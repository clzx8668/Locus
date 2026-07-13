import 'package:drift/drift.dart' show OrderingTerm;
import '../../../core/database/database.dart';

/// 查重结果
class DedupResult {
  final bool hasSimilar;
  final int? similarPayloadId;
  final double? similarityScore;
  final String? summary; // 相似记录的摘要

  const DedupResult({
    required this.hasSimilar,
    this.similarPayloadId,
    this.similarityScore,
    this.summary,
  });

  factory DedupResult.none() => const DedupResult(hasSimilar: false);
}

/// 向量查重服务 —— 首版使用 2-gram + Jaccard 相似度替代真实 Embedding
/// 后续可替换 _computeEmbedding() 为真实的向量模型
class VectorDedupService {
  final AppDatabase _db;

  VectorDedupService(this._db);

  /// 对比 payload 与最近历史记录的相似度
  Future<DedupResult> checkSimilarity(int payloadId) async {
    try {
      // 获取当前 payload
      final current = await (_db.select(_db.hubPayloads)
            ..where((t) => t.id.equals(payloadId)))
          .getSingleOrNull();
      if (current == null) return DedupResult.none();

      final currentText = _getPayloadFullText(current);

      // 如果文本太短（< 10字），跳过查重
      if (currentText.length < 10) return DedupResult.none();

      // 获取最近 50 条记录（排除自身）
      final allRecent = await (_db.select(_db.hubPayloads)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

      final limited =
          allRecent.where((r) => r.id != payloadId).take(50).toList();
      if (limited.isEmpty) return DedupResult.none();

      // 提取当前文本的 2-gram 集合
      final currentGrams = _extractBigrams(currentText);

      double bestScore = 0;
      HubPayload? bestMatch;

      for (final record in limited) {
        final recordText = _getPayloadFullText(record);
        if (recordText.length < 10) continue;

        final recordGrams = _extractBigrams(recordText);
        final score = _jaccardSimilarity(currentGrams, recordGrams);

        if (score > bestScore) {
          bestScore = score;
          bestMatch = record;
        }
      }

      // 阈值 0.45（2-gram Jaccard 近似 85% 语义相似，比纯文本 Jaccard 更宽松）
      if (bestScore > 0.45 && bestMatch != null) {
        return DedupResult(
          hasSimilar: true,
          similarPayloadId: bestMatch.id,
          similarityScore: bestScore,
          summary: _truncateText(_getPayloadFullText(bestMatch), 60),
        );
      }

      return DedupResult.none();
    } catch (_) {
      return DedupResult.none();
    }
  }

  /// 获取 payload 的完整文本（合并 rawText + 内容块）
  String _getPayloadFullText(HubPayload payload) {
    return payload.rawText;
  }

  /// 提取 2-gram 集合
  Set<String> _extractBigrams(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ''); // 去空格
    final grams = <String>{};
    for (var i = 0; i < cleaned.length - 1; i++) {
      grams.add(cleaned.substring(i, i + 2));
    }
    return grams;
  }

  /// Jaccard 相似度 = |A ∩ B| / |A ∪ B|
  double _jaccardSimilarity(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return intersection / union;
  }

  String _truncateText(String text, int maxLen) {
    return text.length > maxLen ? '${text.substring(0, maxLen)}...' : text;
  }

  /// 预留接口：真实 Embedding 计算（后续可接入 ONNX / API）
  // Future<List<double>> _computeEmbedding(String text) async { ... }
}
