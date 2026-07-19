from pathlib import Path
import re
import sys

from validate_governance_contracts import validate_repository

ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = ROOT / ".agents" / "skills"

REQUIRED_SKILL_SECTIONS = [
    "## Overview",
    "## Contract",
    "## Inputs",
    "## Outputs",
    "## Process",
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
    errors = []
    warnings = []
    skills_root = root / ".agents" / "skills"
    deprecated_root = root / "codex" / "skills"

    if deprecated_root.exists():
        errors.append("Deprecated codex/skills directory still exists")

    if not skills_root.exists():
        errors.append(".agents/skills directory is missing")
    else:
        skill_dirs = sorted(p for p in skills_root.iterdir() if p.is_dir())
        if not skill_dirs:
            errors.append(".agents/skills contains no skill directories")

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

            references_dir = skill_dir / "references"
            if references_dir.exists():
                nested_dirs = sorted(p for p in references_dir.iterdir() if p.is_dir())
                for path in nested_dirs:
                    errors.append(f"{path.relative_to(root)} creates nested reference routing")
                non_markdown = sorted(p for p in references_dir.iterdir() if p.is_file() and p.suffix.lower() != ".md")
                for path in non_markdown:
                    errors.append(f"{path.relative_to(root)} must be Markdown or move to scripts/assets")

                for reference in sorted(references_dir.glob("*.md")):
                    relative_link = f"references/{reference.name}"
                    link_lines = [line for line in skill_text.splitlines() if relative_link in line]
                    if not link_lines:
                        errors.append(f"{reference.relative_to(root)} is not linked directly from SKILL.md")
                    elif not any(
                        re.search(r"\b(?:read|load)\b", line, re.I)
                        and re.search(r"\b(?:when|for|if|only)\b", line, re.I)
                        for line in link_lines
                    ):
                        errors.append(f"{reference.relative_to(root)} link must state when to read or load it")
                    if "references/" in reference.read_text(encoding="utf-8"):
                        errors.append(f"{reference.relative_to(root)} must not route to another reference")

            for linked_name in re.findall(r"references/([A-Za-z0-9][A-Za-z0-9._-]*\.md)", skill_text):
                linked_path = skill_dir / "references" / linked_name
                if not linked_path.exists():
                    errors.append(f"{skill_md.relative_to(root)} links missing reference references/{linked_name}")

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
