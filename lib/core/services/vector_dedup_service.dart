import 'dart:typed_data';

import '../../features/idea_stream/data/idea_repository.dart';
import 'vector_service.dart';

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

class VectorDedupService {
  static const double duplicateThreshold = 0.85;

  VectorDedupService(this._ideaRepository, this._vectorService);

  final IdeaRepository _ideaRepository;
  final VectorService _vectorService;

  /// 基于 Zvec 的向量召回结果做查重
  Future<DedupResult> checkSimilarity(
    int payloadId, {
    required Float32List embedding,
    String? currentUuid,
  }) async {
    try {
      final current = await _ideaRepository.getById(payloadId);
      if (current == null) return DedupResult.none();
      final currentText = current.rawText.trim();

      // 如果文本太短（< 10字），跳过查重
      if (currentText.length < 10) return DedupResult.none();

      final uuid = currentUuid ?? await _ideaRepository.getUuidById(payloadId);
      final matches = await _vectorService.queryNearest(
        embedding,
        topK: 5,
        excludeUuid: uuid,
      );
      if (matches.isEmpty) return DedupResult.none();

      final bestMatch = matches.first;
      final payloads = await _ideaRepository.getByUuids([bestMatch.uuid]);
      if (payloads.isEmpty) return DedupResult.none();

      if (bestMatch.score >= duplicateThreshold) {
        return DedupResult(
          hasSimilar: true,
          similarPayloadId: payloads.first.id,
          similarityScore: bestMatch.score,
          summary: _truncateText(payloads.first.rawText, 60),
        );
      }

      return DedupResult.none();
    } catch (_) {
      return DedupResult.none();
    }
  }

  /// 基于本地 FTS 全文检索的查重（纯本地，不依赖嵌入向量）
  Future<DedupResult> checkLocalSimilarity(
    int payloadId,
    String rawText,
    String uuid,
  ) async {
    try {
      if (rawText.trim().length < 10) return DedupResult.none();

      // 取前 100 字作为 FTS 查询关键词
      final keyword = rawText.length > 100
          ? rawText.substring(0, 100)
          : rawText;

      final matches = await _vectorService.queryFts(
        keyword,
        topK: 5,
        excludeUuid: uuid,
      );
      if (matches.isEmpty) return DedupResult.none();

      final bestMatch = matches.first;
      final payloads = await _ideaRepository.getByUuids([bestMatch.uuid]);
      if (payloads.isEmpty) return DedupResult.none();

      if (bestMatch.score >= duplicateThreshold) {
        return DedupResult(
          hasSimilar: true,
          similarPayloadId: payloads.first.id,
          similarityScore: bestMatch.score,
          summary: _truncateText(payloads.first.rawText, 60),
        );
      }

      return DedupResult.none();
    } catch (_) {
      return DedupResult.none();
    }
  }

  String _truncateText(String text, int maxLen) {
    return text.length > maxLen ? '${text.substring(0, maxLen)}...' : text;
  }
}
