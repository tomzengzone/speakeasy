# P0.2 Test Cases：自动带练、进度预测与周期复测

## 状态
Planned / AC-to-TC gate complete with local executed evidence addendum - 本文件保留实现前测试设计，并记录 2026-06-04 本地垂直切片执行证据；P0.2 覆盖率门禁已由自动脚本校验通过。

## 上游来源
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/requirements.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/spec.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/acceptance.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/traceability.md`

## AC-to-TC Gate Result
| 字段 | 值 |
| --- | --- |
| Gate | P0.2 autopilot/progress/checkpoint pre-implementation AC-to-TC mapping |
| Result | Passed for documentation routing；local deterministic vertical slice has executed tests and coverage evidence |
| Date | 2026-06-04 |
| Scope | AutopilotTraining, no-choice execution, user control, ProgressForecast, OutcomeCheckpoint, evidence surfaces, commercial/data/performance/coverage gates |
| Execution status | Local backend/API/Flutter functional and performance slice executed; coverage gate passed |
| Evidence report | `docs/reports/test_report.md` |

## Test Case Library
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-P02-AUTO-001 | P02-SI-010 | P02-AUTO-FR-001 | P02-AUTO-SPEC-001 | AC-P02-AUTO-001 | P02-AUTO-TR-001 | P02-AUTO-GAP-001 | integration | planned | `backend/src/test/java/com/speakeasy/autopilot/AutopilotInputContractTest.java` | `cd backend && mvn -q -Dtest=AutopilotInputContractTest test` | planned | `docs/reports/test_report.md#p02-autopilot-progress-checkpoint-planned` |
| TC-P02-AUTO-002 | P02-SI-010 | P02-AUTO-FR-002 | P02-AUTO-SPEC-002 | AC-P02-AUTO-002 | P02-AUTO-TR-002 | P02-AUTO-GAP-002 | widget | planned | `test/features/autopilot/autopilot_daily_action_test.dart` | `flutter test test/features/autopilot/autopilot_daily_action_test.dart` | planned | `docs/reports/test_report.md#p02-autopilot-progress-checkpoint-planned` |
| TC-P02-AUTO-003 | P02-SI-010 | P02-AUTO-FR-003 | P02-AUTO-SPEC-003 | AC-P02-AUTO-003 | P02-AUTO-TR-003 | P02-AUTO-GAP-003 | widget | planned | `test/features/autopilot/autopilot_control_test.dart` | `flutter test test/features/autopilot/autopilot_control_test.dart` | planned | `docs/reports/test_report.md#p02-autopilot-progress-checkpoint-planned` |
| TC-P02-AUTO-004 | P02-SI-010 | P02-AUTO-FR-003 | P02-AUTO-SPEC-003 | AC-P02-AUTO-003 | P02-AUTO-TR-003 | P02-AUTO-GAP-003 | integration | planned | `backend/src/test/java/com/speakeasy/autopilot/AutopilotRecoveryPolicyTest.java` | `cd backend && mvn -q -Dtest=AutopilotRecoveryPolicyTest test` | planned | `docs/reports/test_report.md#p02-autopilot-progress-checkpoint-planned` |
| TC-P02-AUTO-005 | P02-SI-012 | P02-AUTO-FR-004 | P02-AUTO-SPEC-004 | AC-P02-AUTO-004 | P02-AUTO-TR-004 | P02-AUTO-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/autopilot/ProgressForecastServiceTest.java` | `cd backend && mvn -q -Dtest=ProgressForecastServiceTest test` | planned | `docs/reports/test_report.md#p02-autopilot-progress-checkpoint-planned` |
| TC-P02-AUTO-006 | P02-SI-013 | P02-AUTO-FR-005 | P02-AUTO-SPEC-005 | AC-P02-AUTO-005 | P02-AUTO-TR-005 | P02-AUTO-GAP-005 | integration | planned | `backend/src/test/java/com/speakeasy/autopilot/OutcomeCheckpointServiceTest.java` | `cd backend && mvn -q -Dtest=OutcomeCheckpointServiceTest test` | planned | `docs/reports/test_report.md#p02-autopilot-progress-checkpoint-planned` |
| TC-P02-AUTO-007 | P02-SI-006 | P02-AUTO-FR-006 | P02-AUTO-SPEC-006 | AC-P02-AUTO-006 | P02-AUTO-TR-006 | P02-AUTO-GAP-006 | widget | planned | `test/features/autopilot/goal_progress_surface_test.dart` | `flutter test test/features/autopilot/goal_progress_surface_test.dart` | planned | `docs/reports/test_report.md#p02-autopilot-progress-checkpoint-planned` |
| TC-P02-AUTO-008 | P02 policy gates | P02-AUTO-FR-007 | P02-AUTO-SPEC-007 | AC-P02-AUTO-007 | P02-AUTO-TR-007 | P02-AUTO-GAP-007 | integration | planned | `backend/src/test/java/com/speakeasy/autopilot/AutopilotCommercialPolicyTest.java` | `cd backend && mvn -q -Dtest=AutopilotCommercialPolicyTest test` | planned | `docs/reports/test_report.md#p02-autopilot-progress-checkpoint-planned` |
| TC-P02-AUTO-009 | P02 policy gates | P02-AUTO-FR-007 | P02-AUTO-SPEC-007 | AC-P02-AUTO-007 | P02-AUTO-TR-007 | P02-AUTO-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/autopilot/AutopilotDataGovernanceTest.java` | `cd backend && mvn -q -Dtest=AutopilotDataGovernanceTest test` | planned | `docs/reports/test_report.md#p02-autopilot-progress-checkpoint-planned` |
| TC-P02-AUTO-010 | P02 policy gates | P02-AUTO-FR-008 | P02-AUTO-SPEC-008 | AC-P02-AUTO-008 | P02-AUTO-TR-008 | P02-AUTO-GAP-009 | release-check | planned | `backend/src/test/java/com/speakeasy/autopilot/AutopilotPerformanceTest.java` | `cd backend && mvn -q -Dtest=AutopilotPerformanceTest test` | planned | `docs/reports/test_report.md#p02-autopilot-progress-checkpoint-planned` |
| TC-P02-AUTO-011 | P02 policy gates | P02-AUTO-FR-008 | P02-AUTO-SPEC-008 | AC-P02-AUTO-008 | P02-AUTO-TR-008 | P02-AUTO-GAP-009 | release-check | automated | `scripts/check_p0_2_goal_autopilot_coverage.py` | `python3 scripts/check_p0_2_goal_autopilot_coverage.py` | passed | `docs/reports/test_report.md#2026-06-04-p02-goal-autopilot-local-implementation-validation` |
| TC-P02-AUTO-012 | P02 policy gates | P02-AUTO-FR-001..008 | P02-AUTO-SPEC-001..008 | AC-P02-AUTO-001..008 | P02-AUTO-TR-001..008 | P02-AUTO-GAP-010 | release-check | automated | `scripts/check_p0_2_goal_autopilot_traceability.py` | `python3 scripts/check_p0_2_goal_autopilot_traceability.py` | passed | `docs/reports/test_report.md#2026-06-04-p02-goal-autopilot-local-implementation-validation` |

## Coverage Map
| Acceptance Criteria | Primary TC | Supporting TC | Coverage status |
| --- | --- | --- | --- |
| AC-P02-AUTO-001 | TC-P02-AUTO-001 | TC-P02-AUTO-012 | Covered planned |
| AC-P02-AUTO-002 | TC-P02-AUTO-002 | TC-P02-AUTO-012 | Covered planned |
| AC-P02-AUTO-003 | TC-P02-AUTO-003, TC-P02-AUTO-004 | TC-P02-AUTO-012 | Covered planned |
| AC-P02-AUTO-004 | TC-P02-AUTO-005 | TC-P02-AUTO-012 | Covered planned |
| AC-P02-AUTO-005 | TC-P02-AUTO-006 | TC-P02-AUTO-012 | Covered planned |
| AC-P02-AUTO-006 | TC-P02-AUTO-007 | TC-P02-AUTO-012 | Covered planned |
| AC-P02-AUTO-007 | TC-P02-AUTO-008, TC-P02-AUTO-009 | TC-P02-AUTO-012 | Covered planned |
| AC-P02-AUTO-008 | TC-P02-AUTO-010, TC-P02-AUTO-011 | TC-P02-AUTO-012 | Covered planned |

## Quality Gates
- Changed backend/domain/API/Flutter code must reach line and branch coverage >=80%.
- Autopilot performance budgets in AC-P02-AUTO-008 must be tested in CI or documented with an allowed exception.
- Widget tests must cover pause/resume, quiet hours, partial/unsupported, stale-plan and surface downgrade states.

## 2026-06-04 Local Executed Evidence Addendum
| Planned TC | Executed Evidence | Command | Result | Residual Gate |
| --- | --- | --- | --- | --- |
| TC-P02-AUTO-001 | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java::tcP02Diag001CreatesGoalDiagnosticAndClaimGuardSourceOfTruth`, `docs/architecture/openapi/speakeasy-api.yaml` | `npm run check:api-contract`; `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test` | Passed | None for local input contract |
| TC-P02-AUTO-002 | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java::tcP02PlanAndAuto001GeneratesMemoryPlanAndNoChoiceNextAction`, `test/features/goal_autopilot/goal_autopilot_adapter_test.dart` | Backend Maven command above; `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` | Passed | Full notification-triggered autopilot remains outside local slice |
| TC-P02-AUTO-003 | `lib/features/goal_autopilot/goal_autopilot_panel.dart`, `test/features/goal_autopilot/goal_autopilot_adapter_test.dart` | `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart`; `flutter analyze lib/features/goal_autopilot lib/services/api_client.dart lib/pages/home_page.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` | Passed for visible start/next-action/checkpoint flow | Pause/resume endpoint and notification scheduling not yet implemented |
| TC-P02-AUTO-004 | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java::tcP02PlanAndAuto001GeneratesMemoryPlanAndNoChoiceNextAction` | Backend Maven command above | Passed for complete/skip/defer recovery signal | Full adaptive workload tuning remains future work |
| TC-P02-AUTO-005 | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java::tcP02Policy001UnsupportedGoalFailsClosedWithoutFullPlanOrEta` and `::tcP02AutoCheckpoint001CheckpointUpdatesForecastAndStalesPlan` | Backend Maven command above | Passed | Forecast is deterministic/local and not official-score certification |
| TC-P02-AUTO-006 | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java::tcP02AutoCheckpoint001CheckpointUpdatesForecastAndStalesPlan` | Backend Maven command above | Passed | Broader checkpoint task library remains future content expansion |
| TC-P02-AUTO-007 | `lib/pages/home_page.dart`, `lib/features/goal_autopilot/goal_autopilot_panel.dart`, `test/features/goal_autopilot/goal_autopilot_adapter_test.dart` | Flutter test/analyze commands above | Passed for Home learn-tab surface | Queue/Wiki propagation remains future surface work |
| TC-P02-AUTO-008 | `backend/src/main/java/com/speakeasy/goal/GoalAutopilotService.java`, `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java::tcP02Policy001UnsupportedGoalFailsClosedWithoutFullPlanOrEta` | Backend Maven command above | Passed for unsupported-goal fail-closed and no official claim | Paid AI entitlement/cost telemetry remains external release gate |
| TC-P02-AUTO-009 | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java`, `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java::tcP02Data001AccountDeletionPurgesGoalAutopilotFacts` | Backend Maven command above | Passed | Export/retention policy UI remains future work |
| TC-P02-AUTO-010 | `backend/src/test/java/com/speakeasy/GoalAutopilotPerformanceTest.java::tcP02Perf001GoalAutopilotLocalBudgetsStayUnderP95Targets` | Backend Maven command above | Passed | CI p95 must keep running before release |
| TC-P02-AUTO-011 | `scripts/check_p0_2_goal_autopilot_coverage.py`; JaCoCo report `backend/target/site/jacoco/jacoco.csv`; Flutter `coverage/lcov.info` | backend JaCoCo command; `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart`; `python3 scripts/check_p0_2_goal_autopilot_coverage.py` | Passed | Coverage gate passed: backend changed-code line 96.3% / branch 88.6%; Flutter feature line 82.1%. Dart coverage tooling does not emit branch coverage. |
| TC-P02-AUTO-012 | Increment traceability docs plus generated OpenAPI path registry hash `87c9218d93a5be9879e52390a1cd2c92de6fd198938a613bbcfc89ae5e0e4f98` | `npm run check:api-contract`; local traceability review recorded in `docs/reports/quality_report.md` | Passed with residuals listed | Residual partial gates must stay visible in traceability |
