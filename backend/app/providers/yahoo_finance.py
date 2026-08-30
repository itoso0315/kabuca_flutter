"""Temporary, unofficial Yahoo Finance provider for MVP verification only."""

import asyncio
import json
import math
from datetime import UTC, date, datetime, time, timedelta
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

from .base import (
    MarketDataNotFound,
    MarketDataProviderRateLimited,
    MarketDataProviderUnavailable,
    ProviderClosingPrice,
    ProviderQuote,
    ProviderSplitEvent,
)

_JST = ZoneInfo("Asia/Tokyo")


class YahooFinanceProvider:
    """Unofficial provider. Replace behind MarketDataProvider for production."""

    def __init__(self, request_timeout_seconds: float = 8.0) -> None:
        self._request_timeout_seconds = request_timeout_seconds

    async def get_quote(self, ticker: str) -> ProviderQuote:
        payload = await self._chart(ticker, {"interval": "1m", "range": "1d"})
        result = self._result(payload)
        value = result.get("meta", {}).get("regularMarketPrice")
        price = self._valid_price(value)
        return ProviderQuote(ticker=ticker, price=price, fetched_at=datetime.now(UTC))

    async def get_closing_price(
        self, ticker: str, trading_date: date
    ) -> ProviderClosingPrice:
        start = datetime.combine(trading_date - timedelta(days=2), time.min, _JST)
        end = datetime.combine(trading_date + timedelta(days=2), time.min, _JST)
        payload = await self._chart(
            ticker,
            {
                "interval": "1d",
                "period1": str(int(start.timestamp())),
                "period2": str(int(end.timestamp())),
                "events": "splits",
            },
        )
        result = self._result(payload)
        timestamps = result.get("timestamp") or []
        quotes = result.get("indicators", {}).get("quote") or []
        closes = quotes[0].get("close", []) if quotes else []
        for index, timestamp in enumerate(timestamps):
            if index >= len(closes) or closes[index] is None:
                continue
            market_date = datetime.fromtimestamp(timestamp, UTC).astimezone(_JST).date()
            if market_date == trading_date:
                return ProviderClosingPrice(
                    ticker=ticker,
                    trading_date=trading_date,
                    close=self._valid_price(closes[index]),
                    fetched_at=datetime.now(UTC),
                )
        raise MarketDataNotFound("closing price not found")

    async def get_splits(
        self, ticker: str, from_date: date, to_date: date
    ) -> list[ProviderSplitEvent]:
        start = datetime.combine(from_date, time.min, _JST)
        end = datetime.combine(to_date + timedelta(days=1), time.min, _JST)
        payload = await self._chart(
            ticker,
            {
                "interval": "1d",
                "period1": str(int(start.timestamp())),
                "period2": str(int(end.timestamp())),
                "events": "splits",
            },
        )
        events = self._result(payload).get("events", {}).get("splits", {})
        output: list[ProviderSplitEvent] = []
        for value in events.values():
            timestamp = value.get("date")
            if timestamp is None:
                continue
            event_date = datetime.fromtimestamp(timestamp, UTC).astimezone(_JST).date()
            if not from_date <= event_date <= to_date:
                continue
            output.append(
                ProviderSplitEvent(
                    event_date=event_date,
                    numerator=float(value.get("numerator", 1)),
                    denominator=float(value.get("denominator", 1)),
                )
            )
        return output

    async def _chart(self, ticker: str, query: dict[str, str]) -> dict:
        symbol = ticker if ticker.endswith(".T") else f"{ticker}.T"
        url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?{urlencode(query)}"
        return await asyncio.to_thread(self._request_json, url)

    def _request_json(self, url: str) -> dict:
        request = Request(
            url,
            headers={"Accept": "application/json", "User-Agent": "KABUCA-Backend/1.0"},
        )
        try:
            with urlopen(request, timeout=self._request_timeout_seconds) as response:
                return json.load(response)
        except HTTPError as error:
            if error.code == 404:
                raise MarketDataNotFound("market data not found") from error
            if error.code == 429:
                raise MarketDataProviderRateLimited("upstream rate limited") from error
            raise MarketDataProviderUnavailable("upstream HTTP failure") from error
        except (URLError, TimeoutError, json.JSONDecodeError) as error:
            raise MarketDataProviderUnavailable("upstream unavailable") from error

    @staticmethod
    def _result(payload: dict) -> dict:
        results = payload.get("chart", {}).get("result") or []
        if not results:
            raise MarketDataNotFound("market data not found")
        return results[0]

    @staticmethod
    def _valid_price(value: object) -> float:
        if not isinstance(value, (int, float)):
            raise MarketDataNotFound("price not found")
        price = float(value)
        if not math.isfinite(price) or price <= 0:
            raise MarketDataProviderUnavailable("invalid upstream price")
        return price
