# P0.2 Traceability：自动带练、进度预测与周期复测

## 状态
Implementation vertical slice / local tests and coverage passed - requirements、spec、acceptance、TC、domain/API/AI/UX contracts、本地 deterministic backend/frontend 代码、功能/性能测试和覆盖率证据已建立；通知/商业 release 外部门禁未关闭。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v0.2-p0.2-autopilot-progress-checkpoint-local-implementation |
| Last updated | 2026-06-04 |
| Owner | Product Manager Agent |
| Workflow state | Domain/API/AI/UX contracts complete；local no-choice autopilot/forecast/checkpoint slice implemented and tested；coverage gate passed by script |

## 上游链路
```text
docs/product/stages/p0-2-training-memory.md
  -> docs/product/increments/p0-2-autopilot-progress-checkpoint/definition.md
  -> docs/product/increments/p0-2-autopilot-progress-checkpoint/requirements.md
  -> docs/product/increments/p0-2-autopilot-progress-checkpoint/spec.md
  -> docs/product/increments/p0-2-autopilot-progress-checkpoint/acceptance.md
  -> docs/product/increments/p0-2-autopilot-progress-checkpoint/test_cases.md
  -> docs/product/increments/p0-2-autopilot-progress-checkpoint/traceability.md
```

## Full Traceability Matrix
| Traceability Row ID | Stage Scope ID | Policy Gate | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P02-AUTO-TR-001 | P02-SI-010 | P02-PG-001, P02-PG-002, P02-PG-003 | p0-2-autopilot-progress-checkpoint | P02-AUTO-FR-001 Autopilot 输入契约 | P02-AUTO-SPEC-001 | AC-P02-AUTO-001 | Domain/API/OpenAPI `AutopilotAction` contract | `GoalAutopilotService.nextAction`, `requireDailyPlan`, support/stale fail-closed; Flutter adapter reads backend facts | Backend `tcP02PlanAndAuto001...`; `tcP02Auto002CoversNoPlanInvalidOutcomeSkipDeferAndLowConfidenceCheckpoint`; Flutter adapter path/summary/action tests | Not release scope yet | Implemented / local tests and coverage passed | Coverage gate passed |
| P02-AUTO-TR-002 | P02-SI-010 | P02-PG-003 | p0-2-autopilot-progress-checkpoint | P02-AUTO-FR-002 No-choice daily execution | P02-AUTO-SPEC-002 | AC-P02-AUTO-002 | UX/API no-choice action contract | `GoalPlanItem` active item, `AutopilotAction`, `GoalAutopilotPanel` single Done/Generate primary action | Backend next-action test; Flutter panel widget test; Flutter adapter action completion test | Not release scope yet | Implemented / local tests and coverage passed | Coverage gate passed |
| P02-AUTO-TR-003 | P02-SI-010 | P02-PG-003, P02-PG-005 | p0-2-autopilot-progress-checkpoint | P02-AUTO-FR-003 用户控制、暂停和恢复 | P02-AUTO-SPEC-003 | AC-P02-AUTO-003 | Domain/UX user-control fields and recovery signal | Goal intake stores quiet hours/notification consent; `completeAction` supports skipped/deferred recovery; `PlanUpdateSignal.recovery_replan` | Backend complete action and performance tests | Notification platform permission not release-implemented | Partial local implementation | Pause/resume endpoint and notification scheduling remain future hardening |
| P02-AUTO-TR-004 | P02-SI-012 | P02-PG-001, P02-PG-002 | p0-2-autopilot-progress-checkpoint | P02-AUTO-FR-004 ProgressForecast | P02-AUTO-SPEC-004 | AC-P02-AUTO-004 | Domain/API/AI `ProgressForecast` and claim guard contracts | `GoalProgressForecast`, `GoalAutopilotService.upsertForecast`, OpenAPI `GET /goal-autopilot/forecast` | Backend diagnostic, unsupported, checkpoint, medium/low confidence and performance tests | Not release scope yet | Implemented / local tests and coverage passed | Coverage gate passed |
| P02-AUTO-TR-005 | P02-SI-013 | P02-PG-001, P02-PG-002 | p0-2-autopilot-progress-checkpoint | P02-AUTO-FR-005 OutcomeCheckpoint | P02-AUTO-SPEC-005 | AC-P02-AUTO-005 | Domain/API/AI/UX checkpoint contract | `GoalOutcomeCheckpoint`, `GoalAutopilotService.submitCheckpoint`, plan stale signal | `GoalAutopilotControllerTest.tcP02AutoCheckpoint001CheckpointUpdatesForecastAndStalesPlan`; Flutter checkpoint button transport covered | Paid AI evidence remains separate | Implemented locally / paid AI gate open | External scoring/checkpoint provider evidence open |
| P02-AUTO-TR-006 | P02-SI-006 | P02-PG-005 | p0-2-autopilot-progress-checkpoint | P02-AUTO-FR-006 Goal progress surfaces | P02-AUTO-SPEC-006 | AC-P02-AUTO-006 | UX screen spec; API summary projection | `GoalAutopilotPanel` mounted in `SpeakEasyHomePage`; `GoalAutopilotAdapter.loadSummary`; generated path registry | Flutter widget test renders next action; analyzer passed | Not release scope yet | Implemented for home surface | Queue/Wiki surface propagation remains future expansion |
| P02-AUTO-TR-007 | P02 policy gates | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | p0-2-autopilot-progress-checkpoint | P02-AUTO-FR-007 Commercial、claim 和数据治理 | P02-AUTO-SPEC-007 | AC-P02-AUTO-007 | P02 policy gates; OpenAPI claim/data boundary | Claim guard false for official score; deterministic no-paid-AI fallback; redacted audit; account deletion purge | Backend unsupported, deletion, checkpoint tests | P0 commercial / paid AI gates remain separate | Implemented locally / release gated | Cost telemetry and release evidence open |
| P02-AUTO-TR-008 | P02 policy gates | P02-PG-003, P02-PG-004 | p0-2-autopilot-progress-checkpoint | P02-AUTO-FR-008 性能、覆盖率和运营门禁 | P02-AUTO-SPEC-008 | AC-P02-AUTO-008 | QA/performance/ops contracts complete | `GoalAutopilotPerformanceTest`; Flutter analyzer/test/coverage; API contract gate; coverage script | backend P0.2 test command passed; `flutter test`; `flutter analyze`; `npm run check:api-contract`; `python3 scripts/check_p0_2_goal_autopilot_coverage.py` passed | Not release scope yet | Performance/tests/coverage passed | Backend changed-code line 96.3% / branch 88.6%; Flutter feature line 82.1% |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| P02-AUTO-GAP-001 | Autopilot input domain/API contracts missing. | P02-AUTO-TR-001 | Domain/API | Closed locally |
| P02-AUTO-GAP-002 | No-choice daily execution UX/API contracts missing. | P02-AUTO-TR-002 | UX/API/Frontend | Closed locally |
| P02-AUTO-GAP-003 | User control, notification and recovery policy missing. | P02-AUTO-TR-003 | UX/Domain/QA | Partially closed: skip/defer/quiet-hours fields local；pause/resume endpoint and notification scheduling open |
| P02-AUTO-GAP-004 | ProgressForecast domain/API/AI contracts missing. | P02-AUTO-TR-004 | Domain/API/AI Runtime | Closed locally |
| P02-AUTO-GAP-005 | OutcomeCheckpoint domain/API/AI/UX contracts missing. | P02-AUTO-TR-005 | Domain/API/AI Runtime/UX | Closed locally；external provider evidence open |
| P02-AUTO-GAP-006 | Goal progress surface UX/API projection contract missing. | P02-AUTO-TR-006 | UX/API/Frontend | Closed for home surface；queue/Wiki propagation future |
| P02-AUTO-GAP-007 | Commercial entitlement/cost policy for autopilot/checkpoint missing. | P02-AUTO-TR-007 | Commercial/Backend/Ops | Partially closed by deterministic no-paid-AI fallback；P0 commercial gates remain |
| P02-AUTO-GAP-008 | Autopilot data governance and notification consent contract missing. | P02-AUTO-TR-007 | Security/Data Governance | Closed locally for persisted P0.2 facts; notification consent scheduling not release-implemented |
| P02-AUTO-GAP-009 | Performance and >=80% code coverage gate not implemented. | P02-AUTO-TR-008 | QA/Engineering | Closed: performance passed；coverage gate passed by `scripts/check_p0_2_goal_autopilot_coverage.py` |
| P02-AUTO-GAP-010 | Executed traceability evidence missing. | P02-AUTO-TR-001..008 | QA | Closed for local functional/performance/coverage evidence |

## Completion Gate
This increment cannot be implementation-complete unless:
- every P02-AUTO-FR maps to at least one AC and TC;
- P02-SI-006, P02-SI-010, P02-SI-012 and P02-SI-013 are covered;
- every applicable P02-PG gate has contract, code and test evidence;
- changed code coverage is >=80% for line and branch coverage;
- performance budgets in AC-P02-AUTO-008 pass;
- rollout evidence includes feature flag, kill switch, telemetry and blocked commercial/paid AI gates.
