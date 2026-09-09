import asyncio
import math
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from typing import Awaitable, Callable, TypeVar
from zoneinfo import ZoneInfo

from ..poc.daily_market_cache import DailyPriceRecord, SQLiteMarketDataRepository

from ..providers.base import (
    MarketDataProvider,
    MarketDataNotFound,
    MarketDataProviderRateLimited,
    MarketDataProviderUnavailable,
    ProviderClosingPrice,
    ProviderQuote,
    ProviderSplitEvent,
)

T = TypeVar("T")


@dataclass
class _CacheEntry:
    value: object
    expires_at: datetime


class MarketDataService:
    def __init__(
        self,
        provider: MarketDataProvider,
        *,
        provider_timeout_seconds: float = 9.0,
        quote_ttl: timedelta = timedelta(seconds=60),
        historical_ttl: timedelta = timedelta(hours=24),
        now: Callable[[], datetime] | None = None,
        repository: SQLiteMarketDataRepository | None = None,
    ) -> None:
        self.provider = provider
        self._provider_timeout_seconds = provider_timeout_seconds
        self._quote_ttl = quote_ttl
        self._historical_ttl = historical_ttl
        self._now = now or (lambda: datetime.now(UTC))
        self.repository = repository or SQLiteMarketDataRepository()
        self._cache: dict[tuple, _CacheEntry] = {}
        self._locks: dict[tuple, asyncio.Lock] = {}
        self._failures: dict[tuple, _CacheEntry] = {}

    async def get_quote(self, ticker: str) -> ProviderQuote:
        return await self._cached(
            ("quote", ticker), self._quote_ttl, lambda: self.provider.get_quote(ticker)
        )

    async def get_closing_price(
        self, ticker: str, trading_date: date
    ) -> ProviderClosingPrice:
        if trading_date.weekday() >= 5 or self._now() < self._closing_time(trading_date):
            raise MarketDataNotFound("trading session is not closed")
        cached = self._stored_close(ticker, trading_date)
        if cached is not None:
            return cached

        async def fetch_and_store() -> ProviderClosingPrice:
            value = await self.provider.get_closing_price(ticker, trading_date)
            self._validate(value)
            if value.ticker != ticker or value.trading_date != trading_date:
                raise MarketDataProviderUnavailable("unexpected closing price date/ticker")
            if not self._is_final(value):
                raise MarketDataNotFound("closing price is not final")
            self.repository.upsert_daily_price(DailyPriceRecord(
                ticker=value.ticker,
                trading_date=value.trading_date,
                close=value.close,
                fetched_at=value.fetched_at,
            ))
            return value

        return await self._cached(
            ("history", ticker, trading_date),
            self._historical_ttl,
            fetch_and_store,
        )

    async def get_starting_close(
        self, ticker: str, trading_date: date, fallback_trading_date: date
    ) -> ProviderClosingPrice:
        try:
            return await self.get_closing_price(ticker, trading_date)
        except (MarketDataNotFound, MarketDataProviderRateLimited, MarketDataProviderUnavailable) as error:
            # Only the client's immediately preceding trading day is eligible.
            # A 429 must not cause another upstream request for the fallback date.
            cached = self._stored_close(ticker, fallback_trading_date)
            if cached is not None:
                return cached
            if isinstance(error, MarketDataNotFound):
                return await self.get_closing_price(ticker, fallback_trading_date)
            raise

    def _stored_close(self, ticker: str, trading_date: date) -> ProviderClosingPrice | None:
        value = self.repository.closing_price(ticker, trading_date)
        if value is None or not self._is_final(value):
            return None
        self._validate(value)
        return value

    def _is_final(self, value: ProviderClosingPrice) -> bool:
        close_at = self._closing_time(value.trading_date)
        return (
            value.trading_date.weekday() < 5
            and value.fetched_at.tzinfo is not None
            and self._now() >= close_at
            and value.fetched_at >= close_at
            and value.fetched_at <= self._now()
        )

    @staticmethod
    def _closing_time(trading_date: date) -> datetime:
        minute = 30 if trading_date >= date(2024, 11, 5) else 0
        return datetime.combine(trading_date, time(15, minute), ZoneInfo("Asia/Tokyo"))

    async def get_splits(
        self, ticker: str, from_date: date, to_date: date
    ) -> list[ProviderSplitEvent]:
        return await self._cached(
            ("splits", ticker, from_date, to_date),
            self._historical_ttl,
            lambda: self.provider.get_splits(ticker, from_date, to_date),
        )

    async def _cached(
        self, key: tuple, ttl: timedelta, loader: Callable[[], Awaitable[T]]
    ) -> T:
        cached = self._cache.get(key)
        if cached is not None and cached.expires_at > self._now():
            return cached.value  # type: ignore[return-value]
        lock = self._locks.setdefault(key, asyncio.Lock())
        async with lock:
            cached = self._cache.get(key)
            if cached is not None and cached.expires_at > self._now():
                return cached.value  # type: ignore[return-value]
            failure = self._failures.get(key)
            if failure is not None and failure.expires_at > self._now():
                raise failure.value
            try:
                value = await asyncio.wait_for(
                    loader(), timeout=self._provider_timeout_seconds
                )
            except TimeoutError as error:
                failure = MarketDataProviderUnavailable("upstream timeout")
                self._failures[key] = _CacheEntry(failure, self._now() + timedelta(seconds=30))
                raise failure from error
            except (MarketDataProviderRateLimited, MarketDataProviderUnavailable) as error:
                self._failures[key] = _CacheEntry(error, self._now() + timedelta(seconds=30))
                raise
            self._validate(value)
            self._cache[key] = _CacheEntry(value, self._now() + ttl)
            return value

    @staticmethod
    def _validate(value: object) -> None:
        price = None
        if isinstance(value, ProviderQuote):
            price = value.price
        elif isinstance(value, ProviderClosingPrice):
            price = value.close
        if price is not None and (not math.isfinite(price) or price <= 0):
            raise MarketDataProviderUnavailable("invalid upstream price")
