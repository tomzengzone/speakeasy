import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:speakeasy/l10n/l10n.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  static const String _markdown = '''
# SpeakEasy 用户协议

最后更新：2026年3月25日

欢迎使用 SpeakEasy。在你注册、登录、购买会员或使用本应用提供的服务前，请认真阅读并理解本协议。你访问或使用 SpeakEasy，即视为你已阅读、理解并同意接受本协议的约束。

## 1. 服务条款

- SpeakEasy 为用户提供英语学习、场景练习、语音互动、AI 辅助表达训练及相关配套服务。
- 你应当以真实、合法、有效的方式注册和使用账号，并妥善保管登录凭证。
- 你不得利用本服务从事违法违规、侵犯他人权益、干扰系统安全或破坏平台正常运营的行为。
- 如你违反法律法规、本协议或平台规则，我们有权视情况采取限制功能、暂停服务、终止账号使用等措施。

## 2. 会员订阅条款

- SpeakEasy 可能提供免费功能与付费会员服务，具体权益、价格、周期与展示页面说明为准。
- 你购买会员后，可在订阅有效期内使用相应的会员权益；部分权益可能因网络、地区、设备或功能迭代存在差异。
- 如订阅服务由 Apple App Store、Google Play 或其他第三方支付渠道提供，扣费、续费、取消订阅与退款规则将同时受到对应平台规则约束。
- 如你开通自动续费，在未主动取消的情况下，系统可能按订阅周期自动扣费。你应自行在对应支付平台管理续费设置。
- 已经生效的订阅服务，除法律法规另有规定或支付平台规则另有要求外，通常不支持按未使用时长进行折算退款。

## 3. 知识产权

- SpeakEasy 应用软件、界面设计、课程内容、文案、图形、标识及相关技术成果的知识产权归我们或相关权利人所有。
- 未经书面许可，你不得对应用内容进行复制、传播、改编、反向工程、出租、出售或用于其他商业用途。
- 你通过本服务上传、提交或发布的内容，其合法权利仍归你或原权利人所有；但你同意授予我们在提供服务所必需范围内进行存储、处理、展示与分析的非独占许可。

## 4. 免责声明

- SpeakEasy 提供的学习建议、AI 生成内容、口语反馈与练习结果仅作为语言学习参考，不构成任何专业认证、考试承诺或其他保证。
- 我们会尽力保障服务稳定，但不对因网络波动、设备兼容性、第三方服务异常、不可抗力或系统维护导致的中断、延迟、数据缺失承担绝对责任。
- 对于你因自身操作、账号保管不当、超出合理使用范围或违反本协议造成的损失，应由你自行承担相应责任。

## 5. 争议解决

- 本协议的订立、生效、解释、履行及争议解决，适用中华人民共和国法律。
- 因本协议或本服务引起的任何争议，双方应优先友好协商解决。
- 协商不成的，任一方有权向 SpeakEasy 运营主体所在地有管辖权的人民法院提起诉讼。

如你对本协议有疑问，可联系：contact@speakeasy.app
''';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.termsOfService)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.18 : 0.06,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Markdown(
                  data: _markdown,
                  selectable: true,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  physics: const BouncingScrollPhysics(),
                  styleSheet: _buildStyleSheet(theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(ThemeData theme) {
    final ColorScheme colorScheme = theme.colorScheme;
    final MarkdownStyleSheet base = MarkdownStyleSheet.fromTheme(theme);
    return base.copyWith(
      h1: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      p: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        height: 1.8,
      ),
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        height: 1.8,
      ),
      strong: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      blockSpacing: 16,
    );
  }
}
