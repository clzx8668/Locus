# Tasks

- [x] Task 1: idea_detail_page.dart — AI 底部输入栏 + 旧版 _buildAiInput + 对话框输入框统一
  - [x] `_buildAiInputBar` 内层 Container borderRadius 从 `24` 改为 `12`
  - [x] `_buildAiInput` Container borderRadius 从 `14` 改为 `12`
  - [x] `_buildAiInput` 填充色统一：暗黑 `#262626` / 亮色 `#F1F3F5`
  - [x] `_showEditTitleDialog` 中 TextField 添加 `filled: true`, `fillColor`, `OutlineInputBorder(borderRadius: 12)`
  - [x] `_showBlockTagDialog` 中 TextField 添加 `filled: true`, `fillColor`, `OutlineInputBorder(borderRadius: 12)`

- [x] Task 2: chat_page.dart — 聊天输入框 borderRadius 从 20 改为 12

- [x] Task 3: quick_input_bottom_sheet.dart — 快捷输入框 borderRadius 从 20 改为 12

# Task Dependencies
- 三个任务修改不同文件，完全独立，可并行执行
