
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_system.dart';

class ExportBottomSheet extends StatelessWidget {
  final String content;

  const ExportBottomSheet({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 把手
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('导出到',
                  style: AppTypography.h3
                      .copyWith(color: theme.textTheme.bodyLarge?.color)),
            ),
            // 导出选项网格
            _buildExportGrid(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildExportGrid(BuildContext context, bool isDark) {
    final exportTargets = [
      _ExportTarget(
        icon: Icons.chat_rounded,
        label: '微信',
        color: const Color(0xFF07C160),
        onTap: () => _copyToWechat(context),
      ),
      // 预留槽位：后续可添加更多导出目标
      // _ExportTarget(icon: Icons.picture_as_pdf, label: 'PDF'),
      // _ExportTarget(icon: Icons.description, label: 'Markdown'),
      // _ExportTarget(icon: Icons.mail, label: '钉钉'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: exportTargets.map((target) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            target.onTap();
          },
          child: SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: target.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(target.icon, color: target.color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  target.label,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[300] : Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _copyToWechat(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制，可粘贴到微信'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ExportTarget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportTarget({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
