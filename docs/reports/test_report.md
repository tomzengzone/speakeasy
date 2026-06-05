# Test Report

## Current Status
Latest recorded Followup-B validation: `P02-FOLLOWUP-B-S005-MASTERY-TRANSITION-20260605` closes TC-P02-FUB-013 and TC-P02-FUB-014 for S005 L0-L5 mastery transition and AI candidate-only explanation guardrails: accepted-evidence thresholds, one-level promotion cap, hold/demotion outcomes, read-only transition audit, deterministic `mastery_transition` replay audit, account-deletion cleanup and forbidden persistent-field rejection. TC-P02-FUB-001 through TC-P02-FUB-014 are passed. TC-P02-FUB-015..017 remain planned, including global replay, performance and dedicated Followup-B traceability script. Followup-A remains locally passed; Followup-C Queue/Wiki propagation and Followup-D commercial/release gates remain open.

## Required Sections
- test scope
- commands run
- passing tests
- failing tests
- skipped tests
- acceptance criteria coverage
- residual risk

## 2026-06-05 P02 Followup-B S005 Mastery Transition

Test scope:
- TC-P02-FUB-013 backend unit validation for `MasteryTransitionPolicy` promotion threshold, one-level cap, hold conditions, demotion conditions and rule version.
- TC-P02-FUB-014 backend AI guardrail validation for candidate-only explanation parsing, forbidden persistent-field rejection, official-score/goal-completion claim blocking and safe deterministic fallback.
- Integration regression: `GET /goal-autopilot/mastery-transitions`, `mastery_transition` replay audit, governance export, migration and account-deletion cleanup.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest test` - failed first because S005 policy and AI validator classes did not exist; this was the expected red test.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed after S005 governance expectation sync.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,AccountDeletionLearningDataTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest,GoalAutopilotControllerTest test` - passed after independent review fixed non-deterministic replay output hash and added duplicate-input idempotency assertions.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest,GoalAutopilotControllerTest,FoundationMigrationTest,AccountDeletionLearningDataTest test` - passed.
- `npm run check:api-contract` - passed.
- `npm run check:dart-client-drift` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUB-013: promotion advances at most one L0-L5 level even when the candidate target is higher than one step, and records evidence refs plus `fub-mastery-v1`.
- TC-P02-FUB-013: low confidence, insufficient evidence, partial goal, unsupported goal, fatigue protection and contradictory evidence hold at the previous level.
- TC-P02-FUB-013: repeated retrieval failure and checkpoint regression produce deterministic one-level demotion when confidence is sufficient.
- TC-P02-FUB-013 integration: completing accepted plan evidence writes one read-only `goal_mastery_transition_decisions` row and one `mastery_transition` replay audit; repeating the same input does not duplicate transition or replay rows.
- TC-P02-FUB-014: AI candidate explanations containing final mastery, review due date, notification schedule, goal completion, official score or guardrail violations are rejected and do not mutate persistent state.
- TC-P02-FUB-014: a safe candidate-only explanation that echoes the deterministic decision is accepted as explanation text only and still does not mutate persistent state.
- Regression: governance export reports S005 mastery retention/deletion metadata; account deletion purges mastery transition decisions and related replay audits.

Failing or blocked tests:
- No TC-P02-FUB-013/014 failure remains.
- TC-P02-FUB-015..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-007 is executed for evidence-driven L0-L5 transition decisions, one-level promotion cap, hold/demotion behavior, transition audit metadata, AI forbidden persistent-field rejection and no official-score claim.
- AC-P02-FUB-008 remains planned for broader Followup-B global replay/performance/final traceability gates.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- Global replay fixture corpus, p95 performance budgets, coverage/final traceability script and final independent QA remain open under TC-P02-FUB-015..017.
- No Flutter UI changed in this slice; Flutter layer is N/A for TC-P02-FUB-013/014.

## 2026-06-05 P02 Followup-B S004 Item-Level MemoryCurvePolicy

Test scope:
- TC-P02-FUB-011 backend unit validation for `MemoryCurvePolicy` item-level decisions, forgetting-risk thresholds, retrieval success/failure, default intervals, overlearning cap, interleaving cap, daily budget defer and paused/control-blocked decisions.
- TC-P02-FUB-012 backend integration validation for `POST /goal-autopilot/item-policy/decisions`, deterministic response decisions, `item_policy` replay audit hashes and paused-control blocking through server-owned control state.
- Regression scope: existing `GoalAutopilotControllerTest`, S003 `GoalAutopilotRecoveryControllerTest`, OpenAPI/generated Dart drift and API contract gates.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest,MemoryCurveReplayTest test` - failed once because `next_due_at` used sub-day `Instant.now`, causing replay output hash drift; fixed by using day-level policy evaluation time in the input snapshot.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest,MemoryCurveReplayTest test` - passed.
- `npm run check:api-contract` - passed after adding optional `MemoryItemPolicyInput` to the existing item-policy endpoint schema and syncing generated Dart hash artifacts.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest,MemoryCurveReplayTest,GoalAutopilotControllerTest,GoalAutopilotRecoveryControllerTest test` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `git diff --check` - passed.
- Independent review follow-up fixed `review_not_due.next_due_at` so it reflects `last_reviewed_at + default interval` instead of resetting the interval from the evaluation day; `MemoryCurvePolicyTest` now asserts this default-interval output.

Passing tests:
- TC-P02-FUB-011: high forgetting risk `>=0.70` returns `review_due` and overrides overlearning cap; due risk `>=0.45` plus retrieval failure returns `retrieval_failure_due`.
- TC-P02-FUB-011: successful retrieval below due threshold remains `review_not_due`; elapsed default intervals for L0/L1/L2/L3/L4/L5 and not-due `next_due_at` are enforced through rule-versioned decisions.
- TC-P02-FUB-011: overlearning cap returns `skip_overlearning_cap`; interleaving cap returns `interleave_alternative` when a viable different group exists; exhausted daily memory budget returns `defer_budget`.
- TC-P02-FUB-011: paused and policy-blocked control states return `blocked_by_control` instead of selecting review work.
- TC-P02-FUB-012: item-policy API returns deterministic memory item decisions and writes `item_policy` replay audit with `sha256:` input/output/replay hashes, expected decision, reason code and `memory-curve-v1`.
- TC-P02-FUB-012: replaying the same item-policy request on the same evaluation day returns identical decisions and identical replay hash; pausing control causes all item decisions to become `blocked_by_control`.

Failing or blocked tests:
- No TC-P02-FUB-011/012 failure remains.
- TC-P02-FUB-013..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-006 is executed for item-level memory state, forgetting risk, retrieval evidence, overlearning cap, interleaving cap, daily budget defer, default constants, paused/control-blocked handling and replay determinism.
- AC-P02-FUB-008 remains planned for broader Followup-B global replay/performance/final traceability gates.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- L0-L5 transition, global replay fixtures, performance budgets, coverage evidence and the dedicated Followup-B traceability script remain open.
- No Flutter UI or AI runtime behavior changed in this slice; those layers are N/A for TC-P02-FUB-011/012.

## 2026-06-05 P02 Followup-B S003 Missed-Day Recovery Planner

Test scope:
- TC-P02-FUB-009 backend unit validation for `MissedDayRecoveryPlanner` mode precedence, balanced tie-breaker, daily budget cap and no-overdue-stacking decisions.
- TC-P02-FUB-010 backend integration validation for `/goal-autopilot/recovery/replan`, durable `RecoveryPlanDecision`, stale/replan plan updates, idempotent replay, bounded recovery daily plan and `missed_day_recovery` replay audit.
- Regression scope: existing `GoalAutopilotControllerTest`, notification eligibility/outbox lifecycle/replay tests, OpenAPI/generated Dart drift, runner validation, diff check and project coverage script.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MissedDayRecoveryPlannerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotRecoveryControllerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide test` - passed after S003 governance status-marker fix.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MissedDayRecoveryPlannerTest,GoalAutopilotRecoveryControllerTest,GoalAutopilotControllerTest,NotificationEligibilityPolicyTest,NotificationOutboxServiceTest,NotificationOutboxReplayTest test` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository jacoco:report` - failed because the project does not configure a resolvable `jacoco` Maven plugin prefix; this is a tooling gap for report refresh, not a failed TC-P02-FUB-009/010 assertion.

Passing tests:
- TC-P02-FUB-009: hard safety and high fatigue force `replace` before user preference.
- TC-P02-FUB-009: `balanced` resolves deterministically to `defer` before `compress` and `replace` when feasible; specific `compress` and `replace` preferences are honored when viable.
- TC-P02-FUB-009: compress recovery stays within daily minutes and affects only the risk-driving item instead of stacking every overdue item.
- TC-P02-FUB-010: recovery replan from a skipped item returns `defer`, one affected lower-priority item ref, `sha256:` input snapshot, `fub-recovery-v1` rule version and `recovery_replan` signal.
- TC-P02-FUB-010: recovery creates a new bounded daily plan with one active recovery block and leaves old daily/backplan rows stale with the recovery reason code.
- TC-P02-FUB-010: replaying the same idempotency key returns the same recovery decision and daily plan without duplicate replacement plans.
- TC-P02-FUB-010: `goal_recovery_plan_decisions` and `goal_planner_replay_audits` record recovery decision and `missed_day_recovery` replay evidence.
- Regression: control data-governance export reports implementation through S003 recovery and includes the recovery decision retention/deletion table.

Failing or blocked tests:
- No TC-P02-FUB-009/010 failure remains.
- TC-P02-FUB-011..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-005 is executed for missed/skipped/deferred recovery planner behavior, compress/defer/replace decision mode, no overdue stacking, stale/replan status and replayable decision evidence.
- AC-P02-FUB-008 remains planned for broader Followup-B global replay/performance/final traceability gates.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- Item-level memory, L0-L5 transition, global replay fixtures, performance budgets and the dedicated Followup-B traceability script remain open.
- No Flutter UI or AI runtime behavior changed in this slice; those layers are N/A for TC-P02-FUB-009/010.

## 2026-06-05 P02 Followup-B S002-B Notification Outbox Lifecycle And Replay

Test scope:
- TC-P02-FUB-007 backend integration validation for `NotificationOutboxService` lifecycle, dedupe, cancel/reschedule, retry/failure recovery, expiry and sent-state redaction.
- TC-P02-FUB-008 backend integration validation for deterministic `notification_outbox` replay audit hashes and projections.
- Regression scope: outbox/replay list API redacted projection, OpenAPI/generated Dart drift, foundation migration, control governance export, account deletion cleanup and prior notification eligibility policy.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationOutboxServiceTest,NotificationOutboxReplayTest test` - red step failed before implementation with missing outbox service, repository and replay audit classes.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationOutboxServiceTest,NotificationOutboxReplayTest,NotificationEligibilityPolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub007OutboxAndReplayApisExposeRedactedProjection test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed after updating stale S002-A governance expectations.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,AccountDeletionLearningDataTest,TrainingAccountDeletionRetentionTest test` - passed.
- `npm run check:api-contract` - failed once on OpenAPI/example/hash drift, then passed after schema/example/hash sync.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `flutter analyze lib/generated/api/speakeasy_api.dart` - passed.

Passing tests:
- TC-P02-FUB-007: outbox records are created with stable dedupe key `user_id + goal_revision + plan_item_id + reminder_slot + rule_version`, duplicate schedule calls do not create another record, and lifecycle transitions cover `pending`, `scheduled`, `blocked`, `cancelled`, `failed`, `expired` and `sent`.
- TC-P02-FUB-007: cancelled reminders can be rescheduled back to `pending`, failed reminders enter `retry_waiting` and can recover to `scheduled`, and sent records retain only hashed provider/message payload projection.
- TC-P02-FUB-008: replay audit rows are written for outbox state changes with `notification_outbox` decision family, `outbox:<id>` source reference, deterministic input/output/replay hashes and expected decisions.
- API regression: `/goal-autopilot/reminders/outbox` and `/goal-autopilot/replay-audits` expose redacted hash projections and do not return raw reminder explanation payload keys.
- Data governance regression: `goal_notification_outbox_records` and `goal_planner_replay_audits` are listed in retention/deletion policy and are purged during account deletion.

Failing or blocked tests:
- No TC-P02-FUB-007/008 failure remains.
- TC-P02-FUB-009..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-004 is executed for notification outbox lifecycle, redacted projection, replay audit and deletion cleanup.
- AC-P02-FUB-008 remains planned for the broader Followup-B replay/performance/coverage completion gate.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- Missed-day recovery, item-level memory, L0-L5 transition, global replay fixtures, performance budgets, coverage evidence and the dedicated Followup-B traceability script remain open.
- External platform notification delivery/release evidence is not claimed by this local outbox lifecycle slice.

## 2026-06-05 P02 Followup-B S002-A Notification Eligibility Policy

Test scope:
- TC-P02-FUB-005 backend unit validation for `NotificationEligibilityPolicy`.
- TC-P02-FUB-006 Flutter widget validation for server-supplied quiet-hours and notification blocked reason display without sending completion.
- Regression scope: existing `GoalAutopilotControllerTest`, full goal-autopilot Flutter adapter/widget test, OpenAPI contract and generated Dart drift.
- Explicit boundary: no notification scheduler/outbox lifecycle, dedupe, retry, send, cancel or replay implementation was added; those remain TC-P02-FUB-007/008.

Commands run:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationEligibilityPolicyTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart --name "Followup-B shows quiet-hours and notification blocked reasons without treating them as completion"` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed after fixing reason precedence integration and stale-plan expectation.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `npm run check:openapi-contract` - passed.
- `npm run check:dart-client-drift` - passed.

Passing tests:
- TC-P02-FUB-005: policy returns first matching reason in precedence order: `paused`, `blocked_by_policy`, `unsupported_goal`, `partial_goal_limited`, `stale_plan`, `missing_plan`, `consent_missing`, `permission_denied`, `entitlement_blocked`, `quota_exhausted`, `quiet_hours`, `eligible`.
- TC-P02-FUB-005: quiet hours block same-day windows, cross-midnight evening/morning windows and treat start=end as disabled, returning `next_allowed_at` when blocked.
- TC-P02-FUB-006: Flutter renders `quiet_hours`, `permission_denied`, `entitlement_blocked` and `quota_exhausted` server reason codes and does not call `completeAction` for a blocked or unsent reminder.
- Regression: existing Followup-B control tests still pass; goal revision with stale downstream plan now surfaces `stale_plan` instead of collapsing to `missing_plan`.

Failing or blocked tests:
- No TC-P02-FUB-005/006 failure remains.
- TC-P02-FUB-007..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-003 is executed for deterministic eligibility policy and UI reason rendering.
- AC-P02-FUB-004 remains planned for scheduler/outbox lifecycle.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- Scheduler/outbox, missed-day recovery, item-level memory, L0-L5 transition, replay fixtures, performance budgets, coverage evidence and the dedicated Followup-B traceability script remain open.

## 2026-06-05 P02 Followup-B TC-002 Control Governance Closure

Test scope:
- TC-P02-FUB-002 integration validation for current S001 `UserAutopilotControl` data governance.
- Covered behavior: server-side validation, internal governance export snapshot for control records, redacted idempotency/audit metadata, retention rule snapshot and account deletion cleanup for `goal_autopilot_controls` and `goal_autopilot_control_idempotency`.
- Explicit boundary: no notification scheduler/outbox table or external user export API was added in this slice; notification outbox data governance remains TC-P02-FUB-007/008.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide test` - red step failed before implementation with missing `GoalAutopilotService#exportControlDataGovernance(UUID)`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide test` - passed after implementation.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,AccountDeletionLearningDataTest,TrainingAccountDeletionRetentionTest test` - passed.

Passing tests:
- TC-P02-FUB-002: server rejects invalid control updates, persists valid control state, exports control governance metadata with redacted idempotency/audit details, records retention/deletion policy for current control tables and purges control/idempotency records on account deletion.
- Related regression: foundation migration, full `GoalAutopilotControllerTest`, account-deletion learning data and training account deletion retention tests passed.

Failing or blocked tests:
- No TC-P02-FUB-002 failure remains.
- TC-P02-FUB-005..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-001 is executed for server-owned control source, validation, current persisted control data governance and deletion cleanup.
- Notification outbox records are not implemented in S001 and remain covered by AC-P02-FUB-004 / TC-P02-FUB-007/008.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- Scheduler/outbox, missed-day recovery, item-level memory, L0-L5 transition, replay fixtures, performance budgets, coverage evidence and the dedicated Followup-B traceability script remain open.

## 2026-06-05 P02 Followup-B Policy Table Routing Documentation Audit

Test scope:
- Documentation-only routing audit for Followup-B implementation slices P02-FUB-SLICE-001..006.
- Covered policy tables: notification reason precedence, quiet-hours evaluation, outbox lifecycle, recovery mode precedence, item-level memory thresholds/interleaving/intervals, L0-L5 confidence/hold/demotion and replay/performance fixture corpus.
- Covered mapping: AC-P02-FUB-001..008 to TC-P02-FUB-001..017 and fixture IDs FUB-FIX-001..009.

Commands/checks run:
- `git diff --check -- docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/requirements.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/spec.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/acceptance.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/test_cases.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/traceability.md docs/reports/test_report.md docs/reports/quality_report.md` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `npm run check:api-contract` - passed.
- TC enum audit over `test_cases.md` - passed: all `测试层级`, `自动化状态` and `结果状态` values use allowed enums.

Passing checks:
- P02-FUB-SLICE-001..006 now route every Followup-B AC/TC family to fixture IDs.
- FUB-FIX-001..009 now define concrete fixture assertions for control, notification, outbox, recovery, memory, mastery, replay and performance.
- Historical note: this audit kept TC-P02-FUB-002 unresolved while preserving partial validation/deletion-cleanup evidence. That status is superseded by `2026-06-05 P02 Followup-B TC-002 Control Governance Closure` above.

Failing or blocked tests:
- No executable backend, Flutter, AI eval, replay or performance test was run in this documentation-only audit.
- Historical note: TC-P02-FUB-002 was still unresolved during this documentation-only audit; it is now passed for current S001 control data governance.
- TC-P02-FUB-005..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-001..008 remain mapped to stable TC-P02-FUB-001..017.
- Policy-table assertions are routed through existing AC rows and do not create new AC or TC IDs.

Residual risk:
- This audit improves implementation readiness but does not prove runtime behavior.
- Scheduler/outbox, recovery, item-level memory, mastery transition, replay fixtures, performance budgets, coverage evidence and the dedicated Followup-B traceability script remain open.

## 2026-06-04 P02 Followup-B Control Slice Implementation Validation

Test scope:
- Backend UserAutopilotControl source-of-truth, settings update, idempotency, pause/resume, paused next-action suppression, server validation and deletion cleanup subset.
- Flutter Goal Autopilot control binding for server-owned active/paused state and reminder eligibility display.
- Documentation reconciliation for TC script path/method mapping and traceability evidence.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest test` - passed in implementation evidence.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart --name "Followup-B renders server control state and does not override pause or eligibility"` - passed in implementation evidence.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed in implementation evidence.
- `flutter analyze lib/features/goal_autopilot/goal_autopilot_adapter.dart lib/features/goal_autopilot/goal_autopilot_models.dart lib/features/goal_autopilot/goal_autopilot_panel.dart lib/services/api_client.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed in implementation evidence.
- `python3 scripts/project_agent_runner.py validate` - passed in implementation evidence.
- `npm run check:api-contract` - passed in implementation evidence.

Passing tests:
- TC-P02-FUB-001: server-owned control state exists separately from GoalProfile, blocks when missing plan, becomes active after plan generation, and persists settings through goal revision.
- TC-P02-FUB-003: pause/resume is idempotent, paused control suppresses next action and reminder eligibility, and resume re-enables next action through server response.
- TC-P02-FUB-004: Flutter renders paused server state, does not show executable action while paused, sends resume/update-control with Idempotency-Key and does not locally override reminder eligibility.

Partial tests:
- Historical note: TC-P02-FUB-002 originally had only server validation and account-deletion cleanup for `goal_autopilot_controls` and control idempotency in this earlier slice. It is superseded by the 2026-06-05 TC-002 control governance closure above.

Skipped or planned tests:
- TC-P02-FUB-005..017 remain planned, including quiet-hours across midnight, platform permission, entitlement/quota, scheduler/outbox lifecycle, missed-day recovery, item-level memory due decisions, L0-L5 transitions, AI forbidden-field rejection, replay fixtures, performance budgets, coverage evidence and Followup-B traceability script.

Acceptance criteria coverage:
- AC-P02-FUB-001 is executed for the routed control source and current S001 control data-governance scope through TC-P02-FUB-001 and TC-P02-FUB-002.
- AC-P02-FUB-002 is executed through TC-P02-FUB-003 and TC-P02-FUB-004.
- AC-P02-FUB-003 has supporting control-response coverage for paused/consent/missing-plan reason display, but TC-P02-FUB-005 and TC-P02-FUB-006 remain planned.
- AC-P02-FUB-004 through AC-P02-FUB-008 remain planned.

Residual risk:
- Followup-B is partially implemented only. It is not complete, not release-ready and not Product Base-ready.
- Notification outbox governance, scheduler/outbox, recovery, memory/mastery, replay, coverage, performance and final independent QA remain open.

## 2026-06-04 P02 Followup-B Pre-implementation Test Mapping Reconciliation

Test scope:
- Test Case Development reconciliation for `p0-2-followup-b-autopilot-control-planner-memory`.
- Covered mapping: TC-P02-FUB-017 and its release-check path for traceability, coverage and pre-implementation routing.
- This is not Followup-B code implementation, test execution, performance evidence or release approval.

Commands run:
- `ls scripts/check_p0_2_followup_b_traceability.py scripts/check_p0_2_goal_autopilot_coverage.py` - confirmed `scripts/check_p0_2_followup_b_traceability.py` is missing and `scripts/check_p0_2_goal_autopilot_coverage.py` exists.
- Planned pre-implementation equivalent gate for routing: `python3 scripts/project_agent_runner.py validate`, `npm run check:api-contract`, and `git diff --check -- <touched Followup-B docs/contracts/status files>`.

Passing checks:
- AC-P02-FUB-001 through AC-P02-FUB-008 still map to stable TC-P02-FUB-001 through TC-P02-FUB-017.
- TC-P02-FUB-017 now explicitly distinguishes the missing implementation-completion script from the pre-implementation equivalent routing gate.
- No TC-P02-FUB row is marked passed or implemented.

Failing or blocked tests:
- TC-P02-FUB-017 remains planned. `scripts/check_p0_2_followup_b_traceability.py` must be created or replaced by an approved equivalent before Followup-B can be marked implemented or complete.

Skipped or planned tests:
- All Followup-B backend, Flutter, AI eval, replay, performance, coverage and traceability tests remain planned until implementation starts.

Acceptance criteria coverage:
- AC-P02-FUB-008 retains planned release-check coverage through TC-P02-FUB-015, TC-P02-FUB-016 and TC-P02-FUB-017.
- The pre-implementation equivalent gate is allowed only for routing readiness and must not be reported as executed TC evidence.

Residual risk:
- A dedicated Followup-B traceability script still needs to be implemented during the Followup-B coding or QA slice.
- Followup-B cannot be marked implemented, test-passing, release-ready or Product Base-ready until executable tests, coverage, performance evidence, implementation report and quality review are produced.

## 2026-06-04 P02 Followup-A No-goal Explore Mode Implementation Validation

Test scope:
- Followup-A FR-009 local implementation for no active goal empty state, explicit `Set a goal` transition and no-goal Explore/sample drill boundary.
- Covered code: `lib/features/goal_autopilot/goal_autopilot_panel.dart`, `test/features/goal_autopilot/goal_autopilot_adapter_test.dart` and strengthened `scripts/check_p0_2_goal_autopilot_traceability.py`.

Commands run:
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter analyze lib/features/goal_autopilot lib/services/api_client.dart lib/pages/home_page.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- <Followup-A FR-009 changed files>` - passed.
- Followup-A FR-009 touched-file whitespace audit - passed.

Passing tests:
- TC-P02-FUA-014: no active goal renders `No active goal`, `Set a goal`, `Explore practice` and `Try a sample drill`; it does not render GoalProfile form or create a goal by default.
- TC-P02-FUA-015: `Set a goal` opens editable intake and no non-summary goal-autopilot operation runs before valid submit.
- TC-P02-FUA-016: `Explore practice` renders ordinary sample drill feedback, does not call create/generate/complete/checkpoint/forecast/memory goal-autopilot operations and does not show target gap, ETA, achieved-goal, guaranteed or official-score copy.

Failing or blocked tests:
- No Followup-A FR-009 functional, analyzer, coverage or backend regression failure remains.

Skipped or external tests:
- Full Explore Practice content library, recommender and ordinary practice persistence are not Followup-A scope.

Acceptance criteria coverage:
- AC-P02-FUA-009 maps to executed TC-P02-FUA-014, TC-P02-FUA-015 and TC-P02-FUA-016.

Residual risk:
- Followup-B/C/D remain unimplemented and must not be inferred from Followup-A.

## 2026-06-04 P02 Followup-A No-goal Explore Mode Planned Test Audit

Superseded status note: this planned-test audit is superseded by the implementation validation above, where TC-P02-FUA-014..016 passed locally.

Test scope:
- Documentation-only planned test audit for `P02-FUA-FR-009 No-goal Explore Mode`.
- Covered behavior: no active goal empty state, explicit `Set a goal` transition, no default-goal creation, Explore/sample drill isolation from goal-autopilot APIs, ordinary practice/session evidence boundary and prohibited goal claims.

Commands run:
- Followup-A No-goal Explore Mode document audit - passed.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- `git diff --check -- docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening docs/reports/quality_report.md docs/reports/test_report.md scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- Followup-A no-goal touched-file whitespace audit - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing checks:
- AC-P02-FUA-009 maps to TC-P02-FUA-014, TC-P02-FUA-015 and TC-P02-FUA-016.
- P02-FUA-TR-009 maps WP-009 -> FR-009 -> SPEC-009 -> AC-009 -> TC-014..016.
- Test cases explicitly require no GoalProfile, DiagnosticAssessment, ProgressForecast, GoalBackplan, DailyPlan, AutopilotAction or MemoryCurve schedule during no-goal browsing.

Failing or blocked tests:
- No documentation traceability failure remains.
- Historical note from this documentation-only audit: TC-P02-FUA-014, TC-P02-FUA-015 and TC-P02-FUA-016 were blocked until code implementation started. This is superseded by the implementation validation above.

Skipped or planned tests:
- Historical note from this documentation-only audit: Flutter widget/adapter tests for FR-009 were planned but not run because that earlier step intentionally did not change code. This is superseded by the implementation validation above.

Acceptance criteria coverage:
- Historical note from this documentation-only audit: AC-P02-FUA-009 had planned coverage through TC-P02-FUA-014..016. It now has executed coverage in the implementation validation above.
- AC-P02-FUA-001 was narrowed so editable intake is required after explicit `Set a goal` or edit, not as the default no-active-goal browsing state.

Residual risk:
- Historical note from this documentation-only audit: the app still needed implementation work at that time. This is superseded by the implementation validation above.

## 2026-06-04 P02 Followup-A Implementation Validation

Test scope:
- Followup-A local implementation for editable GoalProfile intake, SupportedGoalMatrix pre-plan UI, diagnostic sample capture, candidate-only diagnostic transport, revision/stale visibility, claim guard copy and Followup-A traceability.
- Covered code: `lib/features/goal_autopilot/goal_autopilot_adapter.dart`, `lib/features/goal_autopilot/goal_autopilot_models.dart`, `lib/features/goal_autopilot/goal_autopilot_panel.dart`, `test/features/goal_autopilot/goal_autopilot_adapter_test.dart` and strengthened `scripts/check_p0_2_goal_autopilot_traceability.py`.

Commands run:
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter analyze lib/features/goal_autopilot lib/services/api_client.dart lib/pages/home_page.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed and generated `coverage/lcov.info`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed and regenerated `backend/target/site/jacoco/jacoco.csv`.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.5%.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed after the script was strengthened to include Followup-A docs, code and test names.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUA-001/002: editable GoalProfile form renders, blocks invalid empty diagnostic submission, sends user-entered goal fields and no longer uses default-goal-only production UI.
- TC-P02-FUA-003/004: diagnostic samples filter empty text, preserve stable sample refs and do not send fake `audio_ref`.
- TC-P02-FUA-005/006/007: supported, partial/low-confidence and unsupported states render correctly; unsupported goals fail closed with Edit goal recovery only.
- TC-P02-FUA-008/009: claim guards block official/guaranteed copy; revision/stale state blocks stale Done action and sends force replan recovery.
- TC-P02-FUA-010/012: backend regression and local performance checks still pass; no backend/API/domain code changed for Followup-A.
- TC-P02-FUA-011/013: coverage and strengthened traceability gates pass.

Failing or blocked tests:
- No Followup-A local functional, analyzer, coverage or traceability failure remains.

Skipped or external tests:
- Production audio capture, paid AI diagnostic quality, commercial entitlement/cost telemetry and release rollout are not Followup-A scope.
- Followup-B/C/D behavior remains unimplemented and must not be inferred from Followup-A.

Acceptance criteria coverage:
- AC-P02-FUA-001 through AC-P02-FUA-008 all map to executed TC-P02-FUA evidence in `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/test_cases.md`.

Residual risk:
- Followup-A closes editable intake and diagnostic hardening locally, but does not close pause/resume, notification scheduling, Queue/Wiki propagation, commercial release, paid AI evidence or Product Base approval.

## 2026-06-04 P02 Goal Autopilot Local Implementation Validation - P02-GOAL-AUTOPILOT-LOCAL-IMPLEMENTATION-20260604

Test scope:
- P0.2 local deterministic vertical slice for `GoalProfile`, `DiagnosticAssessment`, `GoalBackplan`, `MemoryCurvePolicy`, `AutopilotTraining`, `ProgressForecast` and `OutcomeCheckpoint`.
- Covered contracts: domain model, OpenAPI/API path registry, candidate AI-runtime schemas and UX screen spec routing.
- Covered code: backend goal-autopilot persistence/service/controller, account deletion cleanup, Flutter API adapter, Home learn-tab goal-autopilot panel and focused widget/adapter tests.

Commands run:
- `npm run check:api-contract` - passed; OpenAPI lint, contract gate and generated Dart drift gate passed with hash `87c9218d93a5be9879e52390a1cd2c92de6fd198938a613bbcfc89ae5e0e4f98`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter analyze lib/features/goal_autopilot lib/services/api_client.dart lib/pages/home_page.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed and generated `backend/target/site/jacoco/jacoco.csv`.
- `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed and generated `coverage/lcov.info`.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter feature line 82.1%.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.

Passing tests:
- Backend integration tests cover goal creation, supported/partial/unsupported goal matrix, diagnostic confidence/claim guard, weakness decomposition, L0-L5 mastery seed, weekly/daily plan generation, memory policy, next-action orchestration, completion recovery signal, unsupported-goal fail-closed behavior, checkpoint-driven forecast update and account deletion purge.
- Backend performance test covers local p95 budgets for goal intake, daily plan, next action and forecast.
- Flutter tests cover API path-registry usage, summary parsing, default goal creation, plan generation, next action, action completion, checkpoint envelope and Home panel start/autopilot rendering.

Failing or blocked tests:
- No functional local P0.2 test failure remains.
- No coverage failure remains for the implemented local slice. Backend changed-code line/branch coverage and Flutter feature line coverage are above 80%. Dart coverage tooling does not emit branch coverage, so Flutter branch coverage is not separately measurable by the local toolchain.

Skipped or external tests:
- Historical note for this earlier local slice: paid AI entitlement/cost telemetry, production notification scheduling, pause/resume endpoint semantics, Queue/Wiki progress-surface propagation, broader checkpoint task library, full adaptive workload tuning and commercial release checks were outside that local slice. Pause/resume endpoint semantics are now partially covered by `P02-FOLLOWUP-B-CONTROL-SLICE-20260604`; the other listed gates remain open.

Acceptance criteria coverage:
- `AC-P02-DIAG-001..007`, `AC-P02-PLAN-001..008` and `AC-P02-AUTO-001..008` now have planned TC mappings plus local executed evidence addenda in their increment test case files.
- Local code/test/coverage traceability is complete for the deterministic vertical slice; release traceability is not complete until the residual product gates above are closed or explicitly re-scoped.

Residual risk:
- The Flutter entry currently provides a compact default goal setup rather than the full editable GoalProfile UI.
- Autopilot user control remains partial: skip/defer and quiet-hour fields exist, and pause/resume endpoints now have a routed Followup-B control-slice implementation; notification scheduler behavior and full Followup-B control completion remain open.
- Goal progress appears on the Home learn tab only; Queue/Wiki propagation remains a future surface obligation.

## 2026-06-04 P02 Downstream Requirements Spec AC TC Traceability Audit

Test scope:
- Documentation-only audit for the three P0.2 increments:
  `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy` and `p0-2-autopilot-progress-checkpoint`.
- Coverage: P02-SI-001 through P02-SI-013, P02-PG-001 through P02-PG-005, all new FR/Spec/AC/TC/Traceability IDs, performance budgets and >=80% code coverage gates.

Commands run:
- `p02-diagnostic-chain` audit - passed.
- `p02-plan-chain` audit - passed.
- `p02-auto-chain` audit - passed.
- `p02-stage-scope-traceability` audit - passed.
- `p02-policy-gate-downstream` audit - passed.
- `p02-ac-tc-trace-prefixes` audit - passed.
- `git diff --check -- <P0.2 downstream docs and reports>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing checks:
- Every P02-SI-001 through P02-SI-013 appears in at least one increment traceability matrix.
- Every P02-PG-001 through P02-PG-005 is represented in downstream increment docs.
- Every P0.2 AC family has planned TC IDs and traceability rows.
- Each increment includes explicit performance budgets and changed-code line/branch coverage >=80% as implementation completion gates.

Failing or blocked tests:
- No documentation traceability failure remains.

Skipped or planned tests:
- All P0.2 functional, performance and coverage tests are planned, not executed. No code was implemented in this documentation batch.

Acceptance criteria coverage:
- `AC-P02-DIAG-001..007`, `AC-P02-PLAN-001..008` and `AC-P02-AUTO-001..008` are mapped to planned TC IDs.

Residual risk:
- This audit proves 100% documentation traceability for planned P0.2 scope. It does not prove runtime behavior, performance, code coverage or release readiness.
- Domain/API/AI/UX contracts, implementation code, CI coverage reports, performance results and executed test evidence remain open gates.

## 2026-06-04 P02 Policy Gate Commercial Product Review Audit

Test scope:
- Documentation-only audit for P0.2 product-engineering and commercial-software policy gates.
- Coverage: P02-PG-001 through P02-PG-005, the seven previously identified P0.2 defects, P0.2 stage entry/exit gates and the three planned increment definitions.

Commands run:
- P02 policy gate ID audit - passed; all P02-PG-001 through P02-PG-005 appear in the stage and applicable increment definitions.
- P02 seven-defect closure audit - passed at planning-gate level; each defect maps to at least one policy gate and an owning downstream artifact obligation.
- `git diff --check -- <P0.2 policy gate docs and reports>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing checks:
- Goal achievement, supported-goal/content coverage, autopilot control/planner feasibility, commercial entitlement/cost and data governance are now explicit implementation gates.
- The three P0.2 increments must carry applicable policy gates into requirements/spec/acceptance/test_cases/traceability before implementation.
- No policy gate claims implementation readiness, release approval or official exam-score certification.

Failing or blocked tests:
- No documentation-gate failure remains.

Skipped or planned tests:
- Functional, API, UX, AI-runtime and data-governance tests remain planned because downstream P0.2 docs and implementation do not exist yet.

Acceptance criteria coverage:
- No new AC was created in this step. P02-PG-001 through P02-PG-005 are upstream gate obligations that future AC/TC must cover.

Residual risk:
- The seven defects are closed only at planning-gate level. They still require downstream FR/Spec/AC/TC/Traceability, domain/API/AI/UX contracts and independent checker review before implementation.

## 2026-06-04 P02 Superseded Memory Artifact Removal Audit

Test scope:
- P0.2 documentation source-of-truth cleanup after goal-driven stage replanning.
- Coverage: stage plan, roadmap, feature registry, development status, new P0.2 increment definitions and report records.

Commands run:
- Superseded artifact slug reference audit across `docs/product` and `docs/reports` - passed with no remaining matches.
- Directory removal check for the old P0.2 memory-planner artifact - passed.
- Active P0.2 increment link audit for `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy` and `p0-2-autopilot-progress-checkpoint` - passed.
- `git diff --check -- <P0.2 supersession docs>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing checks:
- Old artifact links are removed from active product and report documentation.
- P02-SI-001 through P02-SI-013 remain represented in the P0.2 stage plan and route to the three goal-driven planned increments.
- The earlier memory-planner audit is described as superseded historical evidence, not active implementation input.

Failing or blocked tests:
- No documentation cleanup failure remains.

Skipped or planned tests:
- Functional P0.2 tests remain planned because no P0.2 implementation or downstream contracts were created in this cleanup.

Acceptance criteria coverage:
- No new AC was created. This cleanup protects the P0.2 planning gate by removing a superseded implementation entry and preserving stage-scope routing to the new increment definitions.

Residual risk:
- The three new P0.2 increments still need requirements/spec/acceptance/test_cases/traceability and independent checker review before implementation.

## 2026-06-04 P02 Documentation Design And Traceability Audit

Test scope:
- Superseded historical P0.2 memory-planner documentation design.
- Coverage: P02-SI-001 through P02-SI-006, P02-FR-001 through P02-FR-010, P02-SPEC-001 through P02-SPEC-010, AC-P02-001 through AC-P02-010, TC-P02-001 through TC-P02-014 and P02-TR-001 through P02-TR-010.

Commands run:
- P02 documentation ID coverage audit - passed; `missing_ids=[]`, `forbidden_hits=[]`.
- `git diff --check -- <historical P0.2 memory-planner docs>` - passed before supersession.
- `python3 scripts/project_agent_runner.py validate` - passed.
- P02 traceability `rg` audit - passed before supersession.

Passing checks:
- TC-P02-014 documentation traceability audit passed.
- P02-SI-001..006 all have owning increment coverage.
- Every P02-FR maps to a P02-SPEC and at least one AC.
- Every AC-P02-001..010 maps to at least one stable TC-P02 ID.
- Traceability rows explicitly keep Code Evidence and functional Test Evidence as not started/planned.

Failing or blocked tests:
- No documentation traceability failure remains.

Skipped or planned tests:
- TC-P02-001 through TC-P02-013 are planned functional tests and were not run because implementation and P02 domain/API/AI/UX contracts do not exist yet.

Acceptance criteria coverage:
- AC-P02-001 through AC-P02-010 have complete planned TC coverage.
- P02-GAP-001 through P02-GAP-006 remain implementation blockers or contract blockers and are not closed by this documentation audit.

Residual risk:
- This historical audit is not P0.2 implementation evidence, Product Base merge approval or release approval.
- This historical audit is superseded by the goal-driven stage replanning. Active P0.2 implementation remains blocked until the three new increments generate their own requirements/spec/AC/TC/traceability, domain/API/AI/UX contracts, scope guard and executable functional tests.

## 2026-06-04 P01 Product Base Implementation Review And API Drift Sync

Test scope:
- P0.1 `p0-1-expression-automation-training` Product Base implementation review.
- Coverage: `P01-FR-012` through `P01-FR-017`, `P01-SPEC-013` through `P01-SPEC-018`, `AC-P01-014` through `AC-P01-019`, `TC-P01-021` through `TC-P01-031`, plus backend-only frontend regressions `TC-P01-001` through `TC-P01-013`.

Commands run:
- `cd backend && mvn -q -DskipTests compile` - passed.
- `cd backend && mvn -q -Dtest=TrainingSessionControllerTest,TrainingTurnIdempotencyTest,TrainingSessionAuthorizationTest,TrainingEvidenceRuleTraceTest,TrainingAccountDeletionRetentionTest,TrainingContentVersioningTest,TrainingMediaAiPipelineTest,TrainingPlannerReplayTest,TrainingObservabilityTest test` - passed.
- `npm run check:api-contract` - passed after syncing generated Dart drift pins to OpenAPI hash `4880e61f8dae8673c13eb2aff5c66e690de70e67663bae45608f57206502fcbf`.
- `python3 scripts/check_p0_1_training_frontend_source_of_truth.py` - passed.
- `python3 scripts/check_p0_1_training_rollout_readiness.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter analyze lib/config/app_config.dart lib/services/api_client.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - passed.

Passing tests:
- TC-P01-021 through TC-P01-028 remain covered by backend Training tests for server source-of-truth, idempotency, evidence governance, deletion cleanup, versioned content, media/AI, planner replay and observability.
- TC-P01-029 through TC-P01-031 remain covered by Flutter backend-only loop, fallback and backend-disabled entry tests.
- Contract drift is closed by `npm run check:api-contract`.

Failing or blocked tests:
- No local implementation-review failure remains.

Skipped or external tests:
- Real paid AI DashScope full matrix, object storage, production cost dashboard and retention evidence remain outside this P0.1 local Product Base review and are governed by P0 commercial AI gates.

Acceptance criteria coverage:
- AC-P01-014 through AC-P01-019 are covered by TC-P01-021 through TC-P01-031 and traceability rows P01-TR-013 through P01-TR-018.

Residual risk:
- Product Base merge approval, paid AI voice and commercial release remain separate gates.

## 2026-06-03 P01 Training Bounded-Context Naming Migration

Test scope:
- Namespace-only migration from historical `interview_training_*` / `InterviewTraining*` names to the Training bounded-context names.
- Coverage: executable Training production code, Training widget/adapter tests, TC-P01-031 integration, source-of-truth and rollout readiness scripts, active P0.1 docs.

Commands run:
- `python3 scripts/check_p0_1_training_frontend_source_of_truth.py` - passed.
- `python3 scripts/check_p0_1_training_rollout_readiness.py` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - passed.
- `flutter analyze lib/features/training/training_contract.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_view.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_test_helpers.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart scripts/check_ai_eval_cases.dart` - passed.
- `flutter analyze integration_test/p0_1_training_loop_test.dart` - passed.
- `dart run scripts/check_ai_eval_cases.dart` - passed: 7 cases.

Passing checks:
- Production files are under `lib/features/training/`.
- Training tests are under `test/features/training/`.
- Executable code has no `InterviewTraining*`, `interview_training_*`, `features/interview/training_*`, or frontend `TrainingAgent` source-of-truth fallback.
- `scripts/check_ai_eval_cases.dart` imports `training_contract.dart`, not a local agent.
- AI-EVAL-P01-007 now validates invented action-chain/micro-action rejection without reintroducing a Flutter two-scene allowlist; backend Training content mapping owns official scenario/version fail-closed behavior.

Failing or blocked tests:
- No local naming migration failure remains.

Skipped or external tests:
- None for this namespace-only migration.

Acceptance criteria coverage:
- No new FR/AC was introduced. Existing TC-P01 IDs and traceability rows are preserved; only code/test evidence paths changed.

Residual risk:
- Historical report sections may preserve legacy file references as past evidence. Current source-of-truth docs, scripts and executable code use `training_*` names.

## 2026-06-03 P01 Training Backend-Only Frontend Source Of Truth

Test scope:
- P0.1 `p0-1-expression-automation-training` backend-only frontend correction.
- Coverage: `P01-FR-001` through `P01-FR-010`, `P01-FR-012`, `P01-FR-015`, `P01-FR-017`; `P01-SPEC-001` through `P01-SPEC-011`, `P01-SPEC-013`, `P01-SPEC-016`, `P01-SPEC-018`; `AC-P01-001` through `AC-P01-012`, `AC-P01-014`, `AC-P01-017`, `AC-P01-019`; `TC-P01-001` through `TC-P01-013`, `TC-P01-029`, `TC-P01-030`, `TC-P01-031`.

Commands run:
- `python3 scripts/check_p0_1_training_frontend_source_of_truth.py` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - passed after converting TC-P01-031 to a self-contained HomePage/local-session fixture that does not require `API_BASE_URL`.
- `flutter analyze lib/features/training/training_contract.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_view.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_test_helpers.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter analyze integration_test/p0_1_training_loop_test.dart` - passed.
- `dart format lib/features/training/training_contract.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_view.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_test_helpers.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart integration_test/p0_1_training_loop_test.dart` - completed.

Passing tests:
- TC-P01-001: backend session start renders server state, and backend unavailable renders unavailable instead of creating a local session.
- TC-P01-002 through TC-P01-005: Flutter renders backend content/action/hint/planner state and no longer owns action-chain or planner progression.
- TC-P01-006 and TC-P01-007: voice/text controls remain visible, but text fallback submits backend turns only.
- TC-P01-008 through TC-P01-011: feedback, evidence, recoverable failure and recap state are rendered from backend contract/fallback state; Flutter does not create accepted evidence or final mastery.
- TC-P01-012 and TC-P01-013: unsupported local source-of-truth paths are guarded by backend scenario/version mapping and the frontend source-of-truth script.
- TC-P01-029: continue/retry in the loop call backend refresh/hint, not local planner or canned feedback.
- TC-P01-030: missing trusted audio ref produces recoverable text fallback and typed text submits through backend `submitTurn`.
- TC-P01-031: when `ENABLE_BACKEND_TRAINING=false`, the HomePage training entry is blocked with service-unavailable UI and no route/session is created; covered by source-of-truth static guard and direct integration test.

Failing or blocked tests:
- No local Flutter backend-only source-of-truth failure remains.

Skipped or external tests:
- None for the local backend-only frontend source-of-truth gate.

Acceptance criteria coverage:
- AC-P01-014 is covered by TC-P01-001, TC-P01-013, TC-P01-029 and TC-P01-031 at the frontend entry/loop boundary, plus TC-P01-021/022 at the backend boundary.
- AC-P01-017 is covered by TC-P01-006, TC-P01-007, TC-P01-026 and TC-P01-030.
- AC-P01-019 is covered by TC-P01-013, TC-P01-028, TC-P01-029 and TC-P01-031.

Residual risk:
- This packet intentionally removes Flutter local Training state-machine fallback from the production path. Future local demos must be isolated as fixtures/dev tools and must not be wired to the product training entry.
- Paid AI voice, commercial release and external provider/media evidence remain governed by the P0 strict gates.

## 2026-06-03 P01 Training Product Base Production Hardening

Test scope:
- P0.1 `p0-1-expression-automation-training` backend/Flutter production-hardening implementation.
- Coverage: `P01-FR-012` through `P01-FR-017`, `P01-SPEC-013` through `P01-SPEC-018`, `AC-P01-014` through `AC-P01-019`, `TC-P01-021` through `TC-P01-031`.

Commands run:
- `cd backend && mvn -q -DskipTests compile` - passed.
- `cd backend && mvn -q -Dtest=TrainingSessionControllerTest,TrainingTurnIdempotencyTest,TrainingSessionAuthorizationTest,TrainingEvidenceRuleTraceTest,TrainingAccountDeletionRetentionTest,TrainingContentVersioningTest,TrainingMediaAiPipelineTest,TrainingPlannerReplayTest,TrainingObservabilityTest test` - passed.
- `cd backend && mvn -q test` - passed; full backend regression passed after adding Training user-data cascade cleanup semantics.
- `flutter test test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter analyze lib/config/app_config.dart lib/services/api_client.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `python3 scripts/check_p0_1_training_rollout_readiness.py` - passed.
- `npm run check:api-contract` - passed; OpenAPI/Dart drift hash remains `4880e61f8dae8673c13eb2aff5c66e690de70e67663bae45608f57206502fcbf`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `dart format lib/config/app_config.dart lib/services/api_client.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - completed.

Passing tests:
- TC-P01-021: `TrainingSessionControllerTest` verifies backend Training source-of-truth, persisted session state, reviewed action chain mapping and fail-closed unknown official scenario handling.
- TC-P01-022: `TrainingTurnIdempotencyTest` and `TrainingSessionAuthorizationTest` verify turn replay/conflict behavior, no duplicate provider work and owner-scoped access.
- TC-P01-023: `TrainingEvidenceRuleTraceTest` verifies accepted evidence writes LearningEvidence with `training_signal_v1`, reason code and schema version.
- TC-P01-024: `TrainingAccountDeletionRetentionTest` verifies training sessions, turns, planner decisions, evidence candidates, metrics and LearningEvidence are purged on account deletion.
- TC-P01-025: `TrainingContentVersioningTest` and `training_content_mapping_test.dart` verify reviewed scenario-version mapping and Flutter production adapter support for future official scenarios without a two-seed hard-code.
- TC-P01-026: `TrainingMediaAiPipelineTest` and `training_backend_pipeline_test.dart` verify trusted `audio_ref`, ASR, pronunciation scoring, LLM feedback, backend adapter audio upload and evidence candidate mapping.
- TC-P01-027: `TrainingPlannerReplayTest` and `training_planner_replay_test.dart` verify planner audit rows, rule version, no raw transcript in snapshots, backend hint/pressure/replay mapping and recap mapping.
- TC-P01-028: `TrainingObservabilityTest` verifies redacted training metrics for start, turn, planner, evidence and completion.
- Rollout gate: `scripts/check_p0_1_training_rollout_readiness.py` verifies code/test/report/traceability evidence for TC-P01-021 through TC-P01-031.

Failing or blocked tests:
- No local backend/Flutter failure remains for TC-P01-021 through TC-P01-031.

Skipped or external tests:
- Real paid AI DashScope full matrix, real object storage, production cost dashboard and retention evidence are not part of this P0.1 local hardening closure and remain governed by P0 commercial AI gates.

Acceptance criteria coverage:
- AC-P01-014 through AC-P01-019 are covered by TC-P01-021 through TC-P01-031 and traceability rows P01-TR-013 through P01-TR-018.

Residual risk:
- Superseded by 2026-06-04 implementation review: generated Dart OpenAPI drift pins are now synced to current OpenAPI hash `4880e61f8dae8673c13eb2aff5c66e690de70e67663bae45608f57206502fcbf`.
- Production enablement still requires configuration of `ENABLE_BACKEND_TRAINING=true` and the existing P0 paid AI/commercial release evidence gates before paid voice or app-store release claims.

## 2026-06-03 P0.1 Commercial Software Remediation Documentation Gate

Superseded status note: this section records the earlier documentation-only gate. The later `2026-06-03 P01 Training Product Base Production Hardening` section supersedes its planned-test status for TC-P01-021 through TC-P01-028 and records local passed evidence for TC-P01-021 through TC-P01-031.

Test scope:
- P0.1 documentation/design remediation inside `p0-1-expression-automation-training`.
- Coverage: `P01-FR-012` through `P01-FR-017`, `P01-SPEC-013` through `P01-SPEC-018`, `AC-P01-014` through `AC-P01-019`, `TC-P01-021` through `TC-P01-031`, `P01-TR-013` through `P01-TR-018`.

Commands run:
- `rg -n "P01-FR-012|P01-SPEC-013|AC-P01-014|TC-P01-021|P01-TR-013|P01-GAP-009|P01-HARDEN-001|Product Base/production" docs/product/increments/p0-1-expression-automation-training docs/architecture docs/domain docs/product/stages/p0-1-expression-automation.md docs/product/development_status.md docs/release/release_checklist.md` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- <changed docs>` - passed.

Passing tests:
- OpenAPI lint, contract and generated Dart client drift gates passed through `npm run check:api-contract`.
- Documentation traceability search confirms the new P0.1 production-hardening IDs are present across increment docs, architecture/domain docs, stage/development status and release checklist.
- Diff whitespace validation passed for changed documentation files.

Failing or blocked tests:
- No documentation gate failure remains.
- Historical note from this documentation-only gate: at that time TC-P01-021 through TC-P01-028 were planned and not executed. This statement is superseded by the later Product Base Production Hardening section, where TC-P01-021 through TC-P01-031 have local passed evidence.

Skipped or external tests:
- Backend Training controller/service/repository tests, Flutter generated-client wiring tests, media/AI production pipeline tests and rollout/observability checks were not run because this batch changed documentation only and did not implement those systems.

Acceptance criteria coverage:
- AC-P01-014 through AC-P01-019 now map to stable planned TC IDs and traceability rows.
- Existing TC-P01-013/014 local evidence remains valid for local route/AI eval only and does not close the new Product Base/production hardening gate.

Residual risk:
- Historical note from this documentation-only gate: P0.1 could not be promoted until TC-P01-021 through TC-P01-028 passed or blockers were accepted. This planned-test warning is superseded by the later Product Base Production Hardening section; PM approval and Product Base merge review remain separate gates.
- Commercial release and paid AI voice remain controlled by the P0 commercial release and commercial AI provider hardening gates.

## 2026-06-03 P0-AI OSS Storage Implementation

Test scope:
- `commercial-ai-provider-hardening` object storage implementation for `COM-SI-013`.
- AC/TC: `AC-COM-AI-001`; `TC-COM-AI-001`, `TC-COM-AI-002`, `TC-COM-AI-008`.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,AiMediaStorageServiceTest,ProductionAsrMediaRefTest,PersistentTtsCacheTest,AiCostDashboardTest,AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,DashScopeProviderGatewayIntegrationTest,DashScopeProviderGatewayTest,CommercialFoundationControllerTest,AccountDeletionLearningDataTest,FoundationMigrationTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/check_ai_external_release_evidence.py` - passed and reported the four missing paid AI external evidence refs as release blockers.
- `python3 scripts/check_ai_external_release_evidence.py --strict-external` - failed as expected because the four refs are not set.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- `MediaUploadReferenceServiceTest` verifies backend-created upload sessions, upload headers, complete flow and forged `object_ref` rejection.
- `AiMediaStorageServiceTest` verifies Aliyun OSS canonical `oss://bucket/key`, signed upload/read URLs, KMS/SSE upload header handling, object deletion key resolution and local adapter mismatch rejection.
- Existing ASR, TTS cache, cost dashboard, retention/account deletion and DashScope gateway tests still pass after the storage adapter was introduced.
- Full backend test suite passed after locking the test profile to deterministic provider by default and keeping DashScope-specific tests explicit.

Failing or blocked tests:
- No local failure remains for TC-COM-AI-008.
- Strict external release evidence remains blocked until `AI_MEDIA_STORAGE_EVIDENCE_REF` points to reviewed staging/release candidate OSS evidence.

Skipped or external tests:
- Real Aliyun OSS bucket upload, provider read access, URL expiry, lifecycle/delete proof and KMS/ACL review were not executed because no Aliyun account/credentials were provided.

Acceptance criteria coverage:
- `AC-COM-AI-001` now has automated coverage for backend-owned object refs, signed upload/read URL generation and client-forged object_ref rejection.
- Release evidence coverage for the real bucket lifecycle remains governed by `P0-AI-STORAGE-001` and `AI_MEDIA_STORAGE_EVIDENCE_REF`.

Residual risk:
- Local mocked OSS signing does not prove real-region bucket policy, KMS behavior, provider fetchability, expiry enforcement or deletion in staging/release.

## 2026-06-03 P0-AI External Evidence Gate Validation

Test scope:
- `commercial-ai-provider-hardening` paid AI external evidence strategy and release gates.
- Coverage: `COM-SI-013`, `COM-SI-015`, `COM-SI-016`, `COM-SI-017`.
- AC/TC: `AC-COM-AI-001`, `AC-COM-AI-003`, `AC-COM-AI-004`, `AC-COM-AI-005`; `TC-COM-AI-001`, `TC-COM-AI-002`, `TC-COM-AI-004`, `TC-COM-AI-005`, `TC-COM-AI-006`, `TC-COM-AI-007`.

Commands run:
- `python3 scripts/check_ai_external_release_evidence.py` - passed; reported missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`, `AI_MEDIA_STORAGE_EVIDENCE_REF`, `AI_COST_DASHBOARD_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF`.
- `python3 scripts/check_ai_external_release_evidence.py --strict-external` - failed as expected because the four refs are not set.
- `python3 -m py_compile scripts/check_ai_external_release_evidence.py scripts/check_ai_provider_sandbox_evidence.py scripts/check_manual_external_evidence_plan.py` - passed.
- `bash -n scripts/check_release_readiness.sh` - passed.
- `python3 scripts/check_ai_provider_sandbox_evidence.py` - passed; reported missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.
- `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` - failed as expected.
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with dummy external evidence refs and release env - passed; fixture only validates gate wiring.
- `git diff --check` - passed.

Passing tests:
- Paid AI external checklist structure passed in non-strict mode.
- The new gate is wired into aggregate release readiness and accepts non-local external-style fixture refs in env-only validation.
- Existing manual external evidence plan and DashScope matrix structure gate still pass in non-strict mode.

Failing or blocked tests:
- Strict paid AI external evidence gate fails until all four required external refs are supplied.
- Strict DashScope provider evidence gate still fails until `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` is supplied.

Skipped or external tests:
- No real DashScope full matrix, object-storage lifecycle, PM/Ops dashboard evidence, retention/account deletion external proof or independent external reviewer approval was executed in this local environment.

Acceptance criteria coverage:
- `AC-COM-AI-001`, `AC-COM-AI-003`, `AC-COM-AI-004` and `AC-COM-AI-005` now have explicit external release evidence scenarios and strict gate mappings in addition to existing local automated evidence.

Residual risk:
- Paid AI voice remains blocked for real users until the four external evidence refs are populated from reviewed evidence packages and strict gates pass in the release candidate environment.

## 2026-06-03 P0.1 Local Blocker Closure And Commercial External Gate Revalidation

Test scope:
- TC-P01-013 route-level P0.1 training loop integration.
- TC-P01-014 executable P0.1 AI eval validator.
- TC-COM-AI-004 controlled live DashScope evidence preparation.
- TC-COM-012/015/019/021/022 commercial external/native/store/release gates.

Commands run:
- `dart format lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart integration_test/p0_1_training_loop_test.dart lib/features/training/training_agent.dart test/features/training/training_feedback_schema_test.dart scripts/check_ai_eval_cases.dart` - passed.
- `flutter analyze lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart integration_test/p0_1_training_loop_test.dart lib/features/training/training_agent.dart test/features/training/training_feedback_schema_test.dart scripts/check_ai_eval_cases.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - failed due duplicate macOS test/app processes holding the Hive storage lock, not due TC-P01-013 product behavior.
- `./scripts/run_mvp_system_e2e.sh --suite p0-1-training-loop` - passed with isolated backend, HOME and Hive namespace.
- `dart run scripts/check_ai_eval_cases.dart` - passed: 7 P0.1 AI eval cases.
- `flutter test test/features/training/training_feedback_schema_test.dart` - passed.
- `python3 scripts/run_dashscope_sandbox_matrix.py` - passed: report `build/reports/dashscope-sandbox-20260602T223557Z-3359fcc82fafa457.json`, `overall_status=controlled-live-prepared`, strict ref not present.
- `python3 -m py_compile scripts/run_dashscope_sandbox_matrix.py` - passed.
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/check_commercial_copy_contract.py` - passed in non-strict mode; reported missing store/privacy/support evidence refs.
- `python3 scripts/check_provider_sandbox_evidence.py` - passed in non-strict mode; reported missing Apple/Google evidence refs.
- `python3 scripts/check_ai_provider_sandbox_evidence.py` - passed in non-strict mode; reported missing DashScope external evidence ref.
- `python3 scripts/check_store_submission_evidence.py` - passed in non-strict mode; reported missing store/reviewer/privacy/support evidence refs.
- `python3 scripts/check_commercial_copy_contract.py --strict-external` - failed as expected: `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL`, `SUPPORT_URL` missing.
- `python3 scripts/check_provider_sandbox_evidence.py --strict-external` - failed as expected: `APPLE_SANDBOX_EVIDENCE_REF`, `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` missing.
- `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` - failed as expected: `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` missing.
- `python3 scripts/check_store_submission_evidence.py --strict-external` - failed as expected: `STORE_METADATA_EVIDENCE_REF`, `REVIEWER_ACCOUNT_REF`, `PRIVACY_URL`, `SUPPORT_URL` missing.
- `scripts/check_social_login_release_config.sh --env-only` - failed as expected: `WECHAT_APP_ID` and `WECHAT_UNIVERSAL_LINK` missing.
- `scripts/check_social_login_release_config.sh` - failed as expected: WeChat env missing, iOS placeholder WeChat URL scheme remains, Apple Sign In entitlement missing.
- `scripts/check_release_configuration.sh` - failed as expected: release API URL is not HTTPS production config and `ENV` is not `production`.
- `scripts/check_release_readiness.sh --env-only` and `scripts/check_release_readiness.sh` - failed as expected on strict commercial release evidence, signing, Sentry, social/native and release refs.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- Sanitized report search for API key/Bearer/raw URL patterns - passed; no secret or raw provider reference found.

Passing tests:
- TC-P01-013 passed through the isolated system E2E script. It covers homepage entry into the P0.1 training route, ASR failure text fallback, feedback panel, continue/pressure/recap loop, `pending_local_write` evidence status and return to home.
- TC-P01-014 passed through the executable AI eval validator. All seven P0.1 cases validate runtime schema behavior for positive feedback, task failure, pronunciation-unavailable continuation, ASR fallback, pressure prompt gating, prohibited final-state output rejection and unsupported-scene rejection.
- TC-COM-AI-004 controlled live evidence prep passed for LLM/TTS/ASR positive paths and local fallback/cache/reject/error guards with sanitized output.
- Commercial manual plan, copy, provider, AI provider and store submission structure gates pass in non-strict mode.

Failing or blocked tests:
- No local TC-P01-013 or TC-P01-014 blocker remains.
- TC-COM-AI-004 strict release gate remains blocked by missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.
- TC-COM-012 remains blocked by missing WeChat production env, iOS placeholder WeChat URL scheme and missing Apple Sign In entitlement.
- TC-COM-015 remains blocked by missing `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL` and `SUPPORT_URL`.
- TC-COM-019 remains blocked by missing `APPLE_SANDBOX_EVIDENCE_REF` and `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF`.
- TC-COM-021 remains blocked by missing `STORE_METADATA_EVIDENCE_REF`, `REVIEWER_ACCOUNT_REF`, `PRIVACY_URL` and `SUPPORT_URL`.
- TC-COM-022 remains blocked by strict release configuration, Sentry/signing/symbol/rollback refs, provider/store/native evidence refs, privacy/support URLs and production env.

Skipped or external tests:
- Real Apple sandbox, Google Play internal track, WeChat/Apple native social-login smoke, App Store Connect/Play Console metadata, reviewer account, public privacy/support pages, Android signing, symbol upload and rollback rehearsal were not executed locally.
- The DashScope report is a sanitized evidence-prep artifact in `build/reports`; strict release still requires an external evidence package and independent reviewer.

Acceptance criteria coverage:
- P0.1 route integration and AI eval execution evidence now covers TC-P01-013 and TC-P01-014.
- Commercial external gates remain correctly blocked; non-strict structure pass must not be interpreted as release readiness.

Residual risk:
- P0.1 is locally unblocked for TC-P01-013/014, but Product Manager completion still requires final traceability/report acceptance and any remaining P0.1 non-goal decisions.
- Commercial release and paid AI voice remain blocked until external evidence refs are supplied and independently reviewed.

## 2026-06-02 P0/P0.1 Blocker Retest And System E2E Revalidation

Test scope:
- P0.1 expression automation training core tests and backend AI provider adapter boundary.
- P0 commercial subscription readiness backend, Flutter, API contract, evidence-gate and system E2E blockers.
- P0 commercial AI provider hardening evidence gate and controlled DashScope LLM/TTS/ASR probe.
- MVP system E2E suites used as the end-to-end regression surface for product baseline flows.

Commands run:
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_planner_test.dart test/features/training/training_hint_ladder_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_pressure_check_test.dart test/features/training/training_evidence_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_scope_boundary_test.dart` - passed.
- `python3 scripts/check_manual_external_evidence_plan.py && python3 scripts/check_ai_provider_sandbox_evidence.py && python3 scripts/check_provider_sandbox_evidence.py && python3 scripts/check_store_submission_evidence.py && python3 scripts/check_commercial_copy_contract.py` - passed in non-strict mode; reported expected missing external evidence refs.
- `SPEAKEASY_AI_PROVIDER=deterministic DASHSCOPE_API_KEY= JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,ProductionAsrMediaRefTest,PersistentTtsCacheTest,AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,AccountDeletionLearningDataTest,DashScopeProviderGatewayTest,DashScopeProviderGatewayIntegrationTest,ProviderGatewaySecurityContractTest test` - passed.
- `SPEAKEASY_AI_PROVIDER=deterministic DASHSCOPE_API_KEY= JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AppleSubscriptionVerificationTest,GoogleSubscriptionVerificationTest,SubscriptionCredentialValidationTest,SubscriptionRestoreTest,SubscriptionRestoreEmptyTest,EntitlementGateServiceTest,UsageQuotaGateTest,CommercialAccountDeletionProcessorTest,UsageReservationLifecycleTest,CommercialAbuseControlTest,AiCostDashboardTest test` - passed after updating the stale account-deletion audit assertion to count `account_deletion_completed` events.
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart test/features/commercial/entitlement_downgrade_widget_test.dart test/features/commercial/account_deletion_cleanup_test.dart` - passed.
- `flutter test integration_test/commercial_boundary_test.dart` - passed.
- `npm run check:api-contract` - passed: OpenAPI valid, 68 paths, 73 operations, 32 request examples, 68 success examples, 83 error examples, generated Dart drift hash `044c58f6d5d0c4db06e3f07002afca75d38846b9240f9d3313c066e2d2bbba56`.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite smoke` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite scene-catalog` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite learning-memory` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite practice-feedback` - passed after forcing the E2E backend to deterministic provider by default.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite profile-settings` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite membership-boundary` - passed after scrolling explicitly to the restore-purchases button.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite commercial-boundary` - passed.
- Sanitized inline DashScope provider probe using the configured `DASHSCOPE_API_KEY` - passed: LLM `qwen-plus` returned `http=200` with content, TTS `qwen3-tts-flash` returned `http=200` with audio URL present, ASR `paraformer-v2` submit returned `http=200` with task id, ASR poll returned `SUCCEEDED` with result/transcript URL present.

Passing tests:
- TC-P01-001 through TC-P01-012 remain passed on the P0.1 local training-agent core.
- TC-P01-015 through TC-P01-020 remain passed on the backend AI provider adapter/security/usage boundary.
- TC-COM-001 through TC-COM-011, TC-COM-013, TC-COM-014, TC-COM-016 through TC-COM-018, TC-COM-020 and TC-COM-023 remain passed at the implemented local boundary.
- TC-COM-AI-001 through TC-COM-AI-003 and TC-COM-AI-005 through TC-COM-AI-007 remain passed locally.
- TC-COM-AI-004 no longer has an `invalid_api_key` blocker for controlled live sanity; strict release closure still requires `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` and independent external review.

Failing or blocked tests:
- No local automated test remains failing after the E2E script and stale account-deletion assertion fixes.
- Superseded 2026-06-03: TC-P01-013 now passes via `./scripts/run_mvp_system_e2e.sh --suite p0-1-training-loop`.
- Superseded 2026-06-03: TC-P01-014 now passes via `dart run scripts/check_ai_eval_cases.dart`.
- TC-COM-012, TC-COM-015, TC-COM-019, TC-COM-021 and TC-COM-022 remain external/native/store/release blockers.

Skipped or external tests:
- Apple sandbox, Google Play internal track, native social-login, store metadata/reviewer account/privacy/support, signing/symbol upload and rollback evidence were not executed locally.
- Full DashScope evidence matrix review, object-storage lifecycle evidence, production cost dashboard screenshots/alert approval and production retention/privacy evidence refs remain external release gates.

Acceptance criteria coverage:
- Local implementation coverage for P0.1 and P0 commercial automated boundaries remains green.
- Controlled live LLM/TTS/ASR sanity closes the previous credential-validity blocker only; it does not replace the TC-COM-AI-004 strict external evidence requirement.

Residual risk:
- Commercial release remains blocked until strict external/native/store/release evidence refs are supplied and independently reviewed.
- Superseded 2026-06-03: the prior TC-P01-013/014 local blockers are closed; P0.1 completion now depends on PM acceptance of the updated traceability and any explicit non-goal decisions.
- E2E logs still show non-blocking macOS notification initialization and `/user/stats` refresh warnings.

## 2026-06-02 P0-AI External Gate Recheck And TTS Cache Multi-Owner Tests

Test scope:
- Increment `commercial-ai-provider-hardening`.
- Requested five residual-risk gates: DashScope sandbox, object storage media lifecycle, cost dashboard/budget alerts, retention/privacy deletion proof and TTS cache multi-tenant policy.
- Test cases TC-COM-AI-001 through TC-COM-AI-007.

Commands run:
- Earlier same-day sanitized DashScope probe returned `invalid_api_key`; this was superseded by `P0-P01-BLOCKER-RETEST-20260602`, where the configured key produced successful LLM/TTS/ASR controlled live sanity results.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,ProductionAsrMediaRefTest,AiRetentionPolicyTest test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,AccountDeletionLearningDataTest test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiAccountDeletionMediaCleanupTest,AiRetentionPolicyTest,PersistentTtsCacheTest,AiCostDashboardTest,FoundationMigrationTest test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PostgresFoundationMigrationTest test` from `backend/` - passed.

Passing tests:
- TC-COM-AI-001 and TC-COM-AI-002 local backend media upload/ref and ASR guard tests passed.
- TC-COM-AI-005 cost dashboard tests passed for sanitized aggregation, OPS-only access, budget warning and provider anomaly.
- TC-COM-AI-006 and TC-COM-AI-007 retention/account deletion tests passed.
- TC-COM-AI-007 now includes shared TTS cache owner refs: deleting the first owner leaves the shared cache active, clears the legacy first-owner hash and removes that owner ref; deleting the final owner marks the cache entry deleted and removes owner refs.
- PostgreSQL migration validation applied `V202606020001__commercial_ai_tts_cache_owners.sql` successfully.

Failing or blocked tests:
- TC-COM-AI-004 strict release gate remains open because `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` and independent external evidence review are not supplied. The earlier `invalid_api_key` symptom is closed by the later controlled live probe.

Skipped or external tests:
- Real object storage bucket/CDN/KMS upload/read/lifecycle deletion was not executed because no object-storage credentials or evidence ref are configured in the local environment.
- Production PM/Ops dashboard screenshots, threshold approval and alert destination proof were not executed because no production evidence ref is configured.
- Approved privacy/retention policy evidence and real object-store deletion proof were not supplied.

Acceptance criteria coverage:
- AC-COM-AI-001, AC-COM-AI-004 and AC-COM-AI-005 retain local automated evidence.
- AC-COM-AI-002 has stronger local evidence for multi-owner TTS cache deletion semantics.
- AC-COM-AI-003 has controlled live credential sanity for LLM/TTS/ASR, but remains blocked for release until full matrix evidence and `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` are supplied.

Residual risk:
- Paid AI voice release remains blocked by missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`, `AI_MEDIA_STORAGE_EVIDENCE_REF`, `AI_COST_DASHBOARD_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF`.

## 2026-06-01 - P0.1 Backend AI Provider Gateway Test Report

Test scope:
- Increment `docs/product/increments/p0-1-expression-automation-training/`.
- Change request `CR-20260601-001`: keep current Spring Boot backend and add DashScope LLM/TTS/ASR adapter behind `AiProviderGateway`.
- Test cases TC-P01-015 through TC-P01-020.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=DashScopeProviderGatewayTest,DashScopeProviderGatewayIntegrationTest,ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,FeedbackFailureHandlingTest,CommercialAbuseControlTest,UsageQuotaGateTest test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run lint:openapi` - passed.
- `PYTHONPATH=.uv-cache/archive-v0/6TiI4tLkyvVElUd4WZMLn/lib/python3.11/site-packages python3 scripts/check_openapi_contract.py` - passed.
- `PYTHONPATH=.uv-cache/archive-v0/6TiI4tLkyvVElUd4WZMLn/lib/python3.11/site-packages python3 scripts/check_openapi_dart_drift.py` - passed.
- `npm run check:api-contract` - blocked by local `uv run --with PyYAML` runtime panic after OpenAPI lint passed; the same OpenAPI contract and Dart drift scripts passed through the local PyYAML cache path above.

Passing tests:
- TC-P01-015: `DashScopeProviderGatewayTest` verifies DashScope ASR/TTS/LLM model config and adapter routing while deterministic remains the default provider unless `speakeasy.ai.provider=dashscope`.
- TC-P01-016: `DashScopeProviderGatewayTest` and `DashScopeProviderGatewayIntegrationTest` verify local-path ASR is rejected before provider transport in production DashScope mode, unsigned HTTP refs are rejected before provider transport, over-duration signed audio is rejected before provider transport, and valid backend-signed provider-accessible media refs return transcript/status.
- TC-P01-017: `DashScopeProviderGatewayTest` and integration coverage verify TTS cache by text/model/voice avoids duplicate provider calls in the current process.
- TC-P01-018: `DashScopeProviderGatewayTest` and integration coverage verify strict LLM JSON maps to coach feedback, while invalid enum, missing required field, out-of-range score, unsupported extra field and banned final-mastery/entitlement fields fall back to recoverable feedback.
- TC-P01-019: `DashScopeProviderGatewayIntegrationTest`, `CommercialAbuseControlTest`, and `UsageQuotaGateTest` verify current AI REST uses the adapter, usage reservation/commit/release remains active, free/pro/enterprise policy is server-derived from entitlement snapshots, text/audio thresholds differ by tier, client `provider_tier` cannot override server facts, and policy telemetry includes tier/cost metadata.
- TC-P01-020: `ProviderGatewaySecurityContractTest` and `DashScopeProviderGatewayIntegrationTest` verify clients cannot submit `provider_secret` or `provider_tier`, provider responses/telemetry do not expose provider secrets or full learner transcript payloads, and usage audit does not persist full signed audio URLs.

Failing tests:
- None remaining.

Skipped or unavailable tests:
- No live DashScope request was executed; tests use fake DashScope transport and a test API key.
- Backend/object-storage upload lifecycle for ASR media refs is not implemented in this slice; current executable boundary uses backend-signed media metadata and rejects unsigned HTTP refs.
- Persistent TTS media cache and production retention/deletion execution are not implemented in this slice.

Acceptance criteria coverage:
- AC-P01-013 has local automated evidence for DashScope provider selection, adapter replaceability, ASR guard, TTS cache, LLM schema fallback, usage/tier controls, telemetry and no-secret contract.
- AC-P01-013 is partial, not release-complete, until live provider and persistent media-storage evidence are supplied.

Residual risk:
- `P01-GAP-008` is Partial, not Closed.
- Current TTS cache is process-local; restart or multi-instance deployments need persistent cache/object storage before commercial release.
- ASR accepts backend-signed provider-accessible `audio_ref` URLs and rejects unsafe or unsigned refs, but the Flutter upload-to-backend/object-storage lifecycle remains downstream.
- Combined `npm run check:api-contract` currently fails on a local `uv` runtime panic unrelated to OpenAPI content; direct lint, contract and drift subchecks passed.

## 2026-06-01 - P0 Commercial AI Provider Hardening Planning Validation

Test scope:
- Increment `docs/product/increments/commercial-ai-provider-hardening/`.
- Planning coverage for object-storage media upload, persistent TTS cache, real DashScope sandbox evidence, AI cost dashboard and production AI data strategy.
- Test cases TC-COM-AI-001 through TC-COM-AI-007 are created as planned IDs; no implementation tests have executed.

Commands run:
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `python3 scripts/check_provider_sandbox_evidence.py` - passed and reported existing Apple/Google external evidence blockers for TC-COM-019.

Passing checks:
- Manual external evidence checklist remains structurally valid after adding TC-COM-AI-004.
- Project agent validation passed.
- Whitespace/diff check passed.
- Existing payment provider sandbox evidence matrix script still passes in non-strict mode.

Planned tests:
- TC-COM-AI-001: trusted media upload/reference.
- TC-COM-AI-002: production ASR media ref guard.
- TC-COM-AI-003: persistent TTS cache.
- TC-COM-AI-004: DashScope LLM/ASR/TTS sandbox or controlled live evidence.
- TC-COM-AI-005: AI cost dashboard.
- TC-COM-AI-006: AI retention policy.
- TC-COM-AI-007: account deletion media/cache cleanup.

Residual risk:
- All TC-COM-AI implementation and external evidence remains planned/open.
- `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`, `AI_MEDIA_STORAGE_EVIDENCE_REF`, `AI_COST_DASHBOARD_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF` are not supplied.

## 2026-06-01 - P0.1 Training Agent Core Test Report

Test scope:
- Increment `docs/product/increments/p0-1-expression-automation-training/`.
- Training Agent deterministic planner, action chain, micro-action state, hint ladder, pressure check, feedback schema validation, learning evidence candidate filtering, recoverable failures, scope boundary, and lightweight training session widget surface.
- Test cases TC-P01-001 through TC-P01-012.

Commands run:
- `dart format lib/features/training/training_agent.dart lib/features/training/training_session_view.dart test/features/training/training_test_helpers.dart test/features/training/training_entry_test.dart test/features/training/training_planner_test.dart test/features/training/training_hint_ladder_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_pressure_check_test.dart test/features/training/training_evidence_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_scope_boundary_test.dart` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_planner_test.dart test/features/training/training_hint_ladder_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_pressure_check_test.dart test/features/training/training_evidence_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_scope_boundary_test.dart` - first failed on a missing `hintLevel` argument in the recap decision branch; passed after fix.
- Same `flutter test ...training_*.dart` command rerun after independent review corrections for blank scene ids and malformed schema field types - passed.
- `flutter analyze lib/features/training/training_agent.dart lib/features/training/training_session_view.dart test/features/training/training_entry_test.dart test/features/training/training_planner_test.dart test/features/training/training_hint_ladder_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_pressure_check_test.dart test/features/training/training_evidence_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_scope_boundary_test.dart` - passed with no issues.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-P01-001: `training_entry_test.dart` verifies official scene session creation/resume, unsupported-scene rejection, blank scene rejection, and unavailable/ready widget states.
- TC-P01-002, TC-P01-003, TC-P01-004: `training_planner_test.dart` verifies fixed local action chain mapping, one active micro-action, retry/hint decisions, ASR text fallback, and score-unavailable continuation.
- TC-P01-005: `training_hint_ladder_test.dart` verifies hint escalation, lower scaffold after success, and model-then-retry at high support.
- TC-P01-006: `training_voice_flow_test.dart` verifies spoken micro-action controls and playback recovery.
- TC-P01-007: `training_text_fallback_test.dart` verifies ASR fallback and voice-first default behavior.
- TC-P01-008: `training_feedback_schema_test.dart` verifies valid feedback candidates and rejects unsupported scenes, invalid next actions, malformed field types, final mastery writes, billing fields, and unsafe recoverable-error signals.
- TC-P01-009: `training_pressure_check_test.dart` verifies consecutive-success pressure check, pressure pass advancement, and pressure failure retry with higher hint.
- TC-P01-010: `training_evidence_test.dart` verifies recap retention and deterministic filtering of learning evidence candidates.
- TC-P01-011: `training_recoverable_failure_test.dart` verifies recoverable service-failure state and retry/continue exits.
- TC-P01-012: `training_scope_boundary_test.dart` verifies only two official scenes, arbitrary-scene rejection, in-session pressure check, and no final mastery/entitlement fields.

Failing tests:
- None remaining.
- Initial P0.1 test run failed at compile time because the recap decision branch did not pass `hintLevel` into `_decision`; fixed in `lib/features/training/training_agent.dart`.

Skipped or unavailable tests:
- Superseded 2026-06-03: TC-P01-013 integration loop is now implemented as a dedicated P0.1 training route and system E2E suite.
- Superseded 2026-06-03: TC-P01-014 AI eval execution is now covered by `scripts/check_ai_eval_cases.dart` and `tests/ai_runtime/p0_1_ai_eval_cases.json`.
- Live ASR/TTS/LLM/scoring providers were not called; P0.1 tests use deterministic local states and schema fixtures.

Acceptance criteria coverage:
- AC-P01-001 through AC-P01-012 now have executed unit/widget/contract/release-check evidence for the Training Agent core.
- This is not a full P0.1 completion pass because route integration, end-to-end training loop, and document-level AI eval execution remain planned.

Residual risk:
- `training_session_view.dart` is a reusable rendering surface and is not yet connected to the existing `interview_practice_page.dart` production entry.
- The deterministic planner is local-first; no backend sync or repository-backed persistence was added, so API contract P01-GAP-005 remains conditional.
- Full audio capture/transcription provider behavior still depends on existing app services and requires downstream integration tests.

## 2026-05-29 - P0-COM-MANUAL-EVIDENCE-PLAN-001 Manual External Evidence Plan

Test scope:
- TC-COM-012 / AC-COM-009 / COM-TR-005 and COM-TR-012.
- TC-COM-015 / AC-COM-011 / COM-TR-009.
- TC-COM-019 / AC-COM-013 / COM-TR-011.
- TC-COM-021 and TC-COM-022 / AC-COM-014 / COM-TR-012.
- Structure gate for the manual checklist and release readiness integration.

Commands run:
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/check_commercial_copy_contract.py` - passed; reported missing `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL`, and `SUPPORT_URL` as release blockers.
- `python3 scripts/check_provider_sandbox_evidence.py` - passed; reported missing `APPLE_SANDBOX_EVIDENCE_REF` and `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` as release blockers.
- `python3 scripts/check_store_submission_evidence.py` - passed; reported missing `STORE_METADATA_EVIDENCE_REF`, `REVIEWER_ACCOUNT_REF`, `PRIVACY_URL`, and `SUPPORT_URL` as release blockers.
- `python3 -m py_compile scripts/check_manual_external_evidence_plan.py scripts/check_provider_sandbox_evidence.py scripts/check_store_submission_evidence.py scripts/check_commercial_copy_contract.py` - passed.
- `bash -n scripts/check_release_readiness.sh` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, provider/store/reviewer/symbol/rollback evidence refs, privacy URL, support URL, Sentry and Android signing vars - passed.
- Same fixture `scripts/check_release_readiness.sh` in strict mode - failed as expected on native iOS WeChat URL scheme and Apple Sign In entitlement.

Passing tests:
- Manual evidence checklist structure covers TC-COM-012, TC-COM-015, TC-COM-019, TC-COM-021 and TC-COM-022.
- Result template includes execution ID, executor, date, environment, build, account/vault ref, evidence ref, expected result, actual result, blocker reason, reviewer and review result.
- Release readiness now validates the manual evidence plan before copy/provider/store/native/release gates.

Failing tests:
- Strict release readiness fixture still fails on current native iOS social-login blockers, as expected.

Skipped or external tests:
- Real Apple sandbox, Google Play internal test, App Store Connect, Play Console, public privacy/support pages, reviewer account, symbol upload and rollback rehearsal were not executed in this local documentation/gate step.

Acceptance criteria coverage:
- AC-COM-009, AC-COM-011, AC-COM-013 and AC-COM-014 now have detailed manual execution procedures for their remaining external/native blockers.
- This is not a pass result for those ACs; it is a ready-to-execute manual evidence plan.

Residual risk:
- TC-COM-012, TC-COM-015, TC-COM-019, TC-COM-021 and TC-COM-022 remain release blockers until actual results are filled, evidence refs are supplied and independent review approves them.

## 2026-05-26 - PB-P0-BE-001A Backend/DB Foundation Test Report

Test scope:
- Spring Boot backend skeleton and dependency wiring.
- Flyway baseline migration for Product Base and P0 commercial foundation tables.
- Real PostgreSQL 15 migration execution through Testcontainers.
- Minimal P0 commercial API surface already present in `docs/architecture/openapi/speakeasy-api.yaml`: `/subscription/plans`, `/entitlements`, `/usage/summary`, `/user/me`, `/admin/release-health`.
- OpenAPI contract and Dart client pre-generation drift gate.

Commands run:
- `docker version` - passed after Docker Desktop was started; server version 29.0.1.
- `mvn test -Dtest=PostgresFoundationMigrationTest` from `backend/` - first failed with Testcontainers 1.19.8 / Docker Engine 29 compatibility; passed after pinning Testcontainers 2.0.5.
- `mvn test` from `backend/` - passed after dependency download approval, one test cleanup fix, one DTO contract assertion fix, and PostgreSQL Testcontainers addition.
- `npm.cmd run check:api-contract` from repository root - passed.

Passing tests:
- `com.speakeasy.FoundationMigrationTest.pbP0FoundationTablesExist` verifies the migration creates `user_accounts`, `auth_identities`, `user_profiles`, `onboarding_assessments`, `learning_routes`, `scenarios`, `scenario_versions`, `scenario_levels`, `target_expressions`, `subscription_plans`, `purchases`, `subscriptions`, `entitlement_snapshots`, `usage_ledgers`, `usage_reservations`, `payment_provider_events`, `account_deletion_jobs`, and `audit_logs`.
- `com.speakeasy.PostgresFoundationMigrationTest.pbP0FoundationMigrationAppliesOnPostgres` verifies the Flyway baseline applies successfully to PostgreSQL 15.17 and creates the required foundation tables.
- `com.speakeasy.CommercialFoundationControllerTest.listSubscriptionPlansReturnsOpenApiShapedResponse` covers FR-COM-001 and FR-COM-009 response shape for `/subscription/plans`.
- `com.speakeasy.CommercialFoundationControllerTest.getEntitlementsReturnsLatestSnapshot` covers FR-COM-001, FR-COM-006, and FR-COM-007 foundation response shape for `/entitlements`, including explicit `features` and `generated_at` DTO fields.
- `com.speakeasy.CommercialFoundationControllerTest.getUsageSummaryReturnsLedger` covers FR-COM-010 / AC-COM-012 foundation response shape for `/usage/summary`.
- `com.speakeasy.CommercialFoundationControllerTest.requestAccountDeletionCreatesJob` covers FR-COM-008 / AC-COM-010 foundation behavior for `DELETE /user/me`, including the OpenAPI top-level `deletion_job_id`, `status`, and `requested_at` fields.
- `com.speakeasy.CommercialFoundationControllerTest.releaseHealthRemainsWarningUntilProviderAndReleaseGatesExist` covers FR-COM-011 and FR-COM-012 release-health warning behavior for unfinished provider/release gates.
- `npm.cmd run check:api-contract` passed Redocly lint, OpenAPI contract examples, and Dart client pre-generation drift gate.

Failing tests:
- None remaining.
- During implementation, the first real `mvn test` run failed because `CommercialFoundationControllerTest` deleted `user_accounts` before `account_deletion_jobs`. The test setup now deletes deletion jobs first.
- During DTO contract hardening, one test still asserted the old nested `deletion_job.status` shape. The test now asserts the OpenAPI top-level account deletion response shape.
- During PostgreSQL validation, the first Testcontainers run failed because Spring Boot dependency management selected Testcontainers 1.19.8, which did not connect cleanly to Docker Engine 29. The backend now pins Testcontainers 2.0.5 modules.

Skipped or unavailable tests:
- Provider verification tests for Apple/Google purchase validation, restore, webhooks, refund/expiry, and production secrets are not part of PB-P0-BE-001A.
- Flutter/generated Dart client integration tests are not part of PB-P0-BE-001A.

Acceptance criteria coverage:
- Product Base FR-001, FR-002, FR-003, FR-005, FR-006, FR-008, FR-010 are covered at foundation persistence level through migration table assertions; user-facing Product Base flows remain covered by existing Flutter evidence in Product Base traceability.
- FR-COM-001 / AC-COM-001, AC-COM-005, AC-COM-006 are partially covered by subscription/entitlement persistence and read endpoints; real purchase verification and refresh remain follow-up.
- FR-COM-006 / AC-COM-006 and FR-COM-007 / AC-COM-007 are covered only as entitlement snapshot/read foundation, not full gating enforcement.
- FR-COM-008 / AC-COM-010 is covered by deletion job creation foundation, not full cloud data deletion/anonymization execution.
- FR-COM-010 / AC-COM-012 is covered by usage ledger read foundation, not reserve/commit/release enforcement.
- FR-COM-011 / AC-COM-013 and FR-COM-012 / AC-COM-014 are covered by release-health warning behavior, not final release checklist approval.

Residual risk:
- This is a backend/database foundation slice. It is suitable as the next dependency layer, but not sufficient for production commercial launch.
- Auth, authorization, provider secrets, payment provider calls, webhook signature verification, generated Dart client wiring, and Flutter membership/entitlement UI integration remain downstream work.

## 2026-05-27 - PB-P0-BE-001B Auth/Security + User Identity Boundary Test Report

Test scope:
- Spring Security stateless bearer-token baseline.
- Opaque access/refresh session persistence through `auth_sessions`.
- Minimal `/auth/login/phone`, `/auth/login/apple`, `/auth/login/wechat`, `/auth/refresh`, and `/auth/logout` behavior.
- `GET/PATCH/DELETE /user/me` current-user binding.
- `/entitlements` and `/usage/summary` authenticated-user binding and removal of production `X-User-Id` reliance.
- H2 and PostgreSQL migration validation for the new auth session table.
- OpenAPI contract and Dart client pre-generation drift gate.

Commands run:
- `mvn.cmd -q "-Dtest=AuthServiceTest,AuthControllerTest,CommercialFoundationControllerTest,FoundationMigrationTest" test` from `backend/` - first failed because one seeded test token used a fixed 2026-05-26 timestamp and was expired on 2026-05-27; passed after the fixture used current time.
- `mvn.cmd test` from `backend/` - passed after QA gap fixes, 19 tests, 0 failures, 0 errors.
- `npm.cmd run check:api-contract` from repository root - passed.

Passing tests:
- `com.speakeasy.AuthControllerTest.getMeRequiresBearerToken` verifies protected current-user API returns `UNAUTHENTICATED` without bearer auth.
- `com.speakeasy.AuthControllerTest.patchAndDeleteMeRequireBearerToken` verifies `PATCH /user/me` and `DELETE /user/me` reject unauthenticated requests with shared error schema.
- `com.speakeasy.AuthControllerTest.loginAndGetMeBindToCurrentUser` verifies phone login issues tokens and `GET /user/me` uses the token user while ignoring `X-User-Id`.
- `com.speakeasy.AuthControllerTest.patchMeUpdatesAuthenticatedUserProfile` verifies authenticated `PATCH /user/me` updates display name, level, daily minutes, and reminder fields.
- `com.speakeasy.AuthControllerTest.refreshRotatesTokenAndLogoutRevokesSession` verifies refresh rotation invalidates the previous access token, the new token works, logout returns 204, and the logged-out token is rejected.
- `com.speakeasy.AuthControllerTest.refreshRejectsInvalidToken` verifies invalid refresh tokens return `UNAUTHENTICATED`.
- `com.speakeasy.AuthControllerTest.loginRejectsUnsupportedSchemaVersion` verifies runtime request validation rejects unsupported `schema_version` values.
- `com.speakeasy.AuthServiceTest.loginCreatesRefreshableSessionBoundToUser` verifies service-level login, token authentication, refresh rotation, and old access token invalidation.
- `com.speakeasy.AuthServiceTest.logoutRevokesCurrentSession` verifies service-level logout revokes access.
- `com.speakeasy.AuthServiceTest.loginRejectsMissingTerms` verifies terms gating in the login substitute.
- `com.speakeasy.CommercialFoundationControllerTest.getEntitlementsReturnsLatestSnapshot` verifies entitlement lookup uses authenticated user identity and ignores `X-User-Id`.
- `com.speakeasy.CommercialFoundationControllerTest.getUsageSummaryReturnsLedger` verifies usage summary lookup uses authenticated user identity.
- `com.speakeasy.CommercialFoundationControllerTest.requestAccountDeletionCreatesJob` verifies authenticated account deletion creates a job.
- `com.speakeasy.CommercialFoundationControllerTest.entitlementSummaryRequiresAuthentication` verifies unauthenticated entitlement access is rejected.
- `com.speakeasy.CommercialFoundationControllerTest.usageSummaryRequiresAuthentication` verifies unauthenticated usage summary access is rejected.
- `com.speakeasy.FoundationMigrationTest.pbP0FoundationTablesExist` verifies H2 migration includes `auth_sessions`.
- `com.speakeasy.PostgresFoundationMigrationTest.pbP0FoundationMigrationAppliesOnPostgres` verifies Flyway migrations, including `auth_sessions`, apply to PostgreSQL 15.17 through Testcontainers.

Failing tests:
- None remaining.

Skipped or unavailable tests:
- Real Apple/WeChat login provider verification is not implemented in this slice.
- Apple/Google subscription verify/restore, webhooks, refund/expiry downgrade, usage reserve/commit/release, generated Dart client, and Flutter integration are outside PB-P0-BE-001B.

Acceptance criteria coverage:
- Product Base FR-001 / Flow-002 is covered for server-side login/session/logout baseline, not real social-provider verification.
- Product Base FR-010 / AC-011 is covered for authenticated current-user profile read/update and account deletion job creation/session revocation.
- P0 FR-COM-004 / AC-COM-008 is covered for removing production `X-User-Id` identity substitution from protected backend paths.
- P0 FR-COM-001, FR-COM-006, FR-COM-007 are covered for authenticated entitlement read foundation, not full entitlement refresh/gating.
- P0 FR-COM-010 / AC-COM-012 is covered for authenticated usage summary read foundation, not reserve/commit/release.

Residual risk:
- This slice is an auth/security boundary baseline, not production social login or payment verification.
- Full account deletion processing and commercial release health gates remain downstream.

## 2026-05-29 - mvp-backend-foundation-auth Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-foundation-auth/`.
- Stage Scope Items MVP-SI-001 and MVP-SI-002.
- Acceptance criteria AC-MVP-BE-001 and AC-MVP-BE-002.
- Test cases TC-MVP-BE-001 through TC-MVP-BE-006.
- Backend foundation migrations, OpenAPI-shaped success DTOs, shared error schema, auth/current-user behavior, session lifecycle, OpenAPI contract gate, Dart pre-client drift gate, and Flutter auth service compatibility.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest,FoundationResponseContractTest,FoundationErrorContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest" test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: OpenAPI lint, OpenAPI contract gate, and Dart pre-client drift gate.
- `flutter test test/services/auth_service_test.dart` from repository root - passed.

Passing tests:
- TC-MVP-BE-001: `FoundationMigrationTest` and `PostgresFoundationMigrationTest` verify H2 and PostgreSQL-compatible Flyway migrations create the foundation/auth schema.
- TC-MVP-BE-002: `FoundationResponseContractTest` verifies auth, current-user, and subscription-plan responses do not expose raw persistence fields.
- TC-MVP-BE-003: `FoundationErrorContractTest` verifies validation, malformed JSON, and unauthenticated errors use stable shared error contracts and do not expose stack traces.
- TC-MVP-BE-004: `AuthControllerTest` and `AuthServiceTest` verify login, refresh, logout, and current-user/profile behavior.
- TC-MVP-BE-005: `AuthSessionLifecycleTest` verifies expired access rejection, expired refresh rejection, token rotation, and user-wide session revocation.
- TC-MVP-BE-006: `npm run check:api-contract` and `flutter test test/services/auth_service_test.dart` verify OpenAPI/Dart-safe drift and Flutter auth service compatibility.

Failing tests:
- None remaining.

Skipped or unavailable tests:
- None in this machine's final validation path.
- `PostgresFoundationMigrationTest` is designed to skip only when neither Docker nor local PostgreSQL binaries are available; this machine used the local PostgreSQL fallback successfully.

Acceptance criteria coverage:
- AC-MVP-BE-001 is fully covered by TC-MVP-BE-001, TC-MVP-BE-002, and TC-MVP-BE-003.
- AC-MVP-BE-002 is fully covered by TC-MVP-BE-004, TC-MVP-BE-005, and TC-MVP-BE-006.
- Increment traceability rows MVP-BE-TR-001 and MVP-BE-TR-002 cite the same TC IDs, script paths, execution commands, result status, and this report.

Residual risk:
- This pass covers only `mvp-backend-foundation-auth`. It is not a pass for onboarding/content, practice/AI, learning/memory, generated client integration, or commercial subscription expansion.
- Real provider verification for Apple/WeChat remains out of scope for this increment.

## 2026-05-29 - mvp-backend-onboarding-content Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-onboarding-content/`.
- Stage Scope Items MVP-SI-003, MVP-SI-004, and MVP-SI-005.
- Acceptance criteria AC-MVP-BE-003, AC-MVP-BE-004, and AC-MVP-BE-005.
- Test cases TC-MVP-BE-007 through TC-MVP-BE-015.
- Onboarding assessment validation, learning route mapping, official scenario catalog/detail/level content, content seed/versioning, user scenario join/remove/current state, home summary, OpenAPI contract gate, Dart pre-client drift gate, full backend regression, and Flutter coordinator compatibility.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=OnboardingAssessmentControllerTest,LearningRouteMappingTest,OnboardingRouteResponseContractTest,ScenarioCatalogControllerTest,ScenarioContentControllerTest,ScenarioSeedVersioningTest,UserScenarioStateControllerTest,HomeSummaryControllerTest" test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: 50 paths, 55 operations, 28 request examples, 51 success examples, 61 error examples; Dart pre-client drift hash `d763f44d29ac60f85d953cf302db63f23acba77d711cdb86432e1489f6f284d9`.
- `flutter test test/application/home_cards_coordinator_test.dart test/application/scene_setup_coordinator_test.dart` from repository root - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-MVP-BE-007: `OnboardingAssessmentControllerTest` verifies missing goal, expression blocker, or output level fails validation.
- TC-MVP-BE-008: `LearningRouteMappingTest` verifies English interview maps to `job_interview`, onboarding/work communication maps to `onboarding_introduction`, and daily service creates no playable official scenario.
- TC-MVP-BE-009: `OnboardingRouteResponseContractTest` verifies completed assessment responses include OpenAPI-shaped assessment, learning route, and current scenario state fields.
- TC-MVP-BE-010: `ScenarioCatalogControllerTest` verifies the catalog exposes only the two Product Base official scenarios.
- TC-MVP-BE-011: `ScenarioContentControllerTest` verifies scenario detail and L1/L2/L3 level content, including deterministic errors for invalid level requests.
- TC-MVP-BE-012: `ScenarioSeedVersioningTest` verifies seeded content is readable and no Product Base out-of-scope scenario is introduced.
- TC-MVP-BE-013: `UserScenarioStateControllerTest` verifies join, remove, set-current, and level-change behavior update backend state and downstream summary inputs.
- TC-MVP-BE-014: `HomeSummaryControllerTest` verifies no-scenario and missing-review/weakness/session states return explicit default values.
- TC-MVP-BE-015: `home_cards_coordinator_test.dart` and `scene_setup_coordinator_test.dart` verify current Flutter home/scene coordinators remain compatible with backend-shaped service state.

Failing tests:
- None remaining.
- During implementation, the first full backend regression failed because older auth/foundation/commercial test cleanup deleted `user_accounts` before new onboarding child rows. The cleanup order is now shared/updated and the full backend suite passes.

Skipped or unavailable tests:
- Generated Dart client compilation and real Flutter API wiring are not part of this increment; the API gate remains in pre-client generation mode.
- Practice/AI session runtime, memory/weakness/review derivation, commercial membership, and release checks are outside this increment.

Acceptance criteria coverage:
- AC-MVP-BE-003 is fully covered by TC-MVP-BE-007, TC-MVP-BE-008, and TC-MVP-BE-009.
- AC-MVP-BE-004 is fully covered by TC-MVP-BE-010, TC-MVP-BE-011, and TC-MVP-BE-012.
- AC-MVP-BE-005 is fully covered by TC-MVP-BE-013, TC-MVP-BE-014, and TC-MVP-BE-015.
- `docs/product/increments/mvp-backend-onboarding-content/traceability.md` cites the same TC IDs, script paths, execution commands, result status, and this report.

Residual risk:
- This pass covers only `mvp-backend-onboarding-content`. It is not a pass for practice/AI, learning/memory, commercial membership, generated client integration, or release.
- Home summary default review/weakness/session fields are placeholders until later increments provide those data sources.

## 2026-05-29 - mvp-backend-practice-ai Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-practice-ai/`.
- Stage Scope Items MVP-SI-006, MVP-SI-008, and MVP-SI-009.
- Acceptance criteria AC-MVP-BE-006, AC-MVP-BE-008, and AC-MVP-BE-009.
- Test cases TC-MVP-BE-016 through TC-MVP-BE-025.
- Provider gateway secret boundary, ASR/TTS/pronunciation/coach success and fallback behavior, session lifecycle, turn idempotency, completion summary, recoverable errors, score signal source/availability, OpenAPI contract gate, Dart pre-client drift gate, and full backend regression.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,ProviderGatewayAuthorizationTest,PracticeSessionLifecycleTest,PracticeTurnControllerTest,PracticeSessionCompletionTest,PracticeSessionRecoveryTest,CoachFeedbackContractTest,FeedbackFailureHandlingTest" test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: 50 paths, 55 operations, 28 request examples, 51 success examples, 61 error examples; Dart pre-client drift hash `e81fb612e399777241c2ab6cd2d965f972e9762cf76aaea76c94b5f71f18259c`.

Passing tests:
- TC-MVP-BE-016: `ProviderGatewaySecurityContractTest` verifies clients cannot submit `provider_secret` and server-side gateway works without client secrets.
- TC-MVP-BE-017: `ProviderGatewayControllerTest` verifies normalized ASR, TTS, pronunciation, and coach gateway success responses.
- TC-MVP-BE-018: `ProviderGatewayFailureTest` verifies invalid schema and unavailable transcription return fallback/recoverable results without pseudo success evidence.
- TC-MVP-BE-019: `ProviderGatewayAuthorizationTest` verifies unauthenticated requests and session mismatch do not invoke the provider adapter.
- TC-MVP-BE-020: `PracticeSessionLifecycleTest` verifies start/resume/get behavior and explicit new-session creation when resume is disabled.
- TC-MVP-BE-021: `PracticeTurnControllerTest` verifies valid turn persistence, feedback, session fetch, evidence candidate, and idempotent replay/conflict handling.
- TC-MVP-BE-022: `PracticeSessionCompletionTest` verifies complete returns summary payload and candidate input for learning-memory.
- TC-MVP-BE-023: `PracticeSessionRecoveryTest` verifies recoverable sessions resume and completed sessions are not returned as active recovery.
- TC-MVP-BE-024: `CoachFeedbackContractTest` verifies structured coach feedback, score signal source/availability, candidate-only evidence, and no mastery decision.
- TC-MVP-BE-025: `FeedbackFailureHandlingTest` verifies playback/TTS failure is typed and invalid provider output is not visible as successful feedback.

Failing tests:
- None remaining.

Skipped or unavailable tests:
- Real external provider integration tests are not part of this increment; the adapter is deterministic for contract and lifecycle validation.
- Learning-memory accepted evidence, commercial usage reservation, generated Dart client compilation, and release checks are outside this increment.

Acceptance criteria coverage:
- AC-MVP-BE-006 is fully covered by TC-MVP-BE-016, TC-MVP-BE-017, TC-MVP-BE-018, and TC-MVP-BE-019.
- AC-MVP-BE-008 is fully covered by TC-MVP-BE-020, TC-MVP-BE-021, TC-MVP-BE-022, and TC-MVP-BE-023.
- AC-MVP-BE-009 is fully covered by TC-MVP-BE-024 and TC-MVP-BE-025.
- `docs/product/increments/mvp-backend-practice-ai/traceability.md` cites the same TC IDs, script paths, execution commands, result status, and this report.

Residual risk:
- This pass covers only `mvp-backend-practice-ai`. It is not a pass for learning/memory, commercial membership, generated client integration, or release.
- Real provider credentials, production retries, usage reservation accounting, and provider event audit hardening remain later slices.

## 2026-05-29 - mvp-backend-learning-memory Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-learning-memory/`.
- Stage Scope Items MVP-SI-007 and MVP-SI-010.
- Acceptance criteria AC-MVP-BE-007 and AC-MVP-BE-010.
- Test cases TC-MVP-BE-026 through TC-MVP-BE-032.
- Expression queue, queue ordering/dedupe, task completion progress, favorite idempotency/delete, evidence validation, mastery/review/wiki/history projections, OpenAPI contract gate, Dart pre-client drift gate, and full backend regression.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: 55 paths, 60 operations, 29 request examples, 55 success examples, 67 error examples; Dart pre-client drift hash `d677224d822630f0ca30bdcdd55b8c0793b778b7e8e8a65dbfa58f38be15886e`.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-MVP-BE-026: `ExpressionQueueControllerTest` verifies users without joined scenarios receive explicit `empty_no_scene` state and no queue items.
- TC-MVP-BE-027: `ExpressionQueueOrderingTest` verifies evidence-derived queue items outrank variants and stable target expression IDs are deduped.
- TC-MVP-BE-028: `ExpressionTaskProgressTest` verifies task completion persists attempt, evidence, progress, and mastery linkage.
- TC-MVP-BE-029: `FavoriteExpressionControllerTest` verifies duplicate favorite requests return the same favorite ID and delete removes the active favorite.
- TC-MVP-BE-030: `LearningEvidenceValidationTest` verifies low-confidence candidate evidence is rejected and does not update mastery.
- TC-MVP-BE-031: `LearningEvidenceProjectionTest` verifies accepted evidence projects into evidence list, mastery, review, personal wiki, history, and follow-up queue priority.
- TC-MVP-BE-032: `LearningHistoryWikiControllerTest` verifies wiki/history reflect accepted evidence and history deletion hides the history entry.

Failing tests:
- None remaining.
- During full-suite regression, an initial run exposed a delete-order issue between `learning_evidences` and evidence projection tables. The migration now uses `ON DELETE SET NULL` for derived evidence references, and the full backend suite passes.

Skipped or unavailable tests:
- Generated Dart client compilation and production Flutter service wiring are outside this increment; the API gate remains in pre-client generation mode.
- P0.2 cross-day review planning, full L0-L5 mastery ladder, commercial membership, and release checks are outside this increment.

Acceptance criteria coverage:
- AC-MVP-BE-007 is fully covered by TC-MVP-BE-026, TC-MVP-BE-027, TC-MVP-BE-028, and TC-MVP-BE-029.
- AC-MVP-BE-010 is fully covered by TC-MVP-BE-030, TC-MVP-BE-031, and TC-MVP-BE-032.
- `docs/product/increments/mvp-backend-learning-memory/traceability.md` cites the same TC IDs, script paths, execution commands, result status, and this report.

Residual risk:
- This pass covers only `mvp-backend-learning-memory`. It is not a pass for commercial membership, generated client integration, or release.
- Review scheduling remains MVP immediate-due behavior until the deferred long-term planner increment is opened.

## 2026-05-29 - mvp-backend-membership-boundary Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-membership-boundary/`.
- Stage Scope Items MVP-SI-011 and MVP-SI-012.
- Acceptance criteria AC-MVP-BE-011 and AC-MVP-BE-012.
- Test cases TC-MVP-BE-033 through TC-MVP-BE-038.
- Account deletion completion/status, session invalidation, Product Base learning/practice/profile cleanup, deletion failure audit visibility, MVP membership boundary, Android billing platform limit, report/offline/achievement placeholders, OpenAPI contract gate, Dart pre-client drift gate, and full backend regression.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples; Dart pre-client drift hash `506282ac758a37269df95e12ca6752de9c201eb162fd4cc0e227b13c287ab082`.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-MVP-BE-033: `AccountDeletionControllerTest` verifies authenticated account deletion completes a deletion job and returns completed state.
- TC-MVP-BE-034: `AccountDeletionSessionInvalidationTest` verifies previous access and refresh tokens fail after account deletion.
- TC-MVP-BE-035: `AccountDeletionLearningDataTest` verifies Product Base learning/practice/profile state is cleared, user status becomes `deleted`, and audit evidence is written.
- TC-MVP-BE-036: `AccountDeletionFailureAuditTest` verifies failed deletion job status exposes `failure_reason` and keeps audit evidence visible.
- TC-MVP-BE-037: `MvpMembershipBoundaryControllerTest` verifies membership boundary state and Android purchase/restore platform-limited responses.
- TC-MVP-BE-038: `MvpReportPlaceholderControllerTest` verifies learning report, offline content, and achievement endpoints return explicit placeholder states.

Failing tests:
- None remaining.

Skipped or unavailable tests:
- Real Android/iOS payment provider verification, webhook/refund/expiry, paid report generation, offline content package download, and achievement engine tests are outside this MVP boundary increment.
- Generated Dart client compilation and production Flutter service wiring remain the next client/QA/release increment; the API gate remains in pre-client generation mode.

Acceptance criteria coverage:
- AC-MVP-BE-011 is fully covered by TC-MVP-BE-033, TC-MVP-BE-034, TC-MVP-BE-035, and TC-MVP-BE-036.
- AC-MVP-BE-012 is fully covered by TC-MVP-BE-037 and TC-MVP-BE-038.
- `docs/product/increments/mvp-backend-membership-boundary/traceability.md` cites the same TC IDs, script paths, execution commands, result status, and this report.

Residual risk:
- This pass covers only `mvp-backend-membership-boundary`. It is not a pass for generated Dart client integration or release readiness.
- Production deletion of external object-store raw media/transcript refs and full retention operations remain separate DevOps/Security work.

## 2026-05-29 - mvp-backend-client-qa-release Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-client-qa-release/`.
- Stage Scope Items MVP-SI-013 and MVP-SI-014.
- Acceptance criteria AC-MVP-BE-013 and AC-MVP-BE-014.
- Test cases TC-MVP-BE-039 through TC-MVP-BE-046.
- OpenAPI lint/contract, generated Dart drift, handwritten ApiClient exception tracking, Flutter active API drift tests, full backend regression, full Flutter regression, release checklist, version log, rollback plan, and stage traceability.

Commands run:
- `npm run check:api-contract` from repository root - passed: OpenAPI contract gate passed with 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples; Dart client drift gate passed in `generated_client_drift` mode with hash `506282ac758a37269df95e12ca6752de9c201eb162fd4cc0e227b13c287ab082`.
- `flutter test test/services/api_client_contract_test.dart test/services/auth_service_test.dart test/application/scene_voice_session_lifecycle_coordinator_test.dart test/application/home_cards_coordinator_test.dart` - passed.
- `rg -n "MVP-SI-" docs/product/stages/mvp-backend-foundation.md docs/product/increments/mvp-backend-*` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `flutter test` - passed, 173 tests.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-MVP-BE-039: `npm run check:api-contract` verifies OpenAPI lint, operation/request/response examples, traceability, and error response coverage.
- TC-MVP-BE-040: `scripts/check_openapi_dart_drift.py` verifies generated-client mode, `.openapi-sha256`, generated path coverage, Dart-safe operation/schema names, and handwritten ApiClient exceptions.
- TC-MVP-BE-041: `api_client_contract_test.dart`, `auth_service_test.dart`, `scene_voice_session_lifecycle_coordinator_test.dart`, and `home_cards_coordinator_test.dart` verify active Flutter API drift boundary and current active-flow compatibility.
- TC-MVP-BE-042: documented exception review accepts only listed legacy/provider/platform-limited paths in `dart-client-drift-manifest.json`; the drift gate fails on unlisted or unused exceptions.
- TC-MVP-BE-043: stage/increment traceability grep confirms MVP-SI-001 through MVP-SI-014 are represented across stage and increment artifacts.
- TC-MVP-BE-044: full backend Maven suite passes.
- TC-MVP-BE-045: full Flutter suite passes with 173 tests.
- TC-MVP-BE-046: release checklist, version log, rollback plan, and quality report carry release evidence and Product Object Governance status.

Failing tests:
- None remaining.

Skipped or accepted-exception tests:
- Full `dart-dio` DTO generation is not used; the committed generated boundary is a project-local OpenAPI path/contract registry guarded by hash/path drift checks.
- Legacy stats/freeform scene/role-memory/payment-provider helper paths are documented handwritten-client exceptions and are not silently counted as migrated MVP backend endpoints.
- External object-store retention, real payment provider production readiness, paid report generation, offline packages, and achievements require separate owning increments.

Acceptance criteria coverage:
- AC-MVP-BE-013 is fully covered by TC-MVP-BE-039, TC-MVP-BE-040, TC-MVP-BE-041, and TC-MVP-BE-042.
- AC-MVP-BE-014 is fully covered by TC-MVP-BE-043, TC-MVP-BE-044, TC-MVP-BE-045, and TC-MVP-BE-046.
- `docs/product/increments/mvp-backend-client-qa-release/traceability.md` cites the same TC IDs, script paths, execution commands, result status, evidence reports, and release evidence.

Residual risk:
- Stage release is ready with documented exceptions, not production commercial launch approval.
- Future full DTO codegen should replace the project-local path registry when the frontend migration budget is opened.

## 2026-05-29 - mvp-system-e2e-validation System E2E Deep Regression Test Report

Test scope:
- Increment `docs/product/increments/mvp-system-e2e-validation/`.
- Stage Scope Item MVP-SI-014 system E2E hardening.
- Acceptance criteria AC-MVP-E2E-001 through AC-MVP-E2E-004.
- Test cases TC-MVP-E2E-001 through TC-MVP-E2E-010 executed or explicitly accepted as external gate.
- Local desktop black-box path: Flutter macOS UI + Spring Boot backend + real local PostgreSQL 15.18.

Commands run:
- `scripts/run_mvp_system_e2e.sh` - passed. It initialized isolated PostgreSQL, started backend on a random local port, ran `integration_test/mvp_system_smoke_test.dart` on macOS, and preserved logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-97338`.
- `scripts/run_mvp_system_e2e.sh --suite scene-catalog` - passed; logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-98620`.
- `scripts/run_mvp_system_e2e.sh --suite learning-memory` - passed; logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-99913`.
- `scripts/run_mvp_system_e2e.sh --suite practice-feedback` - passed; logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-1490`.
- `scripts/run_mvp_system_e2e.sh --suite profile-settings` - passed; logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-2774`.
- `scripts/run_mvp_system_e2e.sh --suite membership-boundary` - passed; logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-4371`.
- `python3 scripts/check_mvp_system_e2e_coverage.py` - passed: 10 TC rows, 13 Product Base AC rows, 4 traceability rows.
- `flutter test` - passed, 173 tests.
- `env JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-MVP-E2E-001: real-stack orchestration starts PostgreSQL/backend, applies backend startup/migration path, waits on `/v1/admin/release-health`, runs Flutter, and tears down.
- TC-MVP-E2E-002: Flutter UI starts without stored session, reaches login gate, accepts agreement, uses test phone login, and authenticates through the real backend.
- TC-MVP-E2E-003: onboarding completes through real Flutter UI clicks with deterministic choices and reaches home with learning scene content.
- TC-MVP-E2E-004: Product Base AC-001 through AC-013 all map to an executed TC, manual-external gate, or accepted exception.
- TC-MVP-E2E-005: TC rows include script path, command, result status, and evidence report.
- TC-MVP-E2E-006: scene catalog opens, `job_interview` scene can be joined, and listening warmup/mode toggle is reachable.
- TC-MVP-E2E-007: recommended expression queue appears, favorite action persists, and memory is visible through profile/favorites surfaces.
- TC-MVP-E2E-008: practice UI opens and deterministic backend provider returns coach feedback, provider status, recap fields, and evidence candidates.
- TC-MVP-E2E-009: profile edit, settings toggles, logout, relogin, onboarding bypass, and nickname/session persistence are verified.
- TC-MVP-E2E-010: membership plans, subscribe/restore boundary UI, and external payment exception are verified; real provider payment remains manual/external.

Defects found and fixed during system E2E hardening:
- Docker is not required for this local gate; the script now uses local PostgreSQL binaries, so a missing Docker daemon no longer skips the real PostgreSQL verification path.
- macOS integration build required deployment target 11.0; `macos/Podfile` and the Xcode project were aligned.
- Flutter login/onboarding needed stable test keys for deterministic UI driving.
- macOS app sandbox could not write Hive data into the host temp directory; E2E now uses an isolated Hive namespace under the app-accessible home path and disables SharedPreferences migration for the test run.
- Onboarding daily-goal cards used `Spacer` inside an unbounded scroll context; the card height is now fixed at 118 to prevent RenderFlex layout failure.
- Smoke helper initially accepted a partially initialized state as home-ready and briefly used a session shortcut for onboarding; helper assertions now wait on authenticated/onboarded home evidence, drive onboarding through the real UI, and include visible text diagnostics.
- Onboarding completion was not persisted through the backend because the client patched `/user/me` with unsupported `onboardingDone`; the app now submits `/onboarding/assessment` and uses PATCH `/user/me` with backend field names for profile edits.
- Several UI controls needed stable keys on the actual tappable/scrollable surfaces, including scene cards, profile settings, membership plans, placeholders, and favorites.
- Integration tests previously triggered Flutter's global error-hook warning; the E2E script now passes `SPEAKEASY_DISABLE_GLOBAL_ERROR_HOOKS=true`.

Residual risk:
- `/user/stats` still logs a non-blocking learning-stats refresh failure during E2E; the UI continues, but this is a real cross-layer compatibility risk for a future stats endpoint/client cleanup.
- macOS notification initialization still logs a soft failure in E2E because platform settings are not configured for local macOS tests.
- TC-MVP-E2E-008 deliberately uses deterministic backend/provider behavior; real LLM/ASR/TTS provider SLA and voice hardware remain external/manual gates.
- TC-MVP-E2E-010 verifies local membership boundary UI only; real payment provider purchase, webhook, refund, and restore completion remain manual/external release gates.

## 2026-05-29 - commercial-subscription-readiness Pre-Implementation Test Case Library

Test scope:
- Increment `docs/product/increments/commercial-subscription-readiness/`.
- Stage Scope Items COM-SI-001 through COM-SI-012.
- Acceptance criteria AC-COM-001 through AC-COM-014.
- Test case library `docs/product/increments/commercial-subscription-readiness/test_cases.md`.

Test design result:
- AC-to-TC mapping: passed for pre-implementation gate. AC-COM-001 through AC-COM-014 all map to stable TC IDs TC-COM-001 through TC-COM-023.
- Requirement-to-test mapping: passed for pre-implementation gate. FR-COM-001 through FR-COM-012 all map through accepted AC IDs to one or more TC IDs.
- Execution status: TC-COM-023 contract gate passed; TC-COM-001 through TC-COM-022 remain planned. No Backend, Frontend, AI Runtime or DevOps implementation was started in this step.

Commands run:
- `npm run check:api-contract` - passed outside sandbox after `uv` panicked in the sandboxed run. OpenAPI contract gate passed with 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples; Dart client drift passed with OpenAPI hash `4a0a9978ba4dec45d1df598bc0cd39770fd5eaa021fc6f7fe2ce47f16d0fb63a`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Coverage highlights:
- Purchase/restore/refund/expiry: TC-COM-001 through TC-COM-006 and TC-COM-019.
- Entitlement, gating and usage control: TC-COM-007 through TC-COM-010 and TC-COM-017 through TC-COM-018.
- Production login, social login and account deletion: TC-COM-011 through TC-COM-014.
- Commercial copy and release materials: TC-COM-015, TC-COM-016, TC-COM-021, TC-COM-022.
- OpenAPI contract gate: TC-COM-023 passed.

Manual or external gates:
- TC-COM-015: commercial copy review remains manual-verification.
- TC-COM-019: Apple sandbox and Google Play internal testing remain external-dependency.
- TC-COM-021: store material and privacy review remain manual-verification.

Residual risk:
- This closes the AC-to-TC implementation gate only. Commercial release readiness still requires implementation, executable tests, provider sandbox/internal evidence, DevOps release evidence, implementation report, quality report and PM release decision.

## 2026-05-29 - P0-COM-QA-002 Commercial Subscription QA Evidence

Test scope:
- Increment `docs/product/increments/commercial-subscription-readiness/`.
- Stage Scope Items COM-SI-001 through COM-SI-012.
- Requirements FR-COM-001 through FR-COM-012.
- Acceptance criteria AC-COM-001 through AC-COM-014.
- Automated backend provider/entitlement/usage/deletion tests, Flutter subscription/account deletion tests, OpenAPI contract gate, and release readiness scripts.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CommercialFoundationControllerTest,CommercialAccountDeletionProcessorTest,AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,EntitlementGateServiceTest,UsageQuotaGateTest,UsageReservationLifecycleTest,CommercialAbuseControlTest,ProviderGatewayControllerTest,ProviderGatewayAuthorizationTest,AppleSubscriptionVerificationTest,GoogleSubscriptionVerificationTest,SubscriptionCredentialValidationTest,SubscriptionRestoreTest,SubscriptionRestoreEmptyTest,PaymentProviderEventDowngradeTest test` from `backend/` - passed.
- `flutter test test/features/commercial/entitlement_downgrade_widget_test.dart test/features/commercial/account_deletion_cleanup_test.dart test/services/api_client_contract_test.dart` - passed.
- `npm run check:api-contract` - first failed in sandbox because `uv` panicked in macOS system configuration access; rerun outside sandbox passed with 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples, and Dart generated-client drift hash `4a0a9978ba4dec45d1df598bc0cd39770fd5eaa021fc6f7fe2ce47f16d0fb63a`.
- `bash -n scripts/check_release_configuration.sh scripts/check_social_login_release_config.sh scripts/check_release_readiness.sh` - passed.
- `APP_API_BASE_URL=https://api.speakeasyapp.com ENV=production ENABLE_TEST_PHONE_LOGIN=false scripts/check_release_configuration.sh` - passed.
- `WECHAT_APP_ID=wx1234567890abcdef WECHAT_UNIVERSAL_LINK=https://app.speakeasyapp.com/app/ scripts/check_social_login_release_config.sh --env-only` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, Sentry, Android signing, Apple/Google provider evidence refs, store metadata ref, reviewer account ref, symbol upload ref, rollback rehearsal ref, privacy URL, and support URL - passed.
- Same fixture `scripts/check_release_readiness.sh` in strict mode - failed as expected because native iOS WeChat URL scheme is still `wx0000000000000000` and Apple Sign In entitlement is not present.

Passing tests:
- TC-COM-001: `AppleSubscriptionVerificationTest` passed for server-owned Apple verification boundary.
- TC-COM-002: `GoogleSubscriptionVerificationTest` passed for server-owned Google verification boundary.
- TC-COM-003: `SubscriptionCredentialValidationTest` passed for invalid receipt/token and mismatch rejection.
- TC-COM-004: `SubscriptionRestoreTest` passed for active restore.
- TC-COM-005: `SubscriptionRestoreEmptyTest` passed for empty restore.
- TC-COM-006: `PaymentProviderEventDowngradeTest` passed for provider downgrade event handling.
- TC-COM-007: `entitlement_downgrade_widget_test.dart` passed for free entitlement downgrade UI and no offline/report overpromise.
- TC-COM-008: `EntitlementGateServiceTest` passed for paid L3 entitlement gating.
- TC-COM-009: `UsageQuotaGateTest` passed for quota exhaustion.
- TC-COM-011: `check_release_configuration.sh` passed with production fixture env.
- TC-COM-012: `check_social_login_release_config.sh --env-only` passed with production fixture env; strict native validation remains a release blocker.
- TC-COM-013: `CommercialAccountDeletionProcessorTest` and account deletion backend tests passed.
- TC-COM-014: `account_deletion_cleanup_test.dart` passed for local session/member/cache cleanup after deletion.
- TC-COM-017: `UsageReservationLifecycleTest` passed for reserve/commit/release lifecycle.
- TC-COM-018: `CommercialAbuseControlTest` passed for quota/abuse control boundary.
- TC-COM-022: `check_release_readiness.sh --env-only` passed with complete fixture evidence refs; strict release mode remains blocked by native social-login config.
- TC-COM-023: `npm run check:api-contract` passed outside sandbox.

Blocked, manual, external, or not-yet-executed tests:
- TC-COM-010: passed later by `P0-COM-SCENARIO-GATE-001` via `test/features/commercial/scenario_gating_consistency_test.dart`.
- TC-COM-015: manual commercial copy review remains pending for store/member/privacy screenshots.
- TC-COM-016: commercial copy contract automation is not implemented.
- TC-COM-019: external Apple sandbox and Google Play internal-track provider matrix remains pending.
- TC-COM-020: passed later by `P0-COM-PROVIDER-EVIDENCE-001` via `integration_test/commercial_boundary_test.dart`.
- TC-COM-021: manual store metadata, privacy/support URL, subscription terms, and reviewer-account review remains pending.
- Strict TC-COM-012/TC-COM-022 release mode is blocked until native iOS WeChat URL scheme and Apple Sign In entitlement are configured.

Acceptance criteria coverage:
- AC-COM-001 through AC-COM-006 and AC-COM-010 through AC-COM-012 have automated passed evidence for the implemented local/backend/frontend boundaries, with provider/store external evidence still blocking release where applicable.
- AC-COM-007 is covered by TC-COM-010 after `P0-COM-SCENARIO-GATE-001`.
- AC-COM-011 remains partially covered by Flutter copy assertions but blocked by TC-COM-015 and TC-COM-016.
- AC-COM-013 remains blocked by TC-COM-019 and TC-COM-020.
- AC-COM-014 has release gate scripts and fixture pass evidence, but commercial release is blocked by strict native/external evidence requirements.

Residual risk:
- This QA pass is not commercial release approval.
- The traceability chain is complete from FR/AC to TC IDs, but several TC IDs intentionally remain blocked/manual/external.
- Real provider, store console, privacy/support URL, reviewer-account, native social-login, symbol-upload, rollback rehearsal, and commercial E2E evidence must be supplied before PM can mark the stage release-ready.

## 2026-05-29 - P0-COM-SCENARIO-GATE-001 Scenario Gate Blocker Closure

Test scope:
- TC-COM-010 / AC-COM-007 / COM-TR-008.
- Flutter paid L3 scenario gating consistency across direct training entry, scene navigation/list view, and target-level switch.
- Regression scope for existing `InterviewPracticePage` scene navigation widget tests.

Commands run:
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart --plain-name "免费用户训练入口" --timeout 30s` - passed.
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart` - passed.
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart test/features/interview/interview_practice_page_widget_test.dart` - passed.
- `flutter analyze lib/features/commercial/commercial_scenario_gate.dart lib/features/interview/interview_practice_page.dart lib/pages/home_page.dart test/features/commercial/scenario_gating_consistency_test.dart test/features/interview/interview_practice_page_widget_test.dart` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-COM-010: free user direct L3 training entry is blocked with a Pro entitlement message.
- TC-COM-010: free user scene navigation exposes the same L3 locked state and does not display L3 expressions as accessible content.
- TC-COM-010: Pro user can switch to L3 from scene navigation and sees L3 expressions in the training flow.
- Regression: existing interview scene navigation and composer widget tests passed.

Failing tests:
- None in the scoped command set.

Skipped tests:
- Real provider and store console tests were not in scope for this package.

Acceptance criteria coverage:
- AC-COM-007 is covered by TC-COM-010 and TC-COM-023. TC-COM-010 is now passed for the in-app L3 paid scenario fixture.

Residual risk:
- This closes the scenario gating blocker only.
- TC-COM-016 is closed by `P0-COM-COPY-001`; TC-COM-020 is closed by `P0-COM-PROVIDER-EVIDENCE-001`; TC-COM-015 external evidence, TC-COM-019 external evidence, TC-COM-021 external evidence, and strict TC-COM-012/022 remain release blockers.

## 2026-05-29 - P0-COM-COPY-001 Commercial Copy Blocker Closure

Test scope:
- TC-COM-015 / TC-COM-016 / AC-COM-011 / COM-TR-009.
- In-repo commercial copy across `MembershipPage`, profile upsell copy, release checklist, release runbook, and copy contract automation.
- Release readiness fixture gate after adding the copy contract gate.

Commands run:
- `python3 scripts/check_commercial_copy_contract.py` - passed; reported missing external `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL`, and `SUPPORT_URL` as release blockers.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, Sentry, Android signing, Apple/Google provider evidence refs, store metadata ref, reviewer account ref, symbol upload ref, rollback rehearsal ref, privacy URL, and support URL - passed.
- `flutter test test/features/commercial/entitlement_downgrade_widget_test.dart` - passed.
- `flutter analyze lib/pages/profile_page.dart lib/pages/membership_page.dart test/features/commercial/entitlement_downgrade_widget_test.dart` - passed.
- `bash -n scripts/check_release_readiness.sh` - passed.

Passing tests:
- TC-COM-016: copy contract automation passed for shipped membership benefits, payment plan/product mapping, profile upsell copy, and release copy gate documentation.
- TC-COM-015 internal review: membership/profile/release copy does not promise offline learning packs, dedicated learning reports, unlimited practice, or lifetime membership as shipped paid benefits.
- Regression: TC-COM-007 membership downgrade widget tests still pass.

Failing tests:
- None in the scoped command set.

Skipped or external tests:
- TC-COM-015 external store metadata/privacy/support screenshots were not available locally and remain a release blocker.

Acceptance criteria coverage:
- AC-COM-011 is locally covered by TC-COM-016 and in-repo TC-COM-015 review evidence.
- AC-COM-011 is not release-complete until TC-COM-015 external store/privacy evidence is supplied.

Residual risk:
- The copy contract proves repository copy consistency; it does not prove App Store Connect / Play Console screenshots or privacy declarations.
- TC-COM-020 is closed by `P0-COM-PROVIDER-EVIDENCE-001`; TC-COM-015 external evidence, TC-COM-019 external evidence, TC-COM-021 external evidence, and strict TC-COM-012/022 remain release blockers.

## 2026-05-29 - P0-COM-PROVIDER-EVIDENCE-001 Provider Evidence Gate

Test scope:
- TC-COM-019 / TC-COM-020 / AC-COM-013 / COM-TR-011.
- Provider sandbox/internal evidence matrix and release gate.
- Local non-payment commercial boundary coverage for first install, old plan data, weak-network/provider-error recovery, and exhausted entitlement gating.

Commands run:
- `python3 scripts/check_provider_sandbox_evidence.py` - passed; reported missing `APPLE_SANDBOX_EVIDENCE_REF` and `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` as release blockers.
- `python3 -m py_compile scripts/check_provider_sandbox_evidence.py scripts/check_commercial_copy_contract.py` - passed.
- `bash -n scripts/run_mvp_system_e2e.sh scripts/check_release_readiness.sh` - passed.
- `flutter test integration_test/commercial_boundary_test.dart` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, provider/store/reviewer/symbol/rollback evidence refs, privacy URL, support URL, Sentry, and Android signing vars - passed.

Passing tests:
- TC-COM-020: local commercial boundary test passed for free first install membership gate, legacy plan normalization, L3 locked entitlement boundary, and weak-network/provider-error recovery UI.
- TC-COM-019 local gate: provider matrix and evidence script passed structurally.

Failing tests:
- None in the scoped local command set.

Skipped or external tests:
- TC-COM-019 real Apple sandbox and Google Play internal-track execution remains external pending.

Acceptance criteria coverage:
- AC-COM-013 has local TC-COM-020 passed evidence and TC-COM-019 evidence-gate structure.
- AC-COM-013 remains release-blocked until real provider evidence refs are supplied.

Residual risk:
- Local deterministic provider tests cannot replace Apple sandbox or Google Play internal-track evidence.
- TC-COM-019, TC-COM-015 external evidence, TC-COM-021, and strict TC-COM-012/022 remain release blockers.

## 2026-05-29 - P0-COM-STORE-001 Store Evidence Gate

Test scope:
- TC-COM-021 / TC-COM-022 / AC-COM-014 / COM-TR-012.
- Store submission evidence matrix and release readiness aggregation.
- Strict release gate behavior with fixture evidence refs.

Commands run:
- `python3 scripts/check_store_submission_evidence.py` - passed; reported missing `STORE_METADATA_EVIDENCE_REF`, `REVIEWER_ACCOUNT_REF`, `PRIVACY_URL`, and `SUPPORT_URL` as release blockers.
- `python3 -m py_compile scripts/check_store_submission_evidence.py scripts/check_provider_sandbox_evidence.py scripts/check_commercial_copy_contract.py` - passed.
- `bash -n scripts/check_release_readiness.sh scripts/run_mvp_system_e2e.sh` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, provider/store/reviewer/symbol/rollback evidence refs, privacy URL, support URL, Sentry, and Android signing vars - passed.
- Same fixture `scripts/check_release_readiness.sh` in strict mode - failed as expected because iOS still contains the placeholder WeChat URL scheme and lacks the Apple Sign In entitlement.

Passing tests:
- TC-COM-021 local gate: store submission matrix and evidence script passed structurally.
- TC-COM-022 env-only fixture gate passed with required evidence refs and URLs.

Failing tests:
- Strict TC-COM-012/TC-COM-022 release gate failed as expected on native iOS social-login configuration.

Skipped or external tests:
- TC-COM-021 real App Store Connect / Play Console metadata, reviewer account, privacy URL, and support URL evidence remains external pending.

Acceptance criteria coverage:
- AC-COM-014 has local release-gate evidence and store evidence-gate structure.
- AC-COM-014 remains release-blocked until real store/native evidence refs are supplied.

Residual risk:
- This does not configure App Store Connect, Play Console, public privacy/support pages, reviewer credentials, iOS WeChat URL scheme, or Apple Sign In entitlement.
- Remaining release blockers are TC-COM-015 external copy/store evidence, TC-COM-019 external provider evidence, TC-COM-021 external store evidence, and strict TC-COM-012/022 native/release evidence.
## 2026-06-01 P0-AI-BE-001 Media Upload And ASR Ref Tests

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-BE-001`
- Coverage：`COM-SI-013` / `FR-COM-AI-001` / `AC-COM-AI-001`
- Test cases：`TC-COM-AI-001`, `TC-COM-AI-002`

Command:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,ProductionAsrMediaRefTest,DashScopeProviderGatewayIntegrationTest test
```

Result: passed.

Evidence:
- `MediaUploadReferenceServiceTest` verifies authenticated media upload creation, idempotent upload create, trusted `media://audio/{media_id}` ref shape, upload URL shape, upload completion to `validated`, unsupported MIME rejection and oversize rejection.
- `ProductionAsrMediaRefTest` verifies DashScope production ASR rejects local paths, unsigned HTTP URLs and unvalidated media refs before provider call, and accepts a completed backend media ref.
- `DashScopeProviderGatewayIntegrationTest` regression verifies existing DashScope adapter behavior after changing local path handling from typed no-result to provider-before-call rejection.

Residual:
- This is a local backend/object lifecycle implementation gate. Real object storage bucket credentials, CDN/public serving behavior and live DashScope evidence remain pending in later work packages.

## 2026-06-01 P0-AI-BE-002 Persistent TTS Cache Tests

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-BE-002`
- Coverage：`COM-SI-014` / `FR-COM-AI-002` / `AC-COM-AI-002`
- Test cases：`TC-COM-AI-003`

Command:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PersistentTtsCacheTest,DashScopeProviderGatewayIntegrationTest,DashScopeProviderGatewayTest test
```

Result: passed.

Evidence:
- `PersistentTtsCacheTest` verifies the first TTS request stores a persistent cache entry with `cache_status=miss`, and a repeated request returns `cache_status=hit`, the same cache media id/audio ref and no second provider call.
- `PersistentTtsCacheTest` verifies an expired cache entry is refreshed instead of reused.
- `DashScopeProviderGatewayIntegrationTest` regression verifies the existing `/ai/tts` path still returns available TTS and avoids duplicate provider calls.
- `DashScopeProviderGatewayTest` keeps the non-Spring unit boundary covered with a dev-only local fallback cache while production Spring wiring uses `AiTtsCacheService`.

Residual:
- This closes local persistent cache metadata, expiry refresh and delete-hook support. CDN/object storage distribution and production retention proof remain pending in later work packages.

## 2026-06-01 P0-AI-QA-001 DashScope Sandbox Evidence Gate

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-QA-001`
- Coverage：`COM-SI-015` / `FR-COM-AI-003` / `AC-COM-AI-003`
- Test case：`TC-COM-AI-004`

Commands:
```bash
python3 scripts/check_ai_provider_sandbox_evidence.py
python3 scripts/check_manual_external_evidence_plan.py
python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external
```

Result:
- Non-strict AI provider evidence gate passed and reported the expected missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` release blocker.
- Manual external evidence plan passed after adding the DashScope gate command and scenario IDs.
- Strict AI provider evidence gate failed as expected because real DashScope evidence has not been supplied.

Evidence:
- `tests/commercial/ai_provider_sandbox_matrix.md` now enumerates Qwen valid/fallback, Paraformer valid/reject, TTS generate/cache and provider-error scenarios with latency, error code, cost estimate, format compatibility, fallback and reviewer requirements.
- `scripts/check_ai_provider_sandbox_evidence.py` validates the matrix and blocks strict release closure without `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.
- `scripts/check_release_readiness.sh` now includes the AI provider evidence gate in strict release readiness.

Residual:
- This is not a real DashScope sandbox pass. Controlled live LLM/ASR/TTS execution and external evidence review remain required before paid AI voice release.

## 2026-06-01 P0-AI-OPS-001 AI Cost Dashboard Tests

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-OPS-001`
- Coverage：`COM-SI-016` / `FR-COM-AI-004` / `AC-COM-AI-004`
- Test case：`TC-COM-AI-005`

Command:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest,DashScopeProviderGatewayIntegrationTest,CommercialFoundationControllerTest test
```

Result: passed.

Evidence:
- `AiCostDashboardTest` verifies `/admin/ai/cost-metrics` returns plan, user hash, provider family, model, capability, status, cache hit, call count, token/audio units, estimated cost, budget bucket and margin risk.
- `AiCostDashboardTest` verifies raw user id and raw TTS input text are not exposed in the dashboard response.
- `AiCostDashboardTest` verifies budget warning aggregation and provider anomaly status.
- `AiCostDashboardTest` verifies the endpoint requires the OPS bearer token and rejects normal user tokens.
- Regression coverage with `DashScopeProviderGatewayIntegrationTest` and `CommercialFoundationControllerTest` passed after adding metric persistence and OPS controller wiring.

Residual:
- Local dashboard and budget/anomaly status are implemented. Production PM/Ops evidence is still required through `AI_COST_DASHBOARD_EVIDENCE_REF` before paid AI release.

## 2026-06-01 P0-AI-SEC-001 AI Retention And Deletion Tests

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-SEC-001`
- Coverage：`COM-SI-017` / `FR-COM-AI-005` / `AC-COM-AI-005`
- Test cases：`TC-COM-AI-006`, `TC-COM-AI-007`

Command:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,AiCostDashboardTest,AccountDeletionLearningDataTest test
```

Result: passed.

Evidence:
- `AiRetentionPolicyTest` verifies OPS-only `POST /admin/ai/retention-jobs` deletes expired media and expired TTS cache entries, records counts and returns a redacted evidence ref.
- `AiRetentionPolicyTest` verifies `GET /admin/ai/retention-jobs/{job_id}` reads completed retention evidence and the idempotency key returns the same job.
- `AiAccountDeletionMediaCleanupTest` verifies account deletion runs AI media deletion, TTS cache owner cleanup, provider metric redaction and creates an `account_deletion` AI retention job.
- `AccountDeletionLearningDataTest` passed as an existing account deletion regression.

Residual:
- Local retention execution proof is implemented. Production object-store lifecycle, external deletion proof and approved retention policy evidence remain required through `AI_MEDIA_STORAGE_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF`.

## 2026-06-01 P0-AI-REPORT-001 Final Verification

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-REPORT-001`
- Coverage：final verification for TC-COM-AI-001 through TC-COM-AI-007 local gates and release blockers.

Commands:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,ProductionAsrMediaRefTest,PersistentTtsCacheTest,AiCostDashboardTest,AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,DashScopeProviderGatewayIntegrationTest,DashScopeProviderGatewayTest,CommercialFoundationControllerTest,AccountDeletionLearningDataTest test
python3 scripts/check_ai_provider_sandbox_evidence.py
python3 scripts/check_manual_external_evidence_plan.py
python3 -m py_compile scripts/check_ai_provider_sandbox_evidence.py scripts/check_manual_external_evidence_plan.py scripts/check_provider_sandbox_evidence.py scripts/check_store_submission_evidence.py scripts/check_commercial_copy_contract.py
bash -n scripts/check_release_readiness.sh
git diff --check
npm run lint:openapi
npm run check:api-contract
```

Result:
- Backend combined target tests passed.
- AI provider sandbox evidence non-strict gate passed with expected missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` blocker.
- Manual external evidence plan passed.
- Script compile, release shell syntax, diff whitespace and OpenAPI lint passed.
- `npm run check:api-contract` failed inside the filesystem sandbox due to the known `uv` macOS system configuration panic, then passed outside the sandbox.

Residual:
- This is not paid AI release approval. Strict release still requires DashScope, media storage, cost dashboard and retention evidence refs.
