enum PredictionDirection {
  up,
  down;

  String get label => name.toUpperCase();
}

enum PredictionHorizon {
  nextTradingDay,
  oneWeek,
  oneMonth;

  String get label => switch (this) {
    nextTradingDay => '翌営業日',
    oneWeek => '1週間後',
    oneMonth => '1か月後',
  };
}

enum PredictionStatus { waiting, completed }

class StockPrediction {
  const StockPrediction({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.ticker,
    required this.direction,
    required this.horizon,
    required this.createdAt,
    required this.status,
    this.basePrice,
    this.basePriceAt,
    this.targetDate,
    this.resultPrice,
    this.resultPriceAt,
    this.changePercent,
    this.isCorrect,
    this.awardedPoints,
    this.baseReward,
    this.movementBonus,
    this.streakBonus,
    this.correctStreak,
    this.pointsClaimed,
    this.pointsClaimedAt,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String ticker;
  final PredictionDirection direction;
  final PredictionHorizon horizon;
  final DateTime createdAt;
  final PredictionStatus status;
  final double? basePrice;
  final DateTime? basePriceAt;
  final DateTime? targetDate;
  final double? resultPrice;
  final DateTime? resultPriceAt;
  final double? changePercent;
  final bool? isCorrect;
  final int? awardedPoints;
  final int? baseReward;
  final int? movementBonus;
  final int? streakBonus;
  final int? correctStreak;
  final bool? pointsClaimed;
  final DateTime? pointsClaimedAt;

  StockPrediction copyWith({
    PredictionStatus? status,
    double? resultPrice,
    DateTime? resultPriceAt,
    double? changePercent,
    bool? isCorrect,
    int? awardedPoints,
    int? baseReward,
    int? movementBonus,
    int? streakBonus,
    int? correctStreak,
    bool? pointsClaimed,
    DateTime? pointsClaimedAt,
  }) => StockPrediction(
    id: id,
    companyId: companyId,
    companyName: companyName,
    ticker: ticker,
    direction: direction,
    horizon: horizon,
    createdAt: createdAt,
    status: status ?? this.status,
    basePrice: basePrice,
    basePriceAt: basePriceAt,
    targetDate: targetDate,
    resultPrice: resultPrice ?? this.resultPrice,
    resultPriceAt: resultPriceAt ?? this.resultPriceAt,
    changePercent: changePercent ?? this.changePercent,
    isCorrect: isCorrect ?? this.isCorrect,
    awardedPoints: awardedPoints ?? this.awardedPoints,
    baseReward: baseReward ?? this.baseReward,
    movementBonus: movementBonus ?? this.movementBonus,
    streakBonus: streakBonus ?? this.streakBonus,
    correctStreak: correctStreak ?? this.correctStreak,
    pointsClaimed: pointsClaimed ?? this.pointsClaimed,
    pointsClaimedAt: pointsClaimedAt ?? this.pointsClaimedAt,
  );

  Map<String, Object> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'ticker': ticker,
      'direction': direction.name,
      'horizon': horizon.name,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'basePrice': ?basePrice,
      if (basePriceAt != null) 'basePriceAt': basePriceAt!.toIso8601String(),
      if (targetDate != null) 'targetDate': targetDate!.toIso8601String(),
      'resultPrice': ?resultPrice,
      if (resultPriceAt != null)
        'resultPriceAt': resultPriceAt!.toIso8601String(),
      'changePercent': ?changePercent,
      'isCorrect': ?isCorrect,
      'awardedPoints': ?awardedPoints,
      'baseReward': ?baseReward,
      'movementBonus': ?movementBonus,
      'streakBonus': ?streakBonus,
      'correctStreak': ?correctStreak,
      'pointsClaimed': ?pointsClaimed,
      if (pointsClaimedAt != null)
        'pointsClaimedAt': pointsClaimedAt!.toIso8601String(),
    };
  }

  factory StockPrediction.fromJson(Map<String, Object?> json) {
    return StockPrediction(
      id: json['id']! as String,
      companyId: json['companyId']! as String,
      companyName: json['companyName']! as String,
      ticker: json['ticker']! as String,
      direction: PredictionDirection.values.byName(
        json['direction']! as String,
      ),
      horizon: PredictionHorizon.values.byName(json['horizon']! as String),
      createdAt: DateTime.parse(json['createdAt']! as String),
      status: PredictionStatus.values.byName(json['status']! as String),
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      basePriceAt: json['basePriceAt'] == null
          ? null
          : DateTime.parse(json['basePriceAt']! as String),
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.parse(json['targetDate']! as String),
      resultPrice: (json['resultPrice'] as num?)?.toDouble(),
      resultPriceAt: json['resultPriceAt'] == null
          ? null
          : DateTime.parse(json['resultPriceAt']! as String),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
      isCorrect: json['isCorrect'] as bool?,
      awardedPoints: (json['awardedPoints'] as num?)?.toInt(),
      baseReward: (json['baseReward'] as num?)?.toInt(),
      movementBonus: (json['movementBonus'] as num?)?.toInt(),
      streakBonus: (json['streakBonus'] as num?)?.toInt(),
      correctStreak: (json['correctStreak'] as num?)?.toInt(),
      pointsClaimed: json['pointsClaimed'] as bool?,
      pointsClaimedAt: json['pointsClaimedAt'] == null
          ? null
          : DateTime.parse(json['pointsClaimedAt']! as String),
    );
  }
}
