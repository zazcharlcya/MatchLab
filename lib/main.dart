import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'prediction_engine/prediction_engine.dart';
import 'repositories/match_repository.dart';
import 'repositories/prediction_repository.dart';
import 'repositories/user_repository.dart';
import 'screens/shell_screen.dart';
import 'services/api_service.dart';
import 'services/app_logger.dart';
import 'services/camera_service.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/predictions_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = AppLogger();
  final database = DatabaseService(logger: logger);
  final api = SportsApiService(logger: logger);
  final camera = CameraService();
  final engine = PredictionEngine();
  final matchRepository = SportsMatchRepository(
    api: api,
    database: database,
    engine: engine,
    logger: logger,
  );
  final predictionRepository = SqlitePredictionRepository(
    database: database,
    logger: logger,
  );
  final userRepository = SqliteUserRepository(
    database: database,
    camera: camera,
    logger: logger,
  );
  final themeController = ThemeController(userRepository: userRepository);
  try {
    await userRepository.ensureDefaultUser();
    await themeController.load();
  } catch (error, stack) {
    logger.error('Startup: не удалось открыть локальную базу', error, stack);
  }

  runApp(
    MatchLabApp(
      logger: logger,
      engine: engine,
      matchRepository: matchRepository,
      predictionRepository: predictionRepository,
      userRepository: userRepository,
      themeController: themeController,
    ),
  );
}

class MatchLabApp extends StatelessWidget {
  const MatchLabApp({
    super.key,
    required this.logger,
    required this.engine,
    required this.matchRepository,
    required this.predictionRepository,
    required this.userRepository,
    required this.themeController,
  });

  final AppLog logger;
  final PredictionEngine engine;
  final MatchRepository matchRepository;
  final PredictionRepository predictionRepository;
  final UserRepository userRepository;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppLog>.value(value: logger),
        Provider<PredictionEngine>.value(value: engine),
        Provider<MatchRepository>.value(value: matchRepository),
        Provider<PredictionRepository>.value(value: predictionRepository),
        Provider<UserRepository>.value(value: userRepository),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            matchRepository: matchRepository,
            predictionRepository: predictionRepository,
            logger: logger,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PredictionsViewModel(
            predictionRepository: predictionRepository,
            logger: logger,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(
            userRepository: userRepository,
            logger: logger,
          ),
        ),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'MatchLab',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.mode,
            home: const ShellScreen(),
          );
        },
      ),
    );
  }
}
