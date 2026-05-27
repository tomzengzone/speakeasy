CREATE TABLE auth_sessions (
  session_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id),
  access_token_hash VARCHAR(96) NOT NULL,
  refresh_token_hash VARCHAR(96) NOT NULL,
  status VARCHAR(40) NOT NULL,
  issued_at TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  refresh_expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  CONSTRAINT uq_auth_sessions_access_token UNIQUE (access_token_hash),
  CONSTRAINT uq_auth_sessions_refresh_token UNIQUE (refresh_token_hash)
);

CREATE INDEX idx_auth_sessions_user_status ON auth_sessions(user_id, status);
