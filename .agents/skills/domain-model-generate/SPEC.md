# Domain Model Generate Spec

## Purpose
Keep domain concepts stable before database, API, AI runtime, or UI work depends on them.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- A feature introduces or changes business entities.
- A workflow needs state transitions or lifecycle rules.
- Data ownership between frontend, backend, and AI runtime is unclear.

## Inputs
- `docs/product/increments/<increment-id>/spec.md`
- `docs/product/increments/<increment-id>/acceptance.md`
- `docs/product/base/spec.md`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`
- `docs/product/features/<feature-slug>-spec.md`
- Legacy `docs/product/acceptance_criteria.md` only for explicit compatibility, migration, or audit tasks after Product Base exists.
- Existing `docs/domain/` files.
- `docs/architecture/system_overview.md`
- `docs/architecture/module_boundary.md`

## Outputs
- 领域总览：`docs/domain/domain_schema.md`。
- 实体关系：`docs/domain/entity_relationship.md`。
- 专项领域模型：`docs/domain/<domain>_model.md`。
- 持久化和 API 边界建议：写入相关领域模型文档。

## Product Object Outputs
- Domain updates cite the owning increment or stable feature.
- Legacy feature spec input remains valid only for existing flat artifacts until migration.

## Quality Bar
- Each entity has an owner and lifecycle.
- Relationships are navigable without ambiguity.
- Constraints explain duplicate, deletion, and archival behavior.
- API and database work can proceed without guessing.
- Domain output paths use the canonical `docs/domain/` map.
- Domain changes are not generated from stage scope or roadmap text alone.

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
