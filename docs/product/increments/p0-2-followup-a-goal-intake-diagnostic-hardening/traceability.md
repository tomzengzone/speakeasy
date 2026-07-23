# P0.2 Followup-A Traceability：目标录入与诊断加固

## 状态
FR-001..009 implemented locally / release-gated - 本文件已补充 No-goal Explore Mode 代码和测试证据；Followup-A 本地证据完整覆盖 FR-001..009。该状态不代表 Followup-B/C/D 或完整 P0.2 release approval。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v1.3-p0.2-followup-a-xcb005-fact-boundary-regression |
| Last updated | 2026-06-11 |
| Owner | Product Manager Agent |
| Checker | Product Object Governance Check Agent / Documentation Governance / Independent Quality Review |
| Workflow state | requirements/spec/acceptance/test_cases/code/test evidence complete for FR-001..009 plus XCB-005 backend/Flutter/migration regression TC-P02-FUA-017..019；release still gated by Followup-B/C/D |

## 上游链路
```text
docs/product/stages/p0-2-training-memory.md
  -> docs/product/increments/p0-2-goal-diagnostic-foundation/
  -> docs/reports/quality_report.md local implementation residual blockers
  -> docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/definition.md
  -> docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/requirements.md
  -> docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/spec.md
  -> docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/acceptance.md
  -> docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/test_cases.md
  -> docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/traceability.md
```

## Full Traceability Matrix
| Trace Row ID | WP ID | Stage Scope ID | Policy Gate | Existing upstream row | FR | Spec | AC | TC | Contract Evidence | Code Evidence | Test Evidence | Review Gate | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUA-TR-000 | P02-FUA-WP-000 | P02-SI-007, P02-SI-008 | P02-PG-001..005 applicable subset | P02-DIAG-TR-001..007 | N/A - document setup | N/A - document setup | N/A - document setup | N/A - `git diff --check` and doc validation only | N/A - document scaffold | N/A - no code target | `git diff --check`; `python3 scripts/validate_governance_contracts.py` passed | Independent docs/path/trace review passed | Complete for Followup-A local scope |
| P02-FUA-TR-001 | P02-FUA-WP-001 | P02-SI-007 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-DIAG-TR-001 | P02-FUA-FR-001 | P02-FUA-SPEC-001 | AC-P02-FUA-001 | TC-P02-FUA-001, TC-P02-FUA-002 | Existing OpenAPI `GoalAutopilotGoalRequest` fields cover goal type, target score/ability, deadline, daily minutes and intensity | `GoalAutopilotPanel` editable form; `GoalAutopilotAdapter.createGoal`; production panel does not call `createDefaultGoal()` | `flutter test ...goal_autopilot_adapter_test.dart` passed; TC-P02-FUA-001/002 | UX/API payload review passed locally | Implemented locally / release-gated |
| P02-FUA-TR-002 | P02-FUA-WP-002 | P02-SI-007 | P02-PG-001, P02-PG-002 | P02-DIAG-TR-002 | P02-FUA-FR-002 | P02-FUA-SPEC-002 | AC-P02-FUA-002 | TC-P02-FUA-005, TC-P02-FUA-006, TC-P02-FUA-007 | Existing OpenAPI `SupportedGoalMatrixDecision` covers status, reason, limitation, rubric and content coverage | `GoalAutopilotSummary` parses support decision; `GoalAutopilotPanel` gates supported/partial/unsupported states | `flutter test ...goal_autopilot_adapter_test.dart` passed; TC-P02-FUA-005/006/007 | Product claim guard review passed locally | Implemented locally / release-gated |
| P02-FUA-TR-003 | P02-FUA-WP-003 | P02-SI-008 | P02-PG-001, P02-PG-005 | P02-DIAG-TR-003 | P02-FUA-FR-003 | P02-FUA-SPEC-003 | AC-P02-FUA-003 | TC-P02-FUA-003 | Existing OpenAPI `DiagnosticSampleInput` covers sample ref, transcript, audio ref and duration | `GoalDiagnosticSampleInput`; `GoalAutopilotPanel` three sample fields; adapter filters empty samples | `flutter test ...goal_autopilot_adapter_test.dart` passed; TC-P02-FUA-003 | Diagnostic reliability review passed locally | Implemented locally / release-gated |
| P02-FUA-TR-004 | P02-FUA-WP-004 | P02-SI-008 | P02-PG-001, P02-PG-004, P02-PG-005 | P02-DIAG-TR-003, P02-DIAG-TR-004, P02-DIAG-TR-005 | P02-FUA-FR-004 | P02-FUA-SPEC-004 | AC-P02-FUA-004 | TC-P02-FUA-004 | Existing OpenAPI `DiagnosticAssessment` and AI runtime candidate boundary remain source of accepted facts | Adapter sends candidate sample fields only and does not synthesize audio refs; Flutter displays accepted summary facts only | `flutter test ...goal_autopilot_adapter_test.dart` passed; TC-P02-FUA-004 | AI/runtime and data-governance review passed locally | Implemented locally / release-gated |
| P02-FUA-TR-005 | P02-FUA-WP-005 | P02-SI-007, P02-SI-009 | P02-PG-003, P02-PG-005 | P02-DIAG-TR-001, P02-PLAN-TR-002 | P02-FUA-FR-005 | P02-FUA-SPEC-005 | AC-P02-FUA-005 | TC-P02-FUA-009 | Existing OpenAPI `GoalProfile.revision`, plan/action statuses and `GenerateGoalPlanRequest.force_replan` cover revision/stale visibility | Summary model parses revision/status; panel blocks stale action execution and exposes replan recovery only | `flutter test ...goal_autopilot_adapter_test.dart` passed; TC-P02-FUA-009 | Downstream planner compatibility review passed locally | Implemented locally / release-gated |
| P02-FUA-TR-006 | P02-FUA-WP-006 | P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-002, P02-PG-004, P02-PG-005 | P02-DIAG-TR-002, P02-DIAG-TR-004 | P02-FUA-FR-006 | P02-FUA-SPEC-006 | AC-P02-FUA-006 | TC-P02-FUA-006, TC-P02-FUA-007, TC-P02-FUA-008 | Existing OpenAPI diagnostic and forecast `GoalClaimGuard` fields cover official-score and completion claims | Summary model parses diagnostic/forecast claim guards; panel sanitizes guarded limitation copy and blocks official/guaranteed language | `flutter test ...goal_autopilot_adapter_test.dart` passed; TC-P02-FUA-006/007/008 | Commercial/product claim review passed locally | Implemented locally / release-gated |
| P02-FUA-TR-007 | P02-FUA-WP-007 | P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | All Followup-A rows | P02-FUA-FR-007 | P02-FUA-SPEC-007 | AC-P02-FUA-007 | TC-P02-FUA-010, TC-P02-FUA-011, TC-P02-FUA-012 | QA scripts and existing backend regression contracts; no new API field was required | Changed Flutter tests; no backend code change | Backend regression/performance passed; coverage script passed backend line 96.3%, branch 88.6%, Flutter line 90.9% | QA and performance review passed locally | Implemented locally / release-gated |
| P02-FUA-TR-008 | P02-FUA-WP-008 | P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | All Followup-A rows | P02-FUA-FR-008 | P02-FUA-SPEC-008 | AC-P02-FUA-008 | TC-P02-FUA-013 | Reporting and documentation contracts only | `docs/reports/quality_report.md`, `docs/reports/test_report.md`, `docs/reports/implementation_report.md`; strengthened traceability script | `python3 scripts/check_p0_2_goal_autopilot_traceability.py` passed; `python3 scripts/validate_governance_contracts.py` passed | Independent final review passed locally | Implemented locally / release-gated |
| P02-FUA-TR-009 | P02-FUA-WP-009 | P02-SI-007 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-005 | P02-DIAG-TR-001 | P02-FUA-FR-009 | P02-FUA-SPEC-009 | AC-P02-FUA-009 | TC-P02-FUA-014, TC-P02-FUA-015, TC-P02-FUA-016 | Existing OpenAPI can represent absence by no active goal/no goal-autopilot requests; no new backend field required | `GoalAutopilotPanel` renders `No active goal`, `Set a goal`, `Explore practice`, `Try a sample drill`; `Set a goal` opens `_GoalSetup` without transport; `_ExplorePractice` renders ordinary sample feedback; production browse path does not call `createDefaultGoal()` or goal-autopilot APIs beyond initial summary lookup | `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` passed; TC-P02-FUA-014/015/016; `flutter analyze ...` passed; coverage passed at Flutter line 90.9% | Product/UX/data-governance review passed locally | Implemented locally / release-gated |
| P02-FUA-TR-010 | P02-FUA-WP-004 | P02-SI-008 | P02-PG-001, P02-PG-004, P02-PG-005 | P02-DIAG-TR-003, XCB-001, XCB-002, XCB-005, XCB-006 | P02-FUA-FR-004 | P02-FUA-SPEC-004 | AC-P02-FUA-004, AC-P02-FUA-008 | TC-P02-FUA-017, TC-P02-FUA-019 | `docs/architecture/openapi/speakeasy-api.yaml` requires goal diagnostic audio refs to remain on `POST /goal-autopilot/goals`; `docs/architecture/api_contract.md` and `docs/process/cross_cutting_boundary_registry.md` require trusted `media://audio/...` through Media/AI Gateway | `GoalAutopilotService.validateDiagnosticAudioRefs`; `AiGatewayService.validateTrustedAudioRef`; `GoalAutopilotDataExportRetentionTest`; `GoalAutopilotTelemetryTest` | TC-P02-FUA-017/019 passed with backend Maven command; evidence `docs/reports/test_report.md#2026-06-11-p02-xcb005-goal-autopilot-fact-boundaries` | Independent audio boundary review passed locally; no Followup-E completion claim | Implemented locally / release-gated |
| P02-FUA-TR-011 | P02-FUA-WP-005 | P02-SI-007, P02-SI-009 | P02-PG-003, P02-PG-005 | P02-DIAG-TR-001, P02-PLAN-TR-002, XCB-005, XCB-006 | P02-FUA-FR-005 | P02-FUA-SPEC-005 | AC-P02-FUA-005, AC-P02-FUA-008 | TC-P02-FUA-018 | `POST /goal-autopilot/goals` requires `Idempotency-Key`; `docs/architecture/api_contract.md` defines replay/conflict behavior, Flutter production header propagation and single server-owned goal chain | `GoalAutopilotGoalIdempotency`; `GoalAutopilotGoalIdempotencyRepository`; `GoalAutopilotService.createGoal`; `UserAccountRepository.findByIdForUpdate`; `V202606110001__p0_2_xcb005_goal_autopilot_fact_boundaries.sql`; `FoundationMigrationTest#xcb005GoalProfileUniqueMigrationPrunesLegacyDuplicateRows`; `GoalAutopilotAdapter.createGoal`; `ApiClient.createGoalAutopilotGoal`; `AccountDeletionService` | TC-P02-FUA-018 passed with `GoalAutopilotControllerTest,FoundationMigrationTest` and `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart`; evidence `docs/reports/test_report.md#2026-06-11-p02-xcb005-goal-autopilot-fact-boundaries` | Independent idempotency review rerun after P1 fixes; final verdict recorded in quality report | Implemented locally / release-gated |

## Bidirectional Coverage Index
| Direction | Coverage |
| --- | --- |
| Stage scope -> WP | P02-SI-007 maps to WP-001, WP-002, WP-005, WP-006, WP-007, WP-008, WP-009；P02-SI-008 maps to WP-003, WP-004, WP-006, WP-007, WP-008；P02-SI-009 maps to WP-005 only as stale-plan visibility, not Followup-B implementation |
| WP -> FR | P02-FUA-WP-001..009 each map to exactly one primary FR; WP-000 is documentation setup only |
| FR -> Spec -> AC -> TC | P02-FUA-FR-001..009 each has a primary P02-FUA-SPEC, AC-P02-FUA and at least one TC-P02-FUA；XCB-005 regression rows add TC-P02-FUA-017..019 without introducing new FR IDs |
| TC -> AC | TC-P02-FUA-001..019 all reference at least one AC; AC-P02-FUA-001..009 all have primary TC coverage |
| Contract -> Code | Existing OpenAPI covers baseline Followup-A behavior; XCB-005 updates the `POST /goal-autopilot/goals` contract with trusted diagnostic `audio_ref`, required `Idempotency-Key`, replay/conflict behavior and single-chain persistence |
| Code -> Test | Flutter code targets map to widget/adapter/model tests; backend code changes trigger backend regression, coverage and performance gates; FR-009 code maps to TC-P02-FUA-014..016 and passed locally；XCB-005 backend/Flutter/migration code maps to TC-P02-FUA-017..019 and passed locally |

## Gap Register
| Gap ID | Gap | Trace Row | Current handling |
| --- | --- | --- | --- |
| P02-FUA-GAP-001 | Flutter setup previously started a fixed default goal instead of editable GoalProfile form. | P02-FUA-TR-001 | Closed locally by editable form and TC-P02-FUA-001/002. |
| P02-FUA-GAP-002 | Adapter previously hard-coded diagnostic sample transcripts. | P02-FUA-TR-003, P02-FUA-TR-004 | Closed locally by `GoalDiagnosticSampleInput`, empty filtering and TC-P02-FUA-003/004. |
| P02-FUA-GAP-003 | Flutter summary previously under-parsed support, diagnostic, revision and claim guard fields. | P02-FUA-TR-002, P02-FUA-TR-005, P02-FUA-TR-006 | Closed locally by expanded summary model and TC-P02-FUA-005..009. |
| P02-FUA-GAP-004 | Unsupported/partial/low-confidence action gating was not fully visible in Flutter. | P02-FUA-TR-002, P02-FUA-TR-006 | Closed locally by UI gating and TC-P02-FUA-006/007/008. |
| P02-FUA-GAP-005 | Followup-A execution evidence and coverage evidence did not exist. | P02-FUA-TR-007, P02-FUA-TR-008 | Closed locally by executed evidence addendum and coverage script result. |
| P02-FUA-GAP-006 | No active goal previously routed directly to editable form and lacked Explore Mode no-fact boundary. | P02-FUA-TR-009 | Closed locally by No active goal empty state, Set-a-goal transition, Explore practice isolation and TC-P02-FUA-014..016. |
| P02-FUA-GAP-007 | Goal diagnostic `audio_ref` could remain as an untrusted opaque input unless backend reused the XCB-001/XCB-002 media boundary. | P02-FUA-TR-010 | Closed locally by `AiGatewayService.validateTrustedAudioRef` in goal intake, negative/positive backend tests, redacted export and telemetry non-leakage checks. |
| P02-FUA-GAP-008 | Goal create/revision lacked API idempotency and data-layer single-chain protection. | P02-FUA-TR-011 | Closed locally by Flutter `Idempotency-Key` propagation, backend goal replay table, user-level lock, duplicate-profile pruning before `goal_profiles.user_id` unique constraint, account deletion coverage and TC-P02-FUA-018. |

## Remaining Non-Followup-A Gates
- Followup-B pause/resume, notification scheduler, missed-day recovery and memory queue hardening remain open.
- Followup-C Queue/Wiki progress propagation and checkpoint/forecast surface hardening remain open.
- Followup-D commercial/release/data export/telemetry/Product Base approval remains open.

## Traceability Independent Review
Result: pass after implementation evidence update. P02-FUA-TR-009 maps WP-009 -> FR-009 -> SPEC-009 -> AC-009 -> TC-014/015/016 with real code and passed test evidence. XCB-005 P02-FUA-TR-010/011 maps trusted diagnostic `audio_ref`, goal-create idempotency, Flutter header propagation and migration upgrade safety to TC-P02-FUA-017..019. Bidirectional requirements-code-test traceability is 100% for Followup-A FR-001..009 plus XCB-005 regression rows; release remains gated by Followup-B/C/D.
