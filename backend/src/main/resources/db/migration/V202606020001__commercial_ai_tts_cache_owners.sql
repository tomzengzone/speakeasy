CREATE TABLE ai_tts_cache_owners (
  owner_ref_id UUID PRIMARY KEY,
  cache_id UUID NOT NULL,
  owner_hash VARCHAR(80) NOT NULL,
  first_attached_at TIMESTAMP NOT NULL,
  last_hit_at TIMESTAMP NOT NULL,
  CONSTRAINT fk_ai_tts_cache_owners_cache
    FOREIGN KEY (cache_id) REFERENCES ai_tts_cache_entries(cache_id),
  CONSTRAINT uq_ai_tts_cache_owner
    UNIQUE (cache_id, owner_hash)
);

CREATE INDEX idx_ai_tts_cache_owners_owner
  ON ai_tts_cache_owners(owner_hash, cache_id);
