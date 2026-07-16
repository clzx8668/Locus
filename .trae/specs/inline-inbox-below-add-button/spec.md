# AI 收件箱卡片下移到追加按钮下方 + 与 AI 对话区合并排序 Spec

## Why
当前 DispatchInboxCard 渲染在 `ScrollView` 上方的固定位置（处理状态横幅后），视觉上割裂了内容流。应下移到"追加内容"按钮下方，与 AI 对话气泡区合并在同一内容区域，按激活时间排序（先激活的在上），形成一个完整的内容流卡片。

## What Changes
- **DispatchInboxCard 下移**：从 body `Column` 的固定位置（ScrollView 上方）移至 ScrollView 内部 `_buildAddBlockButton` 下方
- **与 AI 对话区合并排序**：DispatchInboxCard 和 AI 对话气泡区（`_buildAiSection`）共享同一渲染区域，按 `createdAt` 时间戳排序——先产生的在上方展示
- **dispatchedRef 链接卡片化**：`_buildDispatchedLink` 的链接内容合并到 DispatchInboxCard 内部，不再单独渲染
  - **BREAKING**: body 中 `_buildDispatchedLink` 调用移除
- **移除 body 顶部固定 DispatchInboxCard**：`_buildDispatchInboxCard(theme, isDark)` 从 body Column 顶部移除

## Impact
- Affected specs: `refine-inbox-remove-checklist` (DispatchInboxCard 位置修订)
- Affected code: `idea_detail_page.dart` (body 布局重构)

## MODIFIED Requirements

### Requirement: DispatchInboxCard 内嵌位置
DispatchInboxCard SHALL 渲染在 ScrollView 内部、"追加内容"按钮下方，与 AI 对话气泡共享同一渲染区域。

#### Scenario: 仅有收件箱无对话
- **WHEN** payload 有 pending inbox 但无 AI 对话记录
- **THEN** 追加按钮下方显示 DispatchInboxCard，AI 对话区（含"AI 交流"标题）不显示

#### Scenario: 仅有对话无收件箱
- **WHEN** payload 有 AI 对话记录但无 pending inbox
- **THEN** 追加按钮下方显示 AI 对话区，DispatchInboxCard 不渲染

#### Scenario: 两者同时存在，按时间排序
- **WHEN** payload 同时有 pending inbox 和 AI 对话记录
- **THEN** 追加按钮下方按 `createdAt` 时间戳升序排列：先创建的在上面，后创建的在下面
- **AND** inbox 卡片和对话气泡混合排序（非分组隔离）

#### Scenario: 分发链接合并到卡片
- **WHEN** inbox 已确认分发（status=confirmed）且有 dispatchedRef
- **THEN** DispatchInboxCard 内部显示分发链接行（替代 body 顶部的 `_buildDispatchedLink`）

## REMOVED Requirements

### Requirement: Body 顶部固定 DispatchInboxCard
**Reason**: 改为 ScrollView 内部按时间排序渲染
**Migration**: body Column 中移除 `_buildDispatchInboxCard(theme, isDark)`，`_buildAiSection` 和 inbox card 合并渲染

### Requirement: Body 顶部 _buildDispatchedLink
**Reason**: 链接合并到 DispatchInboxCard 内部
**Migration**: body Column 中移除 `_buildDispatchedLink(isDark)` 条件渲染块；在 DispatchInboxCard 的 confirmed 状态下显示链接
