package com.speakeasy.common;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Collections;
import java.util.Enumeration;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestIdFilter extends OncePerRequestFilter {
  public static final String HEADER_NAME = "X-Request-Id";
  private static final String MDC_KEY = "request_id";
  private static final Pattern SAFE_REQUEST_ID = Pattern.compile("[A-Za-z0-9._:-]{1,128}");

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    String requestId = resolve(request.getHeader(HEADER_NAME));
    HttpServletRequest wrapped = new RequestIdRequestWrapper(request, requestId);
    response.setHeader(HEADER_NAME, requestId);
    MDC.put(MDC_KEY, requestId);
    try {
      filterChain.doFilter(wrapped, response);
    } finally {
      MDC.remove(MDC_KEY);
    }
  }

  private String resolve(String supplied) {
    if (supplied != null) {
      String candidate = supplied.trim();
      if (SAFE_REQUEST_ID.matcher(candidate).matches()) {
        return candidate;
      }
    }
    return UUID.randomUUID().toString();
  }

  private static final class RequestIdRequestWrapper extends HttpServletRequestWrapper {
    private final String requestId;

    private RequestIdRequestWrapper(HttpServletRequest request, String requestId) {
      super(request);
      this.requestId = requestId;
    }

    @Override
    public String getHeader(String name) {
      return HEADER_NAME.equalsIgnoreCase(name) ? requestId : super.getHeader(name);
    }

    @Override
    public Enumeration<String> getHeaders(String name) {
      return HEADER_NAME.equalsIgnoreCase(name)
          ? Collections.enumeration(Collections.singleton(requestId))
          : super.getHeaders(name);
    }

    @Override
    public Enumeration<String> getHeaderNames() {
      Set<String> names = new LinkedHashSet<>();
      Enumeration<String> existing = super.getHeaderNames();
      if (existing != null) {
        while (existing.hasMoreElements()) {
          names.add(existing.nextElement());
        }
      }
      names.add(HEADER_NAME);
      return Collections.enumeration(names);
    }
  }
}
