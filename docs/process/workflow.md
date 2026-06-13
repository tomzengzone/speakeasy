# Codex Development Workflow

## Product Planning Layer
```text
user request
-> Product Manager intake
-> product classification
-> optional issue-management tracking when repository issue tracking is needed
-> feature registry / stage scope check
-> increment definition
-> roadmap / development status update
-> PM execution brief
```

Product Manager is the unified user-facing entry point. It decides the active stage goal, backlog priority, roadmap horizon, accepted/deferred scope, and current progress status. Users should not need to choose specialist agents directly.

## Product Object Model
```text
Feature = long-lived product capability
Product Base = living source of truth for accepted product requirements, specs, acceptance, and traceability
Stage = delivery horizon or priority window
Stage Scope Item = stable, ID-addressable capability or obligation committed, deferred, or marked not applicable inside a stage
Increment = scoped delivery slice inside a stage
Test Case Library = canonical AC-to-TC design artifact for an increment before implementation starts
Baseline = frozen snapshot of Product Base at a stage, version, release, or audit point
Change Request = decision record for scope change
Artifact = requirements, spec, acceptance, contracts, tests, reports, release evidence
```

Feature and stage are separate axes. A feature is not a stage, and a stage is not a feature. The Product Base is the living product requirement library. Requirements, specs, acceptance criteria, and traceability for accepted stable behavior live in `docs/product/base/`. Increment artifacts live in `docs/product/increments/<increment-id>/` until they are done and approved to merge back into Product Base. Increment test case libraries live at `docs/product/increments/<increment-id>/test_cases.md` and are the source of truth for AC-to-TC design before implementation. Baselines under `docs/product/baselines/` are frozen snapshots and must not replace Product Base.

## Execution Layer
```text
PM execution brief -> Development Orchestrator -> workflow gate check -> specialist agents -> validation evidence -> PM status update -> user summary
```

Development Orchestrator is the internal execution dispatcher. It does not decide whether a product goal is worth doing; it decides which workflow step is currently legal and necessary for approved scope.

## Standard Flow
```text
idea/change intake
-> product classification
-> feature registry / stage scope check
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

## Required Gates
1. Product classification 完成前，不创建 feature/increment document。
2. Feature registry 和 stage scope 确认前，不创建 requirements/spec/acceptance artifact。
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

The classification must identify the primary feature when one exists, affected features when multiple capabilities are touched, active stage, expected increment, and whether a change request is required.

## Issue Tracking Boundary
Issue tracking is optional and must happen after Product Manager classification when it would help coordinate bugs, follow-ups, release blockers, workflow changes, implementation slices, pull requests, or evidence links.

Use `.agents/skills/issue-management/` for issue title/body drafting, triage fields, label/status suggestions, branch or pull request link text, and source-of-truth links. Issues are tracking containers only. They must not replace Product Manager classification, roadmap priority, Product Base, increment requirements/specs/acceptance/test cases/traceability, implementation reports, test reports, quality reports, or release evidence.

If an issue conflicts with local product or workflow artifacts, the local artifacts win and the issue must be corrected or marked blocked. Use `Refs #<id>` for planning, partial slices, investigations, and blocked evidence. Use `Closes #<id>` only after Definition of Done evidence is complete.

## Increment Definition Gate
Before requirement development starts, the active increment must state:
- increment id and name
- active stage
- covered Stage Scope Item IDs
- primary feature
- affected features
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
- requirement allocation matrix：`Stage Scope ID -> FR -> Spec -> AC -> FE SWC -> BE SWC -> API/OpenAPI -> Domain Entity -> DB table/migration -> TC`；
- 每个 core use case 的 SWC-to-SWC data flow，包括 global Flow ID 或 local flow id、success path、failure path、auth、idempotency、retry、rollback/compensation、audit、logging、metrics 和 permission boundary；
- required reuse list 和 forbidden duplicate-build list；
- 对任何未触碰 layer 写出明确 `N/A - <reason>`；
- architecture validation expectation 和 independent checker finding reference。

SWC allocation document 不得重新定义 product scope、requirements、acceptance criteria、domain entity semantics、OpenAPI request/response schema、AI prompt schema、UX layout、test implementation 或 release approval。它只把已批准 scope 分配到 software component，并证明 implementation 可以在没有 ownership ambiguity 和 duplicate component creation 的前提下推进。

Brownfield change 只能写 delta。若 increment 扩展、修复、重构或加固既有能力，其架构不得从全新设计开始。它必须先证明继承了哪些 existing implementation facts，包括 code path 和 test。除非 allocation 解释为什么 accepted component 不能复用，并记录 migration/deprecation ownership，否则禁止新增 SWC、runtime、store、API、migration、provider 或 cache layer。

CI 通过 `scripts/check_swc_allocation.py` 强制执行。PR 如果修改 `lib/`、`backend/src/main/java/`、`backend/src/main/resources/db/migration/` 或 `docs/architecture/openapi/speakeasy-api.yaml` 下的 implementation-impacting path，必须包含覆盖这些 path 的 changed increment `swc_allocation.md`，或包含已接受的 `N/A - no SWC impact` traceability decision。Scenario-practice 变更必须引用 `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME` 和既有 `FE-SCENARIO-PRACTICE` / `FE-PRACTICE-RUNTIME` 边界。

如果 increment 改变 stable SWC topology，或把 local flow 变成 reusable system flow，必须在 implementation planning 前更新 `docs/architecture/software_component_architecture.md` 和 `docs/architecture/swc_catalog.md`；否则 increment 必须携带 accepted `legacy-compatible` exception，并写明 migration owner 和 expiry condition。

## Stage Scope Traceability Gate
每个 active stage 在生成下游 increment artifact 前，必须把 committed scope 暴露为稳定 Stage Scope Item。每个 stage scope file 应包含一张表，列出：

- Stage Scope ID
- Capability
- Required status: `required`, `deferred`, or `not applicable`
- Target increment or reason no increment is planned
- Current status

Each increment definition must include `Covered Stage Scope Items` and `Excluded Stage Scope Items`. The traceability chain for committed stage work is:

```text
Stage Scope ID
-> Increment ID
-> Requirement ID
-> Spec section/state ID
-> Acceptance Criteria ID
-> Test Case ID
-> Contract ID, when applicable
-> Global SWC Architecture Baseline / Flow ID, when applicable
-> SWC Allocation Row, when applicable
-> Work Package ID, when available
-> Code Evidence
-> Test Evidence
-> Release Evidence
```

`100% traceability` 指每个 required Stage Scope Item ID 都被至少一个 increment 覆盖，或有明确 deferred/not-applicable decision；每条 increment requirement 都能追溯回至少一个 Stage Scope Item ID；每个 FR 至少有一个 AC；每个 AC 映射到至少一个稳定 TC ID 或明确例外；每个 implementation-impacting AC 映射到 global SWC architecture baseline/Flow ID 和 SWC allocation row，或明确 no-SWC-impact decision；每个 AC 都能追溯到 implementation 和 test evidence 或 documented exception；当 release scope 受影响时存在 release evidence。

每个 increment test case 必须携带证明链路所需的最小 traceability field：`Stage Scope ID`, `FR`, `Spec`, `AC`, `Traceability Row`, `Gap`, `测试层级`, `自动化状态`, `测试脚本路径`, `执行命令`, `结果状态`, `证据报告`。空字段是 traceability gap，除非包含明确 `N/A - <reason>`。

测试执行后，QA 只能更新 owning Product Base 或 increment traceability file 中的 Test Evidence、test status、QA gap notes 和 evidence report link。完成前，traceability check 必须能审查完整 `AC -> TC -> test script path -> execution command -> result status -> evidence report -> Test Evidence` 链路。

## Product Base Gate
`docs/product/base/` is the living source of truth for accepted product behavior:
- `docs/product/base/requirements.md`
- `docs/product/base/spec.md`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`

Current MVP legacy artifacts may be migrated into Product Base only when they describe implemented or accepted stable behavior. Planned increment behavior must remain under the owning increment until it satisfies Definition of Done evidence and Product Manager approves the merge.

## Change Flow
Use `docs/process/change_request.md` when a change:
- expands MVP scope
- changes domain schema
- changes API contract
- changes AI output schema
- changes release behavior

## Agent Handoffs
- Product Manager sets roadmap priority and updates `docs/product/development_status.md`.
- Product Manager sends approved or investigatory work to Development Orchestrator using the PM execution brief in `codex/templates/pm_orchestrator_brief.template.md`.
- Product Manager owns product classification, stage scope, Stage Scope Item IDs, and increment priority.
- Requirement Development converts accepted scope into user stories, feature requirements, and acceptance criteria.
- Development Orchestrator routes the approved work through specialist agents and reports workflow progress or DoD gaps back to Product Manager.
- Product Manager is responsible for user-facing summaries, product tradeoff explanations, and development status updates after Orchestrator returns execution findings.
- Product Object Governance Change Agent applies governance rule changes one small step at a time.
- Product Object Governance Check Agent verifies each governance step before the next step starts.

## Dynamic Project Agent Runner
Project-local agents are executed through a dynamic runner contract rather than copied into static tool definitions.

```text
PM execution brief
-> scripts/project_agent_runner.py packet development_orchestrator
-> Orchestrator routing finding
-> scripts/project_agent_runner.py packet <specialist-agent>
-> specialist output
-> scripts/project_agent_runner.py packet product_object_governance_check
-> checker finding
```

Runner rules:
- The only authoritative agent definitions are `codex/agents/*.md`.
- Before a project agent runs, the runner must load the current matching markdown file and emit a Project Agent Execution Packet.
- The packet must include the user task, upstream handoff, loaded agent definition path, and full loaded definition.
- The next agent must read the previous agent's handoff output rather than reconstructing scope from memory.
- Main thread work is limited to routing, packet generation, integration, and user-facing summary unless no suitable project agent exists.
- A static multi-agent tool role such as `worker` or `default` may execute the packet, but it must not replace or override the loaded project-local agent definition.
- Validate runner integrity with `python scripts/project_agent_runner.py validate` after changing `codex/agents/`, the runner script, or the runner packet template.

## PM-Orchestrator Decision Boundary
- Product Manager answers: should this be done now, later, or not now; what is the active product stage; what is the product classification; what is in scope; what is explicitly out of scope.
- Development Orchestrator answers: what workflow gate is current; which artifact is missing; which specialist agent or skill should run next; what validation evidence is required.
- Requirement Development answers: whether accepted scope is expressed as testable requirements, user stories, and acceptance criteria.
- Specialist agents answer: how to produce their owned artifact or implementation within the approved scope.

## Governance Change Control
Changes to workflow, document categories, path rules, content contracts, traceability rules, or agent/skill governance must follow:
```text
approved remediation step
-> Product Object Governance Change Agent edit
-> Product Object Governance Check Agent finding
-> validation command when skills change
-> next step only after pass
```

The checker must verify that the edit matches the intended step, does not change product scope, does not migrate existing product artifacts unless explicitly authorized, and does not introduce a new source-of-truth conflict.

For any multi-step product, requirement, workflow, or documentation governance task, each step must follow:
```text
approved step scope
-> specialist agent edits
-> independent checker agent finding
-> next step only after pass
```

The default checker is Product Object Governance Check Agent for product-object, path, workflow, agent, or skill changes; Documentation Governance Agent may be used for pure documentation content-boundary checks.

## User Communication Rule
The user-facing response should come from the Product Manager viewpoint unless the user explicitly asks for a specialist review or implementation detail. Internally, Product Manager may consult Development Orchestrator, but the final user summary should explain product status, next step, owner, and risk in product terms.
