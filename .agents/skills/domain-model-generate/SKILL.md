---
name: domain-model-generate
description: Use when：已批准的 Vertical Slice，或存在时适用的已批准 Functional Requirement，导致实体、关系、生命周期状态、不变量或持久化事实归属发生变化。不适用于仅改变呈现方式的场景。
---

# Domain Model Generate

## Overview

在 API、后端、AI 或 UI 工作依赖领域与持久化事实之前，先使这些事实稳定下来。

## Contract

这是 `DOMAIN_SCHEMA` 和 `DOMAIN_MODEL` 的 method Skill；`ENTITY_RELATIONSHIP` 是相关 Artifact。治理事实必须通过 Artifact ID 解析。选定的已批准 VS 是产品上游；存在适用的已批准 FR 时，FR 提供需求追溯关系。Architecture/API 是工程上下文。

## Inputs

选定的已批准 VS ID、存在时适用的已批准 FR ID、当前 domain/relationship/model Artifact、系统与 API 边界、持久化约束，以及相关 Contract-TC 需求。

## Outputs

实体、字段、标识、不变量、关系、生命周期转换、持久化事实归属、迁移需求，以及可测试的 contract 变更。

## Process

1. 确认选定的已批准 VS、任何适用的已批准 FR，以及实际发生变化的领域事实。
2. 必须将领域概念与 DTO、数据库机制和 UI view model 分离。
3. 定义事实归属、唯一性、审计、删除规则和有效转换。
4. 只更新持有受影响事实的 Domain Artifact。
5. 新增或更新 Contract-TC，并运行解析得到的校验。

## Red Flags

在明确语义前先定义存储字段；命名不一致；转换不受约束；将 AI 候选结果当作持久事实；在模型中发明产品行为；缺少 Contract-TC。

## Verification

每个发生变化的概念都有明确的事实归属和生命周期；关系与删除规则无歧义；选定 VS 的追溯关系和存在时 FR 的追溯关系可以通过 traceability 解析；Contract-TC 可以证明每项发生变化的事实。
