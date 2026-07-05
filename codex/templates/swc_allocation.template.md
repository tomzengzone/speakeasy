# <increment-id> SWC Allocation

## Status
Draft | Proposed | Accepted | Superseded

## Scope
- Increment ID:
- Active stage:
- Covered Stage Scope IDs:
- Primary feature:
- Affected features:
- Explicit non-goals:
- Change mode: `brownfield-update` / `behavior-preserving-refactor` / `greenfield-with-no-existing-implementation`

## Existing Implementation Baseline
本章节对所有 implementation-impacting increment 都是必填项。局部设计只有先证明继承了哪些已接受实现、SWC、flow、代码路径、API、测试和不可回归行为，才可以进入 implementation-ready 状态。

| Baseline item | Existing evidence required before new design |
| --- | --- |
| Existing user flow | Current accepted or implemented user path this increment extends, or `N/A - greenfield, no accepted implementation` |
| Existing code paths | Concrete existing files/directories, for example `lib/features/interview/`, `lib/application/scene/`, backend package paths, migrations, or `N/A - greenfield, no accepted implementation` |
| Existing SWCs | Existing `FE-*`, `BE-*`, `DB-*`, `AI-*`, `OPS-*` IDs from `docs/architecture/swc_catalog.md` that must be inherited |
| Existing global Flow IDs | Existing `SWC-FLOW-*` IDs from `docs/architecture/software_component_architecture.md`, or local legacy flow classification with migration owner |
| Existing API/OpenAPI calls | Existing OpenAPI operations or explicitly legacy non-OpenAPI paths currently used |
| Existing domain/data ownership | Existing Domain entities, server-owned facts, client-cache-only facts, DB table/migration owners |
| Existing tests/evidence | Existing TC IDs, test paths, reports, or explicit gap with owner and evidence plan |
| Behavior that must not regress | User-visible, data, API, persistence, provider, cache, telemetry, or release behavior that must be preserved |
| Known legacy/deprecated parts | Legacy paths still tolerated, deprecated aliases, compatibility constraints, migration owner and expiry |

## Delta From Existing Baseline
本章节必填。increment 只能描述相对上方 baseline 的 delta，不得静默替换既有 flow 或创建平行实现。

| Delta item | Decision |
| --- | --- |
| Reused SWCs | Existing SWCs that the new design must reuse |
| Reused Flow IDs | Existing `SWC-FLOW-*` IDs or local flow classification |
| Changed behavior | Exact behavior changed by this increment |
| Unchanged behavior | Existing behavior explicitly preserved |
| New code allowed | New files/packages/classes/services/endpoints/migrations allowed by this increment |
| New code forbidden | Duplicate runtime, service, API, provider, store, cache, migration, or UI path that must not be created |
| Existing code modified | Existing files/directories allowed to change |
| Migration/deprecation impact | Required migration, compatibility exception, owner, and expiry; use `N/A - no migration` when none |
| Regression proof required | TC IDs, test paths, static gates, or manual evidence needed to prove old flow still works |

## Baseline References
| Reference type | Required value |
| --- | --- |
| Global SWC architecture baseline | `docs/architecture/software_component_architecture.md` |
| Referenced global Flow IDs | `SWC-FLOW-...` or `N/A - no existing global flow` |
| Referenced SWC Catalog IDs | `FE-...`, `BE-...`, `DB-...`, `AI-...`, `OPS-...` |
| Inherited data flow rules | `docs/architecture/data_flow.md#...` |
| Inherited module boundary rules | `docs/architecture/module_boundary.md#...` |
| Local flow classification | `N/A - uses existing global flow only` / `one-off` / `proposed-global` / `legacy-compatible` |
| Local flow migration owner and expiry | Required when classification is `proposed-global` or `legacy-compatible` |

## System Responsibility Allocation
| Layer | Responsibilities in this increment | Non-responsibilities | Facts owned here |
| --- | --- | --- | --- |
| Frontend |  |  | Client-cache-only facts only |
| Backend |  |  | Server-owned facts |
| Database |  |  | Tables/migrations owned by backend |
| Provider / AI runtime |  |  | Candidate outputs only; accepted persistent facts are owned by backend/domain SWCs after deterministic rules accept them |
| Ops / release |  |  | Gates, audit, rollback, observability evidence |

## Requirement Allocation Matrix
| Stage Scope ID | FR | Spec | AC | FE SWC | BE SWC | API/OpenAPI | Domain Entity | DB Table/Migration | Provider/AI Boundary | TC | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |  |  |  |  |  |

## SWC Data Flows

### <flow-id-or-local-flow-id>
- 全局 Flow ID 或本地分类：
- 触发条件：
- 成功路径：
  ```text
  UI
    -> Adapter
    -> FE-API-CLIENT
    -> BE-API-CONTROLLERS
    -> BE-...
    -> DB-... / AI-... / provider
    -> response
    -> UI
  ```
- 失败路径：
- Auth / authorization：
- Idempotency / retry：
- Rollback or compensation：
- Audit / logging / metrics：
- Permission / privacy：
- Response-to-UI mapping（响应映射）：

## Reuse And Forbidden Boundaries
| Boundary type | Decision |
| --- | --- |
| Existing SWCs that must be reused |  |
| New SWCs allowed |  |
| Duplicate components forbidden |  |
| Forbidden direct calls or bypasses |  |
| Legacy exceptions and migration plan |  |

## Verification
| Check | Expected evidence |
| --- | --- |
| Expected tests | Stable TC IDs and test paths |
| Static gates |  |
| OpenAPI/generated drift checks |  |
| Traceability checker |  |
| Software Architecture Governance Check finding | pass/block report reference |

## Notes
- 本文是相对于 `docs/architecture/software_component_architecture.md` 的 delta，不是完整 SWC architecture。
- 不得在本文中重新定义 product scope、requirements、acceptance criteria、domain entity semantics、OpenAPI schemas、AI prompt schemas、UX layout、test implementation 或 release approval。
