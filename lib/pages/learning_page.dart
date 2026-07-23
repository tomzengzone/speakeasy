import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/l10n/l10n.dart';

class LearningPage extends StatefulWidget {
  const LearningPage({
    super.key,
    required this.card,
    required this.onBack,
    this.onComplete,
  });

  final ExpressionCardData card;
  final VoidCallback onBack;
  final VoidCallback? onComplete;

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  static const int _stepCount = 4;

  int _step = 0;
  int? _recordingPhrase;
  int _selectedVariation = 0;
  final Map<int, String> _recordingPaths = <int, String>{};
  final Map<int, PronunciationScore> _scores = <int, PronunciationScore>{};
  AudioService? _audioService;

  static const List<String> _fallbackVariations = <String>[
    'Thanks for joining on short notice.',
    'I\'d like to start with a quick update.',
    'Let me walk you through the current timeline.',
    'First, here is the recovery plan.',
  ];

  List<String> _titles(AppLocalizations l10n) {
    final List<LessonStepData> steps = widget.card.lessonContent?.steps ??
        const <LessonStepData>[];
    if (steps.length >= _stepCount &&
        steps.take(_stepCount).every((LessonStepData step) {
          return step.title.trim().isNotEmpty;
        })) {
      return steps
          .take(_stepCount)
          .map((LessonStepData step) => step.title.trim())
          .toList(growable: false);
    }
    return <String>[
      l10n.learningStepUnderstandScene,
      l10n.learningStepLearn3Phrases,
      l10n.learningStepRepeatAfterMe,
      l10n.learningStepVariationOutput,
    ];
  }

  List<String> _bodies(AppLocalizations l10n) {
    final List<LessonStepData> steps = widget.card.lessonContent?.steps ??
        const <LessonStepData>[];
    if (steps.length >= _stepCount &&
        steps.take(_stepCount).every((LessonStepData step) {
          return step.body.trim().isNotEmpty;
        })) {
      return steps
          .take(_stepCount)
          .map((LessonStepData step) => step.body.trim())
          .toList(growable: false);
    }
    return <String>[
      l10n.learningBodyUnderstandScene,
      l10n.learningBodyLearn3Phrases,
      l10n.learningBodyRepeatAfterMe,
      l10n.learningBodyVariationOutput,
    ];
  }

  List<LessonPhraseData> _phrases(AppLocalizations l10n) {
    final List<LessonPhraseData> phrases = widget.card.lessonContent?.phrases
            .where((LessonPhraseData phrase) => phrase.en.trim().isNotEmpty)
            .toList(growable: false) ??
        const <LessonPhraseData>[];
    if (phrases.isNotEmpty) {
      return phrases;
    }
    return <LessonPhraseData>[
      LessonPhraseData(
        en: 'Good morning, everyone. Thanks for joining.',
        translation: l10n.learningPhraseTranslationMorning,
        note: l10n.phraseNoteMeetingOpening,
      ),
      LessonPhraseData(
        en: 'Let\'s get started.',
        translation: l10n.learningPhraseTranslationStart,
        note: l10n.phraseNoteNaturalPacing,
      ),
      LessonPhraseData(
        en: 'Today, we\'re here to discuss this week\'s priorities.',
        translation: l10n.learningPhraseTranslationPriorities,
        note: l10n.phraseNoteClearPurpose,
      ),
    ];
  }

  String _sceneNote(AppLocalizations l10n) {
    final String? sceneNote = widget.card.lessonContent?.sceneNote?.trim();
    if (sceneNote != null && sceneNote.isNotEmpty) {
      return sceneNote;
    }
    return l10n.understandSceneBeforePractice;
  }

  List<String> _variationOptions() {
    final List<String> variations = widget.card.lessonContent?.variations
            .where((String item) => item.trim().isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    if (variations.isNotEmpty) {
      return variations;
    }
    return _fallbackVariations;
  }

  String _variationPrompt() {
    final String? prompt = widget.card.lessonContent?.variationPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      return prompt;
    }
    return 'Nice to finally ___ you.';
  }

  String _variationHint(AppLocalizations l10n) {
    final String? hint = widget.card.lessonContent?.variationHint?.trim();
    if (hint != null && hint.isNotEmpty) {
      return hint;
    }
    return l10n.chooseSmoothestVariationHint;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioService = AudioServiceScope.of(context);
  }

  void _handleBack() {
    unawaited(_stopLearningPlayback());
    if (_step == 0) {
      widget.onBack();
      return;
    }
    setState(() {
      _step -= 1;
    });
  }

  void _handleNext() {
    unawaited(_stopLearningPlayback());
    if (_step == _stepCount - 1) {
      (widget.onComplete ?? widget.onBack).call();
      return;
    }
    setState(() {
      _step += 1;
    });
  }

  Future<void> _stopLearningPlayback() async {
    await _audioService?.stopPlayback(clearRealtimeBuffer: false);
  }

  @override
  void dispose() {
    unawaited(_stopLearningPlayback());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.card.color;
    final AudioService audioService = AudioServiceScope.of(context);
    final AppLocalizations l10n = context.l10n;
    final List<String> titles = _titles(l10n);
    final List<String> bodies = _bodies(l10n);

    return Material(
      color: appBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E4A2C),
                  Color(0xFF4A7244),
                  Color(0xFF87B076),
                  appBackground,
                ],
                stops: [0, 0.38, 0.72, 1],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _handleBack,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x1FFFFFFF),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.card.title,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.stepProgress(_step + 1, _stepCount),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xCFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LearningProgress(current: _step + 1, total: _stepCount),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.stepProgress(_step + 1, _stepCount),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        titles[_step],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bodies[_step],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildStepContent(color, audioService, l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            decoration: BoxDecoration(
              color: appBackground.withValues(alpha: 0.97),
              border: const Border(top: BorderSide(color: Color(0xFFF0ECE6))),
            ),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleBack,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(l10n.previousStep),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _handleNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _step == _stepCount - 1
                          ? l10n.completeLesson
                          : l10n.nextStep,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    Color color,
    AudioService audioService,
    AppLocalizations l10n,
  ) {
    final List<LessonPhraseData> phrases = _phrases(l10n);
    final List<String> variations = _variationOptions();
    return switch (_step) {
      0 => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5EF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE7DC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.realScenario,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.card.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.card.pattern,
              style: const TextStyle(
                fontSize: 16,
                height: 1.7,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _sceneNote(l10n),
              style: TextStyle(fontSize: 13, height: 1.6, color: textSecondary),
            ),
          ],
        ),
      ),
      1 => Column(
        children: List<Widget>.generate(phrases.length, (int index) {
          final item = phrases[index];
          final String playKey = item.audioUrl?.trim().isNotEmpty == true
              ? item.audioUrl!.trim()
              : 'tts_${item.en.hashCode}';
          final bool playing =
              audioService.isPlaying &&
              audioService.playingUrl != null &&
              audioService.playingUrl == playKey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.en,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.translation,
                          style: const TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.note,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      final String? audioUrl = item.audioUrl?.trim();
                      if (audioUrl != null && audioUrl.isNotEmpty) {
                        audioService.playUrl(audioUrl);
                        return;
                      }
                      audioService.playTts(item.en);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: playing
                          ? color
                          : color.withValues(alpha: 0.12),
                    ),
                    icon: Icon(
                      Icons.volume_up_rounded,
                      size: 16,
                      color: playing ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
      2 => Column(
        children: List<Widget>.generate(phrases.length, (int index) {
          final item = phrases[index];
          final bool recording =
              audioService.isRecording && _recordingPhrase == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () async {
                if (audioService.isRecording && _recordingPhrase == index) {
                  final String? path = await audioService.stopRecording();
                  if (!mounted) return;
                  setState(() {
                    _recordingPhrase = null;
                    if (path != null) _recordingPaths[index] = path;
                  });
                  if (path != null && mounted) {
                    try {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('发音评分暂未接入可信上传流程'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '评分失败: ${error.toString().split(':').last.trim()}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } finally {
                      unawaited(
                        File(path).delete().catchError((Object _) => File(path)),
                      );
                    }
                  }
                } else {
                  setState(() => _recordingPhrase = index);
                  await audioService.startRecording();
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: recording ? color : borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.en,
                        style: const TextStyle(
                          fontSize: 15,
                          color: textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: recording ? color : const Color(0xFFF3F0EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        recording
                            ? Icons.graphic_eq_rounded
                            : Icons.mic_none_rounded,
                        size: 18,
                        color: recording ? Colors.white : textSecondary,
                      ),
                    ),
                    if (_scores[index] != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _ScoreBadge(
                          score: _scores[index]!.overall,
                          color: color,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
      _ => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.14),
              color.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.yourTurn,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _variationPrompt(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(variations.length, (int index) {
                final bool active = _selectedVariation == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedVariation = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? color.withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? color.withValues(alpha: 0.22)
                            : borderColor,
                      ),
                    ),
                    child: Text(
                      variations[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: active ? color : textPrimary,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Text(
              _variationHint(l10n),
              style: TextStyle(
                fontSize: 13,
                height: 1.65,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    };
  }
}

class _LearningProgress extends StatelessWidget {
  const _LearningProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.stepProgress(current, total),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List<Widget>.generate(
              total,
              (int index) => Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: index < current
                        ? Colors.white
                        : const Color(0x3DFFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color bg = score >= 80
        ? const Color(0xFF4A7244)
        : score >= 60
        ? const Color(0xFFA0622A)
        : const Color(0xFFB0404A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$score',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: bg),
      ),
    );
  }
}
