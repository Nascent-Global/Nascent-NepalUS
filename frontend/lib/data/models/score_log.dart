import '../../core/date_utils.dart';

class ScoreLog {
  const ScoreLog({
    required this.id,
    required this.scoreId,
    required this.changeAmount,
    required this.reason,
    required this.createdAt,
    required this.synced,
  });

  final String id;
  final String scoreId;
  final int changeAmount;
  final String reason;
  final DateTime createdAt;
  final bool synced;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'score_id': scoreId,
      'change_amount': changeAmount,
      'reason': reason,
      'created_at': AppDateUtils.toUtcIso(createdAt),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory ScoreLog.fromMap(Map<String, Object?> map) {
    return ScoreLog(
      id: map['id'] as String,
      scoreId: map['score_id'] as String,
      changeAmount: (map['change_amount'] as num).toInt(),
      reason: map['reason'] as String? ?? '',
      createdAt: AppDateUtils.fromUtcIso(map['created_at'] as String),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
