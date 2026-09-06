import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/company_card.dart';
import '../models/pack_type.dart';

abstract interface class GameStorage {
  Future<int?> readStarterPackCount();
  Future<int?> readPremiumPackCount();
  Future<Map<String, int>> readCardCounts();
  Future<String?> readLastFreeStarterPackDate();
  Future<void> writeStarterPackCount(int value);
  Future<void> writePremiumPackCount(int value);
  Future<void> writeCardCounts(Map<String, int> value);
  Future<void> writeLastFreeStarterPackDate(String? value);
}

class SharedPreferencesGameStorage implements GameStorage {
  static const _legacyPackCountKey = 'game.packCount';
  static const _starterPackCountKey = 'game.starterPackCount';
  static const _premiumPackCountKey = 'game.premiumPackCount';
  static const _cardCountsKey = 'game.cardCounts';
  static const _lastFreeStarterPackDateKey = 'game.lastFreeStarterPackDate';

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
  Future<String?> readLastFreeStarterPackDate() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastFreeStarterPackDateKey);
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

  @override
  Future<void> writeLastFreeStarterPackDate(String? value) async {
    final preferences = await SharedPreferences.getInstance();
    if (value == null) {
      await preferences.remove(_lastFreeStarterPackDateKey);
      return;
    }
    await preferences.setString(_lastFreeStarterPackDateKey, value);
  }
}

class GameState extends ChangeNotifier {
  static const initialPackCount = 3;

  GameState._(
    this._storage,
    this._starterPackCount,
    this._premiumPackCount,
    this._lastFreeStarterPackDate,
    Map<String, int> cardCounts,
  ) : _cardCounts = Map.of(cardCounts);

  final GameStorage _storage;
  int _starterPackCount;
  int _premiumPackCount;
  String? _lastFreeStarterPackDate;
  final Map<String, int> _cardCounts;

  int get starterPackCount => _starterPackCount;
  int get premiumPackCount => _premiumPackCount;
  bool get hasFreeStarterPackToday =>
      _lastFreeStarterPackDate != _dateKey(DateTime.now());
  String? get lastFreeStarterPackDate => _lastFreeStarterPackDate;
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
      targetStorage.readLastFreeStarterPackDate(),
    ]);
    return GameState._(
      targetStorage,
      results[0] as int? ?? initialPackCount,
      results[1] as int? ?? 0,
      results[3] as String?,
      results[2]! as Map<String, int>,
    );
  }

  static GameState memory({
    int packCount = initialPackCount,
    int? starterPackCount,
    int premiumPackCount = 0,
    Map<String, int>? cardCounts,
    String? lastFreeStarterPackDate,
  }) {
    return GameState._(
      _MemoryGameStorage(),
      starterPackCount ?? packCount,
      premiumPackCount,
      lastFreeStarterPackDate,
      cardCounts ?? const {},
    );
  }

  Future<bool> consumeDailyFreeStarterPack({DateTime? now}) async {
    final today = _dateKey(now ?? DateTime.now());
    if (_lastFreeStarterPackDate == today) return false;

    await _storage.writeLastFreeStarterPackDate(today);
    _lastFreeStarterPackDate = today;
    notifyListeners();
    return true;
  }

  static String _dateKey(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
    _lastFreeStarterPackDate = null;
    _cardCounts.clear();
    notifyListeners();
    await Future.wait<void>([
      _storage.writeStarterPackCount(_starterPackCount),
      _storage.writePremiumPackCount(_premiumPackCount),
      _storage.writeCardCounts(_cardCounts),
      _storage.writeLastFreeStarterPackDate(null),
    ]);
  }
}

class _MemoryGameStorage implements GameStorage {
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
  Future<String?> readLastFreeStarterPackDate() async => lastFreeStarterPackDate;

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

  @override
  Future<void> writeLastFreeStarterPackDate(String? value) async =>
      lastFreeStarterPackDate = value;
}
