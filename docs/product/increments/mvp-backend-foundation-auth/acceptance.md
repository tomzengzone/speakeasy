# MVP Backend Foundation Auth Acceptance

## 状态
Draft - foundation/auth acceptance criteria。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 foundation/auth AC。 |

## Owner
Acceptance Criteria Generate Skill

## Acceptance Coverage Map
| AC | Stage Scope ID | FR | Spec |
| --- | --- | --- | --- |
| AC-MVP-BE-001 | MVP-SI-001 | MVP-BE-FR-001 | MVP-BE-SPEC-001 |
| AC-MVP-BE-002 | MVP-SI-002 | MVP-BE-FR-002 | MVP-BE-SPEC-002 |

## AC-MVP-BE-001 Backend Foundation
- 给定测试环境启动 backend，当 migrations 执行时，必须创建 Product Base 和 MVP backend 所需基础表、索引和约束，且重复启动不破坏 schema。
- 给定任一 controller 返回业务结果，响应必须使用 OpenAPI 对齐的 DTO/response envelope。
- 给定请求触发 validation、unauthenticated、forbidden 或 internal error，响应必须包含稳定错误码和可读消息，不得暴露 stack trace。
- 给定 migration 或 persistence 测试运行，必须能在 PostgreSQL-compatible 测试环境中验证。

## AC-MVP-BE-002 Auth And Current User
- 给定用户通过支持的登录方式提交有效凭据或测试替身，后端必须创建/解析用户并返回 access token 与 refresh token。
- 给定 access token 有效，调用 current user/profile 必须返回用户 ID、profile 状态和 Product Base 门禁所需状态。
- 给定 refresh token 有效，refresh 必须返回新的 token 结果；给定 refresh token 无效或过期，必须返回确定性错误。
- 给定用户 logout，后续使用同一会话 token 不得继续通过需要认证的请求。
- 给定 Flutter client 调用 auth/current user endpoints，不得使用与 OpenAPI 不一致的旧路径或旧字段。

## Traceability
完整追溯见 `docs/product/increments/mvp-backend-foundation-auth/traceability.md`。
