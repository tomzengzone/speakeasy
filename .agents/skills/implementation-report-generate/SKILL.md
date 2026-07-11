---
name: implementation-report-generate
description: Use when a development increment finishes and docs/reports/implementation_report.md must record scope, files, tests, risks, and follow-ups. Do not use before implementation or validation results are known.
---

# Implementation Report Generate

## Overview
Create an auditable record that connects the completed change to requirements, tests, and residual risk.

## When to Use
- Product behavior, workflow, or process assets have been added or changed.
- The user asks what changed and how it was verified.
- A sprint increment needs traceability.

## When NOT to Use
- No files were changed.
- The work is still exploratory and not ready to report.
- A release note is needed instead of an implementation report.

## Inputs
- Git status and changed file list.
- Increment reference for new product work.
- Product Base or increment requirement/spec reference.
- Commands run and results.
- Known risks and follow-up items.

## Outputs
- Updated docs/reports/implementation_report.md.
- Summary, requirement mapping, files changed, validation, risks, and follow-ups.
- Clear note when tests were not run.
- Traceability note to the owning increment and its approved V2 Capability classification, or to the governing process artifact.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 实现报告写入 `docs/reports/implementation_report.md`。
- 输入优先读取本次 Product Base / increment requirement 或 spec、`git status`、变更文件清单、实际运行命令和结果。
- 测试结果摘要可引用 `docs/reports/test_report.md`，质量风险可引用 `docs/reports/quality_report.md`。
- 不在实现报告中替代需求、契约或验收标准；缺失时回到对应 workflow 阶段补文档。

## Product Object Rules
- For new product work, copy the owning increment's active stage, approved Primary Capability, and Affected Capabilities before reporting completion. If it has an approved no-Primary classification, preserve its reason and complete Affected Capability list.
- This skill must not declare or modify Capability classification. Missing or conflicting classification is reported as a governance gap and routed to Product Manager to correct the owning Product Base or increment artifact. Invoke `capability-registry-develop` only when Product Manager determines that canonical registry facts must change.
- Reports summarize implementation evidence; they must not redefine requirements, specs, acceptance criteria, or stage scope.
- If no increment/spec/AC reference exists for product work, report the governance gap instead of claiming completion.
- Documentation-only governance work may report against the process artifact and change/check agent handoff instead of a product increment.

## Process
1. Identify the requirement, increment, or user request addressed.
2. List changed files by purpose, not as a raw dump.
3. Record validation commands with pass/fail status.
4. Call out unrun tests and why.
5. Record residual risks and next steps.
6. Keep the report append-only unless correcting the current entry.

## Red Flags
- The report claims done without test or validation evidence.
- The report omits generated docs or process files.
- Risks are hidden in vague wording.
- The report is written before final validation.
- Product work is reported as done without an owning increment or acceptance evidence.

## Verification
- Every meaningful changed area is represented.
- Validation commands match what was actually run.
- Skipped tests are explicit.
- The entry can support later audit or rollback planning.
- The report maps changed files and validation back to the owning increment or process governance artifact.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
