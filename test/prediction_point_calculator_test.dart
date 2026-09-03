import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/services/prediction_reward_service.dart';

void main() {
  PredictionRewardBreakdown reward(
    double change, {
    bool correct = true,
    int previousStreak = 0,
  }) => PredictionRewardService.calculate(
    changePercent: change,
    isCorrect: correct,
    previousCorrectStreak: previousStreak,
  );

  test('基本報酬と値動きボーナスの境界値を仕様どおり計算する', () {
    const cases = <({double change, int expected})>[
      (change: 0.5, expected: 20),
      (change: 1.0, expected: 25),
      (change: 2.9, expected: 25),
      (change: 3.0, expected: 30),
      (change: 4.9, expected: 30),
      (change: 5.0, expected: 40),
      (change: 9.9, expected: 40),
      (change: 10.0, expected: 50),
      (change: -2.0, expected: 25),
      (change: -6.0, expected: 40),
      (change: -12.0, expected: 50),
    ];

    for (final (:change, :expected) in cases) {
      expect(
        reward(change).totalReward,
        expected,
        reason: 'changePercent=$change',
      );
    }
    expect(reward(7, correct: false).totalReward, 0);
  });

  test('1・2・3・4・10連続正解のstreakとボーナスが正しい', () {
    const expectedBonuses = <int, int>{1: 0, 2: 5, 3: 10, 4: 15, 10: 15};

    for (final MapEntry(key: streak, value: bonus) in expectedBonuses.entries) {
      final result = reward(0.5, previousStreak: streak - 1);
      expect(result.correctStreak, streak);
      expect(result.streakBonus, bonus, reason: 'streak=$streak');
    }
  });

  test('不正解は報酬0かつstreakを0へ戻す', () {
    final result = reward(-4, correct: false, previousStreak: 3);
    expect(result.baseReward, 0);
    expect(result.movementBonus, 0);
    expect(result.streakBonus, 0);
    expect(result.totalReward, 0);
    expect(result.correctStreak, 0);

    final next = reward(0.5, previousStreak: result.correctStreak);
    expect(next.correctStreak, 1);
    expect(next.streakBonus, 0);
  });
}
