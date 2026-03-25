import 'dart:async';
import 'dart:io' as dart_io;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart'; // still used by startRecording
import 'package:record/record.dart';

import 'package:speakeasy/services/api_client.dart';

class AudioService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _playingUrl;
  String? _lastRecordingPath;

  AudioService() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.85);
    _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      _isPlaying = false;
      _playingUrl = null;
      notifyListeners();
    });
    _tts.setErrorHandler((msg) {
      _isPlaying = false;
      _playingUrl = null;
      notifyListeners();
    });
  }

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get playingUrl => _playingUrl;
  String? get lastRecordingPath => _lastRecordingPath;

  Future<bool> requestPermission() {
    return _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    final bool hasPermission = await requestPermission();
    if (!hasPermission) return;

    final String directoryPath = (await getTemporaryDirectory()).path;
    final String path =
        '$directoryPath/speakeasy_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    _isRecording = true;
    notifyListeners();
  }

  Future<String?> stopRecording() async {
    final String? path = await _recorder.stop();
    _isRecording = false;
    _lastRecordingPath = path;
    notifyListeners();
    return path;
  }

  Future<void> playUrl(String url) async {
    if (_isPlaying && _playingUrl == url) {
      await _player.stop();
      _isPlaying = false;
      _playingUrl = null;
      notifyListeners();
      return;
    }

    await _player.stop();
    await _player.setUrl(url);
    _isPlaying = true;
    _playingUrl = url;
    notifyListeners();

    try {
      await _player.play();
    } finally {
      if (_playingUrl == url) {
        _isPlaying = false;
        _playingUrl = null;
        notifyListeners();
      }
    }
  }

  /// 播放 TTS：优先调用后端 CosyVoice API，失败时回退到系统 TTS
  Future<void> playTts(String text) async {
    final String ttsKey = 'tts_${text.hashCode}';

    // 再次点击同一段文字 → 停止
    if (_isPlaying && _playingUrl == ttsKey) {
      await _player.stop();
      await _tts.stop();
      _isPlaying = false;
      _playingUrl = null;
      notifyListeners();
      return;
    }

    // 停止其他正在播放的内容
    await _player.stop();
    await _tts.stop();

    _isPlaying = true;
    _playingUrl = ttsKey;
    notifyListeners();

    try {
      // 优先调用后端 CosyVoice API
      final Uint8List audioBytes = await ApiClient.tts(text);
      if (audioBytes.isNotEmpty) {
        final String directoryPath = (await getTemporaryDirectory()).path;
        final String filePath =
            '$directoryPath/tts_${DateTime.now().millisecondsSinceEpoch}.wav';
        final dart_io.File file = dart_io.File(filePath);
        await file.writeAsBytes(audioBytes);
        await _player.setFilePath(filePath);
        await _player.play();
        // 等待播放完成（加超时防止异常音频卡死）
        try {
          await _player.playerStateStream
              .firstWhere(
                (PlayerState state) =>
                    state.processingState == ProcessingState.completed,
              )
              .timeout(const Duration(seconds: 120));
        } on TimeoutException {
          await _player.stop();
        }
      } else {
        // 后端无数据，回退到系统 TTS
        await _tts.speak(text);
      }
    } catch (_) {
      // CosyVoice 失败，回退到系统 TTS
      try {
        await _tts.speak(text);
      } catch (_) {
        // ignore
      }
    } finally {
      if (_playingUrl == ttsKey) {
        _isPlaying = false;
        _playingUrl = null;
        notifyListeners();
      }
    }
  }

  Future<void> playFile(String path) async {
    if (_isPlaying && _playingUrl == path) {
      await _player.stop();
      _isPlaying = false;
      _playingUrl = null;
      notifyListeners();
      return;
    }

    await _player.stop();
    await _player.setFilePath(path);
    _isPlaying = true;
    _playingUrl = path;
    notifyListeners();

    try {
      await _player.play();
    } finally {
      if (_playingUrl == path) {
        _isPlaying = false;
        _playingUrl = null;
        notifyListeners();
      }
    }
  }

  /// 播放 PCM 音频数据用于实时语音（Qwen3-Omni 输出 24kHz 16bit mono PCM）
  Future<void> playRealtimeAudio(Uint8List pcmBytes) async {
    await _player.stop();
    _isPlaying = true;
    notifyListeners();

    try {
      final String dirPath = (await getTemporaryDirectory()).path;
      final String wavPath =
          '$dirPath/rt_${DateTime.now().millisecondsSinceEpoch}.wav';

      // PCM -> WAV：写 44 字节 header
      const int sampleRate = 24000;
      const int bitsPerSample = 16;
      const int channels = 1;
      final int dataSize = pcmBytes.length;
      final int byteRate = sampleRate * channels * bitsPerSample ~/ 8;
      final int blockAlign = channels * bitsPerSample ~/ 8;

      final ByteData header = ByteData(44);
      header.setUint8(0, 0x52);
      header.setUint8(1, 0x49);
      header.setUint8(2, 0x46);
      header.setUint8(3, 0x46);
      header.setUint32(4, 36 + dataSize, Endian.little);
      header.setUint8(8, 0x57);
      header.setUint8(9, 0x41);
      header.setUint8(10, 0x56);
      header.setUint8(11, 0x45);
      header.setUint8(12, 0x66);
      header.setUint8(13, 0x6D);
      header.setUint8(14, 0x74);
      header.setUint8(15, 0x20);
      header.setUint32(16, 16, Endian.little);
      header.setUint16(20, 1, Endian.little);
      header.setUint16(22, channels, Endian.little);
      header.setUint32(24, sampleRate, Endian.little);
      header.setUint32(28, byteRate, Endian.little);
      header.setUint16(32, blockAlign, Endian.little);
      header.setUint16(34, bitsPerSample, Endian.little);
      header.setUint8(36, 0x64);
      header.setUint8(37, 0x61);
      header.setUint8(38, 0x74);
      header.setUint8(39, 0x61);
      header.setUint32(40, dataSize, Endian.little);

      final dart_io.File wavFile = dart_io.File(wavPath);
      final dart_io.IOSink sink = wavFile.openWrite();
      sink.add(header.buffer.asUint8List());
      sink.add(pcmBytes);
      await sink.close();

      await _player.setFilePath(wavPath);
      await _player.play();

      try {
        await _player.playerStateStream
            .firstWhere(
              (PlayerState state) =>
                  state.processingState == ProcessingState.completed,
            )
            .timeout(const Duration(seconds: 120));
      } on TimeoutException {
        await _player.stop();
      }
    } catch (e) {
      debugPrint('[AudioService] playRealtimeAudio error: $e');
    } finally {
      _isPlaying = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    unawaited(_tts.stop());
    super.dispose();
  }
}

class AudioServiceScope extends InheritedNotifier<AudioService> {
  const AudioServiceScope({
    super.key,
    required AudioService service,
    required super.child,
  }) : super(notifier: service);

  static AudioService of(BuildContext context) {
    final AudioServiceScope? scope = context
        .dependOnInheritedWidgetOfExactType<AudioServiceScope>();
    assert(scope != null, 'AudioServiceScope not found in context');
    return scope!.notifier!;
  }
}
