import '../models/company_card.dart';
import 'company_master.dart';

abstract final class CardCatalog {
  static final Map<String, _CompanyCardContent> _detailedContentById =
      <String, _CompanyCardContent>{
        for (final content in _companies) content.companyId: content,
      };

  static final List<CompanyCard> cards = List.unmodifiable(
    _enabledCompanyIds.expand((companyId) {
      final company = CompanyMaster.byId(companyId);
      if (company == null) {
        throw StateError('Unknown companyId in CardCatalog: $companyId');
      }

      final content =
          _detailedContentById[companyId] ??
          _CompanyCardContent.generic(company);

      return CardRarity.values.map(
        (rarity) => CompanyCard(
          id: '${companyId}_${rarity.name}',
          companyId: companyId,
          companyName: company.companyName,
          ticker: company.ticker,
          industry: company.industry,
          rarity: rarity,
          title: content.titleFor(rarity),
          description: content.descriptionFor(rarity),
        ),
      );
    }),
  );

  static int get companyCount => _enabledCompanyIds.length;

  /// Shares the N-card overview without maintaining separate reveal copy.
  static String? companyOverview(String companyId) {
    final content = _detailedContentById[companyId];
    if (content != null) return content.overview;
    final company = CompanyMaster.byId(companyId);
    return company == null
        ? null
        : _CompanyCardContent.generic(company).overview;
  }
}

class _CompanyCardContent {
  const _CompanyCardContent({
    required this.companyId,
    required this.overview,
    required this.businessTitle,
    required this.business,
    required this.strengthTitle,
    required this.strength,
    required this.storyTitle,
    required this.story,
  });

  factory _CompanyCardContent.generic(CompanyMasterEntry company) {
    return _CompanyCardContent(
      companyId: company.companyId,
      overview: '${company.companyName}は、${company.industry}分野で事業を展開する企業。',
      businessTitle: '${company.industry}の事業',
      business: '${company.companyName}が展開する${company.industry}分野の事業やサービスに注目。',
      strengthTitle: '企業を読み解く',
      strength: '${company.companyName}の競争力や市場での立ち位置を、事業内容から読み解いてみよう。',
      storyTitle: '企業ストーリー',
      story: '${company.companyName}が歩んできた歴史や、現在の事業につながる背景を知ってみよう。',
    );
  }

  final String companyId;
  final String overview;
  final String businessTitle;
  final String business;
  final String strengthTitle;
  final String strength;
  final String storyTitle;
  final String story;

  String titleFor(CardRarity rarity) => switch (rarity) {
    CardRarity.n => '企業の基本',
    CardRarity.r => businessTitle,
    CardRarity.sr => strengthTitle,
    CardRarity.ur => storyTitle,
  };

  String descriptionFor(CardRarity rarity) => switch (rarity) {
    CardRarity.n => overview,
    CardRarity.r => business,
    CardRarity.sr => strength,
    CardRarity.ur => story,
  };
}

final List<String> _enabledCompanyIds = List.unmodifiable(
  CompanyMaster.nikkei225Companies.map((company) => company.companyId),
);

const _companies = <_CompanyCardContent>[
  _CompanyCardContent(
    companyId: 'kyowa_kirin',
    overview: '協和キリンは、医療用医薬品の研究・開発・販売を行う製薬企業。',
    businessTitle: '重点領域に絞る研究開発',
    business:
        '腎疾患、がん、免疫・アレルギー、中枢神経などの領域を中心に、新薬の研究開発とグローバル展開を進める。',
    strengthTitle: '抗体技術とバイオ医薬品',
    strength:
        '長年培ってきた抗体技術やバイオ医薬品の研究基盤を生かし、治療選択肢の少ない疾患に向けた新薬開発を進めている。',
    storyTitle: '発酵技術から先端医薬へ',
    story:
        '発酵技術を強みに成長した事業を源流に持ち、その知見を医薬品研究へ広げてきた。現在はバイオ医薬品を軸に、世界で新しい治療法の創出を目指している。',
  ),
  _CompanyCardContent(
    companyId: 'toyota',
    overview: 'トヨタ自動車は、世界各地で乗用車や商用車を開発・生産・販売する、日本を代表する自動車メーカー。',
    businessTitle: 'クルマだけではない収益源',
    business:
        '主力は自動車販売だが、販売金融や部品・サービスも大きな収益源。世界中で車を売るだけでなく、購入から保有までを支える仕組みでも稼ぐ。',
    strengthTitle: '「改善」を積み重ねる強さ',
    strength:
        '必要なものを必要な時に生産する考え方や、現場で小さな改善を積み重ねる文化が競争力の核。巨大企業でありながら、ムダを減らし続ける仕組みを磨いてきた。',
    storyTitle: '織機メーカーから世界最大級の自動車企業へ',
    story:
        'トヨタの源流は自動車ではなく織機。豊田佐吉の自動織機事業から生まれた資金と技術をもとに、自動車産業へ挑戦した。そこから独自の生産方式を築き、世界規模のメーカーへ成長。異業種の技術から始まった挑戦が、現在のトヨタにつながっている。',
  ),
  _CompanyCardContent(
    companyId: 'nintendo',
    overview: 'ゲーム機とソフトを通じて世界へ娯楽を届ける企業。',
    businessTitle: '遊びを生む両輪',
    business: 'ゲーム専用機と自社ソフトを組み合わせ、継続的な体験を提供する。',
    strengthTitle: '愛され続けるIP',
    strength: '世代を超えて親しまれるキャラクターと遊びの設計力を持つ。',
    storyTitle: '花札から世界の遊びへ',
    story: '京都の花札づくりから始まり、時代ごとに娯楽の形を変えてきた。',
  ),
  _CompanyCardContent(
    companyId: 'sony',
    overview: 'ゲーム、音楽、映画、半導体などを展開する企業グループ。',
    businessTitle: '感動をつなぐ事業群',
    business: 'エンタメとエレクトロニクスを横断し、多様な収益源を持つ。',
    strengthTitle: '創造と技術の融合',
    strength: 'コンテンツ制作力とイメージセンサーなどの技術を併せ持つ。',
    storyTitle: '小さな町工場の挑戦',
    story: '戦後の東京で創業し、独創的な製品とコンテンツで世界へ広がった。',
  ),
  _CompanyCardContent(
    companyId: 'mufg',
    overview: '三菱UFJフィナンシャル・グループは、銀行、信託、証券などを世界で展開する総合金融グループ。',
    businessTitle: '金融サービスを総合展開',
    business:
        '預金・融資、決済、資産運用、信託、証券などを個人・法人向けに国内外で提供する。',
    strengthTitle: '国内最大級の顧客基盤',
    strength:
        '幅広い個人・法人顧客と海外ネットワークを持ち、銀行から資産運用まで多様な金融ニーズへ対応できる。',
    storyTitle: '銀行統合が築いた巨大グループ',
    story:
        '長い歴史を持つ複数の銀行や金融会社の統合を重ねて形成され、日本を代表する総合金融グループへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'keyence',
    overview: '工場の自動化に使うセンサーや測定機器を提供する企業。',
    businessTitle: '現場課題を解く直販',
    business: '顧客の製造現場を直接訪ね、高付加価値な機器を提案する。',
    strengthTitle: '高収益な課題解決力',
    strength: '企画力と直販体制を組み合わせ、高い付加価値を生む。',
    storyTitle: '持たない工場、深い現場',
    story: '生産を外部活用しながら顧客現場へ深く入り込む独自モデルを築いた。',
  ),
  _CompanyCardContent(
    companyId: 'fast_retailing',
    overview: 'ユニクロを中心に衣料品ブランドを世界展開する企業。',
    businessTitle: '服を一貫して届ける',
    business: '企画から生産、販売までをつなぎ、日常着を世界へ届ける。',
    strengthTitle: 'LifeWearの標準化',
    strength: '機能性と品質を両立した定番商品を大規模に展開する。',
    storyTitle: '地方の衣料店から世界へ',
    story: '山口の店舗を起点に、服の常識を問い直して世界市場へ進出した。',
  ),
  _CompanyCardContent(
    companyId: 'itochu',
    overview: '繊維、食料、機械、エネルギーなどを扱う総合商社。',
    businessTitle: '暮らしに近い商い',
    business: '消費者に近い分野を含む多様な事業投資と取引で稼ぐ。',
    strengthTitle: '非資源分野の厚み',
    strength: '食料や繊維など、景気変動を受けにくい事業基盤が強み。',
    storyTitle: '麻布の行商から総合商社へ',
    story: '近江商人の商いを源流に、世界を結ぶ事業体へ発展した。',
  ),
  _CompanyCardContent(
    companyId: 'nyk',
    overview: '船舶輸送を中心に世界の物流を支える企業。',
    businessTitle: '海を渡る物流網',
    business: 'コンテナ船、自動車船、資源輸送など多様な船隊を運営する。',
    strengthTitle: '総合物流の運航力',
    strength: '世界の拠点と専門船運航の知見を組み合わせる。',
    storyTitle: '日本の近代化を運んだ航路',
    story: '明治期から航路を広げ、産業と暮らしを世界へつないできた。',
  ),
  _CompanyCardContent(
    companyId: 'tel',
    overview: '半導体をつくるための製造装置を世界へ提供する企業。',
    businessTitle: 'チップを生む装置群',
    business: '成膜、塗布、洗浄など半導体工程を支える装置が柱。',
    strengthTitle: '微細化を支える技術',
    strength: '顧客との共同開発と幅広い工程対応で高い競争力を持つ。',
    storyTitle: '商社から技術企業へ',
    story: '海外機器の輸入から始まり、世界有数の装置メーカーへ転換した。',
  ),
  _CompanyCardContent(
    companyId: 'advantest',
    overview: '半導体が正しく動くかを検査する装置を開発する企業。',
    businessTitle: '品質を守るテスト',
    business: '高性能半導体向けの検査装置と関連サービスが中心。',
    strengthTitle: '先端チップの検査力',
    strength: '複雑化する半導体を高速・高精度に測る技術を持つ。',
    storyTitle: '計測から半導体の門番へ',
    story: '電子計測の知見を磨き、先端半導体の品質を守る存在となった。',
  ),
  _CompanyCardContent(
    companyId: 'ajinomoto',
    overview: '味の素は、調味料や加工食品、アミノ酸技術を生かしたヘルスケア・電子材料などを世界で展開する企業。',
    businessTitle: '食とアミノ酸の二本柱',
    business:
        '調味料や冷凍食品などの食品事業に加え、アミノ酸を生かした医療・健康分野や電子材料事業も展開する。',
    strengthTitle: 'アミノサイエンスの応用力',
    strength:
        '長年蓄積したアミノ酸の研究と生産技術を、食品だけでなく医薬、栄養、半導体関連材料まで幅広く応用できる。',
    storyTitle: 'うま味の発見から科学企業へ',
    story:
        'うま味成分の発見をきっかけに調味料事業を始め、その後アミノ酸研究を深めながら事業領域を拡大。食から先端材料まで支える企業へ進化した。',
  ),
  _CompanyCardContent(
    companyId: 'kagome',
    overview: 'トマトを中心とする飲料・食品を提供する企業。',
    businessTitle: '野菜を届ける加工力',
    business: '飲料、調味料、業務用食品を通じて野菜の価値を届ける。',
    strengthTitle: '種から食卓まで',
    strength: '品種開発から加工・販売までつながるトマトの知見が強み。',
    storyTitle: '一本のトマト苗から',
    story: '創業者が育てたトマトを起点に、日本の食文化へ新しい味を根づかせた。',
  ),
  _CompanyCardContent(
    companyId: 'nitori',
    overview: '家具・インテリア用品を企画販売する企業グループ。',
    businessTitle: '暮らしを一貫設計',
    business: '商品企画、製造物流、店舗販売をつなぎ低価格と品質を両立する。',
    strengthTitle: '製造物流IT小売業',
    strength: 'サプライチェーン全体を自ら改善する独自の運営力を持つ。',
    storyTitle: '北海道から暮らしの標準へ',
    story: '小さな家具店から、住まいの豊かさを広げる全国企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'saizeriya',
    overview: 'イタリア料理を手頃な価格で提供する外食企業。',
    businessTitle: '日常食を支える仕組み',
    business: '店舗運営と食材供給を磨き、低価格なメニューを提供する。',
    strengthTitle: '徹底した生産性',
    strength: '工程の標準化と自社供給網で品質と価格を両立する。',
    storyTitle: '洋食店から世界の日常へ',
    story: '小さな店の試行錯誤から、イタリア料理を身近にする仕組みを築いた。',
  ),
  _CompanyCardContent(
    companyId: 'oriental_land',
    overview: '東京ディズニーリゾートを運営する企業。',
    businessTitle: '体験を生むリゾート',
    business: 'テーマパーク、ホテル、関連施設を一体運営する。',
    strengthTitle: '磨き続ける体験品質',
    strength: '運営ノウハウと継続投資により高い顧客体験を保つ。',
    storyTitle: '日本に夢の国を',
    story: '海外のテーマパーク文化を日本に根づかせ、独自のリゾートへ育てた。',
  ),
  _CompanyCardContent(
    companyId: 'shiseido',
    overview: '化粧品を中心に美の価値を世界へ届ける企業。',
    businessTitle: 'ブランドで届ける美',
    business: 'スキンケアやメイクアップを複数ブランドで展開する。',
    strengthTitle: '研究と感性の融合',
    strength: '皮膚科学の研究と日本発の美意識をブランドへ結びつける。',
    storyTitle: '薬局から美の文化へ',
    story: '銀座の洋風調剤薬局から始まり、化粧文化を切り拓いてきた。',
  ),
  _CompanyCardContent(
    companyId: 'takeda',
    overview: '武田薬品工業は、医療用医薬品を研究・開発し、世界各地へ届けるグローバル製薬企業。',
    businessTitle: '重点領域で新薬を生む',
    business:
        '消化器系疾患、希少疾患、血漿分画製剤、神経科学、がんなどを重点領域とし、新薬の研究開発と世界展開を進める。',
    strengthTitle: '世界規模の研究開発基盤',
    strength:
        '日本発の研究力に海外拠点や開発体制を組み合わせ、研究から臨床開発、製造、販売までをグローバルに展開できる。',
    storyTitle: '道修町から世界の医療へ',
    story:
        '1781年に大阪・道修町で薬種商として創業。長い歴史の中で研究開発型の製薬企業へ転換し、海外企業との統合も経て世界有数の製薬会社へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'astellas_pharma',
    overview: 'アステラス製薬は、新薬の研究・開発・販売を世界で展開する日本の製薬企業。',
    businessTitle: '世界市場で新薬を育てる',
    business:
        'がんや泌尿器などで培った事業基盤を持ち、現在は新たな治療領域やモダリティにも投資しながらグローバルに医薬品を展開する。',
    strengthTitle: '研究とグローバル展開力',
    strength:
        '日本で生まれた研究成果を海外の開発・販売網につなげ、世界市場で大型医薬品へ育てる力を持つ。',
    storyTitle: '二つの製薬会社が一つに',
    story:
        '山之内製薬と藤沢薬品工業が2005年に合併して誕生。両社の研究力と海外基盤を組み合わせ、世界で戦う研究開発型製薬企業を目指してきた。',
  ),
  _CompanyCardContent(
    companyId: 'sumitomo_pharma',
    overview: '住友ファーマは、医療用医薬品の研究・開発・販売を行う製薬企業。',
    businessTitle: '精神神経領域を中心に展開',
    business:
        '精神神経領域をはじめとする医療用医薬品を手がけ、国内外で研究開発と販売を進める。再生・細胞医薬など次世代分野にも取り組む。',
    strengthTitle: '中枢神経と先端医療の知見',
    strength:
        '長年蓄積した精神神経領域の研究経験に加え、再生・細胞医薬など新しい治療技術への研究基盤を持つ。',
    storyTitle: '合併を重ねて次の治療へ',
    story:
        '住友製薬と大日本製薬の統合で誕生し、その後も事業再編を重ねてきた。従来型の医薬品に加え、細胞を使う新しい治療法にも挑戦している。',
  ),
  _CompanyCardContent(
    companyId: 'shionogi',
    overview: '塩野義製薬は、感染症や中枢神経領域などを中心に新薬を研究・開発する製薬企業。',
    businessTitle: '感染症を軸に新薬を開発',
    business:
        '感染症や中枢神経領域を中心に、医療用医薬品の研究開発と国内外での販売を進める。',
    strengthTitle: '感染症研究の蓄積',
    strength:
        '長年にわたり抗菌薬や抗ウイルス薬の研究を続け、感染症領域で独自の研究基盤と創薬力を培ってきた。',
    storyTitle: '薬種問屋から創薬企業へ',
    story:
        '大阪の薬種問屋を起点に医薬品メーカーへ発展。感染症治療薬などを通じて研究開発力を磨き、世界市場へ挑戦する企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'chugai_pharmaceutical',
    overview: '中外製薬は、がんや免疫などの領域で新薬を研究・開発する製薬企業。',
    businessTitle: 'がん領域を中心に展開',
    business:
        'がん、免疫、神経などの領域で医薬品を開発し、国内外の患者へ治療薬を届けている。',
    strengthTitle: '独自技術と世界連携',
    strength:
        '抗体技術をはじめとする独自の創薬技術に加え、海外パートナーとの連携を通じて世界規模で研究開発を進められる。',
    storyTitle: '日本の創薬力を世界へ',
    story:
        '国内で培った研究開発力を基盤に成長し、海外製薬企業との提携を通じてグローバルな開発体制を構築。日本発の新薬を世界へ届けてきた。',
  ),
  _CompanyCardContent(
    companyId: 'eisai',
    overview: 'エーザイは、がんや神経領域を中心に新薬を研究・開発する製薬企業。',
    businessTitle: '神経とがんに注力',
    business:
        '認知症などの神経領域とがん領域を重点分野とし、新薬の研究開発とグローバル展開を進めている。',
    strengthTitle: '患者視点の研究開発',
    strength:
        '患者とその家族の視点を重視する考え方を研究開発に取り込み、治療だけでなく生活全体を見据えた価値づくりを進める。',
    storyTitle: '認知症研究への長い挑戦',
    story:
        '長年にわたり神経領域の研究を続け、認知症という難しいテーマにも挑戦してきた。粘り強い研究開発が世界的な新薬開発へつながっている。',
  ),
  _CompanyCardContent(
    companyId: 'daiichi_sankyo',
    overview: '第一三共は、がん領域を中心に新薬を研究・開発するグローバル製薬企業。',
    businessTitle: 'がん治療薬を世界展開',
    business:
        'がん領域を重点分野とし、抗体薬物複合体など新しいタイプの医薬品を研究・開発して世界へ展開する。',
    strengthTitle: 'ADC技術の競争力',
    strength:
        '抗体に薬剤を結びつけてがん細胞へ届けるADC技術を強みに、従来とは異なる治療選択肢の開発を進めている。',
    storyTitle: '統合から世界のがん治療へ',
    story:
        '第一製薬と三共の統合で誕生。長い創薬の歴史を受け継ぎながら研究領域を選択と集中し、がん治療の分野で世界的な存在感を高めてきた。',
  ),
  _CompanyCardContent(
    companyId: 'otsuka_holdings',
    overview: '大塚ホールディングスは、医薬品と健康関連製品を世界で展開する企業グループ。',
    businessTitle: '医療と日常の両面を支える',
    business:
        '医療用医薬品に加え、飲料や栄養食品などのニュートラシューティカルズ関連事業を展開する。',
    strengthTitle: '医薬と健康食品の二本柱',
    strength:
        '病気の治療を支える医薬品と、日々の健康維持を支える製品の双方を持ち、幅広い健康ニーズに応えられる。',
    storyTitle: '点滴液から世界の健康へ',
    story:
        '医療用の輸液事業を源流に成長し、医薬品だけでなく飲料や栄養食品へ領域を拡大。独自の発想で世界の健康市場へ事業を広げてきた。',
  ),
  _CompanyCardContent(
    companyId: 'kioxia_holdings',
    overview: 'キオクシアホールディングスは、NAND型フラッシュメモリを中心に半導体メモリを開発・製造する企業グループ。',
    businessTitle: 'データを支えるメモリ事業',
    business:
        'スマートフォン、パソコン、データセンターなどで使われるNAND型フラッシュメモリやSSDを世界へ供給する。',
    strengthTitle: '大容量メモリの技術力',
    strength:
        '微細化や多層化を進める半導体技術と大規模な生産拠点を組み合わせ、高性能・大容量のメモリを量産できる。',
    storyTitle: '国産フラッシュメモリの系譜',
    story:
        '東芝の半導体メモリ事業を源流とし、フラッシュメモリの技術革新を積み重ねてきた。独立後も記憶技術を軸に世界市場で存在感を高めている。',
  ),
  _CompanyCardContent(
    companyId: 'ibiden',
    overview: 'イビデンは、半導体向けパッケージ基板や自動車向けセラミック製品を手がける電子部品メーカー。',
    businessTitle: '半導体と自動車を支える材料',
    business:
        '高性能半導体に使われるパッケージ基板や、自動車の排ガス浄化に使うセラミック製品などを供給する。',
    strengthTitle: '高精度な材料加工技術',
    strength:
        '微細な配線形成やセラミック加工など、厳しい品質が求められる分野で長年培った製造技術を持つ。',
    storyTitle: '電力会社から電子部品へ',
    story:
        '水力発電事業を起点に誕生し、時代の変化に合わせて事業を転換。素材加工の技術を磨きながら電子部品企業へ進化してきた。',
  ),
  _CompanyCardContent(
    companyId: 'minebea_mitsumi',
    overview: 'ミネベアミツミは、ベアリングやモーター、センサーなど幅広い精密部品を手がけるメーカー。',
    businessTitle: '小さな部品で機械を動かす',
    business:
        '極小ベアリング、モーター、半導体、センサーなどを自動車、家電、産業機器向けに供給する。',
    strengthTitle: '超精密と量産の両立',
    strength:
        '小型・高精度な部品を大量に安定生産する技術と、複数の部品を組み合わせて提案できる製品群が強み。',
    storyTitle: 'ベアリングから複合部品企業へ',
    story:
        '小径ベアリングの製造から出発し、M&Aを重ねながら電子部品やセンサーへ領域を拡大。精密技術を軸に総合部品メーカーへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'hitachi',
    overview: '日立製作所は、IT、エネルギー、鉄道、産業機器など社会インフラを幅広く手がける企業。',
    businessTitle: 'デジタルで社会インフラを動かす',
    business:
        'ITサービスを軸に、鉄道、電力、産業設備などを組み合わせ、企業や社会の仕組みを支える。',
    strengthTitle: 'ITと現場技術の融合',
    strength:
        'デジタル技術だけでなく、鉄道や電力設備など実際の機械・インフラを持つことで、現場まで含めた改善提案ができる。',
    storyTitle: '国産モーターから社会インフラへ',
    story:
        '鉱山向けの国産モーター製造を起点に創業。電機、鉄道、ITへと事業を広げ、日本の産業と社会基盤を支える企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'mitsubishi_electric',
    overview: '三菱電機は、工場設備、ビル設備、交通、電力、家電などを手がける総合電機メーカー。',
    businessTitle: '社会と工場を動かす電機',
    business:
        'FA機器、エレベーター、鉄道用機器、電力設備、空調機器など幅広い分野へ製品やシステムを供給する。',
    strengthTitle: '制御技術と幅広い事業基盤',
    strength:
        'モーターやパワー半導体、制御機器などの技術を組み合わせ、工場から都市インフラまで一体で支えられる。',
    storyTitle: '造船所の電機部門から世界へ',
    story:
        '三菱造船の電機製作所を母体として独立し、重電から家電、宇宙まで領域を拡大。電気を制御する技術で社会のさまざまな場面を支えてきた。',
  ),
  _CompanyCardContent(
    companyId: 'fuji_electric',
    overview: '富士電機は、パワー半導体や電力設備、産業機器を手がける総合電機メーカー。',
    businessTitle: '電気を効率よく動かす技術',
    business:
        'パワー半導体、受配電設備、インバーター、自動販売機などを幅広い産業へ供給する。',
    strengthTitle: 'パワーエレクトロニクスの蓄積',
    strength:
        '電力変換や制御の技術を長年磨き、省エネや電動化に必要な機器を一体で提供できる。',
    storyTitle: '重電から省エネ技術へ',
    story:
        '重電機器を起点に事業を広げ、電気を生み、変え、制御する技術を磨いてきた。現在は脱炭素や電動化を支える製品群へ強みを広げている。',
  ),
  _CompanyCardContent(
    companyId: 'yaskawa_electric',
    overview: '安川電機は、産業用ロボットやサーボモーター、インバーターを手がけるメーカー。',
    businessTitle: '工場を自動化する機器',
    business:
        '産業用ロボット、モーションコントロール機器、インバーターなどを世界の製造現場へ供給する。',
    strengthTitle: 'モーター制御とロボット技術',
    strength:
        '精密な動きを生み出すサーボ技術とロボット制御を組み合わせ、自動化の中核を担う。',
    storyTitle: 'モーターからロボットへ',
    story:
        '電動機の製造から出発し、制御技術を磨く中で産業用ロボットへ進出。工場自動化の波とともに世界へ事業を広げてきた。',
  ),
  _CompanyCardContent(
    companyId: 'socionext',
    overview: 'ソシオネクストは、用途に合わせた先端SoCを設計・開発する半導体企業。',
    businessTitle: '専用チップを設計する',
    business:
        '自動車、データセンター、通信機器など向けに、顧客の用途へ最適化したSoCの設計・開発を行う。',
    strengthTitle: '先端SoCの設計力',
    strength:
        '高度な回路設計と顧客との共同開発を組み合わせ、用途ごとに最適化した高性能半導体を生み出せる。',
    storyTitle: '半導体事業の再編から誕生',
    story:
        '国内電機メーカーのシステムLSI事業を統合して誕生。汎用品ではなく顧客専用の先端チップに注力し、世界市場で成長を目指している。',
  ),
  _CompanyCardContent(
    companyId: 'omron',
    overview: 'オムロンは、工場自動化機器やヘルスケア機器などを手がけるメーカー。',
    businessTitle: '工場と健康を支えるセンシング',
    business:
        '制御機器やセンサーを使うFA事業に加え、血圧計などのヘルスケア製品を展開する。',
    strengthTitle: 'センシングと制御の技術',
    strength:
        '状態を測るセンサーと、その情報をもとに機械を動かす制御技術を組み合わせられる。',
    storyTitle: '自動化への挑戦を重ねて',
    story:
        '自動券売機や交通管制など社会の自動化に挑みながら技術を磨き、工場や医療へ応用範囲を広げてきた。',
  ),
  _CompanyCardContent(
    companyId: 'nec',
    overview: 'NECは、ITサービス、通信システム、社会インフラ向け技術を展開する企業。',
    businessTitle: '社会を支えるデジタル基盤',
    business:
        '企業や官公庁向けITシステム、通信ネットワーク、生体認証などを国内外で提供する。',
    strengthTitle: 'ITと通信の総合力',
    strength:
        'ネットワーク技術とシステム構築力に加え、顔認証などのデジタル技術を社会インフラへ実装できる。',
    storyTitle: '電話機からデジタル社会へ',
    story:
        '通信機器の製造を起点に、日本の通信網やコンピューター産業の発展を支えてきた。現在は社会課題をデジタルで解く事業へ軸足を移している。',
  ),
  _CompanyCardContent(
    companyId: 'fujitsu',
    overview: '富士通は、企業や官公庁向けのITサービスやシステム開発を世界で展開する企業。',
    businessTitle: '企業のデジタル化を支える',
    business:
        'クラウド、業務システム、AI、ネットワークなどを組み合わせ、企業や公共分野のデジタル化を支援する。',
    strengthTitle: '大規模システムの構築力',
    strength:
        '長年のシステム開発経験と幅広い顧客基盤を生かし、社会インフラ級の大規模案件まで設計・運用できる。',
    storyTitle: '通信機器からデジタル企業へ',
    story:
        '通信機器の製造を起点にコンピューターやITサービスへ事業を拡大。日本の情報化を支えながら、デジタルサービス中心の企業へ転換してきた。',
  ),
  _CompanyCardContent(
    companyId: 'renesas_electronics',
    overview: 'ルネサスエレクトロニクスは、自動車や産業機器向けの半導体を開発・販売する企業。',
    businessTitle: '機械を制御する半導体',
    business:
        '自動車や産業機器で使われるマイコン、アナログ半導体、電源管理ICなどを世界へ供給する。',
    strengthTitle: '組み込み制御の技術力',
    strength:
        '機器の頭脳となるマイコンと周辺半導体を組み合わせ、自動車や工場設備の高度な制御を支えられる。',
    storyTitle: '半導体再編から世界市場へ',
    story:
        '国内大手電機メーカーの半導体事業再編を通じて誕生。事業改革と海外企業の買収を重ね、車載・産業向け半導体の世界企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'seiko_epson',
    overview: 'セイコーエプソンは、プリンターやプロジェクター、産業用ロボットなどを手がける精密機器メーカー。',
    businessTitle: '印刷と映像を支える技術',
    business:
        '家庭・オフィス向けプリンター、プロジェクター、産業用ロボット、電子部品などを世界で展開する。',
    strengthTitle: '小型・省資源のものづくり',
    strength:
        '精密加工やインクジェット技術を生かし、小型化、省電力、省資源を意識した製品開発を得意とする。',
    storyTitle: '時計技術からプリンターへ',
    story:
        '精密時計の製造で培った技術を起点に、電子機器やプリンターへ事業を拡大。精密技術をさまざまな製品へ応用してきた。',
  ),
  _CompanyCardContent(
    companyId: 'panasonic_holdings',
    overview: 'パナソニックホールディングスは、家電、住宅設備、電池、法人向け機器などを展開する企業グループ。',
    businessTitle: '暮らしと産業を広く支える',
    business:
        '家電や住宅設備に加え、車載電池、工場向け機器、法人向けソリューションなど幅広い事業を持つ。',
    strengthTitle: '生活と産業の両方に強い',
    strength:
        '消費者向け製品で培ったブランド力と、電池や業務用機器など法人向けの技術基盤を併せ持つ。',
    storyTitle: '二股ソケットから世界企業へ',
    story:
        '松下幸之助が配線器具の製造から創業し、家電の普及とともに成長。暮らしを便利にする製品を広げ、世界的な電機グループへ発展した。',
  ),
  _CompanyCardContent(
    companyId: 'sharp',
    overview: 'シャープは、家電、ディスプレイ、電子部品などを手がける電機メーカー。',
    businessTitle: '暮らしと表示技術を支える',
    business:
        'テレビ、白物家電、空調、ディスプレイ、電子デバイスなどを国内外で展開する。',
    strengthTitle: '独自技術を製品へ落とし込む力',
    strength:
        '表示技術や家電開発で培った技術を、使いやすさや省エネ性能を重視した製品へ結びつけてきた。',
    storyTitle: 'シャープペンシルから電機へ',
    story:
        '創業者が考案した筆記具を起点に、ラジオやテレビ、液晶へと事業を拡大。新しい生活スタイルを生む製品に挑戦してきた。',
  ),
  _CompanyCardContent(
    companyId: 'sony',
    overview: 'ソニーグループは、ゲーム、音楽、映画、半導体などを世界で展開する企業グループ。',
    businessTitle: 'エンタメと技術の両輪',
    business:
        'ゲーム、音楽、映画などのコンテンツ事業に加え、イメージセンサーなどの半導体事業を展開する。',
    strengthTitle: 'コンテンツとデバイスの融合',
    strength:
        '人を楽しませるコンテンツ制作力と、映像・音響・半導体の技術を同じグループ内で持つ点が強み。',
    storyTitle: '戦後の小さな会社から世界へ',
    story:
        '戦後の東京で創業し、ラジオや音響機器から事業を拡大。独創的な製品とコンテンツを生み出し、世界的ブランドへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'tdk',
    overview: 'TDKは、コンデンサー、センサー、磁性部品などを手がける電子部品メーカー。',
    businessTitle: '電子機器の中を支える部品',
    business:
        'スマートフォン、自動車、産業機器などに使われる受動部品、センサー、電源関連製品を供給する。',
    strengthTitle: '素材から部品までの技術力',
    strength:
        '磁性材料などの素材技術を基盤に、小型・高性能な電子部品へ落とし込む開発力を持つ。',
    storyTitle: '磁性材料から世界の電子部品へ',
    story:
        '磁性材料の国産化を目指して創業し、電子機器の進化に合わせて製品分野を拡大。世界の機器メーカーを部品で支える企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'alps_alpine',
    overview: 'アルプスアルパインは、車載機器やセンサー、スイッチなどを手がける電子部品メーカー。',
    businessTitle: 'クルマと機器の操作を支える',
    business:
        '車載インフォテインメント、スイッチ、センサー、通信モジュールなどを自動車や電子機器向けに供給する。',
    strengthTitle: '入力・検知・通信をまとめる力',
    strength:
        '人の操作を受け取る入力部品と、周囲を検知するセンサー、通信技術を組み合わせて提案できる。',
    storyTitle: '部品と車載の融合で誕生',
    story:
        '電子部品に強いアルプス電気と、車載機器に強いアルパインの統合で現在の体制へ。電子部品と車載技術を組み合わせて事業領域を広げている。',
  ),
  _CompanyCardContent(
    companyId: 'yokogawa_electric',
    overview: '横河電機は、工場やプラントの計測・制御システムを手がける企業。',
    businessTitle: 'プラントを安全に動かす',
    business:
        '石油、化学、電力などのプラント向けに、計測機器や制御システム、運用支援サービスを提供する。',
    strengthTitle: '高精度な計測と制御',
    strength:
        '現場の状態を正確に測り、その情報をもとに設備を安定運転させる制御技術を長年培ってきた。',
    storyTitle: '計測器から産業の司令塔へ',
    story:
        '電気計器の製造から出発し、計測技術を工場や大型プラントの制御へ展開。産業設備の安定運転を支える存在へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'lasertec',
    overview: 'レーザーテックは、半導体製造で使われる検査・計測装置を開発する企業。',
    businessTitle: '見えない欠陥を見つける',
    business:
        '半導体の微細化に必要なマスクや関連工程を検査する装置を世界の半導体メーカーへ供給する。',
    strengthTitle: '先端検査のニッチ技術',
    strength:
        '微細な欠陥を高速・高精度に見つける光学技術を磨き、先端半導体分野で高い競争力を持つ。',
    storyTitle: '小さな計測企業から世界の要所へ',
    story:
        '光学計測技術を磨きながら半導体検査へ注力し、微細化の進展とともに存在感を拡大。先端半導体の品質を支える重要企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'fanuc',
    overview: 'ファナックは、産業用ロボットやCNC、工作機械向け制御装置を世界で展開するメーカー。',
    businessTitle: '工場を自動で動かす技術',
    business:
        'CNC、産業用ロボット、ロボドリルなどを通じて、世界の製造現場の自動化を支える。',
    strengthTitle: '高信頼な制御技術',
    strength:
        '長時間安定して動く制御装置とロボットを自社で磨き込み、生産設備の高い稼働率を支えている。',
    storyTitle: '数値制御から無人化工場へ',
    story:
        '工作機械を自動で動かす数値制御技術から出発し、ロボットへ領域を拡大。工場の自動化を象徴する企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'rohm',
    overview: 'ロームは、半導体や電子部品を開発・製造する電子部品メーカー。',
    businessTitle: '機器を動かす半導体',
    business:
        '自動車、産業機器、家電などに使われるIC、パワー半導体、抵抗器などを供給する。',
    strengthTitle: 'パワー半導体の技術力',
    strength:
        '省エネや電動化に重要なSiCパワー半導体を含め、材料からデバイスまで幅広い技術を持つ。',
    storyTitle: '抵抗器から半導体へ',
    story:
        '抵抗器の製造から創業し、電子機器の進化に合わせて半導体へ事業を拡大。電力を効率よく制御する技術へ強みを広げてきた。',
  ),
  _CompanyCardContent(
    companyId: 'kyocera',
    overview: '京セラは、電子部品、セラミック部品、通信機器などを幅広く展開するメーカー。',
    businessTitle: 'セラミック技術を多分野へ',
    business:
        '半導体製造装置向け部品、電子部品、通信機器、工具などを国内外で展開する。',
    strengthTitle: 'ファインセラミックスの蓄積',
    strength:
        '高温や摩耗に強いセラミック材料を加工し、電子・産業分野へ応用する技術を長年磨いてきた。',
    storyTitle: '町工場から世界企業へ',
    story:
        '京都の小さなセラミック部品会社として創業し、独自材料と経営手法を武器に事業領域を広げ、世界的な総合メーカーへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'taiyo_yuden',
    overview: '太陽誘電は、コンデンサーやインダクターなどを手がける電子部品メーカー。',
    businessTitle: '小さな部品で電気を整える',
    business:
        'スマートフォン、自動車、通信機器などに使われる積層セラミックコンデンサーや高周波部品を供給する。',
    strengthTitle: '材料から作り込む部品技術',
    strength:
        'セラミック材料や電極技術を自社で磨き、小型化と高性能化を両立した電子部品を量産できる。',
    storyTitle: 'コンデンサーからデジタル社会へ',
    story:
        '電子部品の国産化を支えるメーカーとして成長し、機器の小型化と高性能化に合わせて製品を進化させてきた。',
  ),
  _CompanyCardContent(
    companyId: 'murata_manufacturing',
    overview: '村田製作所は、コンデンサーや通信モジュール、センサーなどを世界で供給する電子部品メーカー。',
    businessTitle: 'スマホから車まで支える部品',
    business:
        '積層セラミックコンデンサー、通信モジュール、センサーなどを幅広い電子機器向けに提供する。',
    strengthTitle: '超小型部品の量産力',
    strength:
        '材料技術と精密加工を組み合わせ、極めて小さな電子部品を高品質で大量生産できる。',
    storyTitle: '陶器の技術から電子部品へ',
    story:
        'セラミックを使った電子部品の研究から出発し、電子機器の進化とともに事業を拡大。世界のデジタル機器を内部から支える企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'screen_holdings',
    overview: 'SCREENホールディングスは、半導体やディスプレイの製造装置を手がける企業グループ。',
    businessTitle: '半導体を洗う装置',
    business:
        '半導体製造工程で使われる洗浄装置を中心に、ディスプレイや印刷関連の装置も展開する。',
    strengthTitle: '洗浄工程の高い技術力',
    strength:
        '微細な半導体回路を傷つけずに汚れを除去する洗浄技術で、先端半導体の製造を支える。',
    storyTitle: '写真製版から半導体装置へ',
    story:
        '印刷用の写真製版機器を源流に、精密な画像処理や洗浄技術を発展させ、半導体製造装置の世界企業へ転換してきた。',
  ),
  _CompanyCardContent(
    companyId: 'canon',
    overview: 'キヤノンは、カメラ、プリンター、複合機、半導体関連装置などを手がける精密機器メーカー。',
    businessTitle: '映像と印刷を支える機器',
    business:
        'カメラやレンズ、オフィス向け複合機、プリンター、半導体露光装置などを世界で展開する。',
    strengthTitle: '光学と精密技術の蓄積',
    strength:
        'レンズ、画像処理、精密機構などの技術を組み合わせ、高性能な映像・印刷機器へ仕上げる力を持つ。',
    storyTitle: '国産カメラへの挑戦から世界へ',
    story:
        '高級カメラの国産化を目指して創業し、光学技術を磨きながらプリンターや産業機器へ事業を拡大してきた。',
  ),
  _CompanyCardContent(
    companyId: 'ricoh',
    overview: 'リコーは、複合機やプリンター、業務向けデジタルサービスを展開する企業。',
    businessTitle: '働く現場をデジタル化する',
    business:
        '複合機やプリンターに加え、クラウド、IT支援、業務改善サービスを企業向けに提供する。',
    strengthTitle: '機器とサービスの両輪',
    strength:
        'オフィス機器で築いた顧客基盤と保守網を生かし、ハードだけでなく業務全体のデジタル化まで支援できる。',
    storyTitle: '光学技術から仕事のDXへ',
    story:
        '感光紙やカメラ、複写機で培った光学・画像技術を土台に事業を拡大。現在は働き方そのものを支えるデジタルサービス企業へ転換している。',
  ),
  _CompanyCardContent(
    companyId: 'archion',
    overview: 'ARCHIONは、商用車事業を軸にトラックやバスの開発・生産・販売を担う企業グループ。',
    businessTitle: '物流と移動を支える商用車',
    business:
        'トラックやバスなどの商用車を通じて、物流、公共交通、事業者の輸送ニーズを支える。',
    strengthTitle: '商用車の技術と事業基盤',
    strength:
        '大型車両の開発・生産技術と幅広い販売・サービス網を組み合わせ、商用車のライフサイクル全体を支えられる。',
    storyTitle: '商用車再編から生まれた新体制',
    story:
        '日本の商用車メーカー再編を背景に誕生し、トラックやバスの技術と事業基盤を集約。次世代の物流と移動を支える企業を目指している。',
  ),
  _CompanyCardContent(
    companyId: 'nissan_motor',
    overview: '日産自動車は、乗用車や商用車を世界で開発・生産・販売する自動車メーカー。',
    businessTitle: '世界市場へクルマを届ける',
    business:
        '乗用車、SUV、商用車、電気自動車などを開発し、金融サービスや販売網と組み合わせて世界展開する。',
    strengthTitle: '電動化と車両技術の蓄積',
    strength:
        '早くから電気自動車の量産に取り組み、車両制御や電動パワートレインの技術を積み重ねてきた。',
    storyTitle: '国産車の時代を切り拓く',
    story:
        '日本の自動車産業草創期から量産車を手がけ、海外市場へ進出。時代ごとの技術革新を取り込みながら世界メーカーへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'isuzu_motors',
    overview: 'いすゞ自動車は、トラックやバス、ディーゼルエンジンを世界で展開する商用車メーカー。',
    businessTitle: '物流を支えるトラック事業',
    business:
        '小型から大型までのトラック、バス、エンジンを開発・生産し、世界各地の物流や公共交通を支える。',
    strengthTitle: '商用車とディーゼルの専門力',
    strength:
        '耐久性や燃費が重視される商用車分野で長年技術を蓄積し、用途に合わせた車両を幅広く展開できる。',
    storyTitle: '日本最古級の自動車メーカー',
    story:
        '日本の自動車産業の初期から車両生産に関わり、乗用車から商用車へ軸足を移しながら専門性を磨いてきた。',
  ),
  _CompanyCardContent(
    companyId: 'mitsubishi_motors',
    overview: '三菱自動車は、SUVやピックアップ、電動車を中心に世界で展開する自動車メーカー。',
    businessTitle: 'SUVと電動車を世界へ',
    business:
        'SUV、ピックアップトラック、軽自動車、電動車などを開発・生産し、アジアをはじめ世界市場で販売する。',
    strengthTitle: '四輪駆動と電動化の技術',
    strength:
        'ラリーなどで磨いた四輪駆動技術と、早期から取り組んだ電動車技術を組み合わせた車づくりを得意とする。',
    storyTitle: '三菱の自動車事業から独立',
    story:
        '三菱重工業の自動車部門を源流に独立し、SUVや四輪駆動車で独自の地位を築いた。現在は電動化を軸に次の成長を目指している。',
  ),
  _CompanyCardContent(
    companyId: 'mazda',
    overview: 'マツダは、乗用車やSUVを中心に世界で展開する自動車メーカー。',
    businessTitle: '走る楽しさを追求する',
    business:
        '乗用車やSUVを開発・生産し、独自のエンジン技術やデザインを生かして世界市場へ販売する。',
    strengthTitle: '独自技術と一貫した設計思想',
    strength:
        'エンジン、車体、デザインを一体で磨き、規模だけに頼らず個性的な走行性能と商品性を生み出してきた。',
    storyTitle: 'コルクからクルマへ',
    story:
        'コルク製造会社として始まり、機械事業を経て自動車へ進出。独自技術への挑戦を重ねながら世界市場でブランドを築いてきた。',
  ),
  _CompanyCardContent(
    companyId: 'honda',
    overview: '本田技研工業は、二輪車、四輪車、パワープロダクツなどを世界で展開するモビリティ企業。',
    businessTitle: '二輪から四輪、空へ',
    business:
        '世界最大級の二輪車事業を基盤に、自動車、発電機、船外機、航空機など多様なモビリティ製品を展開する。',
    strengthTitle: 'エンジンと量産技術の蓄積',
    strength:
        '小型エンジンから自動車、航空機まで幅広い製品を自ら開発し、機械を高性能かつ大量に生産する技術を磨いてきた。',
    storyTitle: '町工場から世界のモビリティへ',
    story:
        '本田宗一郎が小さな工場から二輪車づくりを始め、四輪車やモータースポーツへ挑戦。独創的な技術で世界企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'suzuki',
    overview: 'スズキは、軽自動車や小型車、二輪車を世界で展開する自動車メーカー。',
    businessTitle: '小さなクルマを世界へ',
    business:
        '軽自動車やコンパクトカー、二輪車を開発・生産し、日本やインドをはじめ世界各地で販売する。',
    strengthTitle: '小型・低コストのものづくり',
    strength:
        '限られたサイズや価格の中で使いやすさと燃費を両立する設計力に強みを持つ。',
    storyTitle: '織機から小さなモビリティへ',
    story:
        '織機メーカーとして創業し、二輪車や軽自動車へ進出。小型車に特化しながら海外市場を開拓し、世界的メーカーへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'subaru',
    overview: 'SUBARUは、乗用車と航空宇宙事業を手がけるメーカー。',
    businessTitle: '個性的なクルマと航空技術',
    business:
        'SUVや乗用車を中心に開発・生産し、航空宇宙分野では機体部品や関連事業も展開する。',
    strengthTitle: '水平対向エンジンと四輪駆動',
    strength:
        '独自の水平対向エンジンや四輪駆動技術、安全運転支援などを組み合わせた車づくりに特徴がある。',
    storyTitle: '航空機の技術を自動車へ',
    story:
        '航空機メーカーを源流に持ち、戦後に自動車へ進出。航空技術で培った設計思想を生かし、独自性のあるクルマづくりを続けてきた。',
  ),
  _CompanyCardContent(
    companyId: 'yamaha_motor',
    overview: 'ヤマハ発動機は、二輪車、船外機、マリン製品、産業用機器などを世界で展開するメーカー。',
    businessTitle: '陸と海を動かすモビリティ',
    business:
        '二輪車を中心に、船外機、ボート、四輪バギー、産業用ロボットなど多様な製品を展開する。',
    strengthTitle: '小型エンジンと機動力',
    strength:
        '高性能な小型エンジンと軽量設計を得意とし、用途ごとに機動性の高い製品を生み出せる。',
    storyTitle: '楽器会社からモーターの世界へ',
    story:
        'ヤマハの二輪車部門から独立して誕生し、オートバイを起点に海洋製品や産業機器へ事業を拡大してきた。',
  ),
  _CompanyCardContent(
    companyId: 'terumo',
    overview: 'テルモは、カテーテル、注射器、人工心肺関連機器などを手がける医療機器メーカー。',
    businessTitle: '医療現場を支える機器',
    business:
        '心臓血管治療、輸血・細胞治療、注射器や体温計など幅広い医療機器を世界へ供給する。',
    strengthTitle: '低侵襲医療の技術力',
    strength:
        '患者への負担を抑えるカテーテル治療などで、高精度な加工技術と臨床現場の知見を蓄積している。',
    storyTitle: '国産体温計から世界の医療へ',
    story:
        '国産体温計の製造を目的に創業し、注射器や血液関連機器、心臓血管治療へ領域を拡大。世界的な医療機器企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'konica_minolta',
    overview: 'コニカミノルタは、複合機、計測機器、画像関連技術を展開する企業。',
    businessTitle: '画像と計測で企業を支える',
    business:
        'オフィス向け複合機に加え、色や光を測る計測機器、印刷・画像関連ソリューションを提供する。',
    strengthTitle: '光学と画像処理の蓄積',
    strength:
        'カメラや写真で培った光学・画像技術を、計測や印刷、デジタルサービスへ応用している。',
    storyTitle: '写真とカメラから事業転換',
    story:
        'コニカとミノルタの統合で誕生し、写真フィルムやカメラから撤退しながら、光学技術を法人向け事業へ転換してきた。',
  ),
  _CompanyCardContent(
    companyId: 'disco',
    overview: 'ディスコは、半導体や電子部品を切断・研削する精密加工装置を開発する企業。',
    businessTitle: '半導体を切り、薄くする',
    business:
        'シリコンウエハーや半導体チップを切断・研削する装置や砥石を世界の半導体工場へ供給する。',
    strengthTitle: '極薄・高精度の加工技術',
    strength:
        '壊れやすい半導体材料をミクロン単位で切削・研削する装置と消耗品の両方を自社で磨いている。',
    storyTitle: '砥石メーカーから半導体装置へ',
    story:
        '工業用砥石の製造から出発し、精密加工技術を半導体分野へ応用。微細化と高性能化を支える装置メーカーへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'nikon',
    overview: 'ニコンは、カメラ、レンズ、半導体関連装置、計測機器などを手がける精密機器メーカー。',
    businessTitle: '光で見る・測る・つくる',
    business:
        'カメラや交換レンズに加え、半導体・FPD露光装置、産業用計測機器などを展開する。',
    strengthTitle: '高精度な光学技術',
    strength:
        'レンズ設計、精密機構、画像技術を組み合わせ、撮影から製造装置まで幅広い分野へ応用できる。',
    storyTitle: '国産光学機器から世界へ',
    story:
        '光学機器の国産化を目指して誕生し、カメラや顕微鏡、産業装置へ技術を展開。光を扱う精密技術を磨き続けてきた。',
  ),
  _CompanyCardContent(
    companyId: 'olympus',
    overview: 'オリンパスは、内視鏡を中心とする医療機器を世界で展開するメーカー。',
    businessTitle: '体の中を見る医療機器',
    business:
        '消化器内視鏡や外科用機器などを開発・製造し、診断や治療を支える医療機器を世界へ供給する。',
    strengthTitle: '内視鏡の技術と臨床知見',
    strength:
        '高精度な光学技術と長年の医療現場での知見を組み合わせ、内視鏡分野で高い競争力を持つ。',
    storyTitle: '顕微鏡から医療機器へ',
    story:
        '顕微鏡の国産化を目指して創業し、光学技術をカメラや内視鏡へ展開。現在は医療機器へ事業を集中し、世界市場で存在感を高めている。',
  ),
  _CompanyCardContent(
    companyId: 'hoya',
    overview: 'HOYAは、メガネレンズや半導体関連部材、医療機器などを手がける光学・素材メーカー。',
    businessTitle: '光を操る製品群',
    business:
        'メガネレンズ、コンタクトレンズ、半導体製造向けマスクブランクス、内視鏡関連製品などを展開する。',
    strengthTitle: '高精度な光学・ガラス技術',
    strength:
        'ガラス材料と精密加工の技術を生かし、医療から半導体まで高付加価値なニッチ市場で強みを持つ。',
    storyTitle: '光学ガラスから高収益企業へ',
    story:
        '光学ガラスの国産化を目的に創業し、レンズや医療、半導体材料へ領域を拡大。選択と集中を重ねながら高収益な事業構成を築いてきた。',
  ),
  _CompanyCardContent(
    companyId: 'ntt',
    overview: 'NTTは、固定・携帯通信、データセンター、法人向けITなどを世界で展開する通信グループ。',
    businessTitle: '社会を結ぶ通信とIT',
    business:
        '固定・携帯通信に加え、データセンター、クラウド、システム開発などを通じて社会と企業のデジタル基盤を支える。',
    strengthTitle: '巨大インフラと研究開発力',
    strength:
        '全国規模の通信網と世界的なIT事業基盤に加え、光通信などの長期研究を続けられる技術力を持つ。',
    storyTitle: '電話網から次世代通信へ',
    story:
        '日本の電話インフラを担った電電公社を源流に民営化。通信自由化を経て事業を広げ、現在は次世代の光・デジタル基盤へ挑戦している。',
  ),
  _CompanyCardContent(
    companyId: 'kddi',
    overview: 'KDDIは、携帯通信を中心に金融、決済、法人向けITなどを展開する通信会社。',
    businessTitle: '通信を軸に生活サービスへ',
    business:
        '携帯・固定通信に加え、決済、金融、エネルギー、法人向けデジタルサービスなどを展開する。',
    strengthTitle: '通信基盤と顧客接点',
    strength:
        '全国規模の通信ネットワークと多数の契約者基盤を生かし、通信以外のサービスへ顧客接点を広げられる。',
    storyTitle: '国際通信と国内通信の融合',
    story:
        '複数の通信会社の統合を通じて誕生し、固定通信と携帯電話を一体化。通信インフラを軸に生活サービス企業へ進化してきた。',
  ),
  _CompanyCardContent(
    companyId: 'softbank_corp',
    overview: 'ソフトバンクは、携帯通信を軸に決済、メディア、法人向けデジタル事業を展開する企業。',
    businessTitle: '通信からデジタル生活へ',
    business:
        '携帯・固定通信に加え、決済、インターネットサービス、法人向けITなど幅広いデジタル事業を展開する。',
    strengthTitle: '通信とデジタルサービスの連携',
    strength:
        '大規模な通信顧客基盤とグループ内のデジタルサービスを結びつけ、日常のさまざまな接点へ事業を広げられる。',
    storyTitle: '通信事業の挑戦から総合デジタルへ',
    story:
        '固定通信や携帯電話事業への参入を重ねて成長し、通信会社から決済やITまで担う総合デジタル企業へ領域を広げてきた。',
  ),
  _CompanyCardContent(
    companyId: 'softbank_group',
    overview: 'ソフトバンクグループは、AIや半導体、テクノロジー企業への投資を世界で行う投資持株会社。',
    businessTitle: 'テクノロジー企業へ投資する',
    business:
        '半導体設計企業やAI関連企業への出資を軸に、世界の成長企業へ大規模な投資を行う。',
    strengthTitle: '巨大資本と大胆な投資判断',
    strength:
        '世界規模で資金を集め、将来性の高いテクノロジー分野へ集中投資できる資本力と意思決定の速さを持つ。',
    storyTitle: 'ソフト流通から世界投資へ',
    story:
        'パソコンソフトの流通会社として創業し、通信やインターネットへ進出。事業売却と大型投資を重ね、世界的なテクノロジー投資会社へ変貌した。',
  ),
  _CompanyCardContent(
    companyId: 'shizuoka_financial_group',
    overview: 'しずおかフィナンシャルグループは、静岡銀行を中核に地域金融サービスを展開する金融グループ。',
    businessTitle: '地域経済を支える金融',
    business:
        '預金、融資、資産運用、法人支援などを通じて、静岡県を中心とした個人や企業の活動を支える。',
    strengthTitle: '強い地域基盤と健全性',
    strength:
        '地域に根差した顧客基盤と長年の取引関係を持ち、企業の成長支援や資産形成まで幅広く対応できる。',
    storyTitle: '地方銀行から金融グループへ',
    story:
        '静岡銀行を中心に地域経済とともに成長し、持株会社体制へ移行。銀行だけでなく多様な金融サービスを提供するグループへ進化している。',
  ),
  _CompanyCardContent(
    companyId: 'concordia_financial_group',
    overview: 'コンコルディア・フィナンシャルグループは、横浜銀行などを傘下に持つ地域金融グループ。',
    businessTitle: '首都圏の企業と暮らしを支える',
    business:
        '預金、融資、資産運用、事業承継支援などを通じて、神奈川を中心とする首都圏の個人・企業を支える。',
    strengthTitle: '大都市圏の厚い顧客基盤',
    strength:
        '人口と企業が集まる首都圏に強い営業基盤を持ち、個人から中小企業まで幅広い金融ニーズに対応できる。',
    storyTitle: '地域銀行の統合で誕生',
    story:
        '横浜銀行と東日本銀行の経営統合で誕生。異なる地域基盤を組み合わせ、首都圏で存在感のある金融グループを築いてきた。',
  ),
  _CompanyCardContent(
    companyId: 'aozora_bank',
    overview: 'あおぞら銀行は、法人金融や資産運用、個人向け金融サービスを展開する銀行。',
    businessTitle: '専門性を生かす銀行業',
    business:
        '法人向け融資や投資銀行業務、資産運用、個人向け預金・投資商品などを提供する。',
    strengthTitle: '機動的な専門金融',
    strength:
        '大手銀行とは異なる規模感を生かし、専門性の高い案件や投資分野へ柔軟に取り組める。',
    storyTitle: '長期信用銀行から再出発',
    story:
        '日本債券信用銀行を前身とし、経営再建を経てあおぞら銀行として再出発。独自の金融分野を開拓しながら事業モデルを変えてきた。',
  ),
  _CompanyCardContent(
    companyId: 'resona_holdings',
    overview: 'りそなホールディングスは、りそな銀行や埼玉りそな銀行などを傘下に持つ金融グループ。',
    businessTitle: '個人と中小企業に強い銀行',
    business:
        '預金、融資、決済、資産運用、事業承継などを通じて、個人や中小企業を中心に金融サービスを提供する。',
    strengthTitle: '都市銀行と地域密着の両立',
    strength:
        '大都市圏に広い店舗網を持ちながら、地域銀行のように個人や中小企業へ深く入り込む営業基盤を持つ。',
    storyTitle: '再編を経て生まれたりそな',
    story:
        '複数の銀行統合を通じて現在の体制が生まれ、経営再建を経てサービス改革を進めてきた。銀行店舗のあり方を見直すなど独自の変革を重ねている。',
  ),
  _CompanyCardContent(
    companyId: 'sumitomo_mitsui_trust_group',
    overview: '三井住友トラストグループは、信託銀行を中核に資産運用や不動産、年金などを手がける金融グループ。',
    businessTitle: '資産を預かり、育て、つなぐ',
    business:
        '銀行業務に加え、資産運用、年金、不動産、証券代行など信託ならではの幅広いサービスを提供する。',
    strengthTitle: '信託の専門性',
    strength:
        '資産管理や不動産、相続、年金など専門性の高い分野を一体で扱い、長期の資産形成や承継を支援できる。',
    storyTitle: '信託銀行の統合で巨大グループへ',
    story:
        '三井系と住友系を含む信託銀行の再編を経て形成され、銀行とは異なる信託機能を軸に総合金融グループへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'smfg',
    overview: '三井住友フィナンシャルグループは、銀行、カード、証券、リースなどを展開する総合金融グループ。',
    businessTitle: '銀行を軸に金融サービスを展開',
    business:
        '預金・融資、決済、カード、証券、資産運用などを個人・法人向けに国内外で提供する。',
    strengthTitle: '法人金融と決済の総合力',
    strength:
        '大企業から中小企業まで広い法人基盤を持ち、銀行とカード・決済サービスを組み合わせて提案できる。',
    storyTitle: '三井と住友の銀行統合',
    story:
        '三井系と住友系の銀行統合を通じて誕生し、その後カードや証券などへ事業を拡大。国内外で総合金融サービスを展開するグループへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'chiba_bank',
    overview: '千葉銀行は、千葉県を中心に個人や企業へ金融サービスを提供する地方銀行。',
    businessTitle: '地域の暮らしと企業を支える',
    business:
        '預金、融資、住宅ローン、資産運用、法人支援などを通じて千葉県を中心とした地域経済を支える。',
    strengthTitle: '首都圏近郊の厚い顧客基盤',
    strength:
        '人口と企業が多い千葉県に強い営業基盤を持ち、個人向けから法人向けまで幅広い金融ニーズを取り込める。',
    storyTitle: '地域とともに成長した地方銀行',
    story:
        '千葉県内の銀行再編を経て誕生し、地域の人口増加や産業発展とともに成長。首都圏有数の地方銀行へ発展してきた。',
  ),
  _CompanyCardContent(
    companyId: 'fukuoka_financial_group',
    overview: 'ふくおかフィナンシャルグループは、福岡銀行などを傘下に持つ九州地盤の金融グループ。',
    businessTitle: '九州を広く支える金融',
    business:
        '預金、融資、資産運用、法人支援などを通じて、福岡を中心に九州各地の個人や企業へ金融サービスを提供する。',
    strengthTitle: '九州最大級の地域基盤',
    strength:
        '複数の地方銀行を束ねることで広い店舗網と顧客基盤を持ち、地域をまたいだ企業支援や金融サービスを展開できる。',
    storyTitle: '地域銀行の統合で九州をつなぐ',
    story:
        '福岡銀行を中心に複数の地方銀行がグループへ加わり、県境を越えた金融ネットワークを構築。九州全体を支える金融グループへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'mizuho_financial_group',
    overview: 'みずほフィナンシャルグループは、銀行、信託、証券などを国内外で展開する総合金融グループ。',
    businessTitle: '銀行・信託・証券を一体運営',
    business:
        '預金・融資、決済、資産運用、信託、証券などを個人・法人向けに幅広く提供する。',
    strengthTitle: '大企業との深い取引基盤',
    strength:
        '国内の大企業や機関投資家との強い取引関係を持ち、銀行・信託・証券を組み合わせた大規模な金融提案ができる。',
    storyTitle: '三つの銀行が一つに',
    story:
        '第一勧業銀行、富士銀行、日本興業銀行の統合を軸に誕生し、それぞれの顧客基盤と専門性を引き継いで総合金融グループへ発展した。',
  ),
  _CompanyCardContent(
    companyId: 'credit_saison',
    overview: 'クレディセゾンは、クレジットカードを中心に決済、金融、リースなどを展開する企業。',
    businessTitle: 'カードから広がる金融サービス',
    business:
        'クレジットカードや決済サービスに加え、ローン、リース、資産形成支援など幅広い金融サービスを提供する。',
    strengthTitle: '生活に近い決済接点',
    strength:
        '小売やサービスとの提携を通じて築いたカード会員基盤を持ち、日常の支払いから金融サービスへ顧客接点を広げられる。',
    storyTitle: '百貨店カードから総合金融へ',
    story:
        '流通系カード事業を起点に成長し、提携カードや決済サービスを拡大。現在はカード会社の枠を越えて多様な金融事業を展開している。',
  ),
  _CompanyCardContent(
    companyId: 'orix',
    overview: 'オリックスは、リース、金融、不動産、エネルギー、空港運営など幅広い事業を展開する企業グループ。',
    businessTitle: '金融から実物事業まで',
    business:
        '法人向けリースや融資に加え、不動産、再生可能エネルギー、空港運営など多様な事業で収益を生み出す。',
    strengthTitle: '事業を見極める投資力',
    strength:
        '金融で培った審査力や投資判断を生かし、成長性のある事業へ資金と運営ノウハウを投入できる。',
    storyTitle: 'リース会社から事業投資企業へ',
    story:
        'リース事業から出発し、金融や不動産、インフラへ領域を拡大。時代に合わせて新しい収益源を取り込み、独自の複合企業へ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'japan_exchange_group',
    overview: '日本取引所グループは、東京証券取引所などを運営し、日本の証券市場を支える企業グループ。',
    businessTitle: '売買の場を提供する',
    business:
        '株式やデリバティブの取引市場を運営し、上場審査、売買システム、清算など市場インフラを提供する。',
    strengthTitle: '市場インフラとしての信頼性',
    strength:
        '大量の売買を安定して処理するシステムと公正な市場運営を通じて、日本の資本市場の中核を担う。',
    storyTitle: '取引所統合で生まれた市場基盤',
    story:
        '東京証券取引所と大阪証券取引所の経営統合を経て発足。現物株からデリバティブまでを支える総合取引所グループへ発展した。',
  ),
  _CompanyCardContent(
    companyId: 'daiwa_securities_group',
    overview: '大和証券グループ本社は、証券を中心に資産運用や投資銀行業務を展開する金融グループ。',
    businessTitle: '資産運用と企業金融を支える',
    business:
        '個人向けの株式・投資信託販売に加え、法人向けの資金調達やM&A支援、資産運用などを行う。',
    strengthTitle: '幅広い顧客への証券サービス',
    strength:
        '個人投資家から大企業まで幅広い顧客基盤を持ち、市場取引と企業金融の双方に対応できる。',
    storyTitle: '証券市場とともに歩んだ歴史',
    story:
        '長い証券業の歴史を持ち、市場の拡大とともに個人営業や法人金融を発展。総合証券グループとして事業領域を広げてきた。',
  ),
  _CompanyCardContent(
    companyId: 'nomura_holdings',
    overview: '野村ホールディングスは、証券、投資銀行、資産運用などを世界で展開する金融グループ。',
    businessTitle: '市場と企業をつなぐ証券業',
    business:
        '個人向け資産運用、機関投資家向け取引、企業の資金調達やM&A支援などを国内外で提供する。',
    strengthTitle: '国内最大級の証券基盤',
    strength:
        '長年築いた個人・法人の顧客基盤と市場取引のノウハウを生かし、大型の資金調達や運用ニーズに対応できる。',
    storyTitle: '大阪の証券業から世界へ',
    story:
        '大阪の金融事業を源流に証券業へ発展し、日本の資本市場の成長とともに規模を拡大。海外へも進出し世界的な金融グループを目指してきた。',
  ),
  _CompanyCardContent(
    companyId: 'sompo_holdings',
    overview: 'SOMPOホールディングスは、損害保険を中心に生命保険や介護などを展開する保険グループ。',
    businessTitle: '事故や災害のリスクに備える',
    business:
        '自動車保険や火災保険などの損害保険を中心に、生命保険、介護、海外保険事業などを展開する。',
    strengthTitle: '保険と生活支援の組み合わせ',
    strength:
        '幅広い保険商品に加え、介護など保険周辺のサービスも持ち、生活上のさまざまなリスクへ対応できる。',
    storyTitle: '損保再編から総合サービスへ',
    story:
        '複数の損害保険会社の統合を経て現在のグループへ発展。保険だけでなく介護などへ事業を広げ、人の暮らしを支える領域を拡大している。',
  ),
  _CompanyCardContent(
    companyId: 'ms_ad',
    overview: 'MS&ADインシュアランスグループホールディングスは、損害保険と生命保険を国内外で展開する保険グループ。',
    businessTitle: '幅広い保険でリスクを支える',
    business:
        '自動車、火災、企業向け保険などの損害保険を中心に、生命保険や海外保険事業も展開する。',
    strengthTitle: '複数ブランドの事業基盤',
    strength:
        '異なる顧客基盤を持つ保険会社をグループ内に抱え、個人から企業まで幅広いリスクへ対応できる。',
    storyTitle: '保険会社の大型統合で誕生',
    story:
        '三井住友海上やあいおいニッセイ同和損保などの再編を通じて形成され、国内外で総合的な保険サービスを提供するグループへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'dai_ichi_life_group',
    overview: '第一生命ホールディングスは、生命保険を中心に資産運用や海外保険事業を展開する金融グループ。',
    businessTitle: '人生の長期リスクを支える',
    business:
        '死亡保障や医療保障、年金などの生命保険を提供し、資産運用や海外保険事業にも取り組む。',
    strengthTitle: '長期契約と資産運用力',
    strength:
        '長期の保険契約で築いた顧客基盤と大規模な運用資産を持ち、保障と資産形成の両面を支えられる。',
    storyTitle: '相互扶助から株式会社へ',
    story:
        '日本の近代的な生命保険会社として成長し、相互会社から株式会社へ転換。海外展開も進めながら事業構造を変えてきた。',
  ),
  _CompanyCardContent(
    companyId: 'tokio_marine_holdings',
    overview: '東京海上ホールディングスは、損害保険や生命保険を国内外で展開する保険グループ。',
    businessTitle: '世界でリスクを引き受ける',
    business:
        '自動車・火災・企業向け保険などの損害保険を中心に、生命保険や海外保険事業も展開する。',
    strengthTitle: '国内基盤と海外展開力',
    strength:
        '日本で築いた強い顧客基盤に加え、海外保険会社の買収や展開を通じて地域分散された収益源を持つ。',
    storyTitle: '日本初期の海上保険から世界へ',
    story:
        '海上保険を起点に長い歴史を持ち、国内損保の中核企業として成長。海外事業を広げながら世界的な保険グループへ発展した。',
  ),
  _CompanyCardContent(
    companyId: 't_and_d_holdings',
    overview: 'T&Dホールディングスは、生命保険を中心に個人や中小企業向けの保障サービスを展開する金融グループ。',
    businessTitle: '顧客層ごとに保険を届ける',
    business:
        '個人、中小企業、シニア層など異なる顧客層に合わせて、生命保険や資産形成商品を提供する。',
    strengthTitle: '専門ブランドの使い分け',
    strength:
        '異なる顧客ニーズに特化した生命保険会社をグループ内に持ち、きめ細かい商品設計や販売ができる。',
    storyTitle: '生命保険会社の連携で誕生',
    story:
        '複数の生命保険会社が共同持株会社の下に集まり誕生。それぞれの専門性を生かしながら保険事業を広げてきた。',
  ),
  _CompanyCardContent(
    companyId: 'nissui',
    overview: 'ニッスイは、水産物、冷凍食品、加工食品などを世界で展開する食品企業。',
    businessTitle: '海の資源を食卓へ届ける',
    business:
        '漁業・養殖、水産物の加工販売、冷凍食品、業務用食品などを国内外で展開する。',
    strengthTitle: '調達から加工までの一貫力',
    strength:
        '世界の水産資源調達から加工・販売まで幅広く手がけ、安定供給と商品開発を両立できる。',
    storyTitle: '漁業会社から総合食品企業へ',
    story:
        '水産事業を起点に成長し、冷凍・加工技術を磨きながら食品分野へ拡大。海の資源を生かす総合食品企業へ進化した。',
  ),
  _CompanyCardContent(
    companyId: 'nisshin_seifun_group',
    overview: '日清製粉グループ本社は、小麦粉を中心に食品、加工食品、酵母・バイオなどを展開する企業グループ。',
    businessTitle: '小麦を食卓へ届ける',
    business:
        '製粉を中核に、パスタやプレミックスなどの加工食品、業務用食品素材などを幅広く提供する。',
    strengthTitle: '製粉技術と安定供給力',
    strength:
        '小麦の調達から製粉、加工まで長年の技術と供給網を持ち、食品メーカーや外食産業を幅広く支える。',
    storyTitle: '近代製粉から日本の食へ',
    story:
        '近代的な製粉事業を起点に成長し、小麦粉の普及とともに事業を拡大。日本の食生活を裏側から支えてきた。',
  ),
  _CompanyCardContent(
    companyId: 'meiji_holdings',
    overview: '明治ホールディングスは、乳製品、菓子、栄養食品、医薬品などを展開する企業グループ。',
    businessTitle: '食と健康を両方支える',
    business:
        '牛乳やヨーグルト、チョコレートなどの食品に加え、医薬品や栄養関連製品も展開する。',
    strengthTitle: '食品ブランドと研究開発の厚み',
    strength:
        '日常食品で築いた強いブランド力と、乳酸菌や栄養、医薬の研究基盤を組み合わせられる。',
    storyTitle: '菓子と乳業が一つのグループへ',
    story:
        '明治製菓と明治乳業の経営統合で誕生し、食と医薬の両分野を持つ独自の企業グループへ発展した。',
  ),
  _CompanyCardContent(
    companyId: 'nippon_ham',
    overview: '日本ハムは、食肉、ハム・ソーセージ、加工食品などを展開する総合食品メーカー。',
    businessTitle: '肉を育て、加工し、届ける',
    business:
        '食肉の生産・調達から加工、物流、販売までを幅広く手がけ、家庭用・業務用食品を供給する。',
    strengthTitle: '食肉の一貫供給体制',
    strength:
        '生産から販売までつながるサプライチェーンを持ち、品質管理と安定供給を両立できる。',
    storyTitle: '食肉加工から総合食品へ',
    story:
        'ハム・ソーセージ事業から成長し、食肉の生産や販売へ領域を広げた。現在は幅広い食品で日本の食卓を支えている。',
  ),
  _CompanyCardContent(
    companyId: 'sapporo_breweries',
    overview: 'サッポロホールディングスは、ビールなどの酒類、食品、不動産などを展開する企業グループ。',
    businessTitle: 'ビールを軸に複数事業を展開',
    business:
        'ビールを中心とする酒類事業に加え、食品・飲料や不動産事業も手がける。',
    strengthTitle: '長いブランド資産と不動産基盤',
    strength:
        '歴史あるビールブランドに加え、都市部の不動産資産など異なる収益基盤を持つ。',
    storyTitle: '北海道のビールづくりから',
    story:
        '北海道で始まったビール醸造を源流に持ち、日本のビール文化とともに成長。食品や不動産へも事業を広げてきた。',
  ),
  _CompanyCardContent(
    companyId: 'asahi_group_holdings',
    overview: 'アサヒグループホールディングスは、ビールや飲料、食品を国内外で展開する企業グループ。',
    businessTitle: '酒類と飲料を世界へ',
    business:
        'ビールを中心に、清涼飲料、食品、海外の酒類ブランドなどを幅広く展開する。',
    strengthTitle: 'ブランド力と海外展開',
    strength:
        '国内の強いビールブランドに加え、海外ブランドの買収を通じてグローバルな販売基盤を広げてきた。',
    storyTitle: '大阪のビール会社から世界へ',
    story:
        '大阪で始まったビール事業を起点に成長し、ヒット商品を生み出しながら国内で存在感を拡大。さらに海外ブランドを取り込み世界市場へ進出した。',
  ),
  _CompanyCardContent(
    companyId: 'kirin_holdings',
    overview: 'キリンホールディングスは、ビール、飲料、医薬・ヘルスサイエンスなどを展開する企業グループ。',
    businessTitle: '飲料から健康領域へ',
    business:
        'ビールや清涼飲料を中心に、医薬品や健康関連事業まで幅広く展開する。',
    strengthTitle: '発酵・バイオ技術の広がり',
    strength:
        'ビールづくりで培った発酵やバイオ技術を、飲料だけでなく医薬や健康分野へ応用している。',
    storyTitle: 'ビールからヘルスサイエンスへ',
    story:
        'ビール事業を源流に成長し、飲料や食品へ事業を広げた。現在は発酵・バイオ技術を生かし、健康領域へも挑戦している。',
  ),
  _CompanyCardContent(
    companyId: 'kikkoman',
    overview: 'キッコーマンは、しょうゆを中心に調味料、食品、飲料などを世界で展開する食品メーカー。',
    businessTitle: 'しょうゆを世界の食卓へ',
    business:
        'しょうゆを中心に、つゆ、たれ、食品、豆乳などを国内外で製造・販売する。',
    strengthTitle: '発酵技術と世界的ブランド',
    strength:
        '長年培った発酵・醸造技術と海外生産・販売網を持ち、日本の調味料文化を世界市場へ広げている。',
    storyTitle: '野田のしょうゆから世界へ',
    story:
        '千葉県野田のしょうゆ醸造を源流に持ち、品質の標準化と海外進出を進めた。日本食の普及とともに世界的な調味料メーカーへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'nichirei',
    overview: 'ニチレイは、冷凍食品、低温物流、水産・畜産品などを展開する食品企業グループ。',
    businessTitle: '冷凍食品と低温物流を支える',
    business:
        '家庭用・業務用の冷凍食品に加え、温度管理が必要な食品を運ぶ低温物流サービスなどを展開する。',
    strengthTitle: '冷凍と物流の一体運営',
    strength:
        '食品開発と低温物流の両方を持つことで、製造から保管・配送まで品質を保ちながら一貫して支えられる。',
    storyTitle: '戦後の食料供給から冷凍食品へ',
    story:
        '戦後の食料供給を支える事業を源流に持ち、冷蔵・冷凍技術を磨きながら食品と物流へ領域を拡大。日本の冷凍食品文化を支えてきた。',
  ),
  _CompanyCardContent(
    companyId: 'jt',
    overview: 'JTは、たばこを中心に医薬品や加工食品も手がける企業グループ。',
    businessTitle: '世界でたばこ事業を展開',
    business:
        '紙巻たばこや加熱式たばこなどを国内外で販売し、医薬品や加工食品などの事業も展開する。',
    strengthTitle: '世界規模のブランドと販売網',
    strength:
        '複数の国際ブランドと広い販売網を持ち、成熟市場でも安定した収益を生み出せる事業基盤が強み。',
    storyTitle: '専売事業からグローバル企業へ',
    story:
        '日本のたばこ専売事業を源流に民営化され、海外企業の買収を通じて世界市場へ進出。国内中心の企業からグローバル企業へ変化してきた。',
  ),
  _CompanyCardContent(
    companyId: 'j_front_retailing',
    overview: 'J.フロント リテイリングは、大丸・松坂屋や商業施設PARCOなどを展開する小売グループ。',
    businessTitle: '百貨店と商業施設を運営',
    business:
        '百貨店、ファッションビル、商業施設などを運営し、物販だけでなくテナント収入や不動産活用でも収益を得る。',
    strengthTitle: '都市型商業施設の運営力',
    strength:
        '百貨店の顧客基盤とPARCOの商業施設運営ノウハウを組み合わせ、都市ごとに異なる集客施設をつくれる。',
    storyTitle: '老舗百貨店とPARCOの融合',
    story:
        '大丸と松坂屋の経営統合を軸に誕生し、その後PARCOをグループ化。伝統的な百貨店と新しい商業施設の両方を持つ小売グループへ進化した。',
  ),
  _CompanyCardContent(
    companyId: 'zozo',
    overview: 'ZOZOは、ファッション通販サイトを中心に、アパレルECや計測・データ活用を展開する企業。',
    businessTitle: 'オンラインで服を売る仕組み',
    business:
        'ファッションECを運営し、ブランドの商品販売、広告、物流支援などを通じて収益を得る。',
    strengthTitle: '豊富な商品データと顧客基盤',
    strength:
        '多くのブランドと利用者が集まることで、商品・購買データを蓄積し、売り場改善や提案へ活用できる。',
    storyTitle: '音楽通販からファッションECへ',
    story:
        '輸入CDの通販から始まり、インターネット通販へ事業を広げた。そこからファッションに特化し、日本有数のECプラットフォームへ成長した。',
  ),
  _CompanyCardContent(
    companyId: 'isetan_mitsukoshi_holdings',
    overview: '三越伊勢丹ホールディングスは、三越や伊勢丹などの百貨店を中心に小売事業を展開する企業グループ。',
    businessTitle: '都市型百貨店を運営する',
    business:
        '百貨店で衣料品、化粧品、食品、高級品などを販売し、外商や不動産、カード事業なども展開する。',
    strengthTitle: '富裕層との強い顧客接点',
    strength:
        '長年の接客や外商で築いた顧客基盤と、都心の大型店舗を生かし、高付加価値な商品や体験を提供できる。',
    storyTitle: '老舗百貨店同士の統合',
    story:
        '長い歴史を持つ三越と伊勢丹が経営統合して誕生。それぞれのブランドや顧客基盤を受け継ぎ、都市型百貨店のあり方を進化させてきた。',
  ),
  _CompanyCardContent(
    companyId: 'seven_and_i',
    overview: 'セブン＆アイ・ホールディングスは、コンビニエンスストアを中心に小売や金融サービスを展開する企業グループ。',
    businessTitle: '日常の買い物を支える店舗網',
    business:
        'コンビニを中核に、食品や日用品の販売、ATMなどの金融サービスを幅広く提供する。',
    strengthTitle: '高密度な店舗網と商品開発力',
    strength:
        '多数の店舗から得られる販売データを活用し、地域や時間帯に合わせた商品開発と品ぞろえを磨ける。',
    storyTitle: 'コンビニ文化を日本に定着',
    story:
        '海外のコンビニモデルを日本へ導入し、独自の商品開発や物流を組み合わせて成長。身近な生活インフラとして定着させた。',
  ),
  _CompanyCardContent(
    companyId: 'mhi',
    overview: 'エネルギー、航空、防衛、宇宙など大型システムを手がける企業。',
    businessTitle: '社会基盤をつくる技術',
    business: '発電設備、航空機、防衛機器など長期プロジェクトを担う。',
    strengthTitle: '巨大システムの統合力',
    strength: '多分野の技術を組み合わせ、安全性が重要な設備を形にする。',
    storyTitle: '造船所から宇宙へ',
    story: '造船で培った総合工学を発展させ、陸・海・空・宇宙へ領域を広げた。',
  ),
  _CompanyCardContent(
    companyId: 'inpex',
    overview: '石油・天然ガスの開発と供給を行うエネルギー企業。',
    businessTitle: '資源を届ける開発力',
    business: '世界各地で資源を探鉱・開発し、天然ガスなどを供給する。',
    strengthTitle: '大型案件の遂行力',
    strength: '長期かつ大規模な資源開発を運営する知見を持つ。',
    storyTitle: '地下資源から次のエネルギーへ',
    story: '資源開発を基盤に、水素など低炭素エネルギーへの転換を模索する。',
  ),
];
