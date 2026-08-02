import 'package:flutter/foundation.dart';
import 'dart:async';
import '../database/database.dart';
import 'sync_database_ext.dart';
import 'pocketbase_adapter.dart' show PocketBaseAdapter, PocketBaseException;

enum PbSyncMode { manual, auto, smart }

class AutoSyncConfig {
  final int intervalMinutes;
  final String? scheduledTime; // "HH:mm" format, e.g. "09:00"
  final bool syncOnResume; // Smart mode: trigger sync when app comes to foreground
  final bool syncOnPause;  // Smart mode: trigger sync when app goes to background

  const AutoSyncConfig({
    this.intervalMinutes = 15,
    this.scheduledTime,
    this.syncOnResume = true,
    this.syncOnPause = true,
  });

  Duration get interval => Duration(minutes: intervalMinutes);

  Map<String, String> toJson() => {
        'interval': intervalMinutes.toString(),
        if (scheduledTime != null) 'scheduled': scheduledTime!,
        'sync_on_resume': syncOnResume.toString(),
        'sync_on_pause': syncOnPause.toString(),
      };
}

class SyncService extends ChangeNotifier {
  final AppDatabase db;

  String? lastError;

  // PocketBase sync
  PocketBaseAdapter? _pb;
  bool _pbConnected = false;
  bool get isPbConnected => _pbConnected;

  /// Sync mode for PocketBase
  PbSyncMode _pbSyncMode = PbSyncMode.manual;
  PbSyncMode get pbSyncMode => _pbSyncMode;

  /// Auto-sync configuration
  AutoSyncConfig _autoConfig = const AutoSyncConfig();
  AutoSyncConfig get autoConfig => _autoConfig;

  /// Last time a sync completed (used for debounce)
  DateTime? _lastSyncEndTime;
  static const _minSyncInterval = Duration(seconds: 10);

  /// Guards against concurrent syncs — only one sync may run at a time.
  bool _isSyncing = false;

  bool get _canSyncNow {
    if (_lastSyncEndTime == null) return true;
    return DateTime.now().difference(_lastSyncEndTime!) >= _minSyncInterval;
  }

  /// Check if the PocketBase server is reachable.
  Future<bool> isNetworkReachable() async {
    if (_pb == null || !_pbConnected) return false;
    try {
      return await _pb!.healthCheck();
    } catch (_) {
      return false;
    }
  }

  /// Incremented after every PocketBase sync to trigger UI refreshes.
  /// Pages wrap their StreamBuilders in ValueListenableBuilder(syncTick)
  /// because Drift's .watch() doesn't react to customStatement changes.
  final ValueNotifier<int> syncTick = ValueNotifier<int>(0);

  SyncService(this.db);

  /// Restore persisted sync mode and auto-config on startup.
  Future<void> init() async {
    final savedMode = await db.getConfig('pb_sync_mode');
    if (savedMode != null) {
      _pbSyncMode = PbSyncMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => PbSyncMode.manual,
      );
    }
    final savedInterval = await db.getConfig('pb_auto_interval');
    final savedScheduled = await db.getConfig('pb_scheduled_time');
    final savedResume = await db.getConfig('sync_on_resume');
    final savedPause = await db.getConfig('sync_on_pause');
    _autoConfig = AutoSyncConfig(
      intervalMinutes: int.tryParse(savedInterval ?? '') ?? 15,
      scheduledTime: savedScheduled,
      syncOnResume: savedResume != 'false',
      syncOnPause: savedPause != 'false',
    );

    // Try auto-reconnect if previous credentials were saved
    await _tryAutoConnect();

    _applySyncMode();
  }

  /// Silently attempt to reconnect using saved PocketBase credentials.
  /// On success, sets [_pbConnected] and notifies listeners.
  /// On failure, leaves [_pbConnected] as false — user can manually connect later.
  Future<void> _tryAutoConnect() async {
    final savedUrl = await db.getConfig('pb_server_url');
    final savedEmail = await db.getConfig('pb_email');
    final savedPassword = await db.getConfig('pb_password');
    if (savedUrl == null || savedEmail == null || savedPassword == null) return;

    try {
      _pb = PocketBaseAdapter(serverUrl: savedUrl);
      final authErr = await _pb!.auth(email: savedEmail, password: savedPassword);
      if (authErr != null) return;
      final healthy = await _pb!.healthCheck();
      if (!healthy) return;
      _pbConnected = true;
      notifyListeners();
      debugPrint('PB auto-reconnect: success ($savedUrl)');
    } catch (e) {
      debugPrint('PB auto-reconnect: failed ($e)');
      _pb?.dispose();
      _pb = null;
    }
  }

  // ===========================================================================
  // PocketBase Sync
  // ===========================================================================

  /// Configure and connect to a PocketBase server.
  Future<String?> connectPocketBase({
    required String serverUrl,
    required String email,
    required String password,
  }) async {
    try {
      // Normalize URL: auto-prepend http:// and strip trailing slash
      var url = serverUrl.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://$url';
      }
      if (url.endsWith('/')) url = url.substring(0, url.length - 1);

      _pb = PocketBaseAdapter(serverUrl: url);
      final authErr = await _pb!.auth(email: email, password: password);
      if (authErr != null) return authErr;
      final healthy = await _pb!.healthCheck();
      if (!healthy) return 'Server unreachable';
      _pbConnected = true;
      await db.setConfig('pb_server_url', url);
      await db.setConfig('pb_email', email);
      await db.setConfig('pb_password', password);

      // Auto-setup: ensure all collections have correct fields
      try {
        final n = await _pb!.ensureCollections();
        if (n > 0) debugPrint('PB auto-setup: created/updated $n collection(s)');
      } catch (_) {} // Non-fatal: sync still works if schema already exists

      notifyListeners();
      return null; // success
    } catch (e) {
      _pbConnected = false;
      _pb?.dispose();
      _pb = null;
      return e.toString();
    }
  }

  /// Sync all tables via PocketBase (pull first, then push).
  Future<String?> syncViaPocketBase() async {
    if (_pb == null || !_pbConnected) return 'Not connected to PocketBase';

    try {
      notifyListeners();

      // Defer FK checks — sync may insert records in any order, so FK
      // references (e.g. tasks.contact_id → contacts.id) may be temporarily
      // unsatisfied. PRAGMA is re-enabled in the finally block below.
      await db.customStatement('PRAGMA foreign_keys = OFF');

      // Step 0 ...
      for (final table in SyncDatabaseExt.syncTables) {
        try {
          await db.customStatement(
            "UPDATE $table SET sync_uuid = lower(hex(randomblob(16))) WHERE sync_uuid IS NULL",
          );
        } catch (_) {}
      }

      // Step 0.5: Auto-healing — if PocketBase table is empty but local has
      // records marked as synced (from previous failed pushes), force re-push.
      for (final table in SyncDatabaseExt.syncTables) {
        try {
          final allRecords = await _pb!.fetchAll(table);
          if (allRecords.isEmpty) {
            // PocketBase has 0 records — reset local sync_status to re-push everything
            await db.resetSyncStatus(table);
            debugPrint('PB sync: $table empty on server, resetting sync_status for full push');
          }
        } catch (_) {
          // If fetchAll fails, skip auto-healing for this table
        }
      }

      final lastSync = await db.getLastSyncTime();
      var pushed = 0;
      var pulled = 0;
      final errors = <String>[];
      final tableMods = <String, int>{};

      // === PULL FIRST ===
      // Pull-before-push ensures true bidirectional LWW: remote changes are
      // merged locally (with timestamp comparison) before we push. Only
      // records where local timestamp is genuinely newer survive to push.
      //
      // Cross-device FK resolution: as we pull records, we build a
      // source_id→local_id map. When a child table record (e.g. deals)
      // references a parent (e.g. contacts), the FK value from the source
      // device is resolved to the local auto-increment id.
      SyncDatabaseExt.beginFkResolution();
      for (final table in SyncDatabaseExt.syncTables) {
        try {
          final changes = await _pb!.pullChanges(table, lastSync);
          var tablePulled = 0;
          var tableSkipped = 0;
          // Diagnostic: show first record's keys to verify PB response structure
          if (changes.isNotEmpty) {
            debugPrint('PB pull diag $table: first record keys=${changes.first.keys.take(8).join(', ')}');
          }
          for (final record in changes) {
            final syncUuid = record['sync_uuid'] as String?;
            if (syncUuid == null) {
              tableSkipped++;
              debugPrint('PB pull skip $table: record missing sync_uuid, keys=${record.keys.take(6).join(', ')}');
              continue;
            }
            try {
              final change = await db.recordToSyncChange(table, {
                ...record,
                'sync_status': 0,
              });
              await db.applyRemoteChange(change);
              pulled++;
              tablePulled++;

              // Register FK mapping: source_id → local_id for this record
              final sourceId = record['_source_id'];
              if (sourceId is int) {
                final localId = await db.findLocalId(table, syncUuid);
                if (localId != null) {
                  SyncDatabaseExt.registerFkMapping(table, sourceId, localId);
                }
              }
            } catch (e) {
              errors.add('pull $table($syncUuid): $e');
              debugPrint('PB pull record error $table($syncUuid): $e');
            }
          }
          debugPrint('PB pull: $table done — pulled=$tablePulled skipped=$tableSkipped total=${changes.length}');
          if (tablePulled > 0) tableMods[table] = (tableMods[table] ?? 0) + tablePulled;
        } catch (e) {
          errors.add('pull $table: $e');
          debugPrint('PB pull error $table: $e');
        }
      }

      // === PUSH SECOND ===
      // After pull, local DB reflects the merged state. Records that were
      // overwritten by a newer remote version now have sync_status=1 and
      // won't be pushed. Only records where local changes survived LWW
      // (or new local records) remain with sync_status!=1 and get pushed.
      for (final table in SyncDatabaseExt.syncTables) {
        final records = await db.getUnsyncedRecords(table);
        var tablePushed = 0;
        debugPrint('PB push: $table has ${records.length} records to push');
        // Diagnostic: log sync_status distribution to debug "pushed 0" cases
        try {
          final all = await db.customSelect(
            'SELECT sync_status, COUNT(*) as cnt FROM $table GROUP BY sync_status',
          ).get();
          final dist = all.map((r) => 'status=${r.data['sync_status']}=${r.data['cnt']}').join(', ');
          debugPrint('PB push diag $table: $dist');
        } catch (_) {}
        for (final row in records) {
          final syncUuid = row['sync_uuid'] as String?;
          if (syncUuid == null) continue;
          final data = Map<String, dynamic>.from(row)..remove('id');
          try {
            await _pb!.upsert(table, data, syncUuid: syncUuid);
            final localId = row['id'] as int;
            await db.markSynced(table, localId);
            pushed++;
            tablePushed++;
          } catch (e) {
            errors.add('push $table($syncUuid): $e');
            debugPrint('PB push error $table: $e');
          }
        }
        if (tablePushed > 0) tableMods[table] = (tableMods[table] ?? 0) + tablePushed;
      }

      await db.setLastSyncTime(DateTime.now());
      lastError = null;
      final summary = 'Pushed $pushed, pulled $pulled';
      debugPrint('PB sync done: $summary, errors: ${errors.length}');

      // Ensure WAL data is visible to subsequent read queries
      await db.customStatement('PRAGMA wal_checkpoint(PASSIVE)');

      // Notify Drift .watch() subscribers — customStatement bypasses ORM tracking
      if (tableMods.isNotEmpty) {
        db.notifyTableUpdates(tableMods);
        debugPrint('PB sync: notified ${tableMods.length} tables: $tableMods');
      }

      syncTick.value++; // Trigger UI refresh (customStatement bypasses .watch())
      notifyListeners();

      _lastSyncEndTime = DateTime.now();

      if (errors.isNotEmpty) {
        return '$summary — ${errors.length} error(s):\n${errors.take(3).join('\n')}${errors.length > 3 ? '\n...and ${errors.length - 3} more' : ''}';
      }
      return summary; // Show push/pull counts on success
    } catch (e) {
      final msg = e is PocketBaseException ? e.message : e.toString();
      lastError = msg;
      debugPrint('PB sync fatal error: $msg');
      notifyListeners();
      return msg;
    } finally {
      // Re-enable FK checks after sync (or after failure)
      try {
        await db.customStatement('PRAGMA foreign_keys = ON');
      } catch (_) {}
    }
  }

  /// Get a summary string for the last PocketBase sync.
  Future<String> getPbSyncSummary() async {
    final lastSync = await db.getLastSyncTime();
    if (lastSync == null) return 'Never synced';
    final diff = DateTime.now().difference(lastSync);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  /// Set the PocketBase sync mode and persist it.
  Future<void> setPbSyncMode(PbSyncMode mode) async {
    if (_pbSyncMode == mode) return;
    _pbSyncMode = mode;
    await db.setConfig('pb_sync_mode', mode.name);
    _applySyncMode();
    notifyListeners();
  }

  /// Set the auto-sync configuration.
  /// All fields are optional — unspecified fields retain their current values.
  Future<void> setAutoConfig({
    int? intervalMinutes,
    String? scheduledTime,
    bool? syncOnResume,
    bool? syncOnPause,
  }) async {
    // Empty string → null: treats explicit empty as "clear this field"
    final resolvedTime = scheduledTime != null
        ? (scheduledTime.isEmpty ? null : scheduledTime)
        : _autoConfig.scheduledTime;

    _autoConfig = AutoSyncConfig(
      intervalMinutes: intervalMinutes ?? _autoConfig.intervalMinutes,
      scheduledTime: resolvedTime,
      syncOnResume: syncOnResume ?? _autoConfig.syncOnResume,
      syncOnPause: syncOnPause ?? _autoConfig.syncOnPause,
    );
    await db.setConfig('pb_auto_interval', _autoConfig.intervalMinutes.toString());
    if (_autoConfig.scheduledTime != null && _autoConfig.scheduledTime!.isNotEmpty) {
      await db.setConfig('pb_scheduled_time', _autoConfig.scheduledTime!);
    } else {
      await db.setConfig('pb_scheduled_time', '');
    }
    await db.setConfig('sync_on_resume', _autoConfig.syncOnResume.toString());
    await db.setConfig('sync_on_pause', _autoConfig.syncOnPause.toString());
    _applySyncMode();
    notifyListeners();
  }

  /// Apply the current sync mode (start/stop timers as needed).
  void _applySyncMode() {
    _stopAutoTimer();
    _stopDailyScheduler();
    if (_pbSyncMode == PbSyncMode.auto || _pbSyncMode == PbSyncMode.smart) {
      _startAutoTimer();
      _startDailyScheduler();
    }
  }

  /// Unified sync trigger with guards: mode check, debounce, network.
  ///
  /// Returns the sync summary on success, or an error message string.
  /// Returns `null` if the trigger was suppressed (debounce, network, mode).
  Future<String?> triggerPbSync({bool fromUser = false}) async {
    // Mode guard: manual mode only allows user-initiated triggers
    if (_pbSyncMode == PbSyncMode.manual && !fromUser) return null;

    // Debounce guard
    if (!_canSyncNow) {
      debugPrint('PB sync: throttled (min interval: ${_minSyncInterval.inSeconds}s)');
      if (fromUser) return 'Sync throttled — please wait ${_minSyncInterval.inSeconds}s';
      return null;
    }

    // Network guard
    if (!await isNetworkReachable()) {
      debugPrint('PB sync: network unreachable');
      if (fromUser) return 'Network unreachable';
      return null;
    }

    // Concurrency guard — prevent overlapping syncs
    if (_isSyncing) {
      debugPrint('PB sync: already in progress, skipping');
      if (fromUser) return 'Sync already in progress';
      return null;
    }

    _isSyncing = true;
    try {
      return await syncViaPocketBase();
    } finally {
      _isSyncing = false;
    }
  }

  // ===========================================================================
  // Auto-Sync Timer
  // ===========================================================================

  Timer? _autoTimer;
  Timer? _scheduledTimer;

  void _startAutoTimer() {
    _stopAutoTimer();
    _autoTimer = Timer.periodic(_autoConfig.interval, (_) {
      triggerPbSync();
    });
    debugPrint('PB auto-sync: started (every ${_autoConfig.intervalMinutes}min)');
  }

  void _stopAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  void _startDailyScheduler() {
    _stopDailyScheduler();
    final st = _autoConfig.scheduledTime;
    if (st == null || st.isEmpty) return;
    final parts = st.split(':');
    if (parts.length != 2) return;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return;

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, h, m);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    _scheduledTimer = Timer(next.difference(now), () {
      triggerPbSync();
      _startDailyScheduler(); // re-schedule for next day
    });
    debugPrint('PB daily: scheduled at $st, next in ${next.difference(now).inMinutes}min');
  }

  void _stopDailyScheduler() {
    _scheduledTimer?.cancel();
    _scheduledTimer = null;
  }

  /// Disconnect from PocketBase.
  void disconnectPocketBase() {
    _stopAutoTimer();
    _stopDailyScheduler();
    _pb?.dispose();
    _pb = null;
    _pbConnected = false;
    // Clear persisted credentials (fire-and-forget; no await in sync method)
    db.batch((b) {
      b.deleteWhere(db.appConfig, (t) => t.key.equals('pb_server_url'));
      b.deleteWhere(db.appConfig, (t) => t.key.equals('pb_email'));
      b.deleteWhere(db.appConfig, (t) => t.key.equals('pb_password'));
    });
    notifyListeners();
  }
}
