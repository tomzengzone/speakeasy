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

### TC-CONTRACT-CONTENT-COURSE-001 — 无过滤主题全集与稳定顺序

- type: `Contract-TC`
- source_contract_id: `API_CONTRACT`
- layer: `api-integration`
- scope: `CONTENT-COURSE-CATALOG-API-001 / authenticated scenario catalog projection`
- selector: `CONTENT-COURSE-CATALOG-API-001/scenario-all`
- script_path: `backend/src/test/java/com/speakeasy/content/CourseCatalogApiContractTest.java`
- command: `mvn -f backend/pom.xml -Dtest=CourseCatalogApiContractTest#scenarioAll test`
- Given: 已认证学习者的服务端投影包含多个已发布可见主题，主题 ID 顺序被打乱，其中至少一个主题没有可见 Course；另有未发布或不可见主题以及可选 query/category 过滤输入。
- When: 分别以省略过滤参数和显式过滤参数调用 `GET /scenarios`。
- Then: 无过滤调用恰好返回全部已发布可见主题并按 `scenario_id` 升序，零可见 Course 的主题仍保留；显式过滤只能在同一认证、发布和可见性全集上缩小结果，且不改变后续无过滤调用的全集语义。
- Boundary/negative: 无匹配为 `200 scenarios: []`；查询、依赖、部分读取或完整性故障必须返回 typed retryable `503`，不得伪装为空、按 Course 是否存在过滤主题或使用隐式 category/search/entitlement tier。

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
- Given: 三个内容读取操作各有成功、真实空、未认证、privacy-safe unavailable、Content query/integrity failure fixture，并对 Course 等级注入六个 CEFR 值、legacy L 值和未知值。
- When: 响应与 OpenAPI 定义的 success/error schemas 和 examples 进行契约断言。
- Then: 每个 `200` 顶层都有常量 `schema_version: 1` 与本次调用唯一的 `request_id`，合法 Course 等级仅为 A1/A2/B1/B2/C1/C2；`401 UNAUTHENTICATED`、`404 RESOURCE_NOT_FOUND` 和 `503 CONTENT_READ_UNAVAILABLE` 的状态、code、message、request_id、typed retryable details 与 schema/example 一致。
- Boundary/negative: legacy/未知等级必须拒绝；query、依赖、部分读取或 binding 故障不得变成 `200`、空集合、`PROVIDER_UNAVAILABLE` 或未登记错误 shape，内部 SQL/provider/entitlement detail 不得进入外部响应。

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
- Given: OpenAPI、generated Dart path/type registry、typed ErrorCode、hash marker 与 drift manifest 来自同一候选版本，并包含场景全集、主题课程列表和精确 CourseVersion 详情边界；既有 handwritten `/cards` 仅作为 manifest 显式登记的 legacy exception 输入。
- When: Flutter API client contract test 对 operation paths、path builders、Course schemas、CEFR/ErrorCode 类型和 OpenAPI SHA-256 进行逐项比对。
- Then: 两个新增 Course paths、参数化 builder、Course summary/detail/binding/duration/response 类型、`CONTENT_READ_UNAVAILABLE` 与严格 CEFR 均已登记，generated source、marker、manifest 和当前 OpenAPI hash 完全一致；显式登记的 legacy `/cards` 保持为非 Course API 的独立兼容例外。
- Boundary/negative: 新 Course path/type 使用 `/cards`、未在 manifest 登记的 `/cards`、缺失或额外 path/type、旧 hash、latest-version convenience path、Course-level legacy alias、`ScenarioLevel` alias 或未登记 DTO 必须使测试失败；既有 `/cards` 只有在 manifest 显式登记且未被解释为 Course API 时可保留。

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

## 维护规则

- FR 存在时，每条 approved FR 必须有适用的最低成本 FR-TC；例外必须记录 owner、原因、影响和失效期限。
- 每个实施中的 VS 必须有一个用户可感知的 integration/E2E VS-TC。
- Contract 事实变化必须新增或更新对应 Contract-TC，并选择 contract、integration、migration 或 AI-eval 等适用层级。
- selector、脚本路径和命令是可执行定位信息；运行结果由绑定 exact commit SHA 的测试或 CI 系统保存。
