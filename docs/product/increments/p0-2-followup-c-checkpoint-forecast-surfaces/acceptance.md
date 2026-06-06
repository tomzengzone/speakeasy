# P0.2 Followup-C Acceptance Criteria：周期复测、预测与多产品面加固

## 状态
S001、S002、S003、S004、S005、S006 and S007 acceptance locally executed - 本文件基于 Followup-C requirements 和 spec 定义验收标准。S000 文档链验收已通过 TC-P02-FUC-000；S001 ProgressForecast model hardening 已通过 TC-P02-FUC-001..003；S002 Checkpoint cadence and task library 已通过 TC-P02-FUC-004..006；S003 Checkpoint-to-plan update 已通过 TC-P02-FUC-007..009；S004 backend goal-progress projection 已通过 TC-P02-FUC-010..012；S005 Home/Queue/Wiki surface propagation 已通过 TC-P02-FUC-013..016；S006 Surface deletion/unavailable downgrade 已通过 TC-P02-FUC-017..019；S007 performance、coverage、traceability script、report evidence 和 independent review 已通过 TC-P02-FUC-020..022。Followup-C is locally complete for S001-S007. Followup-C is not release-ready and Product Base merge is not approved。

## 上游来源
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/requirements.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/spec.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/definition.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/traceability.md`

## Stage Scope Acceptance Coverage
| Stage Scope ID | Policy Gate | Slice ID | Requirement ID | Spec ID | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- |
| P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-FUC-S000 | P02-FUC-FR-000 | P02-FUC-SPEC-000 | AC-P02-FUC-000 |
| P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-FUC-S001 | P02-FUC-FR-001 | P02-FUC-SPEC-001 | AC-P02-FUC-001 |
| P02-SI-013 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-FUC-S002 | P02-FUC-FR-002 | P02-FUC-SPEC-002 | AC-P02-FUC-002 |
| P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-003 | P02-FUC-S003 | P02-FUC-FR-003 | P02-FUC-SPEC-003 | AC-P02-FUC-003 |
| P02-SI-006 | P02-PG-003, P02-PG-005 | P02-FUC-S004 | P02-FUC-FR-004 | P02-FUC-SPEC-004 | AC-P02-FUC-004 |
| P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-005 | P02-FUC-S005 | P02-FUC-FR-005 | P02-FUC-SPEC-005 | AC-P02-FUC-005 |
| P02-SI-006 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUC-S006 | P02-FUC-FR-006 | P02-FUC-SPEC-006 | AC-P02-FUC-006 |
| P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-FUC-S007 | P02-FUC-FR-007 | P02-FUC-SPEC-007 | AC-P02-FUC-007 |

## Implementation Slice Acceptance Routing
| Slice ID | Scope | Acceptance | Test cases | Required evidence |
| --- | --- | --- | --- | --- |
| P02-FUC-S000 | Followup-C document chain and routing | AC-P02-FUC-000 | TC-P02-FUC-000 | `git diff --check`, traceability review, quality review |
| P02-FUC-S001 | ProgressForecast model hardening | AC-P02-FUC-001 | TC-P02-FUC-001..003 | backend/API forecast tests and claim guard review |
| P02-FUC-S002 | Checkpoint cadence and task library | AC-P02-FUC-002 | TC-P02-FUC-004..006 | Passed locally: cadence/task library tests, API/OpenAPI contract drift and content/scoring review |
| P02-FUC-S003 | Checkpoint-to-plan update | AC-P02-FUC-003 | TC-P02-FUC-007..009 | Passed locally: checkpoint result, forecast update, stale/replan, replay audit and control/recovery tests |
| P02-FUC-S004 | Backend goal-progress projection | AC-P02-FUC-004 | TC-P02-FUC-010..012 | projection source-of-truth tests and contract checks |
| P02-FUC-S005 | Home/Queue/Wiki surface propagation | AC-P02-FUC-005 | TC-P02-FUC-013..016 | Passed locally: widget/integration tests for Home, Queue and Wiki; partial surface routes still cannot close S005 |
| P02-FUC-S006 | Surface deletion/unavailable downgrade | AC-P02-FUC-006 | TC-P02-FUC-017..019 | Passed locally: deletion/unavailable/unsupported/stale/control-blocked/partial/low-confidence downgrade tests |
| P02-FUC-S007 | Automated tests, performance, coverage and final review | AC-P02-FUC-007 | TC-P02-FUC-020..022 | Passed locally: p95 budgets, coverage, traceability script and independent review |

## AC-P02-FUC-000 S000 Document Chain And Slice Routing
- Given the S000 pre-implementation documentation gate runs, `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md`, `definition.md` and `traceability.md` must exist and reference the same increment id.
- Given S000 is complete, the documents must contain S000-S007 slice routing and map every slice to FR, Spec, AC and TC IDs or a documented N/A for docs-only scope.
- Given S000 is complete, traceability must preserve Stage Scope IDs P02-SI-006, P02-SI-010, P02-SI-012 and P02-SI-013 and applicable P02-PG-001..005 references.
- Given S000 is complete, any not-yet-routed slice code evidence and test execution evidence must remain `Not started` or `planned`; after S001/S002/S003 execution, each slice may cite only its own local evidence and no release-ready claim may appear.
- Given independent review runs, it must find no blocker in slice granularity, upstream/downstream path, AC-to-TC mapping, status wording or release/Product Base boundary.

## AC-P02-FUC-001 ProgressForecast Model Hardening
- Given accepted evidence changes, forecast must expose gap summary, ETA range or unavailable reason, confidence band, risk level, risk reason, next checkpoint date and claim guard.
- Given support is partial, unsupported, low-confidence, stale, recovery-required, deleted or unavailable, forecast must not display precise ETA, goal-complete copy or official-score equivalence.
- Given checkpoint evidence is missing, forecast must show a risk/limitation reason that makes the missing checkpoint evidence observable.
- Given goal completion is displayed in any downstream surface, it must cite accepted checkpoint evidence and pass GoalAchievementPolicy.
- Given forecast explanation is AI-assisted, AI output must be candidate-only, must respect entitlement/quota/cost fallback and must not persist final completion, official-score equivalence, guaranteed ETA or commercial entitlement facts.
- Given entitlement, quota, cost or policy blocks forecast AI explanation, forecast must return a deterministic explanation key or unavailable reason and still apply the same ETA/completion claim guards.

## AC-P02-FUC-002 Checkpoint Cadence And Task Library
- Given a supported goal has checkpoint cadence due, the system must return a checkpoint task matching the goal type and content coverage.
- Given the checkpoint is not due, the system must return `CheckpointNotDue` or equivalent with next due information, not create unnecessary checkpoint work.
- Given the goal is partial, the system may return a limited checkpoint task but must show limitation and block full completion forecast.
- Given the goal is unsupported, the system must not return a full checkpoint task and must show unsupported fallback or target narrowing path.
- Given entitlement, quota or cost policy blocks full checkpoint depth or AI explanation, the system must downgrade server-side and must not create commercial entitlement facts.

## AC-P02-FUC-003 Checkpoint-To-Plan Update
- Given checkpoint completes with accepted confidence, the system must persist checkpoint result, update forecast, update risk reason and emit plan stale/replan signal when the result changes the plan.
- Given checkpoint is low-confidence, failed, skipped or unsupported, the system must update limitation/risk state but must not mark goal complete.
- Given checkpoint-to-plan update emits stale/replan, the signal must include source checkpoint id, reason code, rule version and replay/audit reference or input snapshot hash.
- Given autopilot is paused, blocked, recovery-required or stale, checkpoint update must not silently advance the next action without control/recovery compatibility checks.
- Given checkpoint result references evidence, the response must avoid raw transcript/audio leakage unless the downstream contract explicitly permits that surface.

## AC-P02-FUC-004 Backend Goal-Progress Projection
- Given forecast, checkpoint or next-action facts exist, backend projection must aggregate a safe goal-progress view for surfaces.
- Given a surface reads goal progress, it must read backend projection or a backend-owned projection fragment and must not compute final goal state, ETA, completion or claim guard locally.
- Given projection is ready, it must expose source-owned fields for next action, gap, risk, checkpoint conclusion, surface eligibility and downgrade reason.
- Given projection contains sensitive upstream facts, it must expose only safe fragments or hashes and must omit raw diagnostic transcript, sensitive target details and provider payloads.
- Given projection facts are deleted or unavailable, projection must return unavailable/downgraded state instead of stale goal progress.

## AC-P02-FUC-005 Home/Queue/Wiki Surface Propagation
- Given backend projection updates, Home, expression queue and personal Wiki must each render the applicable next action, gap, risk or checkpoint conclusion from the projection before full S005 can close.
- Given S005 is implemented as S005-A/B/C, each sub-surface may close as partial evidence, but S005 completion and P02-SI-006 full landing require all three routed sub-surfaces and test coverage.
- Given expression queue renders goal-progress context, it must not locally reorder or reprioritize final queue state unless backend projection/queue contract provides that priority.
- Given personal Wiki renders checkpoint or goal-progress context, it must use safe projection/evidence fields and must not expose raw sensitive checkpoint or diagnostic content.
- Given surface copy mentions target score, ETA or checkpoint, it must preserve product-internal language and must not claim official certification or guaranteed outcome.

## AC-P02-FUC-006 Surface Deletion/Unavailable Downgrade
- Given goal, forecast or checkpoint data is deleted, surfaces must remove sensitive progress display and cached ETA/gap/checkpoint conclusion.
- Given backend facts are unavailable, surfaces must show neutral unavailable state or omit progress fragment instead of reusing stale local data.
- Given goal is unsupported, partial, low-confidence, stale or control-blocked, surfaces must show the matching downgrade reason and avoid precise ETA or goal-complete copy.
- Given account deletion cleanup executes, Home/Queue/Wiki must not continue displaying deleted goal progress from cached Flutter state.
- Given downgrade state is rendered, it must be traceable to backend downgrade reason rather than local UI inference.

## AC-P02-FUC-007 Automated Tests, Performance, Coverage And Review Gates
- Given S001-S007 implementation is requested, routing must remain blocked until every approved AC maps to stable TC IDs or explicit allowed exceptions in `test_cases.md`.
- Given API or projection contracts change, OpenAPI/API contract and generated client drift checks must be planned and later executed.
- Given surface UI changes, widget or integration tests must prove projection consumption, downgrade behavior and no local final-state recomputation.
- Given performance tests run, forecast recompute p95 must be <=1 s, checkpoint task lookup p95 <=300 ms, checkpoint submit accepted/queued p95 <=2 s, projection load p95 <=500 ms and surface propagation p95 <=1 s.
- Given changed backend/domain/API/Flutter code exists, line and branch coverage for changed code must be >=80% where measurable; unchanged layers must state N/A.
- Given S007 closes, dedicated Followup-C traceability checker or equivalent must pass, and implementation/test/quality reports must cite TC IDs, commands, results and residual release/Product Base risk.

## Negative And Edge Coverage Requirements
- Unsupported or partial goals must block full checkpoint task, precise ETA, goal-completion claim and official-score copy.
- Low-confidence forecast or checkpoint must not produce high-confidence completion or precise ETA.
- Paused, blocked or recovery-required autopilot state must prevent silent next-action advancement after checkpoint result.
- Home, expression queue and Wiki must not compute final goal state locally.
- Deleted or unavailable data must not persist through cached surface UI.
- Commercial entitlement, quota and cost fallback must be respected without creating a new entitlement source of truth.
- Forecast AI explanation must use deterministic fallback when entitlement, quota, cost or policy blocks provider use.

## AC-to-TC Requirement
Every AC-P02-FUC-000 through AC-P02-FUC-007 maps to at least one stable TC-P02-FUC ID in `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/test_cases.md` before S001-S007 implementation routing.

## 下游交接边界
- `test_cases.md`、`traceability.md`、domain/API/OpenAPI/UX/AI contracts 和 reports may consume this file as the AC source of truth, but they must not renumber or redefine AC-P02-FUC-000 through AC-P02-FUC-007 without a versioned Followup-C change.
- Test execution status belongs in `test_cases.md`, `docs/reports/test_report.md` and `traceability.md`; this file may summarize current status but must not replace executable Test Evidence.
- S001 local forecast-hardening pass, S002 local checkpoint task-library pass, S003 local checkpoint-to-plan pass, S004 local backend projection pass, S005 local surface propagation pass, S006 local downgrade/data-governance pass and S007 local quality-gate pass do not approve release readiness, Followup-D gates or Product Base merge.
