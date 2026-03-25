import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl => _getRequired('API_BASE_URL');

  static String get envName => _getOptional('ENV', fallback: 'production');

  static String get openAiApiKey => _getOptional('OPENAI_API_KEY');

  /// DashScope API Key（后端代理使用）
  static String get dashscopeApiKey =>
      _getOptional('DASHSCOPE_API_KEY');

  /// CosyVoice TTS 音色
  static String get ttsVoice =>
      _getOptional('TTS_VOICE', fallback: 'Ethan');

  /// Qwen3-Omni 实时语音模型
  static String get realtimeVoiceModel =>
      _getOptional('REALTIME_VOICE_MODEL', fallback: 'qwen3-omni-realtime');

  /// 对话场景使用的 LLM 模型
  static String get chatModel =>
      _getOptional('CHAT_MODEL', fallback: 'qwen3.5-plus');

  /// 场景反馈使用的 LLM 模型
  static String get feedbackModel =>
      _getOptional('FEEDBACK_MODEL', fallback: 'qwen3.5-flash');

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
