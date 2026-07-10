# 笔记卡片 UI 细化 Spec

## Why
当前笔记列表卡片的信息层级和视觉布局需要优化：标签位置过于突出，缺少内容块数量的可视化指示，且不同视图下卡片间距不一致影响美观。

## What Changes
- 卡片顶部日期上方新增装饰短横线，数量对应内容块数量，预留颜色关联扩展
- 标签标识从卡片顶部右侧移至底部左对齐
- 优化列表/网格视图切换的间距一致性，确保卡片间间隙统一协调
- **BREAKING**: 卡片布局结构变更（标签位置移动、新增装饰线区域）

## Impact
- Affected specs: 无已有 spec
- Affected code:
  - `lib/features/idea_stream/presentation/pages/idea_stream_page.dart` — `_buildSmartCard()` 卡片构建
  - `lib/features/idea_stream/data/idea_repository.dart` — 新增内容块数量查询方法
  - `lib/core/database/database.dart` — 可能新增按 payloadId 的块计数查询
  - `lib/core/services/settings_service.dart` — 预留内容块颜色设置
  - `lib/features/settings/presentation/pages/settings_page.dart` — 预留内容块背景颜色设置入口

## ADDED Requirements

### Requirement: 内容块装饰短横线指示
系统 SHALL 在每张笔记卡片的顶部、日期时间上方，渲染一组装饰短横线。横线数量与该笔记所包含的内容块（ContentBlock）个数一一对应，使用户在不进入详情页时即可感知内容丰富度。

#### Scenario: 卡片有 3 个内容块
- **WHEN** 一张笔记包含 3 个 ContentBlock
- **THEN** 卡片顶部显示 3 条水平短横装饰线

#### Scenario: 卡片无内容块
- **WHEN** 一张笔记没有 ContentBlock（仅 rawText 未拆分）
- **THEN** 卡片顶部显示 1 条默认横线（代表主文本）

#### Scenario: 颜色预留
- **WHEN** 渲染装饰横线
- **THEN** 每条横线使用默认主题色（与卡片文字色协调），预留颜色列表字段供后续按块类型着色

### Requirement: 标签移至卡片底部左对齐
系统 SHALL 将标签（intentTag）显示从卡片顶部右侧移至卡片底部，左对齐排列。

#### Scenario: 卡片有标签
- **WHEN** 笔记的 intentTag 非空且不等于 'NOTE'
- **THEN** 标签 chip 渲染在卡片底部、左对齐

#### Scenario: 卡片无标签
- **WHEN** 笔记的 intentTag 为空或等于 'NOTE'
- **THEN** 卡片底部不显示标签区域，内容区域正常填充

### Requirement: 视图切换与卡片间距统一
系统 SHALL 在列表视图（ListView）和网格视图（GridView）之间切换时，保持卡片之间的间距（gap）统一一致，不受卡片自身内容高度影响。

#### Scenario: 列表视图下卡片间距统一
- **WHEN** 用户处于列表视图模式
- **THEN** 每张卡片之间的垂直间距固定为 12px，与卡片内容高度无关

#### Scenario: 网格视图下卡片间距统一
- **WHEN** 用户处于网格视图模式
- **THEN** 网格单元之间的水平和垂直间距固定为 14px，不受卡片内容影响（由 SliverGridDelegate 保证）

#### Scenario: 大屏默认网格视图
- **WHEN** 屏幕宽度 >= 960px
- **THEN** 默认以 3 列网格展示，间距与其他视图一致

### Requirement: 内容块背景颜色可配置（预留）
系统 SHALL 在设置服务中预留内容块背景颜色的配置能力，为详情页内容块支持可变更背景颜色做基础。

#### Scenario: 设置项预留
- **WHEN** 查看设置相关代码
- **THEN** SettingsService 中存在内容块颜色配置字段（可为后续扩展预留，当前使用默认值）
