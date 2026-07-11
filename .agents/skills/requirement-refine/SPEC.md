# Requirement Refine Spec

## Purpose
Turn natural-language product intent into constrained, testable requirements before design or code begins. Broad module refinement must use an internal two-step method: first-level subfunction decomposition with product-level functional requirement boundaries, then atomic requirement item development.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- A new feature request is ambiguous or broad.
- A change may expand MVP scope.
- A feature needs user stories, non-goals, and success criteria.
- A broad product module needs detailed requirements without collapsing multiple subfunctions into oversized FR rows.

## Inputs
- User request or change request.
- Broad module name, expected module slug, or affected stable capability when available.
- Product object classification from Product Manager.
- `docs/product/base/requirements.md`
- `docs/product/feature_registry.md`
- `docs/product/stages/<stage-id>.md`
- `docs/product/increments/<increment-id>/definition.md`
- `docs/product/vision.md`
- `docs/product/story_map.md`
- `docs/process/change_request.md`
- Known constraints, target users, and MVP boundary.

## Outputs
- 产品级定位或边界更新：`docs/product/vision.md`。
- Approved Story/Slice 只作为输入；本 skill 不创建或修改 Story/Slice。
- Product Base 需求：`docs/product/base/requirements.md`。
- 增量需求：`docs/product/increments/<increment-id>/requirements.md`。
- 范围变更记录：`docs/process/change_request.md`。
- 延期项：owning Product Base / increment requirements 的后续延展段，或 `docs/process/change_request.md` 的范围变更记录。
- 供后续 spec 和 acceptance criteria 使用的上游追溯引用。

## Product Object Outputs
- Product object classification and path decision.
- Accepted stable product requirements: `docs/product/base/requirements.md`.
- New increment requirements: `docs/product/increments/<increment-id>/requirements.md`.
- New increment requirement IDs that reference approved User Story IDs and Vertical Slice IDs as direct upstream.
- Broad-module requirement content organized by module functional boundary and first-level subfunction sections.
- First-level subfunction requirement item tables that use only `需求ID`, `需求项`, and `需求描述`.
- Separate owning traceability matrix for the complete Story/Slice/FR/Spec/AC/TC/evidence join.
- Product Base consolidation output: `docs/product/base/requirements.md`.
- Baseline consolidation references: `docs/product/baselines/<baseline-slug>.md` or `docs/product/baselines/<baseline-slug>/`.
- Baseline snapshots are not the living requirement source; merge accepted stable behavior into Product Base first, then freeze baselines when needed.

## Quality Bar
- Every success criterion can become at least one test.
- Every user story has a user, action, and outcome.
- Assumptions are separate from confirmed requirements.
- Scope additions are recorded as backlog or change request.
- Every created or updated requirement artifact has a concrete repository path.
- Current MVP Product Base consolidation may use actual implementation evidence, but must label that mode explicitly and must not create a frozen baseline unless requested.
- P0 or new-feature requirements must feed downstream spec generation before acceptance criteria and implementation.
- Requirement refinement does not establish 100% coverage; coverage is established in acceptance criteria and verified by traceability checks/tests.
- A feature slug names a stable product capability, not MVP, P0.1, P0.2, Now, Next, or Later.
- Increment requirements use approved Story/Slice as direct behavior input; increment, stage, and capability remain scope guards.
- New increment requirements must not be generated from stage, roadmap, or capability prose alone.
- Every new increment requirement ID cites at least one User Story ID and Vertical Slice ID or a Product Manager-approved change request.
- Stage goals, Product Base requirements, increment requirements, and baseline facts are not mixed in one output document.
- Broad-module requirements are decomposed into stable first-level subfunctions before detailed requirement items are written.
- Each first-level subfunction has a product-level functional requirement boundary that describes observable product capability ownership, excluded adjacent capabilities, entry or precondition, resulting product outcome, and handoff to adjacent subfunctions.
- Each atomic requirement item belongs to exactly one first-level subfunction.
- Main requirement item tables do not contain traceability, spec, AC, API, database, UI, or test fields.
- Final requirements documents present product requirement results and must not expose process headings such as `Step 1` or `Step 2`.

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
