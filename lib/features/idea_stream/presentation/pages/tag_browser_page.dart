import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/tag_repository.dart';
import '../../../../core/di/service_locator.dart';
import 'package:drift/drift.dart' as drift;

/// 标签浏览器 —— "虚拟文件夹"视图
/// 以标签为维度浏览闪念笔记，支持多标签 AND 组合筛选
class TagBrowserPage extends StatefulWidget {
  const TagBrowserPage({super.key});

  @override
  State<TagBrowserPage> createState() => _TagBrowserPageState();
}

class _TagBrowserPageState extends State<TagBrowserPage> {
  late final TagRepository _repo;
  List<Tag> _allTags = [];
  final Set<String> _selectedTagNames = {};
  StreamSubscription<List<Tag>>? _tagSub;

  @override
  void initState() {
    super.initState();
    _repo = getIt<TagRepository>();
    _tagSub = _repo.watchAll().listen((tags) {
      if (mounted) setState(() => _allTags = tags);
    });
  }

  @override
  void dispose() {
    _tagSub?.cancel();
    super.dispose();
  }

  void _toggleTag(Tag tag) {
    setState(() {
      if (_selectedTagNames.contains(tag.name)) {
        _selectedTagNames.remove(tag.name);
      } else {
        _selectedTagNames.add(tag.name);
      }
    });
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) {
        return Color(int.parse('FF$h', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('标签浏览'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 标签筛选栏
          _buildTagBar(theme),
          const Divider(height: 1),
          // 内容列表
          Expanded(child: _buildContentList(theme)),
        ],
      ),
    );
  }

  Widget _buildTagBar(ThemeData theme) {
    if (_allTags.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('暂无标签，给笔记添加标签后即可在此浏览'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _allTags.map((tag) {
            final isSelected = _selectedTagNames.contains(tag.name);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                avatar: CircleAvatar(
                  radius: 5,
                  backgroundColor: _parseColor(tag.color),
                ),
                label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (_) => _toggleTag(tag),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContentList(ThemeData theme) {
    if (_selectedTagNames.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.label_outline,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('选择一个或多个标签筛选笔记',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return StreamBuilder<List<HubPayload>>(
      stream: _repo.watchPayloadsByTags(_selectedTagNames.toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payloads = snapshot.data ?? [];

        if (payloads.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text('没有匹配的笔记',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: payloads.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
          itemBuilder: (context, index) {
            final payload = payloads[index];
            return _buildPayloadTile(theme, payload);
          },
        );
      },
    );
  }

  Widget _buildPayloadTile(ThemeData theme, HubPayload payload) {
    final preview = payload.rawText.length > 80
        ? '${payload.rawText.substring(0, 80)}...'
        : payload.rawText;
    final title = payload.title ?? preview;

    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          _intentIcon(payload.intentTag),
          size: 16,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(payload.intentTag,
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          if (payload.dispatchedRef != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.link,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 2),
            Text(
              payload.dispatchedRef!.split(':').first,
              style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, '/idea_detail', arguments: payload.id);
      },
    );
  }

  IconData _intentIcon(String tag) {
    switch (tag) {
      case 'NOTE':
        return Icons.note_alt_outlined;
      case 'CRM':
        return Icons.person_outline;
      case 'LEDGER':
        return Icons.account_balance_wallet_outlined;
      case 'TODO':
        return Icons.check_circle_outline;
      case 'INVENTORY':
        return Icons.inventory_2_outlined;
      case 'HABIT':
        return Icons.repeat;
      default:
        return Icons.push_pin_outlined;
    }
  }
}
