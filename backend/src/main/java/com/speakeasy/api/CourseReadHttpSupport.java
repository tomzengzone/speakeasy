package com.speakeasy.api;

import com.speakeasy.security.CurrentUser;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.List;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

final class CourseReadHttpSupport {
  private CourseReadHttpSupport() {}

  static String etag(
      CurrentUser currentUser,
      String normalizedRequest,
      String visibilityRevision,
      String projectionFingerprint) {
    String input = currentUser.userId()
        + "|" + currentUser.sessionId()
        + "|" + normalizedRequest
        + "|" + visibilityRevision
        + "|" + projectionFingerprint;
    try {
      byte[] digest = MessageDigest.getInstance("SHA-256").digest(input.getBytes(StandardCharsets.UTF_8));
      return "\"" + Base64.getUrlEncoder().withoutPadding().encodeToString(digest) + "\"";
    } catch (Exception exception) {
      throw new IllegalStateException("Unable to create content representation fingerprint.", exception);
    }
  }

  static <T> ResponseEntity<T> response(String etag, String ifNoneMatch, T body) {
    HttpHeaders headers = new HttpHeaders();
    headers.setCacheControl("private, no-cache");
    headers.setVary(List.of(HttpHeaders.AUTHORIZATION));
    headers.setETag(etag);
    if (matches(ifNoneMatch, etag)) {
      return new ResponseEntity<>(null, headers, HttpStatus.NOT_MODIFIED);
    }
    return new ResponseEntity<>(body, headers, HttpStatus.OK);
  }

  private static boolean matches(String ifNoneMatch, String etag) {
    if (ifNoneMatch == null || ifNoneMatch.isBlank()) {
      return false;
    }
    if ("*".equals(ifNoneMatch.trim())) {
      return true;
    }
    for (String candidate : ifNoneMatch.split(",")) {
      if (etag.equals(candidate.trim())) {
        return true;
      }
    }
    return false;
  }
}
