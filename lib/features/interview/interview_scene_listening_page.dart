import 'dart:async';
import 'package:flutter/material.dart';

import 'package:speakeasy/config/app_config.dart';
import 'package:speakeasy/features/interview/interview_engine.dart';
import 'package:speakeasy/features/interview/interview_scene_dialogue_builder.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/services/audio_service.dart';

enum _ListeningPracticeMode { listening, shadowing }

class _ShadowTurnResult {
  const _ShadowTurnResult({
    required this.transcript,
    required this.completenessScore,
    required this.audioPath,
    this.pronunciationScore,
    this.accuracyScore,
    this.fluencyScore,
    this.source = '',
    this.scoringPronunciation = false,
  });

  final String transcript;
  final int completenessScore;
  final String audioPath;
  final int? pronunciationScore;
  final int? accuracyScore;
  final int? fluencyScore;
  final String source;
  final bool scoringPronunciation;

  int get displayScore {
    final List<int> values = <int>[
      if (pronunciationScore != null) pronunciationScore!.clamp(0, 100).toInt(),
      completenessScore.clamp(0, 100).toInt(),
    ];
    return (values.reduce((int a, int b) => a + b) / values.length)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  _ShadowTurnResult copyWith({
    String? transcript,
    int? completenessScore,
    String? audioPath,
    int? pronunciationScore,
    int? accuracyScore,
    int? fluencyScore,
    String? source,
    bool? scoringPronunciation,
  }) {
    return _ShadowTurnResult(
      transcript: transcript ?? this.transcript,
      completenessScore: completenessScore ?? this.completenessScore,
      audioPath: audioPath ?? this.audioPath,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      accuracyScore: accuracyScore ?? this.accuracyScore,
      fluencyScore: fluencyScore ?? this.fluencyScore,
      source: source ?? this.source,
      scoringPronunciation: scoringPronunciation ?? this.scoringPronunciation,
    );
  }
}

class InterviewSceneListeningPage extends StatefulWidget {
  const InterviewSceneListeningPage({
    super.key,
    required this.sceneId,
    required this.targetLevel,
    this.coverUrl = '',
  });

  final String sceneId;
  final String targetLevel;
  final String coverUrl;

  @override
  State<InterviewSceneListeningPage> createState() =>
      _InterviewSceneListeningPageState();
}

class _InterviewSceneListeningPageState
    extends State<InterviewSceneListeningPage> {
  InterviewSceneGraph? _graph;
  List<InterviewSceneDialogueTurn> _turns =
      const <InterviewSceneDialogueTurn>[];
  List<GlobalKey> _turnKeys = const <GlobalKey>[];
  List<Duration> _estimatedTurnDurations = const <Duration>[];
  List<Duration?> _actualTurnDurations = const <Duration?>[];
  bool _loading = true;
  bool _playing = false;
  bool _loopPlayback = false;
  bool _shadowRecording = false;
  bool _shadowProcessing = false;
  bool _shadowPromptPlaying = false;
  bool _shadowAutoRunning = false;
  String? _errorText;
  Map<String, _ShadowTurnResult> _shadowResults =
      const <String, _ShadowTurnResult>{};
  String? _expandedShadowResultId;
  int _activeIndex = 0;
  int _playbackTicket = 0;
  int _shadowTicket = 0;
  Duration _currentTurnPosition = Duration.zero;
  Duration _shadowElapsed = Duration.zero;
  _ListeningPracticeMode _mode = _ListeningPracticeMode.listening;
  AudioService? _audioService;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  Timer? _shadowTimer;
  Completer<void>? _shadowRecordStopper;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(InterviewSceneListeningPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sceneId != widget.sceneId ||
        oldWidget.targetLevel != widget.targetLevel) {
      unawaited(_load());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AudioService audioService = AudioServiceScope.of(context);
    if (_audioService == audioService) {
      return;
    }
    _audioService = audioService;
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    _positionSub = audioService.playbackPositionStream.listen((position) {
      if (!mounted || !_playing) {
        return;
      }
      setState(() => _currentTurnPosition = position);
    });
    _durationSub = audioService.playbackDurationStream.listen((duration) {
      if (!mounted ||
          !_playing ||
          duration == null ||
          duration.inMilliseconds <= 0 ||
          _activeIndex < 0 ||
          _activeIndex >= _actualTurnDurations.length) {
        return;
      }
      setState(() {
        final List<Duration?> durations = List<Duration?>.from(
          _actualTurnDurations,
        );
        durations[_activeIndex] = duration;
        _actualTurnDurations = durations;
      });
    });
  }

  @override
  void dispose() {
    _playbackTicket++;
    _shadowTicket++;
    _shadowTimer?.cancel();
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_audioService?.stopPlayback(clearRealtimeBuffer: false));
    if (_shadowRecording) {
      unawaited(_audioService?.stopRecording());
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorText = null;
      _activeIndex = 0;
      _currentTurnPosition = Duration.zero;
      _shadowElapsed = Duration.zero;
      _shadowResults = const <String, _ShadowTurnResult>{};
      _expandedShadowResultId = null;
      _playing = false;
      _shadowRecording = false;
      _shadowProcessing = false;
      _shadowPromptPlaying = false;
      _shadowAutoRunning = false;
    });
    try {
      final InterviewSceneGraph graph = await loadInterviewSceneGraph(
        sceneId: widget.sceneId,
      );
      final List<InterviewSceneDialogueTurn> turns =
          buildInterviewSceneDialogueTurns(graph, widget.targetLevel);
      if (!mounted) {
        return;
      }
      setState(() {
        _graph = graph;
        _turns = turns;
        _turnKeys = List<GlobalKey>.generate(
          turns.length,
          (_) => GlobalKey(),
          growable: false,
        );
        _estimatedTurnDurations = turns
            .map(_estimateTurnDuration)
            .toList(growable: false);
        _actualTurnDurations = List<Duration?>.filled(
          turns.length,
          null,
          growable: false,
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorText = '开始热身加载失败：$error';
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_mode == _ListeningPracticeMode.shadowing) {
      await _toggleShadowPractice();
      return;
    }
    if (_playing) {
      await _stopPlayback();
      return;
    }
    await _playFrom(_activeIndex);
  }

  Future<void> _stopPlayback() async {
    _playbackTicket++;
    if (mounted) {
      setState(() {
        _playing = false;
        _shadowPromptPlaying = false;
        _currentTurnPosition = Duration.zero;
      });
    }
    await (_audioService ?? AudioServiceScope.of(context)).stopPlayback(
      clearRealtimeBuffer: false,
    );
  }

  Future<void> _toggleShadowPractice() async {
    if (_shadowAutoRunning ||
        _shadowPromptPlaying ||
        _shadowRecording ||
        _shadowProcessing) {
      await _pauseShadowPractice();
      return;
    }
    await _startShadowPractice();
  }

  Future<void> _startShadowPractice() async {
    if (_turns.isEmpty) {
      return;
    }
    final bool hasCandidateTurns = _shadowTurnIndexes.isNotEmpty;
    if (hasCandidateTurns) {
      final AudioService audioService =
          _audioService ?? AudioServiceScope.of(context);
      final bool allowed = await audioService.requestPermission();
      if (!allowed) {
        if (mounted) {
          setState(() => _errorText = '需要麦克风权限才能跟读。');
        }
        return;
      }
    }
    await _stopPlayback();
    final int ticket = ++_shadowTicket;
    if (!mounted) {
      return;
    }
    setState(() {
      _shadowAutoRunning = true;
      _shadowElapsed = Duration.zero;
      _errorText = null;
    });
    await _runShadowPracticeLoop(startIndex: _activeIndex, ticket: ticket);
  }

  Future<void> _pauseShadowPractice() async {
    _shadowTicket++;
    final Completer<void>? stopper = _shadowRecordStopper;
    if (stopper != null && !stopper.isCompleted) {
      stopper.complete();
    }
    _shadowRecordStopper = null;
    _shadowTimer?.cancel();
    final AudioService audioService =
        _audioService ?? AudioServiceScope.of(context);
    await audioService.stopPlayback(clearRealtimeBuffer: false);
    if (_shadowRecording) {
      await audioService.stopRecording();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _playing = false;
      _shadowAutoRunning = false;
      _shadowRecording = false;
      _shadowProcessing = false;
      _shadowPromptPlaying = false;
      _shadowElapsed = Duration.zero;
      _currentTurnPosition = Duration.zero;
    });
  }

  Future<void> _playShadowOriginal(String audioPath) async {
    final String cleanedPath = audioPath.trim();
    if (cleanedPath.isEmpty) {
      return;
    }
    final AudioService audioService =
        _audioService ?? AudioServiceScope.of(context);
    if (_shadowAutoRunning ||
        _shadowPromptPlaying ||
        _shadowRecording ||
        _shadowProcessing) {
      await _pauseShadowPractice();
    } else {
      await _stopPlayback();
    }
    try {
      await audioService.playFile(cleanedPath);
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = '原音播放失败：$error');
      }
    }
  }

  Future<void> _runShadowPracticeLoop({
    required int startIndex,
    required int ticket,
  }) async {
    if (_turns.isEmpty) {
      return;
    }
    final AudioService audioService =
        _audioService ?? AudioServiceScope.of(context);
    int index = startIndex.clamp(0, _turns.length - 1).toInt();
    bool interruptedByError = false;

    while (mounted && ticket == _shadowTicket && _shadowAutoRunning) {
      final InterviewSceneDialogueTurn turn = _turns[index];
      setState(() {
        _activeIndex = index;
        _playing = true;
        _shadowPromptPlaying = true;
        _shadowRecording = false;
        _shadowProcessing = false;
        _shadowElapsed = Duration.zero;
        _currentTurnPosition = Duration.zero;
        _errorText = null;
      });
      _scrollToActiveTurn();

      final int playbackTicket = ++_playbackTicket;
      try {
        final bool played = await _playTurnWithRoleVoice(
          audioService,
          turn,
          playbackTicket,
        );
        if (!played ||
            !mounted ||
            ticket != _shadowTicket ||
            playbackTicket != _playbackTicket ||
            !_shadowAutoRunning) {
          return;
        }
      } catch (error) {
        if (mounted && ticket == _shadowTicket) {
          setState(() => _errorText = '播放失败：$error');
        }
        interruptedByError = true;
        break;
      } finally {
        if (mounted && ticket == _shadowTicket) {
          setState(() {
            _playing = false;
            _shadowPromptPlaying = false;
            _currentTurnPosition = Duration.zero;
          });
        }
      }

      if (turn.role == InterviewSceneDialogueRole.candidate &&
          mounted &&
          ticket == _shadowTicket &&
          _shadowAutoRunning) {
        await _recordShadowTurn(turn: turn, ticket: ticket);
      }
      if (!mounted ||
          ticket != _shadowTicket ||
          !_shadowAutoRunning ||
          interruptedByError) {
        return;
      }

      final bool atEnd = index >= _turns.length - 1;
      if (atEnd && !_loopPlayback) {
        break;
      }
      index = atEnd ? 0 : index + 1;
    }

    if (mounted && ticket == _shadowTicket) {
      setState(() {
        _shadowAutoRunning = false;
        _playing = false;
        _shadowPromptPlaying = false;
        _shadowRecording = false;
        _shadowProcessing = false;
        _shadowElapsed = Duration.zero;
      });
    }
  }

  Future<void> _recordShadowTurn({
    required InterviewSceneDialogueTurn turn,
    required int ticket,
  }) async {
    final AudioService audioService =
        _audioService ?? AudioServiceScope.of(context);
    await audioService.startRecording();
    _shadowTimer?.cancel();
    final Duration limit = _shadowRecordLimitFor(_activeIndex);
    final Completer<void> stopper = Completer<void>();
    _shadowRecordStopper = stopper;
    if (!mounted) {
      return;
    }
    setState(() {
      _shadowRecording = true;
      _shadowProcessing = false;
      _shadowPromptPlaying = false;
      _shadowElapsed = Duration.zero;
      _errorText = null;
    });
    _shadowTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted || ticket != _shadowTicket || !_shadowRecording) {
        timer.cancel();
        return;
      }
      final Duration nextElapsed = _shadowElapsed + const Duration(seconds: 1);
      setState(() => _shadowElapsed = nextElapsed);
      if (nextElapsed >= limit && !stopper.isCompleted) {
        timer.cancel();
        stopper.complete();
      }
    });
    await stopper.future;
    if (!mounted || ticket != _shadowTicket || !_shadowAutoRunning) {
      return;
    }
    _shadowTimer?.cancel();
    setState(() {
      _shadowRecording = false;
      _shadowProcessing = true;
    });
    try {
      final String? path = await audioService.stopRecording();
      if (!mounted || ticket != _shadowTicket) {
        return;
      }
      if (path == null || path.trim().isEmpty) {
        throw Exception('没有录到有效语音');
      }
      if (!mounted || ticket != _shadowTicket) {
        return;
      }
      final _ShadowTurnResult result = _ShadowTurnResult(
        transcript: '语音识别暂未接入可信上传',
        completenessScore: 0,
        audioPath: path,
        scoringPronunciation: false,
      );
      setState(() {
        _shadowResults = <String, _ShadowTurnResult>{
          ..._shadowResults,
          turn.id: result,
        };
      });
      await Future<void>.delayed(const Duration(milliseconds: 620));
      if (!mounted || ticket != _shadowTicket) {
        return;
      }
    } catch (error) {
      if (mounted && ticket == _shadowTicket) {
        setState(() => _errorText = '识别失败：$error');
      }
    } finally {
      if (mounted && ticket == _shadowTicket) {
        setState(() {
          _shadowProcessing = false;
          _shadowElapsed = Duration.zero;
        });
      }
      if (_shadowRecordStopper == stopper) {
        _shadowRecordStopper = null;
      }
    }
  }

  Future<void> _cancelShadowRecording() async {
    if (!_shadowRecording && !_shadowProcessing) {
      return;
    }
    _shadowTicket++;
    _shadowTimer?.cancel();
    if (_shadowRecording) {
      await (_audioService ?? AudioServiceScope.of(context)).stopRecording();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _shadowRecording = false;
      _shadowProcessing = false;
      _shadowPromptPlaying = false;
      _shadowElapsed = Duration.zero;
    });
  }

  Future<void> _playFrom(int startIndex) async {
    if (_turns.isEmpty) {
      return;
    }
    final int safeStart = startIndex.clamp(0, _turns.length - 1).toInt();
    final int ticket = ++_playbackTicket;
    setState(() {
      _playing = true;
      _activeIndex = safeStart;
      _currentTurnPosition = Duration.zero;
      _errorText = null;
    });
    final AudioService audioService =
        _audioService ?? AudioServiceScope.of(context);
    int cycleStart = safeStart;
    bool interruptedByError = false;
    while (mounted && ticket == _playbackTicket) {
      for (int index = cycleStart; index < _turns.length; index += 1) {
        if (!mounted || ticket != _playbackTicket) {
          return;
        }
        setState(() {
          _activeIndex = index;
          _currentTurnPosition = Duration.zero;
        });
        _scrollToActiveTurn();
        final InterviewSceneDialogueTurn turn = _turns[index];
        try {
          final bool played = await _playTurnWithRoleVoice(
            audioService,
            turn,
            ticket,
          );
          if (!played || ticket != _playbackTicket) {
            return;
          }
        } catch (error) {
          if (mounted && ticket == _playbackTicket) {
            setState(() => _errorText = '播放失败：$error');
          }
          interruptedByError = true;
          break;
        }
      }
      if (interruptedByError ||
          !_loopPlayback ||
          !mounted ||
          ticket != _playbackTicket) {
        break;
      }
      cycleStart = 0;
    }
    if (mounted && ticket == _playbackTicket) {
      setState(() => _playing = false);
    }
  }

  Future<bool> _playTurnWithRoleVoice(
    AudioService audioService,
    InterviewSceneDialogueTurn turn,
    int ticket,
  ) async {
    final String roleVoice = _ttsVoiceForTurn(turn);
    final bool played = await audioService.playCachedTts(
      turn.text,
      voice: roleVoice,
      sceneId: widget.sceneId,
      targetLevel: widget.targetLevel,
      nodeId: turn.nodeId,
    );
    if (played ||
        !mounted ||
        ticket != _playbackTicket ||
        roleVoice == AppConfig.ttsVoice) {
      return played;
    }
    return audioService.playCachedTts(
      turn.text,
      voice: AppConfig.ttsVoice,
      sceneId: widget.sceneId,
      targetLevel: widget.targetLevel,
      nodeId: turn.nodeId,
    );
  }

  void _scrollToActiveTurn() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _activeIndex < 0 ||
          _activeIndex >= _turnKeys.length ||
          _turnKeys[_activeIndex].currentContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        _turnKeys[_activeIndex].currentContext!,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.36,
      );
    });
  }

  Future<void> _jumpBy(int delta) async {
    if (_turns.isEmpty) {
      return;
    }
    final bool shouldResumeListening =
        _mode == _ListeningPracticeMode.listening && _playing;
    final bool shouldResumeShadow =
        _mode == _ListeningPracticeMode.shadowing && _shadowAutoRunning;
    if (_mode == _ListeningPracticeMode.shadowing) {
      await _pauseShadowPractice();
    } else {
      await _cancelShadowRecording();
    }
    final int nextIndex = _jumpTargetIndex(delta);
    await _stopPlayback();
    if (!mounted) {
      return;
    }
    setState(() {
      _activeIndex = nextIndex;
      _currentTurnPosition = Duration.zero;
      _shadowElapsed = Duration.zero;
    });
    _scrollToActiveTurn();
    if (shouldResumeListening) {
      await _playFrom(nextIndex);
    } else if (shouldResumeShadow) {
      await _startShadowPractice();
    }
  }

  void _toggleLoopPlayback() {
    setState(() => _loopPlayback = !_loopPlayback);
  }

  Future<void> _togglePracticeMode() async {
    if (_mode == _ListeningPracticeMode.shadowing &&
        (_shadowAutoRunning ||
            _shadowPromptPlaying ||
            _shadowRecording ||
            _shadowProcessing)) {
      await _pauseShadowPractice();
    } else {
      await _stopPlayback();
      await _cancelShadowRecording();
    }
    if (!mounted) {
      return;
    }
    final bool nextIsShadowing = _mode == _ListeningPracticeMode.listening;
    final int nextIndex = _activeIndex.clamp(0, _turns.length - 1).toInt();
    setState(() {
      _mode = nextIsShadowing
          ? _ListeningPracticeMode.shadowing
          : _ListeningPracticeMode.listening;
      if (nextIndex >= 0) {
        _activeIndex = nextIndex;
      }
      _shadowElapsed = Duration.zero;
      _errorText = null;
    });
    _scrollToActiveTurn();
  }

  Duration get _totalPlaybackDuration {
    final List<int> indexes = _navigableTurnIndexes;
    if (indexes.isEmpty) {
      return Duration.zero;
    }
    return _turnDurationForIndexes(indexes);
  }

  Duration get _elapsedPlaybackDuration {
    final List<int> indexes = _navigableTurnIndexes;
    if (indexes.isEmpty) {
      return Duration.zero;
    }
    final int activePosition = indexes.indexOf(_activeIndex);
    final int currentPosition = activePosition < 0 ? 0 : activePosition;
    final Duration previous = _turnDurationForIndexes(
      indexes.take(currentPosition),
    );
    final Duration currentLimit = _turnDurationAt(_activeIndex);
    final Duration current = _currentTurnPosition > currentLimit
        ? currentLimit
        : _currentTurnPosition;
    return previous + current;
  }

  Duration _turnDurationForIndexes(Iterable<int> indexes) {
    Duration total = Duration.zero;
    for (final int index in indexes) {
      total += _turnDurationAt(index);
    }
    return total;
  }

  Duration _turnDurationAt(int index) {
    if (index >= 0 && index < _actualTurnDurations.length) {
      final Duration? actual = _actualTurnDurations[index];
      if (actual != null && actual.inMilliseconds > 0) {
        return actual;
      }
    }
    if (index >= 0 && index < _estimatedTurnDurations.length) {
      return _estimatedTurnDurations[index];
    }
    return const Duration(seconds: 4);
  }

  Duration _shadowRecordLimitFor(int index) {
    final Duration estimated =
        _turnDurationAt(index) + const Duration(seconds: 2);
    if (estimated < const Duration(seconds: 4)) {
      return const Duration(seconds: 4);
    }
    if (estimated > const Duration(seconds: 12)) {
      return const Duration(seconds: 12);
    }
    return estimated;
  }

  List<int> get _shadowTurnIndexes {
    final List<int> indexes = <int>[];
    for (int index = 0; index < _turns.length; index += 1) {
      if (_isShadowTurnIndex(index)) {
        indexes.add(index);
      }
    }
    return indexes;
  }

  List<int> get _displayTurnIndexes {
    return List<int>.generate(_turns.length, (int index) => index);
  }

  List<int> get _navigableTurnIndexes {
    final List<int> indexes = _displayTurnIndexes;
    if (indexes.isNotEmpty) {
      return indexes;
    }
    return List<int>.generate(_turns.length, (int index) => index);
  }

  bool _isShadowTurnIndex(int index) {
    return index >= 0 &&
        index < _turns.length &&
        _turns[index].role == InterviewSceneDialogueRole.candidate;
  }

  int _jumpTargetIndex(int delta) {
    final List<int> indexes = _navigableTurnIndexes;
    if (indexes.isEmpty) {
      return _activeIndex;
    }
    final int activePosition = indexes.indexOf(_activeIndex);
    final int currentPosition = activePosition < 0 ? 0 : activePosition;
    return indexes[(currentPosition + delta).clamp(0, indexes.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _listeningBg,
      appBar: AppBar(
        backgroundColor: _listeningBg,
        surfaceTintColor: _listeningBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '开始热身',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final String? errorText = _errorText;
    if (errorText != null && _turns.isEmpty) {
      return _ListeningErrorState(text: errorText, onRetry: _load);
    }
    if (_turns.isEmpty) {
      return _ListeningErrorState(text: '当前等级暂无可播放的场景对话。', onRetry: _load);
    }
    final InterviewSceneGraph? graph = _graph;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 10, 26, 6),
          child: _ListeningTitleBlock(
            title: graph?.titleCn ?? '场景对话',
            subtitle:
                '${_levelLabel(widget.targetLevel)} · ${_mode == _ListeningPracticeMode.listening ? '听完整对话' : '跟读目标表达'}',
          ),
        ),
        Expanded(
          child: _displayTurnIndexes.isEmpty
              ? const _ListeningInlineEmptyState(text: '当前等级暂无可跟读的目标表达。')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(28, 42, 28, 54),
                  itemCount: _displayTurnIndexes.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 24),
                  itemBuilder: (BuildContext context, int index) {
                    final int turnIndex = _displayTurnIndexes[index];
                    final InterviewSceneDialogueTurn turn = _turns[turnIndex];
                    final _ShadowTurnResult? shadowResult =
                        turn.role == InterviewSceneDialogueRole.candidate
                        ? _shadowResults[turn.id]
                        : null;
                    return _ListeningLyricLine(
                      key: _turnKeys[turnIndex],
                      turn: turn,
                      active: turnIndex == _activeIndex,
                      onTap: () {
                        setState(() {
                          _activeIndex = turnIndex;
                          _currentTurnPosition = Duration.zero;
                          _shadowElapsed = Duration.zero;
                          _expandedShadowResultId = null;
                        });
                        _scrollToActiveTurn();
                      },
                      practiceMode: _mode,
                      activeHint: turnIndex == _activeIndex
                          ? _shadowActiveHint
                          : '',
                      shadowResult: shadowResult,
                      resultExpanded: _expandedShadowResultId == turn.id,
                      onToggleResult: () {
                        setState(() {
                          _expandedShadowResultId =
                              _expandedShadowResultId == turn.id
                              ? null
                              : turn.id;
                        });
                      },
                      onPlayShadowOriginal: shadowResult == null
                          ? null
                          : () => unawaited(
                              _playShadowOriginal(shadowResult.audioPath),
                            ),
                    );
                  },
                ),
        ),
        _ListeningPlaybackBar(
          progress: _totalPlaybackDuration.inMilliseconds <= 0
              ? 0
              : _elapsedPlaybackDuration.inMilliseconds /
                    _totalPlaybackDuration.inMilliseconds,
          elapsed: _elapsedPlaybackDuration,
          totalDuration: _totalPlaybackDuration,
          playing: _playing,
          loopPlayback: _loopPlayback,
          mode: _mode,
          shadowRecording: _shadowRecording,
          shadowProcessing: _shadowProcessing,
          shadowPromptPlaying: _shadowPromptPlaying,
          errorText: _errorText,
          onPrevious: _jumpTargetIndex(-1) == _activeIndex
              ? null
              : () => unawaited(_jumpBy(-1)),
          onTogglePlayback: () => unawaited(_togglePlayback()),
          onToggleLoop: _toggleLoopPlayback,
          onToggleMode: () => unawaited(_togglePracticeMode()),
          onNext: _jumpTargetIndex(1) == _activeIndex
              ? null
              : () => unawaited(_jumpBy(1)),
        ),
      ],
    );
  }

  String get _shadowActiveHint {
    if (_mode != _ListeningPracticeMode.shadowing) {
      return '';
    }
    if (_shadowRecording) {
      return '正在跟读 · ${_formatPlaybackTime(_shadowElapsed)}';
    }
    if (_shadowPromptPlaying) {
      return _turns[_activeIndex].role == InterviewSceneDialogueRole.interviewer
          ? '面试官正在说'
          : '先听这一句';
    }
    if (_shadowProcessing) {
      return '正在识别...';
    }
    return _turns[_activeIndex].role == InterviewSceneDialogueRole.interviewer
        ? '点播放，听面试官问题'
        : '点播放，先听一句，再跟读';
  }
}

class _ListeningInlineEmptyState extends StatelessWidget {
  const _ListeningInlineEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _listeningMuted,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ListeningTitleBlock extends StatelessWidget {
  const _ListeningTitleBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _listeningText,
            fontSize: 27,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _listeningMuted,
            fontSize: 13,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ListeningLyricLine extends StatelessWidget {
  const _ListeningLyricLine({
    super.key,
    required this.turn,
    required this.active,
    required this.onTap,
    required this.practiceMode,
    required this.activeHint,
    required this.shadowResult,
    required this.resultExpanded,
    required this.onToggleResult,
    required this.onPlayShadowOriginal,
  });

  final InterviewSceneDialogueTurn turn;
  final bool active;
  final VoidCallback onTap;
  final _ListeningPracticeMode practiceMode;
  final String activeHint;
  final _ShadowTurnResult? shadowResult;
  final bool resultExpanded;
  final VoidCallback onToggleResult;
  final VoidCallback? onPlayShadowOriginal;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (active && turn.stageLabel.isNotEmpty) ...[
              Text(
                turn.stageLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _listeningGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 9),
            ],
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: active ? _listeningText : _listeningMuted,
                fontSize: active ? 23 : 18,
                height: 1.34,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 0,
              ),
              child: Text(turn.text),
            ),
            if (active &&
                practiceMode == _ListeningPracticeMode.shadowing &&
                activeHint.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  activeHint,
                  key: ValueKey<String>(activeHint),
                  style: const TextStyle(
                    color: _listeningGreen,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
            if (practiceMode == _ListeningPracticeMode.shadowing &&
                shadowResult != null) ...[
              const SizedBox(height: 12),
              _ShadowResultBar(
                result: shadowResult!,
                active: active,
                expanded: resultExpanded,
                onTap: onToggleResult,
                onPlayOriginal: onPlayShadowOriginal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShadowResultBar extends StatelessWidget {
  const _ShadowResultBar({
    required this.result,
    required this.active,
    required this.expanded,
    required this.onTap,
    required this.onPlayOriginal,
  });

  final _ShadowTurnResult result;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback? onPlayOriginal;

  @override
  Widget build(BuildContext context) {
    final Color tone = _shadowScoreColor(result.displayScore);
    final double opacity = active ? 1 : 0.58;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFF6F8F1) : const Color(0xFFF8F6F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? tone.withValues(alpha: 0.28)
                    : const Color(0xFFE5E0D6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded, size: 16, color: tone),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '你说：${result.transcript}',
                        maxLines: expanded ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _listeningText,
                          fontSize: active ? 13 : 12.5,
                          height: 1.28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (onPlayOriginal != null) ...[
                      _ShadowOriginalAudioButton(onPressed: onPlayOriginal!),
                      const SizedBox(width: 4),
                    ],
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _listeningMuted,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    _ShadowResultChip(
                      label: result.pronunciationScore == null
                          ? result.scoringPronunciation
                                ? '发音评分中'
                                : '发音稍后出'
                          : '发音清晰 ${result.pronunciationScore}',
                      color: result.pronunciationScore == null
                          ? _listeningMuted
                          : _shadowScoreColor(result.pronunciationScore),
                    ),
                    _ShadowResultChip(
                      label: '完整度 ${result.completenessScore}',
                      color: _shadowScoreColor(result.completenessScore),
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 10),
                  _ShadowResultMetricLine(
                    label: '流利度',
                    score: result.fluencyScore,
                  ),
                  _ShadowResultMetricLine(
                    label: '发音准确',
                    score: result.accuracyScore,
                  ),
                  _ShadowResultMetricLine(
                    label: '句子完整',
                    score: result.completenessScore,
                  ),
                  if (result.source.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '来源：${_shadowScoreSourceLabel(result.source)}',
                      style: const TextStyle(
                        color: _listeningMuted,
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShadowOriginalAudioButton extends StatelessWidget {
  const _ShadowOriginalAudioButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '播放原音',
      child: Semantics(
        button: true,
        label: '播放用户跟读原音',
        child: InkResponse(
          onTap: onPressed,
          radius: 18,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _listeningGreen.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: _listeningGreen.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: _listeningGreen,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShadowResultChip extends StatelessWidget {
  const _ShadowResultChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ShadowResultMetricLine extends StatelessWidget {
  const _ShadowResultMetricLine({required this.label, required this.score});

  final String label;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final int value = (score ?? 0).clamp(0, 100).toInt();
    final Color color = score == null
        ? _listeningMuted
        : _shadowScoreColor(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              label,
              style: const TextStyle(
                color: _listeningMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: score == null ? 0 : value / 100,
                minHeight: 4,
                backgroundColor: const Color(0xFFE8E4DA),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 26,
            child: Text(
              score == null ? '--' : '$value',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningPlaybackBar extends StatelessWidget {
  const _ListeningPlaybackBar({
    required this.progress,
    required this.elapsed,
    required this.totalDuration,
    required this.playing,
    required this.loopPlayback,
    required this.mode,
    required this.shadowRecording,
    required this.shadowProcessing,
    required this.shadowPromptPlaying,
    required this.errorText,
    required this.onPrevious,
    required this.onTogglePlayback,
    required this.onToggleLoop,
    required this.onToggleMode,
    required this.onNext,
  });

  final double progress;
  final Duration elapsed;
  final Duration totalDuration;
  final bool playing;
  final bool loopPlayback;
  final _ListeningPracticeMode mode;
  final bool shadowRecording;
  final bool shadowProcessing;
  final bool shadowPromptPlaying;
  final String? errorText;
  final VoidCallback? onPrevious;
  final VoidCallback onTogglePlayback;
  final VoidCallback onToggleLoop;
  final VoidCallback onToggleMode;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _listeningBg,
        border: Border(top: BorderSide(color: Color(0xFFEDE9DF))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorText != null) ...[
                Text(
                  errorText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF9D463F),
                    fontSize: 12,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1).toDouble(),
                  minHeight: 4,
                  backgroundColor: const Color(0xFFE6E1D8),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _listeningText,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatPlaybackTime(elapsed),
                    style: const TextStyle(
                      color: _listeningMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _formatPlaybackTime(totalDuration),
                    style: const TextStyle(
                      color: _listeningMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.translate(
                      offset: const Offset(-128, 0),
                      child: _LoopModeButton(
                        loopPlayback: loopPlayback,
                        onPressed: onToggleLoop,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-82, 0),
                      child: _TrackSkipButton(
                        direction: _TrackSkipDirection.previous,
                        onPressed: onPrevious,
                      ),
                    ),
                    _SimplePlayerButton(
                      icon: _mainActionIcon,
                      onPressed: onTogglePlayback,
                      primary: true,
                    ),
                    Transform.translate(
                      offset: const Offset(82, 0),
                      child: _TrackSkipButton(
                        direction: _TrackSkipDirection.next,
                        onPressed: onNext,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(128, 0),
                      child: _PracticeModeButton(
                        key: const ValueKey<String>('listening_mode_toggle'),
                        mode: mode,
                        onPressed: onToggleMode,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _mainActionIcon {
    if (mode == _ListeningPracticeMode.shadowing) {
      if (shadowProcessing || shadowRecording || shadowPromptPlaying) {
        return Icons.pause_rounded;
      }
      return Icons.play_arrow_rounded;
    }
    return playing ? Icons.pause_rounded : Icons.play_arrow_rounded;
  }
}

enum _TrackSkipDirection { previous, next }

class _TrackSkipButton extends StatelessWidget {
  const _TrackSkipButton({required this.direction, required this.onPressed});

  final _TrackSkipDirection direction;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color color = onPressed == null
        ? _listeningMuted.withValues(alpha: 0.32)
        : _listeningText;
    return SizedBox(
      width: 46,
      height: 46,
      child: IconButton(
        onPressed: onPressed,
        icon: CustomPaint(
          size: const Size(29, 29),
          painter: _TrackSkipIconPainter(color: color, direction: direction),
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _TrackSkipIconPainter extends CustomPainter {
  const _TrackSkipIconPainter({required this.color, required this.direction});

  final Color color;
  final _TrackSkipDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final double width = size.width;
    final double height = size.height;
    final double barWidth = width * 0.12;
    final double barHeight = height * 0.58;
    final double barRadius = barWidth / 2;
    final double centerY = height / 2;

    if (direction == _TrackSkipDirection.next) {
      final RRect bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          width * 0.70,
          centerY - barHeight / 2,
          barWidth,
          barHeight,
        ),
        Radius.circular(barRadius),
      );
      canvas.drawRRect(bar, paint);
      final Path triangle = Path()
        ..moveTo(width * 0.28, height * 0.22)
        ..lineTo(width * 0.28, height * 0.78)
        ..lineTo(width * 0.64, centerY)
        ..close();
      canvas.drawPath(triangle, paint);
      return;
    }

    final RRect bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(width * 0.18, centerY - barHeight / 2, barWidth, barHeight),
      Radius.circular(barRadius),
    );
    canvas.drawRRect(bar, paint);
    final Path triangle = Path()
      ..moveTo(width * 0.72, height * 0.22)
      ..lineTo(width * 0.72, height * 0.78)
      ..lineTo(width * 0.36, centerY)
      ..close();
    canvas.drawPath(triangle, paint);
  }

  @override
  bool shouldRepaint(covariant _TrackSkipIconPainter oldDelegate) {
    return color != oldDelegate.color || direction != oldDelegate.direction;
  }
}

class _LoopModeButton extends StatelessWidget {
  const _LoopModeButton({required this.loopPlayback, required this.onPressed});

  final bool loopPlayback;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String label = loopPlayback ? '循环播放' : '播放一次';
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: SizedBox(
          width: 46,
          height: 46,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              loopPlayback ? Icons.repeat_rounded : Icons.repeat_one_rounded,
            ),
            iconSize: 27,
            color: loopPlayback ? _listeningText : _listeningMuted,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: loopPlayback ? _listeningText : _listeningMuted,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeModeButton extends StatelessWidget {
  const _PracticeModeButton({
    super.key,
    required this.mode,
    required this.onPressed,
  });

  final _ListeningPracticeMode mode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool shadowing = mode == _ListeningPracticeMode.shadowing;
    final String label = shadowing ? '跟读模式' : '听力模式';
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: SizedBox(
          width: 46,
          height: 46,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              shadowing ? Icons.mic_rounded : Icons.headphones_rounded,
            ),
            iconSize: 26,
            color: shadowing ? _listeningText : _listeningMuted,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: shadowing ? _listeningText : _listeningMuted,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimplePlayerButton extends StatelessWidget {
  const _SimplePlayerButton({
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final double size = primary ? 72 : 46;
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: primary ? 38 : 30,
        color: onPressed == null
            ? _listeningMuted.withValues(alpha: 0.32)
            : _listeningText,
        style: IconButton.styleFrom(
          backgroundColor: primary ? Colors.transparent : Colors.transparent,
          side: primary
              ? const BorderSide(color: _listeningText, width: 2)
              : BorderSide.none,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _ListeningErrorState extends StatelessWidget {
  const _ListeningErrorState({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 34,
              color: _listeningMuted,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _listeningMuted,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

String _levelLabel(String targetLevel) {
  return switch (targetLevel) {
    'intermediate' || 'L2' => 'L2 进阶',
    'advanced' || 'L3' => 'L3 精通',
    _ => 'L1 入门',
  };
}

String _ttsVoiceForTurn(InterviewSceneDialogueTurn turn) {
  return switch (turn.role) {
    InterviewSceneDialogueRole.interviewer => AppConfig.interviewerTtsVoice,
    InterviewSceneDialogueRole.candidate => AppConfig.candidateTtsVoice,
  };
}

Duration _estimateTurnDuration(InterviewSceneDialogueTurn turn) {
  final Iterable<RegExpMatch> tokens = RegExp(
    r"[A-Za-z]+(?:'[A-Za-z]+)?|\d+|[\u4e00-\u9fff]",
  ).allMatches(turn.text);
  final int tokenCount = tokens.length;
  final double rolePace = turn.role == InterviewSceneDialogueRole.interviewer
      ? 0.43
      : 0.48;
  final double seconds = (1.0 + tokenCount * rolePace).clamp(2.0, 14.0);
  return Duration(milliseconds: (seconds * 1000).round());
}

String _formatPlaybackTime(Duration duration) {
  final int totalSeconds = duration.inSeconds;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

Color _shadowScoreColor(int? score) {
  if (score == null) {
    return _listeningMuted;
  }
  if (score >= 85) {
    return _listeningGreen;
  }
  if (score >= 70) {
    return const Color(0xFF7A7141);
  }
  return const Color(0xFF9D5A3D);
}

String _shadowScoreSourceLabel(String source) {
  final String normalized = source.trim().toLowerCase();
  if (normalized.contains('backend') || normalized.contains('server')) {
    return '后端评分';
  }
  return '语音评分';
}

const Color _listeningBg = Color(0xFFFCFAF5);
const Color _listeningText = Color(0xFF20231F);
const Color _listeningMuted = Color(0xFF878B83);
const Color _listeningGreen = Color(0xFF315A3A);
