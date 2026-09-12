import 'dart:math';

import '../data/company_quiz_meta_repository.dart';
import '../data/company_stats_repository.dart';
import '../models/company_card.dart';
import '../models/company_quiz_meta.dart';
import '../models/company_stats.dart';
import '../models/quiz_question.dart';

class QuizService {
  static const maxDailyQuestions = 10;

  QuizService({
    this._repository,
    CompanyQuizMetaRepository? metaRepository,
    Random? random,
  }) : _metaRepository =
           metaRepository ?? CardCatalogCompanyQuizMetaRepository(),
       _random = random ?? Random();

  final CompanyStatsRepository? _repository;
  final CompanyQuizMetaRepository _metaRepository;
  final Random _random;

  Future<Map<String, CompanyStats>> loadStats() async =>
      _repository?.load() ?? {};

  Future<Map<String, CompanyQuizMeta>> loadMetadata() => _metaRepository.load();

  QuizQuestion? generateQuestion({
    required List<CompanyCard> ownedCards,
    required Map<String, CompanyQuizMeta> metadata,
    Set<String> excludedQuestionKeys = const {},
  }) {
    final comparableCards = ownedCards
        .where((card) => metadata.containsKey(card.companyId))
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
        final leftMeta = metadata[left.companyId]!;
        final rightMeta = metadata[right.companyId]!;
        if (leftMeta.industry != rightMeta.industry) continue;
        final rightFacts = rightMeta.quizFacts.toSet();
        final leftFacts = leftMeta.quizFacts.toSet();

        for (final fact in leftMeta.quizFacts.where(
          (fact) => !rightFacts.contains(fact),
        )) {
          _addCandidate(
            candidates,
            _Candidate(
              left: left,
              right: right,
              fact: fact,
              correctSide: QuizSide.left,
            ),
            excludedQuestionKeys,
          );
        }
        for (final fact in rightMeta.quizFacts.where(
          (fact) => !leftFacts.contains(fact),
        )) {
          _addCandidate(
            candidates,
            _Candidate(
              left: left,
              right: right,
              fact: fact,
              correctSide: QuizSide.right,
            ),
            excludedQuestionKeys,
          );
        }
      }
    }
    if (candidates.isEmpty) return null;

    final candidate = candidates[_random.nextInt(candidates.length)];
    return QuizQuestion(
      leftCard: candidate.left,
      rightCard: candidate.right,
      fact: candidate.fact,
      correctSide: candidate.correctSide,
      explanation: '${candidate.correctCard.companyName}は、${candidate.fact}。',
    );
  }

  String questionKey(QuizQuestion question) =>
      '${question.leftCard.id}|${question.rightCard.id}|${question.fact}';

  void _addCandidate(
    List<_Candidate> candidates,
    _Candidate candidate,
    Set<String> excludedQuestionKeys,
  ) {
    if (!excludedQuestionKeys.contains(candidate.key)) {
      candidates.add(candidate);
    }
  }
}

class _Candidate {
  const _Candidate({
    required this.left,
    required this.right,
    required this.fact,
    required this.correctSide,
  });

  final CompanyCard left;
  final CompanyCard right;
  final String fact;
  final QuizSide correctSide;

  CompanyCard get correctCard => correctSide == QuizSide.left ? left : right;

  String get key => '${left.id}|${right.id}|$fact';
}
