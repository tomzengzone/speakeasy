---
name: code-review-quality
description: Use when code, docs, or workflow changes need a quality review for regressions, missing tests, maintainability, and release risk. Do not use it as a substitute for running tests.
---

# Code Review Quality

## Overview

Provide a review gate that finds concrete defects and quality risks before a change is accepted.

## When to Use

Use when an increment, refactor, generated change, release, or explicit review request needs a risk gate.

## When NOT to Use

Do not use for formatting-only work, unimplemented changes, or requirement clarification.

## Contract

- Method skill for review evidence; persistent `QUALITY_REPORT` ownership, contributor records, routes, and mutable fields resolve from `docs/process/governance/index.json`.
- Inputs are changed files/diffs, applicable acceptance and traceability artifacts, architecture/API contracts, test results, and `IMPLEMENTATION_REPORT`.

## Inputs

Changed files/diffs, applicable acceptance and traceability artifacts, architecture/API contracts, test results, and `IMPLEMENTATION_REPORT`.

## Outputs

Severity-ordered findings with exact file references, open questions, residual risk, test gaps, and an approve/block summary. Persistent `QUALITY_REPORT` records use the governed scoped fields.

## 文档路径约定

Use the governance contract for report path, owner, contributor scope, and lifecycle; do not silently create alternate reports.

## Process

1. Inspect behavior changes before style; compare implementation with acceptance and contracts.
2. Check errors, compatibility, ownership/lifecycle, data boundaries, and tests at the right layer.
3. Check abstraction size, generated artifacts, DTO/client-server alignment, external evidence, and release risk.
4. Report findings ordered by severity with exact file references, open questions, test gaps, and an approve/block summary. Never silently edit product requirements or contracts; route gaps as actions.

## Red Flags

Missing contract/migration review, mock-only tests, hidden state/broad fallbacks, unverifiable AI behavior, premature abstractions, UI recomputation of backend-owned truth, and provider/release claims without deterministic or external evidence.

## Verification

Each finding has severity, location, impact, and a plausible fix; defects are separated from test gaps; the result drives a fix list. Flag missing contract/migration review, mock-only tests, hidden state/broad fallbacks, unverifiable AI behavior, premature abstractions, UI recomputation of backend-owned truth, and provider/release claims without deterministic or external evidence.

## Quality checklist

Prefer a small verifiable vertical slice, explicit ownership/lifecycle/invariants, typed contract-aligned errors, behavior-level tests, and the simplest readable implementation that proves the behavior.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “Tests are green, so review is unnecessary.” | Review checks contracts, ownership, maintainability, and residual risk beyond test execution. |
| “This is only style.” | Cross-module and generated changes can hide behavior or release risk. |
