ALTER TABLE learning_evidences ADD COLUMN rule_name VARCHAR(120);
ALTER TABLE learning_evidences ADD COLUMN reason_code VARCHAR(120);
ALTER TABLE learning_evidences ADD COLUMN schema_version INTEGER;

CREATE TABLE training_content_mappings (
  mapping_id UUID PRIMARY KEY,
  scenario_id VARCHAR(80) NOT NULL REFERENCES scenarios(scenario_id),
  scenario_version_id UUID NOT NULL REFERENCES scenario_versions(scenario_version_id),
  level_code VARCHAR(20) NOT NULL,
  mapping_version VARCHAR(80) NOT NULL,
  action_chain_version VARCHAR(80) NOT NULL,
  step_key VARCHAR(80) NOT NULL,
  micro_action VARCHAR(80) NOT NULL,
  order_index INTEGER NOT NULL,
  target_expression_id UUID NOT NULL REFERENCES target_expressions(target_expression_id),
  prompt_text TEXT NOT NULL,
  review_status VARCHAR(40) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  UNIQUE (scenario_version_id, level_code, step_key, target_expression_id)
);

CREATE INDEX idx_training_content_mapping_lookup
  ON training_content_mappings (scenario_id, scenario_version_id, level_code, review_status, order_index);

CREATE TABLE training_sessions (
  training_session_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  scenario_id VARCHAR(80) NOT NULL REFERENCES scenarios(scenario_id),
  scenario_version_id UUID NOT NULL REFERENCES scenario_versions(scenario_version_id),
  level_code VARCHAR(20) NOT NULL,
  mapping_version VARCHAR(80) NOT NULL,
  action_chain_version VARCHAR(80) NOT NULL,
  status VARCHAR(40) NOT NULL,
  current_turn_index INTEGER NOT NULL,
  current_step_key VARCHAR(80) NOT NULL,
  current_micro_action VARCHAR(80) NOT NULL,
  hint_level VARCHAR(80) NOT NULL,
  failure_count INTEGER NOT NULL,
  success_count INTEGER NOT NULL,
  evidence_write_status VARCHAR(80) NOT NULL,
  sync_status VARCHAR(80) NOT NULL,
  last_reason_code VARCHAR(120),
  started_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP
);

CREATE INDEX idx_training_sessions_resume
  ON training_sessions (user_id, scenario_id, level_code, status, updated_at);

CREATE TABLE training_turns (
  training_turn_id UUID PRIMARY KEY,
  training_session_id UUID NOT NULL REFERENCES training_sessions(training_session_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  turn_index INTEGER NOT NULL,
  step_key VARCHAR(80) NOT NULL,
  micro_action VARCHAR(80) NOT NULL,
  transcript TEXT,
  audio_ref TEXT,
  selected_option_id VARCHAR(120),
  result VARCHAR(80) NOT NULL,
  idempotency_key VARCHAR(160) NOT NULL,
  input_hash VARCHAR(96) NOT NULL,
  provider_status VARCHAR(80) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  UNIQUE (training_session_id, idempotency_key)
);

CREATE INDEX idx_training_turns_session_order
  ON training_turns (training_session_id, turn_index);

CREATE TABLE training_planner_decisions (
  planner_decision_id UUID PRIMARY KEY,
  training_session_id UUID NOT NULL REFERENCES training_sessions(training_session_id) ON DELETE CASCADE,
  source_turn_id UUID REFERENCES training_turns(training_turn_id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  decision_type VARCHAR(80) NOT NULL,
  next_status VARCHAR(80) NOT NULL,
  next_step_key VARCHAR(80) NOT NULL,
  next_micro_action VARCHAR(80) NOT NULL,
  next_hint_level VARCHAR(80) NOT NULL,
  reason_code VARCHAR(120) NOT NULL,
  planner_version VARCHAR(80) NOT NULL,
  input_snapshot TEXT NOT NULL,
  output_snapshot TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_training_planner_decisions_session_order
  ON training_planner_decisions (training_session_id, created_at);

CREATE TABLE training_evidence_candidates (
  candidate_id UUID PRIMARY KEY,
  training_session_id UUID NOT NULL REFERENCES training_sessions(training_session_id) ON DELETE CASCADE,
  source_turn_id UUID REFERENCES training_turns(training_turn_id) ON DELETE SET NULL,
  learning_evidence_id UUID REFERENCES learning_evidences(evidence_id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  evidence_type VARCHAR(80) NOT NULL,
  target_expression_id UUID REFERENCES target_expressions(target_expression_id),
  confidence DOUBLE PRECISION NOT NULL,
  status VARCHAR(40) NOT NULL,
  rule_name VARCHAR(120) NOT NULL,
  reason_code VARCHAR(120) NOT NULL,
  schema_version INTEGER NOT NULL,
  rule_input TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_training_evidence_candidates_session_order
  ON training_evidence_candidates (training_session_id, created_at);

CREATE TABLE training_recaps (
  recap_id UUID PRIMARY KEY,
  training_session_id UUID NOT NULL UNIQUE REFERENCES training_sessions(training_session_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  summary TEXT NOT NULL,
  learned_items TEXT NOT NULL,
  weak_points TEXT NOT NULL,
  next_focus TEXT NOT NULL,
  accepted_evidence_ids TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE TABLE training_metric_events (
  metric_event_id UUID PRIMARY KEY,
  training_session_id UUID REFERENCES training_sessions(training_session_id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  event_type VARCHAR(120) NOT NULL,
  status VARCHAR(80) NOT NULL,
  provider_family VARCHAR(80),
  latency_bucket VARCHAR(80),
  fallback_reason VARCHAR(120),
  schema_version INTEGER NOT NULL,
  audit_ref VARCHAR(160) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_training_metric_events_lookup
  ON training_metric_events (event_type, status, created_at);
