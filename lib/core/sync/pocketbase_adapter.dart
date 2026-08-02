import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

/// Exception thrown when PocketBase operations fail.
class PocketBaseException implements Exception {
  final String message;
  final int? statusCode;
  PocketBaseException(this.message, {this.statusCode});
  @override
  String toString() => 'PocketBaseException: $message (status: $statusCode)';
}

/// PocketBase 同步适配器（纯 Dio 实现）
///
/// 使用 Dio 直接调用 PocketBase REST API，绕过 PocketBase Dart SDK
/// 内部 HTTP 客户端在 Android 上的路由问题。
///
/// API 参考: https://pocketbase.io/docs/api-records/
class PocketBaseAdapter {
  final String serverUrl;
  final Dio _dio;
  String? _token;

  bool get isAuthenticated => _token != null;

  /// Required field definitions for each sync table (PocketBase schema).
  /// Type values: text, number, bool, date
  /// Fields common to all sync tables.
  static const _commonFields = [
    {'name': '_source_id', 'type': 'number'},
    {'name': 'sync_status', 'type': 'number'},
    {'name': 'sync_uuid', 'type': 'text'},
    {'name': 'is_deleted', 'type': 'bool'},
    {'name': 'created_at', 'type': 'date'},
    {'name': 'updated_at', 'type': 'date'},
  ];

  static const Map<String, List<Map<String, String>>> _schemaFields = {
    'hub_payloads': [
      {'name': 'raw_text', 'type': 'text'},
      {'name': 'media_paths', 'type': 'text'},
      {'name': 'intent_tag', 'type': 'text'},
    ],
    'chat_sessions': [
      {'name': 'title', 'type': 'text'},
    ],
    'chat_messages': [
      {'name': 'session_id', 'type': 'number'},
      {'name': 'role', 'type': 'text'},
      {'name': 'content', 'type': 'text'},
    ],
    'long_term_memories': [
      {'name': 'content', 'type': 'text'},
      {'name': 'tags', 'type': 'text'},
    ],
    'knowledge_files': [
      {'name': 'name', 'type': 'text'},
      {'name': 'local_path', 'type': 'text'},
      {'name': 'size', 'type': 'number'},
      {'name': 'extension', 'type': 'text'},
      {'name': 'is_active', 'type': 'bool'},
    ],
    'contacts': [
      {'name': 'name', 'type': 'text'},
      {'name': 'aliases', 'type': 'text'},
      {'name': 'company', 'type': 'text'},
      {'name': 'role', 'type': 'text'},
      {'name': 'phone', 'type': 'text'},
      {'name': 'email', 'type': 'text'},
      {'name': 'tags', 'type': 'text'},
      {'name': 'notes', 'type': 'text'},
      {'name': 'avatar_path', 'type': 'text'},
    ],
    'deals': [
      {'name': 'contact_id', 'type': 'number'},
      {'name': 'title', 'type': 'text'},
      {'name': 'stage', 'type': 'text'},
      {'name': 'value', 'type': 'number'},
      {'name': 'probability', 'type': 'number'},
      {'name': 'expected_close_date', 'type': 'date'},
      {'name': 'notes', 'type': 'text'},
    ],
    'activities': [
      {'name': 'contact_id', 'type': 'number'},
      {'name': 'deal_id', 'type': 'number'},
      {'name': 'type', 'type': 'text'},
      {'name': 'content', 'type': 'text'},
      {'name': 'media_paths', 'type': 'text'},
    ],
    'products': [
      {'name': 'name', 'type': 'text'},
      {'name': 'category', 'type': 'text'},
      {'name': 'specs', 'type': 'text'},
      {'name': 'unit_price', 'type': 'number'},
      {'name': 'notes', 'type': 'text'},
    ],
    'tasks': [
      {'name': 'title', 'type': 'text'},
      {'name': 'contact_id', 'type': 'number'},
      {'name': 'deal_id', 'type': 'number'},
      {'name': 'due_date', 'type': 'date'},
      {'name': 'priority', 'type': 'number'},
      {'name': 'status', 'type': 'text'},
      {'name': 'source_text', 'type': 'text'},
    ],
  };

  PocketBaseAdapter({required String serverUrl})
      : serverUrl = serverUrl,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
          validateStatus: (s) => s != null && s < 500,
        ));

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  Future<String?> auth({
    required String email,
    required String password,
  }) async {
    try {
      final jsonBody = jsonEncode({'identity': email, 'password': password});
      final response = await _dio.post(
        '$serverUrl/api/collections/_superusers/auth-with-password',
        data: jsonBody,
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _token = data['token'] as String;
        debugPrint('PB: authenticated as $email');
        return null;
      }
      final errMsg = response.data is Map
          ? (response.data as Map)['message']?.toString()
          : null;
      return 'Auth failed (${response.statusCode}): ${errMsg ?? 'Unknown'}';
    } catch (e) {
      debugPrint('PB auth failed: $e');
      return 'Auth error: $e';
    }
  }

  Options get _authOpts => Options(headers: {
        'Authorization': _token ?? '',
        'Content-Type': 'application/json',
      });

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Upsert a record by sync_uuid. Creates if not found, updates otherwise.
  ///
  /// Returns the PocketBase record ID on success.
  /// Throws [PocketBaseException] on failure so callers can detect errors.
  Future<String?> upsert(
    String collection,
    Map<String, dynamic> data, {
    required String syncUuid,
  }) async {
    // 1. Search for existing record
    final searchUrl = '$serverUrl/api/collections/$collection/records'
        '?filter=(sync_uuid=%27${Uri.encodeComponent(syncUuid)}%27)'
        '&perPage=1';
    final searchResp = await _dio.get(searchUrl, options: _authOpts);
    _checkAuth(searchResp);

    final items = (searchResp.data as Map)['items'] as List?;

    final body = _prepareBody(data);

    if (items != null && items.isNotEmpty) {
      // 2a. Update existing
      final existingId = (items.first as Map)['id'] as String;
      final patchResp = await _dio.patch(
        '$serverUrl/api/collections/$collection/records/$existingId',
        data: body,
        options: _authOpts,
      );
      _checkAuth(patchResp);
      debugPrint('PB upsert: updated $collection ($syncUuid)');
      return existingId;
    } else {
      // 2b. Create new
      final postResp = await _dio.post(
        '$serverUrl/api/collections/$collection/records',
        data: body,
        options: _authOpts,
      );
      _checkAuth(postResp);
      debugPrint('PB upsert: created $collection ($syncUuid)');
      return null;
    }
  }

  /// Pull all records from a collection (paginated — handles >500 records).
  ///
  /// Note: Always fetches all records (full sync). For a personal app with
  /// limited data volume, full pulls are simpler and more reliable than
  /// incremental timestamp-based filtering which breaks when date fields
  /// are missing/null.
  Future<List<Map<String, dynamic>>> pullChanges(
    String collection,
    DateTime? since,
  ) async {
    final allItems = <Map<String, dynamic>>[];
    var page = 1;
    var totalPages = 1;
    do {
      final url = '$serverUrl/api/collections/$collection/records?perPage=500&page=$page';
      debugPrint('PB pull: GET $url');
      final response = await _dio.get(url, options: _authOpts);
      _checkAuth(response);
      final data = response.data as Map;
      final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      allItems.addAll(items);
      totalPages = data['totalPages'] as int? ?? 1;
      page++;
    } while (page <= totalPages);
    return allItems;
  }

  /// Fetch all records from a collection (paginated).
  ///
  /// Throws on network error — callers (e.g. sync auto-healing) can distinguish
  /// "truly empty" from "failed to fetch" by catching the exception.
  Future<List<Map<String, dynamic>>> fetchAll(String collection) async {
    final allItems = <Map<String, dynamic>>[];
    var page = 1;
    var totalPages = 1;
    do {
      final url = '$serverUrl/api/collections/$collection/records?perPage=500&page=$page';
      final response = await _dio.get(url, options: _authOpts);
      final data = response.data as Map;
      final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      allItems.addAll(items);
      totalPages = data['totalPages'] as int? ?? 1;
      page++;
    } while (page <= totalPages);
    return allItems;
  }

  // ---------------------------------------------------------------------------
  // Auto-setup: ensure collections + fields exist
  // ---------------------------------------------------------------------------

  /// Ensure all sync collections exist with the correct fields.
  ///
  /// Creates missing collections, adds missing fields. Idempotent —
  /// safe to call every time the app connects.
  /// Returns count of collections created/updated.
  Future<int> ensureCollections() async {
    var updated = 0;
    for (final entry in _schemaFields.entries) {
      final name = entry.key;
      final requiredFields = entry.value;

      try {
        // Fetch existing collection
        final colResp = await _dio.get(
          '$serverUrl/api/collections/$name',
          options: _authOpts,
        );

        if (colResp.statusCode == 404) {
          // Create new collection — combine table fields + common fields
          final allFields = [
            ...requiredFields,
            ..._commonFields,
          ];
          await _dio.post(
            '$serverUrl/api/collections',
            data: jsonEncode({
              'name': name,
              'type': 'base',
              'fields': allFields,
            }),
            options: _authOpts,
          );
          debugPrint('PB setup: created collection $name');
          updated++;
          continue;
        }

        // Update existing: add only missing fields
        final existingFields = (colResp.data as Map)['fields'] as List? ?? [];
        final existingNames = existingFields
            .map((f) => (f as Map)['name'] as String?)
            .where((n) => n != null)
            .toSet();
        final newFields = existingFields.toList();
        var added = false;

        for (final f in [...requiredFields, ..._commonFields]) {
          final fieldName = f['name'] as String;
          if (!existingNames.contains(fieldName)) {
            newFields.add({'name': fieldName, 'type': f['type'], 'required': false});
            added = true;
          }
        }

        if (added) {
          await _dio.patch(
            '$serverUrl/api/collections/$name',
            data: jsonEncode({'fields': newFields}),
            options: _authOpts,
          );
          debugPrint('PB setup: added fields to $name');
          updated++;
        }
      } catch (e) {
        debugPrint('PB setup warn [$name]: $e');
        // Non-fatal — table already exists or server is busy
      }
    }
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('$serverUrl/api/health');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('PB health check failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  void dispose() {
    _token = null;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Check HTTP response for auth failures (401/403) and throw descriptive errors.
  void _checkAuth(Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      _token = null;
      throw PocketBaseException(
        'Authentication failed. Your PocketBase session may have expired. '
        'Please disconnect and reconnect.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode != null && response.statusCode! >= 400) {
      final msg = response.data is Map
          ? (response.data as Map)['message']?.toString() ?? 'Unknown error'
          : 'HTTP ${response.statusCode}';
      throw PocketBaseException(msg, statusCode: response.statusCode);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Prepare body for POST/PATCH: JSON-encode and remove SQLite-only fields.
  ///
  /// Null values are preserved so that field-clearing operations (e.g. setting
  /// a FK to null) propagate to PocketBase. With pull-before-push ordering,
  /// local DB is always up-to-date before push, so nulls accurately represent
  /// either intentionally-cleared fields or fields that were never set.
  String _prepareBody(Map<String, dynamic> data) {
    final filtered = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      // Preserve source device's numeric id as _source_id so that
      // FK references (e.g. deal.contact_id → contact.id) can be
      // resolved across devices during pull.
      if (key == 'id') {
        filtered['_source_id'] = entry.value;
        continue;
      }
      var value = entry.value;

      // Convert DateTime to ISO-8601 string (required for PocketBase date fields)
      if (value is DateTime) {
        value = value.toUtc().toIso8601String();
      }

      filtered[key] = value;
    }

    return jsonEncode(filtered);
  }
}
