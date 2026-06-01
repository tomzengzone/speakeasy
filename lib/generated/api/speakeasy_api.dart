// Generated from docs/architecture/openapi/speakeasy-api.yaml.
// Do not edit without updating docs/architecture/openapi/dart-client-drift-manifest.json.

class SpeakeasyApiContract {
  const SpeakeasyApiContract._();

  static const String openApiSha256 =
      '9340e9d3f6a997f426aa11402b385e3a9004f320bb4ef0ff78d2d0067f2c41a9';

  static const List<String> pathTemplates = <String>[
    '/achievements/status',
    '/admin/audit',
    '/admin/data-deletion/{job_id}/retry',
    '/admin/release-health',
    '/ai/coach-turn',
    '/ai/feedback',
    '/ai/pronunciation',
    '/ai/transcribe',
    '/ai/tts',
    '/auth/login/apple',
    '/auth/login/phone',
    '/auth/login/wechat',
    '/auth/logout',
    '/auth/refresh',
    '/entitlements',
    '/entitlements/refresh',
    '/expressions/queue',
    '/expressions/tasks/{queue_item_id}/complete',
    '/favorites/expressions',
    '/favorites/expressions/{favorite_id}',
    '/home/summary',
    '/learning/evidence',
    '/learning/history',
    '/learning/history/{history_entry_id}',
    '/learning/mastery',
    '/learning/report/summary',
    '/learning/wiki',
    '/membership/android/purchase',
    '/membership/android/restore',
    '/membership/boundary',
    '/offline-content/status',
    '/onboarding/assessment',
    '/practice/sessions',
    '/practice/sessions/{session_id}',
    '/practice/sessions/{session_id}/complete',
    '/practice/sessions/{session_id}/turns',
    '/review/items',
    '/review/items/{review_item_id}/result',
    '/scenarios',
    '/scenarios/{scenario_id}',
    '/scenarios/{scenario_id}/levels/{level_code}',
    '/subscription/plans',
    '/subscriptions/apple/verify',
    '/subscriptions/google/verify',
    '/subscriptions/restore',
    '/subscriptions/webhook/apple',
    '/subscriptions/webhook/google',
    '/training/sessions',
    '/training/sessions/{session_id}',
    '/training/sessions/{session_id}/complete',
    '/training/sessions/{session_id}/hints',
    '/training/sessions/{session_id}/planner/next',
    '/training/sessions/{session_id}/pressure-check',
    '/training/sessions/{session_id}/turns',
    '/usage/commit',
    '/usage/release',
    '/usage/reserve',
    '/usage/summary',
    '/user/deletion-status',
    '/user/me',
    '/user/scenarios/current',
    '/user/scenarios/{scenario_id}',
  ];
}

class SpeakeasyApiPaths {
  const SpeakeasyApiPaths._();

  static const String achievementsStatus = '/achievements/status';
  static const String adminAudit = '/admin/audit';
  static const String adminReleaseHealth = '/admin/release-health';
  static const String aiCoachTurn = '/ai/coach-turn';
  static const String aiFeedback = '/ai/feedback';
  static const String aiPronunciation = '/ai/pronunciation';
  static const String aiTranscribe = '/ai/transcribe';
  static const String aiTts = '/ai/tts';
  static const String authLoginApple = '/auth/login/apple';
  static const String authLoginPhone = '/auth/login/phone';
  static const String authLoginWechat = '/auth/login/wechat';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  static const String entitlements = '/entitlements';
  static const String entitlementsRefresh = '/entitlements/refresh';
  static const String expressionsQueue = '/expressions/queue';
  static const String favoritesExpressions = '/favorites/expressions';
  static const String homeSummary = '/home/summary';
  static const String learningEvidence = '/learning/evidence';
  static const String learningHistory = '/learning/history';
  static const String learningMastery = '/learning/mastery';
  static const String learningReportSummary = '/learning/report/summary';
  static const String learningWiki = '/learning/wiki';
  static const String membershipAndroidPurchase =
      '/membership/android/purchase';
  static const String membershipAndroidRestore = '/membership/android/restore';
  static const String membershipBoundary = '/membership/boundary';
  static const String offlineContentStatus = '/offline-content/status';
  static const String onboardingAssessment = '/onboarding/assessment';
  static const String practiceSessions = '/practice/sessions';
  static const String reviewItems = '/review/items';
  static const String scenarios = '/scenarios';
  static const String subscriptionPlans = '/subscription/plans';
  static const String subscriptionsAppleVerify = '/subscriptions/apple/verify';
  static const String subscriptionsGoogleVerify =
      '/subscriptions/google/verify';
  static const String subscriptionsRestore = '/subscriptions/restore';
  static const String subscriptionsWebhookApple =
      '/subscriptions/webhook/apple';
  static const String subscriptionsWebhookGoogle =
      '/subscriptions/webhook/google';
  static const String trainingSessions = '/training/sessions';
  static const String usageCommit = '/usage/commit';
  static const String usageRelease = '/usage/release';
  static const String usageReserve = '/usage/reserve';
  static const String usageSummary = '/usage/summary';
  static const String userDeletionStatus = '/user/deletion-status';
  static const String userMe = '/user/me';
  static const String userScenariosCurrent = '/user/scenarios/current';

  static String adminDataDeletionRetry(String jobId) =>
      '/admin/data-deletion/${_path(jobId)}/retry';

  static String expressionTaskComplete(String queueItemId) =>
      '/expressions/tasks/${_path(queueItemId)}/complete';

  static String favoriteExpression(String favoriteId) =>
      '/favorites/expressions/${_path(favoriteId)}';

  static String learningHistoryEntry(String historyEntryId) =>
      '/learning/history/${_path(historyEntryId)}';

  static String practiceSession(String sessionId) =>
      '/practice/sessions/${_path(sessionId)}';

  static String practiceSessionComplete(String sessionId) =>
      '/practice/sessions/${_path(sessionId)}/complete';

  static String practiceSessionTurns(String sessionId) =>
      '/practice/sessions/${_path(sessionId)}/turns';

  static String reviewItemResult(String reviewItemId) =>
      '/review/items/${_path(reviewItemId)}/result';

  static String scenario(String scenarioId) =>
      '/scenarios/${_path(scenarioId)}';

  static String scenarioLevel(String scenarioId, String levelCode) =>
      '/scenarios/${_path(scenarioId)}/levels/${_path(levelCode)}';

  static String trainingSession(String sessionId) =>
      '/training/sessions/${_path(sessionId)}';

  static String trainingSessionComplete(String sessionId) =>
      '/training/sessions/${_path(sessionId)}/complete';

  static String trainingSessionHints(String sessionId) =>
      '/training/sessions/${_path(sessionId)}/hints';

  static String trainingSessionPlannerNext(String sessionId) =>
      '/training/sessions/${_path(sessionId)}/planner/next';

  static String trainingSessionPressureCheck(String sessionId) =>
      '/training/sessions/${_path(sessionId)}/pressure-check';

  static String trainingSessionTurns(String sessionId) =>
      '/training/sessions/${_path(sessionId)}/turns';

  static String userScenario(String scenarioId) =>
      '/user/scenarios/${_path(scenarioId)}';

  static String _path(String value) => Uri.encodeComponent(value);
}
