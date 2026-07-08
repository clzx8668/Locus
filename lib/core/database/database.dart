import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../utils/doc_parser.dart';

part 'database.g.dart';

/// 核心表：HubPayloads (多模态路由载荷表)
class HubPayloads extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get rawText => text()();

  TextColumn get mediaPaths => text().withDefault(const Constant('[]'))();

  TextColumn get intentTag => text().withDefault(const Constant('NOTE'))();

  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

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
      const Constant('text'))(); // 'text', 'voice', 'image', 'file'

  TextColumn get content => text()(); // 文本内容或描述

  TextColumn get mediaPaths =>
      text().withDefault(const Constant('[]'))(); // JSON数组: 图片/文件路径

  TextColumn get sourceType => text()
      .withDefault(const Constant('manual'))(); // 'manual' | 'voice' | 'scan'

  BoolColumn get aiPolished =>
      boolean().withDefault(const Constant(false))(); // AI是否已润色

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

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

@DriftDatabase(tables: [
  HubPayloads,
  ChatSessions,
  ChatMessages,
  LongTermMemories,
  KnowledgeFiles,
  VectorStorage,
  IdeaTasks,
  ContentBlocks,
  AiConversations,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
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
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<int> insertPayload(HubPayloadsCompanion entry) {
    return into(hubPayloads).insert(entry);
  }

  Future<void> updatePayload(int id, String rawText, String intentTag) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      HubPayloadsCompanion(
        rawText: Value(rawText),
        intentTag: Value(intentTag),
      ),
    );
  }

  Future<void> updateMediaPaths(int id, String mediaPaths) {
    return (update(hubPayloads)..where((t) => t.id.equals(id))).write(
      HubPayloadsCompanion(mediaPaths: Value(mediaPaths)),
    );
  }

  Future<int> deletePayload(int id) {
    return (delete(hubPayloads)..where((t) => t.id.equals(id))).go();
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

  // ==================== 任务清单 ====================

  Stream<List<IdeaTask>> watchTasksForPayload(int payloadId) {
    return (select(ideaTasks)
          ..where((t) => t.payloadId.equals(payloadId))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Future<int> insertTask(int payloadId, String content, [int sortOrder = 0]) {
    return into(ideaTasks).insert(
      IdeaTasksCompanion.insert(
        payloadId: payloadId,
        content: content,
        sortOrder: Value(sortOrder),
      ),
    );
  }

  Future<void> toggleTask(int taskId, bool isDone) {
    return (update(ideaTasks)..where((t) => t.id.equals(taskId))).write(
      IdeaTasksCompanion(isDone: Value(isDone)),
    );
  }

  Future<int> deleteTask(int taskId) {
    return (delete(ideaTasks)..where((t) => t.id.equals(taskId))).go();
  }

  /// 删除某条闪念对应的所有任务
  Future<int> deleteTasksForPayload(int payloadId) {
    return (delete(ideaTasks)..where((t) => t.payloadId.equals(payloadId)))
        .go();
  }

  // ==================== 内容块 ====================

  Stream<List<ContentBlock>> watchBlocksForPayload(int payloadId) {
    return (select(contentBlocks)
          ..where((t) => t.payloadId.equals(payloadId))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Future<int> insertBlock(
      int payloadId, String blockType, String content, String mediaPaths,
      [String sourceType = 'manual']) {
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
          content: Value(content), mediaPaths: Value(mediaPaths)),
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

  Stream<List<HubPayload>> watchAllPayloads() {
    return (select(hubPayloads)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // ==================== 会话与消息 (左脑短期记忆) ====================

  Future<int> createSession(String title) {
    return into(chatSessions).insert(
      ChatSessionsCompanion.insert(title: title),
    );
  }

  // 升级版：支持会话标题 + 对话正文全文的深度检索流
  Stream<List<ChatSession>> watchAllSessions(String query) {
    if (query.trim().isEmpty) {
      return (select(chatSessions)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();
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
    return (select(longTermMemories)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
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
    return (select(knowledgeFiles)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
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
      await (delete(vectorStorage)..where((t) => t.sourceFileId.equals(id)))
          .go();
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
        VectorStorageCompanion.insert(
          sourceFileId: fileId,
          content: chunk,
        ),
      );
    }
  }

  /// 全文检索匹配——从知识胶囊中查找相关上下文（仅检索已激活文件）
  Future<String> getRelevantContext(String query) async {
    final activeFiles = await (select(knowledgeFiles)
          ..where((t) => t.isActive.equals(true)))
        .get();

    final activeFileIds = activeFiles.map((f) => f.id).toList();

    if (activeFileIds.isEmpty) return "";

    final results = await (select(vectorStorage)
          ..where((t) =>
              t.sourceFileId.isIn(activeFileIds) & t.content.like('%$query%'))
          ..limit(3))
        .get();

    return results.map((e) => e.content).join('\n---\n');
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
    return NativeDatabase(file, setup: (rawDb) {
      rawDb.execute("PRAGMA key = 'locus_super_secret_master_key_2026';");
    });
  });
}
