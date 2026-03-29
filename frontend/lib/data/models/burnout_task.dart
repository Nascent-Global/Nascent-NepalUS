import '../../core/date_utils.dart';

class BurnoutTask {
  const BurnoutTask({
    required this.id,
    required this.date,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.completed,
    required this.taskType,
    required this.createdAt,
    required this.synced,
    this.reason,
  });

  final String id;
  final String date;
  final String title;
  final DateTime? deadline;
  final int priority;
  final bool completed;
  final String taskType;
  final DateTime createdAt;
  final bool synced;
  final String? reason;

  BurnoutTask copyWith({bool? completed}) {
    return BurnoutTask(
      id: id,
      date: date,
      title: title,
      deadline: deadline,
      priority: priority,
      completed: completed ?? this.completed,
      taskType: taskType,
      createdAt: createdAt,
      synced: synced,
      reason: reason,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'deadline': deadline == null ? null : AppDateUtils.toUtcIso(deadline!),
      'priority': priority,
      'completed': completed ? 1 : 0,
      'task_type': taskType,
      'created_at': AppDateUtils.toUtcIso(createdAt),
      'synced': synced ? 1 : 0,
      'reason': reason,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory BurnoutTask.fromMap(Map<String, Object?> map) {
    return BurnoutTask(
      id: map['id'] as String,
      date: map['date'] as String,
      title: map['title'] as String,
      deadline: map['deadline'] == null
          ? null
          : AppDateUtils.fromUtcIso(map['deadline'] as String),
      priority: (map['priority'] as num?)?.toInt() ?? 1,
      completed: (map['completed'] as int? ?? 0) == 1,
      taskType: map['task_type'] as String,
      createdAt: AppDateUtils.fromUtcIso(map['created_at'] as String),
      synced: (map['synced'] as int? ?? 0) == 1,
      reason: map['reason'] as String?,
    );
  }
}
