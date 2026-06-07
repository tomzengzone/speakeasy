CREATE TABLE goal_autopilot_metric_events (
  metric_event_id UUID PRIMARY KEY,
  user_hash VARCHAR(80) NOT NULL,
  event_type VARCHAR(120) NOT NULL,
  status VARCHAR(80) NOT NULL,
  reason_code VARCHAR(120) NOT NULL,
  source_path VARCHAR(120) NOT NULL,
  target_ref VARCHAR(160) NOT NULL,
  audit_ref VARCHAR(160) NOT NULL,
  schema_version INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_goal_autopilot_metric_events_lookup
  ON goal_autopilot_metric_events (event_type, status, reason_code, created_at);

CREATE INDEX idx_goal_autopilot_metric_events_user
  ON goal_autopilot_metric_events (user_hash, created_at);
