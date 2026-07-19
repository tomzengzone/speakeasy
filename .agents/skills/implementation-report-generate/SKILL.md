---
name: implementation-report-generate
description: Use when a development increment finishes and docs/reports/implementation_report.md must record scope, files, tests, risks, and follow-ups. Do not use before implementation or validation results are known.
---

# Implementation Report Generate

## Overview

Create an auditable completion record linking changed work to requirements, evidence, and residual risk.

## When to Use

Use after product, workflow, or governance assets change and validation results are known, or when the user asks for an implementation summary.

## When NOT to Use

Do not use when no files changed, work is exploratory, or a release note is the requested artifact.

## Contract

- Method skill for `IMPLEMENTATION_REPORT`; resolve accountable ownership and contributor record fields from `docs/process/governance/index.json`.
- The canonical path, append schema, lifecycle, and write scope are in `docs/process/governance/index.json`.

## Inputs

Git status/diff and changed-file purpose, increment or governing process reference, requirements/spec/acceptance, commands and actual results, skipped tests, risks, and follow-ups.

## Outputs

An append-only implementation report entry containing summary, requirement/process mapping, files by purpose, validation evidence, explicit unrun tests, risks, and next steps. Never redefine requirements, specs, acceptance, or stage scope.

## 文档路径约定

Write `docs/reports/implementation_report.md` through the governed append-record contract; link test/quality reports rather than copying them.

## Process

1. Identify the addressed increment, request, or process artifact.
2. Group changed files by purpose, record exact validation commands/status, and state skipped tests.
3. Record residual risks and follow-ups; append rather than rewriting history except to correct the current entry.
4. For product work, preserve approved Capability context; missing upstream/acceptance is a governance gap, not completion.

## Red Flags

Done claims without evidence, omitted generated/process files, hidden risks, premature reporting, or product completion without an owning increment/spec/acceptance.

## Verification

Every meaningful changed area is represented; commands match actual runs; skipped tests are explicit; the entry supports audit/rollback and maps to the governing artifact.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The diff is self-explanatory.” | A durable report preserves evidence and rollback context. |
| “We can add tests later.” | The report must distinguish verified, skipped, and follow-up work now. |
