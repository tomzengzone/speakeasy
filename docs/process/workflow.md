# Codex 开发流程

## 治理路由

`GOVERNANCE_INDEX` 是治理契约入口。Artifact path、accountable owner、contributor scope、lifecycle、direct/conditional inputs 和 validation command 由 Artifact ID 解析；Gate applicability、owner/checker、结果和证据要求由 Gate ID 解析。本文只定义阶段顺序与决策点，不重新声明这些治理事实。

变更通过普通 GitHub PR 流程交付：受保护分支要求 CI 编译、静态分析和测试通过后方可合并，CI 结果由 GitHub 绑定到被检查的 commit SHA。

## 默认执行路径

```text
用户任务
-> 根 Codex 判断影响范围
-> 只加载命中的 Artifact/Gate contract
-> 单 owner 局部执行，或在专业/独立审查边界交接
-> 最窄定向验证
-> 适用治理验证和普通 PR CI
-> 用户总结
```

普通 code-only 修复、行为不变重构、UI polish 和只读分析不创建产品治理文档，除非实际影响命中某个 Artifact 或 Gate。

## 产品与交付轴

产品事实源链按事实层协作：

```text
Capability Registry: Capability/Sub-capability boundary facts
Story Map: approved User Story -> approved Child Vertical Slice
FR Catalog when present: approved Child Vertical Slice -> Functional Requirement
```

这是分层的产品事实源链，不是由某一个 Artifact 独占的单一事实源。Capability Registry 持有稳定业务边界和分类事实；Story Map 持有 approved Story/Child Vertical Slice 的用户闭环语义及 Child Vertical Slice 到 Story 的直接父子关系，不保存 Story/Vertical Slice 到 Capability 的映射；FR Catalog 在 FR 存在时持有从 approved Vertical Slice 提炼出的规则、不变量、边界和失败语义，并只通过 `source_vs_ids` 直接引用 approved Vertical Slice。任何一层都不得被描述为整条产品事实源链的唯一来源。Stage、Roadmap、Increment、Work Package 和 PR 是 planning/delivery metadata，不定义产品行为，也不作为 FR、TC 或 Engineering Contract 的上游。

交付轴选择 approved VS，并在 FR 存在时选择适用的 approved FR；工程事实变化时同步受影响 Engineering Contract。Issue/PR 只记录本次选择、范围、风险、状态与证据链接，不复制产品、Contract 或测试事实。

## Feature delivery

只有创建或实质改变已接受产品行为时使用此流程；不适用步骤必须跳过：

```text
idea/change intake
-> G-PRODUCT-CLASSIFICATION
-> 用户价值场景与产品范围确认（Capability 边界事实变化时才进入 G-REGISTRY）
-> Story 与 Child VS 完整、approved
-> FR 存在时进入 G-FR，验证 approved 状态与直接 VS lineage
-> G-TC：VS-TC；FR 存在时增加 FR-TC，Contract 事实变化时增加 Contract-TC
-> G-CONTRACT：只同步事实发生变化的专业 Contract
-> G-SWC：稳定共享拓扑或重大复用边界变化时更新架构并独立检查
-> test-first implementation
-> FR/Contract 快速测试
-> selected VS 定向 integration/E2E
-> applicable governance validators and independent checks
-> 普通 PR CI
-> report/release controls when applicable
```

VS 未批准、产品行为不完整，或当前 FR 自身未批准、lineage 无效或内容冲突时回到 owning source，由 Product Manager 裁决；不得在 TC、Contract、Issue 或代码中补造行为。Selected approved VS 可以没有 FR，且不需要为零 FR 创建例外记录。

## 分层测试决策

`TEST_CASE_CATALOG` 固定三类唯一 direct-upstream edge：

- FR-TC 仅在 FR 存在时使用，只记录 `source_fr_id`，并选择能最快证明该 FR 行为的最低成本层级；同一原子 FR 可因验证层级或边界覆盖需要使用多个 FR-TC。若行为具有独立审批、生命周期、变更风险或测试 oracle，必须先由 Requirement Development 拆分为不同 FR，不得用增加 FR-TC 掩盖未拆分需求。
- Contract-TC 只记录 `source_contract_id`，覆盖实际变化的 API、Domain、Persistence、AI、UX 等边界。
- VS-TC 只记录 `source_vs_id`，覆盖用户可感知的定向全链路和关键失败/降级路径。

先运行适用的 FR/Contract 快速测试，再运行 selected VS 的定向全链路测试。最终 release E2E 不得成为首次发现模块缺陷的验证点。TC Catalog 不保存运行结果；执行证据绑定 exact commit SHA。

`TRACEABILITY` 从 Story Map、TC Catalog、存在时的 FR Catalog 和适用 Engineering Contract 派生当前存在的分支及 coverage join。没有 FR 时不生成 FR、FR-TC 或 VS-TC-to-FR join。它不拥有或覆盖任何 direct edge；不一致时修复 owning source 后重建投影。

## Engineering Contract 与风险

API、OpenAPI、Domain、Persistence、AI structured output、Prompt/fallback、Dialogue、UX 或架构事实变化时，必须同步对应 owning Artifact 并运行适用 Contract-TC。风险低不能豁免事实同步。

稳定 SWC topology、system-level flow 或 reusable component boundary 变化时进入 `G-SWC`，引用当前 Software Component Architecture、SWC Catalog、Data Flow、Module Boundary 和适用专业 Contract；普通局部实现不创建 increment allocation 文档。安全、隐私、支付、数据完整性、不可逆迁移、跨系统兼容、重大共享拓扑或生产发布风险按命中的 Gate 追加独立审查、迁移、canary、回滚或 release control。

触碰 reusable cross-cutting boundary 时，按 `CROSS_CUTTING_BOUNDARY_REGISTRY` Artifact ID 解析当前条目，并在实现与证据中引用 Boundary ID。新增稳定 cross-cutting capability 必须先登记。

## 最小编码上下文

普通实现默认只加载：selected approved VS、存在时的适用 approved FR 与 FR-TC、受影响 Contract 与 Contract-TC、VS-TC、相邻代码/测试和验证命令。历史 `user_stories`、Product Base、Increment Requirements/Spec/Acceptance/Test/Traceability、migration-only 文件、task plan 与未登记 template 不进入默认上下文或 authoritative fallback。

## Gates

- `G-PRODUCT-CLASSIFICATION`：识别 change type、用户价值场景、范围、非目标与是否发生产品事实变化；不生成 Story/Vertical Slice 到 Capability 的映射。
- `G-REGISTRY`：仅 Capability/Sub-capability 边界事实变化时执行。
- `G-INCREMENT-SCOPE`：仅 planning scope/batch 变化时执行；其结果不进入产品/Contract/TC lineage。
- `G-FR`：仅在 FR 存在时验证固定四列表格、approved 状态、非空直接 VS lineage 与非空、可测试的 Requirement；每行 FR 是可独立审批、变更和验证的规范性需求单元。
- `G-TC`：验证三类 TC 的唯一 direct edge、oracle、层级、selector、脚本与命令。
- `G-CONTRACT`：验证工程事实同步和 Contract-TC。
- `G-SWC`：仅共享拓扑、system flow 或重要复用边界变化时执行。
- `G-AI-SCHEMA`：LLM structured output/Prompt/fallback 变化时执行，并要求适用 AI Contract-TC。
- `G-TEST`：先快后全，最终结果由 CI 绑定到被检查的 commit SHA。
- `G-RELEASE`：只在 release scope 命中时执行。
- `G-ARTIFACT-VALIDATION`、`G-INDEPENDENT-CHECK`、`G-DOCUMENT-LANGUAGE`：按 contract applicability 执行。

Gate 的 owner、checker、required evidence、result 和 exception 只能从 Governance Contract 解析。

## Issue tracking

Issue tracking 是可选协作手段，在产品分类后用于协调缺陷、实现切片、阻塞、PR 或证据链接。Issue 不替代 Story Map、FR Catalog、Engineering Contract、TC Catalog、Traceability 或正式报告。只有 Definition of Done 已满足时才能使用 closing 语义。

## 文档语言

新增或修改的持久化项目文档默认使用中文。技术标识、代码路径、API/OpenAPI 字段、SWC/TC ID、命令和机器字段可以保留英文。适用时运行：

```bash
python3 scripts/check_document_language.py --scope changed --include-worktree
```

## Agent handoff

- Product Manager 决定产品分类、Story/VS 与 FR 的产品事实和批准状态。
- Requirement Development 仅在 Product Manager 决定使用 FR 时，按已批准 VS 贡献 FR，不改变产品方向，也不要求每个 implementing VS 都有 FR。
- Test Case Development 设计 FR/Contract/VS 分层 TC，不发明产品行为。
- `traceability` Agent 在相关 Story/FR/Engineering Contract/TC 输入稳定后重建派生投影；direct edge 缺口必须返回 accountable source owner 修复后再生成。
- System Architect 与专业 owner 只在对应工程事实或风险边界变化时介入。
- 根 Codex 负责最短安全执行路径、验证和交接；独立 checker 保持只读。
