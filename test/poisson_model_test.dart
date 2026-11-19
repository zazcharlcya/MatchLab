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

  test('поправка Dixon–Coles повышает вероятность ничьей', () {
    const independent = PoissonModel(rho: 0);
    const dixonColes = PoissonModel(rho: -0.13);
    expect(
      dixonColes.outcomes(1.3, 1.2).draw,
      greaterThan(independent.outcomes(1.3, 1.2).draw),
    );
  });
}
