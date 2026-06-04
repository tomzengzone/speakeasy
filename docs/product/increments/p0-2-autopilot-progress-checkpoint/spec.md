# P0.2 Increment Spec：自动带练、进度预测与周期复测

## 状态
Design-ready / acceptance-input ready - 本 spec 是 `p0-2-autopilot-progress-checkpoint` acceptance criteria 的直接上游输入；尚未进入实现。

## 上游引用
- Increment definition: `docs/product/increments/p0-2-autopilot-progress-checkpoint/definition.md`
- Increment requirements: `docs/product/increments/p0-2-autopilot-progress-checkpoint/requirements.md`
- Upstream diagnostic traceability: `docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md`
- Upstream plan traceability: `docs/product/increments/p0-2-goal-backplan-memory-policy/traceability.md`
- Active stage: `docs/product/stages/p0-2-training-memory.md`

## Spec Trace IDs
| Spec ID | Stage Scope ID | Policy Gate | Requirement ID | Spec area |
| --- | --- | --- | --- | --- |
| P02-AUTO-SPEC-001 | P02-SI-010 | P02-PG-001, P02-PG-002, P02-PG-003 | P02-AUTO-FR-001 | Autopilot input contract |
| P02-AUTO-SPEC-002 | P02-SI-010 | P02-PG-003 | P02-AUTO-FR-002 | No-choice daily execution |
| P02-AUTO-SPEC-003 | P02-SI-010 | P02-PG-003, P02-PG-005 | P02-AUTO-FR-003 | User control and recovery |
| P02-AUTO-SPEC-004 | P02-SI-012 | P02-PG-001, P02-PG-002 | P02-AUTO-FR-004 | ProgressForecast |
| P02-AUTO-SPEC-005 | P02-SI-013 | P02-PG-001, P02-PG-002 | P02-AUTO-FR-005 | OutcomeCheckpoint |
| P02-AUTO-SPEC-006 | P02-SI-006 | P02-PG-005 | P02-AUTO-FR-006 | Goal progress surfaces |
| P02-AUTO-SPEC-007 | P02 policy gates | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-AUTO-FR-007 | Commercial, claim and data governance |
| P02-AUTO-SPEC-008 | P02 policy gates | P02-PG-003, P02-PG-004 | P02-AUTO-FR-008 | Performance, coverage and rollout gates |

## Inputs
- active GoalProfile, DiagnosticAssessment and SupportedGoalMatrixDecision
- active DailyTrainingPlan and PlanItem
- accepted learning evidence, checkpoint history and memory risk
- user control settings: pause, quiet hours, notification permission, intensity override
- entitlement/quota/AI budget and paid AI availability

## Outputs
- `AutopilotAction`
- `AutopilotSessionState`
- `ProgressForecast`
- `OutcomeCheckpointResult`
- `PlanUpdateSignal`
- home/queue/wiki goal-progress projections
- audit events for action selection, skip/defer, forecast and checkpoint update

## State Model
| State | Meaning | Next states |
| --- | --- | --- |
| `AutopilotReady` | Active plan has a valid next action | `PromptStart`, `Paused`, `RecoverableError` |
| `PromptStart` | User sees one primary action and reason | `Executing`, `Deferred`, `Paused` |
| `Executing` | Training/review/checkpoint action is running | `Completed`, `RecoverableError` |
| `Completed` | Action produced evidence or state update | `Forecasting`, `SurfaceUpdate` |
| `Forecasting` | Progress forecast recalculates | `SurfaceUpdate`, `RecoverableError` |
| `CheckpointDue` | Weekly/biweekly checkpoint is due | `Executing`, `Deferred` |
| `SurfaceUpdate` | Home/queue/wiki projections update | terminal |
| `Paused` | User paused autopilot | `AutopilotReady` |
| `Deferred` | User skipped/deferred action | `RecoveryPlanRequired`, `AutopilotReady` |
| `RecoveryPlanRequired` | Missed-day or deferred state needs replan | terminal for upstream planner |
| `RecoverableError` | Policy/provider/permission failure | previous valid state, `Deferred`, `Paused` |

## P02-AUTO-SPEC-001 Autopilot Input Contract
Autopilot consumes only accepted upstream facts and active plan items. Unsupported or stale inputs block full execution and show limitation/recovery path.

## P02-AUTO-SPEC-002 No-choice Daily Execution
Autopilot presents one primary action with duration and reason. It does not ask the user to choose a plan, but allows user-visible explanation before start.

## P02-AUTO-SPEC-003 User Control And Recovery
Pause/resume, skip/defer, quiet hours, intensity override and missed-day recovery are first-class states. Notifications require consent and permission.

## P02-AUTO-SPEC-004 ProgressForecast
Forecast outputs gap, ETA range, confidence, risk reason and next checkpoint. Low confidence or partial support blocks high-precision claims.

## P02-AUTO-SPEC-005 OutcomeCheckpoint
Checkpoint formats are goal-type specific. Results update progress evidence, risk and plan stale/replan signals.

## P02-AUTO-SPEC-006 Goal Progress Surfaces
Home, expression queue and Wiki render backend/autopilot projections. They do not compute goal state locally or create facts.

## P02-AUTO-SPEC-007 Commercial, Claim And Data Governance
Entitlement/cost policy owns paid/free depth, AI use and quota fallback. Claim guard blocks official certification and false goal completion. Data governance owns retention, deletion/export, audit and notification consent.

## P02-AUTO-SPEC-008 Performance, Coverage And Rollout Gates
Implementation must include coverage >=80% line and branch for changed code. Performance budgets: autopilot state load p95 <=500 ms, forecast recompute p95 <=1 s, checkpoint submit accepted/queued p95 <=2 s and surface propagation p95 <=1 s in local deterministic tests.

## Required Downstream Contracts
- Domain model: AutopilotAction, ProgressForecast, OutcomeCheckpointResult, PlanUpdateSignal, UserAutopilotControl.
- API/OpenAPI: get next action, complete action, defer/skip, get forecast, submit checkpoint, update surfaces.
- AI runtime: checkpoint feedback and forecast explanation candidate-only schema.
- UX: no-choice daily execution, pause/quiet hours, progress forecast, checkpoint review and partial/unsupported states.

## Non-goals
- Goal intake, diagnostic collection and backplan/memory policy generation.
- Commercial entitlement source-of-truth creation.
- Official exam score certification or guaranteed outcome.
