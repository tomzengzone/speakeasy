---
name: document-path-governance
description: Use when project documentation needs a canonical path, document owner, source-of-truth decision, path template, or skill/agent input-output path audit. Do not use for judging whether the content inside an already correctly placed document is complete or well scoped.
---

# Document Path Governance

## Overview
治理项目文档的存储位置、维护者、输入输出路径、引用关系和 source of truth，确保文档不会因为路径不清而散落、重复或被错误 agent 修改。

## When to Use
- 需要决定某类文档应该放在哪个目录或文件。
- 需要定义或审查 `docs/` 下的 canonical path。
- 需要审查 `.agents/skills/*` 的 `Inputs`、`Outputs`、`文档路径约定`。
- 需要审查 `codex/agents/*.md` 的 `Inputs`、`Outputs`、`Allowed Paths`。
- 发现同类文档存在多个位置，或新文档可能重复已有 source of truth。
- 需要迁移、重命名、废弃或合并文档路径。

## When NOT to Use
- 文档路径已经明确，只需要判断内容是否完整；使用 `document-content-contract`。
- 需要检查需求到测试的链路是否断开；使用 `document-traceability-check`。
- 需要生成具体需求、规格、API 契约或报告正文；使用对应生成类 skill。
- 只处理业务代码或测试代码，不涉及文档路径。

## Inputs
- `docs/process/workflow.md`
- `docs/process/definition_of_done.md`
- `docs/process/skill_quality_standard.md`
- 当前 `docs/` 目录结构
- `.agents/skills/*/SKILL.md`
- `.agents/skills/*/SPEC.md`
- `codex/agents/*.md`
- 用户提供的新文档类别、目标产物或路径冲突说明。

## Outputs
- 文档路径归属决策。
- 更新后的 `docs/process/skill_quality_standard.md` 路径规则。
- 更新后的 `.agents/skills/<skill>/SKILL.md` 和 `.agents/skills/<skill>/SPEC.md` 路径说明。
- 更新后的 `codex/agents/*.md` 输入、输出或 Allowed Paths。
- 用户要求持久化时，将路径审查摘要写入 `docs/reports/quality_report.md`。

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 产品愿景与定位：`docs/product/vision.md`
- 产品路线图：`docs/product/roadmap.md`
- 产品开发状态：`docs/product/development_status.md`
- 产品功能注册表：`docs/product/feature_registry.md`，V2 canonical registry，记录 `Capability ID`、`Capability slug`、`Capability name`、业务边界、owner、一级 `Sub-capability ID`、相邻能力、下游文档前缀和 `Legacy Mapping`
- 产品总需求库：`docs/product/base/requirements.md`
- 产品总规格库：`docs/product/base/spec.md`
- 产品总验收库：`docs/product/base/acceptance.md`
- 产品总追溯库：`docs/product/base/traceability.md`
- 产品基线：`docs/product/baselines/<baseline-slug>.md`
- V1 功能注册表冻结快照：`docs/product/baselines/feature-registry-v1-<date>.md`，archived baseline，不是 active source of truth、compatibility source 或新增下游输入
- 阶段范围：`docs/product/stages/<stage-id>.md`
- 增量定义：`docs/product/increments/<increment-id>/definition.md`
- 增量需求：`docs/product/increments/<increment-id>/requirements.md`
- 增量规格：`docs/product/increments/<increment-id>/spec.md`
- 增量验收：`docs/product/increments/<increment-id>/acceptance.md`
- 增量测试用例库：`docs/product/increments/<increment-id>/test_cases.md`
- 增量追踪：`docs/product/increments/<increment-id>/traceability.md`
- 增量 SWC 分配：`docs/product/increments/<increment-id>/swc_allocation.md`
- 用户故事：`docs/product/user_stories.md`
- 变更请求：`docs/process/change_request.md`
- 工作流程：`docs/process/workflow.md`
- 完成定义：`docs/process/definition_of_done.md`
- skill 质量标准：`docs/process/skill_quality_standard.md`
- 软件组件架构治理：`docs/process/software_component_architecture_governance.md`
- 架构总览：`docs/architecture/system_overview.md`
- 模块边界：`docs/architecture/module_boundary.md`
- 全局 SWC 架构基准：`docs/architecture/software_component_architecture.md`
- SWC 目录：`docs/architecture/swc_catalog.md`
- API 契约：`docs/architecture/api_contract.md`
- OpenAPI source of truth：`docs/architecture/openapi/speakeasy-api.yaml`
- 数据流：`docs/architecture/data_flow.md`
- 架构决策：`docs/architecture/adr/<id>-<slug>.md`
- 领域总模型：`docs/domain/domain_schema.md`
- 实体关系：`docs/domain/entity_relationship.md`
- 领域专项模型：`docs/domain/<domain>_model.md`
- AI prompt 契约：`docs/ai_runtime/prompt_contract.md`
- AI 输出 schema：`docs/ai_runtime/llm_output_schema.md`
- AI fallback：`docs/ai_runtime/fallback_strategy.md`
- AI 评测用例：`docs/ai_runtime/ai_eval_cases.md`
- 对话状态机：`docs/ai_runtime/dialogue_state_machine.md`
- UX 页面规格：`docs/ux/screen_spec.md`
- 用户流程：`docs/ux/user_flow.md`
- 可用性检查：`docs/ux/usability_checklist.md`
- 文案指南：`docs/ux/copywriting_guideline.md`
- 测试报告：`docs/reports/test_report.md`
- 质量报告：`docs/reports/quality_report.md`
- 实现报告：`docs/reports/implementation_report.md`
- 发布检查：`docs/release/release_checklist.md`
- 回滚计划：`docs/release/rollback_plan.md`
- 版本记录：`docs/release/version_log.md`

## Product Object Path Rules
- 新增产品工作必须先判断对象类型：feature、stage、increment、baseline、change request 或 artifact。
- Capability 是 APP 长期稳定产品分类，登记在 `docs/product/feature_registry.md`，使用 V2 `Capability ID` / `Sub-capability ID` 作为下游 requirements、spec、AC、TC、stage scope 和 increment definition 的引用入口，不分配独立 feature 文档目录。
- Stage / increment 是交付结构，capability / sub-capability 是稳定产品分类；不得用 MVP、P0.1、P0.2、Now、Next、Later 等阶段名作为 `Capability slug` 或 `Capability ID`。
- V1 slug 只允许通过 active registry 的 `Legacy Mapping` 做历史追溯；`docs/product/baselines/feature-registry-v1-<date>.md` 是 archived baseline，不得作为 active source of truth、compatibility source 或新增下游输入。
- Stage 只描述阶段目标、入口/出口和纳入/排除的 increment，不承载需求正文或 implementation plan。
- Increment 是实际交付切片，需求、规格、验收、测试用例库和追踪优先写入 `docs/product/increments/<increment-id>/`。
- Product Base 是需求初版/稳定 Product Base，记录已接受稳定产品行为，归入 `docs/product/base/`。
- Baseline 是从 Product Base 冻结出的阶段、版本、发布或审计快照，只记录该冻结点的事实和回归边界，不得替代活的 Product Base。
- 迁移旧文档前必须列出旧路径、新路径、引用更新点和回滚方式。

## Process
1. 识别文档类型：产品、需求、规格、验收、架构、领域、API、AI runtime、UX、测试、报告、发布、skill 或 agent。
2. 对照文档路径约定选择默认路径；若已有同类文档，优先更新已有 source of truth。
3. 判断是否需要新增路径模板；新增前确认现有目录无法承载。
4. 检查相关 skill 的 `Inputs`、`Outputs`、`文档路径约定` 和 `SPEC.md` 是否写明具体路径或路径模板。
5. 检查相关 agent 的 `Inputs`、`Outputs` 是否被 `Allowed Paths` 覆盖。
6. 若需要迁移路径，列出旧路径、新路径、引用更新点和迁移风险。
7. 完成后运行 `python scripts/validate_agent_skills.py`。

## Red Flags
- 同一类文档存在多个主位置，但没有 source-of-truth 说明。
- skill 输出写成 `updated docs`、`feature-specific notes`、`report updates`，但没有具体路径。
- agent 的 Outputs 不在 Allowed Paths 内。
- 新建目录只是为了当前任务方便，和现有 `docs/` 分类不一致。
- 变更请求、规格文档、验收标准和实现报告之间路径无法互相引用。
- 需求、验收标准、代码证据和测试证据的追溯矩阵没有 canonical path，或被写入验收标准正文导致职责混杂。
- SWC 目录、module boundary、domain schema、OpenAPI、increment swc allocation 互相重复定义同一事实源。

## Verification
- 每个新增或修改文档都有明确路径。
- 每个相关 skill 的文档输入输出路径不需要靠推断。
- 每个相关 agent 的 Outputs 被 Allowed Paths 覆盖。
- 不存在明显重复 source of truth。
- API 契约总览与机器可执行 OpenAPI 不得互相竞争：`docs/architecture/api_contract.md` 记录契约边界、追溯、错误模型、版本和兼容策略；`docs/architecture/openapi/speakeasy-api.yaml` 是 request/response schema、paths、components 和 OpenAPI lint 的唯一 source of truth。
- 全局 SWC 架构基准、SWC 目录与增量 SWC 分配不得互相替代：`docs/architecture/software_component_architecture.md` 记录完整 SWC 拓扑、稳定 `SWC-FLOW-*` 和局部变更参考基准；`docs/architecture/swc_catalog.md` 记录稳定组件职责边界；`docs/product/increments/<increment-id>/swc_allocation.md` 记录已批准增量的 FR/AC 到 SWC/API/domain/DB/test 分配。
- Product Base 强制追溯矩阵使用 `docs/product/base/traceability.md`；increment 强制追溯矩阵使用 `docs/product/increments/<increment-id>/traceability.md`。
- `python scripts/validate_agent_skills.py` 通过。

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| “先随便放一个位置，后面再整理。” | 文档路径一旦被引用就会固化，后续迁移成本更高。 |
| “这个 skill 知道该写哪里，不用写路径。” | 下一次执行可能由另一个 agent 完成，路径必须显式。 |
| “一个大文档更方便。” | 大文档会模糊职责边界，需求、契约、报告需要不同生命周期。 |
