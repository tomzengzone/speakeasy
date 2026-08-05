UPDATE user_profiles
SET target_level = CASE target_level
  WHEN 'L1' THEN 'A2'
  WHEN 'L2' THEN 'B1'
  WHEN 'L3' THEN 'B2'
  ELSE target_level END
WHERE target_level IN ('L1', 'L2', 'L3');

UPDATE onboarding_assessments
SET output_level = CASE output_level
  WHEN 'L1' THEN 'A2'
  WHEN 'L2' THEN 'B1'
  WHEN 'L3' THEN 'B2'
  ELSE output_level END
WHERE output_level IN ('L1', 'L2', 'L3');

UPDATE learning_routes
SET target_level = CASE target_level
  WHEN 'L1' THEN 'A2'
  WHEN 'L2' THEN 'B1'
  WHEN 'L3' THEN 'B2'
  ELSE target_level END
WHERE target_level IN ('L1', 'L2', 'L3');

UPDATE user_scenario_states
SET target_level = CASE target_level
  WHEN 'L1' THEN 'A2'
  WHEN 'L2' THEN 'B1'
  WHEN 'L3' THEN 'B2'
  ELSE target_level END
WHERE target_level IN ('L1', 'L2', 'L3');

UPDATE scenario_levels
SET level_code = CASE level_code
      WHEN 'L1' THEN 'A2'
      WHEN 'L2' THEN 'B1'
      WHEN 'L3' THEN 'B2'
      ELSE level_code END,
    target_level = CASE target_level
      WHEN 'L1' THEN 'A2'
      WHEN 'L2' THEN 'B1'
      WHEN 'L3' THEN 'B2'
      ELSE target_level END
WHERE level_code IN ('L1', 'L2', 'L3')
   OR target_level IN ('L1', 'L2', 'L3');

UPDATE target_expressions
SET level_code = CASE level_code
  WHEN 'L1' THEN 'A2'
  WHEN 'L2' THEN 'B1'
  WHEN 'L3' THEN 'B2'
  ELSE level_code END
WHERE level_code IN ('L1', 'L2', 'L3');

UPDATE practice_sessions
SET level_code = CASE level_code
  WHEN 'L1' THEN 'A2'
  WHEN 'L2' THEN 'B1'
  WHEN 'L3' THEN 'B2'
  ELSE level_code END
WHERE level_code IN ('L1', 'L2', 'L3');

UPDATE training_content_mappings
SET level_code = CASE level_code
  WHEN 'L1' THEN 'A2'
  WHEN 'L2' THEN 'B1'
  WHEN 'L3' THEN 'B2'
  ELSE level_code END
WHERE level_code IN ('L1', 'L2', 'L3');

UPDATE training_sessions
SET level_code = CASE level_code
  WHEN 'L1' THEN 'A2'
  WHEN 'L2' THEN 'B1'
  WHEN 'L3' THEN 'B2'
  ELSE level_code END
WHERE level_code IN ('L1', 'L2', 'L3');

ALTER TABLE user_profiles
  ADD CONSTRAINT ck_user_profiles_target_level_cefr
  CHECK (target_level IS NULL OR target_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'));
ALTER TABLE onboarding_assessments
  ADD CONSTRAINT ck_onboarding_assessments_output_level_cefr
  CHECK (output_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'));
ALTER TABLE learning_routes
  ADD CONSTRAINT ck_learning_routes_target_level_cefr
  CHECK (target_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'));
ALTER TABLE user_scenario_states
  ADD CONSTRAINT ck_user_scenario_states_target_level_cefr
  CHECK (target_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'));
ALTER TABLE scenario_levels
  ADD CONSTRAINT ck_scenario_levels_level_code_cefr
  CHECK (level_code IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'));
ALTER TABLE scenario_levels
  ADD CONSTRAINT ck_scenario_levels_target_level_cefr
  CHECK (target_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'));
ALTER TABLE scenario_levels
  ADD CONSTRAINT ck_scenario_levels_fields_equal
  CHECK (level_code = target_level);
ALTER TABLE target_expressions
  ADD CONSTRAINT ck_target_expressions_level_code_cefr
  CHECK (level_code IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'));
ALTER TABLE practice_sessions
  ADD CONSTRAINT ck_practice_sessions_level_code_cefr
  CHECK (level_code IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'));
ALTER TABLE training_content_mappings
  ADD CONSTRAINT ck_training_content_mappings_level_code_cefr
  CHECK (level_code IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'));
ALTER TABLE training_sessions
  ADD CONSTRAINT ck_training_sessions_level_code_cefr
  CHECK (level_code IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2'));
