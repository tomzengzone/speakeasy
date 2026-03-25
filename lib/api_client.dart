import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _base = 'http://47.98.225.160/api';
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool includeJson = true}) async {
    final String? token = await getToken();
    return <String, String>{
      if (includeJson) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decodeResponse(
    http.Response response, {
    bool allowEmpty = false,
  }) {
    final String raw = response.body.trim();
    if (raw.isEmpty) {
      if (allowEmpty &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        return <String, dynamic>{'code': 0};
      }
      throw Exception('服务器返回空响应');
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return <String, dynamic>{'code': 0, 'data': decoded};
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final http.Response response = await http
        .get(Uri.parse('$_base$path'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final http.Response response = await http
        .post(
          Uri.parse('$_base$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final http.Response response = await http
        .put(
          Uri.parse('$_base$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> sendSmsCode(String phone) =>
      _post('/auth/sms/send', <String, dynamic>{'phone': phone});

  static Future<Map<String, dynamic>> verifySmsCode(
    String phone,
    String code,
  ) => _post('/auth/sms/verify', <String, dynamic>{
    'phone': phone,
    'code': code,
  });

  static Future<Map<String, dynamic>> refreshToken() =>
      _post('/auth/refresh', const <String, dynamic>{});

  static Future<Map<String, dynamic>> getMe() => _get('/user/me');

  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
      _put('/user/me', data);

  static Future<Map<String, dynamic>> getStats() => _get('/user/stats');

  static Future<Map<String, dynamic>> recordSession({
    required int durationSeconds,
    required int score,
  }) => _post('/user/stats/session', <String, dynamic>{
    'durationSeconds': durationSeconds,
    'score': score,
  });

  static Future<String> uploadAvatar(File imageFile) async {
    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/user/me/avatar'),
    );
    final String? token = await getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath('avatar', imageFile.path),
    );
    final http.StreamedResponse response = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final Map<String, dynamic> body = _decodeResponse(
      http.Response(
        await response.stream.bytesToString(),
        response.statusCode,
        headers: response.headers,
      ),
    );
    final Map<String, dynamic> data = _asMap(body['data']);
    return (data['avatarUrl'] as String?) ?? '';
  }

  static Future<Map<String, dynamic>> getCards() => _get('/cards');

  static Future<void> updateCardState(
    String cardId, {
    bool? saved,
    bool? dismissed,
    bool? completed,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (saved != null) body['saved'] = saved;
    if (dismissed != null) body['dismissed'] = dismissed;
    if (completed != null) body['completed'] = completed;
    await _put('/cards/$cardId/state', body);
  }

  static Future<String> createAiSession({
    required String sceneTitle,
    required String sceneGoal,
    required String npcName,
    required String npcRole,
    required String environment,
    required String challenge,
  }) async {
    final Map<String, dynamic> response =
        await _post('/ai/sessions', <String, dynamic>{
          'sceneTitle': sceneTitle,
          'sceneGoal': sceneGoal,
          'npcName': npcName,
          'npcRole': npcRole,
          'environment': environment,
          'challenge': challenge,
        });
    final Map<String, dynamic> data = _asMap(response['data']);
    return (data['sessionId'] as String?) ?? '';
  }

  static Future<String> sendMessage(String sessionId, String text) async {
    final Map<String, dynamic> response = await _post(
      '/ai/sessions/$sessionId/message',
      <String, dynamic>{'text': text},
    );
    final Map<String, dynamic> data = _asMap(response['data']);
    return (data['reply'] as String?) ?? '';
  }

  static Future<Uint8List> tts(String text, {String voice = 'Cherry'}) async {
    final http.Response response = await http
        .post(
          Uri.parse('$_base/ai/tts'),
          headers: await _headers(),
          body: jsonEncode(<String, dynamic>{'text': text, 'voice': voice}),
        )
        .timeout(const Duration(seconds: 20));
    return response.bodyBytes;
  }

  static Future<Map<String, dynamic>> scoreAudio(
    File audioFile,
    String refText, {
    String? cardId,
  }) async {
    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/ai/score'),
    );
    final String? token = await getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath('audio', audioFile.path),
    );
    request.fields['refText'] = refText;
    if (cardId != null && cardId.isNotEmpty) {
      request.fields['cardId'] = cardId;
    }
    final http.StreamedResponse response = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final Map<String, dynamic> body = _decodeResponse(
      http.Response(
        await response.stream.bytesToString(),
        response.statusCode,
        headers: response.headers,
      ),
    );
    return _asMap(body['data']);
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }
}
