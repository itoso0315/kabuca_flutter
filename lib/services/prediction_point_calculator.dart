import 'prediction_reward_service.dart';

class PredictionPointCalculator {
  const PredictionPointCalculator._();

  static int calculate({
    required double changePercent,
    required bool isCorrect,
    int previousCorrectStreak = 0,
  }) {
    return PredictionRewardService.calculate(
      changePercent: changePercent,
      isCorrect: isCorrect,
      previousCorrectStreak: previousCorrectStreak,
    ).totalReward;
  }
}
