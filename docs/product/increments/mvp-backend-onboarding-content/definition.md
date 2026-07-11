# Increment Definition：MVP 首评、学习路线与官方内容后端

## 状态
Draft - MVP backend-first stage planned increment。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 onboarding/content 切片定义。 |

## Increment ID
`mvp-backend-onboarding-content`

## Active Stage
`docs/product/stages/mvp-backend-foundation.md`

## Primary Capability
- Capability ID：`CAP-CONTENT`
- Sub-capability ID：`CAP-CONTENT-01`

## Affected Capabilities
- Capability IDs：`CAP-LEVEL`、`CAP-INTENT`、`CAP-PLAN`
- Sub-capability IDs：`CAP-CONTENT-02`、`CAP-CONTENT-03`、`CAP-LEVEL-02`、`CAP-INTENT-01`、`CAP-INTENT-03`、`CAP-INTENT-04`、`CAP-PLAN-03`

## 上游决策
- Product Base：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`
- MVP backend stage：`docs/product/stages/mvp-backend-foundation.md`
- OpenAPI source of truth：`docs/architecture/openapi/speakeasy-api.yaml`

## Scope
- 首评 assessment 和 Product Base 场景映射持久化。
- `job_interview` 与 `onboarding_introduction` 官方场景、版本、L1/L2/L3 等级和目标表达内容的服务端 seed/version/API。
- 加入、移除、设为当前场景、切换等级和首页学习状态的服务端承接。
- 保持当前 MVP 边界：不新增第三个场景，不承诺任意场景生成。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| MVP-SI-003 | 通过 `MVP-BE-FR-003` 覆盖首评 assessment、学习路线和场景映射持久化。 |
| MVP-SI-004 | 通过 `MVP-BE-FR-004` 覆盖官方场景、版本、等级、target expressions 和内容 API。 |
| MVP-SI-005 | 通过 `MVP-BE-FR-005` 覆盖加入/移除/当前场景、首页学习状态和下一步建议。 |

## Excluded Stage Scope Items
- MVP-SI-001、MVP-SI-002 由 `mvp-backend-foundation-auth` 覆盖。
- MVP-SI-006 到 MVP-SI-014 由后续 MVP backend increments 覆盖。

## Required Product Artifacts
- `docs/product/increments/mvp-backend-onboarding-content/requirements.md`
- `docs/product/increments/mvp-backend-onboarding-content/spec.md`
- `docs/product/increments/mvp-backend-onboarding-content/acceptance.md`
- `docs/product/increments/mvp-backend-onboarding-content/traceability.md`

## Required Downstream Gates
- Domain Schema：assessment、learning route、scenario、scenario version、scenario level、target expression。
- API Contract：`/onboarding/assessment`、`/scenarios`、scenario detail/level、user scene state/home summary。
- Backend：controller/service/seed/versioning/migration。
- Frontend：把本地-first onboarding/content 状态接入 canonical API 或记录离线例外。
- QA：内容 seed、场景边界、首页状态和场景选择回归。

## Non-goals
- 不新增内容包或 CMS。
- 不实现 P0.1 action chain/micro-action。
- 不实现 P0.2 跨天 planner。

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent。
