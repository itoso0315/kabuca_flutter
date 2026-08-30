import asyncio
from datetime import UTC, date, datetime

from fastapi.testclient import TestClient

from app.main import create_app
from app.providers.base import (
    MarketDataProviderUnavailable,
    ProviderClosingPrice,
    ProviderQuote,
    ProviderSplitEvent,
)


class FakeProvider:
    def __init__(self) -> None:
        self.quote_calls = 0
        self.fail = False
        self.invalid_price = False
        self.delay = 0.0
        self.splits: list[ProviderSplitEvent] = []

    async def get_quote(self, ticker: str) -> ProviderQuote:
        self.quote_calls += 1
        if self.delay:
            await asyncio.sleep(self.delay)
        if self.fail:
            raise MarketDataProviderUnavailable("failed")
        return ProviderQuote(
            ticker=ticker,
            price=-1 if self.invalid_price else 2915.5,
            fetched_at=datetime(2026, 8, 30, 6, 30, tzinfo=UTC),
        )

    async def get_closing_price(
        self, ticker: str, trading_date: date
    ) -> ProviderClosingPrice:
        if self.fail:
            raise MarketDataProviderUnavailable("failed")
        return ProviderClosingPrice(
            ticker=ticker,
            trading_date=trading_date,
            close=3000.0,
            fetched_at=datetime(2026, 9, 7, 7, tzinfo=UTC),
        )

    async def get_splits(
        self, ticker: str, from_date: date, to_date: date
    ) -> list[ProviderSplitEvent]:
        return self.splits


def test_health() -> None:
    response = TestClient(create_app(FakeProvider())).get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_quote_and_cache() -> None:
    provider = FakeProvider()
    client = TestClient(create_app(provider))
    first = client.get("/api/market-data/quote", params={"ticker": "7203"})
    second = client.get("/api/market-data/quote", params={"ticker": "7203"})
    assert first.status_code == 200
    assert first.json() == {
        "ticker": "7203",
        "price": 2915.5,
        "fetchedAt": "2026-08-30T06:30:00Z",
    }
    assert second.status_code == 200
    assert provider.quote_calls == 1


def test_historical_close() -> None:
    response = TestClient(create_app(FakeProvider())).get(
        "/api/market-data/history",
        params={"ticker": "7203", "tradingDate": "2026-09-07"},
    )
    assert response.status_code == 200
    assert response.json()["close"] == 3000.0
    assert response.json()["tradingDate"] == "2026-09-07"


def test_split_none_and_present() -> None:
    provider = FakeProvider()
    client = TestClient(create_app(provider))
    params = {"ticker": "7203", "from": "2026-08-30", "to": "2026-09-07"}
    assert client.get("/api/market-data/splits", params=params).json()["hasSplit"] is False

    provider = FakeProvider()
    provider.splits = [ProviderSplitEvent(date(2026, 9, 1), 2, 1)]
    payload = TestClient(create_app(provider)).get(
        "/api/market-data/splits", params=params
    ).json()
    assert payload["hasSplit"] is True
    assert payload["events"][0]["eventDate"] == "2026-09-01"


def test_invalid_ticker_and_invalid_price() -> None:
    client = TestClient(create_app(FakeProvider()))
    assert client.get("/api/market-data/quote", params={"ticker": "bad!"}).status_code == 400

    provider = FakeProvider()
    provider.invalid_price = True
    assert (
        TestClient(create_app(provider))
        .get("/api/market-data/quote", params={"ticker": "7203"})
        .status_code
        == 502
    )


def test_upstream_failure_and_timeout() -> None:
    provider = FakeProvider()
    provider.fail = True
    assert (
        TestClient(create_app(provider))
        .get("/api/market-data/quote", params={"ticker": "7203"})
        .status_code
        == 502
    )

    provider = FakeProvider()
    provider.delay = 0.05
    response = TestClient(create_app(provider, provider_timeout_seconds=0.001)).get(
        "/api/market-data/quote", params={"ticker": "7203"}
    )
    assert response.status_code == 502
    assert response.json()["detail"]["retryable"] is True


def test_provider_is_replaceable() -> None:
    first = FakeProvider()
    second = FakeProvider()
    assert create_app(first) is not create_app(second)
