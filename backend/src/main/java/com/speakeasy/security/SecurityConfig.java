package com.speakeasy.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.common.ErrorResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
public class SecurityConfig {
  @Bean
  SecurityFilterChain securityFilterChain(
      HttpSecurity http, BearerTokenAuthenticationFilter bearerTokenAuthenticationFilter, ObjectMapper objectMapper)
      throws Exception {
    http.csrf(AbstractHttpConfigurer::disable)
        .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers(HttpMethod.POST, "/auth/login/phone", "/auth/login/apple", "/auth/login/wechat",
                "/auth/refresh", "/auth/verification-codes/phone",
                "/auth/account-recovery/phone/verification-codes", "/auth/account-recovery/phone")
            .permitAll()
            .requestMatchers(HttpMethod.POST, "/subscriptions/webhook/apple", "/subscriptions/webhook/google")
            .permitAll()
            .requestMatchers(HttpMethod.GET, "/subscription/plans")
            .permitAll()
            .requestMatchers("/actuator/**")
            .hasRole("OPS")
            .requestMatchers("/admin/**")
            .hasRole("OPS")
            .requestMatchers("/auth/logout", "/auth/logout-*", "/auth/sessions/**")
            .hasAuthority(AuthScopes.authority(AuthScopes.SESSION_MANAGE))
            .requestMatchers(HttpMethod.GET, "/user/**")
            .hasAuthority(AuthScopes.authority(AuthScopes.USER_READ))
            .requestMatchers(HttpMethod.PATCH, "/user/**")
            .hasAuthority(AuthScopes.authority(AuthScopes.USER_WRITE))
            .requestMatchers(HttpMethod.DELETE, "/user/**")
            .hasAuthority(AuthScopes.authority(AuthScopes.USER_WRITE))
            .requestMatchers(HttpMethod.GET, "/scenarios/**", "/courses/**", "/home/**")
            .hasAuthority(AuthScopes.authority(AuthScopes.COURSE_READ))
            .requestMatchers("/ai/**", "/media/**")
            .hasAuthority(AuthScopes.authority(AuthScopes.AI_USE))
            .requestMatchers(HttpMethod.GET, "/learning/**", "/review/**", "/favorites/**", "/expressions/**",
                "/goal-autopilot/**", "/training/**", "/practice/**")
            .hasAuthority(AuthScopes.authority(AuthScopes.LEARNING_READ))
            .requestMatchers("/learning/**", "/review/**", "/favorites/**", "/expressions/**",
                "/goal-autopilot/**", "/training/**", "/practice/**", "/onboarding/**", "/user/scenarios/**")
            .hasAuthority(AuthScopes.authority(AuthScopes.LEARNING_WRITE))
            .anyRequest()
            .hasAuthority(AuthScopes.authority(AuthScopes.USER_READ)))
        .exceptionHandling(exceptions -> exceptions
            .authenticationEntryPoint((request, response, exception) ->
                writeError(objectMapper, request, response, HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Authentication required."))
            .accessDeniedHandler((request, response, exception) ->
                writeError(
                    objectMapper,
                    request,
                    response,
                    HttpStatus.FORBIDDEN,
                    insufficientScope(request) ? "INSUFFICIENT_SCOPE" : "FORBIDDEN",
                    insufficientScope(request) ? "Required scope is missing." : "Access denied.")))
        .addFilterBefore(bearerTokenAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
    return http.build();
  }

  @Bean
  UserDetailsService userDetailsService() {
    return username -> {
      throw new UsernameNotFoundException(username);
    };
  }

  private static void writeError(
      ObjectMapper objectMapper,
      HttpServletRequest request,
      HttpServletResponse response,
      HttpStatus status,
      String code,
      String message)
      throws IOException {
    response.setStatus(status.value());
    response.setHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE);
    String requestId = request.getHeader("X-Request-Id");
    objectMapper.writeValue(
        response.getOutputStream(), ErrorResponse.of(code, message, requestId == null ? "unknown" : requestId));
  }

  private static boolean insufficientScope(HttpServletRequest request) {
    var authentication = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
    Object principal = authentication == null ? null : authentication.getPrincipal();
    String path = request.getRequestURI();
    return principal instanceof CurrentUser && !path.contains("/admin/") && !path.contains("/actuator/");
  }
}
