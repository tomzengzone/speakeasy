---
name: document-governance
description: Use when documentation work spans path governance, content contracts, traceability, or multiple documentation authority concerns.
---

# Document Governance

## Overview

Route mixed documentation governance concerns without duplicating child methods or Governance Contract facts.

## When to Use

Use for mixed path/content/traceability requests, new document categories, source conflicts or documentation governance changes.

## When NOT to Use

Use the specific child skill for a single path, content-boundary or traceability question; do not use for ordinary document authoring.

## Contract

Governance facts are resolved from `GOVERNANCE_INDEX`. This router owns only classification, ordering and conflict escalation.

## Inputs

User request, affected Artifact/Gate IDs, relevant contract records, changed documents/skills/agents and child method findings.

## Outputs

Routing decision, ordered child tasks, conflict/precedence finding and ephemeral handoff unless a governed report is explicitly requested.

## Process

1. Classify single versus mixed scope and resolve relevant Artifact/Gate IDs.
2. Route canonical path/source questions to `document-path-governance`.
3. Route audience/required/prohibited content to `document-content-contract`.
4. Route owning-edge and derived projection checks to `document-traceability-check`.
5. Surface conflicts to the accountable owner; update only the owning authority.

## Red Flags

Copied path/owner/dependency tables; child schemas duplicated here; silent conflict resolution; persistent finding without contract scope; documentation review changing product facts.

## Verification

Every concern has one owning route; no second authority is created; conflicts and omitted scope are explicit; applicable validators pass.
