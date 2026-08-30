package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import io.micrometer.core.instrument.MeterRegistry;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.auth.metrics-supported-app-versions=42.7")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthHttpMetricsIntegrationTest extends BackendIntegrationTestSupport {
  @Autowired MeterRegistry meterRegistry;

  @Test
  void bearerMetricsCarrySessionPlatformVersionBucketAndServerOwnedApiFamily() throws Exception {
    MvcResult login = mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "+8613800138700",
                  "verification_code": "123456",
                  "terms_accepted": true,
                  "platform": "android",
                  "app_version": "42.7.19-beta"
                }
                """))
        .andExpect(status().isOk())
        .andReturn();
    String accessToken = JsonPath.read(login.getResponse().getContentAsString(), "$.access_token");

    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(accessToken)))
        .andExpect(status().isOk());

    assertThat(meterRegistry.find("speakeasy.auth.http")
        .tags(
            "outcome", "authenticated",
            "reason", "none",
            "platform", "android",
            "app_version", "42.7",
            "api_family", "user")
        .counter()).isNotNull();
  }
}
