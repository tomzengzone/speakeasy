# P0 阶段范围：商业化订阅上线准备

## 状态
Draft - Product Manager 已接受为付费上线阻塞阶段。

## 阶段目标
在不改变 P0.1 表达自动化训练闭环产品目标的前提下，补齐真实商业订阅 APP 上线前必须具备的账号、支付、权益、合规、风控和发布门禁能力。该阶段回答的问题不是“用户为什么续费”，而是“APP 能不能安全、合规、可恢复地向真实用户收费”。

## 入口条件
- 当前稳定能力已记录在 `docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md` 和 `docs/product/base/traceability.md`。
- 当前商业入口能力已登记在 `profile-membership` feature 中。
- 商业化缺口已通过 Product Manager 审查进入 `CR-20260524-001` 和 `commercial-subscription-readiness` 增量。`docs/COMMERCIAL_LAUNCH_TODO.md` 仅作为历史输入，不作为后续商业化 scope 的事实源。
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
- 发布合规：隐私申报、订阅条款、商店审核材料、商业边界测试矩阵和发布回滚准备。

## Stage Scope Items
| Stage Scope ID | Capability / obligation | Required status | Target increment | Current status |
| --- | --- | --- | --- | --- |
| COM-SI-001 | 服务端订阅权益事实：计划、状态、生效、过期、宽限期、退款、撤销和恢复购买 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-002 | Apple 订阅购买、恢复、交易校验和状态同步 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-003 | Android 订阅：Google Play Billing、purchase token 校验和权益同步 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-004 | 生产账号体系、后端登录事实、token 和测试登录关闭 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-005 | 微信和 Apple 社交登录生产配置 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-006 | 账号注销、云端数据删除或匿名化、本地数据清理和审计日志 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-007 | 商业权益 gating：免费/付费边界、用量限制、降级和过期体验 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-008 | 官方场景库、场景入口和训练入口的会员权益 gating 一致性 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-009 | 会员页、商店文案、隐私说明和真实能力一致 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-010 | AI/ASR/TTS/评分成本控制、速率限制、滥用检测和审计 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-011 | 商业边界测试矩阵覆盖购买、恢复、退款、过期、注销、弱网和额度耗尽 | required | `commercial-subscription-readiness` | Planned |
| COM-SI-012 | 发布合规、商店审核材料、release secrets、签名、符号表和回滚准备 | required | `commercial-subscription-readiness` | Planned |

## 阶段非目标
- 不替代 P0.1 表达自动化训练闭环；训练 Agent 仍由 `p0-1-expression-automation-training` 管理。
- 不新增第三个官方场景，不扩展 A1-C2 内容体系。
- 不实现后台 CMS、公开社区、真人导师市场或课程市场。
- 不把离线内容包、成就系统、完整笔记本产品化作为 P0 商业上线阻塞项；若会员页继续承诺这些权益，则必须先完成或移除对应承诺。

## 纳入 increment
- `commercial-subscription-readiness`：商业化订阅上线准备增量。

## 出口条件
- 订阅权益以服务端为准，客户端不再把本地 `memberPlan` 作为付费状态唯一依据。
- Apple 和 Android 订阅购买、恢复、退款、过期、宽限期、账号切换均通过沙盒或内部测试验收。
- 免费/付费权益 gating 有明确规则、实现位置、失败兜底和测试证据。
- 生产登录、账号删除、隐私申报、商店元数据、发布密钥和 release workflow 均达到发布检查要求。
- 商业边界测试矩阵、实现报告、质量报告和 release checklist 能追踪到本阶段。
- Domain Schema、API Contract、Architecture/Security、UX/Screen Spec、QA/Test Plan、DevOps/Release 门禁均完成并经独立 checker 复核。
