ALTER TABLE ai_tts_cache_entries
  ADD COLUMN owner_hash VARCHAR(80);

CREATE INDEX idx_ai_tts_cache_entries_owner
  ON ai_tts_cache_entries(owner_hash, deleted_at);

CREATE TABLE ai_retention_jobs (
  job_id UUID PRIMARY KEY,
  idempotency_key VARCHAR(160) NOT NULL UNIQUE,
  scope VARCHAR(40) NOT NULL,
  user_ref VARCHAR(120),
  reason VARCHAR(160) NOT NULL,
  status VARCHAR(40) NOT NULL,
  media_deleted_count INTEGER NOT NULL DEFAULT 0,
  transcript_deleted_count INTEGER NOT NULL DEFAULT 0,
  tts_cache_deleted_count INTEGER NOT NULL DEFAULT 0,
  provider_payload_redacted_count INTEGER NOT NULL DEFAULT 0,
  redacted_evidence_ref VARCHAR(160) NOT NULL,
  failure_reason VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_ai_retention_jobs_scope_status
  ON ai_retention_jobs(scope, status, created_at);
