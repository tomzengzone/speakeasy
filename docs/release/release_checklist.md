# Release Checklist

## Before Release
- [x] MVP scope updated.
- [x] Feature specs updated.
- [x] Acceptance criteria mapped to tests.
- [x] API contract updated.
- [x] Domain schema updated.
- [x] AI output schemas validated.
- [x] All required tests pass.
- [x] Implementation report updated.
- [x] Quality report updated.
- [x] Version log updated.
- [x] Rollback plan reviewed.

## Production Controls
- [x] Provider secrets are not bundled in client.
- [x] Runtime configuration uses release-safe values.
- [x] Error logging avoids sensitive payloads.
- [x] Payment and auth settings are production-ready if enabled.

## 2026-05-29 MVP Backend Stage Release Evidence

Status: ready with documented exceptions for `mvp-backend-foundation`.

Validation:
- `npm run check:api-contract` - passed in `generated_client_drift` mode.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `flutter test` - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Documented exceptions:
- Full commercial payment verification, provider webhooks, entitlement gating, paid reports, offline packages, achievements, legacy stats/freeform scene migration, and external object-store retention are not silently approved by this checklist; they remain in their owning increments or DevOps/Security policies.
