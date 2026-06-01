package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
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
class MediaUploadReferenceServiceTest extends BackendIntegrationTestSupport {
  @Test
  void createsIdempotentTrustedAudioRefAndValidatesCompletion() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138400");

    MvcResult createResult = createUpload(tokens, "upload-idem-1", "rec-001")
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.media.media_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.media.audio_ref", org.hamcrest.Matchers.startsWith("media://audio/")))
        .andExpect(jsonPath("$.media.upload_url", org.hamcrest.Matchers.startsWith("https://upload.test.local/audio/")))
        .andExpect(jsonPath("$.media.status").value("pending"))
        .andExpect(jsonPath("$.media.duration_seconds").value(12))
        .andReturn();

    String mediaId = JsonPath.read(createResult.getResponse().getContentAsString(), "$.media.media_id");

    createUpload(tokens, "upload-idem-1", "rec-001")
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.media.media_id").value(mediaId));

    mvc.perform(post("/media/audio/uploads/%s/complete".formatted(mediaId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checksum_sha256": "checksum-1",
                  "object_ref": "object://speakeasy-ai-media/test/audio.m4a"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.media.media_id").value(mediaId))
        .andExpect(jsonPath("$.media.status").value("validated"));
  }

  @Test
  void rejectsUnsupportedAudioUploadMetadata() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138401");

    mvc.perform(post("/media/audio/uploads")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "upload-idem-unsupported")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "purpose": "asr_input",
                  "content_type": "text/plain",
                  "byte_size": 240000,
                  "duration_seconds": 12
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    mvc.perform(post("/media/audio/uploads")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "upload-idem-oversize")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "purpose": "asr_input",
                  "content_type": "audio/m4a",
                  "byte_size": 10000001,
                  "duration_seconds": 12
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.details.max_upload_bytes").value(10000000));
  }

  private org.springframework.test.web.servlet.ResultActions createUpload(
      AuthTokens tokens, String idempotencyKey, String clientUploadId) throws Exception {
    return mvc.perform(post("/media/audio/uploads")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("Idempotency-Key", idempotencyKey)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "purpose": "asr_input",
              "content_type": "audio/m4a",
              "byte_size": 240000,
              "duration_seconds": 12,
              "checksum_sha256": "checksum-1",
              "client_upload_id": "%s"
            }
            """.formatted(clientUploadId)));
  }
}
