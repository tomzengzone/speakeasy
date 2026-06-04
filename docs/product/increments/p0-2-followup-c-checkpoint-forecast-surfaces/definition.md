# Increment Definition：P0.2 Followup-C 周期复测、预测与多产品面加固

## 状态
Planned - formal follow-up scaffold only。该增量只建立正式 definition 和 work-package traceability scaffold；尚未生成 requirements/spec/acceptance/test_cases，也未进入代码实现。

## Increment ID
`p0-2-followup-c-checkpoint-forecast-surfaces`

## Active Stage
`docs/product/stages/p0-2-training-memory.md`

## Product Classification
- Request type: P0.2 implementation hardening / scope-completion follow-up
- Product object mode: `feature-increment`
- Source mode: local implementation independent review follow-up

## Primary Feature
`goal-driven-learning-autopilot`

## Affected Features
- `learning-memory-review`
- `expression-practice-queue`
- `profile-membership`
- `scoring-feedback`
- `official-scenario-library`

## Upstream Decision Source
- P0.2 stage scope: `docs/product/stages/p0-2-training-memory.md`
- Existing autopilot/progress/checkpoint increment: `docs/product/increments/p0-2-autopilot-progress-checkpoint/`
- Local implementation review: progress evidence only appears on Home learn tab; Queue/Wiki propagation remains open.

## Problem Statement
The current local P0.2 slice can produce deterministic forecast and checkpoint records, but it does not yet provide robust checkpoint cadence/task library, explainable forecast model, backend-owned surface projection, or Queue/Wiki product-surface propagation.

## Scope
- ProgressForecast hardening with gap, ETA range, confidence, risk reason and next checkpoint behavior.
- OutcomeCheckpoint cadence and goal-type task library for supported targets.
- Checkpoint result handling that updates evidence, forecast and plan stale/replan signals.
- Backend-owned goal progress projection for Home, expression queue and personal Wiki surfaces.
- At least two product surfaces consuming backend/autopilot facts without recomputing final goal state locally.
- Surface downgrade/removal behavior when data is deleted, unavailable, unsupported or low-confidence.
- Widget/API/integration/performance tests and >=80% changed-code coverage gates.

## Work Packages
| WP ID | Work package | Primary outcome |
| --- | --- | --- |
| P02-FUC-WP-000 | Followup-C document chain setup | Formal definition and WP traceability scaffold exist before requirements/spec work. |
| P02-FUC-WP-001 | ProgressForecast model hardening | Forecast exposes explainable gap, ETA range, confidence and risk without false claims. |
| P02-FUC-WP-002 | Checkpoint cadence and task library | Weekly/biweekly checkpoint tasks match supported goal types and content coverage. |
| P02-FUC-WP-003 | Checkpoint-to-plan update | Checkpoint results update forecast and emit stale/replan signals. |
| P02-FUC-WP-004 | Backend goal-progress projection | Surfaces read a server-owned projection instead of recomputing goal state. |
| P02-FUC-WP-005 | Home/Queue/Wiki surface propagation | At least two product surfaces show next action, gap, risk or checkpoint conclusion. |
| P02-FUC-WP-006 | Surface deletion/unavailable downgrade | Sensitive progress display is removed or downgraded when data is deleted/unavailable. |
| P02-FUC-WP-007 | Followup-C automated tests and quality gates | Widget/API/integration tests, p95 budgets and >=80% coverage gates are executable. |
| P02-FUC-WP-008 | Followup-C independent review | Traceability, implementation evidence, residual risk and quality report are independently reviewed. |

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| P02-SI-006 | Goal progress and training evidence enter Home, Queue and Wiki through backend-owned projection. |
| P02-SI-010 | Autopilot next action appears as surface-level start/continue/review/checkpoint guidance. |
| P02-SI-012 | ProgressForecast becomes explainable, confidence-aware and claim-guarded. |
| P02-SI-013 | OutcomeCheckpoint cadence and result handling update forecast and plan. |

## Applicable Policy Gates
| Policy Gate ID | Coverage requirement |
| --- | --- |
| P02-PG-001 | Forecast, ETA, risk and goal-complete copy must be confidence-aware and checkpoint-backed. |
| P02-PG-002 | Checkpoint formats and surface projections must match supported goal coverage. |
| P02-PG-003 | Forecast/checkpoint/surface updates must respect autopilot control and recovery state. |
| P02-PG-004 | Checkpoint depth and AI explanation must respect entitlement, quota and cost fallback. |
| P02-PG-005 | Forecast/checkpoint/surface facts must support deletion/export, retention, audit and minimization. |

## Excluded Stage Scope Items
- P02-SI-007 and P02-SI-008 are upstream inputs from Followup-A.
- P02-SI-001, P02-SI-002, P02-SI-003, P02-SI-004, P02-SI-005, P02-SI-009 and P02-SI-011 are routed to Followup-B.
- Release-wide feature flag, kill switch, cost telemetry and Product Base merge gates are routed to Followup-D.

## Required Downstream Artifacts
- `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and updated `traceability.md` for this follow-up before code routing.
- Domain updates for forecast model, checkpoint task/result and goal-progress projection if new objects are needed.
- API/OpenAPI updates for projection, checkpoint cadence/task library and surface reads if existing summary is insufficient.
- AI runtime schema updates for checkpoint feedback and forecast explanation candidate-only behavior.
- UX screen spec updates for forecast, checkpoint and Queue/Wiki/Home progress surfaces.
- Test case library mapping every Followup-C AC to stable TC IDs before implementation.

## Non-goals
- Does not implement editable GoalProfile form or diagnostic capture.
- Does not implement pause/resume/control scheduler hardening.
- Does not close release-wide commercial, paid AI external evidence, store or Product Base merge approval.

## Completion Gate
Followup-C cannot be marked complete unless every WP has FR/Spec/AC/TC/Traceability coverage, contract evidence, code evidence, test evidence, >=80% changed-code coverage where implementation occurs, performance evidence, and independent review in `docs/reports/quality_report.md`.

