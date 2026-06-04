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
- Low confidence or partial support must block high-precision ETA wording.
- Candidate output must not contain official certification, guaranteed outcome, payment status, raw transcript, raw audio, provider secret or unrestricted personal data fields.
