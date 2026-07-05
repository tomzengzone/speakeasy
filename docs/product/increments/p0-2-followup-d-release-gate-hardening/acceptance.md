# P0.2 Followup-D Acceptance Criteria：发布门禁与商业软件加固

## 状态
S011 final Product Base/release review acceptance passed locally with blockers preserved - 本文件基于 Followup-D requirements 和 spec 定义验收标准。AC-P02-FUD-000 已用于 S000 文档链验收；AC-P02-FUD-001 已由 TC-P02-FUD-001..002 本地覆盖 backend/API runtime gate；AC-P02-FUD-002 已由 TC-P02-FUD-003..004 本地覆盖 Flutter entry/surface rollback gate；AC-P02-FUD-003 已由 TC-P02-FUD-005..006 本地覆盖 entitlement/free-paid depth gate；AC-P02-FUD-004 已由 TC-P02-FUD-007..008 本地覆盖 usage reserve/commit/release、quota blocked、idempotent retry 和 idempotency conflict；AC-P02-FUD-005 已由 TC-P02-FUD-009..010 本地覆盖 cost telemetry、deterministic no-provider evidence、policy rejection metric 和 AI forbidden-field guard；AC-P02-FUD-006 已由 TC-P02-FUD-011..012 本地覆盖 quota/entitlement/cost downgrade、stable backend reason 和 Flutter stale full-depth cleanup；AC-P02-FUD-007 已由 TC-P02-FUD-013..014 本地覆盖 redacted export、retention rule coverage、account deletion cleanup 和 redacted audit proof；AC-P02-FUD-008 已由 TC-P02-FUD-015 本地覆盖 consent/privacy UX、notification consent withdrawn blocking、copy contract 和 stale privacy state cleanup；AC-P02-FUD-009 已由 TC-P02-FUD-016..017 本地覆盖 redacted telemetry health/error/funnel metrics、blocked reason coverage 和 non-blocking fallback audit；AC-P02-FUD-010 已由 TC-P02-FUD-018..019 本地覆盖 dedicated traceability checker、OpenAPI/generated drift、release checklist/rollback sync 和 strict release blocker preservation；AC-P02-FUD-011 已由 TC-P02-FUD-020..021 本地覆盖 final report sync、release checklist state separation、Product Base merge blocker、strict release expected-blocker preservation 和 independent review execution。AC-P02-FUD-011 不代表 release 或 Product Base approval 已完成。

## 上游来源
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/requirements.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/spec.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/definition.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/traceability.md`

## Stage Scope Acceptance Coverage
| Stage Scope ID | Policy Gate | Slice ID | Requirement ID | Spec ID | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- |
| P02-SI-001..013 | P02-PG-001..005 | P02-FUD-S000 | P02-FUD-FR-000 | P02-FUD-SPEC-000 | AC-P02-FUD-000 |
| P02-SI-001..013 | P02-PG-003, P02-PG-004 | P02-FUD-S001 | P02-FUD-FR-001 | P02-FUD-SPEC-001 | AC-P02-FUD-001 |
| P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-004 | P02-FUD-S002 | P02-FUD-FR-002 | P02-FUD-SPEC-002 | AC-P02-FUD-002 |
| P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-FUD-S003 | P02-FUD-FR-003 | P02-FUD-SPEC-003 | AC-P02-FUD-003 |
| P02-SI-008..013 | P02-PG-004 | P02-FUD-S004 | P02-FUD-FR-004 | P02-FUD-SPEC-004 | AC-P02-FUD-004 |
| P02-SI-008, P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-004 | P02-FUD-S005 | P02-FUD-FR-005 | P02-FUD-SPEC-005 | AC-P02-FUD-005 |
| P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-FUD-S006 | P02-FUD-FR-006 | P02-FUD-SPEC-006 | AC-P02-FUD-006 |
| P02-SI-001..013 | P02-PG-005 | P02-FUD-S007 | P02-FUD-FR-007 | P02-FUD-SPEC-007 | AC-P02-FUD-007 |
| P02-SI-007..013 | P02-PG-005 | P02-FUD-S008 | P02-FUD-FR-008 | P02-FUD-SPEC-008 | AC-P02-FUD-008 |
| P02-SI-001..013 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUD-S009 | P02-FUD-FR-009 | P02-FUD-SPEC-009 | AC-P02-FUD-009 |
| P02-SI-001..013 | P02-PG-001..005 | P02-FUD-S010 | P02-FUD-FR-010 | P02-FUD-SPEC-010 | AC-P02-FUD-010 |
| P02-SI-001..013 | P02-PG-001..005 | P02-FUD-S011 | P02-FUD-FR-011 | P02-FUD-SPEC-011 | AC-P02-FUD-011 |

## Implementation Slice Acceptance Routing
| Slice ID | Scope | Acceptance | Test cases | Required evidence |
| --- | --- | --- | --- | --- |
| P02-FUD-S000 | Followup-D document chain and routing | AC-P02-FUD-000 | TC-P02-FUD-000 | required docs exist, S000-S011 routing, traceability review and dual independent review |
| P02-FUD-S001 | Backend feature flag and kill switch | AC-P02-FUD-001 | TC-P02-FUD-001..002 | backend mutation/read/audit/API contract tests passed locally |
| P02-FUD-S002 | Flutter entry and surface rollback | AC-P02-FUD-002 | TC-P02-FUD-003..004 | widget/source-of-truth tests passed locally |
| P02-FUD-S003 | Entitlement/free-paid depth policy | AC-P02-FUD-003 | TC-P02-FUD-005..006 | entitlement policy/API/Flutter display tests passed locally |
| P02-FUD-S004 | Usage reservation and quota | AC-P02-FUD-004 | TC-P02-FUD-007..008 | reserve/commit/release, quota and idempotency tests passed locally |
| P02-FUD-S005 | Cost telemetry and AI fallback | AC-P02-FUD-005 | TC-P02-FUD-009..010 | cost metric and AI forbidden-field tests passed locally |
| P02-FUD-S006 | Quota exhausted downgrade | AC-P02-FUD-006 | TC-P02-FUD-011..012 | backend downgrade and Flutter stale-cache tests passed locally |
| P02-FUD-S007 | Export, retention and deletion backend evidence | AC-P02-FUD-007 | TC-P02-FUD-013..014 | export/redaction/deletion tests passed locally |
| P02-FUD-S008 | Consent and privacy UX | AC-P02-FUD-008 | TC-P02-FUD-015 | UX/copy/widget tests passed locally |
| P02-FUD-S009 | Telemetry health/error/funnel metrics | AC-P02-FUD-009 | TC-P02-FUD-016..017 | metric/redaction/fallback tests passed locally |
| P02-FUD-S010 | Contract, traceability and release drift gates | AC-P02-FUD-010 | TC-P02-FUD-018..019 | checker, API drift and release checklist tests passed locally |
| P02-FUD-S011 | Product Base, release checklist and independent review | AC-P02-FUD-011 | TC-P02-FUD-020..021 | report sync and dual independent review passed locally with blockers preserved |

## AC-P02-FUD-000 S000 Document Chain And Slice Routing
- Given S000 documentation gate runs, `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md`, `definition.md` and `traceability.md` must exist and reference the same increment id.
- Given S000 is complete, documents must contain S000-S011 slice routing and map every slice to FR, Spec, AC and TC IDs.
- Given S000 is complete, traceability must preserve P02-SI-001..013 and P02-PG-001..005 references.
- Given S000 is complete, S001-S011 code evidence and test execution evidence must remain `Not started` or `planned`.
- Given independent review runs, product engineer review must find no blocker in product scope, user-visible behavior, upstream Stage Scope coverage, policy gates, non-goals or claim boundaries.
- Given independent review runs, software engineer review must find no blocker in implementability, module ownership, contract handoff, AC-to-TC routing, source-of-truth boundary or release risk.

## AC-P02-FUD-001 Backend Feature Flag And Kill Switch
- Given P0.2 feature flag is disabled, mutation endpoints must reject before creating or changing goal/autopilot/progress data.
- Given kill switch is active, mutation endpoints must fail closed with typed reason and audit evidence.
- Given read/projection endpoints are called while disabled, they must return disabled/unavailable state without stale ETA, goal-complete or checkpoint conclusion.
- Given the flag is re-enabled, existing safe state must resume without requiring code removal.

## AC-P02-FUD-002 Flutter Entry And Surface Rollback
- Given backend runtime state is disabled or unavailable, Flutter must close or downgrade goal-autopilot entry points.
- Given Flutter receives disabled/downgraded projection, Home/Queue/Wiki/Panel must not create local goal, plan, ETA, quota or completion state.
- Given a ready projection was previously cached, disabled/downgraded state must remove old high-depth progress content.
- Given source-of-truth guard runs, it must block local entitlement/quota/final-goal inference.

## AC-P02-FUD-003 Entitlement/Free-Paid Depth Policy
- Given current entitlement is active paid, service may return full P0.2 depth only if support, quota and cost gates allow it.
- Given current entitlement is free, expired, revoked, grace, unknown or missing, service must return limited or blocked depth.
- Given goal is partial or unsupported, support limitation must override paid entitlement depth.
- Given Flutter displays depth limitation, it must render service-owned limitation rather than local entitlement inference.

## AC-P02-FUD-004 Usage Reservation And Quota
- Given a costly or AI-backed P0.2 path starts, service must reserve usage before provider/candidate execution.
- Given the path succeeds, service must commit exactly once.
- Given provider unavailable, validation failure, policy rejection or downgrade happens after reservation, service must release or record no-charge rejection.
- Given idempotent retry repeats the same operation, usage must not be double reserved or double committed.
- Given idempotency key is reused with different payload, service must return typed conflict.

## AC-P02-FUD-005 Cost Telemetry And AI Fallback
- Given P0.2 provider/candidate explanation runs, sanitized cost metric must be recorded.
- Given entitlement/quota/cost/policy rejects provider use, rejected/fallback cost metric must be recorded without creating entitlement facts.
- Given deterministic no-provider path is used, evidence must state deterministic N/A rather than live provider success.
- Given AI output includes forbidden persistent fields, validator must reject them.

## AC-P02-FUD-006 Quota Exhausted Downgrade
- Given quota is exhausted, backend must return `quota_exhausted` or equivalent typed downgrade and block full-depth behavior.
- Given entitlement or cost budget blocks behavior, backend must return stable downgrade reason.
- Given downgrade reaches Flutter, old full-depth ETA/checkpoint/explanation copy must be removed.
- Given unsupported, partial, low-confidence, stale or control-blocked state also applies, existing A/B/C downgrade semantics must remain intact.

## AC-P02-FUD-007 Export, Retention And Deletion Backend Evidence
- Given user export is requested, P0.2 data families must return redacted records and retention rules.
- Given account deletion executes, goal/autopilot/progress user-owned records must be removed or anonymized according to policy.
- Given export contains audit/replay data, idempotency keys, raw notification payloads, raw diagnostic transcripts/audio and provider payloads must be omitted or hashed.
- Given retention policy is reviewed, every P0.2 table or data family must have retention trigger and deletion/export behavior.

## AC-P02-FUD-008 Consent And Privacy UX
- Given user views P0.2 privacy/consent surfaces, copy must match backend data behavior and release checklist.
- Given notification consent is withdrawn, reminder/autopilot prompt paths must be blocked or downgraded.
- Given copy mentions paid value, AI depth, checkpoint or target outcome, it must not claim guaranteed achievement, official-score equivalence or unlimited AI.
- Given export/delete state changes, UX must not display stale consent or privacy state.

## AC-P02-FUD-009 Telemetry Health/Error/Funnel Metrics
- Given goal intake, plan, action, checkpoint or projection events occur, redacted metric events must be recorded.
- Given quota, entitlement, cost, disabled or provider fallback blocks a path, metric must include stable reason code.
- Given telemetry write fails, user path must continue and fallback audit/error evidence must exist.
- Given release review runs, metrics must be usable to evaluate rollout health, error concentration and quota/cost pressure.

## AC-P02-FUD-010 Contract, Traceability And Release Drift Gates
- Given Followup-D traceability checker runs, it must validate docs, TC rows, traceability, reports and forbidden release/Product Base claims.
- Given API shape changes, OpenAPI and generated Dart drift gates must pass before implementation closure.
- Given release checklist or rollback plan references P0.2, their status must match Followup-D traceability.
- Given any required evidence is missing, checker must block completion rather than recording it as a minor follow-up.

## AC-P02-FUD-011 Product Base, Release Checklist And Independent Review
- Given final Followup-D close is requested, implementation/test/quality reports must cite TC IDs, scripts, commands, results and residual risks.
- Given Product Base merge status is recorded, it must be separate from local deterministic completion and commercial release.
- Given paid AI external evidence is missing, release status must remain blocked or external-pending.
- Given independent review runs, product and software engineering findings must be recorded with blocker/no-blocker conclusion.

## Negative And Edge Coverage Requirements
- Disabled feature or kill switch must not create partial writes.
- Flutter must not locally compute entitlement, quota, ETA, goal-complete, official-score equivalence or release state.
- Free, expired, revoked and unknown entitlement must not receive paid depth.
- Quota exhaustion must not silently downgrade to a misleading success state.
- Data export must not include raw sensitive payloads.
- Metrics and audit must be redacted.
- Local deterministic provider behavior must not be claimed as paid AI external evidence.
- S000 documentation closure must not be read as S001-S011 implementation approval.

## AC-to-TC Requirement
Every AC-P02-FUD-000 through AC-P02-FUD-011 maps to at least one stable TC-P02-FUD ID in `docs/product/increments/p0-2-followup-d-release-gate-hardening/test_cases.md` before S001-S011 implementation routing.

## 下游交接边界
- `test_cases.md`、`traceability.md`、domain/API/OpenAPI/UX/AI/Ops contracts 和 reports may consume this file as the AC source of truth, but they must not renumber or redefine AC-P02-FUD-000 through AC-P02-FUD-011 without a versioned Followup-D change.
- Test execution status belongs in `test_cases.md`, `docs/reports/test_report.md` and `traceability.md`; this file may summarize current status but must not replace executable Test Evidence.
- S000 local documentation-chain pass, S001 backend/API runtime gate pass, S002 Flutter rollback pass, S003 entitlement depth pass, S004 usage/quota pass, S005 cost telemetry/AI fallback pass, S006 quota downgrade pass, S007 data governance pass, S008 consent/privacy UX pass, S009 telemetry pass, S010 drift-gate pass and S011 final-review pass do not approve release readiness, paid AI external evidence or Product Base merge.
