# KABUCA 企業アート制作規約

バージョン: v1.1


本書を、KABUCAで使用する企業アートの唯一の正式な制作規約とする。

## 最優先原則

迷った場合は、以下を他のすべてのルールより優先する。

1. 1回の画像生成は必ず1社・1画像だけ。
2. 企業選定・モチーフ設計と画像生成は必ず別ターンに分ける。
3. 画像は常に正方形・PNG・フルブリードとし、画面の四辺いっぱいまで1つの連続したシーンとして描く。円形・楕円形・メダリオン状の内枠、外周フレーム、カード風ボーダー、アプリアイコン風の囲み、四隅装飾はすべて禁止する。
4. 会社名・ブランド名・ticker・株コード・ロゴ・企業固有コピーは入れない。一般的な技術文字・数値・単位・化学式・計測表示は可。
5. 企業ごとにモチーフと主役色を変え、青系に偏らない。
6. 生成後は `{companyId}.png` の実ファイルを用意し、画像とDLリンクを同じ回答内で提示する。

## 画像仕様

- 画像は正方形とする。
- 形式はPNGとする。
- 1社につき1枚とする。
- N / R / SR / URで同一画像を共有する。
- カード枠自体は画像に含めない。
- 画像は正方形キャンバス全面を使うフルブリード構図とする。
- 常に正方形の四辺いっぱいまで背景と主役シーンを連続させ、余白や別色の外周領域を作らない。
- 円形・楕円形・メダリオン状のフレームや窓の中に主役アートを収める構図は、理由を問わず禁止する。
- 正方形の中に円形・楕円形・メダリオン状の内枠を置くデザインは禁止する。
- 四隅に装飾アイコン、記号、飾り罫、バッジ風要素を置くデザインは禁止する。
- 外周フレーム、カード風ボーダー、アプリアイコン風の囲み枠は禁止する。
- 画像はカードの中央アートとして利用する。

## 画像内に絶対入れないもの

以下は絶対に入れないこと。

- 会社名
- ticker
- 株コード
- ロゴ
- ブランド名
- 企業名・ブランド名を示す文字表現
- 企業固有のキャッチコピーや広告文
- UI
- レアリティ表記
- カード枠
- ウォーターマーク

ただし、企業名・ブランド名・ticker・株コード・企業固有の広告文に該当しない一般的な文字、数値、単位、化学式、計測表示、技術ラベル等は使用可とする。

## 画像の役割

画像は「その企業・事業・業界を連想できる中央アート」とする。実在企業の広告のような画像にはしない。

企業そのものを描くというより、「その企業が属する事業・技術・世界観」を表現する。

## 構図

- メインモチーフは中央からやや下に配置する。
- 四隅に重要な要素を置かない。
- 主役アートを円形・楕円形・メダリオン状の窓やフレームに閉じ込めず、正方形キャンバスの四辺いっぱいまで背景を連続させた1シーンとして描く。
- 四隅は背景として自然に使い、装飾専用スペースにはしない。
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
- 全体が青・シアン系に偏らないよう、企業ごとに主役色を明確に変える。
- 青系は通信・IT・半導体など一部企業に限定し、食品、消費財、金融、素材、エネルギー、モビリティ等では赤、橙、黄、緑、紫、ピンク、金、白、黒、土色なども積極的に使う。
- 隣接する企業アート同士で似た配色が続かないようにする。
- 推奨色を決める際は、既存アート群との色被りを確認し、必要なら意図的に暖色系・中性色・多色系へ振る。

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

**最優先ルール：企業アートは必ず1社ずつ生成する。**

- 1回の画像生成リクエストで扱う企業は必ず1社だけとする。
- 1回の画像生成で出力する画像も1社分だけとする。
- 1枚の画像に複数企業、複数業界、複数企業由来のモチーフを含めない。
- コラージュ、グリッド、コンタクトシート、比較画像、分割画面、複数パネルは禁止する。
- 複数企業をまとめて画像生成して後から切り分ける方法は禁止する。
- 複数社を制作する場合も、1社目を生成・保存してから次の1社へ進む。
- 画像生成プロンプトには、その回に生成する1社以外の企業名、companyId、業界テーマ、モチーフを含めない。
- 進捗管理上は複数社をまとめて管理してもよいが、画像生成処理は必ず1社ずつ独立して行う。

## 納品形式

必ず以下を満たすこと。

- 1社につき1個の独立した画像ファイルにする。
- 1回の画像生成で1企業・1画像のみ生成する。
- companyIdをファイル名にする。
- 個別ダウンロード可能にする。
- 画像生成後の回答には、必ず `{companyId}.png` のファイル名で直接ダウンロードできるリンクを付ける。
- 画像生成結果とダウンロードリンクは、必ず同じアシスタント回答内で提示する。
- 画像だけを先に提示して、次のターンでダウンロードリンクを付ける運用は禁止する。

以下は禁止する。

- 1枚の画像に複数企業のモチーフを含めること。
- 1回の生成プロンプトに複数企業名や複数企業分のモチーフを含めること。
- 3x3、4x3等のグリッド、コンタクトシート、複数パネル形式で生成すること。
- コラージュを生成して後から個別画像へ切り分けること。
- コラージュ画像だけを最終成果物にすること。
- 対応関係が分からないファイル名。
- 画像番号だけのファイル名。

## 生成前チェック

生成前に必ず、次の順序で確認する。

1. 今回生成する企業を1社だけ決める。
2. 対象企業がCompanyMasterに存在することを確認する。
3. companyIdを確認する。
4. 既に画像が存在しないか確認する。
5. 企業名とcompanyIdの対応を確認する。
6. 生成プロンプト内に他社名・他社companyId・他社業界テーマが入っていないことを確認する。
7. この1社の画像生成と保存が完了するまで、次の企業へ進まない。
8. 既存の企業アート群と比べて、配色が青系に偏っていないか確認し、必要なら主役色を変更する。

## 生成後チェック

納品前に必ず確認する。

- 1社分だけの画像になっているか。
- 正方形か。
- 正方形の四辺すべてまでシーンが連続したフルブリードになっているか。
- 円形・楕円形・メダリオン状の内枠、外周フレーム、別色の余白、アプリアイコン風の囲みが一切ないか。
- 企業名・ブランド名・ticker・株コード・ロゴ・企業固有の広告文が入っていないか。一般的な文字、数値、単位、化学式、計測表示、技術ラベル等は可。
- companyIdとファイル名が一致しているか。
- 企業と画像のテーマが対応しているか。
- 別企業の業界モチーフが混ざっていないか。
- グリッド、コラージュ、複数パネルになっていないか。
- コラージュから切り出した画像ではないか。

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

Create exactly ONE square premium collectible-card central artwork for ONE company only.
Generate exactly one full-frame image for this company and no other company.
Do not create a collage, grid, contact sheet, comparison layout, split screen, or multiple panels.
Do not include any visual motif, product category, industry theme, company name, or identifier belonging to any other company.

Company concept: [company]
This image is ONLY for [company].
Business theme: [motif]
Suggested palette: [colors]
Mood: cinematic, sophisticated, premium, collectible.

Depict only this company's business and industry through abstract or generic imagery,
without reproducing actual branded products, logos, trademarks, characters,
buildings, packaging, or advertisements.

No company name.
No ticker.
No logo.
No company-specific slogan or advertising copy.
Generic technical text, numbers, units, chemical formulas, measurement readouts, and neutral labels are allowed.
No UI.
No card frame.
No circular inner frame.
No medallion.
No badge layout.
No corner icons.
No decorative border.
No app-icon framing.
Full-bleed square artwork extending edge-to-edge on all four sides.
The entire square canvas must be one continuous scene with no outer margin or separate background area.
Absolutely no circular, oval, medallion, badge, portal, window, ring, or framed composition.
No people.
No collage.
No grid.
No multiple panels.

Square composition.
One continuous scene.
Main subject centered or slightly below center.
Safe for BoxFit.cover cropping.
High-detail cinematic CGI / concept art.
Strong depth, elegant materials, controlled lighting, premium trading-card quality.

## 実行ルール

**画像生成は常に1社ずつ行う。これを他のすべての運用ルールより優先する。**

**企業選定・モチーフ設計と画像生成は、必ず別ターンに分ける。**

- モチーフ設計ターンでは、対象企業・companyId・主モチーフ・推奨色だけを確定し、画像生成は行わない。
- 画像生成ターンでは、直前のターンで確定した1社分の情報だけを使って画像生成する。
- 「次の企業を考えて、そのまま画像生成する」など、企業選定・モチーフ設計・画像生成を同一ターンで完結させる運用は禁止する。
- 再生成が必要な場合も、まずモチーフを再確定するターンを挟み、その次のターンで画像生成する。
- 画像生成ターンでは、過去企業の一覧や他社モチーフを画像生成プロンプトへ含めない。

複数企業の制作依頼でも、以下の順序を厳守する。

1. モチーフ設計ターンで、今回生成する1社だけを選ぶ。
2. 対象企業・companyId・主モチーフ・推奨色を確定する。このターンでは画像生成しない。
3. 次の画像生成ターンで、直前に確定した1社分の情報だけを使ってプロンプトを作る。
4. その1社だけを画像生成する。
5. `{companyId}.png`として保存する。
6. 生成画像を `{companyId}.png` の実ファイルとして用意し、存在を確認する。
7. 画像生成結果と `{companyId}.png` の直接ダウンロードリンクを、必ず同じアシスタント回答内で提示する。
8. 生成後チェックを行う。
9. 問題がなければ次の企業のモチーフ設計ターンへ進む。
10. 全社完了まで同じ手順を繰り返す。

複数企業を一度に画像生成ツールへ渡してはならない。
複数企業の一覧、他社名、他社モチーフを、1回の画像生成プロンプトへ含めてはならない。