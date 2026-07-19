# P0.2 Followup-E Test Cases：生产级音频优先口语诊断

## 状态
Phase 3 test cases passed independent review / implementation planning only - 本文件定义 Followup-E 测试用例库和 AC-to-TC gate。当前所有 TC-P02-FUE-000..026 均为 planned；没有 backend、Flutter、OpenAPI/generated client、AI runtime、native mic/audio bytes upload、retention/export/account deletion、entitlement/provider downgrade、release 或 Product Base 执行通过证据。本文不代表 Followup-E locally complete、release-ready、paid AI external evidence passed 或 Product Base merge approved。

## 上游来源
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/requirements.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/spec.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/acceptance.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/traceability.md`
- `docs/domain/domain_schema.md`
- `docs/architecture/api_contract.md`
- `docs/architecture/data_flow.md`
- `docs/ai_runtime/prompt_contract.md`
- `docs/ai_runtime/llm_output_schema.md`
- `docs/ai_runtime/fallback_strategy.md`
- `docs/ai_runtime/ai_eval_cases.md`
- `docs/ux/screen_spec.md`

## AC-to-TC Gate Result
| 字段 | 值 |
| --- | --- |
| Gate | P0.2 Followup-E Phase 3 AC-to-TC mapping |
| Result | Passed independent review for planning gate |
| Date | 2026-06-07 |
| Scope | Speaking Check entry, sample task set, recording UX, trusted upload/audio_ref, quality gate, diagnostic mode, ASR/scoring/AI candidate validation, accepted result, privacy/retention/export/delete, entitlement/quota/cost downgrade, traceability/release boundary |
| Execution status | All TC-P02-FUE-000..026 remain planned in this docs-only state; no backend, Flutter, OpenAPI/generated, AI runtime or release test evidence is accepted. |
| Evidence report | N/A - implementation test evidence pending |

## Implementation Slice Test Routing
| Slice ID | Scope | AC | TC | Execution state |
| --- | --- | --- | --- | --- |
| P02-FUE-S000 | Document chain and routing | AC-P02-FUE-000 | TC-P02-FUE-000 | Planned / docs-only |
| P02-FUE-S001 | Speaking Check entry, sample set and recording UX | AC-P02-FUE-001..003 | TC-P02-FUE-001..006 | Planned - must reuse existing MVP/P0.1 mic/recording service; no duplicate mic implementation |
| P02-FUE-S002 | Trusted upload and backend-owned `audio_ref` | AC-P02-FUE-004 | TC-P02-FUE-007..009 | Planned |
| P02-FUE-S003 | Quality gate and diagnostic mode | AC-P02-FUE-005 | TC-P02-FUE-010..012 | Planned |
| P02-FUE-S004 | ASR/scoring/AI candidate and accepted result | AC-P02-FUE-006..007 | TC-P02-FUE-013..016 | Planned |
| P02-FUE-S005 | Privacy, retention, export and deletion | AC-P02-FUE-008 | TC-P02-FUE-017..019 | Planned |
| P02-FUE-S006 | Entitlement, quota, cost and provider downgrade | AC-P02-FUE-009 | TC-P02-FUE-020..022 | Planned |
| P02-FUE-S007 | Traceability, drift, coverage and review gates | AC-P02-FUE-010 | TC-P02-FUE-023..026 | Planned |

## Test Case Library
| TC ID | Stage Scope ID | Policy Gate | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-P02-FUE-000 | P02-SI-007, P02-SI-008 | P02-PG-001..005 | P02-FUE-FR-000 | P02-FUE-SPEC-000 | AC-P02-FUE-000 | P02-FUE-TR-000 | P02-FUE-GAP-000 | release-check | planned | `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/*.md` | `python3 scripts/validate_governance_contracts.py`; `git diff --check -- docs/product/increments/p0-2-followup-e-speaking-diagnostic-production` | planned | N/A - Phase 3 docs planned before implementation |
| TC-P02-FUE-001 | P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-FR-001 | P02-FUE-SPEC-001 | AC-P02-FUE-001 | P02-FUE-TR-001 | P02-FUE-GAP-001 | widget | planned | `test/features/goal_autopilot/speaking_check_entry_widget_test.dart` | Planned after UI implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-002 | P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-FR-001 | P02-FUE-SPEC-001 | AC-P02-FUE-001 | P02-FUE-TR-001 | P02-FUE-GAP-001 | widget | planned | `test/features/goal_autopilot/speaking_check_no_goal_guard_test.dart` | Planned after UI implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-003 | P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-FR-002 | P02-FUE-SPEC-002 | AC-P02-FUE-002 | P02-FUE-TR-002 | P02-FUE-GAP-002 | widget | planned | `test/features/goal_autopilot/speaking_check_sample_tasks_widget_test.dart` | Planned after UI implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-004 | P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-FR-002 | P02-FUE-SPEC-002 | AC-P02-FUE-002 | P02-FUE-TR-002 | P02-FUE-GAP-002 | integration | planned | `backend/src/test/java/com/speakeasy/goal/SpeakingDiagnosticTaskPolicyTest.java` | Planned after backend policy implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-005 | P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-FR-003 | P02-FUE-SPEC-003 | AC-P02-FUE-003 | P02-FUE-TR-003 | P02-FUE-GAP-003 | widget | planned | `test/features/goal_autopilot/speaking_check_recording_controls_test.dart` | Planned after UI implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-006 | P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-FR-003 | P02-FUE-SPEC-003 | AC-P02-FUE-003 | P02-FUE-TR-003 | P02-FUE-GAP-003 | widget | planned | `test/features/goal_autopilot/speaking_check_permission_fallback_test.dart` | Planned after UI implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-007 | P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUE-FR-004 | P02-FUE-SPEC-004 | AC-P02-FUE-004 | P02-FUE-TR-004 | P02-FUE-GAP-004 | contract | planned | `backend/src/test/java/com/speakeasy/goal/DiagnosticAudioUploadContractTest.java` | Planned after backend/API implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-008 | P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUE-FR-004 | P02-FUE-SPEC-004 | AC-P02-FUE-004 | P02-FUE-TR-004 | P02-FUE-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/goal/DiagnosticAudioUploadIdempotencyTest.java` | Planned after backend/API implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-009 | P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUE-FR-004 | P02-FUE-SPEC-004 | AC-P02-FUE-004 | P02-FUE-TR-004 | P02-FUE-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/goal/DiagnosticAudioSecurityAndDeleteTest.java` | Planned after backend/API implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-010 | P02-SI-008, P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUE-FR-005 | P02-FUE-SPEC-005 | AC-P02-FUE-005 | P02-FUE-TR-005 | P02-FUE-GAP-005 | unit | planned | `backend/src/test/java/com/speakeasy/goal/SpeakingDiagnosticQualityGateTest.java` | Planned after backend quality implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-011 | P02-SI-008, P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUE-FR-005 | P02-FUE-SPEC-005 | AC-P02-FUE-005 | P02-FUE-TR-005 | P02-FUE-GAP-005 | integration | planned | `backend/src/test/java/com/speakeasy/goal/SpeakingDiagnosticModePolicyTest.java` | Planned after backend mode implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-012 | P02-SI-008, P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUE-FR-005 | P02-FUE-SPEC-005 | AC-P02-FUE-005 | P02-FUE-TR-005 | P02-FUE-GAP-005 | widget | planned | `test/features/goal_autopilot/speaking_diagnostic_mode_downgrade_test.dart` | Planned after UI/backend mode implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-013 | P02-SI-008 | P02-PG-001, P02-PG-004, P02-PG-005 | P02-FUE-FR-006 | P02-FUE-SPEC-006 | AC-P02-FUE-006 | P02-FUE-TR-006 | P02-FUE-GAP-006 | contract | planned | `backend/src/test/java/com/speakeasy/goal/SpeakingDiagnosticTranscriptSourceTest.java` | Planned after AI/backend validation implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-014 | P02-SI-008 | P02-PG-001, P02-PG-004, P02-PG-005 | P02-FUE-FR-006 | P02-FUE-SPEC-006 | AC-P02-FUE-006 | P02-FUE-TR-006 | P02-FUE-GAP-006 | ai-eval | planned | `docs/ai_runtime/ai_eval_cases.md`; `backend/src/test/java/com/speakeasy/goal/FollowupESpeakingDiagnosticCandidateSchemaTest.java` | Planned after AI candidate implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-015 | P02-SI-008 | P02-PG-001, P02-PG-004, P02-PG-005 | P02-FUE-FR-006 | P02-FUE-SPEC-006 | AC-P02-FUE-006 | P02-FUE-TR-006 | P02-FUE-GAP-006 | ai-eval | planned | `backend/src/test/java/com/speakeasy/goal/FollowupESpeakingDiagnosticForbiddenFieldTest.java` | Planned after AI candidate implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-016 | P02-SI-008, P02-SI-009, P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-002 | P02-FUE-FR-007 | P02-FUE-SPEC-007 | AC-P02-FUE-007 | P02-FUE-TR-007 | P02-FUE-GAP-007 | integration | planned | `backend/src/test/java/com/speakeasy/goal/SpeakingDiagnosticResultHandoffTest.java` | Planned after diagnostic result implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-017 | P02-SI-008 | P02-PG-005 | P02-FUE-FR-008 | P02-FUE-SPEC-008 | AC-P02-FUE-008 | P02-FUE-TR-008 | P02-FUE-GAP-008 | widget | planned | `test/features/goal_autopilot/speaking_check_privacy_copy_test.dart` | Planned after UI privacy implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-018 | P02-SI-008 | P02-PG-005 | P02-FUE-FR-008 | P02-FUE-SPEC-008 | AC-P02-FUE-008 | P02-FUE-TR-008 | P02-FUE-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/goal/SpeakingDiagnosticDataGovernanceTest.java` | Planned after data-governance implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-019 | P02-SI-008 | P02-PG-005 | P02-FUE-FR-008 | P02-FUE-SPEC-008 | AC-P02-FUE-008 | P02-FUE-TR-008 | P02-FUE-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/account/AccountDeletionSpeakingDiagnosticCleanupTest.java` | Planned after account-deletion cleanup implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-020 | P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUE-FR-009 | P02-FUE-SPEC-009 | AC-P02-FUE-009 | P02-FUE-TR-009 | P02-FUE-GAP-009 | integration | planned | `backend/src/test/java/com/speakeasy/goal/SpeakingDiagnosticEntitlementDepthTest.java` | Planned after entitlement implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-021 | P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUE-FR-009 | P02-FUE-SPEC-009 | AC-P02-FUE-009 | P02-FUE-TR-009 | P02-FUE-GAP-009 | integration | planned | `backend/src/test/java/com/speakeasy/goal/SpeakingDiagnosticQuotaProviderFallbackTest.java` | Planned after quota/provider implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-022 | P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUE-FR-009 | P02-FUE-SPEC-009 | AC-P02-FUE-009 | P02-FUE-TR-009 | P02-FUE-GAP-009 | widget | planned | `test/features/goal_autopilot/speaking_diagnostic_provider_downgrade_test.dart` | Planned after provider downgrade UI implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-023 | P02-SI-007, P02-SI-008 | P02-PG-001..005 | P02-FUE-FR-010 | P02-FUE-SPEC-010 | AC-P02-FUE-010 | P02-FUE-TR-010 | P02-FUE-GAP-010 | release-check | planned | `scripts/check_p0_2_followup_e_traceability.py` | Planned after checker implementation starts | planned | N/A - implementation test planned |
| TC-P02-FUE-024 | P02-SI-007, P02-SI-008 | P02-PG-001..005 | P02-FUE-FR-010 | P02-FUE-SPEC-010 | AC-P02-FUE-010 | P02-FUE-TR-010 | P02-FUE-GAP-010 | release-check | planned | `docs/architecture/openapi/speakeasy-api.yaml`; `lib/generated/api/` | Planned after OpenAPI/generated-client source-of-truth update is approved | planned | N/A - implementation test planned |
| TC-P02-FUE-025 | P02-SI-007, P02-SI-008 | P02-PG-001..005 | P02-FUE-FR-010 | P02-FUE-SPEC-010 | AC-P02-FUE-010 | P02-FUE-TR-010 | P02-FUE-GAP-010 | release-check | planned | `scripts/check_p0_2_goal_autopilot_coverage.py`; reports; backend/Flutter regression suites | Planned after executable implementation and reports exist | planned | N/A - implementation test planned |
| TC-P02-FUE-026 | P02-SI-007, P02-SI-008 | P02-PG-001..005 | P02-FUE-FR-010 | P02-FUE-SPEC-010 | AC-P02-FUE-010 | P02-FUE-TR-010 | P02-FUE-GAP-010 | manual | planned | `docs/reports/quality_report.md` | Planned independent review after executable evidence exists | planned | N/A - implementation review planned |

## Planned Test Pyramid Notes
- Backend policy and API tests should own `audio_ref`, quality gate, diagnostic mode, candidate validation, retention, entitlement and idempotency behavior.
- Flutter widget tests should own user-visible entry, permission timing, recording controls, fallback labels, downgrade copy, privacy copy and stale/deleted state rendering.
- Flutter recording work must reuse the existing MVP/P0.1 audio capture service boundary where possible; Followup-E should add Speaking Check orchestration and trusted upload bridging, not a duplicate mic subsystem.
- AI eval tests should own candidate schema, forbidden fields, text-only acoustic claim rejection and raw payload rejection.
- Release-check tests should own traceability, OpenAPI/generated client drift, changed-code coverage, report evidence and independent review.
- Live provider tests are not required for Phase 3. Any later paid AI external evidence must remain a separate release gate.

## Coverage Gaps Before Implementation
| Gap | Handling |
| --- | --- |
| Test scripts and implementation may not exist or may later be reworked | All script paths above are planned targets only and must not be cited as passed until the implementation slice is executed and independently reviewed. |
| OpenAPI machine-readable schemas state | Markdown API contract is planning evidence; machine-readable OpenAPI/generated Dart drift remains planned until the implementation batch explicitly accepts it. |
| Native audio recording/platform permission behavior | Existing MVP/P0.1 recording capability should be reused; Followup-E still needs a Speaking Check upload bridge and device/manual gate before claiming native mic evidence. |
| Live provider ASR/scoring evidence is unavailable | Covered later by deterministic fallback/contract tests first; external provider evidence remains release-gated. |

## AC-to-TC Coverage Index
| AC | Stable TC IDs | Coverage status |
| --- | --- | --- |
| AC-P02-FUE-000 | TC-P02-FUE-000 | Planned |
| AC-P02-FUE-001 | TC-P02-FUE-001, TC-P02-FUE-002 | Planned |
| AC-P02-FUE-002 | TC-P02-FUE-003, TC-P02-FUE-004 | Planned |
| AC-P02-FUE-003 | TC-P02-FUE-005, TC-P02-FUE-006 | Planned |
| AC-P02-FUE-004 | TC-P02-FUE-007, TC-P02-FUE-008, TC-P02-FUE-009 | Planned |
| AC-P02-FUE-005 | TC-P02-FUE-010, TC-P02-FUE-011, TC-P02-FUE-012 | Planned |
| AC-P02-FUE-006 | TC-P02-FUE-013, TC-P02-FUE-014, TC-P02-FUE-015 | Planned |
| AC-P02-FUE-007 | TC-P02-FUE-016 | Planned |
| AC-P02-FUE-008 | TC-P02-FUE-017, TC-P02-FUE-018, TC-P02-FUE-019 | Planned |
| AC-P02-FUE-009 | TC-P02-FUE-020, TC-P02-FUE-021, TC-P02-FUE-022 | Planned |
| AC-P02-FUE-010 | TC-P02-FUE-023, TC-P02-FUE-024, TC-P02-FUE-025, TC-P02-FUE-026 | Planned |

## 下游执行边界
- Implementers must not rename or reuse TC-P02-FUE-000..026 for different behavior.
- When implementation starts, each planned test must be created, replaced with an equivalent lower-cost test, or explicitly retired with a replacement/retirement reason.
- Test Evidence must later cite TC ID, script path, command, result status and evidence report before any local completion claim.
- Phase 3 test planning does not close release, paid AI external evidence, native/store privacy evidence or Product Base merge blockers.
