# Document Path Governance Spec

## Purpose
定义和维护项目文档的 canonical path、owner、source of truth 和输入输出路径规则，避免文档位置漂移或职责重叠。

## Scope
适用于 `docs/`、`.agents/skills/`、`codex/agents/`、`scripts/validate_agent_skills.py` 中和文档路径、文档归属、Allowed Paths、路径模板有关的变更。

## Trigger Context
- 新增文档类别或文档路径。
- 文档产物路径不清楚。
- skill 或 agent 的输入输出路径不明确。
- 同一类文档出现多个候选位置。
- 文档迁移、重命名或废弃。

## Inputs
- `docs/process/workflow.md`
- `docs/process/definition_of_done.md`
- `docs/process/skill_quality_standard.md`
- `docs/`
- `.agents/skills/*/SKILL.md`
- `.agents/skills/*/SPEC.md`
- `codex/agents/*.md`

## Outputs
- 路径归属决策。
- 更新后的路径模板与 source-of-truth 说明。
- 更新后的 skill 输入输出路径。
- 更新后的 agent Allowed Paths。
- 必要时写入 `docs/reports/quality_report.md` 的路径审查摘要。
- 全局 SWC 架构基准路径为 `docs/architecture/software_component_architecture.md`；它记录完整 SWC 拓扑、稳定 `SWC-FLOW-*` 和局部变更参考基准。
- API 契约总览路径为 `docs/architecture/api_contract.md`；机器可执行 OpenAPI source-of-truth 路径为 `docs/architecture/openapi/speakeasy-api.yaml`。
- Product Base paths are `docs/product/base/requirements.md`, `docs/product/base/spec.md`, `docs/product/base/acceptance.md`, and `docs/product/base/traceability.md`.
- Increment test case libraries use `docs/product/increments/<increment-id>/test_cases.md` and remain the canonical AC-to-TC design artifact before implementation starts.
- Baseline snapshot paths use `docs/product/baselines/<baseline-slug>/` or `docs/product/baselines/<baseline-slug>.md` for legacy single-file snapshots.

## Quality Bar
- 每类文档只有一个默认 source of truth。
- Product Base is the living source of truth for accepted product requirements, specs, acceptance, and traceability; baselines are frozen snapshots.
- 每个文档产物都能映射到明确路径或路径模板。
- agent Outputs 必须被 Allowed Paths 覆盖。
- skill 的 `SKILL.md` 与 `SPEC.md` 路径说明一致。
- 不为了单次任务引入长期目录。
- API contract overview and OpenAPI YAML have distinct ownership: the overview records scope, traceability, versioning, error semantics, and compatibility policy; the YAML owns paths, components, request/response schemas, examples, and machine lint.
- Global SWC architecture baseline, SWC catalog, and increment SWC allocation have distinct ownership: baseline records topology and reusable Flow IDs, catalog records component inventory, allocation records increment-specific FR/AC mapping.
- 需求覆盖矩阵不分散到验收标准、测试报告或增量规格中作为新的 source of truth；这些文档只能引用矩阵或补充证据。

## Maintenance Notes
- 修改路径约定后同步检查所有生成类 skill。
- 如果新增文档类别，先更新本 skill，再更新 `document-governance` 路由说明。
- 新增或调整追溯矩阵路径时，同步检查 acceptance-criteria-generate、test-case-generate 和 document-traceability-check。
- 修改后运行 `python scripts/validate_agent_skills.py`。
- 不在本 skill 中定义文档内容模板，内容边界由 `document-content-contract` 维护。

## External References
- GitHub Copilot Agent Skills: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills
- awesome-copilot skills: https://github.com/github/awesome-copilot
- The Good Docs Project templates: https://github.com/thegooddocsproject/templates
- Diataxis documentation framework: https://github.com/evildmp/diataxis-documentation-framework
