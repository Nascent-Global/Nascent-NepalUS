import '../../core/date_utils.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.username,
    required this.avatar,
    required this.timezone,
    required this.createdAt,
    required this.synced,
  });

  final String id;
  final String username;
  final String avatar;
  final String timezone;
  final DateTime createdAt;
  final bool synced;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'timezone': timezone,
      'created_at': AppDateUtils.toUtcIso(createdAt),
      'synced': synced ? 1 : 0,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory AppUserProfile.fromMap(Map<String, Object?> map) {
    return AppUserProfile(
      id: map['id'] as String,
      username: map['username'] as String,
      avatar: map['avatar'] as String,
      timezone: map['timezone'] as String,
      createdAt: AppDateUtils.fromUtcIso(map['created_at'] as String),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
