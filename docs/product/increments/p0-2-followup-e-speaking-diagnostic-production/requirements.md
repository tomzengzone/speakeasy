# P0.2 Followup-E Requirements：生产级音频优先口语诊断

## 状态
Phase 1 requirements passed / Phase 2 contracts passed after correction / Phase 3 AC-TC-traceability passed / implementation planning only - 本文件定义 Followup-E 的可测试需求；`spec.md` 已生成并通过 Phase 1 独立审核，domain/API/AI/UX/data contracts 已在独立复核 block 后完成修正并通过复核，acceptance/test_cases/traceability 已通过独立审核。当前 Followup-E 仅作为规划/合同证据；backend、Flutter、OpenAPI/generated client、native mic/audio bytes upload、AI runtime diagnostic result、retention/export/account deletion、release/Product Base/paid AI evidence 均未在本 docs-only 状态中完成或通过。不得将本文件解释为 implementation passed、release-ready、Product Base merge approved 或 paid AI external evidence passed。

## Product Object
- Classification: `feature-increment`
- Increment: `p0-2-followup-e-speaking-diagnostic-production`
- Change request: `CR-20260607-001`
- Active stage: `docs/product/stages/p0-2-training-memory.md`
- Primary Capability ID：`CAP-LEVEL`
- Primary Sub-capability ID：`CAP-LEVEL-02`
- Affected Capability IDs：`CAP-COACH`、`CAP-ACC`、`CAP-COM`、`CAP-PLAN`
- Affected Sub-capability IDs：`CAP-LEVEL-04`、`CAP-LEVEL-05`、`CAP-COACH-03`、`CAP-COACH-05`、`CAP-ACC-03`、`CAP-ACC-04`、`CAP-COM-03`、`CAP-COM-05`、`CAP-PLAN-01`、`CAP-PLAN-06`、`CAP-PLAN-07`

## 上游来源
- `docs/product/stages/p0-2-training-memory.md`
- `docs/process/change_request.md#cr-20260607-001-p02-sheng-chan-ji-yin-pin-you-xian-kou-yu-zhen-duan`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/definition.md`
- `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/requirements.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/requirements.md`
- P02-PG-001 GoalAchievementPolicy
- P02-PG-002 SupportedGoalMatrix
- P02-PG-003 AutopilotControlPolicy
- P02-PG-004 CommercialEntitlementAndCostPolicy
- P02-PG-005 DataGovernancePolicy

## Scope Decision
Followup-E is a production diagnostic hardening increment after Followup-A. It does not reopen Followup-A's local completion; it adds a new implementation-ready path for audio-first Speaking Check. The increment must preserve Followup-A's no-fake-audio boundary, Followup-D's runtime/cost/data governance boundaries, and the P0.2 claim guard against official score equivalence or guaranteed outcomes.

## Stage Scope And WP Coverage
| Stage Scope ID | Policy Gate | WP ID | Requirement ID | Coverage status |
| --- | --- | --- | --- | --- |
| P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUE-WP-000 | P02-FUE-FR-000 | Covered for document chain |
| P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-WP-001 | P02-FUE-FR-001 | Covered |
| P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-WP-001, P02-FUE-WP-006 | P02-FUE-FR-002 | Covered |
| P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-WP-001, P02-FUE-WP-006 | P02-FUE-FR-003 | Covered |
| P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUE-WP-002 | P02-FUE-FR-004 | Covered |
| P02-SI-008, P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUE-WP-003 | P02-FUE-FR-005 | Covered |
| P02-SI-008 | P02-PG-001, P02-PG-004, P02-PG-005 | P02-FUE-WP-004 | P02-FUE-FR-006 | Covered |
| P02-SI-008, P02-SI-009, P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-002 | P02-FUE-WP-004 | P02-FUE-FR-007 | Covered |
| P02-SI-008 | P02-PG-005 | P02-FUE-WP-005 | P02-FUE-FR-008 | Covered |
| P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUE-WP-007 | P02-FUE-FR-009 | Covered |
| P02-SI-007, P02-SI-008 | P02-PG-001..005 | P02-FUE-WP-008, P02-FUE-WP-009 | P02-FUE-FR-010 | Covered |

## 用户目标
学习者能够在设定目标后完成一个短、可信、可跳过、可补做的口语诊断。系统必须优先听到真实口语样本并据此生成产品内诊断和第一天训练重点；当学习者无法或不愿录音时，系统仍允许文本兜底启动，但必须明确诊断低置信、缺少音频维度，并建议稍后补做 Speaking Check。

## 用户路径
1. 用户在 Goal Autopilot 中选择 `Set a goal` 并完成 GoalProfile 表单。
2. 系统进入 Speaking Check，而不是要求用户只填写三段文本。
3. 系统在请求麦克风前说明录音用途、分析维度、保存/删除边界和可跳过路径。
4. 用户完成三类样本：朗读校准句、跟读/复述短句、目标场景自由回答。每类样本支持录音、播放、重录、跳过。
5. 若用户拒绝麦克风、环境嘈杂、设备不可用、网络/provider/配额/成本失败或出于隐私选择跳过，系统进入文本兜底并标记 `diagnostic_mode=text_only` 或 `audio_partial`。
6. 后端完成可信上传和质量门禁后生成 `audio_ref`，ASR transcript 标记为 `audio_asr`，文本输入标记为 `user_text`。
7. 诊断结果必须展示样本数量、置信度、质量问题、主要弱项和今天先练什么；不得只展示分数。
8. 低置信或文本-only 结果必须限制 GoalBackplan、ProgressForecast 和 checkpoint 初始信心，直到用户补做音频诊断或后续 checkpoint 校准。
9. 用户可以删除录音和相关诊断记录；删除后 UI 不得继续展示已删除音频的诊断事实为当前高置信证据。
10. Followup-E 完成前，所有需求必须映射到 AC、TC、合同证据、代码证据、测试证据和独立审核结论。

## Functional Requirements

### P02-FUE-FR-000 Document Chain And Gate
- Followup-E 必须在 requirements、spec、acceptance、test_cases 和 traceability 完整生成并通过独立审核前阻止代码实现。
- 每个阶段的独立审核必须检查是否误关闭 release/Product Base blockers，是否把文本兜底伪装成音频诊断，是否允许 Flutter 伪造 `audio_ref`。
- 阶段 0-3 只允许文档和合同工作；backend、Flutter、OpenAPI/generated client 实现必须等待 AC-to-TC gate 通过。

### P02-FUE-FR-001 Audio-First Speaking Check Entry
- 系统必须在有效 GoalProfile 输入后提供 2-3 分钟 Speaking Check 作为默认诊断路径。
- Speaking Check 必须说明这用于产品内学习计划，不是官方 IELTS/TOEFL/CEFR 认证或保证达标预测。
- 用户必须能选择稍后录音或直接文本兜底，且不会因此被阻断目标创建。

### P02-FUE-FR-002 Diagnostic Sample Task Set
- Speaking Check 必须支持三类样本：read-aloud calibration、listen-repeat/short retell、goal-context free answer。
- 每类样本必须有最小时长、最大时长、题目/提示来源、样本类型和顺序。
- 用户跳过任一音频样本时，诊断必须标记为 `audio_partial` 或更低置信，不得显示完整口语诊断完成。

### P02-FUE-FR-003 Recording Interaction And Fallback UX
- 每个录音样本必须支持开始、停止、播放、重录、取消和跳过。
- 麦克风权限只能在用户明确进入录音动作后请求，不得在 GoalProfile 表单加载时请求。
- 麦克风拒绝、设备不可用、嘈杂环境或用户隐私担忧时，系统必须提供文本兜底和稍后补做路径。

### P02-FUE-FR-004 Trusted Audio Transport And `audio_ref`
- Flutter 不得生成、拼接或伪造 `audio_ref`。
- `audio_ref` 必须由后端在上传完成、用户归属校验、格式/大小/安全校验和基础质量校验通过后生成。
- 后端必须拒绝本地文件路径、未签名 URL、过期 ref、跨用户 ref、重复提交冲突和不支持的音频格式。
- 上传和完成提交必须有幂等规则，避免网络重试造成重复诊断事实。

### P02-FUE-FR-005 Audio Quality Gate And Diagnostic Mode
- 后端必须对音频样本输出质量门禁状态：`accepted`、`too_short`、`silent`、`noisy`、`clipped`、`unsupported_format`、`provider_unavailable` 或 `policy_blocked`。
- 质量不达标不得生成高置信诊断；系统必须要求重录、标记低置信或转入文本兜底。
- 诊断必须明确 `diagnostic_mode=audio_full|audio_partial|text_only` 和 `confidence_band=high|medium|low`。
- `text_only` 不得包含 pronunciation、intonation、speech-rate、pause timing 或 acoustic fluency 结论。

### P02-FUE-FR-006 ASR, Scoring And AI Candidate Boundary
- ASR transcript 必须标记 `transcript_source=audio_asr`，用户输入文本必须标记 `transcript_source=user_text`。
- ASR、pronunciation/scoring provider 或 LLM 只能产生候选事实；最终 DiagnosticAssessment 由后端 deterministic validation 接受或降级。
- 无效 JSON、schema mismatch、provider timeout、quota/cost block 或 forbidden claim 必须触发 deterministic fallback。
- AI/provider 输出不得直接写 GoalProfile、GoalBackplan、ProgressForecast、OutcomeCheckpoint、entitlement、quota、billing、release 或 Product Base 状态。

### P02-FUE-FR-007 Accepted Diagnostic Result And Training Handoff
- 诊断结果必须包含样本数、诊断模式、置信度、质量问题、主要弱项、禁止声明 guard 和下一步训练重点。
- 结果必须转化为第一天训练建议或 backplan 输入，而不是停留在分数展示。
- 低置信、partial 或 text-only 诊断必须让 GoalBackplan、Forecast 和 Checkpoint 初始状态保守降级，并显示补做音频诊断的恢复路径。
- 诊断不能声明官方考试等价分、保证达标、已完成目标或精确达标日期。

### P02-FUE-FR-008 Privacy, Retention, Export And Deletion
- 录音前必须显示产品内用途、敏感数据边界、第三方 provider 处理说明、保留期和删除方式。
- 用户必须能删除录音及相关诊断记录；删除后导出和 UI 不得继续暴露原始音频、完整 transcript 或 provider payload。
- 数据导出只能包含安全/脱敏字段、诊断模式、保留状态、质量状态和 source refs；不得包含 raw audio、provider secret、raw provider payload 或未脱敏敏感诊断文本。
- 原始音频默认短期保留，长期只保留必要诊断事实和训练证据；具体保留期在 data contract 阶段定义。

### P02-FUE-FR-009 Entitlement, Cost, Quota And Provider Downgrade
- 高成本 ASR、pronunciation/scoring、LLM explanation 或多样本分析必须服从后端 entitlement、usage reservation、quota 和 cost policy。
- 免费/受限用户可获得低成本或 text fallback 诊断，但不得看到已完成全量音频诊断或无限 AI 能力。
- Provider 不可用、超时、成本预算触发或额度耗尽时，系统必须降级为可恢复状态，不得阻断 GoalProfile 创建或生成伪成功诊断。

### P02-FUE-FR-010 Test, Traceability, Review And Release Boundary
- 每个 Followup-E AC 必须映射至少一个稳定 TC ID 或明确例外，未完成 AC-to-TC gate 前不得进入实现。
- 任何 backend/API/domain/AI/UX 变更都必须有对应合同更新和测试计划。
- 实现阶段必须满足 P0.2 changed-code coverage gate，并跑 API contract、Dart drift、traceability、Flutter/backend/AI eval 相关测试。
- 阶段 0-3 和后续实现均不得把本地文档或 deterministic provider 证据解释为 release-ready、paid AI external evidence passed 或 Product Base merge approved。

## 非目标
- 不重开 Followup-A FR-001..009 的本地通过状态。
- 不要求录音作为开始学习的强制门槛。
- 不实现官方考试认证、正式 CEFR 评定或保证达标预测。
- 不实现人工评分、教练人工复核或 premium human review。
- 不新增官方场景库、任意场景生成、A1-C2 内容体系或完整评分产品化。
- 不在阶段 1 实现 backend、Flutter、OpenAPI/generated client、AI provider 或 release 配置。

## Requirement Independent Review
Result: pass for Phase 1 independent review. The checker found requirements fully carry the approved audio-first Speaking Check direction, preserve Followup-A local completion/no-fake-audio boundaries, map P02-PG-001..005, and are sufficient input for Phase 2 contracts. This pass does not approve Phase 2 contracts, Phase 3 AC/TC/traceability, implementation, release readiness or Product Base merge.
