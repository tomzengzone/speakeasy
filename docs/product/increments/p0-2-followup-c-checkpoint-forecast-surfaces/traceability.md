# P0.2 Followup-C Traceability Scaffold：周期复测、预测与多产品面加固

## 状态
WP traceability scaffold only - 本文件只建立 work-package 级追溯骨架；requirements/spec/acceptance/test_cases/code/test evidence 尚未生成。任何行不得被解释为实现完成。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v0.1-p0.2-followup-c-wp-scaffold |
| Last updated | 2026-06-04 |
| Owner | Product Manager Agent |
| Checker | Product Object Governance Check Agent / Documentation Governance / Independent Quality Review |
| Workflow state | Definition and WP scaffold created；requirements/spec/AC/TC not started；implementation blocked |

## 上游链路
```text
docs/product/stages/p0-2-training-memory.md
  -> docs/product/increments/p0-2-autopilot-progress-checkpoint/
  -> docs/reports/quality_report.md local implementation residual blockers
  -> docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/definition.md
  -> docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/traceability.md
```

## WP Traceability Matrix
| WP Trace Row ID | WP ID | Stage Scope ID | Policy Gate | Existing upstream row | Required downstream artifacts | Contract impact | Code evidence status | Test evidence status | Review gate | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUC-TR-000 | P02-FUC-WP-000 | P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-AUTO-TR-001..008 | definition, traceability scaffold | N/A - document scaffold only | N/A - no code change | N/A - no executable test required; `git diff --check` required | Independent docs/path/trace review | In progress |
| P02-FUC-TR-001 | P02-FUC-WP-001 | P02-SI-012 | P02-PG-001, P02-PG-002 | P02-AUTO-TR-004 | requirements/spec/AC/TC for forecast hardening | Domain/API/AI/UX forecast | Not started | Planned - gap, ETA range, confidence and risk tests | Claim guard review required | Planned |
| P02-FUC-TR-002 | P02-FUC-WP-002 | P02-SI-013 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-AUTO-TR-005 | requirements/spec/AC/TC for checkpoint cadence/task library | Domain/content/API/AI/UX checkpoint contract | Not started | Planned - weekly/biweekly and goal-type task tests | Content/scoring review required | Planned |
| P02-FUC-TR-003 | P02-FUC-WP-003 | P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-003 | P02-AUTO-TR-004, P02-AUTO-TR-005 | requirements/spec/AC/TC for checkpoint-to-plan updates | Domain/API plan stale/replan signal | Not started | Planned - checkpoint updates forecast and stale plan tests | Planner compatibility review required | Planned |
| P02-FUC-TR-004 | P02-FUC-WP-004 | P02-SI-006 | P02-PG-005 | P02-AUTO-TR-006 | requirements/spec/AC/TC for backend progress projection | Domain/API projection | Not started | Planned - projection source-of-truth tests | Data ownership review required | Planned |
| P02-FUC-TR-005 | P02-FUC-WP-005 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-005 | P02-AUTO-TR-002, P02-AUTO-TR-006 | requirements/spec/AC/TC for Home/Queue/Wiki propagation | Flutter surfaces, API adapter, UX states | Not started | Planned - widget tests for at least two surfaces | UX/source-of-truth review required | Planned |
| P02-FUC-TR-006 | P02-FUC-WP-006 | P02-SI-006 | P02-PG-005 | P02-AUTO-TR-006, P02-AUTO-TR-007 | requirements/spec/AC/TC for deletion/unavailable downgrade | Data governance, UX downgrade states | Not started | Planned - deletion, unavailable and unsupported downgrade tests | Privacy review required | Planned |
| P02-FUC-TR-007 | P02-FUC-WP-007 | P02-SI-006, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-AUTO-TR-008 | test_cases.md, coverage gate, performance gate | QA scripts and reports | Not started | Planned - API/widget/integration p95 budgets and coverage >=80% | QA/performance review required | Planned |
| P02-FUC-TR-008 | P02-FUC-WP-008 | P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | All Followup-C rows | quality_report.md, implementation_report.md when code exists | Reporting only | Not started | Planned - review evidence must cite TC IDs and commands after implementation | Independent final review required | Planned |

## Required Next Documents
Before any Followup-C code change, create:
- `requirements.md`
- `spec.md`
- `acceptance.md`
- `test_cases.md`
- updated `traceability.md` with FR/Spec/AC/TC rows

## Scaffold Review Checklist
- Queue/Wiki/Home progress displays are treated as backend-owned projections.
- At least two product surfaces must be covered by AC and widget/integration tests before implementation completion.
- Forecast and checkpoint copy cannot claim official score certification or guaranteed outcome.
- Code evidence is explicitly `Not started` rather than blank.
- Followup-C does not claim release approval or completed implementation.

