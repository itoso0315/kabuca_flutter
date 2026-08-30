from dataclasses import dataclass
from datetime import date, datetime
from typing import Protocol


class MarketDataProviderError(Exception):
    """Base error raised by an upstream market-data provider."""


class MarketDataNotFound(MarketDataProviderError):
    pass


class MarketDataProviderRateLimited(MarketDataProviderError):
    pass


class MarketDataProviderUnavailable(MarketDataProviderError):
    pass


@dataclass(frozen=True)
class ProviderQuote:
    ticker: str
    price: float
    fetched_at: datetime


@dataclass(frozen=True)
class ProviderClosingPrice:
    ticker: str
    trading_date: date
    close: float
    fetched_at: datetime


@dataclass(frozen=True)
class ProviderSplitEvent:
    event_date: date
    numerator: float
    denominator: float


class MarketDataProvider(Protocol):
    async def get_quote(self, ticker: str) -> ProviderQuote: ...

    async def get_closing_price(
        self, ticker: str, trading_date: date
    ) -> ProviderClosingPrice: ...

    async def get_splits(
        self, ticker: str, from_date: date, to_date: date
    ) -> list[ProviderSplitEvent]: ...
