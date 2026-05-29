# Test Report

## Current Status
Latest recorded test execution: `mvp-system-e2e-validation` TC-MVP-E2E-006 through TC-MVP-E2E-010 passed local Flutter macOS + Spring Boot + real PostgreSQL system E2E gates; TC-MVP-E2E-010 keeps the real payment provider as a manual/external gate.

## Required Sections
- test scope
- commands run
- passing tests
- failing tests
- skipped tests
- acceptance criteria coverage
- residual risk

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
- AC-MVP-BE-008 is fully covered by TC-MVP-BE-020, TC-MVP-BE-021, TC-MVP-BE-022, and TC-MVP-BE-023.
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
