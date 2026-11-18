import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/models/loading_status.dart';
import 'package:matchlab/services/api_service.dart';
import 'package:matchlab/services/app_logger.dart';
import 'package:matchlab/viewmodels/home_viewmodel.dart';

import 'helpers.dart';

void main() {
  test('успешная загрузка матчей через фейковый репозиторий', () async {
    final vm = HomeViewModel(
      matchRepository: FakeMatchRepository(matches: [sampleMatch()]),
      predictionRepository: FakePredictionRepository(),
      logger: const SilentLog(),
    );
    await vm.load();
    expect(vm.status, LoadingStatus.success);
    expect(vm.matches, hasLength(1));
    expect(vm.errorMessage, isNull);
  });

  test('ошибка API переводит ViewModel в error', () async {
    final vm = HomeViewModel(
      matchRepository: FakeMatchRepository(
        exception: const NetworkException('Нет сети. Проверьте подключение и попробуйте снова.'),
      ),
      predictionRepository: FakePredictionRepository(),
      logger: const SilentLog(),
    );
    await vm.load();
    expect(vm.status, LoadingStatus.error);
    expect(vm.errorMessage, contains('Нет сети'));
  });
}
