# MVP Backend Membership Boundary Traceability

## 状态
Draft - membership/boundary traceability matrix。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 membership/boundary traceability rows。 |

## Traceability Chain
`docs/product/roadmap.md`
-> `docs/product/stages/mvp-backend-foundation.md`
-> `docs/product/increments/mvp-backend-membership-boundary/definition.md`
-> `requirements.md`
-> `spec.md`
-> `acceptance.md`
-> `traceability.md`

## Traceability Matrix
| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MVP-BE-TR-011 | MVP-SI-011 | `mvp-backend-membership-boundary` | MVP-BE-FR-011 account deletion and data processing | MVP-BE-SPEC-011 | AC-MVP-BE-011 | OpenAPI delete account paths; security/data policy to confirm | Existing partial: `backend/src/main/java/com/speakeasy/ops/AccountDeletionJob.java`, `AuditLog.java`; full data deletion pending | Account deletion/data deletion tests pending | Not started | Foundation partial | MVP-BE-GAP-008 |
| MVP-BE-TR-012 | MVP-SI-012 | `mvp-backend-membership-boundary` | MVP-BE-FR-012 MVP membership/report boundary | MVP-BE-SPEC-012 | AC-MVP-BE-012 | Product Base FR-011; P0 commercial readiness boundary | Existing partial commercial foundation; MVP boundary endpoints pending | Boundary/placeholder tests pending | Not started | Foundation partial | MVP-BE-GAP-009 |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-BE-GAP-008 | 账号删除已有 foundation，但缺 Product Base 学习数据删除/匿名化完整执行和验收证据。 | MVP-BE-TR-011 | Backend + Security + QA | Open |
| MVP-BE-GAP-009 | 会员/报告/占位页只需 MVP 边界事实，不应误升级为完整商业订阅；需防止与 P0 商业化 scope 混淆。 | MVP-BE-TR-012 | Product Manager + Backend + Frontend | Open |

## Completion Rule
本 increment 只有在 MVP-BE-TR-011 和 MVP-BE-TR-012 的 code/test evidence 更新、gaps 关闭或明确例外记录后，才能标记为 Done。
