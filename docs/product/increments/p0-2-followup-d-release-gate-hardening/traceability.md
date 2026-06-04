# P0.2 Followup-D Traceability Scaffold：发布门禁与商业软件加固

## 状态
WP traceability scaffold only - 本文件只建立 work-package 级追溯骨架；requirements/spec/acceptance/test_cases/code/test evidence 尚未生成。任何行不得被解释为实现完成或 release approval。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v0.1-p0.2-followup-d-wp-scaffold |
| Last updated | 2026-06-04 |
| Owner | Product Manager Agent |
| Checker | Product Object Governance Check Agent / Documentation Governance / Independent Quality Review |
| Workflow state | Definition and WP scaffold created；requirements/spec/AC/TC not started；implementation and release approval blocked |

## 上游链路
```text
docs/product/stages/p0-2-training-memory.md
  -> docs/product/increments/p0-2-goal-diagnostic-foundation/
  -> docs/product/increments/p0-2-goal-backplan-memory-policy/
  -> docs/product/increments/p0-2-autopilot-progress-checkpoint/
  -> docs/reports/quality_report.md local implementation residual blockers
  -> docs/product/increments/p0-2-followup-d-release-gate-hardening/definition.md
  -> docs/product/increments/p0-2-followup-d-release-gate-hardening/traceability.md
```

## WP Traceability Matrix
| WP Trace Row ID | WP ID | Stage Scope ID | Policy Gate | Existing upstream row | Required downstream artifacts | Contract impact | Code evidence status | Test evidence status | Review gate | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUD-TR-000 | P02-FUD-WP-000 | P02-SI-001..013 | P02-PG-001..005 | P02-DIAG/PLAN/AUTO traceability rows | definition, traceability scaffold | N/A - document scaffold only | N/A - no code change | N/A - no executable test required; `git diff --check` required | Independent docs/path/trace review | In progress |
| P02-FUD-TR-001 | P02-FUD-WP-001 | P02-SI-001..013 | P02-PG-003, P02-PG-004 | P02-AUTO-TR-008 | requirements/spec/AC/TC for feature flag and kill switch | Config/Ops/API/Flutter entry gate | Not started | Planned - flag off, kill switch and rollback tests | Release/ops review required | Planned |
| P02-FUD-TR-002 | P02-FUD-WP-002 | P02-SI-007..013 | P02-PG-004 | P02-DIAG-TR-007, P02-PLAN-TR-007, P02-AUTO-TR-007 | requirements/spec/AC/TC for entitlement/free-paid depth | Commerce/domain/API/UX entitlement boundary | Not started | Planned - entitlement downgrade and server-owned decision tests | Commercial review required | Planned |
| P02-FUD-TR-003 | P02-FUD-WP-003 | P02-SI-008..013 | P02-PG-004 | P02-DIAG-TR-007, P02-AUTO-TR-007 | requirements/spec/AC/TC for usage and cost telemetry | Usage/cost metrics/API/Ops | Not started | Planned - reserve/commit/release and cost metric tests | AI cost review required | Planned |
| P02-FUD-TR-004 | P02-FUD-WP-004 | P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-DIAG-TR-002, P02-PLAN-TR-007, P02-AUTO-TR-007 | requirements/spec/AC/TC for quota exhausted downgrade | API/UX downgrade states | Not started | Planned - quota exhausted, partial and unsupported downgrade tests | Commercial/product review required | Planned |
| P02-FUD-TR-005 | P02-FUD-WP-005 | P02-SI-007..013 | P02-PG-005 | P02-DIAG-TR-007, P02-PLAN-TR-007, P02-AUTO-TR-007 | requirements/spec/AC/TC for consent/export/retention | Data governance, API, UX, Ops | Not started | Planned - export, deletion, retention and audit tests | Privacy/security review required | Planned |
| P02-FUD-TR-006 | P02-FUD-WP-006 | P02-SI-001..013 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-AUTO-TR-008 | requirements/spec/AC/TC for telemetry health/error/funnel | Ops telemetry/reporting | Not started | Planned - intake/plan/action/checkpoint/surface telemetry tests | Observability review required | Planned |
| P02-FUD-TR-007 | P02-FUD-WP-007 | P02-SI-001..013 | P02-PG-001..005 | All P0.2 traceability rows | requirements/spec/AC/TC for contract and traceability drift gates | OpenAPI/generated client/scripts/reports | Not started | Planned - OpenAPI, generated client, traceability and coverage scripts | Contract/governance review required | Planned |
| P02-FUD-TR-008 | P02-FUD-WP-008 | P02-SI-001..013 | P02-PG-001..005 | All P0.2 traceability rows | requirements/spec/AC/TC for Product Base/release checklist gate | Product Base, release checklist, rollback plan | Not started | Planned - release checklist and Product Base merge evidence review | PM/release review required | Planned |
| P02-FUD-TR-009 | P02-FUD-WP-009 | P02-SI-001..013 | P02-PG-001..005 | All Followup-D rows | quality_report.md, implementation_report.md when code exists | Reporting only | Not started | Planned - review evidence must cite TC IDs and commands after implementation | Independent final review required | Planned |

## Required Next Documents
Before any Followup-D code or release-gate change, create:
- `requirements.md`
- `spec.md`
- `acceptance.md`
- `test_cases.md`
- updated `traceability.md` with FR/Spec/AC/TC rows

## Scaffold Review Checklist
- Release hardening applies to all P02-SI-001..013 but does not replace A/B/C functional implementation.
- Commercial, paid AI, release and Product Base merge states are explicitly separate.
- Code evidence is explicitly `Not started` rather than blank.
- Followup-D cannot be used to claim official exam score certification, guaranteed outcome, commercial release approval or Product Base merge approval.

