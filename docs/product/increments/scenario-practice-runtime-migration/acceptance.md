# 场景练习 Runtime 迁移验收标准

## 状态
架构设计已就绪。本文件定义后续实现必须满足的验收标准；本增量没有执行任何业务代码实现。

## 验收标准

### MIG-AC-001 前端-only 门禁
如果后续开始实现迁移，在审查变更文件时，除非另有跨层 increment 更新 Domain Schema、OpenAPI、后端、数据库、provider 和 traceability，否则变更必须限制在前端、runtime、测试和文档范围内。

### MIG-AC-002 当前主路径分类
开发者阅读架构文档并检查 `lib/features/interview/` 时，必须能明确看到该路径是 `FE-SCENARIO-PRACTICE` 的当前主流程和 legacy-compatible 物理路径。

### MIG-AC-003 Legacy sandbox 冻结
开发者准备新增场景练习功能并检查 SWC allocation 时，必须能明确看到 `lib/features/scenario/` 被标记为 legacy / non-main-flow，且禁止承接新功能扩展。

### MIG-AC-004 先共享 runtime
开发者准备新增可复用的语音、消息或 session 行为时，迁移方案必须要求先实现或复用 `FE-PRACTICE-RUNTIME`，不得先创建新的 scenario-practice feature package。

### MIG-AC-005 现有功能清单完整
审查迁移方案时，每个当前与练习相关的文件都必须有明确的现有职责和目标 SWC 分配。

### MIG-AC-006 目标分配完整
任何从 interview、scenario 或 application-scene 代码迁移出来的功能，在映射到目标 SWC 时，都必须包含 owner、non-owner、输入、输出、依赖、数据归属、API 使用和测试责任。

### MIG-AC-007 数据流覆盖完整
审查迁移方案时，核心用户流必须覆盖 session start/resume、内容加载、语音、ASR、文本 fallback、消息循环、TTS、hint、feedback/review、wiki/memory、history、exit/recovery、失败路径、幂等/重试、回滚/补偿、日志/指标、鉴权/隐私和 response-to-UI 映射。

### MIG-AC-008 领域逻辑隔离
runtime 抽取实现后，审查 interview/onboarding expression graph、mastery、wiki、queue、reviewed content 和 listening/shadowing 逻辑时，它们必须仍归属 `FE-SCENARIO-PRACTICE`，除非后续有已批准的领域迁移另行改变。

### MIG-AC-009 不允许重复 runtime
审查实现时，voice capture、message loop、TTS、feedback recording、session recovery、API client、audio platform、local cache 和 training boundary 均不得出现重复 SWC 或绕过边界的实现。

### MIG-AC-010 治理检查通过
架构规划完成后，Software Architecture Governance Check 必须返回 pass，或在编码开始前解决全部 blocker findings。

### MIG-AC-011 练习历史一致性决策
迁移实现开始后，审查 completed-session 和 feedback-history 行为时，必须通过共享 adapter 复用 `AppSession.recordPracticeSession`、`AppSession.upsertPracticeFeedback`、`SessionStatsCoordinator`、`StatsService` 和 `ApiClient`；如果 interview history parity 不纳入范围，必须明确记录为 non-goal，且不能产生静默数据丢失。
