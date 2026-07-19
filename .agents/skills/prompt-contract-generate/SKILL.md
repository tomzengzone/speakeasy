---
name: prompt-contract-generate
description: Use when approved AI product behavior needs prompts, structured output schema, examples, fallback behavior, or eval cases. Do not use when the behavior has no LLM-facing path.
---

# Prompt Contract Generate

## Overview

Constrain AI runtime behavior so prompts, schemas, fallbacks, and evaluations are safe and testable for application rendering.

## When to Use

Use when an approved scenario coach, correction, review, explanation, or other LLM-facing behavior changes, or prompt changes need regression coverage.

## When NOT to Use

Do not use for deterministic/static content or provider wiring when the AI contract is unchanged.

## Contract

- Method skill for `PROMPT_CONTRACT`, `LLM_OUTPUT_SCHEMA`, and `AI_EVAL_CASES`; `AI_FALLBACK` and `DIALOGUE_STATE_MACHINE` are related Artifacts. Resolve accountable ownership from `docs/process/governance/index.json`.
- Direct upstream is `INCREMENT_SPEC` (or approved Product Base spec for stable behavior); domain/API/UI needs are context.
- Registry data is classification context only, never AI behavior input; this skill cannot change Capability facts.
- Paths and write scopes are governed by `docs/process/governance/index.json`; default durable project documents to Chinese unless explicitly requested otherwise.

## Inputs

Approved spec, user-visible micro-flow, domain/API/UI dependencies, existing AI contracts, safety/fallback/cost constraints, and approved classification context. Missing or conflicting classification blocks and routes to Product Manager.

## Outputs

System/developer prompt contract, input/JSON output schemas, constraints, positive/negative examples, deterministic fallbacks, normal/edge/adversarial eval cases, and traceability to the owning Product Base/increment.

## 文档路径约定

Use only the governed AI artifacts: `docs/ai_runtime/prompt_contract.md`, `llm_output_schema.md`, `fallback_strategy.md`, `ai_eval_cases.md`, and `dialogue_state_machine.md` as applicable.

## Process

1. Define the AI task and decisions it must not make.
2. Design output fields/schema before prose wording.
3. Set tone, level, safety, and input constraints.
4. Define invalid, low-confidence, off-topic, and provider-failure fallbacks.
5. Add eval cases and require schema validation before frontend consumption.

## Red Flags

Free-form text parsed by UI, AI changing progress/billing truth, malformed JSON without fallback, ideal-only examples, missing approved upstream, or registry/stage text used as behavior input.

## Verification

Schema is stable/renderable; invalid outputs have deterministic handling; evals cover failure/off-topic cases; prompt changes are regression-testable; traceability and approved classification are preserved.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The model will usually follow the prompt.” | Schema validation and deterministic fallback are required behavior. |
| “The UI can clean it up.” | Renderers should consume contract fields, not infer truth from prose. |
