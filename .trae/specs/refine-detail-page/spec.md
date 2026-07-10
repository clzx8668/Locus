# 内容页交互细节完善 Spec

## Why
当前内容详情页存在三个设计缺陷：每次追加新内容块会错误地覆盖首页卡片摘要；内容页缺少标题，以「工作台卡片 #id」硬编码显示不友好；标签绑定在页面级别而非按内容块独立管理，无法按块区分标签。

## What Changes
- 修复摘要覆盖 Bug：追加新内容块不再更新卡片摘要，仅编辑首块时才同步更新
- 新增内容页智能标题：首次进入自动生成标题，支持手动修改，持久化存储
- 标签体系重构：标签从页面顶部分散到每个内容块下方，每块独立管理标签
- **BREAKING**: `HubPayloads` 表新增 `title` 列；`ContentBlocks` 表新增 `tags` 列（需数据库迁移）

## Impact
- Affected specs: `refine-note-card-ui`（标签位置变更与其不冲突，分属不同页面）
- Affected code:
  - `lib/core/database/database.dart` — 表结构变更：`HubPayloads.title`、`ContentBlocks.tags`、新增 `updatePayloadTitle`
  - `lib/features/idea_stream/data/idea_repository.dart` — 新增标题存取方法
  - `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` — 摘要逻辑、标题生成、标签重构
  - `lib/features/idea_stream/presentation/pages/idea_stream_page.dart` — 卡片摘要显示逻辑微调

## ADDED Requirements

### Requirement: 卡片摘要不受后续追加影响
系统 SHALL 确保首页卡片列表显示的摘要在内容页追加新内容块时保持不变，仅当用户编辑第一个内容块的内容时才同步更新摘要。

#### Scenario: 追加新块不更新摘要（核心修复）
- **WHEN** 用户在内容页点击「追加内容」并成功提交新内容块
- **THEN** 首页该卡片的摘要文本保持不变
- **AND** `HubPayloads.rawText` 不被覆盖

#### Scenario: 编辑首块时同步更新摘要
- **WHEN** 用户编辑第一条内容块（sortOrder 最小的块）并保存
- **THEN** 系统自动取编辑后内容的前 200 字更新 `HubPayloads.rawText` 作为卡片摘要

#### Scenario: 编辑非首块不影响摘要
- **WHEN** 用户编辑非第一条内容块并保存
- **THEN** 摘要保持不变

### Requirement: 内容页自动生成智能标题
系统 SHALL 在用户首次进入内容页时自动生成一个标题，显示在页面顶端，并提供手动修改标题的入口。

#### Scenario: 首次进入自动生成标题
- **WHEN** 用户首次打开内容详情页且该记录 `title` 为空
- **THEN** 系统基于第一个内容块文本自动提取/生成标题（截取首行或前 30 字），写入 `HubPayloads.title`

#### Scenario: 标题手动修改
- **WHEN** 用户点击右上角更多菜单 →「修改标题」并输入新标题
- **THEN** 保存新标题至数据库，AppBar 即时更新

#### Scenario: 标题持久化
- **WHEN** 标题已设置（非空）
- **THEN** 再次进入该页面时不再自动生成，始终显示已保存的标题

#### Scenario: 标题清空后兜底
- **WHEN** 用户修改标题时输入空字符串并确认
- **THEN** 系统回退到自动生成逻辑（取首块内容前 30 字兜底）

### Requirement: 内容块独立标签管理
系统 SHALL 允许用户为每个内容块单独添加、修改、删除标签，标签显示在各自内容块的下方。

#### Scenario: 每块下方显示标签
- **WHEN** 内容页加载内容块列表
- **THEN** 每个内容块正文/媒体下方显示该块关联的标签 chip

#### Scenario: 快速添加标签
- **WHEN** 用户点击内容块下方的「+ 标签」按钮
- **THEN** 弹出快速输入框，输入标签名后即添加至该块

#### Scenario: 删除标签
- **WHEN** 用户点击标签 chip 的删除按钮（×）
- **THEN** 该标签从内容块中移除并持久化

#### Scenario: 页面级标签区域移除
- **WHEN** 内容页渲染
- **THEN** 页面顶部不再显示 `_buildTagSection`，标签管理全部分散到各内容块

## Database Migration
- `HubPayloads` 表新增 `title TEXT`（nullable，兼容旧数据）
- `ContentBlocks` 表新增 `tags TEXT`（默认空字符串，JSON 数组格式）
