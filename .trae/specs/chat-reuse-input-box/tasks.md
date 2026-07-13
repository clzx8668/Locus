# Tasks

- [x] Task 1: AiChatInputBox 新增 `AiInputConfig` 配置模型与知识库模式
  - [x] 定义 `AiInputMode` 枚举（`template` / `knowledge`）
  - [x] 定义 `AiInputConfig` 类，包含 mode、knowledgeFiles、selectedKnowledgeIds、onKnowledgeChanged、isWebSearchEnabled、onWebSearchChanged、onManageKnowledge
  - [x] AiChatInputBox 构造函数新增可选的 `AiInputConfig? inputConfig` 参数
  - [x] 当 `inputConfig.mode == knowledge` 时，`_buildAtButton` 替换为知识库按钮
  - [x] 知识库按钮显示数据库图标 + "知识库" 标签，点击弹出多选面板
  - [x] 知识库多选面板：列出所有文件 + Checkbox + "已选 N 个"计数 + 空状态 + 管理入口
  - [x] 功能区新增网页搜索开关按钮（仅知识库模式），地球图标，点击切换激活/关闭态并触发回调
  - [x] 确保 template 模式（默认/null）下 @ 按钮行为完全不变

- [x] Task 2: ChatPage 集成 AiChatInputBox
  - [x] 添加知识库/网页搜索相关状态变量（`_selectedKnowledgeIds`、`_isWebSearchEnabled`、`_selectedModel`）
  - [x] 添加 `StreamBuilder<List<KnowledgeFile>>` + `db.watchAllFiles()` 获取已挂载文件列表
  - [x] 替换 `_buildInputArea` 为 `AiChatInputBox`，传入 `inputConfig: AiInputConfig(mode: knowledge, ...)`
  - [x] `_sendMessage` 中根据 `_selectedKnowledgeIds` 过滤 RAG 上下文（新增 `getRelevantContextForFiles`）
  - [x] `_sendMessage` 中根据 `_isWebSearchEnabled` 注入联网搜索指令
  - [x] `_sendMessage` 模型读取改为使用 `AiEngine`（`_ai.modelName` / `_ai.baseUrl`）
  - [x] 删除旧的 `_buildInputArea` 方法

- [x] Task 3: 编译验证 + 兼容性回归
  - [x] `flutter analyze` 无新增错误/警告（chat_page.dart + ai_chat_input_box.dart + database.dart 全部通过）
  - [x] IdeaDetailPage 侧 @ 模板按钮功能未受影响（独立 analyze 通过）
  - [x] ChatPage 侧知识库多选、网页搜索开关状态切换正确

# Task Dependencies
- Task 2 依赖 Task 1（AiChatInputBox 完成知识库模式扩展后才能集成）
- Task 3 依赖 Task 1 + Task 2
