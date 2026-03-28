import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../data/models/app_alert.dart';
import '../../data/models/burnout_task.dart';
import '../../data/models/daily_entry.dart';
import '../../data/repository/burnout_repository.dart';
import '../entities/dashboard_snapshot.dart';
import '../models/burnout_cause_type.dart';

class BurnoutEngine {
  BurnoutEngine(this._repository);

  final BurnoutRepository _repository;
  final Uuid _uuid = const Uuid();

  Future<void> submitDailyCheckIn({
    required double sleepHours,
    required double workHours,
    required int mood,
    required bool wasOk,
  }) async {
    final now = AppDateUtils.nowUtc();
    final entry = DailyEntry(
      id: _uuid.v4(),
      date: AppDateUtils.dateKeyUtc(now),
      sleepHours: sleepHours,
      workHours: workHours,
      mood: mood,
      wasOk: wasOk,
      createdAt: now,
      synced: false,
    );

    await _repository.saveDailyEntry(entry);
    await _recomputeAndPersist(now);
  }

  Future<void> completeTask(String taskId) async {
    await _repository.completeTask(taskId);
    await _checkAlertsForToday(AppDateUtils.nowUtc());
  }

  Future<DashboardSnapshot> getDashboardSnapshot({int trendDays = 7}) async {
    final now = AppDateUtils.nowUtc();
    final from = now.subtract(Duration(days: trendDays - 1));

    final latestScore = await _repository.getLatestScore();
    final trend = await _repository.getScoresByRange(from, now);
    final latestCauses = latestScore == null
        ? <String>[]
        : await _repository.getCausesByScoreId(latestScore.id);
    final todayTasks = await _repository.getTasksByDate(now);
    final alerts = await _repository.getAlerts(limit: 10);

    String direction = '→';
    final groupedByDate = groupBy(trend, (e) => e.date);
    if (groupedByDate.length >= 2) {
      final orderedDays = groupedByDate.keys.toList()..sort();
      final prev =
          groupedByDate[orderedDays[orderedDays.length - 2]]!.last.score;
      final curr = groupedByDate[orderedDays.last]!.last.score;
      direction = AppDateUtils.relativeDirection(curr, prev);
    }

    return DashboardSnapshot(
      latestScore: latestScore,
      causes: latestCauses,
      todayTasks: todayTasks,
      trend: trend,
      direction: direction,
      alerts: alerts,
    );
  }

  Future<String> startPomodoro({
    int minutes = AppConstants.defaultPomodoroMinutes,
  }) {
    return _repository.startPomodoro(
      startTime: AppDateUtils.nowUtc(),
      durationMinutes: minutes,
    );
  }

  Future<void> endPomodoro({required String id, required bool completed}) {
    return _repository.endPomodoro(
      id: id,
      endTime: AppDateUtils.nowUtc(),
      completed: completed,
    );
  }

  Future<String> startBreathing({
    int minutes = AppConstants.defaultBreathingMinutes,
  }) {
    return _repository.startBreathing(
      startedAt: AppDateUtils.nowUtc(),
      durationMinutes: minutes,
    );
  }

  Future<void> endBreathing({required String id, required bool completed}) {
    return _repository.endBreathing(id: id, completed: completed);
  }

  Future<void> addUserTask({
    required String title,
    required int priority,
    DateTime? deadline,
  }) async {
    final now = AppDateUtils.nowUtc();
    final task = BurnoutTask(
      id: _uuid.v4(),
      date: AppDateUtils.dateKeyUtc(now),
      title: title,
      deadline: deadline,
      priority: priority,
      completed: false,
      taskType: 'user',
      createdAt: now,
      synced: false,
      reason: null,
    );
    await _repository.upsertTask(task);
    await _recomputeAndPersist(now);
  }

  Future<void> _recomputeAndPersist(DateTime now) async {
    final entry = await _repository.getLatestDailyEntryForDate(now);
    if (entry == null) return;

    final tasks = await _repository.getTasksByDate(now);
    final causes = _detectCauses(entry, tasks);
    final score = _computeScore(entry, tasks);
    final classification = _classify(score);

    final scoreId = await _repository.insertScoreSnapshot(
      date: now,
      score: score,
      classification: classification,
      causes: causes.map((e) => e.key).toList(),
    );

    final recommendedTasks = _buildRecoveryTasks(now, causes);
    for (final task in recommendedTasks) {
      await _repository.upsertTask(task);
    }

    await _repository.logScoreChange(
      scoreId: scoreId,
      changeAmount: 0,
      reason: 'New score snapshot from daily evaluation',
    );

    await _checkAlertsForToday(now);
  }

  Future<void> _checkAlertsForToday(DateTime now) async {
    final today = AppDateUtils.dateKeyUtc(now);
    final latest = await _repository.getLatestScore();
    if (latest == null) return;

    if (latest.score >= AppConstants.highAlertThreshold) {
      await _repository.insertAlert(
        AppAlert(
          id: _uuid.v4(),
          date: today,
          type: 'HIGH_SCORE',
          message:
              'Burnout risk is high (${latest.score}). Start recovery now.',
          createdAt: AppDateUtils.nowUtc(),
          synced: false,
        ),
      );
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final recent = await _repository.getScoresByRange(yesterday, now);
    final grouped = groupBy(recent, (e) => e.date);
    if (grouped.length < 2) return;

    final days = grouped.keys.toList()..sort();
    final previousScore = grouped[days[days.length - 2]]!.last.score;
    final currentScore = grouped[days.last]!.last.score;
    if (currentScore - previousScore >= AppConstants.risingAlertDelta) {
      await _repository.insertAlert(
        AppAlert(
          id: _uuid.v4(),
          date: today,
          type: 'RISING_TREND',
          message:
              'Burnout score increased by ${currentScore - previousScore} points since yesterday.',
          createdAt: AppDateUtils.nowUtc(),
          synced: false,
        ),
      );
    }
  }

  int _computeScore(DailyEntry entry, List<BurnoutTask> tasks) {
    var score = 0;

    if (entry.sleepHours < 5) {
      score += 25;
    } else if (entry.sleepHours < 6) {
      score += 18;
    } else if (entry.sleepHours < 7) {
      score += 12;
    } else if (entry.sleepHours > AppConstants.optimalSleepHours) {
      score += 4;
    }

    if (entry.workHours > 10) {
      score += 25;
    } else if (entry.workHours > 8) {
      score += 16;
    } else if (entry.workHours > 6) {
      score += 8;
    }

    score += ((5 - entry.mood).clamp(0, 4) * 7).toInt();

    if (!entry.wasOk) {
      score += 10;
    }

    final now = AppDateUtils.nowUtc();
    final pendingTasks = tasks.where((task) => !task.completed).toList();
    final deadlinePressure = pendingTasks.fold<int>(0, (sum, task) {
      final priority = task.priority.clamp(1, 5);
      final deadline = task.deadline;
      if (deadline == null) return sum + priority;
      final days = deadline.difference(now).inDays;
      if (days <= 0) return sum + (priority * 4);
      if (days <= 1) return sum + (priority * 3);
      if (days <= 2) return sum + (priority * 2);
      return sum + priority;
    });

    score += deadlinePressure.clamp(0, 30);

    return score.clamp(0, 100);
  }

  List<BurnoutCauseType> _detectCauses(
    DailyEntry entry,
    List<BurnoutTask> tasks,
  ) {
    final causes = <BurnoutCauseType>[];

    if (entry.sleepHours < AppConstants.lowSleepHours) {
      causes.add(BurnoutCauseType.lowSleep);
    }
    if (entry.workHours > AppConstants.highWorkHours) {
      causes.add(BurnoutCauseType.highWorkload);
    }
    if (entry.mood <= 2) {
      causes.add(BurnoutCauseType.lowMood);
    }
    if (!entry.wasOk) {
      causes.add(BurnoutCauseType.negativeCheckIn);
    }

    final deadlineHeavy = tasks.any((task) {
      if (task.completed || task.deadline == null) return false;
      return task.deadline!.difference(AppDateUtils.nowUtc()).inDays <= 2;
    });
    if (deadlineHeavy) {
      causes.add(BurnoutCauseType.deadlinePressure);
    }

    return causes;
  }

  List<BurnoutTask> _buildRecoveryTasks(
    DateTime now,
    List<BurnoutCauseType> causes,
  ) {
    final templates = <({String title, String reason, int priority})>[];

    for (final cause in causes) {
      switch (cause) {
        case BurnoutCauseType.lowSleep:
          templates.add((
            title: 'Sleep 30 minutes earlier tonight',
            reason: 'sleep_recovery',
            priority: 5,
          ));
        case BurnoutCauseType.highWorkload:
          templates.add((
            title: 'Drop one non-critical task from today',
            reason: 'workload_trim',
            priority: 5,
          ));
        case BurnoutCauseType.lowMood:
          templates.add((
            title: 'Take a 10-minute reset walk',
            reason: 'break',
            priority: 4,
          ));
        case BurnoutCauseType.negativeCheckIn:
          templates.add((
            title: 'Do a 5-minute breathing reset',
            reason: 'breathing',
            priority: 4,
          ));
        case BurnoutCauseType.deadlinePressure:
          templates.add((
            title: 'Use a focused 25-minute sprint now',
            reason: 'focus_reset',
            priority: 5,
          ));
        case BurnoutCauseType.risingTrend:
          templates.add((
            title: 'Schedule a full recovery block this evening',
            reason: 'general_recovery',
            priority: 4,
          ));
      }
    }

    final unique = <String, ({String title, String reason, int priority})>{};
    for (final template in templates) {
      unique[template.title] = template;
    }

    return unique.values
        .take(AppConstants.maxDailyRecoveryTasks)
        .map(
          (template) => BurnoutTask(
            id: _uuid.v4(),
            date: AppDateUtils.dateKeyUtc(now),
            title: template.title,
            deadline: now.add(const Duration(hours: 8)),
            priority: template.priority,
            completed: false,
            taskType: 'recovery',
            createdAt: now,
            synced: false,
            reason: template.reason,
          ),
        )
        .toList();
  }

  String _classify(int score) {
    if (score <= AppConstants.lowMax) return 'low';
    if (score <= AppConstants.mediumMax) return 'medium';
    return 'high';
  }
}
