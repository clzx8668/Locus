# 修复删除功能与 FAB 快速输入改造 Spec

## Why
1. 闪念笔记的删除操作存在两个 bug：主页左滑删除后重进页面记录复现（本地 DB 删除与 UI 状态不同步）；详情页右上角菜单"删除此条"点击无响应（PopupMenu 关闭动画与 showDialog 时序冲突）
2. FAB 快速输入模块样式简陋，需对齐 AI Hub 页面的 `AiChatInputBox` 统一风格，同时保持快速创建记录的核心功能不变

## What Changes
- 修复主页 `Dismissible.onDismissed` 的 fire-and-forget 删除问题，改为在 `confirmDismiss` 中先 await DB 操作再决定是否移除
- 修复详情页 `_confirmDelete()` 因 PopupMenu 关闭动画导致的 dialog 不弹出问题，添加 `addPostFrameCallback` 延迟
- 将 `QuickInputBottomSheet` 替换为复用 `AiChatInputBox`（`record` 模式），保留 `IdeaRepository.insert()` + `ProcessingPipeline.enqueue()` 记录创建流程

## Impact
- Affected specs: `unify-input-box-style`, `chat-reuse-input-box`（FAB 改造复用已有输入框组件）
- Affected code:
  - **修改** `lib/features/idea_stream/presentation/pages/idea_stream_page.dart`（主页删除逻辑）
  - **修改** `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`（详情页删除时序）
  - **重写** `lib/features/home/presentation/widgets/quick_input_bottom_sheet.dart`（FAB 输入改为 AiChatInputBox）
  - **修改** `lib/features/home/presentation/locus_home_page.dart`（调用方适配）

## ADDED Requirements

### Requirement: AiChatInputBox 新增 record 模式
系统 SHALL 在 `AiChatInputBox` 中新增 `AiInputMode.record` 模式，专用于快速记录场景。

#### Scenario: record 模式下仅显示文本输入与发送按钮
- **WHEN** 模式为 `AiInputMode.record`
- **THEN** 输入框底部不显示 @模板、知识库、网页搜索等功能按钮
- **AND** 发送时触发外部传入的 `onSendRecord` 回调而非 AI 对话流程
- **AND** 保持与 knowledge/template 模式一致的外层容器装饰样式

### Requirement: FAB 快速输入使用 AiChatInputBox（record 模式）
系统 SHALL 将 `QuickInputBottomSheet` 替换为包裹 `AiChatInputBox(mode: record)` 的 BottomSheet，复用 AI Hub 输入框的容器、圆角、色彩等样式。

#### Scenario: FAB 点击打开 record 模式输入
- **WHEN** 用户在非 AI Hub 页面点击 FAB 按钮
- **THEN** 弹出底部弹窗，内含 `AiChatInputBox(record 模式)`，样式与 AI Hub 输入框一致
- **AND** 内置 TextField 自动聚焦

#### Scenario: 快速记录发送
- **WHEN** 用户在 record 模式输入框输入文本并点击发送
- **THEN** 调用 `IdeaRepository.insert()` 创建 `HubPayload` 记录
- **AND** 调用 `ProcessingPipeline.enqueue()` 触发后台处理
- **AND** 发送后自动关闭弹窗

## MODIFIED Requirements

### Requirement: 主页左滑删除同步生效
**原行为**：`Dismissible.onDismissed` 中 fire-and-forget 调用 `_repo.delete()`，UI 已移除但 DB 删除可能失败，重进页面记录复现。

**改为**：在 `confirmDismiss` 中先 await `_repo.delete(data.id)`，仅在 DB 操作成功（返回值 > 0）时返回 `true` 允许移除；失败时返回 `false` 保留卡片并提示用户。

#### Scenario: 左滑删除成功
- **WHEN** 用户左滑卡片并确认删除
- **THEN** `confirmDismiss` 中 await DB delete 操作，成功返回 true
- **AND** 卡片被移除，`watchAll()` 流自动刷新列表
- **AND** 重进页面后记录不再出现

#### Scenario: 左滑删除失败
- **WHEN** DB delete 操作返回 0 或抛出异常
- **THEN** `confirmDismiss` 返回 false，卡片保留在原位
- **AND** 显示 SnackBar 提示"删除失败，请重试"

### Requirement: 详情页"删除此条"正常响应
**原行为**：`PopupMenuButton.onSelected` 中 `val == 'delete'` 直接调用 `_confirmDelete()`，但 PopupMenu 关闭动画与 `showDialog` 存在时序冲突，导致 dialog 有时不弹出。

**改为**：在 `onSelected` 的 delete 分支中使用 `WidgetsBinding.instance.addPostFrameCallback` 延迟一帧后再调用 `_confirmDelete()`，确保 PopupMenu overlay 完全移除后再弹出确认对话框。

#### Scenario: 点击"删除此条"弹出确认框
- **WHEN** 用户在详情页右上角菜单中点击"删除此条"
- **THEN** 菜单关闭，紧接着弹出"确认删除" AlertDialog
- **AND** 确认后执行 DB 删除并返回上一页
- **AND** 取消则不执行任何操作

---

## v26 第十三轮迭代：record 模式功能区完善

### Why
v25 的 record 模式底部仅显示发送按钮，缺少 AI Hub 输入框的标准两行式布局（上输入+下功能区），用户无法在快速输入时添加附件或使用语音输入。

### What Changes
- `_buildFunctionRow` 中 record 模式分支从"仅发送按钮"改为完整的左/右功能区布局
- 左侧：附件选择按钮（图片/文件/更多），替代原有的模型选择与@模板按钮
- 右侧：语音/键盘互斥切换 + 发送按钮（有内容时），移除 + 号上传按钮

## Impact
- Affected specs: `fix-delete-and-fab-input` v25
- Affected code:
  - **修改** `lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart`（`_buildFunctionRow` record 分支）

## v26 MODIFIED Requirements

### Requirement: record 模式采用完整两行式功能区布局
**v25 原行为**：record 模式底部仅靠右显示发送按钮，无其他功能按钮。

**v26 改为**：采用与 knowledge/template 模式一致的 `spaceBetween` 双区布局：
- 左侧：`_buildAttachButton`（图片/文件/更多附件选择）
- 右侧：`_buildToggleButton`（语音/键盘互斥切换）+ `_buildSendButton`（有文本时显示）
- 移除：模型选择按钮、@模板按钮、+号上传按钮

#### Scenario: record 模式功能区正确显示
- **WHEN** FAB 快速输入弹窗打开
- **THEN** 底部显示两行式布局：上文本输入 + 下功能区
- **AND** 左下角为附件按钮（图片、文件、更多选项）
- **AND** 右下角为空文本时显示语音/键盘切换按钮，有文本时显示发送按钮
- **AND** 无 AI 模型选择、无 @ 模板、无 + 号按钮

---

## v27 第十四轮迭代：修复移动端键盘贴合偏移问题

### Why
FAB 快速输入弹窗在移动端软键盘唤起时向上偏移过多，未紧密贴合键盘顶部。根因是 `viewInsets.bottom` 被三重累加：`showModalBottomSheet(isScrollControlled: true)` 已内建键盘避让 → `QuickInputBottomSheet` 又加了一层 `viewInsets.bottom` 填充 → `AiChatInputBox` 内部再加一层，导致输入框远离键盘悬空。

### What Changes
- `AiChatInputBox` / `AiInputConfig` 新增 `applyKeyboardPadding` 开关（默认 `true`），控制是否在 `build()` 中应用 `viewInsets.bottom` 填充
- `QuickInputBottomSheet` 移除自身的 `viewInsets.bottom` 填充
- `QuickInputBottomSheet` 向 `AiChatInputBox` 传入 `applyKeyboardPadding: false`

## Impact
- Affected specs: `fix-delete-and-fab-input` v26
- Affected code:
  - **修改** `lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart`（`AiInputConfig` 加开关，`build()` 条件应用 padding）
  - **修改** `lib/features/home/presentation/widgets/quick_input_bottom_sheet.dart`（移除 padding，传入开关）

## v27 MODIFIED Requirements

### Requirement: 移动端键盘贴合适配
**v26 原行为**：键盘唤起时输入框向上偏移过多，与键盘之间存在大段空白。

**v27 改为**：
- `showModalBottomSheet` 负责键盘避让（已有 `isScrollControlled: true`）
- `QuickInputBottomSheet` 不叠加 `viewInsets.bottom` 填充
- `AiChatInputBox` 在 `applyKeyboardPadding: false` 时跳过 `viewInsets.bottom` 填充
- 结果：输入框底部紧密贴合软键盘顶部边缘，无空档、无遮挡

#### Scenario: 键盘唤起时输入框正确贴合
- **WHEN** 移动端 FAB 快速输入弹窗中点击输入框唤起软键盘
- **THEN** 输入框随键盘平滑上移，底部紧密贴合键盘顶部
- **AND** 无额外空白间隙、无内容被遮挡
- **AND** 键盘收起时输入框恢复原位，无抖动
