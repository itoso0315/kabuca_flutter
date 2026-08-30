import asyncio
import math
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from typing import Awaitable, Callable, TypeVar

from ..providers.base import (
    MarketDataProvider,
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
    ) -> None:
        self.provider = provider
        self._provider_timeout_seconds = provider_timeout_seconds
        self._quote_ttl = quote_ttl
        self._historical_ttl = historical_ttl
        self._now = now or (lambda: datetime.now(UTC))
        self._cache: dict[tuple, _CacheEntry] = {}
        self._locks: dict[tuple, asyncio.Lock] = {}

    async def get_quote(self, ticker: str) -> ProviderQuote:
        return await self._cached(
            ("quote", ticker), self._quote_ttl, lambda: self.provider.get_quote(ticker)
        )

    async def get_closing_price(
        self, ticker: str, trading_date: date
    ) -> ProviderClosingPrice:
        return await self._cached(
            ("history", ticker, trading_date),
            self._historical_ttl,
            lambda: self.provider.get_closing_price(ticker, trading_date),
        )

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
            try:
                value = await asyncio.wait_for(
                    loader(), timeout=self._provider_timeout_seconds
                )
            except TimeoutError as error:
                raise MarketDataProviderUnavailable("upstream timeout") from error
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
