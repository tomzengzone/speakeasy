from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/check_cross_cutting_boundaries.py"
SPEC = importlib.util.spec_from_file_location("check_cross_cutting_boundaries", SCRIPT)
assert SPEC is not None
ccb = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules["check_cross_cutting_boundaries"] = ccb
SPEC.loader.exec_module(ccb)


class CrossCuttingBoundaryCheckTest(unittest.TestCase):
    def test_xcb004_blocks_local_paid_gate_sources(self) -> None:
        path = ROOT / "lib/pages/paywall.dart"
        text = """
        final allowed = session.isPro;
        final scoped = AppSessionScope.of(context).isPro;
        final provider = ref.read(appSessionProvider).isPro;
        final nullable = session?.isPro;
        final parenthesized = (session).isPro;
        final blocked = memberPlan != 'free';
        final current = currentPlan == 'free';
        final legacy = hasProEntitlement;
        CommercialScenarioGate.canAccess(targetLevel: 'L3', isPro: allowed);
        """

        violations = ccb.check_flutter_commercial_gate_sources(path, text)

        self.assertGreaterEqual(len(violations), 9)
        self.assertTrue(all(item.boundary_id == "XCB-004" for item in violations))

    def test_xcb004_blocks_app_session_rebuilding_entitlement_from_member_plan(self) -> None:
        path = ROOT / "lib/services/app_session.dart"
        text = """
        bool get hasActivePaidEntitlement => memberPlan != 'free';
        bool get isPro => hasActivePaidEntitlement;
        String get memberPlan => _user?.memberPlan ?? 'free';
        """

        violations = ccb.check_flutter_commercial_gate_sources(path, text)

        self.assertEqual(len(violations), 1)
        self.assertEqual(violations[0].boundary_id, "XCB-004")

    def test_xcb004_allows_display_only_is_pro_constructor(self) -> None:
        path = ROOT / "lib/pages/profile_page.dart"
        text = """
        const _ProfileBadge({required this.isPro});
        final bool isPro;
        """

        violations = ccb.check_flutter_commercial_gate_sources(path, text)

        self.assertEqual(violations, [])

    def test_xcb004_blocks_legacy_raw_ai_paths(self) -> None:
        path = ROOT / "lib/services/api_client.dart"
        text = """
        await _post('/ai/scene-draft', {});
        await _post('/ai/sessions/$sessionId/message', {});
        final uri = Uri.parse('$base/ai/voice-chat?token=$token');
        """

        violations = ccb.check_flutter_raw_ai_endpoint_paths(path, text)

        self.assertEqual(len(violations), 3)
        self.assertTrue(all(item.boundary_id == "XCB-004" for item in violations))

    def test_xcb004_allows_generated_gateway_constant_usage(self) -> None:
        path = ROOT / "lib/services/api_client.dart"
        text = """
        await _post(SpeakeasyApiPaths.aiCoachTurn, {});
        await _post(SpeakeasyApiPaths.aiTts, {});
        """

        violations = ccb.check_flutter_raw_ai_endpoint_paths(path, text)

        self.assertEqual(violations, [])


if __name__ == "__main__":
    unittest.main()
