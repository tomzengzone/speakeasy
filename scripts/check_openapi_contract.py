from pathlib import Path
import sys

import yaml


SPEC_PATH = Path("docs/architecture/openapi/speakeasy-api.yaml")
METHODS = {"get", "put", "post", "delete", "patch", "head", "options", "trace"}
FUTURE_PATH_TOKENS = {
    "/memory",
    "/adaptive",
    "/team",
    "/b2b",
    "/certification",
    "/notebook",
    "/vocabulary",
    "/cms",
}


def load_spec():
    return yaml.safe_load(SPEC_PATH.read_text(encoding="utf-8"))


def resolve_ref(spec, ref):
    current = spec
    for part in ref[2:].split("/"):
        part = part.replace("~1", "/").replace("~0", "~")
        current = current[part]
    return current


def has_example(media):
    return bool(media.get("example") is not None or media.get("examples"))


def json_media(content):
    if not isinstance(content, dict):
        return None
    media = content.get("application/json")
    return media if isinstance(media, dict) else None


def response_object(spec, response):
    if isinstance(response, dict) and "$ref" in response:
        return resolve_ref(spec, response["$ref"])
    return response


def iter_operations(spec):
    for path, path_item in (spec.get("paths") or {}).items():
        if not isinstance(path_item, dict):
            continue
        for method, operation in path_item.items():
            if method in METHODS and isinstance(operation, dict):
                yield path, method, operation


def main():
    spec = load_spec()
    errors = []
    paths = spec.get("paths") or {}

    for token in FUTURE_PATH_TOKENS:
        if any(token in path for path in paths):
            errors.append(f"future boundary path leaked into implementation OpenAPI: {token}")

    deferred = spec.get("x-deferred-boundaries") or {}
    for key in ("p0_2", "p1", "p2"):
        boundary = deferred.get(key)
        if not isinstance(boundary, dict):
            errors.append(f"missing deferred boundary metadata: {key}")
        elif boundary.get("prohibited_endpoint_generation") is not True:
            errors.append(f"deferred boundary is not protected from endpoint generation: {key}")

    operation_ids = set()
    operation_count = 0
    request_example_count = 0
    success_example_count = 0
    error_example_count = 0

    for path, method, operation in iter_operations(spec):
        operation_count += 1
        label = f"{method.upper()} {path}"
        operation_id = operation.get("operationId")
        if not operation_id:
            errors.append(f"missing operationId: {label}")
        elif operation_id in operation_ids:
            errors.append(f"duplicate operationId: {operation_id}")
        else:
            operation_ids.add(operation_id)

        traceability = operation.get("x-traceability")
        if not isinstance(traceability, dict):
            errors.append(f"missing x-traceability: {label}")
        else:
            if not traceability.get("product_objects"):
                errors.append(f"missing x-traceability.product_objects: {label}")
            if not traceability.get("requirements"):
                errors.append(f"missing x-traceability.requirements: {label}")

        request_body = operation.get("requestBody")
        if isinstance(request_body, dict):
            media = json_media(request_body.get("content"))
            if media is None:
                errors.append(f"requestBody missing application/json media: {label}")
            elif has_example(media):
                request_example_count += 1
            else:
                errors.append(f"requestBody missing JSON example: {label}")

        responses = operation.get("responses") or {}
        success_seen = False
        json_success_with_example = False
        for status, response in responses.items():
            resolved_response = response_object(spec, response)
            if not isinstance(resolved_response, dict):
                continue
            media = json_media(resolved_response.get("content"))
            status_text = str(status)
            if status_text.startswith("2"):
                success_seen = True
                if media is None:
                    continue
                if has_example(media):
                    json_success_with_example = True
                    success_example_count += 1
                else:
                    errors.append(f"success response missing JSON example: {label} {status}")
            if status_text.startswith("4"):
                if media is None:
                    errors.append(f"4XX response missing application/json media: {label} {status}")
                elif has_example(media):
                    error_example_count += 1
                else:
                    errors.append(f"4XX response missing JSON example: {label} {status}")
        if not success_seen:
            errors.append(f"operation has no 2XX response: {label}")
        if success_seen and any(
            str(status).startswith("2")
            and json_media(response_object(spec, response).get("content") if isinstance(response_object(spec, response), dict) else None)
            for status, response in responses.items()
        ) and not json_success_with_example:
            errors.append(f"operation has no 2XX JSON response example: {label}")

    if errors:
        for error in errors:
            print(error)
        return 1

    print(
        "OpenAPI contract gate passed: "
        f"{len(paths)} paths, {operation_count} operations, "
        f"{request_example_count} request examples, "
        f"{success_example_count} success examples, "
        f"{error_example_count} error examples"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
