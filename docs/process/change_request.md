# 变更请求

## 状态
模板与流程基线。

## 必填字段
- id
- date
- requester
- affected feature
- change summary
- reason
- scope impact
- architecture impact
- domain impact
- API impact
- AI runtime impact
- UX impact
- test impact
- release impact
- decision
- follow-up

## 决策取值
- proposed
- accepted
- rejected
- deferred

## 规则
被接受的变更请求必须先更新相关源文档，之后才能开始实现。

## CR-20260523-001 表达自动化训练 Agent

### id
CR-20260523-001

### date
2026-05-23

### requester
当前规划线程中的产品请求。

### affected feature
场景练习、表达学习、复习、AI runtime、用户进度。

### change summary
将现有语音场景模拟升级为训练型 Agent：在 `job_interview` 和 `onboarding_introduction` 两个官方场景中，把场景动作链拆成听一句、选一个、回一句、跟一句、补一句、在追问下继续说等 micro-action；由 session 内 planner 接管训练组织、提示阶梯、重试、降级、升级、即时反馈和轻量压力检测，并把每轮学习证据写回。跨 session/跨天复现、L0-L5 掌握阶梯和长期记忆调度放入 P0.2。

### reason
当前 MVP 已覆盖场景练习、结构化纠错、表达保存和基础复习。该增量用于强化产品核心承诺：让教练主动编排训练，而不是只对开放练习回合做被动回应。

### scope impact
扩展 MVP 行为。P0.1 第一版限制为 2 个现有官方场景、1 套 session 内训练 planner、1 套 micro-action flow、1 套 hint ladder、1 套 in-session pressure check 和训练证据写回规则；不新增第三个场景，不承诺跨 session/跨天调度，不引入完整 L0-L5 掌握阶梯。

### architecture impact
需要新增 session 内训练 planner，或扩展当前场景编排器，使当前小动作、目标表达、提示等级、重试、降级、升级和轻量施压的决策保持确定性并可测试。长期掌握状态推进和跨 session 调度留到 P0.2。

### domain impact
P0.1 需要正式定义训练单元、action chain step、micro-action、hint level、session 阶段、轻量压力检测和学习证据写回。表达技能图谱、L0-L5 用户表达掌握等级、跨天复现规则和长期记忆调度属于 P0.2 域模型扩展。

### API impact
如果训练状态需要在本地存储之外持久化，可能影响前后端契约。第一版可根据实现阶段选择本地或 repository-backed 方式。

### AI runtime impact
需要更新 prompt 契约，使 LLM 返回结构化提示、反馈和追问建议；LLM 不得直接拥有持久化掌握状态的变更权。

### UX impact
需要支持一次一个微动作、支架化重试、场景 drill、hint ladder、轻量追问、session recap 和本轮下一步建议等 UI 状态。跨天复现安排不进入 P0.1 UI 承诺。

### test impact
需要补充 session 阶段流转、planner 决策、hint ladder 升降级、轻量压力检测、训练证据写回的单元测试；AI 输出 schema 校验测试；训练闭环的 widget 测试。L0-L5 掌握状态推进和跨 session 回退规则测试留到 P0.2。

### release impact
建议通过小场景包或 feature flag 发布，先验证训练闭环再扩大内容范围。

### decision
accepted

### follow-up
Product Manager 接受该变更为后续产品路线，但分阶段落地：
- P0.1：在现有 `job_interview` 和 `onboarding_introduction` 官方场景中落地语音优先、文本兜底的 FSI 式表达自动化训练闭环，并明确包含 session 内训练 planner、micro-action UI/flow、hint ladder 和 in-session pressure check。
- P0.2：强化跨 session/跨天训练编排、压力阶梯、L0-L5 掌握等级和长期记忆引擎。
- P1/P2：再扩展任意短语笔记、评分产品化、更多场景包和 A1-C2 内容体系。

P0.1 标准起始工件：`docs/product/increments/p0-1-expression-automation-training/definition.md`。

Legacy P0.1 spec source：`docs/product/features/mvp-learning-loop-spec.md`，已迁移或提炼到：
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/spec.md`
- `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- `docs/product/increments/p0-1-expression-automation-training/traceability.md`

## CR-20260601-001 当前后端 DashScope AI Provider Gateway

### id
CR-20260601-001

### date
2026-06-01

### requester
当前实现线程中的用户请求。

### affected feature
`expression-automation-training`、`voice-scenario-practice`、`scoring-feedback`、`commercial-subscription`、AI runtime、后端 AI Gateway。

### change summary
参考旧 `speakeasy_backend_export` 中 DashScope Qwen、Paraformer ASR 和 TTS 的接入策略，但不切换后端工程；在当前 Spring Boot 后端中保留 `AiProviderGateway` 抽象和 `DeterministicAiProviderGateway` 测试实现，新增可配置的 DashScope provider adapter。Flutter 仍只调用当前 AI REST API，不接触 provider secret。

### reason
P0.1 训练闭环和商业化用量控制都需要真实 LLM/TTS/ASR 能力落在服务端可信边界内。当前 deterministic provider 只能支持本地测试，不能作为真实商业能力、成本统计、provider fallback 或外部服务验收证据。

### scope impact
该变更不新增官方场景、不新增 P0.2/P1/P2 范围，不改变 P0.1 的训练产品目标。它补强 P01-SI-007 语音主路径、P01-SI-008 即时反馈与评分边界、P01-SI-011 可恢复失败的后端 provider 依赖。

### architecture impact
当前后端继续使用 `AiProviderGateway` 作为 provider interface。新增 DashScope adapter 只能位于后端 AI Gateway 后面，必须复用现有 auth、usage reservation/commit/release、schema validation 和 typed fallback 边界；不得复制旧 Node/FastAPI 路由或让 Flutter 直连 DashScope。

### domain impact
不新增持久化 domain entity。`audio_ref` 在本轮被定义为后端/provider 可访问的媒体引用；客户端本地文件路径不得被当作真实 ASR provider 输入。TTS cache 首版可使用后端 adapter 内部缓存键，持久对象存储缓存作为后续 release-hardening 项记录。

### API impact
不新增 AI REST path。现有 `/ai/transcribe`、`/ai/tts`、`/ai/pronunciation`、`/ai/coach-turn`、`/ai/feedback` 的 request/response 契约继续有效，并补充 provider adapter、media ref、fallback 和 no client secret 的契约说明。

### AI runtime impact
LLM provider 输出必须限制为结构化 JSON，并由后端 adapter 映射为现有 `CoachResult` / `CoachFeedbackDto`。无效 JSON、provider unavailable、ASR no result 或 TTS unavailable 必须返回 typed fallback/status，不得生成伪成功反馈或最终学习证据。

### UX impact
无新增 UI 范围。前端继续消费 AI REST 的 normalized status，并在 P0.1 training session view / existing practice page 中展示重试、文本兜底或可恢复失败。

### test impact
新增后端 provider adapter contract tests：provider selection、DashScope LLM JSON parse/fallback、ASR media ref handling、ASR success/unavailable、TTS response/cache/unavailable。保留 deterministic provider integration tests，避免默认测试依赖真实第三方服务。

### release impact
真实 DashScope 上线需要 `DASHSCOPE_API_KEY`、模型配置、timeout、成本监控、provider status metrics、对象存储/媒体引用策略和外部服务验收记录。没有真实凭据和可访问媒体引用时，不得把 live provider E2E 标记为 passed。

### decision
accepted

### follow-up
- 更新 P0.1 requirements/spec/acceptance/test_cases/traceability，保证 provider adapter 需求能追溯到 P01-SI-007、P01-SI-008、P01-SI-011。
- 更新 architecture/API/AI runtime 文档，记录当前后端 provider adapter、media ref、fallback 和商业化用量边界。
- 在当前 Spring Boot 后端新增 DashScope provider adapter；保留 deterministic provider 作为默认 test/dev 实现。
- 运行后端 unit/contract tests、OpenAPI/API contract gates 和项目 agent validation；真实 DashScope live E2E 仅在具备外部凭据和媒体对象后执行。

## CR-20260524-001 商业化订阅上线准备

### id
CR-20260524-001

### date
2026-05-24

### requester
当前规划线程中的商业化订阅产品请求。

### affected feature
`commercial-subscription`、`profile-membership`、`access-onboarding`、`voice-scenario-practice`、`official-scenario-library`、`learning-memory-review`、`scoring-feedback`。

### change summary
将当前“会员页 + Apple IAP 前端雏形”升级为真实商业订阅上线准备增量。范围包括生产账号、Apple/Google 订阅校验、服务端权益持久化、Android Billing、免费/付费权益 gating、账号注销与数据删除、会员页文案一致性、商业风控、AI 成本控制、支付审计、隐私申报和商店发布门禁。

### reason
Product Manager 商业化就绪审查判断：当前 APP 适合继续内测或做付费前准备，但不适合直接面向真实用户收费。主要原因是缺少服务端权益、Android 支付、生产账号、完整商业 gating、账号删除闭环和商业发布测试矩阵。若直接上线付费，会出现付款后权益不可恢复、退款或过期后继续开放、客户端伪造会员状态、AI 成本失控、商店文案承诺无法兑现等风险。

### scope impact
新增 P0 商业化发布阻塞阶段和 `commercial-subscription-readiness` 增量。该增量与 P0.1 表达自动化训练闭环并行，不替代训练 Agent，也不把商业 gating 作为 P0.1 训练闭环前置条件。商业化付费发布前必须补齐本变更范围。

### architecture impact
需要明确客户端、后端、商店、AI runtime、账号服务和发布流水线的边界。订阅权益事实必须由服务端产生和保存，客户端只展示和请求刷新权益。AI/ASR/TTS 用量限制、权益 gating 和审计日志应在服务端或可信边界执行。

### domain impact
需要定义 subscription、entitlement、plan、purchase、receipt verification、refund、grace period、usage quota、account deletion job、audit log 等域对象。需要定义订阅状态机和权益状态机，覆盖 free、pending、active、grace、expired、refunded、revoked 等状态。

### API impact
需要补齐或确认订阅校验、权益查询、恢复购买、Google purchase token 校验、账号删除、用量查询、用量扣减、审计日志等 API 契约。错误码必须覆盖未登录、无权益、额度耗尽、收据无效、商品不匹配、订阅过期、恢复购买为空等情况。

### AI runtime impact
AI runtime 需要接入用量限制、成本控制和无权益/额度耗尽兜底。LLM、ASR、TTS、发音评分等高成本能力不能只依赖前端开关控制。

### UX impact
需要新增或调整付费墙、超限态、购买处理中、购买失败、恢复购买为空、订阅过期、退款后降级、账号切换后权益刷新、账号注销确认和数据删除反馈。会员页、商店文案和实际能力必须一致；未完成权益不得作为已兑现承诺。

### test impact
需要补充商业边界测试矩阵：首次安装、旧本地数据升级、手机号/Apple/微信登录、购买、恢复、退款、过期、宽限期、账号切换、注销、弱网、麦克风/语音权限拒绝、崩溃恢复、AI 额度耗尽和滥用防护。支付、权益 gating、账号生命周期和文案一致性必须有自动化或人工验收记录。

### release impact
付费发布前必须补齐 App Store Connect / Play Console 元数据、订阅条款、隐私申报、支持 URL、审核测试账号、iOS/TestFlight/App Store 发布链路、Android/Play Console 发布链路、签名、release secrets、Sentry 符号表上传和回滚策略。

### decision
accepted

### follow-up
Product Manager 接受该变更为付费上线前的 P0 发布阻塞增量：
- 新增 stable feature：`commercial-subscription`。
- 新增 stage：`docs/product/stages/p0-commercial-readiness.md`。
- 新增 increment definition：`docs/product/increments/commercial-subscription-readiness/definition.md`。
- 已补齐 `commercial-subscription-readiness` 的 requirements、spec、acceptance 和 traceability。
- Development Orchestrator 后续应路由 Domain Schema、API Contract、Architecture/Security、UX/Screen Spec、Backend、Frontend、QA/Test Plan、DevOps/Release 和独立 checker agent，逐步补齐商业发布门禁。

## CR-20260601-002 商业 AI Provider 生产化加固

### id
CR-20260601-002

### date
2026-06-01

### requester
当前规划线程中的产品请求。

### affected feature
`ai-provider-operations`、`voice-scenario-practice`、`expression-automation-training`、`listening-shadowing`、`scoring-feedback`、`commercial-subscription`。

### change summary
将 P0.1 DashScope provider adapter 的 release residual 提升为独立 P0 商业化发布阻塞增量，覆盖对象存储上传链路、持久化 TTS 缓存、真实 DashScope sandbox / controlled live 测试、AI 成本看板和生产级 AI 数据策略。

### reason
当前后端已经有 DashScope LLM/TTS/ASR adapter、签名媒体元数据、进程内 TTS cache、schema validation、tier policy 和 hashed media audit 的本地测试证据，但这只能证明本地边界。真实付费流量开放前，还必须证明生产 ASR media lifecycle、跨实例 TTS 成本控制、真实 provider SLA/错误/费用、套餐毛利和数据保留/删除策略。

### scope impact
新增 P0 `commercial-ai-provider-hardening` increment。该增量不改变 P0.1 训练 Agent 产品范围，不新增场景，不实现 P1 级 BI 或多 provider 路由；它负责把 AI provider 生产化能力纳入商业发布门禁。

### architecture impact
需要补齐对象存储、signed media ref、persistent cache、cost telemetry/dashboard、retention/deletion job 和 provider sandbox evidence 的架构边界。现有 `AiProviderGateway` 抽象继续保留，Flutter 仍不得直连第三方 provider。

### domain impact
需要定义 MediaAsset、TtsCacheEntry、ProviderInvocationMetric、ProviderSandboxRun、RetentionPolicy 等域对象或等价事实边界。

### API impact
需要新增或确认 media upload/signing、media ref resolution、cost dashboard read 和 provider evidence/admin 状态 API。实现前必须更新 OpenAPI 或明确内部 ops-only 契约。

### AI runtime impact
需要补齐 DashScope LLM、Paraformer ASR 和 TTS 的真实 sandbox/eval matrix，记录 latency、error code、cost estimate、format compatibility 和 fallback mapping。fake transport 不能关闭真实 provider evidence。

### UX impact
主用户 UI 不新增页面；Flutter 录音路径需要从本地路径提交改为 upload-to-backend/object-storage 后再提交后端 `audio_ref`。Ops/PM 需要最小成本看板。

### test impact
新增 TC-COM-AI-001 到 TC-COM-AI-007，覆盖 media upload/ref、production ASR guard、persistent TTS cache、DashScope sandbox evidence、AI cost dashboard、retention/deletion 和 account deletion media cleanup。

### release impact
商业发布前必须具备 object storage lifecycle、DashScope evidence ref、budget alert/cost dashboard、retention/deletion evidence 和独立审查。缺少任一项时不得关闭 P01-GAP-008 或声明 paid AI voice ready。

### decision
accepted

### follow-up
- 新增 stage scope：`COM-SI-013` 到 `COM-SI-017`。
- 新增 increment：`docs/product/increments/commercial-ai-provider-hardening/definition.md`。
- 更新 roadmap、feature registry、P0 stage、commercial readiness 文档、architecture/security/release 和 reports，明确这 5 项是 P0 AI provider 生产化加固，而不是 P0.1 本地 adapter 已完成项。
