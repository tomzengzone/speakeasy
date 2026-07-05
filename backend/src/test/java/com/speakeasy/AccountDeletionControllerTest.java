package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AccountDeletionControllerTest extends BackendIntegrationTestSupport {
  @Test
  void accountDeletionCompletesJobAndReturnsUnderstandableStatus() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138370");

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "delete-job-033")
            .header("X-Request-Id", "req_delete_033"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.deletion_job_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.status").value("completed"))
        .andExpect(jsonPath("$.requested_at", not(blankOrNullString())))
        .andExpect(jsonPath("$.completed_at", not(blankOrNullString())));
  }
}
