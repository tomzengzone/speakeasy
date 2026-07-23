---
name: prompt-contract-generate
description: Use when approved Functional Requirements change LLM prompts, structured output, fallback behavior, or AI evaluation configuration. Do not use for deterministic behavior without an LLM path.
---

# Prompt Contract Generate

## Overview

Constrain AI runtime behavior so structured output, prompt, fallback and evaluation remain safe and testable.

## When to Use

Use for LLM-facing product behavior or changes to structured output, fallback, safety or eval configuration.

## When NOT to Use

Do not use for deterministic/static behavior, provider wiring with unchanged AI contract, or unapproved product behavior.

## Contract

Method skill for `PROMPT_CONTRACT`, `LLM_OUTPUT_SCHEMA` and `AI_EVAL_CASES`; related fallback/dialogue Artifacts retain their own ownership. Resolve governance facts by Artifact ID. Mandatory FR is the product upstream.

## Inputs

Applicable approved FR IDs, current AI/Domain/API/UX facts, safety/fallback/cost constraints and relevant AI Contract-TC IDs.

## Outputs

Prompt constraints, input/output schema, positive/negative examples, deterministic fallback, and AI evaluation fixtures/rubric/config keyed by TC ID.

## Process

1. Confirm applicable FR and actual AI contract fact change.
2. Define decisions the model must not make and design structured output before prompt prose.
3. Define invalid, low-confidence, off-topic and provider-failure fallbacks.
4. Put stable AI oracle/selector in a Contract-TC; keep AI Eval Cases limited to TC-linked fixtures, rubric/threshold and provider/model configuration.
5. Run resolved schema/eval validation.

## Red Flags

Free-form UI parsing; AI changing progress/billing truth; malformed output without deterministic fallback; eval file duplicating product behavior/oracle/result; missing Contract-TC.

## Verification

Output is schema-valid and renderable; invalid paths are deterministic; AI Contract-TC owns the oracle; eval fixtures/config link by TC ID without copying execution state.
