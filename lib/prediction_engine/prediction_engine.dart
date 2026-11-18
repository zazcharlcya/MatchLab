import 'dart:math' as math;

import '../models/football_match.dart';
import '../models/model_forecast.dart';
import 'elo_calculator.dart';
import 'poisson_model.dart';

/// MatchLab Prediction Engine: Elo задаёт силу команд,
/// Пуассон — вероятности голов и исходов 1X2.
///
/// λ_home = att_home * def_away * μ_home * home_boost * elo_shift
/// λ_away = att_away * def_home * μ_away / elo_shift
///
/// att = среднее забитых команды / среднее забитых лиги
/// def = среднее пропущенных команды / среднее пропущенных лиги
/// elo_shift = exp(0.35 * tanh((R_home + H - R_away) / 200))
class PredictionEngine {
  PredictionEngine({
    EloCalculator? eloCalculator,
    PoissonModel? poissonModel,
  })  : eloCalculator = eloCalculator ?? const EloCalculator(),
        poissonModel = poissonModel ?? const PoissonModel();

  final EloCalculator eloCalculator;
  final PoissonModel poissonModel;

  static const double defaultHomeMu = 1.45;
  static const double defaultAwayMu = 1.15;
  static const double homeLambdaBoost = 1.08;

  ModelForecast forecast({
    required String homeTeam,
    required String awayTeam,
    required List<FootballMatch> history,
  }) {
    final finished = history.where((match) => match.isFinished).toList();
    final ratings = eloCalculator.ratingsFromMatches(finished);
    final homeElo = ratings[homeTeam] ?? eloCalculator.initialRating;
    final awayElo = ratings[awayTeam] ?? eloCalculator.initialRating;

    final league = _leagueAverages(finished);
    final homeStats = _teamStats(homeTeam, finished, league);
    final awayStats = _teamStats(awayTeam, finished, league);

    final eloDiff = (homeElo + eloCalculator.homeAdvantage) - awayElo;
    final eloShift = math.exp(0.35 * _tanh(eloDiff / 200));

    var lambdaHome =
        homeStats.attack * awayStats.defense * league.homeMu * homeLambdaBoost * eloShift;
    var lambdaAway =
        awayStats.attack * homeStats.defense * league.awayMu / eloShift;

    lambdaHome = lambdaHome.clamp(0.25, 4.5);
    lambdaAway = lambdaAway.clamp(0.25, 4.5);

    final outcomes = poissonModel.outcomes(lambdaHome, lambdaAway);
    return ModelForecast(
      homeWin: outcomes.homeWin,
      draw: outcomes.draw,
      awayWin: outcomes.awayWin,
      homeElo: homeElo,
      awayElo: awayElo,
      expectedHomeGoals: lambdaHome,
      expectedAwayGoals: lambdaAway,
      topScores: poissonModel.topScores(lambdaHome, lambdaAway),
    );
  }

  _LeagueAverages _leagueAverages(List<FootballMatch> finished) {
    if (finished.isEmpty) {
      return const _LeagueAverages(homeMu: defaultHomeMu, awayMu: defaultAwayMu);
    }
    var homeGoals = 0;
    var awayGoals = 0;
    for (final match in finished) {
      homeGoals += match.homeScore!;
      awayGoals += match.awayScore!;
    }
    return _LeagueAverages(
      homeMu: homeGoals / finished.length,
      awayMu: awayGoals / finished.length,
    );
  }

  _TeamStrength _teamStats(
    String team,
    List<FootballMatch> finished,
    _LeagueAverages league,
  ) {
    var scored = 0;
    var conceded = 0;
    var games = 0;
    for (final match in finished) {
      if (match.homeTeam == team) {
        scored += match.homeScore!;
        conceded += match.awayScore!;
        games += 1;
      } else if (match.awayTeam == team) {
        scored += match.awayScore!;
        conceded += match.homeScore!;
        games += 1;
      }
    }
    if (games == 0) {
      return const _TeamStrength(attack: 1, defense: 1);
    }
    final leagueMu = (league.homeMu + league.awayMu) / 2;
    final attack = (scored / games) / (leagueMu == 0 ? 1 : leagueMu);
    final defense = (conceded / games) / (leagueMu == 0 ? 1 : leagueMu);
    return _TeamStrength(
      attack: attack.clamp(0.4, 2.2),
      defense: defense.clamp(0.4, 2.2),
    );
  }

  double _tanh(double x) {
    final value = x.clamp(-20, 20);
    final e2x = math.exp(2 * value);
    return (e2x - 1) / (e2x + 1);
  }
}

class _LeagueAverages {
  const _LeagueAverages({required this.homeMu, required this.awayMu});

  final double homeMu;
  final double awayMu;
}

class _TeamStrength {
  const _TeamStrength({required this.attack, required this.defense});

  final double attack;
  final double defense;
}
