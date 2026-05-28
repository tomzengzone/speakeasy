# Document Traceability Check Spec

## Purpose
检查项目文档在 workflow 中是否形成可追踪链路，确保需求、规格、验收、契约、测试、报告和发布证据一致。

## Scope
适用于 feature、变更请求、发布前检查和质量审查中的文档链路检查。不负责定义文档路径或内容模板，也不生成缺失文档。

## Trigger Context
- 用户询问某个需求处于 workflow 哪一步。
- 发布或完成前需要证明文档链路完整。
- 发现实现、测试或报告与需求状态不一致。
- 需要审查多个文档之间是否断链。
- 需要审查全量系统架构、平台架构、技术栈 ADR、商业化架构或前后端数据库方案是否具备产品对象覆盖证据。

## Inputs
- `docs/process/workflow.md`
- `docs/process/definition_of_done.md`
- `docs/process/change_request.md`
- `docs/product/`
- `docs/product/base/`
- `docs/product/stages/`
- `docs/product/increments/`
- `docs/product/traceability_matrix.md`
- `docs/domain/`
- `docs/architecture/`
- `docs/ai_runtime/`
- `docs/ux/`
- `docs/reports/`
- `docs/release/`
- `test/` and `tests/` when test evidence is needed.

## Outputs
- 链路完整性结论。
- 缺失、重复、过期或状态冲突清单。
- 下一步 workflow 建议。
- 用户要求时写入 `docs/reports/quality_report.md`。
- 对 `FR -> User Story -> AC -> Code Evidence -> Test Evidence -> Status` 的完整性审查结论。
- 对新 increment 的 `Stage Scope ID -> Increment ID -> FR -> AC -> Contract Evidence -> Code Evidence -> Test Evidence -> Release Evidence -> Status` 完整性审查结论。
- Product Base traceability check for `docs/product/base/traceability.md` when accepted stable behavior is in scope.
- Architecture coverage finding for broad architecture tasks: scope mode, source inventory, feature/stage coverage, omitted-scope classification, option comparison, and downstream contract gaps.

## Quality Bar
- 检查范围明确。
- 每个缺口都有具体文件或 workflow 阶段。
- 不把缺失文档直接补写成新内容。
- 不和路径治理或内容契约治理混淆。
- 输出可以指导下一步使用哪个 skill。
- 能区分当前 MVP 代码基线固化与 P0/新增功能 workflow 的 AC 来源规则。
- 能确认 100% 覆盖约束是在 acceptance criteria 阶段建立，测试阶段只验证并补充测试证据。
- 能确认 committed stage work 的 100% 追溯覆盖包括 Stage Scope Item ID coverage、increment coverage、FR coverage、AC coverage 和 evidence status。
- 能确认 Test Evidence 为空时必须有“人工验收”、“外部服务依赖”或“暂不可自动化”例外。
- 能阻止未覆盖 Product Base、baseline、feature registry、stage、increment 和 future boundaries 的全量架构被标记为 source of truth。

## Maintenance Notes
- workflow 变化时同步更新 Traceability Model。
- Product Base traceability lives at `docs/product/base/traceability.md`; global traceability remains a legacy or index path after migration.
- Definition of Done 变化时同步更新检查规则。
- 当追溯矩阵字段、AC 来源规则或测试阶段职责变化时，同步更新 acceptance-criteria-generate 和 test-case-generate。
- 当 Stage Scope Item ID 或 stage-to-increment coverage 规则变化时，同步更新 Product Manager agent、workflow、requirement-refine、feature-spec-generate 和 acceptance-criteria-generate。
- 当 architecture、domain、API、AI runtime 或 release workflow 增加新的强制合同类型时，同步更新 Architecture Traceability Gate。
- 修改后运行 `python scripts/validate_agent_skills.py`。
- 若需要自动化检查，再考虑新增脚本；本 skill 先定义人工审查流程。

## External References
- GitHub Copilot Agent Skills: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills
- Docs as Code guide: https://www.writethedocs.org/guide/docs-as-code.html
- Vale prose linter: https://github.com/errata-ai/vale
- Elastic Vale rules: https://github.com/elastic/vale-rules
