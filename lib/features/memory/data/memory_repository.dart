export '../../../core/database/database.dart' show KnowledgeFile, LongTermMemory;

import '../../../core/database/database.dart';

/// 长久记忆仓库 —— 封装长期记忆与知识文件访问
class MemoryRepository {
  final AppDatabase _db;

  MemoryRepository(this._db);

  Stream<List<LongTermMemory>> watchAllMemories() => _db.watchAllMemories();

  Future<int> addMemory(String content, {String? tags}) =>
      _db.addMemory(content, tags: tags);

  Future<int> updateMemory(int id, String newContent) =>
      _db.updateMemory(id, newContent);

  Future<int> deleteMemory(int id) => _db.deleteMemory(id);

  Stream<List<KnowledgeFile>> watchAllFiles() => _db.watchAllFiles();

  Future<int> addFile({
    required String name,
    required String localPath,
    required int size,
    required String extension,
  }) =>
      _db.addFile(
        name: name,
        localPath: localPath,
        size: size,
        extension: extension,
      );

  Future<void> processFileForRag(int fileId, String localPath) =>
      _db.processFileForRAG(fileId, localPath);

  Future<void> deleteFile(int id) => _db.deleteFile(id);

  Future<void> toggleFileActive(int id, bool isActive) =>
      _db.toggleFileActive(id, isActive);
}
