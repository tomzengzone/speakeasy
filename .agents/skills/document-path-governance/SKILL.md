---
name: document-path-governance
description: Use when：项目文档需要 canonical path、source-of-truth 决策、owner/lifecycle 审计，或 Agent/Skill path reference 审查。
---

# Document Path Governance

## Overview

审计或提出文档路由建议，同时将 canonical path、owner、lifecycle、inputs 和 scope 保留在 Governance Contract 中。

## When to Use

用于新增、移动或重命名文档类别，检查重复位置、source 冲突，或审计 Agent/Skill operational pointer。

## When NOT to Use

不得用于文档内容完整性、traceability 语义、普通文档生成或应用代码。

## Contract

所有 path/owner/lifecycle/input/contributor 事实都必须通过 Artifact ID 从 `GOVERNANCE_INDEX` 解析；不得让本 Skill 成为另一套 registry。

## Inputs

相关 Artifact ID/record、当前目录树、受影响的 Agent/Skill 定义、被引用的 resource，以及请求的路由决策。

## Outputs

输出拟议的 contract change 或审计发现项，标识重复位置、过期引用和 operational pointer。只有对 owning Governance Contract 的编辑才能建立 path。

## Process

1. 对 Artifact 进行分类，并解析其当前 contract record。
2. 检查 source 冲突以及 active reference 与 historical reference。
3. 必须验证 Agent/Skill reference 使用 Artifact ID；只有明确标记为 `Derived operational pointer` 且与 contract 对齐时，才可以使用精确 path/command。
4. 将 content 或 traceability 变更路由给对应 method。
5. 验证 owning contract 和 active definition。

## Red Flags

以下情况属于危险信号：path 只在 Skill/Agent 中建立；存在重复 canonical location；保留 legacy fallback；复制 owner/lifecycle/dependencies；将未注册 Template 当作 authority。

## Verification

必须确认每个 active Artifact 都能唯一解析、operational pointer 与 contract 一致、historical path 未被作为 active source，并且没有 non-owning layer 声称拥有 governance authority。
