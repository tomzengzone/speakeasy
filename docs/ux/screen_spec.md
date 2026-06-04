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
- API dependencies: `GET /goal-autopilot/summary`, `POST /goal-autopilot/plans/generate`, `GET /goal-autopilot/daily-plan`, `GET /goal-autopilot/actions/next`, `POST /goal-autopilot/actions/{plan_item_id}/complete`.
- Empty state: no active plan; if supported goal exists, offer generate plan; otherwise route to goal setup.
- Loading state: show current cached summary as stale if available and avoid local plan computation.
- Error state: stale plan, quota, policy or provider failure shows retry/replan/defer; Flutter must not synthesize next action or final mastery locally.
- Acceptance criteria mapping: P0.2 plan/autopilot ACs for P02-PLAN-FR-001 through P02-PLAN-FR-008 and P02-AUTO-FR-001 through P02-AUTO-FR-003.

### Progress Forecast And Checkpoint
- Purpose: show target gap, ETA confidence, risk and next checkpoint, and collect weekly/biweekly checkpoint results.
- Entry points: daily autopilot completion, progress surface, due checkpoint action, profile goal progress entry.
- Primary user action: review forecast or submit checkpoint result when due.
- Core components: gap summary, ETA/date or uncertainty state, risk reason, next checkpoint date, latest checkpoint summary, checkpoint submit action, plan update signal.
- States: `loading`, `current`, `low_confidence`, `partial_supported`, `checkpoint_due`, `submitting_checkpoint`, `checkpoint_recorded`, `plan_update_required`, `recoverable_error`.
- API dependencies: `GET /goal-autopilot/forecast`, `POST /goal-autopilot/checkpoints`, `GET /goal-autopilot/summary`.
- Empty state: no forecast until active goal, diagnostic and plan exist; show required upstream step.
- Loading state: recompute or submit keeps previous forecast visible as stale.
- Error state: low confidence and partial support block high-precision ETA; checkpoint failure can be retried without claiming goal completion.
- Acceptance criteria mapping: P0.2 forecast/checkpoint ACs for P02-AUTO-FR-004 through P02-AUTO-FR-008.

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
