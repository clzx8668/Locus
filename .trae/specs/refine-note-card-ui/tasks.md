# Tasks

- [x] Task 1: 为 IdeaRepository 新增获取内容块数量的查询方法
  - [x] 在 `AppDatabase` 中新增 `watchBlockCountForPayload(int payloadId)` 方法，返回 `Stream<int>`
  - [x] 在 `IdeaRepository` 中暴露 `watchBlockCount(int payloadId)` 方法

- [x] Task 2: 重构 `_buildSmartCard` — 卡片顶部新增装饰短横线
  - [x] 在卡片顶部（日期上方）新增装饰横线区域，使用 `StreamBuilder` 绑定当前卡片的内容块数量
  - [x] 横线样式：短横（约 20-24px 宽）、2-3px 高、圆角、间距紧凑（4-6px）
  - [x] 颜色使用主题色 `theme.hintColor`，预留 `blockColors` 字段注释
  - [x] 无内容块时默认显示 1 条横线

- [x] Task 3: 重构 `_buildSmartCard` — 标签移至卡片底部左对齐
  - [x] 将标签 chip 从顶部右侧 `Row` 中移除
  - [x] 在卡片 `Column` 底部（文本内容之后）新增左对齐的标签 chip
  - [x] 标签样式保持现有 coral pink 配色和圆角设计
  - [x] 无标签时不占用额外空间

- [x] Task 4: 统一视图切换的卡片间距
  - [x] 确保 ListView 使用 `ListView.separated`，分隔符高度 12px（已验证，无变更）
  - [x] 确保 GridView 的 `crossAxisSpacing` 和 `mainAxisSpacing` 均为 14px（已验证，无变更）
  - [x] 检查大屏（>=960px）3 列网格的间距一致性
  - [x] 验证两种视图切换时卡片不存在额外间隙或重叠

- [x] Task 5: SettingsService 预留内容块颜色配置
  - [x] 在 `SettingsService` 中新增 `List<int>? blockColors` 字段及对应的 SharedPreferences 存取键
  - [x] 新增 getter/setter 方法
  - [x] 当前默认返回 null（使用默认颜色），为后续扩展预留接口

# Task Dependencies
- Task 2 依赖 Task 1（需要内容块数量的查询方法）
- Task 3 可与 Task 2 并行（修改同一方法的不同区域，但建议顺序执行避免冲突）
- Task 4 独立，可与 Task 1-3 并行
- Task 5 独立，可与所有其他任务并行
