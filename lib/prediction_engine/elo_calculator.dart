import 'dart:math' as math;

import '../models/football_match.dart';

/// Классический Elo для футбола + вес разницы голов (как в FIFA World Ranking).
///
/// Ожидаемый результат:
///   E_home = 1 / (1 + 10^((R_away - (R_home + H)) / 400))
///
/// Обновление:
///   R' = R + K * G * (S - E)
///
/// S = 1 победа, 0.5 ничья, 0 поражение.
/// H — бонус домашнего поля в рейтинговых очках.
/// G — множитель разницы голов:
///   1 гол → 1.0,  2 гола → 1.5,  3+ → (11 + |Δ|) / 8
class EloCalculator {
  const EloCalculator({
    this.kFactor = 20,
    this.homeAdvantage = 60,
    this.initialRating = 1500,
  });

  final double kFactor;
  final double homeAdvantage;
  final double initialRating;

  double expectedScore(double ratingA, double ratingB) {
    return 1 / (1 + math.pow(10, (ratingB - ratingA) / 400));
  }

  double updatedRating({
    required double rating,
    required double expected,
    required double actual,
    double margin = 1,
  }) {
    return rating + kFactor * margin * (actual - expected);
  }

  /// FIFA-стиль: крупный счёт двигает рейтинг сильнее минимальной победы.
  double marginMultiplier(int homeGoals, int awayGoals) {
    final difference = (homeGoals - awayGoals).abs();
    if (difference <= 1) {
      return 1;
    }
    if (difference == 2) {
      return 1.5;
    }
    return (11 + difference) / 8;
  }

  Map<String, double> ratingsFromMatches(List<FootballMatch> finished) {
    final ratings = <String, double>{};
    final ordered = [...finished]
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

    for (final match in ordered) {
      if (!match.isFinished) {
        continue;
      }
      final home = ratings.putIfAbsent(match.homeTeam, () => initialRating);
      final away = ratings.putIfAbsent(match.awayTeam, () => initialRating);
      final expectedHome = expectedScore(home + homeAdvantage, away);
      final actualHome = _actualHomeScore(match.homeScore!, match.awayScore!);
      final margin = marginMultiplier(match.homeScore!, match.awayScore!);
      ratings[match.homeTeam] = updatedRating(
        rating: home,
        expected: expectedHome,
        actual: actualHome,
        margin: margin,
      );
      ratings[match.awayTeam] = updatedRating(
        rating: away,
        expected: 1 - expectedHome,
        actual: 1 - actualHome,
        margin: margin,
      );
    }
    return ratings;
  }

  double _actualHomeScore(int home, int away) {
    if (home > away) {
      return 1;
    }
    if (home < away) {
      return 0;
    }
    return 0.5;
  }
}
