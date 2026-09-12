import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/app/app.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/models/company_stats.dart';
import 'package:kabuca_flutter/models/quiz_question.dart';
import 'package:kabuca_flutter/data/company_stats_repository.dart';
import 'package:kabuca_flutter/screens/quiz/quiz_screen.dart';
import 'package:kabuca_flutter/services/quiz_service.dart';
import 'package:kabuca_flutter/services/quiz_daily_progress_store.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/point_wallet.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

class _MemoryStatsRepository implements CompanyStatsRepository {
  _MemoryStatsRepository(this.stats);

  final Map<String, CompanyStats> stats;

  @override
  Future<Map<String, CompanyStats>> load() async => stats;
}

CompanyStats _stats(String companyId, double base) => CompanyStats(
  companyId: companyId,
  revenue: base,
  operatingMargin: base + 1,
  employees: base + 2,
  equityRatio: base + 3,
  fiscalYear: '2026-03',
);

final _toyota = CardCatalog.cards.firstWhere(
  (card) => card.companyId == 'toyota' && card.rarity == CardRarity.n,
);
final _honda = CardCatalog.cards.firstWhere(
  (card) => card.companyId == 'honda' && card.rarity == CardRarity.n,
);
final _toyotaSr = CardCatalog.cards.firstWhere(
  (card) => card.companyId == 'toyota' && card.rarity == CardRarity.sr,
);
final _hondaSr = CardCatalog.cards.firstWhere(
  (card) => card.companyId == 'honda' && card.rarity == CardRarity.sr,
);
void main() {
  testWidgets('クイズタブを開くと所持カード不足の空状態が表示される', (tester) async {
    await tester.pumpWidget(
      KabucaApp(
        gameState: GameState.memory(),
        predictionStore: PredictionStore.memory(),
        notificationStore: NotificationStore.memory(),
        dailyProgressStore: MemoryQuizDailyProgressStore(),
      ),
    );

    await tester.tap(find.text('クイズ'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-screen')), findsOneWidget);
    expect(find.byKey(const Key('quiz-empty-message')), findsOneWidget);
    expect(find.text('クイズに挑戦するには、まず2社以上のカードを集めよう'), findsOneWidget);
  });

  testWidgets('所持カード2社を比較し、回答後に数値と次の問題を表示できる', (tester) async {
    final gameState = GameState.memory(
      cardCounts: {_toyota.id: 1, _honda.id: 1},
    );
    final repository = _MemoryStatsRepository({
      'toyota': _stats('toyota', 100),
      'honda': _stats('honda', 50),
    });
    final service = QuizService(repository: repository, random: Random(1));
    final pointWallet = PointWallet.memory();
    final dailyProgressStore = MemoryQuizDailyProgressStore();

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          gameState: gameState,
          pointWallet: pointWallet,
          quizService: service,
          dailyProgressStore: dailyProgressStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-start-button')), findsOneWidget);
    expect(find.byKey(const Key('quiz-question-text')), findsNothing);
    await tester.tap(find.byKey(const Key('quiz-start-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-question-text')), findsOneWidget);
    expect(find.byKey(const Key('quiz-choice-toyota')), findsOneWidget);
    expect(find.byKey(const Key('quiz-choice-honda')), findsOneWidget);
    expect(find.text('クイズに挑戦するには、まず2社以上のカードを集めよう'), findsNothing);

    final leftChoice = find.byKey(const Key('quiz-choice-toyota'));
    await tester.ensureVisible(leftChoice);
    await tester.tap(leftChoice);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-result')), findsOneWidget);
    expect(find.byKey(const Key('quiz-reward')), findsOneWidget);
    expect(pointWallet.currentPoints, 5);
    expect(find.byKey(const Key('quiz-answer-summary')), findsOneWidget);
    expect(find.byKey(const Key('quiz-explanation')), findsOneWidget);
    expect(find.byKey(const Key('quiz-next-button')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('quiz-next-button'), skipOffstage: false),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    tester
        .widget<FilledButton>(find.byKey(const Key('quiz-next-button')))
        .onPressed!();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quiz-question-text')), findsNothing);
    expect(find.byKey(const Key('quiz-complete-message')), findsOneWidget);
  });

  test('クイズサービスは所持していない企業を出題せず、企業を重複させない', () async {
    final service = QuizService(
      repository: _MemoryStatsRepository(const {}),
      random: Random(1),
    );
    final stats = {
      'toyota': _stats('toyota', 100),
      'honda': _stats('honda', 50),
      'nintendo': _stats('nintendo', 25),
    };

    final question = service.generateQuestion(
      ownedCards: [_toyota, _honda],
      stats: stats,
    );

    expect(question, isNotNull);
    expect(question!.leftCard.companyId, isNot('nintendo'));
    expect(question.rightCard.companyId, isNot('nintendo'));
    expect(question.leftCard.companyId, isNot(question.rightCard.companyId));
    expect(question.correctSide, QuizSide.left);
  });

  test('同値しかない比較は出題しない', () {
    final service = QuizService(
      repository: _MemoryStatsRepository(const {}),
      random: Random(1),
    );
    final sameStats = {
      'toyota': _stats('toyota', 100),
      'honda': _stats('honda', 100),
    };

    final question = service.generateQuestion(
      ownedCards: [_toyota, _honda],
      stats: sameStats,
    );

    expect(question, isNull);
  });

  test('出題済み問題は次の問題として再生成しない', () {
    final service = QuizService(
      repository: _MemoryStatsRepository(const {}),
      random: Random(1),
    );
    final stats = {
      'toyota': _stats('toyota', 100),
      'honda': _stats('honda', 50),
    };
    final first = service.generateQuestion(
      ownedCards: [_toyota, _honda],
      stats: stats,
    );

    final next = service.generateQuestion(
      ownedCards: [_toyota, _honda],
      stats: stats,
      excludedQuestionKeys: {service.questionKey(first!)},
    );

    expect(next, isNull);
  });

  test('レアリティが混在していても同じレアリティ同士だけを出題する', () {
    final service = QuizService(
      repository: _MemoryStatsRepository(const {}),
      random: Random(1),
    );
    final stats = {
      'toyota': _stats('toyota', 100),
      'honda': _stats('honda', 50),
    };

    for (var attempt = 0; attempt < 20; attempt++) {
      final question = service.generateQuestion(
        ownedCards: [_toyota, _honda, _toyotaSr, _hondaSr],
        stats: stats,
      );
      expect(question, isNotNull);
      expect(question!.leftCard.rarity, question.rightCard.rarity);
      expect(question.leftCard.companyId, isNot(question.rightCard.companyId));
    }
  });

  test('高レアリティの正解報酬は大きい', () {
    final service = QuizService(
      repository: _MemoryStatsRepository(const {}),
      random: Random(1),
    );
    final question = service.generateQuestion(
      ownedCards: [_toyotaSr, _hondaSr],
      stats: {'toyota': _stats('toyota', 100), 'honda': _stats('honda', 50)},
    );

    expect(question!.rewardKabu, 20);
  });

  test('統計JSONの読み込みに失敗してもクラッシュせず空データを返す', () async {
    final repository = AssetCompanyStatsRepository(
      loadJson: () async => throw StateError('test failure'),
    );

    expect(await repository.load(), isEmpty);
  });

  testWidgets('1日10問到達済みならクイズを開始できない', (tester) async {
    final dailyProgressStore = MemoryQuizDailyProgressStore();
    for (var index = 0; index < QuizService.maxDailyQuestions; index++) {
      await dailyProgressStore.record('question-$index');
    }
    final gameState = GameState.memory(
      cardCounts: {_toyota.id: 1, _honda.id: 1},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          gameState: gameState,
          quizService: QuizService(
            repository: _MemoryStatsRepository({
              'toyota': _stats('toyota', 100),
              'honda': _stats('honda', 50),
            }),
          ),
          dailyProgressStore: dailyProgressStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-complete-message')), findsOneWidget);
    expect(find.text('今日は10問までです。明日また挑戦しよう。'), findsOneWidget);
    expect(find.byKey(const Key('quiz-start-button')), findsNothing);
  });
}
