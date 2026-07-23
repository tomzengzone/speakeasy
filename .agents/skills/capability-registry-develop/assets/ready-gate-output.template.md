# Capability Registry Ready Gate 输出模板

```text
Assumptions:
- candidate object or mapping facts
- current registry rows and adjacent boundaries
- known downstream references

Gate Applicability:
- change path: candidate-object | confirmed-boundary-change | editorial | legacy-mapping-only | lifecycle-change
- Gate A: required | N/A with reason
- Gate B: required | N/A with reason

Gate A - Candidate Object Destination:
- candidate-object-routing.template.md output, when applicable
- destination finding
- existing target ID or proposed provisional ID
- parent Capability ID, when applicable
- next owning workflow
- missing information

PM Destination Confirmation:
- status: pending | confirmed | rejected | revision-required
- confirmed destination
- confirmed target object type
- confirmed existing target ID or proposed provisional ID
- confirmed parent Capability ID, when applicable
- confirmed change mode
- decision note

Gate B - Type-specific Granularity:
- granularity-evaluation.template.md output, when applicable
- evaluated rule set: Capability | Sub-capability | N/A
- selected peer/sibling IDs and selection basis
- comparison gap
- result: pass | fail | N/A
- required correction or Gate A return reason

Registry Target:
- change mode: editorial | boundary-change | add | split | merge | deprecate
- Capability IDs / Sub-capability IDs / V1 slugs
- intended persistent file: docs/product/feature_registry.md

Proposed Registry Sections / Rows:
- capability-section.template.md, capability-row.template.md, sub-capability-row.template.md, or legacy-mapping-row.template.md
- prohibited before applicable Gate A confirmation and Gate B pass, or before Gate A/Gate B are validly marked N/A under Gate applicability

Impact Inventory:
- affected registry rows
- Story/Slice classification references
- stage / increment scope guards
- Product Base / increment artifacts
- architecture / contract references
- omitted scope

Ready Gate Finding:
- result: pass | fail
- destination gate finding or valid N/A reason
- granularity gate finding or valid N/A reason
- structural gate finding
- Capability chapter heading / parent row / child row nesting finding
- semantic gate finding
- identity / boundary / adjacency / prefix finding
- legacy mapping / migration finding
- untouched historical adjacency baseline finding
- schema governance blocker for V2 split / merge / deprecate, when applicable
- missing information

PM Final Approval Required:
- yes for a Registry row proposal; destination confirmation does not approve the proposed row or persist product facts.
- status: pending | approved | rejected | revision-required
- approved target IDs and exact proposed rows
- decision note

Post-persistence Validation:
- python scripts/validate_capability_registry.py result
- asymmetric-adjacency warnings
- touched-scope decision for each relevant warning

Independent Check Required:
- every persisted semantic change sets `product_object_governance_change=true`, so `G-INDEPENDENT-CHECK` selects Product Object Governance Check before governance completion is claimed.
- handoff includes Gate applicability, Gate A finding, PM destination confirmation, Gate B finding, exact persisted diff, PM final approval, impact inventory and validator output.
- Gate analysis remains handoff/check evidence and must not be copied into docs/product/feature_registry.md.

Persistent Check Record:
- required for the matched Gate in `docs/reports/product_object_governance_check_report.md`, using the Artifact's explicit evidence location.
- retain target IDs, change mode, Gate A/N/A result, PM destination confirmation, Gate B/N/A result and comparison references, PM final row approval, validator result, touched-warning decision, checker result and residual risk.
- the report is audit evidence, not a second Registry source of truth; do not copy full Gate analysis into docs/product/feature_registry.md.
```

输出不得生成或改写 Story、FR、spec、AC、TC、stage、increment、architecture、implementation、test、priority 或 release artifact。
当前 schema 下，V2 `split`、`merge`、`deprecate` 的结果必须是 non-persistent proposal 和 `fail - schema governance required`，不能伪造 successor 持久化位置。
