# P0.2 Test Cases：目标画像与诊断基础

## 状态
Planned + local executed evidence addendum - 本文件定义实现前测试用例，并记录 2026-06-04 本地 deterministic 垂直切片执行证据；P0.2 变更代码覆盖率门禁已由自动脚本校验通过。

## 上游来源
- `docs/product/increments/p0-2-goal-diagnostic-foundation/requirements.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/spec.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/acceptance.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md`

## AC-to-TC Gate Result
| 字段 | 值 |
| --- | --- |
| Gate | P0.2 diagnostic foundation pre-implementation AC-to-TC mapping |
| Result | Passed for documentation routing；local deterministic vertical slice executed with coverage evidence |
| Date | 2026-06-04 |
| Scope | GoalProfile, SupportedGoalMatrix, DiagnosticAssessment, rubric/confidence, weakness tags, initial mastery, commercial/data/performance/coverage gates |
| Execution status | Local functional/performance tests executed; coverage gate passed for backend changed-code line/branch and Flutter feature line coverage |
| Evidence report | `docs/reports/test_report.md` |

## Test Case Library
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-P02-DIAG-001 | P02-SI-007 | P02-DIAG-FR-001 | P02-DIAG-SPEC-001 | AC-P02-DIAG-001 | P02-DIAG-TR-001 | P02-DIAG-GAP-001 | integration | planned | `backend/src/test/java/com/speakeasy/goal/GoalProfileServiceTest.java` | `cd backend && mvn -q -Dtest=GoalProfileServiceTest test` | planned | `docs/reports/test_report.md#p02-diagnostic-foundation-planned` |
| TC-P02-DIAG-002 | P02-SI-007 | P02-DIAG-FR-002 | P02-DIAG-SPEC-002 | AC-P02-DIAG-002 | P02-DIAG-TR-002 | P02-DIAG-GAP-002 | unit | planned | `backend/src/test/java/com/speakeasy/goal/SupportedGoalMatrixTest.java` | `cd backend && mvn -q -Dtest=SupportedGoalMatrixTest test` | planned | `docs/reports/test_report.md#p02-diagnostic-foundation-planned` |
| TC-P02-DIAG-003 | P02-SI-008 | P02-DIAG-FR-003 | P02-DIAG-SPEC-003 | AC-P02-DIAG-003 | P02-DIAG-TR-003 | P02-DIAG-GAP-003 | integration | planned | `backend/src/test/java/com/speakeasy/goal/DiagnosticAssessmentServiceTest.java` | `cd backend && mvn -q -Dtest=DiagnosticAssessmentServiceTest test` | planned | `docs/reports/test_report.md#p02-diagnostic-foundation-planned` |
| TC-P02-DIAG-004 | P02-SI-008 | P02-DIAG-FR-004 | P02-DIAG-SPEC-004 | AC-P02-DIAG-004 | P02-DIAG-TR-004 | P02-DIAG-GAP-003 | contract | planned | `tests/ai_runtime/p0_2_diagnostic_eval_cases.json`; `scripts/check_p0_2_diagnostic_schema.dart` | `dart run scripts/check_p0_2_diagnostic_schema.dart` | planned | `docs/reports/test_report.md#p02-diagnostic-foundation-planned` |
| TC-P02-DIAG-005 | P02-SI-008 | P02-DIAG-FR-005 | P02-DIAG-SPEC-005 | AC-P02-DIAG-005 | P02-DIAG-TR-005 | P02-DIAG-GAP-003 | ai-eval | planned | `tests/ai_runtime/p0_2_diagnostic_eval_cases.json` | `dart run scripts/check_p0_2_diagnostic_schema.dart --eval weaknesses` | planned | `docs/reports/test_report.md#p02-diagnostic-foundation-planned` |
| TC-P02-DIAG-006 | P02-SI-003 | P02-DIAG-FR-006 | P02-DIAG-SPEC-006 | AC-P02-DIAG-006 | P02-DIAG-TR-006 | P02-DIAG-GAP-004 | unit | planned | `backend/src/test/java/com/speakeasy/goal/MasteryInitializationPolicyTest.java` | `cd backend && mvn -q -Dtest=MasteryInitializationPolicyTest test` | planned | `docs/reports/test_report.md#p02-diagnostic-foundation-planned` |
| TC-P02-DIAG-007 | P02 policy gates | P02-DIAG-FR-007 | P02-DIAG-SPEC-007 | AC-P02-DIAG-007 | P02-DIAG-TR-007 | P02-DIAG-GAP-005 | integration | planned | `backend/src/test/java/com/speakeasy/goal/DiagnosticCommercialPolicyTest.java` | `cd backend && mvn -q -Dtest=DiagnosticCommercialPolicyTest test` | planned | `docs/reports/test_report.md#p02-diagnostic-foundation-planned` |
| TC-P02-DIAG-008 | P02 policy gates | P02-DIAG-FR-007 | P02-DIAG-SPEC-007 | AC-P02-DIAG-007 | P02-DIAG-TR-007 | P02-DIAG-GAP-006 | integration | planned | `backend/src/test/java/com/speakeasy/goal/DiagnosticDataGovernanceTest.java` | `cd backend && mvn -q -Dtest=DiagnosticDataGovernanceTest test` | planned | `docs/reports/test_report.md#p02-diagnostic-foundation-planned` |
| TC-P02-DIAG-009 | P02 policy gates | P02-DIAG-FR-007 | P02-DIAG-SPEC-007 | AC-P02-DIAG-007 | P02-DIAG-TR-007 | P02-DIAG-GAP-007 | release-check | automated | `scripts/check_p0_2_goal_autopilot_coverage.py` | `python3 scripts/check_p0_2_goal_autopilot_coverage.py` | passed | `docs/reports/test_report.md#2026-06-04-p02-goal-autopilot-local-implementation-validation` |
| TC-P02-DIAG-010 | P02 policy gates | P02-DIAG-FR-001..007 | P02-DIAG-SPEC-001..007 | AC-P02-DIAG-001..007 | P02-DIAG-TR-001..007 | P02-DIAG-GAP-008 | release-check | automated | `scripts/check_p0_2_goal_autopilot_traceability.py` | `python3 scripts/check_p0_2_goal_autopilot_traceability.py` | passed | `docs/reports/test_report.md#2026-06-04-p02-goal-autopilot-local-implementation-validation` |

## Coverage Map
| Acceptance Criteria | Primary TC | Supporting TC | Coverage status |
| --- | --- | --- | --- |
| AC-P02-DIAG-001 | TC-P02-DIAG-001 | TC-P02-DIAG-010 | Covered planned |
| AC-P02-DIAG-002 | TC-P02-DIAG-002 | TC-P02-DIAG-010 | Covered planned |
| AC-P02-DIAG-003 | TC-P02-DIAG-003 | TC-P02-DIAG-004 | Covered planned |
| AC-P02-DIAG-004 | TC-P02-DIAG-004 | TC-P02-DIAG-009 | Covered planned |
| AC-P02-DIAG-005 | TC-P02-DIAG-005 | TC-P02-DIAG-010 | Covered planned |
| AC-P02-DIAG-006 | TC-P02-DIAG-006 | TC-P02-DIAG-010 | Covered planned |
| AC-P02-DIAG-007 | TC-P02-DIAG-007, TC-P02-DIAG-008, TC-P02-DIAG-009 | TC-P02-DIAG-010 | Covered planned |

## 2026-06-04 Local Executed Evidence Addendum
| TC coverage | Actual script path | Command | Result | Notes |
| --- | --- | --- | --- | --- |
| TC-P02-DIAG-001, TC-P02-DIAG-002, TC-P02-DIAG-003, TC-P02-DIAG-004, TC-P02-DIAG-005, TC-P02-DIAG-006, TC-P02-DIAG-008 | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java`; `backend/src/test/java/com/speakeasy/FoundationMigrationTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test` | passed 2026-06-04 | Covers GoalProfile, SupportedGoalMatrix, diagnostic confidence/rubric/weakness, claim guard, L0-L5 initial state and account deletion purge. |
| TC-P02-DIAG-009 | `backend/src/test/java/com/speakeasy/GoalAutopilotPerformanceTest.java`; `scripts/check_p0_2_goal_autopilot_coverage.py` | backend Maven command above; `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart`; `python3 scripts/check_p0_2_goal_autopilot_coverage.py` | passed 2026-06-04 | p95 budgets passed. Coverage gate passed: backend changed-code line 96.3% / branch 88.6%; Flutter feature line 82.1%. Dart coverage tooling does not emit branch coverage. |
| TC-P02-DIAG-010 | `docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md`; `docs/reports/test_report.md` | traceability update + `npm run check:api-contract` | passed for API/traceability evidence | Code/test/coverage evidence is now linked; commercial paid-AI release gates remain external. |

## Quality Gates
- Implementation must add automated tests before completion and must not mark any TC passed without execution evidence.
- Changed backend/domain/API/Flutter code must reach line and branch coverage >=80%.
- Performance budgets in AC-P02-DIAG-007 must be tested in CI or documented with an allowed exception.
