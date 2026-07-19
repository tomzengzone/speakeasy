# Release Checklist

## Before Release
- [x] MVP scope updated.
- [x] Feature specs updated.
- [x] Acceptance criteria mapped to tests.
- [x] API contract updated.
- [x] Domain schema updated.
- [x] AI output schemas validated.
- [x] Required local/automated tests for the dated evidence packets below pass.
- [x] Implementation report updated.
- [x] Quality report updated.
- [x] Version log updated.
- [x] Rollback plan reviewed.

Scope note: the top checklist is a baseline documentation/process checklist. It does not override the dated P0 Commercial Subscription, P0 Commercial AI Provider Hardening, or P0.1 Training Product Base/Production Hardening sections below; unchecked, planned, or blocked items in those sections remain blockers for their stated release/Product Base promotion scope.

## Production Controls
- [x] Provider secrets are not bundled in client.
- [x] Runtime configuration uses release-safe values.
- [x] Error logging avoids sensitive payloads.
- [x] Payment and auth release checks exist for enabled paths; production-ready status is governed by the P0 Commercial Subscription Release Gate below.

## 2026-05-29 MVP Backend Stage Release Evidence

Status: ready with documented exceptions for `mvp-backend-foundation`.

Validation:
- `npm run check:api-contract` - passed in `generated_client_drift` mode.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `flutter test` - passed.
- `git diff --check` - passed.
- `python3 scripts/validate_governance_contracts.py` - passed.

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
- [x] Paid AI external evidence checklist and strict aggregate gate exist: `tests/commercial/ai_external_release_evidence_checklist.md`, `scripts/check_ai_external_release_evidence.py`.
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
- `python3 scripts/check_ai_external_release_evidence.py --strict-external` still fails without `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`, `AI_MEDIA_STORAGE_EVIDENCE_REF`, `AI_COST_DASHBOARD_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF`.

## 2026-06-03 P0.1 Training Product Base/Production Hardening Gate

Status: local executed / passed for Product Base production-hardening evidence. Existing TC-P01-013/014 local route and AI eval evidence remain valid only after the 2026-06-03 backend-only correction; TC-P01-021 through TC-P01-031 now cover backend/Flutter production-hardening and frontend source-of-truth enforcement inside this stage.

Required before P0.1 Training is promoted to Product Base stable capability or production training mode:
- [x] AC-P01-014 / TC-P01-021 / TC-P01-022: backend Training API, server source of truth, owner authorization and turn idempotency pass locally.
- [x] AC-P01-015 / TC-P01-023 / TC-P01-024: learning evidence rule trace, accepted/rejected evidence governance, account deletion and retention coverage pass locally.
- [x] AC-P01-016 / TC-P01-025: reviewed versioned training content, action chain and target-expression mapping pass locally.
- [x] AC-P01-017 / TC-P01-026: real media/AI Training pipeline passes locally against trusted `audio_ref`, usage reservation/commit/release and typed fallback. Paid AI voice still depends on the P0 Commercial AI Provider Hardening Gate above.
- [x] AC-P01-018 / TC-P01-027: planner audit, config versioning and deterministic replay pass locally.
- [x] AC-P01-019 / TC-P01-028: redacted training metrics, rollout health, feature flag and kill switch readiness pass locally.
- [x] AC-P01-014 / AC-P01-019 / TC-P01-029 / TC-P01-031: Flutter product training entry and loop are backend-only; backend disabled/unavailable blocks entry or renders service unavailable and does not create a local state-machine session.
- [x] AC-P01-017 / TC-P01-030: missing trusted media does not create fake ASR/feedback/evidence; typed fallback submits through backend Training API only.
- [x] Frontend source-of-truth guard exists and passes: `scripts/check_p0_1_training_frontend_source_of_truth.py`.
- [x] Training frontend bounded-context namespace is in force: production code under `lib/features/training/`, tests under `test/features/training/`, and no executable `InterviewTraining*` / `interview_training_*` names remain.
- [x] `docs/product/increments/p0-1-expression-automation-training/traceability.md`, `docs/reports/test_report.md` and `docs/reports/quality_report.md` are updated with executed evidence, not only planned rows.

Current blocker register:
- `P01-GAP-006`, `P01-GAP-007` and `P01-GAP-009` through `P01-GAP-014` are closed locally for P0.1 Product Base/production hardening by TC-P01-001 through TC-P01-013 and TC-P01-021 through TC-P01-031.
- Commercial release and paid AI voice release still remain blocked by the dated P0 Commercial Subscription and P0 Commercial AI Provider Hardening gates above until their external evidence refs pass.

Reference:
- `docs/release/commercial_release_runbook.md`

## 2026-06-07 P0.2 Followup-D Release Gate Hardening

Status: local S001-S011 final review passed / blocked until Product Base merge approval and external release evidence.

Local Followup-D gates:
- [x] S001 backend/API runtime gate evidence passed locally.
- [x] S002 Flutter rollback evidence passed locally.
- [x] S003 entitlement depth evidence passed locally.
- [x] S004 usage reservation/quota evidence passed locally.
- [x] S005 cost telemetry/AI fallback evidence passed locally.
- [x] S006 quota downgrade evidence passed locally.
- [x] S007 data governance backend evidence passed locally.
- [x] S008 consent/privacy UX evidence passed locally.
- [x] S009 telemetry health/error/funnel metrics evidence passed locally.
- [x] TC-P02-FUD-018 dedicated Followup-D traceability checker passed locally.
- [x] TC-P02-FUD-019 OpenAPI/generated drift and release-doc gate passed locally with release readiness fixture wiring.
- [x] TC-P02-FUD-020 S011 final report/release checklist sync passed locally.
- [x] TC-P02-FUD-021 S011 final Product Base/release review executed and independently reviewed.

Required before P0.2 Followup-D can be marked release-ready or merged into Product Base:
- [ ] Product Base merge decision is explicitly approved by PM/release governance.
- [ ] Commercial release external evidence remains blocked until the P0 Commercial Subscription Release Gate is satisfied.
- [ ] Paid AI external evidence remains blocked until the P0 Commercial AI Provider Hardening Gate is satisfied.
- [ ] Strict `scripts/check_release_readiness.sh` remains blocked until it passes in the target release environment with real provider/store/native/symbol/rollback evidence refs.

Latest local evidence:
- `P02-FOLLOWUP-D-S010-DRIFT-GATES-20260607` records TC-P02-FUD-018/019 passed for traceability/report/release-doc drift and API/generated drift gates.
- `P02-FOLLOWUP-D-S011-FINAL-REVIEW-20260607` records TC-P02-FUD-020/021 passed for final report sync, release checklist state separation, Product Base blocker preservation and independent review.
- Followup-D is not release-ready.
- Product Base merge is not approved.
