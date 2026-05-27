# API Contract Generate Spec

## Purpose
Define stable API contracts before implementation so clients, tests, and services share one source of truth.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- A feature crosses frontend/backend boundaries.
- An endpoint or DTO changes.
- Error behavior or compatibility needs to be explicit.

## Inputs
- `docs/product/increments/<increment-id>/spec.md`
- `docs/product/features/<feature-slug>-spec.md`
- `docs/domain/domain_schema.md`
- Relevant `docs/domain/<domain>_model.md`
- Existing `docs/architecture/api_contract.md`
- Existing `docs/architecture/openapi/speakeasy-api.yaml` when present
- Security and compatibility requirements.

## Outputs
- API 契约总览：`docs/architecture/api_contract.md`。
- OpenAPI source of truth：`docs/architecture/openapi/speakeasy-api.yaml`。
- 数据流影响：必要时更新 `docs/architecture/data_flow.md`。
- 模块边界影响：必要时更新 `docs/architecture/module_boundary.md`。
- 架构决策：必要时新增 `docs/architecture/adr/<id>-<slug>.md`。

## Product Object Outputs
- API contract updates cite the owning increment or stable feature.
- Legacy feature spec input remains valid only for existing flat artifacts until migration.

## Quality Bar
- Client and server can be implemented independently from the contract.
- Each error has code, message semantics, and status.
- Examples cover at least one success and one failure path.
- Tests can validate compatibility.
- API output paths are explicit and do not mix domain model ownership into the API contract.
- API changes are not generated from stage scope or roadmap text alone.
- `docs/architecture/api_contract.md` owns human-readable contract boundaries, traceability, compatibility, and examples; `docs/architecture/openapi/speakeasy-api.yaml` owns machine-readable paths, components, request/response schemas, and lintable examples.

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
