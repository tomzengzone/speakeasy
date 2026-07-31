---
name: test-case-generate
description: Use when：已批准 FR、发生变化的 Engineering Contract，或正在实现的 Vertical Slice 需要稳定的 FR-TC、Contract-TC 或 VS-TC 设计。不适用于只需执行测试的场景。
---

# Test Case Generate

## Overview

设计分层且可执行的 Test Case；每个 Test Case 只有一种带类型的直接上游，并具有可复用且自包含的测试判定依据。

## When to Use

用于存在已批准 FR 时的 FR-TC 设计、Engineering Contract 事实变更、选定 VS 的全链路覆盖，或者需要稳定回归测试判定依据的缺陷。

## When NOT to Use

不得用于运行现有测试、存储 CI 结果、发明行为，或者弥补不完整或未批准的 VS/FR。

## Contract

这是 `TEST_CASE_CATALOG` 的 method Skill。治理事实必须通过 Artifact ID 解析。TC 执行结果属于 CI evidence，不属于该 Catalog。

## Inputs

选定的已批准 VS、存在时的已批准 FR、发生变化的 Engineering Contract ID、现有测试约定与代码、稳定 selector、fixture、失败边界和目标命令。

## Outputs

FR-TC、Contract-TC 和 VS-TC 记录；每条记录包含一种带类型的直接关系、自包含的 Given/When/Then、测试判定依据、边界/反向用例、层级、范围、selector、脚本路径和命令。

## Process

1. 必须选择且仅选择一种类型：FR-TC 必须仅使用 `source_fr_id`；Contract-TC 必须仅使用 `source_contract_id`；VS-TC 必须仅使用 `source_vs_id`。
2. 对于 FR-TC，选择可以证明所引用 FR 行为的最低成本层级；如果独立行为需要不同的测试判定依据或层级，应该增加 FR-TC。
3. 对于 Contract-TC，选择可以证明发生变化的工程事实的 contract/integration/migration/AI-eval 或其他层级。
4. 对于 VS-TC，在所有实际受影响的层级覆盖用户可见的 integration/E2E 闭环及其关键降级路径。
5. 添加稳定的 selector、脚本和命令；不得包含 runtime 结果状态。
6. 运行通过 `TEST_CASE_CATALOG` 解析得到的 validation command。

## Red Flags

存在多种直接上游类型；复制跨层覆盖关联；在 Catalog 中记录通过状态；只有 happy path；selector 不稳定；将 release smoke 作为首次缺陷反馈；测试重新定义产品行为。

## Verification

存在 FR 时，每个 FR 都有 FR-TC 或有时限的明确例外；每个 implementing VS 都有 VS-TC；每个发生变化的 Contract 都有 Contract-TC；所有记录都具备可执行字段，并且只有一种允许的直接关系。
