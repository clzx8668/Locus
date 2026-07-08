import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:image_picker/image_picker.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/database/database.dart';
import '../../../core/utils/intent_router.dart';
import '../../idea_stream/data/idea_repository.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final _repo = getIt<IdeaRepository>();
  final TextEditingController _textController = TextEditingController();
  
  // 核心状态：暂存当前准备发送的图片路径
  final List<String> _pendingMediaPaths = [];
  final ImagePicker _picker = ImagePicker();

  // 唤起图片选择器
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _pendingMediaPaths.add(image.path);
        });
      }
    } catch (e) {
      debugPrint("图片选择失败: $e");
    }
  }

  // 弹出选择菜单（相机或相册）
  void _showMediaActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blueGrey),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blueGrey),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 移除预览的图片
  void _removePendingImage(int index) {
    setState(() {
      _pendingMediaPaths.removeAt(index);
    });
  }

  // 提交载荷到加密金库
  void _submitPayload() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _pendingMediaPaths.isEmpty) return;

    // 动态解析意图标签
    final dynamicTag = IntentRouter.parseTag(text);

    // 将图片路径列表转为 JSON 字符串存入数据库
    final mediaJson = jsonEncode(_pendingMediaPaths);

    final entry = HubPayloadsCompanion(
      rawText: d.Value(text),
      intentTag: d.Value(dynamicTag), // 接入正则大脑，自动识别业务意图
      mediaPaths: d.Value(mediaJson),
    );

    await _repo.insert(entry);
    
    // 清理现场
    setState(() {
      _textController.clear();
      _pendingMediaPaths.clear();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // 1. 上半部分：流式列表
          Expanded(
            child: StreamBuilder<List<HubPayload>>(
              stream: _repo.watchAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final payloads = snapshot.data ?? [];
                
                if (payloads.isEmpty) {
                  return const Center(
                    child: Text('轨迹为空\n开始记录你的第一个图文闪念吧', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: payloads.length,
                  itemBuilder: (context, index) {
                    final item = payloads[index];
                    
                    // 解析数据库中的 JSON 图片路径
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
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.intentTag,
                                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // 渲染文本（如果有）
                            if (item.rawText.isNotEmpty)
                              Text(item.rawText, style: const TextStyle(fontSize: 16, height: 1.4)),
                            
                            // 渲染图片（如果有）
                            if (imagePaths.isNotEmpty) ...[
                              if (item.rawText.isNotEmpty) const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: imagePaths.map((path) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(path),
                                    width: 100,
                                    height: 100,
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
          
          // 2. 下半部分：极速输入框与预览区
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -2), blurRadius: 10)
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片待发送预览区
                  if (_pendingMediaPaths.isNotEmpty)
                    Container(
                      height: 70,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _pendingMediaPaths.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 12, top: 8),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(_pendingMediaPaths[index])),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 4,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => _removePendingImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ),
                  
                  // 输入控制台
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.blueGrey, size: 28),
                        onPressed: _showMediaActionSheet,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitPayload(),
                          decoration: InputDecoration(
                            hintText: '记录灵感，或添加产品图片...',
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
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blueGrey),
                        onPressed: _submitPayload,
                      ),
                    ],
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