---
name: prompt-contract-generate
description: Use when an AI feature needs prompts, structured output schema, examples, fallback behavior, or eval cases. Do not use when the feature has no LLM-facing behavior.
---

# Prompt Contract Generate

## Overview
Make AI runtime behavior constrained, testable, and safe for frontend rendering.

## When to Use
- A scenario coach, correction, review, or explanation feature calls an LLM.
- LLM output must be rendered by the app.
- Prompt changes need regression coverage.

## When NOT to Use
- The change is deterministic and does not call an LLM.
- Only static content is being edited.
- The AI contract already exists and only provider wiring changes.

## Inputs
- Increment spec, domain model, and UI rendering needs for new product work.
- Product Base spec or feature registry boundary when validating accepted stable behavior.
- Existing docs/ai_runtime/ contracts.
- Safety, fallback, and cost constraints.

## Outputs
- System/developer prompt contract.
- Input schema and JSON output schema.
- Positive examples, negative examples, fallbacks, and eval cases.
- Traceability note to the owning increment or stable feature.

## 文档语言
- 本 skill 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
- App 内用户可见文案按产品本地化要求处理；持久化的产品、流程、架构、领域、AI runtime、报告、测试计划、需求和设计文档默认使用中文。

## 文档路径约定
- Prompt 契约写入 `docs/ai_runtime/prompt_contract.md`。
- LLM 输出 schema 写入 `docs/ai_runtime/llm_output_schema.md`。
- fallback 行为写入 `docs/ai_runtime/fallback_strategy.md`。
- AI 评测用例写入 `docs/ai_runtime/ai_eval_cases.md`。
- 对话状态机写入 `docs/ai_runtime/dialogue_state_machine.md`。
- 输入优先读取 `docs/product/increments/<increment-id>/spec.md` 或 `docs/product/base/spec.md`、`docs/domain/scene_model.md` 或相关领域模型，以及 `docs/architecture/api_contract.md`。

## Product Object Rules
- For new product work, start from `docs/product/increments/<increment-id>/spec.md` and cite the owning increment in prompt, schema, fallback, and eval updates.
- Do not create AI runtime behavior from a stage goal, roadmap item, or feature registry entry alone.
- Prompt contracts must reference the user-visible micro-flow, API/domain dependencies, and acceptance criteria they support.
- If the feature requires frontend rendering, output schema must be stable before UI implementation.

## Process
1. Define the AI task and what it must not decide.
2. Design JSON output fields before prose wording.
3. Add constraints for tone, level, and safety.
4. Include fallback behavior for invalid, low-confidence, or off-topic outputs.
5. Create eval cases for normal, edge, and adversarial inputs.
6. Require schema validation before frontend consumption.

## Red Flags
- Frontend is expected to parse long natural-language text.
- The prompt can change learning progress or billing state directly.
- No fallback exists for malformed JSON.
- Examples only cover ideal learner answers.
- Prompt behavior is added without an owning increment or approved spec.

## Verification
- Output schema is stable and renderable.
- Invalid outputs have deterministic fallback handling.
- Eval cases include failure and off-topic inputs.
- Prompt changes can be regression-tested.
- Prompt contract updates trace back to the increment or stable feature artifact that required them.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "This is obvious, so no spec is needed." | Obvious work is still easy to mis-scope; write the smallest useful artifact. |
| "We can validate it after implementation." | Validation criteria must exist before the implementation can be called done. |
| "This is only internal process." | Process assets shape future code quality and need the same review discipline. |
