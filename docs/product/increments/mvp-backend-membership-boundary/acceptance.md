# MVP Backend Membership Boundary Acceptance

## 状态
Draft - membership/boundary acceptance criteria。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 membership/boundary AC。 |

## Owner
Acceptance Criteria Generate Skill

## Acceptance Coverage Map
| AC | Stage Scope ID | FR | Spec |
| --- | --- | --- | --- |
| AC-MVP-BE-011 | MVP-SI-011 | MVP-BE-FR-011 | MVP-BE-SPEC-011 |
| AC-MVP-BE-012 | MVP-SI-012 | MVP-BE-FR-012 | MVP-BE-SPEC-012 |

## AC-MVP-BE-011 Account Deletion And Data Processing
- 给定用户请求注销账号，后端必须创建 deletion job 或完成同步删除，并返回可理解状态。
- 给定注销完成，后续使用该用户 session/token 请求受保护资源必须失败。
- 给定用户存在 Product Base 学习数据，删除或匿名化策略必须覆盖这些数据，或在 traceability 中记录明确例外。
- 给定删除过程失败，后端必须返回可恢复或可解释错误，并保留审计证据。

## AC-MVP-BE-012 MVP Membership And Report Boundary
- 给定客户端请求会员状态，后端必须返回 MVP 边界状态，不得伪造完整商业权益。
- 给定 Android 用户请求订阅购买或恢复，必须返回未接入/平台受限状态，不能验收为购买闭环。
- 给定学习报告无数据或未完整实现，后端必须返回空状态或 placeholder，不得返回虚假报告。
- 给定离线内容或成就未实现，后端必须返回 placeholder/empty 状态。
- 给定商业订阅能力未通过 `commercial-subscription-readiness`，本 increment 不得把真实支付、权益 gating 或商业风控标记完成。

## Traceability
完整追溯见 `docs/product/increments/mvp-backend-membership-boundary/traceability.md`。
