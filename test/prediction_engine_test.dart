import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/models/football_match.dart';
import 'package:matchlab/models/match_outcome.dart';
import 'package:matchlab/prediction_engine/prediction_engine.dart';

import 'helpers.dart';

void main() {
  final engine = PredictionEngine();

  test('вероятности 1X2 нормализованы и фаворит дома сильнее', () {
    final history = [
      sampleMatch(
        id: '1',
        home: 'Arsenal',
        away: 'Burnley',
        homeScore: 3,
        awayScore: 0,
        status: MatchStatus.finished,
        kickoff: DateTime(2026, 1, 1),
      ),
      sampleMatch(
        id: '2',
        home: 'Burnley',
        away: 'Arsenal',
        homeScore: 0,
        awayScore: 2,
        status: MatchStatus.finished,
        kickoff: DateTime(2026, 1, 8),
      ),
    ];
    final forecast = engine.forecast(
      homeTeam: 'Arsenal',
      awayTeam: 'Burnley',
      history: history,
    );
    expect(forecast.homeWin + forecast.draw + forecast.awayWin, closeTo(1, 0.001));
    expect(forecast.homeWin, greaterThan(forecast.awayWin));
    expect(forecast.pick, MatchOutcome.homeWin);
  });
}
