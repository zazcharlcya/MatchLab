import 'package:flutter/foundation.dart';

import '../models/loading_status.dart';
import '../models/user_prediction.dart';
import '../repositories/prediction_repository.dart';
import '../services/app_logger.dart';

enum PredictionListFilter { all, active, correct, incorrect }

class PredictionsViewModel extends ChangeNotifier {
  PredictionsViewModel({
    required PredictionRepository predictionRepository,
    required AppLog logger,
  })  : _predictionRepository = predictionRepository,
        _logger = logger;

  final PredictionRepository _predictionRepository;
  final AppLog _logger;

  LoadingStatus status = LoadingStatus.initial;
  String? errorMessage;
  List<UserPrediction> items = const [];
  PredictionListFilter filter = PredictionListFilter.all;

  List<UserPrediction> get visible {
    return items.where((item) {
      return switch (filter) {
        PredictionListFilter.all => true,
        PredictionListFilter.active => item.status == PredictionStatus.active,
        PredictionListFilter.correct => item.status == PredictionStatus.correct,
        PredictionListFilter.incorrect => item.status == PredictionStatus.incorrect,
      };
    }).toList();
  }

  void setFilter(PredictionListFilter value) {
    filter = value;
    notifyListeners();
  }

  Future<void> load() async {
    status = LoadingStatus.loading;
    notifyListeners();
    try {
      items = await _predictionRepository.getAll();
      status = LoadingStatus.success;
    } catch (error, stack) {
      _logger.error('Predictions: ошибка загрузки', error, stack);
      errorMessage = 'Не удалось прочитать сохранённые прогнозы.';
      status = LoadingStatus.error;
    }
    notifyListeners();
  }

  Future<void> delete(UserPrediction prediction) async {
    await _predictionRepository.delete(prediction.id);
    await load();
  }
}
