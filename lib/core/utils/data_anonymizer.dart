
/// 数据脱敏工具 —— 在发送给云端 LLM 前对敏感信息做掩码处理
class DataAnonymizer {
  /// 脱敏处理：替换手机号、身份证号、金额、邮箱等敏感信息
  static String anonymize(String text) {
    if (text.isEmpty) return text;

    String result = text;

    // 手机号：保留前3后4，如 138****5678
    result = result.replaceAllMapped(
      RegExp(r'(?<!\d)(1[3-9]\d)\d{4}(\d{4})(?!\d)'),
      (m) => '${m.group(1)}****${m.group(2)}',
    );

    // 身份证号：保留前4后2，如 3101**********1234
    result = result.replaceAllMapped(
      RegExp(r'(?<!\d)(\d{6})\d{8}(\d{4})(?!\d)'),
      (m) => '${m.group(1)}******${m.group(2)}',
    );

    // 银行卡号：保留前4后4，如 6222****1234
    result = result.replaceAllMapped(
      RegExp(r'(?<!\d)(\d{4})\d{8,12}(\d{4})(?!\d)'),
      (m) => '${m.group(1)}****${m.group(2)}',
    );

    // 金额 ¥xxxx.xx → ¥****
    result = result.replaceAllMapped(
      RegExp(r'¥\s*[\d,]+(?:\.\d+)?'),
      (_) => '¥****',
    );

    // 金额 美元
    result = result.replaceAllMapped(
      RegExp(r'\$\s*[\d,]+(?:\.\d+)?'),
      (_) => '\$****',
    );

    // 邮箱
    result = result.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9._-]{1,3})[a-zA-Z0-9._-]*@([a-zA-Z0-9-]+\.[a-zA-Z]{2,})'),
      (m) => '${m.group(1)}***@${m.group(2)}',
    );

    return result;
  }
}
