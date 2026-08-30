package com.speakeasy.identity;

import java.util.Set;

/** Server-owned policy for the authorization snapshot attached to a newly issued token family. */
public interface AuthGrantPolicy {
  Set<String> scopesFor(LoginContext context);

  record LoginContext(String clientId, String authenticationMethod) {}
}
