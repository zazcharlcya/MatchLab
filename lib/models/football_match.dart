import 'match_outcome.dart';
import 'model_forecast.dart';

enum MatchStatus { scheduled, live, finished }

class FootballMatch {
  const FootballMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.league,
    required this.kickoff,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.homeBadge,
    this.awayBadge,
    this.venue,
    this.forecast,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final String homeTeamId;
  final String awayTeamId;
  final String league;
  final DateTime kickoff;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final String? homeBadge;
  final String? awayBadge;
  final String? venue;
  final ModelForecast? forecast;

  bool get isFinished =>
      status == MatchStatus.finished && homeScore != null && awayScore != null;

  bool get canPredict =>
      status == MatchStatus.scheduled && DateTime.now().isBefore(kickoff);

  MatchOutcome? get actualOutcome {
    if (!isFinished) {
      return null;
    }
    return MatchOutcomeLabel.fromScore(homeScore!, awayScore!);
  }

  String get scoreLabel {
    if (homeScore == null || awayScore == null) {
      return '—';
    }
    return '$homeScore:$awayScore';
  }

  FootballMatch copyWith({ModelForecast? forecast}) {
    return FootballMatch(
      id: id,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      league: league,
      kickoff: kickoff,
      status: status,
      homeScore: homeScore,
      awayScore: awayScore,
      homeBadge: homeBadge,
      awayBadge: awayBadge,
      venue: venue,
      forecast: forecast ?? this.forecast,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'home_team': homeTeam,
      'away_team': awayTeam,
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'league': league,
      'kickoff_utc': kickoff.toIso8601String(),
      'status': status.name,
      'home_score': homeScore,
      'away_score': awayScore,
      'home_badge': homeBadge,
      'away_badge': awayBadge,
      'venue': venue,
    };
  }

  factory FootballMatch.fromMap(Map<String, Object?> map) {
    return FootballMatch(
      id: map['id']! as String,
      homeTeam: map['home_team']! as String,
      awayTeam: map['away_team']! as String,
      homeTeamId: (map['home_team_id'] as String?) ?? '',
      awayTeamId: (map['away_team_id'] as String?) ?? '',
      league: map['league']! as String,
      kickoff: DateTime.parse(map['kickoff_utc']! as String),
      status: MatchStatus.values.byName(map['status']! as String),
      homeScore: map['home_score'] as int?,
      awayScore: map['away_score'] as int?,
      homeBadge: map['home_badge'] as String?,
      awayBadge: map['away_badge'] as String?,
      venue: map['venue'] as String?,
    );
  }
}
