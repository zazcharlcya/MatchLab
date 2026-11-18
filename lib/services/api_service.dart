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
    this.baseUrl = 'https://www.thesportsdb.com/api/v1/json/123',
  })  : _logger = logger,
        _client = client ?? http.Client();

  final AppLog _logger;
  final http.Client _client;
  final String baseUrl;

  static const leagues = <String, String>{
    '4328': 'English Premier League',
    '4335': 'Spanish La Liga',
  };

  Future<List<FootballMatch>> fetchLeagueMatches() async {
    final matches = <FootballMatch>[];
    try {
      for (final id in leagues.keys) {
        matches.addAll(await _fetchEvents('/eventsnextleague.php', {'id': id}));
        matches.addAll(await _fetchEvents('/eventspastleague.php', {'id': id}));
      }
    } on SocketException catch (error, stack) {
      _logger.error('API: нет сети', error, stack);
      throw const NetworkException(
        'Нет сети. Проверьте подключение и попробуйте снова.',
      );
    } on HttpException catch (error, stack) {
      _logger.error('API: HTTP ошибка', error, stack);
      throw const NetworkException('Сервер футбольных данных недоступен.');
    }
    _logger.info('API: загружено матчей ${matches.length}');
    return matches;
  }

  Future<List<FootballMatch>> _fetchEvents(
    String path,
    Map<String, String> query,
  ) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw HttpException('status ${response.statusCode}', uri: uri);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }
    final events = decoded['events'];
    if (events is! List) {
      return const [];
    }
    return events
        .whereType<Map<String, dynamic>>()
        .map(_mapEvent)
        .whereType<FootballMatch>()
        .toList();
  }

  FootballMatch? _mapEvent(Map<String, dynamic> json) {
    final id = json['idEvent']?.toString();
    final home = json['strHomeTeam'] as String?;
    final away = json['strAwayTeam'] as String?;
    if (id == null || home == null || away == null) {
      return null;
    }
    final kickoff = _parseKickoff(json);
    final homeScore = _parseInt(json['intHomeScore']);
    final awayScore = _parseInt(json['intAwayScore']);
    return FootballMatch(
      id: id,
      homeTeam: home,
      awayTeam: away,
      homeTeamId: json['idHomeTeam']?.toString() ?? '',
      awayTeamId: json['idAwayTeam']?.toString() ?? '',
      league: (json['strLeague'] as String?) ?? 'Football',
      kickoff: kickoff,
      status: _statusOf(json['strStatus']?.toString(), homeScore, awayScore, kickoff),
      homeScore: homeScore,
      awayScore: awayScore,
      homeBadge: json['strHomeTeamBadge'] as String?,
      awayBadge: json['strAwayTeamBadge'] as String?,
      venue: json['strVenue'] as String?,
    );
  }

  DateTime _parseKickoff(Map<String, dynamic> json) {
    final stamp = json['strTimestamp'] as String?;
    if (stamp != null && stamp.isNotEmpty) {
      return DateTime.tryParse(stamp)?.toLocal() ?? DateTime.now();
    }
    final date = json['dateEvent'] as String? ?? '';
    final time = json['strTime'] as String? ?? '12:00:00';
    return DateTime.tryParse('${date}T$time')?.toLocal() ?? DateTime.now();
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

  MatchStatus _statusOf(
    String? raw,
    int? homeScore,
    int? awayScore,
    DateTime kickoff,
  ) {
    final status = (raw ?? '').toUpperCase();
    const finished = {'FT', 'AET', 'PEN', 'FT_PEN', 'AOT', 'WO'};
    const live = {'1H', '2H', 'HT', 'ET', 'LIVE', 'P', 'BT'};
    if (finished.contains(status)) {
      return MatchStatus.finished;
    }
    if (live.contains(status)) {
      return MatchStatus.live;
    }
    if (homeScore != null && awayScore != null && status != 'NS') {
      return MatchStatus.finished;
    }
    final now = DateTime.now();
    if (now.isAfter(kickoff.add(const Duration(hours: 2))) &&
        homeScore != null &&
        awayScore != null) {
      return MatchStatus.finished;
    }
    if (now.isAfter(kickoff) && now.isBefore(kickoff.add(const Duration(hours: 2)))) {
      return MatchStatus.live;
    }
    return MatchStatus.scheduled;
  }
}
