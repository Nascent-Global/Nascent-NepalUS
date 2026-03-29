import '../../core/date_utils.dart';

class PomodoroSession {
  const PomodoroSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.completed,
    required this.taskLabel,
    required this.createdAt,
    required this.synced,
  });

  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration;
  final bool completed;
  final String? taskLabel;
  final DateTime createdAt;
  final bool synced;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'start_time': AppDateUtils.toUtcIso(startTime),
      'end_time': endTime == null ? null : AppDateUtils.toUtcIso(endTime!),
      'duration': duration,
      'completed': completed ? 1 : 0,
      'task_label': taskLabel,
      'created_at': AppDateUtils.toUtcIso(createdAt),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory PomodoroSession.fromMap(Map<String, Object?> map) {
    return PomodoroSession(
      id: map['id'] as String,
      startTime: AppDateUtils.fromUtcIso(map['start_time'] as String),
      endTime: map['end_time'] == null
          ? null
          : AppDateUtils.fromUtcIso(map['end_time'] as String),
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      completed: (map['completed'] as int? ?? 0) == 1,
      taskLabel: map['task_label'] as String?,
      createdAt: AppDateUtils.fromUtcIso(map['created_at'] as String),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
