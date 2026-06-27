CREATE TABLE goal_autopilot_goal_idempotency (
  replay_id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE,
  idempotency_key VARCHAR(128) NOT NULL,
  request_hash VARCHAR(64) NOT NULL,
  goal_profile_id UUID NOT NULL REFERENCES goal_profiles(goal_profile_id) ON DELETE CASCADE,
  goal_revision INTEGER NOT NULL,
  response_json TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_goal_autopilot_goal_idempotency UNIQUE (user_id, idempotency_key)
);

CREATE INDEX idx_goal_autopilot_goal_idempotency_user_created
  ON goal_autopilot_goal_idempotency (user_id, created_at);

WITH ranked_goal_profiles AS (
  SELECT
    goal_profile_id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY
        CASE WHEN status IN ('active', 'paused') THEN 0 ELSE 1 END,
        updated_at DESC,
        created_at DESC,
        goal_profile_id
    ) AS keep_rank
  FROM goal_profiles
)
DELETE FROM goal_profiles
WHERE goal_profile_id IN (
  SELECT goal_profile_id FROM ranked_goal_profiles WHERE keep_rank > 1
);

ALTER TABLE goal_profiles
  ADD CONSTRAINT uq_goal_profiles_user UNIQUE (user_id);
