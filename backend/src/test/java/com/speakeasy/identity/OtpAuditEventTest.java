package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import com.speakeasy.ops.AuditLog;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpAuditEventTest extends OtpIntegrationTestSupport {
  @Test
  void otpAuditEventsAreRedactedAndCarryRetentionPolicyVersion() throws Exception {
    MvcResult send = sendOtp("13800138108");
    String challengeId = challengeId(send);
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(eq("+8613800138108"), messageCaptor.capture());
    String code = extractCode(messageCaptor.getValue());

    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "challenge_id": "%s",
                  "phone_number": "13800138108",
                  "verification_code": "%s",
                  "terms_accepted": true
                }
                """.formatted(challengeId, wrongCode(code))));

    String auditText = auditLogs.findAll().stream()
        .map(AuditLog::getRedactedDetails)
        .collect(Collectors.joining("\n"));

    assertThat(auditText).contains("phone_hash", "retention_policy_version");
    assertThat(auditText).doesNotContain(code, "13800138108", "+8613800138108");
  }
}
