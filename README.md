# SpeakEasy AI

![Flutter](https://img.shields.io/badge/Flutter-%5E3.10.7-02569B?logo=flutter&logoColor=white)

SpeakEasy AI 是一款面向英语口语训练场景的 Flutter App，聚焦 AI 陪练、语音反馈与循序渐进的学习体验，帮助用户在真实对话中提升英语表达能力。

## 项目简介

本项目提供从登录、引导、学习到 AI 场景对话与会员订阅的完整口语练习流程，适用于移动端英语学习产品的快速开发与迭代。

## 功能截图

> 截图占位：可在此处补充登录页、学习页、AI 对话页、会员页等核心界面截图。

| 页面 | 截图 |
| --- | --- |
| 登录认证 | `TODO` |
| 新手引导 | `TODO` |
| 学习模块 | `TODO` |
| AI 场景对话 | `TODO` |
| 个人中心 / 会员订阅 | `TODO` |

## 技术栈

- Flutter
- Dart
- OpenAI GPT-4o-mini
- Shared Preferences
- In-App Purchase
- Sign in with Apple / 微信登录
- Sentry

## 主要功能

- 登录认证：支持 Apple 登录、微信登录等身份认证能力
- 新手引导：提供首次使用的引导流程，帮助用户快速进入学习状态
- 学习模块：内置学习内容、课程详情与表达卡片等模块
- AI 场景对话：结合大模型进行多场景英语口语互动练习
- 语音评分：支持录音、播放与语音表现反馈
- 个人中心：支持资料编辑、学习统计与账户管理
- 会员订阅：提供应用内订阅与会员权益管理
- 深色模式：支持夜间主题与多平台样式适配
- 通知与缓存：支持本地通知、资源缓存与基础性能优化

## 项目结构

```text
speakeasy/
├── lib/
│   ├── config/           # 应用配置、支付配置、社交配置、Sentry 配置
│   ├── models/           # 数据模型
│   ├── pages/            # 隐私政策、服务条款等独立页面
│   ├── services/         # 登录、支付、统计等服务层
│   ├── utils/            # 错误处理、图片缓存等工具类
│   ├── main.dart         # 应用入口
│   ├── login_page.dart   # 登录页
│   ├── onboarding_page.dart
│   ├── home_page.dart
│   ├── learning_page.dart
│   ├── scene_page.dart
│   ├── membership_page.dart
│   └── profile_page.dart
├── assets/
│   ├── data/             # 静态学习数据
│   └── icon/             # 应用图标资源
├── android/              # Android 平台工程
├── ios/                  # iOS 平台工程
├── macos/                # macOS 平台工程
├── web/                  # Web 平台资源
├── windows/              # Windows 平台工程
├── linux/                # Linux 平台工程
├── .env.example          # 环境变量示例
└── pubspec.yaml          # Flutter 依赖与工程配置
```

## 开发环境要求

- Flutter SDK: `^3.10.7`
- Dart SDK: 随 Flutter SDK 安装
- Xcode / Android Studio：用于 iOS / Android 平台构建
- CocoaPods：iOS 依赖管理

## 快速开始

### 1. 克隆项目

```bash
git clone <your-repository-url>
cd speakeasy
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 配置环境变量

参考 `.env.example` 创建本地环境配置文件：

```bash
cp .env.example .env
```

按需填写以下配置：

```env
API_BASE_URL=
OPENAI_API_KEY=
ENV=
```

### 4. 运行项目

```bash
flutter run
```

如果需要指定设备，可先执行：

```bash
flutter devices
flutter run -d <device-id>
```

## 构建说明

### Android

```bash
flutter build apk
```

或构建 App Bundle：

```bash
flutter build appbundle
```

### iOS

```bash
flutter build ios
```

### Web

```bash
flutter build web
```

### macOS

```bash
flutter build macos
```

## 许可证

`TODO`：请在此处补充项目许可证信息，例如 MIT、Apache-2.0 或私有许可证说明。
