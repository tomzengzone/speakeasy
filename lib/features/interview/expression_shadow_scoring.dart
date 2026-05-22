import 'dart:math' as math;

import 'package:speakeasy/features/interview/interview_engine.dart';

class ExpressionShadowScoreResult {
  const ExpressionShadowScoreResult({
    required this.totalScore,
    required this.textMatch,
    required this.passed,
    this.pronunciationScore,
  });

  final double totalScore;
  final double textMatch;
  final double? pronunciationScore;
  final bool passed;
}

ExpressionShadowScoreResult scoreExpressionShadowAttempt({
  required String transcript,
  required List<String> targets,
  required double? pronunciationScore,
  bool isSlotReplace = false,
  String practiceMode = '',
  Duration? elapsed,
}) {
  final String resolvedPracticeMode = _resolvedPracticeMode(
    practiceMode: practiceMode,
    isSlotReplace: isSlotReplace,
  );
  final double textMatch = bestExpressionTextMatch(transcript, targets);
  final double textScore = textMatch * 100;
  final double? pronunciation = pronunciationScore?.clamp(0, 100).toDouble();
  final double blendedScore = pronunciation == null
      ? textScore
      : textScore * 0.65 + pronunciation * 0.35;
  final double cappedScore = _capScoreByTextMatch(blendedScore, textMatch);
  final double totalScore = _applyPracticeModeScoreAdjustment(
    score: cappedScore,
    textMatch: textMatch,
    practiceMode: resolvedPracticeMode,
    elapsed: elapsed,
    targets: targets,
  ).clamp(0, 100).toDouble();
  final _PracticeModeThreshold threshold = _thresholdForPracticeMode(
    resolvedPracticeMode,
  );
  final bool passed =
      transcript.trim().isNotEmpty &&
      textMatch >= threshold.minTextMatch &&
      totalScore >= threshold.minTotalScore &&
      _passesPracticeModeTiming(
        practiceMode: resolvedPracticeMode,
        elapsed: elapsed,
        targets: targets,
      );
  return ExpressionShadowScoreResult(
    totalScore: totalScore,
    textMatch: textMatch,
    pronunciationScore: pronunciation,
    passed: passed,
  );
}

double expressionPracticeModeTextThreshold(String practiceMode) {
  return _thresholdForPracticeMode(practiceMode).minTextMatch;
}

String _resolvedPracticeMode({
  required String practiceMode,
  required bool isSlotReplace,
}) {
  final String value = practiceMode.trim();
  if (value.isNotEmpty) {
    return value;
  }
  return isSlotReplace ? 'slotPersonalize' : 'shadow';
}

class _PracticeModeThreshold {
  const _PracticeModeThreshold({
    required this.minTextMatch,
    required this.minTotalScore,
  });

  final double minTextMatch;
  final double minTotalScore;
}

_PracticeModeThreshold _thresholdForPracticeMode(String practiceMode) {
  return switch (practiceMode.trim()) {
    'echoRecall' => const _PracticeModeThreshold(
      minTextMatch: 0.50,
      minTotalScore: 60,
    ),
    'clozeRecall' => const _PracticeModeThreshold(
      minTextMatch: 0.48,
      minTotalScore: 58,
    ),
    'intentRecall' => const _PracticeModeThreshold(
      minTextMatch: 0.42,
      minTotalScore: 52,
    ),
    'cueResponse' => const _PracticeModeThreshold(
      minTextMatch: 0.35,
      minTotalScore: 45,
    ),
    'chunkRecall' => const _PracticeModeThreshold(
      minTextMatch: 0.50,
      minTotalScore: 58,
    ),
    'slotPersonalize' => const _PracticeModeThreshold(
      minTextMatch: 0.35,
      minTotalScore: 45,
    ),
    'mistakeRepair' => const _PracticeModeThreshold(
      minTextMatch: 0.48,
      minTotalScore: 58,
    ),
    'variantParaphrase' => const _PracticeModeThreshold(
      minTextMatch: 0.35,
      minTotalScore: 45,
    ),
    'fluencySprint' => const _PracticeModeThreshold(
      minTextMatch: 0.55,
      minTotalScore: 68,
    ),
    _ => const _PracticeModeThreshold(minTextMatch: 0.55, minTotalScore: 65),
  };
}

double _applyPracticeModeScoreAdjustment({
  required double score,
  required double textMatch,
  required String practiceMode,
  required Duration? elapsed,
  required List<String> targets,
}) {
  if (practiceMode != 'fluencySprint' || elapsed == null || textMatch < 0.55) {
    return score;
  }
  final int elapsedSeconds = elapsed.inSeconds.clamp(1, 180).toInt();
  final int targetSeconds = _fluencyTargetSeconds(targets);
  if (elapsedSeconds <= targetSeconds) {
    return math.min(100, score + 4);
  }
  if (elapsedSeconds <= (targetSeconds * 1.45).ceil()) {
    return score;
  }
  if (elapsedSeconds <= (targetSeconds * 1.9).ceil()) {
    return math.min(score, 82);
  }
  return math.min(score, 70);
}

bool _passesPracticeModeTiming({
  required String practiceMode,
  required Duration? elapsed,
  required List<String> targets,
}) {
  if (practiceMode != 'fluencySprint' || elapsed == null) {
    return true;
  }
  return elapsed.inSeconds <= (_fluencyTargetSeconds(targets) * 1.9).ceil();
}

int _fluencyTargetSeconds(List<String> targets) {
  final Iterable<int> tokenCounts = targets
      .map(tokenizeInterviewWords)
      .map((List<String> tokens) => tokens.length)
      .where((int count) => count > 0);
  final int tokenCount = tokenCounts.isEmpty ? 8 : tokenCounts.reduce(math.max);
  return math.max(5, (tokenCount / 2.2).ceil() + 2);
}

double bestExpressionTextMatch(String transcript, List<String> targets) {
  final String normalizedTranscript = normalizeInterviewText(
    transcript,
  ).toLowerCase();
  final List<String> spokenTokens = tokenizeInterviewWords(transcript);
  if (spokenTokens.isEmpty) {
    return 0;
  }

  double best = 0;
  for (final String target in targets) {
    final String normalizedTarget = normalizeInterviewText(
      target,
    ).toLowerCase();
    final List<String> expectedTokens = tokenizeInterviewWords(target);
    if (expectedTokens.isEmpty) {
      continue;
    }
    if (normalizedTarget.isNotEmpty &&
        normalizedTranscript.contains(normalizedTarget)) {
      best = math.max(best, 1);
      continue;
    }
    best = math.max(
      best,
      _textMatchForTokens(
        spokenTokens: spokenTokens,
        expectedTokens: expectedTokens,
      ),
    );
  }
  return best.clamp(0, 1).toDouble();
}

double _textMatchForTokens({
  required List<String> spokenTokens,
  required List<String> expectedTokens,
}) {
  final Set<String> spoken = spokenTokens.toSet();
  final Set<String> expected = expectedTokens.toSet();
  final int uniqueMatched = expected.where(spoken.contains).length;
  final double uniqueCoverage = uniqueMatched / expected.length;

  final List<String> expectedContent = expectedTokens
      .where((String token) => !_lowValueTokens.contains(token))
      .toSet()
      .toList(growable: false);
  final double contentCoverage = expectedContent.isEmpty
      ? uniqueCoverage
      : expectedContent.where(spoken.contains).length / expectedContent.length;

  final double orderedCoverage =
      _longestCommonSubsequenceLength(spokenTokens, expectedTokens) /
      expectedTokens.length;

  return contentCoverage * 0.45 +
      orderedCoverage * 0.35 +
      uniqueCoverage * 0.20;
}

double _capScoreByTextMatch(double score, double textMatch) {
  if (textMatch < 0.20) {
    return math.min(score, 35);
  }
  if (textMatch < 0.35) {
    return math.min(score, 55);
  }
  if (textMatch < 0.50) {
    return math.min(score, 68);
  }
  return score;
}

int _longestCommonSubsequenceLength(List<String> a, List<String> b) {
  if (a.isEmpty || b.isEmpty) {
    return 0;
  }
  final List<int> previous = List<int>.filled(b.length + 1, 0);
  final List<int> current = List<int>.filled(b.length + 1, 0);
  for (final String spoken in a) {
    for (int index = 0; index < b.length; index += 1) {
      current[index + 1] = spoken == b[index]
          ? previous[index] + 1
          : math.max(previous[index + 1], current[index]);
    }
    for (int index = 0; index < current.length; index += 1) {
      previous[index] = current[index];
      current[index] = 0;
    }
  }
  return previous.last;
}

const Set<String> _lowValueTokens = <String>{
  'a',
  'an',
  'am',
  'and',
  'are',
  'as',
  'at',
  'be',
  'been',
  'but',
  'by',
  'for',
  'from',
  'i',
  "i'd",
  "i'll",
  "i'm",
  "i've",
  'in',
  'is',
  'it',
  "it's",
  'can',
  'could',
  'did',
  'do',
  'does',
  'me',
  'my',
  'of',
  'on',
  'or',
  'our',
  'that',
  'the',
  'this',
  'to',
  'was',
  'we',
  "we're",
  'were',
  'will',
  'with',
  'would',
  'you',
  'your',
};
