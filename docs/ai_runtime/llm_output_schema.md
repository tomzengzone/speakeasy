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

- `schema_version` 为必填。
- `coach_reply` 和 `next_action.prompt` 不得为空。
- `main_issue.type` 必须来自 allowed set。
- 如果 `main_issue.type` 不是 `none`，则必须提供 `original`、`better` 和 `explanation_cn`。
- 当存在 `score_signal.source` 时，它必须是 `server_side_adapter`。
- `recoverable_error` 只允许与 `next_action.type = fallback` 或 provider/schema fallback handling 一起出现。
- 该 schema 不能写入 final mastery status；它只能输出 candidate feedback 或 learning evidence candidates。

## P0.1 Training Feedback Candidate

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`。

所属增量：`docs/product/increments/p0-1-expression-automation-training/`。

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

- `schema_version`、`output_type`、`scene_id`、`action_chain_step`、`micro_action`、`completion_signal`、`task_signal`、`feedback_card` 和 `recommended_next_action` 为必填。
- `output_type` 必须是 `training_feedback_candidate`。
- `scene_id` 必须是 `job_interview` 或 `onboarding_introduction`。
- `micro_action` 必须是上方 allowed values 之一。
- `recommended_next_action.type` 必须由 deterministic planner 作为 allowed next action 提供。
- 只有当 `recommended_next_action.type=pressure_check` 时，`pressure_prompt_candidate.enabled=true` 才有效。
- `learning_evidence_candidates[*].status` 必须是 `candidate`；AI output 不得包含 `accepted`、`mastered`、`review_scheduled`、`entitled` 或 billing state fields。
- 当 pronunciation feedback 可用时，`pronunciation_signal.source` 必须是 `server_side_adapter`。
- 如果存在 `recoverable_error`，completion 和 task signals 必须使用 `unknown` 或 `partial`，且 `recommended_next_action.type` 必须是 `retry`、`text_fallback` 或 `fallback`。

## P0.2 Goal Autopilot Candidate Schemas

Owning stage: `docs/product/stages/p0-2-training-memory.md`。
Owning increments: `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint`。

所属阶段：`docs/product/stages/p0-2-training-memory.md`。
所属增量：`p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint`。

P0.2 AI output is candidate-only. Backend deterministic rules own `GoalProfile`, `DiagnosticAssessment`, `DailyTrainingPlan`, `ProgressForecast`, `OutcomeCheckpoint`, L0-L5 transition, review schedule, entitlement and claim guard decisions.

P0.2 AI output 只能是 candidate-only。`GoalProfile`、`DiagnosticAssessment`、`DailyTrainingPlan`、`ProgressForecast`、`OutcomeCheckpoint`、L0-L5 transition、review schedule、entitlement 和 claim guard decisions 均由 backend deterministic rules 持有。

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

Validation rules 中文说明：
- `output_type` 必须是 `goal_diagnostic_candidate`。
- `confidence_band` 必须是 `low`、`medium` 或 `high`。
- Candidate output 不得包含 `supported`、`unsupported`、`goal_achieved`、`official_score`、`certified`、`entitlement`、`final_mastery_level` 或 `review_due_at` fields。
- 对 IELTS/TOEFL style goals，`official_score_equivalence` 必须为 false。
- 如果 schema validation 失败、sample count 不足、provider confidence low 或缺少 required rubric dimensions，backend 必须降级为 low confidence 或 recoverable diagnostic state。

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

Validation rules 中文说明：
- `output_type` 必须是 `goal_plan_explanation_candidate`。
- Candidate text 可以解释 deterministic decisions，但不能设置 item order、due dates、mastery levels、pressure level、quota state 或 entitlement。
- 如果存在 forbidden decision fields，backend 必须拒绝 candidate，并使用 deterministic explanation fallback。

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
- Candidate may explain checkpoint evidence and forecast risk, but backend owns `OutcomeCheckpoint.result_status`, `eta_date`, `risk_level`, `plan_update_signal`, source checkpoint id, replay/audit hashes, goal completion and stale-plan decisions.
- Followup-C S002 checkpoint cadence and task-library selection is deterministic backend policy. AI output may not select `task_type`, `cadence`, `due_status`, `ai_depth`, scoring boundary, entitlement, quota or cost state.
- Followup-C S003 checkpoint-to-plan update is deterministic backend policy. AI output may not set `recorded`/`low_confidence`/`failed`/`skipped` status, replan requirement, input snapshot hash, replay audit id, control compatibility, next action advancement or goal completion.
- Followup-C S004 goal-progress projection is deterministic backend policy. AI output may not set `projection_state`, `surface_fragments`, surface eligibility, downgrade reason, source refs, safe fields, final goal state, ETA precision, claim guard or personal Wiki/Home/Queue progress facts.
- Low confidence or partial support must block high-precision ETA wording.
- Candidate output must not contain official certification, guaranteed outcome, payment status, raw transcript, raw audio, provider secret or unrestricted personal data fields.

Validation rules 中文说明：
- `output_type` 必须是 `goal_checkpoint_feedback_candidate`。
- Candidate 可以解释 checkpoint evidence 和 forecast risk，但 `OutcomeCheckpoint.result_status`、`eta_date`、`risk_level`、`plan_update_signal`、source checkpoint id、replay/audit hashes、goal completion 和 stale-plan decisions 归 backend 持有。
- Followup-C S002 checkpoint cadence 和 task-library selection 是 deterministic backend policy。AI output 不得选择 `task_type`、`cadence`、`due_status`、`ai_depth`、scoring boundary、entitlement、quota 或 cost state。
- Followup-C S003 checkpoint-to-plan update 是 deterministic backend policy。AI output 不得设置 `recorded`/`low_confidence`/`failed`/`skipped` status、replan requirement、input snapshot hash、replay audit id、control compatibility、next action advancement 或 goal completion。
- Followup-C S004 goal-progress projection 是 deterministic backend policy。AI output 不得设置 `projection_state`、`surface_fragments`、surface eligibility、downgrade reason、source refs、safe fields、final goal state、ETA precision、claim guard 或 personal Wiki/Home/Queue progress facts。
- Low confidence 或 partial support 必须阻断 high-precision ETA wording。
- Candidate output 不得包含 official certification、guaranteed outcome、payment status、raw transcript、raw audio、provider secret 或 unrestricted personal data fields。

### Followup-C Forecast Explanation Candidate

Owning increment: `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`。
Traceability: `AC-P02-FUC-001`, `TC-P02-FUC-003`。

所属增量：`docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`。
可追溯项：`AC-P02-FUC-001`, `TC-P02-FUC-003`。

S001 does not require a live LLM/provider call. If a provider-backed explanation is unavailable, blocked by policy, quota or cost, or intentionally not configured, backend must return deterministic explanation metadata on `ProgressForecast` and keep this candidate schema as the only allowed future provider shape.

S001 不要求 live LLM/provider call。如果 provider-backed explanation unavailable、被 policy/quota/cost 阻断，或被有意不配置，backend 必须在 `ProgressForecast` 上返回 deterministic explanation metadata，并把该 candidate schema 作为未来 provider shape 的唯一允许形态。

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
- Candidate output must not contain `goal_completed`, `official_score`, `certified`, `guaranteed_eta`, `eta_date`, `eta_range_start`, `eta_range_end`, `entitlement`, `quota_state`, `billing_state`, `final_mastery_level`, `release_approval`, `release_ready`, `product_base_merge_approved`, raw transcript, raw audio, raw provider payload or sensitive diagnostic details.
- If provider use is blocked or not configured, backend returns deterministic fallback metadata such as `explanation_source=deterministic_policy` and `ai_explanation_unavailable_reason=deterministic_no_provider_path`.
- Invalid, forbidden or low-confidence candidate output must not mutate `ProgressForecast`, `GoalProfile`, `OutcomeCheckpoint`, `GoalProgressProjection`, surface fragments, plan state, entitlement or billing facts.

Followup-C 验证规则：
- `output_type` 必须是 `followup_c_forecast_explanation_candidate`。
- Candidate text 可以解释 deterministic `ProgressForecast` 字段，但不能设置 `eta_date`、`eta_range`、`goal_completion_claim_allowed`、`official_score_equivalence`、`forecast_state`、entitlement、quota、billing state、checkpoint status 或 plan state。
- Candidate output 不得包含 `goal_completed`、`official_score`、`certified`、`guaranteed_eta`、`eta_date`、`eta_range_start`、`eta_range_end`、`entitlement`、`quota_state`、`billing_state`、`final_mastery_level`、`release_approval`、`release_ready`、`product_base_merge_approved`、raw transcript、raw audio、raw provider payload 或 sensitive diagnostic details。
- 如果 provider use 被阻止或未配置，backend 必须返回 deterministic fallback metadata，例如 `explanation_source=deterministic_policy` 和 `ai_explanation_unavailable_reason=deterministic_no_provider_path`。
- Invalid、forbidden 或 low-confidence candidate output 不得修改 `ProgressForecast`、`GoalProfile`、`OutcomeCheckpoint`、`GoalProgressProjection`、surface fragments、plan state、entitlement 或 billing facts。

Followup-C validation rules 中文说明：
- `output_type` 必须是 `followup_c_forecast_explanation_candidate`。
- Candidate text 可以解释 deterministic `ProgressForecast` fields，但不能设置 `eta_date`、`eta_range`、`goal_completion_claim_allowed`、`official_score_equivalence`、`forecast_state`、entitlement、quota、billing state、checkpoint status 或 plan state。
- Candidate output 不得包含 `goal_completed`、`official_score`、`certified`、`guaranteed_eta`、`eta_date`、`eta_range_start`、`eta_range_end`、`entitlement`、`quota_state`、`billing_state`、`final_mastery_level`、`release_approval`、`release_ready`、`product_base_merge_approved`、raw transcript、raw audio、raw provider payload 或 sensitive diagnostic details。
- 如果 provider use 被阻断或未配置，backend 返回 deterministic fallback metadata，例如 `explanation_source=deterministic_policy` 和 `ai_explanation_unavailable_reason=deterministic_no_provider_path`。
- Invalid、forbidden 或 low-confidence candidate output 不得修改 `ProgressForecast`、`GoalProfile`、`OutcomeCheckpoint`、`GoalProgressProjection`、surface fragments、plan state、entitlement 或 billing facts。

## P0.2 Followup-B Mastery Transition Explanation Candidate

Owning increment: `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

所属增量：`docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

This schema is candidate-only. Backend deterministic rules own `MemoryItemPolicyState`, `MasteryTransitionDecision`, `PlannerReplayAudit`, review schedule, notification schedule, control state, recovery mode, entitlement, quota and official-score claim guards.

该 schema 仅表示 candidate。`MemoryItemPolicyState`、`MasteryTransitionDecision`、`PlannerReplayAudit`、review schedule、notification schedule、control state、recovery mode、entitlement、quota 和 official-score claim guards 均由 backend deterministic rules 拥有。

该 schema 只能产生 candidate-only output。`MemoryItemPolicyState`、`MasteryTransitionDecision`、`PlannerReplayAudit`、review schedule、notification schedule、control state、recovery mode、entitlement、quota 和 official-score claim guards 均由 backend deterministic rules 持有。

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
- Candidate output must not contain persistent decision fields such as `final_mastery_level`, `promotion_applied`, `demotion_applied`, `review_due_at`, `notification_schedule`, `control_status`, `recovery_mode`, `goal_completed`, `official_score`, `certified`, `entitlement`, `quota_state`, `billing_state`, `release_approval`, `release_ready` or `product_base_merge_approved`.
- If any forbidden field is present, backend validation must reject or ignore the candidate for persistence and use deterministic fallback. It must not update `MasteryTransitionDecision`, `MemoryItemPolicyState`, `NotificationOutboxRecord`, `UserAutopilotControl` or `RecoveryPlanDecision`.

### Followup-B 验证规则
- `schema_version`、`output_type`、`transition_id`、`memory_item_state_id`、`previous_level`、`proposed_level`、`accepted_level`、`transition_direction`、`reason_code`、`learner_visible_explanation`、`evidence_summary` 和 `guardrails` 为必填。
- `output_type` 必须是 `followup_b_mastery_transition_explanation_candidate`。
- Level 和 transition 字段必须回显 deterministic input values；candidate 不得编造新的 level、reason code 或 transition direction。
- `guardrails.official_score_equivalence` 和 `guardrails.goal_completion_claim_allowed` 必须为 false。
- 在 candidate 可以渲染前，`guardrails.persistent_decision_fields_present` 必须为 false，且 `guardrails.forbidden_fields_detected` 必须为空。
- `evidence_summary` 只能包含 redacted evidence refs 和 aggregate counts；禁止包含 raw transcript、raw audio、raw provider payload、精确 sensitive diagnostic details 和 unrestricted personal data。
- Candidate output 不得包含 `final_mastery_level`、`promotion_applied`、`demotion_applied`、`review_due_at`、`notification_schedule`、`control_status`、`recovery_mode`、`goal_completed`、`official_score`、`certified`、`entitlement`、`quota_state`、`billing_state`、`release_approval`、`release_ready` 或 `product_base_merge_approved` 等 persistent decision fields。
- 如果出现任何 forbidden field，backend validation 必须拒绝或忽略该 candidate 的持久化，并使用 deterministic fallback。它不得更新 `MasteryTransitionDecision`、`MemoryItemPolicyState`、`NotificationOutboxRecord`、`UserAutopilotControl` 或 `RecoveryPlanDecision`。

- `schema_version`、`output_type`、`transition_id`、`memory_item_state_id`、`previous_level`、`proposed_level`、`accepted_level`、`transition_direction`、`reason_code`、`learner_visible_explanation`、`evidence_summary` 和 `guardrails` 为必填。
- `output_type` 必须是 `followup_b_mastery_transition_explanation_candidate`。
- Level 和 transition fields 必须回显 deterministic input values；candidate 不得虚构新的 level、reason code 或 transition direction。
- `guardrails.official_score_equivalence` 和 `guardrails.goal_completion_claim_allowed` 必须为 false。
- Candidate 可渲染前，`guardrails.persistent_decision_fields_present` 必须为 false，且 `guardrails.forbidden_fields_detected` 必须为空。
- `evidence_summary` 只能包含 redacted evidence refs 和 aggregate counts；raw transcript、raw audio、raw provider payload、精确 sensitive diagnostic details 和 unrestricted personal data 均被禁止。
- Candidate output 不得包含 persistent decision fields，例如 `final_mastery_level`、`promotion_applied`、`demotion_applied`、`review_due_at`、`notification_schedule`、`control_status`、`recovery_mode`、`goal_completed`、`official_score`、`certified`、`entitlement`、`quota_state`、`billing_state`、`release_approval`、`release_ready` 或 `product_base_merge_approved`。
- 如果存在任何 forbidden field，backend validation 必须拒绝或忽略该 candidate 的持久化，并使用 deterministic fallback。它不得更新 `MasteryTransitionDecision`、`MemoryItemPolicyState`、`NotificationOutboxRecord`、`UserAutopilotControl` 或 `RecoveryPlanDecision`。

## P0.2 Followup-E Speaking Diagnostic Candidate

Owning increment: `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。

所属增量：`docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。

This schema is candidate-only. Backend deterministic validation owns accepted `DiagnosticAssessment`, `DiagnosticAudioSample`, `DiagnosticQualityGate`, `audio_ref`, diagnostic mode, confidence band, GoalProfile, GoalBackplan, forecast/checkpoint effects, entitlement, quota, billing, release and Product Base state.

该 schema 仅表示 candidate。已接受的 `DiagnosticAssessment`、`DiagnosticAudioSample`、`DiagnosticQualityGate`、`audio_ref`、diagnostic mode、confidence band、GoalProfile、GoalBackplan、forecast/checkpoint effects、entitlement、quota、billing、release 和 Product Base state 均由 backend deterministic validation 拥有。

该 schema 只能产生 candidate-only output。Accepted `DiagnosticAssessment`、`DiagnosticAudioSample`、`DiagnosticQualityGate`、`audio_ref`、diagnostic mode、confidence band、GoalProfile、GoalBackplan、forecast/checkpoint effects、entitlement、quota、billing、release 和 Product Base state 均由 backend deterministic validation 持有。

```json
{
  "schema_version": 1,
  "output_type": "followup_e_speaking_diagnostic_candidate",
  "diagnostic_id": "diagnostic_id_sample",
  "goal_profile_id": "goal_profile_id_sample",
  "goal_revision": 2,
  "diagnostic_mode": "audio_partial",
  "confidence_band": "medium",
  "accepted_audio_sample_count": 2,
  "text_sample_count": 1,
  "quality_summary": {
    "accepted_sample_count": 2,
    "quality_flags": [
      "third_sample_skipped"
    ],
    "limitation_summary": "One sample was skipped, so the result is a medium-confidence speaking baseline."
  },
  "top_weaknesses": [
    {
      "weakness_type": "pause_control",
      "summary": "Answers slowed down during longer goal-context speech.",
      "evidence_source": "accepted_audio"
    },
    {
      "weakness_type": "answer_structure",
      "summary": "The free answer needs a clearer opening point and example.",
      "evidence_source": "accepted_audio"
    }
  ],
  "next_training_focus": {
    "category": "short_answer_structure",
    "reason": "Start with concise answer framing before longer scenario practice."
  },
  "learner_visible_explanation": "This is a medium-confidence product-internal speaking baseline from two accepted audio samples and one skipped sample.",
  "recalibration_prompt": "You can complete the skipped audio sample later to improve diagnostic confidence.",
  "guardrails": {
    "official_score_equivalence": false,
    "goal_completion_claim_allowed": false,
    "guaranteed_eta_claim_allowed": false,
    "text_only_acoustic_claim_present": false,
    "persistent_decision_fields_present": false,
    "forbidden_fields_detected": []
  },
  "recoverable_error": null
}
```

### Allowed `diagnostic_mode`
- `audio_full`
- `audio_partial`
- `text_only`

### Allowed `confidence_band`
- `high`
- `medium`
- `low`

### Allowed `evidence_source`
- `accepted_audio`
- `audio_asr`
- `user_text`
- `deterministic_fallback`

### Followup-E Validation Rules
- `schema_version`, `output_type`, `diagnostic_id`, `goal_profile_id`, `goal_revision`, `diagnostic_mode`, `confidence_band`, sample counts, `quality_summary`, `top_weaknesses`, `next_training_focus`, `learner_visible_explanation` and `guardrails` are required.
- `output_type` must be `followup_e_speaking_diagnostic_candidate`.
- `diagnostic_id`, `goal_profile_id`, `goal_revision`, `diagnostic_mode`, `confidence_band`, `accepted_audio_sample_count` and `text_sample_count` must echo deterministic backend input values.
- `top_weaknesses` must contain 1-3 items. Each item must use an allowed `weakness_type` from backend policy and a compatible `evidence_source`.
- When `diagnostic_mode=text_only`, `top_weaknesses`, `learner_visible_explanation` and `next_training_focus.reason` must not claim measured pronunciation, intonation, speech rate, pause timing, clipping, noise, accent or acoustic fluency.
- `next_training_focus.category` must be one of the backend-supplied allowed categories, such as `short_answer_structure`, `sentence_completeness`, `pause_reduction`, `pronunciation_clarity`, `vocabulary_range` or `text_fallback_recalibration`.
- `guardrails.official_score_equivalence`, `guardrails.goal_completion_claim_allowed`, `guardrails.guaranteed_eta_claim_allowed`, `guardrails.text_only_acoustic_claim_present` and `guardrails.persistent_decision_fields_present` must be false.
- `guardrails.forbidden_fields_detected` must be empty before the candidate can be rendered.
- Candidate output must not contain `audio_ref`, local file paths, signed URLs, raw audio, raw provider payload, provider secrets, full sensitive transcript, `goal_profile_update`, `goal_backplan_update`, `forecast_state`, `checkpoint_result`, final mastery, official-score fields, entitlement, quota, billing, release approval, release readiness or Product Base merge approval.
- If validation fails, backend returns deterministic fallback and must not update `DiagnosticAssessment`, `DiagnosticAudioSample`, `DiagnosticPrivacyState`, `GoalProfile`, `GoalBackplan`, `ProgressForecast`, `OutcomeCheckpoint`, entitlement, billing, release or Product Base facts.

### Followup-E 验证规则
- `schema_version`、`output_type`、`diagnostic_id`、`goal_profile_id`、`goal_revision`、`diagnostic_mode`、`confidence_band`、sample counts、`quality_summary`、`top_weaknesses`、`next_training_focus`、`learner_visible_explanation` 和 `guardrails` 为必填。
- `output_type` 必须是 `followup_e_speaking_diagnostic_candidate`。
- `diagnostic_id`、`goal_profile_id`、`goal_revision`、`diagnostic_mode`、`confidence_band`、`accepted_audio_sample_count` 和 `text_sample_count` 必须回显 deterministic backend input values。
- `top_weaknesses` 必须包含 1-3 个 item。每个 item 必须使用 backend policy 允许的 `weakness_type`，并匹配兼容的 `evidence_source`。
- 当 `diagnostic_mode=text_only` 时，`top_weaknesses`、`learner_visible_explanation` 和 `next_training_focus.reason` 不得声称 measured pronunciation、intonation、speech rate、pause timing、clipping、noise、accent 或 acoustic fluency。
- `next_training_focus.category` 必须是 backend 提供的 allowed categories 之一，例如 `short_answer_structure`、`sentence_completeness`、`pause_reduction`、`pronunciation_clarity`、`vocabulary_range` 或 `text_fallback_recalibration`。
- `guardrails.official_score_equivalence`、`guardrails.goal_completion_claim_allowed`、`guardrails.guaranteed_eta_claim_allowed`、`guardrails.text_only_acoustic_claim_present` 和 `guardrails.persistent_decision_fields_present` 必须为 false。
- 在 candidate 可以渲染前，`guardrails.forbidden_fields_detected` 必须为空。
- Candidate output 不得包含 `audio_ref`、local file paths、signed URLs、raw audio、raw provider payload、provider secrets、full sensitive transcript、`goal_profile_update`、`goal_backplan_update`、`forecast_state`、`checkpoint_result`、final mastery、official-score fields、entitlement、quota、billing、release approval、release readiness 或 Product Base merge approval。
- 如果 validation fails，backend 返回 deterministic fallback，且不得更新 `DiagnosticAssessment`、`DiagnosticAudioSample`、`DiagnosticPrivacyState`、`GoalProfile`、`GoalBackplan`、`ProgressForecast`、`OutcomeCheckpoint`、entitlement、billing、release 或 Product Base facts。

- `schema_version`、`output_type`、`diagnostic_id`、`goal_profile_id`、`goal_revision`、`diagnostic_mode`、`confidence_band`、sample counts、`quality_summary`、`top_weaknesses`、`next_training_focus`、`learner_visible_explanation` 和 `guardrails` 为必填。
- `output_type` 必须是 `followup_e_speaking_diagnostic_candidate`。
- `diagnostic_id`、`goal_profile_id`、`goal_revision`、`diagnostic_mode`、`confidence_band`、`accepted_audio_sample_count` 和 `text_sample_count` 必须回显 deterministic backend input values。
- `top_weaknesses` 必须包含 1-3 个 items。每个 item 必须使用 backend policy 允许的 `weakness_type`，并使用兼容的 `evidence_source`。
- 当 `diagnostic_mode=text_only` 时，`top_weaknesses`、`learner_visible_explanation` 和 `next_training_focus.reason` 不得声称已测量 pronunciation、intonation、speech rate、pause timing、clipping、noise、accent 或 acoustic fluency。
- `next_training_focus.category` 必须是 backend-supplied allowed categories 之一，例如 `short_answer_structure`、`sentence_completeness`、`pause_reduction`、`pronunciation_clarity`、`vocabulary_range` 或 `text_fallback_recalibration`。
- `guardrails.official_score_equivalence`、`guardrails.goal_completion_claim_allowed`、`guardrails.guaranteed_eta_claim_allowed`、`guardrails.text_only_acoustic_claim_present` 和 `guardrails.persistent_decision_fields_present` 必须为 false。
- Candidate 可渲染前，`guardrails.forbidden_fields_detected` 必须为空。
- Candidate output 不得包含 `audio_ref`、local file paths、signed URLs、raw audio、raw provider payload、provider secrets、full sensitive transcript、`goal_profile_update`、`goal_backplan_update`、`forecast_state`、`checkpoint_result`、final mastery、official-score fields、entitlement、quota、billing、release approval、release readiness 或 Product Base merge approval。
- 如果 validation 失败，backend 返回 deterministic fallback，且不得更新 `DiagnosticAssessment`、`DiagnosticAudioSample`、`DiagnosticPrivacyState`、`GoalProfile`、`GoalBackplan`、`ProgressForecast`、`OutcomeCheckpoint`、entitlement、billing、release 或 Product Base facts。
