#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

DOC_PREFIXES = (
    "docs/",
    "codex/templates/",
)
EXCLUDED_PREFIXES = (
    "docs/archive/",
)
EXCLUDED_FILES = {
    "docs/reports/quality_report.md",
}

ASCII_WORD_RE = re.compile(r"\b[A-Za-z][A-Za-z0-9_-]*\b")
CJK_RE = re.compile(r"[\u4e00-\u9fff]")
INLINE_CODE_RE = re.compile(r"`[^`]*`")
LINK_URL_RE = re.compile(r"\]\([^)]*\)")
TECH_TOKEN_RE = re.compile(
    r"\b(?:"
    r"SWC|FE|BE|DB|AI|OPS|API|OpenAPI|ID|FR|AC|TC|MIG|P0|P01|TTS|ASR|CI|PR|DTO|"
    r"Flutter|Dart|Java|YAML|JSON|HTTP|GET|POST|PUT|PATCH|DELETE|"
    r"frontend|backend|database|provider|runtime|cache|schema|template|agent|skill"
    r")\b",
    re.IGNORECASE,
)


def run_git(args: list[str]) -> str:
    completed = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        text=True,
        encoding="utf-8",
        errors="replace",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    return completed.stdout if completed.returncode == 0 else ""


def changed_paths(base_ref: str | None, include_worktree: bool) -> list[str]:
    names: set[str] = set()
    if base_ref and not re.fullmatch(r"0{40}", base_ref):
        output = run_git(["diff", "--name-only", "--diff-filter=ACMRT", f"{base_ref}...HEAD"])
        if not output:
            output = run_git(["diff", "--name-only", "--diff-filter=ACMRT", base_ref, "HEAD"])
        names.update(line.strip().replace("\\", "/") for line in output.splitlines() if line.strip())
    if include_worktree:
        for args in (
            ["diff", "--name-only", "--diff-filter=ACMRT"],
            ["diff", "--cached", "--name-only", "--diff-filter=ACMRT"],
            ["ls-files", "--others", "--exclude-standard"],
        ):
            names.update(line.strip().replace("\\", "/") for line in run_git(args).splitlines() if line.strip())
    return sorted(name for name in names if (ROOT / name).exists())


def all_doc_paths() -> list[str]:
    paths: list[str] = []
    for prefix in DOC_PREFIXES:
        base = ROOT / prefix
        if not base.exists():
            continue
        paths.extend(path.relative_to(ROOT).as_posix() for path in base.rglob("*.md"))
    return sorted(path for path in paths if is_checked_doc(path))


def is_checked_doc(relative: str) -> bool:
    if not relative.endswith(".md"):
        return False
    if relative in EXCLUDED_FILES:
        return False
    if not any(relative.startswith(prefix) for prefix in DOC_PREFIXES):
        return False
    return not any(relative.startswith(prefix) for prefix in EXCLUDED_PREFIXES)


def added_lines(relative: str) -> list[tuple[int, str]]:
    output = run_git(["diff", "--unified=0", "--", relative])
    if not output:
        output = run_git(["diff", "--cached", "--unified=0", "--", relative])
    if not output:
        return []

    lines: list[tuple[int, str]] = []
    new_line = 0
    for raw in output.splitlines():
        header = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@", raw)
        if header:
            new_line = int(header.group(1))
            continue
        if raw.startswith("+++") or raw.startswith("---"):
            continue
        if raw.startswith("+"):
            lines.append((new_line, raw[1:]))
            new_line += 1
        elif raw.startswith("-"):
            continue
        else:
            new_line += 1
    return lines


def full_file_lines(relative: str) -> list[tuple[int, str]]:
    text = (ROOT / relative).read_text(encoding="utf-8", errors="replace")
    return [(index, line) for index, line in enumerate(text.splitlines(), start=1)]


def strip_markdown_noise(line: str) -> str:
    line = INLINE_CODE_RE.sub("", line)
    line = LINK_URL_RE.sub("]", line)
    line = re.sub(r"https?://\S+", "", line)
    line = re.sub(r"<!--.*?-->", "", line)
    return line.strip()


def is_schema_or_technical_line(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return True
    if stripped in {"---", "```", "```text", "```bash", "```python"}:
        return True
    if stripped.startswith("-> "):
        return True
    if re.fullmatch(r"[\|\-\:\s]+", stripped):
        return True
    if stripped.startswith("|") and stripped.endswith("|") and stripped.count("|") >= 3:
        return True
    if re.fullmatch(r"[-*]\s*`[^`]+`", stripped):
        return True
    if stripped.startswith(("- ", "* ")):
        return False
    if re.fullmatch(r"#*\s*[A-Za-z0-9_./<>:-]+(?:\s+[A-Za-z0-9_./<>:-]+){0,5}", stripped):
        return True
    return False


def english_prose_line(line: str) -> bool:
    if CJK_RE.search(line):
        return False
    if is_schema_or_technical_line(line):
        return False
    cleaned = strip_markdown_noise(line)
    if not cleaned or CJK_RE.search(cleaned):
        return False

    words = ASCII_WORD_RE.findall(cleaned)
    if len(words) < 5:
        return False
    tech_words = [word for word in words if TECH_TOKEN_RE.fullmatch(word)]
    prose_words = [word for word in words if word not in tech_words]
    return len(prose_words) >= 5


def prose_blocks(lines: list[tuple[int, str]]) -> list[list[tuple[int, str]]]:
    blocks: list[list[tuple[int, str]]] = []
    current: list[tuple[int, str]] = []
    in_fence = False
    for line_number, line in lines:
        stripped = line.strip()
        if stripped.startswith("```"):
            if current:
                blocks.append(current)
                current = []
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if not stripped or is_schema_or_technical_line(line):
            if current:
                blocks.append(current)
                current = []
            continue
        current.append((line_number, line))
    if current:
        blocks.append(current)
    return blocks


def block_has_cjk(block: list[tuple[int, str]]) -> bool:
    return any(CJK_RE.search(line) for _, line in block)


def block_has_english_prose(block: list[tuple[int, str]]) -> bool:
    return any(english_prose_line(line) for _, line in block)


def first_english_prose_line(block: list[tuple[int, str]]) -> int:
    for line_number, line in block:
        if english_prose_line(line):
            return line_number
    return block[0][0]


def check_lines(relative: str, lines: list[tuple[int, str]]) -> list[str]:
    findings: list[str] = []
    blocks = prose_blocks(lines)
    for index, block in enumerate(blocks):
        if not block_has_english_prose(block) or block_has_cjk(block):
            continue
        next_block = blocks[index + 1] if index + 1 < len(blocks) else []
        if next_block and block_has_cjk(next_block):
            continue
        line_number = first_english_prose_line(block)
        findings.append(
            f"{relative}:{line_number}: persistent project docs must use Chinese prose, "
            "or place a Chinese translation immediately after the English prose block."
        )
    return findings


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    parser = argparse.ArgumentParser(
        description="Check that persistent project Markdown docs use Chinese prose or bilingual English/Chinese blocks."
    )
    parser.add_argument("--scope", choices=("changed", "all"), default="changed")
    parser.add_argument("--base-ref")
    parser.add_argument("--include-worktree", action="store_true")
    args = parser.parse_args(argv)

    if args.scope == "all":
        paths = all_doc_paths()
        line_source = full_file_lines
    else:
        paths = [path for path in changed_paths(args.base_ref, args.include_worktree) if is_checked_doc(path)]
        untracked = set(run_git(["ls-files", "--others", "--exclude-standard"]).splitlines())

        def line_source(path: str) -> list[tuple[int, str]]:
            if path in untracked:
                return full_file_lines(path)
            diff_lines = added_lines(path)
            return diff_lines if diff_lines else full_file_lines(path)

    findings: list[str] = []
    for path in paths:
        findings.extend(check_lines(path, line_source(path)))

    print("Document language gate")
    if findings:
        print("Result: failed")
        for finding in findings:
            print(f"- {finding}")
        return 1
    print("Result: passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
