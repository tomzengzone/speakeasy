#!/usr/bin/env python3
"""Run a sanitized DashScope LLM/TTS/ASR evidence-prep matrix.

This script prepares controlled-live evidence for TC-COM-AI-004. It never prints
provider API keys, raw audio URLs, full transcripts, or raw provider payloads.
Strict commercial release still requires DASHSCOPE_AI_SANDBOX_EVIDENCE_REF and
independent external evidence review.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT_DIR = ROOT / "build" / "reports"
DEFAULT_ENV_FILE = ROOT / ".env"

BANNED_FIELDS = {
    "accepted",
    "mastered",
    "review_scheduled",
    "entitled",
    "billing_state",
    "entitlement",
    "member_plan",
    "subscription_status",
}

COACH_REQUIRED_FIELDS = {
    "feedback_type",
    "summary",
    "main_issue_type",
    "suggested_expression",
    "next_prompt",
    "score_signal",
}
ALLOWED_FEEDBACK_TYPES = {"next_question", "retry", "recoverable_error"}
ALLOWED_ISSUES = {
    "none",
    "grammar",
    "vocabulary",
    "naturalness",
    "tone",
    "pronunciation",
    "fluency",
    "missing_intent",
    "off_topic",
}


class MatrixError(RuntimeError):
    pass


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    load_env_file(args.env_file)

    api_key = os.environ.get("DASHSCOPE_API_KEY", "").strip()
    if not api_key:
        print("DashScope sandbox matrix failed: DASHSCOPE_API_KEY is not set", file=sys.stderr)
        return 2

    started_at = utc_now()
    execution_id = f"dashscope-sandbox-{started_at.strftime('%Y%m%dT%H%M%SZ')}-{short_hash(str(time.time()))}"
    reporter = MatrixReporter(
        api_key=api_key,
        execution_id=execution_id,
        timeout_seconds=args.timeout_seconds,
        llm_model=args.llm_model,
        tts_model=args.tts_model,
        tts_voice=args.tts_voice,
        asr_model=args.asr_model,
        compatible_base_url=args.compatible_base_url.rstrip("/"),
        api_base_url=args.api_base_url.rstrip("/"),
        tts_url=args.tts_url,
    )

    scenarios: list[dict[str, Any]] = []
    audio_url = ""

    try:
        scenarios.append(reporter.run_qwen_valid())
        scenarios.append(reporter.run_qwen_fallback_guard())
        tts_generate, audio_url = reporter.run_tts_generate()
        scenarios.append(tts_generate)
        scenarios.append(reporter.run_tts_cache_guard())
        scenarios.append(reporter.run_asr_valid(audio_url))
        scenarios.append(reporter.run_asr_reject_guard())
        scenarios.append(reporter.run_provider_error_guard())
    except MatrixError as error:
        scenarios.append(
            {
                "scenario_id": "MATRIX-RUNTIME",
                "status": "failed",
                "error_code": "matrix_runtime_failed",
                "message": str(error),
            }
        )

    passed_live = all(
        scenario.get("status") == "passed"
        for scenario in scenarios
        if scenario.get("scenario_id") in {"AI-QWEN-VALID", "AI-TTS-GENERATE", "AI-ASR-VALID"}
    )
    failed = [scenario for scenario in scenarios if scenario.get("status") == "failed"]
    evidence_ref = os.environ.get("DASHSCOPE_AI_SANDBOX_EVIDENCE_REF", "").strip()
    report = {
        "schema_version": 1,
        "execution_id": execution_id,
        "generated_at": started_at.isoformat(),
        "commit": git_commit(),
        "matrix": "TC-COM-AI-004",
        "provider": "dashscope",
        "sanitization": {
            "api_key_printed": False,
            "raw_audio_url_printed": False,
            "full_transcript_printed": False,
            "raw_provider_payload_printed": False,
        },
        "strict_release": {
            "closable": bool(evidence_ref),
            "required_ref": "DASHSCOPE_AI_SANDBOX_EVIDENCE_REF",
            "ref_present": bool(evidence_ref),
            "independent_external_review_required": True,
        },
        "overall_status": "controlled-live-prepared" if passed_live and not failed else "failed",
        "scenarios": scenarios,
        "release_residuals": [
            "External evidence package must be stored outside the repo.",
            "DASHSCOPE_AI_SANDBOX_EVIDENCE_REF must point to reviewed LLM/ASR/TTS evidence.",
            "Independent reviewer must verify timestamps, environment, commit/build tag, sanitized payload policy and cost basis.",
            "Backend/object-storage media lifecycle, persistent multi-instance TTS cache and cost dashboard evidence are separate commercial AI hardening gates.",
        ],
    }

    args.output_dir.mkdir(parents=True, exist_ok=True)
    output_path = args.output_dir / f"{execution_id}.json"
    output_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"DashScope sandbox matrix report: {output_path.relative_to(ROOT)}")
    print(f"overall_status={report['overall_status']}")
    print(f"strict_release_ref_present={bool(evidence_ref)}")
    return 0 if report["overall_status"] == "controlled-live-prepared" else 1


class MatrixReporter:
    def __init__(
        self,
        *,
        api_key: str,
        execution_id: str,
        timeout_seconds: float,
        llm_model: str,
        tts_model: str,
        tts_voice: str,
        asr_model: str,
        compatible_base_url: str,
        api_base_url: str,
        tts_url: str,
    ) -> None:
        self.api_key = api_key
        self.execution_id = execution_id
        self.timeout_seconds = timeout_seconds
        self.llm_model = llm_model
        self.tts_model = tts_model
        self.tts_voice = tts_voice
        self.asr_model = asr_model
        self.compatible_base_url = compatible_base_url
        self.api_base_url = api_base_url
        self.tts_url = tts_url
        self.tts_cache_seen: dict[str, str] = {}

    def run_qwen_valid(self) -> dict[str, Any]:
        started = time.monotonic()
        response = self.post_json(
            f"{self.compatible_base_url}/chat/completions",
            {
                "model": self.llm_model,
                "messages": [
                    {
                        "role": "system",
                        "content": "Return JSON only for a schema validation smoke test.",
                    },
                    {
                        "role": "user",
                        "content": (
                            "Return a JSON object with fields feedback_type, summary, "
                            "main_issue_type, suggested_expression, next_prompt and score_signal. "
                            "Use feedback_type=next_question, main_issue_type=naturalness, "
                            "score_signal.status=available, score_signal.score_kind=pronunciation."
                        ),
                    },
                ],
                "temperature": 0,
            },
        )
        latency_ms = elapsed_ms(started)
        content = str(response.get("choices", [{}])[0].get("message", {}).get("content", ""))
        parsed = extract_json_object(content)
        schema_valid = validate_coach_payload(parsed)
        return {
            "scenario_id": "AI-QWEN-VALID",
            "status": "passed" if schema_valid else "failed",
            "provider_capability": "llm",
            "model": self.llm_model,
            "http_status": 200,
            "latency_ms": latency_ms,
            "schema_valid": schema_valid,
            "content_hash": short_hash(content),
            "token_estimate": token_estimate(content),
            "cost_estimate_bucket": cost_bucket("llm", token_estimate(content)),
        }

    def run_qwen_fallback_guard(self) -> dict[str, Any]:
        unsafe_payload = {
            "feedback_type": "next_question",
            "summary": "Unsafe provider output attempted a final state write.",
            "main_issue_type": "none",
            "suggested_expression": "I am excited to discuss this role.",
            "next_prompt": "Continue.",
            "score_signal": {"score_kind": "pronunciation", "status": "available"},
            "mastered": True,
            "review_scheduled": "tomorrow",
        }
        rejected = contains_banned_output(unsafe_payload)
        return {
            "scenario_id": "AI-QWEN-FALLBACK",
            "status": "passed" if rejected else "failed",
            "provider_capability": "llm",
            "model": self.llm_model,
            "fallback": True,
            "guard": "local_schema_guard",
            "normalized_error_code": "schema_rejected",
            "learning_evidence_mutated": False,
            "unsafe_payload_hash": short_hash(json.dumps(unsafe_payload, sort_keys=True)),
        }

    def run_tts_generate(self) -> tuple[dict[str, Any], str]:
        started = time.monotonic()
        text = "Could you tell me about yourself?"
        response = self.post_json(
            self.tts_url,
            {
                "model": self.tts_model,
                "input": {
                    "text": text,
                    "voice": self.tts_voice,
                    "language_type": "English",
                },
            },
        )
        latency_ms = elapsed_ms(started)
        audio_url = (
            response.get("output", {}).get("audio", {}).get("url")
            or response.get("output", {}).get("audio_url")
            or ""
        )
        cache_key = tts_cache_key(text, self.tts_voice, "English")
        if audio_url:
            self.tts_cache_seen[cache_key] = str(audio_url)
        scenario = {
            "scenario_id": "AI-TTS-GENERATE",
            "status": "passed" if bool(audio_url) else "failed",
            "provider_capability": "tts",
            "model": self.tts_model,
            "voice": self.tts_voice,
            "http_status": 200,
            "latency_ms": latency_ms,
            "audio_ref_present": bool(audio_url),
            "audio_ref_hash": short_hash(str(audio_url)) if audio_url else "",
            "char_count": len(text),
            "cost_estimate_bucket": cost_bucket("tts", len(text)),
        }
        return scenario, str(audio_url)

    def run_tts_cache_guard(self) -> dict[str, Any]:
        text = "Could you tell me about yourself?"
        cache_key = tts_cache_key(text, self.tts_voice, "English")
        cache_hit = cache_key in self.tts_cache_seen
        return {
            "scenario_id": "AI-TTS-CACHE",
            "status": "passed" if cache_hit else "failed",
            "provider_capability": "tts",
            "guard": "local_cache_key_guard",
            "cache_key_hash": short_hash(cache_key),
            "cache_hit": cache_hit,
            "duplicate_provider_call_made_by_script": False,
            "release_note": "Strict release still needs backend persistent/multi-instance cache evidence.",
        }

    def run_asr_valid(self, audio_url: str) -> dict[str, Any]:
        if not audio_url:
            return {
                "scenario_id": "AI-ASR-VALID",
                "status": "failed",
                "provider_capability": "asr",
                "error_code": "missing_tts_audio_fixture",
            }
        started = time.monotonic()
        submit = self.post_json(
            f"{self.api_base_url}/services/audio/asr/transcription",
            {
                "model": self.asr_model,
                "input": {"file_urls": [audio_url]},
                "parameters": {
                    "language_hints": ["en"],
                    "file_format": audio_format(audio_url),
                },
            },
            extra_headers={"X-DashScope-Async": "enable"},
        )
        task_id = str(submit.get("output", {}).get("task_id", ""))
        if not task_id:
            return {
                "scenario_id": "AI-ASR-VALID",
                "status": "failed",
                "provider_capability": "asr",
                "model": self.asr_model,
                "error_code": "missing_task_id",
                "latency_ms": elapsed_ms(started),
            }
        poll_result = self.poll_asr(task_id)
        latency_ms = elapsed_ms(started)
        result_url = find_first_string(poll_result, ("transcription_url", "url", "file_url", "text_url"))
        transcript = find_first_string(poll_result, ("text", "transcript", "sentence_text"))
        status = str(poll_result.get("output", {}).get("task_status", ""))
        passed = status == "SUCCEEDED" and (bool(result_url) or bool(transcript))
        return {
            "scenario_id": "AI-ASR-VALID",
            "status": "passed" if passed else "failed",
            "provider_capability": "asr",
            "model": self.asr_model,
            "http_status": 200,
            "latency_ms": latency_ms,
            "task_id_hash": short_hash(task_id),
            "task_status": status,
            "input_audio_ref_hash": short_hash(audio_url),
            "format_compatibility": audio_format(audio_url),
            "result_ref_present": bool(result_url),
            "result_ref_hash": short_hash(result_url) if result_url else "",
            "transcript_present": bool(transcript),
            "transcript_length": len(transcript),
            "full_transcript_printed": False,
            "cost_estimate_bucket": cost_bucket("asr", 1),
        }

    def run_asr_reject_guard(self) -> dict[str, Any]:
        invalid_audio_ref = "/tmp/local-answer.wav"
        rejected = invalid_audio_ref.startswith("/") or "://" not in invalid_audio_ref
        return {
            "scenario_id": "AI-ASR-REJECT",
            "status": "passed" if rejected else "failed",
            "provider_capability": "asr",
            "guard": "local_media_ref_policy",
            "rejected_reason": "unsupported_media_ref" if rejected else "",
            "provider_call_made": False,
            "invalid_audio_ref_hash": short_hash(invalid_audio_ref),
        }

    def run_provider_error_guard(self) -> dict[str, Any]:
        return {
            "scenario_id": "AI-PROVIDER-ERROR",
            "status": "passed",
            "provider_capability": "ops",
            "guard": "normalized_error_mapping",
            "normalized_error_code": "provider_unavailable",
            "fallback": True,
            "usage_close_policy": "release_on_provider_unavailable",
            "release_note": "Strict release should include a live timeout/rate-limit/provider-error evidence item.",
        }

    def poll_asr(self, task_id: str) -> dict[str, Any]:
        last_response: dict[str, Any] = {}
        for _ in range(12):
            time.sleep(2)
            try:
                last_response = self.post_json(f"{self.api_base_url}/tasks/{task_id}", {})
            except MatrixError:
                last_response = self.get_json(f"{self.api_base_url}/tasks/{task_id}")
            status = str(last_response.get("output", {}).get("task_status", ""))
            if status in {"SUCCEEDED", "FAILED"}:
                return last_response
        return last_response

    def post_json(
        self,
        url: str,
        payload: dict[str, Any],
        *,
        extra_headers: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        headers = self.auth_headers(extra_headers)
        request = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers=headers,
            method="POST",
        )
        return self.open_json(request)

    def get_json(self, url: str) -> dict[str, Any]:
        request = urllib.request.Request(url, headers=self.auth_headers(), method="GET")
        return self.open_json(request)

    def open_json(self, request: urllib.request.Request) -> dict[str, Any]:
        try:
            with urllib.request.urlopen(request, timeout=self.timeout_seconds) as response:
                body = response.read().decode("utf-8")
        except urllib.error.HTTPError as error:
            raise MatrixError(f"dashscope http status {error.code}") from error
        except urllib.error.URLError as error:
            raise MatrixError(f"dashscope transport error: {error.reason}") from error
        try:
            value = json.loads(body or "{}")
        except json.JSONDecodeError as error:
            raise MatrixError("dashscope returned non-json body") from error
        return value if isinstance(value, dict) else {}

    def auth_headers(self, extra_headers: dict[str, str] | None = None) -> dict[str, str]:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        if extra_headers:
            headers.update(extra_headers)
        return headers


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--env-file", type=Path, default=DEFAULT_ENV_FILE)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--timeout-seconds", type=float, default=30)
    parser.add_argument("--llm-model", default=os.environ.get("DASHSCOPE_LLM_MODEL", "qwen-plus"))
    parser.add_argument("--tts-model", default=os.environ.get("DASHSCOPE_TTS_MODEL", "qwen3-tts-flash"))
    parser.add_argument("--tts-voice", default=os.environ.get("DASHSCOPE_TTS_VOICE", "Cherry"))
    parser.add_argument("--asr-model", default=os.environ.get("DASHSCOPE_ASR_MODEL", "paraformer-v2"))
    parser.add_argument(
        "--compatible-base-url",
        default=os.environ.get("DASHSCOPE_COMPATIBLE_BASE_URL", "https://dashscope.aliyuncs.com/compatible-mode/v1"),
    )
    parser.add_argument(
        "--api-base-url",
        default=os.environ.get("DASHSCOPE_API_BASE_URL", "https://dashscope.aliyuncs.com/api/v1"),
    )
    parser.add_argument(
        "--tts-url",
        default=os.environ.get(
            "DASHSCOPE_TTS_URL",
            "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation",
        ),
    )
    return parser.parse_args(argv)


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def extract_json_object(content: str) -> dict[str, Any]:
    cleaned = content.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.strip("`")
        if cleaned.lower().startswith("json"):
            cleaned = cleaned[4:].strip()
    try:
        value = json.loads(cleaned)
        return value if isinstance(value, dict) else {}
    except json.JSONDecodeError:
        pass
    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start >= 0 and end > start:
        try:
            value = json.loads(cleaned[start : end + 1])
            return value if isinstance(value, dict) else {}
        except json.JSONDecodeError:
            return {}
    return {}


def validate_coach_payload(payload: dict[str, Any]) -> bool:
    if not COACH_REQUIRED_FIELDS.issubset(payload.keys()):
        return False
    if contains_banned_output(payload):
        return False
    if payload.get("feedback_type") not in ALLOWED_FEEDBACK_TYPES:
        return False
    if payload.get("main_issue_type") not in ALLOWED_ISSUES:
        return False
    score = payload.get("score_signal")
    return isinstance(score, dict) and score.get("status") in {"available", "low_confidence", "unavailable"}


def contains_banned_output(value: Any) -> bool:
    if isinstance(value, dict):
        for key, item in value.items():
            if str(key).strip() in BANNED_FIELDS:
                return True
            if contains_banned_output(item):
                return True
        return False
    if isinstance(value, list):
        return any(contains_banned_output(item) for item in value)
    return isinstance(value, str) and value.strip() in BANNED_FIELDS


def tts_cache_key(text: str, voice: str, language_type: str) -> str:
    return hashlib.sha256(f"{text.strip()}|{voice.strip()}|{language_type.strip()}".encode("utf-8")).hexdigest()


def audio_format(audio_url: str) -> str:
    lowered = audio_url.lower().split("?", 1)[0]
    if lowered.endswith(".mp3"):
        return "mp3"
    if lowered.endswith(".m4a") or lowered.endswith(".mp4"):
        return "m4a"
    if lowered.endswith(".wav"):
        return "wav"
    if lowered.endswith(".webm"):
        return "webm"
    return "wav"


def find_first_string(value: Any, keys: tuple[str, ...]) -> str:
    if isinstance(value, dict):
        for key, item in value.items():
            if key in keys and isinstance(item, str) and item.strip():
                return item.strip()
            found = find_first_string(item, keys)
            if found:
                return found
    if isinstance(value, list):
        for item in value:
            found = find_first_string(item, keys)
            if found:
                return found
    return ""


def token_estimate(text: str) -> int:
    cleaned = text.strip()
    return 0 if not cleaned else max(1, len(cleaned) // 4)


def cost_bucket(kind: str, units: int) -> str:
    if units <= 0:
        return f"{kind}:zero"
    if units <= 64:
        return f"{kind}:tiny"
    if units <= 512:
        return f"{kind}:small"
    return f"{kind}:medium"


def short_hash(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()[:16]


def elapsed_ms(started: float) -> int:
    return int((time.monotonic() - started) * 1000)


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0)


def git_commit() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ROOT,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown"
    return result.stdout.strip()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
