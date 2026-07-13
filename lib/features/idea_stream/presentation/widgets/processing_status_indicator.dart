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
      case ProcessingStatus.aiRouting:
      case ProcessingStatus.dispatching:
        return _buildSpinningIcon();
      case ProcessingStatus.failedRetry:
        return _buildWaitingIcon();
      case ProcessingStatus.dispatched:
        return _buildDoneIcon();
    }
  }

  Widget _buildSpinningIcon() {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
      ),
    );
  }

  Widget _buildWaitingIcon() {
    return const Icon(
      Icons.hourglass_empty_rounded,
      size: 14,
      color: Color(0xFFFFA726), // 橙色表示等待
    );
  }

  Widget _buildDoneIcon() {
    return const Icon(
      Icons.check_circle_rounded,
      size: 16,
      color: Color(0xFF66BB6A), // 绿色表示完成
    );
  }
}
