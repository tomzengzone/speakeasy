# Software Component Architecture Governance

## 状态与范围

Accepted current process governance。本文件定义 SWC 架构方法和审查内容，不改变产品范围，也不替代 Domain、OpenAPI、AI runtime、UX、测试或发布 Artifact。Canonical path、owner、lifecycle、inputs 与 Gate routing 只从 Governance Contract 的 Artifact/Gate ID 解析。

## Applicability

只有变更实际影响稳定共享 SWC topology、system-level flow、reusable component boundary、跨层事实 ownership 或重大架构风险时进入 `G-SWC`。普通单组件实现、行为不变重构、copy/style polish 不创建额外 allocation 文档。

当前 SWC 架构工作使用 `SOFTWARE_COMPONENT_ARCHITECTURE`、`SWC_CATALOG`、`DATA_FLOW`、`MODULE_BOUNDARY` 和适用专业 Engineering Contract。Stage、Increment、Work Package 只可记录 planning/delivery selection，不作为 SWC 架构事实上游。旧 Increment SWC Allocation、Spec/AC 与其 gate/script 只属于 historical provenance，不是当前 prerequisite、fallback 或 CI required check。

## Current workflow

```text
selected approved VS + mandatory FR
-> affected Engineering Contract facts
-> inspect existing SWC/Flow and adjacent code/tests
-> decide no stable architecture impact, or update current SWC architecture/catalog
-> Contract-TC and targeted architecture validation
-> G-INDEPENDENT-CHECK when applicable
-> implementation
```

若只是局部实现，交付记录说明复用的 SWC/Flow、相邻代码和验证即可。若稳定 topology/flow/ownership 改变，必须在编码前更新 owning current architecture Artifact，并取得结构化 System Architect evidence；不得通过批次 allocation 文档复制全局事实。

## SWC Catalog content method

每个稳定 SWC 条目应包含：

- stable SWC ID 与 layer；
- code boundary；
- responsibilities 与 explicit non-responsibilities；
- provided/required interfaces；
- data、persistence 与 provider ownership；
- called API/Contract IDs；
- test ownership；
- required reuse、forbidden bypass 与 current status。

Catalog 只描述组件和复用边界；Domain entity、OpenAPI request/response、prompt schema、UX layout 和测试 oracle 继续由各 owning Artifact 持有。

## Global architecture content method

稳定 SWC 架构应描述：

- system-level frontend/backend/database/provider/AI runtime/ops responsibility allocation；
- current topology 与 stable `SWC-FLOW-*` library；
- 每个 Flow 的 SWC sequence、success/failure path 和 canonical engineering sources；
- auth/authorization、idempotency/retry、rollback/compensation、audit/logging/metrics 与 privacy boundary；
- existing implementation、复用规则、禁止重复组件和迁移/废弃责任；
- 局部 flow 升级为 stable global flow 的条件。

Brownfield change 先定位既有 user flow、code path、SWC/Flow、API、data ownership 和 tests，再写最小 delta。若新增 runtime、store、API、provider adapter、cache 或 migration，必须说明现有组件不能复用的原因、兼容影响、迁移 owner 和 regression proof。

## Responsibility boundaries

- Product Manager 决定产品范围、Story/VS 与 FR；不决定 SWC 细节。
- System Architect 判断 topology、flow、reuse 与 cross-layer ownership；不改变产品事实或专业 Contract schema。
- Domain/API/AI/UX owner 维护各自工程事实；SWC 文档只引用，不复制。
- Frontend/Backend/AI Runtime/DevOps 在批准边界内实现，不能把 client cache、provider candidate 或 ops signal 提升为 domain truth。
- Test Case Development 设计 typed TC；不决定架构 ownership。
- Software Architecture Governance Check 独立只读检查；不生成被审查架构。

## Review criteria

命中 `G-SWC` 或 `G-INDEPENDENT-CHECK` 时，以下情况阻塞：

- stable topology/flow/ownership 改变但 owning current architecture 未更新；
- 没有先识别 existing code/SWC/Flow/API/data/test baseline；
- 新组件复制已接受 SWC，且没有可验证的必要性与迁移责任；
- frontend 拥有 server-owned facts，或 backend 绕过 domain/media/AI gateway/usage/entitlement/audit/data-governance boundary；
- data flow 遗漏实际适用的 failure、auth、idempotency、retry、audit、privacy 或 rollback；
- SWC 文档复制或冲突 Domain、OpenAPI、AI runtime、UX、TC 或 release facts；
- changed Contract 缺少 Contract-TC，或测试未覆盖架构 delta；
- 批次 planning metadata 被当作产品或架构 source。

## Verification

先运行 affected Contract/architecture 的最窄测试和静态检查，再运行 selected VS 定向全链路测试。由 Governance Contract 解析 Artifact validation commands 和适用独立 checker；本文件不维护命令、path 或 owner 副本。
