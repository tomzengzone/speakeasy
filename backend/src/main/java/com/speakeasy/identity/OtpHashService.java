package com.speakeasy.identity;

import com.speakeasy.common.ApiException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public class OtpHashService {
  private static final String HMAC_ALGORITHM = "HmacSHA256";

  private final OtpProperties properties;

  public OtpHashService(OtpProperties properties) {
    this.properties = properties;
  }

  public String hmacDigest(UUID challengeId, String e164Phone, String code) {
    String payload = challengeId + "|" + e164Phone + "|" + code;
    try {
      Mac mac = Mac.getInstance(HMAC_ALGORITHM);
      mac.init(new SecretKeySpec(properties.getHmacSecret().getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM));
      return HexFormat.of().formatHex(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception exception) {
      throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "PROVIDER_UNAVAILABLE", "OTP verifier is unavailable.");
    }
  }

  public boolean constantTimeEquals(String expectedDigest, String candidateDigest) {
    if (expectedDigest == null || candidateDigest == null) {
      return false;
    }
    return MessageDigest.isEqual(
        expectedDigest.getBytes(StandardCharsets.UTF_8),
        candidateDigest.getBytes(StandardCharsets.UTF_8));
  }

  public String sha256(String value) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      return HexFormat.of().formatHex(digest.digest((value == null ? "" : value).getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable.", exception);
    }
  }
}
