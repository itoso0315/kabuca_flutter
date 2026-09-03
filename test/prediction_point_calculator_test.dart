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

  test('基本報酬と値動きボーナスを仕様どおり計算する', () {
    expect(reward(0.5).totalReward, 20);
    expect(reward(2).totalReward, 25);
    expect(reward(-4).totalReward, 30);
    expect(reward(7).totalReward, 40);
    expect(reward(-12).totalReward, 50);
    expect(reward(7, correct: false).totalReward, 0);
  });

  test('連続正解ボーナスは2・3・4連続で増え4以上は15 KABU', () {
    expect(reward(0.5).streakBonus, 0);
    expect(reward(0.5, previousStreak: 1).streakBonus, 5);
    expect(reward(0.5, previousStreak: 2).streakBonus, 10);
    expect(reward(0.5, previousStreak: 3).streakBonus, 15);
    expect(reward(0.5, previousStreak: 7).streakBonus, 15);
    expect(reward(0.5, previousStreak: 7).correctStreak, 8);
  });

  test('不正解は報酬0かつstreakを0へ戻す', () {
    final result = reward(-4, correct: false, previousStreak: 3);
    expect(result.baseReward, 0);
    expect(result.movementBonus, 0);
    expect(result.streakBonus, 0);
    expect(result.totalReward, 0);
    expect(result.correctStreak, 0);
  });
}
