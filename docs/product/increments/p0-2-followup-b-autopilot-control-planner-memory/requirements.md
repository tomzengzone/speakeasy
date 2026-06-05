# P0.2 Followup-B Requirements：自动带练控制与计划记忆引擎加固

## 状态
Requirements accepted for Followup-B scoped implementation / downstream executed through S002-B - 本文件定义 `p0-2-followup-b-autopilot-control-planner-memory` 的需求边界；对应 spec、acceptance、test_cases、traceability、Domain、API/OpenAPI/generated client、AI runtime 和 UX 合同已生成并进入实现路由。当前 backend/frontend UserAutopilotControl control slice、S002-A notification eligibility policy 和 S002-B notification outbox lifecycle/replay 有本地执行证据；missed-day recovery、item-level memory、L0-L5 transition、global replay/performance/coverage/final review 仍保持 open。

## Product Object
- 分类：`feature-increment`
- Increment：`p0-2-followup-b-autopilot-control-planner-memory`
- Active stage：`docs/product/stages/p0-2-training-memory.md`
- Primary feature：`goal-driven-learning-autopilot`
- Affected features：`learning-memory-review`、`expression-automation-training`、`expression-practice-queue`、`voice-scenario-practice`、`ai-provider-operations`

## 需求假设
- Followup-A 已提供可编辑 GoalProfile、诊断输入、目标 revision/stale 可见化和 no-goal Explore Mode 的事实边界。
- 既有 P0.2 plan/autopilot 设计已提供 GoalBackplan、DailyTrainingPlan、PlanItem、AutopilotAction、MemoryCurvePolicy 和 checkpoint/forecast 的上游设计意图。
- Followup-B 不继承 Followup-A 的本地实现通过状态；本增量必须独立完成 FR、Spec、AC、TC、Traceability、契约、实现、测试和审核证据。
- 用户控制、通知、恢复计划、记忆调度和 L0-L5 转移必须由服务端事实、确定性规则和可回放审计驱动，不能由 Flutter 本地状态或 LLM 输出直接写入最终事实。

## 上游来源
- `docs/product/stages/p0-2-training-memory.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/definition.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/traceability.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/requirements.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/requirements.md`
- `docs/reports/quality_report.md`
- P02-PG-001 GoalAchievementPolicy
- P02-PG-002 SupportedGoalMatrix
- P02-PG-003 AutopilotControlPolicy
- P02-PG-004 CommercialEntitlementAndCostPolicy
- P02-PG-005 DataGovernancePolicy

## Scope Decision
Followup-B 是 P0.2 自动带练、计划和记忆引擎的加固增量，不创建新 feature，也不替代原始 GoalBackplan 或 Autopilot increment。它关闭当前本地 deterministic slice 的关键缺口：系统虽然可以选择并完成 next action，也可以标记 skip/defer recovery，但还没有持久的 UserAutopilotControl 事实源、pause/resume/update-control 行为、生产可用通知调度语义、item-level memory algorithm，以及证据驱动的 L0-L5 promotion/demotion 规则。

## Scope
- 持久化 `UserAutopilotControl` 状态，覆盖 pause/resume、quiet hours、intensity override、notification consent 和 missed-day policy。
- pause/resume/update-control 的 API/OpenAPI 和 UX 契约，确保 autopilot prompt、next action 和 reminder 行为尊重用户显式控制。
- 生产安全的通知 eligibility、scheduler 或 outbox 语义，覆盖 quiet hours、consent、platform permission、entitlement 和 cancellation/replay。
- missed-day recovery，支持压缩、延期或替换任务，不堆积无法完成的过期任务。
- item-level MemoryCurvePolicy，基于遗忘风险、retrieval success、overlearning cap 和 interleaving 进行复习调度。
- L0-L5 promotion/demotion 由诊断、训练、复现和 checkpoint 证据驱动，禁止 AI 直接写入最终 mastery。
- Planner replay fixtures、确定性决策审计、p95 performance budgets 和 changed-code coverage >=80% 门禁。

## Stage Scope And WP Coverage
| Stage Scope ID | WP ID | Requirement ID | Policy Gate | Coverage status |
| --- | --- | --- | --- | --- |
| P02-SI-010 | P02-FUB-WP-001 | P02-FUB-FR-001 | P02-PG-002, P02-PG-003, P02-PG-005 | Covered |
| P02-SI-010 | P02-FUB-WP-002 | P02-FUB-FR-002 | P02-PG-002, P02-PG-003 | Covered |
| P02-SI-010 | P02-FUB-WP-003 | P02-FUB-FR-003 | P02-PG-003, P02-PG-004, P02-PG-005 | Covered |
| P02-SI-010 | P02-FUB-WP-004 | P02-FUB-FR-004 | P02-PG-003, P02-PG-005 | Covered |
| P02-SI-001, P02-SI-004, P02-SI-005, P02-SI-009 | P02-FUB-WP-005 | P02-FUB-FR-005 | P02-PG-002, P02-PG-003 | Covered |
| P02-SI-001, P02-SI-002, P02-SI-011 | P02-FUB-WP-006 | P02-FUB-FR-006 | P02-PG-001, P02-PG-003 | Covered |
| P02-SI-003, P02-SI-011 | P02-FUB-WP-007 | P02-FUB-FR-007 | P02-PG-001, P02-PG-003 | Covered |
| P02-SI-001, P02-SI-002, P02-SI-003, P02-SI-004, P02-SI-005, P02-SI-009, P02-SI-010, P02-SI-011 | P02-FUB-WP-008 | P02-FUB-FR-008 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | Covered |

## Policy Gate Coverage
| Policy Gate ID | Requirement coverage |
| --- | --- |
| P02-PG-001 | P02-FUB-FR-006, P02-FUB-FR-007, P02-FUB-FR-008 |
| P02-PG-002 | P02-FUB-FR-001, P02-FUB-FR-002, P02-FUB-FR-005, P02-FUB-FR-008 |
| P02-PG-003 | P02-FUB-FR-001, P02-FUB-FR-002, P02-FUB-FR-003, P02-FUB-FR-004, P02-FUB-FR-005, P02-FUB-FR-006, P02-FUB-FR-007, P02-FUB-FR-008 |
| P02-PG-004 | P02-FUB-FR-003, P02-FUB-FR-008 |
| P02-PG-005 | P02-FUB-FR-001, P02-FUB-FR-003, P02-FUB-FR-004, P02-FUB-FR-008 |

## 用户目标
学习者可以明确控制自动带练：随时暂停、恢复、调整强度、设置安静时段和通知偏好。系统在用户错过、跳过或延期训练时，能够用可完成的恢复计划继续推进目标；复习和 L0-L5 变化由可解释证据驱动，而不是由过期计划、UI 本地推断或 AI 输出直接决定。

## 用户路径
1. 用户拥有 active goal、daily plan 或待恢复状态时进入自动带练入口。
2. 系统读取服务端 UserAutopilotControl、目标支持状态、active plan、memory items、recent evidence 和 notification eligibility。
3. 用户可以暂停、恢复或更新控制设置，包括 quiet hours、intensity override、notification consent 和 missed-day policy。
4. 系统根据控制状态决定是否展示 next action、是否允许 reminder、是否需要 recovery/replan。
5. 用户错过、跳过或延期任务时，系统生成压缩、延期或替换后的恢复计划，且不把所有过期任务堆到同一天。
6. 系统按 item-level memory risk、retrieval success、overlearning cap 和 interleaving 选择复习任务。
7. 系统根据诊断、训练、复现和 checkpoint 证据推进或回退 L0-L5，并记录可回放决策审计。
8. 每个控制、通知、恢复、记忆和 mastery 决策都必须能追溯到输入快照、规则版本、reason code 和后续测试证据。

## Functional Requirements

### P02-FUB-FR-001 UserAutopilotControl 事实源
- 系统必须维护服务端拥有的 UserAutopilotControl 状态，不得从 GoalProfile 表单字段、Flutter 本地缓存或最近一次 UI 操作临时推断自动带练控制状态。
- UserAutopilotControl 必须覆盖 pause/resume、quiet hours、intensity override、notification consent、missed-day policy 和控制状态更新时间。
- 当目标 unsupported、partial、stale 或缺少必要 plan 输入时，UserAutopilotControl 不得让系统进入 full autopilot、完整 reminder cadence 或达标承诺路径。
- 控制状态必须支持审计、删除、保留、导出和敏感数据最小化要求。

### P02-FUB-FR-002 Pause、Resume And Update-Control 行为
- 用户暂停 autopilot 后，系统必须停止新的自动 prompt、next-action 推进和通知调度，同时保留可恢复的 goal、plan、memory 和 evidence 状态。
- 用户恢复 autopilot 后，系统必须重新评估 active plan、missed days、quiet hours、fatigue 和 supported/partial 状态，不得直接重放暂停期间过期的旧任务。
- 用户更新强度、quiet hours、notification consent 或 missed-day policy 后，next action、reminder eligibility 和必要的 replan/stale signal 必须随之更新。
- pause/resume/update-control 的结果必须对 UI 和后端决策一致可见，Flutter 不得本地绕过服务端控制事实。

### P02-FUB-FR-003 Quiet Hours And Notification Eligibility
- 系统必须在发送或安排任何自动提醒前检查 notification consent、quiet hours、platform permission、entitlement、quota/cost gate 和 active control state。
- quiet hours 或 permission 阻止提醒时，系统不得发送提醒，也不得把未发送提醒解释为用户完成、拒绝或失败。
- notification eligibility 必须产生可审计 reason code，供 UX 展示限制说明和 QA 回放。
- 通知相关状态必须遵守数据最小化、删除、保留和导出边界；不得在通知内容中暴露敏感诊断 transcript 或高风险目标细节。

### P02-FUB-FR-004 Notification Scheduler Or Outbox Integration
- 系统必须提供生产安全的 notification scheduler 或 notification outbox 语义，覆盖 schedule、cancel、reschedule、dedupe、failure recovery 和 replayable state。
- 当用户暂停、更新 quiet hours、撤回 consent、目标变为 stale/unsupported 或 entitlement 不允许提醒时，已安排但不再合规的提醒必须取消或转为不可发送状态。
- scheduler/outbox 必须记录输入快照、规则版本、reason code 和处理状态，以支持 deterministic replay 和独立审查。
- 调度失败不得产生重复提醒、过期提醒或不可解释的 next-action 状态；失败必须进入可恢复状态。

### P02-FUB-FR-005 Missed-Day Recovery Planner
- 系统必须在 missed day、skip、defer、暂停后恢复或计划过期时生成恢复计划，而不是把所有 overdue tasks 堆积到下一天。
- 恢复计划必须在每日可投入时间、疲劳保护、目标截止日期、当前 milestone、PlanItem 优先级和 supported/partial 状态之间做可解释取舍。
- 系统必须支持至少三类恢复结果：压缩任务、延期任务、替换为更小的复习或训练块。
- 恢复计划必须更新 daily/weekly planner 的 stale/replan 状态，并记录 reason code，便于后续 spec、AC、TC 和 replay fixture 验证。

### P02-FUB-FR-006 Item-Level MemoryCurvePolicy
- 系统必须把 MemoryCurvePolicy 下沉到 item level；复习调度必须基于单个表达、场景、弱项或训练项的遗忘风险和复现证据，而不是只按 session 或目标整体粗略调度。
- 每个 memory item 的 due decision 必须考虑 retrieval success、recent failures、exposure count、overlearning cap、interleaving rule、pressure level 和 daily time budget。
- overlearning cap 必须阻止系统在同一 item 上无限重复练习；interleaving rule 必须避免复习队列只集中在单一表达或单一弱项。
- item-level memory decision 必须可 replay；同一输入快照和规则版本必须产生相同 due/review/skip/defer 结果。

### P02-FUB-FR-007 L0-L5 Promotion And Demotion
- L0-L5 promotion/demotion 必须由接受后的诊断、训练表现、retrieval success、repeated failure、checkpoint evidence 和 confidence 共同驱动。
- AI 输出可以作为候选解释或候选观察，但不得直接写入 final mastery、promotion/demotion、review schedule 或 goal completion。
- 低置信度、证据不足、partial goal、unsupported content 或疲劳保护触发时，系统不得把 mastery 强行提升到更高等级。
- mastery 下降、保持或提升都必须记录 transition reason、evidence references、rule version 和 audit trail，支持后续回放与用户可解释展示。

### P02-FUB-FR-008 Replay、Performance And Coverage Gates
- Followup-B 后续实现必须提供 planner/control/memory/mastery replay fixtures，覆盖 pause、resume、update-control、quiet hours、notification eligibility、scheduler/outbox、missed-day recovery、item-level memory 和 L0-L5 transitions。
- 后续 AC-to-TC library 必须把每个 Followup-B AC 映射到稳定 TC ID 或明确允许例外；没有 AC-to-TC 映射前不得进入 backend、frontend、AI runtime、DevOps 或 QA 实现。
- changed backend/domain/API/Flutter code 的 line 和 branch coverage 必须 >=80%；若某层没有代码变更，必须在 test evidence 中明确标记 N/A reason。
- 性能预算必须至少覆盖 control state load、pause/resume/update-control、notification eligibility、recovery replan、item-level memory due calculation、L0-L5 transition decision 和 replay verification；p95 预算值必须在 spec/test_cases 阶段固化并在实现后提供证据。
- 任何 implementation report 或 quality report 不得把 Followup-B 标记为完成，除非 FR、Spec、AC、TC、Traceability、契约、代码、测试、coverage、performance/replay 和独立审核证据全部闭环。

## 需求到验收交接备注
| Requirement ID | 验收生成时必须关注的可观察行为 | 必须保留的追溯字段 |
| --- | --- | --- |
| P02-FUB-FR-001 | 服务端控制事实存在、UI 不本地推断、unsupported/partial 不进入 full autopilot、控制数据可治理 | Stage Scope ID、WP ID、Policy Gate、control state source、data-governance evidence |
| P02-FUB-FR-002 | pause 后停止 prompt/reminder，resume 后重新评估计划，update-control 影响 next action 和 reminder eligibility | Stage Scope ID、WP ID、Policy Gate、control update reason、plan stale/replan signal |
| P02-FUB-FR-003 | consent、quiet hours、permission、entitlement 和 quota/cost gate 阻止不合规提醒，并产生 reason code | Stage Scope ID、WP ID、Policy Gate、notification eligibility reason、privacy boundary |
| P02-FUB-FR-004 | schedule/cancel/reschedule/dedupe/failure recovery 可审计，暂停或撤回 consent 后不发送旧提醒 | Stage Scope ID、WP ID、Policy Gate、scheduler/outbox state、replay input snapshot |
| P02-FUB-FR-005 | missed/skip/defer 触发压缩、延期或替换，不堆积不可完成任务，并尊重每日时间预算 | Stage Scope ID、WP ID、Policy Gate、recovery mode、planner reason code |
| P02-FUB-FR-006 | item-level due decision 使用遗忘风险、retrieval success、overlearning cap 和 interleaving，且可 replay | Stage Scope ID、WP ID、Policy Gate、memory item id、policy version、replay fixture |
| P02-FUB-FR-007 | L0-L5 只由证据和 confidence 推进或回退，AI direct-write 被拒绝 | Stage Scope ID、WP ID、Policy Gate、evidence refs、transition reason、AI forbidden field check |
| P02-FUB-FR-008 | replay、coverage、performance 和 AC-to-TC gate 阻止未验证实现进入完成状态 | Stage Scope ID、WP ID、Policy Gate、TC ID、command、result、coverage/performance evidence |

Acceptance、test_cases 和 traceability 已从上述 FR 派生并保持稳定 ID。后续不得在本文件中补写通过状态；任何执行证据必须写入 `test_cases.md`、`traceability.md`、`docs/reports/test_report.md` 或 `docs/reports/quality_report.md`。

## 下游交接边界
- `spec.md`、`acceptance.md`、`test_cases.md`、`traceability.md`、domain/API/OpenAPI/UX/AI contracts 和 reports may consume this file as the Followup-B requirement source of truth, but they must not renumber or redefine P02-FUB-FR-001 through P02-FUB-FR-008 without a versioned Followup-B change.
- Implementation and test execution status belongs in `test_cases.md`, `traceability.md`, `docs/reports/test_report.md`, `docs/reports/implementation_report.md` and `docs/reports/quality_report.md`; this file may summarize current workflow status but must not replace evidence records.
- 本文件不声明 release 已批准，也不把 partial control-slice evidence 解释为 Followup-B 全量完成。
- Remaining code implementation still requires approved spec, approved AC, AC-to-TC mapping, contract alignment and independent checker pass finding for the routed slice.

## Excluded Stage Scope Items
- P02-SI-007 和 P02-SI-008 是 Followup-A 的上游输入，不在 Followup-B 中实现。
- P02-SI-006、P02-SI-012 和 P02-SI-013 路由到 Followup-C。
- release-wide feature flag、kill switch、telemetry、commercial/cost、paid AI evidence、Product Base merge 和 release approval 路由到 Followup-D。

## 非目标
- 不实现可编辑 GoalProfile 表单或诊断样本采集。
- 不实现 Queue/Wiki surface propagation 或 checkpoint task library。
- 不关闭 release-wide commercial、paid AI external evidence、store 或 Product Base merge approval。
