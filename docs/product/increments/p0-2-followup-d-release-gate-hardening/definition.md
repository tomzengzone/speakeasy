# Increment Definition：P0.2 Followup-D 发布门禁与商业软件加固

## 状态
Planned - formal follow-up scaffold only。该增量只建立正式 definition 和 work-package traceability scaffold；尚未生成 requirements/spec/acceptance/test_cases，也未进入代码实现。

## Increment ID
`p0-2-followup-d-release-gate-hardening`

## Active Stage
`docs/product/stages/p0-2-training-memory.md`

## Product Classification
- Request type: P0.2 release-gate hardening / product-completion follow-up
- Product object mode: `feature-increment`
- Source mode: local implementation independent review follow-up

## Primary Feature
`goal-driven-learning-autopilot`

## Affected Features
- `commercial-subscription`
- `ai-provider-operations`
- `profile-membership`
- `learning-memory-review`
- `scoring-feedback`

## Upstream Decision Source
- P0.2 stage scope: `docs/product/stages/p0-2-training-memory.md`
- Existing P0.2 traceability and quality reports.
- P0 commercial and paid AI gates: `commercial-subscription-readiness` and `commercial-ai-provider-hardening`.
- Local implementation review: paid AI/commercial gates and Product Base approval remain open.

## Problem Statement
Even after Followup-A/B/C close user-facing and product-surface gaps, P0.2 cannot be treated as commercial software complete without rollout controls, entitlement/cost gates, data export/retention evidence, telemetry, contract drift checks and Product Base/release decision evidence.

## Scope
- P0.2 feature flag and kill switch for goal-autopilot runtime exposure.
- Entitlement/free-paid depth rules for diagnostic, planner, checkpoint and autopilot explanation depth.
- Usage reservation and cost telemetry integration for AI-backed P0.2 operations.
- Quota exhausted downgrade behavior and user-visible limits.
- Consent, export and retention UI/backend execution evidence for P0.2 goal, diagnostic, forecast and checkpoint data.
- Telemetry health, error and funnel metrics for goal intake, plan generation, action completion, checkpoint and surface propagation.
- OpenAPI/generated client drift gate, traceability drift gate and release checklist integration.
- Final Product Base merge and release approval review path.

## Work Packages
| WP ID | Work package | Primary outcome |
| --- | --- | --- |
| P02-FUD-WP-000 | Followup-D document chain setup | Formal definition and WP traceability scaffold exist before requirements/spec work. |
| P02-FUD-WP-001 | P0.2 feature flag and kill switch | Goal autopilot can be disabled or rolled back without code removal. |
| P02-FUD-WP-002 | Entitlement/free-paid depth gate | Diagnostic, planner, checkpoint and explanation depth are server-owned by entitlement policy. |
| P02-FUD-WP-003 | Usage reservation and cost telemetry | AI-backed P0.2 paths reserve/commit/release usage and record cost metrics. |
| P02-FUD-WP-004 | Quota exhausted downgrade | Quota failure downgrades or blocks safely with clear user-facing limits. |
| P02-FUD-WP-005 | Consent/export/retention execution | P0.2 sensitive facts support consent, export, deletion and retention evidence. |
| P02-FUD-WP-006 | Telemetry health/error/funnel metrics | Operational metrics prove runtime health and rollout safety. |
| P02-FUD-WP-007 | Contract and traceability drift gates | OpenAPI/generated client/traceability gates prevent stale release evidence. |
| P02-FUD-WP-008 | Product Base and release checklist gate | Product Base merge and release checklist decisions are explicit and auditable. |
| P02-FUD-WP-009 | Followup-D independent release review | Traceability, implementation evidence, residual risk and quality report are independently reviewed. |

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| P02-SI-001..013 | Release hardening applies across every required P0.2 scope item after A/B/C functional closure. |

## Applicable Policy Gates
| Policy Gate ID | Coverage requirement |
| --- | --- |
| P02-PG-001 | Claims, ETA, goal completion and release copy remain guarded through final launch evidence. |
| P02-PG-002 | Unsupported/partial goal behavior remains gated at release and telemetry layers. |
| P02-PG-003 | Autopilot controls, recovery, notifications and kill switch are release-safe. |
| P02-PG-004 | Entitlement, quota, usage reservation, cost telemetry and downgrade behavior are release-blocking gates. |
| P02-PG-005 | Consent, export, retention, deletion, audit and minimization are release-blocking gates. |

## Excluded Stage Scope Items
- None at release-gate level. Followup-D does not replace A/B/C functional implementation; it verifies that all P02-SI-001..013 evidence is safe to expose, merge or release.

## Required Downstream Artifacts
- `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and updated `traceability.md` for this follow-up before code routing.
- Domain/API/UX/AI/Ops contract updates for flags, entitlement, usage/cost, telemetry, export/retention and release checklist where applicable.
- Release checklist and rollback plan impact review.
- Test case library mapping every Followup-D AC to stable TC IDs before implementation.
- Final quality report entry distinguishing local deterministic completion, Product Base merge decision, commercial release decision and paid AI external evidence status.

## Non-goals
- Does not implement the editable GoalProfile UI, control scheduler or Queue/Wiki surfaces directly; those belong to Followup-A/B/C.
- Does not bypass P0 commercial external/native/store/release gates.
- Does not approve official exam score certification or guaranteed outcome claims.

## Completion Gate
Followup-D cannot be marked complete unless every WP has FR/Spec/AC/TC/Traceability coverage, contract evidence, code evidence where needed, test evidence, >=80% changed-code coverage where implementation occurs, release checklist evidence, and independent review in `docs/reports/quality_report.md`.

