# Sync UI Refresh Fix Spec

## Why
PocketBase 同步将数据写入本地 SQLite 后，Drift 的 `.watch()` 流不触发更新，导致 UI 不刷新。用户需重启应用才能看到同步来的新记录。之前的 `ValueListenableBuilder(syncTick)` + `ValueKey` 方案因 Flutter 重建机制与 Drift 查询缓存的交互问题，实际未完全生效。

## What Changes
- **根因修复**：同步完成后通过 Drift 的 `streamQueries.handleTableUpdates()` 主动触发所有 `.watch()` 流重查
- **诊断增强**：sync 日志中记录触发了哪些表的更新通知
- **移除 Key hack**：`ValueKey('sync_$tick')` 方案作为辅助保留，但依赖根因修复为主要生效路径
- **同步后 WAL checkpoint**：确保 WAL 模式下写入对后续查询可见

## Impact
- Affected specs: 无（新问题修复）
- Affected code:
  - `lib/core/sync/sync_service.dart` — sync 完成后触发 Drift 更新通知 + WAL checkpoint
  - `lib/core/sync/sync_database_ext.dart` — 添加 `notifyTableUpdates` 方法
  - 8 个 UI 页面 — 已有的 `ValueListenableBuilder(syncTick)` 无需修改，但受益于此修复

## Root Cause Analysis

### 技术链路
```
syncViaPocketBase()
  └→ applyRemoteChange() → customStatement(INSERT/UPDATE)  ← raw SQL, bypasses Drift ORM
  └→ markSynced() → customStatement(UPDATE sync_status)      ← 同上
  
Drift .watch() 依赖:
  └→ UpdateKind 追踪 (insert/update/delete 经过 typed API 时设置)
  └→ customStatement 不经过 typed API → UpdateKind 不触发 → .watch() 流不发射
```

### 为什么 ValueKey 方案不完全生效
`ValueKey('sync_$tick')` 迫使 `StreamBuilder` 卸载重建，新 `StreamBuilder` 创建新 `.watch()` 订阅。
`.watch()` 首次订阅时会执行初始查询并返回当前 DB 状态。

但问题在于：
1. **SQLCipher WAL 模式**：`customStatement` 写入的数据可能仍在 WAL 文件中，未 checkpoint 到主数据库文件。后续读查询通过另一个连接可能看不到这些数据。
2. **Drift 内部查询缓存**：`StreamQuery` 可能缓存上次查询结果，新建订阅时可能复用缓存而非重新查询。

### 正确修复路径
Drift 的 `GeneratedDatabase` 暴露 `streamQueries` 属性（`StreamQueryStore`），提供 `handleTableUpdates(Set<TableUpdate>)` 方法，用于手动触发所有注册的流查询重查。这是 Drift 内部用于通知 `.watch()` 的机制。

## ADDED Requirements

### Requirement: Sync triggers Drift watch notifications
同步服务在完成 Pull/Push 后，SHALL 通过 `db.streamQueries.handleTableUpdates()` 通知所有 `.watch()` 订阅者数据已变更。

#### Scenario: Pull records trigger UI refresh
- **GIVEN** 手机端打开 CRM 联系人页面（`StreamBuilder` 监听 `db.watchAllContacts()`）
- **WHEN** 用户点击同步，Pull 到 5 条新联系人
- **THEN** CRM 页面自动显示这 5 条新联系人，无需手动刷新或重启

#### Scenario: Push records trigger local UI refresh
- **GIVEN** PC 端添加了一条新笔记
- **WHEN** 同步 Push 完成后 `markSynced` 更新 `sync_status`
- **THEN** 笔记列表页面的 `StreamBuilder` 自动刷新

### Requirement: WAL checkpoint after sync
同步完成后 SHALL 执行 `PRAGMA wal_checkpoint(PASSIVE)` 确保 WAL 日志中的数据对后续查询可见。

### Requirement: Diagnostic logging
同步日志 SHALL 包含触发了哪些表的更新通知，以及每个表修改的行数。

## Technical Design

### 实现方案：`notifyTableUpdates` in sync_database_ext.dart

```dart
/// Notify Drift's stream query system about table modifications.
/// Must be called after sync completes to trigger .watch() subscribers.
/// This is necessary because sync writes use customStatement (raw SQL)
/// which bypasses Drift's ORM-level update tracking.
Future<void> notifyTableUpdates(Map<String, int> tableModifications) async {
  if (tableModifications.isEmpty) return;
  
  final updates = tableModifications.entries.map((e) => TableUpdate(
    table: e.key,
    kind: UpdateKind.update,
  )).toSet();
  
  streamQueries.handleTableUpdates(updates);
}
```

### 调用点：sync_service.dart syncViaPocketBase() 末尾

```dart
// After push loop completes and before syncTick:
final tableMods = <String, int>{};
// ... during pull/push, accumulate: tableMods[table] = (tableMods[table] ?? 0) + 1;

// WAL checkpoint to ensure visibility
await db.customStatement('PRAGMA wal_checkpoint(PASSIVE)');

// Trigger Drift watch notifications
await db.notifyTableUpdates(tableMods);
debugPrint('PB sync: notified ${tableMods.length} tables: $tableMods');

syncTick.value++;
notifyListeners();
```
