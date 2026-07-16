export '../../../../core/database/database.dart' show HubPayload, Tag;

import '../../../../core/database/database.dart';

/// 标签数据仓库 —— 封装对 Tags 表及关联表的操作
class TagRepository {
  final AppDatabase _db;

  TagRepository(this._db);

  Stream<List<Tag>> watchAll() => _db.watchAllTags();

  Future<List<Tag>> getAll() => _db.getAllTags();

  Future<int> getOrCreate(String name, {String color = '#FF6B6B'}) {
    return _db.getOrCreateTag(name);
  }

  Future<int> delete(int id) => _db.deleteTag(id);

  Stream<List<Tag>> watchForPayload(int payloadId) =>
      _db.watchTagsForPayload(payloadId);

  Stream<List<Tag>> watchForBlock(int blockId) =>
      _db.watchTagsForBlock(blockId);

  Future<void> addToPayload(int payloadId, int tagId) =>
      _db.addTagToPayload(payloadId, tagId);

  Future<void> removeFromPayload(int payloadId, int tagId) =>
      _db.removeTagFromPayload(payloadId, tagId);

  Future<void> addToBlock(int blockId, int tagId) =>
      _db.addTagToBlock(blockId, tagId);

  Future<void> removeFromBlock(int blockId, int tagId) =>
      _db.removeTagFromBlock(blockId, tagId);

  Future<List<Tag>> search(String query) => _db.searchTags(query);

  Stream<List<HubPayload>> watchPayloadsByTags(List<String> tagNames) =>
      _db.watchPayloadsByTags(tagNames);
}
