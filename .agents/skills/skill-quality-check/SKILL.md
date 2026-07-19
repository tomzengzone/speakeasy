---
name: skill-quality-check
description: Use when project-local skills are created or changed and need validation against the project quality standard. Do not use for validating application features or source code behavior.
---

# Skill Quality Check

## Overview

Validate project-local skill structure, routing clarity, verification quality, source-of-truth boundaries, and maintainability.

## When to Use

Use when a `.agents/skills/<skill>/SKILL.md` or bundled resource, the skill standard, or the skill validator changes, or before a workflow release.

## When NOT to Use

Do not use for application behavior/code quality, issue triage, or archived external skill layouts.

## Contract

- Method skill for `SKILL_DEFINITION`, `SKILL_RESOURCE`, and `SKILL_QUALITY_STANDARD`; resolve accountable ownership from `docs/process/governance/index.json`.
- Run `scripts/validate_agent_skills.py`; report findings with exact skill paths. Persistent quality findings use the declared `QUALITY_REPORT` contributor scope; otherwise findings are ephemeral.
- Paths, owner, lifecycle, and write scope are governed by `docs/process/governance/index.json`.

## Inputs

Changed `SKILL.md` and directly linked bundled resources, `docs/process/skill_quality_standard.md`, validator output, and (for broad governance/architecture/product/contract skills) source inventory, scope mode, coverage/traceability gate, and omitted-scope evidence.

## Outputs

Pass/block findings with file paths, required corrections for missing sections or weak triggers, executable verification evidence, and optional future validator-hardening suggestions. Do not modify the skill under review as part of the check.

## 文档路径约定

Inspect `.agents/skills/<skill>/SKILL.md` and only its directly linked bundled resources; use `docs/process/skill_quality_standard.md` as the standard and `scripts/validate_agent_skills.py` as the structural gate.

## Process

1. Run the lightweight validator first.
2. Read the changed SKILL and only the bundled resources selected by its stated conditions.
3. Check trigger/non-trigger boundaries, non-overlap, verification commands, direct resource links, and source-of-truth boundaries.
4. For broad-scope skills, reject partial-context conclusions and missing coverage/omitted-scope handling.
5. Report blockers before style suggestions; do not silently rewrite weak outputs.

## Red Flags

Always-use triggers, generic/empty non-use boundaries, manual-only verification, parallel maintenance files, unlinked or unconditional references, recommendations without constraints/trade-offs, or no rule to reject/supersede weak output.

## Verification

Validator exits 0; changed skills have concrete triggers and red flags; no deprecated `codex/skills`; broad skills define coverage gates; findings distinguish blockers from suggestions and cite exact paths.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The skill is short, so review is unnecessary.” | Trigger, contract, and verification gaps can still change routing behavior. |
| “Manual review is enough.” | The structural validator is required evidence before semantic review. |
