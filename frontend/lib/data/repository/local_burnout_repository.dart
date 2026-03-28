import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../local/app_database.dart';
import '../models/app_alert.dart';
import '../models/breathing_session.dart';
import '../models/burnout_score.dart';
import '../models/burnout_task.dart';
import '../models/daily_entry.dart';
import '../models/pomodoro_session.dart';
import 'burnout_repository.dart';

class LocalBurnoutRepository implements BurnoutRepository {
  LocalBurnoutRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<Database> get _db async => _database.database;

  @override
  Future<void> saveDailyEntry(DailyEntry entry) async {
    final db = await _db;
    await db.insert(DbTables.dailyEntries, entry.toMap());
  }

  @override
  Future<BurnoutScore?> getLatestScore() async {
    final db = await _db;
    final rows = await db.query(
      DbTables.burnoutScores,
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BurnoutScore.fromMap(rows.first);
  }

  @override
  Future<List<BurnoutScore>> getScoresByRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db;
    final fromKey = AppDateUtils.dateKeyUtc(from);
    final toKey = AppDateUtils.dateKeyUtc(to);
    final rows = await db.query(
      DbTables.burnoutScores,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [fromKey, toKey],
      orderBy: 'date ASC, created_at ASC',
    );
    return rows.map(BurnoutScore.fromMap).toList();
  }

  @override
  Future<List<BurnoutTask>> getTasksByDate(DateTime date) async {
    final db = await _db;
    final key = AppDateUtils.dateKeyUtc(date);
    final rows = await db.query(
      DbTables.tasks,
      where: 'date = ?',
      whereArgs: [key],
      orderBy: 'completed ASC, priority DESC, created_at DESC',
    );
    return rows.map(BurnoutTask.fromMap).toList();
  }

  @override
  Future<void> upsertTask(BurnoutTask task) async {
    final db = await _db;
    await db.insert(
      DbTables.tasks,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> completeTask(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      final taskRows = await txn.query(
        DbTables.tasks,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (taskRows.isEmpty) return;

      final task = BurnoutTask.fromMap(taskRows.first);
      if (task.completed) return;

      await txn.update(
        DbTables.tasks,
        {'completed': 1, 'synced': 0},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (task.taskType != 'recovery') {
        return;
      }

      final latestScoreRows = await txn.query(
        DbTables.burnoutScores,
        orderBy: 'created_at DESC',
        limit: 1,
      );
      if (latestScoreRows.isEmpty) {
        return;
      }
      final latestScore = BurnoutScore.fromMap(latestScoreRows.first);

      final impact =
          AppConstants.recoveryImpactByTaskType[task.reason ?? ''] ??
          AppConstants.recoveryImpactByTaskType['general_recovery']!;
      final nextScore = (latestScore.score - impact).clamp(0, 100);
      final nextClassification = _classify(nextScore);
      final snapshotId = _uuid.v4();
      final now = AppDateUtils.nowUtc();

      await txn.insert(DbTables.burnoutScores, {
        'id': snapshotId,
        'date': latestScore.date,
        'score': nextScore,
        'classification': nextClassification,
        'created_at': AppDateUtils.toUtcIso(now),
        'synced': 0,
      });

      await txn.insert(DbTables.scoreLogs, {
        'id': _uuid.v4(),
        'score_id': snapshotId,
        'change_amount': -impact,
        'reason': 'Completed recovery task: ${task.title}',
        'created_at': AppDateUtils.toUtcIso(now),
        'synced': 0,
      });
    });
  }

  @override
  Future<void> logScoreChange({
    required String scoreId,
    required int changeAmount,
    required String reason,
  }) async {
    final db = await _db;
    await db.insert(DbTables.scoreLogs, {
      'id': _uuid.v4(),
      'score_id': scoreId,
      'change_amount': changeAmount,
      'reason': reason,
      'created_at': AppDateUtils.toUtcIso(AppDateUtils.nowUtc()),
      'synced': 0,
    });
  }

  @override
  Future<void> insertAlert(AppAlert alert) async {
    final db = await _db;
    await db.insert(DbTables.alerts, alert.toMap());
  }

  @override
  Future<String> startPomodoro({
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    final db = await _db;
    final id = _uuid.v4();
    final now = AppDateUtils.nowUtc();
    await db.insert(DbTables.pomodoroSessions, {
      'id': id,
      'start_time': AppDateUtils.toUtcIso(startTime),
      'end_time': null,
      'duration': durationMinutes,
      'completed': 0,
      'created_at': AppDateUtils.toUtcIso(now),
      'synced': 0,
    });
    return id;
  }

  @override
  Future<void> endPomodoro({
    required String id,
    required DateTime endTime,
    required bool completed,
  }) async {
    final db = await _db;
    await db.update(
      DbTables.pomodoroSessions,
      {
        'end_time': AppDateUtils.toUtcIso(endTime),
        'completed': completed ? 1 : 0,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<String> startBreathing({
    required DateTime startedAt,
    required int durationMinutes,
  }) async {
    final db = await _db;
    final id = _uuid.v4();
    final now = AppDateUtils.nowUtc();
    await db.insert(DbTables.breathingSessions, {
      'id': id,
      'started_at': AppDateUtils.toUtcIso(startedAt),
      'duration': durationMinutes,
      'completed': 0,
      'created_at': AppDateUtils.toUtcIso(now),
      'synced': 0,
    });
    return id;
  }

  @override
  Future<void> endBreathing({
    required String id,
    required bool completed,
  }) async {
    final db = await _db;
    await db.update(
      DbTables.breathingSessions,
      {'completed': completed ? 1 : 0, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<DailyEntry?> getLatestDailyEntryForDate(DateTime date) async {
    final db = await _db;
    final rows = await db.query(
      DbTables.dailyEntries,
      where: 'date = ?',
      whereArgs: [AppDateUtils.dateKeyUtc(date)],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyEntry.fromMap(rows.first);
  }

  @override
  Future<String> insertScoreSnapshot({
    required DateTime date,
    required int score,
    required String classification,
    required List<String> causes,
  }) async {
    final db = await _db;
    final scoreId = _uuid.v4();
    final now = AppDateUtils.nowUtc();

    await db.transaction((txn) async {
      await txn.insert(DbTables.burnoutScores, {
        'id': scoreId,
        'date': AppDateUtils.dateKeyUtc(date),
        'score': score,
        'classification': classification,
        'created_at': AppDateUtils.toUtcIso(now),
        'synced': 0,
      });

      for (final cause in causes) {
        await txn.insert(DbTables.burnoutCauses, {
          'id': _uuid.v4(),
          'score_id': scoreId,
          'cause_type': cause,
          'created_at': AppDateUtils.toUtcIso(now),
          'synced': 0,
        });
      }
    });

    return scoreId;
  }

  @override
  Future<List<String>> getCausesByScoreId(String scoreId) async {
    final db = await _db;
    final rows = await db.query(
      DbTables.burnoutCauses,
      columns: ['cause_type'],
      where: 'score_id = ?',
      whereArgs: [scoreId],
    );
    return rows.map((e) => e['cause_type'] as String).toList();
  }

  @override
  Future<List<AppAlert>> getAlerts({int limit = 30}) async {
    final db = await _db;
    final rows = await db.query(
      DbTables.alerts,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(AppAlert.fromMap).toList();
  }

  @override
  Future<List<PomodoroSession>> getPomodoroByDate(DateTime date) async {
    final db = await _db;
    final start = AppDateUtils.dateKeyToUtcStart(AppDateUtils.dateKeyUtc(date));
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      DbTables.pomodoroSessions,
      where: 'start_time >= ? AND start_time < ?',
      whereArgs: [AppDateUtils.toUtcIso(start), AppDateUtils.toUtcIso(end)],
      orderBy: 'start_time DESC',
    );
    return rows.map(PomodoroSession.fromMap).toList();
  }

  @override
  Future<List<BreathingSession>> getBreathingByDate(DateTime date) async {
    final db = await _db;
    final start = AppDateUtils.dateKeyToUtcStart(AppDateUtils.dateKeyUtc(date));
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      DbTables.breathingSessions,
      where: 'started_at >= ? AND started_at < ?',
      whereArgs: [AppDateUtils.toUtcIso(start), AppDateUtils.toUtcIso(end)],
      orderBy: 'started_at DESC',
    );
    return rows.map(BreathingSession.fromMap).toList();
  }

  String _classify(int score) {
    if (score <= AppConstants.lowMax) return 'low';
    if (score <= AppConstants.mediumMax) return 'medium';
    return 'high';
  }
}
