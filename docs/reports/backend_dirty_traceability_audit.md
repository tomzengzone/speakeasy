# 后端脏改与追溯审计报告

审计日期：2026-05-27

审计范围：

- 当前工作区全部脏改的整理、风险分析和处置方案。
- 当前已实现后端功能对 Product Base、P0 commercial、架构/API/领域文档的符合性和追溯关系。
- 当前后端测试用例库对需求-代码-测试链路的覆盖情况。

非目标：

- 不继续实现 PB-BE-002、PB-BE-003 或 P0-COM-BE-002 之后的功能。
- 不修改 Product Base 或 increment 的源需求/规格/验收矩阵。
- 不做 Flutter 集成、generated Dart client 集成或真实支付 secrets 接入。

## 1. 本项目 agent 和工作流审查

### 1.1 已审查定义

| 定义 | 路径 | 本次结论 |
| --- | --- | --- |
| Development Orchestrator | `codex/agents/development_orchestrator.md` | 要求 PM brief -> Orchestrator -> specialist -> validation -> report；实现前必须有上游 docs 和 gate。 |
| Documentation Governance | `codex/agents/documentation_governance.md` | 本次属于路径治理、追溯检查、测试证据审查的混合文档治理问题。 |
| Product Object Governance Check | `codex/agents/product_object_governance_check.md` | 要区分本步变更和既有脏改；后续 staging/merge 必须隔离当前步文件。 |
| Backend Agent | `codex/agents/backend.md` | 后端实现必须来自 API contract 和 domain schema；每个 endpoint 必须有测试或明确例外。 |
| QA Agent | `codex/agents/qa.md` | 需要把测试映射到 acceptance criteria，并维护 test/quality report。 |
| Workflow | `docs/process/workflow.md` | 未满足实现、测试、追溯、报告、checker gate 前，不得进入下一批实现。 |
| Document Governance skills | `.agents/skills/document-*/SKILL.md` | 追溯审查只报告断链和下一步，不直接改写需求/规格源文档。 |
| Test Case Generate skill | `.agents/skills/test-case-generate/SKILL.md` | 100% coverage 指需求覆盖完整性，不是代码行覆盖或零缺陷保证。 |

### 1.2 工作流结论

结论：条件通过。

- `python scripts/project_agent_runner.py validate`：通过。
- `python scripts/validate_agent_skills.py`：通过。
- 当前流程允许把本次审计报告写入 `docs/reports/`。
- 发现一个治理缺口：`codex/agents/backend.md` 的输入仍指向 legacy `docs/product/acceptance_criteria.md`，而当前 Product Base/increment 工作流已经把 `docs/product/base/` 和 `docs/product/increments/<increment-id>/` 作为主链路。解决方案：单独创建一个 agent contract 修正小步，把 Backend Agent 输入更新为 Product Base / increment acceptance + traceability + OpenAPI + domain schema，经过 Product Object Governance Check 后合入。

## 2. 全量脏改汇总与处置方案

### 2.1 当前 git 状态摘要

命令：`git status --short`

| 状态 | 数量 | 含义 |
| --- | ---: | --- |
| `A ` | 60 | 已 staged 的新增文件。 |
| `AM` | 45 | 已 staged 后又有 unstaged 修改的文件。 |
| ` M` | 1 | 仅工作区修改：`.gitignore`。 |
| `??` | 17 | untracked 条目；其中多个是目录，实际 untracked 文件数为 78，包含本审计报告。 |

按顶层目录统计：

| 区域 | 状态条目数 | 主要风险 |
| --- | ---: | --- |
| `.agents/` | 30 | 项目本地 skills 大批新增/修改，属于治理变更，不应与后端代码一起 staging。 |
| `codex/` | 21 | agents/templates 新增/修改，属于流程/路由变更。 |
| `docs/` | 63 | 产品、架构、领域、流程、报告文档混在一起，存在 source-of-truth 合并风险。 |
| `backend/` | 1 个 untracked 目录 | 实际包含后端源码、迁移、测试；整个目录尚未被 Git 跟踪。 |
| `scripts/` | 4 | 校验脚本和 agent runner untracked/新增，需随治理或 API gate 分组。 |
| root tooling | 4 | `.gitignore`、`package.json`、`package-lock.json`、`redocly.yaml`；需和 OpenAPI/tooling gate 一起处理。 |

Flutter/app 路径检查：

- `lib/`, `test/`, `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`, `pubspec.yaml`, `pubspec.lock` 当前无脏改。
- 这符合本批非目标：不做 Flutter 集成。

### 2.2 脏改逐项分析

| 编号 | 脏改组 | 当前状态 | 问题 | 解决方案 |
| --- | --- | --- | --- | --- |
| D-01 | 项目本地 skills：`.agents/skills/*` | 多数为 `A` 或 `AM` | skill 新增和二次修改混在一起，若和后端代码同 commit，会导致后端审查无法判断流程规则是否先于实现存在。 | 单独作为“项目工作流/技能治理”变更；先跑 `python scripts/validate_agent_skills.py`，再走 Product Object Governance Check。 |
| D-02 | project agents：`codex/agents/*` | 多数为 `A` 或 `AM` | Orchestrator、PM、Backend、QA、checker 等路由定义本身是上游执行规则，不能和业务实现混合合入。 | 单独治理提交；修正 Backend Agent 输入契约后再合并。 |
| D-03 | templates：`codex/templates/*` | staged 新增，另有 `agent_runner_packet.template.md` untracked | 影响 agent runner 和报告产物格式，应和 agent runner 脚本一起审查。 | 与 `scripts/project_agent_runner.py` 分组，形成“项目 agent runner 支撑”提交。 |
| D-04 | Product Base 文档：`docs/product/base/` | untracked 目录 | 这是当前稳定需求/规格/验收/追溯主链路，不能被后端实现顺手建立后直接视为已验收。 | 作为 Product Base source-of-truth 提交；要求 PM/Documentation Governance 先确认，再供后端继续引用。 |
| D-05 | P0 commercial increment：`docs/product/increments/commercial-subscription-readiness/` | untracked 目录 | 当前后端依赖该增量追溯，但该目录还未跟踪；后续 merge 若漏掉会让后端代码失去上游依据。 | 必须在后端实现前或同批前置合入；保持 definition/requirements/spec/acceptance/traceability 成组。 |
| D-06 | P0.1 increment/stage docs | staged 新增 | 用户当前非目标明确不做 P0.1 训练闭环；这些文档不能误导后端进入 P0.1 实现。 | 保留为规划/上游文档，不与 PB-P0-BE-001B 后端提交混合；后续单独走 P0.1 workflow。 |
| D-07 | 架构/API/领域文档 | staged/untracked 混合 | `api_contract.md`、OpenAPI、domain schema、security design 是后端实现依据；如果漏合或顺序错误，后端代码会出现无依据实现。 | 作为“架构/API/领域契约”提交；必须保留 `npm.cmd run check:api-contract` 通过记录。 |
| D-08 | OpenAPI/tooling：`docs/architecture/openapi/`, `package*.json`, `redocly.yaml`, `scripts/check_openapi_*` | untracked | OpenAPI 是机器可校验 source of truth；tooling 未跟踪时无法在 CI/本地复现 gate。 | 与 API contract 一起合入；不进入 Flutter generated client 阶段前保持 pre-client drift gate。 |
| D-09 | 后端源码：`backend/src/main/java`, `backend/src/main/resources` | 整个 `backend/` untracked | 后端 PB-P0-BE-001A 和 PB-P0-BE-001B 都在同一个 untracked 目录，无法通过普通 diff 精准区分历史步和当前步。 | staging 时必须显式列文件；若需要拆提交，按迁移/基础商业 read endpoints 和 auth/security/current-user 两组人工分拣。不要使用 `git add backend/` 直接全量暂存。 |
| D-10 | 后端测试：`backend/src/test/java`, `backend/src/test/resources` | 跟随 `backend/` untracked | 测试是当前后端完成定义的一部分；漏 stage 会造成“代码有、测试无”的断链。 | 与对应后端实现文件同批 stage；`backend/target/` 继续忽略。 |
| D-11 | `.gitignore` | ` M` | 新增 `node_modules/` 和 `backend/target/` 忽略规则；属于 tooling/backend build hygiene。 | 与 OpenAPI Node tooling 或 backend foundation 提交一起合入；不要单独混入产品文档提交。 |
| D-12 | 报告：`docs/reports/implementation_report.md`, `test_report.md`, `quality_report.md` | `AM` | 三份报告记录了多步历史，包括治理、OpenAPI、PB-P0-BE-001A、PB-P0-BE-001B；直接合并会把多个阶段压成一个审查单元。 | 保留报告时间线，但 merge/staging 时要确认对应代码和上游文档同时进入；必要时按阶段拆分报告段落。 |
| D-13 | 本报告 | 新增 `docs/reports/backend_dirty_traceability_audit.md` | 本报告是审计证据，不是需求、规格或验收 source of truth。 | 可与报告组一并 stage；不得用它替代 `docs/product/base/traceability.md` 或 increment traceability。 |

## 3. 当前后端实现与上游架构符合性

### 3.1 总体结论

结论：条件通过。

- PB-P0-BE-001B 范围内，Spring Security baseline、token/session 边界、current user resolver、`/auth/*` 最小替身、`GET/PATCH/DELETE /user/me` 当前用户绑定、`/entitlements` 和 `/usage/summary` 去除生产 `X-User-Id` 依赖，均有上游依据和测试证据。
- 当前后端不能声明“完整符合商业上线后端架构”。原因是多个 OpenAPI/architecture 已定义但未实现或只做 foundation/stub：entitlement refresh/gating、usage reserve/commit/release、Apple/Google verify/restore、webhook/refund/expiry downgrade、账号删除 processor、admin ops authorization、generated client/Flutter integration。
- 当前后端还存在 3 个需要在进入后续批次前决策或修复的 API/架构契约不一致项，另有 1 个 Backend Agent 输入契约治理项。

### 3.2 后端功能符合性矩阵

| 功能 | 上游依据 | 代码证据 | 测试证据 | 审计结论 |
| --- | --- | --- | --- | --- |
| Spring Security stateless baseline | `docs/architecture/security_design.md`; `docs/architecture/api_contract.md`; OpenAPI `bearerAuth` | `backend/src/main/java/com/speakeasy/security/SecurityConfig.java`, `BearerTokenAuthenticationFilter.java`, `CurrentUser.java`, `TokenHasher.java` | `AuthControllerTest`, `AuthServiceTest`, `CommercialFoundationControllerTest` | 通过。 |
| token/session 边界 | Security Design token refresh/logout；Domain `AuthIdentity`/User；foundation contract identity sessions | `AuthService.java`, `AuthSession.java`, `AuthSessionRepository.java`, `V202605270001__auth_sessions.sql` | `AuthServiceTest.loginCreatesRefreshableSessionBoundToUser`, `AuthControllerTest.refreshRotatesTokenAndLogoutRevokesSession` | 通过；真实 provider verification 仍是下游。 |
| `/auth/login/phone` | Product Base FR-001；OpenAPI `loginPhone` | `AuthController.loginPhone`, `AuthService.loginPhone` | `AuthControllerTest.loginAndGetMeBindToCurrentUser`, `AuthServiceTest.loginRejectsMissingTerms` | 最小替身通过；短信验证码未真实校验，符合本批非目标。 |
| `/auth/login/apple`, `/auth/login/wechat` | Product Base FR-001；P0 FR-COM-005；OpenAPI social login | `AuthController.loginApple`, `AuthController.loginWechat`, `AuthService.loginSocial` | 请求校验和 auth/session 行为通过间接覆盖 | 条件通过；真实 Apple/WeChat token 校验必须进入后续生产登录配置批次。 |
| `/auth/refresh`, `/auth/logout` | Security Design refresh/logout；OpenAPI refresh/logout | `AuthController.refresh/logout`, `AuthService.refresh/logout` | `AuthControllerTest.refreshRotatesTokenAndLogoutRevokesSession`, `AuthControllerTest.refreshRejectsInvalidToken` | 通过。 |
| `GET /user/me` | Product Base FR-010 / AC-011；P0 FR-COM-004；OpenAPI `getMe` | `AuthController.getMe`, `IdentityService.getCurrentUser` | `AuthControllerTest.getMeRequiresBearerToken`, `loginAndGetMeBindToCurrentUser` | 通过；测试证明忽略 `X-User-Id`。 |
| `PATCH /user/me` | Product Base FR-010 / AC-011；OpenAPI `updateMe` | `AuthController.updateMe`, `IdentityService.updateCurrentUser` | `AuthControllerTest.patchMeUpdatesAuthenticatedUserProfile`, `patchAndDeleteMeRequireBearerToken` | 通过。 |
| `DELETE /user/me` | Product Base FR-010 / AC-011；P0 FR-COM-008 / AC-COM-010；OpenAPI `requestAccountDeletion` | `AuthController.requestAccountDeletion`, `IdentityService.requestAccountDeletion`, `AccountDeletionJob` | `CommercialFoundationControllerTest.requestAccountDeletionCreatesJob`, `AuthControllerTest.patchAndDeleteMeRequireBearerToken` | 条件通过；只创建 deletion job 并撤销 session，未实现 idempotency header、完整 processor、数据删除/匿名化。 |
| `GET /entitlements` | P0 FR-COM-001/006/007；OpenAPI `getEntitlements`; ADR 0003 | `CommercialFoundationController.getEntitlements`, `CommercialFoundationService.latestEntitlement/defaultFreeEntitlement` | `CommercialFoundationControllerTest.getEntitlementsReturnsLatestSnapshot`, `entitlementSummaryRequiresAuthentication` | 通过当前用户绑定和 read foundation；refresh/gating 是下游。 |
| `GET /usage/summary` | P0 FR-COM-010 / AC-COM-012；OpenAPI `getUsageSummary` | `CommercialFoundationController.getUsageSummary`, `UsageLedgerRepository` | `CommercialFoundationControllerTest.getUsageSummaryReturnsLedger`, `usageSummaryRequiresAuthentication` | 通过 read foundation；reserve/commit/release 是下游。 |
| `GET /subscription/plans` | P0 FR-COM-001/009；OpenAPI `listSubscriptionPlans` | `CommercialFoundationController.listSubscriptionPlans`, `SubscriptionPlanRepository` | `CommercialFoundationControllerTest.listSubscriptionPlansReturnsOpenApiShapedResponse` | 条件通过；实现当前是 public，OpenAPI 继承全局 bearer auth 且声明 401，需要决策并修正一侧。 |
| `GET /admin/release-health` | P0 FR-COM-012；OpenAPI `opsBearerAuth`; release gates | `CommercialFoundationController.getReleaseHealth`, `SecurityConfig` | `CommercialFoundationControllerTest.releaseHealthRemainsWarningUntilProviderAndReleaseGatesExist` | 条件通过；实现为 public warn stub，不符合 OpenAPI ops auth。生产前必须加 ops authorization 或把 OpenAPI 明确标为临时 public stub。 |
| DB foundation migrations | Domain schema；backend DB foundation contract | `V202605260001__pb_p0_foundation.sql`, `V202605270001__auth_sessions.sql` | `FoundationMigrationTest`, `PostgresFoundationMigrationTest` | 通过；训练 session/evidence 表仍属后续批次。 |

### 3.3 架构/契约不一致项

| 编号 | 严重度 | 问题 | 影响 | 解决方案 |
| --- | --- | --- | --- | --- |
| A-01 | P1 | `DELETE /user/me` 的 OpenAPI 标记 `x-idempotency-required: true`，API contract 也要求账号删除按 `Idempotency-Key` 幂等；当前实现不读取 header，也不返回已有 deletion job。 | 重复请求可能创建多个 deletion job；需求-代码-测试不能声明 100% 符合。 | 在 P0-COM-BE-005 前置或本批补丁中实现 idempotency：新增 deletion job idempotency key 字段/唯一约束或按 active job 返回现有 job，并添加 controller/service tests。 |
| A-02 | P1 | `/admin/release-health` OpenAPI 使用 `opsBearerAuth` 且 403 admin authorization；当前 `SecurityConfig` 对 `GET /admin/release-health` `permitAll()`。 | 管理/发布门禁接口在生产路径暴露；与 Admin/Ops 边界不一致。 | 短期若仅作健康 stub，应在 OpenAPI/报告标明 non-production public stub；推荐实现 ops bearer/role gate 并加未授权/授权测试。 |
| A-03 | P2 | `/subscription/plans` 当前实现和测试允许未登录访问；OpenAPI 继承全局 bearer auth 并声明 401。 | generated client、后端实现、商业付费墙入口对认证策略会产生漂移。 | PM/Architecture 决策：若订阅方案应公开展示，则 OpenAPI 添加 `security: []` 并调整 401；若应登录后可看，则移除 `permitAll()` 并加 401 测试。 |
| A-04 | P2 | `codex/agents/backend.md` 输入仍包含 legacy `docs/product/acceptance_criteria.md`，未显式列 Product Base/increment acceptance/traceability。 | 后续 Backend Agent 可能绕开当前主追溯链。 | 单独治理修正 Backend Agent 输入，添加 `docs/product/base/*` 和 `docs/product/increments/<increment-id>/*`。 |

## 4. 需求-代码-测试追溯审查

### 4.1 当前已实现后端追溯矩阵

| Requirement / AC | 架构/API/领域依据 | Code Evidence | Test Evidence | 状态 |
| --- | --- | --- | --- | --- |
| Product Base FR-001 / AC-002 登录页、登录门禁 | OpenAPI `/auth/login/*`, `/auth/refresh`, `/auth/logout`; Security Design token refresh/logout | `AuthController`, `AuthService`, `AuthSession`, `SecurityConfig` | `AuthControllerTest`, `AuthServiceTest` | 当前后端最小替身已覆盖；真实社交/短信校验例外已记录。 |
| Product Base FR-010 / AC-011 个人中心与设置、退出/注销 | OpenAPI `/user/me`; Domain `User`, `UserProfile`, `AccountDeletionJob` | `AuthController`, `IdentityService`, `UserAccount`, `UserProfile`, `AccountDeletionJob` | `AuthControllerTest`, `CommercialFoundationControllerTest.requestAccountDeletionCreatesJob` | 资料读写和注销入口有证据；完整账号删除 processor 和 idempotency 未完成。 |
| P0 FR-COM-004 / AC-COM-008 生产账号体系不依赖 demo flow | API/Auth + current user boundary | `BearerTokenAuthenticationFilter`, `CurrentUser`, `AuthController`, `CommercialFoundationController` | `AuthControllerTest.loginAndGetMeBindToCurrentUser`; `CommercialFoundationControllerTest.getEntitlementsReturnsLatestSnapshot` | 通过；生产路径不读 `X-User-Id`，仅测试用它证明忽略。 |
| P0 FR-COM-001 / AC-COM-001, AC-COM-005, AC-COM-006 服务端订阅权益事实 | ADR 0003; Domain `SubscriptionPlan`, `Subscription`, `EntitlementSnapshot`; OpenAPI `/subscription/plans`, `/entitlements` | `SubscriptionPlan`, `Subscription`, `EntitlementSnapshot`, `CommercialFoundationService` | `CommercialFoundationControllerTest.listSubscriptionPlansReturnsOpenApiShapedResponse`, `getEntitlementsReturnsLatestSnapshot` | Foundation/read 已覆盖；购买后生效、退款降级、refresh 仍未覆盖。 |
| P0 FR-COM-006 / AC-COM-006 商业权益 gating | OpenAPI `/entitlements`, `/entitlements/refresh`; Security Design entitlement gate | `EntitlementSnapshot`, `CommercialFoundationController.getEntitlements` | `getEntitlementsReturnsLatestSnapshot`, `entitlementSummaryRequiresAuthentication` | 只覆盖读模型和认证边界；真实 gating 属 P0-COM-BE-002。 |
| P0 FR-COM-007 / AC-COM-007 官方场景库 gating | Domain `EntitlementSnapshot`; OpenAPI entitlement family | `EntitlementSnapshot` foundation | entitlement read tests | 条件通过；场景入口 gating 尚无实现和测试。 |
| P0 FR-COM-008 / AC-COM-010 账号注销与数据删除 | Domain `AccountDeletionJob`, `AccountLifecycle`; API `/user/me`; Data Flow account deletion | `IdentityService.requestAccountDeletion`, `AccountDeletionJobRepository` | `requestAccountDeletionCreatesJob` | 只覆盖 job creation/session revocation；数据删除/匿名化/失败重试/audit 未覆盖。 |
| P0 FR-COM-009 / AC-COM-011 商业文案一致性 | OpenAPI `/subscription/plans`; Domain `SubscriptionPlan` | `SubscriptionPlan`, `CommercialFoundationController.listSubscriptionPlans` | `listSubscriptionPlansReturnsOpenApiShapedResponse` | 只覆盖 plan API shape；会员页文案一致和商店商品一致仍需人工/集成验收。 |
| P0 FR-COM-010 / AC-COM-012 AI 成本与滥用控制 | Domain `UsageLedger`, `UsageReservation`; API `/usage/summary`, `/usage/reserve|commit|release` | `UsageLedger`, `UsageReservation`, `CommercialFoundationController.getUsageSummary` | `getUsageSummaryReturnsLedger`, `usageSummaryRequiresAuthentication` | 只覆盖 summary read；reserve/commit/release 和 provider gate 未覆盖。 |
| P0 FR-COM-011 / AC-COM-013 商业边界测试 | Release/test gate docs; Admin/Ops | `AuditLog` foundation; release health warn response | `releaseHealthRemainsWarningUntilProviderAndReleaseGatesExist` | 只覆盖 warning stub；商业事故路径测试矩阵未完成。 |
| P0 FR-COM-012 / AC-COM-014 发布门禁 | OpenAPI `/admin/release-health`; release checklist | `CommercialFoundationController.getReleaseHealth` | `releaseHealthRemainsWarningUntilProviderAndReleaseGatesExist` | 条件通过；ops auth 和最终 release gate 未完成。 |

### 4.2 追溯完整性结论

- 对 PB-P0-BE-001B：需求-代码-测试追溯可以判定为通过，但只限本批定义的最小认证/身份边界。
- 对当前后端全部已实现功能：追溯为条件通过，因为 `/subscription/plans`、`/admin/release-health`、`DELETE /user/me` 存在契约/实现差异或只做 stub。
- 对全量后端 roadmap/OpenAPI：不能判定 100% 追溯。OpenAPI 中已有 47 paths / 51 operations，但当前后端只实现第一批 foundation/auth 子集，未实现的路径必须保持后续批次待办，不能用当前测试报告覆盖。

## 5. 后端测试用例库审查

### 5.1 当前自动化测试库

命令：`mvn.cmd test`

结果：通过，19 tests，0 failures，0 errors，0 skipped。

| 测试类 | 用例数 | 覆盖重点 |
| --- | ---: | --- |
| `AuthControllerTest` | 7 | 未认证保护、登录绑定当前用户、忽略 `X-User-Id`、资料更新、refresh rotation、logout revocation、invalid refresh、unsupported schema version。 |
| `AuthServiceTest` | 3 | login/session 创建、refresh rotation、logout revocation、terms gate。 |
| `CommercialFoundationControllerTest` | 7 | subscription plans shape、entitlement read、usage summary、account deletion job、entitlement/usage auth required、release health warn。 |
| `FoundationMigrationTest` | 1 | H2 migration 创建 PB/P0 foundation 表和 `auth_sessions`。 |
| `PostgresFoundationMigrationTest` | 1 | PostgreSQL 15.17 + Flyway 迁移真实执行。 |

辅助 gate：

- `npm.cmd run check:api-contract`：通过，47 paths，51 operations，26 request examples，47 success examples，54 error examples；Dart drift 为 pre-client generation gate。
- `python scripts/project_agent_runner.py validate`：通过。
- `python scripts/validate_agent_skills.py`：通过。

### 5.2 测试库是否完整

结论：条件通过。

- 已存在后端测试用例库，并且覆盖 PB-P0-BE-001A/B 当前实现。
- 不能声明“全量后端测试用例库已完整”。原因是后续批次功能尚未实现，且相关测试不能被当前 foundation/read/stub 测试代替。
- 不能声明“需求-代码-测试用例 100% 追溯”覆盖所有 Product Base/P0/P0.1 后端目标。当前只能声明 PB-P0-BE-001B 最小切片达到要求，其他需求有明确下游批次或例外。

### 5.3 必补测试用例库条目

| 后续批次 | 必补测试主题 | 追溯目标 |
| --- | --- | --- |
| PB-BE-002 | onboarding/profile/scenario/favorites/review 的 controller/service/repository tests；未授权、跨用户隔离、not found、validation | Product Base FR-002/003/005/006/010 |
| PB-BE-003 | practice session/evidence lifecycle；turn order；resume/complete/abandon；evidence write failure recovery | Product Base FR-007/008/009 |
| P0-COM-BE-002 | entitlement refresh；free/paid gating；usage reserve/commit/release；quota exhausted；idempotency conflict | FR-COM-001/006/007/010; AC-COM-006/007/012 |
| P0-COM-BE-003 | Apple/Google verify/restore；valid/invalid receipt；product mismatch；empty restore | FR-COM-002/003; AC-COM-001..004 |
| P0-COM-BE-004 | webhook signature；duplicate/ordered/out-of-order events；refund/expiry downgrade | FR-COM-002/003/005; AC-COM-005 |
| P0-COM-BE-005 | account deletion idempotency；processor state machine；hard delete/anonymize/retain audit；retry；ops audit | FR-COM-008/011/012; AC-COM-010/013/014 |
| generated client / Flutter | generated Dart client compile/drift；Flutter API integration；secure token storage and logout/delete local cleanup | Product Base FR-001/010/011; P0 commercial UI |

### 5.4 立即应补或决策的测试

| 编号 | 缺口 | 建议 |
| --- | --- | --- |
| T-01 | `DELETE /user/me` idempotency 未测也未实现。 | 新增 `Idempotency-Key` 正/反例测试；实现后再标记 AC-COM-010 完整。 |
| T-02 | `/admin/release-health` ops auth 未测且实现 public。 | 新增 unauthenticated 403 和 ops token 200 测试，或先把 OpenAPI 明确改为临时 public stub。 |
| T-03 | `/subscription/plans` auth 策略和 OpenAPI 不一致。 | 决策后补对应测试：public 200 without bearer，或 unauthenticated 401。 |
| T-04 | `/auth/login/apple|wechat` 只做 providerToken 替身。 | 后续生产配置批次补 provider mock/invalid token/provider unavailable 测试。 |

## 6. 当前能否进入下一批

结论：不建议直接进入下一批实现。

原因：

1. 工作区大量脏改仍未隔离，`backend/` 整体 untracked，后续 staging/merge 容易把治理、产品、架构、后端、报告混成一个不可审查提交。
2. PB-P0-BE-001B 本身通过，但当前后端全局仍有 3 个架构/API 契约不一致项。
3. Product Base 和 P0 commercial 的源追溯文档本身仍未被 Git 跟踪；如果漏合，后端实现会失去上游依据。

建议顺序：

1. 先按 D-01 到 D-13 分组整理 staging，不要 `git add backend/`。
2. 先合入或明确锁定 Product Base/P0 commercial/architecture/OpenAPI source-of-truth。
3. 修复或决策 A-01、A-02、A-03，再进入 PB-BE-002。
4. 每个后续批次必须先在 owning traceability 中补 Code Evidence/Test Evidence 或明确例外，再更新 `docs/reports/test_report.md`。

## 7. 审计验证记录

| 命令 | 结果 |
| --- | --- |
| `git status --short` | 发现 60 `A`、45 `AM`、1 ` M`、16 `??` 条目。 |
| `git status --short lib test android ios web windows macos linux pubspec.yaml pubspec.lock` | 无输出，Flutter/app 路径无脏改。 |
| `python scripts/project_agent_runner.py validate` | passed。 |
| `python scripts/validate_agent_skills.py` | passed。 |
| `npm.cmd run check:api-contract` | passed。 |
| `mvn.cmd test` | 初次在沙箱内因 Maven Central 网络被拒失败；按权限规则联网重跑后 passed，19 tests。 |

## 8. 当前脏改状态快照

以下为本报告写入后的 `git status --short` 快照，用于后续 staging/merge 隔离：

```text
AM .agents/skills/acceptance-criteria-generate/SKILL.md
AM .agents/skills/acceptance-criteria-generate/SPEC.md
AM .agents/skills/api-contract-generate/SKILL.md
AM .agents/skills/api-contract-generate/SPEC.md
A  .agents/skills/code-review-quality/SKILL.md
A  .agents/skills/code-review-quality/SPEC.md
AM .agents/skills/document-content-contract/SKILL.md
AM .agents/skills/document-content-contract/SPEC.md
A  .agents/skills/document-governance/SKILL.md
A  .agents/skills/document-governance/SPEC.md
AM .agents/skills/document-path-governance/SKILL.md
AM .agents/skills/document-path-governance/SPEC.md
AM .agents/skills/document-traceability-check/SKILL.md
AM .agents/skills/document-traceability-check/SPEC.md
A  .agents/skills/domain-model-generate/SKILL.md
A  .agents/skills/domain-model-generate/SPEC.md
AM .agents/skills/feature-spec-generate/SKILL.md
AM .agents/skills/feature-spec-generate/SPEC.md
A  .agents/skills/implementation-report-generate/SKILL.md
A  .agents/skills/implementation-report-generate/SPEC.md
A  .agents/skills/prompt-contract-generate/SKILL.md
A  .agents/skills/prompt-contract-generate/SPEC.md
AM .agents/skills/requirement-refine/SKILL.md
AM .agents/skills/requirement-refine/SPEC.md
A  .agents/skills/screen-spec-generate/SKILL.md
A  .agents/skills/screen-spec-generate/SPEC.md
AM .agents/skills/skill-quality-check/SKILL.md
AM .agents/skills/skill-quality-check/SPEC.md
AM .agents/skills/test-case-generate/SKILL.md
AM .agents/skills/test-case-generate/SPEC.md
 M .gitignore
A  codex/agents/ai_runtime.md
A  codex/agents/backend.md
AM codex/agents/development_orchestrator.md
A  codex/agents/devops.md
A  codex/agents/documentation_governance.md
A  codex/agents/domain_schema.md
A  codex/agents/frontend.md
AM codex/agents/product_manager.md
AM codex/agents/product_object_governance_change.md
AM codex/agents/product_object_governance_check.md
A  codex/agents/qa.md
AM codex/agents/requirement_developer.md
AM codex/agents/system_architect.md
A  codex/agents/ux_review.md
A  codex/templates/adr.template.md
A  codex/templates/change_request.template.md
A  codex/templates/feature_spec.template.md
A  codex/templates/implementation_report.template.md
A  codex/templates/pm_orchestrator_brief.template.md
A  codex/templates/test_report.template.md
A  docs/ai_runtime/ai_eval_cases.md
A  docs/ai_runtime/correction_schema.md
A  docs/ai_runtime/dialogue_state_machine.md
A  docs/ai_runtime/fallback_strategy.md
A  docs/ai_runtime/llm_output_schema.md
A  docs/ai_runtime/prompt_contract.md
A  docs/architecture/adr/0001-development-pipeline.md
AM docs/architecture/api_contract.md
AM docs/architecture/data_flow.md
AM docs/architecture/module_boundary.md
AM docs/architecture/security_design.md
AM docs/architecture/system_overview.md
AM docs/domain/domain_schema.md
AM docs/domain/entity_relationship.md
A  docs/domain/expression_model.md
A  docs/domain/review_model.md
A  docs/domain/scene_model.md
A  docs/domain/user_progress_model.md
AM docs/process/change_request.md
A  docs/process/definition_of_done.md
A  docs/process/product_object_governance_remediation.md
AM docs/process/skill_quality_standard.md
AM docs/process/workflow.md
AM docs/product/acceptance_criteria.md
A  docs/product/baselines/current-mvp.md
AM docs/product/development_status.md
AM docs/product/feature_registry.md
D  旧扁平 feature 需求工件已移除
D  旧扁平 feature 规格工件已移除
A  docs/product/increments/p0-1-expression-automation-training/acceptance.md
A  docs/product/increments/p0-1-expression-automation-training/definition.md
A  docs/product/increments/p0-1-expression-automation-training/requirements.md
A  docs/product/increments/p0-1-expression-automation-training/spec.md
A  docs/product/increments/p0-1-expression-automation-training/traceability.md
AM docs/product/roadmap.md
A  docs/product/stages/p0-1-expression-automation.md
A  docs/product/stages/p0-2-training-memory.md
AM docs/product/traceability_matrix.md
A  docs/product/user_stories.md
A  docs/product/vision.md
A  docs/release/release_checklist.md
A  docs/release/rollback_plan.md
A  docs/release/version_log.md
AM docs/reports/implementation_report.md
A  docs/reports/product_manager_overall_change_review.md
A  docs/reports/product_object_governance_check_report.md
AM docs/reports/quality_report.md
AM docs/reports/test_report.md
A  docs/ux/copywriting_guideline.md
A  docs/ux/screen_spec.md
A  docs/ux/usability_checklist.md
A  docs/ux/user_flow.md
A  scripts/validate_agent_skills.py
?? backend/
?? codex/templates/agent_runner_packet.template.md
?? docs/architecture/adr/0002-whole-app-architecture-stack.md
?? docs/architecture/adr/0003-server-owned-entitlement-and-usage.md
?? docs/architecture/adr/0004-deterministic-training-planner-ai-boundary.md
?? docs/architecture/backend_db_foundation_contract.md
?? docs/architecture/openapi/
?? docs/product/base/
?? docs/product/increments/commercial-subscription-readiness/
?? docs/product/stages/p0-commercial-readiness.md
?? docs/reports/backend_dirty_traceability_audit.md
?? package-lock.json
?? package.json
?? redocly.yaml
?? scripts/check_openapi_contract.py
?? scripts/check_openapi_dart_drift.py
?? scripts/project_agent_runner.py
```

## 9. 本次审计结论

本次审计结论为条件通过：

- PB-P0-BE-001B 当前切片满足最小 auth/security/user identity boundary 要求。
- 当前后端测试库覆盖该切片，但不是全量后端测试用例库。
- 当前后端变更大部分有上游依据，但还不能声明所有后端能力 100% 架构符合和 100% 需求-代码-测试追溯。
- 合并前必须隔离脏改，并处理或显式接受 A-01/A-02/A-03 的契约风险。
