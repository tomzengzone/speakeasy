---
name: feature-spec-generate
description: Use when a feature needs an executable specification before architecture, UI, backend, or AI runtime work. Do not use when the requested change is smaller than a feature and already has clear tests.
---

# Feature Spec Generate

## Overview
Create an executable product specification that turns approved requirements into clear, traceable behavior contracts without becoming acceptance criteria, API schema, or implementation tasks.

## When to Use
- A new user-visible feature is starting.
- A change affects more than one module.
- A feature needs API, UI, data, or AI behavior coordinated.

## When NOT to Use
- A one-line copy or config change is requested.
- Only a bug regression test is needed.
- There is already an approved feature spec and no behavior change.

## Inputs
- Refined requirement or user story.
- Approved increment definition and increment requirements for new product work.
- Covered Stage Scope Item IDs from the active stage and increment definition for new product work.
- Product Base requirements in `docs/product/base/requirements.md` when consolidating or updating accepted stable product behavior.
- Stable feature requirement only when updating a long-lived feature contract.
- Relevant architecture and domain docs.
- Current MVP scope and Definition of Done.

## Outputs
- Product object, upstream sources, feature goal, behavior specifications, shared state/signal definitions, module impact, downstream contract needs, non-goals, and rollout notes.
- Increment spec in `docs/product/increments/<increment-id>/spec.md` for new stage-bound delivery work.
- Product Base spec in `docs/product/base/spec.md`, or a module spec in `docs/product/base/<module-slug>/spec.md` when the approved module requirements declare that path.
- Legacy feature spec in `docs/product/features/<feature-slug>-spec.md` only for existing flat artifacts until migration.
- Required downstream contract list for architecture, domain, API, AI runtime, UX, QA, and DevOps when applicable.
- Traceable spec item IDs that allow acceptance criteria to use the approved spec as direct upstream input.
- Preserved Stage Scope Item ID references for every increment spec section that refines committed stage scope.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 新增阶段交付写入 `docs/product/increments/<increment-id>/spec.md`。
- Product Base 稳定总库写入 `docs/product/base/spec.md`；Product Base 模块分库在上游 requirements 明确声明时写入 `docs/product/base/<module-slug>/spec.md`。
- Legacy flat feature artifacts 才写入 `docs/product/features/<feature-slug>-spec.md`。
- 后续 P0 或新增功能的验收标准必须以已批准 spec 为直接输入；spec 必须保留 requirement、scope boundary、non-goal 和必要 Stage Scope Item ID 的可追溯引用。
- 若规格影响架构、领域、API、AI runtime 或 UX，只记录影响范围；具体契约分别交由对应 skill 更新到 `docs/architecture/`、`docs/domain/`、`docs/ai_runtime/`、`docs/ux/`。
- 发现范围扩展时更新 `docs/process/change_request.md`，不要把变更决策埋进 feature spec。

## Product Object Rules
- For new product work, generate an increment spec at `docs/product/increments/<increment-id>/spec.md`.
- For accepted stable product behavior, update `docs/product/base/spec.md`; do not update a baseline snapshot as the living spec.
- Do not generate a feature spec named after a stage, priority window, roadmap horizon, MVP baseline, or increment id.
- The spec must cite its upstream increment definition, increment requirements, active stage, primary feature, and affected features.
- The spec must cite the `Covered Stage Scope Items` from the increment definition and preserve those IDs in relevant flows, states, dependencies, and non-goals.
- Stable feature contracts live under `docs/product/features/<feature-slug>/`; they describe long-lived capability boundaries and must not absorb stage delivery plans.
- If architecture, domain, API, AI runtime, or UX contracts are needed, record the required contract outputs but do not inline those contracts into the increment spec.
- If no approved increment definition exists, or if the increment definition lacks `Covered Stage Scope Items` for committed stage work, block spec generation and return the missing upstream artifact.

## Semantic Quality Source
- Apply the shared `文档语义质量模型` from `document-content-contract`: granularity, clarity, and coverage.
- For semantic review or uncertain decomposition, read `.agents/skills/document-content-contract/SKILL.md` and use that model as the source of truth.

## Requirement-to-Spec Decomposition
- A single-business-assertion requirement may map 1:1 to one spec item.
- A requirement with multiple independent business conclusions must map 1:N to multiple spec items.
- Do not split below business value into implementation tasks such as rendering a button, adding an endpoint, writing a table field, or naming a class/function.
- Use concise behavior statements, not fixed verbose cards. Prefer: `当 <触发条件/状态> 时，<用户或系统对象> 必须 <执行单一业务动作或规则>，并产生 <可观察结果/状态/错误>。`

## Spec Content Shape
- Start with product object, upstream inputs, goal/boundary, requirement-to-spec mapping, Specification, module impact, required downstream contracts, non-goals, acceptance coverage expectations, and rollout or merge-back notes.
- Under `Specification`, define shared states, inputs, outputs, errors, downgrade and security signals once when they are development inputs. Later spec items reference those IDs; do not scatter duplicate per-section reference tables.
- Functional sections and subsections should mirror the upstream requirement structure unless a Product Manager-approved scope change explains the difference.
- `Spec Items` should use stable spec IDs, upstream requirement IDs, status, and concise specification text. Ref IDs are spec language, not API schema, database fields, or code enums.

## Process
1. Start with assumptions and dependencies.
2. Confirm the product object and output path before drafting the spec.
3. For new increment work, list covered Stage Scope Item IDs and map each major flow/state to them.
4. Inventory upstream requirement IDs, user paths, success criteria, non-goals, and known target/proposed versus code-baseline status.
5. Decompose requirements into spec items using the shared semantic quality model; record 1:N splits when a requirement has multiple independent business conclusions.
6. Define shared states/signals once, then write concise spec items that reference them.
7. List impacted modules by ownership area and required downstream contracts without inlining those contracts.
8. Map spec items to expected acceptance coverage without replacing acceptance criteria.
9. Record risks that require ADR, change request, or semantic review.
10. State whether the spec is approved enough for `acceptance-criteria-generate` to use as direct upstream input.

## Red Flags
- The spec mixes unrelated features.
- The implementation plan is larger than a single verifiable increment.
- The spec has no failure, empty, or loading states.
- Tests are described as optional.
- The spec cannot be traced back to requirements, user stories, or scope boundaries.
- Acceptance criteria are generated for a P0/new feature before the feature spec is approved.
- The spec path uses a stage name or increment id as a stable feature slug.
- The spec includes full API, AI, UX, or domain contracts instead of requesting the correct downstream contract artifacts.
- The spec drops Stage Scope Item IDs and only references the stage or increment in prose.
- A spec section introduces behavior that is not covered by Stage Scope Item IDs, increment requirements, or an approved change request.
- Spec items mirror requirement IDs mechanically while preserving compound behavior that should be split.
- The document passes ID-count coverage but misses requirement intent, exception branches, permissions, security/privacy boundaries, or state transitions.
- Shared states, errors, and signals are duplicated across sections or defined but never referenced.

## Verification
- The feature can be accepted or rejected from the spec alone.
- Every module impact has an owner Agent.
- Every spec item maps to expected acceptance coverage or an explicit exception.
- Non-goals prevent obvious scope creep.
- The spec can serve as the direct upstream input for P0/new-feature acceptance criteria.
- The spec does not claim complete coverage from ID counts alone; semantic coverage must be checked before acceptance criteria generation.
- For new product work, the spec is tied to one increment definition and one increment requirements document.
- For new product work, every major flow/state cites a Stage Scope Item ID or an approved change request source.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
