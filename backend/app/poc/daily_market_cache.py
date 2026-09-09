"""SQLite-backed daily market-data cache proof of concept.

The read provider deliberately has no upstream fallback.  User-facing requests
therefore either read SQLite or return data-not-found; only the refresher is
allowed to contact the upstream provider.
"""

import asyncio
import math
import sqlite3
import threading
from collections.abc import Awaitable, Callable, Iterable
from dataclasses import dataclass
from datetime import UTC, date, datetime
from pathlib import Path

from ..providers.base import (
    MarketDataNotFound,
    MarketDataProvider,
    MarketDataProviderRateLimited,
    ProviderClosingPrice,
    ProviderQuote,
    ProviderSplitEvent,
)


@dataclass(frozen=True)
class DailyPriceRecord:
    ticker: str
    trading_date: date
    close: float
    fetched_at: datetime
    open: float | None = None
    high: float | None = None
    low: float | None = None
    adjusted_close: float | None = None
    volume: int | None = None


@dataclass(frozen=True)
class RefreshResult:
    ticker: str
    succeeded: bool
    attempts: int
    error: str | None = None


class SQLiteMarketDataRepository:
    def __init__(self, database: str | Path = ":memory:") -> None:
        self._connection = sqlite3.connect(
            str(database), check_same_thread=False, isolation_level=None
        )
        self._connection.row_factory = sqlite3.Row
        self._lock = threading.Lock()
        self._create_schema()

    def close(self) -> None:
        with self._lock:
            self._connection.close()

    def _create_schema(self) -> None:
        with self._lock:
            self._connection.executescript(
                """
                CREATE TABLE IF NOT EXISTS market_daily_prices (
                    ticker TEXT NOT NULL,
                    trading_date TEXT NOT NULL,
                    open REAL,
                    high REAL,
                    low REAL,
                    close REAL NOT NULL CHECK(close > 0),
                    adjusted_close REAL,
                    volume INTEGER,
                    fetched_at TEXT NOT NULL,
                    PRIMARY KEY (ticker, trading_date)
                );
                CREATE INDEX IF NOT EXISTS idx_market_daily_prices_latest
                    ON market_daily_prices (ticker, trading_date DESC);

                CREATE TABLE IF NOT EXISTS market_split_events (
                    ticker TEXT NOT NULL,
                    event_date TEXT NOT NULL,
                    numerator REAL NOT NULL CHECK(numerator > 0),
                    denominator REAL NOT NULL CHECK(denominator > 0),
                    fetched_at TEXT NOT NULL,
                    PRIMARY KEY (ticker, event_date, numerator, denominator)
                );
                """
            )

    def upsert_daily_price(self, record: DailyPriceRecord) -> None:
        self._validate_record(record)
        with self._lock:
            self._connection.execute(
                """
                INSERT INTO market_daily_prices (
                    ticker, trading_date, open, high, low, close,
                    adjusted_close, volume, fetched_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(ticker, trading_date) DO UPDATE SET
                    open = excluded.open,
                    high = excluded.high,
                    low = excluded.low,
                    close = excluded.close,
                    adjusted_close = excluded.adjusted_close,
                    volume = excluded.volume,
                    fetched_at = excluded.fetched_at
                """,
                (
                    record.ticker,
                    record.trading_date.isoformat(),
                    record.open,
                    record.high,
                    record.low,
                    record.close,
                    record.adjusted_close,
                    record.volume,
                    self._utc_text(record.fetched_at),
                ),
            )

    def latest_quote(self, ticker: str) -> ProviderQuote | None:
        with self._lock:
            row = self._connection.execute(
                """
                SELECT ticker, close, fetched_at
                FROM market_daily_prices
                WHERE ticker = ?
                ORDER BY trading_date DESC
                LIMIT 1
                """,
                (ticker,),
            ).fetchone()
        if row is None:
            return None
        return ProviderQuote(
            ticker=row["ticker"],
            price=float(row["close"]),
            fetched_at=datetime.fromisoformat(row["fetched_at"]),
        )

    def closing_price(
        self, ticker: str, trading_date: date
    ) -> ProviderClosingPrice | None:
        with self._lock:
            row = self._connection.execute(
                """
                SELECT ticker, trading_date, close, fetched_at
                FROM market_daily_prices
                WHERE ticker = ? AND trading_date = ?
                """,
                (ticker, trading_date.isoformat()),
            ).fetchone()
        if row is None:
            return None
        return ProviderClosingPrice(
            ticker=row["ticker"],
            trading_date=date.fromisoformat(row["trading_date"]),
            close=float(row["close"]),
            fetched_at=datetime.fromisoformat(row["fetched_at"]),
        )

    def upsert_splits(
        self,
        ticker: str,
        events: Iterable[ProviderSplitEvent],
        *,
        fetched_at: datetime,
    ) -> None:
        rows = []
        for event in events:
            if not self._valid_positive(event.numerator) or not self._valid_positive(
                event.denominator
            ):
                raise ValueError("split ratio must be finite and positive")
            rows.append(
                (
                    ticker,
                    event.event_date.isoformat(),
                    event.numerator,
                    event.denominator,
                    self._utc_text(fetched_at),
                )
            )
        with self._lock:
            self._connection.executemany(
                """
                INSERT INTO market_split_events (
                    ticker, event_date, numerator, denominator, fetched_at
                ) VALUES (?, ?, ?, ?, ?)
                ON CONFLICT(ticker, event_date, numerator, denominator)
                DO UPDATE SET fetched_at = excluded.fetched_at
                """,
                rows,
            )

    def splits(
        self, ticker: str, from_date: date, to_date: date
    ) -> list[ProviderSplitEvent]:
        with self._lock:
            rows = self._connection.execute(
                """
                SELECT event_date, numerator, denominator
                FROM market_split_events
                WHERE ticker = ? AND event_date BETWEEN ? AND ?
                ORDER BY event_date
                """,
                (ticker, from_date.isoformat(), to_date.isoformat()),
            ).fetchall()
        return [
            ProviderSplitEvent(
                event_date=date.fromisoformat(row["event_date"]),
                numerator=float(row["numerator"]),
                denominator=float(row["denominator"]),
            )
            for row in rows
        ]

    @classmethod
    def _validate_record(cls, record: DailyPriceRecord) -> None:
        if not record.ticker:
            raise ValueError("ticker is required")
        for value in (
            record.open,
            record.high,
            record.low,
            record.close,
            record.adjusted_close,
        ):
            if value is not None and not cls._valid_positive(value):
                raise ValueError("prices must be finite and positive")
        if record.volume is not None and record.volume < 0:
            raise ValueError("volume must not be negative")

    @staticmethod
    def _valid_positive(value: float) -> bool:
        return isinstance(value, (int, float)) and math.isfinite(value) and value > 0

    @staticmethod
    def _utc_text(value: datetime) -> str:
        if value.tzinfo is None:
            raise ValueError("fetched_at must be timezone-aware")
        return value.astimezone(UTC).isoformat()


class CachedMarketDataProvider:
    """MarketDataProvider that serves user requests from SQLite only."""

    def __init__(self, repository: SQLiteMarketDataRepository) -> None:
        self.repository = repository

    async def get_quote(self, ticker: str) -> ProviderQuote:
        value = self.repository.latest_quote(ticker)
        if value is None:
            raise MarketDataNotFound("cached quote not found")
        return value

    async def get_closing_price(
        self, ticker: str, trading_date: date
    ) -> ProviderClosingPrice:
        value = self.repository.closing_price(ticker, trading_date)
        if value is None:
            raise MarketDataNotFound("cached closing price not found")
        return value

    async def get_splits(
        self, ticker: str, from_date: date, to_date: date
    ) -> list[ProviderSplitEvent]:
        return self.repository.splits(ticker, from_date, to_date)


class DailyMarketDataRefresher:
    """Sequential low-frequency writer; never used by request handlers."""

    def __init__(
        self,
        repository: SQLiteMarketDataRepository,
        upstream: MarketDataProvider,
        *,
        max_attempts: int = 2,
        base_backoff_seconds: float = 2.0,
        inter_ticker_delay_seconds: float = 1.0,
        sleep: Callable[[float], Awaitable[None]] = asyncio.sleep,
        now: Callable[[], datetime] | None = None,
    ) -> None:
        if max_attempts < 1:
            raise ValueError("max_attempts must be at least one")
        self.repository = repository
        self.upstream = upstream
        self.max_attempts = max_attempts
        self.base_backoff_seconds = base_backoff_seconds
        self.inter_ticker_delay_seconds = inter_ticker_delay_seconds
        self._sleep = sleep
        self._now = now or (lambda: datetime.now(UTC))

    async def refresh_prices(
        self, tickers: Iterable[str], trading_date: date
    ) -> list[RefreshResult]:
        ticker_list = list(tickers)
        results: list[RefreshResult] = []
        for index, ticker in enumerate(ticker_list):
            results.append(await self.refresh_price(ticker, trading_date))
            if index + 1 < len(ticker_list) and self.inter_ticker_delay_seconds > 0:
                await self._sleep(self.inter_ticker_delay_seconds)
        return results

    async def refresh_price(self, ticker: str, trading_date: date) -> RefreshResult:
        for attempt in range(1, self.max_attempts + 1):
            try:
                value = await self.upstream.get_closing_price(ticker, trading_date)
                self.repository.upsert_daily_price(
                    DailyPriceRecord(
                        ticker=value.ticker,
                        trading_date=value.trading_date,
                        close=value.close,
                        adjusted_close=value.close,
                        fetched_at=value.fetched_at,
                    )
                )
                return RefreshResult(ticker=ticker, succeeded=True, attempts=attempt)
            except MarketDataProviderRateLimited as error:
                if attempt == self.max_attempts:
                    return RefreshResult(
                        ticker=ticker,
                        succeeded=False,
                        attempts=attempt,
                        error=type(error).__name__,
                    )
                retry_after = getattr(error, "retry_after_seconds", None)
                delay = (
                    float(retry_after)
                    if retry_after is not None
                    else self.base_backoff_seconds * (2 ** (attempt - 1))
                )
                await self._sleep(delay)
            except Exception as error:
                return RefreshResult(
                    ticker=ticker,
                    succeeded=False,
                    attempts=attempt,
                    error=type(error).__name__,
                )
        raise AssertionError("refresh loop must return")

    async def refresh_splits(
        self, ticker: str, from_date: date, to_date: date
    ) -> RefreshResult:
        try:
            events = await self.upstream.get_splits(ticker, from_date, to_date)
            self.repository.upsert_splits(ticker, events, fetched_at=self._now())
            return RefreshResult(ticker=ticker, succeeded=True, attempts=1)
        except Exception as error:
            return RefreshResult(
                ticker=ticker,
                succeeded=False,
                attempts=1,
                error=type(error).__name__,
            )
