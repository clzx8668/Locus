/// 实体抽取结果
class ExtractedEntities {
  final String intentTag;
  final double? amount;
  final String? personName;
  final String? company;
  final String? dueDateText; // 原始时间文本，如"明天"、"下周三"
  final String? category; // 记账分类
  final int priority; // 0-3
  final String? title; // TODO 待办标题（AI 或本地提取）

  const ExtractedEntities({
    required this.intentTag,
    this.amount,
    this.personName,
    this.company,
    this.dueDateText,
    this.category,
    this.priority = 0,
    this.title,
  });

  Map<String, dynamic> toJson() => {
    'intentTag': intentTag,
    'amount': amount,
    'personName': personName,
    'company': company,
    'dueDateText': dueDateText,
    'category': category,
    'priority': priority,
    'title': title,
  };
}

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

  /// 从文本中抽取结构化实体（金额、人名、时间、记账分类、优先级）
  /// 用于 AI 离线降级时的本地抽取
  static ExtractedEntities extractEntities(String text) {
    final intentTag = parseTag(text);
    final lowerText = text.toLowerCase();

    // --- 金额抽取 ---
    double? amount;
    final amountMatch = RegExp(
      r'(\d+\.?\d*)\s*(元|块|￥|¥|💰|块钱|元钱|块钱)',
    ).firstMatch(text);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!);
    }

    // --- 人名/公司抽取 ---
    String? personName;
    final nameMatch = RegExp(
      r'(?:客户|联系人|拜访|回访|联系)[：:\s]*(\S{1,10})(?:[，,。.!！\s]|$)',
    ).firstMatch(text);
    if (nameMatch != null) {
      personName = nameMatch.group(1)?.trim();
    }

    String? company;
    final companyMatch = RegExp(
      r'(?:公司|企业|单位)[：:\s]*(\S{1,20})(?:[，,。.!！\s]|$)',
    ).firstMatch(text);
    if (companyMatch != null) {
      company = companyMatch.group(1)?.trim();
    }

    // --- 时间抽取 ---
    String? dueDateText;
    final timeMatch = RegExp(
      r'(明天|后天|大后天|下周[一二三四五六日天]|下下周|\d{1,2}月\d{1,2}日?|\d{1,2}:\d{2}|上午|下午|晚上|今晚|明早)',
    ).firstMatch(text);
    if (timeMatch != null) {
      dueDateText = timeMatch.group(1);
    }

    // --- 记账分类 ---
    String? category;
    if (intentTag == 'LEDGER') {
      category = _detectLedgerCategory(lowerText);
    }

    // --- 优先级 ---
    int priority = 0;
    if (RegExp(r'(urgent|紧急|重要|加急)').hasMatch(lowerText)) {
      priority = 3;
    } else if (RegExp(r'(尽快|asap|优先)').hasMatch(lowerText)) {
      priority = 2;
    }

    // --- 待办标题提取 ---
    String? title;
    if (intentTag == 'TODO') {
      // 去除时间描述
      String cleaned = text.replaceAll(
        RegExp(
          r'(明天|后天|大后天|下周[一二三四五六日天]|下下周|'
          r'\d{1,2}月\d{1,2}日?|\d{1,2}:\d{2}|'
          r'上午|下午|晚上|今晚|明早|'
          r'记得|别忘了|提醒我|提醒)',
        ),
        '',
      );
      // 去除人名
      cleaned = cleaned.replaceAll(
        RegExp(r'[跟和与找联系]\s*\S{1,4}(?:开会|讨论|吃饭)'),
        '',
      );
      cleaned = cleaned.trim();
      // 去标点取核心
      if (cleaned.isNotEmpty) {
        title = cleaned.replaceAll(RegExp(r'^[，。！？、,\\.!?\s]+'), '');
        title = title!.replaceAll(RegExp(r'[，。！？、,\\.!?\s]+$'), '');
        if (title!.length > 50) {
          title = '${title!.substring(0, 50)}...';
        }
      }
    }

    return ExtractedEntities(
      intentTag: intentTag,
      amount: amount,
      personName: personName,
      company: company,
      dueDateText: dueDateText,
      category: category,
      priority: priority,
      title: title,
    );
  }

  /// 根据关键词检测记账分类
  static String _detectLedgerCategory(String lowerText) {
    if (RegExp(r'(打车|滴滴|地铁|公交|加油|停车|高速|交通|出行|机票|火车票)').hasMatch(lowerText)) {
      return '交通';
    }
    if (RegExp(r'(吃饭|外卖|聚餐|午餐|晚餐|早餐|零食|奶茶|咖啡|餐厅|饭店)').hasMatch(lowerText)) {
      return '餐饮';
    }
    if (RegExp(r'(采购|购物|买|淘宝|京东|拼多多|衣服|鞋子)').hasMatch(lowerText)) {
      return '购物';
    }
    if (RegExp(r'(房租|水电|物业|房贷|租金)').hasMatch(lowerText)) {
      return '居住';
    }
    if (RegExp(r'(医疗|医院|药|看病|挂号)').hasMatch(lowerText)) {
      return '医疗';
    }
    if (RegExp(r'(电影|娱乐|游戏|旅游|酒店|景点)').hasMatch(lowerText)) {
      return '娱乐';
    }
    if (RegExp(r'(报销|发票|办公|文具|打印)').hasMatch(lowerText)) {
      return '办公';
    }
    if (RegExp(r'(工资|奖金|兼职|收入|到账)').hasMatch(lowerText)) {
      return '收入';
    }
    return '其他';
  }
}
