import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/app/app_theme.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/screens/prediction/company_prediction_select_screen.dart';
import 'package:kabuca_flutter/screens/prediction/prediction_category_select_screen.dart';
import 'package:kabuca_flutter/screens/prediction/prediction_screen.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

CompanyCard _card(String companyId, [CardRarity rarity = CardRarity.n]) =>
    CardCatalog.cards.firstWhere(
      (card) => card.companyId == companyId && card.rarity == rarity,
    );

GameState _ownedCompanies() => GameState.memory(
  cardCounts: {
    _card('toyota').id: 3,
    _card('toyota', CardRarity.sr).id: 1,
    _card('honda').id: 1,
    _card('ntt').id: 1,
    _card('kddi').id: 1,
    _card('agc').id: 1,
  },
);

const _searchKey = Key('prediction-company-search');

Future<void> _showCategories(
  WidgetTester tester, {
  GameState? gameState,
  PredictionStore? predictionStore,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: PredictionCategorySelectScreen(
      gameState: gameState ?? _ownedCompanies(),
      predictionStore: predictionStore ?? PredictionStore.memory(),
    ),
  ),
);

Future<void> _enterCategory(WidgetTester tester, String companyId) async {
  final category = find.byKey(
    Key('prediction-category-${_card(companyId).industry}'),
  );
  await tester.ensureVisible(category);
  await tester.tap(category);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('所有企業のindustryを初出順で重複なく表示し、枚数やレアリティではなく企業数を数える', (tester) async {
    await _showCategories(tester);

    expect(find.text('予想する企業'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    final categories = tester.widgetList<ListTile>(
      find.descendant(
        of: find.byKey(const Key('prediction-category-list')),
        matching: find.byType(ListTile),
      ),
    );
    // In CardCatalog, AGC precedes Honda, which precedes KDDI.
    expect(categories.map((tile) => (tile.title! as Text).data), [
      _card('agc').industry,
      _card('honda').industry,
      _card('kddi').industry,
    ]);
    for (final (companyId, count) in [('agc', 1), ('toyota', 2), ('ntt', 2)]) {
      expect(
        tester
            .widget<Text>(
              find.byKey(
                Key('prediction-category-count-${_card(companyId).industry}'),
              ),
            )
            .data,
        '$count社',
      );
    }
    expect(
      find.byKey(Key('prediction-category-${_card('nintendo').industry}')),
      findsNothing,
    );
    expect(find.byKey(const Key('prediction-company-toyota')), findsNothing);
  });

  testWidgets('カテゴリを開くと同industryの所有企業だけを従来の順序と情報で表示する', (tester) async {
    await _showCategories(tester);
    await _enterCategory(tester, 'toyota');

    expect(find.byType(CompanyPredictionSelectScreen), findsOneWidget);
    expect(
      find.widgetWithText(AppBar, _card('toyota').industry),
      findsOneWidget,
    );
    expect(find.byKey(_searchKey), findsOneWidget);
    final companies = tester.widgetList<ListTile>(find.byType(ListTile));
    expect(companies.map((tile) => tile.key), const [
      Key('prediction-company-toyota'),
      Key('prediction-company-honda'),
    ]);
    expect(find.byKey(const Key('prediction-company-ntt')), findsNothing);
    expect(find.byKey(const Key('prediction-company-agc')), findsNothing);
    expect(
      find.byKey(const Key('prediction-company-nissan_motor')),
      findsNothing,
    );
    expect(find.textContaining('最高レアリティ：SR'), findsOneWidget);
    expect(find.textContaining('2 / 4種類取得'), findsOneWidget);
  });

  testWidgets('企業名の部分一致検索とindustry絞り込みを併用し、検索解除で元の一覧に戻る', (tester) async {
    await _showCategories(tester);
    await _enterCategory(tester, 'toyota');
    await tester.enterText(find.byKey(_searchKey), 'トヨ');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-company-toyota')), findsOneWidget);
    expect(find.byKey(const Key('prediction-company-honda')), findsNothing);

    await tester.enterText(find.byKey(_searchKey), 'NTT');
    await tester.pumpAndSettle();
    expect(find.text('一致する企業がありません'), findsOneWidget);
    expect(find.byKey(const Key('prediction-company-ntt')), findsNothing);
    expect(find.byType(ListTile), findsNothing);

    await tester.tap(find.byKey(const Key('prediction-company-search-clear')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(_searchKey)).controller!.text,
      isEmpty,
    );
    expect(find.byKey(const Key('prediction-company-toyota')), findsOneWidget);
    expect(find.byKey(const Key('prediction-company-honda')), findsOneWidget);
    expect(find.byKey(const Key('prediction-company-ntt')), findsNothing);
  });

  testWidgets('銘柄コードでも部分一致検索でき、別industryのコードは表示しない', (tester) async {
    await _showCategories(tester);
    await _enterCategory(tester, 'toyota');
    for (final query in ['720', '7203']) {
      await tester.enterText(find.byKey(_searchKey), query);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('prediction-company-toyota')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('prediction-company-honda')), findsNothing);
    }
    await tester.enterText(find.byKey(_searchKey), _card('ntt').ticker);
    await tester.pumpAndSettle();
    expect(find.text('一致する企業がありません'), findsOneWidget);
    expect(find.byKey(const Key('prediction-company-ntt')), findsNothing);
  });

  testWidgets('英字企業名は大文字小文字と前後の空白を区別せず検索できる', (tester) async {
    await _showCategories(tester);
    await _enterCategory(tester, 'ntt');
    await tester.enterText(find.byKey(_searchKey), ' nT ');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-company-ntt')), findsOneWidget);
    expect(find.byKey(const Key('prediction-company-kddi')), findsNothing);
  });

  testWidgets('企業をタップすると既存の予想入力へ進み、戻るとカテゴリ内の検索状態を維持する', (tester) async {
    final store = PredictionStore.memory();
    await _showCategories(tester, predictionStore: store);
    await _enterCategory(tester, 'toyota');
    await tester.enterText(find.byKey(_searchKey), 'トヨタ');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prediction-company-toyota')));
    await tester.pumpAndSettle();

    final prediction = tester.widget<PredictionScreen>(
      find.byType(PredictionScreen),
    );
    expect(prediction.predictionStore, same(store));
    expect(prediction.company.companyId, 'toyota');
    expect(prediction.company.highestRarity, CardRarity.sr);
    expect(prediction.company.ownedRarityCount, 2);
    expect(find.byKey(const Key('prediction-screen')), findsOneWidget);
    expect(find.byKey(const Key('owned-insight-n')), findsOneWidget);
    expect(find.byKey(const Key('owned-insight-sr')), findsOneWidget);
    expect(find.byKey(const Key('owned-insight-ur')), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byKey(_searchKey)).controller!.text,
      'トヨタ',
    );
    expect(find.byKey(const Key('prediction-company-honda')), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-category-list')), findsOneWidget);
    await _enterCategory(tester, 'ntt');
    expect(
      tester.widget<TextField>(find.byKey(_searchKey)).controller!.text,
      isEmpty,
    );
    expect(find.byKey(const Key('prediction-company-ntt')), findsOneWidget);
    expect(find.byKey(const Key('prediction-company-kddi')), findsOneWidget);
    expect(store.predictions, isEmpty);
  });

  testWidgets('所有状態が変わればカテゴリの企業数と企業一覧も更新する', (tester) async {
    final gameState = GameState.memory(cardCounts: {_card('toyota').id: 1});
    await _showCategories(tester, gameState: gameState);
    await gameState.addCards([_card('honda'), _card('toyota', CardRarity.r)]);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
            find.byKey(
              Key('prediction-category-count-${_card('toyota').industry}'),
            ),
          )
          .data,
      '2社',
    );
    await _enterCategory(tester, 'toyota');
    expect(find.byKey(const Key('prediction-company-honda')), findsOneWidget);
    await gameState.resetDevelopmentData();
    await tester.pumpAndSettle();
    expect(find.text('このカテゴリで予想できる企業がありません'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('prediction-company-empty-state')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('prediction-category-list')), findsNothing);
  });

  testWidgets('iPhoneの縦画面でカテゴリカードと企業一覧を表示し検索できる', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 667);
    tester.view.padding = const FakeViewPadding(top: 20);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);
    await _showCategories(tester);
    expect(tester.takeException(), isNull);
    await _enterCategory(tester, 'toyota');
    expect(
      find.byKey(const Key('prediction-company-toyota')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(_searchKey), '7203');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('prediction-company-toyota')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
