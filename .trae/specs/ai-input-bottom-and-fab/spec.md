# AI 输入框吸底 + 预设按钮 + AI 枢纽隐藏 FAB Spec

## Why
1. 内容页 AI 交流输入框嵌入在 `SingleChildScrollView` 底部，键盘弹出时不吸附，用户需手动滚动才能看到
2. 缺少快速选择预设 AI 执行计划的能力
3. AI 枢纽页已有独立聊天输入框，主页 FAB 悬浮其上造成遮挡

## What Changes
- AI 输入框从 `SingleChildScrollView` 内移入 `Scaffold.bottomNavigationBar`，固定在窗口最底部、键盘上方
- 输入框左侧新增预设功能按钮（`#` 图标），点击弹出预设指令选择菜单
- 预设指令列表预置 3-5 条常用 AI 执行计划（如：总结、翻译、润色、提取要点、生成大纲）
- AI 枢纽页 (`_currentIndex == 2`) 不显示 FAB
- **BREAKING**: `_buildAiInput` 从 `_buildAiSection` 中移除，改为外部独立渲染

## Impact
- Affected specs: 无已有 spec
- Affected code:
  - `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` — AI 输入移出 ScrollView，新增预设按钮
  - `lib/features/home/presentation/locus_home_page.dart` — FAB 按 `_currentIndex == 2` 条件隐藏

## ADDED Requirements

### Requirement: AI 输入框吸附窗口底部
系统 SHALL 将内容页的 AI 交流输入框固定在页面最底部，键盘弹起时自动吸附在键盘上方。

#### Scenario: 输入框常驻底部
- **WHEN** 用户打开内容详情页
- **THEN** AI 交流输入框固定在屏幕最底部，不随内容滚动
- **AND** `SingleChildScrollView` 底部 padding 从 100 缩小为 20（仅保留内容间距）

#### Scenario: 键盘弹出时吸附
- **WHEN** 用户点击 AI 输入框弹出键盘
- **THEN** 输入框自动上移至键盘正上方，不被遮挡

### Requirement: 预设 AI 执行计划按钮
系统 SHALL 在 AI 输入框左侧提供预设按钮，点击可快速选择常用 AI 指令。

#### Scenario: 显示预设按钮
- **WHEN** AI 输入框渲染
- **THEN** 输入框左侧显示 `#` 图标按钮

#### Scenario: 选择预设指令
- **WHEN** 用户点击预设按钮
- **THEN** 弹出菜单，显示预置指令列表（总结、翻译、润色、提取要点、生成大纲）
- **WHEN** 用户选择一项
- **THEN** 指令文本填入输入框，自动发送

#### Scenario: 预设内容可扩展
- **WHEN** 开发者新增预设项
- **THEN** 仅需修改预设列表常量，UI 自动适配

### Requirement: AI 枢纽页隐藏 FAB
系统 SHALL 在 AI 枢纽页（`_currentIndex == 2`）不渲染主页的快速输入 FAB。

#### Scenario: AI 枢纽页无 FAB
- **WHEN** 用户切换到 AI 枢纽标签
- **THEN** 主页 FAB 不显示，AI 枢纽自身的聊天输入框正常可见

#### Scenario: 其他页面 FAB 正常
- **WHEN** 用户切换到闪念、日历或设置标签
- **THEN** 主页 FAB 正常显示
