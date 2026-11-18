import '../models/match_outcome.dart';

/// Виртуальные баллы: только за правильный прогноз, без покупок и вывода.
class PointsRules {
  static const int correctReward = 10;

  static bool isCorrect(MatchOutcome chosen, MatchOutcome actual) {
    return chosen == actual;
  }

  /// Повторная обработка уже начисленного прогноза даёт 0.
  static int award({
    required MatchOutcome chosen,
    required MatchOutcome actual,
    required bool alreadyAwarded,
  }) {
    if (alreadyAwarded) {
      return 0;
    }
    return isCorrect(chosen, actual) ? correctReward : 0;
  }
}
