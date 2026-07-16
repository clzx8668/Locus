# Checklist

## Task 1: 修复主页左滑删除不持久问题
- [x] `onDismissed` 中不再包含 `_repo.delete(data.id)`
- [x] `confirmDismiss` 中用户确认后 await `_repo.delete(data.id)`，成功返回 true，失败返回 false
- [x] 失败时显示 SnackBar "删除失败，请重试"且卡片不消失

## Task 2: 修复详情页"删除此条"点击无响应
- [x] `onSelected` delete 分支使用 `WidgetsBinding.instance.addPostFrameCallback(() => _confirmDelete())`
- [x] 点击"删除此条"后弹出确认对话框
- [x] 确认后执行 DB 删除并返回上一页

## Task 3: AiChatInputBox 新增 record 模式
- [x] `AiInputMode` 枚举包含 `record`
- [x] record 模式下不渲染 @模板、知识库、搜索等功能按钮
- [x] record 模式下发送触发 `onSendRecord` 回调而非 AI 对话
- [x] 发送按钮样式与现有 knowledge/template 模式一致

## Task 4: 重写 QuickInputBottomSheet
- [x] `QuickInputBottomSheet` 内部使用 `AiChatInputBox(mode: record)`
- [x] `onSendRecord` 回调正确调用 `IdeaRepository.insert()` + `ProcessingPipeline.enqueue()`
- [x] 发送后弹窗自动关闭
- [x] 移除旧的 `ImagePicker`、`FilePicker`、`_pendingMediaPaths` 逻辑

## Task 5: 全量验证
- [x] VS Code 诊断零新增 error
- [x] 主页左滑删除持久生效
- [x] 详情页"删除此条"正常响应
- [x] FAB 快速输入样式与 AI Hub 一致

---

## v26 第十三轮迭代（已实施，共 5 项）

### Task 6: record 模式功能区完善
- [x] record 模式 `_buildFunctionRow` 采用 `spaceBetween` 双区布局
- [x] 左侧为 `_buildAttachButton`（无模型/@按钮）
- [x] 右侧为空文本时语音/键盘切换，有文本时发送按钮
- [x] 语音模式下保留语音提交按钮

### Task 7: 全量验证
- [x] VS Code 诊断零新增 error

---

## v27 第十四轮迭代（已实施，共 6 项）

### Task 8: 修复 viewInsets 三重累加
- [x] `AiInputConfig` 新增 `applyKeyboardPadding` 字段，默认 `true`
- [x] `AiChatInputBox.build()` 仅在 `applyKeyboardPadding != false` 时应用 `viewInsets.bottom`
- [x] `QuickInputBottomSheet` 移除自身 `viewInsets.bottom` 填充
- [x] `QuickInputBottomSheet` 传入 `applyKeyboardPadding: false`

### Task 9: 全量验证
- [x] VS Code 诊断零新增 error
- [x] ChatPage / IdeaDetailPage 输入框键盘适配不受影响
