import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:speakeasy/l10n/l10n.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const String _markdown = '''
# SpeakEasy 隐私政策

最后更新：2026年3月25日

欢迎使用 SpeakEasy。我们重视你的个人信息与数据安全。本隐私政策用于说明我们在你使用 SpeakEasy 产品与服务过程中，如何收集、使用、存储、保护你的信息，以及你可以如何管理自己的数据。

## 1. 数据收集

### 1.1 用户信息

我们可能收集你在注册、登录或完善资料时主动提供的信息，包括但不限于：

- 手机号、邮箱地址、昵称、头像等账号信息
- 登录状态、设备标识、基础网络信息与应用版本信息
- 你与我们客服沟通时主动提交的反馈内容

### 1.2 学习数据

为了向你提供个性化英语学习服务，我们可能收集和记录：

- 学习目标、等级、每日学习时长等偏好设置
- 课程进度、练习记录、收藏内容、会员状态与订阅信息
- 你在对话练习、题目作答、场景训练中的输入内容与学习结果

### 1.3 语音数据

当你使用语音练习、跟读、口语评测或 AI 对话能力时，我们可能处理：

- 你主动录制并提交的语音内容
- 由语音内容生成的转写文本、发音分析结果与评分结果
- 为改进交互体验所需的语音处理元数据，例如时长、失败状态和调用日志

## 2. 数据使用方式

我们收集和处理上述信息，主要用于以下目的：

- 完成账号注册、登录验证、身份识别与账号安全保障
- 提供课程学习、练习记录、进度同步、会员服务等核心功能
- 生成个性化学习建议、学习反馈、口语纠错与内容推荐
- 优化产品性能、排查故障、分析异常、预防欺诈与滥用行为
- 在符合法律法规要求的前提下，履行运营管理、审计、合规与安全义务

除非法律法规另有要求或经你明确授权，我们不会将你的个人信息出售给第三方。

## 3. 第三方服务

为提供 AI 对话、文本生成、语音分析、登录、支付、崩溃诊断或学习反馈等能力，我们可能会使用第三方技术服务，包括但不限于：

- 阿里云 / DashScope 等 AI 与语音能力服务
- Apple 登录与 App Store 订阅服务
- 微信登录服务
- Sentry 等崩溃诊断服务

在你使用相关功能时，我们可能向上述服务传输为完成请求所必需的数据，例如：

- 你主动提交的文本、语音内容或语音转写文本
- 与当前学习任务相关的上下文、评分结果和错误状态
- 账号登录凭证、订阅交易凭证、设备与应用版本等必要信息

我们会尽量遵循最小必要原则，仅传输完成当前功能所需的信息。第三方服务提供方将依据其自身规则处理相关数据，你也可以关注其公开政策了解更多信息。

## 4. 数据存储与安全

我们会采取合理、必要的技术与管理措施保护你的信息安全，包括但不限于：

- 采用访问控制、身份校验和日志审计机制限制数据访问范围
- 对敏感信息传输过程采取加密或安全通道保护
- 根据业务需要设置存储期限，并在超出必要期限后删除或匿名化处理相关数据

尽管如此，任何互联网传输或电子存储方式都无法保证绝对安全。如发生可能影响你权益的安全事件，我们将依据适用法律法规及时进行告知与处置。

## 5. 用户权利

在适用法律法规允许的范围内，你有权：

- 访问、查询或更新你的账号信息与部分学习数据
- 通过应用内「我的 - 帮助与支持 - 注销账号」申请删除账号，或删除与你账号相关的部分数据
- 撤回你此前作出的授权同意，但撤回不影响撤回前基于授权开展的处理活动
- 对个人信息处理规则提出意见、投诉或寻求解释

你也可以通过应用内功能或联系邮箱向我们提交相关请求。为保障账号安全，我们可能在处理前要求你完成必要的身份核验。

## 6. 联系方式

如你对本隐私政策有任何疑问、意见或投诉，可通过以下方式联系我们：

- 邮箱：contact@speakeasy.app

我们会在合理期限内予以回复。
''';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyPolicy)),
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
      h3: theme.textTheme.titleMedium?.copyWith(
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
