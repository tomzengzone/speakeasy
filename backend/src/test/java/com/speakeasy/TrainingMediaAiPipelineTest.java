package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.util.Set;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.ai.provider=deterministic")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class TrainingMediaAiPipelineTest extends BackendIntegrationTestSupport {
  @Test
  void tcP01026TrainingAudioTurnUsesTrustedMediaAsrScoringAndCoachGateway() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138560");
    String sessionId = startTraining(tokens);
    String audioRef = createValidatedAudioRef(tokens);

    mvc.perform(post("/training/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "training-audio-turn")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "%s"
                }
                """.formatted(audioRef)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.turn.transcript").value("I worked on a project that improved our workflow."))
        .andExpect(jsonPath("$.turn.audio_ref", startsWith("media://audio/")))
        .andExpect(jsonPath("$.feedback.provider_status").value("success"))
        .andExpect(jsonPath("$.feedback.pronunciation_available").value(true))
        .andExpect(jsonPath("$.learning_evidence_candidates[0].status").value("accepted"));

    Set<String> capabilities = aiProviderMetrics.findAll().stream()
        .map(com.speakeasy.ai.AiProviderInvocationMetric::getCapability)
        .collect(Collectors.toSet());
    assertThat(capabilities).contains("asr", "scoring", "llm");
  }

  private String startTraining(AuthTokens tokens) throws Exception {
    MvcResult result = mvc.perform(post("/training/sessions")
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

  private String createValidatedAudioRef(AuthTokens tokens) throws Exception {
    MvcResult create = mvc.perform(post("/media/audio/uploads")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "training-audio-upload")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "purpose": "asr_input",
                  "content_type": "audio/m4a",
                  "byte_size": 240000,
                  "duration_seconds": 12,
                  "checksum_sha256": "checksum-training-audio",
                  "client_upload_id": "training-audio-client"
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
                  "checksum_sha256": "checksum-training-audio"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.media.status").value("validated"));
    return audioRef;
  }
}
