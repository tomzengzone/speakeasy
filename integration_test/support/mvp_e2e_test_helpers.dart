import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/features/interview/interview_wiki_store.dart';
import 'package:speakeasy/main.dart' as app;
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/pages/onboarding_page.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/storage_service.dart';

const String mvpSystemE2ePhone = '13800139999';

enum E2eScrollDirection { up, down }

void launchMvpSystemApp() {
  final originalFlutterError = FlutterError.onError;
  final ErrorWidgetBuilder originalErrorWidgetBuilder = ErrorWidget.builder;
  addTearDown(() {
    FlutterError.onError = originalFlutterError;
    ErrorWidget.builder = originalErrorWidgetBuilder;
  });
  app.main();
}

Future<void> launchAndCompleteOnboarding(
  WidgetTester tester, {
  String phone = mvpSystemE2ePhone,
}) async {
  launchMvpSystemApp();
  await loginWithTestPhone(tester, phone: phone);
  await completeOnboardingIfNeeded(tester);
  await waitForHome(tester);
}

Future<void> loginWithTestPhone(
  WidgetTester tester, {
  String phone = mvpSystemE2ePhone,
}) async {
  final Finder phoneMethod = find.byKey(
    const ValueKey<String>('login_phone_method'),
  );
  final Finder homeTab = find.byKey(
    const ValueKey<String>('home_bottom_tab_0'),
  );

  final int startIndex = await pumpUntilAny(tester, <Finder>[
    phoneMethod,
    homeTab,
  ], timeout: const Duration(seconds: 45));
  if (startIndex == 1) {
    return;
  }

  final Finder agreement = find.byKey(
    const ValueKey<String>('login_agreement_checkbox'),
  );
  await scrollUntilFound(tester, agreement, direction: E2eScrollDirection.down);
  await tester.ensureVisible(agreement);
  await tester.tap(agreement);
  await tester.pump(const Duration(milliseconds: 200));

  await scrollUntilFound(tester, phoneMethod, direction: E2eScrollDirection.up);
  await tapAndPump(tester, phoneMethod);

  final Finder phoneInput = find.byKey(
    const ValueKey<String>('login_phone_input'),
  );
  final Finder testSubmit = find.byKey(
    const ValueKey<String>('login_test_phone_submit'),
  );
  await pumpUntilFound(tester, testSubmit);
  await tester.enterText(phoneInput, phone);
  await tester.tap(testSubmit);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> completeOnboardingIfNeeded(WidgetTester tester) async {
  await waitForLoggedInSession(tester);
  final Finder onboardingBrand = find.text('SpeakEasy 首评');
  final Finder homeTab = find.byKey(
    const ValueKey<String>('home_bottom_tab_0'),
  );
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 30));
  bool sawHome = false;

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (onboardingBrand.evaluate().isNotEmpty) {
      await completeOnboardingThroughUi(tester);
      return;
    }
    sawHome =
        sawHome ||
        homeTab.evaluate().isNotEmpty ||
        find.text('学习场景').evaluate().isNotEmpty;
  }

  if (sawHome) {
    return;
  }

  fail(
    'Timed out preparing onboarded session; '
    'visibleTexts=${_visibleTextSnapshot()}',
  );
}

Future<void> completeOnboardingThroughUi(WidgetTester tester) async {
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey<String>('onboarding_scene_0')),
  );
  await tapAndPump(
    tester,
    find.byKey(const ValueKey<String>('onboarding_scene_0')),
  );
  await tapAndPump(
    tester,
    find.byKey(const ValueKey<String>('onboarding_primary_action')),
  );

  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey<String>('onboarding_blocker_1')),
  );
  await tapAndPump(
    tester,
    find.byKey(const ValueKey<String>('onboarding_blocker_1')),
  );
  await tapAndPump(
    tester,
    find.byKey(const ValueKey<String>('onboarding_primary_action')),
  );

  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey<String>('onboarding_diagnostic_0')),
  );
  await tapAndPump(
    tester,
    find.byKey(const ValueKey<String>('onboarding_diagnostic_0')),
  );
  await tapAndPump(
    tester,
    find.byKey(const ValueKey<String>('onboarding_primary_action')),
  );

  await pumpUntilFound(tester, find.text('每天练多久'));
  await tapAndPump(
    tester,
    find.byKey(const ValueKey<String>('onboarding_primary_action')),
  );
  await tester.pump(const Duration(seconds: 1));
}

Future<void> prepareDefaultLearningRouteFixture() async {
  await InterviewWikiStore(
    sceneId: 'job_interview',
  ).saveSelectedTargetLevel('beginner');
  await StorageService.instance.saveInterviewHomeSceneSelection(
    const InterviewHomeSceneSelectionStorageModel(
      selectedSceneIds: <String>['job_interview'],
      activeSceneId: 'job_interview',
    ),
  );
}

Future<AppSession> waitForLoggedInSession(WidgetTester tester) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    final Finder scopeFinder = find.byType(AppSessionScope);
    if (scopeFinder.evaluate().isEmpty) {
      continue;
    }
    final AppSessionScope scope = tester.widget<AppSessionScope>(
      scopeFinder.first,
    );
    final AppSession? session = scope.notifier;
    if (session != null && session.isLoggedIn) {
      return session;
    }
  }
  fail(
    'Timed out waiting for authenticated AppSession; '
    'visibleTexts=${_visibleTextSnapshot()}',
  );
}

Future<bool> waitForOnboardingOrSettledHome(WidgetTester tester) async {
  final Finder onboardingTitle = find.text('先选最需要突破的英语场景');
  final Finder onboardingBrand = find.text('SpeakEasy 首评');
  final Finder homeTab = find.byKey(
    const ValueKey<String>('home_bottom_tab_0'),
  );
  final DateTime startedAt = DateTime.now();
  final DateTime deadline = startedAt.add(const Duration(seconds: 45));

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (onboardingTitle.evaluate().isNotEmpty) {
      return true;
    }
    final bool homeVisible =
        homeTab.evaluate().isNotEmpty ||
        find.text('学习场景').evaluate().isNotEmpty;
    final bool onboardingVisible = onboardingBrand.evaluate().isNotEmpty;
    final bool waitedForRouteDecision =
        DateTime.now().difference(startedAt) >= const Duration(seconds: 6);
    if (waitedForRouteDecision && homeVisible && !onboardingVisible) {
      return false;
    }
  }

  fail(
    'Timed out waiting for onboarding or settled home; '
    'visibleTexts=${_visibleTextSnapshot()}',
  );
}

Future<void> waitForHome(WidgetTester tester) async {
  final Finder homeTab = find.byKey(
    const ValueKey<String>('home_bottom_tab_0'),
  );
  final Finder homeTitle = find.text('学习场景');
  final Finder onboardingBrand = find.text('SpeakEasy 首评');
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    final bool homeVisible =
        homeTab.evaluate().isNotEmpty || homeTitle.evaluate().isNotEmpty;
    if (homeVisible && onboardingBrand.evaluate().isEmpty) {
      return;
    }
  }
  fail(
    'Timed out waiting for settled home; '
    'visibleTexts=${_visibleTextSnapshot()}',
  );
}

Future<void> completeOnboardingThroughSessionIfStillNeeded(
  WidgetTester tester,
) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find
            .byKey(const ValueKey<String>('home_bottom_tab_0'))
            .evaluate()
            .isNotEmpty ||
        find.text('学习场景').evaluate().isNotEmpty) {
      return;
    }
  }

  final Finder onboardingPage = find.byType(OnboardingPage);
  if (onboardingPage.evaluate().isEmpty) {
    return;
  }
  final Finder sessionScopeFinder = find.byType(AppSessionScope);
  if (sessionScopeFinder.evaluate().isEmpty) {
    return;
  }
  final AppSessionScope sessionScope = tester.widget<AppSessionScope>(
    sessionScopeFinder.first,
  );
  final AppSession? session = sessionScope.notifier;
  if (session == null) {
    return;
  }
  await session.completeOnboarding(
    goals: const <String>['E2E fallback onboarding completion'],
    level: 1,
    dailyMinutes: 15,
  );
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> tapBottomTab(WidgetTester tester, int index) async {
  final Finder tab = find.byKey(ValueKey<String>('home_bottom_tab_$index'));
  await pumpUntilFound(tester, tab);
  await tapAndPump(tester, tab);
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  await pumpUntilAny(tester, <Finder>[finder], timeout: timeout);
}

Future<int> pumpUntilAny(
  WidgetTester tester,
  List<Finder> finders, {
  required Duration timeout,
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    for (int index = 0; index < finders.length; index += 1) {
      if (finders[index].evaluate().isNotEmpty) {
        return index;
      }
    }
  }

  final String labels = finders
      .map((Finder finder) => finder.describeMatch(Plurality.many))
      .join(', ');
  fail(
    'Timed out waiting for any finder: $labels; '
    'visibleTexts=${_visibleTextSnapshot()}',
  );
}

Future<void> scrollUntilFound(
  WidgetTester tester,
  Finder finder, {
  required E2eScrollDirection direction,
  Finder? scrollable,
  Duration timeout = const Duration(seconds: 12),
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  final Offset delta = direction == E2eScrollDirection.down
      ? const Offset(0, -260)
      : const Offset(0, 260);

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty && _isFinderInViewport(tester, finder)) {
      return;
    }
    final Finder? targetScrollable =
        scrollable != null && scrollable.evaluate().isNotEmpty
        ? scrollable
        : null;
    if (targetScrollable == null) {
      await tester.dragFrom(_scrollGestureStart(tester), delta);
    } else {
      await tester.drag(targetScrollable.first, delta);
    }
    await tester.pump(const Duration(milliseconds: 250));
  }

  fail(_scrollTimeoutMessage(tester, finder, scrollable));
}

Future<void> tapOnboardingPrimaryAction(WidgetTester tester) {
  final Finder enterPath = find.text('进入学习路径').hitTestable();
  if (enterPath.evaluate().isNotEmpty) {
    return tapAndPump(tester, enterPath);
  }
  return tapAndPump(tester, find.text('继续').hitTestable());
}

Future<void> tapAndPump(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _nudgeFinderIntoViewport(tester, finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> tapViewportFraction(WidgetTester tester, Offset fraction) async {
  final Size viewport = _viewportSize(tester);
  await tester.tapAt(
    Offset(viewport.width * fraction.dx, viewport.height * fraction.dy),
  );
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _nudgeFinderIntoViewport(
  WidgetTester tester,
  Finder finder,
) async {
  for (int attempt = 0; attempt < 12; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    if (_isFinderInViewport(tester, finder)) {
      return;
    }
    if (finder.evaluate().isEmpty) {
      return;
    }
    final Rect rect = tester.getRect(finder);
    final Size viewport = _viewportSize(tester);
    final Offset delta = rect.center.dy > viewport.height
        ? const Offset(0, -220)
        : const Offset(0, 220);
    await tester.dragFrom(_scrollGestureStart(tester), delta);
  }
}

bool _isFinderInViewport(WidgetTester tester, Finder finder) {
  if (finder.evaluate().isEmpty) {
    return false;
  }
  try {
    final Rect rect = tester.getRect(finder);
    final Size viewport = _viewportSize(tester);
    final Rect screen = Offset.zero & viewport;
    return screen.contains(rect.center);
  } catch (_) {
    return false;
  }
}

Size _viewportSize(WidgetTester tester) {
  return tester.view.physicalSize / tester.view.devicePixelRatio;
}

Offset _scrollGestureStart(WidgetTester tester) {
  final Size viewport = _viewportSize(tester);
  return Offset(viewport.width / 2, viewport.height * 0.74);
}

String _scrollTimeoutMessage(
  WidgetTester tester,
  Finder finder,
  Finder? scrollable,
) {
  final int finderCount = finder.evaluate().length;
  final int scrollableCount = scrollable?.evaluate().length ?? 0;
  String rectText = 'n/a';
  if (finderCount > 0) {
    try {
      rectText = tester.getRect(finder).toString();
    } catch (error) {
      rectText = 'unavailable: $error';
    }
  }
  return 'Timed out scrolling for finder: ${finder.describeMatch(Plurality.many)}; '
      'finderCount=$finderCount; rect=$rectText; '
      'scrollableCount=$scrollableCount';
}

String _visibleTextSnapshot() {
  final List<String> texts = find
      .byType(Text)
      .evaluate()
      .map((Element element) {
        final Text widget = element.widget as Text;
        return (widget.data ?? widget.textSpan?.toPlainText() ?? '').trim();
      })
      .where((String value) => value.isNotEmpty)
      .take(40)
      .toList(growable: false);
  return texts.join(' | ');
}
