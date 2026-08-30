# 分层测试用例目录

## 文档状态

- Status: candidate

本目录保存稳定的测试意图和 oracle，不保存运行时 `passed` / `failed` 状态。FR-TC 使用 `source_fr_id`，Contract-TC 使用 `source_contract_id`，VS-TC 使用 `source_vs_id`；每条用例同时给出可执行脚本和命令。

账号恢复先执行最低成本的 backend/contract 测试，再执行用户可见 widget-integration 路径；真实短信 provider、真机和 exact-commit 运行结果保存在仓库外的测试证据中。

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

### TC-FR-ACC-001 — 既有手机号身份与恢复专用一次性验证

- type: `FR-TC`
- source_fr_id: `FR-ACC-001`
- layer: `backend-integration`
- scope: `phone account recovery / eligibility and verified account resolution`
- selector: `PhoneAccountRecoveryTest / existing-identity-purpose-bound-one-time-code`
- script_path: `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryTest.java`
- command: `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryTest test`
- execution_owner: `backend`
- Given: 一个 active 既有账号唯一绑定标准化且仍可用的手机号，provider 为该手机号签发一枚未过期、未使用且 purpose 为 `account_recovery` 的验证码；另有账号不存在、手机号未绑定或不可用、普通登录 purpose、错误、过期和已使用验证码 fixture。
- When: 学习者主动选择账号恢复并提交手机号与验证码，service 只通过 existing-identity resolver 处理各 fixture。
- Then: 只有恢复专用有效验证码解析到该手机号已绑定的唯一既有账号并消费验证码一次；同一验证码再次提交不能再次完成恢复，且整个路径不调用 login-or-create。
- Boundary/negative: 任一不符合资格或验证码约束的 fixture 都必须返回恢复验证失败，不得解析其他账号、创建账号、改绑身份或把普通登录验证码接受为恢复凭据；已签发或已消费的恢复码不得被普通手机号登录接受。

### TC-FR-ACC-002 — 恢复保留原账号并撤销全部会话

- type: `FR-TC`
- source_fr_id: `FR-ACC-002`
- layer: `backend-integration`
- scope: `phone account recovery / successful state transition`
- selector: `PhoneAccountRecoveryTest / recoveryPreservesTheAccountRevokesEverySessionAndIssuesNoSession`
- script_path: `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryTest.java`
- command: `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryTest test`
- execution_owner: `backend`
- Given: 经恢复专用验证确认的既有账号具有固定 user、profile、学习数据和订阅权益快照，并在发起恢复的设备及其他设备上各有 active Session、Refresh Token family/token 和 Access Token。
- When: service 成功完成该账号的恢复状态转换。
- Then: 同一账号及其 profile、学习数据和订阅权益快照保持不变，security epoch 只推进一次，全部既有 Session 与 token family/token 均被撤销，结果只指示 `recovered` 和 `login_phone`，且不创建新 Session 或签发 Access/Refresh Token。
- Boundary/negative: 发起恢复的当前 Session 不得被保留；成功结果不得包含 session、token、user 或 revoked-count，学习者未重新完成手机号登录前不得恢复认证访问。

### TC-FR-ACC-003 — 恢复失败零身份与会话副作用

- type: `FR-TC`
- source_fr_id: `FR-ACC-003`
- layer: `backend-integration`
- scope: `phone account recovery / recoverable failure invariants`
- selector: `PhoneAccountRecoveryTest / privacy-safe-failure-and-transaction-rollback`
- script_path: `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryTest.java`
- command: `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryTest test`
- execution_owner: `backend`
- Given: 分别构造账号不存在、手机号未绑定或不可用、验证码发送失败、验证错误、验证码过期以及完成恢复前中断，并记录尝试前的账号数、身份绑定、security epoch、Session 与 token family/token 快照。
- When: 每种失败或中断发生在恢复成功提交之前，随后学习者重新进入恢复入口。
- Then: 本次尝试整体失败，账号数、身份绑定、security epoch、Session 与全部 token 快照均与尝试前一致；明确、隐私安全的验证失败允许重新申请验证码、重试恢复，或由学习者主动返回手机号登录，返回时只保留手机号表单值并清空 recovery code。
- Boundary/negative: 失败不得创建占位账号、部分改绑身份、局部撤销会话、清理客户端 token 来伪造成功，或因上一次失败阻止一次新的显式恢复尝试；明确失败不得自动跳转、自动调用或自动提交 login-or-create，用户主动返回这一导航动作本身不得创建账号/identity/Session/Token。

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

### TC-CONTRACT-CONTENT-COURSE-001 — 无过滤主题全集与稳定顺序

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `api-integration`
- scope: `CONTENT-COURSE-CATALOG-API-001 / authenticated scenario catalog projection`
- selector: `CONTENT-COURSE-CATALOG-API-001/scenario-all`
- script_path: `backend/src/test/java/com/speakeasy/content/CourseCatalogApiContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CourseCatalogApiContractTest#scenarioAll test`
- Given: 已认证学习者的服务端投影包含多个已发布可见主题，主题 ID 顺序被打乱，其中包含满足公共格式但不在两个兼容常量内的 `travel_planning`，且至少一个主题没有可见 Course；另有未发布或不可见主题以及可选 query/category 过滤输入。
- When: 分别以省略过滤参数和显式过滤参数调用 `GET /scenarios`。
- Then: 无过滤调用恰好返回全部已发布可见主题并按 `scenario_id` 升序，`travel_planning` 原样返回并参与正常排序，零可见 Course 的主题仍保留；显式过滤只能在同一认证、发布和可见性全集上缩小结果，且不改变后续无过滤调用的全集语义。
- Boundary/negative: 满足契约的新 ID 不得被旧的两值 allowlist 丢弃；无匹配为 `200 scenarios: []`；查询、依赖、部分读取或完整性故障必须返回 typed retryable `503`，不得伪装为空、按 Course 是否存在过滤主题或使用隐式 category/search/entitlement tier。

### TC-CONTRACT-CONTENT-COURSE-002 — 主题课程摘要全集、排序与真实空集

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `api-integration`
- scope: `CONTENT-COURSE-CATALOG-API-001 / scenario course-summary projection`
- selector: `CONTENT-COURSE-CATALOG-API-001/course-list`
- script_path: `backend/src/test/java/com/speakeasy/content/CourseCatalogApiContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CourseCatalogApiContractTest#courseList test`
- Given: 一个已发布可见主题下有多门 current published 且可见的 Course，并以不同的唯一 `Course.sort_order` 保存；另有 draft、superseded、不可见 Course 和一个真实零课程主题。
- When: 学习者调用 `GET /scenarios/{scenario_id}/courses`。
- Then: 响应恰好包含全部符合条件的 Course summary，按 `Course.sort_order` 升序且不受 per-user state 重排；每条 summary 都含稳定 Course/version/binding 引用、非空英文标题、非空中文简介和唯一合法 CEFR 等级；真实零课程主题返回 `200 courses: []`。
- Boundary/negative: draft、superseded 或不可见 Course 不得进入集合；主题缺失、未发布或不可见统一为 privacy-safe `404`，查询/依赖/完整性故障为 typed retryable `503`，不得返回部分成功或伪空集合。

### TC-CONTRACT-CONTENT-COURSE-003 — 课程详情字段与摘要表示一致性

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `api-integration`
- scope: `CONTENT-COURSE-CATALOG-API-001 / version-pinned course detail representation`
- selector: `CONTENT-COURSE-CATALOG-API-001/course-detail`
- script_path: `backend/src/test/java/com/speakeasy/content/CourseDetailApiContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CourseDetailApiContractTest#courseDetail test`
- Given: 课程列表中的一条已发布可见 summary 可原样提供 `course_id`、`course_version_id` 与 binding 引用，详情 snapshot 具有正值时长、trim 后非空单位，背景引用分别为有效值和 null。
- When: 学习者使用 summary 的精确身份调用 `GET /courses/{course_id}/versions/{course_version_id}`。
- Then: detail 的 Course/version/binding、英文标题、中文简介和 CEFR 与列表 summary 完全一致，并额外返回 `typical_duration.value > 0`、非空单位及 nullable `background_asset_ref`；背景为 null 时其余必备信息仍成功返回。
- Boundary/negative: 标题、简介、CEFR、时长值或单位不满足契约时必须 typed retryable `503`；不得以占位时长、其他媒体、Course/version 或 CEFR 替代缺损 snapshot。

### TC-CONTRACT-CONTENT-COURSE-004 — Course 与 CourseVersion 精确匹配且不回退

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `api-integration`
- scope: `CONTENT-COURSE-CATALOG-API-001 / exact course-version resolution`
- selector: `CONTENT-COURSE-CATALOG-API-001/exact-version`
- script_path: `backend/src/test/java/com/speakeasy/content/CourseDetailApiContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CourseDetailApiContractTest#exactVersion test`
- Given: 固定的 `course_id` 同时存在 current published、draft 和 superseded versions，另一个 Course 有可用版本，并构造 version 缺失、未发布、不可见及不属于所给 Course 的请求。
- When: 学习者逐一请求这些 Course/version 组合。
- Then: 只有同时匹配请求 Course 且为 exact current published、visible 的版本成功；缺失、未发布、不可见和身份不匹配在外部状态、code、message shape 与缓存行为上统一为 `RESOURCE_NOT_FOUND` / `404`。
- Boundary/negative: resolver 绝不得回退到 latest、同 Course 的其他版本、其他 Course、其他 ScenarioVersion/ScenarioLevel 或相邻 CEFR，外部错误也不得暴露资源存在性或 entitlement 结果。

### TC-CONTRACT-CONTENT-COURSE-005 — Binding 一对一、同主题同 CEFR 与整体失败

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `service-integration`
- scope: `CONTENT-COURSE-CATALOG-API-001 / CourseContentBinding read integrity`
- selector: `CONTENT-COURSE-CATALOG-API-001/binding-integrity`
- script_path: `backend/src/test/java/com/speakeasy/content/CourseContentBindingContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CourseContentBindingContractTest#readProjectionIntegrity test`
- Given: 一个有效 CourseVersion 恰好绑定一个同 Scenario 且同 CEFR 的 ScenarioVersion/ScenarioLevel，并分别构造 binding 缺失、重复、Scenario 不一致、CEFR 不一致和 bound content unavailable 数据。
- When: 目录或精确详情 resolver 校验并投影 `course_content_binding_id`、`scenario_version_id` 与 `scenario_level_id`。
- Then: 有效 binding 返回三个稳定安全引用且 `CourseVersion.cefr_level = ScenarioLevel.level_code = ScenarioLevel.target_level`；每种完整性故障都保留内部 typed outcome，并在 API 边界映射为 `CONTENT_READ_UNAVAILABLE` / `503` 与 `details.retryable = true`。
- Boundary/negative: 任一损坏 Course 必须使本次读取整体失败，不得省略损坏项、返回部分集合、重新绑定、选择替代 Course/version/content/level 或暴露存储位置、signed URL、entitlement、用户状态和 runtime identity。

### TC-CONTRACT-CONTENT-COURSE-006 — 成功包络、严格 CEFR 与类型化错误

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `api-contract`
- scope: `CONTENT-COURSE-CATALOG-API-001 / success and error schemas`
- selector: `CONTENT-COURSE-CATALOG-API-001/schema-and-errors`
- script_path: `backend/src/test/java/com/speakeasy/content/CourseCatalogSchemaContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CourseCatalogSchemaContractTest#schemaAndErrors test`
- Given: 三个内容读取操作各有成功、真实空、未认证、privacy-safe unavailable、Content query/integrity failure fixture；`ScenarioId` 机器契约为 `string`、`minLength: 1`、`maxLength: 80`、`^[a-z0-9]+(?:_[a-z0-9]+)*$` 且无 enum，并对 Course 等级注入六个 CEFR 值、legacy L 值和未知值。
- When: 响应与 OpenAPI 定义的 success/error schemas 和 examples 进行契约断言。
- Then: 每个 `200` 顶层都有常量 `schema_version: 1` 与本次调用唯一的 `request_id`，合法新 `ScenarioId` 原样进入普通 Content lookup，合法 Course 等级仅为 A1/A2/B1/B2/C1/C2；`401 UNAUTHENTICATED`、`404 RESOURCE_NOT_FOUND` 和 `503 CONTENT_READ_UNAVAILABLE` 的状态、code、message、request_id、typed retryable details 与 schema/example 一致。
- Boundary/negative: `ScenarioId` 的空值、81 位、大小写、连字符和畸形下划线分隔必须以 `SCHEMA_VALIDATION_FAILED` 拒绝；legacy/未知等级必须拒绝；query、依赖、部分读取或 binding 故障不得变成 `200`、空集合、`PROVIDER_UNAVAILABLE` 或未登记错误 shape，内部 SQL/provider/entitlement detail 不得进入外部响应。

### TC-CONTRACT-CONTENT-COURSE-007 — 发布与可见性分离及隐私安全收敛

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `security-integration`
- scope: `CONTENT-COURSE-CATALOG-API-001 / publication and learner visibility boundary`
- selector: `CONTENT-COURSE-CATALOG-API-001/privacy-visibility`
- script_path: `backend/src/test/java/com/speakeasy/content/CourseCatalogVisibilityContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CourseCatalogVisibilityContractTest#privacyVisibility test`
- Given: Content publication facts 固定不变，两个学习者具有不同 visibility projection；对 theme、Course 和 exact CourseVersion 分别构造不存在、未发布与不可见结果，并启用脱敏内部 outcome 观测。
- When: 两个学习者读取相同路径并比较外部响应与内部审计/指标分类。
- Then: publication 只来自 Content，visibility 只在服务端读取投影中消费且不写回 Course 聚合；不存在、未发布和不可见在外部统一为 privacy-safe `404`，内部仍可区分 theme/course/version/visibility outcome 并仅记录脱敏或散列稳定引用。
- Boundary/negative: 响应、缓存、Content persistence、日志或指标不得复制 per-user entitlement/visibility truth、返回 `FORBIDDEN`/`ENTITLEMENT_REQUIRED` 探测资源、泄漏 raw entitlement/resource existence 或记录 authored body 与用户 runtime payload。

### TC-CONTRACT-CONTENT-COURSE-008 — 学习者私有 ETag 与条件重验证

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `cache-security-integration`
- scope: `CONTENT-COURSE-CATALOG-API-001 / learner-private validation cache`
- selector: `CONTENT-COURSE-CATALOG-API-001/private-etag`
- script_path: `backend/src/test/java/com/speakeasy/content/CourseCatalogCacheContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CourseCatalogCacheContractTest#learnerPrivateEtag test`
- Given: 同一学习者对标准化 method/path/query、visibility revision 和 exact ordered version/binding projection 不变时重复读取，随后切换学习者、授权/可见性、publication 或 exact version；请求携带先前 `If-None-Match`。
- When: 服务端重新认证、重算 publication/visibility projection 并决定返回 `304` 或新的 `200`。
- Then: `200` 返回 learner-specific opaque ETag、`Cache-Control: private, no-cache` 与 `Vary: Authorization` 或等价隔离；representation 未变时可返回携带本次 `X-Request-Id` 的 `304`，变化时返回新表示和新 request_id，request/trace/time 元数据不参与 fingerprint。
- Boundary/negative: 任何 ETag/body 不得跨用户、登出、授权上下文或 exact version 复用；缓存不得成为 publication/visibility truth，fingerprint 不得暴露 raw user id、entitlement payload 或 secret，且不得在重认证/重验证之前返回 `304`。

### TC-CONTRACT-CONTENT-COURSE-009 — OpenAPI 与 generated Dart 路径、类型及哈希一致

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `contract-drift`
- scope: `CONTENT-COURSE-CATALOG-API-001 / OpenAPI and generated Dart candidate`
- selector: `CONTENT-COURSE-CATALOG-API-001/generated-drift`
- script_path: `test/services/api_client_contract_test.dart`
- command: `flutter test test/services/api_client_contract_test.dart`
- Given: OpenAPI、generated Dart path/type registry、typed ErrorCode、hash marker 与 drift manifest 来自同一候选版本；`ScenarioId` 是开放且受 `1..80` 位 lowercase snake-case 格式约束的值对象，两个既有 ID 只保留为兼容常量；候选包含场景全集、主题课程列表和精确 CourseVersion 详情边界，既有 handwritten `/cards` 仅作为 manifest 显式登记的 legacy exception 输入。
- When: Flutter API client contract test 对 operation paths、path builders、Course schemas、CEFR/ErrorCode 类型和 OpenAPI SHA-256 进行逐项比对。
- Then: 两个新增 Course paths、参数化 builder、Course summary/detail/binding/duration/response 类型、`CONTENT_READ_UNAVAILABLE` 与严格 CEFR 均已登记；任意格式合法的 `ScenarioId` 可无损 round-trip，生成器固定 type、长度、pattern、无 enum 及共享 parameter/schema 引用；generated source、marker、manifest 和当前 OpenAPI hash 完全一致，显式登记的 legacy `/cards` 保持为非 Course API 的独立兼容例外。
- Boundary/negative: `ScenarioId` 退化为 enum、约束漂移、非法 ID 被接受、新 Course path/type 使用 `/cards`、未在 manifest 登记的 `/cards`、缺失或额外 path/type、旧 hash、latest-version convenience path、Course-level legacy alias、`ScenarioLevel` alias 或未登记 DTO 必须使测试失败；既有 `/cards` 只有在 manifest 显式登记且未被解释为 Course API 时可保留。

### TC-CONTRACT-CONTENT-COURSE-010 — Additive 上线、入口回滚与既有边界隔离

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `migration-regression`
- scope: `CONTENT-COURSE-CATALOG-API-001 / additive rollout and safe rollback`
- selector: `CONTENT-COURSE-CATALOG-API-001/compatibility-rollback`
- script_path: `backend/src/test/java/com/speakeasy/content/CourseCompatibilityRollbackContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CourseCompatibilityRollbackContractTest test`
- Given: 既有 Scenario/ScenarioVersion/ScenarioLevel、practice/training、mastery L0-L5、hint L1-L4 和账号删除流程已存在；Course 三对象以 additive migration 部署，两个新 route/learner entry 可关闭，且 authored Course inventory 可以为空。
- When: 执行 backend-first 上线检查，关闭新 route/entry 并失效其私有 cache，再运行既有内容、训练、学习与账号删除回归。
- Then: 既有 `GET /scenarios`、ScenarioLevel API 与 practice/training 流程保持可用，mastery/hint namespace 不变，账号删除不删除非用户 authored Course/CourseVersion/binding；回滚保留 additive Course 数据并不需要重解释 ScenarioLevel。
- Boundary/negative: 不得执行破坏性 down migration、dual-read/dual-write、legacy Course path、ScenarioLevel 重命名/复制/alias 或按 ScenarioLevel 合成 Course；Task Plan、OpenAPI example、seed 数量/内容不得被测试接受为 authored content authority，空 Course 库存必须仍是合法部署状态。

### TC-CONTRACT-AUTH-RECOVERY-001 — 恢复码申请不枚举账号

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `api-contract`
- scope: `AUTH-ACCOUNT-RECOVERY-API-001 / POST recovery verification-codes`
- selector: `AUTH-ACCOUNT-RECOVERY-API-001/request-code-privacy -> PhoneAccountRecoveryTest`
- script_path: `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryTest.java`
- command: `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryTest test`
- execution_owner: `backend`
- Given: 相同 schema 的恢复码申请分别携带已绑定 active 账号的手机号、未绑定手机号和不存在账号的手机号，provider 对可接受申请返回接收结果。
- When: 未认证调用方请求 `POST /auth/account-recovery/phone/verification-codes`。
- Then: 三种账号事实均返回外形一致的 `202`、`{schema_version: 1, status: accepted}`、`Cache-Control: no-store` 和本次请求的 `X-Request-Id`，响应时序分类与可观察字段不暴露手机号是否存在或已绑定。
- Boundary/negative: 响应不得包含 user、identity、session、token、发送目标或存在性提示；格式错误只能以登记的 `400 SCHEMA_VALIDATION_FAILED` 拒绝，不得借错误差异泄漏账号事实。

### TC-CONTRACT-AUTH-RECOVERY-002 — Purpose 隔离、一次性消费与 at-most-once

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `provider-contract-integration`
- scope: `AUTH-ACCOUNT-RECOVERY-API-001 / verification purpose and replay boundary`
- selector: `AUTH-ACCOUNT-RECOVERY-API-001/purpose-bound-at-most-once -> PhoneAccountRecoveryTest, PhoneAccountRecoveryProviderFailureTest`
- script_path: `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryTest.java`, `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryProviderFailureTest.java`
- command: `mvn -f backend/pom.xml "-Dtest=PhoneAccountRecoveryTest,PhoneAccountRecoveryProviderFailureTest" test`
- execution_owner: `backend`
- Given: 同一标准化手机号分别具有 recovery purpose 的有效、错误、过期、已使用验证码和普通 phone-login purpose 的有效验证码；完成请求不声明 `Idempotency-Key`，并可在请求中额外携带不同的未登记 `Idempotency-Key` header 以验证其不改变语义。
- When: 各验证码调用 `POST /auth/account-recovery/phone`，并对唯一成功的恢复验证码使用相同或不同 header 重放。
- Then: 只有未过期、未使用且 purpose 为 recovery 的验证码恰好成功一次；普通登录 purpose、错误、过期、已使用及所有重放统一返回 privacy-safe `401 ACCOUNT_RECOVERY_VERIFICATION_FAILED`，更换 `Idempotency-Key` 不能产生第二次成功。
- Boundary/negative: 恢复验证码在签发后、恢复成功消费后及重放时均不得用于普通登录，登录验证码不得用于恢复；服务端不得把 `Idempotency-Key` 变成恢复成功事实、缓存成功响应或在重放时再次推进 security epoch/写入第二个成功审计。

### TC-CONTRACT-AUTH-RECOVERY-003 — 原子推进 epoch、全会话失效且不签发凭据

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `postgres-integration`
- scope: `AUTH-ACCOUNT-RECOVERY-API-001 / successful transactional revocation`
- selector: `AUTH-ACCOUNT-RECOVERY-API-001/atomic-all-session-revocation`
- script_path: `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryPostgresTest.java`
- command: `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryPostgresTest test`
- execution_owner: `backend`
- Given: 一个经恢复验证码唯一确认的既有账号具有固定 user/profile、学习数据和订阅权益快照，多个设备 Session、多个 Refresh Token family/token 及相应 opaque Access Token 均为 active。
- When: 恢复完成请求在真实 PostgreSQL 事务中提交，并随后分别使用所有旧 Access Token 访问受保护资源、使用所有旧 Refresh Token 刷新。
- Then: 同一 user/profile、学习数据和订阅权益快照保持不变；security epoch 在一次提交中恰好推进，所有 Session、Refresh family/token 被撤销，全部旧 Access/Refresh Token 立即失效；`200` 响应精确为 `schema_version: 1`、`status: recovered`、`next_action: login_phone` 并携带 `no-store` 与 `X-Request-Id`。
- Boundary/negative: 响应不得包含 user、session、Access/Refresh Token、revoked-count 或其他 runtime identity；不得保留当前设备 Session、只撤销部分 family，或在事务提交前返回成功。

### TC-CONTRACT-AUTH-RECOVERY-004 — 失败与事务回滚零副作用

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `fault-injection-integration`
- scope: `AUTH-ACCOUNT-RECOVERY-API-001 / failure atomicity and retry recovery`
- selector: `AUTH-ACCOUNT-RECOVERY-API-001/rollback-zero-side-effects`
- script_path: `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryPostgresTest.java`
- command: `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryPostgresTest test`
- execution_owner: `backend`
- Given: 已记录账号数、AuthIdentity、user/profile、学习/订阅、security epoch、Session、Refresh family/token 和审计快照，并在 provider 已消费有效恢复码之后、数据库提交之前分别注入身份解析、撤销持久化或审计写入失败。
- When: 完成恢复请求进入故障点，之后重放已消费验证码并申请一枚新的 recovery 验证码重试。
- Then: 故障请求返回登记的可重试失败，所有数据库与审计快照保持原值且没有成功响应；已消费验证码不能重放，新验证码可重新启动一次独立恢复尝试。
- Boundary/negative: 回滚不得遗留新账号、身份变化、epoch 推进、部分 Session/token 撤销或成功审计；客户端 token 清理不得被服务端测试接受为撤销证据，也不得把已消费验证码恢复为可用。

### TC-CONTRACT-AUTH-RECOVERY-005 — 隐私安全错误、限流与脱敏观测

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `security-integration`
- scope: `AUTH-ACCOUNT-RECOVERY-API-001 / errors, bounded rate limits and observability`
- selector: `AUTH-ACCOUNT-RECOVERY-API-001/privacy-errors-rate-limit-observability -> PhoneAccountRecoveryTest, PhoneAccountRecoveryProviderFailureTest, PhoneAccountRecoveryRateLimitHttpTest`
- script_path: `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryTest.java`, `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryProviderFailureTest.java`, `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryRateLimitHttpTest.java`
- command: `mvn -f backend/pom.xml "-Dtest=PhoneAccountRecoveryTest,PhoneAccountRecoveryProviderFailureTest,PhoneAccountRecoveryRateLimitHttpTest" test`
- execution_owner: `backend`
- Given: 对两个 endpoint 构造账号不存在、手机号未绑定或不可用、验证码错误/过期/已使用/purpose 不匹配、格式错误、provider 暂时不可用，并超过标准化手机号 hash、device 与 network bucket 的各维限流阈值；同时捕获外部响应、日志、metrics 与审计字段。
- When: 依次发送恢复码申请和完成恢复请求直至触发各错误与限流分支。
- Then: 所有恢复验证失败具有相同 `401 ACCOUNT_RECOVERY_VERIFICATION_FAILED` message/details 外形；格式错误为 `400 SCHEMA_VALIDATION_FAILED` 且响应体携带 request_id，限流为 `429 AUTH_RATE_LIMITED` 且有有效 `Retry-After`，临时依赖失败为 `503 AUTH_SERVICE_UNAVAILABLE` 且明确可重试；`401/429/503` 均携带 `Cache-Control: no-store` 和 `X-Request-Id`。
- Boundary/negative: 响应、日志和 metrics 不得出现 raw phone、验证码、token、user/session/device id、任意 app-version 或 raw path 高基数 label；错误差异不得暴露账号存在性，限流不得只依赖单一可绕过维度，失败审计不得记录秘密或被计作成功恢复。

### TC-CONTRACT-AUTH-RECOVERY-006 — Generated 边界、typed wrapper 与明确成功结果一致

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `contract-and-widget-integration`
- scope: `AUTH-ACCOUNT-RECOVERY-API-001 / OpenAPI, generated path/schema/error/hash, typed ApiClient wrapper and explicit-success client boundary`
- selector: `AUTH-ACCOUNT-RECOVERY-API-001/generated-drift-and-result-unknown -> account_recovery_back | account_recovery_retry_after_unknown | account_recovery_retry_local_cleanup`
- script_path: `test/services/api_client_contract_test.dart; test/pages/phone_account_recovery_page_test.dart`
- command: `flutter test test/services/api_client_contract_test.dart test/pages/phone_account_recovery_page_test.dart`
- execution_owner: `frontend`
- Given: OpenAPI、generated Dart path/schema/error registry、hash marker 和 drift manifest 来自同一候选版本，typed `ApiClient` wrapper 只负责构造请求和解析机器契约已有字段；恢复完成请求可能明确收到 `200 recovered`、明确失败，或因 timeout、cancellation、connection/response loss 没有收到明确 `200`。
- When: Flutter contract test 比对 method/path、request/response schema、headers、typed ErrorCode 与 OpenAPI SHA-256，验证 typed wrapper 的成功/错误映射，并让 widget 分别处理明确成功、明确失败和 result-unknown。
- Then: generated 边界登记两个 canonical path、相关 schema/error 定义和当前 OpenAPI hash；typed wrapper 将申请成功限制为 `202 accepted`、将完成成功限制为明确 `200 recovered + login_phone`，并保留登记的 `400/401/429/503` 错误语义；明确验证失败不得自动跳转或调用 login-or-create，但学习者可主动返回手机号登录，返回时清空 recovery code 且只携带非认证手机号表单值；result-unknown 必须锁定返回并在申请新 recovery code 后只重跑 existing-identity 恢复，cleanup in-progress/pending 也必须锁定返回且只允许完成本机清理。
- Boundary/negative: 不宣称或要求项目不存在的 generated DTO/client class；完成 request/operation 不得声明 `Idempotency-Key`，成功响应不得出现 user/session/token/revoked-count；wrapper 不得手写第二套 path、重复定义 DTO 语义、复用普通登录 request 或改变既有 phone login/verification schema；明确失败的主动返回动作不得创建账号/identity/Session/Token，result-unknown 不得返回普通登录、复用验证码或依赖 recovery-status/no-create-login endpoint，本机清理失败不得返回登录或重发已成功的服务端恢复。

### TC-CONTRACT-AUTH-RECOVERY-007 — Additive 上线、能力回滚与既有手机号登录隔离

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `compatibility-regression`
- scope: `AUTH-ACCOUNT-RECOVERY-API-001 / backend-first rollout and rollback`
- selector: `AUTH-ACCOUNT-RECOVERY-API-001/additive-compatibility-rollback -> PhoneAccountRecoveryTest`
- script_path: `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryTest.java`
- command: `mvn -f backend/pom.xml -Dtest=PhoneAccountRecoveryTest test`
- execution_owner: `backend`
- Given: 旧版客户端只调用既有 phone verification/login endpoint，账号恢复以显式启用的 additive backend capability 部署，且只复用既有身份、security epoch、Session、token 与审计结构。
- When: 在账号恢复 endpoint 存在且显式启用时运行既有手机号发码/登录、恢复 purpose 隔离和未参与恢复的已签发会话回归，再关闭客户端恢复入口但不改变旧版客户端请求。
- Then: 两个恢复 endpoint 作为 additive OpenAPI 面存在；既有 phone verification/login 的 method、path、schema、purpose 与成功/错误语义保持不变，恢复码不被普通登录接受，未参与恢复的账号与会话保持有效，关闭客户端入口不改变旧版客户端行为。
- Boundary/negative: additive 上线或入口回滚不得执行破坏性 down migration、恢复已撤销会话、删除 additive OpenAPI 面、改写普通登录验证码 purpose，或引入 recovery-specific auth store、第二套 token revoker 和 dual-read/dual-write；backend capability 自身的 fail-closed 配置行为由独立 selector 验证，不得以客户端入口开关替代。

### TC-CONTRACT-AUTH-RECOVERY-008 — Backend capability 配置默认关闭并 fail-closed

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `configuration-and-api-integration`
- scope: `AUTH-ACCOUNT-RECOVERY-API-001 / backend capability default-off and fail-closed release configuration`
- selector: `AUTH-ACCOUNT-RECOVERY-API-001/capability-fail-closed`
- script_path: `backend/src/test/java/com/speakeasy/AccountRecoveryCapabilityDisabledTest.java; backend/src/test/java/com/speakeasy/AccountRecoveryCapabilityInvalidConfigTest.java; backend/src/test/java/com/speakeasy/PhoneAccountRecoveryTest.java`
- command: `mvn -f backend/pom.xml -Dtest=AccountRecoveryCapabilityDisabledTest,AccountRecoveryCapabilityInvalidConfigTest,PhoneAccountRecoveryTest test`
- execution_owner: `backend`
- Given: 分别以缺失配置、显式 `false`、非法/无法解析值、任何非显式 `true` 值以及经过发布流程显式配置 `true` 启动 backend；记录调用前的 phone verification provider 交互、账号/identity、security epoch、Session/token 与审计快照。
- When: 在每种配置下分别调用恢复码申请和完成恢复两个 endpoint，并仅在显式 `true` 配置下提交有效的 existing-identity recovery fixture。
- Then: 缺失、`false`、非法或任意非显式 `true` 配置均在 provider 调用、identity 解析和 session/token 变更之前返回 `503 AUTH_SERVICE_UNAVAILABLE`，响应携带 `Cache-Control: no-store`、`X-Request-Id` 和可重试信号，且 provider、账号/identity、epoch、Session/token 与审计快照完全不变；只有显式 `true` 才启用既有账号恢复语义。
- Boundary/negative: 客户端 feature flag、truthy 字符串、数字或无法解析值不得启用 backend capability；关闭能力不得消费验证码、创建账号、撤销会话或写成功审计，也不得删除 additive OpenAPI method/path/schema/error 面或改变既有 phone login/verification 行为。

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
- layer: `widget-integration`
- scope: `approved content catalog browsing slice`
- selector: `content_asset_entry -> theme_card -> course_summary_list`
- script_path: `test/features/content/content_catalog_contract_test.dart`
- command: `flutter test test/features/content/content_catalog_contract_test.dart`
- Given: 已完成登录和首评的学习者从生产 `SpeakEasyAppRoot` 进入首页，AppRoot 通过正式 `CourseCatalogApi` seam 注入包含已发布可见主题、有课程主题和零课程主题的 typed fixture。
- When: 学习者点击 `content_asset_entry`，浏览全部主题并选择一个主题查看课程摘要。
- Then: 生产首页接线进入主题与课程列表，学习者可以比较所有符合条件的主题与课程摘要，并在零课程主题看到真实空状态。
- Boundary/negative: 加载失败时保留已知浏览上下文和恢复入口；`401` 提供重新认证，privacy-safe `404` 清除 learner-specific body 且不提供探测性重试，不得把失败显示成空主题或遗漏一部分已发布可见内容。

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

### TC-VS-ACC-009-1 — 手机号账号恢复用户可见闭环验证

- type: `VS-TC`
- source_vs_id: `VS-ACC-009-1`
- layer: `widget-integration`
- scope: `approved phone account recovery user-visible slice`
- selector: `account_recovery_phone_input -> account_recovery_code_request_accepted -> account_recovery_submit -> account_recovery_back | account_recovery_success | account_recovery_retry_after_unknown | account_recovery_retry_local_cleanup`
- script_path: `test/pages/phone_account_recovery_page_test.dart`
- command: `flutter test test/pages/phone_account_recovery_page_test.dart`
- execution_owner: `frontend`
- Given: 无法正常登录的学习者仍可使用原账号已绑定手机号；widget 通过 typed account-recovery API seam 接收隐私安全的发码受理、明确 `200 recovered`、明确恢复失败、result-unknown 和明确成功后本机清理失败结果。
- When: 学习者填写手机号、申请并提交 recovery 专用验证码，随后分别经历明确成功、明确失败、result-unknown 或本机清理失败。
- Then: 发码受理不暴露账号是否存在；恢复过程不提前进入已登录界面；明确失败显示统一可重试状态，不自动导航或调用普通手机号登录，学习者可通过页头/系统返回主动回到手机号登录，返回时清空 recovery code 且只保留手机号表单值；result-unknown 留在本页重新获取恢复码，cleanup in-progress/pending 留在本页完成本机清理；只有明确 `200 recovered` 且本机清理完成才显示成功态的“返回手机号登录”动作。
- Boundary/negative: 明确失败的主动返回动作本身不得创建账号/identity/Session/Token，也不得自动提交具有 auto-create 语义的普通手机号登录；result-unknown 与 cleanup in-progress/pending 必须禁用页头返回并拦截系统返回，result-unknown 不得复用验证码或推测成功，本机清理重试不得重复服务端恢复；该 widget-integration 命令不替代真实短信 provider、真机、多设备旧会话失效或重新登录后原学习/订阅数据可见性的独立 QA 证据。

## 账号恢复测试实现交接

本节只记录可执行测试责任和稳定覆盖缺口，不记录测试是否执行、运行结果或 exact commit SHA。

| TC IDs | executable test owner | target | implementation handoff |
| --- | --- | --- | --- |
| `TC-FR-ACC-001..003`, `TC-CONTRACT-AUTH-RECOVERY-001`, `002`, `005`, `007` | `backend` | `PhoneAccountRecoveryTest.java`, `PhoneAccountRecoveryProviderFailureTest.java`, `PhoneAccountRecoveryRateLimitHttpTest.java` | H2/MockMvc 覆盖存在/不存在/未绑定发码外形一致、purpose 双向隔离及消费后仍不可登录、统一隐私错误、限流/临时不可用 headers、日志与指标标签脱敏，以及显式启用时既有手机号登录兼容回归。 |
| `TC-CONTRACT-AUTH-RECOVERY-003`, `004` | `backend` | `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryPostgresTest.java` | 真实 PostgreSQL 直接查询并证明 epoch、全 Session/Refresh family/token 撤销与旧 opaque token 失效处于一次提交；身份、学习和订阅事实保持不变，身份解析、会话持久化和审计故障均完整回滚，新验证码可重试。 |
| `TC-FR-ACC-003`, `TC-CONTRACT-AUTH-RECOVERY-006`, `TC-VS-ACC-009-1` | `frontend` | `test/pages/phone_account_recovery_page_test.dart` | 明确验证失败后 `account_recovery_back` 可用；返回前清空 recovery code，只回传手机号，且不调用 login-or-create、恢复 API 或本机成功清理。result-unknown 与 cleanup 状态继续锁定返回。 |
| `TC-CONTRACT-AUTH-RECOVERY-006`, `TC-VS-ACC-009-1` | `frontend` | `test/services/api_client_contract_test.dart`, `test/pages/phone_account_recovery_page_test.dart` | 真实本地 HTTP server 驱动 typed `ApiClient` wrapper，覆盖 canonical path、payload、成功 envelope 和结构化 `401/503`；generated hash/registry 仍由同一 contract test 校验，不虚构 generated DTO/client class。 |
| `TC-CONTRACT-AUTH-RECOVERY-008` | `backend` | `backend/src/test/java/com/speakeasy/AccountRecoveryCapabilityDisabledTest.java`, `backend/src/test/java/com/speakeasy/AccountRecoveryCapabilityInvalidConfigTest.java`, `backend/src/test/java/com/speakeasy/PhoneAccountRecoveryTest.java` | 保持缺失/显式关闭配置、非法或非显式 `true` 配置和显式 `true` 启用三组 fixture；关闭态必须在 provider/identity/session/audit 副作用前返回带 `no-store`、request id 的 `503`，客户端入口不能启用 backend capability。 |
| `TC-VS-ACC-009-1` 的 provider/server 扩展 | `backend` | production-like SMS provider sandbox and backend multi-session integration suite | 另行建立真实短信 provider sandbox、验证码 purpose/消费互操作和多设备旧会话失效证据；在相应套件形成提交级证据前，现有 deterministic provider/MockMvc/PostgreSQL 命令不得被解释为生产 provider 证据。 |
| `TC-VS-ACC-009-1` 的真机扩展 | `frontend` | device integration suite | 另行建立真机/模拟器恢复、普通登录和原账号学习/订阅数据可见性路径；相应套件由 QA 绑定 exact commit 前，本目录中的 widget 命令不得被解释为真机 E2E 证据。 |

## 维护规则

- 每条保留的 FR 至少有一个最低成本 FR-TC。
- 每条保留的 VS 至少有一个用户可感知的 integration/E2E VS-TC。
- API 或 AI schema 事实变化时更新对应 Contract-TC。
- selector、脚本路径和命令是可执行定位信息；运行结果由绑定 exact commit SHA 的测试或 CI 系统保存。
