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
  bool _isPreview = false;

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

          // 格式化工具栏（仅编辑模式）
          if (!_isPreview) _buildFormatToolbar(isDark),

          // 核心区域：编辑 / 预览切换
          Expanded(
            child: _isPreview
                ? _buildMarkdownPreview(isDark)
                : Padding(
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
          if (_mediaPaths.isNotEmpty && !_isPreview) _buildMediaBar(isDark),

          // 底部工具栏（仅编辑模式）
          if (!_isPreview) _buildBottomToolbar(isDark),
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
        _isPreview ? '预览' : (widget.initialContent != null ? '编辑内容块' : '追加内容'),
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black),
      ),
      centerTitle: true,
      actions: [
        // 编辑 / 预览切换
        IconButton(
          icon: Icon(
            _isPreview ? Icons.edit_outlined : Icons.visibility_outlined,
            size: 18,
          ),
          color: _isPreview ? const Color(0xFFFF6B6B) : Colors.grey[400],
          tooltip: _isPreview ? '切换到编辑' : '预览',
          onPressed: () => setState(() => _isPreview = !_isPreview),
        ),
        // 分享
        IconButton(
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          color: Colors.grey[400],
          tooltip: '分享',
          onPressed: () => _showShareOptions(),
        ),
        const SizedBox(width: 2),
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

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('分享内容',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _shareChip(Icons.copy_rounded, '复制全文', isDark, () {
                      Navigator.pop(context);
                      // TODO: 实现复制到剪贴板
                    }),
                    _shareChip(Icons.image_outlined, '导出图片', isDark, () {
                      Navigator.pop(context);
                      // TODO: 实现内容截图导出
                    }),
                    _shareChip(
                        Icons.description_outlined, '导出 Markdown', isDark, () {
                      Navigator.pop(context);
                      // TODO: 实现MD文件导出
                    }),
                    _shareChip(Icons.text_snippet_outlined, '纯文本', isDark, () {
                      Navigator.pop(context);
                      // TODO: 实现纯文本导出
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shareChip(
      IconData icon, String label, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: Colors.grey[400]),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildMarkdownPreview(bool isDark) {
    final lines = _controller.text.split('\n');
    final spans = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 水平分割线
      if (line.trimRight() == '---' || line.trimRight() == '***') {
        spans.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Theme.of(context).dividerColor),
        ));
        continue;
      }

      // 标题
      if (line.startsWith('# ')) {
        spans.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            line.substring(2),
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
                height: 1.3),
          ),
        ));
        continue;
      }
      if (line.startsWith('## ')) {
        spans.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(
            line.substring(3),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
                height: 1.3),
          ),
        ));
        continue;
      }
      if (line.startsWith('### ')) {
        spans.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.substring(4),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF333333),
                height: 1.3),
          ),
        ));
        continue;
      }

      // 引用
      if (line.startsWith('> ')) {
        spans.add(
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 6),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                    width: 3),
              ),
            ),
            child: _parseInlineMarkdown(
                line.substring(2),
                TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    fontStyle: FontStyle.italic),
                isDark),
          ),
        );
        continue;
      }

      // 无序列表
      if (line.trimLeft().startsWith('- ')) {
        final indent = line.length - line.trimLeft().length;
        final content = line.trimLeft().substring(2);
        spans.add(Padding(
          padding: EdgeInsets.only(left: indent + 16.0, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ',
                  style: TextStyle(fontSize: 14, color: Color(0xFFFF6B6B))),
              Expanded(
                child: _parseInlineMarkdown(
                    content,
                    TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: isDark
                            ? Colors.grey[300]
                            : const Color(0xFF444444)),
                    isDark),
              ),
            ],
          ),
        ));
        continue;
      }

      // 有序列表
      final olMatch = RegExp(r'^\d+\.\s').firstMatch(line);
      if (olMatch != null) {
        final content = line.substring(olMatch.end);
        spans.add(Padding(
          padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${line.substring(0, olMatch.end - 2)}. ',
                  style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.7))),
              Expanded(
                child: _parseInlineMarkdown(
                    content,
                    TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: isDark
                            ? Colors.grey[300]
                            : const Color(0xFF444444)),
                    isDark),
              ),
            ],
          ),
        ));
        continue;
      }

      // 空行
      if (line.trim().isEmpty) {
        spans.add(const SizedBox(height: 8));
        continue;
      }

      // 普通段落
      spans.add(Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: _parseInlineMarkdown(
            line,
            TextStyle(
                fontSize: 14,
                height: 1.7,
                color: isDark ? Colors.grey[200] : const Color(0xFF333333)),
            isDark),
      ));
    }

    if (spans.isEmpty) {
      return Center(
        child: Text('暂无内容',
            style: TextStyle(fontSize: 14, color: Colors.grey[500])),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: spans),
    );
  }

  /// 解析行内 Markdown：**粗体**、_斜体_、`代码`
  Widget _parseInlineMarkdown(String text, TextStyle baseStyle, bool isDark) {
    final segments = <InlineSpan>[];
    // 匹配 **bold**、_italic_、`code`
    final regex = RegExp(r'(\*\*(.+?)\*\*|_(.+?)_|`(.+?)`)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // 普通文本
      if (match.start > lastEnd) {
        segments.add(TextSpan(
            text: text.substring(lastEnd, match.start), style: baseStyle));
      }

      if (match.group(2) != null) {
        // **粗体**
        segments.add(TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(fontWeight: FontWeight.bold)));
      } else if (match.group(3) != null) {
        // _斜体_
        segments.add(TextSpan(
            text: match.group(3),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic)));
      } else if (match.group(4) != null) {
        // `代码`
        segments.add(TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            fontSize: (baseStyle.fontSize ?? 14) - 1,
            backgroundColor:
                isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
            color: const Color(0xFFFF6B6B),
          ),
        ));
      }

      lastEnd = match.end;
    }

    // 剩余文本
    if (lastEnd < text.length) {
      segments.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return RichText(text: TextSpan(children: segments));
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
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
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
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
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
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
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
