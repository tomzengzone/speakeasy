# Increment Definition：MVP OpenAPI Client、QA 与发布证据

## 状态
Draft - MVP backend-first stage planned increment。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 client/QA/release 切片定义。 |

## Increment ID
`mvp-backend-client-qa-release`

## Active Stage
`docs/product/stages/mvp-backend-foundation.md`

## Primary Feature
`server-backed-learning-foundation`

## Affected Features
- `access-onboarding`
- `official-scenario-library`
- `expression-practice-queue`
- `voice-scenario-practice`
- `learning-memory-review`
- `profile-membership`
- `scoring-feedback`

## 上游决策
- MVP backend stage：`docs/product/stages/mvp-backend-foundation.md`
- All MVP backend increments under `docs/product/increments/mvp-backend-*/`
- OpenAPI source of truth：`docs/architecture/openapi/speakeasy-api.yaml`
- Product Base traceability：`docs/product/base/traceability.md`

## Scope
- OpenAPI 与所有 MVP backend endpoints 对齐，消除 Flutter API client drift。
- 生成 Dart client 或建立等效强约束，防止旧路径和旧字段继续扩散。
- 建立 backend tests、contract tests、Flutter integration/e2e 或明确人工/外部依赖例外。
- 汇总 implementation report、quality report、test report 和 release readiness evidence。
- 对前五个 MVP backend increments 做全量追溯闭环检查。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| MVP-SI-013 | 通过 `MVP-BE-FR-013` 覆盖 OpenAPI 对齐、generated Dart client、Flutter integration 和 endpoint drift 清理。 |
| MVP-SI-014 | 通过 `MVP-BE-FR-014` 覆盖后端测试、契约测试、Flutter integration/e2e、报告和 release evidence。 |

## Excluded Stage Scope Items
- MVP-SI-001 到 MVP-SI-012 的功能实现由前五个 MVP backend increments 负责；本 increment 负责集成、验证和证据闭环。

## Required Product Artifacts
- `docs/product/increments/mvp-backend-client-qa-release/requirements.md`
- `docs/product/increments/mvp-backend-client-qa-release/spec.md`
- `docs/product/increments/mvp-backend-client-qa-release/acceptance.md`
- `docs/product/increments/mvp-backend-client-qa-release/traceability.md`

## Required Downstream Gates
- API Contract/OpenAPI：lint、contract gate、Dart client drift gate。
- Frontend：client migration、endpoint drift cleanup、offline/placeholder exception handling。
- QA：test plan and execution evidence for MVP-SI-001 to MVP-SI-014.
- Release/Documentation：implementation report、quality report、test report、release readiness note。
- Product Object Governance Check：全量 stage traceability review。

## Non-goals
- 不替代各业务 increment 的功能实现。
- 不新增 Product Base 范围外需求。
- 不把未实现的 P0/P0.1/P0.2/P1/P2 能力作为 MVP release evidence。

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent；还需 Documentation Governance 和 QA 复核。
