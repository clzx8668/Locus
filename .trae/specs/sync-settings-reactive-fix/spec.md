# 同步模式选择响应式反馈修复 Spec

## Why
`SyncSettingsPage` 子页面使用 `ListenableBuilder` 绑定 `SyncService`，期望在模式切换、频率选择、开关切换时 UI 即时响应。但 `setPbSyncMode()` 和 `setAutoConfig()` 两个方法修改内部状态后均未调用 `notifyListeners()`，导致 `ListenableBuilder` 不重建，UI 僵死不反馈，只有退出子页面后主设置页因路由切换被动重建才反映出变更。

## What Changes
- `setPbSyncMode()` 末尾增加 `notifyListeners()` 调用
- `setAutoConfig()` 末尾增加 `notifyListeners()` 调用

## Impact
- Affected specs: `sync-settings-subpage`（修复其缺陷）
- Affected code: `lib/core/sync/sync_service.dart`（2 行新增）

---

## MODIFIED Requirements

### Requirement: setPbSyncMode shall notify listeners
`setPbSyncMode()` 在更新 `_pbSyncMode` 并持久化后，SHALL 调用 `notifyListeners()` 使 `ListenableBuilder` 重建。

#### Scenario: User switches mode in SegmentedButton
- **WHEN** 用户在子页面点击 SegmentedButton 切换同步模式
- **THEN** UI 立即更新：按钮选中态切换、下方配置区域切换

### Requirement: setAutoConfig shall notify listeners
`setAutoConfig()` 在更新 `_autoConfig` 并持久化后，SHALL 调用 `notifyListeners()` 使 `ListenableBuilder` 重建。

#### Scenario: User changes frequency or toggles
- **WHEN** 用户在子页面点击 ChoiceChip 切换频率 / 点击 SwitchListTile 切换开关 / 选择定时时间
- **THEN** UI 立即更新：Chip 选中态切换、Switch 状态切换、时间文字更新

---

## Technical Design

**修改文件**：`lib/core/sync/sync_service.dart`

```dart
// setPbSyncMode 末尾加一行
notifyListeners();

// setAutoConfig 末尾加一行  
notifyListeners();
```

两处均为 `SyncService extends ChangeNotifier` 的方法，`notifyListeners()` 可用且语义正确。
