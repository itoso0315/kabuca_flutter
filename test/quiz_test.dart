import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/app/app.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/data/company_quiz_meta_repository.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/models/company_quiz_meta.dart';
import 'package:kabuca_flutter/models/company_stats.dart';
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

class _MemoryQuizMetaRepository implements CompanyQuizMetaRepository {
  _MemoryQuizMetaRepository(this.metadata);

  final Map<String, CompanyQuizMeta> metadata;

  @override
  Future<Map<String, CompanyQuizMeta>> load() async => metadata;
}

CompanyStats _stats(String companyId, double base) => CompanyStats(
  companyId: companyId,
  revenue: base,
  operatingMargin: base + 1,
  employees: base + 2,
  equityRatio: base + 3,
  fiscalYear: '2026-03',
);

CompanyQuizMeta _meta(
  String companyId,
  String fact, {
  String industry = 'その他',
}) => CompanyQuizMeta(
  companyId: companyId,
  industry: industry,
  mainBusiness: fact,
  businessTags: [industry],
  quizFacts: [fact],
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
final _nintendo = CardCatalog.cards.firstWhere(
  (card) => card.companyId == 'nintendo' && card.rarity == CardRarity.n,
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
    expect(find.text('クイズに挑戦するには、まず2社以上の企業カードを集めよう'), findsOneWidget);
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
    expect(find.byKey(const Key('quiz-empty-message')), findsNothing);

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
    expect(find.byKey(const Key('quiz-question-text')), findsOneWidget);
    expect(find.byKey(const Key('quiz-complete-message')), findsNothing);
  });

  testWidgets('出題終了後に同じレアリティのカードを集めると再び挑戦できる', (tester) async {
    final gameState = GameState.memory(
      cardCounts: {_toyota.id: 1, _honda.id: 1},
    );
    final service = QuizService(
      metaRepository: _MemoryQuizMetaRepository({
        'toyota': _meta('toyota', '自動車を手がける'),
        'honda': const CompanyQuizMeta(
          companyId: 'honda',
          industry: 'その他',
          mainBusiness: '自動車',
          businessTags: ['自動車'],
          quizFacts: [],
        ),
        'nintendo': _meta('nintendo', 'ゲームを手がける'),
      }),
      random: Random(1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          gameState: gameState,
          quizService: service,
          dailyProgressStore: MemoryQuizDailyProgressStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quiz-start-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quiz-choice-toyota')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('quiz-next-button'), skipOffstage: false),
    );
    tester
        .widget<FilledButton>(find.byKey(const Key('quiz-next-button')))
        .onPressed!();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-complete-message')), findsOneWidget);
    await gameState.addCards([_nintendo]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz-start-button')), findsOneWidget);
    expect(find.byKey(const Key('quiz-complete-message')), findsNothing);
  });

  test('クイズは所持していない企業を出題せず、同じ企業を比較しない', () {
    final service = QuizService(random: Random(1));
    final question = service.generateQuestion(
      ownedCards: [_toyota, _honda],
      metadata: {
        'toyota': _meta('toyota', '自動車を手がける'),
        'honda': _meta('honda', '二輪車を手がける'),
        'nintendo': _meta('nintendo', 'ゲームを手がける'),
      },
    );

    expect(question, isNotNull);
    expect(question!.leftCard.companyId, isNot('nintendo'));
    expect(question.rightCard.companyId, isNot('nintendo'));
    expect(question.leftCard.companyId, isNot(question.rightCard.companyId));
  });

  test('同じレアリティのカードを2社分集めると最低1問は出題できる', () {
    final question = QuizService(random: Random(1)).generateQuestion(
      ownedCards: [_toyota, _honda],
      metadata: {
        'toyota': _meta('toyota', '自動車を手がける'),
        'honda': _meta('honda', '二輪車を手がける'),
      },
    );

    expect(question, isNotNull);
  });

  test('異なる業種のカード同士は出題しない', () {
    final question = QuizService(random: Random(1)).generateQuestion(
      ownedCards: [_toyota, _honda],
      metadata: {
        'toyota': _meta('toyota', '自動車を手がける', industry: '自動車'),
        'honda': _meta('honda', '二輪車を手がける', industry: '輸送用機器'),
      },
    );

    expect(question, isNull);
  });

  test('異なるレアリティのカード同士は出題しない', () {
    final question = QuizService(random: Random(1)).generateQuestion(
      ownedCards: [_toyota, _hondaSr],
      metadata: {
        'toyota': _meta('toyota', '自動車を手がける'),
        'honda': _meta('honda', '二輪車を手がける'),
      },
    );

    expect(question, isNull);
  });

  test('両社に共通する事実だけでは出題しない', () {
    final question = QuizService(random: Random(1)).generateQuestion(
      ownedCards: [_toyota, _honda],
      metadata: {
        'toyota': _meta('toyota', 'モビリティを手がける'),
        'honda': _meta('honda', 'モビリティを手がける'),
      },
    );

    expect(question, isNull);
  });

  test('出題済み問題を除外し、次の問題を生成できる', () {
    final service = QuizService(random: Random(1));
    final metadata = {
      'toyota': CompanyQuizMeta(
        companyId: 'toyota',
        industry: '自動車',
        mainBusiness: '自動車',
        businessTags: ['自動車'],
        quizFacts: ['自動車を手がける', '金融サービスを展開する'],
      ),
      'honda': _meta('honda', '二輪車を手がける', industry: '自動車'),
    };
    final first = service.generateQuestion(
      ownedCards: [_toyota, _honda],
      metadata: metadata,
    );
    final next = service.generateQuestion(
      ownedCards: [_toyota, _honda],
      metadata: metadata,
      excludedQuestionKeys: {service.questionKey(first!)},
    );

    expect(next, isNotNull);
    expect(service.questionKey(next!), isNot(service.questionKey(first)));
  });

  test('2社未満ではクラッシュせず出題しない', () {
    final question = QuizService().generateQuestion(
      ownedCards: [_toyota],
      metadata: {'toyota': _meta('toyota', '自動車を手がける')},
    );

    expect(question, isNull);
  });

  test('高レアリティのカードは高い報酬を維持する', () {
    final question = QuizService(random: Random(1)).generateQuestion(
      ownedCards: [_toyotaSr, _hondaSr],
      metadata: {
        'toyota': _meta('toyota', '自動車を手がける'),
        'honda': _meta('honda', '二輪車を手がける'),
      },
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
