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

@SpringBootTest(properties = "speakeasy.auth.providers.mode=disabled")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthProviderFailClosedHttpTest {
  @Autowired MockMvc mvc;

  @Test
  void defaultDisabledProviderNeverAcceptsAnUnverifiedPhoneCode() throws Exception {
    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "+8613800138000",
                  "verification_code": "123456",
                  "terms_accepted": true
                }
                """))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("PROVIDER_UNAVAILABLE"));
  }
}
