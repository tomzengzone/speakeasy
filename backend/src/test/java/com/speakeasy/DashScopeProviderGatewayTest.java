package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.ai.AiProviderGateway;
import com.speakeasy.ai.AiProviderTelemetry;
import com.speakeasy.ai.AiMediaProperties;
import com.speakeasy.ai.AiMediaReferenceService;
import com.speakeasy.ai.DashScopeAiProperties;
import com.speakeasy.ai.DashScopeAiProviderGateway;
import com.speakeasy.ai.DashScopeHttpTransport;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DashScopeProviderGatewayTest {
  private final ObjectMapper mapper = new ObjectMapper();
  private DashScopeAiProperties properties;
  private AiMediaReferenceService mediaReferences;
  private RecordingTransport transport;
  private RecordingTelemetry telemetry;
  private DashScopeAiProviderGateway gateway;

  @BeforeEach
  void setUp() {
    properties = new DashScopeAiProperties();
    properties.setApiKey("test-secret");
    properties.setCompatibleBaseUrl("https://dashscope.test/compatible-mode/v1");
    properties.setApiBaseUrl("https://dashscope.test/api/v1");
    properties.setTtsUrl("https://dashscope.test/tts");
    properties.setLlmModel("qwen-plus-test");
    properties.setTtsModel("qwen3-tts-test");
    properties.setAsrModel("paraformer-test");
    properties.setAsrPollAttempts(2);
    AiMediaProperties mediaProperties = new AiMediaProperties();
    mediaProperties.setMetadataSigningKey("test-media-secret");
    mediaReferences = new AiMediaReferenceService(mediaProperties);
    transport = new RecordingTransport(mapper);
    telemetry = new RecordingTelemetry();
    gateway = new DashScopeAiProviderGateway(properties, transport, mapper, telemetry, mediaReferences);
  }

  @Test
  void tcP01015RoutesConfiguredDashScopeAsrThroughProviderGateway() {
    AiProviderGateway.TranscribeResult result =
        gateway.transcribe(mediaReferences.signTrustedAudioRef("https://media.example.com/answer.m4a", 10, 2048), "en,zh");

    assertThat(result.status()).isEqualTo("available");
    assertThat(result.transcript()).isEqualTo("I worked on a project that improved our workflow.");
    assertThat(transport.posts).hasSize(2);
    assertThat(transport.posts.get(0).body().at("/model").asText()).isEqualTo("paraformer-test");
    assertThat(transport.posts.get(0).headers()).containsEntry("X-DashScope-Async", "enable");
    assertThat(telemetry.events).anySatisfy(event -> {
      assertThat(event.provider()).isEqualTo("dashscope");
      assertThat(event.model()).isEqualTo("paraformer-test");
      assertThat(event.usageFamily()).isEqualTo("asr");
      assertThat(event.audioDurationSeconds()).isEqualTo(10);
    });
  }

  @Test
  void tcP01016RejectsLocalPathAndOverPolicyAudioRefBeforeProviderCall() {
    AiProviderGateway.TranscribeResult local = gateway.transcribe("/tmp/answer.wav", "en");
    AiProviderGateway.TranscribeResult tooLong =
        gateway.transcribe(mediaReferences.signTrustedAudioRef("https://media.example.com/answer.wav", 999, 1), "en");
    AiProviderGateway.TranscribeResult unsigned =
        gateway.transcribe("https://media.example.com/answer.wav?duration_seconds=10&bytes=1", "en");

    assertThat(local.status()).isEqualTo("no_result");
    assertThat(tooLong.status()).isEqualTo("provider_unavailable");
    assertThat(unsigned.status()).isEqualTo("no_result");
    assertThat(transport.posts).isEmpty();
    assertThat(telemetry.events)
        .extracting(AiProviderTelemetry.Event::fallbackReason)
        .contains("no_result", "provider_policy_rejected");
  }

  @Test
  void tcP01017CachesTtsByTextModelAndVoice() {
    AiProviderGateway.TtsResult first = gateway.synthesize("Could you tell me about yourself?", "Cherry");
    AiProviderGateway.TtsResult second = gateway.synthesize("Could you tell me about yourself?", "Cherry");

    assertThat(first.status()).isEqualTo("available");
    assertThat(second.audioRef()).isEqualTo(first.audioRef());
    assertThat(transport.posts).hasSize(1);
    assertThat(transport.posts.get(0).body().at("/model").asText()).isEqualTo("qwen3-tts-test");
    assertThat(telemetry.events)
        .extracting(AiProviderTelemetry.Event::fallbackReason)
        .contains("provider_call", "cache_hit");
  }

  @Test
  void tcP01018MapsStrictCoachJsonAndFallsBackOnBannedFields() {
    AiProviderGateway.CoachResult valid =
        gateway.coach(
            UUID.randomUUID(),
            "I worked on a project that improved our workflow.",
            List.of("job_interview_l1_project"));

    transport.coachMode = "banned";
    AiProviderGateway.CoachResult invalid =
        gateway.coach(UUID.randomUUID(), "I worked on a project.", List.of());
    transport.coachMode = "invalid_feedback_type";
    AiProviderGateway.CoachResult invalidEnum =
        gateway.coach(UUID.randomUUID(), "I worked on a project.", List.of());
    transport.coachMode = "missing_next_prompt";
    AiProviderGateway.CoachResult missingRequired =
        gateway.coach(UUID.randomUUID(), "I worked on a project.", List.of());
    transport.coachMode = "score_out_of_range";
    AiProviderGateway.CoachResult outOfRange =
        gateway.coach(UUID.randomUUID(), "I worked on a project.", List.of());
    transport.coachMode = "extra_field";
    AiProviderGateway.CoachResult extraField =
        gateway.coach(UUID.randomUUID(), "I worked on a project.", List.of());

    assertThat(valid.validationStatus()).isEqualTo("valid");
    assertThat(valid.providerStatus()).isEqualTo("success");
    assertThat(valid.scoreSignal().status()).isEqualTo("available");
    assertThat(invalid.validationStatus()).isEqualTo("fallback");
    assertThat(invalid.providerStatus()).isEqualTo("invalid_schema");
    assertThat(invalid.recoverable()).isTrue();
    assertThat(invalidEnum.providerStatus()).isEqualTo("invalid_schema");
    assertThat(missingRequired.providerStatus()).isEqualTo("invalid_schema");
    assertThat(outOfRange.providerStatus()).isEqualTo("invalid_schema");
    assertThat(extraField.providerStatus()).isEqualTo("invalid_schema");
  }

  @Test
  void tcP01020TelemetryIsSanitizedAndCarriesCommercialMetadata() {
    gateway.coach(UUID.randomUUID(), "This is a short answer.", List.of());

    AiProviderTelemetry.Event event = telemetry.events.get(0);
    assertThat(event.provider()).isEqualTo("dashscope");
    assertThat(event.model()).isEqualTo("qwen-plus-test");
    assertThat(event.tokenEstimate()).isGreaterThan(0);
    assertThat(event.estimatedCostBucket()).isIn("low", "medium", "high");
    assertThat(event.toString()).doesNotContain("test-secret");
    assertThat(event.toString()).doesNotContain("This is a short answer.");
  }

  private static class RecordingTransport implements DashScopeHttpTransport {
    private final ObjectMapper mapper;
    private final List<Request> posts = new ArrayList<>();
    private String coachMode = "valid";

    RecordingTransport(ObjectMapper mapper) {
      this.mapper = mapper;
    }

    @Override
    public JsonNode postJson(String url, JsonNode body, Map<String, String> headers, Duration timeout) {
      posts.add(new Request(url, body.deepCopy(), Map.copyOf(headers)));
      try {
        if (url.contains("/services/audio/asr/transcription")) {
          return mapper.readTree("{\"output\":{\"task_id\":\"task-1\"}}");
        }
        if (url.contains("/tasks/task-1")) {
          return mapper.readTree(
              "{\"output\":{\"task_status\":\"SUCCEEDED\",\"results\":[{\"text\":\"I worked on a project that improved our workflow.\"}]}}");
        }
        if (url.contains("/tts")) {
          return mapper.readTree("{\"output\":{\"audio\":{\"url\":\"https://media.example.com/tts.wav\"}}}");
        }
        if (url.contains("/chat/completions")) {
          String content = coachContent();
          return mapper.readTree(
              "{\"choices\":[{\"message\":{\"content\":%s}}]}".formatted(mapper.writeValueAsString(content)));
        }
        return mapper.readTree("{}");
      } catch (Exception e) {
        throw new RuntimeException(e);
      }
    }

    private String coachContent() {
      return switch (coachMode) {
        case "banned" ->
            "{\"feedback_type\":\"next_question\",\"summary\":\"ok\",\"main_issue_type\":\"none\",\"suggested_expression\":\"\",\"next_prompt\":\"Next?\",\"score_signal\":{\"score_kind\":\"pronunciation\",\"value\":0.85,\"confidence\":0.86,\"status\":\"available\"},\"mastered\":true}";
        case "invalid_feedback_type" ->
            "{\"feedback_type\":\"score_signal\",\"summary\":\"ok\",\"main_issue_type\":\"none\",\"suggested_expression\":\"\",\"next_prompt\":\"Next?\",\"score_signal\":{\"score_kind\":\"pronunciation\",\"value\":0.85,\"confidence\":0.86,\"status\":\"available\"}}";
        case "missing_next_prompt" ->
            "{\"feedback_type\":\"next_question\",\"summary\":\"ok\",\"main_issue_type\":\"none\",\"suggested_expression\":\"\",\"score_signal\":{\"score_kind\":\"pronunciation\",\"value\":0.85,\"confidence\":0.86,\"status\":\"available\"}}";
        case "score_out_of_range" ->
            "{\"feedback_type\":\"next_question\",\"summary\":\"ok\",\"main_issue_type\":\"none\",\"suggested_expression\":\"\",\"next_prompt\":\"Next?\",\"score_signal\":{\"score_kind\":\"pronunciation\",\"value\":1.2,\"confidence\":0.86,\"status\":\"available\"}}";
        case "extra_field" ->
            "{\"feedback_type\":\"next_question\",\"summary\":\"ok\",\"main_issue_type\":\"none\",\"suggested_expression\":\"\",\"next_prompt\":\"Next?\",\"score_signal\":{\"score_kind\":\"pronunciation\",\"value\":0.85,\"confidence\":0.86,\"status\":\"available\"},\"unexpected\":\"unsafe\"}";
        default ->
            "{\"feedback_type\":\"next_question\",\"summary\":\"表达清楚，可以更自然。\",\"main_issue_type\":\"naturalness\",\"suggested_expression\":\"My main contribution was clarifying priorities.\",\"next_prompt\":\"What was the biggest challenge?\",\"score_signal\":{\"score_kind\":\"pronunciation\",\"value\":0.85,\"confidence\":0.86,\"status\":\"available\"}}";
      };
    }

    @Override
    public JsonNode getJson(String url, Map<String, String> headers, Duration timeout) {
      throw new UnsupportedOperationException("not used");
    }
  }

  private static class RecordingTelemetry implements AiProviderTelemetry {
    private final List<Event> events = new ArrayList<>();

    @Override
    public void record(Event event) {
      events.add(event);
    }
  }

  private record Request(String url, JsonNode body, Map<String, String> headers) {}
}
