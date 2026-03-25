// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SpeakEasy';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get nextStep => 'Next';

  @override
  String get previousStep => 'Previous';

  @override
  String get continueAction => 'Continue';

  @override
  String get startLearning => 'Start learning';

  @override
  String get completeLesson => 'Complete lesson';

  @override
  String get home => 'Home';

  @override
  String get learning => 'Learn';

  @override
  String get scene => 'Scene';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get membership => 'Membership';

  @override
  String get pro => 'Pro';

  @override
  String get freeVersion => 'Free';

  @override
  String get search => 'Search';

  @override
  String get searchExpressionsScenes => 'Search expressions / scenes';

  @override
  String get searchByKeyword => 'Search by keyword';

  @override
  String get noResultsFound => 'No matching content found';

  @override
  String foundResults(int count) {
    return '$count results found';
  }

  @override
  String get noCards => 'No cards yet';

  @override
  String get noSavedCards => 'No saved cards yet';

  @override
  String get noDismissedCards => 'No dismissed cards';

  @override
  String get noCompletedCards => 'No completed cards yet';

  @override
  String noDifficultyCards(Object difficulty) {
    return 'No $difficulty cards yet';
  }

  @override
  String get chooseAvatar => 'Choose avatar';

  @override
  String get chooseAvatarSubtitle => 'Tap to update the avatar on Home and Profile instantly';

  @override
  String learnersCount(Object count) {
    return '$count learners';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get unknownTime => 'Unknown time';

  @override
  String todayTime(Object time) {
    return 'Today $time';
  }

  @override
  String yesterdayTime(Object time) {
    return 'Yesterday $time';
  }

  @override
  String monthDayTime(int month, int day, Object time) {
    return '$month/$day $time';
  }

  @override
  String get learningStatsTitle => 'Learning stats';

  @override
  String get learningStatsLoading => 'Loading learning stats';

  @override
  String get noLearningStats => 'No learning stats yet';

  @override
  String get learningStatsUnavailable => 'Learning stats unavailable';

  @override
  String get syncingLearningData => 'Syncing your learning data from the server';

  @override
  String get learningStatsAfterPracticeHint => 'After you finish a practice session, this area will show your learning days, accuracy, and streak.';

  @override
  String get waitingSync => 'Waiting for sync';

  @override
  String accuracyRateValue(int accuracy) {
    return 'Accuracy $accuracy%';
  }

  @override
  String bestScoreValue(int score) {
    return 'Best $score';
  }

  @override
  String get startPractice => 'Start practice';

  @override
  String totalHoursAccumulated(Object hours) {
    return '${hours}h total';
  }

  @override
  String get daysStreakSuffix => 'day streak';

  @override
  String get practiceCountSuffix => 'practices';

  @override
  String get dayUnit => 'days';

  @override
  String get greetingMorning => 'Good morning, keep learning today';

  @override
  String get greetingAfternoon => 'Good afternoon, keep learning today';

  @override
  String get greetingEvening => 'Good evening, keep learning today';

  @override
  String get pleaseAgreeTerms => 'Please agree to the Terms of Service and Privacy Policy first';

  @override
  String get enterValidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get enterVerificationCode => 'Please enter the verification code';

  @override
  String get setNicknameFirst => 'Please set a nickname first';

  @override
  String get enterValidEmailAddress => 'Please enter a valid email address';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get verificationCodeSendFailed => 'Failed to send verification code';

  @override
  String get tagline => 'Make spoken English practice feel natural';

  @override
  String get wechatLogin => 'Continue with WeChat';

  @override
  String get wechatLoggingIn => 'Signing in with WeChat...';

  @override
  String get orText => 'or';

  @override
  String get phoneLogin => 'Phone login';

  @override
  String get phoneLoginSubtitle => 'Fast login with a verification code';

  @override
  String get emailLogin => 'Email login';

  @override
  String get emailLoginSubtitle => 'Login or register with email';

  @override
  String get agreementPrefix => 'By signing in, you agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get andText => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get phoneLoginContinue => 'Enter your phone number and verification code to continue';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get verificationCode => 'Verification code';

  @override
  String get sending => 'Sending...';

  @override
  String get resend => 'Resend';

  @override
  String get sendVerificationCode => 'Send code';

  @override
  String get loggingIn => 'Signing in...';

  @override
  String get login => 'Log in';

  @override
  String get emailRegister => 'Email sign up';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get registerWithEmailSubtitle => 'Sign up for SpeakEasy with email and password';

  @override
  String get loginWithEmailSubtitle => 'Enter your email and password to continue';

  @override
  String get setNickname => 'Set nickname';

  @override
  String get inputEmailAddress => 'Enter email address';

  @override
  String get setPassword => 'Set password';

  @override
  String get inputPassword => 'Enter password';

  @override
  String get creating => 'Creating...';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccountGoLogin => 'Already have an account? Log in';

  @override
  String get noAccountRegisterFirst => 'No account yet? Sign up first';

  @override
  String stepProgress(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get goalStepTitle => 'What do you want to fix most?';

  @override
  String get goalStepSubtitle => 'Choose multiple options and we will tailor your learning path';

  @override
  String get levelStepTitle => 'What is your current English level?';

  @override
  String get levelStepSubtitle => 'An honest answer helps us match the right content';

  @override
  String get dailyGoalStepTitle => 'How long do you want to study each day?';

  @override
  String get dailyGoalStepSubtitle => 'Consistency matters. Pick a goal you can keep';

  @override
  String get goalDescNoOpening => 'The first sentence never comes out';

  @override
  String get goalDescCannotExpress => 'You have ideas but cannot say them clearly';

  @override
  String get goalDescCannotContinue => 'You start speaking, then freeze quickly';

  @override
  String get goalDescPanic => 'You forget everything when you get nervous';

  @override
  String get goalDescSpeakBetter => 'You want to sound more natural and polished';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelBeginnerDesc => 'You know basic words but struggle to speak out';

  @override
  String get levelElementary => 'Elementary';

  @override
  String get levelElementaryDesc => 'You can say simple sentences but lack fluency';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelIntermediateDesc => 'You can handle daily conversation but sound unnatural';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get levelAdvancedDesc => 'You are fluent and want more natural expression';

  @override
  String get dailyGoal5Minutes => '5 min';

  @override
  String get dailyGoal5Desc => 'Light practice';

  @override
  String get dailyGoal15Minutes => '15 min';

  @override
  String get dailyGoal15Desc => 'Steady progress';

  @override
  String get dailyGoal30Minutes => '30 min';

  @override
  String get dailyGoal30Desc => 'Break through faster';

  @override
  String get mostPopular => 'Most popular';

  @override
  String get courseIntroduction => 'Course intro';

  @override
  String get sceneUnderstanding => 'Scene understanding';

  @override
  String get lessonTakeaways => 'What you will take away';

  @override
  String get takeawayFramework => '1 opening framework you can use right away';

  @override
  String get takeawayVariations => '2 natural variations that do not feel stiff';

  @override
  String get takeawaySceneOutput => '1 full scene output practice';

  @override
  String get lessonSummaryNoOpening => 'You roughly know what to say, but the first sentence gets stuck. This lesson helps you feel what makes an opening more natural and safe.';

  @override
  String get lessonSummaryCannotExpress => 'You have ideas in your head, but they do not come out clearly. This lesson gives you a smoother expression path.';

  @override
  String get lessonSummaryCannotContinue => 'You can start, but after one or two sentences you run out of steam. This lesson helps you build a structure to keep going.';

  @override
  String get lessonSummaryPanic => 'It is not that you cannot speak. You lose the order when you get nervous. This lesson helps you build a stable expression framework first.';

  @override
  String get lessonSummaryDefault => 'This lesson gives you a scene expression you can use immediately, then walks you through a full practice round.';

  @override
  String get learningStepUnderstandScene => 'Understand the scene first';

  @override
  String get learningStepLearn3Phrases => 'Learn these 3 phrases first';

  @override
  String get learningStepRepeatAfterMe => 'Repeat after me';

  @override
  String get learningStepVariationOutput => 'Try a variation and say your own version';

  @override
  String get learningBodyUnderstandScene => 'First understand why this type of scene feels hard, then build intuition for a natural opening.';

  @override
  String get learningBodyLearn3Phrases => 'Take away 3 easy-to-use phrases first and learn which tone each one fits.';

  @override
  String get learningBodyRepeatAfterMe => 'Repeat first to stabilize tone and rhythm, then improve naturalness gradually.';

  @override
  String get learningBodyVariationOutput => 'Swap out words in the structure, then finish with your own expression.';

  @override
  String get realScenario => 'Real scenario';

  @override
  String get understandSceneBeforePractice => 'Understand the scene clearly before expression and shadowing. The rest will feel smoother.';

  @override
  String get phraseNoteMeetingOpening => 'Good for opening a meeting';

  @override
  String get phraseNoteNaturalPacing => 'Most natural for moving the pace forward';

  @override
  String get phraseNoteClearPurpose => 'Clearer for stating the purpose';

  @override
  String get practiceRecord => 'Practice record';

  @override
  String get weekdayMon => 'M';

  @override
  String get weekdayTue => 'T';

  @override
  String get weekdayWed => 'W';

  @override
  String get weekdayThu => 'T';

  @override
  String get weekdayFri => 'F';

  @override
  String get weekdaySat => 'S';

  @override
  String get weekdaySun => 'S';

  @override
  String get learningDays => 'Learning days';

  @override
  String get totalPracticeCount => 'Total practices';

  @override
  String get accuracyRate => 'Accuracy';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get speakEasyProMember => 'SpeakEasy Pro member';

  @override
  String get freeUser => 'Free user';

  @override
  String get proActivated => 'Pro active';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get totalPracticeShort => 'Practice';

  @override
  String get consecutiveDays => 'Streak';

  @override
  String get bestScore => 'Best score';

  @override
  String get overview => 'Overview';

  @override
  String get learningOverview => 'Learning overview';

  @override
  String get skillDistribution => 'Skill breakdown';

  @override
  String get skillDistributionLoading => 'Loading skill breakdown';

  @override
  String get noSkillDistribution => 'No skill breakdown yet';

  @override
  String get skillDistributionHint => 'When the backend returns segmented skill data, progress for each dimension will appear here.';

  @override
  String get recentPractice => 'Recent practice';

  @override
  String get recentPracticeLoading => 'Loading recent practice';

  @override
  String get noPracticeRecords => 'No practice records yet';

  @override
  String get recentPracticeHint => 'Your recent records will appear here after you start practicing.';

  @override
  String get accountAndMembership => 'Account & membership';

  @override
  String get proMember => 'Pro member';

  @override
  String get viewMembershipBenefits => 'View benefits and manage membership';

  @override
  String get unlockAllFeatures => 'Unlock all features';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get subscriptionManagement => 'Subscription management';

  @override
  String get manageSubscriptionBilling => 'Manage auto-renewal and billing';

  @override
  String get viewSubscriptionPlans => 'View subscription plans';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get editAvatarNickname => 'Change avatar and nickname';

  @override
  String get learningRelated => 'Learning';

  @override
  String get learningReport => 'Learning report';

  @override
  String get viewDetailedLearningData => 'View detailed learning data';

  @override
  String get myFavorites => 'My favorites';

  @override
  String get favoritePatternsAndScenes => 'Saved phrases and scenes';

  @override
  String get offlineContent => 'Offline content';

  @override
  String get manageOfflineScenePacks => 'Manage offline scene packs';

  @override
  String get achievements => 'Achievements';

  @override
  String get viewUnlockedAchievements => 'View unlocked learning achievements';

  @override
  String get preferences => 'Preferences';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String reminderTime(Object time) {
    return 'Reminder time  $time';
  }

  @override
  String get darkMode => 'Dark mode';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get interfaceLanguage => 'App language';

  @override
  String get simplifiedChinese => 'Simplified Chinese';

  @override
  String get privacySettings => 'Privacy settings';

  @override
  String get helpAndSupport => 'Help & support';

  @override
  String get helpFeedback => 'Help & feedback';

  @override
  String get contactUs => 'Contact us';

  @override
  String get rateUs => 'Rate us';

  @override
  String get logout => 'Log out';

  @override
  String get favoritesDescription => 'Manage the phrases, scenes, and high-frequency expressions you saved in one place.';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get noFavoritesSubtitle => 'When you find expressions worth revisiting, save them and they will appear here.';

  @override
  String get offlineContentDescription => 'Manage downloaded scene packs and cached content so you can keep learning with weak or no network.';

  @override
  String get noOfflineContent => 'No offline content yet';

  @override
  String get noOfflineContentSubtitle => 'Downloaded learning content will appear here with local resource and storage status.';

  @override
  String get learningReportDescription => 'Track learning time, practice count, accuracy, and streak trends by week.';

  @override
  String get noLearningReport => 'No learning report yet';

  @override
  String get noLearningReportSubtitle => 'After you complete learning tasks, your staged performance and key metrics will be summarized here automatically.';

  @override
  String get achievementsDescription => 'View unlocked badges, streak milestones, and stage-based learning achievements.';

  @override
  String get noAchievements => 'No achievements yet';

  @override
  String get noAchievementsSubtitle => 'As your learning progresses, unlocked rewards and milestones will appear here.';

  @override
  String get youAreProMember => 'You are already a Pro member';

  @override
  String get youAreProSubtitle => 'Thanks for your support. Enjoy all premium features.';

  @override
  String get upgradeToProSubtitle => 'Unlock all features and accelerate your speaking progress';

  @override
  String get proBenefits => 'Pro benefits';

  @override
  String get chooseMembershipPlan => 'Choose a membership plan';

  @override
  String originalPriceLabel(Object price) {
    return 'Original $price';
  }

  @override
  String get processing => 'Processing...';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get switchPlan => 'Switch plan';

  @override
  String get subscribeNow => 'Subscribe now';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get freeVsPro => 'Free vs Pro';

  @override
  String get featureUnlimitedScenePractice => 'Unlimited scene practice';

  @override
  String get featureUnlimitedScenePracticeDesc => 'Enjoy every scene with no usage limit';

  @override
  String get featureFullPhraseLibrary => 'Full phrase library';

  @override
  String get featureFullPhraseLibraryDesc => '500+ natural English patterns';

  @override
  String get featureAiDeepFeedback => 'Deep AI feedback';

  @override
  String get featureAiDeepFeedbackDesc => 'Voice analysis and pronunciation correction';

  @override
  String get featureImmersiveConversation => 'Immersive conversation';

  @override
  String get featureImmersiveConversationDesc => 'Unlimited immersive dialogue practice';

  @override
  String get featureOfflineLearningPack => 'Offline learning pack';

  @override
  String get featureOfflineLearningPackDesc => 'Download scenes for offline practice';

  @override
  String get featureExclusiveLearningReport => 'Exclusive learning report';

  @override
  String get featureExclusiveLearningReportDesc => 'Detailed capability analysis';

  @override
  String get compareDaily3ScenePractice => '3 scene practices per day';

  @override
  String get compareBasePhraseLibrary50 => 'Basic phrase library (50+)';

  @override
  String get compareLearningProgressTracking => 'Learning progress tracking';

  @override
  String get compareUnlimitedScenePractice => 'Unlimited scene practice';

  @override
  String get compareFullPhraseLibrary500 => 'Full phrase library (500+)';

  @override
  String get compareAiDeepConversationFeedback => 'Deep AI conversation feedback';

  @override
  String get compareOfflineLearningPack => 'Offline learning pack';

  @override
  String get compareExclusiveLearningReport => 'Exclusive learning report';

  @override
  String get planWeekly => 'Weekly plan';

  @override
  String get planMonthly => 'Monthly plan';

  @override
  String get planYearly => 'Yearly plan';

  @override
  String get planUnitWeek => 'week';

  @override
  String get planUnitMonth => 'month';

  @override
  String get planUnitYear => 'year';

  @override
  String get planNoteWeekly => 'Short-term trial, auto-renewing, cancel anytime';

  @override
  String get planNoteMonthly => 'Steady progress, auto-renewing, cancel anytime';

  @override
  String get planNoteYearly => 'Best value, auto-renewing, about ¥24.8/month';

  @override
  String get planBadgeStarter => 'Starter';

  @override
  String get planBadgeBestValue => 'Best value';

  @override
  String get intentNoOpening => 'Cannot start speaking';

  @override
  String get intentCannotExpress => 'Cannot express clearly';

  @override
  String get intentCannotContinue => 'Cannot keep going';

  @override
  String get intentPanic => 'Panic under pressure';

  @override
  String get intentSpeakBetter => 'Speak better';

  @override
  String get sectionRecommended => 'Recommended';

  @override
  String get sectionAll => 'All';

  @override
  String get sectionFavorites => 'Favorites';

  @override
  String get sectionNotInterested => 'Not interested';

  @override
  String get sectionCompleted => 'Completed';

  @override
  String get difficultyAll => 'All';

  @override
  String get difficultyMastery => 'Mastery';

  @override
  String get nickname => 'Nickname';

  @override
  String get enterNickname => 'Enter your nickname';

  @override
  String get learningPhraseTranslationMorning => 'Good morning, everyone. Thanks for joining.';

  @override
  String get learningPhraseTranslationStart => 'Let\'s get started.';

  @override
  String get learningPhraseTranslationPriorities => 'Today we\'re here to discuss this week\'s priorities.';

  @override
  String get yourTurn => 'Your turn';

  @override
  String get chooseSmoothestVariationHint => 'Choose the version that feels most natural, say it out loud, then use it to finish your own scene opening.';

  @override
  String get practiceFeedback => 'Practice feedback';

  @override
  String get feedbackPageSubtitle => 'Detailed review and next-step suggestions';

  @override
  String get generatingAnalysis => 'Generating analysis...';

  @override
  String get taskBreakdown => 'Task breakdown';

  @override
  String get feedbackTaskExplainDelay => 'Explain the reason for the delay';

  @override
  String get feedbackStatusDone => 'Done';

  @override
  String get feedbackTaskAvoidBlame => 'Avoid sounding defensive';

  @override
  String get feedbackStatusPartial => 'Partially done';

  @override
  String get feedbackTaskNextSteps => 'Propose the next steps';

  @override
  String get feedbackStatusWeak => 'Needs work';

  @override
  String get coachAdvice => 'Coach advice';

  @override
  String get feedbackTopFixes => 'Top 3 fixes for this round';

  @override
  String get feedbackNextRoundSuggestions => 'Suggestions for the next round';

  @override
  String get practiceAgain => 'Practice again';

  @override
  String get backToHome => 'Back to home';

  @override
  String get sceneFeedbackHeadlineComplete => 'Core task completed. The details can still be sharpened.';

  @override
  String get sceneFeedbackHeadlineGoodStart => 'You are off to a good start. More practice will make it smoother.';

  @override
  String sceneFeedbackSummary(int rounds, Object npcName) {
    return 'You completed $rounds rounds of dialogue and stayed clear overall. Under follow-up questions from $npcName, you kept a workable pace. More high-pressure practice will make you steadier.';
  }

  @override
  String get sceneFeedbackMetricClarity => 'Clarity';

  @override
  String get sceneFeedbackMetricStructure => 'Structure';

  @override
  String get sceneFeedbackMetricPressure => 'Response under pressure';

  @override
  String get sceneFeedbackCoachTip => 'Next round, bring up the recovery plan earlier and add one concrete time point. It will sound more like a real workplace response.';

  @override
  String get sceneFeedbackImproveActionTitle => 'Lead with the recovery action';

  @override
  String get sceneFeedbackImproveActionDetail => 'If you explain the reason first, the other side may feel you are shifting responsibility. Starting with the action plan reduces pressure immediately.';

  @override
  String get sceneFeedbackImproveTimeTitle => 'Give a concrete time point';

  @override
  String get sceneFeedbackImproveTimeDetail => 'Vague phrases like \"later\" or \"soon\" are far less convincing than \"before 6 PM today.\" A time commitment gives the other side more certainty.';

  @override
  String get sceneFeedbackImproveToneTitle => 'Reduce the defensive tone';

  @override
  String get sceneFeedbackImproveToneDetail => 'Using \"because\" repeatedly can sound defensive. Splitting it into two sentences, first taking ownership and then giving the plan, feels more natural.';

  @override
  String get feedbackSuggestionRetryTitle => 'Retry the same scene';

  @override
  String get feedbackSuggestionRetryBody => 'Keep the current difficulty and do one more round to smooth out your pacing.';

  @override
  String get feedbackSuggestionPressureTitle => 'Increase the follow-up pressure';

  @override
  String get feedbackSuggestionPressureBody => 'Make the other side more demanding and train specifically for high-pressure follow-up questions.';

  @override
  String get feedbackSuggestionAdjustTitle => 'Adjust the scene setup';

  @override
  String get feedbackSuggestionAdjustBody => 'Keep the same goal, but switch it to a client call or a weekly status meeting.';
}
