# 🌌 Locus - Personal Multimodal Local Hub

> *"Your data. Your rules. Your local intelligence."*

Locus 是一个基于 **Local-First（本地优先）** 理念打造的多模态私人助理与轻量化数字网关。它不仅仅是一个记事本，而是一个具备双模态交互（流式输入 + RAG 对话）、端到端加密、以及高可扩展插件架构的纯私人数字底座。

---

## 🎯 核心愿景 (Core Vision)

在云端大厂垄断个人数据的今天，Locus 旨在重新夺回数据的控制权。

系统将作为第一触点截获你的灵感、账单、会议纪要与图像，通过本地预处理与意图识别后，安全地路由到本地加密沙箱，或异步同步至私有云服务器。

---

## ✨ 核心特性 (Key Features)

### 📱 双模交互 (Dual-Mode UI)

- **极速闪念流 (Timeline)**：像发微信一样，毫秒级无感录入文本与多媒体。
- **智能对话窗 (AI Chat)**：向右滑动即刻唤醒专属 AI，支持结合本地记忆库的深度交流。

### 🔒 绝对隐私 (Military-Grade Encryption)

- 底层采用 Drift + SQLCipher，本地数据库文件进行 AES-256 全盘物理加密。
- 无需网络，完全脱机可用。

### 🔌 热插拔架构 (Plugin-based Architecture)

- 基于依赖注入（DI），业务模块（财务看盘、Twenty CRM 推送）全部解耦。
- 一键开启或卸载，保持核心代码极致轻量。

### 🧠 渐进式 AI 引擎 (Progressive AI Routing)

- **目前**：轻量级本地正则意图捕捉 + 远端 API 大模型（DeepSeek / Claude）。
- **未来**：无缝替换接入本地 C/C++ FFI（如 llama.cpp），在手机和低配 PC 端本地运行微调小模型。

---

## 🛠️ 技术栈 (Tech Stack)

| 模块 | 技术选型 |
|------|----------|
| **前端框架** | Flutter（纯 Dart 编译，无痛跨平台 Windows / Android / iOS / macOS） |
| **本地金库** | Drift（强类型响应式 SQL）+ sqlcipher_flutter_libs |
| **依赖注入** | GetIt（实现模块解耦与热插拔） |
| **云端同步** | PocketBase（开源的单文件实时后端，部署于私人 NAS / VPS） |

---

## 🧰 开发环境固化

- Flutter SDK 根目录固定为 `D:\flutter`
- Android SDK 根目录固定为 `D:\AndroidSDK`
- 已接入 `zvec 0.5.2`，当前要求 `Dart 3.11.3+`，建议使用 `Flutter 3.41.9+`
- 后续开发、脚本与 AI 协作处理 Flutter / Android 工具链问题时，默认只检查 `D:\flutter` 与 `D:\AndroidSDK`，不要擅自把 SDK 根目录切到 `C:\Users\...`
- 仓库内可直接使用 `scripts/use_locus_dev_env.ps1` 切换当前终端到项目约定环境
- 详细说明见 [docs/development_environment.md](file:///e:/Dev/Locus/docs/development_environment.md)

---

## 🗺️ 开发路线图 (Roadmap)

### Phase 1：核心基座搭建

- [ ] 初始化插件化目录结构与 GetIt 依赖注入引擎
- [ ] 部署 Drift 加密数据库，定义 HubPayloads 核心载荷表

### Phase 2：流式输入与本地网关

- [ ] 开发极简悬浮输入框，集成图片 / 语音轻量级压缩
- [ ] 开发本地规则分发器，实现本地静默打标与极速入库
- [ ] 跑通 PocketBase 双向实时同步（WebSocket）

### Phase 3：双擎 AI 与智能调度

- [ ] 搭建 Chat UI 与 Markdown 渲染组件
- [ ] 实现基础 API 调用与本地意图路由派单

### Phase 4：记忆觉醒 (Local RAG)

- [ ] 建立纯 Dart 本地余弦相似度计算函数
- [ ] 闪念流文本切片、向量化存储与上下文唤醒

### Phase 5：商业级网关扩展

- [ ] 研发财务账本聚合插件
- [ ] 研发 Twenty CRM 异步推送插件

---

## 🚀 快速启动 (Getting Started)

1. 确认 Flutter SDK 指向 `D:\flutter` 下满足版本要求的安装
2. 确认 Android SDK 位于 `D:\AndroidSDK`
3. 执行：

```powershell
. .\scripts\use_locus_dev_env.ps1
flutter --version
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run
```
