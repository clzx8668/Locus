import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d; // 别名防止与 Flutter 的 Column 冲突
import '../../../core/di/service_locator.dart';
import '../../../core/database/database.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  // 获取数据库单例
  final db = getIt<AppDatabase>();
  final TextEditingController _textController = TextEditingController();

  // 发送数据的逻辑
  void _submitPayload() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 构造插入数据库的载荷
    final entry = HubPayloadsCompanion(
      rawText: d.Value(text),
      intentTag: const d.Value('NOTE'), // 默认先打上普通笔记标签
    );

    // 写入数据库
    await db.insertPayload(entry);
    
    // 清空输入框，保持键盘开启，准备下一次输入
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // 给背景一点极简的灰度
      body: Column(
        children: [
          // 1. 上半部分：流式列表 (监听数据库)
          Expanded(
            child: StreamBuilder<List<HubPayload>>(
              stream: db.watchAllPayloads(), // 核心：时刻监听数据库变化
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final payloads = snapshot.data ?? [];
                
                if (payloads.isEmpty) {
                  return const Center(
                    child: Text('轨迹为空\n开始记录你的第一个闪念吧', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                  );
                }

                // 渲染数据卡片
                return ListView.builder(
                  reverse: true, // 像微信一样，最新消息在最下面（如果需要最新在最上面，改为 false）
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: payloads.length,
                  itemBuilder: (context, index) {
                    final item = payloads[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 标签展示
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.intentTag,
                                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 内容展示
                            Text(
                              item.rawText,
                              style: const TextStyle(fontSize: 16, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // 2. 下半部分：极速输入框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // 预留的加号按钮（多模态入口）
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueGrey),
                    onPressed: () {
                      // 未来在这里调起相机/相册
                    },
                  ),
                  const SizedBox(width: 8),
                  // 文本输入区
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitPayload(), // 键盘的回车键发送
                      decoration: InputDecoration(
                        hintText: '记录灵感、账单或安排...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 发送按钮
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueGrey),
                    onPressed: _submitPayload,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}