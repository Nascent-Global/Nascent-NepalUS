import '../../core/date_utils.dart';

class DailyEntry {
  const DailyEntry({
    required this.id,
    required this.date,
    required this.sleepHours,
    required this.workHours,
    required this.mood,
    required this.wasOk,
    required this.createdAt,
    required this.synced,
  });

  final String id;
  final String date;
  final double sleepHours;
  final double workHours;
  final int mood;
  final bool wasOk;
  final DateTime createdAt;
  final bool synced;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'sleep_hours': sleepHours,
      'work_hours': workHours,
      'mood': mood,
      'was_ok': wasOk ? 1 : 0,
      'created_at': AppDateUtils.toUtcIso(createdAt),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory DailyEntry.fromMap(Map<String, Object?> map) {
    return DailyEntry(
      id: map['id'] as String,
      date: map['date'] as String,
      sleepHours: (map['sleep_hours'] as num?)?.toDouble() ?? 0,
      workHours: (map['work_hours'] as num?)?.toDouble() ?? 0,
      mood: map['mood'] as int? ?? 3,
      wasOk: (map['was_ok'] as int? ?? 0) == 1,
      createdAt: AppDateUtils.fromUtcIso(map['created_at'] as String),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
