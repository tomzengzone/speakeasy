---
name: capability-registry-develop
description: Use when：Product Manager 需要创建、变更、拆分、合并、弃用、映射 Capability/Sub-capability 记录，或对其执行就绪门审查。不适用于定义 Story/Slice 行为、交付阶段范围、需求、规格、验收标准、测试、架构或实现。
---

# Capability Registry Develop

## Overview

提出由 PM 持有的 V2 Capability/Sub-capability 事实建议并执行质量门检查。本 Skill 提供方法和发现项；Product Manager 持有产品事实和审批权。

## When to Use

用于候选归属、Capability/Sub-capability 新增或边界变更、拆分/合并/弃用建议、V1-to-V2 映射、格式检查，以及 `CAPABILITY_REGISTRY` 就绪门审查。

## When NOT to Use

不得用于 Story/Slice 行为、交付规划、FR/Spec/AC/TC、技术 contract、实现、测试，或者 registry path/source-of-truth 变更。这些事项必须路由给持有相应事实的 workflow。

## Contract

- 这是 `CAPABILITY_REGISTRY` 的 method Skill；path 和事实归属必须通过 governance index 解析。
- 在 PM 批准之前，草案和发现项都是临时结果。持久化语义编辑必须运行 `python scripts/validate_capability_registry.py`；只有适用 `G-INDEPENDENT-CHECK` 时才运行 Product Object Governance Check。
- `docs/process/governance/index.json` 是 path、lifecycle、write scope 和 checker 的权威来源。本 Skill 不得创建或改写下游 Artifact。

## Inputs

PM 授权的结果、职责、可观察行为、边界、非目标、理由、目标/父级 ID、变更模式、相关 registry 记录和受影响的下游引用。必须仅读取相关章节；只有身份、拆分、合并或弃用影响分析才可以执行全仓库清点。

Read when：对于新增、边界变更、拆分、合并、弃用或归属未确定的工作，起草前必须读取[结构变更门](references/structural-change-gates.md)。不得在纯编辑或纯格式检查中加载该 reference。

## Outputs

Gate A 归属发现项、Gate B 粒度发现项、当前格式草案、身份/边界影响、遗漏范围、适用时的迁移方向、就绪门结果，以及 PM/checker 交接。不得输出已批准的产品事实。

## 文档路径约定

持久化目标必须为 `docs/product/feature_registry.md`；按条件选择的 reference 和 asset 必须仅作为方法支持，不得作为产品事实来源。

## Registry format

```text
## CAP-<PREFIX> - <Capability name>
### Capability
Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary outcome | Adjacent capabilities | Downstream prefix | Legacy mapping
### Level-1 Sub-capabilities
Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status
## Legacy Mapping
V1 slug | V2 mapping | Migration note
```

标题必须与记录 ID 一致。ID、slug 和 prefix 必须唯一且稳定。格式/schema 变更属于独立治理工作；不得建立并行的扁平 schema。

## Gate A — destination

分类必须为 `new-capability`、`existing-capability-change`、`new-sub-capability`、`existing-sub-capability-change`、`story-slice`、`stage-increment`、`technical-support-object` 或 `insufficient-information`。PM 确认对象类型、目标/临时 ID、适用时的父级以及变更模式。缺少确认时必须阻断 Gate B 和持久化。归属不在 registry 的对象必须停止并交接。

必须使用持久的用户/业务结果、稳定职责、可观察行为、持有/排除边界和非目标。名称、screen、stage、domain、component、provider 或代码标签不得作为 Capability 身份证据。

## Gate B — granularity

- Capability：具有独立的长期结果和完整边界，并且跨越多个 Story/Slice 或交付单元；必须按照结果、持有范围、排除范围和相邻关系比较最接近的两个 Capability。
- Sub-capability：具有已确认的父级和稳定的一级职责，并明确入口、输出和排除范围；必须比较最接近的同级对象，并说明它在父级边界内的价值。
- 范围过宽、过窄或已由其他对象持有时，必须返回 Gate A。Gate B 的结果为 `pass` 或 `fail`；不得改变 PM 已确认的归属。

## Process

1. 重述范围和来源事实；读取相关 registry 记录。
2. 运行 Gate A；问题未解决时，必须停止并等待 PM 确认。
3. 运行 Gate B、当前格式检查和身份检查。
4. 生成草案、影响清单、遗漏范围和交接信息。
5. 持久化前必须获得 PM 批准、运行 validator，并在适用 `G-INDEPENDENT-CHECK` 时取得独立 checker 证据。

## Red Flags

从标签或代码推断 Capability；将 CRUD/screen/stage 当作 Capability；缺少 PM 归属决定；持久化临时记录；缺少同级/父级比较；重复使用 ID；存在未解释的单向相邻关系；自动编辑下游 Artifact；在 schema 不支持时接受 lifecycle 变更。

## Verification

归属和 Gate 适用性明确；格式、ID、父级和相邻关系通过校验；草案与批准明确分离；影响和遗漏范围具体；没有发明行为或下游范围；持久化具有 PM 批准和任何 Gate 要求的 checker 证据。

## Common Rationalizations

| 辩解 | 实际规则 |
| --- | --- |
| “名称足以证明它是 Capability。” | 身份取决于持久结果、职责、边界和 PM 确认。 |
| “把 V2 后继对象放进 Legacy Mapping。” | schema 不支持的 lifecycle 数据需要进行 schema 治理，不得使用自由文本编码。 |
