import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zvec/zvec.dart';

/// Result from a Zvec hybrid search.
class ZvecSearchResult {
  final String noteId;
  final int chunkIndex;
  final String content;
  final double score;

  ZvecSearchResult({
    required this.noteId,
    required this.chunkIndex,
    required this.content,
    required this.score,
  });
}

/// Lightweight wrapper around the Zvec in-process vector database.
///
/// Manages a single [Collection] (locus_notes) that stores text chunks
/// alongside their embedding vectors. Exposes a hybrid [multiSearch] method
/// combining ANN vector search and FTS full-text search via RRF fusion.
class ZvecService {
  /// The embedding dimension used by the configured LLM model.
  /// DeepSeek / OpenAI text-embedding-3-small → 1536.
  final int embeddingDim;

  Collection? _collection;
  bool _initialized = false;
  bool? _available;

  /// Whether the Zvec native library was successfully loaded and initialized.
  bool get isAvailable => _available == true;

  ZvecService({this.embeddingDim = 1536});

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialize the Zvec library and open/create the locus_notes collection.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      Zvec.initialize();
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/zvec_locus';

      // Try to open existing collection first
      try {
        _collection = Collection.open(dbPath);
        debugPrint('Zvec: opened existing locus_notes at $dbPath');
      } catch (_) {
        final schema = CollectionSchema(name: 'locus_notes', fields: [
          VectorSchema('embedding', embeddingDim,
              indexParams: HnswIndexParams(
                  m: 16, efConstruction: 200, metricType: MetricType.cosine)),
          FieldSchema(name: 'content', dataType: DataType.string),
          FieldSchema(name: 'note_id', dataType: DataType.string),
          FieldSchema(name: 'chunk_index', dataType: DataType.int64),
        ]);
        _collection = Collection.createAndOpen(dbPath, schema);

        // Create FTS index on content for hybrid keyword search
        _collection!.createIndex(
          'content',
          FtsIndexParams(tokenizerName: 'jieba', filters: ['lowercase']),
        );
        debugPrint('Zvec: created locus_notes at $dbPath');
      }

      _available = true;
      debugPrint('Zvec: ready (v${Zvec.version}, dim=$embeddingDim)');
    } catch (e) {
      _available = false;
      debugPrint('Zvec: unavailable — $e');
    }
  }

  /// Release all Zvec resources.
  void dispose() {
    try {
      _collection?.close();
    } catch (_) {}
    _collection = null;
    _initialized = false;
    _available = null;
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Insert a document chunk into the collection.
  ///
  /// [docId] is used as the primary key; should be globally unique (UUID).
  void insertDoc({
    required String docId,
    required String noteId,
    required int chunkIndex,
    required String content,
    required Float32List embedding,
  }) {
    if (!isAvailable) return;
    final doc = Doc(id: docId)
      ..setField('note_id', noteId)
      ..setField('content', content)
      ..setField('chunk_index', chunkIndex)
      ..setVector('embedding', embedding);
    try {
      _collection!.upsert([doc]);
    } catch (e) {
      debugPrint('Zvec insert error: $e');
    }
  }

  /// Delete all chunks belonging to a note.
  void deleteByNoteId(String noteId) {
    if (!isAvailable) return;
    try {
      _collection!.deleteByFilter("note_id == '$noteId'");
    } catch (e) {
      debugPrint('Zvec delete error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /// Hybrid search combining vector ANN + FTS full-text via RRF fusion.
  ///
  /// - [queryText]: raw user query for keyword matching.
  /// - [queryVector]: embedding of the query for semantic ANN search.
  /// - [topk]: max results to return after RRF fusion.
  List<ZvecSearchResult> multiSearch({
    required String queryText,
    required Float32List queryVector,
    int topk = 10,
  }) {
    if (!isAvailable) return [];

    try {
      final query = MultiQuery(
        topk: topk,
        subQueries: [
          // Sub-query 1: Dense vector ANN search
          SubQuery(
            fieldName: 'embedding',
            vector: queryVector,
            numCandidates: topk * 10,
            queryParams: HnswQueryParams(ef: 100),
          ),
          // Sub-query 2: FTS full-text keyword search
          SubQuery(
            fieldName: 'content',
            fts: FtsQuery(matchString: queryText),
            numCandidates: topk * 10,
          ),
        ],
        rerank: const RrfRerank(rankConstant: 60),
        includeVector: false,
        outputFields: ['content', 'note_id', 'chunk_index'],
      );

      final docs = _collection!.multiQuery(query);
      return docs.map((doc) {
        return ZvecSearchResult(
          noteId: doc.getString('note_id') ?? '',
          chunkIndex: doc.getInt64('chunk_index') ?? 0,
          content: doc.getString('content') ?? '',
          score: doc.score,
        );
      }).toList();
    } catch (e) {
      debugPrint('Zvec multiSearch error: $e');
      return [];
    }
  }

  /// Get collection statistics.
  String get stats {
    if (!isAvailable) return 'Zvec unavailable';
    try {
      final s = _collection!.stats;
      return 'docs=${s.docCount}, indexes=${s.indexCount}';
    } catch (e) {
      return 'error: $e';
    }
  }
}
