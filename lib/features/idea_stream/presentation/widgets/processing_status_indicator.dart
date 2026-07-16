import 'package:flutter/material.dart';
import '../../../../core/enums/processing_status.dart';

/// 处理流水线状态指示器 —— 显示在卡片角落的微型图标
class ProcessingStatusIndicator extends StatelessWidget {
  final String statusValue;

  const ProcessingStatusIndicator({super.key, required this.statusValue});

  ProcessingStatus get _status => ProcessingStatus.fromString(statusValue);

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case ProcessingStatus.syncedLocal:
        // 刚写入，不显示任何指示
        return const SizedBox.shrink();
      case ProcessingStatus.vectorChecking:
      case ProcessingStatus.textCleaned:
        return _buildStaticIcon(Icons.manage_search_rounded, const Color(0xFF42A5F5));
      case ProcessingStatus.aiRouting:
        return _buildStaticIcon(Icons.auto_awesome_rounded, Colors.amber);
      case ProcessingStatus.dispatching:
      case ProcessingStatus.pendingReview:
        return _buildStaticIcon(Icons.inbox_rounded, const Color(0xFF7E57C2));
      case ProcessingStatus.failedRetry:
        return _buildStaticIcon(Icons.hourglass_empty_rounded, const Color(0xFFFFA726));
      case ProcessingStatus.dispatched:
      case ProcessingStatus.decayed:
        return _buildStaticIcon(Icons.check_circle_rounded, const Color(0xFF66BB6A));
      case ProcessingStatus.offlineSaved:
        return _buildStaticIcon(Icons.cloud_off_rounded, const Color(0xFFFFA726));
    }
  }

  Widget _buildStaticIcon(IconData icon, Color color) {
    return Icon(icon, size: 14, color: color);
  }
}
