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

  test('свежий крупный проигрыш сильнее старой победы', () {
    final history = [
      sampleMatch(
        id: 'old',
        home: 'Arsenal',
        away: 'Burnley',
        homeScore: 5,
        awayScore: 0,
        status: MatchStatus.finished,
        kickoff: DateTime(2025, 1, 1),
      ),
      sampleMatch(
        id: 'new',
        home: 'Arsenal',
        away: 'Burnley',
        homeScore: 0,
        awayScore: 3,
        status: MatchStatus.finished,
        kickoff: DateTime(2026, 11, 1),
      ),
    ];
    final forecast = engine.forecast(
      homeTeam: 'Arsenal',
      awayTeam: 'Burnley',
      history: history,
    );
    expect(forecast.homeWin + forecast.draw + forecast.awayWin, closeTo(1, 0.001));
    expect(forecast.homeWin, lessThan(0.72));
  });

  test('даже разгромный фаворит не получает 95% на П1', () {
    final history = [
      for (var i = 0; i < 8; i++)
        sampleMatch(
          id: 'w$i',
          home: 'Bayern',
          away: 'Koln',
          homeScore: 5,
          awayScore: 0,
          status: MatchStatus.finished,
          kickoff: DateTime(2026, 8, 1).add(Duration(days: i * 7)),
        ),
    ];
    final forecast = engine.forecast(
      homeTeam: 'Bayern',
      awayTeam: 'Koln',
      history: history,
    );
    expect(forecast.homeWin + forecast.draw + forecast.awayWin, closeTo(1, 0.001));
    expect(forecast.homeWin, greaterThan(0.55));
    expect(forecast.homeWin, lessThan(0.86));
    expect(forecast.expectedHomeGoals, lessThanOrEqualTo(2.35));
    expect(forecast.expectedAwayGoals, greaterThanOrEqualTo(0.8));
  });
}
