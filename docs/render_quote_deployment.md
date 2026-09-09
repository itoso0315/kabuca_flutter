# 本番quoteデプロイ記録（2026-09-08）

## 現在の状態

- Renderサービス: `kabuca-api` (`srv-da9tu8on74is7397neag`)
- 管理画面: https://dashboard.render.com/web/srv-da9tu8on74is7397neag
- 今回のデプロイ: `dep-dafvkntg1s2s738d084g`
- `live` 完了: 2026-09-08 12:08:13 UTC（21:08:13 JST）
- 本番反映は完了。ただしquote取得は **HTTP 429のままで、復旧未完了**。
- iPhone 16へ、本番URLを明示した最新Flutter debugビルドをインストール・起動済み。
- 予想確定成功、`price` / `fetchedAt` の本番取得成功は未確認。
- Git commit / pushは実施していない。

## 反映方法と範囲

ユーザー承認に基づき、RenderのBuild CommandでProviderの1ファイルだけを差し替えた。
Gitに未反映の暫定方式のため、**Build Commandの上書きと自動デプロイ停止が現在も有効**。

- ベースは従来の本番コミット `a93eea3acf6a53e117e7ee118cc1347ff4a7dd03`。
- 対象: `backend/app/providers/yahoo_finance.py`。
- Build Commandは旧ファイルのSHA-256を検査し、今回のファイルに置換してから従来の `pip install -r requirements.txt` を実行する。
- 想定外のファイルは上書きせず、ビルドを失敗させる。
- 本番ビルドログに以下のハッシュが出たことを確認済み。

```text
KABUCA quote patch sha256=364a16347b02764a08a26b85897927684cdbf568964b532391ed8598d73b21ca
```

元の設定:

```text
Build Command: pip install -r requirements.txt
Start Command: uvicorn app.main:app --host 0.0.0.0 --port $PORT
Auto Deploy: yes / on commit
```

## 本番APIとBackendログ

対象:

```text
GET https://kabuca-api.onrender.com/api/market-data/quote?ticker=7203
```

デプロイ後の応答時間: 1.534秒。HTTP status: **429**。

```json
{"detail":{"code":"rate_limited","message":"Market data request failed","retryable":true}}
```

同じリクエストに対応する本番Backendログ（UTC）:

```text
2026-09-08T12:08:48.760466961Z Yahoo request failed url=https://query1.finance.yahoo.com/v8/finance/chart/7203.T?interval=1m&range=1d status=429
2026-09-08T12:08:49.286288391Z Yahoo request failed url=https://query2.finance.yahoo.com/v8/finance/chart/7203.T?interval=1m&range=1d status=429
```

両取得先への再試行が実行されているが、Yahooがどちらにも429を返している。
今回の失敗はticker変換、JSONパース、Renderのcold startによるタイムアウトではない。
Yahoo側が制限した詳しい理由（送信IPなど）は、このログだけでは断定できない。
ローカルで成功した取得先切り替えだけでは、本番環境の制限を解消できなかった。

## 実機確認の準備

実行したビルド:

```sh
flutter build ios --debug --dart-define=KABUCA_BACKEND_BASE_URL=https://kabuca-api.onrender.com
```

上記ビルドを接続中のiPhone 16に導入し、Flutterのデバッグ接続も確認した。
実機の予想確定操作でも、既存のStockPriceServiceから本番APIへのリクエストと
HTTP 429、`StockPriceException` を記録できている。

Backendで正常quoteを取得できるようになったら、アプリの「予想する」から
所有企業を選び、方向・期間を指定して「この予想で決定」を押す。
完了画面と保存された基準価格・取得日時を確認する。

## 正式反映時に必要な設定復元

以下は **まだ実行しない**。修正をGitに正式反映する許可を得て、対象コミットが
Renderから取得できることを確認してから、暫定のBuild Commandを通常のものへ戻す。

```sh
render services update srv-da9tu8on74is7397neag \
  --build-command 'pip install -r requirements.txt' --confirm -o json
render deploys create srv-da9tu8on74is7397neag \
  --commit <修正を含むコミットSHA> --clear-cache --confirm -o json
```

デプロイと本番quoteが正常なことを確認した後、元の運用に戻す場合は自動デプロイを再開する。

```sh
render services update srv-da9tu8on74is7397neag \
  --auto-deploy=true --confirm -o json
```

修正を含むコミットの正式反映前にBuild Commandだけ戻して再デプロイすると、今回の変更が消える。
旧バージョンへ戻す必要がある場合は、通常のBuild Commandに戻したうえで旧コミット
`a93eea3acf6a53e117e7ee118cc1347ff4a7dd03` を指定して再デプロイする。
旧バージョンでも429が発生していたため、これはquote障害の復旧策にはならない。
