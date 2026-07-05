import 'package:flutter/material.dart';

import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/utils/app_cached_network_image.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController? _nameController;
  String? _selectedAvatar;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameController != null) {
      return;
    }
    final AppSession session = AppSessionScope.of(context);
    _nameController = TextEditingController(text: session.nickname);
    _selectedAvatar = session.avatarUrl;
  }

  @override
  void dispose() {
    _nameController?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final TextEditingController? nameController = _nameController;
    final String? selectedAvatar = _selectedAvatar;
    if (_saving || nameController == null || selectedAvatar == null) {
      return;
    }
    setState(() => _saving = true);
    final AppSession session = AppSessionScope.of(context);
    await session.updateProfile(
      nickname: nameController.text,
      avatarUrl: selectedAvatar,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextEditingController? nameController = _nameController;
    final String? selectedAvatar = _selectedAvatar;
    if (nameController == null || selectedAvatar == null) {
      return const Scaffold(
        backgroundColor: appBackground,
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFCF9),
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.editProfile,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A2820),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            key: const ValueKey<String>('edit_profile_save_button'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A7244),
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Text(
            l10n.chooseAvatar,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2A2820),
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: defaultAvatarUrls.map((String url) {
              final bool selected = url == selectedAvatar;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = url),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF4A7244)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppCachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: const AppImagePlaceholder(
                            color: Color(0xFFDBE7D4),
                            icon: Icons.person_rounded,
                            iconColor: Colors.white,
                          ),
                          errorWidget: const AppImagePlaceholder(
                            color: Color(0xFF87B076),
                            icon: Icons.person_rounded,
                            iconColor: Colors.white,
                          ),
                        ),
                        if (selected)
                          const ColoredBox(
                            color: Color(0x33000000),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.nickname,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2A2820),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey<String>('edit_profile_nickname_input'),
            controller: nameController,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: l10n.enterNickname,
              hintStyle: const TextStyle(color: Color(0xFF9A9289)),
              filled: true,
              fillColor: Colors.white,
              counterStyle: const TextStyle(
                color: Color(0xFF9A9289),
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8E3DC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8E3DC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF4A7244),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
