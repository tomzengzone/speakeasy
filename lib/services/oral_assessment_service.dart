import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/services/api_client.dart';

class OralAssessmentService {
  OralAssessmentService._();

  static const MethodChannel _channel = MethodChannel(
    'speakeasy/oral_assessment',
  );

  static Future<PronunciationScore?> scorePronunciation({
    required String audioPath,
    required String expectedText,
    String coreType = 'en.sent.score',
  }) async {
    if (kIsWeb || !Platform.isIOS) {
      return null;
    }

    final Map<String, dynamic> auth;
    try {
      auth = await ApiClient.fetchOralAssessmentAuth();
    } catch (error) {
      debugPrint('[OralAssessment] authorization unavailable: $error');
      return null;
    }
    final String appId = _stringValue(auth, const <String>[
      'appId',
      'appid',
      'app_id',
    ]);
    final String warrantId = _stringValue(auth, const <String>[
      'warrantId',
      'warrant_id',
    ]);
    final String authTimeout = _stringValue(auth, const <String>[
      'authTimeout',
      'expireAt',
      'expire_at',
      'expiresAt',
      'expires_at',
    ]);
    final String userId = _stringValue(auth, const <String>[
      'userId',
      'user_id',
    ]);
    final String appSecret = _stringValue(auth, const <String>[
      'appSecret',
      'app_secret',
      'secretKey',
      'secret_key',
    ]);
    if (appId.isEmpty || warrantId.isEmpty || authTimeout.isEmpty) {
      return null;
    }

    try {
      final Map<dynamic, dynamic>? result = await _channel
          .invokeMapMethod<dynamic, dynamic>('scorePronunciation', {
            'audioPath': audioPath,
            'expectedText': expectedText,
            'appId': appId,
            'warrantId': warrantId,
            'authTimeout': authTimeout,
            if (appSecret.isNotEmpty) 'appSecret': appSecret,
            if (userId.isNotEmpty) 'userId': userId,
            'coreType': coreType,
          })
          .timeout(const Duration(seconds: 35));
      return _scoreFromResult(_normalizeMap(result));
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      debugPrint('[OralAssessment] native assessment unavailable: $error');
      return null;
    } catch (error) {
      debugPrint('[OralAssessment] native assessment failed: $error');
      return null;
    }
  }

  static String _stringValue(Map<String, dynamic> source, List<String> keys) {
    for (final String key in keys) {
      final Object? value = source[key];
      if (value == null) {
        continue;
      }
      final String text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static PronunciationScore? _scoreFromResult(Map<String, dynamic> result) {
    if (result.isEmpty) {
      return null;
    }
    final int? overall = _findScore(result, const <String>{
      'overall',
      'overall_score',
      'total_score',
      'final_score',
      'score',
    });
    final int? accuracy = _findScore(result, const <String>{
      'accuracy',
      'accuracy_score',
      'pronunciation',
      'pronunciation_score',
      'pron_score',
      'phone_score',
    });
    final int? fluency = _findScore(result, const <String>{
      'fluency',
      'fluency_score',
      'rhythm',
      'rhythm_score',
    });
    final int? completeness = _findScore(result, const <String>{
      'completeness',
      'complete',
      'complete_score',
      'integrity',
      'integrity_score',
    });
    final int? grammar = _findScore(result, const <String>{
      'grammar',
      'grammar_score',
      'syntax',
      'syntax_score',
    });
    final int? resolvedOverall =
        overall ?? _average(<int?>[accuracy, fluency, completeness, grammar]);
    if (resolvedOverall == null) {
      return null;
    }
    return PronunciationScore(
      overall: resolvedOverall,
      accuracy: accuracy,
      fluency: fluency,
      completeness: completeness,
      grammar: grammar,
      source: 'ali_singsound',
    );
  }

  static int? _findScore(Map<String, dynamic> value, Set<String> keys) {
    for (final MapEntry<String, dynamic> entry in value.entries) {
      final String normalizedKey = _normalizeKey(entry.key);
      if (keys.contains(normalizedKey)) {
        final int? score = _readScore(entry.value);
        if (score != null) {
          return score;
        }
      }
    }
    for (final dynamic child in value.values) {
      if (child is Map<String, dynamic>) {
        final int? score = _findScore(child, keys);
        if (score != null) {
          return score;
        }
      } else if (child is List) {
        for (final dynamic item in child) {
          if (item is Map<String, dynamic>) {
            final int? score = _findScore(item, keys);
            if (score != null) {
              return score;
            }
          }
        }
      }
    }
    return null;
  }

  static int? _readScore(dynamic value) {
    if (value is num) {
      return _normalizeScore(value.toDouble());
    }
    if (value is String) {
      final num? parsed = num.tryParse(value.trim());
      if (parsed != null) {
        return _normalizeScore(parsed.toDouble());
      }
      final dynamic decoded = _tryDecodeJson(value);
      if (decoded is Map) {
        return _findScore(_normalizeMap(decoded), const <String>{
          'overall',
          'score',
        });
      }
    }
    if (value is Map) {
      return _findScore(_normalizeMap(value), const <String>{
        'overall',
        'score',
      });
    }
    return null;
  }

  static int _normalizeScore(double raw) {
    double score = raw;
    if (score >= 0 && score <= 1) {
      score *= 100;
    } else if (score > 1 && score <= 10) {
      score *= 10;
    }
    return score.round().clamp(0, 100).toInt();
  }

  static int? _average(List<int?> values) {
    final List<int> present = values.whereType<int>().toList(growable: false);
    if (present.isEmpty) {
      return null;
    }
    final int total = present.reduce((int a, int b) => a + b);
    return (total / present.length).round().clamp(0, 100).toInt();
  }

  static Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic>? raw) {
    if (raw == null) {
      return <String, dynamic>{};
    }
    return raw.map((dynamic key, dynamic value) {
      return MapEntry<String, dynamic>('$key', _normalizeValue(value));
    });
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      return _normalizeMap(value);
    }
    if (value is List) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    if (value is String) {
      final dynamic decoded = _tryDecodeJson(value);
      if (decoded is Map || decoded is List) {
        return _normalizeValue(decoded);
      }
    }
    return value;
  }

  static dynamic _tryDecodeJson(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty ||
        (!trimmed.startsWith('{') && !trimmed.startsWith('['))) {
      return null;
    }
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  static String _normalizeKey(String key) {
    return key
        .trim()
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (Match match) => '${match.group(1)}_${match.group(2)}',
        )
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .toLowerCase();
  }
}
