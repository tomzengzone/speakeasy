---
name: screen-spec-generate
description: Use when a Flutter or mobile UI screen needs behavior, state, interaction, and API dependencies specified before coding. Do not use for trivial copy-only edits.
---

# Screen Spec Generate

## Overview
Make UI work predictable by defining user goals, components, states, and acceptance checks before page implementation.

## When to Use
- A new screen or major screen state is needed.
- A page consumes new API or AI runtime output.
- UX review needs a concrete screen contract.

## When NOT to Use
- Only a text label, icon, or spacing value changes.
- There is no user-facing UI behavior.
- A design source of truth already fully specifies the change.

## Inputs
- Increment spec, API contract, and UX guidelines for new product work.
- Feature spec only for legacy flat feature artifacts or stable feature contract work.
- Current app navigation and state-management conventions.
- Acceptance criteria.

## Outputs
- Screen goal, entry points, components, states, and actions.
- Loading, empty, error, and success state behavior.
- API dependencies and test checklist.
- Traceability note to the owning increment or stable feature.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 页面规格写入 `docs/ux/screen_spec.md`。
- 用户流程写入 `docs/ux/user_flow.md`。
- 可用性检查项写入 `docs/ux/usability_checklist.md`。
- 文案规则写入 `docs/ux/copywriting_guideline.md`。
- 输入优先读取 `docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/increments/<increment-id>/spec.md`、`docs/product/increments/<increment-id>/acceptance.md`、`docs/architecture/api_contract.md` 和 `docs/ai_runtime/llm_output_schema.md`；`docs/product/acceptance_criteria.md` 仅作显式 legacy compatibility、migration 或 audit 输入。

## Product Object Rules
- For new product work, start from `docs/product/increments/<increment-id>/spec.md` and `docs/product/increments/<increment-id>/acceptance.md`.
- Do not create screen scope from a stage goal, roadmap item, or feature registry entry alone.
- Screen specs must list the owning increment, primary feature, affected features, and upstream API/AI contracts.
- If upstream API or AI output schema is missing, block screen spec completion and return to the required contract skill.

## Process
1. Start with the user's next action on the screen.
2. List stable components and the data each consumes.
3. Define state names and transitions.
4. Specify edge cases including offline, empty, duplicate, and retry states.
5. Keep copy short and supportive for learning workflows.
6. Map screen states to widget or integration tests.

## Red Flags
- The screen has no empty or error state.
- The UI depends on free-form AI text instead of schema fields.
- A component owns data outside its boundary.
- The spec requires more screens than the feature needs.
- Screen scope is added without an owning increment or approved upstream contract.

## Verification
- A developer can implement the page without inventing states.
- Every user action has visible feedback.
- The screen can handle API failure and slow responses.
- Acceptance criteria cover the primary mobile workflow.
- The screen spec maps back to the increment or stable feature artifact that required it.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
