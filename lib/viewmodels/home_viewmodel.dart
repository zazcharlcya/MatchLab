import 'package:flutter/foundation.dart';

import '../models/football_match.dart';
import '../models/loading_status.dart';
import '../models/user_prediction.dart';
import '../repositories/match_repository.dart';
import '../repositories/prediction_repository.dart';
import '../services/api_service.dart';
import '../services/app_logger.dart';

enum MatchListFilter { all, upcoming, finished }

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required MatchRepository matchRepository,
    required PredictionRepository predictionRepository,
    required AppLog logger,
  })  : _matchRepository = matchRepository,
        _predictionRepository = predictionRepository,
        _logger = logger;

  final MatchRepository _matchRepository;
  final PredictionRepository _predictionRepository;
  final AppLog _logger;

  LoadingStatus status = LoadingStatus.initial;
  String? errorMessage;
  List<FootballMatch> matches = const [];
  Map<String, UserPrediction> predictionsByMatch = const {};
  String query = '';
  MatchListFilter filter = MatchListFilter.upcoming;

  UserPrediction? predictionFor(FootballMatch match) => predictionsByMatch[match.id];

  List<FootballMatch> get visible {
    final needle = query.trim().toLowerCase();
    return matches.where((match) {
      final byFilter = switch (filter) {
        MatchListFilter.all => true,
        MatchListFilter.upcoming => match.status != MatchStatus.finished,
        MatchListFilter.finished => match.status == MatchStatus.finished,
      };
      if (!byFilter) {
        return false;
      }
      if (needle.isEmpty) {
        return true;
      }
      return match.homeTeam.toLowerCase().contains(needle) ||
          match.awayTeam.toLowerCase().contains(needle) ||
          match.league.toLowerCase().contains(needle);
    }).toList();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setFilter(MatchListFilter value) {
    filter = value;
    notifyListeners();
  }

  Future<void> load() async {
    status = LoadingStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      matches = await _matchRepository.loadMatches();
      await _predictionRepository.settleFinished(matches);
      await _loadPredictions();
      status = LoadingStatus.success;
    } catch (error, stack) {
      _logger.error('Home: ошибка загрузки', error, stack);
      errorMessage = error is NetworkException
          ? error.message
          : 'Не удалось загрузить матчи. Потяните вниз, чтобы повторить.';
      status = LoadingStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshPredictions() async {
    await _loadPredictions();
    notifyListeners();
  }

  Future<void> _loadPredictions() async {
    final items = await _predictionRepository.getAll();
    predictionsByMatch = {
      for (final item in items) item.matchId: item,
    };
  }
}
