import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    final fromDotenv = dotenv.env['API_BASE_URL']?.trim();
    if (fromDotenv != null && fromDotenv.isNotEmpty) {
      return _normalizeBaseUrl(fromDotenv);
    }

    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.trim().isNotEmpty) {
      return _normalizeBaseUrl(fromDefine);
    }

    return 'http://localhost:3000';
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
