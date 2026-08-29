---
name: requirement-refine
description: Use when：Product Manager 已决定针对某个已批准 User Story 下的已批准 Child Vertical Slice，创建或变更 Functional Requirement，将实现准备所需的产品级行为规则、不变量、边界和失败语义细化为可测试要求；也适用于现有 Functional Requirement 的拆分、合并及不改变语义的字段规范化。不适用于产品行为决策或审批、未批准的 Story/Vertical Slice、Engineering Contract 与技术设计、Test Case、代码实现或行为不变的实现工作。
---

# Functional Requirement Refine

## Overview

在已批准 User Story 和 Child Vertical Slice 的范围内，将实现准备前必须唯一确定的产品行为、业务规则、不变量、边界和失败语义细化为可测试的 Functional Requirement（FR）。Functional Requirement 是 Vertical Slice 的可选下游产品规格，不替代或重述用户价值闭环，不引入未经 Product Manager 批准的产品决策，也不规定工程实现方案。

## Inputs

- 选定的已批准 Child Vertical Slice 及其唯一已批准 User Story 父级；
- Product Manager 已批准为该 Vertical Slice 创建或变更 FR 的决定，以及需要在实现准备前唯一确定的产品规则、边界和失败语义；
- 仅在变更、拆分、合并或规范化现有 FR 时，读取本次范围内受影响的当前 FR 记录。

## Outputs

输出一个或多个原子 FR。原子 FR 是一个可以独立审批、独立变更且独立验证的规范性需求单元。

## Process

1. 确认选定的 VS 已批准、具有唯一的已批准 Story 父级，并核对本次实现准备范围与非目标。
2. 从 VS 及明确 PM 决策中识别实现前必须唯一确定的规则，不复制用户闭环叙事。
3. 仅按实际适用性检查：业务规则/不变量，输入/资格/权限/状态边界，生命周期/状态迁移，重试/重复/并发/幂等/重放语义，失败/降级/恢复，安全/隐私/数据一致性/滥用防护，成功后置条件/路由/跨会话连续性。
4. 将用户或调用方可观察的行为保留在 FR；存储、API、密码学、组件、部署和其他实现决策不得写入 FR Catalog。
5. 按审批边界、生命周期、变更风险和测试判定依据评估粒度；任一维度可独立维护时，必须形成独立 FR 行，合并仅限于同一规范性需求单元。
6. 实际生成或规范化 FR Catalog 时，必须使用 [Functional Requirement 模板](assets/functional-requirement.template.md)。该模板只提供输出格式，需求内容仍必须来自已批准输入；`source_vs_ids` 是唯一直接产品追溯关系，并且只能引用已批准 Child Vertical Slice。
7. 仅对已批准且语义完整的现有 FR 执行拆分、合并或 Markdown 规范化，并保持未受变更影响的产品事实不变。

## Stop Conditions

产品事实缺失、冲突或无法证明来源时必须停止登记，并将待决策问题返回 Product Manager；不得写入不完整 FR。

## Red Flags

- 使用未声明的对象名称或缩写，而不是已声明等价的 `Functional Requirement` / `FR`；
- 从 Capability 文本、Engineering Contract、Test Case 或代码反推产品行为；
- 把某个功能、供应商、存储技术或算法个例固化为通用 Skill 规则；
- 把数据库/缓存选型、字段/索引、密码学算法、密钥、组件或部署方案写成 FR 产品事实；
- 将不同审批边界、生命周期、变更风险或测试判定依据强行合并；
- 增加模板未声明字段或第二条产品追溯字段，或夹带规划、实现、测试、执行结果与发布状态；
- 在产品语义不完整时生成看似完整的记录；
- 复制 Governance Contract 权威事实，或将模板当作内容权威来源。

## Verification

必须确认：

- 全文仅以已声明等价的 `Functional Requirement`、`FR` 表示该对象；
- 输出格式符合直接链接的 [Functional Requirement 模板](assets/functional-requirement.template.md)，且未增加模板未声明字段；
- 每个 FR 仅通过非空 `source_vs_ids` 引用已批准 VS，`Status` 为 `approved`，`Requirement` 非空且可测试；
- 每行可以按照审批边界、生命周期、变更风险和测试判定依据独立维护；
- 任何缺失或冲突的产品事实都未被自行补全；
- 拆分、合并或 Markdown 规范化未改变未受影响的产品事实。

实际生成或规范化 Catalog 记录时，必须从该 Artifact 的 Governance Contract 记录解析并运行当前 `validation_command`。仅修改或审查本 Skill 定义时，必须改为从 `SKILL_DEFINITION` 与适用 Gate 解析验证；Derived operational pointer（SKILL_DEFINITION.validation_command）：`python scripts/validate_agent_skills.py`。
