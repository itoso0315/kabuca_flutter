import re
import os
from contextlib import asynccontextmanager
from datetime import UTC, date, datetime
from pathlib import Path
from collections.abc import Callable

from fastapi import Depends, FastAPI, HTTPException, Query
from pydantic import BaseModel

from .providers import (
    MarketDataNotFound,
    MarketDataProvider,
    MarketDataProviderRateLimited,
    MarketDataProviderUnavailable,
    YahooFinanceProvider,
)
from .services.market_data_service import MarketDataService
from .poc.daily_market_cache import SQLiteMarketDataRepository

_TICKER_PATTERN = re.compile(r"^[0-9A-Z]{4,10}(?:\.T)?$")


class QuoteResponse(BaseModel):
    ticker: str
    price: float
    fetchedAt: str


class HistoryResponse(BaseModel):
    ticker: str
    tradingDate: date
    close: float
    fetchedAt: str


class SplitEventResponse(BaseModel):
    eventDate: date
    numerator: float
    denominator: float


class SplitsResponse(BaseModel):
    ticker: str
    hasSplit: bool
    events: list[SplitEventResponse]


def create_app(
    provider: MarketDataProvider | None = None, *, provider_timeout_seconds: float = 9.0,
    database_path: str = ":memory:",
    repository: SQLiteMarketDataRepository | None = None,
    now: Callable[[], datetime] | None = None,
) -> FastAPI:
    if repository is None and database_path != ":memory:":
        Path(database_path).parent.mkdir(parents=True, exist_ok=True)
    prices = repository or SQLiteMarketDataRepository(database_path)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        yield
        if repository is None:
            prices.close()

    app = FastAPI(title="KABUCA Backend", version="1.0.0", lifespan=lifespan)
    service = MarketDataService(
        provider or YahooFinanceProvider(),
        provider_timeout_seconds=provider_timeout_seconds,
        repository=prices,
        now=now,
    )

    def get_service() -> MarketDataService:
        return service

    @app.get("/health")
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/api/market-data/quote", response_model=QuoteResponse)
    async def quote(
        ticker: str, market_data: MarketDataService = Depends(get_service)
    ) -> QuoteResponse:
        _validate_ticker(ticker)
        try:
            value = await market_data.get_quote(ticker)
            return QuoteResponse(
                ticker=value.ticker,
                price=value.price,
                fetchedAt=value.fetched_at.isoformat().replace("+00:00", "Z"),
            )
        except Exception as error:
            raise _api_error(error) from error

    @app.get("/api/market-data/history", response_model=HistoryResponse)
    async def history(
        ticker: str,
        trading_date: date = Query(alias="tradingDate"),
        fallback_trading_date: date | None = Query(default=None, alias="fallbackTradingDate"),
        market_data: MarketDataService = Depends(get_service),
    ) -> HistoryResponse:
        _validate_ticker(ticker)
        if fallback_trading_date is not None and fallback_trading_date >= trading_date:
            raise HTTPException(status_code=400, detail=_detail("invalid_range", False))
        try:
            if fallback_trading_date is None:
                value = await market_data.get_closing_price(ticker, trading_date)
            else:
                value = await market_data.get_starting_close(ticker, trading_date, fallback_trading_date)
            return HistoryResponse(
                ticker=value.ticker,
                tradingDate=value.trading_date,
                close=value.close,
                fetchedAt=value.fetched_at.isoformat().replace("+00:00", "Z"),
            )
        except Exception as error:
            raise _api_error(error) from error

    @app.get("/api/market-data/splits", response_model=SplitsResponse)
    async def splits(
        ticker: str,
        from_date: date = Query(alias="from"),
        to_date: date = Query(alias="to"),
        market_data: MarketDataService = Depends(get_service),
    ) -> SplitsResponse:
        _validate_ticker(ticker)
        if from_date > to_date:
            raise HTTPException(status_code=400, detail=_detail("invalid_range", False))
        try:
            events = await market_data.get_splits(ticker, from_date, to_date)
            return SplitsResponse(
                ticker=ticker,
                hasSplit=bool(events),
                events=[
                    SplitEventResponse(
                        eventDate=event.event_date,
                        numerator=event.numerator,
                        denominator=event.denominator,
                    )
                    for event in events
                ],
            )
        except Exception as error:
            raise _api_error(error) from error

    return app


def _validate_ticker(ticker: str) -> None:
    if not _TICKER_PATTERN.fullmatch(ticker):
        raise HTTPException(status_code=400, detail=_detail("invalid_ticker", False))


def _detail(code: str, retryable: bool) -> dict[str, object]:
    return {"code": code, "message": "Market data request failed", "retryable": retryable}


def _api_error(error: Exception) -> HTTPException:
    if isinstance(error, MarketDataNotFound):
        return HTTPException(status_code=404, detail=_detail("data_not_found", False))
    if isinstance(error, MarketDataProviderRateLimited):
        return HTTPException(status_code=429, detail=_detail("rate_limited", True))
    if isinstance(error, MarketDataProviderUnavailable):
        return HTTPException(status_code=502, detail=_detail("provider_unavailable", True))
    return HTTPException(status_code=503, detail=_detail("temporarily_unavailable", True))


app = create_app(database_path=os.environ.get("KABUCA_MARKET_DATA_DB", "/tmp/kabuca-market-data.sqlite3"))
