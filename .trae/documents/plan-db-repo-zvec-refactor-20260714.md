# Locus 数据访问收口与 Zvec 向量架构重构计划

## Summary

- 目标：完成三阶段重构，彻底收拢 UI 层数据库访问边界，并以“SQLCipher 明文主库 + Zvec 脱敏向量索引”的双层架构接入本地语义能力。
- 范围：`Repository` 收口、`HubPayloads.uuid` 迁移、`EmbeddingService`/`VectorService`/`VectorDedupService`/`ProcessingPipeline` 联动、依赖注入注册、状态机统一、验证与生成代码。
- 核心原则：
  - UI / Presentation 层禁止直接依赖 `AppDatabase`。
  - Zvec 只保存 `[UUID, Embedding]`，不保存任何明文文本。
  - 向量生成与向量索引写入必须位于后台异步流，不阻塞 UI。
  - SQLite + SQLCipher 仍然是唯一明文事实源；RAG / 查重只允许先召回 UUID，再回主库取明文。

## Current State Analysis

### 已确认的仓库现状

- `lib/core/database/database.dart`
  - `HubPayloads` 已新增 `uuid` 列，`schemaVersion` 已提升到 `13`。
  - 已存在 `_backfillPayloadUuids()` 与 `idx_hub_payloads_uuid` 相关迁移逻辑。
  - 已增加 `getPayloadById()`、`getPayloadByUuid()`、`getPayloadsByUuids()`、`getPayloadUuid()`、`getPendingVectorPayloads()` 等辅助方法。
- `lib/core/di/service_locator.dart`
  - 已注册 `DashboardRepository`、`ChatRepository`、`MemoryRepository`。
  - 已接入 `EmbeddingService`、`VectorService`、`VectorDedupService`、新的 `ProcessingPipeline` 依赖图。
- `lib/core/services/processing_pipeline.dart`
  - 已改为依赖 `IdeaRepository`、`EmbeddingService`、`VectorService`。
  - 已实现网络恢复后重试 `failed_retry` / 向量待处理任务的基础流程。
- `lib/core/services/vector_service.dart`
  - 已按官方 `zvec` 风格写出 `Collection` / `Doc` / `VectorQuery` 方案。
  - 当前仍有两个待收敛点：每次写入后立即 `optimize()`，以及 `contains(uuid)` 后直接跳过，不支持内容更新后的重建索引。
- `lib/features/dashboard/data/dashboard_repository.dart`
  - 已封装 Dashboard 统计查询。
- `lib/features/chat/data/chat_repository.dart`
  - 已封装会话、消息、记忆、知识文件相关访问。
- `lib/features/memory/data/memory_repository.dart`
  - 已封装长期记忆与知识文件访问。
- `lib/features/idea_stream/data/idea_repository.dart`
  - 已扩展为主表、收件箱、状态流转、UUID 访问的统一入口。

### 已确认的隔离状态

- 在 `lib/features/**/*.dart` 范围内，`import '.../database.dart'` 仅剩数据仓库层文件，UI / Presentation 层未再直接导入 `database.dart`。
- `getIt<AppDatabase>()` 目前只出现在 `service_locator.dart` 和数据库自身，不再出现在已核查的 UI 页面里。

### 已确认的阻塞与风险

- `pubspec.yaml` 当前声明 `environment.sdk: ^3.6.2`，同时又声明 `zvec: ^0.5.2`。
- `zvec` 官方 SDK 需要更高的 Dart 版本；当前项目 manifest 与该依赖不一致，执行期若不先处理 SDK 约束，`pub get` 会失败。
- `lib/core/database/database.g.dart` 虽然存在，但在 `database.dart` 已改 schema 的前提下，大概率需要重新生成。
- `VectorService` 目前是“骨架可读、性能策略未收口”的状态，还未做完整编译验证。

## Assumptions & Decisions

- 主表主键策略：保留现有自增 `id` 作为关系型内部主键，同时新增稳定 `uuid` 作为向量索引主键。这是既定决策，不再回退为“直接用 int id”。
- Embedding 来源：使用云端 OpenAI-compatible `/embeddings` 接口，由 `EmbeddingService` 统一封装。这是既定决策。
- 向量库策略：必须使用官方 `zvec` SDK，不引入自定义替代向量库。
- SDK 版本策略：执行前先把项目 SDK 约束提升到满足 `zvec` 的范围，并使用满足该范围的 Flutter / Dart 工具链；如果本机工具链仍低于 `zvec` 要求，则执行期先升级工具链，再继续实现，不以非官方 path hack 或伪接口绕过。
- 明文边界：任何时候都不在 Zvec 中存储 `rawText`、标题、标签、文件内容或其它可逆明文字段。
- 更新策略：凡是会改变 `HubPayload.rawText` 语义内容的写操作，最终都必须触发“重置状态 -> 重新入队 -> 重建/刷新该 UUID 的向量索引”。
- 性能策略：不在每次单条写入后立即执行重型全量 `optimize()`；改为延迟/批量优化，避免高频输入时卡顿。

## Proposed Changes

### 阶段一：收拢数据库访问边界

#### 1. 校准并补齐 Repository 边界

- `lib/features/dashboard/data/dashboard_repository.dart`
  - 保持作为 Dashboard 聚合查询的唯一入口。
  - 执行期核对 `dashboard_page.dart` 使用到的所有统计方法是否都已覆盖，补齐缺失项。
- `lib/features/chat/data/chat_repository.dart`
  - 保持会话、消息、记忆读取、知识文件读取、RAG 上下文查询的统一入口。
  - 若 `chat_page.dart` 仍有任何数据库级方法调用或类型泄漏，继续上移到仓库。
- `lib/features/memory/data/memory_repository.dart`
  - 保持长期记忆与知识文件增删改查的统一入口。
  - 明确 `processFileForRag()` 只暴露业务语义，不让页面知道底层表结构。
- `lib/features/idea_stream/data/idea_repository.dart`
  - 继续承接主载荷、状态迁移、收件箱读取、UUID 查询与后续向量重试入口。
  - 增加“内容变更后重置向量状态”的显式仓库方法，避免页面自行拼状态值。

#### 2. 替换 UI 页面残余越权访问

- `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/features/chat/presentation/chat_page.dart`
- `lib/features/chat/presentation/chat_history_search_page.dart`
- `lib/features/memory/presentation/long_term_memory_page.dart`
- `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`
- `lib/features/idea_stream/presentation/pages/idea_stream_page.dart`
- 以及其它 presentation/widget 文件
  - 执行期统一做两类清理：
    - 删除 UI 层对 `database.dart` 的直接 import。
    - 删除 UI 层中任何 `getIt<AppDatabase>()`、`_db.xxx()`、表类型直接依赖。
  - 若 UI 需要数据库实体类型，优先从对应仓库文件 `export show ...` 暴露只读模型类型，而不是直接从 `database.dart` 引入。

#### 3. 依赖注入收口

- `lib/core/di/service_locator.dart`
  - 保持 Repository 单例注册。
  - 执行期确保服务构造顺序正确：`AppDatabase` -> repositories -> settings / AI -> connectivity -> embedding -> vector -> dedup -> router / dispatch / decay -> pipeline。
  - 若 `VectorService.init()` 在 app 启动阶段过重，则改为懒初始化或显式 warmup，不改变对外接口。

### 阶段二：引入 Zvec 本地脱敏向量索引

#### 1. 先解决依赖与工具链门槛

- `pubspec.yaml`
  - 将 `environment.sdk` 提升到满足 `zvec` 官方 SDK 的范围。
  - 保留 `zvec: ^0.5.2` 与 `uuid` 依赖。
- 执行前置条件
  - 使用满足上述约束的 Flutter / Dart 工具链。
  - 成功执行 `flutter pub get` 后再进行任何依赖 `package:zvec/zvec.dart` 的编译修正。

#### 2. 固化 UUID 迁移与主库访问能力

- `lib/core/database/database.dart`
  - 保持 `uuid` 作为唯一外部语义主键。
  - 执行期核实以下点：
    - 新建记录始终带 `uuid`。
    - 旧数据迁移会补齐 `uuid`。
    - `uuid` 唯一索引稳定存在。
    - 按 UUID 批量回查的 SQL 能覆盖向量召回后的主库读取需求。
- `lib/core/database/database.g.dart`
  - 执行期重新生成，使其与 schemaVersion 13 对齐。

#### 3. 抽象 Zvec 服务层

- `lib/core/services/vector_service.dart`
  - 保持 collection schema 只包含：
    - `id` / 主键：UUID 字符串
    - `embedding`：固定维度向量
  - 执行期重点修正：
    - 将“每次插入后立即 `optimize()`”改为批量或延迟优化机制。
    - 把当前“已存在就跳过”改为“支持按 UUID 刷新索引”的策略。
    - 若官方 API 提供 update / replace / delete，则直接采用；若没有，则采用“先删后写”或“重建 collection 中该文档”的最小确定性实现。
    - 保证任何异常都不会把明文写入 collection。
  - 保留对外接口语义：
    - `init()`
    - `upsertEmbedding(uuid, embedding)`
    - `queryNearest(embedding, topK, excludeUuid)`
    - `contains(uuid)`
    - 必要时新增 `refreshEmbedding()` / `removeByUuid()`，但接口名称以已安装 SDK 编译通过为准。

#### 4. 封装 Embedding 生成

- `lib/core/services/embedding_service.dart`
  - 继续统一封装 `/embeddings`。
  - 执行期补齐：
    - 维度校验失败的非重试错误。
    - 429 / 5xx / 超时 / 离线的重试语义。
    - 对空文本、空 API key、非法 baseUrl 的显式错误。

### 阶段三：联动异步状态机与安全召回

#### 1. 统一向量处理状态流

- `lib/core/enums/processing_status.dart`
  - 保持 snake_case 数据库存储值与旧 camelCase 兼容反序列化。
- `lib/core/services/processing_pipeline.dart`
  - 保持总体流转：
    - UI 写 SQLite，状态 `synced_local`
    - 入队后台处理
    - `vector_checking`
    - `ai_routing`
    - `dispatching`
    - `pending_review` / `dispatched`
    - 离线或超时落到 `failed_retry`
  - 执行期重点修正：
    - 对 `EmbeddingException.retryable` 做分流，非重试错误不要无限回队。
    - 保证队列幂等，避免同一 `payloadId` 高频重复入队。
    - 在内容更新场景支持重新排队和向量刷新。
    - 网络恢复时只静默补齐待向量化 / `failed_retry` 项，不影响已完成项。

#### 2. 向量查重与主库回查

- `lib/core/services/vector_dedup_service.dart`
  - 保持“Zvec 返回 UUID，SQLite 回查明文”的分层原则。
  - 执行期修正：
    - 相似度阈值集中管理，避免硬编码散落。
    - 若召回结果 UUID 在主库不存在，视为脏索引并跳过，不抛出致命错误。
    - 为未来 RAG 查询复用相同的 UUID -> SQLCipher 回查路径。

#### 3. 与分发、衰减、详情页联动

- `lib/core/services/dispatch_service.dart`
- `lib/core/services/decay_manager.dart`
- `lib/features/idea_stream/presentation/widgets/processing_status_indicator.dart`
- `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`
  - 执行期确认所有状态展示、手动重试、重新生成分发都只通过仓库和流水线入口完成。
  - `idea_detail_page.dart` 中用户触发重新生成时，继续沿用“重置为 `synced_local` -> `ProcessingPipeline.enqueue()`”路径。

## Execution Order

1. 调整 `pubspec.yaml` 的 SDK 约束，确保工具链满足 `zvec`。
2. 成功 `flutter pub get`。
3. 完成阶段一剩余清理，确认 UI 层零裸调数据库。
4. 校准 `database.dart` 中 `uuid` 迁移与查询辅助方法。
5. 重新生成 `database.g.dart`。
6. 基于真实安装的 `zvec` API 校准 `VectorService` 的可编译实现。
7. 收敛 `EmbeddingService`、`VectorDedupService`、`ProcessingPipeline` 的错误分流与重试逻辑。
8. 运行分析与验证，修复编译/诊断错误。

## Verification Steps

- 结构隔离验证
  - 搜索 `lib/features/**/*.dart`，确认 UI / Presentation 层不再出现 `import '.../database.dart'`。
  - 搜索 `lib/features/**/*.dart`，确认 UI / Presentation 层不再出现 `getIt<AppDatabase>()`。
- 依赖验证
  - `flutter pub get` 成功。
  - `package:zvec/zvec.dart` 可正常解析。
- 代码生成验证
  - 运行 Drift 生成命令，`database.g.dart` 与 `database.dart` 同步。
- 静态验证
  - `flutter analyze` 无新增错误。
  - 对已修改文件跑 diagnostics，确保无明显类型错误、未使用 import、签名不匹配。
- 行为验证
  - 新建一条闪念后，记录先写入 SQLite，初始状态为 `synced_local`。
  - 在线场景下，后台成功生成 embedding、写入 Zvec、进入 `vector_checking` / `ai_routing` / 后续分发状态。
  - 离线场景下，任务进入 `failed_retry`。
  - 网络恢复后，后台静默补跑并完成向量索引。
  - 向量查重时，只通过 Zvec 取回 UUID 列表，再通过 `IdeaRepository` 回查明文。
  - 任意调试输出或异常日志中都不包含明文写入 Zvec 的痕迹。

## Acceptance Criteria

- Repository 成为 UI 层访问数据库的唯一入口。
- `HubPayloads` 的 `uuid` 迁移、唯一索引、查询辅助方法全部可用。
- `zvec` 官方 SDK 成功接入，且只保存 `[UUID, Embedding]`。
- `ProcessingPipeline` 支持在线向量化、离线挂起、恢复重试、幂等排队。
- RAG / 查重链路严格遵守“向量召回 UUID -> SQLCipher 主库回查明文”的安全分层。
- 全项目在依赖、生成代码、分析阶段可通过，至少不引入新的结构性错误。
