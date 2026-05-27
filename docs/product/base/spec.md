# Product Base Spec

## 状态
Accepted - 当前文件是 Product Base 的稳定产品规格，描述已接受稳定行为如何被用户触发、观察和验收。本文不是 baseline 快照，也不是 P0.1 increment spec。

## Owner
Feature Spec Generate Skill

## 上游输入
- Product Base requirements: `docs/product/base/requirements.md`
- MVP scope: `docs/product/mvp_scope.md`
- Legacy MVP requirements source: `docs/product/features/mvp-learning-loop-requirements.md`
- Feature registry: `docs/product/feature_registry.md`
- Current app evidence: existing Flutter pages, services, assets, local storage, and tests referenced in Product Base traceability.

## 明确排除
- 不从 `docs/product/features/mvp-learning-loop-spec.md` 迁移 P0.1 planned behavior。
- 不定义 `expression-automation-training` 的训练型 Agent、session planner、micro-action、hint ladder、action chain 或 pressure check。
- 不定义 API request/response schema、LLM prompt schema、数据库字段、UI 布局或代码实现。

## 规格目标
把当前已实现的官方职场场景学习闭环整理为可执行产品规格，使下游 acceptance、traceability、测试计划和后续 increment merge-back 都能引用同一个稳定行为源。

## 稳定用户流程

### Flow-001 启动与门禁
1. App 启动时展示初始化状态。
2. 初始化失败时展示可恢复错误和重试入口。
3. 未登录用户进入登录页。
4. 已登录但未完成首评的用户进入首评页。
5. 已登录且已完成首评的用户进入首页。

### Flow-002 登录
1. 用户选择微信、Apple、手机号验证码或邮箱入口。
2. 用户提交登录前必须勾选服务条款和隐私政策。
3. 手机号、验证码、邮箱、密码或注册昵称不符合输入要求时，页面展示校验提示。
4. 平台、网络或后端能力不可用时，页面展示错误提示。
5. 登录成功后进入首评或首页，取决于首评状态。

### Flow-003 首评与学习路线
1. 用户按步骤选择目标方向、表达卡点、当前输出水平和每日分钟数。
2. 缺少关键选择时，用户不能完成对应步骤。
3. 英语面试写入 `job_interview`。
4. 入职介绍写入 `onboarding_introduction`。
5. 工作沟通映射到 `onboarding_introduction`。
6. 日常服务只作为方向选项，不写入真实官方场景。
7. 每日分钟数只保存为偏好，不控制推荐队列长度。

### Flow-004 首页与官方场景
1. 首页底部只展示情景学习、推荐表达、我的三个主入口。
2. 情景学习页加载官方场景目录。
3. 当前官方场景只包括英语面试和入职介绍。
4. 用户可查看场景标题、简介、标签、目标等级、表达数量和进度。
5. 用户可搜索、筛选、加入、移除、设为当前场景并切换目标等级。
6. 首页根据学习状态展示当前或已加入场景、掌握进度、到期复习、薄弱表达、个人素材、未完成会话和下一步建议。

### Flow-005 听力热身
1. 用户从官方场景进入开始热身页。
2. 页面按当前场景和目标等级加载对话。
3. 用户可播放、暂停、上一句、下一句和循环播放。
4. 用户可切换听力模式和跟读模式。
5. 跟读模式支持录制候选人台词、语音识别、完整度反馈和可用时的发音评分。
6. 播放、录音、识别或评分失败时，页面展示可恢复错误。

### Flow-006 推荐表达与收藏
1. 已加入场景的用户进入推荐表达页后看到每日表达队列。
2. 未加入场景的用户看到空状态。
3. 队列基于到期复习、薄弱表达和表达变体生成，并做优先级排序和去重。
4. 用户可完成选择判断、听后复述、表达填空、意图回忆、接下一句、短语背诵、替换槽位、纠错复现、变体改写、流利挑战和跟读任务。
5. 任务完成后，表达进度、最佳得分、转写、复习时间或掌握关联更新。
6. 用户可收藏或取消收藏表达。
7. 收藏使用稳定 ID 去重，收藏页展示有效收藏并支持取消收藏。

### Flow-007 语音场景模拟
1. 用户从官方场景和目标等级进入场景模拟。
2. 页面以语音作答为主路径，支持点击说话、录音、取消、提交和转写提交。
3. 页面展示当前练习状态、目标进度和当前对话消息。
4. 用户可请求提示，提示次数和提示内容可见。
5. 用户可打开场景导航查看目标等级、表达列表、当前节点、掌握、准备、到期复习、薄弱和练习统计。
6. 用户可从场景导航跳转目标表达，或切换到其他目标等级。
7. 同一用户再次进入同一场景同一等级时，符合条件的未完成会话自动恢复。

### Flow-008 教练反馈与消息辅助
1. 用户提交有效回答后，页面展示用户消息。
2. 系统展示教练反馈、重试建议、表达建议、下一问题或可恢复错误中的至少一种。
3. 命中目标表达时，系统更新掌握反馈或掌握状态。
4. 暴露问题时，系统记录薄弱表达、错误模式或重试建议。
5. 教练消息支持播放；播放失败时展示错误。
6. 教练消息支持中文翻译；翻译失败时展示错误。
7. 用户语音消息支持播放；录音文件失效时展示错误。
8. 发音和语法评分可用时展示反馈；不可用时不阻塞主流程。

### Flow-009 复盘与学习沉淀
1. 一轮场景练习结束后展示练习总结。
2. 总结展示本轮学会、总掌握进度、遗忘曲线、薄弱标签或下轮重点。
3. 总结后清理已完成的活跃会话。
4. 系统写入掌握表达、复习时间、薄弱表达、错误模式、个人素材或下轮目标中的至少一种。
5. 写入结果影响后续首页、推荐表达队列、个人 Wiki 或个人中心。
6. 用户可在总结后开始下一轮练习。

### Flow-010 我的、学习结果与设置
1. 我的页展示资料、会员状态、练习数、连续天数和收藏数。
2. 概览页签展示学习统计空状态或统计数据、收藏摘要、技能分布和学习资产入口。
3. 历史页签展示学习历史空状态或练习记录，并支持查看详情和删除记录。
4. 设置页签提供编辑资料、会员、收藏、提醒、主题、隐私政策、服务条款、注销和退出登录入口。
5. 每日提醒开关和时间保存到本地通知设置。
6. 主题切换更新并保存应用主题。
7. 退出登录或注销后清理当前会话相关状态并回到登录门禁。

### Flow-011 会员、学习报告与占位页
1. 会员页展示当前计划、订阅方案、权益文案、购买按钮和恢复购买按钮。
2. iOS/macOS 用户可发起 Apple IAP 前端购买、恢复购买和订阅状态检查。
3. Android 用户看到订阅未接入提示。
4. 学习报告页调用学习画像能力；无数据时展示空状态。
5. 离线内容页和成就页只展示空状态或占位说明。

## 状态模型
| 状态域 | 稳定状态 | 说明 |
| --- | --- | --- |
| App 启动 | loading, failed, ready | 失败时必须可恢复。 |
| 用户门禁 | unauthenticated, authenticated-not-onboarded, authenticated-onboarded | 决定登录页、首评页或首页。 |
| 首评 | incomplete, complete | 缺少关键选择时保持 incomplete。 |
| 场景选择 | no-scene, scene-joined, current-scene-selected | 影响首页与练习入口。 |
| 场景等级 | L1, L2, L3 | 当前资产等级，不等同完整 CEFR A1-C2。 |
| 推荐表达 | empty, queued, in-progress, completed | 队列来自复习、薄弱和变体。 |
| 收藏 | not-favorited, favorited | 稳定 ID 去重。 |
| 语音会话 | idle, recording, submitting, feedback, recoverable-error, completed | 主路径为语音作答。 |
| 学习沉淀 | no-evidence, evidence-written, reflected-in-next-entry | 至少影响首页、推荐表达、个人 Wiki 或个人中心之一。 |
| 会员/占位 | available-entry, platform-limited, placeholder | 只承认当前前端入口和占位状态。 |

## 输入与输出
| 流程 | 用户输入 | 系统输出 |
| --- | --- | --- |
| 启动与门禁 | 启动 App、重试 | 加载、错误、登录页、首评页或首页。 |
| 登录 | 协议勾选、登录方式、账号信息 | 校验提示、登录错误或登录后门禁结果。 |
| 首评 | 目标方向、表达卡点、水平、每日分钟 | 学习路线、偏好和首评完成状态。 |
| 场景目录 | 搜索、筛选、加入、移除、设为当前、切换等级 | 场景列表、场景状态、首页学习状态。 |
| 听力热身 | 播放控制、跟读录音 | 对话播放状态、识别文本、完整度或评分反馈。 |
| 推荐表达 | 任务作答、收藏操作 | 队列进度、得分、复习时间、收藏状态。 |
| 语音模拟 | 提示请求、录音、提交、导航操作 | 用户消息、教练反馈、下一问题、错误、导航状态。 |
| 复盘 | 完成练习、开始下一轮 | 总结、学习证据、下一轮入口。 |
| 我的/设置 | 编辑资料、提醒、主题、退出/注销 | 保存状态、账号状态、学习结果入口。 |
| 会员/报告/占位 | 购买、恢复、查看报告或占位页 | 平台结果、空状态、占位说明或错误。 |

## 失败与降级路径
- 初始化失败必须显示重试入口。
- 登录方式因平台、网络或后端能力失败时，必须显示错误提示。
- 外部 AI、ASR、TTS、翻译、评分或学习报告能力不可用时，必须展示错误或降级状态，不得阻塞非依赖主流程。
- 录音文件失效时，必须提示错误。
- Android 订阅未接入时，必须显示未接入提示，不得验收为购买闭环。
- 离线内容和成就只允许占位或空状态，不得承诺完整业务。

## 模块影响
| 能力域 | 证据路径 |
| --- | --- |
| 启动与门禁 | `lib/main.dart`, `lib/core/bootstrap/app_bootstrapper.dart`, `lib/core/bootstrap/app_root.dart`, `lib/core/routing/app_router.dart`, `lib/core/routing/app_routes.dart` |
| 登录 | `lib/pages/login_page.dart`, `lib/application/login/login_actions_coordinator.dart`, `lib/application/session/session_lifecycle_coordinator.dart`, `lib/services/auth_service.dart`, `lib/services/apple_auth_service.dart`, `lib/services/wechat_auth_service.dart` |
| 首评 | `lib/pages/onboarding_page.dart`, `lib/application/session/session_profile_coordinator.dart`, `lib/services/storage_service.dart`, `lib/features/interview/interview_wiki_store.dart` |
| 首页与场景目录 | `lib/pages/home_page.dart`, `lib/application/home/home_cards_coordinator.dart`, `assets/data/interview_scene_catalog.json`, `assets/data/interview_scene_wikis/` |
| 听力热身 | `lib/features/interview/interview_scene_listening_page.dart`, `lib/features/interview/interview_scene_dialogue_builder.dart`, `lib/services/audio_service.dart` |
| 推荐表达 | `lib/features/interview/expression_daily_queue_coordinator.dart`, `lib/features/interview/interview_expression_learning_page.dart` |
| 收藏 | `lib/pages/favorites_page.dart`, `lib/services/storage_service.dart` |
| 语音模拟 | `lib/features/interview/interview_practice_page.dart`, `lib/features/interview/interview_engine.dart`, `lib/features/interview/interview_llm_scheduler.dart`, `lib/features/interview/expression_scene_orchestrator.dart`, `lib/application/scene/` |
| 学习沉淀 | `lib/features/interview/interview_wiki_store.dart`, `lib/application/session/`, `lib/models/learning_stats_model.dart` |
| 我的与设置 | `lib/pages/profile_page.dart`, `lib/pages/edit_profile_page.dart`, `lib/application/profile/notification_preferences_coordinator.dart` |
| 会员、报告、占位 | `lib/pages/membership_page.dart`, `lib/services/apple_payment_service.dart`, `lib/services/android_payment_service.dart`, `lib/pages/learning_report_page.dart`, `lib/pages/offline_content_page.dart`, `lib/pages/achievements_page.dart` |

## Requirement Mapping
| Requirement | Spec flows |
| --- | --- |
| FR-001 | Flow-001, Flow-002 |
| FR-002 | Flow-003 |
| FR-003 | Flow-004 |
| FR-004 | Flow-005 |
| FR-005 | Flow-006 |
| FR-006 | Flow-006 |
| FR-007 | Flow-007 |
| FR-008 | Flow-008 |
| FR-009 | Flow-009 |
| FR-010 | Flow-010 |
| FR-011 | Flow-011 |

## Acceptance Coverage Expectations
- 每个 Flow 必须至少有一个可观察 acceptance criterion。
- 每个 FR 必须至少追溯到一个 AC。
- 每个 AC 必须能反向追溯到 FR，并具备 Code Evidence 与 Test Evidence，或明确记录人工验收、外部服务依赖、暂不可自动化。
- Product Base traceability 应写入 `docs/product/base/traceability.md`。

## 非目标
- 不承诺任意场景生成。
- 不承诺完整 A1/A2/B1/B2/C1/C2 内容体系。
- 不承诺完整笔记本、任意词句查询或评分产品化。
- 不承诺 P0.1 训练 Agent、session planner、micro-action、hint ladder、pressure check。
- 不承诺跨天训练编排、完整 L0-L5 掌握阶梯或长期记忆调度。
- 不承诺完整会员权益 gating、Android 订阅购买、离线内容包下载或成就系统。
- 不承诺外部服务在所有环境中可用。

## 下游产物
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`
- `docs/reports/test_report.md` when executable or manual test evidence changes.

## Merge-Back Rule
后续 increment 只有在实现、验收、追溯、测试和报告证据完整或例外已记录后，才能由 Product Manager 批准合并进本文。合并时必须保留来源 increment、变更范围、验收证据和非目标变更。
