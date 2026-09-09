import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/screens/prediction/prediction_screen.dart';
import 'package:kabuca_flutter/services/owned_company_service.dart';
import 'package:kabuca_flutter/services/stock_price_service.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

void main() {
  final body = File('test/fixtures/market_data_quote.json').readAsStringSync();

  for (final firstStatus in [200, 503]) {
    testWidgets('quote HTTP $firstStatusから予想を確定し価格・日時を永続保存する', (tester) async {
      final storage = _Storage();
      final store = await PredictionStore.load(storage: storage);
      var calls = 0;
      final client = MockClient((request) async {
        expect(request.url.path, '/api/market-data/quote');
        expect(request.url.queryParameters, {'ticker': '7203'});
        calls++;
        return calls == 1 && firstStatus != 200
            ? http.Response('{}', firstStatus)
            : http.Response(body, 200);
      });
      await _openAndSelect(tester, store, client);
      final save = find.byKey(const Key('save-prediction-button'));
      await tester.tap(save);
      await tester.tap(
        save,
      ); // A second tap before the rebuild cannot start another save.
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('prediction-complete')), findsOneWidget);
      expect(calls, firstStatus == 200 ? 1 : 2);
      expect(storage.writes, 1);
      final restored = await PredictionStore.load(storage: storage);
      final prediction = restored.predictions.single;
      expect(prediction.ticker, '7203');
      expect(prediction.basePrice, 2915.5);
      expect(prediction.basePriceAt, DateTime.utc(2026, 9, 8, 6, 30));
      expect(prediction.targetDate, DateTime.utc(2026, 9, 9));
      expect(prediction.status, PredictionStatus.waiting);
    });
  }

  for (final status in [404, 429, 503]) {
    testWidgets('quote HTTP $statusでは保存せず、原因に合う案内を表示する', (tester) async {
      final store = PredictionStore.memory();
      var calls = 0;
      await _openAndSelect(
        tester,
        store,
        MockClient((_) async {
          calls++;
          return http.Response('{}', status);
        }),
      );
      await tester.tap(find.byKey(const Key('save-prediction-button')));
      await tester.pumpAndSettle();

      expect(store.predictions, isEmpty);
      expect(calls, status == 503 ? 2 : 1);
      final message = tester
          .widget<Text>(find.byKey(const Key('prediction-error')))
          .data!;
      if (status == 404) {
        expect(message, contains('現在の株価データがありません'));
        expect(message, isNot(contains('時間をおいて')));
      } else {
        expect(message, contains(status == 429 ? 'アクセスが集中' : '一時的に取得できません'));
        expect(message, contains('時間をおいて再試行してください'));
      }
      expect(message, isNot(contains('https://')));
    });
  }

  testWidgets('保存失敗を株価取得失敗として表示しない', (tester) async {
    final storage = _Storage()..fail = true;
    final store = await PredictionStore.load(storage: storage);
    await _openAndSelect(
      tester,
      store,
      MockClient((_) async => http.Response(body, 200)),
    );
    await tester.tap(find.byKey(const Key('save-prediction-button')));
    await tester.pumpAndSettle();
    expect(store.predictions, isEmpty);
    expect(find.text('予想を保存できませんでした\n再試行してください'), findsOneWidget);
  });
}

Future<void> _openAndSelect(
  WidgetTester tester,
  PredictionStore store,
  http.Client client,
) async {
  final card = CardCatalog.cards.firstWhere((card) => card.ticker == '7203');
  await tester.pumpWidget(
    MaterialApp(
      home: PredictionScreen(
        company: OwnedCompanySummary(companyId: card.companyId, cards: [card]),
        predictionStore: store,
        stockPriceService: StockPriceService(
          BackendStockPriceProvider(client: client, retryDelay: Duration.zero),
        ),
        // Use the production calendar to cover the whole creation path.
      ),
    ),
  );
  await tester.ensureVisible(find.byKey(const Key('direction-up')));
  await tester.tap(find.byKey(const Key('direction-up')));
  await tester.ensureVisible(find.byKey(const Key('save-prediction-button')));
  await tester.pumpAndSettle();
}

class _Storage implements PredictionStorage {
  List<StockPrediction> values = [];
  int writes = 0;
  bool fail = false;

  @override
  Future<List<StockPrediction>> readPredictions() async => List.of(values);

  @override
  Future<void> writePredictions(List<StockPrediction> predictions) async {
    if (fail) throw StateError('storage unavailable');
    writes++;
    values = predictions
        .map((item) => StockPrediction.fromJson(item.toJson()))
        .toList();
  }
}
