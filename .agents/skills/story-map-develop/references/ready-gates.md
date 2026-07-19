# Story and Slice Ready Gates

Read this reference only for row creation, semantic rewrite, split/merge, or approval-readiness work.

## Story and Slice semantics

- One Story expresses one user-value scenario. Its description makes actor, context, product object, goal/action, and visible outcome understandable. Split independent journeys or primary outcomes.
- One Child Slice is the smallest user-perceivable delivery loop under a Story. State its trigger, action, business object, decision/state effect, visible result, and any exception that changes the decision.
- Split siblings only for distinct triggers, outcomes, state effects, business decisions, or independently verifiable value—not CRUD labels or generic loading/save/retry scaffolding.

## Information and authority

Every new or rewritten Slice carries at least two concrete product facts not derivable from a Capability name, such as object, choice, state meaning, scope difference, handoff, exception, or data boundary. If only generic verbs remain after product nouns are removed, return an ambiguity finding.

Before persistence, declare scope mode, target rows, source inventory, adjacency, omitted scope, and non-goals. Classify each row as `draft proposal`, `PM-provided behavior`, `existing canonical fact`, or `proposed ambiguity`. Affected Capability IDs must be approved adjacent impacts or `none`; registry rows provide boundaries, never missing behavior.

## Ready decision

- Structure: unique `US-<Prefix>-<NNN>` / `VS-<Prefix>-<NNN>`, five columns, correct Capability section, one parent, and no downstream fields.
- Narrative: Story scenario/object/action/outcome; Slice trigger/object/decision/result; siblings have independent value.
- Authority: source coverage, omitted scope, non-goals, unresolved decisions, and Capability mapping are explicit; `draft` is not approval.
- Validation: run `python .agents/skills/story-map-develop/scripts/validate_story_map.py --capability <CAP-ID>` for touched scope, then applicable contract, language, and checker gates.
