import '../models/stock_prediction.dart';
import '../state/point_wallet.dart';
import '../state/prediction_store.dart';

enum RewardClaimResult { claimed, alreadyClaimed, unavailable }

class PredictionRewardBreakdown {
  const PredictionRewardBreakdown({
    required this.baseReward,
    required this.movementBonus,
    required this.streakBonus,
    required this.totalReward,
    required this.correctStreak,
  });

  final int baseReward;
  final int movementBonus;
  final int streakBonus;
  final int totalReward;
  final int correctStreak;
}

class PredictionRewardService {
  PredictionRewardService({
    required this.predictionStore,
    required this.pointWallet,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PredictionStore predictionStore;
  final PointWallet pointWallet;
  final DateTime Function() _now;
  final Set<String> _claiming = {};

  static PredictionRewardBreakdown calculate({
    required double changePercent,
    required bool isCorrect,
    required int previousCorrectStreak,
  }) {
    if (!isCorrect || !changePercent.isFinite) {
      return const PredictionRewardBreakdown(
        baseReward: 0,
        movementBonus: 0,
        streakBonus: 0,
        totalReward: 0,
        correctStreak: 0,
      );
    }

    final movement = changePercent.abs();
    final movementBonus = switch (movement) {
      >= 10 => 30,
      >= 5 => 20,
      >= 3 => 10,
      >= 1 => 5,
      _ => 0,
    };
    final streak = previousCorrectStreak + 1;
    final streakBonus = switch (streak) {
      >= 4 => 15,
      3 => 10,
      2 => 5,
      _ => 0,
    };
    return PredictionRewardBreakdown(
      baseReward: 20,
      movementBonus: movementBonus,
      streakBonus: streakBonus,
      totalReward: 20 + movementBonus + streakBonus,
      correctStreak: streak,
    );
  }

  bool isClaimed(StockPrediction prediction) =>
      prediction.pointsClaimed == true ||
      pointWallet.hasClaimedPrediction(prediction.id);

  Future<RewardClaimResult> claim(String predictionId) async {
    if (!_claiming.add(predictionId)) return RewardClaimResult.alreadyClaimed;
    try {
      final prediction = predictionStore.findById(predictionId);
      final points = prediction?.awardedPoints ?? 0;
      if (prediction == null ||
          prediction.status != PredictionStatus.completed ||
          points <= 0) {
        return RewardClaimResult.unavailable;
      }
      if (isClaimed(prediction)) {
        if (prediction.pointsClaimed != true) {
          await predictionStore.markPointsClaimed(
            prediction.id,
            claimed: true,
            claimedAt: _now().toUtc(),
          );
        }
        return RewardClaimResult.alreadyClaimed;
      }
      final credited = await pointWallet.claimPredictionReward(
        prediction.id,
        points,
      );
      if (!credited) return RewardClaimResult.alreadyClaimed;
      try {
        final updated = await predictionStore.markPointsClaimed(
          prediction.id,
          claimed: true,
          claimedAt: _now().toUtc(),
        );
        if (updated == null) throw StateError('予想結果を更新できませんでした');
      } catch (_) {
        await pointWallet.rollbackPredictionReward(prediction.id, points);
        rethrow;
      }
      return RewardClaimResult.claimed;
    } finally {
      _claiming.remove(predictionId);
    }
  }
}
