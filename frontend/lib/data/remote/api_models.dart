import '../../core/date_utils.dart';

class PaginationQuery {
  const PaginationQuery({this.limit = 50, this.offset = 0});

  final int limit;
  final int offset;

  Map<String, String> toQuery() {
    return {'limit': '$limit', 'offset': '$offset'};
  }
}

class DateRangeQuery {
  const DateRangeQuery({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  Map<String, String> toQuery() {
    return {
      'from': AppDateUtils.dateKeyUtc(from),
      'to': AppDateUtils.dateKeyUtc(to),
    };
  }
}

class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<T> items;
  final int total;
  final int limit;
  final int offset;
}

class ApiUserProfile {
  const ApiUserProfile({
    required this.id,
    required this.username,
    required this.avatar,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String username;
  final String avatar;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'timezone': timezone,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ApiUserProfile.fromJson(Map<String, dynamic> json) {
    return ApiUserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String,
      timezone: json['timezone'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}

class ApiDailyEntry {
  const ApiDailyEntry({
    required this.id,
    required this.date,
    required this.sleepHours,
    required this.workHours,
    required this.mood,
    required this.exerciseMinutes,
    required this.includePomodoroWork,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final double sleepHours;
  final double workHours;
  final int mood;
  final int exerciseMinutes;
  final bool includePomodoroWork;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'sleep_hours': sleepHours,
      'work_hours': workHours,
      'mood': mood,
      'exercise_minutes': exerciseMinutes,
      'include_pomodoro_work': includePomodoroWork,
      // Backward compatibility for older backend schemas.
      'was_ok': mood >= 3,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ApiDailyEntry.fromJson(Map<String, dynamic> json) {
    return ApiDailyEntry(
      id: json['id'] as String,
      date: json['date'] as String,
      sleepHours: (json['sleep_hours'] as num?)?.toDouble() ?? 0,
      workHours: (json['work_hours'] as num?)?.toDouble() ?? 0,
      mood: (json['mood'] as num).toInt(),
      exerciseMinutes: (json['exercise_minutes'] as num?)?.toInt() ?? 0,
      includePomodoroWork: json['include_pomodoro_work'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}

class ApiBurnoutScore {
  const ApiBurnoutScore({
    required this.id,
    required this.date,
    required this.score,
    required this.classification,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final int score;
  final String classification;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'score': score,
      'classification': classification,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ApiBurnoutScore.fromJson(Map<String, dynamic> json) {
    return ApiBurnoutScore(
      id: json['id'] as String,
      date: json['date'] as String,
      score: (json['score'] as num).toInt(),
      classification: json['classification'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}

class BurnoutCauseBatchRequest {
  const BurnoutCauseBatchRequest({required this.scoreId, required this.causes});

  final String scoreId;
  final List<String> causes;

  Map<String, dynamic> toJson() {
    return {'score_id': scoreId, 'causes': causes};
  }
}

class ApiBurnoutCause {
  const ApiBurnoutCause({
    required this.id,
    required this.scoreId,
    required this.causeType,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String scoreId;
  final String causeType;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'score_id': scoreId,
      'cause_type': causeType,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ApiBurnoutCause.fromJson(Map<String, dynamic> json) {
    return ApiBurnoutCause(
      id: json['id'] as String,
      scoreId: json['score_id'] as String,
      causeType: json['cause_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}

class ApiTask {
  const ApiTask({
    required this.id,
    required this.date,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.completed,
    required this.taskType,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final String title;
  final DateTime? deadline;
  final int priority;
  final bool completed;
  final String taskType;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'deadline': deadline?.toUtc().toIso8601String(),
      'priority': priority,
      'completed': completed,
      'task_type': taskType,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ApiTask.fromJson(Map<String, dynamic> json) {
    return ApiTask(
      id: json['id'] as String,
      date: json['date'] as String,
      title: json['title'] as String,
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String).toUtc(),
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      completed: json['completed'] as bool,
      taskType: json['task_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}

class TaskPatchRequest {
  const TaskPatchRequest({
    this.title,
    this.deadline,
    this.priority,
    this.completed,
    this.taskType,
  });

  final String? title;
  final DateTime? deadline;
  final int? priority;
  final bool? completed;
  final String? taskType;

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (deadline != null) 'deadline': deadline!.toUtc().toIso8601String(),
      if (priority != null) 'priority': priority,
      if (completed != null) 'completed': completed,
      if (taskType != null) 'task_type': taskType,
    };
  }
}

class ApiScoreLog {
  const ApiScoreLog({
    required this.id,
    required this.scoreId,
    required this.changeAmount,
    required this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String scoreId;
  final int changeAmount;
  final String reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'score_id': scoreId,
      'change_amount': changeAmount,
      'reason': reason,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ApiScoreLog.fromJson(Map<String, dynamic> json) {
    return ApiScoreLog(
      id: json['id'] as String,
      scoreId: json['score_id'] as String,
      changeAmount: (json['change_amount'] as num).toInt(),
      reason: (json['reason'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}

class ApiPomodoroSession {
  const ApiPomodoroSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.completed,
    required this.taskLabel,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;
  final bool? completed;
  final String? taskLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime?.toUtc().toIso8601String(),
      'duration': duration,
      'completed': completed,
      'task_label': taskLabel,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ApiPomodoroSession.fromJson(Map<String, dynamic> json) {
    return ApiPomodoroSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['start_time'] as String).toUtc(),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String).toUtc(),
      duration: (json['duration'] as num?)?.toInt(),
      completed: json['completed'] as bool?,
      taskLabel: json['task_label'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}

class PomodoroSessionPatchRequest {
  const PomodoroSessionPatchRequest({
    this.endTime,
    this.duration,
    this.completed,
    this.taskLabel,
  });

  final DateTime? endTime;
  final int? duration;
  final bool? completed;
  final String? taskLabel;

  Map<String, dynamic> toJson() {
    return {
      if (endTime != null) 'end_time': endTime!.toUtc().toIso8601String(),
      if (duration != null) 'duration': duration,
      if (completed != null) 'completed': completed,
      if (taskLabel != null) 'task_label': taskLabel,
    };
  }
}

class ApiBreathingSession {
  const ApiBreathingSession({
    required this.id,
    required this.startedAt,
    required this.duration,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime startedAt;
  final int duration;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'started_at': startedAt.toUtc().toIso8601String(),
      'duration': duration,
      'completed': completed,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ApiBreathingSession.fromJson(Map<String, dynamic> json) {
    return ApiBreathingSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String).toUtc(),
      duration: (json['duration'] as num).toInt(),
      completed: json['completed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}

class BreathingSessionPatchRequest {
  const BreathingSessionPatchRequest({this.duration, this.completed});

  final int? duration;
  final bool? completed;

  Map<String, dynamic> toJson() {
    return {
      if (duration != null) 'duration': duration,
      if (completed != null) 'completed': completed,
    };
  }
}

class ApiAlert {
  const ApiAlert({
    required this.id,
    required this.date,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final String type;
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'message': message,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ApiAlert.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String).toUtc();
    return ApiAlert(
      id: json['id'] as String,
      date: (json['date'] as String?) ?? AppDateUtils.dateKeyUtc(createdAt),
      type: json['type'] as String,
      message: json['message'] as String,
      createdAt: createdAt,
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}

class ApiDashboardResponse {
  const ApiDashboardResponse({
    required this.latestScore,
    required this.causes,
    required this.tasksToday,
    required this.trend,
  });

  final ApiBurnoutScore? latestScore;
  final List<String> causes;
  final List<ApiTask> tasksToday;
  final List<ApiBurnoutScore> trend;

  factory ApiDashboardResponse.fromJson(Map<String, dynamic> json) {
    final latestRaw = json['latest_score'] as Map<String, dynamic>?;
    final causesRaw = (json['causes'] as List<dynamic>? ?? const [])
        .map((e) => e as String)
        .toList();
    final tasksRaw = (json['tasks_today'] as List<dynamic>? ?? const [])
        .map((e) => ApiTask.fromJson(e as Map<String, dynamic>))
        .toList();
    final trendRaw = (json['trend'] as List<dynamic>? ?? const [])
        .map((e) => ApiBurnoutScore.fromJson(e as Map<String, dynamic>))
        .toList();

    return ApiDashboardResponse(
      latestScore: latestRaw == null
          ? null
          : ApiBurnoutScore.fromJson(latestRaw),
      causes: causesRaw,
      tasksToday: tasksRaw,
      trend: trendRaw,
    );
  }
}
