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

