import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_client.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_projection.dart';

void main() {
  group('CommercialEntitlementProjection', () {
    test(
      'parses backend entitlement projection without product-plan leakage',
      () {
        final DateTime fetchedAt = DateTime.utc(2026, 6, 10, 8);
        final CommercialEntitlementProjection projection =
            CommercialEntitlementProjection.fromJson(<String, dynamic>{
              'plan': 'pro',
              'status': 'active',
              'features': <String, dynamic>{
                'advanced_scenarios': true,
                'offline_learning_pack': false,
              },
              'valid_until': '2026-06-11T08:00:00Z',
              'generated_at': '2026-06-10T07:59:00Z',
            }, fetchedAt: fetchedAt);

        expect(projection.plan, 'pro');
        expect(projection.status, 'active');
        expect(projection.hasFeature('advanced_scenarios'), isTrue);
        expect(projection.hasFeature('offline_learning_pack'), isFalse);
        expect(projection.validUntil, DateTime.utc(2026, 6, 11, 8));
        expect(projection.generatedAt, DateTime.utc(2026, 6, 10, 7, 59));
        expect(projection.isFreshActivePaid(now: fetchedAt), isTrue);
        expect(
          projection
              .requireFeature(
                'advanced_scenarios',
                now: fetchedAt.add(const Duration(minutes: 1)),
              )
              .allowed,
          isTrue,
        );
      },
    );

    test(
      'fails paid gates closed for stale, expired, revoked, and missing feature',
      () {
        final DateTime now = DateTime.utc(2026, 6, 10, 8);
        final CommercialEntitlementProjection activePro =
            CommercialEntitlementProjection.fromJson(<String, dynamic>{
              'plan': 'pro',
              'status': 'active',
              'features': <String, dynamic>{'advanced_scenarios': true},
              'validUntil': '2026-06-11T08:00:00Z',
            }, fetchedAt: now);

        expect(
          activePro
              .requireFeature(
                'advanced_scenarios',
                now: now.add(const Duration(minutes: 16)),
              )
              .code,
          CommercialEntitlementDecisionCode.stale,
        );

        expect(
          activePro
              .copyWith(validUntil: now.subtract(const Duration(seconds: 1)))
              .requireFeature('advanced_scenarios', now: now)
              .code,
          CommercialEntitlementDecisionCode.expired,
        );

        expect(
          activePro
              .copyWith(status: CommercialEntitlementProjection.revokedStatus)
              .requireFeature('advanced_scenarios', now: now)
              .code,
          CommercialEntitlementDecisionCode.revoked,
        );

        expect(
          activePro
              .copyWith(status: CommercialEntitlementProjection.refundedStatus)
              .requireFeature('advanced_scenarios', now: now)
              .code,
          CommercialEntitlementDecisionCode.revoked,
        );

        expect(
          activePro.requireFeature('offline_learning_pack', now: now).code,
          CommercialEntitlementDecisionCode.featureNotIncluded,
        );
      },
    );

    test('fails paid gates closed for unavailable refresh states', () {
      final DateTime now = DateTime.utc(2026, 6, 10, 8);
      final CommercialEntitlementProjection activePro =
          CommercialEntitlementProjection.fromJson(<String, dynamic>{
            'plan': 'pro',
            'status': 'active',
            'features': <String, dynamic>{'advanced_scenarios': true},
            'validUntil': '2026-06-11T08:00:00Z',
          }, fetchedAt: now);

      expect(
        CommercialEntitlementProjection.unknown()
            .requireFeature('advanced_scenarios', now: now)
            .code,
        CommercialEntitlementDecisionCode.unknown,
      );
      expect(
        CommercialEntitlementProjection.refreshing(
          activePro,
        ).requireFeature('advanced_scenarios', now: now).code,
        CommercialEntitlementDecisionCode.refreshing,
      );
      expect(
        CommercialEntitlementProjection.failed(
          activePro,
        ).requireFeature('advanced_scenarios', now: now).code,
        CommercialEntitlementDecisionCode.refreshFailed,
      );
      expect(
        activePro
            .copyWith(refreshState: CommercialEntitlementRefreshState.stale)
            .requireFeature('advanced_scenarios', now: now)
            .code,
        CommercialEntitlementDecisionCode.stale,
      );
      expect(
        CommercialEntitlementProjection.refreshing(
          activePro,
        ).isFreshActivePaid(now: now),
        isFalse,
      );
      expect(
        CommercialEntitlementProjection.refreshing(
          activePro,
        ).isFreshDisplayPaidFromBackendProjection(now: now),
        isFalse,
      );
      expect(
        activePro
            .copyWith(validUntil: now.subtract(const Duration(seconds: 1)))
            .isFreshDisplayPaidFromBackendProjection(now: now),
        isFalse,
      );
    });

    test('does not treat product plans as entitlement tiers', () {
      final DateTime now = DateTime.utc(2026, 6, 10, 8);
      for (final String productPlan in <String>['monthly', 'yearly']) {
        final CommercialEntitlementProjection projection =
            CommercialEntitlementProjection.fromJson(<String, dynamic>{
              'plan': productPlan,
              'status': 'active',
              'features': <String, dynamic>{'advanced_scenarios': true},
              'validUntil': '2026-06-11T08:00:00Z',
            }, fetchedAt: now);

        expect(
          projection.requireFeature('advanced_scenarios', now: now).code,
          CommercialEntitlementDecisionCode.entitlementRequired,
        );
      }
    });

    test('treats malformed entitlement payload as unknown', () {
      final CommercialEntitlementProjection projection =
          CommercialEntitlementProjection.fromJson(<String, dynamic>{
            'features': <String, dynamic>{'advanced_scenarios': true},
          });

      expect(
        projection.refreshState,
        CommercialEntitlementRefreshState.unknown,
      );
      expect(
        projection.requireFeature('advanced_scenarios').code,
        CommercialEntitlementDecisionCode.unknown,
      );
    });

    test(
      'client returns typed projection from injected refresh transport',
      () async {
        final CommercialEntitlementClient client = CommercialEntitlementClient(
          refreshTransport: () async => <String, dynamic>{
            'plan': 'free',
            'status': 'active',
            'features': <String, dynamic>{},
          },
        );

        final CommercialEntitlementProjection projection = await client
            .refreshProjection();

        expect(projection.plan, CommercialEntitlementProjection.freePlan);
        expect(projection.status, CommercialEntitlementProjection.activeStatus);
        expect(
          projection.refreshState,
          CommercialEntitlementRefreshState.fresh,
        );
      },
    );
  });
}
