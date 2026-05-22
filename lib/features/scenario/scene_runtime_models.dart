import 'package:flutter/material.dart';

import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/models/storage_models.dart';

class RecentSceneSummary {
  const RecentSceneSummary({
    required this.title,
    required this.emoji,
    required this.tags,
    required this.color,
    required this.practiceCount,
    required this.lastTime,
    required this.progress,
    required this.practice,
  });

  final String title;
  final String emoji;
  final List<String> tags;
  final Color color;
  final int practiceCount;
  final String lastTime;
  final int progress;
  final PracticeHistoryModel practice;
}

class VirtualFriendProfile {
  const VirtualFriendProfile({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.role,
    required this.personality,
    required this.profession,
    required this.hobbies,
    required this.relationship,
    required this.preferredScene,
    required this.lastMessage,
    required this.isCustom,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String avatarEmoji;
  final String role;
  final String personality;
  final String profession;
  final List<String> hobbies;
  final String relationship;
  final String preferredScene;
  final String lastMessage;
  final bool isCustom;
  final DateTime updatedAt;

  String get previewText {
    if (lastMessage.trim().isNotEmpty) {
      return lastMessage.trim();
    }
    final List<String> segments = <String>[
      if (profession.trim().isNotEmpty) profession.trim(),
      if (personality.trim().isNotEmpty) personality.trim(),
      if (hobbies.isNotEmpty) '爱好 ${hobbies.take(2).join(' / ')}',
    ];
    if (segments.isNotEmpty) {
      return segments.join(' · ');
    }
    return '点击配置这个虚拟角色的对话设定';
  }

  VirtualFriendStorageModel toStorage() {
    return VirtualFriendStorageModel(
      id: id,
      name: name,
      avatarEmoji: avatarEmoji,
      role: role,
      personality: personality,
      profession: profession,
      hobbies: hobbies,
      relationship: relationship,
      preferredScene: preferredScene,
      lastMessage: lastMessage,
      isCustom: isCustom,
      updatedAt: updatedAt,
    );
  }

  factory VirtualFriendProfile.fromStorage(VirtualFriendStorageModel value) {
    return VirtualFriendProfile(
      id: value.id,
      name: value.name,
      avatarEmoji: value.avatarEmoji.isEmpty ? '🙂' : value.avatarEmoji,
      role: value.role,
      personality: value.personality,
      profession: value.profession,
      hobbies: value.hobbies,
      relationship: value.relationship,
      preferredScene: value.preferredScene,
      lastMessage: value.lastMessage,
      isCustom: value.isCustom,
      updatedAt: value.updatedAt ?? DateTime.now(),
    );
  }

  CharacterProfile toCharacterProfile() {
    final List<String> expertise = <String>[
      if (profession.trim().isNotEmpty) profession.trim(),
      if (role.trim().isNotEmpty && role.trim() != profession.trim()) role.trim(),
    ];
    final List<String> coreTraits = personality
        .split(RegExp(r'[、,，/]'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    return CharacterProfile(
      roleId: id,
      name: name,
      role: role,
      profession: profession,
      personality: personality,
      relationship: relationship,
      background: preferredScene,
      speakingStyle: personality,
      conversationStyle: lastMessage,
      hobbies: hobbies,
      expertise: expertise,
      coreTraits: coreTraits,
    );
  }
}

class SceneAgendaCue {
  const SceneAgendaCue({
    required this.stageLabel,
    required this.learnerTaskEn,
    required this.coachHintZh,
  });

  final String stageLabel;
  final String learnerTaskEn;
  final String coachHintZh;
}

class SceneFeedbackRequestData {
  const SceneFeedbackRequestData({
    required this.key,
    required this.history,
    required this.voiceTurns,
  });

  final String key;
  final List<SceneHistoryTurn> history;
  final List<SceneFeedbackVoiceTurn> voiceTurns;
}

class SceneHintTemplate {
  const SceneHintTemplate({
    required this.keywords,
    required this.starter,
    required this.sample,
  });

  final List<String> keywords;
  final String starter;
  final String sample;
}

class SceneResponseHint {
  const SceneResponseHint({
    required this.stageLabel,
    required this.questionFocus,
    required this.backgroundFocus,
    required this.goalHint,
    required this.keywords,
    required this.starter,
    required this.sampleAnswer,
  });

  final String stageLabel;
  final String questionFocus;
  final String backgroundFocus;
  final String goalHint;
  final List<String> keywords;
  final String starter;
  final String sampleAnswer;
}

class SceneTurnRuntimeContract {
  const SceneTurnRuntimeContract({
    required this.stageLabel,
    required this.questionFocus,
    required this.backgroundFocus,
    required this.learnerTaskEn,
    required this.learnerGoalZh,
    required this.npcTurnSummary,
    required this.npcTurnInstruction,
    required this.keywords,
    required this.starter,
    required this.sampleAnswer,
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

  SceneResponseHint toHint() {
    return SceneResponseHint(
      stageLabel: stageLabel,
      questionFocus: questionFocus,
      backgroundFocus: backgroundFocus,
      goalHint: learnerGoalZh,
      keywords: keywords,
      starter: starter,
      sampleAnswer: sampleAnswer,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stageLabel': stageLabel,
      'questionFocus': questionFocus,
      'backgroundFocus': backgroundFocus,
      'learnerTaskEn': learnerTaskEn,
      'learnerGoalZh': learnerGoalZh,
      'npcTurnSummary': npcTurnSummary,
      'npcTurnInstruction': npcTurnInstruction,
      'keywords': keywords,
      'starter': starter,
      'sampleAnswer': sampleAnswer,
      'confirmedFacts': confirmedFacts,
      'mustAsk': mustAsk,
      'mustAvoid': mustAvoid,
    };
  }
}

enum ServiceSlot {
  item,
  flavor,
  size,
  temperature,
  sweetness,
  milk,
  pickup,
  closing,
}

enum ServiceNextNpcAction { askMissingDetail, closeOrder }

class ServiceDialogueState {
  const ServiceDialogueState({
    this.item,
    this.flavor,
    this.size,
    this.temperature,
    this.sweetness,
    this.milk,
    this.pickup,
  });

  final String? item;
  final String? flavor;
  final String? size;
  final String? temperature;
  final String? sweetness;
  final String? milk;
  final String? pickup;

  bool has(ServiceSlot slot) {
    return switch (slot) {
      ServiceSlot.item => item != null,
      ServiceSlot.flavor => flavor != null,
      ServiceSlot.size => size != null,
      ServiceSlot.temperature => temperature != null,
      ServiceSlot.sweetness => sweetness != null,
      ServiceSlot.milk => milk != null,
      ServiceSlot.pickup => pickup != null,
      ServiceSlot.closing => false,
    };
  }

  String? valueOf(ServiceSlot slot) {
    return switch (slot) {
      ServiceSlot.item => item,
      ServiceSlot.flavor => flavor,
      ServiceSlot.size => size,
      ServiceSlot.temperature => temperature,
      ServiceSlot.sweetness => sweetness,
      ServiceSlot.milk => milk,
      ServiceSlot.pickup => pickup,
      ServiceSlot.closing => null,
    };
  }

  List<String> confirmedSummary() {
    final List<String> parts = <String>[];
    if (item != null) parts.add('item: $item');
    if (flavor != null) parts.add('flavor: $flavor');
    if (size != null) parts.add('size: $size');
    if (temperature != null) parts.add('temperature: $temperature');
    if (sweetness != null) parts.add('sweetness: $sweetness');
    if (milk != null) parts.add('milk: $milk');
    if (pickup != null) parts.add('pickup: $pickup');
    return parts;
  }
}

class ServicePolicyDecision {
  const ServicePolicyDecision({
    required this.cue,
    required this.goalHint,
    required this.questionFocus,
    required this.keywords,
    required this.starter,
    required this.sampleAnswer,
    required this.askedSlots,
    required this.answerSlots,
    required this.state,
    required this.missingSlots,
    required this.latestUserAnsweredSlots,
    required this.nextNpcAction,
    required this.nextNpcInstruction,
    required this.nextNpcSummary,
    this.nextNpcSlot,
  });

  final SceneAgendaCue cue;
  final String goalHint;
  final String questionFocus;
  final List<String> keywords;
  final String starter;
  final String sampleAnswer;
  final List<ServiceSlot> askedSlots;
  final List<ServiceSlot> answerSlots;
  final ServiceDialogueState state;
  final List<ServiceSlot> missingSlots;
  final List<ServiceSlot> latestUserAnsweredSlots;
  final ServiceNextNpcAction nextNpcAction;
  final ServiceSlot? nextNpcSlot;
  final String nextNpcInstruction;
  final String nextNpcSummary;
}

class ServiceTurnTrace {
  const ServiceTurnTrace({
    required this.source,
    required this.createdAt,
    required this.latestUserText,
    required this.latestNpcText,
    required this.assistantReplyText,
    required this.plan,
  });

  final String source;
  final DateTime createdAt;
  final String latestUserText;
  final String latestNpcText;
  final String assistantReplyText;
  final ServicePolicyDecision plan;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'latestUserText': latestUserText,
      'latestNpcText': latestNpcText,
      'assistantReplyText': assistantReplyText,
      'confirmed': plan.state.confirmedSummary(),
      'missingSlots': plan.missingSlots
          .map((ServiceSlot slot) => slot.name)
          .toList(growable: false),
      'askedSlots': plan.askedSlots
          .map((ServiceSlot slot) => slot.name)
          .toList(growable: false),
      'answerSlots': plan.answerSlots
          .map((ServiceSlot slot) => slot.name)
          .toList(growable: false),
      'latestUserAnsweredSlots': plan.latestUserAnsweredSlots
          .map((ServiceSlot slot) => slot.name)
          .toList(growable: false),
      'questionFocus': plan.questionFocus,
      'goalHint': plan.goalHint,
      'starter': plan.starter,
      'sampleAnswer': plan.sampleAnswer,
      'nextNpcAction': plan.nextNpcAction.name,
      'nextNpcSlot': plan.nextNpcSlot?.name,
      'nextNpcInstruction': plan.nextNpcInstruction,
      'nextNpcSummary': plan.nextNpcSummary,
    };
  }
}

enum SceneChatInputType { voice, text }

enum SceneMessageRole { event, npc, user, coach }

class SceneChatMessage {
  const SceneChatMessage({
    required this.role,
    required this.text,
    this.note,
    this.mood,
    this.inputType,
    this.voiceDuration,
    this.audioPath,
    this.isStreaming = false,
    this.accent,
  });

  final SceneMessageRole role;
  final String text;
  final String? note;
  final String? mood;
  final SceneChatInputType? inputType;
  final int? voiceDuration;
  final String? audioPath;
  final bool isStreaming;
  final Color? accent;
}
