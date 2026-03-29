class ApiPaths {
  ApiPaths._();

  static const userProfile = '/user-profile';
  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';
  static const authMe = '/auth/me';
  static const dailyEntries = '/daily-entries';
  static const burnoutScores = '/burnout-scores';
  static const burnoutScoresLatest = '/burnout-scores/latest';
  static const burnoutCauses = '/burnout-causes';
  static const tasks = '/tasks';
  static const scoreLogs = '/score-logs';
  static const pomodoroSessions = '/pomodoro-sessions';
  static const breathingSessions = '/breathing-sessions';
  static const alerts = '/alerts';
  static const dashboard = '/dashboard';

  static String taskById(String id) => '$tasks/$id';

  static String pomodoroSessionById(String id) => '$pomodoroSessions/$id';

  static String breathingSessionById(String id) => '$breathingSessions/$id';
}
