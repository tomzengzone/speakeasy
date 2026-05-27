# Screen Spec Generate Spec

## Purpose
Make UI work predictable by defining user goals, components, states, and acceptance checks before page implementation.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- A new screen or major screen state is needed.
- A page consumes new API or AI runtime output.
- UX review needs a concrete screen contract.

## Inputs
- `docs/product/base/spec.md`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`
- `docs/product/increments/<increment-id>/spec.md`
- `docs/product/increments/<increment-id>/acceptance.md`
- `docs/product/features/<feature-slug>-spec.md`
- Legacy `docs/product/acceptance_criteria.md` only for explicit compatibility, migration, or audit tasks after Product Base exists.
- `docs/architecture/api_contract.md`
- `docs/ai_runtime/llm_output_schema.md`
- Existing `docs/ux/` guidance.

## Outputs
- 页面规格：`docs/ux/screen_spec.md`。
- 用户流程：`docs/ux/user_flow.md`。
- 可用性检查：`docs/ux/usability_checklist.md`。
- 文案规则：必要时更新 `docs/ux/copywriting_guideline.md`。

## Product Object Outputs
- Screen specs cite the owning increment or stable feature.
- Legacy feature spec input remains valid only for existing flat artifacts until migration.

## Quality Bar
- A developer can implement the page without inventing states.
- Every user action has visible feedback.
- The screen can handle API failure and slow responses.
- Acceptance criteria cover the primary mobile workflow.
- Screen outputs remain under `docs/ux/` and do not replace product or API contracts.
- Screen scope is not generated from stage scope or roadmap text alone.

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
