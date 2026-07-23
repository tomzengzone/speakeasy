# Increment Definition：场景练习 Runtime 迁移

## 状态
架构设计已就绪。本增量只生成迁移架构与执行计划，不修改业务代码。实现开始前必须通过 Software Architecture Governance Check。

## Increment ID
`scenario-practice-runtime-migration`

## 变更分类
`frontend-architecture-refactor`

## Active Stage
`docs/product/stages/p0-1-expression-automation.md`

本增量是 P0.1 相关主练习链路的架构迁移准备工作，不新增 stage、不新增产品能力、不扩大 P0.1 范围。

## Capability Classification
- Classification type：`behavior-preserving architecture support`
- Primary Capability ID：无；本 increment 只重构现有 Runtime/SWC 边界，不拥有或新增业务 Capability
- Affected Capability IDs：`CAP-LEVEL`、`CAP-PLAN`、`CAP-CONTENT`、`CAP-PRACTICE`、`CAP-TRAIN`、`CAP-COACH`、`CAP-MEMORY`、`CAP-NOTE`
- Affected Sub-capability IDs：无；本 increment 保持现有行为，不修改 Sub-capability 边界

## 上游决策
- `docs/architecture/software_component_architecture.md`
- `docs/architecture/swc_catalog.md`
- `docs/architecture/module_boundary.md`
- `docs/architecture/data_flow.md`
- `docs/product/increments/p0-1-expression-automation-training/`
- 代码证据：
  - `lib/features/interview/` 是当前主练习路径。
  - `lib/features/scenario/` 是现有 generic scenario sandbox，不是当前主流程。
  - `lib/application/scene/` 已包含部分共享 scene/practice coordinators。

## Frontend-Only 决策
只有当实现限制在以下范围内时，本迁移才保持 frontend-only：
- SWC rename/classification 和 module-boundary cleanup。
- 从 `lib/features/interview/`、`lib/features/scenario/` 和 `lib/application/scene/` 抽取可复用 frontend runtime primitives，归入共享 practice runtime 边界。
- 改接现有前端页面以复用该 runtime，同时保持当前 API 调用、backend DTO、storage semantics、route behavior 和 product scope 不变。
- 将 `lib/features/scenario/` 标记为 legacy / non-main-flow，并阻止新增扩展。

如果任何实现改变以下内容，本迁移立即不再是 frontend-only：
- OpenAPI path、request/response/error schema、schema version、idempotency contract 或 auth rule。
- TrainingSession、PracticeSession、LearningEvidence、MediaAsset、entitlement、usage、audit 或 provider operations 的 backend-owned facts。
- Database migration 或 persistence ownership。
- AI provider routing、media upload trust、provider credentials 或 server-side usage reservation。

## 范围
- 将当前 `lib/features/interview/` 主流程定义为 SWC `FE-SCENARIO-PRACTICE`，并在迁移期间保持该路径 legacy-compatible。
- 将 `lib/features/scenario/` 定义为 SWC `FE-LEGACY-SCENARIO-SANDBOX`；它保持 non-main-flow，且不得承接新产品扩展。
- 为可复用 voice capture、message loop、TTS、feedback recorder 和 session recovery 定义目标共享 SWC `FE-PRACTICE-RUNTIME`。
- 迁移完成前，interview/onboarding expression graph、mastery、wiki、learning queue 和 reviewed content 逻辑继续保留在 `FE-SCENARIO-PRACTICE`。
- 实现前产出所有被迁移行为的完整 SWC 数据流。

## 非目标
- 本增量不做代码变更。
- 共享 runtime 抽取设计并获批前，不新增 `lib/features/scenario_practice/` package。
- 不变更 backend、database、OpenAPI、provider、entitlement、usage 或 media storage。
- 不新增 official scenario、arbitrary scene generation、CMS、content expansion 或 commercial gating change。
- 不声明 Product Base acceptance；本文只为后续迁移实现做架构准备。

## 必需产物
- `docs/product/increments/scenario-practice-runtime-migration/requirements.md`
- `docs/product/increments/scenario-practice-runtime-migration/spec.md`
- `docs/product/increments/scenario-practice-runtime-migration/acceptance.md`
- `docs/product/increments/scenario-practice-runtime-migration/test_cases.md`
- `docs/product/increments/scenario-practice-runtime-migration/traceability.md`
- `docs/product/increments/scenario-practice-runtime-migration/swc_allocation.md`
- Global SWC baseline 更新：
  - `docs/architecture/swc_catalog.md`
  - `docs/architecture/software_component_architecture.md`
  - `docs/architecture/module_boundary.md`
  - `docs/architecture/data_flow.md`
- 独立审查结果记录在 `docs/reports/quality_report.md`

## Owner Agent
System Architect Agent

## Checker Agent
Software Architecture Governance Check Agent
