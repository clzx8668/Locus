# Plan: 内容页右上角更多按钮及功能完善

## Summary
修改内容详情页 AppBar 右上角：将三点图标改为竖向、新增归档/隐藏菜单项、新增导出按钮（含半屏导出选择页，先实现复制到微信）。

## Current State Analysis

### 当前 AppBar actions（[idea_detail_page.dart](file:///e:/Dev/Locus/lib/features/idea_stream/presentation/pages/idea_detail_page.dart) L557-576）
```dart
actions: [
  PopupMenuButton<String>(
    icon: const Icon(Icons.more_horiz_rounded, size: 18),  // ← 横向三点
    ...
    itemBuilder: (ctx) => [
      const PopupMenuItem(value: 'edit_title', child: Text('修改标题')),
      const PopupMenuItem(value: 'delete', child: Text('删除此条')),
    ],
    onSelected: (val) { ... },
  ),
  const SizedBox(width: 8),
],
```

### 现有数据模型
- `hub_payloads.intentTag` 字段：NOTE / TODO / CRM / LEDGER / INVENTORY / HABIT
- `updatePayload(id, rawText, intentTag)` 方法可更新标签
- `_repo.watchBlocks(payloadId).first` 可获取所有内容块

### 现有半屏模式参考
- `QuickInputBottomSheet`（[quick_input_bottom_sheet.dart](file:///e:/Dev/Locus/lib/features/home/presentation/widgets/quick_input_bottom_sheet.dart)）：`showModalBottomSheet` + `isScrollControlled: true`

## Proposed Changes

### 变更一：三点图标方向修改
- **文件**: `idea_detail_page.dart` L559
- **修改**: `Icons.more_horiz_rounded` → `Icons.more_vert_rounded`

### 变更二：新增归档和隐藏菜单项
- **文件**: `idea_detail_page.dart` PopupMenuButton 的 itemBuilder
- **归档**: 新增子菜单项 `PopupMenuItem(value: 'archive', child: ...)`，点击后弹出子菜单列出所有意图标签（NOTE / TODO / CRM / LEDGER / INVENTORY / HABIT），选择后调用 `_repo.update(widget.payload.id, widget.payload.rawText, selectedTag)` 并显示 SnackBar "已归档到 [标签对应名称]"
- **隐藏**: 新增 `PopupMenuItem(value: 'hide', child: Text('隐藏'))`，点击后显示 SnackBar "功能开发中，敬请期待"
- **菜单顺序**: 修改标题 → 归档 → 隐藏 → 删除（红色）

### 变更三：导出按钮 + 半屏导出选择页
- **文件**: `idea_detail_page.dart` — 新增 `_showExportSheet()` 方法 + 新建独立 Widget 文件 `lib/features/idea_stream/presentation/widgets/export_bottom_sheet.dart`
- **AppBar actions 顺序**: `[导出图标, SizedBox(4), 更多菜单, SizedBox(8)]`
- **导出图标**: `IconButton(icon: Icons.ios_share_rounded, size: 18)`
- **半屏页**: `showModalBottomSheet` + `isScrollControlled: true`，页面标题"导出到"，网格布局展示导出选项
- **当前实现**: "复制到微信" — 拼接所有内容块的 `block.content`，用 `\n\n---\n\n` 分隔，复制到系统剪贴板，显示 SnackBar "已复制，可粘贴到微信"
- **预留槽位**: 后续可添加"导出为 PDF"、"导出为 Markdown 文件"、"导出到钉钉"等图标

## Assumptions & Decisions
- 归档通过修改 `intentTag` 实现，不改变 `rawText` 内容
- 标签名称映射：NOTE→普通笔记, TODO→待办清单, CRM→客户关系, LEDGER→记账, INVENTORY→库存管理, HABIT→习惯打卡
- 隐藏功能为纯前端预留，不写入数据库
- 导出使用 `Clipboard.setData(ClipboardData(text: ...))`，不引入第三方包
- 导出半屏页作为独立 Widget 文件，便于后续扩展

## Files to Change
| 操作 | 文件路径 |
|------|---------|
| 修改 | `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` |
| 新建 | `lib/features/idea_stream/presentation/widgets/export_bottom_sheet.dart` |

## Verification
1. 三点图标变为竖向 `Icons.more_vert_rounded`
2. 更多菜单包含 4 项：修改标题、归档、隐藏、删除
3. 点击归档弹出子菜单，选标签后 SnackBar 提示归档成功
4. 点击隐藏弹出 SnackBar "功能开发中，敬请期待"
5. 导出图标在更多按钮左侧，点击打开半屏页
6. 半屏页显示"复制到微信"，点击后内容复制到剪贴板
7. 导出内容为所有内容块的拼接文本
