class SceneHistoryTurn {
  const SceneHistoryTurn({required this.role, required this.text});

  final String role;
  final String text;
}

class SceneTurnContract {
  const SceneTurnContract({
    required this.stageLabel,
    required this.questionFocus,
    required this.backgroundFocus,
    required this.learnerTaskEn,
    required this.learnerGoalZh,
    required this.npcTurnSummary,
    required this.npcTurnInstruction,
    this.keywords = const <String>[],
    this.starter = '',
    this.sampleAnswer = '',
    this.confirmedFacts = const <String>[],
    this.mustAsk = const <String>[],
    this.mustAvoid = const <String>[],
  });

  final String stageLabel;
  final String questionFocus;
  final String backgroundFocus;
  final String learnerTaskEn;
  final String learnerGoalZh;
  final String npcTurnSummary;
  final String npcTurnInstruction;
  final List<String> keywords;
  final String starter;
  final String sampleAnswer;
  final List<String> confirmedFacts;
  final List<String> mustAsk;
  final List<String> mustAvoid;

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((dynamic item) => '$item'.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  factory SceneTurnContract.fromJson(Map<String, dynamic> json) {
    return SceneTurnContract(
      stageLabel: (json['stageLabel'] as String? ?? '').trim(),
      questionFocus: (json['questionFocus'] as String? ?? '').trim(),
      backgroundFocus: (json['backgroundFocus'] as String? ?? '').trim(),
      learnerTaskEn: (json['learnerTaskEn'] as String? ?? '').trim(),
      learnerGoalZh: (json['learnerGoalZh'] as String? ?? '').trim(),
      npcTurnSummary: (json['npcTurnSummary'] as String? ?? '').trim(),
      npcTurnInstruction: (json['npcTurnInstruction'] as String? ?? '').trim(),
      keywords: _readStringList(json['keywords']),
      starter: (json['starter'] as String? ?? '').trim(),
      sampleAnswer: (json['sampleAnswer'] as String? ?? '').trim(),
      confirmedFacts: _readStringList(json['confirmedFacts']),
      mustAsk: _readStringList(json['mustAsk']),
      mustAvoid: _readStringList(json['mustAvoid']),
    );
  }
}

class SceneStateSnapshot {
  const SceneStateSnapshot({
    required this.currentStageId,
    required this.currentStageLabel,
    required this.currentStageIndex,
    required this.totalStages,
    this.userTurnCount = 0,
    this.topic = '',
    this.filledFacts = const <String, String>{},
    this.missingFacts = const <String>[],
    this.repairCount = 0,
    this.offTopicCount = 0,
    this.lastUserIntent = '',
    this.stageSatisfied = false,
    this.confidence = 0,
  });

  final String currentStageId;
  final String currentStageLabel;
  final int currentStageIndex;
  final int totalStages;
  final int userTurnCount;
  final String topic;
  final Map<String, String> filledFacts;
  final List<String> missingFacts;
  final int repairCount;
  final int offTopicCount;
  final String lastUserIntent;
  final bool stageSatisfied;
  final double confidence;

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((dynamic item) => '$item'.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, String> _readStringMap(dynamic value) {
    if (value is! Map) {
      return const <String, String>{};
    }
    final Map<String, String> result = <String, String>{};
    value.forEach((dynamic key, dynamic entryValue) {
      final String normalizedKey = '$key'.trim();
      final String normalizedValue = '$entryValue'.trim();
      if (normalizedKey.isEmpty || normalizedValue.isEmpty) {
        return;
      }
      result[normalizedKey] = normalizedValue;
    });
    return result;
  }

  factory SceneStateSnapshot.fromJson(Map<String, dynamic> json) {
    return SceneStateSnapshot(
      currentStageId: (json['currentStageId'] as String? ?? '').trim(),
      currentStageLabel: (json['currentStageLabel'] as String? ?? '').trim(),
      currentStageIndex: (json['currentStageIndex'] as num?)?.toInt() ?? 0,
      totalStages: (json['totalStages'] as num?)?.toInt() ?? 0,
      userTurnCount: (json['userTurnCount'] as num?)?.toInt() ?? 0,
      topic: (json['topic'] as String? ?? '').trim(),
      filledFacts: _readStringMap(json['filledFacts']),
      missingFacts: _readStringList(json['missingFacts']),
      repairCount: (json['repairCount'] as num?)?.toInt() ?? 0,
      offTopicCount: (json['offTopicCount'] as num?)?.toInt() ?? 0,
      lastUserIntent: (json['lastUserIntent'] as String? ?? '').trim(),
      stageSatisfied: json['stageSatisfied'] == true,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PronunciationScore {
  const PronunciationScore({
    required this.overall,
    this.accuracy,
    this.fluency,
    this.completeness,
    this.grammar,
    this.source = '',
  });

  final int overall;
  final int? accuracy;
  final int? fluency;
  final int? completeness;
  final int? grammar;
  final String source;

  PronunciationScore copyWith({
    int? overall,
    int? accuracy,
    int? fluency,
    int? completeness,
    int? grammar,
    String? source,
  }) {
    return PronunciationScore(
      overall: overall ?? this.overall,
      accuracy: accuracy ?? this.accuracy,
      fluency: fluency ?? this.fluency,
      completeness: completeness ?? this.completeness,
      grammar: grammar ?? this.grammar,
      source: source ?? this.source,
    );
  }
}

class SceneFeedbackVoiceTurn {
  const SceneFeedbackVoiceTurn({
    required this.turnIndex,
    required this.text,
    this.audioPath,
  });

  final int turnIndex;
  final String text;
  final String? audioPath;
}

class SceneFeedbackTurnReview {
  const SceneFeedbackTurnReview({
    required this.turnIndex,
    required this.originalText,
    required this.pronunciationScore,
    required this.pronunciationComment,
    required this.grammarComment,
    required this.expressionComment,
    required this.betterExpression,
    this.betterExpressionTranslation,
  });

  final int turnIndex;
  final String originalText;
  final int pronunciationScore;
  final String pronunciationComment;
  final String grammarComment;
  final String expressionComment;
  final String betterExpression;
  final String? betterExpressionTranslation;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'turnIndex': turnIndex,
      'originalText': originalText,
      'pronunciationScore': pronunciationScore,
      'pronunciationComment': pronunciationComment,
      'grammarComment': grammarComment,
      'expressionComment': expressionComment,
      'betterExpression': betterExpression,
      'betterExpressionTranslation': betterExpressionTranslation,
    };
  }

  factory SceneFeedbackTurnReview.fromJson(Map<String, dynamic> json) {
    return SceneFeedbackTurnReview(
      turnIndex: (json['turnIndex'] as num?)?.toInt() ?? 0,
      originalText: (json['originalText'] as String? ?? '').trim(),
      pronunciationScore: (json['pronunciationScore'] as num?)?.toInt() ?? 0,
      pronunciationComment: (json['pronunciationComment'] as String? ?? '')
          .trim(),
      grammarComment: (json['grammarComment'] as String? ?? '').trim(),
      expressionComment: (json['expressionComment'] as String? ?? '').trim(),
      betterExpression: (json['betterExpression'] as String? ?? '').trim(),
      betterExpressionTranslation:
          (json['betterExpressionTranslation'] as String?)?.trim(),
    );
  }
}
