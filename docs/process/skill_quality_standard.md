# Skill Quality Standard

本仓库使用 `.agents/skills/` 下的 project-local Codex development skills。
目标是让 Codex 按受控的软件工程流水线执行，而不是作为无约束的代码生成器运行。

## Governance Contract Authority

`docs/process/governance/index.json` 是 agent/skill/workflow 治理契约的根索引。项目运行时定义应引用 Artifact ID 和 Gate ID，不再各自复制 path、owner、I/O、生命周期、例外或门禁正文。根索引只负责路由，详细条目按 product、engineering、governance 分片并按需读取。

流程说明不得成为第二套 authority。若说明正文与 contract 冲突，必须作为 canonical-intent conflict 交给 accountable owner 裁决。

Artifact checker、evidence 和稀疏 I/O 的完整语义只由 `docs/process/governance/policy.json` 定义；本标准只要求 Skill 不复制或绕过该策略。

## Directory Contract

每个 skill 必须放在独立目录中：

```text
.agents/skills/<skill-name>/
  SKILL.md
  references/   # optional, read only when SKILL.md names a concrete condition
  scripts/      # optional deterministic helpers
  assets/       # optional output templates or resources
```

`SKILL.md` 是唯一必需的运行时指令文件。不要创建 `SPEC.md`、README、CHANGELOG 或其他平行维护说明；维护规则属于本标准，复杂且非总是适用的领域细节放入一层 `references/`。

## Product Planning Document Paths

- Product roadmap: `docs/product/roadmap.md`
- Product development status: `docs/product/development_status.md`
- Capability Registry：`docs/product/feature_registry.md` 是 PM-owned V2 canonical registry；普通产品事实维护由 Product Manager 使用 `capability-registry-develop`，path/schema/content-boundary/source-of-truth 变化进入文档与产品对象治理流程。新增或修改下游 requirements、spec、AC、TC、stage scope 和 increment definition 时，只允许引用 active V2 `Capability ID` / `Sub-capability ID`。
- Product Base 需求：`docs/product/base/requirements.md`
- Product Base 规格：`docs/product/base/spec.md`
- Product Base 验收：`docs/product/base/acceptance.md`
- Product Base 追溯：`docs/product/base/traceability.md`
- Product baselines: `docs/product/baselines/<baseline-slug>.md`
- Stage scopes: `docs/product/stages/<stage-id>.md`
- Increment definition: `docs/product/increments/<increment-id>/definition.md`
- Increment requirements: `docs/product/increments/<increment-id>/requirements.md`
- Increment specs: `docs/product/increments/<increment-id>/spec.md`
- Increment acceptance criteria: `docs/product/increments/<increment-id>/acceptance.md`
- Increment test case library: `docs/product/increments/<increment-id>/test_cases.md`
- Increment traceability: `docs/product/increments/<increment-id>/traceability.md`

## Process Governance Document Paths

- Workflow: `docs/process/workflow.md`
- Definition of Done: `docs/process/definition_of_done.md`
- Skill quality standard: `docs/process/skill_quality_standard.md`
- Cross-cutting boundary registry: `docs/process/cross_cutting_boundary_registry.md`
- Software component architecture governance: `docs/process/software_component_architecture_governance.md`
- Change request log: `docs/process/change_request.md`

## Architecture And API Document Paths

- System overview: `docs/architecture/system_overview.md`
- Module boundary: `docs/architecture/module_boundary.md`
- Data flow: `docs/architecture/data_flow.md`
- Global SWC architecture baseline: `docs/architecture/software_component_architecture.md`
- Global SWC catalog: `docs/architecture/swc_catalog.md`
- API contract overview: `docs/architecture/api_contract.md`
- OpenAPI source of truth: `docs/architecture/openapi/speakeasy-api.yaml`
- Increment SWC allocation: `docs/product/increments/<increment-id>/swc_allocation.md`

`docs/architecture/api_contract.md` 记录 API family、product-object traceability、统一 error semantics、versioning、compatibility policy 和 generation boundary。`docs/architecture/openapi/speakeasy-api.yaml` 是 OpenAPI path、component、request/response schema、example 和 lint check 的唯一机器可读 source of truth。两者不得重复拥有 implementation-level schema。

`docs/architecture/software_component_architecture.md` 记录完整 global SWC architecture baseline：system-level responsibility allocation、global SWC topology、stable `SWC-FLOW-*` ID、canonical SWC-to-SWC sequence，以及 local architecture change 的 reference baseline。它不得替代 `docs/architecture/swc_catalog.md`、`docs/architecture/data_flow.md`、Domain Schema、OpenAPI、AI runtime、UX、测试或 implementation report。

`docs/architecture/swc_catalog.md` 记录 reusable software component inventory 和 ownership boundary。它必须引用 Domain Schema 和 OpenAPI，不得复制 entity 或 request/response schema。`docs/product/increments/<increment-id>/swc_allocation.md` 记录一个已批准 increment 的 implementation-readiness allocation：Existing Implementation Baseline、Delta From Existing Baseline，以及 FR/AC 到 frontend SWC、backend SWC、API/OpenAPI、domain entity、DB table/migration、provider/AI boundary 和 test case 的分配。它必须引用 global SWC architecture baseline 和适用 `SWC-FLOW-*` ID，或把 local flow 分类为 `one-off`、`proposed-global` 或 `legacy-compatible`。对于 brownfield work，它必须列出具体 existing code path、existing SWC、existing API、existing test、reused SWC/Flow ID、allowed new code、forbidden duplicate code 和 regression proof。它不得引入 product scope，也不得覆盖 requirements、acceptance criteria、domain、API、AI runtime、UX、test 或 release artifact。

`scripts/check_swc_allocation.py` 是 SWC allocation completeness 的可执行门禁。CI 必须对 changed implementation-impacting path 运行它。该 gate 会阻塞缺失 brownfield baseline、缺失 delta、未知 SWC ID、未知 Flow ID、allocation row 中的泛化 frontend/backend 标签、未被 changed allocation 覆盖的 implementation path，以及未遵守已登记跨切面复用边界的变更。

Artifact owner、contributor 和 write scope 只由 `docs/process/governance/index.json` 路由到的 Artifact Contract 定义；本标准只描述方法质量，不复制角色—产物拥有关系。

## Executable Test Paths

- Flutter/Dart tests: `test/`
- Backend Maven/Spring Boot tests: `backend/src/test/java/`
- Cross-service or repository-level tests: `tests/`
- Backend-specific cross-project tests: `tests/backend/`

## Product Object Governance

Product document 在选择路径前必须先区分 product object：

- Capability：长期存在的 APP 稳定产品分类，登记在 PM-owned `docs/product/feature_registry.md`，不分配独立 feature 文档目录；具体字段、ID、迁移、影响分析和 ready gate 由 `capability-registry-develop` 定义。
- Stage：交付 horizon 或 priority window，归入 `docs/product/stages/<stage-id>.md`。
- Stage Scope Item：stage 内稳定、可按 ID 寻址的 capability、obligation 或 explicit deferral。Active stage scope item 归入 owning stage file，并使用 `<stage-prefix>-SI-<NNN>` 格式的稳定 ID。
- Increment：stage 内有边界的 delivery slice，归入 `docs/product/increments/<increment-id>/`。
- Product Base：需求初版/稳定 Product Base，归入 `docs/product/base/`。
- Baseline：已实现行为快照，归入 `docs/product/baselines/<baseline-slug>.md`。
- Change request：scope decision record，仍保留在 `docs/process/change_request.md`。

- Stage / increment 是交付结构，Capability / Sub-capability 是稳定产品分类；两类对象不得互相替代。
- 新增或修改下游 requirements、spec、AC、TC、stage scope 和 increment definition 只能使用 active V2 classification；V1 registry snapshot 是 archived baseline，不得作为 active source、compatibility source 或新增下游输入。

Capability Registry 职责链：

```text
candidate product object
-> capability-registry-develop destination Gate A when unresolved
-> Product Manager destination / target ID / change mode confirmation
   |-- non-Registry -> owning workflow -> STOP Registry development
   `-- Registry -> matching type-specific Gate B
       -> Registry row proposal / impact analysis / ready gate
       -> Product Manager exact-row final approval and persistence
       -> scripts/validate_capability_registry.py
       -> Product Object Governance Check finding and concise persisted audit record
```

Gate A 负责候选对象归宿 finding，Gate B 负责 PM 已确认 Capability / Sub-capability 类型内的颗粒度检查；两者的枚举、适用性、模板和比较证据只由 `capability-registry-develop` 定义。Product Manager 拥有 destination confirmation 和 exact-row final approval，checker 只核验顺序、证据与治理一致性。

普通 registry 产品事实维护不由 Documentation Governance 审批。Registry canonical path、schema、文档类别、内容边界或 source-of-truth 规则变化时，使用 `document-governance` 拆分并进入 Governance Change Control。

`scripts/validate_capability_registry.py` 是 canonical registry 的可执行结构门禁，检查每个 Capability 二级章节、章内 Capability 单行表、直属 Sub-capability 表、章节/父子 ID 与名称一致性、稳定身份唯一性、相邻引用、downstream/FR prefix 和唯一 Legacy Mapping 表。它不决定候选对象 destination 或业务颗粒度。历史 adjacency 不对称只报告 warning；本次新增或触碰关系是否合理仍由 `capability-registry-develop` Gate A/Gate B、semantic gate 和 Product Manager 决定。

## Direct-Upstream And Traceability Ownership

开发 artifact 逐级细化，并只把直接上游作为行为输入：

```text
User Story / Vertical Slice -> FR -> Spec -> AC -> TC -> Evidence
```

规则：

- Active stage file 必须用稳定 Stage Scope Item ID 暴露 scope，并把每个 item 分类为 `required`、`deferred` 或 `not applicable`。
- Increment definition 必须列出 `Covered Stage Scope Items` 和 `Excluded Stage Scope Items`。
- Requirement 的直接上游是已批准 User Story / Vertical Slice；Stage Scope、Increment 和 Capability 只做 scope guard / delivery classification。
- Spec 的直接上游是已批准 FR；AC 的直接上游是已批准 Spec；TC 的直接上游是 AC/Spec。
- Local artifact 不得把完整 Story/Slice/FR/Spec/AC/TC/SWC 链作为重复必填字段。
- 完整跨级 join 只在 owning Product Base 或 increment `traceability.md` 中维护，并使用稳定 `Traceability Row ID`。
- Implementation-impacting increment 在编码开始前必须包含 `docs/product/increments/<increment-id>/swc_allocation.md`，或明确 `N/A - no SWC impact` decision。
- Brownfield implementation-impacting increment 在编码开始前必须包含 Existing Implementation Baseline 和 Delta From Existing Baseline。
- Implementation-impacting increment 必须引用 `docs/architecture/software_component_architecture.md` 和适用 `SWC-FLOW-*` ID，或为任何 local SWC flow 给出 migration/reuse rationale 分类。
- Implementation-impacting PR 必须通过 `scripts/check_swc_allocation.py`；changed implementation path 必须被 owning allocation 的 existing code baseline 或 allowed code delta 覆盖。
- Traceability matrices must prove 100% coverage for committed scope; local artifacts prove only their direct-upstream relationship and evidence fields.
- Increment test case libraries must assign stable `TC-<scope-prefix>-<NNN>` IDs and continue sequentially without renumbering or reuse.
- Published TC IDs remain in the library even when retired; retired rows must record status `retired` and a replacement TC ID or retirement reason.
- Each increment test case must include: `TC ID`, `Traceability Row ID`, `Increment ID`, `WP ID`, `Spec ID`, `AC ID`, `测试层级`, `自动化状态`, `测试脚本路径`, `执行命令`, `结果状态`, `证据报告`, and `Gap / Exception`.
- QA may update traceability Test Evidence only for test evidence, test status, QA gap notes, and evidence report links. Traceability check must review `AC -> TC -> test script path -> execution command -> result status -> evidence report -> Test Evidence` before completion.
- Future roadmap placeholders may be traced only to V2 Capability/stage boundaries and architecture compatibility notes until Product Manager accepts them into an increment; they must not be represented as implementation-ready requirements.

## Naming

- Directory name 使用 lowercase kebab-case。
- `SKILL.md` frontmatter `name` 必须与目录名完全一致。
- 名称应描述一个可复用动作，而不是角色或部门。
- Skill 应足够小，能够独立执行和验证。

## SKILL.md Required Structure

`SKILL.md` 是运行时指令文件，必须以 YAML frontmatter 开始：

```yaml
---
name: skill-name
description: Use when ... Do not use ...
---
```

Required sections:

- `## Overview`
- `## Contract`
- `## Inputs`
- `## Outputs`
- `## Process`
- `## Verification`

`description` 必须同时包含正向和反向触发边界，并使用 `Use when` 与 `Do not use` 短语。`When to Use`、`When NOT to Use`、文档路径、Red Flags 和 Common Rationalizations 仅在能补充非重复执行信息时保留，不作为统一模板负担。

## Bundled Resources

复杂 Skill 可以使用 `references/`、`scripts/` 和 `assets/`，但不得建立隐含的第二运行规则层。

- `references/*.md` 只保存非总是适用的领域细节、模式或大型检查表；SKILL 必须直接链接每个 reference，并明确何时读取、何时不读取。
- Reference 只允许一层，不得从 reference 再路由到另一份 reference。
- 核心触发、权限、I/O、步骤和验证仍保留在 SKILL；reference 不得改写或覆盖这些规则。
- `scripts/` 用于重复、脆弱或需要确定性的操作，并应由 SKILL 说明调用条件。
- `assets/` 是输出模板或资源，不作为运行时规则来源。
- 外部链接只在直接支撑当前方法或 attribution/license 时保留；链接数量、是否包含 `http`、External References 章节都不是质量指标。
- 不强制 Common Rationalizations；只保留能阻止该 Skill 特有高概率误用的条目。

维护 Skill 时直接修改 SKILL、实际命中的 reference/script/asset、治理契约或 validator；不要为记录修改过程新增维护文档。

## Trigger Quality

A high-quality skill has clear boundaries:

- `When to Use` says which work should trigger it.
- `When NOT to Use` prevents over-triggering.
- `Red Flags` identifies failure modes, scope creep, weak assumptions, and unverifiable outputs.
- `Verification` gives concrete checks that can be performed after the skill runs.

## Spec-Driven Behavior

Project skill 应遵循以下规则：

- 先列 assumptions，再给 conclusions。
- 实现前把 requirements 转成可测试 success criteria。
- 预计触碰超过五个文件的任务应拆分。
- 优先采用 contract-first API 和 interface design。
- cross-layer、persistence、API、provider、AI runtime 或 reusable-module implementation 只有在 `G-SWC` applicability 命中时才要求 SWC allocation。
- bug fix 必须要求 regression test。
- 只有用户或 Artifact contract 明确要求持久化记录时，才在 implementation report 中记录 validation、risk 和 follow-up。

## Native Agent Governance

项目级 specialist agent 位于 `.codex/agents/*.toml`，由 Codex 原生发现、隔离和执行。根 `AGENTS.md` 只保留跨任务工作约定。

原生 agent 质量规则：

- 每个 TOML 必须包含唯一 `name`、具体 `description` 和精简 `developer_instructions`。
- `description` 说明何时使用该 specialist；不得使用 always-use 或覆盖所有开发任务的触发器。
- `developer_instructions` 只描述角色、权限、决策边界和关键非目标，不复制 Artifact 路径表、Skill 流程或 Gate 正文。
- Reviewer/Checker 必须使用 `sandbox_mode = "read-only"`；Producer 只有在任务授权范围内写入。
- Skill 是按任务命中的方法，不在 agent 定义中维护静态必选 Skill 列表。
- Artifact/Gate 仅在实际 applicability 命中时读取；没有持久化事实变化的普通开发任务不生成治理文档。
- 修改 `AGENTS.md`、`.codex/config.toml` 或 `.codex/agents/*.toml` 后运行 `python scripts/validate_governance_contracts.py`。

## Full-Scope Planning and Architecture Governance

Broad planning skill 和 architecture agent 必须防止把 partial context 表述成 full-system conclusion。

- 每个 broad architecture 或 platform strategy task 必须声明 scope mode：`whole-app`、`stage`、`increment`、`capability`、`refactor` 或 `experiment`。
- Whole-app task 在结论前必须建立 source inventory：Product Base、V2 Capability registry、roadmap、development status、active stages、planned increments、future-stage boundaries、non-goals、current code structure、existing contracts、release artifacts 和 reports。
- Whole-app architecture 必须包含 Capability/stage/increment coverage matrix，把 V2 Capability 和 delivery objects 映射到 frontend、backend、data、API、AI/runtime、security、tests、release 和 operations；registry row 本身不是行为输入。
- Implementation-impacting architecture 必须包含 software component architecture 和 allocation：global SWC architecture baseline、stable SWC ID、applicable `SWC-FLOW-*` ID、code path、responsibility、non-responsibility、provided/required interface、data ownership、persistence ownership、API/OpenAPI reference、test ownership、reuse requirement 和 forbidden bypass。
- Increment-level implementation architecture 必须把每个受影响 FR/AC 映射到 frontend SWC、backend SWC、API/OpenAPI、domain entity、DB table/migration、provider/AI boundary 和 TC，或记录明确 `N/A - <reason>`。
- 缺失 coverage 必须分类为 blocker、deferred 或 not applicable。未分类遗漏会阻塞 acceptance。
- Technology recommendation 必须能追溯到 requirements、constraints、market/common-practice option comparison、trade-off、team/operations fit 和 rollback cost。
- ADR 记录 accepted 或 proposed decision；不得用 ADR 把 exploratory 或 incomplete architecture 洗成 source of truth。
- 任何 coverage 不通过的 architecture artifact，在下游 development 使用前必须删除、supersede 或标记为 non-source-of-truth。
- Governance fix 必须处理 failure class，不得把一次性事件或具体整改编号写入通用规则；应增加可复用 coverage、traceability 和 review gate。

## 文档路径治理

项目内 skill 必须让文档输入和输出位置清晰可追踪：

- 使用明确的仓库路径或路径模板，例如 `docs/product/increments/<increment-id>/spec.md`。
- 避免只写 `updated docs`、`feature-specific notes`、`report updates` 这类泛称；如果必须使用泛称，也要同时列出具体目标路径。
- 保持 `SKILL.md` 与其直接链接的 references/scripts/assets 一致；未命中的资源不应加载。
- 新增持久化项目文档默认使用中文，除非用户明确要求其他语言。
- 若需要保留英文原文，必须采用源文件内双语格式：英文正文块后紧跟中文翻译或中文等价说明，不另行生成 `.en.md` 旁路文件，除非用户明确要求。
- 涉及 `docs/` 或 `codex/templates/` 下持久化项目文档输出时，解释性段落、状态、规则、结论和流程说明必须通过 `python3 scripts/check_document_language.py --scope changed --include-worktree`；技术标识、路径、API、OpenAPI、SWC ID 和测试 ID 可以保留英文。
- 当路径不清楚或新增文档路径时，先使用 `document-path-governance` skill 做路径归属判断。
- 当问题同时涉及路径、内容契约和追踪检查，或无法判断属于哪一类治理问题时，先使用 `document-governance` 做总控路由。

## 文档治理 skill 分层

文档治理职责拆分为四个 skill：

- `document-governance`：总控路由，负责判断问题类型、拆分任务和处理跨治理冲突。
- `document-path-governance`：路径治理，负责 canonical path、owner、source of truth、路径模板、skill 输入输出路径和 agent Allowed Paths。
- `document-content-contract`：内容契约治理，负责每类文档写什么、不写什么、必需章节、禁止内容和验收检查。
- `document-traceability-check`：追踪检查，负责需求、规格、验收、契约、测试、报告和发布证据之间的链路完整性。

新增或修改文档治理规则时，应优先更新具体子 skill；只有路由和冲突处理规则才写入 `document-governance`。

## External References and Attribution

本仓库借鉴公开 skill 和工程流程仓库中的 workflow patterns，但不直接 vendoring 其内容。
如果未来复制外部 skill 内容到本仓库，必须在对应 skill 目录保留 attribution 和 license 信息。

Reference sources:

- GitHub Copilot Agent Skills: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills
- OpenAI Codex skill-creator sample: https://github.com/openai/codex/blob/main/codex-rs/skills/src/assets/samples/skill-creator/SKILL.md
- addyosmani/agent-skills: https://github.com/addyosmani/agent-skills
- addyosmani documentation-and-ADRs skill: https://github.com/addyosmani/agent-skills/blob/main/skills/documentation-and-adrs/SKILL.md
- Microsoft cloud-solution-architect skill: https://github.com/microsoft/skills/tree/main/.github/skills/cloud-solution-architect
- Callstack agent-skills React Native workflow patterns: https://github.com/callstackincubator/agent-skills
- AIWG multi-agent workflow primitives: https://github.com/jmagly/aiwg
- agent-ecosystem/skill-validator: https://github.com/agent-ecosystem/skill-validator
- getsentry/skills: https://github.com/getsentry/skills

## Local Validation

新增或编辑 skills 后运行以下命令：

```bash
python scripts/validate_agent_skills.py
```

当前 validator 有意保持轻量，只检查必需结构和基础触发质量；后续可集成完整 skill validator 或增加语义检查。
