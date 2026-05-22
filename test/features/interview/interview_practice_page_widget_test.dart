import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeasy/features/interview/interview_llm_scheduler.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/features/interview/interview_practice_page.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/storage_service.dart';

class _FakeInterviewLlmScheduler extends InterviewLlmScheduler {
  @override
  Future<String?> generateOpeningQuestion({
    required InterviewPracticeSession session,
    required InterviewQuestionPlan plan,
    InterviewWikiMemoryPack? memoryPack,
  }) async {
    return null;
  }

  @override
  Future<String?> adaptNextQuestion({
    required InterviewPracticeSession session,
    required InterviewQuestionPlan plan,
    required String userText,
    required List<InterviewChatMessage> messages,
    InterviewWikiMemoryPack? memoryPack,
  }) async {
    return null;
  }

  @override
  Future<String?> generateContextualHint({
    required InterviewPracticeSession session,
    required String question,
    required String answerFocus,
    required String learnerDraft,
    required InterviewExpression targetExpression,
    required List<InterviewChatMessage> messages,
    InterviewWikiMemoryPack? memoryPack,
  }) async {
    return '''
可以用：${targetExpression.text}
可以这样答：Try starting with: '${targetExpression.text}'
''';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp(
      'speakeasy_interview_widget_test_',
    );
    await StorageService.instance.init(hivePath: hiveDir.path);
    await StorageService.instance.remove('interview_personal_wiki_expressions');
    await StorageService.instance.remove('interview_compiled_wiki');
    await StorageService.instance.remove('interview_user_growth_wiki');
    await StorageService.instance.remove('interview_dismissed_wiki_items');
    await StorageService.instance.remove('interview_useful_wiki_items');
  });

  tearDown(() async {
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  Future<void> pumpInterviewPage(
    WidgetTester tester, {
    String targetLevel = 'beginner',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AudioServiceScope(
          service: AudioService(),
          child: AppSessionScope(
            session: AppSession(),
            child: InterviewPracticePage(
              targetLevel: targetLevel,
              llmScheduler: _FakeInterviewLlmScheduler(),
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 60; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('点击说话').evaluate().isNotEmpty ||
          find.textContaining('面试功能加载失败').evaluate().isNotEmpty) {
        break;
      }
    }
    final Object? exception = tester.takeException();
    if (exception != null) {
      fail('Interview page threw during bootstrap: $exception');
    }
    final Iterable<Text> errorTexts = tester.widgetList<Text>(
      find.textContaining('面试功能加载失败'),
    );
    if (errorTexts.isNotEmpty) {
      fail('Interview page failed to bootstrap: ${errorTexts.first.data}');
    }
    if (find.text('点击说话').evaluate().isEmpty) {
      final Iterable<String> visibleTexts = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text widget) => widget.data ?? widget.textSpan?.toPlainText())
          .whereType<String>();
      fail(
        'Interview page did not finish bootstrap. Visible text: '
        '${visibleTexts.join(' | ')}',
      );
    }
  }

  testWidgets('default interview UI uses compact composer', (
    WidgetTester tester,
  ) async {
    await pumpInterviewPage(tester);

    expect(
      find.byKey(const ValueKey<String>('interview_scene_map_menu_button')),
      findsOneWidget,
    );
    expect(find.text('点击说话'), findsOneWidget);
    expect(find.text('内容由 AI 生成'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('interview_voice_start_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('interview_hint_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('interview_target_progress_band')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.textContaining('AI Mock Interview'), findsNothing);
    expect(find.textContaining('本轮目标：'), findsNothing);
  });

  testWidgets('scene title opens current scene map', (
    WidgetTester tester,
  ) async {
    await pumpInterviewPage(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('interview_scene_map_menu_button')),
    );
    for (int i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('interview_scene_map_page'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(
      find.byKey(const ValueKey<String>('interview_scene_map_page')),
      findsOneWidget,
    );
    expect(find.text('场景导航'), findsWidgets);
    expect(find.text('英语面试 · 13 个表达'), findsOneWidget);
    expect(find.text('英语面试'), findsOneWidget);
    expect(find.textContaining('L2 进阶'), findsNothing);
    expect(find.textContaining('L3 精通'), findsNothing);
    expect(find.textContaining('本轮待练'), findsWidgets);
  });

  testWidgets('scene navigation only shows selected difficulty expressions', (
    WidgetTester tester,
  ) async {
    await pumpInterviewPage(tester, targetLevel: 'advanced');

    await tester.tap(
      find.byKey(const ValueKey<String>('interview_scene_map_menu_button')),
    );
    for (int i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('interview_scene_map_page'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.text('英语面试 · 13 个表达'), findsOneWidget);
    expect(
      find.textContaining('I really appreciate you making the time'),
      findsWidgets,
    );
    expect(find.textContaining('Thank you for having me'), findsNothing);
    expect(find.textContaining('L1 入门'), findsNothing);
    expect(find.textContaining('L2 进阶'), findsNothing);
  });

  testWidgets('scene navigation level switch updates dialogue level', (
    WidgetTester tester,
  ) async {
    await pumpInterviewPage(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('interview_scene_map_menu_button')),
    );
    for (int i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('interview_scene_map_page'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Thank you for having me.'), findsWidgets);
    expect(find.textContaining('Thank you for making the time.'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('scene_map_level_dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('scene_map_level_intermediate')),
    );
    for (int i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('L2 进阶').evaluate().isNotEmpty &&
          find
              .byKey(const ValueKey<String>('interview_scene_map_page'))
              .evaluate()
              .isEmpty) {
        break;
      }
    }

    expect(
      find.byKey(const ValueKey<String>('interview_scene_map_page')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('interview_scene_map_menu_button')),
    );
    for (int i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('interview_scene_map_page'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('英语面试 · 13 个表达'), findsOneWidget);
    expect(find.textContaining('Thank you for making the time.'), findsWidgets);
    expect(find.textContaining('Thank you for having me.'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('scene_map_level_dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('scene_map_level_advanced')),
    );
    for (int i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('interview_scene_map_page'))
          .evaluate()
          .isEmpty) {
        break;
      }
    }

    expect(
      find.byKey(const ValueKey<String>('interview_scene_map_page')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('interview_scene_map_menu_button')),
    );
    for (int i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('interview_scene_map_page'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.text('英语面试 · 13 个表达'), findsOneWidget);
    expect(
      find.textContaining('I really appreciate you making the time'),
      findsWidgets,
    );
    expect(find.textContaining('Thank you for making the time.'), findsNothing);
  });

  testWidgets('composer uses hint button without review or swipe controls', (
    WidgetTester tester,
  ) async {
    await pumpInterviewPage(tester);

    expect(find.byTooltip('关闭自动朗读'), findsNothing);
    expect(find.byTooltip('打开自动朗读'), findsNothing);
    expect(find.text('结束复盘'), findsNothing);
    expect(find.text('我卡住了'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('interview_hint_button')),
      findsOneWidget,
    );

    expect(find.text('点击说话'), findsOneWidget);
    expect(find.text('按住说话'), findsNothing);
    expect(find.text('松开发送，上滑取消'), findsNothing);
    expect(find.text('提示阶梯'), findsNothing);
    expect(find.text('完整个人 Wiki'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('interview_hint_remaining_badge'),
        ),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('hint button advances through compact hint levels', (
    WidgetTester tester,
  ) async {
    await pumpInterviewPage(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('interview_hint_button')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('面试官问'), findsNothing);
    expect(find.textContaining('提示：'), findsOneWidget);
    expect(find.textContaining('L1 轻提示 已折叠'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('interview_hint_remaining_badge'),
        ),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('interview_hint_button')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('面试官问'), findsNothing);
    expect(find.textContaining('L1 轻提示 已折叠'), findsNothing);
    expect(find.textContaining('提示：'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('interview_hint_remaining_badge'),
        ),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('L4 stuck hint shows a concise direct answer', (
    WidgetTester tester,
  ) async {
    await pumpInterviewPage(tester);

    for (int i = 0; i < 4; i += 1) {
      await tester.tap(
        find.byKey(const ValueKey<String>('interview_hint_button')),
      );
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('L4 完整回答'), findsWidgets);
    expect(find.textContaining('可以这样答：Try starting with'), findsNothing);
    expect(find.textContaining('可以这样答：可以用'), findsNothing);
    expect(find.textContaining('可用表达：'), findsNothing);
    expect(
      find.textContaining(
        "可以这样答：Thank you for having me. I'm excited to be here today.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('scene navigation target tap jumps to that interview stage', (
    WidgetTester tester,
  ) async {
    await pumpInterviewPage(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('interview_scene_map_menu_button')),
    );
    for (int i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('interview_scene_map_page'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    final Finder targetExpression = find.textContaining(
      "I'm currently working as a designer at a growing company.",
    );
    await tester.ensureVisible(targetExpression);
    await tester.pumpAndSettle();
    await tester.tap(targetExpression);
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Could you start by telling me what you currently do',
      ),
      findsOneWidget,
    );
  });
}
