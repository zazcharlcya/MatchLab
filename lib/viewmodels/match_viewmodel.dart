import 'package:flutter/foundation.dart';

import '../models/football_match.dart';
import '../models/loading_status.dart';
import '../models/match_outcome.dart';
import '../models/model_forecast.dart';
import '../models/user_prediction.dart';
import '../prediction_engine/prediction_engine.dart';
import '../repositories/match_repository.dart';
import '../repositories/prediction_repository.dart';
import '../services/app_logger.dart';

class MatchViewModel extends ChangeNotifier {
  MatchViewModel({
    required this.match,
    required MatchRepository matchRepository,
    required PredictionRepository predictionRepository,
    required PredictionEngine engine,
    required AppLog logger,
  })  : _matchRepository = matchRepository,
        _predictionRepository = predictionRepository,
        _engine = engine,
        _logger = logger;

  final FootballMatch match;
  final MatchRepository _matchRepository;
  final PredictionRepository _predictionRepository;
  final PredictionEngine _engine;
  final AppLog _logger;

  LoadingStatus status = LoadingStatus.initial;
  String? errorMessage;
  String? formError;
  MatchOutcome? selected;
  UserPrediction? existing;
  late ModelForecast forecast;
  List<FootballMatch> recent = const [];

  Future<void> load() async {
    status = LoadingStatus.loading;
    notifyListeners();
    try {
      recent = _matchRepository.historyFor(match.homeTeam, match.awayTeam);
      forecast = match.forecast ??
          _engine.forecast(
            homeTeam: match.homeTeam,
            awayTeam: match.awayTeam,
            history: recent,
          );
      existing = await _predictionRepository.byMatchId(match.id);
      selected = existing?.chosenOutcome;
      status = LoadingStatus.success;
      _logger.debug('Match: модель готова ${match.id}');
    } catch (error, stack) {
      _logger.error('Match: ошибка экрана', error, stack);
      errorMessage = 'Не удалось открыть аналитику матча.';
      status = LoadingStatus.error;
    }
    notifyListeners();
  }

  void select(MatchOutcome outcome) {
    selected = outcome;
    formError = null;
    notifyListeners();
  }

  bool validate() {
    if (selected == null) {
      formError = 'Выберите исход: победа хозяев, ничья или победа гостей.';
      notifyListeners();
      return false;
    }
    if (!match.canPredict) {
      formError = 'Прогноз можно сохранить только до начала матча.';
      notifyListeners();
      return false;
    }
    formError = null;
    return true;
  }

  Future<bool> save() async {
    if (!validate()) {
      return false;
    }
    try {
      if (existing == null) {
        existing = await _predictionRepository.create(
          match: match,
          outcome: selected!,
        );
      } else {
        await _predictionRepository.updateOutcome(existing!, selected!);
        existing = existing!.copyWith(chosenOutcome: selected);
      }
      notifyListeners();
      return true;
    } catch (error, stack) {
      _logger.error('Match: ошибка сохранения прогноза', error, stack);
      formError = error.toString().replaceFirst('Bad state: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> remove() async {
    final current = existing;
    if (current == null) {
      return;
    }
    await _predictionRepository.delete(current.id);
    existing = null;
    selected = null;
    notifyListeners();
  }
}
