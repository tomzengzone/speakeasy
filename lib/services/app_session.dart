import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:speakeasy/application/contracts/app_repository.dart';
import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/application/session/session_profile_coordinator.dart';
import 'package:speakeasy/application/session/session_stats_coordinator.dart';
import 'package:speakeasy/config/payment_config.dart';
import 'package:speakeasy/core/constants/avatar_defaults.dart';
import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_client.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_projection.dart';
import 'package:speakeasy/services/ai_repository.dart';
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
    return AndroidPaymentService();
  }
  return const UnsupportedPaymentService();
}

class AppSession extends ChangeNotifier {
  factory AppSession({
    AppRepository? repository,
    PaymentService? paymentService,
    StatsService? statsService,
    AuthService? authService,
    CommercialEntitlementClient? entitlementClient,
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
      entitlementClient: entitlementClient ?? CommercialEntitlementClient(),
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
    required CommercialEntitlementClient entitlementClient,
    required SessionLifecycleCoordinator sessionCoordinator,
    required SessionProfileCoordinator profileCoordinator,
    required SessionStatsCoordinator statsCoordinator,
  }) : _repository = repository,
       _paymentService = paymentService,
       _entitlementClient = entitlementClient,
       _sessionCoordinator = sessionCoordinator,
       _profileCoordinator = profileCoordinator,
       _statsCoordinator = statsCoordinator {
    Future.microtask(_loadFromStorage);
    Future.microtask(_loadCachedStats);
    Future.microtask(_hydrateFromBackend);
  }

  final AppRepository _repository;
  final PaymentService _paymentService;
  final CommercialEntitlementClient _entitlementClient;
  final SessionLifecycleCoordinator _sessionCoordinator;
  final SessionProfileCoordinator _profileCoordinator;
  final SessionStatsCoordinator _statsCoordinator;

  AppUser? _user;
  CommercialEntitlementProjection _entitlementProjection =
      CommercialEntitlementProjection.unknown();
  Future<CommercialEntitlementProjection>? _entitlementRefreshInFlight;
  int _entitlementRefreshGeneration = 0;
  String? _displayProductPlan;
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
  CommercialEntitlementProjection get entitlementProjection =>
      _entitlementProjection;

  String get nickname => _user?.nickname ?? '学习者';
  String get avatarUrl {
    return _builtInAvatarRefOrDefault(_user?.avatarUrl);
  }

  bool get hasActivePaidEntitlement =>
      _entitlementProjection.isFreshDisplayPaidFromBackendProjection();

  String get displayMemberPlan {
    return _displayProductPlan ?? _user?.memberPlan ?? 'free';
  }

  @Deprecated('Display-only compatibility. Do not use for paid gates.')
  String get memberPlan => _user?.memberPlan ?? 'free';

  @Deprecated(
    'Display-only compatibility. Use entitlementProjection for gates.',
  )
  bool get isPro => hasActivePaidEntitlement;

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
        _resetEntitlementProjection();
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
    if (_user == null) {
      _membershipErrorMessage = '请先登录';
      notifyListeners();
      return;
    }

    _isUpdatingMembership = true;
    _membershipErrorMessage = null;
    final int operationGeneration = _beginEntitlementOperation();
    notifyListeners();

    try {
      final PaymentResult paymentResult = await _paymentService.purchasePlan(
        planId,
      );
      if (!_isCurrentEntitlementOperation(operationGeneration)) {
        return;
      }
      if (!paymentResult.success) {
        _membershipErrorMessage = paymentResult.displayMessage;
        if (paymentResult.entitlement != null) {
          _applyPaymentEntitlement(
            paymentResult.entitlement,
            expectedGeneration: operationGeneration,
          );
        }
        return;
      }

      if (!_applyPaymentEntitlement(
        paymentResult.entitlement,
        expectedGeneration: operationGeneration,
      )) {
        _membershipErrorMessage = '订阅已提交，但未收到后端权益确认，请稍后刷新';
        return;
      }
      _rememberDisplayProductPlan(paymentResult.planId ?? planId);
    } catch (error) {
      if (_isCurrentEntitlementOperation(operationGeneration)) {
        _membershipErrorMessage = _messageFromError(
          error,
          fallback: '会员状态更新失败，请稍后重试',
        );
      }
    } finally {
      _isUpdatingMembership = false;
      notifyListeners();
    }
  }

  Future<void> restoreMembershipPurchases() async {
    if (_user == null) {
      _membershipErrorMessage = '请先登录';
      notifyListeners();
      return;
    }

    _isUpdatingMembership = true;
    _membershipErrorMessage = null;
    final int operationGeneration = _beginEntitlementOperation();
    notifyListeners();

    try {
      final PaymentResult result = await _paymentService.restorePurchases();
      if (!_isCurrentEntitlementOperation(operationGeneration)) {
        return;
      }
      _applyPaymentEntitlement(
        result.entitlement,
        expectedGeneration: operationGeneration,
      );
      if (!result.success) {
        _membershipErrorMessage = result.displayMessage;
        return;
      }
      if (result.entitlement == null) {
        _membershipErrorMessage = '恢复成功，但未收到后端权益确认，请稍后刷新';
      }
      _rememberDisplayProductPlan(result.planId);
    } catch (error) {
      if (_isCurrentEntitlementOperation(operationGeneration)) {
        _membershipErrorMessage = _messageFromError(
          error,
          fallback: '恢复购买失败，请稍后重试',
        );
      }
    } finally {
      _isUpdatingMembership = false;
      notifyListeners();
    }
  }

  Future<void> refreshMembershipStatus({bool silent = true}) async {
    if (_user == null) {
      return;
    }
    if (_isUpdatingMembership) {
      return;
    }

    final int operationGeneration = _beginEntitlementOperation();
    if (!silent) {
      _isUpdatingMembership = true;
      _membershipErrorMessage = null;
      notifyListeners();
    }

    try {
      final PaymentResult result = await _paymentService
          .checkSubscriptionStatus();
      if (!_isCurrentEntitlementOperation(operationGeneration)) {
        return;
      }
      _applyPaymentEntitlement(
        result.entitlement,
        expectedGeneration: operationGeneration,
      );
      if (!result.success && !silent) {
        _membershipErrorMessage = result.displayMessage;
      }
    } catch (error) {
      _markEntitlementRefreshFailed(
        error,
        expectedGeneration: operationGeneration,
      );
      if (!silent && _isCurrentEntitlementOperation(operationGeneration)) {
        _membershipErrorMessage = _messageFromError(
          error,
          fallback: '订阅状态检查失败，请稍后重试',
        );
      }
    } finally {
      if (!silent && _isCurrentEntitlementOperation(operationGeneration)) {
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

  Future<CommercialEntitlementProjection> refreshEntitlementProjection({
    bool silent = true,
  }) async {
    if (_user == null) {
      _resetEntitlementProjection();
      if (!silent) {
        notifyListeners();
      }
      return _entitlementProjection;
    }
    if (_isUpdatingMembership) {
      return _entitlementProjection;
    }

    final Future<CommercialEntitlementProjection>? inFlight =
        _entitlementRefreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    if (!silent) {
      _membershipErrorMessage = null;
    }
    _entitlementProjection = CommercialEntitlementProjection.refreshing(
      _entitlementProjection,
    );
    notifyListeners();

    final int refreshGeneration = _beginEntitlementOperation();
    late final Future<CommercialEntitlementProjection> refreshFuture;
    refreshFuture = () async {
      try {
        final CommercialEntitlementProjection projection =
            await _entitlementClient.refreshProjection();
        if (_user == null ||
            refreshGeneration != _entitlementRefreshGeneration) {
          return _entitlementProjection;
        }
        _entitlementProjection = projection;
        return projection;
      } catch (error) {
        if (_user == null ||
            refreshGeneration != _entitlementRefreshGeneration) {
          return _entitlementProjection;
        }
        _entitlementProjection = CommercialEntitlementProjection.failed(
          _entitlementProjection,
          errorMessage: _messageFromError(error, fallback: '权益刷新失败，请稍后重试'),
        );
        if (!silent) {
          _membershipErrorMessage = _entitlementProjection.errorMessage;
        }
        return _entitlementProjection;
      } finally {
        if (identical(_entitlementRefreshInFlight, refreshFuture)) {
          _entitlementRefreshInFlight = null;
        }
        if (_user != null &&
            refreshGeneration == _entitlementRefreshGeneration) {
          notifyListeners();
        }
      }
    }();
    _entitlementRefreshInFlight = refreshFuture;
    return refreshFuture;
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

  @Deprecated('Use updateProfile so avatar_ref syncs through PATCH /user/me.')
  Future<void> updateAvatar(String avatarUrl) async {
    final AppUser? currentUser = _user;
    final String avatarRef = _builtInAvatarRefOrDefault(avatarUrl);
    if (currentUser == null || currentUser.avatarUrl == avatarRef) {
      return;
    }
    await updateProfile(nickname: nickname, avatarUrl: avatarRef);
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
    final String avatarRef = _builtInAvatarRefOrDefault(avatarUrl);
    _user = _user?.copyWith(nickname: trimmed, avatarUrl: avatarRef);
    notifyListeners();
    unawaited(_persistUserState());
    unawaited(
      _syncUserPatch(<String, dynamic>{
        'display_name': trimmed,
        'avatar_ref': avatarRef,
      }),
    );
  }

  Future<void> logout() async {
    _user = null;
    _resetEntitlementProjection();
    _stats = const LearningStatsModel();
    _onboardingDone = false;
    _themeMode = ThemeMode.light;
    _isStatsLoading = false;
    _isUpdatingMembership = false;
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
    _resetEntitlementProjection();
    _stats = const LearningStatsModel();
    _onboardingDone = false;
    _themeMode = ThemeMode.light;
    _isStatsLoading = false;
    _isUpdatingMembership = false;
    _authErrorMessage = null;
    _membershipErrorMessage = null;
    _statsErrorMessage = null;
    await _statsCoordinator.clearCache();
    notifyListeners();
  }

  Future<void> _persistUserState() async {
    await _profileCoordinator.persistUser(_user);
  }

  bool _applyPaymentEntitlement(
    CommercialEntitlementProjection? projection, {
    required int expectedGeneration,
    bool notify = true,
  }) {
    if (_user == null || expectedGeneration != _entitlementRefreshGeneration) {
      return false;
    }
    if (projection == null) {
      _markEntitlementRefreshFailed(
        Exception('后端权益确认缺失'),
        expectedGeneration: expectedGeneration,
        notify: notify,
      );
      return false;
    }
    _entitlementRefreshInFlight = null;
    _entitlementProjection = projection;
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  bool _isCurrentEntitlementOperation(int expectedGeneration) {
    return _user != null && expectedGeneration == _entitlementRefreshGeneration;
  }

  int _beginEntitlementOperation() {
    _entitlementRefreshGeneration += 1;
    return _entitlementRefreshGeneration;
  }

  void _markEntitlementRefreshFailed(
    Object error, {
    required int expectedGeneration,
    bool notify = true,
  }) {
    if (_user == null || expectedGeneration != _entitlementRefreshGeneration) {
      return;
    }
    _entitlementRefreshInFlight = null;
    _entitlementProjection = CommercialEntitlementProjection.failed(
      _entitlementProjection,
      errorMessage: _messageFromError(error, fallback: '权益刷新失败，请稍后重试'),
    );
    if (notify) {
      notifyListeners();
    }
  }

  void _resetEntitlementProjection() {
    _entitlementRefreshGeneration += 1;
    _entitlementRefreshInFlight = null;
    _entitlementProjection = CommercialEntitlementProjection.unknown();
    _displayProductPlan = null;
  }

  void _rememberDisplayProductPlan(String? planId) {
    final String normalizedPlan = PaymentConfig.normalizePlanId(planId);
    if (normalizedPlan == PaymentConfig.freePlanId) {
      return;
    }
    _displayProductPlan = normalizedPlan;
  }

  Future<void> _loadFromStorage() async {
    final StoredSessionSnapshot snapshot = await _sessionCoordinator
        .loadStoredSession();
    _user = snapshot.user;
    _onboardingDone = snapshot.onboardingDone;
    _themeMode = snapshot.themeMode;
    notifyListeners();
    if (_user != null) {
      unawaited(refreshEntitlementProjection());
    }
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
      _resetEntitlementProjection();
      _applyUserJson(session.userJson);
      final bool hadStats = _stats.hasOverviewData;
      if (!hadStats) {
        _isStatsLoading = true;
      }
      notifyListeners();
      unawaited(_persistUserState());
      unawaited(refreshEntitlementProjection());
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
    _resetEntitlementProjection();
    _applyUserJson(session.userJson);
    final bool hadStats = _stats.hasOverviewData;
    if (!hadStats) {
      _isStatsLoading = true;
    }
    unawaited(_persistUserState());
    unawaited(refreshEntitlementProjection());
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
    final String remoteAvatarRef = remoteUser.avatarUrl.isEmpty
        ? (currentUser?.avatarUrl ?? '')
        : remoteUser.avatarUrl;
    _user = remoteUser.copyWith(
      avatarUrl: _builtInAvatarRefOrDefault(remoteAvatarRef),
    );
    _displayProductPlan = remoteUser.memberPlan;
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

  String _builtInAvatarRefOrDefault(String? avatarRef) {
    final String value = avatarRef?.trim() ?? '';
    return defaultAvatarUrls.contains(value) ? value : defaultAvatarUrls.first;
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
