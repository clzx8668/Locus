# AI 交互输入框重构计划

## 1. 概述 (Summary)

对 `IdeaDetailPage`（闪念详情内容页）中的 AI 交互输入框进行系统性重构，从当前的单行 Row 布局升级为**两行式固定布局**，新增模型选择、模板快捷插入、语音/键盘模式切换、附件添加入口等功能，实现类 Notion AI / ChatGPT 风格的现代智能输入体验。

---

## 2. 当前状态分析

### 2.1 现有输入框实现

**文件：** `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`

- `_buildAiInput(bool isDark)` (line 1270-1309): 简洁单行输入，仅含输入框 + 圆形发送按钮，无对话记录时显示。
- `_buildAiInputBar(bool isDark)` (line 1311-1396): 底部固定输入栏，含预设按钮 + 多行输入框(maxLines:4) + 圆形发送按钮。这是需要重构的核心组件。
- `_buildPresetButton(bool isDark)` (line 1398-1415): 点击跳转至 `TemplateManagementPage`。
- `_showAtMentionOverlay()` (line 1471-1513): 输入 `@` 触发弹出菜单选择模板。
- `_sendPromptToAi(String prompt)` (line 390-416): 核心发送逻辑，将用户消息写入 AiConversations 表，调用 AiEngine 获取 AI 回复。

### 2.2 现有语音/附件支持

- `content_block_editor.dart`: `_isRecording` toggle + snackbar 占位提示，无实际录音功能。
- `full_block_editor.dart`: 工具栏含话筒按钮但回调为空。
- 数据库 `ContentBlocks` 表已预留 `blockType: 'voice'` 和 `sourceType: 'voice'` 字段。

### 2.3 现有模型配置

- `AiEngine` (`lib/core/services/ai_engine.dart`): `_model` 字段为 `final`，构造时从 `.env` 读取，**不支持运行时切换**。
- `ChatPage`: 直接读取 `.env` 变量，不与 AiEngine 共享。
- 设置页有 "API Keys / 模型配置" 入口但无点击响应。

### 2.4 模板系统

- `TemplateRepository` + `AiTemplate` 表已完备，支持 CRUD、启禁用、拖拽排序。
- `TemplateManagementPage` (515行) 功能完整：新增/编辑/删除/导入/导出模板。
- 已有 `@` 触发选择弹窗，但入口不够直观。

---

## 3. 拟议变更

### 3.1 新建文件：`lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart`

**核心组件：`AiChatInputBox`** — 重构后的两行式 AI 输入框组件

**要点：**

- **文件遵循命名规范**：`snake_case` 文件名，`UpperCamelCase` 类名。
- **两行布局结构：**
  - **第一行：文本输入区** — `TextField`/`EditableText`，自动适应高度（minLines:1，maxHeight: 视窗高度的 1/3）。
  - **第二行：功能按钮区** — `Row` with `MainAxisAlignment.spaceBetween` 两端对齐。

- **功能区按钮（从左到右）：**

  1. **模型选择按钮**（最左侧）  
     - 图标：LLM 模型品牌图标或通用 AI 图标 + 模型名简称文字  
     - 点击弹出底部面板 `showModalBottomSheet`，列出可用模型列表  
     - 选中模型后更新全局状态（通过 callback 回调给父页面）  
     - 视觉：圆角容器，hover/选中态高亮

  2. **@按钮**（第二个）  
     - 显示 `@` 文字  
     - **短按（<500ms）**：弹出模板选择面板（底部弹出 `showModalBottomSheet`），展示所有已启用的模板，点击插入模板 prompt 到输入框  
     - **长按（≥500ms）**：`Navigator.push` 跳转至 `TemplateManagementPage`  
     - 实现方式：`GestureDetector` + `onTap` + `onLongPress`

  3. **语音/键盘切换按钮**（右侧区域）  
     - 初始状态：显示话筒图标 `Icons.mic_none_rounded`  
     - 点击后切换为键盘图标 `Icons.keyboard_rounded`，进入语音模式  
     - 语音模式下，文本输入区替换为"点击录音"长条按钮  
     - 可来回切换

  4. **加号按钮（+）**（切换按钮右侧）  
     - 点击弹出底部面板，列出：添加图片、PDF文档、音频文件、视频文件  
     - 选择后调用 `file_picker` 或 `image_picker` 唤起系统选择器

  5. **发送按钮**（条件显示）  
     - 仅在文本输入模式 + 输入框非空时显示  
     - 此时隐藏切换按钮，加号按钮向左平移  
     - 蓝色圆形按钮，`Icons.send_rounded` 或 `Icons.arrow_upward_rounded`

### 3.2 修改文件：`lib/core/services/ai_engine.dart`

**要点：**

- 将 `_model` 从 `final` 改为非 `final`，新增 `setModel(String model)` 方法。
- 新增 `getModel()` getter，返回当前模型名。
- 新增 `static const availableModels` 列表，定义可选模型。
- 新增 `setBaseUrl(String url)` 方法，支持切换 API 端点。

```dart
static const List<Map<String, String>> availableModels = [
  {'id': 'deepseek-chat', 'name': 'DeepSeek Chat', 'provider': 'DeepSeek'},
  {'id': 'deepseek-reasoner', 'name': 'DeepSeek Reasoner', 'provider': 'DeepSeek'},
  {'id': 'gpt-4o', 'name': 'GPT-4o', 'provider': 'OpenAI'},
  // ...更多模型
];

void setModel(String model) => _model = model;
String get modelName => _model;
void setBaseUrl(String url) => _baseUrl = url;
```

### 3.3 修改文件：`lib/features/idea_stream/presentation/pages/idea_detail_page.dart`

**要点：**

- 删除 `_buildAiInput`、`_buildAiInputBar`、`_buildPresetButton`、`_showAtMentionOverlay` 方法。
- 新增 `_selectedModel` 状态变量，默认从 `AiEngine` 读取。
- 替换为 `AiChatInputBox` 组件：
  - 传入 `onSend` callback（复用 `_sendPromptToAi` 逻辑）。
  - 传入模型相关回调（`onModelChanged` → 更新 `AiEngine._model` + setState）。
  - 传入 `onAttachmentPicked` 回调（将文件保存为 ContentBlock）。
  - 传入模板相关回调（短按选择、长按跳转）。

**状态管理新增：**
```dart
String _selectedModel = '';      // 当前选中的模型ID
bool _isVoiceMode = false;       // 是否为语音输入模式
```

### 3.4 语音输入方案（预留接口）

**策略：** 当前技术条件暂不集成完整语音转写 SDK，**优先实现预留接口 + 手动语音文件提交**。

**`AiChatInputBox` 组件中的语音逻辑：**

- 语音模式下，显示"点击开始录音"按钮。
- 点击开始录音（当前阶段仅触觉反馈 + Toast 提示"录音功能开发中"）。
- 预留 `VoiceInputHandler` 抽象接口：

```dart
/// 语音输入处理器接口（预留扩展）
abstract class VoiceInputHandler {
  /// 开始录音，返回录音文件路径
  Future<String> startRecording();
  
  /// 停止录音
  Future<void> stopRecording();
  
  /// 语音转文字（STT）
  Future<String> transcribe(String audioPath);
  
  /// 自动提交：录音 → 转写 → 发送
  Future<bool> autoSubmit(Future<void> Function(String text) onSend);
}
```

- 当前提供 `DefaultVoiceInputHandler` 实现，返回 unsupported 错误提示。
- 后续集成 `speech_to_text` 插件时替换实现即可。

### 3.5 附件添加功能

**实现方式：**

- 加号按钮点击 → 弹出 `showModalBottomSheet`，展示附件类型选项。
- 选择后调用现有 `image_picker` 或 `file_picker` 包（项目已依赖）。
- 选中文件后，通过 callback 传递给父页面，父页面调用 `_repo.addBlock()` 将文件路径写入 ContentBlocks 表。
- 支持的附件类型：图片（`image_picker`）、PDF/文档/音频/视频（`file_picker`）。

---

## 4. UI 规范对齐

### 4.1 尺寸与间距

- 输入框整体圆角：`AppDimensions.radiusMD`(12)
- 按钮容器：36x36px，图标 20px
- 按钮间距：8px
- 两行内边距：horizontal 12px, vertical 8px
- 输入框最大高度：`MediaQuery.of(context).size.height * 0.33`

### 4.2 色彩

- 输入区背景：暗黑 `0xFF262626` / 浅色 `0xFFF1F3F5`
- 发送按钮激活态：品牌色 `Color(0xFFFF6B6B)`
- 发送按钮非激活态：`Colors.grey[400]`
- 功能区容器背景：透明 / 半透明
- 模型按钮激活态：带品牌色边框或高亮

### 4.3 暗黑模式适配

- 所有颜色通过 `Theme.of(context).brightness == Brightness.dark` 判断。
- 卡片阴影在暗黑模式下禁用。
- 输入框光标颜色跟随主题。

---

## 5. 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| **新建** | `lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart` | 核心 AI 输入框组件 |
| **修改** | `lib/core/services/ai_engine.dart` | 新增 `setModel()`、`setBaseUrl()`、`availableModels` |
| **修改** | `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` | 替换旧输入框、集成新组件、新增状态变量 |

---

## 6. 实现步骤

### Step 1: 修改 AiEngine，支持运行时模型切换

- 将 `_model` 改为非 final，新增 getter/setter
- 新增 `availableModels` 静态常量列表
- 新增 `setBaseUrl()` 方法
- ChatPage 同步适配（从 AiEngine 读取模型名）

### Step 2: 创建 AiChatInputBox 组件

按以下顺序实现子组件：

1. **基础布局骨架**：两行 Column（文本区 + 功能区）
2. **文本输入区**：自适应高度 TextField，maxHeight = 视窗 1/3
3. **功能区 Row**：spaceBetween 布局
4. **模型选择按钮**：图标+文字，点击弹底部面板选择模型
5. **@按钮**：`GestureDetector` + `onTap`/`onLongPress`，短按弹模板面板，长按跳转模板管理页
6. **切换按钮**：话筒↔键盘图标切换，同步切换输入模式
7. **加号按钮**：弹附件类型选择面板
8. **发送按钮**：条件显示逻辑（文本模式 + 非空时显示）
9. **语音模式 UI**："点击录音"按钮

### Step 3: 集成到 IdeaDetailPage

- 删除旧的 `_buildAiInput`、`_buildAiInputBar`、`_buildPresetButton`、`_showAtMentionOverlay`
- 引入 `AiChatInputBox` 组件
- 连接 callback：`onSend`、`onModelChanged`、`onAttachmentPicked`
- 保留 `_sendPromptToAi` 核心逻辑不变

### Step 4: 测试验证

- 文本输入 + 发送（基本流程）
- 模型选择 → 切换后发送验证模型是否生效
- @短按 → 模板选择 → 插入输入框
- @长按 → 跳转模板管理页
- 语音/键盘切换 → UI 状态切换正确
- 加号 → 附件面板 → 文件选择
- 输入非空时 → 发送按钮出现，切换按钮消失
- 暗黑模式切换 → 所有颜色正确适配
- 响应式适配：手机竖屏 / 平板横屏 / PC 宽屏

---

## 7. 假设与决策

1. **目标页面**：此次重构仅针对 `IdeaDetailPage`（闪念详情内容页）的 AI 输入框。`ChatPage`（AI Hub 独立聊天页）暂不纳入本次范围，以免改动过大。

2. **语音输入**：当前阶段不集成真实 STT SDK，仅提供 UI 交互体验 + 预留接口。后续迭代时替换 `VoiceInputHandler` 实现即可。

3. **模型配置**：模型列表硬编码在 `AiEngine` 中，后续可通过设置页面自定义配置（本次不做）。

4. **附件处理**：附件上传后保存为 `ContentBlock`，类型标记为对应类型（image/file/voice），与现有数据库 schema 兼容。

5. **模板插入**：短按 @ 按钮弹出的模板面板中，选中模板后将其 `prompt` 内容**插入到输入框光标位置**（而非直接发送），让用户有时间修改。

6. **组件复用**：`AiChatInputBox` 设计为独立 Widget，后续 `ChatPage` 可直接复用。
