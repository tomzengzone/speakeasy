---
name: story-map-develop
description: Use when：Product Manager 创建、拆分、重写、审查或批准 User Story 及其嵌套的 Child Vertical Slice，并需要判断 Capability 归属或 Story/Slice 颗粒度。不适用于 Capability 重构、FR、TC 或实现工作。
---

# Story Map Develop

## Overview

以用户价值和端到端反馈为边界，维护 User Story 及其嵌套 Child Vertical Slice 的唯一当前产品事实来源。

## Contract

这是 `STORY_MAP` 的 method Skill。治理事实必须通过 `GOVERNANCE_INDEX` 解析；`CAPABILITY_REGISTRY` 提供分类边界，不提供行为事实。

本项目的 Parent User Story 是 Story Map 中的用户价值场景；Child Vertical Slice 是可进入交付的最小端到端产品行为单元，对应业界常说的 sprint-ready User Story 或 vertical Product Backlog Item。该术语映射不改变现有 Artifact schema，也不得把 Parent User Story 当作迭代承诺或实现任务容器。

## Inputs

PM 决策、相关当前 Story Map 记录、适用的 Capability/Sub-capability 边界、用户/场景/目标、可见结果、业务决策或状态变化、关键失败/恢复路径和明确的非目标。需要判断 ready 颗粒度时，团队完成一个符合适用 Definition of Done 的迭代能力只作为临时评估输入，不写入 Story Map。

## Outputs

嵌套在 Capability 章节下的 Story 记录，以及嵌套在一个 Story 下、可独立排序和验证的 Child VS 记录。Story 直接记录 Capability 分类；嵌套关系持有 VS-to-Story 直接关系。分类边界不成立、产品行为不足或候选条目只是验收细节/实现任务时，输出 finding 而不是制造 Story Map 行。

## Process

1. Read when：对于记录创建、语义重写、拆分/合并或批准就绪工作，必须读取 [Story 和 Slice 就绪门](references/ready-gates.md)。
2. 确认产品决策和分类，不得从标签推断行为。Primary Capability 必须拥有该记录的主要业务决策、状态或结果；Affected Capability 只记录真实的跨 Capability 产品交接，不记录被触及的页面、代码模块或技术层。
3. 先把 Parent User Story 写成一个参与者在具体情境下完成的单一用户目标及其可见价值；不同用户意图、独立旅程或主要结果必须拆成不同 Story。
4. 再从 Story 中切出最小端到端 Child VS：从触发或入口贯穿必要产品边界到可见结果，并包含使用户决策发生变化的业务状态、关键失败或恢复路径。Slice 可以跨 UI、API、domain 和 persistence，但不得按这些技术层横向拆分。
5. 将候选条目分类为 `delivery slice`、`acceptance detail`、`engineering task`、`cross-cutting constraint` 或 `ambiguity`。只有 `delivery slice` 可以成为 Child VS；其他类型必须并入所属 Slice 的必要语义、交给其 owning 下游 Artifact，或作为 finding 返回。
6. 使用 `INVEST` 作为诊断而不是固定模板：Child VS 应该尽量独立、可协商、有价值、可估算、足够小且可测试。它必须能由一个跨职能团队在一个迭代内达到适用 Definition of Done；不得用固定 Story Point、天数或 Child 数量替代语义判断。
7. 通过嵌套关系保留一个父级；不得增加重复的父级列。只有 Product Manager 可以设置 `approved`；必须校验本次修改的记录。

## Red Flags

将页面、技术 module、endpoint 或数据表当作 Story；将 Capability 文本当作行为；按 UI/backend/database 横向切分；把字段、按钮、格式校验、loading、文案、单个错误码或通用 retry 各自写成 Child VS；公式化的 CRUD Slice；用 Child VS 罗列 acceptance details；一个 VS 包含多个独立闭环；包含 Story Point、工期、Stage/Increment 交付 metadata；将 FR/TC/Contract 正文复制到 Story Map；使用下游 Artifact 制造完整性。

## Verification

每个已批准 Story 只表达一个用户目标和主要结果；每个已批准 VS 都有唯一的已批准 Story 父级、一个可演示的端到端用户闭环、可独立验证的价值或学习结果，并能在一个迭代内达到适用 Definition of Done。分类真实存在且由主要业务决策/状态归属决定；description 持有记录语义；所有候选行都通过类型判定；没有技术层横切、验收清单化、重复交付链或下游正文。
