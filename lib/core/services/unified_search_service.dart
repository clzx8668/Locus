import 'package:drift/drift.dart';
import '../di/service_locator.dart';
import '../database/database.dart';
import '../vault/fts_index_service.dart';

class UnifiedSearchResult {
  final String title;
  final String snippet;
  final String? source;
  final String? filePath;
  final int? recordId;
  final DateTime updatedAt;

  UnifiedSearchResult({
    required this.title,
    required this.snippet,
    this.source,
    this.filePath,
    this.recordId,
    required this.updatedAt,
  });
}

class UnifiedSearchService {
  AppDatabase get db => getIt<AppDatabase>();
  FtsIndexService get ftsService => getIt<FtsIndexService>();

  Future<List<UnifiedSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final results = <UnifiedSearchResult>[];

    await Future.wait([
      _searchVault(query).then((r) => results.addAll(r)),
      _searchContacts(query).then((r) => results.addAll(r)),
      _searchActivities(query).then((r) => results.addAll(r)),
      _searchChatMessages(query).then((r) => results.addAll(r)),
    ]);

    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results.take(30).toList();
  }

  Future<List<UnifiedSearchResult>> _searchVault(String query) async {
    try {
      if (!ftsService.isInitialized) return [];
      final ftsResults = ftsService.search(query);
      return ftsResults.map((r) => UnifiedSearchResult(
        title: r['title'] as String? ?? 'Untitled',
        snippet: r['snippet'] as String? ?? '',
        source: 'vault',
        filePath: r['filePath'] as String?,
        updatedAt: DateTime.now(),
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<UnifiedSearchResult>> _searchContacts(String query) async {
    try {
      final contacts = await db.searchContacts(query);
      return contacts.map((c) {
        final buf = StringBuffer(c.name);
        if (c.company != null) buf.write('  ${c.company}');
        return UnifiedSearchResult(
          title: c.name,
          snippet: buf.toString(),
          source: 'contact',
          recordId: c.id,
          updatedAt: c.updatedAt,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<UnifiedSearchResult>> _searchActivities(String query) async {
    try {
      final results = await (db.select(db.activities)
            ..where((t) => t.content.like('%$query%'))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
          .get();
      return results.map((a) => UnifiedSearchResult(
        title: a.content.length > 80 ? '${a.content.substring(0, 80)}...' : a.content,
        snippet: 'Activity - ${a.type}',
        source: 'activity',
        recordId: a.id,
        updatedAt: a.createdAt,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<UnifiedSearchResult>> _searchChatMessages(String query) async {
    try {
      final messages = await (db.select(db.chatMessages)
            ..where((t) => t.content.like('%$query%'))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
          .get();

      final sessionIds = messages.map((m) => m.sessionId).toSet();
      final sessions = <int, String>{};
      for (final sid in sessionIds) {
        final s = await (db.select(db.chatSessions)..where((t) => t.id.equals(sid))).getSingleOrNull();
        if (s != null) sessions[sid] = s.title;
      }

      return messages.map((m) => UnifiedSearchResult(
        title: sessions[m.sessionId] ?? 'Chat',
        snippet: m.content.length > 100 ? '${m.content.substring(0, 100)}...' : m.content,
        source: 'chat',
        recordId: m.id,
        updatedAt: m.createdAt,
      )).toList();
    } catch (_) {
      return [];
    }
  }
}
