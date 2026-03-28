import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'burnout_radar.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbTables.userProfile} (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        avatar TEXT NOT NULL,
        timezone TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1))
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.dailyEntries} (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        sleep_hours REAL,
        work_hours REAL,
        mood INTEGER CHECK (mood BETWEEN 1 AND 5),
        was_ok INTEGER CHECK (was_ok IN (0,1)),
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1))
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.burnoutScores} (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        score INTEGER CHECK (score BETWEEN 0 AND 100),
        classification TEXT CHECK (classification IN ('low','medium','high')),
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1))
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.burnoutCauses} (
        id TEXT PRIMARY KEY,
        score_id TEXT NOT NULL,
        cause_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1)),
        FOREIGN KEY(score_id) REFERENCES ${DbTables.burnoutScores}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.tasks} (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        title TEXT NOT NULL,
        deadline TEXT,
        priority INTEGER,
        completed INTEGER NOT NULL DEFAULT 0 CHECK (completed IN (0,1)),
        task_type TEXT CHECK (task_type IN ('user','recovery')),
        reason TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1))
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.scoreLogs} (
        id TEXT PRIMARY KEY,
        score_id TEXT NOT NULL,
        change_amount INTEGER NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1)),
        FOREIGN KEY(score_id) REFERENCES ${DbTables.burnoutScores}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.pomodoroSessions} (
        id TEXT PRIMARY KEY,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration INTEGER,
        completed INTEGER CHECK (completed IN (0,1)),
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1))
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.breathingSessions} (
        id TEXT PRIMARY KEY,
        started_at TEXT,
        duration INTEGER,
        completed INTEGER CHECK (completed IN (0,1)),
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1))
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.alerts} (
        id TEXT PRIMARY KEY,
        date TEXT,
        type TEXT,
        message TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1))
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_daily_entries_date ON ${DbTables.dailyEntries}(date)',
    );
    await db.execute(
      'CREATE INDEX idx_burnout_scores_date ON ${DbTables.burnoutScores}(date)',
    );
    await db.execute(
      'CREATE INDEX idx_burnout_scores_created ON ${DbTables.burnoutScores}(created_at)',
    );
    await db.execute('CREATE INDEX idx_tasks_date ON ${DbTables.tasks}(date)');
    await db.execute(
      'CREATE INDEX idx_tasks_type ON ${DbTables.tasks}(task_type)',
    );
    await db.execute(
      'CREATE INDEX idx_pomodoro_start ON ${DbTables.pomodoroSessions}(start_time)',
    );
  }
}
