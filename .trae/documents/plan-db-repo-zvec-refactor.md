# Locus 数据库收口与 Zvec 接入实施计划

## 摘要
- 目标一：收拢 UI 层对 `AppDatabase` 的越权访问，建立稳定的 Repository 边界，确保 Presentation 层不再 `import '.../database.dart'`。
- 目标二：在保留 `SQLite + SQLCipher + Drift` 主存储体系的前提下，引入本地 `zvec` 作为脱敏向量索引，仅保存 `[uuid, embedding]`。
- 目标三：把 Zvec 写入与语义查重纳入现有 `ProcessingPipeline` 异步流，保证 UI 先本地落库后立即释放，联网恢复后自动补齐向量索引。
- 关键决策：
  - `hub_payloads` 新增稳定 `uuid` 字段，继续保留现有 `int id` 作为内部主键与外键基石。
  - Embedding 来源采用云端 Embedding API，新建 `EmbeddingService`，通过当前 OpenAI 兼容配置体系接入。

## 当前状态分析

### 1. 数据层现状
- `lib/core/database/database.dart` 同时承载表定义、迁移、CRUD、统计查询、聊天检索、RAG 处理、收件箱查询，职责过重。
- `HubPayloads` 当前主键为 `int id`，不存在稳定 UUID 字段；`processingStatus` 默认值仍是 `'synced_local'`。
- `VectorStorage` 目前只是文件切片表，结构为 `sourceFileId + content`，不是向量数据库，也不是脱敏索引。

### 2. 仓库层现状
- 已有 `IdeaRepository`、`TemplateRepository`、`CrmRepository`、`LedgerRepository`、`TodoRepository`、`TagRepository`。
- 缺失 `DashboardRepository`、`ChatRepository`、`MemoryRepository`，导致部分 UI 直接访问数据库。
- `IdeaRepository` 已经承担部分流程状态读写，是后续收口的主要范式。

### 3. UI 越权点
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` 直接调用多个统计查询。
- `lib/features/chat/presentation/chat_page.dart` 直接调用聊天、记忆、RAG 相关数据库方法。
- `lib/features/chat/presentation/chat_history_search_page.dart` 直接调用会话流。
- `lib/features/memory/presentation/long_term_memory_page.dart` 直接调用记忆与知识文件 CRUD/RAG 处理。
- `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` 仍直接查询 `dispatchInbox` 并直接更新 `processingStatus`。
- 另外若干 UI 文件仍残留 `database.dart` 僵尸 import，例如 `idea_stream_page.dart`、`timeline_page.dart`、`quick_input_bottom_sheet.dart`、`ai_chat_input_box.dart`。

### 4. 流水线与状态机现状
- `lib/core/services/processing_pipeline.dart` 已具备“本地入库后异步处理”的骨架，但当前查重为 `VectorDedupService` 中的 2-gram + Jaccard 近似实现。
- `lib/core/services/vector_dedup_service.dart` 直接依赖 `AppDatabase`，且不产生真实 embedding 或外部向量索引。
- `lib/core/enums/processing_status.dart` 与数据库内字符串、`DispatchService`/`DecayManager` 的硬编码状态值不完全一致，存在状态漂移风险。

### 5. 外部接入前提
- 当前项目已有 `AiEngine`，使用 OpenAI 兼容 `chat/completions` 接口与可配置 `baseUrl/model/apiKey`。
- 项目尚无 Embedding API 封装，也无 Zvec 初始化、集合生命周期、后台向量查询服务。
- 只读调研确认当前官方 Flutter SDK 可用包为 `zvec`，可通过 `flutter pub add zvec` 接入，支持 Flutter 平台与 FFI 本地集合能力。

## 方案总览

### 阶段一：收拢数据库访问边界
- 通过新建 3 个 Repository，把现有 UI 越权查询和写入全部迁回数据层。
- 保持现有业务行为不变，第一阶段只做“收口”和“移除 UI 裸调”，不主动改动界面交互。
- 同时为 `idea_detail_page.dart` 补齐工作流仓库能力，避免它继续直查 `dispatchInbox`。

### 阶段二：引入脱敏 Zvec 索引
- 主数据仍在 `SQLite + SQLCipher`。
- Zvec 独立保存在应用沙盒目录，作为脱敏索引层，仅保存：
  - `id: string` -> `hub_payloads.uuid`
  - `embedding: vector<float32>` -> 文本向量
- 明文文本始终只存于 Drift/SQLCipher；Zvec 不存 `content`、`title`、`tags`、`metadata`。

### 阶段三：把 Zvec 融入后台流水线
- UI 写入 payload 后仍立刻返回，默认状态为 `synced_local`。
- `ProcessingPipeline` 在后台依次执行：
  - 获取 payload 文本与 UUID
  - 联网时调用 `EmbeddingService`
  - 向 `VectorService` 写入 `[uuid, embedding]`
  - 调用 `VectorDedupService` 基于 Zvec 做相似召回
  - 继续 AI 路由与业务分发
- 网络不可用或 Embedding 超时时，将状态置为 `failed_retry` 并等待 `ConnectivityService` 恢复后自动补偿。

## 拟修改文件与具体改动

### A. 数据库与迁移

#### `lib/core/database/database.dart`
- 为 `HubPayloads` 新增 `uuid` 字段：
  - 类型：`TextColumn`
  - 约束：`unique()`
  - 初始迁移：为已有历史数据补生成 UUID
- 提升 `schemaVersion`，新增从当前版本到下一版的迁移逻辑。
- 补充以下数据访问方法，供仓库与服务统一调用：
  - `Future<HubPayload?> getPayloadById(int id)`
  - `Future<HubPayload?> getPayloadByUuid(String uuid)`
  - `Future<List<HubPayload>> getPayloadsByUuids(List<String> uuids)`
  - `Future<String?> getPayloadUuid(int id)`
  - `Future<List<HubPayload>> getPendingVectorPayloads()` 或更精确的待补偿查询方法
- 为 `insertPayload` 提供自动写入 UUID 的能力，避免调用方手工生成。
- 统一/修复状态查询相关辅助方法，避免后续流水线继续散落直写字符串。

#### 为什么这样改
- 当前所有业务表外键都依赖 `int id`，直接把主键切到 UUID 成本极高。
- 增加稳定 UUID 可以兼顾：
  - SQLite 现有关系结构稳定
  - Zvec 使用字符串主键
  - 后续跨端同步或外部索引映射更清晰

### B. Repository 收口

#### 新建 `lib/features/dashboard/data/dashboard_repository.dart`
- 封装 `dashboard_page.dart` 当前使用的统计方法：
  - `getTotalIncome`
  - `getTotalExpense`
  - `getMonthlyExpense`
  - `getCompletedTodoCount`
  - `getPendingTodoCount`
  - `getPayloadsThisWeek`
  - `getPayloadsToday`
  - `getTopTagsWithCount`
  - `getNewCustomersThisWeek`
  - `getTotalCustomers`
  - 若页面还直接监听文件流，则补一个 `watchAllFiles`/统计包装接口
- 仅暴露页面所需读模型，不让页面触碰 `AppDatabase` 类型。

#### 新建 `lib/features/chat/data/chat_repository.dart`
- 封装：
  - `watchAllSessions`
  - `createSession`
  - `getMessagesForSession`
  - `insertMessage`
  - `getRelevantContext`
  - `getRelevantContextForFiles`
  - `watchAllFiles`
  - `getAllMemoryTexts`
  - `addMemory`
- 这是“聊天协调仓库”，允许聚合会话、知识库与长期记忆调用，先以最小改动消除 UI 越权。

#### 新建 `lib/features/memory/data/memory_repository.dart`
- 封装：
  - `watchAllMemories`
  - `addMemory`
  - `updateMemory`
  - `deleteMemory`
  - `watchAllFiles`
  - `addFile`
  - `processFileForRag`
  - `deleteFile`
  - `toggleFileActive`
- 让 `long_term_memory_page.dart` 从“直接 orchestration 数据库”切换到仓库调用。

#### 扩展 `lib/features/idea_stream/data/idea_repository.dart`
- 增加：
  - `Future<DispatchInboxData?> getDispatchInboxByPayloadId(int payloadId)` 或同等包装方法
  - `Future<void> resetToSyncedLocal(int payloadId)` / `retryDispatch(int payloadId)`
  - `Future<String?> getUuidById(int payloadId)`
  - `Future<List<HubPayload>> getByUuids(List<String> uuids)`
- 这样 `idea_detail_page.dart` 不再直接查 `dispatchInbox` 或直接写状态。

### C. 依赖注入

#### `lib/core/di/service_locator.dart`
- 注册：
  - `DashboardRepository`
  - `ChatRepository`
  - `MemoryRepository`
  - `EmbeddingService`
  - `VectorService`
- 调整核心服务依赖关系：
  - `VectorDedupService` 改为依赖 `IdeaRepository + VectorService`
  - `ProcessingPipeline` 依赖新增的 `EmbeddingService` / `VectorService`
- 保留 `AppDatabase` 单例，但限制它只在 Repository / Core Service 层出现。

### D. UI 页面收口

#### `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- 移除 `database.dart` import。
- 由 `getIt<DashboardRepository>()` 代替 `getIt<AppDatabase>()`。
- 所有 `_db.xxx()` 替换为 `_repo.xxx()`。

#### `lib/features/chat/presentation/chat_page.dart`
- 移除 `database.dart` import。
- 由 `getIt<ChatRepository>()` 统一提供聊天、记忆、RAG 调用。
- 保持现有 UI 流程和交互不变，只替换数据访问入口。

#### `lib/features/chat/presentation/chat_history_search_page.dart`
- 移除 `database.dart` import。
- 使用 `ChatRepository.watchAllSessions()`。

#### `lib/features/memory/presentation/long_term_memory_page.dart`
- 移除 `database.dart` import。
- 使用 `MemoryRepository` 替代页面内两个 `db` getter 入口。
- 保留文件复制、路径处理等页面级行为；数据库操作迁入仓库。

#### `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`
- 移除 `database.dart` import。
- 现有 `_db.select(_db.dispatchInbox)` 改为 `IdeaRepository` 包装方法。
- 现有 `_db.updateProcessingStatus(...)` 改为 `IdeaRepository.resetToSyncedLocal(...)` 或 `updateProcessingStatus(...)`。

#### 清理僵尸 import
- 检查并移除以下 UI 文件中的 `database.dart` import：
  - `lib/features/idea_stream/presentation/pages/idea_stream_page.dart`
  - `lib/features/timeline/presentation/timeline_page.dart`
  - `lib/features/home/presentation/widgets/quick_input_bottom_sheet.dart`
  - `lib/features/idea_stream/presentation/widgets/ai_chat_input_box.dart`
  - 以及检索到的其它 Presentation/UI 层残留项

### E. Zvec 与 Embedding 服务

#### `pubspec.yaml`
- 增加依赖：`zvec`
- 若实现需要 UUID 生成库，则增加 `uuid`
- 若 Embedding 请求采用 `Float32List` 与转换工具，可直接使用 `dart:typed_data`，不额外引入复杂依赖

#### 新建 `lib/core/services/embedding_service.dart`
- 职责：
  - 封装云端 Embedding API 调用
  - 基于当前 `AiEngine` 的配置风格读取 `apiKey/baseUrl/model`
  - 提供 `Future<Float32List> embed(String text)` 或等价接口
- 约束：
  - 只返回向量，不持久化原文
  - 超时、401、5xx、无网等错误明确分类，供流水线决定是否进入 `failed_retry`
- 推荐实现：
  - 通过 OpenAI 兼容 `POST /embeddings`
  - 默认模型名单独配置，例如 `TEXT_EMBEDDING_MODEL`
  - 默认维度先固定为 `1536`，并在服务内集中校验

#### 新建 `lib/core/services/vector_service.dart`
- 职责：
  - 初始化 `Zvec`
  - 在应用沙盒目录创建并打开 collection
  - 暴露：
    - `Future<void> init()`
    - `Future<void> upsertEmbedding({required String uuid, required Float32List embedding})`
    - `Future<void> deleteEmbedding(String uuid)`
    - `Future<List<String>> queryNearest(Float32List embedding, {int topK = 8, String? excludeUuid})`
    - `Future<bool> contains(String uuid)`
- Schema 固定为：
  - `id: string`
  - `embedding: vector(1536)`
- 不创建任何明文字段，不落标题、不落文本、不落标签。
- 由服务内部负责序列化、集合优化、资源释放；对上层隐藏 Zvec FFI 细节。

#### 路径与生命周期
- Zvec collection 文件放在应用文档目录独立子目录，例如：
  - `${appDocDir}/vector_index/hub_payload_vectors`
- `setupLocator()` 初始化期间完成 `VectorService.init()`。

### F. 查重与检索链路重构

#### `lib/core/services/vector_dedup_service.dart`
- 从“Jaccard 文本查重”重构为“Embedding + Zvec 召回 + SQLite 回查”：
  - 通过 `IdeaRepository.getUuidById(payloadId)` 获取当前 payload UUID
  - 通过 `EmbeddingService` 或由上游传入 embedding
  - 调用 `VectorService.queryNearest(...)`
  - 得到 UUID 列表后，再用 `IdeaRepository.getByUuids(...)` 回查 SQLCipher 主库中的明文内容
  - 计算最终 dedup 判断结果并返回 `DedupResult`
- 对短文本保留跳过策略，避免无意义 embedding 调用。
- 需要避免“先写入自己再查导致命中自己”，因此查询时排除当前 UUID。

#### 是否保留旧 Jaccard 兜底
- 执行时采用“可选降级”策略：
  - 若 Embedding 服务不可用且当前处于离线/超时场景，不做旧 Jaccard 本地兜底，而是直接进入 `failed_retry`
  - 这样更符合你要求的“依靠网络恢复后静默补齐向量索引”路径，减少双套判定逻辑混乱

### G. ProcessingPipeline 状态机改造

#### `lib/core/services/processing_pipeline.dart`
- 扩展依赖：
  - `IdeaRepository`
  - `EmbeddingService`
  - `VectorService`
  - `VectorDedupService`
- 调整单条处理流程：
  1. 将状态更新为 `vectorChecking`
  2. 读取 payload 文本和 UUID
  3. 若离线，直接置 `failedRetry` 并返回
  4. 调用 `EmbeddingService.embed(rawText)`
  5. 调用 `VectorService.upsertEmbedding(uuid, embedding)`
  6. 调用 `VectorDedupService.checkSimilarity(...)`
  7. 将状态更新为 `aiRouting`
  8. 继续现有 AI 路由与分发
- 重试逻辑：
  - 启动时与恢复联网时，查询所有需要补偿的 payload 并重新入队
  - 至少覆盖 `failed_retry`
  - 执行时视现有数据情况，可顺手纳入历史遗留的 `synced_local` 和中间异常态恢复
- 队列去重：
  - `enqueue(payloadId)` 改为防重复入队，避免同一 payload 被并发重复处理

### H. 状态值统一

#### `lib/core/enums/processing_status.dart`
- 扩展并统一枚举值，消除 camelCase / snake_case / 硬编码混用问题。
- 计划统一为数据库 snake_case 存储值，并允许 `fromString()` 兼容历史 camelCase 值。
- 建议补齐至少这些状态：
  - `syncedLocal -> synced_local`
  - `vectorChecking -> vector_checking`
  - `aiRouting -> ai_routing`
  - `dispatching`
  - `pendingReview -> pending_review`
  - `dispatched`
  - `failedRetry -> failed_retry`
  - `decayed`
- 同步修改：
  - `DispatchService`
  - `DecayManager`
  - `ProcessingPipeline`
  - `ProcessingStatusIndicator`
  - `idea_detail_page.dart`

#### 为什么要一起做
- 如果只接入 Zvec 而不统一状态，后续 UI 会继续把 `pending_review`、`decayed` 误判成默认状态，难以排查。

## 实施顺序

### 第 1 步：只做边界收口
- 新建 `DashboardRepository`、`ChatRepository`、`MemoryRepository`
- 扩展 `IdeaRepository`
- 修改 `service_locator.dart`
- 替换 5 个 UI 页面数据库调用
- 清理 UI 层 `database.dart` import

### 第 2 步：数据库迁移与 UUID 落地
- 修改 `HubPayloads`
- 新增 UUID 生成与历史数据回填迁移
- 更新所有新建 payload 的写入逻辑，确保 UUID 自动生成

### 第 3 步：引入 EmbeddingService 与 VectorService
- 修改 `pubspec.yaml`
- 新建并注册两个服务
- 初始化 Zvec collection
- 封装写入、查询、删除接口

### 第 4 步：重构查重与流水线
- 重写 `VectorDedupService`
- 改造 `ProcessingPipeline`
- 统一失败重试与联网恢复逻辑
- 统一 processing status 存储值与 UI 展示映射

### 第 5 步：联调语义召回
- 在查重与 RAG 场景中打通：
  - 向量召回 UUID
  - Repository 回查 SQLCipher 明文
- 保持 Zvec 永不接触明文内容

## 假设与决策
- 本次不把所有 `AppDatabase` 方法拆成分文件 DAO；优先完成“边界收口 + 向量接入”，避免范围膨胀。
- 本次不把所有业务表主键迁移为 UUID；只给 `hub_payloads` 增加稳定 `uuid`。
- Embedding 采用云端 API，不在本轮引入端侧 ONNX/TFLite 推理。
- 维度先固定为 `1536`；若实际配置模型不同，后续可把维度抽到配置层，但首轮实现以单一维度确保简单稳定。
- `VectorStorage` 现有文档切片表先保留，不与 Zvec 物理合并；它继续承载文件切片明文，Zvec 专职做脱敏向量索引。
- 若 `chat_page.dart` 当前直接依赖知识库文件流与长期记忆，允许 `ChatRepository` 作为跨域聚合仓库存在，后续再细化拆分。

## 验证步骤

### 代码验证
- 运行 Dart/Flutter 分析，确认新仓库与服务无类型错误。
- 对本次改动文件运行诊断，确保没有新增 linter 错误。
- 确认所有 Presentation/UI 层文件中不再出现 `import '.../database.dart'`。

### 行为验证
- Dashboard 页面正常显示统计数据。
- Chat 页面可正常：
  - 创建会话
  - 发送消息
  - 写入历史消息
  - 读取长期记忆与知识文件上下文
- Long-term memory 页面可正常：
  - 新增/编辑/删除记忆
  - 挂载/删除/启停知识文件
- Idea detail 页面可正常查看收件箱状态并重新触发处理。

### 数据验证
- 新插入 `hub_payloads` 记录自动拥有唯一 `uuid`。
- 旧数据迁移后 `uuid` 全量补齐且唯一。
- Zvec collection 中仅有 `id + embedding`，无任何明文字段。

### 流程验证
- 正常联网时：
  - payload 插入后状态流转为 `synced_local -> vector_checking -> ai_routing -> dispatching/pending_review/dispatched`
  - Zvec 成功写入当前 UUID 的 embedding
- 断网或 Embedding 超时时：
  - payload 状态转为 `failed_retry`
  - 网络恢复后 `ProcessingPipeline` 自动重试并补齐 Zvec
- 查重时：
  - `VectorService` 先返回相似 UUID 列表
  - `IdeaRepository` 再从 SQLCipher 查询对应明文

### 回归检查
- 已有 `DispatchService`、`DecayManager`、`ProcessingStatusIndicator` 在统一状态值后表现一致。
- 现有 PDF RAG 流程不被本次 Zvec 接入破坏；其后续可再决定是否也迁入真正向量召回。
