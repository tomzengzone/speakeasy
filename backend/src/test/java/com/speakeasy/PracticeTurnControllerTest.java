package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ai.AiGatewayService;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PracticeTurnControllerTest extends BackendIntegrationTestSupport {
  @Autowired AiGatewayService gateway;

  @Test
  void submitTurnPersistsFeedbackAndFetchReturnsLatestMessages() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138250");
    String sessionId = startSession(tokens);

    MvcResult turnResult = submitTurn(tokens, sessionId, "turn-1", "I worked on a project that improved our workflow.")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session_status").value("feedback"))
        .andExpect(jsonPath("$.user_message.text").value("I worked on a project that improved our workflow."))
        .andExpect(jsonPath("$.coach_feedback.feedback_type").value("next_question"))
        .andExpect(jsonPath("$.coach_feedback.score_signal.status").value("available"))
        .andExpect(jsonPath("$.learning_evidence_candidates", hasSize(1)))
        .andReturn();

    String userMessageId = JsonPath.read(turnResult.getResponse().getContentAsString(), "$.user_message.message_id");

    mvc.perform(get("/practice/sessions/%s".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session.status").value("feedback"))
        .andExpect(jsonPath("$.session.current_turn_index").value(1))
        .andExpect(jsonPath("$.session.messages", hasSize(2)));

    MvcResult replayResult = submitTurn(tokens, sessionId, "turn-1", "I worked on a project that improved our workflow.")
        .andExpect(status().isOk())
        .andReturn();
    assertThat(JsonPath.<String>read(replayResult.getResponse().getContentAsString(), "$.user_message.message_id"))
        .isEqualTo(userMessageId);
  }

  @Test
  void reusedIdempotencyKeyWithDifferentPayloadIsRejected() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138251");
    String sessionId = startSession(tokens);
    submitTurn(tokens, sessionId, "same-key", "First answer").andExpect(status().isOk());

    submitTurn(tokens, sessionId, "same-key", "Different answer")
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error.code").value("IDEMPOTENCY_CONFLICT"));
  }

  @Test
  void tcMvpBe047RejectsTranscriptTurnWithUntrustedAudioRefBeforePersistenceOrProviderCall() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138252");
    String sessionId = startSession(tokens);
    gateway.resetInvocationCount();

    submitTurnWithAudioRef(
            tokens,
            sessionId,
            "invalid-audio-ref",
            "I worked on a project that improved our workflow.",
            "/tmp/local-answer.wav")
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"))
        .andExpect(jsonPath("$.error.details.media_error").value("unsupported_media_ref"));

    assertThat(practiceTurns.findBySessionIdOrderByTurnIndexAsc(UUID.fromString(sessionId))).isEmpty();
    assertThat(coachFeedbacks.count()).isZero();
    assertThat(gateway.invocationCount()).isZero();
  }

  @Test
  void tcMvpBe048RejectsCrossUserValidatedAudioRefBeforePersistenceOrProviderCall() throws Exception {
    AuthTokens owner = loginPhone("+8613800138253");
    String ownerAudioRef = createValidatedAudioRef(owner, "practice-owner-upload", "checksum-practice-owner");
    AuthTokens otherUser = loginPhone("+8613800138254");
    String sessionId = startSession(otherUser);
    gateway.resetInvocationCount();

    submitTurnWithAudioRef(
            otherUser,
            sessionId,
            "cross-user-audio-ref",
            "I worked on a project that improved our workflow.",
            ownerAudioRef)
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"))
        .andExpect(jsonPath("$.error.details.media_error").value("media_not_found"));

    assertThat(practiceTurns.findBySessionIdOrderByTurnIndexAsc(UUID.fromString(sessionId))).isEmpty();
    assertThat(coachFeedbacks.count()).isZero();
    assertThat(gateway.invocationCount()).isZero();
  }

  private org.springframework.test.web.servlet.ResultActions submitTurn(
      AuthTokens tokens, String sessionId, String key, String transcript) throws Exception {
    return mvc.perform(post("/practice/sessions/%s/turns".formatted(sessionId))
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("Idempotency-Key", key)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "transcript": "%s"
            }
            """.formatted(transcript)));
  }

  private org.springframework.test.web.servlet.ResultActions submitTurnWithAudioRef(
      AuthTokens tokens, String sessionId, String key, String transcript, String audioRef) throws Exception {
    return mvc.perform(post("/practice/sessions/%s/turns".formatted(sessionId))
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("Idempotency-Key", key)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "transcript": "%s",
              "audio_ref": "%s"
            }
            """.formatted(transcript, audioRef)));
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
        .andExpect(jsonPath("$.session.session_id", not(blankOrNullString())))
        .andReturn();
    return JsonPath.read(result.getResponse().getContentAsString(), "$.session.session_id");
  }

  private String createValidatedAudioRef(AuthTokens tokens, String clientUploadId, String checksum) throws Exception {
    MvcResult create = mvc.perform(post("/media/audio/uploads")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", clientUploadId)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "purpose": "asr_input",
                  "content_type": "audio/m4a",
                  "byte_size": 240000,
                  "duration_seconds": 12,
                  "checksum_sha256": "%s",
                  "client_upload_id": "%s"
                }
                """.formatted(checksum, clientUploadId)))
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
                  "checksum_sha256": "%s"
                }
                """.formatted(checksum)))
        .andExpect(status().isOk());
    return audioRef;
  }
}
