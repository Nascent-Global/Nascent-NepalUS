import '../../core/date_utils.dart';

class BreathingSession {
  const BreathingSession({
    required this.id,
    required this.startedAt,
    required this.duration,
    required this.completed,
    required this.createdAt,
    required this.synced,
  });

  final String id;
  final DateTime startedAt;
  final int duration;
  final bool completed;
  final DateTime createdAt;
  final bool synced;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'started_at': AppDateUtils.toUtcIso(startedAt),
      'duration': duration,
      'completed': completed ? 1 : 0,
      'created_at': AppDateUtils.toUtcIso(createdAt),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory BreathingSession.fromMap(Map<String, Object?> map) {
    return BreathingSession(
      id: map['id'] as String,
      startedAt: AppDateUtils.fromUtcIso(map['started_at'] as String),
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      completed: (map['completed'] as int? ?? 0) == 1,
      createdAt: AppDateUtils.fromUtcIso(map['created_at'] as String),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
