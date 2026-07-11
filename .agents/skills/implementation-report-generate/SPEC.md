# Implementation Report Generate Spec

## Purpose
Create an auditable record that connects the completed change to requirements, tests, and residual risk.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- Product behavior, workflow, or process assets have been added or changed.
- The user asks what changed and how it was verified.
- A sprint increment needs traceability.

## Inputs
- Git status and changed file list.
- `docs/product/increments/<increment-id>/definition.md`
- `docs/product/increments/<increment-id>/spec.md`
- `docs/product/increments/<increment-id>/acceptance.md`
- Requirement or increment spec reference.
- Commands run and results.
- Known risks and follow-up items.
- `docs/reports/test_report.md` and `docs/reports/quality_report.md` when available.

## Outputs
- 实现报告：`docs/reports/implementation_report.md`。
- 范围、需求映射、变更文件、验证、风险和后续项：写入实现报告的当前条目。
- 未运行测试说明：写入实现报告的验证或风险段。

## Product Object Outputs
- Implementation reports cite the owning increment, approved V2 Primary Capability and Affected Capabilities, preserve its approved no-Primary classification, reason, and complete Affected Capability list, or cite the process governance artifact for governance-only work.
- Reporting never declares or modifies classification. Missing or conflicting classification is a governance gap routed to Product Manager to correct the owning Product Base or increment artifact; `capability-registry-develop` is invoked only when Product Manager determines that canonical registry facts must change.
- Reports summarize evidence and do not redefine requirements, specs, acceptance criteria, or stage scope.

## Quality Bar
- Every meaningful changed area is represented.
- Validation commands match what was actually run.
- Skipped tests are explicit.
- The entry can support later audit or rollback planning.
- The report path is always `docs/reports/implementation_report.md`.
- Product completion claims include an increment/spec/AC reference or explicitly document the governance gap.

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
