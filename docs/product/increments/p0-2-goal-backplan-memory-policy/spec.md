# P0.2 Increment Spec：目标倒排计划与记忆曲线策略

## 状态
Design-ready / acceptance-input ready - 本 spec 是 `p0-2-goal-backplan-memory-policy` acceptance criteria 的直接上游输入；尚未进入实现。

## 上游引用
- Increment definition: `docs/product/increments/p0-2-goal-backplan-memory-policy/definition.md`
- Increment requirements: `docs/product/increments/p0-2-goal-backplan-memory-policy/requirements.md`
- Upstream diagnostic traceability: `docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md`
- Active stage: `docs/product/stages/p0-2-training-memory.md`

## Spec Trace IDs
| Spec ID | Stage Scope ID | Policy Gate | Requirement ID | Spec area |
| --- | --- | --- | --- | --- |
| P02-PLAN-SPEC-001 | P02-SI-009 | P02-PG-001, P02-PG-002 | P02-PLAN-FR-001 | Planner input contract |
| P02-PLAN-SPEC-002 | P02-SI-004, P02-SI-009 | P02-PG-003 | P02-PLAN-FR-002 | Weekly backplan |
| P02-PLAN-SPEC-003 | P02-SI-001, P02-SI-005 | P02-PG-003 | P02-PLAN-FR-003 | Daily planner |
| P02-PLAN-SPEC-004 | P02-SI-003, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-PLAN-FR-004 | Memory curve and L0-L5 |
| P02-PLAN-SPEC-005 | P02-SI-002, P02-SI-011 | P02-PG-003 | P02-PLAN-FR-005 | Cross-session pressure |
| P02-PLAN-SPEC-006 | P02-SI-005 | P02-PG-003 | P02-PLAN-FR-006 | Cross-day orchestration |
| P02-PLAN-SPEC-007 | P02 policy gates | P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-PLAN-FR-007 | Feasibility, commercial and data gates |
| P02-PLAN-SPEC-008 | P02 policy gates | P02-PG-003 | P02-PLAN-FR-008 | Performance, coverage and replay gates |

## Inputs
- active GoalProfile revision and DiagnosticAssessment
- SupportedGoalMatrixDecision
- weakness tags, initial mastery state, accepted learning evidence
- reviewed content mapping and current official scenario assets
- daily minutes, intensity preference, deadline and checkpoint cadence
- entitlement, quota and paid AI availability

## Outputs
- `WeeklyBackplan`
- `DailyTrainingPlan`
- `PlanItem`
- `ReviewSchedule`
- `MemoryRisk`
- `PressureLevel`
- `PlannerDecisionAudit`
- stale-plan/recalculation event

## State Model
| State | Meaning | Next states |
| --- | --- | --- |
| `InputReady` | Required goal/diagnostic/content inputs exist | `Backplanning`, `UnsupportedOrPartial` |
| `UnsupportedOrPartial` | Goal cannot support full plan | terminal or `InputReady` after narrowed target |
| `Backplanning` | Weekly plan and milestones are generated | `DailyPlanning`, `RecoverableError` |
| `DailyPlanning` | Today plan is selected under time and priority constraints | `ReadyForAutopilot`, `RecoverableError` |
| `ReadyForAutopilot` | Plan can be consumed by autopilot increment | terminal |
| `StalePlan` | Goal, diagnostic or checkpoint input changed | `Backplanning` |
| `RecoveryReplan` | User skipped/missed/deferred enough work to require recovery | `DailyPlanning` |
| `RecoverableError` | Missing input, quota, content or policy violation | previous valid state, `UnsupportedOrPartial` |

## P02-PLAN-SPEC-001 Planner Input Contract
Plan generation reads only accepted upstream facts. Unsupported goals fail closed; partial goals require limitation and reduced scope.

## P02-PLAN-SPEC-002 Weekly Backplan
Weekly plan derives milestones from target gap, deadline, daily minutes and intensity. It includes checkpoint dependency and stale-plan triggers.

## P02-PLAN-SPEC-003 Daily Planner
Daily plan selects a bounded set of PlanItems. Priority order is unfinished critical session, due review with high forgetting risk, high-severity weakness, current goal milestone and interleaving maintenance, unless a recovery rule overrides.

## P02-PLAN-SPEC-004 Memory Curve And L0-L5
Memory policy uses spacing intervals, forgetting risk score, retrieval success, overlearning cap and interleaving groups. L0-L5 transitions require accepted evidence and cannot be set by LLM.

## P02-PLAN-SPEC-005 Cross-session Pressure
Pressure adjusts hint level, retrieval demand and scenario distance across sessions. Pressure cannot increase when fatigue, low confidence or user-control policy requires recovery.

## P02-PLAN-SPEC-006 Cross-day Orchestration
Missed-day handling compresses, defers or replaces tasks based on goal risk; it does not simply accumulate overdue tasks. Every recomputation records reason code and source event.

## P02-PLAN-SPEC-007 Feasibility, Commercial And Data Gates
Plan generation must check content support, entitlement, AI budget and data minimization. Plan explanations may use AI candidate text, but final plan facts are deterministic and audited.

## P02-PLAN-SPEC-008 Performance, Coverage And Replay Gates
Implementation must include replay fixtures. Performance budgets: 14-day weekly backplan p95 <=1 s with 500 evidence rows, daily plan selection p95 <=300 ms, memory due calculation p95 <=300 ms and replay verification p95 <=500 ms in local deterministic tests. Changed code coverage must be >=80% line and branch.

## Required Downstream Contracts
- Domain model: WeeklyBackplan, DailyTrainingPlan, PlanItem, ReviewSchedulePolicy, MemoryRisk, PressureLevel, PlannerDecisionAudit.
- API/OpenAPI: generate weekly plan, get daily plan, replan, defer/skip/complete plan item.
- AI runtime: plan explanation candidate-only schema and forbidden persistent decision fields.
- UX: plan visibility, partial/unsupported limitations, overload/recovery state.

## Non-goals
- Goal intake and diagnostic collection.
- Autopilot execution, notification loop, checkpoint scoring and progress forecast.
- Full release approval or paid AI external evidence.
