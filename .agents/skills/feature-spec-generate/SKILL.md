---
name: feature-spec-generate
description: Use when a feature needs an executable specification before architecture, UI, backend, or AI runtime work. Do not use when the requested change is smaller than a feature and already has clear tests.
---

# Feature Spec Generate

## Overview
Create a feature-level contract that connects requirements, architecture impact, tests, and non-goals.

## When to Use
- A new user-visible feature is starting.
- A change affects more than one module.
- A feature needs API, UI, data, or AI behavior coordinated.

## When NOT to Use
- A one-line copy or config change is requested.
- Only a bug regression test is needed.
- There is already an approved feature spec and no behavior change.

## Inputs
- Approved refined FRs as the direct behavior upstream.
- Vertical Slice IDs only as scope guard / provenance.
- Approved increment definition and increment requirements for new product work.
- Stage Scope Item IDs only as delivery context, not spec behavior input.
- Product Base requirements in `docs/product/base/requirements.md` when consolidating or updating accepted stable product behavior.
- Active V2 Capability / Sub-capability classification from `docs/product/feature_registry.md` when ownership or boundary context is needed.
- Relevant architecture and domain docs.
- Current MVP scope and Definition of Done.

## Outputs
- Feature goal, user flow, inputs, outputs, states, and dependencies.
- Increment spec in `docs/product/increments/<increment-id>/spec.md` for new stage-bound delivery work.
- Product Base spec in `docs/product/base/spec.md` for accepted stable product behavior.
- API, data, UI, AI, and test impact sections.
- Non-goals and rollout notes.
- Traceable references that allow acceptance criteria to use the approved Product Base or increment spec as direct upstream input.
- Source FR references for every increment spec flow, state, and dependency; complete Story/Slice join stays in owning traceability.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 新阶段交付规格默认写入 `docs/product/increments/<increment-id>/spec.md`。
- 已接受稳定行为规格写入 `docs/product/base/spec.md`。
- 输入行为只读取已批准 increment/Product Base FR；必要时读取 `docs/product/story_map.md` 作为 Slice scope guard，并读取 Capability Registry / change request 作为 classification 和边界上下文。
- 后续 AC 必须以已批准 Product Base 或 increment spec 为直接输入；spec 保留 source FR、必要 Vertical Slice scope guard 和 `Traceability Row ID`，不重复完整链路。
- 若规格影响架构、领域、API、AI runtime 或 UX，只记录影响范围；具体契约分别交由对应 skill 更新到 `docs/architecture/`、`docs/domain/`、`docs/ai_runtime/`、`docs/ux/`。
- 发现范围扩展时更新 `docs/process/change_request.md`，不要把变更决策埋进 spec。

## Product Object Rules
- For new product work, generate an increment spec at `docs/product/increments/<increment-id>/spec.md`.
- For accepted stable product behavior, update `docs/product/base/spec.md`; do not update a baseline snapshot as the living spec.
- Do not use a stage, priority window, roadmap horizon, MVP baseline, or increment ID as stable Capability identity; an increment spec path remains a delivery artifact.
- The spec must cite approved FRs as direct upstream, plus increment definition and capability boundaries as scope context.
- Every relevant flow, state, and dependency must cite its source FR. Vertical Slice is scope guard / provenance only.
- Stable product classification lives in `docs/product/feature_registry.md` as active V2 Capability / Sub-capability identity, ownership and boundary context. Stage / Increment remain separate delivery structures, and registry classification must not become spec behavior input.
- If architecture, domain, API, AI runtime, or UX contracts are needed, record the required contract outputs but do not inline those contracts into the increment spec.
- If no approved FR exists, block spec generation and return the missing direct-upstream artifact.

## Process
1. Start with assumptions and dependencies.
2. Confirm the product object and output path before drafting the spec.
3. List approved FR IDs and map each major flow/state/dependency to its source FR; add Vertical Slice only as scope guard.
4. Define observable user success criteria before implementation details.
5. List impacted files or modules by ownership area.
6. Split work if the expected change touches more than five files.
7. Map each success criterion to expected acceptance coverage without replacing acceptance criteria.
8. Record risks that require ADR or change request.
9. State whether the spec is approved enough for `acceptance-criteria-generate` to use as direct upstream input.

## Red Flags
- The spec mixes unrelated features.
- The implementation plan is larger than a single verifiable increment.
- The spec has no failure, empty, or loading states.
- Tests are described as optional.
- The spec cannot be traced back to requirements, user stories, or scope boundaries.
- Acceptance criteria are generated for a P0/new feature before the feature spec is approved.
- The spec uses a stage name, roadmap horizon, baseline, or increment ID as stable Capability identity.
- The spec includes full API, AI, UX, or domain contracts instead of requesting the correct downstream contract artifacts.
- The spec treats Story/Slice, Stage, or Capability as parallel behavior inputs instead of using approved FRs.
- A spec section introduces behavior that is not covered by an approved FR or approved change request.

## Verification
- The feature can be accepted or rejected from the spec alone.
- Every module impact has an owner Agent.
- Every criterion maps to a QA item.
- Non-goals prevent obvious scope creep.
- The spec can serve as the direct upstream input for P0/new-feature acceptance criteria.
- The spec does not claim 100% requirement coverage; that is established in the acceptance-criteria traceability matrix.
- For new product work, the spec is tied to one increment definition and one increment requirements document.
- For new product work, every major flow/state/dependency cites an approved FR or an approved change request source.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
