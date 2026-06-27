# Increment Definition：MVP 账号删除与会员边界后端

## 状态
Draft - MVP backend-first stage planned increment。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 membership/boundary 切片定义。 |

## Increment ID
`mvp-backend-membership-boundary`

## Active Stage
`docs/product/stages/mvp-backend-foundation.md`

## Primary Feature
`server-backed-learning-foundation`

## Affected Features
- `profile-membership`
- `access-onboarding`
- `learning-memory-review`
- `commercial-subscription`

## 上游决策
- Product Base：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`
- MVP backend stage：`docs/product/stages/mvp-backend-foundation.md`
- P0 commercial readiness exists separately：`docs/product/increments/commercial-subscription-readiness/`

## Scope
- Product Base 账号注销、退出登录、云端学习数据删除或匿名化、审计记录和用户可理解状态。
- MVP 会员页、学习报告和占位页的服务端边界事实。
- 明确 Android 支付、完整权益 gating、Apple/Google 真实订阅校验和商业风控不属于 MVP backend completion。
- 与 P0 commercial readiness 建立边界，避免把商业订阅 scope 误标为 MVP 后端完成条件。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| MVP-SI-011 | 通过 `MVP-BE-FR-011` 覆盖 account deletion、云端学习数据删除/匿名化和审计边界。 |
| MVP-SI-012 | 通过 `MVP-BE-FR-012` 覆盖 MVP membership/report/placeholder boundary 和非商业化限制。 |

## Excluded Stage Scope Items
- 完整商业订阅上线继续由 `commercial-subscription-readiness` 管理。
- 学习数据主体写入由 `mvp-backend-learning-memory` 管理，本 increment 负责删除/匿名化边界。

## Required Product Artifacts
- `docs/product/increments/mvp-backend-membership-boundary/requirements.md`
- `docs/product/increments/mvp-backend-membership-boundary/spec.md`
- `docs/product/increments/mvp-backend-membership-boundary/acceptance.md`
- `docs/product/increments/mvp-backend-membership-boundary/traceability.md`

## Required Downstream Gates
- Domain/Security：account deletion job、audit log、learning data deletion/anonymization policy。
- API Contract：delete account、deletion status、membership/report boundary endpoints。
- Backend：deletion workflow、audit、placeholder/boundary responses。
- Frontend：会员/报告/占位页不误展示未兑现商业权益。
- QA：删除、退出、占位、Android 未接入、商业边界防误验收。

## Non-goals
- 不实现 Apple/Google 真实订阅校验。
- 不实现完整商业权益 gating。
- 不实现离线内容包、成就系统或学习报告产品化。

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent。
