# P0.2 Increment Requirements：目标画像与诊断基础

## 状态
Design-ready / implementation gated - 本文件把 `p0-2-goal-diagnostic-foundation` 的 P02-SI 和 P02-PG 下沉为可测试需求；尚未进入实现。

## Product Object
- Classification: `feature-increment`
- Increment: `p0-2-goal-diagnostic-foundation`
- Active stage: `docs/product/stages/p0-2-training-memory.md`
- Primary Capability ID：`CAP-INTENT`
- Primary Sub-capability ID：`CAP-INTENT-01`
- Affected Capability IDs：`CAP-LEVEL`、`CAP-PLAN`、`CAP-MEMORY`、`CAP-COACH`、`CAP-CONTENT`
- Affected Sub-capability IDs：`CAP-INTENT-04`、`CAP-INTENT-06`、`CAP-LEVEL-02`、`CAP-LEVEL-03`、`CAP-LEVEL-04`、`CAP-LEVEL-05`、`CAP-PLAN-01`、`CAP-MEMORY-02`、`CAP-MEMORY-03`、`CAP-COACH-03`、`CAP-COACH-04`、`CAP-CONTENT-02`

## 上游来源
- `docs/product/stages/p0-2-training-memory.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/definition.md`
- P02-PG-001 GoalAchievementPolicy
- P02-PG-002 SupportedGoalMatrix
- P02-PG-004 CommercialEntitlementAndCostPolicy
- P02-PG-005 DataGovernancePolicy

## Stage Scope Coverage
| Stage Scope ID | Requirement ID | Coverage status |
| --- | --- | --- |
| P02-SI-007 | P02-DIAG-FR-001, P02-DIAG-FR-002 | Covered |
| P02-SI-008 | P02-DIAG-FR-003, P02-DIAG-FR-004, P02-DIAG-FR-005 | Covered |
| P02-SI-003 | P02-DIAG-FR-006 | Covered for mastery initialization only |
| P02 policy gates | P02-DIAG-FR-007 | Covered |

## 用户目标
学习者能够输入短期英语口语目标，系统判断目标是否可支持，完成可信初始口语诊断，并产出后续 backplan、memory policy 和 progress forecast 可依赖的目标事实源。

## 用户路径
1. 用户选择目标类型，例如 IELTS speaking、TOEFL speaking、商务会议、面试表达或产品支持的其他口语目标。
2. 用户输入目标分数或能力、截止日期、每日可投入时间和强度偏好。
3. 系统用 SupportedGoalMatrix 判定目标为 supported、partial 或 unsupported。
4. 系统执行初始口语诊断，收集最低样本量的回答、转写、rubric score、弱项和置信度。
5. 系统给出产品内目标差距和低置信度/unsupported 降级说明，不声明官方考试认证分数。
6. 系统持久化 GoalProfile 和 DiagnosticAssessment，作为后续 P0.2 increment 的唯一可信输入。

## Functional Requirements

### P02-DIAG-FR-001 GoalProfile 事实源
- 系统必须保存目标类型、目标分数或能力、截止日期、每日可投入时间、强度偏好和目标状态。
- GoalProfile 必须归属 authenticated user，且后续 planner、forecast 和 checkpoint 必须引用同一事实源。
- 修改目标必须生成新版本或 revision，不得静默覆盖旧诊断与计划含义。

### P02-DIAG-FR-002 SupportedGoalMatrix
- 系统必须维护目标支持矩阵，把目标判定为 `supported`、`partial` 或 `unsupported`。
- 目标支持判断必须检查目标类型、目标分数/能力、rubric、题型/场景、内容资产和可用评分信号。
- `partial` 必须展示限制说明；`unsupported` 不得生成完整训练计划、ETA 或达标预测。

### P02-DIAG-FR-003 初始口语诊断
- 系统必须为 supported/partial 目标执行初始口语测评。
- 诊断必须采集最低样本量的口语回答，并输出 task performance、fluency、pronunciation、grammar/vocabulary 和 scenario fit 中适用维度。
- ASR/评分/LLM 不可用时，诊断必须进入可恢复或低置信度状态，不得伪造高置信度结果。

### P02-DIAG-FR-004 Rubric 校准与置信度
- 系统必须把诊断评分映射到产品内 rubric，不得声称等价官方 IELTS/TOEFL 分数认证。
- 诊断必须输出 confidence band，并说明影响置信度的原因，例如样本不足、音频质量差、provider unavailable 或目标内容不足。
- 低置信度诊断只能生成保守计划输入或触发复测，不得驱动高精度 ETA。

### P02-DIAG-FR-005 弱项分解
- 系统必须把诊断结果分解为弱项标签、证据来源、严重度、推荐训练方向和可复测指标。
- 弱项标签必须可被 backplan 和 memory policy 消费，不能只作为展示文案。
- 弱项分解必须保留 provider/LLM candidate-only 边界，最终弱项事实由应用规则接受。

### P02-DIAG-FR-006 L0-L5 mastery 初始化
- 系统必须根据诊断证据初始化目标表达或能力簇的 L0-L5 初始状态。
- 初始 mastery 只能作为 starting state，后续晋级必须由训练证据和 memory policy 决定。
- LLM 不得直接写入最终 mastery level。

### P02-DIAG-FR-007 Policy gate、商业与数据治理
- 系统必须覆盖 P02-PG-001、P02-PG-002、P02-PG-004 和 P02-PG-005。
- 诊断深度和 AI 用量必须受 entitlement、quota、paid AI gate 和低成本 fallback 管理。
- 目标、录音、转写、诊断、弱项和置信度必须具备 consent、retention、deletion/export、audit trail 和敏感数据最小化规则。
- 后续实现必须提供自动化测试覆盖率不低于 80%，并通过 goal intake、diagnostic submit 和 diagnostic result retrieval 的性能预算测试。

## 非目标
- 不承诺官方 IELTS/TOEFL 认证分数。
- 不生成完整 backplan、daily planner、autopilot execution 或 checkpoint loop。
- 不新增完整 A1-C2 内容体系或任意公开场景。
- 不绕过 P0 commercial release、paid AI voice 或真实 provider 外部门禁。
