import 'dart:async';

import 'package:flutter/material.dart';

import 'package:speakeasy/config/app_config.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';

import 'course_detail_page.dart';

typedef CourseSummarySelection =
    void Function(String courseId, String courseVersionId);

class ContentCatalogPage extends StatefulWidget {
  const ContentCatalogPage({
    super.key,
    required this.api,
    required this.onReauthenticate,
    this.onCourseSelected,
    this.enableCourseDetail,
    this.detailObserver = logCourseDetailObservation,
  });

  final CourseCatalogApi api;
  final Future<void> Function() onReauthenticate;
  final CourseSummarySelection? onCourseSelected;
  final bool? enableCourseDetail;
  final CourseDetailObserver detailObserver;

  @override
  State<ContentCatalogPage> createState() => _ContentCatalogPageState();
}

class _ContentCatalogPageState extends State<ContentCatalogPage> {
  final FocusNode _contentRegionFocusNode = FocusNode(
    debugLabel: 'content catalog updated region',
  );
  List<ScenarioSummary>? _themes;
  ContentApiFailure? _failure;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _contentRegionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    await _load();
    if (mounted) {
      _contentRegionFocusNode.requestFocus();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final ScenarioListResponse response = await widget.api
          .listContentThemes();
      if (!mounted) {
        return;
      }
      setState(() {
        _themes = response.scenarios;
        _loading = false;
      });
    } on ContentApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() {
        _failure = failure;
        _loading = false;
        if (failure.kind == ContentApiFailureKind.unauthenticated ||
            failure.kind == ContentApiFailureKind.notFound) {
          _themes = null;
        }
      });
    }
  }

  void _openTheme(ScenarioSummary theme) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ScenarioCourseListPage(
          api: widget.api,
          theme: theme,
          onReauthenticate: widget.onReauthenticate,
          onCourseSelected: widget.onCourseSelected,
          enableCourseDetail:
              widget.enableCourseDetail ?? AppConfig.enableContentCourseDetail,
          detailObserver: widget.detailObserver,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool refreshAllowed =
        _failure?.kind != ContentApiFailureKind.notFound &&
        _failure?.kind != ContentApiFailureKind.unauthenticated;
    return Scaffold(
      key: const ValueKey<String>('content_asset_entry'),
      appBar: AppBar(
        title: const Text('官方内容'),
        actions: <Widget>[
          if (refreshAllowed)
            IconButton(
              key: const ValueKey<String>('content_catalog_refresh'),
              tooltip: '刷新内容主题',
              onPressed: _loading ? null : () => unawaited(_load()),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  '选择场景主题',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              const Text('浏览全部可见的官方主题，再比较主题中的课程方向。'),
              const SizedBox(height: 16),
              Expanded(
                child: Focus(
                  key: const ValueKey<String>('content_catalog_focus'),
                  focusNode: _contentRegionFocusNode,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final List<ScenarioSummary>? themes = _themes;
    if (_loading && themes == null) {
      return const _CatalogStatus(
        key: ValueKey<String>('content_catalog_loading'),
        message: '正在加载内容主题',
        loading: true,
      );
    }
    final ContentApiFailure? failure = _failure;
    if (failure != null && themes == null) {
      return _CatalogFailure(
        failure: failure,
        errorKey: 'content_catalog_error',
        retryKey: 'content_catalog_retry',
        onRetry: _retry,
        onReauthenticate: widget.onReauthenticate,
      );
    }
    if (themes == null || themes.isEmpty) {
      return const _CatalogStatus(
        key: ValueKey<String>('content_catalog_empty'),
        message: '暂时没有可浏览的官方主题',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_loading) const LinearProgressIndicator(),
        if (failure != null)
          _KnownContextFailure(
            message: '内容主题暂时无法刷新，请重试',
            errorKey: 'content_catalog_error',
            retryKey: 'content_catalog_retry',
            onRetry: _retry,
          ),
        Semantics(liveRegion: true, child: Text('共 ${themes.length} 个主题')),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            key: const ValueKey<String>('content_theme_catalog'),
            itemCount: themes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final ScenarioSummary theme = themes[index];
              return KeyedSubtree(
                key: ValueKey<String>(
                  'theme_card:${theme.scenarioId.wireValue}',
                ),
                child: Card(
                  key: const ValueKey<String>('theme_card'),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    title: Text(theme.title),
                    subtitle: Text(
                      <String>[
                        if ((theme.summary ?? '').trim().isNotEmpty)
                          theme.summary!.trim(),
                        if ((theme.levels ?? const <LevelCode>[]).isNotEmpty)
                          theme.levels!
                              .map((LevelCode level) => level.wireValue)
                              .join(' · '),
                        if (!theme.access.allowed) '当前账号暂不可访问',
                      ].join('\n'),
                    ),
                    trailing: theme.access.allowed
                        ? const Icon(Icons.chevron_right)
                        : const Icon(Icons.lock_outline),
                    onTap: theme.access.allowed
                        ? () => _openTheme(theme)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ScenarioCourseListPage extends StatefulWidget {
  const ScenarioCourseListPage({
    super.key,
    required this.api,
    required this.theme,
    required this.onReauthenticate,
    required this.enableCourseDetail,
    required this.detailObserver,
    this.onCourseSelected,
  });

  final CourseCatalogApi api;
  final ScenarioSummary theme;
  final Future<void> Function() onReauthenticate;
  final bool enableCourseDetail;
  final CourseDetailObserver detailObserver;
  final CourseSummarySelection? onCourseSelected;

  @override
  State<ScenarioCourseListPage> createState() => _ScenarioCourseListPageState();
}

class _ScenarioCourseListPageState extends State<ScenarioCourseListPage> {
  final FocusNode _courseRegionFocusNode = FocusNode(
    debugLabel: 'course list updated region',
  );
  final Map<String, FocusNode> _courseCardFocusNodes = <String, FocusNode>{};
  List<CourseSummary>? _courses;
  ContentApiFailure? _failure;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _courseRegionFocusNode.dispose();
    for (final FocusNode focusNode in _courseCardFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _courseKey(CourseSummary course) =>
      '${course.courseId}:${course.courseVersionId}';

  FocusNode _courseFocusNode(CourseSummary course) {
    final String key = _courseKey(course);
    return _courseCardFocusNodes.putIfAbsent(
      key,
      () => FocusNode(debugLabel: 'course card $key'),
    );
  }

  Future<void> _retry() async {
    await _load();
    if (mounted) {
      _courseRegionFocusNode.requestFocus();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final CourseListResponse response = await widget.api.listScenarioCourses(
        widget.theme.scenarioId,
      );
      if (!mounted) {
        return;
      }
      if (response.scenarioId != widget.theme.scenarioId) {
        throw const ContentApiFailure(
          kind: ContentApiFailureKind.invalidResponse,
          message: '课程响应与所选主题不一致',
        );
      }
      setState(() {
        _courses = response.courses;
        _loading = false;
      });
    } on ContentApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() {
        _failure = failure;
        _loading = false;
        if (failure.kind == ContentApiFailureKind.unauthenticated ||
            failure.kind == ContentApiFailureKind.notFound) {
          _courses = null;
        }
      });
    }
  }

  Future<void> _openCourse(CourseSummary course) async {
    final FocusNode courseFocusNode = _courseFocusNode(course);
    final CourseSummarySelection? onCourseSelected = widget.onCourseSelected;
    if (onCourseSelected != null) {
      onCourseSelected(course.courseId, course.courseVersionId);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CourseDetailPage(
          api: widget.api,
          sourceCourse: course,
          onReauthenticate: widget.onReauthenticate,
          observer: widget.detailObserver,
        ),
      ),
    );
    if (mounted) {
      courseFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool refreshAllowed =
        _failure?.kind != ContentApiFailureKind.notFound &&
        _failure?.kind != ContentApiFailureKind.unauthenticated;
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程目录'),
        actions: <Widget>[
          if (refreshAllowed)
            IconButton(
              key: const ValueKey<String>('course_list_refresh'),
              tooltip: '刷新课程',
              onPressed: _loading ? null : () => unawaited(_load()),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          key: const ValueKey<String>('selected_theme_course_summaries'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  widget.theme.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if ((widget.theme.summary ?? '').trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(widget.theme.summary!.trim()),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: Focus(
                  key: const ValueKey<String>('course_list_focus'),
                  focusNode: _courseRegionFocusNode,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final List<CourseSummary>? courses = _courses;
    if (_loading && courses == null) {
      return const _CatalogStatus(
        key: ValueKey<String>('course_list_loading'),
        message: '正在加载课程',
        loading: true,
      );
    }
    final ContentApiFailure? failure = _failure;
    if (failure != null && courses == null) {
      return _CatalogFailure(
        failure: failure,
        errorKey: 'course_list_error',
        retryKey: 'course_list_retry',
        onRetry: _retry,
        onReauthenticate: widget.onReauthenticate,
      );
    }
    if (courses == null || courses.isEmpty) {
      return const _CatalogStatus(
        key: ValueKey<String>('course_list_empty'),
        message: '该主题暂时没有可浏览的课程',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_loading) const LinearProgressIndicator(),
        if (failure != null)
          _KnownContextFailure(
            message: '课程暂时无法刷新，请重试',
            errorKey: 'course_list_error',
            retryKey: 'course_list_retry',
            onRetry: _retry,
          ),
        Semantics(liveRegion: true, child: Text('共 ${courses.length} 门课程')),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            key: const ValueKey<String>('course_summary_list'),
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final CourseSummary course = courses[index];
              return KeyedSubtree(
                key: ValueKey<String>(
                  'course_summary_card:${course.courseId}:${course.courseVersionId}',
                ),
                child: Card(
                  key: const ValueKey<String>('course_summary_card'),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const ValueKey<String>('course_card'),
                    focusNode: _courseFocusNode(course),
                    onTap: widget.enableCourseDetail
                        ? () => unawaited(_openCourse(course))
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            course.titleEn,
                            key: const ValueKey<String>(
                              'course_summary_title_en',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            course.summaryZh,
                            key: const ValueKey<String>('course_summary_zh'),
                          ),
                          const SizedBox(height: 12),
                          Chip(
                            key: const ValueKey<String>(
                              'course_summary_level_code',
                            ),
                            label: Text(course.levelCode.wireValue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CatalogFailure extends StatelessWidget {
  const _CatalogFailure({
    required this.failure,
    required this.errorKey,
    required this.retryKey,
    required this.onRetry,
    required this.onReauthenticate,
  });

  final ContentApiFailure failure;
  final String errorKey;
  final String retryKey;
  final Future<void> Function() onRetry;
  final Future<void> Function() onReauthenticate;

  @override
  Widget build(BuildContext context) {
    final bool unauthenticated =
        failure.kind == ContentApiFailureKind.unauthenticated;
    final bool notFound = failure.kind == ContentApiFailureKind.notFound;
    final String message = unauthenticated
        ? '登录状态已失效，请重新登录'
        : notFound
        ? '内容暂不可用'
        : '内容暂时无法加载，请重试';
    return _CatalogStatus(
      key: ValueKey<String>(errorKey),
      message: message,
      action: notFound
          ? null
          : TextButton(
              key: ValueKey<String>(
                unauthenticated ? 'content_reauthenticate' : retryKey,
              ),
              onPressed: unauthenticated
                  ? () => unawaited(onReauthenticate())
                  : () => unawaited(onRetry()),
              child: Text(unauthenticated ? '重新登录' : '重试'),
            ),
    );
  }
}

class _KnownContextFailure extends StatelessWidget {
  const _KnownContextFailure({
    required this.message,
    required this.errorKey,
    required this.retryKey,
    required this.onRetry,
  });

  final String message;
  final String errorKey;
  final String retryKey;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: MaterialBanner(
        key: ValueKey<String>(errorKey),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            key: ValueKey<String>(retryKey),
            onPressed: () => unawaited(onRetry()),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _CatalogStatus extends StatelessWidget {
  const _CatalogStatus({
    super.key,
    required this.message,
    this.loading = false,
    this.action,
  });

  final String message;
  final bool loading;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (loading) const CircularProgressIndicator(),
            if (loading) const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...<Widget>[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
