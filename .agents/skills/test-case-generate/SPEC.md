# Test Case Generate Spec

## Purpose
Turn acceptance criteria into a balanced, executable test plan before or during implementation.

## Scope
This project-local skill applies to development workflow assets in this repository. It supports the Codex software engineering pipeline and must not silently expand product scope or bypass the project Definition of Done.

## Trigger Context
- A Product Base or increment spec has acceptance criteria and is ready for implementation or QA planning.
- A bug fix needs a regression test.
- A change affects API, UI, data, or AI output contracts.

## Inputs
- `docs/product/base/acceptance.md`
- `docs/product/base/spec.md`
- `docs/product/base/traceability.md`
- `docs/product/increments/<increment-id>/acceptance.md`
- `docs/product/increments/<increment-id>/spec.md`
- `docs/product/increments/<increment-id>/traceability.md`
- `docs/product/feature_registry.md`
- `docs/architecture/api_contract.md`
- `docs/ux/screen_spec.md`
- `docs/ai_runtime/prompt_contract.md`
- Existing test conventions under `test/`, `backend/src/test/java/`, and `tests/`.

## Outputs
- 增量测试用例库：`docs/product/increments/<increment-id>/test_cases.md`，并引用 owning acceptance 文件。
- 测试执行结果和测试报告：`docs/reports/test_report.md`。
- Flutter/Dart 测试代码：`test/`。
- 后端 Maven/Spring Boot 测试代码：`backend/src/test/java/`。
- 跨服务或仓库级测试代码：`tests/`。
- AI eval 用例：`docs/ai_runtime/ai_eval_cases.md`。
- 覆盖缺口：`docs/reports/test_report.md`。
- Product Base 追溯矩阵测试证据状态：`docs/product/base/traceability.md` 或 `docs/reports/test_report.md`。
- Increment 追溯矩阵测试证据状态：`docs/product/increments/<increment-id>/traceability.md` 或 `docs/reports/test_report.md`。
- Test Evidence updates must cite TC ID, test script path, execution command, result status, and evidence report.

## Product Object Outputs
- Test evidence cites the owning increment or stable feature.
- Stable test case IDs are assigned in the owning increment test case library using `TC-<scope-prefix>-<NNN>`; MVP backend uses `TC-MVP-BE-001`, `TC-MVP-BE-002`, and so on.
- Each test case carries Traceability Row ID, Increment ID, WP ID, Spec ID, AC ID, test layer, automation status, test script path, execution command, result status, evidence report, and Gap / Exception.
- Product Base evidence belongs in `docs/product/base/traceability.md` or `docs/reports/test_report.md`.
- Increment-specific evidence belongs in the increment traceability record.

## Quality Bar
- Every criterion is covered or explicitly deferred with reason.
- The test pyramid remains balanced.
- Failures would point to the responsible module.
- AI schema tests validate both valid and invalid outputs.
- Documentation outputs and executable test outputs are separated by path.
- Test-case generation maps AC to tests or explicit exceptions; it does not define FR, AC, or requirement coverage.
- Test generation validates approved ACs and does not create feature, stage, or increment scope.
- Committed increment implementation is blocked until every approved AC maps to stable TC IDs or explicit allowed exceptions in the owning increment test case library.
- Published TC IDs are immutable: do not renumber, reuse, or assign an existing ID to a different behavior; retire with replacement or reason when needed.
- Required test case fields must be populated or carry an explicit `N/A - <reason>`; blank traceability, script, command, result, or evidence fields are blockers.
- Traceability Test Evidence updates preserve Traceability Row ID, Spec ID, and AC ID; the owning matrix maintains the complete upstream join.
- Every AC has Test Evidence or one of the allowed exceptions: 人工验收, 外部服务依赖, 暂不可自动化.
- Missing Test Evidence is a completion blocker until recorded in the test report or traceability matrix.

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
