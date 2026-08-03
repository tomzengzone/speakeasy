---
name: prompt-contract-generate
description: Use when：已批准的 Vertical Slice，或存在时适用的已批准 Functional Requirement，导致 LLM prompt、结构化输出、fallback 行为或 AI evaluation 配置发生变化。不适用于没有 LLM 路径的确定性行为。
---

# Prompt Contract Generate

## Overview

约束 AI runtime 行为，使结构化输出、prompt、fallback 和 evaluation 保持安全且可测试。

## Contract

这是 `PROMPT_CONTRACT`、`LLM_OUTPUT_SCHEMA` 和 `AI_EVAL_CASES` 的 method Skill；相关 fallback/dialogue Artifact 保留各自的事实归属。治理事实必须通过 Artifact ID 解析。选定的已批准 VS 是产品上游；存在适用的已批准 FR 时，FR 提供需求追溯关系。

## Inputs

选定的已批准 VS ID、存在时适用的已批准 FR ID、当前 AI/Domain/API/UX 事实、安全/fallback/成本约束，以及相关 AI Contract-TC ID。

## Outputs

Prompt 约束、输入/输出 schema、正向/反向示例、确定性 fallback，以及以 TC ID 为键的 AI evaluation fixture、rubric 和配置。

## Process

1. 确认选定的已批准 VS、任何适用的已批准 FR，以及实际发生变化的 AI contract 事实。
2. 定义模型不得做出的决策，并且必须先设计结构化输出，再编写 prompt 文本。
3. 定义无效、低置信度、偏题和 provider 失败时的 fallback。
4. 必须将稳定的 AI 测试判定依据和 selector 放入 Contract-TC；AI Eval Cases 必须仅包含与 TC 关联的 fixture、rubric/threshold 和 provider/model 配置。
5. 运行解析得到的 schema/evaluation 校验。

## Red Flags

UI 解析自由格式文本；AI 修改进度或账单权威事实；格式错误的输出没有确定性 fallback；evaluation 文件复制产品行为、测试判定依据或执行结果；缺少 Contract-TC。

## Verification

输出符合 schema 且可以渲染；无效路径具有确定性；AI Contract-TC 持有测试判定依据；evaluation fixture/config 通过 TC ID 关联，且不复制执行状态。
