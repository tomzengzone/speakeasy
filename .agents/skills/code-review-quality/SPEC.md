# Code Review Quality Spec

## Purpose
Provide a review gate that finds concrete defects and quality risks before a change is accepted.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- A development increment is ready for review.
- A broad refactor or generated change touches multiple areas.
- The user asks for review or quality assessment.

## Inputs
- Changed files and diffs.
- Owning Product Base or increment acceptance, traceability, and architecture contracts.
- Test results and implementation report.
- `docs/reports/implementation_report.md` when available.

## Outputs
- 默认输出：最终回复中的审查发现、开放问题和风险。
- 持久化输出：用户要求或 release 需要时写入 `docs/reports/quality_report.md`。
- 不直接写入需求、架构、领域或 API 契约文档。

## Quality Bar
- Findings include severity and precise location.
- No issue is reported without a plausible user or maintenance impact.
- Test gaps are clearly separated from defects.
- The review result can drive a fix list.
- Persistent review output, when needed, uses `docs/reports/quality_report.md`.
- Reviews check implementation simplicity, justified abstraction, explicit data ownership, typed error behavior, contract alignment, and evidence quality for generated or provider-facing code.

## Maintenance Notes
- Keep SKILL.md concise enough for runtime use.
- Keep this SPEC.md focused on governance, traceability, and future maintenance.
- Update docs/process/skill_quality_standard.md before changing required sections.
- Run `python scripts/validate_agent_skills.py` after editing this skill.
- If external content is vendored, retain attribution and license in this directory.

## External References
- GitHub Copilot Agent Skills: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills
- OpenAI Codex skill-creator sample: https://github.com/openai/codex/blob/main/codex-rs/skills/src/assets/samples/skill-creator/SKILL.md
- addyosmani/agent-skills patterns: https://github.com/addyosmani/agent-skills
- agent-ecosystem/skill-validator: https://github.com/agent-ecosystem/skill-validator
- getsentry/skills attribution practice: https://github.com/getsentry/skills
