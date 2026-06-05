# P0.2 Followup-C Requirements：周期复测、预测与多产品面加固

## 状态
S001 forecast hardening、S002 checkpoint task library and S003 checkpoint-to-plan locally implemented and tested / S004-S007 implementation gated - 本文件定义 `p0-2-followup-c-checkpoint-forecast-surfaces` 的需求边界，并把 Followup-C 拆分为 S000-S007 小粒度 slice。S000 文档链、AC-to-TC 规划、traceability 入口和独立审核已完成；S001 已完成 ProgressForecast model hardening 的本地代码、contract 和 TC-P02-FUC-001..003 测试证据；S002 已完成 Checkpoint cadence/task library 的本地代码、contract 和 TC-P02-FUC-004..006 测试证据；S003 已完成 Checkpoint-to-plan update 的本地代码、contract、TC-P02-FUC-007..009 测试证据和独立审核；S004-S007 尚未进入代码实现。Followup-C is not release-ready；Product Base merge is not approved。

## Product Object
- 分类：`feature-increment`
- Increment：`p0-2-followup-c-checkpoint-forecast-surfaces`
- Active stage：`docs/product/stages/p0-2-training-memory.md`
- Primary feature：`goal-driven-learning-autopilot`
- Affected features：`learning-memory-review`、`expression-practice-queue`、`profile-membership`、`scoring-feedback`、`official-scenario-library`

## 需求假设
- Followup-A 已提供 GoalProfile、DiagnosticAssessment、goal revision/stale 可见化和 no-goal Explore Mode 的上游事实边界。
- Followup-B 已为 UserAutopilotControl、pause/resume/update-control、notification eligibility/outbox、missed-day recovery、item-level MemoryCurvePolicy 和 L0-L5 transition 建立本地证据；Followup-C 不重新实现这些能力。
- 既有 `p0-2-autopilot-progress-checkpoint` 本地垂直切片已有 deterministic forecast/checkpoint 记录和 Home learn-tab surface，但 Queue/Wiki propagation、checkpoint task library、explainable forecast 和 backend-owned projection 仍未闭环。
- Home、expression queue 和 personal Wiki 只能消费 backend/autopilot facts 或 backend-owned projection，不能本地重算 final goal state、goal completion、ETA 或 official-score 等价结论。

## 上游来源
- `docs/product/stages/p0-2-training-memory.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/definition.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/traceability.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/requirements.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/spec.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/traceability.md`
- `docs/reports/quality_report.md`
- P02-PG-001 GoalAchievementPolicy
- P02-PG-002 SupportedGoalMatrix
- P02-PG-003 AutopilotControlPolicy
- P02-PG-004 CommercialEntitlementAndCostPolicy
- P02-PG-005 DataGovernancePolicy

## Scope Decision
Followup-C 是 P0.2 自动带练的 forecast、checkpoint 和多产品面 projection 加固增量。它不创建新 feature，也不替代原始 `p0-2-autopilot-progress-checkpoint`；它关闭当前本地 deterministic slice 的剩余缺口：forecast 需要可解释 gap/ETA/risk/claim guard，checkpoint 需要 cadence 与 goal-type task library，checkpoint result 需要稳定触发 forecast/replan/surface update，Home/Queue/Wiki 需要从服务端投影读取 goal-progress facts，并在删除、不可用、unsupported 或低置信度时降级。

## Scope
- S000：补齐 Followup-C requirements、spec、acceptance、test_cases，并把 S000-S007 routing 写入 definition 和 traceability。
- S001：加固 ProgressForecast model，输出 explainable gap、ETA range、confidence、risk reason、next checkpoint 和 claim guard。
- S002：定义并实现 OutcomeCheckpoint cadence 和 goal-type task library，按 supported/partial/unsupported goal coverage 限制 checkpoint 格式。
- S003：checkpoint result 必须更新 evidence、forecast 和 plan stale/replan signal，且低置信度或失败 checkpoint 不得标记达成。
- S004：建立 backend-owned goal-progress projection，作为 Home、Queue、Wiki surface 的事实源。
- S005：Home、expression queue、personal Wiki 三个产品面都必须消费 projection 才能关闭 full S005；可分支路由为 S005-A/B/C，但一处或两处产品面只能作为 partial milestone。
- S006：数据删除、不可用、unsupported、partial 和 low-confidence 时，surface 必须移除敏感展示或降级。
- S007：建立 Followup-C 自动化测试、performance、coverage、traceability script 和独立审核门禁。

## Stage Scope And Slice Coverage
| Stage Scope ID | Slice ID | Requirement ID | Policy Gate | Coverage status |
| --- | --- | --- | --- | --- |
| P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-FUC-S000 | P02-FUC-FR-000 | P02-PG-001..005 | Covered for documentation chain and routing only |
| P02-SI-012 | P02-FUC-S001 | P02-FUC-FR-001 | P02-PG-001, P02-PG-002, P02-PG-004 | Covered |
| P02-SI-013 | P02-FUC-S002 | P02-FUC-FR-002 | P02-PG-001, P02-PG-002, P02-PG-004 | Covered |
| P02-SI-012, P02-SI-013 | P02-FUC-S003 | P02-FUC-FR-003 | P02-PG-001, P02-PG-003 | Covered |
| P02-SI-006 | P02-FUC-S004 | P02-FUC-FR-004 | P02-PG-003, P02-PG-005 | Covered |
| P02-SI-006, P02-SI-010 | P02-FUC-S005 | P02-FUC-FR-005 | P02-PG-003, P02-PG-005 | Covered |
| P02-SI-006 | P02-FUC-S006 | P02-FUC-FR-006 | P02-PG-001, P02-PG-002, P02-PG-005 | Covered |
| P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-FUC-S007 | P02-FUC-FR-007 | P02-PG-001..005 | Covered |

## Policy Gate Coverage
| Policy Gate ID | Requirement coverage |
| --- | --- |
| P02-PG-001 | P02-FUC-FR-001, P02-FUC-FR-002, P02-FUC-FR-003, P02-FUC-FR-006, P02-FUC-FR-007 |
| P02-PG-002 | P02-FUC-FR-001, P02-FUC-FR-002, P02-FUC-FR-006, P02-FUC-FR-007 |
| P02-PG-003 | P02-FUC-FR-003, P02-FUC-FR-004, P02-FUC-FR-005, P02-FUC-FR-007 |
| P02-PG-004 | P02-FUC-FR-001, P02-FUC-FR-002, P02-FUC-FR-007 |
| P02-PG-005 | P02-FUC-FR-004, P02-FUC-FR-005, P02-FUC-FR-006, P02-FUC-FR-007 |

## 用户目标
学习者能看到可信、克制且可解释的目标进度：当前距目标差多少、为什么存在风险、下一次什么时候复测、最近 checkpoint 说明了什么，以及今天应该继续训练、复习还是复测。Home、表达队列和个人 Wiki 展示的是同一套服务端目标进度事实，而不是各自推断出的不一致状态。

## 用户路径
1. 用户已有 active goal、diagnostic、daily plan、control state 和 forecast/checkpoint facts。
2. 系统根据 accepted evidence、checkpoint history、supported goal coverage、control/recovery state 和 claim guard 计算 ProgressForecast。
3. checkpoint 到期时，系统根据 goal type 和 supported content coverage 选择 weekly/biweekly/mock/business-task 等任务格式。
4. 用户提交 checkpoint 或 checkpoint 失败/跳过/低置信度后，系统更新 checkpoint result、forecast、risk 和 plan stale/replan signal。
5. 后端生成 goal-progress projection，供 Home、expression queue 和 personal Wiki 消费。
6. 产品面展示 next action、goal gap、risk 或 checkpoint conclusion 中适用的信息，并提供进入训练/复习/复测的行动入口。
7. 当 goal data 被删除、不可用、unsupported、partial 或 low-confidence 时，产品面展示降级状态，不继续显示敏感目标进度、精确 ETA 或 goal-complete copy。
8. 每个 forecast、checkpoint、projection 和 surface downgrade 决策都必须能追溯到 FR、Spec、AC、TC、policy gate、code/test evidence 和质量审核。

## Functional Requirements

### P02-FUC-FR-000 S000 文档链和 slice routing
- 系统必须在代码实现前补齐 Followup-C 的 `requirements.md`、`spec.md`、`acceptance.md`、`test_cases.md`，并更新 `definition.md` 与 `traceability.md`。
- 文档链必须包含 S000-S007 slice routing、FR/Spec/AC/TC mapping、gap register、test/report evidence 入口和 release/Product Base 非目标说明。
- S000 只能声明 documentation-chain ready；S001 只能声明 ProgressForecast hardening local evidence ready；S002 只能声明 checkpoint cadence/task-library local evidence ready；S003 只能声明 checkpoint-to-plan local evidence ready；不得声明 S004-S007 已实现、Followup-C release-ready 或 Product Base-ready。
- S000 必须通过独立 traceability/quality review，确认切片粒度、上游 Stage Scope、policy gate、AC-to-TC 和后续证据入口一致。

### P02-FUC-FR-001 ProgressForecast model hardening
- 系统必须输出 explainable gap summary、ETA range、confidence band、risk level、risk reason、next checkpoint date 和 claim guard。
- Forecast 必须区分 supported、partial、unsupported、low-confidence 和 stale/replan 状态；低置信度、partial 或 unsupported goal 不得展示高精度 ETA。
- ETA 必须以 range 或 unavailable reason 表达，不得承诺 guaranteed achievement、official score equivalence 或官方考试认证。
- Forecast risk reason 必须能引用 accepted evidence、checkpoint history、plan/control/recovery state 或 supported goal limitation，而不是只输出泛化文案。
- Forecast explanation 若使用 AI/provider，只能作为 candidate explanation，并必须服从 entitlement、quota 和 cost fallback；被 quota/cost/policy 阻断时必须回退到 deterministic explanation key，不得创建或推断商业权益事实源。

### P02-FUC-FR-002 Checkpoint cadence and task library
- 系统必须定义 checkpoint cadence，至少支持 weekly、biweekly 和 due-now/overdue decision。
- checkpoint task library 必须按 supported goal type 和 content coverage 决定可用任务格式；不支持或 partial coverage 的目标必须限制 checkpoint depth。
- checkpoint task 必须返回 task type、cadence、prompt/task reference、estimated duration、required evidence、scoring/rubric boundary 和 limitation reason。
- checkpoint depth、AI explanation 或 provider use 必须服从 entitlement、quota 和 cost fallback；Followup-C 不创建商业权益事实源。

### P02-FUC-FR-003 Checkpoint-to-plan update
- checkpoint result 必须更新 checkpoint record、accepted evidence reference、forecast、risk reason 和 plan stale/replan signal。
- checkpoint 失败、跳过、低置信度或 unsupported task 不得标记 goal complete，也不得生成高精度 ETA。
- checkpoint result 触发 plan stale/replan 时，必须保留 reason code、source checkpoint、input snapshot hash 或等价 replay/audit 证据。
- checkpoint result 必须和 Followup-B 的 autopilot control/recovery 事实兼容：paused、blocked、recovery-required 或 stale plan 时不得静默推进下一步行动。

### P02-FUC-FR-004 Backend goal-progress projection
- 系统必须建立 backend-owned goal-progress projection，聚合 active goal、next action、forecast、latest checkpoint、risk、surface eligibility 和 downgrade reason。
- Home、expression queue 和 personal Wiki 必须读取 projection 或由同一 backend fact source 生成的 projection fragment，不得本地计算 final goal state、goal complete、ETA 或 claim guard。
- Projection 必须包含 surface-specific safe fields，避免把 raw diagnostic transcript、sensitive target details 或 raw notification/checkpoint payload 暴露给不需要的产品面。
- Projection 必须可删除、可导出或在数据不可用时返回安全 unavailable/downgraded 状态。

### P02-FUC-FR-005 Home/Queue/Wiki surface propagation
- Home、expression queue 和 personal Wiki 三个产品面必须展示 backend projection 中适用的 next action、gap、risk 或 checkpoint conclusion，才可关闭 full S005 和 Followup-C local completion。
- 一处或两处产品面完成时只能标记对应 S005-A/B/C partial milestone；不得把 partial milestone 解释为 P02-SI-006 的完整落地。
- Home surface 必须继续承担 goal autopilot overview 和 next action 入口，但不得成为唯一 goal-progress surface。
- Expression queue surface 必须能在队列项、队列 header 或 next action 区域展示目标相关理由，且不得用 UI 本地排序替代 backend-owned projection。
- Personal Wiki surface 必须能展示最近 checkpoint conclusion、目标弱项或下一步复习说明，并保留数据最小化边界。
- Surface 文案必须使用产品内进度/复测语言，不得宣称官方考试分数认证、保证达成或未证实的会员权益。

### P02-FUC-FR-006 Surface deletion/unavailable downgrade
- 当用户删除 goal/checkpoint/forecast data、账号删除清理执行、数据不可用、goal unsupported、partial 或 low-confidence 时，surface 必须移除敏感进度或显示明确降级状态。
- 降级状态必须说明原因类型，例如 `deleted`, `unavailable`, `unsupported_goal`, `partial_goal_limited`, `low_confidence`, `stale_plan` 或 `control_blocked`。
- 降级后不得保留旧的 gap、ETA、checkpoint conclusion、goal-complete copy 或 sensitive target details。
- 降级必须有 backend/API 和 Flutter/widget 测试覆盖，确保 Home/Queue/Wiki 不通过缓存继续显示过期敏感信息。

### P02-FUC-FR-007 Automated tests, performance, coverage and review gates
- Followup-C 后续实现必须提供 API/contract、backend integration、Flutter widget/integration、performance、coverage 和 traceability gate。
- 每个 AC 必须映射到稳定 TC ID；没有 AC-to-TC mapping 前不得路由 S001-S007 代码实现。
- changed backend/domain/API/Flutter code 的 line 和 branch coverage 必须 >=80%；若某层没有代码变更，必须在 test evidence 中明确标记 `N/A - no code change in this layer`。
- 性能预算至少覆盖 forecast recompute、checkpoint task library lookup、checkpoint submit accepted/queued、projection load 和 surface propagation。
- Followup-C 必须有 dedicated traceability script 或等价 checker，在 S007 关闭前验证 requirements/spec/acceptance/test_cases/traceability/report evidence 一致。
- 独立审核必须记录在质量报告或最终审查结论中，且不得把 S000 文档链完成误写为 Followup-C release-ready。

## 需求到验收交接备注
| Requirement ID | 验收生成时必须关注的可观察行为 | 必须保留的追溯字段 |
| --- | --- | --- |
| P02-FUC-FR-000 | 文档链完整、S000-S007 routing 存在、未实现 slice 未被误标实现 | Stage Scope ID、Slice ID、Policy Gate、S000 review evidence |
| P02-FUC-FR-001 | Forecast 有 gap/ETA range/confidence/risk/claim guard，低置信度不显示精确 ETA，AI explanation 受 entitlement/quota/cost fallback 约束 | forecast reason、confidence band、claim guard、checkpoint refs、AI/cost fallback decision |
| P02-FUC-FR-002 | checkpoint cadence/task library 按 goal type 和 content coverage 限制任务 | goal type、cadence、task type、content coverage、entitlement/cost boundary |
| P02-FUC-FR-003 | checkpoint result 更新 forecast 与 stale/replan signal，失败/低置信度不标记达成 | checkpoint id、plan update reason、input snapshot/replay evidence |
| P02-FUC-FR-004 | projection 由 backend 拥有，surface 不本地计算 final goal state | projection id、surface type、source fact refs、safe field list |
| P02-FUC-FR-005 | Home/Queue/Wiki 三个 surface 都消费 projection；partial milestone 不等于 full S005 closure | surface coverage、widget/API evidence、source-of-truth review、partial/full closure marker |
| P02-FUC-FR-006 | 删除、不可用、unsupported、partial、low-confidence 时移除或降级敏感进度 | downgrade reason、data governance evidence、cache invalidation evidence |
| P02-FUC-FR-007 | AC-to-TC、coverage、performance、traceability script 和 independent review 阻止未验证实现完成 | TC ID、command、result、coverage/performance evidence、quality review |

## 下游交接边界
- `spec.md`、`acceptance.md`、`test_cases.md`、`traceability.md`、domain/API/OpenAPI/UX/AI contracts 和 reports may consume this file as the Followup-C requirement source of truth, but they must not renumber or redefine P02-FUC-FR-000 through P02-FUC-FR-007 without a versioned Followup-C change.
- Implementation and test execution status belongs in `test_cases.md`, `traceability.md`, `docs/reports/test_report.md`, `docs/reports/implementation_report.md` and `docs/reports/quality_report.md`; this file may summarize current workflow status but must not replace executable evidence records.
- S001 forecast hardening local completion, S002 checkpoint task-library local completion and S003 checkpoint-to-plan local completion do not approve S004-S007 code implementation, release readiness, paid AI/provider evidence, Product Base merge or commercial gates.

## Excluded Stage Scope Items
- P02-SI-007 和 P02-SI-008 是 Followup-A 的上游输入，不在 Followup-C 中实现。
- P02-SI-001、P02-SI-002、P02-SI-003、P02-SI-004、P02-SI-005、P02-SI-009 和 P02-SI-011 已路由到 Followup-B，不在 Followup-C 中重新实现。
- release-wide feature flag、kill switch、telemetry、commercial/cost、paid AI evidence、Product Base merge 和 release approval 路由到 Followup-D。

## 非目标
- 不实现可编辑 GoalProfile 表单或诊断样本采集。
- 不实现 pause/resume/control scheduler、missed-day recovery、item-level memory 或 L0-L5 transition。
- 不创建商业权益事实源，不关闭 P0 commercial release、paid AI external evidence、store/reviewer 或 Product Base merge approval。
- 不承诺官方考试认证、官方分数等价或 guaranteed achievement。
