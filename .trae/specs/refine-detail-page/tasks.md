# Tasks

- [x] Task 1: 数据库迁移 — 新增 title 和 tags 列
  - [x] `HubPayloads` 表新增 `title` 列（nullable `TextColumn`）
  - [x] `ContentBlocks` 表新增 `tags` 列（`TextColumn`，默认 `'[]'`）
  - [x] 运行 `dart run build_runner build` 重新生成 `.g.dart`
  - [x] 新增 `updatePayloadTitle(int id, String? title)` 数据库方法
  - [x] 新增 `updateBlockTags(int blockId, String tags)` 数据库方法

- [x] Task 2: Repository 层新增标题与块标签方法
  - [x] `IdeaRepository` 新增 `updateTitle(int payloadId, String? title)` 方法
  - [x] `IdeaRepository` 新增 `updateBlockTags(int blockId, List<String> tags)` 方法

- [x] Task 3: 修复摘要覆盖 Bug + 首块编辑同步摘要
  - [x] 从 `_openBlockEditor`（追加新块）中移除 `_repo.update()` 摘要覆盖调用
  - [x] 在 `_openBlockEditorForEdit`（编辑块）中，判断是否为 sortOrder 最小的首块，是则同步更新摘要
  - [x] 确认首页卡片 `getFirstBlockText` 机制工作正常

- [x] Task 4: 内容页智能标题生成与手动修改
  - [x] 在 `initState` 中检查 `payload.title`，为空时自动从首块内容提取标题
  - [x] AppBar title 显示 `_currentTitle.isEmpty ? '未命名' : _currentTitle`
  - [x] AppBar actions 添加 `PopupMenuButton`，含「修改标题」选项
  - [x] 实现标题编辑弹窗（TextField + 确认/取消）
  - [x] 监听标题变化，实时更新 AppBar

- [x] Task 5: 标签体系重构 — 每块独立标签
  - [x] 移除页面顶部 `_buildTagSection` 及相关的 `_tags`、`_saveTags`、`_showAddTagDialog` 逻辑
  - [x] 在 `_buildContentBlock` 底部新增标签区域：显示已有关联标签 chip +「+ 标签」按钮
  - [x] 实现按块的标签添加弹窗（写入该块的 `tags`）
  - [x] 实现标签 chip 的删除功能（点击 × 移除，更新数据库）
  - [x] 解析/序列化标签 JSON（格式 `["#标签1","#标签2"]`）

# Task Dependencies
- Task 2 依赖 Task 1（数据库迁移完成后才能添加 Repository 方法）
- Task 3 独立，可与 Task 1-2 并行（仅修改详情页逻辑，不依赖新列）
- Task 4 依赖 Task 1-2（需要 `title` 列和存取方法）
- Task 5 依赖 Task 1-2（需要 `tags` 列和存取方法）
