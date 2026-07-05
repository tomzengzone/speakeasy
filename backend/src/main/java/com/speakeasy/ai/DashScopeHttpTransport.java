package com.speakeasy.ai;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.Duration;
import java.util.Map;

public interface DashScopeHttpTransport {
  JsonNode postJson(String url, JsonNode body, Map<String, String> headers, Duration timeout);

  JsonNode getJson(String url, Map<String, String> headers, Duration timeout);
}
