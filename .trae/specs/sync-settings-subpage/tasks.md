# Tasks

- [x] Task 1: 扩展 AutoSyncConfig — 新增智能模式开关字段
  - 新增 `syncOnResume`（默认 true）和 `syncOnPause`（默认 true）字段
  - `setAutoConfig()` 扩展：持久化 `sync_on_resume` / `sync_on_pause` 到 `app_config`
  - `init()` 恢复时读取上述 key
  - `setAutoConfig()` 保持兼容：所有字段可选，未传入则保留当前值

- [x] Task 2: 更新 main.dart 生命周期触发逻辑
  - `didChangeAppLifecycleState` 中检查 `autoConfig.syncOnResume` / `autoConfig.syncOnPause`
  - 仅当对应开关开启时才触发 `triggerPbSync()`

- [x] Task 3: 创建 SyncSettingsPage 子页面
  - 新建 `lib/features/settings/presentation/pages/sync_settings_page.dart`
  - 顶部：`SegmentedButton<PbSyncMode>` 三段按钮切换同步模式，调用 `ss.setPbSyncMode()`
  - 自动/智能模式共用区域：频率选择（ChoiceChip，10档） + 定时时间选择（ListTile → TimePicker）
  - 智能模式专属区域：`SwitchListTile` × 2（syncOnResume / syncOnPause）
  - 手动模式专属区域：说明文字卡片
  - 使用 `ListenableBuilder` 绑定 `SyncService` 实现实时响应

- [x] Task 4: 更新设置页入口
  - "Sync Mode" tile 的 `onTap` 改为 `Navigator.push` 到 `SyncSettingsPage`
  - 移除 `_pickSyncMode()` 旧 Dialog 方法
  - 移除内联 interval / scheduled time 行（已迁移到子页面）
  - 移除旧的 `_pickInterval()`、`_pickTime()` 方法
  - 保留 `_syncModeLabel()` 用于显示当前模式摘要

- [x] Task 5: 端到端验证
  - 三种模式切换 SegmentedButton 正常工作
  - 自动模式：频率选择 + 定时时间设置生效
  - 智能模式：频率选择 + 定时时间 + 生命周期开关均生效
  - `syncOnPause=false` 时应用进入后台不触发同步
  - `syncOnResume=false` 时应用回到前台不触发同步
  - 设置页返回后主卡片显示正确的当前模式摘要
  - 全项目 `flutter analyze` 零新增 issue

# Task Dependencies
- Task 1 是所有后续任务的基础
- Task 2 依赖 Task 1
- Task 3 依赖 Task 1
- Task 4 依赖 Task 3
- Task 5 依赖所有 Tasks
- Task 2 和 Task 3 可并行
