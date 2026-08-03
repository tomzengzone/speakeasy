---
name: requirement-refine
description: Use when：已批准并进入实现准备的 Vertical Slice 需要抽象、创建、拆分或变更 Feature Requirement（FR-RS），或已批准字段需要规范化呈现。不适用于 draft/unapproved VS、行为不变的代码工作、Engineering Contract 设计、Test Case、实现或产品审批。
---

# Feature Requirement Refine

## Overview

将已批准 Vertical Slice 中实现前必须唯一确定、但不得放入用户闭环叙事的 Feature 级规则提炼为 Feature Requirement（FR-RS）。FR-RS 只定义产品行为和工程影响交接，不决定工程实现方案。对象是否为实现准入必需项由适用 Workflow/Gate 决定，不得在对象名称前增加 `mandatory`。

## Contract

执行前必须通过 Artifact/Gate ID 解析适用 Governance Contract。Story/VS 和明确 PM 决策是 FR-RS 语义输入；Capability/Sub-capability 只用于分类，不是行为来源。Engineering Contract 持有存储、API、签名与加密、组件、部署和其他实现事实；FR-RS 只记录必须交接的工程影响类别与约束目标。本 Skill 不复制 canonical path、owner、lifecycle、dependency、contributor scope 或 Gate routing。

## Inputs

- 选定的已批准 VS 及其唯一已批准 Story 父级；
- PM 已批准的行为、边界、非目标和待决问题；
- 已批准的 Capability/Sub-capability 分类和相邻影响；
- 现有 FR-RS 及其重叠、冲突和变更影响；
- 与安全、隐私、数据一致性、权益或滥用防护相关的已批准产品约束；
- 可能受影响的 Engineering Contract 类别，不包含尚未由其事实归属方决定的实现方案；
- 仅做版式规范化时，由事实归属方提供的完整字段、字段适用性和省略决定。

## Outputs

输出以下任一结果：

- 可供审批或登记的 FR-RS 记录：稳定 ID、标题、`Status`、唯一直接追溯字段 `source_vs_ids`、分类、可测试规则、边界/失败语义、适用工程影响类别和 `Approval basis`；
- 拆分或合并建议：说明审批边界、生命周期、变更风险或测试判定依据的差异；
- 歧义交接：列出缺失决策、受影响 FR-RS 和暂停原因，不生成不完整记录；
- 对已提供完整值的 Markdown 规范化结果，其字段集合和字段值不得改变。

不是每个规则维度都必须产生字段或记录；只保留当前 Feature 适用且对实现准备必要的事实。

## Process

1. 确认选定的 VS 已批准、具有唯一的已批准 Story 父级，并核对本次实现准备范围与非目标。
2. 从 VS 及明确 PM 决策中识别实现前必须唯一确定的规则，不复制用户闭环叙事。
3. 仅按实际适用性检查：业务规则/不变量，输入/资格/权限/状态边界，生命周期/状态迁移，重试/重复/并发/幂等/重放语义，失败/降级/恢复，安全/隐私/数据一致性/滥用防护，成功后置条件/路由/跨会话连续性。
4. 将用户或调用方可观察的行为保留在 FR-RS；将存储、API、密码学、组件、部署和其他实现决策只记为 Engineering Contract 影响交接。
5. 按审批边界、生命周期、变更风险和测试判定依据评估粒度；任一维度独立时应该拆分，否则可以在一个 FR-RS 内保留同一审批边界的相关规则。
6. 必须仅使用 `source_vs_ids` 记录直接产品追溯关系；Story、Capability、Stage、Increment、Work Package 或 PR 不得成为第二条直接追溯关系。
7. 对缺失、冲突或无法证明来源的产品事实输出歧义交接；只有完整且可测试的内容才可进入审批或登记。
8. 对已提供并批准的完整字段做 Markdown 规范化时，必须逐字段保留标签、值和行内代码标记，不得在版式步骤改变语义。

## Red Flags

- 在对象名称前增加 `mandatory`，或使用 `FR`、`FR/RS` 等未声明的并行名称；
- 从 Capability 文本、Engineering Contract、Test Case 或代码反推产品行为；
- 把某个功能、供应商、存储技术或算法个例固化为通用 Skill 规则；
- 把数据库/缓存选型、字段/索引、密码学算法、密钥、组件或部署方案写成 FR-RS 产品事实；
- 将不同审批边界、生命周期、变更风险或测试判定依据强行合并；
- 添加第二条产品追溯关系，或夹带规划、实现、测试、执行结果与发布状态；
- 在产品语义不完整时生成看似完整的记录；
- 复制 Governance Contract 权威事实，或 `treating this template as content authority`（将模板当作内容权威来源）。

## Verification

必须确认：

- 全文以 `Feature Requirement`、`FR-RS` 表示该对象，且没有使用 `mandatory` 作为对象名称的一部分；
- 每个 FR-RS 必须仅通过 `source_vs_ids` 引用已批准 VS，分类有效，规则可测试，边界和失败语义明确；
- 粒度可以按照审批边界、生命周期、变更风险和测试判定依据独立维护；
- 工程影响类别已识别，但 FR-RS 未复制存储、API、密码学、组件或部署实现事实；
- 任何缺失或冲突的产品事实已作为歧义交接，没有被自行补全；
- 仅做 Markdown 规范化时，输出与已提供值逐字段一致。

实际生成或规范化 Catalog 记录时，必须从该 Artifact 的 Governance Contract 记录解析并运行当前 `validation_command`。仅修改或审查本 Skill 定义时，必须改为从 `SKILL_DEFINITION` 与适用 Gate 解析验证；Derived operational pointer（SKILL_DEFINITION.validation_command）：`python scripts/validate_agent_skills.py`。
