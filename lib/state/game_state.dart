import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/company_card.dart';

abstract interface class GameStorage {
  Future<int?> readPackCount();
  Future<Map<String, int>> readCardCounts();
  Future<void> writePackCount(int value);
  Future<void> writeCardCounts(Map<String, int> value);
}

class SharedPreferencesGameStorage implements GameStorage {
  static const _packCountKey = 'game.packCount';
  static const _cardCountsKey = 'game.cardCounts';

  @override
  Future<int?> readPackCount() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_packCountKey);
  }

  @override
  Future<Map<String, int>> readCardCounts() async {
    final preferences = await SharedPreferences.getInstance();
    final entries = preferences.getStringList(_cardCountsKey) ?? const [];
    return {
      for (final entry in entries)
        if (entry.split('|') case [final id, final count])
          id: int.tryParse(count) ?? 0,
    }..removeWhere((_, count) => count <= 0);
  }

  @override
  Future<void> writePackCount(int value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_packCountKey, value);
  }

  @override
  Future<void> writeCardCounts(Map<String, int> value) async {
    final preferences = await SharedPreferences.getInstance();
    final entries = value.entries.map((entry) => '${entry.key}|${entry.value}');
    await preferences.setStringList(_cardCountsKey, entries.toList());
  }
}

class GameState extends ChangeNotifier {
  static const initialPackCount = 3;

  GameState._(this._storage, this._packCount, Map<String, int> cardCounts)
    : _cardCounts = Map.of(cardCounts);

  final GameStorage _storage;
  int _packCount;
  final Map<String, int> _cardCounts;

  int get packCount => _packCount;
  Map<String, int> get cardCounts => Map.unmodifiable(_cardCounts);
  int get totalOwnedCardCount =>
      _cardCounts.values.fold(0, (total, count) => total + count);
  int get registeredCardCount => _cardCounts.length;

  int ownedCount(String cardId) => _cardCounts[cardId] ?? 0;
  bool owns(String cardId) => ownedCount(cardId) > 0;

  static Future<GameState> load({GameStorage? storage}) async {
    final targetStorage = storage ?? SharedPreferencesGameStorage();
    final results = await Future.wait<Object?>([
      targetStorage.readPackCount(),
      targetStorage.readCardCounts(),
    ]);
    return GameState._(
      targetStorage,
      results[0] as int? ?? initialPackCount,
      results[1]! as Map<String, int>,
    );
  }

  static GameState memory({
    int packCount = initialPackCount,
    Map<String, int>? cardCounts,
  }) {
    return GameState._(_MemoryGameStorage(), packCount, cardCounts ?? const {});
  }

  Future<void> consumePack() async {
    if (_packCount <= 0) return;
    _packCount--;
    notifyListeners();
    await _storage.writePackCount(_packCount);
  }

  Future<void> addCards(Iterable<CompanyCard> cards) async {
    for (final card in cards) {
      _cardCounts.update(card.id, (count) => count + 1, ifAbsent: () => 1);
    }
    notifyListeners();
    await _storage.writeCardCounts(_cardCounts);
  }

  Future<void> resetDevelopmentData() async {
    _packCount = initialPackCount;
    _cardCounts.clear();
    notifyListeners();
    await Future.wait<void>([
      _storage.writePackCount(_packCount),
      _storage.writeCardCounts(_cardCounts),
    ]);
  }
}

class _MemoryGameStorage implements GameStorage {
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
