import asyncio
from datetime import UTC, date, datetime

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.poc.daily_market_cache import (
    CachedMarketDataProvider,
    DailyMarketDataRefresher,
    DailyPriceRecord,
    SQLiteMarketDataRepository,
)
from app.providers.base import (
    MarketDataProviderRateLimited,
    MarketDataProviderUnavailable,
    ProviderClosingPrice,
    ProviderQuote,
    ProviderSplitEvent,
)

FETCHED_AT = datetime(2026, 9, 3, 8, tzinfo=UTC)
TRADING_DATE = date(2026, 9, 2)


class CountingUpstream:
    def __init__(self) -> None:
        self.closing_calls = 0
        self.quote_calls = 0
        self.split_calls = 0
        self.error: Exception | None = None

    async def get_quote(self, ticker: str) -> ProviderQuote:
        self.quote_calls += 1
        raise AssertionError("PoC request path must never call upstream quote")

    async def get_closing_price(
        self, ticker: str, trading_date: date
    ) -> ProviderClosingPrice:
        self.closing_calls += 1
        if self.error is not None:
            raise self.error
        return ProviderClosingPrice(ticker, trading_date, 2915.5, FETCHED_AT)

    async def get_splits(
        self, ticker: str, from_date: date, to_date: date
    ) -> list[ProviderSplitEvent]:
        self.split_calls += 1
        if self.error is not None:
            raise self.error
        return [ProviderSplitEvent(date(2026, 7, 1), 2, 1)]


@pytest.fixture
def repository() -> SQLiteMarketDataRepository:
    value = SQLiteMarketDataRepository()
    yield value
    value.close()


def test_yahoo_success_is_saved_and_served_without_upstream(
    repository: SQLiteMarketDataRepository,
) -> None:
    upstream = CountingUpstream()
    refresher = DailyMarketDataRefresher(
        repository, upstream, inter_ticker_delay_seconds=0
    )

    result = asyncio.run(refresher.refresh_price("7203", TRADING_DATE))
    cached = asyncio.run(CachedMarketDataProvider(repository).get_quote("7203"))

    assert result.succeeded is True
    assert upstream.closing_calls == 1
    assert cached.price == 2915.5
    assert cached.fetched_at == FETCHED_AT


def test_same_quote_ten_times_has_zero_additional_upstream_calls(
    repository: SQLiteMarketDataRepository,
) -> None:
    upstream = CountingUpstream()
    refresher = DailyMarketDataRefresher(
        repository, upstream, inter_ticker_delay_seconds=0
    )
    asyncio.run(refresher.refresh_price("7203", TRADING_DATE))
    calls_after_refresh = upstream.closing_calls
    client = TestClient(create_app(CachedMarketDataProvider(repository)))

    responses = [
        client.get("/api/market-data/quote", params={"ticker": "7203"})
        for _ in range(10)
    ]

    assert all(response.status_code == 200 for response in responses)
    assert all(
        response.json()
        == {
            "ticker": "7203",
            "price": 2915.5,
            "fetchedAt": "2026-09-03T08:00:00Z",
        }
        for response in responses
    )
    assert upstream.closing_calls == calls_after_refresh == 1
    assert upstream.quote_calls == 0


def test_history_db_hit_preserves_existing_api_contract(
    repository: SQLiteMarketDataRepository,
) -> None:
    repository.upsert_daily_price(
        DailyPriceRecord("7974", TRADING_DATE, 12840.0, FETCHED_AT)
    )
    client = TestClient(create_app(CachedMarketDataProvider(repository)))

    response = client.get(
        "/api/market-data/history",
        params={"ticker": "7974", "tradingDate": "2026-09-02"},
    )

    assert response.status_code == 200
    assert response.json() == {
        "ticker": "7974",
        "tradingDate": "2026-09-02",
        "close": 12840.0,
        "fetchedAt": "2026-09-03T08:00:00Z",
    }


def test_rate_limit_has_bounded_exponential_backoff(
    repository: SQLiteMarketDataRepository,
) -> None:
    upstream = CountingUpstream()
    upstream.error = MarketDataProviderRateLimited("limited")
    delays: list[float] = []

    async def record_sleep(delay: float) -> None:
        delays.append(delay)

    result = asyncio.run(
        DailyMarketDataRefresher(
            repository,
            upstream,
            max_attempts=3,
            base_backoff_seconds=2,
            inter_ticker_delay_seconds=0,
            sleep=record_sleep,
        ).refresh_price("7203", TRADING_DATE)
    )

    assert result.succeeded is False
    assert result.attempts == 3
    assert upstream.closing_calls == 3
    assert delays == [2, 4]
    assert repository.latest_quote("7203") is None


def test_timeout_does_not_destroy_existing_db_value(
    repository: SQLiteMarketDataRepository,
) -> None:
    repository.upsert_daily_price(
        DailyPriceRecord("6758", TRADING_DATE, 1000.0, FETCHED_AT)
    )
    upstream = CountingUpstream()
    upstream.error = MarketDataProviderUnavailable("timeout")

    result = asyncio.run(
        DailyMarketDataRefresher(repository, upstream).refresh_price(
            "6758", TRADING_DATE
        )
    )

    assert result.succeeded is False
    assert repository.latest_quote("6758").price == 1000.0  # type: ignore[union-attr]


@pytest.mark.parametrize("invalid_price", [0, -1, float("nan"), float("inf")])
def test_invalid_price_is_not_saved(
    repository: SQLiteMarketDataRepository, invalid_price: float
) -> None:
    with pytest.raises(ValueError, match="prices must be finite and positive"):
        repository.upsert_daily_price(
            DailyPriceRecord("8035", TRADING_DATE, invalid_price, FETCHED_AT)
        )
    assert repository.latest_quote("8035") is None


def test_split_events_are_saved_and_read_without_upstream(
    repository: SQLiteMarketDataRepository,
) -> None:
    upstream = CountingUpstream()
    refresher = DailyMarketDataRefresher(repository, upstream)
    result = asyncio.run(
        refresher.refresh_splits("9434", date(2026, 1, 1), TRADING_DATE)
    )

    cached = asyncio.run(
        CachedMarketDataProvider(repository).get_splits(
            "9434", date(2026, 1, 1), TRADING_DATE
        )
    )
    assert result.succeeded is True
    assert upstream.split_calls == 1
    assert cached == [ProviderSplitEvent(date(2026, 7, 1), 2, 1)]


def test_five_tickers_are_refreshed_sequentially(
    repository: SQLiteMarketDataRepository,
) -> None:
    upstream = CountingUpstream()
    delays: list[float] = []

    async def record_sleep(delay: float) -> None:
        delays.append(delay)

    results = asyncio.run(
        DailyMarketDataRefresher(
            repository,
            upstream,
            inter_ticker_delay_seconds=1,
            sleep=record_sleep,
        ).refresh_prices(["7203", "7974", "6758", "8035", "9434"], TRADING_DATE)
    )

    assert all(result.succeeded for result in results)
    assert upstream.closing_calls == 5
    assert delays == [1, 1, 1, 1]
    assert all(
        repository.latest_quote(ticker) is not None
        for ticker in ("7203", "7974", "6758", "8035", "9434")
    )
