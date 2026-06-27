# Paid AI External Release Evidence Checklist：商业 AI Provider 真实开放证据

## 状态
Strategy ready / external execution pending。本文定义 paid AI voice 对真实付费用户开放前必须完成的外部证据包、执行步骤、脱敏边界和独立审查要求；不声明真实外部证据已经通过。

## 适用范围
| Evidence scope | Stage Scope | AC | TC | Traceability row | Evidence ref | Current status |
| --- | --- | --- | --- | --- | --- | --- |
| DashScope LLM/ASR/TTS provider matrix | COM-SI-015 | AC-COM-AI-003 | TC-COM-AI-004 | COM-AI-TR-003 | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` | external-pending |
| Object storage and signed media ref lifecycle | COM-SI-013, COM-SI-017 | AC-COM-AI-001, AC-COM-AI-005 | TC-COM-AI-001, TC-COM-AI-002, TC-COM-AI-006, TC-COM-AI-007, TC-COM-AI-008 | COM-AI-TR-001, COM-AI-TR-005 | `AI_MEDIA_STORAGE_EVIDENCE_REF` | external-pending |
| AI cost dashboard and budget alert evidence | COM-SI-016 | AC-COM-AI-004 | TC-COM-AI-005 | COM-AI-TR-004 | `AI_COST_DASHBOARD_EVIDENCE_REF` | external-pending |
| AI retention policy approval and deletion proof | COM-SI-017 | AC-COM-AI-005 | TC-COM-AI-006, TC-COM-AI-007 | COM-AI-TR-005 | `AI_RETENTION_POLICY_EVIDENCE_REF` | external-pending |

## 证据安全规则
- 证据包必须存储在仓库外的受控位置，只在 release vars、测试报告或质量报告中引用 evidence ref。
- 证据不得包含 API key、secret、原始音频、完整 signed URL、完整转写、完整 provider payload、手机号、邮箱或真实姓名。
- 证据允许保留 backend request id、provider request id、media hash、user hash、job id、时间戳、环境、commit/build tag、模型、latency、error code、cost estimate、状态和 reviewer 结论。
- 所有 evidence ref 必须指向外部文档、工单、对象存储证据包、OPS-only dashboard/API 导出或 vault/CI artifact 引用；不得指向 `docs/`、`tests/`、`build/` 或本地 `file://` 路径。
- 每个 scope 必须由非执行人 reviewer 审查证据可访问性、时间戳、环境、commit/build tag、脱敏边界、覆盖完整性和 strict gate 输出。

## 外部执行结果模板
每个场景执行后复制并填写以下字段；未执行时 `Actual result` 使用 `blocked` 并写明原因。

| Field | Value |
| --- | --- |
| Execution ID | `YYYYMMDD-P0-AI-<SCOPE>-<SCENARIO>` |
| Evidence scope | DashScope / media-storage / cost-dashboard / retention-policy |
| TC ID | `TC-COM-AI-001` / `TC-COM-AI-002` / `TC-COM-AI-004` / `TC-COM-AI-005` / `TC-COM-AI-006` / `TC-COM-AI-007` / `TC-COM-AI-008` |
| Scenario ID | 见下方场景表 |
| Executor | 待填写 |
| Execution date | 待填写 |
| Environment | staging / release candidate / release CI |
| Commit / build tag | 待填写 |
| Account / vault ref | 待填写；只允许外部 vault/ref，不得填写明文账号密码 |
| Evidence ref | 待填写；外部文档、截图包、日志包、OPS dashboard/API export 或工单链接 |
| Expected result | 复制对应场景预期 |
| Actual result | `pending` / `passed` / `failed` / `blocked` |
| Failure / blocker reason | 待填写；通过时写 `N/A` |
| Reviewer | 待填写 |
| Review result | `pending` / `approved` / `rejected` |

## P0-AI-EXT-001：DashScope Provider Matrix

### 前置条件
- 使用 release candidate 后端环境和受控 DashScope 凭据。
- 使用脱敏文本、短音频、异常音频和格式样本。
- 后端 provider metric、fallback、usage 和 audit 日志已开启，且不记录完整 signed URL、raw audio、完整 transcript 或 secret。

### 场景
| Scenario ID | 步骤 | 预期结果 | 必需证据 |
| --- | --- | --- | --- |
| AI-QWEN-VALID | 调用 Qwen coach/feedback strict JSON 路径。 | JSON schema validation 通过；记录模型、latency、request id、token estimate 和 cost estimate。 | backend request id、provider model、schema-valid result、latency、cost estimate。 |
| AI-QWEN-FALLBACK | 触发 invalid/unsafe schema fallback。 | 返回 recoverable fallback；不写 learning evidence；usage 按策略处理。 | invalid schema mapping、fallback status、usage event。 |
| AI-ASR-VALID | 使用 backend-signed `audio_ref` 调用 Paraformer。 | ASR 返回 typed status；format/duration/latency/cost 可审计。 | media hash/ref、format compatibility、duration、latency、transcript status、cost estimate。 |
| AI-ASR-REJECT | 使用本地路径、unsigned URL、伪造签名、过期或超限 ref。 | provider call 前拒绝或返回 typed fallback；不记录完整 signed URL。 | rejection reason、provider call count、audit hash evidence。 |
| AI-TTS-GENERATE | 固定 text/model/voice 发起 TTS。 | 生成 media ref；记录 cache miss、char count、latency 和 cost estimate。 | media hash/ref、model、voice、latency、char count、cost estimate。 |
| AI-TTS-CACHE | 重复同一 text/model/voice。 | 返回同一有效 media ref；不重复 provider call；cache hit metric 记录。 | cache key/hash、cache hit event、provider call count。 |
| AI-PROVIDER-ERROR | 触发 timeout/rate-limit/provider error。 | 返回 typed fallback；usage 状态正确；provider anomaly 或 alert 可见。 | normalized error code、fallback status、usage event、alert/dashboard entry。 |

通过条件：全部场景 `passed`，`DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` 指向完整证据包，`python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` 和 `python3 scripts/check_ai_external_release_evidence.py --strict-external` 均通过，独立 reviewer 审查通过。

## P0-AI-STORAGE-001：Object Storage And Signed Media Ref

### 前置条件
- 明确 bucket、region、KMS/secret、signed URL TTL、访问策略、生命周期策略和删除策略。
- Flutter/后端上传链路使用 staging 或 release candidate 环境，音频 fixture 必须脱敏。
- Provider 只能访问后端签发且可过期的 `audio_ref`，客户端不得提交本地路径、裸 URL 或伪造 ref。

### 场景
| Scenario ID | 步骤 | 预期结果 | 必需证据 |
| --- | --- | --- | --- |
| AI-STORAGE-CONFIG | 审查 bucket、region、KMS/secret、ACL、TTL、lifecycle 和 deletion policy。 | 配置由后端/secret manager 控制；provider 可访问范围最小化；生命周期策略存在。 | 脱敏配置截图、policy 摘要、approval/ref。 |
| AI-STORAGE-UPLOAD | Flutter/后端上传短音频并完成 media asset validation。 | media asset 从 pending 到 validated；生成可信 `audio_ref`。 | media id/hash、backend request id、upload/complete timestamps、format metadata。 |
| AI-STORAGE-PROVIDER-ACCESS | 使用 backend-signed `audio_ref` 调用 ASR。 | Provider 可读取短音频；ASR 返回 typed status；不暴露完整 signed URL。 | provider request id、media hash/ref、latency、status、sanitized access proof。 |
| AI-STORAGE-EXPIRE | 等待或强制 signed URL/media ref 过期后访问。 | 过期 ref 不可访问；后端返回 typed expired/rejected。 | expiry timestamp、rejected status、audit hash。 |
| AI-STORAGE-DELETE | 删除 media asset 或执行 lifecycle cleanup 后访问。 | 对象和 media metadata 按策略删除/标记删除；再次访问不可用。 | deletion job id、object delete proof、post-delete access denied proof。 |
| AI-STORAGE-REJECT | 提交本地路径、裸 HTTP URL、伪造 ref、超时长或超大小输入。 | provider call 前拒绝；审计只保留 hash/status。 | rejection reason、provider call count、audit hash evidence。 |

通过条件：全部场景 `passed`，`AI_MEDIA_STORAGE_EVIDENCE_REF` 指向完整证据包，`python3 scripts/check_ai_external_release_evidence.py --strict-external` 通过，Security/DevOps reviewer 审查通过。

## P0-AI-COST-001：Cost Dashboard And Unit Economics

### 前置条件
- 使用真实或 staging provider 调用生成样本，不使用 raw user content。
- PM/Ops 明确定义套餐成本预算、单用户日成本阈值、套餐月成本阈值、provider error spike 和 cache hit 下降告警。
- OPS-only dashboard/API 可按套餐、用户 hash、provider family、模型、能力类型、调用状态、token/audio duration、cache hit 和 fallback reason 聚合。

### 场景
| Scenario ID | 步骤 | 预期结果 | 必需证据 |
| --- | --- | --- | --- |
| AI-COST-SAMPLE-CALLS | 生成 LLM/ASR/TTS 成本样本。 | 每次 provider call 产生 sanitized metric；记录 token/audio units、duration、cost estimate。 | metric ids、provider/model/capability/status、cost basis。 |
| AI-COST-DASHBOARD-DIMENSIONS | 打开 OPS-only dashboard/API 并按必需维度筛选。 | 套餐、用户 hash、provider family、model、capability、status、cache hit、fallback reason 均可聚合。 | dashboard screenshot/API export、dimension coverage note。 |
| AI-COST-BUDGET-ALERTS | 触发或模拟预算 warning/exceeded、provider anomaly 和 cache hit 下降。 | 告警或状态可见；阈值和目的地有审批记录。 | alert event id、threshold config、OPS channel/ref。 |
| AI-COST-RAW-CONTENT-GUARD | 检查 dashboard/API 响应。 | 不暴露 raw text、raw audio、完整 transcript、完整 signed URL、邮箱或手机号。 | sanitized response sample、reviewer note。 |
| AI-COST-PM-APPROVAL | PM/Ops 审批最小 unit economics。 | Free/Pro/Premium 成本和毛利风险可被业务判断。 | approval record、budget threshold summary。 |

通过条件：全部场景 `passed`，`AI_COST_DASHBOARD_EVIDENCE_REF` 指向完整证据包，`python3 scripts/check_ai_external_release_evidence.py --strict-external` 通过，PM/Ops reviewer 审查通过。

## P0-AI-RETENTION-001：Retention Policy And Deletion Proof

### 前置条件
- Security/PM 批准 retention policy，分别覆盖原始音频、转写文本、provider payload、TTS cache、日志、成本指标和审计字段。
- 在 staging 对真实对象存储和数据库执行 retention/account deletion job。
- 证据只保留 hash、job id、时间戳、结果状态、计数和 reviewer 结论。

### 场景
| Scenario ID | 步骤 | 预期结果 | 必需证据 |
| --- | --- | --- | --- |
| AI-RETENTION-POLICY-APPROVAL | 审批 retention policy 版本。 | 每类 AI 数据有保留期限、删除/匿名化动作、失败重试和最小审计字段定义。 | policy version/ref、approver、effective date。 |
| AI-RETENTION-AUDIO-DELETE | 对真实对象存储执行过期音频 cleanup。 | 用户音频对象删除或失效；再次访问不可用。 | retention job id、object delete proof、post-delete access denied proof。 |
| AI-RETENTION-TRANSCRIPT-REDACT | 删除或匿名化 transcript/provider-derived feedback。 | raw transcript 不再可取；只保留允许的 hash/审计字段。 | database row hash、redaction count、job status。 |
| AI-RETENTION-TTS-OWNER-CACHE | 执行账号删除或 cache cleanup。 | 删除 owner ref；最后 owner 删除后 cache entry 删除/失效。 | cache id/hash、owner ref count before/after、job status。 |
| AI-RETENTION-METRIC-SANITIZE | 检查 provider metric 和成本指标保留。 | 成本统计保留 hash/aggregate，不保留 raw user content。 | metric sample、redaction proof、reviewer note。 |
| AI-RETENTION-RETRY-MANUAL | 触发 retryable/manual failure。 | 失败进入 retry/manual ops；后续重跑可审计。 | failure job id、retry status、manual queue/ref。 |

通过条件：全部场景 `passed`，`AI_RETENTION_POLICY_EVIDENCE_REF` 指向完整证据包，`python3 scripts/check_ai_external_release_evidence.py --strict-external` 通过，Security/PM reviewer 审查通过。

## 回填和审查顺序
1. 执行 `P0-AI-EXT-001`，回填 `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`，运行 `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` 和 `python3 scripts/check_ai_external_release_evidence.py --strict-external`，写入独立 AI Runtime review。
2. 执行 `P0-AI-STORAGE-001`，回填 `AI_MEDIA_STORAGE_EVIDENCE_REF`，运行 `python3 scripts/check_ai_external_release_evidence.py --strict-external`，写入 Security/DevOps review。
3. 执行 `P0-AI-COST-001`，回填 `AI_COST_DASHBOARD_EVIDENCE_REF`，运行 `python3 scripts/check_ai_external_release_evidence.py --strict-external`，写入 PM/Ops unit-economics review。
4. 执行 `P0-AI-RETENTION-001`，回填 `AI_RETENTION_POLICY_EVIDENCE_REF`，运行 `python3 scripts/check_ai_external_release_evidence.py --strict-external`，写入 Security/PM privacy review。
5. 四项全部通过后，执行 `scripts/check_release_readiness.sh`，并更新 `docs/reports/test_report.md`、`docs/reports/quality_report.md`、`docs/release/release_checklist.md` 和 `docs/product/increments/commercial-ai-provider-hardening/traceability.md`。

未提供四个 evidence refs 前，paid AI voice 和真实 DashScope provider release 必须保持 blocked。
