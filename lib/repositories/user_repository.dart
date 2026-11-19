import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';
import '../services/app_logger.dart';
import '../services/camera_service.dart';
import '../services/database_service.dart';

abstract class UserRepository {
  Future<UserProfile> ensureDefaultUser();
  Future<UserProfile> getUser();
  Future<void> updateName(String name);
  Future<String?> updateAvatarFromCamera();
  Future<bool> isDarkTheme();
  Future<void> setDarkTheme(bool value);
  Future<ProfileStats> stats();
}

class SqliteUserRepository implements UserRepository {
  SqliteUserRepository({
    required DatabaseService database,
    required CameraService camera,
    required AppLog logger,
  })  : _database = database,
        _camera = camera,
        _logger = logger;

  final DatabaseService _database;
  final CameraService _camera;
  final AppLog _logger;

  static const defaultName = 'Аналитик';

  @override
  Future<UserProfile> ensureDefaultUser() async {
    final db = await _database.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      await db.insert('users', {
        'id': 1,
        'name': defaultName,
        'points': 0,
        'dark_theme': 1,
      });
      _logger.info('User: создан локальный профиль');
    }
    return getUser();
  }

  @override
  Future<UserProfile> getUser() async {
    final db = await _database.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [1]);
    return UserProfile.fromMap(rows.first);
  }

  @override
  Future<void> updateName(String name) async {
    final db = await _database.database;
    await db.update(
      'users',
      {'name': name},
      where: 'id = ?',
      whereArgs: [1],
    );
    _logger.info('User: имя обновлено');
  }

  @override
  Future<String?> updateAvatarFromCamera() async {
    final path = await _camera.takeAvatarPhoto();
    if (path == null) {
      return null;
    }
    final db = await _database.database;
    await db.update(
      'users',
      {'avatar_path': path},
      where: 'id = ?',
      whereArgs: [1],
    );
    _logger.info('User: аватар обновлён');
    return path;
  }

  @override
  Future<bool> isDarkTheme() async {
    final user = await getUser();
    return user.darkTheme;
  }

  @override
  Future<void> setDarkTheme(bool value) async {
    final db = await _database.database;
    await db.update(
      'users',
      {'dark_theme': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [1],
    );
    _logger.info('User: тема ${value ? 'тёмная' : 'светлая'}');
  }

  @override
  Future<ProfileStats> stats() async {
    final db = await _database.database;
    final user = await getUser();
    final total = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM predictions'),
        ) ??
        0;
    final correct = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM predictions WHERE status = 'correct'",
          ),
        ) ??
        0;
    final incorrect = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM predictions WHERE status = 'incorrect'",
          ),
        ) ??
        0;
    return ProfileStats(
      total: total,
      correct: correct,
      incorrect: incorrect,
      points: user.points,
    );
  }
}
