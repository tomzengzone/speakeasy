# P0.2 Acceptance Criteria：自动带练、进度预测与周期复测

## 状态
Design-ready / AC-to-TC mapping required - 基于 increment spec 生成；尚未进入实现。

## 上游来源
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/requirements.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/spec.md`

## Stage Scope Acceptance Coverage
| Stage Scope ID | Requirement ID | Spec ID | Acceptance Criteria |
| --- | --- | --- | --- |
| P02-SI-010 | P02-AUTO-FR-001 | P02-AUTO-SPEC-001 | AC-P02-AUTO-001 |
| P02-SI-010 | P02-AUTO-FR-002 | P02-AUTO-SPEC-002 | AC-P02-AUTO-002 |
| P02-SI-010 | P02-AUTO-FR-003 | P02-AUTO-SPEC-003 | AC-P02-AUTO-003 |
| P02-SI-012 | P02-AUTO-FR-004 | P02-AUTO-SPEC-004 | AC-P02-AUTO-004 |
| P02-SI-013 | P02-AUTO-FR-005 | P02-AUTO-SPEC-005 | AC-P02-AUTO-005 |
| P02-SI-006 | P02-AUTO-FR-006 | P02-AUTO-SPEC-006 | AC-P02-AUTO-006 |
| P02 policy gates | P02-AUTO-FR-007 | P02-AUTO-SPEC-007 | AC-P02-AUTO-007 |
| P02 policy gates | P02-AUTO-FR-008 | P02-AUTO-SPEC-008 | AC-P02-AUTO-008 |

## AC-P02-AUTO-001 Autopilot Input Contract
- Given active upstream goal, diagnostic and plan inputs exist, autopilot must select next action from active PlanItem only.
- Given plan is stale, partial, unsupported or missing, autopilot must show limitation or recovery path and must not start full autopilot.
- Given AI output suggests final mastery, commercial entitlement or official certification, autopilot must reject those fields.

## AC-P02-AUTO-002 No-choice Daily Execution
- Given a valid daily plan exists, the user must see one primary action: start training, continue session, review or checkpoint.
- Given the action is shown, the UI must show expected duration and reason code or explanation.
- Given the user starts the action, the system must enter the owning training/review/checkpoint flow without requiring manual plan selection.

## AC-P02-AUTO-003 User Control And Recovery
- Given the user pauses autopilot, the system must stop prompts and preserve state for resume.
- Given quiet hours or notification permission blocks a reminder, the system must not send the reminder and must retain recovery state.
- Given the user skips or misses a day, the system must trigger recovery planning instead of stacking all overdue tasks.

## AC-P02-AUTO-004 ProgressForecast
- Given accepted evidence changes, forecast must update gap, ETA range, confidence, risk reason and next checkpoint.
- Given confidence is low or goal is partial, forecast must avoid high-precision ETA and show limitation copy.
- Given goal completion is displayed, it must cite checkpoint evidence and pass GoalAchievementPolicy.

## AC-P02-AUTO-005 OutcomeCheckpoint
- Given checkpoint is due, the system must present a checkpoint format matching the supported goal type.
- Given checkpoint completes, the system must update progress evidence, risk, forecast and plan stale/replan signal.
- Given checkpoint fails, is skipped or lacks confidence, the system must show recoverable/low-confidence state and must not mark goal complete.

## AC-P02-AUTO-006 Goal Progress Surfaces
- Given forecast or checkpoint updates, at least two of home, expression queue and personal Wiki must reflect next action, goal gap, risk or checkpoint conclusion.
- Given surfaces render progress, they must read backend/autopilot facts and must not compute final goal state locally.
- Given data is deleted or unavailable, surfaces must remove or downgrade sensitive progress display.

## AC-P02-AUTO-007 Commercial, Claim And Data Governance
- Given user entitlement or quota does not allow full autopilot/checkpoint depth, system must downgrade server-side and show clear limits.
- Given membership value is displayed, it must be value display only and must not create entitlement facts.
- Given checkpoint audio/result or forecast explanation is stored, retention, deletion/export, audit and notification consent rules must apply.
- Given any display mentions target score or ETA, it must not claim official score certification or guaranteed outcome.

## AC-P02-AUTO-008 Performance, Coverage And Rollout Gates
- Given implementation is submitted, changed backend/domain/API/Flutter code for this increment must have automated line and branch coverage >=80%.
- Given performance tests run, autopilot state load p95 must be <=500 ms, forecast recompute p95 <=1 s, checkpoint submit accepted/queued p95 <=2 s and surface propagation p95 <=1 s.
- Given rollout check runs, feature flag, kill switch, telemetry and blocked paid AI/commercial release gates must be explicit.

## AC-to-TC Requirement
Every AC-P02-AUTO-001 through AC-P02-AUTO-008 must map to at least one stable TC-P02-AUTO ID before implementation routing.
