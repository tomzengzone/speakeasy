# P0.1 Acceptance Criteria：表达自动化训练 Agent

## 状态
Implementation-review ready - 基于 P0.1 increment spec 生成；AC-P01-014 through AC-P01-019 已映射到 TC-P01-021 through TC-P01-031 并在 2026-06-04 implementation review 中保持 local executed / passed；PM Product Base merge approval and P0 commercial / paid AI external gates remain separate。

## 上游来源
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/spec.md`

## Stage Scope Acceptance Coverage
| Stage Scope ID | Requirement ID | Spec ID | Acceptance Criteria |
| --- | --- | --- | --- |
| P01-SI-001 | P01-FR-001 | P01-SPEC-001 | AC-P01-001 |
| P01-SI-002 | P01-FR-004 | P01-SPEC-004 | AC-P01-004 |
| P01-SI-003 | P01-FR-002 | P01-SPEC-002 | AC-P01-002 |
| P01-SI-004 | P01-FR-003 | P01-SPEC-003 | AC-P01-003 |
| P01-SI-005 | P01-FR-005 | P01-SPEC-005 | AC-P01-005 |
| P01-SI-006 | P01-FR-008 | P01-SPEC-008 | AC-P01-009 |
| P01-SI-007 | P01-FR-006 | P01-SPEC-006 | AC-P01-006, AC-P01-007 |
| P01-SI-008 | P01-FR-007 | P01-SPEC-007 | AC-P01-008 |
| P01-SI-009 | P01-FR-009 | P01-SPEC-009 | AC-P01-010 |
| P01-SI-010 | P0.1 非目标边界 | P01-SPEC-011 | AC-P01-012 |
| P01-SI-011 | P01-FR-010 | P01-SPEC-010 | AC-P01-011 |
| P01-SI-007, P01-SI-008, P01-SI-011 | P01-FR-011 | P01-SPEC-012 | AC-P01-013 |
| P01-SI-001, P01-SI-002, P01-SI-004, P01-SI-011 | P01-FR-012 | P01-SPEC-013 | AC-P01-014 |
| P01-SI-009, P01-SI-011 | P01-FR-013 | P01-SPEC-014 | AC-P01-015 |
| P01-SI-001, P01-SI-003, P01-SI-004, P01-SI-010 | P01-FR-014 | P01-SPEC-015 | AC-P01-016 |
| P01-SI-007, P01-SI-008, P01-SI-011 | P01-FR-015 | P01-SPEC-016 | AC-P01-017 |
| P01-SI-002, P01-SI-005, P01-SI-006, P01-SI-008, P01-SI-010 | P01-FR-016 | P01-SPEC-017 | AC-P01-018 |
| P01-SI-007, P01-SI-008, P01-SI-009, P01-SI-011 | P01-FR-017 | P01-SPEC-018 | AC-P01-019 |

## AC-P01-001 官方场景入口
- 给定用户打开 `job_interview` 或 `onboarding_introduction` 的当前等级，当用户进入训练入口时，必须进入训练型 Agent session。
- 给定用户打开非 P0.1 官方场景或不存在的场景 id，当用户尝试进入 P0.1 训练时，系统不得创建训练 session，并必须显示不可用或回退提示。
- 给定用户已存在同场景同等级未完成训练 session，当再次进入时，系统必须恢复可继续的训练状态。

## AC-P01-002 Action chain
- 给定用户进入 P0.1 session，系统必须能识别当前 action chain step。
- 给定当前 step 是开场、说明目的、表达观点、回应追问、确认下一步或结束，页面必须只呈现该 step 相关的训练任务。
- 给定场景资产缺少显式 action chain 标注，系统必须使用本地映射继续训练，不得把缺失标注暴露为不可恢复失败。

## AC-P01-003 Micro-action 单步训练
- 给定 session 已 ready，用户一次只能看到或听到一个主要 micro-action。
- 给定 micro-action 为听一句、选一个、回一句、跟一句、补一句或追问继续说，系统必须展示对应用户动作和完成入口。
- 给定用户完成当前 micro-action，系统必须进入评估、反馈、重试、下一个动作或 recap 中的一个明确状态。

## AC-P01-004 Session planner 决策
- 给定用户最近一次作答失败，planner 必须选择重试、提高 hint level 或 model-then-retry 中的至少一种。
- 给定用户连续通过，planner 必须降低提示、升级任务或进入 pressure check 中的至少一种。
- 给定 ASR 失败，planner 不得直接判定用户表达失败，必须提供重录或文本兜底。
- 给定评分不可用，planner 不得阻断 session 继续。

## AC-P01-005 Hint ladder
- 给定用户在无提示下连续失败，系统必须提供句框、选项、chunk shadowing 或 model-then-retry。
- 给定用户在高支架下通过，系统必须在后续任务中尝试降低支架或进入轻量追问。
- 给定 hint level 变化，页面必须让用户可见当前提示或支架内容。

## AC-P01-006 语音主路径
- 给定当前 micro-action 需要口语作答，页面必须提供录音、取消、提交和重录能力。
- 给定用户提交有效录音，系统必须转写并进入评估。
- 给定用户取消录音，系统必须丢弃当前录音并回到可作答状态。
- 给定用户语音消息可播放，页面必须支持播放；播放失败时必须展示可恢复错误。

## AC-P01-007 文本兜底
- 给定麦克风权限被拒绝，页面必须提示授权或提供文本兜底入口。
- 给定 ASR 连续失败，页面必须允许重录或文本兜底。
- 给定文本兜底可用，页面必须明确其为兜底路径，不得替代默认语音主路径。

## AC-P01-008 即时反馈
- 给定用户提交有效回答，页面必须展示表达完成度、场景任务完成度、重试建议或更地道表达提示中的核心反馈。
- 给定回答命中目标表达，系统必须能进入通过、升级或 pressure check。
- 给定回答暴露薄弱点，系统必须能进入重试、提高提示或记录薄弱证据。
- 给定发音评分可用，页面必须展示发音相关反馈；不可用时不得阻断表达反馈。

## AC-P01-009 In-session pressure check
- 给定用户连续通过，系统必须减少提示并进入轻量追问或近场景复现。
- 给定用户在 pressure check 中通过，系统必须允许进入下一个 step 或 recap。
- 给定用户在 pressure check 中失败，系统必须允许回到更高 hint level 的重试。
- P0.1 pressure check 不得展示或承诺跨天调度、跨场景复现或完整 L0-L5。

## AC-P01-010 Learning evidence 写回
- 给定 session 结束，系统必须写回掌握、薄弱、复习、个人素材或下一步建议中的至少一种。
- 给定写回成功，学习证据必须能进入首页、推荐表达、个人 Wiki 或 session recap 中的至少一个后续入口。
- 给定写回失败，系统必须展示可恢复错误，且不得丢失用户可见 recap。
- 给定 LLM 生成反馈，LLM 不得直接写入最终持久化掌握状态。

## AC-P01-011 可恢复失败
- 给定场景、表达、历史证据或音频资源加载失败，页面必须展示可恢复错误。
- 给定 TTS、ASR、LLM 或评分服务失败，用户必须能重试、降级、退出 session 或查看已可用结果。
- 给定服务失败发生在 recap 前，系统不得进入无反馈的死状态。

## AC-P01-012 P0.1 范围边界
- P0.1 不得由 Flutter 新增第三个官方场景或任意场景；未来官方场景必须通过后端 scenario/version/mapping 审核链路进入。
- P0.1 不得承诺任意场景生成或用户自定义公开场景。
- P0.1 不得把跨 session、跨天、跨场景长期调度验收为已完成。
- P0.1 不得把完整 L0-L5 掌握阶梯、完整笔记本、完整评分产品化或商业权益 gating 作为完成条件。

## AC-P01-013 后端 AI Provider Gateway
- 给定后端配置 `speakeasy.ai.provider=deterministic`，系统必须继续使用 deterministic provider，并且本地/CI 测试不得依赖真实第三方服务。
- 给定后端配置 `speakeasy.ai.provider=dashscope` 且提供服务端 DashScope 配置，`/ai/transcribe`、`/ai/tts`、`/ai/coach-turn` 和 `/ai/feedback` 必须通过当前 Spring Boot 后端的 `AiProviderGateway` 调用 DashScope adapter，不得暴露 provider secret 给 Flutter。
- 给定 `/ai/transcribe` 收到空 `audio_ref`、客户端本地文件路径、未携带后端签名媒体元数据的 HTTP ref 或 provider 无结果，系统必须返回 schema/policy 错误、`no_result` 或 `provider_unavailable`，不得生成伪成功 transcript。
- 给定 `/ai/tts` 对相同 text/model/voice 重复请求，系统必须复用稳定 cache key，避免同一后端进程内重复 provider 调用；provider 失败时必须返回 `provider_unavailable`。
- 给定 `/ai/coach-turn` 或 `/ai/feedback` 收到 DashScope LLM 无效 JSON、超时或 schema 不合法，系统必须返回 recoverable fallback，且不得生成最终 mastery、entitlement、billing 或 review schedule。
- 给定任一 AI provider 调用，系统必须经过现有 usage reservation/commit/release 边界，并记录不含敏感原文的 provider/model/status/latency/fallback reason 观测信息。
- 给定 LLM、ASR、TTS 任一 provider 调用，系统必须记录或返回可审计的 usage metadata：usage family、provider、model、status、latency、fallback reason，以及适用时的 token estimate、audio duration 或 estimated cost bucket；不得把这些字段伪造为 live billing 精确账单。
- 给定用户处于 free、pro 或 enterprise 等不同 entitlement tier，provider policy 必须能基于后端事实选择允许的模型、调用频率、音频时长和文本长度；本轮如未实现高级模型差异，也必须以配置和测试证明 free/pro/enterprise 策略不会由 Flutter 决定。
- 给定 ASR 请求，系统必须限制或拒绝不满足后端 policy 的音频输入，包括空 ref、本地文件路径、超长 duration、超大媒体对象或过高频率调用；不满足 policy 时必须返回 typed failure 或 usage limit，而不是调用 provider。
- 给定账号删除、日志或错误上报路径，系统不得记录 raw audio、完整敏感 transcript、provider key 或 raw provider payload；audio/transcript retention 必须遵守 `docs/architecture/security_design.md`。

## AC-P01-014 后端 Training API 与服务端事实源
- 给定 OpenAPI 已声明 `/training/sessions...` endpoint，当后端尚未实现对应 controller/service/test 时，Product Base 合入和 production training release 必须标记为 blocked，不得显示为 ready。
- 给定后端实现 `POST /training/sessions`，当用户从两个官方场景进入训练时，后端必须创建或恢复归属当前 authenticated user 的 session，并返回当前 action step、micro-action、hint state 和 scenario version。
- 给定 `POST /training/sessions/{session_id}/turns` 使用相同 `Idempotency-Key` 重复提交，系统不得重复扣减用量、重复写 learning evidence 或推进多个 planner decision。
- 给定用户尝试读取或推进不属于自己的 training session，系统必须返回授权错误或 not found，不得泄露训练状态。
- 给定 `ENABLE_BACKEND_TRAINING` 关闭或后端 training 不可用，Flutter 必须关闭训练入口或显示服务不可用，不得创建本地 draft session、前端 planner decision、假 feedback 或 `pending_local_write` evidence。

## AC-P01-015 Learning evidence 写回、rule trace 与数据治理
- 给定训练 session 产生 learning evidence candidate，后端必须通过 deterministic rule 接受、拒绝或合并，并记录 source turn、rule name、reason code、schema version 和时间戳。
- 给定 evidence 写回失败，用户可见 recap 必须保留，session/evidence 状态必须标记为 retryable 或 failed-with-reason，不得伪装为 accepted evidence。
- 给定账号删除或 retention job 执行，P0.1 training session、turn、media ref、recap 和 evidence rule trace 必须被删除、匿名化或保留最小审计证明。
- 给定 LLM 输出包含 final mastery、billing、entitlement 或 review schedule 字段，系统必须拒绝作为 accepted evidence。

## AC-P01-016 版本化训练内容和 action chain 映射
- 给定 production training session 启动，当前 action chain 和 target expression 必须来自 `scenario_version_id` 对应的 reviewed mapping 或明确 reviewed fallback，不能只依赖未版本化 Flutter 常量。
- 给定内容映射缺失，系统必须返回可恢复错误或 reviewed fallback reason，不得让 LLM 即兴生成官方 training step。
- 给定场景内容版本更新，已创建 session 必须继续引用原 scenario version，历史 planner decision 和 evidence 含义不得被重写。
- 给定请求未发布、非官方或缺少 reviewed training mapping 的场景，系统必须 fail closed 并保留 P0.1 非目标边界；增加未来官方场景必须通过后端 scenario/version/mapping，而不是 Flutter allowlist。

## AC-P01-017 真实语音、media 和 AI pipeline
- 给定需要语音输入的 training turn，系统必须只接受后端可信 `audio_ref` 或 text fallback，不得把客户端本地文件路径当作 successful ASR 输入。
- 给定 ASR/TTS/LLM/provider timeout、invalid schema 或 no result，系统必须返回 typed recoverable state，并释放或记录 usage reservation，用户可继续重试、文本兜底或退出。
- 给定 pronunciation signal 不可用或低置信度，planner 不得仅因发音失败阻断 expression/task feedback。
- 给定生产模式打开，Flutter training UI 不得用固定假 feedback、固定假 transcript 或 local draft adapter 代表真实 provider/Training service 结果；deterministic fixture 只能存在于后端 test/dev provider 边界。

## AC-P01-018 Planner service 审计、配置和回放
- 给定任一 applied planner decision，系统必须持久化或输出可追踪 decision record：source turn、decision type、next micro-action、hint level、reason code、rule/schema version。
- 给定相同 session state、turn、AI candidate、score signal 和 rule version，planner replay 必须生成相同 decision。
- 给定 LLM recommended next action 不在 planner allowed-action set 中，系统必须拒绝该候选并记录 reason code，不得推进 session。
- 给定 hint ladder 或 pressure threshold 被调整，配置或 rule version 必须更新，旧 session replay 必须仍使用旧 rule version。

## AC-P01-019 训练运营指标、商业边界和 rollout gates
- 给定用户训练一次 session，系统必须产生脱敏 funnel/quality/evidence/provider 指标，至少覆盖 start/resume、turn submit、fallback、hint、pressure、recap、evidence 和 provider status。
- 给定日志或指标上报，系统不得包含 raw audio、完整敏感 transcript、provider key 或 raw provider payload。
- 给定 feature flag 或 kill switch 关闭 P0.1 training，用户必须看到可恢复降级或入口关闭状态，不得进入半可用训练页。
- 给定 paid AI voice strict evidence 未通过，P0.1 训练不得声明 paid AI voice ready；若训练能力进入付费权益，必须复用 P0 commercial entitlement/usage/release gates。
