# Structural Change Gates

Read this reference only for add, boundary change, split, merge, deprecate, or unresolved destination work.

## Gate A evidence

- `new-capability` and `new-sub-capability` require a provisional ID; a new Sub-capability also requires its parent ID.
- Existing-object changes require target type, target ID, and change mode.
- `story-slice`, `stage-increment`, and `technical-support-object` stop after handoff; `insufficient-information` returns the missing facts.
- Editorial and legacy-mapping-only work may record Gate A/Gate B as `N/A` because no business object is created or reclassified.
- A PM-confirmed existing-object boundary change may reuse its destination confirmation, but still runs the matching Gate B.

## Gate B evidence

- Capability comparison covers the two nearest top-level candidates by outcome, owned responsibility, exclusions, and adjacency.
- Sub-capability comparison covers parent fit and the nearest siblings by outcome, responsibility, exclusions, entry, and output. If fewer than two siblings exist, record the comparison gap.
- A failed Gate B returns correction or Gate A reconsideration; it never persists a row or changes the PM-confirmed destination.

## Identity and lifecycle

Use `CAP-<PREFIX>` and `CAP-<PREFIX>-<NN>`. Adjacency is bidirectional unless PM records a reason. Mappings express boundary/classification, not behavior.

Modes are `editorial`, `boundary-change`, `add`, `split`, `merge`, and `deprecate`. Non-editorial findings list affected rows, adjacency, downstream references, omitted scope, and identity transition. Published identities never disappear silently. If the schema cannot safely represent a successor or lifecycle, return a non-persistent `schema governance required` finding; do not encode it in legacy mapping or free prose.

Split, merge, and deprecate remain fail-closed until the canonical schema supports lifecycle and successor identity. Candidate successor analysis may be drafted, but not persisted.

## Completion check

Keep Gate A, PM destination confirmation, Gate B, draft row, PM final approval, deterministic validation, and any `G-INDEPENDENT-CHECK` result as distinct results. The registry stores only approved facts; detailed findings remain ephemeral unless a matched contract explicitly requires a durable record.
