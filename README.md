# 社交塔子 (Relation App Mini)

> 你的智能社交搭子助手

## 功能特性

### 📇 联系人管理
- 支持多种联系方式（微信、QQ、手机、邮箱等）
- 联系人分层管理（不重要、一般、重要、核心）
- 自定义标签分类
- 互动记录追踪

### 🤖 AI智能助手
- **内部AI对话**：支持多种AI模型（OpenAI、Claude、通义千问等）
- **外部AI交互**：通过PDF导出与千问、豆包等AI交互
- **多模型配置**：可自定义API地址和密钥

### 🏷️ 分层管理
- 按重要程度分层管理联系人
- 不同层级设置不同的联系频率

### 🌟 氛围营造
- 设置向特定联系人展示的信息
- 保护隐私，控制信息暴露范围

### 🎯 目标关系
- 为每个联系人设定目标关系
- AI根据目标自动生成社交任务

### 📈 关系跟踪（升迁）
- 记录每次关系层级变更（升迁/降级/手动调整），形成关系演进时间线
- 联系人详情「关系」Tab 展示当前进度（不重要→一般→重要→核心）与变更历史
- 首页「关系升迁动态」全局跟踪视图，快速查看最近的关系变化
- 调整层级时可填写变更原因（如：完成3次深度交流），自动判定升迁/降级类型

### 📋 动态任务系统
- AI自动生成社交任务计划
- 任务提醒和进度追踪
- 支持多种任务类型（发消息、问候、打电话等）

### 🔄 应用更新
- 支持应用内自动更新
- 从GitHub Release自动检测最新版本

## 技术栈

- **Flutter 3.47.0**
- **Dart 3.5.0**
- **Provider** 状态管理
- **Dio** 网络请求
- **sqflite** 本地数据库
- **printing/pdf** PDF生成
- **flutter_local_notifications** 通知

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── core/
│   ├── providers/              # 状态管理
│   │   ├── app_provider.dart
│   │   ├── contact_provider.dart
│   │   ├── task_provider.dart
│   │   ├── ai_provider.dart
│   │   └── atmosphere_provider.dart
│   └── utils/
│       ├── app_update_service.dart   # 应用更新服务
│       └── pdf_exporter.dart         # PDF导出服务
├── models/
│   ├── contact.dart           # 联系人模型
│   ├── task.dart               # 任务模型
│   ├── ai_config.dart          # AI配置模型
│   └── atmosphere.dart         # 氛围配置模型
├── services/
│   ├── storage_service.dart     # 数据库服务
│   ├── notification_service.dart # 通知服务
│   ├── ai_service.dart          # AI服务
│   └── task_generator_service.dart # 任务生成服务
└── ui/
    ├── pages/                  # 页面
    └── widgets/                # 组件
```

## 安装依赖

```bash
flutter pub get
```

## 运行应用

```bash
# Debug模式
flutter run

# Release模式
flutter build apk --release
```

## CI/CD

本项目使用GitHub Actions进行自动化构建和发布：

- 推送tag时自动构建并发布Release APK
- 支持手动触发构建（debug/release）
- 自动签名（需要配置secrets）

### 配置签名密钥

在GitHub仓库的Settings > Secrets中添加：

- `ANDROID_KEYSTORE_B64`: Base64编码的keystore文件
- `ANDROID_KEY_ALIAS`: Key alias
- `ANDROID_KEY_PASSWORD`: Key密码
- `ANDROID_STORE_PASSWORD`: Store密码

## License

MIT License
