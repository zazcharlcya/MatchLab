import 'match_outcome.dart';
import 'scoreline.dart';

class ModelForecast {
  const ModelForecast({
    required this.homeWin,
    required this.draw,
    required this.awayWin,
    required this.homeElo,
    required this.awayElo,
    required this.expectedHomeGoals,
    required this.expectedAwayGoals,
    required this.topScores,
  });

  final double homeWin;
  final double draw;
  final double awayWin;
  final double homeElo;
  final double awayElo;
  final double expectedHomeGoals;
  final double expectedAwayGoals;
  final List<Scoreline> topScores;

  MatchOutcome get pick {
    if (homeWin >= draw && homeWin >= awayWin) {
      return MatchOutcome.homeWin;
    }
    if (awayWin >= draw && awayWin >= homeWin) {
      return MatchOutcome.awayWin;
    }
    return MatchOutcome.draw;
  }

  double probabilityOf(MatchOutcome outcome) {
    switch (outcome) {
      case MatchOutcome.homeWin:
        return homeWin;
      case MatchOutcome.draw:
        return draw;
      case MatchOutcome.awayWin:
        return awayWin;
    }
  }
}
