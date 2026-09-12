import 'company_card.dart';

enum QuizSide { left, right }

class QuizQuestion {
  const QuizQuestion({
    required this.leftCard,
    required this.rightCard,
    required this.fact,
    required this.correctSide,
    required this.explanation,
  });

  final CompanyCard leftCard;
  final CompanyCard rightCard;
  final String fact;
  final QuizSide correctSide;
  final String explanation;

  CardRarity get rarity => leftCard.rarity;

  int get rewardKabu => switch (rarity) {
    CardRarity.n => 5,
    CardRarity.r => 10,
    CardRarity.sr => 20,
    CardRarity.ur => 40,
  };
}
