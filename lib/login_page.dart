import 'dart:async';

import 'package:flutter/material.dart';

import 'app_models.dart';
import 'app_session.dart';

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

  String? _validate(LoginSubmission submission) {
    if (!_agreeTerms) {
      return '请先同意用户协议和隐私政策';
    }

    switch (submission.provider) {
      case LoginProvider.wechat:
      case LoginProvider.apple:
        return null;
      case LoginProvider.phone:
        if ((submission.phone ?? '').trim().length < 11) {
          return '请输入正确的手机号';
        }
        if ((submission.code ?? '').trim().length < 4) {
          return '请输入验证码';
        }
        return null;
      case LoginProvider.email:
        if (submission.isRegister &&
            (submission.nickname ?? '').trim().isEmpty) {
          return '请先设置昵称';
        }
        if (!(submission.email ?? '').contains('@')) {
          return '请输入正确的邮箱地址';
        }
        if ((submission.password ?? '').trim().length < 6) {
          return '密码至少 6 位';
        }
        return null;
    }
  }

  void _sendCode() {
    if (_phoneController.text.trim().length < 11 || _countdown > 0) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: appBackground,
      child: switch (_method) {
        LoginMethod.main => _buildMainView(),
        LoginMethod.phone => _buildPhoneView(),
        LoginMethod.email => _buildEmailView(),
      },
    );
  }

  Widget _buildMainView() {
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
              const Text(
                '让英语口语练习变得自然',
                textAlign: TextAlign.center,
                style: TextStyle(
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
          label: '微信登录',
          backgroundColor: const Color(0xFF07C160),
          icon: Icons.chat_bubble_rounded,
          onTap: widget.isLoading
              ? null
              : () => _submit(
                  const LoginSubmission(provider: LoginProvider.wechat),
                ),
        ),
        const SizedBox(height: 12),
        _PrimarySocialButton(
          label: 'Apple 登录',
          backgroundColor: Colors.black,
          icon: Icons.apple_rounded,
          onTap: widget.isLoading
              ? null
              : () => _submit(
                  const LoginSubmission(provider: LoginProvider.apple),
                ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE5E0D9))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '或',
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
          title: '手机号登录',
          subtitle: '验证码快速登录',
          onTap: widget.isLoading
              ? null
              : () => setState(() => _method = LoginMethod.phone),
        ),
        const SizedBox(height: 12),
        _MethodButton(
          icon: Icons.mail_outline_rounded,
          title: '邮箱登录',
          subtitle: '支持登录与注册',
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
            const Expanded(
              child: Text(
                '登录即表示你同意《用户协议》和《隐私政策》',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 54, 28, 28),
      children: [
        _BackHeader(
          title: '手机号登录',
          onTap: widget.isLoading
              ? null
              : () => setState(() => _method = LoginMethod.main),
        ),
        const SizedBox(height: 32),
        const Text(
          '欢迎回来',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '输入手机号和验证码继续',
          style: TextStyle(fontSize: 14, color: textSecondary),
        ),
        const SizedBox(height: 28),
        if (_errorMessage != null) ...[
          _ErrorBanner(message: _errorMessage!),
          const SizedBox(height: 16),
        ],
        _InputBlock(
          controller: _phoneController,
          hint: '输入手机号',
          icon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InputBlock(
                controller: _codeController,
                hint: '验证码',
                icon: Icons.verified_user_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              height: 54,
              child: FilledButton(
                onPressed: widget.isLoading ? null : _sendCode,
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
                      : (_codeSent ? '重新发送' : '发送验证码'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: widget.isLoading
              ? null
              : () => _submit(
                  LoginSubmission(
                    provider: LoginProvider.phone,
                    phone: _phoneController.text,
                    code: _codeController.text,
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
            widget.isLoading ? '登录中...' : '登录',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 54, 28, 28),
      children: [
        _BackHeader(
          title: _isRegister ? '邮箱注册' : '邮箱登录',
          onTap: widget.isLoading
              ? null
              : () => setState(() => _method = LoginMethod.main),
        ),
        const SizedBox(height: 32),
        Text(
          _isRegister ? '创建你的账号' : '邮箱登录',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRegister ? '用邮箱和密码注册 SpeakEasy' : '输入邮箱和密码继续',
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
            hint: '设置昵称',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
        ],
        _InputBlock(
          controller: _emailController,
          hint: '输入邮箱地址',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _InputBlock(
          controller: _passwordController,
          hint: _isRegister ? '设置密码' : '输入密码',
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
                ? (_isRegister ? '创建中...' : '登录中...')
                : (_isRegister ? '创建账号' : '登录'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.isLoading
              ? null
              : () => setState(() => _isRegister = !_isRegister),
          child: Text(
            _isRegister ? '已有账号，去登录' : '没有账号？先注册',
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
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF4C9C2)),
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
