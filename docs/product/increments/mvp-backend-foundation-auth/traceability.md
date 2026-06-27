# MVP Backend Foundation Auth Traceability

## 状态
Validated - foundation/auth gap closure evidence 已在 2026-05-29 通过；TC-MVP-BE-004 Apple/WeChat test-substitute endpoint evidence 已在 2026-06-25 重新验证。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 foundation/auth traceability rows。 |
| v0.2 | 2026-05-29 | Validated | 补齐 TC-MVP-BE-001 到 TC-MVP-BE-006 的代码、测试和报告证据，关闭 foundation/auth gaps。 |
| v0.3 | 2026-06-25 | Validated | 补齐 TC-MVP-BE-004 Apple/WeChat test-substitute endpoint 与 `AuthService.loginSocial` 测试证据。 |

## Traceability Chain
`docs/product/roadmap.md`
-> `docs/product/stages/mvp-backend-foundation.md`
-> `docs/product/increments/mvp-backend-foundation-auth/definition.md`
-> `requirements.md`
-> `spec.md`
-> `acceptance.md`
-> `traceability.md`

## Traceability Matrix
| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MVP-BE-TR-001 | MVP-SI-001 | `mvp-backend-foundation-auth` | MVP-BE-FR-001 backend foundation | MVP-BE-SPEC-001 | AC-MVP-BE-001 | `docs/architecture/openapi/speakeasy-api.yaml`; `docs/architecture/backend_db_foundation_contract.md`; `docs/architecture/openapi/dart-client-drift-manifest.json` | `backend/pom.xml`; `backend/src/main/java/com/speakeasy/SpeakEasyBackendApplication.java`; `backend/src/main/resources/db/migration/`; `backend/src/main/java/com/speakeasy/common/ApiExceptionHandler.java`; `backend/src/test/java/com/speakeasy/FoundationResponseContractTest.java`; `backend/src/test/java/com/speakeasy/FoundationErrorContractTest.java`; `backend/src/test/java/com/speakeasy/PostgresFoundationMigrationTest.java` | TC-MVP-BE-001: `FoundationMigrationTest`, `PostgresFoundationMigrationTest`, command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest,FoundationResponseContractTest,FoundationErrorContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest" test`, result passed 2026-05-29; TC-MVP-BE-002: `FoundationResponseContractTest`, same command, result passed; TC-MVP-BE-003: `FoundationErrorContractTest`, same command, result passed; evidence `docs/reports/test_report.md` | N/A - no release-scope artifact in this increment; quality evidence in `docs/reports/quality_report.md` | Closed | MVP-BE-GAP-001 closed |
| MVP-BE-TR-002 | MVP-SI-002 | `mvp-backend-foundation-auth` | MVP-BE-FR-002 auth/session/current user | MVP-BE-SPEC-002 | AC-MVP-BE-002 | OpenAPI auth/current-user paths; `docs/architecture/openapi/dart-client-drift-manifest.json` | `backend/src/main/java/com/speakeasy/api/AuthController.java`; `backend/src/main/java/com/speakeasy/identity/`; `backend/src/main/java/com/speakeasy/security/`; `backend/src/test/java/com/speakeasy/AuthSessionLifecycleTest.java`; `backend/src/test/java/com/speakeasy/AuthControllerTest.java`; `backend/src/test/java/com/speakeasy/AuthServiceTest.java`; `package.json` | TC-MVP-BE-004: `AuthControllerTest`, `AuthServiceTest`, command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AuthControllerTest,AuthServiceTest test`, result passed 2026-06-25, covers phone login, Apple/WeChat test-substitute endpoint success, current-user binding, provider namespace isolation, social request validation, and `AuthService.loginSocial`; TC-MVP-BE-005: `AuthSessionLifecycleTest`, command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest,FoundationResponseContractTest,FoundationErrorContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest" test`, result passed 2026-05-29; TC-MVP-BE-006: `npm run check:api-contract` and `flutter test test/services/auth_service_test.dart`, result passed 2026-05-29; evidence `docs/reports/test_report.md` | N/A - no release-scope artifact in this increment; quality evidence in `docs/reports/quality_report.md` | Closed | MVP-BE-GAP-002 closed |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-BE-GAP-001 | Foundation partial exists, but Product Base full backend schema and DTO/error coverage must be confirmed before this increment can be accepted. | MVP-BE-TR-001 | Backend + QA | Closed 2026-05-29: TC-MVP-BE-001/002/003 passed and evidence recorded. |
| MVP-BE-GAP-002 | Auth partial exists, but Flutter API client drift, current user/profile shape, and MVP foundation-auth provider contract evidence need closure; production Apple/WeChat identity validation remains deferred outside this increment. | MVP-BE-TR-002 | Backend + Frontend + QA | Closed 2026-05-29 for original auth/session evidence; TC-MVP-BE-004 Apple/WeChat test-substitute evidence revalidated 2026-06-25. Production Apple/WeChat token/code validation is not closed by this gap. |

## Completion Rule
本 increment 只有在 MVP-BE-TR-001 和 MVP-BE-TR-002 的 code/test evidence 更新、gaps 关闭或明确例外记录后，才能标记为 Done。
