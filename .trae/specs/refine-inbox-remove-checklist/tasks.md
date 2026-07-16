# Tasks

- [ ] Task 1: 创建内嵌 DispatchInboxCard 组件
  - 在 `idea_detail_page.dart` 中新增 `_buildDispatchInboxCard` 私有方法
  - 使用 `StreamBuilder<DispatchInboxData?>` 监听当前 payload 关联的 pending inbox
  - 卡片布局：目标表标签（如 CRM/LEDGER/TODO）+ AI 抽取字段列表（可编辑 TextField）+ 操作按钮行（确认/拒绝/重新生成）
  - 确认操作：调用 `dispatchService.executeDispatch()` 并更新 UI
  - 拒绝操作：调用 `dispatchService.rejectDispatch()` 并收起卡片
  - 重新生成：重置 `processingStatus` 为 `synced_local` 触发 pipeline 重跑
  - 分发后显示撤销按钮，调用 `dispatchService.undoDispatch()`
  - 卡片仅在 `status == 'pending'` 或已确认时显示
  - **Depends on**: Task 2

- [ ] Task 2: 在 idea_detail_page 中插入 DispatchInboxCard
  - 在 `_buildAiChatSection` (AI 对话区) 下方添加 `_buildDispatchInboxCard` 调用
  - 确保卡片与页面风格统一（Material 3 Card + 自适应暗黑模式）
  - 注入 `DispatchService` 和 `AppDatabase` 依赖

- [ ] Task 3: 删除 InboxReviewPage 独立页面及入口
  - 删除 `lib/features/idea_stream/presentation/pages/inbox_review_page.dart`
  - 从 `idea_stream_page.dart` 中：
    - 删除 `import 'inbox_review_page.dart'`
    - 删除 AppBar 铃铛图标按钮及其 StreamBuilder
    - 删除 Drawer "AI 收件箱" ListTile
    - 删除 `_pendingInboxCountStream` 方法

- [ ] Task 4: 移除转化执行清单代码
  - 修改 `idea_detail_page.dart`：
    - 删除 `_tasksStream` 字段声明
    - 删除 `_isEnteringTask` 字段声明
    - 删除 `_newTaskController` 字段声明及 dispose
    - 删除 `_tasksStream = _repo.watchTasks(widget.payload.id)` 初始化
    - 删除 `_buildTaskSection` 方法（第1611-1744行）
    - 删除页面中 `_buildTaskSection(theme, isDark)` 调用
  - 修改 `idea_repository.dart`：删除 `watchTasks`、`addTask`、`toggleTask`、`removeTask` 方法
  - 修改 `database.dart`：删除 `watchTasksForPayload`、`insertTask`、`toggleTask`、`deleteTask` DAO 方法（保留 `IdeaTasks` 表定义和迁移逻辑）

- [ ] Task 5: 运行 build_runner + dart analyze 验证
  - 执行 `dart run build_runner build --delete-conflicting-outputs`
  - 执行 `dart analyze lib/` 确保 0 errors

# Task Dependencies
- Task 2 depends on Task 1
- Task 3, Task 4 无依赖，可与 Task 1 并行
- Task 5 depends on all tasks
