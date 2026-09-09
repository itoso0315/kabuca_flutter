import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/app/app.dart';
import 'package:kabuca_flutter/app/app_theme.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/screens/home/home_screen.dart';
import 'package:kabuca_flutter/screens/prediction/prediction_list_screen.dart';
import 'package:kabuca_flutter/screens/prediction/prediction_result_list_screen.dart';
import 'package:kabuca_flutter/services/prediction_resolution_service.dart';
import 'package:kabuca_flutter/services/stock_price_service.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';
import 'package:kabuca_flutter/widgets/prediction_auto_check.dart';
import 'package:kabuca_flutter/widgets/prediction_result_bell.dart';

import 'support/prediction_result_fixtures.dart';

PredictionStore _store(List<StockPrediction> predictions) =>
    PredictionStore.memory(predictions: predictions, now: () => resultTestNow);

PredictionResolutionService _service(
  PredictionStore store,
  ControlledClosingProvider provider,
) => PredictionResolutionService(
  predictionStore: store,
  stockPriceService: StockPriceService(provider),
  notificationStore: NotificationStore.memory(),
  now: () => store.now,
);

Widget _home(PredictionStore store, {PredictionResolutionService? service}) =>
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: HomeScreen(
          gameState: GameState.memory(
            cardCounts: {CardCatalog.cards.first.id: 1},
          ),
          predictionStore: store,
          notificationStore: NotificationStore.memory(),
          predictionResolutionService: service,
        ),
      ),
    );

void main() {
  testWidgets('予想中一覧は未来のtargetDateだけを表示し、期限到来・completedを含めない', (tester) async {
    final store = _store([
      resultFixture(id: 'future', targetDate: DateTime.utc(2026, 9, 9)),
      resultFixture(),
      resultFixture(id: 'today', targetDate: DateTime.utc(2026, 9, 8)),
      resultFixture(id: 'completed', status: PredictionStatus.completed),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: PredictionListScreen(store: store)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-future')), findsOneWidget);
    expect(find.textContaining('答え合わせ予定 9/9'), findsOneWidget);
    expect(find.byKey(const Key('prediction-due')), findsNothing);
    expect(find.byKey(const Key('prediction-today')), findsNothing);
    expect(find.byKey(const Key('prediction-completed')), findsNothing);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('結果側にはresolvingとcompletedを表示し、未来の予想を含めない', (tester) async {
    final store = _store([
      resultFixture(),
      resultFixture(id: 'completed', status: PredictionStatus.completed),
      resultFixture(id: 'future', targetDate: DateTime.utc(2026, 9, 9)),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: PredictionResultListScreen(store: store)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-result-due')), findsOneWidget);
    expect(find.text('結果確認中'), findsOneWidget);
    expect(find.text('終値の更新を待っています'), findsOneWidget);
    expect(
      find.byKey(const Key('prediction-result-completed')),
      findsOneWidget,
    );
    expect(find.text('結果を見る'), findsOneWidget);
    expect(find.text('獲得ポイント 50 KABU'), findsOneWidget);
    expect(find.byKey(const Key('prediction-result-future')), findsNothing);
    await tester.tap(find.byKey(const Key('prediction-result-completed')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-result-hero')), findsOneWidget);
    expect(find.text('予想的中！'), findsOneWidget);
  });

  testWidgets('未確認のresolving・completedだけをベルに数え、結果一覧を開くと減る', (tester) async {
    final store = _store([
      resultFixture(),
      resultFixture(id: 'completed', status: PredictionStatus.completed),
      resultFixture(id: 'seen', status: PredictionStatus.completed, seen: true),
      resultFixture(id: 'future', targetDate: DateTime.utc(2026, 9, 9)),
    ]);
    await tester.pumpWidget(_home(store));
    expect(
      tester
          .widget<Text>(find.byKey(const Key('notification-unread-badge')))
          .data,
      '2',
    );
    expect(store.unseenResultCount, 2);
    await tester.tap(find.byKey(const Key('notification-bell-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-result-list')), findsOneWidget);
    expect(store.unseenResultCount, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notification-unread-badge')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const Key('waiting-predictions-button')),
    );
    expect(find.text('予想中を見る（1）'), findsOneWidget);
  });

  testWidgets('結果画面を見ている間に確定した新しい結果は詳細を開くまで未確認', (tester) async {
    final store = _store([resultFixture()]);
    final provider = ControlledClosingProvider()..gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PredictionResultListScreen(
          store: store,
          resolutionService: _service(store, provider),
        ),
      ),
    );
    await tester.pump();
    expect(store.unseenResultCount, 0);
    provider.gate!.complete();
    await tester.pumpAndSettle();
    expect(store.predictions.single.status, PredictionStatus.completed);
    expect(store.unseenResultCount, 1);
    await tester.tap(find.byKey(const Key('prediction-result-due')));
    await tester.pumpAndSettle();
    expect(store.unseenResultCount, 0);
  });

  testWidgets('予想中画面を開くと自動確認が走り、失敗しても結果側に残って手動再試行できる', (tester) async {
    final store = _store([resultFixture()]);
    final provider = ControlledClosingProvider()
      ..error = const StockPriceException('offline');
    await tester.pumpWidget(_home(store, service: _service(store, provider)));
    await tester.ensureVisible(
      find.byKey(const Key('waiting-predictions-button')),
    );
    await tester.tap(find.byKey(const Key('waiting-predictions-button')));
    await tester.pumpAndSettle();
    expect(provider.calls, 1);
    expect(find.text('現在予想中の企業はありません'), findsOneWidget);
    expect(store.pendingPredictions, isEmpty);
    await tester.tap(find.byKey(const Key('notification-bell-button')));
    await tester.pumpAndSettle();
    expect(provider.calls, 1); // Automatic entry checks share the retry window.
    expect(find.text('結果確認中'), findsOneWidget);
    expect(find.text('結果を確認できませんでした'), findsOneWidget);
    expect(find.text('あとで再確認します'), findsOneWidget);
    provider.error = null;
    await tester.tap(find.byKey(const Key('check-prediction-results')));
    await tester.pumpAndSettle();
    expect(provider.calls, 2);
    expect(find.text('結果を見る'), findsOneWidget);
    expect(store.pendingPredictions, isEmpty);
  });

  testWidgets('予想する画面の入口でも自動結果確認が走る', (tester) async {
    final store = _store([resultFixture()]);
    final provider = ControlledClosingProvider();
    await tester.pumpWidget(_home(store, service: _service(store, provider)));
    await tester.ensureVisible(
      find.byKey(const Key('start-prediction-button')),
    );
    await tester.tap(find.byKey(const Key('start-prediction-button')));
    await tester.pumpAndSettle();
    expect(provider.calls, 1);
    expect(store.predictions.single.status, PredictionStatus.completed);
    expect(find.byKey(const Key('prediction-category-list')), findsOneWidget);
  });

  testWidgets('アプリ起動・復帰・ホームへの切り替えで自動確認し、背景ではポーリングしない', (tester) async {
    var now = resultTestNow;
    final store = PredictionStore.memory(
      predictions: [resultFixture()],
      now: () => now,
    );
    final provider = ControlledClosingProvider()
      ..error = const StockPriceException('offline');
    await tester.pumpWidget(
      KabucaApp(
        gameState: GameState.memory(),
        predictionStore: store,
        notificationStore: NotificationStore.memory(),
        predictionResolutionService: _service(store, provider),
      ),
    );
    await tester.pumpAndSettle();
    expect(provider.calls, 1);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(minutes: 2));
    expect(provider.calls, 1);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(provider.calls, 2);
    await tester.tap(find.text('図鑑'));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 2));
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(provider.calls, 3);
    expect(store.pendingPredictions, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('開いたまま予定日を迎えても予想中件数と結果バッジを自動更新する', (tester) async {
    var now = DateTime.utc(2026, 9, 7, 14, 59);
    final store = PredictionStore.memory(
      predictions: [resultFixture(targetDate: DateTime.utc(2026, 9, 8))],
      now: () => now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PredictionAutoCheck(
          store: store,
          child: Scaffold(
            body: Column(
              children: [
                ListenableBuilder(
                  listenable: store,
                  builder: (_, _) =>
                      Text('予想中${store.pendingPredictions.length}'),
                ),
                PredictionResultBell(store: store, onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('予想中1'), findsOneWidget);
    expect(find.byKey(const Key('notification-unread-badge')), findsNothing);
    now = DateTime.utc(2026, 9, 7, 15);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('予想中0'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('notification-unread-badge')))
          .data,
      '1',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('期限前だけなら結果は空、期限後だけなら予想中は空と案内する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PredictionResultListScreen(
          store: _store([resultFixture(targetDate: DateTime.utc(2026, 9, 9))]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('新しい結果はありません'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(home: PredictionListScreen(store: _store([resultFixture()]))),
    );
    await tester.pumpAndSettle();
    expect(find.text('現在予想中の企業はありません'), findsOneWidget);
  });

  testWidgets('iPhone縦画面で結果確認中と結果確定のカードを読める', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 667);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PredictionResultListScreen(
          store: _store([
            resultFixture(),
            resultFixture(id: 'completed', status: PredictionStatus.completed),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('結果を見る'), findsOneWidget);
    expect(find.text('結果確認中'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
