# 自动重连 PocketBase Spec

## Why
当前 `init()` 仅恢复同步模式和配置，不恢复 PocketBase 连接。凭证（URL/邮箱/密码）已持久化，但用户每次启动应用都需要手动进入设置页点击 "Connect"。应该在启动时自动尝试连接之前已保存的服务器。

## What Changes
- `init()` 增加自动重连逻辑：读取持久化的连接凭证，静默尝试连接
- 连接成功 → `_pbConnected = true` + `notifyListeners()` + 启动定时器（如果 auto/smart 模式）
- 连接失败 → 静默跳过，保持 `_pbConnected = false`，不弹错误提示
- 调整 `init()` 顺序：先恢复配置 → 自动重连 → 再 `_applySyncMode()`

## Impact
- Affected specs: `sync-comprehensive-fix`
- Affected code: `lib/core/sync/sync_service.dart` — `init()` 方法增强

---

## ADDED Requirements

### Requirement: Auto-Reconnect on Startup
系统 SHALL 在 `init()` 时检测是否存在持久化的 PocketBase 连接凭证，若存在则自动尝试连接。

#### Scenario: Saved credentials exist and server is reachable
- **WHEN** 应用启动，`pb_server_url`/`pb_email`/`pb_password` 均有值且服务器在线
- **THEN** 自动认证并连接成功，`_pbConnected = true`，`notifyListeners()` 触发 UI 刷新，设置页显示 "Connected" 状态；若 sync mode 为 auto/smart，定时器立即开始工作

#### Scenario: Saved credentials exist but server is unreachable
- **WHEN** 应用启动，凭证存在但服务器离线（如不在局域网内）
- **THEN** 静默失败，`_pbConnected` 保持 false，不显示任何错误提示；用户可在设置页手动 "Connect" 重试

#### Scenario: No saved credentials
- **WHEN** 应用首次启动或从未连接过 PocketBase
- **THEN** 无自动重连尝试，`_pbConnected = false`，行为不变

## MODIFIED Requirements

### Requirement: init() Sequence
**原行为**：`init()` 仅恢复模式/配置 → `_applySyncMode()`。
**修改后**：`init()` 恢复模式/配置 → `_tryAutoConnect()` → `_applySyncMode()`。
**Migration**：对已有用户透明，效果等同于手动点 Connect（如果网络可达）。

---

## Technical Design

### `init()` 改动

```dart
Future<void> init() async {
  // 1. Restore persisted sync mode and auto-config
  final savedMode = await db.getConfig('pb_sync_mode');
  if (savedMode != null) {
    _pbSyncMode = PbSyncMode.values.firstWhere(
      (e) => e.name == savedMode,
      orElse: () => PbSyncMode.manual,
    );
  }
  // ... restore autoConfig fields ...

  // 2. Try auto-connect if credentials exist
  await _tryAutoConnect();

  // 3. Start timers if applicable (now with _pbConnected potentially true)
  _applySyncMode();
}

Future<void> _tryAutoConnect() async {
  final savedUrl = await db.getConfig('pb_server_url');
  final savedEmail = await db.getConfig('pb_email');
  final savedPassword = await db.getConfig('pb_password');
  if (savedUrl == null || savedEmail == null || savedPassword == null) return;

  try {
    _pb = PocketBaseAdapter(serverUrl: savedUrl);
    final authErr = await _pb!.auth(email: savedEmail, password: savedPassword);
    if (authErr != null) return;
    final healthy = await _pb!.healthCheck();
    if (!healthy) return;
    _pbConnected = true;
    notifyListeners();
    debugPrint('PB auto-reconnect: success ($savedUrl)');
  } catch (e) {
    debugPrint('PB auto-reconnect: failed ($e)');
    _pb?.dispose();
    _pb = null;
  }
}
```

注：`_tryAutoConnect` 不调用 `ensureCollections()` — schema 一致性检查仅在实际用户操作连接时执行，避免启动时额外的网络开销。
