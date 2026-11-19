import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/models/football_match.dart';
import 'package:matchlab/prediction_engine/elo_calculator.dart';

import 'helpers.dart';

void main() {
  const calculator = EloCalculator();

  test('равные рейтинги дают ожидаемый результат 0.5', () {
    expect(calculator.expectedScore(1500, 1500), closeTo(0.5, 0.0001));
  });

  test('победа поднимает рейтинг на K * (1 - E)', () {
    final next = calculator.updatedRating(rating: 1500, expected: 0.5, actual: 1);
    expect(next, closeTo(1510, 0.0001));
  });

  test('история матчей меняет Elo с учётом домашнего поля', () {
    final ratings = calculator.ratingsFromMatches([
      sampleMatch(
        id: 'm1',
        home: 'Arsenal',
        away: 'Chelsea',
        homeScore: 2,
        awayScore: 0,
        status: MatchStatus.finished,
        kickoff: DateTime(2026, 1, 1),
      ),
    ]);
    expect(ratings['Arsenal']!, greaterThan(1500));
    expect(ratings['Chelsea']!, lessThan(1500));
  });

  test('крупный счёт двигает Elo сильнее минимальной победы', () {
    final narrow = calculator.ratingsFromMatches([
      sampleMatch(
        id: 'n',
        home: 'Arsenal',
        away: 'Chelsea',
        homeScore: 1,
        awayScore: 0,
        status: MatchStatus.finished,
        kickoff: DateTime(2026, 1, 1),
      ),
    ]);
    final blowout = calculator.ratingsFromMatches([
      sampleMatch(
        id: 'b',
        home: 'Arsenal',
        away: 'Chelsea',
        homeScore: 4,
        awayScore: 0,
        status: MatchStatus.finished,
        kickoff: DateTime(2026, 1, 1),
      ),
    ]);
    expect(
      blowout['Arsenal']! - 1500,
      greaterThan(narrow['Arsenal']! - 1500),
    );
  });
}
