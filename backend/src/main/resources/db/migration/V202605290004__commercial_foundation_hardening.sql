ALTER TABLE account_deletion_jobs
  ADD COLUMN idempotency_key VARCHAR(160);

CREATE UNIQUE INDEX idx_account_deletion_jobs_user_idempotency
  ON account_deletion_jobs(user_id, idempotency_key);
