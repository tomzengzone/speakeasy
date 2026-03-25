import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SpeakEasy'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextStep;

  /// No description provided for @previousStep.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousStep;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @startLearning.
  ///
  /// In en, this message translates to:
  /// **'Start learning'**
  String get startLearning;

  /// No description provided for @completeLesson.
  ///
  /// In en, this message translates to:
  /// **'Complete lesson'**
  String get completeLesson;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @learning.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learning;

  /// No description provided for @scene.
  ///
  /// In en, this message translates to:
  /// **'Scene'**
  String get scene;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @membership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get membership;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @freeVersion.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeVersion;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchExpressionsScenes.
  ///
  /// In en, this message translates to:
  /// **'Search expressions / scenes'**
  String get searchExpressionsScenes;

  /// No description provided for @searchByKeyword.
  ///
  /// In en, this message translates to:
  /// **'Search by keyword'**
  String get searchByKeyword;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching content found'**
  String get noResultsFound;

  /// No description provided for @foundResults.
  ///
  /// In en, this message translates to:
  /// **'{count} results found'**
  String foundResults(int count);

  /// No description provided for @noCards.
  ///
  /// In en, this message translates to:
  /// **'No cards yet'**
  String get noCards;

  /// No description provided for @noSavedCards.
  ///
  /// In en, this message translates to:
  /// **'No saved cards yet'**
  String get noSavedCards;

  /// No description provided for @noDismissedCards.
  ///
  /// In en, this message translates to:
  /// **'No dismissed cards'**
  String get noDismissedCards;

  /// No description provided for @noCompletedCards.
  ///
  /// In en, this message translates to:
  /// **'No completed cards yet'**
  String get noCompletedCards;

  /// No description provided for @noDifficultyCards.
  ///
  /// In en, this message translates to:
  /// **'No {difficulty} cards yet'**
  String noDifficultyCards(Object difficulty);

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose avatar'**
  String get chooseAvatar;

  /// No description provided for @chooseAvatarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to update the avatar on Home and Profile instantly'**
  String get chooseAvatarSubtitle;

  /// No description provided for @learnersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} learners'**
  String learnersCount(Object count);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @unknownTime.
  ///
  /// In en, this message translates to:
  /// **'Unknown time'**
  String get unknownTime;

  /// No description provided for @todayTime.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayTime(Object time);

  /// No description provided for @yesterdayTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String yesterdayTime(Object time);

  /// No description provided for @monthDayTime.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day} {time}'**
  String monthDayTime(int month, int day, Object time);

  /// No description provided for @learningStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning stats'**
  String get learningStatsTitle;

  /// No description provided for @learningStatsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading learning stats'**
  String get learningStatsLoading;

  /// No description provided for @noLearningStats.
  ///
  /// In en, this message translates to:
  /// **'No learning stats yet'**
  String get noLearningStats;

  /// No description provided for @learningStatsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Learning stats unavailable'**
  String get learningStatsUnavailable;

  /// No description provided for @syncingLearningData.
  ///
  /// In en, this message translates to:
  /// **'Syncing your learning data from the server'**
  String get syncingLearningData;

  /// No description provided for @learningStatsAfterPracticeHint.
  ///
  /// In en, this message translates to:
  /// **'After you finish a practice session, this area will show your learning days, accuracy, and streak.'**
  String get learningStatsAfterPracticeHint;

  /// No description provided for @waitingSync.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sync'**
  String get waitingSync;

  /// No description provided for @accuracyRateValue.
  ///
  /// In en, this message translates to:
  /// **'Accuracy {accuracy}%'**
  String accuracyRateValue(int accuracy);

  /// No description provided for @bestScoreValue.
  ///
  /// In en, this message translates to:
  /// **'Best {score}'**
  String bestScoreValue(int score);

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start practice'**
  String get startPractice;

  /// No description provided for @totalHoursAccumulated.
  ///
  /// In en, this message translates to:
  /// **'{hours}h total'**
  String totalHoursAccumulated(Object hours);

  /// No description provided for @daysStreakSuffix.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get daysStreakSuffix;

  /// No description provided for @practiceCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'practices'**
  String get practiceCountSuffix;

  /// No description provided for @dayUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get dayUnit;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, keep learning today'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, keep learning today'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, keep learning today'**
  String get greetingEvening;

  /// No description provided for @pleaseAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms of Service and Privacy Policy first'**
  String get pleaseAgreeTerms;

  /// No description provided for @enterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get enterValidPhoneNumber;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get enterVerificationCode;

  /// No description provided for @setNicknameFirst.
  ///
  /// In en, this message translates to:
  /// **'Please set a nickname first'**
  String get setNicknameFirst;

  /// No description provided for @enterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enterValidEmailAddress;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @verificationCodeSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code'**
  String get verificationCodeSendFailed;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Make spoken English practice feel natural'**
  String get tagline;

  /// No description provided for @wechatLogin.
  ///
  /// In en, this message translates to:
  /// **'Continue with WeChat'**
  String get wechatLogin;

  /// No description provided for @wechatLoggingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in with WeChat...'**
  String get wechatLoggingIn;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orText;

  /// No description provided for @phoneLogin.
  ///
  /// In en, this message translates to:
  /// **'Phone login'**
  String get phoneLogin;

  /// No description provided for @phoneLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fast login with a verification code'**
  String get phoneLoginSubtitle;

  /// No description provided for @emailLogin.
  ///
  /// In en, this message translates to:
  /// **'Email login'**
  String get emailLogin;

  /// No description provided for @emailLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login or register with email'**
  String get emailLoginSubtitle;

  /// No description provided for @agreementPrefix.
  ///
  /// In en, this message translates to:
  /// **'By signing in, you agree to the '**
  String get agreementPrefix;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @andText.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andText;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @phoneLoginContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and verification code to continue'**
  String get phoneLoginContinue;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendVerificationCode;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loggingIn;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @emailRegister.
  ///
  /// In en, this message translates to:
  /// **'Email sign up'**
  String get emailRegister;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @registerWithEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up for SpeakEasy with email and password'**
  String get registerWithEmailSubtitle;

  /// No description provided for @loginWithEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to continue'**
  String get loginWithEmailSubtitle;

  /// No description provided for @setNickname.
  ///
  /// In en, this message translates to:
  /// **'Set nickname'**
  String get setNickname;

  /// No description provided for @inputEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get inputEmailAddress;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get setPassword;

  /// No description provided for @inputPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get inputPassword;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @haveAccountGoLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get haveAccountGoLogin;

  /// No description provided for @noAccountRegisterFirst.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Sign up first'**
  String get noAccountRegisterFirst;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String stepProgress(int current, int total);

  /// No description provided for @goalStepTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to fix most?'**
  String get goalStepTitle;

  /// No description provided for @goalStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose multiple options and we will tailor your learning path'**
  String get goalStepSubtitle;

  /// No description provided for @levelStepTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your current English level?'**
  String get levelStepTitle;

  /// No description provided for @levelStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An honest answer helps us match the right content'**
  String get levelStepSubtitle;

  /// No description provided for @dailyGoalStepTitle.
  ///
  /// In en, this message translates to:
  /// **'How long do you want to study each day?'**
  String get dailyGoalStepTitle;

  /// No description provided for @dailyGoalStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Consistency matters. Pick a goal you can keep'**
  String get dailyGoalStepSubtitle;

  /// No description provided for @goalDescNoOpening.
  ///
  /// In en, this message translates to:
  /// **'The first sentence never comes out'**
  String get goalDescNoOpening;

  /// No description provided for @goalDescCannotExpress.
  ///
  /// In en, this message translates to:
  /// **'You have ideas but cannot say them clearly'**
  String get goalDescCannotExpress;

  /// No description provided for @goalDescCannotContinue.
  ///
  /// In en, this message translates to:
  /// **'You start speaking, then freeze quickly'**
  String get goalDescCannotContinue;

  /// No description provided for @goalDescPanic.
  ///
  /// In en, this message translates to:
  /// **'You forget everything when you get nervous'**
  String get goalDescPanic;

  /// No description provided for @goalDescSpeakBetter.
  ///
  /// In en, this message translates to:
  /// **'You want to sound more natural and polished'**
  String get goalDescSpeakBetter;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// No description provided for @levelBeginnerDesc.
  ///
  /// In en, this message translates to:
  /// **'You know basic words but struggle to speak out'**
  String get levelBeginnerDesc;

  /// No description provided for @levelElementary.
  ///
  /// In en, this message translates to:
  /// **'Elementary'**
  String get levelElementary;

  /// No description provided for @levelElementaryDesc.
  ///
  /// In en, this message translates to:
  /// **'You can say simple sentences but lack fluency'**
  String get levelElementaryDesc;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelIntermediateDesc.
  ///
  /// In en, this message translates to:
  /// **'You can handle daily conversation but sound unnatural'**
  String get levelIntermediateDesc;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @levelAdvancedDesc.
  ///
  /// In en, this message translates to:
  /// **'You are fluent and want more natural expression'**
  String get levelAdvancedDesc;

  /// No description provided for @dailyGoal5Minutes.
  ///
  /// In en, this message translates to:
  /// **'5 min'**
  String get dailyGoal5Minutes;

  /// No description provided for @dailyGoal5Desc.
  ///
  /// In en, this message translates to:
  /// **'Light practice'**
  String get dailyGoal5Desc;

  /// No description provided for @dailyGoal15Minutes.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get dailyGoal15Minutes;

  /// No description provided for @dailyGoal15Desc.
  ///
  /// In en, this message translates to:
  /// **'Steady progress'**
  String get dailyGoal15Desc;

  /// No description provided for @dailyGoal30Minutes.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get dailyGoal30Minutes;

  /// No description provided for @dailyGoal30Desc.
  ///
  /// In en, this message translates to:
  /// **'Break through faster'**
  String get dailyGoal30Desc;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get mostPopular;

  /// No description provided for @courseIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Course intro'**
  String get courseIntroduction;

  /// No description provided for @sceneUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Scene understanding'**
  String get sceneUnderstanding;

  /// No description provided for @lessonTakeaways.
  ///
  /// In en, this message translates to:
  /// **'What you will take away'**
  String get lessonTakeaways;

  /// No description provided for @takeawayFramework.
  ///
  /// In en, this message translates to:
  /// **'1 opening framework you can use right away'**
  String get takeawayFramework;

  /// No description provided for @takeawayVariations.
  ///
  /// In en, this message translates to:
  /// **'2 natural variations that do not feel stiff'**
  String get takeawayVariations;

  /// No description provided for @takeawaySceneOutput.
  ///
  /// In en, this message translates to:
  /// **'1 full scene output practice'**
  String get takeawaySceneOutput;

  /// No description provided for @lessonSummaryNoOpening.
  ///
  /// In en, this message translates to:
  /// **'You roughly know what to say, but the first sentence gets stuck. This lesson helps you feel what makes an opening more natural and safe.'**
  String get lessonSummaryNoOpening;

  /// No description provided for @lessonSummaryCannotExpress.
  ///
  /// In en, this message translates to:
  /// **'You have ideas in your head, but they do not come out clearly. This lesson gives you a smoother expression path.'**
  String get lessonSummaryCannotExpress;

  /// No description provided for @lessonSummaryCannotContinue.
  ///
  /// In en, this message translates to:
  /// **'You can start, but after one or two sentences you run out of steam. This lesson helps you build a structure to keep going.'**
  String get lessonSummaryCannotContinue;

  /// No description provided for @lessonSummaryPanic.
  ///
  /// In en, this message translates to:
  /// **'It is not that you cannot speak. You lose the order when you get nervous. This lesson helps you build a stable expression framework first.'**
  String get lessonSummaryPanic;

  /// No description provided for @lessonSummaryDefault.
  ///
  /// In en, this message translates to:
  /// **'This lesson gives you a scene expression you can use immediately, then walks you through a full practice round.'**
  String get lessonSummaryDefault;

  /// No description provided for @learningStepUnderstandScene.
  ///
  /// In en, this message translates to:
  /// **'Understand the scene first'**
  String get learningStepUnderstandScene;

  /// No description provided for @learningStepLearn3Phrases.
  ///
  /// In en, this message translates to:
  /// **'Learn these 3 phrases first'**
  String get learningStepLearn3Phrases;

  /// No description provided for @learningStepRepeatAfterMe.
  ///
  /// In en, this message translates to:
  /// **'Repeat after me'**
  String get learningStepRepeatAfterMe;

  /// No description provided for @learningStepVariationOutput.
  ///
  /// In en, this message translates to:
  /// **'Try a variation and say your own version'**
  String get learningStepVariationOutput;

  /// No description provided for @learningBodyUnderstandScene.
  ///
  /// In en, this message translates to:
  /// **'First understand why this type of scene feels hard, then build intuition for a natural opening.'**
  String get learningBodyUnderstandScene;

  /// No description provided for @learningBodyLearn3Phrases.
  ///
  /// In en, this message translates to:
  /// **'Take away 3 easy-to-use phrases first and learn which tone each one fits.'**
  String get learningBodyLearn3Phrases;

  /// No description provided for @learningBodyRepeatAfterMe.
  ///
  /// In en, this message translates to:
  /// **'Repeat first to stabilize tone and rhythm, then improve naturalness gradually.'**
  String get learningBodyRepeatAfterMe;

  /// No description provided for @learningBodyVariationOutput.
  ///
  /// In en, this message translates to:
  /// **'Swap out words in the structure, then finish with your own expression.'**
  String get learningBodyVariationOutput;

  /// No description provided for @realScenario.
  ///
  /// In en, this message translates to:
  /// **'Real scenario'**
  String get realScenario;

  /// No description provided for @understandSceneBeforePractice.
  ///
  /// In en, this message translates to:
  /// **'Understand the scene clearly before expression and shadowing. The rest will feel smoother.'**
  String get understandSceneBeforePractice;

  /// No description provided for @phraseNoteMeetingOpening.
  ///
  /// In en, this message translates to:
  /// **'Good for opening a meeting'**
  String get phraseNoteMeetingOpening;

  /// No description provided for @phraseNoteNaturalPacing.
  ///
  /// In en, this message translates to:
  /// **'Most natural for moving the pace forward'**
  String get phraseNoteNaturalPacing;

  /// No description provided for @phraseNoteClearPurpose.
  ///
  /// In en, this message translates to:
  /// **'Clearer for stating the purpose'**
  String get phraseNoteClearPurpose;

  /// No description provided for @practiceRecord.
  ///
  /// In en, this message translates to:
  /// **'Practice record'**
  String get practiceRecord;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get weekdaySun;

  /// No description provided for @learningDays.
  ///
  /// In en, this message translates to:
  /// **'Learning days'**
  String get learningDays;

  /// No description provided for @totalPracticeCount.
  ///
  /// In en, this message translates to:
  /// **'Total practices'**
  String get totalPracticeCount;

  /// No description provided for @accuracyRate.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracyRate;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @speakEasyProMember.
  ///
  /// In en, this message translates to:
  /// **'SpeakEasy Pro member'**
  String get speakEasyProMember;

  /// No description provided for @freeUser.
  ///
  /// In en, this message translates to:
  /// **'Free user'**
  String get freeUser;

  /// No description provided for @proActivated.
  ///
  /// In en, this message translates to:
  /// **'Pro active'**
  String get proActivated;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @totalPracticeShort.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get totalPracticeShort;

  /// No description provided for @consecutiveDays.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get consecutiveDays;

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best score'**
  String get bestScore;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @learningOverview.
  ///
  /// In en, this message translates to:
  /// **'Learning overview'**
  String get learningOverview;

  /// No description provided for @skillDistribution.
  ///
  /// In en, this message translates to:
  /// **'Skill breakdown'**
  String get skillDistribution;

  /// No description provided for @skillDistributionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading skill breakdown'**
  String get skillDistributionLoading;

  /// No description provided for @noSkillDistribution.
  ///
  /// In en, this message translates to:
  /// **'No skill breakdown yet'**
  String get noSkillDistribution;

  /// No description provided for @skillDistributionHint.
  ///
  /// In en, this message translates to:
  /// **'When the backend returns segmented skill data, progress for each dimension will appear here.'**
  String get skillDistributionHint;

  /// No description provided for @recentPractice.
  ///
  /// In en, this message translates to:
  /// **'Recent practice'**
  String get recentPractice;

  /// No description provided for @recentPracticeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading recent practice'**
  String get recentPracticeLoading;

  /// No description provided for @noPracticeRecords.
  ///
  /// In en, this message translates to:
  /// **'No practice records yet'**
  String get noPracticeRecords;

  /// No description provided for @recentPracticeHint.
  ///
  /// In en, this message translates to:
  /// **'Your recent records will appear here after you start practicing.'**
  String get recentPracticeHint;

  /// No description provided for @accountAndMembership.
  ///
  /// In en, this message translates to:
  /// **'Account & membership'**
  String get accountAndMembership;

  /// No description provided for @proMember.
  ///
  /// In en, this message translates to:
  /// **'Pro member'**
  String get proMember;

  /// No description provided for @viewMembershipBenefits.
  ///
  /// In en, this message translates to:
  /// **'View benefits and manage membership'**
  String get viewMembershipBenefits;

  /// No description provided for @unlockAllFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features'**
  String get unlockAllFeatures;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @subscriptionManagement.
  ///
  /// In en, this message translates to:
  /// **'Subscription management'**
  String get subscriptionManagement;

  /// No description provided for @manageSubscriptionBilling.
  ///
  /// In en, this message translates to:
  /// **'Manage auto-renewal and billing'**
  String get manageSubscriptionBilling;

  /// No description provided for @viewSubscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'View subscription plans'**
  String get viewSubscriptionPlans;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @editAvatarNickname.
  ///
  /// In en, this message translates to:
  /// **'Change avatar and nickname'**
  String get editAvatarNickname;

  /// No description provided for @learningRelated.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningRelated;

  /// No description provided for @learningReport.
  ///
  /// In en, this message translates to:
  /// **'Learning report'**
  String get learningReport;

  /// No description provided for @viewDetailedLearningData.
  ///
  /// In en, this message translates to:
  /// **'View detailed learning data'**
  String get viewDetailedLearningData;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My favorites'**
  String get myFavorites;

  /// No description provided for @favoritePatternsAndScenes.
  ///
  /// In en, this message translates to:
  /// **'Saved phrases and scenes'**
  String get favoritePatternsAndScenes;

  /// No description provided for @offlineContent.
  ///
  /// In en, this message translates to:
  /// **'Offline content'**
  String get offlineContent;

  /// No description provided for @manageOfflineScenePacks.
  ///
  /// In en, this message translates to:
  /// **'Manage offline scene packs'**
  String get manageOfflineScenePacks;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @viewUnlockedAchievements.
  ///
  /// In en, this message translates to:
  /// **'View unlocked learning achievements'**
  String get viewUnlockedAchievements;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time  {time}'**
  String reminderTime(Object time);

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffects;

  /// No description provided for @interfaceLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get interfaceLanguage;

  /// No description provided for @simplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get simplifiedChinese;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings'**
  String get privacySettings;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpAndSupport;

  /// No description provided for @helpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get helpFeedback;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate us'**
  String get rateUs;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @favoritesDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the phrases, scenes, and high-frequency expressions you saved in one place.'**
  String get favoritesDescription;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// No description provided for @noFavoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you find expressions worth revisiting, save them and they will appear here.'**
  String get noFavoritesSubtitle;

  /// No description provided for @offlineContentDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage downloaded scene packs and cached content so you can keep learning with weak or no network.'**
  String get offlineContentDescription;

  /// No description provided for @noOfflineContent.
  ///
  /// In en, this message translates to:
  /// **'No offline content yet'**
  String get noOfflineContent;

  /// No description provided for @noOfflineContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded learning content will appear here with local resource and storage status.'**
  String get noOfflineContentSubtitle;

  /// No description provided for @learningReportDescription.
  ///
  /// In en, this message translates to:
  /// **'Track learning time, practice count, accuracy, and streak trends by week.'**
  String get learningReportDescription;

  /// No description provided for @noLearningReport.
  ///
  /// In en, this message translates to:
  /// **'No learning report yet'**
  String get noLearningReport;

  /// No description provided for @noLearningReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After you complete learning tasks, your staged performance and key metrics will be summarized here automatically.'**
  String get noLearningReportSubtitle;

  /// No description provided for @achievementsDescription.
  ///
  /// In en, this message translates to:
  /// **'View unlocked badges, streak milestones, and stage-based learning achievements.'**
  String get achievementsDescription;

  /// No description provided for @noAchievements.
  ///
  /// In en, this message translates to:
  /// **'No achievements yet'**
  String get noAchievements;

  /// No description provided for @noAchievementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'As your learning progresses, unlocked rewards and milestones will appear here.'**
  String get noAchievementsSubtitle;

  /// No description provided for @youAreProMember.
  ///
  /// In en, this message translates to:
  /// **'You are already a Pro member'**
  String get youAreProMember;

  /// No description provided for @youAreProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your support. Enjoy all premium features.'**
  String get youAreProSubtitle;

  /// No description provided for @upgradeToProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features and accelerate your speaking progress'**
  String get upgradeToProSubtitle;

  /// No description provided for @proBenefits.
  ///
  /// In en, this message translates to:
  /// **'Pro benefits'**
  String get proBenefits;

  /// No description provided for @chooseMembershipPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a membership plan'**
  String get chooseMembershipPlan;

  /// No description provided for @originalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Original {price}'**
  String originalPriceLabel(Object price);

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @switchPlan.
  ///
  /// In en, this message translates to:
  /// **'Switch plan'**
  String get switchPlan;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe now'**
  String get subscribeNow;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @freeVsPro.
  ///
  /// In en, this message translates to:
  /// **'Free vs Pro'**
  String get freeVsPro;

  /// No description provided for @featureUnlimitedScenePractice.
  ///
  /// In en, this message translates to:
  /// **'Unlimited scene practice'**
  String get featureUnlimitedScenePractice;

  /// No description provided for @featureUnlimitedScenePracticeDesc.
  ///
  /// In en, this message translates to:
  /// **'Enjoy every scene with no usage limit'**
  String get featureUnlimitedScenePracticeDesc;

  /// No description provided for @featureFullPhraseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Full phrase library'**
  String get featureFullPhraseLibrary;

  /// No description provided for @featureFullPhraseLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'500+ natural English patterns'**
  String get featureFullPhraseLibraryDesc;

  /// No description provided for @featureAiDeepFeedback.
  ///
  /// In en, this message translates to:
  /// **'Deep AI feedback'**
  String get featureAiDeepFeedback;

  /// No description provided for @featureAiDeepFeedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Voice analysis and pronunciation correction'**
  String get featureAiDeepFeedbackDesc;

  /// No description provided for @featureImmersiveConversation.
  ///
  /// In en, this message translates to:
  /// **'Immersive conversation'**
  String get featureImmersiveConversation;

  /// No description provided for @featureImmersiveConversationDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlimited immersive dialogue practice'**
  String get featureImmersiveConversationDesc;

  /// No description provided for @featureOfflineLearningPack.
  ///
  /// In en, this message translates to:
  /// **'Offline learning pack'**
  String get featureOfflineLearningPack;

  /// No description provided for @featureOfflineLearningPackDesc.
  ///
  /// In en, this message translates to:
  /// **'Download scenes for offline practice'**
  String get featureOfflineLearningPackDesc;

  /// No description provided for @featureExclusiveLearningReport.
  ///
  /// In en, this message translates to:
  /// **'Exclusive learning report'**
  String get featureExclusiveLearningReport;

  /// No description provided for @featureExclusiveLearningReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed capability analysis'**
  String get featureExclusiveLearningReportDesc;

  /// No description provided for @compareDaily3ScenePractice.
  ///
  /// In en, this message translates to:
  /// **'3 scene practices per day'**
  String get compareDaily3ScenePractice;

  /// No description provided for @compareBasePhraseLibrary50.
  ///
  /// In en, this message translates to:
  /// **'Basic phrase library (50+)'**
  String get compareBasePhraseLibrary50;

  /// No description provided for @compareLearningProgressTracking.
  ///
  /// In en, this message translates to:
  /// **'Learning progress tracking'**
  String get compareLearningProgressTracking;

  /// No description provided for @compareUnlimitedScenePractice.
  ///
  /// In en, this message translates to:
  /// **'Unlimited scene practice'**
  String get compareUnlimitedScenePractice;

  /// No description provided for @compareFullPhraseLibrary500.
  ///
  /// In en, this message translates to:
  /// **'Full phrase library (500+)'**
  String get compareFullPhraseLibrary500;

  /// No description provided for @compareAiDeepConversationFeedback.
  ///
  /// In en, this message translates to:
  /// **'Deep AI conversation feedback'**
  String get compareAiDeepConversationFeedback;

  /// No description provided for @compareOfflineLearningPack.
  ///
  /// In en, this message translates to:
  /// **'Offline learning pack'**
  String get compareOfflineLearningPack;

  /// No description provided for @compareExclusiveLearningReport.
  ///
  /// In en, this message translates to:
  /// **'Exclusive learning report'**
  String get compareExclusiveLearningReport;

  /// No description provided for @planWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly plan'**
  String get planWeekly;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly plan'**
  String get planMonthly;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly plan'**
  String get planYearly;

  /// No description provided for @planUnitWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get planUnitWeek;

  /// No description provided for @planUnitMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get planUnitMonth;

  /// No description provided for @planUnitYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get planUnitYear;

  /// No description provided for @planNoteWeekly.
  ///
  /// In en, this message translates to:
  /// **'Short-term trial, auto-renewing, cancel anytime'**
  String get planNoteWeekly;

  /// No description provided for @planNoteMonthly.
  ///
  /// In en, this message translates to:
  /// **'Steady progress, auto-renewing, cancel anytime'**
  String get planNoteMonthly;

  /// No description provided for @planNoteYearly.
  ///
  /// In en, this message translates to:
  /// **'Best value, auto-renewing, about ¥24.8/month'**
  String get planNoteYearly;

  /// No description provided for @planBadgeStarter.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get planBadgeStarter;

  /// No description provided for @planBadgeBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get planBadgeBestValue;

  /// No description provided for @intentNoOpening.
  ///
  /// In en, this message translates to:
  /// **'Cannot start speaking'**
  String get intentNoOpening;

  /// No description provided for @intentCannotExpress.
  ///
  /// In en, this message translates to:
  /// **'Cannot express clearly'**
  String get intentCannotExpress;

  /// No description provided for @intentCannotContinue.
  ///
  /// In en, this message translates to:
  /// **'Cannot keep going'**
  String get intentCannotContinue;

  /// No description provided for @intentPanic.
  ///
  /// In en, this message translates to:
  /// **'Panic under pressure'**
  String get intentPanic;

  /// No description provided for @intentSpeakBetter.
  ///
  /// In en, this message translates to:
  /// **'Speak better'**
  String get intentSpeakBetter;

  /// No description provided for @sectionRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sectionRecommended;

  /// No description provided for @sectionAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get sectionAll;

  /// No description provided for @sectionFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get sectionFavorites;

  /// No description provided for @sectionNotInterested.
  ///
  /// In en, this message translates to:
  /// **'Not interested'**
  String get sectionNotInterested;

  /// No description provided for @sectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get sectionCompleted;

  /// No description provided for @difficultyAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get difficultyAll;

  /// No description provided for @difficultyMastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get difficultyMastery;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get enterNickname;

  /// No description provided for @learningPhraseTranslationMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, everyone. Thanks for joining.'**
  String get learningPhraseTranslationMorning;

  /// No description provided for @learningPhraseTranslationStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started.'**
  String get learningPhraseTranslationStart;

  /// No description provided for @learningPhraseTranslationPriorities.
  ///
  /// In en, this message translates to:
  /// **'Today we\'re here to discuss this week\'s priorities.'**
  String get learningPhraseTranslationPriorities;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @chooseSmoothestVariationHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the version that feels most natural, say it out loud, then use it to finish your own scene opening.'**
  String get chooseSmoothestVariationHint;

  /// No description provided for @practiceFeedback.
  ///
  /// In en, this message translates to:
  /// **'Practice feedback'**
  String get practiceFeedback;

  /// No description provided for @feedbackPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed review and next-step suggestions'**
  String get feedbackPageSubtitle;

  /// No description provided for @generatingAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Generating analysis...'**
  String get generatingAnalysis;

  /// No description provided for @taskBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Task breakdown'**
  String get taskBreakdown;

  /// No description provided for @feedbackTaskExplainDelay.
  ///
  /// In en, this message translates to:
  /// **'Explain the reason for the delay'**
  String get feedbackTaskExplainDelay;

  /// No description provided for @feedbackStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get feedbackStatusDone;

  /// No description provided for @feedbackTaskAvoidBlame.
  ///
  /// In en, this message translates to:
  /// **'Avoid sounding defensive'**
  String get feedbackTaskAvoidBlame;

  /// No description provided for @feedbackStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partially done'**
  String get feedbackStatusPartial;

  /// No description provided for @feedbackTaskNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Propose the next steps'**
  String get feedbackTaskNextSteps;

  /// No description provided for @feedbackStatusWeak.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get feedbackStatusWeak;

  /// No description provided for @coachAdvice.
  ///
  /// In en, this message translates to:
  /// **'Coach advice'**
  String get coachAdvice;

  /// No description provided for @feedbackTopFixes.
  ///
  /// In en, this message translates to:
  /// **'Top 3 fixes for this round'**
  String get feedbackTopFixes;

  /// No description provided for @feedbackNextRoundSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions for the next round'**
  String get feedbackNextRoundSuggestions;

  /// No description provided for @practiceAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice again'**
  String get practiceAgain;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @sceneFeedbackHeadlineComplete.
  ///
  /// In en, this message translates to:
  /// **'Core task completed. The details can still be sharpened.'**
  String get sceneFeedbackHeadlineComplete;

  /// No description provided for @sceneFeedbackHeadlineGoodStart.
  ///
  /// In en, this message translates to:
  /// **'You are off to a good start. More practice will make it smoother.'**
  String get sceneFeedbackHeadlineGoodStart;

  /// No description provided for @sceneFeedbackSummary.
  ///
  /// In en, this message translates to:
  /// **'You completed {rounds} rounds of dialogue and stayed clear overall. Under follow-up questions from {npcName}, you kept a workable pace. More high-pressure practice will make you steadier.'**
  String sceneFeedbackSummary(int rounds, Object npcName);

  /// No description provided for @sceneFeedbackMetricClarity.
  ///
  /// In en, this message translates to:
  /// **'Clarity'**
  String get sceneFeedbackMetricClarity;

  /// No description provided for @sceneFeedbackMetricStructure.
  ///
  /// In en, this message translates to:
  /// **'Structure'**
  String get sceneFeedbackMetricStructure;

  /// No description provided for @sceneFeedbackMetricPressure.
  ///
  /// In en, this message translates to:
  /// **'Response under pressure'**
  String get sceneFeedbackMetricPressure;

  /// No description provided for @sceneFeedbackCoachTip.
  ///
  /// In en, this message translates to:
  /// **'Next round, bring up the recovery plan earlier and add one concrete time point. It will sound more like a real workplace response.'**
  String get sceneFeedbackCoachTip;

  /// No description provided for @sceneFeedbackImproveActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Lead with the recovery action'**
  String get sceneFeedbackImproveActionTitle;

  /// No description provided for @sceneFeedbackImproveActionDetail.
  ///
  /// In en, this message translates to:
  /// **'If you explain the reason first, the other side may feel you are shifting responsibility. Starting with the action plan reduces pressure immediately.'**
  String get sceneFeedbackImproveActionDetail;

  /// No description provided for @sceneFeedbackImproveTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Give a concrete time point'**
  String get sceneFeedbackImproveTimeTitle;

  /// No description provided for @sceneFeedbackImproveTimeDetail.
  ///
  /// In en, this message translates to:
  /// **'Vague phrases like \"later\" or \"soon\" are far less convincing than \"before 6 PM today.\" A time commitment gives the other side more certainty.'**
  String get sceneFeedbackImproveTimeDetail;

  /// No description provided for @sceneFeedbackImproveToneTitle.
  ///
  /// In en, this message translates to:
  /// **'Reduce the defensive tone'**
  String get sceneFeedbackImproveToneTitle;

  /// No description provided for @sceneFeedbackImproveToneDetail.
  ///
  /// In en, this message translates to:
  /// **'Using \"because\" repeatedly can sound defensive. Splitting it into two sentences, first taking ownership and then giving the plan, feels more natural.'**
  String get sceneFeedbackImproveToneDetail;

  /// No description provided for @feedbackSuggestionRetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Retry the same scene'**
  String get feedbackSuggestionRetryTitle;

  /// No description provided for @feedbackSuggestionRetryBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the current difficulty and do one more round to smooth out your pacing.'**
  String get feedbackSuggestionRetryBody;

  /// No description provided for @feedbackSuggestionPressureTitle.
  ///
  /// In en, this message translates to:
  /// **'Increase the follow-up pressure'**
  String get feedbackSuggestionPressureTitle;

  /// No description provided for @feedbackSuggestionPressureBody.
  ///
  /// In en, this message translates to:
  /// **'Make the other side more demanding and train specifically for high-pressure follow-up questions.'**
  String get feedbackSuggestionPressureBody;

  /// No description provided for @feedbackSuggestionAdjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust the scene setup'**
  String get feedbackSuggestionAdjustTitle;

  /// No description provided for @feedbackSuggestionAdjustBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the same goal, but switch it to a client call or a weekly status meeting.'**
  String get feedbackSuggestionAdjustBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
