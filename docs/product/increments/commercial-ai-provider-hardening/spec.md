# Spec：商业 AI Provider 生产化加固

## 状态
Draft - 可作为 acceptance criteria 的直接上游输入；实现前仍需 API、architecture、security、QA 和 DevOps 契约。

## Product Object
- Increment：`commercial-ai-provider-hardening`
- Requirements：`docs/product/increments/commercial-ai-provider-hardening/requirements.md`
- Active stage：`docs/product/stages/p0-commercial-readiness.md`

## Spec Trace IDs
| Spec ID | Stage Scope ID | Requirement ID | Spec area |
| --- | --- | --- | --- |
| COM-AI-SPEC-001 | COM-SI-013 | FR-COM-AI-001 | Flow-AI-001, Flow-AI-002 |
| COM-AI-SPEC-002 | COM-SI-014 | FR-COM-AI-002 | Flow-AI-003 |
| COM-AI-SPEC-003 | COM-SI-015 | FR-COM-AI-003 | Flow-AI-004 |
| COM-AI-SPEC-004 | COM-SI-016 | FR-COM-AI-004 | Flow-AI-005 |
| COM-AI-SPEC-005 | COM-SI-017 | FR-COM-AI-005 | Flow-AI-006, Required States |

## Feature Goal
把 AI 语音 provider 能力从本地可测 adapter 升级为可控成本、可审计、可删除、可发布的生产能力。

## Core Flows

### Flow-AI-001 录音上传与可信 audio_ref
1. Flutter 完成录音。
2. Flutter 请求后端上传授权或直接上传音频到后端。
3. 后端校验用户、套餐、文件大小、格式和时长。
4. 后端写入 media metadata，并生成 provider 可访问的 signed media ref。
5. 后端返回客户端只可用于后续 AI REST 的 `audio_ref` 或 media id。

### Flow-AI-002 生产 ASR 调用
1. Flutter 调用 `/ai/transcribe`，提交后端签发的 `audio_ref`。
2. 后端解析 media metadata，校验 entitlement、usage、retention 状态和签名。
3. 后端调用 DashScope Paraformer。
4. 成功返回 transcript；失败返回 typed fallback。
5. usage/audit 只记录 media hash/ref，不记录完整 signed URL。

### Flow-AI-003 持久化 TTS 缓存
1. Flutter 或训练流程请求 TTS。
2. 后端按 normalized text hash、model、voice、language 计算 cache key。
3. 命中有效 cache 时返回已有 media ref。
4. 未命中时调用 DashScope TTS，保存音频到对象存储和 cache metadata。
5. 每次 cache 创建或命中都记录 user hash owner ref。
6. 账号删除移除对应 owner ref；没有剩余 owner 时删除或失效 cache entry。
7. retention job 或 cache expiry 删除 cache entry 时同时清理 owner refs。

### Flow-AI-004 DashScope sandbox / controlled live evidence
1. QA 准备脱敏文本、短音频、异常音频和不同格式样本。
2. 在受控环境运行 LLM、ASR、TTS 调用。
3. 记录 provider model、request id、latency、status、error code、token/audio units、estimated cost 和 fallback。
4. 结果写入外部 evidence ref，并由独立 reviewer 审查。

### Flow-AI-005 成本看板
1. 每次 provider call 产生 sanitized metric。
2. 后端按套餐、用户 hash、provider family、model、status 和 cache hit 聚合。
3. Ops/PM 查看日/周成本、预算消耗、异常用户、cache hit rate 和毛利风险。
4. 超预算或异常错误率触发 release/ops blocker。

### Flow-AI-006 数据保留和删除
1. retention policy 定义每类 AI 数据的保存期限和处理方式。
2. 账号删除 job 查找用户 audio refs、transcripts、TTS cache owner refs 和 provider-derived feedback。
3. 系统删除、匿名化或保留最小审计字段。
4. 删除失败进入 retry/manual ops，并记录脱敏证据。

## Required States
- media upload：pending、uploaded、validated、rejected、expired、deleted。
- TTS cache：miss、hit、stale、deleted、provider_unavailable。
- provider sandbox：planned、executed、failed、reviewed、approved、blocked。
- cost dashboard：normal、budget_warning、budget_exceeded、provider_anomaly。
- retention job：pending、running、completed、failed_retryable、failed_manual.

## Required Downstream Contracts
- API Contract：media upload/signing、AI media ref resolution、cost dashboard read、admin/provider evidence status。
- Domain Schema：MediaAsset、TtsCacheEntry、ProviderInvocationMetric、ProviderSandboxRun、RetentionPolicy。
- Security：object storage ACL、signed URL TTL、KMS/secret、hash-only audit、no raw transcript logs。
- AI Runtime：DashScope real-call eval cases and fallback mapping。
- DevOps：bucket lifecycle、budget alert、provider sandbox evidence refs、retention job schedule。

## Module Impact
- Flutter：录音完成后走 upload flow；不再把本地路径直接提交给真实 ASR。
- Backend：AI Gateway、media service、usage/audit、account deletion、ops dashboard。
- Storage：对象存储、CDN 或 media serving boundary。
- AI runtime：DashScope live evidence and compatibility matrix。
- Release：AI provider evidence, storage lifecycle and privacy deletion become release gates。

## Rollout Notes
- P0 可以先支持短音频和有限格式，优先保证可信边界和删除证据。
- P1 可以扩展高级成本分析、provider A/B、CDN 优化和更长音频。
- 没有 live evidence 和 media lifecycle 前，不得声明 P01-GAP-008 closed。
