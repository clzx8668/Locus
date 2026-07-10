import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/database/database.dart';

class ChatHistorySearchPage extends StatefulWidget {
  const ChatHistorySearchPage({super.key});

  @override
  State<ChatHistorySearchPage> createState() => _ChatHistorySearchPageState();
}

class _ChatHistorySearchPageState extends State<ChatHistorySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  AppDatabase get db => getIt<AppDatabase>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: '搜索历史对话内容或标题...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.hintColor),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
      body: Column(
        children: [
          Divider(
              height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
          Expanded(
            child: StreamBuilder<List<ChatSession>>(
              stream: db.watchAllSessions(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data ?? [];

                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? '暂无历史对话记录'
                              : '没有找到相关记忆...',
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.5),
                              fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final timeStr =
                        "${session.updatedAt.month}-${session.updatedAt.day} ${session.updatedAt.hour}:${session.updatedAt.minute.toString().padLeft(2, '0')}";

                    return ListTile(
                      leading: Icon(Icons.chat_bubble_outline,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.7)),
                      title: Text(session.title,
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyLarge?.color)),
                      subtitle: Text('最后活跃: $timeStr',
                          style: TextStyle(color: theme.hintColor)),
                      onTap: () {
                        Navigator.pop(context, session.id);
                      },
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
