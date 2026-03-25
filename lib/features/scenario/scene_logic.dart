part of 'scene_page.dart';

String _buildSceneCoachAnswer(String question) {
  final String normalized = question.toLowerCase();

  if (normalized.contains('语法') ||
      normalized.contains('grammar') ||
      normalized.contains('because') ||
      normalized.contains('due to')) {
    return '语法上这里更适合先给完整结论，再补原因。你可以说：'
        '\n“We slipped by three days because the final QA fixes took longer than expected.”'
        '\n如果想更书面一点，再换成：'
        '\n“The three-day delay was due to longer-than-expected QA fixes.”';
  }

  if (normalized.contains('单词') ||
      normalized.contains('word') ||
      normalized.contains('vocab') ||
      normalized.contains('delay') ||
      normalized.contains('postpone')) {
    return '这组词可以这样分：'
        '\n`delay` 更像“延期/耽搁”，常用于项目、进度、航班。'
        '\n`postpone` 更像“把原定安排往后挪”，语气更主动。'
        '\n在你这个场景里，解释项目延期优先用 `delay` 或 `slip`。';
  }

  if (normalized.contains('表达') ||
      normalized.contains('怎么说') ||
      normalized.contains('how to say') ||
      normalized.contains('polite')) {
    return '这个场景里，常用表达优先记这 3 句：'
        '\n1. “We slipped by three days, but the recovery plan is already in motion.”'
        '\n2. “The client will receive an updated timeline before 6 PM today.”'
        '\n3. “I’m owning the next checkpoint and will keep you posted.”';
  }

  return '如果你现在是想在对话里临时补一句，建议遵循这个顺序：'
      '\n先结论：先说发生了什么。'
      '\n再原因：只补最关键的一个原因。'
      '\n最后动作：明确下一步、负责人和时间点。';
}

String _inferSceneEmoji(String text) {
  if (text.contains('面试')) return '💼';
  if (text.contains('老板') || text.contains('项目')) return '📊';
  if (text.contains('客户')) return '🤝';
  if (text.contains('电话')) return '☎️';
  return '🗣️';
}
