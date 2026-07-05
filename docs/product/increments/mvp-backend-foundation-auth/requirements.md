# MVP Backend Foundation Auth Requirements

## 状态
Draft - derived from `docs/product/stages/mvp-backend-foundation.md`。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 foundation/auth requirement IDs。 |

## Owner
Requirement Development Agent

## 上游输入
- `docs/product/stages/mvp-backend-foundation.md`
- `docs/product/base/requirements.md`
- `docs/product/base/traceability.md`
- `docs/architecture/openapi/speakeasy-api.yaml`

## Requirement Coverage
| Requirement ID | Stage Scope ID | Requirement |
| --- | --- | --- |
| MVP-BE-FR-001 | MVP-SI-001 | 后端必须具备可运行 runtime、环境配置、PostgreSQL schema、Flyway migration、repository/service/controller 基础、统一 response envelope 和错误模型，并可通过测试验证 migration。 |
| MVP-BE-FR-002 | MVP-SI-002 | 后端必须承接 Product Base 登录/session/current user/profile 事实，覆盖登录、refresh、logout、token 校验、用户资料读取和失败返回，且与 OpenAPI 和 Flutter client 一致。 |

## Success Criteria
- SC-MVP-BE-001：backend 应用可在测试环境启动并执行 migration。
- SC-MVP-BE-002：migration 能在 H2 PostgreSQL mode 和真实 PostgreSQL 测试中验证。
- SC-MVP-BE-003：auth/session endpoints 的 request/response 与 OpenAPI 一致。
- SC-MVP-BE-004：current user/profile 能返回 Product Base 所需的用户状态和 profile 字段。
- SC-MVP-BE-005：错误响应不泄露内部异常，且客户端能处理 unauthenticated、invalid token、expired token 和 validation error。

## Non-goals
- 不要求真实短信、微信、Apple provider 全环境可用；本 increment 可先用 provider boundary 或测试替身，但必须保留生产实现接口。
- 不把会员权益、支付或商业风控写入本 increment 完成条件。

## Downstream Artifacts
- `docs/product/increments/mvp-backend-foundation-auth/spec.md`
- `docs/product/increments/mvp-backend-foundation-auth/acceptance.md`
- `docs/product/increments/mvp-backend-foundation-auth/traceability.md`
