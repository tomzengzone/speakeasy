import 'package:speakeasy/services/api_client.dart';

import 'commercial_entitlement_projection.dart';

typedef EntitlementRefreshTransport = Future<Map<String, dynamic>> Function();

class CommercialEntitlementClient {
  CommercialEntitlementClient({EntitlementRefreshTransport? refreshTransport})
    : _refreshTransport = refreshTransport ?? ApiClient.refreshEntitlements;

  final EntitlementRefreshTransport _refreshTransport;

  Future<Map<String, dynamic>> refreshEntitlements() {
    return _refreshTransport();
  }

  Future<CommercialEntitlementProjection> refreshProjection() async {
    final Map<String, dynamic> entitlement = await refreshEntitlements();
    return CommercialEntitlementProjection.fromJson(entitlement);
  }
}
