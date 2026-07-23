---
name: implementation-report-generate
description: Use when completed implementation or governance work requires a durable report of scope, files, validation, risks, and follow-ups. Do not use before validation.
---

# Implementation Report Generate

## Overview

Create an auditable delivery record without copying product, engineering, test or governance authority.

## When to Use

Use only after changed files and validation results are known and the user or applicable contract requires a persistent implementation report.

## When NOT to Use

Do not use for exploratory/no-change work, before validation, or when an ephemeral task summary is sufficient.

## Contract

Method skill for `IMPLEMENTATION_REPORT`. Resolve path, lifecycle, contributor fields and validation from `GOVERNANCE_INDEX`.

## Inputs

Selected VS/FR/Contract/TC IDs when applicable, actual changed-file list and purpose, exact commands/results, skipped checks, risks and follow-ups.

## Outputs

One append-only report entry with scope, changed files, validation evidence, explicit unrun checks, risks, rollback context and next steps.

## Derived operational pointer

When a persistent report is required, the resolved `IMPLEMENTATION_REPORT` contract currently points to `docs/reports/implementation_report.md`; validate this pointer against the contract before writing.

## Process

1. Confirm a persistent report is required.
2. Link stable product/Contract/TC IDs without copying their contents.
3. Group files by purpose and record only commands/results actually run.
4. State skipped checks, residual risks, rollback context and follow-ups.
5. Append without rewriting prior entries; run resolved validation.

## Red Flags

Done claim without evidence; product/Contract/oracle text duplicated; planned command reported as run; hidden risk; Stage/Increment treated as product authority; report written when not required.

## Verification

Every meaningful changed area is represented; evidence matches actual execution and the checked commit where applicable; skipped work is explicit; no authority is redefined.
