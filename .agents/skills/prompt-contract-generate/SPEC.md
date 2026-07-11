# Prompt Contract Generate Spec

## Purpose
Make AI runtime behavior constrained, testable, and safe for frontend rendering.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- An approved scenario coach, correction, review, or explanation behavior calls an LLM.
- LLM output must be rendered by the app.
- Prompt changes need regression coverage.

## Inputs
- `docs/product/increments/<increment-id>/spec.md`
- `docs/product/base/spec.md`
- `docs/product/feature_registry.md`, only to verify the owning increment's approved V2 classification; it is not an AI behavior input
- Relevant `docs/domain/<domain>_model.md`
- `docs/architecture/api_contract.md`
- Existing `docs/ai_runtime/` contracts.
- Safety, fallback, and cost constraints.

## Outputs
- Prompt 契约：`docs/ai_runtime/prompt_contract.md`。
- LLM 输出 schema：`docs/ai_runtime/llm_output_schema.md`。
- fallback 行为：`docs/ai_runtime/fallback_strategy.md`。
- AI eval 用例：`docs/ai_runtime/ai_eval_cases.md`。
- 对话状态机：`docs/ai_runtime/dialogue_state_machine.md`。

## Product Object Outputs
- AI runtime updates cite the owning increment, approved V2 Primary Capability and complete Affected Capability list, or preserve its approved no-Primary classification, reason, and complete Affected Capability list.

## Quality Bar
- Output schema is stable and renderable.
- Invalid outputs have deterministic fallback handling.
- Eval cases include failure and off-topic inputs.
- Prompt changes can be regression-tested.
- AI runtime artifacts are split by contract, schema, fallback, eval, and state machine ownership.
- Registry data is never an AI behavior input; AI runtime behavior is not generated from stage scope or roadmap text.
- This skill preserves approved classification and never declares or modifies it. Missing or conflicting classification blocks this downstream work and routes to Product Manager to correct the owning Product Base or increment artifact; `capability-registry-develop` is invoked only when Product Manager determines that canonical registry facts must change.

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
