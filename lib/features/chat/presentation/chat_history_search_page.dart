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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索历史对话内容或标题...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.black38),
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
          const Divider(height: 1, color: Colors.black12),
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
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? '暂无历史对话记录' : '没有找到相关记忆...',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
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
                      leading:
                          const Icon(Icons.chat_bubble_outline, color: Colors.blueGrey),
                      title: Text(session.title,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('最后活跃: $timeStr'),
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
