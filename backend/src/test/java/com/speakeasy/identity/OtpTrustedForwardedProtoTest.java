package com.speakeasy.identity;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(properties = {
    "speakeasy.identity.otp.enforce-secure-transport=true",
    "speakeasy.identity.otp.trust-forwarded-proto=true"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpTrustedForwardedProtoTest extends OtpIntegrationTestSupport {
  @Test
  void trustedForwardedProtoAllowsOtpSendThroughConfiguredProxyBoundary() throws Exception {
    mvc.perform(post("/auth/otp/send")
            .contentType(MediaType.APPLICATION_JSON)
            .header("X-Forwarded-Proto", "https")
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "13800138113",
                  "terms_accepted": true,
                  "consent_version": "terms-privacy-v1"
                }
                """))
        .andExpect(status().isOk());

    verify(smsProvider).send(anyString(), anyString());
  }
}
