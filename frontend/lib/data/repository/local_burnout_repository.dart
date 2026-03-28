import 'package:drift/drift.dart' as drift;
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

  @override
  Future<void> saveDailyEntry(DailyEntry entry) async {
    await _database
        .into(_database.dailyEntries)
        .insert(
          DailyEntriesCompanion.insert(
            id: entry.id,
            date: entry.date,
            sleepHours: entry.sleepHours,
            workHours: entry.workHours,
            mood: entry.mood,
            wasOk: entry.wasOk,
            createdAt: drift.Value(entry.createdAt.toUtc()),
            synced: drift.Value(entry.synced),
          ),
        );
  }

  @override
  Future<BurnoutScore?> getLatestScore() async {
    final row =
        await (_database.select(_database.burnoutScores)
              ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();

    return row == null ? null : _toBurnoutScore(row);
  }

  @override
  Future<List<BurnoutScore>> getScoresByRange(
    DateTime from,
    DateTime to,
  ) async {
    final fromKey = AppDateUtils.dateKeyUtc(from);
    final toKey = AppDateUtils.dateKeyUtc(to);

    final rows =
        await (_database.select(_database.burnoutScores)
              ..where((t) => t.date.isBetweenValues(fromKey, toKey))
              ..orderBy([
                (t) => drift.OrderingTerm.asc(t.date),
                (t) => drift.OrderingTerm.asc(t.createdAt),
              ]))
            .get();

    return rows.map(_toBurnoutScore).toList();
  }

  @override
  Future<List<BurnoutTask>> getTasksByDate(DateTime date) async {
    final key = AppDateUtils.dateKeyUtc(date);
    final rows =
        await (_database.select(_database.tasks)
              ..where((t) => t.date.equals(key))
              ..orderBy([
                (t) => drift.OrderingTerm.asc(t.completed),
                (t) => drift.OrderingTerm.desc(t.priority),
                (t) => drift.OrderingTerm.desc(t.createdAt),
              ]))
            .get();

    return rows.map(_toBurnoutTask).toList();
  }

  @override
  Future<void> upsertTask(BurnoutTask task) async {
    await _database
        .into(_database.tasks)
        .insertOnConflictUpdate(
          TasksCompanion(
            id: drift.Value(task.id),
            date: drift.Value(task.date),
            title: drift.Value(task.title),
            deadline: drift.Value(task.deadline?.toUtc()),
            priority: drift.Value(task.priority),
            completed: drift.Value(task.completed),
            taskType: drift.Value(task.taskType),
            reason: drift.Value(task.reason),
            createdAt: drift.Value(task.createdAt.toUtc()),
            synced: drift.Value(task.synced),
          ),
        );
  }

  @override
  Future<void> completeTask(String id) async {
    await _database.transaction(() async {
      final taskRow =
          await (_database.select(_database.tasks)
                ..where((t) => t.id.equals(id))
                ..limit(1))
              .getSingleOrNull();
      if (taskRow == null || taskRow.completed) {
        return;
      }

      await (_database.update(
        _database.tasks,
      )..where((t) => t.id.equals(id))).write(
        const TasksCompanion(
          completed: drift.Value(true),
          synced: drift.Value(false),
        ),
      );

      if (taskRow.taskType != 'recovery') {
        return;
      }

      final latestScoreRow =
          await (_database.select(_database.burnoutScores)
                ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
                ..limit(1))
              .getSingleOrNull();

      if (latestScoreRow == null) {
        return;
      }

      final impact =
          AppConstants.recoveryImpactByTaskType[taskRow.reason ?? ''] ??
          AppConstants.recoveryImpactByTaskType['general_recovery']!;
      final nextScore = (latestScoreRow.score - impact).clamp(0, 100);
      final nextClassification = _classify(nextScore);
      final snapshotId = _uuid.v4();
      final now = AppDateUtils.nowUtc();

      await _database
          .into(_database.burnoutScores)
          .insert(
            BurnoutScoresCompanion.insert(
              id: snapshotId,
              date: latestScoreRow.date,
              score: nextScore,
              classification: nextClassification,
              createdAt: drift.Value(now),
              synced: const drift.Value(false),
            ),
          );

      await _database
          .into(_database.scoreLogs)
          .insert(
            ScoreLogsCompanion.insert(
              id: _uuid.v4(),
              scoreId: snapshotId,
              changeAmount: -impact,
              reason: 'Completed recovery task: ${taskRow.title}',
              createdAt: drift.Value(now),
              synced: const drift.Value(false),
            ),
          );
    });
  }

  @override
  Future<void> logScoreChange({
    required String scoreId,
    required int changeAmount,
    required String reason,
  }) async {
    await _database
        .into(_database.scoreLogs)
        .insert(
          ScoreLogsCompanion.insert(
            id: _uuid.v4(),
            scoreId: scoreId,
            changeAmount: changeAmount,
            reason: reason,
            createdAt: drift.Value(AppDateUtils.nowUtc()),
            synced: const drift.Value(false),
          ),
        );
  }

  @override
  Future<void> insertAlert(AppAlert alert) async {
    await _database
        .into(_database.alerts)
        .insert(
          AlertsCompanion.insert(
            id: alert.id,
            date: alert.date,
            type: alert.type,
            message: alert.message,
            createdAt: drift.Value(alert.createdAt.toUtc()),
            synced: drift.Value(alert.synced),
          ),
        );
  }

  @override
  Future<String> startPomodoro({
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    final id = _uuid.v4();
    final now = AppDateUtils.nowUtc();

    await _database
        .into(_database.pomodoroSessions)
        .insert(
          PomodoroSessionsCompanion.insert(
            id: id,
            startTime: startTime.toUtc(),
            duration: drift.Value(durationMinutes),
            completed: const drift.Value(false),
            createdAt: drift.Value(now),
            synced: const drift.Value(false),
          ),
        );

    return id;
  }

  @override
  Future<void> endPomodoro({
    required String id,
    required DateTime endTime,
    required bool completed,
  }) async {
    await (_database.update(
      _database.pomodoroSessions,
    )..where((t) => t.id.equals(id))).write(
      PomodoroSessionsCompanion(
        endTime: drift.Value(endTime.toUtc()),
        completed: drift.Value(completed),
        synced: const drift.Value(false),
      ),
    );
  }

  @override
  Future<String> startBreathing({
    required DateTime startedAt,
    required int durationMinutes,
  }) async {
    final id = _uuid.v4();
    final now = AppDateUtils.nowUtc();

    await _database
        .into(_database.breathingSessions)
        .insert(
          BreathingSessionsCompanion.insert(
            id: id,
            startedAt: startedAt.toUtc(),
            duration: durationMinutes,
            completed: false,
            createdAt: drift.Value(now),
            synced: const drift.Value(false),
          ),
        );

    return id;
  }

  @override
  Future<void> endBreathing({
    required String id,
    required bool completed,
  }) async {
    await (_database.update(
      _database.breathingSessions,
    )..where((t) => t.id.equals(id))).write(
      BreathingSessionsCompanion(
        completed: drift.Value(completed),
        synced: const drift.Value(false),
      ),
    );
  }

  @override
  Future<DailyEntry?> getLatestDailyEntryForDate(DateTime date) async {
    final key = AppDateUtils.dateKeyUtc(date);

    final row =
        await (_database.select(_database.dailyEntries)
              ..where((t) => t.date.equals(key))
              ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();

    return row == null ? null : _toDailyEntry(row);
  }

  @override
  Future<String> insertScoreSnapshot({
    required DateTime date,
    required int score,
    required String classification,
    required List<String> causes,
  }) async {
    final scoreId = _uuid.v4();
    final now = AppDateUtils.nowUtc();

    await _database.transaction(() async {
      await _database
          .into(_database.burnoutScores)
          .insert(
            BurnoutScoresCompanion.insert(
              id: scoreId,
              date: AppDateUtils.dateKeyUtc(date),
              score: score,
              classification: classification,
              createdAt: drift.Value(now),
              synced: const drift.Value(false),
            ),
          );

      for (final cause in causes) {
        await _database
            .into(_database.burnoutCauses)
            .insert(
              BurnoutCausesCompanion.insert(
                id: _uuid.v4(),
                scoreId: scoreId,
                causeType: cause,
                createdAt: drift.Value(now),
                synced: const drift.Value(false),
              ),
            );
      }
    });

    return scoreId;
  }

  @override
  Future<List<String>> getCausesByScoreId(String scoreId) async {
    final rows = await (_database.select(
      _database.burnoutCauses,
    )..where((t) => t.scoreId.equals(scoreId))).get();

    return rows.map((e) => e.causeType).toList();
  }

  @override
  Future<List<AppAlert>> getAlerts({int limit = 30}) async {
    final rows =
        await (_database.select(_database.alerts)
              ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
              ..limit(limit))
            .get();

    return rows.map(_toAlert).toList();
  }

  @override
  Future<List<PomodoroSession>> getPomodoroByDate(DateTime date) async {
    final start = AppDateUtils.dateKeyToUtcStart(AppDateUtils.dateKeyUtc(date));
    final end = start.add(const Duration(days: 1));

    final rows =
        await (_database.select(_database.pomodoroSessions)
              ..where(
                (t) =>
                    t.startTime.isBiggerOrEqualValue(start) &
                    t.startTime.isSmallerThanValue(end),
              )
              ..orderBy([(t) => drift.OrderingTerm.desc(t.startTime)]))
            .get();

    return rows.map(_toPomodoroSession).toList();
  }

  @override
  Future<List<BreathingSession>> getBreathingByDate(DateTime date) async {
    final start = AppDateUtils.dateKeyToUtcStart(AppDateUtils.dateKeyUtc(date));
    final end = start.add(const Duration(days: 1));

    final rows =
        await (_database.select(_database.breathingSessions)
              ..where(
                (t) =>
                    t.startedAt.isBiggerOrEqualValue(start) &
                    t.startedAt.isSmallerThanValue(end),
              )
              ..orderBy([(t) => drift.OrderingTerm.desc(t.startedAt)]))
            .get();

    return rows.map(_toBreathingSession).toList();
  }

  BurnoutScore _toBurnoutScore(BurnoutScoreRow row) {
    return BurnoutScore(
      id: row.id,
      date: row.date,
      score: row.score,
      classification: row.classification,
      createdAt: row.createdAt.toUtc(),
      synced: row.synced,
    );
  }

  DailyEntry _toDailyEntry(DailyEntryRow row) {
    return DailyEntry(
      id: row.id,
      date: row.date,
      sleepHours: row.sleepHours,
      workHours: row.workHours,
      mood: row.mood,
      wasOk: row.wasOk,
      createdAt: row.createdAt.toUtc(),
      synced: row.synced,
    );
  }

  BurnoutTask _toBurnoutTask(TaskRow row) {
    return BurnoutTask(
      id: row.id,
      date: row.date,
      title: row.title,
      deadline: row.deadline?.toUtc(),
      priority: row.priority,
      completed: row.completed,
      taskType: row.taskType,
      createdAt: row.createdAt.toUtc(),
      synced: row.synced,
      reason: row.reason,
    );
  }

  AppAlert _toAlert(AlertRow row) {
    return AppAlert(
      id: row.id,
      date: row.date,
      type: row.type,
      message: row.message,
      createdAt: row.createdAt.toUtc(),
      synced: row.synced,
    );
  }

  PomodoroSession _toPomodoroSession(PomodoroSessionRow row) {
    return PomodoroSession(
      id: row.id,
      startTime: row.startTime.toUtc(),
      endTime: row.endTime?.toUtc(),
      duration: row.duration ?? 0,
      completed: row.completed ?? false,
      createdAt: row.createdAt.toUtc(),
      synced: row.synced,
    );
  }

  BreathingSession _toBreathingSession(BreathingSessionRow row) {
    return BreathingSession(
      id: row.id,
      startedAt: row.startedAt.toUtc(),
      duration: row.duration,
      completed: row.completed,
      createdAt: row.createdAt.toUtc(),
      synced: row.synced,
    );
  }

  String _classify(int score) {
    if (score <= AppConstants.lowMax) return 'low';
    if (score <= AppConstants.mediumMax) return 'medium';
    return 'high';
  }
}
