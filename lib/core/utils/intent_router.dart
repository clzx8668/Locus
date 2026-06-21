class IntentRouter {
  /// 传入用户输入的原始文本，返回匹配的业务标签
  static String parseTag(String text) {
    final lowerText = text.toLowerCase();

    // 1. 待办提醒 (匹配行首的 todo、待办)
    if (RegExp(r'^(todo|待办|- \[ \])').hasMatch(lowerText)) {
      return 'TODO';
    }

    // 2. 财务记账 (匹配金钱符号、账务相关词汇)
    if (RegExp(r'(💰|记账|报销|打车|采购|付款|发票|收款|尾款|[0-9]+元)').hasMatch(lowerText)) {
      return 'LEDGER';
    }

    // 3. 客户关系与合同 (匹配握手、客户、报价、合同等)
    if (RegExp(r'(🤝|客户|回访|拜访|报价|售后|合同|协议)').hasMatch(lowerText)) {
      return 'CRM';
    }

    // 4. 仓库与生产排期 (匹配包装、发货、库存、车间等)
    if (RegExp(r'(📦|库存|发货|仓库|生产|排产|盘点)').hasMatch(lowerText)) {
      return 'INVENTORY';
    }

    // 5. 知识积累与日常打卡 (匹配特定前缀)
    if (RegExp(r'^(打卡|习惯)').hasMatch(lowerText)) {
      return 'HABIT';
    }

    // 默认回退为普通笔记
    return 'NOTE';
  }
}
