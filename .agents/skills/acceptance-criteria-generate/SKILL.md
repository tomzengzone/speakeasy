---
name: acceptance-criteria-generate
description: Use when product behavior needs pass/fail acceptance criteria before implementation or QA planning. Do not use when criteria already exist and only need execution.
---

# Acceptance Criteria Generate

## Overview
Convert requirements into behavior-oriented pass/fail checks that QA and implementation can trace.

## When to Use
- Current MVP Product Base consolidation needs acceptance criteria from implemented behavior, requirements, MVP scope, and user stories.
- An approved P0 or new-feature spec needs acceptance criteria or acceptance-to-test planning.
- An accepted change request has an approved feature spec and must be evaluated for done-ness.

## When NOT to Use
- The task is a design exploration with no committed feature.
- The work is purely internal refactoring with separate technical tests.
- The existing criteria are already specific and current.

## Inputs
- Approved increment spec for new product work.
- Covered Stage Scope Item IDs and increment requirements for new increment work.
- Product Base spec in `docs/product/base/spec.md` when consolidating or updating accepted stable product behavior.
- Approved feature spec only for legacy flat feature artifacts or stable feature contract work.
- User story or change request only as upstream context, not as the direct P0 AC source.
- Product constraints and non-goals.
- Known platform limitations.
- Current MVP code-baseline evidence only when the task explicitly asks to reverse-freeze existing implemented behavior.

## Outputs
- Numbered acceptance criteria.
- Increment acceptance criteria in `docs/product/increments/<increment-id>/acceptance.md` for new product work.
- Product Base acceptance criteria in `docs/product/base/acceptance.md` for accepted stable product behavior.
- Product Base traceability in `docs/product/base/traceability.md` for accepted stable product behavior.
- Legacy global acceptance index in `docs/product/acceptance_criteria.md` only for explicit migration, compatibility, or audit tasks; do not write it as the current acceptance source after Product Base exists.
- Negative and edge-case criteria where relevant.
- Traceability notes to tests and docs.
- Required traceability mapping for new increment work: `Stage Scope ID -> Increment ID -> FR -> Spec section/state -> AC -> Contract Evidence -> Code Evidence -> Test Evidence -> Release Evidence -> Status`.
- Required traceability mapping for accepted stable behavior: `FR -> User Story -> AC -> Code Evidence -> Test Evidence -> Status`.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- Product Base 验收标准写入 `docs/product/base/acceptance.md`。
- 新增 increment 验收标准写入 `docs/product/increments/<increment-id>/acceptance.md`。
- 功能级验收标准较大时，可写入 `docs/product/features/<feature-slug>-acceptance.md`；Product Base 建立后，只在显式 legacy compatibility/index 任务中更新 `docs/product/acceptance_criteria.md`。
- Product Base 强制追溯矩阵写入或更新 `docs/product/base/traceability.md`；increment 追溯矩阵写入或更新 `docs/product/increments/<increment-id>/traceability.md`。
- `docs/product/acceptance_criteria.md` 和 `docs/product/traceability_matrix.md` 是 legacy/global compatibility source；Product Base 建立后不得作为默认写回目标。
- 当前 MVP 代码基线固化时，验收标准可以基于 `docs/product/features/<feature-slug>-requirements.md`、`docs/product/mvp_scope.md`、`docs/product/user_stories.md` 和实际前端代码证据。
- 后续 P0 或新增功能进入标准 workflow 后，验收标准必须以已批准的 `docs/product/features/<feature-slug>-spec.md` 为直接输入，并反向追溯到需求文档、用户故事和范围边界。
- 输入优先读取已批准的 `docs/product/features/<feature-slug>-spec.md`；MVP 反向固化任务才读取需求、scope、user stories 和代码证据作为并列来源。
- 测试映射只记录计划；实际测试用例由 `test-case-generate` 写入测试代码或测试报告。

## Product Object Rules
- For new product work, generate AC from `docs/product/increments/<increment-id>/spec.md`.
- For accepted stable product behavior, generate or update AC from `docs/product/base/spec.md` and write to `docs/product/base/acceptance.md`.
- Output new increment AC to `docs/product/increments/<increment-id>/acceptance.md`.
- Update `docs/product/base/traceability.md` for Product Base traceability.
- Update `docs/product/increments/<increment-id>/traceability.md` for increment traceability; use global traceability only as an index or migration bridge.
- Do not generate AC directly from a stage goal, feature registry entry, user story, or baseline note unless this is explicitly a `product-base-consolidation` or `baseline-consolidation` task.
- Do not generate increment AC when the spec or requirements have dropped the covered Stage Scope Item IDs required by the increment definition.
- Do not use stage names, priority windows, or increment ids as feature slugs.
- If the approved increment spec is missing, block AC generation and return the missing upstream artifact.

## Process
1. Determine the source mode: Product Base consolidation, baseline snapshot consolidation, new increment workflow, or legacy flat feature workflow.
2. For new increment workflow, reject AC generation until an approved increment spec exists.
3. Write criteria from the user's observable perspective.
4. Cover success, failure, empty, loading, permission, and duplicate states as applicable.
5. Avoid implementation-specific phrasing unless validating a contract or reverse-freezing current MVP code evidence.
6. Group criteria by workflow step.
7. For new increment workflow, build or update the traceability matrix before implementation planning: every required Stage Scope Item ID is covered by at least one increment requirement or explicitly deferred/not applicable; every FR has at least one AC; every AC references one or more FRs and the upstream Stage Scope Item IDs.
8. Require each AC to have Code Evidence and Test Evidence, or a clear exception: 人工验收, 外部服务依赖, or 暂不可自动化.
9. Mark any untestable criterion as a requirement issue.

## Red Flags
- Criteria use vague adjectives without thresholds.
- Criteria cannot be verified locally or through a test.
- Only the happy path is covered.
- Criteria conflict with MVP scope.
- P0 or new-feature criteria are generated from user stories alone while an approved feature spec is missing.
- Traceability matrix fields for FR, AC, Code Evidence, or Test Evidence are empty.
- A test plan is treated as the source of requirement coverage rather than downstream evidence.
- Criteria are generated from stage scope or roadmap text instead of an approved increment spec.
- The output path mixes global acceptance index content with increment-specific pass/fail criteria.
- The traceability matrix lacks Stage Scope ID or Increment ID columns for new increment work.
- 100% traceability is claimed while required Stage Scope Item IDs are uncovered, unmapped to FRs, or only referenced in prose.

## Verification
- Each criterion is binary enough to pass or fail.
- At least one criterion checks error handling when the feature can fail.
- The list does not require hidden implementation knowledge.
- QA can generate tests directly from the list.
- The owning traceability file, either `docs/product/base/traceability.md` or `docs/product/increments/<increment-id>/traceability.md`, contains `FR -> User Story -> AC -> Code Evidence -> Test Evidence -> Status`.
- Every FR has at least one AC, and every AC reverse-references one or more FRs.
- Every AC has implementation evidence and test evidence, or a documented exception.
- "100% coverage" is defined as requirement coverage completeness, not 100% code line coverage or zero production defects.
- For new product work, the acceptance document lives under the increment directory and traces back to Stage Scope Item IDs, the increment definition, increment requirements, and the increment spec.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
