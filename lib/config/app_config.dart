import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _envDefine = String.fromEnvironment('ENV');
  static const String _ttsVoiceDefine = String.fromEnvironment('TTS_VOICE');
  static const String _interviewerTtsVoiceDefine = String.fromEnvironment(
    'TTS_INTERVIEWER_VOICE',
  );
  static const String _candidateTtsVoiceDefine = String.fromEnvironment(
    'TTS_CANDIDATE_VOICE',
  );
  static const String _realtimeVoiceModelDefine = String.fromEnvironment(
    'REALTIME_VOICE_MODEL',
  );
  static const String _chatModelDefine = String.fromEnvironment('CHAT_MODEL');
  static const String _feedbackModelDefine = String.fromEnvironment(
    'FEEDBACK_MODEL',
  );
  static const String _enableTestPhoneLoginDefine = String.fromEnvironment(
    'ENABLE_TEST_PHONE_LOGIN',
  );
  static const String _enableBackendTrainingDefine = String.fromEnvironment(
    'ENABLE_BACKEND_TRAINING',
  );

  static String get apiBaseUrl => _getRequired('API_BASE_URL');

  static String get envName => _getOptional('ENV', fallback: 'production');

  @Deprecated('AI provider secrets must stay on the backend, not in the app.')
  static String get openAiApiKey => _getOptional('OPENAI_API_KEY');

  /// DashScope API Key（后端代理使用）
  @Deprecated('AI provider secrets must stay on the backend, not in the app.')
  static String get dashscopeApiKey => _getOptional('DASHSCOPE_API_KEY');

  /// CosyVoice TTS 音色
  static String get ttsVoice => _getOptional('TTS_VOICE', fallback: 'Ethan');

  /// 听一听播放器：面试官音色
  static String get interviewerTtsVoice =>
      _getOptional('TTS_INTERVIEWER_VOICE', fallback: 'Cherry');

  /// 听一听播放器：候选人音色
  static String get candidateTtsVoice =>
      _getOptional('TTS_CANDIDATE_VOICE', fallback: ttsVoice);

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

  static bool get enableTestPhoneLogin =>
      _getOptional('ENABLE_TEST_PHONE_LOGIN').toLowerCase() == 'true';

  static bool get enableBackendTraining =>
      _getOptional('ENABLE_BACKEND_TRAINING').toLowerCase() == 'true';

  static String _getRequired(String key) {
    final String value = _getOptional(key);
    if (value.isEmpty) {
      throw StateError('Missing required env var: $key');
    }
    return value;
  }

  static String _getOptional(String key, {String fallback = ''}) {
    final String definedValue = _definedValueFor(key).trim();
    if (definedValue.isNotEmpty) {
      return definedValue;
    }

    final String value = _dotenvValueFor(key);
    return value.isEmpty ? fallback : value;
  }

  static String _dotenvValueFor(String key) {
    try {
      return dotenv.maybeGet(key)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static String _definedValueFor(String key) {
    return switch (key) {
      'API_BASE_URL' => _apiBaseUrlDefine,
      'ENV' => _envDefine,
      'TTS_VOICE' => _ttsVoiceDefine,
      'TTS_INTERVIEWER_VOICE' => _interviewerTtsVoiceDefine,
      'TTS_CANDIDATE_VOICE' => _candidateTtsVoiceDefine,
      'REALTIME_VOICE_MODEL' => _realtimeVoiceModelDefine,
      'CHAT_MODEL' => _chatModelDefine,
      'FEEDBACK_MODEL' => _feedbackModelDefine,
      'ENABLE_TEST_PHONE_LOGIN' => _enableTestPhoneLoginDefine,
      'ENABLE_BACKEND_TRAINING' => _enableBackendTrainingDefine,
      _ => '',
    };
  }
}
