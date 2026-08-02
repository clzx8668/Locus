import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../di/service_locator.dart';
import '../database/database.dart';

/// Result from a Text-to-SQL execution.
class SqlQueryResult {
  final String naturalQuery;
  final String? generatedSql;
  final List<Map<String, dynamic>> rows;
  final List<String> columns;
  final String? error;

  SqlQueryResult({
    required this.naturalQuery,
    this.generatedSql,
    this.rows = const [],
    this.columns = const [],
    this.error,
  });

  bool get isSuccess => error == null && rows.isNotEmpty;
  bool get isEmpty => rows.isEmpty;

  /// Human-readable summary of the result.
  String get summary {
    if (error != null) return 'Query failed: $error';
    if (rows.isEmpty) return 'No results found.';
    if (rows.length == 1) {
      final row = rows.first;
      final parts = row.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      return parts;
    }
    return 'Found ${rows.length} results.';
  }
}

/// Text-to-SQL engine for structured data queries.
///
/// Injects PocketBase table schema into the LLM prompt, generates
/// SQLite-compatible SELECT statements, and executes them safely
/// against the local Drift database.
///
/// Only SELECT queries are allowed — any other statement type
/// (INSERT, UPDATE, DELETE, DROP, etc.) is rejected.
class TextToSqlService {
  final Dio _dio = Dio();
  AppDatabase get db => getIt<AppDatabase>();

  // ---------------------------------------------------------------------------
  // Schema Injection
  // ---------------------------------------------------------------------------

  /// Complete database schema as a text prompt for the LLM.
  static const _schemaPrompt = '''
You are a SQL query generator for a local SQLite database. Generate ONLY a SELECT statement.

=== DATABASE SCHEMA ===

-- Contacts (CRM contacts/people)
CREATE TABLE contacts (
  id INTEGER PRIMARY KEY,
  sync_uuid TEXT,
  sync_status INTEGER,
  name TEXT NOT NULL,
  aliases TEXT,
  company TEXT,
  role TEXT,
  phone TEXT,
  email TEXT,
  tags TEXT,
  notes TEXT,
  avatar_path TEXT,
  is_deleted INTEGER DEFAULT 0,
  updated_at TEXT
);

-- Deals (sales opportunities)
CREATE TABLE deals (
  id INTEGER PRIMARY KEY,
  sync_uuid TEXT,
  sync_status INTEGER,
  contact_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  stage TEXT,
  value REAL,
  probability REAL,
  expected_close_date TEXT,
  notes TEXT,
  is_deleted INTEGER DEFAULT 0,
  updated_at TEXT
);

-- Activities (contact interactions)
CREATE TABLE activities (
  id INTEGER PRIMARY KEY,
  sync_uuid TEXT,
  sync_status INTEGER,
  contact_id INTEGER NOT NULL,
  deal_id INTEGER,
  type TEXT NOT NULL,
  content TEXT NOT NULL,
  media_paths TEXT,
  is_deleted INTEGER DEFAULT 0,
  updated_at TEXT
);

-- Tasks (to-dos with timeline)
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY,
  sync_uuid TEXT,
  sync_status INTEGER,
  title TEXT NOT NULL,
  contact_id INTEGER,
  deal_id INTEGER,
  due_date TEXT,
  priority INTEGER DEFAULT 0,
  status TEXT,
  source_text TEXT,
  is_deleted INTEGER DEFAULT 0,
  updated_at TEXT
);

-- Products
CREATE TABLE products (
  id INTEGER PRIMARY KEY,
  sync_uuid TEXT,
  sync_status INTEGER,
  name TEXT NOT NULL,
  category TEXT,
  specs TEXT,
  unit_price REAL,
  notes TEXT,
  is_deleted INTEGER DEFAULT 0,
  updated_at TEXT
);

-- HubPayloads (quick capture inbox)
CREATE TABLE hub_payloads (
  id INTEGER PRIMARY KEY,
  sync_uuid TEXT,
  sync_status INTEGER,
  raw_text TEXT NOT NULL,
  media_paths TEXT,
  intent_tag TEXT,
  is_deleted INTEGER DEFAULT 0,
  updated_at TEXT
);

-- Chat Sessions
CREATE TABLE chat_sessions (
  id INTEGER PRIMARY KEY,
  sync_uuid TEXT,
  sync_status INTEGER,
  title TEXT NOT NULL,
  is_deleted INTEGER DEFAULT 0,
  updated_at TEXT
);

-- Chat Messages
CREATE TABLE chat_messages (
  id INTEGER PRIMARY KEY,
  sync_uuid TEXT,
  sync_status INTEGER,
  session_id INTEGER NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  is_deleted INTEGER DEFAULT 0,
  updated_at TEXT
);

-- Long-Term Memories
CREATE TABLE long_term_memories (
  id INTEGER PRIMARY KEY,
  sync_uuid TEXT,
  sync_status INTEGER,
  content TEXT NOT NULL,
  tags TEXT,
  is_deleted INTEGER DEFAULT 0,
  updated_at TEXT
);

-- Knowledge Files
CREATE TABLE knowledge_files (
  id INTEGER PRIMARY KEY,
  sync_uuid TEXT,
  sync_status INTEGER,
  name TEXT NOT NULL,
  local_path TEXT NOT NULL,
  size INTEGER NOT NULL,
  extension TEXT NOT NULL,
  is_active INTEGER DEFAULT 1,
  is_deleted INTEGER DEFAULT 0,
  updated_at TEXT
);

=== RULES ===
1. Output ONLY the raw SQL SELECT statement, no markdown, no explanation.
2. Always filter is_deleted = 0 or is_deleted = false unless user explicitly asks for deleted items.
3. Use LIKE for fuzzy name matching, LOWER() for case-insensitive comparison.
4. For dates, use date() or strftime() SQLite functions. Today is CURRENT_DATE.
5. For amounts, use SUM(), AVG(), COUNT() as needed.
6. JOIN on contact_id when combining contacts with deals/activities.
7. Limit results to 50 rows unless a specific count is requested.
8. If unsure, generate a broad SELECT and let the user refine.
''';

  // ---------------------------------------------------------------------------
  // Generate + Execute
  // ---------------------------------------------------------------------------

  /// Generate SQL from a natural language query and execute it.
  Future<SqlQueryResult> query(String naturalQuery) async {
    final apiKey = (dotenv.env['LLM_API_KEY'] ?? '').trim();
    final baseUrl =
        (dotenv.env['LLM_BASE_URL'] ?? 'https://api.deepseek.com/v1').trim();

    if (apiKey.isEmpty) {
      return SqlQueryResult(
        naturalQuery: naturalQuery,
        error: 'LLM API key not configured',
      );
    }

    final url =
        '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}/chat/completions';

    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
        ),
        data: {
          'model': dotenv.env['LLM_MODEL_NAME'] ?? 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': _schemaPrompt},
            {'role': 'user', 'content': naturalQuery},
          ],
          'temperature': 0.0,
          'max_tokens': 300,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      final sql = _cleanSql(content);
      debugPrint('TextToSQL: "$naturalQuery" → $sql');

      if (!_isSafe(sql)) {
        return SqlQueryResult(
          naturalQuery: naturalQuery,
          generatedSql: sql,
          error: 'Generated SQL is not a safe SELECT statement',
        );
      }

      return await _execute(sql, naturalQuery);
    } catch (e) {
      debugPrint('TextToSQL error: $e');
      return SqlQueryResult(
        naturalQuery: naturalQuery,
        error: 'Failed to generate or execute SQL: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Safety
  // ---------------------------------------------------------------------------

  /// Strip markdown fences and whitespace.
  String _cleanSql(String raw) {
    return raw
        .replaceAll(RegExp(r'```sql\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim()
        .replaceAll(RegExp(r';+$'), '');
  }

  /// Only allow SELECT. Reject INSERT/UPDATE/DELETE/DROP/ALTER/CREATE/PRAGMA.
  bool _isSafe(String sql) {
    final upper = sql.trim().toUpperCase();
    final dangerous = [
      'INSERT', 'UPDATE', 'DELETE', 'DROP', 'ALTER',
      'CREATE', 'PRAGMA', 'ATTACH', 'DETACH', 'REPLACE',
      'VACUUM', 'REINDEX',
    ];
    for (final keyword in dangerous) {
      if (upper.startsWith(keyword) || upper.contains(';$keyword')) {
        return false;
      }
    }
    return upper.startsWith('SELECT');
  }

  // ---------------------------------------------------------------------------
  // Execution
  // ---------------------------------------------------------------------------

  Future<SqlQueryResult> _execute(String sql, String naturalQuery) async {
    try {
      final result = await db.customSelect(sql).get();

      if (result.isEmpty) {
        return SqlQueryResult(
          naturalQuery: naturalQuery,
          generatedSql: sql,
        );
      }

      // Extract column names from first row
      final columns = <String>[];
      final rows = <Map<String, dynamic>>[];

      for (final row in result) {
        final map = <String, dynamic>{};
        for (final key in row.data.keys) {
          if (columns.isEmpty) columns.add(key);
          map[key] = row.data[key];
        }
        rows.add(map);
      }

      return SqlQueryResult(
        naturalQuery: naturalQuery,
        generatedSql: sql,
        columns: columns,
        rows: rows,
      );
    } catch (e) {
      debugPrint('SQL execution error: $e');
      return SqlQueryResult(
        naturalQuery: naturalQuery,
        generatedSql: sql,
        error: 'SQL execution failed: $e',
      );
    }
  }
}
