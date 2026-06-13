# P0 阶段范围：商业化订阅上线准备

## 状态
Executed partial / release-blocked（部分已执行 / 发布受阻） - P0 商业订阅、权益、账号、gating（门禁）、本地 QA 和发布门禁已有执行证据；真实商业发布仍被 native/social（原生/社交配置）、provider/store（提供方/商店）、privacy/support（隐私/支持）、release secret/signing/symbol/rollback（发布密钥/签名/符号表/回滚）和 paid AI external evidence（付费 AI 外部证据）阻断。当目标是商业发布或真实收费准备时，本阶段优先级高于 P0.1 训练体验升级。

## 阶段目标
在不改变 P0.1 表达自动化训练闭环产品目标的前提下，补齐真实商业订阅 APP 上线前必须具备的账号、支付、权益、AI provider（AI 提供方）生产化、合规、风控和发布门禁能力。该阶段回答的问题不是“用户为什么续费”，而是“APP 能不能安全、合规、可恢复、可控成本地向真实用户收费”。

## 阶段排序
- 本阶段是 P0 release-blocking stage（发布阻断阶段），位于 P0.1 价值体验升级之前。
- 本阶段不替代 P0.1 训练 Agent，但任何真实收费、商业发布或会员权益承诺上线前，必须先完成本阶段出口条件。
- P0.1 可以作为体验预研或后续价值升级线推进，但不得把 P0.1 完成误计为商业软件功能补齐完成。

## 入口条件
- 当前稳定能力已记录在 `docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md` 和 `docs/product/base/traceability.md`。
- 当前商业入口能力已登记在 `profile-membership` feature（功能）中。
- 商业化缺口已通过 Product Manager 审查进入 `CR-20260524-001` 和 `commercial-subscription-readiness` 增量。`docs/COMMERCIAL_LAUNCH_TODO.md` 仅作为历史输入，不作为后续商业化 scope（范围）的事实源。
- Product Manager 已完成商业化就绪审查，并接受 `CR-20260524-001 商业化订阅上线准备`。

## 阶段范围
- 订阅权益后端：Apple/Google 交易校验、权益持久化、续订、退款、宽限期、过期、恢复购买。
- Android 订阅：Google Play Billing 购买、恢复、purchase token 后端校验和权益同步。
- 生产账号体系：后端登录、用户状态、会员状态、token 刷新、测试登录关闭和发布门禁。
- 社交登录生产配置：微信 AppID、Universal Link、URL scheme、后端回调配置；Apple 登录开发者能力和签名配置。
- 账号生命周期：账号注销、云端学习数据删除或匿名化、本地学习数据清理、删除日志和用户反馈。
- 商业权益 gating：免费/付费边界、AI 用量和练习次数限制、付费权益解锁、降级和过期后的体验。
- 商业文案一致性：会员页、商店文案和实际能力一致；未实现能力不得作为付费承诺。
- 商业风控与成本控制：AI/ASR/TTS 速率限制、成本预算、滥用检测、支付和账号审计日志。
- 商业 AI provider 生产化：录音上传到可信 `audio_ref`、持久化 TTS 缓存、真实 DashScope sandbox / controlled live evidence、AI 成本看板和生产级音频/转写/provider payload 数据策略。
- 发布合规：隐私申报、订阅条款、商店审核材料、商业边界测试矩阵和发布回滚准备。

## Stage Scope Items（阶段范围项）
Current status（当前状态）以 `commercial-subscription-readiness/traceability.md`、`commercial-ai-provider-hardening/traceability.md`、对应 `test_cases.md` 和 `docs/reports/test_report.md` 的最新证据为准；本地通过、non-strict gate（非严格门禁）通过或 controlled-live evidence-prep（受控真实证据准备）不关闭 strict commercial / paid AI release blockers（严格商业 / 付费 AI 发布阻断项）。

| Stage Scope ID | Capability / obligation | Required status | Target increment | Current status |
| --- | --- | --- | --- | --- |
| COM-SI-001 | 服务端订阅权益事实：计划、状态、生效、过期、宽限期、退款、撤销和恢复购买 | required（必需） | `commercial-subscription-readiness` | Implemented / release-blocked by external provider evidence（已实现 / 受外部 provider 证据阻断发布） |
| COM-SI-002 | Apple 订阅购买、恢复、交易校验和状态同步 | required（必需） | `commercial-subscription-readiness` | Implemented local boundary / Apple sandbox evidence pending（已实现本地边界 / Apple sandbox 证据待补） |
| COM-SI-003 | Android 订阅：Google Play Billing、purchase token 校验和权益同步 | required（必需） | `commercial-subscription-readiness` | Implemented local boundary / Google Play internal evidence pending（已实现本地边界 / Google Play 内测证据待补） |
| COM-SI-004 | 生产账号体系、后端登录事实、token 和测试登录关闭 | required（必需） | `commercial-subscription-readiness` | Gate implemented / strict release blocked by production secrets and native config（门禁已实现 / 严格发布仍被生产密钥和原生配置阻断） |
| COM-SI-005 | 微信和 Apple 社交登录生产配置 | required（必需） | `commercial-subscription-readiness` | Gate implemented / native-social evidence blocked（门禁已实现 / 原生社交证据阻断） |
| COM-SI-006 | 账号注销、云端数据删除或匿名化、本地数据清理和审计日志 | required（必需） | `commercial-subscription-readiness` | Implemented / QA passed（已实现 / QA 通过） |
| COM-SI-007 | 商业权益 gating：免费/付费边界、用量限制、降级和过期体验 | required（必需） | `commercial-subscription-readiness` | Implemented / QA passed / release-blocked by external provider-store evidence（已实现 / QA 通过 / 受外部 provider-store 证据阻断发布） |
| COM-SI-008 | 官方场景库、场景入口和训练入口的会员权益 gating 一致性 | required（必需） | `commercial-subscription-readiness` | Implemented / QA passed（已实现 / QA 通过） |
| COM-SI-009 | 会员页、商店文案、隐私说明和真实能力一致 | required（必需） | `commercial-subscription-readiness` | Local copy passed / external store-privacy-support evidence blocked（本地文案通过 / 外部商店-隐私-支持证据阻断） |
| COM-SI-010 | AI/ASR/TTS/评分成本控制、速率限制、滥用检测和审计 | required（必需） | `commercial-subscription-readiness` | Implemented / QA passed for scoped usage reserve-commit-release（已实现 / 范围内用量 reserve-commit-release QA 通过）；production AI hardening split to COM-SI-013..017（生产 AI 加固拆分到 COM-SI-013..017） |
| COM-SI-011 | 商业边界测试矩阵覆盖购买、恢复、退款、过期、注销、弱网和额度耗尽 | required（必需） | `commercial-subscription-readiness` | Local E2E passed / Apple-Google provider evidence blocked（本地 E2E 通过 / Apple-Google provider 证据阻断） |
| COM-SI-012 | 发布合规、商店审核材料、release secrets、签名、符号表和回滚准备 | required（必需） | `commercial-subscription-readiness` | Gate implemented / strict release blocked（门禁已实现 / 严格发布受阻） |
| COM-SI-013 | 对象存储上传链路：Flutter 录音上传后由后端生成可信 provider-accessible `audio_ref` | required before paid AI voice（付费 AI 语音前必需） | `commercial-ai-provider-hardening` | Backend implemented / local tests passed（后端已实现 / 本地测试通过）；external storage evidence pending（外部存储证据待补） |
| COM-SI-014 | 持久化 TTS 媒体缓存：多实例、重启、对象存储/CDN 复用和删除策略 | required before paid AI scale（付费 AI 规模化前必需） | `commercial-ai-provider-hardening` | Backend implemented / local tests passed（后端已实现 / 本地测试通过）；external distribution evidence pending（外部分发证据待补） |
| COM-SI-015 | 真实 DashScope LLM/ASR/TTS sandbox 或 controlled live evidence | required before paid AI voice（付费 AI 语音前必需） | `commercial-ai-provider-hardening` | Controlled-live evidence-prep passed / strict external evidence pending（受控真实证据准备已通过 / 严格外部证据待补） |
| COM-SI-016 | AI 成本看板：按套餐、用户、provider、模型、cache hit 和状态统计成本与毛利风险 | required before paid AI scale（付费 AI 规模化前必需） | `commercial-ai-provider-hardening` | Backend implemented / local tests passed（后端已实现 / 本地测试通过）；production PM-Ops evidence pending（生产 PM-Ops 证据待补） |
| COM-SI-017 | 生产级 AI 数据策略：音频、转写、provider payload、TTS cache、日志、账号注销和保留删除证据 | required before paid AI voice（付费 AI 语音前必需） | `commercial-ai-provider-hardening` | Backend implemented / local tests passed（后端已实现 / 本地测试通过）；retention-storage external evidence pending（保留-存储外部证据待补） |

## 阶段非目标
- 不替代 P0.1 表达自动化训练闭环；训练 Agent 仍由 `p0-1-expression-automation-training` 管理。
- 不新增第三个官方场景，不扩展 A1-C2 内容体系。
- 不实现后台 CMS、公开社区、真人导师市场或课程市场。
- 不把离线内容包、成就系统、完整笔记本产品化作为 P0 商业上线阻塞项；若会员页继续承诺这些权益，则必须先完成或移除对应承诺。

## 纳入 increment
- `commercial-subscription-readiness`：商业化订阅上线准备增量。
- `commercial-ai-provider-hardening`：商业 AI Provider 生产化加固增量，承接 P0.1 DashScope adapter 的 release residual（发布遗留项）。

## 当前开发计划
- 订阅与权益闭环的详细 PM 阶段开发计划记录在 `docs/product/increments/commercial-subscription-readiness/definition.md` 的 `PM 阶段开发计划` 部分。
- AI provider 生产化的详细 PM 阶段开发计划记录在 `docs/product/increments/commercial-ai-provider-hardening/definition.md` 的 `PM 阶段开发计划` 部分。
- Domain Schema、API Contract、Architecture/Security、UX/Screen Spec 和 QA AC-to-TC 测试用例库已补齐；`test_cases.md` 已覆盖 `AC-COM-001` 到 `AC-COM-014`，并已有 2026-06-02/2026-06-03 的本地执行和 strict external blocker（严格外部阻断项）证据。
- 当前合法下一步不是回退到规划态，而是补齐商业发布和 paid AI voice（付费 AI 语音）的外部 evidence refs（证据引用）、native/social（原生/社交）配置、store/privacy/support（商店/隐私/支持）证据、release secrets/signing/symbol/rollback（发布密钥/签名/符号表/回滚）证据，并重跑 strict gates（严格门禁）。
- 商业发布 ready（就绪）不能由本地 E2E 或现有会员页/Apple IAP 前端雏形替代，必须有支付 provider（提供方）沙盒/内测、权益 gating（门禁）、账号删除、商业文案一致性、release checklist（发布清单）和回滚证据。
- Paid AI voice ready（付费 AI 语音就绪）不能由 fake transport（伪传输）、deterministic provider（确定性 provider）或进程内 TTS cache（缓存）替代，必须有对象存储媒体链路、持久化缓存、真实 DashScope evidence（证据）、成本看板和数据保留/删除证据。

## 出口条件
- 订阅权益以服务端为准，客户端不再把本地 `memberPlan` 作为付费状态唯一依据。
- Apple 和 Android 订阅购买、恢复、退款、过期、宽限期、账号切换均通过沙盒或内部测试验收。
- 免费/付费权益 gating（门禁）有明确规则、实现位置、失败兜底和测试证据。
- 生产登录、账号删除、隐私申报、商店元数据、发布密钥和 release workflow（发布工作流）均达到发布检查要求。
- 商业边界测试矩阵、实现报告、质量报告和 release checklist（发布清单）能追踪到本阶段。
- Domain Schema、API Contract、Architecture/Security、UX/Screen Spec、QA/Test Plan、DevOps/Release 门禁均完成并经独立 checker（检查器）复核。
- 真实 AI provider（AI 提供方）上线前，`COM-SI-013` 到 `COM-SI-017` 必须有实现、测试、外部 evidence（证据）、数据策略和质量审查证据；否则只能保留 deterministic/local provider（确定性/本地 provider）或关闭 paid AI voice（付费 AI 语音）。
