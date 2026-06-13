---
name: document-content-contract
description: Use when a project document needs a content boundary, required sections, prohibited content, audience definition, upstream/downstream contract, or completeness review. Do not use for deciding where the document should live or whether document chains are traceable across workflow stages.
---

# Document Content Contract

## Overview
治理项目文档内部内容边界：每类文档应该写什么、不应该写什么、面向谁、依赖哪些上游、驱动哪些下游，以及如何判断内容合格。

## When to Use
- 需要定义某类文档的必需章节或模板。
- 需要判断文档内容是否越界，例如需求文档写了 API schema。
- 需要区分 vision、requirements、feature spec、acceptance criteria、domain model、API contract、prompt contract、screen spec、report 的职责边界。
- 需要审查文档是否缺少假设、非目标、验收检查、状态或决策字段。
- 需要借鉴 Diataxis、Good Docs 等成熟文档内容分类方法。

## When NOT to Use
- 只需要决定文档路径或 owner；使用 `document-path-governance`。
- 只需要检查跨文档链路是否完整；使用 `document-traceability-check`。
- 只需要生成某类具体文档正文；使用对应生成类 skill。
- 只做代码审查或测试执行。

## Inputs
- `docs/product/vision.md`
- `docs/product/mvp_scope.md`
- `docs/product/base/requirements.md`
- `docs/product/base/spec.md`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`
- `docs/product/user_stories.md`
- `docs/product/acceptance_criteria.md`
- `docs/product/traceability_matrix.md`
- `docs/product/features/*.md`
- `docs/architecture/*.md`
- `docs/domain/*.md`
- `docs/ai_runtime/*.md`
- `docs/ux/*.md`
- `docs/reports/*.md`
- 需要定义或审查的目标文档。

## Outputs
- 文档内容契约定义。
- 必需章节、禁止内容、上游输入、下游输出和验收检查清单。
- 必要时更新 `document-governance` 或具体生成类 skill 的内容边界说明。
- 用户要求持久化时，将内容契约审查摘要写入 `docs/reports/quality_report.md`。

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 内容契约规则默认写入 `.agents/skills/document-content-contract/SKILL.md` 或对应生成类 skill。
- 若需要项目级持久化标准，写入 `docs/process/skill_quality_standard.md`。
- 对单份文档的审查结果默认在最终回复中给出；需要留痕时写入 `docs/reports/quality_report.md`。
- 不决定文档最终路径；路径归属由 `document-path-governance` 处理。

## 内容契约基线
- `docs/product/vision.md`：写 App 定位、目标用户、核心承诺、产品原则和长期非目标；不写具体状态机、接口、页面和实现计划。
- `docs/product/mvp_scope.md`：写 MVP 目标、范围内、范围外、成功标准和范围控制规则；不写详细接口、页面布局或 prompt schema。
- `docs/product/feature_registry.md`：写 APP 稳定功能域、feature slug、owner、长期边界、当前状态和关联 stages/increments；不写阶段计划细节、实现任务或测试证据。
- `docs/product/base/requirements.md`：写已接受稳定产品行为的 FR、用户目标、用户路径、成功标准、非目标、假设和来源；不写阶段计划、API schema、prompt schema、UI 布局或代码实现。
- `docs/product/base/spec.md`：写已接受稳定产品行为的用户流程、状态、输入输出、失败路径、模块影响和测试期望；不写代码实现或产品优先级决策。
- `docs/product/base/acceptance.md`：写已接受稳定产品行为的可观察 pass/fail 行为；不写类名、函数名、数据库字段或测试实现。
- `docs/product/base/traceability.md`：写 Product Base 的 `Requirement -> AC -> Test Case ID -> Code Evidence -> Test Evidence -> Status`；不新增需求，不替代验收标准。
- `docs/product/baselines/<baseline-slug>.md`：写当前已实现能力快照、事实来源、代码/资产证据、回归边界和不承诺项；不写未来新增需求或未批准计划。
- `docs/product/stages/<stage-id>.md`：写阶段目标、入口条件、出口条件、纳入/排除的 increments，并用稳定 Stage Scope Item ID 表表达阶段范围；不写 API schema、UI 布局、prompt schema 或代码实现。
- `docs/product/features/<feature-slug>/README.md`：写稳定 feature 的定义、用户价值、长期边界、owner 和相关 increments；不写阶段交付细节。
- `docs/product/features/<feature-slug>/requirements.md`：写该稳定 feature 的长期能力需求、用户路径和非目标；不写某个阶段的具体交付任务。
- `docs/product/increments/<increment-id>/definition.md`：写 active stage、covered/excluded Stage Scope Item IDs、primary feature、affected features、scope、non-goals、upstream decision 和 required artifacts；不写验收用例或实现计划。
- `docs/product/increments/<increment-id>/requirements.md`：写本次增量的用户目标、用户路径、成功标准、非目标、假设和开放问题；不写 API 字段、prompt schema、UI 布局或代码实现。
- `docs/product/increments/<increment-id>/spec.md`：写本次增量的状态、输入输出、状态、依赖、失败路径、模块影响和测试映射；不写代码实现或产品优先级决策。
- `docs/product/increments/<increment-id>/acceptance.md`：写本次增量可观察 pass/fail 行为；不写类名、函数名、数据库字段或测试实现。
- `docs/product/increments/<increment-id>/traceability.md`：写本次增量的 `Requirement -> AC -> Test Case ID -> Contract -> Code Evidence -> Test Evidence -> Status`；不新增需求或替代验收标准。
- `docs/product/increments/<increment-id>/swc_allocation.md`：写本次增量的 Existing Implementation Baseline、Delta From Existing Baseline、`Stage Scope ID -> FR -> Spec -> AC -> FE SWC -> BE SWC -> API/OpenAPI -> Domain Entity -> DB Table/Migration -> Provider/AI Boundary -> TC` 分配、SWC 间数据流、复用要求和禁止重复实现边界；不新增需求、不改验收标准、不复制 OpenAPI schema、不定义领域实体语义、不写代码实现。
- `docs/product/features/<feature-slug>-requirements.md`：写假设、目标、用户路径、入口、涉及数据、成功标准、非目标、开放问题；不写实现细节。
- `docs/product/features/<feature-slug>-spec.md`：写功能规格、状态、输入输出、依赖、失败情况、模块影响和测试映射；不写代码实现。
- `docs/product/acceptance_criteria.md`：写可通过/失败判断的用户可观察行为；不写类名、函数名或数据库字段。
- `docs/product/traceability_matrix.md`：写 `FR -> User Story -> AC -> Test Case ID -> Code Evidence -> Test Evidence -> Status`，用于证明需求覆盖完整性；不新增需求、不替代验收标准、不把 100% 覆盖表述为代码行覆盖率或线上零缺陷保证。
- `docs/architecture/software_component_architecture.md`：写全局 SWC 架构基准，包括系统级职责分配、SWC 拓扑、稳定 `SWC-FLOW-*`、canonical SWC-to-SWC sequence、局部变更参考基准和历史迁移说明；不复制 SWC Catalog 的完整组件字段表、不替代增量 `swc_allocation.md`、不定义 Domain Schema 或 OpenAPI schema。
- `docs/architecture/swc_catalog.md`：写稳定 SWC 目录，包括 SWC ID、layer、code path、职责、非职责、provided/required interfaces、数据所有权、持久化所有权、测试责任、必须复用和禁止绕过；不复制 Domain Schema、OpenAPI request/response schema、prompt schema、UX layout 或实现报告。
- `docs/domain/<domain>_model.md`：写实体、关系、生命周期、状态机和约束；不写 API response 或 UI 布局。
- `docs/architecture/api_contract.md`：写接口路径、请求、响应、错误、兼容性和示例；不写数据库实现或 prompt 文案。
- `docs/ai_runtime/prompt_contract.md`：写 LLM 输入、输出、禁止决策、fallback 和示例；不让 LLM 拥有持久状态更新权。
- `docs/ux/screen_spec.md`：写页面目标、组件、状态、交互、加载、空态、错误和成功状态；不写产品战略或后端实现。
- `docs/reports/implementation_report.md`：写实际完成范围、文件、验证、风险和后续；不补写需求或替代验收标准。
- `docs/reports/quality_report.md`：写审查发现、风险、阻塞项和质量结论；不新增产品范围。

## Process
1. 判断目标文档类型和主要读者。
2. 对照内容契约基线，列出应包含和不应包含的内容。
3. 检查文档是否混入上游战略、下游设计或实现报告内容。
4. 检查是否缺少状态、假设、非目标、验收检查或上游/下游引用。
5. 对发现的问题按阻塞、重要、建议分类。
6. 如需修正规则，更新对应生成类 skill 或 `docs/process/skill_quality_standard.md`。
7. 完成后运行 `python scripts/validate_agent_skills.py`，若修改了 skill。

## Red Flags
- 需求文档写 API 字段、数据库表或 UI 布局。
- feature spec 补写产品愿景，导致产品级 source of truth 分散。
- 验收标准描述实现方式而不是可观察行为。
- 追溯矩阵缺少 FR、AC、Test Case ID、Code Evidence 或 Test Evidence，或把缺测试项写成已覆盖而没有人工验收/外部服务依赖/暂不可自动化说明。
- 把测试报告、feature spec 或验收标准正文当作追溯矩阵 source of truth。
- 实现报告补写需求或跳过缺失的验收标准。
- Prompt 契约允许 LLM 直接更新持久状态。
- SWC allocation 写成实现计划或代码任务清单，却没有 FR/AC 到 SWC/API/domain/DB/test 的分配。
- SWC allocation 缺少 Existing Implementation Baseline，或者没有列出现有用户流、代码路径、SWC、Flow ID、API、数据归属、测试和不可回归行为。
- SWC allocation 缺少 Delta From Existing Baseline，或者没有列出复用 SWC/Flow、允许新增代码、禁止新增代码、允许修改的旧代码和回归证明。
- SWC allocation 没有引用全局 SWC 架构基准或 `SWC-FLOW-*`，导致局部设计无法判断是否偏离稳定架构。
- 全局 SWC 架构基准复制 `swc_catalog.md` 的完整组件字段表，导致拓扑/流基准和组件目录职责混杂。
- SWC catalog 复制 OpenAPI 或 Domain Schema 字段，导致 source of truth 冲突。

## Verification
- 文档目的、读者、必需内容和禁止内容清晰。
- 文档没有混入不属于该阶段的下游实现细节。
- 上游输入和下游输出明确。
- 内容完整性可以被审查者独立判断。
- 验收标准和追溯矩阵职责分离：前者定义可观察通过/失败行为，后者记录覆盖链路和证据状态。
- 若修改 skill，`python scripts/validate_agent_skills.py` 通过。

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| “都写在一个文档里更完整。” | 完整不等于清晰，不同文档有不同生命周期和读者。 |
| “先把实现想法写进需求，后面再删。” | 需求一旦混入实现方案，会限制后续设计并污染验收标准。 |
| “这只是内部文档，不需要边界。” | 内部文档会驱动代码和测试，边界不清会直接制造返工。 |
