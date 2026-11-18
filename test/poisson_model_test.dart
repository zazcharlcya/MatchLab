import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/prediction_engine/poisson_model.dart';

void main() {
  const model = PoissonModel();

  test('P(0 | λ=1) равно e^{-1}', () {
    expect(model.pmf(0, 1), closeTo(math.exp(-1), 0.000001));
  });

  test('вероятности исходов в сумме дают 1', () {
    final outcomes = model.outcomes(1.4, 1.1);
    expect(
      outcomes.homeWin + outcomes.draw + outcomes.awayWin,
      closeTo(1, 0.0001),
    );
  });
}
