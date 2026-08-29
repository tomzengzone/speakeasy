package com.speakeasy.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.common.ErrorResponse;
import com.speakeasy.identity.AuthService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class BearerTokenAuthenticationFilter extends OncePerRequestFilter {
  private final AuthService authService;
  private final ObjectMapper objectMapper;
  private final String opsBearerTokenHash;
  private final String opsPrincipalId;

  public BearerTokenAuthenticationFilter(
      AuthService authService,
      ObjectMapper objectMapper,
      @Value("${speakeasy.ops.bearer-token:}") String opsBearerToken,
      @Value("${speakeasy.ops.principal-id:shared-ops-token}") String opsPrincipalId) {
    this.authService = authService;
    this.objectMapper = objectMapper;
    this.opsBearerTokenHash = opsBearerToken == null || opsBearerToken.isBlank() ? "" : TokenHasher.hash(opsBearerToken.trim());
    this.opsPrincipalId = opsPrincipalId == null || opsPrincipalId.isBlank() ? "shared-ops-token" : opsPrincipalId.trim();
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    String header = request.getHeader(HttpHeaders.AUTHORIZATION);
    if (header == null || !header.startsWith("Bearer ")) {
      filterChain.doFilter(request, response);
      return;
    }

    String token = header.substring("Bearer ".length()).trim();
    if (isOpsRequest(request) && isOpsToken(token)) {
      UsernamePasswordAuthenticationToken authentication =
          new UsernamePasswordAuthenticationToken(opsPrincipalId, null, List.of(new SimpleGrantedAuthority("ROLE_OPS")));
      SecurityContextHolder.getContext().setAuthentication(authentication);
      filterChain.doFilter(request, response);
      return;
    }

    AuthService.AccessTokenInspection inspection = authService.inspectAccessToken(token);
    CurrentUser currentUser = inspection.currentUser();
    if (currentUser == null) currentUser = deletionRetryUser(request, token);

    if (currentUser == null) {
      SecurityContextHolder.clearContext();
      writeUnauthorized(request, response, inspection.code());
      return;
    }

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(currentUser, null, List.of(new SimpleGrantedAuthority("ROLE_USER")));
    SecurityContextHolder.getContext().setAuthentication(authentication);
    filterChain.doFilter(request, response);
  }

  private boolean isOpsToken(String token) {
    return !opsBearerTokenHash.isBlank() && opsBearerTokenHash.equals(TokenHasher.hash(token));
  }

  private boolean isOpsRequest(HttpServletRequest request) {
    return request.getRequestURI().contains("/admin/") || request.getRequestURI().contains("/actuator/");
  }

  private CurrentUser deletionRetryUser(HttpServletRequest request, String token) {
    if (!"DELETE".equalsIgnoreCase(request.getMethod()) || !request.getRequestURI().endsWith("/user/me")) {
      return null;
    }
    return authService.authenticateAccountDeletionRetry(token, request.getHeader("Idempotency-Key")).orElse(null);
  }

  private void writeUnauthorized(HttpServletRequest request, HttpServletResponse response, String code) throws IOException {
    response.setStatus(HttpStatus.UNAUTHORIZED.value());
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    String requestId = request.getHeader("X-Request-Id");
    objectMapper.writeValue(response.getOutputStream(),
        ErrorResponse.of(code, messageFor(code), requestId == null ? "unknown" : requestId));
  }

  private String messageFor(String code) {
    return switch (code) {
      case "ACCESS_TOKEN_EXPIRED" -> "Access token has expired.";
      case "SESSION_REVOKED" -> "Session has been revoked.";
      case "ACCOUNT_DISABLED" -> "Account is disabled.";
      default -> "Access token is invalid.";
    };
  }
}
