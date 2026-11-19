import 'dart:math' as math;

import '../models/match_outcome.dart';
import '../models/scoreline.dart';

class OutcomeProbabilities {
  const OutcomeProbabilities({
    required this.homeWin,
    required this.draw,
    required this.awayWin,
  });

  final double homeWin;
  final double draw;
  final double awayWin;

  double get sum => homeWin + draw + awayWin;

  OutcomeProbabilities normalized() {
    final total = sum;
    if (total <= 0) {
      return const OutcomeProbabilities(homeWin: 1 / 3, draw: 1 / 3, awayWin: 1 / 3);
    }
    return OutcomeProbabilities(
      homeWin: homeWin / total,
      draw: draw / total,
      awayWin: awayWin / total,
    );
  }
}

/// Распределение Пуассона для голов + поправка Dixon–Coles на низкие счета.
///
/// Независимый Пуассон:
///   P(k | λ) = e^{-λ} * λ^k / k!
///   P(i, j)  = P(i | λ_home) * P(j | λ_away)
///
/// Независимая модель систематически занижает ничьи. Dixon–Coles (1997)
/// домножает клетки 0:0, 1:0, 0:1, 1:1 на τ:
///   τ(0,0) = 1 − λμρ
///   τ(0,1) = 1 + λρ
///   τ(1,0) = 1 + μρ
///   τ(1,1) = 1 − ρ
///   иначе  1
///
/// ρ < 0 (обычно около −0.10) поднимает 0:0 и 1:1.
class PoissonModel {
  const PoissonModel({this.maxGoals = 8, this.rho = -0.10});

  final int maxGoals;
  final double rho;

  double pmf(int k, double lambda) {
    if (k < 0) {
      return 0;
    }
    if (lambda <= 0) {
      return k == 0 ? 1 : 0;
    }
    return math.exp(-lambda) * math.pow(lambda, k) / _factorial(k);
  }

  double tau(int homeGoals, int awayGoals, double lambdaHome, double lambdaAway) {
    if (rho == 0) {
      return 1;
    }
    if (homeGoals == 0 && awayGoals == 0) {
      return math.max(0.05, 1 - lambdaHome * lambdaAway * rho);
    }
    if (homeGoals == 0 && awayGoals == 1) {
      return math.max(0.05, 1 + lambdaHome * rho);
    }
    if (homeGoals == 1 && awayGoals == 0) {
      return math.max(0.05, 1 + lambdaAway * rho);
    }
    if (homeGoals == 1 && awayGoals == 1) {
      return math.max(0.05, 1 - rho);
    }
    return 1;
  }

  List<List<double>> scoreMatrix(double lambdaHome, double lambdaAway) {
    final home = List<double>.generate(maxGoals + 1, (k) => pmf(k, lambdaHome));
    final away = List<double>.generate(maxGoals + 1, (k) => pmf(k, lambdaAway));
    var total = 0.0;
    final raw = List.generate(maxGoals + 1, (i) {
      return List.generate(maxGoals + 1, (j) {
        final p = home[i] * away[j] * tau(i, j, lambdaHome, lambdaAway);
        total += p;
        return p;
      });
    });
    if (total <= 0) {
      return raw;
    }
    return [
      for (final row in raw) [for (final p in row) p / total],
    ];
  }

  OutcomeProbabilities outcomes(double lambdaHome, double lambdaAway) {
    final matrix = scoreMatrix(lambdaHome, lambdaAway);
    var homeWin = 0.0;
    var draw = 0.0;
    var awayWin = 0.0;
    for (var i = 0; i <= maxGoals; i++) {
      for (var j = 0; j <= maxGoals; j++) {
        final p = matrix[i][j];
        if (i > j) {
          homeWin += p;
        } else if (i == j) {
          draw += p;
        } else {
          awayWin += p;
        }
      }
    }
    return OutcomeProbabilities(
      homeWin: homeWin,
      draw: draw,
      awayWin: awayWin,
    ).normalized();
  }

  List<Scoreline> topScores(double lambdaHome, double lambdaAway, {int count = 5}) {
    final matrix = scoreMatrix(lambdaHome, lambdaAway);
    final lines = <Scoreline>[];
    for (var i = 0; i <= maxGoals; i++) {
      for (var j = 0; j <= maxGoals; j++) {
        lines.add(Scoreline(homeGoals: i, awayGoals: j, probability: matrix[i][j]));
      }
    }
    lines.sort((a, b) => b.probability.compareTo(a.probability));
    return lines.take(count).toList();
  }

  MatchOutcome mostLikely(OutcomeProbabilities probabilities) {
    if (probabilities.homeWin >= probabilities.draw &&
        probabilities.homeWin >= probabilities.awayWin) {
      return MatchOutcome.homeWin;
    }
    if (probabilities.awayWin >= probabilities.draw) {
      return MatchOutcome.awayWin;
    }
    return MatchOutcome.draw;
  }

  int _factorial(int n) {
    var result = 1;
    for (var i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }
}
