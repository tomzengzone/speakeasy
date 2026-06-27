CREATE TABLE goal_autopilot_controls (
  control_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  control_status VARCHAR(40) NOT NULL,
  paused_at TIMESTAMP,
  pause_reason TEXT,
  resumed_at TIMESTAMP,
  quiet_hours_start VARCHAR(8),
  quiet_hours_end VARCHAR(8),
  timezone VARCHAR(80) NOT NULL,
  notification_consent BOOLEAN NOT NULL,
  intensity_override VARCHAR(40),
  missed_day_policy VARCHAR(40) NOT NULL,
  rule_version VARCHAR(80) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_goal_autopilot_controls_goal UNIQUE (goal_profile_id)
);

CREATE INDEX idx_goal_autopilot_controls_user_status
  ON goal_autopilot_controls (user_id, control_status, updated_at);

CREATE TABLE goal_autopilot_control_idempotency (
  replay_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  goal_revision INTEGER NOT NULL,
  operation VARCHAR(40) NOT NULL,
  idempotency_key VARCHAR(128) NOT NULL,
  request_hash VARCHAR(64) NOT NULL,
  response_json TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_goal_autopilot_control_idempotency
    UNIQUE (user_id, goal_profile_id, goal_revision, operation, idempotency_key)
);

CREATE INDEX idx_goal_autopilot_control_idempotency_goal
  ON goal_autopilot_control_idempotency (goal_profile_id, operation, created_at);
