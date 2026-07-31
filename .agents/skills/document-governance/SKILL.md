---
name: document-governance
description: Use when：文档工作同时涉及 path governance、content contract、traceability 或多个文档 authority 问题。
---

# Document Governance

## Overview

对混合文档治理问题进行路由，但不得复制 child method 或 Governance Contract 事实。

## When to Use

用于混合的 path/content/traceability 请求、新文档类别、source 冲突或文档治理变更。

## When NOT to Use

单一的 path、content-boundary 或 traceability 问题必须使用对应 child Skill；不得用于普通文档编写。

## Contract

治理事实必须从 `GOVERNANCE_INDEX` 解析。本 router 只负责分类、排序和冲突升级。

## Inputs

用户请求、受影响的 Artifact/Gate ID、相关 contract record、发生变化的文档/Skill/Agent，以及 child method 发现项。

## Outputs

输出路由决策、排序后的 child task、冲突/优先级发现项和临时 handoff；除非明确要求受治理报告，否则不得持久化。

## Process

1. 区分单一范围与混合范围，并解析相关 Artifact/Gate ID。
2. 将 canonical path/source 问题路由给 `document-path-governance`。
3. 将受众、必需内容和禁止内容问题路由给 `document-content-contract`。
4. 将 owning-edge 和派生投影检查路由给 `document-traceability-check`。
5. 必须向 accountable owner 暴露冲突，并且只能更新 owning authority。

## Red Flags

以下情况属于危险信号：复制 path/owner/dependency 表；在此处复制 child schema；静默解决冲突；没有 contract scope 却持久化发现项；文档审查改变产品事实。

## Verification

必须确认每个问题只有一个 owning route、没有创建第二套 authority、冲突和遗漏范围均已明确，并且适用的 validator 全部通过。
