import '../models/company_card.dart';
import 'company_master.dart';

abstract final class CardCatalog {
  static final List<CompanyCard> cards = List.unmodifiable(
    _companies.expand((content) {
      final company = CompanyMaster.byId(content.companyId);
      if (company == null) {
        throw StateError(
          'Unknown companyId in CardCatalog: ${content.companyId}',
        );
      }
      return CardRarity.values.map(
        (rarity) => CompanyCard(
          id: '${content.companyId}_${rarity.name}',
          companyId: content.companyId,
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

  static int get companyCount => _companies.length;
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

const _companies = <_CompanyCardContent>[
  _CompanyCardContent(
    companyId: 'toyota',
    overview: '世界各地で自動車を開発・生産・販売する総合モビリティ企業。',
    businessTitle: '移動を支える量産力',
    business: '乗用車を中心に、金融や部品など幅広い事業で収益を生み出す。',
    strengthTitle: '世界を走る生産力',
    strength: '改善を積み重ねる生産方式と、世界規模の販売網が強み。',
    storyTitle: '織機からモビリティへ',
    story: '織機の技術を源流に自動車へ進出し、世界企業へ成長した。',
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
    overview: '医療用医薬品を研究・開発し世界へ届ける企業。',
    businessTitle: '新薬を生む研究開発',
    business: '消化器、希少疾患などを中心にグローバルで医薬品を展開する。',
    strengthTitle: '世界規模の開発基盤',
    strength: '研究から臨床開発、販売まで国際的な体制を持つ。',
    storyTitle: '道修町から世界の医療へ',
    story: '大阪の薬種商を起点に、長い歴史を持つグローバル製薬企業へ進化した。',
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
