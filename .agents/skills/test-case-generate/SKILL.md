---
name: test-case-generate
description: Use when acceptance criteria or bug fixes need concrete unit, integration, E2E, or AI eval test cases. Do not use when tests already cover the changed behavior and only need to be run.
---

# Test Case Generate

## Overview
Turn acceptance criteria into a balanced, executable test plan before or during implementation.

## When to Use
- A feature spec has acceptance criteria and is ready for implementation or QA planning.
- A bug fix needs a regression test.
- A change affects API, UI, data, or AI output contracts.

## When NOT to Use
- The user asks only to run existing tests.
- The change is documentation-only.
- The implementation is a discarded spike.

## Inputs
- Increment acceptance criteria and increment spec for new product work.
- Product Base acceptance/spec/traceability when validating accepted stable behavior.
- Feature spec only for legacy flat feature artifacts or stable feature contract work.
- Legacy global traceability `docs/product/traceability_matrix.md` only when verifying existing flat artifacts or migration/audit compatibility after Product Base exists.
- API contract, screen spec, or prompt contract.
- Existing test conventions.

## Outputs
- Test cases by layer with fixtures and expected assertions.
- Regression tests for bug fixes.
- Coverage gaps and manual verification notes.
- Test Evidence updates or findings for the traceability matrix.
- Traceability note to the owning increment or stable feature.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 测试计划和测试映射写入 `docs/reports/test_report.md`，并引用 owning AC 文件。
- Product Base 测试证据必须能对应到 `docs/product/base/traceability.md` 中的 AC；increment 测试证据必须能对应到 `docs/product/increments/<increment-id>/traceability.md` 中的 AC。
- 缺测试时只能标记为“人工验收”、“外部服务依赖”或“暂不可自动化”，不能留空。
- 实际 Flutter/Dart 测试写入 `test/`。
- 后端或跨服务测试写入 `tests/`。
- AI eval 用例写入 `docs/ai_runtime/ai_eval_cases.md`，AI schema 测试代码写入项目约定的测试目录。
- 输入优先读取 `docs/product/base/acceptance.md` 或 `docs/product/increments/<increment-id>/acceptance.md`，并结合相关 feature spec、API 契约、screen spec 和 prompt contract。
- `docs/product/acceptance_criteria.md` 和 `docs/product/traceability_matrix.md` 是 legacy/global compatibility source；Product Base 建立后不得作为默认测试证据写回目标。
- 测试阶段只验证和补充 Test Evidence；不得重新定义 FR、AC 或需求覆盖关系。缺少强制追溯矩阵时，回到 `acceptance-criteria-generate` 或 `document-traceability-check`。

## Product Object Rules
- For new product work, start from `docs/product/increments/<increment-id>/acceptance.md` and `docs/product/increments/<increment-id>/spec.md`.
- For accepted stable behavior, start from `docs/product/base/acceptance.md`, `docs/product/base/spec.md`, and `docs/product/base/traceability.md`.
- Test plans validate existing ACs; they must not invent requirements or expand stage scope.
- Increment-specific test evidence belongs with the increment traceability record; global traceability is used only as an index or migration bridge.
- Product Base test evidence belongs in `docs/product/base/traceability.md` or `docs/reports/test_report.md`.
- If increment AC is missing, return to `acceptance-criteria-generate` before generating tests.

## Process
1. Confirm acceptance criteria and the traceability matrix exist when requirement coverage is in scope.
2. Map each acceptance criterion to at least one test, or to a documented exception: 人工验收, 外部服务依赖, or 暂不可自动化.
3. Apply Red-Green-Refactor for new behavior when practical.
4. Prefer the lowest-cost test that proves the behavior.
5. Use integration or E2E tests for cross-boundary workflows.
6. Add regression tests for any fixed bug.
7. Keep test data explicit and reusable.
8. Record uncovered ACs in `docs/reports/test_report.md`; do not mark the feature complete.

## Red Flags
- Only snapshot or happy-path tests are proposed.
- Tests rely on live third-party services without mocks or fixtures.
- A bug fix changes code without a failing test first.
- E2E tests duplicate what unit tests can prove.
- Test generation is used to invent or change FR/AC coverage instead of validating existing ACs.
- A traceability matrix has empty Test Evidence with no explicit exception.
- Tests are generated from roadmap or stage text instead of approved increment AC.

## Verification
- Every criterion is covered or explicitly deferred with reason.
- The test pyramid remains balanced.
- Failures would point to the responsible module.
- AI schema tests validate both valid and invalid outputs.
- Test Evidence for each AC is present in tests, `docs/reports/test_report.md`, or the traceability matrix.
- "100% coverage" means requirement coverage completeness, not 100% code line coverage or zero production defects.
- Test evidence maps back to the owning increment or stable feature artifact.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
