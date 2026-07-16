# Tasks

- [x] Task 1-9: v14 第一轮（已完成）
- [x] Task 10-14: v15 第二轮（已完成）
- [x] Task 15-19: v16 第三轮（已完成）

---

## v17 第四轮迭代（本次新增）

- [x] Task 20: 新建 TextCleanerService 口语化冗余词清洗服务
  - [x] SubTask 20.1: 创建 `lib/core/services/text_cleaner_service.dart`，定义冗余词词库和 `clean(String raw)` 方法
  - [x] SubTask 20.2: 实现正则批量清洗逻辑（纯本地，100ms 内完成）
  - [x] SubTask 20.3: 清洗后自动去除多余空格、标点连续等噪声
  - [x] SubTask 20.4: 在 `service_locator.dart` 注册 `TextCleanerService` 单例

- [x] Task 21: 数据库迁移 v15 —— offline_queue 表 + cleaned_text 列
  - [x] SubTask 21.1: 新建 `OfflineQueue` 表（id, rawText, createdAt, isProcessed）
  - [x] SubTask 21.2: `HubPayloads` 新增 `cleanedText` 列（nullable）
  - [x] SubTask 21.3: `schemaVersion` 升级到 15，编写 v14→v15 迁移
  - [x] SubTask 21.4: IDEA Repository 新增 `insertOfflineQueue` / `getPendingOfflineQueue` / `markOfflineProcessed` 方法
  - [x] SubTask 21.5: 运行 `build_runner build` 重新生成

- [x] Task 22: 重构 ProcessingPipeline 为两阶段异步架构
  - [x] SubTask 22.1: 新增 `processSync(int payloadId)` — 检测在线→清洗→落库→标记 textCleaned，立即返回
  - [x] SubTask 22.2: 新增 `processAsync(int payloadId)` — 从 DB 读取 cleanedText → FTS 索引 → AI 路由 → 分发
  - [x] SubTask 22.3: 新增 `_startBackgroundWorker()` — Timer.periodic 每 3 秒扫描 `textCleaned` 状态记录并自动出队
  - [x] SubTask 22.4: 新增 `_processOfflineQueue()` — 网络恢复时扫描 `offline_queue` 并执行清洗+落库
  - [x] SubTask 22.5: 修改 `enqueue()` 调用 `processSync` 替代 `_processNext()` 中的同步全链路
  - [x] SubTask 22.6: 保留 `_processNext` 作为异步阶段的消费入口

- [x] Task 23: ProcessingStatus 新增状态 + 全链路适配
  - [x] SubTask 23.1: 在 `ProcessingStatus` 枚举新增 `offlineSaved('offline_saved')` 和 `textCleaned('text_cleaned')` 两个值
  - [x] SubTask 23.2: 更新 `fromString()` 的 legacy map 兼容新增枚举值
  - [x] SubTask 23.3: 所有涉及 `ProcessingStatus` 的状态流转处适配新状态（不得遗漏）

- [x] Task 24: 输出格式规范化 —— UI 层修改
  - [x] SubTask 24.1: 检查 `_sendAiMessage` 和 `_onRuleTemplateSelected` 中是否在前端展示了 system prompt，如有则移除
  - [x] SubTask 24.2: 确认 AI 返回结果不再以 JSON 字符串直接渲染到 UI，统一走 `_InboxFieldList` 结构化展示
  - [x] SubTask 24.3: 确保展示原始 AI 对话结果时不暴露 `system` role 消息

- [x] Task 25: 全量 build_runner + flutter analyze + 手动流程回归
  - [x] SubTask 25.1: 执行 `dart run build_runner build --delete-conflicting-outputs`
  - [x] SubTask 25.2: 执行 `flutter analyze`，确保零新增 error

---

## v18 第五轮迭代（本次新增）：四项缺陷修复与体验优化

- [x] Task 26: 修复网络恢复无法触发离线消息处理的 Bug
  - [x] SubTask 26.1: 在 `_retryFailedItems()` 中清理 `_queuedIds`，确保离线消息可重新入队
  - [x] SubTask 26.2: 实现 `_processOfflineQueue()` 方法，直接转换 `offlineSaved` → `textCleaned`（绕过 `enqueue` 守卫）
  - [x] SubTask 26.3: 在 `_connectivitySub` 回调中同时调用 `_processOfflineQueue()` 替代仅调用 `_retryFailedItems`
  - [x] SubTask 26.4: 添加处理进度日志（`debugPrint`），记录离线队列大小、处理条数、状态变更
  - [x] SubTask 26.5: 添加幂等性保护：已为 `textCleaned` 的消息不再被 `_processOfflineQueue` 重复处理

- [x] Task 27: 修复 TextCleanerService 去口语化清洗正则
  - [x] SubTask 27.1: 分析当前正则缺陷：`(^|[标点])词($|[标点])` 要求两端均有分隔符，inline 填充词全部遗漏
  - [x] SubTask 27.2: 新增单字填充词无条件清洗 pass（嗯、呀、哦、啊、额、嘛 — 这 6 个字在业务语境中几乎无独立语义）
  - [x] SubTask 27.3: 多字填充词保留标点分隔匹配，同时新增句首/句尾锚点宽松匹配
  - [x] SubTask 27.4: 编写 5 个典型测试用例（inline 填充词、标点填充词、有意义词保留、空字符串、纯填充词），用 `void main()` 可执行验证
  - [x] SubTask 27.5: 确保清洗后保留原文核心信息完整性（人名、金额、事项关键词不被误删）

- [x] Task 28: AI 处理状态图标静态化 + 详情页横幅 1.5s 退隐
  - [x] SubTask 28.1: 修改 `ProcessingStatusIndicator` 将旋转 `CircularProgressIndicator` 替换为各状态对应静态 `Icon`
  - [x] SubTask 28.2: 补齐 `textCleaned`、`offlineSaved` 状态在 `_buildStatusBanner` switch 中的 case 分支
  - [x] SubTask 28.3: 在 `_IdeaDetailPageState` 中新增 `_showStatusBanner` 状态变量 + `Timer` 实现 1.5s 自动隐藏
  - [x] SubTask 28.4: 实现横幅重显逻辑：每次 `initState` / `didUpdateWidget` 检测到 payload 状态仍在处理中时重置 `_showStatusBanner = true`
  - [x] SubTask 28.5: 处理完成状态（`dispatched`/`decayed`）永久不显示横幅

- [x] Task 29: 移动端收件箱紧凑布局 + 移除编辑图标
  - [x] SubTask 29.1: 在 `_InboxFieldList._buildFieldWrap()` 中通过 `LayoutBuilder` 检测屏幕宽度
  - [x] SubTask 29.2: 宽度 < 600px 时：限制最多展示 6 条，超出显示"查看全部 (N)"可展开折叠入口
  - [x] SubTask 29.3: 移动端 `_InboxFieldChip` 改为单列占满宽度，label/value 叠放布局
  - [x] SubTask 29.4: 移动端移除 `Icons.edit_outlined` 铅笔图标，PC 端保留
  - [x] SubTask 29.5: PC 端（>= 600px）保持原有 `Wrap` 多列布局完全不变

- [x] Task 30: 全量验证：build_runner + flutter analyze + 手动回归
  - [x] SubTask 30.1: 执行 `dart run build_runner build --delete-conflicting-outputs`
  - [x] SubTask 30.2: 执行 `flutter analyze`，确保零新增 error
  - [x] SubTask 30.3: 编写 TextCleanerService 单元测试验证清洗逻辑

# Task Dependencies
- Task 20 依赖于无（独立新文件，可优先并行）
- Task 21 依赖于无（DB 迁移独立，可优先并行）
- Task 22 依赖于 Task 20 + Task 21（需要 TextCleanerService + 新表/列）
- Task 23 依赖于 Task 22（需在新流程中使用新增状态）
- Task 24 依赖于 Task 22 + Task 23（确保输出链路上无不规范渲染）
- Task 25 依赖于 Task 20-24 全部完成

## v18 Dependencies
- Task 26 依赖于无（独立修复 processing_pipeline.dart，可优先并行）
- Task 27 依赖于无（独立修复 text_cleaner_service.dart，可优先并行）
- Task 28 依赖于无（独立修改 UI 组件，可优先并行）
- Task 29 依赖于无（独立修改 UI 组件，可优先并行）
- Task 30 依赖于 Task 26-29 全部完成

---

## v19 第六轮迭代（本次新增）：两项细节打磨

- [x] Task 31: 移动端收件箱 maxVisible 收紧为 4
  - [x] SubTask 31.1: 修改 `_buildMobileLayout` 中 `const maxVisible = 6` 为 `const maxVisible = 4`

- [x] Task 32: 已触发规则时隐藏 @ 规则模板
  - [x] SubTask 32.1: 在 `_IdeaDetailPageState` 中新增 `_hasActiveInbox` getter，判断 `widget.payload.processingStatus == 'pendingReview'`
  - [x] SubTask 32.2: 修改 `bottomNavigationBar` 中传入 `AiChatInputBox` 的 `templates` 列表，当 `_hasActiveInbox` 时过滤掉 `templateType == 'rule'` 的模板
  - [x] SubTask 32.3: 确认 @ 按钮仍可点开（显示过滤后的模板列表），长按仍可进入模板管理

- [x] Task 33: 全量验证
  - [x] SubTask 33.1: `flutter analyze` 零新增 error

## v19 Dependencies
- Task 31 依赖于无（单行常数修改，可立即执行）
- Task 32 依赖于无（独立条件判断 + 列表过滤，可立即执行）
- Task 33 依赖于 Task 31-32

---

## v20 第七轮迭代（本次新增）：模板渲染收尾 + TODO 标题提取

- [x] Task 34: 有活跃收件箱时禁用 `_buildTemplateGrid` 渲染
  - [x] SubTask 34.1: 在两处 `_buildTemplateGrid` 调用（`conversations.isEmpty` 分支）添加 `!_hasActiveInbox` 守卫条件

- [x] Task 35: AI 路由 TODO 规则标题自动提取
  - [x] SubTask 35.1: `_routingTools` function calling 定义新增 `title` 字段（type: string，description 说明为 TODO 主题摘要）
  - [x] SubTask 35.2: 强化 system prompt，增加"当 intent_tag 为 TODO 时，必须从用户原文总结出待办事项的核心主题填充到 title 字段"指令
  - [x] SubTask 35.3: `ExtractedEntities` 类新增 `title` 字段，`toJson` 和构造函数同步
  - [x] SubTask 35.4: `IntentRouter.extractEntities` 中 TODO 分支增加 title 提取逻辑（取原文去除时间/人名等修饰后的核心动宾短语）

- [x] Task 36: 全量验证
  - [x] SubTask 36.1: `flutter analyze` 零新增 error

## v20 Dependencies
- Task 34 依赖于无（UI 条件守卫，独立修改）
- Task 35 依赖于无（后端服务修改，独立修改）
- Task 36 依赖于 Task 34-35

---

## v21 第八轮迭代（本次新增）：四项细节优化

- [x] Task 37: 移除 AI 收件箱外框描边，对齐标准内容块样式
  - [x] SubTask 37.1: 在 `_buildDispatchInboxCard` 中移除 `Card` 的 `shape: RoundedRectangleBorder(side: BorderSide(...))` 外框描边设置
  - [x] SubTask 37.2: 确认卡片所有交互功能（字段编辑、分发确认、折叠展开）完整保留
  - [x] SubTask 37.3: 验证暗色/亮色主题下卡片视觉与上方内容块一致

- [x] Task 38: 修复模板管理页 7+ 条记录底部溢出
  - [x] SubTask 38.1: 在 `template_management_page.dart` 的 `ReorderableListView.builder` 底部添加内边距或 SafeArea，避免列表末项被 FAB 遮挡
  - [x] SubTask 38.2: 验证 7-15 条模板时无 RenderFlex overflow 错误
  - [x] SubTask 38.3: 验证 6 条及以下模板时布局无回归

- [x] Task 39: @ 模板选择器新增 tab 分类切换
  - [x] SubTask 39.1: 重构 `AiChatInputBox._showTemplatePicker` 使用 `DefaultTabController`，新增"对话"/"规则"两个 tab
  - [x] SubTask 39.2: 按 `templateType` 将传入的模板列表拆分为 chat 和 rule 两组
  - [x] SubTask 39.3: 仅一种类型有内容时隐藏 tab 栏，直接展示列表
  - [x] SubTask 39.4: `_hasActiveInbox = true` 时 rule tab 自动隐藏（因为 v19 已过滤 rule 模板）
  - [x] SubTask 39.5: 选中回调逻辑与当前一致，不改变原有行为

- [x] Task 40: 对话模板选择后仅展示 AI 返回结果，使用内容卡片块样式
  - [x] SubTask 40.1: 修改逻辑：对话模板触发时不再写入 user conversation，新增 `_handleChatTemplateSelected` 独立方法
  - [x] SubTask 40.2: AI 返回结果以内容卡片块（`addBlock` + sourceType `'ai'`）展示，替代对话气泡
  - [x] SubTask 40.3: 内容卡片块复用现有 `_buildContentBlock` 渲染样式，支持后续编辑操作
  - [x] SubTask 40.4: 普通对话（底部输入框直接发送）不受影响，仍以对话气泡形式展示

- [x] Task 41: 全量验证
  - [x] SubTask 41.1: VS Code 诊断零新增 error，dart analyze 通过
  - [x] SubTask 41.2: 验证所有 4 项修改在代码层面逻辑正确

## v21 Dependencies
- Task 37 依赖于无（独立 UI 样式修改）
- Task 38 依赖于无（独立布局修复）
- Task 39 依赖于无（独立 UI 组件重构）
- Task 40 依赖于无（独立逻辑修改）
- Task 41 依赖于 Task 37-40 全部完成

---

## v22 第九轮迭代（本次新增）：布局样式统一 + Tab 功能验证

- [x] Task 42: AI 收件箱卡片与内容块样式完全统一
  - [x] SubTask 42.1: 将外层 Container 的 `margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4)` 改为 `margin: EdgeInsets.only(bottom: 10)`，移除 `width: double.infinity`
  - [x] SubTask 42.2: 将 `Card(elevation, custom color, RoundedRectangleBorder)` 替换为 `Container + BoxDecoration`（暗色 0xFF1E1E1E，亮色 0xFFFBFBFB，圆角 14，border 0.06 alpha）
  - [x] SubTask 42.3: 内边距从 `EdgeInsets.all(12)` 调整为 `EdgeInsets.all(14)`
  - [x] SubTask 42.4: 确认所有交互功能（字段编辑、分发确认、折叠展开）不受影响
  - [x] SubTask 42.5: 验证暗色/亮色主题下收件箱卡片与内容块外观一致

- [x] Task 43: @ 模板选择器 Tab 分类功能验证
  - [x] SubTask 43.1: 验证双类型（chat + rule）场景：Tab 栏显示、切换正确、选中回调正常
  - [x] SubTask 43.2: 验证仅 chat 类型场景：Tab 栏隐藏、列表正确渲染
  - [x] SubTask 43.3: 验证仅 rule 类型场景：Tab 栏隐藏、列表正确渲染
  - [x] SubTask 43.4: 验证 Tab 内空状态（某分类无模板时对应 tab 不显示）

- [x] Task 44: 全量验证
  - [x] SubTask 44.1: VS Code 诊断零新增 error
  - [x] SubTask 44.2: 执行 `flutter analyze` 确保零新增 error

## v22 Dependencies
- Task 42 依赖于无（独立 UI 样式修改）
- Task 43 依赖于无（独立功能验证，代码无需修改）
- Task 44 依赖于 Task 42-43 全部完成

---

## v23 第十轮迭代（本次新增）：按钮图标化 + Tab 渲染修复

- [x] Task 45: 收件箱操作按钮图标化
  - [x] SubTask 45.1: 将 `_buildInboxActions` 中"重新生成" `OutlinedButton.icon` 改为 `IconButton(Icons.refresh)`
  - [x] SubTask 45.2: 将"拒绝" `OutlinedButton` 改为 `IconButton(Icons.close, color: error)`
  - [x] SubTask 45.3: 将"确认分发" `FilledButton.tonal` 改为 `IconButton(Icons.check)`，缺键时 disabled
  - [x] SubTask 45.4: 已拒绝状态"编辑后重新规则化"和已确认状态"编辑数据/撤销分发"维持原样不变

- [x] Task 46: "查看全部"与图标按钮合并到同一行
  - [x] SubTask 46.1: 从 `_InboxFieldList._buildMobileLayout` 中移除"查看全部"的内联独立渲染，改为含 trailingActions 的组合 Row
  - [x] SubTask 46.2: 在 `_InboxFieldList` 中新增 `trailingActions` 参数，透传至移动端和 PC 端布局
  - [x] SubTask 46.3: 在 `_buildDispatchInboxCard` 中：pending 状态传图标按钮进字段区，已确认/已拒绝状态保持原有独立按钮行
  - [x] SubTask 46.4: 图标按钮间距 12px，点击区域 36×36px（SizedBox + IconButton）

- [x] Task 47: 移除 rule 模板过滤以修复 Tab 选择器渲染
  - [x] SubTask 47.1: 移除 `active ? allTemplates.where(...) : allTemplates` 过滤 + 删除未使用的 `active` 变量
  - [x] SubTask 47.2: 直接传入 `allTemplates`（`templates: snapshot.data ?? []`）
  - [x] SubTask 47.3: _hasActiveInbox=true 且存在双类型模板时 Tab 栏可正常渲染

- [x] Task 48: 全量验证
  - [x] SubTask 48.1: VS Code 诊断零新增 error
  - [x] SubTask 48.2: `flutter analyze` 零新增 error

## v23 Dependencies
- Task 45 依赖于无（独立按钮样式修改）
- Task 46 依赖于 Task 45（合并行需要图标化后的按钮）
- Task 47 依赖于无（独立过滤逻辑移除）
- Task 48 依赖于 Task 45-47 全部完成

---

## v24 第十一轮迭代（本次新增）：已确认状态按钮图标化收尾

- [x] Task 49: 已确认状态按钮图标化
  - [x] SubTask 49.1: 将 `_buildInboxActions` 中"编辑数据" `OutlinedButton` 改为 `SizedBox(36,36) + IconButton(Icons.edit, tooltip: '编辑数据')`
  - [x] SubTask 49.2: 将"撤销分发" `OutlinedButton.icon` 改为 `SizedBox(36,36) + IconButton(Icons.undo, color: error, tooltip: '撤销分发')`
  - [x] SubTask 49.3: 间距从 `SizedBox(width: 6)` 改为 `SizedBox(width: 12)` 与 pending 状态一致
  - [x] SubTask 49.4: 确认已拒绝状态"编辑后重新规则化"按钮不受影响

- [x] Task 50: 全量验证
  - [x] SubTask 50.1: VS Code 诊断零新增 error

## v24 Dependencies
- Task 49 依赖于无（独立按钮样式修改）
- Task 50 依赖于 Task 49

---

## v25 第十二轮迭代：已确认按钮移至"查看全部"同一行

- [x] Task 51: 已确认状态操作按钮并入字段尾部行
  - [x] SubTask 51.1: 创建 `_buildConfirmedActionIcons` 辅助方法（编辑 + 撤销图标按钮，36x36 + 12px 间距）
  - [x] SubTask 51.2: 更新 `_buildDispatchInboxCard` 中 `trailingActions`：确认状态传入 `_buildConfirmedActionIcons`
  - [x] SubTask 51.3: 底部 `_buildInboxActions` 调用条件从 `isConfirmed \|\| isRejected` 改为仅 `isRejected`
  - [x] SubTask 51.4: 简化 `_buildInboxActions` 方法签名，移除已确认和 pending 死分支，只保留拒绝分支

- [x] Task 52: 全量验证
  - [x] SubTask 52.1: VS Code 诊断零新增 error

## v25 Dependencies
- Task 51 依赖于无（独立布局调整）
- Task 52 依赖于 Task 51
