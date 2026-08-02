# Checklist

## 数据库层
- [x] `deletePayload(int id)` 方法存在且可正常删除 HubPayload 记录
- [x] `deleteCompany(String name)` 方法存在，删除公司同时置空关联联系人的 company 字段
- [x] `deleteDeal(int id)` 方法存在且可正常删除 Deal 记录

## 通用删除组件
- [x] `CrmDeleteActionBar` 组件存在于 `crm_design.dart`，接受 `selectedCount`、`onDelete` 等参数
- [x] `CrmSwipeDismissible` 组件存在，包裹子组件后左滑露出红色删除区域
- [x] `CrmDeleteConfirmation` 组件存在，弹出确认弹窗使用 CRM 设计 token

## CRM Contacts
- [x] 联系人页使用 `CrmDeleteActionBar` 替代原有的 `_selectionBar`
- [x] PC 端联系人表格支持多选 + 批量删除
- [x] 移动端联系人列表支持左滑单条删除
- [x] 移动端支持长按触发多选模式

## CRM Companies
- [x] 公司表格支持多选 + 批量删除
- [x] 移动端公司列表支持左滑删除 + 长按多选

## CRM Deals / Pipeline
- [x] Pipeline 卡片有删除入口（PC hover / 移动端左滑）
- [x] DealDetailPage 更多菜单有删除选项

## CRM 详情页
- [x] CompanyDetailPage 更多菜单含 Delete 选项，删除后返回上一页
- [x] DealDetailPage 更多菜单含 Delete 选项，删除后返回上一页
- [x] ContactDetailPage 更多菜单含 Delete 选项，删除后返回上一页

## 首页笔记
- [x] 首页表格视图支持多选 + 批量删除
- [x] 首页列表/卡片视图支持单条删除（PC hover / 移动端左滑）

## 日历
- [x] 日历页显示 FAB（添加日程），点击弹出表单
- [x] 日历事件如有数据支持删除（左滑 / 长按多选）

## FAB 控制权
- [x] `LocusHomePage` 不再渲染全局 FAB 或拖拽浮动按钮
- [x] 首页 FAB 显示且功能为快速笔记
- [x] 日历页 FAB 显示且功能为添加日程
- [x] CRM 联系人 Tab FAB 显示且功能为添加联系人，选中状态时隐藏
- [x] CRM 公司 Tab FAB 显示且功能为添加公司
- [x] CRM Pipeline Tab FAB 显示且功能为添加商机
- [x] AI Hub 页无 FAB
- [x] 设置页无 FAB

## 原位编辑
- [x] 详情页可编辑字段失焦后自动保存
- [x] 表格视图中可编辑字段失焦后自动保存（如适用）

## 格式化与分析
- [x] 所有改动的文件通过 `dart format`
- [x] `flutter analyze` 无新增错误
