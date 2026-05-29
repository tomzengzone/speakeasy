# Rollback Plan

## Documentation-only Change
- Revert the commit.
- Confirm no app build artifacts were changed.

## App Change
- Revert feature commit or disable feature flag.
- Run regression tests.
- Publish hotfix if release artifact was shipped.

## Backend Change
- Stop rollout.
- Revert deployment.
- Run database rollback only if migration plan allows it.
- Preserve audit logs.

## MVP Backend Stage Change
- Revert the complete six-increment change set as one release unit if generated-client or API compatibility breaks.
- Restore the previous `docs/architecture/openapi/speakeasy-api.yaml`, `docs/architecture/openapi/dart-client-drift-manifest.json`, and `lib/generated/api/` state together.
- Re-run `npm run check:api-contract`, backend Maven tests, and `flutter test` before any hotfix tag.
- Do not hard-delete audit logs or completed account deletion evidence during rollback; preserve them for investigation and compliance review.

## AI Runtime Change
- Revert prompt/schema version.
- Disable new schema path if validation fails.
- Keep fallback response available.

## P0 Commercial Subscription Change
- Stop rollout immediately if paid entitlement, restore, provider webhook, or account deletion behavior violates TC-COM evidence.
- Disable store promotion and pause staged rollout in App Store Connect / Play Console before shipping a hotfix.
- Revert Flutter subscription client changes and backend provider-boundary changes together if API compatibility breaks.
- Preserve `purchases`, `subscriptions`, `payment_provider_events`, `entitlement_snapshots`, `account_deletion_jobs`, and `audit_logs` for investigation; do not hard-delete compliance/audit records during rollback.
- Downgrade affected users only through audited entitlement snapshots or provider event replay, not ad hoc database edits.
- Re-run `scripts/check_release_readiness.sh`, backend commercial tests, Flutter commercial tests, and provider sandbox/internal smoke before resuming rollout.
