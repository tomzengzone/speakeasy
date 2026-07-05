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

- 生成第一个 prompt 后，`session_created -> ai_prompted`。
- learner 提交文本或 transcript 后，`ai_prompted -> learner_answered`。
- AI runtime 收到本轮输入后，`learner_answered -> analyzing`。
- 返回有效 schema 后，`analyzing -> feedback_ready`。
- 需要重试时，`feedback_ready -> awaiting_retry`。
- 当前 action step 满足时，`feedback_ready -> step_completed`。
- 下一个 step 开始时，`step_completed -> ai_prompted`。
- provider 或 schema validation 失败时，任何状态都进入 `fallback`。

## Guardrails
- The AI cannot complete a session without a completed action chain.
- Invalid JSON cannot update mastery or review state.
- Off-topic turns should trigger repair before advancing.

- action chain 未完成时，AI 不能完成 session。
- invalid JSON 不能更新 mastery 或 review state。
- off-topic turn 必须先触发修复流程，不能直接推进。

## P0.1 Training State Machine

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`。

所属增量：`docs/product/increments/p0-1-expression-automation-training/`。

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

完成与 pressure check 路径：

```text
feedback_ready -> pressure_check_ready -> learner_attempting
feedback_ready -> recap_ready -> training_completed
```

Fallback paths:

Fallback 路径：

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

- `training_loading -> micro_action_ready` 要求 official scene、level、action chain step 和当前 micro-action 都有效。
- `learner_attempting -> transcribing` 只适用于语音输入；text fallback 直接进入 `ai_candidate_generating`。
- ASR 失败导致 `transcribing -> recoverable_error` 时，不得把 learner 标记为失败。
- `ai_candidate_generating -> planner_deciding` 要求有效的 `TrainingFeedbackCandidate` schema，或 deterministic fallback candidate。
- `planner_deciding` 只能应用 domain rules 允许的 next actions。
- `feedback_ready -> pressure_check_ready` 必须基于 planner decision，不能基于原始 LLM recommendation。
- 即使 evidence write 之后需要重试，`recap_ready -> training_completed` 也必须保留用户可见 recap。
- 任何 P0.1 state 都不能绕过 evidence rules 创建第三个 scenario、cross-day plan、完整 L0-L5 state、billing state 或 final mastery。
