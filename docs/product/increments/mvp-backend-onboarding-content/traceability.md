# MVP Backend Onboarding Content Traceability

## 状态
Draft - onboarding/content traceability matrix。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 onboarding/content traceability rows。 |

## Traceability Chain
`docs/product/roadmap.md`
-> `docs/product/stages/mvp-backend-foundation.md`
-> `docs/product/increments/mvp-backend-onboarding-content/definition.md`
-> `requirements.md`
-> `spec.md`
-> `acceptance.md`
-> `traceability.md`

## Traceability Matrix
| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MVP-BE-TR-003 | MVP-SI-003 | `mvp-backend-onboarding-content` | MVP-BE-FR-003 onboarding and learning route | MVP-BE-SPEC-003 | AC-MVP-BE-003 | OpenAPI `/onboarding/assessment`; Product Base FR-002 | Existing partial schema/entities: `backend/src/main/java/com/speakeasy/identity/OnboardingAssessment.java`, `LearningRoute.java`; controller/service pending | Backend tests pending | Not started | Planned | MVP-BE-GAP-003 |
| MVP-BE-TR-004 | MVP-SI-004 | `mvp-backend-onboarding-content` | MVP-BE-FR-004 official scenario content | MVP-BE-SPEC-004 | AC-MVP-BE-004 | OpenAPI `/scenarios`; Product Base FR-003 | Existing partial schema/entities: `backend/src/main/java/com/speakeasy/content/`; content seed/API pending | Backend content and boundary tests pending | Not started | Planned | MVP-BE-GAP-003, MVP-BE-GAP-004 |
| MVP-BE-TR-005 | MVP-SI-005 | `mvp-backend-onboarding-content` | MVP-BE-FR-005 user scenario state and home summary | MVP-BE-SPEC-005 | AC-MVP-BE-005 | OpenAPI/user state or home summary contract to confirm | Missing | Backend + Flutter integration tests pending | Not started | Planned | MVP-BE-GAP-004 |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-BE-GAP-003 | 首评、learning route、official scenario content 有 schema/OpenAPI 基础，但缺完整 controller/service/seed/versioning。 | MVP-BE-TR-003, MVP-BE-TR-004 | Backend + Domain Schema | Open |
| MVP-BE-GAP-004 | 加入/移除/当前场景、首页学习状态和下一步建议仍主要由前端/本地状态承接。 | MVP-BE-TR-004, MVP-BE-TR-005 | Backend + Frontend + QA | Open |

## Completion Rule
本 increment 只有在 MVP-BE-TR-003 到 MVP-BE-TR-005 的 code/test evidence 更新、gaps 关闭或明确例外记录后，才能标记为 Done。
