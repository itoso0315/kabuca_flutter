import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/stock_quote.dart';
import 'package:kabuca_flutter/screens/prediction/prediction_screen.dart';
import 'package:kabuca_flutter/services/owned_company_service.dart';
import 'package:kabuca_flutter/services/stock_price_service.dart';
import 'package:kabuca_flutter/services/trading_calendar_service.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

void main() {
  testWidgets('株価取得失敗時は保存せず、再試行でDOWN予想を保存できる', (tester) async {
    final provider = _FailOnceProvider();
    final store = PredictionStore.memory();
    final card = CardCatalog.cards.first;
    await tester.pumpWidget(
      MaterialApp(
        home: PredictionScreen(
          company: OwnedCompanySummary(
            companyId: card.companyId,
            cards: [card],
          ),
          predictionStore: store,
          stockPriceService: StockPriceService(provider),
          tradingCalendarService: TradingCalendarService(
            holidayProvider: _NoHolidays(),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('direction-down')));
    await tester.tap(find.byKey(const Key('direction-down')));
    await tester.drag(
      find.byKey(const Key('prediction-screen')),
      const Offset(0, -160),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-prediction-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('prediction-error')), findsOneWidget);
    expect(store.predictions, isEmpty);

    await tester.tap(find.byKey(const Key('save-prediction-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('prediction-complete')), findsOneWidget);
    expect(store.predictions.single.direction.name, 'down');
    expect(store.predictions.single.basePrice, 4321);
    expect(provider.calls, 2);
  });
}

class _FailOnceProvider implements StockPriceProvider {
  int calls = 0;

  @override
  Future<StockQuote> fetchQuote({
    required String ticker,
    required String companyId,
  }) async {
    calls++;
    if (calls == 1) {
      throw const StockPriceException('通信に失敗しました');
    }
    return StockQuote(
      ticker: ticker,
      price: 4321,
      fetchedAt: DateTime.utc(2026, 8, 31, 6),
    );
  }
}

class _NoHolidays implements TradingHolidayProvider {
  @override
  bool isHoliday(DateTime japanDate) => false;
}
