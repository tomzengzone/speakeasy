---
name: test-case-generate
description: Use when acceptance criteria or bug fixes need concrete unit, integration, E2E, or AI eval test cases. Do not use when tests already cover the changed behavior and only need to be run.
---

# Test Case Generate

## Overview
Turn acceptance criteria into a balanced, executable test plan before or during implementation.

## When to Use
- A Product Base or increment spec has acceptance criteria and is ready for implementation or QA planning.
- A bug fix needs a regression test.
- A change affects API, UI, data, or AI output contracts.

## When NOT to Use
- The user asks only to run existing tests.
- The change is documentation-only.
- The implementation is a discarded spike.

## Inputs
- Increment acceptance criteria and increment spec for new product work.
- Increment definition, WP ID, and owning Traceability Row ID for delivery/evidence context.
- Product Base acceptance/spec/traceability when validating accepted stable behavior.
- Approved V2 Capability classification from `docs/product/feature_registry.md` only to verify the owning increment's boundary context; it is not a test behavior input.
- API contract, screen spec, or prompt contract.
- Existing test conventions.

## Outputs
- Test cases by layer with fixtures and expected assertions.
- Regression tests for bug fixes.
- Coverage gaps and manual verification notes.
- Test Evidence updates or findings for the owning Product Base or increment traceability matrix.
- Traceability note to the owning increment and its approved V2 Primary Capability and complete Affected Capability list, or its approved no-Primary classification, reason, and complete Affected Capability list.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 增量测试用例库写入 `docs/product/increments/<increment-id>/test_cases.md`，并引用 owning AC 文件。
- 测试用例 ID 使用稳定格式 `TC-<scope-prefix>-<NNN>`；MVP 后端使用 `TC-MVP-BE-001`、`TC-MVP-BE-002` 递增，不得重排、复用或把已发布 ID 改给其他用例。
- 测试执行结果和测试报告写入 `docs/reports/test_report.md`。
- Product Base 测试证据必须能对应到 `docs/product/base/traceability.md` 中的 AC；increment 测试证据必须能对应到 `docs/product/increments/<increment-id>/traceability.md` 中的 AC。
- 写回 Test Evidence 时必须包含 TC ID、测试脚本路径、执行命令、结果状态和证据报告；没有执行证据时只能写明确例外或缺口。
- 缺测试时只能标记为“人工验收”、“外部服务依赖”或“暂不可自动化”，不能留空。
- 实际 Flutter/Dart 测试写入 `test/`。
- 后端 Maven/Spring Boot 测试写入 `backend/src/test/java/`。
- 跨服务或仓库级测试写入 `tests/`；后端专属跨项目测试可写入 `tests/backend/`。
- AI eval 用例写入 `docs/ai_runtime/ai_eval_cases.md`，AI schema 测试代码写入项目约定的测试目录。
- 输入优先读取 `docs/product/base/acceptance.md` 或 `docs/product/increments/<increment-id>/acceptance.md`，并结合相关 Product Base / increment spec、API 契约、screen spec 和 prompt contract。
- 测试阶段只验证和补充 Test Evidence；不得重新定义 FR、AC 或需求覆盖关系。缺少强制追溯矩阵时，回到 `acceptance-criteria-generate` 或 `document-traceability-check`。

## Product Object Rules
- For new product work, start from `docs/product/increments/<increment-id>/acceptance.md` and `docs/product/increments/<increment-id>/spec.md`.
- For accepted stable behavior, start from `docs/product/base/acceptance.md`, `docs/product/base/spec.md`, and `docs/product/base/traceability.md`.
- Test plans validate existing ACs; they must not invent requirements or expand stage scope.
- For committed increment implementation, AC-to-TC mapping is a pre-implementation gate; do not route implementation while approved ACs lack stable TC IDs or explicit allowed exceptions.
- Test case IDs are assigned in the owning increment test case library and remain stable for the lifetime of that increment; retired IDs are kept with status `retired` and replacement or retirement reason.
- Increment-specific test evidence belongs with the increment traceability record.
- Product Base test evidence belongs in `docs/product/base/traceability.md` or `docs/reports/test_report.md`.
- QA may update traceability Test Evidence after execution; traceability check may review the same evidence chain before completion.
- If increment AC is missing, return to `acceptance-criteria-generate` before generating tests.
- This skill preserves the owning increment's approved classification and must not declare or modify it. Missing or conflicting classification blocks this downstream work and routes to Product Manager to correct the owning Product Base or increment artifact. Invoke `capability-registry-develop` only when Product Manager determines that canonical registry facts must change.

## Required Test Case Fields
Every test case must include these fields and must not leave them blank:

- `TC ID`
- `Traceability Row ID`
- `Increment ID`
- `WP ID`
- `Spec ID`
- `AC ID`
- `测试层级`
- `自动化状态`
- `测试脚本路径`
- `执行命令`
- `结果状态`
- `证据报告`
- `Gap / Exception`

Use `N/A - <原因>` only when a field is genuinely not applicable. `测试层级` must be one of `unit`, `integration`, `contract`, `widget`, `e2e`, `ai-eval`, `release-check`, or `manual`. `自动化状态` must be one of `automated`, `manual-verification`, `external-dependency`, `not-automatable-yet`, or `planned`. `结果状态` must be one of `planned`, `implemented`, `passed`, `failed`, `blocked`, `skipped`, or `retired`.

## Process
1. Confirm acceptance criteria and the traceability matrix exist when requirement coverage is in scope.
2. Map each acceptance criterion to at least one test, or to a documented exception: 人工验收, 外部服务依赖, or 暂不可自动化.
3. Record the AC-to-TC gate result in the owning increment test case library before implementation routing.
4. Apply Red-Green-Refactor for new behavior when practical.
5. Prefer the lowest-cost test that proves the behavior.
6. Use integration or E2E tests for cross-boundary workflows.
7. Add regression tests for any fixed bug.
8. Keep test data explicit and reusable.
9. Record uncovered ACs in `docs/reports/test_report.md`; do not mark the feature complete or implementation-ready.

## Red Flags
- Only snapshot or happy-path tests are proposed.
- Tests rely on live third-party services without mocks or fixtures.
- A bug fix changes code without a failing test first.
- E2E tests duplicate what unit tests can prove.
- Test generation is used to invent or change FR/AC coverage instead of validating existing ACs.
- Implementation starts before approved ACs are mapped to stable TC IDs or explicit allowed exceptions.
- A traceability matrix has empty Test Evidence with no explicit exception.
- Tests are generated from roadmap or stage text instead of approved increment AC.

## Verification
- Every criterion is covered or explicitly deferred with reason.
- Implementation-readiness is blocked unless every approved AC maps to stable TC IDs or explicit allowed exceptions.
- The test pyramid remains balanced.
- Failures would point to the responsible module.
- AI schema tests validate both valid and invalid outputs.
- Test Evidence for each AC is present in tests, `docs/reports/test_report.md`, or the traceability matrix.
- Every test case includes Traceability Row ID, Increment ID, WP ID, Spec ID, AC ID, test layer, automation status, script path, command, result status, evidence report, and Gap / Exception.
- "100% coverage" means requirement coverage completeness, not 100% code line coverage or zero production defects.
- Test evidence maps back to the Product Base or owning increment artifact and preserves its approved V2 Capability classification.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
