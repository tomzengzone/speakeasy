import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io' as dart_io;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import 'package:speakeasy/config/app_config.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/voice_chat_service.dart';

typedef AudioStreamCallback = void Function(Uint8List pcmBytes);

enum VoiceFeedbackEffect { correct, improve }

class AudioService extends ChangeNotifier {
  static const Duration _defaultTtsRequestTimeout = Duration(seconds: 20);
  static const Duration _autoTtsRequestTimeout = Duration(seconds: 9);
  static const Duration _autoTtsChunkWaitTimeout = Duration(seconds: 11);

  static const MethodChannel _realtimeAudioChannel = MethodChannel(
    'speakeasy/realtime_audio',
  );
  static const MethodChannel _nativeRecorderChannel = MethodChannel(
    'speakeasy/native_recorder',
  );
  static const EventChannel _nativeRecorderStreamChannel = EventChannel(
    'speakeasy/native_recorder_stream',
  );

  AudioRecorder? _recorder;
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _feedbackPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _systemTtsAvailable = true;
  bool _nativeRecorderActive = false;
  final Map<String, String> _ttsAudioFileCache = <String, String>{};

  bool _isRecording = false;
  StreamSubscription<Uint8List>? _audioStreamSub;
  StreamSubscription<dynamic>? _nativeRecorderStreamSub;
  bool _isStreamRecording = false;
  bool _isPlaying = false;
  int _playbackTicket = 0;

  /// 实时音频缓冲区
  final List<int> _realtimeAudioBuffer = [];
  final List<int> _realtimeStreamingBuffer = [];
  Future<void> _realtimeAppendChain = Future<void>.value();
  ConcatenatingAudioSource? _realtimeConcatSource;
  final List<String> _realtimePendingPlaybackFiles = <String>[];
  Future<void> _nativeRealtimeChain = Future<void>.value();
  bool _nativeRealtimeStarted = false;
  bool _nativeRealtimeStartQueued = false;

  /// 当前实时音频格式
  String _realtimeAudioFormat = 'pcm';
  String _realtimeStreamingFormat = 'pcm';
  String? _playingUrl;
  String? _lastRecordingPath;

  static const int _realtimeSegmentTargetBytes = 48000;
  static const int _realtimeStartSegmentThreshold = 3;
  static const int _realtimeStartByteThreshold = 48000;
  static const int _maxManagedTempAudioFiles = 120;

  AudioService() {
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
    unawaited(_configureSystemTts());
  }

  bool get isRecording => _isRecording;
  bool get isStreamRecording => _isStreamRecording;
  bool get isPlaying => _isPlaying;
  Duration get playbackPosition => _player.position;
  Duration? get playbackDuration => _player.duration;
  Stream<Duration> get playbackPositionStream => _player.positionStream;
  Stream<Duration?> get playbackDurationStream => _player.durationStream;
  bool get hasRealtimeAudioBuffered => _realtimeAudioBuffer.isNotEmpty;
  String? get playingUrl => _playingUrl;
  String? get lastRecordingPath => _lastRecordingPath;
  AudioRecorder get _recordPlugin => _recorder ??= AudioRecorder();
  bool get _shouldUseNativeRecorder =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get _shouldUseNativeRealtimePcm =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<dart_io.Directory> _temporaryAudioDirectory() async {
    final dart_io.Directory directory = dart_io.Directory(
      '${dart_io.Directory.systemTemp.path}/speakeasy_audio',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<bool> requestPermission() async {
    if (_shouldUseNativeRecorder) {
      return _requestNativeRecorderPermission();
    }
    try {
      return await _recordPlugin.hasPermission();
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> startRecording({AudioStreamCallback? onPcmData}) async {
    final bool hasPermission = await requestPermission();
    if (!hasPermission) return;

    final String directoryPath = (await _temporaryAudioDirectory()).path;
    final String extension = _shouldUseNativeRecorder ? 'wav' : 'm4a';
    final String path =
        '$directoryPath/speakeasy_${DateTime.now().millisecondsSinceEpoch}.$extension';
    unawaited(_pruneManagedTempAudioFiles());

    if (_shouldUseNativeRecorder) {
      if (onPcmData != null) {
        await _startNativeRecorderStream(onPcmData);
      }
      await _startNativeRecording(path);
    } else {
      await _recordPlugin.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
    }

    _isRecording = true;
    notifyListeners();
  }

  Future<String?> stopRecording() async {
    final String? path = _nativeRecorderActive
        ? await _stopNativeRecording()
        : await _recordPlugin.stop();
    await _nativeRecorderStreamSub?.cancel();
    _nativeRecorderStreamSub = null;
    _isRecording = false;
    _lastRecordingPath = path;
    notifyListeners();
    return path;
  }

  Future<void> startStreamRecording(AudioStreamCallback onAudioData) async {
    if (_shouldUseNativeRecorder) {
      await startRecording(onPcmData: onAudioData);
      _isStreamRecording = true;
      notifyListeners();
      return;
    }
    final bool hasPermission = await requestPermission();
    if (!hasPermission) return;

    await _audioStreamSub?.cancel();

    debugPrint(
      '[AudioService] Starting PCM stream ${jsonEncode(<String, Object>{'sampleRate': 16000, 'bitsPerSample': 16, 'numChannels': 1})}',
    );

    final Stream<Uint8List> audioStream = await _recordPlugin.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _audioStreamSub = audioStream.listen(onAudioData);
    _isRecording = true;
    _isStreamRecording = true;
    notifyListeners();
  }

  Future<void> stopStreamRecording() async {
    await _audioStreamSub?.cancel();
    _audioStreamSub = null;
    await _nativeRecorderStreamSub?.cancel();
    _nativeRecorderStreamSub = null;
    if (!_shouldUseNativeRecorder) {
      await _recordPlugin.stop();
    } else if (_nativeRecorderActive) {
      await _stopNativeRecording();
    }
    _isRecording = false;
    _isStreamRecording = false;
    notifyListeners();
  }

  Future<bool> _requestNativeRecorderPermission() async {
    try {
      return await _nativeRecorderChannel.invokeMethod<bool>(
            'requestPermission',
          ) ??
          false;
    } on MissingPluginException {
      debugPrint('[AudioService] native recorder channel unavailable');
      return false;
    } catch (error) {
      debugPrint('[AudioService] native recorder permission failed: $error');
      return false;
    }
  }

  Future<void> _startNativeRecording(String path) async {
    await _nativeRecorderChannel.invokeMethod<void>('startRecording', {
      'path': path,
    });
    _nativeRecorderActive = true;
  }

  Future<void> _startNativeRecorderStream(AudioStreamCallback onPcmData) async {
    await _nativeRecorderStreamSub?.cancel();
    _nativeRecorderStreamSub = _nativeRecorderStreamChannel
        .receiveBroadcastStream()
        .listen(
          (dynamic event) {
            if (event is Uint8List) {
              onPcmData(event);
              return;
            }
            if (event is ByteData) {
              onPcmData(event.buffer.asUint8List());
              return;
            }
            if (event is List<int>) {
              onPcmData(Uint8List.fromList(event));
            }
          },
          onError: (Object error) {
            debugPrint('[AudioService] native recorder stream failed: $error');
          },
        );
  }

  Future<String?> _stopNativeRecording() async {
    try {
      return await _nativeRecorderChannel.invokeMethod<String>('stopRecording');
    } finally {
      _nativeRecorderActive = false;
    }
  }

  Future<void> playUrl(String url) async {
    final int ticket = ++_playbackTicket;
    if (_isPlaying && _playingUrl == url) {
      await _player.stop();
      _isPlaying = false;
      _playingUrl = null;
      notifyListeners();
      return;
    }

    await _player.stop();
    String resolvedUrl = url;
    try {
      await _player.setUrl(resolvedUrl);
    } catch (error) {
      final String? fallbackUrl = _httpFallbackUrl(url, error);
      if (fallbackUrl == null) rethrow;
      resolvedUrl = fallbackUrl;
      await _player.setUrl(resolvedUrl);
    }
    _isPlaying = true;
    _playingUrl = url;
    notifyListeners();

    try {
      await _player.play();
    } finally {
      if (_playbackTicket == ticket && _playingUrl == url) {
        _isPlaying = false;
        _playingUrl = null;
        notifyListeners();
      }
    }
  }

  String? _httpFallbackUrl(String url, Object error) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return null;
    final String message = error.toString().toLowerCase();
    final bool certificateError =
        message.contains('certificate') || message.contains('-1202');
    if (!certificateError) return null;
    return uri.replace(scheme: 'http').toString();
  }

  Future<bool> playCachedTts(
    String text, {
    String? voice,
    String? sceneId,
    String? targetLevel,
    String? nodeId,
  }) async {
    final String cleanedText = text.trim();
    if (cleanedText.isEmpty) {
      return false;
    }
    final String resolvedVoice = (voice?.trim().isNotEmpty ?? false)
        ? voice!.trim()
        : AppConfig.ttsVoice;
    final String requestKey =
        'tts_cache_${resolvedVoice}_${sceneId ?? ''}_${targetLevel ?? ''}_${nodeId ?? ''}_${cleanedText.hashCode}';
    final int ticket = ++_playbackTicket;

    if (_isPlaying && _playingUrl == requestKey) {
      await stopPlayback(clearRealtimeBuffer: false);
      return false;
    }

    await _player.stop();
    await _stopSystemTts();
    _isPlaying = true;
    _playingUrl = requestKey;
    notifyListeners();

    try {
      final String? audioUrl = await ApiClient.ttsCacheUrl(
        cleanedText,
        voice: resolvedVoice,
        sceneId: sceneId,
        targetLevel: targetLevel,
        nodeId: nodeId,
      );
      if (_playbackTicket != ticket) {
        return false;
      }
      if (audioUrl != null && audioUrl.isNotEmpty) {
        await playUrl(audioUrl);
        return true;
      }
    } catch (error) {
      debugPrint('[AudioService] cached TTS url failed: $error');
    } finally {
      if (_playbackTicket == ticket && _playingUrl == requestKey) {
        _isPlaying = false;
        _playingUrl = null;
        notifyListeners();
      }
    }

    if (_playbackTicket != ticket) {
      return false;
    }
    return playTts(
      cleanedText,
      voice: resolvedVoice,
      allowSystemFallback: false,
    );
  }

  /// 播放 TTS：优先调用后端 CosyVoice API，失败时回退到系统 TTS
  Future<bool> playTts(
    String text, {
    String? voice,
    bool allowSystemFallback = true,
    int maxAttempts = 2,
    Duration requestTimeout = _defaultTtsRequestTimeout,
  }) async {
    final String ttsKey = 'tts_${text.hashCode}';
    final int ticket = ++_playbackTicket;
    final String resolvedVoice = (voice?.trim().isNotEmpty ?? false)
        ? voice!.trim()
        : AppConfig.ttsVoice;
    debugPrint(
      '[AudioService] playTts start key=$ttsKey voice=$resolvedVoice allowSystemFallback=$allowSystemFallback text="${text.substring(0, text.length.clamp(0, 48))}"',
    );

    // 再次点击同一段文字 → 停止
    if (_isPlaying && _playingUrl == ttsKey) {
      await _player.stop();
      await _stopSystemTts();
      _isPlaying = false;
      _playingUrl = null;
      notifyListeners();
      return false;
    }

    // 停止其他正在播放的内容
    await _player.stop();
    await _stopSystemTts();

    _isPlaying = true;
    _playingUrl = ttsKey;
    notifyListeners();

    try {
      // 优先调用后端 CosyVoice API
      final Uint8List audioBytes = await _requestTtsAudioBytes(
        text,
        voice: resolvedVoice,
        maxAttempts: maxAttempts,
        requestTimeout: requestTimeout,
      );
      if (audioBytes.isNotEmpty) {
        debugPrint(
          '[AudioService] playTts backend audio ready bytes=${audioBytes.length} voice=$resolvedVoice',
        );
        final String directoryPath = (await _temporaryAudioDirectory()).path;
        final String filePath =
            '$directoryPath/tts_${DateTime.now().millisecondsSinceEpoch}.wav';
        final dart_io.File file = dart_io.File(filePath);
        await file.writeAsBytes(audioBytes);
        unawaited(_pruneManagedTempAudioFiles());
        await _player.setFilePath(filePath);
        await _player.play();
        // 等待播放完成（加超时防止异常音频卡死）
        try {
          await _player.playerStateStream
              .firstWhere(
                (PlayerState state) =>
                    _playbackTicket != ticket ||
                    state.processingState == ProcessingState.completed,
              )
              .timeout(const Duration(seconds: 120));
        } on TimeoutException {
          await _player.stop();
        }
        return true;
      } else if (allowSystemFallback) {
        // 后端无数据，回退到系统 TTS
        debugPrint(
          '[AudioService] TTS backend returned empty bytes, falling back to system TTS',
        );
        final bool spoke = await _speakSystemTts(text);
        if (spoke) {
          debugPrint(
            '[AudioService] system TTS speak invoked from empty backend',
          );
        }
      }
    } catch (error) {
      // CosyVoice 失败，回退到系统 TTS
      debugPrint('[AudioService] TTS backend failed: $error');
      if (allowSystemFallback) {
        final bool spoke = await _speakSystemTts(text);
        if (spoke) {
          debugPrint('[AudioService] system TTS speak invoked from catch');
        }
      }
    } finally {
      if (_playbackTicket == ticket && _playingUrl == ttsKey) {
        _isPlaying = false;
        _playingUrl = null;
        notifyListeners();
      }
    }
    return false;
  }

  Future<bool> playTtsProgressiveBackend(
    String text, {
    String? voice,
    int maxAttempts = 2,
    Duration requestTimeout = _defaultTtsRequestTimeout,
    Duration? chunkWaitTimeout,
    bool prefetchAllChunks = true,
  }) async {
    final String cleanedText = text.trim();
    if (cleanedText.isEmpty) {
      return false;
    }
    final List<String> chunks = _ttsSpeechChunks(cleanedText);
    if (chunks.length <= 1) {
      return playTts(
        cleanedText,
        voice: voice,
        allowSystemFallback: false,
        maxAttempts: maxAttempts,
        requestTimeout: requestTimeout,
      );
    }

    final Stopwatch watch = Stopwatch()..start();
    final String ttsKey = 'tts_progressive_${cleanedText.hashCode}';
    final int ticket = ++_playbackTicket;
    final String resolvedVoice = (voice?.trim().isNotEmpty ?? false)
        ? voice!.trim()
        : AppConfig.ttsVoice;
    debugPrint(
      '[AudioService] playTtsProgressive start chunks=${chunks.length} voice=$resolvedVoice text="${cleanedText.substring(0, cleanedText.length.clamp(0, 48))}"',
    );

    if (_isPlaying && _playingUrl == ttsKey) {
      await _player.stop();
      await _stopSystemTts();
      _isPlaying = false;
      _playingUrl = null;
      notifyListeners();
      return false;
    }

    await _player.stop();
    await _stopSystemTts();

    _isPlaying = true;
    _playingUrl = ttsKey;
    notifyListeners();

    final List<Future<String?>?> pendingFiles = List<Future<String?>?>.filled(
      chunks.length,
      null,
    );
    Future<String?> requestChunkFile(int index) {
      return createTtsAudioFile(
        chunks[index],
        voice: resolvedVoice,
        maxAttempts: maxAttempts,
        requestTimeout: requestTimeout,
      );
    }

    if (prefetchAllChunks) {
      for (int index = 0; index < chunks.length; index += 1) {
        pendingFiles[index] = requestChunkFile(index);
      }
    } else {
      pendingFiles[0] = requestChunkFile(0);
    }
    bool playedAny = false;
    try {
      for (int index = 0; index < chunks.length; index += 1) {
        pendingFiles[index] ??= requestChunkFile(index);
        if (!prefetchAllChunks && index + 1 < chunks.length) {
          pendingFiles[index + 1] ??= requestChunkFile(index + 1);
        }
        String? filePath;
        try {
          final Future<String?> pendingFile = pendingFiles[index]!;
          filePath = chunkWaitTimeout == null
              ? await pendingFile
              : await pendingFile.timeout(chunkWaitTimeout);
        } on TimeoutException {
          debugPrint(
            '[AudioService] playTtsProgressive chunk timeout index=$index played=$playedAny wait=${chunkWaitTimeout?.inMilliseconds ?? 0}ms',
          );
          break;
        }
        if (_playbackTicket != ticket || _playingUrl != ttsKey) {
          return playedAny;
        }
        if (index == 0) {
          debugPrint(
            '[AudioService] playTtsProgressive first audio ready elapsed=${watch.elapsedMilliseconds}ms',
          );
        }
        if (filePath == null || filePath.isEmpty) {
          debugPrint(
            '[AudioService] playTtsProgressive empty chunk file index=$index',
          );
          continue;
        }
        await _player.setFilePath(filePath);
        await _player.play();
        playedAny = true;
        try {
          await _player.playerStateStream
              .firstWhere(
                (PlayerState state) =>
                    _playbackTicket != ticket ||
                    state.processingState == ProcessingState.completed,
              )
              .timeout(const Duration(seconds: 120));
        } on TimeoutException {
          await _player.stop();
        }
      }
    } catch (error) {
      debugPrint('[AudioService] playTtsProgressive backend failed: $error');
    } finally {
      if (_playbackTicket == ticket && _playingUrl == ttsKey) {
        _isPlaying = false;
        _playingUrl = null;
        notifyListeners();
      }
      debugPrint(
        '[AudioService] playTtsProgressive done played=$playedAny elapsed=${watch.elapsedMilliseconds}ms',
      );
    }
    return playedAny;
  }

  Future<bool> playAutoAssistantTts(String text, {String? voice}) {
    return playTtsProgressiveBackend(
      text,
      voice: voice,
      maxAttempts: 1,
      requestTimeout: _autoTtsRequestTimeout,
      chunkWaitTimeout: _autoTtsChunkWaitTimeout,
      prefetchAllChunks: true,
    );
  }

  Future<void> prewarmAutoAssistantTts(String text, {String? voice}) async {
    final List<String> chunks = _ttsSpeechChunks(text.trim());
    if (chunks.isEmpty) {
      return;
    }
    final String resolvedVoice = (voice?.trim().isNotEmpty ?? false)
        ? voice!.trim()
        : AppConfig.ttsVoice;
    final Iterable<String> warmupChunks = chunks.take(3);
    await Future.wait(
      warmupChunks.map(
        (String chunk) =>
            createTtsAudioFile(
              chunk,
              voice: resolvedVoice,
              maxAttempts: 1,
              requestTimeout: _autoTtsRequestTimeout,
            ).catchError((Object error) {
              debugPrint('[AudioService] auto TTS prewarm skipped: $error');
              return null;
            }),
      ),
    );
  }

  Future<Uint8List> _requestTtsAudioBytes(
    String text, {
    required String voice,
    int maxAttempts = 2,
    Duration requestTimeout = _defaultTtsRequestTimeout,
  }) async {
    final int safeMaxAttempts = math.max(1, maxAttempts);
    Object? lastError;
    for (int attempt = 1; attempt <= safeMaxAttempts; attempt++) {
      try {
        final Uint8List audioBytes = await ApiClient.tts(
          text,
          voice: voice,
          timeout: requestTimeout,
        );
        if (audioBytes.isNotEmpty) {
          return audioBytes;
        }
        debugPrint(
          '[AudioService] TTS request returned empty bytes on attempt $attempt/$safeMaxAttempts',
        );
      } catch (error) {
        lastError = error;
        debugPrint(
          '[AudioService] TTS request failed on attempt $attempt/$safeMaxAttempts: $error',
        );
      }
      if (attempt < safeMaxAttempts) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    return Uint8List(0);
  }

  Future<String?> createTtsAudioFile(
    String text, {
    String? voice,
    int maxAttempts = 2,
    Duration requestTimeout = _defaultTtsRequestTimeout,
  }) async {
    final String cleanedText = text.trim();
    if (cleanedText.isEmpty) {
      return null;
    }
    final String resolvedVoice = (voice?.trim().isNotEmpty ?? false)
        ? voice!.trim()
        : AppConfig.ttsVoice;
    final String cacheKey = '$resolvedVoice|$cleanedText';
    final String? cachedPath = _ttsAudioFileCache[cacheKey];
    if (cachedPath != null && await dart_io.File(cachedPath).exists()) {
      debugPrint('[AudioService] TTS cache hit voice=$resolvedVoice');
      return cachedPath;
    }
    if (cachedPath != null) {
      _ttsAudioFileCache.remove(cacheKey);
    }
    final Uint8List audioBytes = await _requestTtsAudioBytes(
      cleanedText,
      voice: resolvedVoice,
      maxAttempts: maxAttempts,
      requestTimeout: requestTimeout,
    );
    if (audioBytes.isEmpty) {
      return null;
    }
    final String directoryPath = (await _temporaryAudioDirectory()).path;
    final String filePath =
        '$directoryPath/tts_${DateTime.now().microsecondsSinceEpoch}.wav';
    final dart_io.File file = dart_io.File(filePath);
    await file.writeAsBytes(audioBytes);
    _ttsAudioFileCache[cacheKey] = filePath;
    while (_ttsAudioFileCache.length > 40) {
      _ttsAudioFileCache.remove(_ttsAudioFileCache.keys.first);
    }
    unawaited(_pruneManagedTempAudioFiles());
    return filePath;
  }

  List<String> _ttsSpeechChunks(String text) {
    final String normalized = text
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
    if (normalized.length <= 70) {
      return <String>[normalized];
    }
    final List<String> chunks = <String>[];
    final StringBuffer buffer = StringBuffer();
    for (int index = 0; index < normalized.length; index += 1) {
      final String char = normalized[index];
      buffer.write(char);
      final bool hardBreak = char == '\n';
      final bool sentenceBreak = '。！？!?；;'.contains(char);
      final bool softBreak = '，,'.contains(char) && buffer.length >= 46;
      if (hardBreak || sentenceBreak || softBreak || buffer.length >= 86) {
        final String chunk = buffer.toString().trim();
        if (chunk.isNotEmpty) {
          chunks.add(chunk);
        }
        buffer.clear();
      }
    }
    final String tail = buffer.toString().trim();
    if (tail.isNotEmpty) {
      chunks.add(tail);
    }
    if (chunks.length <= 1) {
      return <String>[normalized];
    }
    return chunks
        .map((String chunk) => chunk.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((String chunk) => chunk.isNotEmpty)
        .toList(growable: false);
  }

  Future<String?> persistPcmChunksAsWav(
    List<Uint8List> chunks, {
    int sampleRate = 16000,
    String prefix = 'user_voice',
  }) async {
    if (chunks.isEmpty) {
      return null;
    }
    final BytesBuilder builder = BytesBuilder(copy: false);
    for (final Uint8List chunk in chunks) {
      if (chunk.isNotEmpty) {
        builder.add(chunk);
      }
    }
    final Uint8List pcmBytes = builder.takeBytes();
    if (pcmBytes.isEmpty) {
      return null;
    }
    return _writePcmAudioFile(pcmBytes, sampleRate: sampleRate, prefix: prefix);
  }

  Future<int?> getAudioDurationSeconds(String path) async {
    final String cleanedPath = path.trim();
    if (cleanedPath.isEmpty) {
      return null;
    }
    final AudioPlayer probePlayer = AudioPlayer();
    try {
      await probePlayer.setFilePath(cleanedPath);
      final Duration? duration = probePlayer.duration;
      if (duration == null || duration.inMilliseconds <= 0) {
        return null;
      }
      return math.max(1, (duration.inMilliseconds / 1000).round());
    } catch (_) {
      return null;
    } finally {
      await probePlayer.dispose();
    }
  }

  Future<void> playFile(String path) async {
    debugPrint('[AudioService] playFile path=$path');
    final int ticket = ++_playbackTicket;
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
      if (_playbackTicket == ticket && _playingUrl == path) {
        _isPlaying = false;
        _playingUrl = null;
        notifyListeners();
      }
    }
  }

  Future<void> playVoiceFeedbackEffect(VoiceFeedbackEffect effect) async {
    final String assetPath = switch (effect) {
      VoiceFeedbackEffect.correct => 'assets/audio/feedback_correct.wav',
      VoiceFeedbackEffect.improve => 'assets/audio/feedback_improve.wav',
    };
    try {
      await _feedbackPlayer.stop();
      await _feedbackPlayer.setAsset(assetPath);
      await _feedbackPlayer.setVolume(
        effect == VoiceFeedbackEffect.correct ? 0.72 : 0.62,
      );
      await _feedbackPlayer.play();
    } catch (error) {
      debugPrint('[AudioService] feedback effect skipped: $error');
    }
  }

  /// 添加实时音频数据到缓冲区（支持 PCM/WAV）
  void addRealtimeAudioChunk(RealtimeAudioChunk chunk) {
    final String format = chunk.format.trim().isEmpty ? 'pcm' : chunk.format;
    if (_realtimeAudioBuffer.isNotEmpty && _realtimeAudioFormat != format) {
      debugPrint(
        '[AudioService] Realtime audio format changed mid-stream: $_realtimeAudioFormat -> $format, resetting buffer',
      );
      _realtimeAudioBuffer.clear();
    }
    _realtimeAudioFormat = format;
    _realtimeAudioBuffer.addAll(chunk.bytes);
    debugPrint(
      '[AudioService] Realtime audio chunk received, format=$format, size=${chunk.bytes.length}, total buffered=${_realtimeAudioBuffer.length}',
    );
  }

  void enqueueRealtimeAudioChunk(RealtimeAudioChunk chunk) {
    addRealtimeAudioChunk(chunk);
    final String format = chunk.format.trim().isEmpty ? 'pcm' : chunk.format;
    if (_shouldUseNativeRealtimePcm && format == 'pcm') {
      if (_nativeRealtimeStarted) {
        _nativeRealtimeChain = _nativeRealtimeChain.then(
          (_) => _appendNativeRealtimePcm(Uint8List.fromList(chunk.bytes)),
        );
      } else {
        _realtimeStreamingBuffer.addAll(chunk.bytes);
      }
      if (!_nativeRealtimeStarted &&
          !_nativeRealtimeStartQueued &&
          _realtimeStreamingBuffer.length >= _realtimeStartByteThreshold) {
        _nativeRealtimeStartQueued = true;
        _nativeRealtimeChain = _nativeRealtimeChain.then(
          (_) => _startNativeRealtimePlayback(),
        );
      }
      return;
    }
    if (_realtimeStreamingBuffer.isNotEmpty &&
        _realtimeStreamingFormat != format) {
      unawaited(_flushRealtimeStreamingSegment());
    }
    _realtimeStreamingFormat = format;
    _realtimeStreamingBuffer.addAll(chunk.bytes);
    if (_realtimeStreamingBuffer.length >= _realtimeSegmentTargetBytes) {
      unawaited(_flushRealtimeStreamingSegment());
    }
  }

  /// 刷新播放缓冲的实时音频（收到 turn done / speaking=false 时调用）
  Future<String?> flushRealtimeAudio() async {
    final int ticket = ++_playbackTicket;
    debugPrint(
      '[AudioService] flushRealtimeAudio called, format=$_realtimeAudioFormat, buffer size=${_realtimeAudioBuffer.length}',
    );
    if (_realtimeAudioBuffer.isEmpty) {
      return null;
    }
    if (_isStreamRecording) {
      debugPrint('[AudioService] Stopping stream recording before playback');
      await stopStreamRecording();
    }
    final Uint8List fullAudio = Uint8List.fromList(_realtimeAudioBuffer);
    final String audioFormat = _realtimeAudioFormat;
    _realtimeAudioBuffer.clear();
    _realtimeAudioFormat = 'pcm';

    await _player.stop();
    _isPlaying = true;
    notifyListeners();

    try {
      final String dirPath = (await _temporaryAudioDirectory()).path;
      final String fileExtension = switch (audioFormat) {
        'wav' => 'wav',
        'mp3' => 'mp3',
        'aac' => 'aac',
        'm4a' => 'm4a',
        'ogg' => 'ogg',
        _ => 'wav',
      };
      final String filePath =
          '$dirPath/rt_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      final dart_io.File audioFile = dart_io.File(filePath);
      final dart_io.IOSink sink = audioFile.openWrite();
      if (audioFormat == 'pcm') {
        sink.add(_wrapPcmAsWav(fullAudio));
      } else {
        sink.add(fullAudio);
      }
      await sink.close();

      debugPrint(
        '[AudioService] Realtime audio file written, path=$filePath, format=$audioFormat, size=${fullAudio.length}',
      );
      await _player.setFilePath(filePath);
      await _player.play();

      try {
        await _player.playerStateStream
            .firstWhere(
              (PlayerState state) =>
                  _playbackTicket != ticket ||
                  state.processingState == ProcessingState.completed,
            )
            .timeout(const Duration(seconds: 120));
      } on TimeoutException {
        await _player.stop();
      }
      return filePath;
    } catch (e) {
      debugPrint('[AudioService] flushRealtimeAudio error: $e');
      return null;
    } finally {
      if (_playbackTicket == ticket) {
        _isPlaying = false;
        _playingUrl = null;
        notifyListeners();
      }
    }
  }

  Future<String?> finalizeRealtimeStreamingAudio() async {
    if (_shouldUseNativeRealtimePcm) {
      await _finishNativeRealtimePlayback();
      return _persistRealtimeAudioBuffer();
    }
    await _flushRealtimeStreamingSegment(force: true);
    await _ensureRealtimePlaybackStarted(force: true);
    await _waitForRealtimePlaybackQueueIdle();
    return _persistRealtimeAudioBuffer();
  }

  Future<void> stopPlayback({bool clearRealtimeBuffer = true}) async {
    _playbackTicket++;
    await _player.stop();
    await _stopSystemTts();
    if (_shouldUseNativeRealtimePcm) {
      await _stopNativeRealtimePlayback();
    }
    if (clearRealtimeBuffer) {
      _realtimeAudioBuffer.clear();
      _realtimeAudioFormat = 'pcm';
      _realtimeStreamingBuffer.clear();
      _realtimeStreamingFormat = 'pcm';
      _realtimeConcatSource = null;
      _realtimePendingPlaybackFiles.clear();
      _realtimeAppendChain = Future<void>.value();
      _nativeRealtimeStarted = false;
      _nativeRealtimeChain = Future<void>.value();
    }
    _isPlaying = false;
    _playingUrl = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_audioStreamSub?.cancel());
    unawaited(stopPlayback());
    final AudioRecorder? recorder = _recorder;
    if (recorder != null) {
      unawaited(recorder.dispose());
    }
    unawaited(_player.dispose());
    unawaited(_feedbackPlayer.dispose());
    unawaited(_stopSystemTts());
    super.dispose();
  }

  Uint8List _wrapPcmAsWav(Uint8List pcmBytes, {int sampleRate = 24000}) {
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

    return Uint8List.fromList(<int>[
      ...header.buffer.asUint8List(),
      ...pcmBytes,
    ]);
  }

  Future<String?> _persistRealtimeAudioBuffer() async {
    if (_realtimeAudioBuffer.isEmpty) {
      return null;
    }
    final Uint8List fullAudio = Uint8List.fromList(_realtimeAudioBuffer);
    final String audioFormat = _realtimeAudioFormat;
    _realtimeAudioBuffer.clear();
    _realtimeAudioFormat = 'pcm';
    return _writeRealtimeAudioFile(fullAudio, audioFormat, prefix: 'rt');
  }

  Future<String> _writeRealtimeAudioFile(
    Uint8List audioBytes,
    String audioFormat, {
    required String prefix,
  }) async {
    final String dirPath = (await _temporaryAudioDirectory()).path;
    final String fileExtension = switch (audioFormat) {
      'wav' => 'wav',
      'mp3' => 'mp3',
      'aac' => 'aac',
      'm4a' => 'm4a',
      'ogg' => 'ogg',
      _ => 'wav',
    };
    final String filePath =
        '$dirPath/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final dart_io.File audioFile = dart_io.File(filePath);
    final dart_io.IOSink sink = audioFile.openWrite();
    if (audioFormat == 'pcm') {
      sink.add(_wrapPcmAsWav(audioBytes));
    } else {
      sink.add(audioBytes);
    }
    await sink.close();
    unawaited(_pruneManagedTempAudioFiles());
    return filePath;
  }

  Future<String> _writePcmAudioFile(
    Uint8List audioBytes, {
    required int sampleRate,
    required String prefix,
  }) async {
    final String dirPath = (await _temporaryAudioDirectory()).path;
    final String filePath =
        '$dirPath/${prefix}_${DateTime.now().millisecondsSinceEpoch}.wav';
    final dart_io.File audioFile = dart_io.File(filePath);
    await audioFile.writeAsBytes(
      _wrapPcmAsWav(audioBytes, sampleRate: sampleRate),
    );
    unawaited(_pruneManagedTempAudioFiles());
    return filePath;
  }

  Future<void> _pruneManagedTempAudioFiles() async {
    try {
      final dart_io.Directory dir = await _temporaryAudioDirectory();
      final List<dart_io.FileSystemEntity> entries = dir.listSync();
      final List<dart_io.File> managedFiles = entries
          .whereType<dart_io.File>()
          .where((dart_io.File file) {
            final String name = file.uri.pathSegments.last;
            return name.startsWith('speakeasy_') ||
                name.startsWith('tts_') ||
                name.startsWith('rt_') ||
                name.startsWith('rt_stream_');
          })
          .toList();
      if (managedFiles.length <= _maxManagedTempAudioFiles) {
        final DateTime cutoff = DateTime.now().subtract(
          const Duration(hours: 24),
        );
        for (final dart_io.File file in managedFiles) {
          final dart_io.FileStat stat = await file.stat();
          if (stat.modified.isBefore(cutoff) &&
              file.path != _playingUrl &&
              file.path != _lastRecordingPath) {
            await file.delete();
          }
        }
        return;
      }

      managedFiles.sort(
        (dart_io.File a, dart_io.File b) =>
            b.statSync().modified.compareTo(a.statSync().modified),
      );
      for (final dart_io.File file in managedFiles.skip(
        _maxManagedTempAudioFiles,
      )) {
        if (file.path == _playingUrl || file.path == _lastRecordingPath) {
          continue;
        }
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  Future<void> _flushRealtimeStreamingSegment({bool force = false}) async {
    if (_realtimeStreamingBuffer.isEmpty) {
      return;
    }
    if (!force &&
        _realtimeStreamingBuffer.length < _realtimeSegmentTargetBytes) {
      return;
    }
    final Uint8List segmentBytes = Uint8List.fromList(_realtimeStreamingBuffer);
    final String segmentFormat = _realtimeStreamingFormat;
    _realtimeStreamingBuffer.clear();
    final String filePath = await _writeRealtimeAudioFile(
      segmentBytes,
      segmentFormat,
      prefix: 'rt_stream',
    );
    _realtimePendingPlaybackFiles.add(filePath);
    await _ensureRealtimePlaybackStarted(force: force);
  }

  Future<void> _waitForRealtimePlaybackQueueIdle() async {
    await _realtimeAppendChain;
    if (_realtimeConcatSource == null) {
      return;
    }
    final int ticket = _playbackTicket;
    final PlayerState state = _player.playerState;
    if (state.processingState != ProcessingState.completed) {
      try {
        await _player.playerStateStream
            .firstWhere(
              (PlayerState nextState) =>
                  _playbackTicket != ticket ||
                  nextState.processingState == ProcessingState.completed,
            )
            .timeout(const Duration(seconds: 120));
      } on TimeoutException {
        await _player.stop();
      }
    }
    if (_playbackTicket == ticket) {
      _isPlaying = false;
      _playingUrl = null;
      notifyListeners();
    }
    _realtimeConcatSource = null;
  }

  Future<void> _appendRealtimePlaybackFile(String filePath) async {
    final AudioSource source = AudioSource.file(filePath);
    if (_realtimeConcatSource == null) {
      _realtimeConcatSource = ConcatenatingAudioSource(
        children: <AudioSource>[source],
        useLazyPreparation: false,
      );
      _isPlaying = true;
      _playingUrl = 'realtime_stream';
      notifyListeners();
      await _player.stop();
      await _stopSystemTts();
      await _player.setAudioSource(_realtimeConcatSource!, preload: true);
      unawaited(_player.play());
      return;
    }

    await _realtimeConcatSource!.add(source);
    if (_player.playerState.processingState == ProcessingState.completed) {
      final int lastIndex = _realtimeConcatSource!.children.length - 1;
      await _player.seek(Duration.zero, index: lastIndex);
      unawaited(_player.play());
    }
  }

  Future<void> _ensureRealtimePlaybackStarted({required bool force}) async {
    if (_realtimePendingPlaybackFiles.isEmpty) {
      return;
    }
    if (_realtimeConcatSource == null &&
        !force &&
        _realtimePendingPlaybackFiles.length < _realtimeStartSegmentThreshold) {
      return;
    }
    final List<String> filesToAppend = List<String>.from(
      _realtimePendingPlaybackFiles,
    );
    _realtimePendingPlaybackFiles.clear();
    for (final String filePath in filesToAppend) {
      _realtimeAppendChain = _realtimeAppendChain.then(
        (_) => _appendRealtimePlaybackFile(filePath),
      );
    }
    await _realtimeAppendChain;
  }

  Future<void> _configureSystemTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.85);
      await _tts.setVolume(1.0);
    } on MissingPluginException {
      _disableSystemTts(
        '[AudioService] flutter_tts plugin unavailable on this build; disabling system fallback',
      );
    } catch (error) {
      debugPrint('[AudioService] system TTS init failed: $error');
    }
  }

  Future<bool> _speakSystemTts(String text) async {
    if (!_systemTtsAvailable) {
      return false;
    }
    try {
      await _tts.speak(text);
      return true;
    } on MissingPluginException {
      _disableSystemTts(
        '[AudioService] flutter_tts plugin missing during speak; disabling system fallback',
      );
      return false;
    } catch (error) {
      debugPrint('[AudioService] system TTS speak failed: $error');
      return false;
    }
  }

  Future<void> _stopSystemTts() async {
    if (!_systemTtsAvailable) {
      return;
    }
    try {
      await _tts.stop();
    } on MissingPluginException {
      _disableSystemTts(
        '[AudioService] flutter_tts plugin missing during stop; disabling system fallback',
      );
    } catch (error) {
      debugPrint('[AudioService] system TTS stop failed: $error');
    }
  }

  void _disableSystemTts(String message) {
    if (!_systemTtsAvailable) {
      return;
    }
    _systemTtsAvailable = false;
    debugPrint(message);
  }

  Future<void> _startNativeRealtimePlayback() async {
    if (_nativeRealtimeStarted || _realtimeStreamingBuffer.isEmpty) {
      _nativeRealtimeStartQueued = false;
      return;
    }
    final Uint8List initialBytes = Uint8List.fromList(_realtimeStreamingBuffer);
    _realtimeStreamingBuffer.clear();
    _nativeRealtimeStartQueued = false;
    _nativeRealtimeStarted = true;
    _isPlaying = true;
    _playingUrl = 'realtime_stream';
    notifyListeners();
    await _realtimeAudioChannel.invokeMethod<void>(
      'startPcmStream',
      <String, Object>{'sampleRate': 24000, 'channels': 1},
    );
    await _realtimeAudioChannel.invokeMethod<void>(
      'appendPcmChunk',
      initialBytes,
    );
  }

  Future<void> _appendNativeRealtimePcm(Uint8List bytes) async {
    if (!_nativeRealtimeStarted || bytes.isEmpty) {
      return;
    }
    await _realtimeAudioChannel.invokeMethod<void>('appendPcmChunk', bytes);
  }

  Future<void> _finishNativeRealtimePlayback() async {
    if (!_nativeRealtimeStarted && _realtimeStreamingBuffer.isNotEmpty) {
      if (!_nativeRealtimeStartQueued) {
        _nativeRealtimeStartQueued = true;
        _nativeRealtimeChain = _nativeRealtimeChain.then(
          (_) => _startNativeRealtimePlayback(),
        );
      }
    }
    if (!_nativeRealtimeStarted && !_nativeRealtimeStartQueued) {
      return;
    }
    await _nativeRealtimeChain;
    if (!_nativeRealtimeStarted) {
      return;
    }
    await _realtimeAudioChannel.invokeMethod<void>('finishPcmStream');
    _nativeRealtimeStarted = false;
    _nativeRealtimeStartQueued = false;
    _isPlaying = false;
    _playingUrl = null;
    notifyListeners();
  }

  Future<void> _stopNativeRealtimePlayback() async {
    if (!_nativeRealtimeStarted && _realtimeStreamingBuffer.isEmpty) {
      _nativeRealtimeStartQueued = false;
      return;
    }
    _realtimeStreamingBuffer.clear();
    _nativeRealtimeStarted = false;
    _nativeRealtimeStartQueued = false;
    _nativeRealtimeChain = Future<void>.value();
    await _realtimeAudioChannel.invokeMethod<void>('stopPcmStream');
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
