import '../models/football_match.dart';
import '../models/match_outcome.dart';
import '../models/user_prediction.dart';
import '../prediction_engine/points_rules.dart';
import '../services/app_logger.dart';
import '../services/database_service.dart';

abstract class PredictionRepository {
  Future<List<UserPrediction>> getAll();
  Future<UserPrediction?> byMatchId(String matchId);
  Future<UserPrediction> create({
    required FootballMatch match,
    required MatchOutcome outcome,
  });
  Future<void> updateOutcome(UserPrediction prediction, MatchOutcome outcome);
  Future<void> delete(int id);
  Future<int> settleFinished(List<FootballMatch> matches);
}

class SqlitePredictionRepository implements PredictionRepository {
  SqlitePredictionRepository({
    required DatabaseService database,
    required AppLog logger,
  })  : _database = database,
        _logger = logger;

  final DatabaseService _database;
  final AppLog _logger;

  @override
  Future<List<UserPrediction>> getAll() async {
    final db = await _database.database;
    final rows = await db.query('predictions', orderBy: 'created_at DESC');
    final matchRows = await db.query('matches');
    final matches = {
      for (final row in matchRows) row['id']! as String: FootballMatch.fromMap(row),
    };
    return rows
        .map(UserPrediction.fromMap)
        .map((item) => item.copyWith(match: matches[item.matchId]))
        .toList();
  }

  @override
  Future<UserPrediction?> byMatchId(String matchId) async {
    final db = await _database.database;
    final rows = await db.query(
      'predictions',
      where: 'match_id = ?',
      whereArgs: [matchId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return UserPrediction.fromMap(rows.first);
  }

  @override
  Future<UserPrediction> create({
    required FootballMatch match,
    required MatchOutcome outcome,
  }) async {
    if (!match.canPredict) {
      throw StateError('Нельзя сохранить прогноз после начала матча.');
    }
    final db = await _database.database;
    final existing = await byMatchId(match.id);
    if (existing != null) {
      throw StateError('Прогноз на этот матч уже есть. Измените его в списке.');
    }
    final createdAt = DateTime.now();
    final id = await db.insert('predictions', {
      'match_id': match.id,
      'chosen_outcome': outcome.storageValue,
      'created_at': createdAt.toIso8601String(),
      'status': PredictionStatus.active.name,
      'points_awarded': 0,
    });
    _logger.info('Prediction: создан id=$id match=${match.id}');
    return UserPrediction(
      id: id,
      matchId: match.id,
      chosenOutcome: outcome,
      createdAt: createdAt,
      status: PredictionStatus.active,
      pointsAwarded: 0,
      match: match,
    );
  }

  @override
  Future<void> updateOutcome(UserPrediction prediction, MatchOutcome outcome) async {
    if (!prediction.isActive) {
      throw StateError('Прогноз больше нельзя изменить.');
    }
    if (prediction.match != null && !prediction.match!.canPredict) {
      throw StateError('Прогноз больше нельзя изменить.');
    }
    final db = await _database.database;
    await db.update(
      'predictions',
      {'chosen_outcome': outcome.storageValue},
      where: 'id = ? AND status = ?',
      whereArgs: [prediction.id, PredictionStatus.active.name],
    );
    _logger.info('Prediction: изменён id=${prediction.id}');
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete(
      'predictions',
      where: 'id = ? AND status = ?',
      whereArgs: [id, PredictionStatus.active.name],
    );
    _logger.info('Prediction: удалён id=$id');
  }

  @override
  Future<int> settleFinished(List<FootballMatch> matches) async {
    final db = await _database.database;
    var awardedTotal = 0;
    for (final match in matches.where((item) => item.isFinished)) {
      final actual = match.actualOutcome;
      if (actual == null) {
        continue;
      }
      final rows = await db.query(
        'predictions',
        where: 'match_id = ? AND status = ?',
        whereArgs: [match.id, PredictionStatus.active.name],
      );
      for (final row in rows) {
        final prediction = UserPrediction.fromMap(row);
        final alreadyAwarded = prediction.pointsAwarded > 0;
        final points = PointsRules.award(
          chosen: prediction.chosenOutcome,
          actual: actual,
          alreadyAwarded: alreadyAwarded,
        );
        final correct = PointsRules.isCorrect(prediction.chosenOutcome, actual);
        await db.update(
          'predictions',
          {
            'actual_outcome': actual.storageValue,
            'status': (correct ? PredictionStatus.correct : PredictionStatus.incorrect)
                .name,
            'points_awarded': alreadyAwarded ? prediction.pointsAwarded : points,
          },
          where: 'id = ?',
          whereArgs: [prediction.id],
        );
        if (!alreadyAwarded && points > 0) {
          await db.rawUpdate(
            'UPDATE users SET points = points + ? WHERE id = 1',
            [points],
          );
          awardedTotal += points;
          _logger.info('Points: +$points за прогноз ${prediction.id}');
        }
      }
    }
    return awardedTotal;
  }
}
