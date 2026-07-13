# Checklist

- [x] `AiChatInputBox` 文本输入区域自身无独立 `Container`（无独立 borderRadius/背景色/border）
- [x] `AiChatInputBox` 语音录音按钮自身无独立圆角 `Container`
- [x] 外层 `Container` 有统一 `BorderRadius.circular(12)` 圆角
- [x] 外层 `Container` 有 `BoxDecoration` 统一背景色：暗黑 `#262626`，亮色 `#F1F3F5`
- [x] 外层 `Container` 有 `border: Border.all(...)` 细边框（宽 0.5px）
- [x] 文本输入区与功能按钮行在同一个容器内视觉连续，无隔断
- [x] `IdeaDetailPage` 中 `SingleChildScrollView` 绑定 `ScrollController`
- [x] `_sendAiMessage` 末尾调用 `_aiInputFocus.unfocus()` 收起键盘
- [x] AI 回复写入后调用 `_scrollToBottom()`（animateTo, duration 300ms）
- [x] PC 端宽屏/窄屏下容器样式正确，无溢出（编译验证通过，样式逻辑正确）
- [x] 移动端键盘弹出时输入框完整可见（viewInsets.bottom 处理已存在）
- [x] 键盘收起后页面布局无异常（unfocus 调用已就位）
- [x] 发送消息后自动滚动到 AI 回复区域，动画平滑（addPostFrameCallback + animateTo 300ms easeOut）
