import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/core/routing/app_router.dart';
import 'package:speakeasy/core/routing/app_routes.dart';

void main() {
  test('device sessions route is registered', () {
    final Route<dynamic>? route = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRoutes.deviceSessions),
    );

    expect(route, isA<MaterialPageRoute<dynamic>>());
  });
}
