import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

abstract class AppLog {
  void debug(String message);
  void info(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

class AppLogger implements AppLog {
  AppLogger({Logger? logger})
      : _logger = logger ??
            Logger(
              printer: PrettyPrinter(
                methodCount: 0,
                errorMethodCount: 4,
                lineLength: 80,
                colors: false,
              ),
              output: ConsoleOutput(),
              level: kReleaseMode ? Level.warning : Level.debug,
            );

  final Logger _logger;

  @override
  void debug(String message) => _logger.d(message);

  @override
  void info(String message) => _logger.i(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

class SilentLog implements AppLog {
  const SilentLog();

  @override
  void debug(String message) {}

  @override
  void info(String message) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}
