from pathlib import Path
import re
import sys

from validate_governance_contracts import validate_repository
from validate_story_slice_cutover import collect_candidate_authority_graph

ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = ROOT / ".agents" / "skills"

REQUIRED_SKILL_SECTIONS = [
    "## Overview",
    "## When to Use",
    "## When NOT to Use",
    "## Contract",
    "## Inputs",
    "## Outputs",
    "## Process",
    "## Red Flags",
    "## Verification",
]

NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)


def parse_frontmatter(text):
    match = FRONTMATTER_RE.match(text)
    if not match:
        return None
    data = {}
    for line in match.group(1).splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip()
    return data


def check_file_contains(root, path, text, sections, errors):
    for section in sections:
        if section not in text:
            errors.append(f"{path.relative_to(root)} missing required section {section}")


def validate_skills(root=ROOT):
    root = root.resolve()
    errors = []
    warnings = []
    skills_root = root / ".agents" / "skills"
    deprecated_root = root / "codex" / "skills"

    if deprecated_root.exists():
        errors.append("Deprecated codex/skills directory still exists")

    if not skills_root.exists():
        errors.append(".agents/skills directory is missing")
    else:
        active_skill_files = {
            path.resolve() for path in collect_candidate_authority_graph(root)
            if path.name == "SKILL.md" and ".agents/skills" in path.as_posix()
        }
        skill_dirs = sorted(path.parent for path in active_skill_files)
        if not skill_dirs:
            errors.append("candidate authority graph contains no active method Skills")

        for skill_dir in skill_dirs:
            name = skill_dir.name
            if not NAME_RE.match(name):
                errors.append(f"{skill_dir.relative_to(root)} must use kebab-case")

            skill_md = skill_dir / "SKILL.md"
            spec_md = skill_dir / "SPEC.md"

            if not skill_md.exists():
                errors.append(f"{skill_md.relative_to(root)} is missing")
                continue
            if spec_md.exists():
                errors.append(f"{spec_md.relative_to(root)} is a parallel maintenance layer; move conditional detail to references/")

            skill_text = skill_md.read_text(encoding="utf-8")
            frontmatter = parse_frontmatter(skill_text)
            if frontmatter is None:
                errors.append(f"{skill_md.relative_to(root)} missing YAML frontmatter")
            else:
                if frontmatter.get("name") != name:
                    errors.append(f"{skill_md.relative_to(root)} frontmatter name must match directory name")
                desc = frontmatter.get("description", "")
                if len(desc) < 80:
                    errors.append(f"{skill_md.relative_to(root)} description is too short")
                if "Use when" not in desc or "Do not use" not in desc:
                    errors.append(f"{skill_md.relative_to(root)} description must include 'Use when' and 'Do not use'")

            check_file_contains(root, skill_md, skill_text, REQUIRED_SKILL_SECTIONS, errors)

            extra_md = sorted(p for p in skill_dir.glob("*.md") if p.name != "SKILL.md")
            for path in extra_md:
                errors.append(f"{path.relative_to(root)} is an unsupported top-level skill document")

            for linked_name in re.findall(r"references/([A-Za-z0-9][A-Za-z0-9._-]*\.md)", skill_text):
                linked_path = skill_dir / "references" / linked_name
                if not linked_path.exists():
                    errors.append(f"{skill_md.relative_to(root)} links missing reference references/{linked_name}")
                else:
                    link_lines = [line for line in skill_text.splitlines() if f"references/{linked_name}" in line]
                    if not any(
                        re.search(r"\b(?:read|load)\b", line, re.I)
                        and re.search(r"\b(?:when|for|if|only)\b", line, re.I)
                        for line in link_lines
                    ):
                        errors.append(f"{linked_path.relative_to(root)} link must state when to read or load it")
                    if "references/" in linked_path.read_text(encoding="utf-8"):
                        errors.append(f"{linked_path.relative_to(root)} must not route to another reference")

        for retired in ("feature-spec-generate", "acceptance-criteria-generate"):
            if (skills_root / retired / "SKILL.md").exists():
                errors.append(f"retired Skill remains discoverable: {retired}")

    contract_errors, contract_warnings, _metrics = validate_repository(root)
    errors.extend(f"governance contract: {error}" for error in contract_errors)
    warnings.extend(f"governance contract: {warning}" for warning in contract_warnings)

    return errors, warnings


def main():
    errors, warnings = validate_skills(ROOT)

    print("Skill validation report")
    print(f"Root: {SKILLS_ROOT}")
    if warnings:
        print("\nWarnings:")
        for warning in warnings:
            print(f"- {warning}")
    if errors:
        print("\nErrors:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("\nResult: passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
