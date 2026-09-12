import 'dart:math';

import '../models/company_card.dart';
import '../models/company_stats.dart';
import '../models/quiz_question.dart';
import '../data/company_stats_repository.dart';

class QuizService {
  static const maxDailyQuestions = 10;

  QuizService({required this.repository, Random? random})
    : _random = random ?? Random();

  final CompanyStatsRepository repository;
  final Random _random;

  Future<Map<String, CompanyStats>> loadStats() => repository.load();

  QuizQuestion? generateQuestion({
    required List<CompanyCard> ownedCards,
    required Map<String, CompanyStats> stats,
    Set<String> excludedQuestionKeys = const {},
  }) {
    final comparableCards = ownedCards
        .where((card) => stats.containsKey(card.companyId))
        .toList();
    if (comparableCards.length < 2) return null;

    final candidates = <_Candidate>[];
    for (var leftIndex = 0; leftIndex < comparableCards.length; leftIndex++) {
      for (
        var rightIndex = leftIndex + 1;
        rightIndex < comparableCards.length;
        rightIndex++
      ) {
        final left = comparableCards[leftIndex];
        final right = comparableCards[rightIndex];
        if (left.companyId == right.companyId || left.rarity != right.rarity) {
          continue;
        }
        for (final metric in _metricsFor(left.rarity)) {
          final leftValue = stats[left.companyId]!.valueFor(metric);
          final rightValue = stats[right.companyId]!.valueFor(metric);
          if (leftValue != rightValue) {
            final candidate = _Candidate(
              left: left,
              right: right,
              metric: metric,
              leftValue: leftValue,
              rightValue: rightValue,
            );
            if (!excludedQuestionKeys.contains(candidate.key)) {
              candidates.add(candidate);
            }
          }
        }
      }
    }
    if (candidates.isEmpty) return null;

    final candidate = candidates[_random.nextInt(candidates.length)];
    return QuizQuestion(
      leftCard: candidate.left,
      rightCard: candidate.right,
      metric: candidate.metric,
      leftValue: candidate.leftValue,
      rightValue: candidate.rightValue,
      explanation: _explanation(candidate),
    );
  }

  String questionKey(QuizQuestion question) =>
      '${question.leftCard.id}|${question.rightCard.id}|${question.metric.name}';

  List<QuizMetric> _metricsFor(CardRarity rarity) => switch (rarity) {
    CardRarity.n => [QuizMetric.revenue],
    CardRarity.r => [QuizMetric.revenue, QuizMetric.employees],
    CardRarity.sr => [
      QuizMetric.employees,
      QuizMetric.operatingMargin,
      QuizMetric.equityRatio,
    ],
    CardRarity.ur => [QuizMetric.operatingMargin, QuizMetric.equityRatio],
  };

  String _explanation(_Candidate candidate) {
    final winner = candidate.leftValue > candidate.rightValue
        ? candidate.left.companyName
        : candidate.right.companyName;
    return '$winnerの${candidate.metric.label}が大きい比較です。'
        'カードの企業ごとに、得意な事業のスケールや収益の特徴が異なります。';
  }
}

class _Candidate {
  const _Candidate({
    required this.left,
    required this.right,
    required this.metric,
    required this.leftValue,
    required this.rightValue,
  });

  final CompanyCard left;
  final CompanyCard right;
  final QuizMetric metric;
  final double leftValue;
  final double rightValue;

  String get key => '${left.id}|${right.id}|${metric.name}';
}
