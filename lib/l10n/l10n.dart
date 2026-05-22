import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

class L10n {
  const L10n._();

  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      AppLocalizations.localizationsDelegates;
}

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension AppLocalizationsMappings on AppLocalizations {
  String intentLabel(String value) {
    return switch (value) {
      '不会开口' => intentNoOpening,
      '不会表达' => intentCannotExpress,
      '说不下去' => intentCannotContinue,
      '一慌就乱' => intentPanic,
      '说得更好' => intentSpeakBetter,
      _ => value,
    };
  }

  String sectionLabel(String value) {
    return switch (value) {
      '推荐' => sectionRecommended,
      '全部' => sectionAll,
      '收藏' => sectionFavorites,
      '不感兴趣' => sectionNotInterested,
      '完成' => sectionCompleted,
      _ => value,
    };
  }

  String difficultyLabel(String value) {
    return switch (value) {
      '全部' => difficultyAll,
      '入门' => levelBeginner,
      '初级' => levelElementary,
      '中级' => levelIntermediate,
      '高级' => levelAdvanced,
      '精通' => difficultyMastery,
      _ => value,
    };
  }

  String bottomTabLabel(String value) {
    return switch (value) {
      '学习' => learning,
      '表达' => '表达',
      '场景' => scene,
      '我的' => profile,
      _ => value,
    };
  }

  String onboardingGoalDescription(String value) {
    return switch (value) {
      '不会开口' => goalDescNoOpening,
      '不会表达' => goalDescCannotExpress,
      '说不下去' => goalDescCannotContinue,
      '一慌就乱' => goalDescPanic,
      '说得更好' => goalDescSpeakBetter,
      _ => value,
    };
  }

  String levelDescription(String value) {
    return switch (value) {
      '日常单词认识，但很难开口说' => levelBeginnerDesc,
      '能说简单句子，但不够流利' => levelElementaryDesc,
      '可以日常交流，但表达不自然' => levelIntermediateDesc,
      '表达流利，想进一步提升地道度' => levelAdvancedDesc,
      _ => value,
    };
  }

  String dailyGoalLabel(String value) {
    return switch (value) {
      '5 分钟' => dailyGoal5Minutes,
      '15 分钟' => dailyGoal15Minutes,
      '30 分钟' => dailyGoal30Minutes,
      _ => value,
    };
  }

  String dailyGoalDescription(String value) {
    return switch (value) {
      '随手练练' => dailyGoal5Desc,
      '稳步提升' => dailyGoal15Desc,
      '快速突破' => dailyGoal30Desc,
      _ => value,
    };
  }

  String dailyGoalBadge(String value) {
    return switch (value) {
      '最受欢迎' => mostPopular,
      _ => value,
    };
  }

  String lessonTakeaway(String value) {
    return switch (value) {
      '1 个可直接套用的开口框架' => takeawayFramework,
      '2 个自然不僵硬的变体表达' => takeawayVariations,
      '1 次完整的场景开口输出' => takeawaySceneOutput,
      _ => value,
    };
  }

  String lessonSummary(String value) {
    return switch (value) {
      '不会开口' => lessonSummaryNoOpening,
      '不会表达' => lessonSummaryCannotExpress,
      '说不下去' => lessonSummaryCannotContinue,
      '一慌就乱' => lessonSummaryPanic,
      _ => lessonSummaryDefault,
    };
  }

  String learningTitle(String value) {
    return switch (value) {
      '先理解场景' => learningStepUnderstandScene,
      '先学这 3 句' => learningStepLearn3Phrases,
      '跟我一起说' => learningStepRepeatAfterMe,
      '换一种说法并自己输出' => learningStepVariationOutput,
      _ => value,
    };
  }

  String learningBody(String value) {
    return switch (value) {
      '先理解为什么这类场景容易卡住，再建立“自然开场”的直觉。' => learningBodyUnderstandScene,
      '先拿走 3 句最顺手的表达，知道它们分别适合什么语气。' => learningBodyLearn3Phrases,
      '先跟着说，稳住语调和节奏，再慢慢提高自然度。' => learningBodyRepeatAfterMe,
      '把固定结构换词，最后完成一次你自己的表达。' => learningBodyVariationOutput,
      _ => value,
    };
  }

  String phraseNote(String value) {
    return switch (value) {
      '适合会议开场' => phraseNoteMeetingOpening,
      '推进节奏最自然' => phraseNoteNaturalPacing,
      '说明目的更清楚' => phraseNoteClearPurpose,
      _ => value,
    };
  }

  String weekdayShort(int index) {
    return switch (index) {
      0 => weekdayMon,
      1 => weekdayTue,
      2 => weekdayWed,
      3 => weekdayThu,
      4 => weekdayFri,
      5 => weekdaySat,
      _ => weekdaySun,
    };
  }

  String membershipFeatureTitle(String value) {
    return switch (value) {
      '无限场景练习' => featureUnlimitedScenePractice,
      '完整句型库' => featureFullPhraseLibrary,
      'AI 深度反馈' => featureAiDeepFeedback,
      '沉浸式对话' => featureImmersiveConversation,
      '离线学习包' => featureOfflineLearningPack,
      '专属学习报告' => featureExclusiveLearningReport,
      _ => value,
    };
  }

  String membershipFeatureDescription(String value) {
    return switch (value) {
      '不限次数畅享所有场景' => featureUnlimitedScenePracticeDesc,
      '500+ 地道英语句型' => featureFullPhraseLibraryDesc,
      '语音分析和发音纠正' => featureAiDeepFeedbackDesc,
      '无限次沉浸对话练习' => featureImmersiveConversationDesc,
      '下载场景离线练习' => featureOfflineLearningPackDesc,
      '详细能力分析报告' => featureExclusiveLearningReportDesc,
      _ => value,
    };
  }

  String membershipCompareLabel(String value) {
    return switch (value) {
      '每日 3 次场景练习' => compareDaily3ScenePractice,
      '基础句型库（50+）' => compareBasePhraseLibrary50,
      '学习进度追踪' => compareLearningProgressTracking,
      '无限场景练习' => compareUnlimitedScenePractice,
      '完整句型库（500+）' => compareFullPhraseLibrary500,
      'AI 深度对话反馈' => compareAiDeepConversationFeedback,
      '离线学习包' => compareOfflineLearningPack,
      '专属学习报告' => compareExclusiveLearningReport,
      _ => value,
    };
  }

  String planName(String value) {
    return switch (value) {
      '周度会员' => planWeekly,
      '月度会员' => planMonthly,
      '年度会员' => planYearly,
      _ => value,
    };
  }

  String planUnit(String value) {
    return switch (value) {
      '周' => planUnitWeek,
      '月' => planUnitMonth,
      '年' => planUnitYear,
      _ => value,
    };
  }

  String planNote(String value) {
    return switch (value) {
      '短期体验，自动续费，可随时取消' => planNoteWeekly,
      '稳定进阶，自动续费，可随时取消' => planNoteMonthly,
      '最推荐，自动续费，相当于 ¥24.8/月' => planNoteYearly,
      _ => value,
    };
  }

  String planBadge(String value) {
    return switch (value) {
      '入门' => planBadgeStarter,
      '省更多' => planBadgeBestValue,
      _ => value,
    };
  }

  String sceneFeedbackHeadline(String value) {
    return switch (value) {
      '核心任务完成，细节还可以打磨 ✨' => sceneFeedbackHeadlineComplete,
      '已经开了个好头，继续练习会更流畅 💪' => sceneFeedbackHeadlineGoodStart,
      _ => value,
    };
  }

  String sceneFeedbackMetric(String value) {
    return switch (value) {
      '清晰度' => sceneFeedbackMetricClarity,
      '结构感' => sceneFeedbackMetricStructure,
      '临场应对' => sceneFeedbackMetricPressure,
      _ => value,
    };
  }

  String sceneFeedbackCoach(String value) {
    return switch (value) {
      '下一轮把恢复方案提前说出来，再补一句具体时间点，表达会更像真实职场风格。' => sceneFeedbackCoachTip,
      _ => value,
    };
  }

  String sceneFeedbackImprovementTitle(String value) {
    return switch (value) {
      '先说补救动作' => sceneFeedbackImproveActionTitle,
      '给出具体时间点' => sceneFeedbackImproveTimeTitle,
      '减少解释腔' => sceneFeedbackImproveToneTitle,
      _ => value,
    };
  }

  String sceneFeedbackImprovementDetail(String value) {
    return switch (value) {
      '先解释原因容易让对方觉得在推卸责任，把行动方案放在句子开头压力会明显下降。' =>
        sceneFeedbackImproveActionDetail,
      '模糊的"稍后""很快"远不如"今晚 6 点前"有说服力，时间承诺让对方更有安全感。' =>
        sceneFeedbackImproveTimeDetail,
      '连续使用 because 会显得在辩解，拆成两句先担责再给方案会更自然。' => sceneFeedbackImproveToneDetail,
      _ => value,
    };
  }

  String sceneFeedbackSuggestionTitle(String value) {
    return switch (value) {
      '再练一次同场景' => feedbackSuggestionRetryTitle,
      '提高追问强度' => feedbackSuggestionPressureTitle,
      '调整场景设定' => feedbackSuggestionAdjustTitle,
      _ => value,
    };
  }

  String sceneFeedbackSuggestionBody(String value) {
    return switch (value) {
      '保留当前难度，再打一轮把节奏练顺。' => feedbackSuggestionRetryBody,
      '让对方更强势，专门训练高压追问。' => feedbackSuggestionPressureBody,
      '保留目标，但改成客户电话或周会汇报。' => feedbackSuggestionAdjustBody,
      _ => value,
    };
  }
}
