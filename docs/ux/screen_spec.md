# Screen Spec

## Required Screen Spec Fields
Every new screen must define:

每个新 screen 必须定义以下内容：

- purpose
- entry points
- primary user action
- core components
- states
- API dependencies
- empty state
- loading state
- error state
- analytics or logging events if needed
- acceptance criteria mapping

- purpose：页面目的。
- entry points：入口来源。
- primary user action：用户的主要动作。
- core components：核心组件。
- states：页面状态。
- API dependencies：API 依赖。
- empty state：空状态。
- loading state：加载状态。
- error state：错误状态。
- analytics or logging events if needed：需要时定义分析或日志事件。
- acceptance criteria mapping：验收标准映射。

## MVP Screens

### Scenario List
- Purpose: choose a scenario.
- States: loading, loaded, empty, error.
- Primary action: open scenario detail or practice.

- 目的：选择一个场景。
- 状态：loading, loaded, empty, error。
- 主要动作：打开场景详情或开始练习。

### Practice
- Purpose: complete a guided scenario.
- States: idle, submitting, analyzing, feedback_shown, retry_needed, completed, error.
- Primary action: submit learner turn.

- 目的：完成一个引导式场景。
- 状态：idle, submitting, analyzing, feedback_shown, retry_needed, completed, error。
- 主要动作：提交学习者当前轮回答。

## P0.1 Expression Automation Training Screen

Owning increment: `p0-1-expression-automation-training`。

归属增量：`p0-1-expression-automation-training`。

### Training Session
- Purpose: guide the learner through one session内 micro-action at a time so target expressions can be practiced, retried, lightly pressured, and recapped without open-ended task overload.
- Entry points: `job_interview` or `onboarding_introduction` official scenario detail, current scenario practice entry, unfinished P0.1 session resume entry.
- Primary user action: complete the current micro-action by listening, choosing, speaking, shadowing, filling, or continuing under prompt.
- Core components: session header, current action chain step label, one active micro-action panel, target expression or prompt, hint ladder surface, voice recorder controls, text fallback field, feedback card, retry/continue action, pressure check prompt, recap summary, recoverable error banner.
- States: `loading`, `ready`, `listening`, `recording`, `transcribing`, `evaluating`, `feedback`, `retry`, `pressure_check`, `recap`, `recoverable_error`, `unsupported_scene`.
- API dependencies: Product Base/production Training uses the backend Training API as the source of truth: `POST /training/sessions`, `GET /training/sessions/{session_id}`, `POST /training/sessions/{session_id}/turns`, planner/hint/pressure-check endpoints and `POST /training/sessions/{session_id}/complete`. If backend Training is disabled or unavailable, the screen must show service-unavailable or close the entry; it must not create a local draft session, local planner decision, synthetic feedback or `pending_local_write` evidence. AI dependencies are backend-owned feedback candidates from `docs/ai_runtime/llm_output_schema.md`; ASR/TTS/scoring use the backend AI gateway or backend deterministic test provider.
- Empty state: if no valid action chain or target expression is available for the selected official scene, show a recoverable unavailable state and route back to scenario detail; do not create a fake third scene or arbitrary prompt.
- Loading state: show that scene, level, action step, history and audio resources are loading; keep the previous resumable state if available.
- Error state: preserve learner input or audio reference when possible; ASR failure offers retry recording or text fallback; LLM/schema failure offers deterministic retry/fallback; evidence write failure preserves recap and marks write-back retryable.
- Acceptance criteria mapping: AC-P01-001, AC-P01-002, AC-P01-003, AC-P01-004, AC-P01-005, AC-P01-006, AC-P01-007, AC-P01-008, AC-P01-009, AC-P01-010, AC-P01-011, AC-P01-012, AC-P01-014, AC-P01-015, AC-P01-016, AC-P01-017, AC-P01-018, AC-P01-019.

- 目的：在一个 session 内一次引导一个微动作，让目标表达可以被练习、重试、轻量加压和回顾，同时避免开放式任务过载。
- 入口：`job_interview` 或 `onboarding_introduction` 官方场景详情、当前场景练习入口、未完成 P0.1 session 继续入口。
- 主要用户动作：通过听、选择、说、跟读、填空或根据提示继续，完成当前微动作。
- 核心组件：session 头部、当前动作链步骤标签、一个活动微动作面板、目标表达或提示、提示阶梯区域、语音录制控件、文本兜底输入框、反馈卡片、重试或继续动作、pressure check 提示、回顾摘要、可恢复错误横幅。
- 状态：`loading`, `ready`, `listening`, `recording`, `transcribing`, `evaluating`, `feedback`, `retry`, `pressure_check`, `recap`, `recoverable_error`, `unsupported_scene`。
- API 依赖：Product Base/production Training 以 backend Training API 为事实源：`POST /training/sessions`, `GET /training/sessions/{session_id}`, `POST /training/sessions/{session_id}/turns`, planner/hint/pressure-check endpoints 和 `POST /training/sessions/{session_id}/complete`。如果 backend Training 被禁用或不可用，页面必须显示服务不可用或关闭入口；不得创建本地草稿 session、本地 planner 决策、合成反馈或 `pending_local_write` 证据。AI 依赖是来自 `docs/ai_runtime/llm_output_schema.md` 的后端反馈候选；ASR/TTS/scoring 使用后端 AI gateway 或后端确定性测试 provider。
- 空状态：如果所选官方场景没有有效动作链或目标表达，显示可恢复的不可用状态并返回场景详情；不得创建假的第三场景或任意 prompt。
- 加载状态：显示场景、等级、动作步骤、历史和音频资源正在加载；如有可继续状态则保持上一状态。
- 错误状态：尽可能保留学习者输入或音频引用；ASR 失败提供重新录音或文本兜底；LLM/schema 失败提供确定性重试或兜底；证据写入失败时保留回顾内容并标记回写可重试。
- 验收标准映射：AC-P01-001, AC-P01-002, AC-P01-003, AC-P01-004, AC-P01-005, AC-P01-006, AC-P01-007, AC-P01-008, AC-P01-009, AC-P01-010, AC-P01-011, AC-P01-012, AC-P01-014, AC-P01-015, AC-P01-016, AC-P01-017, AC-P01-018, AC-P01-019。

### Training Session State Contract
| State | User sees | Primary action | Next states |
| --- | --- | --- | --- |
| `loading` | Loading indicator for scene/session | wait or leave | `ready`, `recoverable_error`, `unsupported_scene` |
| `ready` | One micro-action instruction and current hint if any | start/listen/answer | `listening`, `recording`, `feedback` |
| `listening` | Playback for model prompt or target expression | replay, continue, report failure | `ready`, `recording`, `recoverable_error` |
| `recording` | Recorder, cancel, submit, elapsed time | submit or cancel | `transcribing`, `ready` |
| `transcribing` | Processing voice input | wait | `evaluating`, `retry`, `recoverable_error` |
| `evaluating` | Feedback is being prepared | wait | `feedback`, `recoverable_error` |
| `feedback` | Concise feedback card and next action | retry, continue, pressure check, recap | `retry`, `ready`, `pressure_check`, `recap` |
| `retry` | Same action with raised or adjusted hint | answer again | `ready`, `listening`, `recording` |
| `pressure_check` | Short follow-up or near-scene prompt with reduced hint | answer under prompt | `recording`, `feedback`, `recap` |
| `recap` | Summary, one next focus, evidence write status | finish | terminal |
| `recoverable_error` | What failed and what can be done next | retry, text fallback, exit, view recap | previous valid state, `retry`, `recap` |
| `unsupported_scene` | P0.1 training unavailable for this scene | return to scenario detail | terminal |

| 状态 | 用户看到 | 主要动作 | 后续状态 |
| --- | --- | --- | --- |
| `loading` | 场景或 session 的加载指示 | 等待或离开 | `ready`, `recoverable_error`, `unsupported_scene` |
| `ready` | 一个微动作说明和当前提示（如有） | 开始、听或回答 | `listening`, `recording`, `feedback` |
| `listening` | 示范提示或目标表达的播放控件 | 重播、继续、报告失败 | `ready`, `recording`, `recoverable_error` |
| `recording` | 录音器、取消、提交和已录时长 | 提交或取消 | `transcribing`, `ready` |
| `transcribing` | 语音输入正在处理 | 等待 | `evaluating`, `retry`, `recoverable_error` |
| `evaluating` | 反馈正在准备 | 等待 | `feedback`, `recoverable_error` |
| `feedback` | 简短反馈卡片和下一步动作 | 重试、继续、pressure check 或回顾 | `retry`, `ready`, `pressure_check`, `recap` |
| `retry` | 同一动作，并提高或调整提示 | 再次回答 | `ready`, `listening`, `recording` |
| `pressure_check` | 降低提示的简短追问或近场景 prompt | 根据提示回答 | `recording`, `feedback`, `recap` |
| `recap` | 摘要、一个下一重点和证据写入状态 | 完成 | terminal |
| `recoverable_error` | 失败原因和可用下一步 | 重试、文本兜底、退出或查看回顾 | 上一个有效状态, `retry`, `recap` |
| `unsupported_scene` | 当前场景不可用 P0.1 训练 | 返回场景详情 | terminal |

### Micro-action Component Contract
| Micro-action | Required UI | Fallback |
| --- | --- | --- |
| `ListenOne` | play/replay target expression or prompt; continue control | show text if audio/TTS fails |
| `ChooseOne` | options list with one submit action | explain mismatch and retry |
| `SayOne` | recorder, cancel, submit, re-record, optional text fallback after failure | text fallback only after mic/ASR issue or debug mode |
| `ShadowOne` | model audio/chunk, recorder, replay | model-then-retry if score unavailable or low confidence |
| `FillOne` | sentence frame or missing chunk input | options or sentence frame hint |
| `ContinueUnderPrompt` | short pressure prompt and recorder | downgrade to `SayOne` or higher hint |

| 微动作 | 必需 UI | 兜底 |
| --- | --- | --- |
| `ListenOne` | 播放或重播目标表达或 prompt；继续控件 | audio/TTS 失败时显示文本 |
| `ChooseOne` | 选项列表和单一提交动作 | 解释不匹配并允许重试 |
| `SayOne` | 录音器、取消、提交、重新录制、失败后的可选文本兜底 | 仅在麦克风/ASR 问题或调试模式下提供文本兜底 |
| `ShadowOne` | 示范音频或分块、录音器、重播 | 分数不可用或低置信度时改为示范后重试 |
| `FillOne` | 句子框架或缺失片段输入 | 选项或句子框架提示 |
| `ContinueUnderPrompt` | 简短 pressure prompt 和录音器 | 降级为 `SayOne` 或提高提示 |

### Feedback And Recap Contract
- Feedback card shows at most one main issue, one better expression, and one immediate next action.
- Pronunciation appears only when score signal is available; unavailable score must not block the session.
- Hint level changes must be visible through the current prompt, sentence frame, options, chunk shadowing or model-then-retry UI.
- Recap must remain visible even when learning evidence write-back is retryable or delayed.
- The screen must not display cross-day scheduling, full L0-L5 mastery, third-scene creation, arbitrary scene generation, commercial entitlement status, or billing state as P0.1 completion proof.

- 反馈卡片最多展示一个主要问题、一个更好的表达和一个立即可执行的下一步。
- 发音相关内容只在有评分信号时出现；评分不可用不得阻断 session。
- 提示等级变化必须通过当前 prompt、句子框架、选项、分块跟读或示范后重试 UI 表现出来。
- 即使学习证据回写可重试或延迟，回顾内容也必须保持可见。
- 页面不得把跨天排期、完整 L0-L5 掌握、第三场景创建、任意场景生成、商业权益状态或计费状态展示为 P0.1 完成证明。

## P0.2 Goal Autopilot Screens

Owning stage: `docs/product/stages/p0-2-training-memory.md`。
Owning increments: `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint`。

归属阶段：`docs/product/stages/p0-2-training-memory.md`。
归属增量：`p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint`。

### Goal Setup And Diagnostic
- Purpose: capture the learner's target, deadline, daily time and intensity, then show supported/partial/unsupported status and diagnostic confidence.
- Entry points: onboarding completion, home goal setup entry, profile goal edit entry, unsupported/partial plan recovery entry.
- Primary user action: submit or revise the goal and provide diagnostic samples when required.
- Core components: goal type picker, target score/ability input, deadline input, daily minutes input, intensity selector, support status panel, diagnostic confidence panel, weakness tags, claim guard note, continue-to-plan action.
- States: `draft`, `checking_support`, `supported`, `partial_supported`, `unsupported`, `collecting_diagnostic`, `evaluating_diagnostic`, `diagnostic_complete`, `low_confidence`, `recoverable_error`.
- API dependencies: `POST /goal-autopilot/goals`, `GET /goal-autopilot/summary`. Diagnostic AI output follows `docs/ai_runtime/llm_output_schema.md#P0.2-Goal-Autopilot-Candidate-Schemas` and is candidate-only.
- Empty state: no active goal; show compact goal setup form, not a marketing page.
- Loading state: support check and diagnostic evaluation disable duplicate submit while keeping entered goal facts visible.
- Error state: provider/schema failure shows retry or conservative low-confidence path; unsupported goals show limitation and do not create a full plan.
- Acceptance criteria mapping: P0.2 diagnostic ACs for P02-DIAG-FR-001 through P02-DIAG-FR-007.

- 目的：收集学习者目标、截止日期、每日时间和强度，然后展示 supported/partial/unsupported 状态与诊断置信度。
- 入口：onboarding 完成、home 目标设置入口、profile 目标编辑入口、unsupported/partial 计划恢复入口。
- 主要用户动作：提交或修改目标，并在需要时提供诊断样本。
- 核心组件：目标类型选择器、目标分数/能力输入、截止日期输入、每日分钟数输入、强度选择器、支持状态面板、诊断置信度面板、薄弱项标签、承诺防护说明、继续到计划动作。
- 状态：`draft`, `checking_support`, `supported`, `partial_supported`, `unsupported`, `collecting_diagnostic`, `evaluating_diagnostic`, `diagnostic_complete`, `low_confidence`, `recoverable_error`。
- API 依赖：`POST /goal-autopilot/goals`, `GET /goal-autopilot/summary`。诊断 AI 输出遵循 `docs/ai_runtime/llm_output_schema.md#P0.2-Goal-Autopilot-Candidate-Schemas`，且仅作为候选。
- 空状态：没有 active goal；展示紧凑的目标设置表单，而不是营销页。
- 加载状态：支持检查和诊断评估期间禁用重复提交，同时保持已输入的目标事实可见。
- 错误状态：provider/schema 失败时展示重试或保守低置信度路径；unsupported 目标展示限制，不创建完整计划。
- 验收标准映射：P0.2 diagnostic ACs for P02-DIAG-FR-001 through P02-DIAG-FR-007。

### Daily Autopilot
- Purpose: show one primary action so the learner does not manually decide what to practice next.
- Entry points: app home, active goal summary, due review, missed-day recovery, checkpoint due banner.
- Primary user action: start the selected training/review/checkpoint item; secondary controls are pause, defer, lower intensity and resume.
- Core components: goal progress header, next action block, reason code, expected duration, daily plan compact list, pause/defer controls, partial/unsupported limitation state, quiet-hours state.
- States: `loading`, `ready`, `paused`, `quiet_hours`, `stale_plan`, `unsupported_or_partial`, `executing`, `completed`, `deferred`, `recovery_required`, `recoverable_error`.
- API dependencies: `GET /goal-autopilot/progress-projection`, `GET /goal-autopilot/summary`, `POST /goal-autopilot/plans/generate`, `GET /goal-autopilot/daily-plan`, `GET /goal-autopilot/actions/next`, `POST /goal-autopilot/actions/{plan_item_id}/complete`.
- Followup-C S004/S005 boundary: goal progress header, next action affordance, gap/risk/checkpoint summary, surface eligibility and downgrade reason must render from `GoalProgressProjection`; Flutter must not compute final goal state, ETA precision, goal completion or claim guards locally.
- Followup-C S006 boundary: deleted, unavailable, unsupported, stale or control-blocked projection fragments render only backend state/reason and must clear cached gap, action, checkpoint conclusion, precise ETA and completion copy. Partial and low-confidence eligible fragments may show backend downgrade reason plus allowed safe fields, but still cannot show precise ETA or goal-complete copy.
- Empty state: no active plan; if supported goal exists, offer generate plan; otherwise route to goal setup.
- Loading state: show current cached summary as stale only while authenticated and not after deleted/unavailable projection state; avoid local plan computation.
- Error state: stale plan, quota, policy or provider failure shows retry/replan/defer; Flutter must not synthesize next action or final mastery locally.
- Acceptance criteria mapping: P0.2 plan/autopilot ACs for P02-PLAN-FR-001 through P02-PLAN-FR-008 and P02-AUTO-FR-001 through P02-AUTO-FR-003.

- 目的：展示一个主要动作，让学习者不需要手动决定下一步练什么。
- 入口：app home、active goal summary、due review、missed-day recovery、checkpoint due banner。
- 主要用户动作：开始选定的 training/review/checkpoint item；次要控制包括 pause、defer、lower intensity 和 resume。
- 核心组件：目标进度头部、下一动作区块、原因代码、预期时长、每日计划紧凑列表、pause/defer 控件、partial/unsupported 限制状态、quiet-hours 状态。
- 状态：`loading`, `ready`, `paused`, `quiet_hours`, `stale_plan`, `unsupported_or_partial`, `executing`, `completed`, `deferred`, `recovery_required`, `recoverable_error`。
- API 依赖：`GET /goal-autopilot/progress-projection`, `GET /goal-autopilot/summary`, `POST /goal-autopilot/plans/generate`, `GET /goal-autopilot/daily-plan`, `GET /goal-autopilot/actions/next`, `POST /goal-autopilot/actions/{plan_item_id}/complete`。
- Followup-C S004/S005 边界：目标进度头部、下一动作 affordance、gap/risk/checkpoint summary、surface eligibility 和 downgrade reason 必须从 `GoalProgressProjection` 渲染；Flutter 不得在本地计算最终目标状态、ETA 精度、目标完成或 claim guards。
- Followup-C S006 边界：deleted、unavailable、unsupported、stale 或 control-blocked projection fragments 只渲染后端 state/reason，并且必须清除缓存的 gap、action、checkpoint conclusion、precise ETA 和 completion copy。Partial 和 low-confidence eligible fragments 可以展示后端 downgrade reason 以及允许的安全字段，但仍不得展示 precise ETA 或 goal-complete copy。
- 空状态：没有 active plan；如果存在 supported goal，则提供生成计划动作；否则跳转到目标设置。
- 加载状态：只在已认证且不是 deleted/unavailable projection state 时，将当前缓存 summary 显示为 stale；避免本地计划计算。
- 错误状态：stale plan、quota、policy 或 provider 失败时展示 retry/replan/defer；Flutter 不得在本地合成下一动作或最终 mastery。
- 验收标准映射：P0.2 plan/autopilot ACs for P02-PLAN-FR-001 through P02-PLAN-FR-008 and P02-AUTO-FR-001 through P02-AUTO-FR-003。

### Progress Forecast And Checkpoint
- Purpose: show target gap, ETA confidence, risk and next checkpoint, and collect weekly/biweekly checkpoint results.
- Entry points: daily autopilot completion, progress surface, due checkpoint action, profile goal progress entry.
- Primary user action: review forecast or submit checkpoint result when due.
- Core components: gap summary, ETA/date or uncertainty state, risk reason, next checkpoint date, latest checkpoint summary, checkpoint submit action, plan update signal.
- States: `loading`, `current`, `low_confidence`, `partial_supported`, `checkpoint_due`, `submitting_checkpoint`, `checkpoint_recorded`, `plan_update_required`, `recoverable_error`.
- API dependencies: `GET /goal-autopilot/progress-projection`, `GET /goal-autopilot/forecast`, `GET /goal-autopilot/checkpoints/task`, `POST /goal-autopilot/checkpoints`, `GET /goal-autopilot/summary`.
- Followup-C S002 boundary: checkpoint due/not-due/limited/unavailable state, task type, evidence requirements, scoring boundary and limitation reason are rendered from the backend task decision; the UI must not infer cadence or full-task eligibility locally.
- Followup-C S003 boundary: after checkpoint submit, UI must render `OutcomeCheckpoint.result_status`, `plan_update_signal.signal_type`, `plan_update_signal.reason_code` and optional replay metadata from the backend response; it must not infer goal completion, ETA precision, stale/replan status or next-action advancement locally. Paused/control-blocked/recovery-required/stale responses show the backend reason and route to replan/recovery instead of auto-starting the next action.
- Followup-C S005 boundary: Home panel, expression queue and personal Wiki progress fragments read `surface_fragments` and safe projection fields from `GET /goal-autopilot/progress-projection`; queue ordering remains owned by the queue contract/coordinator and raw diagnostic transcript/audio, sensitive target details, raw checkpoint payloads, provider payloads, ETA and goal-completion claims are not display dependencies.
- Followup-C S006 boundary: when projection state is deleted/unavailable/unsupported/stale/control-blocked, the UI must replace any previously rendered progress fragment with the backend downgrade reason and omit stale gap, ETA, checkpoint conclusion and next action refs. Partial/low-confidence fragments must display the backend reason rather than locally inferring a final state.
- Empty state: no forecast until active goal, diagnostic and plan exist; show required upstream step.
- Loading state: recompute or submit keeps previous forecast visible as stale.
- Error state: low confidence and partial support block high-precision ETA; checkpoint failure can be retried without claiming goal completion.
- Acceptance criteria mapping: P0.2 forecast/checkpoint ACs for P02-AUTO-FR-004 through P02-AUTO-FR-008.

- 目的：展示目标差距、ETA 置信度、风险和下一次 checkpoint，并收集每周或双周 checkpoint 结果。
- 入口：daily autopilot 完成、progress surface、due checkpoint action、profile goal progress 入口。
- 主要用户动作：查看 forecast，或在 checkpoint 到期时提交 checkpoint result。
- 核心组件：gap summary、ETA/date 或 uncertainty state、risk reason、next checkpoint date、latest checkpoint summary、checkpoint submit action、plan update signal。
- 状态：`loading`, `current`, `low_confidence`, `partial_supported`, `checkpoint_due`, `submitting_checkpoint`, `checkpoint_recorded`, `plan_update_required`, `recoverable_error`。
- API 依赖：`GET /goal-autopilot/progress-projection`, `GET /goal-autopilot/forecast`, `GET /goal-autopilot/checkpoints/task`, `POST /goal-autopilot/checkpoints`, `GET /goal-autopilot/summary`。
- Followup-C S002 边界：checkpoint due/not-due/limited/unavailable 状态、task type、evidence requirements、scoring boundary 和 limitation reason 都从后端 task decision 渲染；UI 不得在本地推断 cadence 或 full-task eligibility。
- Followup-C S003 边界：checkpoint 提交后，UI 必须渲染后端响应中的 `OutcomeCheckpoint.result_status`, `plan_update_signal.signal_type`, `plan_update_signal.reason_code` 和可选 replay metadata；不得在本地推断 goal completion、ETA precision、stale/replan status 或 next-action advancement。Paused/control-blocked/recovery-required/stale 响应展示后端 reason，并跳转到 replan/recovery，而不是自动开始下一动作。
- Followup-C S005 边界：Home panel、expression queue 和 personal Wiki progress fragments 从 `GET /goal-autopilot/progress-projection` 读取 `surface_fragments` 和安全 projection fields；queue ordering 仍由 queue contract/coordinator 负责，raw diagnostic transcript/audio、sensitive target details、raw checkpoint payloads、provider payloads、ETA 和 goal-completion claims 不是展示依赖。
- Followup-C S006 边界：当 projection state 是 deleted/unavailable/unsupported/stale/control-blocked 时，UI 必须用后端 downgrade reason 替换任何已渲染的 progress fragment，并省略 stale gap、ETA、checkpoint conclusion 和 next action refs。Partial/low-confidence fragments 必须展示后端 reason，而不是本地推断最终状态。
- 空状态：active goal、diagnostic 和 plan 都存在后才显示 forecast；否则展示必需的上游步骤。
- 加载状态：recompute 或 submit 时保留上一 forecast，并标记为 stale。
- 错误状态：low confidence 和 partial support 阻止高精度 ETA；checkpoint 失败可重试，但不得声称目标已完成。
- 验收标准映射：P0.2 forecast/checkpoint ACs for P02-AUTO-FR-004 through P02-AUTO-FR-008。

### Followup-B Autopilot Control And Recovery

Owning increment: `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

归属增量：`docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

- Purpose: let the learner understand and safely control automatic guidance without Flutter inventing control, reminder, recovery, memory or mastery state locally.
- Entry points: Daily Autopilot next-action card, goal summary control chip, paused banner, quiet-hours blocked reminder entry, notification-disabled banner, missed-day recovery banner, memory/mastery explanation entry.
- Primary user action: pause, resume, adjust intensity, set quiet hours, enable/disable reminder consent, choose server-returned recovery action or view memory/mastery explanation.
- Core components: server control status badge, pause/resume button, intensity segmented control, quiet-hours selector, reminder permission/consent status, next-action impact message, reminder eligibility message, recovery decision card, item-policy reason chip, mastery explanation card, replay-safe audit note.
- States: `control_loading`, `control_active`, `paused`, `resume_checking`, `blocked_by_policy`, `quiet_hours_blocked`, `notification_disabled`, `intensity_updated`, `recovery_required`, `recovery_planned`, `item_policy_due`, `item_policy_blocked`, `mastery_explanation_ready`, `recoverable_error`.
- API dependencies: `GET /goal-autopilot/control`, `PATCH /goal-autopilot/control`, `POST /goal-autopilot/control/pause`, `POST /goal-autopilot/control/resume`, `POST /goal-autopilot/reminders/eligibility`, `GET /goal-autopilot/reminders/outbox`, `POST /goal-autopilot/recovery/replan`, `POST /goal-autopilot/item-policy/decisions`, `GET /goal-autopilot/mastery-transitions`, `GET /goal-autopilot/replay-audits`, plus existing summary/daily-plan/next-action APIs.
- AI dependencies: Followup-B mastery explanation candidate in `docs/ai_runtime/llm_output_schema.md`; UI renders only schema-valid candidate explanation or deterministic fallback. UI must never parse free-form AI text to set state.
- Empty state: if no active goal or no server control exists, route to Goal Setup or show “set up goal first”; do not create a local control object.
- Loading state: keep the previous server state visible as stale while refreshing; disable duplicate pause/resume/update actions until the server response returns.
- Error state: failed pause/resume/update keeps the last known server state; failed reminder eligibility shows reason unknown/retry without treating unsent reminders as missed-day evidence; failed explanation falls back to deterministic reason text.
- Acceptance criteria mapping: AC-P02-FUB-001, AC-P02-FUB-002, AC-P02-FUB-003, AC-P02-FUB-004, AC-P02-FUB-005, AC-P02-FUB-006, AC-P02-FUB-007, AC-P02-FUB-008.

- 目的：让学习者理解并安全控制自动引导，同时避免 Flutter 在本地创造 control、reminder、recovery、memory 或 mastery 状态。
- 入口：Daily Autopilot next-action card、goal summary control chip、paused banner、quiet-hours blocked reminder entry、notification-disabled banner、missed-day recovery banner、memory/mastery explanation entry。
- 主要用户动作：pause、resume、adjust intensity、set quiet hours、enable/disable reminder consent、选择服务端返回的 recovery action，或查看 memory/mastery explanation。
- 核心组件：server control status badge、pause/resume button、intensity segmented control、quiet-hours selector、reminder permission/consent status、next-action impact message、reminder eligibility message、recovery decision card、item-policy reason chip、mastery explanation card、replay-safe audit note。
- 状态：`control_loading`, `control_active`, `paused`, `resume_checking`, `blocked_by_policy`, `quiet_hours_blocked`, `notification_disabled`, `intensity_updated`, `recovery_required`, `recovery_planned`, `item_policy_due`, `item_policy_blocked`, `mastery_explanation_ready`, `recoverable_error`。
- API 依赖：`GET /goal-autopilot/control`, `PATCH /goal-autopilot/control`, `POST /goal-autopilot/control/pause`, `POST /goal-autopilot/control/resume`, `POST /goal-autopilot/reminders/eligibility`, `GET /goal-autopilot/reminders/outbox`, `POST /goal-autopilot/recovery/replan`, `POST /goal-autopilot/item-policy/decisions`, `GET /goal-autopilot/mastery-transitions`, `GET /goal-autopilot/replay-audits`，以及已有 summary/daily-plan/next-action APIs。
- AI 依赖：Followup-B mastery explanation candidate 位于 `docs/ai_runtime/llm_output_schema.md`；UI 只渲染 schema-valid candidate explanation 或 deterministic fallback。UI 绝不能解析 free-form AI text 来设置状态。
- 空状态：如果没有 active goal 或 server control，跳转到 Goal Setup 或展示“set up goal first”；不得创建本地 control object。
- 加载状态：刷新时保持上一服务端状态可见并标记为 stale；在服务端响应返回前禁用重复 pause/resume/update 动作。
- 错误状态：pause/resume/update 失败时保留最近一次已知服务端状态；reminder eligibility 失败时展示 reason unknown/retry，不把未发送 reminder 当成 missed-day evidence；explanation 失败时回退到 deterministic reason text。
- 验收标准映射：AC-P02-FUB-001, AC-P02-FUB-002, AC-P02-FUB-003, AC-P02-FUB-004, AC-P02-FUB-005, AC-P02-FUB-006, AC-P02-FUB-007, AC-P02-FUB-008。

### Followup-B Control State Contract
| State | User sees | Primary action | Data source | Next states |
| --- | --- | --- | --- | --- |
| `control_loading` | Existing state marked refreshing | wait or leave | cached `GET /goal-autopilot/control` response | `control_active`, `paused`, `blocked_by_policy`, `recoverable_error` |
| `control_active` | Next action, active reminder state and compact controls | pause, adjust intensity, edit quiet hours, start action | `UserAutopilotControl.control_status=active` | `paused`, `intensity_updated`, `quiet_hours_blocked`, `notification_disabled`, `recovery_required`, `item_policy_due` |
| `paused` | Paused banner; no new automatic prompts or future reminders | resume or edit settings | `UserAutopilotControl.control_status=paused` | `resume_checking`, `intensity_updated` |
| `resume_checking` | Resume is checking plan freshness, missed days, quiet hours, fatigue, support and entitlement | wait | `POST /goal-autopilot/control/resume` | `control_active`, `recovery_required`, `blocked_by_policy`, `quiet_hours_blocked` |
| `blocked_by_policy` | Clear reason for unsupported, partial without safe plan, stale/missing plan, entitlement or data policy block | view required upstream step or refresh | server reason code | `control_active`, `recovery_required`, terminal blocked state |
| `quiet_hours_blocked` | Reminder not sent now; next allowed time when available | edit quiet hours or wait | `NotificationEligibilityDecision.reason_code=quiet_hours` | `control_active`, `notification_disabled` |
| `notification_disabled` | Reminder disabled by consent or platform permission | open permission guidance or update consent | `NotificationEligibilityDecision.reason_code=permission_denied` or `consent_missing` | `control_active`, `quiet_hours_blocked` |
| `intensity_updated` | Server confirms intensity/quiet hours/consent/policy update and impact | continue or replan if required | `PATCH /goal-autopilot/control` response | `control_active`, `recovery_required`, `blocked_by_policy` |
| `recovery_required` | Missed/skip/defer/pause gap/stale plan needs recovery | request recovery plan | summary/control/recovery reason | `recovery_planned`, `recoverable_error` |
| `recovery_planned` | One recovery mode: compress, defer or replace; no overdue stacking | start returned action | `RecoveryPlanDecision` | `control_active`, `item_policy_due` |
| `item_policy_due` | Why this item is due and how it fits interleaving/overlearning | start review/training | `MemoryItemPolicyState.due_decision` | `mastery_explanation_ready`, `control_active` |
| `item_policy_blocked` | Item skipped/deferred due to overlearning, budget, interleaving or control block | view alternative or continue | `MemoryItemPolicyState.due_decision` | `control_active`, `recovery_required` |
| `mastery_explanation_ready` | Safe L0-L5 internal explanation and evidence summary | continue or view audit note | `MasteryTransitionDecision` plus schema-valid AI candidate/fallback | `control_active` |
| `recoverable_error` | What failed and the last known safe state | retry, refresh, leave | typed API/fallback error | previous valid state |

| 状态 | 用户看到 | 主要动作 | 数据源 | 后续状态 |
| --- | --- | --- | --- | --- |
| `control_loading` | 现有状态被标记为刷新中 | 等待或离开 | 缓存的 `GET /goal-autopilot/control` 响应 | `control_active`, `paused`, `blocked_by_policy`, `recoverable_error` |
| `control_active` | 下一动作、active reminder state 和紧凑控制项 | pause、adjust intensity、edit quiet hours、start action | `UserAutopilotControl.control_status=active` | `paused`, `intensity_updated`, `quiet_hours_blocked`, `notification_disabled`, `recovery_required`, `item_policy_due` |
| `paused` | Paused banner；不会出现新的自动 prompt 或未来 reminder | resume 或 edit settings | `UserAutopilotControl.control_status=paused` | `resume_checking`, `intensity_updated` |
| `resume_checking` | Resume 正在检查计划新鲜度、missed days、quiet hours、fatigue、support 和 entitlement | 等待 | `POST /goal-autopilot/control/resume` | `control_active`, `recovery_required`, `blocked_by_policy`, `quiet_hours_blocked` |
| `blocked_by_policy` | unsupported、partial without safe plan、stale/missing plan、entitlement 或 data policy block 的清晰原因 | 查看所需上游步骤或刷新 | server reason code | `control_active`, `recovery_required`, terminal blocked state |
| `quiet_hours_blocked` | 当前未发送 reminder；可用时显示下一允许时间 | edit quiet hours 或等待 | `NotificationEligibilityDecision.reason_code=quiet_hours` | `control_active`, `notification_disabled` |
| `notification_disabled` | Reminder 被 consent 或 platform permission 禁用 | 打开 permission guidance 或更新 consent | `NotificationEligibilityDecision.reason_code=permission_denied` 或 `consent_missing` | `control_active`, `quiet_hours_blocked` |
| `intensity_updated` | 服务端确认 intensity/quiet hours/consent/policy 更新及其影响 | 继续，或在需要时 replan | `PATCH /goal-autopilot/control` 响应 | `control_active`, `recovery_required`, `blocked_by_policy` |
| `recovery_required` | missed/skip/defer/pause gap/stale plan 需要 recovery | 请求 recovery plan | summary/control/recovery reason | `recovery_planned`, `recoverable_error` |
| `recovery_planned` | 一个 recovery mode：compress、defer 或 replace；不堆叠 overdue tasks | 开始返回的动作 | `RecoveryPlanDecision` | `control_active`, `item_policy_due` |
| `item_policy_due` | 说明该 item 为何 due，以及它如何匹配 interleaving/overlearning | 开始 review/training | `MemoryItemPolicyState.due_decision` | `mastery_explanation_ready`, `control_active` |
| `item_policy_blocked` | item 因 overlearning、budget、interleaving 或 control block 被跳过/延后 | 查看替代项或继续 | `MemoryItemPolicyState.due_decision` | `control_active`, `recovery_required` |
| `mastery_explanation_ready` | 安全的 L0-L5 内部解释和证据摘要 | 继续或查看 audit note | `MasteryTransitionDecision` 加 schema-valid AI candidate/fallback | `control_active` |
| `recoverable_error` | 失败内容和最近一次安全状态 | retry、refresh、leave | typed API/fallback error | 上一个有效状态 |

### Followup-B Interaction Rules
- Pause is idempotent in UI: repeated tap while already paused shows current paused state and does not duplicate cancellation UI.
- Resume never immediately shows reminders or prompts until the server returns active eligibility; while checking, all execution buttons stay disabled.
- Quiet hours that cross midnight must display as a single interval in the configured timezone.
- Notification blocked, failed, expired or unsent states must not be worded as “you missed practice” or “you failed”.
- Intensity override must show impact returned by the API: next action changed, reminder eligibility changed, replan required and reason code.
- Recovery card must show exactly one primary mode: `compress`, `defer` or `replace`; it must not list all overdue tasks as today's work.
- Memory/mastery explanation must say it is an internal practice signal, not official exam certification.
- Any AI explanation marked invalid, forbidden-field rejected or unavailable must be replaced by deterministic fallback copy from reason code; UI must not render raw provider text.
- Replay/audit information is developer/support-facing wording only: show safe “decision can be replayed” status or reason code, not input snapshot contents.

- Pause 在 UI 中是幂等的：已暂停时重复点击只显示当前 paused state，不重复展示取消 UI。
- Resume 不会立即展示 reminders 或 prompts，直到服务端返回 active eligibility；检查期间所有执行按钮保持禁用。
- 跨午夜的 quiet hours 必须按配置 timezone 显示为单一时间段。
- Notification blocked、failed、expired 或 unsent 状态不得写成“you missed practice”或“you failed”。
- Intensity override 必须展示 API 返回的影响：next action changed、reminder eligibility changed、replan required 和 reason code。
- Recovery card 必须只展示一个主要模式：`compress`, `defer` 或 `replace`；不得把所有 overdue tasks 列成今天的任务。
- Memory/mastery explanation 必须说明这是内部练习信号，不是官方考试认证。
- 任何标记为 invalid、forbidden-field rejected 或 unavailable 的 AI explanation 都必须用来自 reason code 的 deterministic fallback copy 替换；UI 不得渲染 raw provider text。
- Replay/audit 信息只使用面向 developer/support 的措辞：展示安全的“decision can be replayed”状态或 reason code，不展示 input snapshot contents。

### Followup-B Test Checklist Contract
| Acceptance | Screen state / behavior | Planned test mapping |
| --- | --- | --- |
| AC-P02-FUB-001 | Server-owned active/paused/policy-blocked state; no local control derivation | TC-P02-FUB-001, TC-P02-FUB-002 |
| AC-P02-FUB-002 | Pause/resume/update-control impact messages and disabled duplicate actions | TC-P02-FUB-003, TC-P02-FUB-004 |
| AC-P02-FUB-003 | Quiet-hours, permission, consent, entitlement, quota, stale/missing plan reason display | TC-P02-FUB-005, TC-P02-FUB-006 |
| AC-P02-FUB-004 | Outbox lifecycle displayed as pending/scheduled/blocked/sent/cancelled/failed/expired without evidence mutation wording | TC-P02-FUB-007, TC-P02-FUB-008 |
| AC-P02-FUB-005 | Missed-day recovery shows compress/defer/replace and no overdue stacking | TC-P02-FUB-009, TC-P02-FUB-010 |
| AC-P02-FUB-006 | Item-level due decision explains overlearning cap, interleaving, budget defer or control block | TC-P02-FUB-011, TC-P02-FUB-012 |
| AC-P02-FUB-007 | L0-L5 explanation uses accepted evidence, supports hold/demotion and rejects AI persistent fields | TC-P02-FUB-013, TC-P02-FUB-014 |
| AC-P02-FUB-008 | Replay/performance/coverage gates remain planned evidence; UI does not mark Followup-B complete | TC-P02-FUB-015, TC-P02-FUB-016, TC-P02-FUB-017 |

| 验收项 | 页面状态 / 行为 | 计划测试映射 |
| --- | --- | --- |
| AC-P02-FUB-001 | 服务端拥有 active/paused/policy-blocked 状态；不做本地 control 派生 | TC-P02-FUB-001, TC-P02-FUB-002 |
| AC-P02-FUB-002 | Pause/resume/update-control 影响消息和禁用重复动作 | TC-P02-FUB-003, TC-P02-FUB-004 |
| AC-P02-FUB-003 | 展示 quiet-hours、permission、consent、entitlement、quota、stale/missing plan 原因 | TC-P02-FUB-005, TC-P02-FUB-006 |
| AC-P02-FUB-004 | Outbox lifecycle 以 pending/scheduled/blocked/sent/cancelled/failed/expired 展示，不使用证据变更措辞 | TC-P02-FUB-007, TC-P02-FUB-008 |
| AC-P02-FUB-005 | Missed-day recovery 展示 compress/defer/replace，且不堆叠 overdue tasks | TC-P02-FUB-009, TC-P02-FUB-010 |
| AC-P02-FUB-006 | Item-level due decision 解释 overlearning cap、interleaving、budget defer 或 control block | TC-P02-FUB-011, TC-P02-FUB-012 |
| AC-P02-FUB-007 | L0-L5 explanation 使用已接受证据，支持 hold/demotion，并拒绝 AI persistent fields | TC-P02-FUB-013, TC-P02-FUB-014 |
| AC-P02-FUB-008 | Replay/performance/coverage gates 仍是 planned evidence；UI 不把 Followup-B 标记为 complete | TC-P02-FUB-015, TC-P02-FUB-016, TC-P02-FUB-017 |

### Followup-D Consent And Privacy UX

Owning increment: `docs/product/increments/p0-2-followup-d-release-gate-hardening/`。

归属增量：`docs/product/increments/p0-2-followup-d-release-gate-hardening/`。

- Purpose: show P0.2 data-use, notification consent, export/delete/retention and downgrade privacy boundaries without implying release approval or commercial outcome guarantees.
- Entry points: Goal Autopilot panel when summary/control/projection data loads, including runtime unavailable and downgraded states.
- Primary user action: review current privacy state and enable or withdraw reminder consent through the existing server-owned control update.
- Core components: privacy/control heading, product-internal data-use copy, backend data-governance export/delete/retention copy, sensitive-payload omission copy, notification consent state, reminder prompt eligibility/block reason, projection data state.
- States: `privacy_visible`, `consent_on`, `consent_withdrawn`, `reminder_blocked`, `backend_state_pending`, `projection_ready`, `projection_downgraded`, `runtime_unavailable`.
- API dependencies: existing `GET /goal-autopilot/control`, `PATCH /goal-autopilot/control`, `GET /goal-autopilot/progress-projection`, `GET /goal-autopilot/summary`. S008 does not add OpenAPI fields; Flutter renders existing `notification_consent`, `reminder_eligibility`, `projection_state` and `downgrade_reason`.
- Empty state: if projection is unavailable during load, show `backend_state_pending` rather than local export/delete state.
- Loading state: keep previously loaded server state only as part of the same view refresh; do not invent consent, reminder, export, deletion or retention facts.
- Error state: runtime unavailable uses the backend/runtime reason and blocked control result; no local fallback goal, reminder, export or release state is created.
- Copy boundary: copy must mention product-internal training surfaces, backend data-governance export/delete/retention rules and sensitive payload omission. It must not claim guaranteed achievement, official-score equivalence, unlimited AI, unlimited checkpoint access, release approval or Product Base merge approval.
- Acceptance criteria mapping: AC-P02-FUD-008 / TC-P02-FUD-015.

- 目的：展示 P0.2 的 data-use、notification consent、export/delete/retention 和 downgrade privacy boundaries，同时不暗示 release approval 或商业结果保证。
- 入口：Goal Autopilot panel 在 summary/control/projection data 加载时展示，包括 runtime unavailable 和 downgraded states。
- 主要用户动作：查看当前 privacy state，并通过已有服务端拥有的 control update 启用或撤回 reminder consent。
- 核心组件：privacy/control heading、product-internal data-use copy、backend data-governance export/delete/retention copy、sensitive-payload omission copy、notification consent state、reminder prompt eligibility/block reason、projection data state。
- 状态：`privacy_visible`, `consent_on`, `consent_withdrawn`, `reminder_blocked`, `backend_state_pending`, `projection_ready`, `projection_downgraded`, `runtime_unavailable`。
- API 依赖：已有 `GET /goal-autopilot/control`, `PATCH /goal-autopilot/control`, `GET /goal-autopilot/progress-projection`, `GET /goal-autopilot/summary`。S008 不新增 OpenAPI fields；Flutter 渲染已有 `notification_consent`, `reminder_eligibility`, `projection_state` 和 `downgrade_reason`。
- 空状态：projection 在加载期间不可用时，显示 `backend_state_pending`，而不是本地 export/delete state。
- 加载状态：只在同一视图刷新中保持此前加载的服务端状态；不得创造 consent、reminder、export、deletion 或 retention facts。
- 错误状态：runtime unavailable 使用 backend/runtime reason 和 blocked control result；不创建本地 fallback goal、reminder、export 或 release state。
- 文案边界：文案必须提及 product-internal training surfaces、backend data-governance export/delete/retention rules 和 sensitive payload omission。不得声称 guaranteed achievement、official-score equivalence、unlimited AI、unlimited checkpoint access、release approval 或 Product Base merge approval。
- 验收标准映射：AC-P02-FUD-008 / TC-P02-FUD-015。

### Followup-E Speaking Check

Owning increment: `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。

归属增量：`docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。

- Purpose: collect a short real-speaking baseline after GoalProfile setup, while preserving text fallback and learner control.
- Entry points: Goal Autopilot after successful goal setup, explicit diagnostic recalibration action, and low-confidence diagnostic recovery prompt.
- Primary user action: record, review and submit three short diagnostic samples; or choose text fallback / later recalibration.
- Core components: intro purpose/privacy copy, no-official-score claim guard, sample progress indicator, reviewed prompt text, record/stop control, timer, optional level/noise indicator, playback, re-record, accept, skip, text fallback, upload/quality state, result summary, recalibration action, delete diagnostic/audio action.
- Sample types: `read_aloud`, `listen_repeat_or_retell`, `goal_context_free_answer`.
- API dependencies: diagnostic-audio create/complete/delete, diagnostic assessment submit/read, ASR/scoring/result and native Flutter audio bytes upload are planning/contract dependencies only in the current docs-only state; machine-readable OpenAPI/generated Dart and backend/API evidence must be accepted in a later implementation slice.
- Data dependencies: `DiagnosticUploadSession`, `DiagnosticAudioSample`, `DiagnosticQualityGate`, `SpeakingDiagnosticAssessment`, `SpeakingDiagnosticResult`, `DiagnosticPrivacyState`.

- 目的：在 GoalProfile 设置后收集简短的真实口语基线，同时保留文本兜底和学习者控制权。
- 入口：成功设置 goal 后的 Goal Autopilot、显式 diagnostic recalibration action、low-confidence diagnostic recovery prompt。
- 主要用户动作：录制、回听并提交三个简短诊断样本；或选择 text fallback / later recalibration。
- 核心组件：intro purpose/privacy copy、no-official-score claim guard、sample progress indicator、reviewed prompt text、record/stop control、timer、optional level/noise indicator、playback、re-record、accept、skip、text fallback、upload/quality state、result summary、recalibration action、delete diagnostic/audio action。
- 样本类型：`read_aloud`, `listen_repeat_or_retell`, `goal_context_free_answer`。
- API 依赖：diagnostic-audio create/complete/delete、diagnostic assessment submit/read、ASR/scoring/result 和 native Flutter audio bytes upload 在当前 docs-only 状态中只是 planning/contract dependencies；machine-readable OpenAPI/generated Dart 和 backend/API evidence 必须在后续 implementation slice 中被接受。
- 数据依赖：`DiagnosticUploadSession`, `DiagnosticAudioSample`, `DiagnosticQualityGate`, `SpeakingDiagnosticAssessment`, `SpeakingDiagnosticResult`, `DiagnosticPrivacyState`。

#### Followup-E Screen States
| State | User sees | Primary action | Source of truth | Next states |
| --- | --- | --- | --- | --- |
| `speaking_check_intro` | Purpose, product-internal diagnostic boundary, privacy/retention summary and skip/text options | start sample or choose fallback | GoalProfile exists; no audio fact yet | `recording_ready`, `text_fallback_entry`, `diagnostic_cancelled` |
| `recording_ready` | One sample prompt, duration target and record control | start recording | reviewed task prompt from backend/content contract | `recording_active`, `permission_blocked`, `text_fallback_entry` |
| `permission_blocked` | Permission issue and non-blocking fallback | retry permission or enter text fallback | platform permission plus backend fallback policy | `recording_ready`, `text_fallback_entry` |
| `recording_active` | Timer, stop control and optional level/noise indicator | stop recording | local temporary capture only | `recording_review`, `recording_failed` |
| `recording_review` | Playback, re-record, accept and skip | accept sample | local temporary capture only until upload succeeds | `upload_pending`, `recording_ready`, `sample_skipped` |
| `upload_pending` | Upload and validation progress | wait or cancel if safe | backend upload session | `quality_checking`, `upload_failed` |
| `quality_checking` | Backend is validating audio format, ownership and quality | wait | backend quality gate | `sample_accepted`, `quality_rejected`, `diagnostic_degraded` |
| `sample_accepted` | Sample accepted and next sample unlocked | continue | backend-generated `audio_ref` and sample state | `recording_ready`, `diagnostic_submitting` |
| `sample_skipped` | Skipped sample and confidence impact | continue or return | user action plus backend diagnostic policy | `recording_ready`, `diagnostic_degraded` |
| `quality_rejected` | Clear issue such as too short, silent, noisy or clipped | re-record or use fallback | `DiagnosticQualityGate` | `recording_ready`, `text_fallback_entry`, `diagnostic_degraded` |
| `text_fallback_entry` | Text prompts and low-confidence notice | submit text samples | user text only, no acoustic fact | `diagnostic_submitting`, `diagnostic_cancelled` |
| `diagnostic_submitting` | Safe progress state for analysis | wait | backend assessment policy | `diagnostic_result_ready`, `diagnostic_degraded`, `diagnostic_failed_recoverable` |
| `diagnostic_result_ready` | Diagnostic mode, confidence, sample counts, quality flags, top weaknesses and first training focus | start first focus or view details | accepted backend diagnostic result | downstream GoalBackplan / training entry |
| `diagnostic_degraded` | Lower confidence and why, with continue/recalibrate options | continue conservatively or complete audio later | backend downgrade reason | downstream conservative plan, `recording_ready`, `text_fallback_entry` |
| `diagnostic_failed_recoverable` | Typed recoverable reason and safe next options | retry, fallback or skip for now | backend fallback result | `recording_ready`, `text_fallback_entry`, `diagnostic_cancelled` |
| `diagnostic_deleted_or_unavailable` | Audio-backed facts were deleted or unavailable | recalibrate or continue low confidence | backend privacy/retention state | `recording_ready`, downstream conservative plan |

| 状态 | 用户看到 | 主要动作 | 事实源 | 后续状态 |
| --- | --- | --- | --- | --- |
| `speaking_check_intro` | 目的、product-internal diagnostic boundary、privacy/retention summary 和 skip/text options | 开始样本或选择 fallback | GoalProfile exists；尚无音频事实 | `recording_ready`, `text_fallback_entry`, `diagnostic_cancelled` |
| `recording_ready` | 一个样本 prompt、时长目标和录音控件 | 开始录音 | 后端/content contract 审核过的 task prompt | `recording_active`, `permission_blocked`, `text_fallback_entry` |
| `permission_blocked` | 权限问题和非阻断 fallback | 重试权限或进入 text fallback | platform permission 加 backend fallback policy | `recording_ready`, `text_fallback_entry` |
| `recording_active` | 计时器、停止控件和可选 level/noise indicator | 停止录音 | 仅本地临时录制 | `recording_review`, `recording_failed` |
| `recording_review` | 播放、重新录制、接受和跳过 | 接受样本 | 上传成功前仅为本地临时录制 | `upload_pending`, `recording_ready`, `sample_skipped` |
| `upload_pending` | 上传和校验进度 | 等待，或在安全时取消 | backend upload session | `quality_checking`, `upload_failed` |
| `quality_checking` | 后端正在校验音频格式、归属和质量 | 等待 | backend quality gate | `sample_accepted`, `quality_rejected`, `diagnostic_degraded` |
| `sample_accepted` | 样本已接受且下一样本解锁 | 继续 | 后端生成的 `audio_ref` 和 sample state | `recording_ready`, `diagnostic_submitting` |
| `sample_skipped` | 已跳过样本及其置信度影响 | 继续或返回 | 用户动作加 backend diagnostic policy | `recording_ready`, `diagnostic_degraded` |
| `quality_rejected` | 明确问题，例如过短、静音、噪声或削波 | 重新录制或使用 fallback | `DiagnosticQualityGate` | `recording_ready`, `text_fallback_entry`, `diagnostic_degraded` |
| `text_fallback_entry` | 文本 prompt 和低置信度提醒 | 提交文本样本 | 仅用户文本，无 acoustic fact | `diagnostic_submitting`, `diagnostic_cancelled` |
| `diagnostic_submitting` | 安全的分析进度状态 | 等待 | backend assessment policy | `diagnostic_result_ready`, `diagnostic_degraded`, `diagnostic_failed_recoverable` |
| `diagnostic_result_ready` | Diagnostic mode、confidence、sample counts、quality flags、top weaknesses 和 first training focus | 开始 first focus 或查看详情 | 已接受的后端 diagnostic result | downstream GoalBackplan / training entry |
| `diagnostic_degraded` | 更低置信度及原因，并提供 continue/recalibrate options | 保守继续或稍后补充音频 | backend downgrade reason | downstream conservative plan, `recording_ready`, `text_fallback_entry` |
| `diagnostic_failed_recoverable` | typed recoverable reason 和安全下一步 | retry、fallback 或暂时 skip | backend fallback result | `recording_ready`, `text_fallback_entry`, `diagnostic_cancelled` |
| `diagnostic_deleted_or_unavailable` | 音频支持的事实已删除或不可用 | recalibrate 或低置信度继续 | backend privacy/retention state | `recording_ready`, downstream conservative plan |

#### Followup-E Interaction Rules
- Microphone permission is requested only after the learner taps record for a sample.
- Flutter must never create, edit, concatenate or infer `audio_ref`; it can only display backend-returned opaque refs as safe source labels when needed.
- Cancelled local recordings are discarded and do not create diagnostic samples.
- Re-record replaces the local temporary capture before upload. After backend acceptance, replacement must go through a new upload/assessment path with idempotency.
- Text fallback is a supported path, but UI must label it low confidence and must not show measured acoustic dimensions.
- `audio_partial` and low-quality results must show the limitation and the later recalibration path.
- Result copy must focus on next training focus, not a single score.
- Delete/unavailable states must clear current high-confidence audio-backed claims and show recalibration or conservative continuation.
- UI copy must not claim official exam score equivalence, certification, guaranteed achievement, precise ETA, unlimited AI, release approval or Product Base merge approval.

- 只有在学习者点击某个样本的 record 后，才请求麦克风权限。
- Flutter 绝不能创建、编辑、拼接或推断 `audio_ref`；只可在需要时把后端返回的不透明 refs 显示为安全来源标签。
- 已取消的本地录音会被丢弃，且不会创建 diagnostic samples。
- Re-record 会在上传前替换本地临时录制。后端接受后，如需替换必须走新的 upload/assessment 路径并具备幂等性。
- Text fallback 是受支持路径，但 UI 必须标记其低置信度，且不得展示测量得出的 acoustic dimensions。
- `audio_partial` 和低质量结果必须展示限制，并提供后续 recalibration 路径。
- 结果文案聚焦下一训练重点，而不是单一分数。
- Delete/unavailable 状态必须清除当前 high-confidence audio-backed claims，并展示 recalibration 或 conservative continuation。
- UI 文案不得声称 official exam score equivalence、certification、guaranteed achievement、precise ETA、unlimited AI、release approval 或 Product Base merge approval。

#### Followup-E Planned Test Checklist Contract
| Acceptance | Screen state / behavior | Planned test mapping |
| --- | --- | --- |
| AC-P02-FUE-001 | Speaking Check entry after valid GoalProfile, skip/text option and no official-score copy | TC-P02-FUE-001, TC-P02-FUE-002 |
| AC-P02-FUE-002 | Three sample types, progress, task metadata and skip impact | TC-P02-FUE-003, TC-P02-FUE-004 |
| AC-P02-FUE-003 | Record, stop, playback, re-record, cancel, permission fallback and no local fact on cancel | TC-P02-FUE-005, TC-P02-FUE-006 |
| AC-P02-FUE-004 | Backend-owned upload/audio_ref and visible retry states | TC-P02-FUE-007, TC-P02-FUE-008, TC-P02-FUE-009 |
| AC-P02-FUE-005 | Quality rejection and diagnostic mode/confidence downgrade | TC-P02-FUE-010, TC-P02-FUE-011, TC-P02-FUE-012 |
| AC-P02-FUE-007 | Result summary shows mode, confidence, sample count, weaknesses and next focus | TC-P02-FUE-016 |
| AC-P02-FUE-008 | Privacy, retention, export/delete and deleted/unavailable state handling | TC-P02-FUE-017, TC-P02-FUE-018, TC-P02-FUE-019 |
| AC-P02-FUE-009 | Quota/cost/provider downgrade does not fabricate success | TC-P02-FUE-020, TC-P02-FUE-021, TC-P02-FUE-022 |

| 验收项 | 页面状态 / 行为 | 计划测试映射 |
| --- | --- | --- |
| AC-P02-FUE-001 | 有效 GoalProfile 后进入 Speaking Check，提供 skip/text option，且没有 official-score copy | TC-P02-FUE-001, TC-P02-FUE-002 |
| AC-P02-FUE-002 | 三种 sample types、进度、task metadata 和 skip impact | TC-P02-FUE-003, TC-P02-FUE-004 |
| AC-P02-FUE-003 | Record、stop、playback、re-record、cancel、permission fallback，并且 cancel 不产生本地事实 | TC-P02-FUE-005, TC-P02-FUE-006 |
| AC-P02-FUE-004 | 后端拥有 upload/audio_ref，并展示可见 retry states | TC-P02-FUE-007, TC-P02-FUE-008, TC-P02-FUE-009 |
| AC-P02-FUE-005 | Quality rejection 和 diagnostic mode/confidence downgrade | TC-P02-FUE-010, TC-P02-FUE-011, TC-P02-FUE-012 |
| AC-P02-FUE-007 | Result summary 展示 mode、confidence、sample count、weaknesses 和 next focus | TC-P02-FUE-016 |
| AC-P02-FUE-008 | Privacy、retention、export/delete 和 deleted/unavailable state handling | TC-P02-FUE-017, TC-P02-FUE-018, TC-P02-FUE-019 |
| AC-P02-FUE-009 | Quota/cost/provider downgrade 不伪造成成功 | TC-P02-FUE-020, TC-P02-FUE-021, TC-P02-FUE-022 |

### Notebook
- Purpose: review saved expressions.
- States: empty, loaded, deleting, error.
- Primary action: open saved expression.

- 目的：复习已保存表达。
- 状态：empty, loaded, deleting, error。
- 主要动作：打开已保存表达。

### Review
- Purpose: complete due review tasks.
- States: due, answering, completed, empty.
- Primary action: submit review answer.

- 目的：完成到期复习任务。
- 状态：due, answering, completed, empty。
- 主要动作：提交复习回答。

## P0 Commercial Subscription Screens

Owning increment: `commercial-subscription-readiness`.

归属增量：`commercial-subscription-readiness`。

### Membership / Plans
- Purpose: show current server-owned entitlement state and saleable subscription plans.
- Entry points: profile membership entry, paywall upgrade action, restore purchase action, expired/downgraded entitlement banner.
- Primary user action: choose a plan, start platform purchase, restore purchase, or manage subscription.
- Core components: entitlement status banner, plan list, benefit list, restore action, platform legal note, loading/error state.
- States: loading_entitlement, free, active_paid, grace_period, expired, refunded_or_revoked, purchase_processing, restore_processing, empty_restore, provider_unavailable, config_blocked.
- API dependencies: `GET /subscription/plans`, `GET /entitlements`, `POST /entitlements/refresh`, `POST /subscriptions/apple/verify`, `POST /subscriptions/google/verify`, `POST /subscriptions/restore`.
- Empty state: no saleable plans or no restore result; show a clear explanation and a retry or support action.
- Loading state: disable duplicate purchase/restore actions and keep current entitlement visible as stale until refreshed.
- Error state: invalid receipt, product mismatch, network failure and backend verification failure must not grant entitlement; user sees retry or subscription management guidance.
- Acceptance criteria mapping: AC-COM-001, AC-COM-002, AC-COM-003, AC-COM-004, AC-COM-005, AC-COM-011.

- 目的：展示当前服务端拥有的权益状态和可销售订阅计划。
- 入口：profile membership entry、paywall upgrade action、restore purchase action、expired/downgraded entitlement banner。
- 主要用户动作：选择计划、开始平台购买、恢复购买或管理订阅。
- 核心组件：entitlement status banner、plan list、benefit list、restore action、platform legal note、loading/error state。
- 状态：loading_entitlement, free, active_paid, grace_period, expired, refunded_or_revoked, purchase_processing, restore_processing, empty_restore, provider_unavailable, config_blocked。
- API 依赖：`GET /subscription/plans`, `GET /entitlements`, `POST /entitlements/refresh`, `POST /subscriptions/apple/verify`, `POST /subscriptions/google/verify`, `POST /subscriptions/restore`。
- 空状态：没有可销售计划或没有恢复结果时，显示清晰解释，并提供重试或支持入口。
- 加载状态：禁用重复购买/恢复动作，并在刷新完成前把当前权益显示为 stale。
- 错误状态：invalid receipt、product mismatch、network failure 和 backend verification failure 不得授予权益；用户看到重试或订阅管理指引。
- 验收标准映射：AC-COM-001, AC-COM-002, AC-COM-003, AC-COM-004, AC-COM-005, AC-COM-011。

### Paywall / Entitlement Gate
- Purpose: block unavailable paid capabilities while explaining the required entitlement.
- Entry points: AI deep feedback, high-cost ASR/TTS/scoring call, paid scenario package, learning report or other paid benefit.
- Primary user action: upgrade, retry after refresh, or continue with a free downgraded path when available.
- Core components: required benefit label, current plan state, remaining quota, upgrade action, fallback action.
- States: allowed, entitlement_required, quota_exhausted, expired, refunded_or_revoked, offline_stale_cache, refresh_failed.
- API dependencies: `GET /entitlements`, `POST /entitlements/refresh`, `GET /usage/summary`, `POST /usage/reserve`.
- Empty state: no paid benefit exists for the requested action; show the available free action instead of an empty upsell.
- Loading state: show entitlement refresh progress and avoid starting the protected provider call until the server confirms access.
- Error state: provider or usage failure returns a recoverable message and does not consume client-side-only quota.
- Acceptance criteria mapping: AC-COM-006, AC-COM-007, AC-COM-012.

- 目的：阻断不可用的付费能力，并说明所需权益。
- 入口：AI deep feedback、high-cost ASR/TTS/scoring call、paid scenario package、learning report 或其他 paid benefit。
- 主要用户动作：upgrade、refresh 后 retry，或在可用时继续 free downgraded path。
- 核心组件：required benefit label、current plan state、remaining quota、upgrade action、fallback action。
- 状态：allowed, entitlement_required, quota_exhausted, expired, refunded_or_revoked, offline_stale_cache, refresh_failed。
- API 依赖：`GET /entitlements`, `POST /entitlements/refresh`, `GET /usage/summary`, `POST /usage/reserve`。
- 空状态：请求动作没有对应 paid benefit 时，显示可用 free action，而不是空的 upsell。
- 加载状态：显示 entitlement refresh progress，并在服务端确认 access 前避免启动受保护 provider call。
- 错误状态：provider 或 usage 失败返回可恢复消息，且不消耗仅客户端侧的 quota。
- 验收标准映射：AC-COM-006, AC-COM-007, AC-COM-012。

### Account Deletion
- Purpose: let the user understand and confirm account deletion, then clear local state after backend deletion or anonymization completes.
- Entry points: profile/settings account deletion action.
- Primary user action: confirm deletion after reading consequences.
- Core components: consequence summary, confirmation input or final confirm button, deletion progress, failure/retry/support state.
- States: confirming, deleting, completed, failed_retryable, failed_support_needed, logged_out_after_completion.
- API dependencies: `DELETE /user/me`, `GET /user/deletion-status`.
- Empty state: no deletion job exists; show the default confirmation screen.
- Loading state: keep the screen in progress until the backend returns a deletion job state.
- Error state: local data is not cleared until the backend reports accepted/completed deletion; retryable failure shows next action.
- Acceptance criteria mapping: AC-COM-010.

- 目的：让用户理解并确认账号删除，然后在后端删除或匿名化完成后清理本地状态。
- 入口：profile/settings account deletion action。
- 主要用户动作：阅读后果后确认删除。
- 核心组件：consequence summary、confirmation input 或 final confirm button、deletion progress、failure/retry/support state。
- 状态：confirming, deleting, completed, failed_retryable, failed_support_needed, logged_out_after_completion。
- API 依赖：`DELETE /user/me`, `GET /user/deletion-status`。
- 空状态：没有 deletion job 时，显示默认确认页面。
- 加载状态：页面保持处理中，直到后端返回 deletion job state。
- 错误状态：后端报告 accepted/completed deletion 前不清理本地数据；可重试失败展示下一步。
- 验收标准映射：AC-COM-010。

### Release / Config Blocked State
- Purpose: prevent a store or release candidate from exposing broken commercial flows.
- Entry points: release health checks, internal testing, visible login/payment/social-login entries.
- Primary user action: none for end users; testers see configuration error in non-production channels.
- Core components: release health warning, missing config list, blocked action message.
- States: production_ready, missing_api_base_url, test_login_enabled, missing_payment_product, missing_social_config, missing_release_secret.
- API dependencies: `GET /admin/release-health` for ops; app UI consumes only release-safe configuration values.

- 目的：防止商店版本或 release candidate 暴露损坏的商业流程。
- 入口：release health checks、internal testing、visible login/payment/social-login entries。
- 主要用户动作：终端用户无动作；测试人员在非生产渠道看到配置错误。
- 核心组件：release health warning、missing config list、blocked action message。
- 状态：production_ready, missing_api_base_url, test_login_enabled, missing_payment_product, missing_social_config, missing_release_secret。
- API 依赖：`GET /admin/release-health` 供 ops 使用；app UI 只消费 release-safe configuration values。

- Empty state: no warnings.
- Loading state: not user-facing in production; internal builds may show checking.
- Error state: fail closed for production release, not fail open.
- Acceptance criteria mapping: AC-COM-008, AC-COM-009, AC-COM-014.

- 空状态：没有 warnings。
- 加载状态：生产环境不面向用户；internal builds 可显示 checking。
- 错误状态：production release fail closed，而不是 fail open。
- 验收标准映射：AC-COM-008, AC-COM-009, AC-COM-014。
