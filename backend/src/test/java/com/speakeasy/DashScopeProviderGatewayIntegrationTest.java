package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.ai.AiMediaReferenceService;
import com.speakeasy.ai.AiProviderTelemetry;
import com.speakeasy.ai.DashScopeHttpTransport;
import com.speakeasy.commerce.EntitlementSnapshot;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;
import com.jayway.jsonpath.JsonPath;

@SpringBootTest(
    properties = {
      "speakeasy.ai.provider=dashscope",
      "speakeasy.ai.dashscope.api-key=test-secret",
      "speakeasy.ai.dashscope.compatible-base-url=https://dashscope.test/compatible-mode/v1",
      "speakeasy.ai.dashscope.api-base-url=https://dashscope.test/api/v1",
      "speakeasy.ai.dashscope.tts-url=https://dashscope.test/tts",
      "speakeasy.ai.dashscope.asr-poll-attempts=1",
      "speakeasy.ai.dashscope.max-text-chars=4000",
      "speakeasy.ai.dashscope.max-asr-duration-seconds=600",
      "speakeasy.ai.media.metadata-signing-key=test-media-secret"
    })
@AutoConfigureMockMvc
@ActiveProfiles("test")
class DashScopeProviderGatewayIntegrationTest extends BackendIntegrationTestSupport {
  @Autowired RecordingDashScopeTransport dashScopeTransport;
  @Autowired RecordingTelemetry recordingTelemetry;
  @Autowired AiMediaReferenceService mediaReferences;
  @Autowired ObjectMapper objectMapper;

  @BeforeEach
  void resetProviderFakes() {
    dashScopeTransport.reset();
    recordingTelemetry.events.clear();
  }

  @Test
  void tcP01019AiRestUsesDashScopeAdapterThroughCurrentGateway() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138300");
    String auth = bearer(tokens.accessToken());
    String sessionId = startSession(tokens);
    String signedAudioRef = mediaReferences.signTrustedAudioRef("https://media.example.com/answer.wav", 8, 1024);

    mvc.perform(post("/ai/transcribe")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "%s"
                }
                """.formatted(signedAudioRef)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"))
        .andExpect(jsonPath("$.transcript", not(blankOrNullString())));

    mvc.perform(post("/ai/transcribe")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "/tmp/local-answer.wav"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("no_result"));

    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "text": "Could you tell me about yourself?",
                  "voice": "Cherry"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"))
        .andExpect(jsonPath("$.audio_ref").value("https://media.example.com/tts.wav"));

    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "text": "Could you tell me about yourself?",
                  "voice": "Cherry"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.audio_ref").value("https://media.example.com/tts.wav"));

    mvc.perform(post("/ai/coach-turn")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "session_id": "%s",
                  "transcript": "I worked on a project that improved our workflow."
                }
                """.formatted(sessionId)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.validation_status").value("valid"))
        .andExpect(jsonPath("$.feedback.provider_status").value("success"))
        .andExpect(jsonPath("$.provider_secret").doesNotExist());

    org.assertj.core.api.Assertions.assertThat(dashScopeTransport.ttsCalls).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(auditLogs.findAll())
        .allSatisfy(log -> {
          org.assertj.core.api.Assertions.assertThat(log.getRedactedDetails()).doesNotContain("https://media.example.com");
          org.assertj.core.api.Assertions.assertThat(log.getRedactedDetails()).doesNotContain("media_sig");
        });
    org.assertj.core.api.Assertions.assertThat(recordingTelemetry.events)
        .anySatisfy(event -> {
          org.assertj.core.api.Assertions.assertThat(event.provider()).isEqualTo("dashscope");
          org.assertj.core.api.Assertions.assertThat(event.usageFamily()).isIn("asr", "tts", "ai");
          org.assertj.core.api.Assertions.assertThat(event.estimatedCostBucket()).isNotBlank();
        })
        .anySatisfy(event -> {
          org.assertj.core.api.Assertions.assertThat(event.provider()).isEqualTo("ai-gateway");
          org.assertj.core.api.Assertions.assertThat(event.policyTier()).isEqualTo("free");
          org.assertj.core.api.Assertions.assertThat(event.status()).isEqualTo("allowed");
        });
  }

  @Test
  void tcP01019RejectsAudioBeyondCurrentPlanBeforeProviderCall() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138301");
    String signedTooLongAudioRef = mediaReferences.signTrustedAudioRef("https://media.example.com/answer.wav", 999, 1024);

    mvc.perform(post("/ai/transcribe")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "%s"
                }
                """.formatted(signedTooLongAudioRef)))
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("USAGE_LIMIT_EXCEEDED"))
        .andExpect(jsonPath("$.error.details.policy_tier").value("free"))
        .andExpect(jsonPath("$.error.details.max_audio_duration_seconds").value(60));

    org.assertj.core.api.Assertions.assertThat(dashScopeTransport.asrCalls).isZero();
    org.assertj.core.api.Assertions.assertThat(recordingTelemetry.events)
        .anySatisfy(event -> {
          org.assertj.core.api.Assertions.assertThat(event.provider()).isEqualTo("ai-gateway");
          org.assertj.core.api.Assertions.assertThat(event.usageFamily()).isEqualTo("asr");
          org.assertj.core.api.Assertions.assertThat(event.status()).isEqualTo("rejected");
          org.assertj.core.api.Assertions.assertThat(event.policyTier()).isEqualTo("free");
          org.assertj.core.api.Assertions.assertThat(event.fallbackReason()).isEqualTo("audio_duration_exceeded");
        });
  }

  @Test
  void tcP01019EnforcesServerSideFreeProEnterpriseProviderPolicy() throws Exception {
    String longText = "x".repeat(1300);

    AuthTokens freeTokens = loginPhone("+8613800138303");
    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, bearer(freeTokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content(ttsBody(longText)))
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("USAGE_LIMIT_EXCEEDED"))
        .andExpect(jsonPath("$.error.details.policy_tier").value("free"))
        .andExpect(jsonPath("$.error.details.max_text_chars").value(1200));

    AuthTokens proTokens = loginPhone("+8613800138304");
    grantPlan(proTokens, "pro_monthly");
    String proAudioRef = mediaReferences.signTrustedAudioRef("https://media.example.com/pro-answer.wav", 120, 2048);

    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, bearer(proTokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content(ttsBody(longText)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"));

    mvc.perform(post("/ai/transcribe")
            .header(HttpHeaders.AUTHORIZATION, bearer(proTokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "%s"
                }
                """.formatted(proAudioRef)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"));

    AuthTokens enterpriseTokens = loginPhone("+8613800138305");
    grantPlan(enterpriseTokens, "enterprise");
    String enterpriseAudioRef =
        mediaReferences.signTrustedAudioRef("https://media.example.com/enterprise-answer.wav", 500, 4096);

    mvc.perform(post("/ai/transcribe")
            .header(HttpHeaders.AUTHORIZATION, bearer(enterpriseTokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "%s"
                }
                """.formatted(enterpriseAudioRef)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"));

    org.assertj.core.api.Assertions.assertThat(recordingTelemetry.events)
        .anySatisfy(event -> {
          org.assertj.core.api.Assertions.assertThat(event.provider()).isEqualTo("ai-gateway");
          org.assertj.core.api.Assertions.assertThat(event.policyTier()).isEqualTo("free");
          org.assertj.core.api.Assertions.assertThat(event.status()).isEqualTo("rejected");
          org.assertj.core.api.Assertions.assertThat(event.fallbackReason()).isEqualTo("text_length_exceeded");
        })
        .anySatisfy(event -> {
          org.assertj.core.api.Assertions.assertThat(event.provider()).isEqualTo("ai-gateway");
          org.assertj.core.api.Assertions.assertThat(event.policyTier()).isEqualTo("pro");
          org.assertj.core.api.Assertions.assertThat(event.status()).isEqualTo("allowed");
          org.assertj.core.api.Assertions.assertThat(event.audioDurationSeconds()).isEqualTo(120);
        })
        .anySatisfy(event -> {
          org.assertj.core.api.Assertions.assertThat(event.provider()).isEqualTo("ai-gateway");
          org.assertj.core.api.Assertions.assertThat(event.policyTier()).isEqualTo("enterprise");
          org.assertj.core.api.Assertions.assertThat(event.status()).isEqualTo("allowed");
          org.assertj.core.api.Assertions.assertThat(event.audioDurationSeconds()).isEqualTo(500);
        });
  }

  @Test
  void tcP01019EnforcesAudioSizeByServerTierBeforeProviderCall() throws Exception {
    AuthTokens freeTokens = loginPhone("+8613800138307");
    String freeTooLargeAudioRef =
        mediaReferences.signTrustedAudioRef("https://media.example.com/free-large-answer.wav", 10, 6_000_000);

    mvc.perform(post("/ai/transcribe")
            .header(HttpHeaders.AUTHORIZATION, bearer(freeTokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "%s"
                }
                """.formatted(freeTooLargeAudioRef)))
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("USAGE_LIMIT_EXCEEDED"))
        .andExpect(jsonPath("$.error.details.policy_tier").value("free"))
        .andExpect(jsonPath("$.error.details.max_audio_bytes").value(5_000_000));

    org.assertj.core.api.Assertions.assertThat(dashScopeTransport.asrCalls).isZero();

    AuthTokens proTokens = loginPhone("+8613800138308");
    grantPlan(proTokens, "pro_monthly");
    String proAllowedAudioRef =
        mediaReferences.signTrustedAudioRef("https://media.example.com/pro-large-answer.wav", 10, 6_000_000);

    mvc.perform(post("/ai/transcribe")
            .header(HttpHeaders.AUTHORIZATION, bearer(proTokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "%s"
                }
                """.formatted(proAllowedAudioRef)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"));

    org.assertj.core.api.Assertions.assertThat(dashScopeTransport.asrCalls).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(recordingTelemetry.events)
        .anySatisfy(event -> {
          org.assertj.core.api.Assertions.assertThat(event.provider()).isEqualTo("ai-gateway");
          org.assertj.core.api.Assertions.assertThat(event.policyTier()).isEqualTo("free");
          org.assertj.core.api.Assertions.assertThat(event.status()).isEqualTo("rejected");
          org.assertj.core.api.Assertions.assertThat(event.fallbackReason()).isEqualTo("audio_size_exceeded");
        })
        .anySatisfy(event -> {
          org.assertj.core.api.Assertions.assertThat(event.provider()).isEqualTo("ai-gateway");
          org.assertj.core.api.Assertions.assertThat(event.policyTier()).isEqualTo("pro");
          org.assertj.core.api.Assertions.assertThat(event.status()).isEqualTo("allowed");
          org.assertj.core.api.Assertions.assertThat(event.audioDurationSeconds()).isEqualTo(10);
        });
  }

  @Test
  void tcP01019ClientProviderTierCannotOverrideServerEntitlementPolicy() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138306");

    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "text": "Hello",
                  "provider_tier": "enterprise"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    org.assertj.core.api.Assertions.assertThat(dashScopeTransport.ttsCalls).isZero();
  }

  @Test
  void tcP01016RejectsUnsignedHttpAudioRefBeforeProviderCall() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138302");

    mvc.perform(post("/ai/transcribe")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "https://media.example.com/answer.wav?duration_seconds=8&bytes=1024"
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"))
        .andExpect(jsonPath("$.error.details.media_error").value("trusted_media_metadata_required"));

    org.assertj.core.api.Assertions.assertThat(dashScopeTransport.asrCalls).isZero();
  }

  private String startSession(AuthTokens tokens) throws Exception {
    MvcResult result = mvc.perform(post("/practice/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scenario_id": "job_interview",
                  "level_code": "L1",
                  "resume_existing": true
                }
                """))
        .andExpect(status().isOk())
        .andReturn();
    return JsonPath.read(result.getResponse().getContentAsString(), "$.session.session_id");
  }

  private void grantPlan(AuthTokens tokens, String plan) {
    entitlements.save(new EntitlementSnapshot(
        UUID.randomUUID(),
        UUID.fromString(tokens.userId()),
        plan,
        "{\"basic_scenarios\":true,\"advanced_scenarios\":true,\"ai_feedback\":true}",
        "{\"ai\":100,\"asr\":100,\"tts\":100,\"scoring\":100,\"training\":100}",
        Instant.now()));
  }

  private String ttsBody(String text) throws Exception {
    return objectMapper.writeValueAsString(Map.of(
        "schema_version", 1,
        "text", text,
        "voice", "Cherry"));
  }

  @TestConfiguration
  static class DashScopeTestConfig {
    @Bean
    @Primary
    RecordingDashScopeTransport recordingDashScopeTransport(ObjectMapper mapper) {
      return new RecordingDashScopeTransport(mapper);
    }

    @Bean
    @Primary
    RecordingTelemetry recordingTelemetry() {
      return new RecordingTelemetry();
    }
  }

  static class RecordingDashScopeTransport implements DashScopeHttpTransport {
    private final ObjectMapper mapper;
    private int asrCalls;
    private int ttsCalls;

    RecordingDashScopeTransport(ObjectMapper mapper) {
      this.mapper = mapper;
    }

    void reset() {
      asrCalls = 0;
      ttsCalls = 0;
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
        if (url.contains("/tts")) {
          ttsCalls += 1;
          return mapper.readTree("{\"output\":{\"audio\":{\"url\":\"https://media.example.com/tts.wav\"}}}");
        }
        if (url.contains("/chat/completions")) {
          String content =
              "{\"feedback_type\":\"next_question\",\"summary\":\"表达清楚，可以更自然。\",\"main_issue_type\":\"naturalness\",\"suggested_expression\":\"My main contribution was clarifying priorities.\",\"next_prompt\":\"What was the biggest challenge?\",\"score_signal\":{\"score_kind\":\"pronunciation\",\"value\":0.85,\"confidence\":0.86,\"status\":\"available\"}}";
          return mapper.readTree(
              "{\"choices\":[{\"message\":{\"content\":%s}}]}".formatted(mapper.writeValueAsString(content)));
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

  static class RecordingTelemetry implements AiProviderTelemetry {
    private final List<Event> events = new ArrayList<>();

    @Override
    public void record(Event event) {
      events.add(event);
    }
  }
}
