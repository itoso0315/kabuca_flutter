import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PointWalletSnapshot {
  const PointWalletSnapshot({
    required this.balance,
    required this.claimedPredictionIds,
  });

  final int balance;
  final Set<String> claimedPredictionIds;

  Map<String, Object> toJson() => {
    'balance': balance,
    'claimedPredictionIds': claimedPredictionIds.toList(),
  };

  factory PointWalletSnapshot.fromJson(Map<String, Object?> json) =>
      PointWalletSnapshot(
        balance: (json['balance'] as num?)?.toInt() ?? 0,
        claimedPredictionIds:
            (json['claimedPredictionIds'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toSet(),
      );
}

abstract interface class PointWalletStorage {
  Future<PointWalletSnapshot> read();
  Future<void> write(PointWalletSnapshot snapshot);
}

class SharedPreferencesPointWalletStorage implements PointWalletStorage {
  static const key = 'points.wallet';

  @override
  Future<PointWalletSnapshot> read() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(key);
    if (value == null) {
      return const PointWalletSnapshot(balance: 0, claimedPredictionIds: {});
    }
    return PointWalletSnapshot.fromJson(
      jsonDecode(value) as Map<String, Object?>,
    );
  }

  @override
  Future<void> write(PointWalletSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(snapshot.toJson()));
  }
}

class PointWallet extends ChangeNotifier {
  PointWallet._(this._storage, PointWalletSnapshot snapshot)
    : _currentPoints = snapshot.balance,
      _claimedPredictionIds = Set.of(snapshot.claimedPredictionIds);

  final PointWalletStorage _storage;
  int _currentPoints;
  final Set<String> _claimedPredictionIds;

  int get currentPoints => _currentPoints;
  bool hasClaimedPrediction(String predictionId) =>
      _claimedPredictionIds.contains(predictionId);

  static Future<PointWallet> load({PointWalletStorage? storage}) async {
    final target = storage ?? SharedPreferencesPointWalletStorage();
    return PointWallet._(target, await target.read());
  }

  static PointWallet memory({
    int currentPoints = 0,
    Iterable<String> claimedPredictionIds = const [],
  }) => PointWallet._(
    _MemoryPointWalletStorage(),
    PointWalletSnapshot(
      balance: currentPoints,
      claimedPredictionIds: claimedPredictionIds.toSet(),
    ),
  );

  Future<bool> claimPredictionReward(String predictionId, int points) async {
    if (points <= 0 || hasClaimedPrediction(predictionId)) return false;
    final claimed = Set<String>.of(_claimedPredictionIds)..add(predictionId);
    await _commit(_currentPoints + points, claimed);
    return true;
  }

  Future<void> rollbackPredictionReward(String predictionId, int points) async {
    if (!hasClaimedPrediction(predictionId)) return;
    final claimed = Set<String>.of(_claimedPredictionIds)..remove(predictionId);
    await _commit((_currentPoints - points).clamp(0, 1 << 62), claimed);
  }

  Future<bool> spend(int points) async {
    if (points <= 0 || _currentPoints < points) return false;
    await _commit(_currentPoints - points, _claimedPredictionIds);
    return true;
  }

  Future<void> refund(int points) async {
    if (points <= 0) return;
    await _commit(_currentPoints + points, _claimedPredictionIds);
  }

  Future<void> resetDevelopmentData() => _commit(0, const {});

  Future<void> _commit(int balance, Set<String> claimedIds) async {
    final snapshot = PointWalletSnapshot(
      balance: balance,
      claimedPredictionIds: Set.of(claimedIds),
    );
    await _storage.write(snapshot);
    _currentPoints = balance;
    _claimedPredictionIds
      ..clear()
      ..addAll(claimedIds);
    notifyListeners();
  }
}

class _MemoryPointWalletStorage implements PointWalletStorage {
  PointWalletSnapshot snapshot = const PointWalletSnapshot(
    balance: 0,
    claimedPredictionIds: {},
  );

  @override
  Future<PointWalletSnapshot> read() async => snapshot;

  @override
  Future<void> write(PointWalletSnapshot value) async {
    snapshot = PointWalletSnapshot(
      balance: value.balance,
      claimedPredictionIds: Set.of(value.claimedPredictionIds),
    );
  }
}
