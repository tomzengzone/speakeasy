package com.speakeasy.content;

import org.springframework.jdbc.core.JdbcTemplate;

public final class CourseTestFixture {
  static final String JOB_A2_COURSE_ID = "40000000-0000-4000-8000-000000000001";
  static final String JOB_A2_VERSION_ID = "41000000-0000-4000-8000-000000000001";
  static final String JOB_A2_BINDING_ID = "42000000-0000-4000-8000-000000000001";
  static final String JOB_DRAFT_VERSION_ID = "41000000-0000-4000-8000-000000000091";
  static final String JOB_SUPERSEDED_VERSION_ID = "41000000-0000-4000-8000-000000000092";

  private CourseTestFixture() {}

  public static void restore(JdbcTemplate jdbc) {
    clear(jdbc);
    restoreScenarioFacts(jdbc);
    jdbc.update("""
        INSERT INTO content_course (
          course_id, scenario_id, slug, sort_order, created_at, updated_at
        ) VALUES
          ('40000000-0000-4000-8000-000000000001', 'job_interview', 'job-interview-a2', 10, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('40000000-0000-4000-8000-000000000002', 'job_interview', 'job-interview-b1', 20, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('40000000-0000-4000-8000-000000000003', 'job_interview', 'job-interview-b2', 30, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('40000000-0000-4000-8000-000000000004', 'onboarding_introduction', 'onboarding-introduction-a2', 10, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('40000000-0000-4000-8000-000000000005', 'onboarding_introduction', 'onboarding-introduction-b1', 20, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('40000000-0000-4000-8000-000000000006', 'onboarding_introduction', 'onboarding-introduction-b2', 30, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00')
        """);
    jdbc.update("""
        INSERT INTO content_course_version (
          course_version_id, course_id, version_key, title_en, summary_zh, cefr_level,
          duration_value, duration_unit, background_asset_ref, publication_status, published_at,
          superseded_at, current_published_marker, created_at, updated_at
        ) VALUES
          ('41000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '2026.08-v1', 'Job Interview Basics', '用简单句完成自我介绍并回答常见面试问题。', 'A2', 10, 'minutes', NULL, 'published', TIMESTAMP '2026-08-07 00:00:00', NULL, TRUE, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('41000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000002', '2026.08-v1', 'Structured Interview Answers', '用清晰结构说明经历、贡献与挑战。', 'B1', 15, 'minutes', NULL, 'published', TIMESTAMP '2026-08-07 00:00:00', NULL, TRUE, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('41000000-0000-4000-8000-000000000003', '40000000-0000-4000-8000-000000000003', '2026.08-v1', 'Advanced Interview Responses', '在深入追问下解释取舍、反思与影响。', 'B2', 20, 'minutes', NULL, 'published', TIMESTAMP '2026-08-07 00:00:00', NULL, TRUE, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('41000000-0000-4000-8000-000000000004', '40000000-0000-4000-8000-000000000004', '2026.08-v1', 'Onboarding Introductions', '完成入职自我介绍并进行基础团队对话。', 'A2', 10, 'minutes', NULL, 'published', TIMESTAMP '2026-08-07 00:00:00', NULL, TRUE, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('41000000-0000-4000-8000-000000000005', '40000000-0000-4000-8000-000000000005', '2026.08-v1', 'Roles and Priorities at Work', '说明职责、确认优先级并开展协作沟通。', 'B1', 15, 'minutes', NULL, 'published', TIMESTAMP '2026-08-07 00:00:00', NULL, TRUE, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('41000000-0000-4000-8000-000000000006', '40000000-0000-4000-8000-000000000006', '2026.08-v1', 'Strategic Team Alignment', '在复杂协作场景中澄清目标、风险与下一步。', 'B2', 20, 'minutes', NULL, 'published', TIMESTAMP '2026-08-07 00:00:00', NULL, TRUE, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('41000000-0000-4000-8000-000000000091', '40000000-0000-4000-8000-000000000001', 'fixture-draft', 'Draft Fixture', '仅用于测试未发布课程版本。', 'A2', 8, 'minutes', NULL, 'draft', NULL, NULL, NULL, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('41000000-0000-4000-8000-000000000092', '40000000-0000-4000-8000-000000000001', 'fixture-superseded', 'Superseded Fixture', '仅用于测试已取代课程版本。', 'A2', 9, 'minutes', NULL, 'superseded', TIMESTAMP '2026-08-01 00:00:00', TIMESTAMP '2026-08-06 00:00:00', NULL, TIMESTAMP '2026-08-01 00:00:00', TIMESTAMP '2026-08-06 00:00:00')
        """);
    jdbc.update("""
        INSERT INTO content_course_content_binding (
          course_content_binding_id, course_version_id, scenario_version_id, scenario_level_id, created_at, updated_at
        ) VALUES
          ('42000000-0000-4000-8000-000000000001', '41000000-0000-4000-8000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('42000000-0000-4000-8000-000000000002', '41000000-0000-4000-8000-000000000002', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('42000000-0000-4000-8000-000000000003', '41000000-0000-4000-8000-000000000003', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('42000000-0000-4000-8000-000000000004', '41000000-0000-4000-8000-000000000004', '10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000004', TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('42000000-0000-4000-8000-000000000005', '41000000-0000-4000-8000-000000000005', '10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000005', TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'),
          ('42000000-0000-4000-8000-000000000006', '41000000-0000-4000-8000-000000000006', '10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000006', TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00')
        """);
  }

  public static void clear(JdbcTemplate jdbc) {
    jdbc.update("""
        DELETE FROM content_course_content_binding
        WHERE course_version_id IN (
          SELECT course_version_id FROM content_course_version
          WHERE course_id IN (
            '40000000-0000-4000-8000-000000000001',
            '40000000-0000-4000-8000-000000000002',
            '40000000-0000-4000-8000-000000000003',
            '40000000-0000-4000-8000-000000000004',
            '40000000-0000-4000-8000-000000000005',
            '40000000-0000-4000-8000-000000000006'
          )
        )
        """);
    jdbc.update("""
        DELETE FROM content_course_version
        WHERE course_id IN (
          '40000000-0000-4000-8000-000000000001',
          '40000000-0000-4000-8000-000000000002',
          '40000000-0000-4000-8000-000000000003',
          '40000000-0000-4000-8000-000000000004',
          '40000000-0000-4000-8000-000000000005',
          '40000000-0000-4000-8000-000000000006'
        )
        """);
    jdbc.update("""
        DELETE FROM content_course
        WHERE course_id IN (
          '40000000-0000-4000-8000-000000000001',
          '40000000-0000-4000-8000-000000000002',
          '40000000-0000-4000-8000-000000000003',
          '40000000-0000-4000-8000-000000000004',
          '40000000-0000-4000-8000-000000000005',
          '40000000-0000-4000-8000-000000000006'
        )
        """);
  }

  static void clearScenario(JdbcTemplate jdbc, String scenarioId) {
    jdbc.update("""
        DELETE FROM content_course_content_binding
        WHERE course_version_id IN (
          SELECT version.course_version_id
          FROM content_course_version version
          JOIN content_course course ON course.course_id = version.course_id
          WHERE course.scenario_id = ?
            AND course.course_id IN (
              '40000000-0000-4000-8000-000000000001',
              '40000000-0000-4000-8000-000000000002',
              '40000000-0000-4000-8000-000000000003',
              '40000000-0000-4000-8000-000000000004',
              '40000000-0000-4000-8000-000000000005',
              '40000000-0000-4000-8000-000000000006'
            )
        )
        """, scenarioId);
    jdbc.update("""
        DELETE FROM content_course_version
        WHERE course_id IN (
          SELECT course_id FROM content_course
          WHERE scenario_id = ?
            AND course_id IN (
              '40000000-0000-4000-8000-000000000001',
              '40000000-0000-4000-8000-000000000002',
              '40000000-0000-4000-8000-000000000003',
              '40000000-0000-4000-8000-000000000004',
              '40000000-0000-4000-8000-000000000005',
              '40000000-0000-4000-8000-000000000006'
            )
        )
        """, scenarioId);
    jdbc.update("""
        DELETE FROM content_course
        WHERE scenario_id = ?
          AND course_id IN (
            '40000000-0000-4000-8000-000000000001',
            '40000000-0000-4000-8000-000000000002',
            '40000000-0000-4000-8000-000000000003',
            '40000000-0000-4000-8000-000000000004',
            '40000000-0000-4000-8000-000000000005',
            '40000000-0000-4000-8000-000000000006'
          )
        """, scenarioId);
  }

  public static void restoreScenarioFacts(JdbcTemplate jdbc) {
    jdbc.update("""
        UPDATE scenarios
        SET category = 'official', status = 'available'
        WHERE scenario_id IN ('job_interview', 'onboarding_introduction')
        """);
    jdbc.update("""
        UPDATE scenario_versions
        SET content_status = 'published', published_at = TIMESTAMP '2026-05-29 00:00:00'
        WHERE scenario_version_id IN (
          '10000000-0000-0000-0000-000000000001',
          '10000000-0000-0000-0000-000000000002'
        )
        """);
    jdbc.update("""
        UPDATE scenario_levels SET level_code = CASE scenario_level_id
          WHEN '20000000-0000-0000-0000-000000000001' THEN 'A2'
          WHEN '20000000-0000-0000-0000-000000000002' THEN 'B1'
          WHEN '20000000-0000-0000-0000-000000000003' THEN 'B2'
          WHEN '20000000-0000-0000-0000-000000000004' THEN 'A2'
          WHEN '20000000-0000-0000-0000-000000000005' THEN 'B1'
          WHEN '20000000-0000-0000-0000-000000000006' THEN 'B2'
        END,
        target_level = CASE scenario_level_id
          WHEN '20000000-0000-0000-0000-000000000001' THEN 'A2'
          WHEN '20000000-0000-0000-0000-000000000002' THEN 'B1'
          WHEN '20000000-0000-0000-0000-000000000003' THEN 'B2'
          WHEN '20000000-0000-0000-0000-000000000004' THEN 'A2'
          WHEN '20000000-0000-0000-0000-000000000005' THEN 'B1'
          WHEN '20000000-0000-0000-0000-000000000006' THEN 'B2'
        END
        WHERE scenario_level_id IN (
          '20000000-0000-0000-0000-000000000001',
          '20000000-0000-0000-0000-000000000002',
          '20000000-0000-0000-0000-000000000003',
          '20000000-0000-0000-0000-000000000004',
          '20000000-0000-0000-0000-000000000005',
          '20000000-0000-0000-0000-000000000006'
        )
        """);
  }
}
