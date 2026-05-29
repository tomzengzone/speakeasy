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
