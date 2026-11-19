import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/football_match.dart';
import 'app_logger.dart';

class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SportsApiService {
  SportsApiService({
    required AppLog logger,
    http.Client? client,
    this.baseUrl = 'https://api.openligadb.de',
    this.timeout = const Duration(seconds: 20),
  })  : _logger = logger,
        _client = client ?? http.Client();

  final AppLog _logger;
  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'MatchLab/1.0 (Android; football analytics)',
  };

  /// Bundesliga, текущий сезон. Один запрос, без ключа.
  static const seasonPath = '/getmatchdata/bl1/2026';

  Future<List<FootballMatch>> fetchLeagueMatches() async {
    final uri = Uri.parse('$baseUrl$seasonPath');
    try {
      final response = await _client.get(uri, headers: _headers).timeout(timeout);
      _logger.info('API: ${response.statusCode} $seasonPath');
      if (response.statusCode != 200) {
        throw HttpException('status ${response.statusCode}', uri: uri);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const NetworkException('Сервер футбольных данных недоступен.');
      }
      final matches = decoded
          .whereType<Map<String, dynamic>>()
          .map(_mapEvent)
          .whereType<FootballMatch>()
          .toList();
      if (matches.isEmpty) {
        throw const NetworkException(
          'Сервер футбольных данных недоступен. Потяните вниз, чтобы повторить.',
        );
      }
      _logger.info('API: загружено матчей ${matches.length}');
      return matches;
    } on NetworkException {
      rethrow;
    } on SocketException catch (error, stack) {
      _logger.error('API: нет сети', error, stack);
      throw const NetworkException(
        'Нет сети. Проверьте подключение и попробуйте снова.',
      );
    } on TimeoutException catch (error, stack) {
      _logger.error('API: таймаут', error, stack);
      throw const NetworkException(
        'Сервер слишком долго отвечает. Потяните вниз, чтобы повторить.',
      );
    } on HttpException catch (error, stack) {
      _logger.error('API: HTTP ошибка', error, stack);
      throw const NetworkException(
        'Сервер футбольных данных недоступен. Потяните вниз, чтобы повторить.',
      );
    } on FormatException catch (error, stack) {
      _logger.error('API: битый ответ', error, stack);
      throw const NetworkException(
        'Сервер футбольных данных недоступен. Потяните вниз, чтобы повторить.',
      );
    } catch (error, stack) {
      _logger.error('API: неизвестная ошибка', error, stack);
      throw const NetworkException(
        'Сервер футбольных данных недоступен. Потяните вниз, чтобы повторить.',
      );
    }
  }

  FootballMatch? _mapEvent(Map<String, dynamic> json) {
    final id = json['matchID']?.toString();
    final team1 = json['team1'];
    final team2 = json['team2'];
    if (id == null || team1 is! Map || team2 is! Map) {
      return null;
    }
    final home = team1['teamName'] as String?;
    final away = team2['teamName'] as String?;
    if (home == null || away == null) {
      return null;
    }
    final kickoff = DateTime.tryParse(
          (json['matchDateTimeUTC'] as String?) ?? json['matchDateTime'] as String? ?? '',
        )?.toLocal() ??
        DateTime.now();
    final finished = json['matchIsFinished'] == true;
    final homeScore = finished ? _finalScore(json, home: true) : null;
    final awayScore = finished ? _finalScore(json, home: false) : null;
    return FootballMatch(
      id: id,
      homeTeam: home,
      awayTeam: away,
      homeTeamId: team1['teamId']?.toString() ?? '',
      awayTeamId: team2['teamId']?.toString() ?? '',
      league: (json['leagueName'] as String?) ?? 'Bundesliga',
      kickoff: kickoff,
      status: finished ? MatchStatus.finished : MatchStatus.scheduled,
      homeScore: homeScore,
      awayScore: awayScore,
      homeBadge: team1['teamIconUrl'] as String?,
      awayBadge: team2['teamIconUrl'] as String?,
    );
  }

  int? _finalScore(Map<String, dynamic> json, {required bool home}) {
    final results = json['matchResults'];
    if (results is! List) {
      return null;
    }
    final maps = results.whereType<Map<String, dynamic>>().toList();
    Map<String, dynamic>? full;
    for (final result in maps) {
      if (result['resultTypeID'] == 2 || result['resultName'] == 'Endergebnis') {
        full = result;
        break;
      }
    }
    full ??= maps.isEmpty ? null : maps.last;
    if (full == null) {
      return null;
    }
    return _parseInt(home ? full['pointsTeam1'] : full['pointsTeam2']);
  }

  int? _parseInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}
