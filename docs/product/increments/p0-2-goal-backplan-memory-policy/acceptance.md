# P0.2 Acceptance Criteria：目标倒排计划与记忆曲线策略

## 状态
Design-ready / AC-to-TC mapping required - 基于 increment spec 生成；尚未进入实现。

## 上游来源
- `docs/product/increments/p0-2-goal-backplan-memory-policy/requirements.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/spec.md`

## Stage Scope Acceptance Coverage
| Stage Scope ID | Requirement ID | Spec ID | Acceptance Criteria |
| --- | --- | --- | --- |
| P02-SI-009 | P02-PLAN-FR-001 | P02-PLAN-SPEC-001 | AC-P02-PLAN-001 |
| P02-SI-004, P02-SI-009 | P02-PLAN-FR-002 | P02-PLAN-SPEC-002 | AC-P02-PLAN-002 |
| P02-SI-001, P02-SI-005 | P02-PLAN-FR-003 | P02-PLAN-SPEC-003 | AC-P02-PLAN-003 |
| P02-SI-003, P02-SI-011 | P02-PLAN-FR-004 | P02-PLAN-SPEC-004 | AC-P02-PLAN-004 |
| P02-SI-002, P02-SI-011 | P02-PLAN-FR-005 | P02-PLAN-SPEC-005 | AC-P02-PLAN-005 |
| P02-SI-005 | P02-PLAN-FR-006 | P02-PLAN-SPEC-006 | AC-P02-PLAN-006 |
| P02 policy gates | P02-PLAN-FR-007 | P02-PLAN-SPEC-007 | AC-P02-PLAN-007 |
| P02 policy gates | P02-PLAN-FR-008 | P02-PLAN-SPEC-008 | AC-P02-PLAN-008 |

## AC-P02-PLAN-001 Planner Input Contract
- Given active goal/diagnostic/content inputs exist, the planner must generate from those accepted facts only.
- Given a goal is unsupported, the planner must fail closed and not generate full plan, ETA or completion path.
- Given a goal is partial or diagnostic confidence is low, the planner must generate limited/conservative output with visible reason.

## AC-P02-PLAN-002 Weekly Backplan
- Given supported inputs, the system must generate weekly milestones, session count and review windows from deadline, daily minutes, intensity and target gap.
- Given target or diagnostic input changes, the system must mark old plan stale and generate a new plan version.
- Given plan generation succeeds, the plan must include checkpoint dependency and source input revision.

## AC-P02-PLAN-003 Daily Training Planner
- Given a daily time budget, the system must generate a bounded daily plan that fits the budget and includes minimum viable training block.
- Given due review, weakness, unfinished session and current milestone conflict, the system must select using deterministic priority and record reason code.
- Given plan load fails or content is missing, the system must show recoverable or partial state rather than inventing tasks.

## AC-P02-PLAN-004 Memory Curve And L0-L5
- Given accepted evidence changes mastery or review timing, memory policy must compute spacing, forgetting risk and next due date.
- Given L0-L5 transition is proposed, it must be based on accepted diagnostic/training/checkpoint evidence.
- Given AI output contains final mastery or review schedule, the system must reject it as persistent state.

## AC-P02-PLAN-005 Cross-session Pressure
- Given recent performance is strong and fatigue risk is low, pressure can reduce hints or increase retrieval requirement.
- Given fatigue, repeated failure, low confidence or user-control policy applies, pressure must not increase and may trigger recovery.
- Given a pressure decision is applied, replay with same input and rule version must produce the same decision.

## AC-P02-PLAN-006 Cross-day Orchestration
- Given the user misses a day, the system must generate recovery plan by compressing, deferring or replacing tasks, not by stacking all overdue tasks.
- Given an unfinished session exists, the system must choose continue, compress, defer or replan with reason code.
- Given current goal milestone is at risk, the plan must surface risk-driving items without exceeding daily time budget.

## AC-P02-PLAN-007 Feasibility, Commercial And Data Gates
- Given content or rubric coverage is insufficient, plan generation must downgrade or block.
- Given entitlement/quota/AI budget is insufficient, plan depth or explanation must downgrade server-side.
- Given planner snapshot is stored, it must redact sensitive diagnostic/transcript data and support deletion/retention policy.

## AC-P02-PLAN-008 Performance, Coverage And Replay Gates
- Given implementation is submitted, changed backend/domain/API/Flutter code for this increment must have automated line and branch coverage >=80%.
- Given performance tests run, 14-day weekly backplan p95 must be <=1 s with 500 evidence rows, daily plan selection p95 <=300 ms, memory due calculation p95 <=300 ms and replay verification p95 <=500 ms.
- Given planner replay fixtures run, every deterministic fixture must match expected decision or fail the release-check.

## AC-to-TC Requirement
Every AC-P02-PLAN-001 through AC-P02-PLAN-008 must map to at least one stable TC-P02-PLAN ID before implementation routing.
