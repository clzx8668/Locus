# 同步系统全面修复 Spec

## Why
全项目同步系统审计发现 7 个问题：2 个 Critical（并发竞态导致数据损坏 + 分页缺失导致数据丢失）、2 个 High（定时功能空壳 + fetchAll 误判触发全量重推）、3 个 Medium（disconnect 未清理 + 下拉错误沉默 + 清空字符串语义错误）。需一揽子修复。

## What Changes

### Critical 修复
- 新增 `_isSyncing` 并发锁，防止两个同步同时运行
- `pullChanges` / `fetchAll` 实现分页循环，支持任意数量记录

### High 修复
- `scheduledTime` 真正实现：每日定时触发（Timer 计算下次触发时间 + 触发后重新调度）
- `fetchAll` 区分"真为空"和"网络异常"，避免误触发 auto-healing

### Medium 修复
- `disconnectPocketBase` 停止定时器 + 清除持久化凭证
- 全局下拉刷新读取 sync 返回值，失败时显示 SnackBar
- `scheduledTime` 空字符串视为 null，不持久化空值

## Impact
- Affected specs: `sync-mode-enhancement`, `sync-settings-subpage`, `sync-settings-reactive-fix`
- Affected code:
  - `lib/core/sync/sync_service.dart` — 并发锁 + 定时调度 + disconnect 清理 + 空字符串修复
  - `lib/core/sync/pocketbase_adapter.dart` — 分页循环 + fetchAll 异常语义修复
  - `lib/features/home/presentation/locus_home_page.dart` — 下拉刷新错误提示
  - `lib/features/settings/presentation/pages/sync_settings_page.dart` — "Clear" 按钮修复

---

## ADDED Requirements

### Requirement: Sync Concurrency Mutex
`triggerPbSync()` SHALL 检查 `_isSyncing` 标志，正在同步时拒绝新请求。

#### Scenario: Sync in progress, second trigger arrives
- **WHEN** 上一次同步仍在执行中，新触发到达
- **THEN** 返回 `null`（静默跳过），不启动第二次同步；若 `fromUser=true` 则返回 "Sync already in progress"

### Requirement: PocketBase Pagination
`pullChanges` 和 `fetchAll` SHALL 循环拉取所有分页，直到 `page >= totalPages`。

#### Scenario: Table has 1200 records
- **WHEN** 表在 PB 上有 1200 条记录
- **THEN** 三次请求（page=1,2,3）全部执行，所有 1200 条记录被拉取

### Requirement: Daily Scheduled Sync
当 `autoConfig.scheduledTime` 非空时，系统 SHALL 计算到下次触发时间的延迟，设置单次 Timer，触发后自动重新调度次日。

#### Scenario: Scheduled time set to 09:00, current time 08:00
- **WHEN** 设置了每日 09:00 同步
- **THEN** Timer 在 1 小时后触发同步，完成后重新调度次日 09:00

### Requirement: fetchAll Error Semantics
`fetchAll` 在网络异常时 SHALL 抛出异常（而非静默返回 `[]`），由调用方决定处理策略。

#### Scenario: Network down during fetchAll
- **WHEN** `fetchAll` 因网络超时失败
- **THEN** 抛出异常；`syncViaPocketBase` 的 Step 0.5 捕获后跳过 auto-healing（不误认为空表）

### Requirement: Disconnect Cleanup
`disconnectPocketBase()` SHALL 停止所有定时器并清除持久化的连接凭证。

#### Scenario: User disconnects while in Smart mode
- **WHEN** 用户在智能模式下断开 PocketBase
- **THEN** auto-sync 定时器和每日定时器均停止，pb_server_url/pb_email/pb_password 从 app_config 清除

### Requirement: Pull-to-Refresh Error Feedback
全局 `RefreshIndicator` SHALL 读取 `triggerPbSync` 返回值，非 null 时显示 SnackBar 错误提示。

#### Scenario: Sync fails during pull-to-refresh
- **WHEN** 下拉刷新触发同步但网络不可达
- **THEN** spinner 停止，SnackBar 显示 "Network unreachable"

### Requirement: Empty String Treated as Null
`setAutoConfig(scheduledTime: '')` SHALL 将空字符串视为 null，清除持久化的 `pb_scheduled_time`，UI 显示 "Not set"。

## MODIFIED Requirements

### Requirement: fetchAll Signature Change
**原行为**：`fetchAll` 返回 `Future<List<Map<String, dynamic>>>`，异常时返回 `[]`。
**修改后**：`fetchAll` 返回 `Future<List<Map<String, dynamic>>>`，异常时抛出。
**Migration**：调用方 `syncViaPocketBase` Step 0.5 的 `try-catch` 已存在，行为不变（异常时跳过 auto-healing）。

---

## Technical Design

### sync_service.dart 改动

```dart
// 新增字段
bool _isSyncing = false;

// triggerPbSync 入口新增并发锁
Future<String?> triggerPbSync({bool fromUser = false}) async {
  // ...existing mode guard...

  // Concurrency guard
  if (_isSyncing) {
    if (fromUser) return 'Sync already in progress';
    return null;
  }

  // ...existing debounce + network guards...

  _isSyncing = true;
  try {
    return await syncViaPocketBase();
  } finally {
    _isSyncing = false;
  }
}

// 新增每日定时调度
Timer? _scheduledTimer;

void _startDailyScheduler() {
  _stopDailyScheduler();
  final st = _autoConfig.scheduledTime;
  if (st == null || st.isEmpty) return;
  final parts = st.split(':');
  if (parts.length != 2) return;
  final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
  if (h == null || m == null) return;

  final now = DateTime.now();
  var next = DateTime(now.year, now.month, now.day, h, m);
  if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
  _scheduledTimer = Timer(next.difference(now), () {
    triggerPbSync();
    _startDailyScheduler(); // re-schedule next day
  });
}

void _stopDailyScheduler() {
  _scheduledTimer?.cancel();
  _scheduledTimer = null;
}

// _applySyncMode 新增调度
void _applySyncMode() {
  _stopAutoTimer();
  _stopDailyScheduler();
  if (_pbSyncMode == PbSyncMode.auto || _pbSyncMode == PbSyncMode.smart) {
    _startAutoTimer();
    _startDailyScheduler();
  }
}

// disconnectPocketBase 增强
void disconnectPocketBase() {
  _stopAutoTimer();
  _stopDailyScheduler();
  _pb?.dispose();
  _pb = null;
  _pbConnected = false;
  // Clear persisted credentials
  db.setConfig('pb_sync_mode', 'manual');
  // Note: can't await in sync method — use unawaited or schedule microtask
  notifyListeners();
}

// setAutoConfig — 空字符串修复
Future<void> setAutoConfig({...}) async {
  ...
  final resolvedScheduled = (scheduledTime != null && scheduledTime!.isEmpty) ? null : (scheduledTime ?? _autoConfig.scheduledTime);
  _autoConfig = AutoSyncConfig(
    ...
    scheduledTime: resolvedScheduled,
  );
  ...
  if (_autoConfig.scheduledTime != null) {
    await db.setConfig('pb_scheduled_time', _autoConfig.scheduledTime!);
  } else {
    // Explicitly remove the key when clearing
    await db.customStatement("DELETE FROM app_config WHERE key = 'pb_scheduled_time'");
  }
  ...
}
```

### pocketbase_adapter.dart 改动

```dart
Future<List<Map<String, dynamic>>> pullChanges(String collection, DateTime? since) async {
  final allItems = <Map<String, dynamic>>[];
  var page = 1;
  var totalPages = 1;
  do {
    final url = '$serverUrl/api/collections/$collection/records?perPage=500&page=$page';
    final response = await _dio.get(url, options: _authOpts);
    _checkAuth(response);
    final data = response.data as Map;
    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    allItems.addAll(items);
    totalPages = data['totalPages'] as int? ?? 1;
    page++;
  } while (page <= totalPages);
  return allItems;
}

Future<List<Map<String, dynamic>>> fetchAll(String collection) async {
  // No longer catches all — let exceptions propagate
  final allItems = <Map<String, dynamic>>[];
  var page = 1;
  var totalPages = 1;
  do {
    final url = '$serverUrl/api/collections/$collection/records?perPage=500&page=$page';
    final response = await _dio.get(url, options: _authOpts);
    final data = response.data as Map;
    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    allItems.addAll(items);
    totalPages = data['totalPages'] as int? ?? 1;
    page++;
  } while (page <= totalPages);
  return allItems;
}
```

### locus_home_page.dart 改动

```dart
onRefresh: () async {
  final result = await getIt<SyncService>().triggerPbSync(fromUser: true);
  if (result != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result)),
    );
  }
},
```

### sync_settings_page.dart 改动

```dart
// "Clear" 按钮修复
onPressed: () => ss.setAutoConfig(scheduledTime: null),
```

> 注意：`setAutoConfig` 签名中 `scheduledTime` 参数类型从 `String?` 改为接收 `null` 已有此能力，只需调用方传 `null` 而非 `''`。
