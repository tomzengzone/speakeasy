---
name: screen-spec-generate
description: Use when a Flutter or mobile UI screen needs behavior, state, interaction, and API dependencies specified before coding. Do not use for trivial copy-only edits.
---

# Screen Spec Generate

## Overview

Define user goals, components, states, interactions, and dependencies before implementing a mobile screen.

## When to Use

Use for a new screen, major screen state, new API/AI output consumption, or a UX review requiring a concrete contract.

## When NOT to Use

Do not use for a label/icon/spacing-only edit, non-user-facing behavior, or a fully specified design source with no behavior change.

## Contract

- Method skill for `SCREEN_SPEC`; `USER_FLOW` and `USABILITY_CHECKLIST` are related UX Artifacts. Resolve accountable ownership from `docs/process/governance/index.json`.
- Direct upstream is `INCREMENT_SPEC` plus `INCREMENT_ACCEPTANCE` (or Product Base equivalents); `API_CONTRACT` and `LLM_OUTPUT_SCHEMA` are conditional dependencies.
- Paths and write scopes are governed by `docs/process/governance/index.json`.

## Inputs

Approved spec/acceptance, API and AI output contracts, current navigation/state conventions, UX guidelines, and approved Capability classification only as boundary context. Missing upstream contracts block completion.

## Outputs

Screen goal/entry points, components and data, named states/transitions, success/loading/empty/error/offline/duplicate/retry behavior, API dependencies, test checklist, and traceability to the owning increment/Product Base.

## 文档路径约定

Write the governed UX artifacts only: `docs/ux/screen_spec.md`, `docs/ux/user_flow.md`, `docs/ux/usability_checklist.md`, or `docs/ux/copywriting_guideline.md` as applicable.

## Process

1. Start from the user’s next action and list stable components/data boundaries.
2. Define state names/transitions and visible feedback for every action.
3. Cover slow, offline, empty, duplicate, error, and retry cases.
4. Keep copy supportive and map states to widget/integration tests.

## Red Flags

No error/empty state, free-form AI text as truth, component-owned data outside its boundary, excess screens, or scope without approved upstream.

## Verification

A developer can implement without inventing states; every action has feedback; API failure/slow responses are handled; primary workflow acceptance is covered; upstream and classification context are traceable.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The design already shows the screen.” | Visuals do not define lifecycle, error, or data-boundary behavior. |
| “The API will be obvious.” | Screen state depends on explicit upstream contracts and stable errors. |
