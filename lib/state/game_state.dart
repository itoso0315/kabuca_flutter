import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/company_card.dart';
import '../models/pack_type.dart';

abstract interface class GameStorage {
  Future<int?> readStarterPackCount();
  Future<int?> readPremiumPackCount();
  Future<Map<String, int>> readCardCounts();
  Future<void> writeStarterPackCount(int value);
  Future<void> writePremiumPackCount(int value);
  Future<void> writeCardCounts(Map<String, int> value);
}

class SharedPreferencesGameStorage implements GameStorage {
  static const _legacyPackCountKey = 'game.packCount';
  static const _starterPackCountKey = 'game.starterPackCount';
  static const _premiumPackCountKey = 'game.premiumPackCount';
  static const _cardCountsKey = 'game.cardCounts';

  @override
  Future<int?> readStarterPackCount() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_starterPackCountKey) ??
        preferences.getInt(_legacyPackCountKey);
  }

  @override
  Future<int?> readPremiumPackCount() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_premiumPackCountKey);
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
  Future<void> writeStarterPackCount(int value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_starterPackCountKey, value);
  }

  @override
  Future<void> writePremiumPackCount(int value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_premiumPackCountKey, value);
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

  GameState._(
    this._storage,
    this._starterPackCount,
    this._premiumPackCount,
    Map<String, int> cardCounts,
  ) : _cardCounts = Map.of(cardCounts);

  final GameStorage _storage;
  int _starterPackCount;
  int _premiumPackCount;
  final Map<String, int> _cardCounts;

  int get starterPackCount => _starterPackCount;
  int get premiumPackCount => _premiumPackCount;
  @Deprecated('Use starterPackCount instead.')
  int get packCount => _starterPackCount;
  Map<String, int> get cardCounts => Map.unmodifiable(_cardCounts);
  int get totalOwnedCardCount =>
      _cardCounts.values.fold(0, (total, count) => total + count);
  int get registeredCardCount => _cardCounts.length;

  int ownedCount(String cardId) => _cardCounts[cardId] ?? 0;
  bool owns(String cardId) => ownedCount(cardId) > 0;

  static Future<GameState> load({GameStorage? storage}) async {
    final targetStorage = storage ?? SharedPreferencesGameStorage();
    final results = await Future.wait<Object?>([
      targetStorage.readStarterPackCount(),
      targetStorage.readPremiumPackCount(),
      targetStorage.readCardCounts(),
    ]);
    return GameState._(
      targetStorage,
      results[0] as int? ?? initialPackCount,
      results[1] as int? ?? 0,
      results[2]! as Map<String, int>,
    );
  }

  static GameState memory({
    int packCount = initialPackCount,
    int? starterPackCount,
    int premiumPackCount = 0,
    Map<String, int>? cardCounts,
  }) {
    return GameState._(
      _MemoryGameStorage(),
      starterPackCount ?? packCount,
      premiumPackCount,
      cardCounts ?? const {},
    );
  }

  Future<void> consumePack([PackType type = PackType.starter]) async {
    switch (type) {
      case PackType.starter:
        if (_starterPackCount <= 0) return;
        _starterPackCount--;
        notifyListeners();
        await _storage.writeStarterPackCount(_starterPackCount);
      case PackType.premium:
        if (_premiumPackCount <= 0) return;
        _premiumPackCount--;
        notifyListeners();
        await _storage.writePremiumPackCount(_premiumPackCount);
    }
  }

  Future<void> addPacks([int count = 1, PackType type = PackType.starter]) async {
    if (count <= 0) return;
    switch (type) {
      case PackType.starter:
        final next = _starterPackCount + count;
        await _storage.writeStarterPackCount(next);
        _starterPackCount = next;
      case PackType.premium:
        final next = _premiumPackCount + count;
        await _storage.writePremiumPackCount(next);
        _premiumPackCount = next;
    }
    notifyListeners();
  }

  Future<void> addCards(Iterable<CompanyCard> cards) async {
    for (final card in cards) {
      _cardCounts.update(card.id, (count) => count + 1, ifAbsent: () => 1);
    }
    notifyListeners();
    await _storage.writeCardCounts(_cardCounts);
  }

  Future<void> resetDevelopmentData() async {
    _starterPackCount = initialPackCount;
    _premiumPackCount = 0;
    _cardCounts.clear();
    notifyListeners();
    await Future.wait<void>([
      _storage.writeStarterPackCount(_starterPackCount),
      _storage.writePremiumPackCount(_premiumPackCount),
      _storage.writeCardCounts(_cardCounts),
    ]);
  }
}

class _MemoryGameStorage implements GameStorage {
  int? starterPackCount;
  int? premiumPackCount;
  Map<String, int> cardCounts = {};

  @override
  Future<int?> readStarterPackCount() async => starterPackCount;

  @override
  Future<int?> readPremiumPackCount() async => premiumPackCount;

  @override
  Future<Map<String, int>> readCardCounts() async => Map.of(cardCounts);

  @override
  Future<void> writeStarterPackCount(int value) async =>
      starterPackCount = value;

  @override
  Future<void> writePremiumPackCount(int value) async =>
      premiumPackCount = value;

  @override
  Future<void> writeCardCounts(Map<String, int> value) async {
    cardCounts = Map.of(value);
  }
}
