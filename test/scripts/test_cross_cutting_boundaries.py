from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path
from unittest import mock

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

    def test_xcb006_ignores_backend_test_audit_fixtures(self) -> None:
        path = ROOT / "backend/src/test/java/com/speakeasy/AdminAuditControllerTest.java"
        text = """
        auditLogs.save(new AuditLog(
            id, "system", "system", "fixture", "audit:redaction",
            "{\\"token\\":\\"secret-token\\",\\"signed_url\\":\\"https://media.test.local/audio.wav?signature=secret-token\\"}",
            "req", now));
        """

        violations = ccb.check_sensitive_payload_exposure(path, text)

        self.assertEqual(violations, [])

    def test_xcb006_blocks_sensitive_migration_without_data_governance_coverage(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120001__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          user_id UUID NOT NULL,
          audio_ref TEXT NOT NULL,
          raw_transcript TEXT,
          provider_payload TEXT
        );
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text="")

        self.assertEqual(len(violations), 1)
        self.assertEqual(violations[0].boundary_id, "XCB-006")
        self.assertIn("diagnostic_audio_samples", violations[0].message)

    def test_xcb006_allows_sensitive_migration_with_existing_governance_coverage(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120001__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          user_id UUID NOT NULL,
          audio_ref TEXT NOT NULL,
          raw_transcript TEXT,
          provider_payload TEXT
        );
        """
        coverage = """
        # backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java
        delete("diagnostic_audio_samples", userId);
        # backend/src/main/java/com/speakeasy/goal/GoalAutopilotService.java
        dataFamily("diagnostic_audio_samples", 1, List.of(), List.of(), List.of(), List.of(),
            "redacted_diagnostic_audio_sample");
        new RetentionRuleView("diagnostic_audio_samples", "hard_delete_on_account_deletion",
            "account_deletion_or_audio_expiry", "exports redacted diagnostic metadata only");
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(violations, [])

    def test_xcb006_ignores_non_sensitive_reference_migration(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120002__content_reference.sql"
        text = """
        CREATE TABLE grammar_catalog_items (
          item_id UUID PRIMARY KEY,
          title TEXT NOT NULL,
          status VARCHAR(40) NOT NULL
        );
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text="")

        self.assertEqual(violations, [])

    def test_xcb006_blocks_sensitive_snake_case_table_name_without_exact_sensitive_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120003__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL,
          created_at TIMESTAMP NOT NULL
        );
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text="")

        self.assertEqual(len(violations), 1)
        self.assertIn("diagnostic_audio_samples", violations[0].message)

    def test_xcb006_does_not_allow_generic_planning_text_as_coverage(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120004__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 diagnostic_audio_samples retention export deletion planned in a future batch.
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_does_not_allow_documented_pseudo_code_as_structured_coverage(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120007__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL
        );
        """
        exception_text = """
        Future implementation plan:
        AccountDeletionService should call delete("diagnostic_audio_samples", userId);
        Or run DELETE FROM diagnostic_audio_samples WHERE user_id = ?;
        """

        violations = ccb.check_xcb006_migration_data_governance(
            path,
            text,
            code_coverage_text="",
            exception_coverage_text=exception_text,
        )

        self.assertEqual(len(violations), 1)

    def test_xcb006_does_not_allow_unrelated_java_pseudo_coverage(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120008__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL
        );
        """
        unrelated_java = """
        class ExampleService {
          // TODO delete("diagnostic_audio_samples", userId);
          void example() {
            repository.delete("diagnostic_audio_samples", userId);
          }
        }
        """

        violations = ccb.check_xcb006_migration_data_governance(
            path,
            text,
            code_coverage_text="",
            exception_coverage_text=unrelated_java,
        )

        self.assertEqual(len(violations), 1)

    def test_xcb006_blocks_sensitive_user_ref_payload_and_token_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120009__notification_delivery.sql"
        text = """
        CREATE TABLE notification_deliveries (
          delivery_id UUID PRIMARY KEY,
          user_ref VARCHAR(160) NOT NULL,
          owner_ref_id UUID,
          payload_ref VARCHAR(160) NOT NULL,
          access_token_hash VARCHAR(160)
        );
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text="")

        self.assertEqual(len(violations), 1)
        self.assertIn("notification_deliveries", violations[0].message)

    def test_xcb006_blocks_composite_token_hash_fields_by_tokens(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120013__auth_session_v2.sql"
        text = """
        CREATE TABLE auth_sessions_v2 (
          session_id UUID PRIMARY KEY,
          refresh_token_hash VARCHAR(160) NOT NULL,
          provider_access_token_hash VARCHAR(160)
        );
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text="")

        self.assertEqual(len(violations), 1)
        self.assertIn("auth_sessions_v2", violations[0].message)

    def test_xcb006_blocks_audit_tables_without_governance_coverage(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120016__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text="")

        self.assertEqual(len(violations), 1)
        self.assertIn("audit_logs_v2", violations[0].message)

    def test_xcb006_blocks_idempotency_replay_tables_without_governance_coverage(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120017__webhook_replay.sql"
        text = """
        CREATE TABLE webhook_idempotency_records (
          replay_id UUID PRIMARY KEY,
          idempotency_key_hash VARCHAR(160) NOT NULL,
          request_hash VARCHAR(160) NOT NULL,
          response_json_redacted TEXT NOT NULL
        );
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text="")

        self.assertEqual(len(violations), 1)
        self.assertIn("webhook_idempotency_records", violations[0].message)

    def test_xcb006_does_not_allow_authorized_java_comments_as_coverage(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120010__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL
        );
        """
        code_coverage = """
        class AccountDeletionService {
          // delete("diagnostic_audio_samples", userId);
          /*
           dataFamily("diagnostic_audio_samples", 1, List.of(), List.of(), List.of(), List.of(), "x");
           new RetentionRuleView("diagnostic_audio_samples", "hard_delete_on_account_deletion", "x", "x");
           */
        }
        """

        violations = ccb.check_xcb006_migration_data_governance(
            path,
            text,
            code_coverage_text=code_coverage,
            exception_coverage_text="",
        )

        self.assertEqual(len(violations), 1)

    def test_xcb006_requires_deletion_export_and_retention_code_coverage(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120011__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL
        );
        """
        code_coverage = """
        delete("diagnostic_audio_samples", userId);
        new RetentionRuleView("diagnostic_audio_samples", "hard_delete_on_account_deletion",
            "account_deletion_or_audio_expiry", "exports redacted diagnostic metadata only");
        """

        violations = ccb.check_xcb006_migration_data_governance(
            path,
            text,
            code_coverage_text=code_coverage,
            exception_coverage_text="",
        )

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_planned_exception_for_sensitive_migration(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120005__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 planned exception: diagnostic_audio_samples is blocked from production use until
        AccountDeletionService, export redaction, retention and audit tests are implemented.
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_planned_exception_even_with_retained_redacted_phrase(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120034__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 planned exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,created_at; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=retained-redacted audit evidence required;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_space_separated_exception_type_aliases(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120039__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverages = [
            """
            XCB-006 retained redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,event_type,created_at; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
            """,
            """
            XCB-006 not applicable exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,event_type,created_at; redacted_fields=none; omitted_fields=none; retention_trigger=content_catalog_lifecycle; deletion_behavior=not_user_owned; export_behavior=not_in_user_export; rationale=public_reference no_user_data reference_data table;
            """,
        ]

        for coverage in coverages:
            with self.subTest(coverage=coverage.strip().split(":", maxsplit=1)[0]):
                violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

                self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_case_variant_exception_type_names(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120044__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverages = [
            """
            XCB-006 Retained-Redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,event_type,created_at; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
            """,
            """
            XCB-006 LEGACY exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,event_type,created_at; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=legacy_migration_compatibility_review; deletion_behavior=pre_existing_legacy_redaction_backfill; export_behavior=export_safe_projection_only; rationale=pre_existing legacy table kept only for migration_compatibility;
            """,
            """
            XCB-006 NOT-APPLICABLE exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,event_type,created_at; redacted_fields=none; omitted_fields=none; retention_trigger=content_catalog_lifecycle; deletion_behavior=not_user_owned; export_behavior=not_in_user_export; rationale=public_reference no_user_data reference_data table;
            """,
        ]

        for coverage in coverages:
            with self.subTest(coverage=coverage.strip().split(":", maxsplit=1)[0]):
                violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

                self.assertEqual(len(violations), 1)

    def test_xcb006_allows_complete_retained_redacted_exception(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120018__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,event_type,created_at; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(violations, [])

    def test_xcb006_rejects_retained_redacted_exception_missing_owner(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120019__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; safe_fields=audit_log_id,event_type,created_at; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_exception_with_sensitive_safe_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120020__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,target_ref,created_at; redacted_fields=redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_tokenized_sensitive_safe_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120025__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,raw_audio,refresh_token_hash,upload_signed_url,user_email; redacted_fields=target_ref,redacted_details; omitted_fields=raw_transcript,provider_payload,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_camel_case_sensitive_safe_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120030__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=auditLogId,rawAudio,refreshTokenHash,uploadSignedUrl,userEmail; redacted_fields=target_ref,redacted_details; omitted_fields=raw_transcript,provider_payload,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_placeholder_required_exception_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120031__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; owner=TBD; safe_fields=tbd; redacted_fields=tbd; omitted_fields=tbd; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_user_identifier_safe_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120040__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,event_id,actor_id,actorId,account_id,accountId,member-id,customerRef,learnerUuid,profile_hash; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_bare_user_subject_safe_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120045__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,event_id,actor,account,member,customer,learner,profile,account_identifier,actorIdentifier,member-key,profile-name; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_camel_and_kebab_target_ref_safe_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120035__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=auditLogId,targetRef,target-ref,redactedDetails,redacted-details; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_duplicate_safe_fields_override(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120026__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=target_ref; safe_fields=audit_log_id,created_at; redacted_fields=redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_duplicate_table_override(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120027__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=other_table; table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,created_at; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_empty_duplicate_structured_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120041__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=; table=audit_logs_v2; owner=Ops; safe_fields=; safe_fields=audit_log_id,created_at; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio,raw_transcript,provider_payload,signed_url,secret,idempotency_key; retention_trigger=append_only_minimal_audit; deletion_behavior=retain_redacted_minimal_audit; export_behavior=export_safe_projection_only; rationale=required_for_security_and_compliance_audit_without_raw_payload;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_embedded_placeholder_required_fields(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120036__audit_logs_v2.sql"
        text = """
        CREATE TABLE audit_logs_v2 (
          audit_log_id UUID PRIMARY KEY,
          target_ref VARCHAR(160) NOT NULL,
          redacted_details TEXT NOT NULL
        );
        """
        coverage = """
        XCB-006 retained-redacted exception: table=audit_logs_v2; owner=Ops; safe_fields=audit_log_id,created_at; redacted_fields=target_ref,redacted_details; omitted_fields=raw_audio; retention_trigger=review_later; deletion_behavior=plannedReview; export_behavior=temporary-export; rationale=pendingReview;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_allows_complete_not_applicable_exception_for_false_positive_table(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120021__audit_reference_codes.sql"
        text = """
        CREATE TABLE audit_reference_codes (
          code VARCHAR(80) PRIMARY KEY,
          title TEXT NOT NULL,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 not-applicable exception: table=audit_reference_codes; owner=Content; safe_fields=code,title,status; redacted_fields=none; omitted_fields=none; retention_trigger=content_catalog_lifecycle; deletion_behavior=not_user_owned; export_behavior=not_in_user_export; rationale=public_reference no_user_data reference_data table;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(violations, [])

    def test_xcb006_rejects_not_applicable_exception_without_not_user_owned_rationale(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120022__audit_reference_codes.sql"
        text = """
        CREATE TABLE audit_reference_codes (
          code VARCHAR(80) PRIMARY KEY,
          title TEXT NOT NULL,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 not-applicable exception: table=audit_reference_codes; owner=Content; safe_fields=code,title,status; redacted_fields=none; omitted_fields=none; retention_trigger=later; deletion_behavior=later; export_behavior=later; rationale=planned review;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_not_applicable_when_only_behavior_has_not_user_owned(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120028__audit_reference_codes.sql"
        text = """
        CREATE TABLE audit_reference_codes (
          code VARCHAR(80) PRIMARY KEY,
          title TEXT NOT NULL,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 not-applicable exception: table=audit_reference_codes; owner=Content; safe_fields=code,title,status; redacted_fields=none; omitted_fields=none; retention_trigger=content_catalog_lifecycle; deletion_behavior=not_user_owned; export_behavior=not_in_user_export; rationale=planned review;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_not_applicable_fixed_field_aliases(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120042__audit_reference_codes.sql"
        text = """
        CREATE TABLE audit_reference_codes (
          code VARCHAR(80) PRIMARY KEY,
          title TEXT NOT NULL,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 not-applicable exception: table=audit_reference_codes; owner=Content; safe_fields=code,title,status; redacted_fields=none; omitted_fields=none; retention_trigger=content_catalog_lifecycle; deletion_behavior=not user owned; export_behavior=not-in-user-export; rationale=public_reference no_user_data reference_data table;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_not_applicable_fixed_field_case_and_quote_aliases(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120043__audit_reference_codes.sql"
        text = """
        CREATE TABLE audit_reference_codes (
          code VARCHAR(80) PRIMARY KEY,
          title TEXT NOT NULL,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 not-applicable exception: table=audit_reference_codes; owner=Content; safe_fields=code,title,status; redacted_fields=`NONE`; omitted_fields="none"; retention_trigger=content_catalog_lifecycle; deletion_behavior=NOT_USER_OWNED; export_behavior='not_in_user_export'; rationale=public_reference no_user_data reference_data table;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_not_applicable_with_user_owned_behaviors(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120032__audit_reference_codes.sql"
        text = """
        CREATE TABLE audit_reference_codes (
          code VARCHAR(80) PRIMARY KEY,
          title TEXT NOT NULL,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 not-applicable exception: table=audit_reference_codes; owner=Content; safe_fields=code,title,status; redacted_fields=target_ref; omitted_fields=raw_audio; retention_trigger=content_catalog_lifecycle; deletion_behavior=delete_user_owned_rows; export_behavior=export_user_projection; rationale=public_reference no_user_data reference_data table;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_not_applicable_exception_with_retained_redacted_rationale(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120037__audit_reference_codes.sql"
        text = """
        CREATE TABLE audit_reference_codes (
          code VARCHAR(80) PRIMARY KEY,
          title TEXT NOT NULL,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 not-applicable exception: table=audit_reference_codes; owner=Content; safe_fields=code,title,status; redacted_fields=none; omitted_fields=none; retention_trigger=content_catalog_lifecycle; deletion_behavior=not_user_owned; export_behavior=not_in_user_export; rationale=retained-redacted cleanup retained for review;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_not_applicable_false_assignment_rationale(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120046__audit_reference_codes.sql"
        text = """
        CREATE TABLE audit_reference_codes (
          code VARCHAR(80) PRIMARY KEY,
          title TEXT NOT NULL,
          status VARCHAR(40) NOT NULL
        );
        """
        false_tokens = (
            "not_user_owned=false",
            "public_reference=false",
            "reference_data=false",
            "configuration=false",
            "no_user_data=false",
        )

        for rationale in false_tokens:
            coverage = f"""
            XCB-006 not-applicable exception: table=audit_reference_codes; owner=Content; safe_fields=code,title,status; redacted_fields=none; omitted_fields=none; retention_trigger=content_catalog_lifecycle; deletion_behavior=not_user_owned; export_behavior=not_in_user_export; rationale={rationale};
            """

            with self.subTest(rationale=rationale):
                violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

                self.assertEqual(len(violations), 1)

    def test_xcb006_allows_legacy_exception_only_with_pre_existing_rationale(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120023__legacy_provider_payload_events.sql"
        text = """
        CREATE TABLE legacy_provider_payload_events (
          event_id UUID PRIMARY KEY,
          provider_payload TEXT NOT NULL,
          created_at TIMESTAMP NOT NULL
        );
        """
        coverage = """
        XCB-006 legacy exception: table=legacy_provider_payload_events; owner=Backend; safe_fields=event_id,created_at; redacted_fields=provider_payload; omitted_fields=raw_audio,raw_transcript,signed_url,secret,idempotency_key; retention_trigger=legacy_migration_compatibility_review; deletion_behavior=pre_existing_legacy_redaction_backfill; export_behavior=export_safe_projection_only; rationale=pre_existing legacy table kept only for migration_compatibility;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(violations, [])

    def test_xcb006_rejects_legacy_exception_without_legacy_rationale(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120024__legacy_provider_payload_events.sql"
        text = """
        CREATE TABLE legacy_provider_payload_events (
          event_id UUID PRIMARY KEY,
          provider_payload TEXT NOT NULL,
          created_at TIMESTAMP NOT NULL
        );
        """
        coverage = """
        XCB-006 legacy exception: table=legacy_provider_payload_events; owner=Backend; safe_fields=event_id,created_at; redacted_fields=provider_payload; omitted_fields=raw_audio,raw_transcript,signed_url,secret,idempotency_key; retention_trigger=review_later; deletion_behavior=review_later; export_behavior=review_later; rationale=temporary table;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_bare_legacy_rationale(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120029__legacy_provider_payload_events.sql"
        text = """
        CREATE TABLE legacy_provider_payload_events (
          event_id UUID PRIMARY KEY,
          provider_payload TEXT NOT NULL,
          created_at TIMESTAMP NOT NULL
        );
        """
        coverage = """
        XCB-006 legacy exception: table=legacy_provider_payload_events; owner=Backend; safe_fields=event_id,created_at; redacted_fields=provider_payload; omitted_fields=raw_audio,raw_transcript,signed_url,secret,idempotency_key; retention_trigger=legacy_review; deletion_behavior=legacy_review; export_behavior=export_safe_projection_only; rationale=legacy cleanup retained for review;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_negated_pre_existing_rationale(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120033__legacy_provider_payload_events.sql"
        text = """
        CREATE TABLE legacy_provider_payload_events (
          event_id UUID PRIMARY KEY,
          provider_payload TEXT NOT NULL,
          created_at TIMESTAMP NOT NULL
        );
        """
        coverage = """
        XCB-006 legacy exception: table=legacy_provider_payload_events; owner=Backend; safe_fields=event_id,created_at; redacted_fields=provider_payload; omitted_fields=raw_audio,raw_transcript,signed_url,secret,idempotency_key; retention_trigger=legacy_review; deletion_behavior=legacy_redaction_backfill; export_behavior=export_safe_projection_only; rationale=not_pre_existing new table retained for review;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_legacy_false_assignment_rationale(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120047__legacy_provider_payload_events.sql"
        text = """
        CREATE TABLE legacy_provider_payload_events (
          event_id UUID PRIMARY KEY,
          provider_payload TEXT NOT NULL,
          created_at TIMESTAMP NOT NULL
        );
        """
        false_tokens = (
            "pre_existing=false",
            "migration_compatibility=false",
        )

        for rationale in false_tokens:
            coverage = f"""
            XCB-006 legacy exception: table=legacy_provider_payload_events; owner=Backend; safe_fields=event_id,created_at; redacted_fields=provider_payload; omitted_fields=raw_audio,raw_transcript,signed_url,secret,idempotency_key; retention_trigger=legacy_review; deletion_behavior=legacy_redaction_backfill; export_behavior=export_safe_projection_only; rationale={rationale};
            """

            with self.subTest(rationale=rationale):
                violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

                self.assertEqual(len(violations), 1)

    def test_xcb006_rejects_legacy_exception_with_retained_redacted_rationale(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120038__legacy_provider_payload_events.sql"
        text = """
        CREATE TABLE legacy_provider_payload_events (
          event_id UUID PRIMARY KEY,
          provider_payload TEXT NOT NULL,
          created_at TIMESTAMP NOT NULL
        );
        """
        coverage = """
        XCB-006 legacy exception: table=legacy_provider_payload_events; owner=Backend; safe_fields=event_id,created_at; redacted_fields=provider_payload; omitted_fields=raw_audio,raw_transcript,signed_url,secret,idempotency_key; retention_trigger=legacy_review; deletion_behavior=legacy_redaction_backfill; export_behavior=export_safe_projection_only; rationale=retained-redacted cleanup retained for review;
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_does_not_allow_exception_for_similar_table_name(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120012__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 planned exception: diagnostic_audio_samples_archive is blocked from production use.
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_requires_exception_marker_on_same_line_as_table(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120014__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        XCB-006 diagnostic_audio_samples requires review.
        planned exception: other_table is blocked from production use.
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)

    def test_xcb006_detects_schema_qualified_and_quoted_table_names(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120006__diagnostic_audio.sql"
        text = """
        CREATE TABLE public."diagnostic_audio_samples" (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL
        );
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text="")

        self.assertEqual(len(violations), 1)
        self.assertIn("diagnostic_audio_samples", violations[0].message)

    def test_changed_paths_include_staged_files_when_include_worktree_is_enabled(self) -> None:
        staged = "backend/src/main/resources/db/migration/V202605260001__pb_p0_foundation.sql"

        def fake_run_git(args: list[str]) -> list[str]:
            if args[:3] == ["diff", "--cached", "--name-only"]:
                return [staged]
            return []

        with mock.patch.object(ccb, "run_git", side_effect=fake_run_git):
            paths = ccb.changed_paths(base_ref=None, include_worktree=True)

        self.assertIn(ROOT / staged, paths)

    def test_changed_paths_include_staged_only_index_paths(self) -> None:
        staged = "backend/src/main/resources/db/migration/V202699990001__staged_only.sql"

        def fake_run_git(args: list[str]) -> list[str]:
            if args[:3] == ["diff", "--cached", "--name-only"]:
                return [staged]
            return []

        with (
            mock.patch.object(ccb, "run_git", side_effect=fake_run_git),
            mock.patch.object(ccb, "git_index_path_exists", return_value=True),
        ):
            paths = ccb.changed_paths(base_ref=None, include_worktree=True)

        self.assertIn(ROOT / staged, paths)

    def test_xcb006_scans_staged_blob_when_it_differs_from_worktree(self) -> None:
        relative = "backend/src/main/resources/db/migration/V202605260001__pb_p0_foundation.sql"
        path = ROOT / relative
        worktree_text = """
        CREATE TABLE grammar_catalog_items (
          item_id UUID PRIMARY KEY,
          title TEXT NOT NULL
        );
        """
        staged_text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          audio_ref TEXT NOT NULL
        );
        """

        with (
            mock.patch.object(ccb, "run_git", return_value=[relative]),
            mock.patch.object(ccb, "read_text", return_value=worktree_text),
            mock.patch.object(ccb, "read_git_index_text", return_value=staged_text),
            mock.patch.object(
                ccb,
                "xcb006_governance_coverage",
                return_value=ccb.Xcb006GovernanceCoverage("", ""),
            ),
            mock.patch.object(
                ccb,
                "xcb006_staged_governance_coverage",
                return_value=ccb.Xcb006GovernanceCoverage("", ""),
            ),
        ):
            violations = ccb.check_xcb006_migration_data_governance_for_paths([path])

        self.assertEqual(len(violations), 1)
        self.assertIn("diagnostic_audio_samples", violations[0].message)

    def test_xcb006_staged_blob_uses_staged_coverage_not_worktree_coverage(self) -> None:
        relative = "backend/src/main/resources/db/migration/V202605260001__pb_p0_foundation.sql"
        path = ROOT / relative
        worktree_text = """
        CREATE TABLE grammar_catalog_items (
          item_id UUID PRIMARY KEY,
          title TEXT NOT NULL
        );
        """
        staged_text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          audio_ref TEXT NOT NULL
        );
        """
        worktree_coverage = ccb.Xcb006GovernanceCoverage(
            """
            delete("diagnostic_audio_samples", userId);
            dataFamily("diagnostic_audio_samples", 1, List.of(), List.of(), List.of(), List.of(), "x");
            new RetentionRuleView("diagnostic_audio_samples", "hard_delete_on_account_deletion", "x", "x");
            """,
            "",
        )
        staged_coverage = ccb.Xcb006GovernanceCoverage("", "")

        with (
            mock.patch.object(ccb, "run_git", return_value=[relative]),
            mock.patch.object(ccb, "read_text", return_value=worktree_text),
            mock.patch.object(ccb, "read_git_index_text", return_value=staged_text),
            mock.patch.object(ccb, "xcb006_governance_coverage", return_value=worktree_coverage),
            mock.patch.object(ccb, "xcb006_staged_governance_coverage", return_value=staged_coverage),
        ):
            violations = ccb.check_xcb006_migration_data_governance_for_paths([path])

        self.assertEqual(len(violations), 1)

    def test_xcb006_staged_blob_uses_staged_coverage_even_when_text_matches_worktree(self) -> None:
        relative = "backend/src/main/resources/db/migration/V202605260001__pb_p0_foundation.sql"
        path = ROOT / relative
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          audio_ref TEXT NOT NULL
        );
        """
        worktree_coverage = ccb.Xcb006GovernanceCoverage(
            """
            delete("diagnostic_audio_samples", userId);
            dataFamily("diagnostic_audio_samples", 1, List.of(), List.of(), List.of(), List.of(), "x");
            new RetentionRuleView("diagnostic_audio_samples", "hard_delete_on_account_deletion", "x", "x");
            """,
            "",
        )
        staged_coverage = ccb.Xcb006GovernanceCoverage("", "")

        with (
            mock.patch.object(ccb, "run_git", return_value=[relative]),
            mock.patch.object(ccb, "read_text", return_value=text),
            mock.patch.object(ccb, "read_git_index_text", return_value=text),
            mock.patch.object(ccb, "xcb006_governance_coverage", return_value=worktree_coverage),
            mock.patch.object(ccb, "xcb006_staged_governance_coverage", return_value=staged_coverage),
        ):
            violations = ccb.check_xcb006_migration_data_governance_for_paths([path])

        self.assertEqual(len(violations), 1)

    def test_xcb006_exception_requires_xcb006_marker(self) -> None:
        path = ROOT / "backend/src/main/resources/db/migration/V202606120015__diagnostic_audio.sql"
        text = """
        CREATE TABLE diagnostic_audio_samples (
          sample_id UUID PRIMARY KEY,
          status VARCHAR(40) NOT NULL
        );
        """
        coverage = """
        数据保留、导出、删除和审计 planned exception: diagnostic_audio_samples blocked.
        """

        violations = ccb.check_xcb006_migration_data_governance(path, text, coverage_text=coverage)

        self.assertEqual(len(violations), 1)


if __name__ == "__main__":
    unittest.main()
