import 'dart:async';
import '../../../core/database/database.dart';

/// 废话衰减管理器 —— 管理标记为"日常废话"的内容生命周期
class DecayManager {
  final AppDatabase _db;
  Timer? _decayTimer;

  DecayManager(this._db) {
    _startDecayMonitor();
  }

  /// 启动衰减检查定时器（每 10 分钟检查一次）
  void _startDecayMonitor() {
    _decayTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _checkExpiredItems();
    });
  }

  /// 标记一条 payload 为日常废话
  Future<void> markAsEphemeral(int payloadId) async {
    await _db.markAsEphemeral(payloadId);
  }

  /// 检查已过期的废话条目并自动折叠
  Future<void> _checkExpiredItems() async {
    try {
      final now = DateTime.now();
      // 查找所有标记为废话且未折叠的条目，在 Dart 端过滤过期时间
      final allEphemeral = await (_db.select(_db.hubPayloads)
            ..where((t) => t.isEphemeral.equals(true))
            ..where((t) => t.processingStatus.equals('dispatched')))
          .get();

      final expired = allEphemeral.where((item) {
        return item.decayDeadline != null && item.decayDeadline!.isBefore(now);
      }).toList();

      for (final item in expired) {
        // 标记为已折叠（通过将 processingStatus 改为特殊值，UI 层据此隐藏）
        await _db.updateProcessingStatus(item.id, 'decayed');
      }
    } catch (_) {
      // 静默处理，不影响主流程
    }
  }

  /// 计算透明度 alpha 值（基于衰减进度）
  /// 返回 0.0 ~ 1.0
  static double calculateAlpha(
      bool isEphemeral, DateTime? decayDeadline, DateTime? createdAt) {
    if (!isEphemeral || decayDeadline == null || createdAt == null) {
      return 1.0;
    }

    final now = DateTime.now();
    final totalDuration = decayDeadline.difference(createdAt);
    final elapsed = now.difference(createdAt);

    if (elapsed >= totalDuration) return 0.25; // 最淡，但不完全消失

    final progress = elapsed.inMilliseconds / totalDuration.inMilliseconds;
    // 24h 半衰期：从 1.0 线性降到 0.3，对应 48h
    // 实际公式：alpha = 1.0 - 0.7 * progress
    return (1.0 - 0.75 * progress).clamp(0.25, 1.0);
  }

  void dispose() {
    _decayTimer?.cancel();
  }
}
