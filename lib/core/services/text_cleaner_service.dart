/// 口语化冗余词清洗服务
///
/// 在 AI 分析前对用户输入文本做预处理，精准剔除无业务价值的语气词、
/// 填充词、口语化冗余助词，保留原文语义完整性。
///
/// 纯本地正则匹配，无网络依赖，通常在 100ms 内完成。
class TextCleanerService {
  /// 冗余词词库 —— 按长度降序排列确保最长匹配优先
  static const List<String> _fillerWords = [
    '说白了',
    '就是说',
    '那个啥',
    '嗯呐',
    '对吧',
    '然后',
    '反正',
    '就是',
    '话说',
    '这个',
    '那个',
    '嗯',
    '呀',
    '哦',
    '啊',
    '额',
    '嘛',
  ];

  /// 清洗用户输入文本，剔除口语化冗余词并规整格式
  ///
  /// [raw] 原始用户输入文本
  /// 返回清洗后的文本，去除冗余词、多余空格和连续标点
  String clean(String raw) {
    if (raw.trim().isEmpty) return raw;

    String result = raw;

    // Pass 0: 单字填充词无条件清除（业务语境中几乎无独立语义）
    const singleCharFillers = ['嗯', '呀', '哦', '啊', '额', '嘛'];
    for (final word in singleCharFillers) {
      result = result.replaceAll(word, '');
    }

    // Pass 1: 多字填充词 —— 标点分隔匹配（保留原逻辑）
    const multiCharFillers = [
      '说白了', '就是说', '那个啥', '嗯呐', '对吧',
      '然后', '反正', '就是', '话说', '这个', '那个',
    ];
    for (final word in multiCharFillers) {
      // 原正则：两端均为标点/空白/行边界
      result = result.replaceAllMapped(
        RegExp('(^|[，。！？、,\\.!?\\s])${RegExp.escape(word)}' r'($|[，。！？、,\.!?\s])'),
        _collapseMatch,
      );
    }

    // Pass 2: 多字填充词 —— 句首锚点宽松匹配
    // 匹配：句首 + 填充词 + 非标点字符（即后面直接跟实义词）
    for (final word in multiCharFillers) {
      result = result.replaceAllMapped(
        RegExp('(^|[，。！？、,\\.!?\\s])${RegExp.escape(word)}' r'(?=[^，。！？、,\.!?\s])'),
        (m) => (m.group(1)?.trim().isNotEmpty == true) ? m.group(1)! : '',
      );
    }

    // Pass 3: 去除逗号间冗余词
    for (final word in [...singleCharFillers, ...multiCharFillers]) {
      result = result.replaceAll('，${word}，', '，');
    }

    // Pass 4: 去除连续标点
    result = result.replaceAllMapped(RegExp(r'([，。！？、,\\.!?])\1+'), (m) => m.group(1)!);

    // Pass 5: 去除多余空格
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Pass 6: 去除句首句尾的逗号/顿号
    result = result.replaceAll(RegExp(r'^[，。！？、,\\.!?\s]+'), '');
    result = result.replaceAll(RegExp(r'[，。！？、,\\.!?\s]+$'), '');

    return result;
  }

  /// 辅助方法：处理冗余词匹配替换，保留前后标点分隔符
  static String _collapseMatch(Match m) {
    final before = m.group(1) ?? '';
    final after = m.group(2) ?? '';
    if (before.trim().isEmpty && after.trim().isEmpty) return '';
    if (before.trim().isEmpty) return after.trim();
    if (after.trim().isEmpty) return before.trim();
    return before.trim() + after.trim();
  }
}

// ===== 单元测试（开发验证用） =====
// 运行: dart run lib/core/services/text_cleaner_service.dart
void main() {
  final service = TextCleanerService();
  int passed = 0;
  int failed = 0;

  void test(String name, String input, String expected) {
    final result = service.clean(input);
    if (result == expected) {
      print('✓ $name');
      passed++;
    } else {
      print('✗ $name');
      print('  输入: "$input"');
      print('  期望: "$expected"');
      print('  实际: "$result"');
      failed++;
    }
  }

  print('=== TextCleanerService 单元测试 ===\n');

  test('inline填充词清洗', '嗯这个客户张三呀需要联系一下', '客户张三需要联系一下');
  test('标点包围填充词清洗', '说白了，这个项目，嗯，就是需要审核', '项目，需要审核');
  test('有意义词保留', '那个项目就是这个功能的核心', '项目就是这个功能的核心');
  test('空字符串', '', '');
  test('纯填充词', '嗯呀哦啊额嘛', '');

  print('\n=== 结果: $passed 通过, $failed 失败 ===');
  if (failed > 0) throw Exception('$failed 个测试失败');
}
