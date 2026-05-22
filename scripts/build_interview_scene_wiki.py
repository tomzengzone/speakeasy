#!/usr/bin/env python3
"""Compile the authored interview scene Wiki markdown into app JSON."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


DEFAULT_SOURCE = Path("/Users/tang/WorkBuddy/20260428214045/英语面试场景Wiki_v2.md")
DEFAULT_OUTPUT = Path("assets/data/interview_scene_wikis/job_interview.json")
DEFAULT_LEGACY_OUTPUT = Path("assets/data/interview_scene_wiki.json")


NODE_ID_PATTERN = r"(?:interview_\d{2}|L[123]_\d{2})"

TAG_BY_NODE_ID = {
    "interview_01": "自我介绍",
    "interview_02": "自我介绍",
    "interview_03": "自我介绍",
    "interview_04": "经历阐述",
    "interview_05": "经历阐述",
    "interview_06": "经历阐述",
    "interview_07": "优势说明",
    "interview_08": "岗位认知",
    "interview_09": "反问提问",
    "interview_10": "反问提问",
}

TAG_BY_SLOT = {
    1: "自我介绍",
    2: "自我介绍",
    3: "自我介绍",
    4: "经历阐述",
    5: "经历阐述",
    6: "优势说明",
    7: "压力回应",
    8: "岗位认知",
    9: "职业规划",
    10: "反问提问",
    11: "反问提问",
    12: "劣势应答",
    13: "反问提问",
}

STAGE_LABEL_BY_SLOT = {
    1: "开场感谢",
    2: "当前职位",
    3: "经验领域",
    4: "经历成就",
    5: "问题解决",
    6: "优势说明",
    7: "压力回应",
    8: "求职动机",
    9: "职业规划",
    10: "反向提问",
    11: "后续流程",
    12: "应对难题",
    13: "结束致谢",
}

QUESTION_BY_SLOT = {
    1: "Hi, welcome. Thanks for coming in today. How would you respond at the start of the interview?",
    2: "Could you start by telling me what you currently do and where you work?",
    3: "How much experience do you have, and what field is it in?",
    4: "Tell me about one project or achievement from your previous work.",
    5: "Can you describe a problem you solved at work and what changed afterward?",
    6: "What would you say is one of your key strengths?",
    7: "How do you usually handle pressure at work?",
    8: "What are you looking for in your next role?",
    9: "Where do you see yourself in the next five years?",
    10: "Do you have a question for me about the day-to-day responsibilities of this role?",
    11: "Before we wrap up, what would you like to ask about the hiring process?",
    12: "Suppose I ask about an area you do not know well. How would you respond honestly and positively?",
    13: "We are wrapping up now. What would you like to say to close the conversation?",
}

FOLLOWUP_BY_SLOT = {
    1: "Could you include both thanks and a positive attitude?",
    2: "Could you include your current role and company?",
    3: "Could you include your years of experience and your field?",
    4: "Could you mention the action you took and the result?",
    5: "Could you include the problem, your action, and the improvement?",
    6: "Could you name one specific strength rather than a general quality?",
    7: "Could you explain how pressure affects your focus or working style?",
    8: "Could you connect your motivation to growth or the role itself?",
    9: "Could you make your five-year plan a little more concrete?",
    10: "Could you ask about the work someone in this role does day to day?",
    11: "Could you ask about the next step in the hiring process?",
    12: "Could you be honest about the gap and still show you are willing to learn?",
    13: "Could you close with thanks and a positive note about the conversation?",
}

TARGET_LEVEL_BY_WIKI_LEVEL = {
    "L1": "beginner",
    "L2": "intermediate",
    "L3": "advanced",
}

FALLBACK_QUESTION_BY_NODE_ID = {
    "interview_01": "Hi, welcome. Thanks for coming in today. How would you respond at the start of the interview?",
    "interview_02": "It's good to meet you. How would you greet the interviewer in a more formal way?",
    "interview_03": "Could you start by telling me what you currently do and where you work?",
    "interview_04": "Could you add how many years of experience you have and what you specialize in?",
    "interview_05": "Tell me about one project or achievement you're particularly proud of.",
    "interview_06": "Can you give me an example of a time you improved a process or solved a problem?",
    "interview_07": "What would you say is one of your key strengths?",
    "interview_08": "Why are you interested in our company?",
    "interview_09": "Before we wrap up, what would you like to ask me about this position?",
    "interview_10": "We're wrapping up now. What would you like to say to close the conversation?",
}

FOLLOWUP_QUESTION_BY_NODE_ID = {
    "interview_01": "Could you make that opening response sound a little more natural and positive?",
    "interview_02": "Could you say that again in a slightly more formal interview style?",
    "interview_03": "Could you include both your current role and your company?",
    "interview_04": "Could you include both your years of experience and your focus area?",
    "interview_05": "Could you include your action and one concrete result?",
    "interview_06": "Could you mention the problem, what you implemented, and the result?",
    "interview_07": "Could you name one specific strength rather than a general quality?",
    "interview_08": "Could you connect your interest to something specific about the company?",
    "interview_09": "Could you ask one question about success in the role?",
    "interview_10": "Could you close with thanks and a positive note about the conversation?",
}


def split_markdown_row(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def strip_annotations(value: str) -> str:
    return re.sub(r"（[^）]*）", "", value).strip()


def extract_ids(value: str) -> list[str]:
    if "无" in value or "场景结束" in value or "回到面试流程" in value:
        return []
    return re.findall(NODE_ID_PATTERN, value)


def node_level(node_id: str) -> str:
    match = re.match(r"(L[123])_\d{2}", node_id)
    return match.group(1) if match else ""


def node_slot(node_id: str) -> int:
    match = re.search(r"_(\d{2})$", node_id)
    return int(match.group(1)) if match else 0


def target_level(node_id: str) -> str:
    return TARGET_LEVEL_BY_WIKI_LEVEL.get(node_level(node_id), "scene_wiki")


def parse_target_table(lines: list[str]) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for line in lines:
        stripped = line.strip()
        if not re.match(rf"^\|\s*{NODE_ID_PATTERN}\s*\|", stripped):
            continue
        cells = split_markdown_row(stripped)
        if len(cells) < 5:
            continue
        node_id, target_text, intent, natural_timing, dependencies = cells[:5]
        slot = node_slot(node_id)
        result[node_id] = {
            "id": node_id,
            "targetText": target_text,
            "intent": intent,
            "naturalTiming": natural_timing,
            "dependencies": extract_ids(dependencies),
            "level": node_level(node_id),
            "targetLevel": target_level(node_id),
            "slot": slot,
            "isRescue": slot == 12,
        }
    return result


def section_blocks(text: str) -> dict[str, str]:
    pattern = re.compile(
        rf"^### 表达 ({NODE_ID_PATTERN})：(.+?)\n(?P<body>.*?)(?=^### 表达 {NODE_ID_PATTERN}：|^## 板块4：|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    return {match.group(1): match.group("body") for match in pattern.finditer(text)}


def parse_bullets_between(body: str, heading: str, next_headings: list[str]) -> list[str]:
    start = body.find(heading)
    if start < 0:
        return []
    content = body[start + len(heading) :]
    end_positions = [content.find(item) for item in next_headings if content.find(item) >= 0]
    if end_positions:
        content = content[: min(end_positions)]
    rows: list[str] = []
    for line in content.splitlines():
        line = line.strip()
        if line.startswith("- "):
            rows.append(line[2:].strip())
    return rows


def parse_hooks(body: str) -> list[dict[str, str]]:
    rows = parse_bullets_between(
        body,
        "**引导钩子**",
        ["**预期用户回复变体**", "**常见错误与纠正**", "**提示树**"],
    )
    hooks: list[dict[str, str]] = []
    for row in rows:
        match = re.match(r"([A-Z])\.（([^）]+)）：(.+)", row)
        if not match:
            continue
        hooks.append(
            {
                "id": match.group(1),
                "type": match.group(2).strip(),
                "text": match.group(3).strip(),
            }
        )
    return hooks


def clean_variant(row: str) -> str:
    text = strip_annotations(row)
    text = re.sub(r"^[✅⚠️❌]\s*", "", text).strip()
    return text


def parse_variants(body: str) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    rows = parse_bullets_between(
        body,
        "**预期用户回复变体**",
        ["**常见错误与纠正**", "**提示树**", "**前驱/后继表达**"],
    )
    variants: list[dict[str, str]] = []
    near_misses: list[dict[str, str]] = []
    for index, row in enumerate(rows):
        text = clean_variant(row)
        if not text:
            continue
        if "❌" in row or "⚠️" in row:
            near_misses.append({"text": text, "kind": "near_miss"})
        else:
            variants.append({"text": text, "kind": "target" if index == 0 else "variant"})
    return variants, near_misses


def parse_errors(body: str) -> list[dict[str, str]]:
    rows = parse_bullets_between(
        body,
        "**常见错误与纠正**",
        ["**提示树**", "**前驱/后继表达**"],
    )
    errors: list[dict[str, str]] = []
    for row in rows:
        match = re.match(r"❌\s*(.+?)\s*→\s*✅\s*(.+?)（(.+)）", row)
        if not match:
            continue
        errors.append(
            {
                "wrong": match.group(1).strip(),
                "better": match.group(2).strip(),
                "reason": match.group(3).strip(),
            }
        )
    return errors


def parse_hint_tree(body: str) -> dict[str, str]:
    rows = parse_bullets_between(
        body,
        "**提示树**",
        ["**前驱/后继表达**"],
    )
    hints: dict[str, str] = {}
    for row in rows:
        match = re.match(r"(L[1-4])(?:（[^）]*）)?：(.+)", row)
        if not match:
            continue
        hints[match.group(1)] = match.group(2).strip()
    return hints


def parse_description(body: str, label: str) -> str:
    match = re.search(rf"- {re.escape(label)}：(.+)", body)
    return match.group(1).strip() if match else ""


def parse_graph_edges(body: str, label: str) -> list[str]:
    match = re.search(rf"- {re.escape(label)}：(.+)", body)
    return extract_ids(match.group(1)) if match else []


def parse_phases(text: str) -> list[dict[str, Any]]:
    phases: list[dict[str, Any]] = []
    for match in re.finditer(r"\*\*Phase\s+(\d+)\s+—\s+(.+?)\*\*：(.+)", text):
        ids = extract_ids(match.group(3))
        if not ids:
            continue
        phases.append(
            {
                "id": f"phase_{match.group(1)}",
                "title": match.group(2).strip(),
                "nodeIds": ids,
            }
        )
    return phases


def build_level_tracks(nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:
    tracks: list[dict[str, Any]] = []
    titles = {"L1": "L1 入门", "L2": "L2 进阶", "L3": "L3 精通"}
    for level in ("L1", "L2", "L3"):
        ids = [
            node["id"]
            for node in sorted(nodes, key=lambda item: item.get("slot", 0))
            if node.get("level") == level
        ]
        if ids:
            tracks.append(
                {
                    "id": level,
                    "title": titles[level],
                    "targetLevel": TARGET_LEVEL_BY_WIKI_LEVEL[level],
                    "nodeIds": ids,
                }
            )
    if not tracks:
        ids = [node["id"] for node in nodes]
        if ids:
            tracks.append(
                {
                    "id": "default",
                    "title": "默认主线",
                    "targetLevel": "beginner",
                    "nodeIds": ids,
                }
            )
    return tracks


def build_level_map(nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_slot: dict[int, dict[str, str]] = {}
    for node in nodes:
        slot = node.get("slot", 0)
        level = node.get("level", "")
        if slot and level:
            by_slot.setdefault(slot, {})[level] = node["id"]
    return [
        {
            "slot": slot,
            "label": STAGE_LABEL_BY_SLOT.get(slot, f"表达 {slot:02d}"),
            "levels": by_slot[slot],
        }
        for slot in sorted(by_slot)
    ]


def parse_meta(lines: list[str]) -> dict[str, Any]:
    meta: dict[str, Any] = {
        "id": "job_interview",
        "titleCn": "英语面试",
        "titleEn": "Job Interview in English",
        "description": "",
        "tags": [],
    }
    for line in lines:
        if not line.strip().startswith("|"):
            continue
        cells = split_markdown_row(line)
        if len(cells) < 2:
            continue
        key = re.sub(r"[*（）()]", "", cells[0]).strip()
        value = cells[1].strip()
        if key == "场景名称中文":
            meta["titleCn"] = value
        elif key == "场景名称英文":
            meta["titleEn"] = value
        elif key == "场景标签":
            meta["tags"] = [item.strip("#") for item in value.split() if item.strip()]
        elif key == "场景描述":
            meta["description"] = value
    return meta


def inferred_slots(text: str) -> list[dict[str, str]]:
    slots: list[dict[str, str]] = []
    slot_patterns = {
        "role": r"\b(designer|senior designer|team leader)\b",
        "company": r"\b(XYZ|small company|small firm)\b",
        "field": r"\b(marketing|digital marketing|content marketing|user experience)\b",
        "duration": r"\b(three years|four years|five years|over five years)\b",
        "metric": r"\b(30%|two weeks|50 hours|a third)\b",
    }
    for name, pattern in slot_patterns.items():
        match = re.search(pattern, text, flags=re.IGNORECASE)
        if match:
            slots.append({"name": name, "example": match.group(0)})
    return slots


def build_scene_graph(source: Path) -> dict[str, Any]:
    text = source.read_text(encoding="utf-8")
    lines = text.splitlines()
    target_rows = parse_target_table(lines)
    blocks = section_blocks(text)
    nodes: list[dict[str, Any]] = []
    for node_id, row in target_rows.items():
        body = blocks.get(node_id, "")
        slot = row.get("slot", node_slot(node_id))
        variants, near_misses = parse_variants(body)
        node = {
            **row,
            "tag": TAG_BY_NODE_ID.get(node_id, TAG_BY_SLOT.get(slot, "自我介绍")),
            "stageLabel": STAGE_LABEL_BY_SLOT.get(slot, row["intent"]),
            "question": FALLBACK_QUESTION_BY_NODE_ID.get(node_id, QUESTION_BY_SLOT.get(slot, row["naturalTiming"])),
            "followupQuestion": FOLLOWUP_QUESTION_BY_NODE_ID.get(node_id, FOLLOWUP_BY_SLOT.get(slot, row["naturalTiming"])),
            "meaning": parse_description(body, "中文释义"),
            "usage": parse_description(body, "使用场景说明"),
            "pragmaticNote": parse_description(body, "语用提示"),
            "hooks": parse_hooks(body),
            "expectedVariants": variants,
            "nearMissVariants": near_misses,
            "errors": parse_errors(body),
            "hintTree": parse_hint_tree(body),
            "previousIds": parse_graph_edges(body, "前驱"),
            "nextIds": parse_graph_edges(body, "后继"),
            "equivalentIds": [
                candidate["id"]
                for candidate in target_rows.values()
                if candidate.get("slot") == slot and candidate["id"] != node_id
            ],
            "slots": inferred_slots(row["targetText"]),
        }
        nodes.append(node)

    tracks = build_level_tracks(nodes)
    phases = parse_phases(text)
    if not phases:
        phases = [
            {
                "id": track["id"],
                "title": track["title"],
                "nodeIds": track["nodeIds"],
            }
            for track in tracks
        ]
    phase_by_node = {
        node_id: phase["id"] for phase in phases for node_id in phase["nodeIds"]
    }
    for node in nodes:
        node["phaseId"] = phase_by_node.get(node["id"], "")
    default_flow = tracks[0]["nodeIds"] if tracks else [node["id"] for node in nodes]

    graph = {
        "schemaVersion": 2,
        "meta": parse_meta(lines),
        "phases": phases,
        "tracks": tracks,
        "levelMap": build_level_map(nodes),
        "nodes": nodes,
        "flow": default_flow,
        "transitionPolicy": {
            "afterEvery": 2,
            "messages": [
                "That's a really strong answer. I can tell you've thought a lot about this.",
                "I appreciate you being so specific. That really helps me understand your experience.",
                "Great, that gives me a really good picture. Before we wrap up...",
            ],
        },
    }
    validate_graph(graph)
    return graph


def validate_graph(graph: dict[str, Any]) -> None:
    nodes = graph["nodes"]
    if not nodes:
        raise ValueError("scene graph must contain nodes")
    node_ids = {node["id"] for node in nodes}
    for node in nodes:
        for key in ("id", "targetText", "intent", "hooks", "hintTree", "expectedVariants"):
            if not node.get(key):
                raise ValueError(f"{node['id']} missing required field: {key}")
        for ref_key in ("dependencies", "previousIds", "nextIds"):
            for ref in node.get(ref_key, []):
                if ref not in node_ids:
                    raise ValueError(f"{node['id']} has unknown {ref_key}: {ref}")
    if not any(not node.get("dependencies") for node in nodes):
        raise ValueError("scene graph needs at least one start node")
    if not any(not node.get("nextIds") for node in nodes):
        raise ValueError("scene graph needs at least one terminal node")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--legacy-output", type=Path, default=DEFAULT_LEGACY_OUTPUT)
    parser.add_argument("--skip-legacy-output", action="store_true")
    args = parser.parse_args()
    graph = build_scene_graph(args.source)
    payload = json.dumps(graph, indent=2, ensure_ascii=False) + "\n"
    output_paths = [args.output]
    if not args.skip_legacy_output:
        output_paths.append(args.legacy_output)
    for output in output_paths:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(payload, encoding="utf-8")
        print(f"Wrote {len(graph['nodes'])} interview scene nodes -> {output}")


if __name__ == "__main__":
    main()
