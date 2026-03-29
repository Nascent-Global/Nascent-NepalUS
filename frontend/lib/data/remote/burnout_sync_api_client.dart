import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class SyncApiException implements Exception {
  const SyncApiException({
    required this.statusCode,
    required this.message,
    this.code,
  });

  final int statusCode;
  final String message;
  final String? code;

  bool get isConflict => statusCode == 409;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() =>
      'SyncApiException(status: $statusCode, code: $code, message: $message)';
}

class BurnoutSyncApiClient {
  BurnoutSyncApiClient({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Future<dynamic> request({
    required String method,
    required String path,
    required String token,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $token',
    };
    if (body != null) {
      headers[HttpHeaders.contentTypeHeader] = 'application/json';
    }

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient.get(
            _buildUri(path, query),
            headers: headers,
          );
        case 'POST':
          response = await _httpClient.post(
            _buildUri(path, query),
            headers: headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          );
        case 'PUT':
          response = await _httpClient.put(
            _buildUri(path, query),
            headers: headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          );
        case 'PATCH':
          response = await _httpClient.patch(
            _buildUri(path, query),
            headers: headers,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          );
        default:
          throw UnsupportedError('HTTP method not supported: $method');
      }
    } on SocketException {
      throw const SyncApiException(
        statusCode: 0,
        message: 'No network connection',
      );
    } on http.ClientException catch (error) {
      throw SyncApiException(statusCode: 0, message: error.message);
    }

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
      throw SyncApiException(
        statusCode: response.statusCode,
        message: 'Empty server response',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw SyncApiException(
        statusCode: response.statusCode,
        message: 'Invalid JSON from server',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          throw SyncApiException(
            statusCode: response.statusCode,
            code: error['code'] as String?,
            message:
                (error['message'] as String?) ??
                'Request failed (${response.statusCode})',
          );
        }
      }
      throw SyncApiException(
        statusCode: response.statusCode,
        message: 'Request failed (${response.statusCode})',
      );
    }

    if (decoded is Map<String, dynamic> && decoded['ok'] == true) {
      return decoded['data'];
    }
    return decoded;
  }

  Future<Map<String, dynamic>?> getObject({
    required String path,
    required String token,
    Map<String, String>? query,
  }) async {
    final data = await request(
      method: 'GET',
      path: path,
      token: token,
      query: query,
    );
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    throw const SyncApiException(
      statusCode: 500,
      message: 'Expected object response',
    );
  }

  Future<List<Map<String, dynamic>>> getList({
    required String path,
    required String token,
    Map<String, String>? query,
  }) async {
    final data = await request(
      method: 'GET',
      path: path,
      token: token,
      query: query,
    );
    if (data == null) return const <Map<String, dynamic>>[];
    if (data is! List) {
      throw const SyncApiException(
        statusCode: 500,
        message: 'Expected list response',
      );
    }
    return data.whereType<Map<String, dynamic>>().toList();
  }
}
