# ADR 0002: Whole-App Architecture Stack

## Status
Proposed - pending document traceability and Product Object Governance checks.

提议中 - 等待文档追踪和 Product Object Governance 检查通过。

## Context
SpeakEasy 当前 Flutter APP 已有稳定学习闭环、语音能力、LLM 教练反馈、基础评分、个人 Wiki、会员页和 Apple IAP 前端雏形。P0 商业化需要可信订阅权益、支付校验、用量风控、账号生命周期、审计和发布门禁；P0.1 训练闭环需要确定性 session planner、结构化 AI runtime 和学习证据写回。纯客户端或仅本地状态无法满足这些边界。

## Decision
采用 Flutter client + modular backend + PostgreSQL + backend-owned AI/payment/security gateway 的 whole-app 架构。

Recommended baseline:

推荐基线：
- Frontend：继续 Flutter，保持 feature/application/service 分层。
- Backend：Spring Boot modular monolith，或同等强类型、可模块化、可观测的后端框架。
- Database：PostgreSQL 作为主数据库，migrations 管控 schema；JSONB 仅用于 provider raw payload、audit details 和低频扩展字段。
- Async/cache：Redis 或托管缓存；托管 queue/worker 处理支付 webhook、删除任务和高成本 provider 重试。
- API：OpenAPI-first，生成或校验 Dart client。
- Deployment：托管容器平台优先，保留迁移到 Kubernetes 的路径。
- Observability：Sentry for Flutter + backend structured logs + OpenTelemetry traces/metrics/logs。

## Alternatives
- Client-only/local-first：拒绝。无法可信处理订阅权益、退款、AI 成本控制、provider secrets、账号删除和审计。
- BaaS/functions-first：条件接受为早期原型，但商业化上线前需要明确域模型、幂等、审计、迁移和发布门禁。
- Microservices：暂缓。当前团队和产品阶段更需要清晰模块边界而不是多服务运维复杂度。
- FastAPI/Node/NestJS backend：可行替代，但必须满足 OpenAPI、模块边界、审计、观测、迁移和发布门禁。

## Consequences
- 支付、AI、账号删除和学习证据将有可信服务端边界。
- P0/P0.1 实现前必须补齐后端工程、数据库 schema、OpenAPI、AI schema 和测试矩阵。
- 模块化单体可以先降低运维复杂度，同时保留未来拆分 Commerce、AI Gateway 或 Training Planner 的路径。
- 初期建设成本高于仅改 Flutter，但能避免付费发布后的不可恢复事故。

## Risks
- 后端建设可能拖慢 P0/P0.1。Mitigation：先定义 P0/P0.1 最小 API family 和 schema，不一次性建设 P1/P2。
- Flutter 现有页面逻辑可能继续膨胀。Mitigation：训练 planner 和权益逻辑迁移到 application/domain/API 边界。
- 选型被误读为立即实现全部 future-stage。Mitigation：P0.2/P1/P2 在架构中仅保留扩展边界。

## Rollback
如团队决定先做更轻量后端，可保留 OpenAPI、PostgreSQL schema 和 bounded context 命名，把 Spring Boot implementation 替换为 FastAPI/Node/NestJS；不得回退到客户端拥有支付权益或 provider secrets。
