---
name: document-content-contract
description: Use when a project document needs a content boundary, required sections, prohibited content, audience definition, upstream/downstream contract, or completeness review. Do not use for deciding where the document should live or whether document chains are traceable across workflow stages.
---

# Document Content Contract

## Overview

Define what a document type must contain, must exclude, who reads it, which direct upstream it consumes, which downstream it drives, and how completeness is judged.

## When to Use

Use for required sections/templates, audience or content-boundary review, upstream/downstream contract, prohibited implementation details, or completeness of a document already placed correctly.

## When NOT to Use

Do not use for path/owner/source-of-truth (`document-path-governance`), cross-document chain audits (`document-traceability-check`), document generation, code review/test execution, or Capability semantic operations.

## Contract

- `docs/process/governance/index.json` is authoritative for Artifact owner, direct inputs, persistent/ephemeral outputs, lifecycle, and contributor scope; this skill defines content, not path.
- Method skills own their document behavior: `capability-registry-develop` owns registry schema/operations; generated artifacts own their own formats. Do not copy those schemas into this router.
- Persistent findings use declared `QUALITY_REPORT` scope; otherwise findings stay ephemeral.

## Inputs

Contract index/shards, target document and audience, workflow/DoD/quality standard, direct upstream artifacts, related downstream contracts, and the applicable document family (product, requirements, spec, AC, traceability, architecture/SWC, domain, API, AI, UX, test, report, release, skill, or agent).

## Outputs

Content contract with audience/purpose, required sections/fields, prohibited content, direct upstream and downstream references, completeness checks, and findings classified as blocker/important/suggestion. Do not decide the canonical path.

## 文档路径约定

Record content rules in this skill or the owning generator/skill; project-wide quality rules belong in `docs/process/skill_quality_standard.md`; persistent findings use `docs/reports/quality_report.md` only through contract scope.

## Core boundaries

- Vision: positioning, users, promises, principles; not states/API/UI/implementation.
- Registry: PM-approved Capability/Sub-capability facts; not Story/Slice, FR, Spec, AC, TC, delivery, or evidence. Registry schema/IDs/migration/ready gates belong to `capability-registry-develop`.
- Story/Slice: product semantics; not FR, Spec, AC, TC, SWC, or implementation evidence.
- Requirements: direct Story/Slice upstream; module boundary, first-level capability sections, three-column requirement items (`Requirement ID`, `Requirement Item`, `Requirement Description`), non-goals, open questions, and handoff notes; not API fields/UI layout/implementation process headings.
- Spec: direct approved FR upstream; flows/states/dependencies and downstream contract requests; not inline API/AI/UX/domain contracts.
- Acceptance: direct approved Spec upstream; observable pass/fail behavior; not full Story/Slice chain.
- Traceability: owning `Traceability Row ID -> Story/Slice -> FR -> Spec -> AC -> TC -> SWC/Code/Test Evidence -> Status`; it does not redefine requirements or acceptance.
- Baseline: frozen evidence snapshot, never living Product Base or future requirements.
- Stage/Increment: delivery scope and gates; never replacements for Capability identity or requirements behavior.
- Architecture/SWC/API/domain/AI/UX/report/release artifacts: keep their own contracts and do not duplicate another artifact’s schema/source of truth.

## Requirements-document minimum

For broad module requirements, require: module responsibility boundary (owns/excludes/inputs/outputs/neighbor handoffs), first-level capability sections with business names and stable order, the three-column item table, direct Story/Slice IDs, Capability only as ownership/boundary mapping, explicit non-goals/open questions/downstream handoff, and an independent traceability matrix. Do not use `Step 1`/`Step 2` or agent execution plans as requirements structure.

## Process

1. Identify document type, audience, lifecycle, and direct upstream from the contract.
2. List required and prohibited content before reviewing prose.
3. Check missing assumptions, states, non-goals, acceptance checks, and upstream/downstream references.
4. Check that content does not mix strategy, design, implementation, evidence, or release decisions owned elsewhere.
5. Classify findings, route path/traceability issues to their child skills, and update only the owning content contract when a reusable rule changes.
6. Run `python scripts/validate_agent_skills.py` and applicable language/contract gates after edits.

## Red Flags

Requirements containing API/database/UI fields, implementation `Step` headings, missing module boundaries or Story/Slice references, item tables with extra traceability fields, specs/ACs duplicating full chains, reports redefining requirements, prompts granting persistence authority, or SWC allocations becoming implementation task lists.

## Verification

Purpose/audience/required/prohibited sections are explicit; direct upstream/downstream are correct; broad requirements meet the minimum; acceptance stays observable; traceability owns the complete join; architecture coverage/omitted scope and SWC baseline/allocation rules are preserved when applicable; validator passes.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “Put every detail in one document.” | Completeness is not authority; separate lifecycles and owners prevent source-of-truth conflicts. |
| “Implementation details can be removed later.” | They bias requirements and acceptance before downstream contracts exist. |
