---
name: code-review-quality
description: Use when code, docs, or workflow changes need a quality review focused on regressions, missing tests, maintainability, and release risk. Do not use as a substitute for running tests.
---

# Code Review Quality

## Overview
Provide a review gate that finds concrete defects and quality risks before a change is accepted.

## When to Use
- A development increment is ready for review.
- A broad refactor or generated change touches multiple areas.
- The user asks for review or quality assessment.

## When NOT to Use
- The request is only to format code.
- The change has not been implemented yet.
- The user wants product requirement clarification instead of review.

## Inputs
- Changed files and diffs.
- Owning Product Base or increment acceptance, traceability, and architecture contracts.
- Test results and implementation report.

## Outputs
- Findings ordered by severity with file references.
- Open questions and residual risk.
- Short approval or blocker summary.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 代码审查结果默认在最终回复中给出。
- 用户要求持久化或 release 需要留痕时，写入 `docs/reports/quality_report.md`。
- 输入优先读取变更 diff、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`、`docs/product/increments/<increment-id>/acceptance.md`、`docs/product/increments/<increment-id>/traceability.md`、架构契约、测试结果和 `docs/reports/implementation_report.md`。
- 不直接修改产品需求或契约文档；发现缺口时列为阻塞项或后续动作。

## Process
1. Inspect behavior changes before style issues.
2. Compare implementation to acceptance criteria and contracts.
3. Check error handling, compatibility, and data ownership.
4. Check whether tests prove the changed behavior.
5. Check whether the implementation is the simplest readable shape that proves the behavior without speculative abstraction.
6. Flag generated or repetitive changes that violate local standards.
7. Keep findings actionable with exact file references.

## Implementation Quality Checklist
- Does the change use a small verifiable vertical slice before expanding shared behavior or cross-module surface area?
- Is each new abstraction justified by real duplication, provider isolation, contract boundaries, or an established local pattern?
- Are data ownership, lifecycle states, and invariants explicit rather than inferred from UI state, logs, or fallback behavior?
- Are errors typed and contract-aligned instead of swallowed, logged only, or converted into silent defaults?
- Do tests prove user or system behavior at the right layer rather than only asserting mock calls or implementation details?
- Are generated artifacts, DTO semantics, and API client/server boundaries kept aligned with the owning contract?
- For frontend changes, does UI render backend or adapter facts without recomputing backend-owned truth?
- For backend/provider changes, is there a deterministic test path plus explicit external evidence for live-provider or release claims?

## Red Flags
- Review comments focus on preference while missing behavior risk.
- No test gap analysis is included.
- Cross-module changes lack contract or migration review.
- The review approves unverifiable AI behavior.
- A broad abstraction is introduced before there are at least two real call sites or a clear contract/provider boundary.
- The implementation relies on hidden state, broad fallback behavior, or logs to compensate for unclear control flow.
- UI code recomputes subscription, quota, training, payment, or final learning state that should be backend-owned.

## Verification
- Findings include severity and precise location.
- No issue is reported without a plausible user or maintenance impact.
- Test gaps are clearly separated from defects.
- The review result can drive a fix list.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
