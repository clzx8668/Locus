/// 字段中文别名映射表 —— 按意图分类
///
/// 用于 AI 收件箱中以中文标签替代原始英文字段名展示
class FieldLabels {
  FieldLabels._();

  /// CRM 客户关系字段中文别名
  static const Map<String, String> crm = {
    'person_name': '姓名',
    'company': '公司',
    'contact': '联系方式',
    'notes': '备注',
    'description': '描述',
    'phone': '电话',
    'email': '邮箱',
    'address': '地址',
  };

  /// LEDGER 记账字段中文别名
  static const Map<String, String> ledger = {
    'amount': '金额',
    'ledger_category': '记账分类',
    'description': '描述',
    'type': '类型',
    'notes': '备注',
    'date': '日期',
  };

  /// TODO 待办事项字段中文别名
  static const Map<String, String> todo = {
    'title': '标题',
    'priority': '优先级',
    'notes': '备注',
    'due_date': '截止日期',
    'description': '描述',
    'assignee': '负责人',
  };

  /// 根据意图标签和字段键获取中文别名
  /// 如果未找到匹配，返回原始键名
  static String label(String intentTag, String fieldKey) {
    final map = _byTag(intentTag);
    return map[fieldKey] ?? fieldKey;
  }

  /// 获取指定意图的所有字段标签映射
  static Map<String, String> _byTag(String intentTag) {
    switch (intentTag) {
      case 'CRM':
        return crm;
      case 'LEDGER':
        return ledger;
      case 'TODO':
        return todo;
      default:
        return {};
    }
  }

  /// 获取指定意图的所有字段键列表（用于遍历显示）
  static List<String> fieldKeys(String intentTag) {
    return _byTag(intentTag).keys.toList();
  }
}

/// 每种意图的核心必填键值列表
///
/// 当 AI 抽取结果缺失任一核心键值时，收件箱自动触发补录提示
class RequiredFields {
  RequiredFields._();

  /// CRM 核心必填字段
  static const List<String> crm = ['person_name'];

  /// LEDGER 核心必填字段
  static const List<String> ledger = ['amount'];

  /// TODO 核心必填字段
  static const List<String> todo = ['title'];

  /// 根据意图标签获取核心必填字段列表
  static List<String> forTag(String intentTag) {
    switch (intentTag) {
      case 'CRM':
        return crm;
      case 'LEDGER':
        return ledger;
      case 'TODO':
        return todo;
      default:
        return [];
    }
  }

  /// 检测给定实体数据中缺失的核心必填键值
  /// 返回缺失字段的中文标签列表
  static List<String> detectMissing(
    String intentTag,
    Map<String, dynamic> entities,
  ) {
    final required = forTag(intentTag);
    final missing = <String>[];
    for (final key in required) {
      final value = entities[key];
      if (value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is num && value == 0)) {
        missing.add(FieldLabels.label(intentTag, key));
      }
    }
    return missing;
  }
}
