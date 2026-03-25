import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'ai_repository.dart';
import 'api_client.dart';
import 'app_models.dart';
import 'auth_models.dart';
import 'config/app_config.dart';
import 'config/payment_config.dart';
import 'models/learning_stats_model.dart';
import 'models/storage_models.dart';
import 'services/apple_auth_service.dart';
import 'services/apple_payment_service.dart';
import 'services/android_payment_service.dart';
import 'services/auth_service.dart';
import 'services/payment_service.dart';
import 'services/storage_service.dart';
import 'services/stats_service.dart';
import 'services/wechat_auth_service.dart';
import 'utils/error_handler.dart';

export 'auth_models.dart';

const List<String> defaultAvatarUrls = <String>[
  'https://images.unsplash.com/photo-1725887150031-d353e5c4ce3a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
  'https://images.unsplash.com/photo-1517841905240-472988babdf9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
  'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
  'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
];

class SceneHistoryTurn {
  const SceneHistoryTurn({required this.role, required this.text});

  final String role;
  final String text;
}

class SceneReply {
  const SceneReply({
    required this.npcText,
    this.coachHint,
    this.eventLabel,
    this.eventColor,
    this.mood,
  });

  final String npcText;
  final String? coachHint;
  final String? eventLabel;
  final Color? eventColor;
  final String? mood;
}

class PronunciationScore {
  const PronunciationScore({
    required this.overall,
    this.accuracy,
    this.fluency,
    this.completeness,
  });

  /// 0–100 overall score
  final int overall;
  final int? accuracy;
  final int? fluency;
  final int? completeness;
}

class SceneFeedbackMetric {
  const SceneFeedbackMetric({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;
}

class SceneFeedback {
  const SceneFeedback({
    required this.overallScore,
    required this.headline,
    required this.summary,
    required this.metrics,
    required this.coachTip,
    required this.improvements,
  });

  final int overallScore;
  final String headline;
  final String summary;
  final List<SceneFeedbackMetric> metrics;
  final String coachTip;

  /// Each item: (emoji, title, detail)
  final List<(String, String, String)> improvements;
}

abstract class AppRepository {
  Future<AppUser> signIn(LoginSubmission submission);

  Future<AppUser> changeMembership({
    required AppUser user,
    required String planId,
  });

  Future<SceneReply> sendSceneMessage({
    required String sessionId,
    required String userText,
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  });

  Future<PronunciationScore> scorePronunciation({
    required String audioPath,
    required String expectedText,
  });

  Future<SceneFeedback> generateSceneFeedback({
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  });
}

class DemoAppRepository implements AppRepository {
  const DemoAppRepository();

  static const Set<String> _validPlans = <String>{
    ...PaymentConfig.validPlanIds,
  };

  @override
  Future<AppUser> signIn(LoginSubmission submission) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final String nickname = switch (submission.provider) {
      LoginProvider.wechat => '微信用户',
      LoginProvider.apple => 'Apple 用户',
      LoginProvider.phone => _phoneNickname(submission.phone),
      LoginProvider.email => _emailNickname(
        email: submission.email,
        nickname: submission.nickname,
      ),
    };

    return AppUser(
      nickname: nickname,
      avatarUrl: defaultAvatarUrls.first,
      memberPlan: 'free',
    );
  }

  @override
  Future<AppUser> changeMembership({
    required AppUser user,
    required String planId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!_validPlans.contains(planId)) {
      throw Exception('无效的会员方案');
    }

    return user.copyWith(memberPlan: planId);
  }

  @override
  Future<SceneReply> sendSceneMessage({
    required String sessionId,
    required String userText,
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  }) async {
    if (sessionId.isNotEmpty) {
      try {
        final String reply = await ApiClient.sendMessage(sessionId, userText);
        if (reply.trim().isNotEmpty) {
          return SceneReply(npcText: reply.trim());
        }
      } catch (error, stackTrace) {
        ErrorHandler.handleError(
          error,
          stackTrace: stackTrace,
          context: 'Scene message proxy request failed',
        );
        // Fall back to the local demo response below.
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    final int round = history.where((t) => t.role == 'user').length;
    const List<String> npcReplies = <String>[
      'Understood. Be specific about the recovery plan and give me one concrete milestone.',
      'That is clearer. Now tell me what you will say if the client asks who is accountable.',
      'Better. I still need a date, an owner, and the message you will send after this call.',
    ];
    const List<String> coachHints = <String>['不要过度解释', '直接给时间点', '先稳住，再给动作'];
    const List<(String, Color)> events = <(String, Color)>[
      ('对方要求直接回答', Color(0xFF8BA8E0)),
      ('对方继续追问责任归属', Color(0xFFE8855A)),
      ('对话节奏正在变快', Color(0xFF7ACFBD)),
    ];
    if (round.isEven) {
      final (String label, Color color) = events[round % events.length];
      return SceneReply(
        npcText: npcReplies[round % npcReplies.length],
        eventLabel: label,
        eventColor: color,
        mood: round.isEven ? '变得不耐烦' : '等待你的直接回答',
      );
    } else {
      return SceneReply(
        npcText: npcReplies[round % npcReplies.length],
        coachHint: coachHints[round % coachHints.length],
        mood: '等待你的直接回答',
      );
    }
  }

  @override
  Future<PronunciationScore> scorePronunciation({
    required String audioPath,
    required String expectedText,
  }) async {
    try {
      final Map<String, dynamic> score = await ApiClient.scoreAudio(
        File(audioPath),
        expectedText,
      );
      return PronunciationScore(
        overall: (score['overall'] as num?)?.toInt() ?? 0,
        accuracy: (score['accuracy'] as num?)?.toInt(),
        fluency: (score['fluency'] as num?)?.toInt(),
        completeness: (score['completeness'] as num?)?.toInt(),
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Pronunciation scoring request failed',
      );
      // Keep the demo scoring fallback when the backend is unavailable.
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    final int base = 68 + (expectedText.length % 28);
    return PronunciationScore(
      overall: base,
      accuracy: base + 4 > 100 ? 100 : base + 4,
      fluency: base - 6 < 0 ? 0 : base - 6,
      completeness: base + 2 > 100 ? 100 : base + 2,
    );
  }

  @override
  Future<SceneFeedback> generateSceneFeedback({
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final int rounds = history.where((t) => t.role == 'user').length;
    final int overall = (62 + rounds * 4).clamp(62, 95);
    return SceneFeedback(
      overallScore: overall,
      headline: rounds >= 4 ? '核心任务完成，细节还可以打磨 ✨' : '已经开了个好头，继续练习会更流畅 💪',
      summary:
          '你完成了 $rounds 轮对话，整体表达清楚。在 ${draft.npcName} 的追问下保持了基本节奏，继续多练高压场景会更稳。',
      metrics: const <SceneFeedbackMetric>[
        SceneFeedbackMetric(label: '清晰度', score: 85, color: Color(0xFF4A7C6F)),
        SceneFeedbackMetric(label: '结构感', score: 78, color: Color(0xFF5A6FA8)),
        SceneFeedbackMetric(label: '临场应对', score: 72, color: Color(0xFFA0622A)),
      ],
      coachTip: '下一轮把恢复方案提前说出来，再补一句具体时间点，表达会更像真实职场风格。',
      improvements: const <(String, String, String)>[
        ('🎯', '先说补救动作', '先解释原因容易让对方觉得在推卸责任，把行动方案放在句子开头压力会明显下降。'),
        ('🧭', '给出具体时间点', '模糊的"稍后""很快"远不如"今晚 6 点前"有说服力，时间承诺让对方更有安全感。'),
        ('🗣️', '减少解释腔', '连续使用 because 会显得在辩解，拆成两句先担责再给方案会更自然。'),
      ],
    );
  }

  String _phoneNickname(String? phone) {
    final String value = (phone ?? '').trim();
    if (value.length < 4) {
      return '学习者';
    }
    return '用户${value.substring(value.length - 4)}';
  }

  String _emailNickname({String? email, String? nickname}) {
    final String customNickname = (nickname ?? '').trim();
    if (customNickname.isNotEmpty) {
      return customNickname;
    }

    final String value = (email ?? '').trim();
    if (value.contains('@')) {
      return value.split('@').first;
    }
    return '学习者';
  }
}

AppRepository _defaultRepository() {
  // 优先使用后端 API（ApiClient），OpenAI key 为空时后端直接处理 AI
  // 只有在明确传入 OPENAI_API_KEY 时才走 OpenAI 直连
  final String key = AppConfig.openAiApiKey;
  return OpenAiAppRepository(apiKey: key);
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
  }) {
    final AppRepository resolvedRepository = repository ?? _defaultRepository();
    return AppSession._(
      repository: resolvedRepository,
      paymentService: paymentService ?? _defaultPaymentService(),
      statsService: statsService ?? const StatsService(),
      authService:
          authService ??
          AuthService(signInWithEmail: resolvedRepository.signIn),
    );
  }

  AppSession._({
    required AppRepository repository,
    required PaymentService paymentService,
    required StatsService statsService,
    required AuthService authService,
  }) : _repository = repository,
       _paymentService = paymentService,
       _statsService = statsService,
       _authService = authService {
    Future.microtask(_loadFromStorage);
    Future.microtask(_loadCachedStats);
    Future.microtask(_hydrateFromBackend);
  }

  final AppRepository _repository;
  final PaymentService _paymentService;
  final StatsService _statsService;
  final AuthService _authService;

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
      final AuthSession session = await _authService.signIn(submission);
      if (session.hasToken) {
        await _completeAuthenticatedSession(
          token: session.token!,
          userJson: session.userJson,
        );
      } else {
        _user = session.user;
        unawaited(_saveToStorage());
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
      final AppleAuthResult result = await (service ?? const AppleAuthService())
          .signInWithApple();
      await _completeAuthenticatedSession(
        token: result.token,
        userJson: result.userJson,
      );
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
      final WeChatAuthResult result =
          await (service ?? WeChatAuthService.instance).sendWeChatAuth();
      await _completeAuthenticatedSession(
        token: result.token,
        userJson: result.userJson,
      );
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
      final Map<String, dynamic> res = await ApiClient.verifySmsCode(
        phone.trim(),
        code.trim(),
      );
      if (res['code'] != 0) {
        throw Exception(res['message'] ?? '登录失败');
      }

      final Map<String, dynamic> data = _asMap(res['data']);
      final String token = (data['token'] as String?) ?? '';
      if (token.isEmpty) {
        throw Exception('登录凭证无效');
      }

      await _completeAuthenticatedSession(
        token: token,
        userJson: _asMap(data['user']),
      );
    } catch (error) {
      _authErrorMessage = _messageFromError(error, fallback: '登录失败，请稍后重试');
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
      unawaited(_saveToStorage());
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
      unawaited(_saveToStorage());
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
          unawaited(_saveToStorage());
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
        unawaited(_saveToStorage());
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
  }) {
    return _repository.generateSceneFeedback(draft: draft, history: history);
  }

  void updateAvatar(String avatarUrl) {
    final AppUser? currentUser = _user;
    if (currentUser == null || currentUser.avatarUrl == avatarUrl) {
      return;
    }
    _user = currentUser.copyWith(avatarUrl: avatarUrl);
    notifyListeners();
    unawaited(_saveToStorage());
  }

  Future<void> recordPracticeSession({
    required int durationSeconds,
    required int score,
  }) async {
    _stats = _stats.recordLocalSession(
      durationSeconds: durationSeconds,
      score: score,
      practicedAt: DateTime.now(),
    );
    _statsErrorMessage = null;
    notifyListeners();
    await _statsService.cacheStats(_stats);
    unawaited(
      _recordRemoteSession(durationSeconds: durationSeconds, score: score),
    );
  }

  Future<void> completeOnboarding({
    required List<String> goals,
    required int level,
    required int dailyMinutes,
  }) async {
    final StorageService storage = StorageService.instance;
    _onboardingDone = true;
    _user = _user?.copyWith(onboardingDone: true);
    await storage.saveUserPreferences(
      storage.getUserPreferences().copyWith(
        onboardingDone: true,
        goals: goals,
        level: level,
        dailyGoalMinutes: dailyMinutes,
      ),
    );
    await _saveToStorage();
    notifyListeners();
    unawaited(
      _syncUserPatch(<String, dynamic>{
        'onboardingDone': true,
        'goals': goals,
        'level': level,
        'dailyMinutes': dailyMinutes,
      }),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final StorageService storage = StorageService.instance;
    await storage.saveUserPreferences(
      storage.getUserPreferences().copyWith(themeMode: mode),
    );
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
    unawaited(_saveToStorage());
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
    await StorageService.instance.clearUserProfile();
    await StorageService.instance.clearUserPreferences();
    await _statsService.clearCache();
    await ApiClient.clearToken();
  }

  Future<void> _saveToStorage() async {
    final AppUser? user = _user;
    if (user == null) return;
    final StorageService storage = StorageService.instance;
    await storage.saveUserProfile(StoredUserProfileModel.fromAppUser(user));
    await storage.saveUserPreferences(
      storage.getUserPreferences().copyWith(
        onboardingDone: user.onboardingDone,
      ),
    );
  }

  Future<void> _loadFromStorage() async {
    final StorageService storage = StorageService.instance;
    final AuthSessionStorageModel? authSession = storage.getAuthSession();
    final StoredUserProfileModel? userProfile = storage.getUserProfile();
    final UserPreferencesStorageModel preferences = storage
        .getUserPreferences();
    // 只有存在 JWT token 时才恢复用户，避免"假登录"状态导致 API 401
    final String? token = authSession?.token;
    if (token != null && token.isNotEmpty) {
      final String nickname = (userProfile?.nickname ?? '').trim();
      if (nickname.isNotEmpty) {
        _user = userProfile!.toAppUser().copyWith(
          avatarUrl: userProfile.avatarUrl.isEmpty
              ? defaultAvatarUrls.first
              : userProfile.avatarUrl,
          memberPlan: PaymentConfig.normalizePlanId(userProfile.memberPlan),
        );
      }
    }
    _onboardingDone = preferences.onboardingDone;
    _themeMode = preferences.themeMode;
    notifyListeners();
  }

  Future<void> _loadCachedStats() async {
    try {
      final LearningStatsModel? cached = await _statsService.loadCachedStats();
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
    final String? token = await ApiClient.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic> refreshRes = await ApiClient.refreshToken();
      if (refreshRes['code'] == 0) {
        final Map<String, dynamic> data = _asMap(refreshRes['data']);
        final String refreshedToken = (data['token'] as String?) ?? '';
        if (refreshedToken.isNotEmpty) {
          await ApiClient.saveToken(refreshedToken);
        }
        _applyUserJson(_asMap(data['user']));
      } else {
        final Map<String, dynamic> meRes = await ApiClient.getMe();
        if (meRes['code'] != 0) {
          throw Exception(meRes['message'] ?? refreshRes['message']);
        }
        _applyUserJson(_asMap(meRes['data']));
      }
      final bool hadStats = _stats.hasOverviewData;
      if (!hadStats) {
        _isStatsLoading = true;
      }
      notifyListeners();
      unawaited(_saveToStorage());
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

  Future<void> _completeAuthenticatedSession({
    required String token,
    required Map<String, dynamic> userJson,
  }) async {
    await ApiClient.saveToken(token);
    if (userJson.isNotEmpty) {
      _applyUserJson(userJson);
    } else {
      final Map<String, dynamic> meRes = await ApiClient.getMe();
      if (meRes['code'] != 0) {
        throw Exception(meRes['message'] ?? '获取用户信息失败');
      }
      _applyUserJson(_asMap(meRes['data']));
    }
    final bool hadStats = _stats.hasOverviewData;
    if (!hadStats) {
      _isStatsLoading = true;
    }
    unawaited(_saveToStorage());
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
      _stats = await _statsService.refreshStats();
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

  Future<void> _recordRemoteSession({
    required int durationSeconds,
    required int score,
  }) async {
    final String? token = await ApiClient.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      _stats = await _statsService.recordSession(
        durationSeconds: durationSeconds,
        score: score,
      );
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

  Future<void> _syncUserPatch(Map<String, dynamic> patch) async {
    if (patch.isEmpty) {
      return;
    }

    final String? token = await ApiClient.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic> res = await ApiClient.updateMe(patch);
      if (res['code'] == 0 && res['data'] != null) {
        final Map<String, dynamic> data = _asMap(res['data']);
        if (data.isNotEmpty) {
          _applyUserJson(data);
          notifyListeners();
          unawaited(_saveToStorage());
        }
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'User profile patch sync failed',
      );
    }
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

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
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
