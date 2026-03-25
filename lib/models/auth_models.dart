import 'package:speakeasy/config/payment_config.dart';

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
    this.onboardingDone = false,
  });

  final String nickname;
  final String avatarUrl;
  final String memberPlan;
  final bool onboardingDone;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      nickname: (json['nickname'] as String?)?.trim().isNotEmpty == true
          ? (json['nickname'] as String).trim()
          : '用户',
      avatarUrl:
          (json['avatarUrl'] as String?) ?? (json['avatar'] as String?) ?? '',
      memberPlan: PaymentConfig.normalizePlanId(
        (json['memberPlan'] as String?) ?? (json['plan'] as String?),
      ),
      onboardingDone: json['onboardingDone'] as bool? ?? false,
    );
  }

  AppUser copyWith({
    String? nickname,
    String? avatarUrl,
    String? memberPlan,
    bool? onboardingDone,
  }) {
    return AppUser(
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberPlan: memberPlan ?? this.memberPlan,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}
