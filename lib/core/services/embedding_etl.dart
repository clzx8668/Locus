import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../di/service_locator.dart';
import '../database/database.dart';
import '../services/embedding_service.dart';
import '../zvec/zvec_service.dart';

const _uuid = Uuid();

/// ETL pipeline that extracts text from the SQLCipher database, generates
/// embeddings, and loads them into the Zvec vector database.
///
/// Triggered manually or after data sync completes. Tracks last-processed
/// IDs via AppConfig to support incremental indexing.
class EmbeddingETL {
  AppDatabase get _db => getIt<AppDatabase>();
  EmbeddingService get _es => getIt<EmbeddingService>();
  ZvecService get _zs => getIt<ZvecService>();

  // ---------------------------------------------------------------------------
  // Full re-index
  // ---------------------------------------------------------------------------

  /// Drop all Zvec data and re-index everything from scratch.
  Future<void> rebuildAll() async {
    if (!_zs.isAvailable) {
      debugPrint('ETL: Zvec unavailable, skipping rebuildAll');
      return;
    }

    debugPrint('ETL: starting full rebuild...');
    var indexed = 0;

    // Process VectorStorage entries
    final vsRows = await _db.getAllVectorsForFiles(
      await _allActiveFileIds(),
    );
    for (final row in vsRows) {
      final embedded = await _ensureEmbedding(row);
      if (embedded == null) continue;
      final noteId = 'kf_${row['source_file_id']}';
      _zs.insertDoc(
        docId: _uuid.v4(),
        noteId: noteId,
        chunkIndex: row['id'] as int,
        content: row['content'] as String,
        embedding: embedded,
      );
      indexed++;
    }

    // Process ChatMessages
    final msgs = await (_db.select(_db.chatMessages)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    for (final msg in msgs) {
      final embedded = await _es.getEmbedding(msg.content);
      if (embedded == null) continue;
      _zs.insertDoc(
        docId: _uuid.v4(),
        noteId: 'msg_${msg.id}',
        chunkIndex: 0,
        content: msg.content,
        embedding: Float32List.fromList(embedded),
      );
      indexed++;
    }

    debugPrint('ETL: full rebuild done — $indexed docs indexed');
  }

  // ---------------------------------------------------------------------------
  // Incremental indexing
  // ---------------------------------------------------------------------------

  /// Index only new content since the last run.
  Future<int> syncIncremental() async {
    if (!_zs.isAvailable) return 0;

    var count = 0;

    // New VectorStorage entries
    final lastVsId =
        int.tryParse(await _db.getConfig('zvec_last_vs_id') ?? '') ?? 0;
    final vsQuery = _db.customSelect(
      'SELECT * FROM vector_storage WHERE id > ?',
      variables: [Variable.withInt(lastVsId)],
      readsFrom: {_db.vectorStorage},
    );
    final newVs = await vsQuery.get();
    final activeFileIds = await _allActiveFileIds();
    for (final row in newVs) {
      final sourceFileId = row.read<int>('source_file_id');
      if (!activeFileIds.contains(sourceFileId)) continue;
      final content = row.read<String>('content');
      final embedded = await _es.getEmbedding(content);
      if (embedded == null) continue;
      _zs.insertDoc(
        docId: _uuid.v4(),
        noteId: 'kf_$sourceFileId',
        chunkIndex: row.read<int>('id'),
        content: content,
        embedding: Float32List.fromList(embedded),
      );
      count++;
      await _db.setConfig('zvec_last_vs_id', row.read<int>('id').toString());
    }

    // New ChatMessages
    final lastMsgId =
        int.tryParse(await _db.getConfig('zvec_last_msg_id') ?? '') ?? 0;
    final msgQuery = _db.customSelect(
      'SELECT * FROM chat_messages WHERE id > ? AND is_deleted = 0',
      variables: [Variable.withInt(lastMsgId)],
      readsFrom: {_db.chatMessages},
    );
    final newMsgs = await msgQuery.get();
    for (final row in newMsgs) {
      final content = row.read<String>('content');
      final embedded = await _es.getEmbedding(content);
      if (embedded == null) continue;
      _zs.insertDoc(
        docId: _uuid.v4(),
        noteId: 'msg_${row.read<int>('id')}',
        chunkIndex: 0,
        content: content,
        embedding: Float32List.fromList(embedded),
      );
      count++;
      await _db.setConfig('zvec_last_msg_id', row.read<int>('id').toString());
    }

    if (count > 0) debugPrint('ETL: incrementally indexed $count docs');
    return count;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<List<int>> _allActiveFileIds() async {
    final query = _db.customSelect(
      'SELECT id FROM knowledge_files WHERE is_active = 1 AND is_deleted = 0',
      readsFrom: {_db.knowledgeFiles},
    );
    final rows = await query.get();
    return rows.map((r) => r.read<int>('id')).toList();
  }

  Future<Float32List?> _ensureEmbedding(Map<String, dynamic> row) async {
    final ej = row['embedding'] as String?;
    if (ej != null && ej.isNotEmpty) {
      try {
        return Float32List.fromList(
            (jsonDecode(ej) as List).cast<double>().map((d) => d.toDouble()).toList());
      } catch (_) {}
    }
    // Regenerate embedding if missing
    final embedded = await _es.getEmbedding(row['content'] as String);
    return embedded != null ? Float32List.fromList(embedded) : null;
  }
}
