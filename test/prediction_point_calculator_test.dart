import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/services/prediction_point_calculator.dart';

void main() {
  test('的中時は絶対騰落率×10を切り上げ、外れと同値は0pt', () {
    int points(double change, {bool correct = true}) =>
        PredictionPointCalculator.calculate(
          changePercent: change,
          isCorrect: correct,
        );

    expect(points(0), 0);
    expect(points(0.01), 1);
    expect(points(0.1), 1);
    expect(points(0.8), 8);
    expect(points(1), 10);
    expect(points(1.23), 13);
    expect(points(3.41), 35);
    expect(points(-3.41), 35);
    expect(points(3.41, correct: false), 0);
  });
}
