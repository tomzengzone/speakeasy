package com.speakeasy.identity.provider;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.speakeasy.common.ApiException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;

class AppleIdentityVerifierTest {
  @Test
  void acceptsOnlyATokenBoundToTheOriginalNonce() throws Exception {
    JwtDecoder decoder = mock(JwtDecoder.class);
    String rawNonce = "raw-random-nonce";
    Jwt jwt = new Jwt(
        "identity-token",
        Instant.parse("2026-08-29T00:00:00Z"),
        Instant.parse("2026-08-29T00:05:00Z"),
        Map.of("alg", "ES256"),
        Map.of("sub", "apple-user-123", "nonce", sha256(rawNonce)));
    when(decoder.decode("identity-token")).thenReturn(jwt);
    AppleIdentityVerifier verifier = new AppleIdentityVerifier(decoder);

    assertThat(verifier.verify("identity-token", rawNonce).subject())
        .isEqualTo("apple-user-123");
    assertThatThrownBy(() -> verifier.verify("identity-token", "wrong-nonce"))
        .isInstanceOf(ApiException.class)
        .extracting("code")
        .isEqualTo("UNAUTHENTICATED");
  }

  private String sha256(String value) throws Exception {
    return HexFormat.of().formatHex(
        MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
  }
}
