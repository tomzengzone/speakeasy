# Acceptance Criteria Generate Spec

## Purpose
Convert requirements into behavior-oriented pass/fail checks that QA and implementation can trace.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- Current MVP Product Base consolidation needs acceptance criteria from implemented behavior, requirements, MVP scope, and user stories.
- An approved P0 or new-feature spec needs acceptance criteria or acceptance-to-test planning.
- An accepted change request has an approved Product Base or increment spec and must be evaluated for done-ness.

## Inputs
- `docs/product/user_stories.md`
- `docs/product/base/spec.md`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`
- `docs/product/increments/<increment-id>/spec.md`
- `docs/product/increments/<increment-id>/requirements.md`
- `docs/product/increments/<increment-id>/definition.md`
- `docs/product/stages/<stage-id>.md` with stable Stage Scope Item IDs for new increment work.
- `docs/product/base/requirements.md`
- `docs/product/feature_registry.md`
- `docs/process/change_request.md`
- Known platform limitations.
- Current MVP code evidence only for explicit code-baseline freeze work.

## Outputs
- Product Base 验收标准：`docs/product/base/acceptance.md`。
- Product Base 强制追溯矩阵：`docs/product/base/traceability.md`。
- Increment 验收标准：`docs/product/increments/<increment-id>/acceptance.md`。
- Increment 强制追溯矩阵：`docs/product/increments/<increment-id>/traceability.md`。
- Increment traceability rows that preserve `Stage Scope ID -> Increment ID -> FR -> AC -> Test Case ID -> Contract Evidence -> Code Evidence -> Test Evidence -> Release Evidence -> Status`.
- 测试映射说明：写入对应验收标准条目或追溯矩阵；稳定 TC ID 由 `test-case-generate` 在实现前写入 increment test case library 并回填追溯证据。

## Product Object Outputs
- Product Base acceptance criteria: `docs/product/base/acceptance.md`.
- Product Base traceability: `docs/product/base/traceability.md`.
- New increment acceptance criteria: `docs/product/increments/<increment-id>/acceptance.md`.
- New increment traceability: `docs/product/increments/<increment-id>/traceability.md`.

## Quality Bar
- Each criterion is binary enough to pass or fail.
- At least one criterion checks error handling when the feature can fail.
- The list does not require hidden implementation knowledge.
- QA can generate tests directly from the list.
- Acceptance criteria paths are explicit and linked from the owning Product Base or increment when split.
- For the current MVP baseline, AC can be generated from requirements, MVP scope, user stories, and actual code evidence.
- For P0 or new features, AC uses the approved Product Base or increment spec as the direct upstream source and traces back to requirements, user stories, and scope.
- The traceability matrix has no empty FR, AC, Test Case ID, Code Evidence, or Test Evidence fields unless the field is explicitly pending the next workflow gate or has an allowed exception.
- Requirement coverage completeness is not represented as code line coverage or a guarantee of zero production defects.
- For new product work, AC uses the approved increment spec as the direct upstream source.
- Increment AC and traceability live under the same increment directory.
- Stage scope, feature registry entries, and baseline notes are upstream context, not direct AC sources except for explicit Product Base or baseline consolidation work.
- For new increment work, the traceability matrix proves all required Stage Scope Item IDs are covered by the increment or explicitly deferred/not applicable, and every FR/AC preserves those upstream IDs.

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
