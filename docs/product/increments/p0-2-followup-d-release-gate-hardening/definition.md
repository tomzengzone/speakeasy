# Increment Definition：P0.2 Followup-D 发布门禁与商业软件加固

## 状态
S011 final Product Base/release review locally passed with blockers preserved - S000 documentation chain validated；S001 backend feature flag、kill switch、fail-closed mutation gate、read/projection downgrade and API contract evidence are implemented/tested locally；S002 Flutter entry/surface rollback、cached projection replacement and frontend source-of-truth guard are implemented/tested locally；S003 entitlement/free-paid depth policy、API contract 和 Flutter server-owned limitation display are implemented/tested locally；S004 usage reserve/commit/release、quota blocked、idempotent retry 和 idempotency conflict evidence are implemented/tested locally；S005 cost telemetry、deterministic no-provider evidence、policy rejection metric 和 AI forbidden-field guard are implemented/tested locally；S006 quota/entitlement/cost downgrade propagation、stable reason contract 和 Flutter stale full-depth cleanup are implemented/tested locally；S007 redacted export、retention rule coverage、account deletion cleanup 和 redacted audit proof are implemented/tested locally；S008 consent/privacy UX、notification consent withdrawn blocking、copy contract 和 stale privacy state cleanup are implemented/tested locally；S009 redacted telemetry health/error/funnel metrics、blocked reason coverage 和 non-blocking fallback audit are implemented/tested locally；S010 contract/traceability/release checklist drift gate is implemented/tested locally；S011 final Product Base/release review is implemented/tested locally with release and Product Base blockers preserved。S001-S011 只关闭对应本地 release-gate 子切片和最终审核执行；Followup-D 不具备 release approval 或 Product Base merge approval。

## Increment ID
`p0-2-followup-d-release-gate-hardening`

## Active Stage
`docs/product/stages/p0-2-training-memory.md`

## Product Classification
- Request type: P0.2 release-gate hardening / product-completion follow-up
- Product object mode: `feature-increment`
- Source mode: local implementation independent review follow-up

## Primary Capability
- Capability ID：`CAP-COM`
- Sub-capability ID：`CAP-COM-03`

## Affected Capabilities
- Capability IDs：`CAP-PLAN`、`CAP-TRAIN`、`CAP-LEVEL`、`CAP-INTENT`、`CAP-MEMORY`、`CAP-ACC`、`CAP-ENGAGE`
- Sub-capability IDs：`CAP-COM-01`、`CAP-COM-05`、`CAP-PLAN-06`、`CAP-PLAN-07`、`CAP-TRAIN-02`、`CAP-LEVEL-02`、`CAP-LEVEL-05`、`CAP-INTENT-06`、`CAP-MEMORY-01`、`CAP-MEMORY-04`、`CAP-ACC-03`、`CAP-ACC-04`、`CAP-ENGAGE-01`、`CAP-ENGAGE-02`

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

## Implementation Slice Routing
| Slice ID | Work package | Requirement | Spec | Acceptance | Test cases | Primary outcome | Current state |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUD-S000 | P02-FUD-WP-000 | P02-FUD-FR-000 | P02-FUD-SPEC-000 | AC-P02-FUD-000 | TC-P02-FUD-000 | Followup-D docs and S000-S011 traceability are ready for implementation routing | Validated / no code |
| P02-FUD-S001 | P02-FUD-WP-001 | P02-FUD-FR-001 | P02-FUD-SPEC-001 | AC-P02-FUD-001 | TC-P02-FUD-001..002 | Backend feature flag, kill switch and fail-closed mutation gate | Implemented/tested locally for backend/API runtime gate |
| P02-FUD-S002 | P02-FUD-WP-001 | P02-FUD-FR-002 | P02-FUD-SPEC-002 | AC-P02-FUD-002 | TC-P02-FUD-003..004 | Flutter entry and Home/Queue/Wiki/Panel rollback gate with no local fallback | Implemented/tested locally for Flutter rollback |
| P02-FUD-S003 | P02-FUD-WP-002 | P02-FUD-FR-003 | P02-FUD-SPEC-003 | AC-P02-FUD-003 | TC-P02-FUD-005..006 | Server-owned entitlement/free-paid depth policy | Implemented/tested locally for entitlement depth |
| P02-FUD-S004 | P02-FUD-WP-003 | P02-FUD-FR-004 | P02-FUD-SPEC-004 | AC-P02-FUD-004 | TC-P02-FUD-007..008 | Usage reservation, quota and idempotency for P0.2 costly paths | Implemented/tested locally for usage reservation and quota |
| P02-FUD-S005 | P02-FUD-WP-003 | P02-FUD-FR-005 | P02-FUD-SPEC-005 | AC-P02-FUD-005 | TC-P02-FUD-009..010 | Cost telemetry and AI candidate-only fallback guard | Implemented/tested locally for cost telemetry and AI fallback |
| P02-FUD-S006 | P02-FUD-WP-004 | P02-FUD-FR-006 | P02-FUD-SPEC-006 | AC-P02-FUD-006 | TC-P02-FUD-011..012 | Quota exhausted / entitlement / cost downgrade propagation | Implemented/tested locally for quota downgrade |
| P02-FUD-S007 | P02-FUD-WP-005 | P02-FUD-FR-007 | P02-FUD-SPEC-007 | AC-P02-FUD-007 | TC-P02-FUD-013..014 | Data export, retention and deletion backend evidence | Implemented/tested locally for data governance backend evidence |
| P02-FUD-S008 | P02-FUD-WP-005 | P02-FUD-FR-008 | P02-FUD-SPEC-008 | AC-P02-FUD-008 | TC-P02-FUD-015 | Consent and privacy UX alignment | Implemented/tested locally for consent/privacy UX |
| P02-FUD-S009 | P02-FUD-WP-006 | P02-FUD-FR-009 | P02-FUD-SPEC-009 | AC-P02-FUD-009 | TC-P02-FUD-016..017 | Telemetry health, error and funnel metrics | Implemented/tested locally for telemetry health/error/funnel metrics |
| P02-FUD-S010 | P02-FUD-WP-007 | P02-FUD-FR-010 | P02-FUD-SPEC-010 | AC-P02-FUD-010 | TC-P02-FUD-018..019 | Contract, traceability and release drift gates | Implemented/tested locally for contract/traceability/release drift gates |
| P02-FUD-S011 | P02-FUD-WP-008, P02-FUD-WP-009 | P02-FUD-FR-011 | P02-FUD-SPEC-011 | AC-P02-FUD-011 | TC-P02-FUD-020..021 | Product Base/release checklist evidence and independent review | Final review passed locally with release/Product Base blockers preserved |

S001-S011 may close independently only as backend, Flutter, entitlement, usage, cost/AI guard, quota-downgrade, data-governance, consent/privacy UX, telemetry, drift-gate and final-review sub-slices. Release-ready or Product Base merge claims still require explicit Product Manager / release governance approval and external/native/store evidence. S000 completion alone is documentation readiness only.

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
- Created for S000 routing: `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and updated `traceability.md` for this follow-up before code routing.
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
