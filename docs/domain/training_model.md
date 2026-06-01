# Training Model：P0.1 表达自动化训练闭环

## 状态
Proposed - P0.1 Domain Gate Ready。

本文是 `p0-1-expression-automation-training` 的专项领域模型，用于关闭 `P01-GAP-001`。本文只定义领域对象、关系、生命周期、不变量和持久化边界，不定义 API request/response、不写数据库 migration、不实现 Flutter 或 backend 代码。

## Owning Product Object

| 字段 | 值 |
| --- | --- |
| Increment | `docs/product/increments/p0-1-expression-automation-training/` |
| Active stage | `docs/product/stages/p0-1-expression-automation.md` |
| Primary feature | `expression-automation-training` |
| Affected features | `voice-scenario-practice`, `official-scenario-library`, `listening-shadowing`, `expression-practice-queue`, `learning-memory-review`, `scoring-feedback` |
| Covered gap | `P01-GAP-001` |

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

## Entities

| Entity | Owner | 关键字段 | 不变量 |
| --- | --- | --- | --- |
| `TrainingSession` | Training Planner domain | `training_session_id`, `user_id`, `scene_id`, `level_code`, `scenario_version_id`, `status`, `current_action_step_key`, `current_micro_action_type`, `started_at`, `completed_at` | 一个 active session 必须绑定一个用户、一个官方场景、一个等级和一个内容版本；非 P0.1 场景不得创建 session。 |
| `ActionChainStep` | Content + Training Planner domain | `step_key`, `scene_id`, `scenario_version_id`, `order_index`, `learner_task`, `success_condition`, `target_expression_ids` | P0.1 step 集合固定为开场、说明目的、表达观点、回应追问、确认下一步、结束；缺少资产标注时允许本地映射，但必须可追溯。 |
| `MicroAction` | Training Planner domain | `micro_action_type`, `target_expression_id`, `prompt_ref`, `pass_signal_rule`, `fallback_rule` | 当前类型只能是 `ListenOne`, `ChooseOne`, `SayOne`, `ShadowOne`, `FillOne`, `ContinueUnderPrompt`；一次只允许一个 active micro-action。 |
| `TrainingTurn` | Training Planner domain | `training_turn_id`, `training_session_id`, `micro_action_type`, `input_mode`, `transcript_ref`, `audio_ref`, `answer_text`, `result`, `created_at` | 每次用户尝试形成一条 turn；ASR 失败不能直接写成表达失败，只能进入重录、文本兜底或可恢复错误。 |
| `HintState` | Training Planner domain | `training_session_id`, `current_hint_level`, `failure_count`, `success_count`, `last_changed_at` | hint level 只允许 `none`, `sentence_frame`, `options`, `chunk_shadowing`, `model_then_retry`；连续失败升支架，连续通过降支架或进入 pressure check。 |
| `PlannerDecision` | Training Planner domain | `planner_decision_id`, `training_session_id`, `source_turn_id`, `decision_type`, `next_micro_action_type`, `hint_level`, `reason_code`, `schema_version` | 决策必须可回放、可测试；自由 LLM 文本不得作为唯一决策来源。 |
| `PressureCheck` | Training Planner domain | `pressure_check_id`, `training_session_id`, `trigger_decision_id`, `prompt_ref`, `status`, `result` | 只允许 session 内轻量追问或近场景复现；失败必须回到更高 hint level 的重试路径。 |
| `TrainingFeedback` | AI Gateway + Training domain | `feedback_id`, `source_turn_id`, `ai_result_ref_id`, `completion_signal`, `task_signal`, `pronunciation_signal_ref`, `suggestion_text`, `validation_status` | 反馈可以使用 LLM 候选和评分信号，但通过/失败必须结合表达完成度和场景任务完成度；发音低分不能单独阻断。 |
| `LearningEvidenceCandidate` | Learning Evidence domain | `candidate_id`, `source_turn_id`, `source_feedback_id`, `evidence_type`, `target_expression_id`, `confidence`, `status`, `reject_reason` | 候选证据不能直接改 mastery；必须被 evidence rules 接受、拒绝或合并去重。 |
| `TrainingRecap` | Training + Learning Evidence domain | `recap_id`, `training_session_id`, `summary`, `evidence_refs`, `next_focus`, `status` | recap 是用户可见结果；即使 evidence 写回失败，也不得丢失已可见 recap。 |

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
| Local first | P0.1 第一版允许 `TrainingSession`、`HintState`、`PlannerDecision` 和 `TrainingRecap` 先本地持久化或复用现有 practice session storage。 |
| Server sync | 如果实现选择 repository-backed sync，必须先补 API contract；没有 API contract 时不得新增后端接口。 |
| Existing backend | 当前 Product Base backend 的 `PracticeSession`、`PracticeTurn`、`LearningEvidence` 可作为后续服务端事实源，但 P0.1 不强制在第一切片新增 migration。 |
| AI output | `AIResultRef` 和 structured feedback 只保存 schema-valid、脱敏、可追溯字段；raw provider payload 不能作为 UI 或 evidence 的事实源。 |
| Account deletion | 若 P0.1 数据被持久化，必须纳入账号删除和本地清理策略。 |

## Test And Contract Handoff

| Area | 下游要求 |
| --- | --- |
| Domain tests | 覆盖 `TrainingSession` 状态、action chain fallback、micro-action pass/fallback、hint ladder、pressure check、evidence candidate acceptance/rejection。 |
| AI runtime | 输出 schema 必须支持 `completion_signal`、`task_signal`、`suggestion`、`retry_hint`、`pressure_prompt_candidate`，且不能直接写 mastery。 |
| UX | 训练页必须能呈现一个 micro-action、当前 hint、录音/文本兜底、feedback、pressure check 和 recap。 |
| Architecture | 必须决定复用现有 `InterviewPracticeSession`/`interview_engine` 还是拆新 training planner 模块。 |
| QA | `AC-P01-001` 到 `AC-P01-012` 必须映射到稳定 `TC-P01-*`，缺口只能使用明确例外。 |

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

## Explicit Non-goals

- 不新增第三个官方场景。
- 不实现任意场景生成。
- 不定义跨天训练计划。
- 不实现完整 L0-L5 掌握阶梯。
- 不产品化任意词句笔记本。
- 不把完整评分体系或商业权益 gating 作为 P0.1 完成条件。
