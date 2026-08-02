# Tasks

- [ ] Task 0: 移除 LAN 直连同步代码
  - 删除文件：`sync_server.dart`、`sync_client.dart`、`discovery_service.dart`
  - 清理 `sync_service.dart`：移除 `SyncMode` 枚举、`_mode`/`_status`/`connectedDevice`、`_startServer()`、`_startClient()`、`_connectToServer()`、`syncNow()`(LAN)、`_autoSyncTimer`、`_discoveryService`、`_syncServer`、`_syncClient`、`_deviceSubscription`、`deviceId`、`deviceName`、`discoveredDevices`、`onDeviceFound`
  - 清理 `sync_protocol.dart`：仅保留 `SyncChange`、`SyncOp`（被 `sync_database_ext` 使用），删除 `DeviceInfo`、`SyncPushRequest`、`SyncPushResponse`、`SyncPullRequest`、`SyncPullResponse`、`SyncResult`
  - 清理 `settings_page.dart`：删除整个 "Data Sync" 区域（SyncMode 选择器、状态、设备列表、Server Port）
  - 清理 `service_locator.dart`：移除 `SyncClient`/`SyncServer`/`DiscoveryService` 注册（如有）
  - 保留不动：`sync_database_ext.dart`、`pocketbase_adapter.dart`

- [ ] Task 1: 重构 SyncService — 新增 PbSyncMode 和同步基础设施
  - 新增 `PbSyncMode` 枚举（manual / auto / smart）
  - 新增 `_lastSyncEndTime` 字段和 `_canSyncNow` 防抖检查
  - 新增 `isNetworkReachable()` 网络检测方法（复用 `healthCheck`）
  - 新增 `triggerPbSync()` 统一入口（网络检测 + 防抖 + 模式判断）
  - 持久化 `pb_sync_mode` 到 `app_config`
  - 添加 5 秒超时到 Dio 配置（PocketBaseAdapter）

- [ ] Task 2: 实现自动同步定时器
  - 新增 `AutoSyncConfig` 类（intervalMinutes + scheduledTime）
  - 实现 `_startAutoTimer()`：按 intervalMinutes 启动 `Timer.periodic`
  - 实现 `_scheduleNextDailySync()`：计算到期时间，单次 Timer 触发
  - 实现 `_stopAutoTimer()` / `_stopScheduledTimer()`：清理定时器
  - 在 `setPbSyncMode()` 中自动启停定时器
  - 持久化 `pb_auto_interval` 和 `pb_scheduled_time` 到 `app_config`

- [ ] Task 3: 实现智能同步的应用生命周期触发
  - 在 `LocusApp` 中 mixin `WidgetsBindingObserver`
  - `didChangeAppLifecycleState`：`resumed` 时调用 `triggerPbSync()`（仅在智能模式）
  - `paused` 时调用无等待轻量推送 `_quickPushOnly()`（尽力而为）
  - 启动时检查是否错过了定时同步并补偿执行

- [ ] Task 4: 实现全局下拉刷新
  - 在 `LocusHomePage` 的 `IndexedStack` 外层包装 `RefreshIndicator`
  - `onRefresh` 调用 `triggerPbSync()`
  - 同步完成后 `RefreshIndicator` 动画自然结束

- [ ] Task 5: 更新设置页面 UI
  - "PocketBase Sync" 区域新增同步模式选择器（Dialog: manual/auto/smart）
  - 自动模式下展开显示间隔选择 + 定时时间选择
  - "Sync Now" 按钮贯穿所有模式

- [ ] Task 6: 验证端到端流程
  - 手动模式：只有点击按钮才同步
  - 自动模式：按设置间隔自动触发
  - 智能模式：启动/退出/定时/下拉 四种场景均触发
  - 网络不通时提示"网络不可达"
  - 10 秒防抖生效

# Task Dependencies
- Task 0 是必须首先完成的清理任务
- Task 1 是所有后续任务的基础
- Task 2/3/4 依赖 Task 1，三者可并行
- Task 5 依赖 Task 1 + Task 2
- Task 6 依赖所有 Tasks
