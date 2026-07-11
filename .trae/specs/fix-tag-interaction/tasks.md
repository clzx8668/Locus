# Tasks

- [x] Task 1: 修复标签字色过淡
  - [x] `labelStyle.color` 从 `Color(0xFFFF6B6B)` 改为更深色 `Color(0xFFE55B5B)`
  - [x] `fontWeight` 从 `w500` 升级为 `w600`，提升辨识度

- [x] Task 2: 点击非标签区域退出编辑
  - [x] 标签区域 GestureDetector 添加 `behavior: HitTestBehavior.translucent`
  - [x] 短按穿透到外层 Container 的 GestureDetector.onTap 退出编辑

- [x] Task 3: 增加标签与右侧按钮间距
  - [x] Row 中 `SizedBox(width: 12)` 改为 `SizedBox(width: 24)`
