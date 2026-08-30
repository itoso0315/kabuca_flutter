import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/state/game_state.dart';

void main() {
  test('所持パック・カード・重複枚数を保存し再生成後に復元する', () async {
    final storage = _FakeStorage();
    final state = await GameState.load(storage: storage);
    final card = CardCatalog.cards.first;

    expect(state.packCount, 3);
    await state.consumePack();
    await state.addCards([card, card]);

    expect(state.packCount, 2);
    expect(state.ownedCount(card.id), 2);
    expect(state.totalOwnedCardCount, 2);
    expect(state.registeredCardCount, 1);

    final restored = await GameState.load(storage: storage);
    expect(restored.packCount, 2);
    expect(restored.ownedCount(card.id), 2);
    expect(restored.totalOwnedCardCount, 2);
    expect(restored.registeredCardCount, 1);

    await restored.resetDevelopmentData();
    expect(restored.packCount, 3);
    expect(restored.totalOwnedCardCount, 0);
    expect(restored.registeredCardCount, 0);

    final resetRestored = await GameState.load(storage: storage);
    expect(resetRestored.packCount, 3);
    expect(resetRestored.totalOwnedCardCount, 0);
    expect(resetRestored.registeredCardCount, 0);
  });
}

class _FakeStorage implements GameStorage {
  int? packCount;
  Map<String, int> cardCounts = {};

  @override
  Future<int?> readPackCount() async => packCount;

  @override
  Future<Map<String, int>> readCardCounts() async => Map.of(cardCounts);

  @override
  Future<void> writePackCount(int value) async => packCount = value;

  @override
  Future<void> writeCardCounts(Map<String, int> value) async {
    cardCounts = Map.of(value);
  }
}
