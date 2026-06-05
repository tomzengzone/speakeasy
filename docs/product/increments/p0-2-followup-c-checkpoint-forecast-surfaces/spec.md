# P0.2 Followup-C Spec：周期复测、预测与多产品面加固

## 状态
S001 forecast hardening locally implemented and tested / S002-S007 implementation gated - 本文件把 Followup-C requirements 下沉为可验收的行为规格，并建立 S000-S007 slice routing。S000 文档链和实现前契约规划已通过验证；S001 已完成 ProgressForecast domain/API/OpenAPI/AI fallback 合同、后端代码和 TC-P02-FUC-001..003 测试执行；S002-S007 代码、契约更新、测试执行、coverage、performance 和 release evidence 均未开始。Followup-C is not release-ready；Product Base merge is not approved。

## 上游引用
- Increment definition：`docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/definition.md`
- Increment requirements：`docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/requirements.md`
- WP traceability scaffold：`docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/traceability.md`
- Active stage：`docs/product/stages/p0-2-training-memory.md`
- Upstream autopilot design：`docs/product/increments/p0-2-autopilot-progress-checkpoint/`
- Followup-B implementation boundary：`docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`

## 规格假设和依赖
- Followup-C 只加固 ProgressForecast、OutcomeCheckpoint、checkpoint-to-plan update、backend projection 和 Home/Queue/Wiki surface propagation。
- Forecast、checkpoint、projection 和 surface copy 必须使用产品内进度语言，不得宣称官方考试认证、保证分数或 guaranteed achievement。
- Surface UI 只能渲染 backend projection 或同源 backend facts；Flutter 不得重新计算 final goal state、ETA、goal complete 或 claim guard。
- 本规格只描述所需合同影响；domain/API/OpenAPI/UX/AI runtime 契约必须在后续独立步骤中更新并审核。

## Spec Trace IDs
| Spec ID | Slice ID | Stage Scope ID | Policy Gate | Requirement ID | Spec area |
| --- | --- | --- | --- | --- | --- |
| P02-FUC-SPEC-000 | P02-FUC-S000 | P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-FUC-FR-000 | S000 document chain and slice routing |
| P02-FUC-SPEC-001 | P02-FUC-S001 | P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-FUC-FR-001 | ProgressForecast model hardening |
| P02-FUC-SPEC-002 | P02-FUC-S002 | P02-SI-013 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-FUC-FR-002 | Checkpoint cadence and task library |
| P02-FUC-SPEC-003 | P02-FUC-S003 | P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-003 | P02-FUC-FR-003 | Checkpoint-to-plan update |
| P02-FUC-SPEC-004 | P02-FUC-S004 | P02-SI-006 | P02-PG-003, P02-PG-005 | P02-FUC-FR-004 | Backend goal-progress projection |
| P02-FUC-SPEC-005 | P02-FUC-S005 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-005 | P02-FUC-FR-005 | Home/Queue/Wiki surface propagation |
| P02-FUC-SPEC-006 | P02-FUC-S006 | P02-SI-006 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUC-FR-006 | Surface deletion/unavailable downgrade |
| P02-FUC-SPEC-007 | P02-FUC-S007 | P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-FUC-FR-007 | Automated tests, performance, coverage and review gates |

## Contract Boundary Decision
Followup-C requires downstream contract updates, but S000 does not update those contracts.

Required downstream contract work:
- Domain model：`ProgressForecastExplanation`、`CheckpointCadenceDecision`、`CheckpointTaskDefinition`、`CheckpointResultUpdate`、`GoalProgressProjection`、`GoalProgressSurfaceFragment` and surface downgrade metadata if existing objects are insufficient.
- API/OpenAPI：forecast detail/explanation, checkpoint task library or due task endpoint, checkpoint submit result, projection read endpoint, and surface projection fragments if existing `/goal-autopilot/summary` cannot safely serve all surfaces.
- AI runtime schema：checkpoint feedback and forecast explanation candidate-only schema; AI output must not persist final goal completion, official score equivalence, ETA guarantee, commercial entitlement facts or surface projection facts, and forecast/checkpoint AI explanation must define quota/cost fallback.
- UX screen spec：forecast explanation, checkpoint due/result, Home goal progress, expression queue goal-progress fragment, personal Wiki goal-progress fragment, unavailable/deleted/unsupported/low-confidence states.
- QA/checker：dedicated Followup-C traceability checker or equivalent release-check command.

If implementation discovers a missing contract field, implementation must stop and route the relevant contract update before code continues.

## Implementation Slice Routing
Followup-C implementation must proceed by routed slice. Later slices may consume earlier facts, but they must not mark Followup-C complete until their own AC/TC, contract evidence, code evidence, test evidence, performance/coverage evidence and review evidence are closed.

| Slice ID | Scope | Primary state nodes | API/domain boundary | AC/TC routing | Completion evidence |
| --- | --- | --- | --- | --- | --- |
| P02-FUC-S000 | Documentation chain and implementation routing | `DocumentReady`, `ImplementationBlocked` | docs only | AC-P02-FUC-000 / TC-P02-FUC-000 | requirements/spec/acceptance/test_cases/traceability/definition updated; independent review recorded |
| P02-FUC-S001 | ProgressForecast model hardening | `ForecastReady`, `ForecastLimited`, `ForecastUnavailable` | forecast service/domain/API/AI explanation candidate | AC-P02-FUC-001 / TC-P02-FUC-001..003 | backend/API/AI-schema tests for gap, ETA range, confidence, risk, claim guard, low-confidence/partial/unsupported limitation and AI explanation entitlement/quota/cost fallback or deterministic N/A |
| P02-FUC-S002 | Checkpoint cadence and task library | `CheckpointDue`, `CheckpointNotDue`, `CheckpointLimited`, `CheckpointUnavailable` | checkpoint cadence/task library domain/API/content/AI boundary | AC-P02-FUC-002 / TC-P02-FUC-004..006 | task library and cadence tests for weekly/biweekly, goal type coverage, content limitation and entitlement/cost fallback |
| P02-FUC-S003 | Checkpoint-to-plan update | `CheckpointRecorded`, `CheckpointLowConfidence`, `CheckpointFailed`, `PlanStaleForCheckpoint` | checkpoint result, forecast recompute, plan stale/replan signal | AC-P02-FUC-003 / TC-P02-FUC-007..009 | checkpoint result tests prove forecast update, stale/replan signal, no false goal completion and control/recovery compatibility |
| P02-FUC-S004 | Backend goal-progress projection | `ProjectionReady`, `ProjectionLimited`, `ProjectionUnavailable` | projection domain/API/source ownership | AC-P02-FUC-004 / TC-P02-FUC-010..012 | projection source-of-truth tests and OpenAPI/generated client drift checks |
| P02-FUC-S005 | Home/Queue/Wiki surface propagation | `HomeProjectionRendered`, `QueueProjectionRendered`, `WikiProjectionRendered` | Flutter adapter/widgets and existing surface APIs | AC-P02-FUC-005 / TC-P02-FUC-013..016 | Home, Queue and Wiki all covered by widget/integration tests; one- or two-surface evidence is partial only |
| P02-FUC-S006 | Surface deletion/unavailable downgrade | `SurfaceDowngraded`, `SurfaceRemoved`, `SensitiveProgressHidden` | data governance, account deletion, unavailable projection, Flutter cache invalidation | AC-P02-FUC-006 / TC-P02-FUC-017..019 | deletion/unavailable/unsupported/low-confidence downgrade tests and privacy review |
| P02-FUC-S007 | Automated tests, performance, coverage and final review | `FollowupCTraceabilityChecked`, `PerformanceChecked`, `CoverageChecked`, `IndependentReviewed` | QA scripts, reports and quality gate | AC-P02-FUC-007 / TC-P02-FUC-020..022 | dedicated checker or equivalent gate, p95 budgets, >=80% coverage, report sync and independent review |

S005 may be implemented as subroutes:
- `P02-FUC-S005-A` Home projection surface.
- `P02-FUC-S005-B` Expression Queue projection surface.
- `P02-FUC-S005-C` Personal Wiki projection surface.

The S005 full completion gate requires Home, expression queue and personal Wiki evidence together. S005-A/B/C subroutes may close independently as partial milestones, but they do not close P02-FUC-S005 or P02-SI-006 until all three surfaces have passing evidence.

## Inputs
- Active GoalProfile revision and support status.
- DiagnosticAssessment, accepted learning evidence, checkpoint history and L0-L5/memory facts produced by upstream and Followup-B.
- DailyTrainingPlan, PlanItem, AutopilotAction, UserAutopilotControl and recovery state.
- SupportedGoalMatrixDecision and content coverage for goal type.
- Entitlement/quota/cost fallback decision for checkpoint depth and forecast/checkpoint AI explanation.
- Forecast/checkpoint records, source timestamps and rule versions.
- Account deletion/data availability state and privacy/data-governance rules.

## Outputs
- `ProgressForecast` with gap, ETA range, confidence, risk reason, next checkpoint and claim guard.
- `CheckpointCadenceDecision` and `CheckpointTaskDefinition`.
- `OutcomeCheckpointResult` and `PlanUpdateSignal`.
- `GoalProgressProjection` and surface-specific safe fragments.
- Surface downgrade decision and downgrade reason.
- Replay/audit fields or equivalent deterministic evidence for forecast, checkpoint and projection decisions.

## State Model
| State | Meaning | Allowed next states |
| --- | --- | --- |
| `DocumentReady` | S000 docs exist and map S000-S007 | `ImplementationBlocked` |
| `ImplementationBlocked` | Code routing is blocked until AC-to-TC and contract gates pass for a slice | `ForecastReady`, `CheckpointDue`, `ProjectionReady` |
| `ForecastReady` | Forecast can show gap, ETA range, risk and next checkpoint safely | `CheckpointDue`, `ProjectionReady`, `ForecastLimited` |
| `ForecastLimited` | Forecast can show limited progress but not precise ETA or completion | `CheckpointDue`, `ProjectionLimited`, `SurfaceDowngraded` |
| `ForecastUnavailable` | Forecast facts are missing, deleted or unsafe | `ProjectionUnavailable`, `SurfaceDowngraded` |
| `CheckpointDue` | A supported checkpoint task is due | `CheckpointRecorded`, `CheckpointFailed`, `CheckpointLowConfidence` |
| `CheckpointNotDue` | No checkpoint is due yet | `ForecastReady`, `ProjectionReady` |
| `CheckpointLimited` | Task exists with partial/low-depth limitation | `CheckpointRecorded`, `CheckpointLowConfidence`, `ProjectionLimited` |
| `CheckpointUnavailable` | Unsupported, unavailable or cost/quota-blocked checkpoint | `ProjectionLimited`, `SurfaceDowngraded` |
| `CheckpointRecorded` | Accepted checkpoint result exists | `PlanStaleForCheckpoint`, `ForecastReady`, `ProjectionReady` |
| `CheckpointLowConfidence` | Checkpoint result exists but cannot support completion or precise ETA | `ForecastLimited`, `ProjectionLimited` |
| `CheckpointFailed` | Checkpoint failed or was skipped | `ForecastLimited`, `ProjectionLimited` |
| `PlanStaleForCheckpoint` | Checkpoint result requires replan | `ProjectionReady`, `SurfaceDowngraded` |
| `ProjectionReady` | Backend-owned projection can serve surfaces | `HomeProjectionRendered`, `QueueProjectionRendered`, `WikiProjectionRendered` |
| `ProjectionLimited` | Projection is safe but limited | `SurfaceDowngraded` or rendered limited fragments |
| `ProjectionUnavailable` | Projection has no safe facts | `SurfaceRemoved`, `SensitiveProgressHidden` |
| `SurfaceDowngraded` | Surface shows safe limitation copy only | terminal |
| `SurfaceRemoved` | Surface removes sensitive progress block | terminal |
| `SensitiveProgressHidden` | Cached/old sensitive goal progress is not shown | terminal |

## Deterministic Policy Tables

### Forecast Claim Guard Table
| Condition | ETA output | Completion output | Risk output | Required reason |
| --- | --- | --- | --- | --- |
| supported goal, sufficient evidence, non-low confidence, checkpoint history available | ETA range allowed | product-internal progress only; completion requires checkpoint evidence | risk level and reason required | `forecast_supported` or checkpoint-specific reason |
| supported goal but no checkpoint history | ETA range may be broad or unavailable | no goal-complete status | risk reason must mention checkpoint missing | `checkpoint_evidence_missing` |
| partial goal | no precise ETA; broad range or unavailable reason only | no goal-complete status | limitation shown | `partial_goal_limited` |
| unsupported goal | no ETA | no goal-complete status | unsupported limitation shown | `unsupported_goal` |
| low confidence | no precise ETA | no goal-complete status | low-confidence reason shown | `low_confidence` |
| stale plan or recovery required | no new precise ETA until replan | no goal-complete status | stale/recovery risk shown | `stale_plan` or `recovery_required` |
| AI explanation entitlement/quota/cost blocked | deterministic ETA range only if other claim guards pass | AI output cannot set completion; backend policy only | deterministic reason key or no AI expansion | `ai_explanation_unavailable` or `cost_quota_limited` |
| deleted or unavailable facts | no ETA | no completion output | unavailable/downgrade reason only | `deleted` or `unavailable` |

### Checkpoint Cadence And Task Table
| Goal/support condition | Cadence decision | Task availability | Required limitation |
| --- | --- | --- | --- |
| supported IELTS-style speaking or supported speaking goal | weekly or biweekly based on active backplan/checkpoint history | `weekly_mock`, `biweekly_mock`, `speaking_task` | no official score certification |
| supported business communication goal | weekly or biweekly | `business_task`, `scenario_retake`, `roleplay_checkpoint` | product-internal rubric only |
| partial goal with limited content coverage | biweekly or manual/due-only | limited task only | content limitation copy and no precise ETA |
| unsupported goal | unavailable | no full checkpoint task | unsupported fallback and target narrowing path |
| entitlement/quota/cost blocked | limited or unavailable | low-cost task or no AI explanation | downgrade reason and no paid entitlement fact creation |

### Projection Source Ownership Table
| Field family | Source of truth | Surface may compute locally? | Required safe behavior |
| --- | --- | --- | --- |
| goal status/support | backend GoalProfile/SupportedGoalMatrixDecision | no | display backend status or limitation |
| next action | backend AutopilotAction/control/recovery state | no | render only returned action and reason |
| gap and ETA | backend ProgressForecast | no | no local ETA math |
| risk reason | backend ProgressForecast/checkpoint/recovery facts | no | render safe explanation key/text |
| checkpoint conclusion | backend OutcomeCheckpointResult/projection | no | no local goal completion inference |
| surface eligibility/downgrade | backend projection/data-governance decision | no | hide or downgrade sensitive progress |

### Surface Downgrade Table
| Condition | Downgrade reason | Surface behavior |
| --- | --- | --- |
| goal/forecast/checkpoint data deleted | `deleted` | remove sensitive progress block and cached ETA/gap/checkpoint conclusion |
| backend facts unavailable | `unavailable` | show neutral unavailable state or omit progress fragment |
| unsupported goal | `unsupported_goal` | show limitation and target narrowing path; no forecast/complete claim |
| partial goal | `partial_goal_limited` | show limited progress without precise ETA |
| low confidence | `low_confidence` | show need for checkpoint or more evidence |
| stale plan | `stale_plan` | show replan/recovery prompt when available |
| control paused/blocked | `control_blocked` | show paused/blocked state without prompting unauthorized action |

## P02-FUC-SPEC-000 S000 Document Chain And Slice Routing
- S000 creates or updates `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md`, `definition.md` and `traceability.md`.
- S000 establishes S000-S007 routing, FR/Spec/AC/TC IDs, gap register, evidence columns and report entry points.
- S000 must keep not-yet-implemented slices as planned/not started and must not claim code evidence. After S001 execution, S001 may claim only local forecast-hardening code/test evidence.
- S000 review must check Stage Scope IDs, policy gates, excluded scope, AC-to-TC mapping and release/Product Base non-claims.

## P02-FUC-SPEC-001 ProgressForecast Model Hardening
- Forecast output includes forecast id, source goal revision, gap summary, ETA range or unavailable reason, confidence band, risk level, risk reason, next checkpoint date, claim guard, explanation key and updated timestamp.
- Risk reason is selected from accepted facts: diagnostic gap, checkpoint result, missing checkpoint evidence, stale/replan signal, recovery state, supported goal limitation or data unavailability.
- ETA range is only available when support status and confidence allow it. Low-confidence, partial, unsupported, stale or deleted/unavailable states must suppress precise ETA.
- Claim guard always blocks official-score equivalence and guaranteed achievement; goal-complete display requires accepted checkpoint evidence and GoalAchievementPolicy compatibility.
- AI-assisted forecast explanation is candidate-only. If entitlement, quota, cost or policy blocks AI explanation, the forecast must return a deterministic explanation key/unavailable reason and must not create commercial entitlement facts.

## P02-FUC-SPEC-002 Checkpoint Cadence And Task Library
- Cadence decision uses active backplan checkpoint due date, latest checkpoint date, goal type, support status, content coverage and entitlement/cost fallback.
- Task library returns only task definitions that match supported goal type and content coverage.
- Required task fields: `task_id`, `task_type`, `cadence`, `goal_type`, `prompt_ref` or `task_ref`, `estimated_duration_minutes`, `required_evidence`, `rubric_ref`, `support_status`, `limitation_reason`, `ai_depth`.
- Unsupported goals return no full checkpoint task and must surface unsupported fallback.
- Partial goals may return limited checkpoint tasks but must not allow full completion forecast or precise ETA.

## P02-FUC-SPEC-003 Checkpoint-To-Plan Update
- Checkpoint submission or result processing writes an OutcomeCheckpointResult with status `recorded`, `low_confidence`, `failed`, `skipped` or `unsupported`.
- Recorded checkpoint results update forecast and emit a plan update signal when the result changes risk, target gap or required training direction.
- Low-confidence, failed, skipped or unsupported checkpoint results update risk/limitation state but do not mark goal complete.
- Plan stale/replan signal includes signal type, reason code, source checkpoint id, rule version and input snapshot hash or equivalent audit reference.
- Paused/control-blocked/recovery-required states must prevent silent next-action advancement after checkpoint update.

## P02-FUC-SPEC-004 Backend Goal-Progress Projection
- Backend projection aggregates active goal, support status, control state, next action, forecast, latest checkpoint, surface eligibility and downgrade reason.
- Projection exposes safe surface fragments for Home, expression queue and personal Wiki.
- Projection must redact or omit raw transcript, raw audio reference, sensitive target details and internal provider payload.
- Projection response distinguishes `ready`, `limited`, `unavailable`, `deleted`, `unsupported`, `low_confidence`, `stale_plan` and `control_blocked` states.
- Projection must include source references or hashes sufficient for traceability without leaking sensitive content.

## P02-FUC-SPEC-005 Home/Queue/Wiki Surface Propagation
- Home renders goal-progress overview and next action from backend projection.
- Expression queue renders target-related next action, risk or checkpoint due/conclusion from projection without changing queue ordering unless a backend queue/projection contract explicitly provides priority.
- Personal Wiki renders checkpoint conclusion, goal weakness summary or next review target from projection/evidence-safe fields.
- S005 completion requires Home, expression queue and personal Wiki tests to pass. One- or two-surface implementation may be accepted only as S005-A/B/C partial evidence and cannot close full S005.
- Surface copy must preserve product-internal language and avoid official-score, guaranteed-outcome or commercial entitlement claims.

## P02-FUC-SPEC-006 Surface Deletion/Unavailable Downgrade
- Surface downgrade decision is backend-owned and represented in projection fragments.
- When data is deleted or unavailable, surfaces must remove cached gap, ETA, risk, checkpoint conclusion and goal-complete display.
- Unsupported, partial, low-confidence, stale or control-blocked states render safe limitation copy and no precise ETA.
- Flutter adapters/widgets must not show previous sensitive progress from stale local state after downgrade.

## P02-FUC-SPEC-007 Automated Tests, Performance, Coverage And Review Gates
- AC-to-TC mapping is mandatory before routing S001-S007 implementation.
- Test cases must cover backend/domain/API, OpenAPI/generated client drift when API changes, Flutter widget/integration where surfaces change, AI schema/eval where AI explanation changes, performance budgets and traceability script.
- Test cases must publish fixture/assertion entry points before implementation, including forecast AI cost fallback, all three surface projections, stale cache removal and source-of-truth assertions.
- Planned p95 budgets: forecast recompute <=1 s, checkpoint task lookup <=300 ms, checkpoint submit accepted/queued <=2 s, projection load <=500 ms and surface propagation <=1 s in local deterministic tests.
- Changed backend/domain/API/Flutter code must meet >=80% line and branch coverage where measurable; unchanged layers must state N/A.
- S007 must record implementation, test and quality evidence before Followup-C can be locally complete. Release/Product Base approval remains outside S007 unless Followup-D explicitly approves it.

## Non-goals
- Goal intake, diagnostic sample capture, pause/resume/control scheduler, missed-day recovery, item-level memory and L0-L5 transition.
- Commercial entitlement source-of-truth creation, store/reviewer evidence, paid AI provider evidence or Product Base merge approval.
- Official exam score certification, official-score equivalence or guaranteed outcome copy.
