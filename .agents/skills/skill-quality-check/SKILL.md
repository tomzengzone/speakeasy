---
name: skill-quality-check
description: Use when project-local skills are created or changed and need validation against the project quality standard. Do not use for validating application features or source code behavior.
---

# Skill Quality Check

## Overview
Inspect project-local skills for structure, trigger clarity, verification quality, and maintainability.

## When to Use
- A skill under .agents/skills is added or edited.
- The skill quality standard changes.
- A release wants to ensure development workflow assets are valid.

## When NOT to Use
- The artifact is an application feature, not a skill.
- The request is to review production code quality.
- The old codex/skills layout is intentionally being archived outside the project.

## Inputs
- .agents/skills/<skill>/SKILL.md and SPEC.md.
- docs/process/skill_quality_standard.md.
- scripts/validate_agent_skills.py output.

## Outputs
- Pass/fail findings with file paths.
- Required fixes for missing sections or weak triggers.
- Suggestions for future validator hardening.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- skill 质量标准写入 `docs/process/skill_quality_standard.md`。
- 被检查 skill 位于 `.agents/skills/<skill>/SKILL.md` 和 `.agents/skills/<skill>/SPEC.md`。
- 校验脚本为 `scripts/validate_agent_skills.py`。
- 检查结果默认在最终回复中给出；用户要求持久化时写入 `docs/reports/quality_report.md`。
- 不检查业务功能质量；业务质量审查使用 `code-review-quality`。

## Process
1. Run the lightweight validator first.
2. Read the SKILL.md and SPEC.md for any failed or changed skill.
3. Check that triggers are specific and non-overlapping.
4. Check that verification steps are executable.
5. Check that external references and attribution are present when borrowed content exists.
6. For governance, architecture, product, or contract skills, check that they require source inventory, scope mode, coverage/traceability gate, and explicit omitted-scope handling before accepting broad outputs.
7. Report blockers before style suggestions.

## Red Flags
- A skill says always use without clear boundaries.
- When NOT to Use is empty or generic.
- Verification only says review manually.
- SPEC.md duplicates SKILL.md without adding maintenance context.
- A broad planning or architecture skill can produce conclusions without first proving input coverage.
- A skill allows technology or implementation recommendations without constraints, alternatives, trade-offs, and verification gates.
- A skill has no rule for rejecting or superseding its own weak outputs.

## Verification
- Validator exits with code 0.
- Each changed skill has concrete use and non-use triggers.
- Red flags describe failure modes, not preferences.
- No deprecated codex/skills directory remains.
- Broad-scope skills define coverage gates that prevent partial context from being presented as full-system conclusions.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
