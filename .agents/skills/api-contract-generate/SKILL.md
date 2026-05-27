---
name: api-contract-generate
description: Use when frontend, backend, or AI runtime work needs a contract-first API boundary with request, response, and errors. Do not use for private helper functions or purely local state changes.
---

# API Contract Generate

## Overview
Define stable API contracts before implementation so clients, tests, and services share one source of truth.

## When to Use
- A feature crosses frontend/backend boundaries.
- An endpoint or DTO changes.
- Error behavior or compatibility needs to be explicit.

## When NOT to Use
- The change is fully client-side or fully internal.
- The endpoint exists and only implementation internals change.
- A temporary spike is being thrown away.

## Inputs
- Increment spec and domain model for new product work.
- Feature spec only for legacy flat feature artifacts or stable feature contract work.
- Existing docs/architecture/api_contract.md.
- Existing `docs/architecture/openapi/speakeasy-api.yaml` when present.
- Security and compatibility requirements.

## Outputs
- Endpoint purpose, method, path, auth, request, response, and errors.
- Versioning and compatibility notes.
- Examples that avoid leaking implementation details.
- Traceability note to the owning increment or stable feature.
- Updated OpenAPI source-of-truth when implementation-level API schemas are approved.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- API 契约总览写入 `docs/architecture/api_contract.md`，用于记录 API family、契约范围、产品对象追溯、统一错误模型、版本策略、兼容性和 OpenAPI 生成边界。
- 机器可执行 OpenAPI source of truth 写入 `docs/architecture/openapi/speakeasy-api.yaml`，用于记录 paths、components、request/response schema、examples 和 OpenAPI lint 输入。
- `docs/architecture/api_contract.md` 不得复制完整 OpenAPI schema；`docs/architecture/openapi/speakeasy-api.yaml` 不得承载产品优先级、roadmap 决策或未批准 future-stage endpoint。
- 输入优先读取 `docs/product/features/<feature-slug>-spec.md`、`docs/domain/domain_schema.md` 和相关 `docs/domain/<domain>_model.md`。
- 若 API 变更影响模块边界或数据流，同步更新 `docs/architecture/module_boundary.md` 或 `docs/architecture/data_flow.md`。
- 重大兼容性或架构取舍写入 `docs/architecture/adr/<id>-<slug>.md`。

## Product Object Rules
- For new product work, start from `docs/product/increments/<increment-id>/spec.md` and cite the owning increment in the API contract update.
- Do not add or change an API contract from a stage goal, roadmap item, or feature registry entry alone.
- API changes that affect multiple features must list the primary feature, affected features, and compatibility risk.
- If the approved increment spec is missing, return to `feature-spec-generate` before defining the API contract.

## Process
1. Define the user or system capability before the route shape.
2. Specify request and response schemas with required and optional fields.
3. Define error semantics with stable codes and recovery hints.
4. Check backward compatibility and migration needs.
5. Keep storage, provider, and framework details out of the contract.
6. Map contract cases to API tests.

## Red Flags
- The API mirrors database tables without use-case boundaries.
- Errors are only generic 500 responses.
- Response fields expose internal provider or ORM details.
- Breaking changes lack migration or version notes.
- Contract changes lack an owning increment or stable feature reference.

## Verification
- Client and server can be implemented independently from the contract.
- Each error has code, message semantics, and status.
- Examples cover at least one success and one failure path.
- Tests can validate compatibility.
- The contract maps back to the increment spec or stable feature contract that required it.
- `docs/architecture/api_contract.md` and `docs/architecture/openapi/speakeasy-api.yaml` have non-overlapping source-of-truth responsibilities.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
