# Increment Definition：MVP 后端基础与认证

## 状态
Draft - MVP backend-first stage planned increment。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 MVP 后端基础与认证切片定义。 |

## Increment ID
`mvp-backend-foundation-auth`

## Active Stage
`docs/product/stages/mvp-backend-foundation.md`

## Primary Feature
`server-backed-learning-foundation`

## Affected Features
- `access-onboarding`
- `profile-membership`
- `official-scenario-library`
- `voice-scenario-practice`
- `learning-memory-review`

## 上游决策
- Product Base：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`
- MVP backend stage：`docs/product/stages/mvp-backend-foundation.md`
- OpenAPI source of truth：`docs/architecture/openapi/speakeasy-api.yaml`
- 当前 backend partial evidence：`backend/`

## Scope
- 后端应用运行时、配置、PostgreSQL/Flyway migration、repository/service/controller 基础。
- 统一 API response/error semantics，保持 OpenAPI-first。
- 手机号、Apple、微信登录接口的 MVP 后端事实边界。
- refresh/logout/session token/current user/profile 最小闭环。
- 保留当前已实现 backend skeleton 和 auth partial evidence，不扩大到完整商业账号体系。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| MVP-SI-001 | 通过 `MVP-BE-FR-001` 覆盖后端 runtime、PostgreSQL、Flyway、统一响应和错误模型。 |
| MVP-SI-002 | 通过 `MVP-BE-FR-002` 覆盖 auth/session/current user/profile 后端事实。 |

## Excluded Stage Scope Items
- MVP-SI-003 到 MVP-SI-014 由后续 MVP backend increments 覆盖。

## Uncovered Required Stage Scope Items
- 无。本 increment 覆盖其承诺的 required Stage Scope Items；跨 increment 全量覆盖见 `docs/product/stages/mvp-backend-foundation.md`。

## Required Product Artifacts
- `docs/product/increments/mvp-backend-foundation-auth/requirements.md`
- `docs/product/increments/mvp-backend-foundation-auth/spec.md`
- `docs/product/increments/mvp-backend-foundation-auth/acceptance.md`
- `docs/product/increments/mvp-backend-foundation-auth/traceability.md`

## Required Downstream Gates
- Domain/API：确认用户、身份、session、profile、error response 与 OpenAPI 一致。
- Backend：补齐或确认 controller/service/repository/migration。
- Frontend：清理 Flutter auth/current user endpoint drift。
- QA：后端单元/集成测试、OpenAPI contract gate、auth lifecycle regression。
- Product Object Governance Check：确认未把 P0 商业账号 scope 混入本 MVP 切片。

## Non-goals
- 不实现完整 Apple/Google 订阅校验。
- 不实现 P0 商业权益 gating。
- 不实现 P0.1 训练 Agent。

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent；实现完成后还需 QA 和 Documentation Governance 复核。
