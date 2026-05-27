# Agent Ownership / Input / Output Audit

## 1. 审计范围

本报告审计 `codex/agents/*.md` 中所有项目级 agent 的 Ownership、Inputs、Outputs、Allowed Paths 是否符合真实开发流程。

审计原则：

- Inputs 可以多：agent 可以读取所有必要上游证据、兼容资料和历史报告。
- Outputs 必须按 ownership 收窄：agent 只能把自己真正拥有的产物列为输出。
- Allowed Paths 必须覆盖 Outputs，但不能把路由者或评审者扩大成全项目写入者。
- 当产物属于另一个 agent 或 skill，应写成 handoff、finding 或 status reference，而不是本 agent 的 Output。

## 2. 目标开发链路

| 顺序 | Owner | 产物边界 |
| --- | --- | --- |
| 1 | Product Manager Agent | 产品方向、优先级、stage/increment 定义、feature registry、PM execution brief |
| 2 | Requirement Development Agent | 用户故事、requirements、需求到验收的 handoff |
| 3 | Feature Spec / Acceptance / Traceability skills | spec、acceptance、traceability source of truth |
| 4 | System Architect Agent | architecture、API contract direction、module boundary、ADR、coverage matrix |
| 5 | Domain Schema Agent | domain entities、relationships、lifecycles、data semantics |
| 6 | Backend / Frontend / AI Runtime Agents | 各自代码、配置、实现测试、实现报告 notes |
| 7 | QA Agent | test planning、acceptance-to-test mapping、regression evidence、test/quality reports |
| 8 | DevOps Agent | CI、release readiness、runtime configuration expectations、rollback plan |
| 横向 | Documentation Governance Agent | 文档路径、内容边界、追溯、agent/skill 文档规则 |
| 横向 | Development Orchestrator Agent | 路由、门禁、handoff packet、DoD finding，不拥有 source-of-truth 产物 |
| 横向 | Product Object Governance Change/Check Agents | workflow/product-object governance 的变更与独立检查 |

## 3. Agent Ownership Matrix

| Agent | Ownership | 正确 Inputs | 正确 Outputs |
| --- | --- | --- | --- |
| Product Manager | 产品规划、优先级、scope 决策、stage/increment 定义、PM brief | 用户请求、产品文档、Product Base、feature registry、stage/increment、报告、workflow | vision、roadmap、development_status、backlog、feature_registry、baseline/stage/increment definition、change_request 中的产品决策 |
| Requirement Development | requirements、user stories、requirement assumptions、requirement-to-acceptance handoff | PM classification、increment definition、Product Base、feature registry、stage/increment、change_request | user_stories、Product Base requirements、feature/increment requirements |
| Development Orchestrator | execution routing、gate checks、handoff packets、DoD finding | PM brief、Product Base、registry、stage/increment、workflow、DoD、reports | 非持久 work plan/routing/finding；必要时写 implementation_report 或 quality_report |
| Documentation Governance | path/content/traceability governance、agent/skill doc contracts | docs、process、governance skills、agent/skill definitions | docs/process governance docs、.agents/skills、codex/agents、quality_report notes |
| Product Object Governance Change | governance rules、agent/skill instruction、runner/template scoped changes | PM/remediation request、workflow、skill standards、relevant agents/skills | docs/process、.agents/skills、codex/agents、codex/templates、scripts governance utilities |
| Product Object Governance Check | independent pass/block finding | handoff、changed files、workflow、validator scripts、relevant agents/skills | check finding、corrections、residual risks；可选 quality_report notes |
| System Architect | architecture docs、API contract direction、module boundary、ADR、coverage matrix | Product Base、increments、baselines、registry、roadmap、domain schema、code structure | docs/architecture/* |
| Domain Schema | domain model、entities、relationships、lifecycles、persistence implications | requirements/spec/acceptance/traceability、architecture overview | docs/domain/* |
| Backend | backend code/config/migrations/services/provider integration/backend tests | API contract、OpenAPI、domain schema、acceptance、traceability | backend/*、tests/backend/*、implementation_report backend notes |
| Frontend | app UI/client code、screen/component implementation、frontend tests | screen spec、API contract、OpenAPI、acceptance、traceability | app/* 或 lib/*、test/*、tests/frontend/*、implementation_report frontend notes |
| AI Runtime | prompt contracts、structured schemas、dialogue state、fallback、AI evals | acceptance、traceability、domain scene model、AI runtime docs | docs/ai_runtime/*、AI runtime backend code、tests/ai_eval/*、implementation_report AI notes |
| UX Review | UX findings、screen/user-flow docs、learner-facing copy guidance | acceptance、traceability、screen spec、UI implementation | docs/ux/*、quality_report UX section |
| QA | test planning、acceptance-test mapping、regression evidence、test/quality reports | acceptance、traceability、contracts、implementation report、source code | tests/*、test/*、test_report、quality_report |
| DevOps | CI、release readiness、runtime config expectations、rollback | release checklist、DoD、CI config | .github/workflows/*、docs/release/*、quality_report release notes |

## 4. 已发现问题与解决方案

| 编号 | 问题 | 影响 | 解决方案 | 状态 |
| --- | --- | --- | --- | --- |
| AIO-01 | Product Manager Outputs 包含 `docs/product/base/requirements.md`、`spec.md`、`acceptance.md`、`traceability.md`。 | PM 会越权成为详细需求、规格、验收、追溯 owner，导致后续 Requirement/Acceptance/Traceability 无法判断 source-of-truth。 | 从 PM Outputs 移除这些 Product Base 详细产物；新增 Ownership，限定 PM 只拥有产品规划、scope、stage/increment definition 和 PM brief。 | 已修正 |
| AIO-02 | Requirement Development 同时描述“维护 acceptance criteria”，但 acceptance artifact 实际由 Acceptance Criteria Generate Skill 维护。 | 需求和验收产物 ownership 混淆，容易造成同一 AC 被两个 owner 写入。 | 将职责改为 requirement success criteria 与 handoff notes；Outputs 只保留 requirements/user stories；验收 artifact 明确交给 Acceptance Criteria Generate Skill。 | 已修正 |
| AIO-03 | Development Orchestrator Outputs/Allowed Paths 过宽，含 `Updated reports`、`docs/`、`codex/`。 | 路由者可能被误用为任意文档和 agent 定义写入者，破坏 source-of-truth ownership。 | Outputs 改为非持久 work plan/routing/finding/handoff packet；Allowed Paths 收窄到 implementation_report 和 quality_report。 | 已修正 |
| AIO-04 | 实现类 agents 使用宽泛 `tests/`、`docs/reports/` 或自然语言 Outputs。 | staging 和 review 时难以区分实现测试、QA 测试和报告 ownership。 | Backend/Frontend/AI Runtime Outputs 改为各自代码路径、专属测试路径和 implementation_report notes；Allowed Paths 同步收窄。 | 已修正 |
| AIO-05 | System Architect 和 Domain Schema 允许写 `docs/process/change_request.md`，但它们不拥有产品变更决策。 | 架构/领域 agent 可能绕过 PM 写入 scope/change 决策。 | 移除其 Allowed Paths 中的 `docs/process/change_request.md`；change request 仅作为输入或需回传 PM finding。 | 已修正 |
| AIO-06 | 多数 agent 缺少显式 Ownership section。 | Checker 只能根据 Role/Outputs 推断 ownership，容易产生解释差异。 | 为全部 project agents 增加 `## Ownership`，明确 Owns / Does not own。 | 已修正 |
| AIO-07 | `system_architect.md` scope mode 使用全角冒号。 | 不影响语义，但降低机器校验和文本 diff 的一致性。 | 改为 ASCII 冒号。 | 已修正 |
| AIO-08 | QA、UX Review、DevOps 仍保留 `docs/reports/` 泛写权限。 | 虽然 Outputs 指向具体报告，但 Allowed Paths 仍允许写入任意 report，和 ownership 收窄原则不一致。 | QA Allowed Paths 收窄为 `docs/reports/test_report.md` 与 `docs/reports/quality_report.md`；UX Review 与 DevOps 收窄为 `docs/reports/quality_report.md`。 | 已修正 |

## 5. 后续 Guardrails

- 新增或修改 agent 时，必须同时检查 `Ownership -> Inputs -> Outputs -> Allowed Paths -> Rules` 是否一致。
- `Development Orchestrator` 只能路由和记录 finding，不能直接创建 source-of-truth 需求、规格、验收、架构、领域、测试或 release 产物。
- PM 可以读取完整上游链路，但不能把下游详细产物列为自己的 Outputs。
- 需求、规格、验收、追溯必须分别由对应 owner 或 skill 维护，报告不能替代 source-of-truth。
- 当前仓库仍有大量 `A/AM/??` 脏改，后续 staging 必须显式按本次 agent governance 文件分组，不能使用全量 `git add codex/agents docs/reports`。

## 6. 本次校验记录

- `python scripts/project_agent_runner.py validate`：通过。
- `python scripts/validate_agent_skills.py`：通过。
- Agent ownership invariant check：通过，确认所有 agent 含 `## Ownership`，PM Outputs 不再包含 Product Base 详细产物，Orchestrator Allowed Paths 不再包含 `docs/` 或 `codex/` 泛写路径，Requirement Development 不再输出 legacy `docs/product/acceptance_criteria.md`。
- `python scripts/project_agent_runner.py packet product_manager --task "Validate Product Manager ownership boundary after agent I/O audit"`：通过。
- `python scripts/project_agent_runner.py packet development_orchestrator --task "Validate Orchestrator routing boundary after agent I/O audit"`：通过。
- `git diff --check -- codex/agents docs/reports/agent_ownership_io_audit.md`：无 whitespace error；仅提示 Windows 换行规范化 warning。
- Product Object Governance Check Agent 首轮复核：block，指出 QA、UX Review、DevOps 的 Allowed Paths 仍含 `docs/reports/` 泛写路径。
- 已按 checker 要求修正 QA、UX Review、DevOps 的具体报告路径，并将 invariant check 扩展到 `docs/reports/` 泛写路径。
