---
name: document-content-contract
description: Use when：需要审查受治理文档面向的受众、必须包含与禁止包含的内容、上游事实的使用方式、下游消费边界及语义完整性，并需要形成交给 owning writer 的内容边界发现项。
---

# Document Content Contract

## Overview

定义或审查文档传达的内容，但不拥有其 path、owner、lifecycle、dependency graph 或 Gate routing。

## When to Use

用于审查受众、必需章节、禁止内容、语义完整性和下游消费边界。

## When NOT to Use

不得用于 path/source 决策、全链路 traceability、普通文档生成、code review 或产品分类。

## Contract

必须通过 Artifact ID 解析治理事实。本方法只负责内容边界分析；只能消费 direct inputs，不得重新定义它们。

## Inputs

目标 Artifact ID 及其内容、预期受众和用途、相关 contract record、owning method，以及已知上游事实。

## Outputs

必需/禁止内容发现项、受众/消费者契约、完整性缺口，以及交给 owning writer 的 handoff。

## Process

1. 解析目标 Artifact，并且只读取适用的上游事实。
2. 识别文档必须支持的读者决策。
3. 区分归属事实、上下文、派生投影和一次性证据。
4. 拒绝复制产品或治理事实，不得发明行为。
5. 报告 pass/block 发现项，并在 owner 修正后重新验证。

## Red Flags

以下情况属于危险信号：为了 Template 使用方便而形成新的 authority；复制 path/owner/dependency/Gate 数据；使用下游事实修补上游缺口；在非 owning document 中存储 traceability join。

## Verification

必须确认文档支持必需的读者决策、未包含禁止内容、使用 direct inputs 的方式一致，并且没有创建第二个 source。
