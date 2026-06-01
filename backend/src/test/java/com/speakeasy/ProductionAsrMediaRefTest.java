package com.speakeasy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ai.DashScopeHttpTransport;
import java.time.Duration;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(
    properties = {
      "speakeasy.ai.provider=dashscope",
      "speakeasy.ai.dashscope.api-key=test-secret",
      "speakeasy.ai.dashscope.api-base-url=https://dashscope.test/api/v1",
      "speakeasy.ai.dashscope.asr-poll-attempts=1",
      "speakeasy.ai.media.metadata-signing-key=test-media-secret"
    })
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProductionAsrMediaRefTest extends BackendIntegrationTestSupport {
  @org.springframework.beans.factory.annotation.Autowired RecordingDashScopeTransport dashScopeTransport;

  @BeforeEach
  void resetTransport() {
    dashScopeTransport.reset();
  }

  @Test
  void rejectsLocalUnsignedAndUnvalidatedMediaRefsBeforeProviderCall() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138410");

    transcribe(tokens, "/tmp/local-answer.wav")
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"))
        .andExpect(jsonPath("$.error.details.media_error").value("unsupported_media_ref"));

    transcribe(tokens, "https://media.example.com/answer.wav?duration_seconds=8&bytes=1024")
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"))
        .andExpect(jsonPath("$.error.details.media_error").value("trusted_media_metadata_required"));

    String mediaRef = createUpload(tokens);
    transcribe(tokens, mediaRef)
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"))
        .andExpect(jsonPath("$.error.details.media_error").value("media_not_validated"));

    org.assertj.core.api.Assertions.assertThat(dashScopeTransport.asrCalls).isZero();
  }

  @Test
  void validatedBackendMediaRefCanBeResolvedForProductionAsr() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138411");
    MvcResult createResult = createUploadResult(tokens);
    String mediaId = JsonPath.read(createResult.getResponse().getContentAsString(), "$.media.media_id");
    String mediaRef = JsonPath.read(createResult.getResponse().getContentAsString(), "$.media.audio_ref");

    mvc.perform(post("/media/audio/uploads/%s/complete".formatted(mediaId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checksum_sha256": "checksum-2"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.media.status").value("validated"));

    transcribe(tokens, mediaRef)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.status").value("available"))
        .andExpect(jsonPath("$.transcript").value("I worked on a project that improved our workflow."));

    org.assertj.core.api.Assertions.assertThat(dashScopeTransport.asrCalls).isEqualTo(1);
  }

  private String createUpload(AuthTokens tokens) throws Exception {
    MvcResult result = createUploadResult(tokens);
    return JsonPath.read(result.getResponse().getContentAsString(), "$.media.audio_ref");
  }

  private MvcResult createUploadResult(AuthTokens tokens) throws Exception {
    return mvc.perform(post("/media/audio/uploads")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "upload-%s".formatted(tokens.userId()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "purpose": "asr_input",
                  "content_type": "audio/m4a",
                  "byte_size": 240000,
                  "duration_seconds": 12,
                  "checksum_sha256": "checksum-2"
                }
                """))
        .andExpect(status().isCreated())
        .andReturn();
  }

  private org.springframework.test.web.servlet.ResultActions transcribe(AuthTokens tokens, String audioRef) throws Exception {
    return mvc.perform(post("/ai/transcribe")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "audio_ref": "%s"
            }
            """.formatted(audioRef)));
  }

  @TestConfiguration
  static class ProductionAsrMediaRefTestConfig {
    @Bean
    @Primary
    RecordingDashScopeTransport recordingDashScopeTransport(ObjectMapper mapper) {
      return new RecordingDashScopeTransport(mapper);
    }
  }

  static class RecordingDashScopeTransport implements DashScopeHttpTransport {
    private final ObjectMapper mapper;
    private int asrCalls;

    RecordingDashScopeTransport(ObjectMapper mapper) {
      this.mapper = mapper;
    }

    void reset() {
      asrCalls = 0;
    }

    @Override
    public JsonNode postJson(String url, JsonNode body, Map<String, String> headers, Duration timeout) {
      try {
        if (url.contains("/services/audio/asr/transcription")) {
          asrCalls += 1;
          return mapper.readTree("{\"output\":{\"task_id\":\"task-1\"}}");
        }
        if (url.contains("/tasks/task-1")) {
          return mapper.readTree(
              "{\"output\":{\"task_status\":\"SUCCEEDED\",\"results\":[{\"text\":\"I worked on a project that improved our workflow.\"}]}}");
        }
        return mapper.readTree("{}");
      } catch (Exception e) {
        throw new RuntimeException(e);
      }
    }

    @Override
    public JsonNode getJson(String url, Map<String, String> headers, Duration timeout) {
      throw new UnsupportedOperationException("not used");
    }
  }
}
