export '../../../core/database/database.dart'
    show ChatMessage, ChatSession, KnowledgeFile;

import '../../../core/database/database.dart';

/// 聊天协调仓库 —— 封装会话、消息、长期记忆与知识库检索能力
class ChatRepository {
  final AppDatabase _db;

  ChatRepository(this._db);

  Stream<List<ChatSession>> watchAllSessions(String query) =>
      _db.watchAllSessions(query);

  Future<int> createSession(String title) => _db.createSession(title);

  Future<int> insertMessage(int sessionId, String role, String content) =>
      _db.insertMessage(sessionId, role, content);

  Future<List<ChatMessage>> getMessagesForSession(int sessionId) =>
      _db.getMessagesForSession(sessionId);

  Future<String> getRelevantContext(String query) =>
      _db.getRelevantContext(query);

  Future<String> getRelevantContextForFiles(String query, List<int> fileIds) =>
      _db.getRelevantContextForFiles(query, fileIds);

  Stream<List<KnowledgeFile>> watchAllFiles() => _db.watchAllFiles();

  Future<List<String>> getAllMemoryTexts() => _db.getAllMemoryTexts();

  Future<int> addMemory(String content, {String? tags}) =>
      _db.addMemory(content, tags: tags);
}
