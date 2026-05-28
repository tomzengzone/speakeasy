# Requirement Refine Spec

## Purpose
Turn natural-language product intent into constrained, testable requirements before design or code begins.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- A new feature request is ambiguous or broad.
- A change may expand MVP scope.
- A feature needs user stories, non-goals, and success criteria.

## Inputs
- User request or change request.
- Product object classification from Product Manager.
- `docs/product/base/requirements.md`
- `docs/product/feature_registry.md`
- `docs/product/stages/<stage-id>.md`
- `docs/product/increments/<increment-id>/definition.md`
- `docs/product/vision.md`
- `docs/product/mvp_scope.md`
- `docs/product/user_stories.md`
- `docs/product/feature_backlog.md`
- `docs/process/change_request.md`
- Known constraints, target users, and MVP boundary.

## Outputs
- 产品级定位或边界更新：`docs/product/vision.md`、`docs/product/mvp_scope.md`。
- 用户故事更新：`docs/product/user_stories.md`。
- 功能级需求收敛：`docs/product/features/<feature-slug>-requirements.md`。
- 范围变更记录：`docs/process/change_request.md`。
- 延期项：`docs/product/feature_backlog.md` 或功能级需求文档的后续延展段。
- 供后续 feature spec 和 acceptance criteria 使用的上游追溯引用。

## Product Object Outputs
- Product object classification and path decision.
- Accepted stable product requirements: `docs/product/base/requirements.md`.
- New stable feature requirements: `docs/product/features/<feature-slug>/requirements.md`.
- New increment requirements: `docs/product/increments/<increment-id>/requirements.md`.
- New increment requirement IDs that reference upstream Stage Scope Item IDs from the active stage.
- Product Base consolidation output: `docs/product/base/requirements.md`.
- Baseline consolidation references: `docs/product/baselines/<baseline-slug>.md` or `docs/product/baselines/<baseline-slug>/`.
- Baseline snapshots are not the living requirement source; merge accepted stable behavior into Product Base first, then freeze baselines when needed.
- Legacy feature requirement files remain valid only for existing flat artifacts until migration.

## Quality Bar
- Every success criterion can become at least one test.
- Every user story has a user, action, and outcome.
- Assumptions are separate from confirmed requirements.
- Scope additions are recorded as backlog or change request.
- Every created or updated requirement artifact has a concrete repository path.
- Current MVP Product Base consolidation may use actual implementation evidence, but must label that mode explicitly and must not create a frozen baseline unless requested.
- P0 or new-feature requirements must feed feature spec generation before acceptance criteria and implementation.
- Requirement refinement does not establish 100% coverage; coverage is established in acceptance criteria and verified by traceability checks/tests.
- A feature slug names a stable product capability, not MVP, P0.1, P0.2, Now, Next, or Later.
- Increment requirements reference an increment definition, active stage, covered Stage Scope Item IDs, and primary feature.
- New increment requirements must not be generated from stage prose alone; the active stage must expose stable Stage Scope Item IDs and the increment definition must list `Covered Stage Scope Items`.
- Every new increment requirement ID cites at least one Stage Scope Item ID or a Product Manager-approved change request.
- Stage goals, stable feature requirements, and baseline facts are not mixed in one output document.

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
