# 全局交互规划与完善 Spec

## Why
当前 Locus 平台的删除功能仅覆盖了联系人和记忆库，且 FAB 按钮使用全局统一方案未按页面定制。需补齐全平台记录的删除能力，统一 PC/移动端交互差异，同时各页面 FAB 按业务属性独立控制。

## What Changes
- 为所有记录类型补齐删除功能（HubPayload、Company、Deal、Task、Calendar Event）
- 封装统一的可复用删除交互组件，PC 端支持多选批量删除，移动端支持左滑单条删除 + 长按多选
- 将 FAB 控制权从 Shell 层下放到各独立页面，按业务定制显示/隐藏与功能
- 详情页原位编辑行为统一（失焦自动保存）
- 所有未明确定义的交互细节参照 Twenty 设计语言

## Impact
- Affected specs: CRM, Home/Idea Stream, Calendar, AI Hub, Settings
- Affected code:
  - `lib/core/database/database.dart` — 新增 delete 方法
  - `lib/features/contacts/presentation/widgets/crm_design.dart` — 新增统一删除组件
  - `lib/features/contacts/presentation/pages/crm_page.dart` — FAB 定制、Companies/Deals 删除
  - `lib/features/idea_stream/presentation/pages/idea_stream_page.dart` — FAB 定制、删除
  - `lib/features/calendar/presentation/pages/calendar_page.dart` — FAB 定制
  - `lib/features/home/presentation/locus_home_page.dart` — 移除全局 FAB、改为页面级
  - `lib/features/ai_hub/presentation/pages/ai_hub_page.dart` — 确认无 FAB
  - `lib/features/settings/presentation/pages/settings_page.dart` — 确认无 FAB

---

## ADDED Requirements

### Requirement: Unified Record Deletion
系统 SHALL 为所有核心记录类型提供统一的删除功能，覆盖 HubPayload、Contact、Company、Deal、Task、Calendar Event、LongTermMemory、KnowledgeFile。

#### Scenario: PC 端 — 表格多选批量删除
- **GIVEN** 用户在 PC 端任意记录列表页（Contacts / Companies / Deals / Home 表格视图）
- **WHEN** 用户点击行头 checkbox 进入多选模式，选中若干条记录，点击动作栏「Delete」
- **THEN** 系统弹出内联确认提示，用户确认后批量删除所选记录，刷新列表

#### Scenario: PC 端 — 单条记录删除
- **GIVEN** 用户在 PC 端任意记录列表页
- **WHEN** 用户 hover 某行记录，行尾出现删除图标按钮，点击按钮
- **THEN** 弹出确认提示，确认后删除该条记录，刷新列表

#### Scenario: 移动端 — 左滑单条删除
- **GIVEN** 用户在移动端任意记录列表页
- **WHEN** 用户在某条记录上左滑
- **THEN** 露出红色删除背景按钮，用户点击后弹出确认，确认后删除该条记录

#### Scenario: 移动端 — 长按多选批量删除
- **GIVEN** 用户在移动端任意记录列表页
- **WHEN** 用户长按某条记录触发多选模式，勾选若干条
- **THEN** 顶部出现选中动作栏（含删除按钮），点击后弹出确认，确认后批量删除

#### Scenario: 详情页内删除
- **GIVEN** 用户在任意记录的详情页（ContactDetailPage / CompanyDetailPage / DealDetailPage / IdeaDetailPage）
- **WHEN** 用户点击 AppBar 右侧更多菜单中的「Delete」选项
- **THEN** 弹出确认，确认后删除记录并返回上一页

#### Scenario: 空状态无删除入口
- **GIVEN** 页面当前无记录
- **WHEN** 用户查看页面
- **THEN** 不显示任何删除相关的 UI 元素

### Requirement: Reusable Deletion Components
系统 SHALL 提供封装的可复用删除交互组件，统一风格并简化各页面接入。

#### Scenario: CrmDeleteActionBar — PC 批量删除动作栏
- **GIVEN** 任意列表页需要批量删除功能
- **WHEN** 开发者调用 `CrmDeleteActionBar` 组件并传入选中数量和删除回调
- **THEN** 渲染统一风格的选中动作栏（显示已选计数 + Delete 按钮）

#### Scenario: CrmSwipeDismissible — 移动端左滑删除
- **GIVEN** 任意移动端列表项需要左滑删除
- **WHEN** 开发者用 `CrmSwipeDismissible` 包裹列表项，传入删除回调
- **THEN** 左滑露出红色背景 + 垃圾桶图标，点击触发确认后删除

#### Scenario: CrmDeleteConfirmation — 删除确认弹窗
- **GIVEN** 任意删除操作触发
- **WHEN** 系统调用 `CrmDeleteConfirmation` 显示确认弹窗
- **THEN** 弹窗使用统一的 CRM 设计 token、Twenty 风格，列出即将删除的记录名称摘要，用户确认后执行删除，取消则关闭

### Requirement: Per-Page FAB Customization
系统 SHALL 将 FAB 按钮的控制权从全局 Shell 下放到各独立页面，每页根据业务属性独立决定 FAB 的显示/隐藏及功能。

#### Scenario: 首页 FAB — 快速笔记
- **GIVEN** 用户在首页（IdeaStreamPage）
- **WHEN** 页面渲染
- **THEN** 显示 FAB（+ 图标），点击后弹出快速笔记输入底部弹窗

#### Scenario: 日历页 FAB — 添加日程/待办
- **GIVEN** 用户在日历页（CalendarPage）
- **WHEN** 页面渲染
- **THEN** 显示 FAB（日历图标或 + 图标），点击后弹出添加日程/待办的表单

#### Scenario: CRM 联系人页 FAB — 添加联系人
- **GIVEN** 用户在 CRM 联系人 Tab
- **WHEN** 页面渲染且无批量选中状态
- **THEN** 显示 FAB（+ 图标），点击后弹出添加联系人表单
- **WHEN** 用户处于批量选中状态
- **THEN** FAB 隐藏，改为显示批量动作栏

#### Scenario: CRM 公司页 FAB — 添加公司
- **GIVEN** 用户在 CRM 公司 Tab
- **WHEN** 页面渲染
- **THEN** 显示 FAB（Business 图标或 + 图标），点击后弹出添加公司表单

#### Scenario: CRM Pipeline 页 FAB — 添加商机
- **GIVEN** 用户在 CRM Pipeline Tab
- **WHEN** 页面渲染
- **THEN** 显示 FAB（Handshake 图标或 + 图标），点击后弹出添加商机表单

#### Scenario: AI Hub 页无 FAB
- **GIVEN** 用户在 AI Hub 页
- **WHEN** 页面渲染
- **THEN** 不显示 FAB

#### Scenario: 设置页无 FAB
- **GIVEN** 用户在设置页
- **WHEN** 页面渲染
- **THEN** 不显示 FAB

### Requirement: Global FAB Shell Removal
系统 SHALL 移除 `LocusHomePage` 中的全局浮动圆形按钮，并将 FAB 实现下沉至各页面内部。

#### Scenario: Shell 层不再持有 FAB
- **GIVEN** 应用主 Shell（LocusHomePage）
- **WHEN** 渲染各 Tab 页面
- **THEN** 不再在 Shell 层渲染任何 FAB 或拖拽按钮，各页面自行管理

### Requirement: Inline Edit with Blur-to-Save
系统 SHALL 在所有表格视图和详情页内对可编辑字段采用原位编辑模式，失焦时自动保存。

#### Scenario: 表格行内编辑
- **GIVEN** 用户在表格视图中双击或点击编辑图标触发某行某字段的编辑状态
- **WHEN** 用户修改字段内容后点击其他位置或按 Tab 键
- **THEN** 字段失去焦点时自动执行保存，退出编辑状态

#### Scenario: 详情页字段失焦保存
- **GIVEN** 用户在详情页内点击某可编辑字段
- **WHEN** 用户修改后点击其他字段或区域
- **THEN** 该字段失焦时自动保存

---

## MODIFIED Requirements

### Requirement: CRM Contacts Multi-Select (existing)
**Modified**: 将现有的 `_selectionBar` 组件提升为通用 `CrmDeleteActionBar`，复用至所有需要批量删除的列表页。原方法签名和功能保留。

### Requirement: Database Delete Methods (existing)
**Modified**: 为 `AppDatabase` 新增以下方法：
- `deletePayload(int id)` — 删除单条 HubPayload
- `deleteCompany(String name)` — 删除公司及其关联数据
- `deleteDeal(int id)` — 删除单条 Deal
- `deleteTask(int id)` — 删除单条 Task
- `deleteCalendarEvent(int id)` — 删除单条 Calendar Event（如存在对应表）
