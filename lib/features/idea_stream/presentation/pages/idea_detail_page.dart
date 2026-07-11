import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';
import '../../../../core/services/ai_engine.dart';
import '../../../../core/theme/design_system.dart';
import '../../data/idea_repository.dart';
import '../widgets/content_block_editor.dart';
import '../widgets/full_block_editor.dart';

class IdeaDetailPage extends StatefulWidget {
  final HubPayload payload;

  const IdeaDetailPage({super.key, required this.payload});

  @override
  State<IdeaDetailPage> createState() => _IdeaDetailPageState();
}

class _IdeaDetailPageState extends State<IdeaDetailPage> {
  final _repo = getIt<IdeaRepository>();
  final _ai = getIt<AiEngine>();

  final TextEditingController _newTaskController = TextEditingController();
  bool _isEnteringTask = false;

  // AI 对话输入
  final TextEditingController _aiInputController = TextEditingController();
  bool _isAiWorking = false;
  String _activeAiAction = '';

  late String _currentTitle;

  late final Stream<List<ContentBlock>> _blocksStream;
  late final Stream<List<AiConversation>> _conversationsStream;
  late final Stream<List<IdeaTask>> _tasksStream;

  @override
  void initState() {
    super.initState();
    _blocksStream = _repo.watchBlocks(widget.payload.id);
    _conversationsStream = _repo.watchConversations(widget.payload.id);
    _tasksStream = _repo.watchTasks(widget.payload.id);
    _initContentBlocks();
    _initAiConversations();
    _initTitle();
  }

  /// 初始化内容块：如果 DB 中没有块，将 payload.rawText 作为第一个块写入
  void _initContentBlocks() async {
    // 给 StreamBuilder 一点时间，如果已有块则不处理
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 检查是否已有块（通过 listen 回调判断比较麻烦，改用简单延迟触发）
    // 这里用一次查询判断
    try {
      _repo.watchBlocks(widget.payload.id).first.then((blocks) {
        if (!mounted) return;
        if (blocks.isEmpty && widget.payload.rawText.isNotEmpty) {
          _repo.addBlock(
            widget.payload.id,
            'text',
            widget.payload.rawText,
            _parseMediaPaths(widget.payload.mediaPaths),
          );
          // 保留前200字作为列表卡片摘要
          final preview = widget.payload.rawText.length > 200
              ? '${widget.payload.rawText.substring(0, 200)}...'
              : widget.payload.rawText;
          _repo.update(widget.payload.id, preview, widget.payload.intentTag);
        }
      });
    } catch (_) {}
  }

  void _initAiConversations() {
    // 数据库表新建时不需要特别初始化
  }

  void _initTitle() {
    final payloadTitle = widget.payload.title;
    if (payloadTitle != null && payloadTitle.isNotEmpty) {
      _currentTitle = payloadTitle;
    } else {
      // 标题为空时，延迟从首块内容自动提取
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _repo.watchBlocks(widget.payload.id).first.then((blocks) {
          if (!mounted) return;
          if (blocks.isNotEmpty && blocks.first.content.isNotEmpty) {
            final text = blocks.first.content;
            final firstLine = text.split('\n').first.trim();
            if (firstLine.isEmpty) {
              _currentTitle = '';
              return;
            }
            // 去除 Markdown 标题标记
            final cleanTitle =
                firstLine.replaceFirst(RegExp(r'^#{1,3}\s+'), '');
            _currentTitle = cleanTitle.length > 30
                ? '${cleanTitle.substring(0, 30)}...'
                : cleanTitle;
            // 写入数据库
            _repo.updateTitle(widget.payload.id, _currentTitle);
            if (mounted) setState(() {});
          }
        });
      });
      _currentTitle = widget.payload.title ?? '';
    }
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后将无法恢复，确定要删除这条闪念吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('删除', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _repo.delete(widget.payload.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showEditTitleDialog(bool isDark) {
    final controller = TextEditingController(text: _currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改标题'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入标题',
            filled: true,
            fillColor:
                isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          maxLength: 100,
          onSubmitted: (val) {
            final newTitle = val.trim();
            _currentTitle = newTitle.isEmpty ? '' : newTitle;
            _repo.updateTitle(
                widget.payload.id, newTitle.isEmpty ? null : newTitle);
            setState(() {});
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              _currentTitle = newTitle.isEmpty ? '' : newTitle;
              _repo.updateTitle(
                  widget.payload.id, newTitle.isEmpty ? null : newTitle);
              setState(() {});
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newTaskController.dispose();
    _aiInputController.dispose();
    super.dispose();
  }

  // ==================== 内容块操作 ====================

  Future<void> _openBlockEditor({int? blockId}) async {
    final result = await Navigator.push<BlockEditResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const FullBlockEditor(),
      ),
    );

    if (result != null &&
        (result.content.isNotEmpty || result.mediaPaths.isNotEmpty)) {
      await _repo.addBlock(
        widget.payload.id,
        result.blockType,
        result.content,
        result.mediaPaths,
      );
      // 不再覆盖摘要 — 保持首块生成的摘要不变
    }
  }

  void _deleteBlock(ContentBlock block) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除此内容块'),
        content: Text(
            '确定删除此块？\n"${block.content.length > 40 ? '${block.content.substring(0, 40)}...' : block.content}"'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('删除', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _repo.removeBlock(block.id);
    }
  }

  void _polishBlock(ContentBlock block) async {
    setState(() {
      _isAiWorking = true;
      _activeAiAction = '润色中...';
    });
    final polished = await _ai.polishText(block.content);
    if (mounted) {
      if (!polished.startsWith('[AI离线]')) {
        await _repo.updateBlockContent(
            block.id, polished, _parseMediaPaths(block.mediaPaths));
        await _repo.markBlockPolished(block.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('AI 暂不可用，已标记待处理'), duration: Duration(seconds: 2)),
        );
      }
      setState(() {
        _isAiWorking = false;
        _activeAiAction = '';
      });
    }
  }

  // ==================== AI 对话 ====================

  Future<void> _sendAiMessage() async {
    final text = _aiInputController.text.trim();
    if (text.isEmpty) return;

    // 保存用户消息
    await _repo.addConversation(widget.payload.id, 'user', text);
    _aiInputController.clear();
    setState(() => _isAiWorking = true);

    // 构建上下文：所有内容块的内容
    final blocks = await _repo.watchBlocks(widget.payload.id).first;
    final contextText = blocks.map((b) => b.content).join('\n---\n');

    // 发送 AI 请求
    final response = await _ai.chat(
      '用户正在查看一条笔记，内容如下：\n$contextText\n\n请根据用户的问题提供帮助。简洁回答。',
      text,
    );

    if (mounted) {
      await _repo.addConversation(widget.payload.id, 'assistant', response);
      setState(() => _isAiWorking = false);
    }
  }

  // ==================== 构建内容块 ====================

  Widget _buildContentBlock(ContentBlock block, ThemeData theme, bool isDark) {
    final mediaPaths = _parseMediaPaths(block.mediaPaths);
    final isVoice = block.sourceType == 'voice';
    final dateStr = _formatBlockTime(block.createdAt);

    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFBFBFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.06), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 块头部：来源图标 + 时间 + 操作按钮
            Row(
              children: [
                Icon(
                  isVoice ? Icons.mic_rounded : Icons.text_snippet_rounded,
                  size: 14,
                  color: isVoice
                      ? Colors.orangeAccent.withValues(alpha: 0.7)
                      : Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(dateStr,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const Spacer(),
                _BlockIconButton(
                  icon: Icons.edit_outlined,
                  label: '编辑',
                  onTap: () => _openBlockEditorForEdit(block),
                ),
                if (isVoice)
                  _BlockIconButton(
                    icon: Icons.play_arrow_rounded,
                    label: '播放',
                    onTap: () {},
                  ),
                if (!block.aiPolished)
                  _BlockIconButton(
                    icon: Icons.auto_fix_high_rounded,
                    label: '润色',
                    color: Colors.amber,
                    onTap: _isAiWorking ? null : () => _polishBlock(block),
                  ),
                if (block.aiPolished)
                  Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: Colors.green[400]),
                const SizedBox(width: 4),
                _BlockIconButton(
                  icon: Icons.delete_outline_rounded,
                  label: null,
                  color: Colors.grey[500],
                  onTap: () => _deleteBlock(block),
                ),
              ],
            ),
            if (block.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              _renderMarkdownPreview(block.content, isDark),
            ],
            // 媒体预览
            if (mediaPaths.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: mediaPaths.map((path) {
                  final isImage = path.toLowerCase().endsWith('.jpg') ||
                      path.toLowerCase().endsWith('.png') ||
                      path.toLowerCase().endsWith('.jpeg');
                  return GestureDetector(
                    onTap: isImage ? () => _showFullScreenImage(path) : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: (MediaQuery.of(context).size.width - 84) / 3,
                        height: 90,
                        child: isImage
                            ? Image.file(File(path), fit: BoxFit.cover)
                            : Container(
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF0F0F0),
                                child: const Center(
                                    child: Icon(Icons.insert_drive_file,
                                        color: Colors.grey, size: 24)),
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            // ===== 每块独立标签区域 =====
            _buildBlockTagSection(block, theme, isDark),
          ],
        ));
  }

  void _openBlockEditorForEdit(ContentBlock block) async {
    final result = await Navigator.push<BlockEditResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullBlockEditor(
          initialContent: block.content,
          initialMediaPaths: _parseMediaPaths(block.mediaPaths),
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      await _repo.updateBlockContent(
          block.id, result.content, result.mediaPaths);
      // 仅当编辑的是首块（sortOrder 最小）时同步更新卡片摘要
      final blocks = await _repo.watchBlocks(widget.payload.id).first;
      if (blocks.isNotEmpty && blocks.first.id == block.id) {
        final preview = result.content.length > 200
            ? '${result.content.substring(0, 200)}...'
            : result.content;
        _repo.update(widget.payload.id, preview, widget.payload.intentTag);
      }
    }
  }

  // ==================== 块内标签 ====================

  Widget _buildBlockTagSection(
      ContentBlock block, ThemeData theme, bool isDark) {
    final tags = _parseTags(block.tags);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            ...tags.map((tag) {
              final displayTag = tag.startsWith('#') ? tag : '#$tag';
              return InputChip(
                label: Text(displayTag, style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close_rounded,
                    size: 12, color: Colors.grey),
                onDeleted: () {
                  final updated = List<String>.from(tags)..remove(tag);
                  _repo.updateBlockTags(block.id, updated);
                },
                backgroundColor:
                    const Color(0xFFFF6B6B).withValues(alpha: 0.06),
                labelStyle: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w500,
                    fontSize: 11),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }),
            ActionChip(
              label: const Text('+ 标签', style: TextStyle(fontSize: 11)),
              onPressed: () => _showBlockTagDialog(block, tags),
              backgroundColor:
                  isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
              side: BorderSide.none,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ),
      ],
    );
  }

  void _showBlockTagDialog(ContentBlock block, List<String> currentTags) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入标签名',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF262626)
                : const Color(0xFFF1F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (val) {
            final tag = val.trim();
            if (tag.isNotEmpty) {
              final cleanTag = tag.startsWith('#') ? tag : '#$tag';
              final updated = List<String>.from(currentTags);
              if (!updated.contains(cleanTag)) {
                updated.add(cleanTag);
              }
              _repo.updateBlockTags(block.id, updated);
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty) {
                final cleanTag = tag.startsWith('#') ? tag : '#$tag';
                final updated = List<String>.from(currentTags);
                if (!updated.contains(cleanTag)) {
                  updated.add(cleanTag);
                }
                _repo.updateBlockTags(block.id, updated);
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== 主构建 ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 46,
        centerTitle: true,
        title: Text(_currentTitle.isEmpty ? '未命名' : _currentTitle,
            style: AppTypography.h3
                .copyWith(color: theme.textTheme.bodyMedium?.color)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, size: 18),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                  value: 'edit_title',
                  child: Text('修改标题', style: TextStyle(fontSize: 13))),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('删除此条',
                      style: TextStyle(fontSize: 13, color: Colors.redAccent))),
            ],
            onSelected: (val) {
              if (val == 'edit_title') {
                _showEditTitleDialog(isDark);
              } else if (val == 'delete') {
                _confirmDelete();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 内容块区域 =====
            StreamBuilder<List<ContentBlock>>(
              stream: _blocksStream,
              builder: (context, snapshot) {
                final blocks = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 块标题
                    if (blocks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('内容记录',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500])),
                      ),

                    // 渲染所有内容块
                    ...blocks.map(
                        (block) => _buildContentBlock(block, theme, isDark)),

                    // 追加内容按钮（始终在最后一个块之后）
                    const SizedBox(height: 6),
                    _buildAddBlockButton(isDark, theme),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ===== AI 对话区域 =====
            _buildAiSection(theme, isDark),

            const SizedBox(height: 20),

            // ===== 任务清单 =====
            _buildTaskSection(theme, isDark),
          ],
        ),
      ),
      bottomNavigationBar: _buildAiInputBar(isDark),
    );
  }

  // ==================== 追加按钮 ====================

  Widget _buildAddBlockButton(bool isDark, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: GestureDetector(
          onTap: _openBlockEditor,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '追加内容',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== AI 对话区域 ====================

  Widget _buildAiSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 区域标题
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.amber, size: 14),
            const SizedBox(width: 6),
            Text('AI 交流',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 10),

        // 对话列表
        StreamBuilder<List<AiConversation>>(
          stream: _conversationsStream,
          builder: (context, snapshot) {
            final conversations = snapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 空状态提示
                if (conversations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('所有内容块已作为上下文提供给 AI，开始提问吧',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ),

                // 对话列表
                ...conversations.map(
                    (conv) => _buildConversationBubble(conv, theme, isDark)),

                // 加载指示器
                if (_isAiWorking)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                            child: const Icon(Icons.auto_awesome_rounded,
                                size: 14, color: Color(0xFFFF6B6B)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF0F0F0),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(0xFFFF6B6B)
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('思考中...',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildConversationBubble(
      AiConversation conv, ThemeData theme, bool isDark) {
    final isUser = conv.role == 'user';
    const bubbleMaxWidth = 0.75;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 用户消息：头像在右；AI 消息：头像在左
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor:
                    const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: Color(0xFFFF6B6B)),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * bubbleMaxWidth),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFFF6B6B)
                    : isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Text(
                conv.content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isUser
                      ? Colors.white
                      : isDark
                          ? Colors.grey[200]
                          : const Color(0xFF333333),
                ),
              ),
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor:
                    const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                child: const Text('我',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _aiInputController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: '基于所有内容块进行AI交流...',
                hintStyle: TextStyle(fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _sendAiMessage(),
            ),
          ),
          GestureDetector(
            onTap: _isAiWorking ? null : _sendAiMessage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B6B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _aiPresets = [
    '总结全文要点',
    '翻译为英文',
    '润色优化表达',
    '提取关键信息',
    '生成内容大纲',
  ];

  Widget _buildAiInputBar(bool isDark) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border(
            top: BorderSide(
                color:
                    isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 预设按钮
                _buildPresetButton(isDark),
                const SizedBox(width: 8),
                // 输入框
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _aiInputController,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: '与 AI 交流...',
                        hintStyle: TextStyle(
                            fontSize: 14,
                            color:
                                isDark ? Colors.grey[600] : Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 发送按钮
                GestureDetector(
                  onTap: _sendAiMessage,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _aiInputController.text.trim().isEmpty
                          ? Colors.grey[400]
                          : const Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(bool isDark) {
    return PopupMenuButton<String>(
      offset: const Offset(0, -300),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(Icons.tag_rounded,
            size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      onSelected: (value) {
        _aiInputController.text = value;
        _sendAiMessage();
      },
      itemBuilder: (ctx) => _aiPresets
          .map((p) => PopupMenuItem(
                value: p,
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded,
                        size: 16,
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                    Text(p, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // ==================== 任务清单 ====================

  Widget _buildTaskSection(ThemeData theme, bool isDark) {
    return StreamBuilder<List<IdeaTask>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final doneCount = tasks.where((t) => t.isDone).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checklist_rounded,
                        size: 14, color: Color(0xFFFF6B6B)),
                    const SizedBox(width: 6),
                    Text('转化执行清单 ($doneCount/${tasks.length})',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400])),
                  ],
                ),
                if (tasks.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 60,
                      height: 3,
                      child: LinearProgressIndicator(
                        value: tasks.isEmpty ? 0 : doneCount / tasks.length,
                        backgroundColor: isDark
                            ? const Color(0xFF333333)
                            : const Color(0xFFE0E0E0),
                        color: const Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                if (!_isEnteringTask)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        size: 16, color: Color(0xFFFF6B6B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _isEnteringTask = true),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (_isEnteringTask)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newTaskController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: '输入需要派生执行的步骤...',
                          border: UnderlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            _repo.addTask(
                                widget.payload.id, val.trim(), tasks.length);
                            _newTaskController.clear();
                            setState(() => _isEnteringTask = false);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () => setState(() => _isEnteringTask = false),
                    ),
                  ],
                ),
              ),
            if (tasks.isEmpty && !_isEnteringTask)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('暂无任务，点击 + 或使用 AI 派生',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ),
            ...tasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: task.isDone,
                          activeColor: const Color(0xFFFF6B6B),
                          checkColor: Colors.white,
                          side: BorderSide(color: Colors.grey[500]!, width: 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) =>
                              _repo.toggleTask(task.id, val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.content,
                          style: TextStyle(
                            fontSize: 13,
                            decoration:
                                task.isDone ? TextDecoration.lineThrough : null,
                            color: task.isDone ? theme.hintColor : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 14, color: Colors.grey[600]),
                        onPressed: () => _repo.removeTask(task.id),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  // ==================== 工具方法 ====================

  void _showFullScreenImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  /// 渲染 Markdown 预览（复用自 FullBlockEditor 的预览逻辑）
  Widget _renderMarkdownPreview(String text, bool isDark) {
    final lines = text.split('\n');
    final spans = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trimRight() == '---' || line.trimRight() == '***') {
        spans.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Divider(
              color: isDark ? Colors.grey[800] : Colors.grey[300], height: 1),
        ));
        continue;
      }

      if (line.startsWith('# ')) {
        spans.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 3),
          child: Text(line.substring(2),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: isDark ? Colors.white : Colors.black)),
        ));
        continue;
      }
      if (line.startsWith('## ')) {
        spans.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Text(line.substring(3),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: isDark ? Colors.white : Colors.black)),
        ));
        continue;
      }
      if (line.startsWith('### ')) {
        spans.add(Padding(
          padding: const EdgeInsets.only(top: 7, bottom: 2),
          child: Text(line.substring(4),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: isDark ? Colors.white : const Color(0xFF333333))),
        ));
        continue;
      }

      if (line.startsWith('> ')) {
        spans.add(Container(
          margin: const EdgeInsets.only(top: 4, bottom: 4),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                  width: 3),
            ),
          ),
          child: _parseInlineMD(
              line.substring(2),
              TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  fontStyle: FontStyle.italic),
              isDark),
        ));
        continue;
      }

      if (line.trimLeft().startsWith('- ')) {
        final indent = line.length - line.trimLeft().length;
        final content = line.trimLeft().substring(2);
        spans.add(Padding(
          padding: EdgeInsets.only(left: indent + 14.0, top: 1, bottom: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ',
                  style: TextStyle(fontSize: 13, color: Color(0xFFFF6B6B))),
              Expanded(
                  child: _parseInlineMD(
                      content,
                      TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark
                              ? Colors.grey[300]
                              : const Color(0xFF444444)),
                      isDark)),
            ],
          ),
        ));
        continue;
      }

      final olMatch = RegExp(r'^\d+\.\s').firstMatch(line);
      if (olMatch != null) {
        final content = line.substring(olMatch.end);
        spans.add(Padding(
          padding: const EdgeInsets.only(left: 14, top: 1, bottom: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${line.substring(0, olMatch.end - 2)}. ',
                  style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.7))),
              Expanded(
                  child: _parseInlineMD(
                      content,
                      TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark
                              ? Colors.grey[300]
                              : const Color(0xFF444444)),
                      isDark)),
            ],
          ),
        ));
        continue;
      }

      if (line.trim().isEmpty) {
        spans.add(const SizedBox(height: 6));
        continue;
      }

      spans.add(Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 3),
        child: _parseInlineMD(
            line,
            TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark ? Colors.grey[200] : const Color(0xFF333333)),
            isDark),
      ));
    }

    if (spans.isEmpty) {
      return Text('暂无内容',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]));
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: spans);
  }

  /// 解析行内 Markdown：**粗体**、_斜体_、`代码`
  Widget _parseInlineMD(String text, TextStyle baseStyle, bool isDark) {
    final segments = <InlineSpan>[];
    final regex = RegExp(r'(\*\*(.+?)\*\*|_(.+?)_|`(.+?)`)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        segments.add(TextSpan(
            text: text.substring(lastEnd, match.start), style: baseStyle));
      }

      if (match.group(2) != null) {
        segments.add(TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(fontWeight: FontWeight.bold)));
      } else if (match.group(3) != null) {
        segments.add(TextSpan(
            text: match.group(3),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic)));
      } else if (match.group(4) != null) {
        segments.add(TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            fontSize: (baseStyle.fontSize ?? 13) - 1,
            backgroundColor:
                isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
            color: const Color(0xFFFF6B6B),
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      segments.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return RichText(text: TextSpan(children: segments));
  }

  List<String> _parseMediaPaths(String mediaPathsJson) {
    try {
      final decoded = jsonDecode(mediaPathsJson);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }

  List<String> _parseTags(String tagsJson) {
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }

  String _formatBlockTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 6) return '${diff.inHours}小时前';
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday)
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// 内容块的操作图标按钮
class _BlockIconButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  const _BlockIconButton({
    required this.icon,
    this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[500]!;
    final effectiveOnTap = onTap;

    return GestureDetector(
      onTap: effectiveOnTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: effectiveOnTap == null ? Colors.grey[700] : c),
            if (label != null) ...[
              const SizedBox(width: 2),
              Text(label!, style: TextStyle(fontSize: 10, color: c)),
            ],
          ],
        ),
      ),
    );
  }
}
