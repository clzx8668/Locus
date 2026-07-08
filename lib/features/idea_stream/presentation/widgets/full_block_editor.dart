import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'content_block_editor.dart';

/// 全功能块编辑器 —— 用于追加/编辑内容块
/// 全屏页面，提供格式化工具栏、媒体插入、Markdown / 富文本混合编辑
class FullBlockEditor extends StatefulWidget {
  final String? initialContent;
  final List<String>? initialMediaPaths;

  const FullBlockEditor({
    super.key,
    this.initialContent,
    this.initialMediaPaths,
  });

  @override
  State<FullBlockEditor> createState() => _FullBlockEditorState();
}

class _FullBlockEditorState extends State<FullBlockEditor> {
  late TextEditingController _controller;
  late List<String> _mediaPaths;
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  // 格式化工具状态
  bool _boldActive = false;
  String _headingLevel = '';

  // 时间戳
  late String _createdTime;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent ?? '');
    _mediaPaths = widget.initialMediaPaths != null
        ? List.from(widget.initialMediaPaths!)
        : [];
    _createdTime = _formatNow();

    // 自动聚焦
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialContent == null || widget.initialContent!.isEmpty) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ==================== 格式化操作 ====================

  void _insertHeading(int level) {
    final text = _controller.text;
    final sel = _controller.selection;
    final prefix = '#' * level + ' ';

    if (sel.start == 0 || text[sel.start - 1] == '\n') {
      // 在行首插入 Markdown 标题
      final newText =
          text.substring(0, sel.start) + prefix + text.substring(sel.start);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start + prefix.length),
      );
    } else {
      // 在光标位置换行后插入
      _controller.value = TextEditingValue(
        text:
            '${text.substring(0, sel.start)}\n$prefix${text.substring(sel.start)}',
        selection:
            TextSelection.collapsed(offset: sel.start + 1 + prefix.length),
      );
    }
    setState(() => _headingLevel = 'H$level');
  }

  void _insertMarker(String before, String after) {
    final text = _controller.text;
    final sel = _controller.selection;

    if (sel.isCollapsed) {
      // 无选中：插入标记模板
      final newText =
          '${text.substring(0, sel.start)}$before${text.substring(sel.start, sel.end)}$after${text.substring(sel.end)}';
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start + before.length),
      );
    } else {
      // 有选中：包裹标记
      final selected = text.substring(sel.start, sel.end);
      final newText =
          '${text.substring(0, sel.start)}$before$selected$after${text.substring(sel.end)}';
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: sel.end + before.length + after.length),
      );
    }
    setState(() => _boldActive = !_boldActive);
  }

  void _insertList(String marker) {
    final text = _controller.text;
    final sel = _controller.selection;

    if (sel.start == 0 || text[sel.start - 1] == '\n') {
      final newText =
          '${text.substring(0, sel.start)}$marker ${text.substring(sel.start)}';
      _controller.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: sel.start + marker.length + 1),
      );
    } else {
      _controller.value = TextEditingValue(
        text:
            '${text.substring(0, sel.start)}\n$marker ${text.substring(sel.start)}',
        selection:
            TextSelection.collapsed(offset: sel.start + 1 + marker.length + 1),
      );
    }
  }

  void _insertHorizontalRule() {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.start == 0 || text[sel.start - 1] == '\n' ? '' : '\n';
    final newText =
        '${text.substring(0, sel.start)}$start---\n${text.substring(sel.start)}';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + start.length + 4),
    );
  }

  // ==================== 媒体操作 ====================

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _mediaPaths.addAll(images.map((e) => e.path));
        // 在文本中插入图片占位符
        for (final img in images) {
          _controller.text += '\n![image](${img.path.split('/').last})\n';
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _mediaPaths.add(photo.path);
        _controller.text += '\n![photo](${photo.path.split('/').last})\n';
      });
    }
  }

  // ==================== 保存 ====================

  void _save() {
    Navigator.pop(
      context,
      BlockEditResult(
        content: _controller.text.trim(),
        mediaPaths: List.from(_mediaPaths),
        blockType: _mediaPaths.isNotEmpty
            ? (_mediaPaths.first.toLowerCase().endsWith('.jpg') ||
                    _mediaPaths.first.toLowerCase().endsWith('.png')
                ? 'image'
                : 'file')
            : 'text',
      ),
    );
  }

  String _formatNow() {
    final n = DateTime.now();
    return '${n.month}月${n.day}日 ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // 顶部时间戳 & 信息条
          _buildInfoBar(isDark),

          // 格式化工具栏
          _buildFormatToolbar(isDark),

          // 核心编辑区
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
                decoration: const InputDecoration(
                  hintText: '开始输入...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 8, bottom: 80),
                ),
              ),
            ),
          ),

          // 底部媒体预览条
          if (_mediaPaths.isNotEmpty) _buildMediaBar(isDark),

          // 底部工具栏
          _buildBottomToolbar(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 0,
      leading: TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消',
            style: TextStyle(fontSize: 15, color: Colors.grey)),
      ),
      title: Text(
        widget.initialContent != null ? '编辑内容块' : '追加内容',
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            ),
            child: const Text('保存',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text(_createdTime,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const Spacer(),
          Text('${_controller.text.length} 字',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildFormatToolbar(bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFEEEEEE),
              width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _fmtBtn(Icons.title, 'H1', () => _insertHeading(1)),
          _fmtBtn(Icons.format_size_rounded, 'H2', () => _insertHeading(2)),
          _fmtBtn(Icons.text_fields_rounded, 'H3', () => _insertHeading(3)),
          _fmtBtn(Icons.format_bold_rounded, _boldActive ? 'B' : 'B',
              () => _insertMarker('**', '**')),
          _fmtBtn(
              Icons.format_italic_rounded, 'I', () => _insertMarker('_', '_')),
          _fmtBtn(Icons.format_strikethrough_rounded, 'S',
              () => _insertMarker('~~', '~~')),
          _fmtBtn(
              Icons.format_quote_rounded, '引', () => _insertMarker('> ', '')),
          _fmtBtn(
              Icons.format_list_bulleted_rounded, '列', () => _insertList('-')),
          _fmtBtn(
              Icons.format_list_numbered_rounded, '序', () => _insertList('1.')),
          _fmtBtn(Icons.code_rounded, '码', () => _insertMarker('`', '`')),
          _fmtBtn(Icons.horizontal_rule_rounded, '线', _insertHorizontalRule),
        ]
            .map((w) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: w,
                ))
            .toList(),
      ),
    );
  }

  Widget _fmtBtn(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildMediaBar(bool isDark) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
        border: Border(
          top: BorderSide(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFEEEEEE),
              width: 1),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaPaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final path = _mediaPaths[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: path.toLowerCase().endsWith('.jpg') ||
                        path.toLowerCase().endsWith('.png') ||
                        path.toLowerCase().endsWith('.jpeg')
                    ? Image.file(File(path),
                        width: 60, height: 60, fit: BoxFit.cover)
                    : Container(
                        width: 60,
                        height: 60,
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF0F0F0),
                        child: const Icon(Icons.insert_drive_file,
                            color: Colors.grey, size: 20),
                      ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: GestureDetector(
                  onTap: () => setState(() => _mediaPaths.removeAt(index)),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
        border: Border(
          top: BorderSide(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFEEEEEE),
              width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _toolChip(Icons.image_outlined, _pickImages),
            const SizedBox(width: 8),
            _toolChip(Icons.camera_alt_outlined, _takePhoto),
            const SizedBox(width: 8),
            _toolChip(Icons.mic_none_outlined, () {}),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF262626) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Markdown',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolChip(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF262626)
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.grey[500]),
      ),
    );
  }
}
