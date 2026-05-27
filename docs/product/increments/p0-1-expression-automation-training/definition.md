# Increment Definition：P0.1 表达自动化训练 Agent

## 状态
Draft - active increment definition。

## Increment ID
`p0-1-expression-automation-training`

## Active Stage
`docs/product/stages/p0-1-expression-automation.md`

## Primary Feature
`expression-automation-training`

## Affected Features
- `voice-scenario-practice`
- `official-scenario-library`
- `listening-shadowing`
- `expression-practice-queue`
- `learning-memory-review`
- `scoring-feedback`

## 上游决策
- `docs/process/change_request.md`：`CR-20260523-001 表达自动化训练 Agent`
- `docs/product/baselines/current-mvp.md`
- `docs/product/feature_registry.md`
- `docs/product/features/mvp-learning-loop-spec.md`：legacy P0.1 spec source，已作为本 increment requirements/spec/acceptance/traceability 的迁移来源。

## Scope
- 在两个现有官方场景中，把现有语音场景模拟升级为训练型 Agent。
- 定义 action chain：开场、说明目的、表达观点、回应追问、确认下一步、结束。
- 定义 micro-action：听一句、选一个、回一句、跟一句、补一句、在追问下继续说。
- 定义 session 内训练 planner：选择当前动作、目标表达、提示等级、重试、降级、升级和轻量施压。
- 定义 hint ladder：无提示、句框、选项、chunk shadowing、model-then-retry。
- 定义 in-session pressure check：连续通过后减少提示并进入轻量追问。
- 语音为主路径，文本为 ASR 失败、麦克风拒绝或调试兜底。
- 训练结束写回学习证据：掌握、薄弱、复习、个人素材、下一步建议。

## Non-goals
- 不新增第三个官方场景。
- 不实现任意场景生成。
- 不实现完整 A1-C2 内容体系。
- 不实现跨 session/跨天长期调度。
- 不实现完整 L0-L5 掌握阶梯。
- 不把笔记本、完整评分产品化或商业权益 gating 纳入 P0.1 阻塞范围。

## Required Artifacts
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/spec.md`
- `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- `docs/product/increments/p0-1-expression-automation-training/traceability.md`
- 必要时更新 `docs/domain/`、`docs/architecture/`、`docs/ai_runtime/`、`docs/ux/`
- 实现完成后更新 `docs/reports/implementation_report.md` 和质量/测试报告

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent，随后由 Product Manager Agent 复审整体产品一致性。
