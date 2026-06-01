CREATE TABLE ai_media_assets (
  media_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  client_upload_id VARCHAR(160),
  purpose VARCHAR(40) NOT NULL,
  audio_ref VARCHAR(512) NOT NULL,
  provider_ref TEXT NOT NULL,
  audit_ref VARCHAR(80) NOT NULL,
  upload_url TEXT,
  object_ref TEXT,
  content_type VARCHAR(80) NOT NULL,
  byte_size BIGINT NOT NULL,
  duration_seconds INTEGER NOT NULL,
  checksum_sha256 VARCHAR(128),
  status VARCHAR(32) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE UNIQUE INDEX idx_ai_media_assets_user_client_upload
  ON ai_media_assets(user_id, client_upload_id);

CREATE INDEX idx_ai_media_assets_user_status
  ON ai_media_assets(user_id, status, expires_at);
