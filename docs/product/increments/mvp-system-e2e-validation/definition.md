# MVP System E2E Validation Definition

## 状态
Validated for local MVP system E2E gate - 已建立并跑通 MVP 本地系统级黑盒验证能力，不改变产品功能范围。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-29 | Draft | 新增电脑端前端 + 后端 + 真实 PostgreSQL 系统测试验证增量。 |
| v1.0 | 2026-05-29 | Validated | 本地真实 PostgreSQL + Spring Boot + Flutter macOS smoke gate 通过，覆盖审计通过。 |
| v1.1 | 2026-05-29 | Validated | TC-MVP-E2E-006 到 TC-MVP-E2E-010 深度系统回归通过；真实支付 provider 保留 external/manual gate。 |

## Owner
QA / Development Orchestrator

## Problem
当前 MVP 已有后端迁移、MockMvc、contract、Flutter unit/widget 测试，但这些测试不能证明真实用户路径已经在同一台电脑上贯通 Flutter UI、Spring Boot API 和 PostgreSQL 持久化。人工在手机端逐条回归成本高，也容易漏掉跨层问题，例如：

- Flutter `API_BASE_URL`、鉴权 token、字段命名和后端真实响应不一致。
- Flyway/Liquibase 或 schema 初始化在 H2 通过但 PostgreSQL 失败。
- 登录、首评、首页学习路径在单层测试通过，但真实异步网络和本地存储组合失败。
- QA 报告声称覆盖，但缺少可复跑脚本、命令和证据文件。

## Scope
本增量只建立系统级验证能力，覆盖 MVP 当前可自动化的核心链路：

- 本地启动真实 PostgreSQL。
- 本地启动 Spring Boot 后端并连接该 PostgreSQL。
- 使用 Flutter integration test 在 macOS 桌面端驱动真实 App UI。
- 将 Product Base AC-001 到 AC-013 映射到系统测试用例或明确例外。
- 输出命令、结果、证据路径和残余风险。

## Out Of Scope
- 不引入真实支付扣款。
- 不替代 App Store / TestFlight / 真机语音权限验收。
- 不把真实第三方 ASR、TTS、LLM provider 稳定性纳入本地必过 gate。
- 不改变生产业务逻辑或数据库 schema。

## Completion Signal
本增量只有在以下条件全部满足时才能从 Draft 进入 Validated：

- 每条系统 E2E test case 都包含 Stage Scope ID、FR、Spec、AC、Traceability Row、Gap、测试层级、自动化状态、脚本路径、执行命令、结果状态和证据报告。
- 每条 MVP 系统 E2E AC 都有 test case 或明确例外。
- Product Base AC-001 到 AC-013 在系统级测试库中都有执行覆盖或外部例外说明。
- 本地系统 smoke 和深度回归测试可运行到 Flutter UI + backend + PostgreSQL。
