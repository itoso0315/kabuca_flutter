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
    );
  }
}
