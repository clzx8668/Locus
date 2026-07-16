# Checklist

## v14 第一轮（已验证全部通过）
- [x] `lib/core/services/embedding_service.dart` 文件已删除
- [x] `lib/core/services/processing_pipeline.dart` 不再 import EmbeddingService
- [x] `lib/core/di/service_locator.dart` 中无 EmbeddingService
- [x] `VectorService` 已实现 `upsertFtsDoc` / `queryFts`
- [x] `VectorDedupService` 已新增 `checkLocalSimilarity()`
- [x] `ProcessingPipeline._generateAndStoreVector()` 已改为本地 FTS
- [x] 字段中文别名已定义、核心必填键值已定义
- [x] AI 收件箱卡片中文字段标签展示
- [x] 缺键警告横幅 + 确认按钮 disabled
- [x] 多目的地勾选区域 + `SyncResult`
- [x] `flutter analyze` + `build_runner` 通过

## v15 第二轮（已验证全部通过）
- [x] `_InboxFieldList` 渲染全部已知字段 + 空值 `未识别` 占位
- [x] `DispatchService.updateInboxExtractedData` 持久化编辑
- [x] `status=rejected` 显示"编辑后重新规则化"
- [x] `status=confirmed` 显示"编辑数据"入口
- [x] `DispatchService.reopenInbox()` 已实现
- [x] 手动规则化按钮 + 模板选择器
- [x] `ProcessingPipeline.manualEnqueue()` 已实现
- [x] `flutter analyze` + `build_runner` 通过

## v16 第三轮（已验证全部通过）
- [x] `AiTemplates` 表新增 `templateType` 列
- [x] `schemaVersion` 14 迁移 + 三条默认规则化模板
- [x] @ 选择器规则化模板视觉区分 + `onRuleTemplateSelected`
- [x] 独立"手动规则化"按钮已移除
- [x] `_onRuleTemplateSelected` 替代 `_showManualRouteDialog`
- [x] 模板管理页面 CRUD 含 `templateType` 下拉 + 规则化徽章
- [x] `flutter analyze` zero error + `build_runner` 通过

---

## v17 第四轮迭代（已验证全部通过，共 23 项）

### Task 20: TextCleanerService
- [x] `lib/core/services/text_cleaner_service.dart` 文件已创建
- [x] 冗余词词库包含所有指定目标词（嗯/呀/这个/那个/哦/啊/嗯呐/对吧/说白了等17个）
- [x] `clean(String raw)` 方法纯本地正则执行，100ms 内完成
- [x] 清洗后自动去除多余空格和连续标点
- [x] `service_locator.dart` 中已注册 `TextCleanerService` 单例

### Task 21: 数据库迁移 v15
- [x] `OfflineQueue` 表已创建（id/rawText/createdAt/isProcessed）
- [x] `HubPayloads` 新增 `cleanedText` 列
- [x] `schemaVersion` 升级到 15，迁移逻辑正确
- [x] `IdeaRepository` 新增离线队列 CRUD 方法
- [x] `build_runner build` 成功

### Task 22: ProcessingPipeline 两阶段架构
- [x] `processSync(payloadId)` 已实现：检测在线→清洗→落库→标记 textCleaned
- [x] `processAsync(payloadId)` 已实现：读取 cleanedText→FTS→AI路由→分发
- [x] `_backgroundWorker` Timer 定时扫描 textCleaned 记录并出队
- [x] `_processOfflineQueue()` 网络恢复时扫描并处理离线队列
- [x] `enqueue()` 改为调用 `processSync`
- [x] `_processNext` 作为异步阶段入口保留

### Task 23: ProcessingStatus 新增状态
- [x] `offlineSaved('offline_saved')` 和 `textCleaned('text_cleaned')` 枚举值已新增
- [x] `fromString()` 兼容新枚举值
- [x] 全链路状态流转适配新状态

### Task 24: 输出格式规范化
- [x] system prompt 不在 UI 中渲染
- [x] AI 结果不以 JSON 字符串直接渲染
- [x] system role 消息不在 AI 对话区域暴露

### Task 25: 验证
- [x] `flutter analyze` 零新增 error
- [x] `dart run build_runner build` 成功

---

## v18 第五轮迭代（已验证全部通过，共 25 项）

### Task 26: 网络恢复自动触发离线队列处理
- [x] `_retryFailedItems()` 中 `_queuedIds` 清理逻辑已实现，离线消息可重新入队
- [x] `_processOfflineQueue()` 方法已实现，直接转换 `offlineSaved` → `textCleaned`
- [x] `_connectivitySub` 回调中调用 `_processOfflineQueue()`
- [x] `debugPrint` 日志记录离线队列处理进度
- [x] 幂等性保护：`textCleaned` 消息不会重复处理

### Task 27: TextCleanerService 去口语化清洗正则修复
- [x] 单字填充词（嗯、呀、哦、啊、额、嘛）无条件清洗已实现
- [x] 多字填充词保留标点分隔匹配 + 句首/句尾宽松匹配
- [x] "嗯这个客户张三呀需要联系一下" → 清洗为 "客户张三需要联系一下"
- [x] "说白了，这个项目，嗯，就是需要审核" → 清洗正确
- [x] 关键词（人名、金额、事项）不被误删
- [x] 5 个测试用例可执行并通过

### Task 28: AI 处理状态图标静态化 + 横幅 1.5s 退隐
- [x] `ProcessingStatusIndicator` 中 `CircularProgressIndicator` 已替换为对应静态 `Icon`
- [x] `textCleaned` / `offlineSaved` 状态在 `_buildStatusBanner` 中有对应 case
- [x] 详情页横幅 1.5 秒后自动隐藏
- [x] 重新打开同一消息时横幅重新展示（如 AI 仍在处理）
- [x] `dispatched` / `decayed` 状态横幅永久不显示

### Task 29: 移动端收件箱紧凑布局
- [x] `LayoutBuilder` 检测屏幕宽度，< 600px 触发紧凑布局
- [x] 移动端最多展示 6 条，超出显示"查看全部 (N)"折叠入口
- [x] 移动端 `_InboxFieldChip` 单列布局，label/value 叠放
- [x] 移动端 `Icons.edit_outlined` 铅笔图标已移除
- [x] PC 端（>= 600px）原有布局完全不变

### Task 30: 全量验证
- [x] `dart run build_runner build --delete-conflicting-outputs` 成功
- [x] `flutter analyze` 零新增 error
- [x] TextCleanerService 单元测试可执行并通过

---

## v19 第六轮迭代（已验证全部通过，共 5 项）

### Task 31: 移动端收件箱 maxVisible 收紧为 4
- [x] `const maxVisible = 6` 已改为 `const maxVisible = 4`

### Task 32: 已触发规则时隐藏 @ 规则模板
- [x] `_hasActiveInbox` getter 已实现
- [x] `pendingReview` 状态下 rule 模板已被过滤
- [x] 无活跃收件箱时 rule 模板正常展示

### Task 33: 全量验证
- [x] `flutter analyze` 零新增 error

---

## v20 第七轮迭代（已验证全部通过，共 8 项）

### Task 34: 有活跃收件箱时禁用模板网格
- [x] 两处 `_buildTemplateGrid` 调用均已添加 `!_hasActiveInbox` 守卫
- [x] `_hasActiveInbox = true` 时模板网格不渲染
- [x] `_hasActiveInbox = false` 时模板网格正常显示

### Task 35: TODO 规则标题自动提取
- [x] `_routingTools` 新增 `title` 字段
- [x] system prompt 包含 TODO 标题提取指令
- [x] `ExtractedEntities` 新增 `title` 字段
- [x] 本地 `extractEntities` TODO 分支含 title 提取

### Task 36: 全量验证
- [x] `flutter analyze` 零新增 error

---

## v21 第八轮迭代（已验证全部通过，共 14 项）

### Task 37: 移除 AI 收件箱外框描边
- [x] `_buildDispatchInboxCard` 中 `Card` 的 `BorderSide` 描边已移除
- [x] 卡片在暗色主题下无彩色边框，与上方内容块视觉一致
- [x] 卡片在亮色主题下无彩色边框，与上方内容块视觉一致
- [x] 字段编辑、分发确认、折叠展开等所有交互功能正常

### Task 38: 模板管理页溢出修复
- [x] `ReorderableListView.builder` 底部有足够内边距（bottom: 80）
- [x] 7+ 条模板时无 RenderFlex overflow 错误
- [x] 6 条及以下模板时布局无回归

### Task 39: @ 模板选择器 tab 分类
- [x] 弹窗中有"对话"和"规则"两个 tab（两种类型均存在时）
- [x] 切换 tab 时列表正确切换对应类型模板
- [x] 仅一种类型时 tab 栏隐藏
- [x] 选中回调逻辑不变

### Task 40: 对话模板仅展示 AI 结果
- [x] 选择对话模板后不出现用户 prompt 对话气泡
- [x] AI 返回结果以内容卡片块样式展示（非对话气泡）
- [x] 普通对话不受影响，仍以对话气泡展示

### Task 41: 全量验证
- [x] `flutter analyze` 零新增 error

---

## v22 第九轮迭代（待验证，共 11 项）

### Task 42: AI 收件箱卡片样式完全统一
- [x] 外层 Container margin 改为 `EdgeInsets.only(bottom: 10)`，无 horizontal margin
- [x] `Card` 已替换为 `Container + BoxDecoration`，无 elevation
- [x] 背景色：暗色 `0xFF1E1E1E`，亮色 `0xFFFBFBFB`
- [x] 圆角 `14`，边框 `theme.dividerColor.withValues(alpha: 0.06)`
- [x] 内边距 `EdgeInsets.all(14)`
- [x] 所有交互功能正常

### Task 43: @ 模板选择器 Tab 分类验证
- [x] 双类型时 Tab 栏显示且切换正确
- [x] 仅 chat 类型时 Tab 栏隐藏
- [x] 仅 rule 类型时 Tab 栏隐藏
- [x] 选中回调逻辑与原设计一致

### Task 44: 全量验证
- [x] `flutter analyze` 零新增 error

---

## v23 第十轮迭代（已验证全部通过，共 11 项）

### Task 45: 收件箱操作按钮图标化
- [x] "重新生成"按钮仅显示 `Icons.refresh` 图标，无文字标签
- [x] "拒绝"按钮仅显示 `Icons.close` 图标（error 色），无文字标签
- [x] "确认分发"按钮仅显示 `Icons.check` 图标，缺键时 disabled
- [x] 已拒绝/已确认状态的按钮维持原样不变

### Task 46: "查看全部"与图标按钮合并行
- [x] 移动端字段 > 4 时：底部显示一行"查看全部 (N)" + 右侧三个图标按钮
- [x] 移动端字段 ≤ 4 时：底部仅显示图标按钮靠右
- [x] PC 端：图标按钮独立靠右显示
- [x] 图标按钮间距 ≥ 12px，点击区域 ≥ 36×36px

### Task 47: Tab 选择器渲染修复
- [x] `_hasActiveInbox=true` 时 rule 模板不再被过滤
- [x] 双类型模板存在时 Tab 栏正常显示

### Task 48: 全量验证
- [x] `flutter analyze` 零新增 error

---

## v24 第十一轮迭代（待验证，共 5 项）

### Task 49: 已确认状态按钮图标化
- [x] "编辑数据"为 `IconButton(Icons.edit)`，无文字标签，36x36 点击区域
- [x] "撤销分发"为 `IconButton(Icons.undo)`（error 色），无文字标签，36x36 点击区域
- [x] 按钮间距 12px
- [x] 已拒绝状态"编辑后重新规则化"不受影响

### Task 50: 全量验证
- [x] VS Code 诊断零新增 error

---

## v25 第十二轮迭代（已实施，共 5 项）

### Task 51: 已确认按钮移至"查看全部"同一行
- [x] 新建 `_buildConfirmedActionIcons` 辅助方法，风格与 `_buildPendingActionIcons` 一致
- [x] `trailingActions` 在 `isConfirmed` 时传入 `_buildConfirmedActionIcons`
- [x] 底部 `_buildInboxActions` 仅在 `isRejected` 时渲染
- [x] `_buildInboxActions` 签名简化，移除死分支

### Task 52: 全量验证
- [x] VS Code 诊断零新增 error
