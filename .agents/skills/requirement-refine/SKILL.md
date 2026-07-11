---
name: requirement-refine
description: Use when a user idea, feature request, or change request must be turned into scoped, testable product requirements. Do not use when implementation is already specified and only coding is needed.
---

# Requirement Refine

## Overview
Turn natural-language product intent into constrained, testable requirements before design or code begins. For broad product modules, requirement development must internally run in two steps: first decompose the module into stable first-level subfunctions with product-level functional requirement boundaries, then develop atomic requirement items under each subfunction.

## When to Use
- A new feature request is ambiguous or broad.
- A change may expand MVP scope.
- An approved User Story / Vertical Slice needs scoped FRs, non-goals, and success criteria.
- A broad module needs to be decomposed into first-level subfunctions before detailed requirement items are written.

## When NOT to Use
- The task is only a mechanical code edit with clear acceptance criteria.
- A bug has exact reproduction steps and expected behavior.
- The user explicitly asks to skip documentation for an emergency fix.

## Inputs
- User request or change request.
- Broad module name, expected V2 `Capability ID` / `Sub-capability ID`, or affected stable capability when available.
- Existing product docs under docs/product/.
- Product object classification from Product Manager: feature, stage, increment, baseline, change request, or artifact.
- `docs/product/base/requirements.md` when consolidating or updating accepted stable product requirements.
- For new product work, the V2 feature capability registry, active stage, and increment definition when available.
- Approved User Story IDs and Vertical Slice IDs from `docs/product/story_map.md` as direct behavior upstream.
- For committed stage work, Stage Scope Item IDs and `Covered Stage Scope Items` only as delivery scope guards.
- Known constraints, target users, and MVP boundary.

## Outputs
- Product object classification and path decision.
- Product Base / increment requirement notes derived from approved Story/Slice.
- Product Base requirements in `docs/product/base/requirements.md` for accepted stable product behavior.
- Increment requirements in `docs/product/increments/<increment-id>/requirements.md` for stage-bound delivery slices.
- Requirement IDs that cite direct-upstream User Story ID and Vertical Slice ID for new increment work.
- Upstream V2 `Capability ID` / `Sub-capability ID` references for new or modified Product Base / increment requirements.
- Requirement documents organized by module functional boundary and first-level subfunction sections when the request covers a broad module.
- Each first-level subfunction includes a product-level functional requirement boundary and an atomic requirement item table using only `需求ID`, `需求项`, and `需求描述`.
- Traceability references are kept outside the main requirement item table.
- Baseline references in `docs/product/baselines/<baseline-slug>.md` only when consolidating implemented behavior.
- Testable success criteria.
- Explicit non-goals and assumptions.
- Direct-upstream references that can feed specs; complete cross-level mapping remains in owning `traceability.md`.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 产品级定位和边界写入 `docs/product/vision.md`。
- Approved Story/Slice 读取 `docs/product/story_map.md`；本 skill 不创建或改写 Story/Slice。
- 已接受的稳定产品需求写入 `docs/product/base/requirements.md`；阶段交付切片需求写入 `docs/product/increments/<increment-id>/requirements.md`。
- 范围扩展、跨模块影响或 MVP 变更写入 `docs/process/change_request.md`。
- 延期项或非 MVP 能力通过 `docs/process/change_request.md` 记录范围变更，或在 owning Product Base / increment requirements 中标记为后续延展。
- 当前 MVP 代码基线固化时，需求可以结合实际代码证据反向收敛；P0 或新增功能必须先形成 Product Base 或 increment requirements，再进入 downstream spec，之后由 acceptance criteria 建立强制追溯矩阵。

## Product Object Rules
- First classify the request as `product-base-consolidation`, `baseline-consolidation`, `new-feature`, `feature-increment`, `bugfix`, `refactor`, `experiment`, or `scope-change`.
- A capability is a long-lived APP product classification registered in `docs/product/feature_registry.md` with V2 `Capability ID`, `Capability slug`, boundary, owner, first-level `Sub-capability ID`, adjacent capabilities, downstream prefix, and `Legacy Mapping`. Do not assign a feature document directory, and do not use MVP, P0, P0.1, P0.2, Now, Next, or Later as a `Capability slug` or `Capability ID`.
- Stage goals belong in `docs/product/stages/<stage-id>.md`; they do not replace Product Base or increment requirements.
- Stage / increment is the delivery structure; V2 capability / sub-capability is the stable product classification.
- Increment requirements belong in `docs/product/increments/<increment-id>/requirements.md` and use approved User Story / Vertical Slice as direct upstream; stage, increment, and capability are scope guards.
- Accepted stable requirements belong in `docs/product/base/requirements.md`; baseline snapshots must not be edited as the living requirement source.
- Legacy V1 slug is only for mapping historical material through `Legacy Mapping`; it must not be used as a new requirement ID, module title, or active upstream feature identifier.
- Do not generate new increment requirements when approved Story/Slice product semantics are missing; do not invent behavior from Stage Scope or Capability Registry.
- Each new increment requirement ID must trace directly to at least one User Story ID and Vertical Slice ID, or explicitly mark a Product Manager-approved change request exception.
- If a request mixes feature, stage, increment, and baseline content, split it before writing requirements.
- The two-step decomposition process is an execution method, not document content; final requirements documents must not expose process headings such as `Step 1` or `Step 2`.

## Process
1. List assumptions before conclusions.
2. Classify the product object and source mode before choosing an output path.
3. For new increment work, list approved User Story IDs and Vertical Slice IDs before drafting requirements; record Stage/Increment only as scope guards.
4. Identify the broad module or stable capability being refined; if the request spans multiple modules, split it before writing committed requirements.
5. Decompose the broad module into stable first-level subfunctions before drafting detailed requirement items.
6. For each first-level subfunction, define its product-level functional requirement boundary: owned observable product capability, excluded adjacent capability, entry or precondition, resulting product outcome, and handoff to adjacent subfunctions.
7. Check subfunctions for overlap, missing coverage, and cross-module leakage; route unresolved scope decisions back to Product Manager or change request handling.
8. Under each accepted first-level subfunction, draft atomic requirement items using only `需求ID`, `需求项`, and `需求描述`.
9. Keep the full Story/Slice/FR/Spec/AC/TC/evidence join in the owning traceability matrix, not in the main requirement item table.
10. Convert expectations into measurable success criteria and downstream handoff notes without writing acceptance criteria.
11. Mark out-of-stage ideas as backlog unless the user explicitly includes them through a change request.
12. State whether the output is Product Base consolidation, baseline snapshot consolidation, Product Base requirements, or increment requirements.
13. Request clarification only when a risky decision cannot be inferred.

## Red Flags
- The requirement contains words like smart, seamless, complete, or advanced without measurable behavior.
- The proposed feature adds unrelated screens or data models.
- Acceptance criteria describe implementation details instead of observable behavior.
- The output omits non-goals.
- Requirements attempt to mark 100% coverage complete before acceptance criteria and the traceability matrix exist.
- P0/new-feature requirements bypass downstream spec and go straight to implementation.
- A stage name, MVP label, P0.1 label, Now/Next/Later horizon, or legacy V1 slug is used as a `Capability slug`, `Capability ID`, new requirement ID, or module title.
- Baseline facts are rewritten as future requirements without a Product Manager decision.
- Increment requirements are created from stage, roadmap, or capability prose without approved Story/Slice semantics.
- Requirement IDs cannot be traced directly to approved User Story / Vertical Slice or an approved change request.
- A broad module is represented by only a few large FR rows instead of first-level subfunctions and atomic requirement items.
- First-level subfunctions lack product-level functional requirement boundaries.
- A subfunction boundary describes API, database, UI, or implementation ownership instead of product capability ownership.
- One requirement item combines multiple independent behaviors such as account creation, login admission, token refresh, profile management, and risk control.
- The main requirement item table contains traceability, spec, AC, API, database, UI, or test fields.
- Final requirements documents expose the internal decomposition process through `Step 1` or `Step 2` headings.

## Verification
- Every success criterion can become at least one test.
- Every user story has a user, action, and outcome.
- Assumptions are separate from confirmed requirements.
- Scope additions are recorded as backlog or change request.
- P0/new-feature requirements are ready for downstream spec generation, not treated as final acceptance coverage.
- Current MVP reverse-consolidation requirements explicitly cite the code-baseline mode.
- Output path matches the classified product object and does not mix feature, stage, increment, or baseline boundaries.
- Output references V2 `Capability ID` / `Sub-capability ID` for Product Base or increment requirements when a product capability is in scope.
- For new increment work, every requirement ID cites at least one User Story ID and Vertical Slice ID.
- Broad-module requirements include stable first-level subfunctions before detailed requirement items.
- Every first-level subfunction has a product-level functional requirement boundary.
- Every detailed requirement item belongs to exactly one first-level subfunction.
- Main requirement item tables use only `需求ID`, `需求项`, and `需求描述`.
- Complete cross-level traceability exists separately in the owning `traceability.md`; requirement rows do not duplicate downstream Spec/AC/TC fields.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
