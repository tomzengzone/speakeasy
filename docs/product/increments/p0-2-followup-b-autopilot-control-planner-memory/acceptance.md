# P0.2 Followup-B Acceptance Criteria：自动带练控制与计划记忆引擎加固

## 状态
Acceptance accepted / AC-to-TC mapped / executed through S005 mastery transition - 本文件基于 Followup-B requirements 和 spec 定义验收标准；test_cases、contracts、reports 和 traceability FR/Spec/AC/TC rows 已生成。当前 AC-P02-FUB-001/002 的 control source、TC-P02-FUB-002 control data governance、pause/resume/update-control 子集已有 backend/frontend 本地执行证据；AC-P02-FUB-003 的 notification eligibility policy 已通过 TC-P02-FUB-005/006；AC-P02-FUB-004 的 notification outbox lifecycle/replay 已通过 TC-P02-FUB-007/008；AC-P02-FUB-005 的 S003 missed-day recovery planner 已通过 TC-P02-FUB-009/010；AC-P02-FUB-006 的 S004 item-level MemoryCurvePolicy 已通过 TC-P02-FUB-011/012；AC-P02-FUB-007 的 S005 mastery transition / AI candidate-only explanation guardrails 已通过 TC-P02-FUB-013/014。AC-P02-FUB-008 仍保持 planned/open，不能据此声明 Followup-B 完成。

## 上游来源
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/requirements.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/spec.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/definition.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/traceability.md`

## Stage Scope Acceptance Coverage
| Stage Scope ID | Policy Gate | WP ID | Requirement ID | Spec ID | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- |
| P02-SI-010 | P02-PG-002, P02-PG-003, P02-PG-005 | P02-FUB-WP-001 | P02-FUB-FR-001 | P02-FUB-SPEC-001 | AC-P02-FUB-001 |
| P02-SI-010 | P02-PG-002, P02-PG-003 | P02-FUB-WP-002 | P02-FUB-FR-002 | P02-FUB-SPEC-002 | AC-P02-FUB-002 |
| P02-SI-010 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUB-WP-003 | P02-FUB-FR-003 | P02-FUB-SPEC-003 | AC-P02-FUB-003 |
| P02-SI-010 | P02-PG-003, P02-PG-005 | P02-FUB-WP-004 | P02-FUB-FR-004 | P02-FUB-SPEC-004 | AC-P02-FUB-004 |
| P02-SI-001, P02-SI-004, P02-SI-005, P02-SI-009 | P02-PG-002, P02-PG-003 | P02-FUB-WP-005 | P02-FUB-FR-005 | P02-FUB-SPEC-005 | AC-P02-FUB-005 |
| P02-SI-001, P02-SI-002, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-FUB-WP-006 | P02-FUB-FR-006 | P02-FUB-SPEC-006 | AC-P02-FUB-006 |
| P02-SI-003, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-FUB-WP-007 | P02-FUB-FR-007 | P02-FUB-SPEC-007 | AC-P02-FUB-007 |
| P02-SI-001, P02-SI-002, P02-SI-003, P02-SI-004, P02-SI-005, P02-SI-009, P02-SI-010, P02-SI-011 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUB-WP-008 | P02-FUB-FR-008 | P02-FUB-SPEC-008 | AC-P02-FUB-008 |

## Implementation Slice Acceptance Routing
| Slice ID | Scope | Acceptance | Test cases | Required fixture evidence |
| --- | --- | --- | --- | --- |
| P02-FUB-SLICE-001 | UserAutopilotControl source、pause/resume/update-control | AC-P02-FUB-001, AC-P02-FUB-002 | TC-P02-FUB-001..004 | FUB-FIX-001, FUB-FIX-002 |
| P02-FUB-SLICE-002 | Notification eligibility and scheduler/outbox | AC-P02-FUB-003, AC-P02-FUB-004 | TC-P02-FUB-005..008 | FUB-FIX-003, FUB-FIX-004 |
| P02-FUB-SLICE-003 | Missed-day recovery planner | AC-P02-FUB-005 | TC-P02-FUB-009..010 | FUB-FIX-005 |
| P02-FUB-SLICE-004 | Item-level MemoryCurvePolicy | AC-P02-FUB-006 | TC-P02-FUB-011..012 | FUB-FIX-006 |
| P02-FUB-SLICE-005 | L0-L5 mastery transition and AI candidate-only explanation | AC-P02-FUB-007 | TC-P02-FUB-013..014 | FUB-FIX-007 |
| P02-FUB-SLICE-006 | Replay, performance, coverage and final review gates | AC-P02-FUB-008 | TC-P02-FUB-015..017 | FUB-FIX-008, FUB-FIX-009 |

## AC-P02-FUB-001 UserAutopilotControl Source Of Truth
- Given a learner has an active goal context, the system must expose a server-owned UserAutopilotControl state instead of deriving autopilot control from GoalProfile fields, Flutter local cache or latest UI intent.
- Given the active goal is unsupported, partial without a safe plan, stale or missing required planner input, the control state must block full autopilot and full reminder cadence.
- Given UserAutopilotControl is persisted, deletion/export/retention behavior must include control, audit and notification-related records according to the downstream data-governance contract.
- Given the client reads control state, the visible status must distinguish at least active, paused and policy-blocked states.

## AC-P02-FUB-002 Pause, Resume And Update-Control
- Given the user pauses autopilot, the system must suppress new automatic prompts, executable next-action advancement and future reminder scheduling while preserving recoverable goal, plan, memory and evidence state.
- Given pause is requested more than once while already paused, the operation must be idempotent and must not duplicate cancellation or audit effects beyond a deduped note.
- Given the user resumes autopilot, the system must re-evaluate plan freshness, missed days, quiet hours, fatigue, support status and entitlement before any prompt or reminder becomes eligible.
- Given the user updates intensity, quiet hours, notification consent or missed-day policy, the response must report next-action impact, reminder eligibility impact, replan requirement and reason code.
- Given Flutter receives a server control state, UI must render that state and must not locally override active, paused or eligibility decisions.

## AC-P02-FUB-003 Quiet Hours And Notification Eligibility
- Given a notification is about to be scheduled, rescheduled or sent, the system must check control status, quiet hours, timezone, notification consent, platform permission, entitlement, quota/cost decision, plan status and support status first.
- Given multiple reminder blocks apply, the system must return the first matching reason from the spec reason-precedence table and must produce the same result for the same input snapshot and rule version.
- Given quiet hours block a reminder, the system must not send the reminder and must return `quiet_hours` reason code plus a next allowed time when calculable.
- Given quiet hours cross midnight, the system must evaluate the blocked window in the configured timezone; given start and end are equal, quiet hours must be treated as disabled unless a later all-day contract exists.
- Given permission, consent, entitlement, quota, unsupported goal, partial limitation, stale plan or missing plan blocks a reminder, the system must return a matching reason code and safe user-visible explanation.
- Given a reminder is blocked or unsent, the system must not record that outcome as user completion, refusal, failure or missed-day evidence.
- Given notification content is generated, it must not expose sensitive diagnostic transcript, exact high-risk goal details, official-score equivalence or guaranteed outcome claims.

## AC-P02-FUB-004 Notification Scheduler Or Outbox
- Given a reminder is eligible, the system must create or update a scheduler/outbox record with replayable lifecycle state rather than relying on a fire-and-forget send path.
- Given reminders are scheduled, the lifecycle must distinguish pending, scheduled, blocked, sent, cancelled, failed and expired states.
- Given pause, consent withdrawal, quiet-hours change, unsupported/stale goal status or entitlement block occurs, no-longer-compliant reminders must be cancelled or blocked before sending.
- Given duplicate schedule attempts occur for the same user, goal revision, plan item, reminder slot and rule version, the system must dedupe them.
- Given scheduler/outbox processing fails, the system must surface a recoverable state and must not create duplicate reminders or unexplained next-action changes.
- Given an outbox record exists, it must include input snapshot hash, rule version, reason code, processing status and failure reason when applicable.
- Given an outbox record is exposed for replay or troubleshooting, raw notification payloads, sensitive diagnostic details and exact high-risk target details must be redacted or represented only by safe hashes/keys.
- Given a reminder slot expires before a compliant send, the outbox lifecycle must record `expired` rather than silently dropping the reminder.

## AC-P02-FUB-005 Missed-Day Recovery Planner
- Given the user misses a day, skips, defers, resumes after a pause gap, hits a stale plan or has an expired plan item, the system must generate a recovery decision instead of stacking all overdue tasks into the next day.
- Given recovery is needed, the system must choose one primary mode: compress, defer or replace.
- Given `compress` is chosen, the resulting plan must fit the user's daily minutes and reduce scope rather than exceed the time budget.
- Given `defer` is chosen, lower-priority work may move later while risk-driving items remain visible.
- Given `replace` is chosen, impossible work must be swapped for a smaller review or training block.
- Given recovery is generated, daily/weekly stale or replan status must update with reason code, source event, input snapshot hash and rule version.
- Given multiple recovery modes are viable, hard safety and feasibility rules must override user preference, and `balanced` policy must resolve deterministically instead of choosing an arbitrary mode.
- Given recovery creates a daily plan update, the workload must stay within daily minutes plus any explicit intensity allowance and must not hide risk-driving items.

## AC-P02-FUB-006 Item-Level MemoryCurvePolicy
- Given memory scheduling runs, decisions must operate on item-level memory state for expressions, scenarios, weaknesses or plan items rather than only session-level or goal-level summaries.
- Given a memory item is evaluated, the decision must consider forgetting risk, retrieval success, recent failures, exposure count, overlearning count, interleaving group, pressure level and daily time budget.
- Given an item hits the overlearning cap without a high-risk override, the system must avoid selecting that item for repeated practice.
- Given viable alternatives exist, interleaving must prevent the selected plan from concentrating only on one expression, scenario or weakness group.
- Given the same input snapshot and rule version are replayed, the item-level due decision and reason code must match the original decision.
- Given acceptance fixtures use default memory constants, high risk, due risk, overlearning cap, interleaving cap and review intervals must be recorded with the rule version that produced the decision.
- Given control is paused or policy-blocked, item-level memory evaluation must return a control-blocked decision instead of selecting review work.

## AC-P02-FUB-007 L0-L5 Promotion And Demotion
- Given L0-L5 transition is considered, the system must use accepted diagnostic, training, retrieval, repeated-failure, checkpoint and confidence evidence only.
- Given evidence is low-confidence, insufficient, partial, unsupported or protected by fatigue policy, the system must not force promotion to a higher mastery level.
- Given repeated failure, retrieval regression or checkpoint evidence indicates risk, the system must support hold or demotion decisions.
- Given AI output contains final mastery, promotion/demotion, review schedule or goal completion as persistent state, the system must reject or ignore those fields for persistence.
- Given a transition is applied, the record must include previous level, proposed level, accepted level, direction, evidence references, confidence, reason code, rule version and audit timestamp.
- Given the transition is explained to the user, the explanation must preserve product-internal mastery wording and must not imply official exam certification.
- Given promotion is accepted, it must advance at most one L0-L5 level per deterministic decision.
- Given demotion is accepted, it must be based on repeated failure, retrieval regression or checkpoint regression with accepted evidence and sufficient confidence.

## AC-P02-FUB-008 Replay, Performance And Coverage Gates
- Given Followup-B implementation is requested, routing must remain blocked until every approved AC maps to stable TC IDs or explicit allowed exceptions in `test_cases.md`.
- Given replay fixtures run, they must cover control source, pause/resume, update-control, quiet-hours eligibility, notification outbox lifecycle, missed-day recovery, item-level memory due decision and L0-L5 transition.
- Given replay verification runs, it must compare expected decision, reason code, output state and rule version.
- Given performance tests run, they must cover control state load, pause/resume/update-control, notification eligibility, recovery replan, item-level memory due calculation, L0-L5 transition decision and replay verification p95 budgets.
- Given fixture replay runs, fixture IDs FUB-FIX-001 through FUB-FIX-009 must preserve input snapshot hash, output decision, reason code, output state and rule version where applicable.
- Given changed backend/domain/API/Flutter code exists, line and branch coverage for changed code must be >=80%; unchanged layers must be explicitly marked `N/A - no code change in this layer`.
- Given reports or traceability are updated, they must not mark Followup-B complete until requirements, spec, acceptance, test_cases, traceability, contracts, code evidence, test evidence, performance/replay evidence and independent review are all closed.

## Negative And Edge Coverage Requirements
- Unsupported or partial goals must block full autopilot, high-confidence reminder cadence and goal-completion claims.
- Paused control must block new prompts, executable next-action advancement and future reminder scheduling.
- Quiet-hours, permission denial, consent withdrawal, entitlement block, quota exhaustion, stale plan and missing plan must each have distinct reason codes.
- Missed-day recovery must prove no overdue task stacking.
- Overlearning cap and interleaving must be testable against item-level memory fixtures.
- AI forbidden persistent fields must be rejected or ignored for final mastery, review schedule, notification schedule and goal completion.

## AC-to-TC Requirement
Every AC-P02-FUB-001 through AC-P02-FUB-008 must map to at least one stable TC-P02-FUB ID or explicit allowed exception in `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/test_cases.md` before implementation routing.

## 下游交接边界
- `test_cases.md`、`traceability.md`、domain/API/OpenAPI/UX/AI contracts 和 reports may consume this file as the AC source of truth, but they must not renumber or redefine AC-P02-FUB-001 through AC-P02-FUB-008 without a versioned Followup-B change.
- Test execution status belongs in `test_cases.md`, `docs/reports/test_report.md` and `traceability.md`; this file may summarize current status but must not replace executable Test Evidence.
- 本文件不声明 release 已批准，也不把 partial control-slice evidence 解释为 Followup-B 全量完成。
