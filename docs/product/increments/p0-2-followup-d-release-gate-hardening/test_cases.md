# P0.2 Followup-D Test Cases：发布门禁与商业软件加固

## 状态
S000 AC-to-TC mapping passed - 本文件定义 Followup-D 测试用例库。TC-P02-FUD-000 用于 S000 文档链和双视角独立审核；TC-P02-FUD-001..021 是后续实现 slices 的 planned test cases，尚未执行，不得解释为代码通过、release ready 或 Product Base approval。

## 上游来源
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/requirements.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/spec.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/acceptance.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/traceability.md`

## AC-to-TC Gate Result
| 字段 | 值 |
| --- | --- |
| Gate | P0.2 Followup-D S000 pre-implementation AC-to-TC mapping |
| Result | Passed for S000 documentation validation and dual independent review |
| Date | 2026-06-06 |
| Scope | P0.2 release/commercial/data/ops gates for feature flag, entitlement, usage, cost, downgrade, export/retention, consent, telemetry, drift checks and Product Base/release review |
| Execution status | S000 documentation validation passed; S001-S011 planned |
| Evidence report | `docs/reports/test_report.md#2026-06-06-p02-followup-d-s000-document-chain` and `docs/reports/quality_report.md#2026-06-06-p02-followup-d-s000-document-chain-dual-review` |

## Implementation Slice Test Routing
| Slice ID | Scope | AC | TC | Execution state |
| --- | --- | --- | --- | --- |
| P02-FUD-S000 | Document chain and routing | AC-P02-FUD-000 | TC-P02-FUD-000 | Passed validation; no code |
| P02-FUD-S001 | Backend feature flag and kill switch | AC-P02-FUD-001 | TC-P02-FUD-001..002 | Planned |
| P02-FUD-S002 | Flutter entry and surface rollback | AC-P02-FUD-002 | TC-P02-FUD-003..004 | Planned |
| P02-FUD-S003 | Entitlement/free-paid depth policy | AC-P02-FUD-003 | TC-P02-FUD-005..006 | Planned |
| P02-FUD-S004 | Usage reservation and quota | AC-P02-FUD-004 | TC-P02-FUD-007..008 | Planned |
| P02-FUD-S005 | Cost telemetry and AI fallback | AC-P02-FUD-005 | TC-P02-FUD-009..010 | Planned |
| P02-FUD-S006 | Quota exhausted downgrade | AC-P02-FUD-006 | TC-P02-FUD-011..012 | Planned |
| P02-FUD-S007 | Export, retention and deletion backend evidence | AC-P02-FUD-007 | TC-P02-FUD-013..014 | Planned |
| P02-FUD-S008 | Consent and privacy UX | AC-P02-FUD-008 | TC-P02-FUD-015 | Planned |
| P02-FUD-S009 | Telemetry health/error/funnel metrics | AC-P02-FUD-009 | TC-P02-FUD-016..017 | Planned |
| P02-FUD-S010 | Contract, traceability and release drift gates | AC-P02-FUD-010 | TC-P02-FUD-018..019 | Planned |
| P02-FUD-S011 | Product Base, release checklist and independent review | AC-P02-FUD-011 | TC-P02-FUD-020..021 | Planned |

## Test Case Library
| TC ID | Stage Scope ID | Policy Gate | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-P02-FUD-000 | P02-SI-001..013 | P02-PG-001..005 | P02-FUD-FR-000 | P02-FUD-SPEC-000 | AC-P02-FUD-000 | P02-FUD-TR-000 | P02-FUD-GAP-000 | release-check | automated | `docs/product/increments/p0-2-followup-d-release-gate-hardening/*.md`; `docs/reports/quality_report.md` | `python3 scripts/project_agent_runner.py validate`; `git diff --check -- docs/product/increments/p0-2-followup-d-release-gate-hardening docs/reports/test_report.md docs/reports/implementation_report.md docs/reports/quality_report.md` | passed | `docs/reports/quality_report.md#2026-06-06-p02-followup-d-s000-document-chain-dual-review` |
| TC-P02-FUD-001 | P02-SI-001..013 | P02-PG-003, P02-PG-004 | P02-FUD-FR-001 | P02-FUD-SPEC-001 | AC-P02-FUD-001 | P02-FUD-TR-001 | P02-FUD-GAP-001 | integration | planned | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotRuntimeGateTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotRuntimeGateTest test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s001-backend-runtime-gate` |
| TC-P02-FUD-002 | P02-SI-001..013 | P02-PG-003, P02-PG-004 | P02-FUD-FR-001 | P02-FUD-SPEC-001 | AC-P02-FUD-001 | P02-FUD-TR-001 | P02-FUD-GAP-001 | contract | planned | `docs/architecture/openapi/speakeasy-api.yaml`; `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java` | `npm run check:api-contract`; `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fud001RuntimeGateReadAndMutationBoundary test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s001-backend-runtime-gate` |
| TC-P02-FUD-003 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-004 | P02-FUD-FR-002 | P02-FUD-SPEC-002 | AC-P02-FUD-002 | P02-FUD-TR-002 | P02-FUD-GAP-002 | widget | planned | `test/features/goal_autopilot/goal_autopilot_runtime_gate_widget_test.dart` | `flutter test test/features/goal_autopilot/goal_autopilot_runtime_gate_widget_test.dart` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s002-flutter-runtime-gate` |
| TC-P02-FUD-004 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-004 | P02-FUD-FR-002 | P02-FUD-SPEC-002 | AC-P02-FUD-002 | P02-FUD-TR-002 | P02-FUD-GAP-002 | release-check | planned | `scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` | `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s002-flutter-runtime-gate` |
| TC-P02-FUD-005 | P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-FUD-FR-003 | P02-FUD-SPEC-003 | AC-P02-FUD-003 | P02-FUD-TR-003 | P02-FUD-GAP-003 | unit | planned | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotEntitlementPolicyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotEntitlementPolicyTest test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s003-entitlement-depth` |
| TC-P02-FUD-006 | P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-FUD-FR-003 | P02-FUD-SPEC-003 | AC-P02-FUD-003 | P02-FUD-TR-003 | P02-FUD-GAP-003 | integration | planned | `backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java#tcP02Fud003EntitlementDepthIsServerOwned` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fud003EntitlementDepthIsServerOwned test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s003-entitlement-depth` |
| TC-P02-FUD-007 | P02-SI-008..013 | P02-PG-004 | P02-FUD-FR-004 | P02-FUD-SPEC-004 | AC-P02-FUD-004 | P02-FUD-TR-004 | P02-FUD-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotUsageReservationTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotUsageReservationTest test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s004-usage-quota` |
| TC-P02-FUD-008 | P02-SI-008..013 | P02-PG-004 | P02-FUD-FR-004 | P02-FUD-SPEC-004 | AC-P02-FUD-004 | P02-FUD-TR-004 | P02-FUD-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/UsageQuotaGateTest.java`; `backend/src/test/java/com/speakeasy/UsageReservationLifecycleTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=UsageQuotaGateTest,UsageReservationLifecycleTest test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s004-usage-quota` |
| TC-P02-FUD-009 | P02-SI-008, P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-004 | P02-FUD-FR-005 | P02-FUD-SPEC-005 | AC-P02-FUD-005 | P02-FUD-TR-005 | P02-FUD-GAP-005 | integration | planned | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotCostTelemetryTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotCostTelemetryTest test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s005-cost-telemetry` |
| TC-P02-FUD-010 | P02-SI-008, P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-004 | P02-FUD-FR-005 | P02-FUD-SPEC-005 | AC-P02-FUD-005 | P02-FUD-TR-005 | P02-FUD-GAP-005 | ai-eval | planned | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotAiGuardrailTest.java`; `docs/ai_runtime/ai_eval_cases.md` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotAiGuardrailTest test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s005-cost-telemetry` |
| TC-P02-FUD-011 | P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-FUD-FR-006 | P02-FUD-SPEC-006 | AC-P02-FUD-006 | P02-FUD-TR-006 | P02-FUD-GAP-006 | integration | planned | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotQuotaDowngradeTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotQuotaDowngradeTest test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s006-quota-downgrade` |
| TC-P02-FUD-012 | P02-SI-007..013 | P02-PG-002, P02-PG-004 | P02-FUD-FR-006 | P02-FUD-SPEC-006 | AC-P02-FUD-006 | P02-FUD-TR-006 | P02-FUD-GAP-006 | widget | planned | `test/features/goal_autopilot/goal_autopilot_quota_downgrade_widget_test.dart` | `flutter test test/features/goal_autopilot/goal_autopilot_quota_downgrade_widget_test.dart` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s006-quota-downgrade` |
| TC-P02-FUD-013 | P02-SI-001..013 | P02-PG-005 | P02-FUD-FR-007 | P02-FUD-SPEC-007 | AC-P02-FUD-007 | P02-FUD-TR-007 | P02-FUD-GAP-007 | integration | planned | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotDataExportRetentionTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotDataExportRetentionTest test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s007-data-export-retention` |
| TC-P02-FUD-014 | P02-SI-001..013 | P02-PG-005 | P02-FUD-FR-007 | P02-FUD-SPEC-007 | AC-P02-FUD-007 | P02-FUD-TR-007 | P02-FUD-GAP-007 | integration | planned | `backend/src/test/java/com/speakeasy/AccountDeletionLearningDataTest.java`; `backend/src/test/java/com/speakeasy/goal/GoalAutopilotDataExportRetentionTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AccountDeletionLearningDataTest,GoalAutopilotDataExportRetentionTest test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s007-data-export-retention` |
| TC-P02-FUD-015 | P02-SI-007..013 | P02-PG-005 | P02-FUD-FR-008 | P02-FUD-SPEC-008 | AC-P02-FUD-008 | P02-FUD-TR-008 | P02-FUD-GAP-008 | widget | planned | `test/features/goal_autopilot/goal_autopilot_consent_privacy_widget_test.dart`; `scripts/check_commercial_copy_contract.py` | `flutter test test/features/goal_autopilot/goal_autopilot_consent_privacy_widget_test.dart`; `python3 scripts/check_commercial_copy_contract.py` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s008-consent-privacy` |
| TC-P02-FUD-016 | P02-SI-001..013 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUD-FR-009 | P02-FUD-SPEC-009 | AC-P02-FUD-009 | P02-FUD-TR-009 | P02-FUD-GAP-009 | integration | planned | `backend/src/test/java/com/speakeasy/goal/GoalAutopilotTelemetryTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotTelemetryTest test` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s009-telemetry` |
| TC-P02-FUD-017 | P02-SI-001..013 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUD-FR-009 | P02-FUD-SPEC-009 | AC-P02-FUD-009 | P02-FUD-TR-009 | P02-FUD-GAP-009 | release-check | planned | `scripts/check_p0_2_followup_d_telemetry_redaction.py` | `python3 scripts/check_p0_2_followup_d_telemetry_redaction.py` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s009-telemetry` |
| TC-P02-FUD-018 | P02-SI-001..013 | P02-PG-001..005 | P02-FUD-FR-010 | P02-FUD-SPEC-010 | AC-P02-FUD-010 | P02-FUD-TR-010 | P02-FUD-GAP-010 | release-check | planned | `scripts/check_p0_2_followup_d_traceability.py` | `python3 scripts/check_p0_2_followup_d_traceability.py` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s010-drift-gates` |
| TC-P02-FUD-019 | P02-SI-001..013 | P02-PG-001..005 | P02-FUD-FR-010 | P02-FUD-SPEC-010 | AC-P02-FUD-010 | P02-FUD-TR-010 | P02-FUD-GAP-010 | contract | planned | `docs/architecture/openapi/speakeasy-api.yaml`; `docs/release/release_checklist.md`; `docs/release/rollback_plan.md` | `npm run check:api-contract`; `npm run check:dart-client-drift`; `scripts/check_release_readiness.sh` | planned | `docs/reports/test_report.md#planned-p02-followup-d-s010-drift-gates` |
| TC-P02-FUD-020 | P02-SI-001..013 | P02-PG-001..005 | P02-FUD-FR-011 | P02-FUD-SPEC-011 | AC-P02-FUD-011 | P02-FUD-TR-011 | P02-FUD-GAP-011 | release-check | planned | `docs/reports/implementation_report.md`; `docs/reports/test_report.md`; `docs/reports/quality_report.md`; `docs/release/release_checklist.md` | `python3 scripts/project_agent_runner.py validate`; `git diff --check` | planned | `docs/reports/quality_report.md#planned-p02-followup-d-final-review` |
| TC-P02-FUD-021 | P02-SI-001..013 | P02-PG-001..005 | P02-FUD-FR-011 | P02-FUD-SPEC-011 | AC-P02-FUD-011 | P02-FUD-TR-011 | P02-FUD-GAP-011 | manual | manual-verification | `docs/reports/quality_report.md`; `docs/release/release_checklist.md` | `Product engineer and software engineer independent review recorded with blocker/no-blocker finding` | planned | `docs/reports/quality_report.md#planned-p02-followup-d-final-review` |

## Coverage Map
| Acceptance Criteria | Primary TC | Supporting TC | Coverage status |
| --- | --- | --- | --- |
| AC-P02-FUD-000 | TC-P02-FUD-000 | N/A - documentation setup only | Passed S000 validation |
| AC-P02-FUD-001 | TC-P02-FUD-001 | TC-P02-FUD-002 | Planned |
| AC-P02-FUD-002 | TC-P02-FUD-003 | TC-P02-FUD-004 | Planned |
| AC-P02-FUD-003 | TC-P02-FUD-005 | TC-P02-FUD-006 | Planned |
| AC-P02-FUD-004 | TC-P02-FUD-007 | TC-P02-FUD-008 | Planned |
| AC-P02-FUD-005 | TC-P02-FUD-009 | TC-P02-FUD-010 | Planned |
| AC-P02-FUD-006 | TC-P02-FUD-011 | TC-P02-FUD-012 | Planned |
| AC-P02-FUD-007 | TC-P02-FUD-013 | TC-P02-FUD-014 | Planned |
| AC-P02-FUD-008 | TC-P02-FUD-015 | N/A - UX/copy path | Planned |
| AC-P02-FUD-009 | TC-P02-FUD-016 | TC-P02-FUD-017 | Planned |
| AC-P02-FUD-010 | TC-P02-FUD-018 | TC-P02-FUD-019 | Planned |
| AC-P02-FUD-011 | TC-P02-FUD-020 | TC-P02-FUD-021 | Planned |

## Required Fixture And Assertion Coverage
| Fixture ID | Fixture area | Required assertions | Planned TC |
| --- | --- | --- | --- |
| FUD-FIX-000 | S000 documentation chain | required docs exist, S000-S011 routing, FR/Spec/AC/TC mapping, no implementation/release claim, dual review recorded | TC-P02-FUD-000 |
| FUD-FIX-001 | Backend runtime gate | flag off, kill switch, mutation blocked before write, read downgraded, audit reason | TC-P02-FUD-001..002 |
| FUD-FIX-002 | Flutter rollback | disabled entry, unavailable backend, cached projection cleared, no local fallback | TC-P02-FUD-003..004 |
| FUD-FIX-003 | Entitlement depth | free/paid/expired/revoked/unknown, support override, server-owned decision | TC-P02-FUD-005..006 |
| FUD-FIX-004 | Usage quota | reserve, commit, release, provider failure, idempotent retry, idempotency conflict | TC-P02-FUD-007..008 |
| FUD-FIX-005 | Cost telemetry and AI guard | success/fallback/rejection metric, deterministic N/A, forbidden persistent field rejection | TC-P02-FUD-009..010 |
| FUD-FIX-006 | Quota downgrade | quota exhausted, entitlement blocked, cost limited, stale full-depth cache removed | TC-P02-FUD-011..012 |
| FUD-FIX-007 | Data governance | redacted export, retention table, deletion proof, sensitive payload omitted | TC-P02-FUD-013..014 |
| FUD-FIX-008 | Consent/privacy UX | consent visible, withdrawal blocks reminders, copy contract, stale state removed | TC-P02-FUD-015 |
| FUD-FIX-009 | Telemetry | intake/plan/action/checkpoint/projection events, errors, redaction, telemetry failure fallback | TC-P02-FUD-016..017 |
| FUD-FIX-010 | Drift/release gates | D checker, OpenAPI/generated drift, release checklist/rollback sync, missing evidence blocks | TC-P02-FUD-018..019 |
| FUD-FIX-011 | Final review | reports cite evidence, Product Base/release/paid AI states separated, dual review result | TC-P02-FUD-020..021 |

## Execution Rules
- No TC-P02-FUD row may be marked passed without command output and evidence report updates.
- Backend/domain/API tests are mandatory if runtime gate, entitlement, usage, cost, data export, telemetry or release logic changes.
- OpenAPI/generated client drift checks are mandatory if any API shape or generated path changes.
- Flutter widget/integration tests are mandatory if Home, Queue, Wiki, panel, adapter, consent or downgrade UI changes.
- AI eval/schema tests are mandatory if P0.2 AI explanation candidate schema or forbidden field guard changes.
- Changed backend/domain/API/Flutter code must meet line and branch coverage >=80%; unchanged layers must be explicitly marked `N/A - no code change in this layer`.
- `scripts/check_p0_2_followup_d_traceability.py` is the planned S010 completion deliverable and must exist before TC-P02-FUD-018 can pass.
- S000 documentation validation must not be used to claim S001-S011 implementation, release approval or Product Base merge.

## Implementation Gate
AC-to-TC mapping exists for AC-P02-FUD-000 through AC-P02-FUD-011. S000 validation and dual independent review passed for documentation routing only. S001-S011 implementation remains planned and still requires slice-specific code/test/review evidence. Followup-D is not release-ready and Product Base merge is not approved.
