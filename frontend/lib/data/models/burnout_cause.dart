import '../../core/date_utils.dart';

class BurnoutCause {
  const BurnoutCause({
    required this.id,
    required this.scoreId,
    required this.causeType,
    required this.createdAt,
    required this.synced,
  });

  final String id;
  final String scoreId;
  final String causeType;
  final DateTime createdAt;
  final bool synced;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'score_id': scoreId,
      'cause_type': causeType,
      'created_at': AppDateUtils.toUtcIso(createdAt),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory BurnoutCause.fromMap(Map<String, Object?> map) {
    return BurnoutCause(
      id: map['id'] as String,
      scoreId: map['score_id'] as String,
      causeType: map['cause_type'] as String,
      createdAt: AppDateUtils.fromUtcIso(map['created_at'] as String),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
