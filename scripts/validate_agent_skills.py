\
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = ROOT / ".agents" / "skills"
DEPRECATED_ROOT = ROOT / "codex" / "skills"

REQUIRED_SKILL_SECTIONS = [
    "## Overview",
    "## When to Use",
    "## When NOT to Use",
    "## Inputs",
    "## Outputs",
    "## 文档路径约定",
    "## Process",
    "## Red Flags",
    "## Verification",
    "## Common Rationalizations",
]

REQUIRED_SPEC_SECTIONS = [
    "## Purpose",
    "## Scope",
    "## Trigger Context",
    "## Inputs",
    "## Outputs",
    "## Quality Bar",
    "## Maintenance Notes",
    "## External References",
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


def check_file_contains(path, text, sections, errors):
    for section in sections:
        if section not in text:
            errors.append(f"{path.relative_to(ROOT)} missing required section {section}")


def main():
    errors = []
    warnings = []

    if DEPRECATED_ROOT.exists():
        errors.append("Deprecated codex/skills directory still exists")

    if not SKILLS_ROOT.exists():
        errors.append(".agents/skills directory is missing")
    else:
        skill_dirs = sorted(p for p in SKILLS_ROOT.iterdir() if p.is_dir())
        if not skill_dirs:
            errors.append(".agents/skills contains no skill directories")

        for skill_dir in skill_dirs:
            name = skill_dir.name
            if not NAME_RE.match(name):
                errors.append(f"{skill_dir.relative_to(ROOT)} must use kebab-case")

            skill_md = skill_dir / "SKILL.md"
            spec_md = skill_dir / "SPEC.md"

            if not skill_md.exists():
                errors.append(f"{skill_md.relative_to(ROOT)} is missing")
                continue
            if not spec_md.exists():
                errors.append(f"{spec_md.relative_to(ROOT)} is missing")

            skill_text = skill_md.read_text(encoding="utf-8")
            frontmatter = parse_frontmatter(skill_text)
            if frontmatter is None:
                errors.append(f"{skill_md.relative_to(ROOT)} missing YAML frontmatter")
            else:
                if frontmatter.get("name") != name:
                    errors.append(f"{skill_md.relative_to(ROOT)} frontmatter name must match directory name")
                desc = frontmatter.get("description", "")
                if len(desc) < 80:
                    errors.append(f"{skill_md.relative_to(ROOT)} description is too short")
                if "Use when" not in desc or "Do not use" not in desc:
                    errors.append(f"{skill_md.relative_to(ROOT)} description must include 'Use when' and 'Do not use'")

            check_file_contains(skill_md, skill_text, REQUIRED_SKILL_SECTIONS, errors)
            if "| Rationalization | Reality |" not in skill_text:
                warnings.append(f"{skill_md.relative_to(ROOT)} should use the rationalization table format")

            if spec_md.exists():
                spec_text = spec_md.read_text(encoding="utf-8")
                check_file_contains(spec_md, spec_text, REQUIRED_SPEC_SECTIONS, errors)
                if "http" not in spec_text:
                    warnings.append(f"{spec_md.relative_to(ROOT)} should include external references")

            extra_md = [p.name for p in skill_dir.glob("*.md") if p.name not in {"SKILL.md", "SPEC.md"}]
            if extra_md:
                warnings.append(f"{skill_dir.relative_to(ROOT)} has extra markdown files: {', '.join(extra_md)}")

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
