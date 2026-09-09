import json
from datetime import UTC, date, datetime, timedelta
from pathlib import Path

from fastapi.testclient import TestClient

from app.main import create_app
from app.poc.daily_market_cache import DailyPriceRecord, SQLiteMarketDataRepository
from app.providers.base import MarketDataNotFound, MarketDataProviderRateLimited, ProviderClosingPrice

TODAY = date(2026, 9, 8)
PREVIOUS = date(2026, 9, 7)
NOW = datetime(2026, 9, 8, 9, tzinfo=UTC)


class Provider:
    def __init__(self, error=None):
        self.calls = []
        self.error = error

    async def get_quote(self, ticker):
        raise AssertionError("starting price must not request a quote")

    async def get_splits(self, *args):
        raise AssertionError("starting price must not request splits")

    async def get_closing_price(self, ticker, trading_date):
        self.calls.append(trading_date)
        if self.error:
            raise self.error
        return ProviderClosingPrice(ticker, trading_date, 2915.5,
            datetime(trading_date.year, trading_date.month, trading_date.day, 6, 35, tzinfo=UTC))


def seed(repository, trading_date, fetched_at=None):
    repository.upsert_daily_price(DailyPriceRecord(
        ticker="7203", trading_date=trading_date, close=2915.5,
        fetched_at=fetched_at or datetime(trading_date.year, trading_date.month, trading_date.day, 6, 35, tzinfo=UTC),
    ))


def history(client, fallback=None):
    params = {"ticker": "7203", "tradingDate": TODAY.isoformat()}
    if fallback:
        params["fallbackTradingDate"] = fallback.isoformat()
    return client.get("/api/market-data/history", params=params)


def test_history_contract_and_persistent_cache_after_restart(tmp_path):
    database = str(tmp_path / "prices.sqlite3")
    provider = Provider()
    fixture = json.loads((Path(__file__).parents[2] / "test/fixtures/market_data_close.json").read_text())
    with TestClient(create_app(provider, database_path=database, now=lambda: NOW)) as client:
        assert history(client).json() == fixture
        assert history(client).json() == fixture
    assert provider.calls == [TODAY]
    blocked = Provider(MarketDataProviderRateLimited("429"))
    with TestClient(create_app(blocked, database_path=database, now=lambda: NOW)) as client:
        response = history(client)
        assert response.status_code == 200
        assert response.json() == fixture
    assert blocked.calls == []


def test_intraday_cache_is_rejected_and_final_close_can_replace_it():
    repository = SQLiteMarketDataRepository()
    seed(repository, TODAY, datetime(2026, 9, 8, 5, tzinfo=UTC))
    provider = Provider()
    with TestClient(create_app(provider, repository=repository,
        now=lambda: datetime(2026, 9, 8, 5, tzinfo=UTC))) as client:
        assert history(client).status_code == 404
    assert provider.calls == []
    with TestClient(create_app(provider, repository=repository, now=lambda: NOW)) as client:
        assert history(client).status_code == 200
    assert provider.calls == [TODAY]
    assert repository.closing_price("7203", TODAY).fetched_at.hour == 6
    repository.close()


def test_429_can_use_previous_stored_close_without_another_upstream_request():
    repository = SQLiteMarketDataRepository()
    seed(repository, PREVIOUS)
    provider = Provider(MarketDataProviderRateLimited("429"))
    with TestClient(create_app(provider, repository=repository, now=lambda: NOW)) as client:
        for _ in range(3):
            response = history(client, PREVIOUS)
            assert response.status_code == 200
            assert response.json()["tradingDate"] == "2026-09-07"
        # Resolution requests still require the exact target date.
        assert history(client).status_code == 429
    assert provider.calls == [TODAY]
    repository.close()


def test_outdated_cache_is_not_used_and_429_is_not_reported_as_404():
    repository = SQLiteMarketDataRepository()
    seed(repository, date(2026, 9, 4))
    provider = Provider(MarketDataProviderRateLimited("429"))
    with TestClient(create_app(provider, repository=repository, now=lambda: NOW)) as client:
        response = history(client, PREVIOUS)
        assert response.status_code == 429
        assert response.json()["detail"]["code"] == "rate_limited"
    assert provider.calls == [TODAY]
    repository.close()


def test_not_yet_available_today_can_fetch_previous_close():
    class DelayedProvider(Provider):
        async def get_closing_price(self, ticker, trading_date):
            if trading_date == TODAY:
                self.calls.append(trading_date)
                raise MarketDataNotFound("not published yet")
            return await super().get_closing_price(ticker, trading_date)

    provider = DelayedProvider()
    with TestClient(create_app(provider, now=lambda: NOW)) as client:
        response = history(client, PREVIOUS)
        assert response.status_code == 200
        assert response.json()["tradingDate"] == PREVIOUS.isoformat()
    assert provider.calls == [TODAY, PREVIOUS]


def test_missing_all_closes_returns_404():
    provider = Provider(MarketDataNotFound("missing"))
    with TestClient(create_app(provider, now=lambda: NOW)) as client:
        response = history(client, PREVIOUS)
        assert response.status_code == 404
        assert response.json()["detail"]["retryable"] is False


def test_upstream_failure_cooldown_expires():
    clock = [NOW]
    provider = Provider(MarketDataProviderRateLimited("429"))
    with TestClient(create_app(provider, now=lambda: clock[0])) as client:
        assert history(client).status_code == 429
        assert history(client).status_code == 429
        assert provider.calls == [TODAY]
        clock[0] += timedelta(seconds=31)
        provider.error = None
        assert history(client).status_code == 200
    assert provider.calls == [TODAY, TODAY]


def test_invalid_fallback_range_does_not_contact_provider():
    provider = Provider()
    with TestClient(create_app(provider, now=lambda: NOW)) as client:
        assert history(client, TODAY).status_code == 400
    assert provider.calls == []
