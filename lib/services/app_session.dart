import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:speakeasy/application/contracts/app_repository.dart';
import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/application/session/session_profile_coordinator.dart';
import 'package:speakeasy/application/session/session_stats_coordinator.dart';
import 'package:speakeasy/core/constants/avatar_defaults.dart';
import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/services/ai_repository.dart';
import 'package:speakeasy/config/payment_config.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/apple_auth_service.dart';
import 'package:speakeasy/services/apple_payment_service.dart';
import 'package:speakeasy/services/android_payment_service.dart';
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/payment_service.dart';
import 'package:speakeasy/services/stats_service.dart';
import 'package:speakeasy/services/wechat_auth_service.dart';
import 'package:speakeasy/utils/error_handler.dart';

export 'package:speakeasy/application/contracts/app_repository.dart';
export 'package:speakeasy/core/constants/avatar_defaults.dart'
    show defaultAvatarUrls;
export 'package:speakeasy/domain/auth/auth_models.dart';
export 'package:speakeasy/domain/scene/scene_models.dart';

AppRepository _defaultRepository() {
  // 所有 AI 调用通过后端代理（DashScope），apiKey 参数已不再使用直连
  return OpenAiAppRepository(apiKey: '');
}

PaymentService _defaultPaymentService() {
  if (Platform.isIOS || Platform.isMacOS) {
    return ApplePaymentService();
  }
  if (Platform.isAndroid) {
    return const AndroidPaymentService();
  }
  return const UnsupportedPaymentService();
}

class AppSession extends ChangeNotifier {
  factory AppSession({
    AppRepository? repository,
    PaymentService? paymentService,
    StatsService? statsService,
    AuthService? authService,
    SessionLifecycleCoordinator? sessionCoordinator,
    SessionProfileCoordinator? profileCoordinator,
    SessionStatsCoordinator? statsCoordinator,
  }) {
    final AppRepository resolvedRepository = repository ?? _defaultRepository();
    final StatsService resolvedStatsService =
        statsService ?? const StatsService();
    final AuthService resolvedAuthService =
        authService ?? AuthService(signInWithEmail: resolvedRepository.signIn);
    return AppSession._(
      repository: resolvedRepository,
      paymentService: paymentService ?? _defaultPaymentService(),
      sessionCoordinator:
          sessionCoordinator ??
          SessionLifecycleCoordinator(authService: resolvedAuthService),
      profileCoordinator: profileCoordinator ?? SessionProfileCoordinator(),
      statsCoordinator:
          statsCoordinator ??
          SessionStatsCoordinator(statsService: resolvedStatsService),
    );
  }

  AppSession._({
    required AppRepository repository,
    required PaymentService paymentService,
    required SessionLifecycleCoordinator sessionCoordinator,
    required SessionProfileCoordinator profileCoordinator,
    required SessionStatsCoordinator statsCoordinator,
  }) : _repository = repository,
       _paymentService = paymentService,
       _sessionCoordinator = sessionCoordinator,
       _profileCoordinator = profileCoordinator,
       _statsCoordinator = statsCoordinator {
    Future.microtask(_loadFromStorage);
    Future.microtask(_loadCachedStats);
    Future.microtask(_hydrateFromBackend);
  }

  final AppRepository _repository;
  final PaymentService _paymentService;
  final SessionLifecycleCoordinator _sessionCoordinator;
  final SessionProfileCoordinator _profileCoordinator;
  final SessionStatsCoordinator _statsCoordinator;

  AppUser? _user;
  LearningStatsModel _stats = const LearningStatsModel();
  bool _onboardingDone = false;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isAuthenticating = false;
  bool _isUpdatingMembership = false;
  bool _isStatsLoading = true;
  String? _authErrorMessage;
  String? _membershipErrorMessage;
  String? _statsErrorMessage;

  bool get isLoggedIn => _user != null;
  bool get onboardingDone => _onboardingDone;
  bool get isAuthenticating => _isAuthenticating;
  bool get isUpdatingMembership => _isUpdatingMembership;
  bool get isStatsLoading => _isStatsLoading;
  String? get authErrorMessage => _authErrorMessage;
  String? get membershipErrorMessage => _membershipErrorMessage;
  String? get statsErrorMessage => _statsErrorMessage;
  LearningStatsModel get stats => _stats;
  ThemeMode get themeMode => _themeMode;

  String get nickname => _user?.nickname ?? '学习者';
  String get avatarUrl {
    final String value = _user?.avatarUrl ?? '';
    return value.isEmpty ? defaultAvatarUrls.first : value;
  }

  String get memberPlan => _user?.memberPlan ?? 'free';
  bool get isPro => memberPlan != 'free';

  Future<void> signIn(LoginSubmission submission) async {
    if (submission.provider == LoginProvider.apple) {
      await signInWithApple();
      return;
    }

    if (submission.provider == LoginProvider.wechat) {
      await signInWithWeChat();
      return;
    }

    _isAuthenticating = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final SessionSignInResult result = await _sessionCoordinator.signIn(
        submission,
      );
      final AuthenticatedSessionPayload? authenticatedSession =
          result.authenticatedSession;
      if (authenticatedSession != null) {
        await _completeAuthenticatedSession(authenticatedSession);
      } else {
        _user = result.user;
        unawaited(_persistUserState());
      }
    } catch (error) {
      _authErrorMessage = _messageFromError(error, fallback: '登录失败，请稍后重试');
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signInWithApple({AppleAuthService? service}) async {
    _isAuthenticating = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final AuthenticatedSessionPayload session = await _sessionCoordinator
          .signInWithApple(
            signIn: (service ?? const AppleAuthService()).signInWithApple,
          );
      await _completeAuthenticatedSession(session);
    } catch (error) {
      _authErrorMessage = _messageFromError(
        error,
        fallback: 'Apple 登录失败，请稍后重试',
      );
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signInWithWeChat({WeChatAuthService? service}) async {
    _isAuthenticating = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final AuthenticatedSessionPayload session = await _sessionCoordinator
          .signInWithWeChat(
            signIn: (service ?? WeChatAuthService.instance).sendWeChatAuth,
          );
      await _completeAuthenticatedSession(session);
    } catch (error) {
      _authErrorMessage = _messageFromError(error, fallback: '微信登录失败，请稍后重试');
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signInWithCode({
    required String phone,
    required String code,
  }) async {
    _isAuthenticating = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final SessionSignInResult result = await _sessionCoordinator.signIn(
        LoginSubmission(
          provider: LoginProvider.phone,
          phone: phone,
          code: code,
        ),
      );
      final AuthenticatedSessionPayload? authenticatedSession =
          result.authenticatedSession;
      if (authenticatedSession == null) {
        throw Exception('登录凭证无效');
      }
      await _completeAuthenticatedSession(authenticatedSession);
    } catch (error) {
      _authErrorMessage = _messageFromError(error, fallback: '登录失败，请稍后重试');
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signInWithTestPhone({required String phone}) async {
    _isAuthenticating = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final AuthenticatedSessionPayload session = await _sessionCoordinator
          .signInWithTestPhone(phone: phone);
      await _completeAuthenticatedSession(session);
    } catch (error) {
      _authErrorMessage = _messageFromError(error, fallback: '测试登录失败，请稍后重试');
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> changeMembership(String planId) async {
    final AppUser? currentUser = _user;
    if (currentUser == null) {
      _membershipErrorMessage = '请先登录';
      notifyListeners();
      return;
    }

    _isUpdatingMembership = true;
    _membershipErrorMessage = null;
    notifyListeners();

    try {
      final PaymentResult paymentResult = await _paymentService.purchasePlan(
        planId,
      );
      if (!paymentResult.success) {
        _membershipErrorMessage = paymentResult.displayMessage;
        return;
      }

      final String appliedPlanId = paymentResult.planId ?? planId;
      _user = await _repository.changeMembership(
        user: currentUser,
        planId: appliedPlanId,
      );
      unawaited(_persistUserState());
    } catch (error) {
      _membershipErrorMessage = _messageFromError(
        error,
        fallback: '会员状态更新失败，请稍后重试',
      );
    } finally {
      _isUpdatingMembership = false;
      notifyListeners();
    }
  }

  Future<void> restoreMembershipPurchases() async {
    final AppUser? currentUser = _user;
    if (currentUser == null) {
      _membershipErrorMessage = '请先登录';
      notifyListeners();
      return;
    }

    _isUpdatingMembership = true;
    _membershipErrorMessage = null;
    notifyListeners();

    try {
      final PaymentResult result = await _paymentService.restorePurchases();
      if (!result.success || result.planId == null) {
        _membershipErrorMessage = result.displayMessage;
        return;
      }

      _user = await _repository.changeMembership(
        user: currentUser,
        planId: result.planId!,
      );
      unawaited(_persistUserState());
    } catch (error) {
      _membershipErrorMessage = _messageFromError(
        error,
        fallback: '恢复购买失败，请稍后重试',
      );
    } finally {
      _isUpdatingMembership = false;
      notifyListeners();
    }
  }

  Future<void> refreshMembershipStatus({bool silent = true}) async {
    final AppUser? currentUser = _user;
    if (currentUser == null) {
      return;
    }

    if (!silent) {
      _isUpdatingMembership = true;
      _membershipErrorMessage = null;
      notifyListeners();
    }

    try {
      final PaymentResult result = await _paymentService
          .checkSubscriptionStatus();
      if (result.success && result.planId != null) {
        if (result.planId != currentUser.memberPlan) {
          _user = await _repository.changeMembership(
            user: currentUser,
            planId: result.planId!,
          );
          unawaited(_persistUserState());
          notifyListeners();
        }
        return;
      }

      if (result.status == PaymentStatus.inactive &&
          currentUser.memberPlan != PaymentConfig.freePlanId) {
        _user = await _repository.changeMembership(
          user: currentUser,
          planId: PaymentConfig.freePlanId,
        );
        unawaited(_persistUserState());
        notifyListeners();
      } else if (!silent) {
        _membershipErrorMessage = result.displayMessage;
      }
    } catch (error) {
      if (!silent) {
        _membershipErrorMessage = _messageFromError(
          error,
          fallback: '订阅状态检查失败，请稍后重试',
        );
      }
    } finally {
      if (!silent) {
        _isUpdatingMembership = false;
        notifyListeners();
      }
    }
  }

  Future<SceneReply> sendSceneMessage({
    required String sessionId,
    required String userText,
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  }) {
    return _repository.sendSceneMessage(
      sessionId: sessionId,
      userText: userText,
      draft: draft,
      history: history,
    );
  }

  Future<void> syncRoleProfiles(List<Map<String, dynamic>> roles) {
    return _repository.syncRoleProfiles(roles);
  }

  Future<RoleMemorySummary?> fetchRoleMemory(String roleId) {
    return _repository.fetchRoleMemory(roleId);
  }

  Future<LearningProfileSummary?> fetchLearningProfile() {
    return _repository.fetchLearningProfile();
  }

  Future<PronunciationScore> scorePronunciation({
    required String audioPath,
    required String expectedText,
  }) {
    return _repository.scorePronunciation(
      audioPath: audioPath,
      expectedText: expectedText,
    );
  }

  Future<SceneFeedback> generateSceneFeedback({
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
    List<SceneFeedbackVoiceTurn> voiceTurns = const <SceneFeedbackVoiceTurn>[],
  }) {
    return _repository.generateSceneFeedback(
      draft: draft,
      history: history,
      voiceTurns: voiceTurns,
    );
  }

  void updateAvatar(String avatarUrl) {
    final AppUser? currentUser = _user;
    if (currentUser == null || currentUser.avatarUrl == avatarUrl) {
      return;
    }
    _user = currentUser.copyWith(avatarUrl: avatarUrl);
    notifyListeners();
    unawaited(_persistUserState());
  }

  Future<void> recordPracticeSession({
    required int durationSeconds,
    required int score,
    String? title,
    String? emoji,
    List<String>? tags,
    SceneFeedback? feedback,
    String? promptText,
    SceneDraft? sceneDraft,
    String feedbackStatus = 'ready',
    Map<String, dynamic>? feedbackContext,
  }) async {
    _stats = _statsCoordinator.recordLocalSession(
      currentStats: _stats,
      durationSeconds: durationSeconds,
      score: score,
      title: title,
      emoji: emoji,
      tags: tags,
      feedback: feedback,
      promptText: promptText,
      sceneDraft: sceneDraft,
      feedbackStatus: feedbackStatus,
      feedbackContext: feedbackContext,
    );
    _statsErrorMessage = null;
    notifyListeners();
    await _statsCoordinator.cacheStats(_stats);
    unawaited(
      _syncRecordedSession(
        durationSeconds: durationSeconds,
        score: score,
        title: title,
        emoji: emoji,
        tags: tags,
        feedback: feedback,
        promptText: promptText,
        sceneDraft: sceneDraft,
        feedbackStatus: feedbackStatus,
        feedbackContext: feedbackContext,
      ),
    );
  }

  Future<void> upsertPracticeFeedback({
    required int durationSeconds,
    required int score,
    required String title,
    String? emoji,
    List<String>? tags,
    required SceneFeedback feedback,
    String? promptText,
    SceneDraft? sceneDraft,
    Map<String, dynamic>? feedbackContext,
  }) async {
    _stats = _statsCoordinator.upsertLocalPracticeFeedback(
      currentStats: _stats,
      title: title,
      score: score,
      emoji: emoji,
      tags: tags,
      feedback: feedback,
      promptText: promptText,
      sceneDraft: sceneDraft,
      feedbackContext: feedbackContext,
    );
    _statsErrorMessage = null;
    notifyListeners();
    await _statsCoordinator.cacheStats(_stats);
    unawaited(
      _syncPracticeFeedback(
        durationSeconds: durationSeconds,
        score: score,
        title: title,
        emoji: emoji,
        tags: tags,
        feedback: feedback,
        promptText: promptText,
        sceneDraft: sceneDraft,
      ),
    );
  }

  Future<void> deleteRecentPracticeGroup(String title) async {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _stats = _statsCoordinator.deleteLocalPracticeGroup(
      currentStats: _stats,
      title: trimmed,
    );
    _statsErrorMessage = null;
    notifyListeners();
    await _statsCoordinator.cacheStats(_stats);
    unawaited(_syncDeletedPracticeGroup(trimmed));
  }

  Future<void> completeOnboarding({
    required List<String> goals,
    required int level,
    required int dailyMinutes,
  }) async {
    _onboardingDone = true;
    _user = _user?.copyWith(onboardingDone: true);
    notifyListeners();
    await _profileCoordinator.persistOnboarding(
      user: _user,
      goals: goals,
      level: level,
      dailyMinutes: dailyMinutes,
    );
    unawaited(
      _syncOnboardingAssessment(
        goals: goals,
        level: level,
        dailyMinutes: dailyMinutes,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _profileCoordinator.persistThemeMode(mode);
    unawaited(
      _syncUserPatch(<String, dynamic>{
        'themeMode': switch (mode) {
          ThemeMode.dark => 'dark',
          ThemeMode.light => 'light',
          ThemeMode.system => 'system',
        },
      }),
    );
  }

  Future<void> updateProfile({
    required String nickname,
    required String avatarUrl,
  }) async {
    final String trimmed = nickname.trim();
    if (trimmed.isEmpty) return;
    _user = _user?.copyWith(nickname: trimmed, avatarUrl: avatarUrl);
    notifyListeners();
    unawaited(_persistUserState());
    unawaited(_syncUserPatch(<String, dynamic>{'nickname': trimmed}));
  }

  Future<void> logout() async {
    _user = null;
    _stats = const LearningStatsModel();
    _onboardingDone = false;
    _themeMode = ThemeMode.light;
    _isStatsLoading = false;
    _authErrorMessage = null;
    _membershipErrorMessage = null;
    _statsErrorMessage = null;
    notifyListeners();
    await _profileCoordinator.clearSessionData();
    await _statsCoordinator.clearCache();
  }

  Future<void> deleteAccount() async {
    await _profileCoordinator.deleteAccount();
    _user = null;
    _stats = const LearningStatsModel();
    _onboardingDone = false;
    _themeMode = ThemeMode.light;
    _isStatsLoading = false;
    _authErrorMessage = null;
    _membershipErrorMessage = null;
    _statsErrorMessage = null;
    await _statsCoordinator.clearCache();
    notifyListeners();
  }

  Future<void> _persistUserState() async {
    await _profileCoordinator.persistUser(_user);
  }

  Future<void> _loadFromStorage() async {
    final StoredSessionSnapshot snapshot = await _sessionCoordinator
        .loadStoredSession();
    _user = snapshot.user;
    _onboardingDone = snapshot.onboardingDone;
    _themeMode = snapshot.themeMode;
    notifyListeners();
  }

  Future<void> _loadCachedStats() async {
    try {
      final LearningStatsModel? cached = await _statsCoordinator
          .loadCachedStats();
      if (cached != null) {
        _stats = cached;
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Cached learning stats could not be parsed',
      );
    } finally {
      _isStatsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _hydrateFromBackend() async {
    final ResolvedAuthenticatedSession? session;
    try {
      session = await _sessionCoordinator.hydrateExistingSession();
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Session hydration from backend failed',
      );
      return;
    }
    if (session == null) {
      return;
    }

    try {
      _applyUserJson(session.userJson);
      final bool hadStats = _stats.hasOverviewData;
      if (!hadStats) {
        _isStatsLoading = true;
      }
      notifyListeners();
      unawaited(_persistUserState());
      try {
        await _refreshStats(notify: false, silent: hadStats);
      } catch (error, stackTrace) {
        ErrorHandler.handleError(
          error,
          stackTrace: stackTrace,
          context: 'Learning stats refresh after hydration failed',
        );
      }
      notifyListeners();
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Session hydration from backend failed',
      );
      // Keep the local cache when the backend is temporarily unavailable.
    }
  }

  Future<void> _completeAuthenticatedSession(
    AuthenticatedSessionPayload payload,
  ) async {
    final ResolvedAuthenticatedSession session = await _sessionCoordinator
        .resolveAuthenticatedSession(payload);
    _applyUserJson(session.userJson);
    final bool hadStats = _stats.hasOverviewData;
    if (!hadStats) {
      _isStatsLoading = true;
    }
    unawaited(_persistUserState());
    try {
      await _refreshStats(notify: false, silent: hadStats);
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Learning stats refresh after sign-in failed',
      );
    }
  }

  Future<void> refreshStats({bool silent = false}) {
    return _refreshStats(silent: silent);
  }

  Future<void> _refreshStats({bool notify = true, bool silent = false}) async {
    if (!silent && !_stats.hasOverviewData) {
      _isStatsLoading = true;
      _statsErrorMessage = null;
      if (notify) {
        notifyListeners();
      }
    }

    try {
      _stats = await _statsCoordinator.refreshStats(currentStats: _stats);
      _statsErrorMessage = null;
    } catch (error) {
      _statsErrorMessage = _messageFromError(error, fallback: '获取学习统计失败，请稍后重试');
      rethrow;
    } finally {
      _isStatsLoading = false;
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> _syncRecordedSession({
    required int durationSeconds,
    required int score,
    String? title,
    String? emoji,
    List<String>? tags,
    SceneFeedback? feedback,
    String? promptText,
    SceneDraft? sceneDraft,
    String feedbackStatus = 'ready',
    Map<String, dynamic>? feedbackContext,
  }) async {
    try {
      final LearningStatsModel? remoteStats = await _statsCoordinator
          .syncRecordedSession(
            currentStats: _stats,
            durationSeconds: durationSeconds,
            score: score,
            title: title,
            emoji: emoji,
            tags: tags,
            feedback: feedback,
            promptText: promptText,
            sceneDraft: sceneDraft,
            feedbackStatus: feedbackStatus,
            feedbackContext: feedbackContext,
          );
      if (remoteStats == null) {
        return;
      }
      _stats = remoteStats;
      _statsErrorMessage = null;
      notifyListeners();
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Remote practice session sync failed',
      );
    }
  }

  Future<void> _syncPracticeFeedback({
    required int durationSeconds,
    required int score,
    required String title,
    String? emoji,
    List<String>? tags,
    required SceneFeedback feedback,
    String? promptText,
    SceneDraft? sceneDraft,
    Map<String, dynamic>? feedbackContext,
  }) async {
    try {
      final LearningStatsModel? remoteStats = await _statsCoordinator
          .syncPracticeFeedback(
            currentStats: _stats,
            durationSeconds: durationSeconds,
            score: score,
            title: title,
            emoji: emoji,
            tags: tags,
            feedback: feedback,
            promptText: promptText,
            sceneDraft: sceneDraft,
            feedbackContext: feedbackContext,
          );
      if (remoteStats == null) {
        return;
      }
      _stats = remoteStats;
      _statsErrorMessage = null;
      notifyListeners();
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Remote practice feedback upsert failed',
      );
    }
  }

  Future<void> _syncDeletedPracticeGroup(String title) async {
    try {
      final LearningStatsModel? remoteStats = await _statsCoordinator
          .syncDeletePracticeGroup(currentStats: _stats, title: title);
      if (remoteStats == null) {
        return;
      }
      _stats = remoteStats;
      _statsErrorMessage = null;
      notifyListeners();
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Remote practice group delete failed',
      );
    }
  }

  Future<void> _syncUserPatch(Map<String, dynamic> patch) async {
    if (patch.isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic>? data = await _profileCoordinator
          .syncUserPatch(patch);
      if (data != null && data.isNotEmpty) {
        _applyUserJson(data);
        notifyListeners();
        unawaited(_persistUserState());
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'User profile patch sync failed',
      );
    }
  }

  Future<void> _syncOnboardingAssessment({
    required List<String> goals,
    required int level,
    required int dailyMinutes,
  }) async {
    try {
      await _profileCoordinator.syncOnboardingAssessment(
        goalDirection: _goalDirectionFromGoals(goals),
        painPoints: _painPointsFromGoals(goals),
        outputLevel: _outputLevelFromAssessmentLevel(level),
        dailyMinutes: dailyMinutes,
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Onboarding assessment sync failed',
      );
    }
  }

  String _goalDirectionFromGoals(List<String> goals) {
    final String joined = goals.join('|');
    if (joined.contains('入职')) {
      return 'onboarding_introduction';
    }
    if (joined.contains('工作沟通') || joined.contains('会议')) {
      return 'work_communication';
    }
    if (joined.contains('日常') || joined.contains('生活服务')) {
      return 'daily_service';
    }
    return 'job_interview';
  }

  List<String> _painPointsFromGoals(List<String> goals) {
    final List<String> painPoints = goals
        .map((String goal) => goal.trim())
        .where((String goal) => goal.isNotEmpty)
        .take(5)
        .toList(growable: false);
    return painPoints.isEmpty ? <String>['opening'] : painPoints;
  }

  String _outputLevelFromAssessmentLevel(int level) {
    if (level <= 1) {
      return 'L1';
    }
    if (level == 2) {
      return 'L2';
    }
    return 'L3';
  }

  void _applyUserJson(Map<String, dynamic> json) {
    final AppUser remoteUser = AppUser.fromJson(json);
    final AppUser? currentUser = _user;
    _user = remoteUser.copyWith(
      avatarUrl: remoteUser.avatarUrl.isEmpty
          ? (currentUser?.avatarUrl ?? '')
          : remoteUser.avatarUrl,
    );
    _onboardingDone = _user!.onboardingDone;
    final String? themeMode = json['themeMode'] as String?;
    if (themeMode != null && themeMode.isNotEmpty) {
      _themeMode = _themeModeFromName(themeMode);
    }
  }

  ThemeMode _themeModeFromName(String name) {
    return switch (name) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  String _messageFromError(Object error, {required String fallback}) {
    final String text = error.toString().trim();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text.isEmpty ? fallback : text;
  }
}

class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({
    super.key,
    required AppSession session,
    required super.child,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final AppSessionScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppSessionScope>();
    assert(scope != null, 'AppSessionScope not found in context');
    return scope!.notifier!;
  }
}
