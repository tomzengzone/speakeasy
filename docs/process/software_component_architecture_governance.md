# Software Component Architecture Governance

## 状态
Accepted process governance - 独立 Software Architecture Governance Check follow-up 已关闭技术设计 blocker；durable quality report 记录 initial block、correction 和剩余 historical-increment migration risk。本文件定义代码架构设计如何在本项目落地，不改变产品范围、不替代需求、领域模型、OpenAPI、UX、AI runtime、测试或发布文档。

## 目标
把成熟代码架构设计变成实现前强制门禁，确保每个跨层或可复用模块变更在编码前完成：
- 系统级职责分配；
- Domain Schema 引用；
- OpenAPI / Interface Contract 引用；
- SWC Catalog；
- Existing Implementation Baseline；
- Delta From Existing Baseline；
- Requirement Allocation Matrix；
- SWC 间数据流；
- 复用与禁止边界。

## Canonical Artifacts
| Artifact | Path | Owner | Purpose |
| --- | --- | --- | --- |
| Global SWC Catalog | `docs/architecture/swc_catalog.md` | System Architect Agent | 稳定 SWC 库：前端、后端、数据库、AI runtime、provider、ops 组件清单和职责边界 |
| Global SWC Architecture Baseline | `docs/architecture/software_component_architecture.md` | System Architect Agent | 完整汇总的软件组件架构：SWC 拓扑、全局 SWC-to-SWC Flow ID、稳定复用流和局部变更参考基准 |
| Increment SWC Allocation | `docs/product/increments/<increment-id>/swc_allocation.md` | System Architect Agent | 将已批准 increment 的 FR/AC 分配到具体 SWC、API、领域实体、DB/migration 和测试 |
| Increment SWC Allocation Template | `codex/templates/swc_allocation.template.md` | System Architect Agent | 生成增量 SWC allocation 的稳定模板，防止字段漂移 |
| SWC Allocation Gate Script | `scripts/check_swc_allocation.py` | DevOps + Software Architecture Governance Check Agent | CI 检查模板、增量 allocation、旧实现继承、变更代码路径覆盖和场景对话复用边界 |
| SWC Governance Review | `docs/reports/quality_report.md` | Software Architecture Governance Check Agent | 独立审查 SWC 架构设计是否可执行、无冲突、无重复造轮子风险 |

Template change 属于 workflow/source-of-truth governance change，除普通 validation 外，还必须通过 Product Object Governance Check。

## Workflow Placement
SWC 架构门禁位于：

```text
increment spec
-> acceptance criteria
-> test case library / AC-to-TC mapping
-> architecture/domain/API/screen/AI specs
-> existing implementation baseline / delta from baseline
-> software component architecture / SWC allocation
-> implementation plan
-> code
```

如果变更只影响纯文案、单文件样式或不触达跨层/可复用组件，可在 increment traceability 中记录 `N/A - no SWC impact`，但必须说明原因。

## Global SWC Catalog Content Contract
`docs/architecture/swc_catalog.md` 必须包含：
- SWC ID；
- layer：frontend、backend、database、provider、AI runtime、ops、shared；
- owning agent：Frontend、Backend、Domain Schema、AI Runtime、DevOps、System Architect 等；
- code path；
- responsibilities；
- explicit non-responsibilities；
- provided interfaces；
- required interfaces；
- owned data / DB tables / migrations；
- called APIs or provider boundaries；
- test ownership；
- required reuse and forbidden bypasses（必需复用与禁止绕过）；
- current status（当前状态）：accepted、proposed、deprecated、legacy-compatible。

SWC Catalog 不能复制完整 Domain Schema、OpenAPI schema、prompt schema 或 UX layout；它只能引用这些 source of truth。

## Global SWC Architecture Baseline Content Contract
`docs/architecture/software_component_architecture.md` 必须包含：
- 文档与 `swc_catalog.md`、`data_flow.md`、`module_boundary.md`、Domain Schema、OpenAPI、increment allocation 的 source-of-truth 边界；
- 系统级 frontend/backend/database/provider/AI runtime/ops 职责分配；
- 全局 SWC 拓扑；
- 稳定 SWC-to-SWC Flow ID library；
- 每个 Flow ID 的 SWC sequence 和 canonical source；
- 局部架构变更的 baseline reference rule；
- 增量局部 flow 升级为全局稳定 flow 的规则；
- 历史 increment 迁移说明。

Global SWC Architecture Baseline 不能替代 `swc_catalog.md` 的组件字段清单，也不能替代增量 `swc_allocation.md` 的 FR/AC 落地矩阵。它回答“完整软件组件架构和局部变更参考基准是什么”。

## Increment SWC Allocation Content Contract
`docs/product/increments/<increment-id>/swc_allocation.md` 必须包含：

除非正在更新已有 accepted allocation，否则必须以 `codex/templates/swc_allocation.template.md` 作为起始结构。

1. Scope
   - increment id；
   - active stage；
   - covered Stage Scope IDs；
   - primary feature / affected features；
   - explicit non-goals；
   - change mode：`brownfield-update`、`behavior-preserving-refactor` 或 `greenfield-with-no-existing-implementation`。

2. Existing Implementation Baseline
   - existing user flow；
   - existing code paths；
   - existing SWCs；
   - existing global Flow IDs；
   - existing API/OpenAPI calls；
   - existing domain/data ownership；
   - existing tests/evidence；
   - behavior that must not regress（不可回归行为）；
   - known legacy/deprecated parts（已知 legacy/deprecated 部分）及 migration owner 和 expiry。

   Brownfield 或 refactor increment 不得用空泛的“复用旧流程”替代具体代码路径、SWC ID、Flow ID、API 和测试证据。只有真正没有已接受实现的 greenfield increment 才能写 `N/A - greenfield, no accepted implementation`，并且必须说明为什么不是对现有能力的扩展。

3. Delta From Existing Baseline
   - reused SWCs；
   - reused Flow IDs；
   - changed behavior；
   - unchanged behavior；
   - new code allowed；
   - new code forbidden；
   - existing code modified；
   - migration/deprecation impact；
   - regression proof required。

   Increment design 只能写相对既有 baseline 的 delta。若需要新增 SWC、runtime、API、store、provider adapter、cache 或 DB migration，必须说明现有组件为什么不能复用以及旧组件是否迁移、保留或废弃。

4. Baseline References
   - `docs/architecture/software_component_architecture.md`；
   - referenced global `SWC-FLOW-*` IDs；
   - referenced `docs/architecture/swc_catalog.md` SWC IDs；
   - inherited `data_flow.md` / `module_boundary.md` rules；
   - local flow classification：`one-off`、`proposed-global`、`legacy-compatible` 或 `N/A - uses existing global flow only`。

5. System Responsibility Allocation
   - frontend responsibilities；
   - backend responsibilities；
   - database responsibilities；
   - provider responsibilities；
   - AI runtime responsibilities；
   - ops/release responsibilities；
   - server-owned facts；
   - client-cache-only facts。

6. Requirement Allocation Matrix
   必需列：
   `Traceability Row ID`, `Increment ID`, `WP ID`, `FR`, `Spec`, `AC`, `FE SWC`, `BE SWC`, `API/OpenAPI`, `Domain Entity`, `DB Table/Migration`, `Provider/AI Boundary`, `TC`, `Notes`.

   SWC allocation 只接收 Spec/AC/WP 和既有实现基线作为本层输入；完整 Story/Slice 回连通过 `Traceability Row ID` 交给 owning `traceability.md`，不得在 allocation row 重复整条产品链。

7. SWC Data Flow
   每个核心 flow 必须列出：
   - global Flow ID 或 local flow id；
   - success path；
   - failure path；
   - auth/authorization；
   - idempotency/retry；
   - rollback or compensation；
   - audit/logging/metrics；
   - permission/privacy；
   - response-to-UI mapping。

8. Reuse And Forbidden Boundaries
   - 必须复用的 existing SWC；
   - 允许新增的 new SWC；
   - 禁止重复创建的 duplicate component；
   - forbidden direct call 或 bypass；
   - legacy exception 和 migration plan。

9. Verification
   - expected tests；
   - expected static gates；
   - OpenAPI/generated drift checks；
   - traceability checker；
   - `python3 scripts/check_swc_allocation.py --scope changed --base-ref <base-ref>`；
   - independent Software Architecture Governance Check finding（独立架构治理检查结论）。

## Agent Responsibilities
| Agent | Owns | Must not own |
| --- | --- | --- |
| Product Manager | stage priority, product scope, accepted/deferred decisions | SWC details, code ownership, API schema |
| Requirement Development | FR, user path, acceptance input quality | SWC assignment or implementation design |
| System Architect | global SWC architecture baseline, SWC catalog, increment SWC allocation, module/data-flow/API-boundary architecture | Product priority, detailed domain entity semantics, OpenAPI YAML schema, implementation code |
| Domain Schema | domain entities, lifecycle, invariants, ownership | API request/response schema, SWC implementation routing |
| API Contract | API family, request/response/error/idempotency/version contract | DB implementation, product priority, UI layout |
| Frontend | Flutter SWC implementation under approved allocation | server-owned facts, provider secrets, final entitlement/mastery facts |
| Backend | backend SWC implementation under approved allocation | UI layout, product scope, client-only facts as source of truth |
| QA/Test Case Development | TC design and execution evidence | architecture ownership decisions |
| Software Architecture Governance Check | independent pass/block review of SWC gate | creating SWC allocation or changing product scope |
| Product Object Governance Check | meta-governance for workflow/agent/skill/source-of-truth changes | technical SWC correctness review when Software Architecture Governance Check is the owning checker |

## Stable Output Rule
每个 implementation-impacting increment 必须产出以下之一：
- 通过 checker 的 `docs/product/increments/<increment-id>/swc_allocation.md`；或
- increment traceability 中带 reviewer acceptance 的明确 `N/A - no SWC impact` decision。

除非 accepted decision 是 `N/A - no SWC impact`，否则 `swc_allocation.md` 必须引用 `docs/architecture/software_component_architecture.md`、referenced `SWC-FLOW-*` ID 和 referenced SWC Catalog ID。

Implementation-impacting PR 必须通过 `scripts/check_swc_allocation.py`。当 `lib/`、`backend/src/main/java/`、`backend/src/main/resources/db/migration/` 或 OpenAPI 下的 implementation path 变化时，changed SWC allocation 必须提到变化的 existing/new code path，或 owning increment traceability 必须携带 accepted `N/A - no SWC impact` decision。Scenario-practice code change 必须引用 `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME` 和 existing `FE-SCENARIO-PRACTICE` / `FE-PRACTICE-RUNTIME` boundary。

Implementation report 必须引用 changed code 对应的 SWC allocation row，或引用 accepted no-impact decision。当变更触碰 frontend/backend boundary、persistence、provider/AI runtime、cross-cutting reusable module 或 owned facts 时，code review 应把 missing baseline reference、missing SWC allocation 或 uncategorized local flow 视为 blocker。

## Review Criteria
独立 checker 在以下情况下必须 block：
- 需要完整 SWC architecture baseline，但 `docs/architecture/software_component_architecture.md` 缺失，或 increment allocation 未引用它；
- Existing Implementation Baseline 缺失、没有列出具体 existing code path/SWC/Flow ID/API/test，或在存在 existing accepted implementation 时声称 greenfield；
- Delta From Existing Baseline 缺失、没有列出 reused SWC/Flow ID、没有定义 new-code-allowed/new-code-forbidden boundary，或静默替换 existing behavior；
- local SWC data flow 既没有映射到 existing `SWC-FLOW-*` ID，也没有分类为 `one-off`、`proposed-global` 或 `legacy-compatible`；
- 任一 implementation-impacting FR/AC 没有 SWC allocation，也没有明确 N/A reason；
- FE/BE/DB/provider ownership 模糊；
- client SWC 拥有 server-owned facts；
- backend SWC 绕过 existing domain、media、AI gateway、usage、entitlement、audit 或 data-governance boundary；
- new SWC 在没有 migration reason 的情况下复制 accepted SWC；
- changed implementation path 没有被 owning SWC allocation 的 existing code baseline 或 allowed code delta 覆盖；
- 适用时 data flow 遗漏 failure path、idempotency、auth、audit/logging 或 rollback/compensation；
- SWC allocation 复制或冲突 Domain Schema、OpenAPI、AI runtime、UX、test cases、release gates 或 Product Base scope；
- 变更后相关 agent 或 skill ownership 冲突。

## Migration Plan
1. 为 global SWC architecture baseline 和 SWC allocation 增加 workflow/DoD gate。
2. 增加 System Architect 对 global SWC architecture baseline、SWC catalog 和 increment allocation 的 ownership。
3. 增加 Software Architecture Governance Check Agent 作为 independent reviewer。
4. 更新 document path/content/traceability governance，使其识别 SWC artifact。
5. 对新的 increment，implementation 前要求 baseline reference 和 `swc_allocation.md`。
6. 将 `scripts/check_swc_allocation.py` 加入 CI，使缺失 existing-implementation inheritance 的 PR 被阻塞。
7. 对已有实现的 active increment，在下一次 touched slice 或 Product Base merge review 中补充 baseline references、Existing Implementation Baseline、Delta From Existing Baseline 和 SWC allocation，而不是原地重写历史。
