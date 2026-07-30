import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../utils/doc_parser.dart';

part 'database.g.dart';

class HubPayloads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawText => text()();
  TextColumn get mediaPaths => text().withDefault(const Constant('[]'))();
  TextColumn get intentTag => text().withDefault(const Constant('NOTE'))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ChatSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(ChatSessions, #id)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class LongTermMemories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get tags => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class KnowledgeFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get localPath => text()();
  IntColumn get size => integer()();
  TextColumn get extension => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class VectorStorage extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceFileId => integer().references(KnowledgeFiles, #id)();
  TextColumn get content => text()();
  TextColumn get embedding => text().nullable()();
}

class AppConfig extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get aliases => text().withDefault(const Constant('[]'))();
  TextColumn get company => text().nullable()();
  TextColumn get role => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Deals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contactId => integer().references(Contacts, #id)();
  TextColumn get title => text()();
  TextColumn get stage => text().withDefault(const Constant('lead'))();
  RealColumn get value => real().nullable()();
  IntColumn get probability => integer().nullable()();
  DateTimeColumn get expectedCloseDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contactId => integer().references(Contacts, #id)();
  IntColumn get dealId => integer().references(Deals, #id).nullable()();
  TextColumn get type => text()();
  TextColumn get content => text()();
  TextColumn get mediaPaths => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get specs => text().withDefault(const Constant('{}'))();
  RealColumn get unitPrice => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get contactId => integer().references(Contacts, #id).nullable()();
  IntColumn get dealId => integer().references(Deals, #id).nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get sourceText => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  HubPayloads, ChatSessions, ChatMessages, LongTermMemories,
  KnowledgeFiles, VectorStorage, AppConfig, Contacts, Deals,
  Activities, Products, Tasks,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async { await m.createAll(); },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from <= 1) { await m.createTable(chatSessions); await m.createTable(chatMessages); }
        if (from <= 2) { await m.createTable(longTermMemories); await m.createTable(knowledgeFiles); }
        if (from <= 3) { await customStatement('DROP TABLE IF EXISTS knowledge_files'); await m.createTable(knowledgeFiles); }
        if (from <= 4) { await m.createTable(vectorStorage); }
        if (from <= 5) { await customStatement('ALTER TABLE knowledge_files ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1'); }
        if (from <= 6) {
          await m.createTable(appConfig); await m.createTable(contacts);
          await m.createTable(deals); await m.createTable(activities);
          await m.createTable(products); await m.createTable(tasks);
        }
        // v7 -> v8: VectorStorage embedding column
        if (from <= 7) {
          await customStatement('ALTER TABLE vector_storage ADD COLUMN embedding TEXT');
        }
      },
      beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON'); },
    );
  }

  // ==================== HubPayloads ====================
  Future<int> insertPayload(HubPayloadsCompanion entry) => into(hubPayloads).insert(entry);
  Future<int> updatePayload(int id, String rawText, String intentTag) => (update(hubPayloads)..where((t) => t.id.equals(id))).write(HubPayloadsCompanion(rawText: Value(rawText), intentTag: Value(intentTag)));
  Stream<List<HubPayload>> watchAllPayloads() => (select(hubPayloads)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch();

  // ==================== Chat ====================
  Future<int> createSession(String title) => into(chatSessions).insert(ChatSessionsCompanion.insert(title: title));
  Stream<List<ChatSession>> watchAllSessions(String query) {
    if (query.trim().isEmpty) return (select(chatSessions)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
    return (select(chatSessions)..where((s) {
      final titleMatch = s.title.like('%$query%');
      final matchingSessionIds = selectOnly(chatMessages)..addColumns([chatMessages.sessionId])..where(chatMessages.content.like('%$query%'));
      return titleMatch | s.id.isInQuery(matchingSessionIds);
    })..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }
  Future<int> insertMessage(int sessionId, String role, String content) {
    (update(chatSessions)..where((t) => t.id.equals(sessionId))).write(ChatSessionsCompanion(updatedAt: Value(DateTime.now())));
    return into(chatMessages).insert(ChatMessagesCompanion.insert(sessionId: sessionId, role: role, content: content));
  }
  Future<List<ChatMessage>> getMessagesForSession(int sessionId) => (select(chatMessages)..where((t) => t.sessionId.equals(sessionId))..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

  // ==================== Memories ====================
  Stream<List<LongTermMemory>> watchAllMemories() => (select(longTermMemories)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  Future<List<String>> getAllMemoryTexts() async { final m = await select(longTermMemories).get(); return m.map((e) => e.content).toList(); }
  Future<int> addMemory(String content, {String? tags}) => into(longTermMemories).insert(LongTermMemoriesCompanion.insert(content: content, tags: Value(tags)));
  Future<int> updateMemory(int id, String newContent) => (update(longTermMemories)..where((t) => t.id.equals(id))).write(LongTermMemoriesCompanion(content: Value(newContent), updatedAt: Value(DateTime.now())));
  Future<int> deleteMemory(int id) => (delete(longTermMemories)..where((t) => t.id.equals(id))).go();

  // ==================== Knowledge Files ====================
  Stream<List<KnowledgeFile>> watchAllFiles() => (select(knowledgeFiles)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  Future<int> addFile({required String name, required String localPath, required int size, required String extension}) => into(knowledgeFiles).insert(KnowledgeFilesCompanion.insert(name: name, localPath: localPath, size: size, extension: extension));
  Future<void> deleteFile(int id) => transaction(() async { await (delete(vectorStorage)..where((t) => t.sourceFileId.equals(id))).go(); await (delete(knowledgeFiles)..where((t) => t.id.equals(id))).go(); });
  Future<void> toggleFileActive(int id, bool isActive) => (update(knowledgeFiles)..where((t) => t.id.equals(id))).write(KnowledgeFilesCompanion(isActive: Value(isActive)));

  // ==================== RAG (legacy LIKE-based) ====================
  Future<void> processFileForRAG(int fileId, String localPath) async {
    final fullText = await DocParser.extractTextFromPdf(localPath);
    final chunks = DocParser.chunkText(fullText);
    for (var chunk in chunks) {
      await into(vectorStorage).insert(VectorStorageCompanion.insert(sourceFileId: fileId, content: chunk));
    }
  }

  Future<String> getRelevantContext(String query) async {
    final activeFiles = await (select(knowledgeFiles)..where((t) => t.isActive.equals(true))).get();
    if (activeFiles.isEmpty) return "";
    final activeFileIds = activeFiles.map((f) => f.id).toList();
    final results = await (select(vectorStorage)..where((t) => t.sourceFileId.isIn(activeFileIds) & t.content.like('%$query%'))..limit(3)).get();
    return results.map((e) => e.content).join('\n---\n');
  }

  // ==================== Vector Storage (V2 enhanced) ====================
  Future<void> storeVector(int sourceFileId, String content, String embeddingJson) => into(vectorStorage).insert(VectorStorageCompanion.insert(sourceFileId: sourceFileId, content: content, embedding: Value(embeddingJson)));

  Future<List<Map<String, dynamic>>> getAllVectorsForFiles(List<int> fileIds) async {
    if (fileIds.isEmpty) return [];
    final rows = await (select(vectorStorage)..where((t) => t.sourceFileId.isIn(fileIds) & t.embedding.isNotNull())).get();
    return rows.where((r) => r.embedding != null && r.embedding!.isNotEmpty).map((r) => {'id': r.id, 'content': r.content, 'source_file_id': r.sourceFileId, 'embedding': r.embedding!}).toList();
  }

  // ==================== AppConfig ====================
  Future<String?> getConfig(String key) async { final r = await (select(appConfig)..where((t) => t.key.equals(key))).getSingleOrNull(); return r?.value; }
  Future<void> setConfig(String key, String value) => into(appConfig).insertOnConflictUpdate(AppConfigCompanion(key: Value(key), value: Value(value)));

  // ==================== Contacts ====================
  Future<int> addContact({required String name, String aliases = '[]', String? company, String? role, String? phone, String? email, String tags = '[]'}) => into(contacts).insert(ContactsCompanion.insert(name: name, aliases: Value(aliases), company: Value(company), role: Value(role), phone: Value(phone), email: Value(email), tags: Value(tags)));
  Stream<List<Contact>> watchAllContacts() => (select(contacts)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  Future<List<Contact>> searchContacts(String query) => (select(contacts)..where((t) => t.name.like('%$query%') | t.company.like('%$query%') | t.aliases.like('%$query%'))..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  Future<Contact?> getContact(int id) => (select(contacts)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> updateContact(int id, ContactsCompanion companion) => (update(contacts)..where((t) => t.id.equals(id))).write(companion.copyWith(updatedAt: Value(DateTime.now())));

  // ==================== Activities ====================
  Future<int> addActivity({required int contactId, int? dealId, required String type, required String content, String mediaPaths = '[]'}) {
    (update(contacts)..where((t) => t.id.equals(contactId))).write(ContactsCompanion(updatedAt: Value(DateTime.now())));
    return into(activities).insert(ActivitiesCompanion.insert(contactId: contactId, dealId: Value(dealId), type: type, content: content, mediaPaths: Value(mediaPaths)));
  }
  Stream<List<Activity>> watchActivitiesForContact(int contactId) => (select(activities)..where((t) => t.contactId.equals(contactId))..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  // ==================== Tasks ====================
  Future<int> addTask({required String title, int? contactId, int? dealId, DateTime? dueDate, int priority = 0, String? sourceText}) => into(tasks).insert(TasksCompanion.insert(title: title, contactId: Value(contactId), dealId: Value(dealId), dueDate: Value(dueDate), priority: Value(priority), sourceText: Value(sourceText)));
  Stream<List<Task>> watchActiveTasks() => (select(tasks)..where((t) => t.status.equals('pending'))..orderBy([(t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc), (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc)])).watch();

  // ==================== Deals ====================
  Future<int> addDeal({required int contactId, required String title, String stage = 'lead', double? value, int? probability, DateTime? expectedCloseDate}) => into(deals).insert(DealsCompanion.insert(contactId: contactId, title: title, stage: Value(stage), value: Value(value), probability: Value(probability), expectedCloseDate: Value(expectedCloseDate)));
  Stream<List<Deal>> watchDealsForContact(int contactId) => (select(deals)..where((t) => t.contactId.equals(contactId))..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  // ==================== Products ====================
  Future<int> addProduct({required String name, String? category, String specs = '{}', double? unitPrice}) => into(products).insert(ProductsCompanion.insert(name: name, category: Value(category), specs: Value(specs), unitPrice: Value(unitPrice)));
  Stream<List<Product>> watchAllProducts() => (select(products)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'locus_vault.sqlite'));
    if (Platform.isAndroid) { open.overrideFor(OperatingSystem.android, openCipherOnAndroid); }
    return NativeDatabase(file, setup: (rawDb) { rawDb.execute("PRAGMA key = 'locus_super_secret_master_key_2026';"); });
  });
}
