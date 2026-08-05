# 分层测试用例目录

## 文档状态

- Artifact ID: `TEST_CASE_CATALOG`
- Status: candidate

本目录保存稳定的测试意图和 oracle，不保存运行时 `passed` / `failed` 状态。三类 TC 的直接上游互斥：FR-TC 只使用 `source_fr_id`，Contract-TC 只使用 `source_contract_id`，VS-TC 只使用 `source_vs_id`。跨层覆盖由 `TRACEABILITY` 从 owning sources 派生，不在 TC 中重复维护。

当前用例为已批准 Vertical Slice、已存在的 approved FR 以及受影响 Engineering Contract 建立稳定测试意图；它不保存测试执行结果，也不以目录登记代替实现或运行证据。

## FR-TC

### TC-FR-TRAIN-001 — 训练闭环展示快速验证

- type: `FR-TC`
- source_fr_id: `FR-TRAIN-001`
- layer: `widget`
- scope: `CAP-TRAIN/CAP-TRAIN-06`
- selector: `training_recap_panel`
- script_path: `test/features/training/training_recoverable_failure_test.dart`
- command: `flutter test test/features/training/training_recoverable_failure_test.dart`
- Given: 学习者已进入当前官方场景的语音训练，训练可以完成或返回无可用结果的可恢复状态。
- When: 学习者触发本轮结束动作。
- Then: 可用结果展示本轮练习总结和后续学习入口；失败或无可用结果展示可恢复错误或空状态，且不错误推进进度。
- Boundary/negative: 缺失结果不得生成总结结论，也不得把失败状态显示为已完成进度。

### TC-FR-CONTENT-001 — 已发布可见内容全集与空状态验证

- type: `FR-TC`
- source_fr_id: `FR-CONTENT-001`
- layer: `widget-integration`
- scope: `CAP-CONTENT/CAP-CONTENT-01`
- selector: `content_theme_catalog -> selected_theme_course_summaries`
- script_path: `test/features/content/content_catalog_contract_test.dart`
- command: `flutter test test/features/content/content_catalog_contract_test.dart`
- Given: 当前学习者可访问一组已发布主题，其中至少一个主题没有已发布且可见的课程，另一个主题具有多个不同 CEFR 的已发布可见课程。
- When: 学习者打开内容资产入口并选择主题浏览课程摘要。
- Then: 主题与课程集合完整呈现符合条件的项目；无课程主题仍保留并显示真实空状态；课程摘要可定位英文标题、中文简介和唯一 CEFR 等级。
- Boundary/negative: 获取失败必须与真实空集合区分并保留恢复路径；不得遗漏符合发布与可见条件的内容，也不得接受 legacy 课程等级值。

### TC-FR-CONTENT-002 — 课程基本信息与版本一致性验证

- type: `FR-TC`
- source_fr_id: `FR-CONTENT-002`
- layer: `widget-integration`
- scope: `CAP-CONTENT/CAP-CONTENT-02`
- selector: `course_card -> course_detail_header`
- script_path: `test/features/content/course_detail_contract_test.dart`
- command: `flutter test test/features/content/course_detail_contract_test.dart`
- Given: 同一已发布课程可从课程卡片和另一课程入口打开，并具有英文标题、中文简介、唯一 CEFR 等级、正值典型完成时长及单位。
- When: 学习者分别从两个入口打开该课程。
- Then: 两个入口解析到同一课程及同一发布版本，并展示一致的必备基本信息；缺少背景图时仍可查看其他信息。
- Boundary/negative: 缺少任一发布必备字段或无法解析同一版本时不得用其他课程、其他版本或错误占位值替代。

## Contract-TC

### TC-CONTRACT-CONTENT-CEFR-001 — API 与服务端严格 CEFR 值域

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `contract`
- scope: `CONTENT-CEFR-API-001 / request-response-path LevelCode`
- selector: `CONTENT-CEFR-API-001 -> CefrLevelContractTest`
- script_path: `backend/src/test/java/com/speakeasy/CefrLevelContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CefrLevelContractTest test`
- Given: API 代表性 request、response 与 path boundary 分别收到六个 CEFR 值、legacy L 值、旧英文别名和未知值。
- When: 请求进入 validation、内容查询、练习或训练会话边界。
- Then: 六个 CEFR 值通过 schema validation；存在内容的 A2/B1/B2 可解析；旧值、旧别名和未知值以 schema validation error 拒绝。
- Boundary/negative: 合法但无内容的 A1/C1/C2 返回定义的空集合或资源不存在，不得规范化、fallback 或替换为其他等级。

### TC-CONTRACT-CONTENT-CEFR-002 — 持久化等级一次性迁移与约束

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `migration`
- scope: `CONTENT-CEFR-API-001 / persisted API-facing level facts`
- selector: `CONTENT-CEFR-API-001 -> V202608050001__strict_cefr_level_cutover.sql`
- script_path: `backend/src/test/java/com/speakeasy/FoundationMigrationTest.java`
- command: `mvn -f backend/pom.xml -Dtest=FoundationMigrationTest test`
- Given: 历史 migrations 已创建带 L1/L2/L3 的用户、评估、路线、场景状态、内容、练习和训练等级事实。
- When: 新的 CEFR cutover migration 在完整 schema 上执行。
- Then: 所有 API-facing 等级字段按 L1→A2、L2→B1、L3→B2 转换，稳定 ID、内容版本和会话状态不变，并建立六值约束及 ScenarioLevel 双字段一致性约束。
- Boundary/negative: migration 后不得残留 legacy 值、产生双份记录或允许写入 legacy/未知值；既有历史 migration 文件不得被改写。

### TC-CONTRACT-CONTENT-CEFR-003 — Flutter 内容资产等级与引用完整性

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `asset-contract`
- scope: `CONTENT-CEFR-API-001 / bundled content assets`
- selector: `CONTENT-CEFR-API-001 -> scene phases/tracks/levelMap/nodes/references`
- script_path: `test/features/interview/cefr_level_asset_contract_test.dart`
- command: `flutter test test/features/interview/cefr_level_asset_contract_test.dart`
- Given: 一个 scene catalog 与三份活跃 bundled Wiki 资产已执行 CEFR 内容 ID 与等级值迁移。
- When: 资产 loader 解析 catalog、scene tracks、levelMap、node graph 与所有前后引用。
- Then: 只存在 A2/B1/B2 内容轨道，所有迁移后的 ID 和引用可解析，A1/C1/C2 不被伪造为已有内容。
- Boundary/negative: course/track 字段不得残留 L1/L2/L3 或旧英文别名；hintTree 的 L1–L4 key 和提示语义必须原样保留。

### TC-CONTRACT-CONTENT-CEFR-004 — OpenAPI 与 generated Dart client 漂移门禁

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `contract-drift`
- scope: `CONTENT-CEFR-API-001 / OpenAPI and generated Dart boundary`
- selector: `CONTENT-CEFR-API-001 -> LevelCode enum and OpenAPI hash`
- script_path: `scripts/check_openapi_dart_drift.py`
- command: `python scripts/check_openapi_dart_drift.py`
- Given: OpenAPI 的 LevelCode、API examples、generated Dart registry、manifest 和 hash marker 来自同一候选版本。
- When: API contract 与 Dart drift checks 执行。
- Then: OpenAPI 只声明六个 CEFR 值，generated Dart `LevelCode` typed enum 与其逐值一致，并嵌入同一 OpenAPI hash 且无 path drift。
- Boundary/negative: 任一 legacy course-level enum/example、旧 hash 或手写未登记 API path 都必须使门禁失败；GoalMasteryLevel 不得被 CEFR enum 覆盖。

### TC-CONTRACT-CONTENT-CEFR-005 — 掌握度与提示层级非回归

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `regression`
- scope: `CONTENT-CEFR-API-001 / excluded mastery and hint namespaces`
- selector: `CONTENT-CEFR-API-001 -> GoalMasteryLevel and hint ladder`
- script_path: `backend/src/test/java/com/speakeasy/goal/MasteryTransitionPolicyTest.java`
- command: `mvn -f backend/pom.xml -Dtest=MasteryTransitionPolicyTest test`
- Given: course/scenario 等级已迁移到 CEFR，同时系统仍保存独立的 mastery L0–L5 和 hint L1–L4 语义。
- When: 掌握度 transition 与提示层级回归测试执行。
- Then: mastery 阶梯、transition threshold 和 hint/scaffolding namespace 保持原有语义，不被解释为 CEFR。
- Boundary/negative: CEFR migration 不得修改 mastery 持久化、transition policy、hintTree key 或 UI 提示级别。

### TC-CONTRACT-CONTENT-CEFR-006 — Flutter 本地等级数据原子清理

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `client-storage`
- scope: `CONTENT-CEFR-API-001 / development-local persisted level and node facts`
- selector: `CONTENT-CEFR-API-001 -> storage migration v2`
- script_path: `test/services/storage_service_cefr_migration_test.dart`
- command: `flutter test test/services/storage_service_cefr_migration_test.dart`
- Given: storage migration v1 中仍可能存在携带旧课程等级、旧 node ID 或旧 active-session 引用的开发期本地数据。
- When: 客户端初始化并执行 storage migration v2。
- Then: 所有受课程等级或 node ID 影响的固定 key 与场景 active-session 动态 key 在一次批量操作中清理，无关 key 保留，且仅在清理成功后记录 migration version 2。
- Boundary/negative: 清理失败时不得提前推进版本；重新注入 L1/L2/L3 或旧英文别名后，严格 reader 必须拒绝，不能转换或 fallback 到 A2。

## VS-TC

### TC-VS-TRAIN-001-1 — 官方场景练习结束全链路验证

- type: `VS-TC`
- source_vs_id: `VS-TRAIN-001-1`
- layer: `integration-e2e`
- scope: `selected VS user-visible training loop`
- selector: `training_session_view -> training_recap_panel`
- script_path: `integration_test/p0_1_training_loop_test.dart`
- command: `flutter test integration_test/p0_1_training_loop_test.dart`
- Given: 学习者选择官方场景并进入当前一轮语音练习，实际受影响的训练服务、API、客户端状态和 UI 可用。
- When: 学习者完成或结束当前一轮练习。
- Then: 用户界面展示本轮总结、关键反馈、进度变化和后续学习入口。
- Boundary/negative: 服务不可用、结束失败或无可用结果时，用户看到可恢复的错误或空状态；进度不得被错误推进。

### TC-VS-CONTENT-001-1 — 官方主题与课程摘要浏览全链路验证

- type: `VS-TC`
- source_vs_id: `VS-CONTENT-001-1`
- layer: `integration-e2e`
- scope: `approved content catalog browsing slice`
- selector: `content_asset_entry -> theme_card -> course_summary_list`
- script_path: `integration_test/content_catalog_browse_test.dart`
- command: `flutter test integration_test/content_catalog_browse_test.dart`
- Given: 学习者进入内容资产入口，后端或本地内容源包含已发布可见主题、有课程主题和零课程主题。
- When: 学习者浏览主题并选择一个主题查看课程摘要。
- Then: 学习者可以比较所有符合条件的主题与课程摘要，并在零课程主题看到真实空状态。
- Boundary/negative: 加载失败时保留已知浏览上下文和恢复入口，不得显示成空主题或遗漏一部分已发布可见内容。

### TC-VS-CONTENT-002-1 — 课程详情基本信息全链路验证

- type: `VS-TC`
- source_vs_id: `VS-CONTENT-002-1`
- layer: `integration-e2e`
- scope: `approved course-detail information slice`
- selector: `course_summary_card -> course_detail_header`
- script_path: `integration_test/course_detail_header_test.dart`
- command: `flutter test integration_test/course_detail_header_test.dart`
- Given: 学习者看到一门已发布可见课程的摘要卡片，该课程版本具有所有发布必备基本信息且背景图可以缺省。
- When: 学习者从课程卡片打开课程。
- Then: 详情标题区展示同一课程版本的英文标题、中文简介、CEFR 等级和典型完成时间，学习者可据此判断是否开始。
- Boundary/negative: 背景图缺失不阻断信息展示；课程或版本无法解析时不得显示其他课程或过期版本的数据。

## 维护规则

- FR 存在时，每条 approved FR 必须有适用的最低成本 FR-TC；例外必须记录 owner、原因、影响和失效期限。
- 每个实施中的 VS 必须有一个用户可感知的 integration/E2E VS-TC。
- Contract 事实变化必须新增或更新对应 Contract-TC，并选择 contract、integration、migration 或 AI-eval 等适用层级。
- selector、脚本路径和命令是可执行定位信息；运行结果由绑定 exact commit SHA 的测试或 CI 系统保存。
