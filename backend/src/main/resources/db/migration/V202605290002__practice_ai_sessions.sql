CREATE TABLE practice_sessions (
  practice_session_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  scenario_id VARCHAR(80) NOT NULL REFERENCES scenarios(scenario_id),
  level_code VARCHAR(20) NOT NULL,
  status VARCHAR(40) NOT NULL,
  current_turn_index INTEGER NOT NULL DEFAULT 0,
  started_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP
);

CREATE INDEX idx_practice_sessions_user_recovery
  ON practice_sessions(user_id, scenario_id, level_code, status, updated_at);

CREATE TABLE practice_turns (
  practice_turn_id UUID PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES practice_sessions(practice_session_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  turn_index INTEGER NOT NULL,
  role VARCHAR(40) NOT NULL,
  transcript TEXT,
  audio_ref VARCHAR(255),
  status VARCHAR(40) NOT NULL,
  idempotency_key VARCHAR(160) NOT NULL,
  provider_status VARCHAR(40) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_practice_turn_idempotency UNIQUE (session_id, idempotency_key),
  CONSTRAINT uq_practice_turn_index UNIQUE (session_id, turn_index)
);

CREATE INDEX idx_practice_turns_session_created ON practice_turns(session_id, created_at);

CREATE TABLE coach_feedbacks (
  feedback_id UUID PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES practice_sessions(practice_session_id) ON DELETE CASCADE,
  source_turn_id UUID NOT NULL REFERENCES practice_turns(practice_turn_id) ON DELETE CASCADE,
  feedback_type VARCHAR(60) NOT NULL,
  summary TEXT NOT NULL,
  main_issue_type VARCHAR(60),
  suggested_expression TEXT,
  next_prompt TEXT,
  score_kind VARCHAR(60),
  score_value DOUBLE PRECISION,
  score_confidence DOUBLE PRECISION,
  score_status VARCHAR(40) NOT NULL,
  validation_status VARCHAR(40) NOT NULL,
  provider_status VARCHAR(40) NOT NULL,
  recoverable_error_code VARCHAR(80),
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_coach_feedbacks_session_created ON coach_feedbacks(session_id, created_at);

CREATE TABLE session_summaries (
  summary_id UUID PRIMARY KEY,
  session_id UUID NOT NULL UNIQUE REFERENCES practice_sessions(practice_session_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  learned_items TEXT NOT NULL,
  weak_points TEXT NOT NULL,
  next_focus TEXT NOT NULL,
  evidence_candidate_payload TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_session_summaries_user_created ON session_summaries(user_id, created_at);
