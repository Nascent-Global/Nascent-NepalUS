class AppConstants {
  AppConstants._();

  static const String appName = 'Burnout Radar';

  static const int lowMax = 30;
  static const int mediumMax = 70;
  static const int highMin = 71;

  static const int highAlertThreshold = 70;
  static const int risingAlertDelta = 5;

  static const int maxDailyRecoveryTasks = 3;

  static const double lowSleepHours = 6.0;
  static const double optimalSleepHours = 8.0;
  static const double highWorkHours = 8.0;

  static const int reminderNotificationId = 9001;
  static const String reminderChannelId = 'burnout_reminders';
  static const String reminderChannelName = 'Burnout Reminders';
  static const String reminderChannelDescription =
      'Daily reminders for check-ins and recovery actions.';

  static const int defaultPomodoroMinutes = 25;
  static const int defaultBreathingMinutes = 5;

  static const Map<String, int> recoveryImpactByTaskType = {
    'sleep_recovery': 8,
    'break': 5,
    'workload_trim': 10,
    'exercise_recovery': 7,
    'breathing': 6,
    'general_recovery': 3,
  };
}

class DbTables {
  DbTables._();

  static const userProfile = 'user_profile';
  static const dailyEntries = 'daily_entries';
  static const burnoutScores = 'burnout_scores';
  static const burnoutCauses = 'burnout_causes';
  static const tasks = 'tasks';
  static const scoreLogs = 'score_logs';
  static const pomodoroSessions = 'pomodoro_sessions';
  static const breathingSessions = 'breathing_sessions';
  static const alerts = 'alerts';
}
