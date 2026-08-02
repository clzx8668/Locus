# 同步模式二级设置页 Spec

## Why
当前同步模式选择是一个简单的 Dialog（三选一），自动/智能模式的配置项（间隔、定时时间）以内联行的方式显示在设置页主卡片中。这种平铺方式信息密度低，各模式的差异配置无法清晰展开。需要将同步模式选择升级为独立的二级设置页，每种模式拥有专属的配置区域。

## What Changes

### 新增同步设置子页面
- 创建 `sync_settings_page.dart` 作为独立二级页面
- 从设置页主卡片导航进入，展示当前选中的同步模式及对应的配置项

### 各模式配置区域
- **手动模式**：仅显示说明文字，无额外配置项
- **自动模式**：同步频率选择 + 每日定时时间设置
- **智能模式**：同步频率选择 + 每日定时时间设置 + 生命周期触发开关（resumed / paused）

### UI 升级
- 模式选择从 SimpleDialog 改为 SegmentedButton（三选项分段按钮），更直观
- 配置项使用 Switch / Slider / TimePicker 等富交互控件
- 添加每个配置项的描述文字，减少用户理解成本

### 基础设施增强
- `AutoSyncConfig` 新增 `syncOnResume` / `syncOnPause` 字段（智能模式专用）
- `main.dart` 中 `didChangeAppLifecycleState` 根据配置决定是否触发同步
- 持久化智能模式开关到 `app_config`

## Impact
- Affected specs: `sync-mode-enhancement`（上游已完成）
- Affected code:
  - **新增** `lib/features/settings/presentation/pages/sync_settings_page.dart`
  - `lib/features/settings/presentation/pages/settings_page.dart` — 同步模式 tile 改为导航到子页面
  - `lib/core/sync/sync_service.dart` — `AutoSyncConfig` 新增字段、`setAutoConfig` 扩展
  - `lib/main.dart` — 生命周期回调根据配置开关判断

---

## ADDED Requirements

### Requirement: Sync Settings Sub-Page Navigation
系统 SHALL 在设置页中提供"Sync Mode"入口，点击后导航至独立的同步设置子页面。

#### Scenario: Navigate to sync settings
- **WHEN** 用户在设置页点击"Sync Mode"行
- **THEN** Navigator 推入 `SyncSettingsPage`，显示完整的同步模式配置界面

### Requirement: Mode Switch via SegmentedButton
同步设置子页面 SHALL 使用 `SegmentedButton<PbSyncMode>` 切换三种同步模式。

#### Scenario: Switch mode via segmented button
- **WHEN** 用户点击 SegmentedButton 中的 auto
- **THEN** 页面立即切换到自动模式，下方显示自动模式的专属配置区域

### Requirement: Auto Mode Configuration
自动模式 SHALL 展示以下配置项：
- 同步频率选择（1min ~ 24h，共 10 档，使用下拉或滑块）
- 每日定时同步时间（可选，TimePicker）
- 每项配置附带描述文字说明其作用

#### Scenario: Configure auto sync interval
- **WHEN** 用户在自动模式下选择同步频率为"30 min"
- **THEN** 系统按 30 分钟间隔自动触发同步

### Requirement: Smart Mode Configuration
智能模式 SHALL 展示自动模式全部配置项，外加：
- "前台恢复时同步"开关（syncOnResume，默认开）
- "后台暂停时同步"开关（syncOnPause，默认开）

#### Scenario: Disable pause-triggered sync
- **WHEN** 用户在智能模式下关闭"后台暂停时同步"
- **THEN** 应用进入后台时不再触发同步，仅前台恢复时触发

### Requirement: Manual Mode Info
手动模式 SHALL 仅显示说明文字："仅在点击 Sync Now 或下拉刷新时触发同步"，无配置项。

## MODIFIED Requirements

### Requirement: Smart Sync Lifecycle Triggers (from sync-mode-enhancement)
**原行为**：智能模式下 `resumed` 和 `paused` 无条件触发同步。
**修改后**：根据用户配置的 `syncOnResume` / `syncOnPause` 开关决定是否触发。
**Migration**：已有智能模式用户默认两个开关均为 true（行为不变）。

---

## Technical Design

### 新文件：`sync_settings_page.dart`
```
SyncSettingsPage (StatefulWidget)
├── SegmentedButton<PbSyncMode> — 模式切换
├── [Auto/Smart] 频率选择区域
│   ├── 描述文字："同步频率 — 系统将按此间隔自动同步数据"
│   └── SegmentedButton / DropdownButton — 频率选项
├── [Auto/Smart] 定时时间区域  
│   ├── 描述文字："每日定时 — 可选，每天固定时间触发一次同步"
│   └── ListTile → TimePicker — 时间选择
├── [Smart Only] 生命周期触发区域
│   ├── 描述文字："应用事件触发 — 在以下场景自动同步"
│   ├── SwitchListTile — "前台恢复时同步"
│   └── SwitchListTile — "后台暂停时同步"
└── [Manual Only] 说明文字区域
```

### 修改：`AutoSyncConfig`
```dart
class AutoSyncConfig {
  final int intervalMinutes;
  final String? scheduledTime;
  final bool syncOnResume;   // 新增：智能模式 — 前台恢复触发
  final bool syncOnPause;    // 新增：智能模式 — 后台暂停触发

  const AutoSyncConfig({
    this.intervalMinutes = 15,
    this.scheduledTime,
    this.syncOnResume = true,
    this.syncOnPause = true,
  });
}
```

### 修改：`SyncService`
- `setAutoConfig()` 扩展，新增持久化 `sync_on_resume` / `sync_on_pause`
- `init()` 恢复时读取上述 key

### 修改：`main.dart`
```dart
void didChangeAppLifecycleState(AppLifecycleState state) {
  final ss = getIt<SyncService>();
  if (ss.pbSyncMode != PbSyncMode.smart) return;
  if (state == AppLifecycleState.resumed && ss.autoConfig.syncOnResume) {
    ss.triggerPbSync();
  } else if (state == AppLifecycleState.paused && ss.autoConfig.syncOnPause) {
    ss.triggerPbSync();
  }
}
```

### 修改：`settings_page.dart`
- "Sync Mode" tile 的 `onTap` 从 `_pickSyncMode()` 改为 `Navigator.push` 到 `SyncSettingsPage`
- 移除内联的 interval / scheduled time 行（交由子页面展示）
- 保留 `_syncModeLabel()` 显示当前模式
- "Sync Now" 按钮保持不变
