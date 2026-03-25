import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as apple_sign_in;

import 'api_client.dart';
import 'app_models.dart';
import 'app_session.dart';
import 'l10n/l10n.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/terms_of_service_page.dart';
import 'services/wechat_auth_service.dart';

enum LoginMethod { main, phone, email }

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onSubmit,
    required this.isLoading,
    this.errorMessage,
    this.onClose,
  });

  final Future<void> Function(LoginSubmission submission) onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onClose;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginMethod _method = LoginMethod.main;
  bool _showPassword = false;
  bool _isRegister = false;
  bool _agreeTerms = false;
  bool _codeSent = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  Timer? _timer;
  String? _localErrorMessage;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? get _errorMessage => _localErrorMessage ?? widget.errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(LoginSubmission submission) async {
    final String? validationError = _validate(submission);
    if (validationError != null) {
      setState(() {
        _localErrorMessage = validationError;
      });
      return;
    }

    setState(() {
      _localErrorMessage = null;
    });

    await widget.onSubmit(submission);
  }

  Future<void> _submitAppleLogin() async {
    const LoginSubmission submission = LoginSubmission(
      provider: LoginProvider.apple,
    );
    final String? validationError = _validate(submission);
    if (validationError != null) {
      setState(() {
        _localErrorMessage = validationError;
      });
      return;
    }

    setState(() {
      _localErrorMessage = null;
    });

    await AppSessionScope.of(context).signInWithApple();
  }

  Future<void> _submitWeChatLogin() async {
    const LoginSubmission submission = LoginSubmission(
      provider: LoginProvider.wechat,
    );
    final String? validationError = _validate(submission);
    if (validationError != null) {
      setState(() {
        _localErrorMessage = validationError;
      });
      return;
    }

    setState(() {
      _localErrorMessage = null;
    });

    await AppSessionScope.of(
      context,
    ).signInWithWeChat(service: WeChatAuthService.instance);
  }

  String? _validate(LoginSubmission submission) {
    final AppLocalizations l10n = context.l10n;
    if (!_agreeTerms) {
      return l10n.pleaseAgreeTerms;
    }

    switch (submission.provider) {
      case LoginProvider.wechat:
      case LoginProvider.apple:
        return null;
      case LoginProvider.phone:
        if ((submission.phone ?? '').trim().length < 11) {
          return l10n.enterValidPhoneNumber;
        }
        if ((submission.code ?? '').trim().length < 4) {
          return l10n.enterVerificationCode;
        }
        return null;
      case LoginProvider.email:
        if (submission.isRegister &&
            (submission.nickname ?? '').trim().isEmpty) {
          return l10n.setNicknameFirst;
        }
        if (!(submission.email ?? '').contains('@')) {
          return l10n.enterValidEmailAddress;
        }
        if ((submission.password ?? '').trim().length < 6) {
          return l10n.passwordMinLength;
        }
        return null;
    }
  }

  Future<void> _sendCode() async {
    final String phone = _phoneController.text.trim();
    final AppLocalizations l10n = context.l10n;
    if (phone.length < 11 || _countdown > 0 || _isSendingCode) {
      if (phone.length < 11) {
        setState(() {
          _localErrorMessage = l10n.enterValidPhoneNumber;
        });
      }
      return;
    }

    setState(() {
      _isSendingCode = true;
      _localErrorMessage = null;
    });

    try {
      final Map<String, dynamic> res = await ApiClient.sendSmsCode(phone);
      if (res['code'] != 0) {
        throw Exception(res['message'] ?? l10n.verificationCodeSendFailed);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _codeSent = true;
        _countdown = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (_countdown <= 1) {
          timer.cancel();
          setState(() {
            _countdown = 0;
          });
          return;
        }
        setState(() {
          _countdown -= 1;
        });
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localErrorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  Future<void> _submitPhoneLogin() async {
    final LoginSubmission submission = LoginSubmission(
      provider: LoginProvider.phone,
      phone: _phoneController.text,
      code: _codeController.text,
    );
    final String? validationError = _validate(submission);
    if (validationError != null) {
      setState(() {
        _localErrorMessage = validationError;
      });
      return;
    }

    setState(() {
      _localErrorMessage = null;
    });

    await AppSessionScope.of(context).signInWithCode(
      phone: submission.phone ?? '',
      code: submission.code ?? '',
    );
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const PrivacyPolicyPage(),
      ),
    );
  }

  void _openTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const TermsOfServicePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: appBackground,
      child: switch (_method) {
        LoginMethod.main => _buildMainView(),
        LoginMethod.phone => _buildPhoneView(),
        LoginMethod.email => _buildEmailView(),
      },
    );
  }

  Widget _buildMainView() {
    final AppLocalizations l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      children: [
        if (widget.onClose != null)
          Padding(
            padding: const EdgeInsets.only(top: 54),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: widget.isLoading ? null : widget.onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: textTertiary,
                ),
              ),
            ),
          )
        else
          const SizedBox(height: 90),
        Padding(
          padding: EdgeInsets.only(
            top: widget.onClose == null ? 0 : 24,
            bottom: 48,
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2E4A2C),
                      Color(0xFF4A7244),
                      Color(0xFF87B076),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D4A7244),
                      blurRadius: 32,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🗣️', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SpeakEasy',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          _ErrorBanner(message: _errorMessage!),
          const SizedBox(height: 16),
        ],
        _PrimarySocialButton(
          label: widget.isLoading ? l10n.wechatLoggingIn : l10n.wechatLogin,
          backgroundColor: const Color(0xFF07C160),
          icon: Icons.chat_bubble_rounded,
          onTap: widget.isLoading ? null : _submitWeChatLogin,
        ),
        const SizedBox(height: 12),
        _AppleSignInButton(onTap: widget.isLoading ? null : _submitAppleLogin),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE5E0D9))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                l10n.orText,
                style: TextStyle(
                  fontSize: 12,
                  color: textTertiary.withValues(alpha: 0.9),
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE5E0D9))),
          ],
        ),
        const SizedBox(height: 22),
        _MethodButton(
          icon: Icons.phone_iphone_rounded,
          title: l10n.phoneLogin,
          subtitle: l10n.phoneLoginSubtitle,
          onTap: widget.isLoading
              ? null
              : () => setState(() => _method = LoginMethod.phone),
        ),
        const SizedBox(height: 12),
        _MethodButton(
          icon: Icons.mail_outline_rounded,
          title: l10n.emailLogin,
          subtitle: l10n.emailLoginSubtitle,
          onTap: widget.isLoading
              ? null
              : () => setState(() => _method = LoginMethod.email),
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.isLoading
                  ? null
                  : () => setState(() => _agreeTerms = !_agreeTerms),
              child: Container(
                margin: const EdgeInsets.only(top: 1),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _agreeTerms ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: _agreeTerms ? primaryGreen : const Color(0xFFD5CFC6),
                  ),
                ),
                child: _agreeTerms
                    ? const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                children: [
                  Text(
                    l10n.agreementPrefix,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                  _AgreementLink(
                    label: '《${l10n.termsOfService}》',
                    onTap: widget.isLoading ? null : _openTermsOfService,
                  ),
                  Text(
                    l10n.andText,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                  _AgreementLink(
                    label: '《${l10n.privacyPolicy}》',
                    onTap: widget.isLoading ? null : _openPrivacyPolicy,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneView() {
    final AppLocalizations l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 54, 28, 28),
      children: [
        _BackHeader(
          title: l10n.phoneLogin,
          onTap: widget.isLoading
              ? null
              : () => setState(() => _method = LoginMethod.main),
        ),
        const SizedBox(height: 32),
        Text(
          l10n.welcomeBack,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.phoneLoginContinue,
          style: TextStyle(fontSize: 14, color: textSecondary),
        ),
        const SizedBox(height: 28),
        if (_errorMessage != null) ...[
          _ErrorBanner(message: _errorMessage!),
          const SizedBox(height: 16),
        ],
        _InputBlock(
          controller: _phoneController,
          hint: l10n.enterPhoneNumber,
          icon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InputBlock(
                controller: _codeController,
                hint: l10n.verificationCode,
                icon: Icons.verified_user_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              height: 54,
              child: FilledButton(
                onPressed: widget.isLoading || _isSendingCode
                    ? null
                    : _sendCode,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE9F3EF),
                  foregroundColor: primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _countdown > 0
                      ? '${_countdown}s'
                      : _isSendingCode
                      ? l10n.sending
                      : (_codeSent ? l10n.resend : l10n.sendVerificationCode),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: widget.isLoading ? null : _submitPhoneLogin,
          style: FilledButton.styleFrom(
            backgroundColor: primaryGreen,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            widget.isLoading ? l10n.loggingIn : l10n.login,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailView() {
    final AppLocalizations l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 54, 28, 28),
      children: [
        _BackHeader(
          title: _isRegister ? l10n.emailRegister : l10n.emailLogin,
          onTap: widget.isLoading
              ? null
              : () => setState(() => _method = LoginMethod.main),
        ),
        const SizedBox(height: 32),
        Text(
          _isRegister ? l10n.createYourAccount : l10n.emailLogin,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRegister
              ? l10n.registerWithEmailSubtitle
              : l10n.loginWithEmailSubtitle,
          style: const TextStyle(fontSize: 14, color: textSecondary),
        ),
        const SizedBox(height: 28),
        if (_errorMessage != null) ...[
          _ErrorBanner(message: _errorMessage!),
          const SizedBox(height: 16),
        ],
        if (_isRegister) ...[
          _InputBlock(
            controller: _nicknameController,
            hint: l10n.setNickname,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
        ],
        _InputBlock(
          controller: _emailController,
          hint: l10n.inputEmailAddress,
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _InputBlock(
          controller: _passwordController,
          hint: _isRegister ? l10n.setPassword : l10n.inputPassword,
          icon: Icons.lock_outline_rounded,
          obscureText: !_showPassword,
          trailing: IconButton(
            onPressed: widget.isLoading
                ? null
                : () => setState(() => _showPassword = !_showPassword),
            icon: Icon(
              _showPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: textTertiary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: widget.isLoading
              ? null
              : () => _submit(
                  LoginSubmission(
                    provider: LoginProvider.email,
                    email: _emailController.text,
                    password: _passwordController.text,
                    nickname: _nicknameController.text,
                    isRegister: _isRegister,
                  ),
                ),
          style: FilledButton.styleFrom(
            backgroundColor: primaryGreen,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            widget.isLoading
                ? (_isRegister ? l10n.creating : l10n.loggingIn)
                : (_isRegister ? l10n.createAccount : l10n.login),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.isLoading
              ? null
              : () => setState(() => _isRegister = !_isRegister),
          child: Text(
            _isRegister ? l10n.haveAccountGoLogin : l10n.noAccountRegisterFirst,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.title, required this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _PrimarySocialButton extends StatelessWidget {
  const _PrimarySocialButton({
    required this.label,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveBackgroundColor = onTap == null
        ? backgroundColor.withValues(alpha: isDark ? 0.55 : 0.7)
        : backgroundColor;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? <BoxShadow>[
                  BoxShadow(
                    color: effectiveBackgroundColor.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: FilledButton.icon(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: effectiveBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: isDark
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
                  : BorderSide.none,
            ),
            elevation: 0,
          ),
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.12))
            : null,
        boxShadow: isDark
            ? const <BoxShadow>[]
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: apple_sign_in.SignInWithAppleButton(
            onPressed: onTap,
            text: 'Sign in with Apple',
            height: 54,
            style: apple_sign_in.SignInWithAppleButtonStyle.black,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            iconAlignment: apple_sign_in.IconAlignment.left,
          ),
        ),
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE7E1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF2EFE9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreementLink extends StatelessWidget {
  const _AgreementLink({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: onTap == null ? textSecondary : primaryGreen,
        ),
      ),
    );
  }
}

class _InputBlock extends StatelessWidget {
  const _InputBlock({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E0D8)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: textTertiary),
          prefixIcon: Icon(icon, size: 20, color: textTertiary),
          suffixIcon: trailing,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF412726) : const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF7F4A4A) : const Color(0xFFF4C9C2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Color(0xFFD46B6B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9D4C4C),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
