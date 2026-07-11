# 场景练习 Runtime 迁移需求

## 状态
架构设计已就绪。本文件是后续前端-only 架构迁移的需求输入，不代表实现批准。

## 产品对象
- 分类：`frontend-architecture-refactor`
- Increment：`scenario-practice-runtime-migration`
- Active stage：`docs/product/stages/p0-1-expression-automation.md`
- Capability classification：`behavior-preserving architecture support`
- Primary Capability ID：无；本 increment 只重构现有 Runtime/SWC 边界，不拥有或新增业务 Capability
- Affected Capability IDs：`CAP-LEVEL`、`CAP-PLAN`、`CAP-CONTENT`、`CAP-PRACTICE`、`CAP-TRAIN`、`CAP-COACH`、`CAP-MEMORY`、`CAP-NOTE`
- Affected Sub-capability IDs：无；本 increment 保持现有行为，不修改 Sub-capability 边界

## Stage Scope 覆盖
这是一个 refactor increment，只为现有 P0.1 相关行为提供架构证据，不得声明新增 stage scope 已完成。

| Stage Scope ID | Coverage status |
| --- | --- |
| P01-SI-001 | Refactor evidence only: preserves existing official scenario entry and recovery boundaries. |
| P01-SI-005 | Refactor evidence only: preserves hint/coaching boundaries. |
| P01-SI-007 | Refactor evidence only: preserves voice-first/text-fallback runtime boundaries. |
| P01-SI-008 | Refactor evidence only: preserves feedback/scoring boundaries. |
| P01-SI-009 | Refactor evidence only: preserves learning memory/wiki/queue write boundaries. |
| P01-SI-011 | Refactor evidence only: preserves recoverable failure and session recovery boundaries. |

## 功能需求

### MIG-FR-001 当前主流程分类
架构必须将 `lib/features/interview/` 分类为当前主练习路径，并分配给目标 SWC `FE-SCENARIO-PRACTICE`；同时必须明确记录该代码路径在迁移期间仍是 legacy-compatible 物理路径。

### MIG-FR-002 Legacy sandbox 分类
架构必须将 `lib/features/scenario/` 分类为 `FE-LEGACY-SCENARIO-SANDBOX`，标记为 legacy / non-main-flow，并禁止在该路径内新增功能扩展。

### MIG-FR-003 共享 practice runtime 抽取
在创建或扩展任何第三套 scenario-practice feature package 之前，迁移必须先定义 `FE-PRACTICE-RUNTIME` 的共享 runtime 职责：voice capture、message loop、TTS/playback coordination、feedback recorder、session recovery、retry/fallback state 和 runtime telemetry hooks。

### MIG-FR-004 领域逻辑留在 scenario practice
Interview/onboarding expression graph、mastery、wiki、daily queue、scene dialogue、listening/shadowing 和 reviewed content 逻辑必须继续由 `FE-SCENARIO-PRACTICE` 拥有，直到单独的领域迁移获得批准。

### MIG-FR-005 不产生后端契约漂移
本迁移不得改变 OpenAPI、后端 source-of-truth 规则、DB schema、provider routing、media trust、entitlement、usage、audit 或 learning evidence 归属。

### MIG-FR-006 完整现有功能清单
架构必须列出当前参与主练习、legacy sandbox、部分共享 scene application coordinators、audio services、API client、local cache 和 training boundary 的所有现有 SWC/文件，并说明它们当前承载的功能需求。

### MIG-FR-007 完整目标功能分配
每个需要保留的当前功能都必须映射到目标 SWC，并明确 responsibility、non-responsibility、input、output、dependency、owned data、API usage 和 test responsibility。

### MIG-FR-008 完整 runtime 数据流
迁移必须定义 session start/resume、scene graph/content load、voice capture and ASR、text fallback submit、AI/NPC/coach turn、TTS/playback、hint request、feedback/review、wiki/learning memory updates、practice history、exit/recovery 和 legacy sandbox 行为的完整成功路径和失败路径。

### MIG-FR-009 复用和禁止边界
迁移必须识别必须复用的现有 SWC，并明确禁止 duplicate runtime loops、duplicate voice capture services、duplicate TTS wrappers、duplicate local stores、direct provider calls、client-generated trusted media refs 和 local final-mastery writes。

### MIG-FR-010 迁移切片和门禁
实现计划必须把迁移拆成安全切片，保持 route-preserving 行为，配套 focused tests、static guards，并在编码开始前通过独立 Software Architecture Governance Check。

### MIG-FR-011 Practice history 和 stats adapter 一致性
迁移必须明确处理 practice history recording 和 stats synchronization。当前 legacy sandbox 通过 `AppSession.recordPracticeSession`、`AppSession.upsertPracticeFeedback`、`SessionStatsCoordinator`、`StatsService` 和 `ApiClient` 写入 practice history，而当前 interview 主流程尚未证明写入同一路径。迁移必须新增共享 `PracticeHistoryRecorder` adapter 来保留行为，或在实现前明确把 interview history parity 标记为 non-goal。

## 非功能需求
- 除非后续产品文档明确批准行为变化，迁移必须保留当前用户可见行为。
- Runtime 抽取必须降低 page-level coupling，并让 voice/message/session recovery 可以脱离大型 widget 测试。
- 抽取 runtime mechanics 时不得意外丢失 practice history 和 stats synchronization。
- SWC ID 必须稳定，并能被下游实现任务引用。
- 局部例外必须有 owner、expiry condition 和 no-product-expansion 说明。

## 非目标
- 本增量不修改代码。
- 架构-only 规划期间不做 route rename 或 package move。
- 不修改后端、API、数据库或 provider。
- `FE-PRACTICE-RUNTIME` 抽取完成前，不创建第三套 `scenario_practice` implementation package。
