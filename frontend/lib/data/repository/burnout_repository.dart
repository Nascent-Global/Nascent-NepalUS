import '../models/app_alert.dart';
import '../models/breathing_session.dart';
import '../models/burnout_score.dart';
import '../models/burnout_task.dart';
import '../models/daily_entry.dart';
import '../models/pomodoro_session.dart';

abstract class BurnoutRepository {
  Future<void> saveDailyEntry(DailyEntry entry);

  Future<BurnoutScore?> getLatestScore();

  Future<List<BurnoutScore>> getScoresByRange(DateTime from, DateTime to);

  Future<List<BurnoutTask>> getTasksByDate(DateTime date);

  Future<void> upsertTask(BurnoutTask task);

  Future<void> completeTask(String id);

  Future<void> logScoreChange({
    required String scoreId,
    required int changeAmount,
    required String reason,
  });

  Future<void> insertAlert(AppAlert alert);

  Future<String> startPomodoro({
    required DateTime startTime,
    required int durationMinutes,
  });

  Future<void> endPomodoro({
    required String id,
    required DateTime endTime,
    required bool completed,
  });

  Future<String> startBreathing({
    required DateTime startedAt,
    required int durationMinutes,
  });

  Future<void> endBreathing({required String id, required bool completed});

  Future<DailyEntry?> getLatestDailyEntryForDate(DateTime date);

  Future<String> insertScoreSnapshot({
    required DateTime date,
    required int score,
    required String classification,
    required List<String> causes,
  });

  Future<List<String>> getCausesByScoreId(String scoreId);

  Future<List<AppAlert>> getAlerts({int limit = 30});

  Future<List<PomodoroSession>> getPomodoroByDate(DateTime date);

  Future<List<BreathingSession>> getBreathingByDate(DateTime date);
}
