CREATE TABLE goal_recovery_plan_decisions (
  decision_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  goal_revision INTEGER NOT NULL,
  daily_plan_id UUID NOT NULL REFERENCES goal_daily_plans(daily_plan_id) ON DELETE CASCADE,
  source_event VARCHAR(80) NOT NULL,
  recovery_mode VARCHAR(40) NOT NULL,
  affected_plan_item_refs_json TEXT NOT NULL,
  input_snapshot_hash VARCHAR(80) NOT NULL,
  reason_code VARCHAR(120) NOT NULL,
  rule_version VARCHAR(80) NOT NULL,
  idempotency_key VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_goal_recovery_plan_decision_idempotency
    UNIQUE (user_id, goal_profile_id, goal_revision, source_event, rule_version, idempotency_key)
);

CREATE INDEX idx_goal_recovery_plan_decisions_user_created
  ON goal_recovery_plan_decisions (user_id, created_at);
