package com.speakeasy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(properties = "speakeasy.auth.account-recovery-enabled=invalid")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AccountRecoveryCapabilityInvalidConfigTest {
  @Autowired MockMvc mvc;

  @Test
  void nonExplicitCapabilityValueFailsClosed() throws Exception {
    mvc.perform(post("/auth/account-recovery/phone/verification-codes")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "+8613800138699"
                }
                """))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("AUTH_SERVICE_UNAVAILABLE"));
  }
}
