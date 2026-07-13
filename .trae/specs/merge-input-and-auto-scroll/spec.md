# 输入框容器合并 + 发送后自动滚动 Spec

## Why
1. 当前 AI 输入框采用外框(仅顶部分割线) + 内层独立圆角 TextField 的双层结构，视觉不够统一简洁
2. 用户发送消息后不会自动滚动到最新 AI 回复，需手动下滑查看结果；键盘也不会自动收起，影响阅读体验

## What Changes
- AiChatInputBox 将文本输入区域与功能按钮行合并为一个完整圆角容器，移除内层独立边框
- IdeaDetailPage 添加 ScrollController，发送消息后自动 disband 键盘 + 滚动到底部

## Impact
- Affected specs: `unify-input-box-style`（旧输入框风格已统一，需适配新组件）
- Affected code:
  - `lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart` — 视觉重构：合并为统一容器
  - `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` — 交互增强：ScrollController + 发送后聚焦/滚动

## MODIFIED Requirements

### Requirement: 输入框统一圆角容器
系统 SHALL 将 AiChatInputBox 的文本输入区域与功能按钮行包裹在同一个带圆角的容器内，整个组合区域共享统一的视觉边界。

#### Scenario: 文本模式下显示统一容器
- **WHEN** 界面处于文本输入模式（非语音模式）
- **THEN** 文本输入区与功能按钮行位于同一个带 `BorderRadius.circular(12)` 的容器内
- **AND** 容器背景色为暗黑 `#262626` / 亮色 `#F1F3F5`
- **AND** 容器外围有 `0.5px` 宽度的细边框，颜色跟随主题分割线色
- **AND** 文本输入区自身不再有独立的圆角或边框装饰

#### Scenario: 语音模式下容器保持统一
- **WHEN** 界面处于语音输入模式
- **THEN** "点击录音"按钮与功能按钮行仍位于同一个统一圆角容器内
- **AND** 容器风格与文本模式保持一致

### Requirement: 发送后自动解散键盘
系统 SHALL 在用户提交消息成功后自动收起系统输入法键盘。

#### Scenario: 点击发送按钮后键盘收起
- **WHEN** 用户输入文本后点击发送按钮
- **THEN** 消息提交后系统输入法键盘自动收起

#### Scenario: 按回车提交后键盘收起
- **WHEN** 用户输入文本后按回车提交
- **THEN** 消息提交后系统输入法键盘自动收起

### Requirement: 发送后自动滚动到最新内容
系统 SHALL 在 AI 回复完成后自动将页面滚动至最新对话内容区域，确保用户无需手动操作即可看到回复。

#### Scenario: 发送后自动滚动到 AI 回复
- **WHEN** 用户提交消息且 AI 回复完成渲染
- **THEN** 页面自动滚动到底部，用户可见最新 AI 回复气泡

#### Scenario: 滚动动画平滑
- **WHEN** 触发自动滚动
- **THEN** 滚动过程使用平滑动画（`animateTo` with `duration: 300ms`），不产生突兀跳变
