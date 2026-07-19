# 跨切面边界注册表

## 目的

本注册表记录项目中容易被局部实现绕过的跨切面能力边界。它用于约束实现计划、代码审查和后续验证：当一个需求触及已登记能力时，实施方必须复用授权入口，不得重新发明事实源、网关、上传链路或状态裁决规则。

本文件是治理注册表，不替代 Product Base、increment requirements/spec/acceptance/test_cases/traceability、架构契约、实现报告、测试报告、质量报告或发布证据。

## 使用规则

- 新需求、bugfix、refactor 或实现计划触及下表能力时，必须引用对应 Boundary ID。
- 实施计划必须说明复用的授权入口、禁止的绕过路径、需要补齐的 legacy 迁移或例外。
- 若新增跨切面能力，必须先在本注册表登记 owner、授权入口、禁止行为和验证证据，再进入跨层实现。
- 若现有代码暂时无法遵守某条边界，必须登记为 legacy exception 或明确阻塞，不得把例外当成稳定路径。
- Issue、PR 或报告只能引用本表作为治理约束；不能用本表直接声明需求完成、优先级确认、release ready 或 Product Base merge。

## 边界表

| Boundary ID | 跨切面能力 | 事实源/拥有方 | 授权入口 | 禁止行为 | 最低验证证据 | Owner / Checker |
| --- | --- | --- | --- | --- | --- | --- |
| XCB-001 | 音频媒体上传与 `audio_ref` | Backend MediaAsset / AI Gateway | `POST /media/audio/uploads`、对象存储 `upload_url`、`POST /media/audio/uploads/{media_id}/complete`、业务接口消费后端返回的 `media://audio/...` | Flutter 生成、拼接、推断或持久化 `audio_ref`；把本地文件路径、裸 URL、未验证 ref 当成生产 ASR/评分输入；新建第二套媒体上传系统 | API/OpenAPI 契约、Dart client drift、非法 ref negative tests、上传 create/complete/idempotency tests、Flutter 上传桥接测试 | Backend + Frontend + AI Runtime / QA + Evidence Reviewer |
| XCB-002 | AI provider 调用与用量治理 | Backend AI Gateway | `AiGatewayService`、`AiProviderPolicyService`、`UsageService`、provider gateway adapter | 业务 service 直接调用 provider 并绕过权限、用量、媒体校验、fallback 和审计；provider 输出直接写最终事实 | provider policy tests、usage reservation/commit/release tests、fallback tests、forbidden-field AI evals | Backend + AI Runtime / QA |
| XCB-003 | OpenAPI 与 generated client | OpenAPI source of truth | `docs/architecture/openapi/speakeasy-api.yaml` + generated Dart client | 手写 generated client 语义；新增跨层接口但不更新 OpenAPI；绕过 drift gate | OpenAPI lint、contract check、Dart generated client drift check | Backend + Frontend / QA |
| XCB-004 | 会员权益、额度和商业事实 | Backend Commerce/Entitlement/Usage | Entitlement、subscription、usage API family | Flutter 本地判定最终权益、额度、账单、退款或商业发布状态；AI/provider 创建权益事实 | entitlement tests、quota/cost downgrade tests、release gate evidence | Backend + DevOps / QA + Evidence Reviewer |
| XCB-005 | Goal Autopilot 目标、诊断、预测和 checkpoint 事实 | Backend Goal Autopilot domain | Goal Autopilot API family and deterministic policies | Flutter 本地推断最终 goal 状态、ETA、claim guard、diagnostic mode、confidence band；LLM/provider 直接写持久状态 | backend policy tests、projection tests、low-confidence downgrade tests、claim guard tests | Backend + Frontend + AI Runtime / QA + Evidence Reviewer |
| XCB-006 | 数据保留、导出、删除和审计 | Backend data governance / Ops | Account deletion、retention、export、redacted audit paths | 新表或新媒体事实不接入删除/导出/retention；日志、报告或 API 暴露 raw audio、raw transcript、provider payload、secret 或完整 signed URL | account deletion tests、export redaction tests、retention job tests、log/report redaction review | Backend + DevOps / QA + Evidence Reviewer |
| XCB-007 | Product source of truth 与 issue tracking | Product Manager / local product artifacts | Product Base、stage、increment、traceability、issue-management tracking | 用 issue、PR、报告或实现代码替代 PM 分类、需求、验收、测试、traceability、release evidence 或 Product Base merge | issue body source-of-truth links、traceability check、quality review | Product Manager + Documentation Governance / Product Object Governance Check |
| XCB-008 | 场景练习与共享运行时复用 | Software Component Architecture / SWC Catalog | `FE-SCENARIO-PRACTICE`、`FE-PRACTICE-RUNTIME`、`SWC-FLOW-SCENARIO-PRACTICE-RUNTIME` | 为同一交互主干新建重复 session、voice、message、TTS、history 或 recovery runtime；绕过既有共享组件和 Flow | `scripts/check_swc_allocation.py`、受影响 allocation 的 SWC/Flow 引用、复用与禁止边界证据 | Frontend + System Architect / Software Architecture Governance Check |

## XCB-001 详细说明：统一音频上传主干与业务消费边界

### 统一可信上传主干

所有生产音频输入必须先进入同一条可信上传主干：

```text
Flutter 录音或选择本地临时音频
-> POST /media/audio/uploads 创建后端媒体上传记录
-> Flutter 按后端返回的 upload_url 和 upload_headers 上传音频 bytes
-> POST /media/audio/uploads/{media_id}/complete 确认上传完成
-> 后端校验归属、格式、大小、时长、checksum、object_ref 和状态
-> 后端确认或返回 media://audio/{media_id}
```

`audio_ref` 是后端媒体事实引用，不是音频 bytes，也不是 Flutter 本地文件路径。Flutter 可以把后端返回的 `audio_ref` 写入后续业务接口请求体，表示“该业务输入使用这段已上传并通过后端校验的音频”；Flutter 不得创建、拼接、推断或把本地路径当作 `audio_ref`。

### 业务消费接口

统一上传主干只有一条，但消费 `audio_ref` 的业务接口可以有多个。每个业务接口只能消费属于自己业务语义的音频事实：

| 业务场景 | 允许消费接口 | 业务语义 |
| --- | --- | --- |
| Training 训练回合 | `POST /training/sessions/{session_id}/turns` | 用户在训练 session 中的一次回答，可触发 ASR、发音评分、coach feedback 和训练证据候选 |
| Practice 场景练习回合 | `POST /practice/sessions/{session_id}/turns` | 用户在 Product Base practice session 中的一次对话/练习输入；provider 调用已迁移到 AI Gateway，生产音频合规仍必须满足统一可信上传主干和媒体引用校验 |
| Goal intake / checkpoint | `POST /goal-autopilot/goals`、`POST /goal-autopilot/checkpoints` | 授权的目标诊断样本和阶段检查业务入口；只能消费已经由 Media Service 上传完成并由 AI Gateway 校验的 `media://audio/...` 引用 |
| Followup-E Speaking Check diagnostic | Followup-E diagnostic-audio / diagnostic-assessment endpoint | 规划中的诊断业务入口，当前只作为规划/合同证据；若保留 diagnostic-audio upload endpoint，只能封装或委托 Media Service 统一上传主干 |
| 直接 AI runtime 调用 | `/ai/transcribe`、`/ai/pronunciation` | 仅接受可信 `media://audio/...` 或后端等价可信引用；不能接受 Flutter 本地路径 |

### 当前实现状态和 legacy/planned 说明

- Legacy local-file ASR/pronunciation paths are retired. Flutter, scene, interview, learning, demo repository, iOS native, and handwritten API wrappers must not submit `File.path`, `file://`, raw URL, realtime preview transcript, or local text-derived pronunciation scores as production audio evidence.
- Until a feature is wired to the trusted upload trunk, voice submission must fail closed or use an explicit text-only path. It must not persist or replay local WAV paths as user audio facts.
- Training turn 当前使用生产训练回合入口，并应通过 AI Gateway 消费可信 `audio_ref`。
- Practice turn 当前已迁移到 `AiGatewayService`，不再由 backend business service 直接调用 provider；生产音频合规仍必须补齐统一可信上传主干、媒体引用归属/状态校验和相关证据后才能声明。
- Goal intake diagnostic samples 和 Goal checkpoint 当前通过 `AiGatewayService.validateTrustedAudioRef` 复用 Media/AI Gateway 的 ownership、状态和引用校验；本地路径、裸 URL、跨用户 ref 或未验证 ref 必须 fail closed，且不得在 Goal facts、telemetry 或导出中泄露 raw audio ref。
- Followup-E diagnostic-audio / diagnostic-assessment 当前是规划/合同证据，不是已落地实现。diagnostic-audio upload endpoint 如保留，只能作为 Media Service 统一上传主干的业务封装或委托入口，不得独立签发 `object_ref`、`audio_ref` 或形成第二套媒体事实源。

### 禁止混用

- Training turn 不能承担 Followup-E 诊断样本事实，不能用一次普通训练回答伪装 `DiagnosticAudioSample`。
- Followup-E diagnostic endpoint 不能伪装成普通训练回合，不能写入 TrainingTurn 作为替代诊断实现。
- Practice turn、Training turn、Goal checkpoint 和 diagnostic assessment 可以共享上传主干，但不得共享或互相伪造业务事实。
- 业务接口不得接受 Flutter 本地文件路径、裸 URL、过期 ref、未完成上传 ref、跨用户 ref 或未通过后端校验的 ref 作为生产音频输入。

### 模块责任表

| 模块 | 责任 | 不允许 |
| --- | --- | --- |
| Flutter recording/upload bridge | 录音、停止、回放、重录、管理临时文件、按 `upload_url` 上传 bytes、把后端返回的 `audio_ref` 作为 opaque value 传给对应业务接口 | 生成、拼接、推断或长期持久化 `audio_ref`；把 `File.path`、`file://`、裸 URL 当成生产 `audio_ref` |
| Media Service / MediaAsset | 创建上传记录、签发上传目标、保存媒体元数据、校验用户归属、格式、大小、时长、checksum、object_ref、状态，生成或确认 `media://audio/{media_id}` | 承担 Training、Practice、Goal diagnostic、checkpoint 的业务裁决 |
| Object Storage | 存储音频 bytes，按后端签发的临时上传目标接收对象 | 成为业务事实源；向 Flutter 暴露 provider secret、永久读 URL 或可伪造对象 key |
| AI Gateway | 解析并校验可信 `audio_ref`，执行 ASR、发音评分、usage/cost/fallback/provider policy | 被业务 service 绕过；接受本地路径、裸 URL 或未验证 ref 作为成功 provider 输入 |
| Training domain | 消费可信 `audio_ref` 形成训练回合输入、反馈和训练证据候选 | 写入诊断样本事实，或把 training turn 当成 Followup-E 诊断结果 |
| Practice domain | 消费可信 `audio_ref` 形成 practice turn 和 candidate-only 学习输入 | 绕过 AI Gateway 直接调用 provider，或把 practice turn 当成诊断样本 |
| Goal Autopilot checkpoint | 消费可信 `audio_ref` 形成阶段检查证据和进度更新输入 | 伪造初始 Speaking Check 诊断样本或直接改写诊断置信度 |
| Followup-E diagnostic domain | 消费可信 `audio_ref` 形成 `DiagnosticAudioSample`、质量门禁、诊断模式和置信度事实 | 复用 TrainingTurn/PracticeTurn 代替诊断样本；让 Flutter、LLM 或 provider 直接写最终诊断事实 |

## XCB-002 详细说明：AI provider 调用与用量治理

### 统一 AI 调用主干

所有生产 ASR、TTS、发音评分、coach feedback 或 LLM candidate 都必须经过后端 AI Gateway 与用量治理主干：

```text
业务 API 或业务 service
-> AiGatewayService
-> AiProviderPolicyService 校验媒体引用、provider policy、tier/usage family
-> UsageService reserve
-> AiProviderGateway adapter 调用 deterministic 或真实 provider
-> schema / fallback / candidate guardrail
-> UsageService commit 或 release
-> 业务 domain 只消费候选信号或 deterministic 结果
```

Provider 输出是候选信号，不是最终产品事实。最终训练证据、Goal Autopilot 状态、entitlement、quota、release 或 Product Base 事实必须由对应 deterministic domain service 裁决。

### 授权调用入口

| 调用场景 | 授权入口 | 业务语义 |
| --- | --- | --- |
| ASR / 转写 | `POST /ai/transcribe` 或业务 service 内部调用 `AiGatewayService.transcribe` | 将可信 `audio_ref` 转成候选 transcript；不得把本地路径传给 provider |
| TTS | `POST /ai/tts` 或 `AiGatewayService.synthesize` | 生成或复用后端管理的 TTS media/cache；不得暴露 provider secret 或永久读 URL |
| 发音评分 | `POST /ai/pronunciation` 或 `AiGatewayService.scorePronunciation` | 生成候选 score signal；不得直接写最终 mastery 或诊断事实 |
| Coach feedback | `POST /ai/coach-turn`、`/ai/feedback` 或 `AiGatewayService.coach*` | 生成 schema-valid 或 deterministic fallback feedback；不得写 final learning fact |
| Goal Autopilot candidate | Goal Autopilot deterministic policy + AI runtime validators | AI 只能解释或补充候选文案，不能写 goal、forecast、mastery、entitlement、quota、release 或 Product Base 状态 |

### 当前实现状态和 legacy/planned 说明

- Native/provider-side oral-assessment bridges are retired from Flutter/iOS client code. ASR, pronunciation, coach, and TTS provider execution must be routed through Backend AI Gateway and usage governance.

- `AiGatewayService` 当前已经集中执行媒体引用校验、usage reserve/commit/release、provider adapter 调用和 fallback 处理。
- Training 当前通过 `AiGatewayService` 消费 ASR、评分和 coach，符合 XCB-002 目标边界。
- Practice 当前已改为通过 `AiGatewayService` 调用 ASR/coach，不再直接注入或调用 `AiProviderGateway`；后续新增 Practice AI/provider 能力仍必须走本主干。
- Goal Autopilot 当前主要走 deterministic policy、usage reservation、cost telemetry 和 AI candidate validators；任何新增真实 provider candidate 都必须接入本主干。
- Followup-E diagnostic AI runtime 仍是 planning/contract-only；不得把规划中的 prompt/schema 当作已落地 provider 执行证据。

### 禁止绕过

- 业务 service 不得直接调用 `AiProviderGateway`，除已登记 legacy exception 外必须迁移到 `AiGatewayService`。
- Flutter 或请求体不得选择商业 tier、provider model、quota bypass、usage family 或 provider secret。
- Provider 输出不得直接写入最终 learning evidence、DiagnosticAssessment、GoalProfile、ProgressForecast、mastery transition、entitlement、quota、billing、release 或 Product Base 事实。
- 失败、timeout、schema mismatch、policy rejection 和 quota block 必须返回 typed fallback/downgrade，不得伪装为成功 provider result。
- 日志、报告、导出和 telemetry 不得保存 raw provider payload、raw prompt、raw transcript、raw audio、secret 或完整 signed URL。

### 模块责任表

| 模块 | 责任 | 不允许 |
| --- | --- | --- |
| Backend business API/service | 判断业务语义，调用 `AiGatewayService` 或 deterministic policy，消费候选信号 | 直接调用 provider；把 provider 输出当最终事实；自行计费或扣额度 |
| `AiGatewayService` | 统一 provider 调用、usage reserve/commit/release、fallback、media/cost policy 协调 | 承担 Training、Practice、Goal 或 commerce 的最终业务裁决 |
| `AiProviderPolicyService` | 校验可信媒体引用、provider 可用性、模型/tier/usage family 约束 | 接收 Flutter 声明的 tier/provider 作为事实 |
| `UsageService` / `EntitlementGateService` | 维护 quota、reserve、commit、release、entitlement-derived limits 和审计 | 让 AI/provider 或 Flutter 创建 entitlement/usage 事实 |
| `AiProviderGateway` adapter | 封装 deterministic/dashscope 等 provider 协议、解析 provider 返回、上报 provider metric | 被业务 domain 直接调用；泄露 secret、raw payload 或 provider URL |
| AI runtime validators | 校验 LLM/AI candidate schema、禁止字段和 fallback 文案 | 允许 AI candidate 写持久状态或商业/release 字段 |
| Domain services | 用 deterministic rules 接受、降级或拒绝候选信号 | 省略 fallback/guardrail 后直接持久化 provider candidate |

## XCB-003 详细说明：OpenAPI 与 generated client

### 统一 API 契约主干

所有跨 Flutter / Backend 的稳定 API 变更必须经过同一条契约主干：

```text
Product Base 或已批准 increment
-> docs/architecture/api_contract.md 记录 API family 和边界
-> docs/architecture/openapi/speakeasy-api.yaml 作为机器可校验 source of truth
-> OpenAPI lint / contract check
-> 生成或校验 lib/generated/api/
-> Flutter wrapper / service 消费 generated boundary
-> CI drift gate 阻断未同步变更
```

`api_contract.md` 是人读总览，OpenAPI YAML 是机器可校验 source of truth。`lib/generated/api/` 是生成物，不是手写语义源。

### 授权契约入口

| 契约对象 | 授权入口 | 业务语义 |
| --- | --- | --- |
| API family 总览 | `docs/architecture/api_contract.md` | 说明 API family、状态、deferred boundary、兼容性和 source-of-truth 关系 |
| 机器可校验 schema | `docs/architecture/openapi/speakeasy-api.yaml` | 定义路径、request/response、错误、示例和 tags |
| Generated Dart client | `lib/generated/api/` + `.openapi-sha256` | Flutter 可消费的 generated boundary；不得手写修改语义 |
| Drift manifest | `docs/architecture/openapi/dart-client-drift-manifest.json` | 记录 OpenAPI hash、generated target 和允许的 handwritten client exceptions |
| 检查脚本 | `npm run check:api-contract`、`npm run check:dart-client-drift`、`scripts/check_cross_cutting_boundaries.py` | 阻断 OpenAPI、generated Dart、handwritten client 和 CI 之间的漂移 |

### 当前实现状态和 legacy/planned 说明

- 当前 OpenAPI source、generated Dart client 和 drift manifest 已存在，`package.json` 已提供 `check:api-contract` 和 `check:dart-client-drift`。
- `lib/generated/api/` 已作为 generated boundary 提交；新增或修改 generated client 必须与 OpenAPI source 同步。
- `lib/services/api_client.dart` 仍存在 documented handwritten client exceptions；这些只能作为显式例外或迁移 wrapper，不能重新定义 OpenAPI DTO 语义。
- Followup-E diagnostic-audio / diagnostic-assessment 当前是 markdown planning/contract evidence only；进入实现前必须先落入 OpenAPI 和 generated Dart drift gate。
- 当前 cross-cutting boundary check 已覆盖“generated client 改动未配 OpenAPI source”的明显违规，但不能替代完整 API contract lint 和 generated drift check。

### 禁止绕过

- 不得手改 `lib/generated/api/` 的业务语义，或只改 generated client 不改 OpenAPI source。
- 不得新增 backend controller path 而不更新 OpenAPI 和契约检查。
- 不得让 Flutter handwritten wrapper 自行发明 request/response 字段含义、错误语义或 idempotency 行为。
- 不得把 future/planned endpoint 放进实现级 OpenAPI，除非 Product Manager 已批准 owning increment 且契约链路齐全。
- 不得把 `api_contract.md` 的 planning 段落当作 generated client 已可用证据。

### 模块责任表

| 模块 | 责任 | 不允许 |
| --- | --- | --- |
| Product / increment artifacts | 提供已批准 scope、FR/AC/TC 和实现状态 | 用 API schema 反向发明产品范围或优先级 |
| `api_contract.md` | 记录 API family、边界、兼容性、deferred/planned 状态和验证门禁 | 复制完整 OpenAPI schema；声明未实现 endpoint 已可用 |
| OpenAPI YAML | 作为路径、schema、错误和示例的机器 source of truth | 承载 roadmap priority、未批准 future path 或 release claim |
| Generated Dart client | 从 OpenAPI 同步 Flutter 可消费边界和 hash | 手写业务语义、静默跳过 hash/drift |
| Backend controllers/DTO | 实现 OpenAPI 中的稳定 contract，并保持 schema_version/error/idempotency 一致 | 产生 OpenAPI 外的稳定跨层接口 |
| Flutter service/wrapper | 包装 generated boundary、注入认证/idempotency、处理 typed errors | 用 handwritten DTO 覆盖 generated DTO 语义 |
| CI / drift scripts | 运行 lint、contract、generated drift 和 cross-boundary check | 用单一脚本替代完整契约链路 |

## XCB-004 详细说明：会员权益、额度和商业事实

### 统一商业事实主干

会员、订阅、权益、用量和发布状态必须由后端商业事实主干产生：

```text
Store/provider purchase or webhook / backend commercial API
-> PaymentProviderService / CommercialFoundationService
-> Subscription / Purchase / EntitlementSnapshot
-> EntitlementGateService
-> UsageService reserve / commit / release
-> Flutter 只读取 entitlement / usage / release health projection
```

Flutter 可以展示后端返回的权益和额度状态，但不能本地判定最终权益、退款、订阅状态、用量扣减或商业发布状态。

### 授权商业入口

| 商业场景 | 授权入口 | 业务语义 |
| --- | --- | --- |
| 订阅计划展示 | `GET /subscription/plans` | 展示可售计划；不授予 entitlement |
| Entitlement 读取/刷新 | `GET /entitlements`、`POST /entitlements/refresh` | 返回后端生成的 `EntitlementSnapshot` |
| 用量控制 | `GET /usage/summary`、`POST /usage/reserve`、`POST /usage/commit`、`POST /usage/release` | 后端拥有 quota、reserve、commit、release 生命周期 |
| Apple / Google 校验 | `/subscriptions/apple/verify`、`/subscriptions/google/verify`、`/subscriptions/restore`、webhook paths | 后端接收 provider token/event 后生成 subscription 和 entitlement facts |
| Release health | `GET /admin/release-health`、release checklist / runbook scripts | 只记录本地/外部 gate 状态；不等于商业发布批准 |
| MVP membership boundary | `/membership/boundary` | 兼容性入口，只能表达 MVP 边界状态，不得当成生产 payment/entitlement source |

### 当前实现状态和 legacy/planned 说明

- Backend 已有 `CommercialFoundationController`、`PaymentProviderService`、`EntitlementGateService`、`UsageService` 和相关本地测试。
- P0 commercial 和 paid AI voice 仍有外部/native/store/release evidence blockers；本地实现或脚本通过不等于商业 release ready。
- P0.2 Followup-D 已本地关闭 entitlement depth、usage/quota、cost telemetry、release drift/final review 等门禁，但明确不是 Product Base merge 或 commercial release approval。
- `/membership/boundary` 是 MVP 兼容边界，不能替代生产 subscription/entitlement API family。
- AI/provider candidate 不能创建 entitlement、quota、billing、refund、release 或 Product Base 事实。

### 禁止绕过

- Flutter 不得本地创建或修改最终 plan、entitlement、quota、billing、refund、restore、subscription 或 release-ready 状态。
- Store receipt、purchase token 或 webhook 事件不得在客户端直接转成付费权益。
- Provider/LLM 不得创建商业权益、用量、成本、退款、release approval 或 Product Base merge 事实。
- 本地测试通过、issue close、PR merge、release health message 或 checklist 局部通过不得替代 strict external evidence。
- 用量失败或 entitlement blocked 必须返回 typed downgrade/block reason，不得静默放行高成本路径。

### 模块责任表

| 模块 | 责任 | 不允许 |
| --- | --- | --- |
| Flutter commercial UI | 读取后端 plans、entitlement、usage、downgrade reason，渲染购买/恢复状态 | 本地判定最终权益、额度、退款、release-ready 或 paid-AI availability |
| `CommercialFoundationController` | 暴露 subscription、entitlement、usage、release-health API family | 让 unauthenticated endpoint 泄露用户权益或写商业事实 |
| `PaymentProviderService` | 校验 provider token/event，写 subscription、purchase、entitlement 和 audit | 信任客户端 receipt 结论；跳过 webhook signature/idempotency/audit |
| `EntitlementGateService` | 将后端 entitlement 转成 feature/tier/limit 决策 | 接受 Flutter 或 AI 声明的 tier/limit |
| `UsageService` | 管理 usage ledger、reservation、commit、release、quota audit | 让业务 service 或 provider 直接扣减/补额度 |
| Release scripts/checklists | 汇总 strict external evidence、native/store/provider/release blockers | 把本地 deterministic pass 写成商业发布批准 |
| Product / PM governance | 决定商业上线、Product Base merge 和优先级 | 让 issue、PR、report 或 AI 输出替代商业决策 |

## XCB-005 详细说明：Goal Autopilot 目标、诊断、预测和 checkpoint 事实

### 统一 Goal Autopilot 事实主干

Goal Autopilot 的目标、诊断、计划、forecast、checkpoint、control、reminder、memory 和 mastery facts 必须由后端 domain 主干产生：

```text
Flutter 提交目标或业务动作
-> Goal Autopilot API family
-> GoalAutopilotService / deterministic policy
-> GoalProfile / DiagnosticAssessment / Backplan / DailyPlan / ProgressForecast / OutcomeCheckpoint / Control / Replay facts
-> safe projection 或 summary 返回 Flutter
```

Flutter 可以展示后端 projection，也可以提交用户意图和样本引用；最终 goal 状态、ETA、claim guard、diagnostic mode、confidence band、plan update 和 mastery transition 必须由后端裁决。

### 授权业务入口

| 业务场景 | 授权入口 | 业务语义 |
| --- | --- | --- |
| Goal intake / revision | `POST /goal-autopilot/goals` | 创建或修订 active `GoalProfile`，生成受支持状态和诊断摘要 |
| Summary / projection | `GET /goal-autopilot/summary`、`GET /goal-autopilot/progress-projection` | 返回后端 source-of-truth snapshot 和安全 surface projection |
| Backplan / daily plan / action | `POST /goal-autopilot/plans/generate`、`GET /goal-autopilot/daily-plan`、`GET /goal-autopilot/actions/next`、`POST /goal-autopilot/actions/{plan_item_id}/complete` | 生成、读取和推进 no-choice daily execution |
| Control / reminder / recovery | `/goal-autopilot/control*`、`/goal-autopilot/reminders/outbox`、`/goal-autopilot/recovery/replan` | 后端拥有 pause/resume、reminder lifecycle、missed-day recovery |
| Forecast / checkpoint | `GET /goal-autopilot/forecast`、`GET /goal-autopilot/checkpoints/task`、`POST /goal-autopilot/checkpoints` | 后端拥有 ETA/风险/置信度/周期复测和 checkpoint-to-plan 信号 |
| Memory / mastery / replay | `/goal-autopilot/item-policy/decisions`、`/goal-autopilot/mastery-transitions`、`/goal-autopilot/replay-audits` | 后端拥有 memory item policy、L0-L5 transition、deterministic replay |
| Followup-E diagnostic | planned diagnostic-audio / diagnostic-assessment family | 规划中的音频诊断入口，未实现前不得伪装成普通 goal intake 或 checkpoint |

### 当前实现状态和 legacy/planned 说明

- Followup-A/B/C/D 的 Goal Autopilot 本地 deterministic slices 已有多轮本地证据，但 Followup-C/D 仍不是 release-ready，Product Base merge 未批准。
- Goal Autopilot 中与 quota、entitlement、cost、data governance、telemetry 和 release drift 相关的本地门禁已记录，但不得替代 P0 商业发布或 paid AI external evidence。
- Goal intake 与 checkpoint 当前可以接收 `audio_ref` 字段，但必须只接受通过 XCB-001/XCB-002 主干校验的可信 `media://audio/...`。`POST /goal-autopilot/goals` 必须使用 `Idempotency-Key`，由后端 goal intake replay 表和用户级锁保护 single active goal revision chain；Flutter 不得用重试或本地草稿创建重复目标事实。
- Followup-E Speaking Check 仍是 planning/contract evidence only；不得用现有 `diagnosticSamples` 输入或 checkpoint 音频字段声明 production diagnostic audio 已完成。
- AI/LLM candidate 只能解释或补充，Forecast/Mastery validators 必须拒绝官方分数、goal completion、entitlement、quota、release 等 forbidden persistent fields。

### 禁止绕过

- Flutter 不得本地计算最终 goal progress、ETA、completion、claim guard、diagnostic mode、confidence band、checkpoint status 或 mastery level。
- Training turn、Practice turn、checkpoint 或 Followup-E diagnostic 不得互相伪造业务事实。
- LLM/provider 不得直接写 `GoalProfile`、`DiagnosticAssessment`、`ProgressForecast`、`OutcomeCheckpoint`、`MasteryTransition`、entitlement、quota 或 release facts。
- Unsupported、partial、low-confidence、stale、paused、control-blocked、deleted、quota exhausted 或 entitlement blocked 状态不得被 UI fallback 静默升级。
- 本地 P0.2 slice pass 不得被写成 Product Base merge approved、official score equivalence、guaranteed outcome 或 commercial release ready。

### 模块责任表

| 模块 | 责任 | 不允许 |
| --- | --- | --- |
| Flutter Goal Autopilot surfaces | 读取 summary/projection，提交用户意图、操作和 opaque sample refs，渲染 backend reason codes | 本地推断最终 goal/ETA/checkpoint/claim guard/quota/release 状态 |
| `GoalAutopilotController` | 暴露 goal-autopilot API family、认证、DTO、idempotency/path boundary | 接收未授权 endpoint 或把 planned Followup-E path 当已实现 |
| `GoalAutopilotService` | 维护 GoalProfile、diagnostic、plan、checkpoint、forecast、control、replay、export facts | 绕过 policy、usage、data governance 或让 AI/provider 写最终事实 |
| Deterministic policies | 执行 support matrix、forecast、checkpoint cadence、memory、mastery、recovery、notification decisions | 从 Flutter cache、LLM 输出或最近 UI intent 派生最终状态 |
| AI candidate validators | 校验候选解释和 forbidden fields，生成 fallback | 放行 official score、goal completion、entitlement、quota、release 或 Product Base 字段 |
| Entitlement / usage / runtime gates | 阻断或降级 full-depth、高成本、paused、kill-switch、quota exhausted 路径 | 让 Goal Autopilot 自行创建商业权益或绕过 quota |
| Data governance / telemetry | 导出红线、删除覆盖、redacted metric、audit proof | 暴露 raw transcript、audio ref、provider payload、notification payload 或 idempotency key |

## XCB-006 详细说明：数据保留、导出、删除和审计

### 统一数据治理主干

任何新表、新媒体事实、新 provider payload 或新 telemetry 都必须接入同一条数据治理主干：

```text
业务数据或媒体事实产生
-> 定义 data family、owner、retention rule、export behavior、deletion behavior
-> 用户删除或 admin retention job 触发
-> AccountDeletionService / AiRetentionService / domain export helpers
-> redacted audit proof
-> reports 和 release gates 只记录脱敏证据
```

数据治理默认最小化：用户导出只暴露安全字段和脱敏引用；账号删除必须清理用户自有数据、AI media/cache/metrics 和相关业务表；审计只保留最小脱敏证明。

### 授权治理入口

| 治理场景 | 授权入口 | 业务语义 |
| --- | --- | --- |
| Account deletion | `DELETE /user/me`、`GET /user/deletion-status`、`AccountDeletionService` | 创建幂等删除 job、撤销会话、清理用户自有业务数据并写 redacted audit |
| AI retention | `POST /admin/ai/retention-jobs`、`GET /admin/ai/retention-jobs/{job_id}`、`AiRetentionService` | 删除/匿名化 expired media、account-deletion media/cache/metrics，并返回 aggregate counts |
| Goal Autopilot export/retention | `GoalAutopilotService.export*DataGovernance` | 返回 P0.2 data family、omitted fields、retention rules、deletion tables 和 redacted export only 状态 |
| Audit | `AuditLog` / redacted_details | 记录最小必要事件证明，不保存 raw payload |
| Release / reports | test/quality/implementation report + release checklist | 记录测试和审查证据；不得包含 raw audio、transcript、secret 或 full signed URL |

### 当前实现状态和 legacy/planned 说明

- 当前已有 `AccountDeletionService`、`AiRetentionService`、`AuditLog`、Goal Autopilot redacted export helpers 和相关本地测试。
- Account deletion 已覆盖多类 Product Base、Training、Goal Autopilot、commercial、usage 和 AI retention 清理，但任何新增表或新媒体事实仍必须显式加入删除/导出/retention 覆盖。
- Goal Autopilot S007/S009 已有本地 data governance 和 telemetry redaction 证据；这不等于完整商业 release 或 paid AI external evidence。
- Followup-E 诊断音频的数据治理仍是 planning/contract-only；生产实现前必须补齐 raw audio、transcript、provider payload、delete/export/minimization 证据。
- 如果 provider payload 或 raw transcript 为调试短期保留，必须有受控 retention policy，不得成为长期学习事实或默认导出内容。

### 禁止绕过

- 新表、新媒体事实、新 telemetry 或新 provider payload 不得缺少 deletion/export/retention/audit 设计。
- 日志、报告、export、issue、PR 或 telemetry 不得暴露 raw audio、raw transcript、provider payload、secret、receipt/token、full signed URL、idempotency key 或 notification payload。
- Account deletion 不得只删 UI/profile 而遗漏 media/cache/metrics/business facts。
- Retention job 不得返回 raw evidence；只能返回 aggregate counts、状态和 redacted evidence ref。
- AI/provider、Flutter 或 object storage 不得成为数据保留/删除裁决者。

### 模块责任表

| 模块 | 责任 | 不允许 |
| --- | --- | --- |
| Domain owner | 为新增数据定义 data family、safe fields、omitted fields、retention trigger 和 deletion table | 新增持久事实但不接入 XCB-006 |
| `AccountDeletionService` | 幂等删除用户自有数据、撤销会话、联动 AI retention、写 redacted audit | 只删除部分表或暴露删除过程中的敏感 payload |
| `AiRetentionService` | 清理 AI media、TTS cache owner、provider metrics、transcript refs，返回 aggregate counts | 返回 raw media/provider evidence 或跳过 idempotency |
| Export helpers | 生成 redacted/minimized export projection、retention rules 和 omitted field 列表 | 导出 raw transcript、audio ref、provider payload、full signed URL 或 idempotency key |
| `AuditLog` / telemetry | 记录 redacted proof、blocked reason、fallback audit 和 rollout health | 写入 raw user UUID 之外的敏感 payload、prompt、secret 或完整请求体 |
| QA / Evidence Reviewer | 验证删除、导出、retention、redaction 和 release blocker | 用 report 文字替代实际 deletion/export/retention evidence |
| Flutter | 展示删除/导出/隐私状态和后端返回的安全 projection | 本地判定删除完成或缓存敏感原始 payload |

### 可执行门禁与追溯规则

XCB-006 的完成证据必须能从需求/架构追溯到代码和测试，不能只写在报告里：

| 层级 | 必须证明 | 授权位置 |
| --- | --- | --- |
| 需求/验收 | 新数据族是否涉及用户数据、media/cache、transcript、provider payload、telemetry、idempotency 或 audit | owning increment 的 requirements、acceptance、test_cases、traceability；本注册表 XCB-006 |
| 架构/领域 | data family、safe fields、redacted fields、omitted fields、retention trigger、deletion behavior 和 retained-redacted 例外 | `docs/domain/domain_schema.md`、`docs/domain/entity_relationship.md`、`docs/architecture/backend_db_foundation_contract.md` |
| 代码 | 用户自有业务表接入 `AccountDeletionService` 或被它编排的 domain deletion helper；AI media/cache/metrics 接入 `AiRetentionService`；导出接入 domain export helper；audit 只写 `redacted_details` | `AccountDeletionService`、`AiRetentionService`、domain service export helpers、`AuditLog` / `AuditLogService` |
| 测试 | account deletion、export redaction、retention job、audit write/read redaction、static boundary check 均有自动化证据或明确不适用 | backend integration tests、`test/scripts/test_cross_cutting_boundaries.py`、`docs/reports/test_report.md`、`docs/reports/quality_report.md`、`docs/reports/implementation_report.md` |

新增 migration 创建敏感表时，changed-scope cross-cutting boundary check 必须能在授权位置找到该表的数据治理覆盖。敏感表包括含 `user_id`、`owner_hash`、`audio_ref`、transcript、provider payload、cache/media metric、idempotency key、notification payload 或 signed URL 等字段/语义的表。若表是纯内容、配置、公开 reference data 或只保留最小脱敏审计证明，必须接入 owning domain contract，或使用严格的 XCB-006 retained-redacted / legacy / not-applicable exception；不得把 `planned exception` 或“暂时用不到删除”当作放行证据。

XCB-006 例外必须是同一逻辑行的结构化声明，供 changed-scope checker 读取；例外类型必须来自声明头 `XCB-006 <type> exception:`，不得从 rationale 或其它字段值推断；类型名称只允许精确小写的 `retained-redacted`、`legacy`、`not-applicable`，不得使用 `retained redacted`、`not applicable`、`Retained-Redacted`、`LEGACY`、`NOT-APPLICABLE` 等别名。普通 `planned exception` 只能作为计划说明，即使同一行包含 `retained-redacted` 等字样，也不能放行新增敏感生产表。允许的例外类型和必填字段如下：

```text
XCB-006 retained-redacted exception: table=<table>; owner=<owner>; safe_fields=<safe fields>; redacted_fields=<redacted fields>; omitted_fields=<omitted fields>; retention_trigger=<trigger>; deletion_behavior=<behavior>; export_behavior=<behavior>; rationale=<why retained redacted evidence is required>;
XCB-006 legacy exception: table=<table>; owner=<owner>; safe_fields=<safe fields>; redacted_fields=<redacted fields>; omitted_fields=<omitted fields>; retention_trigger=<trigger>; deletion_behavior=<behavior>; export_behavior=<behavior>; rationale=<pre_existing or migration_compatibility reason>;
XCB-006 not-applicable exception: table=<table>; owner=<owner>; safe_fields=<safe fields>; redacted_fields=none; omitted_fields=none; retention_trigger=<non-user-data lifecycle>; deletion_behavior=not_user_owned; export_behavior=not_in_user_export; rationale=<public_reference/no_user_data/reference_data reason>;
```

`safe_fields` 不得包含 raw audio、raw transcript、provider payload、signed URL、secret、token、idempotency key、user identifier、`target_ref` 或 `redacted_details` 等敏感字段，也不得通过 `raw_audio`、`rawAudio`、`refresh_token_hash`、`refreshTokenHash`、`upload_signed_url`、`uploadSignedUrl`、`user_email`、`userEmail`、`actor`、`account`、`member`、`customer`、`learner`、`profile`、`actor_id`、`actorId`、`account_id`、`accountId`、`account_identifier`、`actorIdentifier`、`member-key`、`customerRef`、`learnerUuid`、`profile_hash`、`profile-name`、`targetRef`、`target-ref`、`redactedDetails`、`redacted-details` 等主体或组合字段名绕过；`audit_log_id`、`event_id` 等非用户主体行 ID 可以作为 safe field。`legacy exception` 的 `rationale` 必须以独立短语说明 `pre_existing` 或 `migration_compatibility`，`not_pre_existing`、`not migration_compatibility`、`pre_existing=false`、`migration_compatibility=false` 等否定或赋值否认语义不得通过；`not-applicable exception` 的 `rationale` 必须以独立短语说明 `not_user_owned`、`public_reference`、`reference_data`、`configuration` 或 `no_user_data`，`not_user_owned=false`、`public_reference=false`、`reference_data=false`、`configuration=false`、`no_user_data=false` 等赋值否认语义不得通过，且必须精确使用裸值 `redacted_fields=none`、`omitted_fields=none`、`deletion_behavior=not_user_owned`、`export_behavior=not_in_user_export`，不得使用 `NONE`、`` `none` ``、`"none"`、`NOT_USER_OWNED`、`'not_in_user_export'`、`not user owned`、`not-in-user-export` 等大小写、引号或分隔符别名。缺少 owner、safe/redacted/omitted fields、retention trigger、deletion behavior、export behavior 或 rationale、任一必填字段使用 `todo`、`tbd`、`later`、`review_later`、`plannedReview`、`pendingReview`、`temporary-export`、`planned`、`pending`、`unknown`、`temporary` 等占位治理说明，或同一声明重复字段名时，包括 `table=; table=...`、`safe_fields=; safe_fields=...` 这类空值重复，一律不得通过 XCB-006。

## XCB-007 详细说明：Product source of truth 与 issue tracking

### 统一产品对象治理主干

产品范围、优先级、需求、验收、测试、实现证据、发布证据和 issue tracking 必须按产品对象治理主干分层：

```text
用户想法或问题
-> Product Manager 分类 V2 Capability/stage/increment/change request
-> Product Base 或 owning increment artifacts
-> requirements / spec / acceptance / test_cases / traceability
-> Codex Root 路由实现或审核
-> reports / quality / release evidence
-> issue 只作为 tracking container 链接上述 source of truth
```

Issue、PR、代码、报告和 agent 输出都不能替代 Product Manager 分类、Product Base、increment artifacts、AC/TC/traceability、release evidence 或 Product Base merge decision。

### 授权治理入口

| 治理场景 | 授权入口 | 业务语义 |
| --- | --- | --- |
| 产品范围与优先级 | Product Manager agent、`docs/product/development_status.md`、V2 Capability registry、stage docs | 决定当前做什么、延期什么、属于哪个 Capability/stage/increment |
| 稳定产品事实 | `docs/product/base/` | 已接受稳定行为的 living source of truth |
| 增量事实 | `docs/product/increments/<increment-id>/` | 当前或历史 increment 的 definition、requirements、spec、acceptance、test_cases、traceability |
| 工作流治理 | `docs/process/workflow.md`、`skill_quality_standard.md`、本注册表 | 规定路由、边界、source-of-truth 和检查流程 |
| Issue tracking | `.agents/skills/issue-management/`、GitHub issues | 跟踪协调、链接源头和证据，不拥有产品事实 |
| 独立审核 | Product Object Governance Check、Documentation Governance、Evidence Reviewer、QA | 审查范围、链路、证据和 release/Product Base 状态 |

### 当前实现状态和 legacy/planned 说明

- 当前 workflow 已明确 Product Manager 是用户入口和产品对象 owner，Codex Root 负责路由，issue-management 只做 tracking。
- `.agents/skills/issue-management/` 已存在并要求 issue 不得替代 PM 分类、需求、验收、测试、traceability 或 release evidence。
- XCB-001..XCB-006 的治理表只能作为 implementation plan 和 review 的边界约束，不能直接声明需求完成、release ready 或 Product Base merge。
- 当前工作树存在非本步骤的治理/脚本改动时，审核必须区分当前步骤范围和既有 residual risk。
- Followup-E 当前仍是 planning/contract evidence only；任何 issue 或跟踪项都不得把它标成 implemented、tested 或 release-approved。

### 禁止绕过

- 不得用 issue、PR、实现代码、测试通过、报告摘要或 agent 口头结论替代 Product Manager 的 scope/priority/stage/increment 决策。
- 不得把 baseline、Capability、stage、increment、change request 和 Product Base 混成同一个 source of truth。
- 不得用本注册表补写需求、验收、测试用例、实现报告、质量报告或发布证据。
- 不得在缺少 owning increment、AC-to-TC mapping、traceability 和 evidence 的情况下声明 done。
- 不得把 local deterministic pass 写成 commercial release approval、paid AI external evidence pass 或 Product Base merge approval。

### 模块责任表

| 模块 | 责任 | 不允许 |
| --- | --- | --- |
| Product Manager | 分类请求、维护 roadmap/development status、V2 Capability registry、stage scope、increment definition 和优先级 | 写详细实现、测试、API schema 或被 issue/PR 替代 |
| Product Base | 承载已接受稳定需求、spec、acceptance、traceability | 接收未完成或未批准的 planned increment scope |
| Increment artifacts | 承载当前增量 definition、requirements、spec、AC、TC、traceability 和 evidence 状态 | 冒充 Product Base 或跨增量混用 scope |
| Codex Root | 检查产品对象门禁并路由 specialist agents | 决定产品优先级或绕过 missing increment/AC/TC gate |
| Issue Management | 创建/更新 tracking issue、链接 source-of-truth、建议 label/status | 决定产品范围、优先级、完成状态或 release readiness |
| Reports / Release evidence | 记录已执行范围、测试、质量、风险、external blockers | 新增需求或把本地 pass 写成发布批准 |
| Product Object Governance Check | 独立检查范围、路径、source-of-truth 和边界一致性 | 自己生成缺失需求或批准自己的变更 |

## 实现计划引用模板

```text
Cross-cutting boundaries:
- Boundary ID:
- Existing authorized entry:
- Reused module/API/service:
- Forbidden bypasses checked:
- Legacy exceptions or migration needed:
- Evidence gate:
```

## 维护规则

本注册表由 Product Object Governance Change Agent 维护，Product Object Governance Check Agent 独立审核。新增或修改边界时，必须确认没有改变产品范围、路线图优先级、已接受需求或 release 状态。
