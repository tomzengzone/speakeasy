---
name: screen-spec-generate
description: Use when：已批准的 Vertical Slice，或存在时适用的已批准 Functional Requirement，导致 Flutter/mobile screen 的行为、状态、交互或 API/AI 依赖发生变化。不适用于只包含轻微视觉调整的场景。
---

# Screen Spec Generate

## Overview

在实现之前定义用户可见的 screen 行为和状态转换。

## Contract

这是 `SCREEN_SPEC` 的 method Skill；User Flow 和 Usability Checklist 保留各自的 Artifact 事实归属。治理事实必须通过 Artifact ID 解析。选定的已批准 VS 是产品上游；存在适用的已批准 FR 时，FR 提供需求追溯关系。API/LLM contract 是条件性工程输入。

## Inputs

选定的已批准 VS ID、存在时适用的已批准 FR ID、当前 UX/API/AI contract、导航/状态约定、无障碍约束，以及相关 Contract-TC 需求。

## Outputs

目标/入口、component/data、命名状态/转换、可见反馈、loading/empty/error/offline/duplicate/retry 行为，以及可测试的 selector 需求。

## Process

1. 确认选定的已批准 VS、任何适用的已批准 FR，以及实际发生变化的 UX 事实。
2. 从用户的下一步操作开始，定义稳定的 component 和数据边界。
3. 覆盖成功、缓慢、离线、空数据、重复、错误和重试状态。
4. 将发生变化的 UX 事实映射到 Contract-TC，并将选定的 VS 映射到 VS-TC，不得复制它们的直接关系。
5. 运行解析得到的校验和适用的 UX review。

## Red Flags

缺少失败或空数据状态；将自由格式 AI 输出当作权威事实；component 持有边界外数据；范围膨胀；在 screen 说明中发明产品行为；缺少稳定 selector。

## Verification

开发者无需发明状态即可实现；每个操作都有可见反馈；API/AI 失败均已处理；Contract-TC 和 VS-TC 可以证明各自的边界。
