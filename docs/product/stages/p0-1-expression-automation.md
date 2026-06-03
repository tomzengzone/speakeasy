# P0.1 阶段范围：表达自动化训练闭环

## 状态
Executed partial - P0.1 core Training Agent、本地 route integration 和 AI eval 已有执行证据；本阶段仍不是商业发布批准。2026-06-03 commercial software remediation 在同一 stage/increment 内新增 Product Base/production blocker `P01-GAP-009` through `P01-GAP-014`；P01-GAP-008 的真实 provider / object storage / paid AI release residual 由 `commercial-ai-provider-hardening` 和 P0 release gates 管理。

## 阶段目标
在当前 Product Base 稳定能力之上，把现有语音场景模拟升级为训练型 Agent：用户只完成听一句、选一个、回一句、跟一句、补一句、在追问下继续说等小动作；agent 在 session 内接管训练组织、节奏控制、难度拆解、重复推进、即时反馈和轻量场景施压。

## 阶段排序
- 本阶段是价值体验升级线，不是商业发布阻塞线。
- P0 商业化订阅上线准备负责生产账号、真实支付、服务端权益、商业 gating、合规、风控和发布门禁，排序高于本阶段。
- 本阶段可以在不混入商业发布承诺的前提下做规划或预研；真实收费上线不得跳过 P0 商业化订阅上线准备。

## 入口条件
- 当前稳定能力已记录在 `docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md` 和 `docs/product/base/traceability.md`。
- 稳定 feature 已登记在 `docs/product/feature_registry.md`。
- P0.1 change request 已 accepted：`docs/process/change_request.md`。
- legacy P0.1 spec 可作为迁移来源：`docs/product/features/mvp-learning-loop-spec.md`。

## 阶段范围
- 以 `job_interview` 和 `onboarding_introduction` 两个官方场景验证。
- 引入 session 内训练 planner。
- 引入 action chain 和 micro-action flow。
- 引入 hint ladder。
- 引入 in-session pressure check。
- 语音作为主路径，文本作为 ASR 失败、麦克风拒绝或调试兜底。
- 发音评分进入反馈，但不作为唯一通关条件。
- 每轮训练写回学习证据。

## Stage Scope Items
Current status 以 `p0-1-expression-automation-training/traceability.md`、`test_cases.md` 和 `docs/reports/test_report.md` 的最新证据为准；`local passed` 不等于商业发布 ready。2026-06-03 商业软件整改不新增 stage，而是在本 stage 的 `p0-1-expression-automation-training` increment 内追踪后端 Training API/source-of-truth、证据治理、内容版本、真实媒体/AI pipeline、planner 审计和 rollout gates。

| Stage Scope ID | Capability / obligation | Required status | Target increment | Current status |
| --- | --- | --- | --- | --- |
| P01-SI-001 | 以 `job_interview` 和 `onboarding_introduction` 两个官方场景验证 P0.1 训练 | required | `p0-1-expression-automation-training` | Implemented / local integration passed |
| P01-SI-002 | 引入 session 内训练 planner | required | `p0-1-expression-automation-training` | Core implemented / local integration passed |
| P01-SI-003 | 引入 action chain | required | `p0-1-expression-automation-training` | Core implemented / local tests passed |
| P01-SI-004 | 引入 micro-action flow | required | `p0-1-expression-automation-training` | Core implemented / local integration passed |
| P01-SI-005 | 引入 hint ladder | required | `p0-1-expression-automation-training` | Core implemented / local tests passed |
| P01-SI-006 | 引入 in-session pressure check | required | `p0-1-expression-automation-training` | Core implemented / local integration passed |
| P01-SI-007 | 语音作为主路径，文本作为 ASR 失败、麦克风拒绝或调试兜底 | required | `p0-1-expression-automation-training` | Core implemented / local tests passed；real provider release residual tracked by P0 paid AI gates |
| P01-SI-008 | 发音评分进入反馈，但不作为唯一通关条件 | required | `p0-1-expression-automation-training` | Core implemented / AI eval passed；real provider release residual tracked by P0 paid AI gates |
| P01-SI-009 | 每轮训练写回学习证据 | required | `p0-1-expression-automation-training` | Core implemented / local integration passed；server sync not required for local route |
| P01-SI-010 | P0.1 非目标边界守护：不把 P0.2/P1/P2 范围标记为 P0.1 完成 | required | `p0-1-expression-automation-training` | Boundary guard implemented / local integration passed |
| P01-SI-011 | 外部服务、音频、ASR、LLM、评分或写回失败时提供可恢复路径 | required | `p0-1-expression-automation-training` | Core implemented / AI eval passed；provider/storage release residual tracked by P0 paid AI gates |

## 阶段非目标
- 不新增第三个官方场景。
- 不承诺任意场景生成或用户自定义公开场景。
- 不实现完整 A1/A2/B1/B2/C1/C2 内容体系。
- 不实现跨 session、跨天、跨场景的长期训练调度。
- 不实现完整 L0-L5 掌握阶梯。
- 不把任意短语/单词查询和笔记本产品化放入 P0.1。
- 不把完整评分体系、学习报告或商业权益 gating 作为 P0.1 阻塞项。

## 纳入 increment
- `p0-1-expression-automation-training`：表达自动化训练 Agent 增量。

## 出口条件
- P0.1 increment definition、requirements、spec、acceptance、traceability 均存在或明确不适用。
- 必要的 domain/API/AI/UX contract 已完成或记录不适用原因。
- 实现计划、代码、测试、实现报告和质量报告能追踪到 P0.1 increment。
- 不把 P0.2/P1/P2 范围误标为 P0.1 完成。
