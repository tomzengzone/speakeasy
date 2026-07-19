---
name: document-traceability-check
description: Use when project documentation needs a Story/Slice-to-evidence traceability audit across requirements, specs, AC, contracts, tests, reports, or release notes. Do not use for deciding document paths or defining document templates.
---

# Document Traceability Check

## Overview

Audit the complete product-to-evidence join while letting each local artifact retain only its direct upstream and necessary scope guards.

## When to Use

Use for feature/increment completeness, requirement-to-acceptance/test/evidence audits, broken/duplicate/expired references, pre-release readiness, workflow-stage status, or whole-app/platform/commercial architecture coverage.

## When NOT to Use

Do not use for path/owner decisions, content-boundary decisions, ordinary test execution, or generating missing documents. Route those to the owning skill.

## Contract

- Method skill for `PRODUCT_BASE_TRACEABILITY` and `INCREMENT_TRACEABILITY`; resolve accountable ownership and QA contributor fields from `docs/process/governance/index.json`.
- Direct-upstream contracts remain: FR←Story/Slice; Spec←approved FR (+ scope guard); AC←approved Spec; TC←AC/Spec; SWC allocation←Spec/AC/WP and implementation baseline; evidence←TC/report.
- `docs/process/governance/index.json` is authoritative for paths, lifecycle, owners, contributor scopes, and Gate evidence.

## Inputs

Workflow/DoD/change request, Story Map, Product Base or increment requirements/spec/acceptance/test cases/traceability, stage and increment scope, architecture/SWC/domain/API/AI/UX contracts, code/test/implementation/quality/release evidence, and applicable contract shards.

For whole-app, architecture, cross-layer, or implementation-impacting SWC review, read [architecture and SWC traceability](references/architecture-swc-traceability.md). Do not load it for product-only FR/AC/TC evidence checks.

## Outputs

Traceability result, missing/broken/duplicate/expired/conflicting link list, evidence-status gaps, next workflow step, and (only when requested) a scoped `QUALITY_REPORT` finding. Never create missing source artifacts or redefine their content.

## 文档路径约定

Use `docs/product/base/traceability.md` or `docs/product/increments/{increment_id}/traceability.md` as the owning matrix; cite reports/contracts/code/tests by canonical Artifact path. Use repository-relative paths and do not create alternate matrices.

## Canonical join

```text
User Story / Vertical Slice
 -> FR -> Spec -> AC -> TC
 -> Contract / SWC allocation when applicable
 -> WP -> PR / Code Evidence -> Test Evidence
 -> Product Base merge decision
```

The owning matrix must include at least: `Traceability Row ID`, Primary/Affected Capability IDs, Story/Slice IDs, Increment ID, WP ID, FR ID, Spec ID, AC ID, TC ID, PR/Code Evidence, Test Evidence, Product Base merge decision, Status, and Gap/Exception. `100% traceability` means every committed Slice joins to FR/Spec/AC/TC/evidence or an explicit exception; it does not mean code-line coverage.

## Increment Test Evidence gate

For every increment: each AC is in the test-case library or has an allowed exception; every TC cites the owning Traceability Row ID; automated/planned cases have script path and execution command; executed cases have result status and evidence report; traceability Test Evidence cites TC ID, script, command, result, and report (or explicit exception). QA may update only governed evidence/status/gap fields.

## Process

1. Define target feature/increment/architecture scope and find the canonical Story/Slice source; record legacy/exception sources explicitly.
2. Select source mode (Product Base, approved baseline consolidation, or increment) and verify Stage Scope IDs plus increment covered/excluded items when committed delivery applies.
3. Walk direct-upstream links and the owning matrix; check status consistency, source-of-truth duplication, and evidence freshness.
4. Run the increment AC→TC→script→command→result→report→Test Evidence review and the SWC/architecture gate when applicable.
5. Classify missing/not-applicable/duplicate/expired/conflicting links and give the next workflow step; do not invent coverage.
6. Run applicable validators, language, contract, SWC, and independent-check gates after governance changes.

## Red Flags

New or changed behavior without approved spec/AC, proposed requirements with accepted downstream implementation, tests used to redefine FR/AC, empty evidence without exception, repeated full chains in local artifacts, unallocated implementation paths, brownfield work without baseline/delta, partial architecture presented as whole-system, missing option comparison/omitted scope, or ADR treated as an unverified architecture source of truth.

## Verification

Every checked object has an approved upstream; the complete join is judged only in the owning matrix; local artifacts follow direct-upstream rules; gaps are explicit; stage/increment/FR/AC/evidence statuses agree; architecture coverage is complete or explicitly conditional/blocked; no missing document is silently generated.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “Tests passed, so traceability is complete.” | Tests prove assertions, not that requirements and evidence are joined. |
| “Small changes need no matrix.” | Small changes can alter contracts, behavior, or evidence ownership. |
