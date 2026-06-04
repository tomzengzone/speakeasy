# P0.2 Followup-B Traceability Scaffold：自动带练控制与计划记忆引擎加固

## 状态
WP traceability scaffold only - 本文件只建立 work-package 级追溯骨架；requirements/spec/acceptance/test_cases/code/test evidence 尚未生成。任何行不得被解释为实现完成。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v0.1-p0.2-followup-b-wp-scaffold |
| Last updated | 2026-06-04 |
| Owner | Product Manager Agent |
| Checker | Product Object Governance Check Agent / Documentation Governance / Independent Quality Review |
| Workflow state | Definition and WP scaffold created；requirements/spec/AC/TC not started；implementation blocked |

## 上游链路
```text
docs/product/stages/p0-2-training-memory.md
  -> docs/product/increments/p0-2-goal-backplan-memory-policy/
  -> docs/product/increments/p0-2-autopilot-progress-checkpoint/
  -> docs/reports/quality_report.md local implementation residual blockers
  -> docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/definition.md
  -> docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/traceability.md
```

## WP Traceability Matrix
| WP Trace Row ID | WP ID | Stage Scope ID | Policy Gate | Existing upstream row | Required downstream artifacts | Contract impact | Code evidence status | Test evidence status | Review gate | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUB-TR-000 | P02-FUB-WP-000 | P02-SI-001..005, P02-SI-009..011 | P02-PG-001..005 | P02-PLAN-TR-001..008, P02-AUTO-TR-003 | definition, traceability scaffold | N/A - document scaffold only | N/A - no code change | N/A - no executable test required; `git diff --check` required | Independent docs/path/trace review | In progress |
| P02-FUB-TR-001 | P02-FUB-WP-001 | P02-SI-010 | P02-PG-003, P02-PG-005 | P02-AUTO-TR-003 | requirements/spec/AC/TC for UserAutopilotControl | Domain/API/UX control state | Not started | Planned - persistence, ownership and deletion tests | Data ownership review required | Planned |
| P02-FUB-TR-002 | P02-FUB-WP-002 | P02-SI-010 | P02-PG-003 | P02-AUTO-TR-003 | requirements/spec/AC/TC for pause/resume/update-control API | API/OpenAPI, Flutter adapter, UX states | Not started | Planned - pause/resume API and widget tests | API compatibility review required | Planned |
| P02-FUB-TR-003 | P02-FUB-WP-003 | P02-SI-010 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-AUTO-TR-003, P02-AUTO-TR-007 | requirements/spec/AC/TC for quiet hours and notification eligibility | Domain/API/UX notification eligibility | Not started | Planned - quiet hours, consent, permission and entitlement tests | Privacy and commercial review required | Planned |
| P02-FUB-TR-004 | P02-FUB-WP-004 | P02-SI-010 | P02-PG-003, P02-PG-005 | P02-AUTO-TR-003 | requirements/spec/AC/TC for scheduler/outbox | Backend scheduler/outbox, Flutter local notification boundary if applicable | Not started | Planned - schedule/cancel/reschedule and audit tests | Ops/reliability review required | Planned |
| P02-FUB-TR-005 | P02-FUB-WP-005 | P02-SI-001, P02-SI-005, P02-SI-009 | P02-PG-003 | P02-PLAN-TR-003, P02-PLAN-TR-006 | requirements/spec/AC/TC for missed-day recovery planner | Domain/API planner recovery | Not started | Planned - skip/defer/missed day no-stacking tests | Planner feasibility review required | Planned |
| P02-FUB-TR-006 | P02-FUB-WP-006 | P02-SI-001, P02-SI-002, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-PLAN-TR-004, P02-PLAN-TR-005 | requirements/spec/AC/TC for item-level memory policy | Domain memory item and review policy | Not started | Planned - spacing, forgetting risk, overlearning and interleaving tests | Algorithm/replay review required | Planned |
| P02-FUB-TR-007 | P02-FUB-WP-007 | P02-SI-003, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-DIAG-TR-006, P02-PLAN-TR-004 | requirements/spec/AC/TC for L0-L5 promotion/demotion | Domain mastery transition, AI forbidden-field schema | Not started | Planned - evidence-based transition and AI rejection tests | Mastery-governance review required | Planned |
| P02-FUB-TR-008 | P02-FUB-WP-008 | P02-SI-001..005, P02-SI-009..011 | P02-PG-003, P02-PG-004 | P02-PLAN-TR-008, P02-AUTO-TR-008 | test_cases.md, replay fixtures, coverage gate, performance gate | QA scripts and reports | Not started | Planned - planner replay, p95 budgets and coverage >=80% | QA/performance review required | Planned |
| P02-FUB-TR-009 | P02-FUB-WP-009 | P02-SI-001..005, P02-SI-009..011 | P02-PG-001..005 | All Followup-B rows | quality_report.md, implementation_report.md when code exists | Reporting only | Not started | Planned - review evidence must cite TC IDs and commands after implementation | Independent final review required | Planned |

## Required Next Documents
Before any Followup-B code change, create:
- `requirements.md`
- `spec.md`
- `acceptance.md`
- `test_cases.md`
- updated `traceability.md` with FR/Spec/AC/TC rows

## Scaffold Review Checklist
- User control is modeled as a durable backend-owned state.
- Pause/resume, quiet hours, notification eligibility and recovery are not treated as UI-only behavior.
- Memory curve and L0-L5 transitions require deterministic rules and replayable tests.
- Code evidence is explicitly `Not started` rather than blank.
- Followup-B does not claim release approval or completed implementation.

