package com.speakeasy.identity.ratelimit;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

class ClientNetworkResolverTest {
  @Test
  void ignoresForwardedHeadersFromUntrustedPeers() {
    ClientNetworkResolver resolver = new ClientNetworkResolver(List.of("10.0.0.0/8"));
    MockHttpServletRequest request = request("203.0.113.8", "198.51.100.9, 10.1.2.3");

    assertThat(resolver.resolve(request)).isEqualTo("203.0.113.8");
  }

  @Test
  void resolvesFirstUntrustedAddressFromTrustedProxyChain() {
    ClientNetworkResolver resolver = new ClientNetworkResolver(List.of("10.0.0.0/8", "192.168.0.0/16"));
    MockHttpServletRequest request = request("10.0.0.4", "198.51.100.9, 192.168.1.2");

    assertThat(resolver.resolve(request)).isEqualTo("198.51.100.9");
  }

  @Test
  void normalizesIpv6ClientsToNetworkPrefix() {
    ClientNetworkResolver resolver = new ClientNetworkResolver(List.of());
    MockHttpServletRequest request = request("2001:db8:1234:5678:abcd::1", null);

    assertThat(resolver.resolve(request)).isEqualTo("2001:db8:1234:5678::/64");
  }

  @Test
  void rejectsMalformedForwardedValuesWithoutTrustingThem() {
    ClientNetworkResolver resolver = new ClientNetworkResolver(List.of("10.0.0.0/8"));
    MockHttpServletRequest request = request("10.0.0.4", "not-an-ip, 192.168.1.2");

    assertThat(resolver.resolve(request)).isEqualTo("10.0.0.4");
  }

  private MockHttpServletRequest request(String remoteAddress, String forwardedFor) {
    MockHttpServletRequest request = new MockHttpServletRequest();
    request.setRemoteAddr(remoteAddress);
    if (forwardedFor != null) request.addHeader("X-Forwarded-For", forwardedFor);
    return request;
  }
}
