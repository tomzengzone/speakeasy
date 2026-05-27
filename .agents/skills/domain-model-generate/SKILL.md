---
name: domain-model-generate
description: Use when a feature needs entities, relationships, lifecycle states, or persistence boundaries defined. Do not use when the change only affects presentation copy or layout.
---

# Domain Model Generate

## Overview
Keep domain concepts stable before database, API, AI runtime, or UI work depends on them.

## When to Use
- A feature introduces or changes business entities.
- A workflow needs state transitions or lifecycle rules.
- Data ownership between frontend, backend, and AI runtime is unclear.

## When NOT to Use
- No persisted or shared domain data changes.
- The entity already exists and only a field label changes.
- The task is an isolated UI polish change.

## Inputs
- Increment spec and acceptance criteria for new product work.
- Feature spec only for legacy flat feature artifacts or stable feature contract work.
- Existing docs/domain/ files.
- Architecture module boundaries and API contract.

## Outputs
- Entity list with fields and invariants.
- Relationships, lifecycle, and state machine notes.
- Persistence and API boundary recommendations.
- Traceability note to the owning increment or stable feature.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 领域总览写入 `docs/domain/domain_schema.md`。
- 实体关系写入 `docs/domain/entity_relationship.md`。
- 专项领域模型写入 `docs/domain/<domain>_model.md`，例如 `scene_model.md`、`expression_model.md`、`review_model.md`。
- 输入优先读取 `docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/increments/<increment-id>/spec.md`、`docs/product/increments/<increment-id>/acceptance.md` 和 `docs/architecture/system_overview.md`；`docs/product/acceptance_criteria.md` 仅作显式 legacy compatibility、migration 或 audit 输入。
- 涉及持久化或跨模块状态变更时，确认 `docs/process/change_request.md` 是否已有对应记录。

## Product Object Rules
- For new product work, start from `docs/product/increments/<increment-id>/spec.md` and `docs/product/increments/<increment-id>/acceptance.md`.
- Domain changes must cite the owning increment, primary feature, and affected features.
- Do not create a domain model from a stage goal, roadmap item, or feature registry entry alone.
- If domain work changes a long-lived product concept, update the stable feature reference as well as the increment traceability note.

## Process
1. Identify nouns, actions, and state transitions from the increment or feature spec.
2. Separate domain concepts from transport DTOs and UI view models.
3. Define IDs, ownership, uniqueness, timestamps, and audit needs.
4. Describe lifecycle states and allowed transitions.
5. Flag migration or seed data requirements.
6. Update docs/domain/ before implementation.

## Red Flags
- Database fields appear before domain meaning is defined.
- The same concept has multiple names across docs.
- State can move backward without a rule.
- AI output fields are treated as durable truth without validation.
- Domain concepts are added without an owning increment or stable feature.

## Verification
- Each entity has an owner and lifecycle.
- Relationships are navigable without ambiguity.
- Constraints explain duplicate, deletion, and archival behavior.
- API and database work can proceed without guessing.
- The domain model cites the increment or feature artifact that required it.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
