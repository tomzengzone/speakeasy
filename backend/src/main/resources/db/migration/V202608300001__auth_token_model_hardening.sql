CREATE TABLE auth_access_tokens (
  token_id UUID PRIMARY KEY,
  token_hash VARCHAR(96) NOT NULL,
  session_id UUID NOT NULL REFERENCES auth_sessions(session_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  client_id VARCHAR(80) NOT NULL,
  audience VARCHAR(120) NOT NULL,
  scope VARCHAR(512) NOT NULL,
  status VARCHAR(40) NOT NULL,
  issued_at TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  CONSTRAINT uq_auth_access_tokens_hash UNIQUE (token_hash)
);

INSERT INTO auth_access_tokens (
  token_id, token_hash, session_id, user_id, client_id, audience, scope,
  status, issued_at, expires_at, revoked_at
)
SELECT session_id, access_token_hash, session_id, user_id,
       'speakeasy-mobile', 'speakeasy-api',
       'ai:use course:read learning:read learning:write session:manage user:read user:write',
       CASE WHEN status = 'active' THEN 'active' ELSE 'revoked' END,
       issued_at, expires_at, revoked_at
FROM auth_sessions;

ALTER TABLE auth_refresh_token_families
  ADD COLUMN client_id VARCHAR(80) NOT NULL DEFAULT 'speakeasy-mobile';
ALTER TABLE auth_refresh_token_families
  ADD COLUMN audience VARCHAR(120) NOT NULL DEFAULT 'speakeasy-api';
ALTER TABLE auth_refresh_token_families
  ADD COLUMN scope VARCHAR(512) NOT NULL
    DEFAULT 'ai:use course:read learning:read learning:write session:manage user:read user:write';

ALTER TABLE auth_refresh_token_families ALTER COLUMN client_id DROP DEFAULT;
ALTER TABLE auth_refresh_token_families ALTER COLUMN audience DROP DEFAULT;
ALTER TABLE auth_refresh_token_families ALTER COLUMN scope DROP DEFAULT;

CREATE INDEX idx_auth_access_tokens_session ON auth_access_tokens(session_id);
CREATE INDEX idx_auth_access_tokens_status_expires ON auth_access_tokens(status, expires_at);

ALTER TABLE auth_sessions DROP CONSTRAINT uq_auth_sessions_access_token;
ALTER TABLE auth_sessions DROP CONSTRAINT uq_auth_sessions_refresh_token;
ALTER TABLE auth_sessions DROP COLUMN access_token_hash;
ALTER TABLE auth_sessions DROP COLUMN refresh_token_hash;
ALTER TABLE auth_sessions DROP COLUMN issued_at;
ALTER TABLE auth_sessions DROP COLUMN expires_at;
ALTER TABLE auth_sessions DROP COLUMN refresh_expires_at;
