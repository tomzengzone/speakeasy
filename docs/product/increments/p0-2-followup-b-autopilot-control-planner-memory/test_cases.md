# P0.2 Followup-B Test Cases：自动带练控制与计划记忆引擎加固

## 状态
AC-to-TC gate complete / S004 item-level memory executed - 本文件定义 Followup-B 测试用例库。TC-P02-FUB-001、TC-P02-FUB-002、TC-P02-FUB-003 和 TC-P02-FUB-004 已有 backend/frontend control slice 本地通过证据；TC-P02-FUB-002 已关闭当前 S001 control、control idempotency、redacted audit、retention policy snapshot 和 account-deletion cleanup 范围；TC-P02-FUB-005 和 TC-P02-FUB-006 已关闭 S002-A notification eligibility policy 范围；TC-P02-FUB-007 和 TC-P02-FUB-008 已关闭 S002-B notification outbox lifecycle/replay 范围；TC-P02-FUB-009 和 TC-P02-FUB-010 已关闭 S003 missed-day recovery planner 范围；TC-P02-FUB-011 和 TC-P02-FUB-012 已关闭 S004 item-level MemoryCurvePolicy 范围，覆盖 forgetting risk、retrieval success/failure、paused/control-blocked、overlearning cap、interleaving cap、daily budget defer、default intervals 和 memory replay determinism。TC-P02-FUB-013..017 仍为 planned，其中 TC-P02-FUB-017 的 Followup-B 专用 traceability 脚本尚不存在，必须在 completion slice 中创建或由批准的等价脚本替代。

## 上游来源
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/requirements.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/spec.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/acceptance.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/traceability.md`

## AC-to-TC Gate Result
| 字段 | 值 |
| --- | --- |
| Gate | P0.2 Followup-B pre-implementation AC-to-TC mapping |
| Result | Passed for documentation routing only |
| Date | 2026-06-04 |
| Scope | UserAutopilotControl, pause/resume/update-control, quiet hours, notification scheduler/outbox, missed-day recovery, item-level MemoryCurvePolicy, L0-L5 transitions, replay/performance/coverage gates |
| Execution status | Partial - control source/update/pause/resume/backend validation/data-governance/deletion-cleanup, Flutter control binding, S002-A eligibility policy, S002-B notification outbox lifecycle/replay, S003 missed-day recovery planner and S004 item-level memory executed; remaining mastery/global replay/performance/final traceability gates planned |
| Evidence report | `docs/reports/test_report.md#2026-06-05-p02-followup-b-s004-item-level-memorycurvepolicy` |

## Implementation Slice Test Routing
| Slice ID | Scope | AC | TC | Fixture IDs | Execution state |
| --- | --- | --- | --- | --- | --- |
| P02-FUB-SLICE-001 | UserAutopilotControl source、pause/resume/update-control | AC-P02-FUB-001, AC-P02-FUB-002 | TC-P02-FUB-001..004 | FUB-FIX-001, FUB-FIX-002 | Partial executed - backend/frontend routed control subset and current control data-governance TC passed; outbox governance is closed separately in S002-B |
| P02-FUB-SLICE-002 | Notification eligibility and scheduler/outbox | AC-P02-FUB-003, AC-P02-FUB-004 | TC-P02-FUB-005..008 | FUB-FIX-003, FUB-FIX-004 | Executed for S002-A eligibility policy and S002-B outbox lifecycle/replay; TC-P02-FUB-005..008 passed |
| P02-FUB-SLICE-003 | Missed-day recovery planner | AC-P02-FUB-005 | TC-P02-FUB-009..010 | FUB-FIX-005 | Executed for S003 recovery planner; TC-P02-FUB-009/010 passed |
| P02-FUB-SLICE-004 | Item-level MemoryCurvePolicy | AC-P02-FUB-006 | TC-P02-FUB-011..012 | FUB-FIX-006 | Executed for S004 memory; TC-P02-FUB-011/012 passed |
| P02-FUB-SLICE-005 | L0-L5 mastery transition and AI candidate-only explanation | AC-P02-FUB-007 | TC-P02-FUB-013..014 | FUB-FIX-007 | Planned - evidence threshold, hold/demotion and AI forbidden-field tests required |
| P02-FUB-SLICE-006 | Replay, performance, coverage and final review gates | AC-P02-FUB-008 | TC-P02-FUB-015..017 | FUB-FIX-008, FUB-FIX-009 | Planned - replay corpus, p95 budgets, coverage and traceability script required |

## Test Case Library
| TC ID | Stage Scope ID | Policy Gate | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-P02-FUB-001 | P02-SI-010 | P02-PG-002, P02-PG-003, P02-PG-005 | P02-FUB-FR-001 | P02-FUB-SPEC-001 | AC-P02-FUB-001 | P02-FUB-TR-001 | P02-FUB-GAP-001 | integration | automated | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java#tcP02Fub001ControlIsServerOwnedAndSeparatesPolicyFromGoalProfile` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub001ControlIsServerOwnedAndSeparatesPolicyFromGoalProfile test` | passed | `docs/reports/test_report.md#2026-06-04-p02-followup-b-control-slice-implementation-validation` |
| TC-P02-FUB-002 | P02-SI-010 | P02-PG-002, P02-PG-003, P02-PG-005 | P02-FUB-FR-001 | P02-FUB-SPEC-001 | AC-P02-FUB-001 | P02-FUB-TR-001 | P02-FUB-GAP-001 | integration | automated | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-b-tc-002-control-governance-closure` |
| TC-P02-FUB-003 | P02-SI-010 | P02-PG-002, P02-PG-003 | P02-FUB-FR-002 | P02-FUB-SPEC-002 | AC-P02-FUB-002 | P02-FUB-TR-002 | P02-FUB-GAP-002 | integration | automated | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java#tcP02Fub003PauseResumeIsIdempotentAndSuppressesNextAction` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub003PauseResumeIsIdempotentAndSuppressesNextAction test` | passed | `docs/reports/test_report.md#2026-06-04-p02-followup-b-control-slice-implementation-validation` |
| TC-P02-FUB-004 | P02-SI-010 | P02-PG-002, P02-PG-003 | P02-FUB-FR-002 | P02-FUB-SPEC-002 | AC-P02-FUB-002 | P02-FUB-TR-002 | P02-FUB-GAP-002 | widget | automated | `test/features/goal_autopilot/goal_autopilot_adapter_test.dart` | `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart --name "Followup-B renders server control state and does not override pause or eligibility"` | passed | `docs/reports/test_report.md#2026-06-04-p02-followup-b-control-slice-implementation-validation` |
| TC-P02-FUB-005 | P02-SI-010 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUB-FR-003 | P02-FUB-SPEC-003 | AC-P02-FUB-003 | P02-FUB-TR-003 | P02-FUB-GAP-003 | unit | automated | `backend/src/test/java/com/speakeasy/goal/NotificationEligibilityPolicyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationEligibilityPolicyTest test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-b-s002-a-notification-eligibility-policy` |
| TC-P02-FUB-006 | P02-SI-010 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUB-FR-003 | P02-FUB-SPEC-003 | AC-P02-FUB-003 | P02-FUB-TR-003 | P02-FUB-GAP-003 | widget | automated | `test/features/goal_autopilot/goal_autopilot_adapter_test.dart` | `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart --name "Followup-B shows quiet-hours and notification blocked reasons without treating them as completion"` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-b-s002-a-notification-eligibility-policy` |
| TC-P02-FUB-007 | P02-SI-010 | P02-PG-003, P02-PG-005 | P02-FUB-FR-004 | P02-FUB-SPEC-004 | AC-P02-FUB-004 | P02-FUB-TR-004 | P02-FUB-GAP-004 | integration | automated | `backend/src/test/java/com/speakeasy/goal/NotificationOutboxServiceTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationOutboxServiceTest test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-b-s002-b-notification-outbox-lifecycle-and-replay` |
| TC-P02-FUB-008 | P02-SI-010 | P02-PG-003, P02-PG-005 | P02-FUB-FR-004 | P02-FUB-SPEC-004 | AC-P02-FUB-004 | P02-FUB-TR-004 | P02-FUB-GAP-004 | integration | automated | `backend/src/test/java/com/speakeasy/goal/NotificationOutboxReplayTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationOutboxReplayTest test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-b-s002-b-notification-outbox-lifecycle-and-replay` |
| TC-P02-FUB-009 | P02-SI-001, P02-SI-004, P02-SI-005, P02-SI-009 | P02-PG-002, P02-PG-003 | P02-FUB-FR-005 | P02-FUB-SPEC-005 | AC-P02-FUB-005 | P02-FUB-TR-005 | P02-FUB-GAP-005 | unit | automated | `backend/src/test/java/com/speakeasy/goal/MissedDayRecoveryPlannerTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MissedDayRecoveryPlannerTest test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-b-s003-missed-day-recovery-planner` |
| TC-P02-FUB-010 | P02-SI-001, P02-SI-004, P02-SI-005, P02-SI-009 | P02-PG-002, P02-PG-003 | P02-FUB-FR-005 | P02-FUB-SPEC-005 | AC-P02-FUB-005 | P02-FUB-TR-005 | P02-FUB-GAP-005 | integration | automated | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotRecoveryControllerTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotRecoveryControllerTest test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-b-s003-missed-day-recovery-planner` |
| TC-P02-FUB-011 | P02-SI-001, P02-SI-002, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-FUB-FR-006 | P02-FUB-SPEC-006 | AC-P02-FUB-006 | P02-FUB-TR-006 | P02-FUB-GAP-006 | unit | automated | `backend/src/test/java/com/speakeasy/goal/MemoryCurvePolicyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-b-s004-item-level-memorycurvepolicy` |
| TC-P02-FUB-012 | P02-SI-001, P02-SI-002, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-FUB-FR-006 | P02-FUB-SPEC-006 | AC-P02-FUB-006 | P02-FUB-TR-006 | P02-FUB-GAP-006 | integration | automated | `backend/src/test/java/com/speakeasy/goal/MemoryCurveReplayTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurveReplayTest test` | passed | `docs/reports/test_report.md#2026-06-05-p02-followup-b-s004-item-level-memorycurvepolicy` |
| TC-P02-FUB-013 | P02-SI-003, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-FUB-FR-007 | P02-FUB-SPEC-007 | AC-P02-FUB-007 | P02-FUB-TR-007 | P02-FUB-GAP-007 | unit | planned | `backend/src/test/java/com/speakeasy/goal/MasteryTransitionPolicyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest test` | planned | `docs/reports/test_report.md#p02-followup-b-planned` |
| TC-P02-FUB-014 | P02-SI-003, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-FUB-FR-007 | P02-FUB-SPEC-007 | AC-P02-FUB-007 | P02-FUB-TR-007 | P02-FUB-GAP-007 | ai-eval | planned | `docs/ai_runtime/ai_eval_cases.md`; `backend/src/test/java/com/speakeasy/goal/MasteryTransitionPolicyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest#rejectsAiPersistentMasteryFields test` | planned | `docs/reports/test_report.md#p02-followup-b-planned` |
| TC-P02-FUB-015 | P02-SI-001, P02-SI-002, P02-SI-003, P02-SI-004, P02-SI-005, P02-SI-009, P02-SI-010, P02-SI-011 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUB-FR-008 | P02-FUB-SPEC-008 | AC-P02-FUB-008 | P02-FUB-TR-008 | P02-FUB-GAP-008 | release-check | planned | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotReplayFixtureTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotReplayFixtureTest test` | planned | `docs/reports/test_report.md#p02-followup-b-planned` |
| TC-P02-FUB-016 | P02-SI-001, P02-SI-002, P02-SI-003, P02-SI-004, P02-SI-005, P02-SI-009, P02-SI-010, P02-SI-011 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUB-FR-008 | P02-FUB-SPEC-008 | AC-P02-FUB-008 | P02-FUB-TR-008 | P02-FUB-GAP-009 | release-check | planned | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotControlPerformanceTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControlPerformanceTest test` | planned | `docs/reports/test_report.md#p02-followup-b-planned` |
| TC-P02-FUB-017 | P02-SI-001, P02-SI-002, P02-SI-003, P02-SI-004, P02-SI-005, P02-SI-009, P02-SI-010, P02-SI-011 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUB-FR-008 | P02-FUB-SPEC-008 | AC-P02-FUB-008 | P02-FUB-TR-008 | P02-FUB-GAP-010 | release-check | planned | Implementation-completion path: `scripts/check_p0_2_followup_b_traceability.py`; supporting existing path: `scripts/check_p0_2_goal_autopilot_coverage.py`; pre-implementation equivalent gate: `python3 scripts/project_agent_runner.py validate`, `npm run check:api-contract`, `git diff --check -- <Followup-B docs/contracts/status files>` | Completion command after script creation: `python3 scripts/check_p0_2_followup_b_traceability.py && python3 scripts/check_p0_2_goal_autopilot_coverage.py`; pre-implementation equivalent command set: `python3 scripts/project_agent_runner.py validate && npm run check:api-contract && git diff --check -- <touched Followup-B docs/contracts/status files>` | planned | `docs/reports/test_report.md#2026-06-04-p02-followup-b-pre-implementation-test-mapping-reconciliation` |

## Coverage Map
| Acceptance Criteria | Primary TC | Supporting TC | Coverage status |
| --- | --- | --- | --- |
| AC-P02-FUB-001 | TC-P02-FUB-001, TC-P02-FUB-002 | TC-P02-FUB-017 | Executed for S001 control source, validation, internal governance export snapshot, redacted audit and deletion cleanup; notification outbox governance closes separately under AC-P02-FUB-004 / TC-P02-FUB-007/008 |
| AC-P02-FUB-002 | TC-P02-FUB-003, TC-P02-FUB-004 | TC-P02-FUB-015, TC-P02-FUB-017 | Executed for backend pause/resume/update-control and Flutter server-state binding |
| AC-P02-FUB-003 | TC-P02-FUB-005, TC-P02-FUB-006 | TC-P02-FUB-015, TC-P02-FUB-017 | Executed for S002-A notification eligibility policy; replay/final traceability support remains planned |
| AC-P02-FUB-004 | TC-P02-FUB-007, TC-P02-FUB-008 | TC-P02-FUB-015, TC-P02-FUB-017 | Executed for S002-B outbox lifecycle, redacted projection, replay audit and deletion cleanup; global replay/final traceability support remains planned |
| AC-P02-FUB-005 | TC-P02-FUB-009, TC-P02-FUB-010 | TC-P02-FUB-015, TC-P02-FUB-017 | Executed for S003 recovery planner; global replay/final traceability support remains planned |
| AC-P02-FUB-006 | TC-P02-FUB-011, TC-P02-FUB-012 | TC-P02-FUB-015, TC-P02-FUB-017 | Executed for S004 item-level memory policy; global replay/final traceability support remains planned |
| AC-P02-FUB-007 | TC-P02-FUB-013, TC-P02-FUB-014 | TC-P02-FUB-015, TC-P02-FUB-017 | Covered planned |
| AC-P02-FUB-008 | TC-P02-FUB-015, TC-P02-FUB-016, TC-P02-FUB-017 | TC-P02-FUB-001..014 | Covered planned |

## Required Fixture And Assertion Coverage
| Fixture ID | Fixture area | Required assertions | Planned TC |
| --- | --- | --- | --- |
| FUB-FIX-001 | Control source | Server-owned state, unsupported/partial/stale/missing-input blocking, deletion/export inclusion, rule version | TC-P02-FUB-001, TC-P02-FUB-002 |
| FUB-FIX-002 | Pause/resume/update-control | Idempotent pause, prompt/reminder suppression, resume re-evaluation, update-control impact fields, UI obeys server state | TC-P02-FUB-003, TC-P02-FUB-004 |
| FUB-FIX-003 | Notification eligibility | First-match reason precedence, `blocked_by_policy`, quiet hours across midnight, start=end disabled, consent/permission/entitlement/quota/stale/missing-plan reasons, no false completion evidence | TC-P02-FUB-005, TC-P02-FUB-006 |
| FUB-FIX-004 | Notification outbox | pending/scheduled/blocked/cancelled/failed/expired/sent lifecycle, stable dedupe key, cancel/reschedule, retry/failure recovery, redacted payload projection, replay audit | TC-P02-FUB-007, TC-P02-FUB-008 |
| FUB-FIX-005 | Missed-day recovery | compress/defer/replace, hard safety and feasibility precedence, `balanced` tie-breaker, no overdue stacking, daily budget cap, stale/replan reason code | TC-P02-FUB-009, TC-P02-FUB-010 |
| FUB-FIX-006 | Item-level memory | forgetting risk thresholds, retrieval success/failure, paused/control-blocked decision, overlearning cap, interleaving cap, budget defer, default review intervals, replay determinism | TC-P02-FUB-011, TC-P02-FUB-012 |
| FUB-FIX-007 | L0-L5 transitions | accepted evidence only, one-level promotion cap, confidence thresholds, low-confidence block, demotion/hold, AI persistent field rejection, no official-score claim | TC-P02-FUB-013, TC-P02-FUB-014 |
| FUB-FIX-008 | Replay gates | all Followup-B decision families compare input snapshot hash, expected decision, reason code, output state and rule version | TC-P02-FUB-015, TC-P02-FUB-017 |
| FUB-FIX-009 | Performance gates | p95 budgets for control, eligibility, outbox, recovery, memory, mastery and replay verification | TC-P02-FUB-016 |

## Policy Fixture Constants
| Constant group | Acceptance value | Owning fixtures | Planned TC |
| --- | --- | --- | --- |
| Notification reason precedence | `paused`, `blocked_by_policy`, `unsupported_goal`, `partial_goal_limited`, `stale_plan`, `missing_plan`, `consent_missing`, `permission_denied`, `entitlement_blocked`, `quota_exhausted`, `quiet_hours`, `eligible` | FUB-FIX-003 | TC-P02-FUB-005, TC-P02-FUB-006 |
| Quiet-hours window | same-day block when start < end; cross-midnight block when start > end; disabled when start == end | FUB-FIX-003 | TC-P02-FUB-005, TC-P02-FUB-006 |
| Outbox dedupe | `learner_id + goal_revision_id + plan_item_id + reminder_slot + rule_version` | FUB-FIX-004 | TC-P02-FUB-007, TC-P02-FUB-008 |
| Recovery tie-breaker | hard safety/feasibility first; user policy preference when specific; `balanced` resolves to `defer`, then `compress`, then `replace` | FUB-FIX-005 | TC-P02-FUB-009, TC-P02-FUB-010 |
| Memory thresholds | high risk >=0.70; due risk >=0.45; overlearning cap 2 selected reviews per item per 24h; interleaving cap 2 consecutive selected items per group | FUB-FIX-006 | TC-P02-FUB-011, TC-P02-FUB-012 |
| Memory default intervals | L0 one day, L1 two days, L2 four days, L3 seven days, L4 fourteen days, L5 thirty days | FUB-FIX-006 | TC-P02-FUB-011, TC-P02-FUB-012 |
| Mastery confidence thresholds | L0->L1 >=0.65, L1->L2 >=0.70, L2->L3 >=0.75, L3->L4 >=0.80, L4->L5 >=0.85; demotion requires two recent failures or one checkpoint regression with confidence >=0.70 | FUB-FIX-007 | TC-P02-FUB-013, TC-P02-FUB-014 |

## Performance Budgets For Planned Tests
| Budget ID | Scenario | Planned threshold | Planned TC |
| --- | --- | --- | --- |
| P02-FUB-PERF-001 | control state load | p95 <=200 ms | TC-P02-FUB-016 |
| P02-FUB-PERF-002 | pause/resume/update-control | p95 <=500 ms | TC-P02-FUB-016 |
| P02-FUB-PERF-003 | notification eligibility | p95 <=200 ms | TC-P02-FUB-016 |
| P02-FUB-PERF-004 | recovery replan | p95 <=500 ms | TC-P02-FUB-016 |
| P02-FUB-PERF-005 | item-level memory due calculation for 500 items | p95 <=300 ms | TC-P02-FUB-016 |
| P02-FUB-PERF-006 | L0-L5 transition decision | p95 <=300 ms | TC-P02-FUB-016 |
| P02-FUB-PERF-007 | replay verification | p95 <=500 ms | TC-P02-FUB-015, TC-P02-FUB-016 |

## Execution Rules
- No TC-P02-FUB row may be marked passed without command output and evidence report updates.
- Backend/domain/API tests are mandatory if Followup-B persistence, planner, memory, notification or mastery code changes.
- Flutter widget/adapter tests are mandatory if user control, paused, quiet-hours, recovery or memory explanation UI changes.
- AI eval or schema tests are mandatory if AI candidate explanation schema changes or forbidden persistent fields are parsed.
- Changed backend/domain/API/Flutter code must meet line and branch coverage >=80%; unchanged layers must be explicitly marked `N/A - no code change in this layer`.
- Performance tests must run before Followup-B can be marked implemented or complete.
- `scripts/check_p0_2_followup_b_traceability.py` is an approved implementation-completion deliverable, not an existing pre-implementation script. Until it exists, TC-P02-FUB-017 may only use the pre-implementation equivalent gate for routing checks and must remain `planned`.

## Implementation Gate
AC-to-TC mapping exists for AC-P02-FUB-001 through AC-P02-FUB-008. The first backend/frontend control slice has executed evidence for TC-P02-FUB-001, TC-P02-FUB-002, TC-P02-FUB-003 and TC-P02-FUB-004. TC-P02-FUB-002 is closed for current S001 persisted control data classes through validation, internal governance export snapshot, redacted audit assertions, retention policy snapshot and account-deletion cleanup. S002-A notification eligibility policy has executed evidence for TC-P02-FUB-005 and TC-P02-FUB-006. S002-B notification outbox lifecycle and replay have executed evidence for TC-P02-FUB-007 and TC-P02-FUB-008. S003 missed-day recovery planner has executed evidence for TC-P02-FUB-009 and TC-P02-FUB-010. S004 item-level MemoryCurvePolicy has executed evidence for TC-P02-FUB-011 and TC-P02-FUB-012. Remaining implementation is still gated until:
- `traceability.md`, `docs/reports/test_report.md` and `docs/reports/quality_report.md` stay synchronized with executed evidence and residual planned rows.
- TC-P02-FUB-013..017 test scripts are implemented in their planned paths or mapped to approved equivalent paths.
- For TC-P02-FUB-017, the dedicated Followup-B traceability script must still be created or replaced by an approved equivalent before Followup-B can be marked complete.
- Coverage evidence, performance evidence, replay evidence, final implementation report evidence and final independent quality review are produced after the remaining code changes.
