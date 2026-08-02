# Tasks

- [x] Task 1: 修复并发竞态 — 新增 `_isSyncing` 同步锁
  - `SyncService` 新增 `_isSyncing` 字段
  - `triggerPbSync()` 入口检查：`_isSyncing` 时拒绝新请求（fromUser 时返回提示）
  - `syncViaPocketBase()` 执行前后设置/清除 `_isSyncing`（try-finally）

- [x] Task 2: 修复分页缺失 — pullChanges/fetchAll 实现循环分页
  - 两个方法均改为 `do { ... } while (page <= totalPages)` 循环结构
  - 读取 PB 返回的 `totalPages` 字段
  - `fetchAll` 移除 try-catch（异常向上抛，由 Step 0.5 的已有 catch 处理）

- [x] Task 3: 实现每日定时调度 + disconnect 清理 + 空字符串修复
  - 新增 `_scheduledTimer` 字段和 `_startDailyScheduler()`/`_stopDailyScheduler()` 方法
  - `_applySyncMode()` 中调用 daily scheduler 启停
  - `disconnectPocketBase()` 增加 `_stopAutoTimer()` + `_stopDailyScheduler()` + 清除 `pb_server_url`/`pb_email`/`pb_password` 配置
  - `setAutoConfig()` 中 `scheduledTime` 参数：空字符串 → null

- [x] Task 4: 修复下拉刷新错误提示
  - `locus_home_page.dart` `onRefresh` 读取 `triggerPbSync` 返回值
  - 非 null 时 `ScaffoldMessenger.showSnackBar` 显示错误

- [x] Task 5: 修复子页面 "Clear" 按钮
  - `sync_settings_page.dart` 中 Clear 按钮 `onPressed` 改为 `ss.setAutoConfig(scheduledTime: null)`

- [x] Task 6: 全项目分析验证
  - `flutter analyze` 14 个既有 issue，零新增

# Task Dependencies
- Task 1 和 Task 2 无依赖，可并行
- Task 3 依赖 Task 1（共享 `_applySyncMode` 改动）
- Task 4 和 Task 5 独立，可随时并行
- Task 6 依赖所有 Tasks
