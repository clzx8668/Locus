# Tasks

- [x] Task 1: 修复主页左滑删除不持久问题
  - [x] SubTask 1.1: 将 `onDismissed` 中的 `_repo.delete(data.id)` 移除
  - [x] SubTask 1.2: 在 `confirmDismiss` 中，用户确认"删除"后先 await `_repo.delete(data.id)`，根据返回值判断成功/失败
  - [x] SubTask 1.3: 失败时保持卡片不消失并显示 SnackBar 提示

- [x] Task 2: 修复详情页"删除此条"点击无响应问题
  - [x] SubTask 2.1: 在 `onSelected` 的 delete 分支中，将 `_confirmDelete()` 包裹在 `WidgetsBinding.instance.addPostFrameCallback` 中延迟一帧执行

- [x] Task 3: AiChatInputBox 新增 record 模式
  - [x] SubTask 3.1: 在 `AiInputMode` 枚举中添加 `record` 值
  - [x] SubTask 3.2: 在 `build()` 中，record 模式下隐藏模板选择、知识库、搜索等功能按钮，仅保留文本输入与发送按钮
  - [x] SubTask 3.3: 新增 `onSendRecord` 回调参数（`final void Function(String text)? onSendRecord`），record 模式下发送时触发此回调而非 AI 对话

- [x] Task 4: 重写 QuickInputBottomSheet 为 AiChatInputBox 包裹
  - [x] SubTask 4.1: 在 `QuickInputBottomSheet` 中移除旧的文本输入和按钮，替换为 `AiChatInputBox(mode: record, onSendRecord: ...)`
  - [x] SubTask 4.2: `onSendRecord` 回调中调用 `IdeaRepository.insert()` + `ProcessingPipeline.enqueue()`，发送后 `Navigator.pop(context)` 关闭弹窗
  - [x] SubTask 4.3: 移除不再需要的图片选择、文件选择、媒体预览相关逻辑（`ImagePicker`、`FilePicker`、`_pendingMediaPaths`）

- [x] Task 5: 全量验证
  - [x] SubTask 5.1: VS Code 诊断零新增 error
  - [x] SubTask 5.2: 确认主页左滑删除功能生效且重进页面记录不重现
  - [x] SubTask 5.3: 确认详情页"删除此条"弹框正常显示并执行删除
  - [x] SubTask 5.4: 确认 FAB 快速输入样式与 AI Hub 一致，发送记录功能正常

## Dependencies
- Task 1 依赖于无（独立修复）
- Task 2 依赖于无（独立修复）
- Task 3 依赖于无（独立组件增强）
- Task 4 依赖于 Task 3（record 模式就绪后接入）
- Task 5 依赖于 Task 1、2、4

---

## v26 第十三轮迭代：record 模式功能区完善

- [x] Task 6: record 模式 `_buildFunctionRow` 改为完整双区布局
  - [x] SubTask 6.1: 左侧放置 `_buildAttachButton`（附件选择），替代原模型/@按钮
  - [x] SubTask 6.2: 右侧放置 `_buildToggleButton`（语音/键盘互斥切换），有文本时显示 `_buildSendButton`
  - [x] SubTask 6.3: 语音模式下保留 `_buildVoiceSubmitButton`，布局与 knowledge 模式一致

- [x] Task 7: 全量验证
  - [x] SubTask 7.1: VS Code 诊断零新增 error

## v26 Dependencies
- Task 6 依赖于无（独立布局调整）
- Task 7 依赖于 Task 6

---

## v27 第十四轮迭代：修复移动端键盘贴合偏移问题

- [x] Task 8: 修复 viewInsets 三重累加导致的键盘偏移
  - [x] SubTask 8.1: 在 `AiInputConfig` 中新增 `applyKeyboardPadding` 字段（默认 `true`）
  - [x] SubTask 8.2: 在 `AiChatInputBox.build()` 中，当 `applyKeyboardPadding` 为 `false` 时跳过 `viewInsets.bottom` 填充
  - [x] SubTask 8.3: `QuickInputBottomSheet` 移除自身的 `viewInsets.bottom` 填充
  - [x] SubTask 8.4: `QuickInputBottomSheet` 传入 `AiInputConfig(applyKeyboardPadding: false)`

- [x] Task 9: 全量验证
  - [x] SubTask 9.1: VS Code 诊断零新增 error
  - [x] SubTask 9.2: 确认非 record 模式（ChatPage / IdeaDetailPage）不受影响（仍应用 keyboard padding）

## v27 Dependencies
- Task 8 依赖于无（独立修复）
- Task 9 依赖于 Task 8
