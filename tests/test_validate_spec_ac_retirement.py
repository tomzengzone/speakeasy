import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from validate_spec_ac_retirement import extract_definition_ids, validate_repository


class SpecAcRetirementValidationTest(unittest.TestCase):
    def copy_fixture(self, target: Path) -> None:
        for relative in [
            "docs/process/governance",
            "docs/product/increments",
        ]:
            shutil.copytree(ROOT / relative, target / relative)
        manifest = "docs/process/migrations/spec-ac-retirement.json"
        destination = target / manifest
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / manifest, destination)

    def load_json(self, root: Path, relative: str) -> dict:
        return json.loads((root / relative).read_text(encoding="utf-8"))

    def write_json(self, root: Path, relative: str, value: dict) -> None:
        (root / relative).write_text(
            json.dumps(value, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    def assert_has_error(self, root: Path, fragment: str) -> None:
        errors, _metrics = validate_repository(root)
        self.assertTrue(
            any(fragment in error for error in errors),
            f"expected error containing {fragment!r}, got: {errors}",
        )

    def test_current_repository_manifest_is_valid(self):
        errors, metrics = validate_repository(ROOT)
        self.assertEqual([], errors)
        self.assertEqual(
            {"legacy_files": 116, "legacy_ids": 262, "manifest_records": 262},
            metrics,
        )

    def test_heading_and_definition_table_ids_are_discovered(self):
        cases = {
            "docs/product/increments/commercial-ai-provider-hardening/spec.md": "COM-AI-SPEC-001",
            "docs/product/increments/commercial-subscription-readiness/spec.md": "COM-SPEC-001",
            "docs/product/increments/mvp-backend-foundation-auth/spec.md": "MVP-BE-SPEC-001",
            "docs/product/increments/mvp-system-e2e-validation/spec.md": "MVP-E2E-SPEC-001",
            "docs/product/increments/mvp-system-e2e-validation/acceptance.md": "AC-MVP-E2E-001",
            "docs/product/increments/scenario-practice-runtime-migration/acceptance.md": "MIG-AC-001",
        }
        for relative, expected_id in cases.items():
            with self.subTest(relative=relative):
                self.assertIn(expected_id, extract_definition_ids(ROOT / relative))

    def test_body_and_non_definition_table_references_are_not_discovered(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "spec.md"
            path.write_text(
                "# Example\n\n"
                "A prose reference to BODY-SPEC-001 is not a definition.\n\n"
                "## Notes\n\n"
                "| REF-SPEC-001 | reference only |\n"
                "| --- | --- |\n\n"
                "## Spec Coverage\n\n"
                "| Spec ID | Area |\n"
                "| --- | --- |\n"
                "| REAL-SPEC-001 | defined here |\n",
                encoding="utf-8",
            )
            self.assertEqual({"REAL-SPEC-001"}, extract_definition_ids(path))

    def test_missing_defined_id_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/migrations/spec-ac-retirement.json"
            manifest = self.load_json(target, relative)
            manifest["records"].pop(0)
            self.write_json(target, relative, manifest)
            self.assert_has_error(target, "manifest is missing defined legacy IDs")

    def test_duplicate_id_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/migrations/spec-ac-retirement.json"
            manifest = self.load_json(target, relative)
            manifest["records"].insert(1, dict(manifest["records"][0]))
            self.write_json(target, relative, manifest)
            self.assert_has_error(target, "manifest contains duplicate old_path/old_id records")

    def test_wrong_legacy_file_count_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/migrations/spec-ac-retirement.json"
            manifest = self.load_json(target, relative)
            manifest["expected_file_count"] += 1
            self.write_json(target, relative, manifest)
            self.assert_has_error(target, "legacy file count mismatch")

    def test_wrong_legacy_path_digest_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/migrations/spec-ac-retirement.json"
            manifest = self.load_json(target, relative)
            manifest["legacy_path_digest"] = "0" * 64
            self.write_json(target, relative, manifest)
            self.assert_has_error(target, "legacy path digest mismatch")

    def test_schema_id_pattern_must_match_strict_parser(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/governance/schemas/spec-ac-retirement.schema.json"
            schema = self.load_json(target, relative)
            schema["properties"]["records"]["items"]["properties"]["old_id"]["pattern"] = ".*"
            self.write_json(target, relative, schema)
            self.assert_has_error(target, "old_id pattern does not match the strict parser contract")

    def test_all_schema_constraints_are_pinned(self):
        mutations = {
            "old_path": lambda schema: schema["properties"]["records"]["items"][
                "properties"
            ]["old_path"].update({"pattern": ".*"}),
            "destination_id": lambda schema: schema["properties"]["records"]["items"][
                "properties"
            ]["destinations"]["items"]["properties"]["id"].update({"pattern": ".*"}),
            "legacy_path_digest": lambda schema: schema["properties"][
                "legacy_path_digest"
            ].update({"pattern": ".*"}),
        }
        for name, mutate in mutations.items():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temp:
                target = Path(temp)
                self.copy_fixture(target)
                relative = "docs/process/governance/schemas/spec-ac-retirement.schema.json"
                schema = self.load_json(target, relative)
                mutate(schema)
                self.write_json(target, relative, schema)
                self.assert_has_error(target, "schema canonical SHA-256 does not match")

    def test_invalid_destination_kind_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/migrations/spec-ac-retirement.json"
            manifest = self.load_json(target, relative)
            manifest["records"][0]["status"] = "migrated"
            manifest["records"][0]["destinations"] = [
                {"kind": "unknown-destination", "id": "VS-PLACEHOLDER"}
            ]
            self.write_json(target, relative, manifest)
            self.assert_has_error(target, "kind has invalid enum value")

    def test_invalid_record_types_are_rejected_without_crashing(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/migrations/spec-ac-retirement.json"
            manifest = self.load_json(target, relative)
            manifest["records"][0]["status"] = []
            manifest["records"][0]["destinations"] = [{}]
            self.write_json(target, relative, manifest)
            errors, _metrics = validate_repository(target)
            self.assertTrue(any("status has invalid enum value" in error for error in errors))
            self.assertTrue(any("destinations[0] missing fields" in error for error in errors))

    def test_grandfathered_record_cannot_have_destinations(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/migrations/spec-ac-retirement.json"
            manifest = self.load_json(target, relative)
            manifest["records"][0]["destinations"] = [
                {"kind": "functional-requirement", "id": "FR-PLACEHOLDER"}
            ]
            self.write_json(target, relative, manifest)
            self.assert_has_error(target, "grandfathered-unverified requires empty destinations")

    def test_migrated_record_supports_multiple_typed_destinations(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/migrations/spec-ac-retirement.json"
            manifest = self.load_json(target, relative)
            manifest["records"][0]["status"] = "migrated"
            manifest["records"][0]["destinations"] = [
                {"kind": "vertical-slice", "id": "VS-COM-AI-001"},
                {"kind": "functional-requirement", "id": "FR-COM-AI-001"},
                {"kind": "executable-regression-test", "id": "TC-COM-AI-001"},
            ]
            self.write_json(target, relative, manifest)
            errors, _metrics = validate_repository(target)
            self.assertEqual([], errors)

    def test_duplicate_typed_destination_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/migrations/spec-ac-retirement.json"
            manifest = self.load_json(target, relative)
            destination = {"kind": "vertical-slice", "id": "VS-COM-AI-001"}
            manifest["records"][0]["status"] = "migrated"
            manifest["records"][0]["destinations"] = [destination, dict(destination)]
            self.write_json(target, relative, manifest)
            self.assert_has_error(target, "destinations must be unique")

    def test_reason_must_contain_chinese_explanation(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp)
            self.copy_fixture(target)
            relative = "docs/process/migrations/spec-ac-retirement.json"
            manifest = self.load_json(target, relative)
            manifest["records"][0]["reason"] = "????????"
            self.write_json(target, relative, manifest)
            self.assert_has_error(target, "reason must be a non-empty Chinese explanation")

    def test_manifest_cannot_become_an_artifact_input(self):
        for field in ("required_direct_inputs", "conditional_inputs"):
            with self.subTest(field=field), tempfile.TemporaryDirectory() as temp:
                target = Path(temp)
                self.copy_fixture(target)
                relative = "docs/process/governance/artifacts/product.json"
                shard = self.load_json(target, relative)
                shard["artifacts"][0][field] = ["SPEC_AC_RETIREMENT_MANIFEST"]
                self.write_json(target, relative, shard)
                self.assert_has_error(target, f"artifact[0].{field}")

    def test_registration_route_owner_lifecycle_and_command_are_enforced(self):
        mutations = {
            "route": (
                "docs/process/governance/index.json",
                lambda value: value["artifact_routes"].update(
                    {"SPEC_AC_RETIREMENT_MANIFEST": "artifacts/product.json"}
                ),
                "artifact route for SPEC_AC_RETIREMENT_MANIFEST",
            ),
            "owner": (
                "docs/process/governance/artifacts/governance.json",
                lambda value: self._set_artifact_field(
                    value, "SPEC_AC_RETIREMENT_MANIFEST", "accountable_owner", "product-manager"
                ),
                "SPEC_AC_RETIREMENT_MANIFEST.accountable_owner",
            ),
            "lifecycle": (
                "docs/process/governance/artifacts/governance.json",
                lambda value: self._set_artifact_field(
                    value, "SPEC_AC_RETIREMENT_SCHEMA", "lifecycle", "persistent"
                ),
                "SPEC_AC_RETIREMENT_SCHEMA.lifecycle",
            ),
            "validation_command": (
                "docs/process/governance/artifacts/governance.json",
                lambda value: self._set_artifact_field(
                    value, "SPEC_AC_RETIREMENT_VALIDATOR", "validation_command", "python -m unittest"
                ),
                "SPEC_AC_RETIREMENT_VALIDATOR.validation_command",
            ),
        }
        for name, (relative, mutate, expected_error) in mutations.items():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temp:
                target = Path(temp)
                self.copy_fixture(target)
                value = self.load_json(target, relative)
                mutate(value)
                self.write_json(target, relative, value)
                self.assert_has_error(target, expected_error)

    @staticmethod
    def _set_artifact_field(shard: dict, artifact_id: str, field: str, value: str) -> None:
        artifact = next(
            item for item in shard["artifacts"] if item["artifact_id"] == artifact_id
        )
        artifact[field] = value


if __name__ == "__main__":
    unittest.main()
