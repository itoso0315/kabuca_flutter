import 'dart:math' as math;

class PredictionPointCalculator {
  const PredictionPointCalculator._();

  static int calculate({
    required double changePercent,
    required bool isCorrect,
  }) {
    if (!isCorrect || changePercent == 0 || !changePercent.isFinite) return 0;
    return math.max(1, (changePercent.abs() * 10).ceil());
  }
}
