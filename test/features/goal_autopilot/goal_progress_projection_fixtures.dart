import 'package:speakeasy/features/goal_autopilot/goal_autopilot_models.dart';

Map<String, dynamic> goalProgressProjectionResponseFixture() {
  return <String, dynamic>{
    'schema_version': 1,
    'projection': <String, dynamic>{
      'projection_id': 'projection_id_sample',
      'projection_state': 'ready',
      'downgrade_reason': null,
      'goal': <String, dynamic>{
        'goal_profile_id': 'goal_profile_id_sample',
        'goal_type': 'ielts_speaking',
        'support_status': 'supported',
        'status': 'active',
        'revision': 1,
      },
      'next_action': <String, dynamic>{
        'action_id': 'action_id_sample',
        'plan_item_id': 'plan_item_id_sample',
        'action_type': 'start_training',
        'title': 'Fluency expansion drill',
        'reason_code': 'highest_weakness_and_memory_risk',
        'expected_duration_minutes': 12,
        'status': 'ready',
      },
      'progress': <String, dynamic>{
        'forecast_id': 'forecast_id_sample',
        'forecast_state': 'ready',
        'gap_summary': 'Projection fluency gap from backend.',
        'eta_date': '2099-08-24',
        'eta_unavailable_reason': null,
        'confidence_band': 'medium',
        'risk_level': 'medium',
        'risk_reason_code': 'backend_checkpoint_due',
        'next_checkpoint_date': '2099-06-11',
        'claim_guard': <String, dynamic>{
          'official_score_equivalence': false,
          'goal_completion_claim_allowed': false,
          'allowed_claim': 'product_internal_progress_only',
        },
        'updated_at': '2099-06-05T09:00:00Z',
      },
      'latest_checkpoint': <String, dynamic>{
        'checkpoint_id': 'checkpoint_id_sample',
        'result_status': 'recorded',
        'confidence_band': 'medium',
        'summary': 'Backend checkpoint conclusion only.',
        'plan_update_signal': 'checkpoint_replan',
        'reason_code': 'checkpoint_recorded',
      },
      'surface_fragments': <Map<String, dynamic>>[
        <String, dynamic>{
          'surface': 'home',
          'display_state': 'ready',
          'eligible': true,
          'downgrade_reason': null,
          'next_action_ref': 'plan_item:plan_item_id_sample',
          'forecast_ref': 'forecast:forecast_id_sample',
          'checkpoint_ref': 'checkpoint:checkpoint_id_sample',
          'safe_fields': <String>[
            'next_action',
            'gap_summary',
            'risk_reason_code',
            'next_checkpoint_date',
            'checkpoint_summary',
          ],
        },
        <String, dynamic>{
          'surface': 'queue',
          'display_state': 'ready',
          'eligible': true,
          'downgrade_reason': null,
          'next_action_ref': 'plan_item:plan_item_id_sample',
          'forecast_ref': 'forecast:forecast_id_sample',
          'checkpoint_ref': 'checkpoint:checkpoint_id_sample',
          'safe_fields': <String>[
            'next_action',
            'risk_reason_code',
            'checkpoint_summary',
          ],
        },
        <String, dynamic>{
          'surface': 'wiki',
          'display_state': 'ready',
          'eligible': true,
          'downgrade_reason': null,
          'next_action_ref': null,
          'forecast_ref': 'forecast:forecast_id_sample',
          'checkpoint_ref': 'checkpoint:checkpoint_id_sample',
          'safe_fields': <String>[
            'gap_summary',
            'risk_reason_code',
            'next_checkpoint_date',
            'checkpoint_summary',
          ],
        },
      ],
      'source_refs': <String>[
        'goal_profile:goal_profile_id_sample',
        'goal_revision:1',
        'plan_item:plan_item_id_sample',
        'forecast:forecast_id_sample',
        'checkpoint:checkpoint_id_sample',
      ],
      'rule_version': 'fuc-progress-projection-v1',
      'updated_at': '2099-06-05T09:00:00Z',
    },
  };
}

GoalProgressProjection goalProgressProjectionFixture() {
  return GoalProgressProjection.fromResponseJson(
    goalProgressProjectionResponseFixture(),
  );
}

GoalProgressProjection goalProgressIneligibleProjectionFixture({
  String state = 'deleted',
  String reason = 'deleted',
}) {
  final Map<String, dynamic> response = goalProgressProjectionResponseFixture();
  final Map<String, dynamic> projection =
      response['projection'] as Map<String, dynamic>;
  projection['projection_state'] = state;
  projection['downgrade_reason'] = reason;
  projection['goal'] = null;
  projection['next_action'] = null;
  projection['progress'] = null;
  projection['latest_checkpoint'] = null;
  projection['source_refs'] = <String>[];
  final List<dynamic> fragments =
      projection['surface_fragments'] as List<dynamic>;
  for (final dynamic item in fragments) {
    final Map<String, dynamic> fragment = item as Map<String, dynamic>;
    fragment['display_state'] = state;
    fragment['eligible'] = false;
    fragment['downgrade_reason'] = reason;
    fragment['next_action_ref'] = null;
    fragment['forecast_ref'] = null;
    fragment['checkpoint_ref'] = null;
    fragment['safe_fields'] = <String>[];
  }
  return GoalProgressProjection.fromResponseJson(response);
}

GoalProgressProjection goalProgressEligibleDowngradeProjectionFixture({
  String state = 'low_confidence',
  String reason = 'low_confidence',
}) {
  final Map<String, dynamic> response = goalProgressProjectionResponseFixture();
  final Map<String, dynamic> projection =
      response['projection'] as Map<String, dynamic>;
  projection['projection_state'] = state;
  projection['downgrade_reason'] = reason;
  final Map<String, dynamic> progress =
      projection['progress'] as Map<String, dynamic>;
  progress['forecast_state'] = state;
  progress['eta_date'] = null;
  progress['eta_unavailable_reason'] = reason;
  progress['confidence_band'] = state == 'low_confidence' ? 'low' : 'medium';
  progress['risk_level'] = 'high';
  progress['risk_reason_code'] = reason;
  final List<dynamic> fragments =
      projection['surface_fragments'] as List<dynamic>;
  for (final dynamic item in fragments) {
    final Map<String, dynamic> fragment = item as Map<String, dynamic>;
    fragment['display_state'] = state;
    fragment['eligible'] = true;
    fragment['downgrade_reason'] = reason;
  }
  return GoalProgressProjection.fromResponseJson(response);
}

Map<String, dynamic> goalProgressSummaryFixture() {
  return <String, dynamic>{
    'schema_version': 1,
    'goal_profile': <String, dynamic>{
      'goal_profile_id': 'goal_profile_id_sample',
      'goal_type': 'ielts_speaking',
      'target_score': 8,
      'target_ability': 'sensitive target ability should stay out of surface',
      'deadline': '2099-08-31',
      'daily_minutes': 30,
      'intensity_preference': 'standard',
      'support_status': 'supported',
      'status': 'active',
      'revision': 1,
    },
    'support_decision': <String, dynamic>{
      'decision_id': 'decision_id_sample',
      'support_status': 'supported',
      'reason_code': 'rubric_and_content_available',
      'limitation_message': 'Product-internal rubric only.',
      'rubric_available': true,
      'content_coverage': 'sufficient_for_local_plan',
    },
    'diagnostic': <String, dynamic>{
      'diagnostic_assessment_id': 'diagnostic_id_sample',
      'status': 'complete',
      'confidence_band': 'medium',
      'sample_count': 3,
      'claim_guard': <String, dynamic>{
        'official_score_equivalence': false,
        'goal_completion_claim_allowed': false,
        'allowed_claim': 'product_internal_progress_only',
      },
    },
    'forecast': <String, dynamic>{
      'forecast_id': 'legacy_forecast_id_sample',
      'gap_summary': 'Legacy summary gap should not render with projection.',
      'eta_date': '2099-08-24',
      'eta_window': '2099-08-17..2099-08-31',
      'confidence_band': 'medium',
      'risk_level': 'medium',
      'risk_reason': 'legacy summary risk should not render with projection',
      'next_checkpoint_date': '2099-06-11',
      'claim_guard': <String, dynamic>{
        'official_score_equivalence': false,
        'goal_completion_claim_allowed': false,
        'allowed_claim': 'product_internal_progress_only',
      },
    },
    'daily_plan': <String, dynamic>{
      'daily_plan_id': 'daily_plan_id_sample',
      'total_minutes': 30,
      'status': 'ready',
      'items': const <Map<String, dynamic>>[],
      'memory_policy': <String, dynamic>{
        'policy_version': 'memory-curve-v1',
        'forgetting_risk': 'high',
        'next_review_interval_days': 1,
        'interleaving_rule': 'rotate_fluency_pronunciation_scenario_fit',
      },
    },
    'next_action': <String, dynamic>{
      'action_id': 'action_id_sample',
      'plan_item_id': 'plan_item_id_sample',
      'action_type': 'start_training',
      'title': 'Legacy summary action',
      'reason_code': 'legacy_summary_reason',
      'expected_duration_minutes': 12,
      'status': 'ready',
    },
  };
}

Map<String, dynamic> goalProgressControlFixture() {
  return <String, dynamic>{
    'schema_version': 1,
    'control': <String, dynamic>{
      'control_id': 'control_id_sample',
      'control_status': 'active',
      'quiet_hours_start': '22:00',
      'quiet_hours_end': '08:00',
      'timezone': 'Asia/Shanghai',
      'notification_consent': true,
      'intensity_override': 'standard',
      'missed_day_policy': 'balanced',
    },
    'reason_code': 'eligible',
    'reminder_eligibility': <String, dynamic>{
      'eligible': true,
      'reason_code': 'eligible',
      'explanation_key': 'reminder_allowed',
    },
  };
}
