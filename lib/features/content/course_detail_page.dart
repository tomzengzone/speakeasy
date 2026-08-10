import 'dart:async';

import 'package:flutter/material.dart';

import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';

class CourseDetailObservation {
  const CourseDetailObservation({
    required this.featureArea,
    required this.resultClass,
    required this.requestId,
    required this.refHash,
    required this.validationResult,
  });

  final String featureArea;
  final String resultClass;
  final String? requestId;
  final String refHash;
  final String validationResult;
}

typedef CourseDetailObserver = void Function(CourseDetailObservation event);

void logCourseDetailObservation(CourseDetailObservation event) {
  debugPrint(
    'content_read feature_area=${event.featureArea} '
    'result_class=${event.resultClass} '
    'request_id=${event.requestId ?? '-'} ref_hash=${event.refHash} '
    'validation_result=${event.validationResult}',
  );
}

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({
    super.key,
    required this.api,
    required this.sourceCourse,
    required this.onReauthenticate,
    this.observer = logCourseDetailObservation,
  });

  final CourseCatalogApi api;
  final CourseSummary sourceCourse;
  final Future<void> Function() onReauthenticate;
  final CourseDetailObserver observer;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final FocusNode _detailHeaderFocusNode = FocusNode(
    debugLabel: 'course detail header',
  );
  final FocusNode _detailErrorFocusNode = FocusNode(
    debugLabel: 'course detail error',
  );
  CourseDetail? _detail;
  ContentApiFailure? _failure;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _detailHeaderFocusNode.dispose();
    _detailErrorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    await _load();
    if (mounted) {
      if (_detail != null && _failure == null) {
        _detailHeaderFocusNode.requestFocus();
      } else {
        _detailErrorFocusNode.requestFocus();
      }
    }
  }

  void _observe(
    String resultClass,
    String? requestId, {
    required String validationResult,
  }) {
    try {
      widget.observer(
        CourseDetailObservation(
          featureArea: 'course_detail',
          resultClass: resultClass,
          requestId: requestId,
          refHash: _courseVersionRefHash(
            widget.sourceCourse.courseId,
            widget.sourceCourse.courseVersionId,
          ),
          validationResult: validationResult,
        ),
      );
    } catch (_) {
      debugPrint(
        'content_read feature_area=course_detail '
        'result_class=observer_failure',
      );
    }
  }

  Future<void> _load() async {
    var validationResult = 'not_evaluated';
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final CourseDetailResponse response = await widget.api
          .getCourseVersionDetail(
            widget.sourceCourse.courseId,
            widget.sourceCourse.courseVersionId,
          );
      if (!_matchesSource(response.course)) {
        validationResult = 'identity_mismatch';
        throw ContentApiFailure(
          kind: ContentApiFailureKind.invalidResponse,
          message: '课程详情与所选课程版本不一致',
          requestId: response.requestId,
        );
      }
      validationResult = 'exact_identity';
      _observe(
        'success',
        response.requestId,
        validationResult: validationResult,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = response.course;
        _loading = false;
      });
    } on ContentApiFailure catch (failure) {
      if (failure.kind == ContentApiFailureKind.invalidResponse &&
          validationResult == 'not_evaluated') {
        validationResult = 'schema_invalid';
      }
      _observe(
        _resultClass(failure.kind),
        failure.requestId,
        validationResult: validationResult,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _failure = failure;
        _loading = false;
        if (failure.kind != ContentApiFailureKind.retryable) {
          _detail = null;
        }
      });
    }
  }

  bool _matchesSource(CourseDetail detail) {
    final CourseSummary source = widget.sourceCourse;
    return detail.courseId == source.courseId &&
        detail.courseVersionId == source.courseVersionId &&
        detail.titleEn == source.titleEn &&
        detail.summaryZh == source.summaryZh &&
        detail.levelCode == source.levelCode &&
        detail.contentBindingRef.courseContentBindingId ==
            source.contentBindingRef.courseContentBindingId &&
        detail.contentBindingRef.scenarioVersionId ==
            source.contentBindingRef.scenarioVersionId &&
        detail.contentBindingRef.scenarioLevelId ==
            source.contentBindingRef.scenarioLevelId;
  }

  @override
  Widget build(BuildContext context) {
    final CourseDetail? detail = _detail;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey<String>('course_detail_back'),
          tooltip: '返回课程目录',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('课程详情'),
        actions: <Widget>[
          if (detail != null)
            IconButton(
              key: const ValueKey<String>('course_detail_refresh'),
              tooltip: '刷新课程信息',
              onPressed: _loading ? null : () => unawaited(_load()),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ExcludeSemantics(
              child: DecoratedBox(
                key: ValueKey<String>(
                  (detail?.backgroundAssetRef ?? '').trim().isEmpty
                      ? 'course_detail_background_placeholder'
                      : 'course_detail_background',
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: (detail?.backgroundAssetRef ?? '').trim().isEmpty
                        ? <Color>[
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.surfaceContainerLow,
                          ]
                        : <Color>[
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.surface,
                          ],
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(20), child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final CourseDetail? detail = _detail;
    if (_loading && detail == null) {
      return const _DetailStatus(
        key: ValueKey<String>('course_detail_loading'),
        message: '正在加载课程信息',
        loading: true,
      );
    }

    final ContentApiFailure? failure = _failure;
    if (detail == null) {
      if (failure?.kind == ContentApiFailureKind.notFound) {
        return const _DetailStatus(
          key: ValueKey<String>('course_detail_unavailable'),
          message: '内容暂不可用',
        );
      }
      if (failure?.kind == ContentApiFailureKind.unauthenticated) {
        return _DetailFailure(
          key: const ValueKey<String>('course_detail_unauthenticated'),
          focusNode: _detailErrorFocusNode,
          message: '登录状态已失效，请重新登录',
          actionKey: 'content_reauthenticate',
          actionLabel: '重新登录',
          onAction: widget.onReauthenticate,
        );
      }
      if (failure != null) {
        return _DetailFailure(
          key: const ValueKey<String>('course_detail_error'),
          focusNode: _detailErrorFocusNode,
          message: '课程信息暂时无法加载，请重试',
          actionKey: failure.kind == ContentApiFailureKind.retryable
              ? 'course_detail_retry'
              : null,
          actionLabel: failure.kind == ContentApiFailureKind.retryable
              ? '重试'
              : null,
          onAction: failure.kind == ContentApiFailureKind.retryable
              ? _retry
              : null,
        );
      }
      return const _DetailStatus(
        key: ValueKey<String>('course_detail_loading'),
        message: '正在加载课程信息',
        loading: true,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_loading) const LinearProgressIndicator(),
          if (failure != null) ...<Widget>[
            _DetailFailure(
              key: const ValueKey<String>('course_detail_error'),
              focusNode: _detailErrorFocusNode,
              message: '课程信息暂时无法刷新，请重试',
              actionKey: 'course_detail_retry',
              actionLabel: '重试',
              onAction: _retry,
            ),
            const SizedBox(height: 16),
          ],
          Focus(
            key: const ValueKey<String>('course_detail_header_focus'),
            focusNode: _detailHeaderFocusNode,
            child: Semantics(
              header: true,
              container: true,
              child: Card(
                key: const ValueKey<String>('course_detail_header'),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        detail.titleEn,
                        key: const ValueKey<String>('course_detail_title_en'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        detail.summaryZh,
                        key: const ValueKey<String>('course_detail_summary_zh'),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          Chip(
                            key: const ValueKey<String>(
                              'course_detail_level_code',
                            ),
                            avatar: const Icon(Icons.school_outlined, size: 18),
                            label: Text(detail.levelCode.wireValue),
                          ),
                          Chip(
                            key: const ValueKey<String>(
                              'course_detail_duration',
                            ),
                            avatar: const Icon(Icons.schedule, size: 18),
                            label: Text(
                              '${_formatNumber(detail.typicalDuration.value)} '
                              '${detail.typicalDuration.unit}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(num value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

String _resultClass(ContentApiFailureKind kind) {
  return switch (kind) {
    ContentApiFailureKind.unauthenticated => 'unauthenticated',
    ContentApiFailureKind.notFound => 'not_found',
    ContentApiFailureKind.retryable => 'retryable',
    ContentApiFailureKind.nonRetryable => 'non_retryable',
    ContentApiFailureKind.invalidResponse => 'invalid_response',
  };
}

String _courseVersionRefHash(String courseId, String courseVersionId) {
  var hash = 0x811c9dc5;
  for (final int unit in '$courseId:$courseVersionId'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

class _DetailFailure extends StatelessWidget {
  const _DetailFailure({
    super.key,
    required this.focusNode,
    required this.message,
    this.actionKey,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final FocusNode focusNode;
  final String? actionKey;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Focus(
      key: const ValueKey<String>('course_detail_error_focus'),
      focusNode: focusNode,
      child: Semantics(
        liveRegion: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message, textAlign: TextAlign.center),
              if (onAction != null && actionKey != null && actionLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton.tonal(
                    key: ValueKey<String>(actionKey!),
                    onPressed: () => unawaited(onAction!()),
                    child: Text(actionLabel!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailStatus extends StatelessWidget {
  const _DetailStatus({super.key, required this.message, this.loading = false});

  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (loading) const CircularProgressIndicator(),
            if (loading) const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
