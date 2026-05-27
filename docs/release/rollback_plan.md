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

## AI Runtime Change
- Revert prompt/schema version.
- Disable new schema path if validation fails.
- Keep fallback response available.

