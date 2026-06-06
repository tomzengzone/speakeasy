# P0.2 Followup-D Traceability：发布门禁与商业软件加固

## 状态
S000 documentation chain validated - 本文件已把 Followup-D definition、requirements、spec、acceptance、test_cases 和 S000-S011 slice routing 接入 traceability。S000 文档链验证和双视角独立审核已记录；S001-S011 code/test evidence 均为 Not started / Planned。任何行不得解释为 release approval、commercial launch approval、paid AI external evidence closure 或 Product Base merge approval。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v0.2-p0.2-followup-d-s000-document-chain |
| Last updated | 2026-06-06 |
| Owner | Product Manager Agent |
| Checker | Product Object Governance Check Agent / Documentation Governance / Independent Quality Review |
| Workflow state | S000 document chain validated；S001-S011 planned；implementation, release approval and Product Base merge blocked |

## 上游链路
```text
docs/product/stages/p0-2-training-memory.md
  -> docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/
  -> docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/
  -> docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/
  -> docs/product/increments/commercial-subscription-readiness/
  -> docs/product/increments/commercial-ai-provider-hardening/
  -> docs/release/release_checklist.md
  -> docs/product/increments/p0-2-followup-d-release-gate-hardening/definition.md
  -> docs/product/increments/p0-2-followup-d-release-gate-hardening/requirements.md
  -> docs/product/increments/p0-2-followup-d-release-gate-hardening/spec.md
  -> docs/product/increments/p0-2-followup-d-release-gate-hardening/acceptance.md
  -> docs/product/increments/p0-2-followup-d-release-gate-hardening/test_cases.md
  -> docs/product/increments/p0-2-followup-d-release-gate-hardening/traceability.md
```

## Implementation Slice Traceability
| Slice ID | WP | FR | Spec | AC | TC | Trace rows | Current status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUD-S000 | P02-FUD-WP-000 | P02-FUD-FR-000 | P02-FUD-SPEC-000 | AC-P02-FUD-000 | TC-P02-FUD-000 | P02-FUD-TR-000 | Documentation validation passed; no code |
| P02-FUD-S001 | P02-FUD-WP-001 | P02-FUD-FR-001 | P02-FUD-SPEC-001 | AC-P02-FUD-001 | TC-P02-FUD-001..002 | P02-FUD-TR-001 | Planned |
| P02-FUD-S002 | P02-FUD-WP-001 | P02-FUD-FR-002 | P02-FUD-SPEC-002 | AC-P02-FUD-002 | TC-P02-FUD-003..004 | P02-FUD-TR-002 | Planned |
| P02-FUD-S003 | P02-FUD-WP-002 | P02-FUD-FR-003 | P02-FUD-SPEC-003 | AC-P02-FUD-003 | TC-P02-FUD-005..006 | P02-FUD-TR-003 | Planned |
| P02-FUD-S004 | P02-FUD-WP-003 | P02-FUD-FR-004 | P02-FUD-SPEC-004 | AC-P02-FUD-004 | TC-P02-FUD-007..008 | P02-FUD-TR-004 | Planned |
| P02-FUD-S005 | P02-FUD-WP-003 | P02-FUD-FR-005 | P02-FUD-SPEC-005 | AC-P02-FUD-005 | TC-P02-FUD-009..010 | P02-FUD-TR-005 | Planned |
| P02-FUD-S006 | P02-FUD-WP-004 | P02-FUD-FR-006 | P02-FUD-SPEC-006 | AC-P02-FUD-006 | TC-P02-FUD-011..012 | P02-FUD-TR-006 | Planned |
| P02-FUD-S007 | P02-FUD-WP-005 | P02-FUD-FR-007 | P02-FUD-SPEC-007 | AC-P02-FUD-007 | TC-P02-FUD-013..014 | P02-FUD-TR-007 | Planned |
| P02-FUD-S008 | P02-FUD-WP-005 | P02-FUD-FR-008 | P02-FUD-SPEC-008 | AC-P02-FUD-008 | TC-P02-FUD-015 | P02-FUD-TR-008 | Planned |
| P02-FUD-S009 | P02-FUD-WP-006 | P02-FUD-FR-009 | P02-FUD-SPEC-009 | AC-P02-FUD-009 | TC-P02-FUD-016..017 | P02-FUD-TR-009 | Planned |
| P02-FUD-S010 | P02-FUD-WP-007 | P02-FUD-FR-010 | P02-FUD-SPEC-010 | AC-P02-FUD-010 | TC-P02-FUD-018..019 | P02-FUD-TR-010 | Planned |
| P02-FUD-S011 | P02-FUD-WP-008, P02-FUD-WP-009 | P02-FUD-FR-011 | P02-FUD-SPEC-011 | AC-P02-FUD-011 | TC-P02-FUD-020..021 | P02-FUD-TR-011 | Planned |

## Full Traceability Matrix
| Trace Row ID | Slice ID | WP ID | Stage Scope ID | Policy Gate | Existing upstream row | FR | Spec | AC | TC | Contract Evidence | Code Evidence | Test Evidence | Review Gate | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUD-TR-000 | P02-FUD-S000 | P02-FUD-WP-000 | P02-SI-001..013 | P02-PG-001..005 | P02-DIAG/PLAN/AUTO/FUA/FUB/FUC traceability rows; commercial release gates | P02-FUD-FR-000 | P02-FUD-SPEC-000 | AC-P02-FUD-000 | TC-P02-FUD-000 | S000 docs created: definition, requirements, spec, acceptance, test_cases and traceability | N/A - no code change | TC-P02-FUD-000 passed: `python3 scripts/project_agent_runner.py validate`; `git diff --check -- docs/product/increments/p0-2-followup-d-release-gate-hardening docs/reports/test_report.md docs/reports/implementation_report.md docs/reports/quality_report.md`; evidence `docs/reports/test_report.md#2026-06-06-p02-followup-d-s000-document-chain` | Product engineer and software engineer S000 review recorded in `docs/reports/quality_report.md#2026-06-06-p02-followup-d-s000-document-chain-dual-review` | S000 documentation validation passed |
| P02-FUD-TR-001 | P02-FUD-S001 | P02-FUD-WP-001 | P02-SI-001..013 | P02-PG-003, P02-PG-004 | P02-AUTO-TR-008, P02-FUB-TR-008, P02-FUC-TR-007 | P02-FUD-FR-001 | P02-FUD-SPEC-001 | AC-P02-FUD-001 | TC-P02-FUD-001, TC-P02-FUD-002 | Config/Ops/API runtime gate contract required | Not started | Planned - backend runtime gate tests | Release/ops review required | Planned |
| P02-FUD-TR-002 | P02-FUD-S002 | P02-FUD-WP-001 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-004 | P02-FUC-TR-005, P02-FUC-TR-006 | P02-FUD-FR-002 | P02-FUD-SPEC-002 | AC-P02-FUD-002 | TC-P02-FUD-003, TC-P02-FUD-004 | Flutter/UX entry and surface rollback contract required | Not started | Planned - widget and source-of-truth guard tests | Frontend/release review required | Planned |
| P02-FUD-TR-003 | P02-FUD-S003 | P02-FUD-WP-002 | P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-DIAG-TR-007, P02-PLAN-TR-007, P02-AUTO-TR-007, COM-TR-007 | P02-FUD-FR-003 | P02-FUD-SPEC-003 | AC-P02-FUD-003 | TC-P02-FUD-005, TC-P02-FUD-006 | Commerce/domain/API/UX entitlement depth contract required | Not started | Planned - entitlement downgrade and server-owned decision tests | Commercial review required | Planned |
| P02-FUD-TR-004 | P02-FUD-S004 | P02-FUD-WP-003 | P02-SI-008..013 | P02-PG-004 | P02-DIAG-TR-007, P02-AUTO-TR-007, COM-TR-010 | P02-FUD-FR-004 | P02-FUD-SPEC-004 | AC-P02-FUD-004 | TC-P02-FUD-007, TC-P02-FUD-008 | Usage/quota/idempotency contract required | Not started | Planned - reserve/commit/release tests | AI cost/commercial review required | Planned |
| P02-FUD-TR-005 | P02-FUD-S005 | P02-FUD-WP-003 | P02-SI-008, P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-004 | COM-AI-TR-004, P02-FUC-TR-001, P02-FUC-TR-002 | P02-FUD-FR-005 | P02-FUD-SPEC-005 | AC-P02-FUD-005 | TC-P02-FUD-009, TC-P02-FUD-010 | AI runtime/cost metric/candidate-only schema contract required | Not started | Planned - cost telemetry and AI forbidden-field tests | AI runtime/Ops review required | Planned |
| P02-FUD-TR-006 | P02-FUD-S006 | P02-FUD-WP-004 | P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-DIAG-TR-002, P02-PLAN-TR-007, P02-AUTO-TR-007, P02-FUC-TR-006 | P02-FUD-FR-006 | P02-FUD-SPEC-006 | AC-P02-FUD-006 | TC-P02-FUD-011, TC-P02-FUD-012 | API/UX downgrade states required | Not started | Planned - quota exhausted and stale-cache downgrade tests | Product/commercial review required | Planned |
| P02-FUD-TR-007 | P02-FUD-S007 | P02-FUD-WP-005 | P02-SI-001..013 | P02-PG-005 | P02-DIAG-TR-007, P02-PLAN-TR-007, P02-AUTO-TR-007, P02-FUB-TR-001, P02-FUC-TR-006, COM-AI-TR-005 | P02-FUD-FR-007 | P02-FUD-SPEC-007 | AC-P02-FUD-007 | TC-P02-FUD-013, TC-P02-FUD-014 | Data governance/API/security export-retention contract required | Not started | Planned - export, deletion, retention and audit tests | Privacy/security review required | Planned |
| P02-FUD-TR-008 | P02-FUD-S008 | P02-FUD-WP-005 | P02-SI-007..013 | P02-PG-005 | P02-FUA-TR rows, P02-FUB-TR-003, COM-TR-009 | P02-FUD-FR-008 | P02-FUD-SPEC-008 | AC-P02-FUD-008 | TC-P02-FUD-015 | UX/copy/privacy consent contract required | Not started | Planned - consent/privacy widget and copy contract tests | UX/privacy review required | Planned |
| P02-FUD-TR-009 | P02-FUD-S009 | P02-FUD-WP-006 | P02-SI-001..013 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-AUTO-TR-008, P02-FUB-TR-008, P02-FUC-TR-007, P01-TR-018 | P02-FUD-FR-009 | P02-FUD-SPEC-009 | AC-P02-FUD-009 | TC-P02-FUD-016, TC-P02-FUD-017 | Ops telemetry/reporting and redaction contract required | Not started | Planned - telemetry and redaction gate tests | Observability review required | Planned |
| P02-FUD-TR-010 | P02-FUD-S010 | P02-FUD-WP-007 | P02-SI-001..013 | P02-PG-001..005 | All P0.2 traceability rows; release docs | P02-FUD-FR-010 | P02-FUD-SPEC-010 | AC-P02-FUD-010 | TC-P02-FUD-018, TC-P02-FUD-019 | OpenAPI/generated client/scripts/release checklist/rollback plan | Not started | Planned - Followup-D checker, API drift and release readiness checks | Contract/governance review required | Planned |
| P02-FUD-TR-011 | P02-FUD-S011 | P02-FUD-WP-008, P02-FUD-WP-009 | P02-SI-001..013 | P02-PG-001..005 | All Followup-D rows; commercial/paid AI external gates | P02-FUD-FR-011 | P02-FUD-SPEC-011 | AC-P02-FUD-011 | TC-P02-FUD-020, TC-P02-FUD-021 | Product Base, release checklist, rollback plan, reports and quality review | Not started | Planned - report sync and dual independent review | PM/release/quality review required | Planned |

## Bidirectional Coverage Index
| Direction | Coverage |
| --- | --- |
| Stage scope -> Slice | P02-SI-001..013 map to S000 and S011；runtime/release gates apply to all stage scope through S001, S009 and S010；surface-specific P02-SI-006/P02-SI-010 map to S002；goal/diagnostic/planner/checkpoint depths map to S003-S006；data governance maps to S007-S008 |
| Slice -> FR | S000..S011 each map to exactly one primary FR |
| FR -> Spec -> AC -> TC | P02-FUD-FR-000..011 each has one primary P02-FUD-SPEC, AC-P02-FUD and at least one TC-P02-FUD |
| TC -> AC | TC-P02-FUD-000..021 all reference at least one AC; AC-P02-FUD-000..011 all have primary TC coverage |
| Contract -> Code | S001-S011 contract and code evidence are Not started until routed implementation |
| Code -> Test | No production code changed in S000; S001-S011 tests are planned and cannot close until scripts/commands/results are recorded |

## Gap Register
| Gap ID | Gap | Trace Row | Current handling |
| --- | --- | --- | --- |
| P02-FUD-GAP-000 | Followup-D lacked requirements/spec/acceptance/test_cases and S000-S011 slice routing. | P02-FUD-TR-000 | Closed for S000 documentation chain: required docs, S000-S011 routing, FR/Spec/AC/TC mapping, validation commands and dual independent review exist. |
| P02-FUD-GAP-001 | P0.2 goal autopilot lacks release-wide backend feature flag and kill switch evidence. | P02-FUD-TR-001 | Planned S001. |
| P02-FUD-GAP-002 | Flutter goal autopilot entry/surfaces do not yet have a dedicated disabled/rollback source-of-truth gate. | P02-FUD-TR-002 | Planned S002. |
| P02-FUD-GAP-003 | Diagnostic/planner/checkpoint/explanation depth is not yet governed by a P0.2-specific server-owned entitlement policy. | P02-FUD-TR-003 | Planned S003. |
| P02-FUD-GAP-004 | P0.2 costly paths do not yet have explicit usage reserve/commit/release and quota idempotency evidence. | P02-FUD-TR-004 | Planned S004. |
| P02-FUD-GAP-005 | P0.2 provider/candidate explanation and policy rejection do not yet have dedicated cost telemetry and AI forbidden-field evidence. | P02-FUD-TR-005 | Planned S005. |
| P02-FUD-GAP-006 | Quota exhausted, entitlement blocked and cost limited states are not yet propagated as a consistent P0.2 downgrade. | P02-FUD-TR-006 | Planned S006. |
| P02-FUD-GAP-007 | P0.2 export, retention and deletion evidence is incomplete for all goal/autopilot/progress data families. | P02-FUD-TR-007 | Planned S007. |
| P02-FUD-GAP-008 | Consent/privacy UX does not yet show P0.2 data governance and release-safe copy boundaries. | P02-FUD-TR-008 | Planned S008. |
| P02-FUD-GAP-009 | P0.2 health/error/funnel telemetry does not yet prove rollout safety. | P02-FUD-TR-009 | Planned S009. |
| P02-FUD-GAP-010 | Followup-D dedicated traceability/release drift checker does not exist yet. | P02-FUD-TR-010 | Planned S010. |
| P02-FUD-GAP-011 | Product Base/release checklist decision evidence and final independent review are not recorded for Followup-D. | P02-FUD-TR-011 | Planned S011. |

## Required Next Documents And Evidence
After S000 validation:
- Product engineer independent review confirmed product scope, upstream coverage, policy gates and claim boundaries for documentation routing.
- Software engineer independent review confirmed implementability, contracts, ownership, tests and release risks for documentation routing.
- S001 implementation must not begin unless AC-P02-FUD-001 maps to stable TC IDs and required contract updates are accepted.
- Every future executed TC must cite TC ID, script path, command, result and evidence report before any trace row moves from Planned to Implemented.

## Scaffold Review Checklist
- Release hardening applies to all P02-SI-001..013 but does not replace A/B/C functional implementation.
- Commercial, paid AI, release and Product Base merge states are explicitly separate.
- Code evidence is explicitly `Not started` rather than blank for S001-S011.
- S000 documentation readiness must not be used to claim official exam score certification, guaranteed outcome, commercial release approval or Product Base merge approval.
- Followup-D future implementation must preserve backend-owned entitlement, quota, ETA, completion and release state.

## Traceability Independent Review
S000 validation and dual independent review passed for documentation routing. Review results are recorded in `docs/reports/quality_report.md#2026-06-06-p02-followup-d-s000-document-chain-dual-review`.
