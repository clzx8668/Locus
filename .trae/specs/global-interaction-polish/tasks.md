# Tasks

## Task 1: 数据库层补齐所有记录的删除方法
- [x] 在 `database.dart` 中为 `AppDatabase` 新增以下方法：
  - `deletePayload(int id)` — 删除单条 HubPayload 记录
  - `deleteCompany(String name)` — 删除公司记录及该公司下所有关联联系人的 company 字段置空
  - `deleteDeal(int id)` — 删除单条 Deal 记录
- [x] 验证：`flutter analyze` 无新增错误

## Task 2: 封装通用删除交互组件于 crm_design.dart
- [x] 实现 `CrmDeleteActionBar` — PC 端批量删除动作栏（显示已选计数 + Delete 按钮 + 确认弹窗），复用现有 `_selectionBar` 结构但提升为公开通用组件
- [x] 实现 `CrmSwipeDismissible` — 移动端左滑删除包装器，左滑露出红色背景 + 删除图标，点击触发确认后回调
- [x] 实现 `CrmDeleteConfirmation` — 统一的删除确认弹窗，使用 CRM token、列出即将删除的记录名称
- [x] 验证：组件可独立实例化，`flutter analyze` 无错误

## Task 3: 将通用删除接入 CRM 联系人列表（Contacts Tab）
- [x] 重构 `_selectionBar` → 改用 `CrmDeleteActionBar`
- [x] 移动端：列表项包裹 `CrmSwipeDismissible`，支持左滑单条删除
- [x] 移动端：长按触发多选模式
- [x] 验证：PC 多选删除正常、移动端左滑删除正常、长按多选正常

## Task 4: CRM 公司页（Companies Tab）加入批量删除与单条删除
- [x] Companies 表格加入 checkbox 多选列（复用 Task 2 组件）
- [x] 接入 `CrmDeleteActionBar` 实现批量删除
- [x] 移动端：接入 `CrmSwipeDismissible` 左滑 + 长按多选
- [x] 验证：PC/移动端删除公司正常

## Task 5: CRM Pipeline 页加入商机删除
- [x] Pipeline 看板卡片加入删除入口（卡片右上角 hover 显示删除图标）
- [x] 移动端：卡片左滑删除
- [x] 详情页 AppBar 更多菜单加入删除选项
- [x] 验证：PC/移动端删除 Deal 正常

## Task 6: CRM 详情页补充删除入口
- [x] `CompanyDetailPage` AppBar 右侧 more 菜单加入「Delete」选项，删除后返回上一页
- [x] `DealDetailPage` AppBar 右侧 more 菜单加入「Delete」选项，删除后返回上一页
- [x] `ContactDetailPage` AppBar 右侧 more 菜单加入「Delete」选项（如尚未有），删除后返回上一页
- [x] 验证：各详情页删除正常，返回上一页后列表刷新

## Task 7: 首页笔记记录（IdeaStreamPage）接入删除
- [x] 表格视图：加入 checkbox 多选 + `CrmDeleteActionBar`
- [x] 列表视图和卡片视图：行尾 hover 显示删除图标（PC），左滑删除（移动端）
- [x] 验证：三种视图下删除正常

## Task 8: 日历页面加入 FAB 与删除
- [x] 添加 FAB（日历/添加图标），点击弹出添加日程/待办表单
- [x] 如日历有事件记录数据，加入左滑删除 / 长按多选删除
- [x] 验证：FAB 正常渲染，删除流程正常

## Task 9: FAB 控制权从 Shell 下放至各页面
- [x] 移除 `LocusHomePage` 中的全局拖拽 FAB 按钮及相关代码
- [x] 确保各 Tab 页面内自行实现 `Scaffold(floatingActionButton: ...)`
- [x] 确认 AI Hub（ai_hub_page.dart）和设置页（settings_page.dart）不渲染 FAB
- [x] 确保 FAB 在各页面的位置和样式与 Twenty 设计语言一致
- [x] 验证：所有 Tab 切换时 FAB 按预期显示/隐藏，无残留全局 FAB

## Task 10: CRM 各子 Tab 的 FAB 定制
- [x] Companies Tab 内部加入 FAB（添加公司），与 Contacts 的 FAB 解耦
- [x] Pipeline Tab 内部加入 FAB（添加商机）
- [x] 确保 Contacts Tab 的 FAB 在选中状态下正确隐藏
- [x] 验证：CRM 页面切换 Tab 时 FAB 随 Tab 变化

# Task Dependencies
- Task 3-8 均依赖 Task 1 和 Task 2 完成
- Task 9 需在所有页面 FAB 实现完成后执行，确保无回归
- Task 4/5/6 可与 Task 3 并行
- Task 10 可与 Task 3/4/5 并行
