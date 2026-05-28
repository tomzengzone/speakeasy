# MVP Backend Client QA Release Traceability

## 状态
Draft - client/QA/release traceability matrix。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 client/QA/release traceability rows。 |

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
| MVP-BE-TR-013 | MVP-SI-013 | `mvp-backend-client-qa-release` | MVP-BE-FR-013 OpenAPI client integration | MVP-BE-SPEC-013 | AC-MVP-BE-013 | `docs/architecture/openapi/speakeasy-api.yaml`; contract scripts | Existing Flutter client drift suspected in `lib/services/api_client.dart`; generated client integration pending | OpenAPI lint/gate and Flutter API drift tests pending | Not started | Planned | MVP-BE-GAP-010 |
| MVP-BE-TR-014 | MVP-SI-014 | `mvp-backend-client-qa-release` | MVP-BE-FR-014 QA and release evidence | MVP-BE-SPEC-014 | AC-MVP-BE-014 | Stage and increment traceability files | Implementation evidence pending across MVP backend increments | Backend, contract, Flutter integration/e2e and report evidence pending | Not started | Planned | MVP-BE-GAP-011 |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-BE-GAP-010 | OpenAPI 与 Flutter 现有 API client 存在 drift，缺 generated Dart client 或等效强约束。 | MVP-BE-TR-013 | Frontend + Backend + QA | Open |
| MVP-BE-GAP-011 | 后端测试、契约测试、Flutter integration/e2e、implementation report 和 quality report 尚未覆盖本 stage 全量。 | MVP-BE-TR-014 | QA + Development Orchestrator | Open |

## Completion Rule
本 increment 只有在 MVP-BE-TR-013 和 MVP-BE-TR-014 的 code/test/release evidence 更新、gaps 关闭或明确例外记录后，才能标记为 Done。
