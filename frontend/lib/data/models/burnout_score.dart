import '../../core/date_utils.dart';

class BurnoutScore {
  const BurnoutScore({
    required this.id,
    required this.date,
    required this.score,
    required this.classification,
    required this.createdAt,
    required this.synced,
  });

  final String id;
  final String date;
  final int score;
  final String classification;
  final DateTime createdAt;
  final bool synced;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'score': score,
      'classification': classification,
      'created_at': AppDateUtils.toUtcIso(createdAt),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory BurnoutScore.fromMap(Map<String, Object?> map) {
    return BurnoutScore(
      id: map['id'] as String,
      date: map['date'] as String,
      score: (map['score'] as num).toInt(),
      classification: map['classification'] as String,
      createdAt: AppDateUtils.fromUtcIso(map['created_at'] as String),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
