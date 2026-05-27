# Feature Spec Generate Spec

## Purpose
Create a feature-level contract that connects requirements, architecture impact, tests, and non-goals.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- A new user-visible feature is starting.
- A change affects more than one module.
- A feature needs API, UI, data, or AI behavior coordinated.

## Inputs
- `docs/product/feature_registry.md`
- `docs/product/base/requirements.md`
- `docs/product/base/spec.md`
- `docs/product/stages/<stage-id>.md`
- `docs/product/increments/<increment-id>/definition.md`
- `docs/product/increments/<increment-id>/requirements.md`
- `docs/product/features/<feature-slug>-requirements.md`
- `docs/product/features/<feature-slug>/requirements.md`
- `docs/product/user_stories.md`
- `docs/product/mvp_scope.md`
- `docs/process/change_request.md`
- Relevant architecture and domain docs when they already exist.
- `docs/process/definition_of_done.md`

## Outputs
- 功能规格：`docs/product/features/<feature-slug>-spec.md`。
- API、数据、UI、AI、测试影响说明：写入同一 feature spec 的影响段。
- 供验收标准使用的上游追溯引用：写入同一 feature spec。
- 范围扩展记录：必要时更新 `docs/process/change_request.md`。
- 不直接写入架构、领域、AI runtime 或 UX 契约；仅标记后续对应文档需求。

## Product Object Outputs
- Product Base spec for accepted stable behavior: `docs/product/base/spec.md`.
- New increment spec: `docs/product/increments/<increment-id>/spec.md`.
- Stable feature contract update when explicitly requested: `docs/product/features/<feature-slug>/README.md`.
- Legacy feature spec: `docs/product/features/<feature-slug>-spec.md` only for existing flat artifacts until migration.
- Required downstream contract list for architecture, domain, API, AI runtime, UX, and tests.

## Quality Bar
- The feature can be accepted or rejected from the spec alone.
- Every module impact has an owner Agent.
- Every criterion maps to a QA item.
- Non-goals prevent obvious scope creep.
- Output path follows `docs/product/features/<feature-slug>-spec.md`.
- For P0 or new features, the approved feature spec is the direct upstream source for acceptance criteria.
- The feature spec preserves traceability to requirements, user stories, MVP/P0 scope, and non-goals.
- Requirement coverage completeness is established later by acceptance criteria and the traceability matrix, not by the feature spec alone.
- For new product work, output path follows `docs/product/increments/<increment-id>/spec.md`.
- The spec cites active stage, primary feature, affected features, increment definition, and increment requirements.
- Stage goals and stable feature boundaries are referenced but not rewritten as the increment spec.

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
