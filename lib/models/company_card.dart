enum CardRarity {
  n,
  r,
  sr,
  ur;

  String get label => name.toUpperCase();
}

class CompanyCard {
  const CompanyCard({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.ticker,
    required this.industry,
    required this.rarity,
    required this.title,
    required this.description,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String ticker;
  final String industry;
  final CardRarity rarity;
  final String title;
  final String description;
}
