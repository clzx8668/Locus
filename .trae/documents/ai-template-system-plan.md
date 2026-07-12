# AI 智能指令模板系统 实施计划

## 概述

在内容详情页引入 AI 预设模板功能，通过"底部模板网格"、"行内 @ 唤醒"和"独立管理页"三位一体，实现 AI Prompt 的高效流转。

---

## 一、现状分析

### 1.1 当前预设系统

| 项目 | 当前状态 | 需变更 |
|------|---------|--------|
| 预设存储 | `static const List<String>` 硬编码 5 条 | 改为数据库驱动 |
| 触发方式 | 点击输入栏左侧 tag 按钮 → PopupMenu 上弹 | 保留按钮入口，新增网格 + @ |
| 发送行为 | 点击即发送，无预览 | 模板网格点击直接发送；@ 选择后可编辑再发送 |
| 管理能力 | 无 CRUD | 新增完整管理页 |
| 导入导出 | 无 | 新增 JSON 导入导出 |

### 1.2 关键代码位置

| 组件 | 文件 | 行号 |
|------|------|------|
| AI 输入栏 | `idea_detail_page.dart` | L1311-1390 |
| 预设按钮 | `idea_detail_page.dart` | L1392-1426 |
| `_sendAiMessage` | `idea_detail_page.dart` | L377-410 |
| 预设列表 | `idea_detail_page.dart` | L1303-1309 |
| 数据库表定义 | `database.dart` | L148-158 |
| 导航方式 | `locus_home_page.dart` | `Navigator.push(MaterialPageRoute(...))` |
| DI 注册 | `service_locator.dart` | L1-19 |
| 对话状态判断 | `idea_detail_page.dart` `_buildAiSection` | conversations.isEmpty |

### 1.3 页面作为新 feature 的模式参考

- `SettingsPage` ([settings_page.dart](file:///e:/Dev/Locus/lib/features/settings/presentation/pages/settings_page.dart)) — `StatefulWidget` + `getIt<>()` + `Scaffold` + `ListView`
- 导航模式：直接 `Navigator.push(MaterialPageRoute(...))`，无需路由框架

---

## 二、数据库层变更

### 2.1 新建 `AiTemplates` 表

**文件**: `lib/core/database/database.dart`，在现有表定义区域新增

```dart
class AiTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get icon => text().withDefault(const Constant('📋'))();   // emoji/图标
  TextColumn get name => text()();                                      // 模板名称
  TextColumn get prompt => text()();                                    // 核心 AI Prompt
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

注册到 `@DriftDatabase(tables: [...])` 注解中，schema version 升到 10，`onUpgrade` 中 `m.createTable(aiTemplates)`。

### 2.2 DAO 方法

```dart
// 按 sortOrder 排序查询所有启用的模板
Stream<List<AiTemplate>> watchEnabledTemplates();

// 查询全部模板（管理页用）
Stream<List<AiTemplate>> watchAllTemplates();

// 插入
Future<int> insertTemplate(String icon, String name, String prompt);

// 更新
Future<void> updateTemplate(int id, {String? icon, String? name, String? prompt, bool? isEnabled, int? sortOrder});

// 删除
Future<void> deleteTemplate(int id);

// 批量更新排序
Future<void> reorderTemplates(List<int> orderedIds);
```

### 2.3 预设种子数据

数据库首次创建时插入 5 条默认模板（替代现有硬编码列表）：

| icon | name | prompt |
|------|------|--------|
| 📝 | 总结全文要点 | 请根据以上内容，总结全文的核心要点 |
| 🌐 | 翻译为英文 | 请将以上内容翻译为英文 |
| ✨ | 润色优化表达 | 请润色优化以上内容的表达，使其更流畅专业 |
| 🔍 | 提取关键信息 | 请从以上内容中提取关键信息 |
| 📑 | 生成内容大纲 | 请根据以上内容生成结构化的内容大纲 |

---

## 三、Repository 层

**文件**: `lib/features/idea_stream/data/idea_repository.dart`（或新建 `template_repository.dart`）

新建 `TemplateRepository` 类，注册到 `service_locator.dart`：

```dart
class TemplateRepository {
  final AppDatabase _db;
  TemplateRepository(this._db);

  Stream<List<AiTemplate>> watchEnabled() => _db.watchEnabledTemplates();
  Stream<List<AiTemplate>> watchAll() => _db.watchAllTemplates();
  Future<int> insert(...) => _db.insertTemplate(...);
  Future<void> update(...) => _db.updateTemplate(...);
  Future<void> delete(int id) => _db.deleteTemplate(id);
  Future<void> reorder(List<int> ids) => _db.reorderTemplates(ids);
}
```

---

## 四、底部模板网格

### 4.1 位置与显隐逻辑

在 `_buildAiSection` 中，`StreamBuilder` 的 `builder` 内，根据 `conversations.isEmpty` 决定：

- **无对话**：在 AI 输入栏上方插入模板网格 `_buildTemplateGrid`
- **有对话**：不显示模板网格

网格位置：内容块区域下方、AI 输入栏上方的 section 内。随键盘弹起自动上移（已在 `_buildAiInputBar` 的 `viewInsets.bottom` 中处理）。

### 4.2 网格 UI

- 九宫格布局：`GridView.count(crossAxisCount: 3)` 或 `Wrap` 方式
- 每个格子：`GestureDetector` 包裹 `Column`（emoji + 名称），圆角卡片风格
- 读取 `_templatesStream`（仅 `isEnabled == true`，按 `sortOrder` 排序）
- 点击模板 → 立即调用发送逻辑（不经过输入框预览）

### 4.3 发送逻辑

从 `_sendAiMessage` 中抽取核心发送方法 `_sendPromptToAi(String prompt)`，不经过 TextField 缓存，直接作为 user message 写入并触发 AI 调用：

```dart
Future<void> _sendPromptToAi(String prompt) async {
  await _repo.addConversation(widget.payload.id, 'user', prompt);
  setState(() => _isAiWorking = true);
  // ... 同 _sendAiMessage 的 AI 调用逻辑 ...
}
```

模板网格点击和 @ 选择均调用此方法。

---

## 五、行内 @ 唤醒

### 5.1 检测逻辑

在 AI 输入栏的 `TextField.onChanged` 中检测文本变化：

```dart
onChanged: (value) {
  if (value.endsWith('@')) {
    _showAtMentionOverlay();
  }
}
```

使用 `Overlay` 或 `showMenu` 在输入框上方弹出模板选择列表。

### 5.2 悬浮选择列表

- `ListView` 显示 `watchEnabledTemplates()` 数据
- 每项：emoji + 名称
- 选中后：将模板的 prompt 填入输入框（替换掉 @），用户可编辑后再发送
- 点击空白处关闭 overlay

### 5.3 实现方式选择

使用 `OverlayEntry` + `CompositedTransformFollower` 定位到输入框上方，或更简单的 `showMenu` 定位。推荐 `showMenu`（与当前预设按钮一致的交互模式）。

---

## 六、模板管理页面

### 6.1 入口

底部 AI 输入栏左侧按钮 → 改为两个图标的组合或长按：
- **单击**：打开管理页（替代原 PopupMenu）
- 方案：将左侧 `_buildPresetButton` 改为直接导航到管理页的按钮

### 6.2 页面结构

**文件**: `lib/features/idea_stream/presentation/pages/template_management_page.dart`

```
TemplateManagementPage (StatefulWidget)
├── AppBar
│   ├── 标题: "AI 模板管理"
│   └── actions: [导入按钮, 导出按钮]
├── body: ReorderableListView
│   └── 每个 item
│       ├── leading: 拖拽手柄 (drag_handle)
│       ├── title: emoji + 名称
│       ├── subtitle: prompt 摘要
│       ├── trailing: Switch (启用/禁用)
│       └── onTap: 进入编辑
└── FAB: 新增模板按钮
```

### 6.3 CRUD 操作

| 操作 | 方式 |
|------|------|
| **新增** | FAB → 弹出编辑对话框（emoji 选择器 + 名称输入 + prompt 输入） |
| **编辑** | 点击 item → 弹出编辑对话框，预填现有值 |
| **删除** | 左滑删除 或 长按弹出删除确认 |
| **排序** | `ReorderableListView` 拖拽，释放后调用 `reorderTemplates` 持久化 |
| **启/禁** | Switch 开关，控制模板是否在网格和 @ 列表中显示 |

### 6.4 Emoji 选择

使用 Flutter 内置 emoji 输入或预设常用 emoji 网格（📝🌐✨🔍📑📊💡⚡🎯📋💬🔗📌🏷️✅❌➕➖），点击即选。

### 6.5 导入导出

| 方向 | 实现 |
|------|------|
| **导出** | 读取所有模板 → JSON 序列化 → 复制到剪贴板 + SnackBar 提示 |
| **导入** | 弹出输入框粘贴 JSON → 解析验证 → 批量 `insertTemplate` |

JSON 格式：
```json
{
  "version": 1,
  "templates": [
    {"icon": "📝", "name": "总结全文要点", "prompt": "...", "sortOrder": 0}
  ]
}
```

---

## 七、`_sendAiMessage` 重构

抽取核心 AI 调用逻辑为独立方法，供三种触发路径共用：

```dart
// 原始路径：用户输入框发送
Future<void> _sendAiMessage() async {
  final text = _aiInputController.text.trim();
  if (text.isEmpty) return;
  _aiInputController.clear();
  await _sendPromptToAi(text);
}

// 模板路径：模板/预设直接发送（不含输入框文本）
Future<void> _sendPromptToAi(String prompt) async {
  // 编辑模式清理
  if (_editingUserConvId != null) { ... }
  await _repo.addConversation(widget.payload.id, 'user', prompt);
  setState(() => _isAiWorking = true);
  // ... AI 调用 ...
}
```

---

## 八、文件变更清单

| 文件 | 变更类型 | 内容 |
|------|---------|------|
| `lib/core/database/database.dart` | **修改** | 新增 `AiTemplates` 表 + DAO 方法 + schema v9→v10 迁移 |
| `lib/core/di/service_locator.dart` | **修改** | 注册 `TemplateRepository` |
| `lib/features/idea_stream/data/idea_repository.dart` | **修改** | 新增 `TemplateRepository` 类（或在同文件中） |
| `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` | **修改** | 重构 `_sendAiMessage`、新增模板网格、@ 唤醒、重构预设按钮入口 |
| `lib/features/idea_stream/presentation/pages/template_management_page.dart` | **新建** | 模板管理页面（CRUD + 排序 + 导入导出） |

---

## 九、验证步骤

1. `flutter analyze` 无错误
2. 运行项目，打开新建笔记 → 底部出现模板网格
3. 点击网格模板 → AI 生成回复 → 网格自动消失
4. 在输入框输入 `@` → 弹出模板选择列表 → 选择后填入并可编辑
5. 点击输入栏左侧按钮 → 进入模板管理页
6. 管理页：新增/编辑/删除/拖拽排序/启用禁用 → 返回详情页验证变化
7. 导出 JSON → 清空模板 → 导入 JSON → 验证还原
8. 暗黑模式适配正常
