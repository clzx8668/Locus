# 内容页标题样式与内容块显示修复 Spec

## Why
上轮 `refine-detail-page` 实现存在三个缺陷：标题使用普通正文字号而非设计系统中的标题样式；标题未居中；数据库迁移遗漏导致内容块无法正常显示。

## What Changes
- AppBar 标题字体改用 `AppTypography.h3`（fontSize: 16, fontWeight: w600），与项目标题层级对齐
- AppBar 标题居中显示（`centerTitle: true`）
- 修复数据库迁移缺失：`schemaVersion` 8→9，补全 `hubPayloads.title` 和 `contentBlocks.tags` 的 ALTER TABLE 迁移

## Impact
- Affected specs: `refine-detail-page`
- Affected code:
  - `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` — AppBar 标题样式和居中
  - `lib/core/database/database.dart` — schemaVersion 8→9，新增 v8→v9 迁移

## MODIFIED Requirements

### Requirement: AppBar 标题使用设计系统标题样式
#### Scenario: 标题显示
- **WHEN** 内容页渲染
- **THEN** 标题使用 `AppTypography.h3.copyWith(color: ...)` 样式（16px, w600, height 1.4）

#### Scenario: 标题居中
- **WHEN** 内容页渲染
- **THEN** AppBar 的 `centerTitle` 为 `true`，标题水平居中

### Requirement: 数据库迁移补齐
#### Scenario: 新数据库创建
- **WHEN** 首次安装应用
- **THEN** `onCreate` 正常创建所有表，含 `title` 和 `tags` 列

#### Scenario: 旧数据库升级（v8 → v9）
- **WHEN** 已有数据库从 v8 升级到 v9
- **THEN** 执行 `ALTER TABLE hub_payloads ADD COLUMN title TEXT` 和 `ALTER TABLE content_blocks ADD COLUMN tags TEXT NOT NULL DEFAULT '[]'`
- **AND** 数据库内已有数据完整保留

## Root Cause
`refine-detail-page` 在 `HubPayloads` 和 `ContentBlocks` 表新增了列但未修改 `schemaVersion`（仍为 8）也未添加对应的 `onUpgrade` 迁移。Drift 生成的 schema 期望新列存在但磁盘数据库不包含它们，导致查询返回空数据或数据库打开失败，内容块无法显示。
