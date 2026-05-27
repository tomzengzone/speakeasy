from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AGENTS_ROOT = ROOT / "codex" / "agents"
TEMPLATE_PATH = ROOT / "codex" / "templates" / "agent_runner_packet.template.md"

REQUIRED_AGENT_SECTIONS = (
    "## Role",
    "## Responsibilities",
    "## Inputs",
    "## Outputs",
    "## Allowed Paths",
    "## Rules",
)

REQUIRED_TEMPLATE_PLACEHOLDERS = (
    "{{AGENT_DEFINITION_PATH}}",
    "{{AGENT_NAME}}",
    "{{TASK}}",
    "{{UPSTREAM_HANDOFF}}",
    "{{AGENT_DEFINITION}}",
)


def repo_path(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def normalize_agent_name(name: str) -> str:
    return name.strip().lower().replace("-", "_").removesuffix(".md")


def agent_path(name: str) -> Path:
    normalized = normalize_agent_name(name)
    return AGENTS_ROOT / f"{normalized}.md"


def load_agent(name: str) -> tuple[str, Path, str]:
    path = agent_path(name)
    if not path.exists():
        known = ", ".join(list_agents())
        raise SystemExit(f"Unknown project agent: {name}\nKnown agents: {known}")
    return path.stem, path, path.read_text(encoding="utf-8")


def list_agents() -> list[str]:
    if not AGENTS_ROOT.exists():
        return []
    return sorted(path.stem for path in AGENTS_ROOT.glob("*.md"))


def validate_agents() -> int:
    errors: list[str] = []
    if not AGENTS_ROOT.exists():
        errors.append("codex/agents directory is missing")
    for path in sorted(AGENTS_ROOT.glob("*.md")):
        text = path.read_text(encoding="utf-8")
        for section in REQUIRED_AGENT_SECTIONS:
            if section not in text:
                errors.append(f"{repo_path(path)} missing required section {section}")

    if not TEMPLATE_PATH.exists():
        errors.append(f"{repo_path(TEMPLATE_PATH)} is missing")
    else:
        template = TEMPLATE_PATH.read_text(encoding="utf-8")
        for placeholder in REQUIRED_TEMPLATE_PLACEHOLDERS:
            if placeholder not in template:
                errors.append(f"{repo_path(TEMPLATE_PATH)} missing required placeholder {placeholder}")

    print("Project agent runner validation")
    print(f"Agents root: {repo_path(AGENTS_ROOT)}")
    if errors:
        print("\nErrors:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("\nResult: passed")
    return 0


def read_handoff(path_value: str | None) -> str:
    if not path_value:
        return "No upstream handoff."
    path = (ROOT / path_value).resolve() if not Path(path_value).is_absolute() else Path(path_value)
    try:
        path.relative_to(ROOT)
    except ValueError as exc:
        raise SystemExit(f"Handoff path must stay inside repository: {path}") from exc
    if not path.exists():
        raise SystemExit(f"Handoff file does not exist: {repo_path(path)}")
    return path.read_text(encoding="utf-8").strip() or "Upstream handoff file is empty."


def render_packet(agent: str, task: str, handoff_path: str | None) -> str:
    agent_name, path, definition = load_agent(agent)
    handoff = read_handoff(handoff_path)
    template = TEMPLATE_PATH.read_text(encoding="utf-8")
    return (
        template.replace("{{AGENT_NAME}}", agent_name)
        .replace("{{AGENT_DEFINITION_PATH}}", repo_path(path))
        .replace("{{TASK}}", task.strip())
        .replace("{{UPSTREAM_HANDOFF}}", handoff)
        .replace("{{AGENT_DEFINITION}}", definition.strip())
    )


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8")

    parser = argparse.ArgumentParser(
        description="Load project-local codex/agents/*.md definitions and emit execution packets."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("list", help="List available project-local agents.")
    subparsers.add_parser("validate", help="Validate project-local agent definitions and runner template.")

    packet_parser = subparsers.add_parser("packet", help="Render an execution packet for one project agent.")
    packet_parser.add_argument("agent", help="Agent name, for example product_manager or system-architect.")
    packet_parser.add_argument("--task", required=True, help="Task this agent must handle.")
    packet_parser.add_argument("--handoff", help="Repository-relative upstream handoff file.")
    packet_parser.add_argument("--output", help="Repository-relative file to write. Defaults to stdout.")

    args = parser.parse_args(argv)
    if args.command == "list":
        for agent in list_agents():
            print(agent)
        return 0
    if args.command == "validate":
        return validate_agents()
    if args.command == "packet":
        packet = render_packet(args.agent, args.task, args.handoff)
        if args.output:
            output = (ROOT / args.output).resolve()
            try:
                output.relative_to(ROOT)
            except ValueError as exc:
                raise SystemExit(f"Output path must stay inside repository: {output}") from exc
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(packet + "\n", encoding="utf-8")
        else:
            print(packet)
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
