# Increment Definition：MVP 推荐表达与学习记忆后端

## 状态
Draft - MVP backend-first stage planned increment。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 learning/memory 切片定义。 |

## Increment ID
`mvp-backend-learning-memory`

## Active Stage
`docs/product/stages/mvp-backend-foundation.md`

## Primary Feature
`server-backed-learning-foundation`

## Affected Features
- `expression-practice-queue`
- `learning-memory-review`
- `voice-scenario-practice`
- `scoring-feedback`
- `official-scenario-library`

## 上游决策
- Product Base：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`
- MVP backend stage：`docs/product/stages/mvp-backend-foundation.md`
- Domain inputs：`docs/domain/expression_model.md`、`docs/domain/user_progress_model.md`、`docs/domain/review_model.md`
- OpenAPI source of truth：`docs/architecture/openapi/speakeasy-api.yaml`

## Scope
- 推荐表达队列、复习、收藏、表达任务进度和表达变体的后端承接。
- Learning evidence、session summary、mastery、weakness、history 和 personal wiki 的服务端持久化。
- Practice/AI increment 产出的 evidence candidate 进入确定性学习事实写入规则。
- 只覆盖 Product Base 已接受的本地学习沉淀迁移，不实现 P0.2 跨天智能 planner。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| MVP-SI-007 | 通过 `MVP-BE-FR-007` 覆盖推荐表达队列、复习、收藏和表达任务进度。 |
| MVP-SI-010 | 通过 `MVP-BE-FR-010` 覆盖 learning evidence、summary、mastery、weakness、history 和 personal wiki。 |

## Excluded Stage Scope Items
- Practice session lifecycle 和 provider gateway 由 `mvp-backend-practice-ai` 覆盖。
- P0.2 daily planner、cross-session pressure ladder 和 L0-L5 完整阶梯不属于本 increment。

## Required Product Artifacts
- `docs/product/increments/mvp-backend-learning-memory/requirements.md`
- `docs/product/increments/mvp-backend-learning-memory/spec.md`
- `docs/product/increments/mvp-backend-learning-memory/acceptance.md`
- `docs/product/increments/mvp-backend-learning-memory/traceability.md`

## Required Downstream Gates
- Domain Schema：expression progress、favorite、review item、learning evidence、mastery/weakness、history。
- API Contract：queue、favorites、review、learning evidence、mastery/history。
- Backend：persistence、dedupe、deterministic write rules。
- Frontend：本地状态到后端同步或明确离线例外。
- QA：队列去重、收藏去重、summary write-back、history/mastery visibility。

## Non-goals
- 不实现完整 P0.2 long-term planner。
- 不让 LLM 直接写入最终 mastery。
- 不把收藏自动生成复习任务作为 Product Base 完成条件。

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent。
