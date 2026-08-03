---
name: api-contract-generate
description: Use when：已批准的 Vertical Slice，或存在时适用的已批准 Functional Requirement，导致前端/后端或外部 API 边界发生变化。不适用于私有 helper 或仅限本地的状态。
---

# API Contract Generate

## Overview

定义稳定的 API 行为，使客户端、服务端和测试可以独立实现。

## Contract

这是 `API_CONTRACT` 的 method Skill；`OPENAPI` 是配套的机器可读 Artifact。所有治理事实必须通过 Artifact ID 解析。选定的已批准 VS 是产品上游；存在适用的已批准 FR 时，FR 提供需求追溯关系。Domain Schema 是条件性工程上下文。

## Inputs

选定的已批准 VS ID、存在时适用的已批准 FR ID、当前 API/OpenAPI 和 Domain 事实、安全与兼容性约束、受影响的客户端，以及相关 Contract-TC 需求。

## Outputs

用途、method/path/auth、请求/响应、校验、稳定错误/恢复、兼容/迁移规则、示例，以及可测试的 contract 变更。

## Process

1. 确认选定的已批准 VS、任何适用的已批准 FR，以及实际发生变化的 API 事实。
2. 必须先定义边界语义，再定义路由形式；不得包含存储、provider 或 framework 细节。
3. 必须分别在各自的事实归属边界内更新说明文档和 OpenAPI。
4. 新增或更新 Contract-TC 时，必须仅使用 `source_contract_id`。
5. 运行通过受影响 Artifact ID 解析得到的 validation command。

## Red Flags

表格机械镜像；只有通用错误；泄漏 provider 细节；破坏性变更没有迁移方案；在 API 说明中新增产品行为；说明文档与机器可读 schema 重复声明事实归属。

## Verification

客户端和服务端可以独立实现；错误与兼容性明确；选定 VS 的追溯关系和存在时 FR 的追溯关系可以通过 governance/traceability 解析；Contract-TC 可以证明每项发生变化的事实。
