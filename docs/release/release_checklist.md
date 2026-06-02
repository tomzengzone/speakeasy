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

## 2026-06-01 P0 Commercial AI Provider Hardening Gate

Status: local implementation/evidence-prep passed / blocked until strict external evidence is supplied.

Required before paid AI voice or real DashScope provider release:
- [ ] `commercial-ai-provider-hardening` requirements/spec/acceptance/test_cases/traceability remain in sync.
- [x] TC-COM-AI-001 trusted media upload/reference tests passed locally.
- [x] TC-COM-AI-002 production ASR rejects local paths, unsigned URLs and forged metadata locally.
- [x] TC-COM-AI-003 persistent TTS cache tests passed locally for metadata, owner refs, expiry and deletion behavior.
- [ ] TC-COM-AI-004 DashScope LLM/ASR/TTS sandbox or controlled live evidence recorded in `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.
- [ ] TC-COM-AI-005 AI cost dashboard evidence recorded in `AI_COST_DASHBOARD_EVIDENCE_REF`.
- [x] TC-COM-AI-006 and TC-COM-AI-007 AI retention/deletion tests passed locally.
- [ ] Object storage lifecycle and signed media ref evidence recorded in `AI_MEDIA_STORAGE_EVIDENCE_REF`.
- [ ] AI retention policy and deletion proof recorded in `AI_RETENTION_POLICY_EVIDENCE_REF`.
- [ ] `P01-GAP-008` remains Partial until the above items are implemented, tested and independently reviewed.

Latest local evidence:
- `python3 scripts/run_dashscope_sandbox_matrix.py` passed on 2026-06-03 and wrote sanitized report `build/reports/dashscope-sandbox-20260602T223557Z-3359fcc82fafa457.json`.
- `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` still fails without `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.

Reference:
- `docs/release/commercial_release_runbook.md`
