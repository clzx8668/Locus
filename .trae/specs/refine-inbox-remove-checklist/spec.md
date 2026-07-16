# AI 收件箱内嵌化 + 移除转化执行清单 Spec

## Why
1. 当前 AI 收件箱以独立页面 + 铃铛按钮形式呈现，交互路径过长，割裂了内容页的连贯体验。应改为内嵌在详情页 AI 交互气泡区下方，以卡片块形式呈现，用户无需跳转即可完成审核操作。
2. "转化执行清单"（IdeaTasks）功能与核心处理管线定位重叠，且当前无实际使用场景，导致代码冗余膨胀。

## What Changes
- **AI 收件箱内嵌化**：删除 `inbox_review_page.dart` 独立页面，在 `idea_detail_page.dart` 的 AI 对话区下方新增内嵌 `DispatchInboxCard` 卡片组件，包含关联链接、撤销、重新生成、局部修改确认功能
  - **BREAKING**: 移除 `idea_stream_page.dart` 中的铃铛图标和 Drawer 入口
- **移除转化执行清单**：删除 idea_detail_page 中 `_buildTaskSection` 及关联状态变量、Repository 方法、数据库 DAO 方法（`IdeaTasks` 表定义保留以兼容已有数据）
  - **BREAKING**: 数据库中 `IdeaTasks` 表 DAO 方法清除，仅保留表结构

## Impact
- Affected specs: processing-pipeline-upgrade-plan (Step 3 UI 部分修订)
- Affected code: `idea_detail_page.dart`, `idea_stream_page.dart`, `inbox_review_page.dart`（删除）, `idea_repository.dart`, `database.dart`

## ADDED Requirements

### Requirement: DispatchInboxCard 内嵌卡片组件
系统 SHALL 在详情页 AI 对话区下方渲染内嵌的收件箱审核卡片，替代原有的独立页面跳转方案。

#### Scenario: Pending 分发项展示
- **WHEN** payload 关联的 DispatchInbox 状态为 `pending`
- **THEN** AI 气泡下方显示 `DispatchInboxCard`，包含：目标分发表标签、AI 抽取字段预览（金额/人名/时间/分类）、确认/拒绝/编辑按钮

#### Scenario: 确认分发
- **WHEN** 用户点击"确认分发"
- **THEN** 执行分发写入对应业务表，卡片变为已确认状态（显示分发链接和撤销按钮）

#### Scenario: 局部编辑后确认
- **WHEN** 用户修改抽取字段（如金额、分类）后点击"确认分发"
- **THEN** 以修改后的数据执行分发

#### Scenario: 重新生成
- **WHEN** 用户点击"重新生成"
- **THEN** 重置 payload 的 processingStatus 为 `synced_local`，重新触发 pipeline 处理

#### Scenario: 撤销已分发
- **WHEN** 用户点击"撤销分发"
- **THEN** 软删除目标表记录，清除 dispatchedRef，重置状态

#### Scenario: 无 Pending 项时不显示卡片
- **WHEN** payload 无关联的 pending DispatchInbox
- **THEN** DispatchInboxCard 区域不渲染，不会出现空白占位

## REMOVED Requirements

### Requirement: InboxReviewPage 独立页面
**Reason**: 交互路径过长，与内容页割裂
**Migration**: 删除 `inbox_review_page.dart`，功能内嵌到 `idea_detail_page.dart`

### Requirement: idea_stream_page 收件箱铃铛入口
**Reason**: 不再需要独立入口
**Migration**: 删除 AppBar 铃铛图标按钮及其 StreamBuilder，删除 Drawer "AI 收件箱"条目

### Requirement: 转化执行清单（_buildTaskSection）
**Reason**: 与处理管线功能重叠，当前无实际使用场景
**Migration**: 
- 删除 `idea_detail_page.dart` 中 `_buildTaskSection` 方法（第1611-1744行）
- 删除 `_tasksStream`、`_isEnteringTask`、`_newTaskController` 状态
- 删除页面中对 `_buildTaskSection` 的调用
- 删除 `idea_repository.dart` 中 `watchTasks`、`addTask`、`toggleTask`、`removeTask`
- 删除 `database.dart` 中 `watchTasksForPayload`、`insertTask`、`toggleTask`、`deleteTask` DAO 方法
- **保留** `IdeaTasks` 表定义及迁移逻辑（兼容已有数据，避免数据丢失）
