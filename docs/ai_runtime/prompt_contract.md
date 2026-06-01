# Prompt Contract

## Purpose
Define how AI runtime prompts are structured and how responses are validated.

Owning increments:
- `docs/product/increments/mvp-backend-practice-ai/` for Product Base coach feedback candidate generation.
- `docs/product/increments/p0-1-expression-automation-training/` for P0.1 structured training feedback, hint, retry, next action candidate, and pressure prompt candidate generation.

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
