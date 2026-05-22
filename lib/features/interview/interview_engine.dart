import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'package:speakeasy/features/interview/expression_scene_orchestrator.dart';
import 'package:speakeasy/features/interview/interview_models.dart';

const List<String> interviewTags = <String>[
  '自我介绍',
  '经历阐述',
  '优势说明',
  '岗位认知',
  '职业规划',
  '劣势应答',
  '薪资沟通',
  '压力回应',
  '反问提问',
];

const List<String> defaultInterviewStageFlow = <String>[
  'open',
  'self_intro',
  'background',
  'experience_project',
  'strength',
  'role_fit',
  'career_plan',
  'weakness',
  'pressure',
  'salary_optional',
  'candidate_question',
  'wrap_up',
];

const List<String> measurableInterviewStages = <String>[
  'self_intro',
  'background',
  'experience_project',
  'strength',
  'role_fit',
  'career_plan',
  'weakness',
  'pressure',
  'salary_optional',
  'candidate_question',
];

const Map<String, String> stageToPrimaryTag = <String, String>{
  'interview_01': '自我介绍',
  'interview_02': '自我介绍',
  'interview_03': '自我介绍',
  'interview_04': '经历阐述',
  'interview_05': '经历阐述',
  'interview_06': '经历阐述',
  'interview_07': '优势说明',
  'interview_08': '岗位认知',
  'interview_09': '反问提问',
  'interview_10': '反问提问',
  'open': '自我介绍',
  'self_intro': '自我介绍',
  'background': '经历阐述',
  'experience_project': '经历阐述',
  'strength': '优势说明',
  'role_fit': '岗位认知',
  'career_plan': '职业规划',
  'weakness': '劣势应答',
  'pressure': '压力回应',
  'salary_optional': '薪资沟通',
  'candidate_question': '反问提问',
  'wrap_up': '反问提问',
};

const Map<String, List<String>> tagToPracticeStages = <String, List<String>>{
  '自我介绍': <String>['self_intro'],
  '经历阐述': <String>['background', 'experience_project'],
  '优势说明': <String>['strength'],
  '岗位认知': <String>['role_fit'],
  '职业规划': <String>['career_plan'],
  '劣势应答': <String>['weakness'],
  '薪资沟通': <String>['salary_optional'],
  '压力回应': <String>['pressure'],
  '反问提问': <String>['candidate_question'],
};

const Map<String, String> stageLabels = <String, String>{
  'interview_01': '开场感谢',
  'interview_02': '正式寒暄',
  'interview_03': '当前职位',
  'interview_04': '经验领域',
  'interview_05': '项目成就',
  'interview_06': '问题解决',
  'interview_07': '优势说明',
  'interview_08': '公司动机',
  'interview_09': '反向提问',
  'interview_10': '结束致谢',
  'open': '开场',
  'self_intro': '自我介绍',
  'background': '背景经历',
  'experience_project': '项目经历',
  'strength': '优势说明',
  'role_fit': '岗位匹配',
  'career_plan': '职业规划',
  'weakness': '劣势应答',
  'pressure': '压力回应',
  'salary_optional': '薪资沟通',
  'candidate_question': '反问提问',
  'wrap_up': '结束复盘',
};

const Map<String, Map<String, String>>
stageQuestions = <String, Map<String, String>>{
  'interview_01': <String, String>{
    'default':
        'Hi, welcome. Thanks for coming in today. How would you respond at the start of the interview?',
    'simple': 'Welcome. What would you say first?',
    'followup':
        'Could you make that opening response sound a little more natural and positive?',
  },
  'interview_02': <String, String>{
    'default':
        'It is good to meet you. How would you greet the interviewer in a more formal way?',
    'simple': 'How would you say nice to meet you formally?',
    'followup':
        'Could you say that again in a slightly more formal interview style?',
  },
  'interview_03': <String, String>{
    'default':
        'Could you start by telling me what you currently do and where you work?',
    'simple': 'What do you do now, and where do you work?',
    'followup': 'Could you include both your current role and your company?',
  },
  'interview_04': <String, String>{
    'default':
        'Could you add how many years of experience you have and what you specialize in?',
    'simple': 'How many years of experience do you have?',
    'followup':
        'Could you include both your years of experience and your focus area?',
  },
  'interview_05': <String, String>{
    'default':
        'Tell me about one project or achievement you are particularly proud of.',
    'simple': 'Tell me about one project you are proud of.',
    'followup': 'Could you include your action and one concrete result?',
  },
  'interview_06': <String, String>{
    'default':
        'Can you give me an example of a time you improved a process or solved a problem?',
    'simple': 'Tell me about a problem you solved at work.',
    'followup':
        'Could you mention the problem, what you implemented, and the result?',
  },
  'interview_07': <String, String>{
    'default': 'What would you say is one of your key strengths?',
    'simple': 'What is one strength you have?',
    'followup':
        'Could you name one specific strength rather than a general quality?',
  },
  'interview_08': <String, String>{
    'default': 'Why are you interested in our company?',
    'simple': 'Why do you want to work here?',
    'followup':
        'Could you connect your interest to something specific about the company?',
  },
  'interview_09': <String, String>{
    'default':
        'Before we wrap up, what would you like to ask me about this position?',
    'simple': 'Do you have one question about this job?',
    'followup': 'Could you ask one question about success in the role?',
  },
  'interview_10': <String, String>{
    'default':
        'We are wrapping up now. What would you like to say to close the conversation?',
    'simple': 'How would you thank the interviewer at the end?',
    'followup':
        'Could you close with thanks and a positive note about the conversation?',
  },
  'open': <String, String>{
    'default':
        'Hi, thanks for joining today. Short answers are totally fine. Could you start by introducing yourself briefly?',
    'simple': 'Hi. Please introduce yourself in simple English.',
    'followup': 'Thanks. What is your current role right now?',
  },
  'self_intro': <String, String>{
    'default': 'Could you tell me a bit about yourself and what you do now?',
    'simple': 'Who are you, and what do you do now?',
    'followup': 'Could you add your years of experience or your background?',
  },
  'background': <String, String>{
    'default':
        'Could you walk me through your background and one experience that shaped your career?',
    'simple': 'Tell me about your background and one important experience.',
    'followup': 'What was your main responsibility in that role?',
  },
  'experience_project': <String, String>{
    'default':
        'Tell me about one project you\'re proud of. What was the situation, what did you do, and what was the result?',
    'simple':
        'Tell me about one project. What happened, what did you do, and what was the result?',
    'followup': 'What was your specific contribution to that project?',
  },
  'strength': <String, String>{
    'default':
        'What would you say is one of your biggest strengths, and how has it helped you at work?',
    'simple': 'What is one strength you have? Please give one example.',
    'followup': 'Can you give me one quick example that proves that strength?',
  },
  'role_fit': <String, String>{
    'default':
        'Why are you interested in this role, and why do you think you\'re a good fit for it?',
    'simple': 'Why do you want this role, and why do you match it?',
    'followup': 'What part of the job or company excites you most?',
  },
  'career_plan': <String, String>{
    'default':
        'Where do you see yourself in the next two to three years, and how does this role fit that plan?',
    'simple': 'What do you want to do in the next 2 to 3 years?',
    'followup': 'How does this job help you move toward that goal?',
  },
  'weakness': <String, String>{
    'default':
        'What\'s one area you\'re still improving, and what are you doing about it?',
    'simple': 'What is one weakness you are working on now?',
    'followup': 'What specific action have you taken to improve it?',
  },
  'pressure': <String, String>{
    'default':
        'Tell me about a time you were under pressure or received pushback. How did you handle it?',
    'simple': 'Tell me about a stressful situation at work. What did you do?',
    'followup': 'What did you learn from that situation?',
  },
  'salary_optional': <String, String>{
    'default':
        'Before we wrap up, how do you usually think about compensation for a role like this?',
    'simple': 'What are your thoughts on salary for this role?',
    'followup': 'Are you looking at the full package or mainly base salary?',
  },
  'candidate_question': <String, String>{
    'default':
        'What would you like to ask me about the role, the team, or the next step?',
    'simple': 'Do you have a question for me about the role or team?',
    'followup':
        'Would you like to ask about team culture, success metrics, or the next step?',
  },
  'wrap_up': <String, String>{
    'default':
        'Thanks. We\'ll stop here for today. A short review will follow.',
    'simple': 'Thanks. We are done for today.',
    'followup': 'Thanks. We are done for today.',
  },
};

const Map<String, Map<String, Object>> tagHints = <String, Map<String, Object>>{
  '自我介绍': <String, Object>{
    'keywords': <String>['name', 'current role', 'years', 'background'],
    'framework': 'who you are -> what you do now -> one reason you\'re here',
    'minimal': 'I\'m [role] with [X] years.',
  },
  '经历阐述': <String, Object>{
    'keywords': <String>['situation', 'task', 'action', 'result'],
    'framework': 'background -> your task -> what you did -> result',
    'minimal': 'I led [task] and got [result].',
  },
  '优势说明': <String, Object>{
    'keywords': <String>['strength', 'example', 'impact', 'team'],
    'framework': 'one strength -> one quick example -> why it helped',
    'minimal': 'My strength is [X]. For example...',
  },
  '岗位认知': <String, Object>{
    'keywords': <String>['role', 'fit', 'company', 'motivation'],
    'framework': 'role focus -> why it fits you -> why this company',
    'minimal': 'This role fits me because...',
  },
  '职业规划': <String, Object>{
    'keywords': <String>['2-3 years', 'grow', 'expertise', 'impact'],
    'framework': 'near-term growth -> longer direction -> how this role helps',
    'minimal': 'In 2 years, I want to...',
  },
  '劣势应答': <String, Object>{
    'keywords': <String>['weakness', 'improving', 'action', 'progress'],
    'framework': 'real weakness -> action you\'re taking -> progress so far',
    'minimal': 'I\'m improving [X] by [action].',
  },
  '薪资沟通': <String, Object>{
    'keywords': <String>['salary range', 'package', 'flexible', 'target'],
    'framework': 'stay open -> align on range -> mention full package',
    'minimal': 'I\'m open, but I\'m targeting [range].',
  },
  '压力回应': <String, Object>{
    'keywords': <String>['fair question', 'pressure', 'approach', 'lesson'],
    'framework': 'acknowledge -> explain your approach -> action -> lesson',
    'minimal': 'That\'s fair. Here\'s how I handled it.',
  },
  '反问提问': <String, Object>{
    'keywords': <String>['team', 'success', 'challenge', 'next step'],
    'framework': 'team culture -> success metrics -> challenges or next step',
    'minimal': 'How do you measure success here?',
  },
};

const Map<String, List<String>> tagRuleFeatures = <String, List<String>>{
  '自我介绍': <String>[
    'i\'m',
    'my name is',
    'years of experience',
    'based in',
    'my background is',
    'i specialize in',
    'currently',
  ],
  '经历阐述': <String>[
    'in my last role',
    'i was responsible for',
    'project',
    'i led',
    'the result was',
    'my task was',
    'what i did was',
    'we managed to',
  ],
  '优势说明': <String>[
    'my biggest strength',
    'i\'m good at',
    'i shine',
    'people come to me',
    'detail-oriented',
    'ownership',
    'strong communicator',
  ],
  '岗位认知': <String>[
    'job description',
    'this role',
    'good fit',
    'the reason i applied',
    'what excites me',
    'company',
    'natural next step',
  ],
  '职业规划': <String>[
    'next 2-3 years',
    'long-term goal',
    'leadership role',
    'career path',
    'grow as',
    'impact',
    'stepping stone',
  ],
  '劣势应答': <String>[
    'working on',
    'used to struggle',
    'improving',
    'weakness',
    'not my strongest suit',
    'i\'ve started to',
    'what i\'m doing about it',
  ],
  '薪资沟通': <String>[
    'salary range',
    'compensation',
    'package',
    'bonus',
    'equity',
    'reasonable increase',
    'negotiation',
  ],
  '压力回应': <String>[
    'that\'s fair',
    'let me address',
    'full picture',
    'honest take',
    'under pressure',
    'pushback',
    'reframe that',
  ],
  '反问提问': <String>[
    'typical day',
    'team culture',
    'measure success',
    'career path',
    'next step',
    'management style',
    'priorities',
  ],
};

const List<String> stuckMarkers = <String>[
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

const String interviewSystemPrompt = '''
You are an AI English interview coach acting as a realistic but supportive interviewer.

Primary goal:
Help the user practice spoken-style English for job interviews by getting them to produce their own answers. Do not give the user a full answer unless the interaction mode explicitly switches to review mode after the user has already attempted an answer.

Role behavior:
- Stay in interviewer mode during the interview round.
- Ask one interview question at a time.
- Follow a coherent interview flow from opening to wrap-up.
- Be beginner-friendly and patient.
- Prioritize helping the user speak, not testing grammar perfection.
- Behave like a calm private speaking coach: acknowledge one useful part, fix one high-value issue, then invite a retry when coaching is needed.
- Use the scene Wiki coach context when available: rubric, coach moves, speech focus, realistic contexts, and personalization cues.
- Do not overload the user with long explanations while the interview is in progress.
- Do not praise every answer mechanically.
- Do not feed polished model answers before the user attempts.
- Do not turn the interview into an English lesson too early.

Questioning rules:
- Ask concise, natural interview questions.
- Adapt the next question based on the user's previous answer.
- If the user answer is too short, ask one focused follow-up question.
- If the user seems stuck, do not give the answer immediately. Use the hint ladder.
- If the user mixes Chinese and English, accept it and guide them back toward simple English.

Response style:
- warm, brief, direct
- one question or one hint at a time
- spoken-English friendly
''';

final RegExp _chinesePattern = RegExp(r'[\u4e00-\u9fff]');
final RegExp _wordPattern = RegExp(r"[A-Za-z']+");

const String _interviewSceneCatalogAssetPath =
    'assets/data/interview_scene_catalog.json';
const String _legacyInterviewSceneGraphAssetPath =
    'assets/data/interview_scene_wiki.json';

Future<String> _loadInterviewAssetString(String assetPath) async {
  final ByteData data = await rootBundle.load(assetPath);
  return utf8.decode(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}

Future<InterviewSceneCatalog> loadInterviewSceneCatalog() async {
  final String raw = await _loadInterviewAssetString(
    _interviewSceneCatalogAssetPath,
  );
  return InterviewSceneCatalog.fromJson(
    jsonDecode(raw) as Map<String, dynamic>,
  );
}

Future<InterviewSceneGraph> loadInterviewSceneGraph({
  String sceneId = defaultInterviewSceneId,
}) async {
  String assetPath = _legacyInterviewSceneGraphAssetPath;
  try {
    final InterviewSceneCatalog catalog = await loadInterviewSceneCatalog();
    final InterviewSceneCatalogEntry? entry = catalog.entryById(sceneId);
    if (entry != null && entry.assetPath.isNotEmpty) {
      assetPath = entry.assetPath;
    }
  } catch (_) {
    if (sceneId.trim().isNotEmpty &&
        sceneId.trim() != defaultInterviewSceneId) {
      rethrow;
    }
  }
  final String raw = await _loadInterviewAssetString(assetPath);
  return InterviewSceneGraph.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Future<InterviewLibrary> loadInterviewLibrary({
  String sceneId = defaultInterviewSceneId,
}) async {
  final InterviewSceneGraph graph = await loadInterviewSceneGraph(
    sceneId: sceneId,
  );
  return graph.toLibrary();
}

String normalizeInterviewText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

List<String> tokenizeInterviewWords(String value) {
  return _wordPattern
      .allMatches(value.toLowerCase())
      .map((RegExpMatch match) => match.group(0)!)
      .toList(growable: false);
}

int chineseCharCount(String value) {
  return _chinesePattern.allMatches(value).length;
}

double languageMixRatio(String value) {
  final int chineseCount = chineseCharCount(value);
  final int englishCount = tokenizeInterviewWords(value).length;
  final int total = chineseCount + englishCount;
  if (total == 0) {
    return 0;
  }
  return double.parse((chineseCount / total).toStringAsFixed(4));
}

bool expressionReproduced({
  required String expressionText,
  required String userText,
}) {
  final List<String> alternatives = expressionText
      .split(RegExp(r'\s+/\s+'))
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);
  if (alternatives.length > 1) {
    return alternatives.any(
      (String value) =>
          expressionReproduced(expressionText: value, userText: userText),
    );
  }
  final String target = _normalizeExpressionForMatch(expressionText);
  final String answer = _normalizeExpressionForMatch(userText);
  if (target.isEmpty || answer.isEmpty) {
    return false;
  }
  if (answer.contains(target)) {
    return true;
  }
  final Set<String> targetTokens = _significantExpressionTokens(target);
  if (targetTokens.isEmpty) {
    return false;
  }
  final Set<String> answerTokens = _expressionAnswerTokens(answer);
  if (answerTokens.isEmpty) {
    return false;
  }
  final int hits = targetTokens.intersection(answerTokens).length;
  final double coverage = hits / targetTokens.length;
  if (coverage >= 0.6) {
    return true;
  }
  return targetTokens.length >= 4 && hits >= 3 && coverage >= 0.55;
}

class ExpressionMasteryJudge {
  const ExpressionMasteryJudge();

  InterviewExpressionMasteryResult evaluate({
    required InterviewExpression expression,
    required String userText,
    InterviewExpressionNode? node,
    String question = '',
  }) {
    final String answer = _normalizeExpressionForMatch(userText);
    final String normalizedQuestion = _normalizeExpressionForMatch(question);
    if (answer.isEmpty) {
      return const InterviewExpressionMasteryResult(
        status: InterviewExpressionMasteryStatus.missed,
        confidence: 0.95,
        reason: 'empty answer',
      );
    }
    final List<String> variants = <String>[
      if (node == null) expression.text else ...node.reproducibleTexts,
    ].where((String value) => value.trim().isNotEmpty).toList(growable: false);
    for (final String variant in variants) {
      if (expressionReproduced(expressionText: variant, userText: userText)) {
        return InterviewExpressionMasteryResult(
          status: InterviewExpressionMasteryStatus.mastered,
          confidence: 0.9,
          matchedVariant: variant,
          reason: 'matched target expression or expected variant',
        );
      }
    }

    if (_looksLikeQuestion(answer) && !_targetIsCandidateQuestion(expression)) {
      return const InterviewExpressionMasteryResult(
        status: InterviewExpressionMasteryStatus.missed,
        confidence: 0.92,
        reason: 'answer is an interviewer-style question',
      );
    }
    if (_looksLikeEcho(answer, normalizedQuestion)) {
      return const InterviewExpressionMasteryResult(
        status: InterviewExpressionMasteryStatus.missed,
        confidence: 0.95,
        reason: 'answer echoes the interviewer question',
      );
    }

    final Set<_CoreExpressionMove> requiredMoves = _coreMovesFor(
      expression: expression,
      node: node,
    );
    final Set<_CoreExpressionMove> hitMoves = requiredMoves
        .where((_CoreExpressionMove move) => _answerHasMove(answer, move))
        .toSet();
    final List<String> missingMoves = requiredMoves
        .difference(hitMoves)
        .map((_CoreExpressionMove move) => move.label)
        .toList(growable: false);
    final bool intentMatched = _intentMatched(
      expression: expression,
      node: node,
      answer: answer,
      hitMoves: hitMoves,
    );

    if (requiredMoves.isNotEmpty &&
        missingMoves.isEmpty &&
        (intentMatched || hitMoves.length >= 2)) {
      return InterviewExpressionMasteryResult(
        status: InterviewExpressionMasteryStatus.mastered,
        confidence: 0.84,
        missingCoreMoves: missingMoves,
        reason: 'matched intent and core expression moves',
      );
    }

    if (intentMatched || hitMoves.isNotEmpty) {
      final double confidence = (0.48 + hitMoves.length * 0.12).clamp(
        0.48,
        0.74,
      );
      return InterviewExpressionMasteryResult(
        status: InterviewExpressionMasteryStatus.nearMiss,
        confidence: confidence,
        missingCoreMoves: missingMoves,
        reason: intentMatched
            ? 'matched intent but missed key expression structure'
            : 'matched part of the target expression structure',
      );
    }

    return InterviewExpressionMasteryResult(
      status: InterviewExpressionMasteryStatus.missed,
      confidence: 0.82,
      missingCoreMoves: missingMoves,
      reason: 'did not match intent or core expression structure',
    );
  }

  bool _looksLikeQuestion(String answer) {
    return answer.endsWith('?') ||
        RegExp(
          r'^(what|which|where|when|why|how|do|does|did|can|could|would|will|are|is|tell|give)\b',
        ).hasMatch(answer);
  }

  bool _targetIsCandidateQuestion(InterviewExpression expression) {
    final String text = expression.text.toLowerCase();
    return expression.tag == '反问提问' ||
        text.endsWith('?') ||
        text.contains('could you tell') ||
        text.contains('what are the next steps') ||
        text.contains('what does a normal day');
  }

  bool _looksLikeEcho(String answer, String question) {
    if (question.isEmpty || answer.length < 12) {
      return false;
    }
    if (answer == question ||
        question.contains(answer) ||
        answer.contains(question)) {
      return true;
    }
    final Set<String> answerTokens = _expressionAnswerTokens(
      answer,
    ).where((String token) => token.length > 3).toSet();
    final Set<String> questionTokens = _expressionAnswerTokens(
      question,
    ).where((String token) => token.length > 3).toSet();
    if (answerTokens.length < 4 || questionTokens.length < 4) {
      return false;
    }
    return answerTokens.intersection(questionTokens).length /
            answerTokens.length >=
        0.72;
  }

  Set<_CoreExpressionMove> _coreMovesFor({
    required InterviewExpression expression,
    InterviewExpressionNode? node,
  }) {
    final String text = _normalizeExpressionForMatch(
      <String>[
        expression.text,
        ?node?.targetText,
        ...?node?.expectedVariants.map(
          (InterviewExpectedVariant item) => item.text,
        ),
      ].join(' '),
    );
    final Set<_CoreExpressionMove> moves = <_CoreExpressionMove>{};
    void addIf(bool condition, _CoreExpressionMove move) {
      if (condition) {
        moves.add(move);
      }
    }

    addIf(
      RegExp(r'\b(thank|thanks|appreciate)\b').hasMatch(text),
      _CoreExpressionMove.gratitude,
    );
    addIf(
      RegExp(
        r'\b(excited|happy|glad|thrilled|look forward|enjoy)\b',
      ).hasMatch(text),
      _CoreExpressionMove.positiveInterest,
    );
    addIf(
      RegExp(
        r'\b(currently|working|work as|senior|designer|engineer|at)\b',
      ).hasMatch(text),
      _CoreExpressionMove.currentRole,
    );
    addIf(text.contains('based in'), _CoreExpressionMove.location);
    addIf(
      text.contains('years of experience') || text.contains('experience in'),
      _CoreExpressionMove.experience,
    );
    addIf(
      RegExp(
        r'\b(project|achievement|proud|led|deliver|finish)\b',
      ).hasMatch(text),
      _CoreExpressionMove.project,
    );
    addIf(
      RegExp(
        r'\b(problem|solve|improve|workflow|faster|reduce)\b',
      ).hasMatch(text),
      _CoreExpressionMove.problemSolving,
    );
    addIf(
      RegExp(
        r'\b(strength|good at|ability|strongest|communicate)\b',
      ).hasMatch(text),
      _CoreExpressionMove.strength,
    );
    addIf(
      RegExp(r'\b(pressure|deadline|calm|focused|stress)\b').hasMatch(text),
      _CoreExpressionMove.pressure,
    );
    addIf(
      RegExp(
        r'\b(next role|grow|learn more|professional|looking for)\b',
      ).hasMatch(text),
      _CoreExpressionMove.growthMotivation,
    );
    addIf(
      RegExp(r'\b(five years|leadership|team leader|mentor)\b').hasMatch(text),
      _CoreExpressionMove.careerPlan,
    );
    addIf(
      RegExp(
        r'\b(next steps|hiring process|normal day|responsibilities)\b',
      ).hasMatch(text),
      _CoreExpressionMove.candidateQuestion,
    );

    return moves;
  }

  bool _answerHasMove(String answer, _CoreExpressionMove move) {
    return switch (move) {
      _CoreExpressionMove.gratitude => RegExp(
        r'\b(thank|thanks|appreciate)\b',
      ).hasMatch(answer),
      _CoreExpressionMove.positiveInterest => RegExp(
        r'\b(excited|happy|glad|thrilled|looking forward|enjoy)\b',
      ).hasMatch(answer),
      _CoreExpressionMove.currentRole => RegExp(
        r'\b(currently|working|work|role|designer|engineer|manager|at)\b',
      ).hasMatch(answer),
      _CoreExpressionMove.location => answer.contains('based in'),
      _CoreExpressionMove.experience => RegExp(
        r'\b(years?|experience|speciali[sz]e|background)\b',
      ).hasMatch(answer),
      _CoreExpressionMove.project => RegExp(
        r'\b(project|achievement|proud|led|delivered|finish|launched)\b',
      ).hasMatch(answer),
      _CoreExpressionMove.problemSolving => RegExp(
        r'\b(problem|solv|improv|workflow|faster|reduced?|bottleneck)\b',
      ).hasMatch(answer),
      _CoreExpressionMove.strength => RegExp(
        r'\b(strength|good at|strong|ability|communicat|explain)\b',
      ).hasMatch(answer),
      _CoreExpressionMove.pressure => RegExp(
        r'\b(pressure|deadline|calm|focused|stress|pushback)\b',
      ).hasMatch(answer),
      _CoreExpressionMove.growthMotivation => RegExp(
        r'\b(grow|learn|next role|looking for|apply my skills)\b',
      ).hasMatch(answer),
      _CoreExpressionMove.careerPlan => RegExp(
        r'\b(five years|leadership|leader|mentor|responsibilit)\b',
      ).hasMatch(answer),
      _CoreExpressionMove.candidateQuestion => RegExp(
        r'\b(next steps|hiring process|normal day|responsibilit|could you tell)\b',
      ).hasMatch(answer),
    };
  }

  bool _intentMatched({
    required InterviewExpression expression,
    required InterviewExpressionNode? node,
    required String answer,
    required Set<_CoreExpressionMove> hitMoves,
  }) {
    if (hitMoves.isNotEmpty) {
      return true;
    }
    final String intent = _normalizeExpressionForMatch(
      <String>[
        expression.tag,
        expression.useCase,
        ?node?.intent,
        ?node?.meaning,
        ?node?.naturalTiming,
        ?node?.question,
      ].join(' '),
    );
    final Set<String> intentTokens = _significantExpressionTokens(
      intent,
    ).where((String token) => token.length > 3).toSet();
    final Set<String> answerTokens = _expressionAnswerTokens(
      answer,
    ).where((String token) => token.length > 3).toSet();
    if (intentTokens.isEmpty || answerTokens.isEmpty) {
      return false;
    }
    final int hits = intentTokens.intersection(answerTokens).length;
    return hits >= 2 || hits / intentTokens.length >= 0.34;
  }
}

enum _CoreExpressionMove {
  gratitude('gratitude'),
  positiveInterest('positive interest'),
  currentRole('current role'),
  location('location'),
  experience('experience'),
  project('project or achievement'),
  problemSolving('problem solving'),
  strength('strength'),
  pressure('pressure handling'),
  growthMotivation('growth motivation'),
  careerPlan('career plan'),
  candidateQuestion('candidate question');

  const _CoreExpressionMove(this.label);

  final String label;
}

String _normalizeExpressionForMatch(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r"\bi'm\b"), 'i am')
      .replaceAll(RegExp(r"\byou're\b"), 'you are')
      .replaceAll(RegExp(r"\bwe're\b"), 'we are')
      .replaceAll(RegExp(r"\bthey're\b"), 'they are')
      .replaceAll(RegExp(r"\bi've\b"), 'i have')
      .replaceAll(RegExp(r"\bwe've\b"), 'we have')
      .replaceAll(RegExp(r"\bi'd\b"), 'i would')
      .replaceAll(RegExp(r"\bi'll\b"), 'i will')
      .replaceAll(RegExp(r"\bthat's\b"), 'that is')
      .replaceAll(RegExp(r"\bwhat's\b"), 'what is')
      .replaceAll(RegExp(r"\bdon't\b"), 'do not')
      .replaceAll(RegExp(r"\bcan't\b"), 'cannot')
      .replaceAll(RegExp(r'\[[^\]]+\]'), ' ')
      .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Set<String> _significantExpressionTokens(String value) {
  const Set<String> stopWords = <String>{
    'a',
    'an',
    'the',
    'and',
    'or',
    'to',
    'of',
    'in',
    'on',
    'for',
    'with',
    'by',
    'at',
    'is',
    'are',
    'am',
    'be',
    'been',
    'was',
    'were',
    'it',
    'this',
    'that',
    'i',
    'you',
    'we',
    'my',
    'me',
    'our',
    'your',
    'about',
    'as',
    'do',
    'does',
    'did',
    'from',
    'so',
    'if',
    'but',
    'here',
    'there',
  };
  final List<String> tokens = tokenizeInterviewWords(value)
      .where((String token) => !stopWords.contains(token))
      .map(_stemExpressionToken)
      .where((String token) => token.isNotEmpty && !stopWords.contains(token))
      .toList(growable: false);
  if (tokens.length >= 2) {
    return tokens.toSet();
  }
  return tokenizeInterviewWords(
    value,
  ).map(_stemExpressionToken).where((String token) => token.isNotEmpty).toSet();
}

Set<String> _expressionAnswerTokens(String value) {
  return tokenizeInterviewWords(
    value,
  ).map(_stemExpressionToken).where((String token) => token.isNotEmpty).toSet();
}

String _stemExpressionToken(String token) {
  if (token.length > 5 && token.endsWith('ies')) {
    return '${token.substring(0, token.length - 3)}y';
  }
  if (token.length > 5 && token.endsWith('ing')) {
    return token.substring(0, token.length - 3);
  }
  if (token.length > 4 && token.endsWith('ed')) {
    final String base = token.substring(0, token.length - 2);
    if (base.endsWith('g') || base.endsWith('s') || base.endsWith('t')) {
      return '${base}e';
    }
    return base;
  }
  if (token.length > 4 && token.endsWith('s')) {
    return token.substring(0, token.length - 1);
  }
  return token;
}

String questionForStage(String stage, {bool simplified = false}) {
  final Map<String, String> questions =
      stageQuestions[stage] ?? stageQuestions['open']!;
  return simplified
      ? questions['simple'] ?? questions['default']!
      : questions['default']!;
}

String followupForStage(String stage, {bool simplified = false}) {
  final Map<String, String> questions =
      stageQuestions[stage] ?? stageQuestions['open']!;
  return simplified
      ? questions['simple'] ?? questions['followup']!
      : questions['followup']!;
}

class InterviewPracticeEngine {
  InterviewPracticeEngine({
    required InterviewLibrary library,
    InterviewSceneGraph? sceneGraph,
  }) : _library = library,
       _sceneGraph = sceneGraph,
       _matcher = _InterviewIntentMatcher(library);

  final InterviewLibrary _library;
  final InterviewSceneGraph? _sceneGraph;
  final _InterviewIntentMatcher _matcher;
  final ExpressionMasteryJudge _masteryJudge = const ExpressionMasteryJudge();
  final ExpressionSceneOrchestrator _sceneOrchestrator =
      const ExpressionSceneOrchestrator();

  InterviewExpressionNode? _nodeForStage(String stage) {
    return _sceneGraph?.nodeById(stage);
  }

  InterviewExpressionNode? _nodeForExpression(InterviewExpression expression) {
    return _sceneGraph?.nodeById(expression.id);
  }

  ExpressionSceneNode? _expressionSceneNodeForStage(String stage) {
    final InterviewExpressionNode? node = _nodeForStage(stage);
    return node == null ? null : ExpressionSceneNode.fromInterviewNode(node);
  }

  String _tagForStage(String stage) {
    return _nodeForStage(stage)?.tag ?? stageToPrimaryTag[stage] ?? '自我介绍';
  }

  String _questionForStage(String stage, {bool simplified = false}) {
    final InterviewExpressionNode? node = _nodeForStage(stage);
    if (node != null) {
      if (simplified) {
        return stageQuestions[stage]?['simple'] ?? node.question;
      }
      return node.question.isNotEmpty ? node.question : questionForStage(stage);
    }
    return questionForStage(stage, simplified: simplified);
  }

  String _followupForStage(String stage, {bool simplified = false}) {
    final InterviewExpressionNode? node = _nodeForStage(stage);
    if (node != null) {
      if (simplified) {
        return stageQuestions[stage]?['simple'] ?? node.followupQuestion;
      }
      return node.followupQuestion.isNotEmpty
          ? node.followupQuestion
          : followupForStage(stage);
    }
    return followupForStage(stage, simplified: simplified);
  }

  InterviewTurnAnalysis analyzeTurn({
    required String stage,
    required String userText,
  }) {
    final String activeStage = stage == 'open' ? 'self_intro' : stage;
    return _matcher.match(activeStage, userText);
  }

  InterviewExpressionMasteryResult evaluateExpressionMastery({
    required InterviewExpression expression,
    required String userText,
    String question = '',
  }) {
    return _expressionMasteryResult(
      expression: expression,
      userText: userText,
      question: question,
    );
  }

  InterviewExpressionMasteryResult _expressionMasteryResult({
    required InterviewExpression expression,
    required String userText,
    String question = '',
    Map<String, InterviewExpressionMasteryResult> overrides =
        const <String, InterviewExpressionMasteryResult>{},
  }) {
    final InterviewExpressionMasteryResult? override = overrides[expression.id];
    if (override != null) {
      return override;
    }
    final InterviewExpressionNode? node = _nodeForExpression(expression);
    return _masteryJudge.evaluate(
      expression: expression,
      userText: userText,
      node: node,
      question: question,
    );
  }

  InterviewNextRoundMode roundModeForMasteredExpressions(
    List<InterviewPersonalWikiExpression> masteredWikiExpressions, {
    String targetLevel = 'beginner',
  }) {
    final List<InterviewExpression> activeExpressions =
        _expressionsForTargetLevel(targetLevel);
    final int totalExpressionCount = activeExpressions
        .where((InterviewExpression item) => item.id.isNotEmpty)
        .length;
    if (totalExpressionCount == 0) {
      return InterviewNextRoundMode.newLesson;
    }
    final Set<String> libraryExpressionIds = activeExpressions
        .map((InterviewExpression item) => item.id)
        .where((String id) => id.isNotEmpty)
        .toSet();
    final int masteredCount = masteredWikiExpressions
        .map((InterviewPersonalWikiExpression item) => item.sourceExpressionId)
        .where(libraryExpressionIds.contains)
        .toSet()
        .length;
    final List<InterviewPersonalWikiExpression> activeMasteredExpressions =
        masteredWikiExpressions
            .where(
              (InterviewPersonalWikiExpression item) =>
                  libraryExpressionIds.contains(item.sourceExpressionId) ||
                  libraryExpressionIds.contains(item.sourceNodeId),
            )
            .toList(growable: false);
    if (masteredCount == 0) {
      return InterviewNextRoundMode.newLesson;
    }
    if (_dueReviewWikiExpressions(activeMasteredExpressions).isNotEmpty) {
      return InterviewNextRoundMode.review;
    }
    if (masteredCount < 3) {
      return InterviewNextRoundMode.newLesson;
    }
    final double masteryRatio = masteredCount / totalExpressionCount;
    final List<InterviewPersonalWikiExpression> reviewQueue =
        _rankedReviewWikiExpressions(activeMasteredExpressions);
    if (masteryRatio < 0.7 &&
        reviewQueue.isNotEmpty &&
        _reviewUrgencyScore(reviewQueue.first, DateTime.now()) >= 0.85) {
      return InterviewNextRoundMode.review;
    }
    return InterviewNextRoundMode.newLesson;
  }

  List<InterviewExpression> _expressionsForTargetLevel(String targetLevel) {
    final String normalizedLevel = targetLevel.trim().isEmpty
        ? 'beginner'
        : targetLevel.trim();
    final List<InterviewExpression> exactLevel = _library.expressions
        .where(
          (InterviewExpression item) =>
              item.id.isNotEmpty && item.level == normalizedLevel,
        )
        .toList(growable: false);
    if (exactLevel.isNotEmpty) {
      return exactLevel;
    }
    return _library.expressions
        .where((InterviewExpression item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  List<InterviewPersonalWikiExpression> _dueReviewWikiExpressions(
    List<InterviewPersonalWikiExpression> masteredWikiExpressions, {
    DateTime? now,
  }) {
    final DateTime referenceTime = now ?? DateTime.now();
    return _rankedReviewWikiExpressions(
          masteredWikiExpressions,
          now: referenceTime,
        )
        .where(
          (InterviewPersonalWikiExpression item) =>
              !item.nextReviewAt.isAfter(referenceTime),
        )
        .toList(growable: false);
  }

  List<InterviewPersonalWikiExpression> _rankedReviewWikiExpressions(
    List<InterviewPersonalWikiExpression> masteredWikiExpressions, {
    DateTime? now,
  }) {
    final DateTime referenceTime = now ?? DateTime.now();
    final Set<String> libraryExpressionIds = _library.expressions
        .map((InterviewExpression item) => item.id)
        .where((String id) => id.isNotEmpty)
        .toSet();
    final List<InterviewPersonalWikiExpression> candidates =
        masteredWikiExpressions
            .where(
              (InterviewPersonalWikiExpression item) =>
                  item.text.isNotEmpty &&
                  libraryExpressionIds.contains(item.sourceExpressionId),
            )
            .toList(growable: false);
    candidates.sort((
      InterviewPersonalWikiExpression a,
      InterviewPersonalWikiExpression b,
    ) {
      final int scoreCompare = _reviewUrgencyScore(
        b,
        referenceTime,
      ).compareTo(_reviewUrgencyScore(a, referenceTime));
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.nextReviewAt.compareTo(b.nextReviewAt);
    });
    return candidates;
  }

  double _reviewUrgencyScore(
    InterviewPersonalWikiExpression expression,
    DateTime now,
  ) {
    final int intervalHours = math.max(
      1,
      expression.nextReviewAt.difference(expression.lastReviewedAt).inHours,
    );
    final int elapsedHours = math.max(
      0,
      now.difference(expression.lastReviewedAt).inHours,
    );
    final int overdueHours = math.max(
      0,
      now.difference(expression.nextReviewAt).inHours,
    );
    final double intervalRatio = elapsedHours / intervalHours;
    final double overdueBoost = overdueHours / 24;
    final double lowReviewBoost = 1 / (expression.reviewCount + 1);
    return intervalRatio + overdueBoost + lowReviewBoost;
  }

  String openingQuestionForSession(InterviewPracticeSession session) {
    final ExpressionSceneNode? sceneNode = _expressionSceneNodeForStage(
      session.currentStage,
    );
    if (sceneNode != null) {
      return _sceneOrchestrator.fallbackQuestionFor(
        sceneNode,
        openingType: ExpressionSceneOpeningType.coldStart,
      );
    }
    final String baseQuestion = _questionForStage(
      session.currentStage,
      simplified: session.simplifiedMode,
    );
    if (session.stageIndex == 0 && session.currentStage != 'open') {
      return baseQuestion;
    }
    return baseQuestion;
  }

  InterviewQuestionPlan openingQuestionPlanForSession({
    required InterviewPracticeSession session,
    required List<InterviewPersonalWikiExpression> masteredWikiExpressions,
  }) {
    final String stage = session.currentStage;
    final String tag = _tagForStage(stage);
    final InterviewExpression? target = session.stageExpressionTargets[stage];
    final bool hasDueReview = _dueReviewWikiExpressions(
      masteredWikiExpressions,
    ).isNotEmpty;
    final String fallback = openingQuestionForSession(session);
    final ExpressionSceneNode? sceneNode = _expressionSceneNodeForStage(stage);
    if (sceneNode != null) {
      final ExpressionSceneTurnPlan plan = _sceneOrchestrator.openingPlan(
        node: sceneNode,
        mode: session.roundMode == InterviewNextRoundMode.review
            ? ExpressionScenePracticeMode.review
            : ExpressionScenePracticeMode.newLesson,
        openingType: ExpressionSceneOpeningType.coldStart,
        hasLearnerHistory: masteredWikiExpressions.isNotEmpty,
        hasDueReview: hasDueReview,
      );
      return InterviewQuestionPlan(
        action: plan.action,
        stage: stage,
        questionIntent: plan.questionIntent,
        mustAskAbout: plan.mustAskAbout,
        localFallbackQuestion: plan.localFallbackQuestion,
        practiceFocus: plan.practiceFocus,
        predictedTag: plan.predictedTag,
        targetExpression: target,
      );
    }
    final String action = hasDueReview && target != null
        ? 'warm_start_due_review'
        : masteredWikiExpressions.isEmpty
        ? 'cold_start_opening'
        : session.roundMode == InterviewNextRoundMode.review && target != null
        ? 'warm_start_due_review'
        : target != null
        ? 'expand_new_expression'
        : 'personalized_warm_start';
    return InterviewQuestionPlan(
      action: action,
      stage: stage,
      questionIntent: _questionIntentForAction(
        action: action,
        stage: stage,
        tag: tag,
      ),
      mustAskAbout: _mustAskAboutForStage(stage),
      localFallbackQuestion: fallback,
      practiceFocus: _practiceFocusFor(session.roundMode),
      predictedTag: tag,
      targetExpression: target,
    );
  }

  InterviewPracticeSession startSession({
    required String userId,
    String jobFamily = 'general',
    String mode = 'full_mock',
    String userTier = 'newbie',
    String targetLevel = 'beginner',
    InterviewNextRoundMode roundMode = InterviewNextRoundMode.newLesson,
    List<InterviewPersonalWikiExpression> masteredWikiExpressions =
        const <InterviewPersonalWikiExpression>[],
    List<InterviewExpressionLearningProgress> preparedLearningProgress =
        const <InterviewExpressionLearningProgress>[],
    List<InterviewWeakExpressionState> weakExpressions =
        const <InterviewWeakExpressionState>[],
  }) {
    final String publicSceneId = (_sceneGraph?.id.trim().isNotEmpty ?? false)
        ? _sceneGraph!.id.trim()
        : defaultInterviewSceneId;
    final List<InterviewPersonalWikiExpression> sceneMasteredExpressions =
        _masteredExpressionsForScene(masteredWikiExpressions, publicSceneId);
    final List<String> plannedStages = _buildPlannedStages(
      mode: mode,
      userTier: userTier,
      targetLevel: targetLevel,
      roundMode: roundMode,
      masteredWikiExpressions: sceneMasteredExpressions,
      preparedLearningProgress: preparedLearningProgress,
      weakExpressions: weakExpressions,
      publicSceneId: publicSceneId,
    );
    final InterviewPracticeSession session = InterviewPracticeSession(
      sessionId: 'local_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      publicSceneId: publicSceneId,
      jobFamily: jobFamily,
      mode: mode,
      userTier: userTier,
      targetLevel: targetLevel,
      plannedStages: plannedStages,
      roundMode: roundMode,
    );
    session.masteredExpressionIds.addAll(
      sceneMasteredExpressions
          .map(
            (InterviewPersonalWikiExpression item) => item.sourceExpressionId,
          )
          .where((String id) => id.isNotEmpty),
    );
    session.stageExpressionTargets.addAll(
      _buildStageExpressionTargets(
        plannedStages,
        targetLevel: targetLevel,
        roundMode: roundMode,
        masteredWikiExpressions: sceneMasteredExpressions,
      ),
    );
    return session;
  }

  List<InterviewPersonalWikiExpression> _masteredExpressionsForScene(
    List<InterviewPersonalWikiExpression> expressions,
    String publicSceneId,
  ) {
    return expressions
        .where(
          (InterviewPersonalWikiExpression item) =>
              item.sourceSceneId.trim().isEmpty ||
              item.sourceSceneId == publicSceneId,
        )
        .toList(growable: false);
  }

  InterviewQuestionPlan followupQuestionPlanForReply({
    required InterviewPracticeSession session,
    required InterviewCoachReply localReply,
    required String userText,
    required List<InterviewExpression> expressions,
    InterviewExpression? reuseTarget,
  }) {
    final String stage = localReply.stage;
    final String planTag = localReply.nextAction == 'followup'
        ? localReply.predictedTag
        : _tagForStage(stage);
    final InterviewExpression? target = _targetExpressionForQuestionPlan(
      session: session,
      localReply: localReply,
      expressions: expressions,
      reuseTarget: reuseTarget,
    );
    final String action = _questionPlanActionForReply(
      session: session,
      localReply: localReply,
      target: target,
      reuseTarget: reuseTarget,
    );
    return InterviewQuestionPlan(
      action: action,
      stage: stage,
      questionIntent: _questionIntentForAction(
        action: action,
        stage: stage,
        tag: planTag,
      ),
      mustAskAbout: localReply.nextAction == 'followup'
          ? localReply.assistantMessage
          : _mustAskAboutForStage(stage),
      localFallbackQuestion: localReply.assistantMessage,
      practiceFocus: _practiceFocusFor(session.roundMode),
      predictedTag: planTag,
      coverageStatus: localReply.coverageStatus,
      targetExpression: target,
    );
  }

  InterviewExpression? _targetExpressionForQuestionPlan({
    required InterviewPracticeSession session,
    required InterviewCoachReply localReply,
    required List<InterviewExpression> expressions,
    InterviewExpression? reuseTarget,
  }) {
    if (reuseTarget != null) {
      return reuseTarget;
    }
    if (localReply.alignmentExpression != null) {
      return localReply.alignmentExpression;
    }
    final InterviewExpression? pendingTarget = session.pendingReuseTarget;
    if (pendingTarget != null &&
        (session.pendingReuseTargetForced ||
            localReply.nextAction == 'followup' ||
            _expressionFitsStage(pendingTarget, localReply.stage))) {
      return pendingTarget;
    }
    final InterviewExpression? stageTarget =
        session.stageExpressionTargets[localReply.stage] ??
        session.stageExpressionTargets[session.currentStage];
    if (stageTarget != null) {
      return stageTarget;
    }
    return expressions.isEmpty ? null : expressions.first;
  }

  bool _expressionFitsStage(InterviewExpression expression, String stage) {
    final String stageTag = _tagForStage(stage);
    return stageTag.isNotEmpty && expression.tag == stageTag;
  }

  String _questionPlanActionForReply({
    required InterviewPracticeSession session,
    required InterviewCoachReply localReply,
    required InterviewExpression? target,
    InterviewExpression? reuseTarget,
  }) {
    if (localReply.isSessionEnd) {
      return 'wrap_up';
    }
    if (localReply.nextAction == 'coach_retry') {
      return 'coach_retry';
    }
    if (localReply.nextAction == 'followup') {
      return 'follow_up';
    }
    if (reuseTarget != null || localReply.alignmentExpression != null) {
      return 'reuse_aligned_expression';
    }
    if (session.pendingReuseTargetForced &&
        target != null &&
        target.id == session.pendingReuseTarget?.id) {
      return 'reuse_aligned_expression';
    }
    if (session.roundMode == InterviewNextRoundMode.review && target != null) {
      return 'reuse_due_expression';
    }
    if (localReply.coverageStatus == 'stuck') {
      return 'consolidate_weak_tag';
    }
    if (target != null) {
      return 'introduce_new_expression';
    }
    return 'next_stage_question';
  }

  String _practiceFocusFor(InterviewNextRoundMode roundMode) {
    return roundMode == InterviewNextRoundMode.review
        ? 'spaced repetition review'
        : 'new expression expansion';
  }

  String _coachRetryMessage({
    required String stage,
    required InterviewExpression expression,
    required InterviewExpressionMasteryResult result,
    required int attempts,
    required bool stuck,
    required String userText,
  }) {
    final InterviewExpressionNode? node = _nodeForStage(stage);
    final String targetText = expression.text.trim();
    final String intent = node?.intent.isNotEmpty == true
        ? node!.intent
        : expression.useCase;
    final String missing = _missingMoveSummary(result.missingCoreMoves);
    if (attempts <= 1) {
      if (result.nearMiss) {
        final String phrase = _targetPhraseForMissingMove(
          targetText,
          result.missingCoreMoves,
        );
        final String phraseLine = phrase.isEmpty ? '' : '\n可以只补这一小块："$phrase"';
        return '方向是对的，先不背整句。你现在只差一步：$missing。$phraseLine\n接着把这一点补出来。';
      }
      final String hint = _shortCoachHint(node: node, fallback: intent);
      return stuck
          ? '没关系，我们先拆小一点。$hint\n先说一个简单版本就可以。'
          : '先停在这一题。重点不是往下走，而是把这一步说清楚：$intent。\n你先用简单英文再试一次。';
    }

    if (attempts == 2) {
      final String corrected = _correctedUserStarter(
        userText: userText,
        missingMoves: result.missingCoreMoves,
      );
      if (corrected.isNotEmpty) {
        final String nextMove =
            result.missingCoreMoves.contains('project or achievement')
            ? '下一句再补一个具体项目或成果。'
            : '下一句再补一个具体细节。';
        return '给你一个小支架，先把你的原句说顺："$corrected"\n$nextMove';
      }
      final String starter = _targetStarter(targetText);
      return '我们加一点支架。先用这个开头："$starter"。\n后面接你的真实信息。';
    }

    return '我先给完整示范："$targetText"\n先把这个节奏说顺，下一轮我们再换成你的真实信息。';
  }

  String _missingMoveSummary(List<String> moves) {
    if (moves.isEmpty) {
      return '把这句话说完整';
    }
    final List<String> labels = moves
        .take(2)
        .map(_localizedCoreMoveLabel)
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    if (labels.isEmpty) {
      return '把这句话说完整';
    }
    return '补上${labels.join('和')}';
  }

  String _localizedCoreMoveLabel(String move) {
    return switch (move) {
      'gratitude' => '感谢',
      'positive interest' => '积极态度',
      'current role' => '当前角色',
      'location' => '地点信息',
      'experience' => '经验背景',
      'project or achievement' => '项目或成果',
      'problem solving' => '解决问题的动作',
      'strength' => '优势',
      'pressure handling' => '抗压处理方式',
      'growth motivation' => '成长动机',
      'career plan' => '职业规划',
      'candidate question' => '反问点',
      _ => move,
    };
  }

  String _targetPhraseForMissingMove(String targetText, List<String> moves) {
    final List<String> chunks = _targetChunks(targetText);
    bool hasAny(List<String> keywords, String value) {
      final String lower = value.toLowerCase();
      return keywords.any(lower.contains);
    }

    for (final String move in moves) {
      final List<String> keywords = switch (move) {
        'gratitude' => const <String>['thank', 'thanks', 'appreciate'],
        'positive interest' => const <String>[
          'excited',
          'happy',
          'glad',
          'thrilled',
          'look forward',
          'enjoy',
        ],
        'current role' => const <String>['currently', 'working', 'role'],
        'experience' => const <String>['experience', 'background'],
        'project or achievement' => const <String>[
          'project',
          'achievement',
          'delivered',
          'led',
        ],
        'problem solving' => const <String>[
          'problem',
          'improve',
          'reduced',
          'solve',
        ],
        'strength' => const <String>['strength', 'good at', 'strong'],
        'pressure handling' => const <String>['pressure', 'calm', 'focused'],
        'growth motivation' => const <String>['grow', 'learn', 'looking for'],
        'career plan' => const <String>['five years', 'leadership', 'mentor'],
        'candidate question' => const <String>[
          'could you',
          'what',
          'next steps',
        ],
        _ => const <String>[],
      };
      if (keywords.isEmpty) {
        continue;
      }
      for (final String chunk in chunks) {
        if (hasAny(keywords, chunk)) {
          return chunk;
        }
      }
    }
    return '';
  }

  List<String> _targetChunks(String targetText) {
    return targetText
        .split(RegExp(r'[.!?]+\s+|;|, and |, but | - |\u2014'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _targetStarter(String targetText) {
    if (targetText.trim().isEmpty) {
      return '';
    }
    final List<String> chunks = _targetChunks(targetText);
    final String firstChunk = chunks.isEmpty ? targetText.trim() : chunks.first;
    final List<String> words = firstChunk.split(RegExp(r'\s+'));
    if (words.length <= 7) {
      return firstChunk.replaceAll(RegExp(r'[.!?]+$'), '');
    }
    return '${words.take(6).join(' ')}...';
  }

  String _correctedUserStarter({
    required String userText,
    required List<String> missingMoves,
  }) {
    String text = normalizeInterviewText(userText)
        .replaceAll(RegExp(r'\bview\s+road\b', caseSensitive: false), 'role')
        .replaceAll(RegExp(r'\bview\s+role\b', caseSensitive: false), 'role')
        .replaceAll(
          RegExp(r'\bprevious\s+view\b', caseSensitive: false),
          'previous role',
        )
        .replaceAll(
          RegExp(r'\bi\s+working\s+as\b', caseSensitive: false),
          'I worked as',
        )
        .replaceAll(
          RegExp(r'\bi\s+work\s+as\b', caseSensitive: false),
          'I worked as',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) {
      return '';
    }
    text = text.replaceFirst(
      RegExp(r'^in my previous role', caseSensitive: false),
      'In my previous role',
    );
    text = text.replaceFirst(RegExp(r'\bi\b'), 'I');
    if (!text.endsWith('.') && !text.endsWith('?') && !text.endsWith('!')) {
      text = '$text.';
    }
    final int wordCount = _expressionAnswerTokens(text).length;
    if (wordCount < 4 || wordCount > 18) {
      return '';
    }
    return text;
  }

  String _shortCoachHint({
    required InterviewExpressionNode? node,
    required String fallback,
  }) {
    final String raw = <String>[
      node?.hintTree.l1 ?? '',
      node?.followupQuestion ?? '',
      fallback,
    ].firstWhere((String item) => item.trim().isNotEmpty, orElse: () => '');
    final String trimmed = raw.trim();
    if (trimmed.length <= 72) {
      return trimmed;
    }
    return '${trimmed.substring(0, 72)}...';
  }

  String _questionIntentForAction({
    required String action,
    required String stage,
    required String tag,
  }) {
    return switch (action) {
      'cold_start_opening' =>
        'establish the learner background and collect reusable interview material',
      'warm_start_due_review' =>
        'create a natural context for a due expression without naming it',
      'personalized_warm_start' =>
        'start from a relevant personal fact or prior interview material',
      'follow_up' =>
        'ask for one concrete detail that completes the current answer',
      'coach_retry' =>
        'pause the sequence, give one focused coaching correction, and ask the learner to retry the same expression',
      'reuse_due_expression' =>
        'help the learner naturally reuse the due expression in this stage',
      'reuse_aligned_expression' =>
        'create a nearby context for the expression just aligned to the learner',
      'introduce_new_expression' =>
        'open a context where the target expression would be useful',
      'consolidate_weak_tag' =>
        'ask a simpler question that strengthens the weak tag',
      'wrap_up' => 'close the interview round and prepare for review',
      _ => 'ask the next concise interview question for $tag',
    };
  }

  String _mustAskAboutForStage(String stage) {
    final InterviewExpressionNode? node = _nodeForStage(stage);
    if (node != null) {
      return node.naturalTiming.isNotEmpty ? node.naturalTiming : node.intent;
    }
    return switch (stage) {
      'open' => 'the learner current role or interview goal',
      'self_intro' => 'the learner background and current role',
      'background' => 'the learner years of experience or work background',
      'experience_project' => 'one concrete project or responsibility',
      'strength' => 'one strength and a quick example',
      'role_fit' => 'why the learner is interested in this role or company',
      'career_plan' => 'the learner career direction and how this role fits',
      'weakness' => 'one weakness and a specific improvement action',
      'pressure' => 'a pressure situation and what the learner learned',
      'salary_optional' => 'salary expectations or compensation priorities',
      'candidate_question' => 'one thoughtful question for the interviewer',
      _ => _questionForStage(stage),
    };
  }

  InterviewHint requestHint(
    InterviewPracticeSession session, {
    String? stage,
    String? question,
  }) {
    final String currentStage = stage ?? session.currentStage;
    final String currentHintLevel =
        session.stageHintLevels[currentStage] ?? 'none';
    final InterviewHint hint = _nextHint(
      currentStage,
      currentHintLevel,
      question: question,
      targetExpression: _hintExpressionForStage(session, currentStage),
    );
    session.stageHintLevels[currentStage] = hint.level;
    return hint;
  }

  InterviewCoachReply answer(
    InterviewPracticeSession session, {
    required String userText,
    Map<String, InterviewExpressionMasteryResult> masteryOverrides =
        const <String, InterviewExpressionMasteryResult>{},
  }) {
    final String currentStage = session.currentStage;
    final String currentQuestion = _questionForStage(
      currentStage,
      simplified: session.simplifiedMode,
    );
    final List<InterviewExpression> masteredExpressions =
        <InterviewExpression>[];
    final Map<String, InterviewExpressionMasteryResult> masteryResults =
        <String, InterviewExpressionMasteryResult>{};
    final InterviewExpression? pendingReuseTarget = session.pendingReuseTarget;
    bool pendingReuseTargetReproduced = false;
    InterviewExpressionMasteryResult? pendingReuseTargetResult;
    if (pendingReuseTarget != null) {
      pendingReuseTargetResult = _expressionMasteryResult(
        expression: pendingReuseTarget,
        userText: userText,
        question: currentQuestion,
        overrides: masteryOverrides,
      );
      masteryResults[pendingReuseTarget.id] = pendingReuseTargetResult;
    }
    if (pendingReuseTarget != null &&
        (pendingReuseTargetResult?.mastered ?? false)) {
      pendingReuseTargetReproduced = true;
      _recordExpressionReproduced(
        session,
        pendingReuseTarget,
        masteredExpressions,
      );
      session.pendingReuseTarget = null;
      session.pendingReuseTargetForced = false;
    }
    final InterviewExpression? alignmentExpression =
        session.stageExpressionTargets[currentStage];
    bool alignmentExpressionReproduced = false;
    InterviewExpressionMasteryResult? alignmentExpressionResult;
    if (alignmentExpression != null) {
      alignmentExpressionResult = _expressionMasteryResult(
        expression: alignmentExpression,
        userText: userText,
        question: currentQuestion,
        overrides: masteryOverrides,
      );
      masteryResults[alignmentExpression.id] = alignmentExpressionResult;
    }
    if (alignmentExpression != null &&
        (alignmentExpressionResult?.mastered ?? false)) {
      alignmentExpressionReproduced = true;
      _recordExpressionReproduced(
        session,
        alignmentExpression,
        masteredExpressions,
      );
    }
    final bool alignmentCoveredByPendingReproduction =
        pendingReuseTargetReproduced &&
        pendingReuseTarget?.id == alignmentExpression?.id;
    _detectReproducedLibraryExpressions(
      session,
      userText: userText,
      masteredExpressions: masteredExpressions,
      currentStage: currentStage,
      currentQuestion: currentQuestion,
      masteryResults: masteryResults,
      masteryOverrides: masteryOverrides,
    );
    final InterviewExpression? replyAlignmentExpression = _alignmentForReply(
      session,
      alignmentExpression,
    );
    final String activeStage = currentStage == 'open'
        ? 'self_intro'
        : currentStage;
    final InterviewTurnAnalysis rawAnalysis = _matcher.match(
      activeStage,
      userText,
    );
    final InterviewTurnAnalysis analysis =
        alignmentExpressionReproduced || alignmentCoveredByPendingReproduction
        ? InterviewTurnAnalysis(
            predictedTag:
                alignmentExpression?.tag ??
                pendingReuseTarget?.tag ??
                rawAnalysis.predictedTag,
            secondaryTags: rawAnalysis.secondaryTags,
            confidence: math.max(rawAnalysis.confidence, 0.85),
            coverageStatus: 'covered',
            coverageCredit: 1,
            stuckState: false,
            needsFollowup: false,
            correctionHits: rawAnalysis.correctionHits,
            languageMixRatio: rawAnalysis.languageMixRatio,
          )
        : rawAnalysis;
    final int attempts = (session.stageAttempts[currentStage] ?? 0) + 1;
    session.stageAttempts[currentStage] = attempts;
    session.stageBestCoverage[currentStage] = math.max(
      session.stageBestCoverage[currentStage] ?? 0,
      analysis.coverageCredit,
    );
    session.stagePrimaryTags[currentStage] = analysis.predictedTag;

    session.turns.add(
      InterviewTurnRecord(
        stage: currentStage,
        question: _questionForStage(
          currentStage,
          simplified: session.simplifiedMode,
        ),
        userText: normalizeInterviewText(userText),
        predictedTags: <String>[
          analysis.predictedTag,
          ...analysis.secondaryTags,
        ],
        correctionHitIds: analysis.correctionHits
            .map((InterviewCorrectionHit hit) => hit.id)
            .toList(growable: false),
        coverageStatus: analysis.coverageStatus,
        coverageCredit: analysis.coverageCredit,
        confidence: analysis.confidence,
        createdAt: DateTime.now(),
      ),
    );

    if (analysis.coverageStatus == 'stuck') {
      session.consecutiveStuckCount += 1;
    } else {
      session.consecutiveStuckCount = 0;
    }
    if (session.consecutiveStuckCount >= 2) {
      session.simplifiedMode = true;
    }

    final bool shouldAskAutomaticFollowup =
        analysis.needsFollowup &&
        attempts == 1 &&
        currentStage != 'candidate_question' &&
        currentStage != 'wrap_up' &&
        alignmentExpressionResult == null;
    if (shouldAskAutomaticFollowup) {
      session.stageFollowups[currentStage] =
          (session.stageFollowups[currentStage] ?? 0) + 1;
      if (!alignmentExpressionReproduced &&
          !alignmentCoveredByPendingReproduction) {
        _queueDelayedReuseTarget(session, alignmentExpression);
      }
      return _reply(
        session: session,
        analysis: analysis,
        stage: currentStage,
        nextAction: 'followup',
        assistantMessage: _followupForStage(
          currentStage,
          simplified: session.simplifiedMode,
        ),
        alignmentExpression: replyAlignmentExpression,
        masteredExpressions: masteredExpressions,
        masteryResults: masteryResults,
      );
    }

    final InterviewExpressionMasteryResult? activeMasteryResult =
        alignmentExpressionResult ?? pendingReuseTargetResult;
    final InterviewExpression? activeCoachExpression =
        alignmentExpression ?? pendingReuseTarget;
    if (activeCoachExpression != null &&
        activeMasteryResult != null &&
        !activeMasteryResult.mastered) {
      return _reply(
        session: session,
        analysis: analysis,
        stage: currentStage,
        nextAction: 'coach_retry',
        assistantMessage: _coachRetryMessage(
          stage: currentStage,
          expression: activeCoachExpression,
          result: activeMasteryResult,
          attempts: attempts,
          stuck: analysis.coverageStatus == 'stuck',
          userText: userText,
        ),
        alignmentExpression: activeCoachExpression,
        masteredExpressions: masteredExpressions,
        masteryResults: masteryResults,
      );
    }

    if (currentStage == 'open') {
      session.stageBestCoverage['self_intro'] = math.max(
        session.stageBestCoverage['self_intro'] ?? 0,
        analysis.coverageCredit,
      );
      session.stagePrimaryTags['self_intro'] = analysis.predictedTag;
      if (session.plannedStages.contains('background')) {
        session.stageIndex = session.plannedStages.indexOf('background');
      } else if (session.plannedStages.contains('experience_project')) {
        session.stageIndex = session.plannedStages.indexOf(
          'experience_project',
        );
      } else {
        session.stageIndex = math.min(1, session.plannedStages.length - 1);
      }
    } else {
      session.stageIndex += 1;
      if (session.stageIndex >= session.plannedStages.length) {
        return _reply(
          session: session,
          analysis: analysis,
          stage: currentStage,
          nextAction: 'end_session',
          assistantMessage: _questionForStage('wrap_up'),
          alignmentExpression: replyAlignmentExpression,
          masteredExpressions: masteredExpressions,
          masteryResults: masteryResults,
        );
      }
    }

    final String nextStage = session.currentStage;
    if (nextStage == 'wrap_up') {
      return _reply(
        session: session,
        analysis: analysis,
        stage: currentStage,
        nextAction: 'end_session',
        assistantMessage: _questionForStage('wrap_up'),
        alignmentExpression: replyAlignmentExpression,
        masteredExpressions: masteredExpressions,
        masteryResults: masteryResults,
      );
    }

    if (!alignmentExpressionReproduced &&
        !alignmentCoveredByPendingReproduction) {
      _queueDelayedReuseTarget(session, alignmentExpression);
    }
    _activateDelayedReuseTargetIfEligible(session);

    return _reply(
      session: session,
      analysis: analysis,
      stage: nextStage,
      nextAction: 'next_question',
      assistantMessage: _questionForStage(
        nextStage,
        simplified: session.simplifiedMode,
      ),
      alignmentExpression: replyAlignmentExpression,
      masteredExpressions: masteredExpressions,
      masteryResults: masteryResults,
    );
  }

  InterviewExpression? _alignmentForReply(
    InterviewPracticeSession session,
    InterviewExpression? expression,
  ) {
    if (expression == null ||
        session.roundMode == InterviewNextRoundMode.review ||
        session.masteredExpressionIds.contains(expression.id)) {
      return null;
    }
    return expression;
  }

  void _armReuseTarget(
    InterviewPracticeSession session,
    InterviewExpression? expression,
  ) {
    if (expression == null) {
      return;
    }
    if (session.roundMode != InterviewNextRoundMode.review &&
        session.masteredExpressionIds.contains(expression.id)) {
      return;
    }
    session.pendingReuseTarget = expression;
    session.pendingReuseTargetForced = false;
  }

  void _queueDelayedReuseTarget(
    InterviewPracticeSession session,
    InterviewExpression? expression,
  ) {
    if (expression == null) {
      return;
    }
    if (session.roundMode != InterviewNextRoundMode.review) {
      if (!session.masteredExpressionIds.contains(expression.id)) {
        session.delayedReuseTarget = expression;
        session.delayedReuseEligibleStageIndex = math.min(
          session.stageIndex + 1,
          math.max(0, session.plannedStages.length - 1),
        );
      }
      return;
    }
    _armReuseTarget(session, expression);
  }

  void _activateDelayedReuseTargetIfEligible(InterviewPracticeSession session) {
    final InterviewExpression? delayedTarget = session.delayedReuseTarget;
    if (delayedTarget == null ||
        session.pendingReuseTarget != null ||
        session.delayedReuseEligibleStageIndex < 0 ||
        session.stageIndex < session.delayedReuseEligibleStageIndex ||
        session.masteredExpressionIds.contains(delayedTarget.id)) {
      return;
    }
    final ExpressionSceneNode? delayedNode = _expressionSceneNodeForStage(
      delayedTarget.id,
    );
    final ExpressionSceneNode? currentNode = _expressionSceneNodeForStage(
      session.currentStage,
    );
    final bool shouldActivate = delayedNode != null && currentNode != null
        ? _sceneOrchestrator.shouldActivateDelayedReuse(
            currentIndex: session.stageIndex,
            eligibleIndex: session.delayedReuseEligibleStageIndex,
            delayedNode: delayedNode,
            currentNode: currentNode,
          )
        : _expressionFitsStage(delayedTarget, session.currentStage);
    if (shouldActivate) {
      session.pendingReuseTarget = delayedTarget;
      session.pendingReuseTargetForced = true;
      session.delayedReuseTarget = null;
      session.delayedReuseEligibleStageIndex = -1;
    }
  }

  void _detectReproducedLibraryExpressions(
    InterviewPracticeSession session, {
    required String userText,
    required List<InterviewExpression> masteredExpressions,
    required String currentStage,
    required String currentQuestion,
    required Map<String, InterviewExpressionMasteryResult> masteryResults,
    Map<String, InterviewExpressionMasteryResult> masteryOverrides =
        const <String, InterviewExpressionMasteryResult>{},
  }) {
    final String currentTag = _tagForStage(currentStage);
    for (final InterviewExpression expression in _library.expressions) {
      if (expression.id.isEmpty ||
          session.masteredExpressionIds.contains(expression.id)) {
        continue;
      }
      if (expression.tag.isNotEmpty &&
          currentTag.isNotEmpty &&
          expression.tag != currentTag) {
        continue;
      }
      final InterviewExpressionMasteryResult result = _expressionMasteryResult(
        expression: expression,
        userText: userText,
        question: currentQuestion,
        overrides: masteryOverrides,
      );
      masteryResults[expression.id] = result;
      if (!result.mastered) {
        continue;
      }
      _recordExpressionReproduced(session, expression, masteredExpressions);
    }
  }

  void _recordExpressionReproduced(
    InterviewPracticeSession session,
    InterviewExpression expression,
    List<InterviewExpression> masteredExpressions,
  ) {
    if (expression.id.isEmpty) {
      return;
    }
    final bool alreadyMastered = session.masteredExpressionIds.contains(
      expression.id,
    );
    if (!alreadyMastered) {
      session.masteredExpressionIds.add(expression.id);
      session.roundMasteredExpressionIds.add(expression.id);
    }
    if (session.pendingReuseTarget?.id == expression.id) {
      session.pendingReuseTarget = null;
      session.pendingReuseTargetForced = false;
    }
    if (session.delayedReuseTarget?.id == expression.id) {
      session.delayedReuseTarget = null;
      session.delayedReuseEligibleStageIndex = -1;
    }
    final bool shouldPersistReview =
        !alreadyMastered || session.roundMode == InterviewNextRoundMode.review;
    final bool alreadyQueued = masteredExpressions.any(
      (InterviewExpression item) => item.id == expression.id,
    );
    if (shouldPersistReview && !alreadyQueued) {
      masteredExpressions.add(expression);
    }
  }

  InterviewReview review(
    InterviewPracticeSession session, {
    List<InterviewPersonalWikiExpression> masteredWikiExpressions =
        const <InterviewPersonalWikiExpression>[],
  }) {
    final Set<String> libraryExpressionIds =
        _expressionsForTargetLevel(session.targetLevel)
            .map((InterviewExpression item) => item.id)
            .where((String id) => id.isNotEmpty)
            .toSet();
    final Set<String> masteredExpressionIds = <String>{
      ...masteredWikiExpressions
          .map(
            (InterviewPersonalWikiExpression item) => item.sourceExpressionId,
          )
          .where((String id) => libraryExpressionIds.contains(id)),
      ...session.masteredExpressionIds.where(libraryExpressionIds.contains),
    };
    final int totalExpressionCount = libraryExpressionIds.length;
    final int totalMasteredCount = masteredExpressionIds.length;
    final double masteryRatio = totalExpressionCount == 0
        ? 0
        : totalMasteredCount / totalExpressionCount;
    final List<InterviewPersonalWikiExpression> activeMasteredWikiExpressions =
        masteredWikiExpressions
            .where(
              (InterviewPersonalWikiExpression item) =>
                  libraryExpressionIds.contains(item.sourceExpressionId) ||
                  libraryExpressionIds.contains(item.sourceNodeId),
            )
            .toList(growable: false);
    final InterviewNextRoundMode nextRoundMode =
        roundModeForMasteredExpressions(
          activeMasteredWikiExpressions,
          targetLevel: session.targetLevel,
        );
    final List<InterviewPersonalWikiExpression> dueReviewExpressions =
        _dueReviewWikiExpressions(activeMasteredWikiExpressions);
    final List<InterviewPersonalWikiExpression> reviewQueue =
        _rankedReviewWikiExpressions(activeMasteredWikiExpressions);
    final DateTime? nextDueReviewAt = dueReviewExpressions.isNotEmpty
        ? dueReviewExpressions.first.nextReviewAt
        : _nextDueReviewAt(reviewQueue);
    final List<String> weakTags = _weakTagsFor(
      session,
      masteredExpressionIds: masteredExpressionIds,
      targetLevel: session.targetLevel,
    );
    final List<String> strongTags = _rankedMasteredTags(masteredExpressionIds);
    final List<InterviewCorrection> corrections = session.turns
        .expand((InterviewTurnRecord turn) => turn.correctionHitIds)
        .toSet()
        .map(_library.correctionById)
        .whereType<InterviewCorrection>()
        .take(4)
        .toList(growable: false);

    return InterviewReview(
      score: (masteryRatio * 100).round().clamp(0, 100),
      coveredCount: totalMasteredCount,
      totalCount: totalExpressionCount,
      strongTags: strongTags,
      focusTags: weakTags,
      corrections: corrections,
      suggestedExpressions: _suggestedExpressionsFor(
        nextRoundMode: nextRoundMode,
        weakTags: weakTags,
        masteredWikiExpressions: activeMasteredWikiExpressions,
        masteredExpressionIds: masteredExpressionIds,
        targetLevel: session.targetLevel,
      ),
      masteredThisRoundCount: session.roundMasteredExpressionIds
          .where(libraryExpressionIds.contains)
          .length,
      totalMasteredCount: totalMasteredCount,
      totalExpressionCount: totalExpressionCount,
      weakTags: weakTags,
      nextRoundMode: nextRoundMode,
      dueReviewCount: dueReviewExpressions.length,
      nextDueReviewAt: nextDueReviewAt,
    );
  }

  DateTime? _nextDueReviewAt(
    List<InterviewPersonalWikiExpression> reviewQueue,
  ) {
    DateTime? result;
    for (final InterviewPersonalWikiExpression expression in reviewQueue) {
      if (result == null || expression.nextReviewAt.isBefore(result)) {
        result = expression.nextReviewAt;
      }
    }
    return result;
  }

  List<String> _weakTagsFor(
    InterviewPracticeSession session, {
    required Set<String> masteredExpressionIds,
    required String targetLevel,
  }) {
    final Map<String, int> unmasteredByTag = <String, int>{
      for (final String tag in interviewTags) tag: 0,
    };
    for (final InterviewExpression expression in _expressionsForTargetLevel(
      targetLevel,
    )) {
      if (expression.id.isEmpty ||
          masteredExpressionIds.contains(expression.id)) {
        continue;
      }
      unmasteredByTag[expression.tag] =
          (unmasteredByTag[expression.tag] ?? 0) + 1;
    }

    final Map<String, int> stuckByTag = <String, int>{
      for (final String tag in interviewTags) tag: 0,
    };
    for (final InterviewTurnRecord turn in session.turns) {
      if (turn.coverageStatus != 'stuck' &&
          turn.coverageStatus != 'partial_covered') {
        continue;
      }
      final String tag = _tagForStage(turn.stage).isNotEmpty
          ? _tagForStage(turn.stage)
          : (turn.predictedTags.isNotEmpty ? turn.predictedTags.first : '');
      if (tag.isEmpty) {
        continue;
      }
      stuckByTag[tag] = (stuckByTag[tag] ?? 0) + 1;
    }

    final List<String> tags = interviewTags
        .where(
          (String tag) =>
              (unmasteredByTag[tag] ?? 0) > 0 || (stuckByTag[tag] ?? 0) > 0,
        )
        .toList(growable: false);
    tags.sort((String a, String b) {
      final int stuckCompare = (stuckByTag[b] ?? 0).compareTo(
        stuckByTag[a] ?? 0,
      );
      if (stuckCompare != 0) {
        return stuckCompare;
      }
      final int unmasteredCompare = (unmasteredByTag[b] ?? 0).compareTo(
        unmasteredByTag[a] ?? 0,
      );
      if (unmasteredCompare != 0) {
        return unmasteredCompare;
      }
      return interviewTags.indexOf(a).compareTo(interviewTags.indexOf(b));
    });
    return tags.take(3).toList(growable: false);
  }

  List<String> _rankedMasteredTags(Set<String> masteredExpressionIds) {
    final Map<String, int> masteredByTag = <String, int>{};
    for (final InterviewExpression expression in _library.expressions) {
      if (!masteredExpressionIds.contains(expression.id)) {
        continue;
      }
      masteredByTag[expression.tag] = (masteredByTag[expression.tag] ?? 0) + 1;
    }
    final List<String> tags = masteredByTag.keys.toList(growable: false);
    tags.sort((String a, String b) {
      final int countCompare = (masteredByTag[b] ?? 0).compareTo(
        masteredByTag[a] ?? 0,
      );
      if (countCompare != 0) {
        return countCompare;
      }
      return interviewTags.indexOf(a).compareTo(interviewTags.indexOf(b));
    });
    return tags.take(3).toList(growable: false);
  }

  List<InterviewExpression> _suggestedExpressionsFor({
    required InterviewNextRoundMode nextRoundMode,
    required List<String> weakTags,
    required List<InterviewPersonalWikiExpression> masteredWikiExpressions,
    required Set<String> masteredExpressionIds,
    required String targetLevel,
  }) {
    final Set<String> activeExpressionIds = _expressionsForTargetLevel(
      targetLevel,
    ).map((InterviewExpression item) => item.id).toSet();
    if (nextRoundMode == InterviewNextRoundMode.review) {
      final List<InterviewExpression> wikiExpressions =
          _rankedReviewWikiExpressions(masteredWikiExpressions)
              .where(
                (InterviewPersonalWikiExpression item) =>
                    activeExpressionIds.contains(item.sourceExpressionId) ||
                    activeExpressionIds.contains(item.sourceNodeId),
              )
              .map(InterviewExpression.fromPersonalWiki)
              .toList(growable: false);
      return wikiExpressions.take(4).toList(growable: false);
    }
    final String targetTag = weakTags.isNotEmpty ? weakTags.first : '自我介绍';
    return _library
        .expressionsForTag(targetTag, targetLevel: targetLevel, limit: 12)
        .where(
          (InterviewExpression item) =>
              !masteredExpressionIds.contains(item.id),
        )
        .take(4)
        .toList(growable: false);
  }

  InterviewCoachReply _reply({
    required InterviewPracticeSession session,
    required InterviewTurnAnalysis analysis,
    required String stage,
    required String nextAction,
    required String assistantMessage,
    String? hintState,
    InterviewExpression? alignmentExpression,
    List<InterviewExpression> masteredExpressions =
        const <InterviewExpression>[],
    Map<String, InterviewExpressionMasteryResult> masteryResults =
        const <String, InterviewExpressionMasteryResult>{},
  }) {
    return InterviewCoachReply(
      predictedTag: analysis.predictedTag,
      secondaryTags: analysis.secondaryTags,
      coverageStatus: analysis.coverageStatus,
      hintState:
          hintState ?? session.stageHintLevels[session.currentStage] ?? 'none',
      nextAction: nextAction,
      assistantMessage: assistantMessage,
      confidence: analysis.confidence,
      correctionHits: analysis.correctionHits,
      coverageCredit: analysis.coverageCredit,
      stage: stage,
      alignmentExpression: alignmentExpression,
      masteredExpressions: masteredExpressions,
      masteryResults: masteryResults,
    );
  }

  Map<String, InterviewExpression> _buildStageExpressionTargets(
    List<String> stages, {
    required String targetLevel,
    required InterviewNextRoundMode roundMode,
    required List<InterviewPersonalWikiExpression> masteredWikiExpressions,
  }) {
    final InterviewSceneGraph? graph = _sceneGraph;
    if (graph != null) {
      return <String, InterviewExpression>{
        for (final String stage in stages)
          if (graph.nodeById(stage) != null)
            stage: graph.nodeById(stage)!.toExpression(),
      };
    }
    if (roundMode == InterviewNextRoundMode.review) {
      return _buildReviewStageExpressionTargets(
        stages,
        targetLevel: targetLevel,
        masteredWikiExpressions: masteredWikiExpressions,
      );
    }
    final Map<String, InterviewExpression> targets =
        <String, InterviewExpression>{};
    final Map<String, int> tagCounts = <String, int>{};
    final Set<String> masteredExpressionIds = masteredWikiExpressions
        .map((InterviewPersonalWikiExpression item) => item.sourceExpressionId)
        .where((String id) => id.isNotEmpty)
        .toSet();
    for (final String stage in stages) {
      if (stage == 'wrap_up') {
        continue;
      }
      final String tag = _tagForStage(stage);
      final List<InterviewExpression> unmasteredCandidates = _library
          .expressionsForTag(tag, targetLevel: targetLevel, limit: 12)
          .where(
            (InterviewExpression item) =>
                !masteredExpressionIds.contains(item.id),
          )
          .toList(growable: false);
      final List<InterviewExpression> candidates =
          unmasteredCandidates.isNotEmpty
          ? unmasteredCandidates
          : _library.expressionsForTag(
              tag,
              targetLevel: targetLevel,
              limit: 12,
            );
      if (candidates.isEmpty) {
        continue;
      }
      final int tagIndex = tagCounts[tag] ?? 0;
      tagCounts[tag] = tagIndex + 1;
      targets[stage] = candidates[tagIndex % candidates.length];
    }
    return targets;
  }

  List<String> _buildPlannedStages({
    required String mode,
    required String userTier,
    required String targetLevel,
    required InterviewNextRoundMode roundMode,
    required List<InterviewPersonalWikiExpression> masteredWikiExpressions,
    required List<InterviewExpressionLearningProgress> preparedLearningProgress,
    required List<InterviewWeakExpressionState> weakExpressions,
    required String publicSceneId,
  }) {
    final InterviewSceneGraph? graph = _sceneGraph;
    if (graph != null) {
      final ExpressionSceneGraph expressionGraph =
          ExpressionSceneGraph.fromInterviewSceneGraph(graph);
      final List<String> graphStages = _sceneOrchestrator.plannedNodeIds(
        graph: expressionGraph,
        targetLevel: targetLevel,
        mode: roundMode == InterviewNextRoundMode.review
            ? ExpressionScenePracticeMode.review
            : ExpressionScenePracticeMode.newLesson,
        learnerStates: _learnerNodeStatesForGraph(
          masteredWikiExpressions,
          preparedLearningProgress: preparedLearningProgress,
          weakExpressions: weakExpressions,
          publicSceneId: publicSceneId,
        ),
      );
      final List<String> resolvedStages = graphStages.isNotEmpty
          ? graphStages
          : graph.flowNodeIdsForLevel(targetLevel);
      return _withWrapUp(resolvedStages, userTier: userTier);
    }
    if (mode == 'single_scene_drill') {
      return _withWrapUp(<String>[
        'open',
        'background',
        'experience_project',
      ], userTier: userTier);
    }
    if (masteredWikiExpressions.isEmpty) {
      return _withWrapUp(
        defaultInterviewStageFlow.where((String stage) => stage != 'wrap_up'),
        userTier: userTier,
      );
    }
    if (roundMode == InterviewNextRoundMode.review) {
      final List<String> reviewStages = _reviewStagesFromWiki(
        masteredWikiExpressions,
        userTier: userTier,
      );
      if (reviewStages.isNotEmpty) {
        return _withWrapUp(reviewStages, userTier: userTier);
      }
    } else {
      final List<String> newLessonStages = _newLessonStagesFromWiki(
        masteredWikiExpressions,
        targetLevel: targetLevel,
        userTier: userTier,
      );
      if (newLessonStages.isNotEmpty) {
        return _withWrapUp(newLessonStages, userTier: userTier);
      }
    }
    return _withWrapUp(
      defaultInterviewStageFlow
          .where((String stage) => stage != 'open' && stage != 'wrap_up')
          .take(5),
      userTier: userTier,
    );
  }

  List<ExpressionSceneLearnerNodeState> _learnerNodeStatesForGraph(
    List<InterviewPersonalWikiExpression> masteredWikiExpressions, {
    List<InterviewExpressionLearningProgress> preparedLearningProgress =
        const <InterviewExpressionLearningProgress>[],
    List<InterviewWeakExpressionState> weakExpressions =
        const <InterviewWeakExpressionState>[],
    String publicSceneId = defaultInterviewSceneId,
  }) {
    final DateTime now = DateTime.now();
    final Map<String, ExpressionSceneLearnerNodeState> states =
        <String, ExpressionSceneLearnerNodeState>{};
    final Map<String, InterviewWeakExpressionState> weakByNode =
        <String, InterviewWeakExpressionState>{
          for (final InterviewWeakExpressionState item in weakExpressions)
            if (item.sourceSceneId == publicSceneId)
              _nodeIdForWeakExpression(item): item,
        }..removeWhere((String key, _) => key.isEmpty);
    final Map<String, InterviewExpressionLearningProgress> progressByNode =
        <String, InterviewExpressionLearningProgress>{
          for (final InterviewExpressionLearningProgress item
              in preparedLearningProgress)
            if (item.nodeId.trim().isNotEmpty) item.nodeId.trim(): item,
        };
    for (final InterviewPersonalWikiExpression item
        in masteredWikiExpressions) {
      final String nodeId = item.sourceNodeId.isNotEmpty
          ? item.sourceNodeId
          : item.sourceExpressionId;
      if (nodeId.isEmpty) {
        continue;
      }
      states[nodeId] = ExpressionSceneLearnerNodeState(
        nodeId: nodeId,
        mastered: true,
        due: !item.nextReviewAt.isAfter(now),
      );
    }
    for (final InterviewExpressionLearningProgress item
        in preparedLearningProgress) {
      final InterviewWeakExpressionState? weak = weakByNode[item.nodeId];
      if (!item.isPrepared ||
          item.nodeId.isEmpty ||
          states.containsKey(item.nodeId) ||
          (weak != null && _isWeakExpressionResolved(weak, item))) {
        continue;
      }
      states[item.nodeId] = ExpressionSceneLearnerNodeState(
        nodeId: item.nodeId,
        prepared: true,
        due: item.nextReviewAt != null && !item.nextReviewAt!.isAfter(now),
      );
    }
    for (final MapEntry<String, InterviewWeakExpressionState> entry
        in weakByNode.entries) {
      final String nodeId = entry.key;
      final InterviewWeakExpressionState item = entry.value;
      if (_isWeakExpressionResolved(item, progressByNode[nodeId])) {
        continue;
      }
      final ExpressionSceneLearnerNodeState? existing = states[nodeId];
      states[nodeId] = ExpressionSceneLearnerNodeState(
        nodeId: nodeId,
        mastered: existing?.mastered ?? false,
        prepared: existing?.prepared ?? false,
        due: existing?.due ?? false,
        weak: true,
      );
    }
    return states.values.toList(growable: false);
  }

  bool _isWeakExpressionResolved(
    InterviewWeakExpressionState weak,
    InterviewExpressionLearningProgress? progress,
  ) {
    if (progress == null) {
      return false;
    }
    final DateTime? lastPracticedAt = progress.lastPracticedAt;
    if (lastPracticedAt == null || lastPracticedAt.isBefore(weak.lastSeenAt)) {
      return false;
    }
    final bool completed =
        progress.isMasteredLinked ||
        progress.isPrepared ||
        progress.hasMinimumWarmup;
    return completed && progress.bestScore >= 72;
  }

  String _nodeIdForWeakExpression(InterviewWeakExpressionState item) {
    return item.sourceNodeId.trim().isNotEmpty
        ? item.sourceNodeId.trim()
        : item.sourceExpressionId.trim();
  }

  List<String> _reviewStagesFromWiki(
    List<InterviewPersonalWikiExpression> masteredWikiExpressions, {
    required String userTier,
  }) {
    final List<InterviewPersonalWikiExpression> reviewQueue =
        _rankedReviewWikiExpressions(masteredWikiExpressions);
    final List<String> queueTags = reviewQueue
        .map((InterviewPersonalWikiExpression item) => item.tag)
        .where((String tag) => tag.isNotEmpty)
        .toList(growable: false);
    final List<String> queueStages = _stagesForTags(
      queueTags,
      userTier: userTier,
    ).take(5).toList(growable: false);
    if (queueStages.isNotEmpty &&
        _dueReviewWikiExpressions(masteredWikiExpressions).isNotEmpty) {
      return queueStages;
    }
    final Map<String, DateTime> latestTagTime = <String, DateTime>{};
    for (final InterviewPersonalWikiExpression item
        in masteredWikiExpressions) {
      if (item.tag.isEmpty || item.text.isEmpty) {
        continue;
      }
      final DateTime current =
          latestTagTime[item.tag] ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (item.masteredAt.isAfter(current)) {
        latestTagTime[item.tag] = item.masteredAt;
      }
    }
    final List<String> tags = latestTagTime.keys.toList(growable: false)
      ..sort(
        (String a, String b) => latestTagTime[b]!.compareTo(latestTagTime[a]!),
      );
    return _stagesForTags(tags, userTier: userTier).take(5).toList();
  }

  List<String> _newLessonStagesFromWiki(
    List<InterviewPersonalWikiExpression> masteredWikiExpressions, {
    required String targetLevel,
    required String userTier,
  }) {
    final Set<String> masteredExpressionIds = masteredWikiExpressions
        .map((InterviewPersonalWikiExpression item) => item.sourceExpressionId)
        .where((String id) => id.isNotEmpty)
        .toSet();
    final Map<String, int> totalByTag = <String, int>{};
    final Map<String, int> masteredByTag = <String, int>{};
    for (final InterviewExpression expression in _expressionsForTargetLevel(
      targetLevel,
    )) {
      if (expression.id.isEmpty) {
        continue;
      }
      totalByTag[expression.tag] = (totalByTag[expression.tag] ?? 0) + 1;
      if (masteredExpressionIds.contains(expression.id)) {
        masteredByTag[expression.tag] =
            (masteredByTag[expression.tag] ?? 0) + 1;
      }
    }
    final List<String> tags = interviewTags
        .where((String tag) {
          if (userTier == 'newbie' && tag == '薪资沟通') {
            return false;
          }
          final int total = totalByTag[tag] ?? 0;
          final int mastered = masteredByTag[tag] ?? 0;
          return total > mastered &&
              _library
                  .expressionsForTag(tag, targetLevel: targetLevel, limit: 12)
                  .any(
                    (InterviewExpression item) =>
                        !masteredExpressionIds.contains(item.id),
                  );
        })
        .toList(growable: false);
    tags.sort((String a, String b) {
      final double aRatio =
          (masteredByTag[a] ?? 0) / math.max(1, totalByTag[a] ?? 0);
      final double bRatio =
          (masteredByTag[b] ?? 0) / math.max(1, totalByTag[b] ?? 0);
      final int ratioCompare = aRatio.compareTo(bRatio);
      if (ratioCompare != 0) {
        return ratioCompare;
      }
      return interviewTags.indexOf(a).compareTo(interviewTags.indexOf(b));
    });
    return _stagesForTags(tags, userTier: userTier).take(5).toList();
  }

  Iterable<String> _stagesForTags(
    Iterable<String> tags, {
    required String userTier,
  }) sync* {
    final Set<String> emittedStages = <String>{};
    for (final String tag in tags) {
      final List<String> stages = tagToPracticeStages[tag] ?? const <String>[];
      for (final String stage in stages) {
        if (stage == 'salary_optional' && userTier == 'newbie') {
          continue;
        }
        if (emittedStages.add(stage)) {
          yield stage;
        }
      }
    }
  }

  List<String> _withWrapUp(
    Iterable<String> stages, {
    required String userTier,
  }) {
    final List<String> result = <String>[];
    for (final String stage in stages) {
      if (stage == 'wrap_up') {
        continue;
      }
      if (stage == 'salary_optional' && userTier == 'newbie') {
        continue;
      }
      if (!result.contains(stage)) {
        result.add(stage);
      }
    }
    if (result.isEmpty) {
      result.add('self_intro');
    }
    result.add('wrap_up');
    return result;
  }

  Map<String, InterviewExpression> _buildReviewStageExpressionTargets(
    List<String> stages, {
    required String targetLevel,
    required List<InterviewPersonalWikiExpression> masteredWikiExpressions,
  }) {
    final List<InterviewExpression> wikiExpressions = masteredWikiExpressions
        .where((InterviewPersonalWikiExpression item) => item.text.isNotEmpty)
        .map(InterviewExpression.fromPersonalWiki)
        .toList(growable: false);
    final List<InterviewExpression> reviewQueueExpressions =
        _rankedReviewWikiExpressions(
          masteredWikiExpressions,
        ).map(InterviewExpression.fromPersonalWiki).toList(growable: false);
    final Map<String, InterviewExpression> targets =
        <String, InterviewExpression>{};
    final Map<String, int> tagCounts = <String, int>{};
    for (final String stage in stages) {
      if (stage == 'wrap_up') {
        continue;
      }
      final String tag = _tagForStage(stage);
      final List<InterviewExpression> sceneCandidates = _library
          .expressionsForTag(tag, targetLevel: targetLevel, limit: 12);
      final List<InterviewExpression> dueTagMatches = reviewQueueExpressions
          .where((InterviewExpression item) => item.tag == tag)
          .toList(growable: false);
      final List<InterviewExpression> tagMatches = wikiExpressions
          .where((InterviewExpression item) => item.tag == tag)
          .toList(growable: false);
      final List<InterviewExpression> candidates = dueTagMatches.isNotEmpty
          ? dueTagMatches
          : sceneCandidates.isNotEmpty
          ? sceneCandidates
          : tagMatches.isNotEmpty
          ? tagMatches
          : wikiExpressions;
      if (candidates.isEmpty) {
        continue;
      }
      final int tagIndex = tagCounts[tag] ?? 0;
      tagCounts[tag] = tagIndex + 1;
      targets[stage] = candidates[tagIndex % candidates.length];
    }
    return targets;
  }

  InterviewExpression? _hintExpressionForStage(
    InterviewPracticeSession session,
    String stage,
  ) {
    final InterviewExpression? stageTarget =
        session.stageExpressionTargets[stage];
    if (stageTarget != null) {
      return stageTarget;
    }
    final String tag = _tagForStage(stage);
    for (final InterviewExpression expression in _library.expressionsForTag(
      tag,
      targetLevel: session.targetLevel,
      limit: 12,
    )) {
      if (!session.masteredExpressionIds.contains(expression.id)) {
        return expression;
      }
    }
    final List<InterviewExpression> fallback = _library.expressionsForTag(
      tag,
      targetLevel: session.targetLevel,
      limit: 1,
    );
    return fallback.isEmpty ? null : fallback.first;
  }

  InterviewHint _nextHint(
    String stage,
    String currentHintLevel, {
    String? question,
    InterviewExpression? targetExpression,
  }) {
    final String nextLevel = switch (currentHintLevel) {
      'none' => 'L1',
      'L1' => 'L2',
      'L2' => 'L3',
      'L3' => 'L4',
      'L4' => 'L4',
      _ => 'L1',
    };
    final InterviewExpressionNode? node =
        _nodeForStage(stage) ??
        (targetExpression == null
            ? null
            : _nodeForExpression(targetExpression));
    if (node != null) {
      final String hintText = node.hintForLevel(nextLevel);
      return InterviewHint(
        level: nextLevel,
        type: 'scene_wiki_hint',
        text: <String>[
          if (nextLevel == 'L4') '可用表达：${node.targetText}',
          '提示：$hintText',
        ].join('\n'),
      );
    }
    final String tag = _tagForStage(stage);
    final Map<String, Object> hints = tagHints[tag] ?? tagHints['自我介绍']!;
    final String expressionText =
        targetExpression?.text ?? (hints['minimal']! as String);
    final String sampleReply = _sampleReplyForStage(stage, expressionText);
    final String lead = switch (nextLevel) {
      'L1' => '可以先这样答',
      'L2' => '把它说完整一点',
      _ => '直接照这个方向说',
    };
    return InterviewHint(
      level: nextLevel,
      type: 'contextual_reply',
      text: <String>['可用表达：$expressionText', '$lead：$sampleReply'].join('\n'),
    );
  }

  String _sampleReplyForStage(String stage, String expressionText) {
    final String expression = _fillExpressionPlaceholders(expressionText);
    return switch (stage) {
      'open' || 'self_intro' =>
        '$expression I have three years of experience in product operations, and I am excited about this opportunity.',
      'background' =>
        '$expression In my last role, I worked on customer growth and learned how to coordinate with product and sales teams.',
      'experience_project' =>
        '$expression I led a small onboarding project, clarified the problem, coordinated the team, and helped make the process smoother.',
      'strength' =>
        '$expression Ownership is one of my strengths. For example, I follow issues through and keep the team updated until they are resolved.',
      'role_fit' =>
        '$expression It matches my experience in operations and gives me room to work on problems I care about.',
      'career_plan' =>
        '$expression I want to grow into someone who can own a bigger part of the business and create measurable impact.',
      'weakness' =>
        '$expression I used to spend too much time polishing details, so now I set clearer checkpoints and ask for feedback earlier.',
      'pressure' =>
        '$expression I stayed calm, clarified the priority, and focused on the next concrete action.',
      'salary_optional' =>
        '$expression I care about the full package and would like to understand the range for this role.',
      'candidate_question' =>
        '$expression I would like to understand what success looks like in the first three months.',
      _ => expression,
    };
  }

  String _fillExpressionPlaceholders(String value) {
    return value
        .replaceAll('[Name]', 'Alex')
        .replaceAll('[City]', 'Shanghai')
        .replaceAll('[X]', 'three')
        .replaceAll('[field]', 'product operations')
        .replaceAll('[field/industry]', 'product operations')
        .replaceAll('[Company]', 'a tech company')
        .replaceAll('[Role]', 'operations specialist')
        .replaceAll('[University]', 'my university')
        .replaceAll('[Major]', 'business')
        .replaceAll('[skill/area]', 'cross-functional coordination')
        .replaceAll('[timeframe]', 'two weeks')
        .replaceAll('[Country]', 'China')
        .replaceAll('[industry]', 'technology')
        .replaceAll('[year]', '2021')
        .replaceAll('[certification]', 'PMP')
        .replaceAll('[topic]', 'your question')
        .replaceAll('[range]', 'a fair market range');
  }
}

class _InterviewIntentMatcher {
  _InterviewIntentMatcher(this.library);

  final InterviewLibrary library;

  InterviewTurnAnalysis match(String stage, String userText) {
    final String text = normalizeInterviewText(userText);
    final Map<String, double> stageScores = _stageScores(stage);
    final Map<String, double> semanticScores = _semanticScores(text);
    final Map<String, double> ruleScores = _ruleScores(text);
    final Map<String, double> finalScores = <String, double>{};
    for (final String tag in interviewTags) {
      finalScores[tag] =
          0.45 * (stageScores[tag] ?? 0) +
          0.4 * (semanticScores[tag] ?? 0) +
          0.15 * (ruleScores[tag] ?? 0);
    }
    final List<MapEntry<String, double>> ranked = finalScores.entries.toList()
      ..sort(
        (MapEntry<String, double> a, MapEntry<String, double> b) =>
            b.value.compareTo(a.value),
      );
    final String predictedTag = ranked.first.key;
    final double confidence = ranked.first.value;
    final List<String> secondaryTags = ranked
        .skip(1)
        .take(2)
        .where(
          (MapEntry<String, double> entry) => confidence - entry.value < 0.12,
        )
        .map((MapEntry<String, double> entry) => entry.key)
        .toList(growable: false);

    final List<String> englishWords = tokenizeInterviewWords(text);
    bool stuckState = _isStuck(text);
    if (englishWords.isEmpty && chineseCharCount(text) > 0) {
      stuckState = true;
    }

    late final String coverageStatus;
    late final double coverageCredit;
    if (stuckState) {
      coverageStatus = 'stuck';
      coverageCredit = 0;
    } else if (confidence >= 0.58 && englishWords.length >= 4) {
      coverageStatus = 'covered';
      coverageCredit = 1;
    } else if (confidence >= 0.35 ||
        englishWords.length >= 2 ||
        chineseCharCount(text) > 0) {
      coverageStatus = 'partial_covered';
      coverageCredit = 0.5;
    } else {
      coverageStatus = 'stuck';
      coverageCredit = 0;
    }

    return InterviewTurnAnalysis(
      predictedTag: predictedTag,
      secondaryTags: secondaryTags,
      confidence: double.parse(confidence.toStringAsFixed(4)),
      coverageStatus: coverageStatus,
      coverageCredit: coverageCredit,
      stuckState: stuckState,
      needsFollowup:
          coverageStatus == 'partial_covered' || englishWords.length < 8,
      correctionHits: _matchCorrections(text),
      languageMixRatio: languageMixRatio(text),
    );
  }

  Map<String, double> _stageScores(String stage) {
    final String? primaryTag = stageToPrimaryTag[stage];
    return <String, double>{
      for (final String tag in interviewTags) tag: tag == primaryTag ? 1 : 0,
    };
  }

  Map<String, double> _semanticScores(String text) {
    final Set<String> tokens = tokenizeInterviewWords(text).toSet();
    final Map<String, double> scores = <String, double>{
      for (final String tag in interviewTags) tag: 0,
    };
    if (tokens.isEmpty) {
      return scores;
    }
    for (final InterviewExpression expression in library.expressions) {
      final Set<String> candidateTokens = tokenizeInterviewWords(
        '${expression.text} ${expression.useCase} ${expression.section}',
      ).toSet();
      if (candidateTokens.isEmpty) {
        continue;
      }
      final int intersection = tokens.intersection(candidateTokens).length;
      final int union = tokens.union(candidateTokens).length;
      final double score = union == 0 ? 0 : intersection / union;
      scores[expression.tag] = math.max(scores[expression.tag] ?? 0, score);
    }
    return scores;
  }

  Map<String, double> _ruleScores(String text) {
    final String normalized = text.toLowerCase();
    final Map<String, double> scores = <String, double>{
      for (final String tag in interviewTags) tag: 0,
    };
    tagRuleFeatures.forEach((String tag, List<String> phrases) {
      final int matches = phrases
          .where((String phrase) => normalized.contains(phrase))
          .length;
      if (matches > 0) {
        scores[tag] = math.min(1, matches / math.max(2, phrases.length / 2));
      }
    });
    return scores;
  }

  bool _isStuck(String text) {
    final String normalized = text.toLowerCase();
    if (normalized.isEmpty || normalized == '...') {
      return true;
    }
    return stuckMarkers.any(normalized.contains);
  }

  List<InterviewCorrectionHit> _matchCorrections(String text) {
    final String normalized = text.toLowerCase();
    final Map<String, InterviewCorrectionHit> hits =
        <String, InterviewCorrectionHit>{};
    for (final InterviewCorrection correction in library.corrections) {
      final String wrong = correction.wrong.toLowerCase();
      if (wrong.isNotEmpty && normalized.contains(wrong)) {
        hits[correction.id] = InterviewCorrectionHit(
          id: correction.id,
          wrong: correction.wrong,
          better: correction.better,
          reason: correction.reason,
        );
      }
    }
    final Map<String, RegExp> regexRules = <String, RegExp>{
      'experience_countable': RegExp(
        r'\bmany experiences\b',
        caseSensitive: false,
      ),
      'interested_vs_interesting': RegExp(
        r'\binteresting in\b',
        caseSensitive: false,
      ),
      'because_so': RegExp(r'\bbecause\b.*\bso\b', caseSensitive: false),
      'although_but': RegExp(r'\balthough\b.*\bbut\b', caseSensitive: false),
      'ability_of': RegExp(
        r'\bability of communication\b',
        caseSensitive: false,
      ),
      'since_with_present': RegExp(
        r'\bi work there since\b',
        caseSensitive: false,
      ),
    };
    regexRules.forEach((String id, RegExp pattern) {
      if (pattern.hasMatch(text)) {
        hits[id] = InterviewCorrectionHit(
          id: id,
          reason: 'Matched heuristic correction rule.',
        );
      }
    });
    return hits.values.toList(growable: false);
  }
}
