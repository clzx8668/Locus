# Tasks

- [x] Task 1: 数据库迁移补齐 — schemaVersion 8→9 + ALTER TABLE 迁移
  - [x] `schemaVersion` 改为 `9`
  - [x] 在 `onUpgrade` 中新增 `if (from <= 8)` 分支：
    - `ALTER TABLE hub_payloads ADD COLUMN title TEXT`（nullable，无默认值）
    - `ALTER TABLE content_blocks ADD COLUMN tags TEXT NOT NULL DEFAULT '[]'`
  - [x] 运行 `dart run build_runner build` 重新生成 `.g.dart`

- [x] Task 2: 修复 AppBar 标题样式与居中
  - [x] 标题 TextStyle 改为 `AppTypography.h3.copyWith(color: theme.textTheme.bodyMedium?.color)`（fontSize: 16, fontWeight: w600）
  - [x] AppBar 添加 `centerTitle: true`
  - [x] 补充 `import '../../../../core/theme/design_system.dart'` 导入

# Task Dependencies
- Task 2 独立于 Task 1，可并行执行
