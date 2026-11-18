import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/models/match_outcome.dart';
import 'package:matchlab/prediction_engine/points_rules.dart';

void main() {
  test('правильный прогноз даёт +10, повторно не начисляет', () {
    expect(
      PointsRules.award(
        chosen: MatchOutcome.homeWin,
        actual: MatchOutcome.homeWin,
        alreadyAwarded: false,
      ),
      10,
    );
    expect(
      PointsRules.award(
        chosen: MatchOutcome.homeWin,
        actual: MatchOutcome.homeWin,
        alreadyAwarded: true,
      ),
      0,
    );
  });

  test('неправильный прогноз даёт 0 баллов', () {
    expect(
      PointsRules.award(
        chosen: MatchOutcome.draw,
        actual: MatchOutcome.awayWin,
        alreadyAwarded: false,
      ),
      0,
    );
  });
}
