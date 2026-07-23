# Broad-Module Requirements

Read this reference only when a target spans a broad product module or multiple first-level subfunctions.

## Decomposition

1. State the module responsibility boundary: owned behavior, exclusions, preconditions/inputs, product outcome, and neighboring handoffs.
2. Identify stable, non-overlapping first-level subfunctions using business names and a stable order.
3. For each subfunction, define its observable product responsibility, exclusions, entry/precondition, resulting outcome, and handoff.
4. Place every atomic requirement item in exactly one subfunction; split mixed behaviors.

## Output contract

The final requirements document presents results, not the internal decomposition process. Do not use `Step 1` or `Step 2` headings.

The main item table contains exactly `Requirement ID`, `Requirement Item`, and `Requirement Description` (or the existing localized labels). Do not add traceability, Spec, AC, API, database, UI, or test columns. Keep the complete Story/Slice→FR→Spec→AC→TC→evidence join in the owning traceability matrix.

Every increment requirement cites its direct Story/Slice source or an approved exception. Capability, Stage, and Increment remain boundary and delivery guards rather than behavior sources.
