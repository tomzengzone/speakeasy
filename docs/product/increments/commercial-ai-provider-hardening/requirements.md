# Requirements：商业 AI Provider 生产化加固

## 状态
Draft - P0 商业化发布阻塞增量需求；尚未实现。

## Product Object
- Increment：`commercial-ai-provider-hardening`
- Stage：`docs/product/stages/p0-commercial-readiness.md`
- Primary Capability ID：`CAP-PRACTICE`
- Primary Sub-capability ID：`CAP-PRACTICE-03`
- Affected Capability IDs：`CAP-COACH`、`CAP-TRAIN`、`CAP-COM`、`CAP-ACC`、`CAP-MEMORY`
- Affected Sub-capability IDs：`CAP-PRACTICE-01`、`CAP-COACH-02`、`CAP-COACH-03`、`CAP-COACH-04`、`CAP-TRAIN-02`、`CAP-COM-03`、`CAP-ACC-03`、`CAP-ACC-04`、`CAP-MEMORY-02`

## 上游来源
- `docs/product/increments/commercial-ai-provider-hardening/definition.md`
- `docs/process/change_request.md`：`CR-20260601-002 商业 AI Provider 生产化加固`
- P0.1 provider residual：`P01-GAP-008`

## Stage Scope Coverage
| Stage Scope ID | Requirement ID | Coverage status |
| --- | --- | --- |
| COM-SI-013 | FR-COM-AI-001 | Planned |
| COM-SI-014 | FR-COM-AI-002 | Planned |
| COM-SI-015 | FR-COM-AI-003 | Planned |
| COM-SI-016 | FR-COM-AI-004 | Planned |
| COM-SI-017 | FR-COM-AI-005 | Planned |

## 目标用户与业务目标
- 作为学习者，我希望录音识别和语音播放稳定、快速、失败可恢复。
- 作为付费用户，我希望 AI 语音能力在高峰、重试和跨设备场景下仍可用。
- 作为运营者，我希望知道每个套餐、用户和 AI 能力的成本与毛利。
- 作为发布负责人，我希望真实 provider、媒体存储、缓存和隐私删除都有证据，避免把 demo 能力误当生产能力。

## Assumptions
- 当前 DashScope adapter 已在本地 fake transport 边界通过，但没有真实 DashScope live evidence。
- 当前 ASR 只接受后端签名 `audio_ref`，还没有 Flutter upload-to-backend/object-storage 生产链路。
- 当前 TTS cache 是进程内缓存，不支持多实例、重启和对象存储复用。
- 当前 usage/audit 已避免落完整 signed audio URL，但生产 retention/deletion 仍未完整定义。

## Functional Requirements

### FR-COM-AI-001 对象存储上传链路
系统必须支持 Flutter 录音通过后端创建上传任务并上传到后端受控对象存储，当前实现方案采用阿里云 OSS private bucket + 后端预签名 URL；后端必须生成 provider 可访问、可审计、带可信元数据的 `audio_ref`，并阻止客户端提交裸 URL、本地路径、伪造 `object_ref` 或长期 OSS 凭据作为生产 ASR 输入。

### FR-COM-AI-002 持久化 TTS 媒体缓存
系统必须按 text hash、model、voice 和语言生成稳定 cache key，把 TTS 音频、元数据、过期时间和删除状态持久化，避免多实例或重启后重复调用 provider。

### FR-COM-AI-003 真实 DashScope sandbox / controlled live 测试
系统必须在受控环境执行 DashScope LLM、Paraformer ASR 和 TTS 的真实调用证据，记录延迟、错误码、费用、音频格式兼容性和 fallback 行为。

### FR-COM-AI-004 AI 成本看板
系统必须按套餐、用户、provider family、模型、调用状态、token/audio duration、cache hit 和 fallback reason 汇总成本、预算消耗和毛利风险。

### FR-COM-AI-005 生产级 AI 数据策略
系统必须定义并执行音频、转写、provider payload、TTS cache、日志和账号注销的保留、删除、匿名化、审计和外部证据规则。

## Non-goals
- 不改变 P0.1 训练 Agent 的产品范围。
- 不新增任意场景、A1-C2 内容体系或实时语音高级套餐。
- 不承诺 P1 级 BI、预测定价或 provider 自动竞价。

## Success Criteria
- 生产 ASR 输入只来自后端可信 media ref。
- TTS 重复文本在多实例/重启后仍能复用已生成音频，且可按策略删除。
- DashScope 三类能力有真实 provider evidence，不再只依赖 fake transport。
- PM/Ops 能看到 AI 成本、毛利风险和异常调用。
- 账号删除和 retention job 能处理音频、转写和 TTS cache，并留下脱敏审计证据。
