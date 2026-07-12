# AI 回复气泡底部按钮图标化 Spec

## Why
当前 AI 回复气泡下方的复制/导出/更多按钮使用纯文字（`_miniTextButton`），与项目整体图标驱动风格不一致。需改为图标按钮，保持间距和大小统一。

## What Changes
- 将 `_miniTextButton` 替换为图标按钮（复用项目已有的 `_BlockIconButton` 样式：icon size 14, color grey[500]）
- 图标选择：复制=`Icons.copy_outlined`、导出=`Icons.ios_share_rounded`、更多=`Icons.more_horiz_rounded`
- 保持按钮间距 `SizedBox(width: 8)` 及左缩进 `padding: EdgeInsets.only(left: 36)`

## Impact
- Affected specs: 无
- Affected code: `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` — `_buildConversationBubble` 方法中的 AI 底部按钮行

## MODIFIED Requirements
### Requirement: AI 回复气泡底部按钮图标化
AI 回复气泡下方的操作按钮 SHALL 使用图标显示，图标大小 14px，颜色 `Colors.grey[500]`，与项目 `_BlockIconButton` 风格一致。

#### Scenario: AI 回复气泡显示底部图标按钮
- **WHEN** 页面渲染 AI 回复气泡
- **THEN** 气泡左下角显示三个图标按钮：复制（copy_outlined）、导出（ios_share_rounded）、更多（more_horiz_rounded）
- **AND** 图标大小 14，颜色 grey[500]
- **AND** 按钮间距 8px
