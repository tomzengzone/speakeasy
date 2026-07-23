---
name: document-content-contract
description: Use when a governed document needs audience, required sections, prohibited content, upstream usage, or completeness reviewed.
---

# Document Content Contract

## Overview

Define or review what a document communicates without owning its path, owner, lifecycle, dependency graph or Gate routing.

## When to Use

Use for audience, required sections, prohibited content, semantic completeness and downstream consumption boundaries.

## When NOT to Use

Do not use for path/source decisions, full-chain traceability, ordinary document generation, code review or product classification.

## Contract

Resolve governance facts by Artifact ID. This method owns only content-boundary analysis; direct inputs are consumed, not redefined.

## Inputs

Target Artifact ID and content, intended audience/use, relevant contract record, owning method and known upstream facts.

## Outputs

Required/prohibited content findings, audience/consumer contract, completeness gaps and handoff to the owning writer.

## Process

1. Resolve target Artifact and read only applicable upstream facts.
2. Identify reader decisions the document must enable.
3. Separate owning facts from context, derived projection and one-time evidence.
4. Reject duplicated product/governance facts and invented behavior.
5. Report pass/block findings and validate after owner correction.

## Red Flags

Template convenience becoming authority; copied path/owner/dependency/Gate data; downstream facts used to repair upstream gaps; traceability joins stored in non-owning documents.

## Verification

Required reader decisions are supported; prohibited content is absent; direct inputs are used consistently; the document does not create a second source.
