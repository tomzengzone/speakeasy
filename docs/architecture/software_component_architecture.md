# Software Component Architecture

## PR-003 current lineage

本次只切换来源链，不改变本文的 SWC 拓扑、数据流、边界或已接受实现事实。当前产品 lineage 仅由适用的 approved FR 解析；Engineering Artifact 之间的 direct/conditional inputs 和适用 Gate 继续仅由 Governance Contract 解析。文内旧 Product Base、Increment、Spec/AC、旧 TC/traceability、Increment SWC Allocation 及与旧链路绑定的 Gate/checker 表述均为 historical provenance，不是当前 authority、prerequisite 或 fallback。局部实现按事实影响引用当前 SWC/Flow，无需创建 increment allocation 文档。

## 状态
Proposed - global SWC architecture baseline. 本文是全局软件组件架构基准，用于汇总稳定 SWC 拓扑、全局 SWC 间数据流、跨层复用边界和局部变更参考规则。本文不替代 `docs/architecture/swc_catalog.md`、`docs/architecture/data_flow.md`、Domain Schema、OpenAPI、AI runtime、UX、测试或实现报告。

## 目的
本文件回答三个问题：
- 当前系统级 SWC 如何组成完整软件架构；
- 稳定 SWC 之间有哪些可复用的全局数据流；
- 局部 increment 架构设计应该继承哪个基准、何时必须更新全局基准。

## Source Of Truth Boundaries
| Concern | Source of truth | 本文职责 |
| --- | --- | --- |
| SWC 清单、职责、代码路径、接口、测试责任 | `docs/architecture/swc_catalog.md` | 引用 SWC ID，不重复完整表格 |
| 业务/跨边界数据流和事实源规则 | `docs/architecture/data_flow.md` | 抽象为 SWC-to-SWC 稳定流 |
| 模块/上下文边界 | `docs/architecture/module_boundary.md` | 继承边界原则并转成 SWC 依赖规则 |
| Domain entity、状态机、不变量 | `docs/domain/domain_schema.md` 和 `docs/domain/*_model.md` | 只引用实体，不定义语义 |
| API request/response/error schema | `docs/architecture/openapi/speakeasy-api.yaml` | 只引用 API family/path，不复制 schema |
| 增量 FR/AC 到 SWC 的落地分配 | `docs/product/increments/<increment-id>/swc_allocation.md` | 提供基准和 Flow ID，增量写 delta |

## Baseline Reference Rule
任何实现影响前端、后端、数据库、OpenAPI、AI runtime、provider、复用模块或 server-owned facts 的 increment，必须在 `swc_allocation.md` 中增加 `Baseline References`，至少列出：
- 本文件路径和适用 Flow ID；
- `docs/architecture/swc_catalog.md` 中被引用的 SWC ID；
- `docs/architecture/data_flow.md` 或 `docs/architecture/module_boundary.md` 中继承的全局规则；
- 如果本次变更改变稳定 SWC 拓扑或新增稳定 SWC，必须先更新本文和 `swc_catalog.md`，或记录明确的 proposed/legacy-compatible 迁移理由。

## System-Level Responsibility Allocation
| Layer | Owns | Must not own |
| --- | --- | --- |
| Frontend SWCs | UX rendering, route/session display state, local recording/playback, OpenAPI client usage, recoverable UI state, display cache | Server-owned facts, final entitlement, final mastery, provider secrets, provider-readable media refs |
| Backend SWCs | Auth, authorization, trusted business facts, application use cases, deterministic domain decisions, provider isolation, audit and deletion orchestration | UI layout, product priority, client-local display preferences |
| Database SWCs | Versioned migrations, table/index ownership, persistence evolution, audit/retention storage | Runtime business decisions, API schema ownership |
| AI runtime/provider SWCs | Prompt/schema/eval contracts, provider adapters behind backend gateway, typed fallback candidates | Final persistent facts, entitlement decisions, direct client credential access |
| Ops SWCs | Release gates, drift checks, observability, rollback evidence, retention and audit evidence | Product scope approval, feature requirements |

## Global SWC Topology
```text
FE-BOOTSTRAP-ROUTING
  -> FE-API-CLIENT
  -> feature frontend SWCs
      -> BE-API-CONTROLLERS
          -> backend application/domain SWCs
              -> DB-* SWCs
              -> BE-AI-GATEWAY -> AI-* provider/runtime SWCs
              -> BE-MEDIA-STORAGE -> provider/object-storage boundary
              -> BE-OPS-AUDIT-DELETION / BE-AI-OPS
          -> typed response/error
      -> FE-LOCAL-CACHE or UI state rendering
```

规则：
- 当存在 OpenAPI contract 时，Frontend feature SWC 只能通过 `FE-API-CLIENT` 调用 backend。
- `FE-PRACTICE-RUNTIME` 只拥有可复用 frontend mechanics；`FE-SCENARIO-PRACTICE` 拥有 official scenario practice domain logic；`FE-LEGACY-SCENARIO-SANDBOX` 保持 non-main-flow。
- Backend controller 必须委托给 service/domain SWC；不得绕过 domain、usage、entitlement、media、AI gateway、audit、retention 或 data-governance boundary。
- DB SWC 只能通过 owning backend service/repository 访问，不允许 direct cross-domain write。
- 适用时，provider call 必须经过 `BE-AI-GATEWAY`、`BE-MEDIA-STORAGE`、`BE-USAGE-CONTROL` 以及相关 provider/ops boundary。

## Canonical SWC Flow Library
| Flow ID | Flow | Stable SWC sequence | Canonical source |
| --- | --- | --- | --- |
| SWC-FLOW-AUTH-PROFILE | Login/profile/session bootstrap | `FE-BOOTSTRAP-ROUTING -> FE-AUTH-PROFILE -> FE-API-CLIENT -> BE-API-CONTROLLERS -> BE-IDENTITY -> DB-IDENTITY-CONTENT -> response -> FE-LOCAL-CACHE/display` | `module_boundary.md`, `api_contract.md` |
| SWC-FLOW-SUBSCRIPTION-ENTITLEMENT | Purchase, restore, entitlement refresh | `FE-COMMERCIAL -> FE-API-CLIENT -> BE-API-CONTROLLERS -> BE-COMMERCE-ENTITLEMENT -> DB-COMMERCE-USAGE -> BE-OPS-AUDIT-DELETION -> response -> FE-COMMERCIAL display cache` | `data_flow.md` P0 Subscription Purchase / Restore Flow |
| SWC-FLOW-USAGE-AI | Usage-gated AI/ASR/TTS/scoring call | `feature FE SWC -> FE-API-CLIENT -> BE-API-CONTROLLERS -> BE-USAGE-CONTROL -> BE-AI-GATEWAY -> AI-* provider -> BE-AI-OPS -> BE-USAGE-CONTROL commit/release -> response -> feature FE SWC` | `data_flow.md` P0 Commercial Usage Flow |
| SWC-FLOW-MEDIA-AUDIO-UPLOAD | Trusted audio upload and provider-readable ref | `FE-AUDIO-PLATFORM -> FE-API-CLIENT -> BE-API-CONTROLLERS -> BE-MEDIA-STORAGE -> DB-AI-MEDIA-OPS/object storage -> BE-AI-GATEWAY -> AI provider -> BE-AI-OPS -> response -> FE-AUDIO-PLATFORM/feature UI` | `data_flow.md` P0 Commercial AI Provider Hardening Flow |
| SWC-FLOW-SCENARIO-PRACTICE-RUNTIME | Frontend scenario practice runtime extraction and reuse | `FE-SCENARIO-PRACTICE/FE-LEGACY-SCENARIO-SANDBOX -> FE-PRACTICE-RUNTIME -> FE-AUDIO-PLATFORM/FE-LOCAL-CACHE/FE-API-CLIENT -> existing BE owner SWCs when remote calls apply -> response/cache -> feature UI` | `data_flow.md` Frontend Scenario Practice Runtime Migration Flow; `docs/product/increments/scenario-practice-runtime-migration/swc_allocation.md` |
| SWC-FLOW-TRAINING-TURN | Production training session and turn | `FE-TRAINING -> FE-API-CLIENT -> BE-API-CONTROLLERS -> BE-TRAINING -> BE-MEDIA-STORAGE/BE-AI-GATEWAY as needed -> BE-LEARNING -> DB-TRAINING-LEARNING -> response -> FE-TRAINING` | `data_flow.md` P0.1 Production-Hardened Training Flow |
| SWC-FLOW-GOAL-AUTOPILOT | Goal profile, diagnostic, planning and projection | `FE-GOAL-AUTOPILOT -> FE-API-CLIENT -> BE-API-CONTROLLERS -> BE-GOAL-AUTOPILOT -> BE-LEARNING/BE-USAGE-CONTROL/BE-AI-GATEWAY/BE-MEDIA-STORAGE as needed -> DB-GOAL-AUTOPILOT -> response -> FE-GOAL-AUTOPILOT` | `data_flow.md` P0.2 Followup-E Speaking Diagnostic Audio Flow and goal docs |
| SWC-FLOW-ACCOUNT-DELETION | Account deletion and data lifecycle | `FE-AUTH-PROFILE -> FE-API-CLIENT -> BE-API-CONTROLLERS -> BE-IDENTITY -> BE-OPS-AUDIT-DELETION -> owning backend SWCs -> DB-* cleanup/anonymization -> response -> FE-AUTH-PROFILE/local cache clear` | `data_flow.md` Account Deletion And Data Retention Flow |
| SWC-FLOW-OBSERVABILITY | Request, audit, metrics and release evidence | `FE-API-CLIENT/request_id -> BE-API-CONTROLLERS -> owning backend SWC -> BE-OPS-AUDIT-DELETION/BE-AI-OPS -> OPS-RELEASE-GATES` | `data_flow.md` Observability Flow |

## Increment Delta Rules
`docs/product/increments/<increment-id>/swc_allocation.md` 不是完整架构，而是相对于本文 baseline 的 delta。

Increment allocation 必须：
- 使用既有稳定 flow 时引用一个或多个 `SWC-FLOW-*` ID；
- 只有当行为尚未提升到 global baseline 时，才定义 increment-local flow；
- 标记每个 increment-local flow 是 `one-off`、`proposed-global` 还是 `legacy-compatible`；
- 如果 proposed-local flow 变成稳定可复用 flow，必须在实现前更新本文；
- 列出所有偏离 global topology 的地方，包括为什么不能复用既有 SWC。

## Local Architecture Change Baseline
设计局部变更时，System Architect 必须按顺序读取以下参考：
1. `docs/product/base/`、active stage 和 owning increment docs，用于确认 approved scope。
2. 本文，用于确认 global SWC topology 和 canonical Flow ID。
3. `docs/architecture/swc_catalog.md`，用于确认具体 SWC ID、code path、responsibility、owned data、test 和 forbidden bypass。
4. `docs/architecture/module_boundary.md` 与 `docs/architecture/data_flow.md`，用于确认 cross-boundary facts 和 business flow rules。
5. Domain Schema、OpenAPI、AI runtime、UX、test case library、release gates 以及当前代码/migration，用于确认 source-of-truth 细节。

如果局部设计与本文 baseline 冲突，实现不得开始，直到满足以下任一条件：
- global baseline 已更新并通过 Software Architecture Governance Check；
- ADR 记录 accepted architecture change，且受影响 baseline 文档已更新；
- increment 记录 accepted temporary `legacy-compatible` exception，并包含 migration owner 和 expiry condition。

## Required Review Questions
Software Architecture Governance Check 必须回答：
- 每个 implementation-impacting increment 是否引用本文 baseline，或是否有明确 no-SWC-impact decision？
- 引用的 SWC ID 是否存在于 `swc_catalog.md`？
- 引用的 Flow ID 是否存在于本文，或 local flow 是否带有 migration decision 分类？
- local flow 是否保持 frontend/backend/database/provider ownership 和 server-owned facts？
- local flow 是否包含 success path、failure path、auth、idempotency/retry、rollback/compensation、audit/logging/metrics、privacy 和 response-to-UI mapping？
- local design 是否复用既有 SWC 并避免 forbidden bypass？

## Historical Migration Note
历史 increment 可能早于本文 baseline。不能因为本文存在，就把历史 increment 追认为完整。下一次触碰相关 slice、Product Base merge review 或 release-readiness review 时，任何被修改或声明完成的 implementation-impacting behavior 都必须补充 `swc_allocation.md` 和 baseline references。
