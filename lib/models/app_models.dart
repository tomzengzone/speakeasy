import 'package:flutter/material.dart';

enum ProgressState { done, current, locked, idle }

class LessonStepData {
  const LessonStepData({required this.title, required this.body});

  final String title;
  final String body;

  factory LessonStepData.fromJson(Map<String, dynamic> json) {
    return LessonStepData(
      title: (json['title'] as String? ?? '').trim(),
      body: (json['body'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'body': body};
  }
}

class LessonPhraseData {
  const LessonPhraseData({
    required this.en,
    required this.translation,
    required this.note,
    this.audioUrl,
  });

  final String en;
  final String translation;
  final String note;
  final String? audioUrl;

  factory LessonPhraseData.fromJson(Map<String, dynamic> json) {
    return LessonPhraseData(
      en: (json['en'] as String? ?? '').trim(),
      translation: (json['translation'] as String? ?? '').trim(),
      note: (json['note'] as String? ?? '').trim(),
      audioUrl: (json['audioUrl'] as String? ?? json['audio_url'] as String?)
          ?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'en': en,
      'translation': translation,
      'note': note,
      if (audioUrl != null && audioUrl!.isNotEmpty) 'audioUrl': audioUrl,
    };
  }
}

class LessonContentData {
  const LessonContentData({
    this.summary,
    this.takeaways = const <String>[],
    this.steps = const <LessonStepData>[],
    this.sceneNote,
    this.phrases = const <LessonPhraseData>[],
    this.variationPrompt,
    this.variationHint,
    this.variations = const <String>[],
  });

  final String? summary;
  final List<String> takeaways;
  final List<LessonStepData> steps;
  final String? sceneNote;
  final List<LessonPhraseData> phrases;
  final String? variationPrompt;
  final String? variationHint;
  final List<String> variations;

  factory LessonContentData.fromJson(Map<String, dynamic> json) {
    return LessonContentData(
      summary: (json['summary'] as String?)?.trim(),
      takeaways: _readStringList(json['takeaways']),
      steps: _readMapList(
        json['steps'],
      ).map(LessonStepData.fromJson).toList(growable: false),
      sceneNote: (json['sceneNote'] as String? ?? json['scene_note'] as String?)
          ?.trim(),
      phrases: _readMapList(
        json['phrases'],
      ).map(LessonPhraseData.fromJson).toList(growable: false),
      variationPrompt:
          (json['variationPrompt'] as String? ??
                  json['variation_prompt'] as String?)
              ?.trim(),
      variationHint:
          (json['variationHint'] as String? ??
                  json['variation_hint'] as String?)
              ?.trim(),
      variations: _readStringList(json['variations']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (summary != null && summary!.isNotEmpty) 'summary': summary,
      'takeaways': takeaways,
      'steps': steps
          .map((LessonStepData step) => step.toJson())
          .toList(growable: false),
      if (sceneNote != null && sceneNote!.isNotEmpty) 'sceneNote': sceneNote,
      'phrases': phrases
          .map((LessonPhraseData phrase) => phrase.toJson())
          .toList(growable: false),
      if (variationPrompt != null && variationPrompt!.isNotEmpty)
        'variationPrompt': variationPrompt,
      if (variationHint != null && variationHint!.isNotEmpty)
        'variationHint': variationHint,
      'variations': variations,
    };
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _readMapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map>()
        .map((Map item) {
          return item.cast<String, dynamic>();
        })
        .toList(growable: false);
  }
}

class IntentData {
  const IntentData({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class DifficultyOption {
  const DifficultyOption({
    required this.label,
    required this.level,
    required this.color,
  });

  final String label;
  final int level;
  final Color color;
}

class ExpressionCardData {
  ExpressionCardData({
    this.id,
    required this.category,
    required this.title,
    required this.pattern,
    required this.image,
    required this.learnerCount,
    required this.difficultyLevel,
    required this.progress,
    required this.thumbHeight,
    required this.color,
    this.lessonContent,
  });

  factory ExpressionCardData.fromJson(Map<String, dynamic> json) {
    return ExpressionCardData(
      id: json['id'] as String?,
      category: json['category'] as String,
      title: json['title'] as String,
      pattern: json['pattern'] as String,
      image: json['image'] as String,
      learnerCount: '${json['learnerCount'] ?? ''}',
      difficultyLevel: (json['difficultyLevel'] as num?)?.toInt() ?? 1,
      progress:
          ((json['progress'] as List<dynamic>?) ??
                  const <dynamic>['idle', 'locked', 'locked', 'locked'])
              .map((dynamic s) => ProgressState.values.byName('$s'))
              .toList(),
      thumbHeight: (json['thumbHeight'] as num).toDouble(),
      color: _parseColor(json['colorHex'] as String?),
      lessonContent: _parseLessonContent(
        json['lessonContent'] ?? json['lesson_content'],
      ),
    );
  }

  final String? id;
  final String category;
  final String title;
  final String pattern;
  final String image;
  final String learnerCount;
  final int difficultyLevel;
  final List<ProgressState> progress;
  final double thumbHeight;
  final Color color;
  final LessonContentData? lessonContent;

  static Color _parseColor(String? raw) {
    final String normalized = (raw ?? '4A7244')
        .replaceFirst(RegExp('^0x', caseSensitive: false), '')
        .replaceAll('#', '')
        .trim();
    final String hex = switch (normalized.length) {
      6 => 'FF$normalized',
      8 => normalized,
      _ => 'FF4A7244',
    };
    return Color(int.parse(hex, radix: 16));
  }

  static LessonContentData? _parseLessonContent(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return LessonContentData.fromJson(raw);
    }
    if (raw is Map) {
      return LessonContentData.fromJson(raw.cast<String, dynamic>());
    }
    return null;
  }
}

class SceneSpec {
  const SceneSpec({
    required this.category,
    required this.timeContext,
    required this.tone,
    required this.pressureLevel,
    required this.interruptionLevel,
    required this.followupDepth,
    required this.warmth,
    required this.responseLength,
    required this.mustNot,
    required this.mustInclude,
    required this.version,
    this.plotDesign = '',
    this.plotBeats = const <String>[],
    this.lastUserIntent = '',
  });

  final String category;
  final String timeContext;
  final String tone;
  final int pressureLevel;
  final int interruptionLevel;
  final int followupDepth;
  final int warmth;
  final String responseLength;
  final List<String> mustNot;
  final List<String> mustInclude;
  final int version;
  final String plotDesign;
  final List<String> plotBeats;
  final String lastUserIntent;

  factory SceneSpec.fromJson(Map<String, dynamic> json) {
    List<String> readStringList(dynamic value) {
      if (value is! List) {
        return const <String>[];
      }
      return value
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return SceneSpec(
      category: (json['category'] as String? ?? 'general').trim(),
      timeContext: (json['timeContext'] as String? ?? '').trim(),
      tone: (json['tone'] as String? ?? 'neutral').trim(),
      pressureLevel: (json['pressureLevel'] as num?)?.toInt() ?? 3,
      interruptionLevel: (json['interruptionLevel'] as num?)?.toInt() ?? 1,
      followupDepth: (json['followupDepth'] as num?)?.toInt() ?? 3,
      warmth: (json['warmth'] as num?)?.toInt() ?? 2,
      responseLength: (json['responseLength'] as String? ?? 'short').trim(),
      mustNot: readStringList(json['mustNot']),
      mustInclude: readStringList(json['mustInclude']),
      version: (json['version'] as num?)?.toInt() ?? 1,
      plotDesign: (json['plotDesign'] as String? ?? '').trim(),
      plotBeats: readStringList(json['plotBeats']),
      lastUserIntent: (json['lastUserIntent'] as String? ?? '').trim(),
    );
  }

  factory SceneSpec.fromDraft(SceneDraft draft, {SceneSpec? previousSpec}) {
    final String roleSignal = [
      draft.characterProfile?.primaryRoleLabel ?? '',
      draft.characterProfile?.personality,
      draft.characterProfile?.conversationStyle,
    ].where((String? item) => (item ?? '').trim().isNotEmpty).join(' ');
    final String topicSignal = [
      draft.discussionTopic ?? '',
      draft.desiredOutcome ?? '',
    ].where((String item) => item.trim().isNotEmpty).join(' ');

    int derivePressureLevel() {
      final String source =
          '${draft.relationship} ${draft.goal} ${draft.challenge} ${draft.title} $roleSignal $topicSignal';
      if (source.contains('流程') ||
          source.contains('优化') ||
          source.contains('提升') ||
          source.contains('讨论')) {
        return 2;
      }
      if (source.contains('强硬') ||
          source.contains('老板') ||
          source.contains('施压') ||
          source.contains('必须') ||
          source.contains('立刻')) {
        return 5;
      }
      if (source.contains('追问') ||
          source.contains('直接') ||
          source.contains('汇报') ||
          source.contains('延期')) {
        return 4;
      }
      if (source.contains('面试') || source.contains('客户')) {
        return 3;
      }
      return previousSpec?.pressureLevel ?? 2;
    }

    int deriveInterruptionLevel() {
      final String source = '${draft.challenge} ${draft.goal} $roleSignal';
      if (source.contains('打断')) {
        return 4;
      }
      if (source.contains('追问') || source.contains('直接')) {
        return 2;
      }
      return previousSpec?.interruptionLevel ?? 1;
    }

    int deriveFollowupDepth() {
      final String source =
          '${draft.challenge} ${draft.goal} $roleSignal $topicSignal';
      if (source.contains('流程') ||
          source.contains('优化') ||
          source.contains('提升') ||
          source.contains('讨论')) {
        return 3;
      }
      if (source.contains('刁钻') ||
          source.contains('责任') ||
          source.contains('风险')) {
        return 5;
      }
      if (source.contains('追问') ||
          source.contains('补救') ||
          source.contains('方案')) {
        return 4;
      }
      return previousSpec?.followupDepth ?? 3;
    }

    int deriveWarmth() {
      final String source =
          '${draft.relationship} ${draft.challenge} $roleSignal';
      if (source.contains('流程') ||
          source.contains('优化') ||
          source.contains('提升') ||
          source.contains('讨论')) {
        return 3;
      }
      if (source.contains('安抚') ||
          source.contains('配合') ||
          source.contains('理解')) {
        return 4;
      }
      if (source.contains('强硬') ||
          source.contains('施压') ||
          source.contains('追问')) {
        return 1;
      }
      return previousSpec?.warmth ?? 2;
    }

    String deriveTone() {
      final String source =
          '${draft.relationship} ${draft.challenge} $roleSignal';
      if (source.contains('面试') ||
          source.contains('汇报') ||
          source.contains('客户')) {
        return 'professional';
      }
      if (source.contains('强硬') || source.contains('直接')) {
        return 'direct';
      }
      if (source.contains('社交') || source.contains('寒暄')) {
        return 'casual';
      }
      return previousSpec?.tone ?? 'neutral';
    }

    String deriveCategory() {
      final String source =
          '${draft.title} ${draft.environment} ${draft.discussionTopic ?? ''} $roleSignal';
      if (source.contains('流程') ||
          source.contains('优化') ||
          source.contains('提升') ||
          source.contains('讨论')) {
        return 'process_review';
      }
      if (source.contains('点单') ||
          source.contains('点餐') ||
          source.contains('咖啡店') ||
          source.contains('餐厅') ||
          source.contains('前台接待') ||
          source.contains('服务台')) {
        return 'service';
      }
      if (source.contains('面试')) return 'interview';
      if (source.contains('客户')) return 'client';
      if (source.contains('汇报') || source.contains('会议')) return 'work_review';
      if (source.contains('社交')) return 'social';
      return previousSpec?.category ?? 'general';
    }

    List<String> derivePlotBeats() {
      final List<String> previousBeats =
          previousSpec?.plotBeats ?? const <String>[];
      if (previousBeats.isNotEmpty) {
        return previousBeats;
      }
      switch (deriveCategory()) {
        case 'process_review':
          return const <String>[
            '先让对方说明当前最影响协作效率的流程卡点',
            '继续追问造成卡点的根本原因与一个真实例子',
            '要求对方提出一个优先级最高的改进动作',
            '最后锁定负责人、下一步和时间点',
          ];
        case 'work_review':
          return const <String>[
            '先要求对方给出当前进展结论',
            '继续追问主要阻塞或风险来源',
            '要求给出一个明确的补救动作',
            '最后锁定负责人和目标时间点',
          ];
        case 'client':
          return const <String>[
            '先回应客户当前最核心的顾虑',
            '继续解释问题产生的关键原因',
            '提出一个缓解影响或推进合作的动作',
            '最后明确双方的下一步和时间安排',
          ];
        case 'interview':
          return const <String>[
            '先要求用户直接回答问题',
            '继续要求补一个具体例子',
            '追问这个例子的结果和影响',
            '最后补充反思或经验总结',
          ];
        case 'service':
          return const <String>[
            '先让用户直接说想要的饮品或服务需求',
            '只追问还缺少的一个关键信息，比如冷热、尺寸、甜度或奶的选择',
            '继续确认取餐方式或最后一个未明确的细节',
            '最后礼貌收尾，不要重复已经确认过的信息',
          ];
        case 'social':
          return const <String>[
            '先自然回应对方刚才的话',
            '补充一个能延展话题的个人信息',
            '继续接一个轻量追问或反馈',
            '让对话自然延续到下一个话题点',
          ];
        default:
          return const <String>[
            '先说明当前最核心的信息',
            '继续补充最关键的原因或背景',
            '给出一个明确的动作或建议',
            '最后补充时间点、承诺或下一步',
          ];
      }
    }

    String derivePlotDesign(List<String> beats) {
      final String previousPlot = previousSpec?.plotDesign.trim() ?? '';
      if (previousPlot.isNotEmpty) {
        return previousPlot;
      }
      return beats.join('；');
    }

    final Set<String> mustNot = <String>{
      ...?previousSpec?.mustNot,
      '不要重复寒暄',
      '不要解释场景设定',
    };
    if (draft.challenge.contains('不要太凶')) {
      mustNot.add('不要变成攻击性语气');
    }

    final Set<String> mustInclude = <String>{
      ...?previousSpec?.mustInclude,
      '紧扣当前场景目标',
      draft.discussionTopic?.trim() ?? '',
      draft.challenge.trim(),
    }..removeWhere((String item) => item.trim().isEmpty);

    final List<String> plotBeats = derivePlotBeats();
    return SceneSpec(
      category: deriveCategory(),
      timeContext: previousSpec?.timeContext.isNotEmpty == true
          ? previousSpec!.timeContext
          : 'This is an in-progress conversation in ${draft.environment}.',
      tone: deriveTone(),
      pressureLevel: derivePressureLevel(),
      interruptionLevel: deriveInterruptionLevel(),
      followupDepth: deriveFollowupDepth(),
      warmth: deriveWarmth(),
      responseLength: previousSpec?.responseLength ?? 'short',
      mustNot: mustNot.toList(growable: false),
      mustInclude: mustInclude.toList(growable: false),
      version: previousSpec?.version ?? 1,
      plotDesign: derivePlotDesign(plotBeats),
      plotBeats: plotBeats,
      lastUserIntent: draft.challenge.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'category': category,
      'timeContext': timeContext,
      'tone': tone,
      'pressureLevel': pressureLevel,
      'interruptionLevel': interruptionLevel,
      'followupDepth': followupDepth,
      'warmth': warmth,
      'responseLength': responseLength,
      'mustNot': mustNot,
      'mustInclude': mustInclude,
      'version': version,
      'plotDesign': plotDesign,
      'plotBeats': plotBeats,
      'lastUserIntent': lastUserIntent,
    };
  }

  String buildSystemPrompt(
    SceneDraft draft, {
    required bool hasPriorUserTurns,
    required String historyPrompt,
    required bool isRealtime,
    List<String> roleMemoryHints = const <String>[],
    List<String> learningProfileHints = const <String>[],
  }) {
    final CharacterProfile? characterProfile = draft.characterProfile;
    final String characterCorePrompt = characterProfile == null
        ? ''
        : 'Character core (hidden, stable across sessions):\n'
              '- Character identity: ${characterProfile.name}${characterProfile.primaryRoleLabel.isNotEmpty ? ', ${characterProfile.primaryRoleLabel}' : ''}.\n'
              '${characterProfile.personality.trim().isNotEmpty ? '- Personality: ${characterProfile.personality.trim()}.\n' : ''}'
              '${characterProfile.conversationStyle.trim().isNotEmpty ? '- Conversation style: ${characterProfile.conversationStyle.trim()}.\n' : ''}'
              '${characterProfile.speakingStyle.trim().isNotEmpty ? '- Speaking style: ${characterProfile.speakingStyle.trim()}.\n' : ''}'
              '${characterProfile.background.trim().isNotEmpty ? '- Background: ${characterProfile.background.trim()}.\n' : ''}'
              '${characterProfile.expertise.isNotEmpty ? '- Expertise: ${characterProfile.expertise.join(', ')}.\n' : ''}'
              '${characterProfile.hobbies.isNotEmpty ? '- Hobbies or recurring interests: ${characterProfile.hobbies.join(', ')}.\n' : ''}'
              '${characterProfile.coreTraits.isNotEmpty ? '- Core traits to preserve: ${characterProfile.coreTraits.join(', ')}.\n' : ''}'
              '${characterProfile.boundaries.isNotEmpty ? '- Boundaries: ${characterProfile.boundaries.join(', ')}.\n' : ''}'
              '- Keep this character stable while adapting to the current topic.\n';
    final String sessionTopicPrompt = [
      if ((draft.discussionTopic ?? '').trim().isNotEmpty)
        '- This session topic: ${draft.discussionTopic!.trim()}.',
      if ((draft.desiredOutcome ?? '').trim().isNotEmpty)
        '- Desired session outcome: ${draft.desiredOutcome!.trim()}.',
    ].join('\n');
    final String mustNotPrompt = mustNot.isEmpty
        ? ''
        : 'Avoid these behaviors:\n${mustNot.map((String item) => '- $item').join('\n')}\n';
    final String mustIncludePrompt = mustInclude.isEmpty
        ? ''
        : 'Prioritize these scene requirements:\n${mustInclude.map((String item) => '- $item').join('\n')}\n';
    final String responseStyleLine = responseLength == 'short'
        ? '- Keep responses concise (1-2 short sentences).\n'
        : '- Keep responses compact, natural, and tightly focused.\n';
    final String serviceRules = category == 'service'
        ? '- In service or ordering scenes, keep track of which details the learner already gave.\n'
              '- Never ask again for size, temperature, sweetness, milk choice, or dine-in/takeaway if the learner already made it clear.\n'
              '- If several details are still missing, ask only for the single most important missing detail.\n'
        : '';
    final String roleMemoryPrompt = roleMemoryHints.isEmpty
        ? ''
        : 'Role relationship memory (hidden, for continuity only):\n'
              '${roleMemoryHints.map((String item) => '- $item').join('\n')}\n'
              '- Use these memories only to keep this role consistent with the learner.\n'
              '- Do not mention memory explicitly or claim long-term recall unless the learner brings it up.\n';
    final String learningProfilePrompt = learningProfileHints.isEmpty
        ? ''
        : 'Learning profile summary (hidden adaptation only):\n'
              '${learningProfileHints.map((String item) => '- $item').join('\n')}\n'
              '- Use these only to adapt pacing, challenge, and follow-up style.\n'
              '- Keep the current scene primary, and do not expose this profile to the learner.\n';
    return 'You are ${draft.npcName}, a ${draft.npcRole}.\n'
        'The learner is ${draft.userRole}.\n'
        'Relationship context: ${draft.relationship}.\n'
        'Setting: ${draft.environment}.\n'
        'Learner goal: ${draft.goal}.\n'
        'Challenge: ${draft.challenge}.\n'
        '${sessionTopicPrompt.isEmpty ? '' : 'Topic for this session:\n$sessionTopicPrompt\n'}'
        'Scene category: $category.\n'
        'Time context: $timeContext\n'
        '$characterCorePrompt'
        'Hidden behavior settings:\n'
        '- Tone: $tone.\n'
        '- Pressure level: $pressureLevel/5.\n'
        '- Interruption level: $interruptionLevel/5.\n'
        '- Follow-up depth: $followupDepth/5.\n'
        '- Warmth: $warmth/5.\n'
        'Rules:\n'
        '- Speak naturally as your character, stay in role.\n'
        '$responseStyleLine'
        '- Move the scene forward in small steps, one beat at a time.\n'
        '- In each turn, focus on only one key point or one follow-up.\n'
        '- Ask at most one question in a single turn.\n'
        '- If you need multiple details, ask for the most important one first, then wait for the learner.\n'
        '- Before asking a follow-up, check whether the learner already answered that point in the latest turn. Do not ask for the same detail twice.\n'
        '- Respond ONLY in English.\n'
        '- Every spoken word must be English only.\n'
        '- Never reply in Chinese, Japanese, Korean, or any other language.\n'
        '- If unsure, use simpler English instead of switching languages.\n'
        '- Treat the role, relationship, setting, goal, and challenge as hidden instructions.\n'
        '- Treat the character core as stable identity and the session topic as the current discussion target.\n'
        '- You are only the NPC in this scene.\n'
        '- Never speak for the learner, never write the learner\'s line, and never tell the learner what they are saying inside your spoken reply.\n'
        '- Never output dialogue for both sides, speaker labels, stage directions, or coaching language inside the NPC reply.\n'
        '- Do not say what the learner thinks, feels, decides, promises, or will say next.\n'
        '${plotDesign.trim().isNotEmpty ? '- Plot design: $plotDesign.\n' : ''}'
        '${plotBeats.isNotEmpty ? '- Plot beats to follow in order:\n${plotBeats.map((String beat) => '  - $beat').join('\n')}\n' : ''}'
        '$serviceRules'
        '- Never read aloud, summarize, or explain the scenario setup unless the learner explicitly asks.\n'
        '- Never say phrases like "You are", "The learner is", "Setting", "Goal", or "Challenge".\n'
        '- Do not repeat or paraphrase your opening line after the learner responds.\n'
        '${hasPriorUserTurns ? '' : '- The scene opener has already been delivered. Do not greet again or restate the agenda; continue from the learner response.\n'}'
        '${isRealtime ? '- This is a real-time voice conversation, speak naturally.\n- If the learner only says a short greeting such as "hello" or "good morning", briefly acknowledge it and immediately move the conversation forward.\n' : '- Continue from the prior conversation naturally instead of restarting the scene.\n- The learner will speak one turn, then wait for your reply.\n- Reply directly to the latest user turn without explaining the scenario.\n'}'
        '$roleMemoryPrompt'
        '$learningProfilePrompt'
        '$mustNotPrompt'
        '$mustIncludePrompt'
        '$historyPrompt';
  }
}

class CharacterProfile {
  const CharacterProfile({
    this.roleId,
    required this.name,
    this.role = '',
    this.profession = '',
    this.personality = '',
    this.relationship = '',
    this.background = '',
    this.speakingStyle = '',
    this.conversationStyle = '',
    this.hobbies = const <String>[],
    this.expertise = const <String>[],
    this.coreTraits = const <String>[],
    this.boundaries = const <String>[],
  });

  final String? roleId;
  final String name;
  final String role;
  final String profession;
  final String personality;
  final String relationship;
  final String background;
  final String speakingStyle;
  final String conversationStyle;
  final List<String> hobbies;
  final List<String> expertise;
  final List<String> coreTraits;
  final List<String> boundaries;

  String get primaryRoleLabel {
    final String normalizedProfession = profession.trim();
    if (normalizedProfession.isNotEmpty) {
      return normalizedProfession;
    }
    return role.trim();
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((dynamic item) => '$item'.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (roleId?.trim().isNotEmpty ?? false) 'roleId': roleId!.trim(),
      'name': name,
      'role': role,
      'profession': profession,
      'personality': personality,
      'relationship': relationship,
      'background': background,
      'speakingStyle': speakingStyle,
      'conversationStyle': conversationStyle,
      'hobbies': hobbies,
      'expertise': expertise,
      'coreTraits': coreTraits,
      'boundaries': boundaries,
    };
  }

  factory CharacterProfile.fromJson(Map<String, dynamic> json) {
    return CharacterProfile(
      roleId: (json['roleId'] as String?)?.trim(),
      name: (json['name'] as String? ?? '').trim(),
      role: (json['role'] as String? ?? '').trim(),
      profession: (json['profession'] as String? ?? '').trim(),
      personality: (json['personality'] as String? ?? '').trim(),
      relationship: (json['relationship'] as String? ?? '').trim(),
      background: (json['background'] as String? ?? '').trim(),
      speakingStyle: (json['speakingStyle'] as String? ?? '').trim(),
      conversationStyle: (json['conversationStyle'] as String? ?? '').trim(),
      hobbies: _readStringList(json['hobbies']),
      expertise: _readStringList(json['expertise']),
      coreTraits: _readStringList(json['coreTraits']),
      boundaries: _readStringList(json['boundaries']),
    );
  }
}

class SceneBlueprintStage {
  const SceneBlueprintStage({
    required this.key,
    required this.label,
    required this.objective,
    this.exitCriteria = const <String>[],
  });

  final String key;
  final String label;
  final String objective;
  final List<String> exitCriteria;

  factory SceneBlueprintStage.fromJson(Map<String, dynamic> json) {
    List<String> readStringList(dynamic value) {
      if (value is! List) {
        return const <String>[];
      }
      return value
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return SceneBlueprintStage(
      key: (json['key'] as String? ?? 'stage').trim(),
      label: (json['label'] as String? ?? '阶段').trim(),
      objective: (json['objective'] as String? ?? '').trim(),
      exitCriteria: readStringList(
        json['exitCriteria'] ?? json['exit_criteria'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'label': label,
      'objective': objective,
      'exitCriteria': exitCriteria,
    };
  }
}

class SceneBlueprint {
  const SceneBlueprint({
    required this.title,
    required this.category,
    required this.userRole,
    required this.agentRole,
    required this.relationship,
    required this.goal,
    required this.tone,
    required this.constraints,
    required this.mustCover,
    required this.forbiddenDrift,
    required this.stages,
    required this.completionCriteria,
    required this.version,
  });

  final String title;
  final String category;
  final String userRole;
  final String agentRole;
  final String relationship;
  final String goal;
  final String tone;
  final List<String> constraints;
  final List<String> mustCover;
  final List<String> forbiddenDrift;
  final List<SceneBlueprintStage> stages;
  final List<String> completionCriteria;
  final int version;

  factory SceneBlueprint.fromJson(Map<String, dynamic> json) {
    List<String> readStringList(dynamic value) {
      if (value is! List) {
        return const <String>[];
      }
      return value
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final List<SceneBlueprintStage> stages =
        ((json['stages'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic item) {
              if (item is Map<String, dynamic>) {
                return SceneBlueprintStage.fromJson(item);
              }
              if (item is Map) {
                return SceneBlueprintStage.fromJson(
                  item.cast<String, dynamic>(),
                );
              }
              return null;
            })
            .whereType<SceneBlueprintStage>()
            .toList(growable: false);

    return SceneBlueprint(
      title: (json['title'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? 'general').trim(),
      userRole: (json['userRole'] as String? ?? '').trim(),
      agentRole: (json['agentRole'] as String? ?? '').trim(),
      relationship: (json['relationship'] as String? ?? '').trim(),
      goal: (json['goal'] as String? ?? '').trim(),
      tone: (json['tone'] as String? ?? 'neutral').trim(),
      constraints: readStringList(json['constraints']),
      mustCover: readStringList(json['mustCover']),
      forbiddenDrift: readStringList(json['forbiddenDrift']),
      stages: stages,
      completionCriteria: readStringList(json['completionCriteria']),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  factory SceneBlueprint.fromDraft(
    SceneDraft draft, {
    SceneSpec? sceneSpec,
    SceneBlueprint? previousBlueprint,
  }) {
    final SceneSpec resolvedSpec =
        sceneSpec ?? draft.sceneSpec ?? SceneSpec.fromDraft(draft);
    final List<String> constraints = <String>{
      'Stay in role as ${draft.npcName.isNotEmpty ? draft.npcName : 'the NPC'}.',
      'Keep the conversation focused on the learner goal.',
      ...resolvedSpec.mustInclude,
    }.where((String item) => item.trim().isNotEmpty).toList(growable: false);
    final List<String> forbiddenDrift = <String>{
      'Do not switch to coaching language in the NPC reply.',
      'Do not restart the scene after it has started.',
      ...resolvedSpec.mustNot,
      ..._sceneBlueprintForbiddenDrift(
        resolvedSpec.category,
        previousBlueprint: previousBlueprint,
      ),
    }.where((String item) => item.trim().isNotEmpty).toList(growable: false);
    final List<String> mustCover = _sceneBlueprintMustCover(
      resolvedSpec.category,
      draft: draft,
      previousBlueprint: previousBlueprint,
    );
    final List<SceneBlueprintStage> stages = _sceneBlueprintStagesFromSpec(
      resolvedSpec,
      previousBlueprint: previousBlueprint,
    );
    return SceneBlueprint(
      title: draft.title,
      category: resolvedSpec.category,
      userRole: draft.userRole,
      agentRole: draft.npcRole,
      relationship: draft.relationship,
      goal: draft.goal,
      tone: resolvedSpec.tone,
      constraints: constraints,
      mustCover: mustCover,
      forbiddenDrift: forbiddenDrift,
      stages: stages,
      completionCriteria: _sceneBlueprintCompletionCriteria(
        resolvedSpec.category,
        mustCover: mustCover,
        previousBlueprint: previousBlueprint,
      ),
      version: previousBlueprint?.version ?? resolvedSpec.version,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'category': category,
      'userRole': userRole,
      'agentRole': agentRole,
      'relationship': relationship,
      'goal': goal,
      'tone': tone,
      'constraints': constraints,
      'mustCover': mustCover,
      'forbiddenDrift': forbiddenDrift,
      'stages': stages
          .map((SceneBlueprintStage stage) => stage.toJson())
          .toList(growable: false),
      'completionCriteria': completionCriteria,
      'version': version,
    };
  }
}

List<String> _sceneBlueprintMustCover(
  String category, {
  required SceneDraft draft,
  SceneBlueprint? previousBlueprint,
}) {
  if (previousBlueprint != null && previousBlueprint.mustCover.isNotEmpty) {
    return previousBlueprint.mustCover;
  }
  switch (category) {
    case 'service':
      return const <String>[
        'main_request',
        'size_or_quantity',
        'customization',
        'pickup_or_finish',
      ];
    case 'interview':
      return const <String>[
        'direct_answer',
        'specific_example',
        'result_or_impact',
        'reflection',
      ];
    case 'client':
      return const <String>[
        'client_concern',
        'root_cause',
        'mitigation',
        'next_step',
      ];
    case 'work_review':
    case 'process_review':
      return const <String>[
        'current_state',
        'main_risk',
        'action_plan',
        'owner_and_timeline',
      ];
    case 'social':
      return const <String>[
        'natural_opening',
        'personal_detail',
        'followup_question',
      ];
    default:
      return <String>[
        'core_point',
        if (draft.challenge.trim().isNotEmpty) 'challenge_response',
        'next_step',
      ];
  }
}

List<String> _sceneBlueprintForbiddenDrift(
  String category, {
  SceneBlueprint? previousBlueprint,
}) {
  if (previousBlueprint != null &&
      previousBlueprint.forbiddenDrift.isNotEmpty) {
    return previousBlueprint.forbiddenDrift;
  }
  switch (category) {
    case 'service':
      return const <String>[
        'repeat_slots_already_confirmed',
        'switch_to_small_talk_too_early',
      ];
    case 'interview':
      return const <String>[
        'ask_multi_part_questions_in_one_turn',
        'leave_the_candidate_without_a_clear_focus',
      ];
    default:
      return const <String>['drift_away_from_scene_goal'];
  }
}

List<SceneBlueprintStage> _sceneBlueprintStagesFromSpec(
  SceneSpec sceneSpec, {
  SceneBlueprint? previousBlueprint,
}) {
  if (previousBlueprint != null && previousBlueprint.stages.isNotEmpty) {
    return previousBlueprint.stages;
  }
  final List<String> beats = sceneSpec.plotBeats.isEmpty
      ? const <String>['先说明当前核心情况', '再解释关键原因', '接着给出一个具体动作', '最后锁定下一步和时间点']
      : sceneSpec.plotBeats;
  return beats
      .asMap()
      .entries
      .map((MapEntry<int, String> entry) {
        final int index = entry.key;
        final String beat = entry.value.trim();
        final String key = switch (index) {
          0 => 'opening',
          1 => 'clarify',
          2 => 'detail',
          3 => 'close',
          _ => 'stage_${index + 1}',
        };
        final String label = switch (index) {
          0 => 'Opening',
          1 => 'Clarify',
          2 => 'Detail',
          3 => 'Close',
          _ => 'Stage ${index + 1}',
        };
        return SceneBlueprintStage(
          key: key,
          label: label,
          objective: beat,
          exitCriteria: <String>[
            'learner_addresses_$key',
            if (index == beats.length - 1) 'conversation_can_close_cleanly',
          ],
        );
      })
      .toList(growable: false);
}

List<String> _sceneBlueprintCompletionCriteria(
  String category, {
  required List<String> mustCover,
  SceneBlueprint? previousBlueprint,
}) {
  if (previousBlueprint != null &&
      previousBlueprint.completionCriteria.isNotEmpty) {
    return previousBlueprint.completionCriteria;
  }
  return <String>[
    'all_required_stages_progressed',
    ...mustCover.map((String item) => 'covered_$item'),
    if (category == 'service') 'order_or_request_confirmed',
    if (category != 'service') 'next_step_or_close_confirmed',
  ];
}

class SceneDraft {
  const SceneDraft({
    required this.title,
    required this.emoji,
    required this.tags,
    this.roleId,
    this.characterProfile,
    this.discussionTopic,
    this.desiredOutcome,
    required this.userRole,
    required this.relationship,
    required this.goal,
    required this.npcName,
    required this.npcRole,
    required this.environment,
    required this.challenge,
    this.plotDesign = '',
    this.sceneSpec,
    this.sceneBlueprint,
  });

  final String title;
  final String emoji;
  final List<String> tags;
  final String? roleId;
  final CharacterProfile? characterProfile;
  final String? discussionTopic;
  final String? desiredOutcome;
  final String userRole;
  final String relationship;
  final String goal;
  final String npcName;
  final String npcRole;
  final String environment;
  final String challenge;
  final String plotDesign;
  final SceneSpec? sceneSpec;
  final SceneBlueprint? sceneBlueprint;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'emoji': emoji,
      'tags': tags,
      if (roleId?.trim().isNotEmpty ?? false) 'roleId': roleId!.trim(),
      if (characterProfile != null)
        'characterProfile': characterProfile!.toJson(),
      if (discussionTopic?.trim().isNotEmpty ?? false)
        'discussionTopic': discussionTopic!.trim(),
      if (desiredOutcome?.trim().isNotEmpty ?? false)
        'desiredOutcome': desiredOutcome!.trim(),
      'userRole': userRole,
      'relationship': relationship,
      'goal': goal,
      'npcName': npcName,
      'npcRole': npcRole,
      'environment': environment,
      'challenge': challenge,
      'plotDesign': plotDesign,
      if (sceneSpec != null)
        'sceneSpec': <String, dynamic>{
          'category': sceneSpec!.category,
          'timeContext': sceneSpec!.timeContext,
          'tone': sceneSpec!.tone,
          'pressureLevel': sceneSpec!.pressureLevel,
          'interruptionLevel': sceneSpec!.interruptionLevel,
          'followupDepth': sceneSpec!.followupDepth,
          'warmth': sceneSpec!.warmth,
          'responseLength': sceneSpec!.responseLength,
          'mustNot': sceneSpec!.mustNot,
          'mustInclude': sceneSpec!.mustInclude,
          'version': sceneSpec!.version,
          'plotDesign': sceneSpec!.plotDesign,
          'plotBeats': sceneSpec!.plotBeats,
          'lastUserIntent': sceneSpec!.lastUserIntent,
        },
      if (sceneBlueprint != null) 'sceneBlueprint': sceneBlueprint!.toJson(),
    };
  }

  factory SceneDraft.fromJson(Map<String, dynamic> json) {
    final dynamic sceneSpecValue = json['sceneSpec'];
    final dynamic sceneBlueprintValue = json['sceneBlueprint'];
    final dynamic characterProfileValue = json['characterProfile'];
    SceneSpec? sceneSpec;
    SceneBlueprint? sceneBlueprint;
    CharacterProfile? characterProfile;
    if (sceneSpecValue is Map<String, dynamic>) {
      sceneSpec = SceneSpec.fromJson(sceneSpecValue);
    } else if (sceneSpecValue is Map) {
      sceneSpec = SceneSpec.fromJson(sceneSpecValue.cast<String, dynamic>());
    }
    if (sceneBlueprintValue is Map<String, dynamic>) {
      sceneBlueprint = SceneBlueprint.fromJson(sceneBlueprintValue);
    } else if (sceneBlueprintValue is Map) {
      sceneBlueprint = SceneBlueprint.fromJson(
        sceneBlueprintValue.cast<String, dynamic>(),
      );
    }
    if (characterProfileValue is Map<String, dynamic>) {
      characterProfile = CharacterProfile.fromJson(characterProfileValue);
    } else if (characterProfileValue is Map) {
      characterProfile = CharacterProfile.fromJson(
        characterProfileValue.cast<String, dynamic>(),
      );
    }
    return SceneDraft(
      title: (json['title'] as String? ?? '').trim(),
      emoji: (json['emoji'] as String? ?? '🎯').trim(),
      tags: ((json['tags'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false),
      roleId: (json['roleId'] as String?)?.trim(),
      characterProfile: characterProfile,
      discussionTopic: (json['discussionTopic'] as String?)?.trim(),
      desiredOutcome: (json['desiredOutcome'] as String?)?.trim(),
      userRole: (json['userRole'] as String? ?? '').trim(),
      relationship: (json['relationship'] as String? ?? '').trim(),
      goal: (json['goal'] as String? ?? '').trim(),
      npcName: (json['npcName'] as String? ?? '').trim(),
      npcRole: (json['npcRole'] as String? ?? '').trim(),
      environment: (json['environment'] as String? ?? '').trim(),
      challenge: (json['challenge'] as String? ?? '').trim(),
      plotDesign: (json['plotDesign'] as String? ?? '').trim(),
      sceneSpec: sceneSpec,
      sceneBlueprint: sceneBlueprint,
    );
  }
}

const appBackground = Color(0xFFFDFCF9);
const shellBackground = Color(0xFFEAE7E0);
const primaryGreen = Color(0xFF4A7244);
const darkGreen = Color(0xFF3D5C3A);
const textPrimary = Color(0xFF2A2820);
const textSecondary = Color(0xFF9A9289);
const textTertiary = Color(0xFFABA39A);
const borderColor = Color(0xFFE8E3DC);
const separatorColor = Color(0xFFF0ECE6);

const intents = <IntentData>[
  IntentData(
    label: '不会开口',
    color: Color(0xFF4A7C6F),
    icon: Icons.mic_off_rounded,
  ),
  IntentData(
    label: '不会表达',
    color: Color(0xFF5A6FA8),
    icon: Icons.translate_rounded,
  ),
  IntentData(
    label: '说不下去',
    color: Color(0xFFA0622A),
    icon: Icons.remove_circle_outline_rounded,
  ),
  IntentData(label: '一慌就乱', color: Color(0xFF7B4EA0), icon: Icons.bolt_rounded),
  IntentData(
    label: '说得更好',
    color: Color(0xFF3D7FA8),
    icon: Icons.auto_awesome_rounded,
  ),
];

const sections = <String>['推荐', '全部', '收藏', '不感兴趣', '完成'];

const difficultyOptions = <DifficultyOption>[
  DifficultyOption(label: '全部', level: 0, color: darkGreen),
  DifficultyOption(label: '入门', level: 1, color: Color(0xFF7A5C3A)),
  DifficultyOption(label: '初级', level: 2, color: Color(0xFF4A607A)),
  DifficultyOption(label: '中级', level: 3, color: Color(0xFF4A6741)),
  DifficultyOption(label: '高级', level: 4, color: Color(0xFF7B4EA0)),
  DifficultyOption(label: '精通', level: 5, color: Color(0xFFA04A4A)),
];

const bottomTabs = <({String label, IconData icon})>[
  (label: '情景学习', icon: Icons.menu_book_rounded),
  (label: '推荐表达', icon: Icons.record_voice_over_rounded),
  (label: '我的', icon: Icons.person_outline_rounded),
];

final expressionCards = <ExpressionCardData>[
  ExpressionCardData(
    category: '不会开口',
    title: '自然地说出第一句',
    pattern: 'Mind if I join you? I\'m ___.',
    image:
        'https://images.unsplash.com/photo-1678345201361-f070f85b62a5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600',
    learnerCount: '47.4w',
    difficultyLevel: 1,
    progress: [
      ProgressState.idle,
      ProgressState.locked,
      ProgressState.locked,
      ProgressState.locked,
    ],
    thumbHeight: 140,
    color: Color(0xFF4A7C6F),
  ),
  ExpressionCardData(
    category: '不会开口',
    title: '和陌生人搭话',
    pattern: 'I couldn\'t help but notice — ___.',
    image:
        'https://images.unsplash.com/photo-1770565280770-57448f53f8dc?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600',
    learnerCount: '32.1w',
    difficultyLevel: 2,
    progress: [
      ProgressState.done,
      ProgressState.current,
      ProgressState.locked,
      ProgressState.locked,
    ],
    thumbHeight: 115,
    color: Color(0xFF4A7C6F),
  ),
  ExpressionCardData(
    category: '不会开口',
    title: '在第一次见面时开口',
    pattern: 'I don\'t think we\'ve met. I\'m ___.',
    image:
        'https://images.unsplash.com/photo-1763739530672-4aadafbd81ff?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600',
    learnerCount: '18.5w',
    difficultyLevel: 2,
    progress: [
      ProgressState.done,
      ProgressState.done,
      ProgressState.current,
      ProgressState.locked,
    ],
    thumbHeight: 155,
    color: Color(0xFF4A7C6F),
  ),
  ExpressionCardData(
    category: '不会表达',
    title: '表达自己的看法',
    pattern: 'Honestly, I feel like ___.',
    image:
        'https://images.unsplash.com/photo-1766867257943-0665537fb2dd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600',
    learnerCount: '25.0w',
    difficultyLevel: 2,
    progress: [
      ProgressState.done,
      ProgressState.current,
      ProgressState.locked,
      ProgressState.locked,
    ],
    thumbHeight: 145,
    color: Color(0xFF5A6FA8),
  ),
  ExpressionCardData(
    category: '不会表达',
    title: '说出你想要什么',
    pattern: 'What I mean is ___.',
    image:
        'https://images.unsplash.com/photo-1690192435015-319c1d5065b2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600',
    learnerCount: '15.7w',
    difficultyLevel: 3,
    progress: [
      ProgressState.done,
      ProgressState.done,
      ProgressState.current,
      ProgressState.locked,
    ],
    thumbHeight: 130,
    color: Color(0xFF5A6FA8),
  ),
  ExpressionCardData(
    category: '说不下去',
    title: '把一句话说完整',
    pattern: 'And the reason is ___.',
    image:
        'https://images.unsplash.com/photo-1714942179079-4fddb552d41d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600',
    learnerCount: '22.4w',
    difficultyLevel: 1,
    progress: [
      ProgressState.idle,
      ProgressState.locked,
      ProgressState.locked,
      ProgressState.locked,
    ],
    thumbHeight: 140,
    color: Color(0xFFA0622A),
  ),
  ExpressionCardData(
    category: '一慌就乱',
    title: '没听清时请对方再说一遍',
    pattern: 'Could you say that again? I want to make sure I got it.',
    image:
        'https://images.unsplash.com/photo-1689857659236-157790e6d4c2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600',
    learnerCount: '35.0w',
    difficultyLevel: 2,
    progress: [
      ProgressState.done,
      ProgressState.current,
      ProgressState.locked,
      ProgressState.locked,
    ],
    thumbHeight: 155,
    color: Color(0xFF7B4EA0),
  ),
  ExpressionCardData(
    category: '说得更好',
    title: '礼貌地拒绝别人',
    pattern: 'I really appreciate it — though ___.',
    image:
        'https://images.unsplash.com/photo-1645753573116-0b515ae0b7ea?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600',
    learnerCount: '41.2w',
    difficultyLevel: 2,
    progress: [
      ProgressState.done,
      ProgressState.done,
      ProgressState.current,
      ProgressState.locked,
    ],
    thumbHeight: 145,
    color: Color(0xFF3D7FA8),
  ),
];

const examplePrompts = <String>[
  '我想模拟和老板解释项目延期',
  '我想练第一次和外国客户寒暄',
  '模拟雅思口语 Part 2，考官会追问',
  '帮我练习在周会上汇报工作进展',
  '我要模拟一场英文电话面试',
];

const quickScenes = <({String emoji, String label, Color color, Color bg})>[
  (emoji: '📊', label: '会议汇报', color: Color(0xFF4A7C6F), bg: Color(0x1A4A7C6F)),
  (emoji: '💼', label: '面试问答', color: Color(0xFF5A6FA8), bg: Color(0x1A5A6FA8)),
  (emoji: '🤝', label: '客户沟通', color: Color(0xFFA0622A), bg: Color(0x1AA0622A)),
  (emoji: '💬', label: '社交聊天', color: Color(0xFF4A6741), bg: Color(0x1A4A6741)),
  (emoji: '✈️', label: '旅行应急', color: Color(0xFF3D7FA8), bg: Color(0x1A3D7FA8)),
  (emoji: '🎓', label: '雅思口语', color: Color(0xFF7B4EA0), bg: Color(0x1A7B4EA0)),
];

const sampleSceneDraft = SceneDraft(
  title: '解释项目延期',
  emoji: '📊',
  tags: ['AI 定制', '口语练习', '高压场景'],
  userRole: '项目负责人',
  relationship: '向项目经理汇报项目进展的内部协作关系',
  goal: '清楚解释项目延期原因，并稳住对方预期。',
  npcName: 'Maya',
  npcRole: '项目经理',
  environment: '周会汇报',
  challenge: '对方会追问延期影响和补救方案。',
  plotDesign: '先说明当前延期现状；再解释延期原因；接着给出补救动作；最后锁定负责人和时间点。',
);
