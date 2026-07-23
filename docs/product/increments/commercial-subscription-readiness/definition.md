# Increment Definition：商业化订阅上线准备

## 状态
Draft - Product Manager accepted；PM 阶段开发计划、Domain/API/Architecture/UX 契约门禁和 AC-to-TC 测试用例库已补齐；本增量负责订阅、权益、账号、商业 gating 和发布门禁。AI provider 生产化 residual 已拆到 `commercial-ai-provider-hardening`。

## Increment ID
`commercial-subscription-readiness`

## Active Stage
`docs/product/stages/p0-commercial-readiness.md`

## Primary Capability
- Capability ID：`CAP-COM`
- Sub-capability ID：`CAP-COM-03`

## Affected Capabilities
- Capability IDs：`CAP-ACC`、`CAP-CONTENT`、`CAP-PRACTICE`、`CAP-COACH`、`CAP-MEMORY`
- Sub-capability IDs：`CAP-COM-01`、`CAP-COM-02`、`CAP-COM-04`、`CAP-ACC-01`、`CAP-ACC-03`、`CAP-ACC-04`、`CAP-CONTENT-01`、`CAP-PRACTICE-03`、`CAP-COACH-01`、`CAP-MEMORY-05`

## 上游决策
- `docs/process/change_request.md`：`CR-20260524-001 商业化订阅上线准备`
- Product Base：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`
- `docs/product/feature_registry.md`
- Product Manager 商业化就绪审查结论：当前具备会员入口和 Apple IAP 前端雏形，但尚不具备真实商业订阅上线条件。

## Scope
- 将会员状态从本地展示字段升级为服务端权益事实。
- 建立 Apple 和 Google Play 订阅购买、恢复、校验、续订、退款、宽限期、过期和降级闭环。
- 建立免费/付费权益 gating，覆盖练习次数、AI 深度反馈、场景包、学习报告、离线或其他付费承诺。
- 替换 demo email/member flow，发布构建关闭测试手机号登录，并阻止错误配置进入生产。
- 完成微信、Apple 登录生产配置和后端回调校验。
- 完成账号注销、云端学习数据删除或匿名化、本地学习数据清理、删除日志和用户可理解反馈。
- 对齐会员页、商店文案、隐私申报和真实能力；未完成权益必须隐藏、降级或从付费承诺中移除。
- 建立商业风控：AI 用量控制、速率限制、滥用检测、支付审计、账号操作审计和数据删除审计；对象存储上传、持久化 TTS cache、真实 DashScope evidence、AI 成本看板和生产 AI 数据策略由 `commercial-ai-provider-hardening` 承接。
- 补齐商业边界测试和发布准备。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| COM-SI-001 | 通过 `FR-COM-001` 覆盖服务端订阅权益事实。 |
| COM-SI-002 | 通过 `FR-COM-002` 覆盖 Apple 订阅校验。 |
| COM-SI-003 | 通过 `FR-COM-003` 覆盖 Android 订阅闭环。 |
| COM-SI-004 | 通过 `FR-COM-004` 覆盖生产账号体系。 |
| COM-SI-005 | 通过 `FR-COM-005` 覆盖社交登录生产配置。 |
| COM-SI-006 | 通过 `FR-COM-008` 覆盖账号注销与数据删除。 |
| COM-SI-007 | 通过 `FR-COM-006` 覆盖商业权益 gating。 |
| COM-SI-008 | 通过 `FR-COM-007` 覆盖官方场景库 gating 一致性。 |
| COM-SI-009 | 通过 `FR-COM-009` 覆盖商业文案一致性。 |
| COM-SI-010 | 通过 `FR-COM-010` 覆盖 AI 成本与滥用控制。 |
| COM-SI-011 | 通过 `FR-COM-011` 覆盖商业边界测试矩阵。 |
| COM-SI-012 | 通过 `FR-COM-012` 覆盖发布门禁和合规准备。 |

## Excluded Stage Scope Items
- `COM-SI-013` 到 `COM-SI-017` 已拆分到 `commercial-ai-provider-hardening`，不由本订阅增量关闭。

## Uncovered Required Stage Scope Items
- 无。`COM-SI-001` 到 `COM-SI-012` 的下游契约、实现、测试和发布证据缺口记录在 `docs/product/increments/commercial-subscription-readiness/traceability.md`；`COM-SI-013` 到 `COM-SI-017` 的缺口记录在 `docs/product/increments/commercial-ai-provider-hardening/traceability.md`。

## Non-goals
- 不负责训练 Agent 的 session 内 planner、micro-action、hint ladder 或 pressure check。
- 不负责新增 3-5 个场景包、A1-C2 内容体系、CMS 或内容生产工具。
- 不承诺离线内容包和成就系统在本增量内完成；如果它们作为会员权益保留，则必须单独拆分并进入商业承诺一致性检查。
- 不直接实现代码；本定义用于后续 Requirements、Spec、Acceptance、Traceability 和下游契约门禁。

## Required Product Artifacts
- `docs/product/increments/commercial-subscription-readiness/requirements.md`
- `docs/product/increments/commercial-subscription-readiness/spec.md`
- `docs/product/increments/commercial-subscription-readiness/acceptance.md`
- `docs/product/increments/commercial-subscription-readiness/traceability.md`

## Required Downstream Gates
- Domain Schema：订阅、权益、计划、购买、退款、宽限期、用量、账号删除和审计日志域对象。
- API Contract：订阅校验、权益查询、恢复购买、Google purchase token 校验、账号删除、用量查询和用量扣减接口。
- Architecture / Security：服务端权益事实、支付校验边界、AI 成本控制、数据删除、审计日志和密钥管理方案。
- UX / Screen Spec：付费墙、超限态、购买失败、恢复购买为空、订阅过期、退款后降级、账号注销确认和文案一致性。
- QA / Test Plan：商业边界测试矩阵和自动化/人工验收记录。
- DevOps / Release：iOS/Android 发布链路、release secrets、签名、Sentry 符号表、商店审核材料和回滚策略。
- Product Object Governance Check：每个下游门禁完成后需独立复核是否偏离本 increment。
- Documentation Governance：发布前复核 requirements/spec/acceptance/traceability、release checklist 和测试报告链路是否完整。

## PM 阶段开发计划

### 计划状态
Ready for implementation routing after independent checker pass - 当前 Product Manager 已完成 stage、increment、requirements、spec、acceptance、traceability、Domain/API/Architecture/UX 契约证据和 AC-to-TC 测试用例库。实现、外部 provider、DevOps/release 和 QA 执行证据仍未开始，不能据此声明商业发布 ready。

### 产品分类
| 字段 | 决策 |
| --- | --- |
| User request classification | product direction / planning request |
| Product object mode | `feature-increment`，基于 active `CAP-COM` / `CAP-COM-03` classification 和 `commercial-subscription-readiness` increment 继续规划 |
| Priority | P0 release-blocking |
| Active stage | `p0-commercial-readiness` |
| Covered Stage Scope Items | `COM-SI-001` 到 `COM-SI-012` |
| Scope change required | 不需要。`CR-20260524-001` 已接受；AI provider 生产化扩展由 `CR-20260601-002` 和 `commercial-ai-provider-hardening` 单独承接 |
| Implementation readiness | Ready for Backend/Frontend/AI Runtime/DevOps implementation routing after independent checker pass；commercial release readiness remains blocked |

### Milestone Plan
| Milestone | 目标 | 完成判断 |
| --- | --- | --- |
| M0 PM scope ready | 阶段范围、增量定义、FR、Spec、AC、traceability 和开发计划齐备 | 本文件和 `docs/product/stages/p0-commercial-readiness.md` 明确范围、非目标、Stage Scope Items 和下游门禁 |
| M1 Contract ready | Domain、API/OpenAPI、Architecture/Security 和 UX/Screen Spec 可供实现消费 | 所有 contract gaps 关闭，并通过 Product Object Governance Check 或 Documentation Governance |
| M2 Test gate ready | AC-to-TC 映射完成，允许路由实现 | `test_cases.md` 覆盖 `AC-COM-001` 到 `AC-COM-014`，未自动化项有明确 `manual-verification` 或 `external-dependency` 例外 |
| M3 Commercial foundation RC | 生产账号、权益事实、账号删除、用量和 gating 基础闭环可测 | 后端、前端、AI gateway 和 Flutter client 形成可自动化验证的最小商业基础闭环 |
| M4 Payment provider RC | Apple/Google 购买、恢复、退款、过期和 provider event 处理可在沙盒/内测验证 | 商店沙盒或内部测试证据覆盖购买、恢复、无效凭据、空恢复、过期/退款降级 |
| M5 Store readiness RC | 发布配置、隐私、商店材料、签名、release secrets、观测和回滚齐备 | release checklist、rollback plan、version log、test report 和 quality report 记录证据 |
| M6 PM release decision | Product Manager 判断是否允许进入商业发布口径 | 所有 required Stage Scope Items 有 code/test/release evidence 或显式外部门禁例外 |

### Work Package Sequence
| Order | Work Package ID | Route / Owner | Scope | Stage Scope Items | Required output | Gate / checker |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | P0-COM-PM-001 | Product Manager | 锁定商业化 stage、increment、范围、非目标和优先级 | COM-SI-001..012 | 本 increment definition、stage doc、development status | Product Object Governance Check |
| 1 | P0-COM-DOM-001 | Domain Schema Agent / `domain-model-generate` | 复核并补齐 subscription、purchase、entitlement、usage、account deletion、audit、provider event 状态机 | COM-SI-001,002,003,006,007,010 | `docs/domain/domain_schema.md`、必要的专项 domain doc | Product Object Governance Check |
| 2 | P0-COM-API-001 | System Architect / `api-contract-generate` | 关闭 entitlement、verify/restore/webhook、usage、account deletion、release health API gap，并决策 `/subscription/plans` 认证策略 | COM-SI-001,002,003,004,006,007,008,010,012 | `docs/architecture/api_contract.md`、`docs/architecture/openapi/speakeasy-api.yaml` | `npm run check:api-contract`，Product Object Governance Check |
| 3 | P0-COM-ARCH-001 | System Architect | 完成商业订阅 stage 级 Architecture/Security，覆盖服务端权益事实、支付边界、secret、审计、成本、删除和回滚 | COM-SI-001..010,012 | `docs/architecture/system_overview.md`、`docs/architecture/security_design.md`、必要 ADR | document-traceability-check，Product Object Governance Check |
| 4 | P0-COM-UX-001 | UX Review / `screen-spec-generate` | 会员页、付费墙、超限态、购买/恢复状态、降级、账号注销、本地清理和商业文案一致性 | COM-SI-006,007,008,009 | `docs/ux/screen_spec.md`、`docs/ux/user_flow.md`、`docs/ux/copywriting_guideline.md` | Documentation Governance，Product Object Governance Check |
| 5 | P0-COM-QA-001 | QA / `test-case-generate` | 建立商业边界 AC-to-TC 测试用例库，定义自动化、人工验收和外部依赖例外 | COM-SI-001..012 | `docs/product/increments/commercial-subscription-readiness/test_cases.md` | AC-to-TC gate pass；未通过前不得实现 |
| 6 | P0-COM-BE-001 | Backend Agent | 生产账号、token/session、账号删除幂等、ops auth、权益读写和基础审计硬化 | COM-SI-001,004,005,006,012 | 后端代码、migration、backend tests、traceability code/test evidence | Backend tests，QA review，Product Object Governance Check |
| 7 | P0-COM-BE-002 | Backend Agent / AI Runtime as needed | Entitlement refresh、免费/付费 gating、usage reserve/commit/release、AI/ASR/TTS/评分用量控制 | COM-SI-001,007,008,010 | 后端/API/AI gateway gating 实现和测试 | Backend/API tests，usage and entitlement traceability；生产媒体链路和成本看板另见 `commercial-ai-provider-hardening` |
| 8 | P0-COM-BE-003 | Backend Agent / DevOps | Apple/Google verify、restore、webhook/provider event、退款/过期/宽限期/撤销降级 | COM-SI-002,003 | payment provider adapter、sandbox fixtures、webhook tests | Provider sandbox/internal evidence；external-dependency exceptions allowed only with owner/evidence plan |
| 9 | P0-COM-FE-001 | Frontend Agent | Flutter 会员页、付费墙、权益刷新缓存、Android Billing、restore、降级、本地账号注销清理 | COM-SI-002,003,006,007,008,009 | Flutter code、widget/integration tests、generated client drift evidence | Flutter tests，UX review，commercial copy check |
| 10 | P0-COM-REL-001 | DevOps Agent | release secrets、签名、Sentry/dSYM/ProGuard、商店元数据、隐私申报、审核账号、rollback | COM-SI-005,009,011,012 | `docs/release/release_checklist.md`、`docs/release/rollback_plan.md`、`docs/release/version_log.md` | DevOps review，Documentation Governance |
| 11 | P0-COM-QA-002 | QA Agent | 商业边界测试执行：购买、恢复、退款、过期、宽限期、账号切换、注销、弱网、权限拒绝、崩溃恢复、额度耗尽 | COM-SI-011,012 | `docs/reports/test_report.md`、traceability Test Evidence | QA pass 或明确 release blocker |
| 12 | P0-COM-REPORT-001 | Codex Root + Documentation Governance | 汇总 implementation、quality、release evidence，并向 PM 返回 release-readiness finding | COM-SI-001..012 | `docs/reports/implementation_report.md`、`docs/reports/quality_report.md`、release evidence | PM release decision |

### Current Legal Next Step
Codex Root 在独立 checker pass 后可开始路由实现批次，建议先执行 `P0-COM-BE-001` 商业 foundation hardening，再依次路由 `P0-COM-BE-002` 权益/用量 gating、`P0-COM-BE-003` provider verify/webhook、`P0-COM-FE-001` Flutter 商业 UI 和 `P0-COM-REL-001` release gate。任何商业发布口径仍必须等待 QA 执行、provider sandbox/internal test、release evidence、quality report 和 PM release decision。

Paid AI voice 或真实 DashScope provider 上线还必须执行 `commercial-ai-provider-hardening` 的 `P0-AI-*` work packages；不得用本增量的用量 gating 证据替代对象存储上传、持久化 TTS cache、DashScope live evidence、成本看板和生产数据策略。

### 2026-06-03 PM 下一步执行批次
本增量的本地实现、契约、自动化边界和商业边界复测已有证据；下一阶段不再优先重复本地实现批次，而是关闭 strict external/native/store/release evidence。

| Order | Work Package ID | Route / Owner | Scope | Blocks | Required evidence | Gate / checker |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | P0-COM-EXT-001 | DevOps / QA / Product Manager | Apple sandbox 与 Google Play internal-test provider evidence | TC-COM-019 | `APPLE_SANDBOX_EVIDENCE_REF`、`GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` | `scripts/check_provider_sandbox_evidence.py --strict-external`、QA review |
| 2 | P0-COM-NATIVE-001 | DevOps / Frontend | WeChat 与 Apple native social-login release config evidence | TC-COM-012 | `WECHAT_APP_ID`、`WECHAT_UNIVERSAL_LINK`、非 placeholder URL scheme、Apple Sign In entitlement evidence | `scripts/check_social_login_release_config.sh`、native config review |
| 3 | P0-COM-STORE-001 | Product Manager / UX / DevOps | 会员页、商店文案、隐私/support/reviewer evidence | TC-COM-015, TC-COM-021 | `STORE_METADATA_EVIDENCE_REF`、`REVIEWER_ACCOUNT_REF`、`PRIVACY_URL`、`SUPPORT_URL` | `scripts/check_store_submission_evidence.py --strict-external`、commercial copy review |
| 4 | P0-COM-REL-002 | DevOps / QA | Strict release configuration、secrets、signing、symbols、rollback rehearsal evidence | TC-COM-022 | production API URL、`ENV=production`、signing/Sentry/symbol/rollback refs | `scripts/check_release_readiness.sh`、Documentation Governance |
| 5 | P0-COM-QA-003 | QA / Product Object Governance Check | 汇总 strict evidence 并 rerun commercial release gates | TC-COM-012,015,019,021,022 | `docs/reports/test_report.md`、`docs/reports/quality_report.md`、release checklist updates | PM release-readiness decision |

PM release decision 只接受 strict gate pass 和独立审核后的 evidence；non-strict structure pass、local deterministic provider pass 或现有会员页 UI 不足以关闭商业发布阻塞项。

### Dependency And Blocker Register
| Blocker ID | 阻塞内容 | 影响 | 解除条件 |
| --- | --- | --- | --- |
| COM-BLOCK-001 | `test_cases.md` 尚未建立 | 已解除：允许进入实现路由前还需独立 checker pass | `AC-COM-001` 到 `AC-COM-014` 已映射到稳定 TC ID 或明确例外 |
| COM-BLOCK-002 | Apple/Google 真实商店配置和沙盒/内测证据缺失 | 不允许声明商业发布 ready | DevOps 提供 App Store / Play Console 配置、商品、审核账号和测试证据 |
| COM-BLOCK-003 | 生产社交登录配置未验证 | 不允许商店版开放占位登录 | 微信、Apple 登录配置和后端校验通过测试或发布阻断 |
| COM-BLOCK-004 | 当前后端 foundation/read/stub 不能等同完整商业闭环 | 不允许把已有 `/entitlements`、`/usage/summary` 或 release-health stub 视为 P0 完成 | 后续 work packages 补齐 verify、gating、usage、webhook、release auth 和证据 |
| COM-BLOCK-005 | 商业文案可能承诺未实现能力 | 不允许以未完成权益作为付费卖点 | UX/PM/Release 完成会员页、商店文案、隐私说明一致性审查 |

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent；商业化实现完成前还需要 Documentation Governance、QA、DevOps 和安全/合规复核。
