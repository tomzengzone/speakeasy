---
name: implementation-report-generate
description: Use when：已完成的实现或治理工作需要持久记录工作范围、变更文件、验证证据、剩余风险、回滚上下文和后续事项，并形成可审计的交付记录。不适用于验证完成之前、无变更工作或临时任务摘要已经足够的场景。
---

# Implementation Report Generate

## Overview

创建可审计的交付记录，但不得复制产品、工程、测试或治理权威事实。

## When to Use

只有在已知变更文件和验证结果，并且用户或适用 contract 要求持久化实现报告时才使用。

## When NOT to Use

不得用于探索性或无变更工作、验证完成之前，或者临时任务摘要已经足够的场景。

## Contract

这是 `IMPLEMENTATION_REPORT` 的 method Skill。必须从 `GOVERNANCE_INDEX` 解析 path、lifecycle、contributor 字段和 validation command。

## Inputs

适用时选定的 VS/FR/Contract/TC ID、实际变更文件列表及用途、准确的命令与结果、跳过的检查、风险和后续事项。

## Outputs

一条仅追加的报告记录，其中包含范围、变更文件、验证证据、明确标注的未运行检查、风险、回滚上下文和后续步骤。

## Derived operational pointer

需要持久化报告时，解析得到的 `IMPLEMENTATION_REPORT` contract 当前指向 `docs/reports/implementation_report.md`；写入前必须对照 contract 验证该指针。

## Process

1. 确认确实需要持久化报告。
2. 关联稳定的产品/Contract/TC ID，但不得复制其内容。
3. 按用途对文件分组，并且只记录实际运行的命令和结果。
4. 说明跳过的检查、剩余风险、回滚上下文和后续事项。
5. 只追加新记录，不得改写以前的记录；运行解析得到的校验。

## Red Flags

没有证据就声称完成；复制产品/Contract/测试判定依据文本；将计划运行的命令报告为已运行；隐藏风险；将 Stage/Increment 当作产品权威来源；在不需要时写入报告。

## Verification

每个有意义的变更区域都已覆盖；证据与实际执行一致，并在适用时与受检查的 commit 一致；跳过的工作已明确说明；没有重新定义任何权威事实。
