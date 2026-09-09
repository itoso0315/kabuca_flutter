import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/app/app_theme.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/models/pack_type.dart';
import 'package:kabuca_flutter/screens/home/home_screen.dart';
import 'package:kabuca_flutter/screens/pack/pack_opening_screen.dart';
import 'package:kabuca_flutter/services/card_pack_service.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';
import 'package:kabuca_flutter/widgets/company_card_artwork.dart';
import 'package:kabuca_flutter/widgets/new_company_reveal.dart';

CompanyCard _card(CardRarity rarity, [String companyId = 'toyota']) =>
    CardCatalog.cards.firstWhere(
      (card) => card.companyId == companyId && card.rarity == rarity,
    );

const _viewCardKey = Key('new-company-view-card');
const _confirmationKey = Key('card-confirmation-gesture');

Future<void> _advance(WidgetTester tester, [int milliseconds = 4000]) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tearPack(WidgetTester tester) async {
  final topLeft = tester.getTopLeft(find.byKey(const Key('tearable-pack')));
  await tester.dragFrom(topLeft + const Offset(20, 40), const Offset(400, 0));
}

Future<void> _open(
  WidgetTester tester,
  List<CompanyCard> cards, {
  GameState? gameState,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: PackOpeningScreen(
        cards: cards,
        gameState: gameState ?? GameState.memory(),
        onPackOpened: () {},
      ),
    ),
  );
  await _tearPack(tester);
  await _advance(tester);
}

Future<void> _viewCard(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_viewCardKey));
  await tester.tap(find.byKey(_viewCardKey));
  await _advance(tester);
}

void main() {
  testWidgets('未所有企業だけ専用演出を挟み、必要な情報とNの概要を表示する', (tester) async {
    await _open(tester, [_card(CardRarity.ur)]);

    expect(find.byType(NewCompanyReveal), findsOneWidget);
    expect(find.text('NEW COMPANY'), findsOneWidget);
    expect(find.byKey(const Key('new-company-name')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('new-company-name'))).data,
      'トヨタ自動車',
    );
    expect(find.text('図鑑に新しい企業が登録されました'), findsOneWidget);
    expect(find.text('1 / 4 CARDS'), findsOneWidget);
    expect(find.byType(CompanyCardArtwork), findsOneWidget);
    expect(find.byKey(_confirmationKey), findsNothing);
    final intro = tester.widget<Text>(
      find.byKey(const Key('new-company-introduction')),
    );
    expect(intro.data, _card(CardRarity.n).description);
    expect(intro.data, isNot(_card(CardRarity.ur).description));
    expect(intro.maxLines, 2);

    await _viewCard(tester);
    expect(find.byType(NewCompanyReveal), findsNothing);
    expect(find.text('CARD 1 / 1'), findsOneWidget);
    expect(find.byKey(_confirmationKey), findsOneWidget);
    await tester.tap(find.byKey(_confirmationKey));
    await tester.pumpAndSettle();
    expect(find.text('1枚獲得！'), findsOneWidget);
  });

  for (final ownedRarity in CardRarity.values) {
    testWidgets('${ownedRarity.label}を所有する企業は別レアリティ初取得でも通常確認へ進む', (
      tester,
    ) async {
      final drawnRarity = ownedRarity == CardRarity.n
          ? CardRarity.r
          : CardRarity.n;
      await _open(tester, [
        _card(drawnRarity),
      ], gameState: GameState.memory(cardCounts: {_card(ownedRarity).id: 1}));
      expect(find.byType(NewCompanyReveal), findsNothing);
      expect(find.text('NEW COMPANY'), findsNothing);
      expect(find.byKey(_confirmationKey), findsOneWidget);
    });
  }

  for (final rarity in [CardRarity.sr, CardRarity.ur]) {
    testWidgets('発見済み企業の${rarity.label}も既存演出で確認できる', (tester) async {
      await _open(tester, [
        _card(rarity),
      ], gameState: GameState.memory(cardCounts: {_card(CardRarity.n).id: 1}));
      expect(find.byType(NewCompanyReveal), findsNothing);
      expect(find.byKey(_confirmationKey), findsOneWidget);
      expect(
        tester
            .widget<CompanyCardArtwork>(find.byType(CompanyCardArtwork))
            .card
            .rarity,
        rarity,
      );
      await tester.tap(find.byKey(_confirmationKey));
      await tester.pumpAndSettle();
      expect(find.text('1枚獲得！'), findsOneWidget);
    });
  }

  testWidgets('同パックの同企業は最初だけ演出し、種類数は詳細画面のpending所有と一致する', (tester) async {
    final gameState = GameState.memory();
    await _open(tester, [
      _card(CardRarity.n),
      _card(CardRarity.r),
      _card(CardRarity.n, 'ntt'),
    ], gameState: gameState);
    expect(find.text('2 / 4 CARDS'), findsOneWidget);
    expect(gameState.totalOwnedCardCount, 0);
    await _viewCard(tester);

    await tester.longPress(find.byKey(_confirmationKey));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('detail-owned-count')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('所持 ×1'), findsOneWidget);
    expect(find.text('取得済み'), findsNWidgets(2));
    for (final rarity in [CardRarity.n, CardRarity.r]) {
      expect(
        find.descendant(
          of: find.byKey(Key('company-rarity-status-${rarity.name}')),
          matching: find.text('取得済み'),
        ),
        findsOneWidget,
      );
    }
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NewCompanyReveal), findsNothing);

    await tester.tap(find.byKey(_confirmationKey));
    await _advance(tester);
    expect(find.byType(NewCompanyReveal), findsNothing);
    expect(find.text('CARD 2 / 3'), findsOneWidget);
    expect(gameState.totalOwnedCardCount, 0);

    await tester.tap(find.byKey(_confirmationKey));
    await _advance(tester);
    expect(find.byType(NewCompanyReveal), findsOneWidget);
    expect(
      tester
          .widget<NewCompanyReveal>(find.byType(NewCompanyReveal))
          .card
          .companyId,
      'ntt',
    );
    expect(find.text('1 / 4 CARDS'), findsOneWidget);
  });

  testWidgets('同レアリティ重複は1種類として数え、ボタン連打でもカードを飛ばさない', (tester) async {
    await _open(tester, [_card(CardRarity.n), _card(CardRarity.n)]);
    expect(find.text('1 / 4 CARDS'), findsOneWidget);
    final button = find.byKey(_viewCardKey);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.tap(button);
    await _advance(tester);
    expect(find.text('CARD 1 / 2'), findsOneWidget);
    await tester.tap(find.byKey(_confirmationKey));
    await _advance(tester);
    expect(find.byType(NewCompanyReveal), findsNothing);
    expect(find.text('CARD 2 / 2'), findsOneWidget);
  });

  for (final exitEarly in [true, false]) {
    testWidgets(
      '${exitEarly ? '演出途中でホームに戻っても未確認カードを' : '全カード確認後に'}一度だけ保存しパックも一度だけ消費する',
      (tester) async {
        final gameState = GameState.memory();
        final cards = [
          _card(CardRarity.n),
          _card(CardRarity.r),
          _card(CardRarity.r),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeScreen(
                gameState: gameState,
                predictionStore: PredictionStore.memory(),
                notificationStore: NotificationStore.memory(),
                cardPackService: _FixedPackService(cards),
              ),
            ),
          ),
        );
        final openButton = find.widgetWithText(FilledButton, 'パックを開ける');
        await tester.ensureVisible(openButton);
        await tester.tap(openButton);
        await tester.pumpAndSettle();
        await _tearPack(tester);
        if (exitEarly) {
          // Stop as soon as the interlude mounts, before its animation completes.
          for (
            var i = 0;
            i < 20 && find.byType(NewCompanyReveal).evaluate().isEmpty;
            i++
          ) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(find.byType(NewCompanyReveal), findsOneWidget);
          expect(
            tester.widget<OutlinedButton>(find.byKey(_viewCardKey)).onPressed,
            isNull,
          );
          await tester.binding.handlePopRoute();
          await tester.pump();
          expect(find.text('未確認のカードも取得済みとしてホームへ戻ります。'), findsOneWidget);
          await tester.tap(find.text('開封を続ける'));
          await tester.pumpAndSettle();
          expect(find.byType(NewCompanyReveal), findsOneWidget);
          expect(gameState.totalOwnedCardCount, 0);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await tester.tap(find.text('ホームへ戻る'));
        } else {
          await _advance(tester);
          expect(gameState.starterPackCount, 2);
          expect(gameState.totalOwnedCardCount, 0);
          await _viewCard(tester);
          for (var i = 0; i < cards.length; i++) {
            await tester.tap(find.byKey(_confirmationKey));
            await _advance(tester);
          }
          await tester.tap(find.byKey(const Key('pack-complete-home-button')));
        }
        await tester.pumpAndSettle();
        expect(find.byType(PackOpeningScreen), findsNothing);
        expect(gameState.starterPackCount, 2);
        expect(gameState.cardCounts, {
          _card(CardRarity.n).id: 1,
          _card(CardRarity.r).id: 2,
        });
      },
    );
  }

  testWidgets('演出は1.6秒で操作可能になり、ピーク時のハプティクスは1回だけ', (tester) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    var viewCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewCompanyReveal(
            card: _card(CardRarity.n),
            ownedRarityCount: 1,
            onViewCard: () => viewCount++,
          ),
        ),
      ),
    );
    expect(
      tester.widget<OutlinedButton>(find.byKey(_viewCardKey)).onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(haptics, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(
      tester.widget<OutlinedButton>(find.byKey(_viewCardKey)).onPressed,
      isNull,
    );
    // Include the first display frame after the 1.6-second boundary.
    await tester.pump(const Duration(milliseconds: 116));
    expect(
      tester.widget<OutlinedButton>(find.byKey(_viewCardKey)).onPressed,
      isNotNull,
    );
    await tester.ensureVisible(find.byKey(_viewCardKey));
    await tester.tap(find.byKey(_viewCardKey));
    await tester.tap(find.byKey(_viewCardKey));
    await tester.pumpAndSettle();
    expect(viewCount, 1);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(390, 844),
  ]) {
    testWidgets('iPhone ${size.width.toInt()}幅でもカードと操作ボタンが表示領域に収まる', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = FakeViewPadding(
        top: size.height > 800 ? 59 : 20,
        bottom: size.height > 800 ? 34 : 0,
      );
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewCompanyReveal(
              card: _card(CardRarity.n),
              ownedRarityCount: 1,
              onViewCard: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(_viewCardKey).hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.byKey(_viewCardKey)).bottom,
        lessThanOrEqualTo(size.height - tester.view.padding.bottom),
      );
      final artwork = tester.getRect(find.byType(CompanyCardArtwork));
      expect(artwork.left, greaterThanOrEqualTo(0));
      expect(artwork.right, lessThanOrEqualTo(size.width));
    });
  }

  testWidgets('動きを減らす設定では待ち時間を省き、拡大文字でもスクロールして操作できる', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            disableAnimations: true,
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: NewCompanyReveal(
              card: _card(CardRarity.n, 'mufg'),
              ownedRarityCount: 1,
              onViewCard: () {},
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<OutlinedButton>(find.byKey(_viewCardKey)).onPressed,
      isNotNull,
    );
    await tester.ensureVisible(find.byKey(_viewCardKey));
    await tester.pumpAndSettle();
    expect(find.byKey(_viewCardKey).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FixedPackService extends CardPackService {
  _FixedPackService(this.cards);
  final List<CompanyCard> cards;

  @override
  List<CompanyCard> openPack({
    int cardCount = 3,
    PackType type = PackType.starter,
  }) => cards;
}
