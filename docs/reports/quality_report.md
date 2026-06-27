# Quality Report

## Current Status
Latest Followup-E quality state: docs-only planning/contract evidence. Followup-E Phase 0-3 planning and contract review gates are recorded, but no Followup-E backend, Flutter, OpenAPI/generated client, AI runtime, native mic/audio bytes upload, test execution, release or Product Base independent implementation review is accepted in this state.

## 2026-06-25 mvp-backend-foundation-auth TC-MVP-BE-004 Social Evidence Quality Check

Result: pass for MVP foundation-auth TC-MVP-BE-004 evidence repair only; not a commercial production identity or release-readiness pass.

Review scope:
- `backend/src/test/java/com/speakeasy/AuthControllerTest.java`
- `backend/src/test/java/com/speakeasy/AuthServiceTest.java`
- `docs/product/increments/mvp-backend-foundation-auth/test_cases.md`
- `docs/product/increments/mvp-backend-foundation-auth/traceability.md`
- `docs/reports/test_report.md`

Findings:
- Apple/WeChat login evidence now exists at endpoint level through `AuthControllerTest.socialLoginsBindToCurrentUserAndPreserveProviderNamespace`.
- `AuthService.loginSocial` now has service-level coverage for provider namespace isolation, refresh/session behavior, and invalid-input no-side-effect behavior.
- TC-MVP-BE-004 evidence now cites the focused 2026-06-25 command, script paths, result status, and this test report.
- The repair reuses the existing controller/service/session/identity test structure and does not introduce a provider SDK, mock gateway, or parallel auth stack.

Boundary:
- This closes the TC-MVP-BE-004 test-evidence mismatch for MVP test-substitute provider boundary and contract-compatible endpoints.
- This does not close production Apple identity token validation, nonce/audience/issuer checks, WeChat code/session/openid/unionid validation, scripted login detection, production test-login disabling, provider config release gates, or commercial release readiness.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AuthControllerTest,AuthServiceTest test` - passed.

## 2026-06-24 Identity Account Lifecycle 内容契约语义审查

Review ID：`PB-IDENTITY-CONTENT-CONTRACT-SEMANTIC-20260624`

结果：conditional。被审查文档可以继续作为 Product Base 模块草案输入，但在下列重要语义修正完成或明确豁免前，不应驱动 Product Base merge、acceptance criteria 生成、实现计划或 release-readiness 声明。

Reviewer：`codex/agents/document_content_contract.md`

审查文档：
- `docs/product/base/identity-account-lifecycle/requirements.md`
- `docs/product/base/identity-account-lifecycle/spec.md`

只读上下文：
- `docs/product/base/identity-account-lifecycle/traceability.md`

审查重点：对 requirements/spec 职责边界、颗粒度、清晰度、覆盖度和内容越界做内容契约与语义审查。本次不是完整追溯审查，也不验证 code evidence 是否准确。

审查-修复双门禁任务划分：
| Task | 类型 | 子章节范围 | Requirements item | Spec item | 修复/检查范围 | 当前状态 | 门禁说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1-R | Review | `IDENTITY-ACCOUNT` 账号创建与身份解析 | `IDENTITY-ACCOUNT-001..011` | `IDENTITY-SPEC-ACCOUNT-001..011` | 逐条语义审查与复审报告 | Confirmed by user | 用户已放行进入 Task 2-R。 |
| 1-F | Fix | `IDENTITY-ACCOUNT` 账号创建与身份解析 | `IDENTITY-ACCOUNT-001..011` | `IDENTITY-SPEC-ACCOUNT-001..011` | 已完成的账号/profile 语义拆分、spec 映射和 traceability 同步 | Completed before Task 2-R | 本报告保留复审结果；不再重复执行。 |
| 2-R | Review | `IDENTITY-OTP` 当前代码基线 | `IDENTITY-OTP-001..003` | `IDENTITY-SPEC-OTP-001..003` | 逐条语义审查、解决方案和修复任务拆分 | Confirmed by user | 用户已放行进入 Task 2-F。 |
| 2-F | Fix | `IDENTITY-OTP` 当前代码基线 | `IDENTITY-OTP-001..003` | `IDENTITY-SPEC-OTP-001..003` | 修复 requirements/spec 中的 baseline limitation、移除“服务层”实现表述、补足不得进入身份解析/账号创建/session 签发边界，并同步 traceability Spec Flow | Confirmed by user | 用户已放行进入 Task 3-R。 |
| 3-R | Review | `IDENTITY-OTP` 真实短信 OTP 目标态 | `IDENTITY-OTP-004..031` | `IDENTITY-SPEC-OTP-004..031` | 逐条语义审查 | Confirmed by user | 用户已确认 Requirement / Spec 分离后的 3-R 修复方案，并放行 Task 3-F。 |
| 3-F | Fix | `IDENTITY-OTP` 真实短信 OTP 目标态 | `IDENTITY-OTP-004..030, 032..037`；`OTP-TESTABILITY-001` 单独 QA 输入 | `IDENTITY-SPEC-OTP-004..030, 032..037`；`OTP-TESTABILITY-001` 单独 testability expectation | 根据 Task 3-R 发现修复 requirements/spec/必要追溯同步 | Confirmed by user | 用户已确认 3-F 修复报告，并放行 Task 4-R。 |
| 4-R | Review | `IDENTITY-PROVIDER` Apple / WeChat 第三方身份 | `IDENTITY-PROVIDER-001..004` | `IDENTITY-SPEC-PROVIDER-001..004` | 逐条检查 provider baseline limitation 和目标态边界 | Confirmed by user | 用户已确认 4-R 审查表，并放行 Task 4-F。 |
| 4-F | Fix | `IDENTITY-PROVIDER` Apple / WeChat 第三方身份 | `IDENTITY-PROVIDER-001..004` | `IDENTITY-SPEC-PROVIDER-001..004` | 根据 Task 4-R 发现修复 requirements/spec/必要追溯同步 | Confirmed by user | 用户已确认 4-F 修复报告，并放行 Task 5-R。 |
| 5-R | Review | `IDENTITY-LOGIN` 登录与 session 签发 | `IDENTITY-LOGIN-001..007` | `IDENTITY-SPEC-LOGIN-001..007` | 逐条语义审查 | Confirmed by user | 用户已确认 5-R 审查表，并放行 Task 5-F。 |
| 5-F | Fix | `IDENTITY-LOGIN` 登录与 session 签发 | `IDENTITY-LOGIN-001..007` | `IDENTITY-SPEC-LOGIN-001..007` | 根据 Task 5-R 发现修复 requirements/spec/必要追溯同步 | Confirmed by user | 用户已确认 5-F 修复复审，并放行 Task 6-R。 |
| 6-R | Review | `IDENTITY-TOKEN` Access / refresh token 生命周期 | `IDENTITY-TOKEN-001..012` | `IDENTITY-SPEC-TOKEN-001..012` | 逐条语义审查 | Confirmed by user | 用户已确认 6-R 审查表，并放行 Task 6-F。 |
| 6-F | Fix | `IDENTITY-TOKEN` Access / refresh token 生命周期 | `IDENTITY-TOKEN-001..012` | `IDENTITY-SPEC-TOKEN-001..012` | 根据 Task 6-R 发现修复 requirements/spec/必要追溯同步 | Confirmed by user | 用户已确认 6-F 修复复审，并放行 Task 7-R。 |
| 7-R | Review | `IDENTITY-ME` 当前用户与 profile gate state | `IDENTITY-ME-001..008` | `IDENTITY-SPEC-ME-001..008` | 逐条语义审查 | Confirmed by user | 用户已确认 ME 审查发现，并要求执行模块边界调整与 Task 7-F。 |
| 7-F | Fix | `IDENTITY-ME` 当前用户与 profile 模块边界修复 | `IDENTITY-ME-001..006`；删除出本模块：原 `IDENTITY-ME-007..008` | `IDENTITY-SPEC-ME-001..006`；删除出本模块：原 `IDENTITY-SPEC-ME-007..008` | 根据 Task 7-R 发现修复 ME requirements/spec/必要追溯同步，并删除不属于 Identity 模块的首评提交推进和首页下一步动作 | Confirmed by user | 用户已确认 7-F 修复复审，并放行 Task 8-R。 |
| 8-R | Review | `IDENTITY-LINK` 身份绑定与解绑 | `IDENTITY-LINK-001..003` | `IDENTITY-SPEC-LINK-001..003` | 逐条语义审查 | Confirmed by user | 用户已确认 LINK 审查发现，并放行 Task 8-F。 |
| 8-F | Fix | `IDENTITY-LINK` 初始登录身份绑定与身份键解析 | `IDENTITY-LINK-001..003` | `IDENTITY-SPEC-LINK-001..003` | 根据 Task 8-R 发现修复 requirements/spec/必要追溯同步 | Confirmed by user | 用户已确认 8-F 修复复审，并放行 Task 9-R。 |
| 9-R | Review | `IDENTITY-LOGOUT` 退出登录 | `IDENTITY-LOGOUT-001..005` | `IDENTITY-SPEC-LOGOUT-001..005` | 逐条语义审查 | Confirmed by user | 用户已确认 9-R 审查表，并放行 Task 9-F。 |
| 9-F | Fix | `IDENTITY-LOGOUT` 退出登录 | `IDENTITY-LOGOUT-001..005` | `IDENTITY-SPEC-LOGOUT-001..005` | 根据 Task 9-R 发现修复 requirements/spec/必要追溯同步 | Confirmed by user | 用户已确认 9-F 修复复审，并放行 Task 10-R。 |
| 10-R | Review | `IDENTITY-DELETE` 账号删除与生命周期状态 | `IDENTITY-DELETE-001..020` | `IDENTITY-SPEC-DELETE-001..020` | 逐条语义审查 | Passed by main+independent agents | 独立 agent 已复核通过，按用户更新后的门禁规则自动进入 Task 10-F。 |
| 10-F | Fix | `IDENTITY-DELETE` 账号删除与生命周期状态 | `IDENTITY-DELETE-001..020` | `IDENTITY-SPEC-DELETE-001..020` | 根据 Task 10-R 发现修复 requirements/spec/必要追溯同步 | Passed by main+independent agents | 独立 agent 已复核通过，按用户更新后的门禁规则自动进入 Task 11-R。 |
| 11-R | Review | `IDENTITY-RISK` 风控、限流与防滥用 | `IDENTITY-RISK-001..003` | `IDENTITY-SPEC-RISK-001..003` | 逐条语义审查 | Passed by main+independent agents | 独立 agent 已复核通过，按用户更新后的门禁规则自动进入 Task 11-F。 |
| 11-F | Fix | `IDENTITY-RISK` 风控、限流与防滥用 | `IDENTITY-RISK-001..003` | `IDENTITY-SPEC-RISK-001..003` | 根据 Task 11-R 发现修复 requirements/spec/必要追溯同步 | Passed by main+independent agents | 独立 agent 已复核通过，按用户更新后的门禁规则自动进入 Task 12-R。 |
| 12-R | Review | `IDENTITY-AUDIT` 审计、隐私与合规 | `IDENTITY-AUDIT-001..006` | `IDENTITY-SPEC-AUDIT-001..006` | 逐条语义审查 | Passed by main+independent agents | 独立 agent 已复核通过，按用户更新后的门禁规则自动进入 Task 12-F。 |
| 12-F | Fix | `IDENTITY-AUDIT` 审计、隐私与合规 | `IDENTITY-AUDIT-001..006` | `IDENTITY-SPEC-AUDIT-001..006` | 根据 Task 12-R 发现修复 requirements/spec/必要追溯同步 | Passed by main+independent agents | 独立 agent 已复核通过，按用户更新后的门禁规则自动进入 Task 13-R。 |
| 13-R | Review | `IDENTITY-RELEASE` 测试替身与生产环境 release gate | 无可归档 requirement item | `IDENTITY-SPEC-RELEASE-000` | 检查无基线边界是否被误写为已实现 | Passed by main+independent agents | 独立 agent 已复核通过，按用户更新后的门禁规则自动进入 Task 13-F。 |
| 13-F | Fix | `IDENTITY-RELEASE` 测试替身与生产环境 release gate | 无可归档 requirement item | `IDENTITY-SPEC-RELEASE-000` | 根据 Task 13-R 发现修复 release boundary/spec/必要追溯同步 | Passed by main+independent agents | 独立 agent 已复核通过，本轮任务完成。 |

门禁执行状态：Task 1-R、Task 2-R、Task 2-F、Task 3-R、Task 3-F、Task 4-R、Task 4-F、Task 5-R、Task 5-F、Task 6-R、Task 6-F、Task 7-R、Task 7-F、Task 8-R 与 Task 8-F、Task 9-R 与 Task 9-F 已由用户放行；Task 10-R、Task 10-F、Task 11-R、Task 11-F、Task 12-R、Task 12-F、Task 13-R 与 Task 13-F 已由主 agent 与独立 agent 一致放行；本轮 Product Base identity 内容契约审查/修复任务完成。`spec.md` 的公共状态、输入输出与错误信号定义已随对应子章节交叉审查；本轮未生成 AC/TC，未修改代码，未新增 release requirement traceability 行。

发现：
- 未发现阻止两份文件继续作为 Draft 模块 artifact 存在的 blocker。两份文档都能区分 `Code baseline` 和 `Target pending` OTP 行为，并多次避免把目标态 OTP 写成已实现。
- Fixed follow-up：`requirements.md` 曾写明本次不生成 `spec.md` 且 `Spec Flow` 后续补齐，但 `spec.md` 已存在。已在本次修正中同步 workflow-state 语言，明确 `spec.md` 已作为 Draft 规格生成，AC/TC/test evidence 仍待后续补齐。
- Important：部分 requirement item 混入了其他内容层级。`IDENTITY-OTP-031` 是测试设计要求，应放到 QA/test-case 或 testability contract，不应放在 Product Base requirements；`IDENTITY-DELETE-006` 命名了实现 runner，而不是业务删除义务；`IDENTITY-OTP-021` 和若干删除项使用 class/record 风格名称，除非 domain model 已接受这些术语，否则应改写为业务或领域对象。
- Important：`spec.md` 主要通过 Ref ID 对 requirements 做 1:1 映射，但还缺少足够的流程级分解。AC/TC 生成前，应为登录、OTP send/verify、refresh、logout、当前用户/profile update、账号删除/retry、audit query 补充显式流程段，包含前置条件、触发、状态转移、输出、typed failure、幂等性和后置条件。
- Important：Apple/WeChat provider 当前把 provider token hash 作为 identity subject。只有在明确标记为 current-code-baseline limitation 时才可接受；不能把它当作稳定目标态 identity 语义。Product Base merge 前应有独立的目标态 provider validation requirement/spec。
- Important：账号删除语义列出了大量 cleanup target，但产品/spec 层面的 lifecycle model 仍不完整。Spec 应定义 deletion job state、转移触发、partial failure 行为、retry/idempotency 关系、跨域 cleanup ownership，以及每个状态对应的 audit event。
- Important：release-gate 语言不一致。requirements 的 scope 说本模块不承载 identity 专属 release gate implementation，但 feature mapping 又把生产 release gate 写入模块候选边界。除非 Product Manager 明确接受为产品模块范围，否则 release gate 应保留为下游 DevOps/Security target boundary。
- Suggestion：按 requirement family 增加紧凑 status column 或小节，让 `Code baseline`、`Target pending`、`No accepted baseline` 不必依赖段落说明才能识别。
- Suggestion：补清 terms/privacy consent 的语义来源。文档要求已接受条款，但也说明 consent persistence 未实现，因此 consent 的 source of truth 仍不清楚。

下游 AC/TC 或 Product Base merge 前的必需修正：
- 已完成：同步 `requirements.md` 的 workflow-state 语言和 `spec.md` 已存在这一事实。
- 移出或重写测试专属、实现 runner、class name 和 record-list 风格语句，让 requirements 保持业务语义优先。
- 在 `spec.md` 补充流程级行为段；保留现有 spec item table 作为映射证据，而不是唯一行为契约。
- 明确把未校验 Apple/WeChat provider-token-hash 登录标记为 baseline limitation。
- 在 spec 层定义账号删除 lifecycle state 与 failure/retry 语义，或先路由到 domain model 后再生成 acceptance/test。

### IDENTITY-ACCOUNT 第一个子章节逐条语义审查与修复复审

审查范围：
- 初审 Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-ACCOUNT-001..009`
- 初审 Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-ACCOUNT-001..009`
- 修复后 Requirements：`IDENTITY-ACCOUNT-001..011`
- 修复后 Spec：`IDENTITY-SPEC-ACCOUNT-001..011`

语义审查定义：
- 颗粒度：一个 item 只表达一个业务规则、状态转移、可观察结果或安全约束；如会产生多个独立验收结论，应拆分。
- 清晰度：主体、触发条件、状态、核心动作、结果或错误边界必须明确。
- 覆盖度：不能只做 ID 映射；需要覆盖主流程、异常分支、权限/安全、关键状态转移、跨域依赖和非目标边界。

Requirements 初审逐条结论（已在本轮修复）：
| Requirement | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 解决方案 |
| --- | --- | --- | --- | --- | --- |
| `IDENTITY-ACCOUNT-001` | 通过 | 条件通过：触发是手机号登录，但需避免被误读为目标态 E.164 规范化 | 已由非目标说明 E.164 未归档 | Suggestion | 改为“当前代码基线的手机号登录解析使用 trim 后手机号作为 `phone` subject；不等同于目标态 E.164 规范化”。 |
| `IDENTITY-ACCOUNT-002` | 通过 | 条件通过：“已有用户”应明确为身份键绑定的账号 | 账号状态校验由 login 需求覆盖 | Suggestion | 改为“当身份来源和 subject 组成的身份键已绑定账号时，解析到该账号；账号可登录状态由登录需求处理”。 |
| `IDENTITY-ACCOUNT-003` | 通过 | 不足：缺少创建账号的前置条件，容易和目标态 OTP send 阶段冲突 | 未明确 OTP 验证成功前不得创建账号 | Important | 增加前置条件：“仅在身份凭证校验通过后；目标态手机号 OTP 仅在 OTP 验证成功后触发创建”。 |
| `IDENTITY-ACCOUNT-004` | 通过 | 通过 | 覆盖新账号生命周期初始状态 | Pass | 可保留。 |
| `IDENTITY-ACCOUNT-005` | 通过 | 通过 | 覆盖 access-onboarding 初始状态 | Pass | 可保留。 |
| `IDENTITY-ACCOUNT-006` | 通过 | 条件通过：默认 locale 触发条件隐含为新账号创建 | 覆盖默认本地化状态 | Suggestion | 可改为“新用户账号创建时，在未提供已接受 locale 的情况下默认初始化为 `zh-CN`”。 |
| `IDENTITY-ACCOUNT-007` | 通过 | 不足：“初始登录身份”缺少来源，可能被误解为任意身份 | 覆盖新账号与登录身份绑定，但不够精确 | Important | 改为“新账号必须绑定本次通过认证的登录身份作为初始登录身份”。 |
| `IDENTITY-ACCOUNT-008` | 不通过：同时表达 profile 创建、目标等级默认值、每日分钟数默认值 | 清晰，但包含多个独立可验收结果 | 覆盖跨 profile 依赖，但粒度过粗 | Important | 拆分为默认 profile 创建、默认目标等级 `L1`、默认每日分钟数 `10` 三条独立 item。 |
| `IDENTITY-ACCOUNT-009` | 通过 | 条件通过：“防止”缺少系统行为和冲突结果 | 覆盖身份唯一性安全约束，但缺少冲突分支 | Important | 改为“同一 provider+subject 的有效身份绑定最多对应一个账号；发生冲突时不得创建或绑定重复身份”。 |

Spec 初审逐条结论（已在本轮修复）：
| Spec item | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 解决方案 |
| --- | --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-ACCOUNT-001` | 通过 | 条件通过：同 requirement 001，需标明当前代码基线边界 | 覆盖输入映射，但非目标边界不在 item 内 | Suggestion | 增加“current code baseline，不等同于 E.164 target normalization”的限定。 |
| `IDENTITY-SPEC-ACCOUNT-002` | 通过 | 条件通过：解析结果明确，但账号状态校验边界隐含 | 账号状态由 login spec 覆盖 | Suggestion | 增加“账号 active/inactive 校验由 `IDENTITY-SPEC-LOGIN-004` 处理”。 |
| `IDENTITY-SPEC-ACCOUNT-003` | 通过 | 不足：缺少已通过身份校验这个前置条件 | 未覆盖目标态 OTP 创建时机 | Important | 改为“当身份凭证已验证且未解析到身份键时，创建账号；OTP target 仅在 verify success 后进入本 spec”。 |
| `IDENTITY-SPEC-ACCOUNT-004` | 通过 | 通过 | 覆盖账号状态转移 | Pass | 可保留。 |
| `IDENTITY-SPEC-ACCOUNT-005` | 通过 | 通过 | 覆盖 onboarding 初始状态 | Pass | 可保留。 |
| `IDENTITY-SPEC-ACCOUNT-006` | 通过 | 条件通过：默认条件可更清楚 | 覆盖 locale 输出 | Suggestion | 补充“新账号创建时默认 locale”。 |
| `IDENTITY-SPEC-ACCOUNT-007` | 通过 | 条件通过：已写 active，但初始身份来源可更明确 | 覆盖账号与身份绑定 | Suggestion | 改为“绑定本次通过认证的 provider+subject，并使该身份进入 active”。 |
| `IDENTITY-SPEC-ACCOUNT-008` | 不通过：`PROFILE-DEFAULT-L1-10` 是组合输出 | 清晰，但不是单一行为契约 | 覆盖 profile 依赖，但无法细分 AC/TC | Important | 拆成 profile 创建、target level 默认、daily minutes 默认三个 spec item。 |
| `IDENTITY-SPEC-ACCOUNT-009` | 通过 | 不足：引用错误但没有说明冲突处理结果 | 覆盖唯一性，但失败路径不完整 | Important | 增加“保持既有绑定不变、不得创建重复身份、返回 `ACCOUNT-ERR-DUPLICATE-IDENTITY`”。 |

已执行改写方案：
```text
Requirements:
- IDENTITY-ACCOUNT-001 当前代码基线的手机号登录解析中，系统必须使用去除前后空白后的手机号作为 `phone` 身份来源的 subject；该行为不等同于目标态 E.164 规范化。
- IDENTITY-ACCOUNT-002 当身份来源和身份 subject 组成的身份键已绑定用户账号时，系统必须解析到该绑定账号；账号可登录状态由登录需求处理。
- IDENTITY-ACCOUNT-003 当身份凭证校验通过且未解析到已有身份时，系统必须创建新的用户账号；目标态手机号 OTP 只能在 OTP 验证成功后触发账号创建。
- IDENTITY-ACCOUNT-004 新用户账号必须初始化为 `active` 账号状态。
- IDENTITY-ACCOUNT-005 新用户账号必须初始化为 `incomplete` 首评状态。
- IDENTITY-ACCOUNT-006 新用户账号创建时必须默认初始化 locale 为 `zh-CN`。
- IDENTITY-ACCOUNT-007 新用户账号必须绑定本次通过认证的登录身份作为初始登录身份。
- IDENTITY-ACCOUNT-008 新用户账号必须同时创建默认 profile。
- IDENTITY-ACCOUNT-009 同一身份来源和身份 subject 的有效身份绑定最多只能对应一个用户账号；冲突时系统不得创建或绑定重复身份。
- IDENTITY-ACCOUNT-010 默认 profile 的目标等级必须为 `L1`。
- IDENTITY-ACCOUNT-011 默认 profile 的每日分钟数必须为 `10`。

Spec:
- IDENTITY-SPEC-ACCOUNT-001 手机号登录解析身份时，系统必须在 current code baseline 下使用 `ACCOUNT-IN-PHONE-SUBJECT` 作为 `phone` provider 的 subject；该规格不表示目标态 E.164 normalization。
- IDENTITY-SPEC-ACCOUNT-002 当存在 `ACCOUNT-IN-IDENTITY-KEY` 对应身份时，系统必须解析到该身份绑定的已有账号；账号 active/inactive 登录校验由 `IDENTITY-SPEC-LOGIN-004` 处理。
- IDENTITY-SPEC-ACCOUNT-003 当身份凭证已验证且未解析到 `ACCOUNT-IN-IDENTITY-KEY` 时，系统必须创建新的用户账号；目标态 OTP 只在 verify success 后进入本创建流程。
- IDENTITY-SPEC-ACCOUNT-004 新用户账号创建后必须进入 `ACCOUNT-STATE-ACTIVE`。
- IDENTITY-SPEC-ACCOUNT-005 新用户账号创建后必须进入 `ONBOARDING-STATE-INCOMPLETE`。
- IDENTITY-SPEC-ACCOUNT-006 新用户账号创建后必须初始化 locale 为 `zh-CN`。
- IDENTITY-SPEC-ACCOUNT-007 新用户账号创建时必须绑定本次通过认证的 provider+subject，并使该初始登录身份进入 active。
- IDENTITY-SPEC-ACCOUNT-008 新用户账号创建时必须同时创建默认 profile。
- IDENTITY-SPEC-ACCOUNT-009 当同一 `ACCOUNT-IN-IDENTITY-KEY` 试图绑定多个用户时，系统必须保持既有绑定不变，不得创建重复身份，并返回 `ACCOUNT-ERR-DUPLICATE-IDENTITY`。
- IDENTITY-SPEC-ACCOUNT-010 默认 profile 的 target level 必须为 `L1`。
- IDENTITY-SPEC-ACCOUNT-011 默认 profile 的 daily minutes 必须为 `10`。
```

执行情况：
- 已执行：将 `IDENTITY-ACCOUNT-008` / `IDENTITY-SPEC-ACCOUNT-008` 拆分为默认 profile 创建、默认 target level、默认 daily minutes 三个独立语义 item。
- 已执行：新增 `IDENTITY-ACCOUNT-010..011` 和 `IDENTITY-SPEC-ACCOUNT-010..011`。
- 已执行：同步更新 `spec.md` 的 `IDENTITY-ACCOUNT-001..011 -> IDENTITY-SPEC-ACCOUNT-001..011` 映射。
- 已执行：同步更新 `traceability.md` 的账号创建子章节 Spec Flow，并为 `IDENTITY-ACCOUNT-010..011` 新增追溯行。

执行后复审结果：
| 复审对象 | 颗粒度 | 清晰度 | 覆盖度 | 结论 |
| --- | --- | --- | --- | --- |
| `IDENTITY-ACCOUNT-001..011` | Pass：每条只表达一个业务规则、状态、默认值或安全约束 | Pass：baseline 边界、认证前置、默认值触发、身份唯一性冲突行为已明确 | Pass：覆盖手机号 subject baseline、身份解析、账号创建、账号/onboarding/locale/profile 初始状态、身份绑定和唯一性约束 | 子章节 requirements 语义问题关闭 |
| `IDENTITY-SPEC-ACCOUNT-001..011` | Pass：`PROFILE-DEFAULT-L1-10` 组合输出已拆分 | Pass：spec item 的前置条件、跨 spec 边界、错误输出和默认输出已明确 | Pass：与 requirements 形成 1:1 映射，并补齐 traceability 的账号章节 Spec Flow | 子章节 spec 语义问题关闭 |
| `traceability.md` 账号创建行 | Pass：新增 requirement/spec ID 均有独立行 | Pass：`Spec Flow` 已从 TBD 替换为具体 spec ID | Pass：账号创建子章节覆盖 `001..011`；AC/TC 仍按当前流程标记后续补齐 | 账号创建追溯同步问题关闭 |

复审验证：
- `identity account semantic sync check`：passed，确认 `IDENTITY-ACCOUNT-001..011`、`IDENTITY-SPEC-ACCOUNT-001..011`、spec 映射和 traceability 行全部存在。
- `PROFILE-DEFAULT-L1-10` 组合 Ref ID 已从 `spec.md` 移除，替换为 `PROFILE-DEFAULT`、`PROFILE-DEFAULT-TARGET-LEVEL-L1`、`PROFILE-DEFAULT-DAILY-MINUTES-10`。
- 本次复审只关闭 `IDENTITY-ACCOUNT` 子章节的语义表达问题；不批准 Product Base merge、AC/TC 完成、测试证据或代码证据准确性。

残余风险：
- 本次未检查 backend code，也未验证 traceability 中 code evidence 是否准确。
- 本次不批准 Product Base root merge、release readiness、acceptance criteria、test cases 或 implementation start。

### IDENTITY-OTP 当前代码基线逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-OTP-001..003`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-OTP-001..003`
- 交叉引用 Ref ID：`OTP-IN-PHONE-RAW`、`OTP-IN-CODE-RAW`、`OTP-ERR-VALIDATION`
- 只读上下文：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-OTP-001..003`

本轮结果：conditional pass。Task 2 没有 blocker；requirements/spec 可继续作为 Draft 输入。但在生成 AC/TC 或 Product Base merge 前，应把实现层表述改为系统行为，并明确当前代码基线只覆盖手机号登录请求的输入存在性校验，不代表真实短信 OTP 发送、challenge、验证码正确性、过期、一次性消费或重放控制已实现。

Requirements 逐条结论：
| Requirement | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 解决方案 |
| --- | --- | --- | --- | --- | --- |
| `IDENTITY-OTP-001` | Pass：只表达手机号字段存在性要求 | 条件通过：需明确这是当前代码基线的手机号登录请求输入校验，不是目标态 OTP send/verify 入口 | 条件通过：覆盖手机号缺失主失败前置，但不覆盖格式、E.164、国家地区或真实 OTP challenge | Suggestion | 改为“当前代码基线的手机号登录请求必须提供非空手机号字段；该要求只代表输入存在性校验，不代表 E.164 规范化、短信发送或 OTP challenge 已实现”。 |
| `IDENTITY-OTP-002` | Pass：只表达验证码字段存在性要求 | 条件通过：需明确“验证码字段”只按当前代码基线做存在性校验 | 条件通过：覆盖验证码缺失前置，但不覆盖验证码正确性、过期、一次性消费或重放控制 | Suggestion | 改为“当前代码基线的手机号登录请求必须提供非空验证码字段；该要求不代表验证码正确性、过期、一次性消费或重放控制已实现”。 |
| `IDENTITY-OTP-003` | 条件通过：手机号为空或验证码为空共享同一拒绝行为，可保留为一个失败规则 | 不足：“服务层”是实现层边界，不是 requirements 语义；“拒绝”缺少后置结果 | 条件通过：覆盖缺失输入失败路径，但未说明不得继续身份解析、账号创建或 session 签发 | Important | 改为“当手机号或验证码字段为空时，系统必须拒绝当前手机号登录请求并停止登录处理；不得继续身份解析、账号创建或 session 签发”。 |

Spec 逐条结论：
| Spec item | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 解决方案 |
| --- | --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-OTP-001` | Pass：只表达 `OTP-IN-PHONE-RAW` 输入存在性 | 条件通过：Ref ID 已说明当前代码基线只要求非空，但 item 本身可更明确 baseline limitation | 条件通过：可下沉为 AC/TC 的输入校验；不覆盖目标态手机号规范化 | Suggestion | 改为“current code baseline 下，手机号登录请求必须包含非空 `OTP-IN-PHONE-RAW`；该 item 不表示 `OTP-IN-PHONE-E164` 或 OTP challenge 已实现”。 |
| `IDENTITY-SPEC-OTP-002` | Pass：只表达 `OTP-IN-CODE-RAW` 输入存在性 | 条件通过：Ref ID 已说明当前代码基线只要求非空，但 item 本身可更明确不验证 OTP 正确性 | 条件通过：可下沉为 AC/TC 的输入校验；不覆盖过期、消费或重放 | Suggestion | 改为“current code baseline 下，手机号登录请求必须包含非空 `OTP-IN-CODE-RAW`；该 item 不表示验证码正确性、过期、一次性消费或重放控制已实现”。 |
| `IDENTITY-SPEC-OTP-003` | 条件通过：两个输入缺失场景共用同一错误输出，可保留一个 spec item | 不足：“服务层”会把 spec 写成实现层约束；停止处理范围应更明确 | 条件通过：覆盖 `OTP-ERR-VALIDATION`，但缺少不进入账号创建/session 签发的后置边界 | Important | 改为“当 `OTP-IN-PHONE-RAW` 或 `OTP-IN-CODE-RAW` 为空时，系统必须返回 `OTP-ERR-VALIDATION`，停止手机号登录处理，并不得进入身份解析、账号创建或 session 签发流程”。 |

建议改写方案（本轮未写入 requirements/spec 原文）：
```text
Requirements:
- IDENTITY-OTP-001 当前代码基线的手机号登录请求必须提供非空手机号字段；该要求只代表输入存在性校验，不代表 E.164 规范化、短信发送或 OTP challenge 已实现。
- IDENTITY-OTP-002 当前代码基线的手机号登录请求必须提供非空验证码字段；该要求不代表验证码正确性、过期、一次性消费或重放控制已实现。
- IDENTITY-OTP-003 当手机号或验证码字段为空时，系统必须拒绝当前手机号登录请求并停止登录处理；不得继续身份解析、账号创建或 session 签发。

Spec:
- IDENTITY-SPEC-OTP-001 current code baseline 下，手机号登录请求必须包含非空 `OTP-IN-PHONE-RAW`；该 item 不表示 `OTP-IN-PHONE-E164` 或 OTP challenge 已实现。
- IDENTITY-SPEC-OTP-002 current code baseline 下，手机号登录请求必须包含非空 `OTP-IN-CODE-RAW`；该 item 不表示验证码正确性、过期、一次性消费或重放控制已实现。
- IDENTITY-SPEC-OTP-003 当 `OTP-IN-PHONE-RAW` 或 `OTP-IN-CODE-RAW` 为空时，系统必须返回 `OTP-ERR-VALIDATION`，停止手机号登录处理，并不得进入身份解析、账号创建或 session 签发流程。
```

执行情况：
- 已执行：完成 `IDENTITY-OTP-001..003` 和 `IDENTITY-SPEC-OTP-001..003` 的逐条内容契约语义审查。
- 已执行：确认 Task 2 未提前审查 `IDENTITY-OTP-004..031` 目标态需求。
- 已关闭：用户已确认 Task 2-R 修复方案；Task 2-F 已按本节解决方案修改 `requirements.md`、`spec.md` 和 `traceability.md`，见下方修复复审。

执行后复审结果：
| 复审对象 | 颗粒度 | 清晰度 | 覆盖度 | 结论 |
| --- | --- | --- | --- | --- |
| `IDENTITY-OTP-001..002` | Pass：每条只表达一个输入存在性要求 | Conditional：需要在 item 内补强 current-code-baseline limitation | Conditional：只覆盖当前登录请求输入存在性，不覆盖目标态 OTP 能力 | 可作为 Draft 输入，建议修文后再生成 AC/TC |
| `IDENTITY-OTP-003` | Conditional：两个缺失输入共享同一失败行为，可保留一个 item | Important：应移除“服务层”实现表述并补足停止处理后置边界 | Conditional：失败路径存在，但缺少不得创建账号或 session 的明确边界 | 建议修文后再生成 AC/TC |
| `IDENTITY-SPEC-OTP-001..003` | Pass/Conditional：输入存在性和失败输出可以独立验收 | Important：`IDENTITY-SPEC-OTP-003` 应避免实现层语言 | Conditional：可映射 AC/TC，但需补足与账号创建/session 签发的边界 | 建议修文后再生成 AC/TC |
| `traceability.md` OTP code baseline 行 | Not reviewed as traceability gate | Not reviewed as traceability gate | Risk：`Spec Flow` 仍为 `TBD - 后续补齐`，与已存在 spec ID 不同步 | 后续应更新为 `IDENTITY-SPEC-OTP-001..003`，但本轮不改追溯矩阵 |

残余风险：
- 本次未检查 backend code，也未验证 traceability 中 code evidence 是否准确。
- 本次不批准 Product Base root merge、release readiness、acceptance criteria、test cases 或 implementation start。
- 已关闭：用户已确认 Task 2-F 修复报告并放行 Task 3-R。

### IDENTITY-OTP 当前代码基线 2-F 修复复审

修复范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-OTP-001..003`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-OTP-001..003`
- Traceability：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-OTP-001..003` 的 `Spec Flow`

已执行修复：
| 修复项 | 文件 | 修复内容 | 复审结论 |
| --- | --- | --- | --- |
| `IDENTITY-OTP-001` | `requirements.md` | 增加 current-code-baseline 限定，明确只代表手机号字段输入存在性校验，不代表 E.164、短信发送或 OTP challenge 已实现。 | Pass |
| `IDENTITY-OTP-002` | `requirements.md` | 增加 current-code-baseline 限定，明确只代表验证码字段输入存在性校验，不代表验证码正确性、过期、一次性消费或重放控制已实现。 | Pass |
| `IDENTITY-OTP-003` | `requirements.md` | 移除“服务层”实现层表述，改为系统拒绝手机号登录请求并停止处理；补足不得继续身份解析、账号创建或 session 签发。 | Pass |
| `IDENTITY-SPEC-OTP-001` | `spec.md` | 增加 current-code-baseline 限定，明确不表示 `OTP-IN-PHONE-E164` 或 OTP challenge 已实现。 | Pass |
| `IDENTITY-SPEC-OTP-002` | `spec.md` | 增加 current-code-baseline 限定，明确不表示验证码正确性、过期、一次性消费或重放控制已实现。 | Pass |
| `IDENTITY-SPEC-OTP-003` | `spec.md` | 移除“服务层”实现层表述，明确返回 `OTP-ERR-VALIDATION`、停止手机号登录处理，并不得进入身份解析、账号创建或 session 签发流程。 | Pass |
| `IDENTITY-OTP-001..003` traceability | `traceability.md` | 将 `Spec Flow` 从 `TBD - 后续补齐` 分别同步为 `IDENTITY-SPEC-OTP-001..003`；`AC` 与 `TC` 继续保留 `TBD - 后续补齐`。 | Pass |

修复后复审结果：
| 复审对象 | 颗粒度 | 清晰度 | 覆盖度 | 结论 |
| --- | --- | --- | --- | --- |
| `IDENTITY-OTP-001..003` | Pass：每条只表达输入存在性或缺失输入失败处理；未混入目标态 OTP 能力 | Pass：current-code-baseline、未实现目标态边界和失败后置条件已明确 | Pass：覆盖当前代码基线手机号登录请求输入校验与缺失输入失败路径；不误承诺真实 OTP 能力 | Task 2-F requirements 修复关闭 |
| `IDENTITY-SPEC-OTP-001..003` | Pass：输入项和失败输出均可独立验收 | Pass：已移除实现层语言，补足 `OTP-ERR-VALIDATION` 与停止处理边界 | Pass：可作为后续 AC/TC 上游；目标态 OTP 仍由 Task 3-R 单独审查 | Task 2-F spec 修复关闭 |
| `traceability.md` OTP code baseline 行 | Pass：`IDENTITY-OTP-001..003` 均映射到具体 spec ID | Pass：AC/TC 未生成前继续显式标记后续补齐 | Pass：Spec 链路同步问题关闭；不声明 AC/TC 或测试证据完成 | Task 2-F traceability 同步关闭 |

修复验证：
- `IDENTITY-OTP-001..003` 均保留在当前代码基线小节，未移动或扩展到目标态 OTP。
- `IDENTITY-SPEC-OTP-001..003` 均保留 `Code baseline` 状态，未改动 `IDENTITY-SPEC-OTP-004..031`。
- `traceability.md` 仅同步 `Spec Flow`，未伪造 AC、TC 或测试证据。
- 本次修复不批准 Product Base root merge、release readiness、acceptance criteria、test cases 或 implementation start。

2-F 修复完成时门禁状态（历史记录；当前状态以本文顶部任务表和 3-F 门禁表为准）：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 2-R | Confirmed by user | 已放行并完成 Task 2-F。 |
| Task 2-F | Confirmed by user | 已放行并执行 Task 3-R。 |
| Task 3-R | Completed - pending user confirmation | 用户确认 Task 3-R 审查表前，不得执行 Task 3-F。 |

### IDENTITY-OTP 真实短信 OTP 目标态 3-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-OTP-004..031`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-OTP-004..031`
- 只读上下文：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-OTP-004..031`

本轮结果：conditional。目标态 OTP 需求和规格可以继续作为 Draft target 输入，但在进入 3-F 修复、AC/TC 生成、实现计划或 Product Base merge 前，必须先处理下表中的内容边界、语义粒度、清晰度和 traceability 同步问题。本轮不修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文。

按文档定位拆分的确认表：
| Item | 级别 | Requirement 问题 | Requirement 修复方案 | Spec 问题 | Spec 修复方案 | Traceability / Cross-doc 修复 |
| --- | --- | --- | --- | --- | --- | --- |
| `OTP-004` | Suggestion | 需求只说“流程入口”，未定义业务范围内哪些 OTP 入口必须统一处理手机号，也未写非法号码的业务后果。 | 写成目标态业务规则：所有接收手机号的 OTP 入口必须先完成 E.164 规范化；非法或不支持号码不得进入 OTP 登录或注册流程。 | 规格未定义 send/verify 等入口的输入处理、typed error 和后置状态。 | 写成行为契约：接收手机号时输出 `OTP-IN-PHONE-E164`；失败返回 `OTP-ERR-INVALID-PHONE`，且不创建 challenge/session。 | 无。 |
| `OTP-005` | Suggestion | 需求应表达“请求 OTP 不等于登录成功或账号创建”的业务边界，但不应细写 challenge 创建细节过多。 | 改为：用户请求 OTP 只启动一次待验证的 OTP 挑战，不得完成账号创建或认证会话。 | 规格需要定义前置校验通过后创建 challenge，provider 失败时不创建可验证 challenge。 | 写明手机号、consent、频控、风险和 provider 前置校验通过后进入 `OTP-STATE-CHALLENGE-ACTIVE`；与 `OTP-023` 对齐。 | 无。 |
| `OTP-006` | Suggestion | 需求列出 challenge 业务绑定对象即可，不应定义过细输入结构。 | 保留“challenge 绑定手机号、purpose、请求上下文和过期时间”的业务要求。 | 规格需定义 `OTP-IN-CONTEXT` 的最低字段和缺失处理。 | 定义 context 至少包含可用 request/client/device 标识；不可用时记录 absent，不改变 challenge 语义。 | 无。 |
| `OTP-007` | Important | 需求把安全来源、默认格式、配置下限混成一条。 | 拆为两条业务安全要求：OTP 必须由服务端安全随机生成；OTP 默认 6 位数字且配置不得低于 6 位。 | 规格也应拆成可独立验收的生成规则和格式配置规则。 | 拆为两个 spec item：生成来源输出约束；格式默认值和配置下限约束。 | 更新映射时新增对应 spec ID。 |
| `OTP-008` | Suggestion | 需求未说明有效期业务起点。 | 补充 OTP 有效期从 challenge 可验证开始计算，默认 5 分钟，配置上限 10 分钟。 | 规格需定义起算状态和过期后的状态/错误。 | 从 `OTP-STATE-CHALLENGE-ACTIVE` 开始计时；过期后不可验证并返回过期错误或进入 expired 状态。 | 无。 |
| `OTP-010` | Suggestion | 需求中的 “HMAC 或 hash” 容易允许不安全解释。 | 改为 OTP 校验值必须使用服务端 secret 参与的不可逆校验机制。 | 规格需定义可验收的存储输出约束。 | 使用 keyed HMAC 或等效 secret-peppered hash；不得保存可逆明文或普通裸 hash。 | 无。 |
| `OTP-011` | Important | 需求缺少 consent source/version 和未同意时业务结果。 | 写成发送前必须确认用户已接受当前版本服务条款和隐私政策；未接受不得发送 OTP。 | 规格需定义输入来源、失败输出和不产生副作用。 | 定义 consent 输入、版本校验、失败 typed error，并声明不创建 challenge/session。 | 无。 |
| `OTP-012` | Suggestion | Requirement 未说明冷却命中结果。 | 补充命中冷却时不得发送 OTP，并返回限流类业务错误。 | Spec 已有 `OTP-ERR-RATE-LIMITED`，无需新增语义。 | 保持或对齐 wording。 | 无。 |
| `OTP-013` | Suggestion | 需求未说明窗口策略是否可配置。 | 写成手机号级发送窗口限制是配置策略，默认每小时 5 次、每天 10 次。 | 规格需定义窗口算法/配置输入和超限输出。 | 明确窗口策略为配置项；超限返回 `OTP-ERR-RATE-LIMITED`。 | 无。 |
| `OTP-014` | Important | Requirement 已包含 IP/device/install_id 默认阈值，语义基本完整但过密。 | 可保留或拆成 IP 限流与 device/install_id 限流两条业务规则。 | Spec 丢失默认阈值，只写独立限流，无法生成完整 AC/TC。 | 用表格补 IP、device、install_id 小时/日阈值和统一 `OTP-ERR-RATE-LIMITED` 输出。 | 无。 |
| `OTP-015` | Suggestion | 需求把“新 challenge 或新 secret”写成实现选择。 | 写成用户重新发送 OTP 后，旧 active OTP 不得再通过验证，且失败计数不得被重置。 | 规格可说明实现允许路径，但行为契约应围绕状态转移。 | 定义 resend 后旧 challenge 进入不可验证状态；实现可通过新 challenge 或新 secret 达成。 | 无。 |
| `OTP-016..017` | Important | 需求未清晰区分单 challenge 尝试上限与手机号+purpose 累计锁定。 | 拆清两层业务规则：单 challenge 错误上限；手机号+purpose 累计错误锁定。 | 规格需定义两个计数器、状态变化和 typed error。 | 定义 per-challenge attempts 和 phone-purpose window attempts；达到阈值后的状态和错误码。 | 无。 |
| `OTP-018` | Important | 需求含“事务或行锁”实现语言，且把一次性消费和账号解析/创建混在一条。 | 改为业务规则：OTP 验证成功只能消费一次；只有消费成功后才允许创建或解析账号。 | 规格需定义原子消费状态转移和后续账号流程调用。 | 定义 `OTP-STATE-CHALLENGE-CONSUMED` 只成功一次；成功后进入账号创建/解析流程。 | 无。 |
| `OTP-019` | Suggestion | 需求重复定义 token 生命周期细节。 | 写成 OTP 验证成功后用户应获得登录会话能力。 | 规格应引用 token 生命周期 spec，而不是重写 token 规则。 | 按 `IDENTITY-SPEC-TOKEN-*` 签发 access/refresh token，并返回对应会话输出。 | 无。 |
| `OTP-021` | Important | 需求使用 `UserAccount`、`AuthIdentity`、`UserProfile` 类/记录名，且一条有三个结果。 | 改成业务语义或引用 `IDENTITY-ACCOUNT-003..011`：新手机号首次验证成功后创建账号、初始身份和默认资料。 | 规格可引用具体领域对象，但应拆成可验收输出或引用账号创建 spec。 | 改为引用 `IDENTITY-SPEC-ACCOUNT-003..011`，或拆成账号、身份、profile 三个 spec item。 | 无。 |
| `OTP-023` | Suggestion | Requirement 写 typed error 但未命名。 | 补充短信 provider 失败返回 provider 失败类业务错误，且不得完成 OTP 登录。 | Spec 已有 `OTP-ERR-PROVIDER-FAILED`，需与 challenge 创建时机对齐。 | 明确 provider 失败时不产生可验证 challenge/session。 | 无。 |
| `OTP-024` | Important | 需求把 release gate/test provider 禁用写成普通 OTP 业务需求。 | 移到 Release/DevOps target boundary；在需求主流程中只保留“生产不得使用测试验证码能力”的安全边界。 | 规格不应把 release gate 实现写成普通行为 item。 | 移到 release boundary spec 或 `IDENTITY-SPEC-RELEASE-*`，不作为 OTP user flow spec。 | 可能调整 traceability 分类为 release target boundary。 |
| `OTP-026` | Suggestion | HTTPS 是 Security/DevOps 边界，需求未标明归属。 | 标记为生产安全边界：生产 OTP 能力只能通过安全传输入口提供。 | 规格需定义入口约束和拒绝行为，而不是部署实现。 | 写明非 HTTPS 生产入口不得处理 OTP 请求，并返回安全错误或由网关阻断。 | 标记为 Architecture/Security boundary。 |
| `OTP-027` | Important | 需求把 audit event 集合和脱敏字段规则混成一条。 | 拆成两条：应记录哪些 OTP 审计事件；审计内容必须脱敏且不得含明文 OTP/token。 | 规格需定义事件枚举、字段白名单和禁止字段。 | 拆成 audit event set spec 与 redaction/data-minimization spec。 | 可链接 Audit 章节，避免重复定义全局审计规则。 |
| `OTP-028` | Important | 需求把风险信号、block、step-up 三类决策混在一条，step-up 未定义。 | 拆成业务策略：风险信号纳入；block 风险不得发送 OTP 或发放会话；step-up 风险需额外验证。 | 规格需定义风险等级输入、状态分支、typed error 和 step-up 成功/失败路径。 | 拆成 risk-signal、risk-block、risk-step-up 三个 spec item，并引用下游 step-up 契约。 | 可能需要 Architecture/Security 或 Risk contract。 |
| `OTP-029` | Suggestion | 需求没有写 CAPTCHA 失败业务结果。 | 补充 CAPTCHA 未通过时不得发送 OTP 或发放 session；CAPTCHA 通过也不能替代 OTP。 | 规格需定义 CAPTCHA 分支状态和后续仍需 OTP verify。 | 增加 captcha-required、captcha-failed、captcha-passed 后续转移。 | 无。 |
| `OTP-030` | Important | 需求把 OTP 明文、challenge、audit 三类 retention 混在一条。 | 拆成三条业务数据保留规则。 | 规格需分别定义对象生命周期和到期动作。 | 拆成 plaintext never stored、challenge cleanup、audit retention 三个 spec item。 | 可能链接数据保留或隐私契约。 |
| `OTP-031` | Blocker before AC/TC | 测试替身和测试覆盖不属于 Product Base requirement。 | 从 requirements 主列表移出；作为 QA/testability 输入保留。 | 测试替身和覆盖不属于产品 spec item。 | 从 spec item 主列表移出；放到 testability expectations 或后续 test cases。 | Traceability 标记为 QA/testability，不作为 requirement row。 |
| OTP target spec section | Important | 无 requirement 问题。 | 不改 requirement。 | Spec 缺少 send、verify、resend、risk block、step-up、provider failure 流程级行为段。 | 只在 spec 补流程级行为段；item table 保留为映射证据。 | 无。 |
| `OTP-004..031` traceability | Important | 无 requirement 问题。 | 不改 requirement。 | 无 spec 正文问题。 | 不改 spec 正文。 | 只修 traceability，把 Spec Flow 同步为 `IDENTITY-SPEC-OTP-004..031`；AC/TC/code evidence 保持 pending。 |
| OTP target section cross-doc | Important | Requirement 中混有 Security、DevOps、Audit、QA 内容，边界不清。 | 增加类型/状态或分小节：Product behavior target、Security target boundary、Release target、QA/testability input。 | Spec 中也需区分用户流程行为、security boundary、release boundary、testability expectation。 | 增加 spec 类型列或小节，并把非行为项移到对应边界。 | 同步 traceability 的状态/分类，避免把 QA 或 release boundary 当作已实现产品行为。 |

逐条审查与修复方案：
| Item | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 3-F 修复方案 |
| --- | --- | --- | --- | --- | --- |
| `IDENTITY-OTP-004` / `IDENTITY-SPEC-OTP-004` | Conditional：规范化和拒绝非法号码属于同一输入校验规则，可保留 | 入口范围不够清楚，容易不区分 send/verify 中哪些地方接收手机号 | 覆盖格式和地区边界，但未说明成功规范化后的后续使用 | Suggestion | 改为“所有接收手机号的 OTP 入口必须先规范化为 E.164；非法或不支持号码返回 `OTP-ERR-INVALID-PHONE`，且不得创建 challenge 或 session”。 |
| `IDENTITY-OTP-005` / `IDENTITY-SPEC-OTP-005` | Pass：只表达 send/request 阶段不得创建账号或 session | “只创建 OTP challenge”需与 provider 失败时不创建可验证 challenge 对齐 | 覆盖 send 阶段核心非目标，但缺少前置校验通过条件 | Suggestion | 补充“通过手机号、consent、频控、风险和 provider 前置校验后”，并与 `IDENTITY-OTP-023` 对齐。 |
| `IDENTITY-OTP-006` / `IDENTITY-SPEC-OTP-006` | Conditional：一个 challenge 输出绑定多个必要属性，可保留 | `OTP-IN-CONTEXT` 含义较宽，设备/客户端上下文最低要求不清 | 覆盖 challenge 绑定，但上下文边界不足 | Suggestion | 明确 context 至少包含可用的 request/client/device 标识；不可用时记录为 absent，不影响字段语义。 |
| `IDENTITY-OTP-007` / `IDENTITY-SPEC-OTP-007` | Important：混合生成来源、默认格式和配置下限 | 业务安全目标清楚，但一个 item 会产生多个 AC/TC | 覆盖随机性和格式策略 | Important | 拆为“OTP 由服务端 CSPRNG 生成”和“默认 6 位数字且配置不得低于 6 位”两个 item/spec。 |
| `IDENTITY-OTP-008` / `IDENTITY-SPEC-OTP-008` | Pass | 需明确有效期从 challenge 创建或发送成功开始计算 | 覆盖默认值和配置上限 | Suggestion | 补充有效期起算点，并保持默认 5 分钟、配置上限 10 分钟。 |
| `IDENTITY-OTP-009` / `IDENTITY-SPEC-OTP-009` | Pass | 明文流向和禁止面清楚 | 覆盖持久化、日志和错误响应泄露 | Pass | 可保留；3-F 只需检查是否与审计 item 重复但不改语义。 |
| `IDENTITY-OTP-010` / `IDENTITY-SPEC-OTP-010` | Pass | “HMAC 或 hash”需避免被误读为无 secret 的普通 hash | 覆盖持久化校验值安全边界 | Suggestion | 改为“keyed HMAC 或等效 secret-peppered hash”，明确不得保存可逆明文或普通裸 hash。 |
| `IDENTITY-OTP-011` / `IDENTITY-SPEC-OTP-011` | Pass | “当前服务条款和隐私政策”的 consent source/version 不清 | 覆盖发送前 consent gate，但未定义失败行为 | Important | 补充 consent source/version 与未接受时的拒绝行为；避免与当前未实现 consent persistence 混淆。 |
| `IDENTITY-OTP-012` / `IDENTITY-SPEC-OTP-012` | Pass | Requirements 未说明命中冷却时的 typed failure，spec 已补 `OTP-ERR-RATE-LIMITED` | 覆盖重复发送冷却 | Suggestion | 在 requirement 中同步超冷却失败输出，并保留默认 60 秒。 |
| `IDENTITY-OTP-013` / `IDENTITY-SPEC-OTP-013` | Pass | 时间窗口类型不清，固定窗口/滑动窗口/配置窗口都可能被误读 | 覆盖手机号级小时/日限制 | Suggestion | 明确窗口策略为配置项，并在默认策略下保留每小时 5 次、每天 10 次。 |
| `IDENTITY-OTP-014` / `IDENTITY-SPEC-OTP-014` | Important：IP、device、install_id 三组阈值在一个 item 中过密 | Spec 丢失默认阈值，只写“独立限流” | Requirements 覆盖完整，Spec 覆盖不足 | Important | 拆分或表格化 IP 与 device/install_id 阈值；同步 spec 中的默认每小时/每天数值。 |
| `IDENTITY-OTP-015` / `IDENTITY-SPEC-OTP-015` | Conditional：resend 策略可保留为一个规则 | “新 challenge 或新 secret”实现选择过宽，用户可观察边界是旧 OTP 不可验证 | 覆盖旧 OTP 失效与失败计数保持 | Suggestion | 改为“重新发送后旧 active OTP 不再可验证；实现可通过新 challenge 或新 secret 达成”，把实现选择降为说明。 |
| `IDENTITY-OTP-016` / `IDENTITY-SPEC-OTP-016` | Pass | 达到单 challenge 5 次后的状态和错误输出不清 | 覆盖 per-challenge 尝试上限，但后置行为不足 | Important | 补充第 5 次之后 challenge 进入不可验证状态，并返回明确 typed error 或引用 `OTP-ERR-ATTEMPTS-LOCKED`/新错误。 |
| `IDENTITY-OTP-017` / `IDENTITY-SPEC-OTP-017` | Conditional：失败计数和手机号+purpose 锁定可保留为一个累计失败规则 | 与 `IDENTITY-OTP-016` 的 per-challenge 上限关系不清 | 覆盖累计错误锁定、窗口和返回码 | Important | 明确 per-challenge 上限与手机号+purpose 累计锁定是两个独立计数层；失败时同时更新适用计数。 |
| `IDENTITY-OTP-018` / `IDENTITY-SPEC-OTP-018` | Important：原子消费和账号创建/解析是两个验收结论，可 1:N 拆分 | “事务或行锁”是实现层表述 | 覆盖一次性消费和账号生命周期入口，但内容越界 | Important | 移除“事务或行锁”，改为“原子且只成功一次地消费 challenge”；拆出“消费成功后才创建或解析账号”。 |
| `IDENTITY-OTP-019` / `IDENTITY-SPEC-OTP-019` | Pass | 需引用 token 生命周期规格，避免重复定义 token 语义 | 覆盖 verify success 后会话发放 | Suggestion | 改为“按 `IDENTITY-TOKEN` 生命周期签发 access/refresh token”。 |
| `IDENTITY-OTP-020` / `IDENTITY-SPEC-OTP-020` | Pass | 清晰 | 覆盖已绑定手机号身份不重复创建账号 | Pass | 可保留；3-F 可只对齐措辞。 |
| `IDENTITY-OTP-021` / `IDENTITY-SPEC-OTP-021` | Important：同时创建账号、身份、profile 三个独立结果 | 使用 `UserAccount`、`AuthIdentity`、`UserProfile` class/record 风格名称，requirements 层越界 | 覆盖首次验证成功的新账号初始化，但与 `IDENTITY-ACCOUNT` 有重复 | Important | 改写为业务/领域对象语义，或拆分并引用 `IDENTITY-ACCOUNT-003..011`；避免 class name。 |
| `IDENTITY-OTP-022` / `IDENTITY-SPEC-OTP-022` | Pass | 清晰 | 覆盖防用户枚举安全约束 | Pass | 可保留。 |
| `IDENTITY-OTP-023` / `IDENTITY-SPEC-OTP-023` | Pass | Requirements 的 “typed error” 未命名，spec 已命名 `OTP-ERR-PROVIDER-FAILED` | 覆盖 provider 失败下不创建 challenge/session | Suggestion | 在 requirement 中同步 `OTP-ERR-PROVIDER-FAILED`，并与 `IDENTITY-OTP-005` 的 challenge 创建时机对齐。 |
| `IDENTITY-OTP-024` / `IDENTITY-SPEC-OTP-024` | Important：生产 provider 禁用和 release gate 属 DevOps/Security release 边界，不应作为普通 Product Base requirement | 与本文“identity 专属 release gate 未实现/不承载 implementation”存在边界张力 | 覆盖发布安全目标，但内容位置不稳 | Important | 从 OTP requirement 主列表移到 release/DevOps target boundary，或改为明确的 target boundary item，不作为用户流程 requirement。 |
| `IDENTITY-OTP-025` / `IDENTITY-SPEC-OTP-025` | Pass | SMS 文案必含/禁含边界清楚 | 覆盖安全短信内容 | Pass | 可保留。 |
| `IDENTITY-OTP-026` / `IDENTITY-SPEC-OTP-026` | Pass/Conditional | HTTPS 是架构/DevOps 安全约束，requirements 中可保留但应标为 security boundary | 覆盖生产传输安全 | Suggestion | 标注为 Architecture/Security/DevOps target boundary，并保留不得通过非 HTTPS 入口处理 OTP。 |
| `IDENTITY-OTP-027` / `IDENTITY-SPEC-OTP-027` | Important：事件覆盖和脱敏字段规则混在一个长 item 中 | event name、字段和禁止项清楚，但过密 | 覆盖审计事件和数据最小化 | Important | 拆分为“必须记录的 OTP audit event set”和“OTP audit redaction/data-minimization rule”。 |
| `IDENTITY-OTP-028` / `IDENTITY-SPEC-OTP-028` | Important：风险信号、block 行为、step-up 行为混合多个业务结论 | “额外验证”未定义，step-up 成功/失败边界不清 | 覆盖风险输入和处置等级，但不可直接生成稳定 AC/TC | Important | 拆为风险信号纳入、block 决策、step-up 决策三组 item；定义 step-up 的允许验证类型或下游契约。 |
| `IDENTITY-OTP-029` / `IDENTITY-SPEC-OTP-029` | Pass | CAPTCHA 通过后的 OTP 主校验边界清楚；失败行为可更明确 | 覆盖 CAPTCHA 不替代 OTP 的安全边界 | Suggestion | 补充 CAPTCHA 未通过时不得发送 OTP 或发放 session。 |
| `IDENTITY-OTP-030` / `IDENTITY-SPEC-OTP-030` | Important：明文不保存、challenge retention、audit retention 三个生命周期规则混在一个 item 中 | 保留期限清楚，但对象生命周期不同 | 覆盖数据保留策略，但粒度过粗 | Important | 拆分为 OTP 明文永不保存、challenge/校验值过期后 24h 删除或失效、audit 脱敏数据按 retention policy version 保留。 |
| `IDENTITY-OTP-031` / `IDENTITY-SPEC-OTP-031` | Blocker for content boundary：测试替身和测试覆盖属于 test cases/testability contract，不属于 Product Base requirements/spec item | 语义清楚但文档类型错误 | 覆盖 QA 设计，不覆盖产品行为 | Blocker before AC/TC | 从 requirements/spec 主列表移出；放入 QA/test-case 或 testability contract，并在 traceability 中标为测试设计来源而非 requirement。 |

跨 item 发现：
| 发现 | 影响 | 级别 | 3-F 修复方案 |
| --- | --- | --- | --- |
| `spec.md` 对 OTP 目标态仍主要是 1:1 item table，缺少 OTP send、verify、resend、risk block、step-up、provider failure 的流程级行为段 | AC/TC 很难判断前置条件、触发、状态转移、输出和失败路径 | Important | 在 spec 中补充目标态 OTP 流程段；保留 item table 作为映射证据。 |
| `traceability.md` 中 `IDENTITY-OTP-004..031` 的 `Spec Flow` 仍为 `TBD - 后续补齐`，但 spec ID 已存在 | 追溯链路显示落后，可能导致 AC/TC 生成引用错误 | Important | 在 3-F 中同步 `Spec Flow` 到 `IDENTITY-SPEC-OTP-004..031`；AC/TC 和 code evidence 继续保持 target pending/TBD，不伪造实现证据。 |
| 目标态 OTP 中安全、DevOps、审计、QA 内容混在同一 requirement 列表中 | Product Base requirement、Architecture/Security、Release、QA 职责边界不清 | Important | 通过小节或状态列标明 `Product behavior target`、`Security target boundary`、`Release/DevOps target boundary`、`QA/testability target`。 |

Task 3-R 执行情况：
- 已执行：完成 `IDENTITY-OTP-004..031` 和 `IDENTITY-SPEC-OTP-004..031` 的逐条内容契约语义审查。
- 已执行：形成 3-F 修复输入表。
- 未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；等待用户确认后再执行 Task 3-F。

Task 3-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 3-R | Confirmed by user | 用户已确认 Requirement / Spec 分离后的修复方案，并放行 Task 3-F。 |
| Task 3-F | Completed - pending user confirmation | 已执行 OTP 目标态 3-F 修复；用户确认本修复复审前，不得执行 Task 4-R。 |

### IDENTITY-OTP 真实短信 OTP 目标态 3-F 修复复审

修复范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的目标态 OTP 段。
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的目标态 OTP 段、公共 OTP Ref ID、Requirement 到 Spec 映射。
- Traceability：`docs/product/base/identity-account-lifecycle/traceability.md` 的目标态 OTP pending 追溯区。

执行结果：conditional pass for docs-only repair。Task 3-F 已完成内容边界修复、语义拆分、spec 流程段补齐和追溯同步；目标态 OTP 仍是 `Target pending`，未声明代码实现、AC/TC 完成、测试证据或 release readiness。

Requirement 修复复审表：
| Requirement item | 原始 Requirement 描述（修复前摘要） | 3-F 修复结果 | 复审结论 |
| --- | --- | --- | --- |
| `IDENTITY-OTP-004` | OTP 流程入口先做 E.164 规范化并拒绝不支持或非法号码。 | 改为所有接收手机号的 OTP 登录或注册入口必须先完成 E.164 规范化；非法或不支持号码不得进入 OTP 登录或注册流程。 | Pass |
| `IDENTITY-OTP-005` | 请求 OTP 只创建 OTP challenge，不创建账号或 session。 | 改为请求 OTP 只启动待验证挑战，不得完成账号创建或认证会话。 | Pass |
| `IDENTITY-OTP-006` | OTP challenge 绑定手机号、purpose、上下文和过期时间。 | 补充 challenge id，保留规范化手机号、`purpose=login_or_register`、请求上下文和过期时间。 | Pass |
| `IDENTITY-OTP-007` | OTP 安全随机生成、默认 6 位数字且配置不得低于 6 位混在一条。 | 保留为“OTP 必须由服务端安全随机能力生成”。 | Pass |
| `IDENTITY-OTP-032` | 原 `IDENTITY-OTP-007` 中的 OTP 格式和配置下限。 | 新增为独立 requirement：默认 6 位数字，位数配置不得低于 6 位。 | Pass |
| `IDENTITY-OTP-008` | OTP 默认有效期 5 分钟、配置上限 10 分钟，起算点不清。 | 补充有效期从 challenge 可验证开始计算。 | Pass |
| `IDENTITY-OTP-009` | OTP 明文只进短信发送，不持久化、不记录日志、不进入错误响应。 | 保留明文流向和禁止面，作为产品安全边界。 | Pass |
| `IDENTITY-OTP-010` | OTP 校验值使用 HMAC 或 hash，存在普通 hash 误读风险。 | 改为使用服务端 secret 参与的不可逆校验机制，并绑定 challenge 和规范化手机号。 | Pass |
| `IDENTITY-OTP-011` | 发送前要求接受服务条款和隐私政策，但版本和失败结果不清。 | 改为必须接受当前版本条款和隐私政策；未接受不得发送 OTP。 | Pass |
| `IDENTITY-OTP-012` | 同手机号重复发送有 60 秒冷却。 | 补充命中冷却时不得发送 OTP。 | Pass |
| `IDENTITY-OTP-013` | 同手机号每小时 5 次、每天 10 次。 | 改为手机号级发送限流按可配置时间窗口执行，并保留默认阈值。 | Pass |
| `IDENTITY-OTP-014` | IP、device、install_id 发送限流阈值集中在一条。 | 保留为业务限流边界，明确 IP 和 device/install_id 独立限流及默认小时/日阈值。 | Conditional pass：后续 AC/TC 可再按维度拆验收。 |
| `IDENTITY-OTP-015` | 重发后旧 OTP 或旧 secret 失效，失败计数不重置。 | 改为用户可观察业务语义：旧 active OTP 不得再通过验证，失败计数不得重置。 | Pass |
| `IDENTITY-OTP-016` | 单个 challenge 最多 5 次错误验证。 | 补足超过上限后该 challenge 不得继续验证成功。 | Pass |
| `IDENTITY-OTP-017` | 手机号和 purpose 级失败计数，30 分钟 10 次锁 15 分钟。 | 明确发送和验证都被锁定，区别于单 challenge 错误上限。 | Pass |
| `IDENTITY-OTP-018` | 通过事务或行锁保证验证成功只消费一次，并进入账号解析/创建。 | 移除实现语言，只保留一次性消费规则。 | Pass |
| `IDENTITY-OTP-033` | 原 `IDENTITY-OTP-018` 中“消费成功后才允许账号创建或解析”的第二个结论。 | 新增为独立 requirement：只有 challenge 成功消费后才允许进入账号创建或解析流程。 | Pass |
| `IDENTITY-OTP-019` | OTP 验证成功后签发 token / session。 | 改为产品语义：验证成功后用户必须获得登录会话能力，token 细节由 token 生命周期承接。 | Pass |
| `IDENTITY-OTP-020` | 已存在手机号身份时解析到原用户，不重复创建账号。 | 保留。 | Pass |
| `IDENTITY-OTP-021` | 新手机号首次成功后创建 `UserAccount`、`AuthIdentity`、`UserProfile`。 | 改为账号、初始登录身份和默认资料的业务语义，引用账号创建规则，移除 class/record 风格名称。 | Pass |
| `IDENTITY-OTP-022` | OTP 错误不得泄露手机号是否已注册。 | 保留。 | Pass |
| `IDENTITY-OTP-023` | 短信 provider 失败返回 typed error，不完成登录。 | 改为 provider 失败类业务错误，且不得完成 OTP 登录。 | Pass |
| `IDENTITY-OTP-025` | SMS 内容包含 App 名称、验证码、有效期、风险提示，禁含敏感资料。 | 移入安全与防滥用目标边界，语义保留。 | Pass |
| `IDENTITY-OTP-026` | 生产 OTP 只能通过 HTTPS。 | 改为生产 OTP 只能通过安全传输入口提供；非安全传输入口不得处理生产 OTP 请求。 | Pass |
| `IDENTITY-OTP-027` | 审计事件集合和脱敏字段规则混在一条。 | 保留为审计事件集合：send requested、verify succeeded/failed、expired、rate limited、provider failed。 | Pass |
| `IDENTITY-OTP-034` | 原 `IDENTITY-OTP-027` 中的审计脱敏和禁止明文规则。 | 新增为独立 requirement：审计内容只能使用脱敏/hash 手机号、purpose、request_id、风险结果，不记录 OTP/token 明文。 | Pass |
| `IDENTITY-OTP-028` | 风险信号、block、step-up 混在一条。 | 保留为风险输入集合：SIM swap/号码转移、异常设备、异常 IP、短时大量请求。 | Pass |
| `IDENTITY-OTP-035` | 原 `IDENTITY-OTP-028` 中的 block 处置。 | 新增为独立 requirement：block 风险不得发送 OTP 或发放会话，并返回风险阻断错误。 | Pass |
| `IDENTITY-OTP-036` | 原 `IDENTITY-OTP-028` 中的 step-up 处置。 | 新增为独立 requirement：step-up 风险要求额外验证，完成前不得发放会话。 | Pass |
| `IDENTITY-OTP-029` | CAPTCHA 不得替代 OTP。 | 补充 CAPTCHA 未通过时不得发送 OTP 或发放会话，通过后仍需正确 OTP。 | Pass |
| `IDENTITY-OTP-030` | OTP 明文、challenge、audit retention 混在一条。 | 保留 challenge 和校验值过期后 24 小时内删除或失效；明文禁止由 `IDENTITY-OTP-009` 承接。 | Pass |
| `IDENTITY-OTP-037` | 原 `IDENTITY-OTP-030` 中的 audit retention。 | 新增为独立 requirement：OTP 审计事件保留脱敏数据和 retention policy 版本。 | Pass |
| `IDENTITY-OTP-024` | 生产不得使用 deterministic/test OTP provider，错误配置由 release gate 阻断。 | 移入 Release / DevOps target boundary，避免作为普通用户流程 requirement。 | Pass |
| `IDENTITY-OTP-031` | 测试应使用 fake SMS provider、覆盖成功/过期/重放/限流/provider 失败。 | 从 Product Base requirement item 移出，改为 `OTP-TESTABILITY-001` QA/testability 输入。 | Pass |

Spec 修复复审表：
| Spec item | 原始 Spec 描述（修复前摘要） | 3-F 修复结果 | 复审结论 |
| --- | --- | --- | --- |
| OTP target flow section | 原规格主要是 1:1 item table，缺少 send、resend、verify、risk、provider failure 流程段。 | 新增 `OTP-FLOW-SEND`、`OTP-FLOW-RESEND`、`OTP-FLOW-VERIFY`、`OTP-FLOW-RISK`、`OTP-FLOW-PROVIDER-FAILURE`，定义触发、前置、状态转移、输出和失败边界。 | Pass |
| OTP Ref IDs | 原 Ref ID 覆盖 active/consumed/locked 和部分错误，缺少 consent、captcha、expired、invalidated、step-up 等状态或输入。 | 新增 consent、captcha、expired、invalidated、step-up required、consent required、expired、challenge attempts exceeded、captcha failed 等 Ref ID。 | Pass |
| `IDENTITY-SPEC-OTP-004` | E.164 规范化规格缺少明确失败后置状态。 | 输出 `OTP-IN-PHONE-E164`；非法或不支持号码返回 `OTP-ERR-INVALID-PHONE`，不得创建 challenge/session。 | Pass |
| `IDENTITY-SPEC-OTP-005` | 创建 challenge 与 provider 失败时机未对齐。 | 明确 send 前置校验通过后才创建 active challenge 并发送 SMS；不得创建账号/session。 | Pass |
| `IDENTITY-SPEC-OTP-006` | challenge 绑定字段存在，但上下文定义较宽。 | 明确绑定 `OTP-IN-PHONE-E164`、purpose、challenge_id、`OTP-IN-CONTEXT` 和过期时间。 | Pass |
| `IDENTITY-SPEC-OTP-007` | 生成来源、格式和配置下限混在一条。 | 保留为 OTP 原始值由服务端安全随机能力生成。 | Pass |
| `IDENTITY-SPEC-OTP-032` | 原 `IDENTITY-SPEC-OTP-007` 中的 OTP 格式配置规则。 | 新增独立 spec item：默认 6 位数字，配置不得低于 6 位。 | Pass |
| `IDENTITY-SPEC-OTP-008` | 有效期缺少起算状态和过期输出。 | 从 active challenge 开始默认 5 分钟、配置不超过 10 分钟；过期后进入 expired 并返回过期错误。 | Pass |
| `IDENTITY-SPEC-OTP-009` | 明文流向和禁止面清楚。 | 保留为只允许进入短信发送流程，不得持久化、写日志或进入错误响应。 | Pass |
| `IDENTITY-SPEC-OTP-010` | “HMAC 或 hash”可能被误读为普通 hash。 | 改为 keyed HMAC 或等效 secret-peppered hash，并禁止可逆明文或普通裸 hash。 | Pass |
| `IDENTITY-SPEC-OTP-011` | consent 输入和失败输出不完整。 | 定义 `OTP-IN-CONSENT`、版本不匹配返回 `OTP-ERR-CONSENT-REQUIRED`，不得创建 challenge/session。 | Pass |
| `IDENTITY-SPEC-OTP-012..014` | 冷却、手机号限流、IP/device/install_id 限流规则不完整或阈值缺失。 | 对齐默认 60 秒冷却、手机号小时/日阈值、IP 与 device/install_id 小时/日阈值，统一返回 `OTP-ERR-RATE-LIMITED`。 | Pass |
| `IDENTITY-SPEC-OTP-015` | resend 语义含实现选择。 | 改为旧 active challenge 进入 invalidated，失败计数不重置。 | Pass |
| `IDENTITY-SPEC-OTP-016..017` | per-challenge attempts 与 phone-purpose attempts 边界不清。 | 明确单 challenge 错误上限、challenge invalidated、手机号+purpose 30 分钟累计锁 15 分钟和对应错误。 | Pass |
| `IDENTITY-SPEC-OTP-018` | 一次性消费和账号解析/创建混在一条。 | 保留 challenge consumed 的一次性成功状态转移。 | Pass |
| `IDENTITY-SPEC-OTP-033` | 原 `IDENTITY-SPEC-OTP-018` 中的账号解析/创建前置。 | 新增独立 spec item：只有 consumed challenge 才能进入账号创建或解析流程。 | Pass |
| `IDENTITY-SPEC-OTP-019` | 重写 token 细节风险。 | 改为引用 `IDENTITY-SPEC-TOKEN-*` 签发 token 并返回登录会话输出。 | Pass |
| `IDENTITY-SPEC-OTP-020..023` | 已有/新手机号、枚举防护、provider 失败语义基本存在。 | 对齐账号创建 spec 引用、错误防枚举、provider failure 不创建可验证 challenge/session。 | Pass |
| `IDENTITY-SPEC-OTP-025..026` | SMS 内容和安全传输作为普通 OTP item 混在同一段。 | 移入 Security and Abuse-Control Target Boundary Spec Items，并保留可验收行为。 | Pass |
| `IDENTITY-SPEC-OTP-027` | 审计事件和数据最小化混在一条。 | 保留为 OTP 审计事件枚举。 | Pass |
| `IDENTITY-SPEC-OTP-034` | 原 `IDENTITY-SPEC-OTP-027` 中的审计安全字段规则。 | 新增为只写入 `OTP-AUDIT-SAFE`，禁止 OTP/token 明文。 | Pass |
| `IDENTITY-SPEC-OTP-028` | 风险信号、block、step-up 决策混在一条。 | 保留为风险输入集合。 | Pass |
| `IDENTITY-SPEC-OTP-035..036` | 原风险 item 中的 block 和 step-up 分支。 | 拆成 block 返回 `OTP-ERR-RISK-BLOCKED` 且不发送/发 session；step-up 进入 `OTP-STATE-STEP-UP-REQUIRED` 且完成前不发 session。 | Pass |
| `IDENTITY-SPEC-OTP-029` | CAPTCHA 分支缺少失败输出。 | 补充 `OTP-ERR-CAPTCHA-FAILED`、不得发送 OTP/session，且通过后仍需正确 OTP。 | Pass |
| `IDENTITY-SPEC-OTP-030` | challenge retention 与 audit retention 混在一条。 | 保留 challenge 和校验值过期后 24 小时内删除或失效。 | Pass |
| `IDENTITY-SPEC-OTP-037` | 原 `IDENTITY-SPEC-OTP-030` 中的 audit retention。 | 新增为审计事件保留脱敏数据和 retention policy 版本。 | Pass |
| `IDENTITY-SPEC-OTP-024` | release gate 作为普通 OTP behavior item。 | 移入 Release / DevOps Target Boundary Spec Items，保留生产禁用 deterministic/test provider 的 release 边界。 | Pass |
| `IDENTITY-SPEC-OTP-031` | fake SMS provider 和覆盖场景属于测试设计。 | 从产品 spec item 移出，改为 `OTP-TESTABILITY-001` Testability Expectation。 | Pass |

Traceability 修复复审表：
| 对象 | 修复内容 | 复审结论 |
| --- | --- | --- |
| `IDENTITY-OTP-004..030,032..037` | `Spec Flow` 从 `TBD - 后续补齐` 同步为对应 `IDENTITY-SPEC-OTP-*`；`AC`、`TC` 继续 `TBD - 后续补齐`；`Code Evidence` 继续 target pending。 | Pass |
| `IDENTITY-OTP-024..030,034..037` | 对安全、防滥用、release 边界使用 `target boundary` 或 `release target boundary` 状态，不伪装成已实现用户流程。 | Pass |
| `IDENTITY-OTP-031` | 从 requirement pending 矩阵移出。 | Pass |
| `OTP-TESTABILITY-001` | 新增单独 QA/testability 输入表，标记为不计入 Product Base requirement 或 code evidence。 | Pass |

3-F 修复后复审结果：
| 复审对象 | 颗粒度 | 清晰度 | 覆盖度 | 结论 |
| --- | --- | --- | --- | --- |
| Target OTP requirements | Pass：随机生成/格式、消费/账号入口、审计事件/脱敏、风险信号/block/step-up、retention/testability 已拆分 | Pass：Product behavior、Security boundary、Release boundary、QA input 已分段 | Pass：覆盖 send、verify、resend、失败计数、provider failure、安全、审计、保留和测试输入边界 | Task 3-F requirements 修复关闭 |
| Target OTP spec | Pass：新增流程段并拆分组合 item | Pass：状态、输入、错误、失败边界和下游引用更明确 | Pass：可作为后续 AC/TC 上游；仍不声明实现完成 | Task 3-F spec 修复关闭 |
| Target OTP traceability | Pass：目标 requirement/spec ID 已同步；QA 输入独立 | Pass：pending code evidence、AC/TC 待补齐状态清楚 | Pass：不再把 `IDENTITY-OTP-031` 当作 requirement 追溯行 | Task 3-F traceability 同步关闭 |

修复验证：
- `IDENTITY-OTP-031` 和 `IDENTITY-SPEC-OTP-031` 已不再作为目标态产品 requirement/spec item 出现在 `requirements.md` 或 `spec.md` 主 item 表中；其语义改为 `OTP-TESTABILITY-001`。
- 新增 `IDENTITY-OTP-032..037` / `IDENTITY-SPEC-OTP-032..037` 承接原组合 item 的独立业务或规格语义。
- `traceability.md` 对目标态 OTP 只声明 pending requirement/spec 链路，未声明 AC、TC、代码证据或测试证据完成。
- 本次修复不批准 Product Base root merge、release readiness、acceptance criteria、test cases、backend implementation 或测试执行完成。

Task 3-F 门禁状态（当前已由用户确认）：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 3-F | Confirmed by user | 已放行并执行 Task 4-R。 |
| Task 4-R | Completed - pending user confirmation | 用户确认 Task 4-R 审查表前，不得执行 Task 4-F。 |

### IDENTITY-PROVIDER Apple / WeChat 第三方身份 4-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-PROVIDER-001..004`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-PROVIDER-001..004`
- 交叉引用 Ref ID：`PROVIDER-IN-APPLE`、`PROVIDER-IN-WECHAT`、`PROVIDER-IN-TOKEN`、`PROVIDER-SUBJECT-HASH`、`PROVIDER-ERR-VALIDATION`
- 只读上下文：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-PROVIDER-001..004`

本轮结果：conditional。provider 子章节可继续作为 current-code-baseline Draft 输入；没有阻止 Draft 留存的 blocker。但在生成 AC/TC、Product Base merge 或后续实现计划前，必须把 Apple/WeChat 当前行为明确标记为“入口路由 + token 存在性 + token hash subject 的代码基线限制”，不得把 provider token hash 误读为生产级 Apple `sub`、WeChat `openid/unionid` 或已完成真实 provider 校验。

Requirement 审查与 4-F 修复方案：
| Requirement item | 原始 Requirement 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 4-F Requirement 修复方案 |
| --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-PROVIDER-001` | Apple 登录入口必须把请求路由到 `apple` 身份来源。 | Pass：单一入口来源归属规则 | Conditional：未在 item 内写明这是当前代码基线路由，不代表 Apple token 已验证 | Conditional：覆盖 Apple 入口来源归属；真实 Apple identity 校验由非归档段落排除 | Suggestion | 改为“当前代码基线的 Apple 登录入口必须把请求归属为 `apple` 身份来源；该行为不代表 Apple identity token 签名、audience、issuer、expiry 或 nonce 校验已实现”。 |
| `IDENTITY-PROVIDER-002` | WeChat 登录入口必须把请求路由到 `wechat` 身份来源。 | Pass：单一入口来源归属规则 | Conditional：未在 item 内写明这是当前代码基线路由，不代表 WeChat 服务端校验 | Conditional：覆盖 WeChat 入口来源归属；真实 WeChat code/openid/unionid/session 校验由非归档段落排除 | Suggestion | 改为“当前代码基线的 WeChat 登录入口必须把请求归属为 `wechat` 身份来源；该行为不代表 WeChat code、openid、unionid 或 session 校验已实现”。 |
| `IDENTITY-PROVIDER-003` | 第三方登录请求必须包含非空 provider token。 | Pass：单一输入存在性要求 | Conditional：容易被误读为 provider token 有效性校验 | Conditional：覆盖缺失 token 的失败前置；不覆盖 token 真实性、过期、签名或 provider 交换 | Important | 改为“当前代码基线的 Apple/WeChat 登录请求必须包含非空 provider token；该要求只代表输入存在性校验，不代表 provider token 真实性或服务端校验已实现”。 |
| `IDENTITY-PROVIDER-004` | 系统必须把 provider token 的 hash 作为第三方身份 subject。 | Pass：表达一个 current-code-baseline subject 派生规则 | Important：以 `必须` 形式出现时容易被当作稳定目标态身份语义；provider token hash 不是生产级 provider subject | Important：覆盖当前代码行为，但未在 item 内保护目标态边界；可能污染后续账号唯一性和社交登录 AC/TC | Important | 改为“当前代码基线必须把 provider token 的 hash 作为第三方身份 subject；该行为仅归档当前实现限制，不代表目标态 Apple/WeChat 稳定身份 subject 规则”。 |

Spec 审查与 4-F 修复方案：
| Spec item | 原始 Spec 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 4-F Spec 修复方案 |
| --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-PROVIDER-001` | Apple 登录入口必须把 `PROVIDER-IN-APPLE` 路由到 `apple` 身份来源。 | Pass：单一输入到 provider source 的行为契约 | Conditional：缺少 current-code-baseline limitation，可能被误读为 Apple 登录完整规格 | Conditional：覆盖入口路由；不覆盖 provider token 解析、校验或 subject 抽取失败路径 | Suggestion | 增加 current code baseline 限定，并声明该 spec 不表示 Apple identity token validation 或 Apple stable subject extraction 已实现。 |
| `IDENTITY-SPEC-PROVIDER-002` | WeChat 登录入口必须把 `PROVIDER-IN-WECHAT` 路由到 `wechat` 身份来源。 | Pass：单一输入到 provider source 的行为契约 | Conditional：缺少 current-code-baseline limitation，可能被误读为 WeChat 登录完整规格 | Conditional：覆盖入口路由；不覆盖 WeChat code/session/openid/unionid 校验或抽取失败路径 | Suggestion | 增加 current code baseline 限定，并声明该 spec 不表示 WeChat code/session/openid/unionid validation 或 stable subject extraction 已实现。 |
| `IDENTITY-SPEC-PROVIDER-003` | 第三方登录请求必须包含非空 `PROVIDER-IN-TOKEN`，否则返回 `PROVIDER-ERR-VALIDATION`。 | Pass：输入存在性和缺失失败可作为一个 spec item | Conditional：`PROVIDER-ERR-VALIDATION` 未说明这只是缺失输入，不是 token 无效/过期/签名失败 | Conditional：覆盖 token 缺失错误；不覆盖 provider 校验失败、provider 不可用、token expired、nonce mismatch 等目标态失败 | Important | 改为 current baseline 输入存在性规格；错误定义限制为 token missing/blank。真实 provider validation failure 应留到后续目标态 provider spec。 |
| `IDENTITY-SPEC-PROVIDER-004` | 系统必须把 `PROVIDER-IN-TOKEN` 计算为 `PROVIDER-SUBJECT-HASH` 并作为第三方身份 subject。 | Pass：单一 subject 派生规则 | Important：规格直接把 token hash 写成 subject，会被 AC/TC 当作稳定身份契约 | Important：未覆盖真实 provider subject 抽取，且可能和账号唯一性语义产生错误链路 | Important | 改为“current code baseline 下计算 `PROVIDER-SUBJECT-HASH` 作为第三方 identity subject；该 spec 不表示 Apple `sub` 或 WeChat `openid/unionid` 已验证或使用”。 |

跨文档发现与 4-F 修复方案：
| 对象 | 问题 | 影响 | 级别 | 4-F 修复方案 |
| --- | --- | --- | --- | --- |
| `traceability.md` provider 行 | `IDENTITY-PROVIDER-001..004` 的 `Spec Flow` 仍为 `TBD - 后续补齐`，但 `IDENTITY-SPEC-PROVIDER-001..004` 已存在。 | 追溯链路显示落后，后续 AC/TC 生成可能继续引用 TBD。 | Important | 在 4-F 中同步 `Spec Flow` 到 `IDENTITY-SPEC-PROVIDER-001..004`；`AC` 和 `TC` 继续保留 `TBD - 后续补齐`，不伪造测试或代码新证据。 |
| provider target boundary | requirements/spec 已在段落中说明真实 Apple/WeChat 校验不归档，但 item 内没有 limitation。 | 单条 item 被抽取到 AC/TC 或 Product Base root 时可能丢失非目标边界。 | Important | 将 limitation 写入相关 requirement/spec item 本身，保留段落级“当前不归档为已实现”作为补充边界。 |

Task 4-R 执行情况：
- 已执行：完成 `IDENTITY-PROVIDER-001..004` 和 `IDENTITY-SPEC-PROVIDER-001..004` 的逐条内容契约语义审查。
- 已执行：按 Requirement / Spec 分离格式形成 4-F 修复输入表，并在 item 后附原始描述。
- 未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；等待用户确认后再执行 Task 4-F。

Task 4-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 4-R | Confirmed by user | 用户已确认本审查表，并放行 Task 4-F。 |
| Task 4-F | Completed - pending user confirmation | 已执行 provider 子章节修复；用户确认本修复复审前，不得执行 Task 5-R。 |

### IDENTITY-PROVIDER Apple / WeChat 第三方身份 4-F 修复复审

修复范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-PROVIDER-001..004`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 provider Ref ID 和 `IDENTITY-SPEC-PROVIDER-001..004`
- Traceability：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-PROVIDER-001..004` 的 `Spec Flow`

执行结果：conditional pass for docs-only repair。Task 4-F 已完成 current-code-baseline limitation 补强、provider token hash subject 目标态边界保护和 provider traceability Spec Flow 同步；仍不声明真实 Apple/WeChat provider 校验、AC/TC、测试证据或 release readiness 完成。

Requirement 修复复审表：
| Requirement item | 原始 Requirement 描述 | 4-F 修复结果 | 复审结论 |
| --- | --- | --- | --- |
| `IDENTITY-PROVIDER-001` | Apple 登录入口必须把请求路由到 `apple` 身份来源。 | 改为当前代码基线 Apple 登录入口把请求归属为 `apple`；明确不代表 Apple identity token 签名、audience、issuer、expiry 或 nonce 校验已实现。 | Pass |
| `IDENTITY-PROVIDER-002` | WeChat 登录入口必须把请求路由到 `wechat` 身份来源。 | 改为当前代码基线 WeChat 登录入口把请求归属为 `wechat`；明确不代表 WeChat code、openid、unionid 或 session 校验已实现。 | Pass |
| `IDENTITY-PROVIDER-003` | 第三方登录请求必须包含非空 provider token。 | 改为当前代码基线 Apple / WeChat 登录请求必须包含非空 provider token；明确只代表输入存在性，不代表真实性、过期、签名或服务端 provider 校验。 | Pass |
| `IDENTITY-PROVIDER-004` | 系统必须把 provider token 的 hash 作为第三方身份 subject。 | 改为当前代码基线把 provider token hash 作为第三方身份 subject；明确只是当前实现限制，不代表目标态 Apple / WeChat 稳定身份 subject。 | Pass |

Spec 修复复审表：
| Spec item | 原始 Spec 描述 | 4-F 修复结果 | 复审结论 |
| --- | --- | --- | --- |
| `PROVIDER-IN-TOKEN` | 第三方登录请求携带的非空 provider token。 | 补充 current-code-baseline 限定；不表示 token 真实性、过期、签名或服务端 provider 校验完成。 | Pass |
| `PROVIDER-SUBJECT-HASH` | provider token 的 hash，作为第三方身份 subject。 | 补充 current-code-baseline 限定；不表示 Apple `sub` 或 WeChat `openid` / `unionid` 已验证或使用。 | Pass |
| `PROVIDER-ERR-VALIDATION` | provider token 为空时的校验失败。 | 改为 provider token 缺失或空白时的输入存在性失败。 | Pass |
| `IDENTITY-SPEC-PROVIDER-001` | Apple 登录入口必须把 `PROVIDER-IN-APPLE` 路由到 `apple` 身份来源。 | 补充 current-code-baseline 限定，并明确不表示 Apple identity token validation 或 Apple stable subject extraction 已实现。 | Pass |
| `IDENTITY-SPEC-PROVIDER-002` | WeChat 登录入口必须把 `PROVIDER-IN-WECHAT` 路由到 `wechat` 身份来源。 | 补充 current-code-baseline 限定，并明确不表示 WeChat code/session/openid/unionid validation 或 stable subject extraction 已实现。 | Pass |
| `IDENTITY-SPEC-PROVIDER-003` | 第三方登录请求必须包含非空 `PROVIDER-IN-TOKEN`，否则返回 `PROVIDER-ERR-VALIDATION`。 | 改为 current baseline 输入存在性规格；缺失或空白返回 `PROVIDER-ERR-VALIDATION`；不表示真实性、过期、签名或服务端校验已实现。 | Pass |
| `IDENTITY-SPEC-PROVIDER-004` | 系统必须把 `PROVIDER-IN-TOKEN` 计算为 `PROVIDER-SUBJECT-HASH` 并作为第三方身份 subject。 | 补充 current-code-baseline 限定，并明确不表示 Apple `sub` 或 WeChat `openid` / `unionid` 已验证或使用。 | Pass |

Traceability 修复复审表：
| 对象 | 修复内容 | 复审结论 |
| --- | --- | --- |
| `IDENTITY-PROVIDER-001..004` | `Spec Flow` 从 `TBD - 后续补齐` 同步为 `IDENTITY-SPEC-PROVIDER-001..004`。 | Pass |
| `IDENTITY-PROVIDER-001..004` AC/TC | 继续保留 `TBD - 后续补齐`，未伪造 acceptance criteria 或 test case。 | Pass |
| `IDENTITY-PROVIDER-001..004` Code Evidence | 保留当前代码证据状态；本次未声明真实 Apple/WeChat provider 校验完成。 | Pass |

4-F 修复后复审结果：
| 复审对象 | 颗粒度 | 清晰度 | 覆盖度 | 结论 |
| --- | --- | --- | --- | --- |
| Provider requirements | Pass：四条仍各自表达入口归属、token 输入存在性或 subject 派生规则 | Pass：current-code-baseline limitation 和目标态 provider 校验非目标已写入 item 内 | Pass：覆盖当前 Apple/WeChat 入口路由、provider token 存在性、token hash subject，同时防止误承诺真实 provider 校验 | Task 4-F requirements 修复关闭 |
| Provider spec | Pass：Ref ID 与 spec item 均保持单一行为契约 | Pass：missing/blank token 错误与 provider validation failure 已区分 | Pass：可作为当前代码基线 AC/TC 上游；目标态 Apple/WeChat 校验仍需后续独立需求/spec | Task 4-F spec 修复关闭 |
| Provider traceability | Pass：provider requirements 均映射到具体 spec ID | Pass：AC/TC 仍显式待补齐，代码证据未扩大解释 | Pass：Spec 链路同步问题关闭 | Task 4-F traceability 同步关闭 |

修复验证：
- provider requirement item 内已显式写入 current-code-baseline limitation。
- provider spec item 内已显式排除真实 Apple/WeChat validation 和 stable subject extraction。
- `traceability.md` provider 行已同步 `IDENTITY-SPEC-PROVIDER-001..004`，未伪造 AC、TC 或新代码证据。
- 本次修复不批准 Product Base root merge、release readiness、acceptance criteria、test cases、backend implementation 或测试执行完成。

Task 4-F 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 4-F | Confirmed by user | 用户已确认本修复复审表，并放行 Task 5-R。 |
| Task 5-R | Confirmed by user | 用户已确认 login 子章节审查表，并放行 Task 5-F。 |
| Task 5-F | Confirmed by user | 用户已确认 login 子章节修复复审，并放行 Task 6-R。 |

### IDENTITY-LOGIN 登录与 session 签发 5-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-LOGIN-001..007`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-LOGIN-001..007`
- 交叉引用 Ref ID：`LOGIN-IN-TERMS-ACCEPTED`、`LOGIN-IN-SCHEMA-VERSION`、`LOGIN-STATE-PUBLIC-ENDPOINT`、`LOGIN-STATE-ACCOUNT-ACTIVE`、`LOGIN-STATE-SESSION-ACTIVE`、`LOGIN-OUT-TOKEN-PAIR`、`LOGIN-ERR-TERMS-REQUIRED`、`LOGIN-ERR-INACTIVE-ACCOUNT`、`LOGIN-ERR-UNSUPPORTED-SCHEMA`
- 只读上下文：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-LOGIN-001..007`

本轮结果：conditional。login 子章节可继续作为 current-code-baseline Draft 输入；没有阻止 Draft 留存的 blocker。但在生成 AC/TC、Product Base merge 或后续实现计划前，应补清登录前置校验失败的后置边界、public endpoint 的权限含义、schema version 的兼容性语义，并同步 traceability 中已存在的 spec ID。

Requirement 审查与 5-F 修复方案：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 5-F Requirement 修复方案 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-LOGIN-001` | 手机号登录请求必须在用户接受条款后才能继续处理。 | 当前代码基线的手机号登录请求必须声明已接受条款后才允许继续认证处理；未接受时必须拒绝，且不得进入身份解析、账号创建或 session 签发；该要求不代表 Terms/Privacy consent 持久化已实现。 | Pass：单一手机号登录 consent gate | Conditional：`继续处理` 未说明失败后置边界，也容易和目标态 current-version consent persistence 混淆 | Conditional：覆盖手机号登录条款前置；未明确未接受时不得进入身份解析、账号创建或 session 签发 | Important | 在 5-F 中按“修复后 Requirement 描述”改写。 |
| `IDENTITY-LOGIN-002` | 第三方登录请求必须在用户接受条款后才能继续处理。 | 当前代码基线的 Apple / WeChat 登录请求必须声明已接受条款后才允许继续认证处理；未接受时必须拒绝，且不得进入 provider token subject 处理、身份解析、账号创建或 session 签发。 | Pass：单一第三方登录 consent gate | Conditional：同样缺少失败后置边界，且未限定 Apple/WeChat current-code-baseline | Conditional：覆盖第三方登录条款前置；未明确未接受时不得进入 provider token subject 处理、身份解析或 session 签发 | Important | 在 5-F 中按“修复后 Requirement 描述”改写。 |
| `IDENTITY-LOGIN-003` | 手机号、Apple、WeChat 登录入口必须允许未认证客户端调用。 | 手机号、Apple、WeChat 登录入口必须不要求既有认证 session；public entry 不得绕过 schema version、terms、凭证或账号状态校验。 | Pass：单一 public entry rule | Conditional：`允许未认证客户端调用` 可能被误读为绕过 schema、terms 或凭证校验 | Conditional：覆盖 public endpoint 安全配置；未说明 public 只是不要求既有 session | Suggestion | 在 5-F 中按“修复后 Requirement 描述”改写。 |
| `IDENTITY-LOGIN-004` | 系统必须拒绝非 `active` 账号登录。 | 身份解析或账号创建得到的账号不为 `active` 时，系统必须拒绝登录，且不得创建认证 session 或发放 token。 | Pass：单一账号状态门禁 | Conditional：触发点未说明是在身份解析/账号创建后、session 创建前 | Conditional：覆盖 inactive 账号拒绝；未明确不得发放 token/session | Suggestion | 在 5-F 中按“修复后 Requirement 描述”改写。 |
| `IDENTITY-LOGIN-005` | 登录成功时，系统必须创建一个 `active` 认证 session。 | 登录请求通过 schema version、terms、凭证和账号状态门禁后，系统必须为本次解析或创建的用户创建 `active` 认证 session。 | Pass：单一成功状态转移 | Conditional：`登录成功` 的前置条件隐含在其他 item 中；session 归属对象不明 | Conditional：覆盖成功后 session 创建，但未写绑定到本次解析/创建账号 | Suggestion | 在 5-F 中按“修复后 Requirement 描述”改写。 |
| `IDENTITY-LOGIN-006` | 登录成功响应必须返回当前用户、access token、refresh token 和 access token 过期时间。 | 登录成功响应必须返回当前用户、access token、refresh token 和 access token 过期时间；access / refresh token 的生命周期和轮换语义由 `IDENTITY-TOKEN` 子章节承接。 | Pass：一个登录成功响应输出 | Conditional：token 语义应引用 token 生命周期，避免在 login requirement 中重定义 | Pass：覆盖登录成功响应核心输出 | Suggestion | 在 5-F 中按“修复后 Requirement 描述”改写。 |
| `IDENTITY-LOGIN-007` | 登录和刷新请求必须拒绝不支持的 schema version。 | 当前代码基线的登录和刷新请求必须在认证状态变化前拒绝不支持的 schema version；拒绝后不得创建 session、发放 token 或刷新 token；具体 schema 字段形态由 API contract 承接。 | Conditional：登录和刷新共享同一兼容性规则，可保留；但跨 login/token 两个子章节 | Conditional：未说明拒绝发生在认证状态变化前，也未限定这是兼容性失败而非 API schema 细节 | Conditional：覆盖 schema compatibility；未明确不得创建 session、刷新 token 或进入登录处理 | Important | 在 5-F 中按“修复后 Requirement 描述”改写。 |

Spec 审查与 5-F 修复方案：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 5-F Spec 修复方案 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-LOGIN-001` | 手机号登录请求只有满足 `LOGIN-IN-TERMS-ACCEPTED` 后才能继续处理，否则返回 `LOGIN-ERR-TERMS-REQUIRED`。 | Current code baseline 下，手机号登录请求只有满足 `LOGIN-IN-TERMS-ACCEPTED` 后才能继续认证处理；否则返回 `LOGIN-ERR-TERMS-REQUIRED`，并不得进入身份解析、账号创建或 session 签发流程。 | Pass：单一手机号 terms gate | Conditional：未写清失败后不得进入身份解析、账号创建或 session 签发 | Conditional：覆盖 terms failure；未区分 spec-level error 与 current baseline 具体 API error surface | Important | 在 5-F 中按“修复后 Spec 描述”改写。 |
| `IDENTITY-SPEC-LOGIN-002` | 第三方登录请求只有满足 `LOGIN-IN-TERMS-ACCEPTED` 后才能继续处理，否则返回 `LOGIN-ERR-TERMS-REQUIRED`。 | Current code baseline 下，Apple / WeChat 登录请求只有满足 `LOGIN-IN-TERMS-ACCEPTED` 后才能继续认证处理；否则返回 `LOGIN-ERR-TERMS-REQUIRED`，并不得进入 provider token subject 处理、身份解析、账号创建或 session 签发流程。 | Pass：单一第三方 terms gate | Conditional：未写清失败后不得处理 provider token subject 或 session | Conditional：覆盖 terms failure；未限定 Apple/WeChat 当前 provider baseline | Important | 在 5-F 中按“修复后 Spec 描述”改写。 |
| `IDENTITY-SPEC-LOGIN-003` | 手机号、Apple 和 WeChat 登录入口必须处于 `LOGIN-STATE-PUBLIC-ENDPOINT`。 | 手机号、Apple 和 WeChat 登录入口必须处于 `LOGIN-STATE-PUBLIC-ENDPOINT`；该状态只表示不要求既有认证 session，仍必须执行 schema version、terms、凭证和账号状态门禁。 | Pass：单一 public endpoint 状态 | Conditional：public endpoint 的语义边界不足 | Conditional：覆盖无既有认证访问；未说明仍需 schema、terms、凭证和账号状态门禁 | Suggestion | 在 5-F 中按“修复后 Spec 描述”改写。 |
| `IDENTITY-SPEC-LOGIN-004` | 账号不处于 `LOGIN-STATE-ACCOUNT-ACTIVE` 时，系统必须返回 `LOGIN-ERR-INACTIVE-ACCOUNT` 并拒绝登录。 | 账号不处于 `LOGIN-STATE-ACCOUNT-ACTIVE` 时，系统必须返回 `LOGIN-ERR-INACTIVE-ACCOUNT` 并拒绝登录；不得创建 `LOGIN-STATE-SESSION-ACTIVE` 或返回 `LOGIN-OUT-TOKEN-PAIR`。 | Pass：单一账号状态失败契约 | Conditional：缺少状态转移后置结果 | Conditional：覆盖 inactive 失败；未明确不得创建 `LOGIN-STATE-SESSION-ACTIVE` 或 `LOGIN-OUT-TOKEN-PAIR` | Suggestion | 在 5-F 中按“修复后 Spec 描述”改写。 |
| `IDENTITY-SPEC-LOGIN-005` | 登录成功时，系统必须创建 `LOGIN-STATE-SESSION-ACTIVE`。 | 登录请求通过 schema version、terms、凭证和账号状态门禁后，系统必须为本次解析或创建的用户创建 `LOGIN-STATE-SESSION-ACTIVE`。 | Pass：单一成功状态输出 | Conditional：前置条件和 session 归属对象不完整 | Conditional：覆盖 session 创建；未显式绑定到本次登录用户 | Suggestion | 在 5-F 中按“修复后 Spec 描述”改写。 |
| `IDENTITY-SPEC-LOGIN-006` | 登录成功响应必须返回 `LOGIN-OUT-TOKEN-PAIR`。 | 登录成功响应必须返回 `LOGIN-OUT-TOKEN-PAIR`；token 生命周期、有效期和轮换行为以 `IDENTITY-SPEC-TOKEN-*` 为 source of truth。 | Pass：单一成功响应输出 | Conditional：token 输出应引用 token spec，避免重复 token 生命周期 | Pass：覆盖当前用户、access/refresh token 和 access expiry 输出 | Suggestion | 在 5-F 中按“修复后 Spec 描述”改写。 |
| `IDENTITY-SPEC-LOGIN-007` | 登录和刷新请求携带不支持的 `LOGIN-IN-SCHEMA-VERSION` 时，系统必须返回 `LOGIN-ERR-UNSUPPORTED-SCHEMA`。 | 登录和刷新请求携带不支持的 `LOGIN-IN-SCHEMA-VERSION` 时，系统必须在认证状态变化前返回 `LOGIN-ERR-UNSUPPORTED-SCHEMA`；失败后不得创建 session、签发 token 或轮换 token；API 字段形态由 API contract 承接。 | Conditional：登录和刷新共享 schema compatibility 规则，可保留 | Conditional：未说明该失败发生在认证状态变化前；`LOGIN-ERR-UNSUPPORTED-SCHEMA` 应为 spec-level compatibility failure，不等同 API schema 字段实现 | Conditional：覆盖 unsupported schema failure；未明确不得创建 session、不得刷新 token | Important | 在 5-F 中按“修复后 Spec 描述”改写。 |

跨文档发现与 5-F 修复方案：
| 对象 | 问题 | 影响 | 级别 | 5-F 修复方案 |
| --- | --- | --- | --- | --- |
| `traceability.md` login 行 | `IDENTITY-LOGIN-001..007` 的 `Spec Flow` 仍为 `TBD - 后续补齐`，但 `IDENTITY-SPEC-LOGIN-001..007` 已存在。 | 追溯链路显示落后，后续 AC/TC 生成可能继续引用 TBD。 | Important | 在 5-F 中同步 `Spec Flow` 到 `IDENTITY-SPEC-LOGIN-001..007`；`AC` 和 `TC` 继续保留 `TBD - 后续补齐`，不伪造测试或代码新证据。 |
| login target boundary | login requirements/spec 与 OTP target、provider baseline、token lifecycle 存在交叉引用，但 item 内部分边界不清。 | 后续生成 AC/TC 时可能把 terms persistence、真实 provider validation 或 token lifecycle 细节错误归入 login 子章节。 | Important | 在 5-F 中把 login item 明确为 current-code-baseline 登录处理边界；terms persistence、真实 provider validation、token lifecycle 细节分别由后续 consent/provider/token 文档承接。 |
| login flow ordering | spec 只有 item table，缺少紧凑登录处理顺序。 | AC/TC 难判断 schema、terms、credential、account status、session creation 的先后和失败副作用。 | Suggestion | 可在 `IDENTITY-LOGIN` spec 小节补一个简短 flow segment：public entry -> schema version -> terms -> credential/identity -> account active -> session/response；失败分支不产生 session/token。 |

Task 5-R 执行情况：
- 已执行：完成 `IDENTITY-LOGIN-001..007` 和 `IDENTITY-SPEC-LOGIN-001..007` 的逐条内容契约语义审查。
- 已执行：按 Requirement / Spec 分离格式形成 5-F 修复输入表，并在 item 后附原始描述。
- 未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；等待用户确认后再执行 Task 5-F。

Task 5-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 5-R | Confirmed by user | 用户已确认本审查表，并放行 Task 5-F。 |
| Task 5-F | Confirmed by user | 用户已确认 login 子章节修复复审，并放行 Task 6-R。 |

### IDENTITY-LOGIN 登录与 session 签发 5-F 修复复审

修复范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-LOGIN-001..007`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的登录 Ref ID、`LOGIN-FLOW-*` flow segment、`IDENTITY-SPEC-LOGIN-001..007`
- Traceability：`docs/product/base/identity-account-lifecycle/traceability.md` 的 `IDENTITY-LOGIN-001..007` Spec Flow

本轮结果：pass for Task 5-F scope。已按用户确认的 Requirement / Spec 分离方案修复 login 子章节；AC、TC、Product Base merge、release readiness 和代码实现不在本轮范围内。

Requirement 修复复审表：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 复审结论 |
| --- | --- | --- | --- |
| `IDENTITY-LOGIN-001` | 手机号登录请求必须在用户接受条款后才能继续处理。 | 当前代码基线的手机号登录请求必须声明已接受条款后才允许继续认证处理；未接受时必须拒绝，且不得进入身份解析、账号创建或 session 签发；该要求不代表 Terms/Privacy consent 持久化已实现。 | Pass：terms gate 的失败后置边界和 consent persistence 非目标已补清。 |
| `IDENTITY-LOGIN-002` | 第三方登录请求必须在用户接受条款后才能继续处理。 | 当前代码基线的 Apple / WeChat 登录请求必须声明已接受条款后才允许继续认证处理；未接受时必须拒绝，且不得进入 provider token subject 处理、身份解析、账号创建或 session 签发。 | Pass：Apple/WeChat current baseline 和失败后置边界已补清。 |
| `IDENTITY-LOGIN-003` | 手机号、Apple、WeChat 登录入口必须允许未认证客户端调用。 | 手机号、Apple、WeChat 登录入口必须不要求既有认证 session；public entry 不得绕过 schema version、terms、凭证或账号状态校验。 | Pass：public endpoint 的权限边界从“允许调用”改为“不要求既有 session”。 |
| `IDENTITY-LOGIN-004` | 系统必须拒绝非 `active` 账号登录。 | 身份解析或账号创建得到的账号不为 `active` 时，系统必须拒绝登录，且不得创建认证 session 或发放 token。 | Pass：账号状态门禁的触发点和失败副作用已补清。 |
| `IDENTITY-LOGIN-005` | 登录成功时，系统必须创建一个 `active` 认证 session。 | 登录请求通过 schema version、terms、凭证和账号状态门禁后，系统必须为本次解析或创建的用户创建 `active` 认证 session。 | Pass：成功 session 创建的前置条件和归属对象已补清。 |
| `IDENTITY-LOGIN-006` | 登录成功响应必须返回当前用户、access token、refresh token 和 access token 过期时间。 | 登录成功响应必须返回当前用户、access token、refresh token 和 access token 过期时间；access / refresh token 的生命周期和轮换语义由 `IDENTITY-TOKEN` 子章节承接。 | Pass：login 输出和 token lifecycle source of truth 已分离。 |
| `IDENTITY-LOGIN-007` | 登录和刷新请求必须拒绝不支持的 schema version。 | 当前代码基线的登录和刷新请求必须在认证状态变化前拒绝不支持的 schema version；拒绝后不得创建 session、发放 token 或刷新 token；具体 schema 字段形态由 API contract 承接。 | Pass：schema compatibility 的失败时机、副作用和 API contract 边界已补清。 |

Spec 修复复审表：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 复审结论 |
| --- | --- | --- | --- |
| `IDENTITY-SPEC-LOGIN-001` | 手机号登录请求只有满足 `LOGIN-IN-TERMS-ACCEPTED` 后才能继续处理，否则返回 `LOGIN-ERR-TERMS-REQUIRED`。 | Current code baseline 下，手机号登录请求只有满足 `LOGIN-IN-TERMS-ACCEPTED` 后才能继续认证处理；否则返回 `LOGIN-ERR-TERMS-REQUIRED`，并不得进入身份解析、账号创建或 session 签发流程。 | Pass：spec failure boundary 已对齐 requirement。 |
| `IDENTITY-SPEC-LOGIN-002` | 第三方登录请求只有满足 `LOGIN-IN-TERMS-ACCEPTED` 后才能继续处理，否则返回 `LOGIN-ERR-TERMS-REQUIRED`。 | Current code baseline 下，Apple / WeChat 登录请求只有满足 `LOGIN-IN-TERMS-ACCEPTED` 后才能继续认证处理；否则返回 `LOGIN-ERR-TERMS-REQUIRED`，并不得进入 provider token subject 处理、身份解析、账号创建或 session 签发流程。 | Pass：第三方登录 spec 限定 Apple/WeChat current baseline，并补齐 provider token subject 失败边界。 |
| `IDENTITY-SPEC-LOGIN-003` | 手机号、Apple 和 WeChat 登录入口必须处于 `LOGIN-STATE-PUBLIC-ENDPOINT`。 | 手机号、Apple 和 WeChat 登录入口必须处于 `LOGIN-STATE-PUBLIC-ENDPOINT`；该状态只表示不要求既有认证 session，仍必须执行 schema version、terms、凭证和账号状态门禁。 | Pass：public endpoint 状态定义已避免绕过门禁的歧义。 |
| `IDENTITY-SPEC-LOGIN-004` | 账号不处于 `LOGIN-STATE-ACCOUNT-ACTIVE` 时，系统必须返回 `LOGIN-ERR-INACTIVE-ACCOUNT` 并拒绝登录。 | 账号不处于 `LOGIN-STATE-ACCOUNT-ACTIVE` 时，系统必须返回 `LOGIN-ERR-INACTIVE-ACCOUNT` 并拒绝登录；不得创建 `LOGIN-STATE-SESSION-ACTIVE` 或返回 `LOGIN-OUT-TOKEN-PAIR`。 | Pass：inactive account 的状态转移禁止项已补清。 |
| `IDENTITY-SPEC-LOGIN-005` | 登录成功时，系统必须创建 `LOGIN-STATE-SESSION-ACTIVE`。 | 登录请求通过 schema version、terms、凭证和账号状态门禁后，系统必须为本次解析或创建的用户创建 `LOGIN-STATE-SESSION-ACTIVE`。 | Pass：成功路径的前置条件和 session 归属已补清。 |
| `IDENTITY-SPEC-LOGIN-006` | 登录成功响应必须返回 `LOGIN-OUT-TOKEN-PAIR`。 | 登录成功响应必须返回 `LOGIN-OUT-TOKEN-PAIR`；token 生命周期、有效期和轮换行为以 `IDENTITY-SPEC-TOKEN-*` 为 source of truth。 | Pass：login spec 保留输出契约，token lifecycle 移交 token spec。 |
| `IDENTITY-SPEC-LOGIN-007` | 登录和刷新请求携带不支持的 `LOGIN-IN-SCHEMA-VERSION` 时，系统必须返回 `LOGIN-ERR-UNSUPPORTED-SCHEMA`。 | 登录和刷新请求携带不支持的 `LOGIN-IN-SCHEMA-VERSION` 时，系统必须在认证状态变化前返回 `LOGIN-ERR-UNSUPPORTED-SCHEMA`；失败后不得创建 session、签发 token 或轮换 token；API 字段形态由 API contract 承接。 | Pass：schema version 失败的时机、副作用和字段边界已补清。 |

Spec Ref / Flow 修复复审表：
| 对象 | 修复内容 | 复审结论 |
| --- | --- | --- |
| `LOGIN-IN-TERMS-ACCEPTED` | 明确为当前登录请求中的用户声明，不表示 Terms/Privacy consent 持久化已实现。 | Pass：输入定义与 requirement 的 current baseline 边界一致。 |
| `LOGIN-IN-SCHEMA-VERSION` | 明确为兼容性版本信号，具体字段形态由 API contract 承接。 | Pass：spec 未越界写 API schema。 |
| `LOGIN-STATE-PUBLIC-ENDPOINT` | 明确 public endpoint 只是不要求既有 session，不绕过 schema、terms、凭证或账号状态校验。 | Pass：权限语义清晰。 |
| `LOGIN-ERR-*` | 补齐 terms、inactive account、unsupported schema 的失败副作用。 | Pass：失败路径具备可验收后置边界。 |
| `LOGIN-FLOW-AUTHENTICATE` | 新增 public entry -> schema version -> terms -> credential/identity -> account active -> session/token pair 的登录处理顺序。 | Pass：flow segment 支持后续 AC/TC 生成，不新增实现任务。 |
| `LOGIN-FLOW-REFRESH-SCHEMA` | 新增 refresh 请求进入 token 生命周期前的 schema version gate。 | Pass：保留 login compatibility 边界，同时将 token 生命周期交给 `IDENTITY-SPEC-TOKEN-*`。 |

Traceability 修复复审表：
| Requirement | Spec Flow | AC | Test Case ID | 复审结论 |
| --- | --- | --- | --- | --- |
| `IDENTITY-LOGIN-001` | `IDENTITY-SPEC-LOGIN-001` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-LOGIN-002` | `IDENTITY-SPEC-LOGIN-002` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-LOGIN-003` | `IDENTITY-SPEC-LOGIN-003` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-LOGIN-004` | `IDENTITY-SPEC-LOGIN-004` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-LOGIN-005` | `IDENTITY-SPEC-LOGIN-005` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-LOGIN-006` | `IDENTITY-SPEC-LOGIN-006` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-LOGIN-007` | `IDENTITY-SPEC-LOGIN-007` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |

Task 5-F 执行情况：
- 已执行：按用户确认的 5-R 方案修复 login requirements、spec items、spec Ref ID 和 flow segment。
- 已执行：同步 `traceability.md` 中 `IDENTITY-LOGIN-001..007` 的 `Spec Flow`。
- 未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 6 token 子章节。

Task 5-F 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 5-F | Confirmed by user | 用户已确认本修复复审表，并放行 Task 6-R。 |
| Task 6-R | Confirmed by user | 用户已确认 token 子章节审查表，并放行 Task 6-F。 |
| Task 6-F | Confirmed by user | 用户已确认 token 子章节修复复审，并放行 Task 7-R。 |

### IDENTITY-TOKEN Access / refresh token 生命周期 6-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-TOKEN-001..012`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-TOKEN-001..012`
- 交叉引用 Ref ID：`TOKEN-STATE-OPAQUE`、`TOKEN-STATE-SESSION-ACTIVE`、`TOKEN-IN-BEARER`、`TOKEN-IN-REFRESH`、`TOKEN-OUT-ROTATED`、`TOKEN-ERR-UNAUTHENTICATED`、`TOKEN-SECURE-RANDOM`
- 只读上下文：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-TOKEN-001..012`，以及 current-code-baseline token 相关代码证据

本轮结果：conditional。token 子章节可继续作为 current-code-baseline Draft 输入；没有阻止 Draft 留存的 blocker。但在生成 AC/TC、Product Base merge 或后续实现计划前，应补清 refresh user-active gate、删除重试例外、token 输出与持久化状态的分离、stateless session 的产品语义边界，并同步 traceability 中已存在的 spec ID。

Requirement 审查与 6-F 修复方案：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 6-F Requirement 修复方案 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-TOKEN-001` | 系统必须签发服务端 opaque access token 和 refresh token。 | 登录或刷新成功时，系统必须向客户端返回服务端 opaque access token 和 refresh token；token 不承载客户端可解析身份 claims，JWT 不归档为已实现。 | Pass：单一 token pair 签发能力 | Conditional：触发条件未说明，容易和 refresh 轮换输出混淆 | Conditional：覆盖 opaque token pair；未明确非 JWT 边界在 item 内 | Suggestion | 在 6-F 中按“修复后 Requirement 描述”改写。 |
| `IDENTITY-TOKEN-002` | 系统必须使用 `SecureRandom` 生成 token 原始字节。 | token 原始值必须由后端使用不可预测的密码学安全随机源生成；Java `SecureRandom` 是当前代码基线实现证据，不作为产品需求唯一表述。 | Conditional：安全目的单一，但写入具体 Java API | Conditional：`SecureRandom` 属于实现层术语，Requirement 应表达安全目标 | Pass：覆盖随机性要求 | Important | Requirement 改写为密码学安全随机源；Spec 可保留 current baseline 的 `SecureRandom` 引用。 |
| `IDENTITY-TOKEN-003` | 系统必须只持久化 access token 和 refresh token 的 hash。 | 系统不得持久化 access token 或 refresh token 明文；持久化会话记录只能保存可用于匹配的 token 摘要值。 | Pass：单一持久化安全约束 | Conditional：`hash` 可接受为安全语义，但应避免写成数据库实现字段 | Pass：覆盖明文不得持久化 | Suggestion | 改为“不得持久化明文 + 只保存摘要值”，字段/算法细节留给 spec/code evidence。 |
| `IDENTITY-TOKEN-004` | access token 默认有效期必须为 30 分钟。 | 当前代码基线下，access token 的有效期必须从签发或刷新轮换时起计算为 30 分钟。 | Pass：单一 TTL 规则 | Conditional：`默认` 未说明从何时起算，也未说明 refresh 轮换会重置 access expiry | Conditional：覆盖 TTL 数值，缺少起算点 | Suggestion | 补充“从签发或刷新轮换时起”。 |
| `IDENTITY-TOKEN-005` | refresh token 默认有效期必须为 30 天。 | 当前代码基线下，refresh token 的有效期必须从签发或刷新轮换时起计算为 30 天。 | Pass：单一 TTL 规则 | Conditional：`默认` 未说明从何时起算，也未说明 refresh 轮换会重置 refresh expiry | Conditional：覆盖 TTL 数值，缺少起算点 | Suggestion | 补充“从签发或刷新轮换时起”。 |
| `IDENTITY-TOKEN-006` | 受保护请求必须从 `Authorization: Bearer` header 提取 access token。 | 受保护用户请求必须携带 access token 才能认证；当前代码基线通过 Bearer token 传递，具体 header 字段形态由 API contract 承接。 | Conditional：目标是认证输入，但直接写 API header | Conditional：Requirement 越界到 API 字段形态 | Conditional：覆盖 bearer 输入；未限定是用户受保护请求，admin ops token 例外未界定 | Important | Requirement 改为产品级“受保护用户请求必须携带 access token”；header 细节留给 spec/API contract。 |
| `IDENTITY-TOKEN-007` | access token 必须匹配 active 且未过期的 session 才能认证通过。 | 常规 access token 认证必须匹配 active 且 access 未过期的认证 session；不匹配、过期或已撤销时必须拒绝认证。 | Pass：单一 access session gate | Conditional：未显式包含 revoked / no-match 失败结果 | Conditional：覆盖 active+expiry；失败副作用不完整 | Suggestion | 补充失败分支和 revoked/no-match 边界。 |
| `IDENTITY-TOKEN-008` | access token 认证必须要求关联用户为 `active` 状态。 | 常规 access token 认证必须要求关联用户为 `active` 状态；账号删除重试的特殊认证路径由 `IDENTITY-DELETE` 子章节承接，不作为常规用户认证通过。 | Pass：单一用户状态 gate | Conditional：当前代码存在 deletion retry 特殊路径，原文未界定例外 | Conditional：覆盖 active 用户要求；缺少删除重试边界 | Important | 在 Requirement 内明确“常规 access token 认证”与 deletion retry 例外归属。 |
| `IDENTITY-TOKEN-009` | refresh token 必须匹配 active 且 refresh 未过期的 session 才能刷新。 | refresh token 必须匹配 active 且 refresh 未过期的 session，并且关联用户为 `active` 状态，才能刷新 token。 | Conditional：refresh session gate 单一，但遗漏用户状态 gate | Conditional：未说明 refresh 与 access 的用户状态要求一致 | Conditional：覆盖 session active + refresh expiry；遗漏关联用户 active | Important | 补充关联用户 active 前置条件。 |
| `IDENTITY-TOKEN-010` | refresh 成功必须轮换同一 session 的 access token hash 和 refresh token hash。 | refresh 成功必须在同一认证 session 上发放新的 access token 和 refresh token，并使旧 access / refresh token 不再可用于后续认证或刷新；持久化摘要替换细节由 spec 承接。 | Conditional：同时表达客户端发放和持久化 hash 替换 | Conditional：Requirement 写入 hash 细节，且未明确旧 token 失效结果 | Conditional：覆盖轮换，但缺少旧 token 不可用这一可观察安全结果 | Important | Requirement 改写为同一 session 轮换和旧 token 失效；hash 替换放到 Spec。 |
| `IDENTITY-TOKEN-011` | refresh token 为空、无效、过期或已被轮换后，系统必须返回未认证错误。 | refresh token 缺失、空白、无效、过期或已被轮换时，系统必须返回未认证错误，且不得刷新、轮换或创建新的 session/token。 | Pass：单一 refresh failure rule | Conditional：未说明失败后不得产生状态变化 | Conditional：覆盖错误类型；缺少失败副作用 | Suggestion | 补充 no state change / no token output。 |
| `IDENTITY-TOKEN-012` | 后端安全配置必须使用 stateless session 策略。 | 受保护 API 认证不得依赖服务端 HTTP session 或 cookie session；用户认证状态必须由 token 与认证 session 记录共同证明。 | Conditional：安全目标单一，但写成后端配置任务 | Conditional：`stateless session 策略` 属于实现配置语言 | Conditional：覆盖无 HTTP session 依赖；未说明仍依赖服务端 auth session 记录 | Important | Requirement 改为产品/安全行为；Spec 可承接 Spring security stateless baseline。 |

Spec 审查与 6-F 修复方案：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 6-F Spec 修复方案 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-TOKEN-001` | 系统必须签发 `TOKEN-STATE-OPAQUE` access token 和 refresh token。 | 登录或刷新成功时，系统必须签发 `TOKEN-STATE-OPAQUE` access token 和 refresh token，并把该 token pair 返回给客户端；JWT claims、JWT 签名校验和 JWKS 不属于当前代码基线。 | Pass：单一 token pair 输出 | Conditional：缺少触发条件和非 JWT 边界 | Conditional：覆盖 opaque pair；未说明输出给客户端 | Suggestion | 在 6-F 中按“修复后 Spec 描述”改写。 |
| `IDENTITY-SPEC-TOKEN-002` | 系统必须使用 `TOKEN-SECURE-RANDOM` 生成 token 原始字节。 | 系统必须分别使用 `TOKEN-SECURE-RANDOM` 为 access token 和 refresh token 生成不可预测原始值；current Java baseline 使用 `SecureRandom`。 | Pass：单一随机性契约 | Conditional：未说明 access/refresh token 均独立生成 | Pass：覆盖安全随机源 | Suggestion | 补清 access/refresh 分别生成，保留 current baseline 实现引用。 |
| `IDENTITY-SPEC-TOKEN-003` | 系统必须只持久化 access token 和 refresh token 的 hash，不得持久化 token 明文。 | 认证 session 持久化状态必须只保存 access token 和 refresh token 的摘要值；token 明文只能在签发或刷新成功响应中返回给客户端，不得写入持久化 session。 | Pass：单一持久化安全契约 | Conditional：未区分客户端输出明文和持久化明文 | Pass：覆盖明文不得持久化 | Suggestion | 补充 raw token 只在成功响应输出。 |
| `IDENTITY-SPEC-TOKEN-004` | access token 默认有效期必须为 30 分钟。 | access token 的 `expiresAt` 必须从登录签发或 refresh 轮换时起计算为 30 分钟，并随成功响应返回。 | Pass：单一 access TTL | Conditional：起算点和响应输出关系未说明 | Conditional：覆盖 TTL；未绑定登录/刷新两个签发点 | Suggestion | 补充起算点和响应输出。 |
| `IDENTITY-SPEC-TOKEN-005` | refresh token 默认有效期必须为 30 天。 | refresh token 的 refresh expiry 必须从登录签发或 refresh 轮换时起计算为 30 天，并用于后续 refresh eligibility 判断。 | Pass：单一 refresh TTL | Conditional：起算点和使用场景未说明 | Conditional：覆盖 TTL；未绑定刷新 eligibility | Suggestion | 补充起算点和用途。 |
| `IDENTITY-SPEC-TOKEN-006` | 受保护请求必须从 `TOKEN-IN-BEARER` 提取 access token。 | 常规受保护用户请求必须从 `TOKEN-IN-BEARER` 提取 access token；缺失、格式不匹配或认证失败时不得建立用户认证上下文，并按受保护端点规则返回 `TOKEN-ERR-UNAUTHENTICATED`。 | Conditional：输入提取和失败输出可保留在一个 spec item | Conditional：未说明缺失/格式不匹配的失败行为，且 admin ops token 例外未界定 | Conditional：覆盖 bearer 提取；缺少异常路径 | Important | 限定常规用户请求，补充缺失/格式错误失败行为；admin ops 例外不纳入本 item。 |
| `IDENTITY-SPEC-TOKEN-007` | access token 只有匹配 `TOKEN-STATE-SESSION-ACTIVE` 时才能认证通过，否则返回 `TOKEN-ERR-UNAUTHENTICATED`。 | access token 只有匹配 active 且 access 未过期的认证 session 时才能通过常规用户认证；未匹配、过期、已撤销或已轮换时必须返回 `TOKEN-ERR-UNAUTHENTICATED`。 | Pass：单一 access session gate | Conditional：`TOKEN-STATE-SESSION-ACTIVE` 未区分 access expiry 与 refresh expiry | Conditional：覆盖 active+unexpired；rotated/no-match 边界隐含 | Important | 拆清 access session active 语义，补充 revoked/rotated/no-match 失败。 |
| `IDENTITY-SPEC-TOKEN-008` | access token 认证必须要求关联用户为 active 状态，否则返回 `TOKEN-ERR-UNAUTHENTICATED`。 | 常规 access token 认证必须要求关联用户为 active 状态，否则返回 `TOKEN-ERR-UNAUTHENTICATED`；账号删除重试 fallback 使用同一 access token 输入但由 `IDENTITY-SPEC-DELETE-*` 承接。 | Pass：单一用户状态 gate | Conditional：未说明 current baseline 中删除重试 fallback 的归属 | Conditional：覆盖 active 用户；缺少特殊路径边界 | Important | 补充 deletion retry fallback 边界，避免与 delete 子章节冲突。 |
| `IDENTITY-SPEC-TOKEN-009` | `TOKEN-IN-REFRESH` 只有匹配 active 且 refresh 未过期 session 时才能刷新。 | 在 `LOGIN-FLOW-REFRESH-SCHEMA` 通过后，`TOKEN-IN-REFRESH` 只有匹配 active 且 refresh 未过期 session、且关联用户为 active 状态时才能刷新；否则返回 `TOKEN-ERR-UNAUTHENTICATED`。 | Conditional：refresh eligibility 单一，但需包含 schema gate 引用和 user gate | Conditional：未引用 login schema version gate，且遗漏关联用户 active | Conditional：覆盖 session refresh eligibility；遗漏用户状态和错误输出 | Important | 补充 schema gate 引用、关联用户 active 和失败错误。 |
| `IDENTITY-SPEC-TOKEN-010` | refresh 成功必须产生 `TOKEN-OUT-ROTATED`，并替换同一 session 的旧 token hash。 | refresh 成功必须在同一 session 上生成新的 access token 和 refresh token，替换持久化 access / refresh token 摘要，返回新的 token pair，并使旧 access / refresh token 后续匹配失败。 | Conditional：混合输出、持久化状态和旧 token 失效，仍可作为一个 refresh success spec | Conditional：`TOKEN-OUT-ROTATED` 当前定义为 hash 输出，和客户端输出混淆 | Conditional：覆盖 hash 替换；未明确旧 token 失效和新 token pair 返回 | Important | 拆分或重定义 `TOKEN-OUT-ROTATED`，明确 client output 与 persistence side effect。 |
| `IDENTITY-SPEC-TOKEN-011` | refresh token 为空、无效、过期或已被轮换后，系统必须返回 `TOKEN-ERR-UNAUTHENTICATED`。 | refresh token 缺失、空白、无效、过期、已撤销 session 关联或已被轮换后，系统必须返回 `TOKEN-ERR-UNAUTHENTICATED`，且不得创建 session、替换 token 摘要或返回新 token pair。 | Pass：单一 refresh failure contract | Conditional：未覆盖 revoked session 关联和 no-state-change | Conditional：覆盖常见失败；缺少失败副作用 | Suggestion | 补充 revoked/no state change。 |
| `IDENTITY-SPEC-TOKEN-012` | 后端安全配置必须使用 stateless session 策略，不依赖服务端 HTTP session。 | 当前代码基线的受保护 API 认证必须不创建或依赖服务端 HTTP session；认证成功来自 bearer token 匹配持久化认证 session，Spring Security stateless 配置是实现证据。 | Conditional：规范了安全行为，但仍含后端配置语言 | Conditional：未说明 stateless 不等于无服务端认证 session 记录 | Conditional：覆盖无 HTTP session；需要区分 auth session 记录 | Important | Spec 保留 current baseline 配置证据，同时补清“stateless HTTP session”与 auth session 记录的差异。 |

跨文档发现与 6-F 修复方案：
| 对象 | 问题 | 影响 | 级别 | 6-F 修复方案 |
| --- | --- | --- | --- | --- |
| `traceability.md` token 行 | `IDENTITY-TOKEN-001..012` 的 `Spec Flow` 仍为 `TBD - 后续补齐`，但 `IDENTITY-SPEC-TOKEN-001..012` 已存在。 | 后续 AC/TC 生成可能继续引用 TBD，导致 token 链路断裂。 | Important | 在 6-F 中同步 `Spec Flow` 到 `IDENTITY-SPEC-TOKEN-001..012`；`AC` 和 `TC` 继续保留 `TBD - 后续补齐`，不伪造测试证据。 |
| `TOKEN-OUT-ROTATED` Ref ID | 当前定义为“新 access token hash 和 refresh token hash”，但类型是输出；它把客户端输出和持久化摘要状态混在一起。 | AC/TC 可能误以为 hash 会返回给客户端，或无法判断 refresh 成功响应。 | Important | 在 6-F 中重定义为客户端可观察的新 token pair，或拆成 `TOKEN-OUT-ROTATED-TOKEN-PAIR` 与 `TOKEN-STATE-HASH-ROTATED`。 |
| `TOKEN-STATE-SESSION-ACTIVE` Ref ID | 同一个状态被 access 认证和 refresh eligibility 共用，但 access expiry 与 refresh expiry 不是同一条件。 | 后续验收无法区分 access 过期但 refresh 仍可用的状态。 | Important | 在 6-F 中拆清 access-session-active 与 refresh-session-active，或在 spec item 内显式说明不同 expiry。 |
| deletion retry fallback | current code baseline 允许账号删除重试路径在 deleted/deletion_requested 状态下通过特殊认证 fallback；token 子章节未界定该例外。 | `IDENTITY-TOKEN-008` 可能和删除重试需求冲突。 | Important | 在 6-F 中把 token item 限定为常规用户认证；删除重试由 `IDENTITY-DELETE` 子章节承接。 |

Task 6-R 执行情况：
- 已执行：完成 `IDENTITY-TOKEN-001..012` 和 `IDENTITY-SPEC-TOKEN-001..012` 的逐条内容契约语义审查。
- 已执行：按 Requirement / Spec 分离格式形成 6-F 修复输入表，并在 item 后附原始描述与修复后描述。
- 未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；等待用户确认后再执行 Task 6-F。

Task 6-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 6-R | Confirmed by user | 用户已确认本审查表，并放行 Task 6-F。 |
| Task 6-F | Confirmed by user | 用户已确认 token 子章节修复复审，并放行 Task 7-R。 |

### IDENTITY-TOKEN Access / refresh token 生命周期 6-F 修复复审

修复范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-TOKEN-001..012`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 token Ref ID、`TOKEN-FLOW-*` flow segment、`IDENTITY-SPEC-TOKEN-001..012`
- Traceability：`docs/product/base/identity-account-lifecycle/traceability.md` 的 `IDENTITY-TOKEN-001..012` Spec Flow

本轮结果：pass for Task 6-F scope。已按用户确认的 Requirement / Spec 分离方案修复 token 子章节；AC、TC、Product Base merge、release readiness 和代码实现不在本轮范围内。

Requirement 修复复审表：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 复审结论 |
| --- | --- | --- | --- |
| `IDENTITY-TOKEN-001` | 系统必须签发服务端 opaque access token 和 refresh token。 | 登录或刷新成功时，系统必须向客户端返回服务端 opaque access token 和 refresh token；token 不承载客户端可解析身份 claims，JWT 不归档为已实现。 | Pass：触发条件、客户端输出和非 JWT 边界已补清。 |
| `IDENTITY-TOKEN-002` | 系统必须使用 `SecureRandom` 生成 token 原始字节。 | token 原始值必须由后端使用不可预测的密码学安全随机源生成；Java `SecureRandom` 是当前代码基线实现证据，不作为产品需求唯一表述。 | Pass：Requirement 已从具体 Java API 收回到安全目标。 |
| `IDENTITY-TOKEN-003` | 系统必须只持久化 access token 和 refresh token 的 hash。 | 系统不得持久化 access token 或 refresh token 明文；持久化会话记录只能保存可用于匹配的 token 摘要值。 | Pass：明文禁止与摘要持久化边界已补清。 |
| `IDENTITY-TOKEN-004` | access token 默认有效期必须为 30 分钟。 | 当前代码基线下，access token 的有效期必须从签发或刷新轮换时起计算为 30 分钟。 | Pass：TTL 起算点已补清。 |
| `IDENTITY-TOKEN-005` | refresh token 默认有效期必须为 30 天。 | 当前代码基线下，refresh token 的有效期必须从签发或刷新轮换时起计算为 30 天。 | Pass：refresh TTL 起算点已补清。 |
| `IDENTITY-TOKEN-006` | 受保护请求必须从 `Authorization: Bearer` header 提取 access token。 | 受保护用户请求必须携带 access token 才能认证；当前代码基线通过 Bearer token 传递，具体 header 字段形态由 API contract 承接。 | Pass：Requirement 已转为产品级认证输入，API header 细节移交 API contract。 |
| `IDENTITY-TOKEN-007` | access token 必须匹配 active 且未过期的 session 才能认证通过。 | 常规 access token 认证必须匹配 active 且 access 未过期的认证 session；不匹配、过期或已撤销时必须拒绝认证。 | Pass：失败分支和 revoked 边界已补清。 |
| `IDENTITY-TOKEN-008` | access token 认证必须要求关联用户为 `active` 状态。 | 常规 access token 认证必须要求关联用户为 `active` 状态；账号删除重试的特殊认证路径由 `IDENTITY-DELETE` 子章节承接，不作为常规用户认证通过。 | Pass：删除重试例外已从常规 token 认证边界中分离。 |
| `IDENTITY-TOKEN-009` | refresh token 必须匹配 active 且 refresh 未过期的 session 才能刷新。 | refresh token 必须匹配 active 且 refresh 未过期的 session，并且关联用户为 `active` 状态，才能刷新 token。 | Pass：refresh user-active gate 已补清。 |
| `IDENTITY-TOKEN-010` | refresh 成功必须轮换同一 session 的 access token hash 和 refresh token hash。 | refresh 成功必须在同一认证 session 上发放新的 access token 和 refresh token，并使旧 access / refresh token 不再可用于后续认证或刷新；持久化摘要替换细节由 spec 承接。 | Pass：Requirement 已表达可观察轮换结果，hash 替换移交 spec。 |
| `IDENTITY-TOKEN-011` | refresh token 为空、无效、过期或已被轮换后，系统必须返回未认证错误。 | refresh token 缺失、空白、无效、过期或已被轮换时，系统必须返回未认证错误，且不得刷新、轮换或创建新的 session/token。 | Pass：失败副作用已补清。 |
| `IDENTITY-TOKEN-012` | 后端安全配置必须使用 stateless session 策略。 | 受保护 API 认证不得依赖服务端 HTTP session 或 cookie session；用户认证状态必须由 token 与认证 session 记录共同证明。 | Pass：Requirement 已从后端配置语言转为认证行为边界。 |

Spec 修复复审表：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 复审结论 |
| --- | --- | --- | --- |
| `IDENTITY-SPEC-TOKEN-001` | 系统必须签发 `TOKEN-STATE-OPAQUE` access token 和 refresh token。 | 登录或刷新成功时，系统必须签发 `TOKEN-STATE-OPAQUE` access token 和 refresh token，并把该 token pair 返回给客户端；JWT claims、JWT 签名校验和 JWKS 不属于当前代码基线。 | Pass：触发、输出和非 JWT 边界已补清。 |
| `IDENTITY-SPEC-TOKEN-002` | 系统必须使用 `TOKEN-SECURE-RANDOM` 生成 token 原始字节。 | 系统必须分别使用 `TOKEN-SECURE-RANDOM` 为 access token 和 refresh token 生成不可预测原始值；current Java baseline 使用 `SecureRandom`。 | Pass：access / refresh 独立生成要求已补清。 |
| `IDENTITY-SPEC-TOKEN-003` | 系统必须只持久化 access token 和 refresh token 的 hash，不得持久化 token 明文。 | 认证 session 持久化状态必须只保存 access token 和 refresh token 的摘要值；token 明文只能在签发或刷新成功响应中返回给客户端，不得写入持久化 session。 | Pass：客户端明文输出与持久化摘要状态已分离。 |
| `IDENTITY-SPEC-TOKEN-004` | access token 默认有效期必须为 30 分钟。 | access token 的 `expiresAt` 必须从登录签发或 refresh 轮换时起计算为 30 分钟，并随成功响应返回。 | Pass：起算点和响应输出已补清。 |
| `IDENTITY-SPEC-TOKEN-005` | refresh token 默认有效期必须为 30 天。 | refresh token 的 refresh expiry 必须从登录签发或 refresh 轮换时起计算为 30 天，并用于后续 refresh eligibility 判断。 | Pass：起算点和 refresh eligibility 用途已补清。 |
| `IDENTITY-SPEC-TOKEN-006` | 受保护请求必须从 `TOKEN-IN-BEARER` 提取 access token。 | 常规受保护用户请求必须从 `TOKEN-IN-BEARER` 提取 access token；缺失、格式不匹配或认证失败时不得建立用户认证上下文，并按受保护端点规则返回 `TOKEN-ERR-UNAUTHENTICATED`。 | Pass：常规用户请求范围和失败副作用已补清。 |
| `IDENTITY-SPEC-TOKEN-007` | access token 只有匹配 `TOKEN-STATE-SESSION-ACTIVE` 时才能认证通过，否则返回 `TOKEN-ERR-UNAUTHENTICATED`。 | access token 只有匹配 `TOKEN-STATE-ACCESS-SESSION-ACTIVE` 时才能通过常规用户认证；未匹配、过期、已撤销或已轮换时必须返回 `TOKEN-ERR-UNAUTHENTICATED`。 | Pass：access session active 状态已从 refresh session active 中拆清。 |
| `IDENTITY-SPEC-TOKEN-008` | access token 认证必须要求关联用户为 active 状态，否则返回 `TOKEN-ERR-UNAUTHENTICATED`。 | 常规 access token 认证必须要求关联用户为 active 状态，否则返回 `TOKEN-ERR-UNAUTHENTICATED`；账号删除重试 fallback 使用同一 access token 输入但由 `IDENTITY-SPEC-DELETE-*` 承接。 | Pass：deletion retry fallback 已路由到 delete spec。 |
| `IDENTITY-SPEC-TOKEN-009` | `TOKEN-IN-REFRESH` 只有匹配 active 且 refresh 未过期 session 时才能刷新。 | 在 `LOGIN-FLOW-REFRESH-SCHEMA` 通过后，`TOKEN-IN-REFRESH` 只有匹配 `TOKEN-STATE-REFRESH-SESSION-ACTIVE` 且关联用户为 active 状态时才能刷新；否则返回 `TOKEN-ERR-UNAUTHENTICATED`。 | Pass：schema gate、refresh session active 和 user-active gate 已补清。 |
| `IDENTITY-SPEC-TOKEN-010` | refresh 成功必须产生 `TOKEN-OUT-ROTATED`，并替换同一 session 的旧 token hash。 | refresh 成功必须在同一 session 上生成新的 access token 和 refresh token，产生 `TOKEN-OUT-ROTATED-TOKEN-PAIR`，替换持久化 access / refresh token 摘要进入 `TOKEN-STATE-HASH-ROTATED`，并使旧 access / refresh token 后续匹配失败。 | Pass：客户端输出、持久化状态和旧 token 失效已拆清。 |
| `IDENTITY-SPEC-TOKEN-011` | refresh token 为空、无效、过期或已被轮换后，系统必须返回 `TOKEN-ERR-UNAUTHENTICATED`。 | refresh token 缺失、空白、无效、过期、已撤销 session 关联或已被轮换后，系统必须返回 `TOKEN-ERR-UNAUTHENTICATED`，且不得创建 session、替换 token 摘要或返回新 token pair。 | Pass：revoked session 和 no-state-change 边界已补清。 |
| `IDENTITY-SPEC-TOKEN-012` | 后端安全配置必须使用 stateless session 策略，不依赖服务端 HTTP session。 | 当前代码基线的受保护 API 认证必须不创建或依赖服务端 HTTP session；认证成功来自 bearer token 匹配持久化认证 session，Spring Security stateless 配置仅作为实现证据。 | Pass：stateless HTTP session 与持久化 auth session 已分离。 |

Spec Ref / Flow 修复复审表：
| 对象 | 修复内容 | 复审结论 |
| --- | --- | --- |
| `TOKEN-STATE-OPAQUE` | 明确 opaque token 非 JWT，客户端不得解析身份 claims。 | Pass：非目标边界清晰。 |
| `TOKEN-STATE-ACCESS-SESSION-ACTIVE` / `TOKEN-STATE-REFRESH-SESSION-ACTIVE` | 将 access expiry 与 refresh expiry 的 session eligibility 拆成两个状态。 | Pass：后续 AC/TC 可区分 access 过期但 refresh 仍可用的场景。 |
| `TOKEN-OUT-ROTATED-TOKEN-PAIR` / `TOKEN-STATE-HASH-ROTATED` | 将 refresh 成功的客户端输出和持久化摘要替换拆开。 | Pass：避免把 hash 误认为客户端输出。 |
| `TOKEN-ERR-UNAUTHENTICATED` | 扩展为 token 缺失、格式不匹配、无效、过期、已撤销、已轮换或关联用户不可认证。 | Pass：失败路径更完整。 |
| `TOKEN-FLOW-ISSUE` | 新增登录或刷新成功后的 token 签发 flow。 | Pass：不新增实现任务，只承接已确认 spec。 |
| `TOKEN-FLOW-AUTHENTICATE-BEARER` | 新增常规受保护用户请求的 access token 认证 flow。 | Pass：明确认证上下文创建与失败边界。 |
| `TOKEN-FLOW-REFRESH` | 新增 refresh schema gate 之后的 refresh eligibility、轮换输出和失败边界。 | Pass：refresh user-active gate 和 no-state-change 结果已进入 flow。 |

Traceability 修复复审表：
| Requirement | Spec Flow | AC | Test Case ID | 复审结论 |
| --- | --- | --- | --- | --- |
| `IDENTITY-TOKEN-001` | `IDENTITY-SPEC-TOKEN-001` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-002` | `IDENTITY-SPEC-TOKEN-002` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-003` | `IDENTITY-SPEC-TOKEN-003` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-004` | `IDENTITY-SPEC-TOKEN-004` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-005` | `IDENTITY-SPEC-TOKEN-005` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-006` | `IDENTITY-SPEC-TOKEN-006` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-007` | `IDENTITY-SPEC-TOKEN-007` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-008` | `IDENTITY-SPEC-TOKEN-008` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-009` | `IDENTITY-SPEC-TOKEN-009` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-010` | `IDENTITY-SPEC-TOKEN-010` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-011` | `IDENTITY-SPEC-TOKEN-011` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |
| `IDENTITY-TOKEN-012` | `IDENTITY-SPEC-TOKEN-012` | `TBD - 后续补齐` | `TBD - 后续补齐` | Pass：Spec Flow 已同步；未伪造 AC/TC。 |

Task 6-F 执行情况：
- 已执行：按用户确认的 6-R 方案修复 token requirements、spec Ref ID、flow segment 和 spec items。
- 已执行：同步 `traceability.md` 中 `IDENTITY-TOKEN-001..012` 的 `Spec Flow`。
- 未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 7 当前用户与 profile gate state 子章节。

Task 6-F 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 6-F | Confirmed by user | 用户已确认本修复复审表，并放行 Task 7-R。 |
| Task 7-R | Confirmed by user | 用户已确认 ME 子章节审查并放行 Task 7-F。 |

### IDENTITY-ME 当前用户与 profile gate state 7-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-ME-001..008`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-ME-001..008`
- 交叉引用 Ref ID：`ME-IN-AUTHENTICATED`、`ME-OUT-CURRENT-USER`、`ME-OUT-PROFILE`、`ME-IN-PROFILE-UPDATE`、`ME-ERR-UNAUTHENTICATED`、`ME-ERR-INVALID-AVATAR`、`HOME-OUT-NEXT-ACTION`
- 只读上下文：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-ME-001..008`，以及 current-code-baseline 当前用户、profile update、首评和首页摘要相关代码证据

本轮结果：conditional。ME 子章节可继续作为 current-code-baseline Draft 输入；没有阻止 Draft 留存的 blocker。但在生成 AC/TC、Product Base merge 或后续实现计划前，应补清 API path 与产品语义边界、ME 与 TOKEN 的认证职责分离、profile 缺失/部分更新边界、avatar ref 的空白输入行为，以及首页 next action 实际依赖 onboarding status 与当前场景状态。

Requirement 审查与 7-F 修复方案：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 7-F Requirement 修复方案 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-ME-001` | `/user/me` 必须只允许已认证用户访问。 | 当前用户资料读取能力必须只允许通过常规 access token 认证的用户访问；未认证或认证上下文无效时必须拒绝；具体 endpoint 路径由 API contract 承接。 | Pass：单一认证访问门禁 | Conditional：Requirement 写入具体 API path，且未说明认证上下文无效的失败边界 | Conditional：覆盖已认证用户访问，但与 token 认证门禁职责有重叠 | Important | 在 7-F 中按“修复后 Requirement 描述”改写。 |
| `IDENTITY-ME-002` | `/user/me` 必须返回当前用户 ID、display name、avatar ref、locale、account status 和 onboarding status。 | 当前用户资料读取成功时，系统必须返回当前认证用户的用户标识、display name、avatar ref、locale、account status 和 onboarding status；具体响应字段形态由 API contract 承接。 | Pass：单一 current user 输出 | Conditional：写入 API path，且未限定为当前认证用户 | Pass：覆盖当前用户核心状态 | Suggestion | 在 7-F 中按“修复后 Requirement 描述”改写。 |
| `IDENTITY-ME-003` | `/user/me` 必须返回当前 profile 的 target level 和 daily minutes。 | 当前用户资料读取成功时，系统必须返回当前用户 profile 的 target level 和 daily minutes；若当前代码基线缺失 profile，补建或错误策略不由本 item 承诺。 | Pass：单一 profile 输出 | Conditional：写入 API path，且未说明 profile 缺失边界 | Conditional：覆盖 profile 输出，但缺少缺失 profile 的当前基线行为 | Suggestion | 在 7-F 中按“修复后 Requirement 描述”改写。 |
| `IDENTITY-ME-004` | 当前用户访问必须要求 access token 对应 active 且未过期 session，并且关联用户为 `active` 状态。 | 当前用户资料读取必须复用 `IDENTITY-TOKEN` 的常规 access token 认证结果；认证上下文无效、session 不可认证或关联用户不可认证时必须拒绝访问。 | Conditional：认证门禁单一，但重复定义 token 生命周期规则 | Conditional：与 `IDENTITY-TOKEN-007..008` 重叠，可能造成 source of truth 分散 | Pass：覆盖 token 与 active 用户要求 | Important | 改写为复用 token 认证结果，不在 ME requirement 重定义 session/expiry 细节。 |
| `IDENTITY-ME-005` | 用户必须能更新 display name、avatar ref、target level、daily minutes、reminder enabled 和 reminder time。 | 已认证用户必须只能更新自己的 display name、avatar ref、target level、daily minutes、reminder enabled 和 reminder time；未提供的可选字段不得被强制改写；avatar ref 允许范围由 `IDENTITY-ME-006` 承接。 | Pass：一个自助资料更新能力 | Conditional：缺少“自己”的 ownership 边界和部分更新语义 | Conditional：覆盖可更新字段；未说明字段未提供时的行为 | Important | 补清 authenticated self-update、partial update 和 avatar 边界。 |
| `IDENTITY-ME-006` | 系统必须拒绝非内置头像引用作为 avatar ref。 | 当用户提交 avatar ref 更新时，系统必须只接受内置头像引用；空白或非内置引用必须拒绝，且不得保存该 avatar ref 更新。 | Pass：单一 avatar validation | Conditional：未说明空白输入和失败后置结果 | Conditional：覆盖非内置引用；缺少空白和 no-save 边界 | Suggestion | 补充空白输入和失败后不得保存。 |
| `IDENTITY-ME-007` | 用户完成首评后，系统必须把 onboarding status 更新为 `complete`。 | 用户首评提交成功后，系统必须把该用户的 onboarding status 更新为 `complete`；首评未成功保存时不得推进 onboarding status。 | Pass：单一 onboarding 状态转移 | Conditional：`完成首评` 应明确为提交成功 | Conditional：覆盖状态转移；缺少失败不推进边界 | Suggestion | 补充提交成功触发和失败不推进。 |
| `IDENTITY-ME-008` | 首页摘要必须根据 onboarding status 输出下一步动作。 | 首页摘要必须根据 onboarding status 和当前场景状态输出下一步动作：未完成首评时引导完成首评；已完成首评但无当前场景时引导选择场景；已有当前场景时引导开始练习。 | Conditional：下一步动作规则单一，但当前描述遗漏 current scenario state | Conditional：`根据 onboarding status` 不足以解释 choose/start practice 分支 | Conditional：覆盖首评前分支；遗漏已完成首评后的场景分支 | Important | 补充 current scenario state 和三个可观察 next action 分支。 |

Spec 审查与 7-F 修复方案：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 7-F Spec 修复方案 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-ME-001` | `/user/me` 必须只允许 `ME-IN-AUTHENTICATED` 访问，否则返回 `ME-ERR-UNAUTHENTICATED`。 | 当前用户资料读取入口必须只允许满足 `ME-IN-AUTHENTICATED` 的常规用户访问；认证上下文缺失或无效时返回 `ME-ERR-UNAUTHENTICATED`；具体 endpoint path 由 API contract 承接。 | Pass：单一访问门禁 | Conditional：spec 可引用入口，但不应把 API path 当成唯一语义；`ME-IN-AUTHENTICATED` 定义过粗 | Conditional：覆盖未认证失败；未说明认证上下文无效 | Important | 在 7-F 中按“修复后 Spec 描述”改写，并细化 Ref ID。 |
| `IDENTITY-SPEC-ME-002` | `/user/me` 必须返回 `ME-OUT-CURRENT-USER`。 | 当前用户资料读取成功时必须返回 `ME-OUT-CURRENT-USER`，其内容必须归属当前认证用户。 | Pass：单一 current user 输出 | Conditional：未说明输出归属当前认证用户 | Pass：覆盖 current user 输出 | Suggestion | 补充归属边界，移除 API path 作为语义主体。 |
| `IDENTITY-SPEC-ME-003` | `/user/me` 必须返回 `ME-OUT-PROFILE`。 | 当前用户资料读取成功时必须返回 `ME-OUT-PROFILE`；current code baseline 下缺失 profile 时可返回空 profile 字段，本 item 不承诺读取时补建 profile。 | Pass：单一 profile 输出 | Conditional：未说明 profile 缺失边界 | Conditional：覆盖 profile 输出；缺少缺失 profile 行为 | Suggestion | 补清 current baseline profile 缺失行为。 |
| `IDENTITY-SPEC-ME-004` | 当前用户访问必须要求 access token 对应 active 且未过期 session，并且关联用户为 active 状态，否则返回 `ME-ERR-UNAUTHENTICATED`。 | 当前用户资料读取必须复用 `TOKEN-FLOW-AUTHENTICATE-BEARER` 的常规用户认证结果；认证上下文不满足时返回 `ME-ERR-UNAUTHENTICATED`，不得返回 `ME-OUT-CURRENT-USER` 或 `ME-OUT-PROFILE`。 | Conditional：认证 gate 可保留，但不应重写 token session/expiry 规则 | Conditional：与 token spec 重复，source of truth 分散 | Pass：覆盖拒绝未认证访问 | Important | 改为引用 token flow，并补充失败后不得返回 ME 输出。 |
| `IDENTITY-SPEC-ME-005` | 用户必须能提交 `ME-IN-PROFILE-UPDATE` 并保存允许更新的 profile 字段。 | 满足 `ME-IN-AUTHENTICATED` 的用户必须能提交 `ME-IN-PROFILE-UPDATE` 更新自己的 display name、avatar ref、target level、daily minutes、reminder enabled 和 reminder time；未提供的字段保持既有值。 | Conditional：一个 partial profile update contract，可保留 | Conditional：`profile 字段` 不准确，display name/avatar ref 属于 current user presentation；未说明 partial update | Conditional：覆盖可更新字段；缺少 ownership 和 no-change 行为 | Important | 明确 self-update、字段集合和未提供字段保持既有值。 |
| `IDENTITY-SPEC-ME-006` | 当 avatar ref 不是内置头像引用时，系统必须返回 `ME-ERR-INVALID-AVATAR` 并拒绝更新。 | 当 `ME-IN-PROFILE-UPDATE` 包含空白或非内置 avatar ref 时，系统必须返回 `ME-ERR-INVALID-AVATAR`，不得保存 avatar ref 或其他依赖该输入的更新结果。 | Pass：单一 avatar validation failure | Conditional：未说明空白输入，且拒绝更新范围不清楚 | Conditional：覆盖非内置失败；缺少 blank/no-save 边界 | Suggestion | 补充 blank input 和失败后置边界。 |
| `IDENTITY-SPEC-ME-007` | 用户完成首评后，系统必须把 onboarding status 更新为 `ONBOARDING-STATE-COMPLETE`。 | 首评提交成功并持久化后，系统必须把该用户状态更新为 `ONBOARDING-STATE-COMPLETE`；提交失败时不得产生该状态转移。 | Pass：单一 onboarding 状态转移 | Conditional：触发条件应是提交成功并持久化 | Conditional：覆盖成功转移；缺少失败不转移 | Suggestion | 补充成功持久化触发和失败边界。 |
| `IDENTITY-SPEC-ME-008` | 首页摘要必须根据 onboarding status 输出 `HOME-OUT-NEXT-ACTION`。 | 首页摘要必须根据 onboarding status 与当前场景状态输出 `HOME-OUT-NEXT-ACTION`：未完成首评输出 complete-onboarding；已完成首评但无当前场景输出 choose-scenario；已有当前场景输出 start-practice。 | Conditional：next action 输出单一，但原描述遗漏输入状态 | Conditional：只写 onboarding status 会漏掉 current scenario branch | Conditional：覆盖首评前，遗漏选择场景和开始练习 | Important | 补充 current scenario state 与三个 next action 分支。 |

跨文档发现与 7-F 修复方案：
| 对象 | 问题 | 影响 | 级别 | 7-F 修复方案 |
| --- | --- | --- | --- | --- |
| `traceability.md` ME 行 | `IDENTITY-ME-001..008` 的 `Spec Flow` 仍为 `TBD - 后续补齐`，但 `IDENTITY-SPEC-ME-001..008` 已存在。 | 后续 AC/TC 生成可能继续引用 TBD，导致 ME 链路断裂。 | Important | 在 7-F 中同步 `Spec Flow` 到 `IDENTITY-SPEC-ME-001..008`；`AC` 和 `TC` 继续保留 `TBD - 后续补齐`，不伪造测试证据。 |
| `ME-IN-AUTHENTICATED` Ref ID | 当前定义为“已认证用户上下文”，未说明它复用 token flow 的常规用户认证结果。 | ME 与 TOKEN 可能重复定义 session/expiry/user active 规则。 | Important | 在 7-F 中把 `ME-IN-AUTHENTICATED` 改为复用 `TOKEN-FLOW-AUTHENTICATE-BEARER` 的常规用户认证上下文。 |
| `ME-IN-PROFILE-UPDATE` Ref ID | 当前定义把 display name/avatar ref 和 profile preference 字段都称为 profile update，未说明 partial update。 | AC/TC 可能错误要求所有字段每次都必须提交，或把账号展示字段误归入 profile 表语义。 | Important | 在 7-F 中定义为“当前用户可编辑资料更新输入”，区分展示字段与 profile preference，并说明未提供字段保持既有值。 |
| `HOME-OUT-NEXT-ACTION` Ref ID | 当前定义只说根据 onboarding status 输出，但 current code baseline 还依赖当前场景状态。 | 首页摘要 AC/TC 会遗漏 choose-scenario / start-practice 分支。 | Important | 在 7-F 中补充 onboarding status + current scenario state 的 next action 决策边界。 |

Task 7-R 执行情况：
- 已执行：完成 `IDENTITY-ME-001..008` 和 `IDENTITY-SPEC-ME-001..008` 的逐条内容契约语义审查。
- 已执行：按 Requirement / Spec 分离格式形成 7-F 修复输入表，并在 item 后附原始描述与修复后描述。
- 未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；等待用户确认后再执行 Task 7-F。

Task 7-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 7-R | Confirmed by user | 用户已确认本审查表与模块边界调整方案，放行 Task 7-F。 |
| Task 7-F | Completed - pending user confirmation | 已完成修复与复审；用户确认前不得执行 Task 8-R。 |

### IDENTITY-ME 当前用户与 profile 7-F 修复复审

修复范围：
- Identity Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-ME-001..006`
- Identity Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-ME-001..006`
- Identity Traceability：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-ME-001..006`
- 删除出 Identity 模块：原 `IDENTITY-ME-007` / `IDENTITY-SPEC-ME-007` 首评提交后推进 onboarding status；原 `IDENTITY-ME-008` / `IDENTITY-SPEC-ME-008` 首页下一步动作

本轮结果：pass。Task 7-F 已按用户修订后的模块边界方案完成：`IDENTITY-ME` 只保留当前用户资料读取与资料更新；原 `IDENTITY-ME-007` 和 `IDENTITY-ME-008` 从 Identity 模块删除，不在本模块创建任何跨模块替代 item。后续若需要承接，应由 access-onboarding / Home Summary / Learning Entry 的独立文档链路处理。

Requirement 修复复审表：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 修复位置 | 复审结论 |
| --- | --- | --- | --- | --- |
| `IDENTITY-ME-001` | `/user/me` 必须只允许已认证用户访问。 | 当前用户资料读取能力必须只允许通过常规 access token 认证的用户访问；未认证或认证上下文无效时必须拒绝；具体 endpoint 路径由 API contract 承接。 | Identity requirements `IDENTITY-ME` | Pass：移除 API path 作为需求主体，保留认证访问门禁和 API contract 边界。 |
| `IDENTITY-ME-002` | `/user/me` 必须返回当前用户 ID、display name、avatar ref、locale、account status 和 onboarding status。 | 当前用户资料读取成功时，系统必须返回当前认证用户的用户标识、display name、avatar ref、locale、account status 和 onboarding status；具体响应字段形态由 API contract 承接。 | Identity requirements `IDENTITY-ME` | Pass：补清输出归属当前认证用户，避免字段 schema 化。 |
| `IDENTITY-ME-003` | `/user/me` 必须返回当前 profile 的 target level 和 daily minutes。 | 当前用户资料读取成功时，系统必须返回当前用户 profile 的 target level 和 daily minutes；若当前代码基线缺失 profile，补建或错误策略不由本 item 承诺。 | Identity requirements `IDENTITY-ME` | Pass：保留 profile 输出需求，并补清缺失 profile 非承诺边界。 |
| `IDENTITY-ME-004` | 当前用户访问必须要求 access token 对应 active 且未过期 session，并且关联用户为 `active` 状态。 | 当前用户资料读取必须复用 `IDENTITY-TOKEN` 的常规 access token 认证结果；认证上下文无效、session 不可认证或关联用户不可认证时必须拒绝访问。 | Identity requirements `IDENTITY-ME` | Pass：避免在 ME 重定义 token 生命周期细节，改为引用 token source of truth。 |
| `IDENTITY-ME-005` | 用户必须能更新 display name、avatar ref、target level、daily minutes、reminder enabled 和 reminder time。 | 已认证用户必须只能更新自己的 display name、avatar ref、target level、daily minutes、reminder enabled 和 reminder time；未提供的可选字段不得被强制改写；avatar ref 允许范围由 `IDENTITY-ME-006` 承接。 | Identity requirements `IDENTITY-ME` | Pass：补清 self-update、partial update 和 avatar validation 边界。 |
| `IDENTITY-ME-006` | 系统必须拒绝非内置头像引用作为 avatar ref。 | 当用户提交 avatar ref 更新时，系统必须只接受内置头像引用；空白或非内置引用必须拒绝，且不得保存该 avatar ref 更新。 | Identity requirements `IDENTITY-ME` | Pass：补清空白输入和失败后不得保存。 |
| `IDENTITY-ME-007` | 用户完成首评后，系统必须把 onboarding status 更新为 `complete`。 | 删除出本 Identity 模块；不在本模块定义替代 requirement item。首评提交后的状态推进由 access-onboarding 独立承接。 | Identity requirements 删除 | Pass：避免把首评提交流程写入 Identity 当前用户/profile 子章节。 |
| `IDENTITY-ME-008` | 首页摘要必须根据 onboarding status 输出下一步动作。 | 删除出本 Identity 模块；不在本模块定义替代 requirement item。首页下一步动作由 Home Summary / Learning Entry 独立承接。 | Identity requirements 删除 | Pass：避免把首页摘要编排写入 Identity 模块。 |

Spec 修复复审表：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 修复位置 | 复审结论 |
| --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-ME-001` | `/user/me` 必须只允许 `ME-IN-AUTHENTICATED` 访问，否则返回 `ME-ERR-UNAUTHENTICATED`。 | 当前用户资料读取入口必须只允许满足 `ME-IN-AUTHENTICATED` 的常规用户访问；认证上下文缺失或无效时返回 `ME-ERR-UNAUTHENTICATED`；具体 endpoint path 由 API contract 承接。 | Identity spec `IDENTITY-ME` | Pass：endpoint path 下沉到 API contract，spec 保留行为契约。 |
| `IDENTITY-SPEC-ME-002` | `/user/me` 必须返回 `ME-OUT-CURRENT-USER`。 | 当前用户资料读取成功时必须返回 `ME-OUT-CURRENT-USER`，其内容必须归属当前认证用户。 | Identity spec `IDENTITY-ME` | Pass：补清 current user 输出归属。 |
| `IDENTITY-SPEC-ME-003` | `/user/me` 必须返回 `ME-OUT-PROFILE`。 | 当前用户资料读取成功时必须返回 `ME-OUT-PROFILE`；current code baseline 下缺失 profile 时可返回空 profile 字段，本 item 不承诺读取时补建 profile。 | Identity spec `IDENTITY-ME` | Pass：补清 current baseline 缺失 profile 行为。 |
| `IDENTITY-SPEC-ME-004` | 当前用户访问必须要求 access token 对应 active 且未过期 session，并且关联用户为 active 状态，否则返回 `ME-ERR-UNAUTHENTICATED`。 | 当前用户资料读取必须复用 `TOKEN-FLOW-AUTHENTICATE-BEARER` 的常规用户认证结果；认证上下文不满足时返回 `ME-ERR-UNAUTHENTICATED`，不得返回 `ME-OUT-CURRENT-USER` 或 `ME-OUT-PROFILE`。 | Identity spec `IDENTITY-ME` | Pass：ME spec 不再重复 token/session/expiry 细节，失败后置边界明确。 |
| `IDENTITY-SPEC-ME-005` | 用户必须能提交 `ME-IN-PROFILE-UPDATE` 并保存允许更新的 profile 字段。 | 满足 `ME-IN-AUTHENTICATED` 的用户必须能提交 `ME-IN-PROFILE-UPDATE` 更新自己的 display name、avatar ref、target level、daily minutes、reminder enabled 和 reminder time；未提供的字段保持既有值。 | Identity spec `IDENTITY-ME` | Pass：补清 self-update、字段集合和 partial update。 |
| `IDENTITY-SPEC-ME-006` | 当 avatar ref 不是内置头像引用时，系统必须返回 `ME-ERR-INVALID-AVATAR` 并拒绝更新。 | 当 `ME-IN-PROFILE-UPDATE` 包含空白或非内置 avatar ref 时，系统必须返回 `ME-ERR-INVALID-AVATAR`，不得保存 avatar ref 或其他依赖该输入的更新结果。 | Identity spec `IDENTITY-ME` | Pass：补清 blank input 和 no-save failure boundary。 |
| `IDENTITY-SPEC-ME-007` | 用户完成首评后，系统必须把 onboarding status 更新为 `ONBOARDING-STATE-COMPLETE`。 | 删除出本 Identity 模块；不在本模块定义替代 spec item。首评提交后的状态推进由 access-onboarding 独立承接。 | Identity spec 删除 | Pass：未保留本模块替代 spec item，避免模块边界混淆。 |
| `IDENTITY-SPEC-ME-008` | 首页摘要必须根据 onboarding status 输出 `HOME-OUT-NEXT-ACTION`。 | 删除出本 Identity 模块；不在本模块定义替代 spec item。首页下一步动作由 Home Summary / Learning Entry 独立承接。 | Identity spec 删除 | Pass：未把其他模块 flow 作为本模块修复项。 |

追溯与边界复审表：
| 对象 | 修复后状态 | 复审结论 |
| --- | --- | --- |
| Requirement 到 Spec 映射 | `IDENTITY-ME-001..006 -> IDENTITY-SPEC-ME-001..006` | Pass：本模块只保留 ME 当前用户/profile item。 |
| Identity Ref ID | `ME-IN-AUTHENTICATED` 复用 token bearer flow；`ME-IN-PROFILE-UPDATE` 明确 partial update；移除 Identity 内 `ONBOARDING-GATE-*` 与 `HOME-OUT-NEXT-ACTION` | Pass：Ref ID 与模块边界一致。 |
| Flow Segments | 新增 `ME-FLOW-READ-CURRENT`、`ME-FLOW-UPDATE-PROFILE` | Pass：ME 补齐当前用户资料读取/更新流程，不包含首评提交或首页编排。 |
| Identity traceability | `IDENTITY-ME-001..006` 的 `Spec Flow` 已同步具体 spec ID；AC/TC 仍为 `TBD - 后续补齐`；`IDENTITY-ME-007..008` 不再作为本模块追溯行维护 | Pass：未伪造 AC、TC 或测试证据，且删除了非本模块行。 |
| Product Base root | 本次按用户反馈撤回根 Product Base 的 Task 7-F 改动 | Pass：Task 7-F 不再改写其他功能模块或根 Product Base。 |

Task 7-F 执行情况：
- 已执行：修复 Identity `requirements.md`、`spec.md` 和 `traceability.md` 中 ME 当前用户/profile 语义。
- 已执行：删除 Identity 模块中的首评提交后 onboarding status 推进 item，不创建本模块替代项。
- 已执行：删除 Identity 模块中的首页下一步动作 item，不在本 Task 更新根 Product Base。
- 未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 8 身份绑定与解绑子章节。

Task 7-F 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 7-F | Confirmed by user | 用户已确认本修复复审表，并放行 Task 8-R。 |
| Task 8-R | Completed - pending user confirmation | 已执行 LINK 子章节审查；用户确认本审查表前，不得执行 Task 8-F。 |

### IDENTITY-LINK 身份绑定与解绑 8-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-LINK-001..003`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-LINK-001..003`
- 交叉引用 Ref ID：`LINK-STATE-INITIAL-IDENTITY`、`LINK-STATE-AUTH-IDENTITY-ACTIVE`、`LINK-IN-IDENTITY-KEY`
- 只读上下文：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-LINK-001..003`，以及 `IDENTITY-ACCOUNT-002`、`IDENTITY-ACCOUNT-007`、`IDENTITY-ACCOUNT-009` 的账号创建/解析边界

本轮结果：conditional。LINK 子章节可以继续作为 current-code-baseline Draft 输入；没有阻止 Draft 留存的 blocker。但在生成 AC/TC、Product Base merge 或后续实现计划前，应收窄章节标题和 item 语义到“初始登录身份绑定与身份键解析”，避免误承诺已登录二次绑定、解绑、身份状态过滤或二次验证；同时需要把与 ACCOUNT 子章节重复的账号创建语义改成明确的跨章节引用，并补充 flow segment 与 traceability Spec Flow。

Requirement 审查与 8-F 修复方案：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 8-F Requirement 修复方案 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-LINK-001` | 新账号创建时必须绑定一个初始登录身份。 | 当新账号由账号创建流程产生时，系统必须为该账号建立一条初始登录身份绑定；该绑定必须来自本次已通过认证的身份来源与 subject；已登录用户绑定第二登录身份不由本 item 承诺。 | Conditional：初始绑定行为单一，但与 `IDENTITY-ACCOUNT-007` 重叠 | Conditional：缺少“本次已通过认证身份”的来源，容易被理解为任意初始身份 | Conditional：覆盖初始绑定，但未明确不覆盖二次绑定 | Important | 在 8-F 中补清身份来源和非二次绑定边界，并在段落中说明与 `IDENTITY-ACCOUNT-007` 的关系。 |
| `IDENTITY-LINK-002` | 新建登录身份必须初始化为 `active` 状态。 | 初始登录身份绑定创建成功时，该登录身份必须初始化为 `active` 状态；该状态只代表当前代码基线的新建身份默认状态，不承诺已实现身份禁用、解绑或状态过滤策略。 | Pass：单一状态初始化 | Conditional：未限定为初始登录身份绑定创建成功 | Conditional：覆盖默认状态，但未排除未实现的身份状态生命周期 | Suggestion | 在 8-F 中补充触发条件和当前代码基线边界。 |
| `IDENTITY-LINK-003` | 身份解析必须使用身份来源和身份 subject。 | 身份解析时，系统必须使用身份来源和身份 subject 组成的身份键查找绑定账号；不得只用 subject 或只用身份来源单独解析；身份状态过滤不归档为当前已实现。 | Pass：单一身份键解析规则 | Conditional：当前描述未明确 provider+subject 必须组合使用，也未说明解析结果归属账号 | Conditional：覆盖身份键输入，但未说明 miss/conflict 边界由 ACCOUNT 承接 | Important | 在 8-F 中补清组合键语义，并引用账号解析、重复身份冲突由 `IDENTITY-ACCOUNT-002` / `IDENTITY-ACCOUNT-009` 承接。 |

Spec 审查与 8-F 修复方案：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 8-F Spec 修复方案 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-LINK-001` | 新账号创建时必须绑定 `LINK-STATE-INITIAL-IDENTITY`。 | 在 `IDENTITY-SPEC-ACCOUNT-003` 创建新账号后，系统必须基于本次已验证身份的 `LINK-IN-IDENTITY-KEY` 创建初始登录身份绑定，并输出 `LINK-OUT-INITIAL-AUTH-IDENTITY`；二次绑定和解绑不属于当前 code baseline。 | Conditional：一个初始绑定 flow，可保留 | Important：`LINK-STATE-INITIAL-IDENTITY` 把输出误写成 state，且缺少身份键来源 | Conditional：覆盖初始绑定，但缺少与账号创建/重复身份约束的关系 | Important | 在 8-F 中把 Ref ID 改为输出型 `LINK-OUT-INITIAL-AUTH-IDENTITY`，并新增 initial-bind flow segment。 |
| `IDENTITY-SPEC-LINK-002` | 新建登录身份必须初始化为 `LINK-STATE-AUTH-IDENTITY-ACTIVE`。 | 初始登录身份绑定创建成功后，该登录身份必须进入 `LINK-STATE-AUTH-IDENTITY-ACTIVE`；该状态不表示身份禁用、解绑或 inactive 查询过滤已实现。 | Pass：单一状态转移 | Conditional：需明确触发为初始绑定创建成功 | Conditional：覆盖默认状态；未排除未实现状态生命周期 | Suggestion | 在 8-F 中补清触发条件和未实现身份状态生命周期边界。 |
| `IDENTITY-SPEC-LINK-003` | 身份解析必须使用 `LINK-IN-IDENTITY-KEY`。 | 身份解析 flow 必须用 `LINK-IN-IDENTITY-KEY` 查找绑定账号；命中时进入 `IDENTITY-SPEC-ACCOUNT-002` 的账号解析结果，未命中时由账号创建 flow 决定后续处理；重复身份冲突由 `IDENTITY-SPEC-ACCOUNT-009` 承接。 | Conditional：身份键解析单一，但需要 flow 语义支撑 | Conditional：只说“使用输入”，没有写命中、未命中或冲突边界 | Conditional：覆盖 lookup 输入，缺少状态/输出/failure boundary | Important | 在 8-F 中新增 resolve-identity flow segment，并把 miss/conflict 边界交回 ACCOUNT 规格。 |

跨文档发现与 8-F 修复方案：
| 对象 | 问题 | 影响 | 级别 | 8-F 修复方案 |
| --- | --- | --- | --- | --- |
| `IDENTITY-LINK` 小节标题 | 标题为“身份绑定与解绑”，但当前已实现 item 只覆盖初始登录身份绑定和身份键解析；解绑明确在非归档范围。 | 读者可能误以为已登录绑定第二身份或解绑也已进入本模块代码基线。 | Important | 在 8-F 中把标题改为“初始登录身份绑定与身份键解析”，或在标题下增加当前仅覆盖初始绑定的边界句。 |
| ACCOUNT 与 LINK 边界 | `IDENTITY-LINK-001` 与 `IDENTITY-ACCOUNT-007` 都表达新账号初始登录身份绑定。 | 下游 AC/TC 可能重复生成同一验收点，或出现 source of truth 分散。 | Important | 保留 ACCOUNT 为账号创建整体结果；LINK 专注 auth identity binding 语义，并在 LINK item 中显式引用 ACCOUNT 边界。 |
| LINK Ref ID | `LINK-STATE-INITIAL-IDENTITY` 实际是初始登录身份绑定输出，不是生命周期状态。 | Spec/AC 可能把绑定记录输出误当状态机状态。 | Suggestion | 改为 `LINK-OUT-INITIAL-AUTH-IDENTITY` 或同等输出型 Ref ID。 |
| `traceability.md` LINK 行 | `IDENTITY-LINK-001..003` 的 `Spec Flow` 仍为 `TBD - 后续补齐`，但 `IDENTITY-SPEC-LINK-001..003` 已存在。 | 后续 AC/TC 生成可能继续引用 TBD，导致 LINK 链路断裂。 | Important | 在 8-F 中同步 `Spec Flow` 到 `IDENTITY-SPEC-LINK-001..003`；`AC` 和 `TC` 继续保留 `TBD - 后续补齐`，不伪造测试证据。 |

Task 8-R 执行情况：
- 已执行：完成 `IDENTITY-LINK-001..003` 和 `IDENTITY-SPEC-LINK-001..003` 的逐条内容契约语义审查。
- 已执行：按 Requirement / Spec 分离格式形成 8-F 修复输入表，并在 item 后附原始描述与修复后描述。
- 未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；等待用户确认后再执行 Task 8-F。

Task 8-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 8-R | Confirmed by user | 用户已确认本审查表，并放行 Task 8-F。 |
| Task 8-F | Completed - pending user confirmation | 已完成 LINK 子章节修复；用户确认本修复复审表前，不得执行 Task 9-R。 |

### IDENTITY-LINK 初始登录身份绑定与身份键解析 8-F 修复复审

修复范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-LINK-001..003`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-LINK-001..003`、`LINK-*` Ref ID 和 LINK flow segments
- Traceability：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-LINK-001..003` 的 `Spec Flow`

本轮结果：pass。Task 8-F 已按用户确认的 8-R 方案完成：LINK 子章节从“身份绑定与解绑”收窄为“初始登录身份绑定与身份键解析”；requirements/spec 明确不承诺二次绑定、解绑、身份禁用或 inactive 查询过滤；spec 增加初始绑定和身份解析 flow segment；traceability 的 LINK 行已同步具体 spec ID。

Requirement 修复复审表：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 修复位置 | 复审结论 |
| --- | --- | --- | --- | --- |
| `IDENTITY-LINK-001` | 新账号创建时必须绑定一个初始登录身份。 | 当新账号由账号创建流程产生时，系统必须为该账号建立一条初始登录身份绑定；该绑定必须来自本次已通过认证的身份来源与 subject；已登录用户绑定第二登录身份不由本 item 承诺。 | Identity requirements `IDENTITY-LINK` | Pass：补清初始绑定来源，并排除二次绑定承诺。 |
| `IDENTITY-LINK-002` | 新建登录身份必须初始化为 `active` 状态。 | 初始登录身份绑定创建成功时，该登录身份必须初始化为 `active` 状态；该状态只代表当前代码基线的新建身份默认状态，不承诺已实现身份禁用、解绑或状态过滤策略。 | Identity requirements `IDENTITY-LINK` | Pass：补清触发条件和当前代码基线边界。 |
| `IDENTITY-LINK-003` | 身份解析必须使用身份来源和身份 subject。 | 身份解析时，系统必须使用身份来源和身份 subject 组成的身份键查找绑定账号；不得只用 subject 或只用身份来源单独解析；身份状态过滤不归档为当前已实现。 | Identity requirements `IDENTITY-LINK` | Pass：补清 provider+subject 组合键和 inactive 过滤非目标。 |

Spec 修复复审表：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 修复位置 | 复审结论 |
| --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-LINK-001` | 新账号创建时必须绑定 `LINK-STATE-INITIAL-IDENTITY`。 | 在 `IDENTITY-SPEC-ACCOUNT-003` 创建新账号后，系统必须基于本次已验证身份的 `LINK-IN-IDENTITY-KEY` 创建初始登录身份绑定，并输出 `LINK-OUT-INITIAL-AUTH-IDENTITY`；二次绑定和解绑不属于当前 code baseline。 | Identity spec `IDENTITY-LINK` | Pass：将初始绑定从 state 误用修正为输出，并连接账号创建规格。 |
| `IDENTITY-SPEC-LINK-002` | 新建登录身份必须初始化为 `LINK-STATE-AUTH-IDENTITY-ACTIVE`。 | 初始登录身份绑定创建成功后，该登录身份必须进入 `LINK-STATE-AUTH-IDENTITY-ACTIVE`；该状态不表示身份禁用、解绑或 inactive 查询过滤已实现。 | Identity spec `IDENTITY-LINK` | Pass：补清状态触发和非承诺生命周期。 |
| `IDENTITY-SPEC-LINK-003` | 身份解析必须使用 `LINK-IN-IDENTITY-KEY`。 | 身份解析 flow 必须用 `LINK-IN-IDENTITY-KEY` 查找绑定账号；命中时进入 `IDENTITY-SPEC-ACCOUNT-002` 的账号解析结果，未命中时由账号创建 flow 决定后续处理；重复身份冲突由 `IDENTITY-SPEC-ACCOUNT-009` 承接。 | Identity spec `IDENTITY-LINK` | Pass：补清命中、未命中和冲突边界，并回到 ACCOUNT source of truth。 |

追溯与边界复审表：
| 对象 | 修复后状态 | 复审结论 |
| --- | --- | --- |
| LINK 小节标题 | `IDENTITY-LINK 初始登录身份绑定与身份键解析` | Pass：不再暗示解绑能力已实现。 |
| LINK Ref ID | `LINK-OUT-INITIAL-AUTH-IDENTITY`、`LINK-STATE-AUTH-IDENTITY-ACTIVE`、`LINK-IN-IDENTITY-KEY` | Pass：输出、状态、输入分类已区分。 |
| LINK Flow Segments | 新增 `LINK-FLOW-CREATE-INITIAL` 和 `LINK-FLOW-RESOLVE-IDENTITY` | Pass：补齐初始绑定和身份键解析的触发、前置、输出和失败边界。 |
| Traceability | `IDENTITY-LINK-001..003` 的 `Spec Flow` 已同步为 `IDENTITY-SPEC-LINK-001..003`；AC/TC 保留 `TBD - 后续补齐` | Pass：未伪造 AC、TC 或测试证据。 |

Task 8-F 执行情况：
- 已执行：修复 LINK requirements 标题、三条 requirement item 和非目标边界。
- 已执行：修复 LINK spec Ref ID、flow segments 和三条 spec item。
- 已执行：同步 `traceability.md` 中 `IDENTITY-LINK-001..003` 的 `Spec Flow`。
- 未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 9 logout 子章节。

Task 8-F 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 8-F | Confirmed by user | 用户已确认本修复复审表，并放行 Task 9-R。 |
| Task 9-R | Completed - pending user confirmation | 已执行 LOGOUT 子章节审查；用户确认本审查表前，不得执行 Task 9-F。 |

### IDENTITY-LOGOUT 退出登录 9-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-LOGOUT-001..005`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-LOGOUT-001..005`
- 交叉引用 Ref ID：`LOGOUT-IN-AUTHENTICATED`、`LOGOUT-STATE-SESSION-REVOKED`、`LOGOUT-OUT-REVOKED-AT`、`LOGOUT-ERR-UNAUTHENTICATED`
- 只读上下文：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-LOGOUT-001..005`，以及 `IDENTITY-TOKEN-007`、`IDENTITY-TOKEN-008` 的常规 access token 认证边界

本轮结果：conditional。LOGOUT 子章节可以继续作为 current-code-baseline Draft 输入；没有阻止 Draft 留存的 blocker。但在生成 AC/TC、Product Base merge 或后续实现计划前，应补清“当前 session”来自本次认证上下文、退出只影响当前 session、找不到 current session 时不得产生状态变化、撤销成功后的状态与时间记录，以及已撤销 session 的后续认证失败应复用 TOKEN 认证边界。同时，spec 需要增加 logout flow segment，并把 traceability 的 Spec Flow 从 TBD 同步为具体 spec ID。

Requirement 审查与 9-F 修复方案：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 9-F Requirement 修复方案 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-LOGOUT-001` | 已认证用户调用 logout 时，系统必须撤销当前 session。 | 已认证用户调用 logout 时，系统必须撤销本次认证上下文对应的当前 session；该行为只影响当前 session，不承诺退出同用户其他 session。 | Pass：单一当前会话撤销行为 | Conditional：`当前 session` 来源不够明确，未说明只影响当前 session | Conditional：覆盖当前设备/当前 session 退出，不覆盖全部设备退出 | Important | 在 9-F 中补清当前 session 来源和非全设备退出边界。 |
| `IDENTITY-LOGOUT-002` | logout 找不到当前 session 时，系统必须返回未认证错误。 | 当 logout 请求无法解析到可撤销的当前 session 时，系统必须返回未认证错误，且不得创建、撤销或修改任何 session。 | Pass：单一失败规则 | Conditional：`找不到当前 session` 未说明后置状态 | Conditional：覆盖失败输出，但缺少 no state change 边界 | Important | 在 9-F 中补充失败后不得产生 session 状态变化。 |
| `IDENTITY-LOGOUT-003` | session 被撤销时，系统必须把 session 状态设为 `revoked`。 | 当前 session 撤销成功时，系统必须把该 session 状态更新为 `revoked`。 | Pass：单一状态转移 | Conditional：触发条件应是当前 session 撤销成功 | Pass：覆盖 revoked 状态 | Suggestion | 在 9-F 中补清触发条件，避免被理解为所有 session。 |
| `IDENTITY-LOGOUT-004` | session 被撤销时，系统必须记录 revoked time。 | 当前 session 撤销成功时，系统必须记录该 session 的撤销发生时间。 | Pass：单一审计/时间输出 | Conditional：`revoked time` 应表达为撤销发生时间，而不是字段名要求 | Conditional：覆盖时间记录，但不说明输出是否返回给用户 | Suggestion | 在 9-F 中改为产品语义“撤销发生时间”，不写字段实现。 |
| `IDENTITY-LOGOUT-005` | 已撤销 session 不得继续通过 access token 认证。 | 已撤销 session 不得再通过常规 access token 认证；后续认证失败边界复用 `IDENTITY-TOKEN` 的常规 access token 认证规则。 | Pass：单一退出后安全后置条件 | Conditional：与 TOKEN 子章节有重叠，应明确复用 token source of truth | Pass：覆盖撤销后 access token 失效 | Important | 在 9-F 中改为 postcondition，并引用 `IDENTITY-TOKEN`，避免重复定义 token 认证细节。 |

Spec 审查与 9-F 修复方案：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 颗粒度 | 清晰度 | 覆盖度 | 结论 | 9-F Spec 修复方案 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-LOGOUT-001` | 已认证用户调用 logout 时，系统必须撤销 `LOGOUT-IN-AUTHENTICATED` 对应的当前 session。 | 当 logout 请求满足 `LOGOUT-IN-CURRENT-SESSION` 时，系统必须撤销该当前 session；不得撤销同用户其他 session。 | Pass：单一 flow 动作 | Conditional：`LOGOUT-IN-AUTHENTICATED` 名称过泛，不如 current session 输入准确 | Conditional：覆盖撤销动作，未明确 multi-session 边界 | Important | 在 9-F 中把 Ref ID 改为 `LOGOUT-IN-CURRENT-SESSION`，并增加 logout-current flow。 |
| `IDENTITY-SPEC-LOGOUT-002` | logout 找不到当前 session 时，系统必须返回 `LOGOUT-ERR-UNAUTHENTICATED`。 | 当 logout 请求缺少或无法解析 `LOGOUT-IN-CURRENT-SESSION` 时，系统必须返回 `LOGOUT-ERR-UNAUTHENTICATED`，不得创建、撤销或修改 session。 | Pass：单一失败输出 | Conditional：缺少 no state change 后置条件 | Conditional：覆盖错误输出，但缺少失败边界 | Important | 在 9-F 中补清失败不改变 session 状态。 |
| `IDENTITY-SPEC-LOGOUT-003` | session 被撤销时，系统必须进入 `LOGOUT-STATE-SESSION-REVOKED`。 | 当前 session 撤销成功后，该 session 必须进入 `LOGOUT-STATE-SESSION-REVOKED`。 | Pass：单一状态转移 | Conditional：应限定为当前 session | Pass：覆盖状态转移 | Suggestion | 在 9-F 中补清当前 session 撤销成功触发。 |
| `IDENTITY-SPEC-LOGOUT-004` | session 被撤销时，系统必须记录 `LOGOUT-OUT-REVOKED-AT`。 | 当前 session 撤销成功后，系统必须记录 `LOGOUT-OUT-REVOKED-AT` 作为该 session 的撤销发生时间。 | Pass：单一输出/记录 | Conditional：需说明是撤销发生时间 | Pass：覆盖 revoked time | Suggestion | 在 9-F 中补充时间语义。 |
| `IDENTITY-SPEC-LOGOUT-005` | `LOGOUT-STATE-SESSION-REVOKED` 不得继续通过 access token 认证。 | `LOGOUT-STATE-SESSION-REVOKED` 对应 session 的 access token 后续必须在 `TOKEN-FLOW-AUTHENTICATE-BEARER` 中认证失败，并按 `TOKEN-ERR-UNAUTHENTICATED` 处理。 | Pass：单一安全后置条件 | Conditional：原文把状态本身当认证主体；应说明是该 session 的 access token 后续认证失败 | Pass：覆盖撤销后 token 不可用 | Important | 在 9-F 中引用 token flow 和 token error，不重新定义 token 认证细节。 |

跨文档发现与 9-F 修复方案：
| 对象 | 问题 | 影响 | 级别 | 9-F 修复方案 |
| --- | --- | --- | --- | --- |
| LOGOUT Flow Segment | spec 当前只有 item table，没有 logout 当前 session 的流程段。 | 后续 AC/TC 难以覆盖成功撤销、找不到 session、撤销后 token 失败的完整路径。 | Important | 在 9-F 中新增 `LOGOUT-FLOW-CURRENT-SESSION`，覆盖 trigger、precondition、state/output、failure boundary。 |
| `LOGOUT-IN-AUTHENTICATED` Ref ID | 当前定义为“已认证用户当前 session”，名称偏认证上下文，容易与 ME/TOKEN 的通用认证输入混淆。 | LOGOUT spec 对“当前 session”的 source of truth 不够精确。 | Suggestion | 在 9-F 中改为 `LOGOUT-IN-CURRENT-SESSION`，定义为本次 logout 请求通过常规 access token 认证得到的当前 session。 |
| LOGOUT 与 TOKEN 边界 | `IDENTITY-LOGOUT-005` 与 `IDENTITY-TOKEN-007` 均涉及撤销后 access token 认证失败。 | 如果独立生成 AC/TC，可能重复定义 token 认证细节。 | Important | LOGOUT 只定义撤销后的安全后置条件；认证细节引用 `TOKEN-FLOW-AUTHENTICATE-BEARER` / `TOKEN-ERR-UNAUTHENTICATED`。 |
| `traceability.md` LOGOUT 行 | `IDENTITY-LOGOUT-001..005` 的 `Spec Flow` 仍为 `TBD - 后续补齐`，但 `IDENTITY-SPEC-LOGOUT-001..005` 已存在。 | 后续 AC/TC 生成可能继续引用 TBD，导致 LOGOUT 链路断裂。 | Important | 在 9-F 中同步 `Spec Flow` 到 `IDENTITY-SPEC-LOGOUT-001..005`；`AC` 和 `TC` 继续保留 `TBD - 后续补齐`，不伪造测试证据。 |

Task 9-R 执行情况：
- 已执行：完成 `IDENTITY-LOGOUT-001..005` 和 `IDENTITY-SPEC-LOGOUT-001..005` 的逐条内容契约语义审查。
- 已执行：按 Requirement / Spec 分离格式形成 9-F 修复输入表，并在 item 后附原始描述与修复后描述。
- 未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；等待用户确认后再执行 Task 9-F。

Task 9-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 9-R | Confirmed by user | 用户已确认本审查表，并放行 Task 9-F。 |
| Task 9-F | Confirmed by user | 用户已确认 LOGOUT 修复复审，并放行 Task 10-R。 |

### IDENTITY-LOGOUT 退出登录 9-F 修复复审

修复范围：
- Requirements：修复 `IDENTITY-LOGOUT-001..005` 的当前 session 来源、单 session 退出边界、失败 no state change、撤销状态和撤销时间语义。
- Spec：修复 LOGOUT Ref ID，新增 `LOGOUT-FLOW-CURRENT-SESSION`，并修复 `IDENTITY-SPEC-LOGOUT-001..005` 的可验收行为契约。
- Traceability：同步 `IDENTITY-LOGOUT-001..005` 的 `Spec Flow` 到 `IDENTITY-SPEC-LOGOUT-001..005`；`AC` 与 `TC` 继续保留 `TBD - 后续补齐`。

Requirement 修复复审表：
| Requirement item | 修复前 Requirement 描述 | 修复后 Requirement 描述 | 复审结论 | 状态 |
| --- | --- | --- | --- | --- |
| `IDENTITY-LOGOUT-001` | 已认证用户调用 logout 时，系统必须撤销当前 session。 | 已认证用户调用 logout 时，系统必须撤销本次认证上下文对应的当前 session；该行为只影响当前 session，不承诺退出同用户其他 session。 | Pass：补清当前 session 来源和非全设备退出边界，仍保持单一产品行为。 | Fixed |
| `IDENTITY-LOGOUT-002` | logout 找不到当前 session 时，系统必须返回未认证错误。 | 当 logout 请求无法解析到可撤销的当前 session 时，系统必须返回未认证错误，且不得创建、撤销或修改任何 session。 | Pass：补清失败后不得产生 session 状态变化。 | Fixed |
| `IDENTITY-LOGOUT-003` | session 被撤销时，系统必须把 session 状态设为 `revoked`。 | 当前 session 撤销成功时，系统必须把该 session 状态更新为 `revoked`。 | Pass：状态转移主体限定为当前 session。 | Fixed |
| `IDENTITY-LOGOUT-004` | session 被撤销时，系统必须记录 revoked time。 | 当前 session 撤销成功时，系统必须记录该 session 的撤销发生时间。 | Pass：把字段式表述修正为产品语义。 | Fixed |
| `IDENTITY-LOGOUT-005` | 已撤销 session 不得继续通过 access token 认证。 | 已撤销 session 不得再通过常规 access token 认证；后续认证失败边界复用 `IDENTITY-TOKEN` 的常规 access token 认证规则。 | Pass：LOGOUT 只保留退出后的安全后置条件，TOKEN 仍是认证规则 source of truth。 | Fixed |

Spec 修复复审表：
| Spec item | 修复前 Spec 描述 | 修复后 Spec 描述 | 复审结论 | 状态 |
| --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-LOGOUT-001` | 已认证用户调用 logout 时，系统必须撤销 `LOGOUT-IN-AUTHENTICATED` 对应的当前 session。 | 当 logout 请求满足 `LOGOUT-IN-CURRENT-SESSION` 时，系统必须撤销该当前 session；不得撤销同用户其他 session。 | Pass：输入 Ref ID 更精确，明确当前 session-only 边界。 | Fixed |
| `IDENTITY-SPEC-LOGOUT-002` | logout 找不到当前 session 时，系统必须返回 `LOGOUT-ERR-UNAUTHENTICATED`。 | 当 logout 请求缺少或无法解析 `LOGOUT-IN-CURRENT-SESSION` 时，系统必须返回 `LOGOUT-ERR-UNAUTHENTICATED`，且不得创建、撤销或修改 session。 | Pass：补齐失败输出和 no state change 后置条件。 | Fixed |
| `IDENTITY-SPEC-LOGOUT-003` | session 被撤销时，系统必须进入 `LOGOUT-STATE-SESSION-REVOKED`。 | 当前 session 撤销成功后，该 session 必须进入 `LOGOUT-STATE-SESSION-REVOKED`。 | Pass：状态变化主体和触发条件清楚。 | Fixed |
| `IDENTITY-SPEC-LOGOUT-004` | session 被撤销时，系统必须记录 `LOGOUT-OUT-REVOKED-AT`。 | 当前 session 撤销成功后，系统必须记录 `LOGOUT-OUT-REVOKED-AT` 作为该 session 的撤销发生时间。 | Pass：输出语义从字段名补充为撤销发生时间。 | Fixed |
| `IDENTITY-SPEC-LOGOUT-005` | `LOGOUT-STATE-SESSION-REVOKED` 不得继续通过 access token 认证。 | `LOGOUT-STATE-SESSION-REVOKED` 对应 session 的 access token 后续必须在 `TOKEN-FLOW-AUTHENTICATE-BEARER` 中认证失败，并按 `TOKEN-ERR-UNAUTHENTICATED` 处理。 | Pass：用 TOKEN flow/error 承接后续认证失败，避免重复定义 token 认证细节。 | Fixed |

Spec Ref / Flow / Traceability 复审表：
| 对象 | 修复内容 | 复审结论 | 状态 |
| --- | --- | --- | --- |
| LOGOUT Ref ID | `LOGOUT-IN-AUTHENTICATED` 改为 `LOGOUT-IN-CURRENT-SESSION`，定义为本次 logout 请求通过 `TOKEN-FLOW-AUTHENTICATE-BEARER` 得到的当前 session。 | Pass：Ref ID 与 LOGOUT 的输入语义一致。 | Fixed |
| LOGOUT Flow Segment | 新增 `LOGOUT-FLOW-CURRENT-SESSION`，覆盖 trigger、precondition、state/output 和 failure boundary。 | Pass：后续 AC/TC 可从流程段生成成功、失败和撤销后认证失败路径。 | Fixed |
| LOGOUT 与 TOKEN 边界 | LOGOUT spec 通过 `TOKEN-FLOW-AUTHENTICATE-BEARER` 和 `TOKEN-ERR-UNAUTHENTICATED` 引用 token 认证失败。 | Pass：边界分离清楚，未把 token 认证细节复制到 LOGOUT。 | Fixed |
| Traceability | `IDENTITY-LOGOUT-001..005` 的 `Spec Flow` 同步为 `IDENTITY-SPEC-LOGOUT-001..005`；AC/TC 保持 `TBD - 后续补齐`。 | Pass：补齐 Requirement -> Spec 链路，同时未伪造 AC、TC 或测试证据。 | Fixed |

Task 9-F 执行情况：
- 已执行：修复 LOGOUT requirements 五条 item。
- 已执行：修复 LOGOUT spec Ref ID、补充 flow segment、修复五条 spec item。
- 已执行：同步 `traceability.md` 中 `IDENTITY-LOGOUT-001..005` 的 `Spec Flow`。
- 未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 10 delete 子章节。

Task 9-F 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 9-F | Confirmed by user | 用户已确认本修复复审表，并放行 Task 10-R。 |
| Task 10-R | Passed by main+independent agents | 独立 agent 已复核通过，并按用户更新后的门禁规则自动进入 Task 10-F。 |

### IDENTITY-DELETE 账号删除与生命周期状态 10-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-DELETE-001..020`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-DELETE-001..020`
- 交叉引用 Ref ID：`DELETE-IN-AUTHENTICATED`、`DELETE-IN-IDEMPOTENCY-KEY`、`DELETE-STATE-*`、`DELETE-JOB-*`、`DELETE-CLEANUP-*`、`TOKEN-FLOW-AUTHENTICATE-BEARER`、`RISK-IN-OPS-BEARER`
- 只读上下文：`docs/product/base/identity-account-lifecycle/traceability.md` 中 `IDENTITY-DELETE-001..020`，以及 current code evidence 中账号删除请求、重试、session 撤销、数据清理和审计写入行为。

本轮结果：conditional。DELETE 子章节可以继续作为 current-code-baseline Draft 输入；没有阻止 Draft 留存的 blocker。但在生成 AC/TC、Product Base merge 或后续实现计划前，应补清删除请求、删除执行、状态查询、运维重试和删除请求重放的 flow segment；移除 requirement 中的内部 runner 和 spec 中的 API path；补充失败时不得创建 job 或改变状态的边界；明确保留的最小账号信息与 user profile 明细删除的关系；并把 traceability 的 `Spec Flow` 从 TBD 同步为具体 spec ID。

Requirement 审查与 10-F 修复方案：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 结论 | 10-F Requirement 修复方案 |
| --- | --- | --- | --- | --- |
| `IDENTITY-DELETE-001` | 已认证用户必须能发起当前账号删除请求。 | 通过常规 access token 认证并解析到当前账号的用户，必须能为该当前账号发起删除请求；系统不得允许该用户为其他账号发起删除。 | Important：已认证用户和当前账号来源可更精确。 | 补清认证上下文和 current-account-only 边界。 |
| `IDENTITY-DELETE-002` | 账号删除请求必须要求 idempotency key 长度在 8 到 128 个字符之间。 | 当前账号删除请求和运维删除重试请求必须携带长度在 8 到 128 个字符之间的幂等键；当幂等键缺失、长度小于 8 个字符或大于 128 个字符时，系统必须拒绝请求，不得创建删除任务或重试幂等记录、不得撤销 session、不得改变账号或删除任务状态。 | Important：缺少失败后置状态，且未覆盖运维重试请求的幂等键失败边界。 | 补充幂等键无效条件、用户删除请求/运维重试请求覆盖，以及不得创建 job / retry idempotency / 改变账号或 session 状态。 |
| `IDENTITY-DELETE-003` | 同一用户使用同一 idempotency key 重复发起删除请求时，系统必须返回已有删除 job。 | 同一用户使用同一幂等键再次发起删除请求时，系统必须返回该用户和该幂等键已经关联的删除任务，且不得创建第二个删除任务。 | Important：缺少 no duplicate job 边界。 | 补充重复请求不得创建新 job。 |
| `IDENTITY-DELETE-004` | 系统必须只允许 `active` 或 `deletion_requested` 账号发起删除执行。 | 只有账号状态为 `active` 或 `deletion_requested` 时，系统才允许该账号进入删除执行；账号状态不是这两者时，系统必须拒绝进入删除执行。 | Suggestion：拒绝边界不显式。 | 补清非允许状态的拒绝语义。 |
| `IDENTITY-DELETE-005` | 删除执行必须撤销该用户所有 active session。 | 删除任务进入访问撤销阶段时，系统必须撤销该账号关联用户的所有 active session；该行为不同于 logout 只撤销当前 session。 | Suggestion：与 LOGOUT 边界应显式区分。 | 补充 all sessions 边界并引用 LOGOUT 差异。 |
| `IDENTITY-DELETE-006` | 删除执行必须调用 AI account deletion retention runner 清理该用户关联的 AI media、TTS cache ownership 和 provider metric 数据。 | 删除执行必须清理该用户关联的 AI media、TTS cache ownership 和 provider metric 数据。 | Important：Requirement 混入内部 runner 实现名。 | 删除 runner 表述，只保留产品数据清理义务。 |
| `IDENTITY-DELETE-007` | 删除完成后，系统必须把账号状态标记为 `deleted`。 | 删除完成后，系统必须把账号生命周期状态标记为 `deleted`。 | Suggestion：可从字段式状态改为生命周期语义。 | 语义收紧为账号生命周期状态。 |
| `IDENTITY-DELETE-008` | 删除完成后，系统必须把 display name 改为 `Deleted User`，清空 avatar ref，并把 onboarding status 标记为 `deleted`。 | 删除完成后，系统必须保留用于表示删除状态的最小账号信息：展示名为 `Deleted User`、头像引用为空、onboarding status 为 `deleted`；该最小账号信息不等同于 user profile 明细数据，profile 明细删除由 `IDENTITY-DELETE-014` 承接。 | Important：与 user profile 删除关系不清。 | 补清保留最小账号信息和 profile 明细删除边界。 |
| `IDENTITY-DELETE-009` | 已认证用户必须能查询当前账号最新删除 job 状态。 | 通过常规 access token 认证并解析到当前账号的用户，必须能查询该当前账号最新删除任务状态；账号进入 `deleted` 后不能通过常规 access token 认证继续查询，删除请求重放场景由 `IDENTITY-DELETE-012` 承接。 | Important：当前可认证边界和删除后查询边界不清。 | 补清查询只依赖常规认证上下文，并把删除后重放交给 012。 |
| `IDENTITY-DELETE-010` | 运维用户必须能重试 failed 删除 job。 | 通过 ops bearer token 运维认证的请求，必须能对状态为 failed 的删除任务发起重试。 | Suggestion：运维认证边界可更清晰。 | 补充 ops bearer token 运维认证前置。 |
| `IDENTITY-DELETE-011` | 删除重试必须只允许 failed 删除 job 进入重试执行；completed job 必须返回已有结果，其他状态必须被拒绝。 | 删除重试只有在删除任务状态为 `failed`，且本次重试幂等键未关联该删除任务时，才允许启动新的重试执行；不得因 `completed`、`requested`、`access_revoked`、`deleting_learning_data`、`anonymizing_audit_refs` 或未识别任务状态启动新的重试执行；具体返回或失败结果由 Spec 重试决策表承接。 | Important：原 item 混合 failed 启动、completed 返回、重复重试、in-progress 拒绝和未知状态拒绝，颗粒度过粗。 | Requirement 收敛为“允许启动新重试执行”的业务入口规则；具体状态输出放到 Spec 决策表。 |
| `IDENTITY-DELETE-012` | 删除重试认证必须允许携带同一 idempotency key 的 `deleted` 或 `deletion_requested` 用户重放同一个 `DELETE /user/me` 请求。 | 当请求携带的 token 对应账号状态为 `deleted` 或 `deletion_requested`，且请求幂等键与该账号已有删除任务的幂等键一致时，系统必须允许该请求重放账号删除请求并返回该已有删除任务；该例外不得用于登录、资料读取或其他受保护用户请求。 | Important：Requirement 写入 API path，且 token/删除重放边界不清。 | 移除 API path，改写为产品级删除请求重放语义。 |
| `IDENTITY-DELETE-013` | 删除执行必须删除该用户的 auth identity 记录。 | 删除执行必须删除该用户的登录身份数据。 | Suggestion：`auth identity 记录` 偏实现/表述。 | 改为业务数据族“登录身份数据”。 |
| `IDENTITY-DELETE-014` | 删除执行必须删除该用户的 user profile 记录。 | 删除执行必须删除该用户的 profile 明细数据；删除后保留的最小账号信息由 `IDENTITY-DELETE-008` 承接。 | Important：需避免与最小账号信息保留冲突。 | 补清 profile 明细删除和保留最小账号信息的分工。 |
| `IDENTITY-DELETE-015` | 删除执行必须删除该用户的 onboarding assessment、learning route 和 user scenario state 记录。 | 删除执行必须删除该用户的 onboarding assessment、learning route 和 scenario state 数据。 | Suggestion：数据族可保留，但少用 record 风格。 | 改为跨域数据族清理义务。 |
| `IDENTITY-DELETE-016` | 删除执行必须删除该用户的 practice session、practice turn 和 session summary 记录。 | 删除执行必须删除该用户的 practice session、practice turn 和 session summary 数据。 | Pass：范围清晰。 | 仅把 record 风格统一为数据清理语义。 |
| `IDENTITY-DELETE-017` | 删除执行必须删除该用户的 training session、training turn、training recap、training planner decision、training evidence candidate 和 training metric event 记录。 | 删除执行必须删除该用户的 training session、training turn、training recap、training planner decision、training evidence candidate 和 training metric event 数据。 | Pass：范围清晰。 | 仅把 record 风格统一为数据清理语义。 |
| `IDENTITY-DELETE-018` | 删除执行必须删除该用户的 purchase、subscription、entitlement snapshot、usage ledger、usage reservation 和关联 payment provider event 记录。 | 删除执行必须删除该用户的 purchase、subscription、entitlement snapshot、usage ledger、usage reservation 和关联 payment provider event 数据。 | Pass：范围清晰。 | 仅把 record 风格统一为数据清理语义。 |
| `IDENTITY-DELETE-019` | 删除执行必须删除该用户的 learning evidence、learning history、mastery、review、practice queue、favorite expression 和 saved expression 记录。 | 删除执行必须删除该用户的 learning evidence、learning history、mastery、review、practice queue、favorite expression 和 saved expression 数据。 | Pass：范围清晰。 | 仅把 record 风格统一为数据清理语义。 |
| `IDENTITY-DELETE-020` | 删除执行必须删除该用户的 goal profile、diagnostic assessment、mastery initial state、backplan、daily plan、plan item、autopilot control、goal idempotency、control idempotency、recovery decision、mastery transition decision、notification outbox、planner replay audit、progress forecast 和 outcome checkpoint 记录。 | 删除执行必须删除该用户的 goal profile、diagnostic assessment、mastery initial state、backplan、daily plan、plan item、autopilot control、goal idempotency、control idempotency、recovery decision、mastery transition decision、notification outbox、planner replay audit、progress forecast 和 outcome checkpoint 数据。 | Conditional：范围完整但术语密集，应确认这些名称是稳定领域数据族。 | 统一为数据清理语义；若这些不是稳定领域术语，后续应由 domain model 收敛命名。 |

Spec 审查与 10-F 修复方案：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 结论 | 10-F Spec 修复方案 |
| --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-DELETE-001` | `DELETE-IN-AUTHENTICATED` 必须能发起当前账号删除请求。 | 在 `DELETE-FLOW-REQUEST-CURRENT-ACCOUNT` 中，`DELETE-IN-CURRENT-ACCOUNT` 表示通过常规 access token 认证解析出的当前账号；该输入只能发起当前账号的删除请求，不得指定或影响其他账号。 | Important：输入 Ref ID 过泛，缺少 current-account-only。 | 改 Ref ID 并新增 request flow。 |
| `IDENTITY-SPEC-DELETE-002` | 账号删除请求必须校验 `DELETE-IN-IDEMPOTENCY-KEY` 长度，非法时返回 `DELETE-ERR-IDEMPOTENCY-KEY`。 | 在 `DELETE-FLOW-REQUEST-CURRENT-ACCOUNT` 和 `DELETE-FLOW-ADMIN-RETRY` 中，当 `DELETE-IN-IDEMPOTENCY-KEY` 缺失、长度小于 8 个字符或大于 128 个字符时，系统必须返回 `DELETE-ERR-IDEMPOTENCY-KEY`，不得创建删除任务或重试幂等记录，不得启动清理执行，不得撤销 session，不得改变账号或删除任务状态。 | Important：缺少失败后置条件，未覆盖 admin retry 幂等键失败边界，且“非法”表述不清。 | 补充 no state change / no job creation / no retry idempotency，并显式列出无效条件。 |
| `IDENTITY-SPEC-DELETE-003` | 同一用户使用同一 `DELETE-IN-IDEMPOTENCY-KEY` 重复删除时，系统必须返回 `DELETE-JOB-EXISTING`。 | 当同一用户和同一 `DELETE-IN-IDEMPOTENCY-KEY` 已有关联删除任务时，系统必须返回 `DELETE-JOB-EXISTING` 指向的该已有任务，且不得创建第二个删除任务或重复启动清理执行。 | Important：缺少重复执行边界。 | 补充 no duplicate job/execution。 |
| `IDENTITY-SPEC-DELETE-004` | 系统只允许 `DELETE-STATE-ACTIVE` 或 `DELETE-STATE-DELETION-REQUESTED` 账号发起删除执行，否则返回 `DELETE-ERR-INVALID-STATE`。 | `DELETE-FLOW-EXECUTE` 只允许 `DELETE-STATE-ACTIVE` 或 `DELETE-STATE-DELETION-REQUESTED` 账号进入删除执行；账号状态不属于这两者时，系统必须返回 `DELETE-ERR-INVALID-STATE`，且不得启动清理执行。 | Suggestion：应挂到执行 flow。 | 补充 flow anchor 和失败后置边界。 |
| `IDENTITY-SPEC-DELETE-005` | 删除执行必须撤销该用户所有 active session。 | `DELETE-FLOW-EXECUTE` 进入访问撤销阶段后，必须撤销该用户所有 active session；该行为不复用 LOGOUT 的 current-session-only 语义。 | Suggestion：与 LOGOUT 边界需明确。 | 补充删除执行阶段和 all-session 边界。 |
| `IDENTITY-SPEC-DELETE-006` | 删除执行必须完成 `DELETE-CLEANUP-AI`。 | `DELETE-FLOW-EXECUTE` 必须完成 `DELETE-CLEANUP-AI`，覆盖 AI media、TTS cache ownership 和 provider metric 数据清理。 | Pass：Spec 已避免 runner 实现名，可补清覆盖内容。 | 可保留并补充覆盖内容。 |
| `IDENTITY-SPEC-DELETE-007` | 删除完成后，账号状态必须进入 `DELETE-STATE-DELETED`。 | `DELETE-FLOW-EXECUTE` 完成 `DELETE-CLEANUP-AI`、`DELETE-CLEANUP-IDENTITY`、`DELETE-CLEANUP-LEARNING`、`DELETE-CLEANUP-COMMERCE` 和 `DELETE-CLEANUP-GOAL` 中适用于该用户的数据清理后，账号状态必须进入 `DELETE-STATE-DELETED`。 | Suggestion：触发条件应绑定清理完成。 | 补清“适用数据清理完成后”。 |
| `IDENTITY-SPEC-DELETE-008` | 删除完成后，系统必须把 display name 改为 `Deleted User`，清空 avatar ref，并把 onboarding status 标记为 `deleted`。 | 删除完成后，保留的最小账号信息必须输出匿名化状态：display name 为 `Deleted User`、avatar ref 为空、onboarding status 为 `deleted`；profile 明细数据删除由 `DELETE-CLEANUP-IDENTITY` 承接。 | Important：保留的最小账号信息和 profile 明细删除边界不清。 | 补充 retained minimal account information 边界。 |
| `IDENTITY-SPEC-DELETE-009` | 已认证用户必须能查询当前账号最新删除 job 状态。 | `DELETE-FLOW-QUERY-LATEST-JOB` 必须允许 `DELETE-IN-CURRENT-ACCOUNT` 查询当前账号最新删除任务状态；当该当前账号不存在任何删除任务时，系统必须返回 `DELETE-ERR-JOB-NOT-FOUND`。 | Important：缺少 query flow 和 not-found 失败。 | 新增 query flow 与 not-found Ref ID。 |
| `IDENTITY-SPEC-DELETE-010` | 运维用户必须能重试 `DELETE-JOB-FAILED`。 | 通过 `RISK-IN-OPS-BEARER` 运维认证的请求，必须能在 `DELETE-FLOW-ADMIN-RETRY` 中对 `DELETE-JOB-FAILED` 发起重试。 | Important：缺少 ops auth source of truth。 | 引用 RISK ops auth，不复制 admin 认证细节。 |
| `IDENTITY-SPEC-DELETE-011` | 删除重试只允许 `DELETE-JOB-FAILED` 进入重试执行；`DELETE-JOB-COMPLETED` 必须返回已有结果，其他状态返回 `DELETE-ERR-INVALID-STATE`。 | `DELETE-FLOW-ADMIN-RETRY` 必须按重试决策表处理：`DELETE-JOB-FAILED` 且无同重试幂等记录时启动新重试执行；同一删除任务和同一重试幂等键已存在时返回 `DELETE-JOB-RETRY-EXISTING` 且不启动新执行；`DELETE-JOB-COMPLETED` 返回该已完成任务；`DELETE-JOB-IN-PROGRESS` 返回 `DELETE-ERR-IN-PROGRESS`；未识别任务状态返回 `DELETE-ERR-INVALID-STATE`。 | Important：遗漏 retry idempotency 和 in-progress 失败类型；单个长句承载过多分支。 | 新增 retry flow、`DELETE-JOB-IN-PROGRESS`、`DELETE-JOB-RETRY-EXISTING`，并用决策表表达分支。 |
| `IDENTITY-SPEC-DELETE-012` | 删除重试认证必须允许携带同一 `DELETE-IN-IDEMPOTENCY-KEY` 的 deleted 或 deletion_requested 用户重放同一个 `DELETE /user/me` 请求。 | `DELETE-FLOW-REPLAY-DELETION-REQUEST` 仅在 token 对应账号处于 `DELETE-STATE-DELETED` 或 `DELETE-STATE-DELETION-REQUESTED`、且 `DELETE-IN-IDEMPOTENCY-KEY` 与该账号已有删除任务匹配时成立；成立时系统必须返回该已有删除任务，且该认证例外不得扩展到常规 `TOKEN-FLOW-AUTHENTICATE-BEARER`。 | Important：Spec 写入 API path，且与 TOKEN 边界不清。 | 移除 API path，新增 replay flow，并明确 TOKEN source-of-truth。 |
| `IDENTITY-SPEC-DELETE-013` | 删除执行必须删除该用户的 auth identity 记录。引用：`DELETE-CLEANUP-IDENTITY`。 | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-IDENTITY` 中删除该用户的登录身份数据。 | Suggestion：record 风格可收敛为数据族。 | 语义收紧为 identity cleanup 数据族。 |
| `IDENTITY-SPEC-DELETE-014` | 删除执行必须删除该用户的 user profile 记录。引用：`DELETE-CLEANUP-IDENTITY`。 | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-IDENTITY` 中删除该用户的 profile 明细数据；删除后保留的最小账号信息由 `IDENTITY-SPEC-DELETE-008` 承接。 | Important：与最小账号信息保留有潜在冲突。 | 补清 identity cleanup 与最小账号信息保留的分工。 |
| `IDENTITY-SPEC-DELETE-015` | 删除执行必须删除该用户的 onboarding assessment、learning route 和 user scenario state 记录。引用：`DELETE-CLEANUP-LEARNING`。 | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-LEARNING` 中删除该用户的 onboarding assessment、learning route 和 scenario state 数据。 | Pass：清理族明确。 | 挂接到 execute flow 并统一数据语义。 |
| `IDENTITY-SPEC-DELETE-016` | 删除执行必须删除该用户的 practice session、practice turn 和 session summary 记录。引用：`DELETE-CLEANUP-LEARNING`。 | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-LEARNING` 中删除该用户的 practice session、practice turn 和 session summary 数据。 | Pass：清理族明确。 | 挂接到 execute flow 并统一数据语义。 |
| `IDENTITY-SPEC-DELETE-017` | 删除执行必须删除该用户的 training session、training turn、training recap、training planner decision、training evidence candidate 和 training metric event 记录。引用：`DELETE-CLEANUP-LEARNING`。 | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-LEARNING` 中删除该用户的 training session、training turn、training recap、training planner decision、training evidence candidate 和 training metric event 数据。 | Pass：清理族明确。 | 挂接到 execute flow 并统一数据语义。 |
| `IDENTITY-SPEC-DELETE-018` | 删除执行必须删除该用户的 purchase、subscription、entitlement snapshot、usage ledger、usage reservation 和关联 payment provider event 记录。引用：`DELETE-CLEANUP-COMMERCE`。 | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-COMMERCE` 中删除该用户的 purchase、subscription、entitlement snapshot、usage ledger、usage reservation 和关联 payment provider event 数据。 | Pass：清理族明确。 | 挂接到 execute flow 并统一数据语义。 |
| `IDENTITY-SPEC-DELETE-019` | 删除执行必须删除该用户的 learning evidence、learning history、mastery、review、practice queue、favorite expression 和 saved expression 记录。引用：`DELETE-CLEANUP-LEARNING`。 | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-LEARNING` 中删除该用户的 learning evidence、learning history、mastery、review、practice queue、favorite expression 和 saved expression 数据。 | Pass：清理族明确。 | 挂接到 execute flow 并统一数据语义。 |
| `IDENTITY-SPEC-DELETE-020` | 删除执行必须删除该用户的 goal profile、diagnostic assessment、mastery initial state、backplan、daily plan、plan item、autopilot control、goal idempotency、control idempotency、recovery decision、mastery transition decision、notification outbox、planner replay audit、progress forecast 和 outcome checkpoint 记录。引用：`DELETE-CLEANUP-GOAL`。 | `DELETE-FLOW-EXECUTE` 必须在 `DELETE-CLEANUP-GOAL` 中删除该用户的 goal profile、diagnostic assessment、mastery initial state、backplan、daily plan、plan item、autopilot control、goal idempotency、control idempotency、recovery decision、mastery transition decision、notification outbox、planner replay audit、progress forecast 和 outcome checkpoint 数据。 | Conditional：可验收但术语密集，需保持与 domain model/source of truth 一致。 | 挂接到 execute flow；术语不稳定时由 domain model 后续收敛。 |

跨文档发现与 10-F 修复方案：
| 对象 | 问题 | 影响 | 级别 | 10-F 修复方案 |
| --- | --- | --- | --- | --- |
| DELETE Flow Segments | spec 当前只有 item table，没有删除请求、执行、查询、运维重试和删除请求重放 flow。 | 后续 AC/TC 难以生成成功、失败、重放、重试和跨域清理路径。 | Important | 新增 `DELETE-FLOW-REQUEST-CURRENT-ACCOUNT`、`DELETE-FLOW-EXECUTE`、`DELETE-FLOW-QUERY-LATEST-JOB`、`DELETE-FLOW-ADMIN-RETRY`、`DELETE-FLOW-REPLAY-DELETION-REQUEST`。 |
| DELETE Ref ID | `DELETE-IN-AUTHENTICATED` 过泛；缺少 query not-found、retry in-progress、retry replay 等输出/失败信号；`DELETE-IN-IDEMPOTENCY-KEY` 未说明同时适用于当前账号删除请求和运维删除重试请求。 | 输入和失败路径无法独立验收。 | Important | 改为 `DELETE-IN-CURRENT-ACCOUNT`；补充 `DELETE-JOB-IN-PROGRESS`、`DELETE-ERR-JOB-NOT-FOUND`、`DELETE-ERR-IN-PROGRESS`、`DELETE-JOB-RETRY-EXISTING`；并明确 `DELETE-IN-IDEMPOTENCY-KEY` 适用于 `DELETE-FLOW-REQUEST-CURRENT-ACCOUNT` 和 `DELETE-FLOW-ADMIN-RETRY`。 |
| Requirement 内容边界 | `IDENTITY-DELETE-006` 命名内部 runner；`IDENTITY-DELETE-012` 写 API path。 | Requirements 混入实现/API 契约层内容。 | Important | 006 改成数据清理义务；012 改成账号删除请求重放产品语义。 |
| DELETE 与 TOKEN/RISK 边界 | 删除请求重放和运维重试涉及认证例外和 admin 认证，但 spec 未清楚引用 source of truth。 | AC/TC 可能重复定义 token 或 admin auth。 | Important | 删除重放只定义 DELETE 例外，常规 token 仍引用 TOKEN；运维认证引用 RISK。 |
| DELETE 与 AUDIT 边界 | 删除完成、失败、重试会写审计，但本子章节不应提前审查 AUDIT items。 | 容易把审计要求混入 DELETE 修复。 | Suggestion | 10-F 只保留删除流程和清理边界；审计事件语义留到 Task 12-R/F。 |
| Traceability | `IDENTITY-DELETE-001..020` 的 `Spec Flow` 仍为 `TBD - 后续补齐`，但 `IDENTITY-SPEC-DELETE-001..020` 已存在。 | Requirement -> Spec 链路断裂。 | Important | 10-F 同步 `Spec Flow` 到 `IDENTITY-SPEC-DELETE-001..020`；AC/TC 继续保留 TBD。 |

Task 10-R 执行情况：
- 已执行：完成 `IDENTITY-DELETE-001..020` 和 `IDENTITY-SPEC-DELETE-001..020` 的逐条内容契约语义审查。
- 已执行：按 Requirement / Spec 分离格式形成 10-F 修复输入表，并在 item 后附原始描述与修复后描述。
- 10-R 阶段未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；后续 Task 10-F 已按主 agent 与独立 agent 一致通过的方案执行。
- 10-R 阶段未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 11 risk、Task 12 audit 或 Task 13 release。

Task 10-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 10-R | Passed by main+independent agents | 独立 agent 已复核通过，按用户更新后的门禁规则自动进入 Task 10-F。 |
| Task 10-F | Passed by main+independent agents | 独立 agent 已确认 DELETE 修复满足颗粒度/清晰度/覆盖度，并按用户更新后的门禁规则自动进入 Task 11-R。 |

### IDENTITY-DELETE 账号删除与生命周期状态 10-F 修复复审

修复范围：
- Requirements：修复 `IDENTITY-DELETE-001..020` 的认证上下文、幂等键失败、重复请求、允许状态、session 撤销、跨域数据清理、状态查询、运维重试和删除请求重放语义。
- Spec：修复 DELETE Ref ID，新增 DELETE flow segments 和 retry decision table，并修复 `IDENTITY-SPEC-DELETE-001..020`。
- Traceability：同步 `IDENTITY-DELETE-001..020` 的 `Spec Flow` 到 `IDENTITY-SPEC-DELETE-001..020`；`AC` 与 `TC` 继续保留 `TBD - 后续补齐`。
- 独立审查：Task 10-R 候选方案先被独立 agent 判定不通过；主 agent 已按独立意见修正 002、011 和 DELETE Ref ID 后重新提交，独立 agent 结论为“通过，可进入 Task 10-F”。

Requirement 修复复审表：
| Requirement item | 修复前 Requirement 描述 | 修复后 Requirement 描述 | 复审结论 | 状态 |
| --- | --- | --- | --- | --- |
| `IDENTITY-DELETE-001` | 已认证用户必须能发起当前账号删除请求。 | 通过常规 access token 认证并解析到当前账号的用户，必须能为该当前账号发起删除请求；系统不得允许该用户为其他账号发起删除。 | Pass：当前账号来源和不得跨账号删除边界清楚。 | Fixed |
| `IDENTITY-DELETE-002` | 账号删除请求必须要求 idempotency key 长度在 8 到 128 个字符之间。 | 当前账号删除请求和运维删除重试请求必须携带长度在 8 到 128 个字符之间的幂等键；当幂等键缺失、长度小于 8 个字符或大于 128 个字符时，系统必须拒绝请求，不得创建删除任务或重试幂等记录、不得撤销 session、不得改变账号或删除任务状态。 | Pass：显式覆盖 request/retry 两条路径和失败后置边界。 | Fixed |
| `IDENTITY-DELETE-003` | 同一用户使用同一 idempotency key 重复发起删除请求时，系统必须返回已有删除 job。 | 同一用户使用同一幂等键再次发起删除请求时，系统必须返回该用户和该幂等键已经关联的删除任务，且不得创建第二个删除任务。 | Pass：补清不得创建重复删除任务。 | Fixed |
| `IDENTITY-DELETE-004` | 系统必须只允许 `active` 或 `deletion_requested` 账号发起删除执行。 | 只有账号状态为 `active` 或 `deletion_requested` 时，系统才允许该账号进入删除执行；账号状态不是这两者时，系统必须拒绝进入删除执行。 | Pass：允许和拒绝状态边界清楚。 | Fixed |
| `IDENTITY-DELETE-005` | 删除执行必须撤销该用户所有 active session。 | 删除任务进入访问撤销阶段时，系统必须撤销该账号关联用户的所有 active session；该行为不同于 logout 只撤销当前 session。 | Pass：与 LOGOUT current-session-only 语义已区分。 | Fixed |
| `IDENTITY-DELETE-006` | 删除执行必须调用 AI account deletion retention runner 清理该用户关联的 AI media、TTS cache ownership 和 provider metric 数据。 | 删除执行必须清理该用户关联的 AI media、TTS cache ownership 和 provider metric 数据。 | Pass：移除内部 runner 实现名。 | Fixed |
| `IDENTITY-DELETE-007` | 删除完成后，系统必须把账号状态标记为 `deleted`。 | 删除完成后，系统必须把账号生命周期状态标记为 `deleted`。 | Pass：状态语义从字段式表述收敛为生命周期状态。 | Fixed |
| `IDENTITY-DELETE-008` | 删除完成后，系统必须把 display name 改为 `Deleted User`，清空 avatar ref，并把 onboarding status 标记为 `deleted`。 | 删除完成后，系统必须保留用于表示删除状态的最小账号信息：展示名为 `Deleted User`、头像引用为空、onboarding status 为 `deleted`；该最小账号信息不等同于 user profile 明细数据，profile 明细删除由 `IDENTITY-DELETE-014` 承接。 | Pass：最小账号信息保留与 profile 明细删除分工清楚。 | Fixed |
| `IDENTITY-DELETE-009` | 已认证用户必须能查询当前账号最新删除 job 状态。 | 通过常规 access token 认证并解析到当前账号的用户，必须能查询该当前账号最新删除任务状态；账号进入 `deleted` 后不能通过常规 access token 认证继续查询，删除请求重放场景由 `IDENTITY-DELETE-012` 承接。 | Pass：查询认证边界和删除后重放边界已区分。 | Fixed |
| `IDENTITY-DELETE-010` | 运维用户必须能重试 failed 删除 job。 | 通过 ops bearer token 运维认证的请求，必须能对状态为 failed 的删除任务发起重试。 | Pass：运维认证前置明确。 | Fixed |
| `IDENTITY-DELETE-011` | 删除重试必须只允许 failed 删除 job 进入重试执行；completed job 必须返回已有结果，其他状态必须被拒绝。 | 删除重试只有在删除任务状态为 `failed`，且本次重试幂等键未关联该删除任务时，才允许启动新的重试执行；不得因 `completed`、`requested`、`access_revoked`、`deleting_learning_data`、`anonymizing_audit_refs` 或未识别任务状态启动新的重试执行；具体返回或失败结果由 Spec 重试决策表承接。 | Pass：Requirement 只保留是否允许启动新重试执行的业务入口规则。 | Fixed |
| `IDENTITY-DELETE-012` | 删除重试认证必须允许携带同一 idempotency key 的 `deleted` 或 `deletion_requested` 用户重放同一个 `DELETE /user/me` 请求。 | 当请求携带的 token 对应账号状态为 `deleted` 或 `deletion_requested`，且请求幂等键与该账号已有删除任务的幂等键一致时，系统必须允许该请求重放账号删除请求并返回该已有删除任务；该例外不得用于登录、资料读取或其他受保护用户请求。 | Pass：移除 API path，并限定认证例外范围。 | Fixed |
| `IDENTITY-DELETE-013..020` | 删除执行必须删除各业务域记录。 | 删除执行必须删除对应业务域数据；profile 明细删除和最小账号信息保留已拆清。 | Pass：数据清理语义统一为业务数据族，不写表实现。 | Fixed |

Spec 修复复审表：
| Spec item | 修复前 Spec 描述 | 修复后 Spec 描述 | 复审结论 | 状态 |
| --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-DELETE-001` | `DELETE-IN-AUTHENTICATED` 必须能发起当前账号删除请求。 | 在 `DELETE-FLOW-REQUEST-CURRENT-ACCOUNT` 中，`DELETE-IN-CURRENT-ACCOUNT` 表示通过常规 access token 认证解析出的当前账号；该输入只能发起当前账号的删除请求，不得指定或影响其他账号。 | Pass：输入 Ref ID 和 current-account-only 边界清楚。 | Fixed |
| `IDENTITY-SPEC-DELETE-002` | 账号删除请求必须校验 `DELETE-IN-IDEMPOTENCY-KEY` 长度，非法时返回 `DELETE-ERR-IDEMPOTENCY-KEY`。 | 在 `DELETE-FLOW-REQUEST-CURRENT-ACCOUNT` 和 `DELETE-FLOW-ADMIN-RETRY` 中，当 `DELETE-IN-IDEMPOTENCY-KEY` 缺失、长度小于 8 个字符或大于 128 个字符时，系统必须返回 `DELETE-ERR-IDEMPOTENCY-KEY`，不得创建删除任务或重试幂等记录，不得启动清理执行，不得撤销 session，不得改变账号或删除任务状态。 | Pass：不再使用“非法时”，且覆盖 request/admin retry 两条路径。 | Fixed |
| `IDENTITY-SPEC-DELETE-003` | 同一用户使用同一 `DELETE-IN-IDEMPOTENCY-KEY` 重复删除时，系统必须返回 `DELETE-JOB-EXISTING`。 | 当同一用户和同一 `DELETE-IN-IDEMPOTENCY-KEY` 已有关联删除任务时，系统必须返回 `DELETE-JOB-EXISTING` 指向的该已有任务，且不得创建第二个删除任务或重复启动清理执行。 | Pass：重复请求无副作用边界已补清。 | Fixed |
| `IDENTITY-SPEC-DELETE-004` | 系统只允许 `DELETE-STATE-ACTIVE` 或 `DELETE-STATE-DELETION-REQUESTED` 账号发起删除执行，否则返回 `DELETE-ERR-INVALID-STATE`。 | `DELETE-FLOW-EXECUTE` 只允许 `DELETE-STATE-ACTIVE` 或 `DELETE-STATE-DELETION-REQUESTED` 账号进入删除执行；账号状态不属于这两者时，系统必须返回 `DELETE-ERR-INVALID-STATE`，且不得启动清理执行。 | Pass：状态拒绝和 no cleanup 边界清楚。 | Fixed |
| `IDENTITY-SPEC-DELETE-005..010` | 删除执行、AI 清理、deleted 状态、最小账号信息、查询、运维重试。 | 已分别挂接到 `DELETE-FLOW-EXECUTE`、`DELETE-FLOW-QUERY-LATEST-JOB` 和 `DELETE-FLOW-ADMIN-RETRY`，并引用 TOKEN/RISK source of truth。 | Pass：流程锚点和跨模块边界清楚。 | Fixed |
| `IDENTITY-SPEC-DELETE-011` | 删除重试只允许 `DELETE-JOB-FAILED` 进入重试执行；`DELETE-JOB-COMPLETED` 必须返回已有结果，其他状态返回 `DELETE-ERR-INVALID-STATE`。 | `DELETE-FLOW-ADMIN-RETRY` 必须按重试决策表处理：failed+无同重试幂等记录启动新重试；同 job+同重试幂等键返回 `DELETE-JOB-RETRY-EXISTING`；completed 返回已完成任务；`DELETE-JOB-IN-PROGRESS` 返回 `DELETE-ERR-IN-PROGRESS`；未识别任务状态返回 `DELETE-ERR-INVALID-STATE`。 | Pass：复杂分支已从长句拆到决策表。 | Fixed |
| `IDENTITY-SPEC-DELETE-012` | 删除重试认证必须允许携带同一 `DELETE-IN-IDEMPOTENCY-KEY` 的 deleted 或 deletion_requested 用户重放同一个 `DELETE /user/me` 请求。 | `DELETE-FLOW-REPLAY-DELETION-REQUEST` 仅在 token 对应账号处于 `DELETE-STATE-DELETED` 或 `DELETE-STATE-DELETION-REQUESTED`、且幂等键与该账号已有删除任务匹配时成立；成立时返回已有删除任务，且认证例外不得扩展到常规 token 认证。 | Pass：API path 已移除，认证例外边界清楚。 | Fixed |
| `IDENTITY-SPEC-DELETE-013..020` | 各数据族删除并引用 cleanup Ref ID。 | 已挂接到 `DELETE-FLOW-EXECUTE` 和对应 `DELETE-CLEANUP-*` Ref ID，统一为数据清理语义。 | Pass：清理范围和 flow anchor 清楚。 | Fixed |

Spec Ref / Flow / Traceability 复审表：
| 对象 | 修复内容 | 复审结论 | 状态 |
| --- | --- | --- | --- |
| DELETE Ref ID | `DELETE-IN-AUTHENTICATED` 改为 `DELETE-IN-CURRENT-ACCOUNT`；新增 `DELETE-JOB-IN-PROGRESS`、`DELETE-JOB-RETRY-EXISTING`、`DELETE-ERR-JOB-NOT-FOUND`、`DELETE-ERR-IN-PROGRESS`；扩展 `DELETE-IN-IDEMPOTENCY-KEY` 到 request 与 admin retry。 | Pass：输入、状态、输出和失败信号可独立验收。 | Fixed |
| DELETE Flow Segments | 新增 `DELETE-FLOW-REQUEST-CURRENT-ACCOUNT`、`DELETE-FLOW-EXECUTE`、`DELETE-FLOW-QUERY-LATEST-JOB`、`DELETE-FLOW-ADMIN-RETRY`、`DELETE-FLOW-REPLAY-DELETION-REQUEST`。 | Pass：覆盖删除请求、执行、查询、运维重试和重放。 | Fixed |
| Retry Decision Table | 新增 failed、retry replay、completed、in-progress、未识别状态五类分支。 | Pass：复杂重试行为从单句拆成决策表。 | Fixed |
| Traceability | `IDENTITY-DELETE-001..020` 的 `Spec Flow` 同步为 `IDENTITY-SPEC-DELETE-001..020`；AC/TC 保持 `TBD - 后续补齐`。 | Pass：补齐 Requirement -> Spec 链路，同时未伪造 AC、TC 或测试证据。 | Fixed |

Task 10-F 执行情况：
- 已执行：修复 DELETE requirements 二十条 item。
- 已执行：修复 DELETE spec Ref ID、flow segments、retry decision table 和二十条 spec item。
- 已执行：同步 `traceability.md` 中 `IDENTITY-DELETE-001..020` 的 `Spec Flow`。
- 未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 11 risk 子章节。

Task 10-F 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 10-F | Passed by main+independent agents | 独立 agent 已确认修复满足颗粒度/清晰度/覆盖度。 |
| Task 11-R | Passed by main+independent agents | 独立 agent 已确认 11-R 审查方案满足颗粒度/清晰度/覆盖度，按用户更新后的门禁规则自动进入 Task 11-F。 |

### IDENTITY-RISK 风控、限流与防滥用 11-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-RISK-001..003`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-RISK-001..003`
- 交叉引用 Ref ID：`RISK-IN-BEARER`、`RISK-IN-OPS-BEARER`、`RISK-OUT-UNAUTHENTICATED-JSON`、`RISK-ERR-ADMIN-FORBIDDEN`、`RISK-SEC-HASH-COMPARE`
- 只读上下文：`BearerTokenAuthenticationFilter`、`SecurityConfig`、`TokenHasher` 的 current code evidence。

本轮结果：conditional。RISK 子章节可以继续作为 current-code-baseline Draft 输入；没有阻止 Draft 留存的 blocker。但当前标题和 item 容易让读者误以为登录限流、OTP 限流、IP/device 风控或 CAPTCHA 已实现。11-F 应把本子章节收窄为“认证错误响应、ops admin 访问门禁与当前防滥用边界”，并补充 protected request / admin ops auth 的 flow segment；traceability 的 `Spec Flow` 也应从 TBD 同步为具体 spec ID。

Requirement 审查与 11-F 修复方案：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 结论 | 11-F Requirement 修复方案 |
| --- | --- | --- | --- | --- |
| `IDENTITY-RISK-001` | 无效 bearer token 访问受保护接口时，系统必须返回 JSON 格式的未认证错误。 | 受保护用户请求无法建立常规用户认证上下文时，系统必须返回 JSON 格式的未认证错误；具体 access token eligibility 由 `IDENTITY-TOKEN` 承接，公共端点不由本 item 承诺。 | Important：原文只写 invalid bearer，未覆盖缺失认证上下文和与 TOKEN source of truth 的边界。 | 改为 protected request 未认证错误响应，不重新定义 token eligibility。 |
| `IDENTITY-RISK-002` | admin 接口必须只允许 ops bearer token 认证通过。 | admin 请求只有通过 ops bearer token 运维认证后才能进入 admin 处理；常规用户 access token 不得获得 admin 权限。 | Important：需要明确常规用户 token 与 ops token 的权限边界。 | 补清 admin-only ops auth 和普通用户不得获得 admin 权限。 |
| `IDENTITY-RISK-003` | ops bearer token 必须以 hash 形式比较。 | ops bearer token 认证必须使用服务端保存的 token 摘要进行匹配，不得以 ops token 明文作为比较基准。 | Suggestion：`hash 形式比较` 偏实现短语，应表达安全约束和比较基准。 | 改为摘要匹配安全要求；具体算法由 code evidence/API security implementation 承接。 |

Spec 审查与 11-F 修复方案：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 结论 | 11-F Spec 修复方案 |
| --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-RISK-001` | 无效 `RISK-IN-BEARER` 访问受保护接口时，系统必须返回 `RISK-OUT-UNAUTHENTICATED-JSON`。 | 在 `RISK-FLOW-PROTECTED-UNAUTHENTICATED` 中，当受保护用户请求无法通过 `TOKEN-FLOW-AUTHENTICATE-BEARER` 建立常规用户认证上下文时，系统必须返回 `RISK-OUT-UNAUTHENTICATED-JSON`，不得进入受保护业务处理。 | Important：需要引用 TOKEN flow，并补充 no business processing 后置边界。 | 新增 protected unauthenticated flow，避免重复定义 token 认证规则。 |
| `IDENTITY-SPEC-RISK-002` | admin 接口必须只允许 `RISK-IN-OPS-BEARER` 认证通过，否则返回 `RISK-ERR-ADMIN-FORBIDDEN`。 | 在 `RISK-FLOW-ADMIN-OPS-AUTH` 中，admin 请求只有满足 `RISK-IN-OPS-BEARER` 时才能获得 ops 权限；已建立常规用户认证上下文但不具备 ops 权限的请求访问 admin 入口时必须返回 `RISK-ERR-ADMIN-FORBIDDEN`；未建立认证上下文的 admin 请求仍按 `RISK-OUT-UNAUTHENTICATED-JSON` 处理。 | Important：原文把所有非 ops 情况都写成 forbidden，但代码基线区分 unauthenticated 与 authenticated-non-ops。 | 补充 admin flow，并拆清 unauthenticated 与 authenticated-non-ops。 |
| `IDENTITY-SPEC-RISK-003` | ops bearer token 必须使用 `RISK-SEC-HASH-COMPARE`，不得以明文直接比较。 | `RISK-IN-OPS-BEARER` 认证必须使用 `RISK-SEC-OPS-TOKEN-DIGEST-MATCH` 与服务端保存的 ops token 摘要匹配；不得把 ops token 明文作为比较基准。 | Suggestion：Ref ID 名称应从泛化 hash compare 收敛为 ops token digest match。 | 将 `RISK-SEC-HASH-COMPARE` 改为 `RISK-SEC-OPS-TOKEN-DIGEST-MATCH`。 |

跨文档发现与 11-F 修复方案：
| 对象 | 问题 | 影响 | 级别 | 11-F 修复方案 |
| --- | --- | --- | --- | --- |
| RISK 小节标题 | 标题写“风控、限流与防滥用”，但当前归档 item 只覆盖认证错误、ops admin 门禁和 ops token 摘要匹配。 | 后续可能误判登录限流、OTP 限流、IP/device 风控、CAPTCHA 已实现。 | Important | 改为 `IDENTITY-RISK 认证错误、ops admin 访问门禁与当前防滥用边界`，非目标仍保留未实现风控项。 |
| RISK Flow Segments | spec 当前只有 item table，没有 protected unauthenticated 和 admin ops auth flow。 | AC/TC 难以区分未认证、普通用户访问 admin、ops token 通过。 | Important | 新增 `RISK-FLOW-PROTECTED-UNAUTHENTICATED` 和 `RISK-FLOW-ADMIN-OPS-AUTH`。 |
| RISK Ref ID | `RISK-ERR-ADMIN-FORBIDDEN` 当前语义过宽，容易把未认证/无效 bearer 与已认证但无 ops 权限的 admin 访问混为同一个 forbidden 分支。 | Spec 错误边界不清，AC/TC 会难以区分 unauthenticated 与 authenticated-non-ops。 | Important | 将 `RISK-ERR-ADMIN-FORBIDDEN` 收窄为“已建立常规用户认证上下文但不具备 ops 权限的请求访问 admin 入口时的安全错误”；未建立认证上下文的 admin 请求必须继续使用 `RISK-OUT-UNAUTHENTICATED-JSON`。 |
| RISK Ref ID | `RISK-SEC-HASH-COMPARE` 过泛，未说明比较对象是 ops token 摘要。 | 安全要求可验收性不足。 | Suggestion | 改为 `RISK-SEC-OPS-TOKEN-DIGEST-MATCH`。 |
| Traceability | `IDENTITY-RISK-001..003` 的 `Spec Flow` 仍为 `TBD - 后续补齐`，但 `IDENTITY-SPEC-RISK-001..003` 已存在。 | Requirement -> Spec 链路断裂。 | Important | 11-F 同步 `Spec Flow` 到 `IDENTITY-SPEC-RISK-001..003`；AC/TC 继续保留 TBD。 |

Task 11-R 执行情况：
- 已执行：完成 `IDENTITY-RISK-001..003` 和 `IDENTITY-SPEC-RISK-001..003` 的逐条内容契约语义审查。
- 已执行：按 Requirement / Spec 分离格式形成 11-F 修复输入表，并在 item 后附原始描述与修复后描述。
- 已执行：独立 agent 初次复核指出 `RISK-ERR-ADMIN-FORBIDDEN` 边界过宽；本审查表已按该意见补充 Ref ID 收窄方案，并重新提交独立复核。
- 11-R 阶段未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；后续 Task 11-F 已按主 agent 与独立 agent 一致通过的方案执行。
- 未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 12 audit 或 Task 13 release。

Task 11-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 11-R | Passed by main+independent agents | 独立 agent 已确认本审查表满足颗粒度/清晰度/覆盖度，并按用户更新后的门禁规则自动进入 Task 11-F。 |
| Task 11-F | Passed by main+independent agents | 独立 agent 已确认 RISK 修复满足颗粒度/清晰度/覆盖度，并按用户更新后的门禁规则自动进入 Task 12-R。 |

### IDENTITY-RISK 认证错误、ops admin 访问门禁与当前防滥用边界 11-F 修复复审

修复范围：
- Requirements：收窄 RISK 小节标题，修复 `IDENTITY-RISK-001..003` 的认证错误、admin ops 权限和 ops token 摘要匹配语义。
- Spec：修复 RISK Ref ID，新增 `RISK-FLOW-PROTECTED-UNAUTHENTICATED` 与 `RISK-FLOW-ADMIN-OPS-AUTH`，并修复 `IDENTITY-SPEC-RISK-001..003`。
- Traceability：同步 `IDENTITY-RISK-001..003` 的 `Spec Flow` 到 `IDENTITY-SPEC-RISK-001..003`；`AC` 与 `TC` 继续保留 `TBD - 后续补齐`。
- 独立审查：Task 11-R 候选方案初次被独立 agent 判定不通过；主 agent 已按独立意见收窄 `RISK-ERR-ADMIN-FORBIDDEN`，重新提交后独立 agent 结论为“通过，可进入 Task 11-F”。

Requirement 修复复审表：
| Requirement item | 修复前 Requirement 描述 | 修复后 Requirement 描述 | 复审结论 | 状态 |
| --- | --- | --- | --- | --- |
| `IDENTITY-RISK-001` | 无效 bearer token 访问受保护接口时，系统必须返回 JSON 格式的未认证错误。 | 受保护用户请求无法建立常规用户认证上下文时，系统必须返回 JSON 格式的未认证错误；具体 access token eligibility 由 `IDENTITY-TOKEN` 承接，公共端点不由本 item 承诺。 | Pass：触发条件从 invalid bearer 收窄/扩展为无法建立常规用户认证上下文，并把 token eligibility 交还 TOKEN。 | Fixed |
| `IDENTITY-RISK-002` | admin 接口必须只允许 ops bearer token 认证通过。 | admin 请求只有通过 ops bearer token 运维认证后才能进入 admin 处理；常规用户 access token 不得获得 admin 权限。 | Pass：admin 入口权限边界清楚，未把常规用户认证等同于 ops 权限。 | Fixed |
| `IDENTITY-RISK-003` | ops bearer token 必须以 hash 形式比较。 | ops bearer token 认证必须使用服务端保存的 token 摘要进行匹配，不得以 ops token 明文作为比较基准。 | Pass：从泛化 hash 表述收敛为可验收的摘要匹配安全约束。 | Fixed |

Spec 修复复审表：
| Spec item | 修复前 Spec 描述 | 修复后 Spec 描述 | 复审结论 | 状态 |
| --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-RISK-001` | 无效 `RISK-IN-BEARER` 访问受保护接口时，系统必须返回 `RISK-OUT-UNAUTHENTICATED-JSON`。 | 在 `RISK-FLOW-PROTECTED-UNAUTHENTICATED` 中，当受保护用户请求无法通过 `TOKEN-FLOW-AUTHENTICATE-BEARER` 建立常规用户认证上下文时，系统必须返回 `RISK-OUT-UNAUTHENTICATED-JSON`，不得进入受保护业务处理。 | Pass：引用 TOKEN source of truth，并补清不得进入业务处理的后置边界。 | Fixed |
| `IDENTITY-SPEC-RISK-002` | admin 接口必须只允许 `RISK-IN-OPS-BEARER` 认证通过，否则返回 `RISK-ERR-ADMIN-FORBIDDEN`。 | 在 `RISK-FLOW-ADMIN-OPS-AUTH` 中，admin 请求只有满足 `RISK-IN-OPS-BEARER` 并通过 `RISK-SEC-OPS-TOKEN-DIGEST-MATCH` 时才能获得 ops 权限；已建立常规用户认证上下文但不具备 ops 权限的请求访问 admin 入口时必须返回 `RISK-ERR-ADMIN-FORBIDDEN`；未建立认证上下文的 admin 请求必须返回 `RISK-OUT-UNAUTHENTICATED-JSON`。 | Pass：已区分 unauthenticated 与 authenticated-non-ops 两类失败结果。 | Fixed |
| `IDENTITY-SPEC-RISK-003` | ops bearer token 必须使用 `RISK-SEC-HASH-COMPARE`，不得以明文直接比较。 | `RISK-IN-OPS-BEARER` 认证必须使用 `RISK-SEC-OPS-TOKEN-DIGEST-MATCH` 与服务端保存的 ops token 摘要匹配；不得把 ops token 明文作为比较基准。 | Pass：Ref ID 与安全约束均收敛到 ops token digest match。 | Fixed |

Spec Ref / Flow / Traceability 复审表：
| 对象 | 修复内容 | 复审结论 | 状态 |
| --- | --- | --- | --- |
| RISK 小节标题 | 从 `IDENTITY-RISK 风控、限流与防滥用` 改为 `IDENTITY-RISK 认证错误、ops admin 访问门禁与当前防滥用边界`。 | Pass：标题不再暗示登录限流、OTP 限流、IP/device 风控、CAPTCHA 已实现。 | Fixed |
| RISK Ref ID | 收窄 `RISK-IN-BEARER`、`RISK-OUT-UNAUTHENTICATED-JSON` 和 `RISK-ERR-ADMIN-FORBIDDEN`；`RISK-SEC-HASH-COMPARE` 改为 `RISK-SEC-OPS-TOKEN-DIGEST-MATCH`。 | Pass：输入、输出、失败和安全要求都可独立验收。 | Fixed |
| RISK Flow Segments | 新增 `RISK-FLOW-PROTECTED-UNAUTHENTICATED` 和 `RISK-FLOW-ADMIN-OPS-AUTH`。 | Pass：覆盖受保护请求未认证、ops admin 通过、已认证非 ops 被拒绝三条关键路径。 | Fixed |
| Traceability | `IDENTITY-RISK-001..003` 的 `Spec Flow` 同步为 `IDENTITY-SPEC-RISK-001..003`；AC/TC 保持 `TBD - 后续补齐`。 | Pass：补齐 Requirement -> Spec 链路，同时未伪造 AC、TC 或测试证据。 | Fixed |

Task 11-F 执行情况：
- 已执行：修复 RISK requirements 三条 item 和小节标题。
- 已执行：修复 RISK spec Ref ID、flow segments 和三条 spec item。
- 已执行：同步 `traceability.md` 中 `IDENTITY-RISK-001..003` 的 `Spec Flow`。
- 未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 12 audit 或 Task 13 release。

Task 11-F 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 11-F | Passed by main+independent agents | 独立 agent 已确认修复满足颗粒度/清晰度/覆盖度，并按用户更新后的门禁规则自动进入 Task 12-R。 |
| Task 12-R | Passed by main+independent agents | 独立 agent 已确认 12-R 审查方案满足颗粒度/清晰度/覆盖度，按用户更新后的门禁规则自动进入 Task 12-F。 |

### IDENTITY-AUDIT 审计、隐私与合规 12-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-AUDIT-001..006`
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-AUDIT-001..006`
- 交叉引用 Ref ID：`AUDIT-IN-RAW`、`AUDIT-OUT-REDACTED`、`AUDIT-SENSITIVE-PATTERN`、`AUDIT-EVENT-DELETION-COMPLETED`、`AUDIT-EVENT-DELETION-FAILED`、`AUDIT-EVENT-DELETION-RETRY`、`AUDIT-EVENT-QUERY`
- 只读上下文：`AuditLog`、`AuditRedaction`、`AccountDeletionService`、`AdminAuditController`、`AuditLogService` 的 current code evidence。

本轮结果：conditional。AUDIT 子章节可以继续作为 current-code-baseline Draft 输入；没有阻止 Draft 留存的 blocker。但当前 requirements/spec 仍偏“字段或事件名映射”，缺少审计写入、敏感信息清洗、删除事件和 ops admin 查询的 flow segment。12-F 应补充 AUDIT flow，并把“共享 audit log 查询”收敛为 ops admin 审计日志查询，避免误以为所有用户可见共享审计查询都已实现。

Requirement 审查与 12-F 修复方案：
| Requirement item | 原始 Requirement 描述 | 修复后 Requirement 描述 | 结论 | 12-F Requirement 修复方案 |
| --- | --- | --- | --- | --- |
| `IDENTITY-AUDIT-001` | 写入 audit log 时，系统必须清洗 target ref、request id 和 details。 | 创建或持久化审计记录时，系统必须对审计目标引用、请求标识和详情内容执行敏感信息清洗；清洗后输出必须满足 `IDENTITY-AUDIT-002` 的敏感集合与安全占位规则。 | Important：原文混用字段名但没有说明清洗结果边界；应保留业务审计语义并引用敏感集合 source of truth。 | 改为审计记录写入清洗义务，并由 `IDENTITY-AUDIT-002` 承接封闭敏感集合和安全占位。 |
| `IDENTITY-AUDIT-002` | audit redaction 必须识别 token、secret、signature、receipt、URL 等敏感 key 或 value。 | 审计清洗必须按 current code baseline 的封闭敏感集合识别 key token：`api_key`、`audio`、`authorization`、`credential`、`idempotency`、`payload`、`provider_key`、`raw`、`receipt`、`secret`、`signature`、`signed`、`token`、`transcript`、`url`；并识别 value pattern：`signature=`、`token=`、`secret`、`api_key`、`raw_payload`、`full_transcript`、`http://`、`https://`。命中敏感 details key 时必须把 details key 输出为 `redacted_field_<index>` 且 value 输出为 `redacted`；命中敏感 details value 时必须把 value 输出为 `redacted`；敏感 target ref 必须输出 `redacted:target_ref`；敏感或空白 request id 必须输出 `unknown`。 | Important：“等”导致敏感范围不可验收；需要把当前 baseline 承诺的敏感类别和安全占位列成封闭集合。 | 删除“等”，列出 current code baseline 的 key token、value pattern 和封闭安全占位结果。 |
| `IDENTITY-AUDIT-003` | 账号删除完成时，系统必须写入删除完成 audit event。 | 账号删除执行完成时，系统必须写入删除完成审计事件；若完成来自运维重试，审计事件必须能区分重试完成结果。 | Suggestion：当前代码区分普通删除完成与重试完成，Requirement 应表达结果语义而不是只写单一事件名。 | 补充 retry completed 作为 deletion completed 结果变体。 |
| `IDENTITY-AUDIT-004` | 账号删除失败时，系统必须写入删除失败 audit event。 | 账号删除执行失败时，系统必须写入删除失败审计事件；若失败来自运维重试，审计事件必须能区分重试失败结果。 | Suggestion：当前代码区分普通删除失败与重试失败，Requirement 应表达失败语义变体。 | 补充 retry failed 作为 deletion failed 结果变体。 |
| `IDENTITY-AUDIT-005` | 账号删除重试请求必须写入删除重试 audit event。 | 通过 ops 运维认证并被接受进入处理的账号删除重试请求，必须写入删除重试请求审计事件；未通过认证或未进入重试处理的请求不由本 item 承诺。 | Important：原文未说明是所有请求还是 accepted retry request；应避免承诺无效请求也写入同一事件。 | 限定触发为通过 ops 认证且被接受处理的重试请求。 |
| `IDENTITY-AUDIT-006` | 共享 audit log 查询必须记录查询行为 audit event。 | ops admin 查询审计日志列表时，系统必须记录该查询行为的审计事件；该事件只证明 admin audit 查询被记录，不承诺普通用户可见的共享审计日志查询。 | Important：“共享 audit log 查询”边界不清，容易误解为用户侧共享查询能力。 | 改为 ops admin audit log list query，并明确不承诺普通用户共享查询。 |

Spec 审查与 12-F 修复方案：
| Spec item | 原始 Spec 描述 | 修复后 Spec 描述 | 结论 | 12-F Spec 修复方案 |
| --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-AUDIT-001` | 写入 audit log 时，系统必须把 `AUDIT-IN-RAW` 清洗为 `AUDIT-OUT-REDACTED`。 | 在 `AUDIT-FLOW-REDACT-ON-WRITE` 中，当系统创建审计记录并接收 `AUDIT-IN-RAW` 时，必须输出 `AUDIT-OUT-REDACTED`，且持久化审计记录不得保存未清洗的 target ref、request id 或 details。 | Important：缺少 flow anchor 和 no raw persistence 后置边界。 | 新增 redaction-on-write flow，补清不得持久化未清洗内容。 |
| `IDENTITY-SPEC-AUDIT-002` | audit redaction 必须识别 `AUDIT-SENSITIVE-PATTERN` 并避免敏感信息进入 audit 输出。 | 在 `AUDIT-FLOW-REDACT-SENSITIVE-CONTENT` 中，`AUDIT-SENSITIVE-PATTERN` 必须覆盖 key token 集合 `api_key`、`audio`、`authorization`、`credential`、`idempotency`、`payload`、`provider_key`、`raw`、`receipt`、`secret`、`signature`、`signed`、`token`、`transcript`、`url`，以及 value pattern 集合 `signature=`、`token=`、`secret`、`api_key`、`raw_payload`、`full_transcript`、`http://`、`https://`；命中 sensitive details key 时，输出 details key 必须为 `redacted_field_<index>` 且 value 为 `redacted`；命中 sensitive details value 时，value 必须为 `redacted`；命中 sensitive target ref 时必须输出 `redacted:target_ref`；命中 sensitive 或空白 request id 时必须输出 `unknown`；所有结果必须进入 `AUDIT-OUT-REDACTED`。 | Important：需要说明命中后的可观察输出、封闭敏感集合和封闭安全占位结果。 | 新增 sensitive-content flow，并补充 current baseline key/value pattern 与 replacement output。 |
| `IDENTITY-SPEC-AUDIT-003` | 账号删除完成时，系统必须写入 `AUDIT-EVENT-DELETION-COMPLETED`。 | 在 `AUDIT-FLOW-ACCOUNT-DELETION-RESULT` 中，账号删除执行完成时必须写入 `AUDIT-EVENT-DELETION-COMPLETED`；当完成来自运维重试时，该事件必须能区分 retry completed 变体。 | Suggestion：补充 deletion result flow 和 retry completed 变体。 | 将完成事件挂到 account deletion result flow。 |
| `IDENTITY-SPEC-AUDIT-004` | 账号删除失败时，系统必须写入 `AUDIT-EVENT-DELETION-FAILED`。 | 在 `AUDIT-FLOW-ACCOUNT-DELETION-RESULT` 中，账号删除执行失败时必须写入 `AUDIT-EVENT-DELETION-FAILED`；当失败来自运维重试时，该事件必须能区分 retry failed 变体。 | Suggestion：补充 deletion result flow 和 retry failed 变体。 | 将失败事件挂到 account deletion result flow。 |
| `IDENTITY-SPEC-AUDIT-005` | 账号删除重试请求必须写入 `AUDIT-EVENT-DELETION-RETRY`。 | 在 `AUDIT-FLOW-ACCOUNT-DELETION-RETRY-REQUESTED` 中，通过 `RISK-FLOW-ADMIN-OPS-AUTH` 且被接受进入重试处理的删除重试请求，必须写入 `AUDIT-EVENT-DELETION-RETRY`。 | Important：需要引用 RISK ops auth source of truth，并限定 accepted retry request。 | 新增 retry-requested flow。 |
| `IDENTITY-SPEC-AUDIT-006` | 共享 audit log 查询必须记录 `AUDIT-EVENT-QUERY`。 | 在 `AUDIT-FLOW-ADMIN-AUDIT-QUERY` 中，通过 `RISK-FLOW-ADMIN-OPS-AUTH` 的 ops admin 审计日志列表查询必须记录 `AUDIT-EVENT-QUERY`；返回的审计详情必须来自 `AUDIT-OUT-REDACTED`，不得输出未清洗 details。 | Important：需要把“共享查询”收敛为 ops admin 查询，并补清返回内容 redaction 边界。 | 新增 admin audit query flow，引用 RISK ops auth。 |

跨文档发现与 12-F 修复方案：
| 对象 | 问题 | 影响 | 级别 | 12-F 修复方案 |
| --- | --- | --- | --- | --- |
| AUDIT Flow Segments | spec 当前只有 item table，没有审计写入清洗、敏感内容替换、删除结果、删除重试请求和 admin 查询 flow。 | AC/TC 难以生成写入、读取、删除事件和查询审计的可观察路径。 | Important | 新增 `AUDIT-FLOW-REDACT-ON-WRITE`、`AUDIT-FLOW-REDACT-SENSITIVE-CONTENT`、`AUDIT-FLOW-ACCOUNT-DELETION-RESULT`、`AUDIT-FLOW-ACCOUNT-DELETION-RETRY-REQUESTED`、`AUDIT-FLOW-ADMIN-AUDIT-QUERY`。 |
| AUDIT Ref ID | `AUDIT-SENSITIVE-PATTERN` 使用“等”类开放范围；候选封闭集合若遗漏 `signed`、`raw`、`payload`、`audio`、`transcript` 等 current baseline key token，也会低估当前安全清洗承诺；`AUDIT-EVENT-QUERY` 没有说明是 ops admin 查询事件。 | Ref ID 可验收性不足，容易扩大为普通用户共享审计查询或遗漏 current baseline 敏感内容。 | Important | 将 `AUDIT-SENSITIVE-PATTERN` 定义为封闭 baseline 集合：key token 为 `api_key`、`audio`、`authorization`、`credential`、`idempotency`、`payload`、`provider_key`、`raw`、`receipt`、`secret`、`signature`、`signed`、`token`、`transcript`、`url`；value pattern 为 `signature=`、`token=`、`secret`、`api_key`、`raw_payload`、`full_transcript`、`http://`、`https://`；安全占位为 sensitive details key `redacted_field_<index>` + value `redacted`、sensitive details value `redacted`、target ref `redacted:target_ref`、request id `unknown`。把 `AUDIT-EVENT-QUERY` 定义为 ops admin audit list query event。 |
| AUDIT 与 RISK 边界 | 删除重试请求和 admin audit 查询都依赖 ops bearer 认证，但 spec 未引用 RISK source of truth。 | 容易在 AUDIT 里重复定义 admin 认证规则。 | Suggestion | 在 AUDIT flow 中引用 `RISK-FLOW-ADMIN-OPS-AUTH`，不重写 ops bearer 认证细节。 |
| Traceability | `IDENTITY-AUDIT-001..006` 的 `Spec Flow` 仍为 `TBD - 后续补齐`，但 `IDENTITY-SPEC-AUDIT-001..006` 已存在。 | Requirement -> Spec 链路断裂。 | Important | 12-F 同步 `Spec Flow` 到 `IDENTITY-SPEC-AUDIT-001..006`；AC/TC 继续保留 TBD。 |

Task 12-R 执行情况：
- 已执行：完成 `IDENTITY-AUDIT-001..006` 和 `IDENTITY-SPEC-AUDIT-001..006` 的逐条内容契约语义审查。
- 已执行：按 Requirement / Spec 分离格式形成 12-F 修复输入表，并在 item 后附原始描述与修复后描述。
- 已执行：独立 agent 初次复核指出 `AUDIT-SENSITIVE-PATTERN` 封闭集合和安全占位不完整；本审查表已按该意见补齐 key token、value pattern 和固定占位输出，并重新提交独立复核。
- 12-R 阶段未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；等待独立 agent 复核通过后再执行 Task 12-F。
- 未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 13 release。

Task 12-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 12-R | Passed by main+independent agents | 独立 agent 已确认本审查表满足颗粒度/清晰度/覆盖度，并按用户更新后的门禁规则自动进入 Task 12-F。 |
| Task 12-F | Passed by main+independent agents | 独立 agent 已确认 AUDIT 修复满足颗粒度/清晰度/覆盖度，并按用户更新后的门禁规则自动进入 Task 13-R。 |

### IDENTITY-AUDIT 审计、隐私与合规 12-F 修复复审

修复范围：
- Requirements：修复 `IDENTITY-AUDIT-001..006` 的审计写入清洗、封闭敏感集合、删除结果事件、删除重试请求事件和 ops admin 查询审计语义。
- Spec：修复 AUDIT Ref ID，新增 AUDIT flow segments，并修复 `IDENTITY-SPEC-AUDIT-001..006`。
- Traceability：同步 `IDENTITY-AUDIT-001..006` 的 `Spec Flow` 到 `IDENTITY-SPEC-AUDIT-001..006`；`AC` 与 `TC` 继续保留 `TBD - 后续补齐`。
- 独立审查：Task 12-R 候选方案初次被独立 agent 判定不通过；主 agent 已按独立意见补齐 `AUDIT-SENSITIVE-PATTERN` 的 key token、value pattern 和固定占位输出，重新提交后独立 agent 结论为“通过，可进入 Task 12-F”。

Requirement 修复复审表：
| Requirement item | 修复前 Requirement 描述 | 修复后 Requirement 描述 | 复审结论 | 状态 |
| --- | --- | --- | --- | --- |
| `IDENTITY-AUDIT-001` | 写入 audit log 时，系统必须清洗 target ref、request id 和 details。 | 创建或持久化审计记录时，系统必须对审计目标引用、请求标识和详情内容执行敏感信息清洗；清洗后输出必须满足 `IDENTITY-AUDIT-002` 的敏感集合与安全占位规则。 | Pass：写入清洗义务清楚，敏感集合 source of truth 交给 002。 | Fixed |
| `IDENTITY-AUDIT-002` | audit redaction 必须识别 token、secret、signature、receipt、URL 等敏感 key 或 value。 | 审计清洗必须按当前代码基线的封闭敏感集合识别 key token：`api_key`、`audio`、`authorization`、`credential`、`idempotency`、`payload`、`provider_key`、`raw`、`receipt`、`secret`、`signature`、`signed`、`token`、`transcript`、`url`；并识别 value pattern：`signature=`、`token=`、`secret`、`api_key`、`raw_payload`、`full_transcript`、`http://`、`https://`。命中敏感 details key 时必须把 details key 输出为 `redacted_field_<index>` 且 value 输出为 `redacted`；命中敏感 details value 时必须把 value 输出为 `redacted`；敏感 target ref 必须输出 `redacted:target_ref`；敏感或空白 request id 必须输出 `unknown`。 | Pass：去掉“等”，封闭集合和固定占位完整。 | Fixed |
| `IDENTITY-AUDIT-003` | 账号删除完成时，系统必须写入删除完成 audit event。 | 账号删除执行完成时，系统必须写入删除完成审计事件；若完成来自运维重试，审计事件必须能区分重试完成结果。 | Pass：覆盖普通完成与重试完成变体。 | Fixed |
| `IDENTITY-AUDIT-004` | 账号删除失败时，系统必须写入删除失败 audit event。 | 账号删除执行失败时，系统必须写入删除失败审计事件；若失败来自运维重试，审计事件必须能区分重试失败结果。 | Pass：覆盖普通失败与重试失败变体。 | Fixed |
| `IDENTITY-AUDIT-005` | 账号删除重试请求必须写入删除重试 audit event。 | 通过 ops 运维认证并被接受进入处理的账号删除重试请求，必须写入删除重试请求审计事件；未通过认证或未进入重试处理的请求不由本 item 承诺。 | Pass：触发条件限定为 accepted retry request，未扩大到无效请求。 | Fixed |
| `IDENTITY-AUDIT-006` | 共享 audit log 查询必须记录查询行为 audit event。 | ops admin 查询审计日志列表时，系统必须记录该查询行为的审计事件；该事件只证明 admin audit 查询被记录，不承诺普通用户可见的共享审计日志查询。 | Pass：从模糊“共享查询”收敛为 ops admin audit list query。 | Fixed |

Spec 修复复审表：
| Spec item | 修复前 Spec 描述 | 修复后 Spec 描述 | 复审结论 | 状态 |
| --- | --- | --- | --- | --- |
| `IDENTITY-SPEC-AUDIT-001` | 写入 audit log 时，系统必须把 `AUDIT-IN-RAW` 清洗为 `AUDIT-OUT-REDACTED`。 | 在 `AUDIT-FLOW-REDACT-ON-WRITE` 中，当系统创建审计记录并接收 `AUDIT-IN-RAW` 时，必须输出 `AUDIT-OUT-REDACTED`，且持久化审计记录不得保存未清洗的 target ref、request id 或 details。 | Pass：flow anchor 和 no raw persistence 边界清楚。 | Fixed |
| `IDENTITY-SPEC-AUDIT-002` | audit redaction 必须识别 `AUDIT-SENSITIVE-PATTERN` 并避免敏感信息进入 audit 输出。 | 在 `AUDIT-FLOW-REDACT-SENSITIVE-CONTENT` 中，`AUDIT-SENSITIVE-PATTERN` 必须覆盖 key token 集合 `api_key`、`audio`、`authorization`、`credential`、`idempotency`、`payload`、`provider_key`、`raw`、`receipt`、`secret`、`signature`、`signed`、`token`、`transcript`、`url`，以及 value pattern 集合 `signature=`、`token=`、`secret`、`api_key`、`raw_payload`、`full_transcript`、`http://`、`https://`；命中 sensitive details key 时，输出 details key 必须为 `redacted_field_<index>` 且 value 为 `redacted`；命中 sensitive details value 时，value 必须为 `redacted`；命中 sensitive target ref 时必须输出 `redacted:target_ref`；命中 sensitive 或空白 request id 时必须输出 `unknown`；所有结果必须进入 `AUDIT-OUT-REDACTED`。 | Pass：封闭敏感集合和输出占位完整。 | Fixed |
| `IDENTITY-SPEC-AUDIT-003` | 账号删除完成时，系统必须写入 `AUDIT-EVENT-DELETION-COMPLETED`。 | 在 `AUDIT-FLOW-ACCOUNT-DELETION-RESULT` 中，账号删除执行完成时必须写入 `AUDIT-EVENT-DELETION-COMPLETED`；当完成来自运维重试时，该事件必须能区分 retry completed 变体。 | Pass：完成事件挂到删除结果 flow，并区分 retry completed。 | Fixed |
| `IDENTITY-SPEC-AUDIT-004` | 账号删除失败时，系统必须写入 `AUDIT-EVENT-DELETION-FAILED`。 | 在 `AUDIT-FLOW-ACCOUNT-DELETION-RESULT` 中，账号删除执行失败时必须写入 `AUDIT-EVENT-DELETION-FAILED`；当失败来自运维重试时，该事件必须能区分 retry failed 变体。 | Pass：失败事件挂到删除结果 flow，并区分 retry failed。 | Fixed |
| `IDENTITY-SPEC-AUDIT-005` | 账号删除重试请求必须写入 `AUDIT-EVENT-DELETION-RETRY`。 | 在 `AUDIT-FLOW-ACCOUNT-DELETION-RETRY-REQUESTED` 中，通过 `RISK-FLOW-ADMIN-OPS-AUTH` 且被接受进入重试处理的删除重试请求，必须写入 `AUDIT-EVENT-DELETION-RETRY`。 | Pass：引用 RISK ops auth，不重复定义 admin 认证。 | Fixed |
| `IDENTITY-SPEC-AUDIT-006` | 共享 audit log 查询必须记录 `AUDIT-EVENT-QUERY`。 | 在 `AUDIT-FLOW-ADMIN-AUDIT-QUERY` 中，通过 `RISK-FLOW-ADMIN-OPS-AUTH` 的 ops admin 审计日志列表查询必须记录 `AUDIT-EVENT-QUERY`；返回的审计详情必须来自 `AUDIT-OUT-REDACTED`，不得输出未清洗 details。 | Pass：admin 查询、query audit event 和读取 redaction 边界清楚。 | Fixed |

Spec Ref / Flow / Traceability 复审表：
| 对象 | 修复内容 | 复审结论 | 状态 |
| --- | --- | --- | --- |
| AUDIT Ref ID | `AUDIT-SENSITIVE-PATTERN` 改为封闭 key token/value pattern 集合和固定安全占位；`AUDIT-EVENT-QUERY` 收敛为 ops admin audit list query event；删除结果和重试事件 Ref ID 补清变体。 | Pass：Ref ID 不再使用开放“等”范围，事件边界清楚。 | Fixed |
| AUDIT Flow Segments | 新增 `AUDIT-FLOW-REDACT-ON-WRITE`、`AUDIT-FLOW-REDACT-SENSITIVE-CONTENT`、`AUDIT-FLOW-ACCOUNT-DELETION-RESULT`、`AUDIT-FLOW-ACCOUNT-DELETION-RETRY-REQUESTED`、`AUDIT-FLOW-ADMIN-AUDIT-QUERY`。 | Pass：覆盖写入清洗、敏感替换、删除结果、删除重试请求和 ops admin 查询。 | Fixed |
| Traceability | `IDENTITY-AUDIT-001..006` 的 `Spec Flow` 同步为 `IDENTITY-SPEC-AUDIT-001..006`；AC/TC 保持 `TBD - 后续补齐`。 | Pass：补齐 Requirement -> Spec 链路，同时未伪造 AC、TC 或测试证据。 | Fixed |

Task 12-F 执行情况：
- 已执行：修复 AUDIT requirements 六条 item。
- 已执行：修复 AUDIT spec Ref ID、flow segments 和六条 spec item。
- 已执行：同步 `traceability.md` 中 `IDENTITY-AUDIT-001..006` 的 `Spec Flow`。
- 未执行：未生成或修改 AC/TC，未修改代码，未审查 Task 13 release。

Task 12-F 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 12-F | Passed by main+independent agents | 独立 agent 已确认修复满足颗粒度/清晰度/覆盖度，并按用户更新后的门禁规则自动进入 Task 13-R。 |
| Task 13-R | Passed by main+independent agents | 独立 agent 已确认 RELEASE 边界审查方案满足颗粒度/清晰度/覆盖度，按用户更新后的门禁规则自动进入 Task 13-F。 |

### IDENTITY-RELEASE 测试替身与生产环境 release gate 13-R 逐条语义审查

审查范围：
- Requirements：`docs/product/base/identity-account-lifecycle/requirements.md` 的 `IDENTITY-RELEASE` 边界说明；当前无可归档 requirement item。
- Spec：`docs/product/base/identity-account-lifecycle/spec.md` 的 `IDENTITY-SPEC-RELEASE-000`、`RELEASE-BOUNDARY-NO-BASELINE`、`RELEASE-TARGET-PENDING`。
- 只读上下文：`/admin/release-health` 当前代码证据只返回通用 warning，未形成 identity 专属生产阻断。
- Traceability：`traceability.md` 明确当前没有 `IDENTITY-RELEASE-*` 已实现 requirement 追溯行。

本轮结果：conditional。当前“无可归档为已实现的 identity 专属 release gate 需求”和 `IDENTITY-SPEC-RELEASE-000` 的 `No accepted baseline` 方向正确，不应新增已实现 requirement、AC、TC 或 code evidence。但 requirements 的稳定 feature mapping 仍把“生产发布门禁”写入 `identity-account-lifecycle` 稳定模块候选边界，和稳定能力范围“不承载 identity 专属生产发布门禁实现”存在语义张力。13-F 应删除或收窄该候选边界，并移除 requirements 正文中的具体 API path 表述，避免把通用 release health warning 误读为 identity release gate。

Requirement 边界审查与 13-F 修复方案：
| Requirement / boundary item | 原始 Requirement / boundary 描述 | 修复后 Requirement / boundary 描述 | 结论 | 13-F Requirement 修复方案 |
| --- | --- | --- | --- | --- |
| 稳定能力范围 | 该模块不承载会员订阅、支付、学习内容、AI 练习、课程推荐、业务学习状态或 identity 专属生产发布门禁实现。 | 保持：该模块不承载 identity 专属生产发布门禁实现。 | Pass：模块非职责边界清楚。 | 不改或仅与 feature mapping 语言对齐。 |
| 稳定 Feature 映射 / `identity-account-lifecycle` | 身份认证、账号生命周期、会话、删除、风控、审计、隐私和生产发布门禁的稳定模块候选。 | 身份认证、账号生命周期、会话、删除、风控、审计和隐私的稳定模块候选；identity 专属生产发布门禁只作为未实现的下游 DevOps/Security target boundary，不纳入当前稳定能力候选。 | Important：原文把“生产发布门禁”放入稳定模块候选，和模块非职责边界冲突。 | 从 Product Base 边界中删除“生产发布门禁”，改为未实现下游边界。 |
| `IDENTITY-RELEASE` 小节标题 | `IDENTITY-RELEASE 测试替身与生产环境 release gate`。 | `IDENTITY-RELEASE 未实现生产发布边界`。 | Suggestion：原标题可能被误读为本模块已有 release gate 能力。 | 改标题为边界型小节，强调未实现。 |
| `IDENTITY-RELEASE` 边界声明 | 当前无可归档为已实现的 identity 专属 release gate 需求。 | 保持：当前无可归档为已实现的 identity 专属 release gate 需求。 | Pass：没有把 target 写成 requirement item。 | 保持。 |
| `IDENTITY-RELEASE` 未归档说明 | 当前不归档为已实现：生产环境禁用 fake OTP、生产环境禁用未校验 provider token、identity provider 配置缺失时阻断发布、identity 专属 release gate。现有 `/admin/release-health` 只是通用 warning，不是 identity 专属生产阻断。 | 当前不归档为已实现：生产环境禁用 fake OTP、生产环境禁用未校验 provider token、identity provider 配置缺失时阻断发布、identity 专属 release gate。现有通用 release health warning 只是状态提示，不是 identity 专属生产阻断。 | Important：requirements 文档写具体 API path 会混入 API contract 表述。 | 移除具体 path，保留业务/发布边界语义。 |

Spec 边界审查与 13-F 修复方案：
| Spec item / boundary | 原始 Spec 描述 | 修复后 Spec 描述 | 结论 | 13-F Spec 修复方案 |
| --- | --- | --- | --- | --- |
| `RELEASE-BOUNDARY-NO-BASELINE` | 当前没有 identity 专属已实现 release gate 可归档为 Product Base 代码基线。 | 当前没有 identity 专属已实现 release gate 可归档为 Product Base 代码基线；通用 release health warning 不构成 identity 专属生产阻断。 | Suggestion：可补充通用 warning 与专属阻断的边界。 | 补清通用 warning 不等于 release gate。 |
| `RELEASE-TARGET-PENDING` | 生产禁用 fake OTP、禁用未校验 provider token、identity provider 配置阻断和 identity 专属 release gate 均仍为未实现目标。 | 保持：生产禁用 fake OTP、禁用未校验 provider token、identity provider 配置阻断和 identity 专属 release gate 均仍为未实现目标。 | Pass：未把目标态写成已实现。 | 保持。 |
| `IDENTITY-SPEC-RELEASE-000` | 在 `RELEASE-BOUNDARY-NO-BASELINE` 下，本规格不得把 `RELEASE-TARGET-PENDING` 写成已实现行为；后续只有形成独立 requirement、spec、AC、TC、实现和 release evidence 后，才能新增 identity release gate spec item。 | 在 `RELEASE-BOUNDARY-NO-BASELINE` 下，本规格不得把 `RELEASE-TARGET-PENDING` 写成已实现行为；当前通用 release health warning 不得作为 identity 专属 release gate code evidence；后续只有形成独立 requirement、spec、AC、TC、实现和 release evidence 后，才能新增 identity release gate spec item。 | Important：Spec 可再明确当前通用 warning 不得作为 code evidence。 | 补充不得把通用 warning 当作 identity release gate 证据。 |
| 模块影响 / Architecture / Security | opaque token、provider boundary、OTP security、audit redaction、admin bearer、release gate。 | opaque token、provider boundary、OTP security、audit redaction、admin bearer，以及未实现的 identity release gate target boundary。 | Suggestion：下游影响中 release gate 应标为 target boundary。 | 收窄为 target boundary。 |
| 模块影响 / DevOps / Release | 生产 HTTPS、OTP provider 禁用测试替身、identity 专属 release gate。 | 生产 HTTPS、OTP provider 禁用测试替身，以及未实现的 identity 专属 release gate target boundary。 | Suggestion：避免把 release gate 当作当前已实现职责。 | 收窄为未实现 target boundary。 |
| 必需下游契约 / Architecture-Security / DevOps | 定义 release gate 关系；目标态 OTP 和 identity provider 进入生产前，需要 release health 阻断等。 | 明确这些均为目标态下游 DevOps/Security 输出，不是当前 `Code baseline` 或 `No accepted baseline` 的实现证据。 | Suggestion：下游契约应避免误导 Product Base merge。 | 在相关下游契约文字中加入目标态/未实现边界。 |

跨文档发现与 13-F 修复方案：
| 对象 | 问题 | 影响 | 级别 | 13-F 修复方案 |
| --- | --- | --- | --- | --- |
| Requirements feature mapping | `identity-account-lifecycle` Product Base 边界仍包含“生产发布门禁”。 | 与稳定能力范围“不承载 identity 专属生产发布门禁实现”冲突。 | Important | 删除“生产发布门禁”，改为未实现下游 target boundary。 |
| Requirements API path | Release 边界说明写入 `/admin/release-health` 具体 path。 | Requirements 混入 API contract 表述。 | Important | 改成“通用 release health warning”。 |
| Spec release evidence boundary | `IDENTITY-SPEC-RELEASE-000` 未明确通用 warning 不可作为 identity release gate code evidence。 | 后续 traceability/AC 可能误把 warning 当成实现证据。 | Important | 在 boundary spec 中补充该禁止解释。 |
| Traceability | 当前没有 `IDENTITY-RELEASE-*` 追溯行。 | 与“无已实现 requirement item”一致。 | Pass | 13-F 不新增 release requirement traceability 行；仅保持边界说明。 |

Task 13-R 执行情况：
- 已执行：完成 `IDENTITY-RELEASE` 无已实现 requirement 边界和 `IDENTITY-SPEC-RELEASE-000` 的内容契约语义审查。
- 已执行：按 Requirement boundary / Spec boundary 分离格式形成 13-F 修复输入表，并在 item 后附原始描述与修复后描述。
- 13-R 阶段未执行：未修改 `requirements.md`、`spec.md` 或 `traceability.md` 正文；等待独立 agent 复核通过后再执行 Task 13-F。
- 未执行：未生成或修改 AC/TC，未修改代码，未新增 release requirement traceability 行。

Task 13-R 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 13-R | Passed by main+independent agents | 独立 agent 已确认本审查表满足颗粒度/清晰度/覆盖度，并按用户更新后的门禁规则自动进入 Task 13-F。 |
| Task 13-F | Passed by main+independent agents | 独立 agent 已确认 RELEASE 边界修复满足颗粒度/清晰度/覆盖度，本轮任务完成。 |

### IDENTITY-RELEASE 未实现生产发布边界 13-F 修复复审

修复范围：
- Requirements：修复稳定 Feature 映射中的 release gate 边界，重命名 `IDENTITY-RELEASE` 小节，并移除 requirements 正文中的具体 API path 表述。
- Spec：修复 release Ref ID、`IDENTITY-SPEC-RELEASE-000`、模块影响和必需下游契约中的 release gate target boundary 表述。
- Traceability：保持当前没有 `IDENTITY-RELEASE-*` 已实现 requirement 追溯行；本轮未新增 release requirement、AC、TC 或 code evidence。
- 独立审查：Task 13-R 审查方案已由独立 agent 判定通过，可进入 Task 13-F。

Requirement 边界修复复审表：
| Requirement / boundary item | 修复前 Requirement / boundary 描述 | 修复后 Requirement / boundary 描述 | 复审结论 | 状态 |
| --- | --- | --- | --- | --- |
| 稳定能力范围 | 该模块不承载会员订阅、支付、学习内容、AI 练习、课程推荐、业务学习状态或 identity 专属生产发布门禁实现。 | 未修改；继续声明该模块不承载 identity 专属生产发布门禁实现。 | Pass：非职责边界保持稳定。 | Fixed |
| 稳定 Feature 映射 / `identity-account-lifecycle` | 身份认证、账号生命周期、会话、删除、风控、审计、隐私和生产发布门禁的稳定模块候选。 | 身份认证、账号生命周期、会话、删除、风控、审计和隐私的稳定模块候选；identity 专属生产发布门禁只作为未实现的下游 DevOps/Security target boundary，不纳入当前稳定能力候选。 | Pass：消除了 feature mapping 与模块非职责边界的冲突。 | Fixed |
| `IDENTITY-RELEASE` 小节标题 | `IDENTITY-RELEASE 测试替身与生产环境 release gate`。 | `IDENTITY-RELEASE 未实现生产发布边界`。 | Pass：标题不再暗示本模块已有 release gate 能力。 | Fixed |
| `IDENTITY-RELEASE` 边界声明 | 当前无可归档为已实现的 identity 专属 release gate 需求。 | 当前无可归档为已实现的 identity 专属 release gate 需求。 | Pass：仍未新增 requirement item。 | Fixed |
| `IDENTITY-RELEASE` 未归档说明 | 当前不归档为已实现：生产环境禁用 fake OTP、生产环境禁用未校验 provider token、identity provider 配置缺失时阻断发布、identity 专属 release gate。现有 `/admin/release-health` 只是通用 warning，不是 identity 专属生产阻断。 | 当前不归档为已实现：生产环境禁用 fake OTP、生产环境禁用未校验 provider token、identity provider 配置缺失时阻断发布、identity 专属 release gate。现有通用 release health warning 只是状态提示，不是 identity 专属生产阻断。 | Pass：移除 API path，保留 release 边界语义。 | Fixed |

Spec 边界修复复审表：
| Spec item / boundary | 修复前 Spec 描述 | 修复后 Spec 描述 | 复审结论 | 状态 |
| --- | --- | --- | --- | --- |
| `RELEASE-BOUNDARY-NO-BASELINE` | 当前没有 identity 专属已实现 release gate 可归档为 Product Base 代码基线。 | 当前没有 identity 专属已实现 release gate 可归档为 Product Base 代码基线；通用 release health warning 不构成 identity 专属生产阻断。 | Pass：通用 warning 与专属阻断边界清楚。 | Fixed |
| `RELEASE-TARGET-PENDING` | 生产禁用 fake OTP、禁用未校验 provider token、identity provider 配置阻断和 identity 专属 release gate 均仍为未实现目标。 | 未修改；仍明确上述能力均为未实现目标。 | Pass：未把目标态写成已实现。 | Fixed |
| `IDENTITY-SPEC-RELEASE-000` | 在 `RELEASE-BOUNDARY-NO-BASELINE` 下，本规格不得把 `RELEASE-TARGET-PENDING` 写成已实现行为；后续只有形成独立 requirement、spec、AC、TC、实现和 release evidence 后，才能新增 identity release gate spec item。 | 在 `RELEASE-BOUNDARY-NO-BASELINE` 下，本规格不得把 `RELEASE-TARGET-PENDING` 写成已实现行为；当前通用 release health warning 不得作为 identity 专属 release gate code evidence；后续只有形成独立 requirement、spec、AC、TC、实现和 release evidence 后，才能新增 identity release gate spec item。 | Pass：明确通用 warning 不可作为 release gate 代码证据。 | Fixed |
| 模块影响 / Architecture / Security | opaque token、provider boundary、OTP security、audit redaction、admin bearer、release gate。 | opaque token、provider boundary、OTP security、audit redaction、admin bearer，以及未实现的 identity release gate target boundary。 | Pass：release gate 被标为未实现 target boundary。 | Fixed |
| 模块影响 / DevOps / Release | 生产 HTTPS、OTP provider 禁用测试替身、identity 专属 release gate。 | 生产 HTTPS、OTP provider 禁用测试替身，以及未实现的 identity 专属 release gate target boundary。 | Pass：DevOps release gate 仍是下游 target，不是当前 code baseline。 | Fixed |
| 必需下游契约 / Architecture-Security / DevOps | 定义 release gate 关系；目标态 OTP 和 identity provider 进入生产前，需要 release health 阻断等。 | Architecture/Security 改为未实现 release gate target boundary 关系；DevOps 改为目标态 release health 阻断，且明确这些是下游 DevOps target boundary，不是当前 identity code baseline。 | Pass：下游契约不再误导为当前已实现证据。 | Fixed |

Traceability / Release Boundary 复审表：
| 对象 | 修复内容 | 复审结论 | 状态 |
| --- | --- | --- | --- |
| Traceability | 保持 `IDENTITY-RELEASE` 当前没有 `IDENTITY-RELEASE-*` 已实现 requirement 追溯行。 | Pass：与无已实现 requirement item 一致。 | Fixed |
| AC / TC / Code evidence | 未生成 AC/TC，未新增 code evidence，未修改代码。 | Pass：没有把 release target boundary 伪装成已实现能力。 | Fixed |

Task 13-F 执行情况：
- 已执行：修复 requirements 中 feature mapping、release 小节标题和 release 边界说明。
- 已执行：修复 spec 中 release Ref ID、`IDENTITY-SPEC-RELEASE-000`、模块影响和下游契约表述。
- 未执行：未新增 release requirement item，未新增 traceability 行，未生成或修改 AC/TC，未修改代码。

Task 13-F 门禁状态：
| Gate | 状态 | 下一步限制 |
| --- | --- | --- |
| Task 13-F | Passed by main+independent agents | 独立 agent 已确认修复满足颗粒度/清晰度/覆盖度，本轮 Product Base identity 内容契约审查/修复任务完成。 |

## 2026-06-11 SWC 架构治理上线独立审核

审核 ID：`SWC-ARCH-GOVERNANCE-ROLLOUT-20260611`

结果：process-governance rollout 在独立 blocker 修复复查后通过。初次独立审核因 SWC catalog 字段完整性、Product Manager 路由和持久状态一致性阻塞完整验收。后续修复扩展了 catalog，更新了 Product Manager 路由，并对齐状态。本审核不批准任何 product feature、Product Base merge、release readiness、backend implementation、Flutter implementation 或外部 evidence。

已检查 artifact：
- `docs/process/workflow.md`
- `docs/process/definition_of_done.md`
- `docs/process/software_component_architecture_governance.md`
- `docs/process/skill_quality_standard.md`
- `docs/architecture/swc_catalog.md`
- `codex/agents/system_architect.md`
- `codex/agents/product_manager.md`
- `codex/agents/development_orchestrator.md`
- `codex/agents/software_architecture_governance_check.md`
- `codex/agents/product_object_governance_check.md`
- `.agents/skills/document-path-governance/SKILL.md`
- `.agents/skills/document-content-contract/SKILL.md`
- `.agents/skills/document-traceability-check/SKILL.md`

发现：
- Workflow placement 未发现 blocker。SWC allocation 现在位于 architecture/domain/API/screen/AI spec 和 AC-to-TC mapping 之后，implementation planning 和 code 之前。
- 初始 blocker 已修复：`swc_catalog.md` 现在包含必需 catalog 字段，包括 layer、owning agent、provided/required interface、owned data/DB/migration、called API/provider boundary、test ownership、reuse/forbidden bypass 和 status。
- 初始 blocker 已修复：Product Manager architecture intake 现在把 SWC 或 implementation-impacting architecture 路由到 Software Architecture Governance Check；Product Object Governance Check 继续作为 workflow/source-of-truth/agent/skill 变更的 meta-governance checker。
- 初始 blocker 已修复：`docs/process/software_component_architecture_governance.md` 和本报告现在记录已修正的 follow-up 状态，不再出现 pending/pass 冲突表述。
- 修正后 content boundary 未发现 blocker。`swc_catalog.md` 拥有 stable component inventory；per-increment `swc_allocation.md` 拥有 FR/AC-to-SWC allocation；两者都不替代 Domain Schema、OpenAPI、AI runtime、UX、test case 或 release gate。
- 修正后 agent responsibility separation 未发现 blocker。System Architect 产出 SWC artifact；Development Orchestrator 执行 gate；Software Architecture Governance Check 独立审核 SWC readiness；Product Object Governance Check 仍是 workflow/source-of-truth/agent/skill 变更的 meta-governance checker。
- Stable output 未发现 blocker。Implementation-impacting increment 现在要求 `docs/product/increments/<increment-id>/swc_allocation.md`，或明确已接受的 `N/A - no SWC impact` decision。

验证：
- `python3 scripts/project_agent_runner.py validate`：passed。
- `python3 scripts/validate_agent_skills.py`：passed。
- `git diff --check`：passed。

残余风险：
- 既有历史 increment 并非全部已有 `swc_allocation.md`；本 rollout 前向生效，active increment 下次被触碰且开始新 implementation 前必须补齐 SWC allocation。
- 后续仍可增加 automation，进一步强制 SWC allocation presence。

## 2026-06-10 P0 Commercial Admin Data Deletion Retry Independent Review

Review ID: `P0-COM-ADMIN-DATA-DELETION-RETRY-20260610`

Result: pass after transaction-boundary and report-chain follow-up. No blocker or P1 remains for the scoped `POST /admin/data-deletion/{job_id}/retry` local backend/API/contract/test closure. P0 commercial release remains blocked by external/native/store/release evidence gates.

Independent agents:
- `Beauvoir` reviewed the first implementation in read-only mode and failed it on a real AI retention rollback risk plus report-chain gaps.
- `Planck` reviewed the corrected implementation in read-only mode and passed runtime, contract and test traceability, with only P2 report status corrections required.

Findings:
- Blocker found and fixed: the first implementation called transactional `AiRetentionService#runAccountDeletion` inside the deletion retry transaction, so a real AI retention exception could mark the outer transaction rollback-only and prevent failed deletion job/retry/audit persistence.
- No blocker remains after adding `AccountDeletionRetentionRunner` with `REQUIRES_NEW` around the existing `AiRetentionService` call; the outer `AccountDeletionService` transaction now persists `AccountDeletionJob failed`, `AccountDeletionRetryIdempotency failed` and `account_deletion_retry_failed` audit on real retention failure.
- No blocker remains for failure coverage. `AdminDataDeletionRetryFailureTest` no longer mocks `AiRetentionService`; it uses the real service path with a test `AiMediaStorageService` failure and verifies job, retry idempotency and audit persistence.
- P2 found and fixed: `api_contract.md` previously over-promised that all retry attempts are audited while duplicate/completed no-op requests intentionally do not create new retry side effects. The contract now says new retry executions are audited, matching implementation and tests.
- P2 found and fixed: `development_status.md` and this quality report lagged behind TC-COM-025. Development status now includes TC-COM-025, and this section records the independent review and closure.
- No blocker found for OPS-only access, OpenAPI/backend/generated-client alignment, failed-only execution, completed no-op, in-progress `DELETE_IN_PROGRESS`, duplicate `Idempotency-Key` replay, redacted audit details or architecture reuse.
- No blocker found for bidirectional traceability. TC-COM-025 links COM-SI-006/011 -> FR-COM-008/011 -> COM-SPEC-006/011 -> AC-COM-010/013 -> COM-TR-006/011 -> backend/OpenAPI/tests/reports.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminDataDeletionRetryFailureTest test` - passed with real `AiRetentionService` failure path.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminDataDeletionControllerTest,AdminDataDeletionRetryFailureTest,AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,CommercialAccountDeletionProcessorTest,AiAccountDeletionMediaCleanupTest,AiRetentionPolicyTest,AdminAuditControllerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CommercialAbuseControlTest test` - passed after deterministic provider isolation.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProviderGatewaySecurityContractTest test` - passed after deterministic provider isolation.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `npm run check:api-contract` - passed with OpenAPI hash `464464b9346a28422831e56e8f5ba42118ebb0a6005d981e4381bee52fce4e30`.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --base-ref HEAD --include-worktree` - passed for 32 changed files.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- Fixed before close: AI retention failures are isolated through `AccountDeletionRetentionRunner` and covered by a real-service integration test.
- Fixed before close: retry audit contract language now matches duplicate/completed no-op behavior.
- Fixed before close: `development_status.md` and this quality report now include TC-COM-025 closure evidence.

Residual risk:
- This review accepts the local admin data deletion retry endpoint closure only. It does not close TC-COM-012/015/019/021/022 external/native/store/release gates.
- Retry still executes synchronously in the backend process. Production queueing, alerting, WORM/SIEM audit retention and external privacy deletion evidence remain ops/release scope.

## 2026-06-10 P0 Commercial Admin Audit Endpoint Independent Review

Review ID: `P0-COM-ADMIN-AUDIT-ENDPOINT-20260610`

Result: pass after documentation follow-up. No blocker or P1 remains for the scoped `GET /admin/audit` local backend/API/contract/test closure. P0 commercial release remains blocked by external/native/store/release evidence gates.

Independent agent:
- `Hilbert` reviewed the current workspace changes in read-only mode against commercial product design, software architecture design, reuse/no-duplicate-build requirements and full bidirectional traceability.

Findings:
- P2 found and fixed: repo-level report traceability was not fully closed because `traceability.md` still said Implementation Report and Test Report “需更新”, and `quality_report.md` had no 2026-06-10 independent review section. This section plus the updated downstream evidence rows in `docs/product/increments/commercial-subscription-readiness/traceability.md` close that report-chain gap.
- No blocker or P1 found for backend runtime behavior.
- No blocker found for OPS-only access. `/admin/**` reuses the existing OPS security boundary, and TC-COM-024 covers unauthenticated 401 plus non-OPS 403.
- No blocker found for pagination/filtering. `AuditLogService` uses bounded page size, opaque keyset cursor and exact `event_type`, `actor_type`, `target_ref`, `created_after` and `created_before` filters.
- No blocker found for sensitive data handling. Response projection omits `actor_id`; JSON and legacy `redacted_details` paths are sanitized for token, signature, URL, raw payload and transcript-like data.
- No blocker found for self-audit. Successful audit reads write `admin_audit_events_listed` with redacted metadata.
- No blocker found for OpenAPI/backend/generated-client alignment. The endpoint parameters, errors, schema, examples and generated Dart hash pin are synchronized.
- No blocker found for architecture reuse. The implementation reuses `AuditLog`, `AuditLogRepository`, existing admin OPS auth, `SchemaResponse`, Flyway, OpenAPI and generated-client drift gates; it does not create a duplicate audit store or admin auth stack.
- No blocker found for FR/AC/TC/report traceability after the P2 documentation correction. TC-COM-024 now links COM-SI-011/012 -> FR-COM-011/012 -> COM-SPEC-011/012 -> AC-COM-013/014 -> COM-TR-011/012 -> backend/OpenAPI/tests/reports.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminAuditControllerTest test` - passed.
- `npm run check:api-contract` - passed.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `defb6aad8bbf84fe39aa3c2982137c7560145ae63d729d30d9d02b9aa70e5a4d`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminAuditControllerTest,CommercialFoundationControllerTest,AiProviderEvidenceControllerTest,AiCostDashboardTest,AiRetentionPolicyTest,AccountDeletionFailureAuditTest test` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --base-ref HEAD --include-worktree` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.

Required corrections:
- Fixed before close: `traceability.md` downstream evidence now marks Implementation Report, Test Report and Quality Report updated for the 2026-06-10 admin audit closure.
- Fixed before close: this `quality_report.md` section records the independent review, finding, correction and final pass result.

Residual risk:
- This review accepts the local admin audit endpoint closure only. It does not close TC-COM-012/015/019/021/022 external/native/store/release gates.
- The endpoint provides local persisted audit event query, not SIEM export, immutable WORM storage, external audit warehouse sync or production incident evidence.

## 2026-06-09 P02 Followup-B XCB-003 Reminder Eligibility Endpoint Independent Review

Review ID: `P02-FOLLOWUP-B-XCB-003-REMINDER-ELIGIBILITY-ENDPOINT-20260609`

Result: pass for the scoped XCB-003 endpoint closure after independent review follow-up. No blocker remains for `POST /goal-autopilot/reminders/eligibility` local controller/service/OpenAPI/generated-client/TC traceability closure. Followup-B remains not release-ready and Product Base merge is not approved.

Findings:
- Independent Review initially found a P1 recovery-required eligibility gap: recovery-required daily plans could still evaluate a pending reminder as eligible before recovery replan. The gap is closed by mapping `PlanFacts.recoveryRequired()` into the existing `stale_plan` reminder block and adding `GoalAutopilotControllerTest#tcP02Fub018ReminderEligibilityRecoveryRequiredDoesNotReturnEligible`.
- Independent Review initially found a P2 malformed `current_time` contract gap: controller-level `Instant` binding could return JSON binding `400` rather than endpoint-contract `422`. The gap is closed by accepting `current_time` as a string DTO field and parsing it in `GoalAutopilotService`, with malformed input returning `SCHEMA_VALIDATION_FAILED` 422.
- No blocker found for endpoint implementation after correction. `GoalAutopilotController#evaluateReminderEligibility` exists and routes to `GoalAutopilotService#evaluateReminderEligibility`.
- No blocker found for runtime gate. The service calls `requireMutationAllowed(userId, "reminder_eligibility", requestId)` before eligibility evaluation and runtime-disabled regression returns audit-backed 503.
- No blocker found for commercial gates. Entitlement, quota and cost downgrade facts are integrated and mapped to `entitlement_blocked` or `quota_exhausted`, rather than hardcoded success.
- No blocker found for outbox boundary. TC-P02-FUB-018 verifies successful eligibility evaluations write low-sensitivity `notification_eligibility` metrics and do not create `goal_notification_outbox_records`.
- No blocker found for XCB-003 contract alignment. OpenAPI lint/contract and Dart generated drift pass with hash `ae03bd46812ddd684bb70fbcb3f927b759c1e70529d1bdd68c0ada18a1aff587`; endpoint `404`, UUID schemas/examples and generated pins are synchronized.
- No blocker found for traceability. TC-P02-FUB-018 is linked through P02-SI-010 -> P02-FUB-WP-003/004 -> P02-FUB-FR-003/004 -> P02-FUB-SPEC-003/004 -> AC-P02-FUB-003/004 -> P02-FUB-TR-003/004 -> code/tests/reports/checker.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub018ReminderEligibilityEndpointEvaluatesRequestBoundary+tcP02Fub018ReminderEligibilityCommercialAndPlanOwnershipGates+tcP02Fub018ReminderEligibilityMissingPlanDoesNotReturnEligibleWithoutItem+tcP02Fub018ReminderEligibilityRecoveryRequiredDoesNotReturnEligible,GoalAutopilotRuntimeGateTest#tcP02Fud002KillSwitchHidesExistingProjectionAndFailsClosed test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,GoalAutopilotRuntimeGateTest,NotificationEligibilityPolicyTest,GoalAutopilotQuotaDowngradeTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `npm run check:api-contract` - passed without OpenAPI warnings.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `ae03bd46812ddd684bb70fbcb3f927b759c1e70529d1bdd68c0ada18a1aff587`.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --base-ref HEAD --include-worktree` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 95.7%, backend branch 81.1% and Flutter line 89.2%.
- `python3 -m py_compile scripts/check_p0_2_followup_b_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_b_traceability.py` - passed after report synchronization.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- Fixed before close: recovery-required eligibility now blocks as `stale_plan` and is covered by TC-P02-FUB-018.
- Fixed before close: malformed `current_time` now returns 422 and is covered by TC-P02-FUB-018.

Residual risk:
- Full all-suite backend/Flutter regression, live notification provider delivery, external production scheduler/send evidence, commercial release readiness and Product Base merge approval were not run.
- The endpoint is a mutation-gated precheck and may create the server-owned control fact through existing `ensureControl`; it remains prohibited from creating outbox, completion, failure, refusal or missed-day evidence.

## 2026-06-09 MVP Practice Audio Ref Boundary Independent Review

Review ID: `MVP-PRACTICE-AUDIO-REF-BOUNDARY-20260609`

Result: pass for the scoped Practice trusted `audio_ref` boundary fix after independent review follow-up. No local blocker remains for XCB-001/XCB-002 compliance on Practice turn input after TC-MVP-BE-047, TC-MVP-BE-048 and API contract gates passed.

Findings:
- Independent review initially found a P1 XCB-001 ownership gap: `media://audio/{id}` validation checked stored asset status but not `AiMediaAsset.userId`. The gap is closed by owner-aware `AiMediaReferenceService` inspection and TC-MVP-BE-048.
- No blocker remains for XCB-001 ownership. `PracticeService.submitTurn` now validates any provided `audio_ref` as an authenticated-user-owned backend media ref through `AiGatewayService.validateTrustedAudioRef` before persistence, coach feedback or provider invocation.
- No blocker found for XCB-002 routing. Practice still routes ASR and coach through `AiGatewayService`; business code does not call `AiProviderGateway` directly.
- No blocker found for API contract alignment. Client-facing audio-ref request schemas now use trusted `media://audio/{uuid}` refs, examples no longer use `sample`, and generated Dart drift pins OpenAPI hash `7e603dd0bec9879ee2d21516e86fb84e2e652102f677506a59255544befa76f5`.
- No blocker found for TC traceability. TC-MVP-BE-047 and TC-MVP-BE-048 are present in the Practice test case library and MVP-BE-TR-008 with script path, command, result and report evidence.
- No blocker found for regression evidence. The negative tests reject transcript + `/tmp/local-answer.wav` and wrong-owner validated `media://audio/...`, verify no turn/feedback persistence, and verify no provider invocation.
- No blocker found for provider fallback compatibility. The stale `audio://provider_unavailable` test fixture was replaced with a validated trusted media ref plus test provider fallback, preserving recoverable ASR-unavailable behavior without weakening XCB-001.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PracticeTurnControllerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProductionAsrMediaRefTest,MediaUploadReferenceServiceTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=TrainingMediaAiPipelineTest test` - passed.
- `flutter test test/features/training/training_backend_pipeline_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,ProviderGatewayAuthorizationTest,UsageQuotaGateTest test` - passed after stale fixture correction.
- `npm run check:api-contract` - passed with OpenAPI hash `7e603dd0bec9879ee2d21516e86fb84e2e652102f677506a59255544befa76f5`.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `7e603dd0bec9879ee2d21516e86fb84e2e652102f677506a59255544befa76f5`.
- `python3 scripts/check_cross_cutting_boundaries.py --scope full` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --base-ref HEAD --include-worktree` - passed.
- `python3 -m py_compile scripts/check_cross_cutting_boundaries.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Residual risk:
- Full all-suite backend/Flutter regression, live provider, external object-storage and release-readiness suites were not run in this scoped boundary validation.
- This review does not approve Product Base merge, release readiness or new audio upload UI behavior.

## 2026-06-07 P02 Followup-E Docs-Only Planning Reclassification Review

Review ID: N/A - implementation review not accepted

Report ID: N/A - implementation evidence reclassified to planned

Result: planning/contract status only. This review boundary does not approve backend implementation, Flutter implementation, OpenAPI/generated client sync, AI runtime, native mic/audio bytes upload, retention/export/account deletion, entitlement/provider downgrade, release readiness, paid AI external evidence or Product Base merge.

Findings:
- Followup-E Phase 0-3 documents can remain as planning/contract evidence.
- All TC-P02-FUE-000..026 must remain planned until an implementation slice is intentionally executed.
- Previous backend/Flutter slice review IDs are not accepted as current Followup-E implementation evidence in this docs-only state.
- MVP/P0.1 mic/recording functionality remains existing baseline capability; Followup-E should reuse that boundary and add Speaking Check orchestration plus trusted upload bridging rather than duplicate mic development.
- Release, paid AI external evidence and Product Base merge blockers remain open.

Validation:
- No backend, Flutter, OpenAPI, generated-client, AI runtime or release validation is claimed here.
- Independent implementation review remains required after any future executable Followup-E slice.

Required corrections:
- Reclassify docs that claimed Followup-E backend/Flutter implementation evidence as planning/contract evidence.

Residual risk:
- Local uncommitted Followup-E code may still exist in the working tree, but it is not accepted quality evidence here.
- Any future implementation evidence must be re-reviewed from the planned TC/traceability baseline.

## 2026-06-07 P02 Followup-C S007 Checker Hash Sync Independent Review

Review ID: `P02-FOLLOWUP-C-S007-CHECKER-HASH-SYNC-20260607`

Result: pass for local checker-regression fix after the Followup-C S007 traceability checker was changed to validate the current OpenAPI/generated Dart hash from active artifacts while preserving historical S007 nullable-cleanup report evidence. No local blocker remains. This Independent Review does not approve release readiness, external production evidence or Product Base merge.

Findings:
- No blocker found for source-of-truth alignment. `scripts/check_p0_2_followup_c_traceability.py` now reads `openapi_sha256` from `docs/architecture/openapi/dart-client-drift-manifest.json`, compares it with `lib/generated/api/.openapi-sha256`, and verifies the same hash is present in `lib/generated/api/speakeasy_api.dart`.
- No blocker found for historical evidence preservation. The original S007 nullable-cleanup hash remains required in report/status evidence as `S007_HISTORICAL_OPENAPI_SHA`, so the checker still proves the historical cleanup record exists without pinning current generated artifacts to an obsolete hash.
- No blocker found for runtime/API safety. The fix changed only the checker and report/status evidence; no production backend, Flutter, OpenAPI or generated Dart API shape changed.
- No blocker found for deterministic validation. Python compile, Followup-C checker, P0.2 coverage, API contract, Dart client drift, A/B/D upstream-downstream traceability, project agent runner and diff checks passed.
- No release/Product Base blocker was closed. Followup-C and Followup-D release readiness plus Product Base merge approval remain outside this local checker fix.

Validation:
- `python3 -m py_compile scripts/check_p0_2_followup_c_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_c_traceability.py` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 95.7%, backend branch 81.1% and Flutter line 90.9%.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.
- `npm run check:api-contract` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_b_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_d_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_d_final_review.py` - passed with release/Product Base blockers preserved.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- Fixed before close: the checker previously required the historical S007 hash in current generated artifacts, which failed after later valid Followup-D OpenAPI/generated-client updates. Current generated artifacts are now validated dynamically.
- None remain for the scoped checker-regression fix after validation and report synchronization.

Residual risk:
- No local blocker remains for the scoped checker-regression fix after report synchronization and final validation.
- This change does not execute live provider, store, payment, native social login, release-readiness or Product Base merge evidence.

## 2026-06-07 P02 Followup-D S011 Final Review Independent Review

Review ID: `P02-FOLLOWUP-D-S011-FINAL-REVIEW-20260607`

Result: pass for local S011 final review execution after TC-P02-FUD-020 and TC-P02-FUD-021 evidence, final-review checker validation, report synchronization, release checklist blocker preservation and Product engineer/software engineer review passed. No local S011 blocker remains. This Independent Review does not approve release readiness, paid AI external evidence, native/store/payment evidence or Product Base merge.

Findings:
- Product engineer review: no blocker found for product scope. S011 reviews Followup-D release-gate evidence only and does not expand A/B/C functional scope, Product Base scope or commercial claims.
- Product engineer review: no blocker found for state separation. Product Base merge state, commercial release state and paid AI external evidence state are separately recorded, and Followup-D is not release-ready plus Product Base merge is not approved remain explicit.
- Product engineer review: blocking finding for release/Product Base approval remains outside local S011: commercial release external evidence, paid AI external evidence, native social login evidence and PM/release governance approval are still required.
- Software engineer review: no blocker found for final-review checker coverage. `scripts/check_p0_2_followup_d_final_review.py` validates TC-P02-FUD-020/021 rows, P02-FUD-TR-011, report IDs, release checklist blockers, rollback command coverage and forbidden release/Product Base claims.
- Software engineer review: no blocker found for contract/runtime risk. S011 changes docs and deterministic checkers only; no production backend, Flutter or API shape changed, while API contract and generated Dart drift checks passed.
- Software engineer review: no blocker found for strict blocker preservation. `scripts/check_release_readiness.sh --env-only` passed with fixture evidence variables, while strict release readiness failed as expected on iOS WeChat placeholder URL scheme and missing Sign in with Apple entitlement.
- No local S011 blocker found for test/report synchronization. Test, implementation, quality, traceability, development status and release reports all reference `P02-FOLLOWUP-D-S011-FINAL-REVIEW-20260607`.

Validation:
- `python3 -m py_compile scripts/check_p0_2_followup_d_final_review.py scripts/check_p0_2_followup_d_traceability.py` - passed.
- `npm run check:api-contract` - passed.
- `npm run check:dart-client-drift` - passed.
- `bash -n scripts/check_release_readiness.sh` - passed.
- `scripts/check_release_readiness.sh --env-only` with fixture production/evidence variables - passed.
- Strict `scripts/check_release_readiness.sh` with the same fixture variables - strict release readiness failed as expected with status 1.
- `python3 scripts/check_p0_2_followup_d_traceability.py` - passed after report synchronization.
- `python3 scripts/check_p0_2_followup_d_final_review.py` - passed after report synchronization.
- `python3 scripts/project_agent_runner.py validate` - passed after report synchronization.
- `git diff --check` - passed after report synchronization.

Required corrections:
- Fixed before close: P02-FUD-S011 traceability routing row briefly had a column mismatch during update; the row now has the correct S011 WP/FR/Spec/AC/TC/trace columns and final review status.
- None remain for local S011 final review after validation and report synchronization.

Residual risk:
- Commercial release external evidence remains blocked.
- Paid AI external evidence remains blocked.
- Native social login evidence remains blocked until the placeholder WeChat URL scheme and Apple Sign In entitlement are corrected.
- Followup-D is not release-ready and Product Base merge is not approved.

## 2026-06-07 P02 Followup-D S010 Drift Gates Independent Review

Review ID: `P02-FOLLOWUP-D-S010-DRIFT-GATES-20260607`

Result: pass for local S010 drift gates after TC-P02-FUD-018 and TC-P02-FUD-019 evidence, dedicated checker validation, OpenAPI/generated Dart drift gates, release checklist/rollback synchronization and report synchronization passed. At S010 close, this Independent Review did not approve the then-open S011 final Product Base/release review, release readiness, paid AI external evidence, native/store/payment evidence or Product Base merge.

Findings:
- No blocker found for traceability closure. `scripts/check_p0_2_followup_d_traceability.py` validates required Followup-D docs, TC-P02-FUD-018/019 rows, P02-FUD-TR-010 closure terms, report IDs, release docs and development status evidence.
- No blocker found for contract drift. `npm run check:api-contract` and `npm run check:dart-client-drift` passed with generated Dart hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`; no production backend, Flutter or API shape changed.
- No blocker found for release-doc synchronization. `release_checklist.md` and `rollback_plan.md` now preserve local S001-S010 passed state, S011 blocker state, rollout rollback controls, `goal_autopilot_metric_events` audit/data preservation and no-release-approval boundaries.
- No blocker found for strict blocker preservation. `scripts/check_release_readiness.sh --env-only` passed with fixture evidence variables, while strict release readiness failed as expected on iOS WeChat placeholder URL scheme and missing Sign in with Apple entitlement.
- No blocker found for claim safety. The S010 checker blocks forbidden Followup-D release/completion claims and the reports keep `Followup-D is not release-ready` plus `Product Base merge is not approved`.
- No blocker found for test/report synchronization. Test, implementation, quality, traceability and development status reports all reference `P02-FOLLOWUP-D-S010-DRIFT-GATES-20260607` and keep S011 open.

Validation:
- `python3 -m py_compile scripts/check_p0_2_followup_d_traceability.py` - passed.
- `npm run check:api-contract` - passed.
- `npm run check:dart-client-drift` - passed.
- `bash -n scripts/check_release_readiness.sh` - passed.
- `scripts/check_release_readiness.sh --env-only` with fixture production/evidence variables - passed.
- Strict `scripts/check_release_readiness.sh` with the same fixture variables - strict release readiness failed as expected with status 1.
- `python3 scripts/check_p0_2_followup_d_traceability.py` - passed after report synchronization.
- `python3 scripts/project_agent_runner.py validate` - passed after report synchronization.
- `git diff --check` - passed after report synchronization.

Required corrections:
- Fixed before close: the strict release readiness assertion wrapper initially used zsh's read-only `status` variable and did not validate the release script. The wrapper was rerun with `release_status`, and the expected native social-login blocker was confirmed.
- None remain for local S010 drift gates after validation and report synchronization.

Residual risk:
- At S010 close, S011 final Product Base/release review remained open; current S011 evidence is recorded above.
- Live paid AI provider, payment provider, store submission and native social login evidence remain outside S010.
- Followup-D is not release-ready and Product Base merge is not approved.

## 2026-06-07 P02 Followup-D S009 Telemetry Independent Review

Review ID: `P02-FOLLOWUP-D-S009-TELEMETRY-20260607`

Result: pass for local S009 telemetry after redacted metric persistence, required funnel/error/blocked event coverage, telemetry write-failure fallback, data-governance export/deletion cleanup, migration validation, backend regression, changed-code coverage and report synchronization passed. At S009 close, this review did not approve the then-open S010/S011 drift/release gates, release readiness, paid AI external evidence or Product Base merge.

Findings:
- No blocker found for telemetry minimization. `goal_autopilot_metric_events` stores redacted user hash, event/status/reason/source and safe refs only; migration/entity/service checks block raw transcript, audio ref, provider payload, prompt, raw user id, idempotency key and notification payload persistence.
- No blocker found for event coverage. `GoalAutopilotService` and `GoalAutopilotRuntimeGate` record intake, diagnostic, plan, control, next action, action completion, checkpoint, projection, quota error, provider fallback and kill-switch events with stable blocked/downgraded reason codes.
- No blocker found for user-path resilience. Forced telemetry failure in `GoalAutopilotTelemetryTest` leaves goal creation successful and records redacted fallback audit evidence instead of surfacing telemetry failure to the user.
- No blocker found for data governance. Export metadata now lists `goal_autopilot_metric_events` as a redacted family with safe/redacted/omitted fields, and account deletion removes metric rows by redacted user hash.
- No blocker found for contract scope. S009 adds internal persistence and service wiring only; no OpenAPI/generated Dart shape changed, and backend migration/compile/regression gates passed.
- No blocker found for regression coverage. S009-specific tests, S007 export/deletion regression, S005 cost telemetry, S006 quota downgrade, S001 runtime gate, Foundation migration and P0.2 coverage gates all passed.

Validation:
- `python3 -m py_compile scripts/check_p0_2_followup_d_telemetry_redaction.py` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotTelemetryTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotDataExportRetentionTest test` - passed.
- `python3 scripts/check_p0_2_followup_d_telemetry_redaction.py` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotTelemetryTest,GoalAutopilotDataExportRetentionTest,GoalAutopilotCostTelemetryTest,GoalAutopilotQuotaDowngradeTest,GoalAutopilotRuntimeGateTest test` - passed.
- Backend JaCoCo goal-autopilot suite including S009 tests and prior S001-S008 regressions - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 95.7%, backend branch 81.1% and Flutter line 90.9%.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest test` - passed.

Required corrections:
- Fixed before close: S009 telemetry test initially asserted `$.goal.status`, but the existing create-goal contract returns `$.goal_profile.status`; the assertion now matches the existing API contract and reruns passed.
- Fixed before close: checkpoint/projection assertions initially expected optimistic `recorded`/`ready` states, but the existing low-confidence policy returns safe low-confidence states for the fixture; assertions now verify the established policy contract and reruns passed.
- None remain for local S009 telemetry after regression validation and report synchronization.

Residual risk:
- At S009 close, S010/S011 contract/release drift and final Product Base/release review remained open; current S010 evidence is recorded above.
- S009 records local backend telemetry evidence only. It does not prove live paid AI provider behavior, external payment/store/native evidence, commercial release readiness or Product Base merge approval.
- Followup-D remains not release-ready and Product Base merge is not approved.

## 2026-06-07 P02 Followup-D S008 Consent Privacy UX Independent Review

Review ID: `P02-FOLLOWUP-D-S008-CONSENT-PRIVACY-UX-20260607`

Result: pass for local S008 consent/privacy UX after backend consent/reminder/projection facts, copy contract, stale privacy state cleanup, screen spec, Flutter regression, changed-code coverage and report synchronization passed. This review does not approve S009-S011 telemetry, release drift, release readiness, paid AI external evidence or Product Base merge.

Findings:
- No blocker found for source-of-truth boundaries. `GoalAutopilotPanel` renders existing backend-owned `notification_consent`, `reminder_eligibility`, `projection_state` and `downgrade_reason`; it does not create local entitlement, quota, export, deletion, release or Product Base state.
- No blocker found for notification consent withdrawal. TC-P02-FUD-015 verifies the update request sends `notification_consent=false`, the UI moves to `Notifications: consent withdrawn`, reminder prompts are blocked with the backend `consent_missing` reason, and stale consent-on copy is removed.
- No blocker found for privacy/data-governance copy. The new surface states product-internal data use, backend export/delete/retention rules and sensitive-payload omission without raw transcript/audio/provider/idempotency/notification payload display.
- No blocker found for claim boundaries. The copy contract blocks guaranteed achievement, official-score equivalence, unlimited AI, unlimited checkpoint and release-approved wording, and widget tests assert those strings are not rendered.
- No blocker found for existing interaction ergonomics after correction. The privacy section sits after primary controls, preserving existing pause/resume/reminder/generate/edit tap targets in the full goal_autopilot widget regression.
- No blocker found for contract scope. S008 uses existing API fields and does not change OpenAPI/generated Dart shape; source-of-truth and coverage gates remain green.

Validation:
- `flutter test test/features/goal_autopilot/goal_autopilot_consent_privacy_widget_test.dart` - passed.
- `flutter test test/features/goal_autopilot` - passed.
- `flutter test --coverage test/features/goal_autopilot` - passed.
- `flutter analyze lib/features/goal_autopilot/goal_autopilot_panel.dart test/features/goal_autopilot/goal_autopilot_consent_privacy_widget_test.dart` - passed.
- `python3 scripts/check_commercial_copy_contract.py` - passed, while still reporting missing external store/privacy/support evidence refs as release blockers.
- `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 96.0%, backend branch 81.2% and Flutter line 90.9%.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- <S008 changed files and reports>` - passed.

Required corrections:
- Fixed before close: the first placement of the privacy section came before primary controls and pushed existing widget-test tap targets outside the default viewport. The section now renders after primary controls, and full `test/features/goal_autopilot` regression passed.
- Fixed before close: single-test coverage initially overwrote `coverage/lcov.info` with narrow S008-only coverage and dropped the project coverage gate below 80%. Full `flutter test --coverage test/features/goal_autopilot` regenerated coverage, and the P0.2 coverage gate passed at Flutter line 90.9%.
- None remain for local S008 consent/privacy UX after regression validation and report synchronization.

Residual risk:
- S009-S011 telemetry, contract/release drift and final Product Base/release review remain open.
- External `STORE_METADATA_EVIDENCE_REF`, `PRIVACY_URL` and `SUPPORT_URL` are still missing and remain release blockers.
- S008 records local deterministic Flutter UX/copy evidence only. It does not prove live paid AI provider behavior, external payment/store/native evidence, commercial release readiness or Product Base merge approval.
- Followup-D remains not release-ready and Product Base merge is not approved.

## 2026-06-07 P02 Followup-D S007 Data Governance Independent Review

Review ID: `P02-FOLLOWUP-D-S007-DATA-GOVERNANCE-20260607`

Result: pass for local S007 data governance after redacted export metadata, retention rules, account deletion cleanup, redacted audit proof, backend/Flutter regression, changed-code coverage and report synchronization passed. This review does not approve S008-S011 consent UX, telemetry, release drift, release readiness, paid AI external evidence or Product Base merge.

Findings:
- No blocker found for export minimization. `GoalAutopilotService.exportGoalAutopilotDataGovernance` returns data-family metadata, source refs, safe/redacted/omitted field names, retention rules and user hash evidence; it does not export raw diagnostic/checkpoint transcript, audio refs, provider payloads, notification payloads or raw idempotency keys.
- No blocker found for data-family coverage. S007 export evidence covers goal profiles, diagnostics, mastery initial state, backplans, daily plans, plan items, progress forecasts, checkpoints, controls, control idempotency, notification outbox, replay audits, recovery/mastery decisions, usage ledgers/reservations and AI provider metrics.
- No blocker found for account deletion cleanup. `AccountDeletionService` explicitly removes goal-autopilot control/idempotency rows, existing cleanup purges related P0.2 goal/autopilot/progress/usage rows, AI retention removes metrics by redacted user hash and audit details record `p0_2_goal_autopilot_data=deleted_or_anonymized`.
- No blocker found for contract boundaries. S007 added service/repository behavior only and did not change public OpenAPI shape; API contract and generated Dart drift remain synced to hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.
- No blocker found for regression coverage. S007-specific tests, account deletion regression, prior S001-S006 backend regressions, Flutter goal-autopilot coverage, analyze, frontend source-of-truth and P0.2 coverage gates all passed.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotDataExportRetentionTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotDataExportRetentionTest,AccountDeletionLearningDataTest,GoalAutopilotUsageReservationTest,UsageReservationLifecycleTest,GoalAutopilotCostTelemetryTest,GoalAutopilotQuotaDowngradeTest,GoalAutopilotControllerTest,GoalAutopilotReplayFixtureTest test` - passed.
- Backend JaCoCo goal-autopilot suite with S007 tests and prior S001-S006 regressions - passed.
- `npm run check:api-contract` - passed with generated Dart hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `flutter analyze` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 96.0%, backend branch 81.2% and Flutter line 90.5%.

Required corrections:
- Fixed before close: the S007 export test initially used a checkpoint before completing/recovery actions, which made the daily plan stale; the fixture now creates plan/action/recovery/checkpoint evidence in a valid order.
- Fixed before close: `GoalAutopilotControllerTest#tcP02Fuc002CheckpointTaskLibrary` had a date-source drift between JVM default `LocalDate.now()` and Spring `Clock`; the fixture now uses the Spring `Clock` and the regression suite passed.
- None remain for local S007 data governance after regression validation and report synchronization.

Residual risk:
- S008-S011 consent/privacy UX, telemetry, release drift and final Product Base/release review remain open.
- S007 records local backend data-governance evidence only. It does not prove live paid AI provider behavior, external payment/store/native evidence, commercial release readiness or Product Base merge approval.
- Followup-D remains not release-ready and Product Base merge is not approved.

## 2026-06-06 P02 Followup-D S006 Quota Downgrade Independent Review

Review ID: `P02-FOLLOWUP-D-S006-QUOTA-DOWNGRADE-20260606`

Result: pass for local S006 quota downgrade after stable quota/entitlement/cost reasons, full-depth plan/checkpoint/ETA/projection block behavior, Flutter stale full-depth cleanup, OpenAPI/generated Dart contract drift, backend/Flutter regression, changed-code coverage and report synchronization passed. This review does not approve S007-S011 data governance, consent UX, telemetry, release readiness, paid AI external evidence or Product Base merge.

Findings:
- No blocker found for stable backend downgrade mapping. Quota exhaustion now returns `quota_exhausted`, cost budget limits return `cost_budget_limited`, and blocked entitlement surfaces normalize user-facing downgrade behavior to `entitlement_required` while preserving raw entitlement source reasons in server-owned entitlement depth or error details.
- No blocker found for quota-before-write behavior. S006 quota retry evidence proves rejected full-depth plan requests surface typed `USAGE_LIMIT_EXCEEDED` downgrade details before additional backplan writes, and read/projection paths are downgraded without copying full-depth source refs or premium fragments.
- No blocker found for full-depth unavailable projection semantics. Forecast/projection/checkpoint task responses remove precise ETA, goal/action/progress/checkpoint source refs, high-depth fragments and full-depth checkpoint controls when quota, entitlement or cost reasons block full-depth behavior.
- No blocker found for Flutter source-of-truth boundaries. Home, Queue, Wiki and Panel widgets render backend downgrade reasons and clear stale action, ETA, checkpoint and plan controls without locally inferring quota, entitlement or release state.
- No blocker found for API/generated contract alignment. OpenAPI stable reason enums and generated Dart client drift are synced to hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.
- No blocker found for regression scope. S006-specific tests, prior S001-S005 backend regressions, OpenAPI/generated drift, Flutter goal-autopilot suite, analyze, frontend source-of-truth and P0.2 coverage gates all passed.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotQuotaDowngradeTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotQuotaDowngradeTest,GoalAutopilotEntitlementPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControllerTest,GoalAutopilotUsageReservationTest,GoalAutopilotCostTelemetryTest test` - passed after quiet-hours fixture stabilization.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotReplayFixtureTest test` - passed after replay fixture quiet-hours stabilization.
- Backend JaCoCo goal-autopilot suite with S006 tests and prior S001-S005 regressions - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_quota_downgrade_widget_test.dart` - passed.
- `flutter test test/features/goal_autopilot` - passed.
- `flutter analyze` - passed.
- `npm run check:api-contract` - passed with 87 paths, 93 operations, 42 request examples, 88 success examples, 113 error examples and generated Dart hash `fa2f5c368a83abbc6e24b182046af875b25856ce3af9756a861ff66794b464eb`.
- `npm run check:dart-client-drift` - passed with the same hash.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 95.9%, backend branch 81.2% and Flutter line 90.5%.
- `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- Fixed before close: `GoalAutopilotControllerTest#tcP02Fub001...` and `GoalAutopilotReplayFixtureTest#tcP02Fub015...` had time-dependent quiet-hours fixture expectations at the current Asia/Shanghai run time; the fixtures now disable quiet hours only for eligible-reminder branches and reruns passed.
- Fixed before close: legacy S003 revoked-entitlement assertions now expect stable `entitlement_required` on forecast/error/checkpoint surfaces while preserving raw `entitlement_blocked_revoked` under `entitlement_depth`.
- Fixed during independent review: `GoalAutopilotService` entitlement source-ref indentation was normalized without changing behavior.
- None remain for local S006 quota downgrade after contract sync, regression validation and report synchronization.

Residual risk:
- S007-S011 data governance, consent UX, telemetry, release drift and final Product Base/release review remain open.
- S006 records deterministic local quota/entitlement/cost downgrade behavior only. It does not prove live paid AI provider behavior, external payment/store/native evidence, commercial release readiness or Product Base merge approval.
- Followup-D remains not release-ready and Product Base merge is not approved.

## 2026-06-06 P02 Followup-D S005 Cost Telemetry And AI Fallback Independent Review

Review ID: `P02-FOLLOWUP-D-S005-COST-TELEMETRY-AI-FALLBACK-20260606`

Result: pass for local S005 cost telemetry/AI fallback after cost metric persistence, deterministic no-provider and policy rejection evidence, AI forbidden-field guardrails, OpenAPI/generated Dart contract drift, backend/Flutter regression, changed-code coverage and report synchronization passed. This review does not approve S006-S011 quota downgrade, data governance, consent UX, telemetry, release readiness, paid AI external evidence or Product Base merge.

Findings:
- No blocker found for deterministic no-provider evidence. Full-depth deterministic plan and checkpoint flows record `deterministic_no_provider` cost metrics with zero estimated cost and explicit operation fallback reasons instead of claiming live provider success.
- No blocker found for policy rejection persistence. `AiCostMetricsService.recordPolicyRejection` uses `REQUIRES_NEW`, so entitlement/provider-candidate and quota rejection metrics persist even when the goal-autopilot API transaction returns an error.
- No blocker found for redaction and entitlement boundaries. Cost metrics store user hashes and safe fallback reasons; tests verify free fallback does not create entitlement snapshots and transcript content is not copied into cost fallback evidence.
- No blocker found for cost dashboard contract alignment. `AiCostMetric` exposes `fallback_reason` and the `deterministic_no_provider` status; `AiCostDashboardTest#tcP02Fud009CostDashboardExposesFallbackReasonForDeterministicNoProvider` verifies the ops API mapping, and OpenAPI, generated Dart manifest and generated API hash are synced to `3196a97f38da3d2f01044cbeab242fa3a78c449ff4bb92fa4ccce549fc96686c`.
- No blocker found for AI candidate-only guardrails. Forecast and mastery validators reject entitlement, quota, billing, final mastery, release approval and Product Base merge fields with `ai_forbidden_persistent_field`, and AI runtime docs record the S005 eval cases.
- No blocker found for regression coverage. S005-specific tests, prior S003/S004 backend regressions, cost dashboard tests, API contract drift, Flutter API contract tests, analyze and P0.2 coverage gates all passed.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotCostTelemetryTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotAiGuardrailTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ForecastExplanationSchemaTest,MasteryTransitionPolicyTest,GoalAutopilotAiGuardrailTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest,GoalAutopilotCostTelemetryTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest,GoalAutopilotCostTelemetryTest,GoalAutopilotAiGuardrailTest test` - passed after adding the dashboard `fallback_reason` API assertion.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotCostTelemetryTest,GoalAutopilotAiGuardrailTest,GoalAutopilotUsageReservationTest,UsageQuotaGateTest,UsageReservationLifecycleTest,GoalAutopilotEntitlementPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControllerTest test` - passed.
- Backend JaCoCo goal-autopilot suite with S005 tests and prior S001-S004 regressions - passed.
- `npm run check:api-contract` - passed with OpenAPI hash `3196a97f38da3d2f01044cbeab242fa3a78c449ff4bb92fa4ccce549fc96686c`.
- `flutter analyze` - passed.
- `flutter test test/services/api_client_contract_test.dart` - passed.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 96.1%, backend branch 81.3% and Flutter line 90.5%.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- Fixed before close: API contract drift initially failed because S005 OpenAPI changes changed the generated hash. The OpenAPI manifest, `.openapi-sha256` and generated Dart client were synced to `3196a97f38da3d2f01044cbeab242fa3a78c449ff4bb92fa4ccce549fc96686c`, then `npm run check:api-contract` passed.
- Fixed before close: AI runtime docs now include S005 eval cases and release/Product Base forbidden persistent fields so TC-P02-FUD-010 has document-level contract evidence, not only Java test evidence.
- Fixed during independent review: added a direct ops dashboard API assertion for deterministic no-provider `fallback_reason` so the DTO/OpenAPI mapping is executable evidence, not only schema evidence.
- None remain for local S005 cost telemetry/AI fallback after contract sync and regression validation.

Residual risk:
- S006-S011 quota exhausted downgrade surfaces, data governance, consent UX, telemetry, release drift and final Product Base/release review remain open.
- S005 records deterministic/no-provider and policy-rejection evidence only. It does not prove live paid AI provider behavior, commercial release readiness, store/native evidence or Product Base merge approval.
- Followup-D remains not release-ready and Product Base merge is not approved.

## 2026-06-06 P02 Followup-D S004 Usage Reservation And Quota Independent Review

Review ID: `P02-FOLLOWUP-D-S004-USAGE-RESERVATION-QUOTA-20260606`

Result: pass for local S004 usage reservation/quota/idempotency after backend reservation lifecycle, OpenAPI/generated Dart contract drift, backend/Flutter regression, changed-code coverage and report synchronization passed. This review does not approve S005-S011 cost telemetry, AI fallback, quota downgrade surfaces, data governance, consent UX, telemetry, release readiness, paid AI external evidence or Product Base merge.

Findings:
- No blocker found for reserve-before-write behavior in the scoped deterministic paths. `GoalAutopilotService.generatePlan` validates runtime/support/blocked entitlement first, then reserves `ai` usage before backplan/daily-plan writes; quota exhaustion returns `USAGE_LIMIT_EXCEEDED` before new backplan writes.
- No blocker found for commit/release accounting. Plan generation commits exactly once on success; checkpoint submission commits recorded evidence and releases failed/skipped/low-confidence fallback so committed usage does not increase on failed checkpoint evidence.
- No blocker found for idempotency. `UsageService.reserve` compares usage family, amount and sanitized `source_ref`; the same retry does not double charge, while the same idempotency key with a different source payload returns typed `IDEMPOTENCY_CONFLICT` before new goal-autopilot writes.
- No blocker found for API/data minimization. `UsageReservation` now carries `source_ref`, redacted `idempotency_key_ref`, optional `provider_usage_event_ref` and `expires_at`; raw idempotency keys are not returned by `CommercialFoundationController`.
- No blocker found for migration compatibility. `V202606060001__p0_2_followup_d_usage_reservation_trace.sql` adds `source_ref` with a non-null default and optional provider event ref; H2 Flyway test startup applied the migration successfully.
- No blocker found for contract and generated-client alignment. OpenAPI adds `/usage/reserve` 409 `IdempotencyConflict`, updates `UsageReservation`, examples and generated Dart hash to `38dd8133c0551dc019eaf56fe8ccde3016db5f3180f9f578e85714ba5aae61b2`.
- No blocker found for regression coverage. S004-specific tests, prior S001/S003 backend regressions, API contract drift, Flutter API contract tests, analyze and P0.2 coverage gates all passed.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotUsageReservationTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=UsageQuotaGateTest,UsageReservationLifecycleTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotUsageReservationTest,UsageQuotaGateTest,UsageReservationLifecycleTest,GoalAutopilotEntitlementPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControllerTest test` - passed.
- `npm run check:api-contract` - passed.
- Backend JaCoCo goal-autopilot suite with `GoalAutopilotUsageReservationTest`, `UsageQuotaGateTest` and `UsageReservationLifecycleTest` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 96.0%, backend branch 81.1% and Flutter line 90.5%.
- `flutter analyze` - passed.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- Fixed before close: API contract drift initially failed because S004 OpenAPI changes changed the generated hash. The OpenAPI manifest, `.openapi-sha256` and generated Dart client were synced to `38dd8133c0551dc019eaf56fe8ccde3016db5f3180f9f578e85714ba5aae61b2`, then `npm run check:api-contract` passed.
- None remain for local S004 usage reservation/quota after contract sync and regression validation.

Residual risk:
- S005-S011 cost telemetry, AI fallback, quota exhausted downgrade surfaces, data governance, consent UX, telemetry, release drift and final Product Base/release review remain open.
- S004 uses deterministic plan/checkpoint paths and existing usage ledgers. Live provider unavailable/cost evidence must be proven in S005; S004 must not be read as paid AI external evidence.
- Followup-D remains not release-ready and Product Base merge is not approved.

## 2026-06-06 P02 Followup-D S003 Entitlement Depth Independent Review

Review ID: `P02-FOLLOWUP-D-S003-ENTITLEMENT-DEPTH-20260606`

Result: pass for local S003 entitlement depth after backend policy, API contract, Flutter service-owned display, regression/coverage evidence and report synchronization passed. This review does not approve S004-S011 commercial/data/ops gates, release readiness, paid AI external evidence or Product Base merge.

Findings:
- No blocker found for server-owned entitlement decisions. `GoalAutopilotEntitlementPolicy` explicitly maps paid active/full, free/default limited, expired/grace limited, revoked/refunded/unknown blocked, support override and quota/cost-limited states without relying on Flutter-provided entitlement facts.
- No blocker found for full-depth blocking. `GoalAutopilotService.generatePlan` rejects blocked entitlement depth before creating a plan, checkpoint task selection returns unavailable for blocked entitlement states, and forecast views suppress precise ETA when entitlement depth is blocked; free users receive limited checkpoint depth instead of full checkpoint depth.
- No blocker found for API contract alignment. OpenAPI declares `GoalEntitlementDepth`, wires `entitlement_depth` into summary, plan, forecast, checkpoint task and checkpoint responses, updates examples, and generated Dart drift pins are synced to `9269bc0c15413f57377629ee3c142fb41d4180518c5f93e81cbfadfcc59a7bd3`.
- No blocker found for Flutter source-of-truth boundary. Flutter parses and displays backend `entitlement_depth` limitation reason and uses backend `depth_state=blocked` to suppress generate-plan UI; it does not infer pro/free/expired entitlement state locally.
- No blocker found for regression coverage. Existing goal-autopilot controller/checkpoint tests, Flutter goal-autopilot tests, API contract drift, analyze and coverage gates passed after S003 changes.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotEntitlementPolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fud003EntitlementDepthIsServerOwned test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotEntitlementPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControllerTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter test test/features/goal_autopilot` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` - passed.
- `npm run check:api-contract` - passed.
- `flutter analyze` - passed.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- Backend JaCoCo goal-autopilot suite with `GoalAutopilotEntitlementPolicyTest` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 96.1%, backend branch 81.0% and Flutter line 90.5%.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- Fixed during independent review: blocked entitlement summary/forecast views now return unavailable forecast state without `eta_date`, so revoked/refunded/unknown users cannot receive a precise ETA while full depth is blocked.
- Fixed during independent review: revoked/refunded/unknown entitlement statuses now take precedence over an already-past `valid_until`, preventing blocked snapshots from being downgraded to limited expired entitlement.
- None remain for S003 entitlement depth after API examples/hash pins, Flutter display tests and blocked-forecast ETA suppression were synchronized.

Residual risk:
- S004-S011 entitlement usage reservation, quota lifecycle, cost telemetry, quota exhausted downgrade, data governance, consent UX, telemetry, drift gates and final release/Product Base review remain open.
- S003 uses existing entitlement snapshot quota limits only to determine whether paid full depth is eligible; full usage reservation/commit/release evidence remains S004/S006 scope.
- S003 does not prove commercial release, paid AI external evidence, store/native evidence or Product Base merge approval.

## 2026-06-06 P02 Followup-D S002 Flutter Runtime Rollback Independent Review

Review ID: `P02-FOLLOWUP-D-S002-FLUTTER-RUNTIME-ROLLBACK-20260606`

Result: pass for local S002 Flutter rollback after the cached projection replacement gap was corrected and widget/source-of-truth/regression/coverage evidence passed. This review does not approve S003-S011 commercial/data/ops gates, release readiness, paid AI external evidence or Product Base merge.

Findings:
- No blocker remains for disabled entry behavior. `GoalAutopilotPanel` now renders `_GoalRuntimeUnavailable` before edit/create/explore branches, so disabled/kill-switch/unavailable states do not expose Set a goal, Explore practice, Start autopilot, Generate plan, Done, Checkpoint or reminder controls.
- No blocker remains for backend-owned projection facts. `GoalAutopilotAdapter.loadRuntimeGateProjection` and `GoalProgressProjection.unavailable` produce an unavailable shell with no goal, action, forecast, checkpoint, source refs or safe progress fields when backend runtime is closed or unavailable.
- No blocker remains for cached projection replacement. Independent review first found that Home could keep an old ready `_goalProgressProjectionFuture`; this was corrected by passing the unavailable projection from `GoalAutopilotPanel` to Home and replacing the cached future.
- No blocker remains for source-of-truth guard coverage. `scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` checks adapter/panel/Home runtime gate wiring, unavailable projection safety, cache replacement and forbidden local target/ETA/quota/release inference in surfaces.
- No blocker remains for regression coverage. Existing Followup-A/B/C goal-autopilot widget/source-of-truth/performance tests still pass after the S002 gate.

Validation:
- `flutter test test/features/goal_autopilot/goal_autopilot_runtime_gate_widget_test.dart` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_frontend_source_of_truth.py` - passed.
- `flutter test test/features/goal_autopilot` - passed.
- `flutter analyze` - passed.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 96.1%, backend branch 80.9% and Flutter line 90.3%.

Required corrections:
- Fixed during review: added `GoalAutopilotPanel.onRuntimeUnavailableProjection` and Home `_replaceGoalProjectionWithRuntimeGate` so disabled projection state replaces cached ready projection.

Residual risk:
- S003-S011 entitlement, usage/quota, cost telemetry, quota downgrade, data governance, consent UX, telemetry, drift gates and final release/Product Base review remain open.
- S002 does not prove commercial release, paid AI external evidence, store/native evidence or Product Base merge approval.

## 2026-06-06 P02 Followup-D S001 Backend Runtime Gate Independent Review

Review ID: `P02-FOLLOWUP-D-S001-RUNTIME-GATE-20260606`

Result: pass for local S001 backend/API runtime gate after blocked mutation audit persistence, read/projection downgrade, OpenAPI/generated Dart drift, coverage and report synchronization passed. At S001 close, this review did not approve S002 Flutter rollback, S003-S011 commercial/data/ops gates, release readiness, paid AI external evidence or Product Base merge.

Findings:
- No blocker found for mutation fail-closed behavior. `GoalAutopilotRuntimeGate` is evaluated before goal create/update, plan generate, control update/pause/resume, recovery replan, item-policy decisions, action completion and checkpoint submission write goal/autopilot/progress state.
- No blocker found for audit persistence. Blocked mutation audit rows are written through a new transaction, so the `GOAL_AUTOPILOT_RUNTIME_DISABLED` exception does not roll back the redacted `goal_autopilot_runtime_blocked` evidence.
- No blocker found for read and projection safety after review correction. Summary, daily plan, next action, forecast, checkpoint task, reminder outbox, replay audit and mastery-transition reads now fail closed while disabled/kill-switch active; progress projection returns unavailable without goal/action/progress/checkpoint refs, and control returns a synthetic blocked state without writing DB rows.
- No blocker found for API contract alignment after review correction. OpenAPI declares runtime-disabled 503 responses for gated mutation/read endpoints, keeps progress projection as 200 unavailable and keeps control GET as 200 blocked; generated Dart hash is synced to `0918bcf90cbc08198be7273e07fd18aa0471e06ba32f9cee21185105814780b2`.
- No blocker found for data minimization. Runtime-blocked audit details include operation, access mode, runtime state, reason and rule version, and tests assert raw diagnostic samples and sensitive target-score payloads are absent.
- No blocker found for regression coverage. Runtime gate tests cover flag disabled and kill switch active paths; controller regression and broader goal-autopilot policy/replay/performance tests pass; P0.2 coverage remains above the 80% line and branch thresholds.
- Fixed before close: the first runtime gate implementation wrote blocked audit rows inside the rolled-back mutation transaction. `GoalAutopilotRuntimeGate` now uses `PROPAGATION_REQUIRES_NEW`, and the regression test verifies persisted audit rows.
- Fixed before close: independent review found read endpoints for reminder outbox, replay audits and mastery transitions were not gated, and OpenAPI missed runtime-disabled responses for plan generate, daily plan, reminder outbox and replay audits. The read gates and OpenAPI responses were added, and unrelated misplaced 503 responses on non-goal-autopilot paths were removed before rerunning contract checks.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotRuntimeGateTest test` - passed after audit and read-gate corrections.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,GoalAutopilotRuntimeGateTest test` - passed.
- `npm run check:api-contract` - passed with OpenAPI hash `0918bcf90cbc08198be7273e07fd18aa0471e06ba32f9cee21185105814780b2`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,GoalAutopilotRuntimeGateTest,GoalProgressProjectionDataGovernanceTest,GoalProgressProjectionServiceTest,ProgressForecastPolicyTest,CheckpointCadencePolicyTest,GoalAutopilotControlPerformanceTest,NotificationOutboxReplayTest,MissedDayRecoveryPlannerTest,GoalAutopilotReplayFixtureTest,NotificationEligibilityPolicyTest,MemoryCurveReplayTest,MasteryTransitionPolicyTest,GoalProgressProjectionPerformanceTest,ForecastExplanationSchemaTest,CheckpointReplayAuditTest,GoalAutopilotRecoveryControllerTest,MemoryCurvePolicyTest,NotificationOutboxServiceTest org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed with backend line 96.1%, backend branch 80.9% and Flutter line 90.1%.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- None remain for S001 backend/API runtime gate after the audit transaction, read gate and OpenAPI contract corrections.

Residual risk:
- At S001 close, S002 Flutter entry/surface rollback was still required before disabled/kill-switch state was fully proven on user-visible surfaces; current S002 evidence is recorded above.
- S003-S011 entitlement, usage/quota, cost telemetry, data governance, consent, telemetry, drift, release checklist and final Product Base/release review remain open.
- This review covers local deterministic backend/API behavior only and does not create paid AI external evidence, commercial release approval or Product Base merge approval.

## 2026-06-06 P02 Followup-D S000 Document Chain Dual Review

Review ID: `P02-FOLLOWUP-D-S000-DOCUMENT-CHAIN-20260606`

Result: pass for S000 documentation-chain closure and implementation routing. This review approves Followup-D readiness for routed implementation planning only. It does not approve S001-S011 implementation, release readiness, paid AI external evidence or Product Base merge.

Findings:
- Product engineer review: no blocker found for product scope. Followup-D is correctly scoped as release-gate hardening over A/B/C functional evidence, covering feature flag, entitlement, usage/cost, quota downgrade, consent/export/retention, telemetry, drift checks and Product Base/release review.
- Product engineer review: no blocker found for upstream coverage. P02-SI-001 through P02-SI-013 are explicitly routed to Followup-D slices, and P02-PG-001 through P02-PG-005 remain visible in requirements, acceptance, tests and traceability.
- Product engineer review: no blocker found for user-visible boundaries. Disabled, quota, entitlement, cost, data-governance and privacy behavior are represented as planned typed states, and copy restrictions block official-score, guaranteed-achievement, unlimited-AI and release-ready claims.
- Product engineer review: no blocker found for commercial/Product Base separation. S000 does not claim commercial release, paid AI external evidence or Product Base merge approval, and S011 keeps those decisions auditable and separate.
- Software engineer review: no blocker found for implementability. S001-S011 are small enough to route to backend runtime gate, Flutter rollback, entitlement policy, usage/cost services, data governance, telemetry, drift checker and final report ownership without mixing concerns.
- Software engineer review: no blocker found for contract handoff. The spec identifies domain, API/OpenAPI, AI runtime, UX and Ops/release contract outputs required before implementation where current contracts are insufficient.
- Software engineer review: no blocker found for AC-to-TC closure at S000 close. AC-P02-FUD-000..011 each mapped to stable TC-P02-FUD IDs, and S001-S011 were intentionally left planned until command output and report evidence existed.
- Software engineer review: no blocker found for source-of-truth boundary. Followup-D requires backend-owned entitlement, quota, runtime, ETA/completion and release state, and blocks Flutter/local fallback for those facts.
- Fixed before close: stage scope coverage was tightened from range-only coverage to an explicit P02-SI-001..013 detail routing table in `requirements.md`.

Validation:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- docs/product/increments/p0-2-followup-d-release-gate-hardening docs/reports/test_report.md docs/reports/implementation_report.md docs/reports/quality_report.md` - passed.

Required corrections:
- None remain for S000 documentation routing after the explicit Stage Scope Detail Coverage table was added.

Residual risk:
- S001-S011 implementation, tests, contract updates and independent reviews remain open.
- Followup-D is not release-ready.
- Product Base merge, commercial release approval and paid AI external evidence remain unapproved.

## 2026-06-06 P02 Followup-C S007 OpenAPI Nullable Cleanup Independent Review

Review ID: `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`

Result: pass for S007 OpenAPI nullable cleanup after contract/drift/traceability regression for TC-P02-FUC-020, TC-P02-FUC-021 and TC-P02-FUC-022. This review does not approve Followup-D, release readiness or Product Base merge.

Findings:
- No blocker found for OpenAPI schema compatibility. `ProgressForecast.eta_range` now uses OpenAPI 3.0.3-compatible `type: object`, `nullable: true` and `allOf` around `ProgressForecastEtaRange`, and the audit scan found no `$ref` plus `nullable` sibling schemas.
- No blocker found for contract behavior. `npm run check:api-contract` passed with unchanged path, operation and example counts, so the cleanup removed Redocly warnings without adding endpoints or changing payload semantics.
- No blocker found for generated Dart drift. Manifest, `.openapi-sha256` and `SpeakeasyApiContract.openApiSha256` all pin `d8b492b07c98e948caf0b5912744f05fa6dcd4b76f97f0ece04dc9778df7da0f`.
- No blocker found for client compatibility. `flutter analyze` and `flutter test test/services/api_client_contract_test.dart` passed after the hash update.
- No blocker found for traceability/report sync. `scripts/check_p0_2_followup_c_traceability.py` now asserts the nullable cleanup shape, generated hash pins and S007 report terms.

Validation:
- `npm run lint:openapi` - passed with no nullable `$ref` warnings.
- `npm run check:api-contract` - passed with 87 paths, 93 operations, 42 request examples, 88 success examples and 112 error examples.
- `npm run check:dart-client-drift` - passed with OpenAPI hash `d8b492b07c98e948caf0b5912744f05fa6dcd4b76f97f0ece04dc9778df7da0f`.
- `flutter analyze` - passed.
- `flutter test test/services/api_client_contract_test.dart` - passed.
- `python3 scripts/check_p0_2_followup_c_traceability.py` - passed with nullable cleanup and generated hash assertions.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- None remain for S007 OpenAPI nullable cleanup.

Residual risk:
- Followup-C is locally complete for S001-S007. Followup-C is not release-ready and Product Base merge is not approved.
- Followup-D commercial/release/data/ops gates remain open.
- Product Base merge is not approved and still requires Product Manager approval plus governance review.

## 2026-06-06 P02 Followup-C S007 Final Independent Review

Review ID: `P02-FOLLOWUP-C-S007-QUALITY-GATES-20260606`

Result: pass for local S007 performance, coverage, traceability and report gates after p95 tests, coverage generation, dedicated checker, static/API contract checks, project validation and diff hygiene passed. This review does not approve Followup-D, release readiness or Product Base merge.

Findings:
- No blocker found for backend p95 coverage. `GoalProgressProjectionPerformanceTest` exercises forecast recompute, checkpoint task lookup, checkpoint submit accepted/queued and backend projection load against the documented Followup-C budgets.
- No blocker found for Flutter surface propagation budget. `goal_progress_surface_performance_test.dart` runs the adapter projection parse plus Home/Queue/Wiki widget render path and asserts p95 <=1s.
- No blocker found for changed-code coverage. `scripts/check_p0_2_goal_autopilot_coverage.py` passed with backend line 96.0%, backend branch 80.9% and Flutter line 90.1%.
- No blocker found for traceability closure. `scripts/check_p0_2_followup_c_traceability.py` validates TC-P02-FUC-020..022 rows, P02-FUC-TR-007 closure, report evidence and forbidden release/Product Base claims.
- No blocker found for static/API drift guards. `flutter analyze`, `npm run check:dart-client-drift` and `npm run check:api-contract` passed with OpenAPI hash `bed8ebbbe2d9fed907b7411fca512912f1302fbb73427e7783b4f7ae2d0678f8`. Historical note: Redocly reported six nullable `$ref` warnings at S007 close; this was later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`.
- No blocker found for scope boundary. S007 added tests, a checker script and evidence updates only; no production backend, Flutter or API code changed.
- No blocker found for report synchronization. `definition.md`, `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md`, `traceability.md`, `test_report.md`, `implementation_report.md`, `quality_report.md` and `development_status.md` now preserve S001-S007 local completion while keeping release/Product Base non-approval explicit.
- Fixed before close: stale S007 `planned/blocked` wording in `test_cases.md`, `spec.md` and `traceability.md` was corrected to local S007 completion with release/Product Base gates still closed.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionPerformanceTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_progress_surface_performance_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `flutter test --coverage test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed.
- `python3 scripts/check_p0_2_followup_c_traceability.py` - passed after report synchronization.
- `flutter analyze` - passed.
- `npm run check:dart-client-drift` - passed.
- `npm run check:api-contract` - passed. Historical note: Redocly reported six nullable `$ref` warnings at S007 close; this was later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- None remain for local S007 quality gates after the stale S007 status wording corrections above.

Residual risk:
- Followup-C is locally complete for S001-S007. Followup-C is not release-ready and Product Base merge is not approved.
- Followup-D commercial/release/data/ops gates remain open.
- Product Base merge is not approved and still requires Product Manager approval plus governance review.

## 2026-06-06 P02 Followup-C S006 Surface Downgrade Independent Review

Review ID: `P02-FOLLOWUP-C-S006-SURFACE-DOWNGRADE-20260606`

Result: pass for local S006 surface deletion/unavailable downgrade after backend fragment minimization, account deletion purge coverage, Flutter downgrade/cache cleanup tests, contract checks and project validation passed. This review does not approve S007, Followup-C completion, release readiness or Product Base merge.

Findings:
- No blocker found for backend data minimization. `GoalAutopilotService.progressSurfaceFragments` now clears action/forecast/checkpoint refs and safe fields for ineligible unavailable, unsupported, stale and control-blocked fragments instead of carrying stale source refs.
- No blocker found for backend downgrade traceability. Eligible limited/low-confidence fragments still carry backend `downgrade_reason`, while forecast policy keeps precise ETA and completion claims unavailable.
- No blocker found for account deletion cleanup. `AccountDeletionLearningDataTest#tcP02Fuc006GoalProgressProjectionPurgedOnDeletion` verifies goal profiles, controls, diagnostics, plans, forecasts, checkpoints and replay audits are deleted, and old projection reads return `UNAUTHENTICATED`.
- No blocker found for Flutter cache replacement. `goal_progress_downgrade_widget_test.dart` pumps a ready projection and then a downgraded projection into the same Home/Queue/Wiki surfaces, proving old gap/action/checkpoint copy is removed.
- No blocker found for sensitive copy boundaries. Downgraded surfaces do not render target score, target ability, precise ETA, official score, guaranteed outcome or goal-achieved copy.
- No API contract drift blocker. S006 does not change OpenAPI shape; `npm run check:api-contract` and `npm run check:dart-client-drift` passed with existing hash `bed8ebbbe2d9fed907b7411fca512912f1302fbb73427e7783b4f7ae2d0678f8`.
- Fixed before close: the first backend data-governance test accessed a package-private test-support repository and then exposed a user-fixture isolation/transaction issue. The test now autowires `GoalProgressForecastRepository` directly, deletes only the current user's forecast fixture and marks the derived delete transactional.
- Scope boundary is correct. S006 does not claim p95 performance, changed-code coverage closure, final Followup-C traceability script, release readiness, Product Base merge or live AI provider behavior.

Validation:
- `flutter test test/features/goal_autopilot/goal_progress_downgrade_widget_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionDataGovernanceTest test` - passed after repository access, user-scoped fixture cleanup and transaction corrections.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AccountDeletionLearningDataTest#tcP02Fuc006GoalProgressProjectionPurgedOnDeletion test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionDataGovernanceTest,AccountDeletionLearningDataTest#tcP02Fuc006GoalProgressProjectionPurgedOnDeletion test` - passed.
- `flutter test test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionServiceTest,GoalAutopilotControllerTest#tcP02Fuc004ProjectionIsBackendOwned,GoalProgressProjectionDataGovernanceTest,AccountDeletionLearningDataTest#tcP02Fuc006GoalProgressProjectionPurgedOnDeletion test` - passed.
- `flutter analyze` - passed.
- `npm run check:dart-client-drift` - passed.
- `npm run check:api-contract` - passed. Historical note: Redocly reported nullable `$ref` warnings at S006 close; this was later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- None for local S006 surface deletion/unavailable downgrade after the repository access, user-scoped fixture cleanup and transaction corrections.

Residual risk:
- Followup-C remains incomplete, not release-ready and not Product Base-ready.
- S007 p95 performance, changed-code coverage gate, dedicated traceability script and final independent review remain implementation gated.
- S006 is deterministic and backend-owned. Future provider-assisted wording must remain candidate-only and must not set projection state, surface eligibility, downgrade reason or source refs.

## 2026-06-06 P02 Followup-C S005 Surface Propagation Independent Review

Review ID: `P02-FOLLOWUP-C-S005-SURFACE-PROPAGATION-20260606`

Result: pass for local S005 Home/Queue/Wiki surface propagation after projection adapter loading, reusable safe-field surface widgets, Home/Queue/Wiki integration, source-of-truth tests, contract checks and project validation passed. This review does not approve S006-S007, Followup-C completion, release readiness or Product Base merge.

Findings:
- No blocker found for backend projection consumption. `GoalAutopilotAdapter.loadProgressProjection()` uses `SpeakeasyApiPaths.goalAutopilotProgressProjection`, and Home, expression queue and personal Wiki all receive `GoalProgressProjection` fragments instead of recomputing final goal state locally.
- No blocker found for surface field minimization. `goal_progress_surface.dart` renders only allowed safe fields such as next action, gap summary, risk reason, next checkpoint date and checkpoint summary; it does not reference target score, target ability, ETA date or goal-completion claim fields.
- No blocker found for Queue source-of-truth behavior. `ExpressionDailyQueueCoordinator` remains free of `GoalProgressProjection`, so S005 does not use projection data to locally reorder or reprioritize queue items.
- No blocker found for Home legacy leakage. Home goal summary suppresses the old summary gap/ETA rows when a projection exists and renders the Home fragment through `GoalProgressHomeSurface`.
- No blocker found for Wiki propagation. Personal Wiki tiles can render `GoalProgressWikiSurface` from the shared projection while omitting next action when the wiki fragment does not list that safe field.
- No blocker found for projection failure handling after review correction. Optional fallback now returns null only for legacy missing-payload `FormatException`; real projection API failures continue to surface instead of reusing old local summary data silently.
- No API contract drift blocker. S005 consumes the S004 projection endpoint without changing OpenAPI shape; `npm run check:api-contract` and `npm run check:dart-client-drift` passed with the existing OpenAPI hash `bed8ebbbe2d9fed907b7411fca512912f1302fbb73427e7783b4f7ae2d0678f8`.
- Fixed before close: the first surface text assertions could not find text inside `RichText`; the surface now uses `Text.rich` for testable text rendering. The standalone Home panel test also exposed a bounded-height overflow, fixed with a bounded scroll fallback.
- Scope boundary is correct. S005 does not claim deletion/unavailable downgrade, cached stale projection cleanup, p95 performance, final traceability script, release readiness, Product Base merge or live AI provider behavior.

Validation:
- `flutter test test/features/goal_autopilot/goal_progress_home_surface_test.dart test/features/goal_autopilot/goal_progress_queue_surface_test.dart test/features/goal_autopilot/goal_progress_wiki_surface_test.dart test/features/goal_autopilot/goal_progress_surface_source_of_truth_test.dart` - passed.
- `flutter test test/features/goal_autopilot test/services/api_client_contract_test.dart` - passed.
- `flutter test test/services/api_client_contract_test.dart` - passed.
- `flutter analyze` - passed.
- `npm run check:dart-client-drift` - passed.
- `npm run check:api-contract` - passed. Historical note: Redocly reported nullable `$ref` warnings at S005 close; this was later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- None for local S005 surface propagation.

Residual risk:
- Followup-C remains incomplete, not release-ready and not Product Base-ready.
- S006 deletion/unavailable/unsupported/low-confidence downgrade and cached stale projection cleanup remain implementation gated.
- S007 p95 performance, changed-code coverage gate, dedicated traceability script and final independent review remain implementation gated.

## 2026-06-06 P02 Followup-C S004 Progress Projection Independent Review

Review ID: `P02-FOLLOWUP-C-S004-PROGRESS-PROJECTION-20260606`

Result: pass for local S004 backend projection behavior after backend aggregation, safe-fragment redaction, unavailable downgrade, OpenAPI/generated Dart drift and project validation passed. This review does not approve S005-S007, Followup-C completion, release readiness or Product Base merge.

Findings:
- No blocker found for backend source-of-truth ownership. `GoalAutopilotService.progressProjection` builds projection state, downgrade reason, next action, forecast, latest checkpoint, surface fragments and source refs server-side; the controller only maps DTOs and does not recompute projection truth.
- No blocker found for safe field boundaries. The projection omits diagnostic rubric/details, raw transcripts, audio refs, target score/ability, weekly/daily plan payloads and provider payloads while exposing safe goal status, action, forecast, checkpoint conclusion, claim guard and source refs.
- No blocker found for unavailable behavior. A user with no active goal receives `projection_state=unavailable`, `downgrade_reason=no_active_goal`, empty source refs and ineligible surface fragments instead of stale progress facts.
- No blocker found for surface contract readiness. Home, Queue and Wiki fragments are present with backend-owned `display_state`, `eligible`, refs, downgrade reason and safe field lists; S005 still must migrate Flutter surfaces to consume them.
- No API contract drift blocker. OpenAPI includes `/goal-autopilot/progress-projection`, projection schemas/examples and a 401 response; generated Dart path registry includes `goalAutopilotProgressProjection`; manifest and marker hash are synced to `bed8ebbbe2d9fed907b7411fca512912f1302fbb73427e7783b4f7ae2d0678f8`.
- Fixed before close: the first S004 projection assertion expected `checkpoint_evidence_updated` after checkpoint replan, but the existing forecast policy correctly returns `forecast_supported` after a fresh replan. The test now checks checkpoint evidence through `latest_checkpoint.reason_code=checkpoint_updated_gap`, which better matches source ownership.
- Fixed before close: Redocly initially warned that the new projection endpoint lacked a 4XX response; the OpenAPI contract now declares `401 Unauthenticated`.
- Scope boundary is correct. S004 does not claim Home/Queue/Wiki UI propagation, deletion/unavailable downgrade across surfaces, p95 performance, final traceability script, release readiness, Product Base merge, Flutter source changes or live AI provider behavior.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionServiceTest,GoalAutopilotControllerTest#tcP02Fuc004ProjectionIsBackendOwned test` - passed after assertion correction.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalProgressProjectionServiceTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc004ProjectionIsBackendOwned test` - passed.
- `npm run check:api-contract` - passed. Historical note: Redocly reported nullable `$ref` warnings at S004 close; this was later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`.
- `npm run check:dart-client-drift` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Residual risk:
- Followup-C remains incomplete, not release-ready and not Product Base-ready.
- S005-S007 remain implementation gated, including Home/Queue/Wiki Flutter surface consumption, deletion/unavailable downgrade tests, p95 performance evidence and final traceability script.
- S004 uses deterministic backend policy only. Future provider-assisted wording must remain candidate-only and must not set projection state, surface eligibility, downgrade reason, source refs or claim guards.

## 2026-06-05 P02 Followup-C S003 Checkpoint Plan Update Independent Review

Review ID: `P02-FOLLOWUP-C-S003-CHECKPOINT-PLAN-UPDATE-20260605`

Result: pass for local S003 checkpoint-to-plan behavior after checkpoint result/status handling, replay audit evidence, OpenAPI/generated Dart drift, control/recovery compatibility, changed-code coverage and regression validation passed. This review does not approve S004-S007, release readiness or Product Base merge.

Findings:
- No blocker found for checkpoint result state handling. `POST /goal-autopilot/checkpoints` accepts omitted/recorded, failed and skipped result intents, derives low confidence from evidence quality, rejects invalid result status, and preserves unsupported/unavailable task rejection through the server-owned S002 task library.
- No blocker found for no-false-completion behavior. Low-confidence, failed and skipped checkpoint paths return conservative forecast/claim-guard output, do not expose precise ETA and do not emit `checkpoint_replan`; skipped checkpoints move forecast risk into recovery-required handling.
- No blocker found for control/recovery compatibility. Paused autopilot rejects checkpoint submission before persistence; recovery-required plans return `recovery_replan/recovery_required`; missing-plan/control-blocked accepted checkpoints return `stale_plan/control_blocked` instead of advancing next action silently.
- No blocker found for replay/audit evidence. S003 writes one `checkpoint_plan_update` `PlannerReplayAudit` per checkpoint submit with source checkpoint ref, redacted input snapshot hash, output hash, expected decision, reason code, rule version `fuc-checkpoint-plan-v1` and replay hash.
- No blocker found for data minimization. Checkpoint response and replay-audit response expose hashes and ids, while raw checkpoint transcript/audio values are not returned. The new replay test asserts learner transcript text is absent from the response.
- No API contract drift blocker. OpenAPI includes S003 `OutcomeCheckpoint` result/status fields and `PlanUpdateSignal` replay metadata, including `stale_plan`; generated Dart drift hash was synced to `226c6d86a691489c8c3cfeba8aa0735aae52aef12ce7d5d561cb46a56ce52860`.
- No test coverage blocker. TC-P02-FUC-007..009 cover accepted, low-confidence, failed, skipped, invalid status, paused, recovery-required and control-blocked branches; changed backend source coverage is line 98.4% and branch 92.0%.
- Scope boundary is correct. S003 does not claim backend goal-progress projection, Home/Queue/Wiki propagation, deletion/unavailable downgrade, p95 performance closure, final traceability script, release readiness, Product Base merge, Flutter surface changes or live AI provider behavior.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc003CheckpointUpdatesForecastAndPlanSignal test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CheckpointReplayAuditTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc003CheckpointRespectsControlAndRecoveryState test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc003CheckpointFailedSkippedAndBlockedBranches test` - passed after fixture correction.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,CheckpointReplayAuditTest test` - passed.
- `npm run check:api-contract` - passed. Historical note: Redocly reported nullable `$ref` warnings at S003 close; this was later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,CheckpointReplayAuditTest org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- Changed backend source coverage: line 98.4%, branch 92.0%.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Residual risk:
- Followup-C remains incomplete, not release-ready and not Product Base-ready.
- S004-S007 remain implementation gated, including backend projection, Home/Queue/Wiki surfaces, deletion/unavailable downgrade, p95 performance evidence and final traceability script.
- S003 uses deterministic backend policy only. Future provider-assisted checkpoint feedback must keep provider output candidate-only and rerun TC-P02-FUC-007..009 plus AI schema/eval gates.

## 2026-06-05 P02 Followup-C S002 Checkpoint Task Library Independent Review

Review ID: `P02-FOLLOWUP-C-S002-CHECKPOINT-TASK-LIBRARY-20260605`

Result: pass for local S002 checkpoint cadence/task-library behavior after deterministic policy, read-only API, submit validation, OpenAPI/generated Dart drift, coverage and regression validation passed. This review does not approve S003-S007, release readiness or Product Base merge.

Findings:
- No blocker found for deterministic checkpoint cadence. `CheckpointCadencePolicy` maps supported speaking goals to weekly/biweekly mock tasks, business goals to business tasks, recent checkpoint facts to not-due decisions, overdue backplan checkpoint facts to due decisions and unsupported goals to unavailable decisions under rule version `fuc-checkpoint-task-v1`.
- No blocker found for partial and cost-limited safety. Partial supported goals return limited biweekly/business task definitions, unsupported goals return no full task, and entitlement/quota/cost fallback inputs downgrade `ai_depth` to `deterministic_low_cost` without emitting official-score, completion-guarantee, entitlement, quota or commercial-provider claims.
- No blocker found for backend source-of-truth ownership. `GET /goal-autopilot/checkpoints/task` returns the server-owned checkpoint task decision, and checkpoint submission rejects unsupported goals or checkpoint types outside the server task library instead of accepting client-selected cadence/task truth.
- Fixed before close: independent review found the no-task response could serialize a nullable `task` property while the OpenAPI contract models `task` as optional. `CheckpointTaskDecisionDto` now omits null fields, and the controller regression asserts no `task` property is serialized for not-due or unsupported no-full-task responses.
- No blocker found for API and generated client alignment. OpenAPI includes the S002 task endpoint and schemas, API contract drift passed, and the generated Dart hash was synced to `3bacdd487b700676793dd2a2c4629d330079cf34dbf2f1e35f9ed46f8f166351`.
- No blocker found for AI and UX boundaries. S002 keeps task type, cadence, due state, AI depth, scoring boundary, entitlement, quota and cost facts deterministic and backend-owned; AI output and UI surfaces may render or phrase server facts but must not choose those fields locally.
- Scope boundary is correct. S002 does not claim checkpoint-to-plan mutation, Home/Queue/Wiki propagation, downgrade/data governance completion, p95 performance closure, release readiness, Product Base merge or Flutter surface changes.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CheckpointCadencePolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc002CheckpointTaskLibrary test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CheckpointCadencePolicyTest,ProgressForecastPolicyTest,ForecastExplanationSchemaTest,GoalAutopilotControllerTest#tcP02Fuc001ForecastHardeningClaimGuard+tcP02Fuc002CheckpointTaskLibrary+tcP02AutoCheckpoint001CheckpointUpdatesForecastAndStalesPlan test` - passed.
- `npm run check:api-contract` - passed. Historical note: Redocly reported nullable `$ref` warnings at S002 close; this was later fixed by `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606`.
- `flutter analyze lib/generated/api/speakeasy_api.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 95.7%, backend branch 80.8%, Flutter line 90.9%.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Residual risk:
- Followup-C remains incomplete, not release-ready and not Product Base-ready.
- S003-S007 remain implementation gated, including checkpoint-to-plan update, cross-surface propagation, downgrade/data governance, p95 performance evidence and final traceability script.
- The S002 service path currently uses deterministic local commercial/cost fallback facts because no live entitlement/quota/cost provider integration is in scope for this slice; any future provider or CMS-backed task-library change must rerun TC-P02-FUC-004..006, API drift and coverage gates.

## 2026-06-05 P02 Followup-C S001 Forecast Hardening Independent Review

Review ID: `P02-FOLLOWUP-C-S001-FORECAST-HARDENING-20260605`

Result: pass for local S001 forecast hardening after migration syntax and stale-plan precedence were fixed, and S001 tests, API contract drift, generated Dart analysis, controller regression and broad coverage gate passed. This review does not approve S002-S007, release readiness or Product Base merge.

Findings:
- No blocker found for deterministic forecast policy. `ProgressForecastPolicy` maps server-owned goal/plan/checkpoint facts to forecast state, source goal revision, ETA range/unavailable reason, confidence band, risk level, risk reason code, next checkpoint date, explanation metadata, rule version and claim guard.
- No blocker found for downgrade safety. Partial, unsupported, low-confidence, stale-plan, recovery-required, deleted and unavailable inputs suppress precise ETA claims and return limited/unavailable forecast states with explicit reasons.
- Fixed before close: independent review found `stale_plan` was evaluated after checkpoint/completed event reasons, allowing ETA under a stale plan. `ProgressForecastPolicy` now gives stale plan blocking precedence, and tests assert checkpoint/completed events cannot override it.
- No blocker found for API and persistence shape. `GoalProgressForecast`, migration `V202606050004__p0_2_followup_c_forecast_hardening.sql`, `GoalAutopilotService` and `GoalAutopilotController` persist and expose the hardened fields through existing forecast read paths without client-owned forecast writes.
- Fixed before close: the first migration used multi-column `ALTER TABLE ... ADD COLUMN` syntax that H2 rejected. The migration now uses one `ALTER TABLE ... ADD COLUMN` statement per added column, and the controller test passes against the migration.
- No blocker found for AI claim guard. `ForecastExplanationCandidateValidator` accepts safe candidate-only explanations and rejects forbidden persistent fields, direct ETA writes, entitlement/quota/provider state writes and official/completion/guaranteed-outcome claims. S001 executes deterministic no-provider fallback only.
- No OpenAPI/generated client drift blocker. `npm run check:api-contract` passed and generated Dart drift hash was synced to `617ce817ef055efb851641a1664211238229d9ed365e01711244da15a75c621c`; generated API analysis passed.
- Scope boundary is correct. S001 does not claim checkpoint cadence/task library, checkpoint-to-plan update, Home/Queue/Wiki propagation, deletion downgrade, p95 performance, coverage, release approval or Product Base merge.

Validation:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProgressForecastPolicyTest,ForecastExplanationSchemaTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fuc001ForecastHardeningClaimGuard test` - passed after migration syntax fix.
- `npm run check:api-contract` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProgressForecastPolicyTest,GoalAutopilotControllerTest#tcP02Fuc001ForecastHardeningClaimGuard,ForecastExplanationSchemaTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - failed once after stale-plan precedence fix because the older checkpoint regression expected checkpoint reason copy under stale plan; assertion was updated.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed after assertion update.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 95.8%, backend branch 80.6%, Flutter line 90.9%.
- `flutter analyze lib/generated/api/speakeasy_api.dart` - passed.
- `git diff --check` - passed.

Residual risk:
- Followup-C is not complete, not release-ready and not Product Base-ready.
- S002-S007 remain implementation gated, including surface propagation, downgrade/data governance, performance/coverage and final traceability script.
- Future live AI forecast explanations must keep the provider output candidate-only and rerun TC-P02-FUC-003 plus AI eval/schema gates.

## 2026-06-05 P02 Followup-C S000 Document Chain Independent Review

Review ID: `P02-FOLLOWUP-C-S000-DOCUMENT-CHAIN-20260605`

Result: pass for S000 documentation-chain closure. This review approves Followup-C requirements/spec/acceptance/test_cases/traceability readiness for routed implementation planning only. It does not approve S001-S007 implementation, release readiness or Product Base merge.

Findings:
- No blocker found for required document existence. `definition.md`, `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and `traceability.md` exist under `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`.
- No blocker found for slice granularity. S000-S007 map to the agreed plan: document chain, forecast hardening, checkpoint cadence/task library, checkpoint-to-plan update, backend projection, Home/Queue/Wiki propagation, downgrade/data governance and final performance/coverage/review gates.
- No blocker found for traceability. P02-FUC-FR-000..007 map to P02-FUC-SPEC-000..007, AC-P02-FUC-000..007, TC-P02-FUC-000..022 and P02-FUC-TR-000..007.
- No blocker found for Stage Scope and policy coverage. Followup-C preserves P02-SI-006, P02-SI-010, P02-SI-012 and P02-SI-013, and keeps P02-PG-001..005 visible in requirements, acceptance and traceability.
- No blocker found for scope boundary. Followup-C explicitly excludes Followup-A GoalProfile/Diagnostic work, Followup-B control/planner/memory/mastery work and Followup-D release/commercial/Product Base gates.
- No blocker found for status accuracy. S000 is marked as documentation validation only; S001-S007 contract/code/test/performance/coverage evidence remains planned or not started.

Validation:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces docs/reports/quality_report.md` - passed.

Residual risk:
- S001-S007 implementation has not started.
- `scripts/check_p0_2_followup_c_traceability.py` is planned for S007 and does not exist yet.
- Domain/API/OpenAPI/AI/UX contracts must be routed per slice before implementation completion when required.
- Followup-C is not release-ready and Product Base merge is not approved.

## 2026-06-05 P02 Followup-B S006 Replay Performance Traceability Independent Review

Review ID: `P02-FOLLOWUP-B-S006-REPLAY-PERFORMANCE-TRACEABILITY-20260605`

Result: No blocker for local S006 closure of TC-P02-FUB-015, TC-P02-FUB-016 and TC-P02-FUB-017 after coverage-support tests were added and reports were synchronized. This Independent Review does not approve release readiness or Product Base merge. Followup-B is not release-ready. Product Base merge is not approved.

Findings:
- No blocker found for TC-P02-FUB-015 replay fixture coverage. `GoalAutopilotReplayFixtureTest` covers FUB-FIX-001..008 decision families and asserts expected decision, reason code, output state, rule version and replay hash evidence where persisted replay audits exist.
- No blocker found for TC-P02-FUB-016 performance coverage. `GoalAutopilotControlPerformanceTest` measures local p95 budgets for control state load, control commands, notification eligibility, outbox lifecycle, missed-day recovery, 500-item memory due calculation, mastery transition and replay verification.
- No blocker found for TC-P02-FUB-017 traceability gate. `scripts/check_p0_2_followup_b_traceability.py` validates required files, TC rows, traceability rows, report terms and forbidden release/Product Base claims; `scripts/check_p0_2_goal_autopilot_coverage.py` validates refreshed coverage.
- Fixed before close: refreshed full JaCoCo initially showed backend branch coverage below the broad P0.2 gate. Additional test-only branch coverage was added for existing memory, recovery and mastery policy/validator branches; final coverage passed at backend line 95.9%, backend branch 81.4% and Flutter line 90.9%.
- No production backend or Flutter code changed in S006. The added coverage-support tests exercise existing deterministic policy branches and do not alter runtime behavior.
- Scope boundary is correct. S006 closes local replay/performance/coverage/traceability evidence only; it does not claim external release, store/commercial readiness, Product Base merge, Followup-C or Followup-D completion.

Validation:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `npm run check:api-contract` - passed.
- `git diff --check` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotReplayFixtureTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControlPerformanceTest test` - passed.
- `python3 -m py_compile scripts/check_p0_2_followup_b_traceability.py` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest,MissedDayRecoveryPlannerTest,MasteryTransitionPolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 95.9%, backend branch 81.4%, Flutter line 90.9%.

Residual risk:
- Followup-B is not release-ready.
- Product Base merge is not approved.
- Future production backend, Flutter, API, AI or release changes must rerun the relevant contract, coverage, replay and quality gates before any broader approval can be claimed.

## 2026-06-05 P02 Followup-B S005 Mastery Transition Independent Review

Result: pass for TC-P02-FUB-013 and TC-P02-FUB-014 after replay output-hash determinism fix. Not full Followup-B completion, not global replay/performance closure, not release approval and not Product Base merge approval.

Findings:
- Fixed before close: `GoalAutopilotService#writeMasteryTransitionReplay` initially included random `transition_id` in the replay output hash. The output hash now uses deterministic transition fields only, and `GoalAutopilotControllerTest#tcP02Fub013MasteryTransitionAuditIsReadOnlyAndReplayable` asserts duplicate same-input completion does not create additional mastery transition or replay audit rows.
- No blocker found for deterministic mastery policy. `MasteryTransitionPolicyTest` covers one-level promotion cap, L0-L5 confidence threshold behavior, low-confidence hold, insufficient-evidence hold, partial/unsupported hold, fatigue-protected hold, retrieval regression, repeated failure and checkpoint regression.
- No blocker found for AI persistent-field guardrails. `MasteryTransitionExplanationValidator` rejects forbidden persistent fields, unsafe official-score/goal-completion claims and candidate mismatches, and returns `mutatesPersistentState=false` for both accepted and rejected candidates.
- No blocker found for persistence and deletion governance. `goal_mastery_transition_decisions` stores user/goal/revision/item, previous/proposed/accepted level, direction, evidence refs, confidence, reason code, rule version and input snapshot hash with a unique idempotency key; account deletion now purges the table.
- No blocker found for read-only API exposure. `GET /goal-autopilot/mastery-transitions` returns transition metadata without accepting client writes, and the existing replay-audit API exposes `mastery_transition` hash evidence.
- No API drift blocker. The mastery transition endpoint already existed in OpenAPI; S005 implemented the backend endpoint without OpenAPI or generated Dart drift, and `npm run check:api-contract` plus `npm run check:dart-client-drift` passed.
- Scope boundary is correct. S005 does not claim global replay corpus, p95 performance budgets, dedicated Followup-B traceability script, Flutter UI changes, official-score certification or release approval.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest test` - red step failed before implementation with missing policy/validator classes, then passed after implementation.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,AccountDeletionLearningDataTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest,GoalAutopilotControllerTest test` - passed after replay output-hash fix.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MasteryTransitionPolicyTest,GoalAutopilotControllerTest,FoundationMigrationTest,AccountDeletionLearningDataTest test` - passed.
- `npm run check:api-contract` - passed.
- `npm run check:dart-client-drift` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `git diff --check` - passed.

Residual risk:
- At S005 close, TC-P02-FUB-015 global replay fixture, TC-P02-FUB-016 p95 performance budgets and TC-P02-FUB-017 dedicated Followup-B traceability script still needed later closure; S006 above later closed those local gates.
- S005 persists transition decision history; it does not update a user-facing mastery UI state or certify official exam readiness.

## 2026-06-05 P02 Followup-B S004 Item-Level Memory Independent Review

Result: pass for TC-P02-FUB-011 and TC-P02-FUB-012 after replay-determinism and not-due `next_due_at` fixes. Not full Followup-B completion, not global replay/performance closure, not release approval and not Product Base merge approval.

Findings:
- Fixed before close: `GoalAutopilotService#itemPolicyDecisions` initially used sub-day `Instant.now` for memory `next_due_at`, so two identical same-day replay requests produced different output hashes. The service now evaluates item policy at day-level granularity and includes `evaluated_at` in the input snapshot while keeping audit creation time out of the replay hash.
- Fixed before close: `review_not_due.next_due_at` initially reset the default interval from the evaluation day. `MemoryCurvePolicy` now returns the existing due date from `last_reviewed_at + default interval`, and `MemoryCurvePolicyTest` asserts the not-due interval output.
- No blocker found for item-level decision coverage. `MemoryCurvePolicyTest` covers high risk `>=0.70`, due risk `>=0.45`, retrieval failure, retrieval success not-due, recent failure override, default intervals, overlearning cap, interleaving cap and daily memory budget defer.
- No blocker found for control ownership. Paused and policy-blocked control states return `blocked_by_control`, and `MemoryCurveReplayTest` verifies pause through server-owned `/goal-autopilot/control/pause` rather than a client-supplied override.
- No blocker found for replay audit determinism. The item-policy endpoint writes `item_policy` replay audit rows with deterministic input/output/replay hashes, expected decision, reason code and `memory-curve-v1`; same request on the same evaluation day returns identical decisions and replay hash.
- No API contract drift blocker. `POST /goal-autopilot/item-policy/decisions` already existed; OpenAPI was extended for S004 by adding optional `MemoryItemPolicyInput` evidence fields while preserving the existing item-ref fallback, and `npm run check:api-contract` passed after generated Dart hash sync.
- Scope boundary is correct. No L0-L5 mastery transition, global replay fixture, performance gate, Flutter UI or AI runtime behavior is claimed in this slice.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -DskipTests compile` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest,MemoryCurveReplayTest test` - passed after replay-determinism fix.
- `npm run check:api-contract` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MemoryCurvePolicyTest,MemoryCurveReplayTest,GoalAutopilotControllerTest,GoalAutopilotRecoveryControllerTest test` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `git diff --check` - passed.

Residual risk:
- At S004 close, item-level memory p95 performance for 500 items still needed TC-P02-FUB-016; S006 above later closed that local performance gate.
- At S004 close, L0-L5 transition, global replay fixtures, dedicated Followup-B traceability script and final Followup-B review were still later-slice work; S005 and S006 above later closed those local gates.

## 2026-06-05 P02 Followup-B S003 Missed-Day Recovery Independent Review

Result: pass for TC-P02-FUB-009 and TC-P02-FUB-010 after one service-consistency fix. Not full Followup-B completion, not global replay/performance closure, not release approval and not Product Base merge approval.

Findings:
- Fixed before close: `GoalAutopilotService#applyRecoveryPlan` initially capped the generated recovery daily plan from `GoalProfile.intensityPreference` while the planner decision used server-owned `UserAutopilotControl.intensityOverride`. The application path now receives the control intensity as the same fact source, preserving Followup-B server-control ownership.
- Fixed before close: the internal control data-governance export listed the new `goal_recovery_plan_decisions` data class but still reported the S002-B status marker. It now reports `implemented_through_s003_recovery`, and the control governance regression asserts the recovery decision retention/deletion table entry.
- No blocker found for deterministic recovery mode selection. `MissedDayRecoveryPlannerTest` covers hard safety/feasibility override, fatigue replacement, user policy preference, `balanced` defer-before-compress behavior and compress daily budget cap.
- No blocker found for no-overdue-stacking behavior. `GoalAutopilotRecoveryControllerTest` proves recovery creates one bounded active recovery block, leaves source plans stale and does not move all source plan items into the next day.
- No blocker found for persistence and replay. Recovery decisions persist in `goal_recovery_plan_decisions` with input snapshot hash, affected refs, source event, reason code and `fub-recovery-v1`; replay audit writes `missed_day_recovery` decision evidence and idempotent replay returns the same decision/daily plan.
- No API drift blocker. `/goal-autopilot/recovery/replan` already existed in OpenAPI/generated client contract; implementing the backend endpoint did not require contract changes, and `npm run check:api-contract` passed.
- No deletion-retention blocker found. Account deletion and test cleanup now remove `goal_recovery_plan_decisions`, and control governance export records the recovery decision data class.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MissedDayRecoveryPlannerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotRecoveryControllerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide test` - passed after S003 governance status-marker fix.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MissedDayRecoveryPlannerTest,GoalAutopilotRecoveryControllerTest,GoalAutopilotControllerTest,NotificationEligibilityPolicyTest,NotificationOutboxServiceTest,NotificationOutboxReplayTest test` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed: backend line 96.3%, backend branch 88.6%, Flutter line 90.9%.
- `git diff --check` - passed.

Residual risk:
- `mvn jacoco:report` cannot refresh coverage because the backend project does not configure a resolvable `jacoco` Maven plugin prefix; the accepted coverage evidence for this slice is the existing project coverage script result above.
- At S003 close, recovery p95 performance still needed TC-P02-FUB-016; S006 above later closed that local performance gate.
- At S003 close, item-level memory, mastery transition, global replay fixtures, dedicated Followup-B traceability script and final Followup-B review were still later-slice work; S004/S005/S006 above later closed those local gates.

## 2026-06-05 P02 Followup-B S002-B Notification Outbox Independent Review

Result: pass for TC-P02-FUB-007 and TC-P02-FUB-008 after one lifecycle-boundary fix. Not full Followup-B completion, not external notification delivery approval, not release approval and not Product Base merge approval.

Findings:
- Fixed before close: `NotificationOutboxService#markScheduled` could have moved non-pending records such as `blocked` or `cancelled` directly to `scheduled`, bypassing the intended eligibility/cancel/reschedule paths. The service now only schedules `pending` records, treats already `scheduled`/terminal records idempotently and raises `CONFLICT` for non-schedulable states; regression assertions cover blocked and cancelled records in `NotificationOutboxServiceTest`.
- No blocker found for stable dedupe and lifecycle coverage. TC-P02-FUB-007 proves one record per dedupe key and covers `pending`, `scheduled`, `blocked`, `cancelled`, `failed`, `expired` and `sent` transitions plus cancel/reschedule and retry/failure recovery.
- No blocker found for redacted payload projection. Outbox and replay API projections expose hashes for input/output/payload/replay fields, and controller regression asserts the raw reminder explanation key is not returned.
- No blocker found for replay audit determinism. TC-P02-FUB-008 verifies `notification_outbox` decision family, `outbox:<id>` source references, deterministic hash fields, expected decisions and duplicate scheduling without duplicate replay rows.
- No deletion-retention blocker found. Governance export lists `goal_notification_outbox_records` and `goal_planner_replay_audits`, and account deletion purges both tables.
- No OpenAPI drift blocker. The OpenAPI schema/example and generated Dart hash artifacts were synced after the outbox projection shape changed.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationOutboxServiceTest,NotificationOutboxReplayTest test` - red step failed before implementation with missing outbox service/repository/replay audit classes.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationOutboxServiceTest,NotificationOutboxReplayTest,NotificationEligibilityPolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub007OutboxAndReplayApisExposeRedactedProjection test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,AccountDeletionLearningDataTest,TrainingAccountDeletionRetentionTest test` - passed.
- `npm run check:api-contract` - passed after OpenAPI/example/hash sync.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `flutter analyze lib/generated/api/speakeasy_api.dart` - passed.
- `git diff --check` - passed.

Residual risk:
- External platform notification delivery, scheduler deployment evidence and production notification provider behavior are not claimed by this local outbox lifecycle slice.
- Missed-day recovery, item-level memory, mastery transition, global replay fixtures, performance budgets, changed-code coverage evidence, dedicated Followup-B traceability script and final Followup-B review remain open.

## 2026-06-05 P02 Followup-B S002-A Notification Eligibility Independent Review

Result: pass for TC-P02-FUB-005 and TC-P02-FUB-006. Not full Followup-B completion, not scheduler/outbox approval, not release approval and not Product Base merge approval.

Findings:
- No blocker found for backend reason precedence. `NotificationEligibilityPolicy` returns the first matching reason in the requested S002-A order: paused, blocked-by-policy, unsupported goal, partial-goal-limited, stale plan, missing plan, consent missing, permission denied, entitlement blocked, quota exhausted, quiet hours, eligible.
- No blocker found for quiet-hours evaluation. Same-day windows, cross-midnight evening/morning windows and start=end disabled behavior are covered by deterministic unit tests with explicit `next_allowed_at` assertions.
- No blocker found for current control-response integration. `GoalAutopilotService` routes reminder eligibility through the policy, preserves rule-versioned decision IDs and distinguishes `stale_plan` from `missing_plan`.
- No blocker found for Flutter display behavior. The adapter widget renders server-supplied `quiet_hours`, `permission_denied`, `entitlement_blocked` and `quota_exhausted` reasons without treating blocked or unsent reminders as completion.
- No API contract drift blocker. `NotificationEligibilityDecision.reason_code` includes `blocked_by_policy`; OpenAPI contract and generated Dart drift gates passed.
- Scope boundary is correct. Scheduler/outbox lifecycle remains TC-P02-FUB-007/008 planned and was not implemented or claimed by this review.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=NotificationEligibilityPolicyTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart --name "Followup-B shows quiet-hours and notification blocked reasons without treating them as completion"` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter analyze test/features/goal_autopilot/goal_autopilot_adapter_test.dart lib/generated/api/speakeasy_api.dart` - passed.
- `npm run check:api-contract` - passed.
- `git diff --check -- <S002-A touched files>` - passed.
- Independent review agent `019e9539-d6a3-79b3-8117-25a45a0dd7fd` - passed with no findings and no open questions for TC-P02-FUB-005/006.

Residual risk:
- Runtime platform permission, entitlement and quota signal plumbing is still future integration work. The current control-response path feeds those fields as allowed while `NotificationEligibilityPolicyTest` covers the deterministic decision table and Flutter covers server-supplied blocked reason display.
- Notification scheduler/outbox lifecycle, outbox replay and notification send records remain TC-P02-FUB-007/008 planned and must be executed in a separate slice.

## 2026-06-05 P02 Followup-B TC-002 Control Governance Independent Review

Result: pass for TC-P02-FUB-002 and P02-FUB-GAP-001 S001 control data-governance closure. Not full Followup-B completion, not release approval and not Product Base merge approval.

Findings:
- No blocker found for server validation. TC-P02-FUB-002 still rejects invalid quiet hours, timezone, intensity override and missed-day policy before persisting control changes.
- No blocker found for current control data export governance. `GoalAutopilotService#exportControlDataGovernance` returns a read-only internal snapshot covering control records, user/goal references, status, quiet hours, notification consent, missed-day policy, rule version and timestamps.
- No sensitive-data blocker found. Idempotency evidence is limited to request hash and metadata; raw idempotency key and stored response JSON are marked redacted, and audit details assert redaction rather than leaking sensitive control payloads.
- No deletion-retention blocker found for current S001 data classes. Account deletion purges `goal_autopilot_controls` and `goal_autopilot_control_idempotency`; retention rules explicitly record hard deletion for those tables and redacted minimal audit retention.
- No API contract drift blocker. No external endpoint or generated Dart client changed; this closure uses an internal service boundary and backend integration tests.
- Residual scope is correctly routed. Notification scheduler/outbox records do not exist in S001 and remain planned under TC-P02-FUB-007/008, so TC-P02-FUB-002 closure does not claim outbox implementation.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide test` - red step failed before implementation with missing `exportControlDataGovernance(UUID)`.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest#tcP02Fub002ControlDataGovernanceAndValidationAreServerSide test` - passed after implementation.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,AccountDeletionLearningDataTest,TrainingAccountDeletionRetentionTest test` - passed.
- `git diff --check -- backend/src/main/java/com/speakeasy/goal/GoalAutopilotService.java backend/src/main/java/com/speakeasy/goal/GoalAutopilotControlRepository.java backend/src/main/java/com/speakeasy/goal/GoalAutopilotControlIdempotencyRepository.java backend/src/main/java/com/speakeasy/goal/GoalAutopilotControlIdempotency.java backend/src/test/java/com/speakeasy/GoalAutopilotControllerTest.java` - passed.

Residual risk:
- Scheduler/outbox, recovery, memory, mastery, replay, performance, coverage, dedicated traceability script and final Followup-B review remain open.
- No external user-facing export endpoint was added in this slice; future release data-export UI/API remains Followup-D/commercial data-governance work.

## 2026-06-05 P02 Followup-B Policy Table Routing Independent Review

Result: pass for documentation readiness and implementation-slice routing. Not code implementation approval, not executed runtime test evidence, not release approval and not Product Base merge approval.

Findings:
- No target-drift blocker. Followup-B remains scoped to control, notification, recovery, item-level memory, L0-L5 transition and replay/performance gates; it still excludes Followup-A/C/D scope.
- No ID stability blocker. FR-P02-FUB-001..008, P02-FUB-SPEC-001..008, AC-P02-FUB-001..008 and TC-P02-FUB-001..017 were not renumbered or expanded.
- No content-boundary blocker. `spec.md` now defines behavior-level slice routing and deterministic policy tables without writing code implementation details.
- No AC/TC blocker. `acceptance.md` and `test_cases.md` now map P02-FUB-SLICE-001..006 to FUB-FIX-001..009 and preserve AC-to-TC coverage.
- TC format issue found and fixed in that audit. Historical note: `TC-P02-FUB-002` used an unresolved result status while preserving partial validation/deletion cleanup evidence at that time; it is superseded by the 2026-06-05 TC-002 control governance closure above.
- Traceability now records policy-table-to-fixture routing and keeps TR-004..009 planned/open.

Validation:
- `git diff --check -- docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/requirements.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/spec.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/acceptance.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/test_cases.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/traceability.md docs/reports/test_report.md docs/reports/quality_report.md` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `npm run check:api-contract` - passed.
- Followup-B TC enum audit - passed for test layer, automation status and result status.

Residual risk:
- The routing update makes remaining slices more implementation-ready but does not execute TC-P02-FUB-005..017.
- Dedicated scheduler/outbox, recovery, memory, mastery, replay, performance, coverage and traceability-script implementation still must be completed and independently reviewed.

## 2026-06-04 P02 Followup-B Control Slice Documentation Reconciliation

Result: conditional pass for documentation-chain reconciliation and control-slice evidence sync. Not a full Followup-B completion approval, not release approval and not Product Base merge approval.

Findings:
- Followup-B scope remains correctly bounded to P02-SI-001/002/003/004/005/009/010/011. P02-SI-007/008 remain Followup-A upstream inputs, and P02-SI-006/012/013 remain Followup-C scope.
- Requirements, spec and acceptance status text no longer claims downstream artifacts do not exist; they now record contract-ready plus partial control-slice execution.
- TC-P02-FUB-001, TC-P02-FUB-003 and TC-P02-FUB-004 now point to actual executed files and method/name selectors. Historical note: TC-P02-FUB-002 recorded only the executed validation/deletion-cleanup subset in this earlier reconciliation; it is now closed for current S001 control data governance.
- Domain/API/AI TC mappings were realigned: item-level memory maps to TC-P02-FUB-011..012 plus replay support, mastery transition maps to TC-P02-FUB-013..014 plus replay support, and replay audit maps to TC-P02-FUB-015..017.
- Traceability rows P02-FUB-TR-001 and P02-FUB-TR-002 now contain concrete code and test evidence. P02-FUB-TR-003 is marked partial support only; P02-FUB-TR-004..009 remain planned/open.

Residual risk:
- The control slice does not close notification scheduler/outbox, quiet-hours across midnight, platform permission, entitlement/quota, missed-day recovery, item-level memory, L0-L5 transition, replay fixture, performance budget, coverage or final traceability script gates.
- Followup-B must not be marked complete until TC-P02-FUB-005..017 are executed or explicitly replaced by approved equivalents, including notification outbox governance through TC-P02-FUB-007/008.

## 2026-06-04 P02 Followup-B Pre-implementation Reporting Gate Note

Result: pass for reporting/status reconciliation scope only. Not code implementation approval, not executed test evidence, not release approval and not Product Base merge approval.

Findings:
- Followup-B is no longer scaffold-only. Its pre-implementation product docs and required contracts have been created or updated and independently reviewed.
- PM status now records Followup-B as documentation/contract-ready while keeping code, executable tests, performance, coverage and release evidence gated.
- TC-P02-FUB-017 historically distinguished the then-missing `scripts/check_p0_2_followup_b_traceability.py` implementation-completion deliverable from the pre-implementation equivalent routing gate; S006 above later created and ran the script.
- No blocker remains in this reporting/status step for asking Development Orchestrator to route the smallest implementation slice.

Validation:
- `git diff --check -- docs/product/development_status.md docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/definition.md` - passed.
- `git diff --check -- docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/test_cases.md docs/reports/test_report.md` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- Followup-B PM status reconciliation independent checker - passed.
- Followup-B Test Case Development reconciliation independent checker - passed.

Residual risk:
- Followup-B executable backend/Flutter/AI tests, the dedicated traceability script or approved implementation equivalent, coverage evidence, performance evidence, implementation report, test evidence and final quality review remain open.
- Followup-B must not be marked implemented, test-passing, release-ready or Product Base-ready until those execution gates are produced and independently reviewed.

## 2026-06-04 P02 Followup-A No-goal Explore Mode Implementation Independent Review

Result: pass for local Followup-A FR-009 implementation and traceability. Not a full P0.2 release approval, not Product Base merge approval and not commercial launch approval.

Findings:
- No blocker found for no-active-goal entry. `GoalAutopilotPanel` now renders `No active goal` with `Set a goal`, `Explore practice` and `Try a sample drill` instead of opening the GoalProfile form by default.
- No blocker found for explicit goal creation. `Set a goal` opens the editable intake form but does not call create-goal transport or `createDefaultGoal()` before valid submit.
- No blocker found for Explore Mode isolation. `Explore practice` renders ordinary sample drill feedback and does not call create/generate-plan/complete/checkpoint/forecast/memory goal-autopilot operations beyond the initial summary lookup.
- No prohibited claim blocker found. Explore Mode does not render target gap, ETA, achieved-goal, guaranteed outcome, official-score-equivalence or next autopilot/memory item copy.
- No coverage blocker. `scripts/check_p0_2_goal_autopilot_coverage.py` passed with backend line 96.3%, backend branch 88.6% and Flutter feature line 90.9%.
- No traceability blocker. `P02-FUA-TR-009` now has code evidence, executed TC-P02-FUA-014..016 evidence and strengthened traceability-script coverage.

Validation:
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter analyze lib/features/goal_autopilot lib/services/api_client.dart lib/pages/home_page.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- <Followup-A FR-009 changed files>` - passed.
- Followup-A FR-009 touched-file whitespace audit - passed.

Residual risk:
- Followup-A still does not implement a full Explore Practice content library; FR-009 intentionally implements the no-goal boundary and sample drill entry only.
- Followup-B/C/D remain open and must not inherit Followup-A's local pass status.

## 2026-06-04 P02 Followup-A No-goal Explore Mode Requirement/Test Documentation Review

Superseded status note: this documentation-only review is superseded by the implementation review above, where FR-009 code and TC-P02-FUA-014..016 passed locally.

Result: pass for documentation addendum and traceability readiness. Not a code implementation approval, not executed test evidence and not release approval.

Findings:
- Current Followup-A docs did not fully cover users who browse without setting a goal. The previous no-active-goal flow routed directly to editable goal intake, which could mislead later implementation toward default or forced GoalProfile creation.
- No documentation blocker remains for the no-goal boundary. `P02-FUA-FR-009`, `P02-FUA-SPEC-009`, `AC-P02-FUA-009`, `TC-P02-FUA-014..016` and `P02-FUA-TR-009` now define empty state, `Set a goal` transition, Explore/sample entry and goal-autopilot fact isolation.
- The addendum explicitly prohibits creating or persisting GoalProfile, DiagnosticAssessment, ProgressForecast, GoalBackplan, DailyPlan, AutopilotAction or MemoryCurve schedule during no-goal browsing.
- The addendum requires casual practice evidence to remain ordinary practice/session evidence and blocks goal gap, ETA, forecast, achieved-goal, guaranteed outcome and official-score-equivalence copy in Explore Mode.
- Historical note from this documentation-only review: prior local Followup-A implementation evidence covered only FR-001..008 at that time. This is superseded by the implementation review above, where FR-009 code and TC-P02-FUA-014..016 passed locally.

Validation:
- Followup-A No-goal Explore Mode document audit - passed.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- `git diff --check -- docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening docs/reports/quality_report.md docs/reports/test_report.md scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- Followup-A no-goal touched-file whitespace audit - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Residual risk:
- Historical note from this documentation-only review: no code had been changed for FR-009 in that earlier step. This is superseded by the implementation review above.

## 2026-06-04 P02 Followup-A Local Implementation Independent Review

Result: pass for local Followup-A implementation and traceability. Not a full P0.2 release approval, not Product Base merge approval and not commercial launch approval.

Findings:
- No blocker found for P02-FUA-FR-001 editable intake. Production `GoalAutopilotPanel` now renders editable GoalProfile fields and calls `widget.adapter.createGoal`; strengthened traceability check fails if the production panel calls `createDefaultGoal()`.
- No blocker found for P02-FUA-FR-003/P02-FUA-FR-004 diagnostic sample handling. `GoalDiagnosticSampleInput` provides a typed input boundary, adapter filters empty samples, preserves stable refs and does not send fake `audio_ref`.
- No blocker found for P02-FUA-FR-002/P02-FUA-FR-006 support and claim boundaries. Flutter parses `support_decision`, diagnostic sample/confidence facts and diagnostic/forecast claim guards; unsupported goals hide Generate plan/Checkpoint/Done, partial/low-confidence states show limitation copy, and guarded copy is sanitized away from official-score/guaranteed outcome wording.
- No blocker found for P02-FUA-FR-005 revision/stale behavior. Flutter exposes revision, blocks stale/blocked next actions and sends force replan recovery instead of auto-executing, notifying or reordering memory queue.
- No coverage blocker. `scripts/check_p0_2_goal_autopilot_coverage.py` passed with backend line 96.3%, backend branch 88.6% and Flutter feature line 90.5%.
- No traceability blocker. `scripts/check_p0_2_goal_autopilot_traceability.py` now covers Followup-A docs, code and test names in addition to the earlier P0.2 vertical slice evidence.

Validation:
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter analyze lib/features/goal_autopilot lib/services/api_client.dart lib/pages/home_page.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository org.jacoco:jacoco-maven-plugin:0.8.12:prepare-agent -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test org.jacoco:jacoco-maven-plugin:0.8.12:report` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Residual risk:
- Followup-A did not implement production audio capture, paid AI diagnostic calibration or commercial entitlement/cost behavior.
- Followup-B/C/D remain open and must not inherit Followup-A's local pass status.

## 2026-06-04 P02 Followup-A Requirements Spec AC TC Traceability Independent Review

Result: pass for Followup-A documentation readiness and code-routing gate. Not a code implementation approval, not executed test evidence and not release approval.

Findings:
- Requirements review passed. `P02-FUA-FR-001` through `P02-FUA-FR-008` map to `P02-FUA-WP-001` through `P02-FUA-WP-008`, include P02-SI-007/P02-SI-008/P02-SI-009 coverage, and include all five policy gates P02-PG-001 through P02-PG-005. A real gap was found and fixed during review: Followup-A initially omitted P02-PG-003, so definition and requirements now explicitly state revision/stale visibility must not auto-execute, notify or reorder memory queue before Followup-B.
- Spec review passed. `P02-FUA-SPEC-001` through `P02-FUA-SPEC-008` define editable GoalProfile intake, SupportedGoalMatrix pre-plan state, diagnostic sample capture, candidate-only transport, revision/stale visibility, claim guard copy, coverage/performance gates and independent review evidence.
- Acceptance review passed. `AC-P02-FUA-001` through `AC-P02-FUA-008` are observable pass/fail criteria covering form validation, custom payload, sample filtering, supported/partial/unsupported gating, low-confidence downgrade, prohibited claims, stale-plan recovery, coverage, performance and traceability.
- Test case review passed. `TC-P02-FUA-001` through `TC-P02-FUA-013` map every AC to stable widget/adapter/model/backend-regression/coverage/performance/traceability checks. All Followup-A test results remain `planned`; no unexecuted pass is claimed.
- Traceability review passed. `P02-FUA-TR-001` through `P02-FUA-TR-008` now include Stage Scope ID, Policy Gate, WP, FR, Spec, AC, TC, contract evidence, planned code evidence, planned test evidence, review gate and status. Gap register entries identify exactly what code must close.

Validation already performed:
- Requirements audit - passed after P02-PG-003 correction.
- Definition policy-gate audit - passed after P02-PG-003 correction.
- Spec audit - passed.
- Acceptance audit - passed after replacing ambiguous future-closeout wording that could be misread as implementation evidence.
- Test case audit - passed.
- Traceability audit - passed.

Final validation before code:
- `git diff --check -- docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening docs/reports/quality_report.md` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- Followup-A FR/Spec/AC/TC/traceability chain audit - passed.

Residual risk:
- Followup-A code has not started. Current local Flutter still has the known gaps: default-goal-only setup, hard-coded diagnostic samples, under-parsed summary fields and incomplete partial/unsupported/revision UI gating.
- Followup-B/C/D remain scaffold-only and must not be treated as implementation-ready.

## 2026-06-04 P02 Followup A-D Definition And WP Traceability Scaffold Independent Review

Result: pass for formal follow-up path setup and WP-level traceability scaffold. Not a requirements/spec/acceptance/test_cases approval, not code implementation approval and not release approval.

Findings:
- No path-governance blocker. Four canonical increment paths now exist under `docs/product/increments/`: `p0-2-followup-a-goal-intake-diagnostic-hardening`, `p0-2-followup-b-autopilot-control-planner-memory`, `p0-2-followup-c-checkpoint-forecast-surfaces` and `p0-2-followup-d-release-gate-hardening`.
- No traceability-scaffold blocker. Every follow-up has stable WP IDs, mapped Stage Scope IDs, mapped P02-PG policy gates, explicit upstream rows, required downstream artifacts, contract impact, code evidence status, test evidence status and review gate.
- No scope-regression blocker. Followup-A owns editable GoalProfile and diagnostic hardening; Followup-B owns autopilot control, notification semantics, planner/memory and L0-L5 transition hardening; Followup-C owns checkpoint, forecast and Home/Queue/Wiki projection; Followup-D owns release, commercial, cost, data, telemetry and Product Base/release gates.
- Implementation remains blocked. The scaffold explicitly states requirements/spec/acceptance/test_cases are not started for A-D and code evidence is `Not started`, preventing the previous local deterministic slice from being mistaken for full P0.2 completion.

Validation:
- P02 Followup path audit - passed.
- P02 Followup WP ID and policy-gate audit - passed.
- Stage/roadmap/development-status/feature-registry reference audit - passed.
- `git diff --check -- <modified P0.2 product status docs>` - passed.
- Followup new-file non-empty and trailing-whitespace audit - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Residual risk:
- A-D still need full requirements/spec/acceptance/test_cases generation and independent review before any code changes.
- Product Base merge, commercial release, paid AI external evidence and official-score-equivalence claims remain blocked.

## 2026-06-04 P02 Goal Autopilot Local Implementation Independent Review

Result: conditional pass for the local deterministic implementation slice. Not a Product Base merge approval and not a commercial release approval.

Findings:
- No coverage blocker remains for the implemented local slice. `scripts/check_p0_2_goal_autopilot_coverage.py` passed with backend changed-code line 96.3%, backend branch 88.6% and Flutter feature line 82.1%. Dart coverage tooling does not emit branch coverage, so Flutter branch coverage is not separately measurable by the local toolchain.
- Product-scope blocker. The Flutter surface currently starts a compact default IELTS goal rather than exposing the full editable `GoalProfile` intake fields for goal type, target score/ability, deadline, daily available time and intensity preference. Backend contracts support these fields, but the user-facing setup is incomplete.
- Superseded product-scope note. At the time of this local deterministic slice review, pause/resume endpoints were not implemented. This is now partially superseded by `P02-FOLLOWUP-B-CONTROL-SLICE-20260604`, where pause/resume/update-control backend behavior and Flutter binding passed target tests; production notification scheduling and full Followup-B control completion remain open.
- Product-scope blocker. Progress evidence is surfaced on the Home learn tab only. The required Home/Queue/Wiki surface propagation is not yet complete because Queue/Wiki propagation remains future work; Followup-C S005 now requires all three surfaces for full local closure.
- No local code blocker found in the implemented deterministic backend/API/Flutter slice after review. The implemented service/controller/adapter tests cover supported-goal routing, diagnostic facts, plan generation, memory policy, next action, checkpoint forecast update, deletion cleanup and OpenAPI path drift.

Validation:
- `npm run check:api-contract` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=FoundationMigrationTest,GoalAutopilotControllerTest,GoalAutopilotPerformanceTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `flutter analyze lib/features/goal_autopilot lib/services/api_client.dart lib/pages/home_page.dart test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- Backend JaCoCo command - passed and generated `backend/target/site/jacoco/jacoco.csv`.
- `flutter test --coverage test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed and generated `coverage/lcov.info`.
- `python3 scripts/check_p0_2_goal_autopilot_coverage.py` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.

Seven-defect closure review after implementation:
- 达标判定与承诺边界：implemented locally through supported-goal fail-closed behavior, confidence, claim guard and no official-score-equivalence claim; paid/external certification evidence remains outside release.
- 诊断可信度：implemented locally through deterministic rubric/weakness decomposition, confidence and L0-L5 initial mastery seed; real speech/audio diagnostic calibration remains a later AI/runtime evidence gate.
- 自动带练过度自动化：partially implemented through next-action orchestration, completion recovery and user-visible checkpoints; pause/resume and notification scheduling remain blockers.
- 商业边界不足：partially implemented by fail-closed unsupported goals and no paid-AI claim; entitlement/cost telemetry remains a release blocker.
- 计划引擎可执行约束不足：implemented locally through weekly/daily plan generation, memory policy and performance tests; full adaptive workload tuning remains future work.
- 内容覆盖与目标类型未绑定：implemented locally through supported/partial/unsupported goal matrix; broader task/content libraries remain future expansion.
- 隐私、数据保留和解释性缺口：implemented locally through account deletion purge and redacted planner audit fields; export/retention UI remains future work.

Residual risk:
- The implementation can continue into the next coding increment, but completion status must remain “conditional/local slice” until full intake/control/surface behavior and commercial gates are closed or explicitly re-scoped.

## 2026-06-04 P02 Downstream Documentation Independent Review

Result: pass for software-development readiness at documentation level. Not an implementation approval, not executed test evidence and not a release approval.

Findings:
- No documentation blocker. `p0-2-goal-diagnostic-foundation` has GoalProfile, SupportedGoalMatrix, DiagnosticAssessment, rubric/confidence, weakness tags, initial L0-L5 state and diagnostic commercial/data governance mapped through FR/Spec/AC/TC/Traceability.
- No documentation blocker. `p0-2-goal-backplan-memory-policy` has GoalBackplan, weekly/daily planner, MemoryCurvePolicy, L0-L5 transition, cross-session pressure, cross-day orchestration, commercial/data governance, deterministic replay, performance and >=80% coverage gates mapped through FR/Spec/AC/TC/Traceability.
- No documentation blocker. `p0-2-autopilot-progress-checkpoint` has AutopilotTraining, no-choice execution, user control, ProgressForecast, OutcomeCheckpoint, progress surfaces, commercial/claim/data governance, performance and >=80% coverage gates mapped through FR/Spec/AC/TC/Traceability.
- No documentation blocker. P02-SI-001 through P02-SI-013 all have downstream traceability rows, and every AC family has stable planned TC IDs.
- Required implementation blocker remains. The >=80% code coverage and performance budgets are acceptance/test gates only; they are not executed evidence until code and CI reports exist.

Validation:
- `p02-diagnostic-chain=passed`.
- `p02-plan-chain=passed`.
- `p02-auto-chain=passed`.
- `p02-stage-scope-traceability=passed`.
- `p02-policy-gate-downstream=passed`.
- `p02-ac-tc-trace-prefixes=passed`.
- `git diff --check -- <P0.2 downstream docs and reports>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Residual risk:
- Product engineering can use these docs to start downstream domain/API/AI/UX contract generation, but implementation must remain blocked until those contracts, code, tests, coverage reports, performance results and executed traceability evidence exist.
- Any future implementation that cannot meet >=80% changed-code line/branch coverage or defined p95 performance budgets must be blocked or explicitly re-scoped before completion.

## 2026-06-04 P02 Policy Gate Commercial Product Review

Result: pass for planning-gate completeness and commercial/product landing guard. Not a requirements/spec/AC/TC approval and not implementation approval.

Findings:
- No planning blocker. P02-PG-001 prevents false achievement, ETA and official-score-equivalence claims by requiring product-internal achievement thresholds, confidence bands, diagnostic reliability and prohibited-claim rules.
- No planning blocker. P02-PG-002 prevents unsupported-goal planning by requiring a supported/partial/unsupported goal matrix tied to rubric, scenario, task and content coverage.
- No planning blocker. P02-PG-003 prevents over-automation and unstable planner behavior by requiring user control, quiet hours, missed-day recovery, fatigue/overload protection, deterministic planner constraints and replay evidence.
- No planning blocker. P02-PG-004 prevents commercial ambiguity by requiring entitlement boundaries, AI usage budgets, cost telemetry, quota downgrade and membership-display limits.
- No planning blocker. P02-PG-005 prevents sensitive-data and explainability gaps by requiring consent, retention/deletion/export, minimization, audit trail and forecast/checkpoint explanation rules.

Seven-defect closure review:
- 达标判定与承诺边界：closed at planning gate by P02-PG-001.
- 诊断可信度：closed at planning gate by P02-PG-001 and P02-PG-005.
- 自动带练过度自动化：closed at planning gate by P02-PG-003.
- 商业边界不足：closed at planning gate by P02-PG-004.
- 计划引擎可执行约束不足：closed at planning gate by P02-PG-003.
- 内容覆盖与目标类型未绑定：closed at planning gate by P02-PG-002.
- 隐私、数据保留和解释性缺口：closed at planning gate by P02-PG-005.

Validation:
- P02 policy gate ID audit - passed.
- P02 seven-defect closure audit - passed at planning-gate level.
- `git diff --check -- <P0.2 policy gate docs and reports>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Residual risk:
- The seven defects are not implemented away yet. They are now hard gates for the next requirements/spec/AC/TC/traceability and contract-generation steps.
- Any downstream increment that omits an applicable P02-PG row must be blocked by independent checker review.

## 2026-06-04 P02 Superseded Memory Artifact Removal Review

Result: pass for documentation governance, link cleanup and implementation-entry guard. Not a requirements/spec/AC/TC approval for the new increments and not implementation approval.

Findings:
- No blocker. The old single memory-planner artifact was removed from the active increment directory.
- No blocker. Stage, roadmap, feature registry and development status now point to `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy` and `p0-2-autopilot-progress-checkpoint` as the only P0.2 planned increment sources.
- No blocker. Reports now describe the earlier memory-planner audit as superseded historical evidence, not as an implementation-ready source of truth.
- Required gate remains. The three new P0.2 increments still need full requirements, specs, acceptance criteria, test cases, traceability and independent checker review before implementation.

Validation:
- Superseded artifact reference audit - passed after active links were removed.
- Directory removal check - passed.
- `git diff --check -- <P0.2 supersession docs>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Residual risk:
- The new P0.2 increments currently have PM definitions only. They still need downstream docs and contract gates before any code work can start.

## 2026-06-04 P02 Goal-Driven Stage Replanning Review

Result: pass for roadmap/stage replanning and PM-owned increment definitions. Not a requirements/spec/AC/TC approval for the new increments and not implementation approval.

Findings:
- No planning blocker. Existing Product Base, P0.1, old P0.2 and P1/P2 were reviewed against the goal-driven autopilot chain; none fully covered GoalProfile, DiagnosticAssessment, GoalBackplan, AutopilotTraining, MemoryCurvePolicy, ProgressForecast and OutcomeCheckpoint.
- No planning blocker. `goal-driven-learning-autopilot` is now registered as the P0.2 primary feature, with `learning-memory-review` as an affected feature.
- No planning blocker. P0.2 stage scope now includes P02-SI-001 through P02-SI-013 and routes the new scope into three planned increments: `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy` and `p0-2-autopilot-progress-checkpoint`.
- No planning blocker. The earlier single memory-planner artifact was identified as incomplete and is now removed from the active implementation path.

Validation:
- P0.2 goal-driven stage audit - passed with no missing P02-SI-001..013 or requirement-chain terms.
- `git diff --check -- <P0.2 stage replanning docs>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Residual risk:
- The three new P0.2 increments currently have PM definitions only. They still need requirements, specs, acceptance criteria, test cases, traceability, domain/API/AI/UX contracts and independent checker review before implementation.
- Earlier single memory-planner requirements/spec/AC/TC are no longer valid as active P0.2 source of truth.

## 2026-06-04 P02 Documentation Design Independent Review

Result: pass for documentation design, AC-to-TC planning and bidirectional traceability. Not an implementation approval.

Independent step reviews:
- PM/stage review passed before supersession. The earlier memory-planner documentation covered P02-SI-001 through P02-SI-006, but it is now historical evidence only.
- Requirement review passed. `P02-FR-001` through `P02-FR-010` cover all P02 stage scope items and keep P0.2 non-goals explicit.
- Spec review passed. `P02-SPEC-001` through `P02-SPEC-010` preserve the upstream Stage Scope IDs and define inputs, outputs, states, failure handling, audit/replay and module impact.
- Acceptance review passed. `AC-P02-001` through `AC-P02-010` are binary enough for QA and reverse-reference FR/Spec/Stage Scope.
- Test case review passed. `TC-P02-001` through `TC-P02-014` include required fields and keep functional tests as `planned`; only TC-P02-014 documentation traceability audit is marked passed.
- Traceability review passed. `P02-TR-001` through `P02-TR-010` form the required Stage Scope -> Increment -> FR -> Spec -> AC -> TC chain and clearly separate planned contract/code/test evidence from real implementation evidence.

Validation:
- P02 documentation ID coverage audit - passed with no missing IDs and no forbidden implementation/release claims.
- `git diff --check -- <P0.2 documentation paths>` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- P02 traceability `rg` audit - passed before supersession.

Residual risk:
- P02-GAP-001 through P02-GAP-006 remain open by design: domain model, UX/screen spec, AI runtime schema, API/OpenAPI contract, implementation/tests and scope guard must be created before implementation can start or complete.
- P0.2 documentation design must not be used to claim Product Base merge, commercial release, paid AI voice readiness or P1/P2 content expansion.

## 2026-06-04 P0.1 Product Base Implementation Review

Result: pass for local implementation review, API drift sync, traceability and regression coverage. Not a commercial release approval.

Findings:
- No local blocker. Backend Training API/source-of-truth, evidence governance, versioned content mapping, media/AI pipeline, planner audit and redacted metrics remain implemented and covered by TC-P01-021 through TC-P01-028.
- No local blocker. Flutter Training entry, adapter, voice/text fallback and backend-disabled gate remain backend-only and covered by TC-P01-029 through TC-P01-031.
- No local blocker. `npm run check:api-contract` now passes after syncing `dart-client-drift-manifest.json`, `.openapi-sha256` and `SpeakeasyApiContract.openApiSha256` to the current OpenAPI hash.
- No local blocker. `P01-FR-012..017 -> P01-SPEC-013..018 -> AC-P01-014..019 -> TC-P01-021..031 -> P01-TR-013..018` remains complete and bidirectional.
- No local blocker after independent review. The independent implementation reviewer initially blocked on a stale `test_cases.md` hash wording; AC-P01-014 now states that generated Dart OpenAPI drift pins are synced to `4880e61f8dae8673c13eb2aff5c66e690de70e67663bae45608f57206502fcbf`, and re-review passed.
- Release blocker remains outside this increment. PM Product Base merge approval, paid AI voice and commercial release still require their owning gates.

Validation:
- `cd backend && mvn -q -DskipTests compile` - passed.
- `cd backend && mvn -q -Dtest=TrainingSessionControllerTest,TrainingTurnIdempotencyTest,TrainingSessionAuthorizationTest,TrainingEvidenceRuleTraceTest,TrainingAccountDeletionRetentionTest,TrainingContentVersioningTest,TrainingMediaAiPipelineTest,TrainingPlannerReplayTest,TrainingObservabilityTest test` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/check_p0_1_training_frontend_source_of_truth.py` - passed.
- `python3 scripts/check_p0_1_training_rollout_readiness.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter analyze lib/config/app_config.dart lib/services/api_client.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - passed.
- Independent implementation re-review - passed after resolving the stale hash wording in `test_cases.md`.

Residual risk:
- This implementation review does not approve commercial release, paid AI voice, external provider/media/cost/retention evidence or PM Product Base merge.

## 2026-06-03 P0.1 Training Naming Migration Review

Result: pass for namespace migration, traceability and regression coverage. No behavior change intended.

Findings:
- No blocker. Training production code now lives under `lib/features/training/` with `TrainingBackendAdapter`, `TrainingSessionLoopPage`, `TrainingSessionView` and `Training*` contract types.
- No blocker. Training tests now live under `test/features/training/`; TC IDs and AC mappings were preserved rather than renumbered.
- No blocker. `scripts/check_p0_1_training_frontend_source_of_truth.py` now forbids `InterviewTraining*`, `interview_training_*`, legacy Training files under `lib/features/interview/`, and frontend `training_agent.dart`.
- No blocker. `scripts/check_ai_eval_cases.dart` validates feedback schema through `training_contract.dart`, not a local planner/agent.
- No blocker. Architecture boundary now states that `interview` is a scenario/practice namespace, while Training frontend belongs to `lib/features/training/`.

Validation:
- `python3 scripts/check_p0_1_training_frontend_source_of_truth.py` - passed.
- `python3 scripts/check_p0_1_training_rollout_readiness.py` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - passed.
- `flutter analyze lib/features/training/training_contract.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_view.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_test_helpers.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart scripts/check_ai_eval_cases.dart` - passed.
- `flutter analyze integration_test/p0_1_training_loop_test.dart` - passed.
- `dart run scripts/check_ai_eval_cases.dart` - passed: 7 cases.

Residual risk:
- Historical report entries may still mention the old file names as past evidence. Current source-of-truth docs and executable paths use the Training bounded-context names.

## 2026-06-03 P0.1 Training Backend-Only Frontend Source-Of-Truth Review

Result: pass for local Flutter backend-only source-of-truth implementation and traceability. Not a commercial release approval.

Findings:
- No local blocker. The retired `interview_training_agent.dart` production fallback is deleted, and the new contract file contains only API-facing DTO/validation helpers, not a planner/session state machine.
- No local blocker. `TrainingSessionLoopPage` requires a backend adapter and calls backend start/get/hint/submit/complete paths; backend start failure renders service-unavailable state instead of creating a local draft session.
- No local blocker. `HomePage` blocks training entry when `ENABLE_BACKEND_TRAINING=false`; it no longer opens a local-first route.
- No local blocker. Voice failure no longer fabricates ASR transcript, feedback, planner decisions or evidence. Missing trusted `audio_ref` becomes a recoverable state, and typed fallback submits to backend only.
- No local blocker. `scripts/check_p0_1_training_frontend_source_of_truth.py` blocks the retired agent file and known local fallback patterns, giving future changes an executable guard.
- Release blocker remains outside this increment. Paid AI voice and commercial release still require P0 external DashScope, object storage, cost dashboard and retention evidence.

Validation:
- `python3 scripts/check_p0_1_training_frontend_source_of_truth.py` - passed.
- `flutter test test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter test integration_test/p0_1_training_loop_test.dart` - passed.
- `flutter analyze lib/features/training/training_contract.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_view.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_entry_test.dart test/features/training/training_backend_only_loop_test.dart test/features/training/training_text_fallback_test.dart test/features/training/training_recoverable_failure_test.dart test/features/training/training_feedback_schema_test.dart test/features/training/training_voice_flow_test.dart test/features/training/training_test_helpers.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter analyze integration_test/p0_1_training_loop_test.dart` - passed.

Residual risk:
- Device-level TC-P01-031 integration now runs with a self-contained local fixture; broader system E2E login/onboarding suites remain separate from this source-of-truth correction.
- Future local demos must stay isolated from the product training entry and cannot be described as Product Base or production ready.

## 2026-06-03 P0.1 Training Product Base Hardening Review

Result: pass for local backend/Flutter production-hardening implementation and traceability, including the backend-only frontend source-of-truth correction. Not a commercial release approval.

Findings:
- No local blocker. Backend Training source-of-truth is implemented with authenticated owner scope, session/turn persistence, idempotency replay/conflict and generic official scenario validation based on scenario/version/level/content mapping rather than hard-coded two scene IDs.
- No local blocker. Evidence governance now writes accepted Training evidence through `LearningMemoryService` with rule trace and covers deletion cleanup for Training tables.
- No local blocker. Training turns can use trusted backend `audio_ref` and route ASR/scoring/LLM through `AiGatewayService` while keeping typed fallback behavior.
- No local blocker. Planner decisions are deterministic, versioned and audited with replay-friendly snapshots that do not include raw transcript content.
- No local blocker. Flutter has a production backend adapter, config gate and backend-only source-of-truth guard; local-first has been retired from the product training entry and cannot be represented as Product Base/production ready.
- Release blocker remains outside this increment. Paid AI voice and commercial release still require P0 external DashScope, object storage, cost dashboard and retention evidence.

Validation:
- `cd backend && mvn -q -DskipTests compile` - passed.
- `cd backend && mvn -q -Dtest=TrainingSessionControllerTest,TrainingTurnIdempotencyTest,TrainingSessionAuthorizationTest,TrainingEvidenceRuleTraceTest,TrainingAccountDeletionRetentionTest,TrainingContentVersioningTest,TrainingMediaAiPipelineTest,TrainingPlannerReplayTest,TrainingObservabilityTest test` - passed.
- `cd backend && mvn -q test` - passed; full backend regression passed after adding Training user-data cascade cleanup semantics.
- `flutter test test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `flutter analyze lib/config/app_config.dart lib/services/api_client.dart lib/features/training/training_backend_adapter.dart lib/features/training/training_session_loop_page.dart lib/pages/home_page.dart test/features/training/training_content_mapping_test.dart test/features/training/training_backend_pipeline_test.dart test/features/training/training_planner_replay_test.dart` - passed.
- `python3 scripts/check_p0_1_training_rollout_readiness.py` - passed.
- `npm run check:api-contract` - passed in the original batch; 2026-06-04 revalidation passed after generated Dart drift pins were synced to current OpenAPI hash `4880e61f8dae8673c13eb2aff5c66e690de70e67663bae45608f57206502fcbf`.
- `python3 scripts/project_agent_runner.py validate` - passed.

Residual risk:
- Superseded by 2026-06-04 implementation review: generated Dart OpenAPI drift pins are now synced to the current OpenAPI hash.
- Production rollout requires setting `ENABLE_BACKEND_TRAINING=true`, operating existing AI/media environment gates and preserving P0 commercial release blockers.

## 2026-06-03 P0.1 Commercial Software Remediation Documentation Review

Superseded status note: this section records the earlier documentation-only review. The later `2026-06-03 P0.1 Training Product Base Hardening Review` supersedes its remaining implementation blocker for TC-P01-021 through TC-P01-028 and records local passed evidence for TC-P01-021 through TC-P01-031.

Result: pass for documentation/design remediation and traceability. Not a Product Base merge approval, production training approval or commercial release approval.

Findings:
- No documentation blocker. The remediation stays inside the existing P0.1 stage and `p0-1-expression-automation-training` increment; no new stage or unrelated P0.2/P1/P2 scope was introduced.
- No documentation blocker. `P01-FR-012..017 -> P01-SPEC-013..018 -> AC-P01-014..019 -> TC-P01-021..031 -> P01-TR-013..018` is now represented in the increment docs.
- No documentation blocker. Architecture and domain docs now state the commercial software boundary: local-first P0.1 evidence is local/draft only; Product Base/production Training requires backend source-of-truth, evidence governance, content versioning, real media/AI pipeline, planner audit and rollout metrics.
- No documentation blocker. The release checklist now has an explicit P0.1 Training Product Base/Production Hardening Gate, so the top-level checked checklist cannot override planned or blocked P0.1 sections.
- Remaining implementation blocker. No backend Training source-of-truth implementation, evidence persistence, production media/AI Training pipeline, planner replay fixtures or rollout metrics were implemented in this batch.

Validation:
- `rg -n "P01-FR-012|P01-SPEC-013|AC-P01-014|TC-P01-021|P01-TR-013|P01-GAP-009|P01-HARDEN-001|Product Base/production" ...` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- <changed docs>` - passed.

Residual risk:
- Historical note from this documentation-only review: TC-P01-021 through TC-P01-028 were planned at that time. This statement is superseded by the later P0.1 Training Product Base Hardening Review, where TC-P01-021 through TC-P01-031 have local passed evidence; PM approval and Product Base merge review remain separate gates.
- Paid AI voice and commercial release remain governed by P0 commercial subscription and commercial AI provider hardening gates.

## 2026-06-03 P0-AI OSS Storage Implementation Independent Review

Result: pass for local backend implementation and traceability. Not a paid AI release approval.

Findings:
- No local blocker. `FR-COM-AI-001 -> COM-AI-SPEC-001 -> AC-COM-AI-001 -> TC-COM-AI-001/002/008 -> COM-AI-TR-001` is fully mapped.
- No local blocker. Backend upload creation now owns `object_ref` generation and complete rejects forged refs before provider access.
- No local blocker. The Aliyun OSS adapter produces canonical `oss://bucket/key` refs, short signed PUT/GET URLs, optional SSE/KMS upload headers and delete-object hooks; the local fallback remains available for test/dev.
- No local blocker. Existing ASR, TTS cache, cost dashboard and retention tests still pass with the storage abstraction.
- Release blocker. Real Aliyun OSS bucket/KMS/ACL/lifecycle/provider-access evidence is not supplied; `AI_MEDIA_STORAGE_EVIDENCE_REF` remains required.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,AiMediaStorageServiceTest,ProductionAsrMediaRefTest,PersistentTtsCacheTest,AiCostDashboardTest,AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,DashScopeProviderGatewayIntegrationTest,DashScopeProviderGatewayTest,CommercialFoundationControllerTest,AccountDeletionLearningDataTest,FoundationMigrationTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/check_ai_external_release_evidence.py` - passed with expected release blockers.
- `python3 scripts/check_ai_external_release_evidence.py --strict-external` - failed as expected without external refs.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Residual risk:
- Real staging/release candidate execution must still prove bucket policy, signed URL expiry, provider fetchability and delete/lifecycle behavior before paid AI voice can be opened to real users.

## 2026-06-03 P0-AI External Evidence Gate Independent Reviews

Result: pass for local strategy, checklist, strict gate wiring and traceability. Not a paid AI release approval.

### P0-AI-EXT-001 DashScope Evidence Review
Findings:
- No local blocker. `tests/commercial/ai_external_release_evidence_checklist.md` carries all seven DashScope scenarios and preserves the existing `tests/commercial/ai_provider_sandbox_matrix.md` contract.
- No local blocker. `scripts/check_ai_external_release_evidence.py --strict-external` requires `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` and cannot be satisfied by a repo/local path.
- Release blocker. The actual full DashScope evidence package and external reviewer approval are still missing.

Validation:
- `python3 scripts/check_ai_provider_sandbox_evidence.py` - passed with expected release blocker.
- `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` - failed as expected without `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.
- `python3 scripts/check_ai_external_release_evidence.py --strict-external` - failed as expected while the ref is missing.

### P0-AI-STORAGE-001 Media Storage Evidence Review
Findings:
- No local blocker. The checklist now defines bucket/KMS/TTL/lifecycle, upload/complete, provider access, expiry, deletion and illegal-ref rejection evidence.
- No local blocker. Traceability maps the external storage gate back to `COM-AI-TR-001`, `COM-AI-TR-005`, `AC-COM-AI-001`, `AC-COM-AI-005`, `TC-COM-AI-001`, `TC-COM-AI-002`, `TC-COM-AI-006` and `TC-COM-AI-007`.
- Release blocker. Real bucket upload/read/provider-access/expiry/deletion proof is not present; `AI_MEDIA_STORAGE_EVIDENCE_REF` remains missing.

Validation:
- `python3 scripts/check_ai_external_release_evidence.py` - passed and reported `AI_MEDIA_STORAGE_EVIDENCE_REF` as a release blocker.
- Fixture `scripts/check_release_readiness.sh --env-only` - passed with dummy external-style ref, proving aggregate gate wiring only.

### P0-AI-COST-001 Cost Dashboard Evidence Review
Findings:
- No local blocker. The checklist requires provider cost samples, dashboard dimensions, budget/provider/cache alerts, raw-content guard evidence and PM/Ops unit-economics approval.
- No local blocker. The external gate maps to `COM-AI-TR-004`, `AC-COM-AI-004` and `TC-COM-AI-005`.
- Release blocker. Production dashboard/API evidence, alert threshold approval and PM/Ops unit-economics approval are not supplied; `AI_COST_DASHBOARD_EVIDENCE_REF` remains missing.

Validation:
- `python3 scripts/check_ai_external_release_evidence.py` - passed and reported `AI_COST_DASHBOARD_EVIDENCE_REF` as a release blocker.
- `bash -n scripts/check_release_readiness.sh` - passed after adding the paid AI external evidence gate.

### P0-AI-RETENTION-001 Retention Evidence Review
Findings:
- No local blocker. The checklist requires policy approval, audio deletion, transcript redaction, TTS owner/cache cleanup, metric sanitization and retry/manual failure evidence.
- No local blocker. The external gate maps to `COM-AI-TR-005`, `AC-COM-AI-005`, `TC-COM-AI-006` and `TC-COM-AI-007`.
- Release blocker. Approved production retention policy and staging/release object-store deletion proof are not supplied; `AI_RETENTION_POLICY_EVIDENCE_REF` remains missing.

Validation:
- `python3 scripts/check_ai_external_release_evidence.py` - passed and reported `AI_RETENTION_POLICY_EVIDENCE_REF` as a release blocker.
- `python3 scripts/project_agent_runner.py validate` - passed.

Overall validation:
- `python3 -m py_compile scripts/check_ai_external_release_evidence.py scripts/check_ai_provider_sandbox_evidence.py scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `git diff --check` - passed.

Residual risk:
- The four release blockers are now explicit and executable, but not externally closed.
- Do not enable paid AI voice for real users until all four evidence refs are set from reviewed external evidence packages and strict gates pass in the release candidate environment.

## 2026-06-03 P0/P0.1 Blocker Closure Independent Review

Result: pass for local P0.1 blocker closure and evidence-prep tooling. This is not commercial release approval.

Checked steps:
- TC-P01-013 training route integration and E2E.
- TC-P01-014 executable AI eval validator and runtime schema hardening.
- TC-COM-AI-004 sanitized DashScope evidence-prep matrix.
- TC-COM-012/015/019/021/022 strict commercial external gates.

Independent review findings:
- PASS for TC-P01-013. The new route uses the existing Training Agent/session view, enters only after entitlement/scene checks, covers ASR failure text fallback, feedback, pressure/continue and recap, and the E2E asserts no entitlement, billing or final mastery write.
- PASS for TC-P01-014. The validator directly calls the runtime schema validator and covers all seven documented P0.1 AI eval cases; runtime schema now rejects prohibited final-state fields recursively.
- PASS for TC-COM-AI-004 evidence preparation. The generated report contains only hashes/status/latency/model/cost buckets and explicitly records that strict release is not closable without `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.
- PASS for commercial gate execution discipline. Non-strict structure gates pass, while strict gates fail for concrete missing external evidence/configuration; no release blocker was incorrectly marked closed.

Validation performed:
- `./scripts/run_mvp_system_e2e.sh --suite p0-1-training-loop` - passed.
- `dart run scripts/check_ai_eval_cases.dart` - passed.
- `flutter test test/features/training/training_feedback_schema_test.dart` - passed.
- Relevant `flutter analyze` commands - passed.
- `python3 scripts/run_dashscope_sandbox_matrix.py` - passed with sanitized report `build/reports/dashscope-sandbox-20260602T223557Z-3359fcc82fafa457.json`.
- Commercial non-strict gates - passed.
- Commercial strict gates - failed as expected on missing external/native/store/release evidence refs and production env.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Residual risk:
- Commercial release remains blocked by TC-COM-012/015/019/021/022 and TC-COM-AI-004 strict external evidence.
- The local DashScope report is evidence-prep only; an external package and independent reviewer must still supply the release ref.
- Native iOS social-login configuration still contains a placeholder WeChat URL scheme and lacks Apple Sign In entitlement.

## 2026-06-02 P0/P0.1 Blocker Retest Independent Review

Result: pass for the local blocker retest and documentation update. This is not commercial release approval and not P0.1 completion approval.

Checked step:
- P0.1 training-agent retest, P0 commercial subscription/AI-provider retest, system E2E revalidation and PM status refresh.
- Code changes in `scripts/run_mvp_system_e2e.sh`, `integration_test/mvp_system_membership_boundary_test.dart`, `AuditLog.java` and `CommercialAccountDeletionProcessorTest.java`.
- Updated evidence reports and product traceability documents.

Independent review finding:
- PASS. The code changes address test-environment drift and stale assertions without weakening product gates.
- E2E health readiness now respects the OPS-protected endpoint by passing an E2E bearer token.
- E2E provider selection is deterministic by default, so local system E2E cannot be polluted by shell-level live-provider env vars.
- Membership boundary E2E still verifies the restore-purchases entry; it now scrolls to the button before asserting it.
- Account deletion idempotency now asserts the relevant completed deletion audit event instead of assuming AI retention cleanup will never add its own audit record.

Validation performed:
- P0.1 Flutter training core suite - passed.
- P0 commercial backend and AI backend deterministic suites - passed.
- Commercial Flutter widget/integration suites - passed.
- `npm run check:api-contract` - passed.
- MVP system E2E suites `smoke`, `scene-catalog`, `learning-memory`, `practice-feedback`, `profile-settings`, `membership-boundary`, `commercial-boundary` - passed.
- Sanitized DashScope LLM/TTS/ASR controlled live sanity - passed.

Residual risk:
- Superseded 2026-06-03: TC-P01-013 and TC-P01-014 are locally closed by route E2E and executable AI eval evidence; P0.1 PM completion now depends on acceptance of the updated traceability and explicit non-goal boundaries.
- TC-COM-012/015/019/021/022 and TC-COM-AI-004 strict evidence ref remain open; commercial and paid AI release are not approved.
- Controlled live DashScope sanity proves reachability only; it does not provide the full evidence matrix or external reviewer evidence.

## 2026-06-01 P0 Commercial AI Provider Hardening Documentation Review

Result: pass for documentation planning and traceability. This is not commercial release approval and not paid AI voice readiness.

Checked step:
- `CR-20260601-002` / `commercial-ai-provider-hardening`.
- Five optimization items: object-storage upload lifecycle, persistent TTS cache, real DashScope sandbox / controlled live evidence, AI cost dashboard, production AI data strategy.
- Updated P0 stage, roadmap, commercial subscription split, P0.1 residual mapping, architecture/security/API/data-flow, release checklist/runbook, manual evidence checklist and reports.

Independent review finding:
- PASS. The reviewer found no blocker and confirmed all five optimization items have Stage Scope -> FR -> Spec -> AC -> TC -> Traceability/Gaps coverage.
- Object-storage upload lifecycle maps to `COM-SI-013 -> FR-COM-AI-001 -> COM-AI-SPEC-001 -> AC-COM-AI-001 -> TC-COM-AI-001/002 -> COM-AI-TR-001 -> COM-AI-GAP-001 Open`.
- Persistent TTS cache maps to `COM-SI-014 -> FR-COM-AI-002 -> COM-AI-SPEC-002 -> AC-COM-AI-002 -> TC-COM-AI-003 -> COM-AI-TR-002 -> COM-AI-GAP-002 Open`.
- Real DashScope sandbox evidence maps to `COM-SI-015 -> FR-COM-AI-003 -> COM-AI-SPEC-003 -> AC-COM-AI-003 -> TC-COM-AI-004 -> COM-AI-TR-003 -> COM-AI-GAP-003 Open / external`.
- AI cost dashboard maps to `COM-SI-016 -> FR-COM-AI-004 -> COM-AI-SPEC-004 -> AC-COM-AI-004 -> TC-COM-AI-005 -> COM-AI-TR-004 -> COM-AI-GAP-004 Open`.
- Production AI data strategy maps to `COM-SI-017 -> FR-COM-AI-005 -> COM-AI-SPEC-005 -> AC-COM-AI-005 -> TC-COM-AI-006/007 -> COM-AI-TR-005 -> COM-AI-GAP-005 Open`.

Quality findings:
- No unimplemented AI hardening item is marked closed or passed.
- `commercial-subscription-readiness` no longer claims to close paid AI voice or production AI provider hardening.
- Release docs clearly state fake transport, deterministic provider, process-local TTS cache and manual signed URLs cannot replace production evidence.
- `P01-GAP-008` remains Partial and now points production closure to `commercial-ai-provider-hardening`.

Validation performed:
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `python3 scripts/check_provider_sandbox_evidence.py` - passed in non-strict mode and reported existing Apple/Google external evidence blockers.

Residual risk:
- COM-AI-GAP-001 through COM-AI-GAP-005 remain open.
- No backend, Flutter, migration, OpenAPI implementation or real DashScope execution was performed for this increment.
- Paid AI voice release remains blocked until implementation, test execution, external evidence and independent review are supplied.

## 2026-06-01 P0.1 Backend AI Provider Gateway Independent Review

Result: pass for local backend provider gateway scope after three independent review loops.

Checked step:
- CR-20260601-001 / P01-FR-011 / P01-SPEC-012 / AC-P01-013.
- LLM/TTS/ASR design obligations 1-5 and commercial obligations 1-5 at the current local executable boundary.
- TC-P01-015 through TC-P01-020 evidence and P01-TR-012 traceability.

Review sequence:
- First independent review blocked ASR metadata trust, signed URL audit leakage, loose LLM schema validation and TTS cache overclaim.
- Second independent review confirmed those fixes, but blocked because TC-P01-019 documented free/pro/enterprise policy while tests only proved free.
- Third independent review confirmed free/pro/enterprise policy tests, but blocked because audio size cap was documented without a direct bytes-limit test.
- Final independent review passed after adding signed audio bytes-limit integration evidence.

Quality findings:
- The current Spring Boot backend remains the implementation boundary; no switch to old `speakeasy_backend_export` occurred.
- `DashScopeAiProviderGateway` implements `AiProviderGateway`; `DeterministicAiProviderGateway` remains the default through `matchIfMissing = true`.
- DashScope ASR now requires backend-signed media metadata for HTTP refs and rejects unsigned refs before provider calls.
- Usage/audit stores hashed media refs rather than complete signed audio URLs.
- LLM coach output is validated by strict backend schema checks for allowed fields, enums, required fields and score ranges.
- Commercial provider policy derives free/pro/enterprise tier from server-side entitlement snapshots; tests cover free rejection, pro/enterprise allowance, audio size rejection and client `provider_tier` rejection.
- TTS cache is correctly documented as in-process partial evidence; persistent media cache remains a residual release requirement.

Validation performed:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=DashScopeProviderGatewayIntegrationTest test` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `npm run lint:openapi` - passed.
- `PYTHONPATH=.uv-cache/archive-v0/6TiI4tLkyvVElUd4WZMLn/lib/python3.11/site-packages python3 scripts/check_openapi_contract.py` - passed.
- `PYTHONPATH=.uv-cache/archive-v0/6TiI4tLkyvVElUd4WZMLn/lib/python3.11/site-packages python3 scripts/check_openapi_dart_drift.py` - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Residual risk:
- No live DashScope request was executed; provider calls remain fake-transport local evidence.
- ASR upload-to-backend/object-storage lifecycle is still downstream.
- TTS cache is process-local and not durable across restarts or multi-instance deployment.
- Combined `npm run check:api-contract` still fails on a local `uv run --with PyYAML` runtime panic after OpenAPI lint passes; direct OpenAPI contract and Dart drift subchecks pass.

## 2026-05-26 OpenAPI Path Governance

Result: pass for path decision; Product Object Governance Check later returned pass for the resulting Redocly/OpenAPI gate.

Decision:
- `docs/architecture/api_contract.md` is the human-readable API contract overview for API families, product-object traceability, unified error semantics, versioning, compatibility policy, and OpenAPI generation boundaries.
- `docs/architecture/openapi/speakeasy-api.yaml` is the machine-readable OpenAPI source of truth for paths, components, request/response schemas, examples, and lint checks.
- API Contract generation must not create implementation-level endpoints from roadmap, stage, or future boundary text alone.

Changed governance files:
- `.agents/skills/document-path-governance/SKILL.md`
- `.agents/skills/document-path-governance/SPEC.md`
- `.agents/skills/api-contract-generate/SKILL.md`
- `.agents/skills/api-contract-generate/SPEC.md`
- `docs/process/skill_quality_standard.md`

## 2026-05-26 Domain/Foundation To API Traceability Check

Result: conditional pass for API Contract/OpenAPI generation; blocked for implementation.

Scope checked:
- Product Base stable chain: `docs/product/base/requirements.md` -> `docs/product/base/spec.md` -> `docs/product/base/acceptance.md` -> `docs/product/base/traceability.md`
- P0 commercial chain: `docs/product/increments/commercial-subscription-readiness/definition.md` -> `requirements.md` -> `spec.md` -> `acceptance.md` -> `traceability.md`
- P0.1 training chain: `docs/product/increments/p0-1-expression-automation-training/definition.md` -> `requirements.md` -> `spec.md` -> `acceptance.md` -> `traceability.md`
- Domain/API upstream: `docs/domain/domain_schema.md`, `docs/domain/entity_relationship.md`, `docs/architecture/backend_db_foundation_contract.md`, `docs/architecture/api_contract.md`

Findings:
- Product Base has accepted requirements, spec, acceptance, and traceability with implementation/test evidence or explicit exceptions. It can provide stable-feature API Contract input where server-backed behavior is now being introduced.
- P0 commercial has definition, requirements, spec, acceptance, and traceability in planned state. Its traceability explicitly requires Domain Schema and API Contract before implementation.
- P0.1 training has definition, requirements, spec, acceptance, and pre-implementation traceability. Its API need must be scoped carefully because some P0.1 behavior may remain local-first unless repository-backed persistence/cloud sync is chosen.
- `docs/domain/domain_schema.md` and `docs/domain/entity_relationship.md` cover Product Base accepted domain plus P0 and P0.1 extensions and explicitly defer P0.2/P1/P2 implementation-level modeling.
- `docs/architecture/backend_db_foundation_contract.md` defines OpenAPI source-of-truth and generated Dart client policy, but it remains Proposed and must not be treated as implementation approval.
- `docs/architecture/api_contract.md` is still a family-level contract sketch and must be upgraded before implementation-level OpenAPI can be consumed.

Required API Contract guardrails:
- Implementation-level endpoints may only be generated for Product Base stable behavior, P0 commercial, and P0.1 training where backed by accepted Product Base or approved increment artifacts.
- P0.2/P1/P2 may only appear as deferred boundary, reserved tag, or explicit non-goal until Product Manager creates the owning increment definition/spec.
- OpenAPI generation must include traceability notes back to Product Base stable features or owning increments.
- Backend/Frontend/QA may proceed only after OpenAPI YAML exists, passes lint, and passes checker review.

## 2026-05-26 API Contract/OpenAPI Generation And Lint Check

Result: pass.

Generated/updated artifacts:
- `docs/architecture/api_contract.md`
- `docs/architecture/openapi/speakeasy-api.yaml`
- `docs/architecture/openapi/dart-client-drift-manifest.json`
- `redocly.yaml`
- `package.json`
- `package-lock.json`
- `scripts/check_openapi_contract.py`
- `scripts/check_openapi_dart_drift.py`

Scope:
- Implementation-level OpenAPI paths cover Product Base stable behavior, P0 commercial readiness, and P0.1 expression automation training.
- P0.2/P1/P2 are recorded only as deferred boundaries and are not generated as implementation-level paths.

Validation performed:
- YAML parse check passed.
- Internal `$ref` resolution check passed.
- Future-boundary path guard passed: no paths were generated for P0.2, P1, P2, daily planner, notebook/vocabulary, or CMS implementation work.
- Redocly lint toolchain added with `@redocly/cli` and `redocly.yaml`.
- `npm.cmd run lint:openapi` passed with no errors or warnings.
- OpenAPI examples added through reusable `components.examples` references.
- `npm.cmd run check:openapi-contract` passed: 47 paths, 51 operations, 26 request examples, 47 success examples, and 54 error examples.
- `npm.cmd run check:dart-client-drift` passed in `pre_client_generation_gate` mode with target `lib/generated/api`.
- `npm.cmd run check:api-contract` passed as the combined API readiness gate.
- Project agent runner validation passed.
- Skill validation passed.
- Result: 47 paths, 51 operations, and 91 schemas.

Independent checker:
- Product Object Governance Check returned pass for `redocly.yaml`, `package.json`, `package-lock.json`, `.gitignore`, `docs/architecture/api_contract.md`, `docs/architecture/openapi/speakeasy-api.yaml`, and this quality report.
- Checker confirmed no Flutter/application code changes, no P0.2/P1/P2 implementation endpoints, and no product-object boundary issues.

Residual gate:
- Backend/Frontend/QA may proceed only against this canonical OpenAPI contract.
- `check:dart-client-drift` is currently a pre-client gate because no generated Dart client is committed yet. When `lib/generated/api/` is introduced, it must be upgraded to generated-client drift mode with a generated hash marker.
- Future P0.2/P1/P2 endpoints still require Product Manager-approved increment definition/spec before generation.

## 2026-05-26 PB-P0-BE-001A Backend Foundation Quality Check

Result: pass for backend foundation scope.

Scope checked:
- New `backend/` Spring Boot skeleton, Flyway migration, JPA entities, repositories, service/controller, and backend tests.
- PostgreSQL 15 Testcontainers migration validation.
- Product Base server-backed persistence foundation entities from `docs/domain/domain_schema.md`.
- P0 commercial persistence foundation entities and minimal OpenAPI-aligned read/request surfaces.
- Reports in `docs/reports/implementation_report.md` and `docs/reports/test_report.md`.

Quality findings:
- Scope remained limited to Product Base server-backed foundation plus P0 commercial DB/API dependency slice.
- No P0.1 training loop, P0.2/P1/P2 implementation, Flutter membership integration, production payment secrets, or real provider calls were introduced.
- Backend tests passed after fixing one test isolation issue around `account_deletion_jobs` foreign-key cleanup and one stale account-deletion response assertion after DTO contract hardening.
- Public API responses now use explicit DTOs for implemented endpoints instead of exposing JPA entity shape as the contract.
- Testcontainers was pinned to 2.0.5 because the Spring Boot-managed 1.19.8 dependency did not connect cleanly to Docker Engine 29.
- OpenAPI gate remained green after backend implementation.
- `.gitignore` now excludes `backend/target/` build artifacts.

Validation performed:
- `docker version` passed after Docker Desktop was started: Docker server 29.0.1.
- `mvn test -Dtest=PostgresFoundationMigrationTest` passed against PostgreSQL 15.17 via Testcontainers.
- `mvn test` in `backend/` passed: 7 tests, 0 failures, 0 errors.
- `npm.cmd run check:api-contract` passed: 47 paths, 51 operations, 26 request examples, 47 success examples, 54 error examples; Dart client pre-generation drift gate passed.

Residual gate:
- Keep provider verification, webhook idempotency, usage reserve/commit/release, auth/security, and generated Dart client wiring in later routed slices.

## Required Review Areas
- requirement traceability
- architecture consistency
- domain model consistency
- AI schema safety
- test coverage
- UX blockers
- release risk

## 2026-05-27 PB-P0-BE-001B Auth/Security Quality Check

Result: pass for scoped auth/security and current-user backend boundary.

Scope checked:
- Spring Security stateless bearer-token baseline.
- Server-side opaque access/refresh token sessions in `auth_sessions`.
- Minimal `/auth/login/phone`, `/auth/login/apple`, `/auth/login/wechat`, `/auth/refresh`, and `/auth/logout`.
- `GET/PATCH/DELETE /user/me` authenticated-user binding.
- `/entitlements` and `/usage/summary` authenticated-user binding and removal of production `X-User-Id` reliance.
- Backend tests, PostgreSQL migration validation, OpenAPI gate, and report evidence.

Quality findings:
- Current-step production code binds protected user/commercial endpoints to `CurrentUser`.
- `X-User-Id` remains only in tests/reports as regression proof that production code ignores it.
- No Flutter code, generated Dart client, P0.1 training loop, P0.2/P1/P2 implementation, real payment secrets, Apple/Google verification, webhook/refund/expiry flow, or usage reserve/commit/release was introduced.
- Initial tool-backed QA returned pass but identified low-cost test gaps: unauthenticated `PATCH /user/me`, `DELETE /user/me`, `GET /usage/summary`, invalid refresh token, and unsupported `schema_version`.
- The executor closed those gaps by adding request validation and controller tests, then reran validation.

Validation performed:
- `mvn.cmd test` in `backend/` passed after QA gap fixes: 19 tests, 0 failures, 0 errors.
- `npm.cmd run check:api-contract` passed after implementation: OpenAPI lint, contract gate, and Dart pre-client drift gate remain green.
- Product Object Governance Check Agent returned pass before and after QA gap fixes.
- Final checker confirmed no scope/boundary drift and no Flutter/generated-client/payment-secret changes.
- Final QA recheck returned pass: previously noted unauthenticated-path, invalid-refresh-token, and unsupported-`schema_version` gaps are covered; QA also reran `npm.cmd run check:api-contract` successfully.

Residual gate:
- This pass only covers PB-P0-BE-001B. It is not a production commercial-launch pass.
- Real social provider verification, entitlement refresh/gating, usage reserve/commit/release, Apple/Google verify/restore, webhooks/refund/expiry downgrade, full account deletion processor, generated Dart client, and Flutter integration remain later routed batches.
- The repository remains heavily dirty with pre-existing governance/product/OpenAPI/backend-foundation changes; staging or merge must isolate PB-P0-BE-001B files from unrelated work.

## 2026-05-29 mvp-backend-foundation-auth QA And Governance Check

Result: pass for `mvp-backend-foundation-auth` only.

Checked step:
- Independent QA checker for MVP-SI-001/MVP-SI-002, MVP-BE-FR-001/MVP-BE-FR-002, AC-MVP-BE-001/002, TC-MVP-BE-001 through TC-MVP-BE-006, code evidence, test evidence, and reports.
- Product Object Governance Check for the same increment, confirming no onboarding/content, practice/AI, learning/memory, generated client, or commercial subscription expansion scope was mixed into this batch.

Changed files:
- Backend implementation/test support: `backend/src/main/java/com/speakeasy/common/ApiExceptionHandler.java`, `backend/src/test/java/com/speakeasy/PostgresFoundationMigrationTest.java`, `backend/src/test/java/com/speakeasy/FoundationResponseContractTest.java`, `backend/src/test/java/com/speakeasy/FoundationErrorContractTest.java`, `backend/src/test/java/com/speakeasy/AuthSessionLifecycleTest.java`, `backend/src/test/resources/mockito-extensions/org.mockito.plugins.MockMaker`.
- Contract/tooling hygiene: `.gitignore`, `package.json`, `docs/architecture/openapi/dart-client-drift-manifest.json`.
- Evidence docs: `docs/product/increments/mvp-backend-foundation-auth/test_cases.md`, `docs/product/increments/mvp-backend-foundation-auth/traceability.md`, `docs/reports/implementation_report.md`, `docs/reports/test_report.md`, `docs/reports/quality_report.md`.

Scope match:
- The change maps only to MVP-SI-001 and MVP-SI-002 through `docs/product/increments/mvp-backend-foundation-auth/`.
- No Flutter application source under `lib/` or `test/` was modified; `test/services/auth_service_test.dart` was executed only as TC-MVP-BE-006 evidence.
- No onboarding/content, practice/AI, learning/memory, generated Dart client, or commercial subscription implementation was introduced.

Traceability finding:
- AC-MVP-BE-001 maps to TC-MVP-BE-001, TC-MVP-BE-002, and TC-MVP-BE-003; each TC row includes Stage Scope ID, FR, Spec, AC, traceability row, script path, execution command, result status, and evidence report.
- AC-MVP-BE-002 maps to TC-MVP-BE-004, TC-MVP-BE-005, and TC-MVP-BE-006; each TC row includes the same required evidence fields.
- `docs/product/increments/mvp-backend-foundation-auth/traceability.md` cites the TC IDs, script paths, commands, pass status, and `docs/reports/test_report.md` evidence for MVP-BE-TR-001 and MVP-BE-TR-002.
- MVP-BE-GAP-001 and MVP-BE-GAP-002 are closed with dated evidence; release evidence is explicitly N/A for this non-release increment.

Validation:
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest,FoundationResponseContractTest,FoundationErrorContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest" test` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `npm run check:api-contract` - passed: 47 paths, 51 operations, 26 request examples, 47 success examples, 54 error examples; Dart pre-client drift gate passed with hash `aaa05cb55926e5cd36a0a1ecf254d159226efe3f29ddeced57f8d78d628a86ed`.
- `flutter test test/services/auth_service_test.dart` - passed.

Required corrections:
- None.

Residual risk:
- `PostgresFoundationMigrationTest` uses Docker when available and falls back to local PostgreSQL binaries; it can skip only on machines with neither available.
- Generated Dart client integration remains a later client/QA increment; this increment only preserves the pre-client drift gate.
- The next route may proceed to onboarding/content only after Development Orchestrator opens that increment separately.

## 2026-05-29 mvp-backend-onboarding-content QA And Governance Check

Result: pass for `mvp-backend-onboarding-content` only.

Checked step:
- Independent QA checker for MVP-SI-003/MVP-SI-004/MVP-SI-005, MVP-BE-FR-003/004/005, AC-MVP-BE-003/004/005, TC-MVP-BE-007 through TC-MVP-BE-015, code evidence, test evidence, and reports.
- Product Object Governance Check for the same increment, confirming no practice/AI, learning/memory, commercial membership, generated-client, or release scope was mixed into this batch.

Changed files:
- Backend implementation: `backend/src/main/java/com/speakeasy/api/OnboardingContentController.java`, `backend/src/main/java/com/speakeasy/content/OnboardingContentService.java`, onboarding/content repositories and entities, and `backend/src/main/resources/db/migration/V202605290001__onboarding_content_seed.sql`.
- Backend tests: `OnboardingAssessmentControllerTest`, `LearningRouteMappingTest`, `OnboardingRouteResponseContractTest`, `ScenarioCatalogControllerTest`, `ScenarioContentControllerTest`, `ScenarioSeedVersioningTest`, `UserScenarioStateControllerTest`, `HomeSummaryControllerTest`, and shared/legacy cleanup updates needed by the new foreign keys.
- Contract/domain docs: `docs/architecture/openapi/speakeasy-api.yaml`, `docs/architecture/api_contract.md`, `docs/domain/domain_schema.md`, `docs/domain/entity_relationship.md`, `docs/architecture/openapi/dart-client-drift-manifest.json`.
- Evidence docs: `docs/product/increments/mvp-backend-onboarding-content/test_cases.md`, `docs/product/increments/mvp-backend-onboarding-content/traceability.md`, `docs/reports/implementation_report.md`, `docs/reports/test_report.md`, `docs/reports/quality_report.md`.

Scope match:
- The change maps to MVP-SI-003 through MVP-SI-005 only.
- No production Flutter source under `lib/` was changed; TC-MVP-BE-015 executed existing Flutter coordinator tests as compatibility evidence only.
- No practice session runtime, AI provider/prompt contract, memory/review/weakness engine, membership/payment flow, generated Dart client, or release checklist implementation was introduced.

Traceability finding:
- AC-MVP-BE-003 maps to TC-MVP-BE-007, TC-MVP-BE-008, and TC-MVP-BE-009; each TC row includes Stage Scope ID, FR, Spec, AC, traceability row, script path, execution command, result status, and evidence report.
- AC-MVP-BE-004 maps to TC-MVP-BE-010, TC-MVP-BE-011, and TC-MVP-BE-012 with the same required evidence fields.
- AC-MVP-BE-005 maps to TC-MVP-BE-013, TC-MVP-BE-014, and TC-MVP-BE-015 with backend and Flutter compatibility evidence.
- `docs/product/increments/mvp-backend-onboarding-content/traceability.md` cites the same TC IDs, implementation files, contract files, commands, pass status, and `docs/reports/test_report.md` evidence for MVP-BE-TR-003 through MVP-BE-TR-005.
- MVP-BE-GAP-003 and MVP-BE-GAP-004 are closed with dated evidence; generated-client wiring is explicitly deferred to the later client/QA increment.

Validation:
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=OnboardingAssessmentControllerTest,LearningRouteMappingTest,OnboardingRouteResponseContractTest,ScenarioCatalogControllerTest,ScenarioContentControllerTest,ScenarioSeedVersioningTest,UserScenarioStateControllerTest,HomeSummaryControllerTest" test` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `npm run check:api-contract` - passed: 50 paths, 55 operations, 28 request examples, 51 success examples, 61 error examples; Dart pre-client drift gate passed with hash `d763f44d29ac60f85d953cf302db63f23acba77d711cdb86432e1489f6f284d9`.
- `flutter test test/application/home_cards_coordinator_test.dart test/application/scene_setup_coordinator_test.dart` - passed.

Required corrections:
- None.

Residual risk:
- Generated Dart client integration remains a later client/QA increment; this increment only preserves the pre-client drift gate.
- Home summary review/weakness/unfinished-session details intentionally return explicit defaults until later practice and learning/memory increments provide live data.
- The next route may proceed to `mvp-backend-practice-ai` only after Development Orchestrator opens that increment separately.

## 2026-05-29 mvp-backend-practice-ai QA And Governance Check

Result: pass for `mvp-backend-practice-ai` only.

Checked step:
- Independent QA checker for MVP-SI-006/MVP-SI-008/MVP-SI-009, MVP-BE-FR-006/008/009, AC-MVP-BE-006/008/009, TC-MVP-BE-016 through TC-MVP-BE-025, code evidence, test evidence, and reports.
- Product Object Governance Check for the same increment, confirming no learning-memory accepted evidence, commercial membership, generated-client, release, or P0.1 planner scope was mixed into this batch.

Changed files:
- Backend implementation: practice migration, practice entities/repositories/service, AI gateway interface/service/deterministic adapter, `PracticeController`, `AiGatewayController`, backend Jackson unknown-field rejection, and home summary unfinished-session integration.
- Backend tests: `ProviderGatewaySecurityContractTest`, `ProviderGatewayControllerTest`, `ProviderGatewayFailureTest`, `ProviderGatewayAuthorizationTest`, `PracticeSessionLifecycleTest`, `PracticeTurnControllerTest`, `PracticeSessionCompletionTest`, `PracticeSessionRecoveryTest`, `CoachFeedbackContractTest`, and `FeedbackFailureHandlingTest`.
- Contract/domain/AI docs: `docs/architecture/openapi/speakeasy-api.yaml`, `docs/architecture/api_contract.md`, `docs/domain/domain_schema.md`, `docs/domain/entity_relationship.md`, `docs/ai_runtime/prompt_contract.md`, `docs/ai_runtime/llm_output_schema.md`, `docs/ai_runtime/fallback_strategy.md`, `docs/ai_runtime/ai_eval_cases.md`, and `docs/architecture/openapi/dart-client-drift-manifest.json`.
- Evidence docs: `docs/product/increments/mvp-backend-practice-ai/test_cases.md`, `docs/product/increments/mvp-backend-practice-ai/traceability.md`, `docs/reports/implementation_report.md`, `docs/reports/test_report.md`, `docs/reports/quality_report.md`.

Scope match:
- The change maps to MVP-SI-006, MVP-SI-008, and MVP-SI-009 only.
- No production Flutter source under `lib/` was changed.
- No accepted learning evidence, mastery, review scheduling, commercial provider billing/accounting, generated Dart client, release gate, P0.1 planner, micro-action, hint ladder, or pressure check was introduced.

Traceability finding:
- AC-MVP-BE-006 maps to TC-MVP-BE-016 through TC-MVP-BE-019; each TC row includes Stage Scope ID, FR, Spec, AC, traceability row, script path, execution command, result status, and evidence report.
- AC-MVP-BE-008 maps to TC-MVP-BE-020 through TC-MVP-BE-023 plus the 2026-06-09 TC-MVP-BE-047/048 trusted `audio_ref` negative regressions with the same required evidence fields.
- AC-MVP-BE-009 maps to TC-MVP-BE-024 and TC-MVP-BE-025 with backend and AI runtime evidence.
- `docs/product/increments/mvp-backend-practice-ai/traceability.md` cites the same TC IDs, implementation files, contract files, commands, pass status, and `docs/reports/test_report.md` evidence for MVP-BE-TR-006, MVP-BE-TR-008, and MVP-BE-TR-009.
- MVP-BE-GAP-005 and MVP-BE-GAP-007 are closed with dated evidence; learning-memory accepted evidence is explicitly deferred to the next increment.

Validation:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,ProviderGatewayAuthorizationTest,PracticeSessionLifecycleTest,PracticeTurnControllerTest,PracticeSessionCompletionTest,PracticeSessionRecoveryTest,CoachFeedbackContractTest,FeedbackFailureHandlingTest" test` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `npm run check:api-contract` - passed: 50 paths, 55 operations, 28 request examples, 51 success examples, 61 error examples; Dart pre-client drift gate passed with hash `e81fb612e399777241c2ab6cd2d965f972e9762cf76aaea76c94b5f71f18259c`.

Required corrections:
- None.

Residual risk:
- Deterministic provider adapters are sufficient for contract/lifecycle tests but do not validate real provider credentials, latency, retry policy, or production cost accounting.
- Accepted evidence, mastery, review scheduling, and learning history remain in `mvp-backend-learning-memory`.
- The next route may proceed to `mvp-backend-learning-memory` only after Development Orchestrator opens that increment separately.

## 2026-05-29 mvp-backend-learning-memory QA And Governance Check

Result: pass for `mvp-backend-learning-memory` only.

Checked step:
- Independent QA checker for MVP-SI-007/MVP-SI-010, MVP-BE-FR-007/010, AC-MVP-BE-007/010, TC-MVP-BE-026 through TC-MVP-BE-032, code evidence, test evidence, and reports.
- Product Object Governance Check for the same increment, confirming no commercial membership, generated-client, release, or P0.2 planner scope was mixed into this batch.

Changed files:
- Backend implementation: learning-memory migration, learning entities/repositories/service, `LearningMemoryController`, migration expected-table tests, and shared backend integration cleanup.
- Backend tests: `ExpressionQueueControllerTest`, `ExpressionQueueOrderingTest`, `ExpressionTaskProgressTest`, `FavoriteExpressionControllerTest`, `LearningEvidenceValidationTest`, `LearningEvidenceProjectionTest`, and `LearningHistoryWikiControllerTest`.
- Contract/domain docs: `docs/architecture/openapi/speakeasy-api.yaml`, `docs/architecture/api_contract.md`, `docs/domain/domain_schema.md`, `docs/domain/entity_relationship.md`, and `docs/architecture/openapi/dart-client-drift-manifest.json`.
- Evidence docs: `docs/product/increments/mvp-backend-learning-memory/test_cases.md`, `docs/product/increments/mvp-backend-learning-memory/traceability.md`, `docs/reports/implementation_report.md`, `docs/reports/test_report.md`, `docs/reports/quality_report.md`.

Scope match:
- The change maps to MVP-SI-007 and MVP-SI-010 only.
- No production Flutter source under `lib/` was changed.
- No membership/payment flow, generated Dart client, release checklist, P0.2 long-term planner, full L0-L5 mastery ladder, or new official scenario content was introduced.

Traceability finding:
- AC-MVP-BE-007 maps to TC-MVP-BE-026 through TC-MVP-BE-029; each TC row includes Stage Scope ID, FR, Spec, AC, traceability row, script path, execution command, result status, and evidence report.
- AC-MVP-BE-010 maps to TC-MVP-BE-030 through TC-MVP-BE-032 with the same required evidence fields.
- `docs/product/increments/mvp-backend-learning-memory/traceability.md` cites the same TC IDs, implementation files, contract files, commands, pass status, and `docs/reports/test_report.md` evidence for MVP-BE-TR-007 and MVP-BE-TR-010.
- MVP-BE-GAP-006 is closed with dated evidence; release evidence is explicitly N/A for this non-release increment.

Validation:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=ExpressionQueueControllerTest,ExpressionQueueOrderingTest,ExpressionTaskProgressTest,FavoriteExpressionControllerTest,LearningEvidenceValidationTest,LearningEvidenceProjectionTest,LearningHistoryWikiControllerTest" test` - passed.
- `npm run check:api-contract` - passed: 55 paths, 60 operations, 29 request examples, 55 success examples, 67 error examples; Dart pre-client drift gate passed with hash `d677224d822630f0ca30bdcdd55b8c0793b778b7e8e8a65dbfa58f38be15886e`.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Required corrections:
- None remaining.
- Full-suite regression initially exposed evidence projection FK delete-order risk; the learning migration now uses `ON DELETE SET NULL` for derived evidence references and the full backend suite passes.

Residual risk:
- Review scheduling is intentionally MVP immediate-due behavior; P0.2 long-term spaced repetition and full L0-L5 mastery remain deferred.
- Generated Dart client integration remains a later client/QA increment; this increment only preserves the pre-client drift gate.
- The next route may proceed to `mvp-backend-membership-boundary` only after Development Orchestrator opens that increment separately.

## 2026-05-29 mvp-backend-membership-boundary QA And Governance Check

Result: pass for `mvp-backend-membership-boundary` only.

Checked step:
- Independent QA checker for MVP-SI-011/MVP-SI-012, MVP-BE-FR-011/012, AC-MVP-BE-011/012, TC-MVP-BE-033 through TC-MVP-BE-038, code evidence, test evidence, and reports.
- Product Object Governance Check for the same increment, confirming no complete commercial subscription, generated-client, or release scope was mixed into this batch.

Changed files:
- Backend implementation: `AccountDeletionService`, `AuthController` deletion/status endpoints, account deletion job helpers, user deleted marker, audit constructor, and `MembershipBoundaryController`.
- Backend tests: `AccountDeletionControllerTest`, `AccountDeletionSessionInvalidationTest`, `AccountDeletionLearningDataTest`, `AccountDeletionFailureAuditTest`, `MvpMembershipBoundaryControllerTest`, and `MvpReportPlaceholderControllerTest`.
- Contract/domain docs: `docs/architecture/openapi/speakeasy-api.yaml`, `docs/architecture/api_contract.md`, `docs/domain/domain_schema.md`, `docs/domain/entity_relationship.md`, and `docs/architecture/openapi/dart-client-drift-manifest.json`.
- Evidence docs: `docs/product/increments/mvp-backend-membership-boundary/test_cases.md`, `docs/product/increments/mvp-backend-membership-boundary/traceability.md`, `docs/reports/implementation_report.md`, `docs/reports/test_report.md`, and `docs/reports/quality_report.md`.

Scope match:
- The change maps to MVP-SI-011 and MVP-SI-012 only.
- No production Flutter source under `lib/` was changed.
- No real payment provider verification, subscription lifecycle, entitlement gating, paid report, offline package, achievement engine, generated Dart client, or release checklist approval was introduced.

Traceability finding:
- AC-MVP-BE-011 maps to TC-MVP-BE-033 through TC-MVP-BE-036; each TC row includes Stage Scope ID, FR, Spec, AC, traceability row, script path, execution command, result status, and evidence report.
- AC-MVP-BE-012 maps to TC-MVP-BE-037 and TC-MVP-BE-038 with the same required evidence fields.
- `docs/product/increments/mvp-backend-membership-boundary/traceability.md` cites the same TC IDs, implementation files, contract files, commands, pass status, and `docs/reports/test_report.md` evidence for MVP-BE-TR-011 and MVP-BE-TR-012.
- MVP-BE-GAP-008 and MVP-BE-GAP-009 are closed with dated evidence; release evidence is explicitly deferred to `mvp-backend-client-qa-release`.

Validation:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test` - passed.
- `npm run check:api-contract` - passed: 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples; Dart pre-client drift gate passed with hash `506282ac758a37269df95e12ca6752de9c201eb162fd4cc0e227b13c287ab082`.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Required corrections:
- None remaining.

Residual risk:
- Production retention for object-store raw media/transcript refs still needs the owning DevOps/Security policy and implementation.
- Generated Dart client integration and release readiness remain in `mvp-backend-client-qa-release`; this increment only preserves the pre-client drift gate.
- The next route may proceed to `mvp-backend-client-qa-release` only after Development Orchestrator opens that increment separately.

## 2026-05-29 mvp-backend-client-qa-release QA And Governance Check

Result: pass for `mvp-backend-client-qa-release`; release status is ready with documented exceptions.

Checked step:
- Independent QA checker for MVP-SI-013/MVP-SI-014, MVP-BE-FR-013/014, AC-MVP-BE-013/014, TC-MVP-BE-039 through TC-MVP-BE-046, generated-client drift, full backend/Flutter regression, release checklist, version log, rollback plan, and stage traceability.
- Product Object Governance Check for the full MVP backend stage, confirming the sixth increment did not mix in full commercial payment, P0.1/P0.2 planner expansion, P1/P2 content expansion, or new Product Base scope.

Changed files:
- Client/generated boundary: `lib/generated/api/.openapi-sha256`, `lib/generated/api/speakeasy_api.dart`, `lib/services/api_client.dart`, `test/services/api_client_contract_test.dart`.
- Contract tooling: `scripts/check_openapi_dart_drift.py`, `docs/architecture/openapi/dart-client-drift-manifest.json`, `docs/architecture/api_contract.md`.
- Stage/increment/release evidence: `docs/product/stages/mvp-backend-foundation.md`, `docs/product/increments/mvp-backend-client-qa-release/test_cases.md`, `docs/product/increments/mvp-backend-client-qa-release/traceability.md`, `docs/release/release_checklist.md`, `docs/release/version_log.md`, `docs/release/rollback_plan.md`, `docs/reports/implementation_report.md`, `docs/reports/test_report.md`, and `docs/reports/quality_report.md`.

Scope match:
- The change maps to MVP-SI-013 and MVP-SI-014 only.
- It closes integration/evidence gaps for the previous five backend increments without adding new backend endpoints or expanding Product Base scope.
- Full commercial payment verification, entitlement gating, paid reports, offline packages, achievements, P0.1 planner, P0.2 long-term memory, P1/P2 content expansion, and CMS remain out of scope.

Traceability finding:
- AC-MVP-BE-013 maps to TC-MVP-BE-039 through TC-MVP-BE-042; each TC row includes Stage Scope ID, FR, Spec, AC, traceability row, script path, execution command, result status, and evidence report.
- AC-MVP-BE-014 maps to TC-MVP-BE-043 through TC-MVP-BE-046 with the same required evidence fields.
- Stage scope MVP-SI-001 through MVP-SI-014 is represented in `docs/product/stages/mvp-backend-foundation.md` and each owning increment traceability file.
- `docs/product/increments/mvp-backend-client-qa-release/traceability.md` cites code, contract, test, release, and accepted-exception evidence for MVP-BE-TR-013 and MVP-BE-TR-014.
- MVP-BE-GAP-010 and MVP-BE-GAP-011 are closed with dated evidence.

Validation:
- `npm run check:api-contract` - passed in `generated_client_drift` mode with OpenAPI hash `506282ac758a37269df95e12ca6752de9c201eb162fd4cc0e227b13c287ab082`.
- `flutter test test/services/api_client_contract_test.dart test/services/auth_service_test.dart test/application/scene_voice_session_lifecycle_coordinator_test.dart test/application/home_cards_coordinator_test.dart` - passed.
- `rg -n "MVP-SI-" docs/product/stages/mvp-backend-foundation.md docs/product/increments/mvp-backend-*` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` - passed.
- `flutter test` - passed, 173 tests.
- `git diff --check` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Required corrections:
- None remaining.

Residual risk:
- Generated Dart boundary is currently a project-local path/contract registry, not full DTO/model codegen.
- Legacy handwritten ApiClient exceptions remain visible and gate-checked; they must be burned down by their owning future increments rather than treated as silent release completion.
- This quality pass does not approve production commercial launch, real provider SLA, object-store retention implementation, paid reports, offline packages, or achievements.

## 2026-05-29 PM Backend / Database Full Review

Result: conditional pass for current `mvp-backend-foundation` runtime, database migration, API contract gate, and automated tests; blocked for accepting the literal `100% traceability` claim until the traceability evidence rows below are corrected.

PM scope:
- Request classification: review request.
- Product object mode: stage-level review for `docs/product/stages/mvp-backend-foundation.md`.
- In scope: current dirty worktree for `backend/`, Flyway migrations, OpenAPI/API contract, generated Dart boundary, six `mvp-backend-*` increments, tests, implementation/test/release/quality reports.
- Non-goals: no new Product Base scope, no P0.1 training planner implementation, no full commercial subscription launch, no P0.2/P1/P2 expansion, and no code changes.

Traceability audit:
- Checked six increments: `mvp-backend-foundation-auth`, `mvp-backend-onboarding-content`, `mvp-backend-practice-ai`, `mvp-backend-learning-memory`, `mvp-backend-membership-boundary`, and `mvp-backend-client-qa-release`.
- Stage Scope Items checked: MVP-SI-001 through MVP-SI-014, all present and mapped to increments.
- Detailed TC rows checked: TC-MVP-BE-001 through TC-MVP-BE-046, all present with Stage Scope ID, FR, Spec, AC, traceability row, gap, level, automation status, script path, command, result status, and evidence report.
- Blocker finding: some owning increment `traceability.md` Test Evidence cells cite passed tests and `docs/reports/test_report.md`, but do not include the execution command directly as required by the traceability gate.
- Affected rows: `docs/product/increments/mvp-backend-onboarding-content/traceability.md` MVP-BE-TR-003/004/005; `docs/product/increments/mvp-backend-practice-ai/traceability.md` MVP-BE-TR-006/008/009; `docs/product/increments/mvp-backend-client-qa-release/traceability.md` MVP-BE-TR-013/014.
- Correction required before literal 100% traceability acceptance: copy the exact command from the owning `test_cases.md` row into each affected `traceability.md` Test Evidence cell.
- Quality warning: `docs/product/increments/mvp-backend-membership-boundary/traceability.md` MVP-BE-TR-011/012 and `docs/product/increments/mvp-backend-client-qa-release/traceability.md` MVP-BE-TR-013/014 use compact TC ranges such as `TC-MVP-BE-033..036`; expand to explicit TC IDs for audit clarity.

Backend / DB / API architecture review:
- Implemented backend controller paths: 44 unique paths, all present in `docs/architecture/openapi/speakeasy-api.yaml`.
- OpenAPI paths not implemented by backend controllers: 18 paths in this 2026-05-29 snapshot, all outside the current MVP backend stage implementation scope or covered by documented future/commercial boundaries: `/admin/audit`, `/admin/data-deletion/{job_id}/retry`, `/entitlements/refresh`, `/subscriptions/apple/verify`, `/subscriptions/google/verify`, `/subscriptions/restore`, `/subscriptions/webhook/apple`, `/subscriptions/webhook/google`, `/training/sessions`, `/training/sessions/{session_id}`, `/training/sessions/{session_id}/complete`, `/training/sessions/{session_id}/hints`, `/training/sessions/{session_id}/planner/next`, `/training/sessions/{session_id}/pressure-check`, `/training/sessions/{session_id}/turns`, `/usage/commit`, `/usage/release`, `/usage/reserve`. Historical note: `/admin/audit` in this 2026-05-29 snapshot is superseded by the 2026-06-10 `P0-COM-ADMIN-AUDIT-ENDPOINT-20260610` closure above; `/admin/data-deletion/{job_id}/retry` is superseded by the 2026-06-10 `P0-COM-ADMIN-DATA-DELETION-RETRY-20260610` closure above.
- Scope finding: this is acceptable for `mvp-backend-foundation` because the stage explicitly excludes full commercial subscription and P0.1 planner implementation, but the project must not describe the full OpenAPI surface as backend-implemented until those owning increments implement the missing controllers and tests.
- Database review found Flyway-managed schema, JPA `ddl-auto: validate`, PostgreSQL-compatible migrations, user-owned data deletion coverage, idempotency constraints for practice turns and usage reservations, and server-owned auth/session/learning facts aligned with the backend foundation architecture.
- Security/API review found no production `X-User-Id` reliance, no client-submitted provider secret boundary in backend code, server-side bearer auth on protected paths, `schema_version` request validation, shared error schema, and `Idempotency-Key` enforcement on practice turns and account deletion.

Validation rerun:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `npm run check:api-contract` - first failed inside sandbox because `uv` panicked in system configuration access; rerun outside sandbox passed: 62 paths, 67 operations, 29 request examples, 62 success examples, 74 error examples; generated Dart drift passed with OpenAPI hash `506282ac758a37269df95e12ca6752de9c201eb162fd4cc0e227b13c287ab082`, 67 operations, 117 schemas.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- Surefire summary after rerun: 39 XML reports, 82 tests, 0 failures, 0 errors, 0 skipped.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PostgresFoundationMigrationTest test` outside sandbox - passed against PostgreSQL 15.18 and applied all five migrations through version `202605290003`.
- `flutter test` - passed, 173 tests.

Required corrections:
- Update the eight affected traceability rows so each Test Evidence cell contains TC ID, script path, exact execution command, result status, and evidence report in the traceability row itself.
- Expand compact TC ranges in membership/client QA traceability rows into explicit TC ID lists.
- Keep the 18 OpenAPI-only paths marked as out of current MVP backend implementation scope unless their owning P0/P0.1 increments are opened and implemented.

Residual risk:
- The current runtime/test/code path is green for the MVP backend stage, but the traceability document rows are not yet strict enough to support a literal `100% traceability` acceptance statement.
- The full OpenAPI source of truth includes future/commercial/training planner paths that are not implemented by backend controllers in this stage.
- This review does not approve production commercial payment, real provider SLA, object-store retention, P0.1 planner, P0.2 memory, P1/P2 content expansion, or CMS.

## 2026-05-29 Traceability Blocker Resolved

Result: traceability blocker resolved for the affected MVP backend stage evidence rows.

Corrections applied:
- `docs/product/increments/mvp-backend-onboarding-content/traceability.md` MVP-BE-TR-003, MVP-BE-TR-004, and MVP-BE-TR-005 now include explicit TC IDs, script paths, execution commands, result status, and evidence report links copied from the owning `test_cases.md` rows.
- `docs/product/increments/mvp-backend-practice-ai/traceability.md` MVP-BE-TR-006, MVP-BE-TR-008, and MVP-BE-TR-009 now include the same required Test Evidence fields.
- `docs/product/increments/mvp-backend-membership-boundary/traceability.md` MVP-BE-TR-011 and MVP-BE-TR-012 no longer use compact TC ranges and now list TC-MVP-BE-033 through TC-MVP-BE-038 explicitly with script path, command, result, and evidence.
- `docs/product/increments/mvp-backend-client-qa-release/traceability.md` MVP-BE-TR-013 and MVP-BE-TR-014 no longer use compact TC ranges and now list TC-MVP-BE-039 through TC-MVP-BE-046 explicitly, including the documented exception command/result for TC-MVP-BE-042.

Validation:
- `python3 scripts/project_agent_runner.py validate` - passed.
- Traceability evidence audit - passed: 10 affected rows and 30 TC mappings checked against the owning `test_cases.md`; compact ranges removed.
- `git diff --check` - passed.

PM release decision:
- The prior traceability evidence blocker is removed for the reviewed affected rows.
- This is a documentation evidence correction only; it does not change backend implementation scope, database scope, OpenAPI scope, or the documented future/commercial/P0.1 non-goals.

## 2026-05-29 mvp-system-e2e-validation QA And Governance Check

Result: pass for `mvp-system-e2e-validation` local system gate. TC-MVP-E2E-001 through TC-MVP-E2E-010 have script, command, result, and report evidence; TC-MVP-E2E-010 retains only the real payment provider sub-scope as manual/external.

Checked step:
- Step 1 independent audit verified the system E2E test case library has 10 stable TC rows and covers Product Base AC-001 through AC-013 without blank required fields.
- Step 2 independent audit verified `MVP-SI-014 -> MVP-E2E-FR-* -> MVP-E2E-SPEC-* -> AC-MVP-E2E-* -> MVP-E2E-TR-* -> TC-MVP-E2E-* -> report evidence` is connected.
- Step 3 independent audit verified executable smoke/deep E2E gates, coverage audit, Flutter regression, project governance validation, and diff whitespace check.

Changed files reviewed:
- Product/docs: `docs/product/increments/mvp-system-e2e-validation/`, `docs/product/stages/mvp-backend-foundation.md`, `docs/product/roadmap.md`, `docs/reports/test_report.md`, `docs/reports/implementation_report.md`, `docs/reports/mvp_system_e2e_handoff.md`.
- Automation: `scripts/run_mvp_system_e2e.sh`, `scripts/check_mvp_system_e2e_coverage.py`, `integration_test/mvp_system_smoke_test.dart`, `integration_test/mvp_system_scene_catalog_test.dart`, `integration_test/mvp_system_learning_memory_test.dart`, `integration_test/mvp_system_practice_feedback_test.dart`, `integration_test/mvp_system_profile_settings_test.dart`, `integration_test/mvp_system_membership_boundary_test.dart`, `integration_test/support/mvp_e2e_test_helpers.dart`.
- App support: `lib/pages/login_page.dart`, `lib/pages/onboarding_page.dart`, `lib/pages/home_page.dart`, `lib/features/interview/interview_scene_listening_page.dart`, `lib/pages/profile_page.dart`, `lib/pages/edit_profile_page.dart`, `lib/pages/membership_page.dart`, `lib/pages/favorites_page.dart`, `lib/pages/feature_placeholder_page.dart`, `lib/main.dart`, `lib/services/api_client.dart`, `lib/services/app_session.dart`, `lib/application/session/session_profile_coordinator.dart`, `lib/core/bootstrap/app_bootstrapper.dart`, `lib/services/storage_service.dart`.
- macOS/dependencies: `macos/Podfile`, `macos/Runner.xcodeproj/project.pbxproj`, `macos/Runner/DebugProfile.entitlements`, `pubspec.yaml`, `pubspec.lock`.

Scope match:
- The work stays inside MVP-SI-014 QA/system validation hardening.
- It fixes client/backend contract mismatches found by E2E where needed to make existing MVP behavior persist correctly; it does not add production payment behavior, P0.1 training planner behavior, P0.2 memory behavior, or P1/P2 content expansion.
- Docker is not required; the local gate uses installed PostgreSQL binaries and still validates real PostgreSQL rather than H2.

Traceability finding:
- AC-MVP-E2E-001 maps to TC-MVP-E2E-001 and passed.
- AC-MVP-E2E-002 maps to TC-MVP-E2E-002 and TC-MVP-E2E-003 and passed.
- AC-MVP-E2E-003 maps to TC-MVP-E2E-004 and TC-MVP-E2E-006 through TC-MVP-E2E-010 and passed, with TC-MVP-E2E-010 payment provider marked external/manual.
- AC-MVP-E2E-004 maps to TC-MVP-E2E-005 and passed.
- Product Base AC-001 through AC-013 are all represented in `test_cases.md`; AC-004 through AC-011 now have executed deep local system evidence, and AC-012/AC-013 preserve only the real payment/provider boundary exception.

Validation:
- `scripts/run_mvp_system_e2e.sh` - passed with local PostgreSQL + backend + Flutter macOS integration test.
- `scripts/run_mvp_system_e2e.sh --suite scene-catalog` - passed.
- `scripts/run_mvp_system_e2e.sh --suite learning-memory` - passed.
- `scripts/run_mvp_system_e2e.sh --suite practice-feedback` - passed.
- `scripts/run_mvp_system_e2e.sh --suite profile-settings` - passed.
- `scripts/run_mvp_system_e2e.sh --suite membership-boundary` - passed.
- `python3 scripts/check_mvp_system_e2e_coverage.py` - passed: 10 TC rows, 13 Product Base AC rows, 4 traceability rows.
- `flutter test` - passed, 173 tests.
- `env JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` from `backend/` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- Closed before final acceptance: the shared E2E helper was changed to drive onboarding through real Flutter UI clicks instead of completing onboarding through a session shortcut, and smoke plus TC-MVP-E2E-006 through TC-MVP-E2E-010 were rerun successfully.

Residual risk:
- `/user/stats` remains a logged non-blocking backend/client mismatch and should not be hidden by the smoke pass.
- macOS notification initialization remains a logged soft failure in the local E2E environment.
- TC-MVP-E2E-008 proves deterministic practice/coach/evidence behavior, not real third-party LLM/ASR/TTS quality or SLA.
- TC-MVP-E2E-010 proves membership boundary UI, not real purchase, restore, webhook, refund, or provider settlement behavior.

## 2026-05-29 commercial-subscription-readiness Gate Review

Result: pass for pre-implementation contract and AC-to-TC gate only. This review does not approve commercial release readiness.

Findings:
- No blocker remains for routing the next implementation packages after this gate. `P0-COM-DOM-001`, `P0-COM-API-001`, `P0-COM-ARCH-001`, `P0-COM-UX-001`, and `P0-COM-QA-001` have documented downstream evidence.
- No Backend, Frontend, AI Runtime, or DevOps implementation was started in this step. The generated Dart OpenAPI boundary and hash were synchronized only because the OpenAPI contract changed and the drift gate requires it.
- No Product Base or stage scope expansion was introduced. The review keeps `commercial-subscription-readiness` as the owning increment for `COM-SI-001` through `COM-SI-012`.

Checked step:
- Development Orchestrator routing evidence for `P0-COM-DOM-001`, `P0-COM-API-001`, `P0-COM-ARCH-001`, `P0-COM-UX-001`, and `P0-COM-QA-001`.
- Document traceability from requirements to acceptance criteria to test cases.
- Product Object Governance Check for scope boundaries, stage object ownership, and no implementation-before-test-case violation.
- Code Review Quality gate for changed docs, OpenAPI contract, generated boundary hash, validation results, and release risk.

Changed files reviewed:
- Product/increment docs: `docs/product/increments/commercial-subscription-readiness/definition.md`, `requirements.md`, `spec.md`, `acceptance.md`, `traceability.md`, and `test_cases.md`.
- Stage/status docs: `docs/product/stages/p0-commercial-readiness.md` and `docs/product/development_status.md`.
- Domain/architecture/UX contracts: `docs/domain/domain_schema.md`, `docs/domain/entity_relationship.md`, `docs/architecture/api_contract.md`, `docs/architecture/system_overview.md`, `docs/architecture/security_design.md`, `docs/architecture/openapi/speakeasy-api.yaml`, `docs/ux/screen_spec.md`, `docs/ux/user_flow.md`, `docs/ux/copywriting_guideline.md`, and `docs/ux/usability_checklist.md`.
- Generated contract boundary: `docs/architecture/openapi/dart-client-drift-manifest.json`, `lib/generated/api/.openapi-sha256`, and `lib/generated/api/speakeasy_api.dart`.
- Evidence reports: `docs/reports/test_report.md` and `docs/reports/quality_report.md`.

Traceability finding:
- Stage scope coverage is complete for this pre-implementation gate: `COM-SI-001` through `COM-SI-012` all map to stable test cases.
- Requirement coverage is complete: `FR-COM-001` through `FR-COM-012` all map through accepted AC IDs to one or more `TC-COM` rows.
- Acceptance coverage is complete: `AC-COM-001` through `AC-COM-014` all map to one or more stable test cases.
- `docs/product/increments/commercial-subscription-readiness/test_cases.md` contains 23 `TC-COM` rows. Each row includes Stage Scope ID, FR, Spec, AC, Traceability Row, Gap, test level, automation status, script path, execution command, result status, and evidence report.
- `TC-COM-023` is passed for the OpenAPI contract gate. `TC-COM-001` through `TC-COM-022` remain planned and block commercial release readiness until implemented and executed.

Validation:
- `npm run check:api-contract` - passed: OpenAPI contract gate passed with 62 paths, 67 operations, 29 request examples, 62 success examples, and 74 error examples; Dart generated-client drift gate passed with OpenAPI hash `4a0a9978ba4dec45d1df598bc0cd39770fd5eaa021fc6f7fe2ce47f16d0fb63a`, 67 operations, and 117 schemas.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.
- `awk` TC row audit - passed: 23 `TC-COM` rows, no malformed row field count reported.
- `awk` coverage audits - passed: `COM-SI-001..012`, `FR-COM-001..012`, and `AC-COM-001..014` all have test-case coverage.

Required corrections:
- None remaining for this pre-implementation gate.

Residual risk:
- The project is not commercial release ready.
- `TC-COM-001` through `TC-COM-022` are planned but not implemented or executed.
- Apple sandbox, Google Play internal testing, refund/expiry/provider event evidence, social login production configuration, store metadata, privacy/support URLs, release secrets, signing, symbols, rollback evidence, implementation report, and release decision remain future blockers.
- This review only authorizes the next Development Orchestrator implementation routing; it does not authorize skipping the planned backend, frontend, provider, release, or QA execution gates.

## 2026-05-29 P0-COM-BE-001 Independent Review

Result: pass for `P0-COM-BE-001` only.

Checked step:
- Commercial foundation hardening after AC-to-TC gate: ops auth for release health, account deletion idempotency, auth/session retry boundary, entitlement/usage read foundation regression, and audit evidence.
- Scope guard: confirmed no `P0-COM-BE-002` entitlement/usage gating, no `P0-COM-BE-003` Apple/Google provider verify/webhook, no Flutter commercial UI, and no DevOps release gate implementation was added.

Changed files:
- Backend auth/security: `BearerTokenAuthenticationFilter.java`, `SecurityConfig.java`, `AuthService.java`, and `application-test.yml`.
- Account deletion persistence/service: `V202605290004__commercial_foundation_hardening.sql`, `AccountDeletionJob.java`, `AccountDeletionJobRepository.java`, and `AccountDeletionService.java`.
- Backend tests: `CommercialAccountDeletionProcessorTest.java` and `CommercialFoundationControllerTest.java`.
- Evidence report: `docs/reports/implementation_report.md`.

Findings:
- No blocker. The ops bearer token is only accepted for admin paths, so it cannot accidentally satisfy normal user endpoints that require `CurrentUser`.
- No blocker. Deletion idempotency returns the existing job before active-user validation, allowing same-key retry after session revocation without re-running purge/audit side effects.
- No blocker. User bearer tokens no longer satisfy `/admin/release-health`; the endpoint returns `FORBIDDEN` for normal users and succeeds only with ops bearer evidence.

Validation:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CommercialFoundationControllerTest,CommercialAccountDeletionProcessorTest,AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest test` - passed.

Required corrections:
- None for this step.

Residual risk:
- This is not commercial release readiness. Provider verification, entitlement/usage gating, Flutter commercial UI, release scripts, store metadata, and QA execution remain pending in later steps.

## 2026-05-29 P0-COM-BE-002 Independent Review

Result: pass for `P0-COM-BE-002` only.

Checked step:
- Entitlement refresh, paid scenario-level gating, usage reserve/commit/release lifecycle, high-cost AI/ASR/TTS/scoring quota enforcement, and audit evidence.
- Scope guard: confirmed no Apple/Google provider verification, webhook processing, Flutter UI, DevOps release scripts, or commercial release decision was added.

Changed files:
- Backend services/controllers: `EntitlementGateService.java`, `UsageService.java`, `UsageReservationRepository.java`, `UsageLedger.java`, `UsageReservation.java`, `CommercialFoundationController.java`, `AiGatewayService.java`, `AiGatewayController.java`, `OnboardingContentService.java`, and `PracticeService.java`.
- Backend test support/tests: `BackendIntegrationTestSupport.java`, `EntitlementGateServiceTest.java`, `UsageQuotaGateTest.java`, `UsageReservationLifecycleTest.java`, and `CommercialAbuseControlTest.java`.
- Evidence report: `docs/reports/implementation_report.md`.

Findings:
- No blocker. The first BE-002 validation run found a real read-only transaction defect in `AiGatewayService.coach`; the method now uses a write transaction and the same routed test set passes.
- No blocker. Quota exhaustion is checked before provider invocation, so high-cost calls do not spend provider resources when the server ledger is exhausted.
- No blocker. Paid scenario gating is attached to both scenario-level content and practice session start, keeping list/detail/training entrance behavior consistent for the L3 paid fixture.

Validation:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=EntitlementGateServiceTest,UsageQuotaGateTest,UsageReservationLifecycleTest,CommercialAbuseControlTest,ProviderGatewayControllerTest,ProviderGatewayAuthorizationTest test` - failed before fix, then passed after the transaction correction.

Required corrections:
- None remaining for this step.

Residual risk:
- Paid entitlement creation still depends on provider verification in `P0-COM-BE-003`; this step proves gating once entitlement facts exist.
- Full commercial packaging, Flutter paywall behavior, provider sandbox evidence, and release checks remain pending in later steps.

## 2026-05-29 P0-COM-BE-003 Independent Review

Result: pass for `P0-COM-BE-003` local provider-boundary implementation only.

Checked step:
- Apple/Google verify endpoints, restore endpoint, provider webhook signature gate, provider event idempotency, refund/expiry/revoke downgrade behavior, and deterministic backend tests for TC-COM-001 through TC-COM-006.
- Scope guard: confirmed no Flutter UI, DevOps release gate, store metadata, signing, or real external sandbox execution was added or claimed.

Changed files:
- Backend provider boundary: `PaymentProviderService.java`, `CommercialFoundationController.java`, `SecurityConfig.java`, and `application-test.yml`.
- Commerce persistence: `Purchase.java`, `Subscription.java`, `PaymentProviderEvent.java`, `EntitlementSnapshot.java`, `PurchaseRepository.java`, `SubscriptionRepository.java`, `PaymentProviderEventRepository.java`, and `SubscriptionPlanRepository.java`.
- Deletion cleanup: `AccountDeletionService.java`.
- Backend tests: `AppleSubscriptionVerificationTest.java`, `GoogleSubscriptionVerificationTest.java`, `SubscriptionCredentialValidationTest.java`, `SubscriptionRestoreTest.java`, `SubscriptionRestoreEmptyTest.java`, and `PaymentProviderEventDowngradeTest.java`.
- Evidence report: `docs/reports/implementation_report.md`.

Findings:
- No blocker. Verify/restore/webhook behavior is tested through server-side deterministic fixtures and preserves server-owned entitlement facts.
- No blocker. Invalid provider credentials or user mismatch return typed errors and do not create entitlement snapshots.
- No blocker. Webhook events are signature-gated and duplicate provider event ids do not reprocess downgrade side effects.

Validation:
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AppleSubscriptionVerificationTest,GoogleSubscriptionVerificationTest,SubscriptionCredentialValidationTest,SubscriptionRestoreTest,SubscriptionRestoreEmptyTest,PaymentProviderEventDowngradeTest test` - passed.

Required corrections:
- None for this step.

Residual risk:
- This pass does not satisfy TC-COM-019. Real Apple sandbox and Google Play internal test evidence remain external blockers.
- Production provider credentials, signing keys, product allowlists, provider webhook registration, and store console state remain release/DevOps blockers.

## 2026-05-29 P0-COM-FE-001 Independent Review

Result: pass for `P0-COM-FE-001` Flutter commercial subscription integration only.

Checked step:
- Flutter client API boundary for Apple verify, Google verify, restore, entitlement refresh, account deletion idempotency, membership downgrade UI, commercial copy safety, and local account deletion cleanup.
- Scope guard: confirmed no DevOps release script, store metadata, signing, real provider sandbox/internal evidence, or commercial release decision was added or claimed.

Changed files:
- Flutter services: `lib/services/api_client.dart`, `lib/services/apple_payment_service.dart`, `lib/services/android_payment_service.dart`, and `lib/services/app_session.dart`.
- Flutter UI: `lib/pages/membership_page.dart`.
- Flutter tests: `test/features/commercial/entitlement_downgrade_widget_test.dart`, `test/features/commercial/account_deletion_cleanup_test.dart`, and `test/services/api_client_contract_test.dart`.
- Contract drift metadata: `docs/architecture/openapi/dart-client-drift-manifest.json`.
- Backend test isolation cleanup: `CommercialFoundationControllerTest.java`, `FoundationErrorContractTest.java`, `FoundationResponseContractTest.java`, `AuthControllerTest.java`, `AuthServiceTest.java`, and `AuthSessionLifecycleTest.java`.
- Evidence report: `docs/reports/implementation_report.md`.

Findings:
- No blocker. The legacy `/payments/apple/verify-receipt` handwritten path is removed and Flutter now uses generated OpenAPI path constants for Apple verify, Google verify, restore, and entitlement refresh.
- No blocker after correction. Provider verify/restore idempotency keys are stable across retries: Apple uses transaction id, Google uses purchase token, and restore uses platform.
- No blocker after correction. Account deletion now reuses the same client idempotency key during a failed same-attempt retry, matching the backend retry boundary from `P0-COM-BE-001`.
- No blocker after correction. Android purchase no longer returns a hardcoded “not connected” error; it uses the Google Play purchase stream and verifies purchase tokens through the backend before returning success.
- No blocker. Membership page copy no longer promises offline packages or dedicated reports as paid benefits, and the free entitlement downgrade banner is covered by a widget test.

Validation:
- `flutter analyze lib/services/app_session.dart lib/services/api_client.dart lib/services/apple_payment_service.dart lib/services/android_payment_service.dart lib/pages/membership_page.dart test/features/commercial/entitlement_downgrade_widget_test.dart test/features/commercial/account_deletion_cleanup_test.dart test/services/api_client_contract_test.dart` - passed.
- `flutter test test/features/commercial/entitlement_downgrade_widget_test.dart test/features/commercial/account_deletion_cleanup_test.dart test/services/api_client_contract_test.dart` - passed.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=CommercialFoundationControllerTest,FoundationErrorContractTest,FoundationResponseContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest test` - passed.
- `git diff --check` - passed before report update.
- `python3 scripts/project_agent_runner.py validate` - passed before report update.

Required corrections:
- Closed before final acceptance: timestamp-based provider idempotency keys were replaced with stable transaction/token/platform keys.
- Closed before final acceptance: same-attempt account deletion retry now reuses the idempotency key.
- Closed before final acceptance: Android purchase was wired to Google Play purchase updates plus backend verification.
- Closed before final acceptance: the account deletion unit test now injects a non-platform payment service so it does not initialize real IAP channels.

Residual risk:
- This pass does not satisfy TC-COM-019. Real App Store sandbox and Google Play internal-track purchase/restore/refund/expiry/grace-period/account-switch evidence remain external blockers.
- The Apple client currently uses the transaction id as the original transaction id fallback; real StoreKit sandbox validation must confirm whether a separate original transaction id is required for production-grade restore history.
- Backend `subscription_plans` product allowlists must be aligned with App Store Connect and Play Console product ids before release.

## 2026-05-29 P0-COM-REL-001 Independent Review

Result: pass for `P0-COM-REL-001` release gate implementation only. Commercial release readiness remains blocked, as intended.

Checked step:
- Release configuration script, social-login release script, aggregate commercial readiness script, GitHub release workflow integration, commercial runbook, release checklist, rollback plan, and version log.
- Scope guard: confirmed no production secrets were committed and no real Apple sandbox / Google Play internal-track evidence was claimed.

Changed files:
- Release scripts: `scripts/check_release_configuration.sh`, `scripts/check_social_login_release_config.sh`, and `scripts/check_release_readiness.sh`.
- Release workflow: `.github/workflows/release.yml`.
- Release docs: `docs/release/commercial_release_runbook.md`, `docs/release/release_checklist.md`, `docs/release/rollback_plan.md`, and `docs/release/version_log.md`.
- Evidence report: `docs/reports/implementation_report.md`.

Findings:
- No blocker. The aggregate release gate fails before signing/build artifact creation in `.github/workflows/release.yml`, so missing commercial evidence cannot be bypassed by the release build.
- No blocker. TC-COM-019 remains an external/manual provider evidence gate; scripts require evidence references and do not pretend to execute real provider sandbox/internal tests.
- No blocker. Strict mode correctly blocks the current repository because iOS still contains the placeholder WeChat URL scheme and lacks the Apple Sign In entitlement.
- No blocker after correction. The readiness gate now requires symbol upload evidence and rollback rehearsal evidence in addition to Sentry DSN and rollback docs.

Validation:
- `bash -n scripts/check_release_configuration.sh scripts/check_social_login_release_config.sh scripts/check_release_readiness.sh` - passed.
- `APP_API_BASE_URL=https://api.speakeasyapp.com ENV=production ENABLE_TEST_PHONE_LOGIN=false scripts/check_release_configuration.sh` - passed.
- `WECHAT_APP_ID=wx1234567890abcdef WECHAT_UNIVERSAL_LINK=https://app.speakeasyapp.com/app/ scripts/check_social_login_release_config.sh --env-only` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, Sentry, Android signing, Apple/Google provider evidence refs, store metadata ref, reviewer account ref, symbol upload ref, rollback rehearsal ref, privacy URL, and support URL - passed.
- Same fixture `scripts/check_release_readiness.sh` in strict mode - failed as expected with native iOS social-login blockers.
- `git diff --check` - passed before report update.
- `python3 scripts/project_agent_runner.py validate` - passed before report update.

Required corrections:
- Closed before final acceptance: readiness gate now checks `SYMBOL_UPLOAD_EVIDENCE_REF` and `ROLLBACK_REHEARSAL_REF`, not only Sentry DSN and rollback document existence.
- Closed before final acceptance: macOS bash 3.2 incompatible lowercasing was replaced with `tr` in `scripts/check_release_configuration.sh`.

Residual risk:
- This step establishes release blocking gates; it does not configure real WeChat AppID/native URL scheme, Apple Sign In entitlement, signing secrets, Sentry upload credentials, or store/provider evidence.
- Current strict commercial release readiness should fail until those external/native configurations and evidence refs are supplied.

## 2026-05-29 P0-COM-QA-002 Independent Review

Result: pass for QA evidence integrity and traceability. Not a commercial release pass.

Checked step:
- Re-executed automated commercial backend tests, Flutter commercial tests, OpenAPI contract gate, and release readiness fixture gate.
- Updated increment traceability with actual code evidence, test evidence, release evidence, statuses, and remaining blockers.
- Confirmed requirements and acceptance criteria still map to TC IDs; blocked/manual/external TCs are explicit and not marked passed.

Findings:
- No blocker for proceeding to Step 7 reporting. FR-COM-001 through FR-COM-012 and AC-COM-001 through AC-COM-014 retain 100% mapping to TC-COM IDs.
- No blocker. Automated local evidence is separated from real provider/store evidence; TC-COM-019 and TC-COM-021 are not falsely marked passed.
- No blocker. Strict release readiness correctly fails on current native iOS social-login blockers, while fixture mode proves the aggregate gate logic.
- No blocker. The OpenAPI gate failure in the sandbox was environmental (`uv` panic); the same command passed outside sandbox with the approved rerun.

Validation:
- Backend commercial Maven test set - passed.
- Flutter commercial/API contract tests - passed.
- `npm run check:api-contract` - passed outside sandbox after sandbox `uv` panic.
- Release scripts syntax and fixture readiness gate - passed.
- Strict release readiness fixture - failed as expected on native iOS WeChat URL scheme and Apple Sign In entitlement.
- `docs/product/increments/commercial-subscription-readiness/traceability.md` now records passed, blocked, manual, and external status by traceability row.

Required corrections:
- None remaining for Step 6.

Residual risk:
- TC-COM-010 is closed by `P0-COM-SCENARIO-GATE-001`; TC-COM-016 is closed by `P0-COM-COPY-001`; TC-COM-020 is closed by `P0-COM-PROVIDER-EVIDENCE-001`; TC-COM-015 external evidence, TC-COM-019 external evidence, and TC-COM-021 external evidence remain release blockers.
- Strict TC-COM-012 and TC-COM-022 remain blocked until native iOS social-login configuration and external evidence refs are supplied.
- Step 7 must summarize this as partial implementation/QA completion, not commercial release readiness.

## 2026-05-29 P0-COM-REPORT-001 Final Independent Review

Result: pass for final reporting, traceability integrity, and blocker preservation. Not a commercial release pass.

Checked step:
- Final summary across `P0-COM-BE-001`, `P0-COM-BE-002`, `P0-COM-BE-003`, `P0-COM-FE-001`, `P0-COM-REL-001`, `P0-COM-QA-002`, and `P0-COM-REPORT-001`.
- Evidence alignment across `docs/reports/implementation_report.md`, `docs/reports/test_report.md`, `docs/product/increments/commercial-subscription-readiness/traceability.md`, and `docs/product/increments/commercial-subscription-readiness/test_cases.md`.
- Review requirement that every completed step has an independent review entry and that incomplete/manual/external TC-COM items are not marked as release-ready.

Findings:
- No blocker for closing the 1-7 execution sequence. Each implementation/QA/release/reporting step has a corresponding quality review entry with scoped validation evidence.
- No blocker. FR-COM-001 through FR-COM-012, AC-COM-001 through AC-COM-014, and TC-COM-001 through TC-COM-023 remain fully traceable; blocked/manual/external rows are represented as explicit release blockers rather than missing coverage.
- No blocker. Final implementation reporting correctly states `Not release ready`; TC-COM-010, TC-COM-016, and TC-COM-020 are now closed, while TC-COM-015 external evidence, TC-COM-019 external evidence, TC-COM-021 external evidence, and strict TC-COM-012/022 remain blockers.
- No blocker. The sandbox-only `uv` panic for `npm run check:api-contract` is recorded as an environmental rerun case; the approved outside-sandbox rerun passed and is reflected in QA evidence.

Validation:
- Backend commercial Maven test set - passed during Step 6 QA.
- Flutter commercial/API contract tests - passed during Step 6 QA.
- `npm run check:api-contract` - passed outside sandbox after the sandbox `uv` panic.
- Release readiness fixture gate - passed; strict release readiness failed as expected on native iOS social-login blockers.
- Final FR/AC/TC coverage audit - passed with no missing FR, AC, or TC links.
- `git diff --check` - passed after final report update.
- `python3 scripts/project_agent_runner.py validate` - passed after final report update.

Required corrections:
- None remaining for the 1-7 execution sequence.

Residual risk:
- The project is still not commercial release ready.
- Remaining work must close the documented blockers before PM can approve launch: copy review/automation, real Apple sandbox and Google Play internal evidence, commercial boundary E2E, store metadata/privacy/support/subscription terms/reviewer account evidence, and native social-login configuration.

## 2026-05-29 P0-COM-SCENARIO-GATE-001 Independent Review

Result: pass for scenario gate blocker closure. Not a commercial release pass.

Checked step:
- Reviewed TC-COM-010 implementation and tests after code changes.
- Confirmed the gate is shared across direct training entry, scene navigation target-level switching, and Home scene entry paths.
- Confirmed traceability, test report, and implementation report mark only TC-COM-010 as closed and preserve other blockers.

Findings:
- No blocker. `CommercialScenarioGate` centralizes the paid L3 policy and avoids divergent lock decisions between list/detail/training entry.
- No blocker. Free users are blocked from L3 direct training and see L3 as locked in scene navigation; Pro users can switch to L3 and train on L3 expressions.
- No blocker. Existing interview widget tests still pass after the gating changes.
- No blocker. Test-only entitlement injection in `InterviewPracticePage` defaults to `AppSessionScope.of(context).isPro`, so production entitlement source remains unchanged.

Validation:
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart --plain-name "免费用户训练入口" --timeout 30s` - passed.
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart` - passed.
- `flutter test test/features/commercial/scenario_gating_consistency_test.dart test/features/interview/interview_practice_page_widget_test.dart` - passed.
- `flutter analyze lib/features/commercial/commercial_scenario_gate.dart lib/features/interview/interview_practice_page.dart lib/pages/home_page.dart test/features/commercial/scenario_gating_consistency_test.dart test/features/interview/interview_practice_page_widget_test.dart` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.

Required corrections:
- Closed during implementation: removed `Future.delayed(Duration.zero)` waits from widget-test helpers because they deadlocked under fake async before `tester.pump`.
- Closed during implementation: scene-map dropdown test now waits for route transition completion before tapping the level menu.

Residual risk:
- TC-COM-016 is closed by `P0-COM-COPY-001`; TC-COM-020 is closed by `P0-COM-PROVIDER-EVIDENCE-001`; TC-COM-015 external evidence, TC-COM-019 external evidence, TC-COM-021 external evidence, and strict TC-COM-012/022 remain release blockers.
- Real provider/store evidence and commercial boundary E2E were intentionally not executed in this package.

## 2026-05-29 P0-COM-COPY-001 Independent Review

Result: pass for local commercial copy blocker closure. Not a commercial release pass.

Checked step:
- Reviewed profile upsell copy, membership copy contract, release checklist/runbook integration, and test/report traceability.
- Confirmed TC-COM-016 is automated and passed.
- Confirmed TC-COM-015 is only marked internal passed / external pending, not falsely closed.

Findings:
- No blocker. The app no longer promises “无限场景练习” in the profile membership upsell; the replacement copy names shipped benefits.
- No blocker. `scripts/check_commercial_copy_contract.py` verifies membership benefit names, plan/product IDs, profile upsell copy, and release copy gate documentation.
- No blocker. `scripts/check_release_readiness.sh` now runs the copy contract in strict external mode before release.
- No blocker. Missing store metadata, privacy URL, and support URL are represented as release blockers rather than hidden passes.

Validation:
- `python3 scripts/check_commercial_copy_contract.py` - passed and reported external evidence blockers.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, provider/store/reviewer/symbol/rollback evidence refs, privacy URL, support URL, Sentry, and Android signing vars - passed.
- `flutter test test/features/commercial/entitlement_downgrade_widget_test.dart` - passed.
- `flutter analyze lib/pages/profile_page.dart lib/pages/membership_page.dart test/features/commercial/entitlement_downgrade_widget_test.dart` - passed.
- `bash -n scripts/check_release_readiness.sh` - passed.

Required corrections:
- None remaining for TC-COM-016.

Residual risk:
- TC-COM-015 still needs external store metadata, privacy/support copy, and screenshot/evidence references.
- TC-COM-020 is closed by `P0-COM-PROVIDER-EVIDENCE-001`; TC-COM-019 external evidence, TC-COM-021 external evidence, and strict TC-COM-012/022 remain release blockers.

## 2026-05-29 P0-COM-PROVIDER-EVIDENCE-001 Independent Review

Result: pass for local provider evidence gate and commercial boundary coverage. Not a commercial release pass.

Checked step:
- Reviewed TC-COM-019 matrix coverage and strict evidence gate behavior.
- Reviewed TC-COM-020 local boundary test coverage.
- Confirmed release readiness includes provider evidence gate and still blocks missing real provider evidence.

Findings:
- No blocker. TC-COM-019 matrix enumerates Apple sandbox and Google Play internal purchase, restore, refund/revoke, expiry, grace-period, and account-switch scenarios.
- No blocker. `scripts/check_provider_sandbox_evidence.py` reports missing external evidence refs in default mode and fails them in strict mode.
- No blocker. Aggregate release readiness now runs provider evidence validation before declaring release readiness.
- No blocker. TC-COM-020 local integration test covers first-install membership gate, legacy plan normalization, L3 entitlement lock, and weak-network/provider-error recovery UI.
- No blocker. Real provider evidence is not falsely marked passed.

Validation:
- `python3 scripts/check_provider_sandbox_evidence.py` - passed and reported external evidence blockers.
- `python3 -m py_compile scripts/check_provider_sandbox_evidence.py scripts/check_commercial_copy_contract.py` - passed.
- `bash -n scripts/run_mvp_system_e2e.sh scripts/check_release_readiness.sh` - passed.
- `flutter test integration_test/commercial_boundary_test.dart` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, provider/store/reviewer/symbol/rollback evidence refs, privacy URL, support URL, Sentry, and Android signing vars - passed.

Required corrections:
- None remaining for TC-COM-020.

Residual risk:
- TC-COM-019 still requires real Apple sandbox and Google Play internal-track evidence refs.
- TC-COM-015 external evidence, TC-COM-021, and strict TC-COM-012/022 remain release blockers.

## 2026-05-29 P0-COM-STORE-001 Independent Review

Result: pass for local store evidence gate and release readiness aggregation. Not a commercial release pass.

Checked step:
- Reviewed TC-COM-021 store submission matrix and strict evidence gate behavior.
- Reviewed aggregate release readiness after adding copy, provider, and store evidence gates.
- Confirmed strict release gate fails on real native blockers and is not marked as release approval.

Findings:
- No blocker. Store submission matrix covers store metadata, subscription terms, privacy labels/Data safety, privacy URL, support URL, and reviewer account evidence.
- No blocker. `scripts/check_store_submission_evidence.py` reports missing external store evidence in default mode and fails it in strict mode.
- No blocker. Aggregate release readiness now runs release config, copy contract, provider evidence, store evidence, social login, secrets, URLs, symbols, and rollback checks.
- No blocker. Strict release gate fails on iOS placeholder WeChat URL scheme and missing Apple Sign In entitlement, which are true remaining native blockers.

Validation:
- `python3 scripts/check_store_submission_evidence.py` - passed and reported external evidence blockers.
- `python3 -m py_compile scripts/check_store_submission_evidence.py scripts/check_provider_sandbox_evidence.py scripts/check_commercial_copy_contract.py` - passed.
- `bash -n scripts/check_release_readiness.sh scripts/run_mvp_system_e2e.sh` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` with production API, social-login env, provider/store/reviewer/symbol/rollback evidence refs, privacy URL, support URL, Sentry, and Android signing vars - passed.
- Same fixture `scripts/check_release_readiness.sh` in strict mode - failed as expected on native iOS social-login blockers.

Required corrections:
- None remaining for local TC-COM-021/022 evidence gate setup.

Residual risk:
- TC-COM-015 external copy/store evidence, TC-COM-019 external provider evidence, TC-COM-021 external store evidence, and strict TC-COM-012/022 native/release evidence remain blockers.
- PM must not treat this as release approval until those external/native blockers are supplied and strict gate passes.

## 2026-05-29 P0-COM-MANUAL-EVIDENCE-PLAN-001 Independent Review

Result: pass for manual external evidence plan completeness and traceability. Not a commercial release pass.

Checked step:
- Reviewed `tests/commercial/manual_external_evidence_checklist.md` against remaining blockers TC-COM-012, TC-COM-015, TC-COM-019, TC-COM-021 and TC-COM-022.
- Reviewed release runbook/checklist, test cases, traceability and aggregate release gate integration.
- Confirmed the change adds execution instructions and result fields without marking external evidence as passed.

Findings:
- No blocker. Each remaining external/native TC now has manual steps, preconditions, expected results, evidence requirements, actual result fields and reviewer fields.
- No blocker. Provider coverage includes Apple sandbox and Google Play internal purchase, restore, refund/revoke, expiry, grace-period and account-switch scenarios.
- No blocker. Store coverage includes App Store / Play metadata, subscription products and terms, privacy/Data safety, privacy/support URLs and reviewer account evidence.
- No blocker. Native/release coverage includes WeChat, Apple Sign In, real login smoke, release secrets, signing, symbols, rollback and strict release readiness.
- No blocker. `scripts/check_release_readiness.sh` now runs `scripts/check_manual_external_evidence_plan.py` before external evidence gates, so the manual plan structure is release-gated.

Validation:
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/check_commercial_copy_contract.py` - passed with expected external copy blockers reported.
- `python3 scripts/check_provider_sandbox_evidence.py` - passed with expected provider evidence blockers reported.
- `python3 scripts/check_store_submission_evidence.py` - passed with expected store evidence blockers reported.
- `python3 -m py_compile scripts/check_manual_external_evidence_plan.py scripts/check_provider_sandbox_evidence.py scripts/check_store_submission_evidence.py scripts/check_commercial_copy_contract.py` - passed.
- `bash -n scripts/check_release_readiness.sh` - passed.
- Fixture `scripts/check_release_readiness.sh --env-only` - passed.
- Same fixture `scripts/check_release_readiness.sh` strict mode - failed as expected on native iOS social-login blockers.

Required corrections:
- None for the manual evidence planning step.

Residual risk:
- The project is still not commercial release ready.
- TC-COM-012, TC-COM-015, TC-COM-019, TC-COM-021 and TC-COM-022 remain blockers until the manual checklist is actually executed, evidence refs are supplied, strict release gate passes and independent review approves the results.
## 2026-06-01 P0-AI-ARCH-001 Independent Review

Result: pass for architecture/API/security contract gate. Not a production AI release pass.

Checked step:
- Reviewed `P0-AI-ARCH-001` changes for `commercial-ai-provider-hardening`.
- Confirmed scope is limited to architecture, API, security, domain, traceability, ADR and generated API boundary updates.
- Confirmed no backend implementation files, Flutter feature files or tests were changed in this step.

Findings:
- No blocker. OpenAPI now contains implementation-level `Media` and `AI Ops` paths for media upload/signing, provider evidence, cost metrics and AI retention jobs.
- No blocker. Domain and relationship docs define `MediaAsset`, `TtsCacheEntry`, `ProviderSandboxRun`, `ProviderInvocationMetric`, `RetentionPolicy` and `AiRetentionJob` with ownership, lifecycle and test impact.
- No blocker. Security contract keeps provider secrets, raw audio, full transcripts, full signed URLs and raw provider payloads out of API responses and logs.
- No blocker. `commercial-ai-provider-hardening` traceability rows are marked contract-ready while preserving implementation/live-evidence gaps as open.

Validation:
- `npm run check:api-contract` - passed outside sandbox after `uv` panicked under sandbox macOS system configuration access.
- `npm run lint:openapi` - passed.
- `npm run check:openapi-contract` - passed outside sandbox.
- `npm run check:dart-client-drift` - passed outside sandbox.

Required corrections:
- None for `P0-AI-ARCH-001`.

Residual risk:
- Backend implementation, persistent cache implementation, real DashScope evidence, cost dashboard implementation, retention execution proof and final reports are still pending in `P0-AI-BE-001` through `P0-AI-REPORT-001`.

## 2026-06-01 P0-AI-BE-001 Independent Review

Result: pass for local backend media upload/signing and ASR ref resolution. Not a production object-storage/live-provider release pass.

Checked step:
- Reviewed backend implementation for `COM-SI-013` / `FR-COM-AI-001` / `AC-COM-AI-001`.
- Reviewed migration, media upload API, trusted media ref resolution, DashScope policy rejection, and tests.
- Confirmed the step did not mark persistent TTS cache, real DashScope evidence, cost dashboard or retention execution as complete.

Findings:
- No blocker. `ai_media_assets` stores backend-owned media metadata, upload URL, signed provider ref, audit ref, duration, byte size, checksum, status and expiry.
- No blocker. `POST /media/audio/uploads` creates idempotent pending media assets and rejects unsupported MIME, oversize or over-duration metadata.
- No blocker. `POST /media/audio/uploads/{media_id}/complete` validates ownership, expiry and checksum before marking a media ref `validated`.
- No blocker. Production DashScope ASR now rejects local paths, unsigned URLs and unvalidated `media://audio/{media_id}` refs before provider calls.
- No blocker. Traceability correctly marks only `COM-AI-GAP-001` local backend work closed; external object storage lifecycle evidence remains pending.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,ProductionAsrMediaRefTest,DashScopeProviderGatewayIntegrationTest test` - passed.
- `git diff --check` - passed.

Required corrections:
- Updated historical P0.1 test report wording so production DashScope local-path behavior is described as provider-before-call rejection rather than typed no-result.

Residual risk:
- Real object storage bucket/KMS/CDN evidence is not supplied yet.
- Flutter is not wired to the upload flow in this step.
- Persistent TTS cache, DashScope live evidence, cost dashboard and retention/deletion proof remain pending in later work packages.

## 2026-06-01 P0-AI-BE-002 Independent Review

Result: pass for local persistent TTS cache metadata, expiry refresh and delete-hook support. Not a CDN/object-storage distribution release pass.

Checked step:
- Reviewed backend implementation for `COM-SI-014` / `FR-COM-AI-002` / `AC-COM-AI-002`.
- Reviewed persistent cache entity, repository, service, migration, `/ai/tts` response metadata and DashScope gateway integration.
- Confirmed the step did not mark real DashScope sandbox evidence, cost dashboard or retention execution proof as complete.

Findings:
- No blocker. `ai_tts_cache_entries` persists cache key, normalized text hash, model, voice, language, audio ref, status, hit count, expiry and deletion fields.
- No blocker. DashScope TTS checks `AiTtsCacheService` before provider calls and returns `cache_status`, `media_id` and `cache_expires_at` through the existing `/ai/tts` response.
- No blocker. Expired entries are not reused; provider refresh updates the existing cache key instead of creating duplicate cache rows.
- No blocker. `markExpiredDeleted` provides the local delete hook needed by later retention jobs.
- No blocker. Traceability correctly marks only `COM-AI-GAP-002` local backend metadata work closed; CDN/object-storage distribution evidence remains pending.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PersistentTtsCacheTest,DashScopeProviderGatewayIntegrationTest,DashScopeProviderGatewayTest test` - passed.
- `git diff --check` - passed.

Required corrections:
- Kept a dev-only local fallback cache for non-Spring unit construction while production Spring wiring uses persistent `AiTtsCacheService`.

Residual risk:
- CDN/object storage distribution proof is not supplied yet.
- Retention/account deletion execution proof is still pending in `P0-AI-SEC-001`.
- Cost dashboard and live DashScope evidence remain pending.

## 2026-06-01 P0-AI-QA-001 Independent Review

Result: pass for DashScope sandbox evidence gate completeness. Not a real DashScope provider execution pass.

Checked step:
- Reviewed `COM-SI-015` / `FR-COM-AI-003` / `AC-COM-AI-003` / `TC-COM-AI-004`.
- Reviewed `tests/commercial/ai_provider_sandbox_matrix.md`, `tests/commercial/manual_external_evidence_checklist.md`, `scripts/check_ai_provider_sandbox_evidence.py`, `scripts/check_manual_external_evidence_plan.py` and `scripts/check_release_readiness.sh`.
- Confirmed the change does not mark fake transport or missing external evidence as a provider pass.

Findings:
- No blocker. The matrix now covers Qwen valid/fallback, Paraformer valid/reject, TTS generate/cache and provider-error scenarios with latency, error code, cost estimate, format compatibility, fallback and reviewer evidence.
- No blocker. The new script passes in non-strict mode while preserving `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` as a strict release blocker.
- No blocker. Manual evidence planning and aggregate release readiness now include the AI provider evidence gate.
- No blocker. Traceability correctly keeps `COM-AI-GAP-003` open for real controlled live execution evidence.

Validation:
- `python3 scripts/check_ai_provider_sandbox_evidence.py` - passed with expected DashScope evidence blocker reported.
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` - failed as expected until `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` is supplied.

Required corrections:
- None for `P0-AI-QA-001`.

Residual risk:
- Real DashScope LLM/ASR/TTS sandbox or controlled live calls have not been executed in this step.
- Provider latency, error code, cost and audio format compatibility evidence remains an external release blocker.

## 2026-06-01 P0-AI-OPS-001 Independent Review

Result: pass for local AI cost dashboard, budget warning and provider anomaly implementation. Not a production PM/Ops release evidence pass.

Checked step:
- Reviewed `COM-SI-016` / `FR-COM-AI-004` / `AC-COM-AI-004` / `TC-COM-AI-005`.
- Reviewed metric entity/repository/migration, cost aggregation service, `/admin/ai/cost-metrics` controller, provider call metric recording, policy rejection metric recording and release readiness evidence var.
- Confirmed responses use user hash and aggregate cost fields only, not raw text, raw audio, full signed URLs or provider secrets.

Findings:
- No blocker. `ai_provider_invocation_metrics` persists provider/model/capability/status/cache hit/token/audio/cost/margin fields needed for PM/Ops aggregation.
- No blocker. `/admin/ai/cost-metrics` is under `/admin/**` and requires `ROLE_OPS`; normal user tokens are forbidden.
- No blocker. Dashboard status escalates for budget warning, budget exceeded and provider anomaly conditions.
- No blocker. TTS result metadata feeds cache hit cost metrics, and provider/policy failures can appear as `provider_unavailable` or `rejected` without exposing raw payloads.
- No blocker. Strict release readiness now requires `AI_COST_DASHBOARD_EVIDENCE_REF`, so local tests cannot be mistaken for production PM/Ops evidence.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest,DashScopeProviderGatewayIntegrationTest,CommercialFoundationControllerTest test` - passed.
- `git diff --check` - passed in the follow-up validation for this step.

Required corrections:
- Changed dashboard aggregation period to daily `YYYY-MM-DD` to match the OpenAPI example and `daily_user` budget bucket.

Residual risk:
- Production budget thresholds and alert destinations are still configuration/ops evidence, not proven by local tests.
- `AI_COST_DASHBOARD_EVIDENCE_REF` remains required before paid AI release.

## 2026-06-01 P0-AI-SEC-001 Independent Review

Result: pass for local AI retention/deletion execution proof. Not a production object-store lifecycle or privacy-policy approval pass.

Checked step:
- Reviewed `COM-SI-017` / `FR-COM-AI-005` / `AC-COM-AI-005` / `TC-COM-AI-006` / `TC-COM-AI-007`.
- Reviewed retention job entity/repository/migration, OPS retention endpoints, expired media/cache deletion, TTS cache owner hash, account deletion hook and release readiness evidence refs.
- Confirmed AI retention responses expose only counts and redacted evidence refs, not raw audio, full transcript, full signed URLs, provider payloads or provider secrets.

Findings:
- No blocker. `ai_retention_jobs` records scope, status, deletion/redaction counts, evidence ref, timestamps and idempotency key.
- No blocker. `POST /admin/ai/retention-jobs` and `GET /admin/ai/retention-jobs/{job_id}` are protected by the existing `/admin/**` OPS role gate.
- No blocker. Expired media and TTS cache entries are marked `deleted` and produce retention evidence counts.
- No blocker. Account deletion invokes AI retention cleanup before general user data purge, marking media/cache deleted and deleting provider metrics for the user hash.
- No blocker. Strict release readiness now requires `AI_MEDIA_STORAGE_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF`, so local retention tests cannot be treated as production privacy evidence.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,AiCostDashboardTest,AccountDeletionLearningDataTest test` - passed.
- `git diff --check` - passed in follow-up validation for this step.

Required corrections:
- None for `P0-AI-SEC-001`.

Residual risk:
- Object-store provider lifecycle deletion is represented by local metadata deletion only; real bucket/CDN deletion proof remains external.
- TTS cache ownership is first-owner based for local cleanup; shared-cache multi-owner deletion policy should be reviewed before broad multi-tenant production use.
- Approved privacy/retention policy evidence remains required before paid AI release.

## 2026-06-01 P0-AI-REPORT-001 Independent Review

Result: pass for implementation/test/quality/release evidence summary. Not a paid AI release approval.

Checked step:
- Reviewed `docs/reports/implementation_report.md`, `docs/reports/test_report.md`, `docs/reports/quality_report.md`, `docs/product/increments/commercial-ai-provider-hardening/traceability.md` and release gate updates.
- Confirmed each work package from `P0-AI-ARCH-001` through `P0-AI-SEC-001` has an independent quality entry and validation evidence.
- Confirmed final report does not claim real DashScope, object-store lifecycle, PM/Ops production dashboard evidence or approved retention policy evidence has passed.

Findings:
- No blocker. Implementation report maps the work to COM-SI-013 through COM-SI-017, FR-COM-AI-001 through FR-COM-AI-005 and TC-COM-AI-001 through TC-COM-AI-007.
- No blocker. Test report records backend, script, release syntax and OpenAPI validation commands with actual outcomes.
- No blocker. Traceability marks local backend gaps closed where implemented and preserves external evidence refs as release blockers.
- No blocker. Strict release readiness requires `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`, `AI_MEDIA_STORAGE_EVIDENCE_REF`, `AI_COST_DASHBOARD_EVIDENCE_REF` and `AI_RETENTION_POLICY_EVIDENCE_REF`.

Validation:
- Combined backend target test command - passed.
- `python3 scripts/check_ai_provider_sandbox_evidence.py` - passed with expected missing DashScope evidence blocker.
- `python3 scripts/check_manual_external_evidence_plan.py` - passed.
- Script compile, `bash -n scripts/check_release_readiness.sh`, `git diff --check` and `npm run lint:openapi` - passed.
- `npm run check:api-contract` - passed outside sandbox after the sandbox `uv` panic.

Required corrections:
- None for `P0-AI-REPORT-001`.

Residual risk:
- External evidence refs are still missing; do not declare paid AI voice release ready.

## 2026-06-02 P0-AI DashScope Sandbox Execution Independent Review

Result: historical blocker, superseded by `2026-06-02 P0/P0.1 Blocker Retest Independent Review`. Real provider was contacted in this earlier probe, but that run used an invalid DashScope credential; a later controlled live LLM/TTS/ASR sanity probe passed. This historical section still does not grant release evidence closure.

Checked step:
- Reviewed TC-COM-AI-004 / AC-COM-AI-003.
- Reviewed sanitized probe output for Qwen LLM, DashScope TTS, ASR-valid prerequisite and provider-error handling.
- Confirmed no API key, raw prompt, full audio URL or raw transcript was written to reports.

Findings:
- Historical blocker. Qwen valid scenario returned provider `invalid_api_key` with HTTP 401, so schema-valid LLM evidence was not produced in this earlier run.
- Historical blocker. TTS generation returned `InvalidApiKey` with HTTP 401, so no TTS audio ref, cache evidence or ASR input fixture was produced in this earlier run.
- Historical blocker. ASR-valid was blocked by missing provider-accessible audio URL in this earlier run. Later controlled live sanity produced ASR `SUCCEEDED`, but full matrix evidence is still missing.
- No blocker in reporting. The run preserves `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` as missing and does not claim release readiness.

Validation:
- Sanitized inline DashScope probe - executed; result blocked by provider invalid API key.

Required corrections:
- Superseded credential correction: later controlled live sanity passed with the configured key. Remaining correction is to rerun the full matrix with sanitized fixtures, then set `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` only after independent evidence review.

Residual risk:
- TC-COM-AI-004 remains open.
- Paid AI voice release remains blocked.

## 2026-06-02 P0-AI Object Storage Evidence Independent Review

Result: pass for local media/ref regression; blocker for production object-storage evidence.

Checked step:
- Reviewed TC-COM-AI-001, TC-COM-AI-002 and the retention deletion path touching media assets.
- Checked local environment for object-storage/media storage configuration and found no production object storage evidence vars.

Findings:
- No local blocker. Media upload/ref and ASR guard tests passed after the TTS ownership change.
- No local blocker. Expired media deletion still works through the retention job.
- Release blocker. Real bucket upload/read, CDN/public object serving, KMS/secret configuration, lifecycle expiry and object deletion proof were not executed.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,ProductionAsrMediaRefTest,AiRetentionPolicyTest test` - passed.

Required corrections:
- Configure real object storage and media public/upload base URLs in staging or release CI.
- Execute upload, read, expiry and delete proof with sanitized audio, then set `AI_MEDIA_STORAGE_EVIDENCE_REF`.

Residual risk:
- Object-store lifecycle and CDN/KMS proof remain external release blockers.

## 2026-06-02 P0-AI Cost Dashboard Evidence Independent Review

Result: pass for local cost dashboard and budget/anomaly behavior; blocker for production PM/Ops evidence.

Checked step:
- Reviewed TC-COM-AI-005 / AC-COM-AI-004.
- Revalidated dashboard aggregation, budget warning, provider anomaly and OPS-only access.

Findings:
- No local blocker. Cost metrics remain sanitized and do not expose raw user id or raw text.
- No local blocker. Budget warning and provider anomaly states are visible to OPS.
- Release blocker. Production thresholds, alert destinations, dashboard screenshots/API evidence and PM/Ops approval were not supplied.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest test` - passed.

Required corrections:
- Configure production thresholds and alert channels.
- Capture dashboard/API evidence covering plan, user hash, provider/model/capability/status/cache hit/cost/margin risk, then set `AI_COST_DASHBOARD_EVIDENCE_REF`.

Residual risk:
- Commercial pricing remains release-blocked until production cost evidence is reviewed.

## 2026-06-02 P0-AI Retention And Privacy Evidence Independent Review

Result: pass for local retention/account deletion execution; blocker for approved policy and external deletion evidence.

Checked step:
- Reviewed TC-COM-AI-006 and TC-COM-AI-007.
- Reviewed retention job counts, account deletion cleanup, provider metric redaction and TTS cache owner refs.

Findings:
- No local blocker. Expired media/cache deletion and account deletion regression tests passed.
- No local blocker. Shared TTS cache now records owner refs and does not delete shared cache until the final owner is removed.
- Release blocker. Approved privacy/retention policy version and real object-store deletion evidence were not supplied.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiRetentionPolicyTest,AiAccountDeletionMediaCleanupTest,AccountDeletionLearningDataTest test` - passed.

Required corrections:
- Security/PM must approve the production retention policy.
- Run retention/account deletion against staging object storage and store redacted execution proof in `AI_RETENTION_POLICY_EVIDENCE_REF`.

Residual risk:
- Production policy approval and external deletion proof remain release blockers.

## 2026-06-02 P0-AI TTS Cache Multi-Tenant Policy Independent Review

Result: pass. The prior first-owner local cleanup risk is closed by owner refs and tests.

Checked step:
- Reviewed `AiTtsCacheOwner`, `AiTtsCacheOwnerRepository`, migration `V202606020001__commercial_ai_tts_cache_owners.sql`, `AiRetentionService` and `AiAccountDeletionMediaCleanupTest`.
- Reviewed domain, spec, test case and traceability updates for multi-owner ownership.

Findings:
- No blocker. `ai_tts_cache_owners` records `(cache_id, owner_hash)` with a uniqueness constraint and timestamps.
- No blocker. Account deletion removes only the deleting user's owner ref; cache remains active while another owner exists.
- No blocker. Deleting the final owner marks the cache entry deleted and removes owner refs.
- No blocker. Expired cache deletion also removes owner refs.
- No blocker. Legacy `owner_hash` remains a fallback for old rows, no longer overwrites first ownership on subsequent hits and is cleared when it matches the deleting user.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiAccountDeletionMediaCleanupTest,AiRetentionPolicyTest,PersistentTtsCacheTest,AiCostDashboardTest,FoundationMigrationTest test` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PostgresFoundationMigrationTest test` - passed.

Required corrections:
- None for local implementation.

Residual risk:
- Production privacy policy still must explicitly approve cross-user reuse of identical normalized TTS cache entries before paid AI release.

## 2026-06-05 P02 Followup-C S000 Follow-up Documentation Correction Independent Review

Result: pass for S000 documentation correction. Followup-C remains implementation-gated; S001-S007 are not implemented and are not release-ready.

Checked step:
- Reviewed `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/definition.md`, `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and `traceability.md` after the S000 follow-up correction.
- Checked the prior product/software-leader findings: S005 full completion gate, S001 forecast AI/cost boundary, and TC fixture/assertion entry points.
- Rechecked that S000 documentation completion does not claim S001-S007 code, test, performance, coverage, release or Product Base evidence.

Findings:
- No blocker. S005 no longer permits one- or two-surface evidence to close full S005; Home, Queue and Wiki are all required for P02-SI-006 and Followup-C local completion.
- No blocker. S001 now maps to P02-PG-004 and requires forecast AI explanation to respect entitlement, quota and cost fallback, or document deterministic N/A.
- No blocker. `test_cases.md` now includes slice fixture/assertion entry points for forecast AI fallback, all three surface projections, Queue source-of-truth behavior, stale cache removal and S005 partial-only blocking.
- No blocker. Traceability rows preserve S001-S007 as planned/not started and keep required downstream contract, code, test and report evidence pending.

Validation:
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check -- docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces docs/reports/quality_report.md` - passed.
- Stale S005 completion-gate phrase scan across Followup-C docs and `quality_report.md` - no current completion-gate residue.

Required corrections:
- None for the S000 follow-up documentation correction.

Residual risk:
- S001-S007 implementation remains blocked until each routed slice updates or explicitly marks N/A the relevant domain/API/OpenAPI/UX/AI contracts.
- Followup-C is not release-ready and Product Base merge is not approved.

## 2026-06-09 P0-AI Provider Evidence Endpoint Independent Review

Result: pass for local backend endpoint evidence. Strict external provider evidence remains blocked.

Checked step:
- Reviewed `GET /admin/ai/provider-evidence` backend implementation for `COM-SI-015` / `FR-COM-AI-003` / `AC-COM-AI-003` / `TC-COM-AI-004` / `COM-AI-TR-003`.
- Reviewed `AiProviderSandboxRun`, `AiProviderSandboxRunRepository`, `AiProviderEvidenceService`, `AiOpsController`, migration `V202606080001__commercial_ai_provider_sandbox_runs.sql`, `AiProviderEvidenceControllerTest`, commercial AI `test_cases.md`, commercial AI `traceability.md`, `test_report.md` and `implementation_report.md`.
- Confirmed the implementation uses the existing `/admin/**` OPS bearer security boundary and does not introduce a parallel controller/auth mechanism.

Findings:
- No blocker. `GET /admin/ai/provider-evidence` is implemented through the existing `AiOpsController` and returns only OpenAPI-declared evidence fields.
- No blocker. `status` and `reviewed_status` remain separate contract fields; unknown stored values are conservatively rendered as `blocked` / `pending`.
- No blocker. The response does not expose internal `model`, `fixture_ref` or `error_code` fields and redacts evidence refs containing API-key markers, raw payload markers, full transcript markers or signed URL query material.
- No blocker. `AiProviderEvidenceControllerTest` covers OPS-only auth, empty-list behavior without fabricated approval, approved/pending/blocked evidence, stable sorting by `executed_at DESC, created_at DESC, evidence_id ASC`, and sensitive field non-disclosure.
- No blocker. `commercial-ai-provider-hardening/traceability.md` keeps `COM-AI-GAP-003` open and keeps strict external release evidence tied to `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiProviderEvidenceControllerTest,AiCostDashboardTest,AiRetentionPolicyTest test` - passed.
- `python3 scripts/check_ai_provider_sandbox_evidence.py` - passed with the expected `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` release blocker reported.
- `python3 scripts/check_ai_external_release_evidence.py` - passed with expected DashScope、media storage、cost dashboard and retention evidence blockers reported.
- `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` - failed as expected because `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` is not supplied.
- `npm run check:api-contract` - passed.
- `git diff --check` - passed.

Required corrections:
- None. The independent review initially requested stronger secondary-sort coverage and traceability metadata sync; both were fixed, retested and rechecked.

Residual risk:
- This closes the local backend endpoint implementation gap only.
- `COM-AI-GAP-003` and paid AI voice release remain blocked until `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` points to externally reviewed full DashScope LLM/ASR/TTS evidence and strict external gates pass.

## 2026-06-10 Product Base Profile Avatar XCB-003 Independent Review

Result: pass.

Checked step:
- Reviewed the Product Base profile avatar fix for `FR-010` / `Flow-010` / `AC-011` / `XCB-003`.
- Reviewed API contract, OpenAPI/generated drift, backend profile update validation, Flutter profile sync, test evidence, implementation report and Product Base traceability.
- Ran independent review from two perspectives: test/traceability closure and commercial product/software architecture maintainability.

Findings:
- No blocker. `PATCH /user/me` remains the only current profile update boundary for built-in avatar selection; no `/user/me/avatar` endpoint or audio media upload path was introduced.
- No blocker. `avatar_ref` is constrained to the six built-in avatar asset refs in OpenAPI and backend validation.
- No blocker. Flutter now sends `display_name` and `avatar_ref` through the existing profile patch flow and `ApiClient` blocks hidden `/user/me/avatar` / multipart avatar upload regressions.
- No blocker. Deprecated `AppSession.updateAvatar` delegates to `updateProfile`, so future callers do not bypass the profile patch boundary.
- No blocker. Unsupported legacy avatar URLs normalize to the default built-in avatar ref before display or sync.
- No blocker. `docs/product/base/traceability.md` links FR-010/AC-011 to `TC-PB-FR010-001`, `TC-PB-FR010-002` and `TC-PB-FR010-003`, and each TC links back to the test report evidence.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AuthControllerTest test` - passed.
- `flutter test test/application/session_profile_coordinator_test.dart test/services/app_session_profile_avatar_sync_test.dart test/services/api_client_contract_test.dart` - passed.
- `npm run check:api-contract && npm run check:dart-client-drift` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope full` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --include-worktree --base-ref HEAD` - passed.
- `flutter analyze lib/services/api_client.dart lib/services/app_session.dart test/application/session_profile_coordinator_test.dart test/services/app_session_profile_avatar_sync_test.dart test/services/api_client_contract_test.dart` - passed.
- `git diff --check` - passed.

Required corrections:
- None for XCB-003.

Residual risk:
- `avatar_ref` intentionally uses Flutter asset paths as the current built-in avatar contract. This is acceptable for the current Product Base scope but future remote or user-uploaded avatars must be designed as a separate `media/image` contract.
- The worktree contains unrelated pre-existing changes outside XCB-003; this review does not approve or reject those unrelated changes.

## 2026-06-11 P02 XCB005 Goal Autopilot Fact Boundaries Independent Review

Report ID:
- `P02-XCB005-GOAL-AUTOPILOT-FACT-BOUNDARIES-20260611`

Result:
- Pass. Final independent review found no P0 findings and no remaining P1 after this report status was updated. Prior P1 findings for Flutter `Idempotency-Key`, duplicate-profile migration upgrade, OpenAPI/generated drift, report/checker traceability and final report source-of-truth status are closed.

Checked step:
- Reviewed `P02-FUA-TR-010`, `P02-FUA-TR-011`, `P02-FUC-TR-003`, `P02-FUC-GAP-010`, `TC-P02-FUA-017`, `TC-P02-FUA-018`, `TC-P02-FUA-019` and `TC-P02-FUC-023`.
- Reviewed backend audio-ref validation, goal-create idempotency, Flutter header propagation, migration upgrade safety, export/telemetry redaction and OpenAPI generated drift.

Findings:
- Closed P1. Flutter production `createGoal` now sends `Idempotency-Key` through `GoalAutopilotRequest.headers` and `ApiClient.createGoalAutopilotGoal`.
- Closed P1. `V202606110001` can upgrade legacy duplicate `goal_profiles` rows by pruning to the service-canonical active/latest row before adding `UNIQUE(user_id)`, with `FoundationMigrationTest` coverage.
- Closed P1. OpenAPI generated Dart drift is synchronized to hash `44739a588708eb47e82707680c0ab0dbada178530abe12a4c7525750f8e35cd5`.
- Closed P1. XCB-005 report and traceability checker coverage now include Followup-A rows `P02-FUA-TR-010/011` and Followup-C checkpoint regression `TC-P02-FUC-023`.
- Closed P1. Final quality-report source-of-truth status is now recorded as pass rather than pending.
- Closed P2. OpenAPI now explicitly documents `400` for missing required `Idempotency-Key` binding errors on `POST /goal-autopilot/goals`.
- No duplicate wheel concern identified in the local implementation: trusted audio uses existing Media/AI Gateway validation, idempotency follows the existing replay-table pattern, deletion/export reuse existing data-governance paths, and Flutter uses the existing adapter/ApiClient transport.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=GoalAutopilotControllerTest,GoalAutopilotDataExportRetentionTest,GoalAutopilotTelemetryTest,FoundationMigrationTest test` - passed.
- `flutter test test/features/goal_autopilot/goal_autopilot_adapter_test.dart` - passed.
- `npm run check:api-contract` - passed.
- `python3 scripts/check_p0_2_goal_autopilot_traceability.py` - passed.
- `python3 scripts/check_p0_2_followup_c_traceability.py` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope full` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --include-worktree --base-ref HEAD` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Required corrections:
- None.

Residual risk:
- Migration prune deletes non-canonical duplicate goal chains through existing FK cascade. This is consistent with the single active goal-chain architecture, but production environments that require duplicate-chain audit history must archive before migration.
- Followup-E diagnostic-audio upload feature completion is not claimed by this review.

## 2026-06-11 XCB-006 Data Lifecycle Boundary Hardening Independent Review

Report ID:
- `XCB006-DATA-LIFECYCLE-BOUNDARY-HARDENING-20260611`

Result:
- Pass for local XCB-006 boundary hardening, audit redaction, AI retention evidence and changed-scope static enforcement.

Checked scope:
- Cross-cutting rule: `docs/process/cross_cutting_boundary_registry.md` `XCB-006`.
- Requirements and acceptance: `FR-COM-011`, `FR-COM-012`, `AC-COM-013`, `AC-COM-014`, `TC-COM-024`, `COM-TR-011`, `COM-TR-012`; `FR-COM-AI-005`, `AC-COM-AI-005`, `TC-COM-AI-006`, `COM-AI-TR-005`.
- Architecture and domain: `docs/domain/domain_schema.md` `AuditLog`, `RetentionPolicy`, `AiRetentionJob`; `docs/domain/entity_relationship.md` account deletion/audit and retention relationships; `docs/architecture/backend_db_foundation_contract.md`; `docs/architecture/api_contract.md` `/admin/audit` and `/admin/ai/retention-jobs`.
- Code and tests: `AuditRedaction`, `AuditLog`, `AuditLogService`, `AiRetentionService`, `AdminAuditControllerTest`, `AiRetentionPolicyTest`, `scripts/check_cross_cutting_boundaries.py`, `test/scripts/test_cross_cutting_boundaries.py`.

Findings:
- No blocker. XCB-006 now has an executable changed-scope migration gate for sensitive tables, with tests covering missing coverage, complete coverage, staged/index coverage, explicit exceptions and non-sensitive reference tables.
- No blocker. Audit write-side and read-side redaction now use shared `AuditRedaction`; this closes the previous duplicated-rule drift between `AuditLog` and `AuditLogService`.
- No blocker. Safe aggregate retention counts ending in `_deleted_count` or `_redacted_count` remain visible as lifecycle evidence while raw audio, full transcript, provider payload, tokens, signed URLs and sensitive target refs are redacted.
- No blocker. `AiRetentionService` persists JSON audit evidence rather than Java `Map.toString()` output, so DB evidence and `/admin/audit` API output are both machine-readable and sanitized.
- No blocker. Product traceability rows now point from `TC-COM-024` and `TC-COM-AI-006` to the 2026-06-11 XCB-006 test evidence, and the implementation/test reports point back to the owning requirements and architecture.

Independent agent reviews:
- Static XCB-006 gate review: passed; no duplicate-wheel concern, residual SQL parser limitations noted as non-blocking.
- Audit redaction architecture review: passed; `AuditRedaction` is the single read/write redaction boundary and does not duplicate existing mechanisms.
- Test/traceability review: passed; write-side persistence, legacy read-side sanitization, AI retention DB/API evidence and XCB-006 traceability all covered.
- Target-ref follow-up review: passed; `usage:*`, `ai_retention:*` and `account_deletion:*` are not over-redacted, and sensitive `audio_ref:*` / `transcript_ref:*` target refs are redacted.
- Final architecture/traceability review: passed; only low-risk traceability metadata freshness was found and then corrected in the two affected traceability headers.

Validation:
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminAuditControllerTest,AiRetentionPolicyTest test` - passed.
- `python3 -m unittest test.scripts.test_cross_cutting_boundaries` - passed.
- `python3 -m py_compile scripts/check_cross_cutting_boundaries.py` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --base-ref HEAD --include-worktree` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Residual risk:
- The static SQL detector is regex-based and intentionally scoped to standard migration files; nonstandard SQL generation still requires human architecture/security review.
- This does not approve paid-AI release. External retention policy approval and object-storage lifecycle evidence refs remain separate release gates.

## 2026-06-11 XCB-006 Structured Exception Gate Final Independent Review

Report ID:
- `XCB006-STRUCTURED-EXCEPTION-GATE-20260611`

Result:
- Pass. Final independent agent review found no remaining wide exception path and no duplicate data-governance service.

Checked scope:
- `docs/process/cross_cutting_boundary_registry.md` XCB-006 structured exception rules.
- `scripts/check_cross_cutting_boundaries.py` XCB-006 migration governance checker.
- `test/scripts/test_cross_cutting_boundaries.py` XCB-006 gate tests.
- `docs/reports/implementation_report.md` and `docs/reports/test_report.md` traceability evidence.

Findings:
- No blocker. `planned exception` is no longer an allowed release path, including lines whose rationale mentions retained-redacted evidence.
- No blocker. Only exact lowercase `retained-redacted exception`, `legacy exception` and `not-applicable exception` declarations are accepted.
- No blocker. Required fields, empty duplicate fields, placeholder values, sensitive `safe_fields`, user-subject identifiers and rationale false assignments are rejected.
- No blocker. `legacy exception` rationale must prove `pre_existing` or `migration_compatibility`; `not-applicable exception` must use exact bare fixed fields and an allowed non-user-data rationale.
- No blocker. No parallel `DataGovernanceService` or privacy service was introduced; the solution remains in the existing XCB checker, registry and unit-test path.

Independent agent result:
- Final pass from agent `Mill`: no remaining correction required after the false-assignment rationale blocker was fixed.

Validation:
- `python3 -m unittest test.scripts.test_cross_cutting_boundaries` - passed, 59 tests.
- `python3 -m py_compile scripts/check_cross_cutting_boundaries.py` - passed.
- `python3 scripts/check_cross_cutting_boundaries.py --scope changed --base-ref HEAD --include-worktree` - passed.
- `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminAuditControllerTest,AiRetentionPolicyTest test` - passed.
- `python3 scripts/project_agent_runner.py validate` - passed.
- `git diff --check` - passed.

Residual risk:
- The checker remains intentionally line-oriented for deterministic changed-scope enforcement; long-form exception reasoning can live in owning docs, but the machine gate requires the compact structured line.

## 2026-06-11 Global SWC 架构基线治理审核

报告 ID：
- `GLOBAL-SWC-ARCHITECTURE-BASELINE-GOVERNANCE-20260611`

结果：
- 独立 blocker 修复复查后通过。本审核批准 global SWC architecture baseline、Flow ID reference、increment SWC allocation 和 allocation template usage 的 workflow/source-of-truth governance change。本审核不批准任何 product feature、implementation、Product Base merge、commercial release readiness、backend code、Flutter code、provider evidence 或 release evidence。

检查范围：
- Global SWC architecture baseline：`docs/architecture/software_component_architecture.md`。
- SWC catalog boundary：`docs/architecture/swc_catalog.md`。
- Business flow 和 module-boundary source reference：`docs/architecture/data_flow.md`、`docs/architecture/module_boundary.md`、`docs/architecture/system_overview.md`。
- Process gate：`docs/process/software_component_architecture_governance.md`、`docs/process/workflow.md`、`docs/process/definition_of_done.md`、`docs/process/skill_quality_standard.md`。
- Agent 和 skill routing：`codex/agents/system_architect.md`、`codex/agents/development_orchestrator.md`、`codex/agents/product_manager.md`、`codex/agents/software_architecture_governance_check.md`、`codex/agents/product_object_governance_check.md`、`.agents/skills/document-path-governance/`、`.agents/skills/document-content-contract/`、`.agents/skills/document-traceability-check/`。
- Template：`codex/templates/swc_allocation.template.md`。

发现：
- 无剩余 blocker。`docs/architecture/software_component_architecture.md` 现在拥有完整 SWC topology、稳定 `SWC-FLOW-*` library、canonical SWC-to-SWC sequence、increment delta rule 和 local architecture change baseline。
- 无剩余 blocker。`docs/architecture/swc_catalog.md` 继续作为 stable component inventory，不变成完整 architecture 或 increment allocation artifact。
- 无剩余 blocker。Increment `swc_allocation.md` 现在定义为相对 global SWC baseline 的 delta，并且必须引用适用 `SWC-FLOW-*` ID，或把 local flow 分类为 `one-off`、`proposed-global` 或 `legacy-compatible`。
- 无剩余 blocker。`data_flow.md` 和 `module_boundary.md` 现在声明它们为 SWC baseline 提供 business flow/fact-source rule 和 context boundary，而不是与其竞争。
- 无剩余 blocker。Product Manager、Development Orchestrator、System Architect、Software Architecture Governance Check、Product Object Governance Check 和 document governance skill 现在对 baseline/catalog/allocation 拆分保持一致。
- 初始 template blocker 已修复：`codex/templates/swc_allocation.template.md` 不再暗示 AI/provider 可以拥有最终持久化事实。Candidate output 保留在 AI/provider；accepted persistent fact 由 deterministic rule 接受后归 backend/domain SWC 拥有。
- Template governance 已澄清：修改 `codex/templates/swc_allocation.template.md` 属于 workflow/source-of-truth governance change，需要 Product Object Governance Check。

独立 agent 结果：
- Agent `Aristotle` 初次 global-baseline review：pass，并提出 template、future CI gate、catalog precision 和 acceptance status 的非阻塞建议。
- Agent `Aristotle` template follow-up：因 AI/provider final-fact ownership ambiguity 阻塞。
- Agent `Aristotle` final template follow-up：文字修正和 template-change governance note 补齐后通过。

验证：
- `python3 scripts/project_agent_runner.py validate`：passed。
- `python3 scripts/validate_agent_skills.py`：passed。
- `git diff --check`：passed。

残余风险：
- Historical increment 仍非全部已有 `swc_allocation.md`；这仍是前向迁移风险，必须在下次触碰 slice、Product Base merge review 或 release-readiness review 时处理。
- `SWC-FLOW-*` reference 和 SWC catalog entry 目前通过 document governance 与 independent review 维护；后续 automation 可以减少与 OpenAPI、Domain Schema 和 code path 的漂移。
- `N/A - no SWC impact` decision 依赖独立 reviewer 纪律；过度使用会削弱 gate。

## 2026-06-12 Scenario Practice Runtime Migration 架构治理审核

报告 ID：
- `SCENARIO-PRACTICE-RUNTIME-MIGRATION-ARCH-GOV-20260612`

结果：
- 独立 blocker 修复复查后通过。本审核批准未来 frontend-only `scenario-practice-runtime-migration` implementation 的 architecture plan 和 SWC allocation readiness。本审核不批准 business-code change、OpenAPI/backend/DB/provider change、Product Base merge、commercial release readiness 或 production rollout。

检查范围：
- Increment docs：`docs/product/increments/scenario-practice-runtime-migration/definition.md`、`requirements.md`、`spec.md`、`acceptance.md`、`test_cases.md`、`traceability.md`、`swc_allocation.md`。
- Global SWC baseline：`docs/architecture/software_component_architecture.md`、`docs/architecture/swc_catalog.md`、`docs/architecture/module_boundary.md`、`docs/architecture/data_flow.md`。
- Process 和 checker contract：`docs/process/software_component_architecture_governance.md`、`codex/agents/software_architecture_governance_check.md`。
- Code evidence 只读检查：`lib/features/interview/`、`lib/features/scenario/`、`lib/application/scene/`、`lib/services/audio_service.dart`、`lib/services/voice_chat_service.dart`、`lib/services/voice_turn_orchestrator.dart`、`lib/services/api_client.dart`、`lib/services/app_session.dart`、`lib/application/session/session_stats_coordinator.dart`、`lib/services/stats_service.dart`、`lib/models/learning_stats_model.dart`。

发现：
- 无剩余 blocker。`FE-SCENARIO-PRACTICE`、`FE-PRACTICE-RUNTIME`、`FE-LEGACY-SCENARIO-SANDBOX` 和 global `SWC-FLOW-SCENARIO-PRACTICE-RUNTIME` 已存在于 global SWC baseline。
- 无剩余 blocker。只要 implementation 不改变 OpenAPI、backend、DB、provider、media trust、usage、entitlement 或 server-owned fact，该 migration 正确分类为 frontend-only。
- 无剩余 blocker。`swc_allocation.md` 现在把 `MIG-FR-001` 到 `MIG-FR-011` 映射到具体 SWC、OpenAPI operation ID 或明确 frontend-only `N/A`、Domain entity、DB table group、provider boundary 和 TC ID。
- 无剩余 blocker。Core flow 覆盖 start/resume、content load、voice/ASR、text turn、AI coach、TTS、hint、feedback/review、wiki/memory/queue、practice history 和 legacy sandbox，并包含 failure handling、auth、idempotency/retry、rollback/compensation、audit/logging/metrics、privacy 和 response-to-UI mapping。
- 无剩余 blocker。`lib/services/voice_turn_orchestrator.dart` 现在明确归类为 `FE-PRACTICE-RUNTIME` migration 的 existing voice-turn mechanics，并被 scenario-practice CI gate 覆盖。
- 无剩余 blocker。Practice history/stats call 已明确分类为 legacy non-OpenAPI client path：`GET /user/stats`、`POST /user/stats/session`、`POST /user/stats/session/feedback` 和 `POST /user/stats/session-group/delete`。它们只能在 `AppSession` / `SessionStatsCoordinator` / `StatsService` adapter 后使用，不是稳定 cross-end contract。
- 无剩余 blocker。Reuse 和 forbidden boundary 阻止第三套 `scenario_practice` runtime、duplicate voice/TTS/API/cache/history store、Flutter direct provider call、client-generated trusted media ref、local final mastery/evidence 和 Training source-of-truth duplication。
- 无剩余 blocker。SWC allocation CI gate 现在要求 `Existing Implementation Baseline`、`Delta From Existing Baseline`、具体 FE/BE SWC ID 或明确 `N/A - <reason>`、brownfield/refactor inheritance evidence、changed-path coverage 三个允许字段、scenario-practice Flow/SWC reuse，以及结构化 `N/A - no SWC impact` exception。

独立 agent 结果：
- System Architect Agent `Epicurus`：产出只读 architecture review，并确认 frontend-only classification 及对应 boundary。
- Software Architecture Governance Check Agent `Peirce`：首次审核因 generic API/backend placeholder 和 stats/OpenAPI source-of-truth ambiguity 阻塞。
- Software Architecture Governance Check Agent `Singer`：blocker 修复后二次审核通过。
- Independent SWC allocation gate reviewer `Hypatia`：首次 follow-up 因 generic SWC allocation、过宽 path coverage、不完整 scenario-practice trigger path 和宽松 no-impact exception 阻塞；补齐 strict gate check 和 `voice_turn_orchestrator.dart` coverage 后最终通过。

验证：
- `python3 scripts/check_swc_allocation.py --scope changed --include-worktree`：passed。
- `python3 scripts/check_swc_allocation.py --scope all`：passed。
- `python3 scripts/project_agent_runner.py validate`：passed。
- `python3 scripts/validate_agent_skills.py`：passed。
- 针对已触碰 architecture/increment docs 的 `git diff --check`：passed。
- 未运行 Flutter/backend test，因为这是 architecture-only documentation increment，没有 business-code change。

残余风险：
- `FE-PRACTICE-RUNTIME` 在通过 `test/application/practice_runtime/*`、import-boundary guard 和 history adapter parity test 实现前仍是 proposed 状态。
- 如果 implementation 改变 OpenAPI、backend、DB、provider、media trust、usage、entitlement 或 server-owned fact，该 frontend-only migration 必须重新分类为 cross-layer increment。
- Legacy `/user/stats*` path 应通过单独 API Contract / OpenAPI increment 稳定后，才能视为 durable cross-end contract。
- Changed-mode CI 只检查当前 change 中的文件；historical increment 仍需要 scheduled `--scope all` audit，或在被触碰时进行明确 review。
- Scenario-practice trigger file 作为 gate whitelist 维护；未来新增 voice/session/stats implementation file 时，必须同步更新 script、SWC catalog 和 owning allocation。
