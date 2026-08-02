# 同步机制增强方案 Spec

## Why
当前同步仅支持手动按钮触发（PocketBase）和 LAN 模式下的固定 30 秒周期定时器。缺少灵活的同步策略（自动/手动/智能），没有网络连通性检测，没有防抖动保护，也没有应用生命周期感知。需要建立一套完整的同步控制体系来适配个人助理的多场景使用需求。

## What Changes

### 新增三个同步模式
- **手动同步**：保持当前 LAN client 模式的定时器行为，PB 同步仅通过按钮触发
- **自动同步**：用户可配置同步周期（频率 + 定时规则），系统按规则自动触发 PB 同步
- **智能同步**：综合四类触发场景的智能模式

### 新增基础设施
- 网络连通性检测（同步前必检）
- 同步防抖动（短时间内拒绝重复触发）
- 应用生命周期监听（启动/退出时触发同步）
- 全局下拉刷新（所有内容页滑动到顶继续下拉触发同步）
- **BREAKING**：移除 LAN 直连同步（`SyncMode` 枚举、`SyncServer`、`SyncClient`、`DiscoveryService`），统一使用 PocketBase 同步

### 新增 UI
- 设置页 "PocketBase Sync" 区域新增同步模式选择器
- 自动同步模式下的周期配置控件（频率滑块/下拉 + 定时时间选择）
- 同步状态指示增强

## Impact
- Affected specs: 无（新功能）
- Affected code:
  - `lib/core/sync/sync_service.dart` — 新增 `PbSyncMode` 枚举、网络检测、防抖、生命周期
  - `lib/core/sync/pocketbase_adapter.dart` — 网络连通性检测增强
  - `lib/features/settings/presentation/pages/settings_page.dart` — 新增同步模式 UI
  - `lib/features/home/presentation/locus_home_page.dart` — 下拉刷新集成
  - `lib/main.dart` — 初始化时注册生命周期监听
  - 8 个内容页面 — 可选：添加下拉刷新包装

---

## 技术可行性分析

### 1. 网络连通性检测

**现有基础**：`PocketBaseAdapter.healthCheck()` 已实现（访问 `/api/health`），可直接复用。

**增强方案**：
```dart
Future<bool> isNetworkReachable() async {
  if (_pb == null || !_pbConnected) return false;
  try {
    return await _pb!.healthCheck();
  } catch (_) {
    return false;
  }
}
```
`healthCheck` 内已有 `try-catch` 兜底，网络不通时返回 `false`。添加超时配置（当前 Dio 默认无超时），建议设 5 秒超时避免长时间卡住。

**风险点**：无。`healthCheck` 已稳定运行。

### 2. 防抖动机制

**方案**：在 `SyncService` 中维护 `_lastSyncTime` 和最小间隔常量 `_minSyncInterval`。

```dart
static const _minSyncInterval = Duration(seconds: 10);

bool get _canSyncNow {
  if (_lastSyncEndTime == null) return true;
  return DateTime.now().difference(_lastSyncEndTime!) >= _minSyncInterval;
}
```

同步入口 `syncViaPocketBase()` 开头加守卫：
```dart
if (!_canSyncNow) return 'Sync throttled (minimum interval: ${_minSyncInterval.inSeconds}s)';
```

对于智能模式的多次触发（启动+定时叠加），防抖确保短时间内只执行一次。

**风险点**：`_minSyncInterval` 需要权衡——太短无效，太长影响体验。10 秒是合理默认值。

### 3. 应用生命周期监听

**方案**：使用 `WidgetsBindingObserver` 在 `LocusApp`（MaterialApp 层级）注册。

```dart
class _LocusAppState extends State<LocusApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用回到前台 — 智能模式触发同步
    } else if (state == AppLifecycleState.paused) {
      // 应用进入后台 — 智能模式触发同步
    }
  }
}
```

**关于"退出前触发"的技术限制**：
Flutter 的 `AppLifecycleState.detached` 或 `paused` 状态下，异步操作（网络请求）可能被系统杀死而无法完成。这是平台限制，无法 100% 保证。

**替代方案**：使用 `paused` 状态触发同步（此时应用仍在内存中，有 10-30 秒时间窗口）。同时配合"恢复时触发"（`resumed`）作为补偿——如果退出时没来得及同步，下次启动回到前台时自动触发。

**风险点**：
- Android 对后台网络请求有限制，大同步可能超时
- 不保证 100% 退出前同步完成
- 建议：退出前仅做轻量推送（只推变更记录，不做全量拉取）

### 4. 下拉刷新（Pull-to-Refresh）

**方案**：使用 Flutter 内置 `RefreshIndicator`。

实现选项：
- **选项 A**：在每个内容页单独包装 `RefreshIndicator` — 侵入性强，每个页面都要改
- **选项 B**：在 `LocusHomePage` 的 `IndexedStack` 外层包装统一 `RefreshIndicator` — 一处改动覆盖所有页面
- **选项 C（推荐）**：使用全局回调机制——`SyncService` 暴露一个 `triggerSync` 方法，各页面在 `RefreshIndicator.onRefresh` 中调用

选择 **选项 C**：最灵活，既支持统一包装也支持各页面独立添加。同时与"智能模式 b. 退出前触发"共用同一个 `triggerSync` 方法。

### 5. 定时同步规则

**方案**：使用 `Timer.periodic` + 用户配置的间隔。

配置模型：
```dart
class AutoSyncConfig {
  final int intervalMinutes; // 5, 10, 15, 30, 60
  final TimeOfDay? scheduledTime; // 可选：每天的固定时间（如每天 9:00）
  final bool enabled;
}
```

- 简单模式：每 N 分钟同步一次（`Timer.periodic`）
- 定时模式：每天指定时间同步（计算到下次触发的时间，设置单次 Timer，完成后重新计算）

**风险点**：
- 定时器在应用被杀死后不再触发（平台限制）
- 配合 `resumed` 生命周期事件补偿：回到前台时检查是否错过了定时同步

### 6. 同步模式独立于 LAN SyncMode

当前 `SyncMode` 是 LAN 直连的枚举（`server/client/disabled`），不应与之混淆。新增独立枚举 `PbSyncMode`：

```dart
enum PbSyncMode { manual, auto, smart }
```

持久化到 `app_config` key `pb_sync_mode`。

---

## ADDED Requirements

### Requirement: PocketBase Sync Mode Selection
系统 SHALL 支持三种 PocketBase 同步模式：手动、自动、智能，用户可在设置页面切换。

#### Scenario: User selects manual mode
- **WHEN** 用户选择"手动同步"模式
- **THEN** 系统不再自动触发任何 PB 同步，仅在用户点击同步按钮时执行

#### Scenario: User selects auto mode
- **WHEN** 用户选择"自动同步"模式
- **THEN** 系统按用户配置的周期规则自动触发 PB 同步

#### Scenario: User selects smart mode
- **WHEN** 用户选择"智能同步"模式
- **THEN** 系统在四类场景下触发同步：a) 应用启动完成时 b) 应用退出前 c) 按周期定时 d) 手动/下拉触发

### Requirement: Network Connectivity Pre-check
所有同步操作执行前 SHALL 先检测与 PocketBase 服务器的网络连通性，不通则直接终止。

#### Scenario: Network disconnected
- **WHEN** 同步被触发但 `healthCheck()` 返回 false
- **THEN** 同步立即终止，UI 显示"网络不可达"提示

#### Scenario: Network connected
- **WHEN** 同步被触发且 `healthCheck()` 返回 true
- **THEN** 同步正常执行

### Requirement: Sync Debounce
系统 SHALL 限制同步最小间隔为 10 秒，短时间内重复触发被忽略。

#### Scenario: Rapid consecutive triggers
- **WHEN** 用户快速连续点击同步按钮（间隔 < 10 秒）
- **THEN** 第二次及后续点击被忽略，显示"同步频率过高，请稍后重试"

#### Scenario: Normal interval trigger
- **WHEN** 距离上次同步结束已超过 10 秒
- **THEN** 同步正常执行

### Requirement: Auto Sync Configuration
自动同步模式 SHALL 允许用户配置同步间隔（5/10/15/30/60 分钟）和可选的每日定时时间。

#### Scenario: Configure sync interval
- **WHEN** 用户设置同步间隔为 15 分钟
- **THEN** 系统每 15 分钟自动触发一次同步（仅在自动或智能模式下）

#### Scenario: Configure scheduled time
- **WHEN** 用户设置每日 9:00 定时同步
- **THEN** 系统在每天 9:00 触发同步（仅在自动或智能模式下）

### Requirement: Smart Sync Triggers
智能同步模式 SHALL 在以下场景触发：
- **启动触发**：应用 `resumed` 且距上次同步超过最小间隔
- **退出触发**：应用进入 `paused` 状态时（尽力而为）
- **周期触发**：兼容自动同步的全部配置规则
- **手动触发**：按钮点击 + 任何内容页面下拉刷新

#### Scenario: App resumed triggers sync
- **WHEN** 用户将应用从后台切回前台（已超过 10 秒间隔）
- **THEN** 自动触发一次同步

#### Scenario: Pull-to-refresh triggers sync
- **WHEN** 用户在任意内容页滑动到顶部并继续下拉
- **THEN** 触发同步操作，完成后显示刷新完成提示

### Requirement: Pull-to-Refresh
系统 SHALL 在首页及所有内容页面（Idea Stream、CRM、Calendar、AI Hub、Chat History、Memory）支持下拉刷新触发同步。

#### Scenario: Pull down on CRM page
- **WHEN** 用户在 CRM 页面列表顶部下拉
- **THEN** `RefreshIndicator` 显示加载动画，调用 `syncViaPocketBase()`，完成后动画消失

---

## Technical Design

### 新增类：`PbSyncMode`（sync_service.dart）
```dart
enum PbSyncMode { manual, auto, smart }
```

### 新增类：`AutoSyncConfig`（同步配置模型）
```dart
class AutoSyncConfig {
  final int intervalMinutes;  // 5, 10, 15, 30, 60
  final TimeOfDay? scheduledTime; // e.g. 09:00
  
  const AutoSyncConfig({this.intervalMinutes = 15, this.scheduledTime});
  
  Duration get interval => Duration(minutes: intervalMinutes);
}
```

### 修改：SyncService 新增字段和方法
```dart
// 新增字段
PbSyncMode _pbSyncMode = PbSyncMode.manual;
DateTime? _lastSyncEndTime;
Timer? _autoPbTimer;
Timer? _scheduledTimer;
static const _minSyncInterval = Duration(seconds: 10);

// 网络检测
Future<bool> isNetworkReachable() async { ... }

// 防抖检查
bool get _canSyncNow { ... }

// 同步触发入口（统一守卫：网络 + 防抖）
Future<String?> triggerPbSync() async {
  if (_pbSyncMode == PbSyncMode.manual && !_forceTrigger) return null;
  if (!_canSyncNow) return 'Sync throttled';
  if (!await isNetworkReachable()) return 'Network unreachable';
  return await syncViaPocketBase();
}

// 定时器管理
void _startAutoTimer() { ... }
void _stopAutoTimer() { ... }
void _scheduleNextDailySync() { ... }
```

### 修改：LocusHomePage 集成下拉刷新
```dart
// IndexedStack 外层包装 RefreshIndicator
// onRefresh 调用 getIt<SyncService>().triggerPbSync()
```

### 修改：SettingsPage 新增 UI
- 同步模式选择器（manual / auto / smart 三选项 Dialog）
- 自动模式下显示间隔选择（DropdownButton: 5/10/15/30/60 分钟）
- 自动模式下显示定时时间选择（TimePicker）

### 修改：main.dart 或 LocusApp 注册生命周期
```dart
// LocusApp 添加 WidgetsBindingObserver
// didChangeAppLifecycleState 中触发智能同步
```

## REMOVED Requirements

### Requirement: LAN Direct Sync (SyncMode)
**Reason**: LAN 点对点同步与 PocketBase 同步功能完全重叠。PocketBase 方案更成熟（有 auto-healing、FK 解析、WAL checkpoint、schema 自动创建），LAN 方案仅为原型级别（有 Push-first 排序错误、无错误恢复、无断线重连）。统一使用 PocketBase 避免维护两套同步代码。

**Migration**: 
- 删除 `sync_server.dart`、`sync_client.dart`、`discovery_service.dart`
- 删除 `sync_service.dart` 中的 `SyncMode` 枚举、`_startServer()`、`_startClient()`、`_connectToServer()`、`syncNow()`(LAN版)、`_autoSyncTimer`
- 删除 `sync_protocol.dart` 中的 LAN 协议模型（如 `SyncPushRequest`、`SyncPushResponse`、`SyncPullRequest`、`SyncPullResponse`、`DeviceInfo`）
- 删除设置页的 "Data Sync" 区域（LAN SyncMode 选择器、状态显示、设备列表）
- 保留 `sync_database_ext.dart`（同时被 PB 同步使用）
- 保留 `sync_protocol.dart` 中的 `SyncChange`、`SyncOp`（被 sync_database_ext 使用）
