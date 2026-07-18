# Locus 项目进展总结报告

> **编制日期**：2026-07-18  
> **当前版本**：v0.1.0  
> **报告范围**：项目启动至今的全量开发进展、技术现状与后续规划

---

## 目录

1. [项目初始开发思想与预设目标](#1-项目初始开发思想与预设目标)
2. [开发规范与实施原则](#2-开发规范与实施原则)
3. [当前技术实现详情](#3-当前技术实现详情)
4. [开发工作总结与里程碑](#4-开发工作总结与里程碑)
5. [后续开发排期与实施路径](#5-后续开发排期与实施路径)
6. [潜在风险、技术疑问与优化建议](#6-潜在风险技术疑问与优化建议)

---

## 1. 项目初始开发思想与预设目标

### 1.1 核心开发理念

**定位**：Locus 是一个基于 **Local-First（本地优先）** 理念打造的纯私人综合全能型 AI 智能助理。核心理念是"你的数据，你的规则，你的本地智能"（Your data. Your rules. Your local intelligence.）。

项目并非一个单纯的聊天应用，而是集成了**智能笔记、日程待办、客户关系管理、合同管理、知识积累、记账以及打卡功能**的高效个人管理系统。在云端大厂垄断个人数据的当下，Locus 旨在重新夺回数据控制权——所有数据优先存储于本地加密沙箱，仅在必要时通过异步通道同步至私有服务器。

**关键设计哲学**：

| 维度 | 理念 |
|------|------|
| **数据主权** | 本地数据库 AES-256 全盘加密，用户完全掌控数据所有权 |
| **双模交互** | 极速闪念流（无感录入）+ 智能对话窗（RAG 深度对话） |
| **渐进式 AI** | 当前为本地正则 + 云端 API 混合路由，未来可接入本地 C/C++ FFI 小模型 |
| **插件化架构** | 核心模块（闪念、日历、AI 枢纽、设置）不可移除；可选插件可动态增删 |
| **响应式设计** | 手机 / 平板 / PC 三阶分流，Material 3 原生适配 |

### 1.2 预设达成目标

根据 [README-CN.md](file:///e:/Dev/Locus/README-CN.md) 中定义的开发路线图，原始规划分为五个阶段：

| 阶段 | 目标内容 | 当前完成度 |
|------|----------|------------|
| **Phase 1: 核心基座** | 插件化目录结构 + GetIt DI 引擎 + Drift 加密数据库 + HubPayloads 核心表 | ✅ 已完成 |
| **Phase 2: 流式输入与本地网关** | 极简悬浮输入框 + 图片/语音轻量压缩 + 本地规则分发器 + PocketBase 双向同步 | 🟡 输入框已完成，本地分发已完成，PocketBase 同步未启动 |
| **Phase 3: 双擎 AI 与智能调度** | Chat UI + Markdown 渲染 + API 调用 + 本地意图路由派单 | ✅ 已完成 |
| **Phase 4: 记忆觉醒 (Local RAG)** | 纯 Dart 余弦相似度计算 + 文本切片 + 向量化存储 + 上下文唤醒 | ✅ 已完成（基于 zvec） |
| **Phase 5: 商业级网关扩展** | 财务账本聚合插件 + Twenty CRM 异步推送插件 | 🟡 财务/CRM 数据模型已完成，UI 与高级分析待完善 |

**量化达成情况**：原始五大阶段均已基本完成核心骨架搭建，14/15 个功能规范（specs）已落地，整体开发进度约 **70%**。

---

## 2. 开发规范与实施原则

### 2.1 代码规范体系

项目建立了完整的规范体系，核心总纲文件位于 [.trae/rules/开发总纲.md](file:///e:/Dev/Locus/.trae/rules/开发总纲.md)。

#### 命名规范

| 类别 | 规范 | 示例 |
|------|------|------|
| 目录/文件名 | `snake_case` | `locus_home_page.dart`, `idea_repository.dart` |
| 类名 | `UpperCamelCase` | `class LocusHomePage extends StatefulWidget` |
| 变量与方法 | `lowerCamelCase` | `_currentNavIndex`, `_openNewChat()` |
| 私有成员 | `_` 前缀 | `_selectedModel`, `_buildSmartCard()` |

#### 代码风格检查

通过 [analysis_options.yaml](file:///e:/Dev/Locus/analysis_options.yaml) 引入 `flutter_lints` 官方规范集：

```yaml
include: package:flutter_lints/flutter.yaml
```

### 2.2 技术选型标准

| 技术域 | 选型 | 版本 | 理由 |
|------|------|------|------|
| **框架** | Flutter | Dart 3.11.3+ | 全平台编译，单一代码库 |
| **数据库 ORM** | Drift | 2.21.0 | 强类型、响应式、编译期 SQL 验证 |
| **数据库加密** | SQLCipher | 0.6.8 | AES-256 本地物理文件加密 |
| **依赖注入** | GetIt | 9.2.1 | 轻量级，无代码生成，支持模块热插拔 |
| **向量计算** | zvec | 0.5.2 | 纯本地 HNSW 索引，1536 维向量 |
| **HTTP 客户端** | Dio | 5.9.2 | SSE 流式响应，拦截器链 |
| **AI API** | DeepSeek | deepseek-chat | 兼容 OpenAI 格式，性价比高 |
| **图表** | fl_chart | 0.68.0 | 纯 Dart，无原生依赖 |
| **PDF** | Syncfusion | 29.1.38 | 商业级 PDF 生成 |
| **状态管理** | StreamBuilder + ChangeNotifier | Flutter 原生 | 响应式数据流，无额外包依赖 |

### 2.3 架构设计核心原则

#### 分层架构（强制）

```
┌─────────────────────────────────────────┐
│  Presentation Layer (UI Widgets)         │  ← 仅负责渲染与事件转发
├─────────────────────────────────────────┤
│  Repository Layer (Data Access)          │  ← 封装所有数据库操作
├─────────────────────────────────────────┤
│  Service Layer (Business Logic)          │  ← AI 路由、分发、管线编排
├─────────────────────────────────────────┤
│  Database Layer (Drift + SQLCipher)      │  ← 21 张表、DAO、迁移
└─────────────────────────────────────────┘
```

**铁律**：Presentation 层严禁直接持有 `AppDatabase` 实例，必须通过 Repository 访问数据；`build` 方法中严禁包含数据库写入或复杂业务逻辑。

#### 响应式数据流

所有动态列表使用 `StreamBuilder` + `Stream<T>` 绑定数据库流，实现数据变动后 UI 自动刷新，严禁滥用全局 `setState`。

#### 插件化可插拔

- **核心模块**（不可移除）：闪念笔记（Idea Stream）、日程待办（Calendar）、AI 枢纽（AI Hub）、设置（Settings）
- **可选模块**（可自由增删）：记账（Ledger）、CRM、运动、习惯追踪、报价管理、产品选型
- 每个可选模块作为独立的 `features/<name>/` 目录存在，拥有自己的数据表、路由、导航入口和 DI 注册

#### 环境固化

- Flutter SDK：`D:\flutter`
- Android SDK：`D:\AndroidSDK`
- 禁止擅自使用 `C:\Users\...` 路径下的 SDK

---

## 3. 当前技术实现详情

### 3.1 项目目录结构

```
e:\Dev\Locus\
├── .trae/                          # AI 协同工作区（规则、文档、规范）
│   ├── documents/                  # 12 份设计计划文档
│   ├── rules/                      # 开发总纲
│   └── specs/                      # 15 个功能规范（spec/tasks/checklist）
├── android/                        # Android 原生平台
├── assets/icons/                   # 静态图标资源
├── ios/                            # iOS 原生平台
├── lib/
│   ├── core/                       # 核心基础层
│   │   ├── constants/              # 字段标签常量
│   │   ├── database/               # Drift 数据库定义（21 张表）+ 生成代码
│   │   ├── di/                     # GetIt 依赖注入注册
│   │   ├── enums/                  # BlockType / ProcessingStatus 枚举
│   │   ├── interfaces/             # BasePlugin / OCR 接口定义
│   │   ├── services/               # 11 个核心服务
│   │   ├── theme/                  # 设计系统（8 套配色 + 字体体系）
│   │   └── utils/                  # 数据匿名化 / 文档解析 / 意图路由
│   ├── features/                   # 功能模块（插件化）
│   │   ├── ai_hub/                 # AI 枢纽（核心模块）
│   │   ├── calendar/               # 日历（核心模块，占位）
│   │   ├── chat/                   # AI 聊天（RAG 对话）
│   │   ├── dashboard/              # 数据看板
│   │   ├── home/                   # 首页导航骨架
│   │   ├── idea_stream/            # 闪念笔记（核心模块）
│   │   ├── memory/                 # 长期记忆管理
│   │   ├── settings/               # 设置（核心模块）
│   │   └── timeline/               # 时间线视图
│   └── main.dart                   # 应用入口
├── linux/ / macos/ / web/ / windows/  # 各平台原生代码
├── scripts/                        # 辅助脚本
├── .env                            # LLM API 密钥配置
├── pubspec.yaml                    # 项目依赖
└── README-CN.md                    # 项目说明
```

### 3.2 部署与运行架构

**运行环境**：

| 项目 | 要求 |
|------|------|
| Flutter SDK | `D:\flutter`，Dart 3.11.3+，建议 Flutter 3.41.9+ |
| Android SDK | `D:\AndroidSDK` |
| 支持平台 | Android / iOS / Windows / macOS / Linux / Web |

**启动流程**：

```dart
main() → WidgetsFlutterBinding.ensureInitialized()
  → dotenv.load(fileName: ".env")          // 加载 API Keys
  → setupLocator()                          // 初始化 GetIt DI 容器（20 个服务）
  → runApp(LocusApp)                        // MaterialApp + 主题管理
    → LocusHomePage                        // 导航骨架（Tab 式导航）
```

### 3.3 核心功能页面清单

| 序号 | 页面名称 | 文件路径 | 功能状态 | 代码行数 |
|------|----------|----------|----------|----------|
| 1 | **LocusHomePage** | `lib/features/home/presentation/locus_home_page.dart` | ✅ 已完成 | ~800 行 |
| 2 | **IdeaStreamPage** | `lib/features/idea_stream/presentation/pages/idea_stream_page.dart` | ✅ 已完成 | ~1047 行 |
| 3 | **IdeaDetailPage** | `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` | ✅ 已完成 | ~4200 行 |
| 4 | **TagBrowserPage** | `lib/features/idea_stream/presentation/pages/tag_browser_page.dart` | ✅ 已完成 | ~245 行 |
| 5 | **TemplateManagementPage** | `lib/features/idea_stream/presentation/pages/template_management_page.dart` | ✅ 已完成 | ~249 行 |
| 6 | **ChatPage** | `lib/features/chat/presentation/chat_page.dart` | ✅ 已完成 | ~575 行 |
| 7 | **DashboardPage** | `lib/features/dashboard/presentation/pages/dashboard_page.dart` | ✅ 已完成 | ~934 行 |
| 8 | **CalendarPage** | `lib/features/calendar/presentation/pages/calendar_page.dart` | 🟡 占位 | ~30 行 |
| 9 | **AiHubPage** | `lib/features/ai_hub/presentation/pages/ai_hub_page.dart` | ✅ 代理 | ~10 行 |
| 10 | **SettingsPage** | `lib/features/settings/presentation/pages/settings_page.dart` | ✅ 已完成 | ~250 行 |
| 11 | **AiSettingsPage** | `lib/features/settings/presentation/pages/ai_settings_page.dart` | ✅ 已完成 | ~200 行 |
| 12 | **AppearanceSettingsPage** | `lib/features/settings/presentation/pages/appearance_settings_page.dart` | ✅ 已完成 | ~150 行 |
| 13 | **LongTermMemoryPage** | `lib/features/memory/presentation/long_term_memory_page.dart` | ✅ 已完成 | ~350 行 |
| 14 | **TimelinePage** | `lib/features/timeline/presentation/timeline_page.dart` | ✅ 已完成 | ~328 行 |
| 15 | **ChatHistorySearchPage** | `lib/features/chat/presentation/chat_history_search_page.dart` | ✅ 已完成 | ~200 行 |

**响应式导航说明**：

| 屏幕尺寸 | 导航方式 | 特性 |
|----------|----------|------|
| **小屏 (<600px)** | 底部 `NavigationBar`（5 个 Tab） + FAB 快捷输入 | 手机竖屏主模式 |
| **中屏 (600-960px)** | 左侧窄侧边栏 (70px 图标导航) + 内容区 | 平板 / 手机横屏 |
| **大屏 (>=960px)** | 左侧可折叠侧边栏 (70/220px) + 内容区 | PC 桌面端 |

### 3.4 全量路由配置

项目**不使用第三方路由包**（无 GoRouter、auto_route），采用极简路由方案：

**主导航**：基于 `_currentIndex` 的 Tab 式切换（不走 Navigator 栈），5 个顶层页面：
- 索引 0：`IdeaStreamPage`（闪念笔记）
- 索引 1：`CalendarPage`（日历）
- 索引 2：`AiHubPage`（AI 枢纽，代理到 ChatPage）
- 索引 3：`SettingsPage`（设置）
- 索引 4：`DashboardPage`（数据看板）

**二级页面**：通过 `Navigator.push(MaterialPageRoute(...))` 命令式导航：

| 源页面 | 目标页面 | 触发方式 |
|--------|----------|----------|
| ChatPage | `LongTermMemoryPage` | AppBar 按钮 |
| ChatPage | `ChatHistorySearchPage` | AppBar 按钮 |
| SettingsPage | `AiSettingsPage` | 列表项点击 |
| AiChatInputBox | `TemplateManagementPage` | @ 模板选择器入口 |

**弹窗式导航**：通过 `showModalBottomSheet` / `showDialog` 打开：
- `QuickInputBottomSheet`（FAB 快捷输入）
- `TagPicker`（标签选择器）
- `FullBlockEditor`（内容块全屏编辑器）
- `ExportBottomSheet`（导出选项）
- `ContentBlockEditor`（快速块编辑）
- 各类确认/编辑 Dialogs

### 3.5 数据库表结构设计

数据库引擎为 **SQLite + SQLCipher AES-256 加密**，当前 schemaVersion = 15。

#### 3.5.1 表清单（21 张表）

**核心业务表（15 张）**：

| 序号 | 表名（SQL） | Drift 类 | 主键 | 核心用途 |
|------|------------|----------|------|----------|
| 1 | `hub_payloads` | `HubPayloads` | id (AUTOINCREMENT) + uuid (UNIQUE) | 核心多模态路由载荷，系统枢纽表 |
| 2 | `chat_sessions` | `ChatSessions` | id (AUTOINCREMENT) | AI 对话会话（"记忆抽屉"） |
| 3 | `chat_messages` | `ChatMessages` | id (AUTOINCREMENT) | 会话消息明细（role/content） |
| 4 | `long_term_memories` | `LongTermMemories` | id (AUTOINCREMENT) | 长久记忆（系统设定与业务规则） |
| 5 | `knowledge_files` | `KnowledgeFiles` | id (AUTOINCREMENT) | 知识文件参考库（文件名/路径/大小/激活状态） |
| 6 | `vector_storage` | `VectorStorage` | id (AUTOINCREMENT) | 向量存储（RAG 知识胶囊） |
| 7 | `idea_tasks` | `IdeaTasks` | id (AUTOINCREMENT) | 闪念子任务清单（isDone/sortOrder） |
| 8 | `content_blocks` | `ContentBlocks` | id (AUTOINCREMENT) | 内容追加块（多模态多轮追加） |
| 9 | `ai_conversations` | `AiConversations` | id (AUTOINCREMENT) | AI 对话记录（与 payload 关联） |
| 10 | `ai_templates` | `AiTemplates` | id (AUTOINCREMENT) | AI 指令模板（chat/rule 两种类型） |
| 11 | `offline_queue` | `OfflineQueue` | id (AUTOINCREMENT) | 离线消息队列 |
| 12 | `crm_customers` | `CrmCustomers` | id (AUTOINCREMENT) | CRM 客户信息表 |
| 13 | `ledger_entries` | `LedgerEntries` | id (AUTOINCREMENT) | 记账流水表 |
| 14 | `todo_schedules` | `TodoSchedules` | id (AUTOINCREMENT) | 待办日程表 |
| 15 | `tags` | `Tags` | id (AUTOINCREMENT) | 全局标签主表 |

**多对多关联表（5 张）**：

| 序号 | 表名（SQL） | 关联关系 |
|------|-----------|----------|
| 16 | `hub_payload_tags` | hub_payloads <-> tags |
| 17 | `crm_customer_tags` | crm_customers <-> tags |
| 18 | `ledger_entry_tags` | ledger_entries <-> tags |
| 19 | `todo_schedule_tags` | todo_schedules <-> tags |
| 20 | `content_block_tags` | content_blocks <-> tags |

**审核收件箱（1 张）**：

| 序号 | 表名（SQL） | 核心用途 |
|------|-----------|----------|
| 21 | `dispatch_inbox` | AI 分发审核收件箱（暂存/确认/拒绝/撤销） |

#### 3.5.2 核心表 `hub_payloads` 完整字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | INTEGER PK | 自增主键 |
| `uuid` | TEXT UNIQUE | 全局唯一 ID |
| `raw_text` | TEXT | 原始输入文本 |
| `media_paths` | TEXT (JSON) | 媒体文件路径数组 |
| `intent_tag` | TEXT | 意图标签（NOTE/TODO/CRM/LEDGER/INVENTORY/HABIT） |
| `title` | TEXT | 载荷标题 |
| `processing_status` | TEXT | 处理流水线状态（10 种状态枚举） |
| `dispatched_ref` | TEXT | 分发引用 |
| `ai_entities` | TEXT (JSON) | AI 路由抽取的实体 |
| `is_ephemeral` | BOOLEAN | 是否标记为废话（48h 衰减） |
| `decay_deadline` | DATETIME | 衰减截止时间 |
| `is_deleted` | BOOLEAN | 软删除标记 |
| `cleaned_text` | TEXT | 清洗后文本 |
| `created_at` | DATETIME | 创建时间 |

#### 3.5.3 处理状态机（10 种状态）

```
synced_local → vector_checking → text_cleaned → ai_routing
                                                  ↓
                                    ┌──────────────┴──────────────┐
                                    ↓                             ↓
                              isEphemeral?                dispatching
                                    ↓                             ↓
                               dispatched                pending_review
                                    ↓                             ↓
                                decayed              confirmed / rejected / reverted
```

此外还有 `offline_saved`（离线暂存）和 `failed_retry`（失败重试）两条异常分支。

#### 3.5.4 数据库迁移历史

| 跨度 | 变更内容 |
|------|----------|
| v1→v2 | 新增 chat_sessions + chat_messages |
| v2→v3 | 新增 long_term_memories + knowledge_files |
| v3→v4 | 重建 knowledge_files（字段重构） |
| v4→v5 | 新增 vector_storage（RAG 向量） |
| v5→v6 | knowledge_files 新增 is_active |
| v6→v7 | 新增 idea_tasks（子任务） |
| v7→v8 | 新增 content_blocks + ai_conversations |
| v8→v9 | hub_payloads 新增 title；content_blocks 新增 tags |
| v9→v10 | 新增 ai_templates + 种子模板 |
| v10→v11 | 新增 processing_status/dispatched_ref/ai_entities/is_ephemeral/decay_deadline + CRM/Ledger/Todo 表 |
| v11→v12 | 新增 is_deleted + tags + 5 张 M2M 表 + dispatch_inbox |
| v12→v13 | hub_payloads 新增 uuid + 唯一索引 |
| v13→v14 | ai_templates 新增 template_type + 种子规则模板 |
| v14→v15 | 新增 offline_queue + cleaned_text |

### 3.6 前端视图组件体系

#### 3.6.1 设计系统（Design System）

位于 [lib/core/theme/design_system.dart](file:///e:/Dev/Locus/lib/core/theme/design_system.dart)，定义了四大设计轴线：

| 轴线 | 内容 | Token 数量 |
|------|------|-----------|
| `AppTypography` | 6 级字体体系（h1/h2/h3/body1/body2/label/caption） | 7 个 |
| `AppDimensions` | 空间度量与圆角（radiusXS→LG, spaceXS→XL） | 9 个 |
| `AppColorsExtension` | 语义化 7 色彩（surface1-2, textPrimary-tertiary, success, warning） | 7 色 |
| `AppThemeSpecification` | 8 套配色方案工厂（暗/明/青瓷绿/极地灰蓝/燕麦暖沙/玫瑰绯/薰衣草紫/抹茶绿） | 8 套 |

**品牌主色**：`Color(0xFFFF6B6B)`（粉红/珊瑚色）

#### 3.6.2 可复用 Widget 组件

| 组件 | 文件 | 功能 |
|------|------|------|
| `AiChatInputBox` | `idea_stream/widgets/ai_chat_input_box.dart` | AI 通用输入框，支持模板/知识库/记录三种模式 |
| `ProcessingStatusIndicator` | `idea_stream/widgets/processing_status_indicator.dart` | 处理状态微型指示器（8 种图标状态） |
| `TagPicker` | `idea_stream/widgets/tag_picker.dart` | 标签选择器，支持 compact 内联和 BottomSheet 两种模式 |
| `ContentBlockEditor` | `idea_stream/widgets/content_block_editor.dart` | 快速块编辑器（BottomSheet 模式） |
| `FullBlockEditor` | `idea_stream/widgets/full_block_editor.dart` | 全功能块编辑器（全屏富文本+Markdown） |
| `ExportBottomSheet` | `idea_stream/widgets/export_bottom_sheet.dart` | 导出选项面板 |
| `QuickInputBottomSheet` | `home/widgets/quick_input_bottom_sheet.dart` | FAB 快捷输入弹窗 |

### 3.7 核心业务逻辑节点

#### 3.7.1 依赖注入拓扑（20 个服务）

```
AppDatabase (SQLCipher 加密 SQLite)
    │
    ├── IdeaRepository, TemplateRepository, DashboardRepository
    ├── ChatRepository, CrmRepository, LedgerRepository
    ├── TodoRepository, TagRepository, MemoryRepository
    │
    ├── DispatchService ──→ AiRouterService ──→ AiEngine ──→ SecureStorageService
    │                              │                    │
    ├── DecayManager               │              SettingsService
    │                              │
    └── ProcessingPipeline ────────┘
            │
            ├── ConnectivityService (每 30s DNS 检测)
            ├── TextCleanerService (口语清洗)
            ├── VectorService (zvec HNSW 索引)
            └── VectorDedupService (语义查重)
```

#### 3.7.2 ProcessingPipeline 处理流水线（核心引擎）

```
用户输入 (QuickInput / Timeline / Chat)
    │
    ▼
IdeaRepository.insert() → HubPayloads (status=synced_local)
    │
    ▼
ProcessingPipeline.enqueue(payloadId)
    │
    ├─ 同步阶段 (processSync):
    │   ├── 离线检测 → offline_queue 暂存
    │   └── 标记 text_cleaned (待异步处理)
    │
    └─ 异步阶段 (processAsync, 3s 定时 Worker):
        ├── TextCleanerService.clean()          # 文本清洗
        ├── VectorService.upsertFtsDoc()        # FTS 索引
        ├── VectorDedupService.checkSimilarity() # 本地查重
        ├── AiRouterService.route()             # AI 意图路由
        │   ├── 在线: AiEngine.functionCall()
        │   └── 离线: IntentRouter.parseTag()
        ├── 若 isEphemeral → DecayManager 标记 + 48h 衰减
        └── 若 CRM/LEDGER/TODO → DispatchService.stageForReview()
            └── dispatch_inbox (pendingReview) → 用户确认/拒绝/编辑
```

#### 3.7.3 AI 引擎设计

[lib/core/services/ai_engine.dart](file:///e:/Dev/Locus/lib/core/services/ai_engine.dart) 封装了三种 LLM 调用模式：

| 模式 | 方法 | 超时 | 用途 |
|------|------|------|------|
| 非流式对话 | `chat()` | 30s | 简单问答 |
| SSE 流式对话 | `chatStream()` | 无 | ChatPage 实时渲染 |
| Function Calling | `functionCall()` | 15s | 意图路由结构化抽取 |

**支持的模型**：DeepSeek Chat / R1、GPT-4o / 4o-mini、Claude 3.5 Sonnet、Ollama 本地模型（llama3/mistral/qwen2/gemma2/deepseek-r1）

**数据安全**：发送前通过 `DataAnonymizer` 对手机号、身份证、银行卡、金额、邮箱做脱敏处理（可通过 `SettingsService` 开关控制）。

---

## 4. 开发工作总结与里程碑

### 4.1 已完成的开发工作

#### 基础设施层
- ✅ Flutter 项目初始化，全平台（Android/iOS/Windows/macOS/Linux/Web）编译支持
- ✅ Drift + SQLCipher 加密数据库部署，21 张表 + 15 步渐进迁移策略
- ✅ GetIt 依赖注入容器搭建，20 个服务/Repository 注册
- ✅ 设计系统建立：8 套配色方案 + 7 级字体体系 + 4 级圆角/间距
- ✅ 响应式导航系统：手机（底栏）/ 平板（窄侧边栏）/ PC（折叠侧边栏）三阶分流
- ✅ 环境固化：Flutter SDK `D:\flutter`，Android SDK `D:\AndroidSDK`

#### 闪念笔记模块（Idea Stream）
- ✅ 主列表页（IdeaStreamPage）：流式监听、搜索、标签联合筛选、网格/列表切换
- ✅ 详情页（IdeaDetailPage ~4200行）：内容块 CRUD、AI 对话、收件箱分发审核、标签管理
- ✅ 快捷输入（QuickInputBottomSheet + TimelinePage）
- ✅ 标签系统：Tags 主表 + 5 张 M2M 关联表 + TagPicker 组件 + TagBrowserPage 虚拟文件夹
- ✅ AI 模板系统：chat/rule 双类型、拖拽排序、种子数据、导入/导出
- ✅ 内容块系统：5 种类型（text/image/voice/video/file）、富文本编辑器、Markdown 混合编辑

#### AI 核心
- ✅ AiEngine：三模式调用（非流式/流式/Function Calling），多模型切换
- ✅ AiRouterService：双模态（在线 Function Calling + 离线本地正则降级）
- ✅ ProcessingPipeline：两阶段异步处理管线（同步 + 3s 定时 Worker）
- ✅ DispatchService：二阶段分发（暂存收件箱 → 用户确认 → 写入业务表）
- ✅ DecayManager：48h 废话衰减（alpha 渐变透明 UI 效果）
- ✅ 向量系统：zvec 接入（HNSW 索引 + FTS 全文检索 + 语义查重）
- ✅ ChatPage：SSE 流式对话、Markdown 渲染、会话管理、RAG 上下文
- ✅ 文本清洗 + 数据脱敏 + 长期记忆注入

#### 业务扩展模块
- ✅ Database Dashboard：财务图表（fl_chart）+ 待办统计 + 高频标签云 + CRM 概览
- ✅ CRM/Ledger/Todo 数据表 + Repository + 分发写入 + 撤销机制
- ✅ 长期记忆（Long-Term Memory）：规则设定 + 知识库文件（RAG 处理）

#### 设置模块
- ✅ 主题管理：明/暗切换 + 8 套配色方案 + 字体缩放（0.85-1.3）
- ✅ AI 配置：API Key/URL/Model 管理 + Ollama 本地模式 + 离线模式
- ✅ 数据脱敏开关 + 环境区分

#### 协同规范
- ✅ `.trae/` 工作区：12 份设计文档 + 15 个功能规范（三件套 + checklist）+ 开发总纲
- ✅ 完整的项目记忆系统（project_memory + topics + user_profile）

### 4.2 已完成的里程碑

| 里程碑 | 达成内容 | 对应 DB Schema |
|--------|----------|---------------|
| M1: 基座搭建 | 项目结构 + DI + DB + 设计系统 | v1 |
| M2: 聊天与记忆 | ChatPage + 会话管理 + 长期记忆 | v2-v3 |
| M3: RAG 知识库 | 文件管理 + 向量存储 + FTS 检索 | v4-v6 |
| M4: 闪念笔记 | 内容块 + 子任务 + AI 对话 | v7-v8 |
| M5: AI 双擎 | 意图路由 + Function Calling + 流式对话 | v9-v10 |
| M6: 五大能力升级 | 标签体系 + 分发收件箱 + 脱敏 + 看板 + 离线 | v11-v15 |
| M7: 详情页重构 | AI 收件箱内联 + 图标化操作 + 模板双分类 + FAB 改造 | - |

### 4.3 当前整体进展状态

**总体完成度**：约 **70%**

| 模块 | 完成度 | 说明 |
|------|--------|------|
| 核心基座 | 100% | DI / DB / 设计系统 / 导航骨架 |
| 闪念笔记 | 85% | 核心功能完备，部分导出功能为 TODO |
| AI 引擎 | 80% | 云端 API 完备，本地模型接入待完善 |
| 知识库 RAG | 75% | 向量/FTS 已实现，语义检索精度待优化 |
| 数据看板 | 80% | 6 大模块已上线，更多维度待扩展 |
| 日历模块 | 5% | 仅占位页面，完全未开发 |
| CRM 模块 | 40% | 数据表+仓库完成，专用 UI 页面未开发 |
| 记账模块 | 40% | 数据表+仓库完成，专用 UI 页面未开发 |
| 云端同步 | 0% | PocketBase 未启动 |
| OCR / 语音 | 5% | 接口定义完成，无实现 |

---

## 5. 后续开发排期与实施路径

### 5.1 近期优先（1-2 周）

#### P0：日历模块从零开始开发

当前 `CalendarPage` 为占位页面（仅含"正在规划中"提示文字）。需完成：
- **数据模型**：复用的 `todo_schedules` 表已具备 due_date 和 priority 字段，可直接作为日历数据源
- **页面开发**：基于 `table_calendar` 包实现月/周/日三视图
- **交互设计**：日期点击跳转待办列表、拖拽调整日期、颜色按优先级区分
- **与闪念笔记联动**：从日历视图可查看对应日期的闪念笔记

**涉及文件**：
- `lib/features/calendar/presentation/pages/calendar_page.dart`（重写）
- 可能需要新增 `lib/features/calendar/data/calendar_repository.dart`
- `lib/features/home/presentation/locus_home_page.dart`（注册导航）

#### P1：完善内容块导出功能

当前 `full_block_editor.dart` 中 4 处 TODO 标注未实现：
- 复制到剪贴板
- 截图导出
- Markdown 导出
- 纯文本导出

**涉及文件**：
- `lib/features/idea_stream/presentation/widgets/full_block_editor.dart`
- `lib/features/idea_stream/presentation/widgets/export_bottom_sheet.dart`

#### P2：CRM / 记账独立页面

已有完整数据模型（`crm_customers` / `ledger_entries` 表 + Repository），但缺少独立的列表和管理页面。

**新建文件**：
- `lib/features/crm/presentation/pages/crm_page.dart`
- `lib/features/ledger/presentation/pages/ledger_page.dart`
- 对应 `data/` 目录下的 Repository（可以复用 idea_stream/data/ 中的现有实现）

#### P3：模板预填机制

`idea_stream_page.dart` 第 277 行 TODO：点击空状态模板后，预填文本到 `QuickInputBottomSheet` 输入框。

### 5.2 中期规划（2-4 周）

#### P4：PocketBase 云端同步

- 搭建 PocketBase 服务（部署于私人 NAS/VPS）
- 实现 `HubPayloads` 双向实时同步
- 冲突解决策略（本地优先，云端为备份）
- 增量同步而非全量（按 `updated_at` 时间戳）

#### P5：知识库语义检索优化

- 当前 zvec 使用 1536 维向量 + HNSW 近似检索
- 需接入实际 Embedding 模型（当前仅建了索引框架）
- FTS 分词准确性优化（jieba 词典定制）
- 检索结果排序策略（向量相似度 + FTS 混合）

#### P6：日历与待办深度整合

- 待办提醒（本地通知）
- 重复待办（每日/每周/每月）
- 日历与待办的双向关联
- 图表化的完成率趋势

### 5.3 远期规划（1-3 月）

#### P7：本地小模型接入

- Ollama 集成完善（当前已有 UI，但功能路径未完全贯通）
- 本地 Embedding 模型（替代云端 API 进行向量化）
- 本地模型性能优化（量化/缓存）

#### P8：高级插件扩展

- 运动追踪插件
- 习惯打卡插件
- 报价管理插件
- 产品选型插件

#### P9：多端协同

- 局域网设备发现
- P2P 直连同步（不经过云端）
- 移动端到 PC 端的"接力"功能

---

## 6. 潜在风险、技术疑问与优化建议

### 6.1 潜在风险

| 风险项 | 严重程度 | 说明 |
|--------|----------|------|
| **单文件膨胀** | 🟡 中 | `idea_detail_page.dart` 已达 ~4200 行，包含内容块管理、AI 对话、收件箱审核三个独立子系统，后续维护成本将急剧上升 |
| **云端同步缺失** | 🔴 高 | PocketBase 同步未启动，用户数据缺乏异地备份能力，有单点故障风险 |
| **向量化实际能力** | 🟡 中 | zvec 已接入但缺乏 Embedding 模型实际调用，语义检索尚未真正跑通 |
| **SQLCipher 密钥硬编码** | 🔴 高 | 加密密钥当前为常量字符串 `locus_super_secret_master_key_2026`，需迁移至 SecureStorage 动态生成 |
| **缺少测试覆盖** | 🟡 中 | 未发现任何单元测试/Widget 测试/集成测试文件 |
| **多端数据一致性** | 🟡 中 | 未来多端同步时需处理时间戳冲突、离线编辑合并等复杂场景 |
| **OCR 能力空白** | 🟢 低 | 接口定义完成但无实现，对扫描件/图片文字提取场景不友好 |
| **录音功能** | 🟢 低 | ContentBlock 支持 voice 类型，但录音 UI 和 STT 转写全为空壳 |

### 6.2 待确认的技术疑问

| 序号 | 疑问 | 建议确认方向 |
|------|------|-------------|
| Q1 | Embedding 模型选型：云端 API vs 本地模型？ | 若纯本地，需接入 text-embedding 模型；若混合，zvec 仅做本地索引缓存 |
| Q2 | PocketBase vs 其他同步方案？ | PocketBase 为 Go 单文件部署，对个人 VPS/NAS 友好，但与 Drift 的映射层需自研 |
| Q3 | `idea_detail_page.dart` 拆分策略？ | 建议按子系统拆分为 `DetailContentBlockSection`、`DetailAIChatSection`、`DetailInboxSection` 三个独立 Widget |
| Q4 | 日历模块数据源：新增 Calendar 专属表 vs 复用 todo_schedules？ | todo_schedules 已有 due_date 和 priority，建议先复用，后续按需扩展 |
| Q5 | 是否引入状态管理框架（Riverpod/BLoC）？ | 当前 StreamBuilder + ChangeNotifier 模式运行良好，暂不建议引入额外复杂度 |
| Q6 | 离线模式下的 AI 能力降级策略？ | 当前离线仅支持本地正则路由，缺乏离线 LLM 推理能力 |

### 6.3 优化建议

#### 架构层面

1. **拆分 `idea_detail_page.dart`**：当前 4200+ 行的单文件需按功能域拆分为 3-5 个独立 Widget 文件，每个文件控制在 800 行以内
2. **抽取共享组件库**：将 `_buildStatusBanner`、`_buildInboxStatusChip`、`_buildPendingActionIcons` 等可复用组件提升为 `lib/core/presentation/widgets/` 下的通用组件
3. **规范 Repository 目录**：当前 CRM/Ledger/Todo 的 Repository 位于 `lib/features/idea_stream/data/`，建议移动到各自 feature 下（`lib/features/crm/data/`）
4. **建立错误处理中间层**：将 Repository 和 Service 中的 try-catch 统一封装，避免 UI 层直接处理数据库异常

#### 安全层面

5. **SQLCipher 密钥迁移**：将硬编码密钥替换为 `SecureStorageService` 动态生成 + 生物特征解锁
6. **API Key 轮换机制**：定期检测 API Key 有效性，提供过期提醒

#### 性能层面

7. **数据库索引优化**：当前仅 1 个显式索引（`idx_hub_payloads_uuid`），建议为高频查询字段（`processing_status`, `created_at`, `is_deleted`）添加复合索引
8. **内容块懒加载**：详情页的内容块列表当前全量加载，建议对超过 20 个块的记录做分页加载
9. **FTS 索引重建策略**：zvec 的 HNSW 索引需定期 optimize，建议在应用空闲时（如切到后台）触发

#### 体验层面

10. **空状态引导优化**：当前多个列表的空状态仅为图标+文字，建议添加操作引导（如"点击 + 创建第一条笔记"）
11. **撤销操作 Toast**：删除/分发操作后提供 3 秒撤销窗口，减少误操作损失
12. **键盘体验优化**：Calendar 和 Dashboard 等非输入密集型页面，建议在页面进入时自动收起键盘

---

## 附录 A：代码仓库统计概览

| 指标 | 数值 |
|------|------|
| Flutter/Dart 源文件数 | 50+ |
| 最大单文件行数 | ~4200 (`idea_detail_page.dart`) |
| 数据库表数 | 21 |
| 数据库迁移版本 | 15 |
| DI 注册服务数 | 20 |
| 核心页面数 | 15 |
| 可复用 Widget 组件数 | 7 |
| 设计系统配色方案数 | 8 |
| 功能规范文档数 | 15 (spec/tasks/checklist) |
| 设计计划文档数 | 12 |
| 已知 TODO/未完成项 | 29 |
| 支持的 AI 模型 | 9 (5 云端 + 4 本地) |

---

## 附录 B：已知 TODO 清单（精选）

| 文件 | 行号 | 内容 |
|------|------|------|
| `idea_stream_page.dart` | 277 | 接入 QuickInputBottomSheet 预填模板文本 |
| `idea_stream_page.dart` | 730 | 扩展 Drawer 导航项（CRM、记账、打卡等） |
| `full_block_editor.dart` | 363-376 | 复制/截图/MD/纯文本导出未实现 |
| `intent_router.dart` | 10 | 待办标题 AI 或本地提取标记 |

---

> **报告审批流程**：本报告供团队研讨确认，请重点关注第 5 章（排期思路）和第 6 章（风险与疑问），在确认开发方向后即可启动下一阶段实施。
