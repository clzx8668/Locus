# Checklist

- [x] `AiInputMode` 枚举定义存在（`template` / `knowledge`）
- [x] `AiInputConfig` 类存在，包含所有必需字段
- [x] `AiChatInputBox` 构造函数接受可选的 `inputConfig` 参数
- [x] 知识库模式下 @ 按钮被替换为知识库按钮（图标 + "知识库" 标签）
- [x] 知识库按钮点击弹出多选面板，列出 `knowledgeFiles`
- [x] 多选面板中每个文件有 Checkbox，勾选后更新 `selectedKnowledgeIds`
- [x] 面板底部显示"已选 N 个知识库"
- [x] 空知识库时面板显示提示 + 管理入口
- [x] 知识库模式下功能区显示网页搜索开关按钮
- [x] 网页搜索开关点击切换激活/关闭态，触发 `onWebSearchChanged` 回调
- [x] `template` 模式（默认）下 @ 模板按钮行为不变
- [x] ChatPage 导入并使用 `AiChatInputBox` + `AiInputConfig`
- [x] ChatPage 的 `_sendMessage` 根据 `_selectedKnowledgeIds` 过滤 RAG
- [x] ChatPage 的 `_sendMessage` 根据 `_isWebSearchEnabled` 注入搜索指令
- [x] 编译 `flutter analyze` 无新增错误
