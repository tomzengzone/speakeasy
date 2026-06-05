# LLM Output Schema

## Practice Turn Response

```json
{
  "schema_version": 1,
  "intent_covered": true,
  "current_action_step": "string",
  "stage_satisfied": false,
  "coach_reply": "string",
  "feedback": "string",
  "main_issue": {
    "type": "none",
    "original": "string",
    "better": "string",
    "explanation_cn": "string"
  },
  "saved_expression_candidates": [
    {
      "text": "string",
      "meaning_cn": "string",
      "example": "string"
    }
  ],
  "next_action": {
    "type": "continue_dialogue",
    "prompt": "string"
  },
  "score_signal": {
    "score_kind": "pronunciation",
    "value": 0.85,
    "confidence": 0.85,
    "status": "available",
    "source": "server_side_adapter"
  },
  "recoverable_error": {
    "code": "string",
    "message": "string",
    "retryable": true
  }
}
```

## Allowed `main_issue.type`
- none
- grammar
- vocabulary
- naturalness
- tone
- pronunciation
- fluency
- missing_intent
- off_topic

## Allowed `next_action.type`
- continue_dialogue
- retry
- model_then_retry
- advance_step
- complete_session
- fallback

## Validation Rules
- `schema_version` is required.
- `coach_reply` and `next_action.prompt` must not be empty.
- `main_issue.type` must be from the allowed set.
- If `main_issue.type` is not `none`, `original`, `better`, and `explanation_cn` are required.
- `score_signal.source` must be `server_side_adapter` when present.
- `recoverable_error` is allowed only with `next_action.type = fallback` or provider/schema fallback handling.
- The schema cannot write final mastery status; it may only emit candidate feedback or learning evidence candidates.

## P0.1 Training Feedback Candidate

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`。

```json
{
  "schema_version": 1,
  "output_type": "training_feedback_candidate",
  "scene_id": "job_interview",
  "action_chain_step": "opening",
  "micro_action": "SayOne",
  "hint_level": "sentence_frame",
  "completion_signal": {
    "status": "met",
    "confidence": 0.82,
    "reason_code": "target_meaning_covered"
  },
  "task_signal": {
    "status": "met",
    "confidence": 0.8,
    "missing_piece": ""
  },
  "pronunciation_signal": {
    "status": "available",
    "summary": "Clear enough for this step.",
    "source": "server_side_adapter"
  },
  "feedback_card": {
    "summary": "You covered the main idea.",
    "main_issue_type": "naturalness",
    "better_expression": "I'm excited to discuss how my experience fits this role.",
    "explanation_cn": "表达更自然，也更贴合面试开场。"
  },
  "retry_hint": {
    "hint_level": "sentence_frame",
    "prompt": "Try starting with: I'm excited to..."
  },
  "recommended_next_action": {
    "type": "retry",
    "micro_action": "SayOne",
    "prompt": "Say it again with the sentence frame."
  },
  "pressure_prompt_candidate": {
    "enabled": false,
    "prompt": "",
    "success_condition": ""
  },
  "learning_evidence_candidates": [
    {
      "status": "candidate",
      "evidence_type": "weak_expression",
      "target_expression_id": "job_interview_l1_opening_excited",
      "confidence": 0.72,
      "rule_input": "Learner covered intent but needed sentence-frame support."
    }
  ],
  "recoverable_error": null
}
```

### Allowed `completion_signal.status`
- `met`
- `partial`
- `not_met`
- `unknown`

### Allowed `task_signal.status`
- `met`
- `partial`
- `not_met`
- `unknown`

### Allowed `feedback_card.main_issue_type`
- `none`
- `grammar`
- `vocabulary`
- `naturalness`
- `tone`
- `pronunciation`
- `fluency`
- `missing_intent`
- `off_topic`
- `asr_uncertain`

### Allowed `recommended_next_action.type`
- `continue`
- `retry`
- `raise_hint`
- `lower_hint`
- `model_then_retry`
- `pressure_check`
- `recap`
- `text_fallback`
- `fallback`

### Allowed `micro_action`
- `ListenOne`
- `ChooseOne`
- `SayOne`
- `ShadowOne`
- `FillOne`
- `ContinueUnderPrompt`

### P0.1 Validation Rules
- `schema_version`, `output_type`, `scene_id`, `action_chain_step`, `micro_action`, `completion_signal`, `task_signal`, `feedback_card`, and `recommended_next_action` are required.
- `output_type` must be `training_feedback_candidate`.
- `scene_id` must be `job_interview` or `onboarding_introduction`.
- `micro_action` must be one of the allowed values above.
- `recommended_next_action.type` must be supplied by deterministic planner as an allowed next action.
- `pressure_prompt_candidate.enabled=true` is valid only when `recommended_next_action.type=pressure_check`.
- `learning_evidence_candidates[*].status` must be `candidate`; AI output must not contain `accepted`, `mastered`, `review_scheduled`, `entitled`, or billing state fields.
- `pronunciation_signal.source` must be `server_side_adapter` when pronunciation feedback is available.
- If `recoverable_error` is present, completion and task signals must use `unknown` or `partial`, and `recommended_next_action.type` must be `retry`, `text_fallback`, or `fallback`.

## P0.2 Goal Autopilot Candidate Schemas

Owning stage: `docs/product/stages/p0-2-training-memory.md`。
Owning increments: `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint`。

P0.2 AI output is candidate-only. Backend deterministic rules own `GoalProfile`, `DiagnosticAssessment`, `DailyTrainingPlan`, `ProgressForecast`, `OutcomeCheckpoint`, L0-L5 transition, review schedule, entitlement and claim guard decisions.

### Diagnostic Candidate

```json
{
  "schema_version": 1,
  "output_type": "goal_diagnostic_candidate",
  "goal_profile_id": "uuid",
  "target_rubric": "ielts_speaking_internal_v1",
  "sample_count": 3,
  "rubric_scores": [
    {
      "dimension": "fluency",
      "score": 5.5,
      "evidence_ref": "sample_1",
      "confidence": 0.72
    }
  ],
  "weakness_tags": [
    {
      "tag": "limited_extension",
      "severity": "high",
      "dimension": "fluency",
      "recommended_training_direction": "longer turn expansion",
      "evidence_ref": "sample_2"
    }
  ],
  "confidence_band": "medium",
  "confidence_reasons": [
    "minimum_sample_met"
  ],
  "claim_guard": {
    "official_score_equivalence": false,
    "allowed_claim": "product_internal_progress_only"
  },
  "recoverable_error": null
}
```

Validation rules:
- `output_type` must be `goal_diagnostic_candidate`.
- `confidence_band` must be `low`, `medium` or `high`.
- Candidate output cannot contain `supported`, `unsupported`, `goal_achieved`, `official_score`, `certified`, `entitlement`, `final_mastery_level` or `review_due_at` fields.
- `official_score_equivalence` must be false for IELTS/TOEFL style goals.
- Backend must downgrade to low confidence or recoverable diagnostic state if schema validation fails, sample count is insufficient, provider confidence is low or required rubric dimensions are missing.

### Plan Explanation Candidate

```json
{
  "schema_version": 1,
  "output_type": "goal_plan_explanation_candidate",
  "goal_profile_id": "uuid",
  "plan_version": "goal-plan-v1",
  "short_explanation": "Today focuses on high-risk fluency retrieval before a short scenario task.",
  "learner_visible_reason": "Your fluency evidence is weaker than your pronunciation evidence.",
  "risk_notes": [
    "checkpoint_due_this_week"
  ],
  "forbidden_decision_fields_present": false,
  "recoverable_error": null
}
```

Validation rules:
- `output_type` must be `goal_plan_explanation_candidate`.
- Candidate text can explain deterministic decisions but cannot set item order, due dates, mastery levels, pressure level, quota state or entitlement.
- If forbidden decision fields are present, backend rejects the candidate and uses deterministic explanation fallback.

### Forecast And Checkpoint Candidate

```json
{
  "schema_version": 1,
  "output_type": "goal_checkpoint_feedback_candidate",
  "goal_profile_id": "uuid",
  "checkpoint_type": "weekly_mock",
  "rubric_observations": [
    {
      "dimension": "task_response",
      "summary": "Answer addressed the topic but lacked examples.",
      "evidence_ref": "checkpoint_sample_1"
    }
  ],
  "forecast_explanation_candidate": {
    "gap_summary": "Main gap remains fluency under follow-up pressure.",
    "risk_reason": "Recent missed review increased retrieval risk.",
    "confidence_band": "medium"
  },
  "claim_guard": {
    "goal_completion_claim_allowed": false,
    "official_score_equivalence": false
  },
  "recoverable_error": null
}
```

Validation rules:
- `output_type` must be `goal_checkpoint_feedback_candidate`.
- Candidate may explain checkpoint evidence and forecast risk, but backend owns `eta_date`, `risk_level`, `plan_update_signal`, goal completion and stale-plan decisions.
- Followup-C S002 checkpoint cadence and task-library selection is deterministic backend policy. AI output may not select `task_type`, `cadence`, `due_status`, `ai_depth`, scoring boundary, entitlement, quota or cost state.
- Low confidence or partial support must block high-precision ETA wording.
- Candidate output must not contain official certification, guaranteed outcome, payment status, raw transcript, raw audio, provider secret or unrestricted personal data fields.

### Followup-C Forecast Explanation Candidate

Owning increment: `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`。
Traceability: `AC-P02-FUC-001`, `TC-P02-FUC-003`。

S001 does not require a live LLM/provider call. If a provider-backed explanation is unavailable, blocked by policy, quota or cost, or intentionally not configured, backend must return deterministic explanation metadata on `ProgressForecast` and keep this candidate schema as the only allowed future provider shape.

```json
{
  "schema_version": 1,
  "output_type": "followup_c_forecast_explanation_candidate",
  "forecast_id": "forecast_id_sample",
  "goal_profile_id": "goal_profile_id_sample",
  "source_goal_revision": 1,
  "forecast_state": "limited",
  "risk_reason_code": "checkpoint_evidence_missing",
  "learner_visible_explanation": "The ETA is broad until a checkpoint confirms the current gap.",
  "guardrails": {
    "official_score_equivalence": false,
    "goal_completion_claim_allowed": false,
    "guaranteed_eta_claim_allowed": false,
    "persistent_decision_fields_present": false,
    "forbidden_fields_detected": []
  },
  "recoverable_error": null
}
```

Allowed `forecast_state` values:
- `ready`
- `limited`
- `unavailable`
- `deleted`
- `unsupported`
- `low_confidence`
- `stale_plan`
- `recovery_required`

Followup-C validation rules:
- `output_type` must be `followup_c_forecast_explanation_candidate`.
- Candidate text may explain deterministic `ProgressForecast` fields but cannot set `eta_date`, `eta_range`, `goal_completion_claim_allowed`, `official_score_equivalence`, `forecast_state`, entitlement, quota, billing state, checkpoint status or plan state.
- Candidate output must not contain `goal_completed`, `official_score`, `certified`, `guaranteed_eta`, `eta_date`, `eta_range_start`, `eta_range_end`, `entitlement`, `quota_state`, `billing_state`, raw transcript, raw audio, raw provider payload or sensitive diagnostic details.
- If provider use is blocked or not configured, backend returns deterministic fallback metadata such as `explanation_source=deterministic_policy` and `ai_explanation_unavailable_reason=deterministic_no_provider_path`.
- Invalid, forbidden or low-confidence candidate output must not mutate `ProgressForecast`, `GoalProfile`, `OutcomeCheckpoint`, plan state, entitlement or billing facts.

## P0.2 Followup-B Mastery Transition Explanation Candidate

Owning increment: `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

This schema is candidate-only. Backend deterministic rules own `MemoryItemPolicyState`, `MasteryTransitionDecision`, `PlannerReplayAudit`, review schedule, notification schedule, control state, recovery mode, entitlement, quota and official-score claim guards.

```json
{
  "schema_version": 1,
  "output_type": "followup_b_mastery_transition_explanation_candidate",
  "transition_id": "mastery_transition_id_sample",
  "memory_item_state_id": "memory_item_state_id_sample",
  "item_type": "expression",
  "previous_level": "L2",
  "proposed_level": "L3",
  "accepted_level": "L3",
  "transition_direction": "promote",
  "reason_code": "accepted_evidence_retrieval_success",
  "confidence_band": "medium",
  "learner_visible_explanation": "You moved from L2 to L3 for this internal practice item because recent accepted evidence shows more reliable retrieval.",
  "evidence_summary": {
    "accepted_evidence_count": 3,
    "latest_evidence_refs": [
      "evidence_id_redacted"
    ],
    "summary": "Accepted retrieval and checkpoint evidence improved for the same item."
  },
  "safety_note": "This is an internal practice signal, not an official exam score.",
  "guardrails": {
    "official_score_equivalence": false,
    "goal_completion_claim_allowed": false,
    "persistent_decision_fields_present": false,
    "forbidden_fields_detected": []
  },
  "recoverable_error": null
}
```

### Allowed `item_type`
- `expression`
- `scenario`
- `diagnostic_weakness`
- `plan_item`

### Allowed `previous_level`, `proposed_level`, `accepted_level`
- `L0`
- `L1`
- `L2`
- `L3`
- `L4`
- `L5`

### Allowed `transition_direction`
- `promote`
- `demote`
- `hold`
- `reject`

### Followup-B Validation Rules
- `schema_version`, `output_type`, `transition_id`, `memory_item_state_id`, `previous_level`, `proposed_level`, `accepted_level`, `transition_direction`, `reason_code`, `learner_visible_explanation`, `evidence_summary` and `guardrails` are required.
- `output_type` must be `followup_b_mastery_transition_explanation_candidate`.
- Level and transition fields must echo deterministic input values; the candidate must not invent a new level, reason code or transition direction.
- `guardrails.official_score_equivalence` and `guardrails.goal_completion_claim_allowed` must be false.
- `guardrails.persistent_decision_fields_present` must be false and `guardrails.forbidden_fields_detected` must be empty before the candidate can be rendered.
- `evidence_summary` may include redacted evidence refs and aggregate counts only; raw transcript, raw audio, raw provider payload, exact sensitive diagnostic details and unrestricted personal data are forbidden.
- Candidate output must not contain persistent decision fields such as `final_mastery_level`, `promotion_applied`, `demotion_applied`, `review_due_at`, `notification_schedule`, `control_status`, `recovery_mode`, `goal_completed`, `official_score`, `certified`, `entitlement`, `quota_state` or `billing_state`.
- If any forbidden field is present, backend validation must reject or ignore the candidate for persistence and use deterministic fallback. It must not update `MasteryTransitionDecision`, `MemoryItemPolicyState`, `NotificationOutboxRecord`, `UserAutopilotControl` or `RecoveryPlanDecision`.
