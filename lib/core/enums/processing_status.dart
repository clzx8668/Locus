
/// 闪念笔记处理流水线状态枚举
/// 对应 hexin.md 中定义的异步流转状态机
enum ProcessingStatus {
  /// 刚写入本地数据库，UI 已释放，等待后台处理
  syncedLocal,

  /// 正在执行向量查重（与历史记录对比语义相似度）
  vectorChecking,

  /// 正在调用 AI 进行意图路由与实体抽取
  aiRouting,

  /// 正在将数据分发至对应业务表
  dispatching,

  /// 已完成全部分发流程
  dispatched,

  /// 处理失败，挂起等待网络恢复后重试
  failedRetry;

  /// 从数据库存储值反序列化
  static ProcessingStatus fromString(String value) {
    return ProcessingStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ProcessingStatus.syncedLocal,
    );
  }

  /// 序列化为数据库存储值
  String toDbValue() => name;
}
