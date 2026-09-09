import asyncio
import io
import json
from datetime import datetime
from pathlib import Path
from urllib.error import HTTPError, URLError

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.providers.base import (
    MarketDataNotFound,
    MarketDataProviderRateLimited,
    MarketDataProviderUnavailable,
)
from app.providers.yahoo_finance import YahooFinanceProvider


def chart(price=2915.5):
    return {"chart": {"result": [{"meta": {"regularMarketPrice": price}}], "error": None}}


def stub_upstream(monkeypatch, responses):
    requests = []

    def open_url(request, timeout):
        requests.append((request.full_url, timeout))
        value = responses[len(requests) - 1]
        if isinstance(value, Exception):
            raise value
        return io.BytesIO(json.dumps(value).encode())

    monkeypatch.setattr("app.providers.yahoo_finance.urlopen", open_url)
    return requests


def http_error(status):
    return HTTPError("https://query1.finance.yahoo.com", status, "upstream error", {}, None)


@pytest.mark.parametrize("ticker", ["7203", "7203.T"])
def test_japanese_ticker_is_normalized_only_once(monkeypatch, ticker):
    requests = stub_upstream(monkeypatch, [chart()])
    quote = asyncio.run(YahooFinanceProvider().get_quote(ticker))
    assert quote.price == 2915.5
    assert quote.ticker == ticker
    assert len(requests) == 1
    assert "/chart/7203.T?" in requests[0][0]
    assert ".T.T" not in requests[0][0]


def test_server_failure_fails_over_once_and_returns_quote(monkeypatch):
    requests = stub_upstream(monkeypatch, [http_error(502), chart()])
    quote = asyncio.run(YahooFinanceProvider().get_quote("7203"))
    assert quote.price == 2915.5
    assert len(requests) == 2
    assert "query1.finance.yahoo.com" in requests[0][0]
    assert "query2.finance.yahoo.com" in requests[1][0]
    assert 0 < requests[1][1] < requests[0][1] <= 8


def test_rate_limit_does_not_retry_another_host(monkeypatch):
    requests = stub_upstream(monkeypatch, [http_error(429), http_error(429)])
    with pytest.raises(MarketDataProviderRateLimited):
        asyncio.run(YahooFinanceProvider().get_quote("7203"))
    assert len(requests) == 1


def test_not_found_is_not_retried(monkeypatch):
    requests = stub_upstream(monkeypatch, [http_error(404)])
    with pytest.raises(MarketDataNotFound):
        asyncio.run(YahooFinanceProvider().get_quote("7203"))
    assert len(requests) == 1


def test_exhausted_time_budget_does_not_start_another_request(monkeypatch):
    clock = iter([0.0, 0.0, 8.0])
    monkeypatch.setattr("app.providers.yahoo_finance.monotonic", lambda: next(clock))
    requests = stub_upstream(monkeypatch, [TimeoutError("timeout")])
    with pytest.raises(MarketDataProviderUnavailable):
        asyncio.run(YahooFinanceProvider().get_quote("7203"))
    assert len(requests) == 1


@pytest.mark.parametrize(
    "code,expected_status,expected_calls",
    [("Not Found", 404, 1), ("Too Many Requests", 429, 1), ("Internal Error", 502, 2)],
)
def test_chart_errors_preserve_http_error_contract(monkeypatch, code, expected_status, expected_calls):
    payload = {"chart": {"result": None, "error": {"code": code}}}
    requests = stub_upstream(monkeypatch, [payload, payload])
    response = TestClient(create_app()).get(
        "/api/market-data/quote", params={"ticker": "7203"}
    )
    assert response.status_code == expected_status
    assert response.json()["detail"]["retryable"] is (expected_status != 404)
    assert len(requests) == expected_calls


@pytest.mark.parametrize("error", [URLError("unavailable"), TimeoutError("timeout")])
def test_temporary_failure_stops_after_two_requests(monkeypatch, error):
    requests = stub_upstream(monkeypatch, [error, error])
    with pytest.raises(MarketDataProviderUnavailable):
        asyncio.run(YahooFinanceProvider().get_quote("7203"))
    assert len(requests) == 2


@pytest.mark.parametrize("payload", [[], {"chart": []}, {"chart": {"result": [None]}}])
def test_malformed_payload_is_not_reported_as_missing_price(monkeypatch, payload):
    stub_upstream(monkeypatch, [payload, payload])
    with pytest.raises(MarketDataProviderUnavailable):
        asyncio.run(YahooFinanceProvider().get_quote("7203"))


def test_null_price_is_not_saved_as_a_quote(monkeypatch):
    stub_upstream(monkeypatch, [chart(None)])
    with pytest.raises(MarketDataNotFound):
        asyncio.run(YahooFinanceProvider().get_quote("7203"))


def test_quote_contract_uses_actual_yahoo_adapter(monkeypatch):
    fixture = json.loads(
        (Path(__file__).parents[2] / "test/fixtures/market_data_quote.json").read_text()
    )
    stub_upstream(monkeypatch, [http_error(502), chart(fixture["price"])])
    response = TestClient(create_app()).get(
        "/api/market-data/quote", params={"ticker": "7203"}
    )
    assert response.status_code == 200
    actual = response.json()
    assert actual.keys() == fixture.keys()
    assert actual["ticker"] == fixture["ticker"]
    assert actual["price"] == fixture["price"]
    assert datetime.fromisoformat(actual["fetchedAt"]).utcoffset().total_seconds() == 0
