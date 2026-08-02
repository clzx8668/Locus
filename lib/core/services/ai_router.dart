import 'package:flutter/foundation.dart';

import '../di/service_locator.dart';
import '../services/embedding_service.dart';
import '../services/text_to_sql_service.dart';
import '../services/unified_search_service.dart';
import '../zvec/zvec_service.dart';

/// Intent classification result.
enum QueryIntent {
  /// Fuzzy semantic search — use Zvec / vector search.
  semantic,

  /// Precise structured query — use Text-to-SQL.
  structured,

  /// Mix of both — run concurrently and merge.
  mixed,
}

/// Unified result from any search backend.
class RouterResult {
  final String source; // 'zvec', 'sql', 'fts', 'unified'
  final String title;
  final String snippet;
  final Map<String, dynamic>? raw;
  final double? score;

  RouterResult({
    required this.source,
    required this.title,
    required this.snippet,
    this.raw,
    this.score,
  });
}

/// AI Router — lightweight intent classification layer.
///
/// Analyzes the user's natural language query and dispatches it to
/// the most appropriate search backend:
///
/// - **Semantic class** → Zvec hybrid search (vector + FTS)
/// - **Structured class** → Text-to-SQL engine
/// - **Mixed class** → Both backends concurrently, results merged
///
/// Uses simple keyword heuristics for zero-latency classification.
/// Complex queries can optionally fall through to the LLM.
class AiRouter {
  EmbeddingService get _es => getIt<EmbeddingService>();
  TextToSqlService get _sql => getIt<TextToSqlService>();
  UnifiedSearchService get _us => getIt<UnifiedSearchService>();
  ZvecService get _zs => getIt<ZvecService>();

  // ---------------------------------------------------------------------------
  // Intent Classification (keyword-based, zero latency)
  // ---------------------------------------------------------------------------

  /// Structured query keywords in Chinese and English.
  static const _structuredKeywords = [
    // Aggregation
    'sum', 'avg', 'count', 'total', 'average', 'max', 'min',
    '总和', '平均', '总计', '一共', '多少', '几个', '多少次',
    '最大值', '最小值', '总额', '统计',

    // Entity references
    '订单', '合同', '报价', '金额', '价格', '产品', '客户',
    '联系人', '公司', '电话', '邮箱', '到期', '截止',
    'order', 'contract', 'deal', 'price', 'product', 'customer',
    'contact', 'company', 'phone', 'email', 'due',

    // Precise lookup
    '查找', '查询', '列表', 'list', 'find', 'search',
    '属于', 'belongs', '谁的', '哪个',

    // Time-based
    '今天', '昨天', '本周', '本月', '今年',
    'today', 'yesterday', 'this week', 'this month',

    // Comparison
    '大于', '小于', '超过', '低于', '高于', '<=', '>=',
    'greater than', 'less than',
  ];

  /// Semantic query keywords.
  static const _semanticKeywords = [
    '总结', '概括', '分析', '解释', '说明', '描述', '意义',
    '观点', '想法', '建议', '推荐', '讨论', '回顾', '评估',
    'summarize', 'explain', 'analyze', 'describe', 'review',
    'opinion', 'suggestion', 'recommendation', 'meaning',

    // Knowledge-related
    '笔记', '文档', '会议', '纪要', '记录', '知识',
    'note', 'document', 'meeting', 'knowledge', 'memo',

    // Open-ended
    '怎么', '如何', '为什么', '什么是',
    'how', 'why', 'what is',
  ];

  /// Classify the user's query intent.
  ///
  /// Returns [QueryIntent.semantic] if the query looks like a fuzzy
  /// semantic search, [QueryIntent.structured] if it asks for precise
  /// data, or [QueryIntent.mixed] if both signals are present.
  QueryIntent classify(String query) {
    final lower = query.toLowerCase();
    var structuredScore = 0;
    var semanticScore = 0;

    for (final kw in _structuredKeywords) {
      if (lower.contains(kw.toLowerCase())) structuredScore++;
    }
    for (final kw in _semanticKeywords) {
      if (lower.contains(kw.toLowerCase())) semanticScore++;
    }

    // Boost for Chinese name patterns or numeric queries
    if (RegExp(r'(?:张三|李四|王五|[张李王陈刘赵吴周]总|[张李王陈刘赵吴周]经理)').hasMatch(query)) {
      structuredScore += 2;
    }
    if (RegExp(r'\d+').hasMatch(query)) {
      structuredScore++;
    }

    if (structuredScore > semanticScore) return QueryIntent.structured;
    if (semanticScore > structuredScore) return QueryIntent.semantic;
    if (structuredScore > 0 && semanticScore > 0) return QueryIntent.mixed;

    // Default to semantic for vague/general queries
    return QueryIntent.semantic;
  }

  // ---------------------------------------------------------------------------
  // Dispatch
  // ---------------------------------------------------------------------------

  /// Route the query and return unified results.
  Future<List<RouterResult>> route(String query) async {
    final intent = classify(query);
    debugPrint('AiRouter: intent=$intent query="$query"');

    switch (intent) {
      case QueryIntent.structured:
        return await _runStructured(query);

      case QueryIntent.semantic:
        return await _runSemantic(query);

      case QueryIntent.mixed:
        final results = await Future.wait([
          _runStructured(query),
          _runSemantic(query),
        ]);
        return [...results[0], ...results[1]];
    }
  }

  // ---------------------------------------------------------------------------
  // Structured path: Text-to-SQL
  // ---------------------------------------------------------------------------

  Future<List<RouterResult>> _runStructured(String query) async {
    try {
      final result = await _sql.query(query);
      if (result.isSuccess) {
        return result.rows.map((row) {
          final title = row.values
              .whereType<String>()
              .firstWhere((_) => true, orElse: () => 'Result');
          return RouterResult(
            source: 'sql',
            title: title.toString(),
            snippet: result.summary,
            raw: row,
          );
        }).toList();
      }
      if (result.error != null) {
        return [
          RouterResult(
            source: 'sql',
            title: 'Query Error',
            snippet: result.error!,
          ),
        ];
      }
      return [];
    } catch (e) {
      return [
        RouterResult(
          source: 'sql',
          title: 'Error',
          snippet: 'Structured search failed: $e',
        ),
      ];
    }
  }

  // ---------------------------------------------------------------------------
  // Semantic path: Zvec hybrid + Unified FTS
  // ---------------------------------------------------------------------------

  Future<List<RouterResult>> _runSemantic(String query) async {
    final results = <RouterResult>[];

    // 1. Zvec hybrid search (vector + FTS)
    if (_zs.isAvailable) {
      try {
        final qv = await _es.getEmbedding(query);
        if (qv != null) {
          final zResults = _zs.multiSearch(
            queryText: query,
            queryVector: Float32List.fromList(qv),
            topk: 5,
          );
          for (final z in zResults) {
            results.add(RouterResult(
              source: 'zvec',
              title: z.content.length > 80
                  ? '${z.content.substring(0, 80)}...'
                  : z.content,
              snippet: 'Zvec match (score: ${z.score.toStringAsFixed(3)})',
              score: z.score,
              raw: {'note_id': z.noteId, 'chunk_index': z.chunkIndex},
            ));
          }
        }
      } catch (e) {
        debugPrint('AiRouter Zvec search failed: $e');
      }
    }

    // 2. Unified search fallback (SQLite FTS + LIKE)
    try {
      final ftsResults = await _us.search(query);
      for (final r in ftsResults) {
        results.add(RouterResult(
          source: r.source ?? 'unified',
          title: r.title,
          snippet: r.snippet,
          raw: {'record_id': r.recordId, 'file_path': r.filePath},
        ));
      }
    } catch (e) {
      debugPrint('AiRouter unified search failed: $e');
    }

    return results;
  }
}
