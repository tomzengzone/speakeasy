---
name: document-governance
description: Use when a documentation request needs routing across path governance, content-contract governance, traceability checks, or multiple documentation governance concerns. Do not use for single-scope path decisions, single-document content boundary reviews, or one feature traceability audits when a more specific document governance skill applies.
---

# Document Governance

## Overview
作为文档治理总控，判断文档问题属于路径治理、内容契约治理、追踪检查，或需要多项治理协同。它不承载全部细节，而是负责路由、冲突处理和跨治理边界决策。

## When to Use
- 用户的问题同时涉及文档路径、内容边界和链路追踪。
- 不确定应该使用哪一个文档治理子 skill。
- 新增文档类别、文档治理规则或文档治理 skill。
- 发现路径治理、内容契约和追踪检查之间存在冲突。
- 需要给文档治理工作拆分任务、确认范围或制定执行顺序。

## When NOT to Use
- 只需要决定文档放在哪里、谁维护、引用谁；使用 `document-path-governance`。
- 只需要判断某类文档写什么、不写什么、怎么验收；使用 `document-content-contract`。
- 只需要检查需求到测试、报告、发布的链路是否完整；使用 `document-traceability-check`。
- 只需要生成具体业务文档；使用对应生成类 skill。

## Inputs
- 用户提出的文档治理问题。
- `docs/process/workflow.md`
- `docs/process/definition_of_done.md`
- `docs/process/skill_quality_standard.md`
- `.agents/skills/document-path-governance/SKILL.md`
- `.agents/skills/document-content-contract/SKILL.md`
- `.agents/skills/document-traceability-check/SKILL.md`
- 相关 `docs/`、`.agents/skills/` 或 `codex/agents/` 文件。

## Outputs
- 文档治理路由决策。
- 涉及多个治理面的任务拆分。
- 冲突处理建议。
- 必要时更新文档治理类 skill 或 `codex/agents/documentation_governance.md`。
- 用户要求持久化时，将治理决策写入 `docs/reports/quality_report.md`。

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 总控规则写入 `.agents/skills/document-governance/SKILL.md` 和 `.agents/skills/document-governance/SPEC.md`。
- 路径细则写入 `.agents/skills/document-path-governance/`。
- 内容契约细则写入 `.agents/skills/document-content-contract/`。
- 追踪检查细则写入 `.agents/skills/document-traceability-check/`。
- 文档治理 agent 规则写入 `codex/agents/documentation_governance.md`。
- 持久化审查记录写入 `docs/reports/quality_report.md`。

## Routing Rules
- 路径、owner、Allowed Paths、source of truth、路径模板：使用 `document-path-governance`。
- 文档目的、读者、必需章节、禁止内容、内容越界：使用 `document-content-contract`。
- 需求、规格、验收、契约、测试、报告、发布之间的断链：使用 `document-traceability-check`。
- 强制追溯矩阵相关问题按类型拆分：路径归属交给 `document-path-governance`，内容边界交给 `document-content-contract`，FR/AC/TC/Code Evidence/Test Evidence 完整性交给 `document-traceability-check`。
- 产品对象治理问题先确认对象类型：feature、stage、increment、baseline、change request 或 artifact；路径归属交给 `document-path-governance`，内容边界交给 `document-content-contract`，链路完整性交给 `document-traceability-check`。
- 当文档同时混用 feature 和 stage，或把 baseline 当作新功能 requirements 时，先阻断并拆成对象分类、路径决策、内容边界、追踪检查四步。
- 同时涉及多个治理面：先用本 skill 拆分，再按顺序调用子 skill。
- 新增治理规则：先判断影响哪个子 skill，再更新对应 skill，最后同步总控说明。

## Process
1. 复述用户要解决的文档治理问题。
2. 判断问题类型：路径治理、内容契约、追踪检查或混合问题。
3. 若是单一类型，路由到具体子 skill。
4. 若是混合问题，拆分任务顺序：通常先路径，再内容契约，最后追踪检查。
5. 如果多个子 skill 的规则冲突，明确冲突点并提出优先级。
6. 若修改了 skill 或质量标准，运行 `python scripts/validate_agent_skills.py`。

## Red Flags
- 把所有文档治理细节继续堆在本总控 skill 中。
- 直接创建新文档而没有先判断路径和内容边界。
- 只检查路径，不检查文档内容是否越界。
- 只检查单份文档，不检查它是否能追踪到下游证据。

## Verification
- 问题被路由到正确的具体 skill，或被拆成清晰的多步治理任务。
- 总控没有复制子 skill 的详细规则。
- 修改后所有文档治理类 skill 的职责不重叠。
- `python scripts/validate_agent_skills.py` 通过。

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| “一个总控 skill 全写进去更省事。” | 总控过大后会触发过宽、职责重叠，后续维护困难。 |
| “路径、内容、追踪其实是一回事。” | 三者回答的问题不同，混在一起会导致审查结论不可执行。 |
| “先做具体文档，治理后面补。” | 治理滞后会让错误路径和错误边界固化成事实。 |
