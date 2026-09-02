# KABUCA 企業アート制作規約

バージョン: v1.0

本書を、KABUCAで使用する企業アートの唯一の正式な制作規約とする。

## 画像仕様

- 画像は正方形とする。
- 形式はPNGとする。
- 1社につき1枚とする。
- N / R / SR / URで同一画像を共有する。
- カード枠自体は画像に含めない。
- 画像はカードの中央アートとして利用する。

## 画像内に絶対入れないもの

以下は絶対に入れないこと。

- 会社名
- ticker
- 株コード
- ロゴ
- ブランド名
- 文字
- Typography
- UI
- レアリティ表記
- カード枠
- ウォーターマーク

## 画像の役割

画像は「その企業・事業・業界を連想できる中央アート」とする。実在企業の広告のような画像にはしない。

企業そのものを描くというより、「その企業が属する事業・技術・世界観」を表現する。

## 構図

- メインモチーフは中央からやや下に配置する。
- 四隅に重要な要素を置かない。
- Flutterの`BoxFit.cover`で多少cropされても成立する構図にする。
- 主役は1〜2モチーフ程度に絞る。
- ごちゃごちゃさせない。
- 人物は原則使用しない。

## 画風

- 写真そのものではなく、高品質なcinematic CGI / concept artとする。
- プレミアムなトレーディングカードに耐える質感にする。
- 適度に暗めにする。
- 高コントラストにする。
- 光、金属、ガラス、自然物などの質感を重視する。
- 全企業で世界観を統一する。
- 企業ごとに色味とモチーフを変える。

## 企業らしさの出し方

企業ロゴやブランドを使わず、主力事業、産業、技術、物流、製造、食、通信、金融、エネルギー、エンタメなどから、その企業を連想できるモチーフを選ぶ。

例:

| 企業 | モチーフ |
| --- | --- |
| トヨタ自動車 | 道路、モビリティ、精密機械、スピード |
| 任天堂 | 遊び、幾何学、想像空間、創造性 |
| 日本郵船 | 海、大型船、港、物流 |
| 味の素 | 食、分子、うま味、科学 |
| 東京エレクトロン | 半導体、wafer、clean room、微細加工 |

「ロゴがなくても企業の雰囲気を感じられる程度」を狙う。

## IP・商標・ブランド対策

以下は禁止する。

- 実在企業ロゴ
- キャラクター
- 商品パッケージ
- 特徴的すぎる実在製品の忠実な再現
- 実在テーマパークの固有建築の忠実な再現
- ブランド広告のような表現

あくまで、抽象化・一般化された産業イメージとして表現する。

## ファイル名と保存場所

ファイル名は必ず`CompanyMaster.companyId`と一致させる。

標準保存場所:

```text
assets/company_art/{companyId}.png
```

正しい例:

```text
assets/company_art/toyota.png
assets/company_art/nintendo.png
assets/company_art/fast_retailing.png
assets/company_art/oriental_land.png
```

禁止例:

```text
01_motor.png
finance.png
semiconductor.png
```

業界名や連番だけのファイル名は禁止する。

## 生成単位

画像生成は**必ず1社ずつ**行う。

- 1回の画像生成リクエストで扱う企業は必ず1社だけとする。
- 10社を制作する場合は、10社を一覧管理してよいが、生成リクエストは10回に分ける。
- 1枚の画像の中に複数企業・複数業界・複数モチーフを並べない。
- コラージュ、グリッド、コンタクトシート、比較画像、複数パネルは禁止する。
- 「10社分を1枚にまとめてから切り出す」方法は禁止する。
- 1社分の画像には、その1社の主力事業・技術・世界観だけを表現する。
- 生成時のプロンプトには、他の対象企業名・他社モチーフ・他社業界テーマを含めない。

## 納品形式

必ず以下を満たすこと。

- 1社ずつ個別ファイルにする。
- 画像生成そのものも必ず1社ずつ個別に行い、1回の生成で1画像・1企業のみとする。
- コラージュを生成して後から切り分ける方式は原則禁止する。
- companyIdをファイル名にする。
- 個別ダウンロード可能にする。
- まとめZIPも用意してよい。

以下は禁止する。

- 1枚の画像に複数企業のモチーフを含めること。
- 1回の生成プロンプトに複数企業名や複数企業分のモチーフを含めること。
- 3x3、4x3等のグリッド、コンタクトシート、複数パネル形式で生成すること。
- 複数企業を1枚のコラージュとして生成し、それを後から個別画像へ切り分けること。
- コラージュ画像だけを最終成果物にすること。
- 対応関係が分からないファイル名。
- 画像番号だけのファイル名。

内部的にコラージュ生成を利用した場合でも、最終成果物は企業ごとの個別ファイルへ分割する。

## 生成前チェック

生成前に必ず、次の順序で確認する。

1. 対象企業がCompanyMasterに存在する。
2. companyIdを確認する。
3. 既に画像が存在しないか確認する。
4. 企業名とcompanyIdの対応を確認する。
5. 今回生成する対象企業を1社だけ選ぶ。
6. その1社以外の企業名・companyId・業界モチーフが生成プロンプトに入っていないことを確認する。
7. 10社単位で進める場合も、次の企業へ進む前に1社分の生成と保存を完了する。

## 生成後チェック

納品前に必ず確認する。

- 正方形か。
- 文字が入っていないか。
- ロゴが入っていないか。
- 社名が入っていないか。
- tickerが入っていないか。
- companyIdとファイル名が一致しているか。
- 企業と画像のテーマが対応しているか。
- 企業ごとに個別ファイルになっているか。
- 10社分すべて揃っているか。
- 各画像が1社単独で生成されたものであり、コラージュから切り出した画像ではないか。
- 画像内の主テーマが1社分だけになっているか。
- 別企業の業界モチーフや複数業界を並べた構図になっていないか。
- グリッド、コラージュ、複数パネルになっていないか。

## Flutterとの関係

企業アート側には、会社名、ticker、rarity、UI文字、カード枠を焼き込まない。これらはFlutter側で描画する。

画像は`CompanyCardArtwork`の中央ビジュアルとしてのみ使用する。

`CompanyMasterEntry.artworkPath`が標準画像パスを提供する。通常画像は`assets/company_art/{companyId}.png`へ配置すれば自動解決されるため、Dartコードへ企業別登録を追加しない。

`CompanyArtworkRegistry`は標準企業画像の登録一覧ではない。alignment、`BoxFit`、例外assetPathなど、標準規則では扱えない例外設定にのみ使用する。

## N / R / SR / UR

1企業につき画像は1枚とし、N / R / SR / URで同一画像を共有する。

レアリティ差分は`CardRarityStyle`などのFlutter側装飾で表現する。

225社 × 4レアリティ = 900画像にはしない。原則として、225社 = 225画像とする。

## 標準画像生成プロンプト

```text
Create exactly one square premium collectible-card central artwork for ONE company only.
Generate a single full-frame image for this one company. Do not create a collage, grid, contact sheet, comparison layout, split screen, or multiple panels.
Do not include any visual motif, product category, or industry theme belonging to other companies in the current batch.

Company concept: [company]
This image is ONLY for [company]. Ignore all other companies from the batch.
Business theme: [motif]
Suggested palette: [colors]
Mood: cinematic, sophisticated, premium, collectible.

Depict the company's business and industry through abstract or generic imagery,
without reproducing actual branded products, logos, trademarks, characters,
buildings, packaging, or advertisements.

No text.
No company name.
No ticker.
No logo.
No typography.
No UI.
No card frame.
No people.

Square composition.
Main subject centered or slightly below center.
Safe for BoxFit.cover cropping.
High-detail cinematic CGI / concept art.
Strong depth, elegant materials, controlled lighting, premium trading-card quality.
```


## 実行ルール

10社など複数企業の制作を依頼された場合でも、以下の順序を厳守する。

1. 対象企業一覧とcompanyIdを確認する。
2. 1社目だけのプロンプトを作る。
3. 1社目だけを画像生成する。
4. 1社目を`{companyId}.png`として保存する。
5. 次の1社へ進む。
6. 全社完了まで繰り返す。

複数企業を一度に画像生成ツールへ渡してはならない。