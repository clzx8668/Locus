# Checklist

- [x] `schemaVersion` 已更新为 `9`
- [x] `onUpgrade` 包含 `if (from <= 8)` 分支
- [x] `ALTER TABLE hub_payloads ADD COLUMN title TEXT` 迁移语句正确
- [x] `ALTER TABLE content_blocks ADD COLUMN tags TEXT NOT NULL DEFAULT '[]'` 迁移语句正确
- [x] `build_runner` 重新生成成功
- [x] 旧数据库升级后数据保留完整
- [x] 内容页内容块正常显示（StreamBuilder 返回数据）
- [x] AppBar 标题使用 `AppTypography.h3` 样式
- [x] AppBar 标题居中（`centerTitle: true`）
- [x] 暗黑模式下标题颜色正确
