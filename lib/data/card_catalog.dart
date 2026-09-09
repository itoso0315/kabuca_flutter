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
    overview: '銀行、信託、証券などを展開する総合金融グループ。',
    businessTitle: '金融の総合力',
    business: '預金・融資に加え、資産運用や決済など多様な金融サービスを提供する。',
    strengthTitle: '国内外の顧客基盤',
    strength: '幅広い法人・個人顧客と海外ネットワークを持つ。',
    storyTitle: '統合が築いた金融基盤',
    story: '複数の銀行の歴史を受け継ぎ、巨大な総合金融グループとなった。',
  ),
  _CompanyCardContent(
    companyId: 'ntt',
    overview: '通信ネットワークを基盤にデジタルサービスを展開する企業。',
    businessTitle: '社会を結ぶ通信網',
    business: '固定・携帯通信や法人向けITサービスが事業の柱。',
    strengthTitle: '研究開発とインフラ',
    strength: '全国規模の通信基盤と長期的な研究開発力を持つ。',
    storyTitle: '電話から次世代通信へ',
    story: '通信インフラを支えながら、光技術を軸に次世代ネットワークへ挑む。',
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
    overview: '調味料や食品、アミノ酸技術を世界展開する企業。',
    businessTitle: '食とアミノ酸の二本柱',
    business: '食品に加え、ヘルスケアや電子材料にもアミノ酸技術を生かす。',
    strengthTitle: 'アミノサイエンス',
    strength: '長年蓄積したアミノ酸の研究を多様な産業へ展開できる。',
    storyTitle: 'うま味発見から広がる科学',
    story: 'うま味を届ける事業から始まり、生命科学へ領域を広げた。',
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
