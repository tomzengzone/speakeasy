# MVP System E2E 测试用例与结果下发版

## 结论
本次已建立并跑通本地电脑端系统 E2E gate：

- Flutter macOS 前端真实启动。
- Spring Boot 后端真实启动。
- PostgreSQL 15.18 本地临时库真实启动并接入后端。
- TC-MVP-E2E-001 到 TC-MVP-E2E-010 均已有脚本、命令、执行结果和报告证据。
- TC-MVP-E2E-010 的真实支付 provider 保留 manual/external gate；本地自动化只覆盖会员边界 UI。

注意：这里的 100% 是“需求链路覆盖 100%”，不是“代码行覆盖 100%”或“线上零缺陷保证”。真实 LLM/ASR/TTS、真实支付 provider、真机音频权限和第三方 SLA 仍是外部门禁。

## 核心文件
| 类型 | 文件 |
| --- | --- |
| E2E 增量定义 | `docs/product/increments/mvp-system-e2e-validation/definition.md` |
| E2E 需求 | `docs/product/increments/mvp-system-e2e-validation/requirements.md` |
| E2E 规格 | `docs/product/increments/mvp-system-e2e-validation/spec.md` |
| E2E 验收标准 | `docs/product/increments/mvp-system-e2e-validation/acceptance.md` |
| E2E 测试用例库 | `docs/product/increments/mvp-system-e2e-validation/test_cases.md` |
| E2E 追踪矩阵 | `docs/product/increments/mvp-system-e2e-validation/traceability.md` |
| 系统 E2E 启动脚本 | `scripts/run_mvp_system_e2e.sh` |
| 覆盖审计脚本 | `scripts/check_mvp_system_e2e_coverage.py` |
| Flutter E2E tests | `integration_test/` |
| 测试报告 | `docs/reports/test_report.md` |
| 实现报告 | `docs/reports/implementation_report.md` |
| 质量审核报告 | `docs/reports/quality_report.md` |

## 测试用例总表
| TC ID | 范围 | 自动化状态 | 结果 | 说明 |
| --- | --- | --- | --- | --- |
| TC-MVP-E2E-001 | 真实 PostgreSQL + 后端 + Flutter orchestration | automated | passed 2026-05-29 | 启动本地临时 PostgreSQL、后端，等待 `/v1/admin/release-health`，再跑 Flutter。 |
| TC-MVP-E2E-002 | 登录 gate + 测试手机号登录 | automated | passed 2026-05-29 | 从 Flutter UI 进入登录页，勾选协议，走测试手机号登录，后端签发会话。 |
| TC-MVP-E2E-003 | 首评 onboarding + 首页学习场景 | automated | passed 2026-05-29 | 选择“英语面试/不会表达/只能蹦关键词”，完成首评并进入首页。 |
| TC-MVP-E2E-004 | Product Base AC 覆盖矩阵审计 | automated | passed 2026-05-29 | 审计 AC-001 到 AC-013 是否全部有系统测试覆盖或例外说明。 |
| TC-MVP-E2E-005 | 测试证据字段审计 | automated | passed 2026-05-29 | 审计每条 TC 是否有脚本路径、命令、结果和报告证据。 |
| TC-MVP-E2E-006 | 场景目录 / 加入场景 / 听力热身 | automated | passed 2026-05-29 | 打开场景目录，进入 `job_interview`，加入场景并到达听力热身路径。 |
| TC-MVP-E2E-007 | 推荐表达 / 收藏 / 学习记忆 | automated | passed 2026-05-29 | 推荐表达出现、收藏动作生效，并在 Profile/Favorites 侧验证记忆持久化。 |
| TC-MVP-E2E-008 | 语音模拟 / 教练反馈 / 复盘证据 | automated | passed 2026-05-29 | 使用 deterministic provider，断言练习、教练反馈、provider status、复盘字段和 evidence candidates。 |
| TC-MVP-E2E-009 | Profile / settings / session persistence | automated | passed 2026-05-29 | 编辑 Profile、切换 settings、logout/relogin，并验证 session 与昵称持久化。 |
| TC-MVP-E2E-010 | 会员边界 UI / 支付外部例外 | automated / accepted-exception | passed 2026-05-29 / accepted-exception | 自动化覆盖会员 UI、计划、订阅/恢复边界；真实支付 provider 保留外部手工门禁。 |

## 已执行命令与结果
| 命令 | 结果 |
| --- | --- |
| `scripts/run_mvp_system_e2e.sh` | passed |
| `scripts/run_mvp_system_e2e.sh --suite scene-catalog` | passed |
| `scripts/run_mvp_system_e2e.sh --suite learning-memory` | passed |
| `scripts/run_mvp_system_e2e.sh --suite practice-feedback` | passed |
| `scripts/run_mvp_system_e2e.sh --suite profile-settings` | passed |
| `scripts/run_mvp_system_e2e.sh --suite membership-boundary` | passed |
| `python3 scripts/check_mvp_system_e2e_coverage.py` | passed：10 TC rows, 13 Product Base AC rows, 4 traceability rows |
| `flutter test` | passed：173 tests |
| `env JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` | passed |
| `python3 scripts/project_agent_runner.py validate` | passed |
| `git diff --check` | passed |

## 证据日志
| TC | 日志目录 |
| --- | --- |
| smoke / TC-MVP-E2E-001..003 | `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-97338` |
| TC-MVP-E2E-006 | `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-98620` |
| TC-MVP-E2E-007 | `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-99913` |
| TC-MVP-E2E-008 | `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-1490` |
| TC-MVP-E2E-009 | `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-2774` |
| TC-MVP-E2E-010 | `/var/folders/zx/k9k7_6k552sgfsc2sgxjr3pr0000gn/T/speakeasy-mvp-system-e2e-4371` |

## 本次 E2E 发现并已修复的问题
| 问题 | 处理 |
| --- | --- |
| 无 Docker daemon 时真实 PostgreSQL 测试会跳过 | 改为本机 PostgreSQL 工具链，不依赖 Docker。 |
| onboarding 状态通过 `/user/me` patch 无法持久化 | 改为提交 `/onboarding/assessment`，并修正 profile patch 字段映射。 |
| `updateMe` 使用 PUT 且 nickname 字段不匹配后端 | 改为 PATCH，并映射为 `display_name`。 |
| E2E helper 曾用 session shortcut 完成 onboarding，削弱 UI 黑盒证据 | 改为真实点击 onboarding UI 并复跑 smoke、TC-006 到 TC-010。 |
| 多个 UI 控件缺少可点击面的稳定 key | 给场景、听力、Profile/settings、收藏、会员等路径补 key。 |
| Flutter integration test 全局错误 hook 警告 | E2E 脚本增加 `SPEAKEASY_DISABLE_GLOBAL_ERROR_HOOKS=true`。 |

## 剩余风险
| 风险 | 状态 |
| --- | --- |
| `/user/stats` 在 E2E 中仍会记录非阻断失败 | 已记录，后续 stats/client 兼容性清理。 |
| macOS notification 初始化在本地 E2E 中软失败 | 已记录，不阻断当前系统路径。 |
| TC-MVP-E2E-008 不依赖真实 LLM/语音服务随机返回 | 符合 deterministic provider 要求；真实 provider 另走外部门禁。 |
| TC-MVP-E2E-010 真实支付 provider | 本地只自动化 UI 边界；真实支付保留 manual/external gate。 |

## 审核判断
当前可以接受的结论：

- 前端系统测试可以在电脑端执行，且已接入真实后端和真实 PostgreSQL。
- TC-MVP-E2E-006 到 TC-MVP-E2E-010 已从 backlog 转为执行通过证据。
- MVP 需求链路已有 100% 可追溯覆盖。
- 真实支付 provider 和真实第三方语音/LLM 质量不被本地自动化冒充通过，继续作为外部门禁追踪。
