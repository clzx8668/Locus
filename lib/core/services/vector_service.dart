import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zvec/zvec.dart';

/// Zvec 向量服务 —— 仅维护 [uuid <-> embedding] 的脱敏索引
class VectorMatch {
  const VectorMatch({required this.uuid, required this.score});

  final String uuid;
  final double score;
}

/// Zvec 向量服务 —— 仅维护 [uuid <-> embedding] 的脱敏索引
class VectorService {
  static const int embeddingDimension = 1536;
  static const String _collectionName = 'hub_payload_vectors';
  static const int _optimizeThreshold = 24;

  Collection? _collection;
  bool _initialized = false;
  bool _available = false;
  int _pendingOptimizeWrites = 0;

  /// Zvec 是否已成功初始化并可用
  bool get isAvailable => _available;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final vectorDir = Directory(p.join(docsDir.path, 'vector_index'));
      if (!await vectorDir.exists()) {
        await vectorDir.create(recursive: true);
      }
      final vectorPath = p.join(vectorDir.path, _collectionName);

      Zvec.initialize();
      final schema = CollectionSchema(
        name: _collectionName,
        fields: [
          VectorSchema(
            'embedding',
            embeddingDimension,
            indexParams: HnswIndexParams(),
          ),
        ],
      );

      try {
        _collection = Collection.createAndOpen(vectorPath, schema);
        _available = true;
        debugPrint('[VectorService] Zvec 初始化成功: $vectorPath');
      } finally {
        schema.destroy();
      }
    } catch (e, st) {
      debugPrint('[VectorService] Zvec 初始化失败，向量功能不可用: $e\n$st');
      _available = false;
    }
  }

  Future<void> upsertEmbedding({
    required String uuid,
    required Float32List embedding,
  }) async {
    await init();
    if (!_available || uuid.isEmpty) return;

    final doc = Doc(id: uuid)..setVector('embedding', embedding);
    try {
      final result = _collection!.upsert([doc]);
      if (!result.isAllSuccess) {
        throw StateError('Zvec 写入失败: $result');
      }
      _pendingOptimizeWrites += result.successCount;
      if (_pendingOptimizeWrites >= _optimizeThreshold) {
        _collection!.optimize();
        _pendingOptimizeWrites = 0;
      }
    } finally {
      doc.destroy();
    }
  }

  Future<void> deleteEmbedding(String uuid) async {
    await init();
    if (!_available || uuid.isEmpty) return;
    final result = _collection!.delete([uuid]);
    if (!result.isAllSuccess && result.errorCount > 0) {
      throw StateError('Zvec 删除失败: $result');
    }
  }

  Future<List<VectorMatch>> queryNearest(
    Float32List embedding, {
    int topK = 8,
    String? excludeUuid,
  }) async {
    await init();
    if (!_available) return [];
    if (_pendingOptimizeWrites > 0) {
      _collection!.optimize();
      _pendingOptimizeWrites = 0;
    }

    final query = VectorQuery(
      fieldName: 'embedding',
      vector: embedding,
      topk: topK + (excludeUuid == null ? 0 : 1),
    );
    try {
      final results = _collection!.query(query);
      return results
          .where((doc) => doc.pk != null)
          .map((doc) => VectorMatch(uuid: doc.pk!, score: doc.score))
          .where((match) => match.uuid.isNotEmpty && match.uuid != excludeUuid)
          .take(topK)
          .toList(growable: false);
    } finally {
      query.destroy();
    }
  }

  Future<bool> contains(String uuid) async {
    await init();
    if (!_available || uuid.isEmpty) return false;
    final fetched = _collection!.fetch([uuid]);
    return fetched.any((doc) => doc.pk == uuid);
  }

  /// 将文本通过 jieba 分词写入 Zvec FTS 索引（纯本地，无网络依赖）
  Future<void> upsertFtsDoc({
    required String uuid,
    required String content,
  }) async {
    await init();
    if (!_available || uuid.isEmpty || content.trim().isEmpty) return;

    final doc = Doc(id: uuid)..setField('fts_content', content);
    try {
      final result = _collection!.upsert([doc]);
      if (!result.isAllSuccess) {
        throw StateError('Zvec FTS 写入失败: $result');
      }
      _pendingOptimizeWrites += result.successCount;
      if (_pendingOptimizeWrites >= _optimizeThreshold) {
        _collection!.optimize();
        _pendingOptimizeWrites = 0;
      }
    } finally {
      doc.destroy();
    }
  }

  /// 基于 jieba 分词的本地全文检索，返回匹配的 UUID 列表
  Future<List<VectorMatch>> queryFts(
    String keyword, {
    int topK = 5,
    String? excludeUuid,
  }) async {
    await init();
    if (!_available || keyword.trim().isEmpty) return [];
    if (_pendingOptimizeWrites > 0) {
      _collection!.optimize();
      _pendingOptimizeWrites = 0;
    }

    final ftsQuery = FtsQuery(queryString: keyword);
    final subQuery = SubQuery(
      fieldName: 'fts_content',
      fts: ftsQuery,
      numCandidates: topK + (excludeUuid == null ? 0 : 1),
    );
    final multiQuery = MultiQuery(
      subQueries: [subQuery],
      topk: topK + (excludeUuid == null ? 0 : 1),
    );
    try {
      final results = _collection!.multiQuery(multiQuery);
      return results
          .where((doc) => doc.pk != null)
          .map((doc) => VectorMatch(uuid: doc.pk!, score: doc.score))
          .where((match) => match.uuid.isNotEmpty && match.uuid != excludeUuid)
          .take(topK)
          .toList(growable: false);
    } finally {
      ftsQuery.destroy();
      subQuery.destroy();
      multiQuery.destroy();
    }
  }

  void dispose() {
    if (_pendingOptimizeWrites > 0 && _available) {
      _collection?.optimize();
      _pendingOptimizeWrites = 0;
    }
    _collection?.close();
    _collection = null;
    if (_available) {
      Zvec.shutdown();
      _available = false;
    }
    _initialized = false;
  }
}
