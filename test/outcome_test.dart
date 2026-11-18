import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/models/match_outcome.dart';
import 'package:matchlab/prediction_engine/points_rules.dart';

void main() {
  test('счёт определяет исход матча', () {
    expect(MatchOutcomeLabel.fromScore(2, 1), MatchOutcome.homeWin);
    expect(MatchOutcomeLabel.fromScore(1, 1), MatchOutcome.draw);
    expect(MatchOutcomeLabel.fromScore(0, 3), MatchOutcome.awayWin);
  });

  test('прогноз считается верным только при совпадении исхода', () {
    expect(
      PointsRules.isCorrect(MatchOutcome.draw, MatchOutcome.draw),
      isTrue,
    );
    expect(
      PointsRules.isCorrect(MatchOutcome.homeWin, MatchOutcome.awayWin),
      isFalse,
    );
  });
}
