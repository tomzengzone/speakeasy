#!/usr/bin/env python3
"""Compile expression-specific context analysis into interview scene Wiki JSON."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SCENE_WIKI_DIR = ROOT / "assets/data/interview_scene_wikis"
LEGACY_JOB_WIKI = ROOT / "assets/data/interview_scene_wiki.json"


JOB_STAGE_ANALYSIS: dict[str, dict[str, str]] = {
    "开场感谢": {
        "when": "用于面试开场：面试官欢迎或感谢你到场后，用来稳稳接住第一轮互动。",
        "purpose": "它的作用是同时传达礼貌和积极状态，让对话从一开始就专业、自然。",
        "practiceFocus": "练习时把感谢说稳，再把 excited 或 glad 的积极语气放轻，不要过度热情。",
    },
    "当前职位": {
        "when": "用于自我介绍前半段：对方想快速了解你现在做什么时。",
        "purpose": "它的作用是先给出职位身份和工作范围，帮面试官建立你的职业坐标。",
        "practiceFocus": "练习时把 role、company、focus 三个信息说清楚，不要一次塞太多细节。",
    },
    "经验领域": {
        "when": "用于自我介绍或背景追问：面试官问你有多少经验、主要做什么领域时。",
        "purpose": "它的作用是用一句话压缩年限、领域和专长，让你的背景听起来有结构。",
        "practiceFocus": "练习时先说年限，再说领域，最后补一个主要方向，保持一句话完成。",
    },
    "经历成就": {
        "when": "用于项目经历或成就追问：对方想听你做过什么、带来什么结果时。",
        "purpose": "它的作用是把经历从职责描述推进到实际贡献，让回答更有证据感。",
        "practiceFocus": "练习时按情境、动作、结果的顺序说，结果可以短，但不能完全缺失。",
    },
    "问题解决": {
        "when": "用于解决问题类追问：面试官想判断你是否能发现问题并推动改进时。",
        "purpose": "它的作用是把问题、行动和改进结果连起来，展示可迁移的问题解决能力。",
        "practiceFocus": "练习时不要只说 helped，要说清楚你发现了什么、做了什么、变好了什么。",
    },
    "优势说明": {
        "when": "用于能力或优势提问：对方问你 strengths、key skills 或核心优势时。",
        "purpose": "它的作用是把优势说成能在工作中产生价值的能力，而不是空泛形容词。",
        "practiceFocus": "练习时把 strength 后面的能力对象说具体，例如解释复杂问题、推动协作或影响决策。",
    },
    "压力回应": {
        "when": "用于压力、截止日期或高风险情境追问：对方想看你的处理方式是否稳定。",
        "purpose": "它的作用是说明你面对压力时有方法，而不是只说 I can handle pressure。",
        "practiceFocus": "练习时语速放稳，重点说出 prioritizing、communicating 或 clarifying 这类处理动作。",
    },
    "求职动机": {
        "when": "用于动机提问：面试官问你为什么找这个岗位或下一步想要什么时。",
        "purpose": "它的作用是把求职原因包装成成长、贡献和岗位匹配，而不是逃离现状。",
        "practiceFocus": "练习时避免抱怨上一份工作，把 contribute、grow、role fit 说得自然。",
    },
    "职业规划": {
        "when": "用于未来规划提问：对方问你未来几年想怎么发展时。",
        "purpose": "它的作用是展示方向感和成长意愿，同时保持现实、不夸口。",
        "practiceFocus": "练习时用 hope、want、would like 这类软化表达，不要说成僵硬承诺。",
    },
    "反向提问": {
        "when": "用于面试反问环节：对方问 Do you have any questions for me? 时。",
        "purpose": "它的作用是通过一个具体问题展示你认真了解岗位，而不是随便问一句。",
        "practiceFocus": "练习时把问题问完整，重点落在 day-to-day、success 或 role expectation 上。",
    },
    "后续流程": {
        "when": "用于面试接近结束：你需要礼貌确认后续流程或是否还需补充信息时。",
        "purpose": "它的作用是推进下一步，同时保持候选人的专业和主动。",
        "practiceFocus": "练习时用 could you share / I'd love to know 让问题听起来礼貌，不要像催结果。",
    },
    "应对难题": {
        "when": "用于被问到不熟悉领域时：你需要承认空白，但不能让回答停在 I don't know。",
        "purpose": "它的作用是诚实说明经验缺口，再把话题拉回学习能力和积极态度。",
        "practiceFocus": "练习时先承认 haven't had direct experience，再补 learn quickly 或 build that skill。",
    },
    "结束致谢": {
        "when": "用于面试收尾：对话结束前，你想留下礼貌、积极、愿意继续沟通的印象。",
        "purpose": "它的作用是完成感谢、兴趣确认和后续开放态度，让收尾更完整。",
        "practiceFocus": "练习时不要只说 thank you，最好补一句 conversation、role 或 next step 相关的信息。",
    },
}


ONBOARDING_STAGE_ANALYSIS: dict[str, dict[str, str]] = {
    "欢迎回应": {
        "when": "用于入职第一天：主管或团队欢迎你之后，你需要自然回应大家。",
        "purpose": "它的作用是快速建立友好、积极的新同事形象，不需要像面试那样正式。",
        "practiceFocus": "练习时把 greeting 和 excited/happy 说自然，语气轻松但不要过度夸张。",
    },
    "岗位说明": {
        "when": "用于自我介绍开头：你需要告诉同事自己加入后的岗位和工作方向。",
        "purpose": "它的作用是让团队快速知道你是谁、负责什么、之后会和哪些工作有关。",
        "practiceFocus": "练习时先说 role，再说 focus，不要一开始就展开太多背景细节。",
    },
    "背景经历": {
        "when": "用于介绍完岗位之后：你想补充入职前的经验，让同事理解你的背景。",
        "purpose": "它的作用是把过往经历和新团队需求连接起来，而不是单纯报履历。",
        "practiceFocus": "练习时把 before joining / before this 说顺，再补一个和团队相关的经验价值。",
    },
    "职责范围": {
        "when": "用于同事想了解你接下来负责什么：尤其是跨团队协作或流程相关工作。",
        "purpose": "它的作用是说明职责边界和协作方式，让别人知道什么时候可以找你。",
        "practiceFocus": "练习时把 main responsibility 后面的动作说具体，例如 track、support、turn priorities into processes。",
    },
    "相关经验": {
        "when": "用于补充自己能带来的经验：对方想知道你过去做过哪些相关事情时。",
        "purpose": "它的作用是用一个简短经历建立可信度，让新团队知道你不是从零开始。",
        "practiceFocus": "练习时说清过去动作和结果，不要只说 I helped，要补 team updates、issues 或 improvements。",
    },
    "学习态度": {
        "when": "用于表达刚加入时的心态：你想说明自己会主动学习和适应。",
        "purpose": "它的作用是展示谦逊和主动性，让同事放心你会及时提问、记录和跟进。",
        "practiceFocus": "练习时把 learning curve 和 proactive 说得自然，不要听起来像没有信心。",
    },
    "优先事项": {
        "when": "用于和主管或 mentor 对齐前几周重点：你需要知道先做什么最重要。",
        "purpose": "它的作用是把不确定变成清晰优先级，体现你不是被动等待任务。",
        "practiceFocus": "练习时用 Could you help me understand 开头，让问题听起来主动又礼貌。",
    },
    "工具流程": {
        "when": "用于了解团队工作方式：你需要确认沟通渠道、任务工具和文档流程。",
        "purpose": "它的作用是快速接入团队协作系统，减少因为工具或流程不熟带来的摩擦。",
        "practiceFocus": "练习时把 tools、channels、tasks、decisions 这些关键词说清楚。",
    },
    "主动贡献": {
        "when": "用于了解团队需求之后：你想表达自己可以尽早帮忙或承担一小块工作。",
        "purpose": "它的作用是传达积极贡献意愿，同时保留和团队优先级对齐的空间。",
        "practiceFocus": "练习时用 if there is an area / anything useful，避免听起来像抢活或承诺过满。",
    },
    "协作方式": {
        "when": "用于和新同事建立协作关系：你想了解大家偏好的沟通和工作方式。",
        "purpose": "它的作用是降低后续协作成本，让别人感到你重视团队习惯。",
        "practiceFocus": "练习时把 working style 或 prefer to communicate 说自然，语气要像真诚请教。",
    },
    "下一步安排": {
        "when": "用于欢迎会或介绍结束前：你需要确认今天之后该做什么。",
        "purpose": "它的作用是把介绍环节转成明确行动，避免结束后不知道下一步。",
        "practiceFocus": "练习时用 best next step / what should I do，让问题简短清晰。",
    },
    "不确定求助": {
        "when": "用于入职初期遇到流程或决策不确定时：你需要知道该和谁对齐。",
        "purpose": "它的作用是避免自己猜流程，也避免把小问题升级得太重。",
        "practiceFocus": "练习时说清 process、decision、align with，重点是先确认再推进。",
    },
    "感谢收尾": {
        "when": "用于入职介绍或欢迎会结束时：你想感谢欢迎，并表达期待合作。",
        "purpose": "它的作用是让收尾友好、有团队感，为之后合作留下积极印象。",
        "practiceFocus": "练习时把 warm welcome 和 looking forward 说顺，语气自然，不要像演讲。",
    },
}


JOB_RECOMMENDED_CARD_COPY: dict[str, dict[str, str]] = {
    "开场感谢": {
        "intent": "面试开场：先感谢对方安排会面，再表达你期待今天的交流。",
        "cue": "Thanks for coming in today. We're glad to have you here.",
    },
    "当前职位": {
        "intent": "自我介绍开头：说清你现在的岗位、公司类型和职业坐标。",
        "cue": "To start, could you tell me what you're doing currently?",
    },
    "经验领域": {
        "intent": "背景介绍：用一句话说明经验年限、所在领域和主要工作方向。",
        "cue": "How many years of experience do you have, and what area have you focused on?",
    },
    "经历成就": {
        "intent": "项目经历：用动作和结果证明你做成过一件具体的事。",
        "cue": "Could you tell me about a project or achievement you're proud of?",
    },
    "问题解决": {
        "intent": "问题解决：说明你发现了什么问题、采取了什么行动，并带来什么改进。",
        "cue": "Tell me about a time you noticed a problem and helped improve the process.",
    },
    "优势说明": {
        "intent": "优势回答：把强项说成能在工作中产生价值的具体能力。",
        "cue": "What is one strength you would bring to this role?",
    },
    "压力回应": {
        "intent": "压力回应：说明你在任务紧急时会先排序、保持专注，而不是只说能抗压。",
        "cue": "How do you handle pressure when several tasks are urgent?",
    },
    "求职动机": {
        "intent": "求职动机：把换工作的原因说成成长、贡献和岗位匹配。",
        "cue": "What are you looking for in your next role?",
    },
    "职业规划": {
        "intent": "未来规划：表达清晰的发展方向，同时保持现实、稳重。",
        "cue": "Where would you like to be in the next few years?",
    },
    "反向提问": {
        "intent": "反向提问：用一个具体问题展示你认真了解岗位日常。",
        "cue": "Do you have any questions about the role itself?",
    },
    "后续流程": {
        "intent": "流程确认：礼貌询问招聘下一步，同时保持专业主动。",
        "cue": "Before we finish, do you have any questions about the hiring process?",
    },
    "应对难题": {
        "intent": "经验缺口：先诚实承认暂未直接做过，再把重点转向学习能力。",
        "cue": "Have you worked directly with this tool or area before?",
    },
    "结束致谢": {
        "intent": "面试收尾：感谢对方时间，确认兴趣，并留下积极印象。",
        "cue": "Thanks for your time today. We'll be in touch after the interview.",
    },
}


ONBOARDING_RECOMMENDED_CARD_COPY: dict[str, dict[str, str]] = {
    "欢迎回应": {
        "intent": "入职欢迎：自然回应团队欢迎，表达你加入团队的积极心情。",
        "cue": "Welcome to the team. It's great to have you with us.",
    },
    "岗位说明": {
        "intent": "岗位介绍：告诉同事你加入后的角色和主要工作方向。",
        "cue": "Could you tell everyone what role you're joining in?",
    },
    "背景经历": {
        "intent": "背景连接：简短说明入职前经历，让同事理解你能带来的经验。",
        "cue": "Could you share a little about what you did before joining?",
    },
    "职责范围": {
        "intent": "职责边界：说明你主要支持什么工作，让同事知道什么时候可以找你。",
        "cue": "What will you mainly be helping the team with?",
    },
    "相关经验": {
        "intent": "经验证明：用过去做过的一件事说明你能支持新团队。",
        "cue": "Is there any past experience that will help you in this new role?",
    },
    "学习态度": {
        "intent": "学习态度：承认需要熟悉新环境，同时表现主动提问和跟进。",
        "cue": "How are you planning to get up to speed in the first few weeks?",
    },
    "优先事项": {
        "intent": "优先级确认：主动问清前期重点，避免自己猜方向。",
        "cue": "What would you like to ask your manager about first priorities?",
    },
    "工具流程": {
        "intent": "工具流程：问清团队使用的沟通、任务和文档工具。",
        "cue": "What do you need to know about our daily tools and channels?",
    },
    "主动贡献": {
        "intent": "主动贡献：表达愿意尽早帮忙，同时尊重团队优先级。",
        "cue": "If you want to help early, how would you offer support?",
    },
    "协作方式": {
        "intent": "协作方式：了解同事的工作和沟通偏好，让后续配合更顺。",
        "cue": "What would you like to learn about how the team works?",
    },
    "下一步安排": {
        "intent": "下一步安排：把欢迎介绍转成明确行动，确认接下来该做什么。",
        "cue": "After this introduction, what do you need to clarify?",
    },
    "不确定求助": {
        "intent": "不确定求助：遇到流程或决策不清楚时，先确认该问谁。",
        "cue": "If you're unsure about a process, what would you ask?",
    },
    "感谢收尾": {
        "intent": "欢迎会收尾：感谢大家欢迎，并表达期待合作。",
        "cue": "Before we wrap up the welcome meeting, what would you say?",
    },
}


RECOMMENDED_CARD_COPY_BY_SCENE: dict[str, dict[str, dict[str, str]]] = {
    "job_interview": JOB_RECOMMENDED_CARD_COPY,
    "onboarding_introduction": ONBOARDING_RECOMMENDED_CARD_COPY,
}


VARIANT_DIFFERENCE_BY_TYPE: dict[str, str] = {
    "concise": "这个变体更短、更直接，适合你想快速表达同一个意思时使用。",
    "natural": "这个变体更口语自然，适合想让句子听起来轻一点、顺一点的时候。",
    "polished": "这个变体更完整、更正式，适合你想把态度说得更稳、更专业时使用。",
    "native": "这个变体更接近母语者的自然组织方式，适合提升表达的流畅感。",
    "strategic": "这个变体更强调策略、影响或主动性，适合需要展示成熟度的时候。",
    "direct_question": "这个变体问得更直接，适合你只需要快速确认信息的时候。",
    "polished_question": "这个变体问得更礼貌完整，适合对主管、面试官或资深同事使用。",
}


VARIANT_FOCUS_BY_TYPE: dict[str, str] = {
    "concise": "练习时抓住「{anchor}」，句子变短也不要丢掉{goal}。",
    "natural": "练习时把「{anchor}」说成自然语流，顺着表达{goal}。",
    "polished": "练习时把「{anchor}」的礼貌铺垫和句尾说完整，让{goal}听起来稳但不僵硬。",
    "native": "练习时关注「{anchor}」的重音和停顿，用更自然的顺序表达{goal}。",
    "strategic": "练习时突出「{anchor}」，把{goal}说成可贡献、可推进的价值。",
    "direct_question": "练习时用「{anchor}」快速问清{goal}，语气短但要友好。",
    "polished_question": "练习时把「{anchor}」里的礼貌结构说顺，再完整问出{goal}。",
}


STAGE_PRACTICE_GOALS: dict[str, str] = {
    "开场感谢": "感谢和积极状态",
    "当前职位": "当前角色和工作范围",
    "经验领域": "年限、领域和方向",
    "经历成就": "动作和结果",
    "问题解决": "问题、行动和改进",
    "优势说明": "优势带来的工作价值",
    "压力回应": "压力下的处理动作",
    "求职动机": "成长、贡献和岗位匹配",
    "职业规划": "未来方向和成长意愿",
    "反向提问": "岗位成功标准",
    "后续流程": "下一步和补充材料",
    "应对难题": "经验缺口和学习态度",
    "结束致谢": "感谢、兴趣和后续开放态度",
    "欢迎回应": "感谢欢迎和加入期待",
    "岗位说明": "岗位身份和工作方向",
    "背景经历": "过往经验与新团队的连接",
    "职责范围": "职责边界和协作方向",
    "相关经验": "相关动作和结果",
    "学习态度": "学习曲线和主动跟进",
    "优先事项": "前期重点和优先级",
    "工具流程": "工具、渠道和决策流程",
    "主动贡献": "主动贡献和团队优先级",
    "协作方式": "沟通偏好和协作方式",
    "下一步安排": "下一步行动",
    "不确定求助": "流程确认和对齐对象",
    "感谢收尾": "感谢欢迎和期待合作",
}


ANCHOR_STOPWORDS = {
    "a",
    "about",
    "again",
    "am",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "been",
    "by",
    "for",
    "from",
    "had",
    "has",
    "have",
    "i",
    "i'd",
    "i'll",
    "i'm",
    "i've",
    "in",
    "into",
    "is",
    "it",
    "it's",
    "me",
    "my",
    "of",
    "on",
    "or",
    "our",
    "the",
    "this",
    "to",
    "we",
    "we'll",
    "what",
    "when",
    "where",
    "with",
    "you",
    "your",
}


def stage_analysis(scene_id: str, stage_label: str) -> dict[str, str]:
    if scene_id == "onboarding_introduction":
        return ONBOARDING_STAGE_ANALYSIS.get(stage_label, {})
    return JOB_STAGE_ANALYSIS.get(stage_label, {})


def node_expression_context(scene_id: str, node: dict[str, Any]) -> dict[str, str]:
    stage_label = str(node.get("stageLabel", "")).strip()
    analysis = dict(stage_analysis(scene_id, stage_label))
    if not analysis:
        natural_timing = str(node.get("naturalTiming", "")).strip()
        intent = str(node.get("intent", "")).strip()
        analysis = {
            "when": f"用于{natural_timing}。" if natural_timing else "",
            "purpose": f"它的作用是{intent}。" if intent else "",
            "practiceFocus": "练习时先确认使用位置，再把句子说得完整、自然。",
        }
    practice_focus = str(analysis.get("practiceFocus", "")).strip()
    if practice_focus:
        analysis["practiceFocus"] = node_practice_focus(node, practice_focus)
    return {key: value for key, value in analysis.items() if value}


def node_practice_focus(node: dict[str, Any], base_focus: str) -> str:
    anchor = focus_anchor(str(node.get("targetText", "")).strip())
    if not anchor:
        return base_focus
    focus = strip_practice_prefix(base_focus)
    return f"练习时先抓住「{anchor}」，{focus}"


def variant_context(
    scene_id: str,
    node: dict[str, Any],
    variant: dict[str, Any],
) -> dict[str, str]:
    stage_label = str(node.get("stageLabel", "")).strip()
    analysis = stage_analysis(scene_id, stage_label)
    variant_type = str(variant.get("type") or variant.get("kind") or "").strip()
    when = analysis.get("when", "")
    if when:
        when = f"和主句用在同一位置：{compact_when_for_variant(when)}"
    else:
        natural_timing = str(node.get("naturalTiming", "")).strip()
        when = f"和主句用在同一语境：{natural_timing}。" if natural_timing else "和主句用在同一语境，可以替换使用。"
    return {
        "when": when,
        "difference": VARIANT_DIFFERENCE_BY_TYPE.get(
            variant_type,
            "这个变体保留同一个表达任务，但换了一种更自然的说法。",
        ),
        "practiceFocus": variant_practice_focus(node, variant, variant_type),
    }


def variant_practice_focus(
    node: dict[str, Any],
    variant: dict[str, Any],
    variant_type: str,
) -> str:
    text = str(variant.get("text", "")).strip()
    anchor = focus_anchor(text) or focus_anchor(str(node.get("targetText", "")))
    goal = stage_practice_goal(node)
    template = VARIANT_FOCUS_BY_TYPE.get(
        variant_type,
        "练习时围绕「{anchor}」确认意思没有变，再把{goal}换一种说法练顺。",
    )
    return template.format(anchor=anchor or "关键词", goal=goal)


def stage_practice_goal(node: dict[str, Any]) -> str:
    stage_label = str(node.get("stageLabel", "")).strip()
    goal = STAGE_PRACTICE_GOALS.get(stage_label, "")
    if goal:
        return goal
    intent = str(node.get("intent", "")).strip()
    if intent:
        return intent
    return "同一个表达任务"


def strip_practice_prefix(value: str) -> str:
    return re.sub(r"^练习时", "", value.strip()).lstrip("，, ")


def focus_anchor(text: str) -> str:
    tokens = re.findall(r"[A-Za-z]+(?:'[A-Za-z]+)?|\d+", text)
    keywords: list[str] = []
    seen: set[str] = set()
    for token in tokens:
        normalized = token.lower()
        if normalized in ANCHOR_STOPWORDS:
            continue
        if normalized in seen:
            continue
        seen.add(normalized)
        keywords.append(token)
        if len(keywords) >= 4:
            break
    if not keywords:
        keywords = tokens[:4]
    return " / ".join(keywords)


def compact_when_for_variant(when: str) -> str:
    value = when.strip()
    for prefix in ("用于面试开场：", "用于入职第一天："):
        if value.startswith(prefix):
            return value.removeprefix(prefix)
    if value.startswith("用于"):
        return value.removeprefix("用于")
    return value


def clean_inline_markup(value: str) -> str:
    return re.sub(r"\*\*(.+?)\*\*", r"\1", value).strip()


def strip_sentence_end(value: str) -> str:
    return re.sub(r"[。.!?？]+$", "", value.strip())


def sentence_chunks(text: str) -> list[str]:
    chunks = [item.strip() for item in re.split(r"(?<=[.!?])\s+", text) if item.strip()]
    if len(chunks) > 1:
        return chunks
    if "," in text:
        parts = [item.strip() for item in text.split(",") if item.strip()]
        if len(parts) > 1:
            return parts[:3]
    return [text.strip()] if text.strip() else []


def card_copy_for_node(scene_id: str, node: dict[str, Any]) -> dict[str, str]:
    stage_label = str(node.get("stageLabel", "")).strip()
    copy = RECOMMENDED_CARD_COPY_BY_SCENE.get(scene_id, {}).get(stage_label)
    if copy:
        return copy
    return {
        "intent": str(node.get("meaning") or node.get("intent") or "").strip(),
        "cue": str(node.get("question") or node.get("usage") or "").strip(),
    }


def common_mistake_prompts(node: dict[str, Any]) -> list[str]:
    prompts: list[str] = []
    for error in node.get("errors", []):
        if not isinstance(error, dict):
            continue
        wrong = strip_sentence_end(clean_inline_markup(str(error.get("wrong", ""))))
        better = strip_sentence_end(clean_inline_markup(str(error.get("better", ""))))
        reason = strip_sentence_end(clean_inline_markup(str(error.get("reason", ""))))
        if not wrong:
            continue
        details: list[str] = [f"常见误句：{wrong}"]
        if reason:
            details.append(f"修正重点：{reason}")
        if better:
            details.append(f"更自然：{better}")
        prompts.append("。".join(details) + "。")
    return prompts


def slot_replace_task_prompt(node: dict[str, Any]) -> tuple[str, str, str]:
    slots = node.get("slots", [])
    if slots and isinstance(slots[0], dict):
        name = str(slots[0].get("name", "")).strip()
        example = str(slots[0].get("example", "")).strip()
        if name and example:
            return (
                f"把 {name} 换成你的真实信息，可以先用 {example} 试一遍。",
                name,
                example,
            )
    return ("把其中一个信息换成你的真实经历、岗位、项目或公司。", "", "")


def default_speaking_tasks(
    node: dict[str, Any],
    intent: str,
    cue: str,
    target: str,
) -> list[dict[str, str]]:
    slot_prompt, slot_name, slot_example = slot_replace_task_prompt(node)
    rhythm = str(node.get("speechFocus", {}).get("rhythm", "")).strip()
    return [
        {
            "type": "listen",
            "title": "听一句",
            "prompt": intent,
            "targetText": target,
        },
        {
            "type": "shadow",
            "title": "跟说一次",
            "prompt": rhythm or "跟着读一遍，先保证完整和顺。",
            "targetText": target,
        },
        {
            "type": "slot_replace",
            "title": "替换一个槽位",
            "prompt": slot_prompt,
            "targetText": target,
            "slotName": slot_name,
            "slotExample": slot_example,
        },
        {
            "type": "scene_transfer",
            "title": "去场景里用",
            "prompt": cue,
            "targetText": target,
        },
    ]


def updated_speaking_tasks(
    node: dict[str, Any],
    existing: list[Any],
    intent: str,
    cue: str,
    target: str,
) -> list[dict[str, str]]:
    if not existing:
        return default_speaking_tasks(node, intent, cue, target)
    updated: list[dict[str, str]] = []
    for task in existing:
        if not isinstance(task, dict):
            continue
        next_task = dict(task)
        task_type = str(next_task.get("type", "")).strip()
        next_task["targetText"] = str(next_task.get("targetText") or target).strip()
        if task_type == "listen":
            next_task["prompt"] = intent
        elif task_type == "scene_transfer":
            next_task["prompt"] = cue
        elif task_type == "slot_replace":
            slot_prompt, slot_name, slot_example = slot_replace_task_prompt(node)
            next_task["prompt"] = slot_prompt
            next_task["slotName"] = slot_name
            next_task["slotExample"] = slot_example
        updated.append(next_task)
    return updated or default_speaking_tasks(node, intent, cue, target)


def update_learning_material(scene_id: str, node: dict[str, Any]) -> bool:
    card_copy = card_copy_for_node(scene_id, node)
    intent = card_copy.get("intent", "").strip()
    cue = card_copy.get("cue", "").strip()
    target = str(node.get("targetText", "")).strip()
    if not target:
        return False
    learning_material = node.get("learningMaterial")
    if not isinstance(learning_material, dict):
        learning_material = {}
    mistakes = common_mistake_prompts(node)
    if not mistakes:
        mistakes = [
            clean_inline_markup(str(item))
            for item in learning_material.get("commonMistakes", [])
            if str(item).strip()
        ]
    next_material = dict(learning_material)
    next_material["intentCn"] = intent or str(
        learning_material.get("intentCn") or node.get("meaning") or node.get("intent") or ""
    ).strip()
    next_material["scenePrompt"] = cue or str(
        learning_material.get("scenePrompt") or node.get("question") or ""
    ).strip()
    next_material["targetExpression"] = str(
        learning_material.get("targetExpression") or target
    ).strip()
    next_material["nativeNotes"] = str(
        learning_material.get("nativeNotes") or node.get("pragmaticNote") or ""
    ).strip()
    next_material["chunks"] = (
        learning_material.get("chunks")
        if isinstance(learning_material.get("chunks"), list)
        and learning_material.get("chunks")
        else sentence_chunks(target)
    )
    next_material["commonMistakes"] = mistakes
    next_material["speakingTasks"] = updated_speaking_tasks(
        node,
        learning_material.get("speakingTasks", []),
        next_material["intentCn"],
        next_material["scenePrompt"],
        target,
    )

    changed = node.get("learningMaterial") != next_material
    node["learningMaterial"] = next_material

    for variant in node.get("practiceVariants", []):
        if isinstance(variant, dict) and next_material["intentCn"]:
            if variant.get("meaning") != next_material["intentCn"]:
                variant["meaning"] = next_material["intentCn"]
                changed = True
    return changed


def compile_file(path: Path) -> bool:
    data = json.loads(path.read_text(encoding="utf-8"))
    scene_id = str(data.get("meta", {}).get("id", "")).strip()
    changed = False
    for node in data.get("nodes", []):
        if not isinstance(node, dict):
            continue
        context = node_expression_context(scene_id, node)
        if node.get("expressionContextAnalysis") != context:
            node["expressionContextAnalysis"] = context
            changed = True
        if update_learning_material(scene_id, node):
            changed = True
        for variant in node.get("practiceVariants", []):
            if not isinstance(variant, dict):
                continue
            context = variant_context(scene_id, node, variant)
            if variant.get("contextAnalysis") != context:
                variant["contextAnalysis"] = context
                changed = True
    if changed:
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return changed


def main() -> None:
    paths = sorted(SCENE_WIKI_DIR.glob("*.json"))
    if LEGACY_JOB_WIKI.exists():
        paths.append(LEGACY_JOB_WIKI)
    changed_paths = [path for path in paths if compile_file(path)]
    for path in changed_paths:
        print(f"compiled {path.relative_to(ROOT)}")
    if not changed_paths:
        print("expression context analysis already up to date")


if __name__ == "__main__":
    main()
