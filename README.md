# KABUCA

企業カードを集め、企業の未来を予想するFlutterアプリです。株価データはFlutterから外部サービスへ直接アクセスせず、KABUCA Backendを経由します。

## Backend

Backendは`backend/`のFastAPIアプリです。

```sh
cd backend
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
python3 -m uvicorn app.main:app --reload --port 8000
```

主なendpoint:

- `GET /health`
- `GET /api/market-data/quote?ticker=7203`
- `GET /api/market-data/history?ticker=7203&tradingDate=2026-09-07`
- `GET /api/market-data/splits?ticker=7203&from=2026-08-30&to=2026-09-07`

`MarketDataProvider`が取得元を抽象化します。現在の`YahooFinanceProvider`はMVP検証用の非公式・暫定実装です。J-Quantsなどへ移行する場合はBackendのProviderだけを差し替え、秘密情報はBackend環境変数から読み込んでください。FlutterへAPIキーを含めないでください。

## FlutterからBackendへ接続

```sh
flutter run --dart-define=KABUCA_BACKEND_BASE_URL=http://127.0.0.1:8000
```

末尾スラッシュの有無には依存しません。URL未設定時は株価取得を行わず、再試行不能な設定エラーとして扱います。タイトル画面のウォームアップは`/health`だけを呼びます。

iPhone実機では`127.0.0.1`はiPhone自身を指します。MacとiPhoneを同じネットワークへ接続し、MacのLAN IPを指定してください。

```sh
flutter run --dart-define=KABUCA_BACKEND_BASE_URL=http://192.168.1.10:8000
```

## Backendテスト

```sh
cd backend
python3 -m pytest
```

## Render等へデプロイする場合

リポジトリのルートを指定するサービスでは、Root Directoryを`backend`に設定します。

- Build command: `pip install -r requirements.txt`
- Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Health check path: `/health`
- Runtime: Python 3.11以降

正式ProviderのAPIキーを使用する場合のみ、Render等の環境変数へ登録します。`.env`や秘密情報はGitへ追加しません。実際のデプロイ作業はこのリポジトリ変更には含まれていません。

## Company Artwork

企業アート制作ルールは[企業アート制作規約](docs/company_art_guidelines.md)を参照してください。
