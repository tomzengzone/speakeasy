CREATE TABLE ai_tts_cache_entries (
  cache_id UUID PRIMARY KEY,
  cache_key VARCHAR(128) NOT NULL,
  normalized_text_hash VARCHAR(128) NOT NULL,
  model VARCHAR(120) NOT NULL,
  voice VARCHAR(120) NOT NULL,
  language VARCHAR(40) NOT NULL,
  audio_ref TEXT NOT NULL,
  status VARCHAR(32) NOT NULL,
  hit_count INTEGER NOT NULL DEFAULT 0,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL,
  last_hit_at TIMESTAMP,
  deleted_at TIMESTAMP,
  CONSTRAINT uq_ai_tts_cache_key UNIQUE (cache_key)
);

CREATE INDEX idx_ai_tts_cache_status_expiry
  ON ai_tts_cache_entries(status, expires_at);
