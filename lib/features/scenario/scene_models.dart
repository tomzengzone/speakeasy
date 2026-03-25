part of 'scene_page.dart';

class _RecentScene {
  const _RecentScene({
    required this.title,
    required this.emoji,
    required this.tags,
    required this.color,
    required this.practiceCount,
    required this.lastTime,
    required this.progress,
  });

  final String title;
  final String emoji;
  final List<String> tags;
  final Color color;
  final int practiceCount;
  final String lastTime;
  final int progress;
}

class _CoachSuggestionChip extends StatelessWidget {
  const _CoachSuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0x124A7C6F),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x334A7C6F)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD5EEE8),
          ),
        ),
      ),
    );
  }
}

enum _ChatInputType { voice, text }

enum _MessageRole { event, npc, user, coach }

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.text,
    this.note,
    this.mood,
    this.inputType,
    this.voiceDuration,
    this.accent,
  });

  final _MessageRole role;
  final String text;
  final String? note;
  final String? mood;
  final _ChatInputType? inputType;
  final int? voiceDuration;
  final Color? accent;
}

class _ThinkingDot extends StatefulWidget {
  const _ThinkingDot({required this.delay});

  final Duration delay;

  @override
  State<_ThinkingDot> createState() => _ThinkingDotState();
}

class _ThinkingDotState extends State<_ThinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF9A9289),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
