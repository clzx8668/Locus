# ChatPage 复用 AiChatInputBox + 知识库/网页搜索功能 Spec

## Why
ChatPage（AI Hub 页面）当前使用自行实现的简单输入框，与 IdeaDetailPage 的 AiChatInputBox 功能差距大（无模型选择、无附件、无语音切换）。复用统一组件可消除重复代码，并在此基础上增强知识库选择与网页搜索能力。

## What Changes
- ChatPage 替换 `_buildInputArea` 为 `AiChatInputBox` 组件
- AiChatInputBox 新增可选的知识库模式，将 @ 模板按钮替换为知识库选择按钮
- 知识库按钮支持多选（勾选多个 KnowledgeFile），选中后注入到 RAG 上下文
- 新增网页搜索开关按钮，控制是否启用联网搜索
- ChatPage 的 `_sendMessage` 适配新输入接口

## Impact
- Affected specs: `merge-input-and-auto-scroll`（统一容器样式自动继承）
- Affected code:
  - `lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart` — 新增知识库模式、网页搜索开关
  - `lib/features/chat/presentation/chat_page.dart` — 替换输入框、适配状态管理

## ADDED Requirements

### Requirement: ChatPage 使用 AiChatInputBox
ChatPage SHALL 使用 `AiChatInputBox` 组件替代当前的 `_buildInputArea`，享受统一两行布局、模型选择、附件添加、语音切换等全部能力。

#### Scenario: ChatPage 显示完整输入框
- **WHEN** 用户进入 AI Hub（ChatPage）
- **THEN** 底部显示与 IdeaDetailPage 相同风格的统一圆角输入容器
- **AND** 包含模型选择按钮、附件按钮、语音/键盘切换按钮、发送按钮

### Requirement: 知识库选择按钮替换 @ 模板按钮
AiChatInputBox SHALL 支持通过配置切换到知识库模式，在该模式下第二个按钮从 @ 模板按钮变为知识库选择按钮（图标 + "知识库" 文字标签）。

#### Scenario: ChatPage 显示知识库按钮
- **WHEN** AiChatInputBox 配置为知识库模式
- **THEN** 第二个按钮显示数据库图标 + "知识库" 文字标签
- **AND** 点击弹出底部面板，列出所有已挂载的知识库文件

#### Scenario: 知识库多选
- **WHEN** 用户在知识库选择面板中勾选/取消勾选文件
- **THEN** 选中状态实时更新，面板内用 Checkbox 标记已选文件
- **AND** 面板底部显示"已选 N 个知识库"的计数提示
- **AND** 关闭面板后，已选知识库文件列表通过回调传递给 ChatPage

#### Scenario: 空知识库提示
- **WHEN** 系统中无任何已挂载的知识库文件
- **THEN** 面板显示"暂无知库文件，请在长期记忆页挂载文档"提示
- **AND** 提供快捷入口跳转至 LongTermMemoryPage

### Requirement: 网页搜索开关
AiChatInputBox SHALL 在知识库模式下，于功能按钮行新增网页搜索开关按钮。

#### Scenario: 网页搜索默认关闭
- **WHEN** AiChatInputBox 初始加载于知识库模式
- **THEN** 功能区显示网页搜索开关按钮（地球图标），默认处于关闭态（灰色）

#### Scenario: 开启网页搜索
- **WHEN** 用户点击网页搜索开关
- **THEN** 按钮切换为激活态（高亮色），状态通过回调通知 ChatPage
- **AND** ChatPage 在构建 system prompt 时追加"请结合联网搜索结果回答"指令

#### Scenario: 关闭网页搜索  
- **WHEN** 用户再次点击网页搜索开关
- **THEN** 按钮恢复关闭态（灰色），ChatPage 移除联网搜索相关指令

## MODIFIED Requirements

### Requirement: AiChatInputBox 支持模式配置
AiChatInputBox 的构造函数 SHALL 新增可选的 `inputConfig` 参数，类型为 `AiInputConfig`，包含：
- `mode: AiInputMode` — 枚举值 `template`（默认）或 `knowledge`
- `knowledgeFiles: List<KnowledgeFile>?` — 可用知识库文件列表
- `selectedKnowledgeIds: Set<int>` — 当前已选知识库文件 ID 集合
- `onKnowledgeChanged: ValueChanged<Set<int>>?` — 知识库选择变更回调
- `isWebSearchEnabled: bool` — 网页搜索开关状态
- `onWebSearchChanged: ValueChanged<bool>?` — 网页搜索开关变更回调
- `onManageKnowledge: VoidCallback?` — 管理知识库入口回调

### Requirement: 兼容性保证
AiChatInputBox 在未传入 `inputConfig` 或 `mode == template` 时 SHALL 保持现有 @ 模板按钮行为完全不变，确保 IdeaDetailPage 不受影响。
