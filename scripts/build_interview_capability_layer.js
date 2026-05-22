"use strict";

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const SCENE_WIKI_DIR = path.join(ROOT, "assets/data/interview_scene_wikis");
const CAPABILITY_REGISTRY_PATH = path.join(
  ROOT,
  "assets/data/capability_registry.json"
);
const COACH_MOVE_LIBRARY_PATH = path.join(
  ROOT,
  "assets/data/coach_move_library.json"
);
const USER_WEAKNESS_PROFILE_PATH = path.join(
  ROOT,
  "assets/data/user_weakness_profile.json"
);
const CAPABILITY_MASTERY_STATE_PATH = path.join(
  ROOT,
  "assets/data/capability_mastery_state.json"
);
const LEGACY_JOB_WIKI_PATH = path.join(
  ROOT,
  "assets/data/interview_scene_wiki.json"
);
const BACKEND_DATA_DIR = path.join(
  ROOT,
  ".server_edit/speakeasy-backend/src/data"
);

const capabilityRegistry = {
  schemaVersion: 1,
  capabilities: [
    {
      id: "professional_opening",
      description: "Open an interview with gratitude, positive energy, and a professional tone.",
      relatedSkills: ["gratitude", "positive_energy", "professional_tone", "company_awareness"],
      equivalentCapabilities: ["rapport_building"],
      upgradePaths: ["professional_opening_with_context"],
    },
    {
      id: "role_summary",
      description: "Summarize current role, scope, and professional identity clearly.",
      relatedSkills: ["current_role", "domain_focus", "scope_summary", "professional_identity"],
      equivalentCapabilities: ["self_introduction"],
      upgradePaths: ["role_summary_with_impact"],
    },
    {
      id: "experience_summary",
      description: "State experience length and domain expertise in a concise interview answer.",
      relatedSkills: ["experience_length", "domain_expertise", "specialization"],
      equivalentCapabilities: ["background_summary"],
      upgradePaths: ["career_growth_narrative"],
    },
    {
      id: "achievement_storytelling",
      description: "Describe a project or achievement with action, responsibility, and result.",
      relatedSkills: ["project_context", "action_taken", "result_framing", "leadership_signal"],
      equivalentCapabilities: ["star_storytelling"],
      upgradePaths: ["impact_storytelling"],
    },
    {
      id: "problem_solving_impact",
      description: "Explain a problem, solution, and measurable improvement.",
      relatedSkills: ["problem_identification", "solution_action", "impact_result", "quantification"],
      equivalentCapabilities: ["solution_storytelling"],
      upgradePaths: ["systems_thinking_impact"],
    },
    {
      id: "strength_positioning",
      description: "Position a strength with relevance, evidence, and a credible tone.",
      relatedSkills: ["strength_claim", "evidence_signal", "role_relevance", "confidence_tone"],
      equivalentCapabilities: ["value_proposition"],
      upgradePaths: ["cross_functional_influence"],
    },
    {
      id: "pressure_response",
      description: "Answer pressure questions with calmness, method, and resilience.",
      relatedSkills: ["calm_response", "focus_strategy", "resilience", "method_explanation"],
      equivalentCapabilities: ["stress_management"],
      upgradePaths: ["pressure_methodology"],
    },
    {
      id: "role_motivation",
      description: "Explain motivation for the next role through growth, role fit, and contribution.",
      relatedSkills: ["motivation", "growth_goal", "role_fit", "contribution_signal"],
      equivalentCapabilities: ["career_motivation"],
      upgradePaths: ["strategic_role_fit"],
    },
    {
      id: "career_planning",
      description: "Describe a future plan with ambition, growth path, and contribution.",
      relatedSkills: ["future_goal", "leadership_growth", "contribution", "realistic_timeline"],
      equivalentCapabilities: ["future_vision"],
      upgradePaths: ["talent_development_vision"],
    },
    {
      id: "candidate_questioning",
      description: "Ask thoughtful candidate questions about responsibilities, success, or process.",
      relatedSkills: ["role_discovery", "success_criteria", "hiring_process", "curiosity_tone"],
      equivalentCapabilities: ["interviewer_questioning"],
      upgradePaths: ["strategic_candidate_questions"],
    },
    {
      id: "growth_mindset_gap",
      description: "Handle gaps honestly while showing learning agility and recovery.",
      relatedSkills: ["honest_gap", "learning_agility", "positive_recovery", "strategic_humility"],
      equivalentCapabilities: ["weakness_reframing"],
      upgradePaths: ["strategic_gap_reframe"],
    },
    {
      id: "professional_closing",
      description: "Close the interview with gratitude, interest, and proactive next-step energy.",
      relatedSkills: ["closing_gratitude", "interest_signal", "proactive_next_step", "professional_tone"],
      equivalentCapabilities: ["closing_rapport"],
      upgradePaths: ["confident_closing"],
    },
    {
      id: "onboarding_welcome_response",
      description: "Respond to a team welcome with a friendly greeting, positive energy, and natural teammate tone.",
      relatedSkills: ["welcome_greeting", "team_joining_positive_energy", "friendly_tone"],
      equivalentCapabilities: ["professional_opening", "rapport_building"],
      upgradePaths: ["confident_team_opening"],
    },
    {
      id: "onboarding_role_intro",
      description: "Introduce a new role, work focus, and onboarding context clearly.",
      relatedSkills: ["role_title", "role_focus", "onboarding_context"],
      equivalentCapabilities: ["role_summary", "self_introduction"],
      upgradePaths: ["role_intro_with_scope"],
    },
    {
      id: "onboarding_background_summary",
      description: "Summarize prior experience in a way that helps new teammates understand the learner's background.",
      relatedSkills: ["prior_experience", "role_relevance", "internal_collaboration"],
      equivalentCapabilities: ["experience_summary", "background_summary"],
      upgradePaths: ["background_with_collaboration_value"],
    },
    {
      id: "onboarding_responsibility_scope",
      description: "Explain responsibilities, process ownership, and team alignment during onboarding.",
      relatedSkills: ["responsibility_scope", "process_support", "team_alignment"],
      equivalentCapabilities: ["role_summary"],
      upgradePaths: ["cross_functional_scope_alignment"],
    },
    {
      id: "onboarding_experience_link",
      description: "Connect a previous work experience to the new team's needs with one useful example.",
      relatedSkills: ["coordination_experience", "issue_resolution", "role_relevance"],
      equivalentCapabilities: ["achievement_storytelling"],
      upgradePaths: ["experience_link_with_impact"],
    },
    {
      id: "onboarding_learning_mindset",
      description: "Show willingness to learn, ask questions, take notes, and adapt quickly.",
      relatedSkills: ["learning_mindset", "question_asking", "note_taking"],
      equivalentCapabilities: ["growth_mindset_gap"],
      upgradePaths: ["proactive_learning_plan"],
    },
    {
      id: "onboarding_priority_alignment",
      description: "Ask for first-week priorities and success expectations without sounding passive.",
      relatedSkills: ["priority_discovery", "first_week_focus", "expectation_alignment"],
      equivalentCapabilities: ["candidate_questioning"],
      upgradePaths: ["priority_alignment_with_ownership"],
    },
    {
      id: "onboarding_workflow_tools",
      description: "Ask about communication channels, task tracking, documentation, and team workflows.",
      relatedSkills: ["tool_discovery", "communication_channels", "documentation_workflow"],
      equivalentCapabilities: ["candidate_questioning"],
      upgradePaths: ["workflow_alignment"],
    },
    {
      id: "onboarding_proactive_contribution",
      description: "Offer early help and contribution while staying aligned with team needs.",
      relatedSkills: ["proactive_help", "early_contribution", "ownership_signal"],
      equivalentCapabilities: ["strength_positioning"],
      upgradePaths: ["early_ownership_signal"],
    },
    {
      id: "onboarding_collaboration_style",
      description: "Learn teammates' working styles and communication preferences to collaborate smoothly.",
      relatedSkills: ["collaboration_preference", "working_style_awareness", "team_alignment"],
      equivalentCapabilities: ["rapport_building"],
      upgradePaths: ["collaboration_norms_alignment"],
    },
    {
      id: "onboarding_next_step_alignment",
      description: "Clarify next onboarding steps and immediate actions after an introduction.",
      relatedSkills: ["next_step_clarity", "onboarding_sequence", "expectation_alignment"],
      equivalentCapabilities: ["candidate_questioning"],
      upgradePaths: ["next_step_with_timeline"],
    },
    {
      id: "onboarding_clarification_path",
      description: "Ask who to align with when a process, decision, or responsibility is unclear.",
      relatedSkills: ["ambiguity_flag", "escalation_path", "alignment_before_action"],
      equivalentCapabilities: ["growth_mindset_gap"],
      upgradePaths: ["ambiguity_management"],
    },
    {
      id: "onboarding_warm_closing",
      description: "Close an onboarding introduction with gratitude, warmth, and a collaborative forward-looking tone.",
      relatedSkills: ["warm_gratitude", "collaboration_expectation", "friendly_tone"],
      equivalentCapabilities: ["professional_closing"],
      upgradePaths: ["collaborative_closing"],
    },
  ],
};

const moveLibrary = {
  schemaVersion: 1,
  moves: [
    {
      moveId: "target_activation",
      description: "Activate the communicative purpose before asking the learner to answer.",
      runtimeTemplate: "Briefly tell the learner what communicative job this answer must do, then invite a natural attempt.",
      applicableStages: ["activate", "first_attempt"],
      defaultPlannerPolicy: { maxAttempts: 1, afterSuccess: "ask_followup", afterFail: "scaffold" },
      generatorGuidance: { coachTone: "patient_specific_human_coach", maxChineseChars: 48, separateFormalQuestion: true },
    },
    {
      moveId: "expression_reshape",
      description: "Recast the learner's intended meaning into a clearer natural expression.",
      runtimeTemplate: "Keep the learner's meaning, repair one expression issue, and avoid forcing the target sentence.",
      applicableStages: ["recast", "retry"],
      defaultPlannerPolicy: { maxAttempts: 2, afterSuccess: "ask_followup", afterFail: "sentence_bridge" },
      generatorGuidance: { coachTone: "specific_recast", maxChineseChars: 56, separateFormalQuestion: true },
    },
    {
      moveId: "sentence_bridge",
      description: "Offer a reusable sentence frame that helps the learner express the intent.",
      runtimeTemplate: "Give one short frame and ask the learner to fill it with their own facts.",
      applicableStages: ["scaffold", "retry"],
      defaultPlannerPolicy: { maxAttempts: 2, afterSuccess: "ask_followup", afterFail: "model_then_retry" },
      generatorGuidance: { coachTone: "calm_scaffold", maxChineseChars: 58, separateFormalQuestion: true },
    },
    {
      moveId: "choice_prompt",
      description: "Reduce speaking anxiety by giving two possible starts.",
      runtimeTemplate: "Offer no more than two short starts and ask the learner to choose one.",
      applicableStages: ["scaffold", "micro_drill"],
      defaultPlannerPolicy: { maxAttempts: 2, afterSuccess: "ask_followup", afterFail: "chunk_shadowing" },
      generatorGuidance: { coachTone: "low_pressure_choice", maxChineseChars: 50, separateFormalQuestion: true },
    },
    {
      moveId: "chunk_shadowing",
      description: "Train one short phrase chunk before the learner retries the whole intent.",
      runtimeTemplate: "Pick one 3-8 word chunk from nodeInputs.chunks and ask for a short repeat or reuse.",
      applicableStages: ["micro_drill", "retry"],
      defaultPlannerPolicy: { maxAttempts: 2, afterSuccess: "coach_retry", afterFail: "choice_prompt" },
      generatorGuidance: { coachTone: "micro_drill", maxChineseChars: 46, separateFormalQuestion: true },
    },
    {
      moveId: "naturalness_tuning",
      description: "Improve tone and pragmatic naturalness without over-correcting.",
      runtimeTemplate: "Point out one tone/naturalness issue and provide one natural alternative.",
      applicableStages: ["recast", "followup"],
      defaultPlannerPolicy: { maxAttempts: 1, afterSuccess: "ask_followup", afterFail: "expression_reshape" },
      generatorGuidance: { coachTone: "naturalness_coach", maxChineseChars: 58, separateFormalQuestion: true },
    },
    {
      moveId: "transfer_practice",
      description: "Move mastered intent to a nearby context.",
      runtimeTemplate: "Ask one short transfer question only after mastery or ready_for_transfer.",
      applicableStages: ["transfer"],
      defaultPlannerPolicy: { maxAttempts: 1, afterSuccess: "advance", afterFail: "adaptive_support" },
      generatorGuidance: { coachTone: "realistic_transfer", maxChineseChars: 44, separateFormalQuestion: true },
    },
    {
      moveId: "similar_expression_contrast",
      description: "Contrast two close expressions when the learner chooses an unnatural option.",
      runtimeTemplate: "Contrast the learner's wording with a more natural option in one point.",
      applicableStages: ["recast"],
      defaultPlannerPolicy: { maxAttempts: 1, afterSuccess: "ask_followup", afterFail: "expression_reshape" },
      generatorGuidance: { coachTone: "clear_contrast", maxChineseChars: 58, separateFormalQuestion: true },
    },
    {
      moveId: "error_diagnosis",
      description: "Diagnose the main error type and repair misunderstanding or off-topic turns.",
      runtimeTemplate: "Name the main issue simply and redirect to the current communicative task.",
      applicableStages: ["scaffold", "retry"],
      defaultPlannerPolicy: { maxAttempts: 1, afterSuccess: "coach_retry", afterFail: "choice_prompt" },
      generatorGuidance: { coachTone: "direct_but_kind", maxChineseChars: 56, separateFormalQuestion: true },
    },
    {
      moveId: "instant_recast_followup",
      description: "Acknowledge partial success, recast one phrase, then ask a precise follow-up.",
      runtimeTemplate: "Credit what is correct, repair one missing signal, and ask for one added detail.",
      applicableStages: ["followup", "recast"],
      defaultPlannerPolicy: { maxAttempts: 2, afterSuccess: "ask_followup", afterFail: "sentence_bridge" },
      generatorGuidance: { coachTone: "responsive_followup", maxChineseChars: 60, separateFormalQuestion: true },
    },
    {
      moveId: "difficulty_progression",
      description: "Increase or simplify difficulty based on mastery and capability state.",
      runtimeTemplate: "Adjust the next task one notch up or down; never add multiple requirements.",
      applicableStages: ["followup", "transfer"],
      defaultPlannerPolicy: { maxAttempts: 1, afterSuccess: "advance", afterFail: "adaptive_support" },
      generatorGuidance: { coachTone: "adaptive_progression", maxChineseChars: 48, separateFormalQuestion: true },
    },
    {
      moveId: "adaptive_support",
      description: "Adapt support using weakness memory and repeated attempts.",
      runtimeTemplate: "Use weaknessProfile to reduce load and pick one support path.",
      applicableStages: ["scaffold", "micro_drill", "retry"],
      defaultPlannerPolicy: { maxAttempts: 2, afterSuccess: "coach_retry", afterFail: "choice_prompt" },
      generatorGuidance: { coachTone: "supportive_adaptive", maxChineseChars: 52, separateFormalQuestion: true },
    },
    {
      moveId: "pronunciation_fluency_feedback",
      description: "Give one pronunciation or fluency adjustment tied to the current expression.",
      runtimeTemplate: "Use scoring signals to focus on one sound, stress, pause, or rhythm issue.",
      applicableStages: ["micro_drill", "retry"],
      defaultPlannerPolicy: { maxAttempts: 1, afterSuccess: "coach_retry", afterFail: "chunk_shadowing" },
      generatorGuidance: { coachTone: "speech_feedback", maxChineseChars: 54, separateFormalQuestion: true },
    },
    {
      moveId: "mastery_assessment",
      description: "Confirm capability mastery and decide whether to advance or transfer.",
      runtimeTemplate: "Confirm the completed intent briefly; do not ask the learner to repeat the same target.",
      applicableStages: ["completed", "followup"],
      defaultPlannerPolicy: { maxAttempts: 1, afterSuccess: "advance", afterFail: "ask_followup" },
      generatorGuidance: { coachTone: "concise_mastery", maxChineseChars: 42, separateFormalQuestion: true },
    },
  ],
};

const defaultAllowedMoves = moveLibrary.moves.map((move) => move.moveId);

const jobSceneNarrative = {
  interviewerProfile: {
    personality: "warm_professional",
    pressureLevel: 0.3,
    interruptiveness: 0.2,
    speakingStyle: "natural_conversational",
  },
  conversationArc: [
    "warm_opening",
    "background_check",
    "evaluation",
    "rapport_building",
    "pressure_question",
    "candidate_questions",
    "closing",
  ],
};

const onboardingSceneNarrative = {
  interviewerProfile: {
    personality: "warm_collaborative",
    pressureLevel: 0.18,
    interruptiveness: 0.12,
    speakingStyle: "natural_team_onboarding",
  },
  conversationArc: [
    "welcome",
    "role_introduction",
    "background_exchange",
    "responsibility_alignment",
    "working_norms",
    "support_path",
    "closing",
  ],
};

const jobStageCapabilityMap = {
  "开场感谢": {
    primaryIntent: "professional_opening",
    subSkills: ["gratitude", "positive_energy", "professional_tone"],
  },
  "当前职位": {
    primaryIntent: "role_summary",
    subSkills: ["current_role", "domain_focus", "professional_identity"],
  },
  "经验领域": {
    primaryIntent: "experience_summary",
    subSkills: ["experience_length", "domain_expertise", "specialization"],
  },
  "经历成就": {
    primaryIntent: "achievement_storytelling",
    subSkills: ["project_context", "action_taken", "result_framing"],
  },
  "问题解决": {
    primaryIntent: "problem_solving_impact",
    subSkills: ["problem_identification", "solution_action", "impact_result"],
  },
  "优势说明": {
    primaryIntent: "strength_positioning",
    subSkills: ["strength_claim", "evidence_signal", "role_relevance"],
  },
  "压力回应": {
    primaryIntent: "pressure_response",
    subSkills: ["calm_response", "focus_strategy", "resilience"],
  },
  "求职动机": {
    primaryIntent: "role_motivation",
    subSkills: ["motivation", "growth_goal", "role_fit"],
  },
  "职业规划": {
    primaryIntent: "career_planning",
    subSkills: ["future_goal", "leadership_growth", "contribution"],
  },
  "反向提问": {
    primaryIntent: "candidate_questioning",
    subSkills: ["role_discovery", "success_criteria", "curiosity_tone"],
  },
  "后续流程": {
    primaryIntent: "candidate_questioning",
    subSkills: ["hiring_process", "proactive_next_step", "professional_tone"],
  },
  "应对难题": {
    primaryIntent: "growth_mindset_gap",
    subSkills: ["honest_gap", "learning_agility", "positive_recovery"],
  },
  "结束致谢": {
    primaryIntent: "professional_closing",
    subSkills: ["closing_gratitude", "interest_signal", "professional_tone"],
  },
};

const onboardingStageCapabilityMap = {
  "欢迎回应": {
    primaryIntent: "onboarding_welcome_response",
    subSkills: ["welcome_greeting", "team_joining_positive_energy", "friendly_tone"],
  },
  "岗位说明": {
    primaryIntent: "onboarding_role_intro",
    subSkills: ["role_title", "role_focus", "onboarding_context"],
  },
  "背景经历": {
    primaryIntent: "onboarding_background_summary",
    subSkills: ["prior_experience", "role_relevance", "internal_collaboration"],
  },
  "职责范围": {
    primaryIntent: "onboarding_responsibility_scope",
    subSkills: ["responsibility_scope", "process_support", "team_alignment"],
  },
  "相关经验": {
    primaryIntent: "onboarding_experience_link",
    subSkills: ["coordination_experience", "issue_resolution", "role_relevance"],
  },
  "学习态度": {
    primaryIntent: "onboarding_learning_mindset",
    subSkills: ["learning_mindset", "question_asking", "note_taking"],
  },
  "优先事项": {
    primaryIntent: "onboarding_priority_alignment",
    subSkills: ["priority_discovery", "first_week_focus", "expectation_alignment"],
  },
  "工具流程": {
    primaryIntent: "onboarding_workflow_tools",
    subSkills: ["tool_discovery", "communication_channels", "documentation_workflow"],
  },
  "主动贡献": {
    primaryIntent: "onboarding_proactive_contribution",
    subSkills: ["proactive_help", "early_contribution", "ownership_signal"],
  },
  "协作方式": {
    primaryIntent: "onboarding_collaboration_style",
    subSkills: ["collaboration_preference", "working_style_awareness", "team_alignment"],
  },
  "下一步安排": {
    primaryIntent: "onboarding_next_step_alignment",
    subSkills: ["next_step_clarity", "onboarding_sequence", "expectation_alignment"],
  },
  "不确定求助": {
    primaryIntent: "onboarding_clarification_path",
    subSkills: ["ambiguity_flag", "escalation_path", "alignment_before_action"],
  },
  "感谢收尾": {
    primaryIntent: "onboarding_warm_closing",
    subSkills: ["warm_gratitude", "collaboration_expectation", "friendly_tone"],
  },
};

const signalExamples = {
  gratitude: ["thank you", "thanks for", "appreciate"],
  positive_energy: ["excited", "glad to", "looking forward"],
  professional_tone: ["having me", "opportunity", "today"],
  current_role: ["currently", "working as", "work as", "work", "I am a"],
  domain_focus: ["focus on", "focusing on", "specializing in", "in marketing", "in design", "in software"],
  professional_identity: ["designer", "engineer", "manager", "specialist"],
  experience_length: ["years of experience", "for three years", "over five years"],
  domain_expertise: ["in marketing", "in design", "in software", "content strategy"],
  specialization: ["specializing in", "focus on", "background in"],
  project_context: ["project", "initiative", "team", "previous role"],
  action_taken: ["helped", "led", "identified", "implemented", "delivered"],
  result_framing: ["on time", "on schedule", "ahead of schedule", "reduced", "improved", "increased"],
  problem_identification: ["problem", "bottleneck", "challenge", "issue"],
  solution_action: ["solved", "implemented", "created", "changed", "improved"],
  impact_result: ["faster", "reduced", "by 30%", "result", "improvement"],
  strength_claim: ["strength", "good at", "ability to", "one of my key strengths"],
  evidence_signal: ["for example", "because", "by", "when"],
  role_relevance: ["this role", "team", "clients", "stakeholders", "next steps"],
  calm_response: ["under pressure", "stay focused", "calm", "deadlines"],
  focus_strategy: ["prioritize", "break it down", "manage", "focus"],
  resilience: ["handle", "adapt", "keep", "pressure"],
  motivation: ["looking for", "want a role", "motivated by", "interested in"],
  growth_goal: ["learn", "grow", "develop", "take on"],
  role_fit: ["apply my skills", "contribute", "matches", "role", "current experience"],
  future_goal: ["in five years", "I hope", "I see myself", "long term"],
  leadership_growth: ["team leader", "leadership", "responsibilities", "mentor"],
  contribution: ["help", "contribute", "support", "make an impact"],
  role_discovery: ["responsibilities", "typical day", "normal day", "day-to-day", "success"],
  success_criteria: ["success", "perform well", "expectations", "first six months"],
  curiosity_tone: ["could you tell me", "could you share", "I'd like to know", "what does"],
  hiring_process: ["next steps", "process", "after this interview", "timeline"],
  proactive_next_step: ["next steps", "anything else", "provide more information"],
  honest_gap: ["don't know", "not familiar", "haven't worked with", "limited", "haven't had direct exposure", "haven't gone deep"],
  learning_agility: ["learn quickly", "pick up", "improve", "open to learning", "build that skill"],
  positive_recovery: ["but", "I can", "I would", "quickly", "confident", "eager"],
  closing_gratitude: ["thank you for your time", "thanks again", "appreciate your time"],
  interest_signal: ["enjoyed", "interested", "excited about", "conversation"],
  welcome_greeting: ["hi everyone", "hello everyone", "good to meet you all"],
  team_joining_positive_energy: ["excited to join", "happy to join", "thrilled to be joining"],
  friendly_tone: ["everyone", "team", "with you all", "warm welcome"],
  role_title: ["working as", "joining as", "product operations specialist", "my role"],
  role_focus: ["focusing on", "focus on", "day-to-day", "support"],
  onboarding_context: ["joining", "new team", "onboarding", "today"],
  prior_experience: ["before this", "before joining", "last role", "spent two years"],
  internal_collaboration: ["worked closely with", "internal teams", "team updates", "coordinate"],
  responsibility_scope: ["main responsibility", "responsible for", "helping the team", "support the team"],
  process_support: ["track", "document", "processes", "follow up", "workflows"],
  team_alignment: ["team", "everyone", "priorities", "communicate", "collaborate"],
  coordination_experience: ["organize", "coordinate", "weekly updates", "worked with"],
  issue_resolution: ["solve", "recurring issues", "customer issues", "actionable improvements"],
  learning_mindset: ["lot to learn", "learning curve", "get up to speed", "learn"],
  question_asking: ["ask questions", "check with", "clarify", "ask"],
  note_taking: ["take notes", "write down", "document", "feedback into action"],
  priority_discovery: ["priorities", "focus on first", "highest-priority", "first priorities"],
  first_week_focus: ["this week", "first few weeks", "first", "early"],
  expectation_alignment: ["understand", "best next step", "should", "expectations"],
  tool_discovery: ["which tools", "tools", "channels", "walk me through"],
  communication_channels: ["daily communication", "communication channels", "Slack", "email"],
  documentation_workflow: ["task tracking", "documentation", "documents", "manage work"],
  proactive_help: ["anything I can help", "let me know", "happy to help", "take on"],
  early_contribution: ["early", "add value", "contribute", "support the team"],
  ownership_signal: ["take ownership", "support", "take on", "own"],
  collaboration_preference: ["prefers to work", "working style", "communicate", "collaborate"],
  working_style_awareness: ["how everyone works", "each person's working style", "work smoothly"],
  next_step_clarity: ["next step", "what should I do", "after this", "after today's"],
  onboarding_sequence: ["after introduction", "onboarding conversation", "today's introduction"],
  ambiguity_flag: ["not sure", "unsure", "ambiguity", "unclear"],
  escalation_path: ["who should I ask", "best person", "check with", "align with"],
  alignment_before_action: ["before moving forward", "confirm", "align", "decision"],
  warm_gratitude: ["thank you", "thanks", "warm welcome", "appreciate"],
  collaboration_expectation: ["looking forward to working", "happy to be here", "contributing", "building momentum"],
};

const jobStageArcMap = {
  "开场感谢": "warm_opening",
  "当前职位": "background_check",
  "经验领域": "background_check",
  "经历成就": "evaluation",
  "问题解决": "evaluation",
  "优势说明": "rapport_building",
  "压力回应": "pressure_question",
  "求职动机": "rapport_building",
  "职业规划": "rapport_building",
  "反向提问": "candidate_questions",
  "后续流程": "candidate_questions",
  "应对难题": "pressure_question",
  "结束致谢": "closing",
};

const onboardingStageArcMap = {
  "欢迎回应": "welcome",
  "岗位说明": "role_introduction",
  "背景经历": "background_exchange",
  "职责范围": "responsibility_alignment",
  "相关经验": "background_exchange",
  "学习态度": "support_path",
  "优先事项": "responsibility_alignment",
  "工具流程": "working_norms",
  "主动贡献": "responsibility_alignment",
  "协作方式": "working_norms",
  "下一步安排": "support_path",
  "不确定求助": "support_path",
  "感谢收尾": "closing",
};

const sceneConfigs = [
  {
    id: "job_interview",
    path: path.join(SCENE_WIKI_DIR, "job_interview.json"),
    narrative: jobSceneNarrative,
    stageCapabilityMap: jobStageCapabilityMap,
    stageArcMap: jobStageArcMap,
    defaultCapability: {
      primaryIntent: "role_summary",
      subSkills: ["professional_identity"],
    },
    interruptionOverride(node) {
      return node.stageLabel === "压力回应" ? 0.35 : undefined;
    },
  },
  {
    id: "onboarding_introduction",
    path: path.join(SCENE_WIKI_DIR, "onboarding_introduction.json"),
    narrative: onboardingSceneNarrative,
    stageCapabilityMap: onboardingStageCapabilityMap,
    stageArcMap: onboardingStageArcMap,
    defaultCapability: {
      primaryIntent: "onboarding_welcome_response",
      subSkills: ["friendly_tone"],
    },
    interruptionOverride() {
      return undefined;
    },
  },
];

const levelPressure = {
  beginner: 0.25,
  intermediate: 0.38,
  advanced: 0.55,
};

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function writeJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`);
}

function compactList(values, max = 6) {
  return [...new Set((values || []).map((value) => String(value || "").trim()).filter(Boolean))].slice(0, max);
}

const jobExpressionProductPolish = {
  L1_01: {
    tier: "starter",
    targetText: "Thank you for having me. I'm excited to be here today.",
    variants: [
      "Thanks for having me. I'm glad to be here.",
      "Thank you for the opportunity. I'm looking forward to our conversation.",
      "I appreciate you taking the time to meet with me today.",
    ],
    frame: "Thank the interviewer + show positive energy.",
    note: "\"Thank you for having me\" is warm and interview-appropriate. Keep it sincere and calm, not overly enthusiastic.",
    stress: ["Thank", "having", "excited"],
  },
  L1_02: {
    tier: "starter",
    targetText: "I'm currently working as a designer at a growing company.",
    variants: [
      "I'm currently working as a product manager at a tech company.",
      "I'm currently working as a software engineer at a growing startup.",
      "Right now, I'm a designer at a growing company.",
    ],
    frame: "Say current role + company type.",
    note: "\"Growing company\" sounds more polished than \"small company\" while still staying simple. Learners should replace the role and company type with their real facts.",
    stress: ["currently", "working as", "growing company"],
  },
  L1_03: {
    tier: "starter",
    targetText: "I have three years of experience in marketing, mainly working on content campaigns.",
    variants: [
      "I have three years of experience in product operations, mainly working on user feedback.",
      "I have three years of experience in software development, mainly working on backend services.",
      "I have three years of experience in design, mainly working on mobile products.",
    ],
    frame: "Say years of experience + field + one focus area.",
    note: "A field alone can sound thin. Adding one focus area makes the answer more interview-ready without making it long.",
    stress: ["three years", "experience", "mainly"],
  },
  L1_04: {
    tier: "starter",
    targetText: "In my last role, I helped my team deliver a key project on time.",
    variants: [
      "In my last role, I helped my team launch an important feature on time.",
      "In my last role, I helped my team finish a client project on time.",
      "In my previous role, I helped the team deliver an important project on schedule.",
    ],
    frame: "Give role context + action + simple result.",
    note: "\"Deliver a key project\" sounds more professional than \"finish a big project\" and still remains easy to say.",
    stress: ["last role", "helped", "deliver", "on time"],
  },
  L1_05: {
    tier: "starter",
    targetText: "I found a workflow problem and helped the team make the process faster.",
    variants: [
      "I noticed a process issue and helped the team make the work smoother.",
      "I found a communication problem and helped the team fix it.",
      "I noticed a workflow problem and helped reduce delays.",
    ],
    frame: "Name problem + action + improvement.",
    note: "A problem-solving answer should include what was wrong and what improved. Keep the first version simple.",
    stress: ["found", "workflow problem", "process faster"],
  },
  L1_06: {
    tier: "starter",
    targetText: "One of my strengths is explaining complex ideas in a simple way.",
    variants: [
      "One of my strengths is making complex information easy to understand.",
      "I'm good at explaining complicated ideas clearly.",
      "One strength I bring is clear communication with different teams.",
    ],
    frame: "Name one strength + make it role-relevant.",
    note: "This avoids the vague \"I'm a good communicator\" and gives the strength a clearer professional shape.",
    stress: ["strengths", "complex ideas", "simple way"],
  },
  L1_07: {
    tier: "starter",
    targetText: "I stay focused under pressure by prioritizing the most important tasks first.",
    variants: [
      "I stay calm under pressure by breaking the work into priorities.",
      "When things get busy, I focus on the most important tasks first.",
      "I handle pressure by staying organized and communicating early.",
    ],
    frame: "Say calm response + method.",
    note: "\"I can work well under pressure\" is too generic. Adding a method makes it sound more credible.",
    stress: ["stay focused", "under pressure", "prioritizing"],
  },
  L1_08: {
    tier: "starter",
    targetText: "I'm looking for a role where I can contribute and continue to grow.",
    variants: [
      "I'm looking for a role where I can use my experience and keep growing.",
      "I'm looking for a role where I can contribute to the team and learn more.",
      "I want a role where I can make an impact and continue to develop.",
    ],
    frame: "Connect motivation to contribution + growth.",
    note: "\"Learn and grow\" alone can sound student-like. Pair it with contribution to sound more mature.",
    stress: ["looking for", "contribute", "grow"],
  },
  L1_09: {
    tier: "starter",
    targetText: "In the next few years, I hope to take on more responsibility and grow into a team lead role.",
    variants: [
      "In the next few years, I hope to take on more responsibility and lead small projects.",
      "In the next few years, I want to grow into a role with more ownership.",
      "Over time, I hope to take on more responsibility and support the team more independently.",
    ],
    frame: "Give timeline + growth direction + contribution.",
    note: "A career plan should sound ambitious but realistic. \"More responsibility\" is safer than promising a title too early.",
    stress: ["next few years", "responsibility", "team lead"],
  },
  L1_10: {
    tier: "starter",
    targetText: "What does a typical day look like in this role?",
    variants: [
      "Could you tell me what a typical day in this role looks like?",
      "What would the day-to-day work look like for this role?",
      "Could you share more about the daily responsibilities of this role?",
    ],
    frame: "Ask about real day-to-day responsibilities.",
    note: "\"Typical day\" and \"role\" sound more polished than \"normal day\" and \"job\" in an interview.",
    stress: ["typical day", "look like", "role"],
  },
  L1_11: {
    tier: "starter",
    targetText: "What are the next steps in the hiring process?",
    variants: [
      "Could you share the next steps in the hiring process?",
      "What should I expect as the next step after today's conversation?",
      "Could you let me know what the timeline looks like from here?",
    ],
    frame: "Ask process + next step politely.",
    note: "This is a standard, professional closing question. Keep the tone curious, not impatient.",
    stress: ["next steps", "hiring process"],
  },
  L1_12: {
    tier: "starter",
    targetText: "I haven't had direct experience with that yet, but I'm confident I can learn it quickly.",
    variants: [
      "I haven't worked directly with that yet, but I'm confident I can pick it up quickly.",
      "I don't have direct experience with that yet, but I'm eager to learn.",
      "That is not an area I've used deeply yet, but I'm willing to build that skill.",
    ],
    frame: "Acknowledge gap + show learning confidence.",
    note: "\"I don't know much\" can weaken the candidate. \"Haven't had direct experience yet\" is honest and more professional.",
    stress: ["haven't had", "direct experience", "confident"],
  },
  L1_13: {
    tier: "starter",
    targetText: "Thank you for your time. I enjoyed our conversation and I'm excited about the role.",
    variants: [
      "Thank you for your time. I enjoyed learning more about the role.",
      "Thanks again for speaking with me today. I'm excited about the opportunity.",
      "I appreciate your time today. This conversation made me more interested in the role.",
    ],
    frame: "Close with gratitude + positive interest.",
    note: "A closing answer should leave warmth and interest, not just say goodbye.",
    stress: ["thank you", "enjoyed", "excited"],
  },
  L2_01: {
    tier: "interview_ready",
    targetText: "Thank you for making the time. I've been looking forward to this conversation.",
    variants: [
      "Thank you for the opportunity. I've been looking forward to speaking with you.",
      "Thanks for taking the time to meet with me. I'm glad to be here.",
      "I appreciate you making the time today. I'm looking forward to our conversation.",
    ],
    frame: "Warm gratitude + prepared interest.",
    note: "This sounds prepared and professional without feeling over-rehearsed.",
    stress: ["making the time", "looking forward", "conversation"],
  },
  L2_02: {
    tier: "interview_ready",
    targetText: "I'm currently a product designer at a growing tech company, focusing on mobile user experience.",
    variants: [
      "I'm currently a product manager at a tech company, focusing on user growth and roadmap planning.",
      "I'm currently a software engineer at a growing tech company, focusing on backend systems.",
      "I'm currently a marketing specialist at a growing company, focusing on content and campaign performance.",
    ],
    frame: "Role + company type + focus area.",
    note: "This is interview-ready because it gives identity, environment, and scope in one sentence.",
    stress: ["currently", "focusing on", "user experience"],
  },
  L2_03: {
    tier: "interview_ready",
    targetText: "I have over five years of experience in digital marketing, with a focus on content strategy and campaign performance.",
    variants: [
      "I have over five years of experience in product management, with a focus on user research and roadmap execution.",
      "I have over five years of experience in software engineering, with a focus on backend reliability and performance.",
      "I have over five years of experience in operations, with a focus on process improvement and cross-functional coordination.",
    ],
    frame: "Experience length + domain + specialization.",
    note: "Adding a focus area makes the background easier for an interviewer to evaluate.",
    stress: ["five years", "experience", "focus on"],
  },
  L2_04: {
    tier: "interview_ready",
    targetText: "In my previous role, I led a cross-functional project that launched two weeks ahead of schedule.",
    variants: [
      "In my previous role, I helped lead a cross-functional project that launched ahead of schedule.",
      "In my previous role, I coordinated a project across teams and delivered it two weeks early.",
      "In my previous role, I owned a key workstream that helped the project launch on time.",
    ],
    frame: "Previous role + ownership + measurable result.",
    note: "The answer is stronger when it includes ownership and a clear result, even if the result is simple.",
    stress: ["previous role", "cross-functional", "ahead of schedule"],
  },
  L2_05: {
    tier: "interview_ready",
    targetText: "I identified a workflow bottleneck and implemented a change that cut turnaround time by 30%.",
    variants: [
      "I found a workflow bottleneck and helped redesign the process, which reduced delays by 30%.",
      "I noticed a review bottleneck and introduced a clearer process that made delivery faster.",
      "I identified a recurring issue and worked with the team to reduce turnaround time.",
    ],
    frame: "Problem + solution + measurable impact.",
    note: "A metric makes the answer more credible. If the learner has no metric, ask for a simple before/after result.",
    stress: ["identified", "bottleneck", "30%"],
  },
  L2_06: {
    tier: "interview_ready",
    targetText: "A key strength of mine is translating complex ideas into clear next steps for different stakeholders.",
    variants: [
      "One of my key strengths is turning complex information into clear action points.",
      "A strength I bring is helping different teams understand complex ideas and move forward.",
      "I'm strong at communicating complex topics in a way that helps stakeholders make decisions.",
    ],
    frame: "Strength + evidence of value to others.",
    note: "This sounds more useful than just saying \"I'm a good communicator\" because it shows the business value.",
    stress: ["key strength", "complex ideas", "clear next steps"],
  },
  L2_07: {
    tier: "interview_ready",
    targetText: "When deadlines are tight, I stay calm by breaking the work into priorities and communicating risks early.",
    variants: [
      "When pressure is high, I stay focused by clarifying priorities and communicating early.",
      "Under pressure, I try to break the work down and focus on the highest-impact tasks first.",
      "When timelines are tight, I stay organized and keep the team aligned on risks.",
    ],
    frame: "Pressure situation + method + communication.",
    note: "This answers how the learner handles pressure, not just whether they can.",
    stress: ["deadlines", "priorities", "risks early"],
  },
  L2_08: {
    tier: "interview_ready",
    targetText: "I'm looking for a role where I can contribute from my current experience while continuing to grow.",
    variants: [
      "I'm looking for a role where I can apply what I've learned and take on new challenges.",
      "I'm interested in a role where I can contribute quickly and keep developing professionally.",
      "I'm looking for a role that matches my experience and gives me room to grow.",
    ],
    frame: "Contribution + growth + role fit.",
    note: "This keeps growth motivation mature by balancing what the candidate gives and what they want to learn.",
    stress: ["contribute", "current experience", "grow"],
  },
  L2_09: {
    tier: "interview_ready",
    targetText: "Over the next few years, I want to grow into a role where I can lead projects and mentor junior teammates.",
    variants: [
      "In the next few years, I hope to take on more ownership and lead larger projects.",
      "Over time, I'd like to move toward project leadership and help develop junior teammates.",
      "In the next few years, I see myself taking on more responsibility and supporting others on the team.",
    ],
    frame: "Future direction + leadership/contribution.",
    note: "This gives ambition without sounding unrealistic or title-obsessed.",
    stress: ["next few years", "lead projects", "mentor"],
  },
  L2_10: {
    tier: "interview_ready",
    targetText: "Could you tell me what a typical day in this role looks like?",
    variants: [
      "Could you share what the day-to-day responsibilities look like for this role?",
      "I'd love to understand what a typical week in this role looks like.",
      "Could you tell me more about the work someone in this role handles day to day?",
    ],
    frame: "Polite question + role reality.",
    note: "This is more polished than asking about a \"normal day\" and shows practical curiosity.",
    stress: ["could you tell me", "typical day", "role"],
  },
  L2_11: {
    tier: "interview_ready",
    targetText: "Could you share what the next steps in the hiring process will be?",
    variants: [
      "Could you let me know what the next steps look like from here?",
      "What should I expect for the next stage of the hiring process?",
      "Could you share the timeline for the rest of the process?",
    ],
    frame: "Polite process question + timeline.",
    note: "The phrasing is professional because it asks for process clarity without sounding pushy.",
    stress: ["next steps", "hiring process"],
  },
  L2_12: {
    tier: "interview_ready",
    targetText: "I haven't had direct exposure to that yet, but I'm a quick learner and would be eager to build that skill.",
    variants: [
      "I haven't worked directly with that yet, but I'm confident I can pick it up quickly.",
      "I don't have hands-on experience with that yet, but I'm actively interested in learning it.",
      "That is an area I haven't used deeply yet, but I'd be eager to build it with the right context.",
    ],
    frame: "Honest gap + learning agility + positive intent.",
    note: "\"Direct exposure\" is a professional way to acknowledge a gap without underselling yourself.",
    stress: ["direct exposure", "quick learner", "build that skill"],
  },
  L2_13: {
    tier: "interview_ready",
    targetText: "Thank you for taking the time to speak with me today. I enjoyed learning more about the role, and I'm even more interested now.",
    variants: [
      "Thank you for speaking with me today. I enjoyed the conversation and I'm even more interested in the role.",
      "I appreciate your time today. Learning more about the team made me more excited about the opportunity.",
      "Thanks again for the conversation. I enjoyed learning more about the role and the team.",
    ],
    frame: "Gratitude + learned something + renewed interest.",
    note: "A strong close makes the candidate sound engaged without being overly eager.",
    stress: ["thank you", "learning more", "interested"],
  },
  L3_01: {
    tier: "native_upgrade",
    targetText: "I really appreciate you making the time. I've been looking forward to learning more about the team and the role.",
    variants: [
      "I appreciate you making the time today. I'm looking forward to understanding the role in more depth.",
      "Thanks for making the time. I've been looking forward to learning more about the team.",
      "I really appreciate the opportunity to speak with you today.",
    ],
    frame: "Gratitude + specific professional curiosity.",
    note: "This sounds senior because it is warm but not overly flattering.",
    stress: ["appreciate", "making the time", "team and role"],
  },
  L3_02: {
    tier: "native_upgrade",
    targetText: "For the past four years, I've been leading UX work for a flagship mobile product, combining hands-on design with mentoring junior teammates.",
    variants: [
      "For the past four years, I've been leading product work for a core platform, combining roadmap ownership with cross-functional execution.",
      "For the past four years, I've been building backend systems for a core product, combining hands-on engineering with mentoring teammates.",
      "For the past four years, I've been leading growth work across content and analytics for a flagship product.",
    ],
    frame: "Timeframe + scope + senior signal.",
    note: "This is a senior-level role summary. It should be personalized to the learner's actual role, scope, and team impact.",
    stress: ["past four years", "leading", "combining"],
  },
  L3_03: {
    tier: "native_upgrade",
    targetText: "My background started in content marketing, and over time I've expanded into growth strategy and campaign analytics.",
    variants: [
      "My background started in product operations, and over time I've expanded into user research and roadmap execution.",
      "My background started in software engineering, and over time I've expanded into system design and reliability work.",
      "My background started in design, and over time I've expanded into product strategy and user research.",
    ],
    frame: "Starting point + growth path + broader expertise.",
    note: "This tells a career story rather than listing a field. It is useful for senior candidates.",
    stress: ["background started", "expanded into", "strategy"],
  },
  L3_04: {
    tier: "native_upgrade",
    targetText: "I led a cross-functional launch that finished two weeks ahead of schedule and later became the playbook for similar projects.",
    variants: [
      "I led a cross-functional initiative that shipped ahead of schedule and became a repeatable process for the team.",
      "I owned a cross-functional workstream that launched early and helped the team standardize future launches.",
      "I coordinated a major launch across teams and turned the process into a reusable playbook.",
    ],
    frame: "Leadership + outcome + reusable impact.",
    note: "The strongest version shows impact beyond one project: it changed how the team works.",
    stress: ["led", "ahead of schedule", "playbook"],
  },
  L3_05: {
    tier: "native_upgrade",
    targetText: "I noticed our review process was slowing delivery, so I redesigned the workflow and cut turnaround time by roughly a third.",
    variants: [
      "I found that our review process was creating delays, so I redesigned the workflow and reduced turnaround time by about 30%.",
      "I identified a delivery bottleneck, simplified the review flow, and helped the team move faster.",
      "I noticed repeated delays in the process, rebuilt the handoff, and shortened delivery time significantly.",
    ],
    frame: "Observation + system fix + measurable business impact.",
    note: "This sounds strong because it shows systems thinking, not just one-time problem solving.",
    stress: ["noticed", "redesigned", "turnaround time"],
  },
  L3_06: {
    tier: "native_upgrade",
    targetText: "I'd say my strongest suit is turning technical ideas into language that helps non-technical stakeholders make decisions.",
    variants: [
      "One of my strongest skills is translating technical complexity into clear decisions for cross-functional partners.",
      "I'm especially strong at making complex ideas clear enough for different stakeholders to act on.",
      "A strength I bring is helping technical and non-technical teams align around the same decision.",
    ],
    frame: "Strength + audience + business decision value.",
    note: "A senior strength answer should show how the strength helps others make progress.",
    stress: ["strongest suit", "technical ideas", "make decisions"],
  },
  L3_07: {
    tier: "native_upgrade",
    targetText: "When the stakes are high, I try to stay calm, clarify priorities, and keep the team focused on the biggest risk first.",
    variants: [
      "When pressure is high, I stay calm by clarifying priorities and focusing the team on the highest-risk work first.",
      "In high-pressure situations, I try to separate urgent noise from the real priority and communicate early.",
      "When the stakes are high, I focus on priorities, risks, and clear communication.",
    ],
    frame: "High-pressure situation + method + team impact.",
    note: "This avoids the cliché of \"I work well under pressure\" by showing the actual operating method.",
    stress: ["stakes are high", "clarify priorities", "biggest risk"],
  },
  L3_08: {
    tier: "native_upgrade",
    targetText: "I'm looking for a role that stretches me, where I can contribute from day one while learning from a strong team.",
    variants: [
      "I'm looking for a role that challenges me and lets me contribute meaningfully from the start.",
      "I'm looking for a role where I can bring my experience to the team while continuing to stretch myself.",
      "I'm interested in a role that combines real contribution with continued learning.",
    ],
    frame: "Stretch + contribution + learning environment.",
    note: "This balances ambition and humility. It sounds more mature than simply saying you want to learn.",
    stress: ["stretches me", "contribute", "strong team"],
  },
  L3_09: {
    tier: "native_upgrade",
    targetText: "Longer term, I'd like to grow into a role where I shape strategy and help develop other people on the team.",
    variants: [
      "Longer term, I'd like to take on broader ownership and help develop the people around me.",
      "In the long run, I want to contribute more to strategy while mentoring other teammates.",
      "Longer term, I see myself growing toward a role that combines strategy, execution, and people development.",
    ],
    frame: "Long-term direction + strategic contribution + people development.",
    note: "This sounds ambitious but credible because it is framed as a direction, not a guaranteed title.",
    stress: ["longer term", "shape strategy", "develop people"],
  },
  L3_10: {
    tier: "native_upgrade",
    targetText: "If we fast-forward six months, what would make you say this person was a great hire?",
    variants: [
      "If we fast-forward six months, what would success in this role look like?",
      "What would someone need to accomplish in the first six months to be seen as successful here?",
      "What would make you feel that the person in this role is doing really well after six months?",
    ],
    frame: "Ask success criteria with a future lens.",
    note: "This is a strong candidate question because it uncovers expectations and shows performance mindset.",
    stress: ["fast-forward", "six months", "great hire"],
  },
  L3_11: {
    tier: "native_upgrade",
    targetText: "I'd love to know what the rest of the process looks like, and whether there's anything else I can share to support the decision.",
    variants: [
      "I'd love to understand the rest of the process and whether I can provide anything else that would be helpful.",
      "Could you share what the rest of the process looks like from here?",
      "I'd be happy to share anything else that would help with the decision.",
    ],
    frame: "Process clarity + helpful next-step offer.",
    note: "This is proactive without sounding pushy because it offers useful follow-up material.",
    stress: ["rest of the process", "anything else", "support the decision"],
  },
  L3_12: {
    tier: "native_upgrade",
    targetText: "I haven't gone deep on that area yet, but it's something I've been tracking, and I'd be excited to build it with the right support.",
    variants: [
      "I haven't had the chance to go deep on that yet, but I'm familiar with the basics and eager to build the skill.",
      "That is not an area I've owned directly yet, but I'm interested in developing it with the right context.",
      "I haven't worked hands-on with that yet, but I've been following it and would be excited to learn more.",
    ],
    frame: "Own the gap + show awareness + growth plan.",
    note: "This is a more senior gap answer because it shows awareness instead of pretending expertise.",
    stress: ["haven't gone deep", "tracking", "build it"],
  },
  L3_13: {
    tier: "native_upgrade",
    targetText: "Thanks again for the conversation. It reinforced my interest in the role, and I'm happy to share anything else that would be helpful.",
    variants: [
      "Thanks again for the conversation. It made me even more interested in the role and the team.",
      "I appreciate the thoughtful conversation today. It reinforced my interest in the opportunity.",
      "Thanks again for your time. I'm excited about the role and happy to provide anything else you need.",
    ],
    frame: "Warm close + renewed interest + helpful follow-up.",
    note: "This closes confidently without sounding scripted or overly eager.",
    stress: ["thanks again", "reinforced", "helpful"],
  },
};

function expressionChunks(text) {
  const chunks = String(text || "")
    .split(/[.!?]+\s+|;|, and |, but |\u2014/)
    .map((item) => item.trim().replace(/[.!?]+$/, ""))
    .filter(Boolean);
  if (chunks.length) return compactList(chunks, 4);
  return chunksFromTargetText(text);
}

function expressionStarter(text) {
  const firstChunk = expressionChunks(text)[0] || String(text || "").trim();
  const words = firstChunk.split(/\s+/).filter(Boolean);
  if (words.length <= 7) return firstChunk;
  return `${words.slice(0, 7).join(" ")}...`;
}

function expressionCloze(text) {
  const words = String(text || "")
    .replace(/[.!?]+$/, "")
    .split(/\s+/)
    .filter(Boolean);
  if (words.length <= 4) return text;
  return words
    .map((word, index) => {
      const clean = word.replace(/[^A-Za-z']/g, "");
      if (index % 4 !== 1 || clean.length < 5) return word;
      return `${clean[0]}_____`;
    })
    .join(" ");
}

function expressionSlots(text) {
  const slots = [];
  const patterns = {
    role: /\b(designer|product manager|software engineer|marketing specialist|team lead)\b/i,
    company: /\b(growing company|tech company|startup|company)\b/i,
    field: /\b(marketing|design|software engineering|product management|operations|UX)\b/i,
    duration: /\b(three years|four years|five years|over five years|past four years)\b/i,
    metric: /\b(30%|two weeks|a third|six months)\b/i,
  };
  for (const [name, pattern] of Object.entries(patterns)) {
    const match = String(text || "").match(pattern);
    if (match) slots.push({ name, example: match[0] });
  }
  return slots;
}

const jobFrameLabelByStage = {
  "开场感谢": "感谢面试官 + 表达积极态度",
  "当前职位": "当前职位 + 公司类型 + 工作重点",
  "经验领域": "经验年限 + 专业领域 + 具体方向",
  "经历成就": "经历背景 + 负责动作 + 结果",
  "问题解决": "发现问题 + 采取动作 + 改进结果",
  "优势说明": "一个优势 + 对团队/岗位的价值",
  "压力回应": "压力场景 + 处理方法 + 稳定表现",
  "求职动机": "求职动机 + 贡献 + 成长",
  "职业规划": "时间方向 + 成长目标 + 贡献方式",
  "反向提问": "围绕岗位真实工作提出问题",
  "后续流程": "礼貌询问后续流程",
  "应对难题": "诚实承认不足 + 表达学习能力",
  "结束致谢": "感谢 + 积极兴趣 + 后续配合",
};

function productFrameLabel(node, profile) {
  return jobFrameLabelByStage[node.stageLabel] || profile.frame;
}

function buildProductHintTree(node, profile) {
  const starter = expressionStarter(profile.targetText);
  const frameLabel = productFrameLabel(node, profile);
  return {
    L1: `先完成这件事：${frameLabel}。不用背整句，先说出自己的真实信息。`,
    L2: `可以用这个开头："${starter}"，后面换成你的真实经历或岗位。`,
    L3: expressionCloze(profile.targetText),
    L4: `${profile.targetText} —— ${profile.note} 再用你自己的信息说一遍。`,
  };
}

function buildProductCoachRubric(node, profile) {
  return {
    mustCover: [
      `Complete the communicative move: ${productFrameLabel(node, profile)}`,
      `Use the model expression as a ${profile.tier} answer, but personalize role/company/result details.`,
      `Answer the interviewer question directly in context: ${node.naturalTiming || node.stageLabel}.`,
      `Keep the pragmatic tone: ${profile.note}`,
    ],
    masterySignals: [
      "The learner completes the intent with their own facts, not necessarily the exact model sentence.",
      "The answer sounds interview-appropriate, specific enough, and easy to follow.",
      "The learner can use the target wording, an accepted variant, or a natural equivalent.",
    ],
    nearMissSignals: [
      "The answer is on-topic but misses one core detail, evidence point, or professional tone marker.",
      "The answer is understandable but sounds too generic, translated, or incomplete.",
      "The learner uses a starter but still needs one guided retry with their own information.",
    ],
    missSignals: [
      "The learner repeats the interviewer question or avoids answering it.",
      "The answer is off-topic, mostly Chinese, or too short to judge.",
      "The response mentions related words but does not complete the communicative intent.",
    ],
  };
}

function buildProductNodeInputs(node, profile) {
  const chunks = expressionChunks(profile.targetText);
  const choices = compactList([profile.targetText, ...(profile.variants || [])], 4);
  return {
    frames: compactList([
      profile.frame,
      `${expressionStarter(profile.targetText)} + your real role/project/result`,
      "Keep the model answer short; replace examples with the learner's actual background.",
    ], 3),
    choices,
    chunks,
    contrast: compactList(profile.contrast || [], 2),
    naturalnessTips: compactList([
      profile.note,
      "Prioritize a personalized interview-ready answer over memorizing the exact sentence.",
    ], 3),
    pronunciationTips: compactList([
      "Speak in one calm thought group, with a small pause before the key phrase.",
      "Sound prepared but not memorized.",
      ...(profile.stress || []),
    ], 5),
    transferPrompts: compactList([
      node.followupQuestion,
      `Use the same move in a recruiter screen for ${node.stageLabel}.`,
      `Use the same move in a hiring manager interview with one concrete detail.`,
    ], 3),
  };
}

function applyJobExpressionProductPolish(node) {
  const profile = jobExpressionProductPolish[node.id];
  if (!profile) return node;
  const targetText = profile.targetText;
  const expectedVariants = compactList([targetText, ...(profile.variants || [])], 6)
    .map((text, index) => ({
      text,
      kind: index === 0 ? profile.tier : index === 1 ? "starter_variant" : "role_variant",
    }));
  return {
    ...node,
    targetText,
    pragmaticNote: profile.note,
    expectedVariants,
    slots: expressionSlots(targetText),
    hintTree: buildProductHintTree(node, profile),
    coachRubric: buildProductCoachRubric(node, profile),
    speechFocus: {
      stress: compactList(profile.stress || [], 5),
      pronunciation: compactList((profile.stress || []).slice(0, 2), 2),
      rhythm: "Speak in one calm thought group, with a small pause before the key phrase.",
      tone: "Confident, concise, and personalized; sound interview-ready without sounding memorized.",
    },
    contextVariants: compactList([
      `Recruiter screening call; use a concise ${profile.tier} version.`,
      `Hiring manager live interview; personalize the answer with one real detail.`,
      `Panel interview follow-up; keep the same intent but adjust role/company/result details.`,
    ], 3),
    personalizationCues: compactList([
      "Replace role, company type, domain, metric, and project examples with the learner's actual background.",
      "Accept natural equivalents that complete the communicative intent; do not force exact memorization.",
      "When the answer is too generic, ask for one concrete role/project/result detail.",
    ], 3),
    expressionProfile: {
      tier: profile.tier,
      modelRole: "model_expression_not_exact_script",
      productPositioning: "starter/interview_ready/native_upgrade progression",
    },
    nodeInputs: buildProductNodeInputs(node, profile),
  };
}

function nodeInputsFromMoveSet(node) {
  const inputs = {
    frames: [],
    choices: [],
    chunks: [],
    contrast: [],
    naturalnessTips: [],
    pronunciationTips: [],
    transferPrompts: [],
  };
  const moves = node.coachMoves?.moveSet || [];
  for (const move of moves) {
    const rawInputs = move.inputs || {};
    for (const key of Object.keys(inputs)) {
      inputs[key].push(...(rawInputs[key] || []));
    }
  }
  const result = {};
  for (const [key, values] of Object.entries(inputs)) {
    const max = key === "chunks" ? 5 : 3;
    const items = compactList(values, max);
    if (items.length) result[key] = items;
  }
  return result;
}

function chunksFromTargetText(targetText) {
  const words = String(targetText || "")
    .replace(/[“”"]/g, "")
    .split(/\s+/)
    .map((word) => word.trim())
    .filter(Boolean);
  if (words.length <= 5) return compactList([words.join(" ")], 2);
  const midpoint = Math.ceil(words.length / 2);
  return compactList([
    words.slice(0, midpoint).join(" "),
    words.slice(midpoint).join(" "),
  ], 2);
}

function nodeInputsFromNode(node) {
  const choices = compactList([
    node.targetText,
    ...((node.expectedVariants || []).map((item) => item.text).filter(Boolean)),
  ], 3);
  const speechFocus = node.speechFocus || {};
  const transferPrompts = compactList([
    node.followupQuestion,
    ...(node.contextVariants || []),
  ], 3);
  return {
    frames: compactList([
      `${node.intent || node.stageLabel} + 一个自己的具体信息`,
      node.hintTree?.L2,
    ], 3),
    choices,
    chunks: chunksFromTargetText(node.targetText),
    naturalnessTips: compactList([
      node.pragmaticNote,
      node.coachMoves?.ifUnnatural,
    ], 3),
    pronunciationTips: compactList([
      speechFocus.rhythm,
      speechFocus.tone,
      ...((speechFocus.pronunciation || []).slice(0, 2)),
    ], 4),
    transferPrompts,
  };
}

function hasNodeInputs(value) {
  return Boolean(
    value &&
      Object.values(value).some((item) =>
        Array.isArray(item) ? item.length > 0 : Boolean(item)
      )
  );
}

function signalForSubSkill(subSkill, node) {
  const examples = compactList([
    ...(signalExamples[subSkill] || []),
    ...((node.expectedVariants || []).map((item) => item.text).filter(Boolean)),
  ], 5);
  return {
    id: subSkill,
    match: "semantic_or_example",
    weight: 1,
    examples,
  };
}

function structuredRubric(node, capability) {
  const old = node.coachMoves?.masteryRubric || {};
  const requiredSignals = capability.subSkills.map((subSkill) => signalForSubSkill(subSkill, node));
  return {
    requiredSignals,
    acceptedVariants: compactList([
      node.targetText,
      ...((node.expectedVariants || []).map((item) => item.text).filter(Boolean)),
      ...(old.acceptedVariants || []),
    ], 8),
    nearMissSignals: [
      {
        id: "missing_one_required_signal",
        scoring: "required_signal_count >= total_required_signals - 1",
        examples: ["intent is clear but one capability signal is missing"],
      },
      {
        id: "rough_but_understandable",
        scoring: "semantic intent present with grammar or naturalness issue",
        examples: ["understandable answer with translated or incomplete phrasing"],
      },
    ],
    missSignals: [
      {
        id: "question_echo",
        scoring: "learner repeats interviewer question without answering",
        examples: ["echoes the prompt"],
      },
      {
        id: "off_topic_or_too_short",
        scoring: "answer lacks communicative intent or has fewer than 3 useful words",
        examples: ["mostly Chinese", "too short", "off-topic"],
      },
    ],
    nearMissScoring: {
      masteredThreshold: 0.78,
      nearMissThreshold: 0.46,
      acceptedVariantBonus: 0.25,
      semanticEquivalence: true,
      tokenCoverageIsWeakSignalOnly: true,
    },
  };
}

function communicativeIntentForNode(node, capability) {
  const requiredCapabilities = capability.subSkills.map((subSkill) => ({
    id: subSkill,
    weight: Number((1 / Math.max(1, capability.subSkills.length)).toFixed(3)),
  }));
  const optionalCapabilities = [];
  if (
    capability.primaryIntent === "professional_opening" ||
    capability.primaryIntent === "onboarding_welcome_response" ||
    capability.primaryIntent === "onboarding_warm_closing"
  ) {
    optionalCapabilities.push({ id: "warmth", weight: 0.2 });
  }
  if (
    capability.primaryIntent === "achievement_storytelling" ||
    capability.primaryIntent === "problem_solving_impact" ||
    capability.primaryIntent === "onboarding_experience_link" ||
    capability.primaryIntent === "onboarding_responsibility_scope"
  ) {
    optionalCapabilities.push({ id: "specificity", weight: 0.2 });
  }
  return {
    id: capability.primaryIntent,
    requiredCapabilities,
    optionalCapabilities,
    topicSignals: compactList([
      node.tag,
      node.stageLabel,
      node.intent,
      node.question,
    ], 4),
    completionRule:
      "target_completed requires topicMatch=true and weighted requiredCapabilities coverage >= masteredThreshold",
  };
}

function narrativeForNode(node, config) {
  const pressureLevel =
    levelPressure[node.targetLevel] ?? levelPressure.beginner;
  const sceneNarrative = config.narrative;
  const interruptionOverride = config.interruptionOverride?.(node);
  return {
    ...sceneNarrative,
    interviewerProfile: {
      ...sceneNarrative.interviewerProfile,
      pressureLevel,
      interruptiveness:
        interruptionOverride ?? sceneNarrative.interviewerProfile.interruptiveness ?? 0.2,
    },
    arcStage: config.stageArcMap[node.stageLabel] || "evaluation",
    runtimePriority: [
      "narrative_runtime",
      "intent_coverage_engine",
      "teaching_runtime",
      "planner",
      "llm_generator",
    ],
  };
}

function teachingVisibilityForNode(node) {
  return {
    mode: node.targetLevel === "beginner" ? "visible" : "hidden",
    visibleWhen: ["repeated_failure", "user_confused", "ask_for_help"],
    hiddenWhen: ["target_completed", "advanced_level", "conversation_flow_ok"],
  };
}

function correctionPolicyForNode() {
  return {
    grammar: "delayed",
    pronunciation: "immediate",
    off_topic: "immediate",
    naturalness: "recast",
    confidence_damage_risk: "avoid_interrupting",
  };
}

function migrateWiki(config) {
  const wiki = readJson(config.path);
  wiki.schemaVersion = Math.max(2, Number(wiki.schemaVersion || 1));
  wiki.nodes = (wiki.nodes || []).map((rawNode) => {
    const node =
      config.id === "job_interview"
        ? applyJobExpressionProductPolish(rawNode)
        : rawNode;
    const capability =
      config.stageCapabilityMap[node.stageLabel] || config.defaultCapability;
    const moveSetInputs = nodeInputsFromMoveSet(node);
    const nodeInputs = hasNodeInputs(node.nodeInputs)
      ? node.nodeInputs
      : hasNodeInputs(moveSetInputs)
        ? moveSetInputs
        : nodeInputsFromNode(node);
    const existingCoachMoves = node.coachMoves || {};
    const { moveSet, ...coachMoveCompatFields } = existingCoachMoves;
    return {
      ...node,
      capability,
      communicativeIntent: communicativeIntentForNode(node, capability),
      narrative: narrativeForNode(node, config),
      teachingVisibility: teachingVisibilityForNode(node),
      correctionPolicy: correctionPolicyForNode(node),
      delayedFeedback: {
        grammar: [],
        naturalness: [],
        pronunciation: [],
        recapWhen: "session_end",
      },
      allowedMoves: defaultAllowedMoves,
      nodeInputs,
      adaptivePolicy: {
        ifRepeatedFailure: "chunk_shadowing",
        ifAnxietyHigh: "choice_prompt",
        ifGrammarWeak: "sentence_bridge",
        ifFluencyWeak: "micro_drill",
        ifCapabilityMastered: "transfer_practice",
      },
      coachMoves: {
        ...coachMoveCompatFields,
        schemaVersion: 2,
        masteryRubric: structuredRubric(node, capability),
      },
    };
  });
  writeJson(config.path, wiki);
  if (config.id === "job_interview") {
    writeJson(LEGACY_JOB_WIKI_PATH, wiki);
  }
}

function writeSeedFiles() {
  writeJson(CAPABILITY_REGISTRY_PATH, capabilityRegistry);
  writeJson(COACH_MOVE_LIBRARY_PATH, moveLibrary);
  writeJson(USER_WEAKNESS_PROFILE_PATH, {
    schemaVersion: 1,
    userId: "local_default",
    grammar: [],
    speaking: [],
    pragmatics: [],
    updatedAt: "",
  });
  writeJson(CAPABILITY_MASTERY_STATE_PATH, {
    schemaVersion: 1,
    capabilities: Object.fromEntries(
      capabilityRegistry.capabilities.map((capability) => [
        capability.id,
        { mastery: 0, lastUpdated: "", relatedNodes: [] },
      ])
    ),
  });

  writeJson(
    path.join(BACKEND_DATA_DIR, "capability_registry.json"),
    capabilityRegistry
  );
  writeJson(
    path.join(BACKEND_DATA_DIR, "coach_move_library.json"),
    moveLibrary
  );
}

writeSeedFiles();
migrateWiki(sceneConfigs[0]);
migrateWiki(sceneConfigs[1]);

console.log("Built capability registry, coach move library, seed state, and migrated interview scene wikis.");
