# Locus 五大能力升级实施计划

> 基于 `docs/hexin.md` 设计哲学，对五大能力进行全面升级：全局标签体系、多模态附件、反悔回滚、离线隐私、聚合看板。

---

## 1. 摘要

本次升级围绕"知识组织 + 输入多样性 + 用户信任 + 数据主权 + 宏观洞察"五个维度展开。核心变化：

- **标签网络**：新增 `tags` 主表 + M2M 关联表，替代 JSON-in-column 存储，实现多维交叉分类
- **多模态附件**：补齐文件选取、视频预览、录音功能，统一所有编辑器的媒体处理
- **AI 收件箱**：DispatchService 引入待确认机制 + 分发后撤销按钮，双重保险
- **离线隐私**：Ollama 本地 LLM 对接、API Key 安全存储、脱敏开关、离线模式
- **聚合看板**：新增 Dashboard 页面，财务图表 + 待办统计 + 标签频率分析

---

## 2. 当前状态分析

| 能力 | 现状 | 关键文件 |
|------|------|----------|
| 标签系统 | 双轨制：`intentTag` 单值 TEXT + `ContentBlock.tags` JSON 数组，无主表，全表扫描去重 | `database.dart`, `idea_detail_page.dart` |
| 多模态附件 | 仅图片完整；视频声明了 blockType 但无录入/预览；录音 UI 全为空壳；文件选取 fallback 为拍照 | `content_block_editor.dart`, `full_block_editor.dart`, `quick_input_bottom_sheet.dart` |
| 反悔机制 | 不存在。Dismissible 仅有确认弹窗，删除即物理销毁；DispatchService 静默写入无确认 | `processing_pipeline.dart`, `dispatch_service.dart` |
| 离线隐私 | SQLCipher 密钥硬编码；Settings 隐私/AI 分组全为占位；无 Ollama 客户端；ping google.com | `database.dart`, `settings_page.dart`, `settings_service.dart`, `connectivity_service.dart` |
| 聚合看板 | 完全空白。无 chart 库；`getTagStats()` 是唯一统计查询（全量内存扫描）；CalendarPage 占位 | `calendar_page.dart`, `pubspec.yaml` |

---

## 3. 详细实施步骤

### Step 1: 全局标签体系 —— 核心数据层

#### 1.1 数据库 Schema 升级 (v11 → v12)

**修改文件**: `lib/core/database/database.dart`

##### 新建 `tags` 主表

```dart
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();             // 不含 # 前缀，如 "设计"
  TextColumn get color => text().withDefault(const Constant('#FF6B6B'))();  // 十六进制颜色
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

##### 新建 M2M 关联表

```dart
class HubPayloadTags extends Table {
  IntColumn get payloadId => integer().references(HubPayloads, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  // 复合唯一约束：同一 payload 不能重复关联同一 tag
}

class CrmCustomerTags extends Table {
  IntColumn get customerId => integer().references(CrmCustomers, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
}

class LedgerEntryTags extends Table {
  IntColumn get entryId => integer().references(LedgerEntries, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
}

class TodoScheduleTags extends Table {
  IntColumn get scheduleId => integer().references(TodoSchedules, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
}
```

##### ContentBlocks.tags 迁移

- 现有 `ContentBlocks.tags` JSON 列保留不动（向后兼容）
- 同时新增 `ContentBlockTags` 关联表：
```dart
class ContentBlockTags extends Table {
  IntColumn get blockId => integer().references(ContentBlocks, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
}
```
- v11→v12 迁移：扫描 `content_blocks.tags` JSON 列，为每个已有标签创建 `Tags` 记录 + `ContentBlockTags` 关联

##### HubPayloads 新增字段

| 新字段 | 类型 | 说明 |
|--------|------|------|
| `isDeleted` | BOOL, default false | 软删除标记（为撤销机制铺路） |

##### 新增 DAO 方法（AppDatabase）

- `watchAllTags()` — 全局标签列表
- `getTagsForPayload(int)` / `getTagsForCrm(int)` / etc. — 获取某实体的标签列表
- `addTagToPayload(int payloadId, int tagId)` / `removeTagFromPayload(...)` — 关联/解除关联
- `getPayloadsByTags(List<String> tagNames)` — 根据标签名称交叉查询 payload
- `getOrCreateTag(String name)` — 查找或创建标签
- `getPopularTags({int limit = 20})` — 最常用标签排行
- `searchByTags(String query)` — 标签模糊搜索

#### 1.2 标签 Repository 层

**新建**: `lib/features/idea_stream/data/tag_repository.dart`

```dart
class TagRepository {
  final AppDatabase _db;
  // CRUD + 关联操作 + 标签自动补全
}
```

#### 1.3 标签选择器 UI 组件

**新建**: `lib/features/idea_stream/presentation/widgets/tag_picker.dart`

- 搜索栏 + 已选标签 chips + 候选列表
- 颜色圆点指示器
- 支持多选 + 快速创建新标签
- 两种模式：`compact`（内联）和 `full`（BottomSheet）

#### 1.4 替换现有标签组件

**修改**: `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`
- `_TagDialog` → 替换为新的 `TagPicker` 组件
- `_buildBlockBottomLeft` 中的 tag chips → 从关联表读取而非 JSON 解析

#### 1.5 "虚拟文件夹"视图

**新增**: `lib/features/idea_stream/presentation/pages/tag_browser_page.dart`

- 以标签为维度的文件浏览器风格页面
- 顶部：标签列表（横向滚动 chips）+ 搜索
- 内容区：`StreamBuilder` 监听 `getPayloadsByTags(selectedTagNames)`
- 支持多标签 AND 组合（交集过滤）
- 每个条目显示：预览文本 + 所属 intentTag + 关联业务表引用（CRM/LEDGER/TODO 链接）

**新增导航入口**: 在 `idea_stream_page.dart` 的 Drawer "常用"区域添加"标签浏览"入口

#### 1.6 DI 注册

**修改**: `lib/core/di/service_locator.dart`
```dart
getIt.registerSingleton<TagRepository>(TagRepository(getIt<AppDatabase>()));
```

---

### Step 2: 多模态附件能力 → 补齐全媒体支持

#### 2.1 统一块类型常量

**新建**: `lib/core/enums/block_type.dart`

```dart
enum BlockType { text, image, voice, video, file }
```

提供 `fromExtension(String ext)` 工厂方法，集中管理文件扩展名 → blockType 映射。

#### 2.2 QuickInputBottomSheet → 补齐文件/多图

**修改**: `lib/features/home/presentation/widgets/quick_input_bottom_sheet.dart`

- **文件选取**：接入 `file_picker`，使用 `FilePicker.platform.pickFiles(allowMultiple: true)` 支持 PDF/Word/TXT 等文件
- **多图支持**：将 `_pickImage` 从单图改为 `pickMultiImage()`
- **预览列表**：可横向滚动的缩略图列表（图片显示缩略图，文件显示类型图标）
- **提交时**：每个媒体文件创建为独立的 ContentBlock（而非存在 payload mediaPaths 中）

#### 2.3 FullBlockEditor → 补齐文件/视频/录音

**修改**: `lib/features/idea_stream/presentation/widgets/full_block_editor.dart`

- 文件选取：接入 `file_picker`
- 视频选取：`ImagePicker.pickVideo()`
- 录音功能：引入 `record` 包
  - 长按录音按钮开始录制 → 显示波形动画 + 计时器
  - 松开停止 → 保存为 `.m4a` 文件
- 媒体预览条扩展：视频显示时长标记，音频显示播放按钮，文件显示扩展名标签

#### 2.4 ContentBlockEditor → 同步补齐

**修改**: `lib/features/idea_stream/presentation/widgets/content_block_editor.dart`

- 将 `_pickFiles()` 中的拍照占位替换为真正的 `file_picker` 调用
- `_toggleRecording()` → 接入 `record` 包实现真实录音
- 媒体预览支持视频缩略图 + 音频波形占位

#### 2.5 详情页媒体渲染增强

**修改**: `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`

在 `_buildContentBlock()` 中根据 `blockType` 渲染不同媒体：
- **video**: 视频缩略图 + 播放按钮 → 点击打开全屏播放器（`video_player` 包）
- **voice**: 音频波形 + 播放/暂停按钮（`audioplayers` 包）
- **file**: 文件图标 + 文件名 + 大小 → 点击用系统默认应用打开（`open_filex` 包）
- **image**: 保持现有 `Image.file()` + 点击全屏预览

#### 2.6 新增依赖

添加到 `pubspec.yaml`：
- `record: ^5.0.0` — 录音
- `audioplayers: ^6.0.0` — 音频播放
- `video_player: ^2.8.0` — 视频播放
- `open_filex: ^4.4.0` — 系统关联打开文件

#### 2.7 OCR 预留接口

**新建**: `lib/core/interfaces/ocr_service.dart`

```dart
abstract class OcrService {
  Future<String> extractText(String imagePath);
}

class NoOpOcrService implements OcrService {
  Future<String> extractText(String imagePath) async => '';
}
```

- 在 `ProcessingPipeline` 中预留 OCR 步骤（在查重之前）
- 后续接入 `google_mlkit_text_recognition` 时只需实现接口即可

---

### Step 3: AI 收件箱 + 撤销机制 → 双重保险

#### 3.1 收件箱数据表

**修改**: `lib/core/database/database.dart` (v11→v12 迁移中)

新建 `DispatchInbox` 表：

```dart
class DispatchInbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get payloadId => integer().references(HubPayloads, #id)();
  TextColumn get intentTag => text()();                        // 目标业务大类
  TextColumn get targetTable => text()();                      // 目标表名
  TextColumn get extractedData => text()();                    // AI 抽取的 JSON 快照
  TextColumn get status => text().withDefault(const Constant('pending'))();  // pending/confirmed/rejected
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
}
```

#### 3.2 DispatchService 改造

**修改**: `lib/core/services/dispatch_service.dart`

- 重构 `dispatch()` → 拆分为两步：
  1. `stageForReview(payloadId, result)` → 写入 `DispatchInbox` 表（状态 `pending`），更新 `payload.processingStatus = 'pending_review'`
  2. `executeDispatch(inboxId)` → 用户确认后，执行原有分发逻辑，更新 inbox 为 `confirmed`

- ProcessingPipeline 中：`aiRouting` 完成后不再直接调用 `dispatch()`，而是调用 `stageForReview()`

#### 3.3 AI 收件箱页面

**新建**: `lib/features/idea_stream/presentation/pages/inbox_review_page.dart`

- 列表展示所有 `status == 'pending'` 的收件箱条目
- 每个条目卡片显示：
  - 原始闪念文本预览
  - AI 抽取结果（金额/人名/标签/分类）以可编辑表单展示
  - 目标分发表（CRM / 记账 / 待办）
- 操作按钮：
  - **确认** → 执行分发 + 标记 `confirmed` + 显示 "已分发到 XX 表"
  - **修正** → 允许用户修改表单字段后再确认
  - **拒绝** → 标记 `rejected` + 将 payload 状态重置为 `dispatched`（视为人工归档）
- 支持批量操作（全选 → 一键确认）

#### 3.4 分发后撤销按钮

**修改**: `lib/features/idea_stream/presentation/pages/idea_detail_page.dart`

在 `_buildDispatchedLink()` 链接行右侧增加撤销按钮：

```dart
IconButton(
  icon: const Icon(Icons.undo, size: 16),
  onPressed: () => _undoDispatch(),
)
```

撤销逻辑：
1. 查找 `DispatchInbox` 中对应的确认记录
2. 软删除目标表记录（不物理删除，设 `isDeleted = true`）
3. 重置 `inbox.status → 'reverted'`
4. 清除 `hub_payloads.dispatchedRef`
5. 重置 `hub_payloads.processingStatus → 'synced_local'`（可重新处理）

#### 3.5 新增导航入口

- `inbox_review_page.dart` 入口：
  - 在 `idea_stream_page.dart` 的 AppBar 右侧添加铃铛图标（`Icons.inbox_rounded`）
  - 徽章数字显示 pending 条目数量
  - 在 Drawer "常用"区域添加"AI 收件箱"入口

---

### Step 4: 离线可用 + 数据私密 → 安全与自主权

#### 4.1 API Key 安全存储

**新增依赖**: `pubspec.yaml` 添加 `flutter_secure_storage: ^9.0.0`

**新建**: `lib/core/services/secure_storage_service.dart`

```dart
class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  
  Future<void> saveApiKey(String key) => _storage.write(key: 'api_key', value: key);
  Future<String?> getApiKey() => _storage.read(key: 'api_key');
  Future<void> saveBaseUrl(String url) => _storage.write(key: 'base_url', value: url);
  Future<String?> getBaseUrl() => _storage.read(key: 'base_url');
  Future<void> saveModelName(String name) => _storage.write(key: 'model', value: name);
  Future<String?> getModelName() => _storage.read(key: 'model');
  Future<void> saveOllamaEnabled(bool enabled) => _storage.write(key: 'ollama_enabled', value: enabled.toString());
  Future<bool> getOllamaEnabled() async => (await _storage.read(key: 'ollama_enabled')) == 'true';
}
```

**修改**: `lib/core/services/ai_engine.dart`
- 构造函数改为异步：优先从 `SecureStorageService` 读取 API Key，不存在则 fallback 到 `.env`
- 新增 `setOllamaMode()` 方法：切换 baseUrl 为 `http://localhost:11434/v1` + model 为 `llama3:8b` 等

#### 4.2 SQLCipher 密钥加固

**修改**: `lib/core/database/database.dart` 的 `_openConnection()`

```dart
final key = await _deriveDatabaseKey();  // 从 SecureStorage / Keychain 派生
rawDb.execute("PRAGMA key = '$key';");
```

`_deriveDatabaseKey()` 实现：
1. 尝试从 `FlutterSecureStorage` 读取已存储密钥
2. 不存在则生成随机密钥（`uuid`）+ 存入 SecureStorage

#### 4.3 设置 → AI 服务页面

**新建**: `lib/features/settings/presentation/pages/ai_settings_page.dart`

- **API 基础设置**：API Key 输入框（`obscureText: true`）、Base URL、Model Name
- **Ollama 本地模式**：开关 toggle
  - 开启时：Base URL 自动切换为 `http://localhost:11434/v1`，显示可用本地模型列表
  - 关闭时：恢复云端配置
- **数据脱敏**：开关 `anonymizeBeforeSending`
  - 开启时：AiEngine 发送前对数字串（疑似金额/手机号）做 `****` 替换
- **离线模式**：全局开关
  - 开启时：所有云端 AI 调用被阻断，仅使用 IntentRouter 本地正则
  - 关闭时：正常云端 + 自动降级

**修改**: `lib/features/settings/presentation/pages/settings_page.dart`
- "AI 服务"分组 `onTap` → `Navigator.push(AiSettingsPage)`

#### 4.4 SettingsService 扩展

**修改**: `lib/core/services/settings_service.dart`

新增持久化字段：

| Key | 类型 | 默认值 | 说明 |
|-----|------|--------|------|
| `ollama_enabled` | bool | false | 是否启用 Ollama |
| `ollama_base_url` | String | `http://localhost:11434/v1` | Ollama 地址 |
| `anonymize_data` | bool | false | 是否脱敏 |
| `offline_mode` | bool | false | 全局离线模式 |

#### 4.5 脱敏模块

**新建**: `lib/core/utils/data_anonymizer.dart`

```dart
class DataAnonymizer {
  static String anonymize(String text) {
    // 替换金额：¥5000 → ¥****
    // 替换手机号：13812345678 → 138****5678
    // 替换身份证号、银行卡号等
    return text
      .replaceAll(RegExp(r'(\d{3})\d{4}(\d{4})'), r'$1****$2')
      .replaceAll(RegExp(r'¥\s*\d+'), '¥****');
  }
}
```

**修改**: `lib/core/services/ai_engine.dart`
- 在 `chat()` 和 `functionCall()` 中，如果 SettingsService.anonymizeData == true，调用 `DataAnonymizer.anonymize(userMessage)` 后再发送

#### 4.6 ConnectivityService 增强

**修改**: `lib/core/services/connectivity_service.dart`

- 备用检测站点：`baidu.com`（fallback 当 google.com 不可达时）
- 暴露 `Stream<ConnectivityEvent>` 区分 `wentOnline` / `wentOffline`

---

### Step 5: 聚合报表与回顾视图 → Dashboard

#### 5.1 新增依赖

添加到 `pubspec.yaml`：
- `fl_chart: ^0.68.0` — 轻量级 Flutter 图表库

#### 5.2 数据库聚合查询

**修改**: `lib/core/database/database.dart`

新增聚合 DAO 方法：

```dart
// 记账统计
Future<Map<String, double>> getMonthlyExpense(int year, int month);  // 分类 → 金额
Future<double> getTotalIncome(int year, int month);
Future<double> getTotalExpense(int year, int month);
Future<List<LedgerEntry>> getRecentEntries({int limit = 20});

// 待办统计
Future<int> getPendingTodoCount();
Future<int> getCompletedTodoCount();
Future<double> getTodoCompletionRate();

// CRM 统计
Future<int> getNewCustomersThisWeek();
Future<int> getTotalCustomers();

// 笔记统计
Future<int> getTotalPayloads();
Future<Map<String, int>> getIntentDistribution();  // intentTag → 数量
Future<int> getPayloadsToday();
Future<int> getPayloadsThisWeek();

// 标签统计
Future<List<TagStat>> getTopTags({int limit = 10});  // SQL GROUP BY + COUNT
```

#### 5.3 Dashboard 页面

**新建**: `lib/features/dashboard/presentation/pages/dashboard_page.dart`

页面布局（响应式）：

**大屏（>960px）**：三列网格
- 左列：财务总览（饼图 + 趋势折线图）
- 中列：笔记活动（本周热力图 + 标签词云）
- 右列：待办进度（环形图）+ 客户动态

**中屏（600-960px）**：两列
**小屏（<600px）**：单列垂直滚动

**组件拆解**：

| 组件 | 功能 | 依赖查询 |
|------|------|----------|
| `_buildFinancialSummary` | 本月收支柱状图（分类堆叠） | `getMonthlyExpense()`, `getTotalIncome()` |
| `_buildExpensePieChart` | 支出分类饼图 | `getMonthlyExpense()` |
| `_buildTodoProgress` | 待办完成率环形图 | `getTodoCompletionRate()` |
| `_buildNoteActivity` | 本周笔记数量热力条 | `getPayloadsThisWeek()` |
| `_buildTagCloud` | 最常用标签频率词云 | `getTopTags()` |
| `_buildCrmSnapshot` | 本周新客户 + 总数卡片 | `getNewCustomersThisWeek()`, `getTotalCustomers()` |

#### 5.4 导航入口

**修改**: `lib/features/home/presentation/locus_home_page.dart`

- 新增第五个 tab：Dashboard（图标：`dashboard_rounded`）
- 替换当前的 CalendarPage 占位 → CalendarPage 保留但移到"更多"区域

**新建**: `lib/features/dashboard/presentation/pages/calendar_page.dart`（覆盖原有占位）
- 日历月视图（使用 `table_calendar` 包或自绘）
- 点击日期显示当日待办和笔记
- 来自 `TodoSchedules.dueDate` 和 `HubPayloads.createdAt`

`pubspec.yaml` 新增：`table_calendar: ^3.1.0`

---

## 4. 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|----------|------|
| **修改** | `lib/core/database/database.dart` | 新增 Tags 表 + 5 张 M2M 关联表 + DispatchInbox 表 + v12 迁移 + 聚合 DAO |
| **修改** | `lib/core/database/database.g.dart` | build_runner 自动生成 |
| **修改** | `lib/core/di/service_locator.dart` | 注册 TagRepository + 更新已有服务 |
| **新建** | `lib/core/enums/block_type.dart` | 统一块类型枚举 |
| **新建** | `lib/core/interfaces/ocr_service.dart` | OCR 服务抽象接口 |
| **新建** | `lib/core/services/secure_storage_service.dart` | API Key 安全存储 |
| **新建** | `lib/core/utils/data_anonymizer.dart` | 数据脱敏工具 |
| **修改** | `lib/core/services/ai_engine.dart` | 异步初始化 + Ollama 支持 + 脱敏集成 |
| **修改** | `lib/core/services/settings_service.dart` | 新增 AI/隐私配置字段 |
| **修改** | `lib/core/services/dispatch_service.dart` | 两阶段分发（stage + execute） |
| **修改** | `lib/core/services/processing_pipeline.dart` | 对接收件箱 + OCR 预留步骤 |
| **修改** | `lib/core/services/connectivity_service.dart` | 备用 DNS + 事件区分 |
| **修改** | `lib/core/database/database.dart` (v12) | 新增 isDeleted + 软删除兼容 |
| **新建** | `lib/features/idea_stream/data/tag_repository.dart` | 标签数据仓库 |
| **新建** | `lib/features/idea_stream/presentation/widgets/tag_picker.dart` | 标签选择器组件 |
| **新建** | `lib/features/idea_stream/presentation/pages/tag_browser_page.dart` | 标签浏览虚拟文件夹 |
| **新建** | `lib/features/idea_stream/presentation/pages/inbox_review_page.dart` | AI 收件箱审核页 |
| **修改** | `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` | 标签组件替换 + 撤销按钮 + 媒体渲染增强 |
| **修改** | `lib/features/idea_stream/presentation/pages/idea_stream_page.dart` | 收件箱入口 + 标签浏览入口 |
| **修改** | `lib/features/home/presentation/widgets/quick_input_bottom_sheet.dart` | 文件/多图/多模态支持 |
| **修改** | `lib/features/idea_stream/presentation/widgets/full_block_editor.dart` | 文件/视频/录音支持 |
| **修改** | `lib/features/idea_stream/presentation/widgets/content_block_editor.dart` | 文件/录音实现 |
| **修改** | `lib/features/home/presentation/locus_home_page.dart` | 新增 Dashboard tab + 导航重构 |
| **新建** | `lib/features/dashboard/presentation/pages/dashboard_page.dart` | 聚合看板主页 |
| **修改** | `lib/features/calendar/presentation/pages/calendar_page.dart` | 覆盖占位 → 真实日历视图 |
| **新建** | `lib/features/settings/presentation/pages/ai_settings_page.dart` | AI 服务设置页 |
| **修改** | `lib/features/settings/presentation/pages/settings_page.dart` | 激活 AI/数据分组 |
| **修改** | `pubspec.yaml` | 新增 8 个依赖 |

---

## 5. 假设与决策

1. **标签颜色存储格式**：十六进制字符串 `#FF6B6B`，UI 层解析为 `Color`
2. **M2M 关联不级联删除**：删除标签时不删除关联的 payload/业务表记录，仅解除关联
3. **ContentBlock.tags JSON 列保留**：向后兼容，新代码使用关联表，旧数据迁移一次
4. **录音格式**：使用 `record` 包默认格式（AAC/M4A），兼容 iOS/Android
5. **视频播放**：使用系统默认 `video_player`，不实现自定义播放器 UI
6. **Ollama 模型列表**：通过 `/api/tags` 接口动态获取，缓存 5 分钟
7. **Dashboard 每日自动刷新**：使用 `StreamBuilder` 绑定数据库流，数据变更即刷新
8. **Dashboard 非实时计算**：简单聚合使用 SQL，复杂统计（如趋势）使用内存计算

---

## 6. 验证步骤

1. **标签 M2M 迁移**：v11 数据库升级到 v12，检查旧 ContentBlocks.tags JSON 是否正确迁移到关联表
2. **多标签交叉查询**：创建 3 个 payload 分别标记 `#A` `#B` `#A+B`，通过标签过滤验证交集/并集
3. **多模态附件**：依次测试图片、视频、文件、录音的上传和预览
4. **AI 收件箱**：创建闪念 → 触发 pipeline → 确认 inbox_review_page 有 pending 条目 → 确认/修正/拒绝操作 → 检查分发状态
5. **分发后撤销**：在详情页点击撤销 → 检查目标表记录被软删除 + payload 状态重置
6. **Ollama 对接**：本地启动 Ollama → 设置页开启 → 发送消息验证响应
7. **脱敏验证**：开启脱敏 → 发送含金额/手机号的文本 → 检查日志确认脱敏生效
8. **离线模式**：开启离线模式 → 断网 → 输入文本 → 确认仅触发 IntentRouter 路由
9. **Dashboard 数据**：创建测试数据（记账 5 笔 + 待办 3 个 + CRM 2 个） → 检查各图表数据正确
10. **build_runner**：运行 `dart run build_runner build --delete-conflicting-outputs` 无错误

---

## 7. 实施顺序

按依赖关系排序：

1. **Step 4 基础** — 安全存储 + SettingsService 扩展（无依赖，其他步骤需要）
2. **Step 1 数据层** — Tags 表 + M2M + v12 迁移（无业务依赖）
3. **Step 1 UI** — TagPicker + TagBrowser + 替换旧组件（依赖 Step 1 数据层）
4. **Step 3 数据层** — DispatchInbox 表（依赖 Step 1 数据库升级）
5. **Step 3 逻辑** — DispatchService 两阶段改造 + Pipeline 调整（依赖 Step 3 数据层）
6. **Step 3 UI** — InboxReviewPage + 撤销按钮（依赖 Step 3 逻辑）
7. **Step 2** — 多模态附件（独立，可并行）
8. **Step 4 UI** — AiSettingsPage + SettingsPage 激活（依赖 Step 4 基础）
9. **Step 4 脱敏** — DataAnonymizer + AiEngine 集成（依赖 Step 4 基础）
10. **Step 5** — Dashboard + Calendar 重构（依赖 Step 1/3，但数据层已完备）
11. **全局导航** — LocusHomePage tab 重构（依赖 Step 5 Dashboard + Step 4 Settings）
12. **build_runner** → 最终验证
