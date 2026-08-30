import importlib.util
import tempfile
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "check_authentication_alert_rules.py"
RULES = ROOT / "ops" / "observability" / "prometheus" / "authentication-alerts.yml"

SPEC = importlib.util.spec_from_file_location("check_authentication_alert_rules", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class AuthenticationAlertRulesTest(unittest.TestCase):
    def test_repository_rules_satisfy_contract(self):
        self.assertEqual([], MODULE.validate(RULES))

    def test_validator_rejects_identity_label(self):
        document = yaml.safe_load(RULES.read_text(encoding="utf-8"))
        document["groups"][0]["rules"][0]["expr"] += '\n+ user_id="unsafe"'

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "rules.yml"
            path.write_text(yaml.safe_dump(document, sort_keys=False), encoding="utf-8")
            errors = MODULE.validate(path)

        self.assertTrue(any("forbidden high-cardinality label 'user_id'" in error for error in errors))

    def test_validator_rejects_missing_sample_floor(self):
        document = yaml.safe_load(RULES.read_text(encoding="utf-8"))
        document["groups"][0]["rules"][0]["expr"] = document["groups"][0]["rules"][0]["expr"].replace(
            ">= 100", ">= 99"
        )

        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "rules.yml"
            path.write_text(yaml.safe_dump(document, sort_keys=False), encoding="utf-8")
            errors = MODULE.validate(path)

        self.assertTrue(any("'>= 100'" in error for error in errors))

    def test_validator_rejects_missing_backend_metric(self):
        dependencies = (
            "backend/src/main/java/com/speakeasy/identity/AuthMetrics.java",
            "backend/src/main/java/com/speakeasy/identity/AccountSecurityService.java",
            "backend/src/main/java/com/speakeasy/ops/AuthAuditService.java",
            "backend/src/main/resources/application.yml",
            "backend/pom.xml",
        )
        with tempfile.TemporaryDirectory() as directory:
            project_root = Path(directory)
            for relative in dependencies:
                target = project_root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text((ROOT / relative).read_text(encoding="utf-8"), encoding="utf-8")
            auth_metrics = project_root / dependencies[0]
            auth_metrics.write_text(
                auth_metrics.read_text(encoding="utf-8").replace(
                    "speakeasy.auth.token.reuse", "speakeasy.auth.token.renamed"
                ),
                encoding="utf-8",
            )

            errors = MODULE.validate_backend_dependencies(project_root)

        self.assertTrue(any("speakeasy.auth.token.reuse" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
