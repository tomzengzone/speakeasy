# P0.2 Test Cases：目标倒排计划与记忆曲线策略

## 状态
Planned + local executed evidence addendum - 本文件定义实现前测试用例，并记录 2026-06-04 本地 deterministic backplan/memory 垂直切片执行证据；P0.2 覆盖率门禁已由自动脚本校验通过。

## 上游来源
- `docs/product/increments/p0-2-goal-backplan-memory-policy/requirements.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/spec.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/acceptance.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/traceability.md`

## AC-to-TC Gate Result
| 字段 | 值 |
| --- | --- |
| Gate | P0.2 backplan/memory policy pre-implementation AC-to-TC mapping |
| Result | Passed for documentation routing；local deterministic vertical slice executed with coverage evidence |
| Date | 2026-06-04 |
| Scope | GoalBackplan, WeeklyBackplan, DailyTrainingPlan, MemoryCurvePolicy, L0-L5, cross-session pressure, cross-day orchestration, commercial/data/performance/coverage gates |
| Execution status | Local backend/frontend vertical-slice tests executed; coverage gate passed |
| Evidence report | `docs/reports/test_report.md` |

## Test Case Library
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-P02-PLAN-001 | P02-SI-009 | P02-PLAN-FR-001 | P02-PLAN-SPEC-001 | AC-P02-PLAN-001 | P02-PLAN-TR-001 | P02-PLAN-GAP-001 | integration | planned | `backend/src/test/java/com/speakeasy/plan/PlannerInputContractTest.java` | `cd backend && mvn -q -Dtest=PlannerInputContractTest test` | planned | `docs/reports/test_report.md#p02-backplan-memory-policy-planned` |
| TC-P02-PLAN-002 | P02-SI-004, P02-SI-009 | P02-PLAN-FR-002 | P02-PLAN-SPEC-002 | AC-P02-PLAN-002 | P02-PLAN-TR-002 | P02-PLAN-GAP-002 | unit | planned | `backend/src/test/java/com/speakeasy/plan/WeeklyBackplanPolicyTest.java` | `cd backend && mvn -q -Dtest=WeeklyBackplanPolicyTest test` | planned | `docs/reports/test_report.md#p02-backplan-memory-policy-planned` |
| TC-P02-PLAN-003 | P02-SI-001, P02-SI-005 | P02-PLAN-FR-003 | P02-PLAN-SPEC-003 | AC-P02-PLAN-003 | P02-PLAN-TR-003 | P02-PLAN-GAP-003 | unit | planned | `backend/src/test/java/com/speakeasy/plan/DailyTrainingPlannerTest.java` | `cd backend && mvn -q -Dtest=DailyTrainingPlannerTest test` | planned | `docs/reports/test_report.md#p02-backplan-memory-policy-planned` |
| TC-P02-PLAN-004 | P02-SI-003, P02-SI-011 | P02-PLAN-FR-004 | P02-PLAN-SPEC-004 | AC-P02-PLAN-004 | P02-PLAN-TR-004 | P02-PLAN-GAP-004 | unit | planned | `backend/src/test/java/com/speakeasy/plan/MemoryCurvePolicyTest.java` | `cd backend && mvn -q -Dtest=MemoryCurvePolicyTest test` | planned | `docs/reports/test_report.md#p02-backplan-memory-policy-planned` |
| TC-P02-PLAN-005 | P02-SI-002, P02-SI-011 | P02-PLAN-FR-005 | P02-PLAN-SPEC-005 | AC-P02-PLAN-005 | P02-PLAN-TR-005 | P02-PLAN-GAP-005 | unit | planned | `backend/src/test/java/com/speakeasy/plan/CrossSessionPressurePolicyTest.java` | `cd backend && mvn -q -Dtest=CrossSessionPressurePolicyTest test` | planned | `docs/reports/test_report.md#p02-backplan-memory-policy-planned` |
| TC-P02-PLAN-006 | P02-SI-005 | P02-PLAN-FR-006 | P02-PLAN-SPEC-006 | AC-P02-PLAN-006 | P02-PLAN-TR-006 | P02-PLAN-GAP-006 | unit | planned | `backend/src/test/java/com/speakeasy/plan/CrossDayRecoveryPlannerTest.java` | `cd backend && mvn -q -Dtest=CrossDayRecoveryPlannerTest test` | planned | `docs/reports/test_report.md#p02-backplan-memory-policy-planned` |
| TC-P02-PLAN-007 | P02 policy gates | P02-PLAN-FR-007 | P02-PLAN-SPEC-007 | AC-P02-PLAN-007 | P02-PLAN-TR-007 | P02-PLAN-GAP-007 | integration | planned | `backend/src/test/java/com/speakeasy/plan/PlannerCommercialPolicyTest.java` | `cd backend && mvn -q -Dtest=PlannerCommercialPolicyTest test` | planned | `docs/reports/test_report.md#p02-backplan-memory-policy-planned` |
| TC-P02-PLAN-008 | P02 policy gates | P02-PLAN-FR-007 | P02-PLAN-SPEC-007 | AC-P02-PLAN-007 | P02-PLAN-TR-007 | P02-PLAN-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/plan/PlannerDataGovernanceTest.java` | `cd backend && mvn -q -Dtest=PlannerDataGovernanceTest test` | planned | `docs/reports/test_report.md#p02-backplan-memory-policy-planned` |
| TC-P02-PLAN-009 | P02 policy gates | P02-PLAN-FR-008 | P02-PLAN-SPEC-008 | AC-P02-PLAN-008 | P02-PLAN-TR-008 | P02-PLAN-GAP-009 | release-check | automated | `scripts/check_p0_2_goal_autopilot_coverage.py` | `python3 scripts/check_p0_2_goal_autopilot_coverage.py` | passed | `docs/reports/test_report.md#2026-06-04-p02-goal-autopilot-local-implementation-validation` |
| TC-P02-PLAN-010 | P02 policy gates | P02-PLAN-FR-008 | P02-PLAN-SPEC-008 | AC-P02-PLAN-008 | P02-PLAN-TR-008 | P02-PLAN-GAP-009 | release-check | planned | `backend/src/test/java/com/speakeasy/plan/PlannerPerformanceTest.java` | `cd backend && mvn -q -Dtest=PlannerPerformanceTest test` | planned | `docs/reports/test_report.md#p02-backplan-memory-policy-planned` |
| TC-P02-PLAN-011 | P02 policy gates | P02-PLAN-FR-008 | P02-PLAN-SPEC-008 | AC-P02-PLAN-008 | P02-PLAN-TR-008 | P02-PLAN-GAP-009 | integration | planned | `backend/src/test/java/com/speakeasy/plan/PlannerReplayFixtureTest.java` | `cd backend && mvn -q -Dtest=PlannerReplayFixtureTest test` | planned | `docs/reports/test_report.md#p02-backplan-memory-policy-planned` |
| TC-P02-PLAN-012 | P02 policy gates | P02-PLAN-FR-001..008 | P02-PLAN-SPEC-001..008 | AC-P02-PLAN-001..008 | P02-PLAN-TR-001..008 | P02-PLAN-GAP-010 | release-check | automated | `scripts/check_p0_2_goal_autopilot_traceability.py` | `python3 scripts/check_p0_2_goal_autopilot_traceability.py` | passed | `docs/reports/test_report.md#2026-06-04-p02-goal-autopilot-local-implementation-validation` |

## Coverage Map
| Acceptance Criteria | Primary TC | Supporting TC | Coverage status |
| --- | --- | --- | --- |
| AC-P02-PLAN-001 | TC-P02-PLAN-001 | TC-P02-PLAN-012 | Covered planned |
| AC-P02-PLAN-002 | TC-P02-PLAN-002 | TC-P02-PLAN-012 | Covered planned |
| AC-P02-PLAN-003 | TC-P02-PLAN-003 | TC-P02-PLAN-012 | Covered planned |
| AC-P02-PLAN-004 | TC-P02-PLAN-004 | TC-P02-PLAN-011 | Covered planned |
| AC-P02-PLAN-005 | TC-P02-PLAN-005 | TC-P02-PLAN-011 | Covered planned |
| AC-P02-PLAN-006 | TC-P02-PLAN-006 | TC-P02-PLAN-012 | Covered planned |
| AC-P02-PLAN-007 | TC-P02-PLAN-007, TC-P02-PLAN-008 | TC-P02-PLAN-012 | Covered planned |
| AC-P02-PLAN-008 | TC-P02-PLAN-009, TC-P02-PLAN-010, TC-P02-PLAN-011 | TC-P02-PLAN-012 | Covered planned |

## Quality Gates
- Changed backend/domain/API/Flutter code must reach line and branch coverage >=80%.
- Planner performance budgets in AC-P02-PLAN-008 must be tested in CI or documented with an allowed exception.
- Replay fixtures are mandatory for planner decisions, memory curve and pressure changes.

## 2026-06-04 Local Executed Evidence Addendum
| TC coverage | Actual script path | Command | Result | Notes |
| --- | --- | --- | --- | --- |
| TC-P02-PLAN-001 through TC-P02-PLAN-008 | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java`; `lib/features/goal_autopilot/`; `test/features/goal_autopilot/goal_autopilot_adapter_test.dart` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test`; `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` | passed 2026-06-04 | Covers accepted input contract, weekly/daily plan, memory policy fields, initial L0-L5 state, pressure level, skip/defer recovery signal and data governance purge. |
| TC-P02-PLAN-009, TC-P02-PLAN-010 | `backend/src/test/java/com/speakeasy/GoalAutopilotPerformanceTest.java`; `scripts/check_p0_2_goal_autopilot_coverage.py` | backend Maven command above; `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart`; `python3 scripts/check_p0_2_goal_autopilot_coverage.py` | passed for performance and coverage | p95 budgets asserted for goal intake, daily plan, next action and forecast. Coverage gate passed: backend changed-code line 96.3% / branch 88.6%; Flutter feature line 82.1%. |
| TC-P02-PLAN-011, TC-P02-PLAN-012 | `docs/product/increments/p0-2-goal-backplan-memory-policy/traceability.md`; `docs/architecture/openapi/speakeasy-api.yaml` | `npm run check:api-contract` | passed 2026-06-04 | OpenAPI traceability, generated Dart path registry and implementation evidence are linked. |
