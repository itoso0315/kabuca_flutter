import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/screens/collection/collection_screen.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';
import 'package:kabuca_flutter/theme/company_theme.dart';
import 'package:kabuca_flutter/widgets/card_rarity_style.dart';

void main() {
  testWidgets('取得済みカードだけ詳細を開き、情報と取得状況を表示する', (tester) async {
    final ownedCard = CardCatalog.cards.first;
    final toyotaSr = CardCatalog.cards.firstWhere(
      (card) => card.companyId == 'toyota' && card.rarity == CardRarity.sr,
    );
    final state = GameState.memory(cardCounts: {ownedCard.id: 2});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CollectionScreen(
            gameState: state,
            predictionStore: PredictionStore.memory(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final collectionScroll = find.byKey(const Key('collection-scroll'));
    final toyotaNFinder = find.text(ownedCard.companyName);

    for (var i = 0; i < 80 && toyotaNFinder.evaluate().isEmpty; i++) {
      await tester.drag(collectionScroll, const Offset(0, -400));
      await tester.pumpAndSettle();
    }

    expect(toyotaNFinder, findsOneWidget);

    expect(find.byKey(const Key('card-detail-screen')), findsNothing);

    await tester.tap(toyotaNFinder.first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-detail-screen')), findsOneWidget);
    expect(find.text(ownedCard.companyName), findsWidgets);
    expect(find.textContaining(ownedCard.ticker), findsWidgets);
    expect(find.textContaining(ownedCard.industry), findsWidgets);
    expect(find.text(ownedCard.title), findsWidgets);
    expect(find.text(ownedCard.description), findsOneWidget);

    final artwork = tester.widget<Container>(
      find.byKey(const Key('card-artwork-surface')),
    );
    final decoration = artwork.decoration! as BoxDecoration;
    final rarityStyle = CardRarityStyle.of(ownedCard.rarity);
    expect(decoration.border!.top.color, rarityStyle.border);
    final innerContainers = find.descendant(
      of: find.byKey(const Key('card-artwork-surface')),
      matching: find.byType(Container),
    );
    final inner = tester.widgetList<Container>(innerContainers).last;
    final innerDecoration = inner.decoration! as BoxDecoration;
    final gradient = innerDecoration.gradient! as LinearGradient;
    expect(
      gradient.colors.last,
      CompanyTheme.forCompany(ownedCard.companyId).baseColor,
    );

    await tester.drag(
      find.byKey(const Key('card-detail-screen')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('所持 ×2'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('card-detail-screen')),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();

    for (final rarity in CardRarity.values) {
      expect(
        find.byKey(Key('company-rarity-status-${rarity.name}')),
        findsOneWidget,
      );
    }
    expect(find.text('取得済み'), findsOneWidget);
    expect(find.text('？？？'), findsNWidgets(3));
    expect(find.text(toyotaSr.title), findsNothing);
    expect(find.text(toyotaSr.description), findsNothing);
    expect(
      find.byKey(const Key('predict-this-company-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('predict-this-company-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prediction-screen')), findsOneWidget);
    expect(find.text(ownedCard.companyName), findsWidgets);
    expect(find.byKey(const Key('owned-insight-n')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-detail-screen')), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collection-scroll')), findsOneWidget);
  });
}
