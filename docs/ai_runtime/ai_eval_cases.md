# AI Evaluation Cases

## Case Format

```json
{
  "id": "case_001",
  "scenario": "job_interview_status_update",
  "input": {
    "action_step": "flag_risks",
    "learner_turn": "export function has risk"
  },
  "expected": {
    "valid_json": true,
    "main_issue_type": "naturalness",
    "next_action_type": "continue_dialogue"
  }
}
```

## MVP Cases
- Learner gives a clear but unnatural answer.
- Learner gives a grammatically wrong answer.
- Learner is off-topic.
- Learner answer is too short.
- Learner completes the action step.
- Provider returns invalid JSON.

- Learner 给出清楚但不自然的答案。
- Learner 给出语法错误的答案。
- Learner 的回答偏离主题。
- Learner 的回答过短。
- Learner 完成当前 action step。
- Provider 返回 invalid JSON。

## MVP Backend Practice/AI Cases
| Case ID | Owning increment | Input | Expected |
| --- | --- | --- | --- |
| AI-EVAL-MVP-BE-001 | `mvp-backend-practice-ai` | Valid interview answer with one naturalness issue | Valid JSON, `feedback_type=next_question`, score signal includes `source=server_side_adapter`, evidence remains candidate-only. |
| AI-EVAL-MVP-BE-002 | `mvp-backend-practice-ai` | Off-topic answer | Valid JSON, `main_issue.type=off_topic`, next action asks retry, no mastery update. |
| AI-EVAL-MVP-BE-003 | `mvp-backend-practice-ai` | Provider invalid schema | Fallback output, `recoverable_error.retryable=true`, no successful feedback or evidence candidate. |
| AI-EVAL-MVP-BE-004 | `mvp-backend-practice-ai` | ASR unavailable for audio-only turn | Session preserved as recoverable, learner input/audio ref retained, no pseudo success feedback. |

中文等价说明：
- AI-EVAL-MVP-BE-001：有效的面试回答只存在一个 naturalness 问题；期望返回 valid JSON，`feedback_type=next_question`，score signal 包含 `source=server_side_adapter`，evidence 仍保持 candidate-only。
- AI-EVAL-MVP-BE-002：回答 off-topic；期望 valid JSON，`main_issue.type=off_topic`，next action 要求 retry，不更新 mastery。
- AI-EVAL-MVP-BE-003：provider 返回 invalid schema；期望 fallback output，`recoverable_error.retryable=true`，不产生 successful feedback 或 evidence candidate。
- AI-EVAL-MVP-BE-004：audio-only turn 中 ASR unavailable；期望 session 保持 recoverable，保留 learner input/audio ref，不生成伪成功反馈。

## P0.1 Training AI Eval Cases

Executable validator:

可执行校验器：

```bash
dart run scripts/check_ai_eval_cases.dart
```

Fixture: `tests/ai_runtime/p0_1_ai_eval_cases.json`。

Fixture：`tests/ai_runtime/p0_1_ai_eval_cases.json`。

Scope: TC-P01-014 validates the documented P0.1 `TrainingFeedbackCandidate` AI eval cases by calling the runtime schema validator in `lib/features/training/training_contract.dart`。The validator checks all seven P0.1 cases below, planner-approved next actions, recoverable fallback behavior, pressure prompt gating, candidate-only learning evidence, pronunciation-unavailable continuation and prohibited final mastery/billing/review fields。Official scenario/version allowlist is owned by backend Training content mapping; the Flutter schema validator must not hard-code the two original scenes.

范围：TC-P01-014 通过调用 `lib/features/training/training_contract.dart` 中的 runtime schema validator，验证本文档列出的 P0.1 `TrainingFeedbackCandidate` AI eval cases。该 validator 覆盖下面七个 P0.1 cases、planner-approved next actions、recoverable fallback behavior、pressure prompt gating、candidate-only learning evidence、pronunciation-unavailable continuation，以及禁止出现的 final mastery/billing/review fields。Official scenario/version allowlist 由 backend Training content mapping 持有；Flutter schema validator 不得硬编码最初的两个 scenes。

| Case ID | Owning increment | Input | Expected |
| --- | --- | --- | --- |
| AI-EVAL-P01-001 | `p0-1-expression-automation-training` | `job_interview`, `SayOne`, sentence-frame hint, learner covers opening intent with slightly unnatural wording | Valid `TrainingFeedbackCandidate`; `completion_signal.status=met` or `partial`; one concise naturalness suggestion; evidence remains `candidate`; no final mastery. |
| AI-EVAL-P01-002 | `p0-1-expression-automation-training` | `ChooseOne`, learner chooses option that misses the intent | Valid schema; `task_signal.status=not_met`; `recommended_next_action.type=retry` or `raise_hint`; no pressure prompt. |
| AI-EVAL-P01-003 | `p0-1-expression-automation-training` | `ShadowOne`, pronunciation score unavailable but transcript is acceptable | Valid schema; `pronunciation_signal.status=unavailable`; feedback continues; user is not failed solely due to missing score. |
| AI-EVAL-P01-004 | `p0-1-expression-automation-training` | ASR failure with audio ref and no transcript | Recoverable fallback candidate; `recommended_next_action.type=retry` or `text_fallback`; no weak evidence candidate. |
| AI-EVAL-P01-005 | `p0-1-expression-automation-training` | Consecutive success context with planner allowing pressure check | Valid schema; may include `pressure_prompt_candidate.enabled=true` only with `recommended_next_action.type=pressure_check`; prompt stays in current session/scenario. |
| AI-EVAL-P01-006 | `p0-1-expression-automation-training` | LLM attempts to output `mastered=true` or a cross-day schedule | Validation rejects or strips prohibited fields; deterministic fallback returns candidate-only feedback. |
| AI-EVAL-P01-007 | `p0-1-expression-automation-training` | Future/custom scene id with invented target expression/action step | Validation fails for invented action-chain step or micro-action; scene officialness is fail-closed by backend scenario/version/mapping, not a Flutter two-scene allowlist. |

中文等价说明：
- AI-EVAL-P01-001：`job_interview`、`SayOne`、sentence-frame hint 下，learner 用略不自然的措辞覆盖开场意图；期望 valid `TrainingFeedbackCandidate`，`completion_signal.status=met` 或 `partial`，只给一个简洁 naturalness suggestion，evidence 保持 `candidate`，不产生 final mastery。
- AI-EVAL-P01-002：`ChooseOne` 中 learner 选择未覆盖意图的选项；期望 valid schema，`task_signal.status=not_met`，`recommended_next_action.type=retry` 或 `raise_hint`，不触发 pressure prompt。
- AI-EVAL-P01-003：`ShadowOne` 中 pronunciation score unavailable，但 transcript 可接受；期望 valid schema，`pronunciation_signal.status=unavailable`，feedback 继续，不能只因缺少 score 判定用户失败。
- AI-EVAL-P01-004：ASR failure 且有 audio ref、无 transcript；期望 recoverable fallback candidate，`recommended_next_action.type=retry` 或 `text_fallback`，不产生 weak evidence candidate。
- AI-EVAL-P01-005：连续成功上下文且 planner 允许 pressure check；期望 valid schema，只有当 `recommended_next_action.type=pressure_check` 时才可包含 `pressure_prompt_candidate.enabled=true`，prompt 必须留在当前 session/scenario。
- AI-EVAL-P01-006：LLM 尝试输出 `mastered=true` 或 cross-day schedule；期望 validation 拒绝或剥离 prohibited fields，deterministic fallback 返回 candidate-only feedback。
- AI-EVAL-P01-007：future/custom scene id 搭配虚构的 target expression/action step；期望 validation 因虚构 action-chain step 或 micro-action 失败；scene officialness 由 backend scenario/version/mapping fail-closed，而不是 Flutter two-scene allowlist。

## P0.2 Followup-B AI Eval Cases

Status: planned contract only. This section documents AI eval coverage required before implementation; it does not create executable `tests/ai_eval/` fixtures in this step.

状态：仅为 planned contract。本节记录实现前必须覆盖的 AI eval 范围；本步骤不创建可执行的 `tests/ai_eval/` fixtures。

Owning increment: `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

所属增量：`docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

Traceability:
- `AC-P02-FUB-007`
- `AC-P02-FUB-008`
- `TC-P02-FUB-014` primary AI eval
- `TC-P02-FUB-015` supporting replay-input coverage only

可追溯项：
- `AC-P02-FUB-007`
- `AC-P02-FUB-008`
- `TC-P02-FUB-014` 作为 primary AI eval。
- `TC-P02-FUB-015` 只提供 supporting replay-input coverage。

Planned validator target: backend/runtime schema validator for `FollowupBMasteryTransitionExplanationCandidate` plus deterministic fallback handling. The validator must reject forbidden persistent fields before any AI candidate can be rendered or associated with a `MasteryTransitionDecision`.

计划 validator 目标：backend/runtime schema validator 覆盖 `FollowupBMasteryTransitionExplanationCandidate`，并包含 deterministic fallback handling。任何 AI candidate 被渲染或关联到 `MasteryTransitionDecision` 之前，validator 必须先拒绝 forbidden persistent fields。

| Case ID | Owning increment | Input | Expected |
| --- | --- | --- | --- |
| AI-EVAL-P02-FUB-001 | `p0-2-followup-b-autopilot-control-planner-memory` | Deterministic `MasteryTransitionDecision` promotes L2 -> L3 with accepted evidence refs, medium confidence and no official-score claim | Valid `followup_b_mastery_transition_explanation_candidate`; explanation is concise, product-internal, candidate-only and does not create final mastery or review schedule. |
| AI-EVAL-P02-FUB-002 | `p0-2-followup-b-autopilot-control-planner-memory` | Deterministic decision holds L2 because evidence is low confidence or partial support | Valid candidate explains hold conservatively; no forced promotion, goal completion claim or high-confidence wording. |
| AI-EVAL-P02-FUB-003 | `p0-2-followup-b-autopilot-control-planner-memory` | Repeated failure/retrieval regression produces deterministic demotion or hold | Valid candidate explains risk using safe reason code; does not blame provider/ASR failure or expose raw transcript. |
| AI-EVAL-P02-FUB-004 | `p0-2-followup-b-autopilot-control-planner-memory` | Malicious/invalid provider output includes `final_mastery_level`, `review_due_at`, `notification_schedule`, `goal_completed` or `official_score` | Schema validation rejects or ignores candidate for persistence; deterministic fallback uses `MasteryTransitionDecision.reason_code`; no state mutation. |
| AI-EVAL-P02-FUB-005 | `p0-2-followup-b-autopilot-control-planner-memory` | Provider output exposes raw transcript, raw audio ref, provider payload, provider name or sensitive diagnostic detail | Candidate is rejected; fallback explanation is rendered from redacted deterministic facts only; logs omit sensitive raw content. |
| AI-EVAL-P02-FUB-006 | `p0-2-followup-b-autopilot-control-planner-memory` | Provider timeout or unavailable during explanation generation | Deterministic fallback explanation is returned; existing transition and replay audit remain unchanged; no duplicate transition record. |
| AI-EVAL-P02-FUB-007 | `p0-2-followup-b-autopilot-control-planner-memory` | Replay fixture reuses the same transition input, reason code and rule version | Deterministic replay compares decision, reason code, output state and rule version; candidate prose is not treated as source-of-truth evidence. |

中文等价说明：
- AI-EVAL-P02-FUB-001：deterministic `MasteryTransitionDecision` 基于 accepted evidence refs、medium confidence 且无 official-score claim，将 L2 提升到 L3；期望 valid `followup_b_mastery_transition_explanation_candidate`，说明简洁、product-internal、candidate-only，不创建 final mastery 或 review schedule。
- AI-EVAL-P02-FUB-002：deterministic decision 因 evidence low confidence 或 partial support 保持 L2；期望 valid candidate 保守解释 hold，不强制 promotion，不声称 goal completion，也不使用 high-confidence wording。
- AI-EVAL-P02-FUB-003：重复失败或 retrieval regression 产生 deterministic demotion 或 hold；期望 valid candidate 用 safe reason code 解释风险，不归咎 provider/ASR failure，也不暴露 raw transcript。
- AI-EVAL-P02-FUB-004：恶意或 invalid provider output 包含 `final_mastery_level`、`review_due_at`、`notification_schedule`、`goal_completed` 或 `official_score`；期望 schema validation 拒绝或忽略 candidate 的持久化，deterministic fallback 使用 `MasteryTransitionDecision.reason_code`，不发生 state mutation。
- AI-EVAL-P02-FUB-005：provider output 暴露 raw transcript、raw audio ref、provider payload、provider name 或 sensitive diagnostic detail；期望 candidate 被拒绝，fallback explanation 只由 redacted deterministic facts 渲染，logs 省略 sensitive raw content。
- AI-EVAL-P02-FUB-006：explanation generation 时 provider timeout 或 unavailable；期望返回 deterministic fallback explanation，现有 transition 和 replay audit 不变，不创建 duplicate transition record。
- AI-EVAL-P02-FUB-007：replay fixture 复用相同 transition input、reason code 和 rule version；期望 deterministic replay 比较 decision、reason code、output state 和 rule version；candidate prose 不作为 source-of-truth evidence。

Forbidden-field assertion for `TC-P02-FUB-014`: every AI eval case that contains a forbidden persistent field must fail schema validation or be stripped before rendering, and must not update `MasteryTransitionDecision`, `MemoryItemPolicyState`, `NotificationOutboxRecord`, `UserAutopilotControl`, `RecoveryPlanDecision` or any review schedule.

`TC-P02-FUB-014` 的 forbidden-field 断言：任何包含 forbidden persistent field 的 AI eval case 都必须在渲染前 schema validation 失败或被剥离，并且不得更新 `MasteryTransitionDecision`、`MemoryItemPolicyState`、`NotificationOutboxRecord`、`UserAutopilotControl`、`RecoveryPlanDecision` 或任何 review schedule。

## P0.2 Followup-C Forecast Explanation Eval Cases

Status: local S001 backend policy/schema validation。

状态：local S001 backend policy/schema validation。

Owning increment: `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`。

所属增量：`docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`。

Traceability:
- `AC-P02-FUC-001`
- `TC-P02-FUC-003`

可追溯项：
- `AC-P02-FUC-001`
- `TC-P02-FUC-003`

Validator target: backend deterministic `ProgressForecastPolicy` plus forecast explanation guardrails. S001 does not call a live provider; deterministic no-provider fallback is valid evidence when it returns explicit fallback metadata and keeps claim guards closed.

Validator 目标：backend deterministic `ProgressForecastPolicy` 与 forecast explanation guardrails。S001 不调用 live provider；只要返回明确 fallback metadata 并保持 claim guards closed，deterministic no-provider fallback 就是有效证据。

| Case ID | Owning increment | Input | Expected |
| --- | --- | --- | --- |
| AI-EVAL-P02-FUC-001 | `p0-2-followup-c-checkpoint-forecast-surfaces` | Supported goal, medium/high confidence, checkpoint evidence missing, provider path not configured | Forecast returns deterministic explanation metadata, risk reason `checkpoint_evidence_missing`, no goal completion claim, no official-score equivalence and no provider entitlement fact. |
| AI-EVAL-P02-FUC-002 | `p0-2-followup-c-checkpoint-forecast-surfaces` | Partial, unsupported, low-confidence, stale or recovery-required forecast | Forecast suppresses precise ETA and completion copy, exposes deterministic limitation reason and keeps AI explanation candidate-only. |
| AI-EVAL-P02-FUC-003 | `p0-2-followup-c-checkpoint-forecast-surfaces` | Candidate output attempts `goal_completed`, official score/certification, guaranteed ETA, entitlement, quota or billing fields | Validator rejects/ignores candidate; deterministic fallback from `risk_reason_code` remains the rendered explanation and no forecast, checkpoint, plan, entitlement or billing state is mutated. |
| AI-EVAL-P02-FUC-004 | `p0-2-followup-c-checkpoint-forecast-surfaces` | Candidate output includes raw transcript, raw audio ref, provider payload or sensitive diagnostic details | Candidate is rejected; fallback metadata is redacted and safe for Flutter/report surfaces. |

中文等价说明：
- AI-EVAL-P02-FUC-001：supported goal、medium/high confidence、checkpoint evidence missing 且未配置 provider path；期望 forecast 返回 deterministic explanation metadata，risk reason 为 `checkpoint_evidence_missing`，不声明 goal completion，不做 official-score equivalence，也不创建 provider entitlement fact。
- AI-EVAL-P02-FUC-002：forecast 为 partial、unsupported、low-confidence、stale 或 recovery-required；期望压制 precise ETA 和 completion copy，暴露 deterministic limitation reason，并保持 AI explanation candidate-only。
- AI-EVAL-P02-FUC-003：candidate output 尝试写入 `goal_completed`、official score/certification、guaranteed ETA、entitlement、quota 或 billing fields；期望 validator 拒绝或忽略 candidate，来自 `risk_reason_code` 的 deterministic fallback 仍是渲染说明，并且不修改 forecast、checkpoint、plan、entitlement 或 billing state。
- AI-EVAL-P02-FUC-004：candidate output 包含 raw transcript、raw audio ref、provider payload 或 sensitive diagnostic details；期望 candidate 被拒绝，fallback metadata 已 redacted，且可安全用于 Flutter/report surfaces。

## P0.2 Followup-D S005 Cost Telemetry And AI Fallback Eval Cases

Status: local S005 backend guardrail validation.

状态：local S005 backend guardrail validation。

Owning increment: `docs/product/increments/p0-2-followup-d-release-gate-hardening/`。

所属增量：`docs/product/increments/p0-2-followup-d-release-gate-hardening/`。

Traceability:
- `AC-P02-FUD-005`
- `TC-P02-FUD-010`

可追溯项：
- `AC-P02-FUD-005`
- `TC-P02-FUD-010`

Validator target: backend forecast and mastery explanation candidate validators. S005 does not require a live provider call; deterministic no-provider and policy-rejection paths are valid only when the evidence explicitly records no live provider success.

Validator 目标：backend forecast 与 mastery explanation candidate validators。S005 不要求 live provider call；只有当 evidence 明确记录没有 live provider success 时，deterministic no-provider 与 policy-rejection paths 才有效。

| Case ID | Owning increment | Input | Expected |
| --- | --- | --- | --- |
| AI-EVAL-P02-FUD-001 | `p0-2-followup-d-release-gate-hardening` | Forecast explanation candidate includes `entitlement`, `quota_state`, `billing_state`, `final_mastery_level`, `release_approval` or `product_base_merge_approved` | Candidate validation rejects with `ai_forbidden_persistent_field`; deterministic fallback remains rendered; no forecast, goal, entitlement, quota, release or Product Base state is mutated. |
| AI-EVAL-P02-FUD-002 | `p0-2-followup-d-release-gate-hardening` | Mastery transition candidate includes `release_approval`, `release_ready` or `product_base_merge_approved` | Candidate validation rejects with `ai_forbidden_persistent_field`; deterministic mastery transition explanation fallback is used; no release or Product Base approval fact is created. |
| AI-EVAL-P02-FUD-003 | `p0-2-followup-d-release-gate-hardening` | Provider candidate is unavailable or policy blocks provider use | Cost telemetry records sanitized rejected/fallback evidence with safe fallback reason and no raw transcript, raw audio, provider payload, entitlement fact or live-provider success claim. |
| AI-EVAL-P02-FUD-004 | `p0-2-followup-d-release-gate-hardening` | Deterministic no-provider path completes plan or checkpoint flow | Cost telemetry records `deterministic_no_provider` with zero estimated cost and fallback reason identifying the deterministic no-provider operation, not paid AI external evidence. |

中文等价说明：
- AI-EVAL-P02-FUD-001：forecast explanation candidate 包含 `entitlement`、`quota_state`、`billing_state`、`final_mastery_level`、`release_approval` 或 `product_base_merge_approved`；期望 candidate validation 以 `ai_forbidden_persistent_field` 拒绝，deterministic fallback 继续渲染，不修改 forecast、goal、entitlement、quota、release 或 Product Base state。
- AI-EVAL-P02-FUD-002：mastery transition candidate 包含 `release_approval`、`release_ready` 或 `product_base_merge_approved`；期望 candidate validation 以 `ai_forbidden_persistent_field` 拒绝，并使用 deterministic mastery transition explanation fallback，不创建 release 或 Product Base approval fact。
- AI-EVAL-P02-FUD-003：provider candidate unavailable 或 policy blocks provider use；期望 cost telemetry 记录 sanitized rejected/fallback evidence，包含 safe fallback reason，且没有 raw transcript、raw audio、provider payload、entitlement fact 或 live-provider success claim。
- AI-EVAL-P02-FUD-004：deterministic no-provider path 完成 plan 或 checkpoint flow；期望 cost telemetry 记录 `deterministic_no_provider`、zero estimated cost，并用 fallback reason 标识 deterministic no-provider operation，而不是 paid AI external evidence。

## P0.2 Followup-E Speaking Diagnostic Eval Cases

Status: planned contract only. This section documents AI/provider guardrail coverage required before implementation; it does not create executable `tests/ai_eval/` fixtures in this phase.

状态：仅为 planned contract。本节记录实现前必须覆盖的 AI/provider guardrail 范围；本阶段不创建可执行的 `tests/ai_eval/` fixtures。

Owning increment: `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。

所属增量：`docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。

Traceability:
- Planned `AC-P02-FUE-006`
- Planned `AC-P02-FUE-007`
- Planned `AC-P02-FUE-009`
- Planned `AC-P02-FUE-010`
- Planned `TC-P02-FUE-013` through `TC-P02-FUE-016`
- Planned `TC-P02-FUE-020` through `TC-P02-FUE-026`

可追溯项：
- 计划覆盖 `AC-P02-FUE-006`
- 计划覆盖 `AC-P02-FUE-007`
- 计划覆盖 `AC-P02-FUE-009`
- 计划覆盖 `AC-P02-FUE-010`
- 计划覆盖 `TC-P02-FUE-013` 至 `TC-P02-FUE-016`
- 计划覆盖 `TC-P02-FUE-020` 至 `TC-P02-FUE-026`

Validator target: backend/runtime schema validator for `FollowupESpeakingDiagnosticCandidate` plus deterministic fallback handling for ASR, pronunciation/scoring, LLM explanation, quota/cost and privacy-sensitive payload rejection. The validator must reject forbidden persistent fields before any candidate can be rendered or associated with an accepted `DiagnosticAssessment`.

Validator 目标：backend/runtime schema validator 覆盖 `FollowupESpeakingDiagnosticCandidate`，并包含 ASR、pronunciation/scoring、LLM explanation、quota/cost 和 privacy-sensitive payload rejection 的 deterministic fallback handling。任何 candidate 被渲染或关联到 accepted `DiagnosticAssessment` 之前，validator 必须先拒绝 forbidden persistent fields。

| Case ID | Owning increment | Input | Expected |
| --- | --- | --- | --- |
| AI-EVAL-P02-FUE-001 | `p0-2-followup-e-speaking-diagnostic-production` | `audio_full` diagnostic with three accepted samples, medium/high ASR confidence, valid quality gates and no claim-guard issue | Valid `followup_e_speaking_diagnostic_candidate`; 1-3 actionable weaknesses; next training focus uses allowed category; no official-score, goal-completion or persistent state field. |
| AI-EVAL-P02-FUE-002 | `p0-2-followup-e-speaking-diagnostic-production` | `audio_partial` diagnostic with one skipped or low-quality sample | Valid candidate explains limitation, keeps confidence conservative and offers later recalibration; no full diagnostic completion wording. |
| AI-EVAL-P02-FUE-003 | `p0-2-followup-e-speaking-diagnostic-production` | `text_only` fallback with user-entered samples and no accepted audio | Candidate may summarize text-based answer structure or vocabulary issues only; validator rejects pronunciation, intonation, speech-rate, pause timing or acoustic fluency claims. |
| AI-EVAL-P02-FUE-004 | `p0-2-followup-e-speaking-diagnostic-production` | Provider output attempts to include `audio_ref`, local path, signed URL, raw audio ref, raw provider payload or provider secret | Candidate is rejected; deterministic fallback renders from safe diagnostic facts only; no `DiagnosticAudioSample` or `audio_ref` mutation. |
| AI-EVAL-P02-FUE-005 | `p0-2-followup-e-speaking-diagnostic-production` | Provider output attempts official IELTS/TOEFL/CEFR score, certification, guaranteed ETA, goal completion, final mastery, entitlement, quota, billing, release approval or Product Base merge approval | Candidate is rejected with forbidden-field/claim-guard reason; accepted diagnostic facts and downstream plan/forecast/checkpoint state are unchanged. |
| AI-EVAL-P02-FUE-006 | `p0-2-followup-e-speaking-diagnostic-production` | ASR empty/low confidence, pronunciation provider unavailable, quota exhausted or cost budget blocked | Diagnostic downgrades to lower confidence/depth with safe reason code; no fabricated acoustic dimension; usage reservation is released or marked by auditable policy. |
| AI-EVAL-P02-FUE-007 | `p0-2-followup-e-speaking-diagnostic-production` | Raw transcript contains sensitive personal detail in a free-answer sample | Candidate and logs use redacted safe summary only; exports/reports do not expose unrestricted transcript or provider payload. |
| AI-EVAL-P02-FUE-008 | `p0-2-followup-e-speaking-diagnostic-production` | Diagnostic deletion/retention state marks audio/transcript unavailable | Candidate cannot cite deleted audio as current high-confidence evidence; UI fallback should show recalibration or deleted/unavailable state. |

中文等价说明：
- AI-EVAL-P02-FUE-001：`audio_full` diagnostic 包含三条 accepted samples、medium/high ASR confidence、valid quality gates 且无 claim-guard issue；期望 valid `followup_e_speaking_diagnostic_candidate`，给出 1-3 个 actionable weaknesses，next training focus 使用 allowed category，不出现 official-score、goal-completion 或 persistent state field。
- AI-EVAL-P02-FUE-002：`audio_partial` diagnostic 中有一条 sample skipped 或 low-quality；期望 valid candidate 解释 limitation，保持 conservative confidence，并提供后续 recalibration，不使用 full diagnostic completion wording。
- AI-EVAL-P02-FUE-003：`text_only` fallback 使用用户输入样本且没有 accepted audio；candidate 只能总结 text-based answer structure 或 vocabulary issues；validator 必须拒绝 pronunciation、intonation、speech-rate、pause timing 或 acoustic fluency claims。
- AI-EVAL-P02-FUE-004：provider output 尝试包含 `audio_ref`、local path、signed URL、raw audio ref、raw provider payload 或 provider secret；期望 candidate 被拒绝，deterministic fallback 只从 safe diagnostic facts 渲染，不修改 `DiagnosticAudioSample` 或 `audio_ref`。
- AI-EVAL-P02-FUE-005：provider output 尝试 official IELTS/TOEFL/CEFR score、certification、guaranteed ETA、goal completion、final mastery、entitlement、quota、billing、release approval 或 Product Base merge approval；期望 candidate 因 forbidden-field/claim-guard reason 被拒绝，accepted diagnostic facts 与下游 plan/forecast/checkpoint state 保持不变。
- AI-EVAL-P02-FUE-006：ASR empty/low confidence、pronunciation provider unavailable、quota exhausted 或 cost budget blocked；期望 diagnostic 以 safe reason code 降级到更低 confidence/depth，不伪造 acoustic dimension，usage reservation 被释放或按可审计 policy 标记。
- AI-EVAL-P02-FUE-007：free-answer sample 的 raw transcript 包含敏感个人信息；期望 candidate 与 logs 只使用 redacted safe summary，exports/reports 不暴露 unrestricted transcript 或 provider payload。
- AI-EVAL-P02-FUE-008：diagnostic deletion/retention state 标记 audio/transcript unavailable；candidate 不能引用 deleted audio 作为当前 high-confidence evidence；UI fallback 应展示 recalibration 或 deleted/unavailable state。

Forbidden-field assertion for planned `TC-P02-FUE-015` and `TC-P02-FUE-024`: every AI eval case that contains a forbidden persistent field, official-score claim, text-only acoustic claim or sensitive raw payload must fail schema validation or be stripped before rendering, and must not update `DiagnosticAssessment`, `DiagnosticAudioSample`, `DiagnosticPrivacyState`, `GoalProfile`, `GoalBackplan`, `ProgressForecast`, `OutcomeCheckpoint`, entitlement, billing, release or Product Base facts.

planned `TC-P02-FUE-015` 和 `TC-P02-FUE-024` 的 forbidden-field 断言：任何包含 forbidden persistent field、official-score claim、text-only acoustic claim 或 sensitive raw payload 的 AI eval case，都必须在渲染前 schema validation 失败或被剥离，并且不得更新 `DiagnosticAssessment`、`DiagnosticAudioSample`、`DiagnosticPrivacyState`、`GoalProfile`、`GoalBackplan`、`ProgressForecast`、`OutcomeCheckpoint`、entitlement、billing、release 或 Product Base facts。
