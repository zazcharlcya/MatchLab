import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'app_logger.dart';

class DatabaseService {
  DatabaseService({required AppLog logger}) : _logger = logger;

  final AppLog _logger;
  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) {
      return existing;
    }
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'matchlab.db');
    _logger.info('DB: открытие $path');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE matches (
            id TEXT PRIMARY KEY,
            home_team TEXT NOT NULL,
            away_team TEXT NOT NULL,
            home_team_id TEXT,
            away_team_id TEXT,
            league TEXT NOT NULL,
            kickoff_utc TEXT NOT NULL,
            status TEXT NOT NULL,
            home_score INTEGER,
            away_score INTEGER,
            home_badge TEXT,
            away_badge TEXT,
            venue TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE predictions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            match_id TEXT NOT NULL UNIQUE,
            chosen_outcome TEXT NOT NULL,
            actual_outcome TEXT,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL,
            points_awarded INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            avatar_path TEXT,
            points INTEGER NOT NULL DEFAULT 0,
            dark_theme INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN dark_theme INTEGER NOT NULL DEFAULT 1',
          );
        }
      },
    );
  }
}
