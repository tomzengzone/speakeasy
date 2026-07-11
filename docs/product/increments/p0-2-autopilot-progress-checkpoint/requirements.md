# P0.2 Increment Requirements：自动带练、进度预测与周期复测

## 状态
Design-ready / implementation gated - 本文件把 `p0-2-autopilot-progress-checkpoint` 的 P02-SI 和 P02-PG 下沉为可测试需求；尚未进入实现。

## Product Object
- Classification: `feature-increment`
- Increment: `p0-2-autopilot-progress-checkpoint`
- Active stage: `docs/product/stages/p0-2-training-memory.md`
- Primary Capability ID：`CAP-TRAIN`
- Primary Sub-capability ID：`CAP-TRAIN-02`
- Affected Capability IDs：`CAP-PLAN`、`CAP-MEMORY`、`CAP-LEVEL`、`CAP-ENGAGE`、`CAP-COM`、`CAP-ACC`
- Affected Sub-capability IDs：`CAP-TRAIN-01`、`CAP-TRAIN-03`、`CAP-TRAIN-05`、`CAP-TRAIN-06`、`CAP-PLAN-05`、`CAP-PLAN-06`、`CAP-PLAN-07`、`CAP-MEMORY-03`、`CAP-MEMORY-04`、`CAP-MEMORY-05`、`CAP-LEVEL-02`、`CAP-LEVEL-06`、`CAP-ENGAGE-01`、`CAP-ENGAGE-02`、`CAP-COM-01`、`CAP-COM-03`、`CAP-ACC-03`

## 上游来源
- `docs/product/stages/p0-2-training-memory.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/definition.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/traceability.md`
- P02-PG-001 GoalAchievementPolicy
- P02-PG-002 SupportedGoalMatrix
- P02-PG-003 AutopilotControlPolicy
- P02-PG-004 CommercialEntitlementAndCostPolicy
- P02-PG-005 DataGovernancePolicy

## Stage Scope Coverage
| Stage Scope ID | Requirement ID | Coverage status |
| --- | --- | --- |
| P02-SI-006 | P02-AUTO-FR-006 | Covered |
| P02-SI-010 | P02-AUTO-FR-001, P02-AUTO-FR-002, P02-AUTO-FR-003 | Covered |
| P02-SI-012 | P02-AUTO-FR-004 | Covered |
| P02-SI-013 | P02-AUTO-FR-005 | Covered |
| P02 policy gates | P02-AUTO-FR-007, P02-AUTO-FR-008 | Covered |

## 用户目标
学习者不需要自律地决定下一步。系统自动把用户带入今天最合适的训练、复习或复测，展示距目标差距、预计达标日期和风险，并通过每周或双周 checkpoint 更新计划。

## 用户路径
1. 用户打开 App 或收到允许的提醒。
2. 系统读取 active daily plan 和用户控制设置，展示唯一主行动：开始、继续、复习或复测。
3. 用户可以一键开始，也可以暂停、跳过、降低强度、设置安静时段或恢复 missed day。
4. 系统完成训练/复习/复测后更新 evidence surface、ProgressForecast 和必要的 plan stale/replan 信号。
5. 每周或双周 OutcomeCheckpoint 运行后，系统更新目标差距、风险、计划和用户可见解释。

## Functional Requirements

### P02-AUTO-FR-001 Autopilot 输入契约
- 系统必须只消费 active GoalProfile、DiagnosticAssessment、DailyTrainingPlan、PlanItem、MemoryCurvePolicy 和 SupportedGoalMatrixDecision。
- 当 upstream plan stale、unsupported 或 partial 时，autopilot 必须显示限制或恢复路径，不得伪装为 full autopilot。
- Autopilot 不得创建商业权益事实源、final mastery 或官方分数认证。

### P02-AUTO-FR-002 No-choice daily execution
- 系统必须在首页或训练入口展示一个清晰的主行动，自动选择训练、复习、继续 session 或 checkpoint。
- 用户不需要手动规划下一步，但系统必须允许开始前查看原因。
- 当前主行动必须引用 plan item、reason code 和 expected duration。

### P02-AUTO-FR-003 用户控制、暂停和恢复
- 系统必须支持 pause/resume、skip/defer、降低强度、quiet hours、notification cadence 和 missed-day recovery。
- 用户跳过或错过训练后，系统必须进入恢复计划，不得羞辱、惩罚或堆积不可完成任务。
- 自动提醒必须受 consent、quiet hours、entitlement 和 platform permission 管理。

### P02-AUTO-FR-004 ProgressForecast
- 系统必须展示当前距目标差距、预计达标日期或区间、风险原因和下一次复测时间。
- Forecast 必须带 confidence/uncertainty，不得对低置信度或 partial goal 显示高精度 ETA。
- 目标完成状态必须由 checkpoint evidence 和 GoalAchievementPolicy 决定。

### P02-AUTO-FR-005 OutcomeCheckpoint
- 系统必须支持每周或每两周 checkpoint，格式必须匹配 supported goal type。
- Checkpoint 必须更新 diagnostic-like evidence、goal gap、risk、plan stale/replan signal 和用户可见解释。
- Checkpoint 不得声明官方考试认证或保证分数。

### P02-AUTO-FR-006 Goal progress surfaces
- 系统必须把目标进度和训练证据进入首页、表达队列和个人 Wiki 中至少两个产品面。
- Surface 必须显示下一步行动、目标差距、风险或最近 checkpoint 结论中的适用信息。
- Surface 不得创建新的学习事实源；必须从 backend/autopilot事实读取。

### P02-AUTO-FR-007 Commercial、claim 和数据治理
- 系统必须覆盖 P02-PG-001 through P02-PG-005。
- Free/paid autopilot depth、AI voice/checkpoint cost、quota exhaustion 和 membership value display 必须由服务端 entitlement/cost policy 决定。
- Checkpoint audio/result、forecast explanation、notification consent 和 progress data 必须具备 retention、deletion/export、audit trail 和数据最小化规则。

### P02-AUTO-FR-008 性能、覆盖率和运营门禁
- 后续实现必须有 widget/integration/API/AI-eval/release-check 测试，覆盖成功、失败、partial、unsupported、quota、quiet hours 和 stale-plan 场景。
- Changed backend/domain/API/Flutter code 的 line 和 branch coverage 必须 >=80%。
- Autopilot state load、forecast recompute、checkpoint submit 和 surface propagation 必须通过性能预算测试。

## 非目标
- 不创建 GoalProfile、DiagnosticAssessment 或 backplan/memory policy；这些来自 upstream increments。
- 不承诺官方考试认证或保证分数。
- 不新增 P1/P2 内容体系、CMS、任意场景或商业权益事实源。
- 不关闭 P0 commercial release、paid AI voice 或 store/reviewer 外部门禁。
