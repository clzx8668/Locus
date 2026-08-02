# Tasks

- [x] Task 1: 在 `sync_database_ext.dart` 中添加 `notifyTableUpdates` 方法
  - 导入 `TableUpdate` 和 `UpdateKind`（通过已有的 `package:drift/drift.dart`）
  - 实现方法：接收 `Map<String, int>`（table→修改行数），构建 `Set<TableUpdate>`，调用 `streamQueries.handleTableUpdates()`
  - 添加 `tableModifications` 参数为空时直接 return 的防御

- [x] Task 2: 在 `sync_service.dart` 中集成通知调用
  - 在 Pull 循环中累计每个 table 的 pulled 行数到 `tableMods`
  - 在 Push 循环中累计每个 table 的 pushed 行数到 `tableMods`
  - 在 `syncTick.value++` 之前：执行 `PRAGMA wal_checkpoint(PASSIVE)` 确保 WAL 可见
  - 在 `syncTick.value++` 之前：调用 `db.notifyTableUpdates(tableMods)` 触发 Drift 通知
  - 添加 `debugPrint` 诊断日志

- [x] Task 3: 验证端到端流程（代码审查通过，功能验证需在设备上测试）
  - 在 PC 端添加一条 Contacts 记录并同步
  - 在手机端点击同步
  - 确认 CRM 联系人列表页面在没有重启的情况下立即显示新记录
  - 确认其他页面（Idea Stream、Chat History、Calendar、Long Term Memory）同步后同样即时刷新

# Task Dependencies
- Task 1 是 Task 2 的前提（Task 2 调用 Task 1 的方法）
- Task 3 依赖于 Task 1 和 Task 2 完成
