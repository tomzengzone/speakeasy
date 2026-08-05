---
name: story-map-develop
description: Use when：Product Manager 创建、拆分、重写、审查或批准 User Story 及其嵌套的 Child Vertical Slice。不适用于 FR、TC 或实现工作。
---

# Story Map Develop

## Overview

维护 Story Map 中 User Story 及其嵌套 Child Vertical Slice 的产品叙事，将用户价值场景组织为清晰的 Story，并拆分为可独立验证的最小用户闭环，同时保持明确的父子关系和就绪质量。

## Contract

这是 `STORY_MAP` 的 method Skill。治理事实必须通过 `GOVERNANCE_INDEX` 解析；`STORY_MAP` 持有 User Story 和 Child Vertical Slice 层的产品叙事，`CAPABILITY_REGISTRY` 持有 Capability/Sub-capability 分类与边界事实，存在时的 `FUNCTIONAL_REQUIREMENT_CATALOG` 持有从 approved Child Vertical Slice 提炼出的 Feature Requirement 规则、边界和失败语义。各 Artifact 不得替代或复制其他事实层的正文。

## Inputs

PM 已确认的产品决策、相关当前 Story Map 上下文、用户及使用情境、用户目标与可见价值，以及适用的业务决策、状态变化、关键失败路径、边界和非目标。

## Outputs

一个表达完整用户价值场景的 User Story 父级记录，以及在需要交付拆分时嵌套于该 Story 下的 Child Vertical Slice 记录。记录只使用 `Id`、`description` 和 `Status` 表达本层事实；父子关系由嵌套持有，不记录 Capability 映射或重复的父级字段。

输出完整 Story 时可以使用 [User Story 输出模板](assets/user-story-card.template.md)；只输出 Child Vertical Slice 时可以使用 [Child Vertical Slice 输出模板](assets/vertical-slice-card.template.md)；用户明确要求就绪审查结果时可以使用 [就绪审查输出模板](assets/ready-gate-output.template.md)。这些 assets 只定义可选版式，不是规则来源。

## Process

1. Read when：对记录创建、语义重写、拆分、合并或批准就绪工作，必须读取 [User Story 和 Child Vertical Slice 就绪参考](references/ready-gates.md)；仅调整不改变语义的格式时不得读取。
2. 确认用户、情境、目标、可见价值和未决产品决策。Product Manager 对产品语义负责；工程、UX 和 QA 可以提供可行性、交互与可验证性输入，但不得据此补写未决定的产品行为。
3. 将一个连贯的用户价值场景写为 User Story 父级容器，不把它写成页面、模块、技术任务或实现单位。
4. 需要拆分交付时，将 Story 拆为最小的 Child Vertical Slice；每个 Child Vertical Slice 必须可独立交付、可独立验证、形成端到端路径并产生可观察的用户或业务价值。
5. 通过文档嵌套保留唯一父级；不得增加 Capability、Parent、验收条件、交付计划或下游 Artifact 字段。
6. 只有 Product Manager 可以把 `Status` 设置为 `approved`；持久化前必须验证本次修改范围。

## Red Flags

将 `STORY_MAP` 表述为整条产品事实源链的唯一来源；按照 Capability、文件分片、页面或 module 组织用户价值场景；从 Capability 或下游 Artifact 推断行为；将字段校验、按钮状态、提示文案、API、数据层工作、测试任务或单条验收条件作为 Child Vertical Slice；按照 CRUD、loading、save、retry 或成功/失败分支机械拆分；依赖 sibling 才能产生价值；一个 Child Vertical Slice 包含多个可独立结果；添加 priority、Stage、Increment、roadmap 或 release metadata；复制 FR、TC 或 Contract 正文。

## Verification

通过 `STORY_MAP` 解析并运行其 `validation_command`。同时人工确认：每个 approved Child Vertical Slice 有唯一的 approved User Story 父级；User Story 只表达一个连贯用户价值场景；每个 Child Vertical Slice 可独立交付、可独立验证、形成端到端路径并产生可观察价值；Sibling 之间不重叠且不互相依赖才能形成基本价值；记录只有 `Id`、`description`、`Status`，没有 Capability 映射或下游内容。确定性校验结果不得替代语义就绪审查。
