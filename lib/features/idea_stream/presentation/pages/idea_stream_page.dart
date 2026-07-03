import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';

class IdeaStreamPage extends StatefulWidget {
  const IdeaStreamPage({super.key});

  @override
  State<IdeaStreamPage> createState() => _IdeaStreamPageState();
}

class _IdeaStreamPageState extends State<IdeaStreamPage> {
  final db = getIt<AppDatabase>();

  String _searchQuery = "";
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth >= 960;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6),
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
                stream: db.watchAllPayloads(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFFF6B6B)));
                  }

                  var items = snapshot.data!.where((item) {
                    return item.rawText
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        item.intentTag
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        '核心私库无归档，点击快捷气泡极速收录',
                        style: TextStyle(color: theme.hintColor),
                      ),
                    );
                  }

                  final useGrid = _isGridView || isLargeScreen;
                  return useGrid
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
                },
              ),
            ),
          ],
        ),
      ),
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
            color: isDark ? const Color(0xFF262626) : const Color(0x1E000000),
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
              onPressed: () => Scaffold.of(context).openDrawer(),
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
          Icon(Icons.auto_awesome_rounded,
              color: Colors.orangeAccent[200], size: 18),
          const SizedBox(width: 12),
          Icon(Icons.assignment_turned_in_outlined,
              color: Colors.grey[400], size: 18),
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
    final hasTag = data.intentTag.isNotEmpty;
    final mediaPaths = _parseImagePaths(data.mediaPaths);
    final dateStr =
        '${data.createdAt.month}月${data.createdAt.day}日 ${data.createdAt.hour.toString().padLeft(2, '0')}:${data.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.08), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr,
                  style: TextStyle(color: theme.hintColor, fontSize: 11)),
              if (hasTag)
                Container(
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
            ],
          ),
          const SizedBox(height: 10),
          if (mediaPaths.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(mediaPaths.first),
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            data.rawText.isEmpty ? "快速归档记录" : data.rawText,
            maxLines: _isGridView ? 3 : 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14, height: 1.45, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
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
}
