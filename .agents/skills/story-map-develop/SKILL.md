---
name: story-map-develop
description: Use when：Product Manager 创建、拆分、重写、审查或批准 User Story 及其嵌套的 Child Vertical Slice。不适用于 FR、TC 或实现工作。
---

# Story Map Develop

## Overview

维护 User Story 及其嵌套 Child Vertical Slice 的唯一当前产品事实来源。

## When to Use

用于 Story/VS 行为、边界、嵌套关系、分类或批准状态发生变化的场景。

## When NOT to Use

不得用于 FR、TC、Contract、交付规划、实现或历史产品文档维护。

## Contract

这是 `STORY_MAP` 的 method Skill。治理事实必须通过 `GOVERNANCE_INDEX` 解析；`CAPABILITY_REGISTRY` 提供分类边界，不提供行为事实。

## Inputs

PM 决策、相关当前 Story Map 记录、适用的 Capability/Sub-capability 边界、用户/场景/目标、可见结果、状态变化、失败路径和明确的非目标。

## Outputs

嵌套在 Capability 章节下的 Story 记录，以及嵌套在一个 Story 下的 Child VS 记录。Story 直接记录 Capability 分类；嵌套关系持有 VS-to-Story 直接关系。

## Process

1. Read when：对于记录创建、语义重写、拆分/合并或批准就绪工作，必须读取 [Story 和 Slice 就绪门](references/ready-gates.md)。
2. 确认产品决策和分类，不得从标签推断行为。
3. 编写包含用户、情境、目标和价值的 Story。
4. 将可独立验证的用户闭环拆分为 Child VS 记录，并包含触发条件、前置条件、用户选择、状态变化、可见结果和关键失败/边界。
5. 通过嵌套关系保留一个父级；不得增加重复的父级列。
6. 只有 Product Manager 可以设置 `approved`；必须校验本次修改的记录。

## Red Flags

将页面/module 当作 Story；将 Capability 文本当作行为；公式化的 CRUD Slice；一个 VS 包含多个独立闭环；包含 Stage/Increment 交付 metadata；将 FR/TC/Contract 正文复制到 Story Map；使用下游 Artifact 制造完整性。

## Verification

每个已批准 VS 都有唯一的已批准 Story 父级和完整用户闭环；分类真实存在；description 持有记录语义；没有复制交付链或下游内容。
