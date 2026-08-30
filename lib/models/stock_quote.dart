class StockQuote {
  const StockQuote({
    required this.ticker,
    required this.price,
    required this.fetchedAt,
  });

  final String ticker;
  final double price;
  final DateTime fetchedAt;
}
