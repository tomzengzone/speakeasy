CREATE TABLE goal_notification_outbox_records (
  outbox_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  goal_revision INTEGER NOT NULL,
  plan_item_id UUID NOT NULL REFERENCES goal_plan_items(plan_item_id) ON DELETE CASCADE,
  reminder_slot VARCHAR(80) NOT NULL,
  lifecycle_status VARCHAR(40) NOT NULL,
  dedupe_key VARCHAR(320) NOT NULL,
  input_snapshot_hash VARCHAR(80) NOT NULL,
  payload_hash VARCHAR(80) NOT NULL,
  reason_code VARCHAR(120) NOT NULL,
  processing_status VARCHAR(40) NOT NULL,
  next_attempt_at TIMESTAMP,
  failure_reason VARCHAR(160),
  retry_count INTEGER NOT NULL DEFAULT 0,
  sent_at TIMESTAMP,
  rule_version VARCHAR(80) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_goal_notification_outbox_dedupe UNIQUE (dedupe_key)
);

CREATE INDEX idx_goal_notification_outbox_user_updated
  ON goal_notification_outbox_records (user_id, updated_at);

CREATE INDEX idx_goal_notification_outbox_lifecycle
  ON goal_notification_outbox_records (lifecycle_status, processing_status, next_attempt_at);

CREATE TABLE goal_planner_replay_audits (
  replay_audit_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  decision_family VARCHAR(80) NOT NULL,
  source_entity_ref VARCHAR(180) NOT NULL,
  input_snapshot_hash VARCHAR(80) NOT NULL,
  output_snapshot_hash VARCHAR(80) NOT NULL,
  expected_decision VARCHAR(80) NOT NULL,
  reason_code VARCHAR(120) NOT NULL,
  rule_version VARCHAR(80) NOT NULL,
  replay_hash VARCHAR(80) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_goal_planner_replay_user_family
  ON goal_planner_replay_audits (user_id, decision_family, created_at);
