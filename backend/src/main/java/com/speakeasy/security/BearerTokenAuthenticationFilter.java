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

  public BearerTokenAuthenticationFilter(
      AuthService authService,
      ObjectMapper objectMapper,
      @Value("${speakeasy.ops.bearer-token:}") String opsBearerToken) {
    this.authService = authService;
    this.objectMapper = objectMapper;
    this.opsBearerTokenHash = opsBearerToken == null || opsBearerToken.isBlank() ? "" : TokenHasher.hash(opsBearerToken.trim());
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
    CurrentUser currentUser = authService.authenticateAccessToken(token).orElse(null);
    if (currentUser == null) {
      if (isOpsRequest(request) && isOpsToken(token)) {
        UsernamePasswordAuthenticationToken authentication =
            new UsernamePasswordAuthenticationToken("ops", token, List.of(new SimpleGrantedAuthority("ROLE_OPS")));
        SecurityContextHolder.getContext().setAuthentication(authentication);
        filterChain.doFilter(request, response);
        return;
      }
      currentUser = deletionRetryUser(request, token);
    }

    if (currentUser == null) {
      SecurityContextHolder.clearContext();
      writeUnauthorized(request, response);
      return;
    }

    UsernamePasswordAuthenticationToken authentication =
        new UsernamePasswordAuthenticationToken(currentUser, token, List.of(new SimpleGrantedAuthority("ROLE_USER")));
    SecurityContextHolder.getContext().setAuthentication(authentication);
    filterChain.doFilter(request, response);
  }

  private boolean isOpsToken(String token) {
    return !opsBearerTokenHash.isBlank() && opsBearerTokenHash.equals(TokenHasher.hash(token));
  }

  private boolean isOpsRequest(HttpServletRequest request) {
    return request.getRequestURI().contains("/admin/");
  }

  private CurrentUser deletionRetryUser(HttpServletRequest request, String token) {
    if (!"DELETE".equalsIgnoreCase(request.getMethod()) || !request.getRequestURI().endsWith("/user/me")) {
      return null;
    }
    return authService.authenticateAccountDeletionRetry(token, request.getHeader("Idempotency-Key")).orElse(null);
  }

  private void writeUnauthorized(HttpServletRequest request, HttpServletResponse response) throws IOException {
    response.setStatus(HttpStatus.UNAUTHORIZED.value());
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    String requestId = request.getHeader("X-Request-Id");
    objectMapper.writeValue(response.getOutputStream(),
        ErrorResponse.of("UNAUTHENTICATED", "Authentication required.", requestId == null ? "unknown" : requestId));
  }
}
