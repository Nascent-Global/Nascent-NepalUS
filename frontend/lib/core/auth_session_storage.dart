import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/remote/auth_models.dart';

class AuthSessionStorage {
  static const _tokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userJsonKey = 'auth_user_json';

  Future<AuthSession?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);
    final userJson = prefs.getString(_userJsonKey);

    if (token == null || refreshToken == null || userJson == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(userJson) as Map<String, dynamic>;
      return AuthSession(
        token: token,
        refreshToken: refreshToken,
        user: AuthUser.fromJson(decoded),
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_refreshTokenKey, session.refreshToken);
    await prefs.setString(_userJsonKey, jsonEncode(session.user.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userJsonKey);
  }
}
