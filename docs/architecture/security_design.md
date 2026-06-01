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
- DashScope provider adapter 只能读取服务端环境变量或 secret manager 配置，Flutter request body 中出现 provider secret 必须被 schema validation 拒绝。
- `audio_ref` 必须是后端可访问且可审计的媒体引用；DashScope ASR 仅接受带后端签名媒体元数据的 HTTP media ref 或后续对象存储上传流程生成的等价 ref。本地设备路径、未签名 HTTP ref、过期 URL 或无法访问对象不得被记录为成功 ASR。
- Usage/audit 只能记录 hash/media id 等脱敏 source ref，不得持久化完整签名音频 URL、provider secret 或完整敏感 transcript。
- TTS cache key 可记录 text hash/model/voice，不得记录完整敏感文本作为 cache index 或日志字段。
- P0 paid AI voice 前必须把“后续对象存储上传流程”和“持久化 TTS cache”从 residual 变为可执行实现，并通过 `commercial-ai-provider-hardening` 的测试和独立审查。
- 成本看板只能使用 user hash、plan、provider family、model、status、duration/token estimate、cache hit 和 cost bucket，不得暴露原始用户内容。

## Data Retention And Deletion
| Data class | Direction |
| --- | --- |
| Audio files | 默认短期保留；完成转写/评分后按业务和合规需要删除或降采样保存引用 |
| Transcripts | 作为学习证据时保留必要片段；账号删除时删除或匿名化 |
| Payment audit | 按财务和商店争议要求保留最小审计字段 |
| Provider logs | 只保留 request_id、provider、latency、status、schema version，不保留敏感正文 |
| Learning evidence | 支持账号删除/匿名化；保留 rule trace 便于解释和测试 |

DashScope adapter retention rule:
- request/response raw payload 默认不落普通业务表；
- debugging 只允许使用脱敏 request_id、provider status、model、latency 和 fallback reason；
- 账号删除必须删除或匿名化用户音频引用、transcript 引用、provider-derived feedback 中的用户私有内容。

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

## P0 Commercial Security Gate

| Gate | Required control | Traceability |
| --- | --- | --- |
| Payment verification | Apple/Google transaction credentials are verified only on the backend; logs must not contain full receipts or provider tokens. | COM-SI-001, COM-SI-002, COM-SI-003 |
| Entitlement truth | `EntitlementSnapshot` is generated from backend facts; Flutter can only cache and refresh it. | COM-SI-001, COM-SI-007, COM-SI-008 |
| Usage and cost | AI/ASR/TTS/scoring calls require entitlement check and usage reservation before provider execution. | COM-SI-010 |
| AI media lifecycle | Production ASR uses backend/object-storage generated trusted `audio_ref`; local paths and unsigned URLs fail closed. | COM-SI-013 |
| Persistent TTS cache | TTS cache stores hash/model/voice/language metadata and object refs, supports expiry and account deletion hooks. | COM-SI-014 |
| Real AI provider evidence | DashScope LLM/ASR/TTS sandbox or controlled live evidence is required before paid AI voice release. | COM-SI-015 |
| AI cost dashboard | Provider cost, cache hit, budget and margin-risk metrics are visible to PM/Ops without sensitive payloads. | COM-SI-016 |
| AI retention/deletion | Audio, transcripts, provider payloads, cache refs and logs have explicit retention and deletion proof. | COM-SI-017 |
| Production identity | Release builds must fail or block when test login, placeholder social config, missing production API, or missing payment products are detected. | COM-SI-004, COM-SI-005, COM-SI-012 |
| Account deletion | Deletion must revoke sessions, clean or anonymize user-owned data, preserve minimum audit records, and surface failure/retry state. | COM-SI-006 |
| Commercial copy | Paid claims must map to `SubscriptionPlan` and `EntitlementRule`; unavailable benefits are hidden, downgraded, or marked unavailable. | COM-SI-009 |
| Release rollback | Paid gates and AI-heavy features can be disabled without reintroducing client-owned entitlement truth. | COM-SI-011, COM-SI-012 |

P0-COM-ARCH-001 security result: controls are defined at the architecture level. Provider sandbox evidence, store metadata, secrets, signing and symbols remain DevOps/release execution evidence, not architecture evidence.

## Open Security Questions
- Final deployment provider and secret manager.
- Final auth token lifetime and refresh model.
- Audio/transcript exact retention duration by jurisdiction；P0 owner is `commercial-ai-provider-hardening` / COM-SI-017.
- Whether a dedicated admin console is needed in P0 or can remain ops-only.
