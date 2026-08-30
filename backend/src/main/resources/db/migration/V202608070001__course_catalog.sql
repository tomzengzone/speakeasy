CREATE TABLE content_course (
  course_id UUID PRIMARY KEY,
  scenario_id VARCHAR(80) NOT NULL REFERENCES scenarios(scenario_id),
  slug VARCHAR(120) NOT NULL,
  sort_order INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_content_course_slug UNIQUE (slug),
  CONSTRAINT uq_content_course_scenario_order UNIQUE (scenario_id, sort_order),
  CONSTRAINT ck_content_course_slug_nonblank CHECK (TRIM(slug) <> ''),
  CONSTRAINT ck_content_course_slug_canonical CHECK (slug = LOWER(TRIM(slug))),
  CONSTRAINT ck_content_course_sort_order CHECK (sort_order >= 0)
);

CREATE INDEX idx_content_course_scenario_order
  ON content_course(scenario_id, sort_order, course_id);

CREATE TABLE content_course_version (
  course_version_id UUID PRIMARY KEY,
  course_id UUID NOT NULL REFERENCES content_course(course_id),
  version_key VARCHAR(80) NOT NULL,
  title_en VARCHAR(240) NOT NULL,
  summary_zh TEXT NOT NULL,
  cefr_level VARCHAR(2) NOT NULL,
  duration_value DECIMAL(10, 2) NOT NULL,
  duration_unit VARCHAR(40) NOT NULL,
  background_asset_ref VARCHAR(500),
  publication_status VARCHAR(20) NOT NULL,
  published_at TIMESTAMP,
  superseded_at TIMESTAMP,
  current_published_marker BOOLEAN,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_content_course_version_key UNIQUE (course_id, version_key),
  CONSTRAINT uq_content_course_current_published UNIQUE (course_id, current_published_marker),
  CONSTRAINT ck_content_course_version_key_nonblank CHECK (TRIM(version_key) <> ''),
  CONSTRAINT ck_content_course_title_nonblank CHECK (TRIM(title_en) <> ''),
  CONSTRAINT ck_content_course_summary_nonblank CHECK (TRIM(summary_zh) <> ''),
  CONSTRAINT ck_content_course_cefr CHECK (cefr_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
  CONSTRAINT ck_content_course_duration_value CHECK (duration_value > 0),
  CONSTRAINT ck_content_course_duration_unit CHECK (TRIM(duration_unit) <> ''),
  CONSTRAINT ck_content_course_publication_status CHECK (publication_status IN ('draft', 'published', 'superseded')),
  CONSTRAINT ck_content_course_publication_timestamps CHECK (
    (publication_status = 'draft' AND published_at IS NULL AND superseded_at IS NULL)
    OR (publication_status = 'published' AND published_at IS NOT NULL AND superseded_at IS NULL)
    OR (publication_status = 'superseded' AND published_at IS NOT NULL AND superseded_at IS NOT NULL)
  ),
  CONSTRAINT ck_content_course_current_marker CHECK (
    (publication_status = 'published' AND current_published_marker = TRUE)
    OR (publication_status <> 'published' AND current_published_marker IS NULL)
  )
);

CREATE INDEX idx_content_course_version_course_status
  ON content_course_version(course_id, publication_status);
CREATE INDEX idx_content_course_version_status_course
  ON content_course_version(publication_status, course_id);

CREATE TABLE content_course_content_binding (
  course_content_binding_id UUID PRIMARY KEY,
  course_version_id UUID NOT NULL REFERENCES content_course_version(course_version_id),
  scenario_version_id UUID NOT NULL REFERENCES scenario_versions(scenario_version_id),
  scenario_level_id UUID NOT NULL REFERENCES scenario_levels(scenario_level_id),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_content_course_binding_version UNIQUE (course_version_id)
);

CREATE INDEX idx_content_course_binding_scenario_version
  ON content_course_content_binding(scenario_version_id);
CREATE INDEX idx_content_course_binding_scenario_level
  ON content_course_content_binding(scenario_level_id);
CREATE INDEX idx_content_course_binding_content
  ON content_course_content_binding(scenario_version_id, scenario_level_id);
