import 'package:matchlab/models/football_match.dart';
import 'package:matchlab/models/match_outcome.dart';
import 'package:matchlab/models/user_prediction.dart';
import 'package:matchlab/repositories/match_repository.dart';
import 'package:matchlab/repositories/prediction_repository.dart';

FootballMatch sampleMatch({
  String id = '1',
  String home = 'Arsenal',
  String away = 'Chelsea',
  int? homeScore,
  int? awayScore,
  MatchStatus status = MatchStatus.scheduled,
  DateTime? kickoff,
}) {
  return FootballMatch(
    id: id,
    homeTeam: home,
    awayTeam: away,
    homeTeamId: 'h$id',
    awayTeamId: 'a$id',
    league: 'English Premier League',
    kickoff: kickoff ?? DateTime.now().add(const Duration(days: 1)),
    status: status,
    homeScore: homeScore,
    awayScore: awayScore,
  );
}

class FakeMatchRepository implements MatchRepository {
  FakeMatchRepository({this.matches = const [], this.exception});

  final List<FootballMatch> matches;
  final Exception? exception;

  @override
  List<FootballMatch> historyFor(String homeTeam, String awayTeam) =>
      matches.where((match) => match.isFinished).toList();

  @override
  Future<List<FootballMatch>> loadMatches() async {
    final error = exception;
    if (error != null) {
      throw error;
    }
    return matches;
  }
}

class FakePredictionRepository implements PredictionRepository {
  @override
  Future<UserPrediction?> byMatchId(String matchId) async => null;

  @override
  Future<UserPrediction> create({
    required FootballMatch match,
    required MatchOutcome outcome,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<UserPrediction>> getAll() async => const [];

  @override
  Future<int> settleFinished(List<FootballMatch> matches) async => 0;

  @override
  Future<void> updateOutcome(UserPrediction prediction, MatchOutcome outcome) async {}
}
