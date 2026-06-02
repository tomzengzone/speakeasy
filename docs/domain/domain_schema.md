# Domain Schema

## 状态

Proposed - Domain Schema Baseline + P0/P0.1 Extension。

本文补齐 Product Base accepted domain baseline，并在同一领域模型中挂接 P0 商业化订阅上线准备和 P0.1 表达自动化训练扩展。本文不是 API Contract，不定义 request/response shape；不是数据库 migration，不写 SQL；不是 Flutter 或 backend 实现计划。

本文写入并通过 `document-traceability-check` 与 Product Object Governance Check Agent 前，不得作为实现开工依据。

## Scope Classification

| 分类 | 范围 | 状态 |
| --- | --- | --- |
| Product Base accepted domain | access-onboarding、official-scenario-library、listening-shadowing、expression-practice-queue、voice-scenario-practice、learning-memory-review、profile-membership 的当前稳定能力 | In scope |
| P0 extension | subscription、purchase、entitlement、usage、account deletion、commercial audit、production identity hardening、AI provider operations | In scope |
| P0.1 extension | training session、training turn、planner decision、action chain step、micro-action、hint state、pressure check、learning evidence hardening | In scope |
| Explicit deferred | P0.2 跨 session/跨天训练编排、完整 L0-L5、P1 notebook/评分产品化、P2 A1-C2/CMS、任意场景生成 | Out of scope |

## Source Inventory

| 来源 | 路径 | 用途 |
| --- | --- | --- |
| Product Base requirements | `docs/product/base/requirements.md` | 稳定 FR 和非目标 |
| Product Base spec | `docs/product/base/spec.md` | 稳定 flow、状态和模块影响 |
| Product Base acceptance | `docs/product/base/acceptance.md` | 可观察验收边界 |
| Product Base traceability | `docs/product/base/traceability.md` | Product Base 到代码/测试证据链路 |
| Product Base implementation evidence | `docs/product/base/traceability.md` | 当前 Flutter APP 能力事实、代码证据和测试证据 |
| Feature registry | `docs/product/feature_registry.md` | 长期 feature 边界 |
| P0 increment | `docs/product/increments/commercial-subscription-readiness/` | 商业化领域扩展来源 |
| P0.1 increment | `docs/product/increments/p0-1-expression-automation-training/` | 训练编排领域扩展来源 |
| P0.1 专项训练模型 | `docs/domain/training_model.md` | P0.1 TrainingSession、ActionChainStep、MicroAction、HintState、PlannerDecision、PressureCheck、TrainingRecap 详细领域契约 |
| Foundation contract | `docs/architecture/backend_db_foundation_contract.md` | backend/DB/OpenAPI/fact-source 基础边界 |
| Architecture docs | `docs/architecture/system_overview.md`, `docs/architecture/module_boundary.md`, `docs/architecture/data_flow.md`, `docs/architecture/security_design.md` | 服务端事实源、AI、用量、删除和安全边界 |
| Existing domain drafts | `docs/domain/*.md` | 当前早期领域草案和命名来源 |

旧 `E:/ZhenChe/APP/speakeasy_backend` 不作为当前目标架构依据。

## Domain Modeling Rules

- Product Base accepted domain 只描述当前已接受稳定能力，不混入 P0/P0.1 planned 行为。
- P0/P0.1 extension 只定义领域语义、生命周期、不变量、持久化影响和后续契约输入。
- 服务端是用户、权益、用量、训练 session、学习证据、账号删除和审计的最终事实源；Flutter 本地状态只能作为展示缓存、离线兜底或会话草稿。
- LLM、ASR、TTS、评分 provider 只产生候选反馈或信号；最终训练推进、权益判断、用量扣减、学习证据写入和掌握更新必须由 deterministic domain rules 裁决。
- JSONB 只能作为 provider raw payload 摘要、audit details、低频扩展字段或第三方事件原文索引，不得替代核心领域对象。
- 每个持久化事实必须能追溯到 Product Base 或 P0/P0.1 increment。
- API boundary recommendation 只说明后续 API family 和契约关注点，不定义 request/response shape。

## Product Base Accepted Domain

### Access / Onboarding

| Entity | Owner | 关键字段 | 生命周期 / 不变量 | Persistence / migration implication | API boundary recommendation | Test impact | Traceability note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| User | Identity domain | user_id, display_name, avatar_ref, locale, level, account_status, created_at | 用户是所有学习、订阅、用量和删除任务的根；账号删除后不得继续产生新学习事实 | 需要 `identity_*` 组表；删除需支持 hard delete/anonymize/retain-for-audit | 后续由 Auth/User API 暴露当前用户和资料更新，不在本文定义 shape | 登录门禁、退出、注销、本地清理、账号状态测试 | Product Base FR-001, FR-010；P0 FR-COM-004, FR-COM-008 |
| AuthIdentity | Identity domain | auth_identity_id, user_id, provider, provider_subject, linked_at, status | 一个 User 可绑定多个登录身份；生产登录不得依赖 demo flow | 需要唯一约束 provider + provider_subject；测试登录需 release gate 可识别 | Auth API 负责登录、refresh、logout、社交登录绑定 | 微信/Apple/手机号/邮箱登录失败和生产配置门禁测试 | Product Base FR-001；P0 FR-COM-004, FR-COM-005 |
| UserProfile | Identity domain | user_id, nickname, target_level, daily_minutes, reminder_enabled, reminder_time, theme | 个人资料和偏好不直接决定权益；每日分钟数只作为偏好 | 可与 User 分表或 profile 表；本地缓存上线后需同步策略 | User/Profile API 后续细化，Flutter 可缓存展示 | 编辑资料、提醒、主题、个人中心展示测试 | Product Base FR-002, FR-010 |
| OnboardingAssessment | Onboarding domain | assessment_id, user_id, goal_direction, pain_points, output_level, daily_minutes, completed_at | 缺少目标方向、表达卡点或输出水平时不得完成 | 需要记录首评结果与完成时间；可支持后续重评版本 | User/Onboarding API 后续细化 | 首评阻止逻辑、场景映射、日常服务非真实场景测试 | Product Base FR-002 |
| LearningRoute | Onboarding + Content domain | route_id, user_id, scenario_ids, current_scenario_id, target_level, source_assessment_id | 只允许写入当前真实官方场景；工作沟通映射到 `onboarding_introduction`；日常服务只能形成空路线或无可练场景状态 | 需要用户到场景/等级的当前关系；避免把文案方向写成场景资产 | Scenario/User route API 后续细化 | 英语面试、入职介绍、工作沟通映射和日常服务排除测试 | Product Base FR-002, FR-003 |
| UserScenarioState | Onboarding + Content domain | user_scenario_state_id, user_id, scenario_id, state, current_flag, target_level, joined_at, updated_at | 用户加入、移除、设为当前和切换等级的服务端事实；移除场景不得继续作为 current scene | 需要 user + scenario 唯一约束；home summary 和练习入口只能读取 active/joined 状态 | User scenario state 与 home summary API 后续细化 | 加入/移除/current/level 切换、首页空状态和下一步建议测试 | Product Base FR-002, FR-003, FR-005 |

### Official Scenario Library

| Entity | Owner | 关键字段 | 生命周期 / 不变量 | Persistence / migration implication | API boundary recommendation | Test impact | Traceability note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Scenario | Content / Scenario domain | scenario_id, slug, title, summary, category, status | 当前真实官方场景只承认 `job_interview` 和 `onboarding_introduction`；不得隐式创建第三场景 | 需要 `content_*` 组表或受审核 bundled asset 迁移路径 | Scenario API 后续提供列表和详情；本文不定义 response | 场景目录、搜索、筛选、真实场景边界测试 | Product Base FR-003；P0.1 P01-FR-001 |
| ScenarioVersion | Content / Scenario domain | scenario_version_id, scenario_id, version, content_status, published_at | 练习、训练和证据必须引用可追踪内容版本 | 需要内容版本表；支持后续内容变更和回归 | Scenario content API 后续暴露版本标识 | 内容版本变化不破坏会话恢复测试 | Product Base FR-003；Architecture content boundary |
| ScenarioLevel | Content / Scenario domain | scenario_level_id, scenario_id, level_code, target_level, expression_count | 当前 L1/L2/L3 是资产等级，不等同完整 A1-C2 | 需要场景等级关系和唯一约束 scenario + level | Scenario API 后续按场景/等级取内容 | 等级切换影响热身、推荐表达、场景模拟测试 | Product Base FR-003 |
| TargetExpression | Content / Learning domain | target_expression_id, scenario_version_id, level_code, text, meaning_cn, tags, usage_note | 表达是练习、收藏、复习、掌握和训练目标的稳定引用 | 需要稳定 ID 和 normalized_text；不得只靠文本匹配 | Scenario/Training/Learning API 后续引用表达 ID | 表达队列、收藏去重、命中目标表达测试 | Product Base FR-005, FR-006, FR-008；P0.1 P01-FR-003 |
| DialogueAsset | Content / Scenario domain | dialogue_asset_id, scenario_version_id, level_code, role, text, audio_ref, order_index | 听力热身和示范输入只引用审核内容；音频缺失需可恢复 | 可作为内容表或 asset manifest；音频引用不得保存 provider secret | Scenario content API 后续提供可播放引用 | 播放、切句、循环、音频失败降级测试 | Product Base FR-004 |

### Listening / Shadowing / Scoring

| Entity | Owner | 关键字段 | 生命周期 / 不变量 | Persistence / migration implication | API boundary recommendation | Test impact | Traceability note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ListeningWarmup | Training domain | warmup_id, user_id, scenario_id, level_code, current_dialogue_id, mode, status | 只围绕当前场景和等级；状态可恢复 | 可本地缓存，服务端上线后可作为 training activity | Training/Scenario API 可后续承接，不在本文定义 shape | 播放、暂停、上一句、下一句、循环、模式切换测试 | Product Base FR-004 |
| ShadowingAttempt | Training + AI Gateway domain | attempt_id, user_id, target_dialogue_id, audio_ref, transcript_ref, completeness_score, score_signal_id, status | ASR/评分失败不得阻断完整度反馈；发音评分不可用时可降级 | 需要音频/转写引用和短期 retention；score signal 独立建模 | AI Gateway/Training API 后续处理 ASR/评分边界 | 跟读录音、ASR 失败、评分不可用测试 | Product Base FR-004；scoring-feedback |
| ScoreSignal | AI Gateway + Training domain | score_signal_id, source_type, source_id, provider, score_kind, value, confidence, status | 分数是反馈信号，不单独决定长期掌握或 P0.1 通过 | 需要 provider usage 关联和 schema_version；低置信度可标记 | AI/Feedback API 后续细化；不得由客户端伪造最终信号 | 发音、完整度、语法评分可用/不可用测试 | Product Base FR-004, FR-008；P0.1 P01-FR-007 |

### Expression Practice Queue / Favorites

| Entity | Owner | 关键字段 | 生命周期 / 不变量 | Persistence / migration implication | API boundary recommendation | Test impact | Traceability note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PracticeQueueItem | Training / Review domain | queue_item_id, user_id, source_type, target_expression_id, task_type, priority, status, due_at | 队列来自到期复习、薄弱表达和变体；必须排序和去重 | 需要来源引用和唯一去重键；P0.2 long-term planner 后续扩展 | Review/Training API 后续提供 due/complete，不定义 shape | 队列生成、优先级、空状态、去重测试 | Product Base FR-005 |
| ExpressionPracticeAttempt | Training domain | attempt_id, queue_item_id, user_id, task_type, answer_text, transcript_ref, result, best_score, completed_at | 完成任务后更新进度、最佳得分、转写、复习时间或掌握关联 | 需要 attempt 表和结果状态；失败尝试可保留用于学习证据 | Training/Review API 后续提交任务结果 | 选择判断、复述、填空、回忆、跟读任务测试 | Product Base FR-005 |
| FavoriteExpression | Learning Assets domain | favorite_id, user_id, target_expression_id, normalized_text, source_type, source_id, status | 同一用户重复收藏同一稳定表达不得新增重复项；收藏不等于自动复习 | 需要 user + stable expression/normalized text 唯一约束 | Favorites/Learning API 后续同步收藏状态 | 收藏、取消收藏、收藏页展示、去重测试 | Product Base FR-006 |
| SavedExpression | Learning Assets domain | saved_expression_id, user_id, expression_text, normalized_text, meaning_cn, example, source_type, source_id | 用户素材与官方表达元数据分离 | 与 FavoriteExpression 可合并或分表，需保留来源 | Learning Assets API 后续定义；P1 notebook 扩展后置 | 个人 Wiki、收藏摘要、学习资产入口测试 | Product Base FR-009, FR-010；P1 notebook deferred |

### Voice Scenario Practice / Feedback

| Entity | Owner | 关键字段 | 生命周期 / 不变量 | Persistence / migration implication | API boundary recommendation | Test impact | Traceability note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PracticeSession | Training Session domain | practice_session_id, user_id, scenario_id, level_code, status, current_turn_index, started_at, completed_at | Product Base 会话支持开始、恢复、完成、中断；同场景同等级可恢复未完成会话 | `mvp-backend-practice-ai` 已落地 session 表；完成后清理活跃恢复状态 | Practice API 负责 session start/resume/get/complete | 会话恢复、完成清理、错误状态测试 | Product Base FR-007, FR-009；MVP-SI-008 |
| DialogueTurn | Training Session domain | dialogue_turn_id, session_id, role, text, audio_ref, transcript_ref, turn_index, idempotency_key, created_at | 每个 turn 必须属于一个 session；用户提交后可关联反馈和证据；同 session 幂等键不得重复创建 turn | `mvp-backend-practice-ai` 已落地 turn 表；音频/转写 retention 由 Security/DevOps 后续细化 | Practice turn API 提交 turn，并由幂等键保护 replay | 录音、转写提交、消息播放、turn 顺序测试 | Product Base FR-007, FR-008；MVP-SI-008 |
| CoachFeedback | AI Gateway + Training domain | feedback_id, source_turn_id, feedback_type, summary, suggestion_ref, score_signal_id, validation_status, provider_status | 教练反馈必须来自有效 turn 或 deterministic fallback；invalid provider schema 不得成为 successful feedback；不可直接写最终 mastery | `mvp-backend-practice-ai` 已落地 feedback 表；敏感正文需脱敏策略 | AI feedback / Practice turn API 返回结构化反馈 | 教练反馈、建议、下一问题、服务失败 fallback 测试 | Product Base FR-008；MVP-SI-006, MVP-SI-009 |
| Correction | Learning Evidence domain | correction_id, source_turn_id, issue_type, original_text, improved_text, explanation, status | Correction 必须引用 DialogueTurn；可成为学习证据候选 | 需要 source turn 外键和去重规则 | Learning/Training API 后续可查询或沉淀 | 纠错展示、薄弱记录、个人素材写入测试 | Product Base FR-008, FR-009 |
| HintRequest | Training domain | hint_request_id, session_id, source_turn_id, hint_type, hint_content_ref, used_at | Product Base 提示次数和内容必须可见；P0.1 扩展为 HintState | 可本地记录，后续并入 training hint 表 | Training hints API 后续细化 | 提示展示、次数更新、失败恢复测试 | Product Base FR-007；P0.1 P01-FR-005 |

### Learning Memory / Review / Profile

| Entity | Owner | 关键字段 | 生命周期 / 不变量 | Persistence / migration implication | API boundary recommendation | Test impact | Traceability note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LearningEvidence | Learning Evidence domain | evidence_id, user_id, source_type, source_id, evidence_type, target_expression_id, confidence, accepted_status, schema_version | Product Base 可本地沉淀；P0.1 后 accepted evidence 必须由 deterministic evidence rules 写入 | 需要 `learning_*` 组表；必须支持去重、删除/匿名化、rule trace | Learning Evidence API 后续负责写入/查询；LLM 不直接写最终 evidence | 学习证据写回、失败恢复、首页/队列/Wiki 影响测试 | Product Base FR-009；P0.1 P01-FR-009 |
| EvidenceRuleTrace | Learning Evidence domain | rule_trace_id, evidence_id, rule_name, source_refs, decision, schema_version, created_at | 每条 accepted evidence 必须可解释来源和规则 | 需要与 LearningEvidence 关联；审计和测试可追溯 | Learning API 后续仅暴露必要可解释信息 | rule trace、去重、低置信度拒绝测试 | P0.1 P01-FR-009；ADR 0004 |
| MasteryRecord | Learning Evidence domain | mastery_record_id, user_id, target_expression_id, mastery_status, score, last_evidence_id, updated_at | 掌握状态变化必须追溯到 practice/review/evidence；单次评分不得单独最终裁决 | 需要 user + target unique；P0.2 L0-L5 后续扩展 | Learning/Mastery API 后续查询和更新边界 | 掌握、薄弱、复习时间、总结影响测试 | Product Base FR-008, FR-009；P0.2 deferred |
| ReviewItem | Review domain | review_item_id, user_id, source_type, source_id, prompt_type, due_at, interval_days, status | 可由学习证据或收藏来源生成；收藏本身不自动等于复习任务 | 需要 due index 和 status；P0.2 调度后续增强 | Review API 后续查询 due/submit result | 到期复习、队列优先级、完成重排测试 | Product Base FR-005, FR-009 |
| SessionSummary | Learning Evidence domain | summary_id, session_id, user_id, learned_items, weak_points, next_focus, created_at | 练习结束后必须展示总结，并影响至少一个后续入口 | 可存 summary 表或从 evidence 聚合；完成后清理活跃会话 | Learning/Training API 后续提供 recap 数据 | 练习总结、下一轮入口、后续入口刷新测试 | Product Base FR-009 |
| LearningHistoryEntry | Profile / Learning domain | history_entry_id, user_id, source_session_id, title, status, created_at, deleted_at | 历史页可查看详情和删除；删除不等于账号删除 | 需要软删除或本地历史迁移策略 | Profile/Learning API 后续提供历史列表 | 历史空状态、详情、删除测试 | Product Base FR-010 |

## P0 Commercial Domain Extension

| Entity | Owner | 关键字段 | 生命周期 / 不变量 | Persistence / migration implication | API boundary recommendation | Test impact | Traceability note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SubscriptionPlan | Commerce / Entitlement domain | plan_id, platform, product_id, billing_period, entitlement_template_id, status | 可售计划必须与商店商品和会员文案一致 | 需要 product_id allowlist 和版本记录 | Subscription/Entitlement API 后续暴露可售计划和权益 | 商品缺失、文案一致性、release gate 测试 | P0 FR-COM-001, FR-COM-009 |
| Purchase | Commerce domain | purchase_id, user_id, platform, provider_transaction_id, product_id, verification_status, purchased_at | 商店凭据未通过后端校验不得授予权益；provider transaction 去重 | 需要 provider transaction 唯一约束和幂等记录 | Subscription verify/restore API 后续细化 | 有效/无效收据、商品不匹配、账号不匹配测试 | P0 FR-COM-002, FR-COM-003 |
| Subscription | Commerce domain | subscription_id, user_id, plan_id, platform, status, starts_at, expires_at, grace_until, latest_purchase_id | 状态由后端根据 verify/webhook/refresh 更新；客户端 memberPlan 不是事实 | 需要 subscription projection 和状态机版本 | Subscription API 后续处理 verify/restore/provider event | 购买、恢复、续订、过期、退款、宽限期、撤销测试 | P0 FR-COM-001, FR-COM-002, FR-COM-003 |
| EntitlementSnapshot | Entitlement domain | entitlement_snapshot_id, user_id, source_subscription_id, plan, feature_flags, quota_limits, status, valid_until, generated_at | 后端生成用户当前权益事实；客户端只缓存可刷新快照 | 需要 user 当前 snapshot 和历史记录策略 | Entitlement API 后续查询/刷新；不得依赖本地最终判断 | 权益刷新、免费/付费 gating、退款后降级测试 | P0 FR-COM-001, FR-COM-006, FR-COM-007 |
| EntitlementRule | Entitlement domain | rule_id, feature_key, required_plan, quota_policy_ref, scenario_scope, status | 权益规则必须和会员页、商店文案、场景入口一致 | 需要规则表或配置版本；发布需审计 | Entitlement/Scenario/Usage API 后续引用规则 | 场景包 gating 三入口一致性测试 | P0 FR-COM-006, FR-COM-007, FR-COM-009 |
| UsageLedger | Usage Control domain | ledger_id, user_id, usage_family, period, reserved_amount, committed_amount, limit_amount, status | 高成本 AI/ASR/TTS/评分用量不能由 Flutter 单独扣减 | 需要 period + usage_family 索引；与 entitlement quota 对齐 | Usage API 后续查询摘要和扣减边界 | AI 额度耗尽、免费/付费额度、风控限制测试 | P0 FR-COM-010, AC-COM-012 |
| UsageReservation | Usage Control domain | reservation_id, user_id, usage_family, amount, status, idempotency_key, reserved_at, expires_at | reserve 后必须 commit/release/expire；provider 失败需可审计释放或失败 | 需要幂等键、过期 job 和事务边界 | Usage reserve/commit/release API 后续细化 | reserve/commit/release、重试、provider timeout 测试 | P0 FR-COM-010 |
| ProviderUsageEvent | Usage Control + AI Gateway domain | provider_usage_event_id, reservation_id, provider, operation, latency_ms, status, cost_class, request_id | 记录成本和故障，不保存 raw audio 或完整敏感对话 | 需要按 provider/status/time 查询；日志脱敏 | AI Gateway/Usage API 后续内部消费 | 成本预算、滥用、provider unavailable 测试 | P0 FR-COM-010；Security Design |
| AccountLifecycle | Identity domain | user_id, lifecycle_status, delete_requested_at, deleted_at, anonymized_at | 删除请求后不得继续产生新业务事实；token 需撤销 | 需要账号状态字段和删除状态关联 | User API 后续处理账号删除和状态查询 | 注销后回未登录、本地清理、token 失效测试 | P0 FR-COM-008 |
| AccountDeletionJob | Admin / Ops + Identity domain | deletion_job_id, user_id, status, requested_at, completed_at, failure_reason, retry_count | 删除 job 是独立状态机；失败可重试并审计 | 需要 `ops_*` job 表；按数据类别 hard delete/anonymize/retain | Account deletion API 后续创建/查询删除任务 | 云端删除/匿名化、本地清理、失败重试测试 | P0 FR-COM-008 |
| AuditLog | Admin / Ops domain | audit_log_id, actor_type, actor_id, event_type, target_ref, redacted_details, request_id, created_at | 审计保留最小必要字段；不得记录完整 receipt、token、raw audio | 需要 append-only audit 表和 retention 策略 | Admin/Ops API 后续受限访问 | 支付、账号删除、用量、发布门禁审计测试 | P0 FR-COM-011, FR-COM-012 |
| PaymentProviderEvent | Commerce / Admin domain | provider_event_id, platform, event_type, received_at, processed_status, related_subscription_id | webhook/provider event 必须按 provider id 去重和幂等处理 | 需要 provider event 唯一约束和处理状态 | Subscription webhook API 后续定义 provider event contract | webhook 乱序、重复、退款/过期降级测试 | P0 FR-COM-002, FR-COM-003, FR-COM-005 |

## P0 Commercial AI Provider Operations Domain Extension

Owning increment：`docs/product/increments/commercial-ai-provider-hardening/`。本节承接 `COM-SI-013` 到 `COM-SI-017`，定义 paid AI voice 前必须落地的媒体、缓存、真实 provider evidence、成本和保留删除领域对象。本文只定义领域语义和持久化边界；API shape 以 `docs/architecture/api_contract.md` 和 `docs/architecture/openapi/speakeasy-api.yaml` 为准。

| Entity | Owner | 关键字段 | 生命周期 / 不变量 | Persistence / migration implication | API boundary recommendation | Test impact | Traceability note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MediaAsset | Media Storage + AI Gateway domain | media_id, user_id, purpose, provider_ref, audit_ref, content_type, byte_size, duration_seconds, checksum_sha256, status, expires_at, deleted_at | Flutter 只能消费后端签发的 `audio_ref`；本地路径、裸 URL、伪造签名、超时长或超大小输入不得进入生产 ASR | 需要 `ai_media_asset` 或等价表；对象存储 key 与 signed URL 分离；audit 只存 hash/ref | `POST /media/audio/uploads`、`POST /media/audio/uploads/{media_id}/complete` | TC-COM-AI-001, TC-COM-AI-002 | COM-SI-013, FR-COM-AI-001 |
| TtsCacheEntry | Media Cache + AI Gateway domain | cache_id, normalized_text_hash, model, voice, language, media_id, status, hit_count, expires_at, deleted_at | cache key 不包含完整敏感文本；有效缓存命中必须复用同一持久 media ref；过期或删除后不得继续返回旧对象 | 需要 cache metadata 表和 object storage media 关系；支持多实例、重启、expiry 和账号删除 hook | `/ai/tts` response exposes `media_id`, `cache_status`, `cache_expires_at` only | TC-COM-AI-003 | COM-SI-014, FR-COM-AI-002 |
| TtsCacheOwner | Media Cache + Security domain | owner_ref_id, cache_id, owner_hash, first_attached_at, last_hit_at | 每次用户命中或创建持久 TTS cache 必须记录 owner ref；账号删除只移除该用户 owner ref，最后一个 owner 删除时才删除 cache entry | 需要 `ai_tts_cache_owners` 表和 `(cache_id, owner_hash)` 唯一约束；legacy `owner_hash` 只能作为旧数据兜底 | 不暴露给 Flutter；由 `/ai/tts`、account deletion 和 retention job 内部维护 | TC-COM-AI-007 | COM-SI-014, COM-SI-017, FR-COM-AI-002, FR-COM-AI-005 |
| ProviderSandboxRun | AI Runtime + QA/Ops domain | evidence_id, provider_family, capability, model, fixture_ref, latency_p50_ms, latency_p95_ms, status, error_code, estimated_cost, reviewed_status, evidence_ref | 真实 DashScope evidence 是 release gate；缺少 approved evidence 时不得关闭 paid AI voice gate；raw payload 不进入普通 API | 可持久化 evidence metadata；外部 evidence refs 指向脱敏测试矩阵或受限存储 | `GET /admin/ai/provider-evidence` | TC-COM-AI-004 | COM-SI-015, FR-COM-AI-003 |
| ProviderInvocationMetric | Usage Control + Ops domain | metric_id, user_hash, plan, provider_family, model, capability, status, cache_hit, token_estimate, audio_duration_seconds, estimated_cost, budget_bucket, created_at | 成本和毛利风险必须可按套餐、用户 hash、provider、模型、状态和 cache hit 聚合；不得保存 raw content | 可从 provider call event 异步聚合；需要日/周索引和 budget threshold 配置 | `GET /admin/ai/cost-metrics` | TC-COM-AI-005 | COM-SI-016, FR-COM-AI-004 |
| RetentionPolicy | Security + Ops domain | policy_id, data_class, retention_days, action, legal_hold, status, approved_by, effective_at | 每类 AI 数据必须有保留、删除、匿名化或最小审计保留规则；未批准策略不得声明 production ready | 可作为配置表或版本化 policy doc；release gate 需要 approved policy version | Admin retention job reads policy but does not expose raw policy internals to Flutter | TC-COM-AI-006, TC-COM-AI-007 | COM-SI-017, FR-COM-AI-005 |
| AiRetentionJob | Security + Backend/Ops domain | job_id, scope, user_ref, status, media_deleted_count, transcript_deleted_count, provider_payload_redacted_count, tts_cache_deleted_count, redacted_evidence_ref, failure_reason | retention/account deletion 必须删除、匿名化或保留最小审计字段，并记录脱敏证据；失败进入 retry/manual ops | 需要 job 表、幂等键和 retry/manual 状态；账号删除必须联动 MediaAsset、TtsCacheEntry 和 provider-derived private content | `POST /admin/ai/retention-jobs`、`GET /admin/ai/retention-jobs/{job_id}` | TC-COM-AI-006, TC-COM-AI-007 | COM-SI-017, FR-COM-AI-005 |

### P0 Lifecycle Notes

| 状态机 | 状态 |
| --- | --- |
| Subscription | `pending_verification -> active -> grace_period -> expired`; `active -> refunded`; `active -> revoked`; `expired/refunded/revoked -> active` 只能通过新的有效购买或恢复 |
| EntitlementSnapshot | `generated -> current -> stale -> replaced`; 离线缓存不得长期绕过服务端 |
| UsageReservation | `reserved -> committed`; `reserved -> released`; `reserved -> expired`; `reserved -> failed` |
| AccountDeletionJob | `requested -> access_revoked -> deleting_learning_data -> anonymizing_audit_refs -> completed`; 任一步可进入 `failed` 并支持 retry |
| AuditLog | append-only；允许 redaction/anonymized target ref，不允许业务流程删除审计事实 |
| MediaAsset | `pending -> uploaded -> validated`; `pending/uploaded/validated -> expired`; `pending/uploaded/validated -> deleted`; invalid metadata enters `rejected` and must not be used by ASR |
| TtsCacheEntry | `miss -> active`; `active -> hit`; `active -> stale`; `active/stale -> deleted`; provider unavailable must not create active cache |
| ProviderSandboxRun | `planned -> executed -> reviewed -> approved`; provider failure enters `failed` and release status remains blocked until reviewed |
| AiRetentionJob | `pending -> running -> completed`; failures enter `failed_retryable` or `failed_manual` and require audit-visible retry state |

### P0-COM-DOM-001 Gate Coverage

| Stage Scope ID | Requirement | Domain evidence | Test impact |
| --- | --- | --- | --- |
| COM-SI-001 | FR-COM-001 | `SubscriptionPlan`、`Purchase`、`Subscription`、`EntitlementSnapshot`、`PaymentProviderEvent` 定义订阅和权益事实源 | 购买后权益生效、退款/过期/撤销降级、权益刷新测试 |
| COM-SI-002 | FR-COM-002 | `Purchase`、`Subscription`、`PaymentProviderEvent` 覆盖 Apple transaction 校验、幂等和 provider event | Apple valid/invalid receipt、restore、webhook、refund 测试 |
| COM-SI-003 | FR-COM-003 | `Purchase`、`Subscription`、`PaymentProviderEvent` 覆盖 Google purchase token 校验和 Android 恢复购买 | Google valid/invalid token、restore、webhook、refund 测试 |
| COM-SI-004 | FR-COM-004 | `User`、`AuthIdentity`、`AccountLifecycle` 覆盖生产账号事实、账号状态和测试登录发布门禁 | release config gate、token/session、账号切换测试 |
| COM-SI-005 | FR-COM-005 | `AuthIdentity` 和 `PaymentProviderEvent` 覆盖社交登录身份与 provider event 可信边界 | Apple/WeChat 生产配置缺失阻断、provider signature 测试 |
| COM-SI-006 | FR-COM-008 | `AccountLifecycle`、`AccountDeletionJob`、`AuditLog` 覆盖注销、删除/匿名化和审计 | 云端删除、本地清理、失败重试、审计测试 |
| COM-SI-007 | FR-COM-006 | `EntitlementSnapshot`、`EntitlementRule`、`UsageLedger` 覆盖免费/付费权益和额度边界 | 付费墙、超限态、降级态测试 |
| COM-SI-008 | FR-COM-007 | `EntitlementRule` 可引用 `scenario_scope`，并与 `Scenario` 访问边界关联 | 场景列表、详情、训练入口 gating 一致性测试 |
| COM-SI-009 | FR-COM-009 | `SubscriptionPlan`、`EntitlementRule`、`AuditLog` 支持商品、权益和文案版本可追踪 | 会员页/商店/隐私文案一致性测试 |
| COM-SI-010 | FR-COM-010 | `UsageLedger`、`UsageReservation`、`ProviderUsageEvent` 覆盖 AI/ASR/TTS/评分成本控制 | reserve/commit/release、额度耗尽、滥用审计测试 |
| COM-SI-011 | FR-COM-011 | `AuditLog`、`PaymentProviderEvent`、`AccountDeletionJob` 为商业边界测试提供可审计事实 | 商业边界测试矩阵结果追踪 |
| COM-SI-012 | FR-COM-012 | `AuditLog`、`AccountLifecycle`、`SubscriptionPlan` 支持发布门禁、配置审计和回滚核查 | release secrets、签名、符号表、商店材料和回滚检查 |
| COM-SI-013 | FR-COM-AI-001 | `MediaAsset` 覆盖 Flutter 录音上传、可信 `audio_ref`、签名元数据、对象生命周期和 ASR 输入边界 | media upload/signing、ASR ref resolution、非法 ref 拒绝测试 |
| COM-SI-014 | FR-COM-AI-002 | `TtsCacheEntry` + `MediaAsset` 覆盖持久化 TTS cache key、media ref、expiry 和删除 hook | persistent TTS cache hit/miss/expiry/delete tests |
| COM-SI-015 | FR-COM-AI-003 | `ProviderSandboxRun` 覆盖真实 DashScope LLM/ASR/TTS evidence、review 状态和 release gate | DashScope sandbox matrix evidence review |
| COM-SI-016 | FR-COM-AI-004 | `ProviderInvocationMetric` 覆盖成本、cache hit、budget bucket 和 margin risk 聚合 | AI cost dashboard aggregation tests |
| COM-SI-017 | FR-COM-AI-005 | `RetentionPolicy`、`AiRetentionJob` 覆盖音频、转写、provider payload、TTS cache 和账号删除证据 | retention policy and account deletion media cleanup tests |

P0-COM-DOM-001 结论：Domain Schema 对 `commercial-subscription-readiness` 的 12 个 required Stage Scope Items 均有领域对象、生命周期或不变量承接。本文仍不定义 API DTO、数据库 SQL、Flutter UI 或实现顺序。

P0-AI-ARCH-001 结论：Domain Schema 对 `commercial-ai-provider-hardening` 的 5 个 required Stage Scope Items 均有领域对象、状态机、持久化方向、API boundary recommendation 和测试影响承接。Backend 实现可以开始前，仍需通过 API/security/document-traceability 检查。

## P0.1 Training Domain Extension

专项领域模型见 `docs/domain/training_model.md`。下表保留领域总览；P0.1 具体字段、不变量、状态机、持久化边界和 `P01-GAP-001` 覆盖关系以专项文档为准。

| Entity | Owner | 关键字段 | 生命周期 / 不变量 | Persistence / migration implication | API boundary recommendation | Test impact | Traceability note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TrainingSession | Training Planner domain | training_session_id, user_id, scenario_id, level_code, status, current_action_step_id, current_micro_action, started_at, completed_at | P0.1 session 内训练事实；只限两个官方场景；不承诺跨天长期调度 | 需要 `training_*` session 表；可从 PracticeSession 迁移或并行建模 | Training API 后续负责创建、恢复、完成；本文不定义 payload | 官方场景入口、恢复、完成、abandon、error 测试 | P0.1 P01-FR-001, P01-FR-010 |
| TrainingTurn | Training Planner domain | training_turn_id, training_session_id, user_action, transcript_ref, audio_ref, result, created_at | 每次 micro-action 尝试形成可追踪 turn；ASR 失败不能直接判定不会 | 需要 turn 表和 source refs；与 provider usage 可关联 | Training turn API 后续提交 turn 和幂等规则 | 录音、重录、文本兜底、ASR 失败测试 | P0.1 P01-FR-003, P01-FR-006, P01-FR-007 |
| ActionChainStep | Content + Training Planner domain | action_chain_step_id, scenario_version_id, step_key, learner_task, success_condition, order_index | 当前 P0.1 step 限定为开场、说明目的、表达观点、回应追问、确认下一步、结束 | 需要内容版本关联；缺失显式标注时可本地映射但需可追踪 | Scenario/Training API 后续暴露 step 引用 | action chain mapping、缺失标注 fallback 测试 | P0.1 P01-FR-002 |
| MicroAction | Training Planner domain | micro_action_id, action_type, target_expression_id, prompt_ref, pass_signal_rule, fallback_rule | 一次只呈现一个主要动作；必须有通过信号或重试路径 | 可作为枚举/配置 + session 引用；P0.2 后续扩展 | Training planner API 后续返回下一动作引用，不定义 shape | 听一句、选一个、回一句、跟一句、补一句、追问继续说测试 | P0.1 P01-FR-003 |
| HintState | Training Planner domain | hint_state_id, training_session_id, current_hint_level, failure_count, success_count, last_changed_at | hint ladder：无提示、句框、选项、chunk shadowing、model-then-retry；失败升支架，通过降支架 | 需要保留当前 level 和计数；可从 PlannerDecision 重建但建议显式保存 | Training hints/planner API 后续细化 | hint 升降级、可见性、model-then-retry 测试 | P0.1 P01-FR-005 |
| PlannerDecision | Training Planner domain | planner_decision_id, training_session_id, source_turn_id, decision_type, next_action_ref, hint_level, reason_code, schema_version | 决策必须由 deterministic rules 裁决；LLM 只能提供候选建议 | 需要 decision log；便于测试和回放 | Planner API 后续处理 next/hint/pressure decision | 重试、降级、升级、评分不可用、ASR 失败测试 | P0.1 P01-FR-004；ADR 0004 |
| PressureCheck | Training Planner domain | pressure_check_id, training_session_id, trigger_decision_id, prompt_ref, status, result | 只限 session 内轻量追问或近场景复现；失败可回到更高 hint level | 需要与 PlannerDecision 和 TrainingTurn 关联 | Planner/Training API 后续定义 pressure check 行为 | 连续通过触发、通过/失败回流测试 | P0.1 P01-FR-008 |
| AIResultRef | AI Gateway domain | ai_result_ref_id, provider_request_id, schema_version, validation_status, source_turn_id | AI 输出未经 schema validation 不得进入 UI 或学习证据 | 需要 provider log 与 training turn 关联；raw payload 受限保存 | AI Runtime/API 后续定义 schema；本文不定义 AI output shape | invalid schema、timeout、fallback、不写 mastery 测试 | P0.1 P01-FR-007, P01-FR-010 |
| LearningEvidenceCandidate | Learning Evidence domain | candidate_id, source_turn_id, source_ai_result_ref, evidence_type, confidence, status | 候选证据不能直接改变最终掌握；必须经 evidence rules 接受或拒绝 | 可与 LearningEvidence 分表或 status 区分；需保留拒绝原因 | Learning Evidence API 后续写入 accepted evidence | LLM 候选、低置信度拒绝、去重测试 | P0.1 P01-FR-009 |
| TrainingRecap | Training + Learning Evidence domain | recap_id, training_session_id, summary_ref, evidence_refs, next_focus, status | recap 可见结果不得因学习证据写回失败而丢失 | 需要与 session 和 evidence refs 关联；失败可重试写回 | Training/Learning API 后续提供 recap 查询 | recap 可见、写回失败可恢复、下一步建议测试 | P0.1 P01-FR-009, P01-FR-010 |

### Product Base Practice Lifecycle Notes

| 状态机 | 状态 |
| --- | --- |
| PracticeSession | `active -> feedback -> completed`; provider/网络/转写失败可进入 `recoverable_error` 并允许重试或退出 |
| DialogueTurn | `submitted -> feedback_ready`；ASR/provider/media/schema failure 可进入 `rejected`，但必须保留 session recovery |
| CoachFeedback | `valid -> user_visible` 或 `fallback -> recoverable_error`；invalid schema 不得成为 successful feedback |

### P0.1 Lifecycle Notes

| 状态机 | 状态 |
| --- | --- |
| TrainingSession | `loading -> ready -> in_progress -> feedback -> retry -> pressure_check -> recap -> completed`; 任一可恢复失败进入 `recoverable_error`，用户可 retry/exit/recap |
| TrainingTurn | `created -> transcribing -> evaluating -> feedback_ready`; ASR 失败进入 `asr_failed` 并允许重录或文本兜底 |
| PlannerDecision | `generated -> applied -> superseded`; 不允许未应用决策修改最终 evidence |
| HintState | `none -> sentence_frame -> options -> chunk_shadowing -> model_then_retry`; 连续通过可降低支架或进入 pressure check |
| LearningEvidenceCandidate | `candidate -> accepted`; `candidate -> rejected`; `candidate -> merged_duplicate` |
| LearningEvidence | `accepted -> reflected_in_mastery/review`; 账号删除后进入 `deleted` 或 `anonymized` |

### P0.1-DOM-001 Gate Coverage

| Stage Scope ID | Requirement | Domain evidence | Test impact |
| --- | --- | --- | --- |
| P01-SI-002 | P01-FR-004 Session planner | `TrainingSession`、`PlannerDecision`、`HintState` 定义 planner 输入、决策、reason code、可回放和可测试边界 | planner decision unit tests |
| P01-SI-003 | P01-FR-002 Action chain | `ActionChainStep` 定义六段动作链、内容版本引用和缺失标注 fallback | action chain mapping tests |
| P01-SI-004 | P01-FR-003 Micro-action flow | `MicroAction`、`TrainingTurn` 定义一次一个动作、通过信号、重试路径和用户尝试记录 | micro-action state/unit/widget tests |
| P01-SI-005 | P01-FR-005 Hint ladder | `HintState` 定义 `none -> sentence_frame -> options -> chunk_shadowing -> model_then_retry` 升降级 | hint ladder unit/widget tests |
| P01-SI-006 | P01-FR-008 In-session pressure check | `PressureCheck` 定义 session 内轻量追问、通过/失败回流和非跨天边界 | pressure check planner tests |
| P01-SI-008 | P01-FR-007 即时反馈与评分边界 | `TrainingFeedback`、`AIResultRef`、`LearningEvidenceCandidate` 定义 AI 候选、评分信号和最终规则裁决边界 | AI schema and feedback tests |
| P01-SI-009 | P01-FR-009 学习证据写回 | `LearningEvidenceCandidate`、`EvidenceRuleTrace`、`TrainingRecap` 定义候选证据、接受/拒绝和 recap 保留 | evidence write-back and recap tests |

P0.1-DOM-001 结论：`docs/domain/training_model.md`、本文和 `docs/domain/entity_relationship.md` 已覆盖 P0.1 domain model gate。后续 AI、UX、Architecture 和 Test gates 仍需单独完成。

## Cross-Domain Invariants

| Invariant | 说明 |
| --- | --- |
| Stable IDs | User、Scenario、ScenarioVersion、TargetExpression、Session、Evidence 必须有稳定 ID，不能只靠展示文本连接。 |
| Source refs | Correction、CoachFeedback、ScoreSignal、LearningEvidence 必须能追溯到 source turn、attempt、review 或 rule trace。 |
| Client cache boundary | Flutter 可缓存 entitlement、profile、scenario、session draft、learning summary；不得作为权益、用量、最终 evidence 的事实源。 |
| Payment truth | Purchase、Subscription、EntitlementSnapshot 只能由服务端校验和 provider event 产生或变更。 |
| Usage truth | UsageLedger 和 UsageReservation 只能由服务端可信边界写入。 |
| AI truth boundary | AIResultRef 和 LearningEvidenceCandidate 是候选输入；PlannerDecision 和 EvidenceRuleTrace 才能解释最终推进。 |
| Deletion boundary | AccountDeletionJob 必须处理用户资料、学习数据、收藏、会话、证据、音频/转写引用；AuditLog 只保留最小脱敏字段。 |
| Product boundary | P0.1 不得新增第三官方场景、跨天调度或完整 L0-L5；P0 不得把未实现权益作为付费承诺。 |

## Persistence And Migration Implications

| Domain group | Persistence direction |
| --- | --- |
| `identity_*` | User、AuthIdentity、UserProfile、OnboardingAssessment、LearningRoute、AccountLifecycle |
| `content_*` | Scenario、ScenarioVersion、ScenarioLevel、TargetExpression、DialogueAsset、ActionChainStep |
| `training_*` | PracticeSession、DialogueTurn、ListeningWarmup、ShadowingAttempt、TrainingSession、TrainingTurn、PlannerDecision、HintState、PressureCheck、TrainingRecap |
| `learning_*` | FavoriteExpression、SavedExpression、LearningEvidence、LearningEvidenceCandidate、EvidenceRuleTrace、MasteryRecord、ReviewItem、SessionSummary、LearningHistoryEntry |
| `commerce_*` | SubscriptionPlan、Purchase、Subscription、EntitlementSnapshot、EntitlementRule、PaymentProviderEvent |
| `usage_*` | UsageLedger、UsageReservation、ProviderUsageEvent、ScoreSignal provider linkage |
| `media_*` / `ai_media_*` | MediaAsset、TtsCacheEntry、provider-accessible signed media refs、object lifecycle metadata |
| `ai_ops_*` | ProviderSandboxRun、ProviderInvocationMetric、RetentionPolicy、AiRetentionJob |
| `ops_*` | AccountDeletionJob、AuditLog |

本文不写 migration SQL。后续 migration 必须等 Domain Schema 和 API Contract 通过复核后，由 Backend/DB implementation plan 生成。

## API Boundary Recommendations

| Domain | 后续 API Contract 输入 |
| --- | --- |
| Identity / Onboarding | Auth、User profile、Onboarding、Account deletion family |
| Scenario / Content | Scenario list/detail/version/level/content family |
| Product Base training | Practice or Training session family，需支持 start/resume/turn/complete |
| Learning memory | Learning evidence、mastery、review、favorites/history family |
| Commerce / Entitlement | Subscription verify/restore/provider event、Entitlement query/refresh family |
| Usage | Usage summary、reserve、commit、release family |
| Media Storage | Audio upload/create/complete、trusted media ref resolution family |
| AI Ops | Provider evidence、cost metrics、budget status、retention job family |
| P0.1 Planner | Training session、turn、planner next、hint、pressure check family |
| AI Gateway | Transcribe、TTS、feedback、pronunciation family，需与 usage 和 schema validation 关联 |

API Contract 阶段必须使用 OpenAPI source-of-truth，并为支付、用量、删除、训练 turn replay 定义 authentication、authorization、idempotency、error code 和 contract tests。本文不定义 request/response shape。

## MVP Practice/AI Increment Note

Owning increment: `docs/product/increments/mvp-backend-practice-ai/`.

- `PracticeSession`、`DialogueTurn`、`CoachFeedback` 和 `SessionSummary` 已在 backend persistence 中落地为 Product Base practice lifecycle 的事实源。
- `SessionSummary` 在本 increment 中只输出 candidate-only learning input；最终 `MasteryRecord`、accepted `LearningEvidence` 和长期复习规则仍归 `mvp-backend-learning-memory`。
- AI/ASR/TTS/pronunciation provider 只通过 server-side gateway adapter 调用；客户端不得提交 provider secret。

## MVP Learning/Memory Increment Note

Owning increment: `docs/product/increments/mvp-backend-learning-memory/`.

- `PracticeQueueItem`、`ExpressionPracticeAttempt`、`FavoriteExpression`、`LearningEvidence`、`MasteryRecord`、`ReviewItem`、`SavedExpression` 和 `LearningHistoryEntry` 已在 backend persistence 中落地为 Product Base learning/memory 事实源。
- 表达队列由已加入官方场景的稳定 `TargetExpression` 生成，并按 evidence-derived priority 去重排序；无已加入场景时返回明确空状态。
- `LearningEvidence` 只有在有稳定 target expression 且置信度满足规则时才写入 mastery、review、personal wiki、history 和后续 queue projection；低置信度或缺 target 的 evidence 保留为 rejected，不更新最终 mastery。
- 收藏使用稳定 `target_expression_id` 幂等去重；历史删除为用户历史软删除，不等同账号删除。

## MVP Membership/Boundary Increment Note

Owning increment: `docs/product/increments/mvp-backend-membership-boundary/`.

- `AccountDeletionJob` 作为账号删除状态事实源保留；成功删除时用户账号标记为 `deleted`，active session 被撤销，用户自有 profile、onboarding、scenario state、practice、learning evidence、mastery、review、favorites、saved expressions、history 和 commercial foundation user rows 被清理。
- `AuditLog` 只保留最小脱敏删除完成/失败证据；不保留 token、raw audio、完整敏感对话或支付凭据。
- MVP membership/report boundary 只落地边界事实：membership entry state、Android billing not connected、learning report empty placeholder、offline content placeholder、achievement placeholder。
- 完整商业订阅、真实 payment provider verify/restore/webhook、权益 gating、付费报告、离线内容包和成就系统仍不是本 increment 的领域事实。

## Test Impact Summary

| Scope | Required test direction |
| --- | --- |
| Product Base accepted domain | 保持启动门禁、首评、双场景、听力热身、表达队列、收藏、语音会话、学习沉淀、个人中心回归测试。 |
| P0 commercial | 增加购买、恢复、无效凭据、退款/过期/撤销、权益刷新、用量额度、账号注销、商业文案一致、release gate 测试。 |
| P0.1 training | 增加 action chain、micro-action、planner decision、hint ladder、pressure check、ASR fallback、AI schema fallback、learning evidence write-back 测试。 |
| Cross-domain | 增加删除/匿名化、审计脱敏、source trace、client cache stale、idempotency 和 provider failure 测试。 |

## Omitted Scope

| Scope | 原因 |
| --- | --- |
| API request/response schema | 由 API Contract/OpenAPI 阶段负责。 |
| PostgreSQL migration SQL | 由 Backend/DB implementation plan 和 migration 阶段负责。 |
| Flutter 业务代码或 backend 代码 | 本轮只定义领域模型。 |
| AI prompt/schema/eval | 由 AI Runtime 阶段负责。 |
| UX screen spec | 由 UX/Screen Spec 阶段负责。 |
| QA test case detail / DevOps release workflow | 由 QA / DevOps 阶段负责。 |
| P0.2 跨 session/跨天 planner 和完整 L0-L5 | Future stage。 |
| P1 notebook、评分产品化、更多场景包 | Future stage。 |
| P2 A1-C2、CMS、内容生产工具 | Future stage。 |
| 旧 `E:/ZhenChe/APP/speakeasy_backend` | 不作为当前目标架构依据。 |

## Downstream Handoff

本文件通过复核后，下游应先进入 API Contract/OpenAPI，输入包括：

- 本文实体清单、状态机和事实源边界。
- `docs/domain/entity_relationship.md` 的 ownership 与 cardinality。
- `docs/architecture/backend_db_foundation_contract.md` 的 OpenAPI source-of-truth 和 generated Dart client policy。
- P0/P0.1 traceability 中列出的 contract gaps。

API Contract/OpenAPI 通过复核后，才进入 AI Runtime、UX、QA、DevOps 和代码实现。
