import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';
import '../../../../core/utils/intent_router.dart';

class QuickInputBottomSheet extends StatefulWidget {
  const QuickInputBottomSheet({super.key});

  @override
  State<QuickInputBottomSheet> createState() => _QuickInputBottomSheetState();
}

class _QuickInputBottomSheetState extends State<QuickInputBottomSheet> {
  final db = getIt<AppDatabase>();
  final TextEditingController _textController = TextEditingController();
  final List<String> _pendingMediaPaths = [];
  final ImagePicker _picker = ImagePicker();

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

  void _showMediaActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
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

  void _submitPayload() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _pendingMediaPaths.isEmpty) return;

    final dynamicTag = IntentRouter.parseTag(text);
    final mediaJson = jsonEncode(_pendingMediaPaths);

    final entry = HubPayloadsCompanion(
      rawText: d.Value(text),
      intentTag: d.Value(dynamicTag),
      mediaPaths: d.Value(mediaJson),
    );

    await db.insertPayload(entry);

    if (mounted) Navigator.pop(context); // 发送完毕自动收回控制台
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 15)],
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶层小把手
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // 图片待发送预览区
            if (_pendingMediaPaths.isNotEmpty)
              Container(
                height: 72,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pendingMediaPaths.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12, top: 4),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                              image: FileImage(File(_pendingMediaPaths[index])),
                              fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 0,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _pendingMediaPaths.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                                color: Colors.redAccent, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

            // 输入控制行
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      color: Color(0xFFFF6B6B), size: 28),
                  onPressed: _showMediaActionSheet,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 4,
                    minLines: 1,
                    autofocus: true,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '极速归档(如: #CRM 客户要求明天发爆炸图)...',
                      hintStyle:
                          TextStyle(color: theme.hintColor, fontSize: 13),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: isDark
                          ? theme.scaffoldBackgroundColor
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: Color(0xFFFF6B6B), size: 28),
                  onPressed: _submitPayload,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
