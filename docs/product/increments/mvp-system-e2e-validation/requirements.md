# MVP System E2E Validation Requirements

## 状态
Validated for local MVP system E2E gate - derived from Product Base acceptance and MVP backend QA release gap hardening。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-29 | Draft | 建立系统 E2E 验证需求 ID。 |
| v1.0 | 2026-05-29 | Validated | FR-001 到 FR-004 的 smoke gate 和覆盖审计已执行通过；深度系统回归继续作为 planned backlog。 |
| v1.1 | 2026-05-29 | Validated | TC-MVP-E2E-006 到 TC-MVP-E2E-010 已执行通过；真实支付 provider 保留 external/manual gate。 |

## Owner
Requirement Development Agent

## Requirement Coverage
| Requirement ID | Stage Scope ID | Requirement |
| --- | --- | --- |
| MVP-E2E-FR-001 | MVP-SI-014 | 本地测试环境必须能以可复跑脚本启动真实 PostgreSQL、Spring Boot 后端和 Flutter integration test，并在无 Docker 时仍可使用本机 PostgreSQL 工具链。 |
| MVP-E2E-FR-002 | MVP-SI-014 | 系统测试必须从 Flutter UI 入口验证登录 gate、测试手机号登录、首评 onboarding、首页学习路径展示和后端 PostgreSQL 持久化的核心贯通链路。 |
| MVP-E2E-FR-003 | MVP-SI-014 | 测试用例库必须把 Product Base AC-001 到 AC-013 全部映射到已执行自动化、手工限制或外部依赖例外，禁止无说明空白覆盖。 |
| MVP-E2E-FR-004 | MVP-SI-014 | 每条系统测试必须记录脚本路径、命令、结果、证据报告和失败时可定位的问题类别，便于后续 CI 或本地回归复跑。 |

## Success Criteria
- SC-MVP-E2E-001：`scripts/run_mvp_system_e2e.sh` 能启动本地 PostgreSQL 和后端，并将 Flutter test 指向 `http://127.0.0.1:<port>/v1`。
- SC-MVP-E2E-002：测试手机号登录只在 `ENABLE_TEST_PHONE_LOGIN=true` 的测试构建中出现。
- SC-MVP-E2E-003：Flutter integration test 断言登录页、手机号登录页、首评步骤、首页核心学习内容、场景目录/听力热身、学习记忆、练习反馈、Profile/settings/session 和会员边界 UI。
- SC-MVP-E2E-004：用例库中 Product Base AC-001 到 AC-013 覆盖率为 100%，其中无法本地自动化的外部项必须标记 accepted-exception 或 manual-external。
- SC-MVP-E2E-005：测试报告记录执行日期、命令、结果、环境限制和剩余外部门禁。

## Non-goals
- 不追求代码行覆盖率 100%。
- 不承诺自动化能证明没有缺陷；本增量的 100% 指需求链路覆盖完整。
- 不用 H2 替代系统级 PostgreSQL 验证。

## Downstream Artifacts
- `docs/product/increments/mvp-system-e2e-validation/spec.md`
- `docs/product/increments/mvp-system-e2e-validation/acceptance.md`
- `docs/product/increments/mvp-system-e2e-validation/test_cases.md`
- `docs/product/increments/mvp-system-e2e-validation/traceability.md`
