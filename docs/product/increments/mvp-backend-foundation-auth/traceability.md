# MVP Backend Foundation Auth Traceability

## 状态
Draft - foundation/auth traceability matrix。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 foundation/auth traceability rows。 |

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
| MVP-BE-TR-001 | MVP-SI-001 | `mvp-backend-foundation-auth` | MVP-BE-FR-001 backend foundation | MVP-BE-SPEC-001 | AC-MVP-BE-001 | `docs/architecture/openapi/speakeasy-api.yaml`; `docs/architecture/backend_db_foundation_contract.md` | Existing partial: `backend/pom.xml`, `backend/src/main/java/com/speakeasy/SpeakEasyBackendApplication.java`, `backend/src/main/resources/db/migration/` | Existing partial: `backend/src/test/java/com/speakeasy/FoundationMigrationTest.java`, `backend/src/test/java/com/speakeasy/PostgresFoundationMigrationTest.java`; must rerun in this increment | Not started | Partially implemented | MVP-BE-GAP-001 |
| MVP-BE-TR-002 | MVP-SI-002 | `mvp-backend-foundation-auth` | MVP-BE-FR-002 auth/session/current user | MVP-BE-SPEC-002 | AC-MVP-BE-002 | OpenAPI auth/current-user paths | Existing partial: `backend/src/main/java/com/speakeasy/api/AuthController.java`, `backend/src/main/java/com/speakeasy/identity/`, `backend/src/main/java/com/speakeasy/security/` | Existing partial: `backend/src/test/java/com/speakeasy/AuthControllerTest.java`, `backend/src/test/java/com/speakeasy/AuthServiceTest.java`; frontend drift tests pending | Not started | Partially implemented | MVP-BE-GAP-002 |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-BE-GAP-001 | Foundation partial exists, but Product Base full backend schema and DTO/error coverage must be confirmed before this increment can be accepted. | MVP-BE-TR-001 | Backend + QA | Open |
| MVP-BE-GAP-002 | Auth partial exists, but Flutter API client drift, current user/profile shape, and production/provider boundary need closure. | MVP-BE-TR-002 | Backend + Frontend + QA | Open |

## Completion Rule
本 increment 只有在 MVP-BE-TR-001 和 MVP-BE-TR-002 的 code/test evidence 更新、gaps 关闭或明确例外记录后，才能标记为 Done。
