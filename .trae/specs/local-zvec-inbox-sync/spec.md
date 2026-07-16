# 本地向量化 + AI 收件箱优化 + 多目的地同步 Spec

## Why
当前系统依赖在线 Embedding API 生成语义向量，存在网络依赖、隐私风险和额外成本。同时 AI 收件箱缺少字段别名、手动编辑和补录能力，数据分发也仅限单一目标模块，无法满足多模块同步落地的实际需求。

### 第四轮迭代（v17）
前三轮（v14/v15/v16）实现了向量本地化、收件箱交互优化、多目的地同步和 @ 模板整合，但核心处理管线仍存在三项全局性缺陷：(1) 离线状态下用户输入无保障存储，数据有丢失风险；(2) 口语化冗余词（如"嗯、呀、这个、那个"等）未经清洗直接送 AI 分析，浪费 token 且降低意图识别准确率；(3) AI 分析过程耦合在主线程同步执行，阻塞 UI；(4) 规则化结果仍以 JSON 格式展示，可读性差且与系统 UI 风格不统一。

## What Changes

### 第一轮（已完成 v14）
- **彻底移除在线向量大模型接入**
- **AI 收件箱交互优化**：字段别名、手动编辑、缺键补录
- **多目的地数据同步**：DispatchService 多表同时写入

### 第二轮（已完成 v15）
- **空值键值全量渲染**
- **已拒绝/已确认记录再规则化**
- **手动规则化触发**

### 第三轮（已完成 v16）
- **手动规则化整合到 @ 模板系统**：移除独立按钮，复用 @ 选择器
- **AiTemplates 新增 templateType 字段**（chat/rule）
- **默认规则化模板预填充**（CRM/LEDGER/TODO）
- **模板管理页面 CRUD 全生命周期**

### 第四轮迭代（v17 - 已完成）
- **两阶段异步处理架构**：将 ProcessingPipeline 拆分为"同步优先"和"异步后置"两个独立阶段
  - **第一阶段（同步，保障数据落地）**：离线检测 → 加密本地存储 → 冗余词清洗 → 落库
  - **第二阶段（异步，保障 UI 流畅）**：后台独立任务 → AI 特征识别 → 模板匹配 → 结构化提取 → 收件箱分发
- **口语化冗余词清洗服务**：新建 `TextCleanerService`，精准剔除"嗯、呀、这个、那个、哦、啊、嗯呐、对吧、说白了"等无业务价值的语气词、填充词
- **离线本地加密存储**：离线时用户输入写入加密本地存储，网络恢复后自动出队处理
- **输出格式规范化**：禁止在前端展示发送给 AI 的原始指令内容；AI 结果禁止以 JSON 格式输出；结构化表格类结果使用系统统一表格组件渲染，纯文本类结果复用现有笔记内容块样式
- **非匹配内容处理**：未匹配任何业务规则的内容标记为普通文本，仅保留基础存储，提供手动规则化入口

### 第五轮迭代（v18 - 本次）：四项缺陷修复与体验优化
测试发现 v17 存在四个关键问题，本轮集中修复：

1. **网络恢复联动缺失**：`_retryFailedItems` 中 `_queuedIds` 未清理导致离线保存的消息在网络恢复后无法重新入队，必须重启应用才能触发处理
2. **去口语化清洗失效**：`TextCleanerService` 正则要求冗余词两端均有标点分隔符，但实际中文口语中填充词常以 inline 形式出现无任何分隔，导致几乎所有单字/双字填充词均无法匹配
3. **处理状态动画过度干扰**：处理中状态使用持续旋转 `CircularProgressIndicator`，无意义动画造成视觉干扰；状态横幅常驻页面顶部不退隐
4. **移动端收件箱布局不佳**：无移动端适配，`Wrap` 布局不限制条目数，铅笔编辑图标占用有限空间

### 第六轮迭代（v19 - 本次）：两项细节打磨

1. **移动端收件箱条目数收紧**：当前移动端最多展示 6 条，过多条目在小屏上密集难读，收紧为 4 条
2.6. **已有规则触发时隐藏规则模板**：当 AI 已明确识别意图并路由到收件箱（存在 `pendingReview` 状态的收件箱条目）时，@ 模板选择器中不再展示 `templateType == 'rule'` 的规则化模板，避免用户重复操作；仅在无明确规则触发时才显示规则模板入口

### 第七轮迭代（v20 - 本次）：模板渲染收尾修复 + 规则识别核心键值提取升级

1. **模板网格渲染收尾修复**：v19 仅在底部 @ 选择器过滤了 rule 模板，但 `_buildTemplateGrid`（页面主体区域的预设模板按钮网格）在 `_hasActiveInbox` 时仍会渲染全部模板（含 rule 类型），导致 AI 收件箱上方出现冗余的"提取待办事项"等规则化按钮。需在 `_hasActiveInbox = true` 时彻底禁用 `_buildTemplateGrid` 的渲染。

2. **TODO 规则标题提取能力缺失**：当前 `AiRouterService._routingTools` 的 function calling 定义和 `IntentRouter.extractEntities` 均不包含 `title` 字段。AI 路由 TODO 时仅返回 `intent_tag=TODO` 但无法从原文中自动总结出待办事项的主题标题，导致收件箱中 TODO 条目缺乏核心摘要。需在工具定义和系统 prompt 中补充 `title` 提取能力。

### 第八轮迭代（v21 - 本次）：四项细节优化

1. **AI 收件箱样式统一**：移除 `_buildDispatchInboxCard` 的彩色外框描边，使其风格与页面上方标准内容块对齐，体现"具备特殊功能的常规内容块"定位。
2. **模板管理页溢出修复**：`ReorderableListView.builder` 在 7+ 条记录时与 FAB 重叠导致底部溢出，需修复布局。
3. **@ 模板选择器 tab 分类**：`_showTemplatePicker` 新增 tab 栏，将 chat/rule 模板分开展示，支持用户自由切换。
4. **对话模板结果展示重构**：选择对话模板后不再展示发送的 prompt，仅以内容卡片块展示 AI 返回结果。

## Impact
- Affected specs: 基于 `local-zvec-inbox-sync` v20 继续迭代
- Affected code (v21):
  - **修改** `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`（`_buildDispatchInboxCard` 去描边、`_sendPromptToAi` 重构为内容卡片块）
  - **修改** `lib/features/idea_stream/presentation/pages/template_management_page.dart`（修复 7 条溢出）
  - **修改** `lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart`（`_showTemplatePicker` 新增 tab 分类）
- Affected code (v20):
  - **修改** `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`（两处 `_buildTemplateGrid` 调用添加 `!_hasActiveInbox` 守卫）
  - **修改** `lib/core/services/ai_router_service.dart`（`_routingTools` 新增 `title` 字段 + system prompt 强化）
  - **修改** `lib/core/utils/intent_router.dart`（`ExtractedEntities` 新增 `title` 字段）

## ADDED Requirements

### Requirement: 两阶段异步处理架构
系统 SHALL 将处理管线拆分为独立的"同步第一阶段"和"异步第二阶段"，严格遵循分步处理的优先级顺序：

**第一阶段（同步，priority 高）**：
1. 检测网络连通性
2. 若离线：将原始 `rawText` 加密写入本地 `offline_queue`（保障不丢失）
3. 执行 `TextCleanerService.clean(rawText)` 剔除口语化冗余词
4. 将清洗后的 `cleanedText` 作为 `raw_text` 存入 `HubPayloads`
5. 标记 `processingStatus = textCleaned`
6. 立即返回（不阻塞 UI）

**第二阶段（异步，独立后台任务）**：
1. 后台 `Timer` 或 `Isolate` 定时扫描 `processingStatus = textCleaned` 的记录
2. 执行 FTS 本地索引
3. 调用 AI 路由进行意图分类与实体抽取
4. 匹配业务规则模板 → 写入 AI 收件箱
5. 未匹配的标记为普通文本 → `processingStatus = dispatched`

#### Scenario: 离线输入处理
- **WHEN** 用户设备无网络，提交文本"嗯，这个客户张三呀，联系一下吧"
- **THEN** 第一阶段：检测到离线 → 加密保存原文 → 清洗为"客户张三，联系一下" → 落库 → 标记 textCleaned
- **AND** 第二阶段：网络恢复后自动扫描 → FTS 索引 → AI 路由 → CRM 收件箱

#### Scenario: 在线输入处理
- **WHEN** 用户设备有网络，提交文本"对了那个花了 50 块钱吃饭"
- **THEN** 第一阶段：检测在线 → 直接清洗为"花了 50 块钱吃饭" → 落库 → 标记 textCleaned
- **AND** 第二阶段：立即启动后台任务 → AI 路由 → LEDGER 收件箱

### Requirement: 口语化冗余词清洗
系统 SHALL 提供 `TextCleanerService` 对用户输入文本做预处理清洗，精准剔除无效语气词：
- 目标词库：`嗯`、`呀`、`这个`、`那个`、`哦`、`啊`、`嗯呐`、`对吧`、`说白了`、`就是说`、`然后`、`那个啥`、`就是`、`反正`、`话说`、`额`、`嘛`
- 清洗后保留原文语义完整性（仅剔除独立使用的填充词，不破坏正常词汇）
- 清洗过程纯本地正则匹配，无网络依赖，100ms 内完成

#### Scenario: 冗余词清洗示例
- **WHEN** 输入 "嗯，这个客户张三呀，对吧，联系一下"
- **THEN** 清洗后得到 "客户张三，联系一下"

### Requirement: 输出格式规范化
系统 SHALL 确保 AI 处理结果按以下规范输出，禁止在前端展示原始 AI 指令：

1. **禁止原始指令展示**：`AiEngine.chat()` 的 system prompt 不输出到 UI，仅 `response` 内容展示
2. **禁止 JSON 格式输出**：AI 返回的实体抽取结果自动解析为 `RoutingResult.entities`，不直接输出 JSON 字符串
3. **结构化表格结果**：CRM/TODO/LEDGER 类的结果通过 `_InboxFieldList` 组件（已有）以结构化键值对展示
4. **纯文本结果**：NOTE 类直接复用 `ContentBlock` 或 `AiConversation` 的渲染样式
5. **收件箱详情**：提取后的结构化字段（person_name、amount、title 等）在收件箱卡片中已有中文标签展示

## MODIFIED Requirements

### Requirement: ProcessingPipeline 拆分两阶段（原：单线程同步处理）
原行为：`_processOne()` 包含 FTS 索引 + AI 路由 + 分发，全部在同一同步循环中执行
改为：
- `processSync(payloadId)` — 仅执行清洗 + 落库，立即返回
- `processAsync(payloadId)` — 后台独立任务，执行 FTS + AI + 分发
- `_backgroundWorker` — 定时扫描 `textCleaned` 状态的记录，自动出队

### Requirement: ProcessingStatus 新增状态
原行为：`syncedLocal → vectorChecking → aiRouting → dispatching → pendingReview/dispatched`
新增两个状态（按顺序插入）：
- `offlineSaved` — 离线时原始数据已加密落库，等待网络恢复
- `textCleaned` — 文本已完成清洗并落库，等待异步 AI 分析
新流程：`syncedLocal → offlineSaved（离线）/ textCleaned（在线）→ vectorChecking → aiRouting → dispatching → pendingReview/dispatched`

### Requirement: HubPayloads 存储清洗文本
原行为：`HubPayloads.rawText` 存储原始用户输入
改为：第一阶段清洗后，将 `cleanedText` 写入 `rawText`（覆盖），原始文本保留在 `offline_queue` 表中备份
- Schema version → 15

## REMOVED Requirements

### Requirement: ProcessingPipeline.enqueue 的单步同步处理
**Reason**: 当前 `enqueue` → `_processNext` 在同一调用栈中串行执行 FTS + AI 路由，AI 调用阻塞主循环
**Migration**: `enqueue` 改为调用 `processSync`，仅执行清洗落库；AI 路由移至 `_backgroundWorker` 独立定时任务

---

## v18 ADDED Requirements

### Requirement: 网络恢复自动触发离线队列处理
系统 SHALL 在网络恢复时自动将 `processingStatus = offlineSaved` 的消息重新入队处理，无需重启应用。

**根因**：`_retryFailedItems()` 调用 `enqueue()` 时，`_queuedIds` 集合仍保留首次离线时的入队记录，导致 `enqueue` 的守卫条件 `_queuedIds.contains(payloadId)` 返回 true 而直接跳过。

#### Scenario: 离线保存后网络恢复自动处理
- **WHEN** 用户离线提交消息"A"，消息标记为 `offlineSaved` 且 payloadId 已加入 `_queuedIds`
- **AND** 网络恢复，`_connectivitySub` 触发 `_retryFailedItems()`
- **THEN** `_retryFailedItems` 中清理 `_queuedIds` 或绕过 `enqueue` 守卫，直接调用 `processSync` 将消息状态从 `offlineSaved` 转为 `textCleaned`
- **AND** 后台 Worker 在 3 秒内扫描到 `textCleaned` 消息并执行 AI 分析
- **AND** 日志记录处理进度，避免重复处理已完成消息

#### Scenario: 多次断网重连不重复处理
- **WHEN** 网络反复断连，`_retryFailedItems` 被多次调用
- **THEN** `getPendingVectorPayloads` 仅返回确实处于 `offlineSaved` 等待处理状态的消息
- **AND** 已转为 `textCleaned` 或 `dispatched` 的消息不会被重复入队

### Requirement: 去口语化清洗正则修复
系统 SHALL 正确识别并清洗所有口语化冗余词，无论其是否被标点符号包围。

**根因**：`TextCleanerService.clean()` 的 Step 1 正则 `(^|[标点\\s])词($|[标点\\s])` 要求冗余词两端均有标点或空白分隔。但中文口语中填充词常直接连接实义词（如"嗯这个客户"），无任何标点分隔，导致 "嗯" 后面紧跟 "这" 不匹配、 "这个" 前后均无标点也不匹配。

#### Scenario: inline 填充词清洗
- **WHEN** 输入 "嗯这个客户张三呀需要联系一下"
- **THEN** 清洗后得到 "客户张三需要联系一下"（"嗯"、"这个"、"呀" 均被移除，"一下" 保留因其非目标词）

#### Scenario: 标点包围填充词清洗（原逻辑保留）
- **WHEN** 输入 "说白了，这个项目，嗯，就是需要审核"
- **THEN** 清洗后得到 "项目，需要审核"（"说白了"、"这个"、"嗯"、"就是" 被移除，逗号保留）

#### Scenario: 有意义词汇不被误删
- **WHEN** 输入 "那个项目就是这个功能的核心"
- **THEN** "那个" 作为指示代词保留、"就是" 根据上下文判断（此场景中均非纯填充词，应保留）
- **AND** 至少不破坏核心语义信息

### Requirement: AI 处理状态静态图标 + 进度横幅定时退隐
系统 SHALL 将处理中的旋转动画替换为稳定静态图标，并在详情页顶部状态横幅实现 1.5 秒自动退隐机制。

#### Scenario: 卡片角标静态图标
- **WHEN** 消息处于 `vectorChecking`、`aiRouting`、`dispatching`、`pendingReview`、`textCleaned` 任一中间处理状态
- **THEN** 首页卡片右上角显示静态图标（替代 `CircularProgressIndicator`）：
  - `textCleaned` / `vectorChecking` → `Icons.manage_search_rounded`（搜索/分析中）
  - `aiRouting` → `Icons.auto_awesome_rounded`（AI 思考中）
  - `dispatching` / `pendingReview` → `Icons.inbox_rounded`（收件箱待确认）
  - `offlineSaved` / `failedRetry` → `Icons.hourglass_empty_rounded`（等待中，已有）
  - `dispatched` / `decayed` → `Icons.check_circle_rounded`（完成，已有）

#### Scenario: 详情页状态横幅 1.5s 退隐
- **WHEN** 用户打开一条处理中的消息详情页
- **THEN** 顶部显示状态横幅（如"AI 正在分析归类..."），1.5 秒后自动隐藏
- **AND** 若用户关闭页面后再次打开同一条消息，且 AI 处理仍未完成分发，横幅重新展示并再次 1.5 秒后退隐
- **AND** 若 AI 处理已完成（`dispatched` 或 `decayed`），横幅永久不再显示

#### Scenario: 不同处理阶段显示对应静态图标和状态文案
- **WHEN** 消息处于 `textCleaned` 状态
- **THEN** 横幅显示静态图标（非旋转） + "文本已清洗，等待 AI 分析..."
- **WHEN** 消息处于 `failedRetry` 状态
- **THEN** 横幅显示 "处理暂停，等待网络恢复..."（不变）

### Requirement: 移动端收件箱紧凑布局
系统 SHALL 在移动端（宽度 < 600px）对 AI 收件箱字段列表应用紧凑布局。

#### Scenario: 移动端单列紧凑排版
- **WHEN** 屏幕宽度 < 600px（手机端）
- **THEN** 收件箱字段列表限制最多展示 6 条，超出时显示"查看全部 (N)"折叠入口
- **AND** 每个字段 Chip 宽度占满可用空间（单列布局），label 与 value 叠放或紧凑并排
- **AND** 移除每个 Chip 尾部的铅笔编辑图标（`Icons.edit_outlined`），保留点击 Chip 弹出编辑对话框的交互

#### Scenario: PC 端不受影响
- **WHEN** 屏幕宽度 >= 600px（PC 端）
- **THEN** 保持原有 `Wrap` 多列布局，不限制条目数，编辑图标正常显示

---

## v19 ADDED Requirements

### Requirement: 移动端收件箱条目数收紧为 4 条
系统 SHALL 在移动端将收件箱字段列表的最多可见条目数从 6 条收紧为 4 条，超出时显示"查看全部 (N)"折叠入口。

#### Scenario: 移动端最多 4 条
- **WHEN** 屏幕宽度 < 600px，收件箱有 5+ 个字段
- **THEN** 默认仅展示前 4 条，底部显示"查看全部 (5)"入口
- **AND** PC 端不受影响

### Requirement: 已触发规则时隐藏 @ 规则模板
系统 SHALL 在 payload 已有活跃收件箱条目（AI 已识别明确业务规则）时，从 @ 模板选择器中过滤掉 `templateType == 'rule'` 的规则化模板，避免用户重复执行已完成的规则化操作。

判断条件：`payload.processingStatus == 'pendingReview'`（即 AI 已将内容路由到收件箱等待用户确认分发）。

#### Scenario: 已有收件箱条目时隐藏规则模板
- **WHEN** 用户打开详情页，该 payload 存在 `pendingReview` 状态的收件箱条目（AI 已识别 CRM/LEDGER/TODO 等明确意图）
- **THEN** `AiChatInputBox` 的 @ 模板选择器中仅显示 `templateType != 'rule'` 的普通 chat 模板
- **AND** 用户长按 @ 仍可进入模板管理页面

#### Scenario: 无规则触发时显示规则模板
- **WHEN** 用户打开详情页，该 payload 不存在活跃收件箱条目（AI 未识别到明确业务规则）
- **THEN** @ 模板选择器正常显示全部模板（含 chat 和 rule 类型）
- **AND** 用户可选择规则化模板手动触发规则化处理

---

## v20 ADDED Requirements

### Requirement:已触发规则时彻底禁用模板网格渲染
系统 SHALL 在 payload 已有活跃收件箱条目（`_hasActiveInbox = true`）时，不再渲染页面主体区域的 `_buildTemplateGrid` 预设模板按钮网格，避免与收件箱功能重复。

**根因**：v19 仅在底部 `AiChatInputBox` 的 @ 选择器中过滤了 rule 模板，但 `_buildTemplateGrid`（位于 body 区域 `conversations.isEmpty` 分支）仍会渲染全部模板，导致"提取待办事项"等 rule 按钮出现在收件箱卡片上方。

**v20 补丁**：`_hasActiveInbox` 从仅判断 `pendingReview` 扩展为同时匹配 `dispatched` 和 `decayed`。确认分发后 status 变为 `dispatched`，原判断失效导致重进入页面时模板重新加载。扩展后，一旦该 payload 经历过收件箱流转，模板永久不显示。

#### Scenario: 有活跃收件箱时隐藏模板网格
- **WHEN** `_hasActiveInbox = true`（存在 `pendingReview` 状态的收件箱条目）
- **THEN** 页面 body 中的 `_buildTemplateGrid` 不渲染（两个调用点均添加 `!_hasActiveInbox` 守卫）
- **AND** 底部 @ 选择器继续遵循 v19 逻辑（过滤 rule 模板）

#### Scenario: 无活跃收件箱时正常显示模板网格
- **WHEN** `_hasActiveInbox = false`
- **THEN** `_buildTemplateGrid` 正常渲染全部模板
- **AND** 底部 @ 选择器显示全部模板

### Requirement: TODO 规则标题自动提取
系统 SHALL 在识别 TODO 意图时，从用户原始输入中自动总结提取待办事项的核心主题标题，填充到 `title` 字段，确保收件箱中 TODO 条目有明确的摘要描述。

#### Scenario: AI 云端路由提取 TODO 标题
- **WHEN** 用户输入"明天下午3点跟张三开会讨论项目进度"
- **AND** AI function calling 返回 `intent_tag = TODO`
- **THEN** 返回的 entities 中包含 `title: "跟张三开会讨论项目进度"`
- **AND** `due_date_text: "明天下午3点"` 和 `person_name: "张三"` 同时被提取

#### Scenario: 本地降级提取 TODO 标题
- **WHEN** 离线状态下用户输入"记得周五前提交报销单"
- **AND** 本地 `IntentRouter.extractEntities` 识别为 TODO
- **THEN** `title` 字段包含"提交报销单"
- **AND** `due_date_text: "周五前"` 同时被提取

#### Scenario: 非 TODO 意图不提取标题
- **WHEN** AI 路由返回 `intent_tag = LEDGER` 或 `CRM` 等非 TODO 意图
- **THEN** `title` 字段为 null，不强制填充

---

## v21 ADDED Requirements

### Requirement: AI 收件箱卡片去除外框描边，对齐标准内容块样式
系统 SHALL 移除 `_buildDispatchInboxCard` 中 `Card` 组件的 `shape: RoundedRectangleBorder(side: BorderSide(...))` 外框描边样式，使其视觉风格与页面上方的标准内容块（如笔记正文卡片）保持一致，呈现为无彩色边框的常规内容块。

#### Scenario: 收件箱卡片无彩色边框
- **WHEN** 用户打开包含活跃收件箱的详情页
- **THEN** `_buildDispatchInboxCard` 渲染的卡片无 `BorderSide` 外框描边
- **AND** 卡片的所有交互功能（字段编辑、分发确认、折叠展开等）完整保留
- **AND** 卡片在暗色/亮色主题下均与上方内容块视觉对齐

### Requirement: 模板管理页列表溢出修复
系统 SHALL 修复 `template_management_page.dart` 中模板条目数 >= 7 时 `ReorderableListView.builder` 与 `FloatingActionButton` 重叠导致底部溢出错误的布局问题。

**根因**：`ReorderableListView.builder` 直接作为 `Scaffold.body`，无底部安全区或内边距预留 FAB 空间，当列表高度超过可视区域时最后一条被 FAB 遮挡并触发布局溢出。

#### Scenario: 7+ 条模板无溢出
- **WHEN** 模板管理页存在 7 条或更多模板记录
- **THEN** `ReorderableListView` 底部有足够内边距或 SafeArea，不与 FAB 重叠
- **AND** 无 RenderFlex overflow 错误
- **AND** 6 条及以下模板时布局不变

### Requirement: @ 模板选择器新增 tab 分类切换
系统 SHALL 在 `AiChatInputBox._showTemplatePicker` 底部弹窗中新增 tab 分类切换机制，将模板按 `templateType` 拆分展示：

- **对话（chat）tab**：展示所有 `templateType == 'chat'` 的对话类模板
- **规则（rule）tab**：展示所有 `templateType == 'rule'` 的规则化模板
- 默认选中第一个有内容的 tab
- 仅当单一类型的模板数量 > 0 时才显示对应 tab（无内容的 tab 自动隐藏）
- 后续扩展新类型时 tab 栏自动适配

#### Scenario: 两种类型模板均存在时显示双 tab
- **WHEN** 数据库中存在 chat 和 rule 两类模板
- **THEN** 弹窗顶部显示"对话"和"规则"两个 tab
- **AND** 用户切换 tab 时下方列表切换为对应类型的模板
- **AND** 选中某个模板后执行与当前一致的选中回调逻辑

#### Scenario: 仅一种类型时隐藏 tab 栏
- **WHEN** 数据库中仅存在 chat 类型模板（无 rule 模板）
- **THEN** 弹窗直接展示 chat 模板列表，不显示 tab 栏
- **AND** 当仅存在 rule 类型模板时同理

#### Scenario: 已有活跃收件箱时 rule tab 自动隐藏
- **WHEN** `_hasActiveInbox = true`
- **THEN** `_showTemplatePicker` 中 rule tab 不显示（因 rule 模板已被过滤）
- **AND** 仅显示 chat 模板（无 tab 栏）

### Requirement: 对话模板选择后仅展示 AI 返回结果，使用内容卡片块样式
系统 SHALL 修改 `_sendPromptToAi` 的对话模板执行逻辑：
1. **不再将用户选择的模板 prompt 写入 conversation 表**（不再以对话气泡展示发送的模板内容）
2. 将 prompt 直接发送给 AI，仅将 AI 返回的处理结果作为正文内容块（ContentBlock 或等效内容卡片）展示在页面上
3. 内容块样式复用现有笔记内容卡片的 `Card` 样式，以正式内容形态呈现，支持后续编辑和拓展操作

#### Scenario: 选择对话模板后仅展示 AI 结果
- **WHEN** 用户在 @ 模板选择器中选中一个 `templateType == 'chat'` 的模板（如"总结要点"）
- **THEN** 页面不出现用户发送模板 prompt 的对话气泡
- **AND** AI 返回结果以内容卡片块形式展示（非对话气泡样式）
- **AND** 内容卡片块与页面上方笔记正文块视觉风格一致
- **AND** 用户可对内容卡片块进行后续编辑操作

#### Scenario: 普通对话（非模板触发）不受影响
- **WHEN** 用户在底部输入框直接输入文本与 AI 对话
- **THEN** 用户消息和 AI 回复仍以原有对话气泡形式展示
- **AND** 对话模板触发的内容卡片块不影响普通对话的消息流

---

### 第九轮迭代（v22 - 本次）：布局样式统一 + @ 模板选择器 Tab 功能验证

1. **AI 收件箱与内容块样式彻底统一**：v21 仅移除了外框描边，但收件箱卡片与上方内容块在宽度（含横向 margin）、内边距、背景色、圆角、边框、阴影等多维度仍不一致，需全面对齐。
2. **@ 模板选择器 Tab 分类功能验证**：v21 已完成 Tab 分类功能的代码实现，本轮需对双类型、单对话类型、单规则类型三种场景进行系统性验证。

## Impact
- Affected specs: 基于 `local-zvec-inbox-sync` v21 继续迭代
- Affected code (v22):
  - **修改** `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`（`_buildDispatchInboxCard` 全面对齐内容块样式）
  - **验证** `lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart`（已有 Tab 分类功能，本轮仅验证不修改）

## v22 ADDED Requirements

### Requirement: AI 收件箱卡片与内容块样式完全统一
系统 SHALL 将 `_buildDispatchInboxCard` 的外层结构从 `Container(margin: horizontal: 12) → Card(elevation, custom color) → Padding(12)` 重构为与 `_buildContentBlock` 完全一致的 `Container(margin: bottom: 10) → BoxDecoration` 样式体系：

- **宽度**：移除 `width: double.infinity` 和外层 `horizontal: 12` margin，改为 `margin: EdgeInsets.only(bottom: 10)`（与内容块完全一致）
- **内边距**：从 `12` 调整为 `14`
- **背景色**：暗色 `Color(0xFF1E1E1E)`，亮色 `Color(0xFFFBFBFB)`（与内容块一致）
- **圆角**：从 `12` 调整为 `14`
- **边框**：新增 `Border.all(color: theme.dividerColor.withValues(alpha: 0.06), width: 1)`（与内容块一致）
- **阴影**：移除 `Card(elevation: ...)`，改用 `Container + BoxDecoration`（无 elevation）

#### Scenario: 收件箱卡片与内容块外观完全一致
- **WHEN** 用户打开包含活跃收件箱的详情页
- **THEN** AI 收件箱卡片的宽度、边距、内边距、背景色、圆角、边框均与上方内容块完全一致
- **AND** 卡片的所有交互功能完整保留
- **AND** 暗色/亮色主题下两者视觉不可区分（除收件箱独有的内部 UI 元素外）

### Requirement: @ 模板选择器 Tab 分类功能验证
系统 SHALL 验证 v21 已实现的 `_showTemplatePicker` Tab 分类切换功能在以下三种场景下均符合预期：

#### Scenario: 双类型模板存在时双 Tab 正常切换
- **WHEN** 数据库中同时存在 chat 和 rule 两类模板
- **THEN** 弹窗显示"对话"和"规则"两个 Tab
- **AND** 默认显示第一个 Tab（对话）的模板列表
- **AND** 切换到"规则" Tab 时正确展示 rule 模板列表
- **AND** 选中任一模板后回调逻辑与原设计一致

#### Scenario: 仅对话类型模板时无 Tab 栏
- **WHEN** 数据库中仅存在 chat 类型模板
- **THEN** 弹窗直接展示对话模板列表，不显示 Tab 栏

#### Scenario: 仅规则类型模板时无 Tab 栏
- **WHEN** 数据库中仅存在 rule 类型模板
- **THEN** 弹窗直接展示规则模板列表，不显示 Tab 栏

---

### 第十轮迭代（v23 - 本次）：收件箱按钮图标化 + Tab 选择器渲染修复

1. **收件箱操作按钮图标化并合并到"查看全部"行**：将重新生成、拒绝、确认分发三个按钮的文字标签移除（仅保留图标），并与移动端的"查看全部"按钮合并到同一行靠右对齐，保持合理间距和可点击区域。
2. **@ 模板选择器 Tab 渲染修复**：排查到 v19 在 `idea_detail_page.dart` 中 `_hasActiveInbox` 时过滤 rule 模板（v19 Task 32）导致 Tab 选择器永不出现。移除该过滤逻辑，让全部模板传入选择器以正常渲染 Tab 栏。

## Impact
- Affected specs: 基于 `local-zvec-inbox-sync` v22 继续迭代
- Affected code (v23):
  - **修改** `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`（`_buildInboxActions` 图标化 + "查看全部"行合并 + 移除 rule 模板过滤）
  - **无需修改** `lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart`（代码已验证正确，仅解除上游过滤即可生效）

## v23 MODIFIED Requirements

### Requirement: 已触发规则时隐藏 @ 规则模板 → 不再过滤规则模板
**v19 原行为**：`_hasActiveInbox = true` 时从 `AiChatInputBox.templates` 中过滤掉 `templateType == 'rule'` 的模板。

**v23 改为**：移除该过滤逻辑，将所有模板（含 rule 类型）完整传入 `AiChatInputBox`，使 `_showTemplatePicker` 能够正常检测到 rule 模板存在并渲染 Tab 切换栏。原 v19 意图（避免已规则化的条目再次触发规则化）由 Tab 分类界面自然解决——用户可看到规则模板存在但无需使用它们。

#### Scenario: 活跃收件箱时 Tab 栏正常显示
- **WHEN** 用户打开已 AI 识别到规则并产生收件箱的详情页
- **AND** 数据库中同时存在 chat 和 rule 模板
- **THEN** @ 选择器弹窗显示"对话"和"规则"两个 Tab
- **AND** 规则模板列表正常可查看

## v23 ADDED Requirements

### Requirement: 收件箱操作按钮图标化并合并到"查看全部"行
系统 SHALL 将 `_buildInboxActions` 中"重新生成""拒绝""确认分发"三个按钮的文字标签移除，仅保留图标，并将这些图标按钮与移动端"查看全部"按钮合并到同一行靠右对齐。

按钮与图标映射：
- 重新生成 → `Icons.refresh`
- 拒绝 → `Icons.close`（使用 `theme.colorScheme.error` 色）
- 确认分发 → `Icons.check`（缺键时 disabled 灰色）

"编辑后重新规则化"（已拒绝状态）、"编辑数据"和"撤销分发"（已确认状态）维持原样不变。

#### Scenario: 待审核状态图标按钮合并行
- **WHEN** 收件箱处于待审核状态且移动端字段超过 4 条
- **THEN** 字段列表底部显示一行：左侧"查看全部 (N)" + 右侧三个图标按钮（重新生成、拒绝、确认分发）
- **AND** 图标按钮间距 ≥ 12px，点击区域 ≥ 36×36px
- **AND** PC 端图标按钮独立靠右显示（无"查看全部"）

#### Scenario: 待审核状态移动端字段 ≤ 4 条
- **WHEN** 收件箱处于待审核状态且移动端字段 ≤ 4 条
- **THEN** 字段列表底部仅显示三个图标按钮靠右对齐（无"查看全部"文字）
- **AND** PC 端行为不变

#### Scenario: 已拒绝/已确认状态
- **WHEN** 收件箱处于已拒绝或已确认状态
- **THEN** "编辑后重新规则化"（已拒绝）维持原有带文字标签的按钮不变
- **AND** "编辑数据"和"撤销分发"（已确认）改为图标按钮（`Icons.edit` + `Icons.undo`），与 pending 状态图标按钮风格一致

---

### 第十一轮迭代（v24 - 本次）：已确认状态按钮图标化收尾

把 v23 未覆盖的已确认状态两个按钮同步图标化：
- "编辑数据" → `IconButton(Icons.edit, tooltip: '编辑数据')`
- "撤销分发" → `IconButton(Icons.undo, color: error, tooltip: '撤销分发')`

## Impact
- Affected specs: 基于 `local-zvec-inbox-sync` v23 继续迭代
- Affected code (v24):
  - **修改** `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`（`_buildInboxActions` 已确认分支两按钮图标化）

## v24 MODIFIED Requirements

### Requirement: 收件箱操作按钮图标化 → 扩展到已确认状态
**v23 原行为**：已确认状态的"编辑数据"和"撤销分发"按钮保持文字标签。

**v24 改为**：与 pending 状态一致，改为 `SizedBox(36x36) + IconButton` 图标按钮。

#### Scenario: 已确认状态图标按钮
- **WHEN** 收件箱已确认分发
- **THEN** 底部显示 `Icons.edit` 图标按钮（tooltip: '编辑数据'）和 `Icons.undo` 图标按钮（error 色，tooltip: '撤销分发'）
- **AND** 间距 ≥ 12px，点击区域 36×36px
- **AND** 已拒绝状态的"编辑后重新规则化"维持文字标签不变

---

## v25 第十二轮迭代：已确认按钮移至"查看全部"同一行

### Why
v24 将已确认状态的"编辑数据"和"撤销分发"图标化后，它们仍渲染在卡片底部独立行。需与 pending 状态的"重新生成/拒绝/确认"对齐，统一放入 `_InboxFieldList` 的尾部（与"查看全部"同行）。

### What Changes
- 新建 `_buildConfirmedActionIcons` 辅助方法，产出与 `_buildPendingActionIcons` 风格一致的 Row
- 更新 `_buildDispatchInboxCard` 中 `trailingActions`：`isConfirmed` 时传入 `_buildConfirmedActionIcons`
- 底部 `_buildInboxActions` 调用条件收窄为仅 `isRejected`
- 简化 `_buildInboxActions` 签名，移除已确认/pending 死分支

## Impact
- Affected code:
  - **修改** `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`

## v25 MODIFIED Requirements

### Requirement: 已确认操作按钮移至字段尾部行
**v24 原行为**：已确认状态图标按钮渲染在 `_buildDispatchInboxCard` 底部独立行。

**v25 改为**：通过 `trailingActions` 参数传入 `_buildInboxFields`，与"查看全部"同行渲染。

#### Scenario: 已确认状态操作按钮与"查看全部"同行
- **WHEN** 收件箱已确认分发
- **THEN** `Icons.edit` 和 `Icons.undo`（error 色）图标按钮显示在字段列表尾部行、与"查看全部"并排
- **AND** 卡片底部不再渲染已确认按钮
- **AND** 被拒绝状态的"编辑后重新规则化"按钮不受影响
