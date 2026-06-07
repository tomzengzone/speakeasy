# Screen Spec

## Required Screen Spec Fields
Every new screen must define:
- purpose
- entry points
- primary user action
- core components
- states
- API dependencies
- empty state
- loading state
- error state
- analytics or logging events if needed
- acceptance criteria mapping

## MVP Screens

### Scenario List
- Purpose: choose a scenario.
- States: loading, loaded, empty, error.
- Primary action: open scenario detail or practice.

### Practice
- Purpose: complete a guided scenario.
- States: idle, submitting, analyzing, feedback_shown, retry_needed, completed, error.
- Primary action: submit learner turn.

## P0.1 Expression Automation Training Screen

Owning increment: `p0-1-expression-automation-training`。

### Training Session
- Purpose: guide the learner through one session内 micro-action at a time so target expressions can be practiced, retried, lightly pressured, and recapped without open-ended task overload.
- Entry points: `job_interview` or `onboarding_introduction` official scenario detail, current scenario practice entry, unfinished P0.1 session resume entry.
- Primary user action: complete the current micro-action by listening, choosing, speaking, shadowing, filling, or continuing under prompt.
- Core components: session header, current action chain step label, one active micro-action panel, target expression or prompt, hint ladder surface, voice recorder controls, text fallback field, feedback card, retry/continue action, pressure check prompt, recap summary, recoverable error banner.
- States: `loading`, `ready`, `listening`, `recording`, `transcribing`, `evaluating`, `feedback`, `retry`, `pressure_check`, `recap`, `recoverable_error`, `unsupported_scene`.
- API dependencies: Product Base/production Training uses the backend Training API as the source of truth: `POST /training/sessions`, `GET /training/sessions/{session_id}`, `POST /training/sessions/{session_id}/turns`, planner/hint/pressure-check endpoints and `POST /training/sessions/{session_id}/complete`. If backend Training is disabled or unavailable, the screen must show service-unavailable or close the entry; it must not create a local draft session, local planner decision, synthetic feedback or `pending_local_write` evidence. AI dependencies are backend-owned feedback candidates from `docs/ai_runtime/llm_output_schema.md`; ASR/TTS/scoring use the backend AI gateway or backend deterministic test provider.
- Empty state: if no valid action chain or target expression is available for the selected official scene, show a recoverable unavailable state and route back to scenario detail; do not create a fake third scene or arbitrary prompt.
- Loading state: show that scene, level, action step, history and audio resources are loading; keep the previous resumable state if available.
- Error state: preserve learner input or audio reference when possible; ASR failure offers retry recording or text fallback; LLM/schema failure offers deterministic retry/fallback; evidence write failure preserves recap and marks write-back retryable.
- Acceptance criteria mapping: AC-P01-001, AC-P01-002, AC-P01-003, AC-P01-004, AC-P01-005, AC-P01-006, AC-P01-007, AC-P01-008, AC-P01-009, AC-P01-010, AC-P01-011, AC-P01-012, AC-P01-014, AC-P01-015, AC-P01-016, AC-P01-017, AC-P01-018, AC-P01-019.

### Training Session State Contract
| State | User sees | Primary action | Next states |
| --- | --- | --- | --- |
| `loading` | Loading indicator for scene/session | wait or leave | `ready`, `recoverable_error`, `unsupported_scene` |
| `ready` | One micro-action instruction and current hint if any | start/listen/answer | `listening`, `recording`, `feedback` |
| `listening` | Playback for model prompt or target expression | replay, continue, report failure | `ready`, `recording`, `recoverable_error` |
| `recording` | Recorder, cancel, submit, elapsed time | submit or cancel | `transcribing`, `ready` |
| `transcribing` | Processing voice input | wait | `evaluating`, `retry`, `recoverable_error` |
| `evaluating` | Feedback is being prepared | wait | `feedback`, `recoverable_error` |
| `feedback` | Concise feedback card and next action | retry, continue, pressure check, recap | `retry`, `ready`, `pressure_check`, `recap` |
| `retry` | Same action with raised or adjusted hint | answer again | `ready`, `listening`, `recording` |
| `pressure_check` | Short follow-up or near-scene prompt with reduced hint | answer under prompt | `recording`, `feedback`, `recap` |
| `recap` | Summary, one next focus, evidence write status | finish | terminal |
| `recoverable_error` | What failed and what can be done next | retry, text fallback, exit, view recap | previous valid state, `retry`, `recap` |
| `unsupported_scene` | P0.1 training unavailable for this scene | return to scenario detail | terminal |

### Micro-action Component Contract
| Micro-action | Required UI | Fallback |
| --- | --- | --- |
| `ListenOne` | play/replay target expression or prompt; continue control | show text if audio/TTS fails |
| `ChooseOne` | options list with one submit action | explain mismatch and retry |
| `SayOne` | recorder, cancel, submit, re-record, optional text fallback after failure | text fallback only after mic/ASR issue or debug mode |
| `ShadowOne` | model audio/chunk, recorder, replay | model-then-retry if score unavailable or low confidence |
| `FillOne` | sentence frame or missing chunk input | options or sentence frame hint |
| `ContinueUnderPrompt` | short pressure prompt and recorder | downgrade to `SayOne` or higher hint |

### Feedback And Recap Contract
- Feedback card shows at most one main issue, one better expression, and one immediate next action.
- Pronunciation appears only when score signal is available; unavailable score must not block the session.
- Hint level changes must be visible through the current prompt, sentence frame, options, chunk shadowing or model-then-retry UI.
- Recap must remain visible even when learning evidence write-back is retryable or delayed.
- The screen must not display cross-day scheduling, full L0-L5 mastery, third-scene creation, arbitrary scene generation, commercial entitlement status, or billing state as P0.1 completion proof.

## P0.2 Goal Autopilot Screens

Owning stage: `docs/product/stages/p0-2-training-memory.md`。
Owning increments: `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint`。

### Goal Setup And Diagnostic
- Purpose: capture the learner's target, deadline, daily time and intensity, then show supported/partial/unsupported status and diagnostic confidence.
- Entry points: onboarding completion, home goal setup entry, profile goal edit entry, unsupported/partial plan recovery entry.
- Primary user action: submit or revise the goal and provide diagnostic samples when required.
- Core components: goal type picker, target score/ability input, deadline input, daily minutes input, intensity selector, support status panel, diagnostic confidence panel, weakness tags, claim guard note, continue-to-plan action.
- States: `draft`, `checking_support`, `supported`, `partial_supported`, `unsupported`, `collecting_diagnostic`, `evaluating_diagnostic`, `diagnostic_complete`, `low_confidence`, `recoverable_error`.
- API dependencies: `POST /goal-autopilot/goals`, `GET /goal-autopilot/summary`. Diagnostic AI output follows `docs/ai_runtime/llm_output_schema.md#P0.2-Goal-Autopilot-Candidate-Schemas` and is candidate-only.
- Empty state: no active goal; show compact goal setup form, not a marketing page.
- Loading state: support check and diagnostic evaluation disable duplicate submit while keeping entered goal facts visible.
- Error state: provider/schema failure shows retry or conservative low-confidence path; unsupported goals show limitation and do not create a full plan.
- Acceptance criteria mapping: P0.2 diagnostic ACs for P02-DIAG-FR-001 through P02-DIAG-FR-007.

### Daily Autopilot
- Purpose: show one primary action so the learner does not manually decide what to practice next.
- Entry points: app home, active goal summary, due review, missed-day recovery, checkpoint due banner.
- Primary user action: start the selected training/review/checkpoint item; secondary controls are pause, defer, lower intensity and resume.
- Core components: goal progress header, next action block, reason code, expected duration, daily plan compact list, pause/defer controls, partial/unsupported limitation state, quiet-hours state.
- States: `loading`, `ready`, `paused`, `quiet_hours`, `stale_plan`, `unsupported_or_partial`, `executing`, `completed`, `deferred`, `recovery_required`, `recoverable_error`.
- API dependencies: `GET /goal-autopilot/progress-projection`, `GET /goal-autopilot/summary`, `POST /goal-autopilot/plans/generate`, `GET /goal-autopilot/daily-plan`, `GET /goal-autopilot/actions/next`, `POST /goal-autopilot/actions/{plan_item_id}/complete`.
- Followup-C S004/S005 boundary: goal progress header, next action affordance, gap/risk/checkpoint summary, surface eligibility and downgrade reason must render from `GoalProgressProjection`; Flutter must not compute final goal state, ETA precision, goal completion or claim guards locally.
- Followup-C S006 boundary: deleted, unavailable, unsupported, stale or control-blocked projection fragments render only backend state/reason and must clear cached gap, action, checkpoint conclusion, precise ETA and completion copy. Partial and low-confidence eligible fragments may show backend downgrade reason plus allowed safe fields, but still cannot show precise ETA or goal-complete copy.
- Empty state: no active plan; if supported goal exists, offer generate plan; otherwise route to goal setup.
- Loading state: show current cached summary as stale only while authenticated and not after deleted/unavailable projection state; avoid local plan computation.
- Error state: stale plan, quota, policy or provider failure shows retry/replan/defer; Flutter must not synthesize next action or final mastery locally.
- Acceptance criteria mapping: P0.2 plan/autopilot ACs for P02-PLAN-FR-001 through P02-PLAN-FR-008 and P02-AUTO-FR-001 through P02-AUTO-FR-003.

### Progress Forecast And Checkpoint
- Purpose: show target gap, ETA confidence, risk and next checkpoint, and collect weekly/biweekly checkpoint results.
- Entry points: daily autopilot completion, progress surface, due checkpoint action, profile goal progress entry.
- Primary user action: review forecast or submit checkpoint result when due.
- Core components: gap summary, ETA/date or uncertainty state, risk reason, next checkpoint date, latest checkpoint summary, checkpoint submit action, plan update signal.
- States: `loading`, `current`, `low_confidence`, `partial_supported`, `checkpoint_due`, `submitting_checkpoint`, `checkpoint_recorded`, `plan_update_required`, `recoverable_error`.
- API dependencies: `GET /goal-autopilot/progress-projection`, `GET /goal-autopilot/forecast`, `GET /goal-autopilot/checkpoints/task`, `POST /goal-autopilot/checkpoints`, `GET /goal-autopilot/summary`.
- Followup-C S002 boundary: checkpoint due/not-due/limited/unavailable state, task type, evidence requirements, scoring boundary and limitation reason are rendered from the backend task decision; the UI must not infer cadence or full-task eligibility locally.
- Followup-C S003 boundary: after checkpoint submit, UI must render `OutcomeCheckpoint.result_status`, `plan_update_signal.signal_type`, `plan_update_signal.reason_code` and optional replay metadata from the backend response; it must not infer goal completion, ETA precision, stale/replan status or next-action advancement locally. Paused/control-blocked/recovery-required/stale responses show the backend reason and route to replan/recovery instead of auto-starting the next action.
- Followup-C S005 boundary: Home panel, expression queue and personal Wiki progress fragments read `surface_fragments` and safe projection fields from `GET /goal-autopilot/progress-projection`; queue ordering remains owned by the queue contract/coordinator and raw diagnostic transcript/audio, sensitive target details, raw checkpoint payloads, provider payloads, ETA and goal-completion claims are not display dependencies.
- Followup-C S006 boundary: when projection state is deleted/unavailable/unsupported/stale/control-blocked, the UI must replace any previously rendered progress fragment with the backend downgrade reason and omit stale gap, ETA, checkpoint conclusion and next action refs. Partial/low-confidence fragments must display the backend reason rather than locally inferring a final state.
- Empty state: no forecast until active goal, diagnostic and plan exist; show required upstream step.
- Loading state: recompute or submit keeps previous forecast visible as stale.
- Error state: low confidence and partial support block high-precision ETA; checkpoint failure can be retried without claiming goal completion.
- Acceptance criteria mapping: P0.2 forecast/checkpoint ACs for P02-AUTO-FR-004 through P02-AUTO-FR-008.

### Followup-B Autopilot Control And Recovery

Owning increment: `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

- Purpose: let the learner understand and safely control automatic guidance without Flutter inventing control, reminder, recovery, memory or mastery state locally.
- Entry points: Daily Autopilot next-action card, goal summary control chip, paused banner, quiet-hours blocked reminder entry, notification-disabled banner, missed-day recovery banner, memory/mastery explanation entry.
- Primary user action: pause, resume, adjust intensity, set quiet hours, enable/disable reminder consent, choose server-returned recovery action or view memory/mastery explanation.
- Core components: server control status badge, pause/resume button, intensity segmented control, quiet-hours selector, reminder permission/consent status, next-action impact message, reminder eligibility message, recovery decision card, item-policy reason chip, mastery explanation card, replay-safe audit note.
- States: `control_loading`, `control_active`, `paused`, `resume_checking`, `blocked_by_policy`, `quiet_hours_blocked`, `notification_disabled`, `intensity_updated`, `recovery_required`, `recovery_planned`, `item_policy_due`, `item_policy_blocked`, `mastery_explanation_ready`, `recoverable_error`.
- API dependencies: `GET /goal-autopilot/control`, `PATCH /goal-autopilot/control`, `POST /goal-autopilot/control/pause`, `POST /goal-autopilot/control/resume`, `POST /goal-autopilot/reminders/eligibility`, `GET /goal-autopilot/reminders/outbox`, `POST /goal-autopilot/recovery/replan`, `POST /goal-autopilot/item-policy/decisions`, `GET /goal-autopilot/mastery-transitions`, `GET /goal-autopilot/replay-audits`, plus existing summary/daily-plan/next-action APIs.
- AI dependencies: Followup-B mastery explanation candidate in `docs/ai_runtime/llm_output_schema.md`; UI renders only schema-valid candidate explanation or deterministic fallback. UI must never parse free-form AI text to set state.
- Empty state: if no active goal or no server control exists, route to Goal Setup or show “set up goal first”; do not create a local control object.
- Loading state: keep the previous server state visible as stale while refreshing; disable duplicate pause/resume/update actions until the server response returns.
- Error state: failed pause/resume/update keeps the last known server state; failed reminder eligibility shows reason unknown/retry without treating unsent reminders as missed-day evidence; failed explanation falls back to deterministic reason text.
- Acceptance criteria mapping: AC-P02-FUB-001, AC-P02-FUB-002, AC-P02-FUB-003, AC-P02-FUB-004, AC-P02-FUB-005, AC-P02-FUB-006, AC-P02-FUB-007, AC-P02-FUB-008.

### Followup-B Control State Contract
| State | User sees | Primary action | Data source | Next states |
| --- | --- | --- | --- | --- |
| `control_loading` | Existing state marked refreshing | wait or leave | cached `GET /goal-autopilot/control` response | `control_active`, `paused`, `blocked_by_policy`, `recoverable_error` |
| `control_active` | Next action, active reminder state and compact controls | pause, adjust intensity, edit quiet hours, start action | `UserAutopilotControl.control_status=active` | `paused`, `intensity_updated`, `quiet_hours_blocked`, `notification_disabled`, `recovery_required`, `item_policy_due` |
| `paused` | Paused banner; no new automatic prompts or future reminders | resume or edit settings | `UserAutopilotControl.control_status=paused` | `resume_checking`, `intensity_updated` |
| `resume_checking` | Resume is checking plan freshness, missed days, quiet hours, fatigue, support and entitlement | wait | `POST /goal-autopilot/control/resume` | `control_active`, `recovery_required`, `blocked_by_policy`, `quiet_hours_blocked` |
| `blocked_by_policy` | Clear reason for unsupported, partial without safe plan, stale/missing plan, entitlement or data policy block | view required upstream step or refresh | server reason code | `control_active`, `recovery_required`, terminal blocked state |
| `quiet_hours_blocked` | Reminder not sent now; next allowed time when available | edit quiet hours or wait | `NotificationEligibilityDecision.reason_code=quiet_hours` | `control_active`, `notification_disabled` |
| `notification_disabled` | Reminder disabled by consent or platform permission | open permission guidance or update consent | `NotificationEligibilityDecision.reason_code=permission_denied` or `consent_missing` | `control_active`, `quiet_hours_blocked` |
| `intensity_updated` | Server confirms intensity/quiet hours/consent/policy update and impact | continue or replan if required | `PATCH /goal-autopilot/control` response | `control_active`, `recovery_required`, `blocked_by_policy` |
| `recovery_required` | Missed/skip/defer/pause gap/stale plan needs recovery | request recovery plan | summary/control/recovery reason | `recovery_planned`, `recoverable_error` |
| `recovery_planned` | One recovery mode: compress, defer or replace; no overdue stacking | start returned action | `RecoveryPlanDecision` | `control_active`, `item_policy_due` |
| `item_policy_due` | Why this item is due and how it fits interleaving/overlearning | start review/training | `MemoryItemPolicyState.due_decision` | `mastery_explanation_ready`, `control_active` |
| `item_policy_blocked` | Item skipped/deferred due to overlearning, budget, interleaving or control block | view alternative or continue | `MemoryItemPolicyState.due_decision` | `control_active`, `recovery_required` |
| `mastery_explanation_ready` | Safe L0-L5 internal explanation and evidence summary | continue or view audit note | `MasteryTransitionDecision` plus schema-valid AI candidate/fallback | `control_active` |
| `recoverable_error` | What failed and the last known safe state | retry, refresh, leave | typed API/fallback error | previous valid state |

### Followup-B Interaction Rules
- Pause is idempotent in UI: repeated tap while already paused shows current paused state and does not duplicate cancellation UI.
- Resume never immediately shows reminders or prompts until the server returns active eligibility; while checking, all execution buttons stay disabled.
- Quiet hours that cross midnight must display as a single interval in the configured timezone.
- Notification blocked, failed, expired or unsent states must not be worded as “you missed practice” or “you failed”.
- Intensity override must show impact returned by the API: next action changed, reminder eligibility changed, replan required and reason code.
- Recovery card must show exactly one primary mode: `compress`, `defer` or `replace`; it must not list all overdue tasks as today's work.
- Memory/mastery explanation must say it is an internal practice signal, not official exam certification.
- Any AI explanation marked invalid, forbidden-field rejected or unavailable must be replaced by deterministic fallback copy from reason code; UI must not render raw provider text.
- Replay/audit information is developer/support-facing wording only: show safe “decision can be replayed” status or reason code, not input snapshot contents.

### Followup-B Test Checklist Contract
| Acceptance | Screen state / behavior | Planned test mapping |
| --- | --- | --- |
| AC-P02-FUB-001 | Server-owned active/paused/policy-blocked state; no local control derivation | TC-P02-FUB-001, TC-P02-FUB-002 |
| AC-P02-FUB-002 | Pause/resume/update-control impact messages and disabled duplicate actions | TC-P02-FUB-003, TC-P02-FUB-004 |
| AC-P02-FUB-003 | Quiet-hours, permission, consent, entitlement, quota, stale/missing plan reason display | TC-P02-FUB-005, TC-P02-FUB-006 |
| AC-P02-FUB-004 | Outbox lifecycle displayed as pending/scheduled/blocked/sent/cancelled/failed/expired without evidence mutation wording | TC-P02-FUB-007, TC-P02-FUB-008 |
| AC-P02-FUB-005 | Missed-day recovery shows compress/defer/replace and no overdue stacking | TC-P02-FUB-009, TC-P02-FUB-010 |
| AC-P02-FUB-006 | Item-level due decision explains overlearning cap, interleaving, budget defer or control block | TC-P02-FUB-011, TC-P02-FUB-012 |
| AC-P02-FUB-007 | L0-L5 explanation uses accepted evidence, supports hold/demotion and rejects AI persistent fields | TC-P02-FUB-013, TC-P02-FUB-014 |
| AC-P02-FUB-008 | Replay/performance/coverage gates remain planned evidence; UI does not mark Followup-B complete | TC-P02-FUB-015, TC-P02-FUB-016, TC-P02-FUB-017 |

### Followup-D Consent And Privacy UX

Owning increment: `docs/product/increments/p0-2-followup-d-release-gate-hardening/`。

- Purpose: show P0.2 data-use, notification consent, export/delete/retention and downgrade privacy boundaries without implying release approval or commercial outcome guarantees.
- Entry points: Goal Autopilot panel when summary/control/projection data loads, including runtime unavailable and downgraded states.
- Primary user action: review current privacy state and enable or withdraw reminder consent through the existing server-owned control update.
- Core components: privacy/control heading, product-internal data-use copy, backend data-governance export/delete/retention copy, sensitive-payload omission copy, notification consent state, reminder prompt eligibility/block reason, projection data state.
- States: `privacy_visible`, `consent_on`, `consent_withdrawn`, `reminder_blocked`, `backend_state_pending`, `projection_ready`, `projection_downgraded`, `runtime_unavailable`.
- API dependencies: existing `GET /goal-autopilot/control`, `PATCH /goal-autopilot/control`, `GET /goal-autopilot/progress-projection`, `GET /goal-autopilot/summary`. S008 does not add OpenAPI fields; Flutter renders existing `notification_consent`, `reminder_eligibility`, `projection_state` and `downgrade_reason`.
- Empty state: if projection is unavailable during load, show `backend_state_pending` rather than local export/delete state.
- Loading state: keep previously loaded server state only as part of the same view refresh; do not invent consent, reminder, export, deletion or retention facts.
- Error state: runtime unavailable uses the backend/runtime reason and blocked control result; no local fallback goal, reminder, export or release state is created.
- Copy boundary: copy must mention product-internal training surfaces, backend data-governance export/delete/retention rules and sensitive payload omission. It must not claim guaranteed achievement, official-score equivalence, unlimited AI, unlimited checkpoint access, release approval or Product Base merge approval.
- Acceptance criteria mapping: AC-P02-FUD-008 / TC-P02-FUD-015.

### Notebook
- Purpose: review saved expressions.
- States: empty, loaded, deleting, error.
- Primary action: open saved expression.

### Review
- Purpose: complete due review tasks.
- States: due, answering, completed, empty.
- Primary action: submit review answer.

## P0 Commercial Subscription Screens

Owning increment: `commercial-subscription-readiness`.

### Membership / Plans
- Purpose: show current server-owned entitlement state and saleable subscription plans.
- Entry points: profile membership entry, paywall upgrade action, restore purchase action, expired/downgraded entitlement banner.
- Primary user action: choose a plan, start platform purchase, restore purchase, or manage subscription.
- Core components: entitlement status banner, plan list, benefit list, restore action, platform legal note, loading/error state.
- States: loading_entitlement, free, active_paid, grace_period, expired, refunded_or_revoked, purchase_processing, restore_processing, empty_restore, provider_unavailable, config_blocked.
- API dependencies: `GET /subscription/plans`, `GET /entitlements`, `POST /entitlements/refresh`, `POST /subscriptions/apple/verify`, `POST /subscriptions/google/verify`, `POST /subscriptions/restore`.
- Empty state: no saleable plans or no restore result; show a clear explanation and a retry or support action.
- Loading state: disable duplicate purchase/restore actions and keep current entitlement visible as stale until refreshed.
- Error state: invalid receipt, product mismatch, network failure and backend verification failure must not grant entitlement; user sees retry or subscription management guidance.
- Acceptance criteria mapping: AC-COM-001, AC-COM-002, AC-COM-003, AC-COM-004, AC-COM-005, AC-COM-011.

### Paywall / Entitlement Gate
- Purpose: block unavailable paid capabilities while explaining the required entitlement.
- Entry points: AI deep feedback, high-cost ASR/TTS/scoring call, paid scenario package, learning report or other paid benefit.
- Primary user action: upgrade, retry after refresh, or continue with a free downgraded path when available.
- Core components: required benefit label, current plan state, remaining quota, upgrade action, fallback action.
- States: allowed, entitlement_required, quota_exhausted, expired, refunded_or_revoked, offline_stale_cache, refresh_failed.
- API dependencies: `GET /entitlements`, `POST /entitlements/refresh`, `GET /usage/summary`, `POST /usage/reserve`.
- Empty state: no paid benefit exists for the requested action; show the available free action instead of an empty upsell.
- Loading state: show entitlement refresh progress and avoid starting the protected provider call until the server confirms access.
- Error state: provider or usage failure returns a recoverable message and does not consume client-side-only quota.
- Acceptance criteria mapping: AC-COM-006, AC-COM-007, AC-COM-012.

### Account Deletion
- Purpose: let the user understand and confirm account deletion, then clear local state after backend deletion or anonymization completes.
- Entry points: profile/settings account deletion action.
- Primary user action: confirm deletion after reading consequences.
- Core components: consequence summary, confirmation input or final confirm button, deletion progress, failure/retry/support state.
- States: confirming, deleting, completed, failed_retryable, failed_support_needed, logged_out_after_completion.
- API dependencies: `DELETE /user/me`, `GET /user/deletion-status`.
- Empty state: no deletion job exists; show the default confirmation screen.
- Loading state: keep the screen in progress until the backend returns a deletion job state.
- Error state: local data is not cleared until the backend reports accepted/completed deletion; retryable failure shows next action.
- Acceptance criteria mapping: AC-COM-010.

### Release / Config Blocked State
- Purpose: prevent a store or release candidate from exposing broken commercial flows.
- Entry points: release health checks, internal testing, visible login/payment/social-login entries.
- Primary user action: none for end users; testers see configuration error in non-production channels.
- Core components: release health warning, missing config list, blocked action message.
- States: production_ready, missing_api_base_url, test_login_enabled, missing_payment_product, missing_social_config, missing_release_secret.
- API dependencies: `GET /admin/release-health` for ops; app UI consumes only release-safe configuration values.
- Empty state: no warnings.
- Loading state: not user-facing in production; internal builds may show checking.
- Error state: fail closed for production release, not fail open.
- Acceptance criteria mapping: AC-COM-008, AC-COM-009, AC-COM-014.
