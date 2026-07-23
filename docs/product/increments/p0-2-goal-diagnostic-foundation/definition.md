# Increment Definition：P0.2 目标画像与诊断基础

## 状态
Planned - PM stage replanning artifact only。该增量用于承接 GoalProfile 和 DiagnosticAssessment；尚未生成 requirements/spec/AC/TC，也未进入实现。

## Increment ID
`p0-2-goal-diagnostic-foundation`

## Active Stage
`docs/product/stages/p0-2-training-memory.md`

## Product Classification
- Request type: product direction / stage replanning request
- Product object mode: `feature-increment`
- Source mode: PM stage plan

## Primary Capability
- Capability ID：`CAP-INTENT`
- Sub-capability ID：`CAP-INTENT-01`

## Affected Capabilities
- Capability IDs：`CAP-LEVEL`、`CAP-PLAN`、`CAP-MEMORY`、`CAP-COACH`、`CAP-CONTENT`
- Sub-capability IDs：`CAP-INTENT-04`、`CAP-INTENT-06`、`CAP-LEVEL-02`、`CAP-LEVEL-03`、`CAP-LEVEL-04`、`CAP-LEVEL-05`、`CAP-PLAN-01`、`CAP-MEMORY-02`、`CAP-MEMORY-03`、`CAP-COACH-03`、`CAP-COACH-04`、`CAP-CONTENT-02`

## Scope
- GoalProfile：目标类型、目标分数或能力、截止日期、每日可投入时间、强度偏好。
- DiagnosticAssessment：初始口语测评、目标 rubric、弱项分解、置信度。
- 目标和诊断必须生成后续 backplan、daily planner、progress forecast 的可信输入。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| P02-SI-007 | GoalProfile source of truth and user goal intake. |
| P02-SI-008 | DiagnosticAssessment, rubric calibration, weakness decomposition and confidence. |
| P02-SI-003 | Provides diagnostic evidence for L0-L5 mastery initialization; final mastery rules are completed in the memory-policy increment. |

## Excluded Stage Scope Items
- P02-SI-001, P02-SI-002, P02-SI-004, P02-SI-005, P02-SI-006, P02-SI-009, P02-SI-010, P02-SI-011, P02-SI-012, P02-SI-013 are routed to later P0.2 increments.

## Non-goals
- 不承诺真实 IELTS/TOEFL 官方评分认证。
- 不新增完整 A1-C2 内容体系。
- 不实现完整 daily planner、autopilot execution 或 long-term schedule。

## Required Downstream Artifacts
- requirements/spec/acceptance/test_cases/traceability for this increment.
- Domain model for GoalProfile, DiagnosticAssessment, RubricScore and ConfidenceBand.
- API/OpenAPI for goal intake and diagnostic result.
- AI/runtime schema for diagnostic feedback candidate-only behavior.
- UX screen spec for goal setup and diagnostic flow.
- P02-PG-001 GoalAchievementPolicy coverage: product-internal achievement definition, supported target score/ability range, rubric calibration, minimum diagnostic sample, confidence band, low-confidence downgrade, reassessment trigger and prohibited official-score-equivalence claims.
- P02-PG-002 SupportedGoalMatrix coverage: supported/partial/unsupported goal types, required rubric/content/scenario assets for each goal, unsupported-goal fallback copy and target narrowing behavior.
- P02-PG-004 CommercialEntitlementAndCostPolicy coverage: free/paid diagnostic depth, AI usage budget for assessment, downgrade behavior when quota or paid AI gate is unavailable, and membership value display limits.
- P02-PG-005 DataGovernancePolicy coverage: consent for goal/diagnostic capture, oral sample retention, deletion/export, sensitive target data minimization, diagnostic audit trail and explanation rules.
