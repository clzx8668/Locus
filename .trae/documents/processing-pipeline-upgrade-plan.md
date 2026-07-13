# 核心处理逻辑与数据库优化升级实施计划

> 基于 `docs/hexin.md` 开发指导文档，对 Locus 的核心处理管线与数据库进行升级。

---

## 1. 摘要

将当前的"直接写库 → 无后续处理"模式升级为 **"本地优先写入 + 异步四阶段流水线"** 架构。核心变化：

- `HubPayloads` 表引入 `processing_status` 状态机字段，驱动后台流水线
- 新建 3 张分发目标业务表（CRM客户 / 记账流水 / 待办日程）
- 实现 4 条异步处理流水线：向量查重 → AI路由抽取 → 结构化分发 → 废话衰减
- AI 路由支持双模态：云端 Function Calling + 本地正则降级
- UI 层增加处理状态指示器与双向链接导航

---

## 2. 当前状态分析

### 2.1 现有架构

| 层面 | 现状 | 文件 |
|------|------|------|
| 数据库 | 10 表，schema v10，`syncStatus` 字段预留但未使用 | `lib/core/database/database.dart` (709行) |
| 输入流 | QuickInputBottomSheet → 正则意图解析 → 直接写库 → 弹窗关闭 | `lib/features/home/presentation/widgets/quick_input_bottom_sheet.dart` (199行) |
| 意图路由 | 纯本地正则匹配，6种意图标签，无实体抽取 | `lib/core/utils/intent_router.dart` (34行) |
| AI 引擎 | 仅支持流式/非流式 Chat，无 Function Calling / Tool Use | `lib/core/services/ai_engine.dart` (202行) |
| 业务表 | 无 CRM、记账、待办独立表，所有数据仅存 hub_payloads | — |
| 网络监听 | 无 connectivity 监听 | — |

### 2.2 关键发现

- `HubPayloads.syncStatus` 字段（int, 默认 0）完全未被任何代码读取或修改
- `IntentRouter.parseTag()` 是纯正则匹配，不抽取实体（金额、时间、人名）
- `AiEngine` 使用 `http` 包，`jsonEncode` 手动构建请求体，无 structured output / tool_choice 支持
- `IdeaRepository` 封装了所有 HubPayload CRUD，但无状态更新方法
- 所有 UI 是 `StreamBuilder` 响应式监听，天然支持数据变化自动刷新

---

## 3. 方案设计

### 3.1 数据流全貌

```
用户输入（10ms 内完成）
    │
    ▼
┌──────────────────────────────────────────────────────┐
│ QuickInputBottomSheet._submitPayload()               │
│   → IntentRouter.parseTag(text)  // 本地快速意图    │
│   → 写入 hub_payloads (status=synced_local)          │
│   → 触发 ProcessingPipeline.enqueue(payloadId)       │
│   → Navigator.pop()  // UI 立即释放                  │
└──────────────────────────────────────────────────────┘
    │
    ▼ (异步后台，不阻塞 UI)
┌──────────────────────────────────────────────────────┐
│ ProcessingPipeline (后台顺序执行)                     │
│                                                      │
│  Step 1: VectorDedupService                          │
│    → status → vector_checking                        │
│    → 计算 embedding → 相似度对比                      │
│    → 相似度 > 85% → 生成合并提示通知                  │
│                                                      │
│  Step 2: AiRouterService                             │
│    → status → ai_routing                             │
│    → 网络在线 → 云端 Function Calling (抽取实体)      │
│    → 网络离线 → 本地正则/关键词降级                   │
│    → 产出具象实体 JSON + 确认大类标签                 │
│                                                      │
│  Step 3: DispatchService                             │
│    → status → dispatching                            │
│    → 根据大类写入对应业务表                            │
│    → 更新 hub_payloads.dispatchedRef                  │
│    → status → dispatched                             │
│                                                      │
│  Step 4: DecayManager                                │
│    → 标记为"废话"的内容 → 衰减时钟启动                │
│    → 48h 后自动折叠                                   │
└──────────────────────────────────────────────────────┘
```

### 3.2 状态机定义

```
synced_local  ──→  vector_checking  ──→  ai_routing  ──→  dispatching  ──→  dispatched
     │                    │                   │                │
     └──── failed_retry ←─┴───────────────────┴────────────────┘
              │
              └── (网络恢复后) → 从断点恢复继续
```

---

## 4. 详细实施步骤

### Step 1: 新增处理状态枚举

**新建文件**: `lib/core/enums/processing_status.dart`

```dart
enum ProcessingStatus {
  syncedLocal,    // 刚写入本地，等待处理
  vectorChecking, // 向量查重中
  aiRouting,      // AI 路由抽取中
  dispatching,    // 结构化分发中
  dispatched,     // 已完成分发
  failedRetry,    // 挂起等待重试
}
```

- 提供 `fromString` / `toDbValue` 序列化方法
- 在 `HubPayloads` 中以 TEXT 存储枚举名

### Step 2: 数据库 Schema 升级 (v10 → v11)

**修改文件**: `lib/core/database/database.dart`

#### 2.1 HubPayloads 表新增字段

| 新字段 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `processingStatus` | TEXT | `'synced_local'` | 处理状态枚举值 |
| `dispatchedRef` | TEXT? | null | 分发引用，格式 `"table_name:id"` |
| `aiEntities` | TEXT? | null | AI 抽取的实体 JSON |
| `isEphemeral` | BOOL | false | 是否标记为日常废话 |
| `decayDeadline` | DATETIME? | null | 废话衰减到期时间 |

> `syncStatus` 保留不动，向后兼容旧数据。

#### 2.2 新建 3 张业务表

**CRM 客户表** (`crm_customers`):

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | INT PK AUTO | 主键 |
| `sourcePayloadId` | INT FK → hub_payloads.id | 来源闪念 |
| `name` | TEXT | 客户名称 |
| `company` | TEXT? | 公司 |
| `contact` | TEXT? | 联系方式 |
| `tags` | TEXT | JSON 标签数组 |
| `notes` | TEXT? | 备注 |
| `createdAt` | DATETIME | 创建时间 |
| `updatedAt` | DATETIME | 更新时间 |

**记账流水表** (`ledger_entries`):

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | INT PK AUTO | 主键 |
| `sourcePayloadId` | INT FK → hub_payloads.id | 来源闪念 |
| `amount` | REAL | 金额 |
| `category` | TEXT | 分类（餐饮/交通/采购等） |
| `type` | TEXT | 类型（收入/支出） |
| `description` | TEXT? | 描述 |
| `occurredAt` | DATETIME? | 发生时间 |
| `createdAt` | DATETIME | 创建时间 |

**待办日程表** (`todo_schedules`):

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | INT PK AUTO | 主键 |
| `sourcePayloadId` | INT FK → hub_payloads.id | 来源闪念 |
| `title` | TEXT | 待办标题 |
| `dueDate` | DATETIME? | 截止时间 |
| `priority` | INT | 优先级（0-3） |
| `isDone` | BOOL | 是否完成 |
| `notes` | TEXT? | 备注 |
| `createdAt` | DATETIME | 创建时间 |

#### 2.3 迁移逻辑 (v10→v11)

```dart
if (from <= 10) {
  // HubPayloads 新增字段
  await customStatement(
    "ALTER TABLE hub_payloads ADD COLUMN processing_status TEXT NOT NULL DEFAULT 'synced_local'",
  );
  await customStatement(
    'ALTER TABLE hub_payloads ADD COLUMN dispatched_ref TEXT',
  );
  await customStatement(
    'ALTER TABLE hub_payloads ADD COLUMN ai_entities TEXT',
  );
  await customStatement(
    'ALTER TABLE hub_payloads ADD COLUMN is_ephemeral INTEGER NOT NULL DEFAULT 0',
  );
  await customStatement(
    'ALTER TABLE hub_payloads ADD COLUMN decay_deadline INTEGER',
  );
  // 新建业务表
  await m.createTable(crmCustomers);
  await m.createTable(ledgerEntries);
  await m.createTable(todoSchedules);
}
```

#### 2.4 更新 `@DriftDatabase(tables:)` 注解

新增 `CrmCustomers`, `LedgerEntries`, `TodoSchedules` 到 tables 列表。

### Step 3: 增强本地意图路由引擎

**修改文件**: `lib/core/utils/intent_router.dart`

在现有 `parseTag()` 基础上新增 `extractEntities()` 静态方法：

```dart
class ExtractedEntities {
  final String intentTag;
  final double? amount;
  final String? personName;
  final String? company;
  final DateTime? dueDate;
  final String? category;      // 记账分类
  final int? priority;          // 待办优先级
}
```

抽取逻辑：
- **金额**: 正则 `/(\d+\.?\d*)\s*(元|块|￥|¥|💰)/` 提取
- **人名**: 正则 `/客户[：:]\s*(\S+)|联系人[：:]\s*(\S+)|拜访\s*(\S+)/` 提取
- **时间**: 正则 `/(明天|后天|下周[一二三四五六日]|\d+月\d+日|\d+:\d+)/` 解析
- **记账分类**: 关键词匹配（打车→交通、吃饭→餐饮、采购→购物）
- **优先级**: `urgent|紧急|重要` → 3，`尽快|asap` → 2

### Step 4: 增强 AI 引擎（支持 Function Calling）

**修改文件**: `lib/core/services/ai_engine.dart`

新增方法 `functionCall()`:

```dart
Future<Map<String, dynamic>?> functionCall({
  required String systemPrompt,
  required String userMessage,
  required List<Map<String, dynamic>> tools,
})
```

- 使用 OpenAI 兼容的 `tool_choice: "auto"` + `tools` 参数
- 解析返回的 `tool_calls[0].function.arguments` JSON
- 30 秒超时，超时返回 null（触发降级）

Tool definitions 定义在 `AiRouterService` 中，包含：
- `extract_entities`: 抽取时间、金额、人名、公司
- `classify_intent`: 确认最终大类标签

### Step 5: 新建核心服务

#### 5.1 网络连通性监听服务

**新建文件**: `lib/core/services/connectivity_service.dart`

```dart
class ConnectivityService {
  Stream<bool> get on ConnectivityChange;  // true=在线, false=离线
  bool get isOnline;
}
```

- 使用 `dart:io` 的 `InternetAddress.lookup` 周期性检测
- 暴露 `onConnectivityChange` Stream 供 Pipeline 监听

#### 5.2 处理管线编排器

**新建文件**: `lib/core/services/processing_pipeline.dart`

核心类：`ProcessingPipeline`

```dart
class ProcessingPipeline {
  void enqueue(int payloadId);    // 将 payload 加入处理队列
  Stream<ProcessingEvent> get events;  // 暴露状态变更事件流
}
```

- 内部维护 FIFO 队列（`List<int>`）
- 顺序处理每个 payload 的四步流水线
- 每步执行前更新 `processingStatus`
- 任一步骤失败 → 标记 `failedRetry` → 监听 ConnectivityService 恢复后重试
- 使用 `Future.microtask` 确保不阻塞 UI

#### 5.3 向量查重服务

**新建文件**: `lib/core/services/vector_dedup_service.dart`

```dart
class VectorDedupService {
  Future<DedupResult> checkSimilarity(int payloadId);
}
```

**注意**: 由于本地 embedding 模型集成复杂（需 ONNX/TFLite runtime），首次实现采用**简化的关键词重叠度检测**作为替代方案：

- 提取 payload 文本的 2-gram 特征
- 与最近 50 条记录做 Jaccard 相似度对比
- 相似度 > 0.7（近似 85% 语义相似）→ 返回 `DedupResult.hasSimilar`
- 预留 `_computeEmbedding()` 接口，后续可替换为真实 embedding 模型

#### 5.4 AI 路由服务（双模态）

**新建文件**: `lib/core/services/ai_router_service.dart`

```dart
class AiRouterService {
  Future<RoutingResult> route(int payloadId);
}
```

路由决策逻辑：

```
1. 检查 ConnectivityService.isOnline
2. 在线 → 调用 AiEngine.functionCall() 进行云端抽取
3. 离线 / 超时 / API 报错 → 降级到 IntentRouter.extractEntities() 本地抽取
4. 返回统一的 RoutingResult { intentTag, entities }
```

#### 5.5 结构化分发服务

**新建文件**: `lib/core/services/dispatch_service.dart`

```dart
class DispatchService {
  Future<void> dispatch(int payloadId, RoutingResult result);
}
```

分发逻辑：

| intentTag | 目标表 | 写入字段 |
|-----------|--------|----------|
| `CRM` | `crm_customers` | name, company, contact, notes, sourcePayloadId |
| `LEDGER` | `ledger_entries` | amount, category, type, description, occurredAt, sourcePayloadId |
| `TODO` | `todo_schedules` | title, dueDate, priority, notes, sourcePayloadId |
| `NOTE` / 其他 | 仅 hub_payloads | 不额外分发，仅标记 dispatched |

分发完成后：
- 更新 `hub_payloads.dispatchedRef = "table_name:id"`
- 更新 `hub_payloads.processingStatus = 'dispatched'`

#### 5.6 废话衰减管理器

**新建文件**: `lib/core/services/decay_manager.dart`

```dart
class DecayManager {
  void markAsEphemeral(int payloadId);
  Stream<int> watchDecayingPayloads();  // 暴露需要衰减的 payload ID 列表
}
```

- AI 路由结果显示为"日常废话"或用户手动标记 → 设置 `isEphemeral = true`, `decayDeadline = now + 48h`
- 每 10 分钟检查一次到期项 → 自动标记为"已折叠"
- UI 层根据 `isEphemeral` + `decayDeadline` 计算透明度 alpha 值

### Step 6: 新增 Repository 层

#### 6.1 IdeaRepository 扩展

**修改文件**: `lib/features/idea_stream/data/idea_repository.dart`

新增方法：
- `updateProcessingStatus(int id, ProcessingStatus status)`
- `updateDispatchedRef(int id, String ref)`
- `updateAiEntities(int id, String entitiesJson)`
- `markAsEphemeral(int id)`
- `watchPayloadById(int id)` — 单个 payload 的实时监听

#### 6.2 新建业务表 Repository

- **新建**: `lib/features/idea_stream/data/crm_repository.dart` — CrmCustomers CRUD
- **新建**: `lib/features/idea_stream/data/ledger_repository.dart` — LedgerEntries CRUD  
- **新建**: `lib/features/idea_stream/data/todo_repository.dart` — TodoSchedules CRUD

每个 Repository 遵循现有模式：构造函数接收 `AppDatabase`，封装对应表的 CRUD。

### Step 7: 更新依赖注入

**修改文件**: `lib/core/di/service_locator.dart`

新增注册：

```dart
getIt.registerSingleton<ConnectivityService>(ConnectivityService());
getIt.registerSingleton<ProcessingPipeline>(ProcessingPipeline(
  getIt<AppDatabase>(),
  getIt<ConnectivityService>(),
));
getIt.registerSingleton<VectorDedupService>(VectorDedupService(getIt<AppDatabase>()));
getIt.registerSingleton<AiRouterService>(AiRouterService(
  getIt<AppDatabase>(),
  getIt<AiEngine>(),
  getIt<ConnectivityService>(),
));
getIt.registerSingleton<DispatchService>(DispatchService(getIt<AppDatabase>()));
getIt.registerSingleton<DecayManager>(DecayManager(getIt<AppDatabase>()));
getIt.registerSingleton<CrmRepository>(CrmRepository(getIt<AppDatabase>()));
getIt.registerSingleton<LedgerRepository>(LedgerRepository(getIt<AppDatabase>()));
getIt.registerSingleton<TodoRepository>(TodoRepository(getIt<AppDatabase>()));
```

### Step 8: UI 层改造

#### 8.1 快速输入弹窗改造

**修改文件**: `lib/features/home/presentation/widgets/quick_input_bottom_sheet.dart`

在 `_submitPayload()` 中，写入成功后增加：

```dart
final payloadId = await _repo.insert(entry);
// 触发后台处理管线
getIt<ProcessingPipeline>().enqueue(payloadId);
```

> 现有流程保持不变：写入 → 立即 pop，enqueue 是异步不阻塞的。

#### 8.2 闪念卡片状态指示器

**新建文件**: `lib/features/idea_stream/presentation/widgets/processing_status_indicator.dart`

一个微小组件，根据 `processingStatus` 显示：
- `syncedLocal` → 不显示
- `vectorChecking` / `aiRouting` / `dispatching` → 🔄 微小旋转图标
- `failedRetry` → ⏳ 等待图标
- `dispatched` → ✅ 完成图标

#### 8.3 卡片改造（叠加状态指示器）

**修改文件**: `lib/features/idea_stream/presentation/pages/idea_stream_page.dart`

在 `_buildSmartCard()` 的卡片右上角叠加 `ProcessingStatusIndicator` 组件。

#### 8.4 详情页改造

**修改文件**: `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`

- 顶部 AppBar 下方增加处理状态横幅（显示当前阶段文字 + 图标）
- `dispatchedRef` 非空时，显示双向链接跳转按钮（如："查看关联客户 →"）
- 用户可以手动触发"标记为废话"操作

#### 8.5 废话衰减视觉效果

在 `idea_stream_page.dart` 的卡片渲染中：

```dart
final alpha = _calculateDecayAlpha(payload);
// 透明度从 1.0 线性衰减到 0.3（24h半衰期）
return Opacity(opacity: alpha, child: card);
```

---

## 5. 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|----------|------|
| **新建** | `lib/core/enums/processing_status.dart` | 处理状态枚举 |
| **修改** | `lib/core/database/database.dart` | 新增字段 + 3 张业务表 + v11 迁移 + DAO 方法 |
| **修改** | `lib/core/database/database.g.dart` | Drift build_runner 自动生成 |
| **修改** | `lib/core/utils/intent_router.dart` | 新增实体抽取方法 |
| **新建** | `lib/core/services/connectivity_service.dart` | 网络连通性监听 |
| **修改** | `lib/core/services/ai_engine.dart` | 新增 Function Calling 支持 |
| **新建** | `lib/core/services/processing_pipeline.dart` | 处理管线编排器 |
| **新建** | `lib/core/services/vector_dedup_service.dart` | 查重服务（简化版） |
| **新建** | `lib/core/services/ai_router_service.dart` | 双模态 AI 路由 |
| **新建** | `lib/core/services/dispatch_service.dart` | 结构化分发服务 |
| **新建** | `lib/core/services/decay_manager.dart` | 废话衰减管理 |
| **修改** | `lib/core/di/service_locator.dart` | 注册 7 个新服务 + 3 个新 Repository |
| **修改** | `lib/features/idea_stream/data/idea_repository.dart` | 扩展状态/分发相关方法 |
| **新建** | `lib/features/idea_stream/data/crm_repository.dart` | CRM 数据仓库 |
| **新建** | `lib/features/idea_stream/data/ledger_repository.dart` | 记账数据仓库 |
| **新建** | `lib/features/idea_stream/data/todo_repository.dart` | 待办数据仓库 |
| **修改** | `lib/features/home/presentation/widgets/quick_input_bottom_sheet.dart` | 接入处理管线 |
| **新建** | `lib/features/idea_stream/presentation/widgets/processing_status_indicator.dart` | 状态指示器组件 |
| **修改** | `lib/features/idea_stream/presentation/pages/idea_stream_page.dart` | 卡片叠加状态图标 + 废话衰减透明度 |
| **修改** | `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` | 状态横幅 + 双向链接 + 手动标记 |

---

## 6. 假设与决策

1. **向量查重首版用关键词替代**: 本地 Embedding 模型集成（ONNX Runtime）复杂度太高，先用 2-gram + Jaccard 相似度实现可用版本，预留 `_computeEmbedding()` 接口后续替换
2. **Function Calling 使用 OpenAI 兼容格式**: 当前 AiEngine 已适配 DeepSeek API（兼容 OpenAI），tool_use 参数相同
3. **废弃字段保留**: `syncStatus` 不再使用但保留在表中，不删除以避免复杂迁移
4. **处理管线是单线程顺序的**: 使用简单的 FIFO 队列 + async/await，不引入 Isolate（复杂度与收益不成正比）。每个步骤都是异步 IO，不会卡 UI 线程
5. **废话衰减 48 小时半衰期**: 按 hexin.md 要求，透明度在 24h 时降为 0.65，48h 后完全折叠
6. **业务表字段为最小集**: CRM/记账/待办 表字段按 hexin.md 描述的最小必要集设计，后续可扩展

---

## 7. 验证步骤

1. **数据库迁移验证**: 在旧 schema v10 数据库上升级到 v11，确认所有 ALTER TABLE 和 CREATE TABLE 成功执行
2. **状态机流转验证**: 
   - 新增一条闪念 → `processingStatus = 'synced_local'`
   - 手动触发 pipeline → 依次经过 vector_checking → ai_routing → dispatching → dispatched
   - 断网状态 → 标记 failed_retry，恢复后自动继续
3. **AI 双模态验证**:
   - 联网状态 → Function Calling 返回结构化 JSON
   - 断开 Wi-Fi → 自动降级到本地正则抽取
4. **UI 状态指示器验证**: 卡片右上角显示对应的 🔄/⏳/✅ 图标
5. **分发验证**: CRM/LEDGER/TODO 表正确写入数据，`dispatchedRef` 正确记录双向链接
6. **废话衰减验证**: 标记为废话后透明度随时间降低，48h 后自动折叠
7. **代码生成验证**: 运行 `dart run build_runner build` 确保 `.g.dart` 文件正确生成

---

## 8. 实施顺序建议

按依赖关系排序，建议按以下步骤实施：

1. Step 1 + Step 2 → 枚举 + 数据库 schema 升级（无外部依赖）
2. Step 5.1 → 连通性服务（无外部依赖）
3. Step 3 + Step 4 → 路由增强 + AI Function Calling（依赖 Step 2）
4. Step 5.3 → 查重服务（依赖 Step 2）
5. Step 5.4 → AI 路由服务（依赖 Step 3/4/5.1）
6. Step 7 → DI 注册（依赖 Step 5 全部完成）
7. Step 6 → Repository 层（依赖 Step 2）
8. Step 5.5 + 5.6 → 分发 + 衰减（依赖 Step 5.4/6）
9. Step 5.2 → 管线编排器（依赖 Step 5.3/5.4/5.5/5.6）
10. Step 8 → UI 层改造（依赖 Step 5.2/6）
