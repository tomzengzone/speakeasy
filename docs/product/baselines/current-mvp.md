# 当前 APP 基线

## 状态
Draft - 从 `docs/product/features/mvp-learning-loop-requirements.md` 提炼的当前已实现 APP 能力快照。

## 用途
本文是当前 APP 的基础需求和回归边界。后续 P0.1、P0.2、P1、P2 需求应在此基线上增加或改造，而不是把阶段名当作 feature。

## 上游来源
- `docs/product/features/mvp-learning-loop-requirements.md`
- 当前 Flutter 代码和资产路径引用

## Baseline 范围

| 能力域 | 当前已实现能力 | 证据 | 边界 |
| --- | --- | --- | --- |
| 启动与登录门禁 | 启动加载、启动失败重试、登录页、首评门禁、首页路由 | `lib/main.dart`, `lib/core/bootstrap/app_root.dart`, `lib/core/routing/app_router.dart` | 登录成功依赖后端、平台和配置 |
| 首评与学习路线 | 目标方向、表达卡点、输出水平、每日分钟偏好；支持写入两个官方场景 | `lib/pages/onboarding_page.dart`, `lib/services/storage_service.dart` | 日常服务不写入官方场景，工作沟通映射到入职介绍 |
| 官方场景库 | 场景目录、搜索、筛选、加入、移除、设为当前、等级切换 | `assets/data/interview_scene_catalog.json`, `assets/data/interview_scene_wikis/*.json`, `lib/pages/home_page.dart` | 真实官方场景仅 `job_interview` 和 `onboarding_introduction` |
| 听力热身和跟读 | 播放、暂停、上一句、下一句、循环播放、跟读录音、转写和基础评分反馈 | `lib/features/interview/interview_scene_listening_page.dart`, `lib/services/audio_service.dart` | 外部 TTS/ASR/评分不可用时只承认可恢复错误或降级 |
| 推荐表达队列 | 到期复习、薄弱表达、表达变体、选择判断、复述、填空、回忆、跟读等任务 | `lib/features/interview/expression_daily_queue_coordinator.dart`, `lib/features/interview/interview_expression_learning_page.dart` | 收藏不等于自动复习任务 |
| 表达收藏 | 收藏、取消收藏、收藏页展示和去重 | `lib/pages/favorites_page.dart`, `lib/services/storage_service.dart` | 仅保证复看，不承诺完整笔记本 |
| 语音场景模拟 | 语音作答、录音、取消、提交、转写、提示、教练反馈、消息播放/翻译、会话恢复 | `lib/features/interview/interview_practice_page.dart`, `lib/features/interview/interview_engine.dart`, `lib/features/interview/interview_llm_scheduler.dart` | 用户可见主路径为语音，不把文本输入作为默认主路径 |
| 学习沉淀 | 练习总结、掌握表达、薄弱表达、复习时间、个人素材、首页/推荐表达/个人 Wiki 影响 | `lib/features/interview/interview_wiki_store.dart`, `lib/features/interview/interview_practice_page.dart` | 本地优先，不承诺云端同步 |
| 我的和学习结果 | 个人中心、学习结果入口、收藏、历史、报告入口、设置、主题和提醒 | `lib/pages/profile_page.dart`, `lib/pages/learning_report_page.dart` | 学习报告依赖接口，无数据为空状态 |
| 会员与占位页 | 会员页、Apple IAP 前端接入、Android 未接入提示、离线和成就占位 | `lib/pages/membership_page.dart`, `lib/services/apple_payment_service.dart`, `lib/pages/offline_content_page.dart` | 不承诺完整权益 gating、Android 订阅或成就业务 |

## 基线成功标准
- 未登录用户启动后进入登录页。
- 已登录未首评用户进入首评页。
- 已登录已首评用户进入首页。
- 官方场景目录只按英语面试和入职介绍验收。
- 用户能进入听力热身、推荐表达、语音场景模拟、收藏、个人中心和学习结果入口。
- 训练结果能写回本地学习状态，并影响后续首页、推荐表达、个人 Wiki 或个人中心中的至少一个入口。
- 外部服务不可用时，用户应看到可恢复错误或降级路径。

## 非承诺项
- 不承诺任意场景生成。
- 不承诺完整 A1/A2/B1/B2/C1/C2 内容体系。
- 不承诺完整笔记本和任意词句查询。
- 不承诺跨天训练编排、完整 L0-L5 掌握阶梯或长期记忆调度。
- 不承诺完整评分产品化。
- 不承诺 Android 订阅购买闭环、完整会员权益 gating、离线内容包和成就业务。

## 下游使用规则
- P0.1 应引用本文作为当前能力基线，并只描述增量改造。
- 本文不得作为新增 feature requirements 直接复用；新增能力必须进入对应 increment requirements/spec。
- 如果后续代码基线变化，需要更新本文或新增新的 baseline 快照。
