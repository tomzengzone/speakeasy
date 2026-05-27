---
name: requirement-refine
description: Use when a user idea, feature request, or change request must be turned into scoped, testable product requirements. Do not use when implementation is already specified and only coding is needed.
---

# Requirement Refine

## Overview
Turn natural-language product intent into constrained, testable requirements before design or code begins.

## When to Use
- A new feature request is ambiguous or broad.
- A change may expand MVP scope.
- A feature needs user stories, non-goals, and success criteria.

## When NOT to Use
- The task is only a mechanical code edit with clear acceptance criteria.
- A bug has exact reproduction steps and expected behavior.
- The user explicitly asks to skip documentation for an emergency fix.

## Inputs
- User request or change request.
- Existing product docs under docs/product/.
- Product object classification from Product Manager: feature, stage, increment, baseline, change request, or artifact.
- `docs/product/base/requirements.md` when consolidating or updating accepted stable product requirements.
- For new product work, the feature registry, active stage, and increment definition when available.
- Known constraints, target users, and MVP boundary.

## Outputs
- Product object classification and path decision.
- Updated docs/product/user_stories.md or feature-specific notes.
- Product Base requirements in `docs/product/base/requirements.md` for accepted stable product behavior.
- Durable feature requirements in `docs/product/features/<feature-slug>/requirements.md` for stable product capabilities.
- Increment requirements in `docs/product/increments/<increment-id>/requirements.md` for stage-bound delivery slices.
- Baseline references in `docs/product/baselines/<baseline-slug>.md` only when consolidating implemented behavior.
- Testable success criteria.
- Explicit non-goals and assumptions.
- Upstream requirement references that can later feed feature specs and acceptance criteria.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 产品级定位和边界写入 `docs/product/vision.md` 与 `docs/product/mvp_scope.md`。
- 用户故事写入 `docs/product/user_stories.md`。
- 功能级需求收敛写入 `docs/product/features/<feature-slug>-requirements.md`。
- 范围扩展、跨模块影响或 MVP 变更写入 `docs/process/change_request.md`。
- 延期项或非 MVP 能力写入 `docs/product/feature_backlog.md`，或在功能级需求文档中标记为后续延展。
- 当前 MVP 代码基线固化时，需求可以结合实际代码证据反向收敛；P0 或新增功能必须先形成需求，再进入 feature spec，之后由 acceptance criteria 建立强制追溯矩阵。

## Product Object Rules
- First classify the request as `product-base-consolidation`, `baseline-consolidation`, `new-feature`, `feature-increment`, `bugfix`, `refactor`, `experiment`, or `scope-change`.
- A feature is a long-lived APP capability. Do not use MVP, P0, P0.1, P0.2, Now, Next, or Later as a feature slug.
- Stage goals belong in `docs/product/stages/<stage-id>.md`; they do not replace feature requirements.
- Increment requirements belong in `docs/product/increments/<increment-id>/requirements.md` and must reference the active stage and primary feature.
- Accepted stable requirements belong in `docs/product/base/requirements.md`; baseline snapshots must not be edited as the living requirement source.
- Feature requirements belong in `docs/product/features/<feature-slug>/requirements.md` and must not include stage delivery plans, implementation plans, or acceptance evidence.
- If a request mixes feature, stage, increment, and baseline content, split it before writing requirements.

## Process
1. List assumptions before conclusions.
2. Classify the product object and source mode before choosing an output path.
3. Restate the functional goal in one sentence.
4. Identify user path, entry point, data touched, and expected outcome.
5. Convert expectations into measurable success criteria.
6. Mark out-of-stage ideas as backlog unless the user explicitly includes them through a change request.
7. State whether the output is Product Base consolidation, baseline snapshot consolidation, stable feature requirements, or increment requirements.
8. Request clarification only when a risky decision cannot be inferred.

## Red Flags
- The requirement contains words like smart, seamless, complete, or advanced without measurable behavior.
- The proposed feature adds unrelated screens or data models.
- Acceptance criteria describe implementation details instead of observable behavior.
- The output omits non-goals.
- Requirements attempt to mark 100% coverage complete before acceptance criteria and the traceability matrix exist.
- P0/new-feature requirements bypass feature spec and go straight to implementation.
- A stage name or roadmap horizon is used as a feature slug.
- Baseline facts are rewritten as future requirements without a Product Manager decision.

## Verification
- Every success criterion can become at least one test.
- Every user story has a user, action, and outcome.
- Assumptions are separate from confirmed requirements.
- Scope additions are recorded as backlog or change request.
- P0/new-feature requirements are ready for feature spec generation, not treated as final acceptance coverage.
- Current MVP reverse-consolidation requirements explicitly cite the code-baseline mode.
- Output path matches the classified product object and does not mix feature, stage, increment, or baseline boundaries.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
