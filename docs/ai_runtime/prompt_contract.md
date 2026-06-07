# Prompt Contract

## Purpose
Define how AI runtime prompts are structured and how responses are validated.

Owning increments:
- `docs/product/increments/mvp-backend-practice-ai/` for Product Base coach feedback candidate generation.
- `docs/product/increments/p0-1-expression-automation-training/` for P0.1 structured training feedback, hint, retry, next action candidate, and pressure prompt candidate generation.
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/` for Followup-B candidate-only mastery transition explanations and forbidden persistent-field rejection.

## Inputs
- user profile summary
- scenario context
- current action step
- dialogue history
- learner latest turn
- target expressions

## Output Requirement
The model must return valid JSON matching `docs/ai_runtime/llm_output_schema.md`.

## Prompt Rules
- Ask for one next action at a time.
- Keep coach feedback concise.
- Do not overload learner with multiple corrections.
- Prefer one main issue per learner turn.
- Do not advance the action step unless success criteria are met.
- Include fallback-safe fields.
- Do not decide final mastery, entitlement, billing, or long-term review state.
- Do not expose provider names, provider secrets, raw credentials, or raw provider payloads to the client.
- If provider output is malformed or low confidence, return fallback-safe structured output instead of natural-language-only feedback.

## Prompt Test Rule
Every prompt contract must have positive and negative cases in `docs/ai_runtime/ai_eval_cases.md`.

## P0.1 Training Prompt Contract

### Purpose
P0.1 的 AI runtime 只生成训练反馈候选，不直接推进训练状态。Prompt 必须支持一个 micro-action 的即时反馈、支架化重试建议、下一步候选动作、轻量追问候选和学习证据候选。

### Owning Product Object
| 字段 | 值 |
| --- | --- |
| Increment | `docs/product/increments/p0-1-expression-automation-training/` |
| Domain input | `docs/domain/training_model.md` |
| Acceptance | `AC-P01-004`, `AC-P01-005`, `AC-P01-008`, `AC-P01-009`, `AC-P01-010`, `AC-P01-011` |
| Closed gap | `P01-GAP-002` after schema/eval/fallback/state-machine updates |

### Required Inputs
- `schema_version`
- `scene_id`: only `job_interview` or `onboarding_introduction`
- `level_code`
- `action_chain_step`
- `micro_action`
- `hint_level`
- `target_expression`
- `learner_input`: transcript or text fallback
- `input_mode`: `voice`, `text_fallback`, or `debug_text`
- `asr_status`
- `score_signal`: optional pronunciation/completeness signal
- `recent_attempt_summary`
- `allowed_next_actions`: supplied by deterministic planner

### Output Requirement
The model must return valid JSON matching the P0.1 `TrainingFeedbackCandidate` schema in `docs/ai_runtime/llm_output_schema.md`.

### Prompt Rules
- Return exactly one main feedback focus.
- Keep learner-facing feedback short enough for a mobile training card.
- Do not invent a new official scene, action chain step, target expression, or mastery level.
- Do not mark `stage_completed`, `mastered`, `paid`, `entitled`, `review_scheduled`, or any final persisted state.
- Do not choose a next action outside `allowed_next_actions`.
- If ASR failed or transcript is empty, return a recoverable fallback candidate and do not judge learner ability.
- Pronunciation feedback may be included only when a score signal is available or explicitly unavailable.
- Pressure prompt candidate must stay inside the current session and current scenario.
- Learning evidence output is candidate-only and must include a `rule_input` summary for deterministic evidence rules.

### Developer Prompt Skeleton
```text
You are generating candidate feedback for a deterministic English speaking training planner.
Return JSON only. Use schema_version=1 and output_type=training_feedback_candidate.

You may:
- explain whether the learner completed the current micro-action;
- suggest one concise improvement;
- suggest a retry hint;
- propose one pressure prompt if the planner says pressure check is allowed;
- emit learning_evidence_candidates for deterministic rules to accept or reject.

You must not:
- advance the session;
- decide final mastery;
- schedule cross-day review;
- create scenes or target expressions;
- override allowed_next_actions;
- blame ASR/provider failures on the learner.
```

### Validation Requirement
- JSON parse must pass.
- `output_type` must be `training_feedback_candidate`.
- `micro_action` and `action_chain_step` must echo valid supplied inputs.
- `recommended_next_action.type` must be in `allowed_next_actions`.
- If `recoverable_error` is present, `recommended_next_action.type` must be `retry`, `text_fallback`, or `fallback`.
- `learning_evidence_candidates[*].status` must be `candidate`; no field may claim final mastery.

## Backend Provider Adapter Prompt Boundary

Traceability: `CR-20260601-001`, `P01-FR-011`, `P01-SPEC-012`, `AC-P01-013`。

- DashScope/Qwen is an implementation behind the current backend AI Gateway; prompt text and provider credentials are never sent to Flutter.
- Provider output must be treated as untrusted until parsed, schema-validated and mapped to the existing backend DTO.
- Product Base `/ai/coach-turn` may map strict JSON into `CoachResult`; P0.1 training feedback must map strict JSON into `TrainingFeedbackCandidate` or deterministic fallback before planner consumption.
- Provider invalid JSON, markdown-wrapped JSON, missing required fields, off-scope actions, or final mastery/billing fields must produce fallback instead of successful feedback.
- Prompt examples and eval cases must include provider timeout/unavailable, ASR empty transcript, TTS unavailable and invalid schema cases.

## P0.2 Followup-B AI Runtime Contract

### Purpose
Followup-B AI runtime may generate candidate-only, learner-visible explanations for deterministic L0-L5 mastery transition decisions. It must not decide or persist autopilot control state, notification eligibility, notification schedule, recovery mode, item due decision, final mastery, review schedule, goal completion, entitlement, quota, official score equivalence or replay result.

### Owning Product Object
| 字段 | 值 |
| --- | --- |
| Increment | `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/` |
| Acceptance | `AC-P02-FUB-007`, `AC-P02-FUB-008` |
| Test cases | `TC-P02-FUB-014` primary AI eval / forbidden persistent-field rejection; `TC-P02-FUB-015` supporting replay fixture input only, not an AI pass/fail substitute |
| Domain input | `MasteryTransitionDecision`, `MemoryItemPolicyState`, `PlannerReplayAudit` in `docs/domain/domain_schema.md` |
| API input | `GET /goal-autopilot/mastery-transitions`, `GET /goal-autopilot/replay-audits` in `docs/architecture/openapi/speakeasy-api.yaml` |

### Required Inputs
- `schema_version`
- `transition_id`
- `memory_item_state_id`
- `item_type`
- `previous_level`
- `proposed_level`
- `accepted_level`
- `transition_direction`
- `accepted_evidence_summary`: redacted aggregate only, no raw transcript or raw audio
- `confidence_band`
- `reason_code`
- `rule_version`
- `support_status`
- `claim_guard`

### Output Requirement
The model must return valid JSON matching `FollowupBMasteryTransitionExplanationCandidate` in `docs/ai_runtime/llm_output_schema.md`.

### Prompt Rules
- Return JSON only; do not wrap JSON in markdown.
- Explain the deterministic transition decision in one concise learner-visible explanation.
- Echo supplied deterministic fields only when the schema allows it; never invent a new level, reason code, rule version or evidence ref.
- Use product-internal mastery wording such as L0-L5 or practice readiness; do not imply IELTS/TOEFL certification, official score, guaranteed outcome or goal completion.
- If evidence is low-confidence, partial, unsupported or fatigue-protected, explain hold/demotion/block conservatively without encouraging forced promotion.
- Do not include raw transcript, raw audio, provider payload, provider name, provider secret, exact high-risk diagnostic details or unrestricted personal data.
- If the model output contains forbidden persistent fields, backend validation must reject the candidate and use deterministic fallback.

### Forbidden Persistent Fields
The prompt must explicitly forbid output fields or prose claims equivalent to:

- `final_mastery_level`
- `promotion_applied`
- `demotion_applied`
- `review_due_at`
- `notification_schedule`
- `control_status`
- `recovery_mode`
- `goal_completed`
- `official_score`
- `certified`
- `entitlement`
- `quota_state`
- `billing_state`
- `release_approval`
- `release_ready`
- `product_base_merge_approved`

### Developer Prompt Skeleton
```text
You are generating a candidate explanation for a deterministic goal-autopilot mastery transition.
Return JSON only. Use schema_version=1 and output_type=followup_b_mastery_transition_explanation_candidate.

You may:
- explain the supplied deterministic L0-L5 transition result;
- summarize accepted evidence using only redacted aggregate facts;
- produce one short learner-visible explanation and one optional safety note.

You must not:
- decide the transition;
- write final mastery, review schedule, notification schedule, recovery mode, control state, goal completion, entitlement, quota or billing fields;
- claim official IELTS/TOEFL score equivalence or certification;
- expose raw transcript, raw audio, provider payload or sensitive diagnostic details.
```

### Validation Requirement
- JSON parse must pass.
- `output_type` must be `followup_b_mastery_transition_explanation_candidate`.
- `previous_level`, `proposed_level` and `accepted_level` must be L0-L5 and match deterministic input values.
- `transition_direction` must match deterministic input and be `promote`, `demote`, `hold` or `reject`.
- `guardrails.official_score_equivalence` must be false.
- `guardrails.persistent_decision_fields_present` must be false and `forbidden_fields_detected` must be empty for successful consumption.
- Any forbidden persistent field, official-score claim, raw transcript/audio/provider payload or unknown top-level field must trigger deterministic fallback and must not update `MasteryTransitionDecision` or `MemoryItemPolicyState`.

## P0.2 Followup-C Forecast Explanation Boundary

### Purpose
Followup-C S001 uses deterministic forecast policy as the source of truth for gap, ETA range/unavailable reason, confidence, risk reason, next checkpoint and claim guard. Any provider-backed forecast explanation is candidate-only and is optional for S001; if provider use is not configured, the backend must return deterministic explanation metadata and a clear fallback reason.

### Owning Product Object
| 字段 | 值 |
| --- | --- |
| Increment | `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/` |
| Acceptance | `AC-P02-FUC-001` |
| Test cases | `TC-P02-FUC-003` |
| Domain input | `ProgressForecast` in `docs/domain/domain_schema.md` |
| API input | `GET /goal-autopilot/forecast` and summary forecast fragment in `docs/architecture/openapi/speakeasy-api.yaml` |

### Required Inputs
- `forecast_id`
- `goal_profile_id`
- `source_goal_revision`
- `forecast_state`
- `gap_summary`
- `eta_range` or `eta_unavailable_reason`
- `confidence_band`
- `risk_level`
- `risk_reason_code`
- `next_checkpoint_date`
- `claim_guard`
- `rule_version`

### Output Requirement
If a model is used, it must return valid JSON matching `FollowupCForecastExplanationCandidate` in `docs/ai_runtime/llm_output_schema.md`. S001's local implementation may instead return deterministic fallback metadata with `explanation_source=deterministic_policy`.

### Prompt Rules
- Return JSON only; do not wrap JSON in markdown.
- Explain only the supplied deterministic forecast decision.
- Use product-internal progress language; do not imply official IELTS/TOEFL certification, official score equivalence, guaranteed outcome or guaranteed ETA.
- Do not include raw transcript, raw audio, provider payload, provider name, provider secret, exact sensitive diagnostic details or unrestricted personal data.
- Do not output or imply entitlement, quota, billing, goal completion, plan state, checkpoint status, release approval, Product Base merge approval or persistent forecast fields.

### Validation Requirement
- JSON parse must pass if a provider candidate is present.
- `output_type` must be `followup_c_forecast_explanation_candidate`.
- `forecast_state` and `risk_reason_code` must echo deterministic input values.
- `guardrails.official_score_equivalence`, `guardrails.goal_completion_claim_allowed` and `guardrails.guaranteed_eta_claim_allowed` must be false.
- `guardrails.persistent_decision_fields_present` must be false and `forbidden_fields_detected` must be empty for successful consumption.
- Any forbidden persistent field, official-score claim, guaranteed ETA claim, raw transcript/audio/provider payload or unknown top-level field must trigger deterministic fallback and must not update `ProgressForecast`, `GoalProfile`, `OutcomeCheckpoint`, plan state, entitlement, billing, release or Product Base facts.

## P0.2 Followup-C Checkpoint Task Boundary

Followup-C S002 has no live provider prompt path. `CheckpointCadenceDecision` and `CheckpointTaskDefinition` are selected by deterministic backend policy from goal type, support status, content coverage, latest backplan/checkpoint dates and entitlement/quota/cost fallback inputs.

AI output may explain checkpoint feedback only after a submitted checkpoint, but it must not choose cadence, due status, task type, evidence requirements, rubric boundary, `ai_depth`, entitlement, quota, cost state or goal completion.

Followup-C S003 checkpoint-to-plan update is deterministic by default. If a future provider candidate explains checkpoint feedback, it may only propose learner-visible wording from already accepted checkpoint facts. It must not set `OutcomeCheckpoint.result_status`, `plan_update_signal`, `source_checkpoint_id`, replay/audit hashes, stale/replan status, control compatibility, next action, ETA precision or goal completion. Backend deterministic rules remain the only source of truth for checkpoint result status, forecast recompute, stale/replan signal and no-false-completion guard.

Followup-C S004 goal-progress projection has no live provider prompt path. `GoalProgressProjection` and `GoalProgressSurfaceFragment` are selected by deterministic backend policy from accepted goal, control, next-action, forecast and checkpoint facts. AI output must not set projection state, surface eligibility, downgrade reason, source refs, safe fields, final goal state, claim guard, ETA precision, Home/Queue/Wiki progress facts or deletion/unavailable behavior.

## P0.2 Followup-E Speaking Diagnostic Candidate Boundary

### Purpose
Followup-E may use ASR, pronunciation/scoring and LLM providers to generate candidate transcript, acoustic signal and learner-visible diagnostic explanation for a short Speaking Check. Providers are not the source of truth for `DiagnosticAssessment`, `audio_ref`, diagnostic mode, confidence band, GoalProfile, GoalBackplan, forecast, checkpoint, entitlement, quota, billing, release or Product Base state.

### Owning Product Object
| 字段 | 值 |
| --- | --- |
| Increment | `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/` |
| Requirements | `P02-FUE-FR-004`, `P02-FUE-FR-005`, `P02-FUE-FR-006`, `P02-FUE-FR-007`, `P02-FUE-FR-009` |
| Spec | `P02-FUE-SPEC-004`, `P02-FUE-SPEC-005`, `P02-FUE-SPEC-006`, `P02-FUE-SPEC-007`, `P02-FUE-SPEC-009` |
| Domain input | `DiagnosticAudioSample`, `DiagnosticQualityGate`, `SpeakingDiagnosticAssessment` in `docs/domain/domain_schema.md` |
| API input | Planned diagnostic upload and assessment API family in `docs/architecture/api_contract.md` |

### Required Inputs
- `schema_version`
- `diagnostic_id`
- `goal_profile_id`
- `goal_revision`
- `diagnostic_mode`
- `confidence_band`
- `sample_set_summary`
- `accepted_audio_sample_count`
- `text_sample_count`
- `quality_gate_summary`
- `transcript_source_summary`
- `supported_goal_context`
- `claim_guard`
- `rule_version`
- redacted `source_refs` only, never raw audio, signed URLs or full provider payloads

### Output Requirement
If a model is used for learner-visible diagnosis, it must return valid JSON matching `FollowupESpeakingDiagnosticCandidate` in `docs/ai_runtime/llm_output_schema.md`. Backend deterministic validation must decide whether the candidate can be rendered. A provider candidate must never create or update the accepted diagnostic fact by itself.

### Prompt Rules
- Return JSON only; do not wrap JSON in markdown.
- Explain only the supplied accepted or candidate diagnostic facts.
- Use product-internal speaking practice wording; do not imply official IELTS/TOEFL/CEFR score, certification, guaranteed outcome or guaranteed ETA.
- Do not include raw audio, local file path, full signed URL, raw transcript beyond redacted excerpts allowed by policy, provider payload, provider name, provider secret or unrestricted sensitive diagnostic detail.
- For `text_only`, do not mention pronunciation, intonation, speech rate, pause timing, clipping, noise or acoustic fluency as measured facts.
- For `audio_partial`, name the evidence limitation and keep confidence conservative.
- Do not output or imply GoalBackplan approval, forecast precision, checkpoint result, mastery level, entitlement, quota, billing, release approval or Product Base merge approval.

### Forbidden Persistent Fields
The prompt must explicitly forbid output fields or prose claims equivalent to:

- `audio_ref`
- `trusted_upload_state`
- `diagnostic_mode_override`
- `confidence_band_override`
- `goal_profile_update`
- `goal_backplan_update`
- `forecast_state`
- `checkpoint_result`
- `final_mastery_level`
- `official_score`
- `cefr_level_certified`
- `ielts_band`
- `toefl_score`
- `goal_completed`
- `guaranteed_eta`
- `entitlement`
- `quota_state`
- `billing_state`
- `release_approval`
- `release_ready`
- `product_base_merge_approved`

### Developer Prompt Skeleton
```text
You are generating a candidate explanation for a product-internal speaking diagnostic.
Return JSON only. Use schema_version=1 and output_type=followup_e_speaking_diagnostic_candidate.

You may:
- summarize supplied accepted diagnostic facts;
- name one to three learner-actionable weaknesses;
- propose one next training focus from the supplied allowed categories;
- explain why confidence is limited when diagnostic_mode is audio_partial or text_only.

You must not:
- create or alter audio_ref, diagnostic_mode, confidence_band, accepted samples, GoalProfile, GoalBackplan, forecast, checkpoint, entitlement, quota, billing, release or Product Base state;
- claim official score equivalence, certification, goal completion, guaranteed outcome or precise ETA;
- infer acoustic pronunciation, intonation, speech-rate or pause timing from text_only input;
- expose raw audio, signed URLs, raw provider payload, provider secrets or unrestricted sensitive transcript.
```

### Validation Requirement
- JSON parse must pass.
- `output_type` must be `followup_e_speaking_diagnostic_candidate`.
- `diagnostic_id`, `goal_profile_id`, `goal_revision`, `diagnostic_mode`, `confidence_band` and sample counts must echo backend input values.
- `diagnostic_mode` must be `audio_full`, `audio_partial` or `text_only`; `confidence_band` must be `high`, `medium` or `low`.
- `top_weaknesses` must contain 1-3 learner-actionable items and must be compatible with the diagnostic mode.
- `next_training_focus.category` must be one of the backend-supplied allowed categories.
- `guardrails.official_score_equivalence`, `guardrails.goal_completion_claim_allowed`, `guardrails.guaranteed_eta_claim_allowed` and `guardrails.persistent_decision_fields_present` must be false.
- Any forbidden persistent field, official-score claim, guaranteed ETA claim, text-only acoustic claim, raw audio, local file path, signed URL, raw transcript beyond policy, provider payload or unknown top-level field must trigger deterministic fallback and must not update `DiagnosticAssessment`, `DiagnosticAudioSample`, `GoalProfile`, `GoalBackplan`, `ProgressForecast`, `OutcomeCheckpoint`, entitlement, billing, release or Product Base facts.
