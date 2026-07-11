# Training Model：P0.1 表达自动化训练闭环

## 状态
Proposed - P0.1 Domain Gate Ready；2026-06-03 commercial production-hardening domain addendum added.

状态：拟议；P0.1 Domain Gate 已准备就绪，并在 2026-06-03 增加 commercial production-hardening domain addendum。

本文是 `p0-1-expression-automation-training` 的专项领域模型，用于关闭 `P01-GAP-001`。本文只定义领域对象、关系、生命周期、不变量和持久化边界，不定义 API request/response、不写数据库 migration、不实现 Flutter 或 backend 代码。

## Owning Product Object

| 字段 | 值 |
| --- | --- |
| Increment | `docs/product/increments/p0-1-expression-automation-training/` |
| Active stage | `docs/product/stages/p0-1-expression-automation.md` |
| Primary Capability ID | `CAP-TRAIN` |
| Primary Sub-capability ID | `CAP-TRAIN-03` |
| Affected Capability IDs | `CAP-PRACTICE`、`CAP-CONTENT`、`CAP-MEMORY`、`CAP-COACH` |
| Affected Sub-capability IDs | `CAP-TRAIN-02`、`CAP-TRAIN-04`、`CAP-TRAIN-05`、`CAP-TRAIN-06`、`CAP-PRACTICE-01`、`CAP-PRACTICE-02`、`CAP-PRACTICE-03`、`CAP-CONTENT-03`、`CAP-MEMORY-02`、`CAP-COACH-02`、`CAP-COACH-03`、`CAP-COACH-05` |
| Covered gap | `P01-GAP-001`, `P01-GAP-009` through `P01-GAP-014` |

## Source Inputs

- `docs/product/increments/p0-1-expression-automation-training/definition.md`
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/spec.md`
- `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- `docs/product/increments/p0-1-expression-automation-training/traceability.md`
- `docs/domain/domain_schema.md`
- `docs/domain/entity_relationship.md`
- `docs/architecture/adr/0004-deterministic-training-planner-ai-boundary.md`

## Domain Principles

- P0.1 训练只在 `job_interview` 和 `onboarding_introduction` 两个官方场景内生效。
- P0.1 只接管 session 内训练组织；跨 session、跨天、完整 L0-L5 和任意场景生成属于 P0.2 或后续阶段。
- Planner 决策必须由 deterministic rules 裁决；LLM 只能提供候选反馈、候选追问和候选学习证据。
- 每次训练只暴露一个主要 micro-action，且必须有通过信号、重试路径或可恢复失败路径。
- Learning evidence 的最终写入必须由应用规则执行；AI 输出不能直接改变最终掌握状态。
- 语音是默认主路径；文本只作为 ASR 失败、麦克风拒绝或调试兜底。
- Local-first state 只允许作为本地草稿、demo 或可恢复 fallback；Product Base 合入和商业生产训练必须由后端 Training API 拥有 session、turn、planner decision、evidence handoff 和审计事实，除非 release/Product Base 状态显式 blocked。

## Entities

| Entity | Owner | 关键字段 | 不变量 |
| --- | --- | --- | --- |
| `TrainingSession` | Training Planner domain | `training_session_id`, `user_id`, `scene_id`, `level_code`, `scenario_version_id`, `status`, `current_action_step_key`, `current_micro_action_type`, `started_at`, `completed_at` | 一个 active session 必须绑定一个用户、一个官方可用场景、一个等级和一个已发布内容版本；缺少 reviewed training mapping 的场景不得创建 production session。 |
| `ActionChainStep` | Content + Training Planner domain | `step_key`, `scene_id`, `scenario_version_id`, `order_index`, `learner_task`, `success_condition`, `target_expression_ids` | P0.1 step 集合固定为开场、说明目的、表达观点、回应追问、确认下一步、结束；缺少资产标注时允许本地映射，但必须可追溯。 |
| `MicroAction` | Training Planner domain | `micro_action_type`, `target_expression_id`, `prompt_ref`, `pass_signal_rule`, `fallback_rule` | 当前类型只能是 `ListenOne`, `ChooseOne`, `SayOne`, `ShadowOne`, `FillOne`, `ContinueUnderPrompt`；一次只允许一个 active micro-action。 |
| `TrainingTurn` | Training Planner domain | `training_turn_id`, `training_session_id`, `micro_action_type`, `input_mode`, `transcript_ref`, `audio_ref`, `answer_text`, `result`, `created_at` | 每次用户尝试形成一条 turn；ASR 失败不能直接写成表达失败，只能进入重录、文本兜底或可恢复错误。 |
| `HintState` | Training Planner domain | `training_session_id`, `current_hint_level`, `failure_count`, `success_count`, `last_changed_at` | hint level 只允许 `none`, `sentence_frame`, `options`, `chunk_shadowing`, `model_then_retry`；连续失败升支架，连续通过降支架或进入 pressure check。 |
| `PlannerDecision` | Training Planner domain | `planner_decision_id`, `training_session_id`, `source_turn_id`, `decision_type`, `next_micro_action_type`, `hint_level`, `reason_code`, `schema_version` | 决策必须可回放、可测试；自由 LLM 文本不得作为唯一决策来源。 |
| `PressureCheck` | Training Planner domain | `pressure_check_id`, `training_session_id`, `trigger_decision_id`, `prompt_ref`, `status`, `result` | 只允许 session 内轻量追问或近场景复现；失败必须回到更高 hint level 的重试路径。 |
| `TrainingFeedback` | AI Gateway + Training domain | `feedback_id`, `source_turn_id`, `ai_result_ref_id`, `completion_signal`, `task_signal`, `pronunciation_signal_ref`, `suggestion_text`, `validation_status` | 反馈可以使用 LLM 候选和评分信号，但通过/失败必须结合表达完成度和场景任务完成度；发音低分不能单独阻断。 |
| `LearningEvidenceCandidate` | Learning Evidence domain | `candidate_id`, `source_turn_id`, `source_feedback_id`, `evidence_type`, `target_expression_id`, `confidence`, `status`, `reject_reason` | 候选证据不能直接改 mastery；必须被 evidence rules 接受、拒绝或合并去重。 |
| `TrainingRecap` | Training + Learning Evidence domain | `recap_id`, `training_session_id`, `summary`, `evidence_refs`, `next_focus`, `status` | recap 是用户可见结果；即使 evidence 写回失败，也不得丢失已可见 recap。 |
| `TrainingContentMapping` | Content + Training Planner domain | `mapping_version`, `scenario_version_id`, `action_chain_version`, `step_key`, `target_expression_ids`, `review_status` | 生产训练只能使用 reviewed mapping；缺失映射必须进入 recoverable/blocked 状态，不得生成未审核场景内容。 |
| `TrainingMetricEvent` | Training + Ops domain | `event_id`, `training_session_id`, `event_type`, `status`, `provider_family`, `latency_bucket`, `fallback_reason`, `schema_version` | 指标必须脱敏；不得包含 provider secret、raw audio、full transcript、raw provider payload 或完整 signed URL。 |

## Lifecycle State Machines

### TrainingSession

```text
loading -> ready -> in_progress -> feedback -> retry -> pressure_check -> recap -> completed
                 \-> recoverable_error -> retry
                 \-> recoverable_error -> recap
                 \-> abandoned
```

Rules:
- `loading` 失败必须进入 `recoverable_error`，不得展示空白训练页。
- `completed` 后不得继续追加 active turn；用户再次训练应创建新 session 或显式恢复未完成 session。
- `abandoned` 不等同失败；可保留本地草稿和已生成 recap。

### HintState

```text
none -> sentence_frame -> options -> chunk_shadowing -> model_then_retry
```

Rules:
- 连续失败至少触发同级重试或升一级支架。
- 连续通过后必须尝试降支架、升级 micro-action 或进入 `PressureCheck`。
- UI 必须能展示当前支架内容；隐藏 hint level 的实现不能通过 P0.1 验收。

### PlannerDecision

```text
generated -> applied -> superseded
generated -> rejected
```

Rules:
- `generated` 只表示候选决策存在；只有 `applied` 决策能推进 session。
- 如果新 turn 到达或用户选择重录，旧决策必须 `superseded`。
- `rejected` 需要 reason code，例如 `invalid_ai_candidate`, `asr_failed`, `score_unavailable`, `out_of_scope_scene`。

### PressureCheck

```text
not_started -> active -> passed -> completed
not_started -> active -> failed -> retry_with_higher_hint
active -> recoverable_error
```

Rules:
- 触发条件必须来自连续通过或 planner upgrade 决策。
- P0.1 pressure check 不产生跨天计划，不展示完整 L0-L5。

### LearningEvidenceCandidate

```text
candidate -> accepted -> written
candidate -> rejected
candidate -> merged_duplicate
accepted -> write_failed -> retryable
```

Rules:
- `accepted` 必须有 deterministic rule trace。
- `write_failed` 不得清空 `TrainingRecap`。
- 低置信度、缺少 stable target expression、无 source turn 的候选必须拒绝或仅作为用户可见建议。

## Relationships

| From | Relationship | To | Cardinality | Rule |
| --- | --- | --- | --- | --- |
| `User` | starts/resumes | `TrainingSession` | 1 -> many | 同用户同场景同等级可恢复一个未完成 session。 |
| `TrainingSession` | references | `ScenarioVersion` | many -> 1 | 所有训练证据必须能追溯到内容版本。 |
| `TrainingSession` | progresses through | `ActionChainStep` | 1 -> ordered many | 当前 step 是 planner 输入，不由 LLM 自由决定。 |
| `ActionChainStep` | targets | `TargetExpression` | many -> many | 缺失目标表达时只能进入可恢复错误或本地映射，不得生成任意场景内容。 |
| `TrainingSession` | contains | `TrainingTurn` | 1 -> many | Turn 顺序稳定；重放需要幂等键或本地 attempt id。 |
| `TrainingTurn` | performs | `MicroAction` | many -> 1 | 一个 turn 只能对应一个主要 micro-action。 |
| `TrainingSession` | owns current | `HintState` | 1 -> 0..1 | HintState 可由 decisions 重建，但实现应保存当前可见支架。 |
| `TrainingTurn` | produces | `TrainingFeedback` | 1 -> 0..1 | invalid AI schema 不得成为 successful feedback。 |
| `TrainingFeedback` | may propose | `LearningEvidenceCandidate` | 1 -> many | 候选证据必须经 rules 接受后才能写入。 |
| `PlannerDecision` | may trigger | `PressureCheck` | 1 -> 0..1 | Pressure check 只在 session 内生效。 |
| `TrainingSession` | ends with | `TrainingRecap` | 1 -> 0..1 | Recap 是用户可见收尾，不依赖远端写回成功。 |

## Persistence Boundary

| Boundary | P0.1 决策 |
| --- | --- |
| Backend-only Training | `TrainingSession`、`HintState`、`PlannerDecision` 和 `TrainingRecap` 的 Product Base/production 事实源只能在后端 Training bounded context。Flutter 只能渲染后端状态或服务不可用状态，不得本地持久化可进入训练的 draft session。 |
| Server sync | 2026-06-03 商业整改要求 Product Base 合入前实现 repository-backed Training API sync，或在 Product Base/release 状态中显式 blocked；没有 API contract/test cases 时不得新增后端接口。 |
| Existing backend | 当前 Product Base backend 的 `PracticeSession`、`PracticeTurn`、`LearningEvidence` 可复用，但不足以自动关闭 P0.1 生产训练事实源；必须有 Training-specific controller/service/repository 或明确的复用映射和测试。 |
| AI output | `AIResultRef` 和 structured feedback 只保存 schema-valid、脱敏、可追溯字段；raw provider payload 不能作为 UI 或 evidence 的事实源。 |
| Account deletion | 若 P0.1 数据被本地或服务端持久化，必须纳入账号删除、本地清理、AI/media retention 和 redacted audit 策略。 |

## Production Hardening Domain Addendum

| Domain concern | Required decision |
| --- | --- |
| Training API source of truth | Product Base/production mode must persist authenticated `TrainingSession`, `TrainingTurn`, `PlannerDecision`, `HintState`, `TrainingRecap` and evidence handoff state on the server. Local draft may be resumed or synced, but cannot overwrite accepted server facts without version and owner checks. |
| Idempotency and authorization | `TrainingTurn` creation uses idempotency key plus session owner scope. Replays cannot duplicate turns, evidence writes, usage charges, provider calls or metric events. |
| Versioned training content | `TrainingContentMapping` links each session to reviewed `scenario_version_id`, `action_chain_version`, `step_key` and stable target expressions. Mapping drift requires explicit migration, backward-compatible replay or blocked status. |
| Planner replay | `PlannerDecision` stores rule version, normalized input snapshot refs, AI candidate refs where used, selected next action, hint level and reason code so Backend/QA can reproduce the decision from fixtures. |
| Evidence rule trace | Accepted evidence stores deterministic rule trace and source turn; rejected or merged duplicate candidates remain auditable but must not update final mastery projections. |
| Media and AI pipeline | `TrainingTurn.audio_ref` must be a trusted backend media ref in production. Provider failures become typed fallback and must release or settle usage reservations according to auditable AI Gateway rules. |
| Metrics and rollout | `TrainingMetricEvent` supports rollout, fallback, latency, completion and evidence-write health without storing sensitive payloads. Rollout gates must separate local pass, Product Base merge readiness and paid AI release readiness. |

中文等价说明：

- Training API source of truth：Product Base/production mode 必须在 server 持久化 authenticated `TrainingSession`、`TrainingTurn`、`PlannerDecision`、`HintState`、`TrainingRecap` 和 evidence handoff state。Local draft 可以恢复或同步，但没有 version 和 owner checks 时不得覆盖 accepted server facts。
- Idempotency and authorization：创建 `TrainingTurn` 必须使用 idempotency key 加 session owner scope。Replay 不得重复创建 turns、evidence writes、usage charges、provider calls 或 metric events。
- Versioned training content：`TrainingContentMapping` 将每个 session 关联到 reviewed `scenario_version_id`、`action_chain_version`、`step_key` 和 stable target expressions。Mapping drift 必须通过显式 migration、backward-compatible replay 或 blocked status 处理。
- Planner replay：`PlannerDecision` 必须保存 rule version、normalized input snapshot refs、使用到的 AI candidate refs、selected next action、hint level 和 reason code，使 Backend/QA 能通过 fixtures 复现决策。
- Evidence rule trace：Accepted evidence 必须保存 deterministic rule trace 和 source turn；rejected 或 merged duplicate candidates 仍可审计，但不得更新最终 mastery projections。
- Media and AI pipeline：production 中 `TrainingTurn.audio_ref` 必须是可信 backend media ref。Provider failures 必须转成 typed fallback，并按照可审计的 AI Gateway rules release 或 settle usage reservations。
- Metrics and rollout：`TrainingMetricEvent` 支持 rollout、fallback、latency、completion 和 evidence-write health，不保存 sensitive payloads。Rollout gates 必须区分 local pass、Product Base merge readiness 和 paid AI release readiness。

## Test And Contract Handoff

| Area | 下游要求 |
| --- | --- |
| Domain tests | 覆盖 `TrainingSession` 状态、action chain fallback、micro-action pass/fallback、hint ladder、pressure check、evidence candidate acceptance/rejection。 |
| AI runtime | 输出 schema 必须支持 `completion_signal`、`task_signal`、`suggestion`、`retry_hint`、`pressure_prompt_candidate`，且不能直接写 mastery。 |
| UX | 训练页必须能呈现一个 micro-action、当前 hint、录音/文本兜底、feedback、pressure check 和 recap。 |
| Architecture | 必须决定复用现有 `InterviewPracticeSession`/`interview_engine` 还是拆新 training planner 模块；Product Base/production mode 还必须落在后端 Training source-of-truth boundary。 |
| Backend/API | OpenAPI Training family、Learning Evidence、Media/AI Gateway 和 deletion/retention contracts 必须覆盖 `P01-FR-012` through `P01-FR-017`。 |
| Ops/Release | 指标、feature flag、kill switch、provider fallback 和 paid AI release blockers 必须能把 local pass、Product Base merge 和 commercial release 明确分开。 |
| QA | `AC-P01-001` 到 `AC-P01-019` 必须映射到稳定 `TC-P01-*`，缺口只能使用明确例外。 |

## P01-GAP-001 Coverage

| Traceability rows | Domain coverage |
| --- | --- |
| `P01-TR-002` | `TrainingSession`, `PlannerDecision`, `HintState` 定义 session planner 决策输入和输出。 |
| `P01-TR-003` | `ActionChainStep` 定义六段动作链和缺失标注 fallback。 |
| `P01-TR-004` | `MicroAction`, `TrainingTurn` 定义单步训练动作和状态记录。 |
| `P01-TR-005` | `HintState` 定义支架化提示阶梯和升降级规则。 |
| `P01-TR-006` | `PressureCheck` 定义连续通过后的 session 内轻量施压。 |
| `P01-TR-008` | `TrainingFeedback`, `LearningEvidenceCandidate` 定义反馈和评分边界。 |
| `P01-TR-009` | `LearningEvidenceCandidate`, `TrainingRecap` 定义证据写回前置候选和 recap 保留。 |
| `P01-TR-013` | `TrainingSession`, `TrainingTurn`, `PlannerDecision`, server persistence boundary 定义后端 Training API/source-of-truth 闭环。 |
| `P01-TR-014` | `LearningEvidenceCandidate` 和 evidence rule trace 定义服务端证据接受、拒绝、合并和删除保留边界。 |
| `P01-TR-015` | `TrainingContentMapping` 定义版本化 action chain、step 和 target expression 映射。 |
| `P01-TR-016` | `TrainingTurn.audio_ref`, `TrainingFeedback` 和 AI Gateway boundary 定义真实媒体/AI pipeline 约束。 |
| `P01-TR-017` | `PlannerDecision` 定义 planner 配置、审计和 replay 证据。 |
| `P01-TR-018` | `TrainingMetricEvent` 定义商业运营指标、脱敏观测和 rollout gate。 |

## Explicit Non-goals

- 不新增第三个官方场景。
- 不实现任意场景生成。
- 不定义跨天训练计划。
- 不实现完整 L0-L5 掌握阶梯。
- 不产品化任意词句笔记本。
- 不把完整评分体系或商业权益 gating 作为 P0.1 完成条件。
- 不在 P0.1 内创建独立计费、权益或 paid AI release 事实源；这些仍由 P0 commercial gates 管理。
