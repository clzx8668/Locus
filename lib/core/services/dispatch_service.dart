import 'package:drift/drift.dart' as d;
import '../../../core/database/database.dart';
import 'ai_router_service.dart';

/// 结构化分发服务 —— 将 AI 路由结果写入对应业务表
class DispatchService {
  final AppDatabase _db;

  DispatchService(this._db);

  /// 执行分发
  Future<String?> dispatch(int payloadId, RoutingResult result) async {
    final tag = result.intentTag;
    final entities = result.entities;

    switch (tag) {
      case 'CRM':
        return _dispatchToCrm(payloadId, entities);
      case 'LEDGER':
        return _dispatchToLedger(payloadId, entities);
      case 'TODO':
        return _dispatchToTodo(payloadId, entities);
      default:
        // NOTE / INVENTORY / HABIT 暂不分发到独立表
        return null;
    }
  }

  Future<String?> _dispatchToCrm(
      int payloadId, Map<String, dynamic> entities) async {
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
    return 'crm_customers:$crmId';
  }

  Future<String?> _dispatchToLedger(
      int payloadId, Map<String, dynamic> entities) async {
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
    return 'ledger_entries:$ledgerId';
  }

  Future<String?> _dispatchToTodo(
      int payloadId, Map<String, dynamic> entities) async {
    final title = entities['title'] as String? ??
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
    return 'todo_schedules:$todoId';
  }

  String? _extractDescription(Map<String, dynamic> entities) {
    // 尝试从实体中获取描述
    for (final key in ['description', 'notes', 'content', 'summary']) {
      final val = entities[key];
      if (val is String && val.isNotEmpty) return val;
    }
    return null;
  }
}
