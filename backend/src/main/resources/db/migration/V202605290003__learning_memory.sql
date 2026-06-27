CREATE TABLE practice_queue_items (
  queue_item_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  source_type VARCHAR(60) NOT NULL,
  target_expression_id UUID NOT NULL REFERENCES target_expressions(target_expression_id),
  task_type VARCHAR(60) NOT NULL,
  priority INTEGER NOT NULL,
  status VARCHAR(40) NOT NULL,
  due_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_practice_queue_items_user_status_priority
  ON practice_queue_items(user_id, status, priority, due_at);

CREATE TABLE expression_practice_attempts (
  attempt_id UUID PRIMARY KEY,
  queue_item_id UUID NOT NULL REFERENCES practice_queue_items(queue_item_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  task_type VARCHAR(60) NOT NULL,
  answer_text TEXT,
  transcript_ref TEXT,
  result VARCHAR(40) NOT NULL,
  best_score DOUBLE PRECISION,
  completed_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_expression_practice_attempts_user_completed
  ON expression_practice_attempts(user_id, completed_at);

CREATE TABLE favorite_expressions (
  favorite_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  target_expression_id UUID NOT NULL REFERENCES target_expressions(target_expression_id),
  expression_text TEXT NOT NULL,
  normalized_text TEXT NOT NULL,
  source_type VARCHAR(60),
  source_id VARCHAR(160),
  status VARCHAR(40) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_favorite_expressions_user_target UNIQUE (user_id, target_expression_id)
);

CREATE INDEX idx_favorite_expressions_user_status ON favorite_expressions(user_id, status);

CREATE TABLE learning_evidences (
  evidence_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  source_type VARCHAR(60) NOT NULL,
  source_id VARCHAR(160) NOT NULL,
  evidence_type VARCHAR(60) NOT NULL,
  target_expression_id UUID REFERENCES target_expressions(target_expression_id),
  confidence DOUBLE PRECISION,
  accepted_status VARCHAR(40) NOT NULL,
  rejection_reason VARCHAR(160),
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_learning_evidences_user_status_created
  ON learning_evidences(user_id, accepted_status, created_at);

CREATE TABLE mastery_records (
  mastery_record_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  target_expression_id UUID NOT NULL REFERENCES target_expressions(target_expression_id),
  mastery_status VARCHAR(40) NOT NULL,
  score DOUBLE PRECISION,
  last_evidence_id UUID REFERENCES learning_evidences(evidence_id) ON DELETE SET NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_mastery_records_user_target UNIQUE (user_id, target_expression_id)
);

CREATE TABLE review_items (
  review_item_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  target_expression_id UUID NOT NULL REFERENCES target_expressions(target_expression_id),
  source_evidence_id UUID REFERENCES learning_evidences(evidence_id) ON DELETE SET NULL,
  prompt_type VARCHAR(60) NOT NULL,
  due_at TIMESTAMP NOT NULL,
  interval_days INTEGER NOT NULL,
  status VARCHAR(40) NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_review_items_user_status_due ON review_items(user_id, status, due_at);

CREATE TABLE saved_expressions (
  saved_expression_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  target_expression_id UUID REFERENCES target_expressions(target_expression_id),
  expression_text TEXT NOT NULL,
  meaning_cn TEXT,
  example TEXT,
  source_evidence_id UUID REFERENCES learning_evidences(evidence_id) ON DELETE SET NULL,
  status VARCHAR(40) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_saved_expressions_user_status ON saved_expressions(user_id, status);

CREATE TABLE learning_history_entries (
  history_entry_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  source_session_id UUID REFERENCES practice_sessions(practice_session_id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  status VARCHAR(40) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_learning_history_entries_user_status_created
  ON learning_history_entries(user_id, status, created_at);
