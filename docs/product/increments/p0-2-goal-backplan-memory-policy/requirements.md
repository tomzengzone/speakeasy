# P0.2 Increment Requirements：目标倒排计划与记忆曲线策略

## 状态
Design-ready / implementation gated - 本文件把 `p0-2-goal-backplan-memory-policy` 的 P02-SI 和 P02-PG 下沉为可测试需求；尚未进入实现。

## Product Object
- Classification: `feature-increment`
- Increment: `p0-2-goal-backplan-memory-policy`
- Active stage: `docs/product/stages/p0-2-training-memory.md`
- Primary Capability ID：`CAP-PLAN`
- Primary Sub-capability ID：`CAP-PLAN-03`
- Affected Capability IDs：`CAP-MEMORY`、`CAP-TRAIN`、`CAP-INTENT`、`CAP-LEVEL`、`CAP-CONTENT`
- Affected Sub-capability IDs：`CAP-PLAN-01`、`CAP-PLAN-02`、`CAP-PLAN-05`、`CAP-PLAN-06`、`CAP-PLAN-07`、`CAP-MEMORY-02`、`CAP-MEMORY-03`、`CAP-MEMORY-04`、`CAP-TRAIN-01`、`CAP-TRAIN-02`、`CAP-TRAIN-03`、`CAP-TRAIN-05`、`CAP-INTENT-04`、`CAP-INTENT-06`、`CAP-LEVEL-04`、`CAP-LEVEL-05`、`CAP-CONTENT-03`

## 上游来源
- `docs/product/stages/p0-2-training-memory.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/definition.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md`
- P02-PG-001 GoalAchievementPolicy
- P02-PG-002 SupportedGoalMatrix
- P02-PG-003 AutopilotControlPolicy
- P02-PG-004 CommercialEntitlementAndCostPolicy
- P02-PG-005 DataGovernancePolicy

## Stage Scope Coverage
| Stage Scope ID | Requirement ID | Coverage status |
| --- | --- | --- |
| P02-SI-001 | P02-PLAN-FR-003 | Covered |
| P02-SI-002 | P02-PLAN-FR-005 | Covered |
| P02-SI-003 | P02-PLAN-FR-004 | Covered |
| P02-SI-004 | P02-PLAN-FR-002 | Covered |
| P02-SI-005 | P02-PLAN-FR-006 | Covered |
| P02-SI-009 | P02-PLAN-FR-001, P02-PLAN-FR-002 | Covered |
| P02-SI-011 | P02-PLAN-FR-004, P02-PLAN-FR-005 | Covered |
| P02 policy gates | P02-PLAN-FR-007, P02-PLAN-FR-008 | Covered |

## 用户目标
学习者不需要自己决定今天练什么。系统根据目标、诊断、每日可投入时间、内容支持和记忆曲线，生成可执行的周计划、日计划和每次训练内容，并能在用户跳过、复习到期、遗忘风险升高或目标改变时重算计划。

## 用户路径
1. 系统读取 active GoalProfile、DiagnosticAssessment、SupportedGoalMatrixDecision、弱项和初始 mastery。
2. 系统判断目标是否 supported/partial；unsupported 目标不得生成完整计划。
3. 系统倒排目标到周计划、日计划和 session plan。
4. 系统按 memory curve、weakness、unfinished session、current scenario 和 goal milestone 选择今日训练。
5. 系统记录 planner decision、reason code、rule version、input snapshot 和 replay fixture。
6. 用户跳过、暂停、时间变少或目标调整时，系统重算计划并保留审计。

## Functional Requirements

### P02-PLAN-FR-001 GoalBackplan 输入契约
- 系统必须只使用 active GoalProfile revision、DiagnosticAssessment、SupportedGoalMatrixDecision、accepted learning evidence 和 reviewed content mapping 作为计划输入。
- 低置信度诊断或 partial goal 必须生成保守计划或限制说明。
- 缺少必要输入时必须 fail closed，不得由 LLM 即兴生成完整计划。

### P02-PLAN-FR-002 周计划与长期 session planner
- 系统必须从目标截止日期、每日分钟数、强度偏好和目标差距倒排周计划。
- 周计划必须包含 milestone、session count、review windows、checkpoint dependency 和 stale-plan 标记。
- 目标变更、诊断更新或 checkpoint 结果变化时，计划必须可重算并保留旧版本审计。

### P02-PLAN-FR-003 Daily training planner
- 系统必须每天生成可执行 daily plan，包含训练、复习、复测准备或轻量恢复任务。
- Daily plan 必须尊重每日时间预算，并提供最小训练块和过载保护。
- 当 due review、weakness、unfinished session、current scenario goal 冲突时，系统必须按确定性优先级选择并记录 reason code。

### P02-PLAN-FR-004 MemoryCurvePolicy 与 L0-L5
- 系统必须定义间隔复习、遗忘风险、复现、过度学习和 interleaving 规则。
- L0-L5 状态推进必须由诊断、训练证据、复现结果和 checkpoint 证据驱动。
- LLM 不得直接写入 final mastery、review schedule 或 goal completion。

### P02-PLAN-FR-005 Cross-session pressure ladder
- 系统必须基于 mastery、target gap、memory risk 和 recent performance 调整跨 session pressure。
- Pressure ladder 必须减少提示、增加复现要求或插入更近真实场景，但不能越过用户控制和疲劳保护。
- Pressure 升降级必须可 replay。

### P02-PLAN-FR-006 Cross-day orchestration
- 系统必须把到期复习、薄弱表达、未完成 session、当前目标场景和 goal milestone 编排到跨天计划。
- 未完成 session 必须有继续、压缩、延期或重算路径。
- 用户 missed day 后必须进入恢复计划，不得简单堆积所有过期任务。

### P02-PLAN-FR-007 Planner feasibility、商业和数据治理
- 系统必须覆盖 P02-PG-002、P02-PG-003、P02-PG-004 和 P02-PG-005。
- 计划深度、AI plan explanation 和复习调度必须受 entitlement、quota、AI budget 和低成本 fallback 管理。
- Planner snapshots 必须最小化敏感诊断和 transcript 数据，并支持删除、保留和解释。

### P02-PLAN-FR-008 性能、覆盖率与实现门禁
- 后续实现必须提供 deterministic unit/integration/replay tests。
- Changed backend/domain/API/Flutter code 的 line 和 branch coverage 必须 >=80%。
- 计划生成、memory due calculation、planner replay 和 stale-plan recomputation 必须通过性能预算测试。

## 非目标
- 不实现目标画像和初始诊断采集；这些来自 upstream diagnostic increment。
- 不实现自动带练 UI、通知、progress forecast 或 checkpoint loop；这些属于 autopilot increment。
- 不新增完整内容体系、CMS 或任意场景生成。
- 不关闭 P0 commercial release 或 paid AI voice gates。
