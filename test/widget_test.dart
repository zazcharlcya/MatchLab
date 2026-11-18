import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchlab/models/loading_status.dart';
import 'package:matchlab/screens/home_screen.dart';
import 'package:matchlab/services/app_logger.dart';
import 'package:matchlab/theme/app_theme.dart';
import 'package:matchlab/viewmodels/home_viewmodel.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';

void main() {
  testWidgets('главный экран показывает список матчей', (tester) async {
    final vm = HomeViewModel(
      matchRepository: FakeMatchRepository(
        matches: [
          sampleMatch(id: '1', home: 'Arsenal', away: 'Chelsea'),
          sampleMatch(id: '2', home: 'Liverpool', away: 'Everton'),
        ],
      ),
      predictionRepository: FakePredictionRepository(),
      logger: const SilentLog(),
    );
    await vm.load();
    expect(vm.status, LoadingStatus.success);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const HomeScreen(loadOnStart: false),
        ),
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Arsenal'), findsOneWidget);
    expect(find.text('Liverpool'), findsOneWidget);
  });

  testWidgets('пустой список не роняет главный экран', (tester) async {
    final vm = HomeViewModel(
      matchRepository: FakeMatchRepository(),
      predictionRepository: FakePredictionRepository(),
      logger: const SilentLog(),
    );
    await vm.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: HomeScreen(loadOnStart: false)),
      ),
    );

    expect(find.text('Матчей нет'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
