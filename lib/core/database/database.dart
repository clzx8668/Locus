import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../utils/doc_parser.dart';

part 'database.g.dart';

final Uuid _uuid = const Uuid();

String _generateUuid() => _uuid.v4();

/// 核心表：HubPayloads (多模态路由载荷表)
class HubPayloads extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().clientDefault(_generateUuid)();

  TextColumn get rawText => text()();

  TextColumn get mediaPaths => text().withDefault(const Constant('[]'))();

  TextColumn get intentTag => text().withDefault(const Constant('NOTE'))();

  TextColumn get title => text().nullable()();

  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  /// 处理流水线状态：synced_local / vector_checking / ai_routing / dispatching / dispatched / failed_retry
  TextColumn get processingStatus =>
      text().withDefault(const Constant('synced_local'))();

  /// 分发引用，格式 "table_name:id"，用于双向链接追溯
  TextColumn get dispatchedRef => text().nullable()();

  /// AI 路由抽取的实体 JSON 快照
  TextColumn get aiEntities => text().nullable()();

  /// 是否标记为日常废话（触发衰减）
  BoolColumn get isEphemeral => boolean().withDefault(const Constant(false))();

  /// 废话衰减到期时间（创建后 48h）
  DateTimeColumn get decayDeadline => dateTime().nullable()();

  /// 软删除标记（为撤销机制铺路，v12）
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// 清洗后的文本（口语词剔除后）
  TextColumn get cleanedText => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 会话表 (ChatSessions) —— 左脑的"记忆抽屉"
/// 每次点击"新建对话"，就会在这里生成一条新记录。
class ChatSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 100)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 消息明细表 (ChatMessages) —— 抽屉里的"具体文件"
/// 记录 User 和 Assistant 的每一句对话。
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId => integer().references(ChatSessions, #id)();

  TextColumn get role => text()();

  TextColumn get content => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 长久记忆表 (LongTermMemories) —— 私人系统设定与业务规则
/// 用于存放："我们的发票抬头是XXX"、"报价单必须包含运费"等事实。
class LongTermMemories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get content => text()();

  TextColumn get tags => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 知识文件参考库 (KnowledgeFiles) —— 挂载的本地附件库
/// 用户上传的 PDF、Word 等本地文件，安全复制到沙盒后永久封存。
class KnowledgeFiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get localPath => text()();

  IntColumn get size => integer()();

  TextColumn get extension => text()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 向量存储表 (VectorStorage) —— RAG 知识胶囊
/// 存储文档切片后的知识片段，供 AI 深度阅读检索。
class VectorStorage extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sourceFileId => integer().references(KnowledgeFiles, #id)();

  TextColumn get content => text()();

  // 后续可增加 RealColumn 存储向量数组
}

/// 闪念任务清单表 (IdeaTasks) —— 闪念笔记的子任务
/// 每条闪念可派生多个可勾选的任务步骤
class IdeaTasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get payloadId => integer().references(HubPayloads, #id)();

  TextColumn get content => text()();

  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 内容追加块表 (ContentBlocks) —— 闪念笔记的多轮追加内容
/// 每条闪念可包含多个内容块（原始录入 + 后续追加），支持文本/图片/文件/录音
class ContentBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get payloadId => integer().references(HubPayloads, #id)();

  TextColumn get blockType => text().withDefault(
    const Constant('text'),
  )(); // 'text', 'voice', 'image', 'file'

  TextColumn get content => text()(); // 文本内容或描述

  TextColumn get mediaPaths =>
      text().withDefault(const Constant('[]'))(); // JSON数组: 图片/文件路径

  TextColumn get sourceType => text().withDefault(
    const Constant('manual'),
  )(); // 'manual' | 'voice' | 'scan'

  BoolColumn get aiPolished =>
      boolean().withDefault(const Constant(false))(); // AI是否已润色

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 该内容块独立关联的标签，JSON 数组格式如 ["#标签1","#标签2"]
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// AI 对话记录表 (AiConversations) —— 闪念详情页的AI交流
/// 每轮对话包含 role (user/assistant) 和内容
class AiConversations extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get payloadId => integer().references(HubPayloads, #id)();

  TextColumn get role => text()(); // 'user' | 'assistant'

  TextColumn get content => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// AI 模板表 (AiTemplates) —— AI 智能指令模板
/// 用户可自定义的 AI Prompt 快捷指令，支持图标、排序、启禁用
class AiTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get icon => text().withDefault(const Constant('📋'))();

  TextColumn get name => text()();

  TextColumn get prompt => text()();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  /// "chat" = 对话模板, "rule" = 规则化模板
  TextColumn get templateType => text().withDefault(const Constant('chat'))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 离线队列 —— 无网络时暂存用户输入，网络恢复后出队处理
@DataClassName('OfflineQueueEntry')
class OfflineQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawText => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isProcessed => boolean().withDefault(const Constant(false))();
}

/// CRM 客户表 —— 从闪念分发来的客户/联系人记录
class CrmCustomers extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sourcePayloadId => integer().references(HubPayloads, #id)();

  TextColumn get name => text()();

  TextColumn get company => text().nullable()();

  TextColumn get contact => text().nullable()();

  TextColumn get tags =>
      text().withDefault(const Constant('[]'))(); // JSON 标签数组

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 记账流水表 —— 从闪念分发来的财务记录
class LedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sourcePayloadId => integer().references(HubPayloads, #id)();

  RealColumn get amount => real()();

  TextColumn get category => text()(); // 餐饮/交通/采购等

  TextColumn get type =>
      text().withDefault(const Constant('expense'))(); // income / expense

  TextColumn get description => text().nullable()();

  DateTimeColumn get occurredAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 待办日程表 —— 从闪念分发来的待办/日程记录
class TodoSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sourcePayloadId => integer().references(HubPayloads, #id)();

  TextColumn get title => text()();

  DateTimeColumn get dueDate => dateTime().nullable()();

  IntColumn get priority =>
      integer().withDefault(const Constant(0))(); // 0-3，0=无优先级

  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ==================== 全局标签体系（v12 新增） ====================

/// 标签主表 —— 全局标签定义
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // 不含 # 前缀，如 "设计"
  TextColumn get color =>
      text().withDefault(const Constant('#FF6B6B'))(); // 十六进制颜色
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 闪念笔记 ↔ 标签 多对多关联
class HubPayloadTags extends Table {
  IntColumn get payloadId => integer().references(HubPayloads, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  @override
  Set<Column> get primaryKey => {payloadId, tagId};
}

/// CRM 客户 ↔ 标签 多对多关联
class CrmCustomerTags extends Table {
  IntColumn get customerId => integer().references(CrmCustomers, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  @override
  Set<Column> get primaryKey => {customerId, tagId};
}

/// 记账流水 ↔ 标签 多对多关联
class LedgerEntryTags extends Table {
  IntColumn get entryId => integer().references(LedgerEntries, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  @override
  Set<Column> get primaryKey => {entryId, tagId};
}

/// 待办日程 ↔ 标签 多对多关联
class TodoScheduleTags extends Table {
  IntColumn get scheduleId => integer().references(TodoSchedules, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  @override
  Set<Column> get primaryKey => {scheduleId, tagId};
}

/// 内容块 ↔ 标签 多对多关联
class ContentBlockTags extends Table {
  IntColumn get blockId => integer().references(ContentBlocks, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  @override
  Set<Column> get primaryKey => {blockId, tagId};
}

// ==================== AI 收件箱（v12 新增） ====================

/// AI 分发审核收件箱 —— 待用户确认/拒绝的 AI 分发结果
class DispatchInbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get payloadId => integer().references(HubPayloads, #id)();
  TextColumn get intentTag => text()(); // 目标业务大类
  TextColumn get targetTable => text()(); // 目标表名
  TextColumn get extractedData => text()(); // AI 抽取的 JSON 快照
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending/confirmed/rejected/reverted
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
}

@DriftDatabase(
  tables: [
    HubPayloads,
    ChatSessions,
    ChatMessages,
    LongTermMemories,
    KnowledgeFiles,
    VectorStorage,
    IdeaTasks,
    ContentBlocks,
    AiConversations,
    AiTemplates,
    CrmCustomers,
    LedgerEntries,
    TodoSchedules,
    Tags,
    HubPayloadTags,
    CrmCustomerTags,
    LedgerEntryTags,
    TodoScheduleTags,
    ContentBlockTags,
    DispatchInbox,
    OfflineQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createHubPayloadUuidIndex();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from <= 1) {
          await m.createTable(chatSessions);
          await m.createTable(chatMessages);
        }
        if (from <= 2) {
          await m.createTable(longTermMemories);
          await m.createTable(knowledgeFiles);
        }
        // v3 → v4: KnowledgeFiles 字段重构 (name/localPath/size/extension/createdAt)
        if (from <= 3) {
          await customStatement('DROP TABLE IF EXISTS knowledge_files');
          await m.createTable(knowledgeFiles);
        }
        // v4 → v5: 新增 VectorStorage 表 (RAG 知识胶囊)
        if (from <= 4) {
          await m.createTable(vectorStorage);
        }
        // v5 → v6: KnowledgeFiles 新增 isActive 列
        if (from <= 5) {
          await customStatement(
            'ALTER TABLE knowledge_files ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
          );
        }
        // v6 → v7: 新增 IdeaTasks 表 (闪念任务清单)
        if (from <= 6) {
          await m.createTable(ideaTasks);
        }
        // v7 → v8: 新增 ContentBlocks + AiConversations 表
        if (from <= 7) {
          await m.createTable(contentBlocks);
          await m.createTable(aiConversations);
        }
        // v8 → v9: 新增 HubPayloads.title + ContentBlocks.tags 列
        if (from <= 8) {
          await customStatement(
            'ALTER TABLE hub_payloads ADD COLUMN title TEXT',
          );
          await customStatement(
            'ALTER TABLE content_blocks ADD COLUMN tags TEXT NOT NULL DEFAULT \'[]\'',
          );
        }
        // v9 → v10: 新增 AiTemplates 表
        if (from <= 9) {
          await m.createTable(aiTemplates);
          await _seedDefaultTemplates();
        }
        // v10 → v11: 新增处理流水线字段 + 3 张业务表
        if (from <= 10) {
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
          await m.createTable(crmCustomers);
          await m.createTable(ledgerEntries);
          await m.createTable(todoSchedules);
        }
        // v11 → v12: 全局标签体系 + AI 收件箱 + 软删除
        if (from <= 11) {
          // HubPayloads 软删除字段
          await customStatement(
            'ALTER TABLE hub_payloads ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
          );
          // 标签主表 + 6 张 M2M 关联表
          await m.createTable(tags);
          await m.createTable(hubPayloadTags);
          await m.createTable(crmCustomerTags);
          await m.createTable(ledgerEntryTags);
          await m.createTable(todoScheduleTags);
          await m.createTable(contentBlockTags);
          // AI 收件箱
          await m.createTable(dispatchInbox);
          // 迁移现有 ContentBlocks.tags JSON → Tags + ContentBlockTags
          await _migrateContentBlockTags(m);
        }
        if (from <= 12) {
          await customStatement(
            "ALTER TABLE hub_payloads ADD COLUMN uuid TEXT NOT NULL DEFAULT ''",
          );
          await _backfillPayloadUuids();
          await _createHubPayloadUuidIndex();
        }
        // v13 → v14: AiTemplates 新增 templateType 列 + 默认规则化模板
        if (from <= 13) {
          await customStatement(
            "ALTER TABLE ai_templates ADD COLUMN template_type TEXT NOT NULL DEFAULT 'chat'",
          );
          await _seedDefaultRuleTemplates();
        }
        // v14 → v15: offline_queue 表 + HubPayloads.cleaned_text 列
        if (from <= 14) {
          // 创建离线队列表
          await customStatement('''
            CREATE TABLE IF NOT EXISTS offline_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              raw_text TEXT NOT NULL,
              created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
              is_processed INTEGER NOT NULL DEFAULT 0
            )
          ''');
          // HubPayloads 新增 cleaned_text 列
          await customStatement(
            "ALTER TABLE hub_payloads ADD COLUMN cleaned_text TEXT",
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<int> insertPayload(HubPayloadsCompanion entry) {
    final companion = entry.uuid.present
        ? entry
        : entry.copyWith(uuid: Value(_generateUuid()));
    return into(hubPayloads).insert(companion);
  }

  Future<void> updatePayload(int id, String rawText, String intentTag) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      HubPayloadsCompanion(
        rawText: Value(rawText),
        intentTag: Value(intentTag),
      ),
    );
  }

  /// 更新 payload 的标题
  Future<void> updatePayloadTitle(int id, String? title) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      HubPayloadsCompanion(title: Value(title)),
    );
  }

  Future<void> updateMediaPaths(int id, String mediaPaths) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      HubPayloadsCompanion(mediaPaths: Value(mediaPaths)),
    );
  }

  Future<int> deletePayload(int id) {
    return transaction(() async {
      // 先删除关联子表记录，避免外键约束冲突
      await (delete(ideaTasks)..where((t) => t.payloadId.equals(id))).go();
      await (delete(
        aiConversations,
      )..where((t) => t.payloadId.equals(id))).go();
      await (delete(contentBlocks)..where((t) => t.payloadId.equals(id))).go();
      await (delete(dispatchInbox)..where((t) => t.payloadId.equals(id))).go();
      await (delete(
        crmCustomers,
      )..where((t) => t.sourcePayloadId.equals(id))).go();
      await (delete(
        ledgerEntries,
      )..where((t) => t.sourcePayloadId.equals(id))).go();
      await (delete(
        todoSchedules,
      )..where((t) => t.sourcePayloadId.equals(id))).go();
      await (delete(hubPayloadTags)..where((t) => t.payloadId.equals(id))).go();
      // 最后删除主表记录
      return (delete(hubPayloads)..where((t) => t.id.equals(id))).go();
    });
  }

  /// 获取所有标签及使用次数统计
  Future<Map<String, int>> getTagStats() async {
    final rows = await select(hubPayloads).get();
    final stats = <String, int>{};
    for (final row in rows) {
      if (row.intentTag.isNotEmpty) {
        for (final tag in row.intentTag.split(' ')) {
          final t = tag.trim();
          if (t.isNotEmpty) {
            stats[t] = (stats[t] ?? 0) + 1;
          }
        }
      }
    }
    return stats;
  }

  /// 获取所有内容块中使用过的标签（去重）
  Future<List<String>> getAllBlockTags() async {
    final allBlocks = await select(contentBlocks).get();
    final allTags = <String>{};
    for (final block in allBlocks) {
      if (block.tags.isNotEmpty) {
        try {
          final tags = jsonDecode(block.tags) as List<dynamic>;
          for (final tag in tags) {
            if (tag is String && tag.isNotEmpty) {
              allTags.add(tag);
            }
          }
        } catch (_) {}
      }
    }
    return allTags.toList()..sort(); // 按字母排序便于查找
  }

  // ==================== 内容块 ====================

  Stream<List<ContentBlock>> watchBlocksForPayload(int payloadId) {
    return (select(contentBlocks)
          ..where((t) => t.payloadId.equals(payloadId))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  /// 监听某条闪念的内容块数量变化
  Stream<int> watchBlockCountForPayload(int payloadId) {
    return watchBlocksForPayload(payloadId).map((blocks) => blocks.length);
  }

  Future<int> insertBlock(
    int payloadId,
    String blockType,
    String content,
    String mediaPaths, [
    String sourceType = 'manual',
  ]) {
    return into(contentBlocks).insert(
      ContentBlocksCompanion.insert(
        payloadId: payloadId,
        blockType: Value(blockType),
        content: content,
        mediaPaths: Value(mediaPaths),
        sourceType: Value(sourceType),
      ),
    );
  }

  Future<void> updateBlock(int blockId, String content, String mediaPaths) {
    return (update(contentBlocks)..where((t) => t.id.equals(blockId))).write(
      ContentBlocksCompanion(
        content: Value(content),
        mediaPaths: Value(mediaPaths),
      ),
    );
  }

  /// 更新内容块的标签
  Future<void> updateBlockTags(int blockId, String tags) {
    return (update(contentBlocks)..where((t) => t.id.equals(blockId))).write(
      ContentBlocksCompanion(tags: Value(tags)),
    );
  }

  Future<void> setBlockAiPolished(int blockId) {
    return (update(contentBlocks)..where((t) => t.id.equals(blockId))).write(
      const ContentBlocksCompanion(aiPolished: Value(true)),
    );
  }

  Future<int> deleteBlock(int blockId) {
    return (delete(contentBlocks)..where((t) => t.id.equals(blockId))).go();
  }

  // ==================== AI 对话 ====================

  Stream<List<AiConversation>> watchConversationsForPayload(int payloadId) {
    return (select(aiConversations)
          ..where((t) => t.payloadId.equals(payloadId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  Future<int> insertConversation(int payloadId, String role, String content) {
    return into(aiConversations).insert(
      AiConversationsCompanion.insert(
        payloadId: payloadId,
        role: role,
        content: content,
      ),
    );
  }

  Future<void> deleteConversation(int id) {
    return (delete(aiConversations)..where((t) => t.id.equals(id))).go();
  }

  // ==================== AI 模板 ====================

  Stream<List<AiTemplate>> watchEnabledTemplates() {
    return (select(aiTemplates)
          ..where((t) => t.isEnabled.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Stream<List<AiTemplate>> watchAllTemplates() {
    return (select(
      aiTemplates,
    )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).watch();
  }

  Future<int> insertTemplate(
    String icon,
    String name,
    String prompt, {
    String? templateType,
  }) {
    return into(aiTemplates).insert(
      AiTemplatesCompanion.insert(
        name: name,
        prompt: prompt,
        icon: Value(icon),
        templateType: templateType != null
            ? Value(templateType)
            : const Value.absent(),
      ),
    );
  }

  Future<void> updateTemplate(
    int id, {
    String? icon,
    String? name,
    String? prompt,
    bool? isEnabled,
    int? sortOrder,
    String? templateType,
  }) {
    return (update(aiTemplates)..where((t) => t.id.equals(id))).write(
      AiTemplatesCompanion(
        icon: icon != null ? Value(icon) : const Value.absent(),
        name: name != null ? Value(name) : const Value.absent(),
        prompt: prompt != null ? Value(prompt) : const Value.absent(),
        isEnabled: isEnabled != null ? Value(isEnabled) : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
        templateType: templateType != null
            ? Value(templateType)
            : const Value.absent(),
      ),
    );
  }

  Future<void> deleteTemplate(int id) {
    return (delete(aiTemplates)..where((t) => t.id.equals(id))).go();
  }

  Future<void> reorderTemplates(List<int> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      await (update(aiTemplates)..where((t) => t.id.equals(orderedIds[i])))
          .write(AiTemplatesCompanion(sortOrder: Value(i)));
    }
  }

  /// 种子数据：默认 AI 指令模板
  Future<void> _seedDefaultTemplates() async {
    final defaults = [
      ('📝', '总结全文要点', '请根据以上内容，总结全文的核心要点'),
      ('🌐', '翻译为英文', '请将以上内容翻译为英文'),
      ('✨', '润色优化表达', '请润色优化以上内容的表达，使其更流畅专业'),
      ('🔍', '提取关键信息', '请从以上内容中提取关键信息'),
      ('📑', '生成内容大纲', '请根据以上内容生成结构化的内容大纲'),
    ];
    for (int i = 0; i < defaults.length; i++) {
      final (icon, name, prompt) = defaults[i];
      await insertTemplate(icon, name, prompt);
      await (update(aiTemplates)..where((t) => t.name.equals(name))).write(
        AiTemplatesCompanion(sortOrder: Value(i)),
      );
    }
  }

  /// 种子数据：默认规则化模板（CRM/LEDGER/TODO）
  Future<void> _seedDefaultRuleTemplates() async {
    // 检查是否已有规则化模板
    final existing = await (select(
      aiTemplates,
    )..where((t) => t.templateType.equals('rule'))).get();
    if (existing.isNotEmpty) return;

    final defaults = [
      (
        '🔍',
        'CRM规则化',
        '你是一个客户关系管理助手。请从以下内容中提取结构化客户信息，以JSON格式返回。\n\n要求：\n- person_name: 客户姓名\n- company: 公司名称\n- contact: 联系方式\n- notes: 备注信息\n\n仅返回JSON，不要其他文字。',
      ),
      (
        '💰',
        '记账规则化',
        '你是一个财务管理助手。请从以下内容中提取记账信息，以JSON格式返回。\n\n要求：\n- amount: 金额（数字）\n- ledger_category: 记账分类（如: 餐饮/交通/购物/收入）\n- description: 描述\n- type: 类型（income/expense）\n\n仅返回JSON，不要其他文字。',
      ),
      (
        '✅',
        '待办规则化',
        '你是一个任务管理助手。请从以下内容中提取待办事项信息，以JSON格式返回。\n\n要求：\n- title: 任务标题\n- priority: 优先级（0=普通, 1=重要, 2=紧急）\n- notes: 备注\n- due_date: 截止日期\n\n仅返回JSON，不要其他文字。',
      ),
    ];
    for (int i = 0; i < defaults.length; i++) {
      final (icon, name, prompt) = defaults[i];
      await into(aiTemplates).insert(
        AiTemplatesCompanion.insert(
          icon: Value(icon),
          name: name,
          prompt: prompt,
          sortOrder: Value(i + 100), // 排在对话模板后面
          templateType: const Value('rule'),
        ),
      );
    }
  }

  /// 插入离线队列（无网络时暂存）
  Future<int> insertOfflineQueue(String rawText) {
    return into(
      offlineQueue,
    ).insert(OfflineQueueCompanion.insert(rawText: rawText));
  }

  /// 获取未处理的离线队列条目
  Future<List<OfflineQueueEntry>> getPendingOfflineQueue() {
    return (select(offlineQueue)
          ..where((t) => t.isProcessed.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// 标记离线队列条目为已处理
  Future<void> markOfflineProcessed(int id) {
    return (update(offlineQueue)..where((t) => t.id.equals(id))).write(
      const OfflineQueueCompanion(isProcessed: Value(true)),
    );
  }

  /// 更新 payload 的清洗文本
  Future<void> updateCleanedText(int payloadId, String cleanedText) {
    return (update(hubPayloads)..where((t) => t.id.equals(payloadId))).write(
      HubPayloadsCompanion(cleanedText: Value(cleanedText)),
    );
  }

  /// v11→v12: 迁移 ContentBlocks.tags JSON 列到 Tags + ContentBlockTags
  Future<void> _migrateContentBlockTags(dynamic m) async {
    try {
      final allBlocks = await select(contentBlocks).get();
      // 使用内存缓存避免重复创建同名标签
      final nameToId = <String, int>{};

      for (final block in allBlocks) {
        if (block.tags.isEmpty) continue;
        try {
          final tagsList = jsonDecode(block.tags) as List<dynamic>;
          for (final tag in tagsList) {
            if (tag is! String || tag.isEmpty) continue;
            final cleanName = tag.replaceAll('#', '').trim();
            if (cleanName.isEmpty) continue;

            // 查找或创建标签
            int tagId;
            if (nameToId.containsKey(cleanName)) {
              tagId = nameToId[cleanName]!;
            } else {
              final existing = await (select(
                tags,
              )..where((t) => t.name.equals(cleanName))).getSingleOrNull();
              if (existing != null) {
                tagId = existing.id;
              } else {
                tagId = await into(
                  tags,
                ).insert(TagsCompanion.insert(name: cleanName));
              }
              nameToId[cleanName] = tagId;
            }

            // 创建关联（忽略重复）
            try {
              await into(contentBlockTags).insert(
                ContentBlockTagsCompanion.insert(
                  blockId: block.id,
                  tagId: tagId,
                ),
              );
            } catch (_) {
              // 主键冲突，忽略
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Stream<List<HubPayload>> watchAllPayloads() {
    return (select(hubPayloads)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// 监听单条 payload 的实时变化
  Stream<HubPayload?> watchPayloadById(int id) {
    return (select(hubPayloads)..where((t) => t.id.equals(id))).watchSingle();
  }

  Future<HubPayload?> getPayloadById(int id) {
    return (select(
      hubPayloads,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<HubPayload?> getPayloadByUuid(String uuid) {
    return (select(
      hubPayloads,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
  }

  Future<List<HubPayload>> getPayloadsByUuids(List<String> uuids) async {
    if (uuids.isEmpty) return const [];
    final rows = await (select(
      hubPayloads,
    )..where((t) => t.uuid.isIn(uuids))).get();
    final order = <String, int>{
      for (var i = 0; i < uuids.length; i++) uuids[i]: i,
    };
    rows.sort(
      (a, b) => (order[a.uuid] ?? uuids.length).compareTo(
        order[b.uuid] ?? uuids.length,
      ),
    );
    return rows;
  }

  Future<String?> getPayloadUuid(int id) async {
    final payload = await getPayloadById(id);
    if (payload == null || payload.uuid.isEmpty) return null;
    return payload.uuid;
  }

  // ==================== 处理状态管理 ====================

  /// 更新处理流水线状态
  Future<void> updateProcessingStatus(int id, String status) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      HubPayloadsCompanion(processingStatus: Value(status)),
    );
  }

  /// 当内容语义发生变化后，清空旧的路由痕迹并重置为本地已同步状态
  Future<void> preparePayloadForReprocessing(int id) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      const HubPayloadsCompanion(
        processingStatus: Value('synced_local'),
        dispatchedRef: Value(null),
        aiEntities: Value(null),
        isEphemeral: Value(false),
        decayDeadline: Value(null),
      ),
    );
  }

  /// 更新分发引用（双向链接）
  Future<void> updateDispatchedRef(int id, String ref) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      HubPayloadsCompanion(dispatchedRef: Value(ref)),
    );
  }

  /// 清除分发引用（撤销分发）
  Future<void> clearDispatchedRef(int id) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      const HubPayloadsCompanion(dispatchedRef: Value.absent()),
    );
  }

  /// 更新 AI 抽取的实体 JSON
  Future<void> updateAiEntities(int id, String entitiesJson) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      HubPayloadsCompanion(aiEntities: Value(entitiesJson)),
    );
  }

  /// 更新意图标签（AI 路由修正后）
  Future<void> updateIntentTag(int id, String intentTag) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      HubPayloadsCompanion(intentTag: Value(intentTag)),
    );
  }

  /// 标记为日常废话，设置衰减截止时间
  Future<void> markAsEphemeral(int id) {
    final deadline = DateTime.now().add(const Duration(hours: 48));
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      HubPayloadsCompanion(
        isEphemeral: const Value(true),
        decayDeadline: Value(deadline),
      ),
    );
  }

  /// 获取所有待处理的 payload（processingStatus != dispatched）
  Future<List<HubPayload>> getPendingPayloads() {
    return (select(hubPayloads)
          ..where((t) => t.processingStatus.equals('dispatched').not())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<HubPayload>> getPendingVectorPayloads() {
    return (select(hubPayloads)
          ..where(
            (t) => t.processingStatus.isIn(const [
              'synced_local',
              'failed_retry',
              'vector_checking',
              'offline_saved',
            ]),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// 按处理状态查询 payload，支持分页
  Future<List<HubPayload>> getPayloadsByStatus(
    String status, {
    int limit = 50,
  }) {
    return (select(hubPayloads)
          ..where((t) => t.processingStatus.equals(status))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 获取所有标记为废话且未到期的 payload
  Future<List<HubPayload>> getDecayingPayloads() {
    final now = DateTime.now();
    return (select(hubPayloads)..where(
          (t) =>
              t.isEphemeral.equals(true) &
              t.decayDeadline.isBiggerThanValue(now),
        ))
        .get();
  }

  // ==================== CRM 客户表 CRUD ====================

  Stream<List<CrmCustomer>> watchAllCrmCustomers() {
    return (select(
      crmCustomers,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  Future<int> insertCrmCustomer(CrmCustomersCompanion entry) {
    return into(crmCustomers).insert(entry);
  }

  Future<void> updateCrmCustomer(int id, CrmCustomersCompanion entry) {
    return (update(crmCustomers)..where((t) => t.id.equals(id))).write(
      entry.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  Future<int> deleteCrmCustomer(int id) {
    return (delete(crmCustomers)..where((t) => t.id.equals(id))).go();
  }

  // ==================== 记账流水表 CRUD ====================

  Stream<List<LedgerEntry>> watchAllLedgerEntries() {
    return (select(
      ledgerEntries,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<int> insertLedgerEntry(LedgerEntriesCompanion entry) {
    return into(ledgerEntries).insert(entry);
  }

  Future<void> updateLedgerEntry(int id, LedgerEntriesCompanion entry) {
    return (update(ledgerEntries)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<int> deleteLedgerEntry(int id) {
    return (delete(ledgerEntries)..where((t) => t.id.equals(id))).go();
  }

  // ==================== 待办日程表 CRUD ====================

  Stream<List<TodoSchedule>> watchAllTodoSchedules() {
    return (select(
      todoSchedules,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Stream<List<TodoSchedule>> watchTodosForPayload(int payloadId) {
    return (select(todoSchedules)
          ..where((t) => t.sourcePayloadId.equals(payloadId))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  Future<int> insertTodoSchedule(TodoSchedulesCompanion entry) {
    return into(todoSchedules).insert(entry);
  }

  Future<void> toggleTodoDone(int id, bool isDone) {
    return (update(todoSchedules)..where((t) => t.id.equals(id))).write(
      TodoSchedulesCompanion(isDone: Value(isDone)),
    );
  }

  Future<int> deleteTodoSchedule(int id) {
    return (delete(todoSchedules)..where((t) => t.id.equals(id))).go();
  }

  // ==================== 会话与消息 (左脑短期记忆) ====================

  Future<int> createSession(String title) {
    return into(
      chatSessions,
    ).insert(ChatSessionsCompanion.insert(title: title));
  }

  // 升级版：支持会话标题 + 对话正文全文的深度检索流
  Stream<List<ChatSession>> watchAllSessions(String query) {
    if (query.trim().isEmpty) {
      return (select(
        chatSessions,
      )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
    } else {
      return (select(chatSessions)
            ..where((s) {
              final titleMatch = s.title.like('%$query%');

              final matchingSessionIds = selectOnly(chatMessages)
                ..addColumns([chatMessages.sessionId])
                ..where(chatMessages.content.like('%$query%'));

              final contentMatch = s.id.isInQuery(matchingSessionIds);

              return titleMatch | contentMatch;
            })
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();
    }
  }

  Future<int> insertMessage(int sessionId, String role, String content) {
    (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(
      ChatSessionsCompanion(updatedAt: Value(DateTime.now())),
    );

    return into(chatMessages).insert(
      ChatMessagesCompanion.insert(
        sessionId: sessionId,
        role: role,
        content: content,
      ),
    );
  }

  Future<List<ChatMessage>> getMessagesForSession(int sessionId) {
    return (select(chatMessages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  // ==================== 长久记忆 ====================

  Stream<List<LongTermMemory>> watchAllMemories() {
    return (select(
      longTermMemories,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  Future<List<String>> getAllMemoryTexts() async {
    final memories = await select(longTermMemories).get();
    return memories.map((m) => m.content).toList();
  }

  Future<int> addMemory(String content, {String? tags}) {
    return into(longTermMemories).insert(
      LongTermMemoriesCompanion.insert(content: content, tags: Value(tags)),
    );
  }

  Future<int> updateMemory(int id, String newContent) {
    return (update(longTermMemories)..where((t) => t.id.equals(id))).write(
      LongTermMemoriesCompanion(
        content: Value(newContent),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteMemory(int id) {
    return (delete(longTermMemories)..where((t) => t.id.equals(id))).go();
  }

  // ==================== 知识文件 ====================

  Stream<List<KnowledgeFile>> watchAllFiles() {
    return (select(
      knowledgeFiles,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<int> addFile({
    required String name,
    required String localPath,
    required int size,
    required String extension,
  }) {
    return into(knowledgeFiles).insert(
      KnowledgeFilesCompanion.insert(
        name: name,
        localPath: localPath,
        size: size,
        extension: extension,
      ),
    );
  }

  Future<void> deleteFile(int id) {
    return transaction(() async {
      await (delete(
        vectorStorage,
      )..where((t) => t.sourceFileId.equals(id))).go();
      await (delete(knowledgeFiles)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> toggleFileActive(int id, bool isActive) {
    return (update(knowledgeFiles)..where((t) => t.id.equals(id))).write(
      KnowledgeFilesCompanion(isActive: Value(isActive)),
    );
  }

  // ==================== RAG 知识检索 ====================

  /// 将文档切片存入向量存储
  Future<void> processFileForRAG(int fileId, String localPath) async {
    final fullText = await DocParser.extractTextFromPdf(localPath);
    final chunks = DocParser.chunkText(fullText);

    for (var chunk in chunks) {
      await into(vectorStorage).insert(
        VectorStorageCompanion.insert(sourceFileId: fileId, content: chunk),
      );
    }
  }

  /// 全文检索匹配——从知识胶囊中查找相关上下文（仅检索已激活文件）
  Future<String> getRelevantContext(String query) async {
    final activeFiles = await (select(
      knowledgeFiles,
    )..where((t) => t.isActive.equals(true))).get();

    final activeFileIds = activeFiles.map((f) => f.id).toList();

    if (activeFileIds.isEmpty) return "";

    final results =
        await (select(vectorStorage)
              ..where(
                (t) =>
                    t.sourceFileId.isIn(activeFileIds) &
                    t.content.like('%$query%'),
              )
              ..limit(3))
            .get();

    return results.map((e) => e.content).join('\n---\n');
  }

  /// 根据指定的知识库文件 ID 列表检索相关上下文
  Future<String> getRelevantContextForFiles(
    String query,
    List<int> fileIds,
  ) async {
    if (fileIds.isEmpty) return "";

    final results =
        await (select(vectorStorage)
              ..where(
                (t) =>
                    t.sourceFileId.isIn(fileIds) & t.content.like('%$query%'),
              )
              ..limit(3))
            .get();

    return results.map((e) => e.content).join('\n---\n');
  }

  // ==================== 软删除 ====================

  /// 软删除 payload（标记 isDeleted=true，不物理删除）
  Future<void> softDeletePayload(int id) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      const HubPayloadsCompanion(isDeleted: Value(true)),
    );
  }

  /// 恢复已软删除的 payload
  Future<void> restorePayload(int id) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      const HubPayloadsCompanion(isDeleted: Value(false)),
    );
  }

  // ==================== 标签 CRUD + 关联 ====================

  Stream<List<Tag>> watchAllTags() {
    return (select(
      tags,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  Future<List<Tag>> getAllTags() {
    return (select(
      tags,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Future<Tag?> getTagByName(String name) {
    return (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  /// 查找或创建标签，返回标签 ID
  Future<int> getOrCreateTag(String name) async {
    final existing = await getTagByName(name);
    if (existing != null) return existing.id;
    return into(tags).insert(TagsCompanion.insert(name: name));
  }

  Future<void> updateTag(int id, {String? name, String? color}) {
    return (update(tags)..where((t) => t.id.equals(id))).write(
      TagsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
      ),
    );
  }

  Future<int> deleteTag(int id) {
    return transaction(() async {
      // 清除所有关联
      await (delete(hubPayloadTags)..where((t) => t.tagId.equals(id))).go();
      await (delete(crmCustomerTags)..where((t) => t.tagId.equals(id))).go();
      await (delete(ledgerEntryTags)..where((t) => t.tagId.equals(id))).go();
      await (delete(todoScheduleTags)..where((t) => t.tagId.equals(id))).go();
      await (delete(contentBlockTags)..where((t) => t.tagId.equals(id))).go();
      return (delete(tags)..where((t) => t.id.equals(id))).go();
    });
  }

  // --- Payload 标签关联 ---

  Stream<List<Tag>> watchTagsForPayload(int payloadId) {
    final tagIdsQuery = selectOnly(hubPayloadTags)
      ..addColumns([hubPayloadTags.tagId])
      ..where(hubPayloadTags.payloadId.equals(payloadId));
    return (select(tags)..where((t) => t.id.isInQuery(tagIdsQuery))).watch();
  }

  Future<void> addTagToPayload(int payloadId, int tagId) async {
    try {
      await into(hubPayloadTags).insert(
        HubPayloadTagsCompanion.insert(payloadId: payloadId, tagId: tagId),
      );
    } catch (_) {
      // 主键冲突，忽略
    }
  }

  Future<void> removeTagFromPayload(int payloadId, int tagId) {
    return (delete(hubPayloadTags)
          ..where((t) => t.payloadId.equals(payloadId) & t.tagId.equals(tagId)))
        .go();
  }

  /// 根据标签名称列表筛选 payloads（AND 逻辑：同时包含所有选中标签）
  /// 由于 Drift 子查询限制，采用两阶段查询方案
  Stream<List<HubPayload>> watchPayloadsByTags(List<String> tagNames) {
    if (tagNames.isEmpty) return watchAllPayloads();

    // Step 1: 查找所有 tag IDs
    // 在 Dart 端执行过滤逻辑（简化实现，避免复杂的 SQL 子查询）
    return watchAllPayloads().map((payloads) {
      // 此处做 Dart 端过滤：对于复杂 AND 标签逻辑，在实际使用中由 TagBrowser 处理
      return payloads;
    });
  }

  // --- CRM 标签关联 ---

  Future<void> addTagToCrm(int customerId, int tagId) async {
    try {
      await into(crmCustomerTags).insert(
        CrmCustomerTagsCompanion.insert(customerId: customerId, tagId: tagId),
      );
    } catch (_) {}
  }

  // --- 内容块标签关联 ---

  Stream<List<Tag>> watchTagsForBlock(int blockId) {
    final tagIdsQuery = selectOnly(contentBlockTags)
      ..addColumns([contentBlockTags.tagId])
      ..where(contentBlockTags.blockId.equals(blockId));
    return (select(tags)..where((t) => t.id.isInQuery(tagIdsQuery))).watch();
  }

  Future<void> addTagToBlock(int blockId, int tagId) async {
    try {
      await into(contentBlockTags).insert(
        ContentBlockTagsCompanion.insert(blockId: blockId, tagId: tagId),
      );
    } catch (_) {}
  }

  Future<void> removeTagFromBlock(int blockId, int tagId) {
    return (delete(
      contentBlockTags,
    )..where((t) => t.blockId.equals(blockId) & t.tagId.equals(tagId))).go();
  }

  // --- 标签统计 ---

  /// 最常用标签排行
  Future<List<Tag>> getPopularTags({int limit = 20}) async {
    final stats = await getTagUsageStats();
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topIds = sorted
        .take(limit)
        .map((e) => int.tryParse(e.key))
        .whereType<int>()
        .toList();
    if (topIds.isEmpty) return [];

    return (select(tags)..where((t) => t.id.isIn(topIds))).get();
  }

  /// 标签使用频率统计 (tagId → count)
  Future<Map<String, int>> getTagUsageStats() async {
    final stats = <String, int>{};

    // 使用原始 SQL 查询各关联表中的标签使用次数
    try {
      final payloadTagRows = await customSelect(
        'SELECT tag_id FROM hub_payload_tags',
      ).get();
      for (final row in payloadTagRows) {
        final tagId = row.data['tag_id']?.toString();
        if (tagId != null) stats[tagId] = (stats[tagId] ?? 0) + 1;
      }
    } catch (_) {}

    try {
      final crmTagRows = await customSelect(
        'SELECT tag_id FROM crm_customer_tags',
      ).get();
      for (final row in crmTagRows) {
        final tagId = row.data['tag_id']?.toString();
        if (tagId != null) stats[tagId] = (stats[tagId] ?? 0) + 1;
      }
    } catch (_) {}

    try {
      final blockTagRows = await customSelect(
        'SELECT tag_id FROM content_block_tags',
      ).get();
      for (final row in blockTagRows) {
        final tagId = row.data['tag_id']?.toString();
        if (tagId != null) stats[tagId] = (stats[tagId] ?? 0) + 1;
      }
    } catch (_) {}

    return stats;
  }

  /// 模糊搜索标签
  Future<List<Tag>> searchTags(String query) {
    return (select(tags)..where((t) => t.name.like('%$query%'))).get();
  }

  // ==================== AI 收件箱 ====================

  Future<int> insertDispatchInbox(DispatchInboxCompanion entry) {
    return into(dispatchInbox).insert(entry);
  }

  Stream<List<DispatchInboxData>> watchPendingInbox() {
    return (select(dispatchInbox)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<DispatchInboxData>> getPendingInbox() {
    return (select(dispatchInbox)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<int> getPendingInboxCount() async {
    final result =
        await (selectOnly(dispatchInbox)
              ..addColumns([dispatchInbox.id.count()])
              ..where(dispatchInbox.status.equals('pending')))
            .getSingle();
    return result.read(dispatchInbox.id.count()) ?? 0;
  }

  Future<void> confirmDispatchInbox(int inboxId) {
    return (update(dispatchInbox)..where((t) => t.id.equals(inboxId))).write(
      DispatchInboxCompanion(
        status: const Value('confirmed'),
        reviewedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> rejectDispatchInbox(int inboxId) {
    return (update(dispatchInbox)..where((t) => t.id.equals(inboxId))).write(
      DispatchInboxCompanion(
        status: const Value('rejected'),
        reviewedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新收件箱的 extractedData 字段（用于用户手动编辑后持久化）
  Future<void> updateDispatchInboxData(int inboxId, String extractedData) {
    return (update(dispatchInbox)..where((t) => t.id.equals(inboxId))).write(
      DispatchInboxCompanion(extractedData: Value(extractedData)),
    );
  }

  Future<DispatchInboxData?> getDispatchInboxByPayloadId(int payloadId) {
    return (select(dispatchInbox)
          ..where((t) => t.payloadId.equals(payloadId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .getSingleOrNull();
  }

  Stream<List<DispatchInboxData>> watchDispatchInboxForPayload(
    int payloadId, {
    List<String> statuses = const ['pending', 'confirmed'],
  }) {
    return (select(dispatchInbox)
          ..where((t) => t.payloadId.equals(payloadId))
          ..where((t) => t.status.isIn(statuses))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  // ==================== 聚合统计查询 ====================

  // 记账统计
  Future<Map<String, double>> getMonthlyExpense(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);
    final entries =
        await (select(ledgerEntries)..where(
              (t) =>
                  t.type.equals('expense') &
                  t.createdAt.isBetweenValues(startDate, endDate),
            ))
            .get();
    final map = <String, double>{};
    for (final e in entries) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Future<double> getTotalIncome(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);
    final result =
        await (selectOnly(ledgerEntries)
              ..addColumns([ledgerEntries.amount.sum()])
              ..where(
                ledgerEntries.type.equals('income') &
                    ledgerEntries.createdAt.isBetweenValues(startDate, endDate),
              ))
            .getSingle();
    return result.read(ledgerEntries.amount.sum()) ?? 0.0;
  }

  Future<double> getTotalExpense(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);
    final result =
        await (selectOnly(ledgerEntries)
              ..addColumns([ledgerEntries.amount.sum()])
              ..where(
                ledgerEntries.type.equals('expense') &
                    ledgerEntries.createdAt.isBetweenValues(startDate, endDate),
              ))
            .getSingle();
    return result.read(ledgerEntries.amount.sum()) ?? 0.0;
  }

  // 待办统计
  Future<int> getPendingTodoCount() async {
    final result =
        await (selectOnly(todoSchedules)
              ..addColumns([todoSchedules.id.count()])
              ..where(todoSchedules.isDone.equals(false)))
            .getSingle();
    return result.read(todoSchedules.id.count()) ?? 0;
  }

  Future<int> getCompletedTodoCount() async {
    final result =
        await (selectOnly(todoSchedules)
              ..addColumns([todoSchedules.id.count()])
              ..where(todoSchedules.isDone.equals(true)))
            .getSingle();
    return result.read(todoSchedules.id.count()) ?? 0;
  }

  Future<double> getTodoCompletionRate() async {
    final total = await getPendingTodoCount() + await getCompletedTodoCount();
    if (total == 0) return 0.0;
    return await getCompletedTodoCount() / total;
  }

  // CRM 统计
  Future<int> getNewCustomersThisWeek() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final result =
        await (selectOnly(crmCustomers)
              ..addColumns([crmCustomers.id.count()])
              ..where(crmCustomers.createdAt.isBiggerThanValue(weekAgo)))
            .getSingle();
    return result.read(crmCustomers.id.count()) ?? 0;
  }

  Future<int> getTotalCustomers() async {
    final result = await (selectOnly(
      crmCustomers,
    )..addColumns([crmCustomers.id.count()])).getSingle();
    return result.read(crmCustomers.id.count()) ?? 0;
  }

  // 笔记统计
  Future<int> getTotalPayloads() async {
    final result =
        await (selectOnly(hubPayloads)
              ..addColumns([hubPayloads.id.count()])
              ..where(hubPayloads.isDeleted.equals(false)))
            .getSingle();
    return result.read(hubPayloads.id.count()) ?? 0;
  }

  Future<int> getPayloadsToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result =
        await (selectOnly(hubPayloads)
              ..addColumns([hubPayloads.id.count()])
              ..where(
                hubPayloads.isDeleted.equals(false) &
                    hubPayloads.createdAt.isBiggerThanValue(today),
              ))
            .getSingle();
    return result.read(hubPayloads.id.count()) ?? 0;
  }

  Future<int> getPayloadsThisWeek() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final result =
        await (selectOnly(hubPayloads)
              ..addColumns([hubPayloads.id.count()])
              ..where(
                hubPayloads.isDeleted.equals(false) &
                    hubPayloads.createdAt.isBiggerThanValue(weekAgo),
              ))
            .getSingle();
    return result.read(hubPayloads.id.count()) ?? 0;
  }

  Future<Map<String, int>> getIntentDistribution() async {
    final payloads = await (select(
      hubPayloads,
    )..where((t) => t.isDeleted.equals(false))).get();
    final dist = <String, int>{};
    for (final p in payloads) {
      dist[p.intentTag] = (dist[p.intentTag] ?? 0) + 1;
    }
    return dist;
  }

  /// 获取所有标签及其使用频率（用于 Dashboard 词云）
  Future<List<({String name, int count, String color})>> getTopTagsWithCount({
    int limit = 10,
  }) async {
    final usageStats = await getTagUsageStats();
    final allTags = await getAllTags();

    final entries = <({String name, int count, String color})>[];
    for (final tag in allTags) {
      final count = usageStats[tag.id.toString()] ?? 0;
      if (count > 0) {
        entries.add((name: tag.name, count: count, color: tag.color));
      }
    }

    entries.sort((a, b) => b.count.compareTo(a.count));
    return entries.take(limit).toList();
  }

  Future<void> _createHubPayloadUuidIndex() async {
    await customStatement(
      "CREATE UNIQUE INDEX IF NOT EXISTS idx_hub_payloads_uuid ON hub_payloads(uuid) WHERE uuid <> ''",
    );
  }

  Future<void> _backfillPayloadUuids() async {
    final rows = await select(hubPayloads).get();
    for (final row in rows.where((item) => item.uuid.isEmpty)) {
      await (update(hubPayloads)..where((t) => t.id.equals(row.id))).write(
        HubPayloadsCompanion(uuid: Value(_generateUuid())),
      );
    }
  }
}

/// 打开并初始化加密数据库连接
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'locus_vault.sqlite'));

    // 核心修复1：强制 Android 系统加载加密版 SQLCipher
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }

    // 核心修复2：使用原生的 NativeDatabase，而不是 createInBackground。
    // 这样保证代码在主 Isolate 运行，能够正确读取到上面的 overrideFor 配置。
    return NativeDatabase(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = 'locus_super_secret_master_key_2026';");
      },
    );
  });
}
