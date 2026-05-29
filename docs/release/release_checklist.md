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

## 2026-05-29 P0 Commercial Subscription Release Gate

Status: blocked until external provider/store evidence and production native social-login configuration are supplied.

Automated gates:
- [x] TC-COM-011 gate script exists: `scripts/check_release_configuration.sh`.
- [x] TC-COM-012 gate script exists: `scripts/check_social_login_release_config.sh`.
- [x] TC-COM-016 copy contract gate script exists: `scripts/check_commercial_copy_contract.py`.
- [x] TC-COM-012/015/019/021/022 manual external evidence plan exists: `tests/commercial/manual_external_evidence_checklist.md`.
- [x] Manual external evidence plan gate script exists: `scripts/check_manual_external_evidence_plan.py`.
- [x] TC-COM-019 provider evidence gate script exists: `scripts/check_provider_sandbox_evidence.py`.
- [x] TC-COM-021 store submission evidence gate script exists: `scripts/check_store_submission_evidence.py`.
- [x] TC-COM-022 aggregate gate script exists: `scripts/check_release_readiness.sh`.
- [x] GitHub release workflow invokes `scripts/check_release_readiness.sh` before signing/build artifacts.

Required before commercial store submission:
- [ ] TC-COM-015 membership page, store metadata, privacy/support copy review evidence recorded in `STORE_METADATA_EVIDENCE_REF`.
- [ ] TC-COM-019 Apple sandbox evidence reference recorded in `APPLE_SANDBOX_EVIDENCE_REF`.
- [ ] TC-COM-019 Google Play internal-test evidence reference recorded in `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF`.
- [ ] TC-COM-021 store metadata, subscription terms, privacy declaration, support URL and reviewer account evidence recorded.
- [ ] TC-COM-012/015/019/021/022 manual checklist results are executed, evidence-linked, and independently reviewed.
- [ ] iOS WeChat URL scheme no longer uses `wx0000000000000000`.
- [ ] iOS Sign in with Apple entitlement is present in release signing configuration.
- [ ] Android signing secrets、Sentry DSN、symbol upload evidence 和 rollback rehearsal evidence are present in release secrets/vars.
- [ ] `ENABLE_TEST_PHONE_LOGIN` is disabled and `ENV=production`.

Reference:
- `docs/release/commercial_release_runbook.md`
