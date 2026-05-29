# Implementation Report

## Current Status
Latest feature implementation recorded: `mvp-system-e2e-validation` completed TC-MVP-E2E-006 through TC-MVP-E2E-010 local system E2E automation and independent review; real payment provider remains a manual/external gate.

## Report Format
Each completed change should append:
- date
- feature or change request
- files changed
- requirement mapping
- tests added or updated
- commands run
- results
- risks
- follow-up

## 2026-05-23 - Project-local skill standardization

Change request: migrate project-local development skills from the deprecated flat `codex/skills` layout to standardized `.agents/skills/<skill>/SKILL.md` and `SPEC.md` directories, add quality-loop skills, and add local validation.

Files changed:
- Added `.agents/skills/` with 11 skills: 8 migrated core development skills and 3 quality-loop skills.
- Removed deprecated `codex/skills/`.
- Added `docs/process/skill_quality_standard.md`.
- Added `scripts/validate_agent_skills.py`.
- Updated this implementation report.

Requirement mapping:
- Supports the project-internal Codex development workflow for requirement clarification, feature specs, API contracts, domain models, screen specs, prompt contracts, test cases, skill quality checks, implementation reports, and code review quality.
- Enforces required skill sections: When to Use, When NOT to Use, Red Flags, Verification, and Common Rationalizations.
- Adds a lightweight quality gate before introducing or changing project skills.

Validation:
- Command: `python scripts/validate_agent_skills.py`
- Result: passed.

Tests added or updated:
- Added local structural validator for `.agents/skills`.
- No application runtime tests were run because this change only affects development workflow assets.

Risks:
- The validator currently checks structure and basic trigger quality only; it does not yet perform semantic quality scoring.
- Future external skill vendoring must add attribution and license files inside the affected skill directory.

Follow-up:
- Consider integrating a stronger validator or CI job after the process stabilizes.
- Add semantic checks for duplicate trigger scopes and weak verification language if skill count grows.

## 2026-05-24 - Product object governance remediation

Change request: separate product objects from delivery stages so feature registry, stage scope, increment requirements, contracts, tests, and reports have clear boundaries.

Files changed:
- Added `docs/process/product_object_governance_remediation.md`.
- Added `codex/agents/product_object_governance_change.md`.
- Added `codex/agents/product_object_governance_check.md`.
- Updated `docs/process/workflow.md`.
- Updated `docs/process/skill_quality_standard.md`.
- Updated document governance skills under `.agents/skills/document-*`.
- Updated generation, contract, test, and report skills under `.agents/skills/`.
- Added `docs/reports/product_object_governance_check_report.md`.

Requirement mapping:
- Defines Feature, Stage, Increment, Baseline, Change Request, and Artifact as separate product objects.
- Adds classification and increment-definition gates before requirements/spec/acceptance/contracts.
- Requires new product work to bind downstream contracts, tests, and reports to an owning increment or stable feature.

Validation:
- Command: `python scripts/validate_agent_skills.py`
- Result: passed.
- Additional `rg` checks confirmed the object rules, path rules, and workflow gates are present.

Tests added or updated:
- No application runtime tests were run because this change only affects process, agent, and skill governance assets.

Risks:
- Existing flat product artifacts are still not migrated.
- The new object-based paths must be used in the next product planning increment to prove the workflow end to end.

Follow-up:
- Create or migrate `docs/product/feature_registry.md`, stage scope docs, and increment docs in a separate controlled migration.
- Run the governance check agent after each migration step and update traceability references.

## 2026-05-24 - Product object baseline and PM gate alignment

Change request: extract the current APP baseline and stable feature map from legacy `mvp-learning-loop-*` documents, then align Product Manager, Development Orchestrator, and PM brief with the product object gates.

Files changed:
- Added `docs/product/feature_registry.md`.
- Added `docs/product/baselines/current-mvp.md`.
- Added `docs/product/stages/p0-1-expression-automation.md`.
- Added `docs/product/stages/p0-2-training-memory.md`.
- Added `docs/product/increments/p0-1-expression-automation-training/definition.md`.
- Updated `docs/product/roadmap.md`, `docs/product/development_status.md`, and `docs/process/change_request.md`.
- Updated `codex/agents/product_manager.md`, `codex/agents/development_orchestrator.md`, and `codex/templates/pm_orchestrator_brief.template.md`.
- Added `docs/reports/product_manager_overall_change_review.md`.

Requirement mapping:
- `mvp-learning-loop-requirements.md` is retained as legacy baseline source.
- `mvp-learning-loop-spec.md` is retained as legacy P0.1 spec source.
- Current APP baseline is now represented by `docs/product/baselines/current-mvp.md`.
- Stable APP capabilities are now represented by `docs/product/feature_registry.md`.
- P0.1 and P0.2 are represented as stages, with P0.1 active increment defined separately.

Validation:
- Command: `python scripts/validate_agent_skills.py`
- Result: passed.
- Additional `rg` checks confirmed product object fields and gates are present.
- Application source directories showed no changes.

Tests added or updated:
- No application runtime tests were run because this change only affects product governance, documentation, agent definitions, and templates.

Risks:
- P0.1 increment requirements/spec/acceptance/traceability still need to be generated or migrated from the legacy spec.
- Legacy flat docs remain as compatibility sources until a controlled migration updates downstream references.

Follow-up:
- Generate `docs/product/increments/p0-1-expression-automation-training/requirements.md`.
- Migrate or regenerate P0.1 spec under the increment directory.
- Generate P0.1 acceptance and traceability before implementation planning.

## 2026-05-24 - P0.1 increment artifact migration

Change request: migrate the P0.1 expression automation training requirements/spec/acceptance/traceability from the legacy feature spec source into the active increment directory.

Files changed:
- Added `docs/product/increments/p0-1-expression-automation-training/requirements.md`.
- Added `docs/product/increments/p0-1-expression-automation-training/spec.md`.
- Added `docs/product/increments/p0-1-expression-automation-training/acceptance.md`.
- Added `docs/product/increments/p0-1-expression-automation-training/traceability.md`.
- Updated `docs/product/development_status.md`, `docs/product/roadmap.md`, `docs/process/change_request.md`, and `docs/reports/product_manager_overall_change_review.md`.

Requirement mapping:
- Covers P0.1 official scene entry, action chain, micro-action flow, session planner, hint ladder, voice-first/text-fallback path, immediate feedback, in-session pressure check, learning evidence write-back, and recoverable failure handling.
- Preserves P0.1 non-goals: no third official scene, no arbitrary scene generation, no cross-session/cross-day scheduling, no full L0-L5 mastery ladder, no full notebook, no full scoring productization, and no commercial gating dependency.

Validation:
- Command: `python scripts/validate_agent_skills.py`
- Result: passed.
- Additional `rg` checks confirmed the P01-FR and AC-P01 traceability chain is present.
- Application source directories showed no changes.

Tests added or updated:
- No application runtime tests were run because this change only migrates product increment artifacts and status/report documents.

Risks:
- Domain model, AI runtime prompt/schema, UX screen spec, architecture/module boundary, and test cases are still planned downstream artifacts.
- The generated traceability matrix is pre-implementation and intentionally marks code/test evidence as planned.

Follow-up:
- Generate or update P0.1 domain, AI runtime, UX, architecture, and test artifacts before code implementation.

## 2026-05-26 - PB-P0-BE-001A Product Base server-backed foundation and P0 commercial DB foundation

Change request: implement the first backend/database slice after Product Manager and Development Orchestrator routing confirmed that Product Base and P0 commercial requirements/spec/acceptance/domain/OpenAPI gates exist, while backend and database implementation were missing.

Owning product objects:
- Stable feature source: `docs/product/base/requirements.md`, `docs/product/base/spec.md`, `docs/product/base/acceptance.md`, `docs/product/base/traceability.md`.
- Active increment: `docs/product/increments/commercial-subscription-readiness/`.
- Architecture/domain source: `docs/domain/domain_schema.md`, `docs/architecture/openapi/speakeasy-api.yaml`.

Files changed:
- Added backend skeleton: `backend/pom.xml`, `backend/src/main/java/com/speakeasy/SpeakEasyBackendApplication.java`, `backend/src/main/resources/application.yml`.
- Added Flyway baseline: `backend/src/main/resources/db/migration/V202605260001__pb_p0_foundation.sql`.
- Added Product Base entities and repositories under `backend/src/main/java/com/speakeasy/identity/` and `backend/src/main/java/com/speakeasy/content/`.
- Added P0 commercial, usage, and ops entities/repositories under `backend/src/main/java/com/speakeasy/commerce/`, `backend/src/main/java/com/speakeasy/usage/`, and `backend/src/main/java/com/speakeasy/ops/`.
- Added minimal API/service surface: `backend/src/main/java/com/speakeasy/api/CommercialFoundationController.java`, `backend/src/main/java/com/speakeasy/commerce/CommercialFoundationService.java`, `backend/src/main/java/com/speakeasy/common/SchemaResponse.java`, `backend/src/main/java/com/speakeasy/config/ClockConfig.java`.
- Added backend tests: `backend/src/test/java/com/speakeasy/FoundationMigrationTest.java`, `backend/src/test/java/com/speakeasy/PostgresFoundationMigrationTest.java`, `backend/src/test/java/com/speakeasy/CommercialFoundationControllerTest.java`, `backend/src/test/resources/application-test.yml`.
- Updated repository hygiene: `.gitignore` ignores `backend/target/`.

Requirement mapping:
- Product Base FR-001, FR-010 and domain `User`/`AuthIdentity` are represented by `user_accounts`, `auth_identities`, `UserAccount`, `AuthIdentity`, and the `/user/me` deletion foundation.
- Product Base FR-002 is represented by `user_profiles`, `onboarding_assessments`, `learning_routes`, `UserProfile`, `OnboardingAssessment`, and `LearningRoute`.
- Product Base FR-003, FR-005, FR-006, FR-008 are represented by `scenarios`, `scenario_versions`, `scenario_levels`, `target_expressions`, and the matching content entities.
- P0 FR-COM-001, FR-COM-006, FR-COM-007, FR-COM-009 are represented by `subscription_plans`, `subscriptions`, `entitlement_snapshots`, `/subscription/plans`, and `/entitlements`.
- P0 FR-COM-002, FR-COM-003, FR-COM-005 are represented by `purchases`, `payment_provider_events`, and subscription state foundation only; real Apple/Google verification remains a documented non-goal for this slice.
- P0 FR-COM-008 is represented by `account_deletion_jobs` and `DELETE /user/me`.
- P0 FR-COM-010 / AC-COM-012 is represented by `usage_ledgers`, `usage_reservations`, and `GET /usage/summary`.
- P0 FR-COM-011, FR-COM-012 are represented by `audit_logs` and `GET /admin/release-health` returning `warn` until provider/release gates are implemented.

Tests added or updated:
- `FoundationMigrationTest` verifies the PB/P0 foundation migration creates all required tables.
- `PostgresFoundationMigrationTest` runs the same Flyway baseline against a real `postgres:15` Testcontainers database.
- `CommercialFoundationControllerTest` verifies OpenAPI-shaped response envelopes for `/subscription/plans`, `/entitlements`, `/usage/summary`, `/user/me`, and `/admin/release-health`.
- Test setup validates repository persistence across the foundation entities used by the API slice.

Commands run:
- `python scripts/project_agent_runner.py validate` - passed before implementation.
- `python scripts/project_agent_runner.py packet development_orchestrator --task ...` - generated routing packet.
- `python scripts/project_agent_runner.py packet backend --task ...` - generated backend execution packet.
- `mvn test` in `backend/` - initially blocked by sandboxed dependency download; rerun with approved network access.
- `mvn test` in `backend/` - first real run found a test cleanup foreign-key issue; fixed by deleting `AccountDeletionJob` rows before `UserAccount` rows.
- `mvn test` in `backend/` - after DTO contract hardening, found one stale test assertion for `DELETE /user/me`; fixed the test to assert the OpenAPI top-level `deletion_job_id`, `status`, and `requested_at` fields.
- `docker version` - initially showed Docker daemon unavailable; after Docker Desktop was started, Docker server 29.0.1 became reachable.
- `mvn test -Dtest=PostgresFoundationMigrationTest` - first attempt exposed Spring Boot-managed Testcontainers 1.19.8 incompatibility with Docker Engine 29; fixed by pinning Testcontainers 2.0.5 modules and adding `flyway-database-postgresql`.
- `mvn test -Dtest=PostgresFoundationMigrationTest` - passed against PostgreSQL 15.17 via Testcontainers.
- `mvn test` in `backend/` - passed, 7 tests, 0 failures, 0 errors.
- `npm.cmd run check:api-contract` - passed, 47 paths, 51 operations, 26 request examples, 47 success examples, 54 error examples; Dart client pre-generation drift gate passed.

Results:
- Backend skeleton builds under Maven with Java 17.
- Flyway migration runs under the backend test profile and creates the Product Base and P0 commercial foundation tables.
- Flyway baseline is now validated against both H2 PostgreSQL compatibility and a real PostgreSQL 15 Testcontainers database.
- Minimal commercial readiness API surface is aligned to existing OpenAPI paths for the implemented endpoints and now uses explicit response DTOs instead of serializing JPA entities as public API contracts.
- Real provider verification, generated Dart client integration, Flutter membership integration, P0.1 training flow implementation, and production secrets are not implemented in this slice.

Risks:
- The API surface is intentionally a foundation/stub for commercial readiness; Apple/Google verification, webhook processing, usage reservation transitions, authorization, and security hardening remain follow-up implementation slices.
- Product Base traceability source files were not edited in this backend slice; merge-back to Product Base traceability should be performed only after PM/document-governance approval.

Follow-up:
- Route the next backend slice for provider verification, webhook idempotency, entitlement refresh, and usage reserve/commit/release only after PM/Development Orchestrator narrows the scope.
- Run QA and Product Object Governance Check against this implementation/report evidence before declaring the increment ready for downstream frontend/generated-client work.

## 2026-05-27 - PB-P0-BE-001B Auth/Security + User Identity Boundary

变更请求：在 PB-P0-BE-001A 后端/数据库基础上实现第一批最小认证与当前用户边界，使 Product Base 用户身份和 P0 commercial entitlement/usage/account deletion 接口不再依赖生产路径的 `X-User-Id` 替身。

Owning product objects:
- Stable feature source: `docs/product/base/requirements.md`, `docs/product/base/spec.md`, `docs/product/base/acceptance.md`, `docs/product/base/traceability.md`.
- Active increment: `docs/product/increments/commercial-subscription-readiness/`.
- Contract/security source: `docs/architecture/openapi/speakeasy-api.yaml`, `docs/architecture/api_contract.md`, `docs/architecture/security_design.md`, `docs/domain/domain_schema.md`.

Files changed:
- Updated `backend/pom.xml` to add Spring Security.
- Added `backend/src/main/resources/db/migration/V202605270001__auth_sessions.sql` for opaque access/refresh session storage.
- Added security boundary under `backend/src/main/java/com/speakeasy/security/`: bearer token filter, current-user principal, token hashing, and stateless security config.
- Added shared API error support under `backend/src/main/java/com/speakeasy/common/`: `ErrorResponse`, `ApiException`, and `ApiExceptionHandler`.
- Added auth/session/profile repositories and entities under `backend/src/main/java/com/speakeasy/identity/`.
- Added `AuthService`, `IdentityService`, and `AuthController` for `/auth/login/phone`, `/auth/login/apple`, `/auth/login/wechat`, `/auth/refresh`, `/auth/logout`, and `GET/PATCH/DELETE /user/me`.
- Updated `CommercialFoundationController` so `/entitlements` and `/usage/summary` read the authenticated principal instead of `X-User-Id`.
- Updated backend tests: `AuthControllerTest`, `AuthServiceTest`, `CommercialFoundationControllerTest`, `FoundationMigrationTest`, and `PostgresFoundationMigrationTest`.

Requirement mapping:
- Product Base FR-001 / Flow-002: minimal measurable login, refresh, logout, and bearer-token boundary now exist.
- Product Base FR-010 / AC-011: `GET/PATCH/DELETE /user/me` now bind to the authenticated user; account deletion creates a deletion job and revokes active sessions.
- P0 FR-COM-004 / AC-COM-008: production path no longer relies on demo `X-User-Id` identity substitution for protected user/commercial endpoints.
- P0 FR-COM-001, FR-COM-006, FR-COM-007: `/entitlements` uses the authenticated user for entitlement lookup and default free snapshot fallback.
- P0 FR-COM-010 / AC-COM-012: `/usage/summary` uses the authenticated user for usage summary lookup.

Tests added or updated:
- `AuthControllerTest` covers unauthenticated `GET /user/me`, phone login, current-user binding while ignoring `X-User-Id`, profile patch, refresh-token rotation, logout, and revoked-token rejection.
- `AuthServiceTest` covers login session creation, refresh rotation, access token invalidation after refresh, logout revocation, and missing-terms rejection.
- `CommercialFoundationControllerTest` now authenticates with a bearer token, proves `X-User-Id` is ignored, verifies `/entitlements`, `/usage/summary`, and `DELETE /user/me`, and checks unauthenticated entitlement access.
- Migration tests now require `auth_sessions` in both H2 and PostgreSQL Testcontainers validation.

Commands run:
- `python scripts/project_agent_runner.py validate` - passed.
- `npm.cmd run check:api-contract` - passed before implementation.
- `python scripts/project_agent_runner.py packet development_orchestrator --task ...` - generated routing packet.
- `python scripts/project_agent_runner.py packet backend --task ...` - generated backend execution packet.
- `mvn.cmd -q -DskipTests compile` in `backend/` - initially blocked by sandboxed Maven dependency resolution, then passed with approved Maven access.
- `mvn.cmd -q "-Dtest=AuthServiceTest,AuthControllerTest,CommercialFoundationControllerTest,FoundationMigrationTest" test` - first run found an expired seeded test token; fixed by using a current timestamp, then passed.
- Tool-backed QA returned pass and identified low-cost coverage gaps for additional unauthenticated paths, invalid refresh token, and unsupported `schema_version`; fixed in the same slice.
- `mvn.cmd test` in `backend/` - passed after QA gap fixes, 19 tests, 0 failures, 0 errors.
- `npm.cmd run check:api-contract` - passed after implementation; OpenAPI lint, contract gate, and Dart pre-client drift gate remain green.

Results:
- Spring Security stateless bearer-token baseline is active.
- Access/refresh tokens are opaque server-side sessions, stored as hashes in `auth_sessions`.
- `/auth/login/*`, `/auth/refresh`, and `/auth/logout` have minimal testable implementations or provider substitutes without real Apple/WeChat verification.
- `GET/PATCH/DELETE /user/me`, `/entitlements`, and `/usage/summary` bind to authenticated user identity.
- Shared error responses are JSON-shaped with OpenAPI error codes for authentication and validation failures.
- Runtime request validation rejects unsupported `schema_version` values for the implemented auth/user request DTOs.

Risks:
- Login provider implementations are substitutes only; real Apple/WeChat verification remains downstream.
- Tokens are opaque random bearer tokens, not signed JWTs; this is acceptable for the current server-side session boundary but must be revisited if horizontal stateless auth is required.
- Account deletion still creates the job and revokes sessions only; full deletion processor, anonymization, audit hardening, and release health gates remain in P0-COM-BE-005.
- Usage reserve/commit/release and entitlement refresh/gating remain in P0-COM-BE-002.

Follow-up:
- Route PB-BE-002 only after QA and checker pass this slice.
- Keep Apple/Google verify/restore, webhooks/refund/expiry downgrade, account deletion processor, generated Dart client, and Flutter integration in their later named batches.

## 2026-05-29 - mvp-backend-foundation-auth Gap Closure

变更请求：按 PM -> Development Orchestrator 路由只关闭 `mvp-backend-foundation-auth` 的 backend foundation/auth gap，不进入 onboarding/content 或其他后续 increment。

Owning product objects:
- Stage: `docs/product/stages/mvp-backend-foundation.md`
- Increment: `docs/product/increments/mvp-backend-foundation-auth/`
- Covered Stage Scope Items: MVP-SI-001, MVP-SI-002
- Requirements / acceptance: MVP-BE-FR-001, MVP-BE-FR-002, AC-MVP-BE-001, AC-MVP-BE-002
- Traceability rows: MVP-BE-TR-001, MVP-BE-TR-002

Files changed:
- Added response/error/session lifecycle coverage: `backend/src/test/java/com/speakeasy/FoundationResponseContractTest.java`, `backend/src/test/java/com/speakeasy/FoundationErrorContractTest.java`, `backend/src/test/java/com/speakeasy/AuthSessionLifecycleTest.java`.
- Updated backend error handling: `backend/src/main/java/com/speakeasy/common/ApiExceptionHandler.java`.
- Hardened PostgreSQL-compatible migration validation fallback: `backend/src/test/java/com/speakeasy/PostgresFoundationMigrationTest.java`.
- Added Mockito test runtime config: `backend/src/test/resources/mockito-extensions/org.mockito.plugins.MockMaker`.
- Updated contract tooling reproducibility and local cache hygiene: `.gitignore`, `package.json`, `docs/architecture/openapi/dart-client-drift-manifest.json`.
- Updated traceability and report evidence: `docs/product/increments/mvp-backend-foundation-auth/test_cases.md`, `docs/product/increments/mvp-backend-foundation-auth/traceability.md`, `docs/reports/implementation_report.md`, `docs/reports/test_report.md`, `docs/reports/quality_report.md`.

Requirement mapping:
- MVP-SI-001 / MVP-BE-FR-001 / AC-MVP-BE-001 is covered by TC-MVP-BE-001, TC-MVP-BE-002, and TC-MVP-BE-003 for migrations, OpenAPI-shaped DTO responses, and shared error contracts.
- MVP-SI-002 / MVP-BE-FR-002 / AC-MVP-BE-002 is covered by TC-MVP-BE-004, TC-MVP-BE-005, and TC-MVP-BE-006 for auth/current-user behavior, session lifecycle, OpenAPI drift, and Flutter auth service compatibility.
- No onboarding/content, practice/AI, learning/memory, generated Dart client, or commercial subscription expansion was implemented in this increment.

Tests added or updated:
- `FoundationResponseContractTest` verifies implemented controllers do not expose raw persistence shapes.
- `FoundationErrorContractTest` verifies validation, malformed JSON, and unauthenticated failures use the shared error schema and do not expose stack traces.
- `AuthSessionLifecycleTest` verifies expired token rejection, refresh rotation, and user-wide session revocation.
- `PostgresFoundationMigrationTest` now validates against Docker when available or a local PostgreSQL binary fallback when Docker is unavailable.

Commands run:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `python3 scripts/project_agent_runner.py packet development_orchestrator --task ...` - generated the scoped routing packet.
- `python3 scripts/project_agent_runner.py packet backend --task ...` - generated the backend execution packet.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest,FoundationResponseContractTest,FoundationErrorContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest" test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed after updating tooling to use `uv run --with PyYAML` and refreshing the pre-client OpenAPI hash.
- `flutter test test/services/auth_service_test.dart` from repository root - passed.

Results:
- MVP-BE-GAP-001 and MVP-BE-GAP-002 are closed in `docs/product/increments/mvp-backend-foundation-auth/traceability.md`.
- TC-MVP-BE-001 through TC-MVP-BE-006 are automated, executed, and recorded in `docs/product/increments/mvp-backend-foundation-auth/test_cases.md`.
- API contract gate remains in `pre_client_generation_gate` mode; no generated Dart client was introduced.

Risks:
- `PostgresFoundationMigrationTest` can still skip on machines that have neither Docker nor local PostgreSQL binaries; this machine validated with the local PostgreSQL fallback.
- Real Apple/WeChat provider verification remains out of scope for this foundation/auth increment.
- The generated Dart client remains a later client/QA increment, guarded here only by pre-client drift checks.

Follow-up:
- Run independent QA / Product Object Governance Check before routing the next increment.
- After checker pass, Development Orchestrator may route the next increment in sequence: onboarding/content.

## 2026-05-29 - mvp-backend-onboarding-content Gap Closure

变更请求：按 PM -> Development Orchestrator 路由只关闭 `mvp-backend-onboarding-content`，覆盖 onboarding assessment、official scenario content、user scenario state 和 home summary，不进入 practice/AI、learning/memory、commercial membership、generated client 或 release increment。

Owning product objects:
- Stage: `docs/product/stages/mvp-backend-foundation.md`
- Increment: `docs/product/increments/mvp-backend-onboarding-content/`
- Covered Stage Scope Items: MVP-SI-003, MVP-SI-004, MVP-SI-005
- Requirements / acceptance: MVP-BE-FR-003, MVP-BE-FR-004, MVP-BE-FR-005; AC-MVP-BE-003, AC-MVP-BE-004, AC-MVP-BE-005
- Traceability rows: MVP-BE-TR-003, MVP-BE-TR-004, MVP-BE-TR-005

Files changed:
- Added backend API/service surface: `backend/src/main/java/com/speakeasy/api/OnboardingContentController.java`, `backend/src/main/java/com/speakeasy/content/OnboardingContentService.java`.
- Added onboarding/content persistence support: `UserScenarioState`, scenario content repositories, onboarding assessment and learning route repositories, and the Flyway seed migration `V202605290001__onboarding_content_seed.sql`.
- Updated existing entities with read/update methods needed by the service: `Scenario`, `ScenarioVersion`, `ScenarioLevel`, `TargetExpression`, `OnboardingAssessment`, `LearningRoute`, and `UserAccount`.
- Extended OpenAPI/domain contracts for user scenario state and home summary: `docs/architecture/openapi/speakeasy-api.yaml`, `docs/architecture/api_contract.md`, `docs/domain/domain_schema.md`, and `docs/domain/entity_relationship.md`.
- Added onboarding/content tests: `OnboardingAssessmentControllerTest`, `LearningRouteMappingTest`, `OnboardingRouteResponseContractTest`, `ScenarioCatalogControllerTest`, `ScenarioContentControllerTest`, `ScenarioSeedVersioningTest`, `UserScenarioStateControllerTest`, and `HomeSummaryControllerTest`.
- Added shared backend test cleanup support and updated older auth/foundation/commercial tests so the new onboarding foreign keys do not break full-suite isolation.
- Updated increment traceability and report evidence: `docs/product/increments/mvp-backend-onboarding-content/test_cases.md`, `docs/product/increments/mvp-backend-onboarding-content/traceability.md`, `docs/reports/test_report.md`, and `docs/reports/quality_report.md`.

Requirement mapping:
- MVP-SI-003 / MVP-BE-FR-003 / AC-MVP-BE-003 is covered by TC-MVP-BE-007, TC-MVP-BE-008, and TC-MVP-BE-009 for onboarding validation, learning route mapping, and OpenAPI-shaped route responses.
- MVP-SI-004 / MVP-BE-FR-004 / AC-MVP-BE-004 is covered by TC-MVP-BE-010, TC-MVP-BE-011, and TC-MVP-BE-012 for official scenario catalog, detail/level content, seed/version boundaries, and Product Base scope limitation.
- MVP-SI-005 / MVP-BE-FR-005 / AC-MVP-BE-005 is covered by TC-MVP-BE-013, TC-MVP-BE-014, and TC-MVP-BE-015 for join/remove/current state, home summary, and Flutter coordinator compatibility.

Commands run:
- `python3 scripts/project_agent_runner.py packet development_orchestrator --task ...` - generated the scoped routing packet.
- `python3 scripts/project_agent_runner.py packet backend --task ...` - generated the backend execution packet.
- `python3 scripts/project_agent_runner.py packet qa --task ...` - generated the QA verification packet.
- `python3 scripts/project_agent_runner.py packet product_object_governance_check --task ...` - generated the independent checker packet.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=OnboardingAssessmentControllerTest,LearningRouteMappingTest,OnboardingRouteResponseContractTest,ScenarioCatalogControllerTest,ScenarioContentControllerTest,ScenarioSeedVersioningTest,UserScenarioStateControllerTest,HomeSummaryControllerTest" test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed after OpenAPI examples and Dart pre-client drift hash were updated.
- `flutter test test/application/home_cards_coordinator_test.dart test/application/scene_setup_coordinator_test.dart` from repository root - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Results:
- MVP-BE-GAP-003 and MVP-BE-GAP-004 are closed in `docs/product/increments/mvp-backend-onboarding-content/traceability.md`.
- TC-MVP-BE-007 through TC-MVP-BE-015 are automated, executed, and recorded in `docs/product/increments/mvp-backend-onboarding-content/test_cases.md`.
- Official Product Base scenarios are seeded and versioned for `job_interview` and `onboarding_introduction`, with L1/L2/L3 target expressions.
- Onboarding assessment now creates deterministic learning routes and scenario state for supported Product Base directions; daily service returns an explicit no-scenario route.
- Home summary now reads backend user scenario state and exposes stable default states for review, weakness, and unfinished-session data that are not yet implemented.

Risks:
- Generated Dart client and real Flutter service wiring remain a later client/QA increment; this increment keeps the contract in pre-client drift mode.
- Home summary intentionally reports default `not_available` / `none` values for review, weakness, and unfinished-session inputs until the learning/memory and practice increments provide those data sources.
- Scenario seed content is MVP seed data, not a CMS or content operations pipeline.

Follow-up:
- Route `mvp-backend-practice-ai` only after independent QA / Product Object Governance Check passes this increment.

## 2026-05-29 - mvp-backend-practice-ai Gap Closure

变更请求：按 PM -> Development Orchestrator 路由只关闭 `mvp-backend-practice-ai`，覆盖 provider gateway、practice session lifecycle、turn persistence、coach feedback、recoverable failure 和 summary candidate，不进入 learning-memory accepted evidence、commercial membership、generated Dart client、release 或 P0.1 planner。

Owning product objects:
- Stage: `docs/product/stages/mvp-backend-foundation.md`
- Increment: `docs/product/increments/mvp-backend-practice-ai/`
- Covered Stage Scope Items: MVP-SI-006, MVP-SI-008, MVP-SI-009
- Requirements / acceptance: MVP-BE-FR-006, MVP-BE-FR-008, MVP-BE-FR-009; AC-MVP-BE-006, AC-MVP-BE-008, AC-MVP-BE-009
- Traceability rows: MVP-BE-TR-006, MVP-BE-TR-008, MVP-BE-TR-009

Files changed:
- Added practice persistence migration: `backend/src/main/resources/db/migration/V202605290002__practice_ai_sessions.sql`.
- Added practice domain code under `backend/src/main/java/com/speakeasy/practice/`: session, turn, feedback, summary entities/repositories and `PracticeService`.
- Added AI gateway code under `backend/src/main/java/com/speakeasy/ai/`: `AiProviderGateway`, deterministic server-side adapter, and `AiGatewayService`.
- Added API controllers: `backend/src/main/java/com/speakeasy/api/PracticeController.java` and `AiGatewayController.java`.
- Updated backend Jackson config to reject unknown JSON request fields so provider secrets cannot be smuggled into gateway DTOs.
- Updated home summary unfinished-session state to read backend practice sessions.
- Updated OpenAPI/API/domain/AI runtime contracts: `docs/architecture/openapi/speakeasy-api.yaml`, `docs/architecture/api_contract.md`, `docs/domain/domain_schema.md`, `docs/domain/entity_relationship.md`, and `docs/ai_runtime/*`.
- Added tests TC-MVP-BE-016 through TC-MVP-BE-025 under `backend/src/test/java/com/speakeasy/`.

Requirement mapping:
- MVP-SI-006 / MVP-BE-FR-006 / AC-MVP-BE-006 is covered by TC-MVP-BE-016 through TC-MVP-BE-019 for provider secret rejection, mock provider success, provider failure fallback, and auth/session mismatch blocking.
- MVP-SI-008 / MVP-BE-FR-008 / AC-MVP-BE-008 is covered by TC-MVP-BE-020 through TC-MVP-BE-023 for start/resume/get/turn/complete/recovery and idempotent turn replay.
- MVP-SI-009 / MVP-BE-FR-009 / AC-MVP-BE-009 is covered by TC-MVP-BE-024 and TC-MVP-BE-025 for structured coach feedback, score signal source/availability, playback failure, invalid provider output fallback, and candidate-only evidence.

Commands run:
- `python3 scripts/project_agent_runner.py packet development_orchestrator --task ...` - generated the scoped routing packet.
- `python3 scripts/project_agent_runner.py packet backend --task ...` - generated the backend execution packet.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,ProviderGatewayAuthorizationTest,PracticeSessionLifecycleTest,PracticeTurnControllerTest,PracticeSessionCompletionTest,PracticeSessionRecoveryTest,CoachFeedbackContractTest,FeedbackFailureHandlingTest" test` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed with OpenAPI lint, contract examples, and Dart pre-client drift hash `e81fb612e399777241c2ab6cd2d965f972e9762cf76aaea76c94b5f71f18259c`.

Results:
- MVP-BE-GAP-005 and MVP-BE-GAP-007 are closed in `docs/product/increments/mvp-backend-practice-ai/traceability.md`.
- TC-MVP-BE-016 through TC-MVP-BE-025 are automated, executed, and recorded in `docs/product/increments/mvp-backend-practice-ai/test_cases.md`.
- Practice sessions can start/resume/get/submit turns/complete and no completed session is returned as active recovery.
- Provider gateway behavior is server-side only; unknown request fields such as `provider_secret` fail before provider invocation.
- Feedback and score signals are structured and candidate-only; no final mastery, accepted learning evidence, billing, or release state is written by this increment.

Risks:
- Provider adapters are deterministic local substitutes for MVP contract testing; real provider credentials, retries, latency budgets, and usage reservation accounting remain downstream work.
- `SessionSummary` returns learning-memory candidate input only; accepted evidence, review scheduling, mastery, and history remain in `mvp-backend-learning-memory`.
- Generated Dart client and production Flutter service wiring remain later client/QA work.

Follow-up:
- Route `mvp-backend-learning-memory` only after independent QA / Product Object Governance Check passes this increment.

## 2026-05-29 - mvp-backend-learning-memory Gap Closure

变更请求：按 PM -> Development Orchestrator 路由只关闭 `mvp-backend-learning-memory`，覆盖推荐表达队列、表达任务完成、收藏、learning evidence、mastery、review、personal wiki 和 history，不进入 commercial membership、generated Dart client、release 或 P0.2 长期训练规划。

Owning product objects:
- Stage: `docs/product/stages/mvp-backend-foundation.md`
- Increment: `docs/product/increments/mvp-backend-learning-memory/`
- Covered Stage Scope Items: MVP-SI-007, MVP-SI-010
- Requirements / acceptance: MVP-BE-FR-007, MVP-BE-FR-010; AC-MVP-BE-007, AC-MVP-BE-010
- Traceability rows: MVP-BE-TR-007, MVP-BE-TR-010

Files changed:
- Added learning/memory persistence migration: `backend/src/main/resources/db/migration/V202605290003__learning_memory.sql`.
- Added learning domain code under `backend/src/main/java/com/speakeasy/learning/`: queue, attempt, favorite, evidence, mastery, review, saved expression and history entities/repositories plus `LearningMemoryService`.
- Added API controller `backend/src/main/java/com/speakeasy/api/LearningMemoryController.java`.
- Updated migration tests and backend integration cleanup for the new learning tables.
- Updated OpenAPI/API/domain contracts: `docs/architecture/openapi/speakeasy-api.yaml`, `docs/architecture/api_contract.md`, `docs/domain/domain_schema.md`, `docs/domain/entity_relationship.md`, and `docs/architecture/openapi/dart-client-drift-manifest.json`.
- Added tests TC-MVP-BE-026 through TC-MVP-BE-032 under `backend/src/test/java/com/speakeasy/`.

Requirement mapping:
- MVP-SI-007 / MVP-BE-FR-007 / AC-MVP-BE-007 is covered by TC-MVP-BE-026 through TC-MVP-BE-029 for empty queue state, queue priority/dedupe, task progress/evidence/mastery link, and favorite idempotency/delete.
- MVP-SI-010 / MVP-BE-FR-010 / AC-MVP-BE-010 is covered by TC-MVP-BE-030 through TC-MVP-BE-032 for rejected low-confidence evidence, accepted evidence projections, personal wiki/history visibility, and history deletion.

Commands run:
- `python3 scripts/project_agent_runner.py packet development_orchestrator --task ...` - generated the scoped routing packet.
- `python3 scripts/project_agent_runner.py packet backend --task ...` - generated the backend execution packet.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` from `backend/` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed with OpenAPI lint, contract examples, and Dart pre-client drift hash `d677224d822630f0ca30bdcdd55b8c0793b778b7e8e8a65dbfa58f38be15886e`.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed after adjusting learning evidence projection FKs to `ON DELETE SET NULL`.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Results:
- MVP-BE-GAP-006 is closed in `docs/product/increments/mvp-backend-learning-memory/traceability.md`.
- TC-MVP-BE-026 through TC-MVP-BE-032 are automated, executed, and recorded in `docs/product/increments/mvp-backend-learning-memory/test_cases.md`.
- Learning queue, favorite, evidence, mastery, review, personal wiki, and history now have backend-owned persistence and API contracts.

Risks:
- Review scheduling is MVP immediate-due behavior, not the deferred P0.2 cross-day planner or full L0-L5 mastery ladder.
- Generated Dart client and production Flutter service wiring remain later client/QA work; this increment keeps the contract in pre-client drift mode.

Follow-up:
- Route `mvp-backend-membership-boundary` only after independent QA / Product Object Governance Check passes this increment.

## 2026-05-29 - mvp-backend-membership-boundary Gap Closure

变更请求：按 PM -> Development Orchestrator 路由只关闭 `mvp-backend-membership-boundary`，覆盖账号删除、Product Base 学习数据处理、MVP membership/report/placeholder boundary，不进入完整商业订阅、真实支付、generated Dart client 或 release increment。

Owning product objects:
- Stage: `docs/product/stages/mvp-backend-foundation.md`
- Increment: `docs/product/increments/mvp-backend-membership-boundary/`
- Covered Stage Scope Items: MVP-SI-011, MVP-SI-012
- Requirements / acceptance: MVP-BE-FR-011, MVP-BE-FR-012; AC-MVP-BE-011, AC-MVP-BE-012
- Traceability rows: MVP-BE-TR-011, MVP-BE-TR-012

Files changed:
- Added account deletion orchestration: `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java`, account deletion job failure/completion helpers, audit constructor, user deleted marker, and latest-job repository query.
- Updated API surface: `backend/src/main/java/com/speakeasy/api/AuthController.java` for `DELETE /user/me` idempotency and `GET /user/deletion-status`; `backend/src/main/java/com/speakeasy/api/MembershipBoundaryController.java` for membership, Android billing, report, offline content, and achievements boundary states.
- Added backend tests TC-MVP-BE-033 through TC-MVP-BE-038 under `backend/src/test/java/com/speakeasy/`.
- Updated OpenAPI/API/domain contracts and drift manifest: `docs/architecture/openapi/speakeasy-api.yaml`, `docs/architecture/openapi/dart-client-drift-manifest.json`, `docs/architecture/api_contract.md`, `docs/domain/domain_schema.md`, and `docs/domain/entity_relationship.md`.
- Updated increment traceability and report evidence: `docs/product/increments/mvp-backend-membership-boundary/test_cases.md`, `docs/product/increments/mvp-backend-membership-boundary/traceability.md`, `docs/reports/test_report.md`, and `docs/reports/quality_report.md`.

Requirement mapping:
- MVP-SI-011 / MVP-BE-FR-011 / AC-MVP-BE-011 is covered by TC-MVP-BE-033 through TC-MVP-BE-036 for deletion completion, session invalidation, Product Base learning/practice/profile data cleanup, failure status visibility, and audit evidence.
- MVP-SI-012 / MVP-BE-FR-012 / AC-MVP-BE-012 is covered by TC-MVP-BE-037 and TC-MVP-BE-038 for MVP membership boundary, Android billing platform-limited responses, and explicit report/offline/achievement placeholders.

Commands run:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test` from `backend/` - passed.
- `npm run check:api-contract` from repository root - passed: 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples; Dart pre-client drift hash `506282ac758a37269df95e12ca6752de9c201eb162fd4cc0e227b13c287ab082`.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Results:
- MVP-BE-GAP-008 and MVP-BE-GAP-009 are closed in `docs/product/increments/mvp-backend-membership-boundary/traceability.md`.
- Account deletion now revokes sessions, clears user-owned Product Base learning/practice/profile state, marks the account deleted, completes a deletion job, and writes redacted audit evidence.
- Membership, Android purchase/restore, learning report, offline content, and achievements endpoints return explicit MVP boundary/placeholder facts without claiming full commercial readiness.

Risks:
- Complete commercial subscription, real Android/iOS payment provider verification, webhook handling, entitlement gating, paid reports, offline packages, and achievements remain outside this increment.
- Account deletion performs synchronous local DB cleanup for MVP scope; production retention policies for raw media/transcript object stores still need their owning DevOps/Security increment.

Follow-up:
- Route `mvp-backend-client-qa-release` only after independent QA / Product Object Governance Check passes this increment.

## 2026-05-29 - mvp-backend-client-qa-release Gap Closure

变更请求：按第六个顺序 increment 关闭 `mvp-backend-client-qa-release`，覆盖 OpenAPI/Dart client drift、Flutter active-flow evidence、全量 QA 和 release evidence，不新增 Product Base 范围外后端能力。

Owning product objects:
- Stage: `docs/product/stages/mvp-backend-foundation.md`
- Increment: `docs/product/increments/mvp-backend-client-qa-release/`
- Covered Stage Scope Items: MVP-SI-013, MVP-SI-014
- Requirements / acceptance: MVP-BE-FR-013, MVP-BE-FR-014; AC-MVP-BE-013, AC-MVP-BE-014
- Traceability rows: MVP-BE-TR-013, MVP-BE-TR-014

Files changed:
- Added generated OpenAPI Dart boundary: `lib/generated/api/.openapi-sha256`, `lib/generated/api/speakeasy_api.dart`.
- Upgraded Dart drift gate: `scripts/check_openapi_dart_drift.py` now verifies generated Dart files include all OpenAPI path templates and checks handwritten ApiClient exceptions.
- Updated Flutter API client: `lib/services/api_client.dart` now routes active auth/current-user/account-delete/AI gateway MVP calls through `SpeakeasyApiPaths`, uses OpenAPI snake_case request fields, and removes migrated legacy paths.
- Added Flutter contract tests: `test/services/api_client_contract_test.dart`.
- Updated API/release/stage evidence: `docs/architecture/api_contract.md`, `docs/architecture/openapi/dart-client-drift-manifest.json`, `docs/product/stages/mvp-backend-foundation.md`, `docs/product/increments/mvp-backend-client-qa-release/test_cases.md`, `docs/product/increments/mvp-backend-client-qa-release/traceability.md`, `docs/release/release_checklist.md`, `docs/release/version_log.md`, and `docs/release/rollback_plan.md`.

Requirement mapping:
- MVP-SI-013 / MVP-BE-FR-013 / AC-MVP-BE-013 is covered by TC-MVP-BE-039 through TC-MVP-BE-042 for OpenAPI lint/contract, generated Dart drift, Flutter active API drift tests, and documented handwritten-client exceptions.
- MVP-SI-014 / MVP-BE-FR-014 / AC-MVP-BE-014 is covered by TC-MVP-BE-043 through TC-MVP-BE-046 for stage traceability, full backend regression, full Flutter regression, release checklist, version log, rollback plan, and Product Object Governance evidence.

Commands run:
- `npm run check:api-contract` from repository root - passed: OpenAPI contract gate passed with 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples; Dart client drift gate passed in `generated_client_drift` mode with hash `506282ac758a37269df95e12ca6752de9c201eb162fd4cc0e227b13c287ab082`.
- `flutter test test/services/api_client_contract_test.dart test/services/auth_service_test.dart test/application/scene_voice_session_lifecycle_coordinator_test.dart test/application/home_cards_coordinator_test.dart` - passed.
- `rg -n "MVP-SI-" docs/product/stages/mvp-backend-foundation.md docs/product/increments/mvp-backend-*` - passed and returned stage/increment traceability evidence.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `flutter test` - passed, 173 tests.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Results:
- MVP-BE-GAP-010 and MVP-BE-GAP-011 are closed in `docs/product/increments/mvp-backend-client-qa-release/traceability.md`.
- `docs/product/stages/mvp-backend-foundation.md` now marks MVP-SI-001 through MVP-SI-014 as Done or Done with documented exceptions.
- API contract gate is no longer pre-client-only; it validates committed generated Dart boundary files and handwritten exception drift.
- Release status is ready with documented exceptions, recorded in `docs/release/release_checklist.md`.

Risks:
- The generated Dart boundary is a project-local path/contract registry, not a full `dart-dio` model client. The drift gate enforces hash/path coverage and exception tracking; full DTO codegen can still replace it later.
- Legacy stats, freeform scene, role-memory, grammar-score, oral-assessment auth, and payment verify paths remain explicitly documented exceptions until their owning increments migrate them or retire them.
- Production payment provider readiness, external object-store deletion/retention, paid reports, offline packages, and achievements remain out of scope for this stage release.

Follow-up:
- Future commercial/provider/content expansion must open separate owning increments; this stage should not be used as implicit approval for P0/P0.1/P0.2/P1/P2 expansion.

## 2026-05-29 - mvp-system-e2e-validation Deep System Regression

变更请求：按“1/2/3 分步执行并独立审核”的要求，补齐 TC-MVP-E2E-006 到 TC-MVP-E2E-010，使 Product Base AC-001 到 AC-013 在本地电脑端形成 Flutter macOS + Spring Boot + 真实 PostgreSQL 的系统 E2E 执行证据；真实支付 provider 保留 manual/external gate。

Owning product objects:
- Stage: `docs/product/stages/mvp-backend-foundation.md`
- Increment: `docs/product/increments/mvp-system-e2e-validation/`
- Covered Stage Scope Item: MVP-SI-014
- Requirements / acceptance: MVP-E2E-FR-001 through MVP-E2E-FR-004; AC-MVP-E2E-001 through AC-MVP-E2E-004
- Traceability rows: MVP-E2E-TR-001 through MVP-E2E-TR-004

Files changed:
- Added system E2E increment artifacts under `docs/product/increments/mvp-system-e2e-validation/`.
- Added `scripts/run_mvp_system_e2e.sh` to start isolated PostgreSQL, backend, and Flutter macOS integration test; added `scripts/check_mvp_system_e2e_coverage.py` for Product Base AC/TC traceability auditing.
- Added `integration_test/mvp_system_smoke_test.dart`, `integration_test/mvp_system_scene_catalog_test.dart`, `integration_test/mvp_system_learning_memory_test.dart`, `integration_test/mvp_system_practice_feedback_test.dart`, `integration_test/mvp_system_profile_settings_test.dart`, `integration_test/mvp_system_membership_boundary_test.dart`, and shared helpers in `integration_test/support/mvp_e2e_test_helpers.dart`.
- Added stable Flutter UI keys across login/onboarding, home, listening warmup, profile/settings, favorites, feature placeholders, edit profile, and membership pages.
- Added E2E-safe Hive isolation switches in `lib/core/bootstrap/app_bootstrapper.dart` and `lib/services/storage_service.dart`; added E2E error-hook disabling in `lib/main.dart`.
- Fixed client/session integration bugs in `lib/services/api_client.dart`, `lib/application/session/session_profile_coordinator.dart`, and `lib/services/app_session.dart` so profile patch and onboarding assessment persistence match backend contracts.
- Updated macOS test runtime settings and dependency metadata: `macos/Podfile`, `macos/Runner.xcodeproj/project.pbxproj`, `macos/Runner/DebugProfile.entitlements`, `pubspec.yaml`, and `pubspec.lock`.
- Updated roadmap/stage/report evidence for the new system E2E gate.

Requirement mapping:
- MVP-E2E-FR-001 / AC-MVP-E2E-001 is covered by TC-MVP-E2E-001 and `scripts/run_mvp_system_e2e.sh`.
- MVP-E2E-FR-002 / AC-MVP-E2E-002 is covered by TC-MVP-E2E-002 and TC-MVP-E2E-003 through `integration_test/mvp_system_smoke_test.dart`.
- MVP-E2E-FR-003 / AC-MVP-E2E-003 is covered by TC-MVP-E2E-004 and TC-MVP-E2E-006 through TC-MVP-E2E-010 through traceability audit plus deep E2E suites.
- MVP-E2E-FR-004 / AC-MVP-E2E-004 is covered by TC-MVP-E2E-005 through required TC evidence fields and report updates.

Commands run:
- Step 1 independent audit: TC library field/Product Base AC audit - passed, 10 TC rows and 13 Product Base AC rows checked.
- Step 2 independent audit: requirement/spec/acceptance/traceability chain audit - passed after correcting explicit Spec/FR/TR references.
- Step 3 system smoke: `scripts/run_mvp_system_e2e.sh` - passed against local PostgreSQL + backend + Flutter macOS.
- Step 3 deep regression: `scripts/run_mvp_system_e2e.sh --suite scene-catalog` - passed.
- Step 3 deep regression: `scripts/run_mvp_system_e2e.sh --suite learning-memory` - passed.
- Step 3 deep regression: `scripts/run_mvp_system_e2e.sh --suite practice-feedback` - passed.
- Step 3 deep regression: `scripts/run_mvp_system_e2e.sh --suite profile-settings` - passed.
- Step 3 deep regression: `scripts/run_mvp_system_e2e.sh --suite membership-boundary` - passed.
- Step 3 coverage audit: `python3 scripts/check_mvp_system_e2e_coverage.py` - passed.
- Regression/governance: `flutter test` - passed, 173 tests; `env JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed; `python3 scripts/project_agent_runner.py validate` - passed; `git diff --check` - passed.

Results:
- MVP-E2E-GAP-001 through MVP-E2E-GAP-004 are closed.
- TC-MVP-E2E-001 through TC-MVP-E2E-005 are automated and passed on 2026-05-29.
- MVP-E2E-GAP-005 through MVP-E2E-GAP-007 are closed by TC-MVP-E2E-006 through TC-MVP-E2E-009.
- TC-MVP-E2E-010 passed local membership boundary UI automation; GAP-008 remains an accepted external/manual payment provider exception.
- TC-MVP-E2E-006 through TC-MVP-E2E-010 are automated and passed on 2026-05-29, except the real payment provider sub-scope explicitly marked manual/external.
- The local system gate no longer depends on Docker; it uses installed local PostgreSQL tooling.

Risks:
- `/user/stats` refresh still logs a non-blocking failure in E2E and should be handled by a future stats/client compatibility cleanup.
- macOS notification initialization still logs a soft failure in E2E because local macOS notification settings are not configured.
- TC-MVP-E2E-008 uses deterministic backend provider assertions; real mobile audio permissions, real ASR/TTS/LLM provider quality, and provider SLA remain external/manual gates.
- Real payment provider purchase/restore/webhook/refund completion remains outside this local E2E gate and must stay a release/provider gate.

Follow-up:
- Keep TC-MVP-E2E-001 through TC-MVP-E2E-010 as the required local MVP system E2E gate; add future suites only through stable TC IDs and explicit provider exceptions.
