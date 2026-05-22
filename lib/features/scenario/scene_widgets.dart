part of 'scene_page.dart';

class _SceneScaffold extends StatelessWidget {
  const _SceneScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: appBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 54, 18, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF213E3A),
                  Color(0xFF2E6058),
                  Color(0xFF6EA8A0),
                  appBackground,
                ],
                stops: [0, 0.5, 0.82, 1],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x14FFFFFF),
                  ),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xD5DFF8F2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SceneFriendHomeHeader extends StatelessWidget {
  const _SceneFriendHomeHeader({
    required this.searchController,
    required this.onAddFriend,
  });

  final TextEditingController searchController;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.8),
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '场景好友',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onAddFriend,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                    ),
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              children: [
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF8B8B8B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: '搜索角色、职业、性格或爱好',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9A9A9A),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6F2E6)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: Color(0xFF1AAD19),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '好友都可以自定义角色、性格、爱好、职业。点击任意角色后，再进入二级“场景创建”页。',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5F6B5F),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneCreateEntryTile extends StatelessWidget {
  const _SceneCreateEntryTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EA),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF1AAD19),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '场景创建',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '进入二级页，继续使用当前角色或从头生成新场景',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB5B5B5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VirtualFriendTile extends StatelessWidget {
  const _VirtualFriendTile({
    required this.friend,
    required this.timeLabel,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    this.onDelete,
  });

  final _VirtualFriend friend;
  final String timeLabel;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final String meta = <String>[
      if (friend.profession.trim().isNotEmpty) friend.profession.trim(),
      if (friend.role.trim().isNotEmpty) friend.role.trim(),
    ].join(' · ');
    return Material(
      color: selected ? const Color(0xFFF7FFF7) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VirtualFriendAvatarBadge(
                emoji: friend.avatarEmoji,
                size: 48,
                borderRadius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            friend.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                        if (friend.isCustom)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2FAF2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '自定义',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1AAD19),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1AAD19),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      friend.previewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A8A8A),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB2B2B2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          return;
                        case 'delete':
                          onDelete?.call();
                          return;
                      }
                    },
                    color: Colors.white,
                    itemBuilder: (BuildContext context) {
                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('编辑角色'),
                        ),
                        if (onDelete != null)
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('删除角色'),
                          ),
                      ];
                    },
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: Color(0xFFB2B2B2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VirtualFriendAvatarBadge extends StatelessWidget {
  const _VirtualFriendAvatarBadge({
    required this.emoji,
    this.size = 44,
    this.borderRadius = 12,
  });

  final String emoji;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4FFF4), Color(0xFFE7F7EA)],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFDDEDDD)),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji.isEmpty ? '🙂' : emoji,
        style: TextStyle(fontSize: size * 0.44),
      ),
    );
  }
}

class _VirtualFriendDetailHero extends StatelessWidget {
  const _VirtualFriendDetailHero({
    required this.friend,
    required this.onBack,
    required this.onEdit,
  });

  final _VirtualFriend friend;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final List<String> chips = <String>[
      if (friend.personality.trim().isNotEmpty)
        ...friend.personality
            .split(RegExp(r'[、,，·]'))
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .take(3),
      if (friend.role.trim().isNotEmpty && friend.personality.trim().isEmpty)
        friend.role.trim(),
    ];
    final String subtitle = <String>[
      if (friend.profession.trim().isNotEmpty) friend.profession.trim(),
      if (friend.role.trim().isNotEmpty) friend.role.trim(),
    ].join(' · ');
    final String hobbies = friend.hobbies.isEmpty
        ? '可继续补充兴趣偏好'
        : friend.hobbies.join(' · ');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9AA8D6), Color(0xFFABB6DD), Color(0xFFF8F5EF)],
          stops: [0, 0.52, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Column(
            children: [
              Row(
                children: [
                  _VirtualFriendDetailActionButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: onBack,
                  ),
                  const Spacer(),
                  _VirtualFriendDetailActionButton(
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFCF9),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE5EBF8), Color(0xFFC9D3ED)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            friend.avatarEmoji.isEmpty
                                ? '🙂'
                                : friend.avatarEmoji,
                            style: const TextStyle(fontSize: 44),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E1B18),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8C847C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: chips
                            .map(
                              (String item) =>
                                  _VirtualFriendSoftChip(label: item),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F1EA),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '说话风格',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFA59C91),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            friend.personality.trim().isEmpty
                                ? '自然、真实、符合设定，能围绕当前场景继续追问。'
                                : '${friend.personality.trim()}，会围绕细节继续追问并推进话题。',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF352F29),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '♡  $hobbies',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF978D83),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VirtualFriendDetailActionButton extends StatelessWidget {
  const _VirtualFriendDetailActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0x18FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x55FFFFFF)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _VirtualFriendSoftChip extends StatelessWidget {
  const _VirtualFriendSoftChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE4F6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6174B8),
        ),
      ),
    );
  }
}

class _VirtualFriendRecommendationSection extends StatelessWidget {
  const _VirtualFriendRecommendationSection({
    required this.items,
    required this.onTapItem,
  });

  final List<({String label, String prompt})> items;
  final ValueChanged<String> onTapItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.play_arrow_rounded, size: 20, color: Color(0xFF667CC1)),
            SizedBox(width: 8),
            Text(
              '快速开始场景',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B18),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '4 个推荐',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA7A097),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final ({String label, String prompt}) item = items[index];
              return _VirtualFriendRecommendationPill(
                label: item.label,
                onTap: () => onTapItem(item.prompt),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VirtualFriendRecommendationPill extends StatelessWidget {
  const _VirtualFriendRecommendationPill({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 176),
        padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFEAE1D6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FC),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF667CC1),
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 156),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2621),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VirtualFriendCustomSceneComposer extends StatelessWidget {
  const _VirtualFriendCustomSceneComposer({
    required this.friendName,
    required this.controller,
    required this.isLoading,
    required this.onGenerate,
  });

  final String friendName;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final bool canGenerate = controller.text.trim().isNotEmpty && !isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 18,
              color: Color(0xFF667CC1),
            ),
            SizedBox(width: 8),
            Text(
              '自定义场景',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xEEE9DED0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: TextField(
                  controller: controller,
                  maxLines: 5,
                  minLines: 5,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2B2621),
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '描述你想和 $friendName 练习的场景...',
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFB7AEA2),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1E8DD)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: canGenerate ? onGenerate : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFECE5DA),
                        disabledBackgroundColor: const Color(0xFFECE5DA),
                        foregroundColor: canGenerate
                            ? const Color(0xFF7A6A56)
                            : const Color(0xFFBFB4A6),
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      icon: isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  canGenerate
                                      ? const Color(0xFF7A6A56)
                                      : const Color(0xFFBFB4A6),
                                ),
                              ),
                            )
                          : const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: Text(
                        isLoading ? '生成中' : '生成场景',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VirtualFriendRecentPracticeSection extends StatelessWidget {
  const _VirtualFriendRecentPracticeSection({
    required this.practices,
    required this.onTapPractice,
  });

  final List<PracticeHistoryModel> practices;
  final ValueChanged<PracticeHistoryModel> onTapPractice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded, size: 18, color: Color(0xFF8E857A)),
            SizedBox(width: 8),
            Text(
              '最近练习',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (practices.isEmpty)
          const _RecentSceneEmptyCard()
        else
          ...practices.indexed.map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.$1 == practices.length - 1 ? 0 : 12,
              ),
              child: _VirtualFriendRecentPracticeCard(
                practice: entry.$2,
                onTap: () => onTapPractice(entry.$2),
              ),
            ),
          ),
      ],
    );
  }
}

class _VirtualFriendRecentPracticeCard extends StatelessWidget {
  const _VirtualFriendRecentPracticeCard({
    required this.practice,
    required this.onTap,
  });

  final PracticeHistoryModel practice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DateTime? practicedAt = practice.practicedAt;
    final String dateLabel = practicedAt == null
        ? (practice.timeLabel?.trim().isNotEmpty == true
              ? practice.timeLabel!.trim()
              : '最近一次')
        : '${practicedAt.year}-${practicedAt.month.toString().padLeft(2, '0')}-${practicedAt.day.toString().padLeft(2, '0')}';
    final int? score = practice.score;
    final bool goodScore = (score ?? 0) >= 85;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xEEE8DED1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF7386C3),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      practice.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2B2621),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFAAA093),
                      ),
                    ),
                  ],
                ),
              ),
              if (score != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${goodScore ? '↗' : '↘'} $score',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: goodScore
                          ? const Color(0xFF4C8C72)
                          : const Color(0xFF6C7DC0),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD0C5B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedFriendSummaryCard extends StatelessWidget {
  const _SelectedFriendSummaryCard({
    required this.friend,
    required this.onClear,
  });

  final _VirtualFriend friend;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final String summary = <String>[
      if (friend.profession.trim().isNotEmpty) friend.profession.trim(),
      if (friend.personality.trim().isNotEmpty) friend.personality.trim(),
    ].join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          _VirtualFriendAvatarBadge(emoji: friend.avatarEmoji, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xD9FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text(
              '清除',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedFriendPromptCard extends StatelessWidget {
  const _SelectedFriendPromptCard({required this.friend});

  final _VirtualFriend friend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_pin_circle_outlined,
                size: 18,
                color: Color(0xFF1AAD19),
              ),
              const SizedBox(width: 8),
              Text(
                '当前带入角色 · ${friend.name}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                <String>[
                      if (friend.role.trim().isNotEmpty) friend.role.trim(),
                      if (friend.profession.trim().isNotEmpty)
                        friend.profession.trim(),
                      if (friend.personality.trim().isNotEmpty)
                        friend.personality.trim(),
                      ...friend.hobbies.take(2),
                    ]
                    .map(
                      (String label) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FBF4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A6A3A),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
          ),
          if (friend.relationship.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              friend.relationship,
              style: const TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VirtualFriendsEmptyState extends StatelessWidget {
  const _VirtualFriendsEmptyState({required this.onCreateFriend});

  final VoidCallback onCreateFriend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        children: [
          const Text('👥', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          const Text(
            '还没有自定义角色',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '先创建一个虚拟好友，再从聊天列表进入场景创建。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onCreateFriend,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1AAD19),
            ),
            child: const Text('新建角色'),
          ),
        ],
      ),
    );
  }
}

class _VirtualFriendEditorField extends StatelessWidget {
  const _VirtualFriendEditorField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 13, color: textTertiary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF1AAD19)),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableCard extends StatelessWidget {
  const _EditableCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftOverviewInfoCard extends StatelessWidget {
  const _DraftOverviewInfoCard({
    required this.tintColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.label,
    required this.labelColor,
    required this.value,
    required this.icon,
  });

  final Color tintColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final String label;
  final Color labelColor;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                    height: 1.1,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18160F),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftOverviewWideCard extends StatelessWidget {
  const _DraftOverviewWideCard({
    required this.tintColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.label,
    required this.labelColor,
    required this.value,
    required this.icon,
  });

  final Color tintColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final String label;
  final Color labelColor;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                    height: 1.1,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3A3530),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftOverviewGoalCard extends StatelessWidget {
  const _DraftOverviewGoalCard({
    required this.label,
    required this.labelColor,
    required this.icon,
    required this.summary,
    required this.steps,
  });

  final String label;
  final Color labelColor;
  final String icon;
  final String summary;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0x08C0641A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x10C0641A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0x15C0641A),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                    height: 1.1,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (summary.trim().isNotEmpty) ...[
            Text(
              summary,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A6248),
                height: 1.55,
              ),
            ),
            if (steps.isNotEmpty) const SizedBox(height: 10),
          ],
          if (steps.isNotEmpty)
            Column(
              children: steps
                  .asMap()
                  .entries
                  .map(
                    (MapEntry<int, String> entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == steps.length - 1 ? 0 : 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0x15C0641A),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0x24C0641A),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFC0641A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF5A4A3A),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _EditSectionHeader extends StatelessWidget {
  const _EditSectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SceneTopPill extends StatelessWidget {
  const _SceneTopPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.suffix,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 6, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0x2E000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            suffix,
            style: const TextStyle(fontSize: 10, color: Color(0x85FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _SceneProgressPill extends StatelessWidget {
  const _SceneProgressPill({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x2E000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: const Color(0x33FFFFFF),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xD8A8E6DC),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(fontSize: 10, color: Color(0xA6FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _RecentSceneCard extends StatelessWidget {
  const _RecentSceneCard({
    required this.scene,
    required this.onSummary,
    required this.onContinue,
  });

  final _RecentScene scene;
  final VoidCallback onSummary;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final bool feedbackPending = scene.practice.feedbackStatus == 'pending';
    final String summaryLabel = feedbackPending ? '查看进度' : '查看总结';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scene.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    scene.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: scene.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scene.color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scene.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: scene.progress / 100,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFEDE9E3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                scene.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${scene.progress}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: scene.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '练习 ${scene.practiceCount} 次',
                style: const TextStyle(fontSize: 11, color: textSecondary),
              ),
              const SizedBox(width: 8),
              const Text(
                '·',
                style: TextStyle(fontSize: 11, color: textTertiary),
              ),
              const SizedBox(width: 8),
              Text(
                scene.lastTime,
                style: const TextStyle(fontSize: 11, color: textSecondary),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onSummary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: scene.color,
                  side: BorderSide(color: scene.color.withValues(alpha: 0.22)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(summaryLabel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: scene.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('继续练习'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentSceneEmptyCard extends StatelessWidget {
  const _RecentSceneEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: const Row(
        children: [
          Icon(Icons.history_rounded, size: 18, color: Color(0xFF8A8078)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '完成一次场景练习后，这里会显示你的最近记录',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  const _ConversationBubble({
    required this.message,
    required this.npcName,
    required this.npcAvatarEmoji,
    required this.userAvatarEmoji,
    required this.transcriptExpanded,
    required this.transcriptTranslated,
    required this.transcriptTranslating,
    this.transcriptTranslation,
    this.onVoiceLongPress,
    this.onTranscriptTranslateTap,
    this.onVoiceTap,
    this.onCoachTap,
    this.coachExpanded = false,
  });

  final _ChatMessage message;
  final String npcName;
  final String npcAvatarEmoji;
  final String userAvatarEmoji;
  final bool transcriptExpanded;
  final bool transcriptTranslated;
  final bool transcriptTranslating;
  final String? transcriptTranslation;
  final VoidCallback? onVoiceLongPress;
  final VoidCallback? onTranscriptTranslateTap;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onCoachTap;
  final bool coachExpanded;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (message.role == _MessageRole.event) {
      final Color accent = message.accent ?? const Color(0xFF7ACFBD);
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark ? const Color(0x14FFFFFF) : borderColor,
                thickness: 1,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark ? const Color(0x14FFFFFF) : borderColor,
                thickness: 1,
              ),
            ),
          ],
        ),
      );
    }

    if (message.role == _MessageRole.coach) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCoachTap,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                _CoachTagChip(
                  label: '语法',
                  icon: Icons.warning_amber_rounded,
                  foreground: isDark
                      ? const Color(0xFFF3D689)
                      : const Color(0xFF8B6D21),
                  background: isDark
                      ? const Color(0x14E9C46A)
                      : const Color(0xFFFFF6DE),
                  border: isDark
                      ? const Color(0x33E9C46A)
                      : const Color(0xFFE8D6A0),
                ),
                _CoachTagChip(
                  label: message.note?.trim().isNotEmpty == true
                      ? message.note!.trim()
                      : message.text,
                  foreground: isDark
                      ? const Color(0xFFCEEBD9)
                      : const Color(0xFF4D7A65),
                  background: isDark
                      ? const Color(0x143E6C5A)
                      : const Color(0xFFF2F7F3),
                  border: isDark
                      ? const Color(0x334E8B72)
                      : const Color(0xFFDDE9E2),
                ),
                if (onCoachTap != null)
                  _CoachTagChip(
                    label: coachExpanded ? '收起' : '优化',
                    foreground: isDark
                        ? const Color(0xFFCDCDCD)
                        : const Color(0xFF909090),
                    background: isDark
                        ? const Color(0x14FFFFFF)
                        : const Color(0xFFF2F2F2),
                    border: isDark
                        ? const Color(0x1FFFFFFF)
                        : const Color(0xFFE5E5E5),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isNpc = message.role == _MessageRole.npc;
    final bool isVoice = message.inputType == _ChatInputType.voice;
    final Color bubbleBackgroundColor = isNpc
        ? Colors.white
        : (isDark ? const Color(0xFF80DA53) : const Color(0xFF95EC69));
    final Color bubbleBorderColor = isNpc
        ? (isDark ? const Color(0x1FFFFFFF) : const Color(0xFFE8E8E8))
        : (isDark ? const Color(0xFF71C547) : const Color(0xFF89DB61));
    final Color bubbleTextColor = isNpc
        ? const Color(0xFF1F1F1F)
        : const Color(0xFF1B3A12);
    final BorderRadius bubbleRadius = BorderRadius.circular(24).copyWith(
      topLeft: isNpc ? const Radius.circular(8) : const Radius.circular(24),
      topRight: isNpc ? const Radius.circular(24) : const Radius.circular(8),
    );

    Widget avatar(String emoji) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFDDEEE3),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      );
    }

    Widget messageBubble() {
      return GestureDetector(
        onTap: isVoice ? onVoiceTap : null,
        onLongPress: isVoice ? onVoiceLongPress : null,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            isVoice ? 14 : 13,
            16,
            isVoice ? 14 : 13,
          ),
          decoration: BoxDecoration(
            color: bubbleBackgroundColor,
            borderRadius: bubbleRadius,
            border: Border.all(color: bubbleBorderColor),
            boxShadow: isNpc
                ? [
                    BoxShadow(
                      color: const Color(0x12000000),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: isVoice
              ? _VoiceMessageCard(
                  isNpc: isNpc,
                  duration: message.voiceDuration ?? (isNpc ? 8 : 6),
                )
              : Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: bubbleTextColor,
                  ),
                ),
        ),
      );
    }

    Widget transcriptCard() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: isNpc
              ? (isDark ? const Color(0x12111714) : const Color(0xFFF8F5EF))
              : (isDark ? const Color(0x12324E47) : const Color(0xFFF1F8F5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNpc
                ? (isDark ? const Color(0x1EFFFFFF) : borderColor)
                : const Color(0x335A9E90),
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xE6FFFFFF) : textPrimary,
              height: 1.55,
            ),
            children: [
              TextSpan(
                text:
                    transcriptTranslated &&
                        (transcriptTranslation?.trim().isNotEmpty ?? false)
                    ? transcriptTranslation!.trim()
                    : message.text,
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _InlineTranscriptTranslateButton(
                    translated: transcriptTranslated,
                    loading: transcriptTranslating,
                    onTap: onTranscriptTranslateTap ?? () {},
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Widget bubbleColumn = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isNpc ? 288 : 296),
      child: Column(
        crossAxisAlignment: isNpc
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (isNpc) ...[
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                npcName,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0x99FFFFFF)
                      : const Color(0xFF9B9B9B),
                ),
              ),
            ),
          ],
          messageBubble(),
          if (isVoice && transcriptExpanded) ...[
            const SizedBox(height: 8),
            transcriptCard(),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: isNpc
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isNpc
            ? [avatar(npcAvatarEmoji), const SizedBox(width: 14), bubbleColumn]
            : [
                Flexible(child: bubbleColumn),
                const SizedBox(width: 12),
                avatar(userAvatarEmoji),
              ],
      ),
    );
  }
}

class _VoiceMessageCard extends StatelessWidget {
  const _VoiceMessageCard({required this.isNpc, required this.duration});

  final bool isNpc;
  final int duration;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double waveformWidth = (duration * 12.0).clamp(44.0, 92.0);
    final Color iconColor = isNpc
        ? (isDark ? const Color(0xFFD0D0D0) : const Color(0xFF7A7A7A))
        : const Color(0xFF2D6A1E);
    final Color durationColor = isNpc
        ? (isDark ? const Color(0xB3FFFFFF) : const Color(0xFF949494))
        : const Color(0xFF2D6A1E);
    final Color waveformColor = isNpc
        ? (isDark ? const Color(0xB3FFFFFF) : const Color(0xFF7D7D7D))
        : const Color(0xFF2D6A1E);
    final List<double> bars = <double>[12, 18, 24, 28, 24, 18];

    Widget waveform() {
      return SizedBox(
        width: waveformWidth,
        height: 28,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: bars
              .map(
                (double height) => Container(
                  width: 5,
                  height: height,
                  decoration: BoxDecoration(
                    color: waveformColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      );
    }

    if (isNpc) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volume_up_rounded, size: 22, color: iconColor),
          const SizedBox(width: 14),
          waveform(),
          const SizedBox(width: 16),
          Text(
            '$duration"',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: durationColor,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$duration"',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: durationColor,
          ),
        ),
        const SizedBox(width: 16),
        waveform(),
        const SizedBox(width: 14),
        Icon(Icons.volume_up_rounded, size: 22, color: iconColor),
      ],
    );
  }
}

class _CoachTagChip extends StatelessWidget {
  const _CoachTagChip({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImprovementCard extends StatelessWidget {
  const _ImprovementCard({
    required this.index,
    required this.emoji,
    required this.title,
    required this.detail,
    required this.color,
  });

  final int index;
  final String emoji;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE9E3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A6258),
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackMetric extends StatelessWidget {
  const _FeedbackMetric({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFF2EFE9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTurnReviewCard extends StatelessWidget {
  const _FeedbackTurnReviewCard({required this.review});

  final SceneFeedbackTurnReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '第 ${review.turnIndex} 条语音',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x124A7C6F),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '发音 ${review.pronunciationScore}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A7C6F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              review.originalText,
              style: const TextStyle(
                fontSize: 13,
                color: textPrimary,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FeedbackTurnReviewLine(
            label: '发音',
            body: review.pronunciationComment,
          ),
          const SizedBox(height: 8),
          _FeedbackTurnReviewLine(label: '语法', body: review.grammarComment),
          const SizedBox(height: 8),
          _FeedbackTurnReviewLine(label: '表达', body: review.expressionComment),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x114A7C6F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x224A7C6F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '更佳表达',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A7C6F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  review.betterExpression,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.55,
                  ),
                ),
                if (review.betterExpressionTranslation != null &&
                    review.betterExpressionTranslation!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    review.betterExpressionTranslation!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTurnReviewLine extends StatelessWidget {
  const _FeedbackTurnReviewLine({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFF2EFE8),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineTranscriptTranslateButton extends StatelessWidget {
  const _InlineTranscriptTranslateButton({
    required this.translated,
    required this.loading,
    required this.onTap,
  });

  final bool translated;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = translated
        ? (isDark ? const Color(0x224A7C6F) : const Color(0x144A7C6F))
        : (isDark ? const Color(0x14FFFFFF) : const Color(0xFFF4F1EB));
    final Color borderColor = translated
        ? const Color(0x664A7C6F)
        : (isDark ? const Color(0x29FFFFFF) : const Color(0xFFE2DBD1));
    final Color foregroundColor = translated
        ? (isDark ? const Color(0xFFD5EEE8) : const Color(0xFF2E6058))
        : (isDark ? const Color(0xCCFFFFFF) : textSecondary);
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.4,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            else
              Icon(Icons.translate_rounded, size: 12, color: foregroundColor),
            const SizedBox(width: 4),
            Text(
              loading
                  ? '翻译中'
                  : translated
                  ? '原文'
                  : '翻译',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
