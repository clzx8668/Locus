import 'dart:convert';
import 'package:drift/drift.dart' as d;
import '../../../core/database/database.dart';
import '../enums/processing_status.dart';
import 'ai_router_service.dart';

/// 单表写入结果
class SyncResult {
  final String table;
  final int? id;
  final bool success;
  final String? error;

  const SyncResult({
    required this.table,
    this.id,
    required this.success,
    this.error,
  });

  bool get isCrm => table == 'crm_customers';
  bool get isLedger => table == 'ledger_entries';
  bool get isTodo => table == 'todo_schedules';
}

/// 结构化分发服务 —— 将 AI 路由结果写入对应业务表
/// v12 改造：两阶段分发（stage → 待用户确认 → execute）
class DispatchService {
  final AppDatabase _db;

  DispatchService(this._db);

  // ==================== 第一阶段：暂存到收件箱 ====================

  /// 将 AI 路由结果暂存到收件箱，等待用户确认
  Future<int> stageForReview(int payloadId, RoutingResult result) async {
    final tag = result.intentTag;
    final targetTable = _targetTableName(tag);
    final extractedData = jsonEncode(result.entities);

    final inboxId = await _db.insertDispatchInbox(
      DispatchInboxCompanion.insert(
        payloadId: payloadId,
        intentTag: tag,
        targetTable: targetTable,
        extractedData: extractedData,
      ),
    );

    await _db.updateProcessingStatus(
      payloadId,
      ProcessingStatus.pendingReview.toDbValue(),
    );
    return inboxId;
  }

  // ==================== 第二阶段：确认后执行分发 ====================

  /// 用户确认后，执行实际分发
  /// [syncTargets] 用户选择的目标表列表，如 ['crm_customers', 'todo_schedules']
  /// 返回写入结果的列表
  Future<List<SyncResult>> executeDispatch(
    int inboxId, {
    List<String>? syncTargets,
  }) async {
    final inbox = await (_db.select(
      _db.dispatchInbox,
    )..where((t) => t.id.equals(inboxId))).getSingleOrNull();

    if (inbox == null || inbox.status != 'pending') return [];

    final entities = jsonDecode(inbox.extractedData) as Map<String, dynamic>;
    final results = <SyncResult>[];

    // 确定要写入的目标表列表
    final targets = syncTargets ?? [_targetTableName(inbox.intentTag)];

    for (final table in targets) {
      try {
        SyncResult result;
        switch (table) {
          case 'crm_customers':
            result = await _dispatchToCrm(inbox.payloadId, entities);
            break;
          case 'ledger_entries':
            result = await _dispatchToLedger(inbox.payloadId, entities);
            break;
          case 'todo_schedules':
            result = await _dispatchToTodo(inbox.payloadId, entities);
            break;
          default:
            result = SyncResult(table: table, success: false, error: '不支持的目标表');
        }
        results.add(result);
      } catch (e) {
        results.add(
          SyncResult(table: table, success: false, error: e.toString()),
        );
      }
    }

    // 更新收件箱为已确认
    await _db.confirmDispatchInbox(inboxId);

    // 更新 payload 状态和引用（使用第一个成功结果的引用）
    final firstRef = results
        .where((r) => r.success && r.id != null)
        .map((r) => '${r.table}:${r.id}')
        .firstOrNull;
    if (firstRef != null) {
      await _db.updateDispatchedRef(inbox.payloadId, firstRef);
    }
    await _db.updateProcessingStatus(
      inbox.payloadId,
      ProcessingStatus.dispatched.toDbValue(),
    );

    return results;
  }

  /// 用户拒绝分发
  Future<void> rejectDispatch(int inboxId) async {
    final inbox = await (_db.select(
      _db.dispatchInbox,
    )..where((t) => t.id.equals(inboxId))).getSingleOrNull();

    if (inbox == null) return;

    await _db.rejectDispatchInbox(inboxId);
    await _db.updateProcessingStatus(
      inbox.payloadId,
      ProcessingStatus.dispatched.toDbValue(),
    );
  }

  /// 撤销已确认的分发
  Future<void> undoDispatch(int payloadId) async {
    // 查找最接近的确认记录
    final inbox = await _db.getDispatchInboxByPayloadId(payloadId);
    if (inbox == null) return;

    // 解析目标表和引用，软删除目标表记录
    await _softDeleteTargetRecord(inbox.targetTable, payloadId);

    // 重置收件箱状态
    await (_db.update(_db.dispatchInbox)..where((t) => t.id.equals(inbox.id)))
        .write(const DispatchInboxCompanion(status: d.Value('reverted')));

    // 清除 payload 引用
    await (_db.update(
      _db.hubPayloads,
    )..where((t) => t.id.equals(payloadId))).write(
      HubPayloadsCompanion(
        dispatchedRef: const d.Value.absent(),
        processingStatus: d.Value(ProcessingStatus.syncedLocal.toDbValue()),
      ),
    );
  }

  /// 持久化收件箱编辑后的字段数据
  Future<void> updateInboxExtractedData(
    int inboxId,
    Map<String, dynamic> entities,
  ) async {
    await _db.updateDispatchInboxData(inboxId, jsonEncode(entities));
  }

  /// 重开已拒绝/已确认的收件箱，恢复到 pending 状态
  Future<void> reopenInbox(int inboxId) async {
    final inbox = await (_db.select(
      _db.dispatchInbox,
    )..where((t) => t.id.equals(inboxId))).getSingleOrNull();
    if (inbox == null) return;

    // 重置收件箱状态为 pending
    await (_db.update(
      _db.dispatchInbox,
    )..where((t) => t.id.equals(inboxId))).write(
      const DispatchInboxCompanion(
        status: d.Value('pending'),
        reviewedAt: d.Value(null),
      ),
    );

    // 重置 payload 状态为 synced_local，准备重新路由
    await _db.updateProcessingStatus(
      inbox.payloadId,
      ProcessingStatus.syncedLocal.toDbValue(),
    );
  }

  // ==================== 内部：分发表写入 ====================

  Future<SyncResult> _dispatchToCrm(
    int payloadId,
    Map<String, dynamic> entities,
  ) async {
    try {
      final name = (entities['person_name'] as String?) ?? '未命名客户';
      final company = entities['company'] as String?;
      final contact = entities['contact'] as String?;
      final notes = _extractDescription(entities);

      final entry = CrmCustomersCompanion.insert(
        sourcePayloadId: payloadId,
        name: name,
        company: d.Value(company),
        contact: d.Value(contact),
        notes: d.Value(notes),
      );

      final crmId = await _db.insertCrmCustomer(entry);
      return SyncResult(table: 'crm_customers', id: crmId, success: true);
    } catch (e) {
      return SyncResult(
        table: 'crm_customers',
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<SyncResult> _dispatchToLedger(
    int payloadId,
    Map<String, dynamic> entities,
  ) async {
    try {
      final amount = (entities['amount'] as num?)?.toDouble() ?? 0.0;
      final category = (entities['ledger_category'] as String?) ?? '其他';
      final description = _extractDescription(entities);
      final type = category == '收入' ? 'income' : 'expense';

      final entry = LedgerEntriesCompanion.insert(
        sourcePayloadId: payloadId,
        amount: amount,
        category: category,
        type: d.Value(type),
        description: d.Value(description),
      );

      final ledgerId = await _db.insertLedgerEntry(entry);
      return SyncResult(table: 'ledger_entries', id: ledgerId, success: true);
    } catch (e) {
      return SyncResult(
        table: 'ledger_entries',
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<SyncResult> _dispatchToTodo(
    int payloadId,
    Map<String, dynamic> entities,
  ) async {
    try {
      final title =
          entities['title'] as String? ??
          _extractDescription(entities) ??
          '未命名待办';
      final priority = (entities['priority'] as int?) ?? 0;
      final notes = entities['notes'] as String?;

      final entry = TodoSchedulesCompanion.insert(
        sourcePayloadId: payloadId,
        title: title,
        priority: d.Value(priority),
        notes: d.Value(notes),
      );

      final todoId = await _db.insertTodoSchedule(entry);
      return SyncResult(table: 'todo_schedules', id: todoId, success: true);
    } catch (e) {
      return SyncResult(
        table: 'todo_schedules',
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _softDeleteTargetRecord(String table, int payloadId) async {
    switch (table) {
      case 'crm_customers':
        try {
          final record =
              await (_db.select(_db.crmCustomers)
                    ..where((t) => t.sourcePayloadId.equals(payloadId)))
                  .getSingleOrNull();
          if (record != null) {
            await _db.deleteCrmCustomer(record.id);
          }
        } catch (_) {}
        break;
      case 'ledger_entries':
        try {
          final record =
              await (_db.select(_db.ledgerEntries)
                    ..where((t) => t.sourcePayloadId.equals(payloadId)))
                  .getSingleOrNull();
          if (record != null) {
            await _db.deleteLedgerEntry(record.id);
          }
        } catch (_) {}
        break;
      case 'todo_schedules':
        try {
          final record =
              await (_db.select(_db.todoSchedules)
                    ..where((t) => t.sourcePayloadId.equals(payloadId)))
                  .getSingleOrNull();
          if (record != null) {
            await _db.deleteTodoSchedule(record.id);
          }
        } catch (_) {}
        break;
    }
  }

  String _targetTableName(String intentTag) {
    switch (intentTag) {
      case 'CRM':
        return 'crm_customers';
      case 'LEDGER':
        return 'ledger_entries';
      case 'TODO':
        return 'todo_schedules';
      default:
        return 'hub_payloads';
    }
  }

  String? _extractDescription(Map<String, dynamic> entities) {
    for (final key in ['description', 'notes', 'content', 'summary']) {
      final val = entities[key];
      if (val is String && val.isNotEmpty) return val;
    }
    return null;
  }
}
