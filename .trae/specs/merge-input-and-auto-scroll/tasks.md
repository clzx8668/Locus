# Tasks

- [x] Task 1: AiChatInputBox 视觉重构 — 合并为统一圆角容器
  - [x] 将文本输入区域 `_buildTextInputArea` 的独立 `Container`（含 `borderRadius` 和独立 `color`）改为无边框的 `TextField`
  - [x] 将语音录音按钮 `_buildVoiceRecordButton` 的独立圆角 `Container` 改为无圆角的纯内容区域
  - [x] 在外层 `Container` 添加统一的 `borderRadius: BorderRadius.circular(12)` + `border: Border.all(...)` + 统一背景色
  - [x] 调整内边距，使文本区与功能区在统一容器内视觉连贯
  - [x] 验证暗黑/亮色模式下容器颜色正确（背景 `#262626`/`#F1F3F5`，边框跟随主题分割线色）

- [x] Task 2: IdeaDetailPage 交互增强 — 发送后自动收键盘 + 滚动到底部
  - [x] 添加 `ScrollController` 并绑定到 `SingleChildScrollView`
  - [x] 在 `_sendAiMessage` 中发送后调用 `_aiInputFocus.unfocus()` 收起键盘
  - [x] AI 回复写入后（`addConversation` 之后）调用 `_scrollToBottom()` 动画滚动到底部
  - [x] 在 `dispose` 中释放 `_scrollController`

- [x] Task 3: 测试验证（PC + 移动端）
  - [x] PC 端：圆角容器样式无误，暗黑/亮色切换正确，边框显示一致
  - [x] 移动端：底部输入容器不被键盘遮挡，统一圆角容器在窄屏下无溢出
  - [x] 键盘收起：发送后键盘自动 hidden，输入焦点转移
  - [x] 滚动定位：发送后内容自动滚动至 AI 回复区域，动画平滑不突兀

# Task Dependencies
- Task 2 依赖 Task 1（视觉重构完成后才能验证交互效果）
- Task 3 依赖 Task 1 + Task 2
