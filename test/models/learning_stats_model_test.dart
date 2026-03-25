import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/models/learning_stats_model.dart';

void main() {
  test('fromJson 会解析主字段与嵌套数据', () {
    final LearningStatsModel model = LearningStatsModel.fromJson(
      <String, dynamic>{
        'totalSessions': 12,
        'totalLearningDays': 8,
        'currentStreak': 3,
        'bestScore': 97,
        'totalMinutes': 135,
        'masteredPhrases': 18,
        'accuracyRate': 92,
        'experiencePoints': 560,
        'level': 7,
        'weekActivity': const <bool>[
          true,
          false,
          true,
          false,
          true,
          false,
          true,
        ],
        'skillLevels': <Map<String, dynamic>>[
          <String, dynamic>{'label': '口语', 'level': 88, 'color': '#4A7C6F'},
        ],
        'recentPractices': <Map<String, dynamic>>[
          <String, dynamic>{
            'title': '会议沟通',
            'timeLabel': '今天',
            'score': 95,
            'emoji': '🔥',
            'practicedAt': '2026-03-25T10:30:00.000Z',
          },
        ],
        'updatedAt': '2026-03-25T11:00:00.000Z',
      },
    );

    expect(model.totalSessions, 12);
    expect(model.totalLearningDays, 8);
    expect(model.accuracyRate, 92);
    expect(model.weekActivity, <bool>[
      true,
      false,
      true,
      false,
      true,
      false,
      true,
    ]);
    expect(model.skillLevels.single.label, '口语');
    expect(model.skillLevels.single.color, const Color(0xFF4A7C6F));
    expect(model.recentPractices.single.title, '会议沟通');
    expect(model.updatedAt, DateTime.parse('2026-03-25T11:00:00.000Z'));
  });

  test('fromJson 支持后端别名字段并规范化周活跃数据', () {
    final LearningStatsModel
    model = LearningStatsModel.fromJson(<String, dynamic>{
      'practiceCount': '9',
      'studyDays': '4',
      'checkInStreak': '2',
      'highestScore': '86',
      'practiceMinutes': '61',
      'phrasesMastered': '11',
      'correctRate': '89',
      'totalXp': '240',
      'userLevel': '5',
      'weeklyActivity': <dynamic>[1, '0', true, 'false', '1', 0, 'true', true],
      'abilityDistribution': <Map<String, dynamic>>[
        <String, dynamic>{'name': '听力', 'value': 73, 'colorHex': '0xFF5A6FA8'},
      ],
      'practiceHistory': <Map<String, dynamic>>[
        <String, dynamic>{
          'sceneTitle': '面试问答',
          'displayTime': '昨天',
          'accuracy': '84',
          'createdAt': '2026-03-24T09:00:00.000Z',
        },
      ],
      'statsUpdatedAt': '2026-03-25T08:00:00.000Z',
    });

    expect(model.totalSessions, 9);
    expect(model.totalLearningDays, 4);
    expect(model.bestScore, 86);
    expect(model.totalMinutes, 61);
    expect(model.accuracyRate, 89);
    expect(model.level, 5);
    expect(model.weekActivity, <bool>[
      true,
      false,
      true,
      false,
      true,
      false,
      true,
    ]);
    expect(model.skillLevels.single.color, const Color(0xFF5A6FA8));
    expect(model.recentPractices.single.score, 84);
    expect(model.updatedAt, DateTime.parse('2026-03-25T08:00:00.000Z'));
  });

  test('toJson 会输出规范化后的可序列化结构', () {
    const LearningStatsModel model = LearningStatsModel(
      totalSessions: 5,
      totalLearningDays: 3,
      currentStreak: 2,
      bestScore: 91,
      totalMinutes: 70,
      masteredPhrases: 14,
      accuracyRate: 93,
      experiencePoints: 410,
      level: 6,
      weekActivity: <bool>[true, false, true],
      skillLevels: <SkillLevelModel>[
        SkillLevelModel(label: '表达', level: 81, color: Color(0xFFA0622A)),
      ],
      recentPractices: <PracticeHistoryModel>[
        PracticeHistoryModel(
          title: '客户电话',
          timeLabel: '刚刚',
          score: 90,
          emoji: '🎯',
        ),
      ],
    );

    final Map<String, dynamic> json = model.toJson();

    expect(json['totalSessions'], 5);
    expect(json['weekActivity'], <bool>[
      true,
      false,
      true,
      false,
      false,
      false,
      false,
    ]);
    expect(json['skillLevels'], <Map<String, dynamic>>[
      <String, dynamic>{'label': '表达', 'level': 81, 'color': '#A0622A'},
    ]);
    expect(json['recentPractices'], <Map<String, dynamic>>[
      <String, dynamic>{
        'title': '客户电话',
        'timeLabel': '刚刚',
        'score': 90,
        'emoji': '🎯',
        'practicedAt': null,
      },
    ]);
  });

  test('copyWith 可以更新字段并清空可空值', () {
    final DateTime updatedAt = DateTime.parse('2026-03-25T08:30:00.000Z');
    final LearningStatsModel model = LearningStatsModel(
      totalSessions: 4,
      accuracyRate: 88,
      level: 3,
      updatedAt: updatedAt,
    );

    final LearningStatsModel updated = model.copyWith(
      totalSessions: 9,
      totalMinutes: 45,
      clearAccuracyRate: true,
      clearLevel: true,
      clearUpdatedAt: true,
    );

    expect(updated.totalSessions, 9);
    expect(updated.totalMinutes, 45);
    expect(updated.accuracyRate, isNull);
    expect(updated.level, isNull);
    expect(updated.updatedAt, isNull);
  });

  test('recordLocalSession 会在新学习日累计次数天数分数和分钟数', () {
    final DateTime practicedAt = DateTime.utc(2026, 3, 23, 10, 0);
    const LearningStatsModel model = LearningStatsModel(
      totalSessions: 5,
      totalLearningDays: 2,
      currentStreak: 4,
      bestScore: 80,
      totalMinutes: 20,
    );

    final LearningStatsModel updated = model.recordLocalSession(
      durationSeconds: 185,
      score: 92,
      practicedAt: practicedAt,
    );

    expect(updated.totalSessions, 6);
    expect(updated.totalLearningDays, 3);
    expect(updated.currentStreak, 5);
    expect(updated.bestScore, 92);
    expect(updated.totalMinutes, 23);
    expect(updated.weekActivity, <bool>[
      true,
      false,
      false,
      false,
      false,
      false,
      false,
    ]);
    expect(updated.updatedAt, practicedAt);
  });

  test('recordLocalSession 在同一天重复记录时不会重复累计学习天数', () {
    final DateTime practicedAt = DateTime.utc(2026, 3, 23, 20, 0);
    const LearningStatsModel model = LearningStatsModel(
      totalSessions: 5,
      totalLearningDays: 2,
      currentStreak: 4,
      bestScore: 95,
      totalMinutes: 20,
      weekActivity: <bool>[true, false, false, false, false, false, false],
    );

    final LearningStatsModel updated = model.recordLocalSession(
      durationSeconds: 59,
      score: 80,
      practicedAt: practicedAt,
    );

    expect(updated.totalSessions, 6);
    expect(updated.totalLearningDays, 2);
    expect(updated.currentStreak, 4);
    expect(updated.bestScore, 95);
    expect(updated.totalMinutes, 20);
    expect(updated.weekActivity, <bool>[
      true,
      false,
      false,
      false,
      false,
      false,
      false,
    ]);
  });
}
