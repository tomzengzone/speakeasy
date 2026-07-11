# Codex Development Workflow

## Product Planning Layer
```text
user request
-> Product Manager intake
-> product classification
-> optional issue-management tracking when repository issue tracking is needed
-> V2 capability registry / stage scope check
-> increment definition
-> roadmap / development status update
-> PM execution brief
```

Product Manager is the unified user-facing entry point. It decides the active stage goal, backlog priority, roadmap horizon, accepted/deferred scope, and current progress status. Users should not need to choose specialist agents directly.

## Product Object Model
```text
Capability = long-lived product capability registered by V2 Capability ID / Sub-capability ID
Product Base = living source of truth for accepted product requirements, specs, acceptance, and traceability
Stage = delivery horizon or priority window
Stage Scope Item = stable, ID-addressable capability or obligation committed, deferred, or marked not applicable inside a stage
Increment = scoped delivery slice inside a stage
Test Case Library = canonical AC-to-TC design artifact for an increment before implementation starts
Baseline = frozen snapshot of Product Base at a stage, version, release, or audit point
Change Request = decision record for scope change
Artifact = requirements, spec, acceptance, contracts, tests, reports, release evidence
```

Capability 和 stage 是两条独立轴线；capability 不是 stage，stage 也不是 capability。`Capability ID` 与 `Sub-capability ID` 来自 V2 registry `docs/product/feature_registry.md`；`Stage Scope ID` 描述阶段交付承诺，不得替代 capability ID。Product Base 是活的产品需求库。已接受稳定行为的 requirements、specs、acceptance criteria 和 traceability 位于 `docs/product/base/`。Increment artifacts 在完成并被批准 merge back into Product Base 前，位于 `docs/product/increments/<increment-id>/`。Increment test case library 位于 `docs/product/increments/<increment-id>/test_cases.md`，是 implementation 开始前 AC-to-TC design 的 source of truth。`docs/product/baselines/` 下的 baselines 是冻结快照，不得替代 Product Base。

## Execution Layer
```text
PM execution brief -> Development Orchestrator -> workflow gate check -> specialist agents -> validation evidence -> PM status update -> user summary
```

Development Orchestrator is the internal execution dispatcher. It does not decide whether a product goal is worth doing; it decides which workflow step is currently legal and necessary for approved scope.

## Standard Flow
```text
idea/change intake
-> product classification
-> V2 capability registry / stage scope check
-> increment definition
-> requirement development
-> increment spec
-> acceptance criteria
-> test case library / AC-to-TC mapping
-> architecture/domain/API/screen/AI specs
-> software component architecture / SWC allocation
-> implementation plan
-> code
-> tests
-> review
-> report
-> product base merge when done
-> optional baseline freeze
-> release
```

Requirement Development 负责 scoped feature/change 的 requirement quality。Development Orchestrator 负责 workflow routing、cross-module execution 和 Definition of Done verification。

## Direct-Upstream Input Rule
开发文档按逐级细化模型传递输入。每个 artifact 只把本层直接上游作为行为生成输入，并保留必要的 scope guard；不得把完整上游链重复塞入每个下游文档。

```text
User Story / Vertical Slice -> FR -> Spec -> AC -> TC -> implementation evidence
```

- Requirement：直接上游是已批准 User Story / Vertical Slice；Stage、Increment 和 Capability 只做交付范围或边界分类。
- Spec：直接上游是已批准 FR；Vertical Slice 只做 scope guard / provenance。
- AC：直接上游是已批准 Spec，必要时引用相关 FR 做覆盖说明。
- TC：直接上游是 AC 和 Spec，并携带 Increment/WP、执行与证据字段。
- SWC allocation：直接上游是 Spec、AC、WP 和 Existing Implementation Baseline。
- Implementation/Test Report：引用 `Traceability Row ID`、WP、AC、TC 和实际证据，不重复整条产品链。

完整 `Story/Slice -> FR -> Spec -> AC -> TC -> SWC/Code/Test Evidence` join 只在 owning `docs/product/base/traceability.md` 或 `docs/product/increments/<increment-id>/traceability.md` 中维护，并由 `document-traceability-check` 统一审查。

## Required Gates
1. Product classification 完成前，不创建 feature/increment document。
2. V2 capability registry 和 stage scope 确认前，不创建 requirements/spec/acceptance artifact。
3. 没有稳定 Stage Scope Item ID，且每个 required item 没有 increment coverage decision 时，committed stage work 不得推进。
4. Increment spec 完成前，不开始 implementation。
5. Approved AC 尚未映射到 `docs/product/increments/<increment-id>/test_cases.md` 中的稳定 TC ID 或明确例外前，不开始 implementation。
6. Contract update 完成前，不开始 cross-layer implementation。
7. Global SWC architecture baseline 未被引用或更新，且 owning increment 没有带适用 `SWC-FLOW-*` reference 的 `docs/product/increments/<increment-id>/swc_allocation.md` 或明确 `N/A - no SWC impact` decision 前，不开始 cross-layer 或 SWC-impacting implementation。
8. Schema definition 完成前，不做 AI UI rendering。
9. 没有测试或 documented test gap 时，不得标记 completion。
10. 没有 release checklist 时，不得 release。
11. Acceptance、traceability、适用时的 SWC allocation、implementation、test 和 report evidence 未完成或未明确例外前，increment 不得 merge into Product Base。
12. Multi-step product、architecture、software component 或 documentation governance task，在独立 checker agent 对已完成步骤返回 pass finding 前，不得进入下一步。
13. 除非用户明确指定其他语言，新增或修改的持久化项目文档自然语言必须使用中文；若保留英文原文，英文正文块后必须紧跟中文翻译，并通过 document language gate。

## 文档语言门禁
持久化项目文档默认使用中文，覆盖 `docs/` 和 `codex/templates/` 下的 Markdown 输出。技术标识、代码路径、API 名称、OpenAPI 字段、SWC ID、测试 ID、命令和机器解析字段可以保留英文。若文档需要保留英文原文，必须使用源文件内双语格式：英文正文块后紧跟对应中文翻译或中文等价说明。

CI 通过 `scripts/check_document_language.py` 检查 changed scope，防止新生成或修改的项目文档出现没有中文对应说明的英文段落。本地验证命令：

```bash
python3 scripts/check_document_language.py --scope changed --include-worktree
```

## Cross-Cutting Boundary Registry
`docs/process/cross_cutting_boundary_registry.md` 是 reusable cross-cutting boundary 的 governance registry，覆盖 media/audio refs、AI provider usage、OpenAPI/generated clients、entitlement、Goal Autopilot facts、data governance 和 issue tracking 等边界。

Cross-layer implementation 开始前，Development Orchestrator 和 specialist agent 必须检查工作是否触碰已登记 Boundary ID。若触碰，implementation plan 必须引用授权条目、复用的 module/API/service、forbidden bypass、legacy exception 或 migration need，以及 evidence gate。新的 cross-cutting capability 在被实现作为稳定边界使用前，必须先登记。

`python scripts/check_cross_cutting_boundaries.py --scope changed --base-ref <base-ref>` 是针对新增变更文件的 repository automation guard。CI 以 changed-only mode 运行它，确保新增或修改代码不能加入已登记 forbidden bypass；单独追踪的 legacy path 在自己的 slice 中治理。Full-scope scan 可在本地用于 governance audit 和 legacy exception planning。

## Product Classification Gate
Every incoming request must be classified before requirements or specs are created:
- `product-base-consolidation`: consolidates accepted stable product behavior into the living Product Base under `docs/product/base/`.
- `baseline-consolidation`: freezes Product Base into an implemented capability snapshot under `docs/product/baselines/`.
- `new-feature`: adds a long-lived product capability.
- `feature-increment`: changes or extends an existing feature inside a stage.
- `bugfix`: corrects existing behavior without changing product scope.
- `refactor`: changes implementation structure without changing user-visible behavior.
- `experiment`: investigates feasibility and produces findings, not delivery commitment.
- `scope-change`: changes accepted scope and requires `docs/process/change_request.md`.

分类必须识别 primary `Capability ID` / `Sub-capability ID`；当触碰多个 capability 时，还必须识别 affected `Capability ID` / `Sub-capability ID` values、active stage、expected increment，以及是否需要 change request。

## Issue Tracking Boundary
Issue tracking 是可选协作手段，只能在 Product Manager 完成分类后使用，用于协调缺陷、后续项、发布阻塞、流程变更、实现切片、Pull Request 或证据链接。

使用 `.agents/skills/issue-management/` 起草 issue 标题和正文、triage 字段、标签与状态建议、分支或 Pull Request 链接文本以及 source-of-truth 链接。Issue 只是跟踪容器，不得替代 Product Manager 分类、roadmap priority、Product Base、increment requirements/specs/acceptance/test cases/traceability、实现报告、测试报告、质量报告或发布证据。

若 issue 与本地产品或流程 artifact 冲突，以本地 artifact 为准，并修正 issue 或将其标记为 blocked。规划、部分切片、调查和阻塞证据使用 `Refs #<id>`；只有 Definition of Done 证据完整后才使用 `Closes #<id>`。

## Increment Definition Gate
Requirement Development 开始前，active increment 必须说明：
- increment id and name
- active stage
- covered Stage Scope Item IDs
- primary `Capability ID` / `Sub-capability ID`
- affected `Capability ID` / `Sub-capability ID` values
- scope and non-goals
- upstream decision source
- required downstream artifacts
- owner agent and checker agent

If the work is product-base consolidation, the artifact must update `docs/product/base/` and must only include accepted stable behavior. If the work is baseline consolidation, the artifact must be marked as a frozen baseline snapshot and must not replace the living Product Base.

## AC-To-TC Implementation Gate
Owning increment 在 `docs/product/increments/<increment-id>/test_cases.md` 中建立 canonical test case library 前，committed increment implementation 不得开始。在 Backend、Frontend、AI Runtime、DevOps 或 QA 执行工作开始前，该 library 必须把每个 approved AC 映射到至少一个稳定 TC ID，或映射到明确允许的例外。

允许的例外是 `manual-verification`、`external-dependency` 或 `not-automatable-yet`，且每个例外必须包含 reason、owner 和 evidence plan。缺失 AC-to-TC mapping 是 workflow blocker，不是 QA follow-up。

## Software Component Architecture Gate
Cross-layer、persistence-impacting、API-impacting、AI-runtime-impacting、provider-impacting 或 reusable-module-impacting implementation，在 System Architect 产出适用 software component architecture artifact 且独立 Software Architecture Governance Check 返回 pass 前不得开始。

Canonical paths：
- Global SWC architecture baseline：`docs/architecture/software_component_architecture.md`
- Global SWC catalog：`docs/architecture/swc_catalog.md`
- Increment SWC allocation：`docs/product/increments/<increment-id>/swc_allocation.md`

`docs/architecture/software_component_architecture.md` 是完整 global SWC architecture baseline。它记录 system-level responsibility allocation、global SWC topology、稳定 `SWC-FLOW-*` ID、canonical SWC-to-SWC sequence，以及 local architecture change 的 reference baseline。它必须引用 `docs/architecture/swc_catalog.md`、`docs/architecture/data_flow.md`、`docs/architecture/module_boundary.md`、Domain Schema 和 OpenAPI，不得复制这些 source-of-truth detail。

`docs/architecture/swc_catalog.md` 是稳定 frontend、backend、database、provider、AI runtime 和 operations SWC 的 reusable inventory。它记录 SWC ID、owner layer、code path、responsibility、explicit non-responsibility、provided interface、required interface、data ownership、persistence ownership、provider ownership、test 和 forbidden bypass。它必须引用 `docs/domain/`、`docs/architecture/api_contract.md` 和 `docs/architecture/openapi/speakeasy-api.yaml`，不得复制 domain 或 OpenAPI schema。

`docs/product/increments/<increment-id>/swc_allocation.md` 是 owning increment 的 implementation-readiness artifact。它必须包含：
- Existing Implementation Baseline：列出当前 accepted user flow、existing code path、existing SWC、existing `SWC-FLOW-*` ID、existing API/OpenAPI call、domain/data ownership、tests/evidence、non-regression behavior 和 known legacy/deprecated parts；
- Delta From Existing Baseline：列出 reused SWC、reused Flow ID、changed behavior、unchanged behavior、new code allowed、new code forbidden、existing code modified、migration/deprecation impact 和 regression proof required；
- baseline references：引用 `docs/architecture/software_component_architecture.md`、适用 `SWC-FLOW-*` ID、referenced SWC Catalog ID，以及继承的 `data_flow.md` / `module_boundary.md` rule；
- frontend、backend、database、third-party provider、AI runtime 和 operations 的 system-level responsibility allocation；
- requirement allocation matrix：`Traceability Row ID -> Increment ID -> WP ID -> FR -> Spec -> AC -> FE SWC -> BE SWC -> API/OpenAPI -> Domain Entity -> DB table/migration -> TC`；
- 每个 core use case 的 SWC-to-SWC data flow，包括 global Flow ID 或 local flow id、success path、failure path、auth、idempotency、retry、rollback/compensation、audit、logging、metrics 和 permission boundary；
- required reuse list 和 forbidden duplicate-build list；
- 对任何未触碰 layer 写出明确 `N/A - <reason>`；
- architecture validation expectation 和 independent checker finding reference。

SWC allocation document 不得重新定义 product scope、requirements、acceptance criteria、domain entity semantics、OpenAPI request/response schema、AI prompt schema、UX layout、test implementation 或 release approval。它只把已批准 scope 分配到 software component，并证明 implementation 可以在没有 ownership ambiguity 和 duplicate component creation 的前提下推进。

Brownfield change 只能写 delta。若 increment 扩展、修复、重构或加固既有能力，其架构不得从全新设计开始。它必须先证明继承了哪些 existing implementation facts，包括 code path 和 test。除非 allocation 解释为什么 accepted component 不能复用，并记录 migration/deprecation ownership，否则禁止新增 SWC、runtime、store、API、migration、provider 或 cache layer。

CI 通过 `scripts/check_swc_allocation.py` 强制执行。PR 如果修改 `lib/`、`backend/src/main/java/`、`backend/src/main/resources/db/migration/` 或 `docs/architecture/openapi/speakeasy-api.yaml` 下的 implementation-impacting path，必须包含覆盖这些 path 的 changed increment `swc_allocation.md`，或包含已接受的 `N/A - no SWC impact` traceability decision。Scenario-practice 变更必须引用 `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME` 和既有 `FE-SCENARIO-PRACTICE` / `FE-PRACTICE-RUNTIME` 边界。

如果 increment 改变 stable SWC topology，或把 local flow 变成 reusable system flow，必须在 implementation planning 前更新 `docs/architecture/software_component_architecture.md` 和 `docs/architecture/swc_catalog.md`；否则 increment 必须携带 accepted `legacy-compatible` exception，并写明 migration owner 和 expiry condition。

## Traceability Ownership And Stage Coverage Gate
每个 active stage 在生成下游 increment artifact 前，必须把 committed scope 暴露为稳定 Stage Scope Item。每个 stage scope file 应包含一张表，列出：

- Stage Scope ID
- Capability
- Required status: `required`, `deferred`, or `not applicable`
- Target increment，或不规划 increment 的原因
- Current status

每个 increment definition 必须包含 `Covered Stage Scope Items` 和 `Excluded Stage Scope Items`。Stage Scope 只作为交付控制上下文；完整产品到证据链只在 owning traceability matrix 中维护：

```text
User Story ID / Vertical Slice ID
-> Increment ID
-> WP ID
-> FR ID
-> Spec ID
-> AC ID
-> TC ID
-> Contract ID, when applicable
-> Global SWC Architecture Baseline / Flow ID, when applicable
-> SWC Allocation Row, when applicable
-> Code Evidence
-> Test Evidence
-> Release Evidence
```

`100% traceability` 只由 owning traceability matrix 判定：每个 committed Slice 有 FR、Spec、AC、TC 和证据行或明确例外；每个 required Stage Scope Item 有 increment coverage 或 deferred/not-applicable decision；每个 implementation-impacting AC 有 SWC allocation 或 no-impact decision；release scope 受影响时存在 release evidence。Local artifact 不因未重复整条链路而失败。

每个 increment test case 必须携带本层直接上游和证据所需字段：`TC ID`, `Traceability Row ID`, `Increment ID`, `WP ID`, `Spec ID`, `AC ID`, `测试层级`, `自动化状态`, `测试脚本路径`, `执行命令`, `结果状态`, `证据报告`, `Gap / Exception`。完整 Story/Slice/FR join 通过 `Traceability Row ID` 回到 owning traceability matrix。

测试执行后，QA 只能更新 owning Product Base 或 increment traceability file 中的 Test Evidence、test status、QA gap notes 和 evidence report link。完成前，traceability check 必须能审查完整 `AC -> TC -> test script path -> execution command -> result status -> evidence report -> Test Evidence` 链路。

## Product Base Gate
`docs/product/base/` 是已接受产品行为的活跃事实源：
- `docs/product/base/requirements.md`
- `docs/product/base/spec.md`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`

当前 MVP legacy artifact 只有在描述已实现或已接受稳定行为时才能迁入 Product Base。计划中的 increment 行为必须保留在 owning increment 中，直到 Definition of Done 证据满足且 Product Manager 批准回并。

## Change Flow
Use `docs/process/change_request.md` when a change:
- expands MVP scope
- changes domain schema
- changes API contract
- changes AI output schema
- changes release behavior

## Agent Handoffs
- Product Manager 设定 roadmap priority 并更新 `docs/product/development_status.md`。
- Product Manager 使用 `codex/templates/pm_orchestrator_brief.template.md` 将已批准或调查性工作交给 Development Orchestrator。
- Product Manager 拥有产品分类、Story/Slice 产品事实、stage scope、Stage Scope Item ID 和 increment priority。
- Requirement Development 将已批准 Story/Slice 转换为 FR 和成功标准。
- Development Orchestrator 将已批准工作路由给 specialist agent，并向 Product Manager 返回流程进度或 DoD 缺口。
- Product Manager 在 Orchestrator 返回执行发现后负责用户摘要、产品取舍说明和开发状态更新。
- Product Object Governance Change Agent 每次只实施一个小范围治理变更。
- Product Object Governance Check Agent 在进入下一步前检查每个治理步骤。

## Dynamic Project Agent Runner
Project-local agent 通过动态 runner contract 执行，不复制到静态工具定义。

```text
PM execution brief
-> scripts/project_agent_runner.py packet development_orchestrator
-> Orchestrator routing finding
-> scripts/project_agent_runner.py packet <specialist-agent>
-> specialist output
-> scripts/project_agent_runner.py packet product_object_governance_check
-> checker finding
```

Runner 规则：
- 唯一权威 agent 定义是 `codex/agents/*.md`。
- Project agent 运行前，runner 必须加载当前匹配的 Markdown 文件并生成 Project Agent Execution Packet。
- Packet 必须包含用户任务、上游 handoff、已加载 agent 定义路径和完整定义。
- 下一 Agent 必须读取上一 Agent 的 handoff 输出，不得凭记忆重建范围。
- 除非没有合适 project agent，主任务只负责路由、packet 生成、整合和用户摘要。
- `worker` 或 `default` 等静态 multi-agent role 可以执行 packet，但不得替代或覆盖已加载的 project-local agent 定义。
- 修改 `codex/agents/`、runner script 或 runner packet template 后，使用 `python scripts/project_agent_runner.py validate` 验证完整性。

## PM-Orchestrator Decision Boundary
- Product Manager 回答：现在做、以后做或不做；当前产品 stage、产品分类、scope 和 explicit non-goals 是什么。
- Development Orchestrator 回答：当前 workflow gate、缺失 artifact、下一 specialist agent/skill 和所需验证证据是什么。
- Requirement Development 回答：已批准 Story/Slice 是否已转为可测试 FR。
- Specialist agent 回答：如何在批准范围内产出其拥有的 artifact 或实现。

## Governance Change Control
Workflow、文档类别、路径规则、内容契约、追踪规则或 agent/skill 治理变更必须遵循：
```text
approved remediation step
-> Product Object Governance Change Agent edit
-> Product Object Governance Check Agent finding
-> validation command when skills change
-> next step only after pass
```

Checker 必须确认编辑符合目标步骤、不改变产品范围、未在缺少明确授权时迁移既有产品 artifact，且没有引入新的 source-of-truth 冲突。

任何多步骤 product、requirement、workflow 或 documentation governance 任务的每一步都必须遵循：
```text
approved step scope
-> specialist agent edits
-> independent checker agent finding
-> next step only after pass
```

Product-object、path、workflow、agent 或 skill 变更默认由 Product Object Governance Check Agent 检查；纯文档内容边界可使用 Documentation Governance Agent。

## User Communication Rule
除非用户明确要求 specialist review 或实现细节，用户可见回复应采用 Product Manager 视角。Product Manager 内部可咨询 Development Orchestrator，但最终摘要必须用产品语言说明状态、下一步、owner 和风险。
