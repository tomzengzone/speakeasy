# Increment Definition：P0.2 自动带练、进度预测与周期复测

## 状态
Planned - PM stage replanning artifact only。该增量用于承接 AutopilotTraining、ProgressForecast 和 OutcomeCheckpoint；尚未生成 requirements/spec/AC/TC，也未进入实现。

## Increment ID
`p0-2-autopilot-progress-checkpoint`

## Active Stage
`docs/product/stages/p0-2-training-memory.md`

## Product Classification
- Request type: product direction / stage replanning request
- Product object mode: `feature-increment`
- Source mode: PM stage plan

## Primary Capability
- Capability ID：`CAP-TRAIN`
- Sub-capability ID：`CAP-TRAIN-02`

## Affected Capabilities
- Capability IDs：`CAP-PLAN`、`CAP-MEMORY`、`CAP-LEVEL`、`CAP-ENGAGE`、`CAP-COM`、`CAP-ACC`
- Sub-capability IDs：`CAP-TRAIN-01`、`CAP-TRAIN-03`、`CAP-TRAIN-05`、`CAP-TRAIN-06`、`CAP-PLAN-05`、`CAP-PLAN-06`、`CAP-PLAN-07`、`CAP-MEMORY-03`、`CAP-MEMORY-04`、`CAP-MEMORY-05`、`CAP-LEVEL-02`、`CAP-LEVEL-06`、`CAP-ENGAGE-01`、`CAP-ENGAGE-02`、`CAP-COM-01`、`CAP-COM-03`、`CAP-ACC-03`

## Scope
- AutopilotTraining：系统自动开练、自动切换训练/复习/复测，不依赖用户自律。
- ProgressForecast：当前距目标差距、预计达标日期、风险提醒、阶段复测。
- OutcomeCheckpoint：每周或每两周模拟考试/商务任务复测，更新计划。
- 目标进度和训练证据进入首页、表达队列、个人 Wiki 和必要的会员价值展示，但不创建商业权益事实源。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| P02-SI-006 | Evidence surfaces become goal-progress surfaces across home, queue and Wiki. |
| P02-SI-010 | AutopilotTraining execution loop and no-self-discipline interaction model. |
| P02-SI-012 | ProgressForecast with gap, ETA, risk and reassessment triggers. |
| P02-SI-013 | OutcomeCheckpoint weekly/biweekly reassessment and plan update. |

## Excluded Stage Scope Items
- P02-SI-007 and P02-SI-008 are upstream goal/diagnostic inputs.
- P02-SI-001 through P02-SI-005, P02-SI-009 and P02-SI-011 are upstream plan/memory-policy inputs.

## Non-goals
- 不承诺官方考试认证或保证分数。
- 不实现 P1/P2 场景包、A1-C2 内容体系或 CMS。
- 不绕过 P0 commercial entitlement、paid AI voice 或 release gates。

## Required Downstream Artifacts
- requirements/spec/acceptance/test_cases/traceability for this increment.
- UX screen spec for no-choice daily execution, progress forecast and checkpoint review.
- API/OpenAPI for progress forecast, checkpoint result and plan update.
- AI/runtime schema for checkpoint feedback and forecast explanation candidate-only behavior.
- QA tests for skip/defer recovery, checkpoint recalculation, risk forecast and no false goal-completion claims.
- P02-PG-001 GoalAchievementPolicy coverage: progress gap, ETA, risk and achievement copy must include confidence/uncertainty; goal-complete status requires checkpoint evidence and cannot claim official score certification.
- P02-PG-002 SupportedGoalMatrix coverage: checkpoint formats must match supported goal types; partial goals require explicit limitation copy and unsupported goals cannot show completion forecasts.
- P02-PG-003 AutopilotControlPolicy coverage: no-choice daily execution, pause/resume, quiet hours, fatigue guard, missed-day recovery, notification cadence, interruption recovery and user override behavior.
- P02-PG-004 CommercialEntitlementAndCostPolicy coverage: paid/free autopilot depth, AI voice/checkpoint cost budget, quota exhaustion fallback, membership value display boundaries, cost telemetry and no commercial entitlement source-of-truth creation.
- P02-PG-005 DataGovernancePolicy coverage: checkpoint audio/result retention, forecast explanation audit, user deletion/export behavior, sensitive progress data minimization and consent-aware notification behavior.
