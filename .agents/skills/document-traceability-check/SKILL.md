---
name: document-traceability-check
description: Use when project documentation needs a workflow traceability audit across requirements, feature specs, acceptance criteria, domain/API/AI/UX contracts, tests, implementation reports, quality reports, or release notes. Do not use for deciding document paths or defining document templates.
---

# Document Traceability Check

## Overview
检查项目文档链路是否可追踪，确保需求、规格、验收、契约、测试、实现报告和质量报告之间没有断链、重复链、过期引用或缺失状态。

## When to Use
- 需要检查一个 feature 是否具备完整文档链路。
- 需要确认需求是否能追踪到验收标准、测试和实现报告。
- 需要发现断链、重复 source of truth、过期引用或未接受的变更。
- 发布前需要审查文档证据是否足够支持完成定义。
- 用户询问某个需求现在推进到 workflow 的哪一步。
- 需要检查全量系统架构、平台架构、商业化架构或技术栈决策是否覆盖 Product Base、当前基线、feature registry、stage、increment、契约、测试和发布门禁。

## When NOT to Use
- 只需要决定文档放哪里；使用 `document-path-governance`。
- 只需要判断单份文档内容边界；使用 `document-content-contract`。
- 只需要生成缺失文档；使用对应生成类 skill。
- 只需要运行测试或代码审查。

## Inputs
- `docs/process/workflow.md`
- `docs/process/definition_of_done.md`
- `docs/process/change_request.md`
- `docs/product/vision.md`
- `docs/product/mvp_scope.md`
- `docs/product/base/requirements.md`
- `docs/product/base/spec.md`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`
- `docs/product/stages/`
- `docs/product/increments/`
- `docs/product/user_stories.md`
- `docs/product/acceptance_criteria.md`
- `docs/product/traceability_matrix.md`
- `docs/product/features/*.md`
- `docs/domain/*.md`
- `docs/architecture/*.md`
- `docs/architecture/software_component_architecture.md`
- `docs/architecture/swc_catalog.md`
- `docs/product/increments/<increment-id>/swc_allocation.md`
- `docs/ai_runtime/*.md`
- `docs/ux/*.md`
- `docs/reports/*.md`
- `docs/release/*.md`

## Outputs
- 文档链路审查结论。
- 缺失文档、断链、重复引用、过期引用和状态不一致清单。
- 下一步 workflow 建议。
- 用户要求持久化时，将追踪检查摘要写入 `docs/reports/quality_report.md`。
- Increment Test Evidence 复核结论：确认 `AC -> TC -> 测试脚本/执行命令/结果/证据报告 -> traceability Test Evidence` 链路是否完整。

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- 追踪检查默认在最终回复中输出。
- 持久化追踪审查写入 `docs/reports/quality_report.md`。
- 不创建新的需求、规格或契约文档；发现缺失时只列为下一步，由对应 skill 生成。
- 检查链路时使用仓库相对路径引用文档。

## Traceability Model
标准链路：

```text
docs/product/vision.md
docs/product/mvp_scope.md
  -> docs/product/base/requirements.md
  -> docs/product/base/spec.md
  -> docs/product/base/acceptance.md
  -> docs/product/base/traceability.md
  -> docs/product/features/<feature-slug>-requirements.md
  -> docs/process/change_request.md
  -> docs/product/features/<feature-slug>-spec.md
  -> docs/product/acceptance_criteria.md
  -> docs/product/traceability_matrix.md
  -> docs/domain/<domain>_model.md
  -> docs/architecture/api_contract.md
  -> docs/architecture/software_component_architecture.md
  -> docs/architecture/swc_catalog.md
  -> docs/product/increments/<increment-id>/swc_allocation.md when implementation-impacting
  -> docs/ai_runtime/prompt_contract.md
  -> docs/ux/screen_spec.md
  -> test/、backend/src/test/java/ 或 tests/
  -> docs/reports/implementation_report.md
  -> docs/reports/quality_report.md
  -> docs/release/release_checklist.md
```

不是每个 feature 都必须触达所有下游文档；但跳过某个下游文档时，必须有明确原因或“不适用”说明。

新 increment 标准链路：

```text
Stage Scope ID
  -> docs/product/increments/<increment-id>/definition.md
  -> docs/product/increments/<increment-id>/requirements.md
  -> docs/product/increments/<increment-id>/spec.md
  -> docs/product/increments/<increment-id>/acceptance.md
  -> docs/product/increments/<increment-id>/test_cases.md
  -> docs/product/increments/<increment-id>/traceability.md
  -> docs/architecture/software_component_architecture.md / SWC-FLOW-* when implementation-impacting
  -> docs/product/increments/<increment-id>/swc_allocation.md when implementation-impacting
  -> docs/domain/ 或 docs/architecture/ 或 docs/ai_runtime/ 或 docs/ux/ when applicable
  -> test/、backend/src/test/java/ 或 tests/
  -> docs/reports/implementation_report.md
  -> docs/reports/quality_report.md
  -> docs/release/release_checklist.md when release scope is affected
```

`100% traceability` for committed stage work means every required Stage Scope Item ID is covered by at least one increment or has an explicit deferred/not-applicable decision, every increment requirement traces back to at least one Stage Scope Item ID, every FR has at least one AC, every AC maps to stable TC IDs or explicit exceptions, implementation-impacting ACs map to the global SWC architecture baseline/Flow ID and SWC allocation rows or explicit no-SWC-impact decisions, every AC has code/test evidence or a documented exception once implementation has started, and release evidence exists when the increment affects release scope.

Increment Test Evidence review must verify:
- every AC listed in increment acceptance appears in the increment test case library or has an allowed exception;
- every TC row cites the owning traceability row;
- every automated or planned automated TC has a test script path and execution command;
- every executed TC has result status and evidence report;
- the owning increment traceability row has Test Evidence that cites the TC ID, script path, command, result status, and evidence report, or a documented exception.

## Architecture Traceability Gate
当检查系统架构、技术栈、前后端数据库方案、商业化架构或全量 APP 架构时，必须增加以下检查：

- 判定架构范围模式：`whole-app`、`stage`、`increment`、`feature`、`refactor` 或 `experiment`。
- `whole-app` 架构必须覆盖 Product Base、当前 APP baseline、feature registry、roadmap、development status、active stages、planned increments、future-stage boundaries 和 explicit non-goals。
- 架构文档必须包含 feature/stage coverage matrix；每个 stable feature、active stage、planned increment 至少映射到 frontend、backend、data、API、AI/runtime、security、test、release 中的适用项或明确 `not applicable`。
- 技术栈推荐必须能追溯到 requirements、constraints、trade-offs 和至少两个 viable options。没有 option comparison 的技术栈只能标记为 exploratory。
- 代码实现前架构必须能追溯到全局 SWC 架构基准、SWC Catalog、increment SWC allocation、Existing Implementation Baseline 和 Delta From Existing Baseline；实现影响前端、后端、数据库、API、AI runtime、provider、复用模块或 server-owned facts 时，缺少 `docs/architecture/software_component_architecture.md`、`SWC-FLOW-*` 引用、`swc_allocation.md`、旧实现继承证据、delta-only 设计或明确 no-SWC-impact 决策，只能标记为 Blocked 或 Conditional。
- ADR 只能记录通过 coverage gate 的重大决策；未覆盖全量范围的 ADR 不能作为全量架构 source of truth。
- 架构输出如果缺少覆盖矩阵、遗漏范围说明、市场方案对比或下游契约缺口，结论必须是 `Blocked` 或 `Conditional`，不得标记为完整通过。

## Process
1. 确定要检查的 feature、变更请求或文档范围。
2. 找到最上游来源：产品定位、MVP 范围、需求收敛或变更请求。
3. 判断 AC 来源模式：Product Base 稳定需求库、当前 MVP 代码基线固化，或标准 P0/新增 increment workflow。
4. 对标准 increment workflow，先检查 active stage 是否有稳定 Stage Scope Item IDs，以及 increment definition 是否列出 `Covered Stage Scope Items` 和 `Excluded Stage Scope Items`。
5. 当前 MVP 代码基线固化时，检查 AC 是否基于主需求文档、MVP scope、用户故事和实际代码证据；P0/新增功能时，检查 AC 是否以已批准 increment spec 为直接输入，并保留 Stage Scope Item IDs。
6. 沿 workflow 检查是否存在 feature/increment spec、验收标准、强制追溯矩阵、相关契约、测试和报告。
7. 检查新 increment 链路是否完整：每个 required Stage Scope ID 有 increment 覆盖或明确 deferred/not applicable；每个 FR 至少有 1 个 AC；每个 AC 反向引用 1 个或多个 FR 和上游 Stage Scope ID；每个 AC 映射到 stable TC ID 或明确例外；Code Evidence 不为空；Test Evidence 不为空或有明确例外。
8. 对 implementation-impacting increment 检查 `swc_allocation.md`：每个受影响 FR/AC 是否映射到 FE SWC、BE SWC、API/OpenAPI、Domain Entity、DB Table/Migration、Provider/AI Boundary、TC 或明确 `N/A - <reason>`，并是否引用全局 SWC 架构基准和适用 `SWC-FLOW-*` ID。
9. 对 brownfield/refactor increment 检查 Existing Implementation Baseline 和 Delta From Existing Baseline：是否列出现有用户流、代码路径、SWC、Flow ID、API、数据归属、测试、不可回归行为、复用 SWC/Flow、允许/禁止新增代码、允许修改旧代码、迁移/废弃和回归证明。
10. 检查 SWC allocation gate evidence：implementation-impacting PR 是否运行或计划运行 `python3 scripts/check_swc_allocation.py --scope changed --base-ref <base-ref>`；若变更场景对话路径，是否引用 `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME` 和 `FE-SCENARIO-PRACTICE` / `FE-PRACTICE-RUNTIME`。
11. 对 increment Test Evidence 执行 `AC -> TC -> 测试脚本/执行命令/结果/证据报告 -> traceability Test Evidence` 复核；缺少 TC ID、脚本路径、执行命令、结果状态或证据报告时，不得通过完成审查。
12. 检查 Product Base 链路时，检查 `FR -> User Story -> AC -> Code Evidence -> Test Evidence -> Status` 是否完整。
13. 标记缺失、不适用、重复、过期或状态冲突。
14. 检查 accepted/proposed/deferred 等状态是否和实际推进阶段一致。
15. 输出断链清单和下一步建议；不直接生成缺失文档。
16. 若修改 skill 或质量标准，运行 `python scripts/validate_agent_skills.py`。

## Red Flags
- P0 或新增功能代码实现存在，但没有 feature spec 或验收标准；当前 MVP 反向固化任务必须显式标记为代码基线例外。
- P0 或新增功能存在 AC，但没有已批准 feature spec 作为直接上游。
- acceptance criteria 和 requirements 之间没有强制追溯矩阵。
- 需求仍是 proposed，但下游已经按 accepted 实现。
- acceptance criteria 没有对应测试或测试报告说明。
- 测试阶段才开始定义 FR/AC 覆盖关系，而不是在 acceptance criteria 阶段建立。
- 代码实现已经开始，但 implementation-impacting FR/AC 没有 `swc_allocation.md` 或 no-SWC-impact 决策。
- implementation-impacting increment 没有引用全局 SWC 架构基准或适用 `SWC-FLOW-*`，局部 SWC flow 也没有 `one-off`、`proposed-global` 或 `legacy-compatible` 分类。
- brownfield/refactor increment 缺少 Existing Implementation Baseline 或 Delta From Existing Baseline，导致后续设计没有基于已有功能和代码实现。
- changed implementation path 没有被 owning `swc_allocation.md` 的旧实现基线、允许新增代码或允许修改旧代码覆盖。
- SWC allocation 只写“前端实现/后端实现”，没有映射到具体 SWC、API/OpenAPI、Domain Entity、DB Table/Migration 和 TC。
- SWC allocation 绕过现有 SWC 或 cross-cutting boundary，新增重复组件却没有迁移/废弃理由。
- `FR`、`AC`、`Code Evidence` 或 `Test Evidence` 字段为空且无明确例外。
- Stage scope is written only as bullets with no stable Stage Scope Item IDs for committed work.
- Increment definition lacks `Covered Stage Scope Items`, or requirements/spec/AC drop those IDs downstream.
- 100% traceability is claimed while a required Stage Scope Item ID is uncovered, deferred without reason, or not represented in the increment traceability matrix.
- Increment traceability Test Evidence cites a test report but not the owning TC ID, script path, execution command, or result status.
- prompt/schema/API 变更没有对应契约文档。
- implementation report 声称完成，但没有验证命令或测试缺口说明。
- 全量架构只基于最新 change request 或 active stage，没有覆盖 Product Base、baseline、feature registry 和 future stages。
- 架构文档先给技术栈结论，却没有需求覆盖矩阵、约束、市场方案比较和 omitted-scope 列表。
- 架构 ADR 被接受，但其上游架构方案仍是 exploratory、conditional 或 coverage-blocked。

## Verification
- 每个检查对象都有上游来源。
- 缺失链路被明确标记为缺失或不适用。
- 下一步建议对应 workflow 的具体阶段。
- 没有把追踪检查变成内容生成。
- 必要时质量报告保留审查结论。
- AC 来源模式被明确判定，且不和当前 phase 冲突。
- 需求覆盖完整性已通过追溯矩阵检查；该结论不被表述为代码行覆盖率或线上零缺陷保证。
- 新 increment 追溯检查确认 Stage Scope ID coverage、increment coverage、FR coverage、AC coverage 和 evidence status 均有结论。
- Increment Test Evidence 复核确认 AC-to-TC mapping、script path、execution command、result status、evidence report 和 traceability Test Evidence 一致。
- 架构检查已明确范围模式，并给出 coverage matrix 通过、条件通过或阻塞结论。
- 全量架构没有把 future-stage、P1/P2 或商业发布门禁遗漏为隐性非目标。
- Implementation-impacting increment 的全局 SWC 架构基准、`SWC-FLOW-*`、SWC allocation 覆盖受影响 FR/AC，且没有替代 Domain Schema、OpenAPI、AI runtime、UX、测试或发布 source of truth。
- Brownfield/refactor increment 的 Existing Implementation Baseline、Delta From Existing Baseline 和 `scripts/check_swc_allocation.py` gate evidence 已覆盖受影响代码路径，防止另造轮子或不读旧方案。

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| “文档以后补也可以。” | 没有链路就无法判断实现是否满足原始需求。 |
| “测试通过说明需求没问题。” | 测试只能证明已写的断言，不能替代需求和验收边界。 |
| “这是小改动，不需要报告。” | 小改动也可能改变契约或用户行为，必须判断链路是否受影响。 |
