---
name: document-traceability-check
description: Use when：Story/VS/FR/Engineering Contract/Test Case 的追溯关系和派生覆盖需要独立审计。不适用于编写事实归属方持有的事实。
---

# Document Traceability Check

## Overview

从事实归属方持有的直接关系重建规范全链路投影并报告缺口，但不得在投影中创建或修复事实。

## When to Use

用于 Story/VS/FR/TC 变更、Engineering Contract 事实变更、覆盖审计、悬空 ID 或追溯投影更新。

## When NOT to Use

不得用于选择 canonical path、创建 requirement/test/contract、存储执行状态或批准产品行为。

## Contract

这是 `TRACEABILITY` 的 method Skill。必须通过 Artifact ID 解析其治理事实。投影是只读派生结果；直接关系必须从 Story Map、FR Catalog、Engineering Contract 和 TC Catalog 读取，不得从其他来源推断。

## Inputs

当前 Story Map、存在适用 FR 时的 FR Catalog、适用的 Engineering Contract 引用、TC Catalog，以及稳定的 selector/evidence link。

## Outputs

输出重建的投影、完整性/唯一性发现项、悬空关系发现项，以及交给事实归属方的修正信息。

## Process

1. 从 Story Map 读取 Story-to-Capability 直接关系和嵌套的 VS-to-Story 直接关系。
2. 存在 FR 时，必须从 FR Catalog 的 `source_vs_ids` 读取 VS-to-FR，不得从其他位置读取。
3. 当 FR 影响发生变更的 Contract 时，必须从持有该事实的 Engineering Contract 读取该关系。
4. 必须从各自带类型的 TC 字段读取当前存在的 FR-TC、Contract-TC 和 VS-TC 直接关系。
5. 连接 selector/evidence；存在 FR 时派生 VS-TC-to-FR 覆盖关系，并与只读投影比较。
6. 必须在事实归属方中修复差异，然后重新生成并验证追溯投影。

## Red Flags

以下情况属于危险信号：在追溯投影中编写直接关系；VS-TC 重复 FR ID；一个 TC 包含多种直接上游类型；将执行结果复制到投影；使用 Stage/Increment 表示追溯关系；当前 FR 缺少批准状态、VS 追溯关系、FR-TC 或其派生投影分支。

## Verification

必须确认每个当前分支都能无歧义解析且不存在悬空 ID；每个已批准 FR 都有直接 VS 追溯关系和 FR-TC 覆盖；每个已批准且正在实现的 VS 都有 VS-TC 覆盖；每个发生变化的 Contract 都有 Contract-TC；投影不包含独立关系或 runtime 结果状态。
