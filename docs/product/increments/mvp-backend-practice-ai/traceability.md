# MVP Backend Practice AI Traceability

## 状态
Draft - practice/AI traceability matrix。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 practice/AI traceability rows。 |

## Traceability Chain
`docs/product/roadmap.md`
-> `docs/product/stages/mvp-backend-foundation.md`
-> `docs/product/increments/mvp-backend-practice-ai/definition.md`
-> `requirements.md`
-> `spec.md`
-> `acceptance.md`
-> `traceability.md`

## Traceability Matrix
| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MVP-BE-TR-006 | MVP-SI-006 | `mvp-backend-practice-ai` | MVP-BE-FR-006 provider gateway | MVP-BE-SPEC-006 | AC-MVP-BE-006 | OpenAPI AI/voice paths; `docs/ai_runtime/prompt_contract.md` | Missing backend provider gateway | Provider mocked tests pending | Not started | Planned | MVP-BE-GAP-005 |
| MVP-BE-TR-008 | MVP-SI-008 | `mvp-backend-practice-ai` | MVP-BE-FR-008 practice session lifecycle | MVP-BE-SPEC-008 | AC-MVP-BE-008 | OpenAPI `/practice/sessions` family | Missing backend session controllers/services/entities | Session lifecycle tests pending | Not started | Planned | MVP-BE-GAP-005, MVP-BE-GAP-007 |
| MVP-BE-TR-009 | MVP-SI-009 | `mvp-backend-practice-ai` | MVP-BE-FR-009 feedback and recoverable failure | MVP-BE-SPEC-009 | AC-MVP-BE-009 | OpenAPI turn/feedback schemas; AI runtime schema | Missing feedback persistence/gateway | Feedback schema/failure tests pending | Not started | Planned | MVP-BE-GAP-005, MVP-BE-GAP-007 |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-BE-GAP-005 | AI/ASR/TTS/pronunciation provider 网关、secret 边界、重试和失败兜底未完成。 | MVP-BE-TR-006, MVP-BE-TR-008, MVP-BE-TR-009 | Backend + AI Runtime + Security | Open |
| MVP-BE-GAP-007 | Practice session/turn/complete/recovery API 未实现，教练反馈 schema 与持久化证据未闭环。 | MVP-BE-TR-008, MVP-BE-TR-009 | Backend + AI Runtime + QA | Open |

## Completion Rule
本 increment 只有在 MVP-BE-TR-006、MVP-BE-TR-008 和 MVP-BE-TR-009 的 code/test evidence 更新、gaps 关闭或明确例外记录后，才能标记为 Done。
