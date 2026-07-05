package com.speakeasy.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(prefix = "speakeasy.ai", name = "provider", havingValue = "dashscope")
public class JavaDashScopeHttpTransport implements DashScopeHttpTransport {
  private final HttpClient client = HttpClient.newHttpClient();
  private final ObjectMapper mapper;

  public JavaDashScopeHttpTransport(ObjectMapper mapper) {
    this.mapper = mapper;
  }

  @Override
  public JsonNode postJson(String url, JsonNode body, Map<String, String> headers, Duration timeout) {
    try {
      HttpRequest.Builder builder =
          HttpRequest.newBuilder(URI.create(url))
              .timeout(timeout)
              .POST(HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(body)));
      headers.forEach(builder::header);
      HttpResponse<String> response = client.send(builder.build(), HttpResponse.BodyHandlers.ofString());
      return decode(response.statusCode(), response.body());
    } catch (Exception e) {
      throw new ProviderTransportException("dashscope post failed", e);
    }
  }

  @Override
  public JsonNode getJson(String url, Map<String, String> headers, Duration timeout) {
    try {
      HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(url)).timeout(timeout).GET();
      headers.forEach(builder::header);
      HttpResponse<String> response = client.send(builder.build(), HttpResponse.BodyHandlers.ofString());
      return decode(response.statusCode(), response.body());
    } catch (Exception e) {
      throw new ProviderTransportException("dashscope get failed", e);
    }
  }

  private JsonNode decode(int statusCode, String body) throws Exception {
    if (statusCode < 200 || statusCode >= 300) {
      throw new ProviderTransportException("dashscope status " + statusCode);
    }
    return mapper.readTree(body == null || body.isBlank() ? "{}" : body);
  }

  public static class ProviderTransportException extends RuntimeException {
    public ProviderTransportException(String message) {
      super(message);
    }

    public ProviderTransportException(String message, Throwable cause) {
      super(message, cause);
    }
  }
}
