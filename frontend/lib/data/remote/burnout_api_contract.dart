import 'api_models.dart';

abstract class BurnoutApiContract {
  Future<ApiUserProfile> putUserProfile(ApiUserProfile profile);

  Future<ApiUserProfile?> getUserProfile();

  Future<ApiDailyEntry> createDailyEntry(ApiDailyEntry entry);

  Future<PagedResult<ApiDailyEntry>> getDailyEntries({
    required DateRangeQuery range,
    required PaginationQuery pagination,
  });

  Future<ApiBurnoutScore> createBurnoutScore(ApiBurnoutScore score);

  Future<ApiBurnoutScore?> getLatestBurnoutScore();

  Future<PagedResult<ApiBurnoutScore>> getBurnoutScores({
    required DateRangeQuery range,
    required PaginationQuery pagination,
  });

  Future<List<ApiBurnoutCause>> addBurnoutCauses(
    BurnoutCauseBatchRequest request,
  );

  Future<PagedResult<ApiBurnoutCause>> getBurnoutCauses({
    required String scoreId,
    required PaginationQuery pagination,
  });

  Future<ApiTask> createTask(ApiTask task);

  Future<PagedResult<ApiTask>> getTasksByDate({
    required DateTime date,
    required PaginationQuery pagination,
  });

  Future<ApiTask> patchTask({
    required String taskId,
    required TaskPatchRequest patch,
  });

  Future<ApiScoreLog> createScoreLog(ApiScoreLog scoreLog);

  Future<PagedResult<ApiScoreLog>> getScoreLogsByScore({
    required String scoreId,
    required PaginationQuery pagination,
  });

  Future<ApiPomodoroSession> createPomodoroSession(ApiPomodoroSession session);

  Future<ApiPomodoroSession> patchPomodoroSession({
    required String sessionId,
    required PomodoroSessionPatchRequest patch,
  });

  Future<PagedResult<ApiPomodoroSession>> getPomodoroSessions({
    required DateRangeQuery range,
    required PaginationQuery pagination,
  });

  Future<ApiBreathingSession> createBreathingSession(
    ApiBreathingSession session,
  );

  Future<ApiBreathingSession> patchBreathingSession({
    required String sessionId,
    required BreathingSessionPatchRequest patch,
  });

  Future<PagedResult<ApiBreathingSession>> getBreathingSessions({
    required DateRangeQuery range,
    required PaginationQuery pagination,
  });

  Future<ApiAlert> createAlert(ApiAlert alert);

  Future<PagedResult<ApiAlert>> getAlerts({
    required DateRangeQuery range,
    required PaginationQuery pagination,
  });

  Future<ApiDashboardResponse> getDashboard();
}
