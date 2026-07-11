# 标签交互完善 Spec

## Why
1. 非编辑状态下标签字色过淡，辨识度不足
2. 退出标签编辑只能点击「完成」按钮，不便操作
3. 标签区域与右侧复制/导出按钮间距太小

## What Changes
- 标签字色改为更深/更醒目的颜色，增加 `fontWeight` 和 `fontSize`
- 将标签区域的长按 GestureDetector 改为 `HitTestBehavior.translucent`，使短按能穿透到外层 GestureDetector 触发退出编辑
- 标签与右侧按钮间距从 12 扩大到 24

## Impact
- Affected code: `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`

## MODIFIED Requirements

### Requirement: 非编辑状态标签颜色醒目
系统 SHALL 使非编辑模式下的标签文字颜色清晰可读。

#### Scenario: 标签文字清晰
- **WHEN** 用户查看内容块下的标签
- **THEN** 标签文字颜色与背景对比度足够，10px 字体清晰可辨

### Requirement: 点击非标签区域退出编辑
系统 SHALL 允许用户通过点击内容块中非标签的任意位置退出标签编辑模式。

#### Scenario: 点击内容区域退出
- **WHEN** 用户在标签编辑模式下点击内容块的文字/图片/空白区域（非标签 chip）
- **THEN** 编辑模式退出，标签恢复默认显示

### Requirement: 标签区域与右侧按钮间距合理
系统 SHALL 保持标签区域与右侧复制/导出按钮之间有足够的视觉间距。

#### Scenario: 间距合理
- **WHEN** 用户查看内容块底栏
- **THEN** 标签区域最右侧标签与复制按钮之间有至少 24px 的间距
