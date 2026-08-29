package com.speakeasy.identity.ratelimit;

import jakarta.servlet.http.HttpServletRequest;
import java.net.Inet4Address;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

public final class ClientNetworkResolver {
  private final List<CidrBlock> trustedProxies;

  public ClientNetworkResolver(List<String> trustedProxyCidrs) {
    this.trustedProxies = (trustedProxyCidrs == null ? List.<String>of() : trustedProxyCidrs).stream()
        .filter(value -> value != null && !value.isBlank())
        .map(CidrBlock::parse)
        .toList();
  }

  public String resolve(HttpServletRequest request) {
    InetAddress direct = parseAddress(request.getRemoteAddr());
    if (direct == null) return "unknown";
    if (!isTrusted(direct)) return normalize(direct);

    List<InetAddress> forwarded = forwardedChain(request);
    if (forwarded == null || forwarded.isEmpty()) return normalize(direct);
    InetAddress candidate = direct;
    for (int index = forwarded.size() - 1; index >= 0; index--) {
      if (!isTrusted(candidate)) break;
      candidate = forwarded.get(index);
    }
    return normalize(candidate);
  }

  private List<InetAddress> forwardedChain(HttpServletRequest request) {
    String forwarded = request.getHeader("Forwarded");
    List<String> rawValues = forwarded == null || forwarded.isBlank()
        ? splitXForwardedFor(request.getHeader("X-Forwarded-For"))
        : splitForwarded(forwarded);
    if (rawValues.isEmpty()) return List.of();

    List<InetAddress> addresses = new ArrayList<>();
    for (String raw : rawValues) {
      InetAddress address = parseAddress(stripAddressDecoration(raw));
      if (address == null) return null;
      addresses.add(address);
    }
    return addresses;
  }

  private List<String> splitXForwardedFor(String value) {
    return value == null || value.isBlank()
        ? List.of()
        : Arrays.stream(value.split(",")).map(String::trim).toList();
  }

  private List<String> splitForwarded(String value) {
    List<String> addresses = new ArrayList<>();
    for (String element : value.split(",")) {
      for (String parameter : element.split(";")) {
        String candidate = parameter.trim();
        if (candidate.toLowerCase(Locale.ROOT).startsWith("for=")) {
          addresses.add(candidate.substring(4).trim());
          break;
        }
      }
    }
    return addresses;
  }

  private String stripAddressDecoration(String raw) {
    String value = raw == null ? "" : raw.trim();
    if (value.startsWith("\"") && value.endsWith("\"") && value.length() > 1) {
      value = value.substring(1, value.length() - 1);
    }
    if (value.startsWith("[")) {
      int end = value.indexOf(']');
      return end > 0 ? value.substring(1, end) : value;
    }
    int colon = value.indexOf(':');
    return colon > 0 && value.indexOf(':', colon + 1) < 0 ? value.substring(0, colon) : value;
  }

  private boolean isTrusted(InetAddress address) {
    return trustedProxies.stream().anyMatch(block -> block.matches(address));
  }

  private InetAddress parseAddress(String value) {
    if (value == null || value.isBlank()) return null;
    String candidate = value.trim();
    boolean numericIpv4 = candidate.matches("[0-9]{1,3}(?:\\.[0-9]{1,3}){3}");
    boolean numericIpv6 = candidate.contains(":") && candidate.matches("[0-9A-Fa-f:.]+");
    if (!numericIpv4 && !numericIpv6) return null;
    try {
      InetAddress address = InetAddress.getByName(candidate);
      if (!(address instanceof Inet4Address) && !(address instanceof Inet6Address)) return null;
      return address;
    } catch (UnknownHostException exception) {
      return null;
    }
  }

  private String normalize(InetAddress address) {
    if (address instanceof Inet4Address) return address.getHostAddress();
    byte[] bytes = address.getAddress();
    return hexGroup(bytes, 0) + ":" + hexGroup(bytes, 2) + ":" + hexGroup(bytes, 4) + ":"
        + hexGroup(bytes, 6) + "::/64";
  }

  private String hexGroup(byte[] bytes, int offset) {
    return Integer.toHexString(((bytes[offset] & 0xff) << 8) | (bytes[offset + 1] & 0xff));
  }

  private record CidrBlock(byte[] network, int prefixLength) {
    static CidrBlock parse(String value) {
      String[] parts = value.trim().split("/", -1);
      InetAddress address;
      try {
        address = InetAddress.getByName(parts[0]);
      } catch (UnknownHostException exception) {
        throw new IllegalArgumentException("Invalid trusted proxy CIDR: " + value, exception);
      }
      int bits = address.getAddress().length * 8;
      int prefix = parts.length == 1 ? bits : Integer.parseInt(parts[1]);
      if (prefix < 0 || prefix > bits) throw new IllegalArgumentException("Invalid trusted proxy CIDR: " + value);
      byte[] network = address.getAddress().clone();
      for (int bit = prefix; bit < bits; bit++) {
        network[bit / 8] &= (byte) ~(1 << (7 - bit % 8));
      }
      return new CidrBlock(network, prefix);
    }

    boolean matches(InetAddress address) {
      byte[] candidate = address.getAddress();
      if (candidate.length != network.length) return false;
      int fullBytes = prefixLength / 8;
      int remainingBits = prefixLength % 8;
      if (!Arrays.equals(Arrays.copyOf(candidate, fullBytes), Arrays.copyOf(network, fullBytes))) return false;
      if (remainingBits == 0) return true;
      int mask = 0xff << (8 - remainingBits);
      return (candidate[fullBytes] & mask) == (network[fullBytes] & mask);
    }
  }
}
