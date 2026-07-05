# Document Content Contract Spec

## Purpose
定义每类项目文档的内容边界、必需章节、禁止内容、上游输入、下游输出和验收标准，防止文档职责混杂。

## Scope
适用于 `docs/` 下所有持久化项目文档，以及会生成这些文档的 `.agents/skills/*`。不负责文档路径归属，也不负责跨文档链路完整性检查。

## Trigger Context
- 需要定义或修改文档模板。
- 需要审查文档内容是否越界。
- 需要判断某个内容应该写在需求、规格、契约还是报告中。
- 需要把成熟文档框架转化为本项目的内容契约。

## Inputs
- 目标文档。
- `docs/product/base/` when Product Base content boundaries are being reviewed.
- 上游需求、规格或契约文档。
- `docs/process/skill_quality_standard.md`
- 相关生成类 skill。

## Outputs
- 文档内容边界定义。
- 必需章节和禁止内容清单。
- Product Base content boundary definitions for requirements, spec, acceptance, and traceability.
- Requirements content boundary definitions for broad modules: module functional requirement boundary, first-level subfunction sections, product-level functional requirement boundaries, three-column requirement item tables, separate traceability mapping, non-goals, open questions, and downstream handoff notes.
- 内容审查结论。
- 必要时更新相关 skill 或 `docs/process/skill_quality_standard.md`。
- 对验收标准和强制追溯矩阵职责边界的审查结论。
- 对 stage 文档是否用稳定 Stage Scope Item IDs 表达 committed scope、increment definition 是否声明 covered/excluded Stage Scope Item IDs 的审查结论。
- 对全局 SWC 架构基准、SWC Catalog、increment SWC allocation 内容边界是否分离的审查结论。

## Quality Bar
- 每类文档的目的和读者清晰。
- 每类文档都有必需内容和禁止内容。
- 文档内容不越过 workflow 阶段边界。
- 审查结论能指导具体修订。
- 不和路径治理、追踪检查职责重叠。
- `docs/product/base/acceptance.md` and `docs/product/increments/<increment-id>/acceptance.md` define observable acceptance behavior; `docs/product/base/traceability.md` and `docs/product/increments/<increment-id>/traceability.md` record FR, User Story, AC, Test Case ID, Code Evidence, Test Evidence, and Status.
- 100% 覆盖只表示需求覆盖完整性，不表述为代码行覆盖率或线上零缺陷保证。
- Committed stage scope must be expressed as stable Stage Scope Item IDs, not prose-only bullets; increment definitions must preserve those IDs as covered or excluded scope.
- Global SWC architecture baseline must own topology and reusable `SWC-FLOW-*` IDs; SWC Catalog must own component inventory; increment SWC allocation must own Existing Implementation Baseline, Delta From Existing Baseline, and FR/AC-to-SWC delta mapping.
- Broad-module requirements documents present product requirement results, not execution process. They must not use `Step 1` or `Step 2` headings.
- Broad-module requirements documents must include module functional requirement boundary, first-level subfunction sections, product-level functional requirement boundary for each subfunction, and requirement item tables with only `需求ID`, `需求项`, and `需求描述`.
- Traceability fields such as Stage Scope ID, source increment, spec ID, acceptance criteria ID, status, and evidence must remain in separate traceability mapping, not in the main requirement item table.

## Maintenance Notes
- 新增文档类别时，同时检查是否需要更新 `document-path-governance`。
- 修改 requirements 内容边界时，同步检查 requirement-refine 和 Requirement Development Agent。
- 修改验收标准或追溯矩阵内容边界时，同步检查 acceptance-criteria-generate、test-case-generate 和 document-traceability-check。
- 修改 stage scope item 或 stage-to-increment coverage 内容边界时，同步检查 Product Manager agent、workflow、requirement-refine、feature-spec-generate、acceptance-criteria-generate 和 document-traceability-check。
- 修改 SWC 架构内容边界时，同步检查 software component architecture governance、System Architect、Software Architecture Governance Check 和 document-traceability-check。
- 借鉴外部模板时只吸收结构和原则，不复制未确认许可的内容。
- 修改 skill 后运行 `python scripts/validate_agent_skills.py`。
- 保持内容契约简洁，详细模板应放到对应生成类 skill。

## External References
- Diataxis documentation framework: https://github.com/evildmp/diataxis-documentation-framework
- The Good Docs Project templates: https://github.com/thegooddocsproject/templates
- Write the Docs docs-as-code guide: https://www.writethedocs.org/guide/docs-as-code.html
- Vale prose linter: https://github.com/errata-ai/vale
