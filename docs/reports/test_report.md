# Test Report

## Current Status
Latest recorded Followup-E state: docs-only planning/contract evidence. Followup-E Phase 0 planning, Phase 1 requirements/spec, Phase 2 domain/API/AI/UX/data contracts after correction, and Phase 3 acceptance/test_cases/traceability have planning-gate evidence. No Followup-E backend, Flutter, OpenAPI/generated client, native mic/audio bytes upload, AI runtime, retention/export/account deletion, entitlement/provider downgrade, release or Product Base test evidence is accepted in this docs-only state.

## 2026-06-10 P0 Commercial Admin Data Deletion Retry Closure

Report ID:
- `P0-COM-ADMIN-DATA-DELETION-RETRY-20260610`

Test scope:
- TC-COM-025 covers local backend/API closure for `POST /admin/data-deletion/{job_id}/retry`.
- Requirement chain: COM-SI-006/011 -> FR-COM-008/011 -> COM-SPEC-006/011 -> AC-COM-010/013 -> COM-TR-006/011 -> TC-COM-025.
- Architecture boundary: reuse `AccountDeletionService`, `AccountDeletionJob`, `AuditLog`, `AiRetentionService`, Spring Security `/admin/**` OPS bearer auth, Flyway and OpenAPI/generated-client drift gates; no parallel deletion processor, audit store or admin auth stack.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminDataDeletionControllerTest,AdminDataDeletionRetryFailureTest,AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,CommercialAccountDeletionProcessorTest,AiAccountDeletionMediaCleanupTest,AiRetentionPolicyTest,AdminAuditControllerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CommercialAbuseControlTest test` - passed after pinning the test to the existing deterministic AI provider pattern.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProviderGatewaySecurityContractTest test` - passed after pinning the test to the existing deterministic AI provider pattern.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `npm run check:api-contract` - passed; OpenAPI contract gate reported 87 paths, 93 operations, 42 request examples, 88 success examples and 123 error examples; Dart drift passed with hash `464464b9346a28422831e56e8f5ba42118ebb0a6005d981e4381bee52fce4e30`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --base-ref HEAD --include-worktree` - passed for 30 changed files.
- `git diff --check` - passed.

Passing tests:
- TC-COM-025 auth: `/admin/data-deletion/{job_id}/retry` returns 401 without bearer token and 403 for non-OPS bearer token.
- TC-COM-025 success: failed deletion jobs retry through OPS, transition to `completed`, revoke sessions, reuse account deletion cleanup and write `account_deletion_retry_requested` plus `account_deletion_retry_completed`.
- TC-COM-025 idempotency: duplicate `Idempotency-Key` replay returns the current job without increasing `retry_count`, without new retry audit rows and without creating another AI retention job.
- TC-COM-025 terminal state: completed deletion jobs return the current completed job without creating retry idempotency or retry audit rows.
- TC-COM-025 in-progress state: `requested` jobs fail closed with 409 `DELETE_IN_PROGRESS`.
- TC-COM-025 validation: missing `Idempotency-Key` returns 422 `SCHEMA_VALIDATION_FAILED`; malformed job id returns 404 `RESOURCE_NOT_FOUND`.
- TC-COM-025 failure persistence: a real `AiRetentionService` execution with a failing media storage adapter leaves the deletion job in `failed`, persists retry idempotency as `failed`, writes `account_deletion_retry_failed`, increments retry count once and stores sanitized `failure_reason`.
- Regression: existing account deletion request, session invalidation, learning data cleanup, failure status query, commercial idempotency, AI account deletion media cleanup, AI retention policy and admin audit tests continue to pass.
- Regression: full backend test suite passes after `CommercialAbuseControlTest` and `ProviderGatewaySecurityContractTest` were aligned with the repository's existing deterministic AI provider isolation pattern.

Failing tests:
- None in the executed scope.

Skipped or external tests:
- Real Apple/Google sandbox/internal provider evidence, native/social login configuration, store submission evidence, production release secrets/signing/symbol upload, rollback approval and external release review were not run because they require external accounts or production configuration.

Acceptance criteria coverage:
- AC-COM-010 is covered locally for backend failed-deletion recovery, account deletion status flow, idempotency, audit and cleanup reuse.
- AC-COM-013 is covered locally for commercial boundary recovery testing around account deletion failure, duplicate retry, terminal-state no-op, in-progress conflict and retry failure persistence.

Residual risk:
- This closes the local admin data deletion retry contract gap only. P0 commercial release remains blocked by TC-COM-012/015/019/021/022 external/native/store/release evidence gates.
- The retry executes synchronously in the current backend process; production scheduling/queueing, WORM retention and external privacy evidence remain release/ops concerns outside this local endpoint closure.

## 2026-06-10 P0 Commercial Admin Audit Endpoint Closure

Report ID:
- `P0-COM-ADMIN-AUDIT-ENDPOINT-20260610`

Test scope:
- TC-COM-024 covers local backend/API closure for `GET /admin/audit`.
- Requirement chain: COM-SI-011/012 -> FR-COM-011/012 -> COM-SPEC-011/012 -> AC-COM-013/014 -> COM-TR-011/012 -> TC-COM-024.
- Architecture boundary: reuse existing `AuditLog`, OPS bearer security, `SchemaResponse`, OpenAPI source of truth and generated Dart drift gate; no separate audit store or duplicate admin auth stack.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminAuditControllerTest test` - passed.
- `npm run check:api-contract` - passed; OpenAPI contract gate reported 87 paths, 93 operations, 42 request examples, 88 success examples and 119 error examples.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `defb6aad8bbf84fe39aa3c2982137c7560145ae63d729d30d9d02b9aa70e5a4d`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminAuditControllerTest,CommercialFoundationControllerTest,AiProviderEvidenceControllerTest,AiCostDashboardTest,AiRetentionPolicyTest,AccountDeletionFailureAuditTest test` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --base-ref HEAD --include-worktree` - passed for 14 changed files.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.

Passing tests:
- TC-COM-024 auth: `GET /admin/audit` returns 401 without bearer token and 403 for non-OPS bearer token.
- TC-COM-024 query: endpoint supports bounded `limit`, opaque cursor pagination, exact `event_type`, `actor_type`, `target_ref`, `created_after` and `created_before` filters, and returns newest-first stable results.
- TC-COM-024 projection: response includes schema version, page limit, next cursor and safe audit event fields; it omits `actor_id`.
- TC-COM-024 redaction: JSON and legacy audit details do not leak token, raw transcript, signed URL, media URL or signature-like values.
- TC-COM-024 compliance trace: every successful audit read writes `admin_audit_events_listed` with redacted details.
- TC-COM-024 validation: out-of-range `limit` and malformed cursor return `422` `SCHEMA_VALIDATION_FAILED`.

Failing tests:
- None in the executed scope.

Skipped or external tests:
- Real Apple/Google sandbox/internal provider evidence, native/social login configuration, store submission evidence, production release secrets/signing/symbol upload, rollback approval and external release review were not run because they require external accounts or production configuration.

Acceptance criteria coverage:
- AC-COM-013 is covered locally for audit-driven commercial boundary observability and remains externally blocked for real provider evidence.
- AC-COM-014 is covered locally for admin/compliance audit API readiness and remains release-blocked by strict external/native/store/release evidence.

Residual risk:
- This closes the `/admin/audit` implementation-level contract gap only. P0 commercial release is still not ready until TC-COM-012/015/019/021/022 external/native/store/release gates pass and are independently reviewed.

## 2026-06-09 P02 Followup-B XCB-003 Reminder Eligibility Endpoint Closure

Report ID:
- `P02-FOLLOWUP-B-XCB-003-REMINDER-ELIGIBILITY-ENDPOINT-20260609`

Test scope:
- TC-P02-FUB-018 covers endpoint-level closure for `POST /goal-autopilot/reminders/eligibility`.
- Requirement chain: P02-SI-010 -> P02-FUB-WP-003/004 -> P02-FUB-FR-003/004 -> P02-FUB-SPEC-003/004 -> AC-P02-FUB-003/004 -> P02-FUB-TR-003/004 -> TC-P02-FUB-018.
- Architecture boundary: XCB-003 OpenAPI/generated client source of truth; P02-FUB-API-002 reminder eligibility precheck boundary.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub018ReminderEligibilityEndpointEvaluatesRequestBoundary+tcP02Fub018ReminderEligibilityCommercialAndPlanOwnershipGates+tcP02Fub018ReminderEligibilityMissingPlanDoesNotReturnEligibleWithoutItem+tcP02Fub018ReminderEligibilityRecoveryRequiredDoesNotReturnEligible,GoalAutopilotRuntimeGateTest#tcP02Fud002KillSwitchHidesExistingProjectionAndFailsClosed test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,GoalAutopilotRuntimeGateTest,NotificationEligibilityPolicyTest,GoalAutopilotQuotaDowngradeTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `npm run check:api-contract` - passed without OpenAPI warnings.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `ae03bd46812ddd684bb70fbcb3f927b759c1e70529d1bdd68c0ada18a1aff587`.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --base-ref HEAD --include-worktree` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 95.7%, backend branch 81.1% and Flutter line 89.2%.
- `python3 -m py_compile scripts/check_p0_2_followup_b_traceability.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `python3 scripts/check_p0_2_followup_b_traceability.py` - passed after report synchronization.

Passing tests:
- TC-P02-FUB-018: `GoalAutopilotControllerTest.tcP02Fub018ReminderEligibilityEndpointEvaluatesRequestBoundary` verifies quiet-hours blocking, `permission_denied` for `unknown`, eligible daytime response, malformed `plan_item_id` 422, invalid `reminder_slot` 422, malformed `current_time` 422, three low-sensitivity `notification_eligibility` metric events and zero outbox rows.
- TC-P02-FUB-018: `GoalAutopilotControllerTest.tcP02Fub018ReminderEligibilityCommercialAndPlanOwnershipGates` verifies `quota_exhausted`, `entitlement_blocked`, inactive/current-plan conflict 409 and wrong-owner/nonexistent plan item 404.
- TC-P02-FUB-018: `GoalAutopilotControllerTest.tcP02Fub018ReminderEligibilityMissingPlanDoesNotReturnEligibleWithoutItem` verifies missing plan does not return `eligible=true` with a null item.
- TC-P02-FUB-018: `GoalAutopilotControllerTest.tcP02Fub018ReminderEligibilityRecoveryRequiredDoesNotReturnEligible` verifies recovery-required stale-plan blocking: recovery-required daily plans return `eligible=false` with `stale_plan` before replan.
- TC-P02-FUB-018 runtime regression: `GoalAutopilotRuntimeGateTest.tcP02Fud002KillSwitchHidesExistingProjectionAndFailsClosed` verifies kill switch blocks the endpoint with 503, request id, reason code and audit log id.
- OpenAPI lint/contract and Dart drift pass after endpoint `404`, UUID schema/examples and generated hash pins are synchronized.
- Followup-B traceability checker now validates TC-P02-FUB-018, XCB-003 report terms and traceability rows P02-FUB-TR-003/004.

Failing tests:
- None remain in the executed scope.
- Independent review initially found recovery-required eligibility and malformed `current_time` contract gaps. Both gaps were fixed and covered by the rerun TC-P02-FUB-018 target command.

Skipped or external tests:
- Full all-suite backend/Flutter regression, live notification provider, external production scheduler/send evidence, release readiness and Product Base merge gates were not run.

Acceptance criteria coverage:
- AC-P02-FUB-003 is covered for endpoint request validation, reason-code decisions, quiet-hours, permission, entitlement, quota, stale/missing-plan and runtime-gate behavior.
- AC-P02-FUB-004 is supported for the precheck no-outbox-write boundary; outbox lifecycle remains covered by TC-P02-FUB-007/008.

Residual risk:
- This does not prove live notification provider delivery or commercial release readiness.
- Followup-B is not release-ready and Product Base merge is not approved.

## 2026-06-09 MVP Practice Audio Ref Boundary Regression

Report ID:
- `MVP-PRACTICE-AUDIO-REF-BOUNDARY-20260609`

Test scope:
- TC-MVP-BE-047 covers Practice turn requests that include both transcript and an invalid `audio_ref`.
- TC-MVP-BE-048 covers wrong-owner validated `media://audio/...` refs across Practice turn input and `/ai/transcribe`.
- Requirement chain: MVP-SI-008 -> MVP-BE-FR-008 -> MVP-BE-SPEC-008 -> AC-MVP-BE-008 -> MVP-BE-TR-008 -> TC-MVP-BE-047/048.
- Architecture boundary: XCB-001 trusted audio upload and business consumption boundary; Practice may accept transcript-only input, but any `audio_ref` must be authenticated-user-owned trusted media before persistence.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PracticeTurnControllerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProductionAsrMediaRefTest,MediaUploadReferenceServiceTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=TrainingMediaAiPipelineTest test` - passed.
- `flutter test test/features/training/training_backend_pipeline_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,ProviderGatewayAuthorizationTest,UsageQuotaGateTest test` - passed after updating the stale ASR-unavailable fixture to use a validated trusted media ref.
- `python3 scripts/check_cross_cutting_boundaries.py --scope full` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --base-ref HEAD --include-worktree` - passed.
- `python3 -m py_compile scripts/check_cross_cutting_boundaries.py` - passed.
- `npm run check:api-contract` - passed with OpenAPI hash `7e603dd0bec9879ee2d21516e86fb84e2e652102f677506a59255544befa76f5`.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `7e603dd0bec9879ee2d21516e86fb84e2e652102f677506a59255544befa76f5`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-MVP-BE-047: `PracticeTurnControllerTest.tcMvpBe047RejectsTranscriptTurnWithUntrustedAudioRefBeforePersistenceOrProviderCall` rejects `/tmp/local-answer.wav` when submitted alongside transcript.
- The same test verifies no PracticeTurn is persisted, no CoachFeedback is generated, and `AiGatewayService.invocationCount()` remains zero for the rejected request.
- TC-MVP-BE-048: `PracticeTurnControllerTest.tcMvpBe048RejectsCrossUserValidatedAudioRefBeforePersistenceOrProviderCall` rejects another user's validated `media://audio/...` with `media_not_found`, without turn/feedback persistence or provider invocation.
- Existing Practice turn persistence and idempotency tests in `PracticeTurnControllerTest` still pass.
- Production ASR/media tests reject local paths, unsigned URLs, unvalidated media refs and wrong-owner validated media refs before provider calls, and accept same-owner validated backend media refs.
- Training backend and Flutter adapter tests prove trusted upload/create-complete, `media://audio/...` turn submission, ASR/scoring/coach routing and evidence mapping.
- Provider gateway security/failure/authorization/usage tests pass after the stale `audio://provider_unavailable` fixture was replaced with a validated media-ref based ASR-unavailable fixture.
- OpenAPI lint/contract and Dart drift pass after `SubmitTurnRequest.audio_ref`, `TranscribeRequest.audio_ref` and `PronunciationRequest.audio_ref` were narrowed to trusted `media://audio/{uuid}` and examples were corrected.
- Cross-cutting boundary full scan passes after the Practice fix.

Failing tests:
- None remain in the executed scope.
- Historical note from this validation round: `ProviderGatewayFailureTest.unavailableTranscriptionReturnsRecoverableSessionError` failed once because it still used `audio://provider_unavailable`, which is now correctly rejected by XCB-001. The test fixture was updated to use validated backend media plus a test provider fallback, then the provider/security/fallback/authorization/usage group passed.
- Historical note from independent review: two independent agents found an owner-check gap where `media://audio/{id}` validation checked asset status but not `AiMediaAsset.userId`. The gap was fixed with owner-aware media inspection and TC-MVP-BE-048, then the scoped tests and gates above passed.

Skipped or external tests:
- Full all-suite backend/Flutter regression, live provider, external object-storage and release readiness suites were not run; this validation targets XCB-001/XCB-002 boundary, contract and traceability regressions.

Acceptance criteria coverage:
- AC-MVP-BE-008 now includes negative `audio_ref` acceptance paths: any Practice turn carrying `audio_ref` must validate ref shape, owner and validated status before persistence, feedback or provider calls.

Residual risk:
- This does not implement new audio upload UI or object-storage behavior; it only enforces that Practice cannot consume untrusted refs.

## 2026-06-07 P02 Followup-E Docs-Only Planning Reclassification

Report ID:
- N/A - implementation evidence reclassified to planned

Test scope:
- TC-P02-FUE-000..026 remain planned.
- This report records that previous Followup-E backend/Flutter implementation evidence claims are not accepted as current project evidence.
- MVP/P0.1 local mic/recording capability remains existing baseline capability; Followup-E should reuse that boundary and add Speaking Check orchestration plus trusted upload bridging rather than duplicate mic development.

Commands run:
- No backend, Flutter, OpenAPI, generated-client, AI runtime or release commands are accepted as Followup-E evidence in this docs-only state.

Passing tests:
- None for Followup-E implementation.

Failing tests:
- N/A - implementation tests have not been accepted.

Skipped or external tests:
- All TC-P02-FUE-000..026 executable checks remain planned until an approved implementation slice runs.
- Native mic/audio bytes upload, ASR/scoring/result, retention/export/account deletion, entitlement/provider downgrade, paid AI external evidence, release readiness and Product Base merge remain open.

Acceptance criteria coverage:
- AC-P02-FUE-000..010 have planned TC coverage in `test_cases.md` and traceability rows in `traceability.md`.
- No AC is closed by executable Followup-E evidence in this docs-only state.

Residual risk:
- Local uncommitted Followup-E code may exist in the working tree, but it is not accepted report evidence here.
- Any future implementation claim must cite TC ID, script path, command, result status, report evidence and independent review after the slice is intentionally executed.

## 2026-06-07 P02 Followup-C S007 Checker Hash Sync

Report ID:
- `P02-FOLLOWUP-C-S007-CHECKER-HASH-SYNC-20260607`

Test scope:
- TC-P02-FUC-021 dedicated Followup-C traceability checker remains executable after later valid OpenAPI/generated Dart hash updates.
- TC-P02-FUC-022 report and generated-artifact drift evidence remains consistent without changing production backend, Flutter, OpenAPI or generated Dart API shape.

Commands run:
- `python3 -m py_compile scripts/check_p0_2_followup_c_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_c_traceability.py` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 95.7%, backend branch 81.1% and Flutter line 90.9%.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`, 93 operations and 196 schemas.
- `npm run check:api-contract` - passed: OpenAPI lint passed, contract gate reported 87 paths, 93 operations, 42 request examples, 88 success examples and 113 error examples, and Dart drift passed with OpenAPI hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_b_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_d_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_d_final_review.py` - passed with release/Product Base blockers preserved.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUC-021: `scripts/check_p0_2_followup_c_traceability.py` now validates the current manifest `openapi_sha256`, `lib/generated/api/.openapi-sha256` and `SpeakeasyApiContract.openApiSha256` agree.
- TC-P02-FUC-021: historical S007 nullable-cleanup report evidence still requires `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606` and the original cleanup hash in reports only.
- TC-P02-FUC-022: generated Dart drift remains green at the current hash; no API regeneration or OpenAPI shape change occurred in this fix.
- Cross-followup guard: A goal-autopilot traceability, Followup-B traceability and Followup-D traceability/final review gates still pass after the checker/report sync.

Failing tests:
- None remain in the scoped checker-regression command set.

Skipped or external tests:
- No backend or Flutter runtime regression was required because this change updates a deterministic checker and reports only.
- No live provider, store, payment, native social login, release-readiness or Product Base merge evidence was executed.

Acceptance criteria coverage:
- AC-P02-FUC-007 remains covered locally by TC-P02-FUC-021/022 for repeatable traceability/report/checker evidence after valid downstream OpenAPI hash changes.

Residual risk:
- This change does not approve Followup-C release readiness, Followup-D release readiness or Product Base merge.

## 2026-06-07 P02 Followup-D S011 Final Review

Report ID:
- `P02-FOLLOWUP-D-S011-FINAL-REVIEW-20260607`

Test scope:
- TC-P02-FUD-020 final report/release checklist synchronization: implementation, test, quality, traceability, development status, release checklist and rollback evidence must cite TC IDs, scripts, commands, results and residual risk.
- TC-P02-FUD-021 final independent review: Product Base merge state, commercial release state and paid AI external evidence state must remain separate, with product and software engineering blocker/no-blocker findings recorded.
- Non-goal: no production backend, Flutter or API shape changed; S011 does not approve commercial release, paid AI external evidence, native/store/payment evidence or Product Base merge.

Commands run:
- `python3 -m py_compile scripts/check_p0_2_followup_d_final_review.py scripts/check_p0_2_followup_d_traceability.py` - passed.
- `npm run check:api-contract` - passed: OpenAPI lint passed, contract gate reported 87 paths, 93 operations, 42 request examples, 88 success examples and 113 error examples, and Dart drift passed with OpenAPI hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`, 93 operations and 196 schemas.
- `bash -n scripts/check_release_readiness.sh` - passed.
- `scripts/check_release_readiness.sh --env-only` with fixture production/evidence environment variables - passed.
- Strict `scripts/check_release_readiness.sh` with the same fixture variables - strict release readiness failed as expected with status 1 because social login native release evidence remains blocked: iOS WeChat placeholder URL scheme and missing Sign in with Apple entitlement.
- `python3 scripts/check_p0_2_followup_d_traceability.py` - passed after report synchronization.
- `python3 scripts/check_p0_2_followup_d_final_review.py` - passed after report synchronization.
- `python3 scripts/project_agent_runner.py validate` - passed after report synchronization.
- `git diff --check` - passed after report synchronization.

Passing tests:
- TC-P02-FUD-020: `scripts/check_p0_2_followup_d_final_review.py` validates S011 closure terms across Followup-D docs, TC-P02-FUD-020/021 rows, P02-FUD-TR-011, reports, development status, release checklist and rollback plan.
- TC-P02-FUD-020: API contract and generated Dart drift checks remain green; no OpenAPI or generated client shape changed in S011.
- TC-P02-FUD-020: release checklist now records local S001-S011 final review passed while Product Base merge approval, external commercial evidence, paid AI external evidence and strict release readiness remain blocked.
- TC-P02-FUD-021: Product engineer and software engineer independent review recorded with blocker/no-blocker finding in the quality report.
- TC-P02-FUD-021: strict release readiness remains blocked by native social login evidence, proving S011 did not convert local final review into release approval.

Failing tests:
- None remain in the scoped S011 local command set.
- Strict `scripts/check_release_readiness.sh` intentionally remains blocked without native/external release evidence; this is the expected release blocker, not a local S011 failure.

Skipped or external tests:
- No live paid AI provider, payment provider, store submission, native social login remediation or Product Base merge approval was executed.
- No backend or Flutter runtime regression was required for S011 because this slice changed documentation, release evidence state and deterministic review checkers only.

Acceptance criteria coverage:
- AC-P02-FUD-011 is locally covered by TC-P02-FUD-020/021 for final report synchronization, Product Base/release/paid AI state separation, strict release blocker preservation and independent review execution.

Residual risk:
- Followup-D is not release-ready and Product Base merge is not approved.
- Commercial release external evidence, paid AI external evidence, native social login evidence and PM/release governance approval remain outside S011.

## 2026-06-07 P02 Followup-D S010 Drift Gates

Report ID:
- `P02-FOLLOWUP-D-S010-DRIFT-GATES-20260607`

Test scope:
- TC-P02-FUD-018 dedicated Followup-D traceability checker coverage for definition, requirements, spec, acceptance, test cases, traceability, reports, development status, release checklist and rollback plan synchronization.
- TC-P02-FUD-019 contract/release drift coverage for OpenAPI contract, generated Dart client drift, release readiness fixture wiring and strict release readiness blocker preservation.
- S010 non-goal at S010 close: no production backend, Flutter or API shape changed; S010 did not approve the then-open S011 final review, external/native/store evidence, commercial release or Product Base merge.

Commands run:
- `python3 -m py_compile scripts/check_p0_2_followup_d_traceability.py` - passed.
- `npm run check:api-contract` - passed: OpenAPI lint passed, contract gate reported 87 paths, 93 operations, 42 request examples, 88 success examples and 113 error examples, and Dart drift passed with OpenAPI hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`, 93 operations and 196 schemas.
- `bash -n scripts/check_release_readiness.sh` - passed.
- `scripts/check_release_readiness.sh --env-only` with fixture production/evidence environment variables - passed.
- Strict `scripts/check_release_readiness.sh` with the same fixture variables - strict release readiness failed as expected with status 1 because social login native release evidence remains blocked: iOS WeChat placeholder URL scheme and missing Sign in with Apple entitlement.
- `python3 scripts/check_p0_2_followup_d_traceability.py` - passed after report synchronization.
- `python3 scripts/project_agent_runner.py validate` - passed after report synchronization.
- `git diff --check` - passed after report synchronization.

Passing tests:
- TC-P02-FUD-018: `scripts/check_p0_2_followup_d_traceability.py` validates S010 closure terms across Followup-D definition, requirements, spec, acceptance, test cases, traceability, reports, development status, release checklist and rollback plan.
- TC-P02-FUD-018: the checker blocks missing S010 evidence anchors, missing TC-P02-FUD-018/019 passed rows, missing report IDs and forbidden release/completion claims.
- TC-P02-FUD-019: API contract and generated Dart drift checks remain green; no OpenAPI or generated client shape changed in S010.
- TC-P02-FUD-019: release checklist and rollback plan now carry the local S001-S010 passed / S011 blocked state, rollback control points, audit-log preservation and explicit no-release-approval boundary.
- TC-P02-FUD-019: strict release readiness remains blocked by native social login evidence, proving S010 did not convert local drift gates into release approval.

Failing tests:
- None remain in the scoped S010 local command set.
- Strict `scripts/check_release_readiness.sh` intentionally remains blocked without native/external release evidence; this is the expected release blocker, not a local S010 failure.

Skipped or external tests:
- S011 final Product Base/release decision review was not executed.
- No live paid AI provider, payment provider, store submission, native social login remediation or Product Base merge evidence was executed.
- No backend or Flutter runtime regression was required for S010 because this slice changed documentation, release evidence state and a deterministic checker only.

Acceptance criteria coverage:
- AC-P02-FUD-010 is locally covered by TC-P02-FUD-018/019 for traceability/report synchronization, OpenAPI/generated drift gates, release checklist/rollback sync and strict release blocker preservation.

Residual risk:
- At S010 close, S011 remained open for final Product Base/release review; current S011 evidence is recorded above.
- Followup-D is not release-ready and Product Base merge is not approved.

## 2026-06-07 P02 Followup-D S009 Telemetry

Report ID:
- `P02-FOLLOWUP-D-S009-TELEMETRY-20260607`

Test scope:
- TC-P02-FUD-016 integration coverage for redacted metric events across goal intake, diagnostic assessment, plan generation, control update, next action, action completion, checkpoint, projection read, provider fallback, quota block and kill-switch paths.
- TC-P02-FUD-017 release-check coverage for telemetry schema redaction, required event tokens, fallback audit behavior and sensitive-field omissions.
- Regression coverage for S007 data governance export/deletion, S005 cost telemetry, S006 quota downgrade, S001 runtime gate, migration validation and P0.2 changed-code coverage.

Commands run:
- `python3 -m py_compile scripts/check_p0_2_followup_d_telemetry_redaction.py` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotTelemetryTest test` - passed after aligning assertions to existing response contracts.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotDataExportRetentionTest test` - passed.
- `python3 scripts/check_p0_2_followup_d_telemetry_redaction.py` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotTelemetryTest,GoalAutopilotDataExportRetentionTest,GoalAutopilotCostTelemetryTest,GoalAutopilotQuotaDowngradeTest,GoalAutopilotRuntimeGateTest test` - passed.
- Backend JaCoCo goal-autopilot suite including S009 tests and prior S001-S008 regressions - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with `P0.2 coverage: backend line=95.7% branch=81.1%; flutter line=90.9%`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest test` - passed.

Passing tests:
- TC-P02-FUD-016: `GoalAutopilotTelemetryTest#tcP02Fud016RecordsRedactedFunnelHealthAndBlockedReasonMetrics` proves S009 metric events are recorded for the main funnel/health/error paths with stable blocked reason codes.
- TC-P02-FUD-016: quota exhaustion records `quota_error` with `quota_exhausted`, kill switch records `kill_switch_event` with `kill_switch_active`, provider fallback records fallback status, and projection/checkpoint low-confidence reasons are preserved.
- TC-P02-FUD-016: metric rows use redacted user hash and safe refs, not raw diagnostic/checkpoint text, raw audio, provider payload, raw user UUID or idempotency key.
- TC-P02-FUD-016: `GoalAutopilotTelemetryTest#tcP02Fud016TelemetryWriteFailureFallsBackToAuditWithoutBlockingUserPath` proves forced telemetry write failure leaves the user path successful and records redacted fallback audit evidence.
- TC-P02-FUD-017: `scripts/check_p0_2_followup_d_telemetry_redaction.py` verifies migration/entity/service/test tokens for schema minimization, non-blocking fallback and required event coverage.
- Regression: S007 export/deletion now includes `goal_autopilot_metric_events`, account deletion removes metric rows by redacted user hash, and prior runtime/cost/quota tests continue to pass.

Failing tests:
- None remain in the scoped S009 command set.
- During development, the S009 telemetry test initially asserted old JSON paths and optimistic checkpoint/projection statuses; assertions were corrected to the existing `goal_profile` response and low-confidence policy contract, then reruns passed.

Skipped or external tests:
- No S010 drift checker, S011 final Product Base/release decision review, live paid AI provider evidence, external payment/store/native evidence or Product Base merge evidence was executed.
- No OpenAPI/generated Dart drift check was required because S009 added internal telemetry persistence and data-governance metadata only, with no public API shape change.
- No Flutter tests were required for S009 because no Flutter code path changed in this slice.

Acceptance criteria coverage:
- AC-P02-FUD-009 is locally covered by TC-P02-FUD-016/017 for redacted metric events, stable blocked reason codes, rollout health/error/funnel coverage and non-blocking telemetry failure fallback.

Residual risk:
- At S009 close, S010/S011 remained open for contract/release drift gates and final Product Base/release review; current S010 evidence is recorded above.
- S009 proves local deterministic backend telemetry only. It does not approve commercial release, paid AI external evidence, store/native evidence or Product Base merge.

## 2026-06-07 P02 Followup-D S008 Consent Privacy UX

Report ID:
- `P02-FOLLOWUP-D-S008-CONSENT-PRIVACY-UX-20260607`

Test scope:
- TC-P02-FUD-015 widget coverage for visible P0.2 privacy/data-use copy, backend consent/reminder/projection state rendering, notification consent withdrawal blocking and stale privacy state cleanup.
- Copy contract coverage for required Goal Autopilot privacy copy and prohibited release/commercial promise phrases.
- Regression coverage for goal_autopilot widget suite, frontend source-of-truth guard and P0.2 changed-code coverage.

Commands run:
- `flutter test test/features/goal_autopilot/goal_autopilot_consent_privacy_widget_test.dart` - passed.
- `flutter test test/features/goal_autopilot` - passed.
- `flutter test --coverage test/features/goal_autopilot` - passed.
- `flutter analyze lib/features/goal_autopilot/goal_autopilot_panel.dart test/features/goal_autopilot/goal_autopilot_consent_privacy_widget_test.dart` - passed.
- `python3 scripts/check_commercial_copy_contract.py` - passed, with external release blockers still reported for missing `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL` and `SUPPORT_URL`.
- `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with `P0.2 coverage: backend line=96.0% branch=81.2%; flutter line=90.9%`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- <S008 changed files and reports>` - passed.

Passing tests:
- TC-P02-FUD-015: `goal_autopilot_consent_privacy_widget_test.dart` proves privacy/data-use, export/delete/retention and sensitive-payload omission copy is visible and release-safe.
- TC-P02-FUD-015: notification consent withdrawal sends `notification_consent=false`, renders `Notifications: consent withdrawn`, blocks reminder prompts with backend `consent_missing` reason and removes stale `consent on` / `Reminder prompts: eligible` state.
- TC-P02-FUD-015: deleted projection state renders `Data state: deleted` and does not display stale `Data state: ready`.
- Copy contract: `scripts/check_commercial_copy_contract.py` verifies required Goal Autopilot privacy copy and blocks guaranteed achievement, official-score equivalence, unlimited AI, unlimited checkpoint and release-approved wording.
- Regression: full `test/features/goal_autopilot` suite, Flutter analyze, frontend source-of-truth and coverage gates continue to pass.

Failing tests:
- None remain in the scoped S008 command set.
- During regression, placing the privacy section before primary controls initially pushed legacy test tap targets below the default widget-test viewport; the section was moved after primary controls and the full goal_autopilot suite passed.

Skipped or external tests:
- No S009 telemetry metric/redaction tests, S010 drift gates, S011 release/Product Base decision review, live paid AI provider evidence, external payment/store/native evidence or Product Base merge evidence was executed.
- `python3 scripts/check_commercial_copy_contract.py` reports external store/privacy/support evidence blockers, but those are release-gate blockers outside S008 local UX completion.

Acceptance criteria coverage:
- AC-P02-FUD-008 is locally covered by TC-P02-FUD-015 for backend-aligned privacy copy, notification consent withdrawal behavior, release-safe copy guard and stale privacy state cleanup.

Residual risk:
- S009-S011 remain open for telemetry, drift/release gates and final Product Base/release review.
- S008 does not approve commercial release, paid AI external evidence, store/native evidence or Product Base merge.

## 2026-06-07 P02 Followup-D S007 Data Governance

Report ID:
- `P02-FOLLOWUP-D-S007-DATA-GOVERNANCE-20260607`

Test scope:
- TC-P02-FUD-013 integration coverage for redacted P0.2 export records, omitted sensitive fields and retention rules across goal/autopilot/progress/usage/cost data families.
- TC-P02-FUD-014 integration coverage for account deletion cleanup across P0.2 user-owned tables and redacted audit proof.
- Regression coverage for S001-S006 backend policies, OpenAPI/generated Dart drift, Flutter goal-autopilot surfaces, frontend source-of-truth and P0.2 changed-code coverage.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotDataExportRetentionTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotDataExportRetentionTest,AccountDeletionLearningDataTest,GoalAutopilotUsageReservationTest,UsageReservationLifecycleTest,GoalAutopilotCostTelemetryTest,GoalAutopilotQuotaDowngradeTest,GoalAutopilotControllerTest,GoalAutopilotReplayFixtureTest test` - passed after stabilizing a date fixture in `GoalAutopilotControllerTest#tcP02Fuc002CheckpointTaskLibrary`.
- Backend JaCoCo goal-autopilot suite with `GoalAutopilotDataExportRetentionTest`, account deletion and prior S001-S006 regressions - passed.
- `npm run check:api-contract` - passed with 87 paths, 93 operations, 42 request examples, 88 success examples, 113 error examples and generated Dart hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `flutter analyze` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with `P0.2 coverage: backend line=96.0% branch=81.2%; flutter line=90.5%`; backend changed-code line 96.0% and branch 81.2% remain above the 80% gate.

Passing tests:
- TC-P02-FUD-013: `GoalAutopilotDataExportRetentionTest#tcP02Fud013ExportReturnsRedactedRecordsAndRetentionRulesForP02Families` proves export family `goal_autopilot_p0_2`, user hash redaction, retention rules, deletion tables and safe/redacted/omitted field metadata across all S007 data families.
- TC-P02-FUD-013: raw diagnostic transcript/audio refs, checkpoint transcript/audio refs, notification payload details, provider payload details and raw idempotency keys are omitted from export output.
- TC-P02-FUD-014: `GoalAutopilotDataExportRetentionTest#tcP02Fud014AccountDeletionPurgesP02DataFamiliesAndKeepsRedactedAuditProof` proves account deletion purges P0.2 goal/autopilot/progress/usage/cost user-owned rows and keeps redacted audit details including P0.2 deletion evidence.
- Regression: API contract drift, Flutter source-of-truth, Flutter goal-autopilot coverage and backend S001-S006 suites continue to pass.

Failing tests:
- None remain in the scoped S007 command set.
- During regression, `GoalAutopilotControllerTest#tcP02Fuc002CheckpointTaskLibrary` initially used JVM default `LocalDate.now()` while the app uses the Spring `Clock`; the fixture now uses the same `Clock` and reruns passed.

Skipped or external tests:
- No consent/privacy UX implementation, telemetry redaction checker, release drift checker, live paid AI provider evidence, external payment/store/native evidence or Product Base merge evidence was executed; those remain S008-S011 / external gate scope.

Acceptance criteria coverage:
- AC-P02-FUD-007 is locally covered by TC-P02-FUD-013 and TC-P02-FUD-014 for redacted export, retention table coverage, sensitive payload omission/hash boundary, account deletion cleanup and redacted audit proof.

Residual risk:
- S008-S011 remain open for consent/privacy UX, telemetry, drift/release gates and final Product Base/release review.
- S007 does not approve commercial release, paid AI external evidence, store/native evidence or Product Base merge.

## 2026-06-06 P02 Followup-D S006 Quota Downgrade

Report ID:
- `P02-FOLLOWUP-D-S006-QUOTA-DOWNGRADE-20260606`

Test scope:
- TC-P02-FUD-011 integration coverage for quota exhausted, entitlement blocked and cost budget limited stable downgrade reasons across plan, forecast, projection and checkpoint task surfaces.
- TC-P02-FUD-012 Flutter widget coverage for Home/Queue/Wiki/Panel stale full-depth cleanup and no local quota/entitlement inference.
- Regression coverage for S001-S005 backend policies, OpenAPI/generated Dart drift, Flutter API contract consumption, source-of-truth guard and P0.2 changed-code coverage.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotQuotaDowngradeTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotQuotaDowngradeTest,GoalAutopilotEntitlementPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControllerTest,GoalAutopilotUsageReservationTest,GoalAutopilotCostTelemetryTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotReplayFixtureTest test` - passed.
- Backend JaCoCo goal-autopilot suite with `GoalAutopilotQuotaDowngradeTest` and prior S001-S005 regressions - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_quota_downgrade_widget_test.dart` - passed.
- `flutter test test/features/goal_autopilot` - passed.
- `flutter analyze` - passed.
- `npm run check:api-contract` - passed with 87 paths, 93 operations, 42 request examples, 88 success examples, 113 error examples and generated Dart hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.
- `npm run check:dart-client-drift` - passed with the same hash.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with `P0.2 coverage: backend line=95.9% branch=81.2%; flutter line=90.5%`.
- `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-P02-FUD-011: `GoalAutopilotQuotaDowngradeTest` proves quota exhaustion returns `quota_exhausted` before additional plan writes, marks projection/forecast unavailable without full-depth fragments, and exposes typed downgrade details on rejected mutations.
- TC-P02-FUD-011: entitlement blocked paths return stable `entitlement_required` for forecast, plan error details and checkpoint task limitation while preserving raw entitlement source reason under server-owned entitlement depth/details.
- TC-P02-FUD-011: cost-budget-limited entitlement returns `cost_budget_limited`, disables provider/full-depth paths and keeps checkpoint/projection behavior downgraded.
- TC-P02-FUD-012: Flutter Home/Queue/Wiki and panel widget tests remove stale action, ETA, checkpoint and plan controls after quota/entitlement/cost downgrade and render backend reason without local inference.
- Contract regression: OpenAPI stable downgrade reason enums and generated Dart drift pins passed with hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.

Failing tests:
- None remain in the scoped S006 command set.
- During regression, `GoalAutopilotControllerTest#tcP02Fub001...` and `GoalAutopilotReplayFixtureTest#tcP02Fub015...` initially failed because the current run time was inside Asia/Shanghai quiet hours; the fixtures now disable quiet hours only for eligible-reminder branches and reruns passed.

Skipped or external tests:
- No live paid AI provider, external payment/store/native evidence, data export/deletion evidence, telemetry redaction gate or Product Base merge evidence was executed; those remain S007-S011 / external gate scope.

Acceptance criteria coverage:
- AC-P02-FUD-006 is locally covered by TC-P02-FUD-011 and TC-P02-FUD-012 for stable quota/cost/entitlement downgrade reasons, full-depth block/downgrade behavior and Flutter stale full-depth cleanup.

Residual risk:
- S007-S011 remain open for data governance, consent UX, telemetry, release drift and final release/Product Base review.
- S006 does not approve commercial release, paid AI external evidence, store/native evidence or Product Base merge.

## 2026-06-06 P02 Followup-D S005 Cost Telemetry And AI Fallback

Report ID:
- `P02-FOLLOWUP-D-S005-COST-TELEMETRY-AI-FALLBACK-20260606`

Test scope:
- TC-P02-FUD-009 integration coverage for plan/checkpoint deterministic no-provider metrics, entitlement/provider-candidate rejection metrics, quota rejection metrics, redaction and no entitlement-fact creation.
- TC-P02-FUD-010 AI eval/guardrail coverage for forecast and mastery candidates that attempt forbidden entitlement, quota, final mastery, release approval or Product Base merge fields.
- Regression coverage for cost dashboard fallback reason, AI schema tests, usage/quota, entitlement depth, API/generated contract drift, Flutter API contract consumption and P0.2 changed-code coverage.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotCostTelemetryTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotAiGuardrailTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ForecastExplanationSchemaTest,MasteryTransitionPolicyTest,GoalAutopilotAiGuardrailTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest,GoalAutopilotCostTelemetryTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest,GoalAutopilotCostTelemetryTest,GoalAutopilotAiGuardrailTest test` - passed after adding the dashboard `fallback_reason` API assertion.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotCostTelemetryTest,GoalAutopilotAiGuardrailTest,GoalAutopilotUsageReservationTest,UsageQuotaGateTest,UsageReservationLifecycleTest,GoalAutopilotEntitlementPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControllerTest test` - passed.
- Backend JaCoCo goal-autopilot suite with S005 tests and prior S001-S004 regressions - passed.
- `npm run check:api-contract` - passed with 87 paths, 93 operations, 42 request examples, 88 success examples, 113 error examples and generated Dart hash `3196a97f38da3d2f01044cbeab242fa3a78c449ff4bb92fa4ccce549fc96686c`.
- `flutter analyze` - passed.
- `flutter test test/services/api_client_contract_test.dart` - passed.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with `P0.2 coverage: backend line=96.1% branch=81.3%; flutter line=90.5%`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUD-009: `GoalAutopilotCostTelemetryTest#tcP02Fud009DeterministicNoProviderMetricsAreRecordedForPlanAndCheckpoint` proves full-depth deterministic plan/checkpoint paths record `deterministic_no_provider` metrics with zero estimated cost, safe fallback reasons and no raw transcript/user id leakage.
- TC-P02-FUD-009: `GoalAutopilotCostTelemetryTest#tcP02Fud009PolicyRejectionAndQuotaMetricsDoNotCreateEntitlementFacts` proves free fallback records rejected provider-candidate metric without creating entitlement snapshots, and quota exhaustion records rejected cost telemetry even though the API returns quota failure.
- TC-P02-FUD-009: `AiCostDashboardTest#tcP02Fud009CostDashboardExposesFallbackReasonForDeterministicNoProvider` proves ops dashboard responses expose `fallback_reason` for deterministic no-provider cost metrics.
- TC-P02-FUD-010: `GoalAutopilotAiGuardrailTest` proves forecast and mastery candidate validators reject entitlement/quota/final mastery/release/Product Base fields with `ai_forbidden_persistent_field` and do not mutate persistent state.
- Contract regression: OpenAPI `AiCostMetric` includes `fallback_reason`, `deterministic_no_provider` status and generated Dart drift pins with hash `3196a97f38da3d2f01044cbeab242fa3a78c449ff4bb92fa4ccce549fc96686c`.

Failing tests:
- None in the scoped S005 command set.

Skipped or external tests:
- No live paid AI provider or external provider evidence was executed. Deterministic no-provider and policy rejection metrics are explicit local evidence only.
- Quota exhausted downgrade surfaces, data export/retention, consent UX, telemetry drift checker, release checklist and Product Base merge evidence remain S006-S011 scope.

Acceptance criteria coverage:
- AC-P02-FUD-005 is locally covered by TC-P02-FUD-009 and TC-P02-FUD-010 for sanitized metrics, policy rejection/fallback evidence, deterministic N/A/no-provider status and AI forbidden persistent-field rejection.

Residual risk:
- S006-S011 remain open for quota downgrade, data governance, consent UX, telemetry, drift gates and final release/Product Base review.
- S005 does not approve commercial release, paid AI external evidence, store/native evidence or Product Base merge.

## 2026-06-06 P02 Followup-D S004 Usage Reservation And Quota

Report ID:
- `P02-FOLLOWUP-D-S004-USAGE-RESERVATION-QUOTA-20260606`

Test scope:
- TC-P02-FUD-007 integration coverage for full-depth plan/checkpoint usage reservation, commit, failed-checkpoint release, idempotent retry and same idempotency key different payload conflict.
- TC-P02-FUD-008 integration/contract regression coverage for usage quota gate, reservation lifecycle DTOs, source-ref idempotency comparison, OpenAPI/generated Dart drift and existing usage ledger behavior.
- Regression coverage for S001 runtime gate, S003 entitlement depth, Followup-B/C goal-autopilot backend policies, Flutter API contract consumption and P0.2 changed-code coverage.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotUsageReservationTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=UsageQuotaGateTest,UsageReservationLifecycleTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotUsageReservationTest,UsageQuotaGateTest,UsageReservationLifecycleTest,GoalAutopilotEntitlementPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControllerTest test` - passed.
- `npm run check:api-contract` - passed with 87 paths, 93 operations, 42 request examples, 88 success examples, 113 error examples and generated Dart hash `38dd8133c0551dc019eaf56fe8ccde3016db5f3180f9f578e85714ba5aae61b2`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,GoalAutopilotRuntimeGateTest,GoalAutopilotEntitlementPolicyTest,GoalAutopilotUsageReservationTest,UsageQuotaGateTest,UsageReservationLifecycleTest,GoalProgressProjectionDataGovernanceTest,GoalProgressProjectionServiceTest,ProgressForecastPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControlPerformanceTest,NotificationOutboxReplayTest,MissedDayRecoveryPlannerTest,GoalAutopilotReplayFixtureTest,NotificationEligibilityPolicyTest,MemoryCurveReplayTest,MasteryTransitionPolicyTest,GoalProgressProjectionPerformanceTest,ForecastExplanationSchemaTest,CheckpointReplayAuditTest,GoalAutopilotRecoveryControllerTest,MemoryCurvePolicyTest,NotificationOutboxServiceTest org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with `P0.2 coverage: backend line=96.0% branch=81.1%; flutter line=90.5%`.
- `flutter analyze` - passed.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUD-007: `GoalAutopilotUsageReservationTest#tcP02Fud007PlanUsageIsReservedCommittedAndIdempotent` proves full-depth plan generation reserves `ai` usage before plan writes, commits exactly once on success, exposes source/provider event refs, does not double charge on idempotent retry and returns typed `IDEMPOTENCY_CONFLICT` before new plan writes when the same request id carries a different payload.
- TC-P02-FUD-007: `GoalAutopilotUsageReservationTest#tcP02Fud007CheckpointUsageCommitsSuccessfulEvidenceAndReleasesLowConfidenceFallback` proves checkpoint scoring reserves `scoring` usage, commits successful recorded evidence and releases failed checkpoint fallback without increasing committed usage.
- TC-P02-FUD-008: `GoalAutopilotUsageReservationTest#tcP02Fud008QuotaBlocksBeforePlanWritesAndLimitedDepthDoesNotReserveUsage` proves quota exhaustion returns typed `USAGE_LIMIT_EXCEEDED` before new backplan writes and free/limited depth does not reserve usage.
- TC-P02-FUD-008: `UsageReservationLifecycleTest` and `UsageQuotaGateTest` prove usage DTO source/idempotency/provider event refs, lifecycle reserve/commit/release semantics, quota gate accounting and source-ref-aware idempotency conflict behavior.
- Contract regression: OpenAPI `UsageReservation` schema, `/usage/reserve` 409 conflict response and generated Dart drift pins passed with hash `38dd8133c0551dc019eaf56fe8ccde3016db5f3180f9f578e85714ba5aae61b2`.

Failing tests:
- None in the scoped S004 command set.

Skipped or external tests:
- No live paid AI provider, external provider unavailable scenario, cost dashboard, store/native release or Product Base merge evidence was executed; those remain S005-S011 / external gate scope.

Acceptance criteria coverage:
- AC-P02-FUD-004 is locally covered by TC-P02-FUD-007 and TC-P02-FUD-008 for reserve before deterministic costly execution, success commit exactly once, failed checkpoint release/no-charge, quota blocked before writes, idempotent retry without double charge and typed idempotency conflict.

Residual risk:
- S005-S011 remain open for cost telemetry, AI fallback, quota downgrade surfaces, data governance, consent UX, telemetry, drift gates and final release/Product Base review.
- S004 does not approve commercial release, paid AI external evidence, store/native evidence or Product Base merge.

## 2026-06-06 P02 Followup-D S003 Entitlement Depth

Report ID:
- `P02-FOLLOWUP-D-S003-ENTITLEMENT-DEPTH-20260606`

Test scope:
- TC-P02-FUD-005 unit coverage for paid/full, free/default, expired/grace/revoked/refunded/unknown, support override and quota/cost-limited entitlement depth decisions.
- TC-P02-FUD-006 integration/widget/contract coverage for server-owned `entitlement_depth`, revoked plan/checkpoint blocking, paid full-depth eligibility, partial support override and Flutter no-local entitlement inference.
- Regression coverage for existing goal-autopilot controller/checkpoint behavior, Flutter goal-autopilot surfaces, OpenAPI/generated drift and P0.2 changed-code coverage.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotEntitlementPolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fud003EntitlementDepthIsServerOwned test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc002CheckpointTaskLibrary test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotEntitlementPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControllerTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter test test/features/goal_autopilot` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` - passed.
- `npm run check:api-contract` - passed with generated Dart hash `9269bc0c15413f57377629ee3c142fb41d4180518c5f93e81cbfadfcc59a7bd3`.
- `flutter analyze` - passed.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,GoalAutopilotRuntimeGateTest,GoalAutopilotEntitlementPolicyTest,GoalProgressProjectionDataGovernanceTest,GoalProgressProjectionServiceTest,ProgressForecastPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControlPerformanceTest,NotificationOutboxReplayTest,MissedDayRecoveryPlannerTest,GoalAutopilotReplayFixtureTest,NotificationEligibilityPolicyTest,MemoryCurveReplayTest,MasteryTransitionPolicyTest,GoalProgressProjectionPerformanceTest,ForecastExplanationSchemaTest,CheckpointReplayAuditTest,GoalAutopilotRecoveryControllerTest,MemoryCurvePolicyTest,NotificationOutboxServiceTest org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with `P0.2 coverage: backend line=96.1% branch=81.0%; flutter line=90.5%`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUD-005: `GoalAutopilotEntitlementPolicyTest` proves paid active full depth only when support/quota/cost allow, free/default depth limited, expired/grace downgraded, revoked/refunded/unknown blocked even when `valid_until` is already past, and partial/unsupported/low-confidence support limits override paid depth.
- TC-P02-FUD-006: `GoalAutopilotControllerTest#tcP02Fud003EntitlementDepthIsServerOwned` proves `entitlement_depth` is returned by the backend, default-free users are limited, paid users can reach full depth, partial paid users are limited by support status, revoked users cannot generate a plan, do not receive precise forecast ETA and receive unavailable checkpoint task state.
- TC-P02-FUD-006: Flutter adapter/widget test renders server-owned entitlement limitation reason and suppresses generate-plan UI only from `depth_state=blocked`, without local pro/free inference.
- Contract regression: OpenAPI `GoalEntitlementDepth` schema, response examples and generated Dart drift pins passed with hash `9269bc0c15413f57377629ee3c142fb41d4180518c5f93e81cbfadfcc59a7bd3`.

Failing tests:
- None in the scoped S003 command set.

Skipped or external tests:
- No live payment provider, usage reservation, paid AI provider, store, release or Product Base merge evidence was executed; those remain S004-S011 / external gate scope.

Acceptance criteria coverage:
- AC-P02-FUD-003 is locally covered by TC-P02-FUD-005 and TC-P02-FUD-006 for entitlement/free-paid depth, support override, blocked full-depth behavior and Flutter service-owned limitation display.

Residual risk:
- S004-S011 remain open for usage reservation/quota, cost telemetry, quota downgrade, data governance, consent UX, telemetry, release drift and final release/Product Base review.
- S003 does not approve commercial release, paid AI external evidence, store/native evidence or Product Base merge.

## 2026-06-06 P02 Followup-D S002 Flutter Runtime Rollback

Report ID:
- `P02-FOLLOWUP-D-S002-FLUTTER-RUNTIME-ROLLBACK-20260606`

Test scope:
- TC-P02-FUD-003 widget coverage for disabled projection, backend runtime unavailable, no no-goal fallback, no mutation controls and stale projection copy removal.
- TC-P02-FUD-004 frontend source-of-truth guard for adapter/panel/Home runtime gate wiring, unavailable projection safety and forbidden local inference.
- Regression coverage for existing Goal Autopilot Followup-A/B/C Flutter behavior, API drift and P0.2 changed-code coverage.

Commands run:
- `flutter test test/features/goal_autopilot/goal_autopilot_runtime_gate_widget_test.dart` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` - passed.
- `flutter test test/features/goal_autopilot` - passed.
- `flutter analyze` - passed.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `npm run check:api-contract` - passed; generated Dart hash remains `0918bcf90cbc08198be7273e07fd18aa0471e06ba32f9cee21185105814780b2`.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 96.1%, backend branch 80.9% and Flutter line 90.3%.

Passing tests:
- TC-P02-FUD-003: disabled projection renders `Goal autopilot unavailable`, hides Set a goal / Explore / Start autopilot / Generate plan / Done / Checkpoint / reminder controls, sends no mutation requests and forwards the backend unavailable projection to Home cache replacement without source refs.
- TC-P02-FUD-003: runtime-disabled backend failure does not fall back to `No active goal`; it renders the kill-switch unavailable state and preserves no-local-fallback behavior.
- TC-P02-FUD-003: ready Home/Queue/Wiki projection copy is replaced by unavailable state and old action, gap and checkpoint copy are removed.
- TC-P02-FUD-004: source-of-truth script confirms adapter runtime gate usage, panel unavailable branch, Home cache replacement, safe unavailable projection fields and absence of local target/ETA/quota/release inference in surfaces.

Failing tests:
- None in the scoped S002 command set.

Skipped or external tests:
- Backend runtime gate tests were not rerun in this S002-only Flutter slice; S001 backend/API evidence remains recorded under `P02-FOLLOWUP-D-S001-RUNTIME-GATE-20260606`.
- No live commercial entitlement, quota, paid AI provider, store, release or Product Base merge evidence was executed.

Acceptance criteria coverage:
- AC-P02-FUD-002 is locally covered by TC-P02-FUD-003 and TC-P02-FUD-004 for Flutter disabled/unavailable entry rollback, safe surface downgrade, cached projection replacement and frontend source-of-truth guard.

Residual risk:
- S003-S011 remain open for entitlement, usage/quota, cost telemetry, quota downgrade, data governance, consent UX, telemetry, drift gates and final release/Product Base review.
- S002 proves local Flutter rollback behavior only; it is not commercial release approval, paid AI external evidence or Product Base merge approval.

## 2026-06-06 P02 Followup-D S001 Backend Runtime Gate

Report ID:
- `P02-FOLLOWUP-D-S001-RUNTIME-GATE-20260606`

Test scope:
- TC-P02-FUD-001 backend runtime-gate integration coverage for disabled feature flag, kill switch, fail-closed mutations, read/projection downgrade and audit reason persistence.
- TC-P02-FUD-002 API contract coverage for typed `503 GOAL_AUTOPILOT_RUNTIME_DISABLED` responses on gated endpoints and disabled/kill-switch projection behavior.
- Regression coverage that S001 changes do not break existing goal-autopilot controller paths or P0.2 changed-code coverage gates.

Commands run:
- `python3 scripts/project_agent_runner.py validate` - passed before implementation routing.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotRuntimeGateTest test` - passed after correcting audit persistence to use a new transaction.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,GoalAutopilotRuntimeGateTest test` - passed.
- `npm run check:api-contract` - passed with 87 paths, 93 operations, 42 request examples, 88 success examples and 112 error examples; generated Dart OpenAPI hash synced to `0918bcf90cbc08198be7273e07fd18aa0471e06ba32f9cee21185105814780b2`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,GoalAutopilotRuntimeGateTest,GoalProgressProjectionDataGovernanceTest,GoalProgressProjectionServiceTest,ProgressForecastPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControlPerformanceTest,NotificationOutboxReplayTest,MissedDayRecoveryPlannerTest,GoalAutopilotReplayFixtureTest,NotificationEligibilityPolicyTest,MemoryCurveReplayTest,MasteryTransitionPolicyTest,GoalProgressProjectionPerformanceTest,ForecastExplanationSchemaTest,CheckpointReplayAuditTest,GoalAutopilotRecoveryControllerTest,MemoryCurvePolicyTest,NotificationOutboxServiceTest org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed and refreshed backend coverage.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with `P0.2 coverage: backend line=96.1% branch=80.9%; flutter line=90.1%`.
- `python3 scripts/project_agent_runner.py validate` - passed after report synchronization.
- `git diff --check -- backend/src/main/java/com/speakeasy/goal/GoalAutopilotRuntimeGate.java backend/src/main/java/com/speakeasy/goal/GoalAutopilotService.java backend/src/main/resources/application.yml backend/src/test/java/com/speakeasy/goal/GoalAutopilotRuntimeGateTest.java docs/architecture/openapi/speakeasy-api.yaml docs/architecture/openapi/dart-client-drift-manifest.json lib/generated/api/.openapi-sha256 lib/generated/api/speakeasy_api.dart` - passed before report synchronization.
- `git diff --check` - passed after report synchronization.

Passing tests:
- TC-P02-FUD-001: feature flag disabled blocks goal creation and plan generation before goal/profile/diagnostic/backplan writes, returns typed 503, and records redacted `goal_autopilot_runtime_blocked` audit rows with request id, operation, reason and rule version.
- TC-P02-FUD-001: kill switch active hides existing projection details, returns unavailable projection state, blocks action completion without changing plan item status and persists audit evidence.
- TC-P02-FUD-002: OpenAPI declares runtime-disabled 503 responses for gated goal-autopilot mutation/read endpoints, and `GET /goal-autopilot/progress-projection` documents disabled/kill-switch unavailable states without changing operation count.
- Regression: existing controller tests plus broader goal-autopilot policy/replay/performance tests pass with refreshed JaCoCo coverage above the 80% line and branch thresholds.

Failing or blocked tests:
- Initial `GoalAutopilotRuntimeGateTest` run exposed that audit writes inside blocked mutation transactions rolled back with the API error. `GoalAutopilotRuntimeGate` now writes the audit row through `PROPAGATION_REQUIRES_NEW`; rerun passed.
- No TC-P02-FUD-001 or TC-P02-FUD-002 failure remains.

Skipped tests:
- Flutter widget/source-of-truth rollback tests were not run at S001 close because S001 changed backend/API only; current S002 evidence for TC-P02-FUD-003..004 is recorded above.
- Live AI/provider, entitlement, usage reservation, cost telemetry, quota downgrade, export/retention, consent, telemetry, release checklist and Product Base review tests were not run; those remain S003-S011.

Acceptance criteria coverage:
- AC-P02-FUD-001 is locally covered for backend feature flag, kill switch, fail-closed mutation behavior, safe disabled/kill-switch projection downgrade, audit evidence and rollback-ready configuration.

Residual risk:
- Followup-D is not complete, not release-ready and not Product Base-approved.
- At S001 close, S002 Flutter rollback was still required before end-user surfaces were fully guarded by disabled/kill-switch state; current S002 evidence is recorded above.
- S003-S011 commercial entitlement, quota, cost, data governance, consent, telemetry, drift and final release/Product Base gates remain open.

## 2026-06-06 P02 Followup-D S000 Document Chain

Report ID:
- `P02-FOLLOWUP-D-S000-DOCUMENT-CHAIN-20260606`

Test scope:
- TC-P02-FUD-000 documentation-chain validation for `p0-2-followup-d-release-gate-hardening`.
- Required docs: definition, requirements, spec, acceptance, test_cases and traceability.
- S000-S011 slice routing, FR/Spec/AC/TC mapping, Stage Scope P02-SI-001..013 coverage, Policy Gate P02-PG-001..005 coverage and release/Product Base non-claims.

Commands run:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- docs/product/increments/p0-2-followup-d-release-gate-hardening docs/reports/test_report.md docs/reports/implementation_report.md docs/reports/quality_report.md` - passed.

Passing tests:
- TC-P02-FUD-000 passed for S000 documentation routing.
- AC-P02-FUD-000 has stable TC coverage and quality-report evidence.
- At S000 close, S001-S011 were intentionally left planned with explicit TC-P02-FUD-001..021 routes and no code/test evidence marked complete.

Failing or blocked tests:
- No S000 validation failure remains.
- S001-S011 implementation tests were not executed because S000 is docs-only routing.

Skipped tests:
- Backend, Flutter, OpenAPI/generated-client and AI/provider runtime tests were not run because no production code, API shape, generated client or AI runtime behavior changed in S000.

Acceptance criteria coverage:
- AC-P02-FUD-000 is covered by TC-P02-FUD-000 for required docs, slice routing, Stage Scope/Policy Gate traceability, S001-S011 planned state and dual independent review.

Residual risk:
- Followup-D release/commercial/data/ops implementation remains open for S001-S011.
- Product Base merge, commercial release approval and paid AI external evidence remain unapproved.

## 2026-06-06 P02 Followup-C S007 OpenAPI Nullable Cleanup

Report ID:
- `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`

Test scope:
- Redocly nullable `$ref` warning cleanup for `ProgressForecast.eta_range`.
- Generated Dart OpenAPI hash sync for `docs/architecture/openapi/dart-client-drift-manifest.json`, `lib/generated/api/.openapi-sha256` and `SpeakeasyApiContract.openApiSha256`.
- Followup-C S007 traceability checker regression after adding nullable-cleanup assertions.

Commands run:
- `npm run lint:openapi` - passed with no nullable `$ref` warnings.
- `npm run check:api-contract` - passed with OpenAPI contract gate counts unchanged at 87 paths, 93 operations, 42 request examples, 88 success examples and 112 error examples.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `d8b492b07c98e948caf0b5912744f05fa6dcd4b76f97f0ece04dc9778df7da0f`.
- `flutter analyze` - passed.
- `flutter test test/services/api_client_contract_test.dart` - passed.
- `python3 scripts/check_p0_2_followup_c_traceability.py` - passed with nullable cleanup and generated hash assertions.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with `P0.2 coverage: backend line=96.0% branch=80.9%; flutter line=90.1%`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- OpenAPI 3.0.3 schema cleanup: `eta_range` now uses `type: object`, `nullable: true` and `allOf` around `ProgressForecastEtaRange`, removing the six repeated Redocly example warnings from goal-autopilot forecast-bearing responses.
- Dart drift gate: manifest, generated hash marker and generated API registry all pin `d8b492b07c98e948caf0b5912744f05fa6dcd4b76f97f0ece04dc9778df7da0f`.

Failing or blocked tests:
- No OpenAPI nullable-warning cleanup failure remains.

Skipped tests:
- No backend or Flutter production runtime code changed; this cleanup changes API contract syntax and generated hash pins only.
- Followup-D release/commercial/data/ops gates were not executed and remain outside this cleanup.

Acceptance criteria coverage:
- AC-P02-FUC-007 remains locally covered through TC-P02-FUC-022 report/contract hygiene, with S007 checker regression passed after nullable cleanup.

Residual risk:
- Followup-C is locally complete for S001-S007. Followup-C is not release-ready and Product Base merge is not approved.
- Product Base merge and release readiness still require Followup-D and Product Manager approval.

## 2026-06-06 P02 Followup-C S007 Quality Gates

Report ID:
- `P02-FOLLOWUP-C-S007-QUALITY-GATES-20260606`

Test scope:
- TC-P02-FUC-020 p95 performance budgets for forecast recompute, checkpoint task lookup, checkpoint submit accepted/queued, backend projection load and surface propagation through Flutter adapter/widget path.
- TC-P02-FUC-021 dedicated Followup-C traceability checker and changed-code coverage gate.
- TC-P02-FUC-022 project agent runner validation, diff hygiene, report evidence and final independent review.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionPerformanceTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_progress_surface_performance_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed and refreshed `backend/target/site/jacoco/jacoco.csv`.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed and refreshed `coverage/lcov.info`.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with `P0.2 coverage: backend line=96.0% branch=80.9%; flutter line=90.1%`.
- `python3 scripts/check_p0_2_followup_c_traceability.py` - passed after S007 report evidence was synchronized.
- `flutter analyze` - passed.
- `npm run check:dart-client-drift` - passed with unchanged OpenAPI hash `bed8ebbbe2d9fed907b7411fca512912f1302fbb73427e7783b4f7ae2d0678f8`.
- `npm run check:api-contract` - passed. Historical note: Redocly reported six nullable `$ref` warnings at S007 close; this was later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed after final report and traceability edits.

Passing tests:
- TC-P02-FUC-020: `GoalProgressProjectionPerformanceTest` proves forecast recompute p95 <=1s, checkpoint task lookup p95 <=300ms, checkpoint submit accepted/queued p95 <=2s and backend projection load p95 <=500ms. `goal_progress_surface_performance_test.dart` proves Flutter projection adapter plus Home/Queue/Wiki widget propagation p95 <=1s.
- TC-P02-FUC-021: `scripts/check_p0_2_followup_c_traceability.py` validates S007 TC rows, traceability closure, report terms and forbidden release/Product Base claims; `scripts/check_p0_2_goal_autopilot_coverage.py` validates changed-code coverage >=80%.
- TC-P02-FUC-022: project agent runner validation, diff hygiene and quality report review evidence are present.

Failing or blocked tests:
- No TC-P02-FUC-020..022 failure remains.

Skipped tests:
- No production backend, Flutter or API code changed in S007; API/OpenAPI drift checks were run as supplemental guards and passed with the unchanged generated-client hash.
- No live AI provider path was executed; S007 validates deterministic local gates and does not create paid AI/provider evidence.
- Followup-D release/commercial/data/ops gates were not executed and remain outside S007.

Acceptance criteria coverage:
- AC-P02-FUC-007 is executed locally for AC-to-TC closure, performance budgets, changed-code coverage, dedicated traceability checker and report/independent review evidence.

Residual risk:
- Followup-C is locally complete for S001-S007. Followup-C is not release-ready and Product Base merge is not approved.
- Followup-D commercial/release/data/ops gates and Product Manager approval remain required before any release-readiness or Product Base merge claim.

## 2026-06-06 P02 Followup-C S006 Surface Downgrade

Report ID:
- `P02-FOLLOWUP-C-S006-SURFACE-DOWNGRADE-20260606`

Test scope:
- TC-P02-FUC-017 backend data-governance validation for no active goal, missing forecast, unsupported goal, stale plan, paused/control-blocked projection and eligible partial/low-confidence downgrade reasons.
- TC-P02-FUC-018 Flutter widget validation for Home, expression queue and personal Wiki downgrade rendering, cached stale projection replacement and no precise ETA/completion/sensitive target copy.
- TC-P02-FUC-019 account deletion validation that goal progress projection facts are purged and old tokens cannot continue reading deleted goal progress.

Commands run:
- `flutter test test/features/goal_autopilot/goal_progress_downgrade_widget_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionDataGovernanceTest test` - passed after correcting forecast fixture cleanup to inject `GoalProgressForecastRepository` directly, scope deletion to the current user and run the derived delete inside a transaction.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AccountDeletionLearningDataTest#tcP02Fuc006GoalProgressProjectionPurgedOnDeletion test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionDataGovernanceTest,AccountDeletionLearningDataTest#tcP02Fuc006GoalProgressProjectionPurgedOnDeletion test` - passed.
- `flutter test test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionServiceTest,GoalAutopilotControllerTest#tcP02Fuc004ProjectionIsBackendOwned,GoalProgressProjectionDataGovernanceTest,AccountDeletionLearningDataTest#tcP02Fuc006GoalProgressProjectionPurgedOnDeletion test` - passed.
- `flutter analyze` - passed.
- `npm run check:dart-client-drift` - passed; OpenAPI hash remains `bed8ebbbe2d9fed907b7411fca512912f1302fbb73427e7783b4f7ae2d0678f8`.
- `npm run check:api-contract` - passed. Historical note: Redocly reported six nullable `$ref` warnings at S006 close; this was later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUC-017: backend projection returns ineligible fragments with empty refs/safe fields for unavailable, unsupported, stale and control-blocked states, and keeps partial/low-confidence downgrade reasons traceable without precise ETA or completion claims.
- TC-P02-FUC-018: Home/Queue/Wiki downgrade widgets replace previously rendered ready progress with backend downgrade state, remove old gap/action/checkpoint copy when ineligible and avoid target/ETA/official/guaranteed/goal-achieved copy.
- TC-P02-FUC-019: account deletion removes goal profile/control/diagnostic/backplan/daily plan/forecast/checkpoint/replay-audit rows for the deleted user and old projection reads fail with `UNAUTHENTICATED`.

Failing or blocked tests:
- No TC-P02-FUC-017..019 failure remains after the repository access, user-scoped fixture cleanup and transaction corrections.
- TC-P02-FUC-020 through TC-P02-FUC-022 remain planned for S007 and were not executed as completed evidence in this S006 slice.

Skipped tests:
- No live AI provider path was executed; S006 downgrade state, surface eligibility and copy are deterministic backend/Flutter behavior.
- No p95 performance or final coverage gate was run; those remain S007.

Acceptance criteria coverage:
- AC-P02-FUC-006 is executed locally for deleted/unavailable/unsupported/stale/control-blocked/partial/low-confidence projection downgrade, backend-provided reason traceability, sensitive progress removal and cached stale Flutter surface cleanup.

Residual risk:
- Followup-C is not complete, not release-ready and not Product Base-ready.
- S007 p95 performance, changed-code coverage gate, dedicated traceability script and final independent review remain open.
- S006 did not change OpenAPI shape; future API changes still require OpenAPI/generated client drift gates.

## 2026-06-06 P02 Followup-C S005 Surface Propagation

Report ID:
- `P02-FOLLOWUP-C-S005-SURFACE-PROPAGATION-20260606`

Test scope:
- TC-P02-FUC-013 Home surface widget validation: Home goal summary loads `GET /goal-autopilot/progress-projection`, renders backend-owned home safe fields and suppresses legacy/local target-score/ETA style output.
- TC-P02-FUC-014 Queue surface widget validation: expression queue renders queue fragment safe fields without local queue priority/reordering.
- TC-P02-FUC-015 Wiki surface widget validation: personal Wiki renders wiki fragment safe fields and omits next action where the fragment does not allow it.
- TC-P02-FUC-016 source-of-truth validation: adapter path, Home/Queue/Wiki code references, optional projection failure handling and surface widget source scan block local ETA, goal-complete and sensitive target detail rendering.

Commands run:
- `flutter test test/features/goal_autopilot/goal_progress_home_surface_test.dart test/features/goal_autopilot/goal_progress_queue_surface_test.dart test/features/goal_autopilot/goal_progress_wiki_surface_test.dart test/features/goal_autopilot/goal_progress_surface_source_of_truth_test.dart` - passed after two implementation corrections: projection body text now uses findable `Text.rich`, and the autopilot panel has a bounded scroll fallback for standalone widget tests.
- `flutter test test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `flutter test test/services/api_client_contract_test.dart` - passed.
- `flutter analyze` - passed.
- `npm run check:dart-client-drift` - passed; OpenAPI hash remains `bed8ebbbe2d9fed907b7411fca512912f1302fbb73427e7783b4f7ae2d0678f8`.
- `npm run check:api-contract` - passed. Historical note: Redocly reported six nullable `$ref` warnings at S005 close; this was later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUC-013: Home panel requests the projection endpoint, renders Home next action/gap/risk/checkpoint fields from the projection and does not expose target ability, official score, guaranteed outcome or ETA copy.
- TC-P02-FUC-014: Queue surface renders the queue fragment next action/risk/checkpoint summary and does not render gap, queue priority, target score, target ability, official score, guaranteed outcome or ETA copy.
- TC-P02-FUC-015: Wiki surface renders wiki gap/risk/next checkpoint/checkpoint summary and does not render next action, target score, target ability, official score, guaranteed outcome or ETA copy.
- TC-P02-FUC-016: source-of-truth test verifies `GoalAutopilotAdapter.loadProgressProjection()` uses `SpeakeasyApiPaths.goalAutopilotProgressProjection`, Home/Queue/Wiki consume the projection surface widgets, the queue coordinator does not depend on `GoalProgressProjection`, `goal_progress_surface.dart` does not reference target score, target ability, ETA or goal-completion fields, and optional projection fallback only treats legacy missing projection payloads as optional while preserving real API failures.

Failing or blocked tests:
- No TC-P02-FUC-013..016 failure remains after the widget text and bounded-scroll corrections.
- TC-P02-FUC-017 through TC-P02-FUC-022 remain planned for S006/S007 and were not executed as completed evidence in this S005 slice.

Skipped tests:
- No backend service tests were added because S005 consumes the S004 projection endpoint without changing backend/OpenAPI shape.
- No live AI provider path was executed; S005 surface copy renders deterministic projection facts only.
- No p95 performance or final coverage gate was run; those remain S007.

Acceptance criteria coverage:
- AC-P02-FUC-005 is executed locally for all three product surfaces consuming backend projection fragments, no local final-state recomputation, no queue reprioritization from UI projection data and safe product-internal copy.

Residual risk:
- Followup-C is not complete, not release-ready and not Product Base-ready.
- S006 deletion/unavailable/unsupported/low-confidence downgrade across surfaces and S007 performance/coverage/final traceability remain open.
- S005 does not prove cached stale projection cleanup after account deletion; that remains S006.

## 2026-06-06 P02 Followup-C S004 Progress Projection

Report ID:
- `P02-FOLLOWUP-C-S004-PROGRESS-PROJECTION-20260606`

Test scope:
- TC-P02-FUC-010 service/integration validation for backend-owned `GoalProgressProjection`, safe surface fragments, source refs, no-active-goal unavailable downgrade and redaction of raw transcript/audio, sensitive target details and provider payloads.
- TC-P02-FUC-011 controller validation for `GET /goal-autopilot/progress-projection`, safe JSON response shape, source-owned next action/forecast/checkpoint fields and no local summary/diagnostic leakage.
- TC-P02-FUC-012 API/OpenAPI/generated Dart drift validation for the S004 projection endpoint, schemas, examples, generated path registry and hash marker.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionServiceTest,GoalAutopilotControllerTest#tcP02Fuc004ProjectionIsBackendOwned test` - failed once because the new assertion expected checkpoint risk code after replan; existing forecast policy correctly returned `forecast_supported`. The assertion was corrected to check checkpoint conclusion through `latest_checkpoint.reason_code`, then rerun passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionServiceTest,GoalAutopilotControllerTest#tcP02Fuc004ProjectionIsBackendOwned test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionServiceTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc004ProjectionIsBackendOwned test` - passed.
- `npm run check:api-contract` - passed. Historical note: Redocly reported six nullable `$ref` example warnings, later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`; OpenAPI validation, OpenAPI contract and Dart drift gates passed with SHA `bed8ebbbe2d9fed907b7411fca512912f1302fbb73427e7783b4f7ae2d0678f8`.
- `npm run check:dart-client-drift` - passed with the same OpenAPI SHA.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-P02-FUC-010: `GoalProgressProjectionServiceTest` verifies ready projection aggregation across goal, control, next action, forecast and latest checkpoint; verifies no-active-goal returns `unavailable/no_active_goal`; verifies surface fragments and source refs are safe and do not include raw diagnostic/checkpoint text, sensitive target details or provider payloads.
- TC-P02-FUC-011: `GoalAutopilotControllerTest#tcP02Fuc004ProjectionIsBackendOwned` verifies `GET /goal-autopilot/progress-projection` returns server-owned goal, next action, forecast, checkpoint and surface fragments, with no `target_score`, `target_ability`, diagnostic, transcript, audio ref, weekly backplan or daily plan leakage.
- TC-P02-FUC-012: OpenAPI includes `/goal-autopilot/progress-projection`, `GoalProgressProjectionResponse` schemas and example; generated Dart path registry includes `goalAutopilotProgressProjection`; manifest and marker hash are synchronized.

Failing or blocked tests:
- No TC-P02-FUC-010/011/012 failure remains after the assertion correction.
- TC-P02-FUC-013 through TC-P02-FUC-022 remain planned for S005-S007 and were not executed as completed evidence in this S004 slice.

Skipped tests:
- No Flutter widget tests were run because S004 changed backend/API contracts and generated path metadata only; Home/Queue/Wiki rendering remains S005.
- No live AI provider path was executed; S004 projection state, surface eligibility and downgrade reason are deterministic backend policy.
- No p95 performance or final coverage gate was run; those remain S007.

Acceptance criteria coverage:
- AC-P02-FUC-004 is executed locally for backend-owned aggregation, source-owned next action/gap/risk/checkpoint fields, safe surface fragments, redaction and unavailable downgrade.

Residual risk:
- Followup-C is not complete, not release-ready and not Product Base-ready.
- S005 Home/Queue/Wiki surface propagation, S006 deletion/unavailable downgrade across surfaces and S007 performance/final traceability remain open.
- S004 establishes the backend projection contract; Flutter surfaces still need to be migrated to consume it before P02-SI-006 is fully landed.

## 2026-06-05 P02 Followup-C S003 Checkpoint Plan Update

Report ID:
- `P02-FOLLOWUP-C-S003-CHECKPOINT-PLAN-UPDATE-20260605`

Test scope:
- TC-P02-FUC-007 backend integration validation for accepted checkpoint result, forecast recompute, plan stale/replan signal fields and no precise ETA or goal-complete claim under stale-plan output.
- TC-P02-FUC-008 replay/audit validation for checkpoint-to-plan `PlannerReplayAudit` evidence, source checkpoint id, rule version, input/output/replay hashes and raw transcript/audio minimization.
- TC-P02-FUC-009 backend integration validation for paused rejection, recovery-required compatibility, invalid result status rejection, failed/skipped checkpoint handling and control-blocked/no-plan behavior.
- Contract/regression scope: S003 domain/API/OpenAPI/generated Dart drift, deterministic AI/UX source-of-truth boundaries and changed-code coverage.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc003CheckpointUpdatesForecastAndPlanSignal test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CheckpointReplayAuditTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc003CheckpointRespectsControlAndRecoveryState test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc003CheckpointFailedSkippedAndBlockedBranches test` - failed once because the no-plan accepted-checkpoint fixture transcript was too short and correctly produced `low_confidence`; fixture was expanded to accepted-confidence evidence, then rerun passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,CheckpointReplayAuditTest test` - passed.
- `npm run check:api-contract` - passed. Historical note: Redocly reported six nullable `$ref` example warnings, later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`; OpenAPI validation, OpenAPI contract and Dart drift gates passed with SHA `226c6d86a691489c8c3cfeba8aa0735aae52aef12ce7d5d561cb46a56ce52860`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,CheckpointReplayAuditTest org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- Backend changed source coverage from JaCoCo diff check: line 98.4% and branch 92.0% for changed `GoalAutopilotService` and `GoalAutopilotController` source lines.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUC-007: accepted-confidence checkpoint persists `recorded`, returns checkpoint reason `checkpoint_updated_gap`, emits `checkpoint_replan`, marks plans stale, recomputes forecast to conservative `stale_plan` output and writes one `checkpoint_plan_update` replay audit.
- TC-P02-FUC-008: checkpoint plan signal returns source checkpoint id, `fuc-checkpoint-plan-v1`, input snapshot hash and replay audit id; replay-audit API exposes matching source ref, input/output/replay hashes, expected decision and reason without raw transcript text.
- TC-P02-FUC-009: paused autopilot rejects checkpoint submit without checkpoint persistence; recovery-required plan returns `recovery_replan`; failed/skipped/low-confidence checkpoints return no completion claim; invalid `result_status` is rejected; missing-plan accepted checkpoint returns `stale_plan/control_blocked` instead of silently advancing next action.
- Contract drift: `POST /goal-autopilot/checkpoints` request/response schemas, `OutcomeCheckpoint`, `PlanUpdateSignal` replay metadata and generated Dart hash are synchronized.

Failing or blocked tests:
- No TC-P02-FUC-007/008/009 failure remains after the fixture correction.
- TC-P02-FUC-010 through TC-P02-FUC-022 remain planned for S004-S007 and were not executed as completed evidence in this S003 slice.

Skipped tests:
- No Flutter widget tests were run because S003 changed backend/API contracts and generated path metadata only; Home/Queue/Wiki projection and surfaces remain S004/S005.
- No live AI provider path was executed; S003 checkpoint-to-plan status, signal and replay evidence are deterministic backend policy.

Acceptance criteria coverage:
- AC-P02-FUC-003 is executed locally for checkpoint result persistence, forecast update, stale/replan/control-blocked signal, replay/audit reference, no raw transcript/audio leakage, no false completion and paused/recovery compatibility.

Residual risk:
- Followup-C is not complete, not release-ready and not Product Base-ready.
- S004 backend-owned projection, S005 Home/Queue/Wiki surface propagation, S006 downgrade/deletion handling and S007 performance/final traceability remain open.
- The broad project coverage script still depends on unchanged Flutter coverage and final Followup-C S007 gates; S003 evidence uses changed-backend-source JaCoCo coverage because no Flutter source changed.

## 2026-06-05 P02 Followup-C S002 Checkpoint Task Library

Report ID:
- `P02-FOLLOWUP-C-S002-CHECKPOINT-TASK-LIBRARY-20260605`

Test scope:
- TC-P02-FUC-004 backend unit validation for deterministic `CheckpointCadencePolicy`, including weekly due, biweekly not-due from checkpoint history, overdue, partial limited, unsupported unavailable, cost fallback and input validation.
- TC-P02-FUC-005 backend API/integration validation for `GET /goal-autopilot/checkpoints/task`, including supported not-due/due decisions, partial limited task, unsupported no-full-task fallback and omitted `task` field when no task is available.
- TC-P02-FUC-006 API/OpenAPI/generated Dart drift validation for the new checkpoint task endpoint and path registry.
- Regression scope: S001 forecast policy/schema/controller slice and existing checkpoint-to-plan regression around stale-plan forecast suppression.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CheckpointCadencePolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc002CheckpointTaskLibrary test` - passed.
- `npm run check:api-contract` - passed. Historical note: Redocly reported six nullable `$ref` example warnings, later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`; OpenAPI validation, OpenAPI contract and Dart drift gates passed with SHA `3bacdd487b700676793dd2a2c4629d330079cf34dbf2f1e35f9ed46f8f166351`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CheckpointCadencePolicyTest,ProgressForecastPolicyTest,ForecastExplanationSchemaTest,GoalAutopilotControllerTest#tcP02Fuc001ForecastHardeningClaimGuard+tcP02Fuc002CheckpointTaskLibrary+tcP02AutoCheckpoint001CheckpointUpdatesForecastAndStalesPlan test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 95.7%, backend branch 80.8%, Flutter line 90.9%.
- `flutter analyze lib/generated/api/speakeasy_api.dart` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUC-004: `CheckpointCadencePolicyTest` verifies due-now/overdue/not-due decisions, weekly/biweekly cadence, task type selection, prompt refs, duration, required evidence, product-internal scoring boundary and deterministic-low-cost fallback.
- TC-P02-FUC-005: `GoalAutopilotControllerTest#tcP02Fuc002CheckpointTaskLibrary` verifies the API returns server-owned checkpoint task decisions and omits the `task` field for not-due and unsupported no-full-task responses.
- TC-P02-FUC-006: OpenAPI and generated Dart path registry include `GET /goal-autopilot/checkpoints/task` with synchronized drift hash.
- Regression: S001 forecast hardening tests, generated Dart analysis, broad P0.2 coverage gate and the existing checkpoint-to-plan stale-plan assertion still pass.

Failing or blocked tests:
- No TC-P02-FUC-004/005/006 failure remains.
- TC-P02-FUC-007 through TC-P02-FUC-022 remain planned for S003-S007 and were not executed in this S002 slice.

Skipped tests:
- No Flutter widget tests were run because S002 changes backend/API contracts only and no Flutter surface was changed beyond generated path registry.
- No live AI provider path was executed; S002 checkpoint task selection is deterministic backend policy and AI/provider task selection is explicitly N/A.

Acceptance criteria coverage:
- AC-P02-FUC-002 is executed locally for checkpoint cadence due/not-due/overdue behavior, goal-type task matching, partial/unsupported limitation, product-internal rubric boundary and cost fallback without entitlement fact creation.

Residual risk:
- Followup-C is not complete, not release-ready and not Product Base-ready.
- S003 checkpoint-to-plan update, S004 backend-owned projection, S005 Home/Queue/Wiki surface propagation, S006 downgrade/deletion handling and S007 performance/coverage/final traceability remain open.
- S002 defines a deterministic task library in code; if task content later moves to CMS/content configuration, TC-P02-FUC-004..006 must rerun against that source.

## 2026-06-05 P02 Followup-C S001 Forecast Hardening

Report ID:
- `P02-FOLLOWUP-C-S001-FORECAST-HARDENING-20260605`

Test scope:
- TC-P02-FUC-001 backend unit validation for deterministic `ProgressForecastPolicy`, including supported forecast, ETA range, claim guard, confidence/risk, limited states and input validation.
- TC-P02-FUC-001 independent review follow-up for stale-plan precedence over checkpoint/completed event reasons, proving stale forecasts return no ETA and no completion claim.
- TC-P02-FUC-002 backend API/integration validation for `/goal-autopilot/goals` and `GET /goal-autopilot/forecast`, including new ProgressForecast fields, persisted migration shape and closed outcome-claim guard.
- TC-P02-FUC-003 AI fallback/schema validation for forecast explanation candidate-only behavior, deterministic no-provider fallback metadata and forbidden completion/ETA/entitlement/provider field rejection.
- Contract/regression scope: OpenAPI/generated Dart drift, full `GoalAutopilotControllerTest` regression, generated API analysis and project runner validation.

Commands run:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProgressForecastPolicyTest,ForecastExplanationSchemaTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc001ForecastHardeningClaimGuard test` - failed once because H2 rejected the first multi-column forecast migration syntax; migration was split into one `ALTER TABLE ... ADD COLUMN` statement per column.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc001ForecastHardeningClaimGuard test` - passed after migration fix.
- `npm run check:api-contract` - passed. Historical note: Redocly reported nullable-example warnings, later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`; OpenAPI validation and downstream drift gates passed with SHA `617ce817ef055efb851641a1664211238229d9ed365e01711244da15a75c621c`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProgressForecastPolicyTest,GoalAutopilotControllerTest#tcP02Fuc001ForecastHardeningClaimGuard,ForecastExplanationSchemaTest test` - passed as formal S001 TC run after stale-plan fix.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - failed once after stale-plan precedence fix because the older checkpoint regression still expected checkpoint reason copy under stale plan; the assertion was updated.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed after the regression assertion update.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 95.8%, backend branch 80.6%, Flutter line 90.9%.
- `flutter analyze lib/generated/api/speakeasy_api.dart` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUC-001: `ProgressForecastPolicyTest` verifies supported forecasts expose source goal revision, forecast state, ETA range, ETA unavailable reason, confidence band, risk reason code, deterministic explanation metadata, rule version and closed claim guard.
- TC-P02-FUC-001: partial goal, unsupported goal, low confidence, stale plan, recovery required, deleted and unavailable states return limited/unavailable forecast states without precise ETA claims; checkpoint/completed events cannot override `stale_plan`.
- TC-P02-FUC-002: `GoalAutopilotControllerTest#tcP02Fuc001ForecastHardeningClaimGuard` verifies API projections expose the hardened fields in both goal list and forecast detail responses after persistence migration.
- TC-P02-FUC-003: `ForecastExplanationSchemaTest` accepts safe candidate-only explanations and rejects provider attempts to set persistent fields or unsafe official/completion/guaranteed outcome claims.
- Regression: full `GoalAutopilotControllerTest`, OpenAPI contract/drift and generated Dart API analysis pass.

Failing or blocked tests:
- No TC-P02-FUC-001/002/003 failure remains after the migration syntax fix and stale-plan regression assertion update.
- Full `GoalAutopilotControllerTest` failed once during independent review because the previous checkpoint regression expected checkpoint reason copy under stale plan; it now expects `stale_plan`, no ETA and closed claim guard, and the rerun passed.
- TC-P02-FUC-004 through TC-P02-FUC-022 remain planned for S002-S007 and were not executed in this S001 slice.

Skipped tests:
- Followup-C performance, dedicated Followup-C traceability script, surface widget/integration and release gates are intentionally deferred to S005-S007; the broad P0.2 coverage script was executed and passed for this revalidation.
- No live AI provider path was executed; S001 validates deterministic no-provider fallback and candidate-only schema guardrails.

Acceptance criteria coverage:
- AC-P02-FUC-001 is executed locally for forecast state/risk/ETA range exposure, downgrade safety, deterministic explanation fallback, no official-score/guaranteed-outcome claim and API contract drift.

Residual risk:
- Followup-C is not complete, not release-ready and not Product Base-ready.
- S002 checkpoint cadence/task library, S003 checkpoint-to-plan update, S004 backend projection, S005 Home/Queue/Wiki surface propagation, S006 downgrade/deletion handling and S007 performance/coverage/final traceability remain open.
- The S001 AI runtime path is deterministic fallback only; future live/provider explanation support must keep the candidate-only boundary and rerun TC-P02-FUC-003.

## 2026-06-05 P02 Followup-B S006 Replay Performance Traceability

Report ID:
- `P02-FOLLOWUP-B-S006-REPLAY-PERFORMANCE-TRACEABILITY-20260605`

Test scope:
- TC-P02-FUB-015 backend replay fixture validation through `GoalAutopilotReplayFixtureTest`, covering FUB-FIX-001..008 control, pause/resume/update-control, notification eligibility, notification outbox, missed-day recovery, item-level memory and mastery transition replay evidence.
- TC-P02-FUB-016 backend p95 performance validation through `GoalAutopilotControlPerformanceTest`, covering FUB-FIX-009 budgets for control load, control commands, notification eligibility, outbox lifecycle, recovery, memory, mastery and replay verification.
- TC-P02-FUB-017 traceability and coverage validation through `python3 scripts/check_p0_2_followup_b_traceability.py` and `python3 scripts/check_p0_2_goal_autopilot_coverage.py`.
- Coverage support: added backend test-only branch coverage cases for existing `MemoryCurvePolicy`, `MissedDayRecoveryPlanner`, `MasteryTransitionPolicy` and `MasteryTransitionExplanationValidator` branches so the current broad P0.2 coverage gate reflects the current codebase.

Commands run:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `npm run check:api-contract` - passed.
- `git diff --check` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotReplayFixtureTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControlPerformanceTest test` - passed.
- `python3 -m py_compile scripts/check_p0_2_followup_b_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_b_traceability.py` - failed before report synchronization because TC-P02-FUB-015 still lacked `passed` evidence in `test_cases.md`; this was the expected Step 4/6 gap.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest,MissedDayRecoveryPlannerTest,MasteryTransitionPolicyTest test` - passed after test-only coverage additions.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 95.9%, backend branch 81.4%, Flutter line 90.9%.

Passing tests:
- TC-P02-FUB-015: `GoalAutopilotReplayFixtureTest` verifies Followup-B replay fixture coverage across control source, control commands, notification eligibility, outbox replay, recovery replay, item-policy replay and mastery transition replay. Assertions include expected decision, reason code, output state, rule version and hash evidence where replay audits exist.
- TC-P02-FUB-016: `GoalAutopilotControlPerformanceTest` keeps local p95 budgets within the planned thresholds: control load <=200 ms, control command <=500 ms, notification eligibility <=200 ms, outbox lifecycle <=300 ms, recovery <=500 ms, 500-item memory due calculation <=300 ms, mastery transition <=300 ms and replay verification <=500 ms.
- TC-P02-FUB-017: `scripts/check_p0_2_followup_b_traceability.py` exists and validates TC rows, traceability rows, report terms, required files and forbidden release/Product Base claims; coverage gate passes with backend branch >=80%.

Failing or blocked tests:
- No TC-P02-FUB-015/016/017 failure remains after S006 report synchronization and coverage test additions.
- Release approval, Product Base merge, Followup-C and Followup-D remain outside S006 and are not claimed.

Acceptance criteria coverage:
- AC-P02-FUB-008 is executed for replay fixture coverage, p95 performance budgets, changed-code coverage gate and final traceability script.
- TC-P02-FUB-001 through TC-P02-FUB-017 now have local passed evidence.

Residual risk:
- Followup-B is not release-ready.
- Product Base merge is not approved.
- No production backend or Flutter code changed in the S006 coverage-support follow-up; the added tests cover existing policy branches and local release-check gates only.

## 2026-06-05 P02 Followup-B S005 Mastery Transition

Test scope:
- TC-P02-FUB-013 backend unit validation for `MasteryTransitionPolicy` promotion threshold, one-level cap, hold conditions, demotion conditions and rule version.
- TC-P02-FUB-014 backend AI guardrail validation for candidate-only explanation parsing, forbidden persistent-field rejection, official-score/goal-completion claim blocking and safe deterministic fallback.
- Integration regression: `GET /goal-autopilot/mastery-transitions`, `mastery_transition` replay audit, governance export, migration and account-deletion cleanup.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest test` - failed first because S005 policy and AI validator classes did not exist; this was the expected red test.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed after S005 governance expectation sync.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,AccountDeletionLearningDataTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest,GoalAutopilotControllerTest test` - passed after independent review fixed non-deterministic replay output hash and added duplicate-input idempotency assertions.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest,GoalAutopilotControllerTest,FoundationMigrationTest,AccountDeletionLearningDataTest test` - passed.
- `npm run check:api-contract` - passed.
- `npm run check:dart-client-drift` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUB-013: promotion advances at most one L0-L5 level even when the candidate target is higher than one step, and records evidence refs plus `fub-mastery-v1`.
- TC-P02-FUB-013: low confidence, insufficient evidence, partial goal, unsupported goal, fatigue protection and contradictory evidence hold at the previous level.
- TC-P02-FUB-013: repeated retrieval failure and checkpoint regression produce deterministic one-level demotion when confidence is sufficient.
- TC-P02-FUB-013 integration: completing accepted plan evidence writes one read-only `goal_mastery_transition_decisions` row and one `mastery_transition` replay audit; repeating the same input does not duplicate transition or replay rows.
- TC-P02-FUB-014: AI candidate explanations containing final mastery, review due date, notification schedule, goal completion, official score or guardrail violations are rejected and do not mutate persistent state.
- TC-P02-FUB-014: a safe candidate-only explanation that echoes the deterministic decision is accepted as explanation text only and still does not mutate persistent state.
- Regression: governance export reports S005 mastery retention/deletion metadata; account deletion purges mastery transition decisions and related replay audits.

Failing or blocked tests:
- No TC-P02-FUB-013/014 failure remains.
- TC-P02-FUB-015..017 were later executed in the S006 section above.

Acceptance criteria coverage:
- AC-P02-FUB-007 is executed for evidence-driven L0-L5 transition decisions, one-level promotion cap, hold/demotion behavior, transition audit metadata, AI forbidden persistent-field rejection and no official-score claim.
- AC-P02-FUB-008 is covered by the later S006 section above for broader Followup-B global replay/performance/final traceability gates.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- At S005 close, global replay fixture corpus, p95 performance budgets, coverage/final traceability script and final independent QA remained open; S006 evidence above supersedes that local implementation gap while release/Product Base approval remains separate.
- No Flutter UI changed in this slice; Flutter layer is N/A for TC-P02-FUB-013/014.

## 2026-06-05 P02 Followup-B S004 Item-Level MemoryCurvePolicy

Test scope:
- TC-P02-FUB-011 backend unit validation for `MemoryCurvePolicy` item-level decisions, forgetting-risk thresholds, retrieval success/failure, default intervals, overlearning cap, interleaving cap, daily budget defer and paused/control-blocked decisions.
- TC-P02-FUB-012 backend integration validation for `POST /goal-autopilot/item-policy/decisions`, deterministic response decisions, `item_policy` replay audit hashes and paused-control blocking through server-owned control state.
- Regression scope: existing `GoalAutopilotControllerTest`, S003 `GoalAutopilotRecoveryControllerTest`, OpenAPI/generated Dart drift and API contract gates.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest,MemoryCurveReplayTest test` - failed once because `next_due_at` used sub-day `Instant.now`, causing replay output hash drift; fixed by using day-level policy evaluation time in the input snapshot.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest,MemoryCurveReplayTest test` - passed.
- `npm run check:api-contract` - passed after adding optional `MemoryItemPolicyInput` to the existing item-policy endpoint schema and syncing generated Dart hash artifacts.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest,MemoryCurveReplayTest,GoalAutopilotControllerTest,GoalAutopilotRecoveryControllerTest test` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `git diff --check` - passed.
- Independent review follow-up fixed `review_not_due.next_due_at` so it reflects `last_reviewed_at + default interval` instead of resetting the interval from the evaluation day; `MemoryCurvePolicyTest` now asserts this default-interval output.

Passing tests:
- TC-P02-FUB-011: high forgetting risk `>=0.70` returns `review_due` and overrides overlearning cap; due risk `>=0.45` plus retrieval failure returns `retrieval_failure_due`.
- TC-P02-FUB-011: successful retrieval below due threshold remains `review_not_due`; elapsed default intervals for L0/L1/L2/L3/L4/L5 and not-due `next_due_at` are enforced through rule-versioned decisions.
- TC-P02-FUB-011: overlearning cap returns `skip_overlearning_cap`; interleaving cap returns `interleave_alternative` when a viable different group exists; exhausted daily memory budget returns `defer_budget`.
- TC-P02-FUB-011: paused and policy-blocked control states return `blocked_by_control` instead of selecting review work.
- TC-P02-FUB-012: item-policy API returns deterministic memory item decisions and writes `item_policy` replay audit with `sha256:` input/output/replay hashes, expected decision, reason code and `memory-curve-v1`.
- TC-P02-FUB-012: replaying the same item-policy request on the same evaluation day returns identical decisions and identical replay hash; pausing control causes all item decisions to become `blocked_by_control`.

Failing or blocked tests:
- No TC-P02-FUB-011/012 failure remains.
- TC-P02-FUB-013..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-006 is executed for item-level memory state, forgetting risk, retrieval evidence, overlearning cap, interleaving cap, daily budget defer, default constants, paused/control-blocked handling and replay determinism.
- AC-P02-FUB-008 remains planned for broader Followup-B global replay/performance/final traceability gates.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- L0-L5 transition, global replay fixtures, performance budgets, coverage evidence and the dedicated Followup-B traceability script remain open.
- No Flutter UI or AI runtime behavior changed in this slice; those layers are N/A for TC-P02-FUB-011/012.

## 2026-06-05 P02 Followup-B S003 Missed-Day Recovery Planner

Test scope:
- TC-P02-FUB-009 backend unit validation for `MissedDayRecoveryPlanner` mode precedence, balanced tie-breaker, daily budget cap and no-overdue-stacking decisions.
- TC-P02-FUB-010 backend integration validation for `/goal-autopilot/recovery/replan`, durable `RecoveryPlanDecision`, stale/replan plan updates, idempotent replay, bounded recovery daily plan and `missed_day_recovery` replay audit.
- Regression scope: existing `GoalAutopilotControllerTest`, notification eligibility/outbox lifecycle/replay tests, OpenAPI/generated Dart drift, runner validation, diff check and project coverage script.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MissedDayRecoveryPlannerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotRecoveryControllerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide test` - passed after S003 governance status-marker fix.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MissedDayRecoveryPlannerTest,GoalAutopilotRecoveryControllerTest,GoalAutopilotControllerTest,NotificationEligibilityPolicyTest,NotificationOutboxServiceTest,NotificationOutboxReplayTest test` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository jacoco:report` - failed because the project does not configure a resolvable `jacoco` Maven plugin prefix; this is a tooling gap for report refresh, not a failed TC-P02-FUB-009/010 assertion.

Passing tests:
- TC-P02-FUB-009: hard safety and high fatigue force `replace` before user preference.
- TC-P02-FUB-009: `balanced` resolves deterministically to `defer` before `compress` and `replace` when feasible; specific `compress` and `replace` preferences are honored when viable.
- TC-P02-FUB-009: compress recovery stays within daily minutes and affects only the risk-driving item instead of stacking every overdue item.
- TC-P02-FUB-010: recovery replan from a skipped item returns `defer`, one affected lower-priority item ref, `sha256:` input snapshot, `fub-recovery-v1` rule version and `recovery_replan` signal.
- TC-P02-FUB-010: recovery creates a new bounded daily plan with one active recovery block and leaves old daily/backplan rows stale with the recovery reason code.
- TC-P02-FUB-010: replaying the same idempotency key returns the same recovery decision and daily plan without duplicate replacement plans.
- TC-P02-FUB-010: `goal_recovery_plan_decisions` and `goal_planner_replay_audits` record recovery decision and `missed_day_recovery` replay evidence.
- Regression: control data-governance export reports implementation through S003 recovery and includes the recovery decision retention/deletion table.

Failing or blocked tests:
- No TC-P02-FUB-009/010 failure remains.
- TC-P02-FUB-011..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-005 is executed for missed/skipped/deferred recovery planner behavior, compress/defer/replace decision mode, no overdue stacking, stale/replan status and replayable decision evidence.
- AC-P02-FUB-008 remains planned for broader Followup-B global replay/performance/final traceability gates.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- Item-level memory, L0-L5 transition, global replay fixtures, performance budgets and the dedicated Followup-B traceability script remain open.
- No Flutter UI or AI runtime behavior changed in this slice; those layers are N/A for TC-P02-FUB-009/010.

## 2026-06-05 P02 Followup-B S002-B Notification Outbox Lifecycle And Replay

Test scope:
- TC-P02-FUB-007 backend integration validation for `NotificationOutboxService` lifecycle, dedupe, cancel/reschedule, retry/failure recovery, expiry and sent-state redaction.
- TC-P02-FUB-008 backend integration validation for deterministic `notification_outbox` replay audit hashes and projections.
- Regression scope: outbox/replay list API redacted projection, OpenAPI/generated Dart drift, foundation migration, control governance export, account deletion cleanup and prior notification eligibility policy.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationOutboxServiceTest,NotificationOutboxReplayTest test` - red step failed before implementation with missing outbox service, repository and replay audit classes.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationOutboxServiceTest,NotificationOutboxReplayTest,NotificationEligibilityPolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub007OutboxAndReplayApisExposeRedactedProjection test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed after updating stale S002-A governance expectations.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,AccountDeletionLearningDataTest,TrainingAccountDeletionRetentionTest test` - passed.
- `npm run check:api-contract` - failed once on OpenAPI/example/hash drift, then passed after schema/example/hash sync.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `flutter analyze lib/generated/api/speakeasy_api.dart` - passed.

Passing tests:
- TC-P02-FUB-007: outbox records are created with stable dedupe key `user_id + goal_revision + plan_item_id + reminder_slot + rule_version`, duplicate schedule calls do not create another record, and lifecycle transitions cover `pending`, `scheduled`, `blocked`, `cancelled`, `failed`, `expired` and `sent`.
- TC-P02-FUB-007: cancelled reminders can be rescheduled back to `pending`, failed reminders enter `retry_waiting` and can recover to `scheduled`, and sent records retain only hashed provider/message payload projection.
- TC-P02-FUB-008: replay audit rows are written for outbox state changes with `notification_outbox` decision family, `outbox:<id>` source reference, deterministic input/output/replay hashes and expected decisions.
- API regression: `/goal-autopilot/reminders/outbox` and `/goal-autopilot/replay-audits` expose redacted hash projections and do not return raw reminder explanation payload keys.
- Data governance regression: `goal_notification_outbox_records` and `goal_planner_replay_audits` are listed in retention/deletion policy and are purged during account deletion.

Failing or blocked tests:
- No TC-P02-FUB-007/008 failure remains.
- TC-P02-FUB-009..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-004 is executed for notification outbox lifecycle, redacted projection, replay audit and deletion cleanup.
- AC-P02-FUB-008 remains planned for the broader Followup-B replay/performance/coverage completion gate.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- Missed-day recovery, item-level memory, L0-L5 transition, global replay fixtures, performance budgets, coverage evidence and the dedicated Followup-B traceability script remain open.
- External platform notification delivery/release evidence is not claimed by this local outbox lifecycle slice.

## 2026-06-05 P02 Followup-B S002-A Notification Eligibility Policy

Test scope:
- TC-P02-FUB-005 backend unit validation for `NotificationEligibilityPolicy`.
- TC-P02-FUB-006 Flutter widget validation for server-supplied quiet-hours and notification blocked reason display without sending completion.
- Regression scope: existing `GoalAutopilotControllerTest`, full goal-autopilot Flutter adapter/widget test, OpenAPI contract and generated Dart drift.
- Explicit boundary: no notification scheduler/outbox lifecycle, dedupe, retry, send, cancel or replay implementation was added; those remain TC-P02-FUB-007/008.

Commands run:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationEligibilityPolicyTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart --name "Followup-B shows quiet-hours and notification blocked reasons without treating them as completion"` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed after fixing reason precedence integration and stale-plan expectation.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `npm run check:openapi-contract` - passed.
- `npm run check:dart-client-drift` - passed.

Passing tests:
- TC-P02-FUB-005: policy returns first matching reason in precedence order: `paused`, `blocked_by_policy`, `unsupported_goal`, `partial_goal_limited`, `stale_plan`, `missing_plan`, `consent_missing`, `permission_denied`, `entitlement_blocked`, `quota_exhausted`, `quiet_hours`, `eligible`.
- TC-P02-FUB-005: quiet hours block same-day windows, cross-midnight evening/morning windows and treat start=end as disabled, returning `next_allowed_at` when blocked.
- TC-P02-FUB-006: Flutter renders `quiet_hours`, `permission_denied`, `entitlement_blocked` and `quota_exhausted` server reason codes and does not call `completeAction` for a blocked or unsent reminder.
- Regression: existing Followup-B control tests still pass; goal revision with stale downstream plan now surfaces `stale_plan` instead of collapsing to `missing_plan`.

Failing or blocked tests:
- No TC-P02-FUB-005/006 failure remains.
- TC-P02-FUB-007..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-003 is executed for deterministic eligibility policy and UI reason rendering.
- AC-P02-FUB-004 remains planned for scheduler/outbox lifecycle.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- Scheduler/outbox, missed-day recovery, item-level memory, L0-L5 transition, replay fixtures, performance budgets, coverage evidence and the dedicated Followup-B traceability script remain open.

## 2026-06-05 P02 Followup-B TC-002 Control Governance Closure

Test scope:
- TC-P02-FUB-002 integration validation for current S001 `UserAutopilotControl` data governance.
- Covered behavior: server-side validation, internal governance export snapshot for control records, redacted idempotency/audit metadata, retention rule snapshot and account deletion cleanup for `goal_autopilot_controls` and `goal_autopilot_control_idempotency`.
- Explicit boundary: no notification scheduler/outbox table or external user export API was added in this slice; notification outbox data governance remains TC-P02-FUB-007/008.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide test` - red step failed before implementation with missing `GoalAutopilotService#exportControlDataGovernance(UUID)`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide test` - passed after implementation.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,AccountDeletionLearningDataTest,TrainingAccountDeletionRetentionTest test` - passed.

Passing tests:
- TC-P02-FUB-002: server rejects invalid control updates, persists valid control state, exports control governance metadata with redacted idempotency/audit details, records retention/deletion policy for current control tables and purges control/idempotency records on account deletion.
- Related regression: foundation migration, full `GoalAutopilotControllerTest`, account-deletion learning data and training account deletion retention tests passed.

Failing or blocked tests:
- No TC-P02-FUB-002 failure remains.
- TC-P02-FUB-005..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-001 is executed for server-owned control source, validation, current persisted control data governance and deletion cleanup.
- Notification outbox records are not implemented in S001 and remain covered by AC-P02-FUB-004 / TC-P02-FUB-007/008.

Residual risk:
- Followup-B is still not complete, not release-ready and not Product Base-ready.
- Scheduler/outbox, missed-day recovery, item-level memory, L0-L5 transition, replay fixtures, performance budgets, coverage evidence and the dedicated Followup-B traceability script remain open.

## 2026-06-05 P02 Followup-B Policy Table Routing Documentation Audit

Test scope:
- Documentation-only routing audit for Followup-B implementation slices P02-FUB-SLICE-001..006.
- Covered policy tables: notification reason precedence, quiet-hours evaluation, outbox lifecycle, recovery mode precedence, item-level memory thresholds/interleaving/intervals, L0-L5 confidence/hold/demotion and replay/performance fixture corpus.
- Covered mapping: AC-P02-FUB-001..008 to TC-P02-FUB-001..017 and fixture IDs FUB-FIX-001..009.

Commands/checks run:
- `git diff --check -- docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/requirements.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/spec.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/acceptance.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/test_cases.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/traceability.md docs/reports/test_report.md docs/reports/quality_report.md` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `npm run check:api-contract` - passed.
- TC enum audit over `test_cases.md` - passed: all `测试层级`, `自动化状态` and `结果状态` values use allowed enums.

Passing checks:
- P02-FUB-SLICE-001..006 now route every Followup-B AC/TC family to fixture IDs.
- FUB-FIX-001..009 now define concrete fixture assertions for control, notification, outbox, recovery, memory, mastery, replay and performance.
- Historical note: this audit kept TC-P02-FUB-002 unresolved while preserving partial validation/deletion-cleanup evidence. That status is superseded by `2026-06-05 P02 Followup-B TC-002 Control Governance Closure` above.

Failing or blocked tests:
- No executable backend, Flutter, AI eval, replay or performance test was run in this documentation-only audit.
- Historical note: TC-P02-FUB-002 was still unresolved during this documentation-only audit; it is now passed for current S001 control data governance.
- TC-P02-FUB-005..017 remain planned.

Acceptance criteria coverage:
- AC-P02-FUB-001..008 remain mapped to stable TC-P02-FUB-001..017.
- Policy-table assertions are routed through existing AC rows and do not create new AC or TC IDs.

Residual risk:
- This audit improves implementation readiness but does not prove runtime behavior.
- Scheduler/outbox, recovery, item-level memory, mastery transition, replay fixtures, performance budgets, coverage evidence and the dedicated Followup-B traceability script remain open.

## 2026-06-04 P02 Followup-B Control Slice Implementation Validation

Test scope:
- Backend UserAutopilotControl source-of-truth, settings update, idempotency, pause/resume, paused next-action suppression, server validation and deletion cleanup subset.
- Flutter Goal Autopilot control binding for server-owned active/paused state and reminder eligibility display.
- Documentation reconciliation for TC script path/method mapping and traceability evidence.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest test` - passed in implementation evidence.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart --name "Followup-B renders server control state and does not override pause or eligibility"` - passed in implementation evidence.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed in implementation evidence.
- `flutter analyze lib/features/goal_autopilot/goal_autopilot_adapter.dart lib/features/goal_autopilot/goal_autopilot_models.dart lib/features/goal_autopilot/goal_autopilot_panel.dart lib/services/api_client.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed in implementation evidence.
- `python3 scripts/project_agent_runner.py validate` - passed in implementation evidence.
- `npm run check:api-contract` - passed in implementation evidence.

Passing tests:
- TC-P02-FUB-001: server-owned control state exists separately from GoalProfile, blocks when missing plan, becomes active after plan generation, and persists settings through goal revision.
- TC-P02-FUB-003: pause/resume is idempotent, paused control suppresses next action and reminder eligibility, and resume re-enables next action through server response.
- TC-P02-FUB-004: Flutter renders paused server state, does not show executable action while paused, sends resume/update-control with Idempotency-Key and does not locally override reminder eligibility.

Partial tests:
- Historical note: TC-P02-FUB-002 originally had only server validation and account-deletion cleanup for `goal_autopilot_controls` and control idempotency in this earlier slice. It is superseded by the 2026-06-05 TC-002 control governance closure above.

Skipped or planned tests:
- TC-P02-FUB-005..017 remain planned, including quiet-hours across midnight, platform permission, entitlement/quota, scheduler/outbox lifecycle, missed-day recovery, item-level memory due decisions, L0-L5 transitions, AI forbidden-field rejection, replay fixtures, performance budgets, coverage evidence and Followup-B traceability script.

Acceptance criteria coverage:
- AC-P02-FUB-001 is executed for the routed control source and current S001 control data-governance scope through TC-P02-FUB-001 and TC-P02-FUB-002.
- AC-P02-FUB-002 is executed through TC-P02-FUB-003 and TC-P02-FUB-004.
- AC-P02-FUB-003 has supporting control-response coverage for paused/consent/missing-plan reason display, but TC-P02-FUB-005 and TC-P02-FUB-006 remain planned.
- AC-P02-FUB-004 through AC-P02-FUB-008 remain planned.

Residual risk:
- Followup-B is partially implemented only. It is not complete, not release-ready and not Product Base-ready.
- Notification outbox governance, scheduler/outbox, recovery, memory/mastery, replay, coverage, performance and final independent QA remain open.

## 2026-06-04 P02 Followup-B Pre-implementation Test Mapping Reconciliation

Test scope:
- Test Case Development reconciliation for `p0-2-followup-b-autopilot-control-planner-memory`.
- Covered mapping: TC-P02-FUB-017 and its release-check path for traceability, coverage and pre-implementation routing.
- This is not Followup-B code implementation, test execution, performance evidence or release approval.

Commands run:
- `ls scripts/check_p0_2_followup_b_traceability.py scripts/check_p0_2_goal_autopilot_coverage.py` - at this earlier pre-implementation gate, confirmed `scripts/check_p0_2_followup_b_traceability.py` was missing and `scripts/check_p0_2_goal_autopilot_coverage.py` existed; the dedicated script was later created in S006.
- Planned pre-implementation equivalent gate for routing: `python3 scripts/project_agent_runner.py validate`, `npm run check:api-contract`, and `git diff --check -- <touched Followup-B docs/contracts/status files>`.

Passing checks:
- AC-P02-FUB-001 through AC-P02-FUB-008 still map to stable TC-P02-FUB-001 through TC-P02-FUB-017.
- TC-P02-FUB-017 explicitly distinguished the then-missing implementation-completion script from the pre-implementation equivalent routing gate; S006 later created and ran the script.
- No TC-P02-FUB row is marked passed or implemented.

Failing or blocked tests:
- At this earlier gate, TC-P02-FUB-017 was planned. S006 later created `scripts/check_p0_2_followup_b_traceability.py` and recorded passed evidence.

Skipped or planned tests:
- At this earlier gate, all Followup-B backend, Flutter, AI eval, replay, performance, coverage and traceability tests were planned until implementation started.

Acceptance criteria coverage:
- AC-P02-FUB-008 was routed to release-check coverage through TC-P02-FUB-015, TC-P02-FUB-016 and TC-P02-FUB-017; S006 later executed those rows.
- The pre-implementation equivalent gate is allowed only for routing readiness and must not be reported as executed TC evidence.

Residual risk:
- At this earlier gate, a dedicated Followup-B traceability script still needed implementation; S006 later closed that local gap.
- Followup-B remains not release-ready and must not be marked implemented, test-passing, release-ready or Product Base-ready until executable tests, coverage, performance evidence, implementation report and quality review are produced.

## 2026-06-04 P02 Followup-A No-goal Explore Mode Implementation Validation

Test scope:
- Followup-A FR-009 local implementation for no active goal empty state, explicit `Set a goal` transition and no-goal Explore/sample drill boundary.
- Covered code: `lib/features/goal_autopilot/goal_autopilot_panel.dart`, `test/features/goal_autopilot/goal_autopilot_adapter_test.dart` and strengthened `scripts/check_p0_2_goal_autopilot_traceability.py`.

Commands run:
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter analyze lib/features/goal_autopilot lib/services/api_client.dart lib/pages/home_page.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- <Followup-A FR-009 changed files>` - passed.
- Followup-A FR-009 touched-file whitespace audit - passed.

Passing tests:
- TC-P02-FUA-014: no active goal renders `No active goal`, `Set a goal`, `Explore practice` and `Try a sample drill`; it does not render GoalProfile form or create a goal by default.
- TC-P02-FUA-015: `Set a goal` opens editable intake and no non-summary goal-autopilot operation runs before valid submit.
- TC-P02-FUA-016: `Explore practice` renders ordinary sample drill feedback, does not call create/generate/complete/checkpoint/forecast/memory goal-autopilot operations and does not show target gap, ETA, achieved-goal, guaranteed or official-score copy.

Failing or blocked tests:
- No Followup-A FR-009 functional, analyzer, coverage or backend regression failure remains.

Skipped or external tests:
- Full Explore Practice content library, recommender and ordinary practice persistence are not Followup-A scope.

Acceptance criteria coverage:
- AC-P02-FUA-009 maps to executed TC-P02-FUA-014, TC-P02-FUA-015 and TC-P02-FUA-016.

Residual risk:
- Followup-B/C/D remain unimplemented and must not be inferred from Followup-A.

## 2026-06-04 P02 Followup-A No-goal Explore Mode Planned Test Audit

Superseded status note: this planned-test audit is superseded by the implementation validation above, where TC-P02-FUA-014..016 passed locally.

Test scope:
- Documentation-only planned test audit for `P02-FUA-FR-009 No-goal Explore Mode`.
- Covered behavior: no active goal empty state, explicit `Set a goal` transition, no default-goal creation, Explore/sample drill isolation from goal-autopilot APIs, ordinary practice/session evidence boundary and prohibited goal claims.

Commands run:
- Followup-A No-goal Explore Mode document audit - passed.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- `git diff --check -- docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening docs/reports/quality_report.md docs/reports/test_report.md scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- Followup-A no-goal touched-file whitespace audit - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing checks:
- AC-P02-FUA-009 maps to TC-P02-FUA-014, TC-P02-FUA-015 and TC-P02-FUA-016.
- P02-FUA-TR-009 maps WP-009 -> FR-009 -> SPEC-009 -> AC-009 -> TC-014..016.
- Test cases explicitly require no GoalProfile, DiagnosticAssessment, ProgressForecast, GoalBackplan, DailyPlan, AutopilotAction or MemoryCurve schedule during no-goal browsing.

Failing or blocked tests:
- No documentation traceability failure remains.
- Historical note from this documentation-only audit: TC-P02-FUA-014, TC-P02-FUA-015 and TC-P02-FUA-016 were blocked until code implementation started. This is superseded by the implementation validation above.

Skipped or planned tests:
- Historical note from this documentation-only audit: Flutter widget/adapter tests for FR-009 were planned but not run because that earlier step intentionally did not change code. This is superseded by the implementation validation above.

Acceptance criteria coverage:
- Historical note from this documentation-only audit: AC-P02-FUA-009 had planned coverage through TC-P02-FUA-014..016. It now has executed coverage in the implementation validation above.
- AC-P02-FUA-001 was narrowed so editable intake is required after explicit `Set a goal` or edit, not as the default no-active-goal browsing state.

Residual risk:
- Historical note from this documentation-only audit: the app still needed implementation work at that time. This is superseded by the implementation validation above.

## 2026-06-04 P02 Followup-A Implementation Validation

Test scope:
- Followup-A local implementation for editable GoalProfile intake, SupportedGoalMatrix pre-plan UI, diagnostic sample capture, candidate-only diagnostic transport, revision/stale visibility, claim guard copy and Followup-A traceability.
- Covered code: `lib/features/goal_autopilot/goal_autopilot_adapter.dart`, `lib/features/goal_autopilot/goal_autopilot_models.dart`, `lib/features/goal_autopilot/goal_autopilot_panel.dart`, `test/features/goal_autopilot/goal_autopilot_adapter_test.dart` and strengthened `scripts/check_p0_2_goal_autopilot_traceability.py`.

Commands run:
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter analyze lib/features/goal_autopilot lib/services/api_client.dart lib/pages/home_page.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed and generated `coverage/lcov.info`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed and regenerated `backend/target/site/jacoco/jacoco.csv`.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.5%.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed after the script was strengthened to include Followup-A docs, code and test names.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-P02-FUA-001/002: editable GoalProfile form renders, blocks invalid empty diagnostic submission, sends user-entered goal fields and no longer uses default-goal-only production UI.
- TC-P02-FUA-003/004: diagnostic samples filter empty text, preserve stable sample refs and do not send fake `audio_ref`.
- TC-P02-FUA-005/006/007: supported, partial/low-confidence and unsupported states render correctly; unsupported goals fail closed with Edit goal recovery only.
- TC-P02-FUA-008/009: claim guards block official/guaranteed copy; revision/stale state blocks stale Done action and sends force replan recovery.
- TC-P02-FUA-010/012: backend regression and local performance checks still pass; no backend/API/domain code changed for Followup-A.
- TC-P02-FUA-011/013: coverage and strengthened traceability gates pass.

Failing or blocked tests:
- No Followup-A local functional, analyzer, coverage or traceability failure remains.

Skipped or external tests:
- Production audio capture, paid AI diagnostic quality, commercial entitlement/cost telemetry and release rollout are not Followup-A scope.
- Followup-B/C/D behavior remains unimplemented and must not be inferred from Followup-A.

Acceptance criteria coverage:
- AC-P02-FUA-001 through AC-P02-FUA-008 all map to executed TC-P02-FUA evidence in `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/test_cases.md`.

Residual risk:
- Followup-A closes editable intake and diagnostic hardening locally, but does not close pause/resume, notification scheduling, Queue/Wiki propagation, commercial release, paid AI evidence or Product Base approval.

## 2026-06-04 P02 Goal Autopilot Local Implementation Validation - P02-GOAL-AUTOPILOT-LOCAL-IMPLEMENTATION-20260604

Test scope:
- P0.2 local deterministic vertical slice for `GoalProfile`, `DiagnosticAssessment`, `GoalBackplan`, `MemoryCurvePolicy`, `AutopilotTraining`, `ProgressForecast` and `OutcomeCheckpoint`.
- Covered contracts: domain model, OpenAPI/API path registry, candidate AI-runtime schemas and UX screen spec routing.
- Covered code: backend goal-autopilot persistence/service/controller, account deletion cleanup, Flutter API adapter, Home learn-tab goal-autopilot panel and focused widget/adapter tests.

Commands run:
- `npm run check:api-contract` - passed; OpenAPI lint, contract gate and generated Dart drift gate passed with hash `87c9218d93a5be9879e52390a1cd2c92de6fd198938a613bbcfc89ae5e0e4f98`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter analyze lib/features/goal_autopilot lib/services/api_client.dart lib/pages/home_page.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed and generated `backend/target/site/jacoco/jacoco.csv`.
- `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed and generated `coverage/lcov.info`.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter feature line 82.1%.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.

Passing tests:
- Backend integration tests cover goal creation, supported/partial/unsupported goal matrix, diagnostic confidence/claim guard, weakness decomposition, L0-L5 mastery seed, weekly/daily plan generation, memory policy, next-action orchestration, completion recovery signal, unsupported-goal fail-closed behavior, checkpoint-driven forecast update and account deletion purge.
- Backend performance test covers local p95 budgets for goal intake, daily plan, next action and forecast.
- Flutter tests cover API path-registry usage, summary parsing, default goal creation, plan generation, next action, action completion, checkpoint envelope and Home panel start/autopilot rendering.

Failing or blocked tests:
- No functional local P0.2 test failure remains.
- No coverage failure remains for the implemented local slice. Backend changed-code line/branch coverage and Flutter feature line coverage are above 80%. Dart coverage tooling does not emit branch coverage, so Flutter branch coverage is not separately measurable by the local toolchain.

Skipped or external tests:
- Historical note for this earlier local slice: paid AI entitlement/cost telemetry, production notification scheduling, pause/resume endpoint semantics, Queue/Wiki progress-surface propagation, broader checkpoint task library, full adaptive workload tuning and commercial release checks were outside that local slice. Pause/resume endpoint semantics are now partially covered by `P02-FOLLOWUP-B-CONTROL-SLICE-20260604`; the other listed gates remain open.

Acceptance criteria coverage:
- `AC-P02-DIAG-001..007`, `AC-P02-PLAN-001..008` and `AC-P02-AUTO-001..008` now have planned TC mappings plus local executed evidence addenda in their increment test case files.
- Local code/test/coverage traceability is complete for the deterministic vertical slice; release traceability is not complete until the residual product gates above are closed or explicitly re-scoped.

Residual risk:
- The Flutter entry currently provides a compact default goal setup rather than the full editable GoalProfile UI.
- Autopilot user control remains partial: skip/defer and quiet-hour fields exist, and pause/resume endpoints now have a routed Followup-B control-slice implementation; notification scheduler behavior and full Followup-B control completion remain open.
- Goal progress appears on the Home learn tab only; Queue/Wiki propagation remains a future surface obligation.

## 2026-06-04 P02 Downstream Requirements Spec AC TC Traceability Audit

Test scope:
- Documentation-only audit for the three P0.2 increments:
  `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy` and `p0-2-autopilot-progress-checkpoint`.
- Coverage: P02-SI-001 through P02-SI-013, P02-PG-001 through P02-PG-005, all new FR/Spec/AC/TC/Traceability IDs, performance budgets and >=80% code coverage gates.

Commands run:
- `p02-diagnostic-chain` audit - passed.
- `p02-plan-chain` audit - passed.
- `p02-auto-chain` audit - passed.
- `p02-stage-scope-traceability` audit - passed.
- `p02-policy-gate-downstream` audit - passed.
- `p02-ac-tc-trace-prefixes` audit - passed.
- `git diff --check -- <P0.2 downstream docs and reports>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing checks:
- Every P02-SI-001 through P02-SI-013 appears in at least one increment traceability matrix.
- Every P02-PG-001 through P02-PG-005 is represented in downstream increment docs.
- Every P0.2 AC family has planned TC IDs and traceability rows.
- Each increment includes explicit performance budgets and changed-code line/branch coverage >=80% as implementation completion gates.

Failing or blocked tests:
- No documentation traceability failure remains.

Skipped or planned tests:
- All P0.2 functional, performance and coverage tests are planned, not executed. No code was implemented in this documentation batch.

Acceptance criteria coverage:
- `AC-P02-DIAG-001..007`, `AC-P02-PLAN-001..008` and `AC-P02-AUTO-001..008` are mapped to planned TC IDs.

Residual risk:
- This audit proves 100% documentation traceability for planned P0.2 scope. It does not prove runtime behavior, performance, code coverage or release readiness.
- Domain/API/AI/UX contracts, implementation code, CI coverage reports, performance results and executed test evidence remain open gates.

## 2026-06-04 P02 Policy Gate Commercial Product Review Audit

Test scope:
- Documentation-only audit for P0.2 product-engineering and commercial-software policy gates.
- Coverage: P02-PG-001 through P02-PG-005, the seven previously identified P0.2 defects, P0.2 stage entry/exit gates and the three planned increment definitions.

Commands run:
- P02 policy gate ID audit - passed; all P02-PG-001 through P02-PG-005 appear in the stage and applicable increment definitions.
- P02 seven-defect closure audit - passed at planning-gate level; each defect maps to at least one policy gate and an owning downstream artifact obligation.
- `git diff --check -- <P0.2 policy gate docs and reports>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing checks:
- Goal achievement, supported-goal/content coverage, autopilot control/planner feasibility, commercial entitlement/cost and data governance are now explicit implementation gates.
- The three P0.2 increments must carry applicable policy gates into requirements/spec/acceptance/test_cases/traceability before implementation.
- No policy gate claims implementation readiness, release approval or official exam-score certification.

Failing or blocked tests:
- No documentation-gate failure remains.

Skipped or planned tests:
- Functional, API, UX, AI-runtime and data-governance tests remain planned because downstream P0.2 docs and implementation do not exist yet.

Acceptance criteria coverage:
- No new AC was created in this step. P02-PG-001 through P02-PG-005 are upstream gate obligations that future AC/TC must cover.

Residual risk:
- The seven defects are closed only at planning-gate level. They still require downstream FR/Spec/AC/TC/Traceability, domain/API/AI/UX contracts and independent checker review before implementation.

## 2026-06-04 P02 Superseded Memory Artifact Removal Audit

Test scope:
- P0.2 documentation source-of-truth cleanup after goal-driven stage replanning.
- Coverage: stage plan, roadmap, feature registry, development status, new P0.2 increment definitions and report records.

Commands run:
- Superseded artifact slug reference audit across `docs/product` and `docs/reports` - passed with no remaining matches.
- Directory removal check for the old P0.2 memory-planner artifact - passed.
- Active P0.2 increment link audit for `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy` and `p0-2-autopilot-progress-checkpoint` - passed.
- `git diff --check -- <P0.2 supersession docs>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing checks:
- Old artifact links are removed from active product and report documentation.
- P02-SI-001 through P02-SI-013 remain represented in the P0.2 stage plan and route to the three goal-driven planned increments.
- The earlier memory-planner audit is described as superseded historical evidence, not active implementation input.

Failing or blocked tests:
- No documentation cleanup failure remains.

Skipped or planned tests:
- Functional P0.2 tests remain planned because no P0.2 implementation or downstream contracts were created in this cleanup.

Acceptance criteria coverage:
- No new AC was created. This cleanup protects the P0.2 planning gate by removing a superseded implementation entry and preserving stage-scope routing to the new increment definitions.

Residual risk:
- The three new P0.2 increments still need requirements/spec/acceptance/test_cases/traceability and independent checker review before implementation.

## 2026-06-04 P02 Documentation Design And Traceability Audit

Test scope:
- Superseded historical P0.2 memory-planner documentation design.
- Coverage: P02-SI-001 through P02-SI-006, P02-FR-001 through P02-FR-010, P02-SPEC-001 through P02-SPEC-010, AC-P02-001 through AC-P02-010, TC-P02-001 through TC-P02-014 and P02-TR-001 through P02-TR-010.

Commands run:
- P02 documentation ID coverage audit - passed; `missing_ids=[]`, `forbidden_hits=[]`.
- `git diff --check -- <historical P0.2 memory-planner docs>` - passed before supersession.
- `python3 scripts/project_agent_runner.py validate` - passed.
- P02 traceability `rg` audit - passed before supersession.

Passing checks:
- TC-P02-014 documentation traceability audit passed.
- P02-SI-001..006 all have owning increment coverage.
- Every P02-FR maps to a P02-SPEC and at least one AC.
- Every AC-P02-001..010 maps to at least one stable TC-P02 ID.
- Traceability rows explicitly keep Code Evidence and functional Test Evidence as not started/planned.

Failing or blocked tests:
- No documentation traceability failure remains.

Skipped or planned tests:
- TC-P02-001 through TC-P02-013 are planned functional tests and were not run because implementation and P02 domain/API/AI/UX contracts do not exist yet.

Acceptance criteria coverage:
- AC-P02-001 through AC-P02-010 have complete planned TC coverage.
- P02-GAP-001 through P02-GAP-006 remain implementation blockers or contract blockers and are not closed by this documentation audit.

Residual risk:
- This historical audit is not P0.2 implementation evidence, Product Base merge approval or release approval.
- This historical audit is superseded by the goal-driven stage replanning. Active P0.2 implementation remains blocked until the three new increments generate their own requirements/spec/AC/TC/traceability, domain/API/AI/UX contracts, scope guard and executable functional tests.

## 2026-06-04 P01 Product Base Implementation Review And API Drift Sync

Test scope:
- P0.1 `p0-1-expression-automation-training` Product Base implementation review.
- Coverage: `P01-FR-012` through `P01-FR-017`, `P01-SPEC-013` through `P01-SPEC-018`, `AC-P01-014` through `AC-P01-019`, `TC-P01-021` through `TC-P01-031`, plus backend-only frontend regressions `TC-P01-001` through `TC-P01-013`.

Commands run:
- `cd backend && mvn -q -DskipTests compile` - passed.
- `cd backend && mvn -q -Dtest=TrainingSessionControllerTest,TrainingTurnIdempotencyTest,TrainingSessionAuthorizationTest,TrainingEvidenceRuleTraceTest,TrainingAccountDeletionRetentionTest,TrainingContentVersioningTest,TrainingMediaAiPipelineTest,TrainingPlannerReplayTest,TrainingObservabilityTest test` - passed.
- `npm run check:api-contract` - passed after syncing generated Dart drift pins to OpenAPI hash `4880e61f8dae8673c13eb2aff5c66e690de70e67663bae45608f57206502fcbf`.
- `python3 scripts/check_p0_1_training_frontend_source_of_truth.py` - passed.
- `python3 scripts/check_p0_1_training_rollout_readiness.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter analyze lib/config/app_config.dart lib/services/api_client.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - passed.

Passing tests:
- TC-P01-021 through TC-P01-028 remain covered by backend Training tests for server source-of-truth, idempotency, evidence governance, deletion cleanup, versioned content, media/AI, planner replay and observability.
- TC-P01-029 through TC-P01-031 remain covered by Flutter backend-only loop, fallback and backend-disabled entry tests.
- Contract drift is closed by `npm run check:api-contract`.

Failing or blocked tests:
- No local implementation-review failure remains.

Skipped or external tests:
- Real paid AI DashScope full matrix, object storage, production cost dashboard and retention evidence remain outside this P0.1 local Product Base review and are governed by P0 commercial AI gates.

Acceptance criteria coverage:
- AC-P01-014 through AC-P01-019 are covered by TC-P01-021 through TC-P01-031 and traceability rows P01-TR-013 through P01-TR-018.

Residual risk:
- Product Base merge approval, paid AI voice and commercial release remain separate gates.

## 2026-06-03 P01 Training Bounded-Context Naming Migration

Test scope:
- Namespace-only migration from historical `interview_training_*` / `InterviewTraining*` names to the Training bounded-context names.
- Coverage: executable Training production code, Training widget/adapter tests, TC-P01-031 integration, source-of-truth and rollout readiness scripts, active P0.1 docs.

Commands run:
- `python3 scripts/check_p0_1_training_frontend_source_of_truth.py` - passed.
- `python3 scripts/check_p0_1_training_rollout_readiness.py` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - passed.
- `flutter analyze lib/features/training/training_contract.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_view.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_test_helpers.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart scripts/check_ai_eval_cases.dart` - passed.
- `flutter analyze integration_test/p0_1_training_loop_test.dart` - passed.
- `dart run scripts/check_ai_eval_cases.dart` - passed: 7 cases.

Passing checks:
- Production files are under `lib/features/training/`.
- Training tests are under `test/features/training/`.
- Executable code has no `InterviewTraining*`, `interview_training_*`, `features/interview/training_*`, or frontend `TrainingAgent` source-of-truth fallback.
- `scripts/check_ai_eval_cases.dart` imports `training_contract.dart`, not a local agent.
- AI-EVAL-P01-007 now validates invented action-chain/micro-action rejection without reintroducing a Flutter two-scene allowlist; backend Training content mapping owns official scenario/version fail-closed behavior.

Failing or blocked tests:
- No local naming migration failure remains.

Skipped or external tests:
- None for this namespace-only migration.

Acceptance criteria coverage:
- No new FR/AC was introduced. Existing TC-P01 IDs and traceability rows are preserved; only code/test evidence paths changed.

Residual risk:
- Historical report sections may preserve legacy file references as past evidence. Current source-of-truth docs, scripts and executable code use `training_*` names.

## 2026-06-03 P01 Training Backend-Only Frontend Source Of Truth

Test scope:
- P0.1 `p0-1-expression-automation-training` backend-only frontend correction.
- Coverage: `P01-FR-001` through `P01-FR-010`, `P01-FR-012`, `P01-FR-015`, `P01-FR-017`; `P01-SPEC-001` through `P01-SPEC-011`, `P01-SPEC-013`, `P01-SPEC-016`, `P01-SPEC-018`; `AC-P01-001` through `AC-P01-012`, `AC-P01-014`, `AC-P01-017`, `AC-P01-019`; `TC-P01-001` through `TC-P01-013`, `TC-P01-029`, `TC-P01-030`, `TC-P01-031`.

Commands run:
- `python3 scripts/check_p0_1_training_frontend_source_of_truth.py` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - passed after converting TC-P01-031 to a self-contained HomePage/local-session fixture that does not require `API_BASE_URL`.
- `flutter analyze lib/features/training/training_contract.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_view.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_test_helpers.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter analyze integration_test/p0_1_training_loop_test.dart` - passed.
- `dart format lib/features/training/training_contract.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_view.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_test_helpers.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart integration_test/p0_1_training_loop_test.dart` - completed.

Passing tests:
- TC-P01-001: backend session start renders server state, and backend unavailable renders unavailable instead of creating a local session.
- TC-P01-002 through TC-P01-005: Flutter renders backend content/action/hint/planner state and no longer owns action-chain or planner progression.
- TC-P01-006 and TC-P01-007: voice/text controls remain visible, but text fallback submits backend turns only.
- TC-P01-008 through TC-P01-011: feedback, evidence, recoverable failure and recap state are rendered from backend contract/fallback state; Flutter does not create accepted evidence or final mastery.
- TC-P01-012 and TC-P01-013: unsupported local source-of-truth paths are guarded by backend scenario/version mapping and the frontend source-of-truth script.
- TC-P01-029: continue/retry in the loop call backend refresh/hint, not local planner or canned feedback.
- TC-P01-030: missing trusted audio ref produces recoverable text fallback and typed text submits through backend `submitTurn`.
- TC-P01-031: when `ENABLE_BACKEND_TRAINING=false`, the HomePage training entry is blocked with service-unavailable UI and no route/session is created; covered by source-of-truth static guard and direct integration test.

Failing or blocked tests:
- No local Flutter backend-only source-of-truth failure remains.

Skipped or external tests:
- None for the local backend-only frontend source-of-truth gate.

Acceptance criteria coverage:
- AC-P01-014 is covered by TC-P01-001, TC-P01-013, TC-P01-029 and TC-P01-031 at the frontend entry/loop boundary, plus TC-P01-021/022 at the backend boundary.
- AC-P01-017 is covered by TC-P01-006, TC-P01-007, TC-P01-026 and TC-P01-030.
- AC-P01-019 is covered by TC-P01-013, TC-P01-028, TC-P01-029 and TC-P01-031.

Residual risk:
- This packet intentionally removes Flutter local Training state-machine fallback from the production path. Future local demos must be isolated as fixtures/dev tools and must not be wired to the product training entry.
- Paid AI voice, commercial release and external provider/media evidence remain governed by the P0 strict gates.

## 2026-06-03 P01 Training Product Base Production Hardening

Test scope:
- P0.1 `p0-1-expression-automation-training` backend/Flutter production-hardening implementation.
- Coverage: `P01-FR-012` through `P01-FR-017`, `P01-SPEC-013` through `P01-SPEC-018`, `AC-P01-014` through `AC-P01-019`, `TC-P01-021` through `TC-P01-031`.

Commands run:
- `cd backend && mvn -q -DskipTests compile` - passed.
- `cd backend && mvn -q -Dtest=TrainingSessionControllerTest,TrainingTurnIdempotencyTest,TrainingSessionAuthorizationTest,TrainingEvidenceRuleTraceTest,TrainingAccountDeletionRetentionTest,TrainingContentVersioningTest,TrainingMediaAiPipelineTest,TrainingPlannerReplayTest,TrainingObservabilityTest test` - passed.
- `cd backend && mvn -q test` - passed; full backend regression passed after adding Training user-data cascade cleanup semantics.
- `flutter test test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter analyze lib/config/app_config.dart lib/services/api_client.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `python3 scripts/check_p0_1_training_rollout_readiness.py` - passed.
- `npm run check:api-contract` - passed; OpenAPI/Dart drift hash remains `4880e61f8dae8673c13eb2aff5c66e690de70e67663bae45608f57206502fcbf`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `dart format lib/config/app_config.dart lib/services/api_client.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - completed.

Passing tests:
- TC-P01-021: `TrainingSessionControllerTest` verifies backend Training source-of-truth, persisted session state, reviewed action chain mapping and fail-closed unknown official scenario handling.
- TC-P01-022: `TrainingTurnIdempotencyTest` and `TrainingSessionAuthorizationTest` verify turn replay/conflict behavior, no duplicate provider work and owner-scoped access.
- TC-P01-023: `TrainingEvidenceRuleTraceTest` verifies accepted evidence writes LearningEvidence with `training_signal_v1`, reason code and schema version.
- TC-P01-024: `TrainingAccountDeletionRetentionTest` verifies training sessions, turns, planner decisions, evidence candidates, metrics and LearningEvidence are purged on account deletion.
- TC-P01-025: `TrainingContentVersioningTest` and `training_content_mapping_test.dart` verify reviewed scenario-version mapping and Flutter production adapter support for future official scenarios without a two-seed hard-code.
- TC-P01-026: `TrainingMediaAiPipelineTest` and `training_backend_pipeline_test.dart` verify trusted `audio_ref`, ASR, pronunciation scoring, LLM feedback, backend adapter audio upload and evidence candidate mapping.
- TC-P01-027: `TrainingPlannerReplayTest` and `training_planner_replay_test.dart` verify planner audit rows, rule version, no raw transcript in snapshots, backend hint/pressure/replay mapping and recap mapping.
- TC-P01-028: `TrainingObservabilityTest` verifies redacted training metrics for start, turn, planner, evidence and completion.
- Rollout gate: `scripts/check_p0_1_training_rollout_readiness.py` verifies code/test/report/traceability evidence for TC-P01-021 through TC-P01-031.

Failing or blocked tests:
- No local backend/Flutter failure remains for TC-P01-021 through TC-P01-031.

Skipped or external tests:
- Real paid AI DashScope full matrix, real object storage, production cost dashboard and retention evidence are not part of this P0.1 local hardening closure and remain governed by P0 commercial AI gates.

Acceptance criteria coverage:
- AC-P01-014 through AC-P01-019 are covered by TC-P01-021 through TC-P01-031 and traceability rows P01-TR-013 through P01-TR-018.

Residual risk:
- Superseded by 2026-06-04 implementation review: generated Dart OpenAPI drift pins are now synced to current OpenAPI hash `4880e61f8dae8673c13eb2aff5c66e690de70e67663bae45608f57206502fcbf`.
- Production enablement still requires configuration of `ENABLE_BACKEND_TRAINING=true` and the existing P0 paid AI/commercial release evidence gates before paid voice or app-store release claims.

## 2026-06-03 P0.1 Commercial Software Remediation Documentation Gate

Superseded status note: this section records the earlier documentation-only gate. The later `2026-06-03 P01 Training Product Base Production Hardening` section supersedes its planned-test status for TC-P01-021 through TC-P01-028 and records local passed evidence for TC-P01-021 through TC-P01-031.

Test scope:
- P0.1 documentation/design remediation inside `p0-1-expression-automation-training`.
- Coverage: `P01-FR-012` through `P01-FR-017`, `P01-SPEC-013` through `P01-SPEC-018`, `AC-P01-014` through `AC-P01-019`, `TC-P01-021` through `TC-P01-031`, `P01-TR-013` through `P01-TR-018`.

Commands run:
- `rg -n "P01-FR-012|P01-SPEC-013|AC-P01-014|TC-P01-021|P01-TR-013|P01-GAP-009|P01-HARDEN-001|Product Base/production" docs/product/increments/p0-1-expression-automation-training docs/architecture docs/domain docs/product/stages/p0-1-expression-automation.md docs/product/development_status.md docs/release/release_checklist.md` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- <changed docs>` - passed.

Passing tests:
- OpenAPI lint, contract and generated Dart client drift gates passed through `npm run check:api-contract`.
- Documentation traceability search confirms the new P0.1 production-hardening IDs are present across increment docs, architecture/domain docs, stage/development status and release checklist.
- Diff whitespace validation passed for changed documentation files.

Failing or blocked tests:
- No documentation gate failure remains.
- Historical note from this documentation-only gate: at that time TC-P01-021 through TC-P01-028 were planned and not executed. This statement is superseded by the later Product Base Production Hardening section, where TC-P01-021 through TC-P01-031 have local passed evidence.

Skipped or external tests:
- Backend Training controller/service/repository tests, Flutter generated-client wiring tests, media/AI production pipeline tests and rollout/observability checks were not run because this batch changed documentation only and did not implement those systems.

Acceptance criteria coverage:
- AC-P01-014 through AC-P01-019 now map to stable planned TC IDs and traceability rows.
- Existing TC-P01-013/014 local evidence remains valid for local route/AI eval only and does not close the new Product Base/production hardening gate.

Residual risk:
- Historical note from this documentation-only gate: P0.1 could not be promoted until TC-P01-021 through TC-P01-028 passed or blockers were accepted. This planned-test warning is superseded by the later Product Base Production Hardening section; PM approval and Product Base merge review remain separate gates.
- Commercial release and paid AI voice remain controlled by the P0 commercial release and commercial AI provider hardening gates.

## 2026-06-03 P0-AI OSS Storage Implementation

Test scope:
- `commercial-ai-provider-hardening` object storage implementation for `COM-SI-013`.
- AC/TC: `AC-COM-AI-001`; `TC-COM-AI-001`, `TC-COM-AI-002`, `TC-COM-AI-008`.

Commands run:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,AiMediaStorageServiceTest,ProductionAsrMediaRefTest,PersistentTtsCacheTest,AiCostDashboardTest,AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,DashScopeProviderGatewayIntegrationTest,DashScopeProviderGatewayTest,CommercialFoundationControllerTest,AccountDeletionLearningDataTest,FoundationMigrationTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/check_ai_external_release_evidence.py` - passed and reported the four missing paid AI external evidence refs as release blockers.
- `python3 scripts/check_ai_external_release_evidence.py --strict-external` - failed as expected because the four refs are not set.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- `MediaUploadReferenceServiceTest` verifies backend-created upload sessions, upload headers, complete flow and forged `object_ref` rejection.
- `AiMediaStorageServiceTest` verifies Aliyun OSS canonical `oss://bucket/key`, signed upload/read URLs, KMS/SSE upload header handling, object deletion key resolution and local adapter mismatch rejection.
- Existing ASR, TTS cache, cost dashboard, retention/account deletion and DashScope gateway tests still pass after the storage adapter was introduced.
- Full backend test suite passed after locking the test profile to deterministic provider by default and keeping DashScope-specific tests explicit.

Failing or blocked tests:
- No local failure remains for TC-COM-AI-008.
- Strict external release evidence remains blocked until `AI_MEDIA_STORAGE_EVIDENCE_REF` points to reviewed staging/release candidate OSS evidence.

Skipped or external tests:
- Real Aliyun OSS bucket upload, provider read access, URL expiry, lifecycle/delete proof and KMS/ACL review were not executed because no Aliyun account/credentials were provided.

Acceptance criteria coverage:
- `AC-COM-AI-001` now has automated coverage for backend-owned object refs, signed upload/read URL generation and client-forged object_ref rejection.
- Release evidence coverage for the real bucket lifecycle remains governed by `P0-AI-STORAGE-001` and `AI_MEDIA_STORAGE_EVIDENCE_REF`.

Residual risk:
- Local mocked OSS signing does not prove real-region bucket policy, KMS behavior, provider fetchability, expiry enforcement or deletion in staging/release.

## 2026-06-03 P0-AI External Evidence Gate Validation

Test scope:
- `commercial-ai-provider-hardening` paid AI external evidence strategy and release gates.
- Coverage: `COM-SI-013`, `COM-SI-015`, `COM-SI-016`, `COM-SI-017`.
- AC/TC: `AC-COM-AI-001`, `AC-COM-AI-003`, `AC-COM-AI-004`, `AC-COM-AI-005`; `TC-COM-AI-001`, `TC-COM-AI-002`, `TC-COM-AI-004`, `TC-COM-AI-005`, `TC-COM-AI-006`, `TC-COM-AI-007`.

Commands run:
- `python3 scripts/check_ai_external_release_evidence.py` - passed; reported missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`, `AI_MEDIA_STORAGE_EVIDENCE_REF`, `AI_COST_DASHBOARD_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF`.
- `python3 scripts/check_ai_external_release_evidence.py --strict-external` - failed as expected because the four refs are not set.
- `python3 -m py_compile scripts/check_ai_external_release_evidence.py scripts/check_ai_provider_sandbox_evidence.py scripts/check_manual_external_evidence_plan.py` - passed.
- `bash -n scripts/check_release_readiness.sh` - passed.
- `python3 scripts/check_ai_provider_sandbox_evidence.py` - passed; reported missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.
- `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` - failed as expected.
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with dummy external evidence refs and release env - passed; fixture only validates gate wiring.
- `git diff --check` - passed.

Passing tests:
- Paid AI external checklist structure passed in non-strict mode.
- The new gate is wired into aggregate release readiness and accepts non-local external-style fixture refs in env-only validation.
- Existing manual external evidence plan and DashScope matrix structure gate still pass in non-strict mode.

Failing or blocked tests:
- Strict paid AI external evidence gate fails until all four required external refs are supplied.
- Strict DashScope provider evidence gate still fails until `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` is supplied.

Skipped or external tests:
- No real DashScope full matrix, object-storage lifecycle, PM/Ops dashboard evidence, retention/account deletion external proof or independent external reviewer approval was executed in this local environment.

Acceptance criteria coverage:
- `AC-COM-AI-001`, `AC-COM-AI-003`, `AC-COM-AI-004` and `AC-COM-AI-005` now have explicit external release evidence scenarios and strict gate mappings in addition to existing local automated evidence.

Residual risk:
- Paid AI voice remains blocked for real users until the four external evidence refs are populated from reviewed evidence packages and strict gates pass in the release candidate environment.

## 2026-06-03 P0.1 Local Blocker Closure And Commercial External Gate Revalidation

Test scope:
- TC-P01-013 route-level P0.1 training loop integration.
- TC-P01-014 executable P0.1 AI eval validator.
- TC-COM-AI-004 controlled live DashScope evidence preparation.
- TC-COM-012/015/019/021/022 commercial external/native/store/release gates.

Commands run:
- `dart format lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart integration_test/p0_1_training_loop_test.dart lib/features/training/training_agent.dart test/features/training/training_feedback_schema_test.dart scripts/check_ai_eval_cases.dart` - passed.
- `flutter analyze lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart integration_test/p0_1_training_loop_test.dart lib/features/training/training_agent.dart test/features/training/training_feedback_schema_test.dart scripts/check_ai_eval_cases.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - failed due duplicate macOS test/app processes holding the Hive storage lock, not due TC-P01-013 product behavior.
- `./scripts/run_mvp_system_e2e.sh --suite p0-1-training-loop` - passed with isolated backend, HOME and Hive namespace.
- `dart run scripts/check_ai_eval_cases.dart` - passed: 7 P0.1 AI eval cases.
- `flutter test test/features/training/training_feedback_schema_test.dart` - passed.
- `python3 scripts/run_dashscope_sandbox_matrix.py` - passed: report `build/reports/dashscope-sandbox-20260602T223557Z-3359fcc82fafa457.json`, `overall_status=controlled-live-prepared`, strict ref not present.
- `python3 -m py_compile scripts/run_dashscope_sandbox_matrix.py` - passed.
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/check_commercial_copy_contract.py` - passed in non-strict mode; reported missing store/privacy/support evidence refs.
- `python3 scripts/check_provider_sandbox_evidence.py` - passed in non-strict mode; reported missing Apple/Google evidence refs.
- `python3 scripts/check_ai_provider_sandbox_evidence.py` - passed in non-strict mode; reported missing DashScope external evidence ref.
- `python3 scripts/check_store_submission_evidence.py` - passed in non-strict mode; reported missing store/reviewer/privacy/support evidence refs.
- `python3 scripts/check_commercial_copy_contract.py --strict-external` - failed as expected: `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL`, `SUPPORT_URL` missing.
- `python3 scripts/check_provider_sandbox_evidence.py --strict-external` - failed as expected: `APPLE_SANDBOX_EVIDENCE_REF`, `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` missing.
- `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` - failed as expected: `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` missing.
- `python3 scripts/check_store_submission_evidence.py --strict-external` - failed as expected: `STORE_METADATA_EVIDENCE_REF`, `REVIEWER_ACCOUNT_REF`, `PRIVACY_URL`, `SUPPORT_URL` missing.
- `scripts/check_social_login_release_config.sh --env-only` - failed as expected: `WECHAT_APP_ID` and `WECHAT_UNIVERSAL_LINK` missing.
- `scripts/check_social_login_release_config.sh` - failed as expected: WeChat env missing, iOS placeholder WeChat URL scheme remains, Apple Sign In entitlement missing.
- `scripts/check_release_configuration.sh` - failed as expected: release API URL is not HTTPS production config and `ENV` is not `production`.
- `scripts/check_release_readiness.sh --env-only` and `scripts/check_release_readiness.sh` - failed as expected on strict commercial release evidence, signing, Sentry, social/native and release refs.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- Sanitized report search for API key/Bearer/raw URL patterns - passed; no secret or raw provider reference found.

Passing tests:
- TC-P01-013 passed through the isolated system E2E script. It covers homepage entry into the P0.1 training route, ASR failure text fallback, feedback panel, continue/pressure/recap loop, `pending_local_write` evidence status and return to home.
- TC-P01-014 passed through the executable AI eval validator. All seven P0.1 cases validate runtime schema behavior for positive feedback, task failure, pronunciation-unavailable continuation, ASR fallback, pressure prompt gating, prohibited final-state output rejection and unsupported-scene rejection.
- TC-COM-AI-004 controlled live evidence prep passed for LLM/TTS/ASR positive paths and local fallback/cache/reject/error guards with sanitized output.
- Commercial manual plan, copy, provider, AI provider and store submission structure gates pass in non-strict mode.

Failing or blocked tests:
- No local TC-P01-013 or TC-P01-014 blocker remains.
- TC-COM-AI-004 strict release gate remains blocked by missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.
- TC-COM-012 remains blocked by missing WeChat production env, iOS placeholder WeChat URL scheme and missing Apple Sign In entitlement.
- TC-COM-015 remains blocked by missing `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL` and `SUPPORT_URL`.
- TC-COM-019 remains blocked by missing `APPLE_SANDBOX_EVIDENCE_REF` and `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF`.
- TC-COM-021 remains blocked by missing `STORE_METADATA_EVIDENCE_REF`, `REVIEWER_ACCOUNT_REF`, `PRIVACY_URL` and `SUPPORT_URL`.
- TC-COM-022 remains blocked by strict release configuration, Sentry/signing/symbol/rollback refs, provider/store/native evidence refs, privacy/support URLs and production env.

Skipped or external tests:
- Real Apple sandbox, Google Play internal track, WeChat/Apple native social-login smoke, App Store Connect/Play Console metadata, reviewer account, public privacy/support pages, Android signing, symbol upload and rollback rehearsal were not executed locally.
- The DashScope report is a sanitized evidence-prep artifact in `build/reports`; strict release still requires an external evidence package and independent reviewer.

Acceptance criteria coverage:
- P0.1 route integration and AI eval execution evidence now covers TC-P01-013 and TC-P01-014.
- Commercial external gates remain correctly blocked; non-strict structure pass must not be interpreted as release readiness.

Residual risk:
- P0.1 is locally unblocked for TC-P01-013/014, but Product Manager completion still requires final traceability/report acceptance and any remaining P0.1 non-goal decisions.
- Commercial release and paid AI voice remain blocked until external evidence refs are supplied and independently reviewed.

## 2026-06-02 P0/P0.1 Blocker Retest And System E2E Revalidation

Test scope:
- P0.1 expression automation training core tests and backend AI provider adapter boundary.
- P0 commercial subscription readiness backend, Flutter, API contract, evidence-gate and system E2E blockers.
- P0 commercial AI provider hardening evidence gate and controlled DashScope LLM/TTS/ASR probe.
- MVP system E2E suites used as the end-to-end regression surface for product baseline flows.

Commands run:
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_planner_test.dart test/features/training/training_hint_ladder_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_pressure_check_test.dart test/features/training/training_evidence_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_scope_boundary_test.dart` - passed.
- `python3 scripts/check_manual_external_evidence_plan.py && python3 scripts/check_ai_provider_sandbox_evidence.py && python3 scripts/check_provider_sandbox_evidence.py && python3 scripts/check_store_submission_evidence.py && python3 scripts/check_commercial_copy_contract.py` - passed in non-strict mode; reported expected missing external evidence refs.
- `SPEAKEASY_AI_PROVIDER=deterministic DASHSCOPE_API_KEY= JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,ProductionAsrMediaRefTest,PersistentTtsCacheTest,AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,AccountDeletionLearningDataTest,DashScopeProviderGatewayTest,DashScopeProviderGatewayIntegrationTest,ProviderGatewaySecurityContractTest test` - passed.
- `SPEAKEASY_AI_PROVIDER=deterministic DASHSCOPE_API_KEY= JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AppleSubscriptionVerificationTest,GoogleSubscriptionVerificationTest,SubscriptionCredentialValidationTest,SubscriptionRestoreTest,SubscriptionRestoreEmptyTest,EntitlementGateServiceTest,UsageQuotaGateTest,CommercialAccountDeletionProcessorTest,UsageReservationLifecycleTest,CommercialAbuseControlTest,AiCostDashboardTest test` - passed after updating the stale account-deletion audit assertion to count `account_deletion_completed` events.
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart test/features/commercial/entitlement_downgrade_widget_test.dart test/features/commercial/account_deletion_cleanup_test.dart` - passed.
- `flutter test integration_test/commercial_boundary_test.dart` - passed.
- `npm run check:api-contract` - passed: OpenAPI valid, 68 paths, 73 operations, 32 request examples, 68 success examples, 83 error examples, generated Dart drift hash `044c58f6d5d0c4db06e3f07002afca75d38846b9240f9d3313c066e2d2bbba56`.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite smoke` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite scene-catalog` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite learning-memory` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite practice-feedback` - passed after forcing the E2E backend to deterministic provider by default.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite profile-settings` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite membership-boundary` - passed after scrolling explicitly to the restore-purchases button.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/run_mvp_system_e2e.sh --suite commercial-boundary` - passed.
- Sanitized inline DashScope provider probe using the configured `DASHSCOPE_API_KEY` - passed: LLM `qwen-plus` returned `http=200` with content, TTS `qwen3-tts-flash` returned `http=200` with audio URL present, ASR `paraformer-v2` submit returned `http=200` with task id, ASR poll returned `SUCCEEDED` with result/transcript URL present.

Passing tests:
- TC-P01-001 through TC-P01-012 remain passed on the P0.1 local training-agent core.
- TC-P01-015 through TC-P01-020 remain passed on the backend AI provider adapter/security/usage boundary.
- TC-COM-001 through TC-COM-011, TC-COM-013, TC-COM-014, TC-COM-016 through TC-COM-018, TC-COM-020 and TC-COM-023 remain passed at the implemented local boundary.
- TC-COM-AI-001 through TC-COM-AI-003 and TC-COM-AI-005 through TC-COM-AI-007 remain passed locally.
- TC-COM-AI-004 no longer has an `invalid_api_key` blocker for controlled live sanity; strict release closure still requires `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` and independent external review.

Failing or blocked tests:
- No local automated test remains failing after the E2E script and stale account-deletion assertion fixes.
- Superseded 2026-06-03: TC-P01-013 now passes via `./scripts/run_mvp_system_e2e.sh --suite p0-1-training-loop`.
- Superseded 2026-06-03: TC-P01-014 now passes via `dart run scripts/check_ai_eval_cases.dart`.
- TC-COM-012, TC-COM-015, TC-COM-019, TC-COM-021 and TC-COM-022 remain external/native/store/release blockers.

Skipped or external tests:
- Apple sandbox, Google Play internal track, native social-login, store metadata/reviewer account/privacy/support, signing/symbol upload and rollback evidence were not executed locally.
- Full DashScope evidence matrix review, object-storage lifecycle evidence, production cost dashboard screenshots/alert approval and production retention/privacy evidence refs remain external release gates.

Acceptance criteria coverage:
- Local implementation coverage for P0.1 and P0 commercial automated boundaries remains green.
- Controlled live LLM/TTS/ASR sanity closes the previous credential-validity blocker only; it does not replace the TC-COM-AI-004 strict external evidence requirement.

Residual risk:
- Commercial release remains blocked until strict external/native/store/release evidence refs are supplied and independently reviewed.
- Superseded 2026-06-03: the prior TC-P01-013/014 local blockers are closed; P0.1 completion now depends on PM acceptance of the updated traceability and any explicit non-goal decisions.
- E2E logs still show non-blocking macOS notification initialization and `/user/stats` refresh warnings.

## 2026-06-02 P0-AI External Gate Recheck And TTS Cache Multi-Owner Tests

Test scope:
- Increment `commercial-ai-provider-hardening`.
- Requested five residual-risk gates: DashScope sandbox, object storage media lifecycle, cost dashboard/budget alerts, retention/privacy deletion proof and TTS cache multi-tenant policy.
- Test cases TC-COM-AI-001 through TC-COM-AI-007.

Commands run:
- Earlier same-day sanitized DashScope probe returned `invalid_api_key`; this was superseded by `P0-P01-BLOCKER-RETEST-20260602`, where the configured key produced successful LLM/TTS/ASR controlled live sanity results.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,ProductionAsrMediaRefTest,AiRetentionPolicyTest test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,AccountDeletionLearningDataTest test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiAccountDeletionMediaCleanupTest,AiRetentionPolicyTest,PersistentTtsCacheTest,AiCostDashboardTest,FoundationMigrationTest test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PostgresFoundationMigrationTest test` from `backend/` - passed.

Passing tests:
- TC-COM-AI-001 and TC-COM-AI-002 local backend media upload/ref and ASR guard tests passed.
- TC-COM-AI-005 cost dashboard tests passed for sanitized aggregation, OPS-only access, budget warning and provider anomaly.
- TC-COM-AI-006 and TC-COM-AI-007 retention/account deletion tests passed.
- TC-COM-AI-007 now includes shared TTS cache owner refs: deleting the first owner leaves the shared cache active, clears the legacy first-owner hash and removes that owner ref; deleting the final owner marks the cache entry deleted and removes owner refs.
- PostgreSQL migration validation applied `V202606020001__commercial_ai_tts_cache_owners.sql` successfully.

Failing or blocked tests:
- TC-COM-AI-004 strict release gate remains open because `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` and independent external evidence review are not supplied. The earlier `invalid_api_key` symptom is closed by the later controlled live probe.

Skipped or external tests:
- Real object storage bucket/CDN/KMS upload/read/lifecycle deletion was not executed because no object-storage credentials or evidence ref are configured in the local environment.
- Production PM/Ops dashboard screenshots, threshold approval and alert destination proof were not executed because no production evidence ref is configured.
- Approved privacy/retention policy evidence and real object-store deletion proof were not supplied.

Acceptance criteria coverage:
- AC-COM-AI-001, AC-COM-AI-004 and AC-COM-AI-005 retain local automated evidence.
- AC-COM-AI-002 has stronger local evidence for multi-owner TTS cache deletion semantics.
- AC-COM-AI-003 has controlled live credential sanity for LLM/TTS/ASR, but remains blocked for release until full matrix evidence and `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` are supplied.

Residual risk:
- Paid AI voice release remains blocked by missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`, `AI_MEDIA_STORAGE_EVIDENCE_REF`, `AI_COST_DASHBOARD_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF`.

## 2026-06-01 - P0.1 Backend AI Provider Gateway Test Report

Test scope:
- Increment `docs/product/increments/p0-1-expression-automation-training/`.
- Change request `CR-20260601-001`: keep current Spring Boot backend and add DashScope LLM/TTS/ASR adapter behind `AiProviderGateway`.
- Test cases TC-P01-015 through TC-P01-020.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=DashScopeProviderGatewayTest,DashScopeProviderGatewayIntegrationTest,ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,FeedbackFailureHandlingTest,CommercialAbuseControlTest,UsageQuotaGateTest test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run lint:openapi` - passed.
- `PYTHONPATH=.uv-cache/archive-v0/6TiI4tLkyvVElUd4WZMLn/lib/python3.11/site-packages python3 scripts/check_openapi_contract.py` - passed.
- `PYTHONPATH=.uv-cache/archive-v0/6TiI4tLkyvVElUd4WZMLn/lib/python3.11/site-packages python3 scripts/check_openapi_dart_drift.py` - passed.
- `npm run check:api-contract` - blocked by local `uv run --with PyYAML` runtime panic after OpenAPI lint passed; the same OpenAPI contract and Dart drift scripts passed through the local PyYAML cache path above.

Passing tests:
- TC-P01-015: `DashScopeProviderGatewayTest` verifies DashScope ASR/TTS/LLM model config and adapter routing while deterministic remains the default provider unless `speakeasy.ai.provider=dashscope`.
- TC-P01-016: `DashScopeProviderGatewayTest` and `DashScopeProviderGatewayIntegrationTest` verify local-path ASR is rejected before provider transport in production DashScope mode, unsigned HTTP refs are rejected before provider transport, over-duration signed audio is rejected before provider transport, and valid backend-signed provider-accessible media refs return transcript/status.
- TC-P01-017: `DashScopeProviderGatewayTest` and integration coverage verify TTS cache by text/model/voice avoids duplicate provider calls in the current process.
- TC-P01-018: `DashScopeProviderGatewayTest` and integration coverage verify strict LLM JSON maps to coach feedback, while invalid enum, missing required field, out-of-range score, unsupported extra field and banned final-mastery/entitlement fields fall back to recoverable feedback.
- TC-P01-019: `DashScopeProviderGatewayIntegrationTest`, `CommercialAbuseControlTest`, and `UsageQuotaGateTest` verify current AI REST uses the adapter, usage reservation/commit/release remains active, free/pro/enterprise policy is server-derived from entitlement snapshots, text/audio thresholds differ by tier, client `provider_tier` cannot override server facts, and policy telemetry includes tier/cost metadata.
- TC-P01-020: `ProviderGatewaySecurityContractTest` and `DashScopeProviderGatewayIntegrationTest` verify clients cannot submit `provider_secret` or `provider_tier`, provider responses/telemetry do not expose provider secrets or full learner transcript payloads, and usage audit does not persist full signed audio URLs.

Failing tests:
- None remaining.

Skipped or unavailable tests:
- No live DashScope request was executed; tests use fake DashScope transport and a test API key.
- Backend/object-storage upload lifecycle for ASR media refs is not implemented in this slice; current executable boundary uses backend-signed media metadata and rejects unsigned HTTP refs.
- Persistent TTS media cache and production retention/deletion execution are not implemented in this slice.

Acceptance criteria coverage:
- AC-P01-013 has local automated evidence for DashScope provider selection, adapter replaceability, ASR guard, TTS cache, LLM schema fallback, usage/tier controls, telemetry and no-secret contract.
- AC-P01-013 is partial, not release-complete, until live provider and persistent media-storage evidence are supplied.

Residual risk:
- `P01-GAP-008` is Partial, not Closed.
- Current TTS cache is process-local; restart or multi-instance deployments need persistent cache/object storage before commercial release.
- ASR accepts backend-signed provider-accessible `audio_ref` URLs and rejects unsafe or unsigned refs, but the Flutter upload-to-backend/object-storage lifecycle remains downstream.
- Combined `npm run check:api-contract` currently fails on a local `uv` runtime panic unrelated to OpenAPI content; direct lint, contract and drift subchecks passed.

## 2026-06-01 - P0 Commercial AI Provider Hardening Planning Validation

Test scope:
- Increment `docs/product/increments/commercial-ai-provider-hardening/`.
- Planning coverage for object-storage media upload, persistent TTS cache, real DashScope sandbox evidence, AI cost dashboard and production AI data strategy.
- Test cases TC-COM-AI-001 through TC-COM-AI-007 are created as planned IDs; no implementation tests have executed.

Commands run:
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `python3 scripts/check_provider_sandbox_evidence.py` - passed and reported existing Apple/Google external evidence blockers for TC-COM-019.

Passing checks:
- Manual external evidence checklist remains structurally valid after adding TC-COM-AI-004.
- Project agent validation passed.
- Whitespace/diff check passed.
- Existing payment provider sandbox evidence matrix script still passes in non-strict mode.

Planned tests:
- TC-COM-AI-001: trusted media upload/reference.
- TC-COM-AI-002: production ASR media ref guard.
- TC-COM-AI-003: persistent TTS cache.
- TC-COM-AI-004: DashScope LLM/ASR/TTS sandbox or controlled live evidence.
- TC-COM-AI-005: AI cost dashboard.
- TC-COM-AI-006: AI retention policy.
- TC-COM-AI-007: account deletion media/cache cleanup.

Residual risk:
- All TC-COM-AI implementation and external evidence remains planned/open.
- `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`, `AI_MEDIA_STORAGE_EVIDENCE_REF`, `AI_COST_DASHBOARD_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF` are not supplied.

## 2026-06-01 - P0.1 Training Agent Core Test Report

Test scope:
- Increment `docs/product/increments/p0-1-expression-automation-training/`.
- Training Agent deterministic planner, action chain, micro-action state, hint ladder, pressure check, feedback schema validation, learning evidence candidate filtering, recoverable failures, scope boundary, and lightweight training session widget surface.
- Test cases TC-P01-001 through TC-P01-012.

Commands run:
- `dart format lib/features/training/training_agent.dart lib/features/training/training_session_view.dart test/features/training/training_test_helpers.dart test/features/training/training_entry_test.dart test/features/training/training_planner_test.dart test/features/training/training_hint_ladder_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_pressure_check_test.dart test/features/training/training_evidence_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_scope_boundary_test.dart` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_planner_test.dart test/features/training/training_hint_ladder_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_pressure_check_test.dart test/features/training/training_evidence_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_scope_boundary_test.dart` - first failed on a missing `hintLevel` argument in the recap decision branch; passed after fix.
- Same `flutter test ...training_*.dart` command rerun after independent review corrections for blank scene ids and malformed schema field types - passed.
- `flutter analyze lib/features/training/training_agent.dart lib/features/training/training_session_view.dart test/features/training/training_entry_test.dart test/features/training/training_planner_test.dart test/features/training/training_hint_ladder_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_pressure_check_test.dart test/features/training/training_evidence_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_scope_boundary_test.dart` - passed with no issues.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-P01-001: `training_entry_test.dart` verifies official scene session creation/resume, unsupported-scene rejection, blank scene rejection, and unavailable/ready widget states.
- TC-P01-002, TC-P01-003, TC-P01-004: `training_planner_test.dart` verifies fixed local action chain mapping, one active micro-action, retry/hint decisions, ASR text fallback, and score-unavailable continuation.
- TC-P01-005: `training_hint_ladder_test.dart` verifies hint escalation, lower scaffold after success, and model-then-retry at high support.
- TC-P01-006: `training_voice_flow_test.dart` verifies spoken micro-action controls and playback recovery.
- TC-P01-007: `training_text_fallback_test.dart` verifies ASR fallback and voice-first default behavior.
- TC-P01-008: `training_feedback_schema_test.dart` verifies valid feedback candidates and rejects unsupported scenes, invalid next actions, malformed field types, final mastery writes, billing fields, and unsafe recoverable-error signals.
- TC-P01-009: `training_pressure_check_test.dart` verifies consecutive-success pressure check, pressure pass advancement, and pressure failure retry with higher hint.
- TC-P01-010: `training_evidence_test.dart` verifies recap retention and deterministic filtering of learning evidence candidates.
- TC-P01-011: `training_recoverable_failure_test.dart` verifies recoverable service-failure state and retry/continue exits.
- TC-P01-012: `training_scope_boundary_test.dart` verifies only two official scenes, arbitrary-scene rejection, in-session pressure check, and no final mastery/entitlement fields.

Failing tests:
- None remaining.
- Initial P0.1 test run failed at compile time because the recap decision branch did not pass `hintLevel` into `_decision`; fixed in `lib/features/training/training_agent.dart`.

Skipped or unavailable tests:
- Superseded 2026-06-03: TC-P01-013 integration loop is now implemented as a dedicated P0.1 training route and system E2E suite.
- Superseded 2026-06-03: TC-P01-014 AI eval execution is now covered by `scripts/check_ai_eval_cases.dart` and `tests/ai_runtime/p0_1_ai_eval_cases.json`.
- Live ASR/TTS/LLM/scoring providers were not called; P0.1 tests use deterministic local states and schema fixtures.

Acceptance criteria coverage:
- AC-P01-001 through AC-P01-012 now have executed unit/widget/contract/release-check evidence for the Training Agent core.
- This is not a full P0.1 completion pass because route integration, end-to-end training loop, and document-level AI eval execution remain planned.

Residual risk:
- `training_session_view.dart` is a reusable rendering surface and is not yet connected to the existing `interview_practice_page.dart` production entry.
- The deterministic planner is local-first; no backend sync or repository-backed persistence was added, so API contract P01-GAP-005 remains conditional.
- Full audio capture/transcription provider behavior still depends on existing app services and requires downstream integration tests.

## 2026-05-29 - P0-COM-MANUAL-EVIDENCE-PLAN-001 Manual External Evidence Plan

Test scope:
- TC-COM-012 / AC-COM-009 / COM-TR-005 and COM-TR-012.
- TC-COM-015 / AC-COM-011 / COM-TR-009.
- TC-COM-019 / AC-COM-013 / COM-TR-011.
- TC-COM-021 and TC-COM-022 / AC-COM-014 / COM-TR-012.
- Structure gate for the manual checklist and release readiness integration.

Commands run:
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/check_commercial_copy_contract.py` - passed; reported missing `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL`, and `SUPPORT_URL` as release blockers.
- `python3 scripts/check_provider_sandbox_evidence.py` - passed; reported missing `APPLE_SANDBOX_EVIDENCE_REF` and `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` as release blockers.
- `python3 scripts/check_store_submission_evidence.py` - passed; reported missing `STORE_METADATA_EVIDENCE_REF`, `REVIEWER_ACCOUNT_REF`, `PRIVACY_URL`, and `SUPPORT_URL` as release blockers.
- `python3 -m py_compile scripts/check_manual_external_evidence_plan.py scripts/check_provider_sandbox_evidence.py scripts/check_store_submission_evidence.py scripts/check_commercial_copy_contract.py` - passed.
- `bash -n scripts/check_release_readiness.sh` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, provider/store/reviewer/symbol/rollback evidence refs, privacy URL, support URL, Sentry and Android signing vars - passed.
- Same fixture `scripts/check_release_readiness.sh` in strict mode - failed as expected on native iOS WeChat URL scheme and Apple Sign In entitlement.

Passing tests:
- Manual evidence checklist structure covers TC-COM-012, TC-COM-015, TC-COM-019, TC-COM-021 and TC-COM-022.
- Result template includes execution ID, executor, date, environment, build, account/vault ref, evidence ref, expected result, actual result, blocker reason, reviewer and review result.
- Release readiness now validates the manual evidence plan before copy/provider/store/native/release gates.

Failing tests:
- Strict release readiness fixture still fails on current native iOS social-login blockers, as expected.

Skipped or external tests:
- Real Apple sandbox, Google Play internal test, App Store Connect, Play Console, public privacy/support pages, reviewer account, symbol upload and rollback rehearsal were not executed in this local documentation/gate step.

Acceptance criteria coverage:
- AC-COM-009, AC-COM-011, AC-COM-013 and AC-COM-014 now have detailed manual execution procedures for their remaining external/native blockers.
- This is not a pass result for those ACs; it is a ready-to-execute manual evidence plan.

Residual risk:
- TC-COM-012, TC-COM-015, TC-COM-019, TC-COM-021 and TC-COM-022 remain release blockers until actual results are filled, evidence refs are supplied and independent review approves them.

## 2026-05-26 - PB-P0-BE-001A Backend/DB Foundation Test Report

Test scope:
- Spring Boot backend skeleton and dependency wiring.
- Flyway baseline migration for Product Base and P0 commercial foundation tables.
- Real PostgreSQL 15 migration execution through Testcontainers.
- Minimal P0 commercial API surface already present in `docs/architecture/openapi/speakeasy-api.yaml`: `/subscription/plans`, `/entitlements`, `/usage/summary`, `/user/me`, `/admin/release-health`.
- OpenAPI contract and Dart client pre-generation drift gate.

Commands run:
- `docker version` - passed after Docker Desktop was started; server version 29.0.1.
- `mvn test -Dtest=PostgresFoundationMigrationTest` from `backend/` - first failed with Testcontainers 1.19.8 / Docker Engine 29 compatibility; passed after pinning Testcontainers 2.0.5.
- `mvn test` from `backend/` - passed after dependency download approval, one test cleanup fix, one DTO contract assertion fix, and PostgreSQL Testcontainers addition.
- `npm.cmd run check:api-contract` from repository root - passed.

Passing tests:
- `com.speakeasy.FoundationMigrationTest.pbP0FoundationTablesExist` verifies the migration creates `user_accounts`, `auth_identities`, `user_profiles`, `onboarding_assessments`, `learning_routes`, `scenarios`, `scenario_versions`, `scenario_levels`, `target_expressions`, `subscription_plans`, `purchases`, `subscriptions`, `entitlement_snapshots`, `usage_ledgers`, `usage_reservations`, `payment_provider_events`, `account_deletion_jobs`, and `audit_logs`.
- `com.speakeasy.PostgresFoundationMigrationTest.pbP0FoundationMigrationAppliesOnPostgres` verifies the Flyway baseline applies successfully to PostgreSQL 15.17 and creates the required foundation tables.
- `com.speakeasy.CommercialFoundationControllerTest.listSubscriptionPlansReturnsOpenApiShapedResponse` covers FR-COM-001 and FR-COM-009 response shape for `/subscription/plans`.
- `com.speakeasy.CommercialFoundationControllerTest.getEntitlementsReturnsLatestSnapshot` covers FR-COM-001, FR-COM-006, and FR-COM-007 foundation response shape for `/entitlements`, including explicit `features` and `generated_at` DTO fields.
- `com.speakeasy.CommercialFoundationControllerTest.getUsageSummaryReturnsLedger` covers FR-COM-010 / AC-COM-012 foundation response shape for `/usage/summary`.
- `com.speakeasy.CommercialFoundationControllerTest.requestAccountDeletionCreatesJob` covers FR-COM-008 / AC-COM-010 foundation behavior for `DELETE /user/me`, including the OpenAPI top-level `deletion_job_id`, `status`, and `requested_at` fields.
- `com.speakeasy.CommercialFoundationControllerTest.releaseHealthRemainsWarningUntilProviderAndReleaseGatesExist` covers FR-COM-011 and FR-COM-012 release-health warning behavior for unfinished provider/release gates.
- `npm.cmd run check:api-contract` passed Redocly lint, OpenAPI contract examples, and Dart client pre-generation drift gate.

Failing tests:
- None remaining.
- During implementation, the first real `mvn test` run failed because `CommercialFoundationControllerTest` deleted `user_accounts` before `account_deletion_jobs`. The test setup now deletes deletion jobs first.
- During DTO contract hardening, one test still asserted the old nested `deletion_job.status` shape. The test now asserts the OpenAPI top-level account deletion response shape.
- During PostgreSQL validation, the first Testcontainers run failed because Spring Boot dependency management selected Testcontainers 1.19.8, which did not connect cleanly to Docker Engine 29. The backend now pins Testcontainers 2.0.5 modules.

Skipped or unavailable tests:
- Provider verification tests for Apple/Google purchase validation, restore, webhooks, refund/expiry, and production secrets are not part of PB-P0-BE-001A.
- Flutter/generated Dart client integration tests are not part of PB-P0-BE-001A.

Acceptance criteria coverage:
- Product Base FR-001, FR-002, FR-003, FR-005, FR-006, FR-008, FR-010 are covered at foundation persistence level through migration table assertions; user-facing Product Base flows remain covered by existing Flutter evidence in Product Base traceability.
- FR-COM-001 / AC-COM-001, AC-COM-005, AC-COM-006 are partially covered by subscription/entitlement persistence and read endpoints; real purchase verification and refresh remain follow-up.
- FR-COM-006 / AC-COM-006 and FR-COM-007 / AC-COM-007 are covered only as entitlement snapshot/read foundation, not full gating enforcement.
- FR-COM-008 / AC-COM-010 is covered by deletion job creation foundation, not full cloud data deletion/anonymization execution.
- FR-COM-010 / AC-COM-012 is covered by usage ledger read foundation, not reserve/commit/release enforcement.
- FR-COM-011 / AC-COM-013 and FR-COM-012 / AC-COM-014 are covered by release-health warning behavior, not final release checklist approval.

Residual risk:
- This is a backend/database foundation slice. It is suitable as the next dependency layer, but not sufficient for production commercial launch.
- Auth, authorization, provider secrets, payment provider calls, webhook signature verification, generated Dart client wiring, and Flutter membership/entitlement UI integration remain downstream work.

## 2026-05-27 - PB-P0-BE-001B Auth/Security + User Identity Boundary Test Report

Test scope:
- Spring Security stateless bearer-token baseline.
- Opaque access/refresh session persistence through `auth_sessions`.
- Minimal `/auth/login/phone`, `/auth/login/apple`, `/auth/login/wechat`, `/auth/refresh`, and `/auth/logout` behavior.
- `GET/PATCH/DELETE /user/me` current-user binding.
- `/entitlements` and `/usage/summary` authenticated-user binding and removal of production `X-User-Id` reliance.
- H2 and PostgreSQL migration validation for the new auth session table.
- OpenAPI contract and Dart client pre-generation drift gate.

Commands run:
- `mvn.cmd -q "-Dtest=AuthServiceTest,AuthControllerTest,CommercialFoundationControllerTest,FoundationMigrationTest" test` from `backend/` - first failed because one seeded test token used a fixed 2026-05-26 timestamp and was expired on 2026-05-27; passed after the fixture used current time.
- `mvn.cmd test` from `backend/` - passed after QA gap fixes, 19 tests, 0 failures, 0 errors.
- `npm.cmd run check:api-contract` from repository root - passed.

Passing tests:
- `com.speakeasy.AuthControllerTest.getMeRequiresBearerToken` verifies protected current-user API returns `UNAUTHENTICATED` without bearer auth.
- `com.speakeasy.AuthControllerTest.patchAndDeleteMeRequireBearerToken` verifies `PATCH /user/me` and `DELETE /user/me` reject unauthenticated requests with shared error schema.
- `com.speakeasy.AuthControllerTest.loginAndGetMeBindToCurrentUser` verifies phone login issues tokens and `GET /user/me` uses the token user while ignoring `X-User-Id`.
- `com.speakeasy.AuthControllerTest.patchMeUpdatesAuthenticatedUserProfile` verifies authenticated `PATCH /user/me` updates display name, level, daily minutes, and reminder fields.
- `com.speakeasy.AuthControllerTest.refreshRotatesTokenAndLogoutRevokesSession` verifies refresh rotation invalidates the previous access token, the new token works, logout returns 204, and the logged-out token is rejected.
- `com.speakeasy.AuthControllerTest.refreshRejectsInvalidToken` verifies invalid refresh tokens return `UNAUTHENTICATED`.
- `com.speakeasy.AuthControllerTest.loginRejectsUnsupportedSchemaVersion` verifies runtime request validation rejects unsupported `schema_version` values.
- `com.speakeasy.AuthServiceTest.loginCreatesRefreshableSessionBoundToUser` verifies service-level login, token authentication, refresh rotation, and old access token invalidation.
- `com.speakeasy.AuthServiceTest.logoutRevokesCurrentSession` verifies service-level logout revokes access.
- `com.speakeasy.AuthServiceTest.loginRejectsMissingTerms` verifies terms gating in the login substitute.
- `com.speakeasy.CommercialFoundationControllerTest.getEntitlementsReturnsLatestSnapshot` verifies entitlement lookup uses authenticated user identity and ignores `X-User-Id`.
- `com.speakeasy.CommercialFoundationControllerTest.getUsageSummaryReturnsLedger` verifies usage summary lookup uses authenticated user identity.
- `com.speakeasy.CommercialFoundationControllerTest.requestAccountDeletionCreatesJob` verifies authenticated account deletion creates a job.
- `com.speakeasy.CommercialFoundationControllerTest.entitlementSummaryRequiresAuthentication` verifies unauthenticated entitlement access is rejected.
- `com.speakeasy.CommercialFoundationControllerTest.usageSummaryRequiresAuthentication` verifies unauthenticated usage summary access is rejected.
- `com.speakeasy.FoundationMigrationTest.pbP0FoundationTablesExist` verifies H2 migration includes `auth_sessions`.
- `com.speakeasy.PostgresFoundationMigrationTest.pbP0FoundationMigrationAppliesOnPostgres` verifies Flyway migrations, including `auth_sessions`, apply to PostgreSQL 15.17 through Testcontainers.

Failing tests:
- None remaining.

Skipped or unavailable tests:
- Real Apple/WeChat login provider verification is not implemented in this slice.
- Apple/Google subscription verify/restore, webhooks, refund/expiry downgrade, usage reserve/commit/release, generated Dart client, and Flutter integration are outside PB-P0-BE-001B.

Acceptance criteria coverage:
- Product Base FR-001 / Flow-002 is covered for server-side login/session/logout baseline, not real social-provider verification.
- Product Base FR-010 / AC-011 is covered for authenticated current-user profile read/update and account deletion job creation/session revocation.
- P0 FR-COM-004 / AC-COM-008 is covered for removing production `X-User-Id` identity substitution from protected backend paths.
- P0 FR-COM-001, FR-COM-006, FR-COM-007 are covered for authenticated entitlement read foundation, not full entitlement refresh/gating.
- P0 FR-COM-010 / AC-COM-012 is covered for authenticated usage summary read foundation, not reserve/commit/release.

Residual risk:
- This slice is an auth/security boundary baseline, not production social login or payment verification.
- Full account deletion processing and commercial release health gates remain downstream.

## 2026-05-29 - mvp-backend-foundation-auth Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-foundation-auth/`.
- Stage Scope Items MVP-SI-001 and MVP-SI-002.
- Acceptance criteria AC-MVP-BE-001 and AC-MVP-BE-002.
- Test cases TC-MVP-BE-001 through TC-MVP-BE-006.
- Backend foundation migrations, OpenAPI-shaped success DTOs, shared error schema, auth/current-user behavior, session lifecycle, OpenAPI contract gate, Dart pre-client drift gate, and Flutter auth service compatibility.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest,FoundationResponseContractTest,FoundationErrorContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest" test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: OpenAPI lint, OpenAPI contract gate, and Dart pre-client drift gate.
- `flutter test test/services/auth_service_test.dart` from repository root - passed.

Passing tests:
- TC-MVP-BE-001: `FoundationMigrationTest` and `PostgresFoundationMigrationTest` verify H2 and PostgreSQL-compatible Flyway migrations create the foundation/auth schema.
- TC-MVP-BE-002: `FoundationResponseContractTest` verifies auth, current-user, and subscription-plan responses do not expose raw persistence fields.
- TC-MVP-BE-003: `FoundationErrorContractTest` verifies validation, malformed JSON, and unauthenticated errors use stable shared error contracts and do not expose stack traces.
- TC-MVP-BE-004: `AuthControllerTest` and `AuthServiceTest` verify login, refresh, logout, and current-user/profile behavior.
- TC-MVP-BE-005: `AuthSessionLifecycleTest` verifies expired access rejection, expired refresh rejection, token rotation, and user-wide session revocation.
- TC-MVP-BE-006: `npm run check:api-contract` and `flutter test test/services/auth_service_test.dart` verify OpenAPI/Dart-safe drift and Flutter auth service compatibility.

Failing tests:
- None remaining.

Skipped or unavailable tests:
- None in this machine's final validation path.
- `PostgresFoundationMigrationTest` is designed to skip only when neither Docker nor local PostgreSQL binaries are available; this machine used the local PostgreSQL fallback successfully.

Acceptance criteria coverage:
- AC-MVP-BE-001 is fully covered by TC-MVP-BE-001, TC-MVP-BE-002, and TC-MVP-BE-003.
- AC-MVP-BE-002 is fully covered by TC-MVP-BE-004, TC-MVP-BE-005, and TC-MVP-BE-006.
- Increment traceability rows MVP-BE-TR-001 and MVP-BE-TR-002 cite the same TC IDs, script paths, execution commands, result status, and this report.

Residual risk:
- This pass covers only `mvp-backend-foundation-auth`. It is not a pass for onboarding/content, practice/AI, learning/memory, generated client integration, or commercial subscription expansion.
- Real provider verification for Apple/WeChat remains out of scope for this increment.

## 2026-05-29 - mvp-backend-onboarding-content Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-onboarding-content/`.
- Stage Scope Items MVP-SI-003, MVP-SI-004, and MVP-SI-005.
- Acceptance criteria AC-MVP-BE-003, AC-MVP-BE-004, and AC-MVP-BE-005.
- Test cases TC-MVP-BE-007 through TC-MVP-BE-015.
- Onboarding assessment validation, learning route mapping, official scenario catalog/detail/level content, content seed/versioning, user scenario join/remove/current state, home summary, OpenAPI contract gate, Dart pre-client drift gate, full backend regression, and Flutter coordinator compatibility.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=OnboardingAssessmentControllerTest,LearningRouteMappingTest,OnboardingRouteResponseContractTest,ScenarioCatalogControllerTest,ScenarioContentControllerTest,ScenarioSeedVersioningTest,UserScenarioStateControllerTest,HomeSummaryControllerTest" test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: 50 paths, 55 operations, 28 request examples, 51 success examples, 61 error examples; Dart pre-client drift hash `d763f44d29ac60f85d953cf302db63f23acba77d711cdb86432e1489f6f284d9`.
- `flutter test test/application/home_cards_coordinator_test.dart test/application/scene_setup_coordinator_test.dart` from repository root - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-MVP-BE-007: `OnboardingAssessmentControllerTest` verifies missing goal, expression blocker, or output level fails validation.
- TC-MVP-BE-008: `LearningRouteMappingTest` verifies English interview maps to `job_interview`, onboarding/work communication maps to `onboarding_introduction`, and daily service creates no playable official scenario.
- TC-MVP-BE-009: `OnboardingRouteResponseContractTest` verifies completed assessment responses include OpenAPI-shaped assessment, learning route, and current scenario state fields.
- TC-MVP-BE-010: `ScenarioCatalogControllerTest` verifies the catalog exposes only the two Product Base official scenarios.
- TC-MVP-BE-011: `ScenarioContentControllerTest` verifies scenario detail and L1/L2/L3 level content, including deterministic errors for invalid level requests.
- TC-MVP-BE-012: `ScenarioSeedVersioningTest` verifies seeded content is readable and no Product Base out-of-scope scenario is introduced.
- TC-MVP-BE-013: `UserScenarioStateControllerTest` verifies join, remove, set-current, and level-change behavior update backend state and downstream summary inputs.
- TC-MVP-BE-014: `HomeSummaryControllerTest` verifies no-scenario and missing-review/weakness/session states return explicit default values.
- TC-MVP-BE-015: `home_cards_coordinator_test.dart` and `scene_setup_coordinator_test.dart` verify current Flutter home/scene coordinators remain compatible with backend-shaped service state.

Failing tests:
- None remaining.
- During implementation, the first full backend regression failed because older auth/foundation/commercial test cleanup deleted `user_accounts` before new onboarding child rows. The cleanup order is now shared/updated and the full backend suite passes.

Skipped or unavailable tests:
- Generated Dart client compilation and real Flutter API wiring are not part of this increment; the API gate remains in pre-client generation mode.
- Practice/AI session runtime, memory/weakness/review derivation, commercial membership, and release checks are outside this increment.

Acceptance criteria coverage:
- AC-MVP-BE-003 is fully covered by TC-MVP-BE-007, TC-MVP-BE-008, and TC-MVP-BE-009.
- AC-MVP-BE-004 is fully covered by TC-MVP-BE-010, TC-MVP-BE-011, and TC-MVP-BE-012.
- AC-MVP-BE-005 is fully covered by TC-MVP-BE-013, TC-MVP-BE-014, and TC-MVP-BE-015.
- `docs/product/increments/mvp-backend-onboarding-content/traceability.md` cites the same TC IDs, script paths, execution commands, result status, and this report.

Residual risk:
- This pass covers only `mvp-backend-onboarding-content`. It is not a pass for practice/AI, learning/memory, commercial membership, generated client integration, or release.
- Home summary default review/weakness/session fields are placeholders until later increments provide those data sources.

## 2026-05-29 - mvp-backend-practice-ai Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-practice-ai/`.
- Stage Scope Items MVP-SI-006, MVP-SI-008, and MVP-SI-009.
- Acceptance criteria AC-MVP-BE-006, AC-MVP-BE-008, and AC-MVP-BE-009.
- Test cases TC-MVP-BE-016 through TC-MVP-BE-025.
- Current supplement: TC-MVP-BE-047 and TC-MVP-BE-048 were added on 2026-06-09 for the AC-MVP-BE-008 Practice trusted `audio_ref` negative paths; see `MVP-PRACTICE-AUDIO-REF-BOUNDARY-20260609`.
- Provider gateway secret boundary, ASR/TTS/pronunciation/coach success and fallback behavior, session lifecycle, turn idempotency, completion summary, recoverable errors, score signal source/availability, OpenAPI contract gate, Dart pre-client drift gate, and full backend regression.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,ProviderGatewayAuthorizationTest,PracticeSessionLifecycleTest,PracticeTurnControllerTest,PracticeSessionCompletionTest,PracticeSessionRecoveryTest,CoachFeedbackContractTest,FeedbackFailureHandlingTest" test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: 50 paths, 55 operations, 28 request examples, 51 success examples, 61 error examples; Dart pre-client drift hash `e81fb612e399777241c2ab6cd2d965f972e9762cf76aaea76c94b5f71f18259c`.

Passing tests:
- TC-MVP-BE-016: `ProviderGatewaySecurityContractTest` verifies clients cannot submit `provider_secret` and server-side gateway works without client secrets.
- TC-MVP-BE-017: `ProviderGatewayControllerTest` verifies normalized ASR, TTS, pronunciation, and coach gateway success responses.
- TC-MVP-BE-018: `ProviderGatewayFailureTest` verifies invalid schema and unavailable transcription return fallback/recoverable results without pseudo success evidence.
- TC-MVP-BE-019: `ProviderGatewayAuthorizationTest` verifies unauthenticated requests and session mismatch do not invoke the provider adapter.
- TC-MVP-BE-020: `PracticeSessionLifecycleTest` verifies start/resume/get behavior and explicit new-session creation when resume is disabled.
- TC-MVP-BE-021: `PracticeTurnControllerTest` verifies valid turn persistence, feedback, session fetch, evidence candidate, and idempotent replay/conflict handling.
- TC-MVP-BE-022: `PracticeSessionCompletionTest` verifies complete returns summary payload and candidate input for learning-memory.
- TC-MVP-BE-023: `PracticeSessionRecoveryTest` verifies recoverable sessions resume and completed sessions are not returned as active recovery.
- TC-MVP-BE-024: `CoachFeedbackContractTest` verifies structured coach feedback, score signal source/availability, candidate-only evidence, and no mastery decision.
- TC-MVP-BE-025: `FeedbackFailureHandlingTest` verifies playback/TTS failure is typed and invalid provider output is not visible as successful feedback.

Failing tests:
- None remaining.

Skipped or unavailable tests:
- Real external provider integration tests are not part of this increment; the adapter is deterministic for contract and lifecycle validation.
- Learning-memory accepted evidence, commercial usage reservation, generated Dart client compilation, and release checks are outside this increment.

Acceptance criteria coverage:
- AC-MVP-BE-006 is fully covered by TC-MVP-BE-016, TC-MVP-BE-017, TC-MVP-BE-018, and TC-MVP-BE-019.
- AC-MVP-BE-008 is fully covered by TC-MVP-BE-020, TC-MVP-BE-021, TC-MVP-BE-022, TC-MVP-BE-023, and the 2026-06-09 TC-MVP-BE-047/048 trusted `audio_ref` negative regressions.
- AC-MVP-BE-009 is fully covered by TC-MVP-BE-024 and TC-MVP-BE-025.
- `docs/product/increments/mvp-backend-practice-ai/traceability.md` cites the same TC IDs, script paths, execution commands, result status, and this report.

Residual risk:
- This pass covers only `mvp-backend-practice-ai`. It is not a pass for learning/memory, commercial membership, generated client integration, or release.
- Real provider credentials, production retries, usage reservation accounting, and provider event audit hardening remain later slices.

## 2026-05-29 - mvp-backend-learning-memory Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-learning-memory/`.
- Stage Scope Items MVP-SI-007 and MVP-SI-010.
- Acceptance criteria AC-MVP-BE-007 and AC-MVP-BE-010.
- Test cases TC-MVP-BE-026 through TC-MVP-BE-032.
- Expression queue, queue ordering/dedupe, task completion progress, favorite idempotency/delete, evidence validation, mastery/review/wiki/history projections, OpenAPI contract gate, Dart pre-client drift gate, and full backend regression.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: 55 paths, 60 operations, 29 request examples, 55 success examples, 67 error examples; Dart pre-client drift hash `d677224d822630f0ca30bdcdd55b8c0793b778b7e8e8a65dbfa58f38be15886e`.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-MVP-BE-026: `ExpressionQueueControllerTest` verifies users without joined scenarios receive explicit `empty_no_scene` state and no queue items.
- TC-MVP-BE-027: `ExpressionQueueOrderingTest` verifies evidence-derived queue items outrank variants and stable target expression IDs are deduped.
- TC-MVP-BE-028: `ExpressionTaskProgressTest` verifies task completion persists attempt, evidence, progress, and mastery linkage.
- TC-MVP-BE-029: `FavoriteExpressionControllerTest` verifies duplicate favorite requests return the same favorite ID and delete removes the active favorite.
- TC-MVP-BE-030: `LearningEvidenceValidationTest` verifies low-confidence candidate evidence is rejected and does not update mastery.
- TC-MVP-BE-031: `LearningEvidenceProjectionTest` verifies accepted evidence projects into evidence list, mastery, review, personal wiki, history, and follow-up queue priority.
- TC-MVP-BE-032: `LearningHistoryWikiControllerTest` verifies wiki/history reflect accepted evidence and history deletion hides the history entry.

Failing tests:
- None remaining.
- During full-suite regression, an initial run exposed a delete-order issue between `learning_evidences` and evidence projection tables. The migration now uses `ON DELETE SET NULL` for derived evidence references, and the full backend suite passes.

Skipped or unavailable tests:
- Generated Dart client compilation and production Flutter service wiring are outside this increment; the API gate remains in pre-client generation mode.
- P0.2 cross-day review planning, full L0-L5 mastery ladder, commercial membership, and release checks are outside this increment.

Acceptance criteria coverage:
- AC-MVP-BE-007 is fully covered by TC-MVP-BE-026, TC-MVP-BE-027, TC-MVP-BE-028, and TC-MVP-BE-029.
- AC-MVP-BE-010 is fully covered by TC-MVP-BE-030, TC-MVP-BE-031, and TC-MVP-BE-032.
- `docs/product/increments/mvp-backend-learning-memory/traceability.md` cites the same TC IDs, script paths, execution commands, result status, and this report.

Residual risk:
- This pass covers only `mvp-backend-learning-memory`. It is not a pass for commercial membership, generated client integration, or release.
- Review scheduling remains MVP immediate-due behavior until the deferred long-term planner increment is opened.

## 2026-05-29 - mvp-backend-membership-boundary Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-membership-boundary/`.
- Stage Scope Items MVP-SI-011 and MVP-SI-012.
- Acceptance criteria AC-MVP-BE-011 and AC-MVP-BE-012.
- Test cases TC-MVP-BE-033 through TC-MVP-BE-038.
- Account deletion completion/status, session invalidation, Product Base learning/practice/profile cleanup, deletion failure audit visibility, MVP membership boundary, Android billing platform limit, report/offline/achievement placeholders, OpenAPI contract gate, Dart pre-client drift gate, and full backend regression.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples; Dart pre-client drift hash `506282ac758a37269df95e12ca6752de9c201eb162fd4cc0e227b13c287ab082`.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-MVP-BE-033: `AccountDeletionControllerTest` verifies authenticated account deletion completes a deletion job and returns completed state.
- TC-MVP-BE-034: `AccountDeletionSessionInvalidationTest` verifies previous access and refresh tokens fail after account deletion.
- TC-MVP-BE-035: `AccountDeletionLearningDataTest` verifies Product Base learning/practice/profile state is cleared, user status becomes `deleted`, and audit evidence is written.
- TC-MVP-BE-036: `AccountDeletionFailureAuditTest` verifies failed deletion job status exposes `failure_reason` and keeps audit evidence visible.
- TC-MVP-BE-037: `MvpMembershipBoundaryControllerTest` verifies membership boundary state and Android purchase/restore platform-limited responses.
- TC-MVP-BE-038: `MvpReportPlaceholderControllerTest` verifies learning report, offline content, and achievement endpoints return explicit placeholder states.

Failing tests:
- None remaining.

Skipped or unavailable tests:
- Real Android/iOS payment provider verification, webhook/refund/expiry, paid report generation, offline content package download, and achievement engine tests are outside this MVP boundary increment.
- Generated Dart client compilation and production Flutter service wiring remain the next client/QA/release increment; the API gate remains in pre-client generation mode.

Acceptance criteria coverage:
- AC-MVP-BE-011 is fully covered by TC-MVP-BE-033, TC-MVP-BE-034, TC-MVP-BE-035, and TC-MVP-BE-036.
- AC-MVP-BE-012 is fully covered by TC-MVP-BE-037 and TC-MVP-BE-038.
- `docs/product/increments/mvp-backend-membership-boundary/traceability.md` cites the same TC IDs, script paths, execution commands, result status, and this report.

Residual risk:
- This pass covers only `mvp-backend-membership-boundary`. It is not a pass for generated Dart client integration or release readiness.
- Production deletion of external object-store raw media/transcript refs and full retention operations remain separate DevOps/Security work.

## 2026-05-29 - mvp-backend-client-qa-release Gap Closure Test Report

Test scope:
- Increment `docs/product/increments/mvp-backend-client-qa-release/`.
- Stage Scope Items MVP-SI-013 and MVP-SI-014.
- Acceptance criteria AC-MVP-BE-013 and AC-MVP-BE-014.
- Test cases TC-MVP-BE-039 through TC-MVP-BE-046.
- OpenAPI lint/contract, generated Dart drift, handwritten ApiClient exception tracking, Flutter active API drift tests, full backend regression, full Flutter regression, release checklist, version log, rollback plan, and stage traceability.

Commands run:
- `npm run check:api-contract` from repository root - passed: OpenAPI contract gate passed with 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples; Dart client drift gate passed in `generated_client_drift` mode with hash `506282ac758a37269df95e12ca6752de9c201eb162fd4cc0e227b13c287ab082`.
- `flutter test test/services/api_client_contract_test.dart test/services/auth_service_test.dart test/application/scene_voice_session_lifecycle_coordinator_test.dart test/application/home_cards_coordinator_test.dart` - passed.
- `rg -n "MVP-SI-" docs/product/stages/mvp-backend-foundation.md docs/product/increments/mvp-backend-*` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `flutter test` - passed, 173 tests.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-MVP-BE-039: `npm run check:api-contract` verifies OpenAPI lint, operation/request/response examples, traceability, and error response coverage.
- TC-MVP-BE-040: `scripts/check_openapi_dart_drift.py` verifies generated-client mode, `.openapi-sha256`, generated path coverage, Dart-safe operation/schema names, and handwritten ApiClient exceptions.
- TC-MVP-BE-041: `api_client_contract_test.dart`, `auth_service_test.dart`, `scene_voice_session_lifecycle_coordinator_test.dart`, and `home_cards_coordinator_test.dart` verify active Flutter API drift boundary and current active-flow compatibility.
- TC-MVP-BE-042: documented exception review accepts only listed legacy/provider/platform-limited paths in `dart-client-drift-manifest.json`; the drift gate fails on unlisted or unused exceptions.
- TC-MVP-BE-043: stage/increment traceability grep confirms MVP-SI-001 through MVP-SI-014 are represented across stage and increment artifacts.
- TC-MVP-BE-044: full backend Maven suite passes.
- TC-MVP-BE-045: full Flutter suite passes with 173 tests.
- TC-MVP-BE-046: release checklist, version log, rollback plan, and quality report carry release evidence and Product Object Governance status.

Failing tests:
- None remaining.

Skipped or accepted-exception tests:
- Full `dart-dio` DTO generation is not used; the committed generated boundary is a project-local OpenAPI path/contract registry guarded by hash/path drift checks.
- Legacy stats/freeform scene/role-memory/payment-provider helper paths are documented handwritten-client exceptions and are not silently counted as migrated MVP backend endpoints.
- External object-store retention, real payment provider production readiness, paid report generation, offline packages, and achievements require separate owning increments.

Acceptance criteria coverage:
- AC-MVP-BE-013 is fully covered by TC-MVP-BE-039, TC-MVP-BE-040, TC-MVP-BE-041, and TC-MVP-BE-042.
- AC-MVP-BE-014 is fully covered by TC-MVP-BE-043, TC-MVP-BE-044, TC-MVP-BE-045, and TC-MVP-BE-046.
- `docs/product/increments/mvp-backend-client-qa-release/traceability.md` cites the same TC IDs, script paths, execution commands, result status, evidence reports, and release evidence.

Residual risk:
- Stage release is ready with documented exceptions, not production commercial launch approval.
- Future full DTO codegen should replace the project-local path registry when the frontend migration budget is opened.

## 2026-05-29 - mvp-system-e2e-validation System E2E Deep Regression Test Report

Test scope:
- Increment `docs/product/increments/mvp-system-e2e-validation/`.
- Stage Scope Item MVP-SI-014 system E2E hardening.
- Acceptance criteria AC-MVP-E2E-001 through AC-MVP-E2E-004.
- Test cases TC-MVP-E2E-001 through TC-MVP-E2E-010 executed or explicitly accepted as external gate.
- Local desktop black-box path: Flutter macOS UI + Spring Boot backend + real local PostgreSQL 15.18.

Commands run:
- `scripts/run_mvp_system_e2e.sh` - passed. It initialized isolated PostgreSQL, started backend on a random local port, ran `integration_test/mvp_system_smoke_test.dart` on macOS, and preserved logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-97338`.
- `scripts/run_mvp_system_e2e.sh --suite scene-catalog` - passed; logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-98620`.
- `scripts/run_mvp_system_e2e.sh --suite learning-memory` - passed; logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-99913`.
- `scripts/run_mvp_system_e2e.sh --suite practice-feedback` - passed; logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-1490`.
- `scripts/run_mvp_system_e2e.sh --suite profile-settings` - passed; logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-2774`.
- `scripts/run_mvp_system_e2e.sh --suite membership-boundary` - passed; logs under `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-4371`.
- `python3 scripts/check_mvp_system_e2e_coverage.py` - passed: 10 TC rows, 13 Product Base AC rows, 4 traceability rows.
- `flutter test` - passed, 173 tests.
- `env JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Passing tests:
- TC-MVP-E2E-001: real-stack orchestration starts PostgreSQL/backend, applies backend startup/migration path, waits on `/v1/admin/release-health`, runs Flutter, and tears down.
- TC-MVP-E2E-002: Flutter UI starts without stored session, reaches login gate, accepts agreement, uses test phone login, and authenticates through the real backend.
- TC-MVP-E2E-003: onboarding completes through real Flutter UI clicks with deterministic choices and reaches home with learning scene content.
- TC-MVP-E2E-004: Product Base AC-001 through AC-013 all map to an executed TC, manual-external gate, or accepted exception.
- TC-MVP-E2E-005: TC rows include script path, command, result status, and evidence report.
- TC-MVP-E2E-006: scene catalog opens, `job_interview` scene can be joined, and listening warmup/mode toggle is reachable.
- TC-MVP-E2E-007: recommended expression queue appears, favorite action persists, and memory is visible through profile/favorites surfaces.
- TC-MVP-E2E-008: practice UI opens and deterministic backend provider returns coach feedback, provider status, recap fields, and evidence candidates.
- TC-MVP-E2E-009: profile edit, settings toggles, logout, relogin, onboarding bypass, and nickname/session persistence are verified.
- TC-MVP-E2E-010: membership plans, subscribe/restore boundary UI, and external payment exception are verified; real provider payment remains manual/external.

Defects found and fixed during system E2E hardening:
- Docker is not required for this local gate; the script now uses local PostgreSQL binaries, so a missing Docker daemon no longer skips the real PostgreSQL verification path.
- macOS integration build required deployment target 11.0; `macos/Podfile` and the Xcode project were aligned.
- Flutter login/onboarding needed stable test keys for deterministic UI driving.
- macOS app sandbox could not write Hive data into the host temp directory; E2E now uses an isolated Hive namespace under the app-accessible home path and disables SharedPreferences migration for the test run.
- Onboarding daily-goal cards used `Spacer` inside an unbounded scroll context; the card height is now fixed at 118 to prevent RenderFlex layout failure.
- Smoke helper initially accepted a partially initialized state as home-ready and briefly used a session shortcut for onboarding; helper assertions now wait on authenticated/onboarded home evidence, drive onboarding through the real UI, and include visible text diagnostics.
- Onboarding completion was not persisted through the backend because the client patched `/user/me` with unsupported `onboardingDone`; the app now submits `/onboarding/assessment` and uses PATCH `/user/me` with backend field names for profile edits.
- Several UI controls needed stable keys on the actual tappable/scrollable surfaces, including scene cards, profile settings, membership plans, placeholders, and favorites.
- Integration tests previously triggered Flutter's global error-hook warning; the E2E script now passes `SPEAKEASY_DISABLE_GLOBAL_ERROR_HOOKS=true`.

Residual risk:
- `/user/stats` still logs a non-blocking learning-stats refresh failure during E2E; the UI continues, but this is a real cross-layer compatibility risk for a future stats endpoint/client cleanup.
- macOS notification initialization still logs a soft failure in E2E because platform settings are not configured for local macOS tests.
- TC-MVP-E2E-008 deliberately uses deterministic backend/provider behavior; real LLM/ASR/TTS provider SLA and voice hardware remain external/manual gates.
- TC-MVP-E2E-010 verifies local membership boundary UI only; real payment provider purchase, webhook, refund, and restore completion remain manual/external release gates.

## 2026-05-29 - commercial-subscription-readiness Pre-Implementation Test Case Library

Test scope:
- Increment `docs/product/increments/commercial-subscription-readiness/`.
- Stage Scope Items COM-SI-001 through COM-SI-012.
- Acceptance criteria AC-COM-001 through AC-COM-014.
- Test case library `docs/product/increments/commercial-subscription-readiness/test_cases.md`.

Test design result:
- AC-to-TC mapping: passed for pre-implementation gate. AC-COM-001 through AC-COM-014 all map to stable TC IDs TC-COM-001 through TC-COM-023.
- Requirement-to-test mapping: passed for pre-implementation gate. FR-COM-001 through FR-COM-012 all map through accepted AC IDs to one or more TC IDs.
- Execution status: TC-COM-023 contract gate passed; TC-COM-001 through TC-COM-022 remain planned. No Backend, Frontend, AI Runtime or DevOps implementation was started in this step.

Commands run:
- `npm run check:api-contract` - passed outside sandbox after `uv` panicked in the sandboxed run. OpenAPI contract gate passed with 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples; Dart client drift passed with OpenAPI hash `4a0a9978ba4dec45d1df598bc0cd39770fd5eaa021fc6f7fe2ce47f16d0fb63a`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Coverage highlights:
- Purchase/restore/refund/expiry: TC-COM-001 through TC-COM-006 and TC-COM-019.
- Entitlement, gating and usage control: TC-COM-007 through TC-COM-010 and TC-COM-017 through TC-COM-018.
- Production login, social login and account deletion: TC-COM-011 through TC-COM-014.
- Commercial copy and release materials: TC-COM-015, TC-COM-016, TC-COM-021, TC-COM-022.
- OpenAPI contract gate: TC-COM-023 passed.

Manual or external gates:
- TC-COM-015: commercial copy review remains manual-verification.
- TC-COM-019: Apple sandbox and Google Play internal testing remain external-dependency.
- TC-COM-021: store material and privacy review remain manual-verification.

Residual risk:
- This closes the AC-to-TC implementation gate only. Commercial release readiness still requires implementation, executable tests, provider sandbox/internal evidence, DevOps release evidence, implementation report, quality report and PM release decision.

## 2026-05-29 - P0-COM-QA-002 Commercial Subscription QA Evidence

Test scope:
- Increment `docs/product/increments/commercial-subscription-readiness/`.
- Stage Scope Items COM-SI-001 through COM-SI-012.
- Requirements FR-COM-001 through FR-COM-012.
- Acceptance criteria AC-COM-001 through AC-COM-014.
- Automated backend provider/entitlement/usage/deletion tests, Flutter subscription/account deletion tests, OpenAPI contract gate, and release readiness scripts.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CommercialFoundationControllerTest,CommercialAccountDeletionProcessorTest,AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,EntitlementGateServiceTest,UsageQuotaGateTest,UsageReservationLifecycleTest,CommercialAbuseControlTest,ProviderGatewayControllerTest,ProviderGatewayAuthorizationTest,AppleSubscriptionVerificationTest,GoogleSubscriptionVerificationTest,SubscriptionCredentialValidationTest,SubscriptionRestoreTest,SubscriptionRestoreEmptyTest,PaymentProviderEventDowngradeTest test` from `backend/` - passed.
- `flutter test test/features/commercial/entitlement_downgrade_widget_test.dart test/features/commercial/account_deletion_cleanup_test.dart test/services/api_client_contract_test.dart` - passed.
- `npm run check:api-contract` - first failed in sandbox because `uv` panicked in macOS system configuration access; rerun outside sandbox passed with 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples, and Dart generated-client drift hash `4a0a9978ba4dec45d1df598bc0cd39770fd5eaa021fc6f7fe2ce47f16d0fb63a`.
- `bash -n scripts/check_release_configuration.sh scripts/check_social_login_release_config.sh scripts/check_release_readiness.sh` - passed.
- `APP_API_BASE_URL=https://api.speakeasyapp.com ENV=production ENABLE_TEST_PHONE_LOGIN=false scripts/check_release_configuration.sh` - passed.
- `WECHAT_APP_ID=wx1234567890abcdef WECHAT_UNIVERSAL_LINK=https://app.speakeasyapp.com/app/ scripts/check_social_login_release_config.sh --env-only` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, Sentry, Android signing, Apple/Google provider evidence refs, store metadata ref, reviewer account ref, symbol upload ref, rollback rehearsal ref, privacy URL, and support URL - passed.
- Same fixture `scripts/check_release_readiness.sh` in strict mode - failed as expected because native iOS WeChat URL scheme is still `wx0000000000000000` and Apple Sign In entitlement is not present.

Passing tests:
- TC-COM-001: `AppleSubscriptionVerificationTest` passed for server-owned Apple verification boundary.
- TC-COM-002: `GoogleSubscriptionVerificationTest` passed for server-owned Google verification boundary.
- TC-COM-003: `SubscriptionCredentialValidationTest` passed for invalid receipt/token and mismatch rejection.
- TC-COM-004: `SubscriptionRestoreTest` passed for active restore.
- TC-COM-005: `SubscriptionRestoreEmptyTest` passed for empty restore.
- TC-COM-006: `PaymentProviderEventDowngradeTest` passed for provider downgrade event handling.
- TC-COM-007: `entitlement_downgrade_widget_test.dart` passed for free entitlement downgrade UI and no offline/report overpromise.
- TC-COM-008: `EntitlementGateServiceTest` passed for paid L3 entitlement gating.
- TC-COM-009: `UsageQuotaGateTest` passed for quota exhaustion.
- TC-COM-011: `check_release_configuration.sh` passed with production fixture env.
- TC-COM-012: `check_social_login_release_config.sh --env-only` passed with production fixture env; strict native validation remains a release blocker.
- TC-COM-013: `CommercialAccountDeletionProcessorTest` and account deletion backend tests passed.
- TC-COM-014: `account_deletion_cleanup_test.dart` passed for local session/member/cache cleanup after deletion.
- TC-COM-017: `UsageReservationLifecycleTest` passed for reserve/commit/release lifecycle.
- TC-COM-018: `CommercialAbuseControlTest` passed for quota/abuse control boundary.
- TC-COM-022: `check_release_readiness.sh --env-only` passed with complete fixture evidence refs; strict release mode remains blocked by native social-login config.
- TC-COM-023: `npm run check:api-contract` passed outside sandbox.

Blocked, manual, external, or not-yet-executed tests:
- TC-COM-010: passed later by `P0-COM-SCENARIO-GATE-001` via `test/features/commercial/scenario_gating_consistency_test.dart`.
- TC-COM-015: manual commercial copy review remains pending for store/member/privacy screenshots.
- TC-COM-016: commercial copy contract automation is not implemented.
- TC-COM-019: external Apple sandbox and Google Play internal-track provider matrix remains pending.
- TC-COM-020: passed later by `P0-COM-PROVIDER-EVIDENCE-001` via `integration_test/commercial_boundary_test.dart`.
- TC-COM-021: manual store metadata, privacy/support URL, subscription terms, and reviewer-account review remains pending.
- Strict TC-COM-012/TC-COM-022 release mode is blocked until native iOS WeChat URL scheme and Apple Sign In entitlement are configured.

Acceptance criteria coverage:
- AC-COM-001 through AC-COM-006 and AC-COM-010 through AC-COM-012 have automated passed evidence for the implemented local/backend/frontend boundaries, with provider/store external evidence still blocking release where applicable.
- AC-COM-007 is covered by TC-COM-010 after `P0-COM-SCENARIO-GATE-001`.
- AC-COM-011 remains partially covered by Flutter copy assertions but blocked by TC-COM-015 and TC-COM-016.
- AC-COM-013 remains blocked by TC-COM-019 and TC-COM-020.
- AC-COM-014 has release gate scripts and fixture pass evidence, but commercial release is blocked by strict native/external evidence requirements.

Residual risk:
- This QA pass is not commercial release approval.
- The traceability chain is complete from FR/AC to TC IDs, but several TC IDs intentionally remain blocked/manual/external.
- The stage remains not release-ready and blocked until real provider, store console, privacy/support URL, reviewer-account, native social-login, symbol-upload, rollback rehearsal, and commercial E2E evidence is supplied before any PM release-ready marking.

## 2026-05-29 - P0-COM-SCENARIO-GATE-001 Scenario Gate Blocker Closure

Test scope:
- TC-COM-010 / AC-COM-007 / COM-TR-008.
- Flutter paid L3 scenario gating consistency across direct training entry, scene navigation/list view, and target-level switch.
- Regression scope for existing `InterviewPracticePage` scene navigation widget tests.

Commands run:
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart --plain-name "免费用户训练入口" --timeout 30s` - passed.
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart` - passed.
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart test/features/interview/interview_practice_page_widget_test.dart` - passed.
- `flutter analyze lib/features/commercial/commercial_scenario_gate.dart lib/features/interview/interview_practice_page.dart lib/pages/home_page.dart test/features/commercial/scenario_gating_consistency_test.dart test/features/interview/interview_practice_page_widget_test.dart` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Passing tests:
- TC-COM-010: free user direct L3 training entry is blocked with a Pro entitlement message.
- TC-COM-010: free user scene navigation exposes the same L3 locked state and does not display L3 expressions as accessible content.
- TC-COM-010: Pro user can switch to L3 from scene navigation and sees L3 expressions in the training flow.
- Regression: existing interview scene navigation and composer widget tests passed.

Failing tests:
- None in the scoped command set.

Skipped tests:
- Real provider and store console tests were not in scope for this package.

Acceptance criteria coverage:
- AC-COM-007 is covered by TC-COM-010 and TC-COM-023. TC-COM-010 is now passed for the in-app L3 paid scenario fixture.

Residual risk:
- This closes the scenario gating blocker only.
- TC-COM-016 is closed by `P0-COM-COPY-001`; TC-COM-020 is closed by `P0-COM-PROVIDER-EVIDENCE-001`; TC-COM-015 external evidence, TC-COM-019 external evidence, TC-COM-021 external evidence, and strict TC-COM-012/022 remain release blockers.

## 2026-05-29 - P0-COM-COPY-001 Commercial Copy Blocker Closure

Test scope:
- TC-COM-015 / TC-COM-016 / AC-COM-011 / COM-TR-009.
- In-repo commercial copy across `MembershipPage`, profile upsell copy, release checklist, release runbook, and copy contract automation.
- Release readiness fixture gate after adding the copy contract gate.

Commands run:
- `python3 scripts/check_commercial_copy_contract.py` - passed; reported missing external `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL`, and `SUPPORT_URL` as release blockers.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, Sentry, Android signing, Apple/Google provider evidence refs, store metadata ref, reviewer account ref, symbol upload ref, rollback rehearsal ref, privacy URL, and support URL - passed.
- `flutter test test/features/commercial/entitlement_downgrade_widget_test.dart` - passed.
- `flutter analyze lib/pages/profile_page.dart lib/pages/membership_page.dart test/features/commercial/entitlement_downgrade_widget_test.dart` - passed.
- `bash -n scripts/check_release_readiness.sh` - passed.

Passing tests:
- TC-COM-016: copy contract automation passed for shipped membership benefits, payment plan/product mapping, profile upsell copy, and release copy gate documentation.
- TC-COM-015 internal review: membership/profile/release copy does not promise offline learning packs, dedicated learning reports, unlimited practice, or lifetime membership as shipped paid benefits.
- Regression: TC-COM-007 membership downgrade widget tests still pass.

Failing tests:
- None in the scoped command set.

Skipped or external tests:
- TC-COM-015 external store metadata/privacy/support screenshots were not available locally and remain a release blocker.

Acceptance criteria coverage:
- AC-COM-011 is locally covered by TC-COM-016 and in-repo TC-COM-015 review evidence.
- AC-COM-011 is not release-complete until TC-COM-015 external store/privacy evidence is supplied.

Residual risk:
- The copy contract proves repository copy consistency; it does not prove App Store Connect / Play Console screenshots or privacy declarations.
- TC-COM-020 is closed by `P0-COM-PROVIDER-EVIDENCE-001`; TC-COM-015 external evidence, TC-COM-019 external evidence, TC-COM-021 external evidence, and strict TC-COM-012/022 remain release blockers.

## 2026-05-29 - P0-COM-PROVIDER-EVIDENCE-001 Provider Evidence Gate

Test scope:
- TC-COM-019 / TC-COM-020 / AC-COM-013 / COM-TR-011.
- Provider sandbox/internal evidence matrix and release gate.
- Local non-payment commercial boundary coverage for first install, old plan data, weak-network/provider-error recovery, and exhausted entitlement gating.

Commands run:
- `python3 scripts/check_provider_sandbox_evidence.py` - passed; reported missing `APPLE_SANDBOX_EVIDENCE_REF` and `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` as release blockers.
- `python3 -m py_compile scripts/check_provider_sandbox_evidence.py scripts/check_commercial_copy_contract.py` - passed.
- `bash -n scripts/run_mvp_system_e2e.sh scripts/check_release_readiness.sh` - passed.
- `flutter test integration_test/commercial_boundary_test.dart` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, provider/store/reviewer/symbol/rollback evidence refs, privacy URL, support URL, Sentry, and Android signing vars - passed.

Passing tests:
- TC-COM-020: local commercial boundary test passed for free first install membership gate, legacy plan normalization, L3 locked entitlement boundary, and weak-network/provider-error recovery UI.
- TC-COM-019 local gate: provider matrix and evidence script passed structurally.

Failing tests:
- None in the scoped local command set.

Skipped or external tests:
- TC-COM-019 real Apple sandbox and Google Play internal-track execution remains external pending.

Acceptance criteria coverage:
- AC-COM-013 has local TC-COM-020 passed evidence and TC-COM-019 evidence-gate structure.
- AC-COM-013 remains release-blocked until real provider evidence refs are supplied.

Residual risk:
- Local deterministic provider tests cannot replace Apple sandbox or Google Play internal-track evidence.
- TC-COM-019, TC-COM-015 external evidence, TC-COM-021, and strict TC-COM-012/022 remain release blockers.

## 2026-05-29 - P0-COM-STORE-001 Store Evidence Gate

Test scope:
- TC-COM-021 / TC-COM-022 / AC-COM-014 / COM-TR-012.
- Store submission evidence matrix and release readiness aggregation.
- Strict release gate behavior with fixture evidence refs.

Commands run:
- `python3 scripts/check_store_submission_evidence.py` - passed; reported missing `STORE_METADATA_EVIDENCE_REF`, `REVIEWER_ACCOUNT_REF`, `PRIVACY_URL`, and `SUPPORT_URL` as release blockers.
- `python3 -m py_compile scripts/check_store_submission_evidence.py scripts/check_provider_sandbox_evidence.py scripts/check_commercial_copy_contract.py` - passed.
- `bash -n scripts/check_release_readiness.sh scripts/run_mvp_system_e2e.sh` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, provider/store/reviewer/symbol/rollback evidence refs, privacy URL, support URL, Sentry, and Android signing vars - passed.
- Same fixture `scripts/check_release_readiness.sh` in strict mode - failed as expected because iOS still contains the placeholder WeChat URL scheme and lacks the Apple Sign In entitlement.

Passing tests:
- TC-COM-021 local gate: store submission matrix and evidence script passed structurally.
- TC-COM-022 env-only fixture gate passed with required evidence refs and URLs.

Failing tests:
- Strict TC-COM-012/TC-COM-022 release gate failed as expected on native iOS social-login configuration.

Skipped or external tests:
- TC-COM-021 real App Store Connect / Play Console metadata, reviewer account, privacy URL, and support URL evidence remains external pending.

Acceptance criteria coverage:
- AC-COM-014 has local release-gate evidence and store evidence-gate structure.
- AC-COM-014 remains release-blocked until real store/native evidence refs are supplied.

Residual risk:
- This does not configure App Store Connect, Play Console, public privacy/support pages, reviewer credentials, iOS WeChat URL scheme, or Apple Sign In entitlement.
- Remaining release blockers are TC-COM-015 external copy/store evidence, TC-COM-019 external provider evidence, TC-COM-021 external store evidence, and strict TC-COM-012/022 native/release evidence.
## 2026-06-01 P0-AI-BE-001 Media Upload And ASR Ref Tests

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-BE-001`
- Coverage：`COM-SI-013` / `FR-COM-AI-001` / `AC-COM-AI-001`
- Test cases：`TC-COM-AI-001`, `TC-COM-AI-002`

Command:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,ProductionAsrMediaRefTest,DashScopeProviderGatewayIntegrationTest test
```

Result: passed.

Evidence:
- `MediaUploadReferenceServiceTest` verifies authenticated media upload creation, idempotent upload create, trusted `media://audio/{media_id}` ref shape, upload URL shape, upload completion to `validated`, unsupported MIME rejection and oversize rejection.
- `ProductionAsrMediaRefTest` verifies DashScope production ASR rejects local paths, unsigned HTTP URLs and unvalidated media refs before provider call, and accepts a completed backend media ref.
- `DashScopeProviderGatewayIntegrationTest` regression verifies existing DashScope adapter behavior after changing local path handling from typed no-result to provider-before-call rejection.

Residual:
- This is a local backend/object lifecycle implementation gate. Real object storage bucket credentials, CDN/public serving behavior and live DashScope evidence remain pending in later work packages.

## 2026-06-01 P0-AI-BE-002 Persistent TTS Cache Tests

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-BE-002`
- Coverage：`COM-SI-014` / `FR-COM-AI-002` / `AC-COM-AI-002`
- Test cases：`TC-COM-AI-003`

Command:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PersistentTtsCacheTest,DashScopeProviderGatewayIntegrationTest,DashScopeProviderGatewayTest test
```

Result: passed.

Evidence:
- `PersistentTtsCacheTest` verifies the first TTS request stores a persistent cache entry with `cache_status=miss`, and a repeated request returns `cache_status=hit`, the same cache media id/audio ref and no second provider call.
- `PersistentTtsCacheTest` verifies an expired cache entry is refreshed instead of reused.
- `DashScopeProviderGatewayIntegrationTest` regression verifies the existing `/ai/tts` path still returns available TTS and avoids duplicate provider calls.
- `DashScopeProviderGatewayTest` keeps the non-Spring unit boundary covered with a dev-only local fallback cache while production Spring wiring uses `AiTtsCacheService`.

Residual:
- This closes local persistent cache metadata, expiry refresh and delete-hook support. CDN/object storage distribution and production retention proof remain pending in later work packages.

## 2026-06-01 P0-AI-QA-001 DashScope Sandbox Evidence Gate

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-QA-001`
- Coverage：`COM-SI-015` / `FR-COM-AI-003` / `AC-COM-AI-003`
- Test case：`TC-COM-AI-004`

Commands:
```bash
python3 scripts/check_ai_provider_sandbox_evidence.py
python3 scripts/check_manual_external_evidence_plan.py
python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external
```

Result:
- Non-strict AI provider evidence gate passed and reported the expected missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` release blocker.
- Manual external evidence plan passed after adding the DashScope gate command and scenario IDs.
- Strict AI provider evidence gate failed as expected because real DashScope evidence has not been supplied.

Evidence:
- `tests/commercial/ai_provider_sandbox_matrix.md` now enumerates Qwen valid/fallback, Paraformer valid/reject, TTS generate/cache and provider-error scenarios with latency, error code, cost estimate, format compatibility, fallback and reviewer requirements.
- `scripts/check_ai_provider_sandbox_evidence.py` validates the matrix and blocks strict release closure without `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.
- `scripts/check_release_readiness.sh` now includes the AI provider evidence gate in strict release readiness.

Residual:
- This is not a real DashScope sandbox pass. Controlled live LLM/ASR/TTS execution and external evidence review remain required before paid AI voice release.

## 2026-06-01 P0-AI-OPS-001 AI Cost Dashboard Tests

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-OPS-001`
- Coverage：`COM-SI-016` / `FR-COM-AI-004` / `AC-COM-AI-004`
- Test case：`TC-COM-AI-005`

Command:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest,DashScopeProviderGatewayIntegrationTest,CommercialFoundationControllerTest test
```

Result: passed.

Evidence:
- `AiCostDashboardTest` verifies `/admin/ai/cost-metrics` returns plan, user hash, provider family, model, capability, status, cache hit, call count, token/audio units, estimated cost, budget bucket and margin risk.
- `AiCostDashboardTest` verifies raw user id and raw TTS input text are not exposed in the dashboard response.
- `AiCostDashboardTest` verifies budget warning aggregation and provider anomaly status.
- `AiCostDashboardTest` verifies the endpoint requires the OPS bearer token and rejects normal user tokens.
- Regression coverage with `DashScopeProviderGatewayIntegrationTest` and `CommercialFoundationControllerTest` passed after adding metric persistence and OPS controller wiring.

Residual:
- Local dashboard and budget/anomaly status are implemented. Production PM/Ops evidence is still required through `AI_COST_DASHBOARD_EVIDENCE_REF` before paid AI release.

## 2026-06-01 P0-AI-SEC-001 AI Retention And Deletion Tests

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-SEC-001`
- Coverage：`COM-SI-017` / `FR-COM-AI-005` / `AC-COM-AI-005`
- Test cases：`TC-COM-AI-006`, `TC-COM-AI-007`

Command:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,AiCostDashboardTest,AccountDeletionLearningDataTest test
```

Result: passed.

Evidence:
- `AiRetentionPolicyTest` verifies OPS-only `POST /admin/ai/retention-jobs` deletes expired media and expired TTS cache entries, records counts and returns a redacted evidence ref.
- `AiRetentionPolicyTest` verifies `GET /admin/ai/retention-jobs/{job_id}` reads completed retention evidence and the idempotency key returns the same job.
- `AiAccountDeletionMediaCleanupTest` verifies account deletion runs AI media deletion, TTS cache owner cleanup, provider metric redaction and creates an `account_deletion` AI retention job.
- `AccountDeletionLearningDataTest` passed as an existing account deletion regression.

Residual:
- Local retention execution proof is implemented. Production object-store lifecycle, external deletion proof and approved retention policy evidence remain required through `AI_MEDIA_STORAGE_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF`.

## 2026-06-01 P0-AI-REPORT-001 Final Verification

Scope:
- `commercial-ai-provider-hardening`
- Work package：`P0-AI-REPORT-001`
- Coverage：final verification for TC-COM-AI-001 through TC-COM-AI-007 local gates and release blockers.

Commands:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,ProductionAsrMediaRefTest,PersistentTtsCacheTest,AiCostDashboardTest,AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,DashScopeProviderGatewayIntegrationTest,DashScopeProviderGatewayTest,CommercialFoundationControllerTest,AccountDeletionLearningDataTest test
python3 scripts/check_ai_provider_sandbox_evidence.py
python3 scripts/check_manual_external_evidence_plan.py
python3 -m py_compile scripts/check_ai_provider_sandbox_evidence.py scripts/check_manual_external_evidence_plan.py scripts/check_provider_sandbox_evidence.py scripts/check_store_submission_evidence.py scripts/check_commercial_copy_contract.py
bash -n scripts/check_release_readiness.sh
git diff --check
npm run lint:openapi
npm run check:api-contract
```

Result:
- Backend combined target tests passed.
- AI provider sandbox evidence non-strict gate passed with expected missing `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` blocker.
- Manual external evidence plan passed.
- Script compile, release shell syntax, diff whitespace and OpenAPI lint passed.
- `npm run check:api-contract` failed inside the filesystem sandbox due to the known `uv` macOS system configuration panic, then passed outside the sandbox.

Residual:
- This is not paid AI release approval. Strict release still requires DashScope, media storage, cost dashboard and retention evidence refs.

## 2026-06-09 P0-AI Provider Evidence Endpoint Tests

Scope:
- `commercial-ai-provider-hardening`
- Work package：local backend endpoint evidence for `P0-AI-QA-001`
- Coverage：`COM-SI-015` / `FR-COM-AI-003` / `AC-COM-AI-003`
- Test case：`TC-COM-AI-004`

Commands:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiProviderEvidenceControllerTest,AiCostDashboardTest,AiRetentionPolicyTest test
python3 scripts/check_ai_provider_sandbox_evidence.py
python3 scripts/check_ai_external_release_evidence.py
python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external
npm run check:api-contract
git diff --check
```

Result:
- Backend endpoint and regression tests passed.
- Non-strict AI provider sandbox evidence check passed and reported the expected `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` release blocker.
- Non-strict paid AI external evidence check passed and reported the expected DashScope、media storage、cost dashboard and retention evidence blockers.
- Strict AI provider sandbox evidence check failed as expected because `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` is not supplied.
- OpenAPI/API/generated Dart drift contract check passed.
- `git diff --check` passed.

Evidence:
- `AiProviderEvidenceControllerTest` verifies `GET /admin/ai/provider-evidence` returns `schema_version=1` and an empty evidence list without fabricating provider approval when no evidence rows exist.
- `AiProviderEvidenceControllerTest` verifies the endpoint requires OPS bearer authentication: missing bearer returns `UNAUTHENTICATED`, normal user bearer returns `FORBIDDEN`, and OPS bearer returns 200.
- `AiProviderEvidenceControllerTest` verifies approved, pending and blocked `ProviderSandboxRun` rows are returned with OpenAPI-aligned fields, stable ordering by `executed_at DESC, created_at DESC, evidence_id ASC`, and separate `status` / `reviewed_status` semantics.
- `AiProviderEvidenceControllerTest` verifies risky evidence fixtures containing API-key markers, raw payload, full transcript markers and a signed URL query are redacted and that internal `model`, `fixture_ref` and `error_code` fields are not exposed in the response.
- Regression coverage with `AiCostDashboardTest` and `AiRetentionPolicyTest` passed after adding the provider evidence repository to backend integration test cleanup.

Residual:
- This is local backend endpoint evidence only. Strict paid AI voice release remains blocked until `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` points to externally reviewed full DashScope LLM/ASR/TTS evidence and strict external gates pass.

## 2026-06-10 Product Base Profile Avatar XCB-003 Tests

Scope:
- Product Base profile identity boundary.
- Coverage: `FR-010` / `Flow-010` / `AC-011` / `XCB-003`.
- Test cases: `TC-PB-FR010-001`, `TC-PB-FR010-002`, `TC-PB-FR010-003`.

Commands:
```bash
cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AuthControllerTest test
flutter test test/application/session_profile_coordinator_test.dart test/services/app_session_profile_avatar_sync_test.dart test/services/api_client_contract_test.dart
npm run check:api-contract && npm run check:dart-client-drift
python3 scripts/check_cross_cutting_boundaries.py --scope full
python3 scripts/check_cross_cutting_boundaries.py --scope changed --include-worktree --base-ref HEAD
flutter analyze lib/services/api_client.dart lib/services/app_session.dart test/application/session_profile_coordinator_test.dart test/services/app_session_profile_avatar_sync_test.dart test/services/api_client_contract_test.dart
git diff --check
```

Result: passed.

Evidence:
- `TC-PB-FR010-001`: `AuthControllerTest` verifies `PATCH /user/me` persists a built-in `avatar_ref`, returns it through `PATCH` and `GET /user/me`, preserves it when omitted or `null`, and rejects remote URLs, blank strings, unknown assets and whitespace-padded refs with `SCHEMA_VALIDATION_FAILED`.
- `TC-PB-FR010-002`: Flutter session/profile tests verify `updateProfile` sends `display_name` and `avatar_ref` through the existing profile patch flow, deprecated `updateAvatar` delegates to the same profile patch boundary, unsupported legacy avatar URLs normalize to the default built-in avatar ref before sync, and `SessionProfileCoordinator` maps the backend `avatar_ref` response back into the local user profile.
- `TC-PB-FR010-003`: API contract gates verify `avatar_ref` is declared on `UpdateUserProfileRequest` and generated Dart drift hash `63618e40eaec4877be5a6927433b52da57cd487fb3e855dcc12b727b8a21d359` matches the OpenAPI source; the Flutter API contract test blocks `/user/me/avatar` and multipart avatar upload regressions.
- Cross-cutting checks passed for both full scope and changed worktree scope, confirming the profile avatar path now uses the generated `/user/me` boundary instead of a hidden hard-coded API.

Residual:
- The current product supports built-in avatar selection only. Remote avatar URLs and user-uploaded images remain out of scope until a dedicated media/image API contract is designed.
- The worktree contained unrelated pre-existing changes outside XCB-003; they were not reverted and are not part of this test result.
