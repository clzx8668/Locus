import 'package:flutter/material.dart';
import '../../data/tag_repository.dart';
import '../../../../core/di/service_locator.dart';
import 'dart:async';

/// 标签选择器 —— 支持多选、搜索、快速创建
/// [compact] 模式：内联显示已选标签 chips + 添加按钮
/// [full] 模式：BottomSheet 形式，完整搜索 + 候选列表
class TagPicker extends StatefulWidget {
  final List<Tag> initiallySelected;
  final void Function(List<Tag> selectedTags) onChanged;
  final bool compact; // true = 内联模式，false = 弹窗模式（由外部控制）

  const TagPicker({
    super.key,
    required this.initiallySelected,
    required this.onChanged,
    this.compact = true,
  });

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  late TagRepository _repo;
  late List<Tag> _selected;
  List<Tag> _allTags = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _repo = getIt<TagRepository>();
    _selected = List.from(widget.initiallySelected);
    _sub = _repo.watchAll().listen((tags) {
      setState(() => _allTags = tags);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _toggleTag(Tag tag) {
    setState(() {
      if (_selected.any((t) => t.id == tag.id)) {
        _selected.removeWhere((t) => t.id == tag.id);
      } else {
        _selected.add(tag);
      }
    });
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ..._selected.map((tag) => Chip(
              label: Text(tag.name, style: const TextStyle(fontSize: 12)),
              backgroundColor: _parseColor(tag.color).withValues(alpha: 0.15),
              side: BorderSide(
                  color: _parseColor(tag.color).withValues(alpha: 0.3)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => _toggleTag(tag),
            )),
        ActionChip(
          label: const Icon(Icons.add, size: 16),
          onPressed: () => _showFullPicker(context),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildFull() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final availableTags =
        _allTags.where((t) => !_selected.any((s) => s.id == t.id)).toList();
    final availableColors = [
      '#FF6B6B',
      '#4ECDC4',
      '#45B7D1',
      '#96CEB4',
      '#FFEAA7',
      '#DDA0DD',
      '#98D8C8',
      '#F7DC6F',
      '#BB8FCE',
      '#85C1E9',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 已选标签
        if (_selected.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _selected
                .map((tag) => Chip(
                      label:
                          Text(tag.name, style: const TextStyle(fontSize: 12)),
                      backgroundColor:
                          _parseColor(tag.color).withValues(alpha: 0.15),
                      side: BorderSide(
                          color: _parseColor(tag.color).withValues(alpha: 0.3)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => _toggleTag(tag),
                    ))
                .toList(),
          ),
        if (_selected.isNotEmpty) const SizedBox(height: 12),

        // 候选标签（快速选择）
        Text('可用标签', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        if (availableTags.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('暂无标签，在下方输入创建', style: theme.textTheme.bodySmall),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: availableTags
                .map((tag) => ActionChip(
                      avatar: CircleAvatar(
                        radius: 4,
                        backgroundColor: _parseColor(tag.color),
                      ),
                      label:
                          Text(tag.name, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _toggleTag(tag),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
      ],
    );
  }

  void _showFullPicker(BuildContext context) async {
    final result = await showModalBottomSheet<List<Tag>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TagPickerSheet(
        alreadySelected: _selected,
      ),
    );
    if (result != null) {
      setState(() {
        _selected = result;
      });
      widget.onChanged(_selected);
    }
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
}

/// BottomSheet 形式的标签选择器
class _TagPickerSheet extends StatefulWidget {
  final List<Tag> alreadySelected;

  const _TagPickerSheet({required this.alreadySelected});

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late TagRepository _repo;
  late List<Tag> _selected;
  List<Tag> _allTags = [];
  String _query = '';
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo = getIt<TagRepository>();
    _selected = List.from(widget.alreadySelected);
    _repo.getAll().then((tags) {
      if (mounted) setState(() => _allTags = tags);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTag(Tag tag) {
    setState(() {
      if (_selected.any((t) => t.id == tag.id)) {
        _selected.removeWhere((t) => t.id == tag.id);
      } else {
        _selected.add(tag);
      }
    });
  }

  Future<void> _createTag(String name) async {
    final id = await _repo.getOrCreate(name);
    _repo.getAll().then((tags) {
      if (mounted) setState(() => _allTags = tags);
    });
    final newTag =
        Tag(id: id, name: name, color: '#FF6B6B', createdAt: DateTime.now());
    _toggleTag(newTag);
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _query.isEmpty
        ? _allTags
        : _allTags.where((t) => t.name.contains(_query)).toList();
    final availableColors = [
      '#FF6B6B',
      '#4ECDC4',
      '#45B7D1',
      '#96CEB4',
      '#FFEAA7',
      '#DDA0DD',
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 + 完成按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('选择标签', style: theme.textTheme.titleMedium),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, _selected),
                child: const Text('完成'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 已选标签
          if (_selected.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _selected
                  .map((tag) => Chip(
                        label: Text(tag.name,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor:
                            _parseColor(tag.color).withValues(alpha: 0.15),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _toggleTag(tag),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          const SizedBox(height: 12),

          // 搜索输入
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: '搜索或输入新标签名...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty &&
                  !_allTags.any((t) => t.name == v.trim())) {
                _createTag(v.trim());
              }
            },
          ),
          const SizedBox(height: 12),

          // 候选标签列表
          Flexible(
            child: filtered.isEmpty && _query.isNotEmpty
                ? ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: Text('创建标签 "$_query"'),
                    onTap: () => _createTag(_query.trim()),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final tag = filtered[i];
                      final isSelected = _selected.any((t) => t.id == tag.id);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(tag.name),
                        secondary: CircleAvatar(
                          radius: 6,
                          backgroundColor: _parseColor(tag.color),
                        ),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        onChanged: (_) => _toggleTag(tag),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
}
