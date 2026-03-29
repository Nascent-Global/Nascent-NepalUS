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
    required int exerciseMinutes,
    required bool includePomodoroWork,
  }) async {
    final now = AppDateUtils.nowUtc();
    final entry = DailyEntry(
      id: _uuid.v4(),
      date: AppDateUtils.dateKeyUtc(now),
      sleepHours: sleepHours,
      workHours: workHours,
      mood: mood,
      exerciseMinutes: exerciseMinutes,
      includePomodoroWork: includePomodoroWork,
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

    final effectiveWorkHours = await _resolveEffectiveWorkHours(entry, now);
    final causes = _detectCauses(entry, effectiveWorkHours);
    final score = _computeScore(entry, effectiveWorkHours);
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

  int _computeScore(DailyEntry entry, double effectiveWorkHours) {
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

    if (effectiveWorkHours > 10) {
      score += 25;
    } else if (effectiveWorkHours > 8) {
      score += 16;
    } else if (effectiveWorkHours > 6) {
      score += 8;
    }

    score += ((5 - entry.mood).clamp(0, 4) * 7).toInt();

    if (entry.exerciseMinutes < 10) {
      score += 10;
    } else if (entry.exerciseMinutes < 20) {
      score += 6;
    } else if (entry.exerciseMinutes < 30) {
      score += 3;
    } else if (entry.exerciseMinutes >= 45) {
      score -= 4;
    }

    return score.clamp(0, 100);
  }

  List<BurnoutCauseType> _detectCauses(
    DailyEntry entry,
    double effectiveWorkHours,
  ) {
    final causes = <BurnoutCauseType>[];

    if (entry.sleepHours < AppConstants.lowSleepHours) {
      causes.add(BurnoutCauseType.lowSleep);
    }
    if (effectiveWorkHours > AppConstants.highWorkHours) {
      causes.add(BurnoutCauseType.highWorkload);
    }
    if (entry.mood <= 2) {
      causes.add(BurnoutCauseType.lowMood);
    }
    if (entry.exerciseMinutes < 20) {
      causes.add(BurnoutCauseType.lowExercise);
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
        case BurnoutCauseType.lowExercise:
          templates.add((
            title: 'Do at least 20 minutes of light exercise',
            reason: 'exercise_recovery',
            priority: 4,
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

  Future<double> _resolveEffectiveWorkHours(
    DailyEntry entry,
    DateTime date,
  ) async {
    if (!entry.includePomodoroWork) {
      return entry.workHours;
    }

    final sessions = await _repository.getPomodoroByDate(date);
    final completedMinutes = sessions
        .where((session) => session.completed)
        .fold<int>(0, (sum, session) {
          if (session.duration > 0) {
            return sum + session.duration;
          }
          if (session.endTime == null) return sum;
          return sum + session.endTime!.difference(session.startTime).inMinutes;
        });

    final pomodoroHours = completedMinutes / 60.0;
    return entry.workHours + pomodoroHours;
  }

  String _classify(int score) {
    if (score <= AppConstants.lowMax) return 'low';
    if (score <= AppConstants.mediumMax) return 'medium';
    return 'high';
  }
}
