import 'package:flutter/material.dart';

enum ProgressState { done, current, locked, idle }

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
  const ExpressionCardData({
    required this.category,
    required this.title,
    required this.pattern,
    required this.image,
    required this.learnerCount,
    required this.difficultyLevel,
    required this.progress,
    required this.thumbHeight,
    required this.color,
  });

  final String category;
  final String title;
  final String pattern;
  final String image;
  final String learnerCount;
  final int difficultyLevel;
  final List<ProgressState> progress;
  final double thumbHeight;
  final Color color;
}

class SceneDraft {
  const SceneDraft({
    required this.title,
    required this.emoji,
    required this.tags,
    required this.goal,
    required this.npcName,
    required this.npcRole,
    required this.environment,
    required this.challenge,
  });

  final String title;
  final String emoji;
  final List<String> tags;
  final String goal;
  final String npcName;
  final String npcRole;
  final String environment;
  final String challenge;
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
  (label: '学习', icon: Icons.menu_book_rounded),
  (label: '场景', icon: Icons.map_outlined),
  (label: '我的', icon: Icons.person_outline_rounded),
];

const expressionCards = <ExpressionCardData>[
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
  goal: '清楚解释项目延期原因，并稳住对方预期。',
  npcName: 'Maya',
  npcRole: '项目经理',
  environment: '周会汇报',
  challenge: '对方会追问延期影响和补救方案。',
);
