# Feature Spec Generate Spec

## Purpose
Create an executable product specification that turns approved requirements into clear, traceable behavior contracts without becoming acceptance criteria, API schema, or implementation tasks.

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
- Product object, upstream sources, goal/boundary, requirement-to-spec mapping, behavior spec items, shared state/signal definitions, module impact, downstream contract needs, non-goals, acceptance coverage expectations, and rollout or merge-back notes.
- 供验收标准使用的上游追溯引用：写入 owning spec。
- 范围扩展记录：必要时更新 `docs/process/change_request.md`。
- 不直接写入架构、领域、AI runtime 或 UX 契约；仅标记后续对应文档需求。

## Product Object Outputs
- New increment spec: `docs/product/increments/<increment-id>/spec.md`.
- Stage Scope Item ID references preserved in increment spec flows, states, dependencies, and non-goals.
- Product Base spec for accepted stable behavior: `docs/product/base/spec.md`.
- Product Base module spec when declared by upstream requirements: `docs/product/base/<module-slug>/spec.md`.
- Stable feature contract update when explicitly requested: `docs/product/features/<feature-slug>/README.md`.
- Legacy feature spec: `docs/product/features/<feature-slug>-spec.md` only for existing flat artifacts until migration.
- Required downstream contract list for architecture, domain, API, AI runtime, UX, and tests.

## Quality Bar
- The feature can be accepted or rejected from the spec alone.
- Every module impact has an owner Agent.
- Every spec item maps to expected acceptance coverage or an explicit exception.
- Non-goals prevent obvious scope creep.
- For P0 or new features, the approved feature spec is the direct upstream source for acceptance criteria.
- The feature spec preserves traceability to requirements, user stories, MVP/P0 scope, and non-goals.
- The shared semantic quality model in `document-content-contract` is the source for granularity, clarity, and coverage checks.
- A requirement with multiple independent business conclusions maps to multiple spec items.
- The spec stops before implementation tasks; it must not decompose into UI rendering steps, endpoint work items, table fields, class names, or test steps.
- For new product work, output path follows `docs/product/increments/<increment-id>/spec.md`.
- The spec cites active stage, covered Stage Scope Item IDs, primary feature, affected features, increment definition, and increment requirements.
- Stage goals and stable feature boundaries are referenced but not rewritten as the increment spec.
- New behavior in the spec must be traceable to a Stage Scope Item ID, an increment requirement, or a Product Manager-approved change request.
- Shared states, inputs, outputs, errors, downgrade and security signals are defined once in the Specification section when they are development inputs; functional sections reference them without duplicating per-section reference tables.

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
