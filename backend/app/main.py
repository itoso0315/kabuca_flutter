import re
import os
from contextlib import asynccontextmanager
from datetime import UTC, date, datetime
from pathlib import Path
from collections.abc import Callable

from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.responses import HTMLResponse
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


_LEGAL_PAGE_STYLE = """
<style>
  :root {
    color-scheme: light;
    --bg: #f8f5ed;
    --card: #fffdf8;
    --green: #123d33;
    --muted: #66736c;
    --line: #e4dfd3;
    --gold: #b39450;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--green);
    font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif;
    line-height: 1.75;
  }
  main {
    width: min(760px, calc(100% - 32px));
    margin: 48px auto;
  }
  .brand {
    letter-spacing: .16em;
    font-weight: 800;
    margin-bottom: 18px;
  }
  .card {
    background: var(--card);
    border: 1px solid var(--line);
    border-radius: 20px;
    padding: 28px;
    box-shadow: 0 10px 30px rgba(18, 61, 51, .06);
  }
  h1 { font-size: 28px; margin: 0 0 8px; }
  h2 { font-size: 19px; margin-top: 28px; }
  p, li { color: var(--muted); }
  a { color: var(--green); font-weight: 700; }
  .meta { color: var(--gold); font-size: 14px; margin-bottom: 24px; }
  .nav { margin-top: 28px; font-size: 14px; }
</style>
"""


def _legal_page(title: str, body: str) -> HTMLResponse:
    html = f"""<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title} | KABUCA</title>
  {_LEGAL_PAGE_STYLE}
</head>
<body>
  <main>
    <div class="brand">KABUCA</div>
    <section class="card">
      {body}
      <div class="nav">
        <a href="/privacy">プライバシーポリシー</a> ・
        <a href="/terms">利用規約</a> ・
        <a href="/support">サポート</a>
      </div>
    </section>
  </main>
</body>
</html>"""
    return HTMLResponse(content=html)


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

    @app.get("/privacy", response_class=HTMLResponse)
    async def privacy() -> HTMLResponse:
        return _legal_page(
            "プライバシーポリシー",
            """
<h1>プライバシーポリシー</h1>
<div class="meta">最終更新日：2026年9月11日</div>
<p>KABUCA（以下「本アプリ」）は、利用者のプライバシーを尊重し、取得する情報を必要最小限にとどめます。</p>
<h2>1. 取得する情報</h2>
<p>本アプリは、カード所持状況、KABU残高、株価予想履歴、設定情報など、アプリの利用に必要なデータを端末内に保存します。これらの情報を、利用者を直接識別する目的で運営者が収集することはありません。</p>
<h2>2. 外部サービスとの通信</h2>
<p>株価情報の取得などのため、インターネットを通じて本アプリのバックエンドおよび外部の市場データ提供元へ通信することがあります。通信時には、銘柄コードや対象日など、機能提供に必要な情報が送信される場合があります。</p>
<h2>3. 通知</h2>
<p>利用者が許可した場合、予想結果の確認時刻などを知らせるローカル通知を利用します。通知の利用可否は端末設定および本アプリ内の設定から変更できます。</p>
<h2>4. 個人情報</h2>
<p>本アプリは、氏名、住所、電話番号、位置情報などの個人情報を必須情報として取得しません。</p>
<h2>5. データの保存</h2>
<p>本アプリのゲームデータは主に端末内へ保存されます。端末の削除、初期化、機種変更などによりデータが失われる場合があります。現時点ではクラウドによるデータ同期・復元機能は提供していません。</p>
<h2>6. お問い合わせ</h2>
<p>本ポリシーに関するお問い合わせは、<a href="mailto:soisoi315@icloud.com">soisoi315@icloud.com</a> までご連絡ください。</p>
<h2>7. 改定</h2>
<p>本ポリシーは、機能追加や法令・サービス内容の変更に応じて改定することがあります。重要な変更がある場合は、本ページ等でお知らせします。</p>
            """,
        )

    @app.get("/terms", response_class=HTMLResponse)
    async def terms() -> HTMLResponse:
        return _legal_page(
            "利用規約",
            """
<h1>利用規約</h1>
<div class="meta">最終更新日：2026年9月11日</div>
<p>本利用規約は、KABUCA（以下「本アプリ」）の利用条件を定めるものです。本アプリを利用することで、本規約に同意したものとみなします。</p>
<h2>1. 本アプリについて</h2>
<p>本アプリは、上場企業を題材にカード収集や株価予想を楽しむエンターテインメントサービスです。</p>
<h2>2. 投資情報ではありません</h2>
<p>本アプリ内の株価、企業情報、予想ゲーム、表示内容その他一切の情報は、投資助言、投資勧誘、金融商品の売買推奨を目的とするものではありません。実際の投資判断は、利用者自身の責任で行ってください。</p>
<h2>3. 市場データについて</h2>
<p>株価等の市場データは外部サービスから取得する場合があります。データの正確性、完全性、最新性、リアルタイム性を保証するものではありません。また、取得元の仕様変更や障害等により、一時的に表示できない場合があります。</p>
<h2>4. KABU・カード等</h2>
<p>本アプリ内のKABU、カード、パックその他のゲーム内要素は、本アプリ内でのみ利用できるものであり、現金その他の財産的価値への交換を保証するものではありません。</p>
<h2>5. 禁止事項</h2>
<ul>
  <li>本アプリまたはサーバーへ過度な負荷を与える行為</li>
  <li>不正アクセス、解析、改ざんその他運営を妨害する行為</li>
  <li>法令または公序良俗に反する行為</li>
</ul>
<h2>6. 免責</h2>
<p>運営者は、本アプリの利用または利用不能により生じた損害について、法令上認められる範囲で責任を負いません。本アプリの内容は予告なく変更・停止・終了することがあります。</p>
<h2>7. 規約の変更</h2>
<p>運営者は、必要に応じて本規約を変更することがあります。変更後の規約は本ページに掲載した時点から適用されます。</p>
<h2>8. お問い合わせ</h2>
<p>お問い合わせは、<a href="mailto:soisoi315@icloud.com">soisoi315@icloud.com</a> までご連絡ください。</p>
            """,
        )

    @app.get("/support", response_class=HTMLResponse)
    async def support() -> HTMLResponse:
        return _legal_page(
            "サポート",
            """
<h1>サポート</h1>
<div class="meta">KABUCAに関するお問い合わせ</div>
<p>不具合のご報告、ご意見・ご要望、そのほかKABUCAに関するお問い合わせは、以下のメールアドレスまでお願いいたします。</p>
<p><a href="mailto:soisoi315@icloud.com">soisoi315@icloud.com</a></p>
<h2>お問い合わせ時にあると助かる情報</h2>
<ul>
  <li>発生した問題の内容</li>
  <li>問題が発生した画面</li>
  <li>可能であればスクリーンショット</li>
  <li>アプリのバージョン</li>
</ul>
<p>内容によっては返信までお時間をいただく場合があります。</p>
            """,
        )

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
