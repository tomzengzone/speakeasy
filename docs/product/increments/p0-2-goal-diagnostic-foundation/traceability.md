# P0.2 Traceability：目标画像与诊断基础

## 状态
Implementation vertical slice / local tests and coverage passed - requirements、spec、acceptance、TC、domain/API/AI/UX contracts、本地 deterministic backend/frontend 代码、功能/性能测试和覆盖率证据已建立；商业 paid AI / release 外部门禁未关闭。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v0.2-p0.2-diagnostic-foundation-local-implementation |
| Last updated | 2026-06-04 |
| Owner | Product Manager Agent |
| Workflow state | Domain/API/AI/UX contracts complete；local deterministic backend/frontend vertical slice implemented and tested；coverage gate passed by script |

## 上游链路
```text
docs/product/stages/p0-2-training-memory.md
  -> docs/product/increments/p0-2-goal-diagnostic-foundation/definition.md
  -> docs/product/increments/p0-2-goal-diagnostic-foundation/requirements.md
  -> docs/product/increments/p0-2-goal-diagnostic-foundation/spec.md
  -> docs/product/increments/p0-2-goal-diagnostic-foundation/acceptance.md
  -> docs/product/increments/p0-2-goal-diagnostic-foundation/test_cases.md
  -> docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md
```

## Full Traceability Matrix
| Traceability Row ID | Stage Scope ID | Policy Gate | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P02-DIAG-TR-001 | P02-SI-007 | P02-PG-001, P02-PG-005 | p0-2-goal-diagnostic-foundation | P02-DIAG-FR-001 GoalProfile 事实源 | P02-DIAG-SPEC-001 | AC-P02-DIAG-001 | `docs/domain/domain_schema.md`; `docs/architecture/openapi/speakeasy-api.yaml`; `docs/ux/screen_spec.md` | `GoalProfile`, `GoalProfileRepository`, `GoalAutopilotService.createGoal`, `GoalAutopilotController.createGoal`, `GoalAutopilotAdapter.createDefaultGoal`, `GoalAutopilotPanel` | `GoalAutopilotControllerTest.tcP02Diag001CreatesGoalDiagnosticAndClaimGuardSourceOfTruth`; Flutter `goal_autopilot_adapter_test`; coverage script | Not release scope yet | Implemented / local tests and coverage passed | Backend changed-code line 96.3% / branch 88.6%; Flutter feature line 82.1% |
| P02-DIAG-TR-002 | P02-SI-007 | P02-PG-002 | p0-2-goal-diagnostic-foundation | P02-DIAG-FR-002 SupportedGoalMatrix | P02-DIAG-SPEC-002 | AC-P02-DIAG-002 | Domain/API SupportedGoalMatrix decision in `domain_schema.md` and OpenAPI `SupportedGoalMatrixDecision` | `GoalAutopilotService.decideSupport`; unsupported fail-closed in `generatePlan` | `GoalAutopilotControllerTest.tcP02Policy001UnsupportedGoalFailsClosedWithoutFullPlanOrEta`; `tcP02Diag003ServiceCoversGoalBoundaryAndLowConfidenceBranches` | Not release scope yet | Implemented / local tests and coverage passed | Coverage gate passed by `scripts/check_p0_2_goal_autopilot_coverage.py` |
| P02-DIAG-TR-003 | P02-SI-008 | P02-PG-001, P02-PG-005 | p0-2-goal-diagnostic-foundation | P02-DIAG-FR-003 初始口语诊断 | P02-DIAG-SPEC-003 | AC-P02-DIAG-003 | `docs/ai_runtime/llm_output_schema.md` P0.2 diagnostic candidate schema；OpenAPI diagnostic DTO | `GoalDiagnosticAssessment`, `GoalAutopilotService.buildDiagnostic` | `GoalAutopilotControllerTest.tcP02Diag001CreatesGoalDiagnosticAndClaimGuardSourceOfTruth` | Paid AI evidence remains separate；local deterministic fallback only | Implemented locally / paid AI external gate open | Paid AI provider evidence not closed |
| P02-DIAG-TR-004 | P02-SI-008 | P02-PG-001 | p0-2-goal-diagnostic-foundation | P02-DIAG-FR-004 Rubric 校准与置信度 | P02-DIAG-SPEC-004 | AC-P02-DIAG-004 | AI/runtime claim guard schema；OpenAPI `GoalClaimGuard`, `GoalConfidenceBand` | `GoalAutopilotService.buildDiagnostic`, `GoalAutopilotService.upsertForecast` | `GoalAutopilotControllerTest.tcP02Diag001CreatesGoalDiagnosticAndClaimGuardSourceOfTruth`; `tcP02Policy001UnsupportedGoalFailsClosedWithoutFullPlanOrEta`; `tcP02Diag003ServiceCoversGoalBoundaryAndLowConfidenceBranches` | Not release scope yet | Implemented / local tests and coverage passed | Coverage gate passed |
| P02-DIAG-TR-005 | P02-SI-008 | P02-PG-005 | p0-2-goal-diagnostic-foundation | P02-DIAG-FR-005 弱项分解 | P02-DIAG-SPEC-005 | AC-P02-DIAG-005 | Domain WeaknessTag and AI candidate schema | `GoalAutopilotService.buildDiagnostic` structured `WeaknessTagView`; `GoalDiagnosticAssessment.weaknessTagsJson` | `GoalAutopilotControllerTest.tcP02Diag001CreatesGoalDiagnosticAndClaimGuardSourceOfTruth` | Not release scope yet | Implemented / local tests and coverage passed | Coverage gate passed |
| P02-DIAG-TR-006 | P02-SI-003 | P02-PG-001 | p0-2-goal-diagnostic-foundation | P02-DIAG-FR-006 L0-L5 mastery 初始化 | P02-DIAG-SPEC-006 | AC-P02-DIAG-006 | Domain `MasteryInitialState`; migration `goal_mastery_initial_states` | `GoalMasteryInitialState`, `GoalMasteryInitialStateRepository`, `GoalAutopilotService.saveInitialMasteryStates` | `GoalAutopilotControllerTest.tcP02Diag001CreatesGoalDiagnosticAndClaimGuardSourceOfTruth` asserts four `initial_from_diagnostic` rows | Not release scope yet | Implemented / local tests passed | Later L0-L5 promotion still belongs to memory policy evidence |
| P02-DIAG-TR-007 | P02 policy gates | P02-PG-001, P02-PG-002, P02-PG-004, P02-PG-005 | p0-2-goal-diagnostic-foundation | P02-DIAG-FR-007 Policy gate、商业与数据治理 | P02-DIAG-SPEC-007 | AC-P02-DIAG-007 | Domain/API/AI/UX policy gates complete；OpenAPI P0.2 implementation-level boundary | Claim guard, supported/partial/unsupported fail-closed, redacted `AuditLog`, `AccountDeletionService` purges `goal_*` tables | `GoalAutopilotControllerTest.tcP02Data001AccountDeletionPurgesGoalAutopilotFacts`; `tcP02Data003DeletionServiceCoversRequestedAndDeletedAccountBranches`; `GoalAutopilotPerformanceTest.tcP02Perf001GoalAutopilotLocalBudgetsStayUnderP95Targets`; coverage script | P0 commercial / paid AI gates remain separate | Implemented locally / release gated | Coverage/performance passed；paid AI/commercial external gates open |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| P02-DIAG-GAP-001 | GoalProfile domain/API/UX contracts missing. | P02-DIAG-TR-001 | Domain/API/UX | Closed by domain/API/UX + backend/frontend implementation |
| P02-DIAG-GAP-002 | SupportedGoalMatrix content/rubric coverage contract missing. | P02-DIAG-TR-002 | Product/Content/Domain | Closed locally by deterministic support matrix；future content expansion remains P1/P2 |
| P02-DIAG-GAP-003 | Diagnostic AI/runtime schema, confidence and rubric calibration missing. | P02-DIAG-TR-003..005 | AI Runtime/Domain/QA | Closed for local deterministic candidate boundary；paid AI external evidence remains release gate |
| P02-DIAG-GAP-004 | Initial mastery domain policy missing. | P02-DIAG-TR-006 | Domain/QA | Closed by `goal_mastery_initial_states` |
| P02-DIAG-GAP-005 | Commercial entitlement/cost policy for diagnostic missing. | P02-DIAG-TR-007 | Commercial/Backend/Ops | Partially closed by no-paid-AI deterministic fallback；P0 commercial gates remain external |
| P02-DIAG-GAP-006 | Diagnostic data governance contract missing. | P02-DIAG-TR-007 | Security/Data Governance | Closed locally by redacted audit and account deletion purge |
| P02-DIAG-GAP-007 | Performance and >=80% code coverage gate not implemented. | P02-DIAG-TR-007 | QA/Engineering | Closed: performance passed；coverage gate passed by `scripts/check_p0_2_goal_autopilot_coverage.py` |
| P02-DIAG-GAP-008 | Executed traceability evidence missing. | P02-DIAG-TR-001..007 | QA | Closed for local test and coverage evidence |

## Completion Gate
This increment cannot be implementation-complete unless:
- every P02-DIAG-FR maps to at least one AC and TC;
- every applicable P02-PG gate has contract, code and test evidence;
- changed code coverage is >=80% for line and branch coverage;
- performance budgets in AC-P02-DIAG-007 pass;
- test evidence includes TC ID, script path, command, result and report link.
