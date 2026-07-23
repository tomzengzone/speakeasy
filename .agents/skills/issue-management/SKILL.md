---
name: issue-management
description: Use when creating, triaging, updating, or linking repository issues after product classification. Do not use issues as product, contract, test, or governance authority.
---

# Issue Management

## Overview

Use issues as optional coordination containers while linking, not duplicating, current owning facts.

## When to Use

Use for defect tracking, implementation slices, blockers, follow-ups, PR coordination or stable evidence links.

## When NOT to Use

Do not use to decide product scope/priority, approve Story/VS/FR, define Contract/TC, replace reports, or bypass a Gate.

## Contract

Method skill for `ISSUE_TRACKING`. Resolve governance facts by Artifact ID; Product Manager classification precedes issue authoring.

## Inputs

Classification, selected approved VS, mandatory FR, affected Contract IDs, typed TC IDs, scoped delivery intent, owner, dependencies and stable evidence links.

## Outputs

Concise issue title/body, labels/status suggestions, linked Artifact IDs, blocker/follow-up wording and PR relationship text.

## Process

1. Confirm classification and selected product IDs.
2. Link the minimum coding context: VS, FR, affected Contracts, FR/Contract/VS TCs, adjacent code/tests and validation commands.
3. State scope, non-goals, owner, risks and evidence without copying owning text.
4. Use `Refs` for planning/partial/blocked work; use closing semantics only after Definition of Done.
5. Reconcile conflicts by correcting the issue, never the authority from issue text.

## Red Flags

Issue-only product facts; copied oracle or Contract schema; Stage/Increment treated as behavior source; completion claim without CI evidence linked to the checked commit; issue scope silently expanding approved behavior.

## Verification

Every linked ID resolves; content remains coordination-only; no owning facts are duplicated; closure matches Definition of Done evidence.
