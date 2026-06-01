# Dialogue State Machine

## States
```text
session_created
ai_prompted
learner_answered
analyzing
feedback_ready
awaiting_retry
step_completed
session_completed
fallback
```

## Transitions
- `session_created -> ai_prompted` when the first prompt is generated.
- `ai_prompted -> learner_answered` when learner submits text or transcript.
- `learner_answered -> analyzing` when AI runtime receives the turn.
- `analyzing -> feedback_ready` when valid schema is returned.
- `feedback_ready -> awaiting_retry` when retry is needed.
- `feedback_ready -> step_completed` when current action step is satisfied.
- `step_completed -> ai_prompted` when next step starts.
- Any state -> `fallback` when provider or schema validation fails.

## Guardrails
- The AI cannot complete a session without a completed action chain.
- Invalid JSON cannot update mastery or review state.
- Off-topic turns should trigger repair before advancing.

## P0.1 Training State Machine

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`。

```text
training_loading
-> micro_action_ready
-> learner_attempting
-> transcribing
-> ai_candidate_generating
-> planner_deciding
-> feedback_ready
-> retry_ready
-> micro_action_ready
```

Completion and pressure paths:

```text
feedback_ready -> pressure_check_ready -> learner_attempting
feedback_ready -> recap_ready -> training_completed
```

Fallback paths:

```text
transcribing -> recoverable_error -> learner_attempting
ai_candidate_generating -> recoverable_error -> planner_deciding
planner_deciding -> retry_ready
recap_ready -> evidence_write_retryable
```

## P0.1 Transition Guards

- `training_loading -> micro_action_ready` requires valid official scene, level, action chain step and current micro-action.
- `learner_attempting -> transcribing` applies only to voice input; text fallback goes directly to `ai_candidate_generating`.
- `transcribing -> recoverable_error` on ASR failure must not set learner failure.
- `ai_candidate_generating -> planner_deciding` requires valid `TrainingFeedbackCandidate` schema or deterministic fallback candidate.
- `planner_deciding` may only apply allowed next actions from domain rules.
- `feedback_ready -> pressure_check_ready` requires planner decision, not raw LLM recommendation.
- `recap_ready -> training_completed` must preserve user-visible recap even if evidence write later retries.
- No P0.1 state may create a third scenario, cross-day plan, complete L0-L5 state, billing state, or final mastery without evidence rules.
