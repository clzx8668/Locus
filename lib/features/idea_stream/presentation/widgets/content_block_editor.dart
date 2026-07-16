import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// 内容块编辑器的返回结果
class BlockEditResult {
  final String content;
  final List<String> mediaPaths;
  final String blockType; // 'text', 'image', 'file', 'voice'

  BlockEditResult({
    required this.content,
    required this.mediaPaths,
    this.blockType = 'text',
  });
}

/// 快捷编辑器 —— 首次创建闪念时的快速输入
/// 作为 BottomSheet 使用，提供基础文本、图片、文件、录音功能
class QuickBlockEditor extends StatefulWidget {
  final String? initialContent;
  final List<String>? initialMediaPaths;

  const QuickBlockEditor({
    super.key,
    this.initialContent,
    this.initialMediaPaths,
  });

  @override
  State<QuickBlockEditor> createState() => _QuickBlockEditorState();
}

class _QuickBlockEditorState extends State<QuickBlockEditor> {
  late TextEditingController _controller;
  final List<String> _mediaPaths = [];
  final ImagePicker _picker = ImagePicker();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent ?? '');
    if (widget.initialMediaPaths != null) {
      _mediaPaths.addAll(widget.initialMediaPaths!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 拖拽指示条
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 文本输入
          TextField(
            controller: _controller,
            autofocus: widget.initialContent == null,
            maxLines: 8,
            minLines: 3,
            style: const TextStyle(fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              hintText: '输入内容...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),

          // 已选媒体预览
          if (_mediaPaths.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaPaths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final path = _mediaPaths[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: path.toLowerCase().endsWith('.jpg') ||
                                path.toLowerCase().endsWith('.png') ||
                                path.toLowerCase().endsWith('.jpeg') ||
                                path.toLowerCase().endsWith('.webp')
                            ? Image.file(File(path),
                                width: 80, height: 80, fit: BoxFit.cover)
                            : Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF333333)
                                      : const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.insert_drive_file,
                                    color: Colors.grey, size: 28),
                              ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _mediaPaths.removeAt(index)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 10),

          // 工具栏
          Row(
            children: [
              _buildToolButton(
                  Icons.image_outlined, '图片', isDark, () => _pickImages()),
              const SizedBox(width: 6),
              _buildToolButton(
                  Icons.attach_file_rounded, '文件', isDark, () => _pickFiles()),
              const SizedBox(width: 6),
              _buildToolButton(
                  _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                  _isRecording ? '停止' : '录音',
                  isDark,
                  () => _toggleRecording()),
              const Spacer(),
              // 确认按钮
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    BlockEditResult(
                      content: _controller.text.trim(),
                      mediaPaths: List.from(_mediaPaths),
                      blockType: _mediaPaths.isNotEmpty
                          ? (_mediaPaths.first.toLowerCase().endsWith('.jpg') ||
                                  _mediaPaths.first
                                      .toLowerCase()
                                      .endsWith('.png')
                              ? 'image'
                              : 'file')
                          : 'text',
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  widget.initialContent != null ? '保存' : '添加',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
      IconData icon, String label, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: _isRecording && icon == Icons.stop_rounded
                    ? Colors.redAccent
                    : Colors.grey[500]),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _mediaPaths.addAll(images.map((e) => e.path));
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _mediaPaths
            .addAll(result.files.map((f) => f.path!).where((p) => p != null));
      });
    }
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    if (!_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('录音功能需要在系统设置中开启麦克风权限'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
