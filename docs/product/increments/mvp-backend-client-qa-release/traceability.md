# MVP Backend Client QA Release Traceability

## 状态
Validated - client/QA/release traceability matrix 已通过 generated-client drift、全量 QA 和 release evidence 闭环。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 client/QA/release traceability rows。 |
| v1.0 | 2026-05-29 | Validated | 关闭 generated Dart boundary、Flutter drift、QA/release evidence gaps。 |

## Traceability Chain
`docs/product/roadmap.md`
-> `docs/product/stages/mvp-backend-foundation.md`
-> `docs/product/increments/mvp-backend-client-qa-release/definition.md`
-> `requirements.md`
-> `spec.md`
-> `acceptance.md`
-> `traceability.md`

## Traceability Matrix
| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MVP-BE-TR-013 | MVP-SI-013 | `mvp-backend-client-qa-release` | MVP-BE-FR-013 OpenAPI client integration | MVP-BE-SPEC-013 | AC-MVP-BE-013 | `docs/architecture/openapi/speakeasy-api.yaml`; `scripts/check_openapi_contract.py`; `scripts/check_openapi_dart_drift.py`; `docs/architecture/openapi/dart-client-drift-manifest.json` in `generated_client_drift` mode | `lib/generated/api/.openapi-sha256`; `lib/generated/api/speakeasy_api.dart`; `lib/services/api_client.dart`; `test/services/api_client_contract_test.dart`; migrated active auth/user/AI paths to `SpeakeasyApiPaths` | TC-MVP-BE-039 script path `scripts/check_openapi_contract.py`; `docs/architecture/openapi/speakeasy-api.yaml`, command `npm run check:api-contract`, result `passed`, evidence `docs/reports/test_report.md`; TC-MVP-BE-040 script path `scripts/check_openapi_dart_drift.py`; `docs/architecture/openapi/dart-client-drift-manifest.json`; `lib/generated/api/`, command `npm run check:api-contract`, result `passed`, evidence `docs/reports/test_report.md`; TC-MVP-BE-041 script path `test/services/api_client_contract_test.dart`; `test/services/auth_service_test.dart`; `test/application/scene_voice_session_lifecycle_coordinator_test.dart`; `test/application/home_cards_coordinator_test.dart`, command `flutter test test/services/api_client_contract_test.dart test/services/auth_service_test.dart test/application/scene_voice_session_lifecycle_coordinator_test.dart test/application/home_cards_coordinator_test.dart`, result `passed`, evidence `docs/reports/test_report.md`; TC-MVP-BE-042 script path `docs/architecture/openapi/dart-client-drift-manifest.json`; `docs/reports/test_report.md`, command `N/A - documented exception review`, result `accepted exception`, evidence `docs/reports/test_report.md` | `docs/release/release_checklist.md`; `docs/release/version_log.md`; release status ready with documented exceptions | Done | MVP-BE-GAP-010 closed 2026-05-29 |
| MVP-BE-TR-014 | MVP-SI-014 | `mvp-backend-client-qa-release` | MVP-BE-FR-014 QA and release evidence | MVP-BE-SPEC-014 | AC-MVP-BE-014 | `docs/product/stages/mvp-backend-foundation.md`; all six increment traceability files; `docs/reports/implementation_report.md`; `docs/reports/test_report.md`; `docs/reports/quality_report.md` | Backend code/tests from MVP-BE-TR-001..012 plus client/release files in MVP-BE-TR-013; no additional backend scope introduced here | TC-MVP-BE-043 script path `docs/product/stages/mvp-backend-foundation.md`; `docs/product/increments/*/traceability.md`, command `rg -n "MVP-SI-" docs/product/stages/mvp-backend-foundation.md docs/product/increments/mvp-backend-*`, result `passed`, evidence `docs/reports/test_report.md`; TC-MVP-BE-044 script `backend/src/test/java/com/speakeasy/`, command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test`, result `passed`, evidence `docs/reports/test_report.md`; TC-MVP-BE-045 script `test/`, command `flutter test`, result `passed`, evidence `docs/reports/test_report.md`; TC-MVP-BE-046 script path `docs/release/release_checklist.md`; `docs/reports/quality_report.md`; `scripts/validate_governance_contracts.py`, command `python3 scripts/validate_governance_contracts.py`, result `passed`, evidence `docs/reports/quality_report.md` | `docs/release/release_checklist.md`; `docs/release/version_log.md`; `docs/release/rollback_plan.md`; `docs/reports/quality_report.md` | Done | MVP-BE-GAP-011 closed 2026-05-29 |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-BE-GAP-010 | OpenAPI 与 Flutter 现有 API client 存在 drift，缺 generated Dart client 或等效强约束。 | MVP-BE-TR-013 | Frontend + Backend + QA | Closed 2026-05-29 |
| MVP-BE-GAP-011 | 后端测试、契约测试、Flutter integration/e2e、implementation report 和 quality report 尚未覆盖本 stage 全量。 | MVP-BE-TR-014 | QA + Codex Root | Closed 2026-05-29 |

## Completion Rule
本 increment 只有在 MVP-BE-TR-013 和 MVP-BE-TR-014 的 code/test/release evidence 更新、gaps 关闭或明确例外记录后，才能标记为 Done。
