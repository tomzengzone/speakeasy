# ADR 0006：商业 AI Provider 媒体、缓存、成本与保留删除边界

## 状态
Accepted for `P0-AI-ARCH-001`。

已接受，适用于 `P0-AI-ARCH-001`。

## Context
`commercial-ai-provider-hardening` 需要在 paid AI voice 前关闭对象存储上传、持久化 TTS cache、真实 DashScope evidence、成本看板和生产数据策略缺口。现有 fake transport、进程内 TTS cache 和本地路径式 ASR 证据不能证明生产可用性。

## Decision
- 生产录音先进入后端-owned `MediaAsset`，再生成可信 `audio_ref`；Flutter 不生成 provider-accessible URL，也不提交本地路径作为生产 ASR 输入。
- TTS cache 按 normalized text hash、model、voice、language 和 media ref 持久化；进程内缓存只能作为 dev/local 优化，不作为 paid AI scale 证据。
- DashScope sandbox / controlled live evidence 作为受限 ops evidence，不暴露 raw provider payload、provider secret、raw audio 或完整 transcript。
- 成本看板使用 user hash、plan、provider family、model、capability、status、cache hit、duration/token estimate、estimated cost、budget bucket 和 margin risk。
- AI retention job 必须覆盖音频、转写、provider payload ref、TTS cache 和账号删除联动，并记录 redacted evidence ref 与失败重试状态。

## Alternatives Considered
| Option | Decision | Reason |
| --- | --- | --- |
| Flutter 直传 DashScope 或提交本地路径 | Rejected | 暴露 provider 边界，无法审计 owner、duration、size、retention，也无法稳定支持 ASR。 |
| 继续使用进程内 TTS cache | Rejected for P0 production | 多实例、重启和 CDN/object storage 复用不可用，不能控制 paid AI 重复生成成本。 |
| 成本只看 provider 月账单 | Rejected | 无法按套餐、用户 hash、能力、cache hit 和异常状态判断毛利风险。 |
| 把 provider evidence 放在普通测试日志 | Rejected | 需要独立审查、脱敏 evidence ref 和 release gate 追踪。 |

## Consequences
- Backend 需要新增 media upload/signing、persistent cache metadata、cost metrics 和 retention job 实现。
- OpenAPI 需要包含 `Media` 和 `AI Ops` 实现级路径，Flutter 只消费 media upload/playback 边界。
- QA 必须保留真实 DashScope evidence 的脱敏记录；没有 approved evidence 时不得关闭 paid AI voice release gate。
- Security review 必须确认日志、API response、audit 和 retention evidence 不包含 raw sensitive payload。

## Traceability
- Stage Scope：`COM-SI-013` 到 `COM-SI-017`
- Increment：`commercial-ai-provider-hardening`
- Work package：`P0-AI-ARCH-001`
- Acceptance：`AC-COM-AI-001` 到 `AC-COM-AI-005`
- Test cases：`TC-COM-AI-001` 到 `TC-COM-AI-007`
