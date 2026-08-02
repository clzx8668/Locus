# Tasks

- [x] Task 1: 实现自动重连逻辑
  - `init()` 中新增 `_tryAutoConnect()` 调用，置于 `_applySyncMode()` 之前
  - `_tryAutoConnect()` 读取 `pb_server_url`/`pb_email`/`pb_password`
  - 凭证不全则直接 return
  - 创建 `PocketBaseAdapter` → `_pb!.auth()` → `_pb!.healthCheck()`
  - 成功：`_pbConnected = true` + `notifyListeners()` + debugPrint
  - 失败：`_pb?.dispose()` + `_pb = null` + debugPrint（不弹错误）
  - 不调用 `ensureCollections()`（由手动 Connect 时处理）

- [x] Task 2: 全项目分析验证
  - `flutter analyze` 14 个既有 issue，零新增
  - `init()` 在 `main.dart` 的 `_LocusAppState.initState()` 中被调用
  - `_applySyncMode()` 在 `_tryAutoConnect()` 之后执行

# Task Dependencies
- Task 2 依赖 Task 1
