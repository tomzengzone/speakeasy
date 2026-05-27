# Skill Quality Check Spec

## Purpose
Inspect project-local skills for structure, trigger clarity, verification quality, and maintainability.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- A skill under .agents/skills is added or edited.
- The skill quality standard changes.
- A release wants to ensure development workflow assets are valid.

## Inputs
- `.agents/skills/<skill>/SKILL.md`
- `.agents/skills/<skill>/SPEC.md`
- `docs/process/skill_quality_standard.md`
- `scripts/validate_agent_skills.py` output.

## Outputs
- 默认输出：最终回复中的通过/失败结论、文件路径和修复建议。
- 持久化输出：用户要求时写入 `docs/reports/quality_report.md`。
- 标准变更：必要时更新 `docs/process/skill_quality_standard.md`。
- 不输出业务功能质量结论。

## Quality Bar
- Validator exits with code 0.
- Each changed skill has concrete use and non-use triggers.
- Red flags describe failure modes, not preferences.
- No deprecated codex/skills directory remains.
- Skill quality outputs identify exact skill file paths.
- Broad-scope skills cannot produce full-system conclusions without source inventory, scope mode, coverage gate, omitted-scope handling, and verification evidence.
- Skills that make technology, architecture, API, data, security, or release recommendations must require alternatives, trade-offs, constraints, and acceptance criteria.

## Maintenance Notes
- Keep SKILL.md concise enough for runtime use.
- Keep this SPEC.md focused on governance, traceability, and future maintenance.
- Update docs/process/skill_quality_standard.md before changing required sections.
- Run `python scripts/validate_agent_skills.py` after editing this skill.
- If external content is vendored, retain attribution and license in this directory.
- When a task failure exposes a reusable governance gap, update the generic standard first, then the smallest set of affected skills. Avoid one-off reminders tied to a single feature or stage.

## External References
- GitHub Copilot Agent Skills: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills
- OpenAI Codex skill-creator sample: https://github.com/openai/codex/blob/main/codex-rs/skills/src/assets/samples/skill-creator/SKILL.md
- addyosmani/agent-skills patterns: https://github.com/addyosmani/agent-skills
- Microsoft cloud-solution-architect skill: https://github.com/microsoft/skills/tree/main/.github/skills/cloud-solution-architect
- Callstack agent-skills structure and reference-file pattern: https://github.com/callstackincubator/agent-skills
- AIWG multi-agent workflow primitives and review flow pattern: https://github.com/jmagly/aiwg
- agent-ecosystem/skill-validator: https://github.com/agent-ecosystem/skill-validator
- getsentry/skills attribution practice: https://github.com/getsentry/skills
