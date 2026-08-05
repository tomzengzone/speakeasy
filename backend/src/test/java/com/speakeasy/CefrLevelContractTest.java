package com.speakeasy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CefrLevelContractTest extends BackendIntegrationTestSupport {
  @ParameterizedTest
  @ValueSource(strings = {"A1", "A2", "B1", "B2", "C1", "C2"})
  void assessmentAcceptsEveryCefrLevel(String levelCode) throws Exception {
    AuthTokens tokens = loginPhone("+86139001" + levelCode.hashCode());

    mvc.perform(post("/onboarding/assessment")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_direction": "daily_service",
                  "pain_points": ["opening"],
                  "output_level": "%s",
                  "daily_minutes": 10
                }
                """.formatted(levelCode)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.route.target_level").value(levelCode));
  }

  @ParameterizedTest
  @ValueSource(strings = {"L1", "L2", "L3", "beginner", "intermediate", "advanced", "A0", "C3"})
  void assessmentRejectsLegacyAliasesAndUnknownLevels(String levelCode) throws Exception {
    AuthTokens tokens = loginPhone("+86139002" + levelCode.hashCode());

    mvc.perform(post("/onboarding/assessment")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_direction": "daily_service",
                  "pain_points": ["opening"],
                  "output_level": "%s",
                  "daily_minutes": 10
                }
                """.formatted(levelCode)))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }

  @ParameterizedTest
  @MethodSource("unavailableCefrLevels")
  void validCefrWithoutPublishedTrackReturnsNotFoundWithoutFallback(String levelCode) throws Exception {
    AuthTokens tokens = loginPhone("+86139003" + levelCode.hashCode());

    mvc.perform(get("/scenarios/job_interview/levels/" + levelCode)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));
  }

  private static Stream<Arguments> unavailableCefrLevels() {
    return Stream.of(Arguments.of("A1"), Arguments.of("C1"), Arguments.of("C2"));
  }

  @ParameterizedTest
  @ValueSource(strings = {"L1", "L2", "L3", "beginner", "intermediate", "advanced"})
  void scenarioLevelPathRejectsLegacyValuesInsteadOfTreatingThemAsMissingContent(String levelCode) throws Exception {
    AuthTokens tokens = loginPhone("+86139004" + levelCode.hashCode());

    mvc.perform(get("/scenarios/job_interview/levels/" + levelCode)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }

  @Test
  void omittedScenarioTargetLevelDefaultsToA2() throws Exception {
    AuthTokens tokens = loginPhone("+8613900500000");

    mvc.perform(put("/user/scenarios/job_interview")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "set_current": true
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.state.target_level").value("A2"));
  }

  @ParameterizedTest
  @ValueSource(strings = {"L1", "beginner"})
  void userProfileRejectsLegacyLevelValues(String levelCode) throws Exception {
    AuthTokens tokens = loginPhone("+86139006" + levelCode.hashCode());

    mvc.perform(patch("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "target_level": "%s"
                }
                """.formatted(levelCode)))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }

  @ParameterizedTest
  @ValueSource(strings = {"L1", "beginner"})
  void practiceAndTrainingRejectLegacyLevelValues(String levelCode) throws Exception {
    AuthTokens tokens = loginPhone("+86139007" + levelCode.hashCode());
    String body = """
        {
          "schema_version": 1,
          "scenario_id": "job_interview",
          "level_code": "%s",
          "resume_existing": true
        }
        """.formatted(levelCode);

    mvc.perform(post("/practice/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    mvc.perform(post("/training/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }
}
