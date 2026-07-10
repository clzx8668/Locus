# 统一系统输入框风格 Spec

## Why
内容页 AI 底部输入栏内层 TextField 使用 `BorderRadius.circular(24)`，呈椭圆/胶囊形，与扁平外框不协调。同时系统内各输入框风格不统一（圆角 8/12/14/20/24、填充色各异），需统一为一致的视觉语言。

## What Changes
- AI 底部输入栏（`_buildAiInputBar`）内层 Container 的 borderRadius 从 24 改为 12
- 统一主输入框填充色：暗黑 `#262626` / 亮色 `#F1F3F5`
- 聊天页输入框 borderRadius 从 20 改为 12
- 快捷输入底部弹窗（QuickInputBottomSheet）TextField borderRadius 从 20 改为 12
- 旧版 `_buildAiInput`（桌面端备用）borderRadius 从 14 改为 12
- 对话框 TextField（标题编辑、标签添加）统一添加 filled + borderRadius 12 样式

## Impact
- Affected specs: `ai-input-bottom-and-fab`
- Affected code:
  - `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` — 3 处输入框
  - `lib/features/chat/presentation/chat_page.dart` — 聊天输入框
  - `lib/features/home/presentation/widgets/quick_input_bottom_sheet.dart` — 快捷输入

## MODIFIED Requirements

### Requirement: 内容页 AI 底部输入框风格
系统 SHALL 将 AI 底部输入栏内层 TextField 的圆角从 24 改为 12，与系统其他主输入框保持一致。

#### Scenario: 底部输入框圆角一致
- **WHEN** 用户查看内容详情页的 AI 输入栏
- **THEN** 输入框内层圆角为 `BorderRadius.circular(12)`，非椭圆/胶囊形
- **AND** 填充色暗黑模式为 `#262626`，亮色模式为 `#F1F3F5`

### Requirement: 聊天页输入框风格统一
系统 SHALL 将聊天页输入框 borderRadius 从 20 改为 12，填充色统一。

#### Scenario: 聊天输入框风格
- **WHEN** 用户在 AI 枢纽聊天页输入消息
- **THEN** 输入框圆角为 12，与内容页 AI 输入框一致

### Requirement: 快捷输入弹窗风格统一
系统 SHALL 将快捷输入弹窗（QuickInputBottomSheet）的 TextField borderRadius 从 20 改为 12。

#### Scenario: 快捷输入框风格
- **WHEN** 用户点击主页 FAB 打开快捷输入
- **THEN** 输入框圆角为 12

### Requirement: 对话框输入框风格
系统 SHALL 为标题编辑和标签添加两个对话框中的 TextField 添加统一样式。

#### Scenario: 对话框输入框
- **WHEN** 用户打开修改标题或添加标签对话框
- **THEN** 输入框使用 filled + borderRadius 12 + 统一填充色
