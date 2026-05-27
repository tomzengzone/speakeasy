from pathlib import Path
import hashlib
import json
import re
import sys

import yaml


SPEC_PATH = Path("docs/architecture/openapi/speakeasy-api.yaml")
MANIFEST_PATH = Path("docs/architecture/openapi/dart-client-drift-manifest.json")
DEFAULT_TARGET = Path("lib/generated/api")
METHODS = {"get", "put", "post", "delete", "patch", "head", "options", "trace"}
DART_RESERVED = {
    "abstract",
    "as",
    "assert",
    "async",
    "await",
    "break",
    "case",
    "catch",
    "class",
    "const",
    "continue",
    "covariant",
    "default",
    "deferred",
    "do",
    "dynamic",
    "else",
    "enum",
    "export",
    "extends",
    "extension",
    "external",
    "factory",
    "false",
    "final",
    "finally",
    "for",
    "function",
    "get",
    "hide",
    "if",
    "implements",
    "import",
    "in",
    "interface",
    "is",
    "late",
    "library",
    "mixin",
    "new",
    "null",
    "on",
    "operator",
    "part",
    "required",
    "rethrow",
    "return",
    "set",
    "show",
    "static",
    "super",
    "switch",
    "sync",
    "this",
    "throw",
    "true",
    "try",
    "typedef",
    "var",
    "void",
    "while",
    "with",
    "yield",
}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_spec():
    return yaml.safe_load(SPEC_PATH.read_text(encoding="utf-8"))


def dart_class_name(name):
    parts = re.split(r"[^A-Za-z0-9]+", name)
    value = "".join(part[:1].upper() + part[1:] for part in parts if part)
    return value


def is_identifier(name):
    return bool(re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", name or ""))


def iter_operations(spec):
    for path_item in (spec.get("paths") or {}).values():
        if not isinstance(path_item, dict):
            continue
        for method, operation in path_item.items():
            if method in METHODS and isinstance(operation, dict):
                yield operation


def main():
    errors = []
    spec = load_spec()
    current_hash = sha256(SPEC_PATH)

    if not MANIFEST_PATH.exists():
        errors.append(f"missing Dart drift manifest: {MANIFEST_PATH}")
        manifest = {}
    else:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))

    expected_openapi = str(SPEC_PATH).replace("\\", "/")
    expected_target = str(DEFAULT_TARGET).replace("\\", "/")
    if manifest.get("openapi_path") != expected_openapi:
        errors.append("manifest openapi_path does not match canonical OpenAPI path")
    if manifest.get("target_directory") != expected_target:
        errors.append("manifest target_directory must be lib/generated/api")
    if manifest.get("openapi_sha256") != current_hash:
        errors.append("OpenAPI hash drift detected; update generated Dart client or pre-client manifest")

    mode = manifest.get("mode")
    target = DEFAULT_TARGET
    if target.exists():
        if mode != "generated_client_drift":
            errors.append("generated Dart client exists, but manifest mode is not generated_client_drift")
        marker = target / ".openapi-sha256"
        if not marker.exists():
            errors.append("generated Dart client is missing lib/generated/api/.openapi-sha256")
        elif marker.read_text(encoding="utf-8").strip() != current_hash:
            errors.append("generated Dart client hash marker does not match current OpenAPI")
        if not list(target.rglob("*.dart")):
            errors.append("generated Dart client directory exists but contains no Dart files")
    else:
        if mode != "pre_client_generation_gate":
            errors.append("generated Dart client is absent, but manifest is not in pre-client mode")

    operation_ids = []
    for operation in iter_operations(spec):
        operation_id = operation.get("operationId")
        if not is_identifier(operation_id):
            errors.append(f"operationId is not a Dart-safe identifier: {operation_id}")
        elif operation_id.lower() in DART_RESERVED:
            errors.append(f"operationId conflicts with a Dart reserved word: {operation_id}")
        operation_ids.append(operation_id)
    if len(operation_ids) != len(set(operation_ids)):
        errors.append("duplicate operationId values block deterministic Dart client generation")

    schemas = (spec.get("components") or {}).get("schemas") or {}
    dart_names = {}
    for schema_name in schemas:
        class_name = dart_class_name(schema_name)
        if not class_name or class_name[:1].isdigit():
            errors.append(f"schema name cannot map to a Dart class: {schema_name}")
            continue
        if class_name.lower() in DART_RESERVED:
            errors.append(f"schema name maps to a Dart reserved word: {schema_name}")
        previous = dart_names.get(class_name)
        if previous and previous != schema_name:
            errors.append(f"schema names collide after Dart class normalization: {previous}, {schema_name}")
        dart_names[class_name] = schema_name

    handwritten_client = Path("lib/services/api_client.dart")
    if handwritten_client.exists() and target in handwritten_client.parents:
        errors.append("handwritten ApiClient is inside generated Dart client target")

    if errors:
        for error in errors:
            print(error)
        return 1

    print(
        "Dart client drift gate passed: "
        f"mode={mode}, openapi_sha256={current_hash}, "
        f"target={expected_target}, operations={len(operation_ids)}, schemas={len(schemas)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
