#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

import 'package:speakeasy/features/interview/interview_training_agent.dart';

const Set<String> _requiredCaseIds = <String>{
  'AI-EVAL-P01-001',
  'AI-EVAL-P01-002',
  'AI-EVAL-P01-003',
  'AI-EVAL-P01-004',
  'AI-EVAL-P01-005',
  'AI-EVAL-P01-006',
  'AI-EVAL-P01-007',
};

const Set<String> _bannedOutputFields = <String>{
  'accepted',
  'mastered',
  'review_scheduled',
  'entitled',
  'billing_state',
  'entitlement',
  'member_plan',
  'subscription_status',
};

void main(List<String> args) {
  final String casesPath = _optionValue(
    args,
    '--cases',
    'tests/ai_runtime/p0_1_ai_eval_cases.json',
  );
  final String docsPath = _optionValue(
    args,
    '--docs',
    'docs/ai_runtime/ai_eval_cases.md',
  );
  final List<String> errors = <String>[];

  final File casesFile = File(casesPath);
  if (!casesFile.existsSync()) {
    _fail(<String>['missing AI eval case fixture: $casesPath']);
  }

  final Map<String, dynamic> suite = _decodeObject(
    casesFile.readAsStringSync(),
    casesPath,
  );
  if (suite['schema_version'] != 1) {
    errors.add('suite schema_version must be 1');
  }
  if (suite['suite_id'] != 'TC-P01-014') {
    errors.add('suite_id must be TC-P01-014');
  }

  final List<dynamic> rawCases = suite['cases'] is List
      ? suite['cases'] as List<dynamic>
      : const <dynamic>[];
  final Set<String> seenIds = <String>{};
  for (final dynamic rawCase in rawCases) {
    final Map<String, dynamic> evalCase = _asMap(rawCase);
    final String caseId = _string(evalCase['id']);
    if (caseId.isEmpty) {
      errors.add('case id is required');
      continue;
    }
    if (!seenIds.add(caseId)) {
      errors.add('$caseId: duplicate case id');
      continue;
    }
    _validateCase(evalCase, errors);
  }

  for (final String requiredId in _requiredCaseIds) {
    if (!seenIds.contains(requiredId)) {
      errors.add('missing required P0.1 AI eval case: $requiredId');
    }
  }
  for (final String seenId in seenIds) {
    if (seenId.startsWith('AI-EVAL-P01-') &&
        !_requiredCaseIds.contains(seenId)) {
      errors.add('unexpected P0.1 AI eval case: $seenId');
    }
  }

  final File docsFile = File(docsPath);
  if (!docsFile.existsSync()) {
    errors.add('missing AI eval documentation: $docsPath');
  } else {
    final String docs = docsFile.readAsStringSync();
    for (final String requiredId in _requiredCaseIds) {
      if (!docs.contains(requiredId)) {
        errors.add('docs missing AI eval case id: $requiredId');
      }
    }
    if (!docs.contains('dart run scripts/check_ai_eval_cases.dart')) {
      errors.add('docs missing executable validator command');
    }
  }

  if (errors.isNotEmpty) {
    _fail(errors);
  }
  stdout.writeln('AI eval cases check passed: ${seenIds.length} cases');
}

void _validateCase(Map<String, dynamic> evalCase, List<String> errors) {
  final String caseId = _string(evalCase['id']);
  final Map<String, dynamic> candidate = _asMap(evalCase['candidate']);
  final Map<String, dynamic> expected = _asMap(evalCase['expected']);
  final bool expectedValid = expected['valid'] == true;
  final InterviewTrainingNextActionType? plannerNextAction = _plannerNextAction(
    evalCase['planner_next_action'],
  );
  if (evalCase.containsKey('planner_next_action') &&
      plannerNextAction == null) {
    errors.add('$caseId: planner_next_action is not allowed');
  }

  final InterviewTrainingFeedbackValidationResult validation =
      InterviewTrainingFeedbackCandidate.validateJson(
        candidate,
        plannerNextAction: plannerNextAction,
      );
  if (validation.isValid != expectedValid) {
    errors.add(
      '$caseId: expected valid=$expectedValid but got '
      '${validation.isValid}; errors=${validation.errors.join(", ")}',
    );
  }

  final List<String> expectedErrors = _stringList(expected['errors_contain']);
  for (final String expectedError in expectedErrors) {
    if (!validation.errors.contains(expectedError)) {
      errors.add(
        '$caseId: expected validation error "$expectedError"; '
        'actual=${validation.errors.join(", ")}',
      );
    }
  }

  if (expectedValid && validation.isValid) {
    _validateAcceptedCandidate(caseId, candidate, expected, errors);
  }

  if (expected['fallback_valid'] == true) {
    final Map<String, dynamic> fallback = _asMap(
      evalCase['fallback_candidate'],
    );
    final InterviewTrainingNextActionType? fallbackPlanner = _plannerNextAction(
      _firstString(expected['fallback_next_action_type_in']),
    );
    final InterviewTrainingFeedbackValidationResult fallbackValidation =
        InterviewTrainingFeedbackCandidate.validateJson(
          fallback,
          plannerNextAction: fallbackPlanner,
        );
    if (!fallbackValidation.isValid) {
      errors.add(
        '$caseId: fallback_candidate must be valid; '
        'errors=${fallbackValidation.errors.join(", ")}',
      );
    } else {
      _validateAcceptedCandidate(
        '$caseId fallback',
        fallback,
        <String, dynamic>{
          'next_action_type_in': expected['fallback_next_action_type_in'],
          'recoverable_error': expected['fallback_recoverable_error'],
          'forbidden_output_fields_absent': true,
        },
        errors,
      );
    }
  }

  final bool? expectForbiddenAbsent =
      expected['forbidden_output_fields_absent'] is bool
      ? expected['forbidden_output_fields_absent'] as bool
      : null;
  if (expectForbiddenAbsent != null) {
    final bool hasBanned = _containsBannedOutputField(candidate);
    if (expectForbiddenAbsent && hasBanned) {
      errors.add('$caseId: candidate contains prohibited output fields');
    }
    if (!expectForbiddenAbsent && !hasBanned) {
      errors.add('$caseId: expected prohibited output field fixture');
    }
  }
}

void _validateAcceptedCandidate(
  String caseId,
  Map<String, dynamic> candidate,
  Map<String, dynamic> expected,
  List<String> errors,
) {
  late final InterviewTrainingFeedbackCandidate parsed;
  try {
    parsed = InterviewTrainingFeedbackCandidate.fromJson(candidate);
  } on FormatException catch (error) {
    errors.add('$caseId: fromJson failed unexpectedly: ${error.message}');
    return;
  }

  _expectIn(
    caseId,
    'completion_signal.status',
    parsed.completionStatus.key,
    _stringList(expected['completion_status_in']),
    errors,
  );
  _expectIn(
    caseId,
    'task_signal.status',
    parsed.taskStatus.key,
    _stringList(expected['task_status_in']),
    errors,
  );
  _expectIn(
    caseId,
    'feedback_card.main_issue_type',
    parsed.feedbackCard.mainIssueType,
    _stringList(expected['main_issue_type_in']),
    errors,
  );
  _expectIn(
    caseId,
    'recommended_next_action.type',
    parsed.recommendedNextAction.key,
    _stringList(expected['next_action_type_in']),
    errors,
  );

  if (expected['pronunciation_available'] is bool &&
      parsed.pronunciationAvailable !=
          expected['pronunciation_available'] as bool) {
    errors.add('$caseId: pronunciation availability mismatch');
  }
  if (expected['pressure_prompt_enabled'] is bool &&
      parsed.pressurePromptEnabled !=
          expected['pressure_prompt_enabled'] as bool) {
    errors.add('$caseId: pressure prompt enabled mismatch');
  }
  if (expected['recoverable_error'] is bool) {
    final bool hasRecoverableError = parsed.recoverableErrorCode.isNotEmpty;
    if (hasRecoverableError != expected['recoverable_error'] as bool) {
      errors.add('$caseId: recoverable error expectation mismatch');
    }
  }

  final int evidenceCount = parsed.learningEvidenceCandidates.length;
  final int? minEvidence = _intOrNull(expected['evidence_count_min']);
  final int? maxEvidence = _intOrNull(expected['evidence_count_max']);
  if (minEvidence != null && evidenceCount < minEvidence) {
    errors.add('$caseId: expected at least $minEvidence evidence candidates');
  }
  if (maxEvidence != null && evidenceCount > maxEvidence) {
    errors.add('$caseId: expected at most $maxEvidence evidence candidates');
  }

  final String expectedEvidenceStatus = _string(
    expected['all_evidence_status'],
  );
  if (expectedEvidenceStatus.isNotEmpty) {
    for (final InterviewTrainingLearningEvidenceCandidate evidence
        in parsed.learningEvidenceCandidates) {
      if (evidence.status != expectedEvidenceStatus) {
        errors.add('$caseId: evidence status must be $expectedEvidenceStatus');
      }
    }
  }

  if (expected['forbidden_output_fields_absent'] == true &&
      _containsBannedOutputField(candidate)) {
    errors.add('$caseId: accepted candidate contains prohibited output fields');
  }
}

void _expectIn(
  String caseId,
  String field,
  String actual,
  List<String> allowed,
  List<String> errors,
) {
  if (allowed.isEmpty) {
    return;
  }
  if (!allowed.contains(actual)) {
    errors.add('$caseId: $field expected one of $allowed but got "$actual"');
  }
}

InterviewTrainingNextActionType? _plannerNextAction(dynamic value) {
  final String key = _string(value);
  if (key.isEmpty) {
    return null;
  }
  return InterviewTrainingNextActionType.fromKey(key);
}

String _firstString(dynamic value) {
  final List<String> values = _stringList(value);
  return values.isEmpty ? '' : values.first;
}

String _optionValue(List<String> args, String option, String fallback) {
  final int index = args.indexOf(option);
  if (index < 0) {
    return fallback;
  }
  if (index == args.length - 1) {
    _fail(<String>['$option requires a value']);
  }
  return args[index + 1];
}

Map<String, dynamic> _decodeObject(String text, String label) {
  try {
    final dynamic value = jsonDecode(text);
    return _asMap(value);
  } on FormatException catch (error) {
    _fail(<String>['$label is not valid JSON: ${error.message}']);
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic mapValue) =>
          MapEntry<String, dynamic>(key.toString(), mapValue),
    );
  }
  return <String, dynamic>{};
}

List<String> _stringList(dynamic value) {
  if (value is! List) {
    return const <String>[];
  }
  return value.map(_string).where((String item) => item.isNotEmpty).toList();
}

String _string(dynamic value) {
  return value is String ? value.trim() : '';
}

int? _intOrNull(dynamic value) {
  return value is int ? value : null;
}

bool _containsBannedOutputField(dynamic value) {
  if (value is Map) {
    for (final MapEntry<dynamic, dynamic> entry in value.entries) {
      final String key = entry.key.toString().trim();
      if (_bannedOutputFields.contains(key)) {
        return true;
      }
      if (_containsBannedOutputField(entry.value)) {
        return true;
      }
    }
    return false;
  }
  if (value is List) {
    return value.any(_containsBannedOutputField);
  }
  return value is String && _bannedOutputFields.contains(value.trim());
}

Never _fail(List<String> errors) {
  stderr.writeln('AI eval cases check failed:');
  for (final String error in errors) {
    stderr.writeln('- $error');
  }
  exit(1);
}
