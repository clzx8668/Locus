# 移动端键盘弹出时 AI 输入栏跟随 Spec

## Why
内容页 AI 输入框移入 `Scaffold.bottomNavigationBar` 后，移动端键盘弹出时输入栏被遮挡，不会自动上移。因为 `bottomNavigationBar` 不在 `resizeToAvoidBottomInset` 的管辖范围内，需手动添加键盘高度偏移。

## What Changes
- `_buildAiInputBar` 方法外层添加 `Padding`，`bottom` 使用 `MediaQuery.of(context).viewInsets.bottom`，键盘弹出时自动顶起输入栏

## Impact
- Affected specs: `ai-input-bottom-and-fab`
- Affected code: `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`

## MODIFIED Requirements

### Requirement: 键盘弹出时 AI 输入栏跟随上移
系统 SHALL 在移动端键盘弹出时，将 `bottomNavigationBar` 中的 AI 输入栏顶起至键盘上方。

#### Scenario: 键盘弹出
- **WHEN** 用户点击 AI 输入框弹出键盘
- **THEN** 输入栏整体上移至键盘正上方，不被遮挡

#### Scenario: 键盘收起
- **WHEN** 用户收起键盘
- **THEN** 输入栏恢复至屏幕底部原位
