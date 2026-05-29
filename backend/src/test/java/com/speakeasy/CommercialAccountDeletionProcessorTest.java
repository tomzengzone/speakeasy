package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CommercialAccountDeletionProcessorTest extends BackendIntegrationTestSupport {
  @Test
  void accountDeletionIsIdempotentForTheSameRequestKeyAfterSessionRevocation() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138410");
    String idempotencyKey = "commercial-delete-013";

    MvcResult first = mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", idempotencyKey)
            .header("X-Request-Id", "req_delete_013_first"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.deletion_job_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.status").value("completed"))
        .andReturn();

    String deletionJobId = JsonPath.read(first.getResponse().getContentAsString(), "$.deletion_job_id");

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", idempotencyKey)
            .header("X-Request-Id", "req_delete_013_retry"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.deletion_job_id").value(deletionJobId))
        .andExpect(jsonPath("$.status").value("completed"));

    UUID userId = UUID.fromString(tokens.userId());
    assertThat(deletionJobs.findByUserIdAndIdempotencyKey(userId, idempotencyKey)).isPresent();
    assertThat(auditLogs.count()).isEqualTo(1);
  }
}
