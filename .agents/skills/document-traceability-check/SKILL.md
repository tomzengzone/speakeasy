---
name: document-traceability-check
description: Use when Story/VS/FR/Engineering Contract/Test Case lineage and derived coverage need an independent traceability audit. Do not use to author owning facts.
---

# Document Traceability Check

## Overview

Rebuild the canonical full-chain projection from owning direct edges and report gaps without creating or repairing facts in the projection.

## When to Use

Use for Story/VS/FR/TC changes, Engineering Contract fact changes, coverage audits, dangling IDs or traceability projection updates.

## When NOT to Use

Do not use to choose canonical paths, create requirements/tests/contracts, store execution status or approve product behavior.

## Contract

Method skill for `TRACEABILITY`. Resolve its governance facts by Artifact ID. The projection is derived-read-only; read direct edges only from Story Map, FR Catalog, Engineering Contracts and TC Catalog.

## Inputs

Current Story Map, FR Catalog, applicable Engineering Contract references, TC Catalog and stable selector/evidence links.

## Outputs

Rebuilt projection, completeness/uniqueness findings, dangling-edge findings and correction handoffs to the owning sources.

## Process

1. Read Story-to-Capability and nested VS-to-Story edges from Story Map.
2. Read VS-to-FR only from `source_vs_ids` in FR Catalog.
3. Read FR-to-affected-Contract only from the changed owning Engineering Contract.
4. Read FR-TC, Contract-TC and VS-TC direct edges only from their typed TC fields.
5. Join selectors/evidence, derive VS-TC-to-FR coverage, and compare with the read-only projection.
6. Fix discrepancies only in the owning source, then regenerate and validate traceability.

## Red Flags

Direct edge authored in traceability; VS-TC repeating FR IDs; multiple direct-upstream types in one TC; execution result copied into projection; Stage/Increment used as lineage; missing approved VS mandatory FR.

## Verification

All three branches resolve without ambiguity or dangling IDs; every approved implementing VS has FR/FR-TC/VS-TC coverage; changed Contracts have Contract-TC; projection contains no independent edge or runtime status.
