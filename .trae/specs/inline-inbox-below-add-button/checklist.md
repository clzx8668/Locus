# Checklist

- [x] body Column 中 `_buildDispatchedLink` 条件渲染块已移除
- [x] body Column 中 `_buildDispatchInboxCard(theme, isDark)` 已移除
- [x] ScrollView 内部、追加按钮下方新增统一排序区（inbox + 对话气泡混合）
- [x] inbox 卡片和对话气泡按 createdAt 升序排列（先产生的在上）
- [x] 仅有 inbox 无对话时，仅显示 inbox 卡片（AI 交流标题不冗余显示）
- [x] 仅有对话无 inbox 时，仅显示 AI 对话区（保持原有"AI 交流"标题）
- [x] 两者同时存在时，混合排序，不分组隔离
- [x] DispatchInboxCard 在 confirmed 状态下内部显示 dispatchedRef 链接
- [x] 撤销按钮功能正常（卡片级 `_buildInboxActions` 统一处理）
- [x] DispatchInboxCard 原始 confirmed 状态下的撤销按钮与链接行不重复
- [x] build_runner 构建成功
- [x] dart analyze 0 errors
