// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'SpeakEasy';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get loading => '加载中';

  @override
  String get save => '保存';

  @override
  String get edit => '编辑';

  @override
  String get close => '关闭';

  @override
  String get back => '返回';

  @override
  String get nextStep => '下一步';

  @override
  String get previousStep => '上一步';

  @override
  String get continueAction => '继续';

  @override
  String get startLearning => '开始学习';

  @override
  String get completeLesson => '完成本课';

  @override
  String get home => '首页';

  @override
  String get learning => '学习';

  @override
  String get scene => '场景';

  @override
  String get profile => '我的';

  @override
  String get settings => '设置';

  @override
  String get membership => '会员';

  @override
  String get pro => 'Pro';

  @override
  String get freeVersion => '免费版';

  @override
  String get search => '搜索';

  @override
  String get searchExpressionsScenes => '搜索表达 / 场景';

  @override
  String get searchByKeyword => '输入关键词搜索';

  @override
  String get noResultsFound => '未找到相关内容';

  @override
  String foundResults(int count) {
    return '找到 $count 个结果';
  }

  @override
  String get noCards => '暂无卡片';

  @override
  String get noSavedCards => '还没有收藏的卡片';

  @override
  String get noDismissedCards => '没有标记不感兴趣的卡片';

  @override
  String get noCompletedCards => '还没有完成的卡片';

  @override
  String noDifficultyCards(Object difficulty) {
    return '暂无「$difficulty」难度卡片';
  }

  @override
  String get chooseAvatar => '选择头像';

  @override
  String get chooseAvatarSubtitle => '点击即可立即替换首页和个人页头像';

  @override
  String learnersCount(Object count) {
    return '$count 人学习';
  }

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get unknownTime => '时间未知';

  @override
  String todayTime(Object time) {
    return '今天 $time';
  }

  @override
  String yesterdayTime(Object time) {
    return '昨天 $time';
  }

  @override
  String monthDayTime(int month, int day, Object time) {
    return '$month月$day日 $time';
  }

  @override
  String get learningStatsTitle => '学习统计';

  @override
  String get learningStatsLoading => '学习统计加载中';

  @override
  String get noLearningStats => '暂无学习统计';

  @override
  String get learningStatsUnavailable => '学习统计暂不可用';

  @override
  String get syncingLearningData => '正在从服务器同步你的学习数据';

  @override
  String get learningStatsAfterPracticeHint => '完成一次练习后，这里会展示学习天数、正确率和连续打卡。';

  @override
  String get waitingSync => '等待同步';

  @override
  String accuracyRateValue(int accuracy) {
    return '正确率 $accuracy%';
  }

  @override
  String bestScoreValue(int score) {
    return '最佳 $score';
  }

  @override
  String get startPractice => '开始练习';

  @override
  String totalHoursAccumulated(Object hours) {
    return '${hours}h 累计';
  }

  @override
  String get daysStreakSuffix => '天连续';

  @override
  String get practiceCountSuffix => '次练习';

  @override
  String get dayUnit => '天';

  @override
  String get greetingMorning => '早上好，今天继续学习吧';

  @override
  String get greetingAfternoon => '中午好，今天继续学习吧';

  @override
  String get greetingEvening => '晚上好，今天继续学习吧';

  @override
  String get pleaseAgreeTerms => '请先同意用户协议和隐私政策';

  @override
  String get enterValidPhoneNumber => '请输入正确的手机号';

  @override
  String get enterVerificationCode => '请输入验证码';

  @override
  String get setNicknameFirst => '请先设置昵称';

  @override
  String get enterValidEmailAddress => '请输入正确的邮箱地址';

  @override
  String get passwordMinLength => '密码至少 6 位';

  @override
  String get verificationCodeSendFailed => '验证码发送失败';

  @override
  String get tagline => '让英语口语练习变得自然';

  @override
  String get wechatLogin => '微信登录';

  @override
  String get wechatLoggingIn => '微信登录中...';

  @override
  String get orText => '或';

  @override
  String get phoneLogin => '手机号登录';

  @override
  String get phoneLoginSubtitle => '验证码快速登录';

  @override
  String get emailLogin => '邮箱登录';

  @override
  String get emailLoginSubtitle => '支持登录与注册';

  @override
  String get agreementPrefix => '登录即表示你同意';

  @override
  String get termsOfService => '用户协议';

  @override
  String get andText => '和';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get phoneLoginContinue => '输入手机号和验证码继续';

  @override
  String get enterPhoneNumber => '输入手机号';

  @override
  String get verificationCode => '验证码';

  @override
  String get sending => '发送中...';

  @override
  String get resend => '重新发送';

  @override
  String get sendVerificationCode => '发送验证码';

  @override
  String get loggingIn => '登录中...';

  @override
  String get login => '登录';

  @override
  String get emailRegister => '邮箱注册';

  @override
  String get createYourAccount => '创建你的账号';

  @override
  String get registerWithEmailSubtitle => '用邮箱和密码注册 SpeakEasy';

  @override
  String get loginWithEmailSubtitle => '输入邮箱和密码继续';

  @override
  String get setNickname => '设置昵称';

  @override
  String get inputEmailAddress => '输入邮箱地址';

  @override
  String get setPassword => '设置密码';

  @override
  String get inputPassword => '输入密码';

  @override
  String get creating => '创建中...';

  @override
  String get createAccount => '创建账号';

  @override
  String get haveAccountGoLogin => '已有账号，去登录';

  @override
  String get noAccountRegisterFirst => '没有账号？先注册';

  @override
  String stepProgress(int current, int total) {
    return '步骤 $current/$total';
  }

  @override
  String get goalStepTitle => '你最想解决哪个问题？';

  @override
  String get goalStepSubtitle => '可以多选，我们会为你定制学习路径';

  @override
  String get levelStepTitle => '你目前的英语水平？';

  @override
  String get levelStepSubtitle => '诚实评估，帮助我们匹配合适内容';

  @override
  String get dailyGoalStepTitle => '每天打算学多久？';

  @override
  String get dailyGoalStepSubtitle => '坚持才是关键，选个能坚持的目标';

  @override
  String get goalDescNoOpening => '第一句话总是说不出口';

  @override
  String get goalDescCannotExpress => '脑子里有想法但说不出来';

  @override
  String get goalDescCannotContinue => '开口了但很快就卡住';

  @override
  String get goalDescPanic => '一紧张就什么都忘了';

  @override
  String get goalDescSpeakBetter => '想让表达更地道自然';

  @override
  String get levelBeginner => '入门';

  @override
  String get levelBeginnerDesc => '日常单词认识，但很难开口说';

  @override
  String get levelElementary => '初级';

  @override
  String get levelElementaryDesc => '能说简单句子，但不够流利';

  @override
  String get levelIntermediate => '中级';

  @override
  String get levelIntermediateDesc => '可以日常交流，但表达不自然';

  @override
  String get levelAdvanced => '高级';

  @override
  String get levelAdvancedDesc => '表达流利，想进一步提升地道度';

  @override
  String get dailyGoal5Minutes => '5 分钟';

  @override
  String get dailyGoal5Desc => '随手练练';

  @override
  String get dailyGoal15Minutes => '15 分钟';

  @override
  String get dailyGoal15Desc => '稳步提升';

  @override
  String get dailyGoal30Minutes => '30 分钟';

  @override
  String get dailyGoal30Desc => '快速突破';

  @override
  String get mostPopular => '最受欢迎';

  @override
  String get courseIntroduction => '课程介绍';

  @override
  String get sceneUnderstanding => '场景理解';

  @override
  String get lessonTakeaways => '这节课你会拿走';

  @override
  String get takeawayFramework => '1 个可直接套用的开口框架';

  @override
  String get takeawayVariations => '2 个自然不僵硬的变体表达';

  @override
  String get takeawaySceneOutput => '1 次完整的场景开口输出';

  @override
  String get lessonSummaryNoOpening =>
      '你知道大概要说什么，但第一句总是卡住。这节课先帮你理解什么样的开场更自然、更安全。';

  @override
  String get lessonSummaryCannotExpress =>
      '你脑子里有想法，但说出来时不够清楚。这节课会先给你一个更顺的表达路径。';

  @override
  String get lessonSummaryCannotContinue =>
      '你能开头，但一两句之后就接不下去。这里会先帮你建立继续往下说的结构感。';

  @override
  String get lessonSummaryPanic => '你不是不会，而是一紧张就丢掉顺序。这节课会先帮你把稳定表达的骨架搭起来。';

  @override
  String get lessonSummaryDefault => '这节课会先给你一个能马上用起来的场景表达方式，再带你完成一次完整练习。';

  @override
  String get learningStepUnderstandScene => '先理解场景';

  @override
  String get learningStepLearn3Phrases => '先学这 3 句';

  @override
  String get learningStepRepeatAfterMe => '跟我一起说';

  @override
  String get learningStepVariationOutput => '换一种说法并自己输出';

  @override
  String get learningBodyUnderstandScene => '先理解为什么这类场景容易卡住，再建立“自然开场”的直觉。';

  @override
  String get learningBodyLearn3Phrases => '先拿走 3 句最顺手的表达，知道它们分别适合什么语气。';

  @override
  String get learningBodyRepeatAfterMe => '先跟着说，稳住语调和节奏，再慢慢提高自然度。';

  @override
  String get learningBodyVariationOutput => '把固定结构换词，最后完成一次你自己的表达。';

  @override
  String get realScenario => '真实场景';

  @override
  String get understandSceneBeforePractice => '先把场景理解清楚，再进入表达和跟读，后面会更顺。';

  @override
  String get phraseNoteMeetingOpening => '适合会议开场';

  @override
  String get phraseNoteNaturalPacing => '推进节奏最自然';

  @override
  String get phraseNoteClearPurpose => '说明目的更清楚';

  @override
  String get practiceRecord => '练习记录';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get weekdaySun => '日';

  @override
  String get learningDays => '学习天数';

  @override
  String get totalPracticeCount => '总练习数';

  @override
  String get accuracyRate => '正确率';

  @override
  String get currentStreak => '连续打卡';

  @override
  String get speakEasyProMember => 'SpeakEasy Pro 会员';

  @override
  String get freeUser => '免费版用户';

  @override
  String get proActivated => '已开通 Pro';

  @override
  String get upgradeToPro => '升级到 Pro';

  @override
  String get totalPracticeShort => '总练习';

  @override
  String get consecutiveDays => '连续天数';

  @override
  String get bestScore => '最佳分数';

  @override
  String get overview => '概览';

  @override
  String get learningOverview => '学习概览';

  @override
  String get skillDistribution => '能力分布';

  @override
  String get skillDistributionLoading => '能力分布加载中';

  @override
  String get noSkillDistribution => '暂无能力分布';

  @override
  String get skillDistributionHint => '后端返回能力拆分后，这里会显示各项维度进展。';

  @override
  String get recentPractice => '最近练习';

  @override
  String get recentPracticeLoading => '最近练习加载中';

  @override
  String get noPracticeRecords => '暂无练习记录';

  @override
  String get recentPracticeHint => '开始一次练习后，最近记录会显示在这里。';

  @override
  String get accountAndMembership => '账户与会员';

  @override
  String get proMember => 'Pro 会员';

  @override
  String get viewMembershipBenefits => '查看会员权益与管理';

  @override
  String get unlockAllFeatures => '解锁全部功能';

  @override
  String get upgrade => '升级';

  @override
  String get subscriptionManagement => '订阅管理';

  @override
  String get manageSubscriptionBilling => '管理自动续费与账单';

  @override
  String get viewSubscriptionPlans => '查看订阅方案';

  @override
  String get editProfile => '编辑资料';

  @override
  String get editAvatarNickname => '修改头像、昵称';

  @override
  String get learningRelated => '学习相关';

  @override
  String get learningReport => '学习报告';

  @override
  String get viewDetailedLearningData => '查看详细学习数据';

  @override
  String get myFavorites => '我的收藏';

  @override
  String get favoritePatternsAndScenes => '收藏的句型和场景';

  @override
  String get offlineContent => '离线内容';

  @override
  String get manageOfflineScenePacks => '管理离线场景包';

  @override
  String get achievements => '成就徽章';

  @override
  String get viewUnlockedAchievements => '查看已解锁的学习成就';

  @override
  String get preferences => '偏好设置';

  @override
  String get dailyReminder => '每日提醒';

  @override
  String reminderTime(Object time) {
    return '提醒时间  $time';
  }

  @override
  String get darkMode => '深色模式';

  @override
  String get soundEffects => '音效';

  @override
  String get interfaceLanguage => '界面语言';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get privacySettings => '隐私设置';

  @override
  String get helpAndSupport => '帮助与支持';

  @override
  String get helpFeedback => '帮助与反馈';

  @override
  String get contactUs => '联系我们';

  @override
  String get rateUs => '给个好评';

  @override
  String get logout => '退出登录';

  @override
  String get favoritesDescription => '集中管理你标记过的句型、场景和高频表达内容。';

  @override
  String get noFavorites => '暂无收藏内容';

  @override
  String get noFavoritesSubtitle => '遇到想反复练习的表达时收藏它们，这里会为你统一保存。';

  @override
  String get offlineContentDescription => '管理已下载的场景包与缓存内容，弱网或离线时也能继续学习。';

  @override
  String get noOfflineContent => '暂无离线内容';

  @override
  String get noOfflineContentSubtitle => '下载可离线使用的学习内容后，这里会显示本地资源与存储状态。';

  @override
  String get learningReportDescription => '按周查看学习时长、练习次数、正确率和连续打卡趋势。';

  @override
  String get noLearningReport => '暂无学习报告';

  @override
  String get noLearningReportSubtitle => '完成学习任务后，这里会自动汇总你的阶段表现与关键数据。';

  @override
  String get achievementsDescription => '查看已解锁徽章、连续打卡里程碑和阶段性学习成就。';

  @override
  String get noAchievements => '暂无成就徽章';

  @override
  String get noAchievementsSubtitle => '随着学习进度推进，你解锁的奖励和里程碑会展示在这里。';

  @override
  String get youAreProMember => '你已是 Pro 会员';

  @override
  String get youAreProSubtitle => '感谢你的支持，享受所有高级功能';

  @override
  String get upgradeToProSubtitle => '解锁全部功能，加速你的口语进步';

  @override
  String get proBenefits => 'Pro 会员权益';

  @override
  String get chooseMembershipPlan => '选择会员方案';

  @override
  String originalPriceLabel(Object price) {
    return '原价 $price';
  }

  @override
  String get processing => '处理中...';

  @override
  String get currentPlan => '当前方案';

  @override
  String get switchPlan => '切换方案';

  @override
  String get subscribeNow => '立即开通';

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get freeVsPro => '免费版 vs Pro';

  @override
  String get featureUnlimitedScenePractice => '无限场景练习';

  @override
  String get featureUnlimitedScenePracticeDesc => '不限次数畅享所有场景';

  @override
  String get featureFullPhraseLibrary => '完整句型库';

  @override
  String get featureFullPhraseLibraryDesc => '500+ 地道英语句型';

  @override
  String get featureAiDeepFeedback => 'AI 深度反馈';

  @override
  String get featureAiDeepFeedbackDesc => '语音分析和发音纠正';

  @override
  String get featureImmersiveConversation => '沉浸式对话';

  @override
  String get featureImmersiveConversationDesc => '无限次沉浸对话练习';

  @override
  String get featureOfflineLearningPack => '离线学习包';

  @override
  String get featureOfflineLearningPackDesc => '下载场景离线练习';

  @override
  String get featureExclusiveLearningReport => '专属学习报告';

  @override
  String get featureExclusiveLearningReportDesc => '详细能力分析报告';

  @override
  String get compareDaily3ScenePractice => '每日 3 次场景练习';

  @override
  String get compareBasePhraseLibrary50 => '基础句型库（50+）';

  @override
  String get compareLearningProgressTracking => '学习进度追踪';

  @override
  String get compareUnlimitedScenePractice => '无限场景练习';

  @override
  String get compareFullPhraseLibrary500 => '完整句型库（500+）';

  @override
  String get compareAiDeepConversationFeedback => 'AI 深度对话反馈';

  @override
  String get compareOfflineLearningPack => '离线学习包';

  @override
  String get compareExclusiveLearningReport => '专属学习报告';

  @override
  String get planWeekly => '周度会员';

  @override
  String get planMonthly => '月度会员';

  @override
  String get planYearly => '年度会员';

  @override
  String get planUnitWeek => '周';

  @override
  String get planUnitMonth => '月';

  @override
  String get planUnitYear => '年';

  @override
  String get planNoteWeekly => '短期体验，自动续费，可随时取消';

  @override
  String get planNoteMonthly => '稳定进阶，自动续费，可随时取消';

  @override
  String get planNoteYearly => '最推荐，自动续费，相当于 ¥24.8/月';

  @override
  String get planBadgeStarter => '入门';

  @override
  String get planBadgeBestValue => '省更多';

  @override
  String get intentNoOpening => '不会开口';

  @override
  String get intentCannotExpress => '不会表达';

  @override
  String get intentCannotContinue => '说不下去';

  @override
  String get intentPanic => '一慌就乱';

  @override
  String get intentSpeakBetter => '说得更好';

  @override
  String get sectionRecommended => '推荐';

  @override
  String get sectionAll => '全部';

  @override
  String get sectionFavorites => '收藏';

  @override
  String get sectionNotInterested => '不感兴趣';

  @override
  String get sectionCompleted => '完成';

  @override
  String get difficultyAll => '全部';

  @override
  String get difficultyMastery => '精通';

  @override
  String get nickname => '昵称';

  @override
  String get enterNickname => '输入你的昵称';

  @override
  String get learningPhraseTranslationMorning => '大家早上好，感谢加入。';

  @override
  String get learningPhraseTranslationStart => '我们开始吧。';

  @override
  String get learningPhraseTranslationPriorities => '今天我们来聊一下本周的优先事项。';

  @override
  String get yourTurn => '现在轮到你了';

  @override
  String get chooseSmoothestVariationHint => '选一个最顺口的版本，大声说一遍，然后用它完成你自己的场景开口。';

  @override
  String get practiceFeedback => '练后反馈';

  @override
  String get feedbackPageSubtitle => '本轮表现拆解与下一步建议';

  @override
  String get generatingAnalysis => '正在生成分析...';

  @override
  String get taskBreakdown => '任务拆解';

  @override
  String get feedbackTaskExplainDelay => '解释延期原因';

  @override
  String get feedbackStatusDone => '完成';

  @override
  String get feedbackTaskAvoidBlame => '避免显得推责';

  @override
  String get feedbackStatusPartial => '部分完成';

  @override
  String get feedbackTaskNextSteps => '提出后续方案';

  @override
  String get feedbackStatusWeak => '较弱';

  @override
  String get coachAdvice => '教练建议';

  @override
  String get feedbackTopFixes => '这轮最该改的 3 个点';

  @override
  String get feedbackNextRoundSuggestions => '下一轮建议';

  @override
  String get practiceAgain => '再练一次';

  @override
  String get backToHome => '回到首页';

  @override
  String get sceneFeedbackHeadlineComplete => '核心任务完成，细节还可以打磨';

  @override
  String get sceneFeedbackHeadlineGoodStart => '已经开了个好头，继续练习会更流畅';

  @override
  String sceneFeedbackSummary(int rounds, Object npcName) {
    return '你完成了 $rounds 轮对话，整体表达清楚。在 $npcName 的追问下保持了基本节奏，继续多练高压场景会更稳。';
  }

  @override
  String get sceneFeedbackMetricClarity => '清晰度';

  @override
  String get sceneFeedbackMetricStructure => '结构感';

  @override
  String get sceneFeedbackMetricPressure => '临场应对';

  @override
  String get sceneFeedbackCoachTip => '下一轮把恢复方案提前说出来，再补一句具体时间点，表达会更像真实职场风格。';

  @override
  String get sceneFeedbackImproveActionTitle => '先说补救动作';

  @override
  String get sceneFeedbackImproveActionDetail =>
      '先解释原因容易让对方觉得在推卸责任，把行动方案放在句子开头压力会明显下降。';

  @override
  String get sceneFeedbackImproveTimeTitle => '给出具体时间点';

  @override
  String get sceneFeedbackImproveTimeDetail =>
      '模糊的\"稍后\"\"很快\"远不如\"今晚 6 点前\"有说服力，时间承诺让对方更有安全感。';

  @override
  String get sceneFeedbackImproveToneTitle => '减少解释腔';

  @override
  String get sceneFeedbackImproveToneDetail =>
      '连续使用 because 会显得在辩解，拆成两句先担责再给方案会更自然。';

  @override
  String get feedbackSuggestionRetryTitle => '再练一次同场景';

  @override
  String get feedbackSuggestionRetryBody => '保留当前难度，再打一轮把节奏练顺。';

  @override
  String get feedbackSuggestionPressureTitle => '提高追问强度';

  @override
  String get feedbackSuggestionPressureBody => '让对方更强势，专门训练高压追问。';

  @override
  String get feedbackSuggestionAdjustTitle => '调整场景设定';

  @override
  String get feedbackSuggestionAdjustBody => '保留目标，但改成客户电话或周会汇报。';
}
