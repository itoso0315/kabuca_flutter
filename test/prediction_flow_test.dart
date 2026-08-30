import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/models/stock_quote.dart';
import 'package:kabuca_flutter/screens/home/home_screen.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';
import 'package:kabuca_flutter/services/stock_price_service.dart';
import 'package:kabuca_flutter/services/trading_calendar_service.dart';

void main() {
  testWidgets('所持情報だけを参照してUP予想を保存し結果待ち一覧で確認できる', (tester) async {
    CompanyCard cardFor(CardRarity rarity) => CardCatalog.cards.firstWhere(
      (card) => card.companyId == 'toyota' && card.rarity == rarity,
    );
    final toyotaN = cardFor(CardRarity.n);
    final toyotaSr = cardFor(CardRarity.sr);
    final gameState = GameState.memory(
      cardCounts: {toyotaN.id: 1, toyotaSr.id: 1},
    );
    final predictionStore = PredictionStore.memory();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            gameState: gameState,
            predictionStore: predictionStore,
            stockPriceService: StockPriceService(_SuccessfulQuoteProvider()),
            tradingCalendarService: TradingCalendarService(
              holidayProvider: _NoHolidays(),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('start-prediction-button')),
    );
    await tester.tap(find.byKey(const Key('start-prediction-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-company-toyota')), findsOneWidget);
    expect(find.byKey(const Key('prediction-company-nintendo')), findsNothing);
    expect(find.textContaining('最高レアリティ：SR'), findsOneWidget);
    expect(find.textContaining('2 / 4種類取得'), findsOneWidget);

    await tester.tap(find.byKey(const Key('prediction-company-toyota')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('owned-insight-n')), findsOneWidget);
    expect(find.byKey(const Key('owned-insight-sr')), findsOneWidget);
    expect(find.byKey(const Key('owned-insight-r')), findsNothing);
    expect(find.byKey(const Key('owned-insight-ur')), findsNothing);
    expect(find.text(cardFor(CardRarity.r).description), findsNothing);
    expect(find.text(cardFor(CardRarity.ur).description), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('horizon-oneWeek')));
    await tester.tap(find.byKey(const Key('horizon-oneWeek')));
    await tester.drag(
      find.byKey(const Key('prediction-screen')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('direction-up')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-prediction-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-complete')), findsOneWidget);
    expect(find.text('1週間後  UP'), findsOneWidget);
    expect(find.text('基準株価  ¥12,340'), findsOneWidget);
    expect(find.text('答え合わせ予定  2026/09/07'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '企業一覧へ戻る'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('waiting-predictions-button')),
    );
    await tester.tap(find.byKey(const Key('waiting-predictions-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-list')), findsOneWidget);
    expect(find.text('トヨタ自動車'), findsOneWidget);
    expect(find.textContaining('1週間後'), findsOneWidget);
    expect(find.textContaining('UP  ・  結果待ち'), findsOneWidget);
  });
}

class _SuccessfulQuoteProvider implements StockPriceProvider {
  @override
  Future<StockQuote> fetchQuote({
    required String ticker,
    required String companyId,
  }) async => StockQuote(
    ticker: ticker,
    price: 12340,
    fetchedAt: DateTime.utc(2026, 8, 31, 6),
  );
}

class _NoHolidays implements TradingHolidayProvider {
  @override
  bool isHoliday(DateTime japanDate) => false;
}
