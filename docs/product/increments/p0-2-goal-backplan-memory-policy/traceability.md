# P0.2 Traceability：目标倒排计划与记忆曲线策略

## 状态
Implementation vertical slice / local tests and coverage passed - requirements、spec、acceptance、TC、domain/API/AI/UX contracts、本地 deterministic backend/frontend 代码、功能/性能测试和覆盖率证据已建立。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v0.2-p0.2-backplan-memory-policy-local-implementation |
| Last updated | 2026-06-04 |
| Owner | Product Manager Agent |
| Workflow state | Domain/API/AI/UX contracts complete；local deterministic backplan/memory policy implementation tested；coverage gate passed by script |

## 上游链路
```text
docs/product/stages/p0-2-training-memory.md
  -> docs/product/increments/p0-2-goal-backplan-memory-policy/definition.md
  -> docs/product/increments/p0-2-goal-backplan-memory-policy/requirements.md
  -> docs/product/increments/p0-2-goal-backplan-memory-policy/spec.md
  -> docs/product/increments/p0-2-goal-backplan-memory-policy/acceptance.md
  -> docs/product/increments/p0-2-goal-backplan-memory-policy/test_cases.md
  -> docs/product/increments/p0-2-goal-backplan-memory-policy/traceability.md
```

## Full Traceability Matrix
| Traceability Row ID | Stage Scope ID | Policy Gate | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P02-PLAN-TR-001 | P02-SI-009 | P02-PG-001, P02-PG-002 | p0-2-goal-backplan-memory-policy | P02-PLAN-FR-001 GoalBackplan 输入契约 | P02-PLAN-SPEC-001 | AC-P02-PLAN-001 | Domain/API/OpenAPI P0.2 plan contract | `GoalAutopilotService.generatePlan` reads active `GoalProfile`, `GoalDiagnosticAssessment`, support status and deterministic policy only | `GoalAutopilotControllerTest.tcP02PlanAndAuto001GeneratesMemoryPlanAndNoChoiceNextAction`; `tcP02Plan002PartialGoalForceReplanAndRevisionStaleExistingPlans`; coverage script | Not release scope yet | Implemented / local tests and coverage passed | Coverage gate passed |
| P02-PLAN-TR-002 | P02-SI-004, P02-SI-009 | P02-PG-003 | p0-2-goal-backplan-memory-policy | P02-PLAN-FR-002 周计划与长期 session planner | P02-PLAN-SPEC-002 | AC-P02-PLAN-002 | Domain `WeeklyBackplan`; OpenAPI `WeeklyBackplan` | `GoalBackplan`, `GoalBackplanRepository`, migration `goal_backplans`, stale/replan logic | `GoalAutopilotControllerTest.tcP02PlanAndAuto001GeneratesMemoryPlanAndNoChoiceNextAction`; checkpoint stale assertion | Not release scope yet | Implemented / local tests passed | Long-term planner is local weekly backplan slice, not release-scale optimizer |
| P02-PLAN-TR-003 | P02-SI-001, P02-SI-005 | P02-PG-003 | p0-2-goal-backplan-memory-policy | P02-PLAN-FR-003 Daily training planner | P02-PLAN-SPEC-003 | AC-P02-PLAN-003 | Domain/API/UX daily plan contract | `GoalDailyPlan`, `GoalPlanItem`, `GoalAutopilotService.createDefaultPlanItems`; Flutter `GoalAutopilotPanel` | Backend `tcP02PlanAndAuto001...`; `tcP02Plan002PartialGoalForceReplanAndRevisionStaleExistingPlans`; Flutter `P0.2 panel creates goal then renders next action`; adapter coverage test | Not release scope yet | Implemented / local tests and coverage passed | Coverage gate passed |
| P02-PLAN-TR-004 | P02-SI-003, P02-SI-011 | P02-PG-001, P02-PG-003 | p0-2-goal-backplan-memory-policy | P02-PLAN-FR-004 MemoryCurvePolicy 与 L0-L5 | P02-PLAN-SPEC-004 | AC-P02-PLAN-004 | Domain `MemoryCurvePolicy`, `MasteryInitialState`; OpenAPI `MemoryCurvePolicy` | `GoalDailyPlan` memory policy fields; `GoalMasteryInitialState` initial L0-L5 facts; deterministic no-LLM schedule | Backend `tcP02Diag001...` and `tcP02PlanAndAuto001...` | Not release scope yet | Implemented local initial/memory slice | Later promotion to final mastery remains evidence-driven future hardening |
| P02-PLAN-TR-005 | P02-SI-002, P02-SI-011 | P02-PG-003 | p0-2-goal-backplan-memory-policy | P02-PLAN-FR-005 Cross-session pressure ladder | P02-PLAN-SPEC-005 | AC-P02-PLAN-005 | Domain `PlanItem.pressure_level`; UX reason display | `GoalPlanItem.pressureLevel`, partial goals lower pressure, supported goals standard pressure | Backend `tcP02PlanAndAuto001...` checks plan item/action reason; Flutter summary renders action | Not release scope yet | Implemented local deterministic slice | Full adaptive pressure tuning remains future evidence expansion |
| P02-PLAN-TR-006 | P02-SI-005 | P02-PG-003 | p0-2-goal-backplan-memory-policy | P02-PLAN-FR-006 Cross-day orchestration | P02-PLAN-SPEC-006 | AC-P02-PLAN-006 | Domain/API recovery contract | `GoalAutopilotService.completeAction` marks skipped/deferred plans `recovery_required`; `PlanUpdateSignal` emits `recovery_replan` | Backend action completion path; performance loop exercises daily plan load | Not release scope yet | Implemented local recovery slice | Notification/calendar orchestration not included |
| P02-PLAN-TR-007 | P02 policy gates | P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | p0-2-goal-backplan-memory-policy | P02-PLAN-FR-007 Planner feasibility、商业和数据治理 | P02-PLAN-SPEC-007 | AC-P02-PLAN-007 | P02 policy gates in stage/domain/API/UX | Unsupported plan fail-closed, redacted audit, account deletion purge, deterministic no-paid-AI fallback | Backend unsupported, deletion and checkpoint tests | P0 commercial / paid AI gates remain separate | Implemented locally / release gated | Cost telemetry not expanded for local deterministic plan |
| P02-PLAN-TR-008 | P02 policy gates | P02-PG-003 | p0-2-goal-backplan-memory-policy | P02-PLAN-FR-008 性能、覆盖率与实现门禁 | P02-PLAN-SPEC-008 | AC-P02-PLAN-008 | QA/performance contracts complete | `GoalAutopilotPerformanceTest` p95 budget assertions for daily/action/forecast; backend tests; Flutter coverage report | `mvn -q -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test`; `flutter test --coverage`; `python3 scripts/check_p0_2_goal_autopilot_coverage.py` passed | Not release scope yet | Performance and coverage passed | Backend changed-code line 96.3% / branch 88.6%; Flutter feature line 82.1% |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| P02-PLAN-GAP-001 | Planner input domain/API contracts missing. | P02-PLAN-TR-001 | Domain/API | Closed by contracts and implementation |
| P02-PLAN-GAP-002 | Weekly backplan domain/API/UX contracts missing. | P02-PLAN-TR-002 | Domain/API/UX | Closed locally |
| P02-PLAN-GAP-003 | Daily planner domain/API/UX contracts missing. | P02-PLAN-TR-003 | Domain/API/UX | Closed locally |
| P02-PLAN-GAP-004 | Memory curve and L0-L5 policy missing. | P02-PLAN-TR-004 | Domain/QA | Closed for initial L0-L5 + deterministic memory policy；final promotion remains future evidence |
| P02-PLAN-GAP-005 | Cross-session pressure policy missing. | P02-PLAN-TR-005 | Domain/UX/QA | Closed for local deterministic pressure field；full adaptive tuning future |
| P02-PLAN-GAP-006 | Cross-day recovery/replan policy missing. | P02-PLAN-TR-006 | Domain/API/QA | Closed for skip/defer recovery signal |
| P02-PLAN-GAP-007 | Commercial entitlement/cost policy for planning missing. | P02-PLAN-TR-007 | Commercial/Backend/Ops | Partially closed by deterministic no-paid-AI fallback；P0 commercial gates remain |
| P02-PLAN-GAP-008 | Planner data governance contract missing. | P02-PLAN-TR-007 | Security/Data Governance | Closed locally by redacted audit and deletion purge |
| P02-PLAN-GAP-009 | Performance and >=80% code coverage gate not implemented. | P02-PLAN-TR-008 | QA/Engineering | Closed: performance passed；coverage gate passed by `scripts/check_p0_2_goal_autopilot_coverage.py` |
| P02-PLAN-GAP-010 | Executed traceability evidence missing. | P02-PLAN-TR-001..008 | QA | Closed for local functional/performance/coverage evidence |

## Completion Gate
This increment cannot be implementation-complete unless:
- every P02-PLAN-FR maps to at least one AC and TC;
- P02-SI-001, P02-SI-002, P02-SI-003, P02-SI-004, P02-SI-005, P02-SI-009 and P02-SI-011 are covered;
- every applicable P02-PG gate has contract, code and test evidence;
- changed code coverage is >=80% for line and branch coverage;
- performance budgets in AC-P02-PLAN-008 pass;
- planner replay evidence includes TC ID, script path, command, result and report link.
