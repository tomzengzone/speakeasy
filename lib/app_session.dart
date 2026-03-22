import 'package:flutter/material.dart';

const List<String> defaultAvatarUrls = <String>[
  'https://images.unsplash.com/photo-1725887150031-d353e5c4ce3a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
  'https://images.unsplash.com/photo-1517841905240-472988babdf9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
  'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
  'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=160',
];

enum LoginProvider { wechat, apple, phone, email }

class LoginSubmission {
  const LoginSubmission({
    required this.provider,
    this.phone,
    this.code,
    this.email,
    this.password,
    this.nickname,
    this.isRegister = false,
  });

  final LoginProvider provider;
  final String? phone;
  final String? code;
  final String? email;
  final String? password;
  final String? nickname;
  final bool isRegister;
}

class AppUser {
  const AppUser({
    required this.nickname,
    required this.avatarUrl,
    required this.memberPlan,
  });

  final String nickname;
  final String avatarUrl;
  final String memberPlan;

  AppUser copyWith({String? nickname, String? avatarUrl, String? memberPlan}) {
    return AppUser(
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberPlan: memberPlan ?? this.memberPlan,
    );
  }
}

abstract class AppRepository {
  Future<AppUser> signIn(LoginSubmission submission);

  Future<AppUser> changeMembership({
    required AppUser user,
    required String planId,
  });
}

class DemoAppRepository implements AppRepository {
  static const Set<String> _validPlans = <String>{
    'free',
    'monthly',
    'yearly',
    'lifetime',
  };

  @override
  Future<AppUser> signIn(LoginSubmission submission) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final String nickname = switch (submission.provider) {
      LoginProvider.wechat => '微信用户',
      LoginProvider.apple => 'Apple 用户',
      LoginProvider.phone => _phoneNickname(submission.phone),
      LoginProvider.email => _emailNickname(
        email: submission.email,
        nickname: submission.nickname,
      ),
    };

    return AppUser(
      nickname: nickname,
      avatarUrl: defaultAvatarUrls.first,
      memberPlan: 'free',
    );
  }

  @override
  Future<AppUser> changeMembership({
    required AppUser user,
    required String planId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!_validPlans.contains(planId)) {
      throw Exception('无效的会员方案');
    }

    return user.copyWith(memberPlan: planId);
  }

  String _phoneNickname(String? phone) {
    final String value = (phone ?? '').trim();
    if (value.length < 4) {
      return '学习者';
    }
    return '用户${value.substring(value.length - 4)}';
  }

  String _emailNickname({String? email, String? nickname}) {
    final String customNickname = (nickname ?? '').trim();
    if (customNickname.isNotEmpty) {
      return customNickname;
    }

    final String value = (email ?? '').trim();
    if (value.contains('@')) {
      return value.split('@').first;
    }
    return '学习者';
  }
}

class AppSession extends ChangeNotifier {
  AppSession({AppRepository? repository})
    : _repository = repository ?? DemoAppRepository();

  final AppRepository _repository;

  AppUser? _user;
  bool _isAuthenticating = false;
  bool _isUpdatingMembership = false;
  String? _authErrorMessage;
  String? _membershipErrorMessage;

  bool get isLoggedIn => _user != null;
  bool get isAuthenticating => _isAuthenticating;
  bool get isUpdatingMembership => _isUpdatingMembership;
  String? get authErrorMessage => _authErrorMessage;
  String? get membershipErrorMessage => _membershipErrorMessage;

  String get nickname => _user?.nickname ?? '学习者';
  String get avatarUrl => _user?.avatarUrl ?? defaultAvatarUrls.first;
  String get memberPlan => _user?.memberPlan ?? 'free';
  bool get isPro => memberPlan != 'free';

  Future<void> signIn(LoginSubmission submission) async {
    _isAuthenticating = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.signIn(submission);
    } catch (error) {
      _authErrorMessage = _messageFromError(error, fallback: '登录失败，请稍后重试');
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> changeMembership(String planId) async {
    final AppUser? currentUser = _user;
    if (currentUser == null) {
      _membershipErrorMessage = '请先登录';
      notifyListeners();
      return;
    }

    _isUpdatingMembership = true;
    _membershipErrorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.changeMembership(
        user: currentUser,
        planId: planId,
      );
    } catch (error) {
      _membershipErrorMessage = _messageFromError(
        error,
        fallback: '会员状态更新失败，请稍后重试',
      );
    } finally {
      _isUpdatingMembership = false;
      notifyListeners();
    }
  }

  void updateAvatar(String avatarUrl) {
    final AppUser? currentUser = _user;
    if (currentUser == null || currentUser.avatarUrl == avatarUrl) {
      return;
    }
    _user = currentUser.copyWith(avatarUrl: avatarUrl);
    notifyListeners();
  }

  void logout() {
    _user = null;
    _authErrorMessage = null;
    _membershipErrorMessage = null;
    notifyListeners();
  }

  String _messageFromError(Object error, {required String fallback}) {
    final String text = error.toString().trim();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text.isEmpty ? fallback : text;
  }
}

class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({
    super.key,
    required AppSession session,
    required super.child,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final AppSessionScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppSessionScope>();
    assert(scope != null, 'AppSessionScope not found in context');
    return scope!.notifier!;
  }
}
