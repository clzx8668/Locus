# Plan: 内容块右下角复制导出图标 + 长按选择文本

## Summary
在每个内容块右下角添加复制和导出两个小图标，实现单块内容的快捷复制和导出。同时为内容块文本区域启用长按选择，支持部分文本复制。

## Current State Analysis

### 当前内容块结构（[idea_detail_page.dart](file:///e:/Dev/Locus/lib/features/idea_stream/presentation/pages/idea_detail_page.dart) L356-457）
```
_buildContentBlock:
├── 块头部 Row（来源图标 + 时间 + 编辑/润色/删除按钮）
├── 内容区域：_renderMarkdownPreview(block.content, isDark)
│   └── 返回 Column of RichText widgets（不支持文本选择）
├── 媒体预览
└── 标签区域
```

### 关键方法
- `_renderMarkdownPreview(text, isDark)` L1283-1337：用 `_parseInlineMD` 生成 `RichText` 片段
- `_parseInlineMD(text, baseStyle, isDark)` L1340-1380：解析行内 Markdown 返回 `RichText`
- `ExportBottomSheet(content)` 已存在，接收拼接文本字符串
- `_BlockIconButton` 组件 L1412-1448：统一的图标按钮

## Proposed Changes

### 变更一：内容块启用文本选择
- **文件**: `idea_detail_page.dart` `_buildContentBlock` 方法
- **做法**: 在内容区域外层包裹 `SelectionArea` widget
- **效果**: 用户可长按文本选中任意部分，系统自动弹出复制菜单
- **无需改动** `_renderMarkdownPreview` 内部逻辑

### 变更二：内容块右下角添加复制和导出图标
- **文件**: `idea_detail_page.dart` `_buildContentBlock` 方法
- **位置**: 在标签区域之后（Column 的最底部）添加 Row，`mainAxisAlignment: MainAxisAlignment.end`
- **复制图标**: `Icons.copy_rounded`，点击后 `Clipboard.setData(ClipboardData(text: block.content))`，SnackBar "已复制"
- **导出图标**: `Icons.ios_share_rounded`，点击后打开 `ExportBottomSheet(content: block.content)`（仅导出该块内容）
- **样式**: 复用 `_BlockIconButton` 小型图标按钮风格

## Files to Change
| 操作 | 文件路径 |
|------|---------|
| 修改 | `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` |

## Verification
1. 每个内容块右下角显示复制和导出两个小图标
2. 点击复制图标 → 该块内容复制到剪贴板 → SnackBar "已复制"
3. 点击导出图标 → 打开半屏导出页（仅该块内容）
4. 长按内容块文本区域 → 可框选部分文字 → 系统弹出复制菜单
5. 图标颜色使用灰色（与删除等图标风格一致）
