CREATE TABLE goal_mastery_transition_decisions (
  transition_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  goal_revision INTEGER NOT NULL,
  memory_item_state_id VARCHAR(160) NOT NULL,
  item_type VARCHAR(60) NOT NULL,
  item_ref VARCHAR(160) NOT NULL,
  previous_level VARCHAR(20) NOT NULL,
  proposed_level VARCHAR(20) NOT NULL,
  accepted_level VARCHAR(20) NOT NULL,
  direction VARCHAR(40) NOT NULL,
  evidence_refs_json TEXT NOT NULL,
  confidence DOUBLE PRECISION NOT NULL,
  reason_code VARCHAR(120) NOT NULL,
  rule_version VARCHAR(80) NOT NULL,
  input_snapshot_hash VARCHAR(80) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_goal_mastery_transition_input
    UNIQUE (user_id, goal_profile_id, goal_revision, memory_item_state_id, input_snapshot_hash, rule_version)
);

CREATE INDEX idx_goal_mastery_transition_user_created
  ON goal_mastery_transition_decisions (user_id, created_at);

CREATE INDEX idx_goal_mastery_transition_goal_item
  ON goal_mastery_transition_decisions (goal_profile_id, memory_item_state_id, created_at);
