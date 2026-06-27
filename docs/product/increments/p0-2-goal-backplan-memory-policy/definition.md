# Increment Definition：P0.2 目标倒排计划与记忆曲线策略

## 状态
Planned - PM stage replanning artifact only。该增量用于承接 GoalBackplan、MemoryCurvePolicy 和目标驱动的 cross-session planner；尚未生成 requirements/spec/AC/TC，也未进入实现。

## Increment ID
`p0-2-goal-backplan-memory-policy`

## Active Stage
`docs/product/stages/p0-2-training-memory.md`

## Product Classification
- Request type: product direction / stage replanning request
- Product object mode: `feature-increment`
- Source mode: PM stage plan

## Primary Feature
`goal-driven-learning-autopilot`

## Affected Features
- `learning-memory-review`
- `expression-automation-training`
- `expression-practice-queue`
- `voice-scenario-practice`
- `scoring-feedback`

## Scope
- GoalBackplan：从目标倒推周计划、日计划和每次训练内容。
- MemoryCurvePolicy：明确间隔复习算法、遗忘风险、复现、过度学习和 interleaving。
- Daily planner、cross-session pressure、L0-L5 mastery、long-term session planner 进入目标驱动版本。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| P02-SI-001 | Daily planner becomes goal-driven rather than only evidence-driven. |
| P02-SI-002 | Cross-session pressure ladder follows target gap and memory risk. |
| P02-SI-003 | Completes L0-L5 mastery transitions using diagnostic and training evidence. |
| P02-SI-004 | Long-term planner schedules weeks/days/sessions from GoalProfile. |
| P02-SI-005 | Cross-day orchestration combines due review, weakness, unfinished sessions and goal milestones. |
| P02-SI-009 | GoalBackplan from target to weekly/daily/session plan. |
| P02-SI-011 | Explicit MemoryCurvePolicy for spacing, forgetting risk, overlearning and interleaving. |

## Excluded Stage Scope Items
- P02-SI-006, P02-SI-010, P02-SI-012 and P02-SI-013 are routed to `p0-2-autopilot-progress-checkpoint`.
- P02-SI-007 and P02-SI-008 are upstream inputs from `p0-2-goal-diagnostic-foundation`.

## Supersession Note
The previous single memory-planner artifact has been removed as an active source of truth. P02-SI-001 through P02-SI-005, P02-SI-009 and P02-SI-011 must be regenerated through this increment's downstream requirements, spec, acceptance criteria, test cases and traceability before implementation.

## Non-goals
- 不实现用户公开场景生成、完整 A1-C2 内容体系或 content CMS。
- 不实现自动带练 UI/notification/checkpoint loop；这些属于后续 P0.2 autopilot increment。
- 不关闭商业发布或 paid AI voice gates。

## Required Downstream Artifacts
- requirements/spec/acceptance/test_cases/traceability for this increment.
- Domain model for Backplan, ReviewSchedulePolicy, ForgettingRisk, InterleavingGroup and PlanItem.
- API/OpenAPI for weekly/daily/session plan generation and plan actions.
- QA fixtures for memory curve and replay determinism.
- P02-PG-001 GoalAchievementPolicy coverage: target-gap calculation inputs, confidence-aware plan intensity, no false ETA precision, no goal-complete claim without checkpoint evidence and forecast uncertainty rules.
- P02-PG-002 SupportedGoalMatrix coverage: plan generation must fail closed or downgrade when the goal lacks enough scenario, task, rubric or expression coverage.
- P02-PG-003 AutopilotControlPolicy coverage: deterministic planner feasibility, daily time budget, overload guard, priority conflict rules, skipped/missed-day recomputation, pause/resume effects, memory curve replay fixtures and plan recalculation audit.
- P02-PG-004 CommercialEntitlementAndCostPolicy coverage: plan depth by entitlement, AI usage reservation for plan generation/review scheduling, low-cost fallback, cost telemetry and commercial downgrade rules.
- P02-PG-005 DataGovernancePolicy coverage: plan/audit retention, deletion behavior, redaction of diagnostic evidence in planner snapshots and user-visible explanation of why a plan item appears.
