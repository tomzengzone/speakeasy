# P0.2 Followup-C Test Cases：周期复测、预测与多产品面加固

## 状态
S001 forecast hardening and S002 checkpoint task-library tests passed / S003-S007 implementation gated - 本文件定义 Followup-C 测试用例库。TC-P02-FUC-000 已通过 S000 文档链和 traceability routing 检查；TC-P02-FUC-001..003 已通过 S001 ProgressForecast hardening 本地测试；TC-P02-FUC-004..006 已通过 S002 Checkpoint cadence/task library 本地测试和 API contract drift；TC-P02-FUC-007..022 仍为 S003-S007 planned 测试。Followup-C is not release-ready；Product Base merge is not approved。

## 上游来源
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/requirements.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/spec.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/acceptance.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/traceability.md`

## AC-to-TC Gate Result
| 字段 | 值 |
| --- | --- |
| Gate | P0.2 Followup-C S000 pre-implementation AC-to-TC mapping |
| Result | Passed for documentation routing; implementation remains blocked until routed slice approval |
| Date | 2026-06-05 |
| Scope | ProgressForecast hardening, checkpoint cadence/task library, checkpoint-to-plan update, backend projection, Home/Queue/Wiki surfaces, downgrade/data governance, performance/coverage/traceability gates |
| Execution status | S000 documentation validation passed; S001 TC-P02-FUC-001..003 passed locally; S002 TC-P02-FUC-004..006 passed locally; S003-S007 tests planned/not started |
| Evidence report | `docs/reports/quality_report.md#2026-06-05-p02-followup-c-s000-document-chain-independent-review` |

## Implementation Slice Test Routing
| Slice ID | Scope | AC | TC | Execution state |
| --- | --- | --- | --- | --- |
| P02-FUC-S000 | Document chain and routing | AC-P02-FUC-000 | TC-P02-FUC-000 | Passed for S000 documentation validation; no code |
| P02-FUC-S001 | ProgressForecast model hardening | AC-P02-FUC-001 | TC-P02-FUC-001..003 | Passed locally |
| P02-FUC-S002 | Checkpoint cadence and task library | AC-P02-FUC-002 | TC-P02-FUC-004..006 | Passed locally |
| P02-FUC-S003 | Checkpoint-to-plan update | AC-P02-FUC-003 | TC-P02-FUC-007..009 | Planned |
| P02-FUC-S004 | Backend goal-progress projection | AC-P02-FUC-004 | TC-P02-FUC-010..012 | Planned |
| P02-FUC-S005 | Home/Queue/Wiki surface propagation | AC-P02-FUC-005 | TC-P02-FUC-013..016 | Planned |
| P02-FUC-S006 | Surface deletion/unavailable downgrade | AC-P02-FUC-006 | TC-P02-FUC-017..019 | Planned |
| P02-FUC-S007 | Automated tests, performance, coverage and final review | AC-P02-FUC-007 | TC-P02-FUC-020..022 | Planned |

## Test Case Library
| TC ID | Stage Scope ID | Policy Gate | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-P02-FUC-000 | P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-FUC-FR-000 | P02-FUC-SPEC-000 | AC-P02-FUC-000 | P02-FUC-TR-000 | P02-FUC-GAP-000 | release-check | automated | `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/*.md`; `docs/reports/quality_report.md` | `python3 scripts/project_agent_runner.py validate`; `git diff --check -- docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces docs/reports/quality_report.md` | passed | `docs/reports/quality_report.md#2026-06-05-p02-followup-c-s000-document-chain-independent-review` |
| TC-P02-FUC-001 | P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-FUC-FR-001 | P02-FUC-SPEC-001 | AC-P02-FUC-001 | P02-FUC-TR-001 | P02-FUC-GAP-001 | unit | automated | `backend/src/test/java/com/speakeasy/goal/ProgressForecastPolicyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProgressForecastPolicyTest test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-c-s001-forecast-hardening` |
| TC-P02-FUC-002 | P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-FUC-FR-001 | P02-FUC-SPEC-001 | AC-P02-FUC-001 | P02-FUC-TR-001 | P02-FUC-GAP-001 | integration | automated | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java#tcP02Fuc001ForecastHardeningClaimGuard` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc001ForecastHardeningClaimGuard test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-c-s001-forecast-hardening` |
| TC-P02-FUC-003 | P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-FUC-FR-001 | P02-FUC-SPEC-001 | AC-P02-FUC-001 | P02-FUC-TR-001 | P02-FUC-GAP-001 | ai-eval | automated | `docs/ai_runtime/ai_eval_cases.md`; `backend/src/test/java/com/speakeasy/goal/ForecastExplanationSchemaTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ForecastExplanationSchemaTest test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-c-s001-forecast-hardening` |
| TC-P02-FUC-004 | P02-SI-013 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-FUC-FR-002 | P02-FUC-SPEC-002 | AC-P02-FUC-002 | P02-FUC-TR-002 | P02-FUC-GAP-002 | unit | automated | `backend/src/test/java/com/speakeasy/goal/CheckpointCadencePolicyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CheckpointCadencePolicyTest test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-c-s002-checkpoint-task-library` |
| TC-P02-FUC-005 | P02-SI-013 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-FUC-FR-002 | P02-FUC-SPEC-002 | AC-P02-FUC-002 | P02-FUC-TR-002 | P02-FUC-GAP-002 | integration | automated | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java#tcP02Fuc002CheckpointTaskLibrary` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc002CheckpointTaskLibrary test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-c-s002-checkpoint-task-library` |
| TC-P02-FUC-006 | P02-SI-013 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-FUC-FR-002 | P02-FUC-SPEC-002 | AC-P02-FUC-002 | P02-FUC-TR-002 | P02-FUC-GAP-002 | contract | automated | `docs/architecture/openapi/speakeasy-api.yaml`; `lib/generated/api/speakeasy_api.dart` | `npm run check:api-contract` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-c-s002-checkpoint-task-library` |
| TC-P02-FUC-007 | P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-003 | P02-FUC-FR-003 | P02-FUC-SPEC-003 | AC-P02-FUC-003 | P02-FUC-TR-003 | P02-FUC-GAP-003 | integration | planned | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java#tcP02Fuc003CheckpointUpdatesForecastAndPlanSignal` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc003CheckpointUpdatesForecastAndPlanSignal test` | planned | `docs/reports/test_report.md#p02-followup-c-s003-checkpoint-plan-update` |
| TC-P02-FUC-008 | P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-003 | P02-FUC-FR-003 | P02-FUC-SPEC-003 | AC-P02-FUC-003 | P02-FUC-TR-003 | P02-FUC-GAP-003 | integration | planned | `backend/src/test/java/com/speakeasy/goal/CheckpointReplayAuditTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CheckpointReplayAuditTest test` | planned | `docs/reports/test_report.md#p02-followup-c-s003-checkpoint-plan-update` |
| TC-P02-FUC-009 | P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-003 | P02-FUC-FR-003 | P02-FUC-SPEC-003 | AC-P02-FUC-003 | P02-FUC-TR-003 | P02-FUC-GAP-003 | integration | planned | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java#tcP02Fuc003CheckpointRespectsControlAndRecoveryState` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc003CheckpointRespectsControlAndRecoveryState test` | planned | `docs/reports/test_report.md#p02-followup-c-s003-checkpoint-plan-update` |
| TC-P02-FUC-010 | P02-SI-006 | P02-PG-003, P02-PG-005 | P02-FUC-FR-004 | P02-FUC-SPEC-004 | AC-P02-FUC-004 | P02-FUC-TR-004 | P02-FUC-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/goal/GoalProgressProjectionServiceTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionServiceTest test` | planned | `docs/reports/test_report.md#p02-followup-c-s004-progress-projection` |
| TC-P02-FUC-011 | P02-SI-006 | P02-PG-003, P02-PG-005 | P02-FUC-FR-004 | P02-FUC-SPEC-004 | AC-P02-FUC-004 | P02-FUC-TR-004 | P02-FUC-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java#tcP02Fuc004ProjectionIsBackendOwned` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc004ProjectionIsBackendOwned test` | planned | `docs/reports/test_report.md#p02-followup-c-s004-progress-projection` |
| TC-P02-FUC-012 | P02-SI-006 | P02-PG-003, P02-PG-005 | P02-FUC-FR-004 | P02-FUC-SPEC-004 | AC-P02-FUC-004 | P02-FUC-TR-004 | P02-FUC-GAP-004 | contract | planned | `docs/architecture/openapi/speakeasy-api.yaml`; `lib/generated/api/speakeasy_api.dart` | `npm run check:api-contract`; `npm run check:dart-client-drift` | planned | `docs/reports/test_report.md#p02-followup-c-s004-progress-projection` |
| TC-P02-FUC-013 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-005 | P02-FUC-FR-005 | P02-FUC-SPEC-005 | AC-P02-FUC-005 | P02-FUC-TR-005 | P02-FUC-GAP-005 | widget | planned | `test/features/goal_autopilot/goal_progress_home_surface_test.dart` | `flutter test test/features/goal_autopilot/goal_progress_home_surface_test.dart` | planned | `docs/reports/test_report.md#p02-followup-c-s005-surface-propagation` |
| TC-P02-FUC-014 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-005 | P02-FUC-FR-005 | P02-FUC-SPEC-005 | AC-P02-FUC-005 | P02-FUC-TR-005 | P02-FUC-GAP-005 | widget | planned | `test/features/goal_autopilot/goal_progress_queue_surface_test.dart` | `flutter test test/features/goal_autopilot/goal_progress_queue_surface_test.dart` | planned | `docs/reports/test_report.md#p02-followup-c-s005-surface-propagation` |
| TC-P02-FUC-015 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-005 | P02-FUC-FR-005 | P02-FUC-SPEC-005 | AC-P02-FUC-005 | P02-FUC-TR-005 | P02-FUC-GAP-005 | widget | planned | `test/features/goal_autopilot/goal_progress_wiki_surface_test.dart` | `flutter test test/features/goal_autopilot/goal_progress_wiki_surface_test.dart` | planned | `docs/reports/test_report.md#p02-followup-c-s005-surface-propagation` |
| TC-P02-FUC-016 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-005 | P02-FUC-FR-005 | P02-FUC-SPEC-005 | AC-P02-FUC-005 | P02-FUC-TR-005 | P02-FUC-GAP-005 | integration | planned | `test/features/goal_autopilot/goal_progress_surface_source_of_truth_test.dart` | `flutter test test/features/goal_autopilot/goal_progress_surface_source_of_truth_test.dart` | planned | `docs/reports/test_report.md#p02-followup-c-s005-surface-propagation` |
| TC-P02-FUC-017 | P02-SI-006 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUC-FR-006 | P02-FUC-SPEC-006 | AC-P02-FUC-006 | P02-FUC-TR-006 | P02-FUC-GAP-006 | integration | planned | `backend/src/test/java/com/speakeasy/goal/GoalProgressProjectionDataGovernanceTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionDataGovernanceTest test` | planned | `docs/reports/test_report.md#p02-followup-c-s006-surface-downgrade` |
| TC-P02-FUC-018 | P02-SI-006 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUC-FR-006 | P02-FUC-SPEC-006 | AC-P02-FUC-006 | P02-FUC-TR-006 | P02-FUC-GAP-006 | widget | planned | `test/features/goal_autopilot/goal_progress_downgrade_widget_test.dart` | `flutter test test/features/goal_autopilot/goal_progress_downgrade_widget_test.dart` | planned | `docs/reports/test_report.md#p02-followup-c-s006-surface-downgrade` |
| TC-P02-FUC-019 | P02-SI-006 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUC-FR-006 | P02-FUC-SPEC-006 | AC-P02-FUC-006 | P02-FUC-TR-006 | P02-FUC-GAP-006 | integration | planned | `backend/src/test/java/com/speakeasy/AccountDeletionLearningDataTest.java#tcP02Fuc006GoalProgressProjectionPurgedOnDeletion` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AccountDeletionLearningDataTest#tcP02Fuc006GoalProgressProjectionPurgedOnDeletion test` | planned | `docs/reports/test_report.md#p02-followup-c-s006-surface-downgrade` |
| TC-P02-FUC-020 | P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-FUC-FR-007 | P02-FUC-SPEC-007 | AC-P02-FUC-007 | P02-FUC-TR-007 | P02-FUC-GAP-007 | release-check | planned | `backend/src/test/java/com/speakeasy/goal/GoalProgressProjectionPerformanceTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionPerformanceTest test` | planned | `docs/reports/test_report.md#p02-followup-c-s007-quality-gates` |
| TC-P02-FUC-021 | P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-FUC-FR-007 | P02-FUC-SPEC-007 | AC-P02-FUC-007 | P02-FUC-TR-007 | P02-FUC-GAP-008 | release-check | planned | `scripts/check_p0_2_followup_c_traceability.py`; `scripts/check_p0_2_goal_autopilot_coverage.py` | `python3 scripts/check_p0_2_followup_c_traceability.py && python3 scripts/check_p0_2_goal_autopilot_coverage.py` | planned | `docs/reports/test_report.md#p02-followup-c-s007-quality-gates` |
| TC-P02-FUC-022 | P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-FUC-FR-007 | P02-FUC-SPEC-007 | AC-P02-FUC-007 | P02-FUC-TR-007 | P02-FUC-GAP-009 | release-check | planned | `docs/reports/implementation_report.md`; `docs/reports/test_report.md`; `docs/reports/quality_report.md` | `python3 scripts/project_agent_runner.py validate`; `git diff --check` | planned | `docs/reports/quality_report.md#p02-followup-c-s007-final-independent-review` |

## Coverage Map
| Acceptance Criteria | Primary TC | Supporting TC | Coverage status |
| --- | --- | --- | --- |
| AC-P02-FUC-000 | TC-P02-FUC-000 | N/A - documentation setup only | Passed for S000 documentation routing |
| AC-P02-FUC-001 | TC-P02-FUC-001, TC-P02-FUC-002 | TC-P02-FUC-003; TC-P02-FUC-021 remains planned for final traceability gate | Passed locally for S001 forecast hardening |
| AC-P02-FUC-002 | TC-P02-FUC-004, TC-P02-FUC-005 | TC-P02-FUC-006; TC-P02-FUC-021 remains planned for final traceability gate | Passed locally for S002 checkpoint cadence/task library |
| AC-P02-FUC-003 | TC-P02-FUC-007, TC-P02-FUC-008 | TC-P02-FUC-009, TC-P02-FUC-021 | Covered planned |
| AC-P02-FUC-004 | TC-P02-FUC-010, TC-P02-FUC-011 | TC-P02-FUC-012, TC-P02-FUC-021 | Covered planned |
| AC-P02-FUC-005 | TC-P02-FUC-013, TC-P02-FUC-014, TC-P02-FUC-015 | TC-P02-FUC-016, TC-P02-FUC-021 | Covered planned; full S005 completion requires Home, Queue and Wiki together; one- or two-surface evidence is partial only |
| AC-P02-FUC-006 | TC-P02-FUC-017, TC-P02-FUC-018 | TC-P02-FUC-019, TC-P02-FUC-021 | Covered planned |
| AC-P02-FUC-007 | TC-P02-FUC-020, TC-P02-FUC-021, TC-P02-FUC-022 | TC-P02-FUC-001..019 | Covered planned |

## Required Fixture And Assertion Coverage
| Fixture ID | Fixture area | Required assertions | Planned TC |
| --- | --- | --- | --- |
| FUC-FIX-000 | S000 documentation chain | required docs exist, S000-S007 routing, FR/Spec/AC/TC mapping, no implementation/release claim | TC-P02-FUC-000 |
| FUC-FIX-001 | Forecast claim guard | supported/partial/unsupported/low-confidence/stale/deleted, ETA range, risk reason, no official-score claim, AI explanation entitlement/quota/cost blocked fallback | TC-P02-FUC-001..003 |
| FUC-FIX-002 | Checkpoint task library | weekly/biweekly, goal type matching, content coverage limitation, entitlement/quota/cost fallback | TC-P02-FUC-004..006 |
| FUC-FIX-003 | Checkpoint update | recorded/low-confidence/failed/skipped/unsupported, forecast recompute, stale/replan signal, replay/audit reference | TC-P02-FUC-007..009 |
| FUC-FIX-004 | Backend projection | source-owned next action/gap/risk/checkpoint, redacted safe fragments, unavailable/deleted projection | TC-P02-FUC-010..012 |
| FUC-FIX-005 | Surface propagation | Home, Queue, Wiki all consume projection; no local final-state recomputation; Queue ordering not locally rewritten; two-surface evidence remains partial; safe copy | TC-P02-FUC-013..016 |
| FUC-FIX-006 | Surface downgrade | deletion, unavailable, unsupported, partial, low-confidence, stale, control-blocked, cached Flutter stale data removal and backend downgrade reason traceability | TC-P02-FUC-017..019 |
| FUC-FIX-007 | Performance and traceability | p95 budgets, coverage >=80%, checker script, reports and independent review | TC-P02-FUC-020..022 |

## Slice Fixture And Assertion Entry Points
| Slice ID | Fixture entry point | Required variants | Minimum assertions before implementation closure | Owning TC |
| --- | --- | --- | --- | --- |
| P02-FUC-S001 | `FUC-FIX-001` forecast fixtures in backend policy/controller tests and AI eval cases | supported, partial, unsupported, low-confidence, stale/replan, deleted/unavailable, AI explanation allowed, AI explanation quota/cost/policy blocked | ETA is range or unavailable; no official-score or guaranteed outcome; completion requires accepted checkpoint evidence; AI output is candidate-only; blocked AI explanation falls back to deterministic key without commercial entitlement facts | TC-P02-FUC-001..003 |
| P02-FUC-S002 | `FUC-FIX-002` checkpoint task-library fixtures in backend policy/controller tests and OpenAPI contract gate | weekly due, biweekly not-due from checkpoint history, overdue, partial limited task, unsupported unavailable task, cost/quota limited deterministic-low-cost task | server returns cadence, due status, task type, prompt ref, duration, required evidence, rubric boundary and limitation reason; unsupported goals return no full task; cost fallback does not create entitlement facts; API contract/generated path registry are synced | TC-P02-FUC-004..006 |
| P02-FUC-S005 | `FUC-FIX-005` surface fixtures in Home, Queue, Wiki widget tests and source-of-truth integration test | Home projection ready, Queue projection ready, Wiki projection ready, two-surface partial milestone, backend-provided queue priority, no backend priority | all three surfaces render backend projection for full closure; two-surface evidence cannot mark S005 complete; Queue does not locally reorder final state without backend contract; surfaces do not compute ETA/goal-complete locally | TC-P02-FUC-013..016 |
| P02-FUC-S006 | `FUC-FIX-006` downgrade fixtures in backend data-governance tests and Flutter downgrade widgets | deleted, unavailable, unsupported, partial, low-confidence, stale_plan, control_blocked, cached previous projection | sensitive gap/ETA/checkpoint conclusion is removed or downgraded; Flutter stale cache does not reappear; downgrade reason comes from backend projection; no local UI inference of final state | TC-P02-FUC-017..019 |
| P02-FUC-S007 | `FUC-FIX-007` gate fixtures in traceability/performance/coverage checks | missing TC mapping, missing script path, failed performance budget, missing report evidence, S005 partial-only evidence | checker blocks incomplete evidence; p95 budgets and >=80% changed-code coverage are reported; S005 partial-only evidence cannot close Followup-C; quality report cites residual release/Product Base risk | TC-P02-FUC-020..022 |

## Performance Budgets For Planned Tests
| Budget ID | Scenario | Planned threshold | Planned TC |
| --- | --- | --- | --- |
| P02-FUC-PERF-001 | forecast recompute | p95 <=1 s | TC-P02-FUC-020 |
| P02-FUC-PERF-002 | checkpoint task lookup | p95 <=300 ms | TC-P02-FUC-020 |
| P02-FUC-PERF-003 | checkpoint submit accepted/queued | p95 <=2 s | TC-P02-FUC-020 |
| P02-FUC-PERF-004 | backend projection load | p95 <=500 ms | TC-P02-FUC-020 |
| P02-FUC-PERF-005 | surface propagation through adapter/widget path | p95 <=1 s | TC-P02-FUC-020 |

## Execution Rules
- No TC-P02-FUC row may be marked passed without command output and evidence report updates.
- Backend/domain/API tests are mandatory if forecast, checkpoint, projection, deletion or data-governance code changes.
- OpenAPI/generated client drift checks are mandatory if any API shape or generated path changes.
- Flutter widget/integration tests are mandatory if Home, Queue, Wiki, adapter or downgrade UI changes.
- AI eval/schema tests are mandatory if checkpoint feedback or forecast explanation AI schema changes.
- Forecast AI explanation tests include documented deterministic `N/A - no AI/provider path in this slice` evidence through `ForecastExplanationSchemaTest` and AI runtime docs; no commercial entitlement/quota source of truth is created in S001.
- S005 tests must include Home, Queue and Wiki fixture rows; missing one surface keeps S005 partial even if the implemented surfaces pass.
- Each routed implementation slice must expand its fixture entry point into concrete test data and assertions in the named test script before changing the TC result status from `planned`.
- Changed backend/domain/API/Flutter code must meet line and branch coverage >=80%; unchanged layers must be explicitly marked `N/A - no code change in this layer`.
- Performance tests must run before Followup-C can be marked implemented or complete.
- `scripts/check_p0_2_followup_c_traceability.py` is the planned implementation-completion deliverable for TC-P02-FUC-021; until it exists, S007 remains planned.

## Implementation Gate
AC-to-TC mapping exists for AC-P02-FUC-000 through AC-P02-FUC-007. S001 routed implementation has passed TC-P02-FUC-001..003. S002 routed implementation has passed TC-P02-FUC-004..006. S003-S007 implementation remains blocked until the routed slice is approved, relevant domain/API/OpenAPI/UX/AI contracts are updated or explicitly marked N/A, and the slice fixture/assertion entry point above has been expanded into concrete tests or a documented allowed exception.

Followup-C is not release-ready and Product Base merge is not approved. S000 documentation-chain completion must not be interpreted as forecast/checkpoint/surface implementation completion.
