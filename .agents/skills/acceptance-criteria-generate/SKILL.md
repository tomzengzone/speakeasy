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
- An accepted change request has an approved Product Base or increment spec and must be evaluated for done-ness.

## When NOT to Use
- The task is a design exploration with no committed feature.
- The work is purely internal refactoring with separate technical tests.
- The existing criteria are already specific and current.

## Inputs
- Approved increment spec for new product work.
- Approved Spec IDs as direct upstream and related FR IDs for coverage context.
- Product Base spec in `docs/product/base/spec.md` when consolidating or updating accepted stable product behavior.
- Stable feature metadata from `docs/product/feature_registry.md` when needed for product capability boundary context.
- Story/Slice, Stage, Capability, or change request only as scope/provenance context, not parallel AC behavior inputs.
- Product constraints and non-goals.
- Known platform limitations.
- Current MVP code-baseline evidence only when the task explicitly asks to reverse-freeze existing implemented behavior.

## Outputs
- Numbered acceptance criteria.
- Increment acceptance criteria in `docs/product/increments/<increment-id>/acceptance.md` for new product work.
- Product Base acceptance criteria in `docs/product/base/acceptance.md` for accepted stable product behavior.
- Product Base traceability in `docs/product/base/traceability.md` for accepted stable product behavior.
- Negative and edge-case criteria where relevant.
- Traceability notes to tests and docs.
- Owning traceability matrix update for the complete Story/Slice-to-evidence join; AC artifacts themselves keep only approved Spec and applicable FR references.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- Product Base 验收标准写入 `docs/product/base/acceptance.md`。
- 新增 increment 验收标准写入 `docs/product/increments/<increment-id>/acceptance.md`。
- Product Base 强制追溯矩阵写入或更新 `docs/product/base/traceability.md`；increment 追溯矩阵写入或更新 `docs/product/increments/<increment-id>/traceability.md`。
- 当前 MVP 代码基线固化时，验收标准可以基于 `docs/product/base/requirements.md`、`docs/product/user_stories.md` 和实际前端代码证据。
- 后续 AC 必须以已批准的 increment/Product Base spec 为直接输入；完整 Story/Slice 回连通过 owning traceability matrix，不作为 AC 的并列输入。
- 输入优先读取已批准的 Product Base 或 increment spec；MVP 反向固化任务才读取需求、scope、user stories 和代码证据作为并列来源。
- 测试映射只记录计划；稳定 TC ID 和实际测试用例库由 `test-case-generate` 写入 `docs/product/increments/<increment-id>/test_cases.md`，并在实现前补齐 AC-to-TC gate。

## Product Object Rules
- For new product work, generate AC from `docs/product/increments/<increment-id>/spec.md`.
- For accepted stable product behavior, generate or update AC from `docs/product/base/spec.md` and write to `docs/product/base/acceptance.md`.
- Output new increment AC to `docs/product/increments/<increment-id>/acceptance.md`.
- Update `docs/product/base/traceability.md` for Product Base traceability.
- Update `docs/product/increments/<increment-id>/traceability.md` for increment traceability.
- Do not generate AC directly from a stage goal, feature registry entry, user story, or baseline note unless this is explicitly a `product-base-consolidation` or `baseline-consolidation` task.
- Do not generate increment AC when the approved Spec direct-upstream reference is missing.
- Do not use stage names, priority windows, or increment ids as feature slugs.
- If the approved increment spec is missing, block AC generation and return the missing upstream artifact.

## Process
1. Determine the source mode: Product Base consolidation, baseline snapshot consolidation, or new increment workflow.
2. For new increment workflow, reject AC generation until an approved increment spec exists.
3. Write criteria from the user's observable perspective.
4. Cover success, failure, empty, loading, permission, and duplicate states as applicable.
5. Avoid implementation-specific phrasing unless validating a contract or reverse-freezing current MVP code evidence.
6. Group criteria by workflow step.
7. Build or update the owning traceability matrix so each AC joins back to Spec, FR, Story/Slice and delivery scope; do not duplicate that complete chain inside the AC artifact.
8. Reserve Test Case ID and Test Evidence status for each AC; before implementation, `test-case-generate` must replace pending TC status with stable TC IDs or a clear exception: 人工验收, 外部服务依赖, or 暂不可自动化.
9. Require each AC to have Code Evidence and Test Evidence, or a clear exception, before completion.
10. Mark any untestable criterion as a requirement issue.

## Red Flags
- Criteria use vague adjectives without thresholds.
- Criteria cannot be verified locally or through a test.
- Only the happy path is covered.
- Criteria conflict with MVP scope.
- P0 or new-feature criteria are generated from user stories alone while an approved Product Base or increment spec is missing.
- Traceability matrix fields for FR, AC, Test Case ID, Code Evidence, or Test Evidence are empty without a pending status or explicit exception.
- A test plan is treated as the source of requirement coverage rather than downstream evidence.
- Criteria are generated from stage scope or roadmap text instead of an approved increment spec.
- The output path mixes Product Base acceptance content with increment-specific pass/fail criteria.
- The AC artifact repeats the complete Story/Slice/FR/Spec chain as parallel required inputs.
- 100% traceability is claimed outside the owning traceability matrix.

## Verification
- Each criterion is binary enough to pass or fail.
- At least one criterion checks error handling when the feature can fail.
- The list does not require hidden implementation knowledge.
- QA can generate tests directly from the list.
- The owning traceability file, either `docs/product/base/traceability.md` or `docs/product/increments/<increment-id>/traceability.md`, contains `FR -> User Story -> AC -> Test Case ID -> Code Evidence -> Test Evidence -> Status` or the increment-equivalent chain.
- Every FR has at least one AC, and every AC reverse-references one or more FRs.
- Every AC has stable TC mapping before implementation, then implementation evidence and test evidence before completion, or a documented exception.
- "100% coverage" is defined as requirement coverage completeness, not 100% code line coverage or zero production defects.
- For new product work, the acceptance document cites approved Spec as direct upstream; the owning traceability matrix provides the complete cross-level join.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
