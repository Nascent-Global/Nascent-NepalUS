import 'package:drift/drift.dart' as drift;

import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../data/local/app_database.dart';
import '../../data/remote/api_paths.dart';
import '../../data/remote/auth_models.dart';
import '../../data/remote/burnout_sync_api_client.dart';

class SyncReport {
  const SyncReport({required this.pushedRows, required this.pulledRows});

  final int pushedRows;
  final int pulledRows;

  bool get hasChanges => pushedRows > 0 || pulledRows > 0;
}

class SyncService {
  SyncService({
    required AppDatabase database,
    required BurnoutSyncApiClient apiClient,
  }) : _database = database,
       _apiClient = apiClient;

  static const int _pageSize = 100;
  static const int _maxTaskDatesToPull = 30;

  final AppDatabase _database;
  final BurnoutSyncApiClient _apiClient;

  bool _isRunning = false;

  Future<SyncReport> syncNow({required AuthSession session}) async {
    if (_isRunning) {
      return const SyncReport(pushedRows: 0, pulledRows: 0);
    }

    _isRunning = true;
    try {
      final pushed = await _pushLocalChanges(session);
      final pulled = await _pullRemoteChanges(session);
      return SyncReport(pushedRows: pushed, pulledRows: pulled);
    } finally {
      _isRunning = false;
    }
  }

  Future<int> _pushLocalChanges(AuthSession session) async {
    var pushed = 0;

    pushed += await _pushProfile(session);
    pushed += await _pushDailyEntries(session);
    pushed += await _pushBurnoutScores(session);
    pushed += await _pushBurnoutCauses(session);
    pushed += await _pushTasks(session);
    pushed += await _pushScoreLogs(session);
    pushed += await _pushPomodoroSessions(session);
    pushed += await _pushBreathingSessions(session);
    pushed += await _pushAlerts(session);

    return pushed;
  }

  Future<int> _pullRemoteChanges(AuthSession session) async {
    var pulled = 0;

    pulled += await _pullProfile(session);
    pulled += await _pullDailyEntries(session);
    pulled += await _pullBurnoutScoresAndCauses(session);
    pulled += await _pullTasks(session);
    pulled += await _pullPomodoroSessions(session);
    pulled += await _pullBreathingSessions(session);
    pulled += await _pullAlerts(session);

    return pulled;
  }

  Future<int> _pushProfile(AuthSession session) async {
    final existing =
        await (_database.select(_database.userProfiles)
              ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();

    if (existing != null && existing.synced) {
      return 0;
    }

    final username = existing?.username ?? session.user.username;
    final timezone = existing?.timezone ?? session.user.timezone;
    final avatar = existing?.avatar.isNotEmpty == true
        ? existing!.avatar
        : 'avatar_1';

    final data = await _apiClient.request(
      method: 'PUT',
      path: ApiPaths.userProfile,
      token: session.token,
      body: {'username': username, 'avatar': avatar, 'timezone': timezone},
    );

    if (data is! Map<String, dynamic>) return 0;

    final createdAt =
        _parseDateTime(data['created_at']) ?? AppDateUtils.nowUtc();
    await _database
        .into(_database.userProfiles)
        .insertOnConflictUpdate(
          UserProfilesCompanion(
            id: drift.Value(
              (data['id'] as String?) ?? (existing?.id ?? session.user.id),
            ),
            username: drift.Value((data['username'] as String?) ?? username),
            avatar: drift.Value((data['avatar'] as String?) ?? avatar),
            timezone: drift.Value((data['timezone'] as String?) ?? timezone),
            createdAt: drift.Value(createdAt),
            synced: const drift.Value(true),
          ),
        );
    return 1;
  }

  Future<int> _pushDailyEntries(AuthSession session) async {
    final rows =
        await (_database.select(_database.dailyEntries)
              ..where((t) => t.synced.equals(false))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
            .get();

    var pushed = 0;
    for (final row in rows) {
      try {
        await _apiClient.request(
          method: 'POST',
          path: ApiPaths.dailyEntries,
          token: session.token,
          body: {
            'id': row.id,
            'date': row.date,
            'sleep_hours': row.sleepHours,
            'work_hours': row.workHours,
            'mood': row.mood,
            'exercise_minutes': row.exerciseMinutes,
            'include_pomodoro_work': row.includePomodoroWork,
            // Backward compatibility for older backend schema.
            'was_ok': row.mood >= 3,
          },
        );
      } on SyncApiException catch (error) {
        if (!error.isConflict) {
          rethrow;
        }
      }

      await _markSynced(DbTables.dailyEntries, row.id);
      pushed++;
    }
    return pushed;
  }

  Future<int> _pushBurnoutScores(AuthSession session) async {
    final rows =
        await (_database.select(_database.burnoutScores)
              ..where((t) => t.synced.equals(false))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
            .get();

    var pushed = 0;
    for (final row in rows) {
      try {
        await _apiClient.request(
          method: 'POST',
          path: ApiPaths.burnoutScores,
          token: session.token,
          body: {
            'id': row.id,
            'date': row.date,
            'score': row.score,
            'classification': row.classification,
          },
        );
      } on SyncApiException catch (error) {
        if (!error.isConflict) {
          rethrow;
        }
      }

      await _markSynced(DbTables.burnoutScores, row.id);
      pushed++;
    }
    return pushed;
  }

  Future<int> _pushBurnoutCauses(AuthSession session) async {
    final rows =
        await (_database.select(_database.burnoutCauses)
              ..where((t) => t.synced.equals(false))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
            .get();
    if (rows.isEmpty) return 0;

    final grouped = <String, List<BurnoutCauseRow>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.scoreId, () => <BurnoutCauseRow>[]).add(row);
    }

    var pushed = 0;
    for (final entry in grouped.entries) {
      final scoreId = entry.key;
      final backendCauses = entry.value
          .map((row) => _toBackendCauseType(row.causeType))
          .toSet()
          .toList();

      try {
        await _apiClient.request(
          method: 'POST',
          path: ApiPaths.burnoutCauses,
          token: session.token,
          body: {'score_id': scoreId, 'causes': backendCauses},
        );
      } on SyncApiException catch (error) {
        if (!error.isConflict) {
          rethrow;
        }
      }

      for (final row in entry.value) {
        await _markSynced(DbTables.burnoutCauses, row.id);
        pushed++;
      }
    }
    return pushed;
  }

  Future<int> _pushTasks(AuthSession session) async {
    final rows =
        await (_database.select(_database.tasks)
              ..where((t) => t.synced.equals(false))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
            .get();

    var pushed = 0;
    for (final row in rows) {
      try {
        await _apiClient.request(
          method: 'POST',
          path: ApiPaths.tasks,
          token: session.token,
          body: {
            'id': row.id,
            'date': row.date,
            'title': row.title,
            'deadline': row.deadline?.toUtc().toIso8601String(),
            'priority': row.priority,
            'completed': row.completed,
            'task_type': row.taskType,
          },
        );
      } on SyncApiException catch (error) {
        if (!error.isConflict) {
          rethrow;
        }

        await _apiClient.request(
          method: 'PATCH',
          path: ApiPaths.taskById(row.id),
          token: session.token,
          body: {
            'date': row.date,
            'title': row.title,
            'deadline': row.deadline?.toUtc().toIso8601String(),
            'priority': row.priority,
            'completed': row.completed,
            'task_type': row.taskType,
          },
        );
      }

      await _markSynced(DbTables.tasks, row.id);
      pushed++;
    }
    return pushed;
  }

  Future<int> _pushScoreLogs(AuthSession session) async {
    final rows =
        await (_database.select(_database.scoreLogs)
              ..where((t) => t.synced.equals(false))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
            .get();

    var pushed = 0;
    for (final row in rows) {
      try {
        await _apiClient.request(
          method: 'POST',
          path: ApiPaths.scoreLogs,
          token: session.token,
          body: {
            'id': row.id,
            'score_id': row.scoreId,
            'change_amount': row.changeAmount,
            'reason': row.reason,
          },
        );
      } on SyncApiException catch (error) {
        if (!error.isConflict) {
          rethrow;
        }
      }

      await _markSynced(DbTables.scoreLogs, row.id);
      pushed++;
    }
    return pushed;
  }

  Future<int> _pushPomodoroSessions(AuthSession session) async {
    final rows =
        await (_database.select(_database.pomodoroSessions)
              ..where((t) => t.synced.equals(false))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
            .get();

    var pushed = 0;
    for (final row in rows) {
      try {
        await _apiClient.request(
          method: 'POST',
          path: ApiPaths.pomodoroSessions,
          token: session.token,
          body: {
            'id': row.id,
            'start_time': row.startTime.toUtc().toIso8601String(),
            'end_time': row.endTime?.toUtc().toIso8601String(),
            'duration': row.duration,
            'completed': row.completed,
            'task_label': row.taskLabel,
          },
        );
      } on SyncApiException catch (error) {
        if (!error.isConflict) {
          rethrow;
        }

        await _apiClient.request(
          method: 'PATCH',
          path: ApiPaths.pomodoroSessionById(row.id),
          token: session.token,
          body: {
            'end_time': row.endTime?.toUtc().toIso8601String(),
            'duration': row.duration,
            'completed': row.completed,
            'task_label': row.taskLabel,
          },
        );
      }

      await _markSynced(DbTables.pomodoroSessions, row.id);
      pushed++;
    }
    return pushed;
  }

  Future<int> _pushBreathingSessions(AuthSession session) async {
    final rows =
        await (_database.select(_database.breathingSessions)
              ..where((t) => t.synced.equals(false))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
            .get();

    var pushed = 0;
    for (final row in rows) {
      try {
        await _apiClient.request(
          method: 'POST',
          path: ApiPaths.breathingSessions,
          token: session.token,
          body: {
            'id': row.id,
            'started_at': row.startedAt.toUtc().toIso8601String(),
            'duration': row.duration,
            'completed': row.completed,
          },
        );
      } on SyncApiException catch (error) {
        if (!error.isConflict) {
          rethrow;
        }

        await _apiClient.request(
          method: 'PATCH',
          path: ApiPaths.breathingSessionById(row.id),
          token: session.token,
          body: {'duration': row.duration, 'completed': row.completed},
        );
      }

      await _markSynced(DbTables.breathingSessions, row.id);
      pushed++;
    }
    return pushed;
  }

  Future<int> _pushAlerts(AuthSession session) async {
    final rows =
        await (_database.select(_database.alerts)
              ..where((t) => t.synced.equals(false))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
            .get();

    var pushed = 0;
    for (final row in rows) {
      try {
        await _apiClient.request(
          method: 'POST',
          path: ApiPaths.alerts,
          token: session.token,
          body: {
            'id': row.id,
            'date': row.date,
            'type': _toBackendAlertType(row.type),
            'message': row.message,
          },
        );
      } on SyncApiException catch (error) {
        if (!error.isConflict) {
          rethrow;
        }
      }

      await _markSynced(DbTables.alerts, row.id);
      pushed++;
    }
    return pushed;
  }

  Future<int> _pullProfile(AuthSession session) async {
    Map<String, dynamic>? profile;
    try {
      profile = await _apiClient.getObject(
        path: ApiPaths.userProfile,
        token: session.token,
      );
    } on SyncApiException catch (error) {
      if (!error.isNotFound) {
        rethrow;
      }
    }

    if (profile == null) return 0;

    final createdAt =
        _parseDateTime(profile['created_at']) ?? AppDateUtils.nowUtc();
    final profileId = (profile['id'] as String?) ?? session.user.id;
    final existed = await _rowExists(DbTables.userProfile, profileId);
    await _database
        .into(_database.userProfiles)
        .insertOnConflictUpdate(
          UserProfilesCompanion(
            id: drift.Value(profileId),
            username: drift.Value(
              (profile['username'] as String?) ?? session.user.username,
            ),
            avatar: drift.Value((profile['avatar'] as String?) ?? 'avatar_1'),
            timezone: drift.Value(
              (profile['timezone'] as String?) ?? session.user.timezone,
            ),
            createdAt: drift.Value(createdAt),
            synced: const drift.Value(true),
          ),
        );
    return existed ? 0 : 1;
  }

  Future<int> _pullDailyEntries(AuthSession session) async {
    final rows = await _fetchPagedRange(
      path: ApiPaths.dailyEntries,
      token: session.token,
    );

    var inserted = 0;
    for (final item in rows) {
      final id = item['id'] as String?;
      final date = item['date'] as String?;
      if (id == null || date == null) continue;
      if (!await _rowExists(DbTables.dailyEntries, id)) {
        inserted++;
      }

      await _database
          .into(_database.dailyEntries)
          .insertOnConflictUpdate(
            DailyEntriesCompanion(
              id: drift.Value(id),
              date: drift.Value(date),
              sleepHours: drift.Value(_toDouble(item['sleep_hours'])),
              workHours: drift.Value(_toDouble(item['work_hours'])),
              mood: drift.Value(_toInt(item['mood'], fallback: 3)),
              exerciseMinutes: drift.Value(
                _toInt(item['exercise_minutes'], fallback: 0),
              ),
              includePomodoroWork: drift.Value(
                _toBool(item['include_pomodoro_work']),
              ),
              createdAt: drift.Value(
                _parseDateTime(item['created_at']) ?? AppDateUtils.nowUtc(),
              ),
              synced: const drift.Value(true),
            ),
          );
    }

    return inserted;
  }

  Future<int> _pullBurnoutScoresAndCauses(AuthSession session) async {
    final rows = await _fetchPagedRange(
      path: ApiPaths.burnoutScores,
      token: session.token,
    );

    var inserted = 0;
    var insertedCauses = 0;
    for (final item in rows) {
      final id = item['id'] as String?;
      final date = item['date'] as String?;
      if (id == null || date == null) continue;
      if (!await _rowExists(DbTables.burnoutScores, id)) {
        inserted++;
      }

      await _database
          .into(_database.burnoutScores)
          .insertOnConflictUpdate(
            BurnoutScoresCompanion(
              id: drift.Value(id),
              date: drift.Value(date),
              score: drift.Value(_toInt(item['score'])),
              classification: drift.Value(
                (item['classification'] as String?) ?? 'medium',
              ),
              createdAt: drift.Value(
                _parseDateTime(item['created_at']) ?? AppDateUtils.nowUtc(),
              ),
              synced: const drift.Value(true),
            ),
          );

      final causes = item['causes'];
      if (causes is! List) continue;
      for (final raw in causes.whereType<Map<String, dynamic>>()) {
        final causeId = raw['id'] as String?;
        final causeType = raw['cause_type'] as String?;
        if (causeId == null || causeType == null) continue;
        if (!await _rowExists(DbTables.burnoutCauses, causeId)) {
          insertedCauses++;
        }

        await _database
            .into(_database.burnoutCauses)
            .insertOnConflictUpdate(
              BurnoutCausesCompanion(
                id: drift.Value(causeId),
                scoreId: drift.Value(id),
                causeType: drift.Value(causeType),
                createdAt: drift.Value(
                  _parseDateTime(raw['created_at']) ?? AppDateUtils.nowUtc(),
                ),
                synced: const drift.Value(true),
              ),
            );
      }
    }

    return inserted + insertedCauses;
  }

  Future<int> _pullTasks(AuthSession session) async {
    final today = DateTime.now().toUtc();
    final dateKeys = <String>{
      AppDateUtils.dateKeyUtc(today),
      AppDateUtils.dateKeyUtc(today.subtract(const Duration(days: 1))),
    };

    final existingDateRows = await _database
        .customSelect(
          'SELECT DISTINCT date FROM ${DbTables.tasks} ORDER BY date DESC LIMIT $_maxTaskDatesToPull',
        )
        .get();
    for (final row in existingDateRows) {
      final date = row.data['date'] as String?;
      if (date != null && date.isNotEmpty) {
        dateKeys.add(date);
      }
    }

    final allRows = <Map<String, dynamic>>[];

    for (final dateKey in dateKeys) {
      final rows = await _fetchPaged(
        path: ApiPaths.tasks,
        token: session.token,
        query: {'date': dateKey},
      );
      allRows.addAll(rows);
    }

    var inserted = 0;
    for (final item in allRows) {
      final id = item['id'] as String?;
      final date = item['date'] as String?;
      if (id == null || date == null) continue;
      if (!await _rowExists(DbTables.tasks, id)) {
        inserted++;
      }

      await _database
          .into(_database.tasks)
          .insertOnConflictUpdate(
            TasksCompanion(
              id: drift.Value(id),
              date: drift.Value(date),
              title: drift.Value((item['title'] as String?) ?? ''),
              deadline: drift.Value(_parseDateTime(item['deadline'])),
              priority: drift.Value(_toInt(item['priority'], fallback: 1)),
              completed: drift.Value(_toBool(item['completed'])),
              taskType: drift.Value((item['task_type'] as String?) ?? 'user'),
              createdAt: drift.Value(
                _parseDateTime(item['created_at']) ?? AppDateUtils.nowUtc(),
              ),
              reason: const drift.Value(null),
              synced: const drift.Value(true),
            ),
          );
    }

    return inserted;
  }

  Future<int> _pullPomodoroSessions(AuthSession session) async {
    final rows = await _fetchPagedRange(
      path: ApiPaths.pomodoroSessions,
      token: session.token,
    );

    var inserted = 0;
    for (final item in rows) {
      final id = item['id'] as String?;
      final startTime = _parseDateTime(item['start_time']);
      if (id == null || startTime == null) continue;
      if (!await _rowExists(DbTables.pomodoroSessions, id)) {
        inserted++;
      }

      await _database
          .into(_database.pomodoroSessions)
          .insertOnConflictUpdate(
            PomodoroSessionsCompanion(
              id: drift.Value(id),
              startTime: drift.Value(startTime),
              endTime: drift.Value(_parseDateTime(item['end_time'])),
              duration: drift.Value(_nullableInt(item['duration'])),
              completed: drift.Value(_nullableBool(item['completed'])),
              taskLabel: drift.Value(item['task_label'] as String?),
              createdAt: drift.Value(
                _parseDateTime(item['created_at']) ?? AppDateUtils.nowUtc(),
              ),
              synced: const drift.Value(true),
            ),
          );
    }
    return inserted;
  }

  Future<int> _pullBreathingSessions(AuthSession session) async {
    final rows = await _fetchPagedRange(
      path: ApiPaths.breathingSessions,
      token: session.token,
    );

    var inserted = 0;
    for (final item in rows) {
      final id = item['id'] as String?;
      final startedAt = _parseDateTime(item['started_at']);
      if (id == null || startedAt == null) continue;
      if (!await _rowExists(DbTables.breathingSessions, id)) {
        inserted++;
      }

      await _database
          .into(_database.breathingSessions)
          .insertOnConflictUpdate(
            BreathingSessionsCompanion(
              id: drift.Value(id),
              startedAt: drift.Value(startedAt),
              duration: drift.Value(_toInt(item['duration'])),
              completed: drift.Value(_toBool(item['completed'])),
              createdAt: drift.Value(
                _parseDateTime(item['created_at']) ?? AppDateUtils.nowUtc(),
              ),
              synced: const drift.Value(true),
            ),
          );
    }
    return inserted;
  }

  Future<int> _pullAlerts(AuthSession session) async {
    final rows = await _fetchPagedRange(
      path: ApiPaths.alerts,
      token: session.token,
    );

    var inserted = 0;
    for (final item in rows) {
      final id = item['id'] as String?;
      if (id == null) continue;
      final createdAt =
          _parseDateTime(item['created_at']) ?? AppDateUtils.nowUtc();
      final date =
          (item['date'] as String?) ?? AppDateUtils.dateKeyUtc(createdAt);
      if (!await _rowExists(DbTables.alerts, id)) {
        inserted++;
      }

      await _database
          .into(_database.alerts)
          .insertOnConflictUpdate(
            AlertsCompanion(
              id: drift.Value(id),
              date: drift.Value(date),
              type: drift.Value(
                _fromBackendAlertType((item['type'] as String?) ?? 'SYSTEM'),
              ),
              message: drift.Value((item['message'] as String?) ?? ''),
              createdAt: drift.Value(createdAt),
              synced: const drift.Value(true),
            ),
          );
    }
    return inserted;
  }

  Future<List<Map<String, dynamic>>> _fetchPagedRange({
    required String path,
    required String token,
  }) async {
    final from = DateTime.utc(2000, 1, 1);
    final to = DateTime.utc(2100, 12, 31);
    return _fetchPaged(
      path: path,
      token: token,
      query: {
        'from': AppDateUtils.dateKeyUtc(from),
        'to': AppDateUtils.dateKeyUtc(to),
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPaged({
    required String path,
    required String token,
    required Map<String, String> query,
  }) async {
    final items = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final page = await _apiClient.getList(
        path: path,
        token: token,
        query: {...query, 'limit': '$_pageSize', 'offset': '$offset'},
      );
      items.addAll(page);
      if (page.length < _pageSize) break;
      offset += page.length;
    }
    return items;
  }

  Future<void> _markSynced(String tableName, String id) {
    return _database.customStatement(
      'UPDATE $tableName SET synced = 1 WHERE id = ?',
      [id],
    );
  }

  Future<bool> _rowExists(String tableName, String id) async {
    final row = await _database
        .customSelect(
          'SELECT id FROM $tableName WHERE id = ? LIMIT 1',
          variables: [drift.Variable<String>(id)],
        )
        .getSingleOrNull();
    return row != null;
  }

  String _toBackendCauseType(String localCause) {
    const supported = <String>{
      'LOW_SLEEP',
      'HIGH_WORKLOAD',
      'LOW_MOOD',
      'DEADLINE_PRESSURE',
      'RISING_TREND',
      'TASK_OVERLOAD',
      'INSUFFICIENT_BREAKS',
      'OTHER',
    };
    if (supported.contains(localCause)) return localCause;
    if (localCause == 'LOW_EXERCISE') return 'OTHER';
    return 'OTHER';
  }

  String _toBackendAlertType(String localType) {
    switch (localType) {
      case 'HIGH_SCORE':
        return 'HIGH_BURNOUT';
      case 'RISING_TREND':
        return 'RISING_BURNOUT';
      case 'TASK_OVERLOAD':
        return 'TASK_OVERLOAD';
      case 'REMINDER':
        return 'REMINDER';
      default:
        return 'SYSTEM';
    }
  }

  String _fromBackendAlertType(String backendType) {
    switch (backendType) {
      case 'HIGH_BURNOUT':
        return 'HIGH_SCORE';
      case 'RISING_BURNOUT':
        return 'RISING_TREND';
      default:
        return backendType;
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    return (value as num?)?.toDouble() ?? fallback;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    return (value as num?)?.toInt() ?? fallback;
  }

  int? _nullableInt(dynamic value) {
    if (value == null) return null;
    return (value as num?)?.toInt();
  }

  bool _toBool(dynamic value, {bool fallback = false}) {
    return value is bool ? value : fallback;
  }

  bool? _nullableBool(dynamic value) {
    if (value == null) return null;
    return value is bool ? value : null;
  }
}
