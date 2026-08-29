package com.speakeasy.identity.provider;

import com.speakeasy.common.ApiException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;

final class AppleIdentityVerifier {
  private final JwtDecoder decoder;

  AppleIdentityVerifier(JwtDecoder decoder) {
    this.decoder = decoder;
  }

  SocialIdentityVerifier.VerifiedIdentity verify(String identityToken, String rawNonce) {
    if (identityToken == null || identityToken.isBlank() || rawNonce == null || rawNonce.isBlank()) {
      throw invalid();
    }
    try {
      Jwt jwt = decoder.decode(identityToken.trim());
      String subject = jwt.getSubject();
      String nonce = jwt.getClaimAsString("nonce");
      if (subject == null || subject.isBlank() || !hash(rawNonce.trim()).equals(nonce)) throw invalid();
      return new SocialIdentityVerifier.VerifiedIdentity(subject);
    } catch (JwtException exception) {
      throw invalid();
    }
  }

  private String hash(String value) {
    try {
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable.", exception);
    }
  }

  private ApiException invalid() {
    return new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Apple identity token is invalid.");
  }
}
