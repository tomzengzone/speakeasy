from pathlib import Path
import argparse
import hashlib
import json
import re
import sys
from textwrap import dedent

import yaml


SPEC_PATH = Path("docs/architecture/openapi/speakeasy-api.yaml")
MANIFEST_PATH = Path("docs/architecture/openapi/dart-client-drift-manifest.json")
DEFAULT_TARGET = Path("lib/generated/api")
GENERATED_DART = DEFAULT_TARGET / "speakeasy_api.dart"
CATALOG_SECTION_START = "// BEGIN GENERATED CONTENT CATALOG DTOs"
CATALOG_SECTION_END = "// END GENERATED CONTENT CATALOG DTOs"
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


def path_templates(spec):
    return sorted((spec.get("paths") or {}).keys())


def dart_source_text(target):
    return "\n".join(path.read_text(encoding="utf-8") for path in sorted(target.rglob("*.dart")))


def generated_level_code_values(generated_text):
    enum_match = re.search(r"enum\s+LevelCode\s*\{(?P<body>.*?)\n\}", generated_text, re.DOTALL)
    if not enum_match:
        return None
    return re.findall(r"^[ \t]*[a-z][A-Za-z0-9_]*\('([^']+)'\)[,;]", enum_match.group("body"), re.MULTILINE)


def require_catalog_contract(spec):
    schemas = (spec.get("components") or {}).get("schemas") or {}
    expected = {
        "ScenarioListResponse": {
            "required": {"schema_version", "request_id", "scenarios"},
            "properties": {"schema_version", "request_id", "scenarios"},
        },
        "ScenarioSummary": {
            "required": {"scenario_id", "title", "status", "access"},
            "properties": {"scenario_id", "title", "summary", "tags", "levels", "status", "access"},
        },
        "AccessState": {
            "required": {"allowed"},
            "properties": {"allowed", "reason_code"},
        },
        "CourseListResponse": {
            "required": {"schema_version", "request_id", "scenario_id", "courses"},
            "properties": {"schema_version", "request_id", "scenario_id", "courses"},
        },
        "CourseDetailResponse": {
            "required": {"schema_version", "request_id", "course"},
            "properties": {"schema_version", "request_id", "course"},
        },
        "CourseSummary": {
            "required": {
                "course_id",
                "course_version_id",
                "title_en",
                "summary_zh",
                "level_code",
                "content_binding_ref",
            },
            "properties": {
                "course_id",
                "course_version_id",
                "title_en",
                "summary_zh",
                "level_code",
                "content_binding_ref",
            },
        },
        "CourseContentBindingRef": {
            "required": {"course_content_binding_id", "scenario_version_id", "scenario_level_id"},
            "properties": {"course_content_binding_id", "scenario_version_id", "scenario_level_id"},
        },
        "TypicalDuration": {
            "required": {"value", "unit"},
            "properties": {"value", "unit"},
        },
        "ErrorResponse": {
            "required": {"error"},
            "properties": {"error"},
        },
        "ErrorDetails": {
            "required": set(),
            "properties": {"retryable"},
        },
    }
    errors = []
    for name, signature in expected.items():
        schema = schemas.get(name)
        if not isinstance(schema, dict):
            errors.append(f"missing catalog schema: {name}")
            continue
        required = set(schema.get("required") or [])
        properties = set((schema.get("properties") or {}).keys())
        if required != signature["required"]:
            errors.append(f"{name}.required changed: {sorted(required)}")
        if properties != signature["properties"]:
            errors.append(f"{name}.properties changed: {sorted(properties)}")

    scenario_values = (schemas.get("ScenarioId") or {}).get("enum")
    if scenario_values != ["job_interview", "onboarding_introduction"]:
        errors.append(f"ScenarioId enum changed: {scenario_values}")
    scenario_status = (((schemas.get("ScenarioSummary") or {}).get("properties") or {}).get("status") or {}).get("enum")
    if scenario_status != ["available", "hidden"]:
        errors.append(f"ScenarioSummary.status enum changed: {scenario_status}")
    access_reasons = (((schemas.get("AccessState") or {}).get("properties") or {}).get("reason_code") or {}).get("enum")
    if access_reasons != ["ENTITLEMENT_REQUIRED", "SUBSCRIPTION_EXPIRED", "USAGE_LIMIT_EXCEEDED", None]:
        errors.append(f"AccessState.reason_code enum changed: {access_reasons}")

    refs = {
        ("ScenarioListResponse", "scenarios", "items"): "#/components/schemas/ScenarioSummary",
        ("ScenarioSummary", "scenario_id", None): "#/components/schemas/ScenarioId",
        ("ScenarioSummary", "access", None): "#/components/schemas/AccessState",
        ("CourseListResponse", "courses", "items"): "#/components/schemas/CourseSummary",
        ("CourseListResponse", "scenario_id", None): "#/components/schemas/ScenarioId",
        ("CourseDetailResponse", "course", None): "#/components/schemas/CourseDetail",
        ("CourseSummary", "course_id", None): "#/components/schemas/CourseId",
        ("CourseSummary", "course_version_id", None): "#/components/schemas/CourseVersionId",
        ("CourseSummary", "level_code", None): "#/components/schemas/LevelCode",
        ("CourseSummary", "content_binding_ref", None): "#/components/schemas/CourseContentBindingRef",
        ("CourseContentBindingRef", "course_content_binding_id", None): "#/components/schemas/CourseContentBindingId",
        ("CourseContentBindingRef", "scenario_version_id", None): "#/components/schemas/ScenarioVersionId",
        ("CourseContentBindingRef", "scenario_level_id", None): "#/components/schemas/ScenarioLevelId",
    }
    for (schema_name, property_name, nested), expected_ref in refs.items():
        prop = (((schemas.get(schema_name) or {}).get("properties") or {}).get(property_name) or {})
        actual_ref = (prop.get(nested) or {}).get("$ref") if nested else prop.get("$ref")
        if actual_ref != expected_ref:
            errors.append(f"{schema_name}.{property_name} ref changed: {actual_ref}")
    for schema_name in (
        "CourseId",
        "CourseVersionId",
        "CourseContentBindingId",
        "ScenarioVersionId",
        "ScenarioLevelId",
    ):
        schema = schemas.get(schema_name) or {}
        if schema.get("type") != "string" or schema.get("format") != "uuid":
            errors.append(f"{schema_name} must remain a string with format uuid")

    course_detail = schemas.get("CourseDetail") or {}
    course_detail_parts = course_detail.get("allOf") or []
    if len(course_detail_parts) != 2 or course_detail_parts[0].get("$ref") != "#/components/schemas/CourseSummary":
        errors.append("CourseDetail must extend CourseSummary through allOf")
    else:
        detail_extension = course_detail_parts[1]
        detail_required = set(detail_extension.get("required") or [])
        detail_properties = set((detail_extension.get("properties") or {}).keys())
        if detail_required != {"typical_duration"}:
            errors.append(f"CourseDetail.required changed: {sorted(detail_required)}")
        if detail_properties != {"typical_duration", "background_asset_ref"}:
            errors.append(f"CourseDetail.properties changed: {sorted(detail_properties)}")
        duration_ref = ((detail_extension.get("properties") or {}).get("typical_duration") or {}).get("$ref")
        if duration_ref != "#/components/schemas/TypicalDuration":
            errors.append(f"CourseDetail.typical_duration ref changed: {duration_ref}")
        background = (detail_extension.get("properties") or {}).get("background_asset_ref") or {}
        if background.get("type") != "string" or background.get("nullable") is not True:
            errors.append("CourseDetail.background_asset_ref must remain a nullable string")

    duration_value = (((schemas.get("TypicalDuration") or {}).get("properties") or {}).get("value") or {})
    if duration_value.get("type") != "number" or duration_value.get("exclusiveMinimum") is not True:
        errors.append("TypicalDuration.value must remain a positive number")
    return errors


def generated_catalog_section():
    return dedent(
        r'''
        // BEGIN GENERATED CONTENT CATALOG DTOs
        // Generated by scripts/check_openapi_dart_drift.py --write.

        enum ScenarioId {
          jobInterview('job_interview'),
          onboardingIntroduction('onboarding_introduction');

          const ScenarioId(this.wireValue);

          final String wireValue;

          static ScenarioId parse(Object? value) {
            for (final ScenarioId item in ScenarioId.values) {
              if (item.wireValue == value) {
                return item;
              }
            }
            throw FormatException('Invalid ScenarioId: $value');
          }
        }

        enum ScenarioStatus {
          available('available'),
          hidden('hidden');

          const ScenarioStatus(this.wireValue);

          final String wireValue;

          static ScenarioStatus parse(Object? value) {
            for (final ScenarioStatus item in ScenarioStatus.values) {
              if (item.wireValue == value) {
                return item;
              }
            }
            throw FormatException('Invalid ScenarioStatus: $value');
          }
        }

        enum AccessReasonCode {
          entitlementRequired('ENTITLEMENT_REQUIRED'),
          subscriptionExpired('SUBSCRIPTION_EXPIRED'),
          usageLimitExceeded('USAGE_LIMIT_EXCEEDED');

          const AccessReasonCode(this.wireValue);

          final String wireValue;

          static AccessReasonCode? parseNullable(Object? value) {
            if (value == null) {
              return null;
            }
            for (final AccessReasonCode item in AccessReasonCode.values) {
              if (item.wireValue == value) {
                return item;
              }
            }
            throw FormatException('Invalid AccessReasonCode: $value');
          }
        }

        Map<String, Object?> _catalogMap(Object? value, String field) {
          if (value is! Map) {
            throw FormatException('$field must be an object');
          }
          final Map<String, Object?> result = <String, Object?>{};
          for (final MapEntry<Object?, Object?> entry in value.entries) {
            if (entry.key is! String) {
              throw FormatException('$field contains a non-string key');
            }
            result[entry.key! as String] = entry.value;
          }
          return result;
        }

        String _catalogString(
          Map<String, Object?> json,
          String field, {
          bool nonEmpty = false,
        }) {
          final Object? value = json[field];
          if (value is! String || (nonEmpty && value.trim().isEmpty)) {
            throw FormatException(
              '$field must be${nonEmpty ? ' a non-empty' : ''} string',
            );
          }
          return value;
        }

        String? _catalogOptionalString(Map<String, Object?> json, String field) {
          if (!json.containsKey(field)) {
            return null;
          }
          final Object? value = json[field];
          if (value is! String) {
            throw FormatException('$field must be a string when present');
          }
          return value;
        }

        String? _catalogNullableString(Map<String, Object?> json, String field) {
          final Object? value = json[field];
          if (value == null) {
            return null;
          }
          if (value is! String) {
            throw FormatException('$field must be a string or null');
          }
          return value;
        }

        num _catalogPositiveNumber(Map<String, Object?> json, String field) {
          final Object? value = json[field];
          if (value is! num || value <= 0) {
            throw FormatException('$field must be a positive number');
          }
          return value;
        }

        bool _catalogBool(Map<String, Object?> json, String field) {
          final Object? value = json[field];
          if (value is! bool) {
            throw FormatException('$field must be a boolean');
          }
          return value;
        }

        List<Object?> _catalogList(Map<String, Object?> json, String field) {
          final Object? value = json[field];
          if (value is! List) {
            throw FormatException('$field must be an array');
          }
          return value.cast<Object?>();
        }

        String _catalogUuid(Map<String, Object?> json, String field) {
          final String value = _catalogString(json, field);
          if (!RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ).hasMatch(value)) {
            throw FormatException('$field must be a UUID');
          }
          return value;
        }

        int _catalogSchemaVersion(Map<String, Object?> json) {
          final Object? value = json['schema_version'];
          if (value != 1) {
            throw FormatException('schema_version must be 1');
          }
          return 1;
        }

        class ErrorDetails {
          const ErrorDetails({required this.values, this.retryable});

          final Map<String, Object?> values;
          final bool? retryable;

          factory ErrorDetails.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'error.details');
            final Object? retryable = json['retryable'];
            if (retryable != null && retryable is! bool) {
              throw const FormatException('error.details.retryable must be a boolean');
            }
            return ErrorDetails(
              values: Map<String, Object?>.unmodifiable(json),
              retryable: retryable as bool?,
            );
          }
        }

        class ApiError {
          const ApiError({
            required this.code,
            required this.message,
            required this.requestId,
            this.details,
          });

          final ErrorCode code;
          final String message;
          final String requestId;
          final ErrorDetails? details;

          factory ApiError.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'error');
            final ErrorCode? code = ErrorCode.tryParse(json['code']);
            if (code == null) {
              throw FormatException('Invalid ErrorCode: ${json['code']}');
            }
            return ApiError(
              code: code,
              message: _catalogString(json, 'message'),
              requestId: _catalogString(json, 'request_id'),
              details: json['details'] == null
                  ? null
                  : ErrorDetails.fromJson(json['details']),
            );
          }
        }

        class ErrorResponse {
          const ErrorResponse({required this.error});

          final ApiError error;

          factory ErrorResponse.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'response');
            return ErrorResponse(error: ApiError.fromJson(json['error']));
          }
        }

        class AccessState {
          const AccessState({required this.allowed, this.reasonCode});

          final bool allowed;
          final AccessReasonCode? reasonCode;

          factory AccessState.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'access');
            return AccessState(
              allowed: _catalogBool(json, 'allowed'),
              reasonCode: AccessReasonCode.parseNullable(json['reason_code']),
            );
          }
        }

        class ScenarioSummary {
          const ScenarioSummary({
            required this.scenarioId,
            required this.title,
            required this.status,
            required this.access,
            this.summary,
            this.tags,
            this.levels,
          });

          final ScenarioId scenarioId;
          final String title;
          final ScenarioStatus status;
          final AccessState access;
          final String? summary;
          final List<String>? tags;
          final List<LevelCode>? levels;

          factory ScenarioSummary.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'scenario');
            return ScenarioSummary(
              scenarioId: ScenarioId.parse(json['scenario_id']),
              title: _catalogString(json, 'title'),
              status: ScenarioStatus.parse(json['status']),
              access: AccessState.fromJson(json['access']),
              summary: _catalogOptionalString(json, 'summary'),
              tags: !json.containsKey('tags')
                  ? null
                  : List<String>.unmodifiable(
                      _catalogList(json, 'tags').map((Object? item) {
                        if (item is! String) {
                          throw const FormatException('tags must contain strings');
                        }
                        return item;
                      }),
                    ),
              levels: !json.containsKey('levels')
                  ? null
                  : List<LevelCode>.unmodifiable(
                      _catalogList(json, 'levels').map(LevelCode.tryParse).map((
                        LevelCode? item,
                      ) {
                        if (item == null) {
                          throw const FormatException(
                            'levels contains an invalid LevelCode',
                          );
                        }
                        return item;
                      }),
                    ),
            );
          }
        }

        class ScenarioListResponse {
          const ScenarioListResponse({
            required this.schemaVersion,
            required this.requestId,
            required this.scenarios,
          });

          final int schemaVersion;
          final String requestId;
          final List<ScenarioSummary> scenarios;

          factory ScenarioListResponse.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'response');
            return ScenarioListResponse(
              schemaVersion: _catalogSchemaVersion(json),
              requestId: _catalogString(json, 'request_id'),
              scenarios: List<ScenarioSummary>.unmodifiable(
                _catalogList(json, 'scenarios').map(ScenarioSummary.fromJson),
              ),
            );
          }
        }

        class CourseContentBindingRef {
          const CourseContentBindingRef({
            required this.courseContentBindingId,
            required this.scenarioVersionId,
            required this.scenarioLevelId,
          });

          final String courseContentBindingId;
          final String scenarioVersionId;
          final String scenarioLevelId;

          factory CourseContentBindingRef.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'content_binding_ref');
            return CourseContentBindingRef(
              courseContentBindingId: _catalogUuid(json, 'course_content_binding_id'),
              scenarioVersionId: _catalogUuid(json, 'scenario_version_id'),
              scenarioLevelId: _catalogUuid(json, 'scenario_level_id'),
            );
          }
        }

        class CourseSummary {
          const CourseSummary({
            required this.courseId,
            required this.courseVersionId,
            required this.titleEn,
            required this.summaryZh,
            required this.levelCode,
            required this.contentBindingRef,
          });

          final String courseId;
          final String courseVersionId;
          final String titleEn;
          final String summaryZh;
          final LevelCode levelCode;
          final CourseContentBindingRef contentBindingRef;

          factory CourseSummary.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'course');
            final LevelCode? levelCode = LevelCode.tryParse(json['level_code']);
            if (levelCode == null) {
              throw FormatException('Invalid LevelCode: ${json['level_code']}');
            }
            return CourseSummary(
              courseId: _catalogUuid(json, 'course_id'),
              courseVersionId: _catalogUuid(json, 'course_version_id'),
              titleEn: _catalogString(json, 'title_en', nonEmpty: true),
              summaryZh: _catalogString(json, 'summary_zh', nonEmpty: true),
              levelCode: levelCode,
              contentBindingRef: CourseContentBindingRef.fromJson(
                json['content_binding_ref'],
              ),
            );
          }
        }

        class CourseListResponse {
          const CourseListResponse({
            required this.schemaVersion,
            required this.requestId,
            required this.scenarioId,
            required this.courses,
          });

          final int schemaVersion;
          final String requestId;
          final ScenarioId scenarioId;
          final List<CourseSummary> courses;

          factory CourseListResponse.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'response');
            return CourseListResponse(
              schemaVersion: _catalogSchemaVersion(json),
              requestId: _catalogString(json, 'request_id'),
              scenarioId: ScenarioId.parse(json['scenario_id']),
              courses: List<CourseSummary>.unmodifiable(
                _catalogList(json, 'courses').map(CourseSummary.fromJson),
              ),
            );
          }
        }

        class TypicalDuration {
          const TypicalDuration({required this.value, required this.unit});

          final num value;
          final String unit;

          factory TypicalDuration.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'typical_duration');
            return TypicalDuration(
              value: _catalogPositiveNumber(json, 'value'),
              unit: _catalogString(json, 'unit', nonEmpty: true),
            );
          }
        }

        class CourseDetail extends CourseSummary {
          const CourseDetail({
            required super.courseId,
            required super.courseVersionId,
            required super.titleEn,
            required super.summaryZh,
            required super.levelCode,
            required super.contentBindingRef,
            required this.typicalDuration,
            this.backgroundAssetRef,
          });

          final TypicalDuration typicalDuration;
          final String? backgroundAssetRef;

          factory CourseDetail.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'course');
            final CourseSummary summary = CourseSummary.fromJson(json);
            return CourseDetail(
              courseId: summary.courseId,
              courseVersionId: summary.courseVersionId,
              titleEn: summary.titleEn,
              summaryZh: summary.summaryZh,
              levelCode: summary.levelCode,
              contentBindingRef: summary.contentBindingRef,
              typicalDuration: TypicalDuration.fromJson(json['typical_duration']),
              backgroundAssetRef: _catalogNullableString(json, 'background_asset_ref'),
            );
          }
        }

        class CourseDetailResponse {
          const CourseDetailResponse({
            required this.schemaVersion,
            required this.requestId,
            required this.course,
          });

          final int schemaVersion;
          final String requestId;
          final CourseDetail course;

          factory CourseDetailResponse.fromJson(Object? value) {
            final Map<String, Object?> json = _catalogMap(value, 'response');
            return CourseDetailResponse(
              schemaVersion: _catalogSchemaVersion(json),
              requestId: _catalogString(json, 'request_id'),
              course: CourseDetail.fromJson(json['course']),
            );
          }
        }
        // END GENERATED CONTENT CATALOG DTOs
        '''
    ).strip()


def write_generated_catalog_section():
    if not GENERATED_DART.exists():
        raise ValueError(f"missing generated Dart entrypoint: {GENERATED_DART}")
    source = GENERATED_DART.read_text(encoding="utf-8")
    section = generated_catalog_section()
    if CATALOG_SECTION_START in source or CATALOG_SECTION_END in source:
        pattern = re.compile(
            re.escape(CATALOG_SECTION_START) + r".*?" + re.escape(CATALOG_SECTION_END),
            re.DOTALL,
        )
        if len(pattern.findall(source)) != 1:
            raise ValueError("generated catalog DTO markers are incomplete or duplicated")
        updated = pattern.sub(section, source)
    else:
        anchor = "class SpeakeasyApiContract {"
        if anchor not in source:
            raise ValueError("cannot locate SpeakeasyApiContract insertion point")
        updated = source.replace(anchor, section + "\n\n" + anchor, 1)
    GENERATED_DART.write_text(updated, encoding="utf-8", newline="\n")


def generated_catalog_drift(generated_text):
    pattern = re.compile(
        re.escape(CATALOG_SECTION_START) + r".*?" + re.escape(CATALOG_SECTION_END),
        re.DOTALL,
    )
    matches = pattern.findall(generated_text)
    if len(matches) != 1:
        return "generated Dart client is missing one canonical catalog DTO section"
    if matches[0] != generated_catalog_section():
        return "generated catalog DTO drift detected; run: python scripts/check_openapi_dart_drift.py --write"
    return None


def handwritten_path_literals(path):
    if not path.exists():
        return set()
    text = path.read_text(encoding="utf-8")
    literals = set()
    for match in re.finditer(r"""(?P<quote>['"])(/[^'"]+)(?P=quote)""", text):
        literal = match.group(2)
        if literal.startswith("//"):
            continue
        literals.add(literal)
    return literals


def main(write=False):
    errors = []
    spec = load_spec()
    errors.extend(require_catalog_contract(spec))
    if write and not errors:
        try:
            write_generated_catalog_section()
        except ValueError as error:
            errors.append(str(error))
    current_hash = sha256(SPEC_PATH)
    openapi_paths = set(path_templates(spec))

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
        dart_files = list(target.rglob("*.dart"))
        if not dart_files:
            errors.append("generated Dart client directory exists but contains no Dart files")
        else:
            generated_text = dart_source_text(target)
            catalog_drift = generated_catalog_drift(generated_text)
            if catalog_drift:
                errors.append(catalog_drift)
            if current_hash not in generated_text:
                errors.append("generated Dart client does not embed the current OpenAPI hash")
            missing_paths = [path for path in sorted(openapi_paths) if path not in generated_text]
            if missing_paths:
                errors.append(
                    "generated Dart client is missing OpenAPI path templates: "
                    + ", ".join(missing_paths[:12])
                    + (" ..." if len(missing_paths) > 12 else "")
                )
            openapi_level_codes = (((spec.get("components") or {}).get("schemas") or {}).get("LevelCode") or {}).get("enum")
            generated_level_codes = generated_level_code_values(generated_text)
            if not openapi_level_codes:
                errors.append("OpenAPI components.schemas.LevelCode must define an enum")
            elif generated_level_codes is None:
                errors.append("generated Dart client is missing typed LevelCode enum")
            elif generated_level_codes != openapi_level_codes:
                errors.append(
                    "generated Dart LevelCode values do not match OpenAPI: "
                    + f"generated={generated_level_codes}, openapi={openapi_level_codes}"
                )
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
    exceptions = set((manifest.get("handwritten_client_exceptions") or {}).keys())
    handwritten_paths = handwritten_path_literals(handwritten_client)
    untracked_paths = sorted(
        path for path in handwritten_paths
        if path not in openapi_paths and path not in exceptions
    )
    if untracked_paths:
        errors.append(
            "handwritten ApiClient uses paths that are neither OpenAPI paths nor documented exceptions: "
            + ", ".join(untracked_paths)
        )
    unused_exceptions = sorted(path for path in exceptions if path not in handwritten_paths)
    if unused_exceptions:
        errors.append(
            "Dart drift manifest has unused handwritten client exceptions: "
            + ", ".join(unused_exceptions)
        )

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
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--write",
        action="store_true",
        help="regenerate the deterministic Dart content catalog DTO section",
    )
    args = parser.parse_args()
    sys.exit(main(write=args.write))
