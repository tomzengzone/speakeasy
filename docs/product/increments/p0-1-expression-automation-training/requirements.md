# P0.1 Increment Requirements：表达自动化训练 Agent

## 状态
Implementation-review ready - 从 legacy P0.1 spec 迁移生成，作为本 increment 的标准 requirements；2026-06-04 P0.1 Product Base/production-hardening local implementation review passed，仍归属本 P0.1 stage 和 `p0-1-expression-automation-training` increment；PM Product Base merge approval and P0 commercial / paid AI external gates remain separate。

## Product Object
- Classification: `feature-increment`
- Increment: `p0-1-expression-automation-training`
- Active stage: `docs/product/stages/p0-1-expression-automation.md`
- Primary feature: `expression-automation-training`
- Affected features: `voice-scenario-practice`, `official-scenario-library`, `listening-shadowing`, `expression-practice-queue`, `learning-memory-review`, `scoring-feedback`

## 上游来源
- `docs/product/increments/p0-1-expression-automation-training/definition.md`
- Product Base：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`
- `docs/product/feature_registry.md`
- `docs/process/change_request.md`
- Legacy source: `docs/product/features/mvp-learning-loop-spec.md`

## Stage Scope Coverage
| Stage Scope ID | Requirement ID | Coverage status |
| --- | --- | --- |
| P01-SI-001 | P01-FR-001, P01-FR-012, P01-FR-014 | Covered；production hardening adds backend session source-of-truth and versioned content mapping |
| P01-SI-002 | P01-FR-004, P01-FR-012, P01-FR-016 | Covered；production hardening adds backend planner contract and decision audit |
| P01-SI-003 | P01-FR-002, P01-FR-014 | Covered；production hardening replaces hardcoded-only action chain with versioned content mapping |
| P01-SI-004 | P01-FR-003, P01-FR-012, P01-FR-014 | Covered；production hardening requires backend turn state and versioned micro-action references |
| P01-SI-005 | P01-FR-005, P01-FR-016 | Covered；production hardening adds planner audit for hint transitions |
| P01-SI-006 | P01-FR-008, P01-FR-016 | Covered；production hardening adds pressure-check decision audit |
| P01-SI-007 | P01-FR-006, P01-FR-011, P01-FR-015, P01-FR-017 | Covered；production hardening connects voice path to trusted media and rollout gates |
| P01-SI-008 | P01-FR-007, P01-FR-011, P01-FR-015, P01-FR-016, P01-FR-017 | Covered；production hardening keeps AI output candidate-only and auditable |
| P01-SI-009 | P01-FR-009, P01-FR-013, P01-FR-017 | Covered；production hardening adds server evidence write-back, rule trace and metrics |
| P01-SI-010 | P0.1 非目标边界 | Covered by non-goals and AC-P01-012 |
| P01-SI-011 | P01-FR-010, P01-FR-012, P01-FR-013, P01-FR-015, P01-FR-017 | Covered；production hardening adds recoverable backend/API/media/evidence failure handling |

## 用户目标
学习者在现有官方场景中不再面对开放式“大任务”，而是在训练型 Agent 引导下完成一个个小动作，通过语音优先、文本兜底的训练闭环，把目标表达练到能在场景中自然说出。

## 用户路径
1. 用户从 `job_interview` 或 `onboarding_introduction` 进入 P0.1 训练。
2. 系统按场景、等级、action chain 和已有学习证据创建或恢复训练 session。
3. Session planner 选择当前 action chain step、target expression、micro-action 和 hint level。
4. 用户只完成一个小动作：听一句、选一个、回一句、跟一句、补一句或在追问下继续说。
5. 用户优先语音作答；ASR 失败、麦克风拒绝或调试模式下可使用文本兜底。
6. 系统即时反馈表达完成度、场景任务完成度、必要的发音反馈和更地道表达建议。
7. Planner 根据表现决定重试、提示升级、任务升级或轻量压力检测。
8. 用户连续通过后，系统减少提示并进入轻量追问或近场景复现。
9. 本轮结束后，系统写回学习证据，并展示 recap 和下一步建议。

## Functional Requirements

### P01-FR-001 官方场景入口
- 系统必须只在 `job_interview` 和 `onboarding_introduction` 两个现有官方场景中启用 P0.1 训练。
- 用户必须能从当前官方场景和目标等级进入训练型 Agent session。
- 进入训练前必须保留当前 MVP 的场景选择、等级切换和会话恢复边界。

### P01-FR-002 Action chain
- 每个 P0.1 场景必须能映射到 action chain step：开场、说明目的、表达观点、回应追问、确认下一步、结束。
- 系统必须能在 session 中记录当前 action chain step。
- 缺失显式标注的场景资产，可以先使用本地映射补齐，但不得承诺新增官方场景内容。

### P01-FR-003 Micro-action flow
- 系统必须把训练拆成 micro-action：听一句、选一个、回一句、跟一句、补一句、在追问下继续说。
- 每次用户只应看到或听到一个主要动作。
- 每个 micro-action 必须有可判定的通过信号或重试路径。

### P01-FR-004 Session planner
- Planner 必须根据场景、等级、action chain、目标表达、最近尝试结果、ASR 状态、评分信号和学习证据选择下一步。
- Planner 必须输出 micro-action、target expression、hint level、是否重试、是否降级、是否升级、是否进入 pressure check。
- Planner 决策必须可测试，不能只依赖自由 LLM 对话。

### P01-FR-005 Hint ladder
- 系统必须支持从低到高的提示阶梯：无提示、句框、选项、chunk shadowing、model-then-retry。
- 用户连续失败时，系统必须提高支架或提供更明确的 model-then-retry。
- 用户连续通过时，系统必须降低支架或进入轻量压力检测。

### P01-FR-006 语音主路径与文本兜底
- 用户作答必须以语音为主路径，支持录音、取消、提交、重录和播放。
- ASR 失败、麦克风拒绝或调试模式下，系统必须提供文本兜底。
- 文本兜底不得成为默认主路径。

### P01-FR-007 即时反馈与评分边界
- 用户提交有效作答后，系统必须给出表达完成度、场景任务完成度和更地道表达建议中的核心反馈。
- 发音评分可用时必须进入反馈；不可用时不得阻断训练闭环。
- 发音低分不能单独决定用户不通过，必须结合表达完成度和场景任务完成度。

### P01-FR-008 In-session pressure check
- 用户连续通过后，系统必须减少提示。
- 系统必须进入轻量追问或近场景复现，以检测用户是否能在更少支架下说出目标表达。
- P0.1 的 pressure check 只限 session 内，不承诺跨天、跨场景或完整 L0-L5。

### P01-FR-009 学习证据写回
- 本轮训练结束后，系统必须写回掌握、薄弱、复习、个人素材或下一步建议中的至少一种学习证据。
- 写回结果必须能进入首页、推荐表达、个人 Wiki 或 session recap 的至少一个后续入口。
- LLM 不得直接拥有最终持久化掌握状态的变更权；持久化更新必须由应用规则执行。

### P01-FR-010 可恢复失败
- 场景、表达、历史证据、音频资源、TTS、ASR、LLM、评分或本地写回失败时，系统必须展示可恢复错误。
- ASR 失败不能直接判定用户不会，必须允许重录或文本兜底。
- 服务失败不得阻断用户退出 session 或查看已可用的 recap。

### P01-FR-011 后端 AI Provider Gateway
- 系统必须在当前 Spring Boot 后端的 `AiProviderGateway` 抽象后接入真实 LLM/TTS/ASR provider，不得切换到旧后端工程或让 Flutter 直连 provider。
- 系统必须保留 `DeterministicAiProviderGateway` 作为默认 test/dev provider，并通过配置选择真实 DashScope provider。
- DashScope provider 必须覆盖 Qwen LLM、DashScope TTS 和 Paraformer ASR 的 normalized result mapping：成功返回 `available`/`success`，失败返回 `no_result`、`provider_unavailable`、`invalid_schema` 或 recoverable fallback。
- `audio_ref` 必须是后端/provider 可访问且带后端签名媒体元数据的媒体引用；客户端本地文件路径或未签名 HTTP ref 不得被当作真实 ASR 输入并产生伪成功 transcript。
- TTS 必须使用稳定 cache key 避免同一 text/model/voice 在同一后端进程内重复调用 provider；持久对象存储缓存属于后续 release-hardening，不作为本轮通过条件。
- LLM 输出不得直接写最终 mastery、entitlement、billing 或 review schedule；后端必须先做结构化 JSON 映射和 fallback。

### P01-FR-012 后端 Training API 与服务端训练事实源
- 系统必须将 `docs/architecture/openapi/speakeasy-api.yaml` 中已定义的 `/training/sessions`、`/training/sessions/{session_id}`、`/training/sessions/{session_id}/turns`、`/planner/next`、`/hints`、`/pressure-check` 和 `/complete` 明确实现为当前 Spring Boot 后端能力，或在 release gate 中显式标记为未实现并阻断 Product Base 合入。
- 生产训练 session 的事实源必须是后端 Training bounded context；Flutter 只能缓存和渲染当前状态，不得独立生成可被当作服务端事实的 session、turn、planner decision 或 accepted evidence。
- `submitTrainingTurn` 必须要求幂等键，重复提交同一 turn 不得重复扣减用量、重复生成学习证据或推进两个 planner decision。
- 后端必须基于当前用户身份校验 session ownership；客户端不得通过传入 `user_id`、`provider_tier` 或本地 session id 越权恢复或推进训练。
- Flutter production training entry 必须依赖后端 Training API；当 `ENABLE_BACKEND_TRAINING` 关闭或后端 training 不可用时，训练入口必须关闭或显示服务不可用，不得降级到前端本地 Training 状态机、假 session、假 planner decision 或假 feedback。

### P01-FR-013 学习证据写回、rule trace 与数据治理
- 训练结束或关键 turn 完成后，系统必须由后端规则接受、拒绝或合并 `LearningEvidenceCandidate`，并为 accepted evidence 记录 source turn、feedback/schema version、rule name、reason code 和 created_at。
- Recap 必须来自后端 Training API 或明确的后端可恢复失败状态；服务端 evidence 写回失败时必须保持 `retryable` 或 failed-with-reason，不得在 Flutter 里生成 `pending_local_write` 作为生产证据。
- 账号删除、数据导出、retention job 和安全日志必须覆盖 P0.1 training session、turn、media refs、planner decision、recap 和 evidence rule trace。
- LLM 或 provider payload 不得直接进入 accepted evidence；只有 schema-valid candidate 加 deterministic evidence rule trace 后才可写入。

### P01-FR-014 版本化训练内容与 action chain 映射
- P0.1 仍只覆盖 `job_interview` 和 `onboarding_introduction`，但 production-ready 训练不得只依赖 Flutter 本地常量；必须有版本化 content mapping 或受审核 bundled asset 作为 action chain、micro-action prompt 和 target expression 的事实源。
- 每个 `ActionChainStep` 必须引用 stable `scenario_version_id`、`step_key`、`order_index`、`target_expression_id` 或明确的 reviewed fallback reason。
- 内容版本变更必须可灰度、回滚和测试；旧 session 必须继续引用其创建时的 scenario version，不得因内容更新而改变历史证据含义。
- 缺少内容映射时，系统必须 fail closed 到可恢复错误或 reviewed fallback，不得由 LLM 即兴生成新官方场景内容。

### P01-FR-015 真实语音/media/AI pipeline 接入训练 turn
- 需要语音作答的 training turn 必须通过后端 media upload 或可信 `audio_ref` 链路进入 ASR，不得把客户端本地文件路径当作 provider-accessible 输入。
- Training turn 必须经过 AI Gateway usage reservation、provider call、schema validation、fallback 和 usage commit/release；失败时返回 typed recoverable state。
- TTS、ASR、LLM 和 pronunciation signal 的 normalized status 必须进入 planner input，但发音不可用或低分不得单独阻断训练。
- Flutter 训练页必须调用后端 Training API；生产入口不得继续使用 local draft adapter、固定假 feedback、固定假 transcript 或前端 planner 代表真实 provider/Training service 结果。

### P01-FR-016 Planner service 审计、配置和回放
- Planner 必须作为 deterministic domain service 存在于可测试边界内，并输出 `PlannerDecision`、`reason_code`、`source_turn_id`、`next_micro_action_type`、`hint_level`、`schema_version` 和 `applied_at`。
- Hint ladder、pressure check、retry、recap 和 text fallback 的阈值必须来自配置或版本化规则，不得散落在页面事件处理里。
- 每个 applied decision 必须能根据 session、turn、AI candidate、score signal 和 existing evidence 重放；重放结果不一致必须成为测试或审计失败。
- LLM recommended next action 不得绕过 planner allowed-action set；不合法候选必须被拒绝并记录 reason code。

### P01-FR-017 训练运营指标、商业边界和 rollout gates
- 系统必须记录 P0.1 training funnel 指标：session start/resume、turn submit、ASR fallback、hint escalation、pressure check enter/pass/fail、recap shown、evidence accepted/rejected/write_failed、provider status 和 latency/cost bucket。
- 指标必须使用 user hash、session id、request id 和 redacted metadata；不得记录 raw audio、完整敏感 transcript、provider key 或 raw provider payload。
- P0.1 训练功能必须有 feature flag、kill switch 和 provider rollback 路径；provider failure 或成本异常时可切换到后端 deterministic provider、关闭训练入口或关闭 paid AI voice，不得回退到 Flutter 本地 Training 状态机。
- 若 P0.1 训练被纳入付费权益，必须复用 P0 commercial entitlement/usage/release gates；P0.1 本身不得绕过 `p0-commercial-readiness` 或 `commercial-ai-provider-hardening` 的 strict blockers。

## 成功标准
- 用户能在两个官方场景中进入训练型 Agent session。
- 用户每一步只面对一个明确 micro-action。
- Planner 能根据用户表现选择重试、提示升降级、升级或轻量压力检测。
- 连续通过后，系统减少提示并进入轻量追问或近场景复现。
- ASR、麦克风或外部服务失败时存在可恢复路径。
- 本轮结束后学习证据写回，并能影响至少一个后续学习入口。
- 当前后端能够在不暴露 provider secret 的前提下，通过可配置 provider adapter 调用真实 DashScope LLM/TTS/ASR，且默认测试仍不依赖第三方服务。
- Product Base 合入前，OpenAPI Training endpoints 与 Spring Boot 实现状态一致；若未实现，Product Base 合入必须 blocked。
- 服务端能保存或明确阻断 TrainingSession、TrainingTurn、PlannerDecision、TrainingRecap、LearningEvidenceCandidate 和 rule trace；Flutter 不再保留本地 Training 状态机事实源。
- 训练内容映射有版本和回滚策略；当前两个官方场景的 action chain 不再只能靠 Flutter 常量解释。
- 训练 turn 的真实语音/media/AI pipeline、observability、usage/cost 和 rollout gate 均有测试或明确外部阻断证据。

## 非目标
- 不新增第三个官方场景。
- 不实现任意场景生成或用户自定义公开场景。
- 不实现完整 A1/A2/B1/B2/C1/C2 内容体系。
- 不实现跨 session、跨天、跨场景的长期训练调度。
- 不实现完整 L0-L5 掌握阶梯。
- 不把任意短语/单词查询和笔记本产品化放入 P0.1。
- 不把完整评分体系、学习报告或商业权益 gating 作为 P0.1 阻塞项。

## 假设
- 当前 TTS、录音、文本类评分和 LLM 教练反馈链路可复用；生产 ASR/发音评分必须等待 trusted upload + Backend AI Gateway，不得复用本地文件路径或文本派生评分。
- 官方场景资产已提供目标表达、等级轨道和示范对话。
- P0.1 第一版曾允许学习证据本地优先写回；本轮商业软件整改要求 Product Base 合入前必须给出服务端事实源实现或明确阻断口径。
- 真实 ASR live E2E 需要后端可访问的音频对象或 URL；本轮不把 Flutter 本地文件路径视为有效 provider 输入。
- 本轮不新增 stage；新增 FR 均追溯到现有 P01-SI-001..011 和 `p0-1-expression-automation-training`。

## 开放问题
- P0.1 session 状态是否只本地持久化，还是需要 repository-backed 同步。2026-06-03 商业整改决策：Product Base 合入前必须 repository-backed sync 或显式 blocked。
- action chain 映射先写在本地常量、场景资产扩展字段，还是独立内容 schema。2026-06-03 商业整改决策：生产 ready 必须有版本化 content mapping 或 reviewed bundled asset。
- 训练页是改造现有 `interview_practice_page`，还是拆出专门的 training session view。2026-06-03 商业整改决策：UI 形态可继续拆页，但生产模式必须通过后端 Training API；Flutter local draft adapter 不再作为可进入的训练路径。
