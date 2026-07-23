# Increment Definition：P0.2 Followup-A 目标录入与诊断加固

## 状态
Implemented locally for FR-001..009 / release-gated。Followup-A 本地 Flutter 实现和测试证据已覆盖 editable intake、diagnostic hardening 和 no-goal Explore Mode；该状态不代表 Followup-B/C/D 或完整 P0.2 release approval。

## Increment ID
`p0-2-followup-a-goal-intake-diagnostic-hardening`

## Active Stage
`docs/product/stages/p0-2-training-memory.md`

## Product Classification
- Request type: P0.2 implementation hardening / scope-completion follow-up
- Product object mode: `feature-increment`
- Source mode: local implementation independent review follow-up

## Primary Capability
- Capability ID：`CAP-INTENT`
- Sub-capability ID：`CAP-INTENT-01`

## Affected Capabilities
- Capability IDs：`CAP-LEVEL`、`CAP-PLAN`、`CAP-MEMORY`、`CAP-COACH`、`CAP-CONTENT`、`CAP-ACC`
- Sub-capability IDs：`CAP-INTENT-04`、`CAP-INTENT-06`、`CAP-LEVEL-02`、`CAP-LEVEL-04`、`CAP-LEVEL-05`、`CAP-PLAN-06`、`CAP-PLAN-07`、`CAP-MEMORY-02`、`CAP-MEMORY-03`、`CAP-COACH-03`、`CAP-COACH-04`、`CAP-CONTENT-01`、`CAP-CONTENT-02`、`CAP-ACC-03`

## Upstream Decision Source
- P0.2 stage scope: `docs/product/stages/p0-2-training-memory.md`
- Existing diagnostic increment: `docs/product/increments/p0-2-goal-diagnostic-foundation/`
- Local implementation review: `docs/reports/quality_report.md#2026-06-04-p02-goal-autopilot-local-implementation-independent-review`
- Follow-up planning decision: full editable GoalProfile UI and diagnostic hardening are required before P0.2 can be considered product-complete.

## Problem Statement
The current local P0.2 slice supports a backend GoalProfile contract but the Flutter user path starts a fixed default IELTS goal. This creates a product gap: learners cannot express their real goal, time budget, deadline, intensity preference, diagnostic sample evidence, or partial/unsupported limitations through a complete user-facing intake flow.
After Followup-A implementation review, an additional product gap is identified: users who are only browsing or trying the app without a learning goal need a non-goal Explore Mode. The app must not silently create a GoalProfile, DiagnosticAssessment, ETA, forecast or autopilot schedule for those users.

## Scope
- Editable GoalProfile intake for goal type, target score/ability, deadline, daily available time and intensity preference.
- No-goal Explore Mode that lets users browse or try practice without creating GoalProfile, DiagnosticAssessment, forecast, plan or memory/autopilot schedule.
- SupportedGoalMatrix limitation states rendered before full plan generation.
- Diagnostic sample collection and validation, including text fallback and audio reference boundary where available.
- Goal revision and stale downstream-plan visibility after target edits.
- Low-confidence, partial and unsupported goal downgrade paths with claim guard copy.
- Automated widget/API/backend tests, performance and changed-code coverage gates for this follow-up.

## Work Packages
| WP ID | Work package | Primary outcome |
| --- | --- | --- |
| P02-FUA-WP-000 | Followup-A document chain setup | Formal definition and WP traceability scaffold exist before requirements/spec work. |
| P02-FUA-WP-001 | Editable GoalProfile form | Flutter exposes all required GoalProfile fields instead of creating a default goal. |
| P02-FUA-WP-002 | SupportedGoalMatrix pre-plan boundary | supported/partial/unsupported and limitation copy are visible before plan generation. |
| P02-FUA-WP-003 | Diagnostic sample capture | User-facing diagnostic sample collection supports minimum sample count and recoverable validation. |
| P02-FUA-WP-004 | Diagnostic transport boundary | Text fallback and audio_ref inputs follow candidate-only and data-governance rules. |
| P02-FUA-WP-005 | Goal revision and stale visibility | Goal edits create revision/stale-plan behavior that users and downstream planner can observe. |
| P02-FUA-WP-006 | Low-confidence and unsupported downgrade UX | Low-confidence, partial and unsupported states block false ETA/achievement claims. |
| P02-FUA-WP-007 | Followup-A automated tests and quality gates | Widget/API/backend tests, performance budgets and >=80% coverage gates are executable. |
| P02-FUA-WP-008 | Followup-A independent review | Traceability, implementation evidence, residual risk and quality report are independently reviewed. |
| P02-FUA-WP-009 | No-goal Explore Mode | Users can browse or try ordinary practice without setting a goal or polluting goal-autopilot facts. |

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| P02-SI-007 | Full user-facing GoalProfile intake, revision visibility and explicit no-goal browsing boundary. |
| P02-SI-008 | DiagnosticAssessment sample collection, confidence downgrade and rubric/weakness input quality. |
| P02-SI-003 | Diagnostic evidence remains the source for initial L0-L5 state; promotion rules stay in planner/memory follow-up. |

## Applicable Policy Gates
| Policy Gate ID | Coverage requirement |
| --- | --- |
| P02-PG-001 | Achievement claim guard, product-internal rubric, confidence band and low-confidence downgrade. |
| P02-PG-002 | Supported/partial/unsupported decision before plan, ETA or checkpoint promise. |
| P02-PG-003 | Goal revision and stale-plan visibility must not auto-execute or reschedule downstream training without the Followup-B control/replay gate. |
| P02-PG-004 | Diagnostic depth, AI usage and paid/free fallback must be server-owned. |
| P02-PG-005 | Consent, retention, deletion/export, audit and sensitive-data minimization for goal and diagnostic data. |

## Excluded Stage Scope Items
- P02-SI-001, P02-SI-002, P02-SI-004, P02-SI-005, P02-SI-009 and P02-SI-011 are routed to Followup-B.
- P02-SI-006, P02-SI-010, P02-SI-012 and P02-SI-013 are routed to Followup-B/C/D as noted in their definitions.

## Required Downstream Artifacts
- `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and updated `traceability.md` for this follow-up before code routing.
- Domain updates for any new GoalProfile revision, diagnostic sample, consent or diagnostic state objects.
- API/OpenAPI updates for any new or changed goal intake/diagnostic submission fields.
- AI runtime schema updates if diagnostic candidate output or claim guard behavior changes.
- UX screen spec updates for editable intake, diagnostic capture, partial/unsupported and low-confidence states.
- Test case library mapping every Followup-A AC to stable TC IDs before implementation.

## Non-goals
- Does not implement planner/memory algorithm hardening.
- Does not implement notification scheduling or pause/resume control.
- Does not implement Queue/Wiki surface propagation.
- Does not close P0 commercial release, paid AI external evidence, store or Product Base merge approval.

## Completion Gate
Followup-A cannot be marked complete unless every WP has FR/Spec/AC/TC/Traceability coverage, contract evidence, code evidence, test evidence, >=80% changed-code coverage where implementation occurs, performance evidence, and independent review in `docs/reports/quality_report.md`.
