ALTER TABLE user_accounts ADD COLUMN security_epoch BIGINT NOT NULL DEFAULT 0;
ALTER TABLE user_accounts ADD COLUMN disabled_at TIMESTAMP;
ALTER TABLE user_accounts ADD COLUMN disabled_reason_code VARCHAR(80);
ALTER TABLE user_accounts ADD COLUMN status_changed_at TIMESTAMP;

ALTER TABLE auth_sessions ADD COLUMN refresh_token_family_id UUID;
ALTER TABLE auth_sessions ADD COLUMN device_id VARCHAR(160);
ALTER TABLE auth_sessions ADD COLUMN device_name VARCHAR(160);
ALTER TABLE auth_sessions ADD COLUMN platform VARCHAR(40);
ALTER TABLE auth_sessions ADD COLUMN app_version VARCHAR(40);
ALTER TABLE auth_sessions ADD COLUMN created_at TIMESTAMP;
ALTER TABLE auth_sessions ADD COLUMN last_active_at TIMESTAMP;
ALTER TABLE auth_sessions ADD COLUMN idle_expires_at TIMESTAMP;
ALTER TABLE auth_sessions ADD COLUMN absolute_expires_at TIMESTAMP;
ALTER TABLE auth_sessions ADD COLUMN revoked_reason_code VARCHAR(80);
ALTER TABLE auth_sessions ADD COLUMN security_epoch BIGINT;

UPDATE auth_sessions
SET refresh_token_family_id = session_id,
    device_name = 'Unknown device',
    platform = 'unknown',
    created_at = issued_at,
    last_active_at = issued_at,
    idle_expires_at = refresh_expires_at,
    absolute_expires_at = refresh_expires_at,
    security_epoch = 0;

ALTER TABLE auth_sessions ALTER COLUMN refresh_token_family_id SET NOT NULL;
ALTER TABLE auth_sessions ALTER COLUMN device_name SET NOT NULL;
ALTER TABLE auth_sessions ALTER COLUMN platform SET NOT NULL;
ALTER TABLE auth_sessions ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE auth_sessions ALTER COLUMN last_active_at SET NOT NULL;
ALTER TABLE auth_sessions ALTER COLUMN idle_expires_at SET NOT NULL;
ALTER TABLE auth_sessions ALTER COLUMN absolute_expires_at SET NOT NULL;
ALTER TABLE auth_sessions ALTER COLUMN security_epoch SET NOT NULL;

CREATE TABLE auth_refresh_token_families (
  family_id UUID PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES auth_sessions(session_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  status VARCHAR(40) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  revoked_reason_code VARCHAR(80),
  CONSTRAINT uq_auth_refresh_family_session UNIQUE (session_id)
);

INSERT INTO auth_refresh_token_families (family_id, session_id, user_id, status, created_at, revoked_at, revoked_reason_code)
SELECT refresh_token_family_id, session_id, user_id, status, created_at, revoked_at, revoked_reason_code
FROM auth_sessions;

CREATE TABLE auth_refresh_tokens (
  token_id UUID PRIMARY KEY,
  family_id UUID NOT NULL REFERENCES auth_refresh_token_families(family_id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES auth_sessions(session_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  parent_token_id UUID REFERENCES auth_refresh_tokens(token_id),
  token_hash VARCHAR(96) NOT NULL,
  status VARCHAR(40) NOT NULL,
  issued_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  CONSTRAINT uq_auth_refresh_tokens_hash UNIQUE (token_hash)
);

INSERT INTO auth_refresh_tokens (token_id, family_id, session_id, user_id, token_hash, status, issued_at, expires_at, revoked_at)
SELECT session_id, refresh_token_family_id, session_id, user_id, refresh_token_hash,
       CASE WHEN status = 'active' THEN 'active' ELSE 'revoked' END,
       issued_at, refresh_expires_at, revoked_at
FROM auth_sessions;

CREATE INDEX idx_auth_sessions_user_active ON auth_sessions(user_id, status, last_active_at);
CREATE INDEX idx_auth_sessions_absolute_status ON auth_sessions(absolute_expires_at, status);
CREATE INDEX idx_auth_refresh_tokens_family_status ON auth_refresh_tokens(family_id, status);
