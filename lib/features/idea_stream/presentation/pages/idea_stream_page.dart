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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '早上好';
    if (hour >= 12 && hour < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey[50],
      body: Column(
        children: [
          // 1. 固定的顶部美化问候与标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '这是你的纯私人闪念轨迹，数据已加密存入本地。',
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.all_inbox_rounded, color: theme.hintColor.withValues(alpha: 0.6)),
              ],
            ),
          ),

          // 2. 闪念瀑布流列表（铺满剩余空间，底部留 padding 避开悬浮 FAB）
          Expanded(
            child: StreamBuilder<List<HubPayload>>(
              stream: db.watchAllPayloads(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payloads = snapshot.data ?? [];

                if (payloads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, size: 48, color: theme.hintColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('闪念流空空如也\n点击右下角 + 写下第一条思考吧',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.hintColor, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                  itemCount: payloads.length,
                  itemBuilder: (context, index) {
                    final item = payloads[index];
                    List<String> imagePaths = [];
                    try {
                      List<dynamic> decoded = jsonDecode(item.mediaPaths);
                      imagePaths = decoded.cast<String>();
                    } catch (e) {
                      debugPrint("解析图片路径失败");
                    }

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? theme.dividerColor : Colors.grey[200]!),
                      ),
                      color: theme.cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.intentTag.isEmpty ? '#自由灵感' : item.intentTag,
                                style: const TextStyle(fontSize: 11, color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (item.rawText.isNotEmpty)
                              Text(item.rawText, style: const TextStyle(fontSize: 15, height: 1.4)),

                            if (imagePaths.isNotEmpty) ...[
                              if (item.rawText.isNotEmpty) const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: imagePaths.map((path) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )).toList(),
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
