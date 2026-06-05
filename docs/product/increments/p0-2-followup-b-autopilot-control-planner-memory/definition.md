# Increment Definition：P0.2 Followup-B 自动带练控制与计划记忆引擎加固

## 状态
Contract-ready / partially implemented through S002-B / completion gated。该增量已建立正式 definition、requirements、spec、acceptance、test_cases 和 traceability，并已完成 Domain、API/OpenAPI/generated client sync、AI runtime 和 UX 合同门禁的独立审核。当前 backend UserAutopilotControl read/update/pause/resume、Flutter control binding、S002-A notification eligibility policy 和 S002-B notification outbox lifecycle/replay 已有本地执行证据；missed-day recovery、item-level memory、L0-L5 transition、global replay/performance/coverage/final review 和 release evidence 仍未闭环。

## Increment ID
`p0-2-followup-b-autopilot-control-planner-memory`

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
- `expression-automation-training`
- `expression-practice-queue`
- `voice-scenario-practice`
- `ai-provider-operations`

## Upstream Decision Source
- P0.2 stage scope: `docs/product/stages/p0-2-training-memory.md`
- Existing plan/memory increment: `docs/product/increments/p0-2-goal-backplan-memory-policy/`
- Existing autopilot increment: `docs/product/increments/p0-2-autopilot-progress-checkpoint/`
- Local implementation review: pause/resume endpoint and production notification scheduling remain blockers.

## Problem Statement
The current local P0.2 slice can select and complete a next action, and can mark skip/defer recovery. It does not yet provide a durable UserAutopilotControl fact source, pause/resume/update-control API, notification scheduling semantics, item-level memory algorithm, or evidence-driven L0-L5 promotion/demotion rules.

## Scope
- Durable `UserAutopilotControl` state with pause/resume, quiet hours, intensity override, notification consent and missed-day policy.
- API/OpenAPI and UX contracts for pause/resume/update-control behavior.
- Production-safe notification scheduling or notification outbox semantics, including quiet hours and consent.
- Missed-day recovery that compresses, defers or replaces tasks without stacking impossible work.
- Item-level MemoryCurvePolicy with forgetting risk, retrieval success, overlearning cap and interleaving rules.
- Evidence-driven L0-L5 promotion/demotion rules.
- Planner replay fixtures, deterministic decision audit, p95 performance budgets and >=80% changed-code coverage gates.

## Work Packages
| WP ID | Work package | Primary outcome |
| --- | --- | --- |
| P02-FUB-WP-000 | Followup-B document chain setup | Formal definition and WP traceability scaffold exist before requirements/spec work. |
| P02-FUB-WP-001 | UserAutopilotControl source of truth | Control state is persisted and server-owned, not inferred from goal intake fields. |
| P02-FUB-WP-002 | Pause/resume/update-control API | Autopilot prompts and next actions honor explicit pause/resume/control updates. |
| P02-FUB-WP-003 | Quiet hours and notification semantics | Reminder eligibility obeys consent, quiet hours, permissions and entitlement gates. |
| P02-FUB-WP-004 | Notification scheduler/outbox integration | Notifications are scheduled or queued with audit, cancellation and replayable state. |
| P02-FUB-WP-005 | Missed-day recovery planner | Missed/skipped/deferred work triggers feasible recovery without task stacking. |
| P02-FUB-WP-006 | Item-level MemoryCurvePolicy | Review scheduling uses item-level memory risk, retrieval success, overlearning and interleaving. |
| P02-FUB-WP-007 | L0-L5 promotion/demotion | Mastery movement is evidence-driven and cannot be directly written by AI output. |
| P02-FUB-WP-008 | Planner replay/performance/coverage gates | Replay fixtures, p95 budgets and >=80% changed-code coverage are executable. |
| P02-FUB-WP-009 | Followup-B independent review | Traceability, implementation evidence, residual risk and quality report are independently reviewed. |

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| P02-SI-001 | Daily planner must honor control state, fatigue and feasible time budget. |
| P02-SI-002 | Cross-session pressure ladder must obey pause, fatigue and recovery constraints. |
| P02-SI-003 | Completes evidence-driven L0-L5 transition rules beyond diagnostic initialization. |
| P02-SI-004 | Long-term planner must persist deterministic state and replayable recalculation. |
| P02-SI-005 | Cross-day orchestration must recover missed/deferred work without stacking. |
| P02-SI-009 | Backplan output becomes resilient to control changes and recovery events. |
| P02-SI-010 | AutopilotTraining gains first-class user control and notification behavior. |
| P02-SI-011 | MemoryCurvePolicy becomes item-level and testable. |

## Applicable Policy Gates
| Policy Gate ID | Coverage requirement |
| --- | --- |
| P02-PG-001 | Achievement, pressure and mastery changes must be confidence-aware. |
| P02-PG-002 | Unsupported/partial goals cannot receive full planner/autopilot behavior. |
| P02-PG-003 | User control, pause/resume, quiet hours, missed-day recovery, fatigue guard and deterministic replay are mandatory. |
| P02-PG-004 | Plan depth, reminders and AI explanation must respect entitlement, quota and cost fallback. |
| P02-PG-005 | Planner/control/audit data must support deletion, retention, export and minimization. |

## Excluded Stage Scope Items
- P02-SI-007 and P02-SI-008 are upstream inputs from Followup-A.
- P02-SI-006, P02-SI-012 and P02-SI-013 are routed to Followup-C.
- Release-wide feature flag, kill switch, telemetry and Product Base merge gates are routed to Followup-D.

## Required Downstream Artifacts
- Completed for pre-implementation routing: `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and updated `traceability.md` for this follow-up.
- Completed for pre-implementation routing: Domain updates for UserAutopilotControl, notification schedule/outbox, planner audit, memory review item and mastery transition records.
- Completed for pre-implementation routing: API/OpenAPI updates for pause/resume/update-control, reminder eligibility, scheduler/outbox state, recovery/replan, item-policy decisions, mastery transitions and replay audits; generated Dart client drift has been synced.
- Completed for pre-implementation routing: AI runtime updates for candidate-only mastery transition explanation schema, forbidden persistent fields and deterministic fallback.
- Completed for pre-implementation routing: UX screen spec updates for paused, quiet-hours, notification-disabled, missed-day recovery, fatigue/intensity override and memory/mastery explanations.
- Still required during remaining implementation routing: QA replay fixtures for planner/memory/control decisions, executable tests for recovery、item-level memory、mastery transition、global replay/performance evidence, >=80% changed-code coverage evidence where new code changes, test report updates and quality report updates.
- Completed for the first routed control slice: backend control source/update/pause/resume implementation evidence and Flutter control binding evidence are recorded in `docs/reports/implementation_report.md` and reconciled into `docs/reports/test_report.md` / `docs/reports/quality_report.md`.
- Completed for S002-A: notification eligibility reason precedence, quiet-hours evaluation and Flutter blocked-reason/no-false-completion evidence are recorded in `docs/reports/implementation_report.md` and reconciled into `docs/reports/test_report.md` / `docs/reports/quality_report.md`.
- Completed for S002-B: notification outbox lifecycle/replay, stable dedupe key, cancel/reschedule, retry/failure recovery, redacted payload projection and deletion cleanup evidence are recorded in `docs/reports/implementation_report.md` and reconciled into `docs/reports/test_report.md` / `docs/reports/quality_report.md`.

## Non-goals
- Does not implement editable GoalProfile form or diagnostic sample capture.
- Does not implement Queue/Wiki surface propagation or checkpoint task library.
- Does not close release-wide commercial, paid AI external evidence, store or Product Base merge approval.

## Completion Gate
Followup-B cannot be marked complete unless every WP has FR/Spec/AC/TC/Traceability coverage, contract evidence, code evidence, test evidence, >=80% changed-code coverage where implementation occurs, performance/replay evidence, and independent review in `docs/reports/quality_report.md`.
