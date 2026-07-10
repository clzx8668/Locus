# 内容页与详情交互完善计划

## 一、概述

对内容详情页（IdeaDetailPage）进行四项 UI/UX 完善：
1. 内容块默认 Markdown 预览模式，显式确认后才切换编辑
2. 完善图片预览（点击放大、网格优化）
3. 「追加内容」按钮收窄为自适应内容宽度、左对齐
4. AI 对话区改为微信风格气泡（用户右对齐、AI 左对齐）

## 二、当前状态分析

### 2.1 涉及文件

| 文件 | 关键代码 | 当前状态 |
|------|----------|----------|
| `idea_detail_page.dart` | `_buildContentBlock` (L285-385) | 纯文本 `Text(block.content)`，点击跳转编辑器 |
| `idea_detail_page.dart` | media preview (L351-378) | `Wrap` + 固定 `SizedBox` 网格，无点击放大 |
| `idea_detail_page.dart` | `_buildAddBlockButton` (L614-643) | `width: double.infinity` + `mainAxisAlignment: center` |
| `idea_detail_page.dart` | `_buildConversationBubble` (L733-775) | 全宽 + 左对齐 + 角色标签 |
| `idea_detail_page.dart` | `_buildAiSection` (L647-731) | 整体左对齐 `crossAxisAlignment: CrossAxisAlignment.start` |
| `full_block_editor.dart` | `_isPreview` (L32) | 默认 `false`（编辑模式），需手动切换预览 |

### 2.2 现有 Markdown 预览能力

`full_block_editor.dart` 的 `_buildMarkdownPreview` (L394) 已实现完整的 Markdown 渲染：标题 H1-H3、引用、列表、粗体、斜体、删除线、行内代码、分割线。该渲染器可直接复用到内容页。

## 三、变更计划

### 变更 1：内容块默认 Markdown 预览模式

**改什么**：`idea_detail_page.dart` — `_buildContentBlock` 方法

**具体步骤**：

1. **内容块预览改用 Markdown 渲染**：将 `_buildContentBlock` 中的纯 `Text(block.content)`（L345-348）替换为 Markdown 预览渲染。将 `full_block_editor.dart` 的 `_buildMarkdownPreview` 逻辑提取为独立方法 `_renderMarkdownPreview(String text, bool isDark)`，放入 `idea_detail_page.dart`。

2. **点击内容块行为变更**：
   - 当前：`onTap: () => _openBlockEditorForEdit(block)` — 直接进入编辑
   - 改为：保持 Markdown 预览状态，增加显式的"编辑"操作入口（在块头部的操作按钮行新增编辑按钮）

3. **双击或点击编辑按钮进入编辑**：在 `_buildContentBlock` 顶部操作栏添加 `_BlockIconButton(icon: Icons.edit_outline_rounded, label: '编辑', ...)`，点击后调用 `_openBlockEditorForEdit(block)`。

4. **编辑器默认预览模式**：修改 `full_block_editor.dart` 的 `_isPreview` 初始值从 `false` 改为 `true`（当有 `initialContent` 时默认预览）。新建空块时仍默认编辑模式。

### 变更 2：完善图片预览

**改什么**：`idea_detail_page.dart` — `_buildContentBlock` 中的 media preview 部分 (L351-378)

**具体步骤**：

1. **图片点击放大**：为 `Image.file(File(path))` 包裹 `GestureDetector`，点击后弹出全屏图片查看器。复用项目的图片查看方案：使用 `showDialog` + `InteractiveViewer`（支持缩放/平移）。

2. **网格布局优化**：将固定 `SizedBox(width: (width - 84) / 3, height: 90)` 改为使用 `LayoutBuilder` 自适应列数：
   - 宽屏：3-4 列
   - 窄屏：2 列
   - 图片高度自适应（`aspectRatio` 保持）

3. **多图角标**：超过 4 张图片时，第 5 张显示 `+N` 角标遮罩，点击可查看全部。

### 变更 3：「追加内容」按钮收窄 + 左对齐

**改什么**：`idea_detail_page.dart` — `_buildAddBlockButton` (L614-643) 及其父级 Column

**具体步骤**：

1. **宽度自适应**：移除 `width: double.infinity`，改用 `IntrinsicWidth` 包裹或直接设置 `padding` 让按钮根据文字内容自适配宽度。

2. **左对齐**：移除 `mainAxisAlignment: MainAxisAlignment.center`，将图标+文字 Row 改为 `mainAxisSize: MainAxisSize.min`。在调用处（L591）将 `Column(crossAxisAlignment: CrossAxisAlignment.start, ...)` 的左对齐继承下来。

3. **样式微调**：保持虚线边框风格，内边距从 `symmetric(vertical: 14)` 改为 `symmetric(horizontal: 16, vertical: 12)`，使按钮更紧凑。

### 变更 4：AI 对话微信风格气泡

**改什么**：`idea_detail_page.dart` — `_buildConversationBubble` (L733-775) + `_buildAiSection` (L647-731)

**具体步骤**：

1. **气泡对齐切换**：
   - 用户消息（`conv.role == 'user'`）：Column 的 `crossAxisAlignment: CrossAxisAlignment.end`，气泡右对齐
   - AI 消息（`conv.role == 'assistant'`）：Column 的 `crossAxisAlignment: CrossAxisAlignment.start`，气泡左对齐

2. **Remove full width**：移除 `width: double.infinity`，改用 `ConstrainedBox(maxWidth: width * 0.75)` 限制气泡最大宽度。

3. **气泡样式**：
   - 用户：Coral pink 背景 `Color(0xFFFF6B6B)`，白色文字，右对齐
   - AI：浅灰背景（light: `Color(0xFFF0F0F0)`, dark: `Color(0xFF2A2A2A)`），默认文字色，左对齐
   - 移除角色标签 `Text(isUser ? '你' : 'AI')`

4. **加载指示器对齐**：AI 思考中状态也左对齐。

## 四、不变更范围

- **数据库结构**：不修改任何表
- **Repository 层**：不修改 `IdeaRepository`
- **首页卡片列表**：不修改 `idea_stream_page.dart`
- **标签系统**：不修改 `_buildBlockTagSection`
- **任务清单**：不修改 `_buildTaskSection`

## 五、验证步骤

1. 进入内容页，确认内容块以 Markdown 渲染（标题/列表/粗体可见）
2. 点击内容块不跳转编辑器，仅通过"编辑"按钮进入
3. 编辑器打开已有内容时默认显示预览
4. 点击图片可放大查看，支持双指缩放
5. 「追加内容」按钮左对齐、宽度紧凑
6. AI 对话中用户消息右对齐粉色气泡，AI 消息左对齐灰色气泡
7. 检查暗黑模式下的图片预览和气泡颜色
