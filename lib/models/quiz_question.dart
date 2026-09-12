import 'company_card.dart';
import 'company_stats.dart';

enum QuizSide { left, right }

class QuizQuestion {
  const QuizQuestion({
    required this.leftCard,
    required this.rightCard,
    required this.metric,
    required this.leftValue,
    required this.rightValue,
    required this.explanation,
  });

  final CompanyCard leftCard;
  final CompanyCard rightCard;
  final QuizMetric metric;
  final double leftValue;
  final double rightValue;
  final String explanation;

  QuizSide get correctSide =>
      leftValue > rightValue ? QuizSide.left : QuizSide.right;

  CardRarity get rarity => leftCard.rarity;

  int get rewardKabu => switch (rarity) {
    CardRarity.n => 5,
    CardRarity.r => 10,
    CardRarity.sr => 20,
    CardRarity.ur => 40,
  };
}
