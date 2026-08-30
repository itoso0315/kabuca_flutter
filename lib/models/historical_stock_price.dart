class HistoricalStockPrice {
  const HistoricalStockPrice({
    required this.ticker,
    required this.tradingDate,
    required this.close,
    required this.fetchedAt,
    this.splitDetected = false,
  });

  final String ticker;
  final DateTime tradingDate;
  final double close;
  final DateTime fetchedAt;
  final bool splitDetected;
}
