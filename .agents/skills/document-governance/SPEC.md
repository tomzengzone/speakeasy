# Document Governance Spec

## Purpose
作为文档治理总控，路由路径治理、内容契约治理和追踪检查任务，并处理多个文档治理规则之间的冲突。

## Scope
适用于不确定使用哪个文档治理 skill、或同时涉及路径、内容和追踪多个治理面的任务。本 skill 不维护详细路径表、不定义每类文档完整内容契约、不执行完整链路审查。

## Trigger Context
- 文档治理需求范围不清。
- 需要拆分文档治理任务。
- 新增或调整文档治理类 skill。
- 路径、内容契约和追踪检查之间出现规则冲突。
- 需要更新文档治理 agent 的路由规则。

## Inputs
- 用户文档治理请求。
- `.agents/skills/document-path-governance/SKILL.md`
- `.agents/skills/document-content-contract/SKILL.md`
- `.agents/skills/document-traceability-check/SKILL.md`
- `.agents/skills/capability-registry-develop/SKILL.md`
- `docs/process/workflow.md`
- `docs/process/definition_of_done.md`
- `docs/process/skill_quality_standard.md`

## Outputs
- 路由决策。
- 多治理面任务拆分。
- 冲突处理建议。
- 必要时更新 `.agents/skills/document-governance/` 或 `codex/agents/documentation_governance.md`。
- 用户要求时写入 `docs/reports/quality_report.md`。

## Quality Bar
- 单一职责问题必须路由到具体子 skill。
- 混合问题必须拆分为可执行步骤。
- 本 skill 不复制子 skill 的详细规则。
- 路由规则必须覆盖路径、内容契约和追踪检查三类问题。
- 普通 Capability Registry 产品事实操作必须路由到 Product Manager 使用 `capability-registry-develop`；只有 path、schema、category、content boundary 或 source-of-truth 变化留在文档治理流程。
- 本 skill 不复制 Capability Registry 的字段、ID、迁移、影响分析或 ready-gate 细则。
- 强制追溯矩阵问题必须按路径、内容边界、链路完整性拆分，而不是由总控直接审查细节。
- 修改后必须通过 skill 校验。

## Maintenance Notes
- 新增文档治理子 skill 时，更新本文件和 `SKILL.md` 的 Routing Rules。
- 子 skill 规则变更时，只同步路由摘要，不复制细则。
- `capability-registry-develop` 变更时，只同步普通操作与治理变更的分流边界。
- 修改后运行 `python scripts/validate_agent_skills.py`。
- 若外部文档治理方法被引入，只记录来源和采用的原则。

## External References
- GitHub Copilot Agent Skills: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills
- awesome-copilot skills: https://github.com/github/awesome-copilot
- Diataxis documentation framework: https://github.com/evildmp/diataxis-documentation-framework
- The Good Docs Project templates: https://github.com/thegooddocsproject/templates
