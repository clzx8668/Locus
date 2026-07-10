# Tasks

- [x] Task 1: idea_detail_page.dart — AI 输入框移入 Scaffold.bottomNavigationBar
  - [x] 从 `_buildAiSection` 中移除 `_buildAiInput(isDark)` 调用
  - [x] 在 `Scaffold` 中添加 `bottomNavigationBar` 属性，值为 `_buildAiInputBar(isDark)`
  - [x] 新建 `_buildAiInputBar(bool isDark)` 方法：从 `_buildAiInput` 复制逻辑，包裹为 `SafeArea` + `Padding` 的底部固定栏
  - [x] `SingleChildScrollView` 的 `padding` 底部从 `100` 改为 `20`
  - [x] 保留 `_buildAiInput` 方法不变（供后续复用），仅移除调用

- [x] Task 2: idea_detail_page.dart — 预设 AI 指令按钮
  - [x] 在 `_buildAiInputBar` 的输入框左侧插入预设按钮 `PopupMenuButton`
  - [x] 预设按钮弹出 `PopupMenuButton` 或 `showMenu`，列出 5 条预置指令
  - [x] 预置指令常量列表：`['总结全文要点', '翻译为英文', '润色优化表达', '提取关键信息', '生成内容大纲']`
  - [x] 选中预设后，将指令设为 `_aiInputController.text` 并调用 `_sendAiMessage()`

- [x] Task 3: locus_home_page.dart — AI 枢纽页隐藏 FAB
  - [x] 在 FAB 渲染处添加 `if (_currentIndex != 2)` 条件包裹
  - [x] 确认 `_currentIndex` 在 `locus_home_page.dart` 中可访问

# Task Dependencies
- Task 1 和 Task 2 可合并执行（修改同一文件的相邻代码）
- Task 3 完全独立，可并行执行
