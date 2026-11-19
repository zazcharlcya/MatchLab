import 'dart:math' as math;

import '../models/football_match.dart';
import '../models/model_forecast.dart';
import 'elo_calculator.dart';
import 'poisson_model.dart';

/// MatchLab Prediction Engine.
///
/// 1. Elo с домашним полем и весом разницы голов → сила команд
/// 2. Атака/оборона относительно лиги, свежие матчи весят больше
/// 3. Сила ужимается к среднему лиги, λ ограничен —
///    чтобы фаворит не получал 95% из разгромных счетов
/// 4. Пуассон + Dixon–Coles → 1X2
///
/// λ_home = att_home * def_away * μ_home * home_boost * elo_shift
/// elo_shift = exp(0.22 * tanh((R_home + H - R_away) / 200))
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
  static const double homeLambdaBoost = 1.04;
  static const double recencyHalfLifeDays = 45;
  static const double strengthShrink = 0.4;
  static const double eloShiftScale = 0.22;

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
    final eloShift = math.exp(eloShiftScale * _tanh(eloDiff / 200));

    var lambdaHome =
        homeStats.attack * awayStats.defense * league.homeMu * homeLambdaBoost * eloShift;
    var lambdaAway =
        awayStats.attack * homeStats.defense * league.awayMu / eloShift;

    lambdaHome = lambdaHome.clamp(0.8, 2.35);
    lambdaAway = lambdaAway.clamp(0.8, 2.35);

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
    var homeGoals = 0.0;
    var awayGoals = 0.0;
    var weight = 0.0;
    final latest = _latestKickoff(finished);
    for (final match in finished) {
      final w = _recencyWeight(match, latest);
      homeGoals += match.homeScore! * w;
      awayGoals += match.awayScore! * w;
      weight += w;
    }
    if (weight == 0) {
      return const _LeagueAverages(homeMu: defaultHomeMu, awayMu: defaultAwayMu);
    }
    return _LeagueAverages(
      homeMu: homeGoals / weight,
      awayMu: awayGoals / weight,
    );
  }

  _TeamStrength _teamStats(
    String team,
    List<FootballMatch> finished,
    _LeagueAverages league,
  ) {
    var scored = 0.0;
    var conceded = 0.0;
    var games = 0.0;
    final latest = _latestKickoff(finished);
    for (final match in finished) {
      final w = _recencyWeight(match, latest);
      if (match.homeTeam == team) {
        scored += match.homeScore! * w;
        conceded += match.awayScore! * w;
        games += w;
      } else if (match.awayTeam == team) {
        scored += match.awayScore! * w;
        conceded += match.homeScore! * w;
        games += w;
      }
    }
    if (games == 0) {
      return const _TeamStrength(attack: 1, defense: 1);
    }
    final leagueMu = (league.homeMu + league.awayMu) / 2;
    final rawAttack = (scored / games) / (leagueMu == 0 ? 1 : leagueMu);
    final rawDefense = (conceded / games) / (leagueMu == 0 ? 1 : leagueMu);
    return _TeamStrength(
      attack: _shrink(rawAttack.clamp(0.55, 1.75)),
      defense: _shrink(rawDefense.clamp(0.55, 1.75)),
    );
  }

  /// Тянет атаку/оборону к 1, чтобы разгромы не давали λ = 4 против 0.4.
  double _shrink(double value) => 1 + (value - 1) * strengthShrink;

  DateTime? _latestKickoff(List<FootballMatch> finished) {
    if (finished.isEmpty) {
      return null;
    }
    return finished
        .map((match) => match.kickoff)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  double _recencyWeight(FootballMatch match, DateTime? latest) {
    if (latest == null) {
      return 1;
    }
    final days = latest.difference(match.kickoff).inDays.clamp(0, 400);
    return math.exp(-math.ln2 * days / recencyHalfLifeDays);
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
