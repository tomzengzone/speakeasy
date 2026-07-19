---
name: document-governance
description: Use when a documentation request needs routing across path governance, content-contract governance, traceability checks, or multiple documentation governance concerns. Do not use for single-scope path decisions, single-document content boundary reviews, or one feature traceability audits when a more specific document governance skill applies.
---

# Document Governance

## Overview

Act as the routing and conflict-resolution layer for documentation governance. Keep path, content, traceability, and product-object authorities separate instead of duplicating their detailed rules.

## When to Use

Use when a request spans path/owner/source-of-truth, content boundaries, traceability, new document categories, governance-rule changes, or task decomposition across those concerns.

## When NOT to Use

Do not use for a single path decision (`document-path-governance`), one content-boundary review (`document-content-contract`), one chain audit (`document-traceability-check`), or ordinary document generation.

## Contract

- `docs/process/governance/index.json` is authoritative for Artifact owner, canonical path, lifecycle, I/O, contributor scope, and Gate routing.
- Method skills own their procedures: `document-path-governance`, `document-content-contract`, `document-traceability-check`, and `capability-registry-develop` owns Capability facts. This router never copies their schemas, IDs, migrations, or ready gates.
- Persistent governance findings use the declared `QUALITY_REPORT` contributor scope; otherwise decisions are ephemeral.

## Inputs

User governance request, `WORKFLOW`, `DEFINITION_OF_DONE`, `SKILL_QUALITY_STANDARD`, the contract index and selected shards, the three child governance skills, capability skill when relevant, and affected docs/skills/agents.

## Outputs

Routing decision, ordered child tasks, conflict/precedence decision, scope/applicability finding, and (only when requested) a scoped quality-report record. It does not create the governed document itself.

## 文档路径约定

Governance routing lives in this SKILL and `.codex/agents/documentation_governance.toml`; path/content/traceability rules remain in their child skills; durable findings use `docs/reports/quality_report.md` only when explicitly required under contract scope.

## Routing precedence

1. Classify the product/document object (Capability, Story/Slice, Stage, Increment, Base, Baseline, Change Request, or engineering artifact).
2. Route canonical path/owner/I-O/lifecycle to `document-path-governance`.
3. Route audience, required sections, prohibited content, and completeness to `document-content-contract`.
4. Route FR/Spec/AC/TC/contract/SWC/code/test/release joins to `document-traceability-check`.
5. Route Capability/Sub-capability semantic operations to Product Manager + `capability-registry-develop`; never infer a registry change from path/content review.

## Process

1. Restate the governance question and classify single vs mixed scope.
2. Resolve source-of-truth and applicability from the contract before selecting child skills.
3. For mixed scope, run path → content → traceability unless evidence shows a different dependency order.
4. Surface conflicts explicitly with authority, affected artifacts, and required correction; do not silently merge rules.
5. Update only the owning child skill/standard for a rule change, then update this router only for routing or precedence changes.
6. Run `python scripts/validate_agent_skills.py` and the applicable contract/language gates after governance changes.

## Red Flags

Duplicating child skill schemas, creating a document before path/content decisions, reviewing path without content/traceability impact, mixing feature and stage/baseline semantics, or writing a persistent finding without declared scope.

## Verification

Every request routes to the correct child skill(s); no method skill owns a duplicate authority; conflicts state precedence; direct-upstream and contract IDs are preserved; applicable validators pass; no product facts are changed by routing.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “Put every document rule here for convenience.” | A router that duplicates methods becomes a second conflicting authority. |
| “Path, content, and traceability are one review.” | They have different owners, evidence, and lifecycles and must remain separable. |
