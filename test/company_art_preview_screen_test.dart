import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/data/company_master.dart';
import 'package:kabuca_flutter/screens/debug/company_art_preview_screen.dart';
import 'package:kabuca_flutter/screens/profile/profile_screen.dart';
import 'package:kabuca_flutter/services/card_pack_service.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';
import 'package:kabuca_flutter/theme/company_artwork_registry.dart';
import 'package:kabuca_flutter/widgets/company_card_artwork.dart';

void main() {
  setUp(CompanyArtworkRegistry.resetCacheForTesting);

  testWidgets('通常一覧は画像あり企業のみでfallback表示時は全企業を描画する', (tester) async {
    final toyota = CompanyMaster.byId('toyota')!;
    final noArtwork = CompanyMaster.byId('kyowa_kirin')!;

    await tester.pumpWidget(
      MaterialApp(
        home: CompanyArtPreviewScreen(
          availableCompanies: Future.value([toyota]),
          allCompanies: [toyota, noArtwork],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('画像あり 1社 / CompanyMaster 2社'), findsOneWidget);
    expect(find.byKey(const Key('company-art-preview-toyota')), findsOneWidget);
    expect(
      find.byKey(const Key('company-art-preview-kyowa_kirin')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('company-art-preview-toyota')),
        matching: find.byType(CompanyCardArtwork),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('show-fallback-switch')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('company-art-preview-kyowa_kirin')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('company-artwork-fallback')), findsWidgets);

    await tester.tap(find.byKey(const Key('company-art-preview-toyota')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('company-art-detail-metadata')),
      findsOneWidget,
    );
    expect(find.textContaining('companyId: toyota'), findsOneWidget);
  });

  testWidgets('Profileの開発用導線から企業アート確認へ遷移できる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            gameState: GameState.memory(),
            predictionStore: PredictionStore.memory(),
            notificationStore: NotificationStore.memory(),
          ),
        ),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const Key('company-art-preview-button')),
    );
    await tester.tap(find.byKey(const Key('company-art-preview-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('company-art-preview-title')), findsOneWidget);
    expect(find.byKey(const Key('company-art-grid')), findsOneWidget);
  });

  test('CardCatalogと既定パック抽選母集団は20社80枚のまま', () {
    expect(CardCatalog.companyCount, 20);
    expect(CardCatalog.cards, hasLength(80));
    final service = CardPackService();
    expect(service.openPack(), everyElement(isIn(CardCatalog.cards)));
  });
}
