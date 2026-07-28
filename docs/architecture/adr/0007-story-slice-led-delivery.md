# ADR 0007：Story / Slice 驱动的前瞻式交付治理

- Status: Accepted for candidate baseline
- Date: 2026-07-21
- Decision owner: Product Manager / System Architect / Governance Owner

## Context

旧流程把相同产品事实依次翻译为 Feature Spec、Acceptance Criteria、Increment Test Case 和多份 traceability，增加了跳转、重复和漂移风险。PR-003 需要在不改变既有产品、工程和实现事实的前提下，把当前 authority 收敛到可唯一解析的产品、工程和测试边界。

## Current decision

### 产品事实链

当前产品事实链为：

```text
Capability / Sub-capability classification
-> approved User Story
-> approved Child Vertical Slice
-> Functional Requirement when present
```

`STORY_MAP` Artifact 是 User Story 与嵌套 Child Vertical Slice 的唯一当前产品事实来源，可由 Governance Contract 注册的 Capability 分片共同承载；导航索引不拥有行为语义。Story 直接归属 Capability，Child VS 直接归属 Story。Product Manager 按 implementing VS 决定是否创建 FR，零 FR 不会仅因缺少 FR 而阻止交付。FR 存在时只通过 `source_vs_ids` 直接引用 approved VS，并可包含多个独立规则、不变量、边界或失败条件。Capability 与 Sub-capability 只用于分类、编号和影响筛选，不从名称或描述推导行为，也不成为第二条 lineage。

Stage、Roadmap、Increment、Work Package 与 PR 只组织时间、优先级、批次和交付状态，不定义产品行为，也不作为 FR、TC 或 Engineering Contract 的权威上游。

### 分层测试和唯一直接边

Test Case Catalog 保存稳定 oracle、Given/When/Then、边界/负例、测试层级、scope、selector、脚本路径和执行命令，不保存易过期的执行状态。三类 TC 的直接上游固定且互斥：

| TC 类型 | 唯一直接上游字段 | 目的 |
| --- | --- | --- |
| FR-TC | `source_fr_id` | FR 存在时，在 unit/domain/service/contract/integration/widget 中选择最低成本层级证明其行为；独立行为需要不同 oracle 或层级时可使用多个 FR-TC |
| Contract-TC | `source_contract_id` | 证明受影响 Architecture/SWC、API、Domain、Persistence、AI、UX 等工程事实 |
| VS-TC | `source_vs_id` | 在受影响的真实层上验证用户可感知 integration/E2E 闭环和关键降级路径 |

FR 存在时，每条 approved FR 必须有适用的最低成本 FR-TC，或具有 owner、原因、影响和失效期限明确的例外；零 FR 不需要例外记录。工程 Contract 事实变化必须同步 owning Contract 并新增或更新 Contract-TC。每个实施中的 VS 必须有用户可感知的 VS-TC。先运行适用的 FR/Contract 快速测试，再运行 selected VS 的定向全链路测试；最终 release E2E 不是首次发现模块缺陷的验证点。

### Derived canonical traceability

Canonical traceability 是只读、完整、可重建的投影，不拥有直接边：

```text
Story Map: Capability/Sub-capability -> Story -> VS
FR Catalog when FR exists: VS -> FR
Engineering Contract when FR exists: FR -> affected Contract
TC Catalog when FR exists: FR -> FR-TC
TC Catalog: Contract -> Contract-TC
TC Catalog: VS -> VS-TC
```

Traceability 连接 selector 和稳定 evidence link，并在 FR 存在时从 VS/FR owning edge 派生 VS-TC 对适用 FR 的 coverage join。没有 FR 时不生成 FR、FR-TC 或对应 coverage join；VS-TC 不重复保存 FR ID 集合。投影不一致时修复 owning source 后重新生成，不得在 traceability 中覆盖关系。执行结果只由绑定 exact commit SHA 的 CI 或测试系统保存。

### Engineering Contract 与治理责任

Engineering Contract 是现有 Architecture、API、Domain、Persistence、AI、UX 等专业 Artifact 的分类，不建立统一聚合 Contract，也不改变其 accountable owner。只有工程事实实际变化时才同步对应 Contract；风险高低不能豁免事实同步。安全、隐私、支付、数据完整性、不可逆迁移、跨系统兼容、重大共享拓扑或生产发布风险按实际命中追加独立审查、迁移、flag/canary、回滚和 release control。

Governance Contract 独占 canonical path、accountable owner、contributor scope、lifecycle、Artifact direct/conditional inputs 和 Gate routing。Agent 只定义角色、权限、专业边界和 handoff；Skill 只定义适用任务、方法步骤、内容规则和验证方法；Workflow 只定义顺序、决策点和按 Artifact/Gate ID 解析 contract 的规则；Template 只定义内容字段与版式。非 owning layer 只能保留经 contract 校验、明确标记为 derived 的必要执行路径或命令指针。

普通编码的最小上下文是 selected approved VS、存在时的适用 approved FR 与 FR-TC、实际受影响 Contract 与 Contract-TC、VS-TC、相邻代码/测试和验证命令。

### Forward-only cutover

本次切换是 forward-only、no-migration：旧 `docs/product/user_stories.md`、Product Base 与 Increment Requirements/Spec/Acceptance/Test/Traceability 文档原地保持不变，只作为 historical-reference-only / non-canonical evidence。它们不进入 active route、默认编码上下文、fallback 或新增 authoritative input。本决策不迁移或重写旧事实，不生成逐条 disposition，也不声称旧文档已无损覆盖。

Feature Spec 与 Acceptance Criteria 的 active Artifact、Actor、Skill 和 Gate 被移除；新交付不能恢复这些层替代 approved VS、存在时的 FR 或分层 TC。Stage/Increment planning artifacts 可继续存在，但不得承载产品、Contract 或测试事实。

PR-002 的 shadow、262 条 migration disposition 和 typed-destination 方案已被本前向切换决定明确 supersede。PR-001 的 migration-only 文件可作为历史证据原地保留，但不进入 active route、CI 入口或默认上下文。

本项目不建立 project-local Hook、runtime governance resolver、ephemeral context bundle、首次写入 deny/retry 或 actor/session/turn 匹配。治理执行依赖 native permission、静态 validator、普通 PR CI 和适用的独立 checker。

### Candidate 与 baseline 激活

当前 authority graph 从默认分支的 index route、registered native Agent/config、active method Skill 及其直接链接 resource 派生；task plan、未登记 template、migration-only 文件和历史产品文档不进入图。变更通过受保护分支的普通 PR CI 和代码审查后合并生效。

## Consequences

- 产品事实、工程事实、持久测试 oracle 和一次性交付状态各有唯一 owner。
- 普通改动减少重复 artifact 和默认上下文，同时保留 FR 存在时的 requirement-level 快速测试、全链路测试与风险治理。
- 旧产品文档继续可用于历史审计，但不能被新变更当成当前 authority。
- 任一现有 FR 的 approved 状态、直接 VS lineage、FR-TC 或 derived projection 缺口，以及适用 typed TC、Contract 同步或 CI 证据缺口都会阻止合并；零 FR 本身不会阻止合并。

## Superseded decisions

以下内容只说明历史方案已失效，不构成当前义务：强制 Spec/AC Gate、shadow rollout、262 条 legacy 迁移、runtime Hook/preflight/resolver/bundle、候选内容自声明 active。ADR 0001 保留为历史记录；本 ADR 取代其交付流程规则。

## Alternatives rejected

- 保留强制 Spec/AC：继续产生重复翻译和漂移。
- 长期双轨：使人员、AI 和 CI 无法唯一确定 authority。
- 删除旧产品文档：超出前向切换范围并损害历史审计。
- 用低风险豁免 Contract 同步：会造成工程事实与实现不一致。
