import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/design_system.dart';
import '../../data/idea_repository.dart';

class TemplateManagementPage extends StatefulWidget {
  const TemplateManagementPage({super.key});

  @override
  State<TemplateManagementPage> createState() => _TemplateManagementPageState();
}

class _TemplateManagementPageState extends State<TemplateManagementPage> {
  final _repo = getIt<TemplateRepository>();

  String _templateTypeController = 'chat';

  static const _availableEmojis = [
    '📝',
    '🌐',
    '✨',
    '🔍',
    '📑',
    '📊',
    '💡',
    '⚡',
    '🎯',
    '📋',
    '💬',
    '🔗',
    '📌',
    '🏷️',
    '✅',
    '❌',
    '➕',
    '➖',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'AI 模板管理',
          style: AppTypography.h2.copyWith(color: colors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share, color: colors.textSecondary),
            tooltip: '导出',
            onPressed: _exportTemplates,
          ),
          IconButton(
            icon: Icon(Icons.file_download, color: colors.textSecondary),
            tooltip: '导入',
            onPressed: _importTemplates,
          ),
        ],
      ),
      body: StreamBuilder<List<AiTemplate>>(
        stream: _repo.watchAll(),
        builder: (context, snapshot) {
          final templates = snapshot.data ?? [];

          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }

          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 64,
                    color: colors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无模板，点击 + 创建',
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            buildDefaultDragHandles: false,
            itemCount: templates.length,
            onReorder: (oldIndex, newIndex) {
              final ids = templates.map((t) => t.id).toList();
              if (oldIndex < newIndex) newIndex--;
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              _repo.reorder(ids);
            },
            itemBuilder: (context, index) {
              final t = templates[index];
              return _buildTemplateItem(t, index, colors, isDark);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6B6B),
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTemplateItem(
    AiTemplate t,
    int index,
    AppColorsExtension colors,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Padding(
      key: ValueKey(t.id),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: colors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          onTap: () => _showEditDialog(template: t),
          onLongPress: () => _deleteTemplate(t),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.grey,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(t.icon, style: const TextStyle(fontSize: 20)),
                if (t.templateType == 'rule') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_fix_high,
                          size: 11,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '规则化',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.prompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: t.isEnabled,
                  activeThumbColor: const Color(0xFFFF6B6B),
                  onChanged: (_) => _toggleEnabled(t),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 编辑/新增弹窗 ====================

  void _showEditDialog({AiTemplate? template}) {
    final isEdit = template != null;
    final nameCtrl = TextEditingController(text: template?.name ?? '');
    final promptCtrl = TextEditingController(text: template?.prompt ?? '');
    String selectedEmoji = template?.icon ?? '📝';
    _templateTypeController = template?.templateType ?? 'chat';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final dialogTheme = Theme.of(ctx);
            final dialogColors = dialogTheme.extension<AppColorsExtension>()!;
            final dialogIsDark = dialogTheme.brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: dialogColors.surface1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              ),
              title: Text(
                isEdit ? '编辑模板' : '新建模板',
                style: AppTypography.h3.copyWith(
                  color: dialogColors.textPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji 选择器
                    Text(
                      '图标',
                      style: TextStyle(
                        fontSize: 12,
                        color: dialogColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _availableEmojis.map((emoji) {
                        final selected = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedEmoji = emoji);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(
                                      0xFFFF6B6B,
                                    ).withValues(alpha: 0.15)
                                  : dialogIsDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSM,
                              ),
                              border: selected
                                  ? Border.all(
                                      color: const Color(
                                        0xFFFF6B6B,
                                      ).withValues(alpha: 0.4),
                                    )
                                  : null,
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 模板名称
                    Text(
                      '名称',
                      style: TextStyle(
                        fontSize: 12,
                        color: dialogColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(
                        fontSize: 14,
                        color: dialogColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '例如：总结全文要点',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: dialogColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: dialogColors.surface2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSM,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prompt 内容
                    Text(
                      '提示词',
                      style: TextStyle(
                        fontSize: 12,
                        color: dialogColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: promptCtrl,
                      maxLines: 5,
                      minLines: 3,
                      style: TextStyle(
                        fontSize: 13,
                        color: dialogColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '输入 AI 提示词模板...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: dialogColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: dialogColors.surface2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSM,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    // 模板类型
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _templateTypeController,
                      decoration: InputDecoration(
                        labelText: '模板类型',
                        filled: true,
                        fillColor: dialogIsDark
                            ? const Color(0xFF262626)
                            : const Color(0xFFF1F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'chat',
                          child: Row(
                            children: [
                              Icon(Icons.chat_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('对话模板'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'rule',
                          child: Row(
                            children: [
                              Icon(Icons.auto_fix_high, size: 16),
                              SizedBox(width: 8),
                              Text('规则化模板'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setDialogState(
                          () => _templateTypeController = v ?? 'chat',
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    '取消',
                    style: TextStyle(color: dialogColors.textSecondary),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSM,
                      ),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final prompt = promptCtrl.text.trim();
                    if (name.isEmpty || prompt.isEmpty) return;

                    final nav = Navigator.of(ctx);
                    if (isEdit) {
                      await _repo.update(
                        template.id,
                        icon: selectedEmoji,
                        name: name,
                        prompt: prompt,
                        templateType: _templateTypeController,
                      );
                    } else {
                      await _repo.insert(
                        selectedEmoji,
                        name,
                        prompt,
                        templateType: _templateTypeController,
                      );
                    }
                    nav.pop();
                  },
                  child: const Text(
                    '确定',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== 启/禁用 ====================

  void _toggleEnabled(AiTemplate t) {
    _repo.update(t.id, isEnabled: !t.isEnabled);
  }

  // ==================== 删除 ====================

  void _deleteTemplate(AiTemplate t) {
    showDialog(
      context: context,
      builder: (ctx) {
        final dTheme = Theme.of(ctx);
        final dColors = dTheme.extension<AppColorsExtension>()!;
        return AlertDialog(
          backgroundColor: dColors.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          ),
          title: Text(
            '删除模板',
            style: AppTypography.h3.copyWith(color: dColors.textPrimary),
          ),
          content: Text(
            '确定要删除「${t.name}」吗？此操作不可恢复。',
            style: TextStyle(fontSize: 14, color: dColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消', style: TextStyle(color: dColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
              ),
              onPressed: () {
                _repo.delete(t.id);
                Navigator.pop(ctx);
              },
              child: const Text('删除', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ==================== 导出 ====================

  void _exportTemplates() async {
    final templates = await _repo.watchAll().first;
    final jsonList = templates
        .map((t) => {'icon': t.icon, 'name': t.name, 'prompt': t.prompt})
        .toList();

    final output = jsonEncode({'version': 1, 'templates': jsonList});

    await Clipboard.setData(ClipboardData(text: output));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导出 ${templates.length} 个模板到剪贴板'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ==================== 导入 ====================

  void _importTemplates() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final dTheme = Theme.of(ctx);
        final dColors = dTheme.extension<AppColorsExtension>()!;
        return AlertDialog(
          backgroundColor: dColors.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          ),
          title: Text(
            '导入模板',
            style: AppTypography.h3.copyWith(color: dColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '粘贴 JSON 内容开始导入',
                style: TextStyle(fontSize: 13, color: dColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 5,
                style: TextStyle(fontSize: 13, color: dColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '在此粘贴 JSON...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: dColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: dColors.surface2,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消', style: TextStyle(color: dColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
              ),
              onPressed: () async {
                final raw = ctrl.text.trim();
                if (raw.isEmpty) {
                  Navigator.pop(ctx);
                  return;
                }
                try {
                  final data = jsonDecode(raw);
                  if (data is! Map || data['templates'] is! List) {
                    throw const FormatException('格式错误');
                  }
                  final list = data['templates'] as List;
                  int count = 0;
                  for (final item in list) {
                    if (item is! Map) continue;
                    final icon = item['icon'] as String? ?? '📝';
                    final name = item['name'] as String? ?? '';
                    final prompt = item['prompt'] as String? ?? '';
                    if (name.isEmpty || prompt.isEmpty) continue;
                    await _repo.insert(icon, name, prompt);
                    count++;
                  }
                  if (mounted && ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('成功导入 $count 个模板'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('导入失败：${e.toString()}'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const Text('导入', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
