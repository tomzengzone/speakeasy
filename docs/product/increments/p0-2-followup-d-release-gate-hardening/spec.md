# P0.2 Followup-D Spec：发布门禁与商业软件加固

## 状态
S000 documentation chain validated - 本文件把 Followup-D requirements 下沉为可验收的行为规格，并建立 S000-S011 slice routing。S000 只表示文档链可用于后续实现路由；S001-S011 仍为 planned，尚未实现、测试或批准 release/Product Base。

## 上游引用
- Increment definition：`docs/product/increments/p0-2-followup-d-release-gate-hardening/definition.md`
- Increment requirements：`docs/product/increments/p0-2-followup-d-release-gate-hardening/requirements.md`
- WP traceability scaffold：`docs/product/increments/p0-2-followup-d-release-gate-hardening/traceability.md`
- Active stage：`docs/product/stages/p0-2-training-memory.md`
- Followup-A/B/C implementation boundaries：`docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/`、`docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`、`docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`
- Commercial gates：`docs/product/increments/commercial-subscription-readiness/`、`docs/product/increments/commercial-ai-provider-hardening/`
- Release docs：`docs/release/release_checklist.md`、`docs/release/commercial_release_runbook.md`、`docs/release/rollback_plan.md`

## 规格假设和依赖
- Existing backend anchors include `GoalAutopilotService`, `GoalAutopilotController`, `EntitlementGateService`, `UsageService`, `AiCostMetricsService`, `AccountDeletionService`, `AuditLog` and release scripts.
- Existing Flutter anchors include `GoalAutopilotAdapter`, `GoalAutopilotPanel`, `GoalProgressSurface` widgets and the P0.1 `AppConfig.enableBackendTraining` source-of-truth pattern.
- Followup-D may add new domain/API/UX/Ops contracts, but S000 does not update those downstream contracts beyond planning the required outputs.
- If implementation discovers a missing API/domain/UX/AI/Ops contract field, implementation must stop and route the corresponding contract update before code continues.

## Spec Trace IDs
| Spec ID | Slice ID | Stage Scope ID | Policy Gate | Requirement ID | Spec area |
| --- | --- | --- | --- | --- | --- |
| P02-FUD-SPEC-000 | P02-FUD-S000 | P02-SI-001..013 | P02-PG-001..005 | P02-FUD-FR-000 | S000 document chain and slice routing |
| P02-FUD-SPEC-001 | P02-FUD-S001 | P02-SI-001..013 | P02-PG-003, P02-PG-004 | P02-FUD-FR-001 | Backend feature flag and kill switch |
| P02-FUD-SPEC-002 | P02-FUD-S002 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-004 | P02-FUD-FR-002 | Flutter entry and surface rollback |
| P02-FUD-SPEC-003 | P02-FUD-S003 | P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-FUD-FR-003 | Entitlement/free-paid depth policy |
| P02-FUD-SPEC-004 | P02-FUD-S004 | P02-SI-008..013 | P02-PG-004 | P02-FUD-FR-004 | Usage reservation and quota |
| P02-FUD-SPEC-005 | P02-FUD-S005 | P02-SI-008, P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-004 | P02-FUD-FR-005 | Cost telemetry and AI fallback |
| P02-FUD-SPEC-006 | P02-FUD-S006 | P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-FUD-FR-006 | Quota exhausted downgrade |
| P02-FUD-SPEC-007 | P02-FUD-S007 | P02-SI-001..013 | P02-PG-005 | P02-FUD-FR-007 | Export, retention and deletion backend evidence |
| P02-FUD-SPEC-008 | P02-FUD-S008 | P02-SI-007..013 | P02-PG-005 | P02-FUD-FR-008 | Consent and privacy UX |
| P02-FUD-SPEC-009 | P02-FUD-S009 | P02-SI-001..013 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUD-FR-009 | Telemetry health/error/funnel metrics |
| P02-FUD-SPEC-010 | P02-FUD-S010 | P02-SI-001..013 | P02-PG-001..005 | P02-FUD-FR-010 | Contract, traceability and release drift gates |
| P02-FUD-SPEC-011 | P02-FUD-S011 | P02-SI-001..013 | P02-PG-001..005 | P02-FUD-FR-011 | Product Base, release checklist and independent review gate |

## Contract Boundary Decision
Followup-D requires downstream contract updates, but S000 only records the required contract outputs.

Required downstream contract work:
- Domain model：`GoalAutopilotRuntimeGate`, `GoalAutopilotEntitlementDecision`, `GoalAutopilotUsageReservation`, `GoalAutopilotQuotaDowngrade`, `GoalAutopilotDataExport`, `GoalAutopilotMetricEvent` and release evidence refs if existing objects are insufficient.
- API/OpenAPI：runtime gate/status, export/data-governance endpoint if not covered by existing user export, telemetry/ops read endpoint if exposed, error schemas for disabled/quota/downgrade and any new entitlement-depth fields.
- AI runtime：candidate-only explanation guard for forecast/checkpoint/mastery/release-copy assistants; forbidden persistent fields include entitlement, quota, final mastery, goal-complete, official-score equivalence and release approval.
- UX screen spec：disabled/kill-switch state, entitlement depth limitations, quota exhausted, export/deletion/retention, consent copy, telemetry-unavailable and release-gated wording.
- Ops/release：release checklist, rollback plan, external evidence refs and dedicated Followup-D traceability checker.

## Implementation Slice Routing
| Slice ID | Scope | Primary state nodes | API/domain boundary | AC/TC routing | Completion evidence |
| --- | --- | --- | --- | --- | --- |
| P02-FUD-S000 | Documentation chain and implementation routing | `DocumentReady`, `ImplementationBlocked` | docs only | AC-P02-FUD-000 / TC-P02-FUD-000 | requirements/spec/acceptance/test_cases/traceability/definition updated; independent review recorded |
| P02-FUD-S001 | Backend feature flag and kill switch | `RuntimeEnabled`, `RuntimeDisabled`, `KillSwitchActive` | backend config/runtime policy/API/read downgrade | AC-P02-FUD-001 / TC-P02-FUD-001..002 | backend tests for mutation fail-closed, read downgrade, audit and rollback reason |
| P02-FUD-S002 | Flutter entry and surface rollback | `EntryEnabled`, `EntryDisabled`, `SurfaceDowngraded`, `CacheCleared` | Flutter adapter/widgets/source-of-truth guard | AC-P02-FUD-002 / TC-P02-FUD-003..004 | widget/source-of-truth tests prove no local fallback |
| P02-FUD-S003 | Entitlement/free-paid depth policy | `DepthFull`, `DepthLimited`, `DepthBlocked` | commerce/domain/API/UX entitlement decision | AC-P02-FUD-003 / TC-P02-FUD-005..006 | entitlement downgrade and server-owned depth tests |
| P02-FUD-S004 | Usage reservation and quota | `UsageReserved`, `UsageCommitted`, `UsageReleased`, `QuotaBlocked` | usage ledger/reservation/idempotency | AC-P02-FUD-004 / TC-P02-FUD-007..008 | reserve/commit/release/idempotency tests |
| P02-FUD-S005 | Cost telemetry and AI fallback | `CostRecorded`, `PolicyRejected`, `DeterministicNoProvider` | AI/cost metric/candidate-only guard | AC-P02-FUD-005 / TC-P02-FUD-009..010 | cost dashboard/policy rejection and AI forbidden-field tests |
| P02-FUD-S006 | Quota exhausted downgrade | `QuotaDowngraded`, `EntitlementBlocked`, `CostLimited` | API/UX downgrade state | AC-P02-FUD-006 / TC-P02-FUD-011..012 | backend downgrade and Flutter stale-content cleanup tests |
| P02-FUD-S007 | Export, retention and deletion backend evidence | `ExportReady`, `RetentionPolicyReady`, `DeletionProofReady` | data governance/API/security | AC-P02-FUD-007 / TC-P02-FUD-013..014 | redacted export, retention table and deletion proof tests |
| P02-FUD-S008 | Consent and privacy UX | `ConsentVisible`, `ConsentWithdrawn`, `PrivacyCopyAligned` | UX/backend consent state | AC-P02-FUD-008 / TC-P02-FUD-015 | widget/copy contract tests |
| P02-FUD-S009 | Telemetry health/error/funnel metrics | `MetricRecorded`, `MetricRedacted`, `TelemetryUnavailable` | ops telemetry/reporting | AC-P02-FUD-009 / TC-P02-FUD-016..017 | metrics tests and redaction/source coverage |
| P02-FUD-S010 | Contract, traceability and release drift gates | `DriftChecked`, `ReleaseChecklistSynced` | scripts/OpenAPI/generated client/release docs | AC-P02-FUD-010 / TC-P02-FUD-018..019 | checker, API drift and release docs gate |
| P02-FUD-S011 | Product Base, release checklist and independent review | `ReportsSynced`, `PMDecisionPending`, `IndependentReviewed` | reports/release checklist/quality gate | AC-P02-FUD-011 / TC-P02-FUD-020..021 | reports, Product Base/release status and independent review evidence |

S001 and S002 may close independently only as backend and Flutter rollout sub-slices. Full runtime exposure safety requires both slices plus S010/S011 release gates before any release-ready claim.

## Inputs
- Active GoalProfile, DiagnosticAssessment, Backplan, DailyPlan, PlanItem, Control, Forecast, Checkpoint and Projection facts from Followup-A/B/C.
- Current entitlement snapshot, quota limits, usage ledgers/reservations and AI cost metric settings.
- Runtime config, environment, kill-switch reason and release flags.
- Consent, notification control, account deletion state, export request and retention policy.
- Existing release checklist, rollback plan, paid AI/commercial external evidence refs and Product Base decision state.

## Outputs
- Runtime gate decision and disabled/downgrade state.
- Entitlement depth decision and service-owned limitation reason.
- Usage reservation/commit/release records and cost metric rows.
- Quota/cost/entitlement downgrade reason for API and Flutter surfaces.
- Redacted export package and retention/deletion evidence.
- Goal autopilot metric events and ops health summary.
- Drift checker result, release checklist status, implementation/test/quality reports and independent review.

## State Model
| State | Meaning | Allowed next states |
| --- | --- | --- |
| `DocumentReady` | S000 docs exist and map S000-S011 | `ImplementationBlocked` |
| `ImplementationBlocked` | Code routing blocked until approved AC-to-TC exists | `RuntimeEnabled`, `RuntimeDisabled` |
| `RuntimeEnabled` | P0.2 runtime can serve reads and mutations under policy gates | `DepthFull`, `DepthLimited`, `UsageReserved`, `KillSwitchActive` |
| `RuntimeDisabled` | Feature flag is off | `EntryDisabled`, `SurfaceDowngraded` |
| `KillSwitchActive` | Runtime disabled by emergency/operator control | `EntryDisabled`, `SurfaceDowngraded`, `ReportsSynced` |
| `EntryDisabled` | Flutter entry closes or renders unavailable state | terminal or `RuntimeEnabled` after flag recovery |
| `DepthFull` | Entitlement allows full P0.2 depth | `UsageReserved`, `MetricRecorded` |
| `DepthLimited` | Entitlement allows limited depth | `QuotaDowngraded`, `MetricRecorded` |
| `DepthBlocked` | Entitlement blocks full feature path | `EntitlementBlocked`, `SurfaceDowngraded` |
| `UsageReserved` | Usage is reserved for a costly path | `UsageCommitted`, `UsageReleased` |
| `UsageCommitted` | Usage is finalized after success | `CostRecorded`, `MetricRecorded` |
| `UsageReleased` | Reservation released after fallback/failure | `CostRecorded`, `QuotaDowngraded` |
| `QuotaBlocked` | Reservation rejected by quota | `QuotaDowngraded` |
| `CostRecorded` | Cost metric recorded or deterministic N/A documented | `MetricRecorded` |
| `QuotaDowngraded` | Quota/cost/entitlement limitation is exposed | `SurfaceDowngraded` |
| `ExportReady` | Redacted export data is available | `RetentionPolicyReady`, `DeletionProofReady` |
| `MetricRecorded` | Redacted funnel/health/error event exists | `DriftChecked` |
| `DriftChecked` | Contract and release doc drift gates passed | `ReportsSynced` |
| `ReportsSynced` | Reports and release checklist state are synchronized | `IndependentReviewed` |
| `IndependentReviewed` | Product and software engineering reviews recorded | terminal |

## Deterministic Policy Tables

### Runtime Gate Table
| Condition | Mutation behavior | Read/projection behavior | Required reason |
| --- | --- | --- | --- |
| feature flag on, no kill switch | allow under policy gates | normal policy-governed response | `runtime_enabled` |
| feature flag off | block mutation before data write | disabled/unavailable projection | `feature_disabled` |
| kill switch active | block mutation before data write | disabled/unavailable projection and rollback copy | `kill_switch_active` |
| backend unavailable | no client fallback | unavailable state only | `backend_unavailable` |

### Entitlement Depth Table
| Entitlement state | Diagnostic depth | Planner depth | Checkpoint depth | Explanation depth |
| --- | --- | --- | --- | --- |
| active paid/pro | configured full depth | full supported horizon | full supported task | provider/candidate allowed if quota/cost allow |
| free | minimum sample/depth | limited horizon/session count | low-cost/limited task | deterministic explanation only |
| expired/revoked/unknown | blocked or free fallback | blocked or limited fallback | blocked or limited fallback | deterministic only |
| unsupported/partial goal | limited by support matrix first | limited/blocked | limited/blocked | no precise ETA or completion copy |

### Usage And Cost Table
| Path family | Reservation required | Commit condition | Release condition | Cost metric |
| --- | --- | --- | --- | --- |
| AI-backed diagnostic/explanation | yes when provider call may occur | provider or candidate accepted | provider unavailable, validation fail, policy rejection | record success/fallback/rejection |
| Plan generation without provider | optional or N/A | deterministic generation complete | N/A | deterministic N/A metric if release gate requires |
| Checkpoint with provider/candidate | yes when provider call may occur | checkpoint accepted | low-confidence fail, provider unavailable, policy rejection | record status and cost estimate |
| Read/projection only | no | N/A | N/A | funnel/health metric only |

### Data Governance Table
| Data family | Export behavior | Deletion behavior | Retention note |
| --- | --- | --- | --- |
| goal profile and diagnostic | redacted facts, no raw audio/provider payload | hard delete on account deletion | user export or account deletion |
| plan/control/notification/replay | redacted state, hashes only | hard delete user-owned rows | replay window or audit policy |
| forecast/checkpoint/projection | safe summary and source refs | hard delete on account deletion | no stale surface cache |
| usage/cost refs | aggregate or redacted refs | delete user ledger rows where required | retain minimal audit when policy requires |

## P02-FUD-SPEC-000 S000 Document Chain And Slice Routing
- S000 creates or updates `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md`, `definition.md` and `traceability.md`.
- S000 establishes S000-S011 routing, FR/Spec/AC/TC IDs, gap register, evidence columns and report entry points.
- S000 review must check Stage Scope IDs, policy gates, A/B/C/D boundaries, release/Product Base non-claims and AC-to-TC mapping.

## P02-FUD-SPEC-001 Backend Feature Flag And Kill Switch
- Runtime gate is evaluated before every mutation path writes goal/autopilot/progress data.
- Disabled and kill-switch states return typed errors or typed downgrade responses with reason code and no partial writes.
- Read/projection endpoints return safe disabled/unavailable state and must not expose stale ETA, goal-complete or checkpoint conclusion.
- Gate decisions are auditable and support rollback review.

## P02-FUD-SPEC-002 Flutter Entry And Surface Rollback
- Flutter adapter obtains runtime/projection state from backend and treats disabled/unavailable as authoritative.
- Entry widgets close or downgrade under disabled/kill-switch state.
- No Flutter code path may instantiate local goal planner, local forecast, local quota decision or local Product Base/release state.
- Cached projection replacement removes old goal progress after disabled/downgraded response.

## P02-FUD-SPEC-003 Entitlement/Free-Paid Depth Policy
- Entitlement decision maps current plan/status to depth limits for diagnostic, planner, checkpoint and explanation.
- Decision includes `depth_state`, `allowed_depth`, `limitation_reason`, `source_entitlement_ref` or equivalent safe ref.
- Full-depth AI/provider path requires both entitlement and quota/cost gates.
- Unsupported/partial goal limitations take precedence over paid depth.

## P02-FUD-SPEC-004 Usage Reservation And Quota
- Service reserves usage before costly or AI-backed execution.
- Successful execution commits; provider or policy failure releases or records no-charge rejection.
- Idempotency prevents duplicate reservation/commit on retry.
- Quota exceeded maps to typed P0.2 downgrade or error without continuing the costly action.

## P02-FUD-SPEC-005 Cost Telemetry And AI Fallback
- Cost metrics are sanitized and grouped by plan/provider/capability/status.
- Deterministic/no-provider path records explicit N/A in evidence instead of live provider claims.
- AI candidate validators reject forbidden persistent fields.
- Policy rejection records zero-cost or rejected status with safe fallback reason.

## P02-FUD-SPEC-006 Quota Exhausted Downgrade
- Backend downgrade reasons are stable: `quota_exhausted`, `entitlement_required`, `cost_budget_limited`, `feature_disabled`, `provider_unavailable`.
- Surfaces render downgrade and remove paid/full-depth fields.
- Downgrade keeps Followup-A/B/C state semantics for unsupported, partial, low-confidence, stale and control-blocked.
- Cached full-depth content is cleared after downgrade.

## P02-FUD-SPEC-007 Export, Retention And Deletion Backend Evidence
- Export returns redacted records with family, source refs, retention rules and generated timestamp.
- Deletion proof covers P0.2 user-owned tables and existing account deletion service behavior.
- Retention rule list is explicit and auditable.
- Raw audio, raw transcript, provider payload, notification payload and idempotency keys are not exported unless separately approved.

## P02-FUD-SPEC-008 Consent And Privacy UX
- UX surfaces consent and privacy states using backend facts.
- Notification consent withdrawal blocks reminder/autopilot prompt paths as applicable.
- Copy avoids guaranteed achievement, official-score equivalence, unlimited AI and unapproved paid benefit claims.
- UX copy aligns with release checklist, privacy/support/store evidence requirements.

## P02-FUD-SPEC-009 Telemetry Health/Error/Funnel Metrics
- Metrics capture P0.2 funnel and health events with redacted payload.
- Error and downgrade metrics include reason code and source path.
- Telemetry write failure does not block user path; fallback audit or error metric is recorded where possible.
- Metrics can support release review of rollout health and cost/quota pressure.

## P02-FUD-SPEC-010 Contract, Traceability And Release Drift Gates
- Dedicated checker validates S000-S011 docs, TC rows, traceability, report evidence and forbidden release/Product Base claims.
- API drift checks run when OpenAPI or generated client changes.
- Release checklist and rollback plan references are kept synchronized with D status.
- Missing evidence blocks completion rather than being treated as a follow-up note.

## P02-FUD-SPEC-011 Product Base, Release Checklist And Independent Review Gate
- Final reports cite TC IDs, commands, results, code evidence and residual risk.
- Product Base merge state, commercial release state and paid AI external evidence state are separate fields.
- Product engineering review validates product scope, user-visible behavior, policy gate coverage and claim boundaries.
- Software engineering review validates implementability, module ownership, contracts, tests, release risks and no hidden local fallback.
