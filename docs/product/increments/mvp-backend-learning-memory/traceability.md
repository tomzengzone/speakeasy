# MVP Backend Learning Memory Traceability

## 状态
Draft - learning/memory traceability matrix。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 learning/memory traceability rows。 |

## Traceability Chain
`docs/product/roadmap.md`
-> `docs/product/stages/mvp-backend-foundation.md`
-> `docs/product/increments/mvp-backend-learning-memory/definition.md`
-> `requirements.md`
-> `spec.md`
-> `acceptance.md`
-> `traceability.md`

## Traceability Matrix
| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MVP-BE-TR-007 | MVP-SI-007 | `mvp-backend-learning-memory` | MVP-BE-FR-007 expression queue/review/favorites | MVP-BE-SPEC-007 | AC-MVP-BE-007 | OpenAPI expression/review/favorite contracts to confirm; Product Base FR-005/FR-006 | Missing backend persistence/API | Queue/favorite/review tests pending | Not started | Planned | MVP-BE-GAP-006 |
| MVP-BE-TR-010 | MVP-SI-010 | `mvp-backend-learning-memory` | MVP-BE-FR-010 learning evidence and memory | MVP-BE-SPEC-010 | AC-MVP-BE-010 | OpenAPI `/learning/evidence`, `/learning/mastery`; domain progress/review models | Missing backend persistence/API | Evidence/mastery/history tests pending | Not started | Planned | MVP-BE-GAP-006 |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-BE-GAP-006 | 推荐表达、收藏、复习、learning evidence、mastery、history 和 personal wiki 缺服务端持久化闭环。 | MVP-BE-TR-007, MVP-BE-TR-010 | Backend + Domain Schema + QA | Open |

## Completion Rule
本 increment 只有在 MVP-BE-TR-007 和 MVP-BE-TR-010 的 code/test evidence 更新、gaps 关闭或明确例外记录后，才能标记为 Done。
