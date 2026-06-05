# Increment Definition：P0.2 Followup-C 周期复测、预测与多产品面加固

## 状态
S001 forecast hardening and S002 checkpoint task library locally implemented and tested / implementation still gated for S003-S007。该增量已建立正式 definition、requirements、spec、acceptance、test_cases 和 FR/Spec/AC/TC traceability，并把 S000-S007 implementation slice routing 写入文档链。S000 文档链、实现前 AC-to-TC mapping、验证命令和独立审核已完成；S001 ProgressForecast gap/ETA/confidence/risk/claim guard hardening 已有本地 domain/API/AI fallback 合同、后端代码和 TC-P02-FUC-001..003 测试证据；S002 Checkpoint cadence/task library 已有本地 domain/API/OpenAPI/AI/UX 合同、后端代码和 TC-P02-FUC-004..006 测试证据；S003-S007 checkpoint-to-plan、projection、surface、downgrade、performance、coverage 和 release evidence 仍未进入代码实现。Followup-C is not release-ready；Product Base merge is not approved。

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
- Followup-B boundary: `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`
- Local implementation review: progress evidence only appears on Home learn tab; Queue/Wiki propagation remains open.

## Problem Statement
The current local P0.2 slice can produce deterministic forecast and checkpoint records, but it does not yet provide robust checkpoint cadence/task library, explainable forecast model, backend-owned surface projection, or Queue/Wiki product-surface propagation. Followup-C closes those gaps without reimplementing Followup-A intake/diagnostic, Followup-B control/planner/memory/mastery, or Followup-D release/commercial gates.

## Scope
- ProgressForecast hardening with gap, ETA range, confidence, risk reason and next checkpoint behavior.
- OutcomeCheckpoint cadence and goal-type task library for supported targets.
- Checkpoint result handling that updates evidence, forecast and plan stale/replan signals.
- Backend-owned goal progress projection for Home, expression queue and personal Wiki surfaces.
- Home, expression queue and personal Wiki all consume backend/autopilot facts without recomputing final goal state locally. S005 may route each surface as a smaller sub-slice, but full S005 completion requires all three surfaces.
- Surface downgrade/removal behavior when data is deleted, unavailable, unsupported, partial, stale, control-blocked or low-confidence.
- Widget/API/integration/performance tests, dedicated traceability gate and >=80% changed-code coverage gates.

## Work Packages
| WP ID | Work package | Primary outcome |
| --- | --- | --- |
| P02-FUC-WP-000 | Followup-C document chain setup | Formal definition, requirements, spec, acceptance, test_cases and traceability exist before implementation work. |
| P02-FUC-WP-001 | ProgressForecast model hardening | Forecast exposes explainable gap, ETA range, confidence and risk without false claims. |
| P02-FUC-WP-002 | Checkpoint cadence and task library | Weekly/biweekly checkpoint tasks match supported goal types and content coverage. |
| P02-FUC-WP-003 | Checkpoint-to-plan update | Checkpoint results update forecast and emit stale/replan signals. |
| P02-FUC-WP-004 | Backend goal-progress projection | Surfaces read a server-owned projection instead of recomputing goal state. |
| P02-FUC-WP-005 | Home/Queue/Wiki surface propagation | Home, expression queue and personal Wiki all show backend-owned next action, gap, risk or checkpoint conclusion without local final-state recomputation. |
| P02-FUC-WP-006 | Surface deletion/unavailable downgrade | Sensitive progress display is removed or downgraded when data is deleted/unavailable. |
| P02-FUC-WP-007 | Followup-C automated tests and quality gates | Widget/API/integration tests, p95 budgets and >=80% coverage gates are executable. |
| P02-FUC-WP-008 | Followup-C independent review | Traceability, implementation evidence, residual risk and quality report are independently reviewed. |

## Implementation Slice Routing
| Slice ID | Work package | Requirement | Spec | Acceptance | Test cases | Primary outcome | Current state |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUC-S000 | P02-FUC-WP-000 | P02-FUC-FR-000 | P02-FUC-SPEC-000 | AC-P02-FUC-000 | TC-P02-FUC-000 | Followup-C docs and S000-S007 traceability are ready for implementation routing | Validated / no code |
| P02-FUC-S001 | P02-FUC-WP-001 | P02-FUC-FR-001 | P02-FUC-SPEC-001 | AC-P02-FUC-001 | TC-P02-FUC-001..003 | Forecast gap/ETA/confidence/risk/claim guard hardening | Implemented locally / TC-P02-FUC-001..003 passed |
| P02-FUC-S002 | P02-FUC-WP-002 | P02-FUC-FR-002 | P02-FUC-SPEC-002 | AC-P02-FUC-002 | TC-P02-FUC-004..006 | Checkpoint cadence and goal-type task library | Implemented locally / TC-P02-FUC-004..006 passed |
| P02-FUC-S003 | P02-FUC-WP-003 | P02-FUC-FR-003 | P02-FUC-SPEC-003 | AC-P02-FUC-003 | TC-P02-FUC-007..009 | Checkpoint result updates forecast and plan stale/replan signal | Planned / not started |
| P02-FUC-S004 | P02-FUC-WP-004 | P02-FUC-FR-004 | P02-FUC-SPEC-004 | AC-P02-FUC-004 | TC-P02-FUC-010..012 | Backend-owned goal-progress projection | Planned / not started |
| P02-FUC-S005 | P02-FUC-WP-005 | P02-FUC-FR-005 | P02-FUC-SPEC-005 | AC-P02-FUC-005 | TC-P02-FUC-013..016 | Home/Queue/Wiki surface propagation | Planned / not started |
| P02-FUC-S006 | P02-FUC-WP-006 | P02-FUC-FR-006 | P02-FUC-SPEC-006 | AC-P02-FUC-006 | TC-P02-FUC-017..019 | Surface deletion/unavailable downgrade | Planned / not started |
| P02-FUC-S007 | P02-FUC-WP-007, P02-FUC-WP-008 | P02-FUC-FR-007 | P02-FUC-SPEC-007 | AC-P02-FUC-007 | TC-P02-FUC-020..022 | Performance, coverage, traceability script and independent review | Planned / not started |

S005 may be routed as S005-A Home, S005-B Expression Queue and S005-C Personal Wiki. A one- or two-surface route may close only as a partial milestone; full S005 completion and Followup-C local closure require Home, Queue and Wiki evidence together.

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| P02-SI-006 | Goal progress and training evidence enter Home, Queue and Wiki through backend-owned projection. |
| P02-SI-010 | Autopilot next action appears as surface-level start/continue/review/checkpoint guidance, while Followup-B remains the owner of control semantics. |
| P02-SI-012 | ProgressForecast becomes explainable, confidence-aware and claim-guarded. |
| P02-SI-013 | OutcomeCheckpoint cadence and result handling update forecast and plan. |

## Applicable Policy Gates
| Policy Gate ID | Coverage requirement |
| --- | --- |
| P02-PG-001 | Forecast, ETA, risk and goal-complete copy must be confidence-aware and checkpoint-backed. |
| P02-PG-002 | Checkpoint formats and surface projections must match supported goal coverage. |
| P02-PG-003 | Forecast/checkpoint/surface updates must respect autopilot control and recovery state. |
| P02-PG-004 | Checkpoint depth and forecast/checkpoint AI explanation must respect entitlement, quota and cost fallback. |
| P02-PG-005 | Forecast/checkpoint/surface facts must support deletion/export, retention, audit and minimization. |

## Excluded Stage Scope Items
- P02-SI-007 and P02-SI-008 are upstream inputs from Followup-A.
- P02-SI-001, P02-SI-002, P02-SI-003, P02-SI-004, P02-SI-005, P02-SI-009 and P02-SI-011 are routed to Followup-B.
- Release-wide feature flag, kill switch, cost telemetry and Product Base merge gates are routed to Followup-D.

## Required Downstream Artifacts
- Completed for S000: `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and updated `traceability.md` for this follow-up before code routing.
- Required for S001-S007 before/within routed implementation: Domain updates for forecast model, checkpoint task/result and goal-progress projection if existing objects are insufficient.
- Required for S001-S007 before/within routed implementation: API/OpenAPI updates for projection, checkpoint cadence/task library and surface reads if existing summary is insufficient.
- Required for S001-S007 before/within routed implementation: AI runtime schema updates for checkpoint feedback and forecast explanation candidate-only behavior.
- Required for S001-S007 before/within routed implementation: UX screen spec updates for forecast, checkpoint and Queue/Wiki/Home progress surfaces.
- Required before implementation completion: Test case evidence mapping every Followup-C AC to stable TC IDs, code evidence, test evidence, performance evidence, coverage evidence and quality review.

## Non-goals
- Does not implement editable GoalProfile form or diagnostic capture.
- Does not implement pause/resume/control scheduler hardening, missed-day recovery, item-level memory or L0-L5 transition.
- Does not close release-wide commercial, paid AI external evidence, store or Product Base merge approval.
- Does not claim official score certification, official-score equivalence or guaranteed outcome.

## Completion Gate
Followup-C cannot be marked complete unless every slice has FR/Spec/AC/TC/Traceability coverage, contract evidence, code evidence, test evidence, >=80% changed-code coverage where implementation occurs, performance evidence, and independent review in `docs/reports/quality_report.md`.

S001 completion only means local forecast hardening evidence for TC-P02-FUC-001..003. S002 completion only means local checkpoint cadence/task-library evidence for TC-P02-FUC-004..006. These do not approve S003-S007 implementation, Followup-C completion, release readiness or Product Base merge.
