# Acceptance Criteria：商业 AI Provider 生产化加固

## 状态
Draft - 来自 `commercial-ai-provider-hardening` spec 的增量验收标准。

## Upstream
- Requirements：`docs/product/increments/commercial-ai-provider-hardening/requirements.md`
- Spec：`docs/product/increments/commercial-ai-provider-hardening/spec.md`
- Change request：`CR-20260601-002`

## Stage Scope Acceptance Coverage
| Stage Scope ID | Requirement ID | Spec ID | Acceptance Criteria |
| --- | --- | --- | --- |
| COM-SI-013 | FR-COM-AI-001 | COM-AI-SPEC-001 | AC-COM-AI-001 |
| COM-SI-014 | FR-COM-AI-002 | COM-AI-SPEC-002 | AC-COM-AI-002 |
| COM-SI-015 | FR-COM-AI-003 | COM-AI-SPEC-003 | AC-COM-AI-003 |
| COM-SI-016 | FR-COM-AI-004 | COM-AI-SPEC-004 | AC-COM-AI-004 |
| COM-SI-017 | FR-COM-AI-005 | COM-AI-SPEC-005 | AC-COM-AI-005 |

## AC-COM-AI-001 可信媒体上传和 ASR 输入
给定用户完成录音，当进入生产 ASR 流程时，系统必须通过后端上传或对象存储生成可信 `audio_ref`，并拒绝本地路径、裸 HTTP URL、伪造签名、超时长或超大小输入。

## AC-COM-AI-002 持久化 TTS 缓存
给定相同 normalized text、model、voice 和 language，当系统多次请求 TTS 且缓存仍有效时，系统必须返回同一持久化 media ref，不重复调用 provider；当缓存过期或删除时，系统必须重新生成或返回 typed unavailable。

## AC-COM-AI-003 真实 DashScope provider evidence
给定 release candidate 环境，当执行 DashScope LLM、ASR 和 TTS sandbox / controlled live 测试时，系统必须记录延迟、错误码、费用、音频格式兼容性、fallback 和独立审查结果；缺少证据时不得关闭 release gate。

## AC-COM-AI-004 AI 成本看板
给定 AI/ASR/TTS/评分调用产生，当 PM/Ops 查看成本看板时，必须能按套餐、用户 hash、provider family、模型、调用状态和 cache hit 查看成本、预算消耗、异常和毛利风险。

## AC-COM-AI-005 生产数据保留与删除
给定 retention job 或账号删除 job 执行，当用户相关音频、转写、provider-derived feedback 或 TTS cache 存在时，系统必须按策略删除、匿名化或保留最小审计字段，并记录脱敏执行证据和失败重试状态。
