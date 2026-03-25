import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl => _getRequired('API_BASE_URL');

  static String get envName => _getOptional('ENV', fallback: 'production');

  static String get openAiApiKey => _getOptional('OPENAI_API_KEY');

  static bool get isDevelopment => envName == 'development';

  static bool get isProduction => envName == 'production';

  static String _getRequired(String key) {
    final String value = dotenv.maybeGet(key)?.trim() ?? '';
    if (value.isEmpty) {
      throw StateError('Missing required env var: $key');
    }
    return value;
  }

  static String _getOptional(String key, {String fallback = ''}) {
    final String value = dotenv.maybeGet(key)?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }
}
