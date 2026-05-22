import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:speakeasy/features/interview/expression_shadow_scoring.dart';
import 'package:speakeasy/features/interview/expression_scene_orchestrator.dart';
import 'package:speakeasy/features/interview/interview_coach_schema.dart';
import 'package:speakeasy/features/interview/interview_engine.dart';
import 'package:speakeasy/features/interview/interview_llm_scheduler.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/features/interview/interview_wiki_store.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/voice_chat_service.dart';

const TextStyle _chromeTitleStyle = TextStyle(
  color: textPrimary,
  fontSize: 15,
  height: 1.12,
  fontWeight: FontWeight.w800,
  letterSpacing: 0,
);

const TextStyle _composerPrimaryTextStyle = TextStyle(
  fontSize: 16,
  height: 1.12,
  fontWeight: FontWeight.w800,
  letterSpacing: 0,
);

const TextStyle _composerCaptionStyle = TextStyle(
  color: textTertiary,
  fontSize: 11.5,
  height: 1.15,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
);

class InterviewPracticePage extends StatefulWidget {
  const InterviewPracticePage({
    super.key,
    this.sceneId = defaultInterviewSceneId,
    this.targetLevel = 'beginner',
    this.initialNodeId = '',
    this.llmScheduler,
  });

  final String sceneId;
  final String targetLevel;
  final String initialNodeId;
  final InterviewLlmScheduler? llmScheduler;

  @override
  State<InterviewPracticePage> createState() => _InterviewPracticePageState();
}

class _SpeakingCoachTurnResult {
  const _SpeakingCoachTurnResult({
    required this.userIntent,
    required this.mastery,
    required this.nextAction,
    required this.coachText,
    required this.targetExpressionUsed,
    required this.targetExpressionCompleted,
    required this.mainIssue,
    required this.betterVersion,
    required this.retryPrompt,
    required this.followupQuestion,
    required this.coachMove,
    required this.nextTeachingStage,
    required this.levelAdjustment,
    required this.diagnosisErrorType,
    required this.diagnosisEvidence,
    required this.triggerCodes,
    required this.targetActivation,
    required this.bridgePattern,
    required this.choices,
    required this.chunks,
    required this.drillLine,
    required this.naturalnessTip,
    required this.contrast,
    required this.transferPrompt,
    required this.reviewLink,
    required this.pronunciationTip,
    required this.feedbackShouldShow,
    required this.feedbackBrief,
    required this.feedbackDetails,
    required this.feedbackSuggestedExpression,
    required this.confidence,
    required this.wikiWeaknesses,
    this.masteredExpression,
    this.personalFact,
  });

  final String userIntent;
  final String mastery;
  final String nextAction;
  final String coachText;
  final bool targetExpressionUsed;
  final bool targetExpressionCompleted;
  final String mainIssue;
  final String betterVersion;
  final String retryPrompt;
  final String followupQuestion;
  final String coachMove;
  final String nextTeachingStage;
  final String levelAdjustment;
  final String diagnosisErrorType;
  final String diagnosisEvidence;
  final List<String> triggerCodes;
  final String targetActivation;
  final String bridgePattern;
  final List<String> choices;
  final List<String> chunks;
  final String drillLine;
  final String naturalnessTip;
  final List<String> contrast;
  final String transferPrompt;
  final String reviewLink;
  final String pronunciationTip;
  final bool feedbackShouldShow;
  final String feedbackBrief;
  final List<String> feedbackDetails;
  final String feedbackSuggestedExpression;
  final double confidence;
  final List<String> wikiWeaknesses;
  final String? masteredExpression;
  final String? personalFact;

  bool get keepsCurrentStage {
    return switch (nextAction) {
      'coach_retry' ||
      'scaffold' ||
      'model_then_retry' ||
      'pronunciation_focus' ||
      'grammar_focus' ||
      'repair_misunderstanding' ||
      'transfer_practice' => true,
      _ => false,
    };
  }

  bool get shouldSkipExtraLlm {
    return nextAction != 'advance' && nextAction != 'review_expression';
  }

  bool get suggestsMastery =>
      mastery == MasteryStatus.mastered || targetExpressionCompleted;

  bool get suggestsMiss =>
      mastery == 'missed' ||
      nextAction == 'coach_retry' ||
      nextAction == 'scaffold' ||
      nextAction == 'model_then_retry' ||
      nextAction == 'repair_misunderstanding';

  String get displayText {
    final bool isRetryAction =
        nextAction == 'coach_retry' ||
        nextAction == 'scaffold' ||
        nextAction == 'model_then_retry' ||
        nextAction == 'pronunciation_focus' ||
        nextAction == 'grammar_focus' ||
        nextAction == 'repair_misunderstanding';
    final List<String> lines = <String>[];
    void addLine(String value) {
      final String text = _cleanCoachDisplayLine(value);
      if (text.isEmpty || lines.contains(text)) {
        return;
      }
      lines.add(text);
    }

    addLine(coachText);

    if (targetExpressionCompleted) {
      if (betterVersion.isNotEmpty && !coachText.contains(betterVersion)) {
        addLine('更自然可以说：$betterVersion');
      }
      return lines.isEmpty ? '很好，这个意思已经表达出来了。' : lines.take(2).join('\n');
    }

    if (isRetryAction) {
      final String scaffold = _primaryScaffoldLine;
      if (scaffold.isNotEmpty) {
        addLine(scaffold);
      } else if (retryPrompt.isNotEmpty) {
        addLine(retryPrompt);
      }
      return lines.isEmpty ? '没关系，我们先说一小句。' : lines.take(2).join('\n');
    }

    if (nextAction == 'ask_followup' && betterVersion.isNotEmpty) {
      addLine('你也可以这样说：$betterVersion');
    } else if (coachMove == 'transfer_practice' && transferPrompt.isNotEmpty) {
      addLine(transferPrompt);
    }
    return lines.isEmpty ? '我听懂了，我们继续。' : lines.take(2).join('\n');
  }

  String get voiceFeedbackText {
    if (!feedbackShouldShow) {
      return '';
    }
    final List<String> lines = <String>[];
    void addLine(String value) {
      final String text = value.trim();
      if (text.isEmpty || lines.contains(text)) {
        return;
      }
      lines.add(text);
    }

    addLine(feedbackBrief);
    final List<String> details = feedbackDetails.isNotEmpty
        ? feedbackDetails
        : generatedTeachingDetails;
    for (final String detail in details) {
      addLine(detail);
    }
    if (feedbackSuggestedExpression.isNotEmpty &&
        !lines.any(
          (String line) => line.contains(feedbackSuggestedExpression),
        )) {
      addLine('可以这样说：$feedbackSuggestedExpression');
    }
    return lines.join('\n');
  }

  List<String> get generatedTeachingDetails {
    final List<String> lines = <String>[];
    void addLine(String value) {
      final String text = _cleanCoachDisplayLine(value);
      if (text.isEmpty || lines.contains(text)) {
        return;
      }
      lines.add(text);
    }

    addLine(coachText);
    if (mainIssue.isNotEmpty) {
      addLine('这轮主要卡点：$mainIssue');
    }
    if (betterVersion.isNotEmpty) {
      addLine('更自然可以说：$betterVersion');
    }
    if (retryPrompt.isNotEmpty) {
      addLine(retryPrompt);
    }
    if (bridgePattern.isNotEmpty) {
      addLine('先用这个句架：$bridgePattern');
    }
    if (choices.isNotEmpty) {
      addLine('可以先从这里开始：${choices.take(2).join(' / ')}');
    }
    if (drillLine.isNotEmpty) {
      addLine('先把这一小段说顺：$drillLine');
    } else if (chunks.isNotEmpty) {
      addLine('先把这一小段说顺：${chunks.first}');
    }
    if (naturalnessTip.isNotEmpty) {
      addLine(naturalnessTip);
    }
    if (pronunciationTip.isNotEmpty) {
      addLine(pronunciationTip);
    }
    return lines.take(5).toList(growable: false);
  }

  String get _primaryScaffoldLine {
    final String choice = choices.isNotEmpty ? choices.first : '';
    if (_looksLikeSpeakableEnglish(choice)) {
      return '你可以先说：$choice';
    }
    if (_looksLikeSpeakableEnglish(betterVersion)) {
      return '你可以先说：$betterVersion';
    }
    if (_looksLikeSpeakableEnglish(drillLine)) {
      return '先练这一小段：$drillLine';
    }
    for (final String chunk in chunks) {
      if (_looksLikeSpeakableEnglish(chunk)) {
        return '先练这一小段：$chunk';
      }
    }
    if (_looksLikeUsefulFrame(bridgePattern)) {
      return '先用这个框架：$bridgePattern';
    }
    return retryPrompt;
  }

  factory _SpeakingCoachTurnResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> wikiPatch = _mapFromDynamic(json['wikiPatch']);
    final Map<String, dynamic> analysis = _mapFromDynamic(json['analysis']);
    final Map<String, dynamic> plan = _mapFromDynamic(json['plan']);
    final Map<String, dynamic> lessonStatePatch = _mapFromDynamic(
      json['lessonStatePatch'],
    );
    final Map<String, dynamic> diagnosis = _mapFromDynamic(json['diagnosis']);
    final Map<String, dynamic> coachPlan = _mapFromDynamic(json['coachPlan']);
    final Map<String, dynamic> coachFeedback = _mapFromDynamic(
      json['coachFeedback'],
    );
    final String mastery = _stringFromDynamic(
      analysis['masteryStatus'] ?? json['mastery'],
    );
    final String nextAction = _stringFromDynamic(
      plan['nextAction'] ??
          lessonStatePatch['lastNextAction'] ??
          json['nextAction'],
    );
    final String selectedMoveId = _stringFromDynamic(
      plan['selectedMoveId'] ??
          lessonStatePatch['lastCoachMoveId'] ??
          json['coachMove'],
    );
    final String nextTeachingStage = _stringFromDynamic(
      plan['nextTeachingStage'] ?? lessonStatePatch['teachingStage'],
    );
    final bool targetExpressionCompleted =
        analysis['targetExpressionCompleted'] == true ||
        lessonStatePatch['targetExpressionCompleted'] == true ||
        json['targetExpressionCompleted'] == true;
    return _SpeakingCoachTurnResult(
      userIntent: _stringFromDynamic(json['userIntent']),
      mastery: mastery,
      nextAction: nextAction,
      coachText: _stringFromDynamic(json['coachMessage'] ?? json['coachText']),
      targetExpressionUsed:
          targetExpressionCompleted || json['targetExpressionUsed'] == true,
      targetExpressionCompleted: targetExpressionCompleted,
      mainIssue: _stringFromDynamic(json['mainIssue']),
      betterVersion: _stringFromDynamic(json['betterVersion']),
      retryPrompt: _stringFromDynamic(json['retryPrompt']),
      followupQuestion: _stringFromDynamic(
        json['formalQuestion'] ?? json['followupQuestion'],
      ),
      coachMove: selectedMoveId,
      nextTeachingStage: nextTeachingStage,
      levelAdjustment: _stringFromDynamic(json['levelAdjustment']),
      diagnosisErrorType: _stringFromDynamic(
        analysis['errorType'] ?? diagnosis['errorType'],
      ),
      diagnosisEvidence: _stringFromDynamic(diagnosis['evidence']),
      triggerCodes: _stringListFromDynamic(
        analysis['triggerCodes'],
      ).where(InterviewCoachSchema.isTriggerCode).toList(growable: false),
      targetActivation: _stringFromDynamic(coachPlan['targetActivation']),
      bridgePattern: _stringFromDynamic(coachPlan['bridgePattern']),
      choices: _coachPlanStringListFromDynamic(coachPlan['choices']),
      chunks: _coachPlanStringListFromDynamic(coachPlan['chunks']),
      drillLine: _stringFromDynamic(coachPlan['drillLine']),
      naturalnessTip: _stringFromDynamic(coachPlan['naturalnessTip']),
      contrast: _coachPlanStringListFromDynamic(coachPlan['contrast']),
      transferPrompt: _stringFromDynamic(coachPlan['transferPrompt']),
      reviewLink: _stringFromDynamic(coachPlan['reviewLink']),
      pronunciationTip: _stringFromDynamic(coachPlan['pronunciationTip']),
      feedbackShouldShow:
          coachFeedback['shouldShow'] == true ||
          (coachFeedback['shouldShow'] != false &&
              (_stringFromDynamic(coachFeedback['brief']).isNotEmpty ||
                  _coachPlanStringListFromDynamic(
                    coachFeedback['details'],
                  ).isNotEmpty)),
      feedbackBrief: _stringFromDynamic(coachFeedback['brief']),
      feedbackDetails: _coachPlanStringListFromDynamic(
        coachFeedback['details'],
      ),
      feedbackSuggestedExpression: _stringFromDynamic(
        coachFeedback['suggestedExpression'],
      ),
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.6)
          .clamp(0, 1)
          .toDouble(),
      wikiWeaknesses: _stringListFromDynamic(wikiPatch['weaknesses']),
      masteredExpression: _nullableStringFromDynamic(
        wikiPatch['masteredExpression'],
      ),
      personalFact: _nullableStringFromDynamic(wikiPatch['personalFact']),
    );
  }
}

Map<String, dynamic> _mapFromDynamic(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

String _stringFromDynamic(Object? value) {
  return value?.toString().trim() ?? '';
}

String? _nullableStringFromDynamic(Object? value) {
  final String text = _stringFromDynamic(value);
  return text.isEmpty ? null : text;
}

List<String> _stringListFromDynamic(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((Object? item) => _stringFromDynamic(item))
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _coachPlanStringListFromDynamic(Object? value) {
  if (value is String) {
    return value
        .split(RegExp(r'[\r\n]+|[；;]'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((Object? item) {
        if (item is Map) {
          final Map<String, dynamic> map = item.cast<String, dynamic>();
          final String label = _stringFromDynamic(
            map['label'] ?? map['title'] ?? map['name'],
          );
          final String text = _stringFromDynamic(
            map['text'] ?? map['body'] ?? map['value'] ?? map['tip'],
          );
          if (label.isNotEmpty && text.isNotEmpty) {
            return '$label：$text';
          }
          return label.isNotEmpty ? label : text;
        }
        return _stringFromDynamic(item);
      })
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

String _cleanCoachDisplayLine(String value) {
  String text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) {
    return '';
  }

  final RegExp fieldLabel = RegExp(
    r'(?:^|\s)(目标|句型桥|自然度|发音/流利度|发音流利度|拆开说|选一个开口|先练这个语块|复习关联)[：:]',
  );
  final RegExpMatch? firstLabel = fieldLabel.firstMatch(text);
  if (firstLabel != null) {
    if (firstLabel.start > 0) {
      text = text.substring(0, firstLabel.start).trim();
    } else {
      text = text.substring(firstLabel.end).trim();
    }
  }

  const List<String> blockedFragments = <String>[
    'Speak in one calm thought group',
    'thought group',
    '目标表达',
    '逐字复述',
    '顺带复习',
  ];
  for (final String fragment in blockedFragments) {
    if (text.toLowerCase().contains(fragment.toLowerCase())) {
      return '';
    }
  }

  return text;
}

bool _looksLikeSpeakableEnglish(String value) {
  final String text = _cleanCoachDisplayLine(value);
  if (text.isEmpty || text.length > 130 || text.contains('·')) {
    return false;
  }
  if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
    return false;
  }
  if (!RegExp(r'[A-Za-z]{2,}').hasMatch(text)) {
    return false;
  }
  if (RegExp(
    r'\b(goal|target|pattern|rhythm|thought group|naturalness)\b',
    caseSensitive: false,
  ).hasMatch(text)) {
    return false;
  }
  return true;
}

bool _looksLikeUsefulFrame(String value) {
  final String text = _cleanCoachDisplayLine(value);
  if (text.isEmpty || text.length > 100 || text.contains('·')) {
    return false;
  }
  if (RegExp(
    r'\b(thought group|naturalness|pronunciation|fluency)\b',
    caseSensitive: false,
  ).hasMatch(text)) {
    return false;
  }
  return RegExp(r'[A-Za-z]').hasMatch(text);
}

class _InterviewPracticePageState extends State<InterviewPracticePage> {
  final TextEditingController _answerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final InterviewLlmScheduler _llmScheduler;
  late final InterviewWikiStore _wikiStore;
  final List<InterviewChatMessage> _messages = <InterviewChatMessage>[];
  final Map<int, String> _messageTranslations = <int, String>{};
  final Set<int> _translatedMessageIndexes = <int>{};
  final Set<int> _translatingMessageIndexes = <int>{};
  final Set<int> _revealedVoiceMessageIndexes = <int>{};
  final Set<int> _expandedExpressionSuggestionIndexes = <int>{};
  final List<_ComposerHintData> _composerHintStack = <_ComposerHintData>[];

  InterviewLibrary? _library;
  InterviewSceneGraph? _sceneGraph;
  InterviewPracticeEngine? _engine;
  InterviewPracticeSession? _session;
  InterviewReview? _review;
  PronunciationScore? _lastPronunciationScore;
  String? _aiReviewNote;
  String? _wikiWriteSummary;
  String? _errorText;
  bool _loading = true;
  bool _submitting = false;
  bool _finishingReview = false;
  bool _hintThinking = false;
  bool _recording = false;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTimer;
  bool _transcribing = false;
  bool _llmThinking = false;
  bool _wikiCompiling = false;
  bool _exitInProgress = false;
  bool _exitFinalizationStarted = false;
  String? _pendingVoiceAudioPath;
  late String _runtimeTargetLevel;
  VoiceChatService? _streamingAsrService;
  StreamSubscription<String>? _streamingAsrTextSub;
  StreamSubscription<String>? _streamingAsrPreviewSub;
  StreamSubscription<String>? _streamingAsrConnectionSub;
  Completer<String?>? _streamingAsrCompleter;
  Future<void>? _streamingAsrStartFuture;
  String _streamingAsrFinalText = '';
  String _streamingAsrPreviewText = '';
  final List<Uint8List> _streamingAsrPendingChunks = <Uint8List>[];
  int _streamingAsrPendingBytes = 0;
  int _activeComposerHintIndex = -1;
  String _composerHintStage = '';

  @override
  void initState() {
    super.initState();
    _llmScheduler = widget.llmScheduler ?? InterviewLlmScheduler();
    _wikiStore = InterviewWikiStore(sceneId: widget.sceneId);
    _runtimeTargetLevel = _normalizeSceneMapTargetLevel(widget.targetLevel);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_closeStreamingAsrCapture());
    _answerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetMessageUiState() {
    _messageTranslations.clear();
    _translatedMessageIndexes.clear();
    _translatingMessageIndexes.clear();
    _revealedVoiceMessageIndexes.clear();
    _expandedExpressionSuggestionIndexes.clear();
    _clearComposerHintState();
  }

  void _clearComposerHintState() {
    _composerHintStack.clear();
    _activeComposerHintIndex = -1;
    _composerHintStage = '';
  }

  void _expandExistingExpressionSuggestions() {
    _expandedExpressionSuggestionIndexes.clear();
  }

  Future<void> _bootstrap({InterviewNextRoundMode? roundMode}) async {
    setState(() {
      _loading = true;
      _errorText = null;
      _wikiWriteSummary = null;
    });
    try {
      final InterviewSceneGraph sceneGraph = await loadInterviewSceneGraph(
        sceneId: widget.sceneId,
      );
      final InterviewLibrary library = sceneGraph.toLibrary();
      if (!mounted) {
        return;
      }
      final String userId = AppSessionScope.of(context).nickname;
      final InterviewPracticeEngine engine = InterviewPracticeEngine(
        library: library,
        sceneGraph: sceneGraph,
      );
      final List<InterviewPersonalWikiExpression> masteredWikiExpressions =
          _wikiStore.loadMasteredExpressions();
      final List<InterviewExpressionLearningProgress> preparedLearningProgress =
          _wikiStore.loadExpressionLearningProgress();
      final List<InterviewWeakExpressionState> weakExpressions = _wikiStore
          .loadUserGrowthWiki()
          .weakExpressions;
      final String selectedTargetLevel = _runtimeTargetLevel;
      final bool hasInitialNode = widget.initialNodeId.trim().isNotEmpty;
      final InterviewActiveSessionSnapshot? activeSnapshot =
          roundMode == null && !hasInitialNode
          ? _wikiStore.loadActiveSession(userId: userId)
          : null;
      final Set<String> libraryExpressionIds = library.expressions
          .map((InterviewExpression expression) => expression.id)
          .toSet();
      final bool canRestoreActiveSnapshot =
          activeSnapshot != null &&
          activeSnapshot.session.publicSceneId == sceneGraph.id &&
          activeSnapshot.session.targetLevel == selectedTargetLevel &&
          activeSnapshot.messages.isNotEmpty &&
          activeSnapshot.session.plannedStages.every(
            (String stage) =>
                stage == 'wrap_up' || libraryExpressionIds.contains(stage),
          ) &&
          activeSnapshot.session.stageExpressionTargets.values.every(
            (InterviewExpression expression) =>
                libraryExpressionIds.contains(expression.id),
          );
      if (canRestoreActiveSnapshot) {
        final InterviewActiveSessionSnapshot snapshot = activeSnapshot;
        _hydrateMissingSessionTargets(snapshot.session, sceneGraph);
        final List<InterviewChatMessage> restoredMessages =
            _messagesForRestoredSnapshot(snapshot, sceneGraph);
        final bool appendedResumeMessage =
            restoredMessages.length > snapshot.messages.length;
        setState(() {
          _resetMessageUiState();
          _library = library;
          _sceneGraph = sceneGraph;
          _engine = engine;
          _session = snapshot.session;
          _messages
            ..clear()
            ..addAll(restoredMessages);
          _expandExistingExpressionSuggestions();
          _review = null;
          _aiReviewNote = null;
          _wikiWriteSummary = null;
          _lastPronunciationScore = null;
          _pendingVoiceAudioPath = null;
          _loading = false;
        });
        if (appendedResumeMessage) {
          unawaited(_saveActiveSession());
          unawaited(_speakAssistant(restoredMessages.last.text));
        }
        _scrollToBottom();
        return;
      }
      if (activeSnapshot != null) {
        unawaited(_wikiStore.clearActiveSession());
      }
      final InterviewNextRoundMode resolvedRoundMode =
          roundMode ??
          engine.roundModeForMasteredExpressions(
            masteredWikiExpressions,
            targetLevel: selectedTargetLevel,
          );
      final InterviewPracticeSession session = engine.startSession(
        userId: userId,
        targetLevel: selectedTargetLevel,
        roundMode: resolvedRoundMode,
        masteredWikiExpressions: masteredWikiExpressions,
        preparedLearningProgress: preparedLearningProgress,
        weakExpressions: weakExpressions,
      );
      _prioritizeInitialNode(session, sceneGraph);
      final InterviewQuestionPlan openingPlan = engine
          .openingQuestionPlanForSession(
            session: session,
            masteredWikiExpressions: masteredWikiExpressions,
          );
      final String opening = openingPlan.localFallbackQuestion;
      if (!mounted) {
        return;
      }
      setState(() {
        _resetMessageUiState();
        _library = library;
        _sceneGraph = sceneGraph;
        _engine = engine;
        _session = session;
        _messages
          ..clear()
          ..add(
            InterviewChatMessage(
              role: 'assistant',
              text: opening,
              createdAt: DateTime.now(),
              stage: session.currentStage,
              tag: openingPlan.predictedTag,
              targetExpression: openingPlan.targetExpression,
              questionPlanAction: openingPlan.action,
              mustAskAbout: openingPlan.mustAskAbout,
            ),
          );
        _review = null;
        _aiReviewNote = null;
        _wikiWriteSummary = null;
        _lastPronunciationScore = null;
        _pendingVoiceAudioPath = null;
        _loading = false;
      });
      unawaited(_saveActiveSession());
      unawaited(_speakAssistant(opening));
      _prewarmQuestionSession();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorText = '面试功能加载失败：$error';
      });
    }
  }

  void _prioritizeInitialNode(
    InterviewPracticeSession session,
    InterviewSceneGraph sceneGraph,
  ) {
    final String nodeId = widget.initialNodeId.trim();
    if (nodeId.isEmpty) {
      return;
    }
    final InterviewExpressionNode? node = sceneGraph.nodeById(nodeId);
    if (node == null ||
        _normalizeSceneMapTargetLevel(node.targetLevel) !=
            _normalizeSceneMapTargetLevel(session.targetLevel)) {
      return;
    }
    final List<String> planned = session.plannedStages
        .where((String stage) => stage != nodeId && stage != 'wrap_up')
        .toList(growable: true);
    session.plannedStages = <String>[nodeId, ...planned, 'wrap_up'];
    session.stageIndex = 0;
    session.stageExpressionTargets[nodeId] = node.toExpression();
  }

  List<InterviewChatMessage> _messagesForRestoredSnapshot(
    InterviewActiveSessionSnapshot snapshot,
    InterviewSceneGraph sceneGraph,
  ) {
    final List<InterviewChatMessage> restored =
        List<InterviewChatMessage>.from(snapshot.messages)..removeWhere(
          (InterviewChatMessage message) =>
              message.role == 'assistant' &&
              (message.isMastered || message.isAlignment),
        );
    final InterviewPracticeSession session = snapshot.session;
    while (restored.isNotEmpty) {
      final InterviewChatMessage last = restored.last;
      if (last.role != 'assistant') {
        break;
      }
      if (!last.isHint && !_isGenericInterviewQuestionDirective(last.text)) {
        break;
      }
      restored.removeLast();
    }
    if (restored.isNotEmpty) {
      final InterviewChatMessage last = restored.last;
      if (last.role == 'assistant' &&
          last.stage == session.currentStage &&
          !last.isHint &&
          !_isGenericInterviewQuestionDirective(last.text)) {
        return restored;
      }
    }
    final InterviewExpressionNode? node = sceneGraph.nodeById(
      session.currentStage,
    );
    if (node == null) {
      return restored;
    }
    final ExpressionSceneOrchestrator orchestrator =
        const ExpressionSceneOrchestrator();
    final ExpressionSceneTurnPlan plan = orchestrator.openingPlan(
      node: ExpressionSceneNode.fromInterviewNode(node),
      mode: session.roundMode == InterviewNextRoundMode.review
          ? ExpressionScenePracticeMode.review
          : ExpressionScenePracticeMode.newLesson,
      openingType: ExpressionSceneOpeningType.resumeSession,
      hasLearnerHistory: true,
    );
    restored.add(
      InterviewChatMessage(
        role: 'assistant',
        text: plan.localFallbackQuestion,
        createdAt: DateTime.now(),
        stage: session.currentStage,
        tag: plan.predictedTag,
        targetExpression:
            session.stageExpressionTargets[session.currentStage] ??
            node.toExpression(),
        questionPlanAction: plan.action,
        mustAskAbout: plan.mustAskAbout,
      ),
    );
    return restored;
  }

  void _hydrateMissingSessionTargets(
    InterviewPracticeSession session,
    InterviewSceneGraph sceneGraph,
  ) {
    for (final String stage in session.plannedStages) {
      if (stage == 'wrap_up' || session.stageExpressionTargets[stage] != null) {
        continue;
      }
      final InterviewExpressionNode? node = sceneGraph.nodeById(stage);
      if (node != null) {
        session.stageExpressionTargets[stage] = node.toExpression();
      }
    }
    final String currentStage = session.currentStage;
    if (currentStage != 'wrap_up' &&
        session.stageExpressionTargets[currentStage] == null) {
      final InterviewExpressionNode? node = sceneGraph.nodeById(currentStage);
      if (node != null) {
        session.stageExpressionTargets[currentStage] = node.toExpression();
      }
    }
  }

  bool _isGenericInterviewQuestionDirective(String text) {
    final String normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    const List<String> blockedPhrases = <String>[
      'give me your direct answer first',
      'give me a direct answer first',
      'direct answer first',
      'answer directly',
      'please answer directly',
      'give me your answer',
      'try again',
      'say it again',
      'repeat after me',
      'use the expression',
      'use this expression',
      'can you answer this part of the interview',
    ];
    return blockedPhrases.any(normalized.contains);
  }

  Future<void> _submitAnswer({
    String? sourceAudioPath,
    String? overrideText,
    Stopwatch? voicePipelineWatch,
  }) async {
    final Stopwatch pipelineWatch =
        voicePipelineWatch ?? (Stopwatch()..start());
    _logVoiceLatency('submit:start', pipelineWatch);
    final InterviewPracticeEngine? engine = _engine;
    final InterviewPracticeSession? session = _session;
    final InterviewLibrary? library = _library;
    if (engine == null || session == null || library == null || _submitting) {
      return;
    }
    final String userText = normalizeInterviewText(
      overrideText ?? _answerController.text,
    );
    if (userText.isEmpty) {
      return;
    }
    final String? resolvedAudioPath = sourceAudioPath ?? _pendingVoiceAudioPath;
    final String answeredStage = session.currentStage;
    final DateTime now = DateTime.now();
    final bool hasVoiceAnswer =
        resolvedAudioPath != null && resolvedAudioPath.isNotEmpty;
    final int userMessageIndex = _messages.length;
    final InterviewChatMessage? answeredQuestionMessage =
        _latestInterviewQuestion();
    final InterviewExpression? answerTargetExpression =
        answeredQuestionMessage?.targetExpression ??
        session.stageExpressionTargets[answeredStage] ??
        _sceneGraph?.nodeById(answeredStage)?.toExpression();
    setState(() {
      _submitting = true;
      _errorText = null;
      _pendingVoiceAudioPath = null;
      _answerController.clear();
      _messages.add(
        InterviewChatMessage(
          role: 'user',
          text: userText,
          createdAt: now,
          stage: answeredStage,
          voiceAudioPath: hasVoiceAnswer ? resolvedAudioPath : '',
          targetExpression: answerTargetExpression,
        ),
      );
    });
    _scrollToBottom();
    _logVoiceLatency('user_message:rendered', pipelineWatch);

    if (hasVoiceAnswer) {
      unawaited(
        _scoreVoiceAnswerInBackground(
          audioPath: resolvedAudioPath,
          userText: userText,
          userMessageIndex: userMessageIndex,
          answerTargetExpression: answerTargetExpression,
          answeredQuestionMessage: answeredQuestionMessage,
          pipelineWatch: pipelineWatch,
        ),
      );
    }

    _SpeakingCoachTurnResult? coachTurn;
    try {
      coachTurn =
          await _requestSpeakingCoachTurn(
            engine: engine,
            session: session,
            userText: userText,
            answeredStage: answeredStage,
            targetExpression: answerTargetExpression,
            questionMessage: answeredQuestionMessage,
          ).timeout(
            const Duration(milliseconds: 7200),
            onTimeout: () {
              _logVoiceLatency('coach_skill:timeout', pipelineWatch);
              return null;
            },
          );
    } catch (error) {
      debugPrint('[SpeakingCoachSkill] request failed: $error');
    }
    _logVoiceLatency('coach_skill:ready', pipelineWatch);
    if (coachTurn != null) {
      _applyCoachLessonStatePatch(
        session: session,
        answeredStage: answeredStage,
        coachTurn: coachTurn,
        targetExpression: answerTargetExpression,
      );
    }

    Map<String, InterviewExpressionMasteryResult> masteryOverrides =
        _coachMasteryOverrides(
          coachTurn: coachTurn,
          targetExpression: answerTargetExpression,
        );
    try {
      if (masteryOverrides.isEmpty) {
        masteryOverrides =
            await _masteryOverridesForAnswer(
              engine: engine,
              session: session,
              userText: userText,
            ).timeout(
              const Duration(milliseconds: 1300),
              onTimeout: () {
                _logVoiceLatency('mastery_llm:timeout', pipelineWatch);
                return const <String, InterviewExpressionMasteryResult>{};
              },
            );
      }
    } catch (error) {
      debugPrint('[InterviewLatency] mastery override skipped: $error');
    }
    _logVoiceLatency('mastery:ready', pipelineWatch);
    final InterviewCoachReply localReply = engine.answer(
      session,
      userText: userText,
      masteryOverrides: masteryOverrides,
    );
    final bool coachKeepsCurrentStage =
        coachTurn?.keepsCurrentStage == true && !localReply.isSessionEnd;
    if (coachKeepsCurrentStage) {
      _restoreSessionStageForCoach(session, answeredStage);
      if (coachTurn?.suggestsMastery != true) {
        _removeRejectedMastery(session, answerTargetExpression);
      }
    }
    final String effectiveStage = coachKeepsCurrentStage
        ? answeredStage
        : localReply.stage;
    final String effectiveNextAction = coachKeepsCurrentStage
        ? (coachTurn?.nextAction == 'ask_followup' ||
                  coachTurn?.nextAction == 'transfer_practice'
              ? 'followup'
              : 'coach_retry')
        : localReply.nextAction;
    final _SpeakingCoachTurnResult? readyCoachTurn = coachTurn;
    final bool coachProvidesTurnText =
        readyCoachTurn != null &&
        !localReply.isSessionEnd &&
        (coachKeepsCurrentStage ||
            readyCoachTurn.nextAction == 'ask_followup' ||
            readyCoachTurn.nextAction == 'transfer_practice' ||
            (readyCoachTurn.nextAction == 'advance' &&
                readyCoachTurn.followupQuestion.isNotEmpty));
    String assistantText = coachProvidesTurnText
        ? readyCoachTurn.displayText
        : localReply.assistantMessage;
    String splitFormalQuestion = coachProvidesTurnText
        ? (readyCoachTurn.followupQuestion.trim())
        : '';
    final String questionTag =
        stageToPrimaryTag[effectiveStage] ?? localReply.predictedTag;
    final List<InterviewExpression> expressionHints =
        _expressionHintsForNextQuestion(
          session: session,
          library: library,
          predictedTag: questionTag,
          questionStage: effectiveStage,
        );
    final InterviewQuestionPlan questionPlan = engine
        .followupQuestionPlanForReply(
          session: session,
          localReply: localReply,
          userText: userText,
          expressions: expressionHints,
          reuseTarget: localReply.alignmentExpression,
        );

    final bool shouldAdaptWithLlm =
        !coachProvidesTurnText &&
        !localReply.isSessionEnd &&
        localReply.nextAction != 'offer_hint' &&
        localReply.nextAction != 'coach_retry';
    if (localReply.nextAction == 'coach_retry') {
      final InterviewExpression? targetExpression =
          localReply.alignmentExpression ??
          questionPlan.targetExpression ??
          answerTargetExpression;
      final InterviewExpressionMasteryResult? masteryResult =
          targetExpression == null
          ? null
          : localReply.masteryResults[targetExpression.id];
      if (coachTurn != null && coachTurn.coachText.isNotEmpty) {
        assistantText = coachTurn.displayText;
        _logVoiceLatency('diagnosis:coach_skill', pipelineWatch);
      } else if (targetExpression != null && masteryResult != null) {
        setState(() => _llmThinking = true);
        final String answeredQuestion =
            answeredQuestionMessage?.text ??
            questionForStage(answeredStage, simplified: session.simplifiedMode);
        final Future<InterviewAnswerDiagnosis?> diagnosisFuture = _llmScheduler
            .diagnoseAnswerForCoach(
              session: session,
              targetExpression: targetExpression,
              question: answeredQuestion,
              userText: userText,
              localResult: masteryResult,
              attemptNumber: session.stageAttempts[answeredStage] ?? 1,
              messages: _messages,
              node: _sceneGraph?.nodeById(targetExpression.id),
              memoryPack: _memoryPackFor(
                session: session,
                stage: answeredStage,
                tag: targetExpression.tag,
                query: '$userText ${targetExpression.text}',
              ),
            );
        final InterviewAnswerDiagnosis? diagnosis = await diagnosisFuture
            .timeout(
              const Duration(milliseconds: 1800),
              onTimeout: () {
                _logVoiceLatency('diagnosis_llm:timeout', pipelineWatch);
                return null;
              },
            );
        if (diagnosis != null && diagnosis.hasCoachMessage) {
          assistantText = diagnosis.coachMessage;
          unawaited(
            _wikiStore.recordAnswerDiagnosis(
              session: session,
              targetExpression: targetExpression,
              diagnosis: diagnosis,
              userText: userText,
            ),
          );
        } else {
          assistantText = _localAnswerDiagnosisCoachMessage(
            userText: userText,
            targetExpression: targetExpression,
            masteryResult: masteryResult,
            attemptNumber: session.stageAttempts[answeredStage] ?? 1,
          );
        }
        _logVoiceLatency('diagnosis:ready', pipelineWatch);
      }
    } else if (shouldAdaptWithLlm) {
      setState(() => _llmThinking = true);
      final Future<String?> questionFuture = _llmScheduler.adaptNextQuestion(
        session: session,
        plan: questionPlan,
        userText: userText,
        messages: _messages,
        memoryPack: _memoryPackFor(
          session: session,
          stage: questionPlan.stage,
          tag: questionPlan.predictedTag,
          query:
              '$userText ${questionPlan.mustAskAbout} ${questionPlan.targetExpressionText}',
        ),
      );
      final String? llmQuestion = await questionFuture.timeout(
        const Duration(milliseconds: 1800),
        onTimeout: () {
          _logVoiceLatency('question_llm:timeout', pipelineWatch);
          return null;
        },
      );
      if (llmQuestion != null && llmQuestion.isNotEmpty) {
        assistantText = llmQuestion;
        splitFormalQuestion = '';
      }
      _logVoiceLatency('question:ready', pipelineWatch);
    }

    if (!mounted) {
      return;
    }
    final List<InterviewExpression> masteredExpressionsForPersistence =
        coachKeepsCurrentStage
        ? (coachTurn?.targetExpressionCompleted == true &&
                  answerTargetExpression != null
              ? <InterviewExpression>[answerTargetExpression]
              : const <InterviewExpression>[])
        : localReply.masteredExpressions;
    unawaited(
      _persistMasteredExpressions(
        masteredExpressionsForPersistence,
        stage: answeredStage,
        userText: userText,
        masteryResults: localReply.masteryResults,
        attemptCount: session.stageAttempts[answeredStage] ?? 1,
      ),
    );
    if (coachTurn != null && answerTargetExpression != null) {
      unawaited(
        _recordSpeakingCoachWikiPatch(
          session: session,
          targetExpression: answerTargetExpression,
          coachTurn: coachTurn,
          userText: userText,
        ),
      );
    }
    if (!mounted) {
      return;
    }
    final String voiceFeedbackText = hasVoiceAnswer
        ? _coachGeneratedVoiceFeedbackText(
            coachTurn,
            allowCoachTextFallback:
                coachProvidesTurnText ||
                coachKeepsCurrentStage ||
                localReply.nextAction == 'coach_retry',
            fallbackCoachText: assistantText,
          )
        : '';
    final bool attachTeachingPromptToVoice =
        hasVoiceAnswer &&
        userMessageIndex < _messages.length &&
        !localReply.isSessionEnd &&
        voiceFeedbackText.isNotEmpty;
    final String expressionSuggestionText = attachTeachingPromptToVoice
        ? voiceFeedbackText
        : '';
    final String expressionSuggestionTag =
        answerTargetExpression?.tag ?? questionTag;
    final bool voiceFeedbackConsumesAssistantText =
        attachTeachingPromptToVoice &&
        (coachProvidesTurnText ||
            coachKeepsCurrentStage ||
            localReply.nextAction == 'coach_retry');
    final bool suppressTeachingBubble =
        hasVoiceAnswer && localReply.nextAction == 'coach_retry';
    final bool addCoachMessageBubble =
        !voiceFeedbackConsumesAssistantText &&
        !suppressTeachingBubble &&
        assistantText.trim().isNotEmpty;
    final bool addFormalQuestionBubble =
        splitFormalQuestion.isNotEmpty &&
        splitFormalQuestion != assistantText.trim();
    final String speechText = addFormalQuestionBubble
        ? splitFormalQuestion
        : addCoachMessageBubble
        ? assistantText
        : '';
    final bool shouldPlayCorrectEffect =
        hasVoiceAnswer && masteredExpressionsForPersistence.isNotEmpty;
    final bool shouldPlayImproveEffect =
        hasVoiceAnswer &&
        !shouldPlayCorrectEffect &&
        expressionSuggestionText.isNotEmpty;
    if (effectiveNextAction != 'offer_hint' && speechText.trim().isNotEmpty) {
      unawaited(
        AudioServiceScope.of(context).prewarmAutoAssistantTts(speechText),
      );
    }
    setState(() {
      _llmThinking = false;
      _submitting = false;
      if (masteredExpressionsForPersistence.isNotEmpty &&
          userMessageIndex < _messages.length) {
        _messages[userMessageIndex] = _copyMessageWithMasteryFeedback(
          _messages[userMessageIndex],
          targetExpression: masteredExpressionsForPersistence.first,
        );
      }
      if (expressionSuggestionText.isNotEmpty &&
          userMessageIndex < _messages.length) {
        _messages[userMessageIndex] = _copyMessageWithExpressionSuggestion(
          _messages[userMessageIndex],
          suggestionText: expressionSuggestionText,
          suggestionTag: expressionSuggestionTag,
        );
      }
      if (addCoachMessageBubble) {
        _messages.add(
          InterviewChatMessage(
            role: 'assistant',
            text: assistantText,
            createdAt: DateTime.now(),
            stage: effectiveStage,
            status:
                effectiveNextAction == 'followup' ||
                    effectiveNextAction == 'coach_retry'
                ? localReply.coverageStatus
                : '',
            tag: questionPlan.predictedTag,
            isHint: effectiveNextAction == 'offer_hint',
            targetExpression: coachKeepsCurrentStage
                ? answerTargetExpression
                : questionPlan.targetExpression,
            questionPlanAction: coachKeepsCurrentStage
                ? coachTurn?.nextAction ?? questionPlan.action
                : questionPlan.action,
            mustAskAbout: questionPlan.mustAskAbout,
          ),
        );
      }
      if (addFormalQuestionBubble) {
        _messages.add(
          InterviewChatMessage(
            role: 'assistant',
            text: splitFormalQuestion,
            createdAt: DateTime.now(),
            stage: effectiveStage,
            status: '',
            tag: questionPlan.predictedTag,
            targetExpression: questionPlan.targetExpression,
            questionPlanAction: questionPlan.action,
            mustAskAbout: questionPlan.mustAskAbout,
          ),
        );
      }
    });
    _logVoiceLatency('assistant_message:rendered', pipelineWatch);
    unawaited(_saveActiveSession());
    _scrollToBottom();
    if (shouldPlayCorrectEffect || shouldPlayImproveEffect) {
      unawaited(
        AudioServiceScope.of(context).playVoiceFeedbackEffect(
          shouldPlayCorrectEffect
              ? VoiceFeedbackEffect.correct
              : VoiceFeedbackEffect.improve,
        ),
      );
    }
    if (effectiveNextAction != 'offer_hint' && speechText.trim().isNotEmpty) {
      unawaited(_speakAssistant(speechText));
    }

    if (!coachKeepsCurrentStage && localReply.isSessionEnd) {
      await _finishReview();
    }
  }

  Future<void> _finishReview() async {
    final InterviewPracticeEngine? engine = _engine;
    final InterviewPracticeSession? session = _session;
    if (engine == null || session == null) {
      return;
    }
    if (_review != null) {
      _scrollToBottom();
      return;
    }
    setState(() {
      _finishingReview = true;
      _llmThinking = false;
      _submitting = false;
    });
    final InterviewReview review = engine.review(
      session,
      masteredWikiExpressions: _wikiStore.loadMasteredExpressions(),
    );
    await _wikiStore.clearActiveSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _review = review;
      _finishingReview = false;
    });
    _scrollToBottom();
    final String? note = await _llmScheduler.generateReviewNote(
      session: session,
      review: review,
    );
    if (!mounted) {
      return;
    }
    if (note != null && note.isNotEmpty) {
      setState(() => _aiReviewNote = note);
      _scrollToBottom();
    }
    if (_exitFinalizationStarted) {
      return;
    }
    await _compileWikiFromReview(session: session, review: review);
  }

  Future<void> _compileWikiFromReview({
    required InterviewPracticeSession session,
    required InterviewReview review,
  }) async {
    if (mounted) {
      setState(() => _wikiCompiling = true);
    }
    final String? summary = await _writeWikiFromReview(
      session: session,
      review: review,
      pronunciationScore: _lastPronunciationScore,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _wikiCompiling = false;
      if (summary != null) {
        _wikiWriteSummary = summary;
      }
    });
    _scrollToBottom();
  }

  Future<String?> _writeWikiFromReview({
    required InterviewPracticeSession session,
    required InterviewReview review,
    required PronunciationScore? pronunciationScore,
  }) async {
    final List<InterviewPersonalWikiExpression> masteredExpressions = _wikiStore
        .loadMasteredExpressions();
    final InterviewCompiledWiki existingWiki = _wikiStore.loadCompiledWiki();
    InterviewCompiledWiki? compiled = await _llmScheduler.compilePersonalWiki(
      session: session,
      review: review,
      masteredExpressions: masteredExpressions,
      existingWiki: existingWiki,
    );
    compiled ??= _localCompiledWiki(
      session: session,
      review: review,
      masteredExpressions: masteredExpressions,
    );
    String? summary;
    if (compiled != null && !compiled.isEmpty) {
      await _wikiStore.mergeCompiledWiki(compiled);
      summary = _formatWikiWriteSummary(compiled);
    }
    await _wikiStore.updateUserGrowthWikiFromReview(
      session: session,
      review: review,
      pronunciationOverall: pronunciationScore?.overall,
      pronunciationAccuracy: pronunciationScore?.accuracy,
      pronunciationFluency: pronunciationScore?.fluency,
      pronunciationCompleteness: pronunciationScore?.completeness,
    );
    return summary;
  }

  String _formatWikiWriteSummary(InterviewCompiledWiki wiki) {
    final List<String> parts = <String>[
      if (wiki.personalFacts.isNotEmpty) '个人事实 ${wiki.personalFacts.length}',
      if (wiki.interviewStories.isNotEmpty)
        '面试故事 ${wiki.interviewStories.length}',
      if (wiki.weakPatterns.isNotEmpty) '薄弱模式 ${wiki.weakPatterns.length}',
      if (wiki.nextTargets.isNotEmpty) '下轮目标 ${wiki.nextTargets.length}',
    ];
    if (parts.isEmpty) {
      return '本轮没有写入新的长期 Wiki 条目。';
    }
    return '已写入个人 Wiki：${parts.join('，')}。可在个人 Wiki 的今日计划中标记有用或不再显示。';
  }

  InterviewCompiledWiki? _localCompiledWiki({
    required InterviewPracticeSession session,
    required InterviewReview review,
    required List<InterviewPersonalWikiExpression> masteredExpressions,
  }) {
    final DateTime now = DateTime.now();
    final List<InterviewCompiledWikiItem> facts = session.turns
        .where((InterviewTurnRecord turn) => turn.userText.trim().isNotEmpty)
        .take(4)
        .map(
          (InterviewTurnRecord turn) => InterviewCompiledWikiItem(
            id: _localWikiItemId('fact', turn.stage, turn.userText),
            title: stageLabels[turn.stage] ?? turn.stage,
            body: turn.userText,
            tag: turn.predictedTags.isEmpty ? '' : turn.predictedTags.first,
            evidence: turn.userText,
            updatedAt: now,
            source: 'local',
          ),
        )
        .toList(growable: false);
    final List<InterviewCompiledWikiItem> weakPatterns = review.weakTags
        .take(4)
        .map(
          (String tag) => InterviewCompiledWikiItem(
            id: _localWikiItemId('weak', tag, tag),
            title: '$tag 需要巩固',
            body: '下一轮优先创造语境，让用户复现这个标签下的地道表达。',
            tag: tag,
            evidence: 'mastery gap',
            updatedAt: now,
            source: 'local',
          ),
        )
        .toList(growable: false);
    final List<InterviewCompiledWikiItem> nextTargets = masteredExpressions
        .take(4)
        .map(
          (InterviewPersonalWikiExpression expression) =>
              InterviewCompiledWikiItem(
                id: _localWikiItemId(
                  'target',
                  expression.tag,
                  expression.sourceExpressionId,
                ),
                title: expression.text,
                body: '在相近面试问题中自然复用这句表达。',
                tag: expression.tag,
                evidence: expression.userExample,
                updatedAt: now,
                source: 'local',
              ),
        )
        .toList(growable: false);
    final String summary = facts.isEmpty
        ? ''
        : 'Learner interview profile: ${facts.map((InterviewCompiledWikiItem item) => item.body).take(2).join(' ')}';
    final InterviewCompiledWiki wiki = InterviewCompiledWiki(
      updatedAt: now,
      summary: summary,
      personalFacts: facts,
      weakPatterns: weakPatterns,
      nextTargets: nextTargets,
    );
    return wiki.isEmpty ? null : wiki;
  }

  String _localWikiItemId(String section, String tag, String text) {
    final String slug = '$tag $text'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (slug.isEmpty) {
      return '${section}_${DateTime.now().microsecondsSinceEpoch}';
    }
    return '${section}_${slug.length > 48 ? slug.substring(0, 48) : slug}';
  }

  Future<PronunciationScore?> _scoreVoice(String audioPath, String text) async {
    try {
      return await AppSessionScope.of(
        context,
      ).scorePronunciation(audioPath: audioPath, expectedText: text);
    } catch (_) {
      return null;
    }
  }

  Future<_GrammarScoreResult?> _scoreGrammarForVoiceAnswer({
    required String userText,
    InterviewExpression? targetExpression,
    InterviewChatMessage? questionMessage,
  }) async {
    try {
      final Map<String, dynamic> data = await ApiClient.scoreGrammar(
        text: userText,
        targetText: targetExpression?.text,
        questionText: questionMessage?.text,
      );
      final int? score = (data['score'] as num?)?.toInt();
      if (score == null) {
        return null;
      }
      return _GrammarScoreResult(
        score: score,
        issues: (data['issues'] as List? ?? const <dynamic>[])
            .map((dynamic item) => item.toString().trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
        correction: (data['correction'] as String? ?? '').trim(),
        provider: (data['provider'] as String? ?? '').trim(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _scoreVoiceAnswerInBackground({
    required String audioPath,
    required String userText,
    required int userMessageIndex,
    required InterviewExpression? answerTargetExpression,
    required InterviewChatMessage? answeredQuestionMessage,
    required Stopwatch pipelineWatch,
  }) async {
    if (!mounted) {
      return;
    }
    _logVoiceLatency('score:start', pipelineWatch);
    final Future<PronunciationScore?> pronunciationFuture = _scoreVoice(
      audioPath,
      userText,
    );
    final Future<_GrammarScoreResult?> grammarFuture =
        _scoreGrammarForVoiceAnswer(
          userText: userText,
          targetExpression: answerTargetExpression,
          questionMessage: answeredQuestionMessage,
        );
    void applyVoiceScoreUpdate({
      PronunciationScore? pronunciation,
      _GrammarScoreResult? grammar,
    }) {
      final int? grammarScore = grammar?.score;
      PronunciationScore? score = pronunciation;
      if (score != null && score.grammar == null && grammarScore != null) {
        score = score.copyWith(grammar: grammarScore);
      }
      if (!mounted ||
          (score == null && grammarScore == null) ||
          userMessageIndex >= _messages.length) {
        return;
      }
      final InterviewChatMessage currentMessage = _messages[userMessageIndex];
      if (currentMessage.role != 'user' ||
          currentMessage.text.trim() != userText.trim() ||
          currentMessage.voiceAudioPath.trim() != audioPath.trim()) {
        _logVoiceLatency('score:stale_skip', pipelineWatch);
        return;
      }
      setState(() {
        if (score != null) {
          _lastPronunciationScore = score;
        }
        _updateTurnVoiceScores(
          stage: currentMessage.stage,
          userText: userText,
          pronunciationScore: score?.overall,
          grammarScore: score?.grammar ?? grammarScore,
        );
        _messages[userMessageIndex] = _copyMessageWithVoiceScores(
          _messages[userMessageIndex],
          pronunciationScore: score?.overall,
          grammarScore: score?.grammar ?? grammarScore,
          pronunciationSource: score?.source,
          pronunciationAccuracy: score?.accuracy,
          pronunciationFluency: score?.fluency,
          pronunciationCompleteness: score?.completeness,
          grammarIssues: grammar?.issues,
          grammarCorrection: grammar?.correction,
          grammarProvider: grammar?.provider,
        );
      });
      _logVoiceLatency('score:rendered', pipelineWatch);
      unawaited(_saveActiveSession());
    }

    unawaited(
      pronunciationFuture
          .then((PronunciationScore? score) {
            _logVoiceLatency('pronunciation:ready', pipelineWatch);
            applyVoiceScoreUpdate(pronunciation: score);
          })
          .catchError((Object error) {
            debugPrint('[InterviewLatency] pronunciation skipped: $error');
          }),
    );
    unawaited(
      grammarFuture
          .then((_GrammarScoreResult? grammarResult) {
            _logVoiceLatency('grammar:ready', pipelineWatch);
            applyVoiceScoreUpdate(grammar: grammarResult);
          })
          .catchError((Object error) {
            debugPrint('[InterviewLatency] grammar skipped: $error');
          }),
    );
  }

  void _logVoiceLatency(String marker, Stopwatch watch) {
    debugPrint(
      '[InterviewLatency] $marker elapsed=${watch.elapsedMilliseconds}ms',
    );
  }

  String _localAnswerDiagnosisCoachMessage({
    required String userText,
    required InterviewExpression targetExpression,
    required InterviewExpressionMasteryResult masteryResult,
    required int attemptNumber,
    PronunciationScore? pronunciationScore,
    int? grammarScore,
    List<String> grammarIssues = const <String>[],
    String grammarCorrection = '',
  }) {
    final String preview = _shortAnswerPreview(userText);
    final String issue = _localAnswerIssue(
      userText: userText,
      masteryResult: masteryResult,
      pronunciationScore: pronunciationScore,
      grammarScore: grammarScore,
      grammarIssues: grammarIssues,
    );
    if (attemptNumber <= 1) {
      final String microFix = _localMicroFix(
        targetExpression: targetExpression,
        masteryResult: masteryResult,
        grammarCorrection: grammarCorrection,
      );
      return '我听到的是：“$preview”。\n$issue\n这次只补一小步：$microFix';
    }
    if (attemptNumber == 2) {
      final String starter = _localTargetStarter(targetExpression.text);
      if (starter.isNotEmpty) {
        return '这轮我们加一个句架。\n先从 “$starter” 开头，后面接你的真实信息。\n不用追求长，先说顺。';
      }
      return '这轮我们加一个句架。\n先说你的身份或动作，再补一个具体结果。\n不用追求长，先说顺。';
    }
    final String model = _localModelSentence(targetExpression.text);
    if (model.isNotEmpty) {
      return '我先给一个可模仿版本：\n“$model”\n先把这个节奏说顺，下一轮再换成你的真实经历。';
    }
    return '我先帮你收窄任务：先回答“我做了什么”，再补“结果是什么”。\n按这个顺序接着说。';
  }

  String _shortAnswerPreview(String value) {
    final String normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 70) {
      return normalized;
    }
    return '${normalized.substring(0, 67).trim()}...';
  }

  String _localAnswerIssue({
    required String userText,
    required InterviewExpressionMasteryResult masteryResult,
    PronunciationScore? pronunciationScore,
    int? grammarScore,
    List<String> grammarIssues = const <String>[],
  }) {
    final int wordCount = tokenizeInterviewWords(userText).length;
    if (wordCount <= 4) {
      return '主要问题是信息太少，我还听不到完整回答。';
    }
    if ((pronunciationScore?.overall ?? 100) < 72 ||
        (pronunciationScore?.accuracy ?? 100) < 70) {
      return '主要问题是发音清晰度，意思可能有，但关键词不够稳。';
    }
    if ((pronunciationScore?.completeness ?? 100) < 70) {
      return '主要问题是句子没有说完整，后半句需要补出来。';
    }
    if ((grammarScore ?? 100) < 75 || grammarIssues.isNotEmpty) {
      return '主要问题是句子结构影响了表达，但方向可以保留。';
    }
    if (masteryResult.missingCoreMoves.isNotEmpty) {
      return '主要问题是目标动作还缺一块：${_localMissingMoveLabel(masteryResult.missingCoreMoves)}。';
    }
    if (masteryResult.nearMiss) {
      return '方向接近了，但还没有把这句表达的核心说完整。';
    }
    return '这次回答没有对准当前问题，我们先把核心意思说清楚。';
  }

  String _localMicroFix({
    required InterviewExpression targetExpression,
    required InterviewExpressionMasteryResult masteryResult,
    String grammarCorrection = '',
  }) {
    if (grammarCorrection.trim().isNotEmpty) {
      return '先用更顺的结构：“${_shortAnswerPreview(grammarCorrection)}”';
    }
    if (masteryResult.missingCoreMoves.isNotEmpty) {
      final String phrase = _localTargetPhraseForMissingMove(
        targetExpression.text,
        masteryResult.missingCoreMoves,
      );
      if (phrase.isNotEmpty) {
        return '补上${_localMissingMoveLabel(masteryResult.missingCoreMoves)}：“$phrase”';
      }
      return '补上${_localMissingMoveLabel(masteryResult.missingCoreMoves)}';
    }
    final String phrase = _localTargetMicroPhrase(targetExpression.text);
    if (phrase.isNotEmpty) {
      return '补上这一小块：“$phrase”';
    }
    return '先说一个具体动作，再补一个结果';
  }

  String _localMissingMoveLabel(List<String> moves) {
    final List<String> labels = moves
        .take(2)
        .map(
          (String move) => switch (move) {
            'gratitude' => '感谢',
            'positive interest' => '积极态度',
            'current role' => '当前角色',
            'location' => '地点信息',
            'experience' => '经验背景',
            'project or achievement' => '项目或成果',
            'problem solving' => '解决动作',
            'strength' => '优势',
            'pressure handling' => '抗压处理方式',
            'growth motivation' => '成长动机',
            'career plan' => '职业规划',
            'candidate question' => '反问点',
            _ => move,
          },
        )
        .where((String item) => item.trim().isNotEmpty)
        .toList(growable: false);
    return labels.isEmpty ? '核心信息' : labels.join('和');
  }

  String _localTargetStarter(String targetText) {
    final String clean = _localModelSentence(targetText);
    final List<String> words = tokenizeInterviewWords(clean);
    if (words.isEmpty) {
      return '';
    }
    return words.take(math.min(6, words.length)).join(' ');
  }

  String _localTargetMicroPhrase(String targetText) {
    final String clean = _localModelSentence(targetText);
    if (clean.isEmpty) {
      return '';
    }
    final List<String> chunks = clean
        .split(RegExp(r'[,.;:]|\s+(?:and|but|so)\s+'))
        .map((String item) => item.trim())
        .where((String item) => tokenizeInterviewWords(item).length >= 3)
        .toList(growable: false);
    final String phrase = chunks.isEmpty ? clean : chunks.first;
    final List<String> words = tokenizeInterviewWords(phrase);
    if (words.length <= 7) {
      return phrase;
    }
    return '${words.take(7).join(' ')}...';
  }

  String _localTargetPhraseForMissingMove(
    String targetText,
    List<String> moves,
  ) {
    final String clean = _localModelSentence(targetText);
    if (clean.isEmpty || moves.isEmpty) {
      return '';
    }
    final List<String> chunks = clean
        .split(RegExp(r'[.!?]+\s+|[,;:]|\s+(?:and|but|so)\s+'))
        .map((String item) => item.trim().replaceAll(RegExp(r'[.!?]+$'), ''))
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    final Map<String, List<String>> hints = <String, List<String>>{
      'gratitude': <String>['thank', 'appreciate'],
      'positive interest': <String>[
        'excited',
        'happy',
        'glad',
        'looking forward',
        'thrilled',
        'interested',
      ],
      'current role': <String>['currently', 'working as', 'role'],
      'experience': <String>['experience', 'years', 'background'],
      'project or achievement': <String>[
        'project',
        'achievement',
        'finish',
        'delivered',
        'launched',
      ],
      'growth motivation': <String>['learn', 'grow', 'develop'],
      'career plan': <String>['hope', 'five years', 'leader'],
      'candidate question': <String>['could you', 'what', 'next steps'],
    };
    for (final String move in moves) {
      final List<String> keywords = hints[move] ?? const <String>[];
      for (final String chunk in chunks) {
        final String lower = chunk.toLowerCase();
        if (keywords.any(lower.contains)) {
          return chunk;
        }
      }
    }
    if (chunks.length > 1) {
      return chunks[1];
    }
    return chunks.first;
  }

  String _localModelSentence(String targetText) {
    return targetText
        .replaceAllMapped(
          RegExp(r'\[[^\]]+\]'),
          (Match match) => 'your real example',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<Map<String, InterviewExpressionMasteryResult>>
  _masteryOverridesForAnswer({
    required InterviewPracticeEngine engine,
    required InterviewPracticeSession session,
    required String userText,
  }) async {
    final InterviewChatMessage? questionMessage = _latestInterviewQuestion();
    final String question =
        questionMessage?.text ??
        questionForStage(
          session.currentStage,
          simplified: session.simplifiedMode,
        );
    final List<InterviewExpression> targets =
        _uniqueExpressions(<InterviewExpression>[
          ?session.pendingReuseTarget,
          ?session.stageExpressionTargets[session.currentStage],
        ]);
    final Map<String, InterviewExpressionMasteryResult> overrides =
        <String, InterviewExpressionMasteryResult>{};
    for (final InterviewExpression target in targets) {
      final InterviewExpressionMasteryResult localResult = engine
          .evaluateExpressionMastery(
            expression: target,
            userText: userText,
            question: question,
          );
      if (!localResult.lowConfidence) {
        continue;
      }
      final InterviewExpressionMasteryResult? llmResult = await _llmScheduler
          .judgeExpressionMastery(
            session: session,
            targetExpression: target,
            question: question,
            userText: userText,
            localResult: localResult,
            node: _sceneGraph?.nodeById(target.id),
          );
      if (llmResult != null) {
        overrides[target.id] = llmResult;
      }
    }
    return overrides;
  }

  Future<_SpeakingCoachTurnResult?> _requestSpeakingCoachTurn({
    required InterviewPracticeEngine engine,
    required InterviewPracticeSession session,
    required String userText,
    required String answeredStage,
    InterviewExpression? targetExpression,
    InterviewChatMessage? questionMessage,
  }) async {
    final Map<String, dynamic> payload = _speakingCoachPayload(
      engine: engine,
      session: session,
      userText: userText,
      answeredStage: answeredStage,
      targetExpression: targetExpression,
      questionMessage: questionMessage,
    );
    try {
      final Map<String, dynamic> data = await ApiClient.interviewCoachTurn(
        payload,
      );
      debugPrint(
        '[SpeakingCoachSkill] result '
        'intent=${data['userIntent']} '
        'mastery=${data['mastery']} '
        'completed=${data['analysis'] is Map ? data['analysis']['targetExpressionCompleted'] : data['targetExpressionCompleted']} '
        'action=${data['nextAction']} '
        'move=${data['plan'] is Map ? data['plan']['selectedMoveId'] : data['coachMove']} '
        'debug=${data['debug']}',
      );
      return _SpeakingCoachTurnResult.fromJson(data);
    } catch (error) {
      debugPrint('[SpeakingCoachSkill] skipped: $error');
      return null;
    }
  }

  Map<String, dynamic> _speakingCoachPayload({
    required InterviewPracticeEngine engine,
    required InterviewPracticeSession session,
    required String userText,
    required String answeredStage,
    InterviewExpression? targetExpression,
    InterviewChatMessage? questionMessage,
  }) {
    final InterviewSceneGraph? sceneGraph = _sceneGraph;
    final InterviewExpressionNode? node = targetExpression == null
        ? null
        : sceneGraph?.nodeById(targetExpression.id);
    final String question =
        questionMessage?.text ??
        questionForStage(answeredStage, simplified: session.simplifiedMode);
    final InterviewExpressionMasteryResult? localMastery =
        targetExpression == null
        ? null
        : engine.evaluateExpressionMastery(
            expression: targetExpression,
            userText: userText,
            question: question,
          );
    final InterviewTurnAnalysis turnAnalysis = engine.analyzeTurn(
      stage: answeredStage,
      userText: userText,
    );
    final int attemptCount = (session.stageAttempts[answeredStage] ?? 0) + 1;
    final bool targetCompleted =
        targetExpression != null &&
        (session.completedTargetExpressionIds.contains(targetExpression.id) ||
            localMastery?.mastered == true);
    final String teachingStage = targetCompleted
        ? TeachingStage.completed
        : session.stageTeachingStages[answeredStage] ??
              _teachingStageForLessonState(
                attemptCount: attemptCount,
                localMastery: localMastery,
                stuck:
                    _hasStuckMarker(userText) ||
                    turnAnalysis.coverageStatus == 'stuck',
              );
    final InterviewUserGrowthWiki growthWiki = _wikiStore.loadUserGrowthWiki();
    final DateTime now = DateTime.now();
    final List<InterviewPersonalWikiExpression> dueExpressions = _wikiStore
        .loadMasteredExpressions()
        .where(
          (InterviewPersonalWikiExpression item) =>
              item.sourceSceneId == session.publicSceneId &&
              !item.nextReviewAt.isAfter(now),
        )
        .take(5)
        .toList(growable: false);
    return <String, dynamic>{
      'userText': userText,
      'lessonState': <String, dynamic>{
        'sceneId': sceneGraph?.id ?? session.publicSceneId,
        'nodeId': answeredStage,
        'targetLevel': session.targetLevel,
        'teachingStage': teachingStage,
        'attemptCount': attemptCount,
        'masteryStatus': _masteryStatusForLessonState(localMastery),
        'masteryScore': localMastery?.confidence ?? 0,
        'targetExpressionCompleted': targetCompleted,
        'lastCoachMoveId': session.stageLastCoachMoveIds[answeredStage] ?? '',
        'lastNextAction': session.stageLastNextActions[answeredStage] ?? '',
        'needsFormalQuestion': true,
      },
      'current': <String, dynamic>{
        'sceneId': sceneGraph?.id ?? session.publicSceneId,
        'sceneTitle': sceneGraph?.titleCn ?? session.publicSceneId,
        'targetLevel': session.targetLevel,
        'stage': answeredStage,
        'stageLabel':
            node?.stageLabel ?? stageLabels[answeredStage] ?? answeredStage,
        'question': question,
        'recentMessages': _messages
            .take(_messages.length)
            .toList()
            .reversed
            .take(8)
            .toList()
            .reversed
            .map(
              (InterviewChatMessage message) => <String, dynamic>{
                'role': message.role,
                'text': message.text,
              },
            )
            .toList(growable: false),
      },
      'targetExpression': <String, dynamic>{
        'id': targetExpression?.id ?? '',
        'text': targetExpression?.text ?? '',
        'tag': targetExpression?.tag ?? node?.tag ?? '',
        'useCase': targetExpression?.useCase ?? node?.usage ?? '',
        'section': targetExpression?.section ?? node?.stageLabel ?? '',
        'level': targetExpression?.level ?? node?.targetLevel ?? '',
        'nodeIntent': node?.intent ?? '',
        'naturalTiming': node?.naturalTiming ?? '',
        'expectedVariants':
            node?.expectedVariants
                .map((InterviewExpectedVariant item) => item.text)
                .where((String value) => value.trim().isNotEmpty)
                .toList(growable: false) ??
            const <String>[],
      },
      'coachMoves':
          node?.coachMoves.toRuntimeJson(
            targetText: node.targetText,
            capability: node.capability,
            communicativeIntent: node.communicativeIntent,
            narrative: node.narrative,
            teachingVisibility: node.teachingVisibility,
            correctionPolicy: node.correctionPolicy,
            delayedFeedback: node.delayedFeedback,
            allowedMoves: node.allowedMoves,
            nodeInputs: node.nodeInputs,
            adaptivePolicy: node.adaptivePolicy,
            expectedVariants: node.expectedVariants,
            fallbackRubric: node.coachRubric,
            speechFocus: node.speechFocus,
            contextVariants: node.contextVariants,
          ) ??
          const <String, dynamic>{},
      'capability': node?.capability.toJson() ?? const <String, dynamic>{},
      'communicativeIntent':
          node?.communicativeIntent ?? const <String, dynamic>{},
      'narrative': node?.narrative ?? const <String, dynamic>{},
      'teachingVisibility':
          node?.teachingVisibility ?? const <String, dynamic>{},
      'correctionPolicy': node?.correctionPolicy ?? const <String, dynamic>{},
      'delayedFeedback': node?.delayedFeedback ?? const <String, dynamic>{},
      'allowedMoves': node?.allowedMoves ?? const <String>[],
      'adaptivePolicy': node?.adaptivePolicy ?? const <String, String>{},
      'userWeaknessProfile': _userWeaknessProfileForCoach(growthWiki),
      'capabilityMastery': <String, dynamic>{
        if (node?.capability.primaryIntent.isNotEmpty == true)
          node!.capability.primaryIntent: <String, dynamic>{
            'mastery': localMastery?.confidence ?? 0,
            'relatedNodes': <String>[answeredStage],
          },
      },
      'localSignals': <String, dynamic>{
        'wordCount': tokenizeInterviewWords(userText).length,
        'chineseCharCount': chineseCharCount(userText),
        'targetTokenCoverage': _targetTokenCoverage(
          userText: userText,
          targetText: targetExpression?.text ?? node?.targetText ?? '',
        ),
        'looksLikeQuestion': _looksLikeQuestionForCoach(userText),
        'looksLikeEcho': _looksLikeEchoForCoach(userText, question),
        'stuckMarker': _hasStuckMarker(userText),
        'localMastery': localMastery?.status.name ?? 'not_applicable',
        'localMasteryReason': localMastery?.reason ?? '',
        'correctionHits': turnAnalysis.correctionHits
            .map((InterviewCorrectionHit hit) => hit.id)
            .toList(growable: false),
        'coverageStatus': turnAnalysis.coverageStatus,
        'coverageCredit': turnAnalysis.coverageCredit,
        'predictedTag': turnAnalysis.predictedTag,
        'confidence': turnAnalysis.confidence,
        'languageMixRatio': turnAnalysis.languageMixRatio,
      },
      'voiceScores': <String, dynamic>{
        if (_lastPronunciationScore != null)
          'pronunciation': _lastPronunciationScore!.overall,
        if (_lastPronunciationScore?.accuracy != null)
          'accuracy': _lastPronunciationScore!.accuracy,
        if (_lastPronunciationScore?.fluency != null)
          'fluency': _lastPronunciationScore!.fluency,
        if (_lastPronunciationScore?.completeness != null)
          'completeness': _lastPronunciationScore!.completeness,
        if (_lastPronunciationScore?.grammar != null)
          'grammar': _lastPronunciationScore!.grammar,
      },
      'personalWiki': <String, dynamic>{
        'weakExpressions': growthWiki.weakExpressions
            .where(
              (InterviewWeakExpressionState item) =>
                  item.sourceSceneId == session.publicSceneId,
            )
            .map(
              (InterviewWeakExpressionState item) =>
                  item.lastUserExample.isNotEmpty
                  ? item.lastUserExample
                  : item.targetText,
            )
            .where((String value) => value.trim().isNotEmpty)
            .take(5)
            .toList(growable: false),
        'errorPatterns': growthWiki.errorPatterns
            .where(
              (InterviewUserErrorPattern item) =>
                  item.sourceSceneId == session.publicSceneId,
            )
            .map(
              (InterviewUserErrorPattern item) =>
                  item.title.isNotEmpty ? item.title : item.detail,
            )
            .where((String value) => value.trim().isNotEmpty)
            .take(5)
            .toList(growable: false),
        'personalFacts': growthWiki.personalFacts
            .map(
              (InterviewCompiledWikiItem item) =>
                  item.body.isNotEmpty ? item.body : item.title,
            )
            .where((String value) => value.trim().isNotEmpty)
            .take(5)
            .toList(growable: false),
        'dueReviewExpressions': dueExpressions
            .map((InterviewPersonalWikiExpression item) => item.text)
            .where((String value) => value.trim().isNotEmpty)
            .toList(growable: false),
        'pronunciationNotes':
            growthWiki.pronunciationProfile?.notes
                .where((String value) => value.trim().isNotEmpty)
                .take(4)
                .toList(growable: false) ??
            const <String>[],
        'grammarNotes':
            <String>[
                  ...?growthWiki.grammarProfile?.recurringIssues,
                  ...?growthWiki.grammarProfile?.notes,
                ]
                .where((String value) => value.trim().isNotEmpty)
                .take(4)
                .toList(growable: false),
        'levelHints': <String>[
          'targetLevel=${session.targetLevel}',
          if (growthWiki.weakExpressions.isNotEmpty)
            'weakExpressions=${growthWiki.weakExpressions.length}',
          if (growthWiki.errorPatterns.isNotEmpty)
            'errorPatterns=${growthWiki.errorPatterns.length}',
        ],
      },
    };
  }

  Map<String, dynamic> _userWeaknessProfileForCoach(
    InterviewUserGrowthWiki growthWiki,
  ) {
    final List<String> grammar = <String>[
      ...?growthWiki.grammarProfile?.recurringIssues,
      ...?growthWiki.grammarProfile?.notes,
    ].where((String value) => value.trim().isNotEmpty).take(6).toList();

    final List<String> speaking = <String>[
      if (growthWiki.weakExpressions.isNotEmpty) 'short_answers',
      ...?growthWiki.pronunciationProfile?.notes,
    ].where((String value) => value.trim().isNotEmpty).take(6).toList();

    final List<String> pragmatics = growthWiki.errorPatterns
        .map(
          (InterviewUserErrorPattern item) =>
              item.title.isNotEmpty ? item.title : item.detail,
        )
        .where((String value) => value.trim().isNotEmpty)
        .take(6)
        .toList(growable: false);

    return <String, dynamic>{
      'grammar': grammar,
      'speaking': speaking,
      'pragmatics': pragmatics,
    };
  }

  String _teachingStageForLessonState({
    required int attemptCount,
    required InterviewExpressionMasteryResult? localMastery,
    required bool stuck,
  }) {
    if (localMastery?.mastered == true) {
      return TeachingStage.completed;
    }
    if (stuck) {
      return TeachingStage.scaffold;
    }
    if (localMastery?.nearMiss == true) {
      return attemptCount <= 1 ? TeachingStage.recast : TeachingStage.retry;
    }
    if (attemptCount <= 1) {
      return TeachingStage.firstAttempt;
    }
    if (attemptCount >= 3) {
      return TeachingStage.microDrill;
    }
    return TeachingStage.scaffold;
  }

  String _masteryStatusForLessonState(
    InterviewExpressionMasteryResult? localMastery,
  ) {
    return switch (localMastery?.status) {
      InterviewExpressionMasteryStatus.mastered => MasteryStatus.mastered,
      InterviewExpressionMasteryStatus.nearMiss => MasteryStatus.nearMiss,
      InterviewExpressionMasteryStatus.missed => MasteryStatus.missed,
      _ => MasteryStatus.unknown,
    };
  }

  void _applyCoachLessonStatePatch({
    required InterviewPracticeSession session,
    required String answeredStage,
    required _SpeakingCoachTurnResult coachTurn,
    InterviewExpression? targetExpression,
  }) {
    if (coachTurn.nextTeachingStage.isNotEmpty &&
        InterviewCoachSchema.isTeachingStage(coachTurn.nextTeachingStage)) {
      session.stageTeachingStages[answeredStage] = coachTurn.nextTeachingStage;
    }
    if (coachTurn.coachMove.isNotEmpty &&
        InterviewCoachSchema.isCoachMoveId(coachTurn.coachMove)) {
      session.stageLastCoachMoveIds[answeredStage] = coachTurn.coachMove;
    }
    if (coachTurn.nextAction.isNotEmpty &&
        InterviewCoachSchema.isNextAction(coachTurn.nextAction)) {
      session.stageLastNextActions[answeredStage] = coachTurn.nextAction;
    }
    if (coachTurn.targetExpressionCompleted && targetExpression != null) {
      session.completedTargetExpressionIds.add(targetExpression.id);
    }
  }

  Map<String, InterviewExpressionMasteryResult> _coachMasteryOverrides({
    required _SpeakingCoachTurnResult? coachTurn,
    required InterviewExpression? targetExpression,
  }) {
    if (coachTurn == null || targetExpression == null) {
      return const <String, InterviewExpressionMasteryResult>{};
    }
    final InterviewExpressionMasteryStatus? status = switch (coachTurn
        .mastery) {
      'mastered' => InterviewExpressionMasteryStatus.mastered,
      'near_miss' =>
        (coachTurn.targetExpressionCompleted ||
                    coachTurn.targetExpressionUsed) &&
                (coachTurn.nextAction == 'ask_followup' ||
                    coachTurn.nextAction == 'advance')
            ? InterviewExpressionMasteryStatus.mastered
            : InterviewExpressionMasteryStatus.nearMiss,
      'missed' => InterviewExpressionMasteryStatus.missed,
      _ =>
        coachTurn.suggestsMiss ? InterviewExpressionMasteryStatus.missed : null,
    };
    if (status == null) {
      return const <String, InterviewExpressionMasteryResult>{};
    }
    return <String, InterviewExpressionMasteryResult>{
      targetExpression.id: InterviewExpressionMasteryResult(
        status: status,
        confidence: coachTurn.confidence.clamp(0.58, 0.92).toDouble(),
        matchedVariant: coachTurn.targetExpressionCompleted
            ? targetExpression.text
            : '',
        missingCoreMoves: coachTurn.mainIssue.isEmpty
            ? const <String>[]
            : <String>[coachTurn.mainIssue],
        reason: 'speaking coach skill: ${coachTurn.nextAction}',
      ),
    };
  }

  bool _looksLikeQuestionForCoach(String text) {
    final String normalized = normalizeInterviewText(text).toLowerCase();
    if (normalized.endsWith('?')) {
      return true;
    }
    return RegExp(
      r'^(what|which|where|when|why|how|do|does|did|can|could|would|will|are|is|tell|give)\b',
    ).hasMatch(normalized);
  }

  bool _looksLikeEchoForCoach(String text, String question) {
    if (_looksLikeCurrentTargetAttempt(text)) {
      return false;
    }
    final Set<String> answerTokens = tokenizeInterviewWords(
      text,
    ).where((String token) => token.length > 3).toSet();
    final Set<String> questionTokens = tokenizeInterviewWords(
      question,
    ).where((String token) => token.length > 3).toSet();
    if (answerTokens.length < 4 || questionTokens.length < 4) {
      return false;
    }
    final double overlap =
        answerTokens.intersection(questionTokens).length / answerTokens.length;
    return overlap >= 0.72;
  }

  bool _hasStuckMarker(String text) {
    final String normalized = normalizeInterviewText(text).toLowerCase();
    const List<String> markers = <String>[
      '不会',
      '不知道',
      '怎么说',
      '卡住了',
      'i don\'t know',
      'not sure',
      'how to say',
      'stuck',
      '...',
    ];
    return normalized.isEmpty || markers.any(normalized.contains);
  }

  double _targetTokenCoverage({
    required String userText,
    required String targetText,
  }) {
    final Set<String> targetTokens = tokenizeInterviewWords(
      targetText,
    ).where((String token) => token.length > 3).toSet();
    if (targetTokens.isEmpty) {
      return 0;
    }
    final Set<String> answerTokens = tokenizeInterviewWords(
      userText,
    ).where((String token) => token.length > 3).toSet();
    if (answerTokens.isEmpty) {
      return 0;
    }
    return targetTokens.intersection(answerTokens).length / targetTokens.length;
  }

  void _restoreSessionStageForCoach(
    InterviewPracticeSession session,
    String answeredStage,
  ) {
    final int index = session.plannedStages.indexOf(answeredStage);
    if (index >= 0) {
      session.stageIndex = index;
    }
  }

  void _removeRejectedMastery(
    InterviewPracticeSession session,
    InterviewExpression? targetExpression,
  ) {
    final String id = targetExpression?.id ?? '';
    if (id.isEmpty) {
      return;
    }
    session.masteredExpressionIds.remove(id);
    session.roundMasteredExpressionIds.remove(id);
  }

  InterviewChatMessage _copyMessageWithVoiceScores(
    InterviewChatMessage message, {
    int? pronunciationScore,
    int? grammarScore,
    String? pronunciationSource,
    int? pronunciationAccuracy,
    int? pronunciationFluency,
    int? pronunciationCompleteness,
    List<String>? grammarIssues,
    String? grammarCorrection,
    String? grammarProvider,
  }) {
    return InterviewChatMessage(
      role: message.role,
      text: message.text,
      createdAt: message.createdAt,
      stage: message.stage,
      status: message.status,
      tag: message.tag,
      isHint: message.isHint,
      hintLevel: message.hintLevel,
      isAlignment: message.isAlignment,
      isMastered: message.isMastered,
      targetExpression: message.targetExpression,
      questionPlanAction: message.questionPlanAction,
      mustAskAbout: message.mustAskAbout,
      voiceAudioPath: message.voiceAudioPath,
      pronunciationScore: pronunciationScore ?? message.pronunciationScore,
      grammarScore: grammarScore ?? message.grammarScore,
      pronunciationSource: pronunciationSource ?? message.pronunciationSource,
      pronunciationAccuracy:
          pronunciationAccuracy ?? message.pronunciationAccuracy,
      pronunciationFluency:
          pronunciationFluency ?? message.pronunciationFluency,
      pronunciationCompleteness:
          pronunciationCompleteness ?? message.pronunciationCompleteness,
      grammarIssues: grammarIssues ?? message.grammarIssues,
      grammarCorrection: grammarCorrection ?? message.grammarCorrection,
      grammarProvider: grammarProvider ?? message.grammarProvider,
      expressionSuggestionText: message.expressionSuggestionText,
      expressionSuggestionTag: message.expressionSuggestionTag,
    );
  }

  void _updateTurnVoiceScores({
    required String stage,
    required String userText,
    int? pronunciationScore,
    int? grammarScore,
  }) {
    final InterviewPracticeSession? session = _session;
    if (session == null ||
        (pronunciationScore == null && grammarScore == null)) {
      return;
    }
    final String normalizedUserText = normalizeInterviewText(userText);
    for (int index = session.turns.length - 1; index >= 0; index -= 1) {
      final InterviewTurnRecord turn = session.turns[index];
      if (turn.stage != stage) {
        continue;
      }
      if (normalizeInterviewText(turn.userText) != normalizedUserText) {
        continue;
      }
      session.turns[index] = turn.copyWith(
        pronunciationScore: pronunciationScore,
        grammarScore: grammarScore,
      );
      return;
    }
  }

  InterviewChatMessage _copyMessageWithMasteryFeedback(
    InterviewChatMessage message, {
    InterviewExpression? targetExpression,
  }) {
    return InterviewChatMessage(
      role: message.role,
      text: message.text,
      createdAt: message.createdAt,
      stage: message.stage,
      status: message.status,
      tag: message.tag,
      isHint: message.isHint,
      hintLevel: message.hintLevel,
      isAlignment: message.isAlignment,
      isMastered: true,
      targetExpression: targetExpression ?? message.targetExpression,
      questionPlanAction: message.questionPlanAction,
      mustAskAbout: message.mustAskAbout,
      voiceAudioPath: message.voiceAudioPath,
      pronunciationScore: message.pronunciationScore,
      grammarScore: message.grammarScore,
      pronunciationSource: message.pronunciationSource,
      pronunciationAccuracy: message.pronunciationAccuracy,
      pronunciationFluency: message.pronunciationFluency,
      pronunciationCompleteness: message.pronunciationCompleteness,
      grammarIssues: message.grammarIssues,
      grammarCorrection: message.grammarCorrection,
      grammarProvider: message.grammarProvider,
      expressionSuggestionText: '',
      expressionSuggestionTag: '',
    );
  }

  InterviewChatMessage _copyMessageWithExpressionSuggestion(
    InterviewChatMessage message, {
    required String suggestionText,
    required String suggestionTag,
  }) {
    return InterviewChatMessage(
      role: message.role,
      text: message.text,
      createdAt: message.createdAt,
      stage: message.stage,
      status: message.status,
      tag: message.tag,
      isHint: message.isHint,
      hintLevel: message.hintLevel,
      isAlignment: message.isAlignment,
      isMastered: message.isMastered,
      targetExpression: message.targetExpression,
      questionPlanAction: message.questionPlanAction,
      mustAskAbout: message.mustAskAbout,
      voiceAudioPath: message.voiceAudioPath,
      pronunciationScore: message.pronunciationScore,
      grammarScore: message.grammarScore,
      pronunciationSource: message.pronunciationSource,
      pronunciationAccuracy: message.pronunciationAccuracy,
      pronunciationFluency: message.pronunciationFluency,
      pronunciationCompleteness: message.pronunciationCompleteness,
      grammarIssues: message.grammarIssues,
      grammarCorrection: message.grammarCorrection,
      grammarProvider: message.grammarProvider,
      expressionSuggestionText: suggestionText,
      expressionSuggestionTag: suggestionTag,
    );
  }

  String _coachGeneratedVoiceFeedbackText(
    _SpeakingCoachTurnResult? coachTurn, {
    required bool allowCoachTextFallback,
    required String fallbackCoachText,
  }) {
    final String structuredFeedback = coachTurn?.voiceFeedbackText.trim() ?? '';
    if (_isUsableInlineFeedback(structuredFeedback)) {
      return structuredFeedback;
    }
    if (!allowCoachTextFallback) {
      return '';
    }
    return _compactLocalInlineFeedback(fallbackCoachText);
  }

  bool _isUsableInlineFeedback(String value) {
    final String text = value.trim();
    if (text.isEmpty || chineseCharCount(text) < 2) {
      return false;
    }
    final String firstLine = text
        .split(RegExp(r'[\r\n]+'))
        .map((String line) => line.trim())
        .firstWhere((String line) => line.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) {
      return false;
    }
    final String normalized = firstLine.toLowerCase();
    const List<String> blockedStarts = <String>[
      '我听到的是',
      '听到的是',
      '我刚才听到的是',
      '表达建议',
      '语法反馈',
      '发音反馈',
      '目标',
      '句型桥',
      '自然度',
      '发音/流利度',
      'native upgrade',
      'try this',
    ];
    return !blockedStarts.any(normalized.startsWith);
  }

  String _compactLocalInlineFeedback(String value) {
    final String text = value.trim();
    if (text.isEmpty || chineseCharCount(text) < 2) {
      return '';
    }
    if (text.contains('录到了') || text.contains('问题本身')) {
      return '像录到了问题\n这轮先不算回答，重新按住后直接说你的回答。';
    }
    if (text.contains('跑题') || text.contains('有点偏') || text.contains('偏离')) {
      return '回答有点跑题\n回到面试官的问题，补一句和岗位、经历或动机有关的回答。';
    }
    if (text.contains('积极态度') || text.contains('感受')) {
      return "还差一个关键信息\n补一句你的感受，比如 “I'm excited to be here today.”";
    }
    if (text.contains('信息太少') ||
        text.contains('不完整') ||
        text.contains('还缺') ||
        text.contains('缺一块')) {
      return '回答还不完整\n先补一个具体信息，再继续回答。';
    }
    if (text.contains('先从') || text.contains('开头') || text.contains('开口')) {
      return '先给你一个开口\n选一个短句开头，再接你的真实信息。';
    }
    if (text.contains('可模仿版本') || text.contains('节奏说顺')) {
      final String model = _firstQuotedFeedbackSegment(text);
      if (model.isNotEmpty) {
        return '先照这个节奏说\n可以先模仿：$model\n下一轮再换成你的真实经历。';
      }
      return '先照这个节奏说\n先把这句说顺，下一轮再换成你的真实经历。';
    }
    if (text.contains('收窄任务') || text.contains('按这个顺序')) {
      return '先收窄回答\n先回答“我做了什么”，再补一个具体结果。';
    }
    if (text.contains('发音') || text.contains('重音')) {
      return '关键词重音再稳一点\n先把关键词慢一点说清楚，再继续回答。';
    }
    if (text.contains('语法') || text.contains('句子结构')) {
      return '句子结构再稳一点\n先说清楚主语和动作，细节可以后面补。';
    }
    return '';
  }

  String _firstQuotedFeedbackSegment(String value) {
    final RegExpMatch? match = RegExp(r'[“"]([^”"]+)[”"]').firstMatch(value);
    return match?.group(1)?.trim() ?? '';
  }

  Future<void> _toggleMessageTranslation(
    int index,
    InterviewChatMessage message,
  ) async {
    if (message.text.trim().isEmpty ||
        _translatingMessageIndexes.contains(index)) {
      return;
    }
    final String? existing = _messageTranslations[index];
    if (existing != null && existing.isNotEmpty) {
      setState(() {
        if (_translatedMessageIndexes.contains(index)) {
          _translatedMessageIndexes.remove(index);
        } else {
          _translatedMessageIndexes.add(index);
        }
      });
      return;
    }
    setState(() {
      _errorText = null;
      _translatingMessageIndexes.add(index);
    });
    try {
      final String translation = await ApiClient.translateTextToChinese(
        message.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messageTranslations[index] = translation;
        _translatedMessageIndexes.add(index);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorText = '翻译失败：$error');
    } finally {
      if (mounted) {
        setState(() => _translatingMessageIndexes.remove(index));
      }
    }
  }

  Future<void> _playAssistantMessage(InterviewChatMessage message) async {
    final String text = message.text.trim();
    if (text.isEmpty) {
      return;
    }
    try {
      await AudioServiceScope.of(context).playTtsProgressiveBackend(
        text,
        maxAttempts: 1,
        requestTimeout: const Duration(seconds: 15),
        chunkWaitTimeout: const Duration(seconds: 18),
        prefetchAllChunks: false,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = '播放失败：$error');
      }
    }
  }

  Future<void> _playUserVoiceMessage(InterviewChatMessage message) async {
    final String path = message.voiceAudioPath.trim();
    if (path.isEmpty) {
      return;
    }
    final AudioService audioService = AudioServiceScope.of(context);
    try {
      final File audioFile = File(path);
      if (!await audioFile.exists()) {
        if (mounted) {
          setState(() => _errorText = '这条语音文件已失效，无法播放。');
        }
        return;
      }
      await audioService.playFile(path);
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = '语音播放失败：$error');
      }
    }
  }

  Future<void> _persistMasteredExpressions(
    List<InterviewExpression> expressions, {
    required String stage,
    required String userText,
    Map<String, InterviewExpressionMasteryResult> masteryResults =
        const <String, InterviewExpressionMasteryResult>{},
    int attemptCount = 1,
  }) async {
    for (final InterviewExpression expression in expressions) {
      try {
        final InterviewExpressionMasteryResult? masteryResult =
            masteryResults[expression.id];
        final double textMatch = bestExpressionTextMatch(userText, <String>[
          expression.text,
        ]);
        final double performanceScore = _conversationReviewPerformanceScore(
          masteryResult: masteryResult,
          textMatch: textMatch,
        );
        await _wikiStore.upsertMasteredExpression(
          expression: expression,
          stage: stage,
          userExample: userText,
          performanceScore: performanceScore,
          textMatch: textMatch,
          attemptCount: attemptCount,
        );
        await _wikiStore.markExpressionLearningMasteredLinked(
          nodeId: expression.id,
          targetLevel: expression.level,
          sourceSceneId: _session?.publicSceneId ?? widget.sceneId,
        );
      } catch (_) {}
    }
  }

  double _conversationReviewPerformanceScore({
    required InterviewExpressionMasteryResult? masteryResult,
    required double textMatch,
  }) {
    final double masteryScore = ((masteryResult?.confidence ?? textMatch) * 100)
        .clamp(0, 100)
        .toDouble();
    final double textScore = (textMatch * 100).clamp(0, 100).toDouble();
    return (masteryScore * 0.55 + textScore * 0.45).clamp(0, 100).toDouble();
  }

  Future<void> _recordSpeakingCoachWikiPatch({
    required InterviewPracticeSession session,
    required InterviewExpression targetExpression,
    required _SpeakingCoachTurnResult coachTurn,
    required String userText,
  }) async {
    final bool hasActionableDiagnosis =
        coachTurn.mainIssue.trim().isNotEmpty &&
        !coachTurn.targetExpressionCompleted &&
        coachTurn.mastery != MasteryStatus.mastered &&
        coachTurn.nextAction != 'advance';
    if (hasActionableDiagnosis) {
      await _wikiStore.recordAnswerDiagnosis(
        session: session,
        targetExpression: targetExpression,
        diagnosis: InterviewAnswerDiagnosis(
          issueType: coachTurn.nextAction,
          didWell: coachTurn.targetExpressionUsed ? '表达方向正确' : '',
          mainIssue: coachTurn.mainIssue,
          microFix: coachTurn.betterVersion,
          retryMode: coachTurn.nextAction,
          coachMessage: coachTurn.coachText,
          suggestedReply: coachTurn.betterVersion,
          confidence: coachTurn.confidence,
        ),
        userText: userText,
      );
    }

    final DateTime now = DateTime.now();
    final List<InterviewCompiledWikiItem> facts = <InterviewCompiledWikiItem>[
      if (coachTurn.personalFact != null)
        InterviewCompiledWikiItem(
          id: _localWikiItemId(
            'coach_fact',
            targetExpression.tag,
            coachTurn.personalFact!,
          ),
          title: stageLabels[session.currentStage] ?? targetExpression.tag,
          body: coachTurn.personalFact!,
          tag: targetExpression.tag,
          evidence: userText,
          updatedAt: now,
          source: 'speaking_coach_skill',
        ),
    ];
    final List<InterviewCompiledWikiItem> weakPatterns = coachTurn
        .wikiWeaknesses
        .map(
          (String weakness) => InterviewCompiledWikiItem(
            id: _localWikiItemId('coach_weak', targetExpression.tag, weakness),
            title: weakness,
            body: coachTurn.betterVersion.isEmpty
                ? coachTurn.coachText
                : coachTurn.betterVersion,
            tag: targetExpression.tag,
            evidence: userText,
            updatedAt: now,
            source: 'speaking_coach_skill',
          ),
        )
        .toList(growable: false);
    if (facts.isEmpty && weakPatterns.isEmpty) {
      return;
    }
    await _wikiStore.mergeCompiledWiki(
      InterviewCompiledWiki(
        updatedAt: now,
        personalFacts: facts,
        weakPatterns: weakPatterns,
      ),
    );
  }

  List<InterviewExpression> _expressionHintsForNextQuestion({
    required InterviewPracticeSession session,
    required InterviewLibrary library,
    required String predictedTag,
    required String questionStage,
  }) {
    if (session.roundMode == InterviewNextRoundMode.review) {
      final InterviewExpression? stageTarget =
          session.stageExpressionTargets[questionStage];
      final InterviewExpression? reuseTarget = session.pendingReuseTarget;
      return _uniqueExpressions(<InterviewExpression>[
        ?stageTarget,
        if (reuseTarget != null && reuseTarget.id != stageTarget?.id)
          reuseTarget,
        ...library.expressionsForTag(
          predictedTag,
          targetLevel: session.targetLevel,
          limit: 12,
        ),
      ]).take(6).toList(growable: false);
    }
    final List<InterviewExpression> unmastered = library
        .expressionsForTag(
          predictedTag,
          targetLevel: session.targetLevel,
          limit: 12,
        )
        .where(
          (InterviewExpression item) =>
              !session.masteredExpressionIds.contains(item.id),
        )
        .take(4)
        .toList(growable: false);
    if (unmastered.isNotEmpty) {
      return unmastered;
    }
    return library.expressionsForTag(
      predictedTag,
      targetLevel: session.targetLevel,
    );
  }

  List<InterviewExpression> _uniqueExpressions(
    Iterable<InterviewExpression> expressions,
  ) {
    final Set<String> seen = <String>{};
    return expressions
        .where((InterviewExpression expression) {
          final String key = expression.id.isNotEmpty
              ? expression.id
              : expression.text.toLowerCase();
          if (key.isEmpty || seen.contains(key)) {
            return false;
          }
          seen.add(key);
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _startStreamingAsrCapture() async {
    await _closeStreamingAsrCapture();
    final String? token = await ApiClient.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    final VoiceChatService service = VoiceChatService();
    final Completer<String?> transcriptCompleter = Completer<String?>();
    _streamingAsrService = service;
    _streamingAsrCompleter = transcriptCompleter;
    _streamingAsrFinalText = '';
    _streamingAsrPreviewText = '';
    _streamingAsrTextSub = service.userTextStream.listen((String text) {
      final String normalized = normalizeInterviewText(text);
      if (normalized.isEmpty) {
        return;
      }
      _streamingAsrFinalText = normalized;
      if (!transcriptCompleter.isCompleted) {
        transcriptCompleter.complete(normalized);
      }
    });
    _streamingAsrPreviewSub = service.userTextPreviewStream.listen((
      String text,
    ) {
      final String normalized = normalizeInterviewText(text);
      if (normalized.isNotEmpty) {
        _streamingAsrPreviewText = normalized;
      }
    });
    _streamingAsrConnectionSub = service.connectionStream.listen((
      String state,
    ) {
      if (state == 'connected') {
        _flushStreamingAsrPendingChunks();
      }
    });
    await service.connect(
      token: token,
      transcriptionOnly: true,
      manualTurnDetection: true,
      model: 'qwen3-asr-flash-realtime',
    );
    if (service.isConnected) {
      _flushStreamingAsrPendingChunks();
    }
  }

  void _sendStreamingAsrPcmChunk(Uint8List bytes) {
    if (bytes.isEmpty) {
      return;
    }
    final VoiceChatService? service = _streamingAsrService;
    if (service != null && service.isConnected) {
      _flushStreamingAsrPendingChunks();
      service.sendAudio(bytes);
      return;
    }

    const int maxBufferedBytes = 320000;
    _streamingAsrPendingChunks.add(Uint8List.fromList(bytes));
    _streamingAsrPendingBytes += bytes.length;
    while (_streamingAsrPendingBytes > maxBufferedBytes &&
        _streamingAsrPendingChunks.isNotEmpty) {
      final Uint8List removed = _streamingAsrPendingChunks.removeAt(0);
      _streamingAsrPendingBytes -= removed.length;
    }
  }

  void _flushStreamingAsrPendingChunks() {
    final VoiceChatService? service = _streamingAsrService;
    if (service == null || !service.isConnected) {
      return;
    }
    for (final Uint8List chunk in _streamingAsrPendingChunks) {
      service.sendAudio(chunk);
    }
    _streamingAsrPendingChunks.clear();
    _streamingAsrPendingBytes = 0;
  }

  Future<String?> _finishStreamingAsrCapture() async {
    try {
      await _streamingAsrStartFuture?.timeout(
        const Duration(milliseconds: 700),
        onTimeout: () {},
      );
    } catch (_) {}

    final VoiceChatService? service = _streamingAsrService;
    if (service == null) {
      return null;
    }
    _flushStreamingAsrPendingChunks();
    if (service.isConnected) {
      service.commitTurn();
    }

    String transcript = normalizeInterviewText(_streamingAsrFinalText);
    if (transcript.isEmpty) {
      try {
        final String? completedText = await _streamingAsrCompleter?.future
            .timeout(const Duration(milliseconds: 1800));
        transcript = normalizeInterviewText(completedText ?? '');
      } catch (_) {
        transcript = normalizeInterviewText(_streamingAsrPreviewText);
      }
    }
    await _closeStreamingAsrCapture();
    return transcript.isEmpty ? null : transcript;
  }

  Future<void> _closeStreamingAsrCapture() async {
    _streamingAsrPendingChunks.clear();
    _streamingAsrPendingBytes = 0;
    _streamingAsrFinalText = '';
    _streamingAsrPreviewText = '';
    await _streamingAsrTextSub?.cancel();
    await _streamingAsrPreviewSub?.cancel();
    await _streamingAsrConnectionSub?.cancel();
    _streamingAsrTextSub = null;
    _streamingAsrPreviewSub = null;
    _streamingAsrConnectionSub = null;
    final VoiceChatService? service = _streamingAsrService;
    _streamingAsrService = null;
    _streamingAsrCompleter = null;
    _streamingAsrStartFuture = null;
    if (service != null) {
      await service.disconnect();
      service.dispose();
    }
  }

  Future<void> _startVoiceRecording() async {
    final AudioService audioService = AudioServiceScope.of(context);
    if (_recording ||
        _transcribing ||
        _submitting ||
        _finishingReview ||
        _hintThinking) {
      return;
    }
    unawaited(HapticFeedback.lightImpact());
    final bool granted = await audioService.requestPermission();
    if (!granted) {
      if (!mounted) {
        return;
      }
      setState(() => _errorText = '需要麦克风权限后才能语音作答');
      return;
    }
    await audioService.stopPlayback(clearRealtimeBuffer: false);
    _streamingAsrStartFuture = _startStreamingAsrCapture().catchError((
      Object error,
    ) {
      debugPrint('[InterviewLatency] streaming ASR unavailable: $error');
    });
    await audioService.startRecording(onPcmData: _sendStreamingAsrPcmChunk);
    if (!mounted) {
      return;
    }
    setState(() {
      _recording = true;
      _recordingElapsed = Duration.zero;
      _errorText = null;
      _activeComposerHintIndex = -1;
      _expandedExpressionSuggestionIndexes.clear();
    });
    _startRecordingTimer();
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_recording) {
        return;
      }
      setState(() {
        _recordingElapsed += const Duration(seconds: 1);
      });
    });
  }

  Future<void> _finishVoiceRecording({required bool cancel}) async {
    final AudioService audioService = AudioServiceScope.of(context);
    if (!_recording) {
      return;
    }
    unawaited(
      cancel ? HapticFeedback.selectionClick() : HapticFeedback.mediumImpact(),
    );
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final bool shouldCancel = cancel;
    setState(() {
      _recording = false;
      _recordingElapsed = Duration.zero;
      _transcribing = !shouldCancel;
    });
    final String? path = await audioService.stopRecording();
    final Future<String?> streamingTranscriptFuture =
        _finishStreamingAsrCapture();
    if (shouldCancel) {
      await streamingTranscriptFuture.catchError((_) => null);
      if (path != null && path.isNotEmpty) {
        unawaited(File(path).delete().then<void>((_) {}).catchError((_) {}));
      }
      if (mounted) {
        setState(() => _errorText = null);
      }
      return;
    }
    if (path == null || path.isEmpty) {
      await streamingTranscriptFuture.catchError((_) => null);
      if (mounted) {
        setState(() => _transcribing = false);
      }
      return;
    }
    await _transcribeAndSubmitVoice(
      path,
      streamingTranscriptFuture: streamingTranscriptFuture,
    );
  }

  Future<void> _transcribeAndSubmitVoice(
    String path, {
    Future<String?>? streamingTranscriptFuture,
  }) async {
    final Stopwatch pipelineWatch = Stopwatch()..start();
    _logVoiceLatency('transcribe:start', pipelineWatch);
    try {
      String transcript = '';
      if (streamingTranscriptFuture != null) {
        try {
          transcript = normalizeInterviewText(
            await streamingTranscriptFuture.timeout(
                  const Duration(milliseconds: 2200),
                  onTimeout: () => null,
                ) ??
                '',
          );
          if (transcript.isNotEmpty) {
            _logVoiceLatency('transcribe:stream_ready', pipelineWatch);
          }
        } catch (error) {
          debugPrint('[InterviewLatency] streaming ASR skipped: $error');
        }
      }
      if (transcript.isEmpty) {
        _logVoiceLatency('transcribe:file_start', pipelineWatch);
        transcript = normalizeInterviewText(
          await ApiClient.transcribeAudio(File(path), repairMode: 'background'),
        );
      }
      _logVoiceLatency('transcribe:ready', pipelineWatch);
      if (!mounted) {
        return;
      }
      if (transcript.isEmpty) {
        setState(() {
          _transcribing = false;
          _errorText = '没有识别到有效语音，请再说一遍';
        });
        return;
      }
      if (_looksLikeAssistantEcho(transcript)) {
        setState(() {
          _transcribing = false;
          _pendingVoiceAudioPath = null;
          _answerController.clear();
          _errorText = '这次像录到了系统刚播的问题，先不提交。请重新按住，直接说你的回答。';
        });
        return;
      }
      setState(() {
        _transcribing = false;
        _answerController.text = transcript;
        _pendingVoiceAudioPath = path;
      });
      await _submitAnswer(
        sourceAudioPath: path,
        overrideText: transcript,
        voicePipelineWatch: pipelineWatch,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _transcribing = false;
        _errorText = '语音识别失败：$error';
      });
    }
  }

  Future<void> _requestHint() async {
    final InterviewPracticeEngine? engine = _engine;
    final InterviewPracticeSession? session = _session;
    final InterviewLibrary? library = _library;
    final bool canRevealNextGeneratedHint =
        _activeComposerHintIndex >= 0 &&
        _activeComposerHintIndex < _composerHintStack.length - 1;
    if (engine == null ||
        session == null ||
        _hintThinking ||
        (_remainingHintsForCurrentQuestion() <= 0 &&
            !canRevealNextGeneratedHint)) {
      return;
    }
    final String stageKey = session.currentStage;
    if (_composerHintStage != stageKey) {
      setState(() {
        _composerHintStack.clear();
        _activeComposerHintIndex = -1;
        _composerHintStage = stageKey;
      });
    }
    if (_activeComposerHintIndex >= 0 &&
        _activeComposerHintIndex < _composerHintStack.length - 1) {
      setState(() => _activeComposerHintIndex += 1);
      return;
    }
    final InterviewChatMessage? questionMessage = _latestInterviewQuestion();
    final String question = questionMessage?.text ?? '';
    final String learnerDraft = _currentDraftOrLatestUserAnswer();
    final String answerFocus = _hintAnswerFocus(
      session: session,
      questionMessage: questionMessage,
    );
    final InterviewExpression? targetExpression = _hintTargetExpression(
      session: session,
      library: library,
      questionMessage: questionMessage,
      question: question,
    );
    final InterviewHint hint = engine.requestHint(session, question: question);
    setState(() => _hintThinking = true);
    final bool needsFullAnswer = hint.level == 'L4';
    final String? contextualHint = !needsFullAnswer || targetExpression == null
        ? null
        : await _llmScheduler.generateContextualHint(
            session: session,
            question: question,
            answerFocus: answerFocus,
            learnerDraft: learnerDraft,
            targetExpression: targetExpression,
            messages: _messages,
            memoryPack: _memoryPackFor(
              session: session,
              tag: targetExpression.tag.isNotEmpty
                  ? targetExpression.tag
                  : stageToPrimaryTag[session.currentStage],
              query: '$question $learnerDraft ${targetExpression.text}',
            ),
          );
    if (!mounted) {
      return;
    }
    final String tag =
        targetExpression?.tag ?? stageToPrimaryTag[session.currentStage] ?? '';
    setState(() {
      _hintThinking = false;
      _composerHintStage = session.currentStage;
      _composerHintStack.add(
        _ComposerHintData(
          stage: session.currentStage,
          level: hint.level,
          tag: tag,
          text: _hintDisplayText(hint: hint, contextualHint: contextualHint),
          createdAt: DateTime.now(),
        ),
      );
      _activeComposerHintIndex = _composerHintStack.length - 1;
    });
    unawaited(_saveActiveSession());
  }

  void _dismissComposerHint() {
    if (_activeComposerHintIndex < 0) {
      return;
    }
    setState(() => _activeComposerHintIndex = -1);
  }

  void _showPreviousComposerHint() {
    if (_activeComposerHintIndex <= 0) {
      return;
    }
    setState(() => _activeComposerHintIndex -= 1);
  }

  _ComposerHintData? _activeComposerHintFor(InterviewPracticeSession session) {
    if (_activeComposerHintIndex < 0 ||
        _activeComposerHintIndex >= _composerHintStack.length) {
      return null;
    }
    final _ComposerHintData hint = _composerHintStack[_activeComposerHintIndex];
    if (hint.stage != session.currentStage) {
      return null;
    }
    return hint;
  }

  Future<void> _saveActiveSession() async {
    final InterviewPracticeSession? session = _session;
    if (session == null || _review != null) {
      return;
    }
    try {
      await _wikiStore.saveActiveSession(
        session: session,
        messages: List<InterviewChatMessage>.from(_messages),
      );
    } catch (_) {}
  }

  String _currentDraftOrLatestUserAnswer() {
    final String draft = normalizeInterviewText(_answerController.text);
    if (draft.isNotEmpty) {
      return draft;
    }
    for (final InterviewChatMessage message in _messages.reversed) {
      if (message.role == 'user') {
        return message.text;
      }
    }
    return '';
  }

  InterviewWikiMemoryPack _memoryPackFor({
    required InterviewPracticeSession session,
    String? stage,
    String? tag,
    String query = '',
  }) {
    final String resolvedStage = stage ?? session.currentStage;
    final String? stageTargetTag =
        session.stageExpressionTargets[resolvedStage]?.tag;
    return _wikiStore.buildMemoryPack(
      tags: <String>[
        ?tag,
        ?stageTargetTag,
        stageToPrimaryTag[resolvedStage] ?? '',
      ],
      query: query,
      session: session,
    );
  }

  InterviewExpression? _hintTargetExpression({
    required InterviewPracticeSession session,
    required InterviewLibrary? library,
    required InterviewChatMessage? questionMessage,
    required String question,
  }) {
    final InterviewExpression? boundTarget = questionMessage?.targetExpression;
    if (boundTarget != null && boundTarget.text.isNotEmpty) {
      return boundTarget;
    }
    final InterviewExpression? reuseTarget = session.pendingReuseTarget;
    if (reuseTarget != null && reuseTarget.text.isNotEmpty) {
      return reuseTarget;
    }
    final InterviewExpression? stageTarget =
        session.stageExpressionTargets[session.currentStage];
    if (stageTarget != null && stageTarget.text.isNotEmpty) {
      return stageTarget;
    }
    if (library == null) {
      return null;
    }
    final List<InterviewExpression> fallbackExpressions =
        _hintExpressionsForCurrentStage(
          session: session,
          library: library,
          question: question,
        );
    return fallbackExpressions.isEmpty ? null : fallbackExpressions.first;
  }

  List<InterviewExpression> _hintExpressionsForCurrentStage({
    required InterviewPracticeSession session,
    required InterviewLibrary library,
    required String question,
  }) {
    final String stage = session.currentStage;
    final InterviewExpression? stageTarget =
        session.stageExpressionTargets[stage];
    final String tag = stageTarget?.tag ?? stageToPrimaryTag[stage] ?? '';
    final List<InterviewExpression> expressions = <InterviewExpression>[
      ?stageTarget,
      ?session.pendingReuseTarget,
      ...library.expressions.where(
        (InterviewExpression expression) => expression.tag == tag,
      ),
    ];
    final Set<String> seen = <String>{};
    final List<InterviewExpression> filtered = expressions
        .where((InterviewExpression expression) {
          final String key = expression.id.isNotEmpty
              ? expression.id
              : expression.text.toLowerCase();
          if (key.isEmpty || seen.contains(key)) {
            return false;
          }
          seen.add(key);
          return true;
        })
        .toList(growable: false);
    filtered.sort(
      (InterviewExpression a, InterviewExpression b) => _hintExpressionScore(
        question,
        b,
      ).compareTo(_hintExpressionScore(question, a)),
    );
    return filtered.take(8).toList(growable: false);
  }

  int _hintExpressionScore(String question, InterviewExpression expression) {
    final Set<String> questionTokens = _hintContentTokens(question);
    final Set<String> expressionTokens = _hintContentTokens(
      '${expression.text} ${expression.useCase}',
    );
    int score = questionTokens.intersection(expressionTokens).length * 10;
    final String normalizedQuestion = question.toLowerCase();
    final String normalizedExpression =
        '${expression.text} ${expression.useCase}'.toLowerCase();
    if (normalizedQuestion.contains('excite') &&
        normalizedExpression.contains('excite')) {
      score += 40;
    }
    if (normalizedQuestion.contains('why') &&
        (normalizedExpression.contains('reason') ||
            normalizedExpression.contains('applied') ||
            normalizedExpression.contains('fit'))) {
      score += 24;
    }
    if (normalizedQuestion.contains('company') &&
        normalizedExpression.contains('company')) {
      score += 18;
    }
    if (normalizedQuestion.contains('role') &&
        normalizedExpression.contains('role')) {
      score += 18;
    }
    if (expression.level == 'beginner') {
      score -= 2;
    }
    return score;
  }

  Set<String> _hintContentTokens(String value) {
    const Set<String> stopWords = <String>{
      'what',
      'which',
      'where',
      'when',
      'why',
      'how',
      'the',
      'and',
      'you',
      'your',
      'this',
      'that',
      'about',
      'most',
      'part',
      'with',
      'from',
      'into',
    };
    return RegExp(r"[a-zA-Z']+")
        .allMatches(value.toLowerCase())
        .map((RegExpMatch match) => _stemHintToken(match.group(0)!))
        .where((String token) => token.length > 3 && !stopWords.contains(token))
        .toSet();
  }

  String _stemHintToken(String token) {
    if (token.length > 5 && token.endsWith('ing')) {
      return token.substring(0, token.length - 3);
    }
    if (token.length > 4 && token.endsWith('ed')) {
      return token.substring(0, token.length - 2);
    }
    if (token.length > 4 && token.endsWith('es')) {
      return token.substring(0, token.length - 2);
    }
    if (token.length > 4 && token.endsWith('s')) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  String _hintDisplayText({
    required InterviewHint hint,
    required String? contextualHint,
  }) {
    final String base = _stripRepeatedQuestionFromHint(hint.text);
    final String answer = _stripRepeatedQuestionFromHint(contextualHint ?? '');
    if (hint.level == 'L4') {
      return _compactFullAnswerHint(baseHint: base, contextualHint: answer);
    }
    if (answer.isEmpty) {
      return base;
    }
    return <String>[if (base.isNotEmpty) base, '可以这样答：$answer'].join('\n');
  }

  String _compactFullAnswerHint({
    required String baseHint,
    required String contextualHint,
  }) {
    final String answer =
        _extractDirectHintAnswer(contextualHint) ??
        _extractDirectHintAnswer(baseHint) ??
        _extractHintTarget(contextualHint) ??
        _extractHintTarget(baseHint) ??
        '';
    final String cleaned = _cleanDirectHintAnswer(answer);
    if (cleaned.isEmpty) {
      return _cleanDirectHintAnswer(baseHint);
    }
    return '可以这样答：$cleaned';
  }

  String? _extractDirectHintAnswer(String value) {
    final List<String> lines = value
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    for (final String line in lines.reversed) {
      final String? answer = _valueAfterAnyPrefix(line, const <String>[
        '可以这样答：',
        '可以这样答:',
        '完整回答：',
        '完整回答:',
        'suggested_reply:',
        '"suggested_reply":',
      ]);
      if (answer != null && _cleanDirectHintAnswer(answer).isNotEmpty) {
        return answer;
      }
    }
    for (final String line in lines.reversed) {
      final String? answer = _valueAfterAnyPrefix(line, const <String>[
        '提示：',
        '提示:',
      ]);
      if (answer != null && _cleanDirectHintAnswer(answer).isNotEmpty) {
        return answer;
      }
    }
    final String text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _extractHintTarget(String value) {
    for (final String line in value.split('\n')) {
      final String? target = _valueAfterAnyPrefix(line.trim(), const <String>[
        '可用表达：',
        '可用表达:',
        '可以用：',
        '可以用:',
      ]);
      if (target != null && _cleanDirectHintAnswer(target).isNotEmpty) {
        return target;
      }
    }
    return null;
  }

  String? _valueAfterAnyPrefix(String value, List<String> prefixes) {
    for (final String prefix in prefixes) {
      if (value.toLowerCase().startsWith(prefix.toLowerCase())) {
        return value.substring(prefix.length).trim();
      }
    }
    return null;
  }

  String _cleanDirectHintAnswer(String value) {
    String text = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\-•]\s*'), '')
        .trim();
    bool removedPrefix = true;
    while (removedPrefix) {
      removedPrefix = false;
      for (final String prefix in const <String>[
        '可以这样答：',
        '可以这样答:',
        '可用表达：',
        '可用表达:',
        '可以用：',
        '可以用:',
        '提示：',
        '提示:',
        'Try starting with:',
        'Try saying:',
      ]) {
        if (text.toLowerCase().startsWith(prefix.toLowerCase())) {
          text = text.substring(prefix.length).trim();
          removedPrefix = true;
          break;
        }
      }
    }
    text = text
        .replaceAll(RegExp("^[\"“”']+"), '')
        .replaceAll(RegExp("[\"“”']+\$"), '')
        .trim();
    final int explanationStart = text.indexOf('——');
    if (explanationStart > 0) {
      text = text.substring(0, explanationStart).trim();
    }
    return text;
  }

  String _stripRepeatedQuestionFromHint(String value) {
    return value
        .split('\n')
        .map((String line) => line.trim())
        .where(
          (String line) =>
              line.isNotEmpty && !line.toLowerCase().startsWith('面试官问：'),
        )
        .join('\n')
        .trim();
  }

  String _hintAnswerFocus({
    required InterviewPracticeSession session,
    required InterviewChatMessage? questionMessage,
  }) {
    final String messageFocus = questionMessage?.mustAskAbout.trim() ?? '';
    if (messageFocus.isNotEmpty) {
      return messageFocus;
    }
    return switch (session.currentStage) {
      'open' => 'the learner current role or interview goal',
      'self_intro' => 'the learner background and current role',
      'background' => 'the learner years of experience or work background',
      'experience_project' => 'one concrete project or responsibility',
      'strength' => 'one strength and a quick example',
      'role_fit' => 'why the learner is interested in this role or company',
      'career_plan' => 'the learner career direction and how this role fits',
      'weakness' => 'one real weakness and the specific action being taken',
      'pressure' => 'a pressure situation and what the learner learned',
      'salary_optional' => 'salary expectations or compensation priorities',
      'candidate_question' => 'one thoughtful question for the interviewer',
      _ => stageLabels[session.currentStage] ?? session.currentStage,
    };
  }

  InterviewChatMessage? _latestInterviewQuestion() {
    for (final InterviewChatMessage message in _messages.reversed) {
      if (message.role != 'assistant' ||
          message.isHint ||
          message.isAlignment ||
          message.isMastered ||
          _isCoachFeedbackMessage(message)) {
        continue;
      }
      return message;
    }
    return null;
  }

  bool _isCoachFeedbackMessage(InterviewChatMessage message) {
    final String action = message.questionPlanAction.trim();
    if (const <String>{
      'coach_retry',
      'scaffold',
      'model_then_retry',
      'pronunciation_focus',
      'grammar_focus',
      'repair_misunderstanding',
      'transfer_practice',
    }.contains(action)) {
      return true;
    }
    final String text = message.text.trim();
    if (text.isEmpty) {
      return true;
    }
    if (message.mustAskAbout.trim().isNotEmpty && text.contains('?')) {
      return false;
    }
    final String normalized = _normalizeForEchoCheck(text);
    final bool looksLikeInterviewQuestion =
        text.contains('?') ||
        RegExp(
          r'^(welcome|hi|hello|could|can|would|what|why|how|tell|give)\b',
          caseSensitive: false,
        ).hasMatch(normalized);
    return !looksLikeInterviewQuestion;
  }

  Set<int> _collapsedHintMessageIndexes() {
    final Map<String, int> latestHintIndexByStage = <String, int>{};
    final Map<String, List<int>> hintIndexesByStage = <String, List<int>>{};
    for (int index = 0; index < _messages.length; index += 1) {
      final InterviewChatMessage message = _messages[index];
      if (!message.isHint) {
        continue;
      }
      final String stageKey = message.stage.trim().isNotEmpty
          ? message.stage.trim()
          : 'hint_$index';
      latestHintIndexByStage[stageKey] = index;
      hintIndexesByStage.putIfAbsent(stageKey, () => <int>[]).add(index);
    }
    final Set<int> collapsed = <int>{};
    for (final MapEntry<String, List<int>> entry
        in hintIndexesByStage.entries) {
      final int? latestIndex = latestHintIndexByStage[entry.key];
      if (latestIndex == null || entry.value.length < 2) {
        continue;
      }
      collapsed.addAll(entry.value.where((int index) => index != latestIndex));
    }
    return collapsed;
  }

  bool _looksLikeAssistantEcho(String transcript) {
    final String normalizedTranscript = _normalizeForEchoCheck(transcript);
    if (normalizedTranscript.length < 16) {
      return false;
    }
    final bool learnerLike = _looksLikeLearnerAnswer(transcript);
    if (learnerLike) {
      return false;
    }
    final String lastAssistant = _latestInterviewQuestion()?.text ?? '';
    final String normalizedAssistant = _normalizeForEchoCheck(lastAssistant);
    if (normalizedAssistant.isEmpty) {
      return false;
    }
    if (normalizedAssistant == normalizedTranscript) {
      return true;
    }
    final Set<String> transcriptWords = tokenizeInterviewWords(
      normalizedTranscript,
    ).toSet();
    final Set<String> assistantWords = tokenizeInterviewWords(
      normalizedAssistant,
    ).toSet();
    if (transcriptWords.length < 5 || assistantWords.length < 5) {
      return false;
    }
    if (normalizedAssistant.contains(normalizedTranscript)) {
      final double transcriptShare =
          transcriptWords.length / assistantWords.length;
      return transcriptShare >= 0.45;
    }
    if (normalizedTranscript.contains(normalizedAssistant)) {
      final int extraWords = transcriptWords.difference(assistantWords).length;
      return extraWords < 3;
    }
    final double overlap =
        transcriptWords.intersection(assistantWords).length /
        transcriptWords.length;
    return overlap >= 0.72;
  }

  bool _looksLikeLearnerAnswer(String transcript) {
    if (_looksLikeCurrentTargetAttempt(transcript)) {
      return true;
    }
    final String normalized = _normalizeForEchoCheck(transcript);
    final Set<String> words = tokenizeInterviewWords(normalized).toSet();
    if (words.isEmpty) {
      return false;
    }
    const Set<String> firstPersonWords = <String>{
      'i',
      "i'm",
      'im',
      "i've",
      'ive',
      "i'd",
      'id',
      "i’ll",
      'ill',
      'me',
      'my',
      'mine',
      'we',
      "we're",
      "we've",
      'our',
      'ours',
    };
    if (words.intersection(firstPersonWords).isNotEmpty) {
      return true;
    }
    const Set<String> answerSignals = <String>{
      'worked',
      'work',
      'experience',
      'project',
      'responsible',
      'learned',
      'improved',
      'achieved',
      'built',
      'handled',
      'managed',
      'helped',
      'because',
      'so',
      'therefore',
      'example',
      'strength',
      'weakness',
      'role',
      'team',
      'company',
    };
    if (words.intersection(answerSignals).isNotEmpty) {
      return true;
    }
    return false;
  }

  bool _looksLikeCurrentTargetAttempt(String transcript) {
    final String normalizedTranscript = _normalizeForEchoCheck(transcript);
    if (normalizedTranscript.isEmpty) {
      return false;
    }
    final InterviewPracticeSession? session = _session;
    final InterviewChatMessage? questionMessage = _latestInterviewQuestion();
    final List<InterviewExpression> targets =
        _uniqueExpressions(<InterviewExpression>[
          ?questionMessage?.targetExpression,
          ?session?.pendingReuseTarget,
          if (session != null)
            ?session.stageExpressionTargets[session.currentStage],
        ]);
    for (final InterviewExpression target in targets) {
      if (_matchesTargetAttempt(
        transcript: transcript,
        normalizedTranscript: normalizedTranscript,
        target: target,
      )) {
        return true;
      }
    }
    return false;
  }

  bool _matchesTargetAttempt({
    required String transcript,
    required String normalizedTranscript,
    required InterviewExpression target,
  }) {
    if (expressionReproduced(
      expressionText: target.text,
      userText: transcript,
    )) {
      return true;
    }
    final InterviewExpressionNode? node = _sceneGraph?.nodeById(target.id);
    final List<String> variants = <String>[
      target.text,
      ...?node?.reproducibleTexts,
    ];
    for (final String variant in variants) {
      final String normalizedVariant = _normalizeForEchoCheck(variant);
      if (normalizedVariant.isEmpty) {
        continue;
      }
      if (expressionReproduced(expressionText: variant, userText: transcript)) {
        return true;
      }
      if (_targetContainsSpokenChunk(
        normalizedTarget: normalizedVariant,
        normalizedTranscript: normalizedTranscript,
      )) {
        return true;
      }
    }
    return false;
  }

  bool _targetContainsSpokenChunk({
    required String normalizedTarget,
    required String normalizedTranscript,
  }) {
    final Set<String> transcriptWords = tokenizeInterviewWords(
      normalizedTranscript,
    ).where((String token) => token.length > 2).toSet();
    if (transcriptWords.length < 3) {
      return false;
    }
    if (normalizedTarget.contains(normalizedTranscript)) {
      return true;
    }
    final Set<String> targetWords = tokenizeInterviewWords(
      normalizedTarget,
    ).where((String token) => token.length > 2).toSet();
    if (targetWords.isEmpty) {
      return false;
    }
    final int hits = transcriptWords.intersection(targetWords).length;
    return hits >= 3 && hits / transcriptWords.length >= 0.72;
  }

  String _normalizeForEchoCheck(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _speakAssistant(String text) async {
    final String speechText = text.trim();
    if (!mounted || !_shouldAutoSpeakAssistantText(speechText)) {
      return;
    }
    try {
      await AudioServiceScope.of(context).playAutoAssistantTts(speechText);
    } catch (_) {}
  }

  bool _shouldAutoSpeakAssistantText(String text) {
    if (text.isEmpty) {
      return false;
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(text)) {
      return false;
    }
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
      return false;
    }
    return text.length <= 220;
  }

  Future<void> _exitPractice() async {
    if (_exitInProgress) {
      return;
    }
    final bool confirmed = await _confirmExitPractice();
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _exitInProgress = true);
    unawaited(HapticFeedback.mediumImpact());
    if (_recording) {
      await _finishVoiceRecording(cancel: true);
    }
    if (mounted) {
      unawaited(
        AudioServiceScope.of(context).stopPlayback(clearRealtimeBuffer: false),
      );
    }
    _startExitFinalizationInBackground();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).maybePop();
  }

  Future<bool> _confirmExitPractice() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            '退出本轮练习？',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          content: const Text(
            '确认后会立即返回首页。本轮内容会继续在后台整理进个人 Wiki，不需要停在这里等待。',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('继续练习'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('确认退出'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  void _startExitFinalizationInBackground() {
    if (_exitFinalizationStarted || _wikiCompiling) {
      return;
    }
    final InterviewPracticeEngine? engine = _engine;
    final InterviewPracticeSession? session = _session;
    if (engine == null || session == null) {
      return;
    }
    _exitFinalizationStarted = true;
    final PronunciationScore? pronunciationScore = _lastPronunciationScore;
    unawaited(
      _finalizePracticeAfterExit(
        engine: engine,
        session: session,
        pronunciationScore: pronunciationScore,
      ),
    );
  }

  Future<void> _finalizePracticeAfterExit({
    required InterviewPracticeEngine engine,
    required InterviewPracticeSession session,
    required PronunciationScore? pronunciationScore,
  }) async {
    try {
      final InterviewReview review =
          _review ??
          engine.review(
            session,
            masteredWikiExpressions: _wikiStore.loadMasteredExpressions(),
          );
      await _writeWikiFromReview(
        session: session,
        review: review,
        pronunciationScore: pronunciationScore,
      );
      await _wikiStore.clearActiveSession();
    } catch (error, stackTrace) {
      debugPrint('Background wiki finalization failed: $error\n$stackTrace');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 160,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final InterviewPracticeSession? session = _session;
    final Set<int> collapsedHintMessageIndexes = _collapsedHintMessageIndexes();
    final int firstProminentMessageIndex = (_messages.length - 4)
        .clamp(0, _messages.length)
        .toInt();
    final List<InterviewChatMessage> displayMessages = session == null
        ? _messages
        : _messages
              .map(
                (InterviewChatMessage message) =>
                    _messageWithRecoveredMastery(message, session),
              )
              .toList(growable: false);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: appBackground,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorText != null && session == null
            ? _ErrorState(
                message: _errorText!,
                onRetry: () => unawaited(_bootstrap()),
              )
            : Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(session!),
                      _TopTargetProgressBand(
                        progress: _sceneStageProgressFor(session),
                      ),
                      if (_topProgressVisible)
                        _TopConversationProgress(label: _topProgressLabel()),
                      Expanded(
                        child: ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            14,
                            16,
                            _conversationBottomPadding(context),
                          ),
                          children: [
                            for (
                              int index = 0;
                              index < displayMessages.length;
                              index += 1
                            )
                              _InterviewMessageBubble(
                                message: displayMessages[index],
                                assistantName: _assistantDisplayName(),
                                assistantRoleLabel: _assistantRoleLabel(),
                                softened: index < firstProminentMessageIndex,
                                collapsed: collapsedHintMessageIndexes.contains(
                                  index,
                                ),
                                translation:
                                    _translatedMessageIndexes.contains(index)
                                    ? _messageTranslations[index]
                                    : null,
                                translating: _translatingMessageIndexes
                                    .contains(index),
                                voiceTextRevealed: _revealedVoiceMessageIndexes
                                    .contains(index),
                                masteryStreak: _masteryStreakEndingAt(
                                  index,
                                  session,
                                ),
                                expressionSuggestionExpanded:
                                    _expandedExpressionSuggestionIndexes
                                        .contains(index),
                                onTranslate:
                                    displayMessages[index].role ==
                                            'assistant' &&
                                        !collapsedHintMessageIndexes.contains(
                                          index,
                                        )
                                    ? () => unawaited(
                                        _toggleMessageTranslation(
                                          index,
                                          displayMessages[index],
                                        ),
                                      )
                                    : null,
                                onPlayAssistant:
                                    displayMessages[index].role ==
                                            'assistant' &&
                                        !collapsedHintMessageIndexes.contains(
                                          index,
                                        )
                                    ? () => unawaited(
                                        _playAssistantMessage(
                                          displayMessages[index],
                                        ),
                                      )
                                    : null,
                                onRevealVoiceText:
                                    displayMessages[index].role == 'user' &&
                                        displayMessages[index].isVoice
                                    ? () => setState(() {
                                        if (_revealedVoiceMessageIndexes
                                            .contains(index)) {
                                          _revealedVoiceMessageIndexes.remove(
                                            index,
                                          );
                                        } else {
                                          _revealedVoiceMessageIndexes.add(
                                            index,
                                          );
                                        }
                                      })
                                    : null,
                                onPlayUserVoice:
                                    displayMessages[index].role == 'user' &&
                                        displayMessages[index].isVoice
                                    ? () => unawaited(
                                        _playUserVoiceMessage(
                                          displayMessages[index],
                                        ),
                                      )
                                    : null,
                                onToggleExpressionSuggestion:
                                    displayMessages[index].role == 'user' &&
                                        displayMessages[index]
                                            .hasExpressionSuggestion &&
                                        !displayMessages[index].isMastered
                                    ? () => setState(() {
                                        if (_expandedExpressionSuggestionIndexes
                                            .contains(index)) {
                                          _expandedExpressionSuggestionIndexes
                                              .remove(index);
                                        } else {
                                          _expandedExpressionSuggestionIndexes
                                              .add(index);
                                        }
                                      })
                                    : null,
                              ),
                            if (_llmThinking || _submitting)
                              _TypingDotsBubble(
                                label: '${_assistantRoleLabel()}思考中',
                              ),
                            if (_hintThinking)
                              const _TypingDotsBubble(label: '提示生成中'),
                            if (_wikiCompiling)
                              const _ThinkingBubble(label: 'AI 正在编译个人 Wiki'),
                            if (_errorText != null) ...[
                              const SizedBox(height: 8),
                              _InlineError(message: _errorText!),
                            ],
                            if (_review != null) ...[
                              const SizedBox(height: 12),
                              _ReviewPanel(
                                review: _review!,
                                aiNote: _aiReviewNote,
                                onRestart: () => unawaited(
                                  _bootstrap(roundMode: _review!.nextRoundMode),
                                ),
                              ),
                              if (_wikiWriteSummary != null) ...[
                                const SizedBox(height: 10),
                                _WikiWriteSummaryPanel(
                                  summary: _wikiWriteSummary!,
                                  onOpenWiki: () {
                                    final InterviewPracticeSession? session =
                                        _session;
                                    if (session != null) {
                                      _showWikiStateSheet(session);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: _buildComposer(session),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  double _conversationBottomPadding(BuildContext context) {
    final InterviewPracticeSession? session = _session;
    final bool showingComposerHint =
        session != null && _activeComposerHintFor(session) != null;
    return MediaQuery.paddingOf(context).bottom +
        (showingComposerHint ? 270 : 150);
  }

  int _masteryStreakEndingAt(
    int messageIndex,
    InterviewPracticeSession? session,
  ) {
    if (messageIndex < 0 || messageIndex >= _messages.length) {
      return 0;
    }
    final InterviewChatMessage current = _messages[messageIndex];
    if (!_isVoiceMessageMastered(current, session)) {
      return 0;
    }
    int streak = 0;
    for (int index = messageIndex; index >= 0; index -= 1) {
      final InterviewChatMessage message = _messages[index];
      if (message.role != 'user' || !message.isVoice) {
        continue;
      }
      if (!_isVoiceMessageMastered(message, session)) {
        break;
      }
      streak += 1;
    }
    return streak;
  }

  bool _isVoiceMessageMastered(
    InterviewChatMessage message,
    InterviewPracticeSession? session,
  ) {
    if (message.role != 'user' || !message.isVoice) {
      return false;
    }
    if (message.isMastered) {
      return true;
    }
    if (session == null) {
      return false;
    }
    final Set<String> candidateIds = <String>{
      message.targetExpression?.id ?? '',
      message.stage,
      session.stageExpressionTargets[message.stage]?.id ?? '',
    }.where((String id) => id.trim().isNotEmpty).toSet();
    return candidateIds.any(
      (String id) =>
          session.masteredExpressionIds.contains(id) ||
          session.roundMasteredExpressionIds.contains(id) ||
          session.completedTargetExpressionIds.contains(id),
    );
  }

  InterviewChatMessage _messageWithRecoveredMastery(
    InterviewChatMessage message,
    InterviewPracticeSession? session,
  ) {
    if (message.isMastered || !_isVoiceMessageMastered(message, session)) {
      return message;
    }
    return _copyMessageWithMasteryFeedback(
      message,
      targetExpression:
          message.targetExpression ??
          session?.stageExpressionTargets[message.stage],
    );
  }

  bool get _topProgressVisible =>
      _transcribing ||
      _finishingReview ||
      _llmThinking ||
      _wikiCompiling ||
      _submitting;

  String _topProgressLabel() {
    if (_transcribing) {
      return '正在识别语音';
    }
    if (_wikiCompiling) {
      return '正在编译个人 Wiki';
    }
    if (_finishingReview) {
      return '正在生成复盘';
    }
    if (_llmThinking || _submitting) {
      return '${_assistantRoleLabel()}思考中';
    }
    return '处理中';
  }

  String _headerRealtimeStatusTitle() {
    if (_recording) {
      return '正在听你回答';
    }
    if (_transcribing) {
      return '正在识别语音';
    }
    if (_submitting || _llmThinking) {
      return '${_assistantRoleLabel()}思考中';
    }
    if (_finishingReview) {
      return '正在生成复盘';
    }
    if (_wikiCompiling) {
      return '后台整理中';
    }
    return '实时演练中';
  }

  String _headerRealtimeStatusSubtitle(InterviewPracticeSession session) {
    return '${_conversationSceneTitle()} · ${_conversationStageSubtitle(session)}';
  }

  String _conversationSceneTitle() {
    final String sceneId = _sceneGraph?.id.trim() ?? widget.sceneId;
    if (sceneId == defaultInterviewSceneId || sceneId == 'job_interview') {
      return 'Google PM 面试';
    }
    final String titleCn = _sceneGraph?.titleCn.trim() ?? '';
    if (titleCn.isNotEmpty) {
      return titleCn;
    }
    final String titleEn = _sceneGraph?.titleEn.trim() ?? '';
    return titleEn.isEmpty ? '英语情景演练' : titleEn;
  }

  String _assistantDisplayName() {
    final String sceneId = _sceneGraph?.id.trim() ?? widget.sceneId;
    if (sceneId == 'onboarding_introduction') {
      return 'Maya Chen';
    }
    return 'Emma Carter';
  }

  String _assistantRoleLabel() {
    final String sceneId = _sceneGraph?.id.trim() ?? widget.sceneId;
    if (sceneId == 'onboarding_introduction') {
      return '入职导师';
    }
    return '面试官';
  }

  String _conversationStageSubtitle(InterviewPracticeSession session) {
    final InterviewExpressionNode? node = _sceneGraph?.nodeById(
      session.currentStage,
    );
    final String rawStage = node?.stageLabel.trim().isNotEmpty == true
        ? node!.stageLabel.trim()
        : stageLabels[session.currentStage] ?? session.currentStage;
    final String stage = _sceneStageChineseLabel(
      rawStage,
      fallbackId: session.currentStage,
    );
    final int position = math.max(0, session.stageIndex) + 1;
    return '第${_shortChineseNumber(position)}轮 · $stage';
  }

  String _sceneStageChineseLabel(String label, {required String fallbackId}) {
    final String source = '$label $fallbackId'.toLowerCase();
    if (source.contains('open') ||
        source.contains('开场') ||
        source.contains('寒暄') ||
        source.contains('自我介绍')) {
      return '开场寒暄';
    }
    if (source.contains('role') ||
        source.contains('岗位') ||
        source.contains('匹配') ||
        source.contains('认知')) {
      return '岗位认知';
    }
    if (source.contains('experience') ||
        source.contains('project') ||
        source.contains('背景') ||
        source.contains('经验') ||
        source.contains('项目')) {
      return '经历项目';
    }
    if (source.contains('strength') || source.contains('优势')) {
      return '优势说明';
    }
    if (source.contains('pressure') || source.contains('压力')) {
      return '压力追问';
    }
    if (source.contains('question') ||
        source.contains('反问') ||
        source.contains('提问')) {
      return '候选人提问';
    }
    if (source.contains('salary') || source.contains('薪资')) {
      return '薪资沟通';
    }
    if (source.contains('wrap') ||
        source.contains('closing') ||
        source.contains('结束') ||
        source.contains('致谢')) {
      return '收尾致谢';
    }
    return label.trim().isEmpty ? '实时演练' : label.trim();
  }

  String _shortChineseNumber(int value) {
    return switch (value) {
      1 => '一',
      2 => '二',
      3 => '三',
      4 => '四',
      5 => '五',
      6 => '六',
      7 => '七',
      8 => '八',
      9 => '九',
      10 => '十',
      _ => '$value',
    };
  }

  Widget _buildHeader(InterviewPracticeSession session) {
    final String statusTitle = _headerRealtimeStatusTitle();
    final String subtitle = _headerRealtimeStatusSubtitle(session);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 5),
      child: Row(
        children: [
          IconButton(
            tooltip: '退出',
            onPressed: _exitInProgress
                ? null
                : () => unawaited(_exitPractice()),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: textPrimary,
              fixedSize: const Size(40, 40),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.chevron_left_rounded, size: 25),
          ),
          Expanded(
            child: Padding(
              key: const ValueKey<String>('interview_realtime_status_header'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: _chromeTitleStyle.copyWith(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF20241F),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 11.5,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            key: const ValueKey<String>('interview_scene_map_menu_button'),
            tooltip: '场景导航',
            onPressed: () => unawaited(_showSceneMap(session)),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: textPrimary,
              fixedSize: const Size(40, 40),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.more_horiz_rounded, size: 24),
          ),
        ],
      ),
    );
  }

  void _showWikiStateSheet(InterviewPracticeSession session) {
    final InterviewSceneGraph? sceneGraph = _sceneGraph;
    final InterviewLibrary? library = _library;
    final InterviewUserGrowthWiki growthWiki = _wikiStore.loadUserGrowthWiki();
    final InterviewCompiledWiki compiledWiki = _wikiStore.loadCompiledWiki();
    final InterviewWikiActionPlan actionPlan = _wikiStore.buildActionPlan(
      session: session,
    );
    final List<InterviewPersonalWikiExpression> masteredExpressions = _wikiStore
        .loadMasteredExpressions();
    final DateTime now = DateTime.now();
    final List<InterviewPersonalWikiExpression> dueExpressions =
        masteredExpressions
            .where(
              (InterviewPersonalWikiExpression item) =>
                  !item.nextReviewAt.isAfter(now),
            )
            .toList(growable: false)
          ..sort(
            (
              InterviewPersonalWikiExpression a,
              InterviewPersonalWikiExpression b,
            ) => a.nextReviewAt.compareTo(b.nextReviewAt),
          );
    final List<InterviewWeakExpressionState> weakExpressions = growthWiki
        .weakExpressions
        .where(
          (InterviewWeakExpressionState item) =>
              item.sourceSceneId == session.publicSceneId,
        )
        .toList(growable: false);
    final List<InterviewUserErrorPattern> errorPatterns = growthWiki
        .errorPatterns
        .where(
          (InterviewUserErrorPattern item) =>
              item.sourceSceneId == session.publicSceneId,
        )
        .toList(growable: false);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: appBackground,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return _InterviewWikiStateSheet(
          session: session,
          sceneGraph: sceneGraph,
          library: library,
          actionPlan: actionPlan,
          compiledWiki: compiledWiki,
          growthWiki: growthWiki,
          masteredExpressions: masteredExpressions,
          dueExpressions: dueExpressions,
          weakExpressions: weakExpressions,
          errorPatterns: errorPatterns,
          currentNode: sceneGraph?.nodeById(session.currentStage),
          review: _review,
          onDismissAction: (String id) async {
            await _wikiStore.dismissWikiItem(id);
            if (sheetContext.mounted && mounted) {
              Navigator.of(sheetContext).pop();
              _showWikiStateSheet(session);
            }
          },
          onMarkUseful: (String id) async {
            await _wikiStore.markWikiItemUseful(id);
            if (sheetContext.mounted && mounted) {
              Navigator.of(sheetContext).pop();
              _showWikiStateSheet(session);
            }
          },
        );
      },
    );
  }

  Future<void> _showSceneMap(InterviewPracticeSession session) async {
    final InterviewSceneGraph? sceneGraph = _sceneGraph;
    if (sceneGraph == null) {
      return;
    }
    final Map<String, _SceneNodePracticeStats> practiceStatsByNode =
        _practiceStatsByNode(session);
    final _SceneMapResult? selected = await Navigator.of(context)
        .push<_SceneMapResult>(
          PageRouteBuilder<_SceneMapResult>(
            opaque: true,
            transitionDuration: const Duration(milliseconds: 260),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            pageBuilder:
                (BuildContext context, Animation<double> animation, _) {
                  return _SceneMapPage(
                    sceneGraph: sceneGraph,
                    session: session,
                    masteredNodeIds: _masteredNodeIds(session),
                    preparedNodeIds: _preparedNodeIds(session),
                    dueNodeIds: _dueNodeIds(),
                    weakNodeIds: _weakNodeIds(session),
                    practiceStatsByNode: practiceStatsByNode,
                  );
                },
            transitionsBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child,
                ) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  );
                },
          ),
        );
    if (selected == null || !mounted) {
      return;
    }
    final String? targetLevel = selected.targetLevel;
    if (targetLevel != null) {
      await _switchToTargetLevel(targetLevel);
      return;
    }
    final InterviewExpressionNode? node = selected.node;
    if (node != null) {
      await _switchToSceneNode(node);
    }
  }

  Future<void> _switchToTargetLevel(String targetLevel) async {
    final String normalizedLevel = _normalizeSceneMapTargetLevel(targetLevel);
    final InterviewPracticeEngine? engine = _engine;
    final InterviewSceneGraph? sceneGraph = _sceneGraph;
    final InterviewLibrary? library = _library;
    final InterviewPracticeSession? currentSession = _session;
    if (currentSession?.targetLevel == normalizedLevel && _review == null) {
      return;
    }
    if (engine == null || sceneGraph == null || library == null) {
      _runtimeTargetLevel = normalizedLevel;
      await _bootstrap();
      return;
    }
    _answerController.clear();
    setState(() {
      _runtimeTargetLevel = normalizedLevel;
      _loading = true;
      _errorText = null;
      _submitting = false;
      _llmThinking = false;
      _hintThinking = false;
      _transcribing = false;
      _pendingVoiceAudioPath = null;
    });
    try {
      unawaited(
        _wikiStore.saveSelectedTargetLevel(normalizedLevel).catchError((_) {}),
      );
      final String userId = AppSessionScope.of(context).nickname;
      final List<InterviewPersonalWikiExpression> masteredWikiExpressions =
          _wikiStore.loadMasteredExpressions();
      final List<InterviewExpressionLearningProgress> preparedLearningProgress =
          _wikiStore.loadExpressionLearningProgress();
      final List<InterviewWeakExpressionState> weakExpressions = _wikiStore
          .loadUserGrowthWiki()
          .weakExpressions;
      final InterviewNextRoundMode roundMode = engine
          .roundModeForMasteredExpressions(
            masteredWikiExpressions,
            targetLevel: normalizedLevel,
          );
      final InterviewPracticeSession session = engine.startSession(
        userId: userId,
        targetLevel: normalizedLevel,
        roundMode: roundMode,
        masteredWikiExpressions: masteredWikiExpressions,
        preparedLearningProgress: preparedLearningProgress,
        weakExpressions: weakExpressions,
      );
      final InterviewQuestionPlan openingPlan = engine
          .openingQuestionPlanForSession(
            session: session,
            masteredWikiExpressions: masteredWikiExpressions,
          );
      final String opening = openingPlan.localFallbackQuestion;
      if (!mounted) {
        return;
      }
      setState(() {
        _resetMessageUiState();
        _library = library;
        _sceneGraph = sceneGraph;
        _engine = engine;
        _session = session;
        _messages
          ..clear()
          ..add(
            InterviewChatMessage(
              role: 'assistant',
              text: opening,
              createdAt: DateTime.now(),
              stage: session.currentStage,
              tag: openingPlan.predictedTag,
              targetExpression: openingPlan.targetExpression,
              questionPlanAction: openingPlan.action,
              mustAskAbout: openingPlan.mustAskAbout,
            ),
          );
        _review = null;
        _aiReviewNote = null;
        _wikiWriteSummary = null;
        _lastPronunciationScore = null;
        _pendingVoiceAudioPath = null;
        _loading = false;
      });
      unawaited(_saveActiveSession());
      unawaited(_speakAssistant(opening));
      _prewarmQuestionSession();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorText = '切换等级失败：$error';
      });
    }
  }

  Future<void> _switchToSceneNode(InterviewExpressionNode node) async {
    final InterviewPracticeSession? session = _session;
    if (session == null || _review != null) {
      return;
    }
    if (session.currentStage == node.id) {
      return;
    }
    final String question = _manualSceneJumpQuestion(node);
    setState(() {
      session.stageIndex = _resetPlanForManualSceneJump(session, node);
      session.stageExpressionTargets[node.id] = node.toExpression();
      session.pendingReuseTarget = null;
      session.pendingReuseTargetForced = false;
      _messages.add(
        InterviewChatMessage(
          role: 'assistant',
          text: question,
          createdAt: DateTime.now(),
          stage: node.id,
          tag: node.tag,
          targetExpression: node.toExpression(),
          questionPlanAction: 'manual_scene_jump',
          mustAskAbout: node.naturalTiming.isNotEmpty
              ? node.naturalTiming
              : node.intent,
        ),
      );
    });
    unawaited(_saveActiveSession());
    _scrollToBottom();
    unawaited(_speakAssistant(question));
  }

  void _prewarmQuestionSession() {
    unawaited(
      _llmScheduler.ensureSession().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          '[InterviewPracticePage] question session prewarm failed: $error',
        );
      }),
    );
  }

  int _resetPlanForManualSceneJump(
    InterviewPracticeSession session,
    InterviewExpressionNode node,
  ) {
    final InterviewSceneGraph? sceneGraph = _sceneGraph;
    final List<String> levelNodeIds =
        sceneGraph
            ?.flowNodeIdsForLevel(session.targetLevel)
            .where((String id) => id != 'wrap_up')
            .toList(growable: false) ??
        const <String>[];
    final int flowIndex = levelNodeIds.indexOf(node.id);
    if (sceneGraph != null && flowIndex >= 0) {
      final List<String> continuation = levelNodeIds.sublist(flowIndex);
      session.plannedStages = <String>[...continuation, 'wrap_up'];
      for (final String nodeId in continuation) {
        final InterviewExpressionNode? graphNode = sceneGraph.nodeById(nodeId);
        if (graphNode != null) {
          session.stageExpressionTargets[nodeId] = graphNode.toExpression();
        }
      }
      return 0;
    }
    int targetIndex = session.plannedStages.indexOf(node.id);
    if (targetIndex < 0) {
      final int wrapUpIndex = session.plannedStages.indexOf('wrap_up');
      targetIndex = wrapUpIndex >= 0
          ? wrapUpIndex
          : session.plannedStages.length;
      session.plannedStages.insert(targetIndex, node.id);
    }
    return targetIndex;
  }

  Set<String> _masteredNodeIds(InterviewPracticeSession session) {
    return <String>{
      ...session.masteredExpressionIds,
      ..._wikiStore.loadMasteredExpressions().map(
        (InterviewPersonalWikiExpression item) => item.sourceNodeId.isNotEmpty
            ? item.sourceNodeId
            : item.sourceExpressionId,
      ),
    }.where((String id) => id.trim().isNotEmpty).toSet();
  }

  Set<String> _dueNodeIds() {
    final DateTime now = DateTime.now();
    return _wikiStore
        .loadMasteredExpressions()
        .where(
          (InterviewPersonalWikiExpression item) =>
              !item.nextReviewAt.isAfter(now),
        )
        .map(
          (InterviewPersonalWikiExpression item) => item.sourceNodeId.isNotEmpty
              ? item.sourceNodeId
              : item.sourceExpressionId,
        )
        .where((String id) => id.trim().isNotEmpty)
        .toSet();
  }

  Set<String> _preparedNodeIds(InterviewPracticeSession session) {
    return _wikiStore
        .loadExpressionLearningProgress(sourceSceneId: session.publicSceneId)
        .where((InterviewExpressionLearningProgress item) => item.isPrepared)
        .map((InterviewExpressionLearningProgress item) => item.nodeId)
        .where((String id) => id.trim().isNotEmpty)
        .toSet();
  }

  Set<String> _weakNodeIds(InterviewPracticeSession session) {
    return _wikiStore
        .loadUserGrowthWiki()
        .weakExpressions
        .where(
          (InterviewWeakExpressionState item) =>
              item.sourceSceneId == session.publicSceneId,
        )
        .map((InterviewWeakExpressionState item) => item.sourceNodeId)
        .where((String id) => id.trim().isNotEmpty)
        .toSet();
  }

  Map<String, _SceneNodePracticeStats> _practiceStatsByNode(
    InterviewPracticeSession session,
  ) {
    final InterviewUserGrowthWiki growthWiki = _wikiStore.loadUserGrowthWiki();
    final String sceneId = session.publicSceneId.trim().isEmpty
        ? widget.sceneId
        : session.publicSceneId.trim();
    final Map<String, _SceneNodePracticeStats> stats =
        <String, _SceneNodePracticeStats>{};
    for (final InterviewLearningEvidenceRef evidence
        in growthWiki.evidenceRefs) {
      if (evidence.sourceSceneId != sceneId) {
        continue;
      }
      final String nodeId = evidence.sourceNodeId.trim().isEmpty
          ? evidence.stage.trim()
          : evidence.sourceNodeId.trim();
      if (nodeId.isEmpty) {
        continue;
      }
      final _SceneNodePracticeStats current =
          stats[nodeId] ?? _SceneNodePracticeStats.empty;
      stats[nodeId] = current.copyWith(
        attempts: current.attempts + 1,
        bestScore: evidence.type == 'voice_score' && evidence.score > 0
            ? math.max(current.bestScore, evidence.score)
            : current.bestScore,
      );
    }
    for (final InterviewWeakExpressionState weak
        in growthWiki.weakExpressions) {
      if (weak.sourceSceneId != sceneId) {
        continue;
      }
      final String nodeId = weak.sourceNodeId.trim().isEmpty
          ? weak.sourceExpressionId.trim()
          : weak.sourceNodeId.trim();
      if (nodeId.isEmpty || weak.attempts <= 0) {
        continue;
      }
      final _SceneNodePracticeStats current =
          stats[nodeId] ?? _SceneNodePracticeStats.empty;
      stats[nodeId] = current.copyWith(
        attempts: math.max(current.attempts, weak.attempts),
      );
    }
    for (final InterviewChatMessage message in _messages) {
      if (message.role != 'user' || !message.isVoice) {
        continue;
      }
      final int? score = _voiceCompositeScore(
        grammarScore: message.grammarScore,
        pronunciationScore: message.pronunciationScore,
      );
      if (score == null) {
        continue;
      }
      final String nodeId =
          message.targetExpression?.id.trim().isNotEmpty == true
          ? message.targetExpression!.id.trim()
          : session.stageExpressionTargets[message.stage]?.id
                    .trim()
                    .isNotEmpty ==
                true
          ? session.stageExpressionTargets[message.stage]!.id.trim()
          : message.stage.trim();
      if (nodeId.isEmpty) {
        continue;
      }
      final _SceneNodePracticeStats current =
          stats[nodeId] ?? _SceneNodePracticeStats.empty;
      stats[nodeId] = current.copyWith(
        bestScore: math.max(current.bestScore, score.toDouble()),
      );
    }
    return Map<String, _SceneNodePracticeStats>.unmodifiable(stats);
  }

  int? _voiceCompositeScore({int? grammarScore, int? pronunciationScore}) {
    final List<int> scores = <int>[
      if (grammarScore != null) grammarScore.clamp(0, 100),
      if (pronunciationScore != null) pronunciationScore.clamp(0, 100),
    ];
    if (scores.isEmpty) {
      return null;
    }
    return (scores.reduce((int a, int b) => a + b) / scores.length).round();
  }

  String _manualSceneJumpQuestion(InterviewExpressionNode node) {
    final ExpressionSceneOrchestrator orchestrator =
        const ExpressionSceneOrchestrator();
    return orchestrator.fallbackQuestionFor(
      ExpressionSceneNode.fromInterviewNode(node),
      openingType: ExpressionSceneOpeningType.manualJump,
    );
  }

  // ignore: unused_element
  _InterviewTargetContext _targetContextFor(InterviewPracticeSession session) {
    final InterviewSceneGraph? sceneGraph = _sceneGraph;
    final InterviewExpressionNode? node = sceneGraph?.nodeById(
      session.currentStage,
    );
    final InterviewExpression? target =
        session.stageExpressionTargets[session.currentStage] ??
        node?.toExpression();
    final String title = node?.stageLabel.trim().isNotEmpty == true
        ? node!.stageLabel
        : target?.section.trim().isNotEmpty == true
        ? target!.section
        : stageLabels[session.currentStage] ?? session.currentStage;
    final String sceneTitle = sceneGraph?.titleCn.trim().isNotEmpty == true
        ? sceneGraph!.titleCn
        : session.publicSceneId;
    final int index = session.plannedStages.indexOf(session.currentStage);
    final int position = index < 0 ? session.stageIndex + 1 : index + 1;
    final String targetText = node?.targetText.trim().isNotEmpty == true
        ? node!.targetText
        : target?.text ?? '';
    final String intent = node?.intent.trim().isNotEmpty == true
        ? node!.intent
        : target?.useCase ?? '引导你自然复现当前场景表达。';
    final Set<String> masteredIds = _masteredNodeIds(session);
    final InterviewUserGrowthWiki growthWiki = _wikiStore.loadUserGrowthWiki();
    final InterviewCompiledWiki compiledWiki = _wikiStore.loadCompiledWiki();
    final DateTime now = DateTime.now();
    InterviewPersonalWikiExpression? dueExpression;
    for (final InterviewPersonalWikiExpression item
        in _wikiStore.loadMasteredExpressions()) {
      final String id = item.sourceNodeId.isNotEmpty
          ? item.sourceNodeId
          : item.sourceExpressionId;
      if (id == session.currentStage && !item.nextReviewAt.isAfter(now)) {
        dueExpression = item;
        break;
      }
    }
    InterviewWeakExpressionState? weakExpression;
    for (final InterviewWeakExpressionState item
        in growthWiki.weakExpressions) {
      if (item.sourceSceneId == session.publicSceneId &&
          item.sourceNodeId == session.currentStage) {
        weakExpression = item;
        break;
      }
    }
    final String personalNote = _personalNoteForTarget(
      mastered: masteredIds.contains(session.currentStage),
      dueExpression: dueExpression,
      weakExpression: weakExpression,
      growthWiki: growthWiki,
      compiledWiki: compiledWiki,
    );
    return _InterviewTargetContext(
      sceneTitle: sceneTitle,
      title: title,
      headerTitle:
          '$sceneTitle · $title ($position/${session.plannedStages.length})',
      node: node,
      targetExpression: target,
      targetText: targetText,
      intent: intent,
      hintLevel: session.stageHintLevels[session.currentStage] ?? '',
      attempts: session.stageAttempts[session.currentStage] ?? 0,
      mastered: masteredIds.contains(session.currentStage),
      due: dueExpression != null,
      weakExpression: weakExpression,
      personalNote: personalNote,
      previousNodes:
          node?.previousIds
              .map((String id) => sceneGraph?.nodeById(id))
              .nonNulls
              .toList(growable: false) ??
          const <InterviewExpressionNode>[],
    );
  }

  String _personalNoteForTarget({
    required bool mastered,
    required InterviewPersonalWikiExpression? dueExpression,
    required InterviewWeakExpressionState? weakExpression,
    required InterviewUserGrowthWiki growthWiki,
    required InterviewCompiledWiki compiledWiki,
  }) {
    if (weakExpression != null && weakExpression.reason.trim().isNotEmpty) {
      return '个人 Wiki：${weakExpression.reason.trim()}';
    }
    if (dueExpression != null) {
      return '个人 Wiki：这句已到期，优先自然复现一次。';
    }
    if (mastered) {
      return '个人 Wiki：这句已掌握，可以试着说得更轻松。';
    }
    if (growthWiki.profileSummary.trim().isNotEmpty) {
      return '个人 Wiki：${growthWiki.profileSummary.trim()}';
    }
    if (compiledWiki.summary.trim().isNotEmpty) {
      return '个人 Wiki：${compiledWiki.summary.trim()}';
    }
    return '个人 Wiki：先把目标表达自然放进下一句回答。';
  }

  Widget _buildComposer(InterviewPracticeSession session) {
    final bool ended = _review != null;
    final int hintRemaining = _remainingHintsForCurrentQuestion();
    final _ComposerHintData? activeHint = _activeComposerHintFor(session);
    final bool canRevealNextGeneratedHint =
        _activeComposerHintIndex >= 0 &&
        _activeComposerHintIndex < _composerHintStack.length - 1;
    final bool voiceEnabled =
        !ended &&
        !_submitting &&
        !_transcribing &&
        !_finishingReview &&
        !_hintThinking;
    final bool hintEnabled =
        !ended &&
        !_submitting &&
        !_finishingReview &&
        !_hintThinking &&
        (hintRemaining > 0 || canRevealNextGeneratedHint);
    final double bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 11, 14, 10 + bottomSafeArea * 0.45),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFCF9),
        border: Border(top: BorderSide(color: Color(0xFFE9E7E0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: activeHint == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey<String>(
                      'composer_hint_${activeHint.stage}_${activeHint.level}_${activeHint.createdAt.millisecondsSinceEpoch}',
                    ),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ComposerHintPopup(
                      hint: activeHint,
                      hasPrevious: _activeComposerHintIndex > 0,
                      previousLevel: _activeComposerHintIndex > 0
                          ? _composerHintStack[_activeComposerHintIndex - 1]
                                .level
                          : '',
                      onPrevious: _showPreviousComposerHint,
                      onClose: _dismissComposerHint,
                    ),
                  ),
          ),
          _VoiceInputPanel(
            enabled: voiceEnabled,
            hintEnabled: hintEnabled,
            recording: _recording,
            transcribing: _transcribing,
            elapsed: _recordingElapsed,
            hintRemaining: hintRemaining,
            onStart: () => unawaited(_startVoiceRecording()),
            onCancel: () => unawaited(_finishVoiceRecording(cancel: true)),
            onSend: () => unawaited(_finishVoiceRecording(cancel: false)),
            onHint: () => unawaited(_requestHint()),
          ),
        ],
      ),
    );
  }

  int _remainingHintsForCurrentQuestion() {
    final InterviewPracticeSession? session = _session;
    int latestQuestionIndex = -1;
    for (int index = _messages.length - 1; index >= 0; index -= 1) {
      final InterviewChatMessage message = _messages[index];
      if (message.role == 'assistant' &&
          !message.isHint &&
          !message.isAlignment &&
          !message.isMastered) {
        latestQuestionIndex = index;
        break;
      }
    }
    int usedByCurrentStage = 0;
    if (session != null) {
      usedByCurrentStage = math.max(
        usedByCurrentStage,
        _hintLevelUsedCount(session.stageHintLevels[session.currentStage]),
      );
      if (_composerHintStage == session.currentStage) {
        usedByCurrentStage = math.max(
          usedByCurrentStage,
          _composerHintStack.length,
        );
      }
    }
    if (latestQuestionIndex < 0) {
      return (4 - usedByCurrentStage).clamp(0, 4).toInt();
    }
    int usedHints = 0;
    for (
      int index = latestQuestionIndex + 1;
      index < _messages.length;
      index += 1
    ) {
      final InterviewChatMessage message = _messages[index];
      if (message.role == 'assistant' && message.isHint) {
        usedHints += 1;
      }
    }
    usedHints = math.max(usedHints, usedByCurrentStage);
    return (4 - usedHints).clamp(0, 4).toInt();
  }

  int _hintLevelUsedCount(String? level) {
    return switch (level) {
      'L1' => 1,
      'L2' => 2,
      'L3' => 3,
      'L4' => 4,
      _ => 0,
    };
  }

  double _sceneStageProgressFor(InterviewPracticeSession session) {
    final InterviewSceneGraph? sceneGraph = _sceneGraph;
    List<String> stageIds =
        sceneGraph
            ?.flowNodeIdsForLevel(session.targetLevel)
            .where((String id) => id != 'wrap_up')
            .toList(growable: false) ??
        const <String>[];
    if (stageIds.isEmpty) {
      stageIds = session.plannedStages
          .where((String id) => id != 'wrap_up')
          .toList(growable: false);
    }
    if (stageIds.isEmpty) {
      return 0;
    }
    int currentIndex = stageIds.indexOf(session.currentStage);
    if (currentIndex < 0) {
      currentIndex = session.stageIndex.clamp(0, stageIds.length - 1).toInt();
    }
    return ((currentIndex + 1) / stageIds.length).clamp(0.0, 1.0);
  }
}

class _ComposerHintData {
  const _ComposerHintData({
    required this.stage,
    required this.level,
    required this.tag,
    required this.text,
    required this.createdAt,
  });

  final String stage;
  final String level;
  final String tag;
  final String text;
  final DateTime createdAt;
}

class _ComposerHintPopup extends StatelessWidget {
  const _ComposerHintPopup({
    required this.hint,
    required this.hasPrevious,
    required this.previousLevel,
    required this.onPrevious,
    required this.onClose,
  });

  final _ComposerHintData hint;
  final bool hasPrevious;
  final String previousLevel;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final Color levelColor = _hintLevelColor(hint.level);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(13, 11, 9, 11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E0D6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _hintLevelLabel(hint.level),
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 11.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (hint.tag.trim().isNotEmpty) ...[
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      hint.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (hasPrevious)
                  InkWell(
                    onTap: onPrevious,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4EC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.keyboard_arrow_left_rounded,
                            size: 15,
                            color: darkGreen,
                          ),
                          Text(
                            '返回 ${previousLevel.isEmpty ? '上一层' : previousLevel}',
                            style: const TextStyle(
                              color: darkGreen,
                              fontSize: 11.5,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 5),
                IconButton(
                  tooltip: '关闭提示',
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              hint.text,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 14,
                height: 1.38,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '继续点灯泡会进入下一层提示',
              style: TextStyle(
                color: textTertiary,
                fontSize: 11.5,
                height: 1.15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceInputPanel extends StatelessWidget {
  const _VoiceInputPanel({
    required this.enabled,
    required this.hintEnabled,
    required this.recording,
    required this.transcribing,
    required this.elapsed,
    required this.hintRemaining,
    required this.onStart,
    required this.onCancel,
    required this.onSend,
    required this.onHint,
  });

  final bool enabled;
  final bool hintEnabled;
  final bool recording;
  final bool transcribing;
  final Duration elapsed;
  final int hintRemaining;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: recording
          ? _RecordingVoiceControls(
              key: const ValueKey<String>('interview_voice_recording_controls'),
              elapsed: elapsed,
              onCancel: onCancel,
              onSend: onSend,
            )
          : _IdleVoiceControls(
              key: const ValueKey<String>('interview_voice_idle_controls'),
              enabled: enabled,
              hintEnabled: hintEnabled,
              transcribing: transcribing,
              hintRemaining: hintRemaining,
              onStart: onStart,
              onHint: onHint,
            ),
    );
  }
}

class _IdleVoiceControls extends StatelessWidget {
  const _IdleVoiceControls({
    super.key,
    required this.enabled,
    required this.hintEnabled,
    required this.transcribing,
    required this.hintRemaining,
    required this.onStart,
    required this.onHint,
  });

  final bool enabled;
  final bool hintEnabled;
  final bool transcribing;
  final int hintRemaining;
  final VoidCallback onStart;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final bool canStart = enabled && !transcribing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const ValueKey<String>('interview_voice_start_button'),
                  onTap: canStart ? onStart : null,
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    height: 56,
                    decoration: BoxDecoration(
                      color: canStart
                          ? const Color(0xFFE6F2CE)
                          : const Color(0xFFECE7DF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: canStart
                            ? const Color(0xFFD4E7AE)
                            : const Color(0xFFE0DCD3),
                      ),
                      boxShadow: canStart
                          ? const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          transcribing
                              ? Icons.graphic_eq_rounded
                              : Icons.multitrack_audio_rounded,
                          size: 22,
                          color: canStart ? textPrimary : textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          transcribing ? '正在识别...' : '点击说话',
                          style: _composerPrimaryTextStyle.copyWith(
                            color: canStart ? textPrimary : textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _VoiceIconButton(
              key: const ValueKey<String>('interview_hint_button'),
              enabled: hintEnabled,
              backgroundColor: const Color(0xFFF2F4EC),
              foregroundColor: const Color(0xFF4E5B48),
              icon: Icons.lightbulb_rounded,
              badgeText: '$hintRemaining',
              onTap: onHint,
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('内容由 AI 生成', style: _composerCaptionStyle),
      ],
    );
  }
}

class _RecordingVoiceControls extends StatelessWidget {
  const _RecordingVoiceControls({
    super.key,
    required this.elapsed,
    required this.onCancel,
    required this.onSend,
  });

  final Duration elapsed;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _VoiceIconButton(
              key: const ValueKey<String>('interview_voice_cancel_button'),
              enabled: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              icon: Icons.close_rounded,
              circular: true,
              onTap: onCancel,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedContainer(
                key: const ValueKey<String>('interview_voice_recording_bar'),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F9E9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD3E7B2)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _VoiceWaveform(elapsed: elapsed),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '正在录音',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatRecordingDuration(elapsed),
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _VoiceIconButton(
              key: const ValueKey<String>('interview_voice_send_button'),
              enabled: true,
              backgroundColor: const Color(0xFFE6F2CE),
              foregroundColor: Colors.black,
              icon: Icons.near_me_rounded,
              circular: true,
              onTap: onSend,
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('内容由 AI 生成', style: _composerCaptionStyle),
      ],
    );
  }
}

class _VoiceIconButton extends StatelessWidget {
  const _VoiceIconButton({
    super.key,
    required this.enabled,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    this.circular = false,
    this.badgeText,
    required this.onTap,
  });

  final bool enabled;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final bool circular;
  final String? badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(circular ? 999 : 18),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: enabled ? backgroundColor : const Color(0xFFECE7DF),
                shape: circular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: circular ? null : BorderRadius.circular(18),
                boxShadow: enabled
                    ? const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 27,
                color: enabled ? foregroundColor : textTertiary,
              ),
            ),
            if (badgeText != null && badgeText!.isNotEmpty)
              Positioned(
                top: -6,
                right: -4,
                child: _HintRemainingBadge(text: badgeText!, enabled: enabled),
              ),
          ],
        ),
      ),
    );
  }
}

class _HintRemainingBadge extends StatelessWidget {
  const _HintRemainingBadge({required this.text, required this.enabled});

  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('interview_hint_remaining_badge'),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFE6493F) : const Color(0xFFC9C1B7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _VoiceWaveform extends StatelessWidget {
  const _VoiceWaveform({required this.elapsed});

  final Duration elapsed;

  static const List<double> _bars = <double>[18, 27, 35, 25, 31, 22, 14];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _bars.length; i += 1)
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              width: 6,
              height: _bars[(i + elapsed.inSeconds) % _bars.length],
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _bars.length - 1
                    ? const Color(0xFFCBEF7B)
                    : const Color(0xFF78CE52),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatRecordingDuration(Duration duration) {
  final int minutes = duration.inMinutes;
  final int seconds = duration.inSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class _TopConversationProgress extends StatelessWidget {
  const _TopConversationProgress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: const LinearProgressIndicator(
        minHeight: 2,
        backgroundColor: Color(0xFFECE7DF),
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDDF8A6)),
      ),
    );
  }
}

class _TopTargetProgressBand extends StatelessWidget {
  const _TopTargetProgressBand({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return _TargetSparkBand(
      key: const ValueKey<String>('interview_target_progress_band'),
      progress: progress,
    );
  }
}

String _practiceFocusShortLabel(InterviewNextRoundMode mode) {
  return switch (mode) {
    InterviewNextRoundMode.review => '到期复习',
    InterviewNextRoundMode.newLesson => '新表达拓展',
  };
}

String _practiceFocusDescription(InterviewNextRoundMode mode) {
  return switch (mode) {
    InterviewNextRoundMode.review => '系统根据遗忘曲线挑选到期表达，本轮优先放进自然面试语境里复现。',
    InterviewNextRoundMode.newLesson => '当前没有明显到期表达，本轮优先引入新的地道说法，并穿插轻量复用。',
  };
}

String _reviewDueText(InterviewReview review) {
  if (review.dueReviewCount > 0) {
    return '${review.dueReviewCount} 个表达已到期';
  }
  final DateTime? nextDueAt = review.nextDueReviewAt;
  if (nextDueAt == null) {
    return '暂无到期表达';
  }
  final int rawDays = nextDueAt.difference(DateTime.now()).inDays;
  final int days = rawDays < 0 ? 0 : rawDays.clamp(0, 365).toInt();
  if (days == 0) {
    return '下一批今天到期';
  }
  if (days == 1) {
    return '下一批明天到期';
  }
  return '下一批 $days 天后到期';
}

class _InterviewTargetContext {
  const _InterviewTargetContext({
    required this.sceneTitle,
    required this.title,
    required this.headerTitle,
    required this.node,
    required this.targetExpression,
    required this.targetText,
    required this.intent,
    required this.hintLevel,
    required this.attempts,
    required this.mastered,
    required this.due,
    required this.weakExpression,
    required this.personalNote,
    required this.previousNodes,
  });

  final String sceneTitle;
  final String title;
  final String headerTitle;
  final InterviewExpressionNode? node;
  final InterviewExpression? targetExpression;
  final String targetText;
  final String intent;
  final String hintLevel;
  final int attempts;
  final bool mastered;
  final bool due;
  final InterviewWeakExpressionState? weakExpression;
  final String personalNote;
  final List<InterviewExpressionNode> previousNodes;

  String get stateLabel {
    if (mastered) {
      return '已复现';
    }
    if (hintLevel.isNotEmpty) {
      return _hintLevelLabel(hintLevel);
    }
    if (attempts > 0) {
      return '$attempts 次尝试';
    }
    return '待复现';
  }

  Color get stateColor {
    if (mastered) {
      return darkGreen;
    }
    if (hintLevel.isNotEmpty) {
      return _hintLevelColor(hintLevel);
    }
    if (attempts > 0) {
      return const Color(0xFF5A6FA8);
    }
    return textSecondary;
  }
}

// ignore: unused_element
class _CoachDrawer extends StatelessWidget {
  const _CoachDrawer({
    required this.extent,
    required this.target,
    required this.onExtentChanged,
    required this.onRequestHint,
    required this.onOpenWiki,
  });

  static const double collapsedExtent = 0.08;
  static const double coreExtent = 0.40;
  static const double expandedExtent = 0.50;

  final double extent;
  final _InterviewTargetContext target;
  final ValueChanged<double> onExtentChanged;
  final VoidCallback onRequestHint;
  final VoidCallback onOpenWiki;

  bool get _expanded => extent > collapsedExtent;
  bool get _fullyExpanded => extent >= expandedExtent;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double height = _expanded ? screenHeight * extent : 54;
    return GestureDetector(
      onTap: () {
        if (!_expanded) {
          onExtentChanged(coreExtent);
        }
      },
      onVerticalDragEnd: (DragEndDetails details) {
        final double velocity = details.primaryVelocity ?? 0;
        if (velocity < -80) {
          onExtentChanged(extent >= coreExtent ? expandedExtent : coreExtent);
          return;
        }
        if (velocity > 80) {
          onExtentChanged(_fullyExpanded ? coreExtent : collapsedExtent);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: height,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xF7FFFFFF),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            _CoachDrawerHandleHeader(
              target: target,
              expanded: _expanded,
              onToggle: () {
                onExtentChanged(_expanded ? collapsedExtent : coreExtent);
              },
            ),
            if (_expanded)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TargetExpressionPanel(target: target),
                      const SizedBox(height: 10),
                      _HintLadder(
                        currentLevel: target.hintLevel,
                        compact: !_fullyExpanded,
                        node: target.node,
                      ),
                      const SizedBox(height: 10),
                      _PersonalWikiNotice(target: target),
                      if (_fullyExpanded) ...[
                        const SizedBox(height: 10),
                        _TargetDetailPanel(target: target),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: onRequestHint,
                            icon: const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 17,
                            ),
                            label: const Text('要一个提示'),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: onOpenWiki,
                            icon: const Icon(
                              Icons.menu_book_outlined,
                              size: 17,
                            ),
                            label: const Text('完整个人 Wiki'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CoachDrawerHandleHeader extends StatelessWidget {
  const _CoachDrawerHandleHeader({
    required this.target,
    required this.expanded,
    required this.onToggle,
  });

  final _InterviewTargetContext target;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D2C8),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: darkGreen,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '当前目标：${target.targetText.isEmpty ? target.title : target.targetText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _TinyBadge(label: target.stateLabel, color: target.stateColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetExpressionPanel extends StatelessWidget {
  const _TargetExpressionPanel({required this.target});

  final _InterviewTargetContext target;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.track_changes_rounded,
                size: 17,
                color: darkGreen,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  target.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
              ),
              if (target.due)
                const _TinyBadge(label: '到期', color: Color(0xFFA0622A))
              else if (target.mastered)
                const _TinyBadge(label: '已掌握', color: darkGreen),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            target.targetText.isEmpty ? '当前节点暂无目标句' : target.targetText,
            style: const TextStyle(
              fontSize: 17,
              height: 1.25,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            target.intent,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalWikiNotice extends StatelessWidget {
  const _PersonalWikiNotice({required this.target});

  final _InterviewTargetContext target;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5EA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_stories_outlined, size: 17, color: darkGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              target.personalNote,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintLadder extends StatelessWidget {
  const _HintLadder({
    required this.currentLevel,
    required this.compact,
    required this.node,
  });

  final String currentLevel;
  final bool compact;
  final InterviewExpressionNode? node;

  @override
  Widget build(BuildContext context) {
    const List<String> levels = <String>['L1', 'L2', 'L3', 'L4'];
    final Iterable<String> visibleLevels = compact && currentLevel.isNotEmpty
        ? levels.where((String level) => level == currentLevel)
        : levels;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '提示阶梯',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final String level in visibleLevels)
            _HintStep(
              level: level,
              text: _hintTextForLevel(node, level),
              active: currentLevel == level,
            ),
          if (compact && currentLevel.isEmpty)
            const Text(
              '还没有使用提示。需要时点“我卡住了”，系统会自动推进 L1-L4。',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
        ],
      ),
    );
  }

  static String _hintTextForLevel(InterviewExpressionNode? node, String level) {
    final String text = node?.hintForLevel(level).trim() ?? '';
    if (text.isNotEmpty) {
      return text;
    }
    return switch (level) {
      'L1' => '轻轻提示回答方向',
      'L2' => '给出结构骨架',
      'L3' => '提供填空式表达',
      'L4' => '给出完整可复述回答',
      _ => '',
    };
  }
}

class _HintStep extends StatelessWidget {
  const _HintStep({
    required this.level,
    required this.text,
    required this.active,
  });

  final String level;
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? _hintLevelColor(level) : textTertiary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: active ? 0.16 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Text(
              level.substring(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: active ? FontWeight.w800 : FontWeight.w400,
                color: active ? textPrimary : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetDetailPanel extends StatelessWidget {
  const _TargetDetailPanel({required this.target});

  final _InterviewTargetContext target;

  @override
  Widget build(BuildContext context) {
    final InterviewExpressionNode? node = target.node;
    final List<InterviewExpectedVariant> variants =
        node?.expectedVariants.take(4).toList(growable: false) ??
        const <InterviewExpectedVariant>[];
    final List<InterviewErrorPattern> errors =
        node?.errors.take(3).toList(growable: false) ??
        const <InterviewErrorPattern>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (target.previousNodes.isNotEmpty)
          _DetailBlock(
            title: '前置表达路径',
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: target.previousNodes
                    .map(
                      (InterviewExpressionNode item) => _TinyBadge(
                        label: item.stageLabel.isEmpty
                            ? item.id
                            : item.stageLabel,
                        color: const Color(0xFF5A6FA8),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        if (variants.isNotEmpty)
          _DetailBlock(
            title: '可接受变体',
            children: [
              for (final InterviewExpectedVariant item in variants)
                _SmallDetailLine(text: item.text),
            ],
          ),
        if (errors.isNotEmpty)
          _DetailBlock(
            title: '常见错误',
            children: [
              for (final InterviewErrorPattern item in errors)
                _SmallDetailLine(
                  text: item.reason.isEmpty
                      ? '${item.wrong} -> ${item.better}'
                      : '${item.wrong} -> ${item.better} · ${item.reason}',
                ),
            ],
          ),
      ],
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }
}

class _SmallDetailLine extends StatelessWidget {
  const _SmallDetailLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.35,
          color: textSecondary,
        ),
      ),
    );
  }
}

class _TargetSparkBand extends StatelessWidget {
  const _TargetSparkBand({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final double normalizedProgress = progress.clamp(0.0, 1.0);
    return Container(
      height: 3,
      width: double.infinity,
      color: const Color(0xFFE4E8DD),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: normalizedProgress <= 0 ? 0.03 : normalizedProgress,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[Color(0xFF87B076), darkGreen],
            ),
          ),
        ),
      ),
    );
  }
}

class _SceneMapResult {
  const _SceneMapResult.node(this.node) : targetLevel = null;

  const _SceneMapResult.targetLevel(this.targetLevel) : node = null;

  final InterviewExpressionNode? node;
  final String? targetLevel;
}

class _SceneNodePracticeStats {
  const _SceneNodePracticeStats({
    required this.attempts,
    required this.bestScore,
  });

  static const _SceneNodePracticeStats empty = _SceneNodePracticeStats(
    attempts: 0,
    bestScore: 0,
  );

  final int attempts;
  final double bestScore;

  _SceneNodePracticeStats copyWith({int? attempts, double? bestScore}) {
    return _SceneNodePracticeStats(
      attempts: attempts ?? this.attempts,
      bestScore: bestScore ?? this.bestScore,
    );
  }
}

class _SceneMapPage extends StatefulWidget {
  const _SceneMapPage({
    required this.sceneGraph,
    required this.session,
    required this.masteredNodeIds,
    required this.preparedNodeIds,
    required this.dueNodeIds,
    required this.weakNodeIds,
    required this.practiceStatsByNode,
  });

  final InterviewSceneGraph sceneGraph;
  final InterviewPracticeSession session;
  final Set<String> masteredNodeIds;
  final Set<String> preparedNodeIds;
  final Set<String> dueNodeIds;
  final Set<String> weakNodeIds;
  final Map<String, _SceneNodePracticeStats> practiceStatsByNode;

  @override
  State<_SceneMapPage> createState() => _SceneMapPageState();
}

class _SceneMapPageState extends State<_SceneMapPage> {
  late String _selectedTargetLevel;

  @override
  void initState() {
    super.initState();
    _selectedTargetLevel = _normalizeSceneMapTargetLevel(
      widget.session.targetLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final InterviewSceneGraph sceneGraph = widget.sceneGraph;
    final InterviewPracticeSession session = widget.session;
    final List<_SceneTargetLevelOption> levelOptions = _sceneTargetLevelOptions(
      sceneGraph,
    );
    final String activeTargetLevel = _normalizeSceneMapTargetLevel(
      session.targetLevel,
    );
    final String selectedTargetLevel =
        levelOptions.any(
          (_SceneTargetLevelOption option) =>
              option.targetLevel == _selectedTargetLevel,
        )
        ? _selectedTargetLevel
        : levelOptions.isEmpty
        ? activeTargetLevel
        : levelOptions.first.targetLevel;
    final bool showingActiveSessionLevel =
        selectedTargetLevel == activeTargetLevel;
    final String levelTitle = _sceneTargetLevelTitle(
      sceneGraph,
      selectedTargetLevel,
    );
    final List<String> roundNodeIds = showingActiveSessionLevel
        ? session.plannedStages
              .where((String id) => id != 'wrap_up')
              .toList(growable: false)
        : const <String>[];
    final ExpressionSceneNavigationState navigationState =
        const ExpressionSceneOrchestrator().navigationState(
          graph: ExpressionSceneGraph.fromInterviewSceneGraph(sceneGraph),
          targetLevel: selectedTargetLevel,
          currentNodeId: showingActiveSessionLevel ? session.currentStage : '',
          roundNodeIds: roundNodeIds,
          masteredNodeIds: widget.masteredNodeIds,
          preparedNodeIds: widget.preparedNodeIds,
          dueNodeIds: widget.dueNodeIds,
          weakNodeIds: widget.weakNodeIds,
        );
    final List<ExpressionSceneNavigationNodeState> nodeStates =
        navigationState.nodes;
    final Map<String, InterviewExpressionNode> interviewNodes =
        <String, InterviewExpressionNode>{
          for (final InterviewExpressionNode node in sceneGraph.nodes)
            node.id: node,
        };
    final int currentIndex = navigationState.currentPublicIndex;
    final int currentRoundIndex = navigationState.currentRoundIndex;
    final int publicTotal = navigationState.publicTotal;
    final int roundTotal = navigationState.roundTotal;
    final int masteredCount = navigationState.masteredCount;
    final bool hasCurrentNode = currentIndex >= 0;
    final int currentDisplayIndex = currentIndex < 0 ? 0 : currentIndex;
    final int currentRoundDisplayIndex = currentRoundIndex < 0
        ? 0
        : currentRoundIndex;
    final int resolvedPublicTotal = publicTotal <= 0
        ? nodeStates.length
        : publicTotal;
    final int resolvedRoundTotal = roundTotal <= 0
        ? roundNodeIds.length
        : roundTotal;
    final String publicProgressText = resolvedPublicTotal <= 0
        ? '0/0'
        : '${currentDisplayIndex + 1}/$resolvedPublicTotal';
    final String roundProgressText = resolvedRoundTotal <= 0
        ? '0/0'
        : '${currentRoundDisplayIndex + 1}/$resolvedRoundTotal';
    final bool hasRoundPlan =
        showingActiveSessionLevel && hasCurrentNode && resolvedRoundTotal > 0;
    final String progressText = hasRoundPlan
        ? '本轮 $roundProgressText · 地图 $publicProgressText'
        : '地图 ${nodeStates.length} 个表达';
    final String masteryText = '$masteredCount/$resolvedPublicTotal 已掌握';
    final String countText = '${nodeStates.length} 个表达';
    final String titleText = '${sceneGraph.titleCn} · $countText';
    final String subtitleText = hasRoundPlan
        ? '只显示当前等级表达 · $masteryText'
        : '只显示$levelTitle目标表达 · $masteryText';
    final bool empty = nodeStates.isEmpty;
    final List<Widget> nodeTiles = nodeStates
        .map((ExpressionSceneNavigationNodeState state) {
          final InterviewExpressionNode? node = interviewNodes[state.node.id];
          if (node == null) {
            return const SizedBox.shrink();
          }
          final _SceneNodePracticeStats storedStats =
              widget.practiceStatsByNode[node.id] ??
              _SceneNodePracticeStats.empty;
          return _SceneNodeTile(
            node: node,
            current: state.current,
            inRound: state.inRound,
            mastered: state.mastered,
            prepared: state.prepared,
            due: state.due,
            weak: state.weak,
            unlocked: state.unlocked || !showingActiveSessionLevel,
            attempts:
                storedStats.attempts + (session.stageAttempts[node.id] ?? 0),
            bestScore: storedStats.bestScore,
            hintLevel: session.stageHintLevels[node.id] ?? '',
            followups: session.stageFollowups[node.id] ?? 0,
            onTap: showingActiveSessionLevel
                ? () => Navigator.of(context).pop(_SceneMapResult.node(node))
                : null,
          );
        })
        .toList(growable: false);
    return Scaffold(
      key: const ValueKey<String>('interview_scene_map_page'),
      backgroundColor: appBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '场景导航',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          titleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SceneTargetLevelDropdown(
                    options: levelOptions,
                    selectedTargetLevel: selectedTargetLevel,
                    activeTargetLevel: activeTargetLevel,
                    onChanged: (String targetLevel) {
                      Navigator.of(
                        context,
                      ).pop(_SceneMapResult.targetLevel(targetLevel));
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                children: [
                  _SceneNavigationSummary(
                    sceneTitle: sceneGraph.titleCn,
                    levelTitle: levelTitle,
                    progressText: progressText,
                    subtitleText: subtitleText,
                  ),
                  const SizedBox(height: 12),
                  if (empty)
                    const _WikiEmptyState(text: '当前等级还没有可练习表达。')
                  else
                    ...nodeTiles,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneTargetLevelDropdown extends StatelessWidget {
  const _SceneTargetLevelDropdown({
    required this.options,
    required this.selectedTargetLevel,
    required this.activeTargetLevel,
    required this.onChanged,
  });

  final List<_SceneTargetLevelOption> options;
  final String selectedTargetLevel;
  final String activeTargetLevel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (options.length <= 1) {
      return const SizedBox.shrink();
    }
    final _SceneTargetLevelOption selectedOption = options.firstWhere(
      (_SceneTargetLevelOption option) =>
          option.targetLevel == selectedTargetLevel,
      orElse: () => options.first,
    );
    return PopupMenuButton<String>(
      key: const ValueKey<String>('scene_map_level_dropdown'),
      tooltip: '切换等级',
      initialValue: selectedTargetLevel,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor.withValues(alpha: 0.9)),
      ),
      onSelected: (String targetLevel) {
        if (targetLevel != selectedTargetLevel) {
          onChanged(targetLevel);
        }
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          for (final _SceneTargetLevelOption option in options)
            PopupMenuItem<String>(
              value: option.targetLevel,
              child: KeyedSubtree(
                key: ValueKey<String>('scene_map_level_${option.targetLevel}'),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        option.shortLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: option.targetLevel == selectedTargetLevel
                              ? darkGreen
                              : textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${option.title} · ${option.expressionCount} 个',
                        style: const TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (option.targetLevel == activeTargetLevel) ...[
                      const SizedBox(width: 8),
                      const _TinyBadge(label: '当前', color: darkGreen),
                    ],
                  ],
                ),
              ),
            ),
        ];
      },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF5EA),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD9E5D2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedOption.shortLabel,
              style: const TextStyle(
                fontSize: 13,
                height: 1,
                fontWeight: FontWeight.w900,
                color: darkGreen,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: darkGreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneNavigationSummary extends StatelessWidget {
  const _SceneNavigationSummary({
    required this.sceneTitle,
    required this.levelTitle,
    required this.progressText,
    required this.subtitleText,
  });

  final String sceneTitle;
  final String levelTitle;
  final String progressText;
  final String subtitleText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5EA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9E5D2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.route_rounded, color: darkGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sceneTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$levelTitle · $subtitleText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            progressText,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneTargetLevelOption {
  const _SceneTargetLevelOption({
    required this.targetLevel,
    required this.title,
    required this.expressionCount,
  });

  final String targetLevel;
  final String title;
  final int expressionCount;

  String get shortLabel {
    final String trimmedTitle = title.trim();
    if (trimmedTitle.startsWith('L1')) {
      return 'L1';
    }
    if (trimmedTitle.startsWith('L2')) {
      return 'L2';
    }
    if (trimmedTitle.startsWith('L3')) {
      return 'L3';
    }
    return switch (targetLevel) {
      'intermediate' => 'L2',
      'advanced' => 'L3',
      _ => 'L1',
    };
  }
}

List<_SceneTargetLevelOption> _sceneTargetLevelOptions(
  InterviewSceneGraph sceneGraph,
) {
  const List<String> targetLevels = <String>[
    'beginner',
    'intermediate',
    'advanced',
  ];
  final List<_SceneTargetLevelOption> options = <_SceneTargetLevelOption>[];
  for (final String targetLevel in targetLevels) {
    final InterviewSceneTrack? track = _sceneTrackForTargetLevel(
      sceneGraph,
      targetLevel,
    );
    if (track == null) {
      continue;
    }
    final int expressionCount = track.nodeIds
        .where((String id) => sceneGraph.nodeById(id) != null)
        .length;
    options.add(
      _SceneTargetLevelOption(
        targetLevel: targetLevel,
        title: track.title.isEmpty
            ? _fallbackTargetLevelTitle(targetLevel)
            : track.title,
        expressionCount: expressionCount,
      ),
    );
  }
  if (options.isNotEmpty) {
    return options;
  }
  final String fallbackLevel = _normalizeSceneMapTargetLevel('');
  return <_SceneTargetLevelOption>[
    _SceneTargetLevelOption(
      targetLevel: fallbackLevel,
      title: _fallbackTargetLevelTitle(fallbackLevel),
      expressionCount: sceneGraph.flowNodeIdsForLevel(fallbackLevel).length,
    ),
  ];
}

InterviewSceneTrack? _sceneTrackForTargetLevel(
  InterviewSceneGraph sceneGraph,
  String targetLevel,
) {
  final String normalizedLevel = _normalizeSceneMapTargetLevel(targetLevel);
  for (final InterviewSceneTrack track in sceneGraph.tracks) {
    if (track.targetLevel == normalizedLevel || track.id == normalizedLevel) {
      return track;
    }
  }
  final String trackId = switch (normalizedLevel) {
    'intermediate' => 'L2',
    'advanced' => 'L3',
    _ => 'L1',
  };
  for (final InterviewSceneTrack track in sceneGraph.tracks) {
    if (track.id == trackId) {
      return track;
    }
  }
  return null;
}

String _normalizeSceneMapTargetLevel(String targetLevel) {
  final String normalizedLevel = targetLevel.trim();
  return switch (normalizedLevel) {
    'L2' || 'intermediate' => 'intermediate',
    'L3' || 'advanced' => 'advanced',
    _ => 'beginner',
  };
}

String _sceneTargetLevelTitle(
  InterviewSceneGraph? sceneGraph,
  String targetLevel,
) {
  final String normalizedLevel = _normalizeSceneMapTargetLevel(targetLevel);
  if (sceneGraph != null) {
    for (final InterviewSceneTrack track in sceneGraph.tracks) {
      if (track.targetLevel == normalizedLevel || track.id == normalizedLevel) {
        return track.title.isEmpty
            ? _fallbackTargetLevelTitle(normalizedLevel)
            : track.title;
      }
    }
    final String trackId = switch (normalizedLevel) {
      'intermediate' => 'L2',
      'advanced' => 'L3',
      _ => 'L1',
    };
    for (final InterviewSceneTrack track in sceneGraph.tracks) {
      if (track.id == trackId) {
        return track.title.isEmpty
            ? _fallbackTargetLevelTitle(normalizedLevel)
            : track.title;
      }
    }
  }
  return _fallbackTargetLevelTitle(normalizedLevel);
}

String _fallbackTargetLevelTitle(String targetLevel) {
  return switch (targetLevel) {
    'intermediate' => 'L2 进阶',
    'advanced' => 'L3 精通',
    _ => 'L1 入门',
  };
}

class _SceneNodeTile extends StatelessWidget {
  const _SceneNodeTile({
    required this.node,
    required this.current,
    required this.inRound,
    required this.mastered,
    required this.prepared,
    required this.due,
    required this.weak,
    required this.unlocked,
    required this.attempts,
    required this.bestScore,
    required this.hintLevel,
    required this.followups,
    required this.onTap,
  });

  final InterviewExpressionNode node;
  final bool current;
  final bool inRound;
  final bool mastered;
  final bool prepared;
  final bool due;
  final bool weak;
  final bool unlocked;
  final int attempts;
  final double bestScore;
  final String hintLevel;
  final int followups;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool jumpable = onTap != null;
    final bool enabled =
        current ||
        inRound ||
        mastered ||
        prepared ||
        due ||
        weak ||
        jumpable ||
        unlocked;
    final _SceneNodeStatusView status = _sceneNodeStatusView(
      current: current,
      inRound: inRound,
      mastered: mastered,
      prepared: prepared,
      due: due,
      weak: weak,
      jumpable: jumpable,
      unlocked: unlocked,
      attempts: attempts,
      bestScore: bestScore,
      hintLevel: hintLevel,
    );
    final List<String> metaLabels = <String>[
      if (attempts > 0) '已练 $attempts 次',
      if (bestScore > 0) '最高 ${bestScore.round().clamp(1, 100)}分',
      if (hintLevel.trim().isNotEmpty) _hintLevelLabel(hintLevel),
      if (followups > 0) '追问 $followups 次',
    ];
    final String title = node.stageLabel.trim().isEmpty
        ? node.id
        : node.stageLabel.trim();
    final String targetText = node.targetText.trim().isEmpty
        ? node.intent.trim()
        : node.targetText.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: current
                ? const Color(0xFFEEF5EA)
                : enabled
                ? Colors.white
                : const Color(0xFFF4F1EC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: current ? darkGreen : borderColor,
              width: current ? 1.2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(status.icon, size: 16, color: status.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.28,
                              fontWeight: FontWeight.w900,
                              color: enabled ? textPrimary : textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TinyBadge(label: status.label, color: status.color),
                      ],
                    ),
                    if (targetText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        targetText,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: enabled ? textSecondary : textTertiary,
                        ),
                      ),
                    ],
                    if (metaLabels.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final String label in metaLabels)
                            _SceneNodeMetaChip(label: label),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneNodeStatusView {
  const _SceneNodeStatusView({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class _SceneNodeMetaChip extends StatelessWidget {
  const _SceneNodeMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          height: 1,
          fontWeight: FontWeight.w700,
          color: textSecondary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

_SceneNodeStatusView _sceneNodeStatusView({
  required bool current,
  required bool inRound,
  required bool mastered,
  required bool prepared,
  required bool due,
  required bool weak,
  required bool jumpable,
  required bool unlocked,
  required int attempts,
  required double bestScore,
  required String hintLevel,
}) {
  const Color blue = Color(0xFF4E659C);
  const Color amber = Color(0xFFA0622A);
  const Color slate = Color(0xFF667085);
  if (current) {
    return const _SceneNodeStatusView(
      label: '当前练习',
      color: darkGreen,
      icon: Icons.play_arrow_rounded,
    );
  }
  if (due) {
    return const _SceneNodeStatusView(
      label: '待复习',
      color: amber,
      icon: Icons.history_rounded,
    );
  }
  if (weak) {
    return const _SceneNodeStatusView(
      label: '薄弱待补',
      color: amber,
      icon: Icons.tips_and_updates_outlined,
    );
  }
  if (mastered) {
    return const _SceneNodeStatusView(
      label: '已掌握',
      color: darkGreen,
      icon: Icons.check_rounded,
    );
  }
  if (prepared) {
    return const _SceneNodeStatusView(
      label: '已热身',
      color: Color(0xFF5A6FA8),
      icon: Icons.bookmark_added_rounded,
    );
  }
  if (attempts > 0 && bestScore >= 80) {
    return const _SceneNodeStatusView(
      label: '接近达标',
      color: Color(0xFF6F8E63),
      icon: Icons.trending_up_rounded,
    );
  }
  if (attempts > 0 && hintLevel.trim().isNotEmpty) {
    return const _SceneNodeStatusView(
      label: '提示中',
      color: amber,
      icon: Icons.lightbulb_outline_rounded,
    );
  }
  if (attempts > 0) {
    return const _SceneNodeStatusView(
      label: '练习中',
      color: blue,
      icon: Icons.more_horiz_rounded,
    );
  }
  if (inRound) {
    return const _SceneNodeStatusView(
      label: '本轮待练',
      color: blue,
      icon: Icons.radio_button_unchecked_rounded,
    );
  }
  if (jumpable || unlocked) {
    return const _SceneNodeStatusView(
      label: '可练习',
      color: slate,
      icon: Icons.arrow_forward_rounded,
    );
  }
  return const _SceneNodeStatusView(
    label: '未解锁',
    color: textTertiary,
    icon: Icons.lock_outline_rounded,
  );
}

String _hintLevelLabel(String level) {
  return switch (level) {
    'L1' => 'L1 轻提示',
    'L2' => 'L2 结构',
    'L3' => 'L3 填空',
    'L4' => 'L4 完整回答',
    _ => level,
  };
}

Color _hintLevelColor(String level) {
  return switch (level) {
    'L1' => const Color(0xFF6F8E63),
    'L2' => const Color(0xFF5A6FA8),
    'L3' => const Color(0xFFA0622A),
    'L4' => const Color(0xFF8B4A40),
    _ => textSecondary,
  };
}

class _InterviewWikiStateSheet extends StatelessWidget {
  const _InterviewWikiStateSheet({
    required this.session,
    required this.sceneGraph,
    required this.library,
    required this.actionPlan,
    required this.compiledWiki,
    required this.growthWiki,
    required this.masteredExpressions,
    required this.dueExpressions,
    required this.weakExpressions,
    required this.errorPatterns,
    required this.currentNode,
    required this.review,
    required this.onDismissAction,
    required this.onMarkUseful,
  });

  final InterviewPracticeSession session;
  final InterviewSceneGraph? sceneGraph;
  final InterviewLibrary? library;
  final InterviewWikiActionPlan actionPlan;
  final InterviewCompiledWiki compiledWiki;
  final InterviewUserGrowthWiki growthWiki;
  final List<InterviewPersonalWikiExpression> masteredExpressions;
  final List<InterviewPersonalWikiExpression> dueExpressions;
  final List<InterviewWeakExpressionState> weakExpressions;
  final List<InterviewUserErrorPattern> errorPatterns;
  final InterviewExpressionNode? currentNode;
  final InterviewReview? review;
  final Future<void> Function(String id) onDismissAction;
  final Future<void> Function(String id) onMarkUseful;

  @override
  Widget build(BuildContext context) {
    final int totalCount =
        library?.expressions.length ?? sceneGraph?.nodes.length ?? 0;
    final Set<String> masteredIds = masteredExpressions
        .map(
          (InterviewPersonalWikiExpression item) => item.sourceNodeId.isNotEmpty
              ? item.sourceNodeId
              : item.sourceExpressionId,
        )
        .where((String id) => id.trim().isNotEmpty)
        .toSet();
    final bool currentMastered =
        currentNode != null && masteredIds.contains(currentNode!.id);
    final String hintLevel =
        session.stageHintLevels[session.currentStage] ?? '';
    final int attempts = session.stageAttempts[session.currentStage] ?? 0;
    final String currentState = currentMastered
        ? '当前目标已复现'
        : hintLevel.isNotEmpty
        ? '当前目标依赖 $hintLevel'
        : attempts > 0
        ? '当前目标尝试中'
        : '当前目标待复现';
    final String nextFocus = dueExpressions.isNotEmpty
        ? '下一轮优先复习 ${dueExpressions.length} 个到期表达'
        : _practiceFocusDescription(session.roundMode);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: DefaultTabController(
          length: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_outlined, color: darkGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${sceneGraph?.titleCn ?? session.publicSceneId} · 个人 Wiki',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        _TinyBadge(
                          label: _practiceFocusShortLabel(session.roundMode),
                          color:
                              session.roundMode == InterviewNextRoundMode.review
                              ? const Color(0xFFA0622A)
                              : darkGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _WikiSummaryTile(
                          label: '本轮学会',
                          value: '${session.roundMasteredExpressionIds.length}',
                        ),
                        _WikiSummaryTile(
                          label: '总掌握',
                          value: '${masteredIds.length}/$totalCount',
                        ),
                        _WikiSummaryTile(
                          label: '到期',
                          value: '${dueExpressions.length}',
                        ),
                        _WikiSummaryTile(
                          label: '薄弱',
                          value: '${weakExpressions.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _WikiNotice(
                      icon: currentMastered
                          ? Icons.check_circle_outline_rounded
                          : Icons.track_changes_rounded,
                      title: currentState,
                      body: currentNode?.intent.isNotEmpty == true
                          ? currentNode!.intent
                          : '系统会根据当前公共 Wiki 节点和个人学习记录安排下一问。',
                    ),
                    const SizedBox(height: 8),
                    _WikiNotice(
                      icon: Icons.next_plan_outlined,
                      title: actionPlan.primaryAction?.title ?? '下一步策略',
                      body: actionPlan.primaryAction?.reason ?? nextFocus,
                    ),
                  ],
                ),
              ),
              const TabBar(
                isScrollable: true,
                labelColor: darkGreen,
                unselectedLabelColor: textSecondary,
                indicatorColor: darkGreen,
                tabs: [
                  Tab(text: '今日计划'),
                  Tab(text: '已掌握'),
                  Tab(text: '待复习'),
                  Tab(text: '薄弱'),
                  Tab(text: '发音语法'),
                  Tab(text: '个人素材'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _WikiActionPlanTab(
                      actionPlan: actionPlan,
                      onDismissAction: onDismissAction,
                      onMarkUseful: onMarkUseful,
                    ),
                    _MasteredWikiTab(
                      sceneTitle: sceneGraph?.titleCn ?? session.publicSceneId,
                      expressions: masteredExpressions,
                    ),
                    _DueWikiTab(
                      sceneTitle: sceneGraph?.titleCn ?? session.publicSceneId,
                      expressions: dueExpressions,
                    ),
                    _WeakWikiTab(
                      sceneTitle: sceneGraph?.titleCn ?? session.publicSceneId,
                      expressions: weakExpressions,
                    ),
                    _VoiceGrammarWikiTab(
                      pronunciationProfile: growthWiki.pronunciationProfile,
                      grammarProfile: growthWiki.grammarProfile,
                      errorPatterns: errorPatterns,
                    ),
                    _PersonalMaterialWikiTab(
                      growthWiki: growthWiki,
                      compiledWiki: compiledWiki,
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
}

class _WikiSummaryTile extends StatelessWidget {
  const _WikiSummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 60) / 4,
      constraints: const BoxConstraints(minWidth: 70),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: textSecondary),
          ),
        ],
      ),
    );
  }
}

class _WikiNotice extends StatelessWidget {
  const _WikiNotice({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5EA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: darkGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WikiActionPlanTab extends StatelessWidget {
  const _WikiActionPlanTab({
    required this.actionPlan,
    required this.onDismissAction,
    required this.onMarkUseful,
  });

  final InterviewWikiActionPlan actionPlan;
  final Future<void> Function(String id) onDismissAction;
  final Future<void> Function(String id) onMarkUseful;

  @override
  Widget build(BuildContext context) {
    final InterviewWikiActionItem? primary = actionPlan.primaryAction;
    final List<InterviewWikiActionItem> supporting = actionPlan.promptContext
        .where((InterviewWikiActionItem item) => item != primary)
        .toList(growable: false);
    if (primary == null &&
        actionPlan.reviewQueue.isEmpty &&
        actionPlan.weaknessQueue.isEmpty &&
        actionPlan.personalMaterialHints.isEmpty) {
      return const _WikiEmptyState(text: '还没有今日计划。完成一轮练习后，系统会生成复习目标和个人素材。');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        if (primary != null)
          _WikiActionCard(
            item: primary,
            isPrimary: true,
            onDismissAction: onDismissAction,
            onMarkUseful: onMarkUseful,
          ),
        if (supporting.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _WikiSectionLabel('辅助上下文'),
          for (final InterviewWikiActionItem item in supporting)
            _WikiActionCard(
              item: item,
              onDismissAction: onDismissAction,
              onMarkUseful: onMarkUseful,
            ),
        ],
        if (actionPlan.reviewQueue.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _WikiSectionLabel('复习队列'),
          for (final InterviewWikiActionItem item
              in actionPlan.reviewQueue.take(4))
            _WikiActionCard(
              item: item,
              onDismissAction: onDismissAction,
              onMarkUseful: onMarkUseful,
            ),
        ],
        if (actionPlan.weaknessQueue.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _WikiSectionLabel('薄弱队列'),
          for (final InterviewWikiActionItem item
              in actionPlan.weaknessQueue.take(4))
            _WikiActionCard(
              item: item,
              onDismissAction: onDismissAction,
              onMarkUseful: onMarkUseful,
            ),
        ],
      ],
    );
  }
}

class _WikiSectionLabel extends StatelessWidget {
  const _WikiSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: textSecondary,
        ),
      ),
    );
  }
}

class _WikiActionCard extends StatelessWidget {
  const _WikiActionCard({
    required this.item,
    required this.onDismissAction,
    required this.onMarkUseful,
    this.isPrimary = false,
  });

  final InterviewWikiActionItem item;
  final Future<void> Function(String id) onDismissAction;
  final Future<void> Function(String id) onMarkUseful;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFEEF5EA) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPrimary ? darkGreen : borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TinyBadge(
                label: isPrimary ? '主目标' : _wikiActionTypeLabel(item.type),
                color: isPrimary ? darkGreen : const Color(0xFF5A6FA8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (item.body.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _WikiActionMeta(icon: Icons.info_outline_rounded, text: item.reason),
          if (item.evidence.trim().isNotEmpty)
            _WikiActionMeta(
              icon: Icons.format_quote_rounded,
              text: '证据：${item.evidence}',
            ),
          _WikiActionMeta(
            icon: Icons.playlist_add_check_rounded,
            text: '这轮怎么用：${item.suggestedUse}',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => onMarkUseful(item.id),
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                label: const Text('有用'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => onDismissAction(item.id),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('不再显示'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WikiActionMeta extends StatelessWidget {
  const _WikiActionMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _wikiActionTypeLabel(String type) {
  return switch (type) {
    'review' => '复习',
    'weak_expression' => '薄弱',
    'error_pattern' => '错误',
    'weak_pattern' => '弱点',
    'next_target' => '目标',
    'personal_story' => '故事',
    'personal_fact' => '事实',
    _ => '上下文',
  };
}

class _MasteredWikiTab extends StatelessWidget {
  const _MasteredWikiTab({required this.sceneTitle, required this.expressions});

  final String sceneTitle;
  final List<InterviewPersonalWikiExpression> expressions;

  @override
  Widget build(BuildContext context) {
    final List<InterviewPersonalWikiExpression> sorted =
        List<InterviewPersonalWikiExpression>.from(expressions)..sort(
          (
            InterviewPersonalWikiExpression a,
            InterviewPersonalWikiExpression b,
          ) => b.lastReviewedAt.compareTo(a.lastReviewedAt),
        );
    if (sorted.isEmpty) {
      return const _WikiEmptyState(text: '还没有掌握表达。完成一次自然复现后会自动进入这里。');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        for (final InterviewPersonalWikiExpression item in sorted)
          _WikiRecordCard(
            badge: '已掌握',
            badgeColor: darkGreen,
            title: item.text,
            body: item.userExample.isEmpty
                ? '暂无用户例句'
                : '你说过：${item.userExample}',
            footer:
                '来源：$sceneTitle / ${_nodeIdForExpression(item)} · 下次复习：${_formatWikiDate(item.nextReviewAt)}',
          ),
      ],
    );
  }
}

class _DueWikiTab extends StatelessWidget {
  const _DueWikiTab({required this.sceneTitle, required this.expressions});

  final String sceneTitle;
  final List<InterviewPersonalWikiExpression> expressions;

  @override
  Widget build(BuildContext context) {
    if (expressions.isEmpty) {
      return const _WikiEmptyState(text: '当前没有到期表达。系统会在遗忘曲线到期时自动优先复习。');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        for (final InterviewPersonalWikiExpression item in expressions)
          _WikiRecordCard(
            badge: _dueLabel(item.nextReviewAt),
            badgeColor: const Color(0xFFA0622A),
            title: item.text,
            body:
                '上次复习：${_formatWikiDate(item.lastReviewedAt)} · 已复现 ${item.reviewCount} 次',
            footer:
                '来源：$sceneTitle / ${_nodeIdForExpression(item)} · 用户证据：${item.userExample}',
          ),
      ],
    );
  }
}

class _WeakWikiTab extends StatelessWidget {
  const _WeakWikiTab({required this.sceneTitle, required this.expressions});

  final String sceneTitle;
  final List<InterviewWeakExpressionState> expressions;

  @override
  Widget build(BuildContext context) {
    if (expressions.isEmpty) {
      return const _WikiEmptyState(text: '当前没有薄弱表达。卡住、部分复现或依赖高阶提示时会自动记录。');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        for (final InterviewWeakExpressionState item in expressions)
          _WikiRecordCard(
            badge: item.lastHintLevel.isEmpty ? '待巩固' : item.lastHintLevel,
            badgeColor: const Color(0xFFA0622A),
            title: item.targetText,
            body: item.reason,
            footer:
                '来源：$sceneTitle / ${item.sourceNodeId} · 最近回答：${item.lastUserExample.isEmpty ? '暂无' : item.lastUserExample}',
          ),
      ],
    );
  }
}

class _VoiceGrammarWikiTab extends StatelessWidget {
  const _VoiceGrammarWikiTab({
    required this.pronunciationProfile,
    required this.grammarProfile,
    required this.errorPatterns,
  });

  final InterviewPronunciationProfile? pronunciationProfile;
  final InterviewGrammarProfile? grammarProfile;
  final List<InterviewUserErrorPattern> errorPatterns;

  @override
  Widget build(BuildContext context) {
    final InterviewPronunciationProfile? pronunciation = pronunciationProfile;
    final InterviewGrammarProfile? grammar = grammarProfile;
    final bool hasVoice = pronunciation != null && !pronunciation.isEmpty;
    final bool hasGrammar = grammar != null && !grammar.isEmpty;
    if (!hasVoice && !hasGrammar && errorPatterns.isEmpty) {
      return const _WikiEmptyState(text: '还没有发音和语法记录。语音作答和复盘后会逐步沉淀。');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        if (pronunciation != null && !pronunciation.isEmpty) ...[
          _WikiRecordCard(
            badge: '发音',
            badgeColor: darkGreen,
            title:
                '平均 ${pronunciation.averageOverall.round()} · 样本 ${pronunciation.sampleCount}',
            body:
                '准确度 ${pronunciation.averageAccuracy.round()} · 流利度 ${pronunciation.averageFluency.round()} · 完整度 ${pronunciation.averageCompleteness.round()}',
            footer: pronunciation.notes.isEmpty
                ? '最近更新：${_formatWikiDate(pronunciation.updatedAt)}'
                : pronunciation.notes.join('；'),
          ),
          const SizedBox(height: 10),
        ],
        if (grammar != null && !grammar.isEmpty) ...[
          _WikiRecordCard(
            badge: '语法',
            badgeColor: const Color(0xFF5A6FA8),
            title: '累计 ${grammar.issueCount} 个语法问题',
            body: grammar.recurringIssues.isEmpty
                ? '暂无高频问题'
                : grammar.recurringIssues.take(3).join('；'),
            footer: grammar.notes.isEmpty
                ? '最近更新：${_formatWikiDate(grammar.updatedAt)}'
                : grammar.notes.join('；'),
          ),
          const SizedBox(height: 10),
        ],
        for (final InterviewUserErrorPattern item in errorPatterns)
          _WikiRecordCard(
            badge: item.category,
            badgeColor: const Color(0xFFA0622A),
            title: item.title,
            body: item.correction.isEmpty
                ? item.detail
                : '建议：${item.correction}',
            footer: '证据：${item.evidence} · 出现 ${item.count} 次',
          ),
      ],
    );
  }
}

class _PersonalMaterialWikiTab extends StatelessWidget {
  const _PersonalMaterialWikiTab({
    required this.growthWiki,
    required this.compiledWiki,
  });

  final InterviewUserGrowthWiki growthWiki;
  final InterviewCompiledWiki compiledWiki;

  @override
  Widget build(BuildContext context) {
    final List<InterviewCompiledWikiItem> facts =
        growthWiki.personalFacts.isNotEmpty
        ? growthWiki.personalFacts
        : compiledWiki.personalFacts;
    final List<InterviewCompiledWikiItem> stories =
        growthWiki.interviewStories.isNotEmpty
        ? growthWiki.interviewStories
        : compiledWiki.interviewStories;
    final List<InterviewCompiledWikiItem> nextTargets =
        compiledWiki.nextTargets;
    if (growthWiki.profileSummary.isEmpty &&
        facts.isEmpty &&
        stories.isEmpty &&
        nextTargets.isEmpty) {
      return const _WikiEmptyState(
        text: '还没有个人素材。完成复盘后，AI 会把背景、项目和下轮目标编译进个人 Wiki。',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        if (growthWiki.profileSummary.isNotEmpty)
          _WikiRecordCard(
            badge: '摘要',
            badgeColor: darkGreen,
            title: '个人画像',
            body: growthWiki.profileSummary,
            footer: '用户 Growth Wiki · ${_formatWikiDate(growthWiki.updatedAt)}',
          ),
        for (final InterviewCompiledWikiItem item in facts)
          _WikiRecordCard(
            badge: '事实',
            badgeColor: const Color(0xFF5A6FA8),
            title: item.title,
            body: item.body,
            footer: '证据：${item.evidence}',
          ),
        for (final InterviewCompiledWikiItem item in stories)
          _WikiRecordCard(
            badge: '故事',
            badgeColor: const Color(0xFFA0622A),
            title: item.title,
            body: item.body,
            footer: '证据：${item.evidence}',
          ),
        for (final InterviewCompiledWikiItem item in nextTargets)
          _WikiRecordCard(
            badge: '下轮目标',
            badgeColor: darkGreen,
            title: item.title,
            body: item.body,
            footer: '证据：${item.evidence}',
          ),
      ],
    );
  }
}

class _WikiRecordCard extends StatelessWidget {
  const _WikiRecordCard({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.body,
    required this.footer,
  });

  final String badge;
  final Color badgeColor;
  final String title;
  final String body;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TinyBadge(label: badge, color: badgeColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: textPrimary,
              ),
            ),
          ],
          if (footer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              footer,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WikiEmptyState extends StatelessWidget {
  const _WikiEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: textSecondary,
          ),
        ),
      ),
    );
  }
}

String _nodeIdForExpression(InterviewPersonalWikiExpression expression) {
  return expression.sourceNodeId.isNotEmpty
      ? expression.sourceNodeId
      : expression.sourceExpressionId;
}

String _formatWikiDate(DateTime date) {
  if (date.millisecondsSinceEpoch <= 0) {
    return '暂无';
  }
  return '${date.month}/${date.day}';
}

String _dueLabel(DateTime date) {
  final DateTime now = DateTime.now();
  if (!date.isAfter(now)) {
    return '已到期';
  }
  final int days = date.difference(now).inDays.clamp(0, 365).toInt();
  if (days == 0) {
    return '今天';
  }
  if (days == 1) {
    return '明天';
  }
  return '$days 天后';
}

class _GrammarScoreResult {
  const _GrammarScoreResult({
    required this.score,
    required this.issues,
    required this.correction,
    required this.provider,
  });

  final int score;
  final List<String> issues;
  final String correction;
  final String provider;
}

class _InterviewMessageBubble extends StatelessWidget {
  const _InterviewMessageBubble({
    required this.message,
    required this.assistantName,
    required this.assistantRoleLabel,
    this.softened = false,
    this.collapsed = false,
    this.translation,
    this.translating = false,
    this.voiceTextRevealed = false,
    this.masteryStreak = 0,
    this.expressionSuggestionExpanded = false,
    this.onTranslate,
    this.onPlayAssistant,
    this.onRevealVoiceText,
    this.onPlayUserVoice,
    this.onToggleExpressionSuggestion,
  });

  final InterviewChatMessage message;
  final String assistantName;
  final String assistantRoleLabel;
  final bool softened;
  final bool collapsed;
  final String? translation;
  final bool translating;
  final bool voiceTextRevealed;
  final int masteryStreak;
  final bool expressionSuggestionExpanded;
  final VoidCallback? onTranslate;
  final VoidCallback? onPlayAssistant;
  final VoidCallback? onRevealVoiceText;
  final VoidCallback? onPlayUserVoice;
  final VoidCallback? onToggleExpressionSuggestion;

  @override
  Widget build(BuildContext context) {
    final bool assistant = message.role == 'assistant';
    final bool userVoice = !assistant && message.isVoice;
    final String expressionSuggestionText = _expressionSuggestionTextForMessage(
      message,
    );
    final bool showExpressionSuggestion =
        _shouldShowExpressionSuggestionForMessage(message) &&
        expressionSuggestionText.isNotEmpty;
    final bool primaryAssistantQuestion =
        assistant &&
        !message.isHint &&
        !message.isAlignment &&
        !message.isMastered;
    final Color bubbleColor = assistant
        ? const Color(0xFFFFFCF6)
        : const Color(0xFFE7F0D1);
    final Color textColor = textPrimary;
    final BorderRadius bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(assistant ? 8 : 18),
      bottomRight: Radius.circular(assistant ? 18 : 8),
    );
    final Widget bubbleBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.isHint ||
            message.isAlignment ||
            (assistant && message.isMastered))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (message.isHint) ...[
                  const _TinyBadge(label: '提示', color: Color(0xFFA0622A)),
                  if (message.hintLevel.isNotEmpty)
                    _TinyBadge(
                      label: _hintLevelLabel(message.hintLevel),
                      color: _hintLevelColor(message.hintLevel),
                    ),
                ],
                if (message.isAlignment)
                  const _TinyBadge(label: '对齐', color: Color(0xFF5A6FA8)),
                if (assistant && message.isMastered)
                  const _TinyBadge(label: '已掌握', color: Color(0xFF4A7C6F)),
                if (message.isHint && message.tag.isNotEmpty)
                  _TinyBadge(label: message.tag, color: darkGreen),
              ],
            ),
          ),
        if (collapsed && message.isHint)
          Row(
            children: [
              const Icon(
                Icons.unfold_less_rounded,
                size: 16,
                color: textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_hintLevelLabel(message.hintLevel)} 已折叠，继续看最新提示。',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          )
        else if (!assistant && message.isVoice)
          _UserVoiceContent(
            message: message,
            textRevealed: voiceTextRevealed,
            onReveal: onRevealVoiceText,
            onPlay: onPlayUserVoice,
          )
        else
          Text(
            message.text,
            style: TextStyle(
              fontSize: primaryAssistantQuestion ? 17 : 14.5,
              height: primaryAssistantQuestion ? 1.42 : 1.45,
              color: textColor,
              fontWeight: primaryAssistantQuestion
                  ? FontWeight.w600
                  : FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        if (assistant &&
            (onPlayAssistant != null || onTranslate != null) &&
            !collapsed) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [
              if (onPlayAssistant != null)
                _MessagePlaybackButton(onPressed: onPlayAssistant),
              if (onTranslate != null)
                _MessageTranslationButton(
                  translating: translating,
                  expanded: translation != null && translation!.isNotEmpty,
                  onPressed: onTranslate,
                ),
            ],
          ),
          if (translation != null && translation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _TranslationPanel(text: translation!),
          ],
        ],
      ],
    );
    final Widget bubble = userVoice
        ? bubbleBody
        : Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.79,
            ),
            padding: EdgeInsets.fromLTRB(
              primaryAssistantQuestion ? 14 : 13,
              primaryAssistantQuestion ? 12 : 11,
              primaryAssistantQuestion ? 14 : 13,
              primaryAssistantQuestion ? 11 : 11,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: bubbleRadius,
              border: Border.all(
                color: assistant
                    ? const Color(0xFFF0EEE6)
                    : const Color(0xFFD4E7AE),
              ),
              boxShadow: primaryAssistantQuestion
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: bubbleBody,
          );
    final bool showVoiceOutcomePulse =
        !assistant &&
        message.isVoice &&
        (message.isMastered || showExpressionSuggestion);
    final Widget displayedBubble = showVoiceOutcomePulse
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: message.isMastered
                        ? _MasteryPulseIndicator(streak: masteryStreak)
                        : const _NeedsPracticePulseIndicator(),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              bubble,
            ],
          )
        : bubble;
    final Widget messageColumn = Column(
      crossAxisAlignment: assistant
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        if (assistant) ...[
          Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  assistantName,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1,
                    color: Color(0xFF454A43),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  assistantRoleLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1,
                    color: textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
        displayedBubble,
        if (!assistant && message.isVoice) ...[
          const SizedBox(height: 6),
          _VoiceScoreRow(
            text: message.text,
            voiceAudioPath: message.voiceAudioPath,
            grammarScore: message.grammarScore,
            pronunciationScore: message.pronunciationScore,
            pronunciationSource: message.pronunciationSource,
            pronunciationAccuracy: message.pronunciationAccuracy,
            pronunciationFluency: message.pronunciationFluency,
            pronunciationCompleteness: message.pronunciationCompleteness,
            grammarIssues: message.grammarIssues,
            grammarCorrection: message.grammarCorrection,
            grammarProvider: message.grammarProvider,
            refinementText: expressionSuggestionText,
            expressionSuggestionText: expressionSuggestionText,
            isMastered: message.isMastered,
            masteryStreak: masteryStreak,
            showExpressionSuggestion: showExpressionSuggestion,
            expressionSuggestionExpanded: expressionSuggestionExpanded,
            onToggleExpressionSuggestion: onToggleExpressionSuggestion,
          ),
        ],
      ],
    );
    final Widget row = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: assistant
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: assistant
            ? <Widget>[
                const _ChatAvatar(assistant: true),
                const SizedBox(width: 8),
                Flexible(child: messageColumn),
              ]
            : <Widget>[
                Flexible(child: messageColumn),
                const SizedBox(width: 8),
                const _ChatAvatar(assistant: false),
              ],
      ),
    );
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      opacity: softened && userVoice && message.isMastered
          ? 0.78
          : softened
          ? 0.36
          : 1,
      child: row,
    );
  }

  static String _hintLevelLabel(String level) {
    return switch (level) {
      'L1' => 'L1 轻提示',
      'L2' => 'L2 结构',
      'L3' => 'L3 填空',
      'L4' => 'L4 完整回答',
      _ => level,
    };
  }

  static Color _hintLevelColor(String level) {
    return switch (level) {
      'L1' => const Color(0xFF6F8E63),
      'L2' => const Color(0xFF5A6FA8),
      'L3' => const Color(0xFFA0622A),
      'L4' => const Color(0xFF8B4A40),
      _ => textSecondary,
    };
  }

  static String _expressionSuggestionTextForMessage(
    InterviewChatMessage message,
  ) {
    return message.expressionSuggestionText.trim();
  }

  static bool _shouldShowExpressionSuggestionForMessage(
    InterviewChatMessage message,
  ) {
    return message.isVoice &&
        message.expressionSuggestionText.trim().isNotEmpty;
  }
}

class _MasteryPulseIndicator extends StatefulWidget {
  const _MasteryPulseIndicator({required this.streak});

  final int streak;

  @override
  State<_MasteryPulseIndicator> createState() => _MasteryPulseIndicatorState();
}

class _MasteryPulseIndicatorState extends State<_MasteryPulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool combo = widget.streak >= 2;
    final int comboCount = widget.streak.clamp(2, 99);
    final double boxSize = combo ? 48 : 36;
    return SizedBox(
      width: boxSize,
      height: combo ? 42 : 36,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double value = _controller.value;
          final double beat = combo
              ? 1 + math.sin(value * math.pi * 2) * 0.055
              : 1.0;
          final Color accent = combo ? const Color(0xFFE5A83B) : darkGreen;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (combo)
                ...List<Widget>.generate(5, (int index) {
                  final double phase = (value + index * 0.17) % 1;
                  final double angle = -math.pi / 2 + index * math.pi * 0.42;
                  final double radius = 13 + phase * 10;
                  final double opacity = (1 - phase).clamp(0.0, 1.0) * 0.72;
                  return Transform.translate(
                    offset: Offset(
                      math.cos(angle) * radius,
                      math.sin(angle) * radius,
                    ),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: index.isEven ? 3.8 : 3.2,
                        height: index.isEven ? 3.8 : 3.2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index.isEven
                              ? const Color(0xFFE5A83B)
                              : const Color(0xFF6F8E63),
                        ),
                      ),
                    ),
                  );
                }),
              Transform.scale(
                scale: 0.72 + value * (combo ? 0.68 : 0.55),
                child: Opacity(
                  opacity: (1 - value).clamp(0.0, 1.0),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.38),
                        width: combo ? 2.4 : 2,
                      ),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: beat,
                child: Container(
                  width: combo ? 29 : 26,
                  height: combo ? 29 : 26,
                  decoration: BoxDecoration(
                    color: combo
                        ? const Color(0xFFFFF0BC)
                        : const Color(0xFFDDF8A6),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: combo ? 1.8 : 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: combo ? 0.26 : 0.16),
                        blurRadius: combo ? 16 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    combo
                        ? Icons.local_fire_department_rounded
                        : Icons.check_rounded,
                    size: combo ? 18 : 17,
                    color: combo ? const Color(0xFF8A5A12) : darkGreen,
                  ),
                ),
              ),
              if (combo)
                Positioned(
                  top: -1,
                  right: 0,
                  child: Transform.scale(
                    scale: 0.96 + math.sin(value * math.pi * 2) * 0.06,
                    child: Container(
                      height: 16,
                      constraints: const BoxConstraints(minWidth: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF263A23),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFFFF2C5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFE5A83B,
                            ).withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'x${comboCount > 9 ? '9+' : comboCount}',
                        style: const TextStyle(
                          color: Color(0xFFFFF6D6),
                          fontSize: 9.5,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NeedsPracticePulseIndicator extends StatefulWidget {
  const _NeedsPracticePulseIndicator();

  @override
  State<_NeedsPracticePulseIndicator> createState() =>
      _NeedsPracticePulseIndicatorState();
}

class _NeedsPracticePulseIndicatorState
    extends State<_NeedsPracticePulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFB9872F);
    const Color fill = Color(0xFFFFF4D9);
    return SizedBox(
      width: 36,
      height: 36,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double value = _controller.value;
          final double wobble = math.sin(value * math.pi * 2) * 0.06;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.72 + value * 0.48,
                child: Opacity(
                  opacity: (0.58 - value * 0.48).clamp(0.0, 0.58),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.42),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: wobble,
                child: Transform.scale(
                  scale: 1 + math.sin(value * math.pi * 2) * 0.035,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 1.45),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: Color(0xFF815B19),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF0),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '!',
                    style: TextStyle(
                      color: Color(0xFF815B19),
                      fontSize: 8.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.assistant});

  final bool assistant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: assistant ? const Color(0xFFF0F2EA) : const Color(0xFFE6F2CE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: assistant ? const Color(0xFFE0E3DA) : const Color(0xFFD4E7AE),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        assistant ? Icons.person_outline_rounded : Icons.person_rounded,
        size: 18,
        color: textPrimary,
      ),
    );
  }
}

class _UserVoiceContent extends StatelessWidget {
  const _UserVoiceContent({
    required this.message,
    required this.textRevealed,
    required this.onReveal,
    required this.onPlay,
  });

  final InterviewChatMessage message;
  final bool textRevealed;
  final VoidCallback? onReveal;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final String duration = _estimatedVoiceDurationLabel(
      message.text,
    ).replaceAll('"', '秒');
    final double transcriptWidth = math.min(
      MediaQuery.sizeOf(context).width * 0.74,
      320,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onReveal,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(
                minWidth: 172,
                maxWidth: 224,
                minHeight: 46,
              ),
              padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F0D1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD4E7AE)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mic_rounded,
                    size: 16,
                    color: Color(0xFF31442D),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      '$duration回答',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1,
                        color: Color(0xFF23301F),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: _VoiceWaveGlyph(),
                  ),
                  if (onPlay != null) ...[
                    const SizedBox(width: 2),
                    IconButton(
                      tooltip: '播放我的回答',
                      onPressed: onPlay,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(30, 30),
                        fixedSize: const Size(30, 30),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        size: 18,
                        color: Color(0xFF31442D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (textRevealed) ...[
          const SizedBox(height: 7),
          Container(
            width: transcriptWidth,
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E6DC)),
            ),
            child: Text(
              message.text,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                height: 1.38,
                color: textPrimary.withValues(alpha: 0.78),
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VoiceWaveGlyph extends StatelessWidget {
  const _VoiceWaveGlyph();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: const _VoiceWaveGlyphPainter(),
    );
  }
}

class _VoiceWaveGlyphPainter extends CustomPainter {
  const _VoiceWaveGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF152314)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final double centerY = size.height / 2;
    final List<double> radii = <double>[4.0, 7.5, 11.0];
    for (int index = 0; index < radii.length; index += 1) {
      final double radius = radii[index];
      final Rect rect = Rect.fromCircle(
        center: Offset(0, centerY),
        radius: radius,
      );
      canvas.drawArc(rect, -0.72, 1.44, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWaveGlyphPainter oldDelegate) => false;
}

class _VoiceScoreRow extends StatelessWidget {
  const _VoiceScoreRow({
    required this.text,
    required this.voiceAudioPath,
    required this.grammarScore,
    required this.pronunciationScore,
    required this.pronunciationSource,
    required this.pronunciationAccuracy,
    required this.pronunciationFluency,
    required this.pronunciationCompleteness,
    required this.grammarIssues,
    required this.grammarCorrection,
    required this.grammarProvider,
    required this.refinementText,
    required this.expressionSuggestionText,
    required this.isMastered,
    required this.masteryStreak,
    required this.showExpressionSuggestion,
    required this.expressionSuggestionExpanded,
    required this.onToggleExpressionSuggestion,
  });

  final String text;
  final String voiceAudioPath;
  final int? grammarScore;
  final int? pronunciationScore;
  final String pronunciationSource;
  final int? pronunciationAccuracy;
  final int? pronunciationFluency;
  final int? pronunciationCompleteness;
  final List<String> grammarIssues;
  final String grammarCorrection;
  final String grammarProvider;
  final String refinementText;
  final String expressionSuggestionText;
  final bool isMastered;
  final int masteryStreak;
  final bool showExpressionSuggestion;
  final bool expressionSuggestionExpanded;
  final VoidCallback? onToggleExpressionSuggestion;

  @override
  Widget build(BuildContext context) {
    final _InlineVoiceFeedbackData? feedback = _inlineFeedbackData();
    if (feedback == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerRight,
      child: _InlineVoiceFeedbackBar(
        feedback: feedback,
        expanded: expressionSuggestionExpanded,
        onToggle: onToggleExpressionSuggestion,
        onShowDetails: () => _showFeedbackDetails(context),
      ),
    );
  }

  _InlineVoiceFeedbackData? _inlineFeedbackData() {
    final List<String> lines = expressionSuggestionText
        .split(RegExp(r'[\r\n]+'))
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      return null;
    }
    final String message = lines.first;
    if (!showExpressionSuggestion || message.isEmpty) {
      return null;
    }
    return _InlineVoiceFeedbackData(
      message: message,
      icon: isMastered
          ? Icons.check_circle_outline_rounded
          : Icons.lightbulb_outline_rounded,
      accentColor: isMastered
          ? const Color(0xFF6F8E63)
          : const Color(0xFF7A6B45),
      details: lines.skip(1).take(5).toList(growable: false),
    );
  }

  int? _overallFeedbackScore() {
    final List<int> scores = <int>[
      if (grammarScore != null) grammarScore!.clamp(0, 100),
      if (pronunciationScore != null) pronunciationScore!.clamp(0, 100),
    ];
    if (scores.isEmpty) {
      return null;
    }
    return (scores.reduce((int a, int b) => a + b) / scores.length).round();
  }

  void _showFeedbackDetails(BuildContext context) {
    final List<String> generatorNotes = expressionSuggestionText
        .split(RegExp(r'[\r\n]+'))
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .skip(1)
        .toList(growable: false);
    final List<String> notes = <String>[...generatorNotes, ...grammarIssues];
    _showVoiceScoreDetails(
      context,
      title: '本轮反馈',
      score: _overallFeedbackScore(),
      providerLabel:
          '${_grammarProviderLabel(grammarProvider)} · ${_pronunciationProviderLabel(pronunciationSource)}',
      rows: <_ScoreDetailRowData>[
        _ScoreDetailRowData('语法', grammarScore),
        _ScoreDetailRowData('发音', pronunciationScore),
        _ScoreDetailRowData('流利度', pronunciationFluency),
        _ScoreDetailRowData('完整度', pronunciationCompleteness),
      ],
      notes: notes,
      correction: grammarCorrection,
      emptyText: grammarScore == null && pronunciationScore == null
          ? '这条回答还没有生成详细反馈。'
          : '',
    );
  }

  // ignore: unused_element
  void _showGrammarDetails(BuildContext context) {
    _showVoiceScoreDetails(
      context,
      title: '语法评分详情',
      score: grammarScore,
      providerLabel: _grammarProviderLabel(grammarProvider),
      rows: const <_ScoreDetailRowData>[],
      notes: grammarIssues,
      correction: grammarCorrection,
      emptyText: grammarScore == null ? '这条语音还没有生成语法评分。' : '',
    );
  }

  // ignore: unused_element
  void _showPronunciationDetails(BuildContext context) {
    _showPronunciationReport(
      context,
      text: text,
      voiceAudioPath: voiceAudioPath,
      score: pronunciationScore,
      accuracy: pronunciationAccuracy,
      fluency: pronunciationFluency,
      completeness: pronunciationCompleteness,
      providerLabel: _pronunciationProviderLabel(pronunciationSource),
      refinementText: refinementText,
    );
  }

  String _pronunciationProviderLabel(String source) {
    final String normalized = source.toLowerCase();
    if (normalized.contains('ali') || normalized.contains('singsound')) {
      return '来源：阿里口语测评';
    }
    if (normalized.contains('backend') || normalized.contains('server')) {
      return '来源：后端备用评分';
    }
    return '来源：待确认';
  }

  String _grammarProviderLabel(String provider) {
    final String normalized = provider.toLowerCase();
    if (normalized.contains('qwen')) {
      return '来源：后端语法评测';
    }
    return grammarScore == null ? '来源：暂无' : '来源：语法评测';
  }
}

class _InlineVoiceFeedbackData {
  const _InlineVoiceFeedbackData({
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.details,
  });

  final String message;
  final IconData icon;
  final Color accentColor;
  final List<String> details;
}

class _InlineVoiceFeedbackBar extends StatelessWidget {
  const _InlineVoiceFeedbackBar({
    required this.feedback,
    required this.expanded,
    required this.onToggle,
    required this.onShowDetails,
  });

  final _InlineVoiceFeedbackData feedback;
  final bool expanded;
  final VoidCallback? onToggle;
  final VoidCallback onShowDetails;

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.sizeOf(context).width * 0.74;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBF6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9E4DA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(feedback.icon, size: 15, color: feedback.accentColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      feedback.message,
                      maxLines: expanded ? 3 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.32,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: textTertiary,
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 8),
                for (final String line in feedback.details)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      line,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.36,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onShowDetails,
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '查看本轮细节',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreDetailRowData {
  const _ScoreDetailRowData(this.label, this.score);

  final String label;
  final int? score;
}

void _showPronunciationReport(
  BuildContext context, {
  required String text,
  required String voiceAudioPath,
  required int? score,
  required int? accuracy,
  required int? fluency,
  required int? completeness,
  required String providerLabel,
  required String refinementText,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF3F3F1),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.48,
        maxChildSize: 0.94,
        builder: (BuildContext context, ScrollController scrollController) {
          return FutureBuilder<int?>(
            future: _estimateWordsPerMinute(
              audioPath: voiceAudioPath,
              text: text,
            ),
            builder: (BuildContext context, AsyncSnapshot<int?> snapshot) {
              return SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PronunciationSentenceCard(
                        text: text,
                        voiceAudioPath: voiceAudioPath,
                        score: score,
                      ),
                      const SizedBox(height: 18),
                      const _PronunciationSectionTitle(text: '评分建议'),
                      const SizedBox(height: 8),
                      _PronunciationScoreCard(
                        score: score,
                        accuracy: accuracy,
                        fluency: fluency,
                        completeness: completeness,
                        wordsPerMinute: snapshot.data,
                        providerLabel: providerLabel,
                      ),
                      const SizedBox(height: 20),
                      const _PronunciationSectionTitle(text: '语境润色'),
                      const SizedBox(height: 8),
                      _PronunciationRefinementCard(
                        originalText: text,
                        refinementText: refinementText,
                      ),
                      const SizedBox(height: 14),
                      const Center(
                        child: Text(
                          '内容由 AI 生成',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFC0C4BE),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

Future<int?> _estimateWordsPerMinute({
  required String audioPath,
  required String text,
}) async {
  final String path = audioPath.trim();
  if (path.isEmpty) {
    return null;
  }
  final double? seconds = await _readWavDurationSeconds(path);
  if (seconds == null || seconds <= 0) {
    return null;
  }
  final int wordCount = RegExp(
    r"[A-Za-z]+(?:'[A-Za-z]+)?|\d+",
  ).allMatches(text).length;
  if (wordCount <= 0) {
    return null;
  }
  return ((wordCount / seconds) * 60).round().clamp(0, 320);
}

Future<double?> _readWavDurationSeconds(String path) async {
  try {
    final File file = File(path);
    if (!await file.exists()) {
      return null;
    }
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.length < 44) {
      return null;
    }
    final ByteData data = ByteData.sublistView(bytes);
    final String riff = String.fromCharCodes(bytes.sublist(0, 4));
    final String wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') {
      return null;
    }
    int offset = 12;
    int? byteRate;
    int? dataSize;
    while (offset + 8 <= bytes.length) {
      final String chunkId = String.fromCharCodes(
        bytes.sublist(offset, offset + 4),
      );
      final int chunkSize = data.getUint32(offset + 4, Endian.little);
      final int chunkDataOffset = offset + 8;
      if (chunkId == 'fmt ' && chunkDataOffset + 16 <= bytes.length) {
        byteRate = data.getUint32(chunkDataOffset + 8, Endian.little);
      } else if (chunkId == 'data') {
        dataSize = chunkSize;
        break;
      }
      offset = chunkDataOffset + chunkSize + (chunkSize.isOdd ? 1 : 0);
    }
    if (byteRate == null || byteRate <= 0 || dataSize == null) {
      return null;
    }
    return dataSize / byteRate;
  } catch (_) {
    return null;
  }
}

class _PronunciationSentenceCard extends StatelessWidget {
  const _PronunciationSentenceCard({
    required this.text,
    required this.voiceAudioPath,
    required this.score,
  });

  final String text;
  final String voiceAudioPath;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final Color markColor = _scoreColor(score);
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PronunciationLegend(),
              const SizedBox(height: 18),
              _PronunciationMarkedText(text: text, color: markColor),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFE7E8E4)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _PronunciationActionButton(
                    label: '英音',
                    icon: Icons.volume_up_rounded,
                    onTap: () async {
                      await AudioServiceScope.of(context).playTts(text);
                    },
                  ),
                  _PronunciationActionButton(
                    label: '美音',
                    icon: Icons.volume_up_rounded,
                    onTap: () async {
                      await AudioServiceScope.of(context).playTts(text);
                    },
                  ),
                  _PronunciationActionButton(
                    label: '我的',
                    icon: Icons.volume_up_rounded,
                    onTap: () async {
                      final String path = voiceAudioPath.trim();
                      if (path.isNotEmpty) {
                        await AudioServiceScope.of(context).playFile(path);
                      }
                    },
                  ),
                  _PronunciationActionButton(
                    label: '重读',
                    icon: Icons.replay_rounded,
                    highlight: true,
                    onTap: () async {
                      await Navigator.of(context).maybePop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF2F3F0),
              foregroundColor: textPrimary,
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}

class _PronunciationLegend extends StatelessWidget {
  const _PronunciationLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _LegendDot(label: '待提高', color: Color(0xFFFF4D5A)),
        _LegendDot(label: '小瑕疵', color: Color(0xFFFF9F1C)),
        _LegendDot(label: '很完美', color: Color(0xFF101010)),
        _LegendLine(label: '连读', color: Color(0xFF59D323), curved: true),
        _LegendLine(label: '重读词', color: Color(0xFF59D323)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({
    required this.label,
    required this.color,
    this.curved = false,
  });

  final String label;
  final Color color;
  final bool curved;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(18, 8),
          painter: _LegendLinePainter(color: color, curved: curved),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter({required this.color, required this.curved});

  final Color color;
  final bool curved;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (curved) {
      final Path path = Path()
        ..moveTo(1, size.height * 0.45)
        ..quadraticBezierTo(
          size.width * 0.35,
          size.height,
          size.width * 0.55,
          size.height * 0.45,
        )
        ..quadraticBezierTo(
          size.width * 0.75,
          0,
          size.width - 1,
          size.height * 0.45,
        );
      canvas.drawPath(path, paint);
    } else {
      canvas.drawLine(
        Offset(1, size.height / 2),
        Offset(size.width - 1, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.curved != curved;
  }
}

class _PronunciationMarkedText extends StatelessWidget {
  const _PronunciationMarkedText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final List<String> words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return const Text(
        '暂无文本',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0,
        ),
      );
    }
    return Wrap(
      spacing: 9,
      runSpacing: 10,
      children: words
          .map(
            (String word) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.12,
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: math.max(28, math.min(82, word.length * 9.5)),
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          )
          .toList(growable: false),
    );
  }
}

class _PronunciationActionButton extends StatelessWidget {
  const _PronunciationActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final IconData icon;
  final Future<void> Function()? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color color = highlight ? const Color(0xFF59D323) : textPrimary;
    return InkWell(
      onTap: onTap == null ? null : () => unawaited(onTap!()),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PronunciationSectionTitle extends StatelessWidget {
  const _PronunciationSectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: 0,
      ),
    );
  }
}

class _PronunciationScoreCard extends StatelessWidget {
  const _PronunciationScoreCard({
    required this.score,
    required this.accuracy,
    required this.fluency,
    required this.completeness,
    required this.wordsPerMinute,
    required this.providerLabel,
  });

  final int? score;
  final int? accuracy;
  final int? fluency;
  final int? completeness;
  final int? wordsPerMinute;
  final String providerLabel;

  @override
  Widget build(BuildContext context) {
    final int displayScore = (score ?? 0).clamp(0, 100);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 340;
                  final Widget metrics = Column(
                    children: [
                      _PronunciationMetricBar(label: '流利度', score: fluency),
                      _PronunciationMetricBar(label: '发音分', score: accuracy),
                      _PronunciationMetricBar(
                        label: '完整度',
                        score: completeness,
                      ),
                    ],
                  );
                  final Widget gauge = _SpeechSpeedGauge(
                    wordsPerMinute: wordsPerMinute,
                  );
                  if (compact) {
                    return Column(
                      children: [metrics, const SizedBox(height: 16), gauge],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: metrics),
                      Container(
                        width: 1,
                        height: 118,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: const Color(0xFFE7E8E4),
                      ),
                      SizedBox(width: 142, child: gauge),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE7E8E4)),
              const SizedBox(height: 12),
              Text(
                _pronunciationAdvice(
                  score: displayScore,
                  fluency: fluency,
                  accuracy: accuracy,
                  completeness: completeness,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                providerLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -16,
          left: 16,
          child: Row(
            children: [
              _CircularScoreBadge(score: score),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.fromLTRB(11, 6, 13, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Text(
                  '综合评分',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircularScoreBadge extends StatelessWidget {
  const _CircularScoreBadge({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    final int value = (score ?? 0).clamp(0, 100);
    final Color color = _scoreColor(score);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 4),
      ),
      alignment: Alignment.center,
      child: Text(
        score == null ? '--' : '$value',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _PronunciationMetricBar extends StatelessWidget {
  const _PronunciationMetricBar({required this.label, required this.score});

  final String label;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final int value = (score ?? 0).clamp(0, 100);
    final Color color = _scoreColor(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '$label  ${score == null ? '--' : value}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: 0,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: score == null ? 0 : value / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFFE7E8E4),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechSpeedGauge extends StatelessWidget {
  const _SpeechSpeedGauge({required this.wordsPerMinute});

  final int? wordsPerMinute;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: CustomPaint(
        painter: _SpeechSpeedGaugePainter(wordsPerMinute: wordsPerMinute),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wordsPerMinute == null ? '--词/分' : '$wordsPerMinute词/分',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '语速',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC0C4BE),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechSpeedGaugePainter extends CustomPainter {
  const _SpeechSpeedGaugePainter({required this.wordsPerMinute});

  final int? wordsPerMinute;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.82);
    final double radius = math.min(size.width * 0.42, size.height * 0.62);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    const double start = math.pi;
    const double sweep = math.pi;
    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      start,
      sweep * 0.28,
      false,
      base..color = const Color(0xFFFFA12A),
    );
    canvas.drawArc(
      rect,
      start + sweep * 0.28,
      sweep * 0.44,
      false,
      base..color = const Color(0xFF59D323),
    );
    canvas.drawArc(
      rect,
      start + sweep * 0.72,
      sweep * 0.28,
      false,
      base..color = const Color(0xFFFF4D5A),
    );

    final int value = (wordsPerMinute ?? 150).clamp(50, 250);
    final double t = (value - 50) / 200;
    final double angle = start + sweep * t;
    final Offset needleEnd = Offset(
      center.dx + math.cos(angle) * radius * 0.9,
      center.dy + math.sin(angle) * radius * 0.9,
    );
    final Paint needle = Paint()
      ..color = const Color(0xFFECC872)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needle);

    const TextStyle tickStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w800,
      color: Color(0xFF9CA39B),
    );
    for (final int tick in <int>[50, 90, 110, 150, 190, 210, 250]) {
      final double tickT = (tick - 50) / 200;
      final double tickAngle = start + sweep * tickT;
      final Offset tickOffset = Offset(
        center.dx + math.cos(tickAngle) * radius * 1.28,
        center.dy + math.sin(tickAngle) * radius * 1.28,
      );
      final TextPainter painter = TextPainter(
        text: TextSpan(text: '$tick', style: tickStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        tickOffset - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeechSpeedGaugePainter oldDelegate) {
    return oldDelegate.wordsPerMinute != wordsPerMinute;
  }
}

class _PronunciationRefinementCard extends StatelessWidget {
  const _PronunciationRefinementCard({
    required this.originalText,
    required this.refinementText,
  });

  final String originalText;
  final String refinementText;

  @override
  Widget build(BuildContext context) {
    final String suggestion = _cleanRefinementText(refinementText);
    final String optimized = suggestion.isNotEmpty ? suggestion : originalText;
    final bool hasSuggestion =
        suggestion.isNotEmpty && suggestion != originalText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 22,
            children: [
              _RefinementTab(label: '地道美式', selected: true),
              _RefinementTab(label: '商务正式'),
              _RefinementTab(label: '地道英式'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 7,
            children: const [
              _RefinementTool(icon: Icons.mic_rounded, label: '循环跟读'),
              _RefinementTool(icon: Icons.add_box_outlined, label: '复制'),
              _RefinementTool(icon: Icons.star_border_rounded, label: '收藏'),
              _RefinementTool(icon: Icons.volume_up_rounded, label: 'AI'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '优化后的句子： $optimized',
            style: const TextStyle(
              fontSize: 15,
              height: 1.42,
              color: textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasSuggestion
                ? '修改解释：这句表达可以更自然地贴近当前语境。跟读时先保证语速稳定，再把关键词重音说清楚。'
                : '修改解释：当前暂未生成单独的语境润色建议。你可以先围绕这句话继续跟读，重点保持语速自然、关键词清晰。',
            style: const TextStyle(
              fontSize: 13,
              height: 1.52,
              color: textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefinementTab extends StatelessWidget {
  const _RefinementTab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: selected ? textPrimary : const Color(0xFF9EA39A),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 68,
          height: 3,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF59D323) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _RefinementTool extends StatelessWidget {
  const _RefinementTool({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: textPrimary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

String _cleanRefinementText(String value) {
  return value.trim().replaceFirst(RegExp(r'^也可以这样说[:：]\s*'), '').trim();
}

String _pronunciationAdvice({
  required int score,
  int? fluency,
  int? accuracy,
  int? completeness,
}) {
  final List<String> weak = <String>[];
  if ((fluency ?? 100) < 75) weak.add('语速可以更自然');
  if ((accuracy ?? 100) < 75) weak.add('关键词发音需要更清楚');
  if ((completeness ?? 100) < 75) weak.add('句子完整度还可以提高');
  if (score >= 90 && weak.isEmpty) {
    return '语速自然，表达流利顺畅，发音整体稳定。继续保持关键词重音和句尾收束，会更接近自然交流。';
  }
  if (weak.isEmpty) {
    return '整体表达可懂，继续用慢速跟读把节奏、重音和连读练得更稳定。';
  }
  return '${weak.join('，')}。建议先分段跟读，再连成完整句。';
}

Color _scoreColor(int? score) {
  if (score == null) {
    return const Color(0xFF9EA39A);
  }
  if (score >= 85) {
    return const Color(0xFF59D323);
  }
  if (score >= 70) {
    return const Color(0xFFFF9F1C);
  }
  return const Color(0xFFFF4D5A);
}

void _showVoiceScoreDetails(
  BuildContext context, {
  required String title,
  required int? score,
  required String providerLabel,
  required List<_ScoreDetailRowData> rows,
  required List<String> notes,
  required String correction,
  required String emptyText,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (BuildContext context) {
      final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      final List<_ScoreDetailRowData> visibleRows = rows
          .where((_ScoreDetailRowData row) => row.score != null)
          .toList(growable: false);
      final List<String> visibleNotes = notes
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
      final String trimmedCorrection = correction.trim();
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.74,
        minChildSize: 0.42,
        maxChildSize: 0.94,
        builder: (BuildContext context, ScrollController scrollController) {
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(20, 2, 20, 26 + bottomInset),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      _ScorePill(score: score),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    providerLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                  if (emptyText.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      emptyText.trim(),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                  if (visibleRows.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...visibleRows.map(
                      (_ScoreDetailRowData row) => _ScoreDetailMetric(row: row),
                    ),
                  ],
                  if (visibleNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _ScoreDetailSectionTitle(text: '主要问题'),
                    const SizedBox(height: 8),
                    ...visibleNotes.map(
                      (String item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 7),
                              child: Icon(
                                Icons.circle,
                                size: 5,
                                color: darkGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (trimmedCorrection.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const _ScoreDetailSectionTitle(text: '建议改写'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCE8D5)),
                      ),
                      child: Text(
                        trimmedCorrection,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6D1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        score == null ? '--' : '${score!.clamp(0, 100)} 分',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: darkGreen,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ScoreDetailSectionTitle extends StatelessWidget {
  const _ScoreDetailSectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: 0,
      ),
    );
  }
}

class _ScoreDetailMetric extends StatelessWidget {
  const _ScoreDetailMetric({required this.row});

  final _ScoreDetailRowData row;

  @override
  Widget build(BuildContext context) {
    final int score = (row.score ?? 0).clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: darkGreen,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFE6EAE1),
              valueColor: const AlwaysStoppedAnimation<Color>(darkGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagePlaybackButton extends StatelessWidget {
  const _MessagePlaybackButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '播放',
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF4F6EF),
          foregroundColor: darkGreen,
          fixedSize: const Size(32, 32),
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
      ),
    );
  }
}

class _MessageTranslationButton extends StatelessWidget {
  const _MessageTranslationButton({
    required this.translating,
    required this.expanded,
    required this.onPressed,
  });

  final bool translating;
  final bool expanded;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: translating
          ? '翻译中'
          : expanded
          ? '收起翻译'
          : '翻译',
      child: IconButton(
        onPressed: translating ? null : onPressed,
        style: IconButton.styleFrom(
          backgroundColor: expanded
              ? const Color(0xFFEAF2DF)
              : const Color(0xFFF4F6EF),
          foregroundColor: darkGreen,
          fixedSize: const Size(32, 32),
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: translating
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.translate_rounded, size: 16),
      ),
    );
  }
}

class _TranslationPanel extends StatelessWidget {
  const _TranslationPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E8DB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: textPrimary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

String _estimatedVoiceDurationLabel(String text) {
  final int words = RegExp(r"[a-zA-Z']+").allMatches(text).length;
  final int seconds = (words / 2.4).ceil().clamp(2, 60).toInt();
  return '$seconds"';
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDotsBubble extends StatefulWidget {
  const _TypingDotsBubble({required this.label});

  final String label;

  @override
  State<_TypingDotsBubble> createState() => _TypingDotsBubbleState();
}

class _TypingDotsBubbleState extends State<_TypingDotsBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        label: widget.label,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor.withValues(alpha: 0.72)),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TypingDot(opacity: _typingDotOpacity(_controller.value, 0)),
                  const SizedBox(width: 5),
                  _TypingDot(
                    opacity: _typingDotOpacity(_controller.value, 0.42),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double _typingDotOpacity(double value, double offset) {
    final double phase = ((value + offset) % 1) * math.pi * 2;
    return 0.34 + (0.66 * ((math.sin(phase) + 1) / 2));
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: darkGreen,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.review,
    required this.aiNote,
    required this.onRestart,
  });

  final InterviewReview review;
  final String? aiNote;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final int masteryPercent = (review.masteryRatio * 100).round();
    final Color modeColor =
        review.nextRoundMode == InterviewNextRoundMode.review
        ? const Color(0xFFA0622A)
        : darkGreen;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: darkGreen),
              const SizedBox(width: 8),
              const Text(
                '学习状态',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              _TinyBadge(
                label: _practiceFocusShortLabel(review.nextRoundMode),
                color: modeColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LearningMetricRow(
            icon: Icons.check_circle_outline_rounded,
            title: '本轮学会',
            value: '${review.masteredThisRoundCount} 个地道表达',
          ),
          const SizedBox(height: 10),
          _LearningMetricRow(
            icon: Icons.stacked_bar_chart_rounded,
            title: '总掌握进度',
            value:
                '${review.totalMasteredCount} / ${review.totalExpressionCount} · $masteryPercent%',
          ),
          const SizedBox(height: 10),
          _LearningMetricRow(
            icon: Icons.schedule_rounded,
            title: '遗忘曲线',
            value: _reviewDueText(review),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                size: 18,
                color: darkGreen,
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 92,
                child: Text(
                  '当前薄弱标签',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: review.weakTags.isEmpty
                      ? const <Widget>[
                          _TinyBadge(label: '暂无', color: textSecondary),
                        ]
                      : review.weakTags
                            .map(
                              (String tag) =>
                                  _TinyBadge(label: tag, color: darkGreen),
                            )
                            .toList(growable: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: modeColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  review.nextRoundMode == InterviewNextRoundMode.review
                      ? Icons.replay_rounded
                      : Icons.auto_awesome_rounded,
                  size: 18,
                  color: modeColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '下轮重点：${_practiceFocusShortLabel(review.nextRoundMode)}。${review.nextRoundMessage}',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: modeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (aiNote != null && aiNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              aiNote!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.55,
                color: textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('开始下一轮智能练习'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningMetricRow extends StatelessWidget {
  const _LearningMetricRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: darkGreen),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _WikiWriteSummaryPanel extends StatelessWidget {
  const _WikiWriteSummaryPanel({
    required this.summary,
    required this.onOpenWiki,
  });

  final String summary;
  final VoidCallback? onOpenWiki;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5EA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7E5D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_outlined, color: darkGreen, size: 18),
              SizedBox(width: 8),
              Text(
                '写入 Wiki 摘要',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onOpenWiki,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('查看今日计划'),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: Color(0xFFB45445)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
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
              size: 42,
              color: textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
