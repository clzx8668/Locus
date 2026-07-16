# Tasks

- [x] Task 1: 重构 body 布局 —— 移除顶部固定渲染块
  - 从 body `Column` 中移除 `_buildDispatchedLink` 条件渲染块（约第1362-1364行）
  - 从 body `Column` 中移除 `_buildDispatchInboxCard(theme, isDark)` 调用（约第1366行）
  - 保留 `_buildStatusBanner` 在顶部不变

- [x] Task 2: 创建统一的"补充内容区"渲染方法
  - 在 `_buildAiSection` 同一层级（ScrollView 内部、`_buildAddBlockButton` 之后）新建 `_buildSupplementaryArea` 方法
  - 该方法合并获取 inbox 数据和 AI 对话数据，统一按 `createdAt` 排序
  - inbox 数据：通过 `StreamBuilder<List<DispatchInboxData>>` 获取当前 payload 的 pending/confirmed inbox
  - 对话数据：通过现有 `_conversationsStream` 获取
  - 排序规则：将 inbox 的 `createdAt` 与对话的 `createdAt` 合并排序，升序排列
  - 渲染：inbox 用 `_buildDispatchInboxCard` 项渲染，对话用 `_buildConversationBubble` 渲染
  - 空状态处理：两者皆空时显示空状态提示

- [x] Task 3: DispatchInboxCard 内部集成 dispatchedRef 链接
  - 修改 `_buildDispatchInboxCard`：当 `inbox.status == 'confirmed'` 且 payload 有 `dispatchedRef` 时，卡片内部显示分发链接行
  - 链接行包含：目标表标签 + 跳转链接
  - 确保与 body 中已被移除的 `_buildDispatchedLink` 功能对等

- [x] Task 4: 替换 ScrollView 内调用
  - 在 ScrollView 内部、`_buildAddBlockButton` 之后、原 `_buildAiSection` 之前，插入 `_buildSupplementaryArea`
  - 原 `_buildAiSection` 保留但不调用

- [x] Task 5: build_runner + dart analyze 验证
  - 执行 `dart run build_runner build --delete-conflicting-outputs` - 成功 (35.9s, 1346 outputs)
  - 执行 `dart analyze lib/` - 0 errors

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 1
- Task 4 depends on Task 2, Task 3
- Task 5 depends on all tasks
