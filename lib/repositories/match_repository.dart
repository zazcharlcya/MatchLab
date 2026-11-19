import 'package:sqflite/sqflite.dart';

import '../models/football_match.dart';
import '../prediction_engine/prediction_engine.dart';
import '../services/api_service.dart';
import '../services/app_logger.dart';
import '../services/database_service.dart';

abstract class MatchRepository {
  Future<List<FootballMatch>> loadMatches();
  List<FootballMatch> historyFor(String homeTeam, String awayTeam);
}

class SportsMatchRepository implements MatchRepository {
  SportsMatchRepository({
    required SportsApiService api,
    required DatabaseService database,
    required PredictionEngine engine,
    required AppLog logger,
  })  : _api = api,
        _database = database,
        _engine = engine,
        _logger = logger;

  final SportsApiService _api;
  final DatabaseService _database;
  final PredictionEngine _engine;
  final AppLog _logger;
  List<FootballMatch> _cached = const [];

  @override
  List<FootballMatch> historyFor(String homeTeam, String awayTeam) {
    return _cached
        .where(
          (match) =>
              match.isFinished &&
              (match.homeTeam == homeTeam ||
                  match.awayTeam == homeTeam ||
                  match.homeTeam == awayTeam ||
                  match.awayTeam == awayTeam),
        )
        .toList();
  }

  @override
  Future<List<FootballMatch>> loadMatches() async {
    _logger.debug('Matches: загрузка из API');
    try {
      final remote = await _api.fetchLeagueMatches();
      final db = await _database.database;
      final batch = db.batch();
      for (final match in remote) {
        batch.insert(
          'matches',
          match.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (error, stack) {
      final stored = await _readStored();
      if (stored.isEmpty) {
        _logger.error('Matches: API недоступен и локальных матчей нет', error, stack);
        rethrow;
      }
      _logger.info('Matches: API недоступен, показаны сохранённые ${stored.length}');
      return _decorate(stored);
    }

    return _decorate(await _readStored());
  }

  Future<List<FootballMatch>> _readStored() async {
    final db = await _database.database;
    final rows = await db.query('matches', orderBy: 'kickoff_utc DESC');
    return rows.map(FootballMatch.fromMap).toList();
  }

  List<FootballMatch> _decorate(List<FootballMatch> stored) {
    final finished = stored.where((match) => match.isFinished).toList();
    _logger.debug('Matches: расчёт модели для ${stored.length} матчей');
    _cached = stored
        .map(
          (match) => match.copyWith(
            forecast: _engine.forecast(
              homeTeam: match.homeTeam,
              awayTeam: match.awayTeam,
              history: finished.where((item) => item.id != match.id).toList(),
            ),
          ),
        )
        .toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
    _logger.info('Matches: готово ${_cached.length}');
    return _cached;
  }
}
