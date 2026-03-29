import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_paths.dart';
import 'auth_models.dart';

class AuthApiClient {
  AuthApiClient({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final body = await _post(ApiPaths.authLogin, {
      'email': email,
      'password': password,
    });
    final data = _extractDataEnvelope(body);
    return AuthSession.fromJson(data);
  }

  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
    required String timezone,
  }) async {
    final body = await _post(ApiPaths.authRegister, {
      'username': username,
      'email': email,
      'password': password,
      'timezone': timezone,
    });
    final data = _extractDataEnvelope(body);
    return AuthSession.fromJson(data);
  }

  Future<AuthUser> fetchMe({required String token}) async {
    final body = await _get(
      ApiPaths.authMe,
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _extractDataEnvelope(body);
    final userJson = (data['user'] ?? data) as Map<String, dynamic>;
    return AuthUser.fromJson(userJson);
  }

  Future<AuthSession> refresh({required String refreshToken}) async {
    final body = await _post(ApiPaths.authRefresh, {
      'refresh_token': refreshToken,
    });
    final data = _extractDataEnvelope(body);
    return AuthSession.fromJson(data);
  }

  Future<void> logout({required String token}) async {
    await _post(
      ApiPaths.authLogout,
      const {},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload, {
    Map<String, String> headers = const {},
  }) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...headers,
      },
      body: jsonEncode(payload),
    );

    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    final response = await _httpClient.get(
      _uri(path),
      headers: {'Accept': 'application/json', ...headers},
    );
    return _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthError(
        'Invalid response from auth server.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final nestedError = body['error'];
      final nestedMessage = nestedError is Map<String, dynamic>
          ? nestedError['message'] as String?
          : null;
      throw AuthError(
        body['message'] as String? ??
            nestedMessage ??
            'Authentication request failed.',
        statusCode: response.statusCode,
      );
    }

    return body;
  }

  Map<String, dynamic> _extractDataEnvelope(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return body;
  }
}
