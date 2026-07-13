# 修复文本输入框残留线框 Spec

## Why
AiChatInputBox 文本输入区内 `TextField` 的 `InputDecoration` 只设置了 `border: InputBorder.none`，但全局 `InputDecorationTheme` 定义了 `enabledBorder` / `focusedBorder` 为 `OutlineInputBorder`，导致聚焦/非聚焦时仍显示线框。

## What Changes
- AiChatInputBox 的 `_buildTextInputArea` 中 `InputDecoration` 显式设置 `enabledBorder: InputBorder.none` 和 `focusedBorder: InputBorder.none`

## Impact
- Affected code: `lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart`

## MODIFIED Requirements
### Requirement: 文本输入区完全无边框
系统 SHALL 确保 AiChatInputBox 的文本输入区在任何状态下（默认/聚焦/非聚焦）均不显示任何线框或边框装饰。

#### Scenario: 默认状态无边框
- **WHEN** 文本输入区未聚焦
- **THEN** 不显示任何边框或下划线

#### Scenario: 聚焦状态无边框
- **WHEN** 用户点击文本输入区使之获得焦点
- **THEN** 不显示任何高亮边框或下划线，仅光标闪烁
