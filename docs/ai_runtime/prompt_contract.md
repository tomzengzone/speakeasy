# Prompt Contract

## Purpose
Define how AI runtime prompts are structured and how responses are validated.

## Inputs
- user profile summary
- scenario context
- current action step
- dialogue history
- learner latest turn
- target expressions

## Output Requirement
The model must return valid JSON matching `docs/ai_runtime/llm_output_schema.md`.

## Prompt Rules
- Ask for one next action at a time.
- Keep coach feedback concise.
- Do not overload learner with multiple corrections.
- Prefer one main issue per learner turn.
- Do not advance the action step unless success criteria are met.
- Include fallback-safe fields.

## Prompt Test Rule
Every prompt contract must have positive and negative cases in `docs/ai_runtime/ai_eval_cases.md`.

