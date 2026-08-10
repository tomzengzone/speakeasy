---
name: screen-spec-generate
description: Use when：已批准的 Vertical Slice，或存在时适用的已批准 Functional Requirement，导致 Flutter/mobile screen 的行为、状态、交互或 API/AI 依赖发生变化。不适用于只包含轻微视觉调整的场景。
---

# Screen Spec Generate

## Overview

将 approved Vertical Slice 的产品语义细化为实现就绪的页面与 screen 表达，使开发和验证无需补写用户行为。

## Contract

这是 `SCREEN_SPEC` 的 method Skill。治理事实必须通过 Artifact ID 解析；本 Skill 只细化 approved Vertical Slice，不得重新定义、缩减、替换或发明其产品行为。User Flow 和 Usability Checklist 保留各自的 Artifact 事实归属。

## Inputs

选定 approved Vertical Slice 中已确认的用户目标、行为或选择、产品状态影响、可见结果和关键恢复语义；存在时适用的 approved Functional Requirement；受影响的 UX、API、AI Contract；当前导航、状态和无障碍约束。

## Outputs

approved Vertical Slice 范围内的页面或 screen 结构、component 呈现与 data 边界、精确交互状态转换、视觉反馈、适用的异常与恢复状态、无障碍要求和稳定 selector。

## Process

1. 确认选定的 approved Vertical Slice、存在时适用的 approved Functional Requirement，以及受影响的 Contract。若实现所需的用户行为、选择、产品状态影响、可见结果或关键恢复语义缺失或冲突，必须返回 owning Story、Vertical Slice 或 Functional Requirement 解决，不得在 `SCREEN_SPEC` 中补写。
2. 保持上游产品语义不变，将每项已确认行为细化为页面或 screen 结构、component 呈现、data 边界和精确交互状态转换。
3. 为每项操作定义可见反馈；仅在上游语义或受影响 Contract 要求时细化 loading、empty、error、offline、duplicate 和 retry 等状态，不得由通用模式引入新的产品选择、状态影响或结果。
4. 定义适用的无障碍要求和稳定 selector，使这些实现就绪 UX 事实支持后续 Contract-TC 与 VS-TC 设计和验证，而不复制测试用例正文或直接关系。
5. 运行解析得到的校验和适用的 UX review。

## Red Flags

重新定义、缩减、替换或发明 approved Vertical Slice 的产品行为；把缺失产品事实当作 UX 决策补写；从通用 UI 模式、下游 Contract 或测试用例反推产品选择或结果；遗漏适用状态或可见反馈；将自由格式 AI 输出当作权威事实；component 持有边界外 data；复制测试用例正文或治理事实；范围膨胀；缺少无障碍要求或稳定 selector。

## Verification

逐项确认 approved Vertical Slice 的目标、行为或选择、产品状态影响、可见结果和关键恢复语义均保持不变并获得实现就绪表达；`SCREEN_SPEC` 中每个产品选择与结果均可追溯到上游事实；缺失或冲突事实已返回上游而未被补写；每个适用操作都有精确状态转换、可见反馈、无障碍要求和稳定 selector；受影响的 Contract-TC 与 VS-TC 可以验证各自边界。
