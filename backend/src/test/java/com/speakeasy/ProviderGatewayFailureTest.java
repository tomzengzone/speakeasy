package com.speakeasy;

import static org.hamcrest.Matchers.empty;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ai.AiProviderGateway;
import com.speakeasy.ai.DeterministicAiProviderGateway;
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

@SpringBootTest(properties = "speakeasy.ai.provider=deterministic")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProviderGatewayFailureTest extends BackendIntegrationTestSupport {
  @Test
  void invalidProviderSchemaReturnsRecoverableFallback() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138220");
    String sessionId = startSession(tokens);

    mvc.perform(post("/ai/coach-turn")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "session_id": "%s",
                  "transcript": "invalid_schema"
                }
                """.formatted(sessionId)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.validation_status").value("fallback"))
        .andExpect(jsonPath("$.feedback.feedback_type").value("recoverable_error"))
        .andExpect(jsonPath("$.feedback.provider_status").value("invalid_schema"));
  }

  @Test
  void failedPracticeTurnDoesNotCreatePseudoSuccessEvidence() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138221");
    String sessionId = startSession(tokens);

    mvc.perform(post("/practice/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "turn-invalid-schema")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transcript": "invalid_schema"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session_status").value("recoverable_error"))
        .andExpect(jsonPath("$.coach_feedback.validation_status").value("fallback"))
        .andExpect(jsonPath("$.recoverable_error.retryable").value(true))
        .andExpect(jsonPath("$.learning_evidence_candidates", empty()));
  }

  @Test
  void unavailableTranscriptionReturnsRecoverableSessionError() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138222");
    String sessionId = startSession(tokens);
    String audioRef = createValidatedAudioRef(tokens);

    mvc.perform(post("/practice/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "turn-asr-unavailable")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "%s"
                }
                """.formatted(audioRef)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session_status").value("recoverable_error"))
        .andExpect(jsonPath("$.recoverable_error.code").value("asr_unavailable"));
  }

  private String createValidatedAudioRef(AuthTokens tokens) throws Exception {
    MvcResult create = mvc.perform(post("/media/audio/uploads")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "practice-unavailable-audio-upload")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "purpose": "asr_input",
                  "content_type": "audio/m4a",
                  "byte_size": 240000,
                  "duration_seconds": 12,
                  "checksum_sha256": "checksum-practice-unavailable",
                  "client_upload_id": "practice-unavailable-audio"
                }
                """))
        .andExpect(status().isCreated())
        .andReturn();
    String mediaId = JsonPath.read(create.getResponse().getContentAsString(), "$.media.media_id");
    String audioRef = JsonPath.read(create.getResponse().getContentAsString(), "$.media.audio_ref");
    mvc.perform(post("/media/audio/uploads/%s/complete".formatted(mediaId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checksum_sha256": "checksum-practice-unavailable"
                }
                """))
        .andExpect(status().isOk());
    return audioRef;
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

  @TestConfiguration
  static class ProviderGatewayFailureTestConfig {
    @Bean
    @Primary
    AiProviderGateway unavailableAsrProvider() {
      return new UnavailableAsrDeterministicProviderGateway();
    }
  }

  static class UnavailableAsrDeterministicProviderGateway extends DeterministicAiProviderGateway {
    @Override
    public TranscribeResult transcribe(String audioRef, String languageHint) {
      return new TranscribeResult("", 0, "provider_unavailable");
    }
  }
}
