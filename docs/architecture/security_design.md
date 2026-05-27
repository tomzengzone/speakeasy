# Security Design

## 状态
Proposed - whole-app architecture。本文聚焦安全、合规和发布风控边界，不替代隐私政策、法务条款或具体实现。

## Security Principles
- Provider credentials、payment secrets、webhook secrets 和 signing keys 只存在于后端或部署 secret manager。
- 客户端不保存支付权益最终事实；只保存可刷新的展示缓存。
- 所有高成本 AI/ASR/TTS/评分调用必须经过服务端 entitlement 和 usage control。
- LLM 输出不得直接修改持久化掌握状态、权益状态或账号生命周期。
- 日志、trace、错误上报不得包含 raw audio、完整敏感对话、provider keys、payment credentials 或完整 token。

## Sensitive Data Inventory
| Data | Risk | Required control |
| --- | --- | --- |
| Auth token / refresh token | 账号接管 | 短期 token、refresh 轮换、Flutter secure storage 迁移计划 |
| Audio recordings | 个人敏感数据 | 最短 retention、对象存储隔离、删除任务、日志不落原文 |
| Transcripts / coach feedback | 学习和个人表达隐私 | 脱敏日志、访问控制、删除/匿名化 |
| Payment identifiers / receipts | 财务和欺诈风险 | 后端校验、幂等、审计、不可在日志中完整输出 |
| Entitlement / usage ledger | 付费权益和成本风险 | 服务端事实源、审计、不可由客户端直接改 |
| Provider keys | 供应商滥用和成本风险 | secret manager、最小权限、轮换 |
| Account deletion jobs | 合规风险 | 状态机、审计、失败重试和人工运维路径 |

## Identity And Token Storage
- 当前 Flutter token/local store 只能作为 baseline；商业发布前需要安全存储策略。
- 后端必须支持 token refresh、logout、账号删除后 token 撤销。
- 测试手机号/demo login 不得进入生产构建；release gate 必须检查配置。
- Apple/WeChat 登录必须有后端回调或 token 校验，客户端 SDK 成功不等于生产身份可信。

## Payment And Entitlement Security
- Apple/Google purchase token 或 transaction id 必须提交后端校验。
- EntitlementSnapshot 由后端根据购买、续订、退款、宽限期、过期和撤销事件生成。
- 支付 verify、restore 和 webhook 需要 idempotency key 或 provider event id 去重。
- 退款、撤销和过期必须触发降级；客户端离线缓存不得长期绕过服务端状态。
- 商业文案和实际能力必须一致，未实现权益需要隐藏、降级或移除承诺。

## AI / Provider Security
- AI Gateway 统一处理 LLM、ASR、TTS 和评分 provider。
- Provider call 前必须检查 entitlement 和 usage reservation。
- Provider raw response 可作为受限审计数据保存，但不得传给 Flutter 或普通日志。
- Invalid schema、provider timeout、policy refusal 或成本超限必须返回 typed fallback。
- Prompt/schema 变更必须有 eval cases；schema validation failure 不能更新 learning evidence。

## Data Retention And Deletion
| Data class | Direction |
| --- | --- |
| Audio files | 默认短期保留；完成转写/评分后按业务和合规需要删除或降采样保存引用 |
| Transcripts | 作为学习证据时保留必要片段；账号删除时删除或匿名化 |
| Payment audit | 按财务和商店争议要求保留最小审计字段 |
| Provider logs | 只保留 request_id、provider、latency、status、schema version，不保留敏感正文 |
| Learning evidence | 支持账号删除/匿名化；保留 rule trace 便于解释和测试 |

## Abuse And Cost Controls
- Rate limit by user, device, IP risk class, entitlement status and provider family.
- Use quota reservation/commit/release for AI/ASR/TTS/scoring.
- Detect repeated invalid receipts, scripted login, excessive ASR/TTS calls and suspicious restore attempts.
- Paid release requires budget alerts and provider error-rate alerts.

## Observability Security
- Sentry/Flutter crash report 需要 before-send 或等价脱敏策略。
- Backend structured logs 使用 request_id、trace_id、user hash，不输出 token、receipt、raw audio。
- OpenTelemetry traces should propagate request context but not sensitive payload.
- Admin audit access must be role-gated and itself logged.

## Release Security Gates
- Production secrets present and test secrets absent.
- Payment products match store metadata and backend allowlist.
- Android Billing is either fully enabled and tested or clearly disabled in UI.
- Account deletion flow has backend job, local cleanup and user feedback.
- Privacy declaration covers audio, transcripts, AI provider processing, purchases and account deletion.
- Rollback plan can disable paid gates or AI-heavy features without corrupting entitlement state.

## Open Security Questions
- Final deployment provider and secret manager.
- Final auth token lifetime and refresh model.
- Audio/transcript exact retention duration by jurisdiction.
- Whether a dedicated admin console is needed in P0 or can remain ops-only.
