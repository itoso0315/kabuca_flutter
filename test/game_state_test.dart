import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/pack_type.dart';
import 'package:kabuca_flutter/state/game_state.dart';

void main() {
  test('所持パック・カード・重複枚数を保存し再生成後に復元する', () async {
    final storage = _FakeStorage();
    final state = await GameState.load(storage: storage);
    final card = CardCatalog.cards.first;

    expect(state.starterPackCount, 3);
    expect(state.premiumPackCount, 0);

    await state.consumePack();
    await state.addPacks(1, PackType.premium);
    await state.addCards([card, card]);

    expect(state.starterPackCount, 2);
    expect(state.premiumPackCount, 1);
    expect(state.ownedCount(card.id), 2);
    expect(state.totalOwnedCardCount, 2);
    expect(state.registeredCardCount, 1);

    final restored = await GameState.load(storage: storage);
    expect(restored.starterPackCount, 2);
    expect(restored.premiumPackCount, 1);
    expect(restored.ownedCount(card.id), 2);
    expect(restored.totalOwnedCardCount, 2);
    expect(restored.registeredCardCount, 1);

    await restored.resetDevelopmentData();
    expect(restored.starterPackCount, 3);
    expect(restored.premiumPackCount, 0);
    expect(restored.totalOwnedCardCount, 0);
    expect(restored.registeredCardCount, 0);

    final resetRestored = await GameState.load(storage: storage);
    expect(resetRestored.starterPackCount, 3);
    expect(resetRestored.premiumPackCount, 0);
    expect(resetRestored.totalOwnedCardCount, 0);
    expect(resetRestored.registeredCardCount, 0);
  });

  test('同じ日は無料スタートパックを2回受け取れない', () async {
    final storage = _FakeStorage();
    final state = await GameState.load(storage: storage);
    final now = DateTime(2026, 9, 6, 10, 0);

    expect(state.starterPackCount, 3);

    final firstClaim = await state.consumeDailyFreeStarterPack(now: now);
    final secondClaim = await state.consumeDailyFreeStarterPack(
      now: DateTime(2026, 9, 6, 23, 59),
    );

    expect(firstClaim, isTrue);
    expect(secondClaim, isFalse);
    expect(state.starterPackCount, 3);
    expect(storage.lastFreeStarterPackDate, '2026-09-06');
  });

  test('翌日になれば無料スタートパックを再び受け取れる', () async {
    final storage = _FakeStorage();
    final state = await GameState.load(storage: storage);

    final firstClaim = await state.consumeDailyFreeStarterPack(
      now: DateTime(2026, 9, 6, 23, 59),
    );
    final nextDayClaim = await state.consumeDailyFreeStarterPack(
      now: DateTime(2026, 9, 7, 0, 1),
    );

    expect(firstClaim, isTrue);
    expect(nextDayClaim, isTrue);
    expect(state.starterPackCount, 3);
    expect(storage.lastFreeStarterPackDate, '2026-09-07');
  });
}

class _FakeStorage implements GameStorage {
  int? starterPackCount;
  int? premiumPackCount;
  String? lastFreeStarterPackDate;
  Map<String, int> cardCounts = {};

  @override
  Future<int?> readStarterPackCount() async => starterPackCount;

  @override
  Future<int?> readPremiumPackCount() async => premiumPackCount;

  @override
  Future<Map<String, int>> readCardCounts() async => Map.of(cardCounts);

  @override
  Future<String?> readLastFreeStarterPackDate() async =>
      lastFreeStarterPackDate;

  @override
  Future<void> writeStarterPackCount(int value) async =>
      starterPackCount = value;

  @override
  Future<void> writePremiumPackCount(int value) async =>
      premiumPackCount = value;

  @override
  Future<void> writeLastFreeStarterPackDate(String? value) async =>
      lastFreeStarterPackDate = value;

  @override
  Future<void> writeCardCounts(Map<String, int> value) async {
    cardCounts = Map.of(value);
  }
}
