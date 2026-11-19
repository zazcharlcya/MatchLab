import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/models/football_match.dart';
import 'package:matchlab/models/match_outcome.dart';
import 'package:matchlab/models/user_prediction.dart';
import 'package:matchlab/prediction_engine/points_rules.dart';

import 'helpers.dart';

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

  test('прогноз нельзя сохранить после начала матча', () {
    final upcoming = sampleMatch(kickoff: DateTime.now().add(const Duration(hours: 2)));
    final started = sampleMatch(kickoff: DateTime.now().subtract(const Duration(minutes: 1)));
    expect(upcoming.canPredict, isTrue);
    expect(started.canPredict, isFalse);
  });

  test('прогноз можно менять только до матча и с привязанным событием', () {
    final prediction = UserPrediction(
      id: 1,
      matchId: '1',
      chosenOutcome: MatchOutcome.homeWin,
      createdAt: DateTime.now(),
      status: PredictionStatus.active,
      pointsAwarded: 0,
    );
    expect(prediction.canEdit, isFalse);
    expect(prediction.copyWith(match: sampleMatch()).canEdit, isTrue);
    expect(
      prediction
          .copyWith(
            match: sampleMatch(
              status: MatchStatus.finished,
              homeScore: 1,
              awayScore: 0,
              kickoff: DateTime.now().subtract(const Duration(hours: 3)),
            ),
          )
          .canEdit,
      isFalse,
    );
  });
}
