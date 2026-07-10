import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';
import '../../data/idea_repository.dart';
import 'idea_detail_page.dart';

class IdeaStreamPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const IdeaStreamPage({super.key, this.onNavigate});

  @override
  State<IdeaStreamPage> createState() => _IdeaStreamPageState();
}

class _IdeaStreamPageState extends State<IdeaStreamPage> {
  final _repo = getIt<IdeaRepository>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = "";
  bool _isGridView = false;
  List<String> _selectedTags = [];
  final Map<int, String> _blockTextCache = {};
  final Map<int, int> _blockCountCache = {};
  late final Stream<List<HubPayload>> _allPayloadsStream;

  @override
  void initState() {
    super.initState();
    _allPayloadsStream = _repo.watchAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth >= 960;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6),
      drawer: _buildAppDrawer(context, isDark),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernTopAppBar(context, isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                _getGreetingPhrase(),
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<HubPayload>>(
                stream: _allPayloadsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFFF6B6B)));
                  }

                  var items = snapshot.data!.where((item) {
                    final matchText = _blockTextCache[item.id] ?? item.rawText;
                    final matchesSearch = _searchQuery.isEmpty ||
                        matchText
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        item.intentTag
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                    final matchesTags = _selectedTags.isEmpty ||
                        _selectedTags.any((tag) => item.intentTag
                            .toLowerCase()
                            .contains(tag.toLowerCase()));
                    return matchesSearch && matchesTags;
                  }).toList();

                  // 异步加载空 rawText 记录的第一个内容块文本
                  for (final item in items) {
                    if (item.rawText.isEmpty &&
                        !_blockTextCache.containsKey(item.id)) {
                      _repo.getFirstBlockText(item.id).then((text) {
                        if (text != null && mounted) {
                          setState(() => _blockTextCache[item.id] = text!);
                        }
                      });
                    }
                  }

                  // 异步加载内容块数量
                  for (final item in items) {
                    if (!_blockCountCache.containsKey(item.id)) {
                      _repo.getBlockCount(item.id).then((count) {
                        if (mounted) {
                          setState(() => _blockCountCache[item.id] = count);
                        }
                      });
                    }
                  }

                  if (items.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  final useGrid = _isGridView || isLargeScreen;
                  final listOrGrid = useGrid
                      ? GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isLargeScreen ? 3 : 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) =>
                              _buildSmartCard(items[index], theme),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildSmartCard(items[index], theme),
                        );
                  return listOrGrid;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final templates = [
      {
        'icon': Icons.record_voice_over_rounded,
        'label': '会议纪要',
        'hint': '2026年度Q3季度复盘会议...'
      },
      {
        'icon': Icons.auto_stories_rounded,
        'label': '读书笔记',
        'hint': '《原则》第二章核心观点...'
      },
      {
        'icon': Icons.wb_incandescent_rounded,
        'label': '灵感闪记',
        'hint': '突然想到一个关于XXX的点子...'
      },
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flash_on_rounded,
                  size: 36,
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text('闪念已清空',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color
                        ?.withValues(alpha: 0.5))),
            const SizedBox(height: 6),
            Text('点击右下角 + 号快速收录灵感',
                style: TextStyle(fontSize: 13, color: theme.hintColor)),
            const SizedBox(height: 32),
            Text('试试这些模板：',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            const SizedBox(height: 14),
            ...templates.map((tpl) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    // 导航到快速输入弹窗并预填模板
                    _openQuickInputWithTemplate(tpl['hint'] as String);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.06),
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(tpl['icon'] as IconData,
                            size: 20,
                            color:
                                const Color(0xFFFF6B6B).withValues(alpha: 0.6)),
                        const SizedBox(width: 12),
                        Text(tpl['label'] as String,
                            style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color)),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openQuickInputWithTemplate(String hint) {
    // TODO: 接入 LocusHomePage 的 QuickInputBottomSheet 并预填模板文本
    // 当前通过设置 _searchQuery 作为临时预填方案
    setState(() => _searchQuery = '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('模板提示: $hint'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTagFilterDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _TagFilterDialog(
          repo: _repo,
          selectedTags: _selectedTags,
          isDark: isDark,
          onSelectionChanged: (tags) {
            setState(() => _selectedTags = tags);
          },
        );
      },
    );
  }

  Widget _buildModernTopAppBar(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isSmallScreen) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 22),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, color: Colors.grey[500], size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                          fontSize: 13, textBaseline: TextBaseline.alphabetic),
                      decoration: InputDecoration(
                        hintText: '搜索或向 AI 提问...',
                        hintStyle:
                            TextStyle(color: Colors.grey[500], fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              _selectedTags.isNotEmpty
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              color: _selectedTags.isNotEmpty
                  ? const Color(0xFFFF6B6B)
                  : Colors.grey[400],
              size: 18,
            ),
            tooltip: '按标签筛选',
            onPressed: () => _showTagFilterDialog(isDark),
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(
              _isGridView
                  ? Icons.view_headline_rounded
                  : Icons.dashboard_customize_outlined,
              color: _isGridView ? const Color(0xFFFF6B6B) : Colors.grey[400],
              size: 20,
            ),
            tooltip: '切换卡片视图样式',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartCard(HubPayload data, ThemeData theme) {
    final hasTag = data.intentTag.isNotEmpty && data.intentTag != 'NOTE';
    final mediaPaths = _parseImagePaths(data.mediaPaths);
    final dateStr = _formatRelativeTime(data.createdAt);
    final displayText =
        _stripMarkdownForPreview(_blockTextCache[data.id] ?? data.rawText);

    final card = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IdeaDetailPage(payload: data),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.08), width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== 装饰短横线：数量 = 内容块数量 =====
            Builder(builder: (context) {
              final count = (_blockCountCache[data.id] ?? 1).clamp(1, 12);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: List.generate(count, (i) {
                    return Container(
                      width: 22,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: theme.hintColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              );
            }),
            // 日期行
            Text(dateStr,
                style: TextStyle(color: theme.hintColor, fontSize: 11)),
            const SizedBox(height: 8),
            if (mediaPaths.isNotEmpty && !_isGridView) ...[
              _buildImagePreview(mediaPaths),
              const SizedBox(height: 6),
            ],
            Flexible(
              child: Text(
                displayText.isEmpty ? "快速归档记录" : displayText,
                maxLines: _isGridView ? 5 : 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, height: 1.45, fontWeight: FontWeight.w500),
              ),
            ),
            // ===== 标签移至底部左对齐 =====
            if (hasTag) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data.intentTag.toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Dismissible(
      key: Key('payload_${data.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('确认删除'),
                content: Text(
                    '确定要删除"${displayText.length > 30 ? '${displayText.substring(0, 30)}...' : displayText}"吗？'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('取消')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('删除',
                          style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _repo.delete(data.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
      ),
      child: card,
    );
  }

  Widget _buildImagePreview(List<String> paths) {
    final count = paths.length;
    if (count == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(paths.first),
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
      );
    }

    // 多图堆叠效果
    final displayPaths = paths.take(3).toList();
    final extraCount = count - 3;

    return SizedBox(
      height: 72,
      child: Stack(
        children: List.generate(displayPaths.length, (i) {
          return Positioned(
            left: i * 18.0,
            child: Container(
              width: 56,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
                image: DecorationImage(
                  image: FileImage(File(displayPaths[i])),
                  fit: BoxFit.cover,
                ),
              ),
              child: i == 2 && extraCount > 0
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('+$extraCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 6) return '${diff.inHours}小时前';

    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
    if (isYesterday) {
      return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    if (date.year == now.year) {
      return '${date.month}月${date.day}日';
    }
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  List<String> _parseImagePaths(String mediaPathsJson) {
    try {
      final decoded = jsonDecode(mediaPathsJson);
      if (decoded is List) {
        return decoded.cast<String>();
      }
    } catch (_) {}
    return [];
  }

  String _getGreetingPhrase() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '早上好';
    if (hour >= 12 && hour < 18) return '下午好';
    return '晚上好';
  }

  Widget _buildAppDrawer(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final drawerBgColor =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFF212121);

    final menuItems = [
      {'label': '首页', 'icon': Icons.flash_on, 'selected': false},
      {'label': '日历', 'icon': Icons.calendar_month, 'selected': false},
      {'label': 'AI枢纽', 'icon': Icons.hub, 'selected': false},
      {'label': '设置', 'icon': Icons.settings, 'selected': false},
    ];

    // TODO: 后续在此扩展更多导航项（如客户CRM、记账、打卡等）

    return Drawer(
      width: 260,
      backgroundColor: drawerBgColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('L',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Locus',
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.white70,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('全能型 AI 私人助理',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                    child: Text('常用',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0)),
                  ),
                  ...menuItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                      dense: true,
                      horizontalTitleGap: 12,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        _scaffoldKey.currentState?.closeDrawer();
                        widget.onNavigate?.call(index);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                    child: Text('更多',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0)),
                  ),
                  // TODO: 后续在此添加更多功能入口
                  ListTile(
                    leading: Icon(Icons.more_horiz,
                        color: Colors.grey[600], size: 20),
                    title: Text('即将上线...',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                    dense: true,
                    horizontalTitleGap: 12,
                    enabled: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 剥离 Markdown 格式标识字符，转为纯文本预览
  /// - 任务复选框 [ ]/[x] → ☐/☑
  /// - 标题 #、粗体 **、斜体 _、代码 `、删除线 ~~ → 去除标识符
  /// - 引用 >、列表 -/1. → 去除前缀
  /// - 水平分割线 --- → 移除整行
  String _stripMarkdownForPreview(String text) {
    // 1. 任务复选框 → 视觉状态符号（在行级处理之前先做）
    text = text.replaceAll('[x]', '☑');
    text = text.replaceAll('[X]', '☑');
    text = text.replaceAll('[ ]', '☐');

    final lines = text.split('\n');
    final result = <String>[];

    for (final line in lines) {
      var trimmed = line.trim();

      // 跳过水平分割线
      if (RegExp(r'^[-*]{3,}$').hasMatch(trimmed)) continue;

      // 去除块级前缀标识
      trimmed = trimmed
          .replaceFirst(RegExp(r'^#{1,3}\s+'), '') // 标题 # / ## / ###
          .replaceFirst(RegExp(r'^>\s?'), '') // 引用 >
          .replaceFirst(RegExp(r'^[-•]\s+'), '') // 无序列表 - / •
          .replaceFirst(RegExp(r'^\d+\.\s+'), ''); // 有序列表 1. / 2.

      // 去除行内格式标识字符（顺序：先处理成对标记）
      trimmed = trimmed
          .replaceAll('**', '') // 粗体
          .replaceAll('~~', '') // 删除线
          .replaceAll('`', '') // 行内代码
          .replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m.group(1) ?? ''); // 斜体

      result.add(trimmed);
    }

    return result
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // 合并连续空行
        .trim();
  }
}

/// 标签筛选弹窗 —— 显示所有标签及使用次数，支持多选
class _TagFilterDialog extends StatefulWidget {
  final IdeaRepository repo;
  final List<String> selectedTags;
  final bool isDark;
  final ValueChanged<List<String>> onSelectionChanged;

  const _TagFilterDialog({
    required this.repo,
    required this.selectedTags,
    required this.isDark,
    required this.onSelectionChanged,
  });

  @override
  State<_TagFilterDialog> createState() => _TagFilterDialogState();
}

class _TagFilterDialogState extends State<_TagFilterDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: widget.repo.getTagStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final sortedTags = stats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return AlertDialog(
          backgroundColor:
              widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Row(
            children: [
              const Text('按标签筛选', style: TextStyle(fontSize: 16)),
              const Spacer(),
              if (_selected.isNotEmpty)
                TextButton(
                  onPressed: () {
                    final result = <String>[];
                    widget.onSelectionChanged(result);
                    Navigator.pop(context);
                  },
                  child: const Text('清除',
                      style: TextStyle(fontSize: 13, color: Color(0xFFFF6B6B))),
                ),
            ],
          ),
          content: SizedBox(
            width: 280,
            child: sortedTags.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child:
                            Text('暂无标签', style: TextStyle(color: Colors.grey))),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: sortedTags.map((entry) {
                      final tag = entry.key;
                      final count = entry.value;
                      final displayTag =
                          tag.startsWith('#') ? tag.substring(1) : tag;
                      final isChecked = _selected.contains(tag);

                      return CheckboxListTile(
                        value: isChecked,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(displayTag,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text('$count 条记录',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600])),
                        activeColor: const Color(0xFFFF6B6B),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selected.add(tag);
                            } else {
                              _selected.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(fontSize: 13)),
            ),
            FilledButton(
              onPressed: () {
                widget.onSelectionChanged(List.from(_selected));
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B)),
              child: const Text('确定',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
