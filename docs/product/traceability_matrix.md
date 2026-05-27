# MVP 强制追溯矩阵

## 文档状态
Legacy source - 本文是 MVP 阶段强制追溯矩阵的历史来源文件，已迁移到 Product Base 活需求库。

当前稳定追溯矩阵 source of truth：
- `docs/product/base/traceability.md`
- `docs/product/base/requirements.md`
- `docs/product/base/spec.md`
- `docs/product/base/acceptance.md`

本文只作为迁移来源、审计依据和历史参考保留。后续 increment 的 FR/AC/Spec Flow/Code Evidence/Test Evidence 链路不得继续写回本文；完成实现、验收、追溯、测试和报告后，应 merge back 到 `docs/product/base/traceability.md`。

## 目的

本文用于把当前 MVP 产品基线中的需求、用户故事、验收标准、实现证据和测试证据建立强制追溯关系。

“100% 覆盖”在本文中只表示需求覆盖完整性：每条已接受需求都有验收标准、实现证据和测试证据或明确例外说明。它不等于 100% 代码行覆盖，也不等于线上绝对无缺陷。

## 上游来源判定

当前 MVP 是由现有 Flutter 前端代码反向固化的阶段产物，因此 `docs/product/acceptance_criteria.md` 当前基于以下来源生成和校验：

1. 主需求文档：`docs/product/features/mvp-learning-loop-requirements.md`
2. MVP 边界：`docs/product/mvp_scope.md`
3. 用户故事：`docs/product/user_stories.md`
4. 当前前端代码、资产、存储、服务调用和已有测试证据

后续 P0 或新增功能进入标准 workflow 后，验收标准应以已批准的 feature specification 为直接输入，同时反向追溯到需求文档、用户故事和 MVP/P0 范围边界。没有 feature specification 的新增功能不得进入实现。

## 阶段约束

强制追溯矩阵必须在 acceptance criteria 阶段建立，最晚不得晚于 implementation plan 前。测试阶段只负责补齐和验证 Test Evidence，不负责事后定义需求覆盖关系。

P0 以后每个新增功能必须满足以下规则：

- 每个 FR 至少有 1 个 AC 覆盖。
- 每个 AC 必须反向引用 1 个或多个 FR。
- 每个 AC 必须有实现证据文件。
- 每个 AC 必须有测试证据，或者明确标记为“人工验收”、“外部服务依赖”或“暂不可自动化”。
- CI 或脚本检查矩阵中不得出现空的 FR、AC、Code Evidence、Test Evidence。
- Product Manager 不得仅凭口头说明把需求标记为完成；Development Orchestrator/QA 必须在后续阶段用测试、报告或明确例外补齐证据。

## 阶段职责

| 阶段 | 负责内容 | 完成判定 |
| --- | --- | --- |
| Requirement Development | 输出 FR、用户故事、需求边界 | FR 和用户故事可追溯 |
| Feature Specification | 输出可执行功能规格 | P0 新功能必须存在 spec |
| Acceptance Criteria | 输出 AC 并建立本矩阵 | FR、User Story、AC、Code Evidence、Test Evidence 不为空 |
| Test Case Generate | 把每个 AC 映射到测试用例或例外 | 每个 AC 有自动化测试计划或明确例外 |
| QA | 运行测试、记录失败和缺口 | `docs/reports/test_report.md` 或测试代码能反向引用 AC |
| Document Traceability Check | 完成前审查需求、AC、测试、报告是否断链 | 无未解释断链 |
| Definition of Done | 完成门禁 | 无未关闭或未记录例外的必填项 |

## 强制追溯矩阵

| FR | User Story | AC | Code Evidence | Test Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | 启动、登录与首评：未登录进入登录页；已登录新用户进入首评；已首评用户进入首页 | AC-001 启动与门禁 | `lib/main.dart`, `lib/core/bootstrap/app_bootstrapper.dart`, `lib/core/bootstrap/app_root.dart`, `lib/pages/login_page.dart`, `lib/pages/onboarding_page.dart`, `lib/pages/home_page.dart` | `test/core/bootstrap/app_bootstrapper_test.dart`; 人工验收：三种启动门禁页面状态 | MVP 已追溯；门禁 UI 仍建议补 widget/e2e 测试 |
| FR-001 | 启动、登录与首评：登录前同意条款；选择可用登录方式进入 App | AC-002 登录页 | `lib/pages/login_page.dart`, `lib/application/login/login_actions_coordinator.dart`, `lib/services/auth_service.dart`, `lib/services/apple_auth_service.dart`, `lib/services/wechat_auth_service.dart`, `lib/core/routing/app_router.dart` | `test/application/login_actions_coordinator_test.dart`, `test/services/auth_service_test.dart`; 外部服务依赖：微信、Apple、短信、邮箱后端 | MVP 已追溯；平台登录成功需外部环境验收 |
| FR-002 | 启动、登录与首评：完成首评生成第一条学习路线；日常服务不被误导为已可练完整场景 | AC-003 首评 | `lib/pages/onboarding_page.dart`, `lib/features/interview/interview_wiki_store.dart`, `lib/services/storage_service.dart`, `lib/models/storage_models.dart` | `test/models/interview_home_scene_selection_storage_model_test.dart`; 人工验收：四步首评阻止逻辑和场景写入映射 | MVP 已追溯；首评 UI 建议补 widget 测试 |
| FR-003 | 情景学习：首页三个主入口；查看两个官方场景；搜索、筛选、加入、移除、设为当前、切换等级 | AC-004 首页与官方场景 | `lib/models/app_models.dart`, `lib/pages/home_page.dart`, `assets/data/interview_scene_catalog.json`, `assets/data/interview_scene_wikis/job_interview.json`, `assets/data/interview_scene_wikis/onboarding_introduction.json`, `lib/features/interview/interview_wiki_store.dart` | `test/application/home_cards_coordinator_test.dart`, `test/models/interview_home_scene_selection_storage_model_test.dart`, `test/models/app_models_test.dart`; 人工验收：首页场景卡片 UI | MVP 已追溯 |
| FR-003, FR-005, FR-007, FR-009 | 情景学习：首页优先提示未完成会话、到期复习、薄弱表达或下一条表达 | AC-005 首页学习状态 | `lib/pages/home_page.dart`, `lib/features/interview/interview_wiki_store.dart`, `lib/features/interview/expression_daily_queue_coordinator.dart`, `lib/features/interview/interview_engine.dart` | `test/application/home_cards_coordinator_test.dart`, `test/features/interview/interview_spaced_review_test.dart`, `test/features/interview/expression_daily_queue_coordinator_test.dart`; 人工验收：首页综合状态展示 | MVP 已追溯 |
| FR-004 | 听力热身与推荐表达：播放完整场景对话；切句、暂停、循环；跟读候选人台词 | AC-006 听力热身 | `lib/features/interview/interview_scene_listening_page.dart`, `lib/features/interview/interview_scene_dialogue_builder.dart`, `lib/services/audio_service.dart`, `lib/services/api_client.dart`, `lib/services/app_session.dart` | `test/features/interview/interview_scene_dialogue_builder_test.dart`, `test/features/interview/expression_shadow_scoring_test.dart`; 外部服务依赖：ASR、TTS、发音评分；人工验收：播放和录音 UI | MVP 已追溯；听力页建议补 widget 测试 |
| FR-005, FR-006 | 听力热身与推荐表达：每日表达队列；完成小任务；收藏或取消收藏表达 | AC-007 推荐表达与收藏 | `lib/features/interview/expression_daily_queue_coordinator.dart`, `lib/features/interview/interview_expression_learning_page.dart`, `lib/features/interview/interview_wiki_store.dart`, `lib/pages/favorites_page.dart`, `lib/services/storage_service.dart` | `test/features/interview/expression_daily_queue_coordinator_test.dart`, `test/features/interview/expression_shadow_scoring_test.dart`, `test/features/interview/interview_spaced_review_test.dart`; 人工验收：收藏页可见、取消和去重 | MVP 已追溯；收藏页建议补 widget 测试 |
| FR-007 | 语音模拟与教练反馈：进入语音模拟；查看目标进度和场景导航；提示、录音、取消、提交、恢复未完成会话 | AC-008 场景模拟 | `lib/features/interview/interview_practice_page.dart`, `lib/features/interview/interview_engine.dart`, `lib/features/interview/interview_llm_scheduler.dart`, `lib/features/interview/expression_scene_orchestrator.dart`, `lib/application/scene/scene_voice_runtime_coordinator.dart`, `lib/application/scene/scene_voice_session_lifecycle_coordinator.dart` | `test/features/interview/interview_practice_page_widget_test.dart`, `test/features/interview/expression_scene_orchestrator_test.dart`, `test/application/scene_voice_runtime_coordinator_test.dart`, `test/application/scene_voice_session_lifecycle_coordinator_test.dart`, `test/application/scene_hint_coordinator_test.dart` | MVP 已追溯 |
| FR-008 | 语音模拟与教练反馈：提交回答后看到反馈、建议、下一题或错误；播放/翻译消息；查看发音和语法反馈 | AC-009 教练反馈与消息辅助 | `lib/features/interview/interview_practice_page.dart`, `lib/features/interview/interview_engine.dart`, `lib/features/interview/interview_llm_scheduler.dart`, `lib/application/scene/scene_conversation_coordinator.dart`, `lib/application/scene/scene_auxiliary_coordinator.dart`, `lib/application/scene/scene_voice_user_turn_coordinator.dart` | `test/features/interview/interview_practice_page_widget_test.dart`, `test/features/interview/interview_coach_schema_test.dart`, `test/application/scene_conversation_coordinator_test.dart`, `test/application/scene_auxiliary_coordinator_test.dart`, `test/application/scene_voice_user_turn_coordinator_test.dart`; 外部服务依赖：LLM、TTS、翻译、评分 | MVP 已追溯 |
| FR-009 | 复盘、复习与个人结果：一轮结束后看到总结；学习沉淀影响首页、推荐表达、个人 Wiki 或个人中心 | AC-010 复盘与学习沉淀 | `lib/features/interview/interview_practice_page.dart`, `lib/features/interview/interview_wiki_store.dart`, `lib/features/interview/interview_engine.dart`, `lib/application/session/session_stats_coordinator.dart`, `lib/application/session/session_lifecycle_coordinator.dart` | `test/features/interview/interview_practice_page_widget_test.dart`, `test/features/interview/interview_spaced_review_test.dart`, `test/application/session_stats_coordinator_test.dart`, `test/application/session_lifecycle_coordinator_test.dart`, `test/application/session_profile_coordinator_test.dart` | MVP 已追溯 |
| FR-010 | 我的与账号设置：查看学习概览、收藏、历史、报告入口；设置提醒、主题；退出或注销账号 | AC-011 个人中心与设置 | `lib/pages/profile_page.dart`, `lib/pages/learning_report_page.dart`, `lib/pages/edit_profile_page.dart`, `lib/models/learning_stats_model.dart`, `lib/application/profile/notification_preferences_coordinator.dart`, `lib/services/storage_service.dart` | `test/models/learning_stats_model_test.dart`, `test/application/notification_preferences_coordinator_test.dart`, `test/application/session_profile_coordinator_test.dart`, `test/application/session_lifecycle_coordinator_test.dart`; 人工验收：个人中心三页签和设置入口 | MVP 已追溯；Profile UI 建议补 widget 测试 |
| FR-011 | 我的与账号设置：查看会员方案、发起或恢复购买；查看占位页 | AC-012 会员与占位页 | `lib/pages/membership_page.dart`, `lib/services/apple_payment_service.dart`, `lib/services/android_payment_service.dart`, `lib/config/payment_config.dart`, `lib/pages/offline_content_page.dart`, `lib/pages/achievements_page.dart`, `lib/pages/feature_placeholder_page.dart` | 人工验收/外部服务依赖：Apple IAP 沙盒、Android 未接入提示、离线内容和成就占位页；暂不可完全自动化 | MVP 已追溯；支付闭环不作为前端 MVP 完成条件 |
| FR-002, FR-003, FR-006, FR-007, FR-011 | 全局边界：日常服务/工作沟通/旧课程页/通用场景/自动复习/后端全环境可用性不进入当前 MVP | AC-013 MVP 边界 | `lib/core/routing/app_router.dart`, `lib/core/routing/app_routes.dart`, `lib/pages/learning_page.dart`, `lib/pages/lesson_detail_page.dart`, `lib/features/scenario/scene_page.dart`, `docs/product/mvp_scope.md`, `docs/product/features/mvp-learning-loop-requirements.md` | 人工验收/静态检查：确认旧页面不在当前路由和首页主流程；确认收藏不被验收为自动复习；确认外部服务全环境可用性不作为 MVP 完成条件 | MVP 已追溯；建议 P0 补静态校验脚本 |

## 反向覆盖检查

| AC | 反向引用 FR | 结论 |
| --- | --- | --- |
| AC-001 | FR-001 | 已覆盖 |
| AC-002 | FR-001 | 已覆盖 |
| AC-003 | FR-002 | 已覆盖 |
| AC-004 | FR-003 | 已覆盖 |
| AC-005 | FR-003, FR-005, FR-007, FR-009 | 已覆盖 |
| AC-006 | FR-004 | 已覆盖 |
| AC-007 | FR-005, FR-006 | 已覆盖 |
| AC-008 | FR-007 | 已覆盖 |
| AC-009 | FR-008 | 已覆盖 |
| AC-010 | FR-009 | 已覆盖 |
| AC-011 | FR-010 | 已覆盖 |
| AC-012 | FR-011 | 已覆盖 |
| AC-013 | FR-002, FR-003, FR-006, FR-007, FR-011 | 已覆盖 |

## FR 覆盖检查

| FR | 覆盖 AC | 结论 |
| --- | --- | --- |
| FR-001 | AC-001, AC-002 | 已覆盖 |
| FR-002 | AC-003, AC-013 | 已覆盖 |
| FR-003 | AC-004, AC-005, AC-013 | 已覆盖 |
| FR-004 | AC-006 | 已覆盖 |
| FR-005 | AC-005, AC-007 | 已覆盖 |
| FR-006 | AC-007, AC-013 | 已覆盖 |
| FR-007 | AC-005, AC-008, AC-013 | 已覆盖 |
| FR-008 | AC-009 | 已覆盖 |
| FR-009 | AC-005, AC-010 | 已覆盖 |
| FR-010 | AC-011 | 已覆盖 |
| FR-011 | AC-012, AC-013 | 已覆盖 |

## 当前缺口

- 矩阵已补齐所有 FR、AC、Code Evidence、Test Evidence 字段，但 CI 或脚本校验尚未实现。
- 若要把“字段不得为空”变成机器门禁，需要由 Development Orchestrator 在后续执行阶段路由到 QA 或工程实现，新增脚本或 CI 检查。
- 标记为人工验收、外部服务依赖或暂不可自动化的项，不计为空缺，但必须在测试报告中记录实际验收结果或环境限制。
