package com.speakeasy.identity;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.identity.AuthIdentityRepository;
import com.speakeasy.identity.AuthSessionRepository;
import com.speakeasy.identity.OtpChallengeRepository;
import com.speakeasy.identity.OtpFailureLockRepository;
import com.speakeasy.identity.OtpRateCounterRepository;
import com.speakeasy.identity.OtpSmsProvider;
import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.identity.UserProfileRepository;
import com.speakeasy.ops.AuditLogRepository;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;

abstract class OtpIntegrationTestSupport {
  private static final Pattern OTP_CODE_PATTERN = Pattern.compile("\\b(\\d{6,})\\b");

  @Autowired protected MockMvc mvc;
  @Autowired protected OtpChallengeRepository challenges;
  @Autowired protected OtpRateCounterRepository rateCounters;
  @Autowired protected OtpFailureLockRepository failureLocks;
  @Autowired protected AuditLogRepository auditLogs;
  @Autowired protected AuthSessionRepository sessions;
  @Autowired protected AuthIdentityRepository identities;
  @Autowired protected UserProfileRepository profiles;
  @Autowired protected UserAccountRepository users;
  @MockBean protected OtpSmsProvider smsProvider;

  @BeforeEach
  void cleanOtpData() {
    sessions.deleteAll();
    identities.deleteAll();
    profiles.deleteAll();
    users.deleteAll();
    challenges.deleteAll();
    rateCounters.deleteAll();
    failureLocks.deleteAll();
    auditLogs.deleteAll();
  }

  protected MvcResult sendOtp(String phoneNumber) throws Exception {
    return requestOtp(phoneNumber)
        .andExpect(status().isOk())
        .andReturn();
  }

  protected ResultActions requestOtp(String phoneNumber) throws Exception {
    return requestOtp(phoneNumber, "device-otp-test", "install-otp-test");
  }

  protected ResultActions requestOtp(String phoneNumber, String deviceId, String installId) throws Exception {
    return mvc.perform(post("/auth/otp/send")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "%s",
                  "terms_accepted": true,
                  "consent_version": "terms-privacy-v1",
                  "device_id": "%s",
                  "install_id": "%s"
                }
                """.formatted(phoneNumber, deviceId, installId)));
  }

  protected String challengeId(MvcResult result) throws Exception {
    return JsonPath.read(result.getResponse().getContentAsString(), "$.challenge_id");
  }

  protected String extractCode(String message) {
    Matcher matcher = OTP_CODE_PATTERN.matcher(message);
    if (!matcher.find()) {
      throw new AssertionError("OTP message did not contain a code: " + message);
    }
    return matcher.group(1);
  }

  protected ResultActions loginOtp(String challengeId, String phoneNumber, String code) throws Exception {
    return mvc.perform(post("/auth/login/phone")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 2,
              "challenge_id": "%s",
              "phone_number": "%s",
              "verification_code": "%s",
              "terms_accepted": true
            }
            """.formatted(challengeId, phoneNumber, code)));
  }

  protected String wrongCode(String correctCode) {
    return "000000".equals(correctCode) ? "111111" : "000000";
  }
}
