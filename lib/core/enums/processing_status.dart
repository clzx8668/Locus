
/// 闪念笔记处理流水线状态枚举
/// 对应 hexin.md 中定义的异步流转状态机
enum ProcessingStatus {
  /// 刚写入本地数据库，UI 已释放，等待后台处理
  syncedLocal('synced_local'),

  /// 正在执行向量查重（与历史记录对比语义相似度）
  vectorChecking('vector_checking'),

  /// 正在调用 AI 进行意图路由与实体抽取
  aiRouting('ai_routing'),

  /// 正在将数据分发至对应业务表
  dispatching('dispatching'),

  /// 已进入待确认收件箱
  pendingReview('pending_review'),

  /// 离线已保存 —— 原始数据已加密落库到 offline_queue，等待网络恢复
  offlineSaved('offline_saved'),

  /// 已完成全部分发流程
  dispatched('dispatched'),

  /// 文本已清洗 —— 冗余词已剔除，等待异步 AI 分析
  textCleaned('text_cleaned'),

  /// 处理失败，挂起等待网络恢复后重试
  failedRetry('failed_retry'),

  /// 已衰减折叠
  decayed('decayed');

  const ProcessingStatus(this.dbValue);

  final String dbValue;

  /// 从数据库存储值反序列化
  static ProcessingStatus fromString(String value) {
    const legacyMap = {
      'syncedLocal': 'synced_local',
      'vectorChecking': 'vector_checking',
      'aiRouting': 'ai_routing',
      'failedRetry': 'failed_retry',
      'pendingReview': 'pending_review',
    };
    final normalized = legacyMap[value] ?? value;
    return ProcessingStatus.values.firstWhere(
      (s) => s.dbValue == normalized,
      orElse: () => ProcessingStatus.syncedLocal,
    );
  }

  /// 序列化为数据库存储值
  String toDbValue() => dbValue;
}
