import 'package:drift/drift.dart';
import '../database/database.dart';
import 'sync_protocol.dart';

extension SyncDatabaseExt on AppDatabase {
  static const List<String> syncTables = [
    'hub_payloads',
    'chat_sessions',
    'chat_messages',
    'long_term_memories',
    'knowledge_files',
    'contacts',
    'deals',
    'activities',
    'products',
    'tasks',
  ];

  /// FK column → parent table mapping for cross-device ID resolution.
  /// When pulling a record, FK values from the source device (e.g.
  /// contact_id=5) are resolved to local IDs using the _fkMap built
  /// during the pull phase.
  static const _fkRelations = <String, Map<String, String>>{
    'chat_messages': {'session_id': 'chat_sessions'},
    'deals': {'contact_id': 'contacts'},
    'activities': {'contact_id': 'contacts', 'deal_id': 'deals'},
    'tasks': {'contact_id': 'contacts', 'deal_id': 'deals'},
  };

  /// FK resolution map: parentTable → (source_id → local_id).
  /// Populated by sync_service during pull as records are applied.
  static final Map<String, Map<int, int>> _fkMap = {};

  /// Reset FK map before a new sync pull phase.
  static void beginFkResolution() {
    _fkMap.clear();
  }

  /// Register a mapping from source device ID to local ID.
  static void registerFkMapping(String table, int sourceId, int localId) {
    _fkMap.putIfAbsent(table, () => {});
    _fkMap[table]![sourceId] = localId;
  }

  /// PocketBase metadata fields that don't exist in local SQLite tables.
  static const _pbMetaFields = {
    'collectionId',
    'collectionName',
    'created',  // PB auto field — we use created_at
    'updated',  // PB auto field — we use updated_at
    'expand',
  };

  static const _tablesWithoutUpdatedAt = {'hub_payloads'};

  /// Get records that need to be synced (sync_status != 1).
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    final rows = await customSelect(
      'SELECT * FROM $table WHERE sync_uuid IS NOT NULL AND sync_status != 1',
    ).get();
    return rows.map((r) => Map<String, dynamic>.from(r.data)).toList();
  }

  /// Get records changed since a given timestamp.
  Future<List<Map<String, dynamic>>> getChangesSince(
      String table, DateTime since) async {
    final tsColumn =
        _tablesWithoutUpdatedAt.contains(table) ? 'created_at' : 'updated_at';
    try {
      final rows = await customSelect(
        'SELECT * FROM $table WHERE sync_uuid IS NOT NULL AND $tsColumn > ?',
        variables: [Variable.withDateTime(since)],
      ).get();
      return rows.map((r) => Map<String, dynamic>.from(r.data)).toList();
    } catch (_) {
      // Column missing (e.g. updated_at on legacy DB) — fall back to created_at
      final rows = await customSelect(
        'SELECT * FROM $table WHERE sync_uuid IS NOT NULL AND created_at > ?',
        variables: [Variable.withDateTime(since)],
      ).get();
      return rows.map((r) => Map<String, dynamic>.from(r.data)).toList();
    }
  }

  /// Find the local id for a given sync_uuid.
  Future<int?> findLocalId(String table, String syncUuid) async {
    final rows = await customSelect(
      'SELECT id FROM $table WHERE sync_uuid = ?',
      variables: [Variable.withString(syncUuid)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data['id'] as int;
  }

  /// Mark a record as synced (sync_status = 1).
  Future<void> markSynced(String table, int localId) async {
    await customStatement(
      'UPDATE $table SET sync_status = 1 WHERE id = ?',
      [localId],
    );
  }

  /// Convert a DB row to a SyncChange.
  Future<SyncChange> recordToSyncChange(
      String table, Map<String, dynamic> record) async {
    final syncStatus = record['sync_status'] as int;
    SyncOp op;
    if (syncStatus == 3) {
      op = SyncOp.delete;
    } else if (syncStatus == 0) {
      op = SyncOp.insert;
    } else {
      op = SyncOp.update;
    }

    final tsValue = _tablesWithoutUpdatedAt.contains(table)
        ? record['created_at']
        : (record['updated_at'] ?? record['created_at']);

    DateTime updatedAt;
    if (tsValue is DateTime) {
      updatedAt = tsValue;
    } else if (tsValue is String && (tsValue as String).isNotEmpty) {
      try {
        updatedAt = DateTime.parse(tsValue);
      } catch (_) {
        updatedAt = DateTime.now();
      }
    } else {
      updatedAt = DateTime.now();
    }

    return SyncChange(
      table: table,
      syncUuid: record['sync_uuid'] as String,
      op: op,
      data: Map<String, dynamic>.from(record),
      updatedAt: updatedAt,
    );
  }

  /// Apply a remote change with LWW conflict resolution.
  Future<void> applyRemoteChange(SyncChange change) async {
    final localId = await findLocalId(change.table, change.syncUuid);

    if (change.op == SyncOp.delete) {
      if (localId != null) {
        await customStatement(
          'UPDATE ${change.table} SET is_deleted = 1, sync_status = 1 WHERE id = ?',
          [localId],
        );
      }
      return;
    }

    // For insert/update
    if (localId != null) {
      // Record exists locally — LWW conflict resolution.
      // Some tables lack updated_at on older databases (migration may have
      // silently failed). Try updated_at first, fall back to created_at only.
      final hasUpdatedAt = !_tablesWithoutUpdatedAt.contains(change.table);
      final tsCol = hasUpdatedAt ? 'updated_at' : 'created_at';
      List<QueryRow> existing;
      try {
        existing = await customSelect(
          'SELECT $tsCol, created_at FROM ${change.table} WHERE id = ?',
          variables: [Variable.withInt(localId)],
        ).get();
      } catch (_) {
        // Column missing — retry with created_at only
        existing = await customSelect(
          'SELECT created_at FROM ${change.table} WHERE id = ?',
          variables: [Variable.withInt(localId)],
        ).get();
      }

      if (existing.isNotEmpty) {
        final localTsValue = existing.first.data['updated_at'] ??
            existing.first.data['created_at'];

        DateTime localTs;
        if (localTsValue is DateTime) {
          localTs = localTsValue;
        } else if (localTsValue is String && (localTsValue as String).isNotEmpty) {
          try {
            localTs = DateTime.parse(localTsValue);
          } catch (_) {
            localTs = DateTime(2000);
          }
        } else {
          localTs = DateTime(2000);
        }

        // LWW: remote wins only if it's newer
        if (!change.updatedAt.isAfter(localTs)) {
          return; // Local is newer or same, skip
        }
      }

      // Apply update
      await _applyUpdate(change.table, localId, change.data);
    } else {
      // Record doesn't exist locally — insert
      await _applyInsert(change.table, change.data);
    }
  }

  /// Normalize foreign key values: 0 → null.
  /// 
  /// FK references like tasks.contact_id → contacts.id will fail if the
  /// value is 0 (no contact with id=0 exists). Since all FK columns in our
  /// schema are nullable, converting 0 to null is safe and correct.
  static void _normalizeForeignKeys(Map<String, dynamic> data) {
    // Known FK columns (with and without underscore variants from legacy data)
    const fkColumns = {
      'contact_id', 'contactid',
      'deal_id', 'dealid',
      'session_id', 'sessionid',
    };
    for (final col in fkColumns) {
      if (data[col] == 0) {
        data[col] = null;
      }
    }
  }

  /// Resolve cross-device FK references using the _fkMap.
  ///
  /// When a record from device A has e.g. contact_id=5, that 5 is A's local
  /// auto-increment id. On device B, the same contact has a different local
  /// id. We use the _source_id→local_id mapping built during pull to replace
  /// the source device's FK value with the local one.
  static void _resolveForeignKeys(String table, Map<String, dynamic> data) {
    final relations = _fkRelations[table];
    if (relations == null) return;
    for (final entry in relations.entries) {
      final fkCol = entry.key;
      final parentTable = entry.value;
      final fkValue = data[fkCol];
      if (fkValue is int && fkValue > 0) {
        final parentMap = _fkMap[parentTable];
        if (parentMap != null) {
          final localId = parentMap[fkValue];
          if (localId != null) {
            data[fkCol] = localId;
          }
        }
      }
    }
  }

  /// Apply an UPDATE operation.
  Future<void> _applyUpdate(
      String table, int localId, Map<String, dynamic> data) async {
    // Remove local id + PocketBase metadata fields
    final filtered = Map<String, dynamic>.from(data)
      ..remove('id')
      ..removeWhere((k, _) => _pbMetaFields.contains(k));
    filtered['sync_status'] = 1;

    // Also remove null/empty date fields that would fail type coercion
    filtered.removeWhere((k, v) =>
        (k == 'created_at' || k == 'updated_at' || k == 'due_date' ||
         k == 'expected_close_date') &&
        (v == null || (v is String && v.isEmpty)));

    // Normalize FK columns: 0 → null (FK references won't match id=0)
    _normalizeForeignKeys(filtered);

    // Resolve cross-device FK references (source_id → local_id)
    _resolveForeignKeys(table, filtered);

    // Remove _source_id (PB-only field, not in local SQLite)
    filtered.remove('_source_id');

    final columns = filtered.keys.toList();
    final setClauses = columns.map((c) => '$c = ?').join(', ');
    final values = columns.map((c) {
      final v = filtered[c];
      if (v is DateTime) return v.toIso8601String();
      if (v is bool) return v ? 1 : 0;
      return v;
    }).toList();
    values.add(localId);

    await customStatement(
      'UPDATE $table SET $setClauses WHERE id = ?',
      values,
    );
  }

  /// Apply an INSERT operation.
  Future<void> _applyInsert(
      String table, Map<String, dynamic> data) async {
    // Remove local id + PocketBase metadata fields
    final filtered = Map<String, dynamic>.from(data)
      ..remove('id')
      ..removeWhere((k, _) => _pbMetaFields.contains(k));
    filtered['sync_status'] = 1;

    // Remove null/empty date fields that would fail type coercion
    filtered.removeWhere((k, v) =>
        (k == 'created_at' || k == 'updated_at' || k == 'due_date' ||
         k == 'expected_close_date') &&
        (v == null || (v is String && v.isEmpty)));

    // Normalize FK columns: 0 → null (FK references won't match id=0)
    _normalizeForeignKeys(filtered);

    // Resolve cross-device FK references (source_id → local_id)
    _resolveForeignKeys(table, filtered);

    // Remove _source_id (PB-only field, not in local SQLite)
    filtered.remove('_source_id');

    final columns = filtered.keys.toList();
    final placeholders = columns.map((_) => '?').join(', ');
    final values = columns.map((c) {
      final v = filtered[c];
      if (v is DateTime) return v.toIso8601String();
      if (v is bool) return v ? 1 : 0;
      return v;
    }).toList();

    await customStatement(
      'INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders)',
      values,
    );
  }

  /// Reset sync_status to 0 for all records in a table (force full re-sync).
  Future<void> resetSyncStatus(String table) async {
    await customStatement(
      'UPDATE $table SET sync_status = 0 WHERE sync_uuid IS NOT NULL',
    );
  }

  /// Get the last sync time from app_config.
  Future<DateTime?> getLastSyncTime() async {
    final val = await getConfig('last_sync_time');
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  /// Set the last sync time in app_config.
  Future<void> setLastSyncTime(DateTime time) async {
    await setConfig('last_sync_time', time.toIso8601String());
  }

  /// Notify Drift's stream query system about table modifications.
  ///
  /// Sync writes use [customStatement] (raw SQL) which bypasses Drift's
  /// typed ORM layer. As a result, Drift's internal [UpdateKind] tracking
  /// is never activated, and `.watch()` subscribers never re-emit. This
  /// method manually triggers [streamQueries.handleTableUpdates] to force
  /// all registered stream queries to re-evaluate and emit fresh data.
  ///
  /// Call this after sync pull/push completes, before any UI refresh.
  void notifyTableUpdates(Map<String, int> tableModifications) {
    if (tableModifications.isEmpty) return;

    final updates = tableModifications.entries.map<TableUpdate>((e) => TableUpdate(
      e.key,
      kind: UpdateKind.update,
    )).toSet();

    streamQueries.handleTableUpdates(updates);
  }
}
