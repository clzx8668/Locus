import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../di/service_locator.dart';
import '../database/database.dart';
import '../zvec/zvec_service.dart';

class VectorSearchResult {
  final int vectorStorageId;
  final String content;
  final double similarity;
  final int sourceFileId;
  VectorSearchResult({required this.vectorStorageId, required this.content, required this.similarity, required this.sourceFileId});
}

class EmbeddingService {
  final Dio _dio = Dio();
  AppDatabase get db => getIt<AppDatabase>();
  ZvecService get _zs => getIt<ZvecService>();

  Future<List<double>?> getEmbedding(String text) async {
    final apiKey = (dotenv.env['LLM_API_KEY'] ?? '').trim();
    var baseUrl = (dotenv.env['LLM_BASE_URL'] ?? 'https://api.deepseek.com/v1').trim();
    if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    if (apiKey.isEmpty) return null;
    try {
      final response = await _dio.post('$baseUrl/embeddings', options: Options(headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'}), data: {'model': dotenv.env['LLM_MODEL_NAME'] ?? 'deepseek-chat', 'input': text});
      final data = response.data['data'];
      if (data != null && data is List && data.isNotEmpty) {
        final embedding = data[0]['embedding'];
        if (embedding is List) return embedding.cast<double>().map((e) => (e as num).toDouble()).toList();
      }
      return null;
    } catch (e) { debugPrint('Embedding API failed: $e'); return null; }
  }

  Future<void> embedAndStore({required int sourceFileId, required String content}) async {
    final v = await getEmbedding(content); if (v == null) return;
    await db.storeVector(sourceFileId, content, jsonEncode(v));
  }

  Future<void> embedChunks(int sourceFileId, List<String> chunks) async { for (final c in chunks) {
    await embedAndStore(sourceFileId: sourceFileId, content: c);
  } }

  Future<List<VectorSearchResult>> search({required String query, int limit = 5, double minSimilarity = 0.3}) async {
    // Prefer Zvec hybrid search (local, sub-millisecond)
    final qv = await getEmbedding(query);
    if (qv == null) return [];

    if (_zs.isAvailable) {
      try {
        final zResults = _zs.multiSearch(
          queryText: query,
          queryVector: Float32List.fromList(qv),
          topk: limit,
        );
        return zResults.map((z) => VectorSearchResult(
          vectorStorageId: 0, // Zvec results don't have VS id
          content: z.content,
          similarity: z.score,
          sourceFileId: 0,
        )).toList();
      } catch (e) {
        debugPrint('Zvec search failed, falling back to brute-force: $e');
      }
    }

    // Fallback: brute-force cosine similarity over VectorStorage table
    return _bruteForceSearch(queryEmbedding: qv, limit: limit, minSimilarity: minSimilarity);
  }

  Future<List<VectorSearchResult>> _bruteForceSearch({
    required List<double> queryEmbedding,
    int limit = 5,
    double minSimilarity = 0.3,
  }) async {
    final af = await (db.select(db.knowledgeFiles)..where((t) => t.isActive.equals(true))).get();
    if (af.isEmpty) return [];
    final ids = af.map((f) => f.id).toList();
    final all = await db.getAllVectorsForFiles(ids);
    final results = <VectorSearchResult>[];
    for (final row in all) {
      final ej = row['embedding'] as String?; if (ej == null || ej.isEmpty) continue;
      try {
        final sv = (jsonDecode(ej) as List).cast<double>();
        final sim = _cos(queryEmbedding, sv);
        if (sim >= minSimilarity) results.add(VectorSearchResult(vectorStorageId: row['id'] as int, content: row['content'] as String, similarity: sim, sourceFileId: row['source_file_id'] as int));
      } catch (_) {}
    }
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results.take(limit).toList();
  }

  double _cos(List<double> a, List<double> b) {
    double dot = 0, na = 0, nb = 0;
    for (int i = 0; i < a.length; i++) { dot += a[i] * b[i]; na += a[i] * a[i]; nb += b[i] * b[i]; }
    if (na == 0 || nb == 0) return 0;
    return dot / (sqrt(na) * sqrt(nb));
  }
}
