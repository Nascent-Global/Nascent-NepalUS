import '../../core/date_utils.dart';

class AppAlert {
  const AppAlert({
    required this.id,
    required this.date,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.synced,
  });

  final String id;
  final String date;
  final String type;
  final String message;
  final DateTime createdAt;
  final bool synced;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'message': message,
      'created_at': AppDateUtils.toUtcIso(createdAt),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory AppAlert.fromMap(Map<String, Object?> map) {
    return AppAlert(
      id: map['id'] as String,
      date: map['date'] as String? ?? '',
      type: map['type'] as String? ?? '',
      message: map['message'] as String? ?? '',
      createdAt: AppDateUtils.fromUtcIso(map['created_at'] as String),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
