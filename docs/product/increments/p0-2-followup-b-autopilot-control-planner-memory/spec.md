# P0.2 Followup-B Spec：自动带练控制与计划记忆引擎加固

## 状态
Spec accepted / downstream executed through S004 item-level memory - 本文件把 Followup-B requirements 下沉为可验收的行为规格；acceptance、test_cases、traceability、Domain、API/OpenAPI/generated client、AI runtime 和 UX 合同已生成并完成 pre-implementation 审核。当前 UserAutopilotControl read/update/pause/resume、TC-P02-FUB-002 control data governance、Flutter control binding、S002-A notification eligibility policy、S002-B notification outbox lifecycle/replay、S003 missed-day recovery planner 与 S004 item-level MemoryCurvePolicy 已有本地执行证据；mastery transition、global replay/performance/final review 仍保持 planned/open。

## 上游引用
- Increment definition：`docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/definition.md`
- Increment requirements：`docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/requirements.md`
- WP traceability scaffold：`docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/traceability.md`
- Active stage：`docs/product/stages/p0-2-training-memory.md`
- Upstream plan design：`docs/product/increments/p0-2-goal-backplan-memory-policy/`
- Upstream autopilot design：`docs/product/increments/p0-2-autopilot-progress-checkpoint/`

## 规格假设和依赖
- Followup-B 只加固自动带练控制、通知语义、恢复计划、item-level memory 和 L0-L5 转移；不重新定义 GoalProfile、DiagnosticAssessment、ProgressForecast 或 OutcomeCheckpoint。
- 所有自动带练控制事实由服务端拥有；Flutter 只能展示和提交控制意图，不能本地决定 final control state。
- LLM 输出只能作为候选解释或候选观察；最终计划、提醒、记忆和 mastery 状态必须由确定性规则接受。
- 本规格只描述所需合同影响；domain/API/OpenAPI/UX/AI runtime 契约必须在后续独立步骤中更新并审核。

## Spec Trace IDs
| Spec ID | Stage Scope ID | Policy Gate | WP ID | Requirement ID | Spec area |
| --- | --- | --- | --- | --- | --- |
| P02-FUB-SPEC-001 | P02-SI-010 | P02-PG-002, P02-PG-003, P02-PG-005 | P02-FUB-WP-001 | P02-FUB-FR-001 | UserAutopilotControl source of truth |
| P02-FUB-SPEC-002 | P02-SI-010 | P02-PG-002, P02-PG-003 | P02-FUB-WP-002 | P02-FUB-FR-002 | Pause, resume and update-control behavior |
| P02-FUB-SPEC-003 | P02-SI-010 | P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUB-WP-003 | P02-FUB-FR-003 | Quiet hours and notification eligibility |
| P02-FUB-SPEC-004 | P02-SI-010 | P02-PG-003, P02-PG-005 | P02-FUB-WP-004 | P02-FUB-FR-004 | Notification scheduler or outbox |
| P02-FUB-SPEC-005 | P02-SI-001, P02-SI-004, P02-SI-005, P02-SI-009 | P02-PG-002, P02-PG-003 | P02-FUB-WP-005 | P02-FUB-FR-005 | Missed-day recovery planner |
| P02-FUB-SPEC-006 | P02-SI-001, P02-SI-002, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-FUB-WP-006 | P02-FUB-FR-006 | Item-level MemoryCurvePolicy |
| P02-FUB-SPEC-007 | P02-SI-003, P02-SI-011 | P02-PG-001, P02-PG-003 | P02-FUB-WP-007 | P02-FUB-FR-007 | L0-L5 promotion and demotion |
| P02-FUB-SPEC-008 | P02-SI-001, P02-SI-002, P02-SI-003, P02-SI-004, P02-SI-005, P02-SI-009, P02-SI-010, P02-SI-011 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUB-WP-008 | P02-FUB-FR-008 | Replay, performance and coverage gates |

## Contract Boundary Decision
Followup-B requires downstream contract updates, but this spec step does not update those contracts.

Required downstream contract work:
- Domain model：`UserAutopilotControl`、`NotificationEligibilityDecision`、`NotificationOutboxRecord`、`RecoveryPlanDecision`、`MemoryItemPolicyState`、`MasteryTransitionDecision` 和 `PlannerReplayAudit`。
- API/OpenAPI：get/update control、pause、resume、notification eligibility、recovery replan、memory due decision exposure where needed、mastery transition audit exposure where needed。
- UX screen spec：paused、resume recovery、quiet-hours blocked、notification disabled、intensity override、missed-day recovery 和 memory/mastery explanation states。
- AI runtime schema：AI candidate explanation must not include persistent final mastery、review schedule、notification schedule or goal completion fields.

If any implementation discovers a missing contract field, implementation must stop and route the relevant contract step before code continues.

## Implementation Slice Routing
Followup-B implementation must proceed by routed slice. A later slice may reuse earlier slice facts, but it must not mark Followup-B complete until its own AC/TC, contract evidence, replay evidence and report evidence are closed.

| Slice ID | Scope | Primary state nodes | API boundary | AC/TC routing | Fixture routing | Completion evidence |
| --- | --- | --- | --- | --- | --- | --- |
| P02-FUB-SLICE-001 | UserAutopilotControl source、pause/resume/update-control | `ControlActive`, `Paused`, `ControlUpdated`, `ResumeRequested` | `GET/PATCH /goal-autopilot/control`, `POST /goal-autopilot/control/pause`, `POST /goal-autopilot/control/resume` | AC-P02-FUB-001..002 / TC-P02-FUB-001..004 | FUB-FIX-001 control source, FUB-FIX-002 pause/resume/update-control | Backend/API/Flutter evidence exists for routed control subset; TC-P02-FUB-002 closes current control/audit/idempotency data governance; outbox governance closes separately in S002-B |
| P02-FUB-SLICE-002 | Notification eligibility and scheduler/outbox | `EligibilityCheck`, `ReminderEligible`, `ReminderBlocked`, `OutboxPending`, `OutboxScheduled` | `POST /goal-autopilot/reminders/eligibility`, `GET /goal-autopilot/reminders/outbox` | AC-P02-FUB-003..004 / TC-P02-FUB-005..008 | FUB-FIX-003 notification eligibility, FUB-FIX-004 outbox lifecycle | Eligibility reason precedence, outbox lifecycle, dedupe and failure replay evidence |
| P02-FUB-SLICE-003 | Missed-day recovery planner | `RecoveryRequired`, `RecoveryPlanned` | `POST /goal-autopilot/recovery/replan` | AC-P02-FUB-005 / TC-P02-FUB-009..010 | FUB-FIX-005 missed-day recovery | Executed for S003 recovery planner; compress/defer/replace decision evidence and no-overdue-stacking assertions passed |
| P02-FUB-SLICE-004 | Item-level MemoryCurvePolicy | `MemoryDuePlanning` | `POST /goal-autopilot/item-policy/decisions` | AC-P02-FUB-006 / TC-P02-FUB-011..012 | FUB-FIX-006 item-level memory due | Executed for S004 memory; forgetting risk, retrieval success/failure, overlearning, interleaving, budget, paused/control-blocked, default intervals and replay-determinism evidence passed |
| P02-FUB-SLICE-005 | L0-L5 mastery transition and AI candidate-only explanation | `MasteryTransitionPending`, `MasteryTransitionApplied` | `GET /goal-autopilot/mastery-transitions`, AI explanation validator | AC-P02-FUB-007 / TC-P02-FUB-013..014 | FUB-FIX-007 mastery transition | evidence threshold, hold/demotion and AI forbidden-field rejection evidence |
| P02-FUB-SLICE-006 | Replay, performance, coverage and final review gates | All Followup-B state nodes | `GET /goal-autopilot/replay-audits` and QA scripts | AC-P02-FUB-008 / TC-P02-FUB-015..017 | FUB-FIX-008 replay corpus, FUB-FIX-009 performance corpus | replay match, p95 budgets, >=80% changed-code coverage and independent review evidence |

Slice ordering for remaining implementation after S004 is S005 mastery and S006 replay/performance/final review. S006 may run targeted replay checks after any earlier slice, but final S006 closure must happen last.

## Inputs
- Active learner identity and authenticated session.
- Active GoalProfile revision and support status from Followup-A/upstream diagnostic facts.
- Active WeeklyBackplan、DailyTrainingPlan、PlanItem and stale/replan status.
- Existing learning evidence、diagnostic evidence、retrieval attempts、checkpoint evidence and confidence signals.
- Server-owned UserAutopilotControl state.
- Platform notification permission、notification consent、quiet-hours timezone and entitlement/quota/cost decision.
- Memory item inventory for expressions、scenarios、weaknesses or plan items.
- Current rule version and replay input snapshot.

## Outputs
- UserAutopilotControl state visible to API clients and planner/autopilot services.
- Control update result with current control status、next-action impact、reminder eligibility impact and replan requirement.
- Notification eligibility decision with reason code.
- Notification scheduler/outbox record with lifecycle state and replayable audit fields.
- Recovery plan decision with compress、defer or replace mode.
- Item-level memory due decision with forgetting risk、review action and next due date.
- L0-L5 mastery transition decision with evidence references and rule version.
- Planner replay audit entries suitable for deterministic fixture validation.

## State Model
| State | Meaning | Allowed next states |
| --- | --- | --- |
| `ControlActive` | UserAutopilotControl allows autopilot evaluation | `Paused`, `EligibilityCheck`, `RecoveryRequired`, `MemoryDuePlanning` |
| `Paused` | User explicitly paused autopilot | `ResumeRequested`, `ControlUpdated` |
| `ControlUpdated` | User changed intensity、quiet hours、consent or missed-day policy | `EligibilityCheck`, `RecoveryRequired`, `ControlActive`, `Paused` |
| `ResumeRequested` | User resumes after pause | `RecoveryRequired`, `EligibilityCheck`, `ControlActive` |
| `EligibilityCheck` | System checks reminder and next-action eligibility | `ReminderEligible`, `ReminderBlocked`, `RecoveryRequired` |
| `ReminderEligible` | Reminder can be scheduled or queued | `OutboxPending`, `OutboxScheduled` |
| `ReminderBlocked` | Reminder is blocked by control、quiet hours、permission、entitlement、quota or stale plan | `ControlUpdated`, `EligibilityCheck`, `ControlActive` |
| `OutboxPending` | Notification request exists but is not sent | `OutboxScheduled`, `OutboxBlocked`, `OutboxCancelled`, `OutboxFailed`, `OutboxExpired` |
| `OutboxScheduled` | Notification request is scheduled for a compliant slot | `OutboxSent`, `OutboxBlocked`, `OutboxCancelled`, `OutboxFailed`, `OutboxExpired` |
| `RecoveryRequired` | Missed、skip、defer、pause gap or stale plan requires recovery | `RecoveryPlanned`, `ControlUpdated` |
| `RecoveryPlanned` | Feasible recovery decision exists | `MemoryDuePlanning`, `ControlActive` |
| `MemoryDuePlanning` | Item-level memory decisions are being evaluated | `MasteryTransitionPending`, `ControlActive` |
| `MasteryTransitionPending` | Accepted evidence may change L0-L5 | `MasteryTransitionApplied`, `ControlActive` |
| `MasteryTransitionApplied` | Evidence-driven transition is persisted with audit | `ControlActive`, `RecoveryRequired` |

## Deterministic Policy Tables

### Control And Notification Reason Precedence
When multiple reminder blocks apply, the system returns the first matching reason in this table. The same input snapshot and rule version must return the same `reason_code`, `eligible`, `next_allowed_at` and output state.

| Order | Condition | Reason code | Eligible | Output state | Required assertion |
| --- | --- | --- | --- | --- | --- |
| 1 | UserAutopilotControl is paused | `paused` | false | `ReminderBlocked` | No new prompt, next-action advancement or reminder scheduling |
| 2 | Control is policy-blocked by data or safety policy | `blocked_by_policy` | false | `ReminderBlocked` | Client cannot override server state |
| 3 | Goal is unsupported | `unsupported_goal` | false | `ReminderBlocked` | No full autopilot cadence or goal-completion claim |
| 4 | Goal is partial without safe plan | `partial_goal_limited` | false | `ReminderBlocked` | High-confidence reminders are blocked |
| 5 | Active plan is stale | `stale_plan` | false | `RecoveryRequired` | Recovery/replan requirement is surfaced |
| 6 | Required plan or planner input is missing | `missing_plan` | false | `ReminderBlocked` | Missing data is not treated as user refusal or missed-day evidence |
| 7 | User notification consent is missing or withdrawn | `consent_missing` | false | `ReminderBlocked` | Existing no-longer-compliant outbox records are cancelled or blocked |
| 8 | Platform permission is denied | `permission_denied` | false | `ReminderBlocked` | Safe user-visible explanation is returned |
| 9 | Entitlement or commercial gate blocks reminders | `entitlement_blocked` | false | `ReminderBlocked` | No reminder is scheduled outside the allowed plan |
| 10 | Quota or cost gate is exhausted | `quota_exhausted` | false | `ReminderBlocked` | No paid/high-cost reminder path is invoked |
| 11 | Current local time is inside quiet hours | `quiet_hours` | false | `ReminderBlocked` | `next_allowed_at` is returned when calculable |
| 12 | No block applies | `eligible` | true | `ReminderEligible` | Reminder may enter scheduler/outbox boundary |

Quiet-hours evaluation uses the user's configured timezone. If `quiet_hours_start < quiet_hours_end`, the blocked window is `start <= now < end`. If `quiet_hours_start > quiet_hours_end`, the blocked window crosses midnight and is `now >= start OR now < end`. If start and end are equal, quiet hours are treated as disabled unless a future explicit all-day flag is added through a separate contract update.

### Notification Outbox Lifecycle Table
| Current state | Event | Next state | Required deterministic fields |
| --- | --- | --- | --- |
| none | Eligibility returns `eligible` | `pending` | dedupe key, input snapshot hash, rule version, reason code |
| `pending` | Worker accepts schedule request | `scheduled` | processing status, scheduled slot, next attempt cleared |
| `pending` or `scheduled` | Pause, consent withdrawal, unsupported/stale goal or entitlement block occurs | `cancelled` or `blocked` | cancellation/block reason, rule version, audit timestamp |
| `pending` or `scheduled` | Quiet-hours update makes slot non-compliant | `blocked` | `quiet_hours`, recalculated `next_allowed_at` |
| `scheduled` | Provider or platform send succeeds | `sent` | send timestamp, redacted payload hash |
| `pending` or `scheduled` | Transient worker/provider failure occurs | `failed` | failure reason, retry count, next attempt time |
| `pending`, `scheduled` or `failed` | Reminder slot expires before compliant send | `expired` | expiry reason and original slot |
| any non-terminal state | Duplicate schedule attempt with same dedupe key | unchanged | original record is returned or referenced; no duplicate reminder |

The outbox dedupe key is `learner_id + goal_revision_id + plan_item_id + reminder_slot + rule_version`. Raw notification payloads, sensitive diagnostic details and exact high-risk target details must not be exposed through the outbox projection.

### Missed-Day Recovery Mode Table
Recovery chooses exactly one primary mode. Hard safety and feasibility rules override the user's missed-day policy preference; otherwise the user policy acts as a deterministic tie-breaker.

| Priority | Condition | Recovery mode | Required output |
| --- | --- | --- | --- |
| 1 | No active safe plan, unsupported goal or required planner input missing | `replace` | Smaller safe review/training block or blocked recovery reason; no overdue stacking |
| 2 | Fatigue risk is high or daily minutes cannot fit risk-driving work after compression | `replace` | Feasible smaller block, affected item refs and reason code |
| 3 | Deadline slack exists and lower-priority unfinished work can move without hiding risk-driving items | `defer` | Deferred item refs, preserved risk-driving items and stale/replan marker |
| 4 | Risk-driving work is due and can fit within daily minutes after scope reduction | `compress` | Reduced feasible block within daily minutes |
| 5 | Multiple modes remain viable | User `missed_day_policy` preference when it is `compress`, `defer` or `replace`; `balanced` resolves to `defer`, then `compress`, then `replace` | Deterministic reason code and source event |

Recovery must cap the generated daily workload at the user's daily minutes plus any explicitly configured intensity allowance. It must never move all overdue plan items into the next day as a single stacked plan.

### Item-Level Memory Due Decision Table
Memory due decisions operate on normalized `forgetting_risk` in `[0, 1]` and stable rule-version constants. Initial acceptance constants are: high risk `>= 0.70`, due risk `>= 0.45`, overlearning cap `2` selected reviews per item per 24 hours, and interleaving cap `2` consecutive selected items from the same interleaving group when viable alternatives exist.

| Priority | Condition | Due decision | Required output |
| --- | --- | --- | --- |
| 1 | Control is paused or policy-blocked | `blocked_by_control` | No review selection; reason code references control state |
| 2 | High-risk evidence exists or recent repeated failure overrides cap | `review_due` | Selected action, evidence refs and next due date |
| 3 | Overlearning count reaches cap and no high-risk override exists | `skip_overlearning_cap` | Item skipped with cap reason |
| 4 | Daily memory budget is exhausted | `defer_budget` | Deferred item and next evaluation window |
| 5 | Interleaving cap would be exceeded and viable alternative exists | `interleave_alternative` | Alternative item ref or group reason |
| 6 | Forgetting risk is due by threshold or elapsed interval | `review_due` | Review action and next due date |
| 7 | No due rule matches | `review_not_due` | Stable non-due reason |

Default review intervals for acceptance fixtures are L0 one day, L1 two days, L2 four days, L3 seven days, L4 fourteen days and L5 thirty days. Implementations may externalize these constants, but fixtures must record the rule version that produced the decision.

### L0-L5 Mastery Transition Table
Transitions use accepted evidence only. Promotion is at most one level per decision. Hold and demotion are first-class outcomes, not failures.

| Outcome | Required condition | Reason code family | Required output |
| --- | --- | --- | --- |
| promote one level | Enough accepted evidence for target level, no recent blocking regression, confidence meets threshold | `evidence_promotion` | previous level, proposed level, accepted level, confidence, evidence refs |
| hold | Evidence is insufficient, low confidence, partial/unsupported, fatigue-protected or contradictory | `insufficient_evidence`, `low_confidence`, `partial_goal_limited`, `fatigue_protected` | accepted level equals previous level with explanation key |
| demote one level | Repeated failure, retrieval regression or checkpoint evidence shows risk with sufficient confidence | `retrieval_regression`, `repeated_failure`, `checkpoint_regression` | accepted level below previous level with evidence refs |
| reject persistence | AI output attempts final mastery, review schedule, notification schedule, recovery mode, goal completion or official score claim | `ai_forbidden_persistent_field` | AI candidate rejected or ignored; deterministic fallback explanation used |

Initial confidence thresholds for acceptance fixtures are L0->L1 `>=0.65`, L1->L2 `>=0.70`, L2->L3 `>=0.75`, L3->L4 `>=0.80` and L4->L5 `>=0.85`. Demotion requires at least two recent failures or one accepted checkpoint regression with confidence `>=0.70`. These thresholds are product-internal readiness rules and must not be rendered as official exam certification.

### Replay Fixture Corpus
| Fixture ID | Slice | Required scenarios | Primary TC |
| --- | --- | --- | --- |
| FUB-FIX-001 | S001 control source | active, paused, policy-block state, unsupported/partial/stale/missing input | TC-P02-FUB-001, TC-P02-FUB-002 |
| FUB-FIX-002 | S001 control commands | idempotent pause, resume re-evaluation, update-control impact fields | TC-P02-FUB-003, TC-P02-FUB-004 |
| FUB-FIX-003 | S002 eligibility | reason precedence, quiet-hours crossing midnight, consent/permission/entitlement/quota/stale/missing plan | TC-P02-FUB-005, TC-P02-FUB-006 |
| FUB-FIX-004 | S002 outbox | pending/scheduled/blocked/cancelled/failed/expired/sent, dedupe and retry | TC-P02-FUB-007, TC-P02-FUB-008 |
| FUB-FIX-005 | S003 recovery | compress/defer/replace, high fatigue, deadline slack, no overdue stacking | TC-P02-FUB-009, TC-P02-FUB-010 |
| FUB-FIX-006 | S004 memory | high risk, due threshold, overlearning cap, interleaving cap, budget defer, replay determinism | TC-P02-FUB-011, TC-P02-FUB-012 |
| FUB-FIX-007 | S005 mastery | promotion, hold, demotion, low confidence, forbidden AI fields | TC-P02-FUB-013, TC-P02-FUB-014 |
| FUB-FIX-008 | S006 replay | all decision families compare decision, reason code, output state and rule version | TC-P02-FUB-015 |
| FUB-FIX-009 | S006 performance | p95 budgets for control, eligibility, outbox, recovery, memory, mastery and replay | TC-P02-FUB-016 |

## P02-FUB-SPEC-001 UserAutopilotControl Source Of Truth
- UserAutopilotControl is a server-owned fact bound to a learner and active goal context.
- Required fields at contract level: `control_status`, `paused_at`, `pause_reason`, `resumed_at`, `quiet_hours_start`, `quiet_hours_end`, `timezone`, `intensity_override`, `notification_consent`, `missed_day_policy`, `updated_at`, `rule_version` and audit metadata.
- `control_status` must distinguish at least `active`, `paused` and `blocked_by_policy`.
- `missed_day_policy` must distinguish at least `balanced`, `compress`, `defer` and `replace`.
- Full autopilot and reminder cadence are blocked when the active goal is unsupported, partial without a safe plan, stale, missing required planner input or blocked by entitlement/data policy.
- Account deletion or data export flows must include UserAutopilotControl and related audit/outbox records according to downstream data-governance contract.

## P02-FUB-SPEC-002 Pause, Resume And Update-Control Behavior
- Pause is idempotent. Repeating pause while already paused must not duplicate audit events or notification cancellation work beyond a deduped audit note.
- Pausing suppresses new automatic prompts, new executable next-action advancement and future reminder scheduling. Existing goal, plan, memory and evidence facts remain recoverable.
- Resume must re-evaluate active plan freshness, missed days, quiet hours, fatigue risk, support status and entitlement before any prompt or reminder becomes eligible.
- Update-control applies to intensity, quiet hours, notification consent and missed-day policy through one server-owned update result.
- Update-control must return whether next action changed, whether reminders are eligible, whether recovery/replan is required and a reason code.
- Flutter must render the returned state. It must not locally mark autopilot active, paused or eligible when the server state says otherwise.

## P02-FUB-SPEC-003 Quiet Hours And Notification Eligibility
- Notification eligibility runs before schedule, reschedule or send.
- Eligibility inputs include control status, quiet-hours window, timezone, notification consent, platform permission, entitlement, quota/cost decision, active plan status and support status.
- Quiet hours may cross midnight and must be evaluated in the user's configured timezone.
- Eligibility output must include `eligible=true|false`, `reason_code`, `next_allowed_at` when blocked by time, and safe user-visible explanation text or explanation key.
- Required blocked reason codes include at least `paused`, `blocked_by_policy`, `quiet_hours`, `permission_denied`, `consent_missing`, `entitlement_blocked`, `quota_exhausted`, `unsupported_goal`, `partial_goal_limited`, `stale_plan` and `missing_plan`.
- A blocked or unsent notification must not be interpreted as completion, refusal, failure or missed-day evidence.
- Notification content must avoid sensitive diagnostic transcripts, exact target-risk details and unsupported official-score claims.

## P02-FUB-SPEC-004 Notification Scheduler Or Outbox
- Followup-B must use a scheduler or outbox boundary with replayable lifecycle states rather than fire-and-forget reminder calls.
- Required lifecycle states are `pending`, `scheduled`, `blocked`, `sent`, `cancelled`, `failed` and `expired`.
- Required operations are schedule, cancel, reschedule, dedupe and failure recovery.
- Dedupe must use a stable key that prevents duplicate reminders for the same user, goal revision, plan item, reminder slot and rule version.
- Pause, consent withdrawal, quiet-hours update, unsupported/stale goal status and entitlement block must cancel or block no-longer-compliant records.
- Outbox records must keep input snapshot hash, rule version, reason code, processing status, next attempt time and failure reason when applicable.
- Scheduler/outbox failure must surface a recoverable state and must not create duplicate reminders or unexpected next-action changes.

## P02-FUB-SPEC-005 Missed-Day Recovery Planner
- Recovery planning is triggered by missed day, skip, defer, resume after pause gap, stale plan or plan item expiry.
- Recovery inputs include active goal revision, deadline, daily minutes, intensity, fatigue signal, current milestone, due memory items, unfinished plan items, support status and missed-day policy.
- Recovery output must choose exactly one primary mode: `compress`, `defer` or `replace`.
- `compress` reduces scope into a smaller feasible block without exceeding daily minutes.
- `defer` moves lower-priority work while preserving risk-driving items.
- `replace` swaps impossible work for a smaller review or training block.
- Recovery must not stack all overdue tasks into the next daily plan.
- Recovery must update plan stale/replan status and record reason code, source event, input snapshot hash and rule version.

## P02-FUB-SPEC-006 Item-Level MemoryCurvePolicy
- Memory scheduling must operate on `MemoryItemPolicyState`, not only on whole sessions or goal-level summaries.
- Memory items may represent expressions, scenarios, weaknesses or plan items; each item needs stable ID, item type, interleaving group, current mastery level, evidence references and last-reviewed timestamps.
- Due decision inputs include forgetting risk, retrieval success, recent failures, exposure count, overlearning count, interleaving group, pressure level and daily time budget.
- Due decision output must distinguish `review_due`, `review_not_due`, `skip_overlearning_cap`, `defer_budget`, `interleave_alternative` and `blocked_by_control`.
- Overlearning cap prevents repeated practice of the same item beyond the configured cap unless a high-risk evidence rule explicitly overrides it.
- Interleaving must prevent the selected plan from concentrating only on one expression, one scenario or one weakness group when viable alternatives exist.
- Same input snapshot and rule version must produce the same item-level due decision.

## P02-FUB-SPEC-007 L0-L5 Promotion And Demotion
- L0-L5 transition decisions must use accepted evidence only: diagnostic facts, training results, retrieval success, repeated failure, checkpoint evidence and confidence signals.
- L0-L5 meanings remain product-internal mastery states and must not imply official exam certification.
- Promotion requires enough evidence and confidence for the target transition; low confidence, partial support, unsupported content or fatigue protection blocks forced promotion.
- Demotion or hold decisions must be possible when repeated failure, retrieval regression or checkpoint evidence indicates risk.
- AI output containing final mastery, promotion/demotion, review schedule or goal completion as persistent state must be rejected or ignored for persistence.
- Transition records must include previous level, proposed level, accepted level, transition direction, evidence references, confidence, reason code, rule version and audit timestamp.
- User-facing explanation may summarize reason codes, but must not expose sensitive transcript details or unsupported official-score claims.

## P02-FUB-SPEC-008 Replay, Performance And Coverage Gates
- Followup-B implementation cannot start until AC-to-TC mapping exists in `test_cases.md`.
- Required replay fixture categories: control source, pause/resume, update-control, quiet-hours eligibility, notification outbox lifecycle, missed-day recovery, item-level memory due decision and L0-L5 transition.
- Replay verification must compare expected decision, reason code, output state and rule version.
- Required performance budgets to solidify in `test_cases.md`: control state load p95, pause/resume/update-control p95, notification eligibility p95, recovery replan p95, item-level memory due calculation p95, L0-L5 transition decision p95 and replay verification p95.
- Suggested initial budgets for acceptance planning: control state load p95 <=200 ms, pause/resume/update-control p95 <=500 ms, notification eligibility p95 <=200 ms, recovery replan p95 <=500 ms, item-level memory due calculation p95 <=300 ms for 500 items, L0-L5 transition decision p95 <=300 ms and replay verification p95 <=500 ms.
- Changed backend/domain/API/Flutter code must meet line and branch coverage >=80%; unchanged layers must be explicitly marked `N/A - no code change in this layer` in test evidence.
- Reports must not mark Followup-B complete until requirements, spec, acceptance, test_cases, traceability, contracts, code evidence, test evidence, performance/replay evidence and independent review are all closed.

## Acceptance Generation Handoff
- `acceptance.md` must create at least one AC for every Spec ID P02-FUB-SPEC-001 through P02-FUB-SPEC-008.
- Every AC must preserve Stage Scope ID, Policy Gate, WP ID, Requirement ID and Spec ID.
- Negative cases are mandatory for unsupported/partial goals, pause, quiet-hours block, permission denial, consent withdrawal, stale plan, overlearning cap, AI forbidden-field rejection and insufficient evidence for L0-L5 promotion.
- AC must not claim implementation, test execution or release approval.

## Required Downstream Contracts
- Domain：UserAutopilotControl、notification outbox、recovery planner、memory item policy、mastery transition and replay audit.
- API/OpenAPI：control read/update, pause/resume, notification eligibility, scheduler/outbox state where needed, recovery/replan and decision audit exposure.
- UX：paused state, quiet-hours state, notification-disabled state, missed-day recovery state, intensity override and memory/mastery explanations.
- AI runtime：candidate-only explanation schema and forbidden persistent fields.

## Non-goals
- Do not implement editable GoalProfile form or diagnostic sample capture; these remain Followup-A/upstream inputs.
- Do not implement Queue/Wiki surface propagation, checkpoint cadence/task library or forecast model hardening; these are routed to Followup-C.
- Do not implement release-wide feature flag, kill switch, commercial/cost telemetry, paid AI evidence, Product Base merge or release approval; these are routed to Followup-D.
- Do not write code, tests, OpenAPI, domain, UX, AI runtime, reports or traceability FR/Spec/AC/TC rows in this spec step.
